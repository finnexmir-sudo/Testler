-- =====================================================================
--  174_valideyn_abune.sql — VALIDEYN EKRANI: «nə baş verib» pulsuz,
--  «necədir» (təhlil) abunə ilə
--
--  ISTIFADECI QERARI (2026-09-09 muzakiresi):
--   * Valideyn HEC VAXT odemir - bu ved deyismir.  Odeyen muellimdir.
--   * Muellimi valideyne hesabat vermek eziyyetinden qurtaran hisse
--     abunenin icinde olsun: valideyn 1-2 ay rahatliga oyresir, abune
--     bitende hemin hisse baglanir ve DAVAM ETMEYI VALIDEYN ISTEYIR.
--   * Amma KESMIRIK, AZALDIRIQ: valideyn Bil10-un isledigini gormeye
--     davam etmelidir - o, en guclu yayilma kanalimizdir.  Qapida
--     qalan valideyn muellimi gunahlandirir, hekaye pis yayilir.
--
--  BOLGU:
--    HEMISE PULSUZ  usagin adi, muellim, «Son nəticələr» siyahisi
--                   (test-test faiz), gozleyen tapsiriqlar, ferdi plan,
--                   movzu mesqi, davamiyyet ve odenis defteri,
--                   «son 30 gunde N test yazib» sayi
--    ABUNE ILE      ortalama faiz (avg30), meyl («8% yaxsilasib»),
--                   en yaxsi netice, zeif movzular (onsuz da bele idi)
--
--  Yeni ved metni valideyn ekraninda NEYTRALDIR - «müəllim ödəməyib»
--  kimi oxunan hec ne yazilmir.  Sebeb: Bil10 muellimi oz musterisinin
--  qarsisinda utandiran sey olmamalidir.
--
--  IKINCI HISSE - OLCU.  rpc_admin_accounts-da sagird ve valideyn
--  girisi AYRILDI (evvel bir reqemde idi).  Elave olunur:
--    parent_login  son valideyn girisi
--    parents       nece sagirdin valideyni EN AZI bir defe girib
--  Bu, qiymet qerarini melumatla vermek ucundur: valideyn ekrani
--  neqeder islenir?  Az islenirse, bu lever zeifdir.
--
--  BETA DOVRUNDE HEC KIME HEC NE OLMUR: hediyye/sinaq abunesi olan
--  hesabda v_paid = true, yeni valideyn her seyi gorur.  Bolgu yalniz
--  abune bitenden sonra ise dusur.
-- =====================================================================

do $$
begin
  if to_regclass('public.parent_sessions') is null then
    raise exception 'ONCE 107_valideyn.sql isledilmelidir.';
  end if;
