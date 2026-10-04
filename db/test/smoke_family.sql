-- =====================================================================
--  smoke_family.sql : 913 - ailə yolu (valideyn hesabi, usaq elave et, Ailem, valideyn ekrani)
--  Hamisi tranzaksiyada, sonda GERI alinir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
begin;

insert into auth.users (id, email) values
  ('11110000-0000-0000-0000-0000000008a1', 'fam1@t.az'),      -- valideyn 1
  ('11110000-0000-0000-0000-0000000008a2', 'fam2@t.az'),      -- valideyn 2
  ('11110000-0000-0000-0000-0000000008a3', 'teacher8@t.az');  -- muellim
insert into public.accounts (id, type, name, owner_id, is_demo) values
  ('aaaa0000-0000-0000-0000-0000000008a3', 'tutor', 'Muellim 8', '11110000-0000-0000-0000-0000000008a3', false);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000008a3', '11110000-0000-0000-0000-0000000008a3', true);

-- ------------------------------------------------ 1 · bayraq sonukdur
update public.app_state set val = '{"on": false, "emails": []}' where key = 'family';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$ begin
  begin perform public.rpc_family_start('Aygun H'); assert false, 'bayraq sonuk: hesab acilmamali';
  exception when others then if sqlerrm like '%Bu xidm%' then null; else raise; end if; end;
end $$;
reset role;
set role anon;
do $$ begin
  assert (public.rpc_family_status()->>'on')::boolean = false, 'status: baglidir';
end $$;
reset role;

-- ------------------------------------------------ 2 · e-poct siyahisi (canli sinaq) ile hesab
update public.app_state set val = '{"on": false, "emails": ["FAM1@t.az"]}' where key = 'family';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$
declare r jsonb; r2 jsonb;
begin
  r := public.rpc_family_start('  Aygun   Huseynova ');
  assert (r->>'ok')::boolean and r->>'trial_end' is not null, 'hesab + sinaq: ' || r::text;
  assert (select count(*) from public.accounts where owner_id = '11110000-0000-0000-0000-0000000008a1') = 1, 'bir hesab';
  assert (select a.name from public.accounts a where a.owner_id = '11110000-0000-0000-0000-0000000008a1') = 'Aygun Huseynova', 'ad temizlenib';
  r2 := public.rpc_family_start('Basqa ad');
  assert (r2->>'existing')::boolean, 'ikinci cagiris: movcud hesab';
  assert (select count(*) from public.accounts where owner_id = '11110000-0000-0000-0000-0000000008a1') = 1, 'ikinci hesab yaranmayib';
  assert app.has_active_subscription((r->>'account_id')::uuid), 'sinaq abunesi aktivdir';
  assert (select s.current_period_end - now() from public.subscriptions s where s.account_id = (r->>'account_id')::uuid)
           between interval '29 days' and interval '31 days', '30 gun';
end $$;
--  basqa e-poct siyahida deyil -> icaze yoxdur
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a2';
do $$ begin
  begin perform public.rpc_family_start('Basqa'); assert false, 'siyahida olmayan e-poct';
  exception when others then if sqlerrm like '%Bu xidm%' then null; else raise; end if; end;
end $$;
--  muellim e-poctu ile ailə hesabi acilmir
reset role;
update public.app_state set val = '{"on": true, "emails": []}' where key = 'family';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a3';
do $$ begin
  begin perform public.rpc_family_start('Muellim'); assert false, 'muellim ailə hesabi aça bilməz';
  exception when others then if sqlerrm like '%hesabına bağlıdır%' then null; else raise; end if; end;
end $$;
reset role;
set role anon;
do $$ begin assert (public.rpc_family_status()->>'on')::boolean, 'status: aciqdir'; end $$;
reset role;

