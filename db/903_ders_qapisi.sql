-- =====================================================================
--  903 : DERS TESTI QAPISI DERS-DERS ACILIR (2026-09-30)
--
--  NIYE
--  23.09-da «test yig» dugmesi ders setrinden fesil basligina kocdu:
--  suallar yalniz fesle bagli idi, her derste eyni fesil hovuzundan
--  demek olar eyni test yigilardi.  Indi bank sessiyalari suallara
--  'ders:<alt-movzu-slug>' nisani yazib (222): ~3000 plan dersinden 311-de
--  20+ nisanli sual var.  Qapi HAMI UCUN BIRDEN yox, DERS-DERS acilir:
--  server her plan setri ucun deyir «ders testi mumkundur / yox».
--
--  NE DEYISIR
--    1) class_plan_items.fesil_test_id (yeni sutun): fesil testinin yeri.
--       Sebeb: feslin SON dersi hazir olanda eyni setirde HEM dersin oz testi,
--       HEM fesil testi ola biler; tek test_id ikisine catmirdi.
--       Kohne fesil testleri (adi «<fesil> — yoxlama») geri doldurulur.
--    2) rpc_plan_get: her setirde ders_hazir / ders_n / fesil_test_id.
--       Say app.ders_sual_sayi ile serverde hesablanir; hedd app.ders_min().
--    3) rpc_plan_test(uuid, int, text): ucuncu parametr 'ders' | 'fesil' |
--       null.  Iki parametrli cagiris (kohne brauzer) eyni isleyir - imza
--       deyismir, yalniz default-lu parametr elave olunur; kohne imza
--       silinir (PostgREST iki namized arasinda sece bilmir).
--
--  ON SERT: 135 (rpc_plan_get), 222 (app.ders_*), 223 (rpc_plan_test).
--  Sonra 05_grants lazim deyil - qrantlar faylin ozundedir.
-- =====================================================================

alter table public.class_plan_items
  add column if not exists fesil_test_id uuid references public.tests(id) on delete set null;

--  Kohne fesil testleri: feslin SON dersinde saxlanilib, adi «<fesil> — yoxlama».
--  Dersin oz testi «<ders> — yoxlama» adlanir - ferq adla ayrilir.
update public.class_plan_items i
   set fesil_test_id = i.test_id
  from public.topics t
  join public.topics par on par.id = t.parent_id
  join public.tests te   on true
 where t.id = i.topic_id
   and te.id = i.test_id
   and te.title = par.name || ' — yoxlama'
   and i.fesil_test_id is null
   and not exists (select 1 from public.class_plan_items i2
                     join public.topics t2 on t2.id = i2.topic_id
                    where i2.plan_id = i.plan_id and t2.parent_id = par.id
                      and i2.ord > i.ord);

