-- smoke_valideyn_susma.sql - db/182: valideyn girisi susmaya gore aciq
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email) values
  ('eeee0000-0000-0000-0000-0000000000f1','vsmuel@t.az');
insert into public.profiles (id, full_name) values
  ('eeee0000-0000-0000-0000-0000000000f1','Vs Muellim')
on conflict (id) do update set full_name = excluded.full_name;
insert into public.accounts (id, owner_id, type, name) values
  ('eeea0000-0000-0000-0000-0000000000f1','eeee0000-0000-0000-0000-0000000000f1','tutor','Vs hesab');
insert into public.account_members values
  ('eeea0000-0000-0000-0000-0000000000f1','eeee0000-0000-0000-0000-0000000000f1',true);

set role authenticated;
set request.jwt.claim.sub = 'eeee0000-0000-0000-0000-0000000000f1';

-- =====================================================================
--  1. YENI qrup: bayraq susmaya gore ACIQDIR
-- =====================================================================
do $$
declare v jsonb; v_cls uuid;
begin
  v := public.rpc_create_class('eeea0000-0000-0000-0000-0000000000f1', 'Usaq qrupu',
                               'tutor_group', null);
  v_cls := (v->>'id')::uuid;
  assert (select parent_access from public.classes where id = v_cls),
         'yeni qrupda valideyn girisi bagli geldi';
end $$;
\echo 'OK  1 · yeni qrupda valideyn girisi aciqdir'

-- =====================================================================
--  2. Sagird elave olunanda valideyn kodu OZU yaranir
-- =====================================================================
do $$
declare v jsonb; v_cls uuid; v_st uuid; v_code text;
begin
  select id into v_cls from public.classes where name = 'Usaq qrupu';
  v := public.rpc_add_student(v_cls, 'Nurə Məmmədova');
  v_st := (v->>'id')::uuid;
  assert v->>'parent_code' is not null, 'cavabda valideyn kodu yoxdur';
  select parent_code into v_code from public.students where id = v_st;
  assert v_code is not null, 'bazada valideyn kodu yaranmadi';
  assert left(v_code, 1) = 'V', 'valideyn kodu V ile baslamir: ' || v_code;
  assert v_code <> (select login_code from public.students where id = v_st),
         'valideyn kodu sagird kodu ile eynidir - ciddi sehv';
end $$;
\echo 'OK  2 · sagird elave olunanda valideyn kodu ozu yaranir'

-- =====================================================================
--  3. Qrup bayragi SONDURULENDE movcud kodlar da olur
--     («bagladim, amma hele de baxir» olmasin)
-- =====================================================================
do $$
declare v_cls uuid; v jsonb; n int;
begin
  select id into v_cls from public.classes where name = 'Usaq qrupu';
  v := public.rpc_class_parent_access(v_cls, false);
  assert (v->>'parent_access')::boolean = false, 'bayraq sonmedi';
  select count(*) into n from public.students
   where class_id = v_cls and parent_code is not null;
  assert n = 0, 'bagladiqdan sonra kod qaldi: ' || n;
end $$;
\echo 'OK  3 · qrup baglananda movcud kodlar silinir'

-- =====================================================================
--  4. Bayraq BAGLI olanda yeni sagirde kod YARANMIR
-- =====================================================================
do $$
declare v_cls uuid; v jsonb;
begin
  select id into v_cls from public.classes where name = 'Usaq qrupu';
  v := public.rpc_add_student(v_cls, 'Rəşad Əliyev');
  assert v->>'parent_code' is null, 'bagli qrupda kod yarandi';
end $$;
\echo 'OK  4 · bagli qrupda yeni sagirde kod yaranmir'

-- =====================================================================
--  5. Yeniden ACILANDA kodu olmayan sagirdlere kod verilir
-- =====================================================================
do $$
declare v_cls uuid; v jsonb; n int;
begin
  select id into v_cls from public.classes where name = 'Usaq qrupu';
  v := public.rpc_class_parent_access(v_cls, true);
  assert (v->>'deyisen')::int = 2, 'iki sagird gozlenilirdi: ' || (v->>'deyisen');
  select count(*) into n from public.students
   where class_id = v_cls and parent_code is null and is_active;
  assert n = 0, 'kodsuz sagird qaldi: ' || n;
end $$;
\echo 'OK  5 · yeniden acilanda kodsuz sagirdlere kod verilir'

-- =====================================================================
--  6. Basqasinin qrupuna toxunmaq olmur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
--  Yad muellim qrupu RLS-e gore GORMUR - «select id» null qaytarir
--  ve funksiya «Qrup tapilmadi» deyir.  Bu, duzgun davranisdir, amma
--  yoxlamaq istediyimiz sey basqadir: id ELINDE OLSA da toxuna
--  bilmemelidir.  Ona gore id evvelceden goturulur.
create temp table vs_id on commit drop as
  select id from public.classes where name = 'Usaq qrupu';
grant select on vs_id to authenticated;
insert into auth.users (id, email) values
  ('eeee0000-0000-0000-0000-0000000000f2','vsyad@t.az');
insert into public.profiles (id, full_name) values
  ('eeee0000-0000-0000-0000-0000000000f2','Yad Muellim')
on conflict (id) do update set full_name = excluded.full_name;
set role authenticated;
set request.jwt.claim.sub = 'eeee0000-0000-0000-0000-0000000000f2';
do $$
declare v_cls uuid;
begin
  select id into v_cls from vs_id;
  assert v_cls is not null, 'qrup id-si goturulmedi';
  begin
    perform public.rpc_class_parent_access(v_cls, false);
    raise exception 'SEHV: yad muellim qrupun ayarini deyisdi';
  exception when sqlstate '42501' then null;
  end;
end $$;
\echo 'OK  6 · yad muellim qrupun valideyn ayarina toxuna bilmir'

reset role; reset request.jwt.claim.sub;
rollback;
\echo 'VALIDEYN SUSMA: BUTUN YOXLAMALAR KECDI'