-- ------------------------------------------------ 3 · fennler + usaq elave et
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$
declare s jsonb; r jsonb; v_sid uuid; v_slugs text[]; ch jsonb;
begin
  s := public.rpc_family_subjects('7');
  assert jsonb_array_length(s) >= 2, 'sinif 7: fennler var: ' || s::text;
  assert jsonb_array_length(public.rpc_family_subjects('99')) = 0, 'yoxdur sinif: bos';
  select array_agg(x->>'slug') into v_slugs from (select * from jsonb_array_elements(s) limit 2) z(x);

  begin perform public.rpc_family_add_child('Huseyn', '7', v_slugs, 10, false); assert false, 'razilqsiz';
  exception when others then if sqlerrm like '%razılıq%' then null; else raise; end if; end;
  begin perform public.rpc_family_add_child('H', '7', v_slugs, 10, true); assert false, 'qisa ad';
  exception when others then if sqlerrm like '%adını%' then null; else raise; end if; end;
  begin perform public.rpc_family_add_child('Huseyn', 'x', v_slugs, 10, true); assert false, 'yanlis sinif';
  exception when others then if sqlerrm like '%Sinif%' then null; else raise; end if; end;
  begin perform public.rpc_family_add_child('Huseyn', '7', array['yoxdur-fenn'], 10, true); assert false, 'fennsiz';
  exception when others then if sqlerrm like '%fənn%' then null; else raise; end if; end;

  r := public.rpc_family_add_child('Huseyn Aliyev', '7', v_slugs, 15, true);
  assert (r->>'ok')::boolean and length(r->>'login_code') = 8, 'usaq elave olundu: ' || r::text;
  v_sid := (r->>'student_id')::uuid;
  assert jsonb_array_length(r->'diagnostics') = array_length(v_slugs, 1), 'diaqnostika her fenn ucun';
  assert exists (select 1 from jsonb_array_elements(r->'diagnostics') d where (d->>'ok')::boolean), 'en azi bir diaqnostika yaranib: ' || (r->'diagnostics')::text;
  ch := public.rpc_family_children();
  assert (ch->>'has_account')::boolean and jsonb_array_length(ch->'kids') = 1, 'Ailem: bir usaq';
  assert (ch->'kids'->0->>'login_code') = r->>'login_code', 'kod gorunur';
  assert (ch->'kids'->0->>'diag_total')::int >= 1 and (ch->'kids'->0->>'diag_done')::int = 0, 'diaqnostika sayi';
  assert (ch->'account'->>'active')::boolean and ch->'account'->>'trial_end' is not null, 'sinaq melumati';
  assert (ch->'kids'->0->>'sinif') = '7' and (ch->'kids'->0->>'minutes')::int = 15, 'sinif, vaxt';
  assert jsonb_array_length(ch->'kids'->0->'subject_names') = 2, 'fenn adlari: ' || (ch->'kids'->0->'subject_names')::text;
  perform set_config('smoke.sid', v_sid::text, false);
  perform set_config('smoke.scode', r->>'login_code', false);
end $$;

reset role;
do $$
declare v_sid uuid := current_setting('smoke.sid')::uuid;
begin
  assert (select count(*) from public.consents where student_id = v_sid and kind = 'parental' and revoked_at is null) = 1, 'razilq yazilib';
  assert (select fk.minutes from public.family_kids fk where fk.student_id = v_sid) = 15, 'gunluk vaxt';
  assert (select c.kind from public.classes c join public.students st on st.class_id = c.id where st.id = v_sid) = 'self_study', 'gizli self_study qrup';
  assert (select l.code from public.classes c join public.levels l on l.id = c.level_id join public.students st on st.class_id = c.id where st.id = v_sid) = '7', 'sinif 7';
  assert (select parent_code is not null from public.students where id = v_sid), 'valideyn kodu yaranib';
  assert (select account_id from public.students where id = v_sid) = app.family_account('11110000-0000-0000-0000-0000000008a1'), 'ailə hesabinin usagi';

end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';

-- ------------------------------------------------ 4 · valideyn ekrani movcud token ile + usagin girisi
do $$
declare o jsonb;
begin
  o := public.rpc_family_open(current_setting('smoke.sid')::uuid);
  assert (o->>'ok')::boolean and length(o->>'token') = 64, 'token verilir';
  perform set_config('smoke.ptok', o->>'token', false);
end $$;
reset role;
set role anon;
do $$
declare h jsonb; l jsonb;
begin
  h := public.rpc_parent_home(current_setting('smoke.ptok'));
  assert h is not null and h::text like '%Huseyn%', 'movcud valideyn ekrani ailə tokeni ile isleyir';
  l := public.rpc_student_login(current_setting('smoke.scode'));
  assert (l->>'ok')::boolean, 'usaq kodla girir: ' || l::text;
end $$;
reset role;

