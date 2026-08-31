-- =====================================================================
--  101_ders_plani_alt.sql — dərs planı iki səviyyəli olur
--
--  NIYE
--  Plan indiyedek yalniz movzu BASLIQLARINI sayirdi: "2 / 11 movzu".
--  Amma "Kvadrat tenlikler" bir ders deyil - derslikde onun altinda
--  4-5 alt movzu var, yeni ~bir hefteликdir.  Muellim onun iki dersini
--  kecende bunu qeyd ede bilmirdi: ya hamisini "kecildi" edirdi
--  (yalan), ya hec ne.  Alt movzular plani REAL DERS RITMI ile
--  ust-uste salir ve faiz durust olur.
--
--  MODEL: PLAN SETIRI = YARPAQ
--  Plan setirleri yalniz YARPAQ movzulardan qurulur:
--    - alt movzusu OLAN basliq setir DEYIL, yalniz qruplasdirici etiketdir;
--    - alt movzusu OLMAYAN basliq ozu yarpaqdir (bugunku davranis).
--  Bele olanda:
--    - rpc_plan_done-un "yalniz cari setir" mentiqi oldugu kimi qalir;
--    - unique (plan_id, ord) tebii sekilde islyir;
--    - "N/M" real DERS sayidir, fesil sayi yox.
--  Basliq DB-de setir kimi saxlanilmir - oxu funksiyasi onu
--  topics.parent_id-den TOREDIR.  Yeni sutun, yeni cedvel yoxdur.
--
--  "TEST YIG" HARADA QALIR
--  Suallar BASLIGA baglidir, alt movzunun oz sualı yoxdur.  Ona gore
--  her alt movzuda "test yig" teklif etsek, bes alt movzu eyni
--  hovuzdan demek olar eyni testi yigardi - bos ved.
--  Duz yol: duyme fesil BITENDE cixir - yeni qrupun SON yarpagi
--  kecilende.  Pedaqoji olaraq da dogrudur (fesil bitdi -> yoxlama).
--  rpc_plan_test o zaman VALIDEYNIN movzusundan yigir.
--
--  GERIYE UYGUNLUQ
--  Bazada hec bir alt movzu yoxdursa (bu gunku hal), butun basliqlar
--  yarpaqdir ve davranis HERFEN eskisi kimidir.  Ona gore bu fayl
--  alt movzu setirlerinden EVVEL de tehlukesiz tetbiq olunur.
--  Movcud planlar toxunulmur - onlar oz setirleri ile isleyir;
--  muellim isteyerse plani silib yeniden yaradir.
-- =====================================================================

-- --------------------------------------------------- plan yaradilmasi
create or replace function public.rpc_plan_create(
  p_class_id uuid, p_subject text, p_level text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
  v_subj  uuid;
  v_lev   uuid;
  v_plan  uuid;
  v_n     int;
begin
  if not app.has_active_subscription(v_class.account_id) then
    raise exception 'Ders plani abune paketine daxildir.' using errcode = '42501';
  end if;

  select id into v_subj from public.subjects where slug = p_subject;
  if v_subj is null then
    raise exception 'Fenn tapilmadi.' using errcode = '22023';
  end if;
  --  Reqem kodlu sinifler uzre kod TEKDIR (db/31 indeksi) - "limit 1"
  --  artiq ikimenali deyil, yene de sertlə saxlanilir.
  select l.id into v_lev from public.levels l
   where l.code = p_level and l.code ~ '^[0-9]+$'
   order by l.sort limit 1;
  if v_lev is null then
    raise exception 'Sinif tapilmadi.' using errcode = '22023';
  end if;
  if exists (select 1 from public.class_plans
              where class_id = p_class_id and subject_id = v_subj) then
    raise exception 'Bu qrupda hemin fennin plani artiq var.'
      using errcode = '22023';
  end if;

  insert into public.class_plans (class_id, subject_id, level_id)
  values (p_class_id, v_subj, v_lev)
  returning id into v_plan;

  --  YARPAQLAR: ovladi olmayan movzular.  Siralama agac sirasi ile -
  --  evvelce fesil (valideynin sort-u), sonra fesil daxilinde alt
  --  movzunun sort-u.  Fesilsiz movzuda valideyn yoxdur, ozu esas gotur.
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan, t.id,
         row_number() over (order by coalesce(par.sort, t.sort),
                                     coalesce(par.name, t.name),
                                     t.sort, t.name)
    from public.topics t
    left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_subj
     and t.level_id   = v_lev
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  get diagnostics v_n = row_count;

  if v_n = 0 then
    delete from public.class_plans where id = v_plan;
    raise exception 'Bu fenn ve sinif ucun movzu agaci hele yoxdur.'
      using errcode = '22023';
  end if;

  return jsonb_build_object('ok', true, 'plan_id', v_plan, 'topics', v_n);
end $$;

-- ------------------------------------------------------- plani oxumaq
--  Her setire fesil melumati elave olunur ki, interfeys agac kimi
--  yigib gostere bilsin.  Fesil DB-de setir deyil - burada torenir.
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

-- ------------------------------------------------------ yoxlama testi
--  Yeganə deyisiklik: suallar VALIDEYN movzudan goturulur (alt
--  movzunun oz sualı yoxdur).  Qalan hər şey 25-dekinin eynidir.
create or replace function public.rpc_plan_test(
  p_item_id uuid, p_count int default 15)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item  public.class_plan_items%rowtype;
  v_plan  public.class_plans%rowtype;
  v_topic text;
  v_tid   uuid;
  v_rule  jsonb;
  v_res   jsonb;
  v_test  uuid;
begin
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

  --  Alt movzudursa hovuz VALIDEYNDEDIR.  Ad da valideynden gotur:
  --  "Kvadrat tenlikler — yoxlama" muellime "Tam kvadrat ayirmaqla
  --  kvadrat tenliklerin helli — yoxlama"dan daha aydindir.
  select coalesce(par.id, t.id), coalesce(par.name, t.name)
    into v_tid, v_topic
    from public.topics t
    left join public.topics par on par.id = t.parent_id
   where t.id = v_item.topic_id;

  v_rule := jsonb_build_object(
    'pool', 'all',
    'count', p_count,
    'subject', (select slug from public.subjects where id = v_plan.subject_id),
    'level',   (select code from public.levels   where id = v_plan.level_id),
    'topics',  jsonb_build_array(v_tid::text));

  --  generator abuneni ozu yoxlayir ('all' hovuzu pullu qapidir)
  v_res  := public.rpc_generate_test(v_rule, v_topic || ' — yoxlama');
  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  update public.class_plan_items set test_id = v_test where id = p_item_id;

  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count');
end $$;

-- --------------------------------------------------------------- huquq
revoke all on function public.rpc_plan_create(uuid, text, text) from public, anon;
revoke all on function public.rpc_plan_get(uuid)                from public, anon;
revoke all on function public.rpc_plan_test(uuid, int)          from public, anon;

grant execute on function public.rpc_plan_create(uuid, text, text) to authenticated;
grant execute on function public.rpc_plan_get(uuid)                to authenticated;
grant execute on function public.rpc_plan_test(uuid, int)          to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_plan_get(uuid)', 'EXECUTE') then
    raise exception 'anon ders planini gore bilir';
  end if;
  if has_function_privilege('anon',
      'public.rpc_plan_create(uuid, text, text)', 'EXECUTE') then
    raise exception 'anon plan yarada bilir';
  end if;
  raise notice 'Ders plani iki seviyyeli oldu: setirler yarpaqdir, fesil torenir.';
end $$;
