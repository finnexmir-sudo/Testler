-- =====================================================================
--  136_numune_hesab.sql : numune (demo) hesab - "Muellim kimi bax"
--
--  Meqsed: muellim qeydiyyatsiz, 2 deqiqeye, real reqemlerle dolu
--  hesabi gorsun.  Uc giris:
--    muellim  - anonim giris (Supabase "anonymous sign-ins" ACIQ olmalidir)
--               + rpc_demo_start(): ziyaretcinin OZ nusxesi qurulur, 24
--               saatdan sonra rpc_demo_reset() silir.  Kimse kimin
--               nusxesine toxunmur, parol yoxdur.
--    sagird   - PAYLASILAN numune hesabin sagirdi: kod DEMO0001 (sabit)
--    valideyn - eyni sagirdin valideyn kodu VDEMO001 (sabit)
--  Paylasilan numune her gece (is axini, anon acar ile) rpc_demo_reset()
--  ile yeniden qurulur - ziyaretcilerin yazdigi cehdler silinir.
--
--  Qurucu app.demo_build(owner, account, fixed): iki qrup, 20 sagird, ders
--  plani (9 movzu kecilib), ev tapsiriqlari + isinmeler + rub sinagi +
--  diaqnostika, 45 gunluk cehd tarixcesi (zeif movzu: Kesrler), acıq
--  tapsiriq (4 nefer etmeyib), sehv defteri (trigger ile), movzu mesqi,
--  davamiyyet ve odenis defteri, bir "bize yaz", bir sual bildirisi.
--  Sabit toxum (setseed) - paylasilan numune her gun eyni gorunur.
--
--  Paylasilan numunenin sahibi auth.users-de sabit ID ile yaradilir
--  (numune@bil10.local) - hec kim onunla daxil olmur, yalniz sahibdir.
-- =====================================================================

alter table public.accounts add column if not exists is_demo boolean not null default false;

create table if not exists public.app_state (
  key        text primary key,
  val        jsonb,
  updated_at timestamptz not null default now()
);
alter table public.app_state enable row level security;
revoke all on public.app_state from public, anon, authenticated;

create or replace function app.demo_owner() returns uuid
language sql immutable as $$ select 'd0000000-0000-4000-8000-000000000001'::uuid $$;
create or replace function app.demo_account() returns uuid
language sql immutable as $$ select 'd0000000-0000-4000-8000-0000000000a1'::uuid $$;
revoke all on function app.demo_owner()   from public, anon, authenticated;
revoke all on function app.demo_account() from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Test: verilen movzulardan (platforma, derc olunmus) beraber sayda sual
-- ---------------------------------------------------------------------
create or replace function app.demo_test(p_owner uuid, p_subject uuid, p_level uuid, p_program uuid,
  p_topics uuid[], p_n int, p_title text, p_rule jsonb, p_diffs int[] default '{1,2,3}',
  p_per_topic int default null, p_diag boolean default false, p_created timestamptz default now())
returns uuid
language plpgsql as $$
declare v_test uuid;
begin
  insert into public.tests (owner_type, owner_id, program_id, subject_id, level_id, title, status,
                            gen_rule, max_attempts, is_free, is_diagnostic, created_at, updated_at)
  values ('educator', p_owner, p_program, p_subject, p_level, p_title, 'published',
          p_rule, 1, true, p_diag, p_created, p_created)
  returning id into v_test;
  insert into public.test_questions (test_id, question_id, ord)
  select v_test, z.id, row_number() over (order by z.rn, z.r)
    from (select q.id, random() as r,
                 row_number() over (partition by q.topic_id order by random()) as rn
            from public.questions q
           where q.owner_type = 'platform' and q.status = 'published'
             and q.subject_id = p_subject and q.level_id = p_level
             and q.topic_id = any(p_topics) and q.difficulty = any(p_diffs)) z
   where p_per_topic is null or z.rn <= p_per_topic
   order by z.rn, z.r
   limit p_n;
  return v_test;
end $$;
revoke all on function app.demo_test(uuid, uuid, uuid, uuid, uuid[], int, text, jsonb, int[], int, boolean, timestamptz)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Cehd: sagirdin bacarigina (0..1) gore cavablar; zeif movzuda -0.3
-- ---------------------------------------------------------------------
create or replace function app.demo_attempt(p_student uuid, p_test uuid, p_class uuid,
  p_ability numeric, p_weak uuid[], p_at timestamptz)
