-- =====================================================================
--  smoke_paket.sql : paket sehifesi ve admin idareetmesi
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000e1','admin@t.az'),
  ('11110000-0000-0000-0000-0000000000e2','muellim@t.az');
insert into public.user_roles (user_id, role) values
  ('11110000-0000-0000-0000-0000000000e1','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000e2','tutor','Muellim hesabi',
   '11110000-0000-0000-0000-0000000000e2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000e2','11110000-0000-0000-0000-0000000000e2',true);

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Paket sehifesi: abunesiz hesab planlari gorur, current bosdur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e2';
do $$
declare v jsonb;
begin
  v := public.rpc_paket();
  assert v->'current' is null or v->'current' = 'null'::jsonb, 'abunesiz current dolu geldi';
  --  169: satisda TEK qayda var - 'sagird-basi'.  Kohne pilleli
  --  paketler (repetitor-25/60/acik) baglanib: setirler bazada qalir
  --  (kohne abuneler onlara istinad edir), amma satisa cixmir.
  assert jsonb_array_length(v->'plans') = 1, 'satisda tek qayda olmalidir: '
    || (v->'plans')::text;
  assert v->'plans'->0->>'slug' = 'sagird-basi', 'satisdaki plan yanlis: '
    || (v->'plans'->0)::text;
  --  pulsuz plan siyahida olmamalidir - satis sehifesidir
  assert not exists (select 1 from jsonb_array_elements(v->'plans') p
                      where p->>'slug' = 'pulsuz'), 'pulsuz plan satisdadir';
  --  valideyn planlari tutor hesabina gosterilmir
  assert not exists (select 1 from jsonb_array_elements(v->'plans') p
                      where p->>'slug' like 'valideyn%'), 'ozge auditoriya plani geldi';
end $$;
\echo 'OK  1 · paket sehifesi: uygun planlar, artiq olanlar yox'

-- =====================================================================
--  2. Adi muellim admin funksiyalarini cagira BILMIR
-- =====================================================================
do $$
declare ok1 boolean := false; ok2 boolean := false; ok3 boolean := false;
begin
  begin
    perform public.rpc_admin_accounts(null);
  exception when insufficient_privilege then ok1 := true; end;
  begin
    perform public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 1);
  exception when insufficient_privilege then ok2 := true; end;
  begin
    perform public.rpc_admin_stop('muellim@t.az');
  exception when insufficient_privilege then ok3 := true; end;
  assert ok1 and ok2 and ok3, 'adi muellim admin emeliyyati etdi!';
end $$;
\echo 'OK  2 · adi muellim admin emeliyyatlarina toxuna bilmir'

-- =====================================================================
--  3. Admin abune acir - has_active_subscription derhal gorur
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 1);
  assert (v->>'ok')::boolean, 'grant alinmadi';
  assert app.has_active_subscription('aaaa0000-0000-0000-0000-0000000000e2'),
         'abune aktiv gorunmur';
end $$;
\echo 'OK  3 · admin bir emrle abune acir'

-- =====================================================================
--  4. Tekrar grant UZADIR, ikinci setir yaratmir
-- =====================================================================
do $$
declare v jsonb; n int; e1 timestamptz; e2 timestamptz;
begin
  select current_period_end into e1 from public.subscriptions
   where account_id = 'aaaa0000-0000-0000-0000-0000000000e2' and status='active';
  v := public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 2);
  select count(*) into n from public.subscriptions
   where account_id = 'aaaa0000-0000-0000-0000-0000000000e2'
     and status = 'active';
  assert n = 1, format('aktiv abune sayi: %s (1 gozlenilirdi)', n);
  select current_period_end into e2 from public.subscriptions
   where account_id = 'aaaa0000-0000-0000-0000-0000000000e2' and status='active';
  assert e2 > e1 + interval '50 days', 'muddet uzadilmadi';
end $$;
\echo 'OK  4 · tekrar grant muddeti uzadir, dublikat yaratmir'

-- =====================================================================
--  5. Admin siyahisi hesabi gorur
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_admin_accounts('muellim');
  assert jsonb_array_length(v) = 1, format('axtaris neticesi: %s', jsonb_array_length(v));
  assert v->0->>'email' = 'muellim@t.az', 'e-poct gorunmur';
  assert v->0->'plan'->>'status' = 'active', 'plan statusu gorunmur';
  assert v->0 ? 'groups' and v->0 ? 'attempts' and v->0 ? 'last_active',
         'aktivlik sutunlari yoxdur';
  --  pullu/pulsuz suzgeci: hesabin bu anda aktiv abunesi var
  v := public.rpc_admin_accounts(null, 'pullu');
  assert jsonb_array_length(v) = 1, 'pullu suzgeci aktiv abuneni tapmir';
  v := public.rpc_admin_accounts(null, 'pulsuz');
  assert jsonb_array_length(v) = 0, 'pulsuz suzgecine abuneli hesab dusdu';
  --  'bitir': abune ~90 gun sonra bitir - 14 gunluk pencereye dusmur
  v := public.rpc_admin_accounts(null, 'bitir');
  assert jsonb_array_length(v) = 0, 'uzaq bitme tarixi bitir siyahisina dusdu';
