-- =====================================================================
--  09_assignments.sql : test teyinatlari
--
--  Muellim testi QRUPA teyin edir. Sagird oz daimi kodu ile girib
--  aktiv tapsiriqlari gorur - her test ucun ayrica kod paylanmir.
--
--  Cedvel 01_schema.sql-dedir, RLS siyasetleri 02_rls.sql-de.
--  Bu fayl yalniz muellim terefinin funksiyalaridir.
-- =====================================================================

-- ------------------------------------------------- muellim: teyin etmek
create or replace function public.rpc_assign_test(
  p_class_id uuid, p_test_id uuid,
  p_closes_at timestamptz default null,
  p_max_attempts int default 1)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_test  public.tests%rowtype;
  v_id    uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid and not app.is_account_member(v_class.account_id) then
    raise exception 'Bu qrupa test teyin ede bilmezsiniz.' using errcode = '42501';
  end if;

  select * into v_test from public.tests where id = p_test_id and status = 'published';
  if not found then
    raise exception 'Test tapilmadi.' using errcode = '22023';
  end if;
  -- Muellim yalniz platforma testini ve ya OZ testini teyin ede biler
  if v_test.owner_type = 'educator' and v_test.owner_id <> v_uid then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  if p_max_attempts is null or p_max_attempts < 0 or p_max_attempts > 20 then
    raise exception 'Cehd sayi 0-20 araliginda olmalidir.' using errcode = '22023';
  end if;
  if p_closes_at is not null and p_closes_at <= now() then
    raise exception 'Son tarix kecmisde ola bilmez.' using errcode = '22023';
  end if;

  insert into public.assignments (class_id, test_id, assigned_by, closes_at, max_attempts)
  values (p_class_id, p_test_id, v_uid, p_closes_at, p_max_attempts)
  on conflict (class_id, test_id) do update
    set closes_at = excluded.closes_at,
        max_attempts = excluded.max_attempts,
        opens_at = now(),
        assigned_by = excluded.assigned_by
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'test', v_test.title);
end $$;

create or replace function public.rpc_unassign_test(p_assignment_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_class uuid;
begin
  select a.class_id into v_class
    from public.assignments a
    join public.classes c on c.id = a.class_id
   where a.id = p_assignment_id
     and (c.teacher_id = auth.uid() or app.is_account_member(c.account_id));
  if v_class is null then
    raise exception 'Teyinat tapilmadi.' using errcode = '42501';
  end if;
  delete from public.assignments where id = p_assignment_id;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------ muellim: teyin edile bilen testler
create or replace function public.rpc_available_tests(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
begin
  select * into v_class from public.classes where id = p_class_id;
  if not found or (v_class.teacher_id <> v_uid
                   and not app.is_account_member(v_class.account_id)) then
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by x->>'subject', x->>'title')
    from (
      select jsonb_build_object(
               'id',        t.id,
               'title',     t.title,
               'subject',   sub.name,
               'level',     lv.name,
               'is_free',   t.is_free,
               'mine',      t.owner_type = 'educator',
               'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
               'assigned',  (select a.id from public.assignments a
                              where a.class_id = p_class_id and a.test_id = t.id)
             ) as x
        from public.tests t
        join public.subjects sub on sub.id = t.subject_id
        left join public.levels lv on lv.id = t.level_id
       where t.status = 'published'
         and (t.owner_type = 'platform' or t.owner_id = v_uid)
         and (v_class.level_id is null or t.level_id is null or t.level_id = v_class.level_id)
    ) z
  ), '[]'::jsonb);
end $$;

-- ---------------------------------------- muellim: qrupun teyinatlari
create or replace function public.rpc_class_assignments(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_total int;
begin
  select * into v_class from public.classes where id = p_class_id;
  if not found or (v_class.teacher_id <> v_uid
                   and not app.is_account_member(v_class.account_id)) then
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  select count(*) into v_total from public.students
   where class_id = p_class_id and is_active;

  return jsonb_build_object(
    'free_practice', v_class.free_practice,
    'students', v_total,
    'items', coalesce((
      select jsonb_agg(x order by (x->>'open')::boolean desc, x->>'closes_at')
      from (
        select jsonb_build_object(
                 'id',        a.id,
                 'test_id',   t.id,
                 'title',     t.title,
                 'subject',   sub.name,
                 'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
                 'closes_at', a.closes_at,
                 'max_attempts', a.max_attempts,
                 'open',      app.assignment_open(a.*),
                 -- Nece sagird bitirib ve ortalama netice
                 'done',      (select count(distinct at.student_id)
                                 from public.attempts at
                                 join public.students s on s.id = at.student_id
                                where at.test_id = t.id and s.class_id = p_class_id
                                  and at.status = 'submitted'),
                 'avg',       (select round(avg(best), 0) from (
                                 select max(at.percent) best
                                   from public.attempts at
                                   join public.students s on s.id = at.student_id
                                  where at.test_id = t.id and s.class_id = p_class_id
                                    and at.status = 'submitted'
                                  group by at.student_id) b)
               ) as x
          from public.assignments a
          join public.tests t on t.id = a.test_id
          join public.subjects sub on sub.id = t.subject_id
         where a.class_id = p_class_id
      ) z), '[]'::jsonb)
  );
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_assign_test(uuid, uuid, timestamptz, int) from public;
revoke all on function public.rpc_unassign_test(uuid)                       from public;
revoke all on function public.rpc_available_tests(uuid)                     from public;
revoke all on function public.rpc_class_assignments(uuid)                   from public;

grant execute on function public.rpc_assign_test(uuid, uuid, timestamptz, int) to authenticated;
grant execute on function public.rpc_unassign_test(uuid)                       to authenticated;
grant execute on function public.rpc_available_tests(uuid)                     to authenticated;
grant execute on function public.rpc_class_assignments(uuid)                   to authenticated;

do $$
declare bad text;
begin
  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_assign_test(uuid, uuid, timestamptz, int)',
    'public.rpc_unassign_test(uuid)',
    'public.rpc_available_tests(uuid)',
    'public.rpc_class_assignments(uuid)']) f
   where not has_function_privilege('authenticated', f, 'EXECUTE');
  if bad is not null then
    raise exception 'authenticated bu funksiyalari cagira bilmir: %', bad;
  end if;
  raise notice 'Teyinat funksiyalari acildi.';
end $$;