returns numeric
language plpgsql as $$
declare
  v_att uuid;
  r record;
  v_ok boolean;
  v_sel uuid;
  v_score numeric := 0;
  v_max numeric := 0;
  v_pc numeric;
  v_par jsonb;
  v_params jsonb := '{}'::jsonb;
  v_dur int := 0;
begin
  insert into public.attempts (student_id, test_id, class_id, status, started_at)
  values (p_student, p_test, p_class, 'in_progress', p_at) returning id into v_att;
  for r in select q.id, q.topic_id, q.body, q.explanation, q.params, coalesce(tq.points, q.points) as pts
             from public.test_questions tq join public.questions q on q.id = tq.question_id
            where tq.test_id = p_test order by tq.ord loop
    v_max := v_max + r.pts;
    v_par := app.pq_seed(r.params, r.id);
    if v_par is not null then v_params := v_params || jsonb_build_object(r.id::text, v_par); end if;
    if random() < 0.04 then continue; end if;   -- cavabsiz
    v_pc := p_ability - case when r.topic_id = any(p_weak) then 0.3 else 0 end;
    v_ok := random() < v_pc;
    select o.id into v_sel from public.question_options o
     where o.question_id = r.id and o.is_correct = v_ok order by random() limit 1;
    if v_sel is null then
      select o.id into v_sel from public.question_options o where o.question_id = r.id order by random() limit 1;
      v_ok := (select is_correct from public.question_options where id = v_sel);
    end if;
    v_dur := v_dur + 6 + floor(random() * 60)::int;
    insert into public.attempt_answers (attempt_id, question_id, topic_id, selected_option_ids, is_correct,
                                        points, question_body, question_explanation, seconds, sure, answered_at)
    values (v_att, r.id, r.topic_id, array[v_sel], v_ok, case when v_ok then r.pts else 0 end,
            app.pq_render(r.body, v_par), app.pq_render(r.explanation, v_par),
            6 + floor(random() * 60)::int, random() > 0.15, p_at + make_interval(secs => v_dur));
    if v_ok then v_score := v_score + r.pts; end if;
  end loop;
  update public.attempts
     set status = 'submitted', finished_at = p_at + make_interval(secs => v_dur + 30),
         duration_sec = v_dur + 30, score = v_score, max_score = v_max,
         percent = case when v_max > 0 then round(v_score * 100 / v_max, 2) else 0 end,
         params = case when v_params = '{}'::jsonb then null else v_params end
   where id = v_att;
  return case when v_max > 0 then round(v_score * 100 / v_max, 2) else 0 end;
end $$;
revoke all on function app.demo_attempt(uuid, uuid, uuid, numeric, uuid[], timestamptz)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  QURUCU
-- ---------------------------------------------------------------------
create or replace function app.demo_build(p_owner uuid, p_account uuid, p_fixed boolean)
returns jsonb
language plpgsql as $$
declare
  v_riy  uuid; v_l3 record; v_l7 record;
  v_c1 uuid; v_c2 uuid;
  v_names1 text[] := array['Ayan Məmmədova','Murad Həsənov','Nigar Əliyeva','Tural Quliyev','Leyla Hüseynova',
                           'Elvin Rəhimov','Aysel Kərimova','Kənan İbrahimov','Zəhra Abbasova','Rəşad Nəbiyev',
                           'Fidan Səfərova','Orxan Mustafayev'];
  v_names2 text[] := array['Aytac Cəfərova','Nihad Vəliyev','Günel Əhmədova','Rauf Ağayev',
                           'Səbinə Qasımova','Tunar Bağırov','Lalə Hacıyeva','Ülvi Salmanov'];
  --  1-ci sagird (DEMO0001 / VDEMO001 - numune girisleri) ORTA seviyyeli:
  --  zeif movzu ve sehv defteri gorunsun.  Gucluler 3 ve 4-dur.
  v_abil1 numeric[] := array[0.72,0.86,0.92,0.78,0.74,0.70,0.68,0.66,0.62,0.55,0.48,0.42];
  v_abil2 numeric[] := array[0.85,0.75,0.72,0.66,0.62,0.58,0.52,0.45];
  v_stu1 uuid[] := '{}'; v_stu2 uuid[] := '{}';
  v_sid uuid; v_code text; v_pcode text; i int; k int;
  v_plan uuid; v_plan2 uuid;
  v_items uuid[]; v_topics uuid[]; v_weak uuid[] := '{}';
  v_item uuid; v_topic uuid; v_tname text; v_test uuid; v_at timestamptz; v_days int[] := array[45,40,35,30,25,20,15,10,3];
  v_par record;
  v_exam uuid; v_diag uuid;
  v_month date := date_trunc('month', current_date)::date;
  v_les uuid; v_d date;
  v_q uuid;
  v_code1 text; v_pcode1 text;