create or replace function public.rpc_plan_get(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
begin
  return jsonb_build_object(
    'paid', app.has_active_subscription(v_class.account_id),
    'plans', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', p.id,
               'subject', s.name, 'subject_slug', s.slug,
               'level', l.name, 'level_code', l.code,
               --  'total'/'done' artiq DERS sayidir (yarpaq), fesil yox
               'total', (select count(*) from public.class_plan_items i
                          where i.plan_id = p.id),
               'done', (select count(*) from public.class_plan_items i
                         where i.plan_id = p.id and i.done_at is not null),
               'items', (select jsonb_agg(x order by x_ord) from (
                   select i.ord as x_ord, jsonb_build_object(
                     'id', i.id, 'ord', i.ord, 'topic', t.name,
                     'done', i.done_at is not null,
                     'done_at', i.done_at,
                     'test_id', i.test_id,
                     'warm_test_id', i.warm_test_id,
                     --  903: fesil testi ayrica saxlanir (dersin oz testi ile qarismasin)
                     'fesil_test_id', i.fesil_test_id,
                     --  903: DERS TESTI MUMKUNDURMU?  Say SERVERDE hesablanir, brauzer
                     --  saymir; hedd bir yerdedir (app.ders_min).  Hovuz rpc_plan_test
                     --  ile EYNI: fesil (ve ya fesilsiz movzuda ozu) + 'ders:<slug>' nisani.
                     'ders_n', case when t.slug is null or t.slug = '' then 0
                                    else app.ders_sual_sayi(coalesce(par.id, t.id), t.slug) end,
                     'ders_hazir', case when t.slug is null or t.slug = '' then false
                                    else app.ders_sual_sayi(coalesce(par.id, t.id), t.slug)
                                         >= app.ders_min() end,
                     --  fesil: valideyn varsa onun adi/id-si
                     'group',    par.name,
                     'group_id', par.id,
                     --  fesildeki YER: interfeys "2/5" yaza bilsin
                     'gpos', case when par.id is null then null else
                        (select count(*) from public.class_plan_items i2
                           join public.topics t2 on t2.id = i2.topic_id
                          where i2.plan_id = p.id and t2.parent_id = par.id
                            and i2.ord <= i.ord) end,
                     'gtotal', case when par.id is null then null else
                        (select count(*) from public.class_plan_items i2
                           join public.topics t2 on t2.id = i2.topic_id
                          where i2.plan_id = p.id and t2.parent_id = par.id) end,
                     --  "test yig" YALNIZ fesil bitende: fesilsiz
                     --  movzuda ozu, fesildə isə SON yarpaqda.
                     --  Sebeb: suallar fesle baglidir, alt movzunun
                     --  oz hovuzu yoxdur - hər alt movzuda teklif
                     --  etsek eyni testi bes defe yigardiq.
                     'can_test', i.done_at is not null and (
                        par.id is null or not exists (
                          select 1 from public.class_plan_items i3
                            join public.topics t3 on t3.id = i3.topic_id
                           where i3.plan_id = p.id and t3.parent_id = par.id
                             and i3.ord > i.ord)),
                     'avg', (select round(avg(a.percent))
                               from public.attempts a
                              where a.test_id = i.test_id
                                and a.status = 'submitted'),
                     'takers', (select count(distinct a.student_id)
                                  from public.attempts a
                                 where a.test_id = i.test_id
                                   and a.status = 'submitted')) as x
                     from public.class_plan_items i
                     join public.topics t on t.id = i.topic_id
                     left join public.topics par on par.id = t.parent_id
                    where i.plan_id = p.id) z)
             ) order by s.sort)
        from public.class_plans p
        join public.subjects s on s.id = p.subject_id
        join public.levels   l on l.id = p.level_id
       where p.class_id = p_class_id), '[]'::jsonb));
end $$;

