-- =====================================================================
--  smoke_mesq.sql : ders mesqi (db/935, 936 - pilot riy 5)
--
--  Iddialar:
--   1 · mesq sualı test mexanizmine QARISMIR: bank siyahisi, generator,
--       adaptiv mesq hovuzu, gunun 5 suali hovuzu, ders testi sayi gormur
--   2 · muellim: yalniz mesq sualı olan dersler; qrupa ve tek sagirde verir;
--       sira asandan cetine (difficulty, ext_key) dondurulur; basqa muellim
--       vere / gore / sile bilmir; bos ders redd
--   3 · sagird: suallar sira ile; duz variant (is_correct) sagirde getmir;
--       sehife yenilenende eyni sual eyni reqemle; cavab -> duz/sehv + izah;
--       ikinci defe cavab redd; sablon sualda reqem saxlanir ve duz yoxlanir;
--       sexsi mesqi basqa sagird gormur / aca bilmir
--   4 · hesabat: baslayan / bitiren / duz %, en cox sehv olunan sual;
--       valideyn setri; attempts-e hec ne yazilmir
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.mesq_assignments;
delete from public.homework_done; delete from public.homework;
delete from public.parent_sessions; delete from public.student_sessions;
delete from public.practice;
delete from public.students; delete from public.classes;
delete from public.attempt_answers; delete from public.attempts; delete from public.assignments;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles; delete from public.profiles; delete from auth.users;
delete from public.questions where ext_key like 'smkmesq-%';
delete from public.topics where slug like 'smk-mesq-%';

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000f1','mesq-muellim@t.az'),
  ('11110000-0000-0000-0000-0000000000f2','mesq-basqa@t.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000f1','tutor','Mesq hesabi','11110000-0000-0000-0000-0000000000f1'),
  ('aaaa0000-0000-0000-0000-0000000000f2','tutor','Basqa hesab','11110000-0000-0000-0000-0000000000f2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000f1','11110000-0000-0000-0000-0000000000f1',true),
  ('aaaa0000-0000-0000-0000-0000000000f2','11110000-0000-0000-0000-0000000000f2',true);
insert into public.subscriptions (account_id, plan_id, status, current_period_end)
select a, p.id, 'active', now() + interval '30 days'
  from public.plans p, unnest(array['aaaa0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f2']::uuid[]) a
 where p.slug = 'repetitor-25';
insert into public.classes (id, account_id, teacher_id, kind, name, join_code, level_id) values
  ('cccc0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','Mesq qrupu','MESQQRP1',
   (select id from public.levels where code = '5' order by sort limit 1)),
  ('cccc0000-0000-0000-0000-0000000000f3','aaaa0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','tutor_group','7-ci sinif','MESQQRP3',
   (select id from public.levels where code = '7' order by sort limit 1));
insert into public.students (id, account_id, class_id, created_by, full_name, display_name, login_code, parent_code) values
  ('dddd0000-0000-0000-0000-0000000000f1','aaaa0000-0000-0000-0000-0000000000f1','cccc0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','Aysu Mesq','Aysu M.','MSAYSU01','VMSAYSU1'),
  ('dddd0000-0000-0000-0000-0000000000f2','aaaa0000-0000-0000-0000-0000000000f1','cccc0000-0000-0000-0000-0000000000f1',
   '11110000-0000-0000-0000-0000000000f1','Kenan Mesq','Kenan M.','MSKENAN1','VMSKENA1');

--  movzu: 5-ci sinif riyaziyyat fesli + iki ders (yarpaq)
insert into public.topics (id, subject_id, level_id, slug, name, sort)
select 'eeee0000-0000-0000-0000-0000000000f0', s.id, l.id, 'smk-mesq-fesil', 'Mesq fesli', 9990
  from public.subjects s, public.levels l where s.slug = 'riyaziyyat' and l.code = '5';
