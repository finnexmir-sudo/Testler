-- =====================================================================
--  smoke_bank_rpc.sql : sual yazmaq / redakte / suzgecli axtaris
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.attempt_answers; delete from public.attempts;
delete from public.assignments;     delete from public.student_sessions;
delete from public.test_questions where test_id in
  (select id from public.tests where owner_type = 'educator');
delete from public.question_options o using public.questions q
 where o.question_id = q.id and q.owner_type = 'educator';
delete from public.questions where owner_type = 'educator';
delete from public.tests where owner_type = 'educator';
delete from public.students; delete from public.classes;
delete from public.subscriptions; delete from public.account_members;
delete from public.accounts; delete from public.user_roles;
delete from public.profiles; delete from auth.users;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000000c1','a@c.az'),
  ('22220000-0000-0000-0000-0000000000c2','b@c.az');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-0000000000c1','tutor','A','11110000-0000-0000-0000-0000000000c1'),
  ('aaaa0000-0000-0000-0000-0000000000c2','tutor','B','22220000-0000-0000-0000-0000000000c2');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000000c1','11110000-0000-0000-0000-0000000000c1',true),
  ('aaaa0000-0000-0000-0000-0000000000c2','22220000-0000-0000-0000-0000000000c2',true);

\echo '--- hazirliq tamam'

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';

-- =====================================================================
--  1. Sual yazilir, variantlari ile birlikde
-- =====================================================================
do $$
declare v jsonb; q jsonb;
begin
  v := public.rpc_bank_save_question(
    null, 'riyaziyyat', '7 x 6 nece eder?',
    '[{"body":"42","correct":true},{"body":"36"},{"body":"48"}]'::jsonb,
    'single', '3', null, 'Qirx iki.', 2, 1, 9, array['vurma']);
  assert (v->>'created')::boolean, 'yeni sual kimi yaranmadi';

  q := public.rpc_bank_question((v->>'id')::uuid);
  assert q->>'body' = '7 x 6 nece eder?', 'metn sehv';
  assert jsonb_array_length(q->'options') = 3, 'variant sayi sehv';
  assert (q->'options'->0->>'correct')::boolean, 'duzgun cavab itdi';
  assert q->>'subject_name' is not null, 'fenn adi yoxdur';
  assert q->>'level' = '3', 'sinif yazilmadi';
  assert (q->>'difficulty')::int = 2, 'cetinlik sehv';
  assert (q->>'quarter')::int = 1 and (q->>'month')::int = 9, 'dovr sehv';
  assert q->'tags' ? 'vurma', 'etiket itdi';
end $$;
\echo 'OK  1 · sual variantlari ile birlikde yazilir'

