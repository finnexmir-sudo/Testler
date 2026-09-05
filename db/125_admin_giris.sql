-- =====================================================================
--  125  ADMIN: KIM NE VAXT GIRIB
--
--  Istifadeci sualı: "admin olaraq kimlerin girdiyini izleye bilerem?"
--  Evvel Idareetmedeki "aktivlik" yalniz cehd/test yigmagi olcurdu -
--  qrup qurub hele test vermeyen muellim "hec vaxt" gorunurdu.
--
--  Menbe:
--    profiles.last_seen_at  - muellim paneli acilanda rpc_seen() yazir
--                             (15 deqiqede bir defeden cox yox).
--                             Supabase-in last_sign_in_at-i yalniz parolla
--                             girisde yenilenir; sessiya aylarla qalir.
--    student_sessions / parent_sessions.created_at - kodla giris.
--
--  rpc_admin_accounts: last_login, student_login, p_f='girmir' suzgeci.
--  rpc_admin_stats: seen_week.  Govdeler 111 / 21 uzerindedir.
-- =====================================================================

alter table public.profiles add column if not exists last_seen_at timestamptz;

create or replace function public.rpc_seen()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false);
  end if;
  update public.profiles
     set last_seen_at = now()
   where id = auth.uid()
     and (last_seen_at is null or last_seen_at < now() - interval '15 minutes');
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.rpc_seen() from public, anon;
grant execute on function public.rpc_seen() to authenticated;

create or replace function public.rpc_admin_accounts(
  p_q text default null, p_f text default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by
             case when p_f in ('pullu','bitir')
                  then x->'plan'->>'ends' end asc nulls last,
             x->>'created' desc)
    from (
      select jsonb_build_object(
               'id',    a.id,
               'name',  a.name,
               'type',  a.type,
               'email', u.email,
               'students', app.account_student_count(a.id),
               'groups', (select count(*) from public.classes c
                           where c.account_id = a.id),
               --  Testler hesaba SAHIBLIK uzre baglanir.  Evvel
               --  class_id uzre birlesdirilirdi, halbuki muellimin
               --  yigdigi testde class_id HEC VAXT dolmur (nə generator,
               --  ne duzelis testi onu yazmir) - say butun hesablarda
               --  hemise 0 gorunurdu.
               'tests', (select count(*) from public.tests t
                          where (t.owner_type = 'educator'
                      and (t.owner_id in (select am.user_id
                                            from public.account_members am
                                           where am.account_id = a.id)
                           or t.class_id in (select c.id from public.classes c
                                              where c.account_id = a.id)))),
               'attempts', (select count(*) from public.attempts att
                             join public.students st on st.id = att.student_id
                            where st.account_id = a.id
                              and att.status = 'submitted'),
               'last_active', greatest(
                 (select max(att.finished_at) from public.attempts att
                   join public.students st on st.id = att.student_id
                  where st.account_id = a.id),
                 --  Eyni qusur burada da vardi: test yigan, amma hele
                 --  cehd olmayan muellim "aktivlik: hec vaxt" gorunurdu.
                 (select max(t.created_at) from public.tests t
                   where (t.owner_type = 'educator'
                      and (t.owner_id in (select am.user_id
                                            from public.account_members am
                                           where am.account_id = a.id)
                           or t.class_id in (select c.id from public.classes c
                                              where c.account_id = a.id))))),
               'created', a.created_at,
               --  Girisler: muellim paneli acilanda rpc_seen() yazir
               --  (profiles.last_seen_at); Supabase-in oz last_sign_in_at-i
               --  yalniz parolla girisde yenilenir - ikisinin boyuyu.
               'last_login', greatest(
                 (select max(p2.last_seen_at) from public.profiles p2
                   where p2.id = a.owner_id
                      or p2.id in (select am.user_id from public.account_members am
                                    where am.account_id = a.id)),
                 u.last_sign_in_at),
               --  Sagird/valideyn girisi: kodla giris = yeni sessiya
               'student_login', greatest(
                 (select max(ss.created_at) from public.student_sessions ss
                   join public.students st on st.id = ss.student_id
                  where st.account_id = a.id),
                 (select max(ps.created_at) from public.parent_sessions ps
                   join public.students st on st.id = ps.student_id
                  where st.account_id = a.id)),
               'plan', (select jsonb_build_object(
                          'name', pl.name, 'status', s.status,
                          'ends', s.current_period_end)
                          from public.subscriptions s
                          join public.plans pl on pl.id = s.plan_id
                         where s.account_id = a.id
                           and s.status in ('trialing','active')
                           and (s.current_period_end is null
                                or s.current_period_end > now())
                         order by s.current_period_end desc nulls last
                         limit 1)
             ) as x
        from public.accounts a
        join auth.users u on u.id = a.owner_id
       where (p_q is null or btrim(p_q) = ''
           or a.name ilike '%' || btrim(p_q) || '%'
           or u.email ilike '%' || btrim(p_q) || '%')
         and (p_f is null
           --  Girmeyenler: 7 gundur hec bir uzv paneli acmayib
           or (p_f = 'girmir' and coalesce(greatest(
                 (select max(p3.last_seen_at) from public.profiles p3
                   where p3.id = a.owner_id
                      or p3.id in (select am.user_id from public.account_members am
                                    where am.account_id = a.id)),
                 u.last_sign_in_at), a.created_at) < now() - interval '7 days')
           or (p_f = 'bitir' and exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status in ('trialing','active')
                   and s2.current_period_end > now()
                   and s2.current_period_end <= now() + interval '14 days'))
           or (p_f in ('pullu','pulsuz')
               and (p_f = 'pullu') = exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status in ('trialing','active')
                   and (s2.current_period_end is null
                        or s2.current_period_end > now()))))
       order by a.created_at desc
       limit 50
    ) z), '[]'::jsonb);
end $$;


create or replace function public.rpc_admin_stats()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'accounts', (select count(*) from public.accounts),
    'accounts_week', (select count(*) from public.accounts
                       where created_at > now() - interval '7 days'),
    'paid_accounts', (select count(distinct s.account_id)
                       from public.subscriptions s
                      where s.status in ('trialing','active')
                        and (s.current_period_end is null
                             or s.current_period_end > now())),
    'active_subs', (select count(*) from public.subscriptions s
                     where s.status in ('trialing','active')
                       and (s.current_period_end is null
                            or s.current_period_end > now())),
    'mrr_minor', coalesce((
      select sum(pl.price_minor
                 + pl.price_per_seat_minor * greatest(s.seats, 0))
        from public.subscriptions s
        join public.plans pl on pl.id = s.plan_id
       where s.status in ('trialing','active')
         and (s.current_period_end is null
              or s.current_period_end > now())), 0),
    'students', (select count(*) from public.students where is_active),
    'seen_week', (select count(*) from public.accounts a
                   where exists (select 1 from public.profiles p2
                                  where (p2.id = a.owner_id
                                     or p2.id in (select am.user_id from public.account_members am
                                                   where am.account_id = a.id))
                                    and p2.last_seen_at > now() - interval '7 days')
                      or exists (select 1 from auth.users u2
                                  where u2.id = a.owner_id
                                    and u2.last_sign_in_at > now() - interval '7 days')),
    'attempts_week', (select count(*) from public.attempts
                       where status = 'submitted'
                         and finished_at > now() - interval '7 days'),
    'plans', coalesce((
      select jsonb_agg(jsonb_build_object('slug', p.slug, 'name', p.name)
                       order by (p.audience <> 'tutor'), p.sort)
        from public.plans p
       where p.is_active and p.slug <> 'pulsuz'), '[]'::jsonb));
end $$;

