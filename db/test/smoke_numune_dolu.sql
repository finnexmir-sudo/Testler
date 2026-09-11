-- =====================================================================
--  smoke_numune_dolu.sql : db/183 + db/184
--
--  Iddialar:
--   1. Numunenin paketi 'sagird-basi'-dir ve limitsizdir (Icmalda
--      "Paketin limiti dolub" xeberdarligi cixmir)
--   2. Numunede HEC BIR sagird bos deyil - herkesin en azi bir
--      teslim edilmis cehdi var
--   3. "Kim etmeyib" yene isleyir: en azi bir acıq/son tapsirigi
--      etmemis sagird var
--   4. Uc qrupun da davamiyyeti, odenis defteri ve hefte cedveli var
--   5. Bugunku hefte gunu cedveldedir (Icmalda «Bu gün dərs var»)
--   6. 11-ci sinifin uc testi AYRI-AYRI adlarla
--   7. Sagird ve valideyn girisi numunede demo=true, real hesabda false
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.app_state where key = 'demo_reset';

do $$
declare v jsonb; n int; c uuid;
begin
  v := public.rpc_demo_reset();
  assert (v->>'ok')::boolean, 'numune qurulmadi';

  -- 1 -------------------------------------------------------------- paket
  select count(*) into n from public.subscriptions s
    join public.plans p on p.id = s.plan_id
   where s.account_id = app.demo_account() and p.slug = 'sagird-basi';
  assert n = 1, 'numunede sagird-basi abunesi yoxdur: ' || n;
  assert not exists (select 1 from public.subscriptions s
                       join public.plans p on p.id = s.plan_id
                      where s.account_id = app.demo_account()
                        and p.max_students is not null),
         'numunede hele de limitli paket var';

  -- 2 -------------------------------------------------------- bos sagird
  select count(*) into n from public.students s
   where s.account_id = app.demo_account()
     and not exists (select 1 from public.attempts a
                      where a.student_id = s.id and a.status = 'submitted');
  assert n = 0, 'hec bir cehdi olmayan sagird qalib: ' || n;

  -- 3 ------------------------------------------------- "kim etmeyib" isleyir
  select count(*) into n
    from public.assignments asg
    join public.students s on s.class_id = asg.class_id
   where s.account_id = app.demo_account()
     and not exists (select 1 from public.attempts a
                      where a.student_id = s.id and a.test_id = asg.test_id
                        and a.status = 'submitted');
  assert n > 0, 'tapsirigi etmemis sagird qalmayib - "kim etmeyib" bos cixir';
end $$;
\echo 'OK  1 · paket limitsizdir'
\echo 'OK  2 · bos sagird yoxdur'
\echo 'OK  3 · "kim etmeyib" hele de isleyir'

-- 4 ve 5 ------------------------------------------- davamiyyet/odenis/cedvel
do $$
declare r record; n int;
begin
  for r in select c.id, c.name from public.classes c
            where c.account_id = app.demo_account()
  loop
    select count(*) into n from public.lessons l where l.class_id = r.id;
    assert n > 0, r.name || ': ders qeydi yoxdur';
    select count(*) into n from public.fee_payments f
      join public.students s on s.id = f.student_id where s.class_id = r.id;
    assert n > 0, r.name || ': odenis defteri bosdur';
    select count(*) into n from public.class_schedule cs where cs.class_id = r.id;
    assert n > 0, r.name || ': hefte cedveli bosdur';
  end loop;

  select count(*) into n from public.class_schedule cs
    join public.classes c on c.id = cs.class_id
   where c.account_id = app.demo_account()
     and cs.weekday = extract(isodow from (now() at time zone 'Asia/Baku'))::int;
  assert n > 0, 'bugun ucun cedvel setri yoxdur - «Bu gün dərs var» gorunmez';
end $$;
\echo 'OK  4 · uc qrupda da davamiyyet, odenis ve cedvel var'
\echo 'OK  5 · bugunku ders cedveldedir'