begin
  perform setseed(case when p_fixed then 0.4242 else random() end);

  -- ---- temizlik (numune hesabin oz melumati)
  delete from public.classes where account_id = p_account;
  delete from public.tests where owner_type = 'educator' and owner_id = p_owner;
  delete from public.feedback where account_id = p_account;
  delete from public.question_reports where account_id = p_account;
  delete from public.students where account_id = p_account;

  update public.accounts set subjects = '{riyaziyyat}', is_demo = true where id = p_account;
  update public.profiles set full_name = 'Nümunə Müəllim' where id = p_owner and coalesce(full_name, '') in ('', 'Nümunə Müəllim');
  if not app.has_active_subscription(p_account) then
    insert into public.subscriptions (account_id, plan_id, status, seats, current_period_end)
    select p_account, p.id, 'active', 25, now() + interval '365 days'
      from public.plans p where p.slug = 'repetitor-25';
  end if;

  select id into v_riy from public.subjects where slug = 'riyaziyyat';
  select l.* into v_l3 from public.levels l where l.code = '3' order by l.sort limit 1;
  select l.* into v_l7 from public.levels l where l.code = '7' order by l.sort limit 1;

  -- ---- qrup 1: 3-cu sinif, 12 sagird
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_l3.program_id, v_l3.id, '3-cü sinif — şənbə qrupu', app.gen_login_code(8))
  returning id into v_c1;
  for i in 1..12 loop
    v_code := case when p_fixed then 'DEMO' || lpad(i::text, 4, '0') else app.gen_login_code(8) end;
    v_pcode := case when i = 1 then (case when p_fixed then 'VDEMO001' else 'V' || app.gen_login_code(7) end) else null end;
    insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, parent_code, created_at)
    values (p_account, v_c1, p_owner, v_names1[i], app.unique_display_name(v_c1, v_names1[i]), v_code, v_pcode,
            now() - interval '50 days' + make_interval(mins => i))
    returning id into v_sid;
    v_stu1 := v_stu1 || v_sid;
    if i = 1 then v_code1 := v_code; v_pcode1 := v_pcode; end if;
  end loop;

  -- ---- plan: riyaziyyat 3, yarpaqlar, ilk 9 kecilib
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c1, v_riy, v_l3.id, now() - interval '48 days') returning id into v_plan;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_l3.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan;

  --  zeif movzu: "Kesrler" fesli (yoxdursa 8-ci movzunun fesli)
  select coalesce(
    (select t.id from public.topics t where t.subject_id = v_riy and t.level_id = v_l3.id and t.parent_id is null and t.name ilike 'Kəsr%' limit 1),
    (select tp.o_id from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[8])) tp))
    into v_topic;
  --  zeif movzular: Kesrler (diaqnostikada gorunur) + 6-ci dersin fesli
  --  (ev tapsiriqlarinda gorunur - sagird hesabatinda "zeif" cixsin)
  v_weak := array[v_topic];
  if cardinality(v_items) >= 6 then
    v_weak := v_weak || (select tp.o_id from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[6])) tp);
  end if;

  for i in 1..least(9, cardinality(v_items)) loop
    v_item := v_items[i];
    v_at := now() - make_interval(days => v_days[i]);
    update public.class_plan_items set done_at = v_at where id = v_item;
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_item));
    --  ev tapsirigi
    v_test := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, array[v_par.o_id], 10,
                v_par.o_name || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_item;
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c1, v_test, p_owner, v_at, case when i = 9 then now() + interval '4 days' else v_at + interval '7 days' end, 1, v_at);
    for k in 1..12 loop
      --  sonuncu (acıq) tapsiriq: 4 nefer hele etmeyib
      if i = 9 then
        if k in (3, 7, 10, 12) then continue; end if;
        perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k], v_weak, now() - make_interval(hours => 6 + floor(random() * 60)::int));
      elsif random() < 0.86 then
        perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k], v_weak, v_at + make_interval(hours => 20 + floor(random() * 96)::int));
      end if;
    end loop;
    --  isinme: son uc movzuda
    if i >= 7 then
      v_test := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, array[v_par.o_id], 5,
                  'İsinmə — ' || v_par.o_name, jsonb_build_object('pack','warm','topics',jsonb_build_array(v_par.o_id::text)),
                  '{1,2}', null, false, v_at - interval '1 day');
      update public.class_plan_items set warm_test_id = v_test where id = v_item;
      insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
      values (v_c1, v_test, p_owner, v_at - interval '1 day', v_at, 1, v_at - interval '1 day');
      for k in 1..12 loop
        if random() < 0.7 then
          perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k] + 0.1, v_weak, v_at - make_interval(hours => 2 + floor(random() * 14)::int));
        end if;
      end loop;
    end if;
    --  rub sinagi: 6-ci movzudan sonra
    if i = 6 then
      select array_agg(distinct tp.o_id) into v_topics
        from unnest(v_items[1:6]) x join public.class_plan_items it on it.id = x
        cross join lateral app.pack_topic(it.topic_id) tp;
      v_exam := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, v_topics, 20,
                  'Rüb sınağı — Riyaziyyat · 6 mövzu', jsonb_build_object('pack','exam','plan',v_plan::text,'topics',to_jsonb(v_topics)),
                  '{1,2,3}', null, false, v_at + interval '1 day');
      insert into public.plan_exams (plan_id, test_id, item_ids, created_at) values (v_plan, v_exam, v_items[1:6], v_at + interval '1 day');
      insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
      values (v_c1, v_exam, p_owner, v_at + interval '1 day', v_at + interval '8 days', 1, v_at + interval '1 day');
      for k in 1..12 loop
        if k <> 6 and k <> 11 then
          perform app.demo_attempt(v_stu1[k], v_exam, v_c1, v_abil1[k], v_weak, v_at + make_interval(days => 2, hours => floor(random() * 96)::int));
        end if;
      end loop;
    end if;
  end loop;

  -- ---- diaqnostika (35 gun evvel): her kok movzudan 3 sual
  select array_agg(t.id) into v_topics from public.topics t
   where t.subject_id = v_riy and t.level_id = v_l3.id and t.parent_id is null;
  v_at := now() - interval '35 days';
  v_diag := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, v_topics, 3 * cardinality(v_topics),
              'Diaqnostika · Riyaziyyat · ' || v_l3.name,
              jsonb_build_object('kind','diagnostic','subject','riyaziyyat','level',v_l3.code,'per_topic',3),
              '{1,2,3}', 3, true, v_at);
  insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
  values (v_c1, v_diag, p_owner, v_at, v_at + interval '7 days', 1, v_at);
  for k in 1..12 loop
    perform app.demo_attempt(v_stu1[k], v_diag, v_c1, v_abil1[k], v_weak, v_at + make_interval(hours => 10 + floor(random() * 100)::int));
  end loop;

  -- ---- movzu mesqi: uc sagird
  for k in 1..3 loop
    insert into public.practice (student_id, topic_id, score, streak, answered, correct, mastered_at, started_at, updated_at)
    select v_stu1[k], t.id, 100, 4, 9, 8, now() - interval '6 days', now() - interval '9 days', now() - interval '6 days'
      from public.topics t where t.id = v_topics[1];
    insert into public.practice (student_id, topic_id, score, streak, answered, correct, started_at, updated_at)
    select v_stu1[k], t.id, 40 + 12 * k, 1, 7, 5, now() - interval '2 days', now() - make_interval(hours => 5 * k)
      from public.topics t where t.id = v_weak[1];
  end loop;

  -- ---- davamiyyet: son 6 senbe; odenis: bu ay 8 odenib, kecen ay hamisi
  for k in 0..6 loop
    v_d := (date_trunc('week', current_date)::date + 5) - k * 7;   -- senbe
    if v_d > current_date then continue; end if;
    insert into public.lessons (class_id, held_on, created_by) values (v_c1, v_d, p_owner) returning id into v_les;
    insert into public.attendance (lesson_id, student_id, present)
    select v_les, s, random() > 0.12 from unnest(v_stu1) s;
  end loop;
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu1[g.n], v_month, g.n <= 8, case when g.n <= 8 then now() - make_interval(days => 2 + g.n) end, p_owner
    from generate_series(1, 12) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu1[g.n], (v_month - interval '1 month')::date, true, v_month - make_interval(days => 20 - g.n), p_owner
    from generate_series(1, 12) as g(n);

  -- ---- bize yaz + sual bildirisi
  insert into public.feedback (author_type, user_id, account_id, kind, page, body, created_at)
  values ('teacher', p_owner, p_account, 'teklif', 'hesabat',
          'Qrup hesabatında zəif mövzuların yanında «təkrar dərs» üçün hazır test düyməsi çox yaxşı olardı.',
          now() - interval '4 days');
  select tq.question_id into v_q from public.test_questions tq
   where tq.test_id = (select test_id from public.class_plan_items where id = v_items[2]) order by tq.ord limit 1;
  if v_q is not null then
    insert into public.question_reports (question_id, student_id, reason, note, created_at)
    values (v_q, v_stu1[4], 'yazi', 'Sualda «neçə edər» sözü iki dəfə yazılıb.', now() - interval '2 days');
  end if;

  -- ---- qrup 2: 7-ci sinif, 8 sagird, plan 2 movzu
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_l7.program_id, v_l7.id, '7-ci sinif — DİM hazırlıq', app.gen_login_code(8))
  returning id into v_c2;
  for i in 1..8 loop
    v_code := case when p_fixed then 'DEMO' || lpad((12 + i)::text, 4, '0') else app.gen_login_code(8) end;
    insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, created_at)
    values (p_account, v_c2, p_owner, v_names2[i], app.unique_display_name(v_c2, v_names2[i]), v_code,
            now() - interval '30 days' + make_interval(mins => i))
    returning id into v_sid;
    v_stu2 := v_stu2 || v_sid;
  end loop;
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c2, v_riy, v_l7.id, now() - interval '28 days') returning id into v_plan2;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan2, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_l7.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan2;
  if cardinality(v_items) >= 2 then
    update public.class_plan_items set done_at = now() - interval '20 days' where id = v_items[1];
    update public.class_plan_items set done_at = now() - interval '12 days' where id = v_items[2];
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[2]));
    v_at := now() - interval '12 days';
    v_test := app.demo_test(p_owner, v_riy, v_l7.id, v_l7.program_id, array[v_par.o_id], 10,
                v_par.o_name || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_items[2];
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c2, v_test, p_owner, v_at, v_at + interval '7 days', 1, v_at);
    for k in 1..8 loop
      if k <> 5 and k <> 8 then
        perform app.demo_attempt(v_stu2[k], v_test, v_c2, v_abil2[k], '{}', v_at + make_interval(hours => 20 + floor(random() * 96)::int));
      end if;
    end loop;
  end if;

  return jsonb_build_object('ok', true, 'account_id', p_account, 'student_code', v_code1, 'parent_code', v_pcode1,
                            'classes', 2, 'students', 20);
