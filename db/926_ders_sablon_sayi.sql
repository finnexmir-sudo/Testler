-- =====================================================================
--  926 : SABLON (parametrik) SUAL DERS QAPISINDA 2 SUAL SAYILIR (2026-10-08)
--
--  NIYE
--  Riyaziyyatda sablon suallar bank fayllarina gelir (bir sablon = her
--  sagirdde ferqli reqem, cavab ezberlenmir).  Dersin «hazirdir» qapisi
--  (app.ders_min = 20) indiye qeder setir sayirdi: bir sablon sual 1 sayilirdi.
--  Istifadeci razi: SABLON SUAL QAPIDA 2 SUAL SAYILIR.
--
--  NE DEYISIR
--    1) app.ders_sual_sayi: count(*)  ->  sum(case when q.params is not null then 2 else 1 end).
--       Qapi VE rpc_plan_get.ders_n / ders_hazir bunu oxuyur (903) - basqa yer yoxdur.
--    2) app.ders_sual_setir (YENI): FERQLI setir sayi (hamisi 1).  Bir testde bir sual
--       BIR defe cixir; sablon sual testde de bir setirdir.
--    3) rpc_plan_test (903-un tam govdesi + 2 setir): ders testinin sual sayi
--       least(app.ders_test_count(), SETIR sayi) - cekili sayi yox.  Cekili say
--       setirden boyukdur; ona esaslansaq generator «kifayet sual yoxdur» xetasi atardi.
--       (hedd 20 oldugu ucun setir >= 10 = test olcusu; qoruyucu hedd/olcu deyisse isleyir.)
--
--  DIQQET: app.ders_min() DEYISMIR (20).  Muellimin OZ suallari sayilmir (222).
--  ON SERT: 222 (app.ders_*), 903 (rpc_plan_test/rpc_plan_get).   Tekrar isledile biler.
-- =====================================================================

create or replace function app.ders_sual_sayi(p_fesil uuid, p_slug text)
returns int
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select coalesce(sum(case when q.params is not null then 2 else 1 end), 0)::int
    from public.questions q
   where q.topic_id = p_fesil
     and q.owner_type = 'platform'
     and q.status = 'published'
     and q.tags @> array[app.ders_tag(p_slug)]
$$;

create or replace function app.ders_sual_setir(p_fesil uuid, p_slug text)
returns int
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select count(*)::int
    from public.questions q
   where q.topic_id = p_fesil
     and q.owner_type = 'platform'
     and q.status = 'published'
     and q.tags @> array[app.ders_tag(p_slug)]
$$;
revoke all on function app.ders_sual_sayi(uuid, text)  from public, anon, authenticated;
revoke all on function app.ders_sual_setir(uuid, text) from public, anon, authenticated;

-- ------------------------------------------------- plan testi (903-den kopya + 926)
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
  v_n      int := 0;            -- 926: CEKILI say (sablon sual = 2) - yalniz QAPI ucun
  v_rows   int := 0;            -- 926: FERQLI setir sayi - TEST OLCUSU bundan boyuk ola bilmez
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
    v_rows := app.ders_sual_setir(v_tid, v_slug);
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
    --  926: sablon sual qapida 2 sayilir, amma testde BIR defe cixir (bir sual = bir setir).
    --  Ona gore test olcusu CEKILI saydan yox, FERQLI setir sayindan boyuk ola bilmez.
    v_count := least(app.ders_test_count(), v_rows);
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
                            'pool',  v_n,
                            'rows',  v_rows);
end $$;

drop function if exists public.rpc_plan_test(uuid, int);
revoke all on function public.rpc_plan_test(uuid, int, text) from public, anon;
grant execute on function public.rpc_plan_test(uuid, int, text) to authenticated;
