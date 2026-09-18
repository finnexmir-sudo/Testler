-- =====================================================================
--  smoke_paylas.sql : «Dostuna at» - sual paylasimi (214)
--
--  Esas iddia BANK QAPISIDIR: girissiz acilan sehife yalniz sagirdin
--  OZUNUN cavabladigi sualı gostere biler ve duz variant CAVABDAN EVVEL
--  getmir.  Qalanlari: gunluk hedd, omur, acilis heddi, olcu.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.shares;
delete from public.daily_packs;
delete from public.mistakes;
delete from public.student_sessions;
delete from public.attempt_answers where attempt_id in
  (select id from public.attempts where student_id in
    (select id from public.students where login_code in ('PAY00001','PAY00002')));
delete from public.attempts where student_id in
  (select id from public.students where login_code in ('PAY00001','PAY00002'));
delete from public.students where login_code in ('PAY00001','PAY00002');
delete from public.classes where id = 'cccc0000-0000-0000-0000-000000000214';
delete from public.accounts where id = 'aaaa0000-0000-0000-0000-000000000214';

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-000000000214','pay@t.az','{"full_name":"Pay Muellim"}')
on conflict (id) do nothing;
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-000000000214','tutor','Pay hesabi','11110000-0000-0000-0000-000000000214')
on conflict (id) do nothing;
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-000000000214','11110000-0000-0000-0000-000000000214',true)
on conflict do nothing;
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id) values
  ('cccc0000-0000-0000-0000-000000000214','aaaa0000-0000-0000-0000-000000000214',
   '11110000-0000-0000-0000-000000000214','tutor_group','Pay qrup','KODPAY14',
   (select id from public.levels order by sort limit 1))
on conflict (id) do nothing;
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code) values
  ('5555000e-0000-0000-0000-000000000214','aaaa0000-0000-0000-0000-000000000214',
   'cccc0000-0000-0000-0000-000000000214','11110000-0000-0000-0000-000000000214',
   'Aysu Memmedova','Aysu M.','PAY00001')
on conflict (id) do nothing;
insert into public.student_sessions (token_hash, student_id, expires_at) values
  (app.hash_token('pay-tok'),'5555000e-0000-0000-0000-000000000214', now() + interval '1 day')
on conflict (token_hash) do nothing;

--  Sagird DORD suala cavab verir (gunluk hedd + tekrar ucun lazimdir)
do $$
declare v_test uuid; v_att uuid; q record; i int := 0; ids uuid[] := '{}';
begin
  insert into public.tests (owner_type, owner_id, class_id, program_id, subject_id, level_id, title, status)
  select 'educator','11110000-0000-0000-0000-000000000214',
         'cccc0000-0000-0000-0000-000000000214',
         (select id from public.programs order by id limit 1),
         q2.subject_id, q2.level_id, 'Pay testi','published'
    from public.questions q2 where q2.status='published' and q2.kind='single' limit 1
  returning id into v_test;
  insert into public.attempts (test_id, student_id, class_id, status, finished_at, score, max_score, percent)
  values (v_test,'5555000e-0000-0000-0000-000000000214',
          'cccc0000-0000-0000-0000-000000000214','submitted', now(), 4, 4, 100)
  returning id into v_att;
  for q in select id, topic_id from public.questions
            where status='published' and kind='single'
              and exists (select 1 from public.question_options o
                           where o.question_id = questions.id and o.is_correct)
              and exists (select 1 from public.question_options o2
                           where o2.question_id = questions.id and not o2.is_correct)
            limit 4 loop
    i := i + 1;
    ids := ids || q.id;
    insert into public.test_questions (test_id, question_id, ord) values (v_test, q.id, i);
    insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, points)
    values (v_att, q.id, q.topic_id, true, 1);
  end loop;
  if i < 4 then raise exception '214 fikstur: 4 sual lazimdir (%)', i; end if;
  perform set_config('smoke.q1', ids[1]::text, false);
  perform set_config('smoke.q2', ids[2]::text, false);
  perform set_config('smoke.q3', ids[3]::text, false);
  perform set_config('smoke.q4', ids[4]::text, false);
  --  sagirdin GORMEDIYI sual
  perform set_config('smoke.yad',
    (select q3.id::text from public.questions q3
      where q3.status='published' and q3.kind='single' and not (q3.id = any(ids))
        and exists (select 1 from public.question_options o where o.question_id = q3.id and o.is_correct)
      limit 1), false);
