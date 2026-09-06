-- =====================================================================
--  135_kurikulum_paketi.sql : kurikulum paketi - "hazir il" (yol xeritesi 22.d)
--
--  Ders planinin her movzusu ucun hazir uc parca, bir toxunusla:
--    isinme      5 asan/orta sual, dersden EVVEL (movzu hele kecilmeyib),
--                1 gun, 1 cehd - dersin evvelinde 5 deqiqe
--    ev tapsirigi 10 sual "Kecildi"den sonra (movcud rpc_plan_test)
--    rub sinagi  son sinaqdan beri kecilmis movzulardan 20 sual, 7 gun
--  Hamisi movcud generator (rpc_generate_test) ve teyinat (rpc_assign_test)
--  uzerindedir; abune generatorun ozunde yoxlanir.
--
--  class_plan_items.warm_test_id - isinme testi (test_id ev tapsirigidir).
--  plan_exams - hansi sinaq hansi movzulari ehate edib (novbeti sinaq
--  "son sinaqdan beri" movzulari goturur).
-- =====================================================================

alter table public.class_plan_items
  add column if not exists warm_test_id uuid references public.tests(id) on delete set null;

create table if not exists public.plan_exams (
  id         uuid primary key default gen_random_uuid(),
  plan_id    uuid not null references public.class_plans(id) on delete cascade,
  test_id    uuid not null references public.tests(id) on delete cascade,
  item_ids   uuid[] not null default '{}',
  created_at timestamptz not null default now()
);
create index if not exists idx_plan_exams_plan on public.plan_exams (plan_id, created_at desc);
alter table public.plan_exams enable row level security;
revoke all on public.plan_exams from public, anon, authenticated;

