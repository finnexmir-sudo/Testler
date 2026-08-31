-- =====================================================================
--  25_ders_plani.sql : DERS PLANI - "komekci isci"
--
--  Muellim qrupa fenn+sinif secir; sistem movzu agacini (real
--  derslik ardicilligi ile) plana cevirir.  Qrup sehifesinde:
--  irelileyis zolagi + CARI movzu + "Kecildi" duymesi.
--
--  ESAS PRINSIP: plan TARIXLE yox, ARDICILLIQLA yasayir.  Cari movzu
--  muellim "kecildi" demeyince deyismir - "geride qaldin" stressi yoxdur.
--
--  "Kecildi" basilan kimi UI teklif edir: "N sualliq yoxlama testi
--  yigilsinmi?" -> rpc_plan_test movcud generatoru isledir, testi
--  yaradir ve qrupa DERHAL tapsiriq kimi teyin edir (son tarix +7 gun,
--  1 cehd).  Sagird panelinde ozu gorunur - elave addim yoxdur.
--
--  PULLU: plan yaratmaq ve yoxlama testi abune paketine daxildir
--  (app.has_active_subscription).  Movcud plana baxis serbestdir -
--  abune bitse muellim iteceyini yox, kilidlenecayini gorur.
--
--  ON SERT: 01, 04 (topics), 09/10 (rpc_assign_test), 13 (generator).
--  SONRA:   05_grants.sql yeniden islet.
--  Tekrar isledile biler.
-- =====================================================================

do $$
begin
  if to_regprocedure('public.rpc_generate_test(jsonb, text, uuid, uuid)') is null
     or to_regprocedure('public.rpc_assign_test(uuid, uuid, timestamptz, int)') is null then
    raise exception 'ONCE 13_generator.sql ve 09/10 (tapsiriqlar) islenmelidir.';
  end if;
end $$;

-- ------------------------------------------------------------ cedveller
create table if not exists public.class_plans (
  id         uuid primary key default gen_random_uuid(),
  class_id   uuid not null references public.classes(id)  on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  level_id   uuid not null references public.levels(id)   on delete restrict,
  created_at timestamptz not null default now(),
  --  bir qrupda her fennden bir plan (riyaziyyat + az dili ola biler)
  unique (class_id, subject_id)
);

create table if not exists public.class_plan_items (
  id       uuid primary key default gen_random_uuid(),
  plan_id  uuid not null references public.class_plans(id) on delete cascade,
  topic_id uuid not null references public.topics(id) on delete cascade,
  ord      int  not null,
  done_at  timestamptz,
  --  "kecildi"den sonra yigilan yoxlama testi (varsa)
  test_id  uuid references public.tests(id) on delete set null,
  unique (plan_id, topic_id),
  unique (plan_id, ord)
);

create index if not exists idx_cpi_plan on public.class_plan_items(plan_id, ord);

alter table public.class_plans      enable row level security;
alter table public.class_plan_items enable row level security;
--  Siyaset yoxdur - yalniz definer RPC-ler toxunur.

-- ------------------------------------------------- komekci: qrup yoxlanisi
--  Qrup movcuddur ve cagiran muellim onun hesabinin uzvudur.
create or replace function app.plan_class(p_class uuid)
returns public.classes
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v public.classes%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  select * into v from public.classes where id = p_class;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v.teacher_id <> auth.uid() and not app.is_account_member(v.account_id) then
    raise exception 'Bu qrup sizin deyil.' using errcode = '42501';
  end if;
  return v;
end $$;

-- ------------------------------------------------- plan yaratmaq
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
  select l.id into v_lev from public.levels l
   where l.code = p_level order by l.sort limit 1;
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

  --  movzu agaci onsuz da real derslik ardicilligi iledir (sort)
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan, t.id, row_number() over (order by t.sort, t.name)
    from public.topics t
   where t.subject_id = v_subj and t.level_id = v_lev;
  get diagnostics v_n = row_count;

  if v_n = 0 then
    delete from public.class_plans where id = v_plan;
    raise exception 'Bu fenn ve sinif ucun movzu agaci hele yoxdur.'
      using errcode = '22023';
  end if;

  return jsonb_build_object('ok', true, 'plan_id', v_plan, 'topics', v_n);
end $$;