-- 8 ------------------------------------------------------ valideyn kodu
--  182-den sonra yeni qrupda kodlar ozu yaranir; numunede yalniz bir
--  sagirdde var idi ve gosterisde valideyn hissesi gorunmurdu.
do $$
declare n int; m int;
begin
  select count(*), count(distinct parent_code) into n, m
    from public.students where account_id = app.demo_account();
  assert n = 25, '25 sagird gozlenilir: ' || n;
  assert m = 25, 'valideyn kodu catmir ve ya tekrarlanir: ' || m;
  assert (select count(*) from public.students
           where account_id = app.demo_account() and parent_code = 'VDEMO001') = 1,
         'ana sehifedeki VDEMO001 kodu itib';
end $$;
\echo 'OK  8 · her sagirdin ferqli valideyn kodu var, VDEMO001 yerinde'

-- 6 ---------------------------------------------------- ayri-ayri adlar
do $$
declare n int; m int;
begin
  select count(distinct t.id), count(distinct t.title)
    into n, m
    from public.assignments a
    join public.tests t on t.id = a.test_id
    join public.classes c on c.id = a.class_id
   where c.account_id = app.demo_account() and c.name like '11-ci%';
  assert n = 3, '11-ci sinifde 3 test gozlenilir: ' || n;
  assert m = 3, 'testlerin adi tekrarlanir: ' || m || ' ad, ' || n || ' test';
end $$;
\echo 'OK  6 · 11-ci sinifin uc testi ayri adlidir'

-- 7 --------------------------------------------------------- demo bayragi
do $$
declare v jsonb;
begin
  v := public.rpc_student_login('DEMO0001');
  assert (v->>'ok')::boolean, 'numune sagird girisi: ' || v::text;
  assert (v->>'demo')::boolean, 'sagird girisinde demo bayragi yoxdur';
  v := public.rpc_parent_login('VDEMO001');
  assert (v->>'ok')::boolean, 'numune valideyn girisi: ' || v::text;
  assert (v->>'demo')::boolean, 'valideyn girisinde demo bayragi yoxdur';
end $$;
\echo 'OK  7a · numune girisinde demo=true'

--  Real (numune olmayan) hesab: bayraq false olmalidir
begin;
insert into auth.users (id, email) values
  ('eeee0000-0000-0000-0000-0000000000d1','ndmuel@t.az');
insert into public.profiles (id, full_name) values
  ('eeee0000-0000-0000-0000-0000000000d1','Nd Muellim')
on conflict (id) do update set full_name = excluded.full_name;
insert into public.accounts (id, owner_id, type, name) values
  ('eeea0000-0000-0000-0000-0000000000d1','eeee0000-0000-0000-0000-0000000000d1','tutor','Nd hesab');
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('eeeb0000-0000-0000-0000-0000000000d1','eeea0000-0000-0000-0000-0000000000d1',
   'eeee0000-0000-0000-0000-0000000000d1','tutor_group','Nd qrup','NDJOIN01');
insert into public.students (account_id, class_id, created_by, full_name, display_name,
                             login_code, parent_code)
values ('eeea0000-0000-0000-0000-0000000000d1','eeeb0000-0000-0000-0000-0000000000d1',
        'eeee0000-0000-0000-0000-0000000000d1','Nd Sagird','Nd S.','NDST0001','VNDST001');

do $$
declare v jsonb;
begin
  v := public.rpc_student_login('NDST0001');
  assert (v->>'ok')::boolean, 'real sagird girisi: ' || v::text;
  assert (v->>'demo')::boolean = false, 'real hesabda demo=true geldi';
  v := public.rpc_parent_login('VNDST001');
  assert (v->>'ok')::boolean, 'real valideyn girisi: ' || v::text;
  assert (v->>'demo')::boolean = false, 'real valideynde demo=true geldi';
end $$;
rollback;
\echo 'OK  7b · real hesabda demo=false'
