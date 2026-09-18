-- =====================================================================
--  smoke_giren_saygaci.sql : «Bu gün — girən müəllim» sayğacı (215)
--
--  Tekrarlanan hal (istifadeci, 18.09): muellim bu gun paneli acib,
--  Hesablar cedveli «bu gun 12:54» yazir, «Bu gun» lovhesi ise 0
--  gosterirdi.  Sebeb: seen_today yalniz auth.users.last_sign_in_at-e
--  baxirdi, Supabase ise onu ancaq PAROLLA girisde yenileyir.  Diri
--  sessiya ile girən muellim sayilmirdi.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

--  A: parolla COXDAN girib, amma BU GUN paneli acib (diri sessiya)
--  B: bu gun parolla girib
--  C: hec bir girisi yoxdur
--  D: admin - hec vaxt sayilmir
insert into auth.users (id, email, raw_user_meta_data, last_sign_in_at) values
  ('11110000-0000-0000-0000-0000000002a1','a@t.az','{"full_name":"A Muellim"}', now() - interval '20 days'),
  ('11110000-0000-0000-0000-0000000002a2','b@t.az','{"full_name":"B Muellim"}', now()),
  ('11110000-0000-0000-0000-0000000002a3','c@t.az','{"full_name":"C Muellim"}', now() - interval '30 days'),
  --  D admin BU GUN parolla da girib: motərizesiz «or» onu sayırdı
  ('11110000-0000-0000-0000-0000000002a4','d@t.az','{"full_name":"D Admin"}',   now());
insert into public.user_roles (user_id, role) values
  ('11110000-0000-0000-0000-0000000002a4','admin');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000002a1','tutor','A hesabi','11110000-0000-0000-0000-0000000002a1'),
  ('aaaa0000-0000-0000-0000-0000000002a2','tutor','B hesabi','11110000-0000-0000-0000-0000000002a2'),
  ('aaaa0000-0000-0000-0000-0000000002a3','tutor','C hesabi','11110000-0000-0000-0000-0000000002a3'),
  ('aaaa0000-0000-0000-0000-0000000002a4','tutor','D hesabi','11110000-0000-0000-0000-0000000002a4');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000002a1','11110000-0000-0000-0000-0000000002a1',true),
  ('aaaa0000-0000-0000-0000-0000000002a2','11110000-0000-0000-0000-0000000002a2',true),
  ('aaaa0000-0000-0000-0000-0000000002a3','11110000-0000-0000-0000-0000000002a3',true),
  ('aaaa0000-0000-0000-0000-0000000002a4','11110000-0000-0000-0000-0000000002a4',true);
--  A bu gun paneli acib (rpc_seen yazib), D admin de acib
update public.profiles set last_seen_at = now()
 where id in ('11110000-0000-0000-0000-0000000002a1','11110000-0000-0000-0000-0000000002a4');

set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000002a4';
do $$
declare st jsonb;
begin
  st := public.rpc_admin_stats();
  --  A (diri sessiya) + B (parolla) = 2.  C yoxdur, D admin sayilmir.
  if (st->>'seen_today')::int <> 2 then
    raise exception '215: seen_today 2 gozlenilirdi, geldi % - diri sessiya ile girən muellim sayilmir',
      st->>'seen_today';
  end if;
end $$;
\echo 'OK  1 · diri sessiya ilə girən müəllim sayılır (parolsuz)'

--  Cedvel ve lovhe EYNI seyi demelidir - ekranda ziddiyyet olmasin
do $$
declare st jsonb; v_cedvel int;
begin
  st := public.rpc_admin_stats();
  select count(*) into v_cedvel
    from jsonb_array_elements(public.rpc_admin_accounts(null, null)) r
   where not coalesce((r->>'admin')::boolean, false)
     and coalesce((r->>'demo')::boolean, false) is false
     and ((r->>'last_login')::timestamptz at time zone 'Asia/Baku')::date
         = (now() at time zone 'Asia/Baku')::date;
  if (st->>'seen_today')::int <> v_cedvel then
    raise exception '215: lovhe % deyir, cedvel % - ziddiyyet', st->>'seen_today', v_cedvel;
  end if;
end $$;
\echo 'OK  2 · lövhə və Hesablar cədvəli eyni rəqəmi deyir'

--  Dunen acilibsa BU GUN sayilmamalidir
update public.profiles set last_seen_at = now() - interval '1 day'
 where id = '11110000-0000-0000-0000-0000000002a1';
do $$
declare st jsonb;
begin
  st := public.rpc_admin_stats();
  if (st->>'seen_today')::int <> 1 then
    raise exception '215: dunenki giris bu gune sayildi (%)', st->>'seen_today';
  end if;
  --  hefte reqemi ise onu hele de gormelidir
  if (st->>'seen_week')::int <> 2 then
    raise exception '215: seen_week 2 olmalidir (%)', st->>'seen_week';
  end if;
end $$;
reset request.jwt.claim.sub;
\echo 'OK  3 · dünənki giriş bu günə sayılmır, həftəyə sayılır'
\echo 'OK  smoke_giren_saygaci — hamısı keçdi'