end $$;

-- =====================================================================
--  1 · BANK QAPISI: gormediyi sualı paylasa bilmir
-- =====================================================================
set role anon;
do $$
begin
  begin
    perform public.rpc_share_make('pay-tok', current_setting('smoke.yad')::uuid);
    raise exception '214/1: gormediyi sual paylasildi - BANK ACIQDIR';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
\echo 'OK  1 · görmədiyi sualı paylaşa bilmir (bank qapısı)'

-- =====================================================================
--  2 · Oz sualını paylasir; token 12 simvol, unikal
-- =====================================================================
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_share_make('pay-tok', current_setting('smoke.q1')::uuid);
  if length(r->>'k') <> 12 then raise exception '214/2: acar uzunlugu % (12 gozlenilir)', length(r->>'k'); end if;
  if (r->>'tekrar')::boolean then raise exception '214/2: yeni link «tekrar» gelmemelidir'; end if;
  if (r->>'qaliq')::int <> 2 then raise exception '214/2: qaliq 2 olmalidir (%)', r->>'qaliq'; end if;
  perform set_config('smoke.k1', r->>'k', false);
  --  eyni sual: KVOTA YANMIR, eyni link qayidir
  r := public.rpc_share_make('pay-tok', current_setting('smoke.q1')::uuid);
  if not (r->>'tekrar')::boolean or r->>'k' <> current_setting('smoke.k1') then
    raise exception '214/2: eyni sual ucun ikinci link yarandi';
  end if;
end $$;
reset role;
\echo 'OK  2 · öz sualını paylaşır; eyni sual kvota yandırmır'

-- =====================================================================
--  3 · Dost acir: DUZ VARIANT GETMIR, sagirdin TAM ADI getmir
-- =====================================================================
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_share_open(current_setting('smoke.k1'));
  if not (r->>'ok')::boolean then raise exception '214/3: link acilmadi'; end if;
  if r::text like '%is_correct%' then raise exception '214/3: DUZ VARIANT SIZDI'; end if;
  if r::text like '%Memmedova%' then raise exception '214/3: sagirdin TAM ADI sizdi'; end if;
  if r->>'kim' <> 'Aysu M.' then raise exception '214/3: gorunen ad yanlis (%)', r->>'kim'; end if;
  if jsonb_array_length(r->'question'->'options') < 2 then raise exception '214/3: variantlar gelmedi'; end if;
end $$;
reset role;
\echo 'OK  3 · düz variant və tam ad göndərilmir'

-- =====================================================================
--  4 · Cavab serverde yoxlanir; sayğaclar artir
-- =====================================================================
do $$
declare v_o uuid;
begin
  select o.id into v_o from public.question_options o
   where o.question_id = current_setting('smoke.q1')::uuid and not o.is_correct limit 1;
  perform set_config('smoke.sehv', v_o::text, false);
  select o.id into v_o from public.question_options o
   where o.question_id = current_setting('smoke.q1')::uuid and o.is_correct limit 1;
  perform set_config('smoke.duz', v_o::text, false);
end $$;
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_share_answer(current_setting('smoke.k1'), current_setting('smoke.sehv')::uuid);
  if (r->>'correct')::boolean then raise exception '214/4: sehv cavab duz sayildi'; end if;
  if r->>'right_id' <> current_setting('smoke.duz') then
    raise exception '214/4: duz variant cavabdan SONRA bildirilmelidir';
  end if;
  r := public.rpc_share_answer(current_setting('smoke.k1'), current_setting('smoke.duz')::uuid);
  if not (r->>'correct')::boolean then raise exception '214/4: duz cavab sehv sayildi'; end if;
  --  bil10.az kliki
  r := public.rpc_share_open(current_setting('smoke.k1'), 'click');
  if not (r->>'klik')::boolean then raise exception '214/4: klik sayilmadi'; end if;
end $$;
reset role;
do $$
declare s public.shares%rowtype;
begin
  select * into s from public.shares where k = current_setting('smoke.k1');
  --  1-ci bolmede bir acilis + 3-cu bolmede bir acilis
  if s.opens < 1 then raise exception '214/4: acilis sayilmadi (%)', s.opens; end if;
  if s.answers <> 2 or s.ok_n <> 1 then
    raise exception '214/4: cavab sayğaci yanlis (%, %)', s.answers, s.ok_n;
  end if;
  if s.clicks <> 1 then raise exception '214/4: klik sayğaci yanlis (%)', s.clicks; end if;