end $$;
--  bitmeye az qalan abune siyahiya duser (superuser tarixi qisaldir)
reset role; reset request.jwt.claim.sub;
update public.subscriptions set current_period_end = now() + interval '3 days';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_accounts(null, 'bitir');
  assert jsonb_array_length(v) = 1, 'bitmek uzre olan hesab gorunmur';
end $$;
reset role; reset request.jwt.claim.sub;
update public.subscriptions set current_period_end = now() + interval '80 days';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
\echo 'OK  5 · admin siyahisi: axtaris, plan statusu, pullu/pulsuz suzgeci'

-- =====================================================================
--  6. Dayandirmaq - abune derhal kecersizdir
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_admin_stop('muellim@t.az');
  assert (v->>'stopped')::int = 1, 'dayandirilan say sehvdir';
  assert not app.has_active_subscription('aaaa0000-0000-0000-0000-0000000000e2'),
         'abune hele aktivdir';
end $$;
\echo 'OK  6 · dayandirilan abune derhal kecersizdir'

-- =====================================================================
--  7. Yanlis e-poct ve hedden artiq ay - acıq imtina
-- =====================================================================
do $$
declare ok1 boolean := false; ok2 boolean := false;
begin
  begin
    perform public.rpc_admin_grant('yoxdur@t.az', 'repetitor-25', 1);
  exception when others then ok1 := position('tapilmadi' in sqlerrm) > 0; end;
  begin
    perform public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 99);
  exception when others then ok2 := position('1-24' in sqlerrm) > 0; end;
  assert ok1, 'yanlis e-poctda aydin xeta yoxdur';
  assert ok2, 'ay heddi yoxlanmir';
end $$;
\echo 'OK  7 · yanlis giris acıq imtina ile qarsilanir'

-- =====================================================================
--  8. anon hec birine toxuna bilmir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
begin
  assert not has_function_privilege('anon', 'public.rpc_paket(uuid)', 'EXECUTE'),
         'anon paket sehifesini gorur';
  assert not has_function_privilege('anon', 'public.rpc_admin_grant(text, text, int, boolean)', 'EXECUTE'),
         'anon abune aca bilir';
end $$;
\echo 'OK  8 · anon paket/admin funksiyalarini gormur'

-- =====================================================================
--  9. Gostericiler: yalniz admin, saylar duzgun
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e2';
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_admin_stats();
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'adi muellim gostericileri gordu!';
end $$;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb;
begin
  v := public.rpc_admin_stats();
  assert (v->>'accounts')::int = 1, 'hesab sayi sehvdir';
  --  6-ci addimda abune dayandirilib - aktiv abune qalmamalidir
  assert (v->>'active_subs')::int = 0, 'dayandirilmis abune sayilir';
  assert (v->>'paid_accounts')::int = 0, 'pullu hesab sayi sehvdir';
  assert (v->>'mrr_minor')::int = 0, 'gelir sifir olmalidir';
  assert jsonb_array_length(v->'plans') >= 2, 'plan siyahisi bosdur';
  assert not exists (select 1 from jsonb_array_elements(v->'plans') p
                      where p->>'slug' = 'pulsuz'), 'pulsuz plan satis siyahisindadir';
end $$;
reset role; reset request.jwt.claim.sub;



\echo 'OK  9 · gostericiler: yalniz admin, saylar duzgun'

-- =====================================================================
--  10. Admin panelinde TEST SAYI - class_id qusuru
--      Muellimin yigdigi testde class_id HEC VAXT dolmur; say ona gore
--      butun hesablarda hemise 0 gorunurdu.
-- =====================================================================
do $$
declare v jsonb; n int; acc uuid; usr uuid;
begin
  select a.id, a.owner_id into acc, usr from public.accounts a limit 1;
  --  class_id-SIZ test - eynen generatorun yaratdigi kimi
  insert into public.tests (owner_type, owner_id, program_id, subject_id,
                            title, status)
  select 'educator', usr, (select id from public.programs limit 1),
         (select id from public.subjects limit 1), 'Sayğac testi', 'published';

  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
  v := public.rpc_admin_accounts(null, null);
  reset role; reset request.jwt.claim.sub;

  select (x->>'tests')::int into n from jsonb_array_elements(v) x
   where (x->>'id')::uuid = acc;
  assert n >= 1,
    'class_id-siz test sayilmir - admin panelinde "0 test" gorunur (say: '
    || coalesce(n::text,'null') || ')';