end $$;
create or replace function public.rpc_parent_home(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_sid   uuid := app.session_parent(p_token);
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_paid  boolean;
  v_min   int := app.min_topic_answers();
  v_now   numeric;
  v_prev  numeric;
begin
  if v_sid is null then
    raise exception 'Sessiya bitib. Kodu yeniden yaz.' using errcode = '28000';
  end if;
  select * into v_st from public.students where id = v_sid;
  select * into v_class from public.classes where id = v_st.class_id;
  v_paid := app.has_active_subscription(v_st.account_id);

  --  Meyl: son 30 gun ve ondan EVVELKI 30 gun.  Cilpaq faiz valideyne
  --  hec ne demir - "8% yaxsilasib" deyir.
  select round(avg(a.percent), 0) into v_now from public.attempts a
   where a.student_id = v_sid and a.status = 'submitted'
     and a.finished_at >= now() - interval '30 days';
  select round(avg(a.percent), 0) into v_prev from public.attempts a
   where a.student_id = v_sid and a.status = 'submitted'
     and a.finished_at >= now() - interval '60 days'
     and a.finished_at <  now() - interval '30 days';

  return jsonb_build_object(
    'paid', v_paid,
    --  Tam ad DEYIL - gorunen ad.  Kod yayilsa yad adam usagin tam
    --  adini oyrenmesin.
    'child', jsonb_build_object(
               'name',  v_st.display_name,
               'class', v_class.name),
    'teacher', (select p.full_name from public.profiles p
                 where p.id = v_class.teacher_id),

    -- ------------------------------------------------------ veziyyet
    'summary', jsonb_build_object(
      'attempts30', (select count(*) from public.attempts a
                      where a.student_id = v_sid and a.status = 'submitted'
                        and a.finished_at >= now() - interval '30 days'),
      --  174: NE BAS VERIB - pulsuz; NECEDIR (tehlil) - abune ile.
      --  Valideyn «Son nəticələr» siyahisini ve tapsiriqlari HEMISE
      --  gorur; ortalama, meyl ve en yaxsi netice muellimin abunesi
      --  ile acilir.  Sebeb (istifadeci qerari): muellimi valideyne
      --  hesabat vermek eziyyetinden qurtaran hisse elə budur.
      'avg30',  case when v_paid then v_now end,
      'prev30', case when v_paid then v_prev end,
      'delta',  case when v_paid and v_now is not null and v_prev is not null
                     then v_now - v_prev end,
      'best',   case when v_paid then
                  (select round(max(a.percent), 0) from public.attempts a
                    where a.student_id = v_sid and a.status = 'submitted') end),

    -- -------------------------------------------- gozleyen tapsiriq
    --  Ekranin en vacib hissesi: valideyni geri qaytaran yeganə sey.
    'pending', coalesce((
      select jsonb_agg(x order by x->>'closes_at' nulls last)
        from (
          select jsonb_build_object(
                   'title',     t.title,
                   'subject',   sub.name,
                   'closes_at', a.closes_at,
                   'questions', (select count(*) from public.test_questions tq
                                  where tq.test_id = t.id),
                   'fix', t.is_remedial, 'diag', t.is_diagnostic) as x
            from public.assignments a
            join public.tests t on t.id = a.test_id and t.status = 'published'
            left join public.subjects sub on sub.id = t.subject_id
           where a.class_id = v_st.class_id
             and app.assignment_open(a.*)
             --  bu usaq hele yazmayib
             and not exists (select 1 from public.attempts at
                              where at.test_id = t.id and at.student_id = v_sid
                                and at.status = 'submitted')
             --  ferdi tapsiriqsa YALNIZ bu usaga aiddirsa
             and (a.student_id is null or a.student_id = v_sid)
        ) z), '[]'::jsonb),

    -- --------------------------------------------------- neticeler
    'results', coalesce((
      select jsonb_agg(x order by x->>'at' desc)
        from (
          select jsonb_build_object(
                   'at',      a.finished_at,
                   'test',    t.title,
                   'subject', sub.name,
                   'percent', round(a.percent, 0),
                   --  DUZELIS testi - sutundan gelir, tehmin yox.
                   'fix', t.is_remedial, 'diag', t.is_diagnostic) as x
            from public.attempts a
            join public.tests t on t.id = a.test_id
            left join public.subjects sub on sub.id = t.subject_id
           where a.student_id = v_sid and a.status = 'submitted'
           order by a.finished_at desc limit 10
        ) z), '[]'::jsonb),

    -- ------------------------------------------------ zeif movzular
    --  En coxu 3.  Az cavab varsa GOSTERILMIR - uc sualdan cixarilan
    --  "zeifdir" hokmu valideyni nahaq yere hemlə edir.
    'weak', case when not v_paid then null else coalesce((
      select jsonb_agg(y order by (y->>'percent')::numeric)
        from (
          select jsonb_build_object(
                   'topic',   t.name,
                   'subject', sub.name,
                   'answers', count(*),
                   'percent', round(count(*) filter (where aa.is_correct)
                                    * 100.0 / count(*), 0)) as y
            from public.attempt_answers aa
            join public.attempts a on a.id = aa.attempt_id
                                  and a.student_id = v_sid
                                  and a.status = 'submitted'
            join public.topics t     on t.id = aa.topic_id
            join public.subjects sub on sub.id = t.subject_id
           group by t.id, t.name, sub.name
          having count(*) >= v_min
             and count(*) filter (where aa.is_correct) * 100.0 / count(*) < 60
           order by count(*) filter (where aa.is_correct) * 100.0 / count(*)
           limit 3
        ) z), '[]'::jsonb) end,

    -- --------------------------------------------- kecilen dersler
    --  "Bunu kecdim" - muellimin valideyne dediyi cumle.
    --  131: ferdi plan irelileyisi
    'plan', (select case when count(*) = 0 then null else
               jsonb_build_object('total', count(*), 'done', count(*) filter (where i.done_at is not null)) end
               from public.student_plan_items i
               join public.student_plans p on p.id = i.plan_id
              where p.student_id = v_sid),

    --  133: movzu mesqi
    'practice', (select jsonb_build_object(
                   'mastered', count(*) filter (where p.mastered_at is not null),
                   'active',   count(*) filter (where p.mastered_at is null and p.answered > 0))
                   from public.practice p where p.student_id = v_sid),

    --  130: davamiyyet ve odenis - bu ay
    'attendance', (
      select jsonb_build_object(
               'month',    to_char(date_trunc('month', now()), 'YYYY-MM-DD'),
               'lessons',  (select count(*) from public.lessons l
                             where l.class_id = v_st.class_id
                               and l.held_on >= date_trunc('month', now())::date
                               and l.held_on <  (date_trunc('month', now()) + interval '1 month')::date),
               'attended', (select count(*) from public.attendance at
                             join public.lessons l on l.id = at.lesson_id
                            where at.student_id = v_sid and at.present
                              and l.held_on >= date_trunc('month', now())::date
                              and l.held_on <  (date_trunc('month', now()) + interval '1 month')::date),
               'paid',     (select p.paid from public.fee_payments p
                             where p.student_id = v_sid
                               and p.month = date_trunc('month', now())::date))),

    'lessons', coalesce((
      select jsonb_agg(x order by x->>'at' desc)
        from (
          select jsonb_build_object(
                   'topic',   t.name,
                   'subject', sub.name,
                   'at',      i.done_at) as x
            from public.class_plan_items i
            join public.class_plans p on p.id = i.plan_id
                                     and p.class_id = v_st.class_id
            join public.topics t     on t.id = i.topic_id
            join public.subjects sub on sub.id = p.subject_id
           where i.done_at is not null
           order by i.done_at desc limit 5
        ) z), '[]'::jsonb));
end $$;
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
               'student_login',
                 (select max(ss.created_at) from public.student_sessions ss
                   join public.students st on st.id = ss.student_id
                  where st.account_id = a.id),
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
end $$;
revoke all on function public.rpc_parent_home(text)    from public, authenticated;
grant  execute on function public.rpc_parent_home(text) to anon, authenticated;
revoke all on function public.rpc_admin_accounts(text, text) from public, anon;
grant  execute on function public.rpc_admin_accounts(text, text) to authenticated;