-- ------------------------------------------------- plani silmek
create or replace function public.rpc_plan_delete(p_plan_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_class uuid;
begin
  select class_id into v_class from public.class_plans where id = p_plan_id;
  if v_class is null then
    raise exception 'Plan tapilmadi.' using errcode = '22023';
  end if;
  perform app.plan_class(v_class);
  delete from public.class_plans where id = p_plan_id;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- qrupun planlari
--  Baxis abunesiz de mumkundur (plan itmir, kilidlenir) - amma
--  'paid' bayragi UI-a deyir ki, emeliyyatlar acibmi.
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
               'total', (select count(*) from public.class_plan_items i
                          where i.plan_id = p.id),
               'done', (select count(*) from public.class_plan_items i
                         where i.plan_id = p.id and i.done_at is not null),
               --  'avg'/'takers': movzu testinin qrup neticesi - plan
               --  adaptiv olsun: zeif cixan movzu setirde qirmizi gorunur
               'items', (select jsonb_agg(jsonb_build_object(
                          'id', i.id, 'ord', i.ord, 'topic', t.name,
                          'done', i.done_at is not null,
                          'done_at', i.done_at,
                          'test_id', i.test_id,
                          'avg', (select round(avg(a.percent))
                                    from public.attempts a
                                   where a.test_id = i.test_id
                                     and a.status = 'submitted'),
                          'takers', (select count(distinct a.student_id)
                                       from public.attempts a
                                      where a.test_id = i.test_id
                                        and a.status = 'submitted')) order by i.ord)
                          from public.class_plan_items i
                          join public.topics t on t.id = i.topic_id
                         where i.plan_id = p.id)
             ) order by s.sort)
        from public.class_plans p
        join public.subjects s on s.id = p.subject_id
        join public.levels   l on l.id = p.level_id
       where p.class_id = p_class_id), '[]'::jsonb));
end $$;

