-- =====================================================================
--  202 : AKTIVLESME HUNISI - IDAREETMEDE (2026-09-17)
--
--  Reqemler SQL Editor-de el ile sayilirdi: 6 qeydiyyat -> 3 tesdiq ->
--  3 giris -> 0 qrup.  Indi admin ekraninda kart: qeydiyyat -> tesdiq ->
--  panele giris -> qrup -> sagird -> test -> cehd -> pullu; alti «qrup
--  yaratmayanlar» siyahisi (kime mesaj yazmali; son 50, panelde surusur).
--
--  Supabase-de «Confirm email» sondurulur (Authentication -> Sign In /
--  Providers -> Email): muellim qeydiyyatdan dusen kimi panele girir,
--  panel sari zolaqla e-pocti tesdiqlemeyi xatirladir (parol berpasi
--  ucun).  Yerli stub-a auth.users.email_confirmed_at elave olundu.
--
--  Numune ve admin hesablari sayilmir.  p_days = 0 -> butun tarix.
-- =====================================================================
create or replace function public.rpc_admin_huni(p_days int default 30)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_since timestamptz := case when coalesce(p_days, 0) > 0
                              then now() - make_interval(days => p_days)
                              else '-infinity'::timestamptz end;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  return (
    with u as (
      select u.id, u.email, u.created_at, u.email_confirmed_at,
             coalesce(pr.last_seen_at, u.last_sign_in_at) seen_at, pr.full_name
        from auth.users u
        left join public.profiles pr on pr.id = u.id
       where u.email is not null
         and u.created_at >= v_since
         and not exists (select 1 from public.accounts a where a.owner_id = u.id and a.is_demo)
         and not exists (select 1 from public.user_roles r where r.user_id = u.id and r.role = 'admin')
    ),
    s as (
      select u.*,
             exists (select 1 from public.classes c join public.accounts a on a.id = c.account_id
                      where a.owner_id = u.id) has_group,
             exists (select 1 from public.students st join public.accounts a on a.id = st.account_id
                      where a.owner_id = u.id) has_student,
             exists (select 1 from public.tests t
                      where t.owner_type = 'educator' and t.owner_id = u.id and not t.is_diagnostic) has_test,
             exists (select 1 from public.attempts at
                      join public.students st on st.id = at.student_id
                      join public.accounts a on a.id = st.account_id
                      where a.owner_id = u.id and at.status = 'submitted') has_attempt,
             exists (select 1 from public.subscriptions sb join public.accounts a on a.id = sb.account_id
                      where a.owner_id = u.id and sb.status = 'active'
                        and (sb.current_period_end is null or sb.current_period_end > now())) is_paid
        from u
    )
    select jsonb_build_object(
      'days',       p_days,
      'registered', count(*),
      'confirmed',  count(*) filter (where email_confirmed_at is not null),
      'entered',    count(*) filter (where seen_at is not null),
      'grup',       count(*) filter (where has_group),
      'sagird',     count(*) filter (where has_student),
      'test',       count(*) filter (where has_test),
      'cehd',       count(*) filter (where has_attempt),
      'pullu',      count(*) filter (where is_paid),
      'stuck', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'email', x.email, 'name', x.full_name, 'at', x.created_at,
                 'seen', x.seen_at, 'confirmed', x.email_confirmed_at is not null)
               order by x.created_at desc)
          from (select * from s where not has_group order by created_at desc limit 50) x), '[]'::jsonb)
    ) from s
  );
end $$;

revoke all on function public.rpc_admin_huni(int) from public, anon;
grant execute on function public.rpc_admin_huni(int) to authenticated;