insert into public.topics (id, subject_id, level_id, parent_id, slug, name, sort)
select x.id, s.id, l.id, 'eeee0000-0000-0000-0000-0000000000f0', x.slug, x.name, x.sort
  from public.subjects s, public.levels l,
       (values ('eeee0000-0000-0000-0000-0000000000f1'::uuid, 'smk-mesq-ders1', 'Toplama dersi', 1),
               ('eeee0000-0000-0000-0000-0000000000f2'::uuid, 'smk-mesq-ders2', 'Bos ders', 2)) x(id, slug, name, sort)
 where s.slug = 'riyaziyyat' and l.code = '5';

--  ders 1: 6 mesq suali (qarisiq sirada yazilir - server duzmelidir) + 1 adi (published) sual.
--  #4 sablon: {a}+{b}.  Hamisinin govdesinde MESQSIZMA nisani (bank axtarisi ucun).
insert into public.questions (id, owner_type, subject_id, level_id, topic_id, tags, kind, body, explanation, difficulty, status, ext_key, params)
select x.id, 'platform', s.id, l.id, 'eeee0000-0000-0000-0000-0000000000f0',
       case when x.st = 'mesq' then array['ders:smk-mesq-ders1', 'mesq'] else array['ders:smk-mesq-ders1'] end,
       'single', x.body, x.ex, x.d, x.st::public.content_status, x.ek, x.par::jsonb
  from public.subjects s, public.levels l,
       (values
        ('ffff0000-0000-0000-0000-000000000003'::uuid, 'MESQSIZMA cetin 1', 'izah c1', 3::smallint, 'mesq', 'smkmesq-d1#005', null),
        ('ffff0000-0000-0000-0000-000000000001'::uuid, 'MESQSIZMA asan 2',  'izah a2', 1::smallint, 'mesq', 'smkmesq-d1#002', null),
        ('ffff0000-0000-0000-0000-000000000002'::uuid, 'MESQSIZMA asan 1',  'izah a1', 1::smallint, 'mesq', 'smkmesq-d1#001', null),
        ('ffff0000-0000-0000-0000-000000000004'::uuid, 'MESQSIZMA {a} + {b} = ?', '{a} + {b} = {a+b}', 2::smallint, 'mesq', 'smkmesq-d1#003',
         '{"vars": {"a": [100, 999], "b": [100, 999]}}'),
        ('ffff0000-0000-0000-0000-000000000005'::uuid, 'MESQSIZMA orta 2',  'izah o2', 2::smallint, 'mesq', 'smkmesq-d1#004', null),
        ('ffff0000-0000-0000-0000-000000000006'::uuid, 'MESQSIZMA cetin 2', 'izah c2', 3::smallint, 'mesq', 'smkmesq-d1#006', null),
        ('ffff0000-0000-0000-0000-000000000009'::uuid, 'Adi test suali',    'izah t',  2::smallint, 'published', 'smkmesq-test#001', null)
       ) x(id, body, ex, d, st, ek, par)
 where s.slug = 'riyaziyyat' and l.code = '5';
insert into public.question_options (question_id, ord, body, is_correct)
select q.id, o.ord, case when q.params is null then o.b else o.tb end, o.ok
  from public.questions q,
       (values (1, 'duz', '{a+b}', true), (2, 'sehv-1', '{a+b+10}', false), (3, 'sehv-2', '{a+b-10}', false)) o(ord, b, tb, ok)
 where q.ext_key like 'smkmesq-%';

create or replace function pg_temp.duz(p_q uuid) returns uuid[] language sql security definer as $$
  select coalesce(array_agg(o.id), '{}') from public.question_options o where o.question_id = p_q and o.is_correct $$;
create or replace function pg_temp.sehv(p_q uuid) returns uuid[] language sql security definer as $$
  select array[o.id] from public.question_options o where o.question_id = p_q and not o.is_correct order by o.ord limit 1 $$;

\echo '--- hazirliq tamam'

