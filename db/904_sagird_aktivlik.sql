-- =====================================================================
--  904 : IDAREETME - «SAGIRD GIRISI» SON AKTIVLIKDIR (2026-09-30)
--
--  NIYE
--  «Samir test» hesabinda yazirdi: «sagird: 4 gun evvel» - amma sagird
--  dunen girib test yazmisdi.  Sebeb: «sagird girisi» yalniz
--  student_sessions.created_at idi, yeni sagirdin KODU YAZIB DAXIL
--  OLDUGU an.  Sessiya 30 gundur (164): sagird bir defe girir, sonra her
--  gun kodsuz acir ve test yazir - yeni sessiya setri yaranmir.
--
--  NECE
--  student_login = greatest(son sessiya, son test cehdi).  Cehd =
--  finished_at, yarimciqdirsa started_at.  Yalniz bu ifade deyisir;
--  gövdenin qalani rpc_admin_accounts-in cari versiyasindan (174)
--  pg_get_functiondef ile kocurulub.
--
--  DEYISMIR: parent_login (valideyn ekrani hec bir aktivlik yazmir -
--  ayrica is), last_login (muellim: profiles.last_seen_at, 206).
--
--  ON SERT: 174.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.rpc_admin_accounts(p_q text DEFAULT NULL::text, p_f text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by
             case when p_f in ('pullu','bitir','sinaq')
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
               --  174: sagird ve valideyn girisi AYRILDI.  Evvel ikisi
               --  bir reqemde idi - valideynlerin girib-girmediyini
               --  bilmek mumkun deyildi.  Bu, qiymet qerari ucun
               --  lazimdir: valideyn ekrani neqeder isleyir?
               --  904: «sagird girisi» = SON AKTIVLIK.  Evvel yalniz sessiyanin acildigi an idi
               --  (student_sessions.created_at) - sagird 30 gunluk sessiya ile (164) kodu yeniden
               --  yazmadan her gun girib test yazirdi, idareetmede «4 gun evvel» qalirdi.  Indi test
               --  basladigi / bitdigi an da sayilir.
               'student_login',
                 greatest(
                   (select max(ss.created_at) from public.student_sessions ss
                     join public.students st on st.id = ss.student_id
                    where st.account_id = a.id),
                   (select max(coalesce(at.finished_at, at.started_at)) from public.attempts at
                     join public.students st on st.id = at.student_id
                    where st.account_id = a.id)),
               'parent_login',
                 (select max(ps.created_at) from public.parent_sessions ps
                   join public.students st on st.id = ps.student_id
                  where st.account_id = a.id),
               --  nece sagirdin valideyni EN AZI bir defe girib
               'parents',
                 (select count(distinct ps.student_id) from public.parent_sessions ps
                   join public.students st on st.id = ps.student_id
                  where st.account_id = a.id),
               --  138: admin sahibli hesab daimidir, numune nusxesi
               --  sayilmir - panel duymeleri buna gore gizledir
               'admin', app.account_is_admin(a.id),
               'demo',  a.is_demo,
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
       --  138: numune nusxeleri yalniz 'numune' suzgecinde
       where a.is_demo = coalesce(p_f = 'numune', false)
         and (p_q is null or btrim(p_q) = ''
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
           or p_f = 'numune'
           --  138: pullu = yalniz ODENISLI (active); sinaq = trialing;
           --  pulsuz = hec biri.  Admin sahibli hesab pullu deyil.
           or (p_f = 'pullu' and not app.account_is_admin(a.id) and exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status = 'active'
                   and (s2.current_period_end is null
                        or s2.current_period_end > now())))
           or (p_f = 'sinaq' and exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status = 'trialing'
                   and (s2.current_period_end is null
                        or s2.current_period_end > now())))
           or (p_f = 'pulsuz' and not app.account_is_admin(a.id) and not exists (
                select 1 from public.subscriptions s2
                 where s2.account_id = a.id
                   and s2.status in ('trialing','active')
                   and (s2.current_period_end is null
                        or s2.current_period_end > now()))))
       order by a.created_at desc
       limit 50
    ) z), '[]'::jsonb);
end $function$;

revoke all on function public.rpc_admin_accounts(text, text) from public, anon;
grant execute on function public.rpc_admin_accounts(text, text) to authenticated;
