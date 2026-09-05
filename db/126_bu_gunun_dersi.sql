-- =====================================================================
--  126  «BU GUNUN DERSI» - derse hazirliq karti (yol xeritesi 21.1)
--
--  Muellim dersden 5 deqiqe evvel qrupu acir ve bir kartda gorur:
--    - novbeti movzu (plan uzre cari ders) ve son kecilen (tarix, test
--      ortalamasi),
--    - tapsirigi hele etmeyenler (acıq teyinat, cehd yoxdur),
--    - hazir addimlar: son movzudan test yig, tapsiriq ver.
--  Melumatin hamisi bazada var idi - bura yalniz bir sorguda yigilir.
--  Zeif/risk siqnallari ayrica (rpc_class_alerts) qalir.
-- =====================================================================

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
    'last',     v_last,
    'open',     v_open,
    'pending',  v_pend,
    'students', (select count(*) from public.students s
                  where s.class_id = p_class_id and s.is_active));
end $$;

revoke all on function public.rpc_lesson_prep(uuid) from public, anon;
grant execute on function public.rpc_lesson_prep(uuid) to authenticated;