-- =====================================================================
--  1. Test mexanizmine qarismir
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; n int;
begin
  v := public.rpc_bank_list('{"pool":"platform","q":"MESQSIZMA"}'::jsonb);
  assert (v->>'total')::int = 0, 'bank siyahisinda mesq sualı: ' || (v->>'total');
  v := public.rpc_generate_test(
         jsonb_build_object('pool', 'platform', 'subject', 'riyaziyyat', 'level', '5',
                            'topics', jsonb_build_array('eeee0000-0000-0000-0000-0000000000f0'), 'count', 1), 'Mesq sizma');
  select count(*) into n from public.test_questions tq join public.questions q on q.id = tq.question_id
   where tq.test_id = (v->>'test_id')::uuid and q.status::text = 'mesq';
  assert n = 0, 'generator mesq sualı goturdu: ' || n;
  select count(*) into n from public.test_questions tq where tq.test_id = (v->>'test_id')::uuid;
  assert n = 1, 'generator adi suali goturmeli idi (1), aldi: ' || n;
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare v_lvl uuid := (select id from public.levels where code = '5' order by sort limit 1);
begin
  assert not exists (select 1 from app.practice_pool('eeee0000-0000-0000-0000-0000000000f0', v_lvl,
                       'aaaa0000-0000-0000-0000-0000000000f1') x
                      join public.questions q on q.id = x.id where q.status::text = 'mesq'), 'adaptiv mesq hovuzunda mesq suali';
  assert not exists (select 1 from app.daily_pool('eeee0000-0000-0000-0000-0000000000f0', v_lvl,
                       'aaaa0000-0000-0000-0000-0000000000f1') x
                      join public.questions q on q.id = x.id where q.status::text = 'mesq'), 'gunun 5 suali hovuzunda mesq suali';
  assert app.ders_sual_setir('eeee0000-0000-0000-0000-0000000000f0', 'smk-mesq-ders1') = 1, 'ders testi sayi mesq sualini saydi';
end $$;
\echo 'OK  1 · mesq sualı bank siyahisi, generator, adaptiv, gunun 5 suali, ders testi sayinda yoxdur'

-- =====================================================================
--  2. Muellim: dersler, vermek, huquq
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; it jsonb; bos boolean := false;
begin
  v := public.rpc_mesq_lessons('cccc0000-0000-0000-0000-0000000000f1');
  select x into it from jsonb_array_elements(v->'items') x where x->>'id' = 'eeee0000-0000-0000-0000-0000000000f1';
  assert it is not null and (it->>'n')::int = 6, 'ders 1 siyahida 6 sualla olmali: ' || left(v::text, 200);
  assert not exists (select 1 from jsonb_array_elements(v->'items') x where x->>'id' = 'eeee0000-0000-0000-0000-0000000000f2'),
         'mesq sualı olmayan ders siyahida';
  --  7-ci sinif qrupu: 5-ci sinif dersi gorunmur
  v := public.rpc_mesq_lessons('cccc0000-0000-0000-0000-0000000000f3');
  assert not exists (select 1 from jsonb_array_elements(v->'items') x where x->>'id' = 'eeee0000-0000-0000-0000-0000000000f1'),
         'basqa sinfin qrupunda 5-ci sinif dersi';

  v := public.rpc_mesq_assign('cccc0000-0000-0000-0000-0000000000f1', 'eeee0000-0000-0000-0000-0000000000f1', null, current_date + 7);
  assert (v->>'n')::int = 6, 'qrupa: ' || v::text;
  perform set_config('smoke.m1', v->>'id', false);
  v := public.rpc_mesq_assign('cccc0000-0000-0000-0000-0000000000f1', 'eeee0000-0000-0000-0000-0000000000f1',
                              'dddd0000-0000-0000-0000-0000000000f2', null);
  perform set_config('smoke.m2', v->>'id', false);
  begin
    perform public.rpc_mesq_assign('cccc0000-0000-0000-0000-0000000000f1', 'eeee0000-0000-0000-0000-0000000000f2', null, null);
  exception when others then bos := true;
  end;
  assert bos, 'sualsiz ders verildi';
  bos := false;
  begin
    perform public.rpc_mesq_assign('cccc0000-0000-0000-0000-0000000000f1', 'eeee0000-0000-0000-0000-0000000000f1', null, current_date - 1);
  exception when others then bos := true;
  end;
  assert bos, 'kecmis son tarix qebul olundu';
  v := public.rpc_mesq_list('cccc0000-0000-0000-0000-0000000000f1');
  assert jsonb_array_length(v) = 2, 'siyahi 2 olmali';
  assert (select (x->>'targets')::int from jsonb_array_elements(v) x where x->>'id' = current_setting('smoke.m1')) = 2, 'qrup hedefi 2';
  assert (select (x->>'targets')::int from jsonb_array_elements(v) x where x->>'id' = current_setting('smoke.m2')) = 1, 'sexsi hedef 1';