-- ------------------------------------------------ 4b · butun fennler: ilk 3-e yoxlama, qalani «Yoxlama ver» ile
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$
declare s jsonb; v_slugs text[]; r jsonb; ch jsonb; kid jsonb; v_sid uuid; v_none text; v_other text; n int;
begin
  s := public.rpc_family_subjects('7');
  select array_agg(x->>'slug') into v_slugs from jsonb_array_elements(s) x;
  n := array_length(v_slugs, 1);
  assert n >= 4, 'sinif 7: en azi 4 fenn lazimdir: ' || n;
  r := public.rpc_family_add_child('Aysu Aliyeva', '7', v_slugs, 30, true);
  v_sid := (r->>'student_id')::uuid;
  assert jsonb_array_length(r->'diagnostics') = 3 and (r->>'subjects_total')::int = n, 'ilk 3 yoxlama, cemi ' || n || ': ' || r::text;

  ch := public.rpc_family_children();
  select k into kid from jsonb_array_elements(ch->'kids') k where (k->>'id')::uuid = v_sid;
  assert (kid->>'minutes')::int = 30, '30 deq';
  assert jsonb_array_length(kid->'subject_diag') = n, 'her fenn ucun veziyyet';
  assert (select count(*) from jsonb_array_elements(kid->'subject_diag') x where x->>'state' = 'open') = 3, '3 «open»';
  assert (select count(*) from jsonb_array_elements(kid->'subject_diag') x where x->>'state' = 'none') = n - 3, 'qalani «none»';

  select x->>'slug' into v_none from jsonb_array_elements(kid->'subject_diag') x where x->>'state' = 'none' limit 1;
  r := public.rpc_family_diag(v_sid, v_none);
  assert (r->>'ok')::boolean, 'yoxlama verildi: ' || r::text;
  ch := public.rpc_family_children();
  select k into kid from jsonb_array_elements(ch->'kids') k where (k->>'id')::uuid = v_sid;
  assert (select count(*) from jsonb_array_elements(kid->'subject_diag') x where x->>'state' = 'open') = 4, 'indi 4 «open»';
  r := public.rpc_family_diag(v_sid, v_none);
  assert (r->>'existing')::boolean, 'ikinci cagiris dublikat yaratmir';

  select sl.slug into v_other from public.subjects sl where sl.slug <> all(v_slugs) limit 1;
  begin perform public.rpc_family_diag(v_sid, coalesce(v_other, 'yoxdur')); assert false, 'secilmeyen fenn';
  exception when others then if sqlerrm like '%seçilməyib%' then null; else raise; end if; end;
end $$;
reset role;

-- ------------------------------------------------ 4b · cari fesil (916)
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$
declare
  v_sid uuid := current_setting('smoke.sid')::uuid;
  v_subj text; r jsonb; ch jsonb; v_c2 uuid; v_c1 uuid; n1 int; n2 int;
begin
  select x->>'slug' into v_subj
    from jsonb_array_elements((select k->'subject_diag' from jsonb_array_elements(public.rpc_family_children()->'kids') k
                                where (k->>'id')::uuid = v_sid)) x
   where jsonb_array_length(public.rpc_family_chapters(v_sid, x->>'slug')->'chapters') >= 2 limit 1;
  assert v_subj is not null, '916: en azi 2 fesilli fenn lazimdir';
  r := public.rpc_family_chapters(v_sid, v_subj);
  assert r->'current' = 'null'::jsonb or r->>'current' is null, 'evvelce cari fesil yoxdur: ' || r::text;
  v_c1 := (r->'chapters'->0->>'id')::uuid;
  v_c2 := (r->'chapters'->1->>'id')::uuid;
  r := public.rpc_family_set_current(v_sid, v_subj, v_c2);
  n2 := (r->>'done_topics')::int;
  assert n2 > 0, 'ikinci fesile qeder kecildi';
  assert (public.rpc_family_chapters(v_sid, v_subj)->>'current')::uuid = v_c2, 'cari = 2-ci fesil';
  r := public.rpc_family_set_current(v_sid, v_subj, v_c1);
  n1 := (r->>'done_topics')::int;
  assert n1 > 0 and n1 < n2, 'geri qayitmaq: ' || n1 || ' < ' || n2;
  assert (public.rpc_family_chapters(v_sid, v_subj)->>'current')::uuid = v_c1, 'cari = 1-ci fesil';
  begin perform public.rpc_family_set_current(v_sid, v_subj, gen_random_uuid()); assert false, 'yalan fesil';
  exception when others then if sqlerrm like '%tapılmadı%' then null; else raise; end if; end;
  begin perform public.rpc_family_set_current(v_sid, 'yoxdur', v_c1); assert false, 'yalan fenn';
  exception when others then if sqlerrm like '%seçilməyib%' then null; else raise; end if; end;
  perform set_config('smoke.subj', v_subj, false);