end $$;
revoke all on function app.demo_build(uuid, uuid, boolean) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Paylasilan numunenin sahibi ve hesabi (sabit ID) - yoxdursa yaradilir
-- ---------------------------------------------------------------------
create or replace function app.demo_ensure_shared() returns void
language plpgsql as $$
begin
  if not exists (select 1 from auth.users where id = app.demo_owner()) then
    insert into auth.users (id, email, raw_user_meta_data)
    values (app.demo_owner(), 'numune@bil10.local', '{"full_name":"Nümunə Müəllim"}'::jsonb);
  end if;
  insert into public.profiles (id, full_name) values (app.demo_owner(), 'Nümunə Müəllim')
  on conflict (id) do nothing;
  if not exists (select 1 from public.accounts where id = app.demo_account()) then
    insert into public.accounts (id, type, name, owner_id, is_demo, subjects)
    values (app.demo_account(), 'tutor', 'Nümunə hesabı', app.demo_owner(), true, '{riyaziyyat}');
  end if;
  insert into public.account_members (account_id, user_id, is_admin)
  values (app.demo_account(), app.demo_owner(), true) on conflict do nothing;
  insert into public.user_roles (user_id, role) values (app.demo_owner(), 'tutor') on conflict do nothing;
end $$;
revoke all on function app.demo_ensure_shared() from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Muellim kimi bax: ziyaretcinin (anonim istifadecinin) oz nusxesi
-- ---------------------------------------------------------------------
create or replace function public.rpc_demo_start()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  --  artiq hesabi varsa: numunedirse yeniden qurulur, deyilse toxunulmur
  select a.id into v_acc from public.accounts a where a.owner_id = v_uid order by a.created_at limit 1;
  if v_acc is not null and not (select is_demo from public.accounts where id = v_acc) then
    raise exception 'Bu istifadecinin oz hesabi var - numune yalniz yeni ziyaretci ucundur.' using errcode = '42501';
  end if;
  if v_acc is null then
    insert into public.profiles (id, full_name) values (v_uid, 'Nümunə Müəllim') on conflict (id) do nothing;
    insert into public.accounts (type, name, owner_id, is_demo) values ('tutor', 'Nümunə hesabı', v_uid, true)
    returning id into v_acc;
    insert into public.account_members (account_id, user_id, is_admin) values (v_acc, v_uid, true);
    insert into public.user_roles (user_id, role) values (v_uid, 'tutor') on conflict do nothing;
  end if;
  v_res := app.demo_build(v_uid, v_acc, false);
  return v_res;