end $$;
reset role; reset request.jwt.claim.sub;
--  sira asandan cetine (difficulty, ext_key) dondurulub - cedvel yalniz RPC ile, ona gore rolsuz baxilir
do $$
declare qids uuid[];
begin
  select m.qids into qids from public.mesq_assignments m where m.id = current_setting('smoke.m1')::uuid;
  assert qids = array['ffff0000-0000-0000-0000-000000000002','ffff0000-0000-0000-0000-000000000001',
                      'ffff0000-0000-0000-0000-000000000004','ffff0000-0000-0000-0000-000000000005',
                      'ffff0000-0000-0000-0000-000000000003','ffff0000-0000-0000-0000-000000000006']::uuid[],
         'sira asandan cetine deyil: ' || qids::text;
end $$;

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f2';
do $$
declare yox int := 0;
begin
  begin perform public.rpc_mesq_assign('cccc0000-0000-0000-0000-0000000000f1', 'eeee0000-0000-0000-0000-0000000000f1', null, null);
  exception when insufficient_privilege then yox := yox + 1; end;
  begin perform public.rpc_mesq_list('cccc0000-0000-0000-0000-0000000000f1');
  exception when insufficient_privilege then yox := yox + 1; end;
  begin perform public.rpc_mesq_report(current_setting('smoke.m1')::uuid);
  exception when insufficient_privilege then yox := yox + 1; end;
  begin perform public.rpc_mesq_del(current_setting('smoke.m1')::uuid);
  exception when insufficient_privilege then yox := yox + 1; end;
  assert yox = 4, 'basqa muellim ' || (4 - yox) || ' emeliyyati edə bildi';
end $$;
reset role; reset request.jwt.claim.sub;
--  anon cedvelleri oxuya bilmir
set role anon;
do $$
declare ok boolean := false;
begin
  begin perform 1 from public.mesq_assignments; exception when insufficient_privilege then ok := true; end;
  assert ok, 'anon mesq_assignments oxudu';
  ok := false;
  begin perform 1 from public.mesq_answers; exception when insufficient_privilege then ok := true; end;
  assert ok, 'anon mesq_answers oxudu';
end $$;
reset role;
\echo 'OK  2 · muellim: dersler sinfe gore, sira asandan cetine, qrupa / tek sagirde; yad muellim ve anon girmir'

-- =====================================================================
--  3. Sagird: sira, duz variant getmir, yenileme, sablon, ikinci cavab
-- =====================================================================
do $$
declare tok text; tok2 text; v jsonb; r jsonb; q uuid; m uuid := current_setting('smoke.m1')::uuid;
        a int; b int; yox boolean := false; i int; lst jsonb;