end $$;
reset role;
do $$ begin
  assert exists (select 1 from app.daily_topics(current_setting('smoke.sid')::uuid) where src = 'plan'), 'gundelik movzular planin kecilenlerinden gelir';
end $$;

-- ------------------------------------------------ 5 · basqa ailə baxa bilmir
update public.app_state set val = '{"on": true, "emails": []}' where key = 'family';
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a2';
do $$
declare ch jsonb;
begin
  assert (public.rpc_family_start('Ikinci Valideyn')->>'ok')::boolean, 'ikinci valideyn hesab acir';
  ch := public.rpc_family_children();
  assert jsonb_array_length(ch->'kids') = 0, 'basqa ailənin usagi gorunmur';
  begin perform public.rpc_family_diag(current_setting('smoke.sid')::uuid, 'riyaziyyat'); assert false, 'basqa ailenin usagina yoxlama';
  exception when others then if sqlerrm like '%tapılmadı%' then null; else raise; end if; end;
  begin perform public.rpc_family_chapters(current_setting('smoke.sid')::uuid, current_setting('smoke.subj')); assert false, 'basqa usagin fesilleri';
  exception when others then if sqlerrm like '%tapılmadı%' then null; else raise; end if; end;
  begin perform public.rpc_family_open(current_setting('smoke.sid')::uuid); assert false, 'basqa usagin tokeni';
  exception when others then if sqlerrm like '%tapılmadı%' then null; else raise; end if; end;
end $$;
reset role;

-- ------------------------------------------------ 6 · limit: 6 usaq
update public.students set is_active = true where account_id = app.family_account('11110000-0000-0000-0000-0000000008a1');
insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code)
select st.account_id, st.class_id, st.created_by, 'Dummy ' || g, 'D' || g, 'DUMMYX0' || g
  from public.students st, generate_series(1, 5) g where st.id = current_setting('smoke.sid')::uuid;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$ begin
  begin perform public.rpc_family_add_child('Yeddinci', '5', array['riyaziyyat'], 10, true); assert false, '7-ci usaq';
  exception when others then if sqlerrm like '%ən çox 6%' or sqlerrm like '%çox 6%' then null; else raise; end if; end;
end $$;
reset role;

-- ------------------------------------------------ 7 · anon bu RPC-lere toxuna bilmir
set role anon;
do $$ begin
  begin perform public.rpc_family_children(); assert false, 'anon: children';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_family_add_child('X Y', '7', array['riyaziyyat'], 10, true); assert false, 'anon: add';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_family_open(gen_random_uuid()); assert false, 'anon: open';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_family_diag(gen_random_uuid(), 'riyaziyyat'); assert false, 'anon: diag';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- ------------------------------------------------ 8 · valideyn xulasesi (bu gun / hefte / diqqet)
do $$
declare
  v_sid uuid := current_setting('smoke.sid')::uuid;
  v_test uuid; v_att uuid; v_topic uuid;
begin
  select a.test_id into v_test from public.assignments a where a.student_id = v_sid limit 1;
  select q.topic_id into v_topic from public.questions q where q.topic_id is not null and q.status = 'published'
   group by q.topic_id having count(*) >= 5 limit 1;
  insert into public.attempts (student_id, test_id, class_id, status, finished_at)
  values (v_sid, v_test, (select class_id from public.students where id = v_sid), 'submitted', now()) returning id into v_att;
  insert into public.attempt_answers (attempt_id, question_id, topic_id, is_correct, answered_at)
  select v_att, q.id, v_topic, (row_number() over (order by q.id) = 1), now()
    from public.questions q where q.topic_id = v_topic and q.status = 'published' order by q.id limit 5;
  insert into public.daily_packs (student_id, day, items, answers)
  values (v_sid, (now() at time zone 'Asia/Baku')::date, '[{"q":"x"},{"q":"y"}]', '[{"ok":true},{"ok":false}]');