-- ------------------------------------------------- plan testi
create or replace function public.rpc_plan_test(
  p_item_id uuid, p_count int default 15, p_scope text default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item   public.class_plan_items%rowtype;
  v_plan   public.class_plans%rowtype;
  v_topic  text;
  v_tid    uuid;
  v_slug   text;
  v_leaf   text;
  v_n      int := 0;
  v_ders   boolean := false;
  v_count  int;
  v_rule   jsonb;
  v_res    jsonb;
  v_test   uuid;
  v_excl   jsonb;
begin
  if p_scope is not null and p_scope not in ('ders', 'fesil') then
    raise exception 'Test hovzu ders ve ya fesil ola biler.' using errcode = '22023';
  end if;
  if p_count is null or p_count < 3 or p_count > 50 then
    raise exception 'Sual sayi 3-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_item from public.class_plan_items where id = p_item_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = v_item.plan_id;
  perform app.plan_class(v_plan.class_id);
  if v_item.done_at is null then
    raise exception 'Evvel movzunu "kecildi" isareleyin.' using errcode = '22023';
  end if;

  --  Hovuz VALIDEYNDEDIR (101).  Alt movzunun oz slug-u nisan ucundur.
  select coalesce(par.id, t.id), coalesce(par.name, t.name), t.slug, t.name
    into v_tid, v_topic, v_slug, v_leaf
    from public.topics t
    left join public.topics par on par.id = t.parent_id
   where t.id = v_item.topic_id;

  --  Nisanli sual yeterlidirse DERS testi, deyilse kohne kimi FESIL.
  if v_slug is not null and v_slug <> '' then
    v_n := app.ders_sual_sayi(v_tid, v_slug);
    v_ders := v_n >= app.ders_min();
  end if;

  --  903: hovuzu MUELLIM secir (dersin sirasindaki «test yig» ve fesil
  --  basligindaki «fesilden test yig» ayri dugmelerdir).  Yoxsa feslin SON
  --  dersi hazir olanda fesil basligi de ders testi yigardi.
  --    'ders'  - yalniz hazir (>= app.ders_min) dersde; hazir deyilse xeta,
  --              sessizce fesle dusmur (muellim «bu dersden» basdi)
  --    'fesil' - HEMISE fesil hovuzu, nisansiz
  --    null    - kohne davranis: hazirsa ders, deyilse fesil (kohne musteriler)
  if p_scope = 'ders' and not v_ders then
    raise exception 'Bu ders ucun hele kifayet qeder sual yoxdur (% / %).', v_n, app.ders_min()
      using errcode = '22023';
  end if;
  if p_scope = 'fesil' then v_ders := false; end if;

  --  223: bu qrupa SON 20 tapsiriqda verilmis suallar.  Hedd var ki,
  --  il boyu yigilan minlerle id massivi sismesin.  Bu, SERT suzgec
  --  deyil - generator onlari sadece novbede geri qoyur.
  select coalesce(jsonb_agg(distinct tq.question_id::text), '[]'::jsonb)
    into v_excl
    from (select a.test_id from public.assignments a
           where a.class_id = v_plan.class_id
           order by a.created_at desc limit 20) z
    join public.test_questions tq on tq.test_id = z.test_id;

  if v_ders then
    --  Ders testi qisadir; hovuzdan cox istemirik ki generator
    --  «N sual tapildi» xetasi atmasin.
    v_count := least(app.ders_test_count(), v_n);
    v_rule := jsonb_build_object(
      'pool', 'all',
      'count', v_count,
      'subject', (select slug from public.subjects where id = v_plan.subject_id),
      'level',   (select code from public.levels   where id = v_plan.level_id),
      'topics',  jsonb_build_array(v_tid::text),
      'tags',    jsonb_build_array(app.ders_tag(v_slug)),
      'exclude', v_excl);
    v_res := public.rpc_generate_test(v_rule, v_leaf || ' — yoxlama');
  else
    v_count := p_count;
    v_rule := jsonb_build_object(
      'pool', 'all',
      'count', v_count,
      'subject', (select slug from public.subjects where id = v_plan.subject_id),
      'level',   (select code from public.levels   where id = v_plan.level_id),
      'topics',  jsonb_build_array(v_tid::text),
      'exclude', v_excl);
    v_res := public.rpc_generate_test(v_rule, v_topic || ' — yoxlama');
  end if;

  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  if v_ders then
    --  dersin OZ testi: yalniz test_id.  fesil_test_id toxunulmaz qalir.
    update public.class_plan_items set test_id = v_test where id = p_item_id;
  else
    --  fesil testi: fesil_test_id-ye yazilir.  test_id yalniz bos ve ya evvelki
    --  FESIL testi olanda yenilenir - dersin oz testini pozmur.  (UPDATE-de sag
    --  teref kohne deyerleri gorur.)
    update public.class_plan_items
       set fesil_test_id = v_test,
           test_id = case when test_id is null or test_id = fesil_test_id
                          then v_test else test_id end
     where id = p_item_id;
  end if;

  --  'scope' interfeys ucundur: setir «dərs testi» yoxsa «fəsil
  --  testi» yigildigini yaza bilsin - muellim ne aldigini bilsin.
  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count',
                            'scope', case when v_ders then 'ders' else 'fesil' end,
                            'pool',  v_n);
end $$;

-- ------------------------------------------------- huquq
drop function if exists public.rpc_plan_test(uuid, int);
revoke all on function public.rpc_plan_test(uuid, int, text) from public, anon;
grant execute on function public.rpc_plan_test(uuid, int, text) to authenticated;
revoke all on function public.rpc_plan_get(uuid) from public, anon;
grant execute on function public.rpc_plan_get(uuid) to authenticated;