begin
  tok := public.rpc_student_login('MSAYSU01')->>'token';
  tok2 := public.rpc_student_login('MSKENAN1')->>'token';
  set local role anon;
  lst := public.rpc_student_mesq_list(tok);
  assert jsonb_array_length(lst) = 1, 'Aysu yalniz qrup mesqini gormeli: ' || jsonb_array_length(lst);
  assert jsonb_array_length(public.rpc_student_mesq_list(tok2)) = 2, 'Kenan qrup + sexsi gormeli';
  begin
    perform public.rpc_student_mesq_next(tok, current_setting('smoke.m2')::uuid);
  exception when insufficient_privilege then yox := true;
  end;
  assert yox, 'Aysu Kenanin sexsi mesqini acdi';

  v := public.rpc_student_mesq_next(tok, m);
  assert (v->>'n')::int = 6 and (v->>'pos')::int = 1 and not (v->>'done')::boolean, 'ilk sual: ' || left(v::text, 120);
  assert v->'question'->>'id' = 'ffff0000-0000-0000-0000-000000000002', 'ilk sual asan 1 olmali';
  assert v::text not like '%is_correct%' and v::text not like '%"correct": true%', 'duz variant sagirde getdi';
  --  yenileme: eyni sual
  assert public.rpc_student_mesq_next(tok, m)->'question'->>'id' = v->'question'->>'id', 'yenilemede sual deyisdi';

  --  1: duz
  r := public.rpc_student_mesq_answer(tok, m, (v->'question'->>'id')::uuid, pg_temp.duz((v->'question'->>'id')::uuid), null);
  assert (r->>'correct')::boolean and r->>'explanation' = 'izah a1', 'duz cavab: ' || r::text;
  --  ikinci defe redd
  yox := false;
  begin
    perform public.rpc_student_mesq_answer(tok, m, (v->'question'->>'id')::uuid, pg_temp.duz((v->'question'->>'id')::uuid), null);
  exception when others then yox := true;
  end;
  assert yox, 'eyni suala ikinci cavab qebul olundu';
  --  basqa (gosterilmemis) suala cavab redd
  yox := false;
  begin
    perform public.rpc_student_mesq_answer(tok, m, 'ffff0000-0000-0000-0000-000000000006', pg_temp.duz('ffff0000-0000-0000-0000-000000000006'), null);
  exception when others then yox := true;
  end;
  assert yox, 'gosterilmemis suala cavab qebul olundu';

  --  2: sehv -> izah
  v := public.rpc_student_mesq_next(tok, m);
  assert (v->>'pos')::int = 2 and v->'question'->>'id' = 'ffff0000-0000-0000-0000-000000000001', '2-ci sual asan 2';
  r := public.rpc_student_mesq_answer(tok, m, 'ffff0000-0000-0000-0000-000000000001', pg_temp.sehv('ffff0000-0000-0000-0000-000000000001'), null);
  assert not (r->>'correct')::boolean and r->>'explanation' = 'izah a2', 'sehv cavab: ' || r::text;

  --  3: sablon - reqem yenilemede deyismir, duz variant reqemle yoxlanir
  v := public.rpc_student_mesq_next(tok, m);
  assert v->'question'->>'id' = 'ffff0000-0000-0000-0000-000000000004', '3-cu sual sablon';
  assert v->'question'->>'body' !~ '[{}]', 'sablon render olunmayib: ' || (v->'question'->>'body');
  a := substring(v->'question'->>'body' from 'MESQSIZMA (\d+) \+')::int;
  b := substring(v->'question'->>'body' from '\+ (\d+) =')::int;
  assert a between 100 and 999 and b between 100 and 999, 'reqemler: ' || (v->'question'->>'body');
  assert public.rpc_student_mesq_next(tok, m)->'question'->>'body' = v->'question'->>'body', 'yenilemede reqem deyisdi';
  assert exists (select 1 from jsonb_array_elements(v->'question'->'options') o where o->>'body' = (a + b)::text), 'duz reqem variantlarda yoxdur';
  r := public.rpc_student_mesq_answer(tok, m, 'ffff0000-0000-0000-0000-000000000004', pg_temp.duz('ffff0000-0000-0000-0000-000000000004'), null);
  assert (r->>'correct')::boolean and r->>'explanation' = a || ' + ' || b || ' = ' || (a + b), 'sablon izahi: ' || r::text;

  --  qalan 3: ikisi duz, biri (cetin 2) sehv -> bitir
  for i in 1..3 loop
    v := public.rpc_student_mesq_next(tok, m);
    q := (v->'question'->>'id')::uuid;
    r := public.rpc_student_mesq_answer(tok, m, q,
           case when q = 'ffff0000-0000-0000-0000-000000000006' then pg_temp.sehv(q) else pg_temp.duz(q) end, null);
  end loop;
  assert (r->>'done')::boolean and (r->>'answered')::int = 6 and (r->>'ok')::int = 4, 'bitme: ' || r::text;
  v := public.rpc_student_mesq_next(tok, m);
  assert (v->>'done')::boolean and v->'question' = 'null'::jsonb, 'bitmis mesqde sual gelmemeli';

  --  Kenan: 2 suala cavab verir (asan 1 sehv, asan 2 duz)
  v := public.rpc_student_mesq_next(tok2, m);
  perform public.rpc_student_mesq_answer(tok2, m, 'ffff0000-0000-0000-0000-000000000002', pg_temp.sehv('ffff0000-0000-0000-0000-000000000002'), null);
  v := public.rpc_student_mesq_next(tok2, m);
  perform public.rpc_student_mesq_answer(tok2, m, 'ffff0000-0000-0000-0000-000000000001', pg_temp.duz('ffff0000-0000-0000-0000-000000000001'), null);
  reset role;