end $$;
\echo 'OK 10 · class_id-siz test admin sayğacinda gorunur'

-- =====================================================================
--  11. (138) SINAQ ABUNE: pulsuz verilir, tam imkan, gelire dusmur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
delete from public.subscriptions;
--  169: gelir artiq paketin qiymeti deyil, AKTIV SAGIRD x tarif.
--  Yoxlamalar menali olsun deye hesaba 3 sagird qoyulur -> 450 qepik.
insert into public.classes (id, account_id, teacher_id, kind, name, join_code)
values ('cccc0000-0000-0000-0000-0000000000e2',
        'aaaa0000-0000-0000-0000-0000000000e2',
        '11110000-0000-0000-0000-0000000000e2', 'tutor_group',
        'Paket qrupu', 'KODPKT01');
insert into public.students (account_id, class_id, created_by, full_name,
                             display_name, login_code, is_active)
select 'aaaa0000-0000-0000-0000-0000000000e2',
       'cccc0000-0000-0000-0000-0000000000e2',
       '11110000-0000-0000-0000-0000000000e2', 'Paket Sagird ' || g,
       'P' || g, 'PKTS000' || g, true
  from generate_series(1,3) g;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb; st jsonb;
begin
  v := public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 1, true);
  assert (v->>'ok')::boolean and (v->>'trial')::boolean, 'sinaq grant alinmadi';
  assert app.has_active_subscription('aaaa0000-0000-0000-0000-0000000000e2'),
         'sinaq abune aktiv gorunmur - muellim imkan almir';
  --  169: sagird basina planda yer limiti YOXDUR (hediyye/sinaq ayinda da)
  assert app.account_seat_limit('aaaa0000-0000-0000-0000-0000000000e2') = 2147483647,
         'sinaqda yer limiti olmamalidir';
  assert exists (select 1 from public.subscriptions
                  where status = 'trialing' and provider = 'trial'), 'status trialing deyil';
  st := public.rpc_admin_stats();
  assert (st->>'paid_accounts')::int = 0, 'sinaq pullu sayildi';
  assert (st->>'trial_accounts')::int = 1, 'sinaq sayi 1 deyil';
  assert (st->>'mrr_minor')::int = 0, 'sinaq gelire dusdu: ' || (st->>'mrr_minor');
  --  suzgecler
  assert jsonb_array_length(public.rpc_admin_accounts(null, 'sinaq')) = 1, 'sinaq suzgeci tapmir';
  assert jsonb_array_length(public.rpc_admin_accounts(null, 'pullu')) = 0, 'sinaq pullu suzgecine dusdu';
  assert jsonb_array_length(public.rpc_admin_accounts(null, 'pulsuz')) = 0, 'sinaq pulsuz suzgecine dusdu';
  assert public.rpc_admin_accounts('muellim')->0->'plan'->>'status' = 'trialing', 'siyahida status trialing deyil';
  --  sinaq + sinaq = sinaq qalir, muddet uzanir
  v := public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 1, true);
  assert (v->>'trial')::boolean, 'ikinci sinaq odenisliye cevrildi';
  assert (select count(*) from public.subscriptions) = 1, 'sinaq dublikat yaratdi';
end $$;
\echo 'OK 11 · sinaq abune: tam imkan, pullu deyil, gelir sifir'

-- =====================================================================
--  12. (138) Sinaq odenisliye kecir: status active, muddet BU GUNDEN
-- =====================================================================
do $$
declare v jsonb; st jsonb; e timestamptz;
begin
  v := public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 1, false);
  assert not (v->>'trial')::boolean, 'odenisli grant sinaq qaldi';
  select current_period_end into e from public.subscriptions where status = 'active';
  assert e is not null, 'status active olmadi';
  assert e < now() + interval '32 days' and e > now() + interval '27 days',
         'odenisli muddet bu gunden baslamadi (sinaq qaligi ustune geldi): ' || e::text;
  assert (select provider from public.subscriptions) = 'manual', 'provider manual deyil';
  st := public.rpc_admin_stats();
  assert (st->>'paid_accounts')::int = 1 and (st->>'trial_accounts')::int = 0, 'odenisliye kecid saylarda yoxdur';
  --  169: 3 aktiv sagird x 150 = 450 qepik (kohne pilleli paketde 2900 idi)
  assert (st->>'mrr_minor')::int = 450, 'gelir 4,50 AZN deyil: ' || (st->>'mrr_minor');
  --  odenisli + sinaq = odenisli qalir (hediyye ay), gelir deyismir
  v := public.rpc_admin_grant('muellim@t.az', 'sagird-basi', 1, true);
  assert not (v->>'trial')::boolean, 'odenisli hesab sinaga endi';
  assert (select status from public.subscriptions) = 'active', 'odenisli status pozuldu';