-- =====================================================================
--  2. Yararsiz sual QEBUL EDILMIR
-- =====================================================================
do $$
declare n int := 0;
begin
  begin  -- bos metn
    perform public.rpc_bank_save_question(null,'riyaziyyat','   ',
      '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
  exception when others then n := n + 1; end;
  begin  -- tek variant
    perform public.rpc_bank_save_question(null,'riyaziyyat','x',
      '[{"body":"1","correct":true}]'::jsonb);
  exception when others then n := n + 1; end;
  begin  -- duzgun cavab yoxdur
    perform public.rpc_bank_save_question(null,'riyaziyyat','x',
      '[{"body":"1"},{"body":"2"}]'::jsonb);
  exception when others then n := n + 1; end;
  begin  -- iki duzgun cavab, amma tip 'single'
    perform public.rpc_bank_save_question(null,'riyaziyyat','x',
      '[{"body":"1","correct":true},{"body":"2","correct":true}]'::jsonb);
  exception when others then n := n + 1; end;
  begin  -- bos variant
    perform public.rpc_bank_save_question(null,'riyaziyyat','x',
      '[{"body":"1","correct":true},{"body":"  "}]'::jsonb);
  exception when others then n := n + 1; end;
  begin  -- olmayan fenn
    perform public.rpc_bank_save_question(null,'yoxdur','x',
      '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
  exception when others then n := n + 1; end;
  begin  -- cetinlik 5
    perform public.rpc_bank_save_question(null,'riyaziyyat','x',
      '[{"body":"1","correct":true},{"body":"2"}]'::jsonb,'single',null,null,'',5);
  exception when others then n := n + 1; end;
  assert n = 7, format('yalniz %s yararsiz sual redd edildi, 7 olmali idi', n);
  assert (select count(*) from public.questions where owner_type='educator') = 1,
         'yararsiz sual bazaya dusdu';
end $$;
\echo 'OK  2 · yararsiz sual serverde redd edilir'

-- =====================================================================
--  3. Coxsecimli ve metn sualı
-- =====================================================================
do $$
declare v jsonb; q jsonb;
begin
  v := public.rpc_bank_save_question(null,'riyaziyyat','Hansilar cutdur?',
    '[{"body":"2","correct":true},{"body":"3"},{"body":"4","correct":true}]'::jsonb,
    'multi','3');
  q := public.rpc_bank_question((v->>'id')::uuid);
  assert q->>'kind' = 'multi', 'tip sehv';
  assert (select count(*) from jsonb_array_elements(q->'options') x
           where (x->>'correct')::boolean) = 2, 'iki duzgun cavab saxlanmadi';

  v := public.rpc_bank_save_question(null,'riyaziyyat','5 x 5 = ?',
    '[{"body":"25"}]'::jsonb, 'text','3');
  q := public.rpc_bank_question((v->>'id')::uuid);
  assert q->>'kind' = 'text', 'metn tipi sehv';
  assert (q->'options'->0->>'correct')::boolean,
         'metn sualinda cavab duzgun kimi yazilmadi';
end $$;
\echo 'OK  3 · coxsecimli ve metn sualı duzgun yazilir'

-- =====================================================================
--  4. Redakte: kohne variantlar EVEZ olunur, coxalmir
-- =====================================================================
do $$
declare qid uuid; q jsonb; v jsonb;
begin
  select id into qid from public.questions
   where body = '7 x 6 nece eder?';
  v := public.rpc_bank_save_question(qid,'riyaziyyat','7 x 6 = ?',
    '[{"body":"42","correct":true},{"body":"40"}]'::jsonb,'single','3',
    null,'Yeni izah.',3,2,10,array['vurma','cetin']);
  assert not (v->>'created')::boolean, 'redakte yeni sual yaratdi';

  q := public.rpc_bank_question(qid);
  assert q->>'body' = '7 x 6 = ?', 'metn yenilenmedi';
  assert jsonb_array_length(q->'options') = 2,
         format('variant sayi %s - kohneler qalib', jsonb_array_length(q->'options'));
  assert (q->>'difficulty')::int = 3, 'cetinlik yenilenmedi';
  assert q->>'explanation' = 'Yeni izah.', 'izah yenilenmedi';
  assert q->'tags' ? 'cetin', 'etiket yenilenmedi';
end $$;
\echo 'OK  4 · redakte kohne variantlari evez edir'

-- =====================================================================
--  5. Ozge muellimin sualina EL VURULMUR
--  DIQQET: id-ni ROL DEYISMEDEN EVVEL gotururuk - eks halda RLS onu
--  onsuz da gizledir, qid null qalir ve yoxlama yalan yere kecir.
-- =====================================================================
reset role;
drop table if exists public.q_fix;
create table public.q_fix (k text primary key, v uuid);
insert into public.q_fix select 'a1', id from public.questions where body = '7 x 6 = ?';
insert into public.q_fix select 'plat', id from public.questions
 where owner_type = 'platform' limit 1;
grant select on public.q_fix to authenticated;

set role authenticated;
set request.jwt.claim.sub = '22220000-0000-0000-0000-0000000000c2';
do $$
declare qid uuid; n int := 0;
begin
  select f.v into qid from public.q_fix f where f.k = 'a1';
  assert qid is not null, 'fixture bosdur';
  begin perform public.rpc_bank_question(qid);
  exception when insufficient_privilege then n := n + 1; end;
  begin perform public.rpc_bank_save_question(qid,'riyaziyyat','oglurluq',
    '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
  exception when insufficient_privilege then n := n + 1; end;
  begin perform public.rpc_bank_delete_question(qid);
  exception when insufficient_privilege then n := n + 1; end;
  assert n = 3, format('yalniz %s emeliyyat bloklandi, 3 olmali idi', n);
end $$;
\echo 'OK  5 · ozge sual oxunmur, deyisilmir, silinmir'

-- =====================================================================
--  6. Suzgec: hovuz, fenn, cetinlik, dovr, etiket, axtaris
-- =====================================================================
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare v jsonb;
begin
  v := public.rpc_bank_list('{"pool":"mine"}'::jsonb);
  assert (v->>'total')::int = 3, format('oz sualim: %s', v->>'total');

  v := public.rpc_bank_list('{"pool":"platform"}'::jsonb);
  assert (v->>'total')::int >= 20, format('platforma hovuzu: %s', v->>'total');

  v := public.rpc_bank_list('{"pool":"mine","difficulty":[3]}'::jsonb);
  assert (v->>'total')::int = 1, format('cetinlik suzgeci: %s', v->>'total');

  v := public.rpc_bank_list('{"pool":"mine","quarter":2}'::jsonb);
  assert (v->>'total')::int = 1, format('rub suzgeci: %s', v->>'total');

  v := public.rpc_bank_list('{"pool":"mine","tags":["vurma","cetin"]}'::jsonb);
  assert (v->>'total')::int = 1, format('etiket suzgeci: %s', v->>'total');

  v := public.rpc_bank_list('{"pool":"mine","tags":["vurma","yoxdur"]}'::jsonb);
  assert (v->>'total')::int = 0, 'etiketlerin HAMISI teleb olunmur';

  v := public.rpc_bank_list('{"pool":"mine","q":"cutdur"}'::jsonb);
  assert (v->>'total')::int = 1, format('metn axtarisi: %s', v->>'total');

  v := public.rpc_bank_list('{"pool":"mine","level":"4"}'::jsonb);
  assert (v->>'total')::int = 0, 'sinif suzgeci islemir';
end $$;
\echo 'OK  6 · suzgecler duzgun isleyir'

-- =====================================================================
--  7. Sehifeleme ve sayğac
-- =====================================================================
do $$
declare v jsonb; c jsonb;
begin
  v := public.rpc_bank_list('{"pool":"mine"}'::jsonb, 2, 0);
  assert jsonb_array_length(v->'items') = 2, 'limit islemir';
  assert (v->>'total')::int = 3, 'total sehifelemeden asili olmamalidir';

  v := public.rpc_bank_list('{"pool":"mine"}'::jsonb, 2, 2);
  assert jsonb_array_length(v->'items') = 1, 'offset islemir';

  c := public.rpc_bank_count('{"pool":"mine"}'::jsonb);
  assert (c->>'total')::int = 3, 'sayğac sehvdir';
end $$;
\echo 'OK  7 · sehifeleme ve sayğac'

-- =====================================================================
--  8. Cavab acari siyahida GORUNMUR
-- =====================================================================
do $$
declare v jsonb; t text;
begin
  v := public.rpc_bank_list('{"pool":"platform"}'::jsonb, 50, 0);
  t := v::text;
  assert t not like '%is_correct%', 'siyahida is_correct var';
  assert t not like '%"correct"%', 'siyahida duzgun cavab nisani var';
  assert t not like '%"options"%', 'siyahi variantlari da gonderir';
end $$;
\echo 'OK  8 · siyahi cavab acarini sizdirmir'

-- =====================================================================
--  9. Platformanin sualı OXUNUR, amma DEYISILMIR
-- =====================================================================
do $$
declare qid uuid; n int := 0;
begin
  select f.v into qid from public.q_fix f where f.k = 'plat';
  begin perform public.rpc_bank_question(qid);
  exception when insufficient_privilege then n := n + 1; end;
  begin perform public.rpc_bank_save_question(qid,'riyaziyyat','deyisdirdim',
    '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
  exception when insufficient_privilege then n := n + 1; end;
  assert n = 2, format('platforma sualı qorunmadi (%s/2)', n);
  -- amma suzgecde gorunur (generator hovuzu)
  assert (public.rpc_bank_list('{"pool":"platform"}'::jsonb)->>'total')::int > 0,
         'platforma hovuzu bagli - generator islemeyecek';
end $$;
\echo 'OK  9 · platforma sualı oxunur, deyisilmir'

-- =====================================================================
-- 10. Silmek: islenmemis SILINIR, islenmis ARXIVLENIR
-- =====================================================================
do $$
declare qid uuid; v jsonb; tid uuid;
begin
  select id into qid from public.questions where body = '5 x 5 = ?';
  v := public.rpc_bank_delete_question(qid);
  assert (v->>'ok')::boolean and not (v->>'archived')::boolean, 'silinmedi';
  assert not exists (select 1 from public.questions where id = qid), 'sual qalib';

  -- indi bir sualı teste baglayiriq
  select id into qid from public.questions where body = '7 x 6 = ?';
  insert into public.tests (id, owner_type, owner_id, program_id, subject_id, title, status)
  select 'dddd0000-0000-0000-0000-0000000000c1','educator',
         '11110000-0000-0000-0000-0000000000c1', p.id, s.id, 'T','published'
    from public.programs p, public.subjects s
   where p.slug='ibtidai' and s.slug='riyaziyyat' returning id into tid;
  insert into public.test_questions (test_id, question_id, ord) values (tid, qid, 1);

  v := public.rpc_bank_delete_question(qid);
  assert (v->>'archived')::boolean, 'islenmis sual arxivlenmedi';
  assert (select status from public.questions where id = qid) = 'archived',
         'status arxiv deyil';
  -- arxiv suzgecde gorunmur
  assert (public.rpc_bank_list('{"pool":"mine"}'::jsonb)->>'total')::int = 1,
         'arxivlenmis sual hele de siyahida';
end $$;
\echo 'OK 10 · islenmemis silinir, islenmis arxivlenir'

-- =====================================================================
-- 11. Paket heddi bazada tetbiq olunur
-- =====================================================================
reset role; reset request.jwt.claim.sub;
create or replace function app.free_question_limit() returns int
language sql immutable as $$ select 3 $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000000c1';
do $$
declare i int; ok boolean := false; n int;
begin
  for i in 1..2 loop
    perform public.rpc_bank_save_question(null,'riyaziyyat','hedd '||i,
      '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
  end loop;
  begin
    perform public.rpc_bank_save_question(null,'riyaziyyat','asiri',
      '[{"body":"1","correct":true},{"body":"2"}]'::jsonb);
    assert false, 'hedd asildi';
  exception when insufficient_privilege then ok := true; end;
  assert ok, 'limit xetasi gelmedi';
  select count(*) into n from public.questions
   where owner_type='educator' and status <> 'archived';
  assert n = 3, format('limitden sonra %s sual var', n);
end $$;
\echo 'OK 11 · paketin sual limiti bazada tetbiq olunur'

-- =====================================================================
-- 12. Suzgec siyahilari (facets)
-- =====================================================================
do $$
declare v jsonb;
begin
  v := public.rpc_bank_facets('riyaziyyat', '3');
  assert jsonb_array_length(v->'subjects') >= 10, 'fenn siyahisi bos';
  --  test bazasinda yalniz 3-4-cu sinif banklari var - siyahida da
  --  yalniz onlar olmalidir (suali olmayan sinif gorunmur)
  assert jsonb_array_length(v->'levels') >= 2, 'sinif siyahisi bos';
  assert not exists (select 1 from jsonb_array_elements(v->'levels') e
                      where e->>'code' = '11'), 'sualsiz sinif siyahidadir';
  assert jsonb_array_length(v->'topics') >= 1, 'movzu siyahisi bos';
  assert (v->'usage'->>'limit')::int = 3, 'hedd gorunmur';
  assert (v->'usage'->>'used')::int = 3, 'istifade gorunmur';

  --  hovuz suzgeci: 'mine' yalniz OZ suallarinin fennini sayir -
  --  muellimin butun suallari riyaziyyatdadir
  v := public.rpc_bank_facets(null, null, null, 'mine');
  assert (select count(*) from jsonb_array_elements(v->'subjects') e
           where (e->>'n')::int > 0) = 1,
         'mine hovuzunda yalniz oz fenni sayilmalidir';
  --  'platform' hovuzunda oz suallari sayilmir, banklar sayilir
  v := public.rpc_bank_facets(null, null, null, 'platform');
  assert exists (select 1 from jsonb_array_elements(v->'subjects') e
                  where e->>'slug' = 'riyaziyyat'
                    and (e->>'n')::int >= 100),
         'platform hovuzunda bank sayilmir';
  --  p_pool verilende movzu siyahisina yalniz suali olanlar dusur
  v := public.rpc_bank_facets('riyaziyyat', '3', null, 'platform');
  assert jsonb_array_length(v->'topics') >= 1, 'platform movzulari bos';
  assert (select bool_and(exists (
            select 1 from public.questions q
             where q.topic_id = (e->>'id')::uuid
               and q.owner_type = 'platform' and q.status = 'published'))
            from jsonb_array_elements(v->'topics') e),
         'sualsiz movzu siyahiya dusdu';
end $$;
\echo 'OK 12 · suzgec siyahilari, hovuz suzgeci, istifade gostericisi'

reset role; reset request.jwt.claim.sub;
create or replace function app.free_question_limit() returns int
language sql immutable as $$ select 150 $$;
drop table if exists public.q_fix;

\echo ''
\echo '=============================='
\echo ' BANK RPC: HAMISI KECDI'
\echo '=============================='
