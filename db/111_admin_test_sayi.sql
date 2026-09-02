-- =====================================================================
--  111_admin_test_sayi.sql — admin panelinde "0 test" qusuru
--
--  NIYE
--  Idareetme ekraninda HER hesabda "0 test" yazilirdi - hesabda
--  onlarla test olsa da.  Sebeb sayğacin testi hesaba CLASS_ID uzre
--  baglamasi idi:
--
--      from public.tests t join public.classes c on c.id = t.class_id
--
--  Halbuki muellimin yigdigi testde class_id HEC VAXT dolmur - nə
--  rpc_generate_test, ne rpc_remedial_test onu yazmir.  Yeni birlesme
--  hemise bos qayidirdi ve say sifir cixirdi.
--
--  "aktivlik" sutununda da eyni qusur vardi: test yigan, amma hele
--  cehd olmayan muellim "hec vaxt" gorunurdu.
--
--  NE EDIRIK
--  Test hesaba SAHIBLIK uzre baglanir: testin sahibi hesabin uzvudur
--  (account_members).  class_id serti saxlanilir - bir gun doldurulsa
--  o testler de sayilsin.
--
--  Fayl 21_paket.sql-den PROQRAMLA cixarilib.
-- =====================================================================

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

revoke all on function public.rpc_admin_accounts(text, text) from public, anon;
grant execute on function public.rpc_admin_accounts(text, text) to authenticated;

do $x$
declare v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_admin_accounts';
  if v_def like '%join public.classes c on c.id = t.class_id%' then
    raise exception 'test sayi hele de class_id uzre birlesdirilir';
  end if;
  raise notice 'Admin paneli: test sayi sahibliye gore hesablanir.';
end $x$;