end $$;
\echo 'OK 12 · sinaq -> odenisli: bu gunden, gelir sagird sayindan; odenisli sinaga enmir'

-- =====================================================================
--  13. (138) Admin sahibli hesab DAIMIDIR: abunesiz limitsiz, saylarda yox
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000e1','tutor','Admin hesabi',
   '11110000-0000-0000-0000-0000000000e1');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000e1','11110000-0000-0000-0000-0000000000e1',true);
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare v jsonb; st jsonb; p jsonb;
begin
  assert app.account_is_admin('aaaa0000-0000-0000-0000-0000000000e1'), 'admin hesabi taninmir';
  assert not app.account_is_admin('aaaa0000-0000-0000-0000-0000000000e2'), 'adi hesab admin sayildi';
  assert app.has_active_subscription('aaaa0000-0000-0000-0000-0000000000e1'),
         'admin hesabi abunesiz aktiv deyil';
  assert app.account_seat_limit('aaaa0000-0000-0000-0000-0000000000e1') > 1000000,
         'admin hesabi limitsiz deyil';
  st := public.rpc_admin_stats();
  assert (st->>'accounts')::int = 2, 'admin hesabi hesab sayinda olmalidir';
  assert (st->>'paid_accounts')::int = 1, 'admin pullu sayildi';
  assert (st->>'mrr_minor')::int = 450, 'admin gelire dusdu: '
    || (st->>'mrr_minor');
  --  siyahi: admin nisani, pullu/pulsuz suzgecinde yoxdur
  v := public.rpc_admin_accounts('Admin hesabi');
  assert (v->0->>'admin')::boolean, 'siyahida admin nisani yoxdur';
  assert jsonb_array_length(public.rpc_admin_accounts(null, 'pulsuz')) = 0, 'admin pulsuz suzgecine dusdu';
  assert jsonb_array_length(public.rpc_admin_accounts(null, 'pullu')) = 1, 'pullu suzgecinde admin var';
  --  paket sehifesi: "Admin - daimi"
  p := public.rpc_paket('aaaa0000-0000-0000-0000-0000000000e1');
  assert p->'current'->>'slug' = 'admin', 'paket sehifesi admin daimi demir';
end $$;
\echo 'OK 13 · admin sahibli hesab daimidir: limitsiz, gelir/pullu sayinda yox'

-- =====================================================================
--  14. (138) Numune nusxesi saylarda YOX, yalniz numune suzgecinde
-- =====================================================================
reset role; reset request.jwt.claim.sub;
insert into auth.users (id, email) values ('11110000-0000-0000-0000-0000000000e3', null);
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-0000000000e3','tutor','Nümunə hesabı',
   '11110000-0000-0000-0000-0000000000e3', true);
insert into public.subscriptions (account_id, plan_id, status, seats, current_period_end)
select 'aaaa0000-0000-0000-0000-0000000000e3', id, 'active', 25, now() + interval '365 days'
  from public.plans where slug = 'repetitor-25';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000e1';
do $$
declare st jsonb; v jsonb;
begin
  st := public.rpc_admin_stats();
  assert (st->>'accounts')::int = 2, 'numune hesab sayina dusdu';
  assert (st->>'paid_accounts')::int = 1, 'numune pullu sayildi';
  --  169: numune hesabin abunesi kohne 'repetitor-25'-dedir (satisdan
  --  cixib, amma setir qalir - kohne abuneler ucun).  Gelire dusmemelidir,
  --  ona gore reqem adi hesabin 3 sagirdinden gelir: 450 qepik.
  assert (st->>'mrr_minor')::int = 450, 'numune gelire dusdu: ' || (st->>'mrr_minor');
  assert (st->>'demo_accounts')::int = 1, 'numune sayi ayrica gelmir';
  v := public.rpc_admin_accounts(null, null);
  assert not exists (select 1 from jsonb_array_elements(v) x where (x->>'demo')::boolean),
         'numune "Hamisi" siyahisindadir';
  assert jsonb_array_length(public.rpc_admin_accounts(null, 'pullu')) = 1, 'numune pullu suzgecinde';
  v := public.rpc_admin_accounts(null, 'numune');
  assert jsonb_array_length(v) = 1 and (v->0->>'demo')::boolean, 'numune suzgeci nusxeni gostermir';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK 14 · numune nusxesi saylarda yox, yalniz numune suzgecinde'
