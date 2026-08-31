-- =====================================================================
--  smoke_arxiv.sql : sagird arxivi - yer azad olur, kod dayanir
--                    (baza terefinde yeni kod YOXDUR: RLS + movcud
--                     trg_students_seat_limit kifayet edir; bu suite
--                     onlarin HEQIQETEN kifayet etdiyini yoxlayir)
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.class_plan_items; delete from public.class_plans;
delete from public.attempt_answers;  delete from public.attempts;
delete from public.assignments;      delete from public.student_sessions;
delete from public.students;         delete from public.classes;
delete from public.subscriptions;
delete from public.account_members;  delete from public.accounts;
delete from public.user_roles;       delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-0000000000ba','a@t.az','{"full_name":"Arxiv M"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000ba','tutor','A hesabi',
   '11110000-0000-0000-0000-0000000000ba');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000ba','11110000-0000-0000-0000-0000000000ba',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-0000000000ba','aaaa0000-0000-0000-0000-0000000000ba',
   '11110000-0000-0000-0000-0000000000ba','tutor_group','A qrupu','KODARX01');

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Pulsuz hedd 5-dir: 5 sagird girir, 6-ci girmir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000ba';
do $$
declare i int; ok boolean := false;
begin
  for i in 1..5 loop
    perform public.rpc_add_student('cccc0000-0000-0000-0000-0000000000ba',
                                   'Sagird ' || i);
  end loop;
  begin
    perform public.rpc_add_student('cccc0000-0000-0000-0000-0000000000ba', 'Altinci');
  exception when others then ok := true;
  end;
  assert ok, 'hedd dolu ikən 6-ci sagird elave olundu';
end $$;
\echo 'OK  1 · yer dolanda yeni sagird qebul olunmur'

-- =====================================================================
--  2. Bir sagird ARXIVE salinir -> yer AZAD OLUR
--     (kohne davranis: paneldə bunu etmek MUMKUN DEYILDI, yer bir
--      defe tutulurdu ve geri qayitmirdi)
-- =====================================================================
do $$
declare sid uuid; n int;
begin
  select id into sid from public.students where full_name = 'Sagird 1';
  update public.students set is_active = false where id = sid;
  select app.account_student_count('aaaa0000-0000-0000-0000-0000000000ba') into n;
  assert n = 4, 'arxivden sonra say azalmadi: ' || n;
  --  indi yeni sagird YENE girmelidir
  perform public.rpc_add_student('cccc0000-0000-0000-0000-0000000000ba', 'Altinci');
  select app.account_student_count('aaaa0000-0000-0000-0000-0000000000ba') into n;
  assert n = 5, 'azad yere yeni sagird girmedi: ' || n;
end $$;
\echo 'OK  2 · arxiv yeri azad edir, yerine yeni sagird girir'

-- =====================================================================
--  3. Geri qaytarma yerler DOLU ikən BLOKLANIR
--     (yoxsa limit yan kecilerdi: arxivle, elave et, geri qaytar)
-- =====================================================================
do $$
declare sid uuid; ok boolean := false;
begin
  select id into sid from public.students where full_name = 'Sagird 1';
  begin
    update public.students set is_active = true where id = sid;
  exception when others then ok := true;
  end;
  assert ok, 'yerler dolu ikən arxivden geri qaytarmaq alindi - limit yan kecilir';
end $$;
\echo 'OK  3 · yer yoxdursa geri qaytarma bloklanir'

-- =====================================================================
--  4. Yer acilanda geri qaytarma ISLEYIR
-- =====================================================================
do $$
declare sid uuid; oid uuid; n int; a boolean;
begin
  select id into oid from public.students where full_name = 'Altinci';
  update public.students set is_active = false where id = oid;   -- yer acildi
  select id into sid from public.students where full_name = 'Sagird 1';
  update public.students set is_active = true where id = sid;
  select is_active into a from public.students where id = sid;
  assert a, 'yer aciq ikən geri qaytarma alinmadi';
  select app.account_student_count('aaaa0000-0000-0000-0000-0000000000ba') into n;
  assert n = 5, 'geri qaytarmadan sonra say yanlisdir: ' || n;
end $$;
\echo 'OK  4 · yer acilanda geri qaytarma isleyir'

-- =====================================================================
--  5. Arxivdeki sagirdin GIRIS KODU dayanir - acıq sessiya da olsa
-- =====================================================================
reset role; reset request.jwt.claim.sub;
do $$
declare kod text; tok text; sid uuid; v jsonb; r jsonb;
begin
  select login_code, id into kod, sid from public.students
   where full_name = 'Sagird 2';
  r := public.rpc_student_login(kod);
  assert (r->>'ok')::boolean, 'aktiv sagird daxil ola bilmir';
  tok := r->>'token';
  assert app.session_student(tok) is not null, 'sessiya qurulmadi';

  --  arxive salinir - ACIQ sessiya derhal etibarsiz olmalidir
  update public.students set is_active = false where id = sid;
  assert app.session_student(tok) is null,
    'ARXIVDEKI sagirdin acıq sessiyasi hele de isleyir';

  --  yeniden giris de alinmamalidir
  r := public.rpc_student_login(kod);
  assert not (r->>'ok')::boolean, 'arxivdeki sagird yeniden daxil ola bildi';
end $$;
\echo 'OK  5 · arxivde kod dayanir, acıq sessiya da kesilir'

-- =====================================================================
--  6. Kecmis neticeler QALIR - arxiv silmek deyil
-- =====================================================================
do $$
declare sid uuid; n int;
begin
  select id into sid from public.students where full_name = 'Sagird 2';
  insert into public.attempts (student_id, test_id, status, percent, finished_at)
  select sid, t.id, 'submitted', 80, now() from public.tests t
    where status = 'published' limit 1;
  select count(*) into n from public.attempts where student_id = sid;
  assert n = 1, 'arxivdeki sagirde netice yazila bilmir';
  --  sagird setri de yerindedir
  select count(*) into n from public.students where id = sid;
  assert n = 1, 'arxiv sagirdi SILIB - bu, arxiv deyil';
end $$;
\echo 'OK  6 · arxiv silmek deyil - setir ve neticeler qalir'

\echo 'ARXIV: BUTUN YOXLAMALAR KECDI'