-- ------------------------------------------------- "kecildi"
--  Yalniz CARI movzu (done olmayan en kicik ord) kecile biler -
--  tesadufi klikle plan qarismasin.
create or replace function public.rpc_plan_done(p_item_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item public.class_plan_items%rowtype;
  v_plan public.class_plans%rowtype;
  v_cur  uuid;
begin
  select * into v_item from public.class_plan_items where id = p_item_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = v_item.plan_id;
  perform app.plan_class(v_plan.class_id);
  if not app.has_active_subscription(
       (select account_id from public.classes where id = v_plan.class_id)) then
    raise exception 'Ders plani abune paketine daxildir.' using errcode = '42501';
  end if;

  select id into v_cur from public.class_plan_items
   where plan_id = v_item.plan_id and done_at is null
   order by ord limit 1;
  if v_cur is distinct from p_item_id then
    raise exception 'Yalniz cari movzu kecile biler.' using errcode = '22023';
  end if;

  update public.class_plan_items set done_at = now() where id = p_item_id;
  return jsonb_build_object('ok', true);
end $$;

--  Sehv klik ucun geri qaytarma - yalniz SON kecilmis movzu.
create or replace function public.rpc_plan_undo(p_item_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item public.class_plan_items%rowtype;
  v_last uuid;
begin
  select * into v_item from public.class_plan_items where id = p_item_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  perform app.plan_class(
    (select class_id from public.class_plans where id = v_item.plan_id));

  select id into v_last from public.class_plan_items
   where plan_id = v_item.plan_id and done_at is not null
   order by ord desc limit 1;
  if v_last is distinct from p_item_id then
    raise exception 'Yalniz son kecilmis movzu geri qaytarila biler.'
      using errcode = '22023';
  end if;

  update public.class_plan_items set done_at = null where id = p_item_id;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- yoxlama testi
--  "Kecildi"den sonraki teklif: movcud generator hemin movzudan
--  balansli, tekrarsiz test yigir ve qrupa DERHAL tapsiriq verir
--  (son tarix +7 gun, 1 cehd).  Muellim isterse veraqden deyisir.
create or replace function public.rpc_plan_test(
  p_item_id uuid, p_count int default 15)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item  public.class_plan_items%rowtype;
  v_plan  public.class_plans%rowtype;
  v_topic text;
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

  select t.name into v_topic from public.topics t where t.id = v_item.topic_id;

  v_rule := jsonb_build_object(
    'pool', 'all',
    'count', p_count,
    'subject', (select slug from public.subjects where id = v_plan.subject_id),
    'level',   (select code from public.levels   where id = v_plan.level_id),
    'topics',  jsonb_build_array(v_item.topic_id::text));

  --  generator abuneni ozu yoxlayir ('all' hovuzu pullu qapidir)
  v_res  := public.rpc_generate_test(v_rule, v_topic || ' — yoxlama');
  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  update public.class_plan_items set test_id = v_test where id = p_item_id;

  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count');
end $$;

-- ------------------------------------------------- birge yoxlama testi
--  Bir nece KECILMIS movzudan QARISIQ test: "Sonra" deyilib sonradan
--  yigan, ve ya 2-3 movzunu birden yoxlamaq isteyen muellim ucun.
--  Test item-lere baglanmir (movzu-test elaqesi tek movzuludur) -
--  veraq ve neticeler Tapsiriqlar bolmesinde gorunur.
create or replace function public.rpc_plan_test_multi(
  p_item_ids uuid[], p_count int default 15)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_ids    uuid[];
  v_n      int;
  v_plan   public.class_plans%rowtype;
  v_topics jsonb;
  v_rule   jsonb;
  v_res    jsonb;
  v_test   uuid;
begin
  if p_count is null or p_count < 3 or p_count > 50 then
    raise exception 'Sual sayi 3-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select array_agg(distinct x) into v_ids from unnest(p_item_ids) x;
  v_n := coalesce(array_length(v_ids, 1), 0);
  if v_n < 2 then
    raise exception 'En azi 2 movzu secin.' using errcode = '22023';
  end if;
  if (select count(*) from public.class_plan_items where id = any(v_ids)) <> v_n then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  if (select count(distinct plan_id)
        from public.class_plan_items where id = any(v_ids)) <> 1 then
    raise exception 'Movzular eyni plandan olmalidir.' using errcode = '22023';
  end if;

  select p.* into v_plan
    from public.class_plans p
    join public.class_plan_items i on i.plan_id = p.id
   where i.id = v_ids[1];
  perform app.plan_class(v_plan.class_id);

  if exists (select 1 from public.class_plan_items
              where id = any(v_ids) and done_at is null) then
    raise exception 'Yalniz kecilmis movzulardan test yigilir.'
      using errcode = '22023';
  end if;

  select jsonb_agg(topic_id::text) into v_topics
    from public.class_plan_items where id = any(v_ids);

  v_rule := jsonb_build_object(
    'pool', 'all',
    'count', p_count,
    'subject', (select slug from public.subjects where id = v_plan.subject_id),
    'level',   (select code from public.levels   where id = v_plan.level_id),
    'topics',  v_topics);

  --  generator abuneni ozu yoxlayir ('all' hovuzu pullu qapidir)
  v_res  := public.rpc_generate_test(
    v_rule,
    (select name from public.subjects where id = v_plan.subject_id) ||
      ' — qarışıq yoxlama (' || v_n || ' mövzu)');
  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count');
end $$;

-- ------------------------------------------------- plan seçimləri
--  Formada YALNIZ movzu agaci olan fenn+sinif kombinasiyalari
--  gorunsun - "Kurikulum" kimi agacsiz fenni secib xeta almaq
--  olmasin.  Agac genislendikce siyahi ozu boyuyur.
create or replace function public.rpc_plan_options()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'slug', z.slug, 'name', z.name, 'levels', z.levels)
           order by z.sort)
    from (
      select s.slug, s.name, s.sort,
             jsonb_agg(jsonb_build_object('code', l.code, 'name', l.name)
                       order by l.sort) as levels
        from (select distinct t.subject_id, t.level_id
                from public.topics t
               where t.level_id is not null) x
        join public.subjects s on s.id = x.subject_id
        join public.levels   l on l.id = x.level_id
       group by s.slug, s.name, s.sort) z), '[]'::jsonb);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_plan_options()                from public, anon;
revoke all on function public.rpc_plan_create(uuid, text, text) from public, anon;
revoke all on function public.rpc_plan_delete(uuid)             from public, anon;
revoke all on function public.rpc_plan_get(uuid)                from public, anon;
revoke all on function public.rpc_plan_done(uuid)               from public, anon;
revoke all on function public.rpc_plan_undo(uuid)               from public, anon;
revoke all on function public.rpc_plan_test(uuid, int)          from public, anon;
revoke all on function public.rpc_plan_test_multi(uuid[], int)  from public, anon;

grant execute on function public.rpc_plan_options()                to authenticated;
grant execute on function public.rpc_plan_create(uuid, text, text) to authenticated;
grant execute on function public.rpc_plan_delete(uuid)             to authenticated;
grant execute on function public.rpc_plan_get(uuid)                to authenticated;
grant execute on function public.rpc_plan_done(uuid)               to authenticated;
grant execute on function public.rpc_plan_undo(uuid)               to authenticated;
grant execute on function public.rpc_plan_test(uuid, int)          to authenticated;
grant execute on function public.rpc_plan_test_multi(uuid[], int)  to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_plan_create(uuid, text, text)', 'EXECUTE') then
    raise exception 'anon plan yarada bilir!';
  end if;
  raise notice 'Ders plani quruldu.';
end $$;