--  movzunun hovuzu: alt movzudursa valideyn (suallar fesle baglidir)
create or replace function app.pack_topic(p_topic uuid, out o_id uuid, out o_name text)
language sql stable as $$
  select coalesce(par.id, t.id), coalesce(par.name, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.id = p_topic
$$;
revoke all on function app.pack_topic(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Isinme: 5 asan/orta sual, dersden evvel, 1 gun, 1 cehd
-- ---------------------------------------------------------------------
create or replace function public.rpc_pack_warm(p_item_id uuid, p_count int default 5)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_item public.class_plan_items%rowtype;
  v_plan public.class_plans%rowtype;
  tp     record;
  v_rule jsonb;
  v_res  jsonb;
  v_test uuid;
begin
  if p_count is null or p_count < 3 or p_count > 20 then
    raise exception 'Isinme 3-20 sual olar.' using errcode = '22023';
  end if;
  select * into v_item from public.class_plan_items where id = p_item_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = v_item.plan_id;
  perform app.plan_class(v_plan.class_id);
  if v_item.warm_test_id is not null then
    raise exception 'Bu movzunun isinmesi artiq yigilib.' using errcode = '22023';
  end if;
  select * into tp from app.pack_topic(v_item.topic_id);

  v_rule := jsonb_build_object(
    'pool', 'all', 'count', p_count,
    'subject', (select slug from public.subjects where id = v_plan.subject_id),
    'level',   (select code from public.levels   where id = v_plan.level_id),
    'topics',  jsonb_build_array(tp.o_id::text),
    'difficulty', jsonb_build_array('1', '2'),
    'pack', 'warm');
  v_res  := public.rpc_generate_test(v_rule, 'İsinmə — ' || tp.o_name);
  v_test := (v_res->>'test_id')::uuid;
  perform public.rpc_assign_test(v_plan.class_id, v_test, now() + interval '1 day', 1);
  update public.class_plan_items set warm_test_id = v_test where id = p_item_id;
  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', v_res->>'count');
end $$;
revoke all on function public.rpc_pack_warm(uuid, int) from public, anon;
grant execute on function public.rpc_pack_warm(uuid, int) to authenticated;

-- ---------------------------------------------------------------------
--  Rub sinagi: son sinaqdan beri kecilmis movzular (p_all = hamisi), 7 gun
-- ---------------------------------------------------------------------
create or replace function public.rpc_pack_exam(p_plan_id uuid, p_count int default 20,
                                                p_all boolean default false)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_plan  public.class_plans%rowtype;
  v_ids   uuid[];
  v_top   jsonb;
  v_n     int;
  v_rule  jsonb;
  v_res   jsonb;
  v_test  uuid;
  v_subj  text;
begin
  if p_count is null or p_count < 5 or p_count > 50 then
    raise exception 'Sinaq 5-50 sual olar.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = p_plan_id;
  if not found then
    raise exception 'Plan tapilmadi.' using errcode = '22023';
  end if;
  perform app.plan_class(v_plan.class_id);

  select array_agg(i.id order by i.ord) into v_ids
    from public.class_plan_items i
   where i.plan_id = p_plan_id and i.done_at is not null
     and (p_all or not exists (select 1 from public.plan_exams e
                                where e.plan_id = p_plan_id and i.id = any(e.item_ids)));
  v_n := coalesce(array_length(v_ids, 1), 0);
  if v_n = 0 then
    raise exception 'Sinaq ucun kecilmis movzu yoxdur.' using errcode = '22023';
  end if;
  select jsonb_agg(distinct tp.o_id::text) into v_top
    from unnest(v_ids) x
    join public.class_plan_items i on i.id = x
    cross join lateral app.pack_topic(i.topic_id) tp;

  select s.name into v_subj from public.subjects s where s.id = v_plan.subject_id;
  v_rule := jsonb_build_object(
    'pool', 'all', 'count', p_count,
    'subject', (select slug from public.subjects where id = v_plan.subject_id),
    'level',   (select code from public.levels   where id = v_plan.level_id),
    'topics',  v_top,
    'pack', 'exam', 'plan', p_plan_id::text);
  v_res  := public.rpc_generate_test(v_rule, 'Rüb sınağı — ' || v_subj || ' · ' || v_n || ' mövzu');
  v_test := (v_res->>'test_id')::uuid;
  perform public.rpc_assign_test(v_plan.class_id, v_test, now() + interval '7 days', 1);
  insert into public.plan_exams (plan_id, test_id, item_ids) values (p_plan_id, v_test, v_ids);
  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', v_res->>'count', 'items', v_n);
end $$;
revoke all on function public.rpc_pack_exam(uuid, int, boolean) from public, anon;
grant execute on function public.rpc_pack_exam(uuid, int, boolean) to authenticated;

-- ---------------------------------------------------------------------
--  Paket ekrani: plan uzre her movzunun uc parcasi ve sinaqlar
-- ---------------------------------------------------------------------
create or replace function public.rpc_pack_get(p_plan_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_plan public.class_plans%rowtype;
  v_cls  public.classes%rowtype;
begin
  select * into v_plan from public.class_plans where id = p_plan_id;
  if not found then
    raise exception 'Plan tapilmadi.' using errcode = '22023';
  end if;
  v_cls := app.plan_class(v_plan.class_id);
  return jsonb_build_object(
    'plan', jsonb_build_object(
      'id', v_plan.id, 'class_id', v_plan.class_id, 'class', v_cls.name,
      'subject', (select name from public.subjects where id = v_plan.subject_id),
      'level',   (select name from public.levels   where id = v_plan.level_id),
      'total',   (select count(*) from public.class_plan_items i where i.plan_id = v_plan.id),
      'done',    (select count(*) from public.class_plan_items i where i.plan_id = v_plan.id and i.done_at is not null)),
    'paid', app.has_active_subscription(v_cls.account_id),
    'students', (select count(*) from public.students s where s.class_id = v_plan.class_id and s.is_active),
    --  son sinaqdan beri kecilmis, sinaga dusmemis movzular
    'exam_pending', (select count(*) from public.class_plan_items i
                      where i.plan_id = v_plan.id and i.done_at is not null
                        and not exists (select 1 from public.plan_exams e
                                         where e.plan_id = v_plan.id and i.id = any(e.item_ids))),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'ord', i.ord, 'topic', t.name, 'group', par.name,
               'done', i.done_at is not null, 'done_at', i.done_at,
               'warm', case when i.warm_test_id is null then null else jsonb_build_object(
                 'test_id', i.warm_test_id,
                 'avg', (select round(avg(a.percent)) from public.attempts a where a.test_id = i.warm_test_id and a.status = 'submitted'),
                 'takers', (select count(distinct a.student_id) from public.attempts a where a.test_id = i.warm_test_id and a.status = 'submitted')) end,
               'hw', case when i.test_id is null then null else jsonb_build_object(
                 'test_id', i.test_id,
                 'avg', (select round(avg(a.percent)) from public.attempts a where a.test_id = i.test_id and a.status = 'submitted'),
                 'takers', (select count(distinct a.student_id) from public.attempts a where a.test_id = i.test_id and a.status = 'submitted')) end,
               'examined', exists (select 1 from public.plan_exams e where e.plan_id = v_plan.id and i.id = any(e.item_ids))
             ) order by i.ord)
        from public.class_plan_items i
        join public.topics t on t.id = i.topic_id
        left join public.topics par on par.id = t.parent_id
       where i.plan_id = v_plan.id), '[]'::jsonb),
    'exams', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', e.id, 'test_id', e.test_id, 'title', ts.title,
               'items', cardinality(e.item_ids), 'created_at', e.created_at,
               'questions', (select count(*) from public.test_questions tq where tq.test_id = e.test_id),
               'avg', (select round(avg(a.percent)) from public.attempts a where a.test_id = e.test_id and a.status = 'submitted'),
               'takers', (select count(distinct a.student_id) from public.attempts a where a.test_id = e.test_id and a.status = 'submitted')
             ) order by e.created_at desc)
        from public.plan_exams e join public.tests ts on ts.id = e.test_id
       where e.plan_id = v_plan.id), '[]'::jsonb));
