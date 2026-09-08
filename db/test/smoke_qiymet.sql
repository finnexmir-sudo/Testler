-- =====================================================================
--  smoke_qiymet.sql : Sagird basina qiymet + guzest muddeti (db/165)
--
--  Iddialar: yeni plan limitsizdir ve sagird basina 1.50 AZN-dir ·
--  valideyn pullu paketleri baglidir · abune bitenden sonra 3 gun
--  hesab isleyir (sagird elave olunur) · 3 gunden sonra pulsuz hedde
--  dusur, MOVCUD sagirdler qalir · rpc_my_context meblegi ve qalan
--  gunu duzgun verir (guzestde menfi).
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.parent_sessions;
delete from public.student_sessions; delete from public.students;
delete from public.classes;          delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000165a1','qm@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000165a1','tutor','Qiymet hesabi',
   '11110000-0000-0000-0000-0000000165a1');
insert into public.account_members (account_id, user_id, is_admin) values
  ('aaaa0000-0000-0000-0000-0000000165a1','11110000-0000-0000-0000-0000000165a1',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('ccc00000-0000-0000-0000-0000000165a1','aaaa0000-0000-0000-0000-0000000165a1',
   '11110000-0000-0000-0000-0000000165a1','tutor_group','Qiymet qrupu','KODQYM01');

-- 1 · plan: limitsiz, sagird basina 150 qepik, baza haqqi yoxdur
do $$
declare p public.plans%rowtype;
begin
  select * into p from public.plans where slug = 'sagird-basi';
  if not found then raise exception 'sagird-basi plani yoxdur'; end if;
  if p.price_minor <> 0 then raise exception 'baza haqqi olmamalidir: %', p.price_minor; end if;
  if p.price_per_seat_minor <> 150 then
    raise exception 'sagird basina 150 qepik olmalidir: %', p.price_per_seat_minor; end if;
  if p.max_students is not null then raise exception 'limitsiz olmalidir'; end if;
  if not p.is_active or p.audience <> 'tutor' then raise exception 'aktiv/tutor olmalidir'; end if;
  --  valideyn pullu paketleri baglidir (sagird ve valideyn pulsuzdur)
  if exists (select 1 from public.plans
              where slug in ('valideyn-aylik','valideyn-illik') and is_active) then
    raise exception 'valideyn pullu paketi hele aciqdir';
  end if;
end $$;
\echo 'OK  1 · plan limitsiz, sagird basina 1.50 AZN; valideyn paketleri bagli'

-- 2 · abune bitenden 2 gun sonra (guzest icinde) hesab hele isleyir
insert into public.subscriptions (account_id, plan_id, status, seats, started_at,
                                  current_period_end, provider)
select 'aaaa0000-0000-0000-0000-0000000165a1', p.id, 'active', 0,
       now() - interval '32 days', now() - interval '2 days', 'manual'
  from public.plans p where p.slug = 'sagird-basi';
do $$
begin
  if not app.has_active_subscription('aaaa0000-0000-0000-0000-0000000165a1') then
    raise exception 'guzest icinde abune aktiv sayilmalidir';
  end if;
  if app.account_seat_limit('aaaa0000-0000-0000-0000-0000000165a1') <> 2147483647 then
    raise exception 'guzest icinde limit limitsiz qalmalidir';
  end if;
end $$;
--  guzest icinde sagird ELAVE olunur (hedd bloklamir)
insert into public.students (account_id, class_id, created_by, full_name,
                             display_name, login_code, is_active)
select 'aaaa0000-0000-0000-0000-0000000165a1','ccc00000-0000-0000-0000-0000000165a1',
       '11110000-0000-0000-0000-0000000165a1','Sagird ' || g, 'S' || g,
       'QYM0000' || g, true
  from generate_series(1,8) g;
\echo 'OK  2 · guzest muddetinde (3 gun) hesab isleyir, sagird elave olunur'

-- 3 · guzest bitende pulsuz hedde dusur, MOVCUD sagirdler qalir
update public.subscriptions set current_period_end = now() - interval '4 days'
 where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
do $$
declare n int;
begin
  if app.has_active_subscription('aaaa0000-0000-0000-0000-0000000165a1') then
    raise exception 'guzest bitib, abune aktiv sayilmamalidir';
  end if;
  if app.account_seat_limit('aaaa0000-0000-0000-0000-0000000165a1')
     <> app.free_seat_limit() then
    raise exception 'guzestden sonra pulsuz hedde dusmelidir';
  end if;
  --  movcud sagirdler ISLEYIR (silinmir, dayandirilmir)
  select count(*) into n from public.students
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1' and is_active;
  if n <> 8 then raise exception 'movcud sagirdler qalmalidir, qaldi: %', n; end if;
  --  amma TEZESI elave olunmur
  begin
    insert into public.students (account_id, class_id, created_by, full_name,
                                 display_name, login_code, is_active)
    values ('aaaa0000-0000-0000-0000-0000000165a1','ccc00000-0000-0000-0000-0000000165a1',
            '11110000-0000-0000-0000-0000000165a1','Doqquzuncu','D9','QYM00009',true);
    raise exception 'guzestden sonra sagird elave olundu - hedd islemedi';
  exception when check_violation then null;
  end;
end $$;
\echo 'OK  3 · guzestden sonra pulsuz hedd; movcud sagirdler qalir, tezesi olmur'

-- 4 · rpc_my_context: meblegi ve qalan gunu duzgun verir
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000165a1';
do $$
declare v jsonb; pl jsonb;
begin
  --  aktiv abune: 5 gun qalir
  update public.subscriptions set current_period_end = now() + interval '5 days'
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
  v  := public.rpc_my_context();
  pl := v->'accounts'->0->'plan';
  if pl->>'slug' <> 'sagird-basi' then raise exception 'plan yanlis: %', pl; end if;
  --  8 aktiv sagird x 150 qepik = 1200 qepik (12.00 AZN)
  if (pl->>'due_minor')::int <> 1200 then
    raise exception 'meblegi yanlis: % (gozlenilen 1200)', pl->>'due_minor'; end if;
  if (pl->>'days_left')::int not between 4 and 5 then
    raise exception 'qalan gun yanlis: %', pl->>'days_left'; end if;
  if (pl->>'grace_days')::int <> 3 then
    raise exception 'guzest gunu yanlis: %', pl->>'grace_days'; end if;

  --  guzest icinde: qalan gun MENFI, plan hele gorunur
  update public.subscriptions set current_period_end = now() - interval '2 days'
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
  pl := public.rpc_my_context()->'accounts'->0->'plan';
  if pl is null or pl = 'null'::jsonb then
    raise exception 'guzest icinde plan gorunmelidir (xatirlatma ucun)'; end if;
  if (pl->>'days_left')::int >= 0 then
    raise exception 'guzestde qalan gun menfi olmalidir: %', pl->>'days_left'; end if;

  --  guzest bitende plan artiq gorunmur
  update public.subscriptions set current_period_end = now() - interval '4 days'
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
  pl := public.rpc_my_context()->'accounts'->0->'plan';
  if pl is not null and pl <> 'null'::jsonb then
    raise exception 'guzest bitib, plan gorunmemelidir: %', pl; end if;
end $$;
\echo 'OK  4 · rpc_my_context: mebleg, qalan gun (guzestde menfi), guzest gunu'

-- 5 · dayandirilmis sagird pul tutmur
do $$
declare pl jsonb;
begin
  update public.subscriptions set current_period_end = now() + interval '10 days'
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
  update public.students set is_active = false
   where login_code in ('QYM00001','QYM00002');
  pl := public.rpc_my_context()->'accounts'->0->'plan';
  --  8 - 2 = 6 aktiv sagird x 150 = 900 qepik
  if (pl->>'due_minor')::int <> 900 then
    raise exception 'dayandirilmis sagird sayilib: % (gozlenilen 900)', pl->>'due_minor';
  end if;
end $$;
\echo 'OK  5 · dayandirilmis sagird meblege dusmur'

-- 6 · (166) qalan gun BAKI vaxti ile sayilir, bazanin UTC-si ile yox
--  Bu yoxlama SAATDAN ASILI OLMAMALIDIR.  Ona gore EYNI Baki gununun
--  iki fereqli saatini goturuuruk: saat 01:00 ve saat 23:00.
--  Baki gunune gore ikisi de EYNI gundedir -> qalan gun eyni olmalidir.
--  UTC-ye gore ise onlar AYRI gunlere dusur (01:00 Baki = evvelki gun
--  21:00 UTC) -> UTC ile hesablansa netice ferqli cixar.
do $$
declare
  b_gun  date := (now() at time zone 'Asia/Baku')::date;
  t_erken timestamptz := ((b_gun + 3) + time '01:00') at time zone 'Asia/Baku';
  t_gec   timestamptz := ((b_gun + 3) + time '23:00') at time zone 'Asia/Baku';
  d_erken int; d_gec int;
begin
  --  yoxlama qurulusu: bu iki an UTC-de HEQIQETEN ayri gunlerdedir
  if (t_erken at time zone 'UTC')::date = (t_gec at time zone 'UTC')::date then
    raise exception 'yoxlama qurulusu pozulub: UTC-de eyni gune dusdu';
  end if;

  update public.subscriptions set current_period_end = t_erken
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
  d_erken := (public.rpc_my_context()->'accounts'->0->'plan'->>'days_left')::int;

  update public.subscriptions set current_period_end = t_gec
   where account_id = 'aaaa0000-0000-0000-0000-0000000165a1';
  d_gec := (public.rpc_my_context()->'accounts'->0->'plan'->>'days_left')::int;

  if d_erken <> d_gec then
    raise exception 'eyni Baki gunu, ferqli netice: 01:00 -> %, 23:00 -> % '
      '(UTC ile hesablanir)', d_erken, d_gec;
  end if;
  if d_erken <> 3 then
    raise exception 'qalan gun yanlis: % (gozlenilen 3)', d_erken;
  end if;
end $$;
\echo 'OK  6 · qalan gun Baki gunune goredir (saatdan asili deyil)'