end $$;
\echo 'OK  3 · sagird: sira, duz variant getmir, yenileme eyni sual / reqem, ikinci cavab redd, sexsi mesq qorunur'

-- =====================================================================
--  4. Hesabat, valideyn, attempts toxunulmur
-- =====================================================================
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$
declare v jsonb; s jsonb;
begin
  v := public.rpc_mesq_report(current_setting('smoke.m1')::uuid);
  s := v->'summary';
  assert (s->>'n')::int = 6 and (s->>'targets')::int = 2 and (s->>'started')::int = 2 and (s->>'finished')::int = 1,
         'xulase: ' || s::text;
  assert (s->>'pct')::int = 63, 'duz % (5/8): ' || (s->>'pct');
  assert v->'students'->0->>'name' = 'Aysu Mesq' and (v->'students'->0->>'answered')::int = 6, 'sagird setri: ' || left((v->'students')::text, 160);
  assert jsonb_array_length(v->'hard') = 3, 'sehv olunan sual sayi: ' || (v->'hard')::text;
  assert (v->'hard'->0->>'no')::int = 1 and v->'hard'->0->>'body' = 'MESQSIZMA asan 1' and (v->'hard'->0->>'wrong')::int = 1, 'en cox sehv: ' || (v->'hard')::text;
  v := public.rpc_mesq_list('cccc0000-0000-0000-0000-0000000000f1');
  assert (select (x->>'finished')::int from jsonb_array_elements(v) x where x->>'id' = current_setting('smoke.m1')) = 1, 'siyahida bitiren 1';
end $$;
reset role; reset request.jwt.claim.sub;
do $$
declare tok text; v jsonb;
begin
  tok := public.rpc_parent_login('VMSAYSU1')->>'token';
  set local role anon;
  v := public.rpc_parent_mesq(tok);
  reset role;
  assert jsonb_array_length(v) = 1 and (v->0->>'answered')::int = 6 and (v->0->>'correct')::int = 4
         and v->0->>'lesson' = 'Toplama dersi', 'valideyn: ' || v::text;
  assert not exists (select 1 from public.attempts), 'mesq attempts-e yazdi';
  assert not exists (select 1 from public.mistakes where question_id in (select id from public.questions where ext_key like 'smkmesq-%')),
         'mesq sehv defterine dusdu';
end $$;
--  silme: cavablar da gedir
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000f1';
do $$ begin perform public.rpc_mesq_del(current_setting('smoke.m1')::uuid); end $$;
reset role; reset request.jwt.claim.sub;
do $$ begin
  assert not exists (select 1 from public.mesq_answers where assignment_id = current_setting('smoke.m1')::uuid), 'cavablar qaldi';
end $$;
\echo 'OK  4 · hesabat (baslayan / bitiren / duz % / en cox sehv), valideyn setri, attempts ve sehv defteri toxunulmur, silinir'

delete from public.mesq_assignments;
delete from public.test_questions tq using public.tests t where t.id = tq.test_id and t.owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.questions where ext_key like 'smkmesq-%';
delete from public.topics where slug like 'smk-mesq-%';
\echo 'MESQ: HAMISI KECDI'