end $$;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$
declare s jsonb; k jsonb;
begin
  s := public.rpc_family_summary();
  select x into k from jsonb_array_elements(s) x where x->>'id' = current_setting('smoke.sid');
  assert k is not null, 'xulase usagi tapir';
  assert (k->>'today_q')::int = 7 and (k->>'today_ok')::int = 2, 'bu gun 7 sual, 2 duz: ' || k::text;
  assert jsonb_array_length(k->'week') = 7, 'hefte 7 gun';
  assert (k->'week'->>((k->>'today_i')::int))::int = 1, 'bu gun «calisib»';
  assert jsonb_array_length(k->'weak') = 1 and (k->'weak'->0->>'percent')::int = 20 and (k->'weak'->0->>'n')::int = 5 and (k->>'weak_total')::int = 1, 'zeif movzu: ' || (k->>'weak');
  assert jsonb_array_length(s) = 7, 'butun aktiv usaqlar xulasede: Huseyn + Aysu + 5 sinaq usagi, alindi ' || jsonb_array_length(s);
end $$;
reset role;

-- ------------------------------------------------ 9 · silme
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a2';
do $$
declare s jsonb;
begin
  s := public.rpc_family_summary();
  assert jsonb_array_length(s) = 0, 'basqa ailenin xulasesi bos';
  begin perform public.rpc_family_delete_child(current_setting('smoke.sid')::uuid); assert false, 'basqasinin usagini silmək';
  exception when others then if sqlerrm like '%tapılmadı%' then null; else raise; end if; end;
end $$;
reset role;
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$
begin
  perform public.rpc_family_delete_child(current_setting('smoke.sid')::uuid);
end $$;
reset role;
do $$
declare v_sid uuid := current_setting('smoke.sid')::uuid;
begin
  assert not exists (select 1 from public.students where id = v_sid), 'usaq silinib';
  assert not exists (select 1 from public.consents where student_id = v_sid), 'razilig silinib';
  assert not exists (select 1 from public.family_kids where student_id = v_sid), 'parametrler silinib';
  assert not exists (select 1 from public.attempts where student_id = v_sid), 'cehdler silinib';
  assert not exists (select 1 from public.daily_packs where student_id = v_sid), 'gundelik paket silinib';
  assert not exists (select 1 from public.parent_sessions where student_id = v_sid), 'valideyn sessiyalari silinib';
  assert not exists (select 1 from public.tests where gen_rule->>'student' = v_sid::text), 'diaqnostika testleri silinib';
  assert exists (select 1 from public.students where account_id = app.family_account('11110000-0000-0000-0000-0000000008a1') and display_name = 'Aysu'), 'ikinci usaq yerindedir';
end $$;
--  hesabi sil (ikinci valideyn: usaqsiz)
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a2';
do $$ begin perform public.rpc_family_delete_account(); end $$;
reset role;
do $$ begin
  assert not exists (select 1 from auth.users where id = '11110000-0000-0000-0000-0000000008a2'), 'istifadeci silinib';
  assert not exists (select 1 from public.accounts where owner_id = '11110000-0000-0000-0000-0000000008a2'), 'hesab silinib';
  assert not exists (select 1 from public.profiles where id = '11110000-0000-0000-0000-0000000008a2'), 'profil silinib';
end $$;
--  birinci valideyn: usaqlari ile birlikde
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a1';
do $$ begin perform public.rpc_family_delete_account(); end $$;
reset role;
do $$ begin
  assert not exists (select 1 from auth.users where id = '11110000-0000-0000-0000-0000000008a1'), 'valideyn 1 silinib';
  assert not exists (select 1 from public.students where created_by = '11110000-0000-0000-0000-0000000008a1'), 'butun usaqlar silinib';
  assert not exists (select 1 from public.classes where teacher_id = '11110000-0000-0000-0000-0000000008a1'), 'qruplar silinib';
  assert not exists (select 1 from public.consents c join public.students s on s.id = c.student_id where s.created_by = '11110000-0000-0000-0000-0000000008a1'), 'razilqlar silinib';
end $$;
--  muellim bu yolla hesabini sile bilmez
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000008a3';
do $$ begin
  begin perform public.rpc_family_delete_account(); assert false, 'muellim hesabi silinmemeli';
  exception when others then if sqlerrm like '%müəllim hesabı%' then null; else raise; end if; end;
end $$;
reset role;
set role anon;
do $$ begin
  begin perform public.rpc_family_summary(); assert false, 'anon: summary';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_family_delete_account(); assert false, 'anon: delete account';
  exception when insufficient_privilege then null; end;
  begin perform public.rpc_family_delete_child(gen_random_uuid()); assert false, 'anon: delete child';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

rollback;
\echo smoke_family: HAMISI KECDI
