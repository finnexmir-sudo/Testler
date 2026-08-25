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
  assert jsonb_array_length(v->'plans') >= 2, 'tutor planlari gelmedi';
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
    perform public.rpc_admin_grant('muellim@t.az', 'repetitor-25', 1);
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
  v := public.rpc_admin_grant('muellim@t.az', 'repetitor-25', 1);
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
  v := public.rpc_admin_grant('muellim@t.az', 'repetitor-25', 2);
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
end $$;
\echo 'OK  5 · admin siyahisi: axtaris, e-poct, plan statusu, aktivlik'

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
    perform public.rpc_admin_grant('muellim@t.az', 'repetitor-25', 99);
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
  assert not has_function_privilege('anon', 'public.rpc_admin_grant(text, text, int)', 'EXECUTE'),
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
  assert (v->>'mrr_minor')::int = 0, 'gelir sifir olmalidir';
  assert jsonb_array_length(v->'plans') >= 2, 'plan siyahisi bosdur';
  assert not exists (select 1 from jsonb_array_elements(v->'plans') p
                      where p->>'slug' = 'pulsuz'), 'pulsuz plan satis siyahisindadir';
end $$;
reset role; reset request.jwt.claim.sub;
\echo 'OK  9 · gostericiler: yalniz admin, saylar duzgun'