end $$;
revoke all on function public.rpc_demo_start() from public, anon;
grant execute on function public.rpc_demo_start() to authenticated;

-- ---------------------------------------------------------------------
--  Gece isi (anon acar ile): paylasilan numune yeniden qurulur, kohne
--  anonim nusxeler silinir.  10 deqiqede birden cox islemir.
-- ---------------------------------------------------------------------
create or replace function public.rpc_demo_reset()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_last timestamptz;
  v_res  jsonb;
  v_del  int := 0;
begin
  select (val->>'at')::timestamptz into v_last from public.app_state where key = 'demo_reset';
  if v_last is not null and v_last > now() - interval '10 minutes' then
    return jsonb_build_object('ok', true, 'skipped', true, 'last', v_last);
  end if;
  insert into public.app_state (key, val, updated_at) values ('demo_reset', jsonb_build_object('at', now()), now())
  on conflict (key) do update set val = excluded.val, updated_at = now();

  perform app.demo_ensure_shared();
  v_res := app.demo_build(app.demo_owner(), app.demo_account(), true);

  --  24 saatdan kohne anonim nusxeler.  accounts.owner_id ve
  --  classes.teacher_id RESTRICT-dir - evvel qruplar/testler/hesab,
  --  sonra istifadeci (profil kaskadla gedir).
  create temp table if not exists demo_old (owner_id uuid, account_id uuid) on commit drop;
  delete from demo_old;
  insert into demo_old select a.owner_id, a.id from public.accounts a
   where a.is_demo and a.id <> app.demo_account() and a.created_at < now() - interval '24 hours';
  delete from public.classes c using demo_old o where c.account_id = o.account_id;
  delete from public.tests t using demo_old o where t.owner_type = 'educator' and t.owner_id = o.owner_id;
  delete from public.students s using demo_old o where s.account_id = o.account_id;
  delete from public.accounts a using demo_old o where a.id = o.account_id;
  delete from auth.users u using demo_old o where u.id = o.owner_id;
  get diagnostics v_del = row_count;
  return v_res || jsonb_build_object('deleted_copies', v_del);
