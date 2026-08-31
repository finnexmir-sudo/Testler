-- =====================================================================
--  smoke_seviyye.sql : qrup yaradilanda sinif ITMIR
--                      (db/31_seviyye_modeli.sql)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.students;        delete from public.classes;
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000fe','s@t.az','{"full_name":"Seviyye Muellim"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000fe','tutor','S hesabi',
   '11110000-0000-0000-0000-0000000000fe');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000fe','11110000-0000-0000-0000-0000000000fe',true);

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000fe';

-- =====================================================================
--  1. ESAS SEHV: 'ibtidai' proqrami ile YUXARI sinif secmek
--     Kohne kodda sinif sessizce ITIRDI (8 'ibtidai'-de yoxdur).
-- =====================================================================
do $$
declare r jsonb; v_lev uuid; v_code text;
begin
  r := public.rpc_create_class('aaaa0000-0000-0000-0000-0000000000fe',
                               'Sekkizinci qrup', 'tutor_group', 'ibtidai', '8');
  select level_id into v_lev from public.classes where id = (r->>'id')::uuid;
  assert v_lev is not null,
    '8-ci sinif ITDI - qrup sinifsiz yarandi (kohne sehv qayidib)';
  select code into v_code from public.levels where id = v_lev;
  assert v_code = '8', 'yanlis sinif yazilib: ' || coalesce(v_code, 'null');
end $$;
\echo 'OK  1 · yuxari sinif "ibtidai" gonderilse de ITMIR'

-- =====================================================================
--  2. Proqram sinifden TOREYIR - gonderilene yox
-- =====================================================================
do $$
declare r jsonb; v_prog text;
begin
  r := public.rpc_create_class('aaaa0000-0000-0000-0000-0000000000fe',
                               'Onuncu qrup', 'tutor_group', 'ibtidai', '10');
  select p.slug into v_prog from public.classes c
    join public.programs p on p.id = c.program_id
   where c.id = (r->>'id')::uuid;
  assert v_prog is not null and v_prog <> 'ibtidai',
    'proqram sinifden torenmedi: ' || coalesce(v_prog, 'null');
end $$;
\echo 'OK  2 · proqram sinifden toreyir, gonderilen deyer yox'

-- =====================================================================
--  3. Proqram ADI ile de isleyir (kohne cagirislar pozulmayib)
-- =====================================================================
do $$
declare r jsonb; v_lev uuid; v_code text;
begin
  r := public.rpc_create_class('aaaa0000-0000-0000-0000-0000000000fe',
                               'Dorduncu qrup', 'tutor_group', 'ibtidai', '4');
  select level_id into v_lev from public.classes where id = (r->>'id')::uuid;
  select code into v_code from public.levels where id = v_lev;
  assert v_code = '4', 'ibtidai sinif pozulub: ' || coalesce(v_code, 'null');
end $$;
\echo 'OK  3 · ibtidai sinifler eskisi kimi isleyir'

-- =====================================================================
--  4. Sinifsiz qrup yene yaranir (mecburi deyil)
-- =====================================================================
do $$
declare r jsonb; v_lev uuid;
begin
  r := public.rpc_create_class('aaaa0000-0000-0000-0000-0000000000fe',
                               'Sinifsiz qrup', 'tutor_group', null, null);
  select level_id into v_lev from public.classes where id = (r->>'id')::uuid;
  assert v_lev is null, 'sinifsiz qrupda sinif peyda oldu';
end $$;
\echo 'OK  4 · sinif mecburi deyil - sinifsiz qrup yaranir'

-- =====================================================================
--  5. Olmayan sinif SESSIZ udulmur - xeta atir
-- =====================================================================
do $$
declare ok boolean := false;
begin
  begin
    perform public.rpc_create_class('aaaa0000-0000-0000-0000-0000000000fe',
                                    'Yanlis qrup', 'tutor_group', null, '99');
  exception when others then ok := true;
  end;
  assert ok, 'olmayan sinif sessizce udulub - kohne davranis qayidib';
end $$;
\echo 'OK  5 · olmayan sinif sessiz udulmur, xeta atir'

-- =====================================================================
--  6. Reqem kodlu sinifler TEKDIR - indeks tekrari bloklayir
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare ok boolean := false; v_prog uuid;
begin
  select id into v_prog from public.programs where slug = 'miq';
  begin
    insert into public.levels (program_id, code, name, sort)
    values (v_prog, '8', 'Sekkiz - tekrar', 999);
    ok := false;
  exception when unique_violation then ok := true;
  end;
  assert ok, 'reqem kodlu sinif TEKRAR yaradila bildi - indeks islemir';
end $$;
\echo 'OK  6 · sinif kodu tekrari baza seviyyesinde bloklanir'

-- =====================================================================
--  7. MIQ/sertifikasiya seviyyeleri toxunulmayib (kodlari reqem deyil)
-- =====================================================================
do $$
declare v_n int;
begin
  select count(*) into v_n from public.levels
   where code = 'riyaziyyat';
  assert v_n >= 2,
    'MIQ/sertifikasiya seviyyeleri pozulub: riyaziyyat kodu ' || v_n || ' defe';
end $$;
\echo 'OK  7 · MIQ/sertifikasiya seviyyelerine toxunulmayib'

\echo 'SEVIYYE: BUTUN YOXLAMALAR KECDI'