end $$;
revoke all on function public.rpc_pack_get(uuid) from public, anon;
grant execute on function public.rpc_pack_get(uuid) to authenticated;

-- rpc_lesson_prep (esas: 126): novbeti movzunun isinmesi, plan_id
create or replace function public.rpc_lesson_prep(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_class public.classes%rowtype := app.plan_class(p_class_id);
  v_plan  public.class_plans%rowtype;
  v_next  jsonb;
  v_last  jsonb;
  v_pend  jsonb;
  v_open  int;
begin
  --  Qrupun plani (bir qrupda bir nece fenn plani ola biler - en son
  --  islenen: son "kecildi" tarixi, yoxsa yaranma tarixi)
  select p.* into v_plan
    from public.class_plans p
   where p.class_id = p_class_id
   order by (select max(i.done_at) from public.class_plan_items i
              where i.plan_id = p.id) desc nulls last,
            p.created_at desc
   limit 1;

  if v_plan.id is not null then
    --  novbeti = ilk kecilmemis ders
    select jsonb_build_object(
             'item_id',  i.id,
             'topic',    t.name,
             'topic_id', coalesce(par.id, t.id),
             'group',    par.name,
             --  135: isinme testi
             'warm_test_id', i.warm_test_id,
             'warm_avg', (select round(avg(a.percent)) from public.attempts a where a.test_id = i.warm_test_id and a.status = 'submitted'),
             'warm_takers', (select count(distinct a.student_id) from public.attempts a where a.test_id = i.warm_test_id and a.status = 'submitted'),
             'gpos', case when par.id is null then null else
                       (select count(*) from public.class_plan_items i2
                          join public.topics t2 on t2.id = i2.topic_id
                         where i2.plan_id = v_plan.id and t2.parent_id = par.id
                           and i2.ord <= i.ord) end,
             'gtotal', case when par.id is null then null else
                       (select count(*) from public.class_plan_items i2
                          join public.topics t2 on t2.id = i2.topic_id
                         where i2.plan_id = v_plan.id and t2.parent_id = par.id) end)
      into v_next
      from public.class_plan_items i
      join public.topics t on t.id = i.topic_id
      left join public.topics par on par.id = t.parent_id
     where i.plan_id = v_plan.id and i.done_at is null
     order by i.ord limit 1;

    --  son kecilen = done_at en boyuk; testi varsa ortalama
    select jsonb_build_object(
             'item_id',  i.id,
             'topic',    t.name,
             'topic_id', coalesce(par.id, t.id),
             'group',    par.name,
             'done_at',  i.done_at,
             'test_id',  i.test_id,
             'avg', (select round(avg(a.percent)) from public.attempts a
                      where a.test_id = i.test_id and a.status = 'submitted'),
             'takers', (select count(distinct a.student_id) from public.attempts a
                         where a.test_id = i.test_id and a.status = 'submitted'))
      into v_last
      from public.class_plan_items i
      join public.topics t on t.id = i.topic_id
      left join public.topics par on par.id = t.parent_id
     where i.plan_id = v_plan.id and i.done_at is not null
     order by i.done_at desc, i.ord desc limit 1;
  end if;

  --  Acıq teyinatlar: bu qrupa (hamiya ve ya ferdi) verilmis, vaxti
  --  bitmemis; sagird hele submit etmeyibse "etmeyib" sayilir
  select count(*) into v_open
    from public.assignments a
   where a.class_id = p_class_id and app.assignment_open(a.*);

  select coalesce(jsonb_agg(jsonb_build_object(
           'student_id', z.id, 'name', z.full_name, 'n', z.n,
           'tests', z.tests) order by z.n desc, z.full_name), '[]'::jsonb)
    into v_pend
    from (
      select s.id, s.full_name, count(*) n,
             jsonb_agg(t.title order by a.closes_at nulls last, t.title) tests
        from public.students s
        join public.assignments a on a.class_id = s.class_id
                                 and (a.student_id is null or a.student_id = s.id)
                                 and app.assignment_open(a.*)
        join public.tests t on t.id = a.test_id
       where s.class_id = p_class_id and s.is_active
         and not exists (select 1 from public.attempts at
                          where at.student_id = s.id and at.test_id = a.test_id
                            and at.status = 'submitted')
       group by s.id, s.full_name
    ) z;

  return jsonb_build_object(
    'paid',     app.has_active_subscription(v_class.account_id),
    'has_plan', v_plan.id is not null,
    'plan_id',  v_plan.id,
    'subject',  (select s.slug from public.subjects s where s.id = v_plan.subject_id),
    'level',    (select l.code from public.levels l where l.id = v_plan.level_id),
    'next',     v_next,
    'plan_id',  v_plan.id,
    'last',     v_last,
    'open',     v_open,
    'pending',  v_pend,
    'students', (select count(*) from public.students s
                  where s.class_id = p_class_id and s.is_active));
end $$;

-- rpc_plan_get (esas: 101): warm_test_id
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