end $$;
revoke all on function public.rpc_demo_reset() from public;
grant execute on function public.rpc_demo_reset() to anon, authenticated;

-- rpc_my_context (esas: 26): is_demo, demo_codes
create or replace function public.rpc_my_context()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  return jsonb_build_object(
    'user_id', v_uid,
    'profile', (select jsonb_build_object('full_name', p.full_name, 'phone', p.phone)
                  from public.profiles p where p.id = v_uid),
    'roles',   coalesce((select jsonb_agg(role) from public.user_roles where user_id = v_uid), '[]'::jsonb),
    'accounts', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',    a.id,
               'type',  a.type,
               'name',  a.name,
               'is_owner', a.owner_id = v_uid,
               --  136: numune hesab nisani ve numune kodlari (zolaq ucun)
               'is_demo', a.is_demo,
               'demo_codes', case when a.is_demo then (
                   select jsonb_build_object('student', st.login_code, 'parent', st.parent_code)
                     from public.students st where st.account_id = a.id
                    order by st.created_at, st.id limit 1) end,
               'subjects', to_jsonb(a.subjects),
               'students_used',  app.account_student_count(a.id),
               'students_limit', app.account_seat_limit(a.id),
               'plan', (select jsonb_build_object('slug', pl.slug, 'name', pl.name)
                          from public.subscriptions s2
                          join public.plans pl on pl.id = s2.plan_id
                         where s2.account_id = a.id
                           and s2.status in ('trialing','active')
                           and (s2.current_period_end is null or s2.current_period_end > now())
                         order by s2.started_at desc limit 1)
             ) order by a.name)
        from public.accounts a
        join public.account_members m on m.account_id = a.id and m.user_id = v_uid
    ), '[]'::jsonb)
  );
end $$;