end $$;
\echo 'OK  4 · cavab serverdə yoxlanır, sayğaclar artır'

-- =====================================================================
--  5 · Gunluk hedd: 3 link, dorduncu redd olunur
-- =====================================================================
set role anon;
do $$
begin
  perform public.rpc_share_make('pay-tok', current_setting('smoke.q2')::uuid);
  perform public.rpc_share_make('pay-tok', current_setting('smoke.q3')::uuid);
  begin
    perform public.rpc_share_make('pay-tok', current_setting('smoke.q4')::uuid);
    raise exception '214/5: gunluk hedd islemedi';
  exception when sqlstate '42901' then null;
  end;
end $$;
reset role;
\echo 'OK  5 · gündə 3 link — dördüncü rədd olunur'

-- =====================================================================
--  6 · Omur ve acilis heddi
-- =====================================================================
update public.shares set expires_at = now() - interval '1 hour' where k = current_setting('smoke.k1');
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_share_open(current_setting('smoke.k1'));
  if (r->>'ok')::boolean or r->>'reason' <> 'vaxt' then
    raise exception '214/6: vaxti bitmis link acildi (%)', r::text;
  end if;
  begin
    perform public.rpc_share_answer(current_setting('smoke.k1'), current_setting('smoke.duz')::uuid);
    raise exception '214/6: vaxti bitmis linke cavab qebul olundu';
  exception when sqlstate '22023' then null;
  end;
  --  yad acar
  r := public.rpc_share_open('yoxbelekey1');
  if (r->>'ok')::boolean or r->>'reason' <> 'yox' then
    raise exception '214/6: yad acar acildi';
  end if;
end $$;
reset role;
update public.shares set expires_at = now() + interval '7 days', opens = app.share_max_opens()
 where k = current_setting('smoke.k1');
set role anon;
do $$
declare r jsonb;
begin
  r := public.rpc_share_open(current_setting('smoke.k1'));
  if (r->>'ok')::boolean or r->>'reason' <> 'hedd' then
    raise exception '214/6: acilis heddi islemedi (%)', r::text;
  end if;
end $$;
reset role;
\echo 'OK  6 · 7 gün ömür, açılış həddi, yad açar'

-- =====================================================================
--  7 · Yad token linki duzelde bilmir
-- =====================================================================
set role anon;
do $$
begin
  begin
    perform public.rpc_share_make('yad-token-123', current_setting('smoke.q1')::uuid);
    raise exception '214/7: yad token link duzeltdi';
  exception when invalid_authorization_specification then null;
  end;
end $$;
reset role;
\echo 'OK  7 · yad token link düzəldə bilmir'

-- =====================================================================
--  8 · Olcu: hunide paylasim zenciri
-- =====================================================================
insert into public.user_roles (user_id, role) values
  ('11110000-0000-0000-0000-000000000214','admin') on conflict do nothing;
set request.jwt.claim.sub = '11110000-0000-0000-0000-000000000214';
do $$
declare t jsonb;
begin
  t := public.rpc_admin_huni(30)->'paylasim';
  if t is null then raise exception '214/8: huni «paylasim» bloku yoxdur'; end if;
  if (t->>'gonderildi')::int <> 3 then
    raise exception '214/8: gonderildi 3 gozlenilirdi (%)', t->>'gonderildi';
  end if;
  if (t->>'sagird')::int <> 1 then raise exception '214/8: sagird 1 olmalidir (%)', t->>'sagird'; end if;
  if (t->>'cavabladi')::int <> 2 then raise exception '214/8: cavabladi 2 olmalidir (%)', t->>'cavabladi'; end if;
  if (t->>'klik')::int <> 1 then raise exception '214/8: klik 1 olmalidir (%)', t->>'klik'; end if;
end $$;
reset request.jwt.claim.sub;
delete from public.user_roles where user_id = '11110000-0000-0000-0000-000000000214';
\echo 'OK  8 · hunidə paylaşım zənciri (göndərildi → açıldı → cavabladı → klik)'

delete from public.shares;
\echo 'OK  smoke_paylas — hamısı keçdi'
