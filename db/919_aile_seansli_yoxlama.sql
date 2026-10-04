-- =====================================================================
--  919 : AILE YOLU - SEANSLI BASLANGIC YOXLAMA (2026-10-06)
--
--  Evvel: bir fenn = bir test = sinfin BUTUN fesillerinden 3 sual (24-36 sual).  Iki problem:
--    * bir oturumda cox uzun (usaq yorulur, tesadufi cavab verir - «Diqqet» 21 %-e dusurdu);
--    * hele KECILMEMIS fesillerden sual verilirdi - zeif netice yalan idi.
--  Indi: bir fenn = bir SERIYA (run) = bir nece HISSE (seans), her hisse <=5 fesil x 3 sual = 15 sual (~15-20 deq).
--    Seriyanin fesilleri: evvelki sinfin (N-1) BUTUN fesilleri + bu sinfin (N) ILK ucde biri (en azi 2) -
--    usagin bildiyi + indi kecdiyi materyal.  Siya ilk hissede gen_rule-da saxlanir (kitab bankasi deyisse seriya pozulmasin).
--    Valideyn her hisseni «Novbeti hisse ver» ile ozu verir (usaq bezmesin); netice hisseler uzre BIRLESIR:
--    «Diqqet» movzu uzre cavablari birlikde sayir (915), ayrica birlesdirme lazim deyil.
--  rpc_family_children: her fenn ucun state = none | open | partial | done  + done/of (hisse sayi).
--  Muellim yolu (rpc_diagnostic_create) deyismir.
--  ON SERT: 913-918.   Tekrar isledile biler.
-- =====================================================================

create or replace function app.family_diag_state(p_student uuid, p_subject uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_g    jsonb;
  v_run  text;
  v_of   int;
  v_done int;
  v_open boolean;
begin
  select t.gen_rule into v_g
    from public.assignments a join public.tests t on t.id = a.test_id
   where a.student_id = p_student and t.is_diagnostic and t.subject_id = p_subject
   order by a.created_at desc limit 1;
  if v_g is null then
    return jsonb_build_object('state', 'none');
  end if;
  v_run := v_g->>'run';
  if v_run is null then                        -- kohne, tek hisseli yoxlama
    if exists (select 1 from public.attempts at join public.tests t on t.id = at.test_id
                where at.student_id = p_student and t.is_diagnostic and t.subject_id = p_subject and at.status = 'submitted') then
      return jsonb_build_object('state', 'done', 'done', 1, 'of', 1);
    end if;
    return jsonb_build_object('state', 'open', 'done', 0, 'of', 1);
  end if;
  v_of := coalesce((v_g->>'of')::int, 1);
  select count(distinct t.id) into v_done
    from public.attempts at join public.tests t on t.id = at.test_id
   where at.student_id = p_student and t.is_diagnostic and t.gen_rule->>'run' = v_run and at.status = 'submitted';
  select exists (select 1 from public.assignments a join public.tests t on t.id = a.test_id
                  where a.student_id = p_student and t.is_diagnostic and t.subject_id = p_subject
                    and app.assignment_open(a.*)
                    and not exists (select 1 from public.attempts at where at.test_id = t.id and at.student_id = p_student and at.status = 'submitted'))
    into v_open;
  return jsonb_build_object('state', case when v_done >= v_of then 'done' when v_open then 'open' else 'partial' end,
                            'done', v_done, 'of', v_of);
end $$;
revoke all on function app.family_diag_state(uuid, uuid) from public, anon, authenticated;

create or replace function app.family_diag_session(p_student uuid, p_subject text, p_days int default 14)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid    uuid := auth.uid();
  v_st     public.students%rowtype;
  v_class  public.classes%rowtype;
  v_lev    public.levels%rowtype;
  v_prev   public.levels%rowtype;
  v_subj   public.subjects%rowtype;
  v_acc    uuid;
  v_open   uuid;
  v_g      jsonb;
  v_run    text;
  v_topics uuid[] := '{}';
  v_cur    uuid[];
  v_of     int;
  v_done   int;
  v_seq    int;
  v_chunk  uuid[];
  v_ids    uuid[] := '{}';
  v_pick   uuid[];
  v_any    uuid[];
  v_tid    uuid;
  v_code   text;
  d        int;
  i        int;
  v_n      int := 0;
  v_test   uuid;
  v_close  timestamptz;
  v_title  text;
  c_per    constant int := 5;          -- bir hissede fesil sayi (5 x 3 = 15 sual)
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.can_read_student(p_student) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student;
  if v_st.class_id is null then
    raise exception 'Şagird heç bir qrupda deyil.' using errcode = '22023';
  end if;
  select * into v_class from public.classes where id = v_st.class_id;
  if v_class.level_id is null then
    raise exception 'Sinif seçilməyib.' using errcode = '22023';
  end if;
  v_acc := v_st.account_id;
  if not app.has_active_subscription(v_acc) then
    raise exception 'Diaqnostik test platformanin sual bankindan yigilir - abune paketine daxildir.' using errcode = '42501';
  end if;
  if p_days is null or p_days < 1 or p_days > 60 then
    raise exception 'Muddet 1-60 gun araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_subj from public.subjects where slug = p_subject;
  if not found then
    raise exception 'Fenn tapilmadi.' using errcode = '22023';
  end if;
  select * into v_lev from public.levels where id = v_class.level_id;

  --  Acıq, hele yazilmamis hisse varsa DUBLIKAT yaratma - onu qaytar
  select t.id into v_open
    from public.tests t join public.assignments a on a.test_id = t.id and a.student_id = v_st.id
   where t.is_diagnostic and t.subject_id = v_subj.id and app.assignment_open(a.*)
     and not exists (select 1 from public.attempts at
                      where at.test_id = t.id and at.student_id = v_st.id and at.status = 'submitted')
   order by a.created_at desc limit 1;
  if v_open is not null then
    select t.gen_rule into v_g from public.tests t where t.id = v_open;
    return jsonb_build_object('test_id', v_open, 'existing', true,
             'questions', (select count(*) from public.test_questions where test_id = v_open),
             'part', coalesce((v_g->>'seq')::int, 1), 'of', coalesce((v_g->>'of')::int, 1),
             'closes_at', (select a.closes_at from public.assignments a
                            where a.test_id = v_open and a.student_id = v_st.id limit 1));
  end if;

  --  Cari seriya (son tapsirilan hisseden)
  select t.gen_rule into v_g
    from public.assignments a join public.tests t on t.id = a.test_id
   where a.student_id = v_st.id and t.is_diagnostic and t.subject_id = v_subj.id and t.gen_rule ? 'run'
   order by a.created_at desc limit 1;

  if v_g is not null then
    v_run := v_g->>'run';
    v_of  := coalesce((v_g->>'of')::int, 1);
    select count(distinct t.id) into v_done
      from public.attempts at join public.tests t on t.id = at.test_id
     where at.student_id = v_st.id and t.is_diagnostic and t.gen_rule->>'run' = v_run and at.status = 'submitted';
    if v_done >= v_of then
      return jsonb_build_object('complete', true, 'part', v_of, 'of', v_of);
    end if;
    v_topics := array(select x::uuid from jsonb_array_elements_text(v_g->'topics') x);
    v_seq := v_done + 1;
  else
    --  Yeni seriya: evvelki sinfin hamisi + bu sinfin ilk ucde biri (en azi 2)
    if v_lev.code ~ '^[0-9]+$' then
      select * into v_prev from public.levels where code = ((v_lev.code::int) - 1)::text order by sort limit 1;
    end if;
    if v_prev.id is not null then
      v_topics := array(select z.topic_id from app.diag_topics(v_subj.id, v_prev.id) z);
    end if;
    v_cur := array(select z.topic_id from app.diag_topics(v_subj.id, v_lev.id) z);
    if coalesce(cardinality(v_cur), 0) > 0 then
      v_topics := v_topics || v_cur[1 : greatest(2, ceil(cardinality(v_cur) / 3.0)::int)];
    end if;
    if coalesce(cardinality(v_topics), 0) = 0 then
      raise exception 'Bu fenn ve sinif ucun kifayet qeder sual yoxdur.' using errcode = '22023';
    end if;
    v_run := gen_random_uuid()::text;
    v_of  := ceil(cardinality(v_topics) / c_per::numeric)::int;
    v_seq := 1;
  end if;

  v_chunk := v_topics[(v_seq - 1) * c_per + 1 : v_seq * c_per];

  --  Her fesilden 3 sual: asan, orta, cetin - varsa; yoxsa ne varsa (fesil oz sinfinin kodu ile)
  foreach v_tid in array coalesce(v_chunk, '{}') loop
    select l.code into v_code from public.topics t join public.levels l on l.id = t.level_id where t.id = v_tid;
    v_pick := '{}';
    for d in 1..3 loop
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_code,
                 'topics', jsonb_build_array(v_tid::text),
                 'difficulty', jsonb_build_array(d::text),
                 'count', 1, 'pool', 'platform'), v_acc);
      if coalesce(array_length(v_any, 1), 0) >= 1 and not (v_any[1] = any(v_pick)) then
        v_pick := v_pick || v_any[1];
      end if;
    end loop;
    if coalesce(array_length(v_pick, 1), 0) < 3 then
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_code,
                 'topics', jsonb_build_array(v_tid::text),
                 'count', 6, 'pool', 'platform'), v_acc);
      for i in 1 .. coalesce(array_length(v_any, 1), 0) loop
        exit when coalesce(array_length(v_pick, 1), 0) >= 3;
        if not (v_any[i] = any(v_pick)) then v_pick := v_pick || v_any[i]; end if;
      end loop;
    end if;
    if coalesce(array_length(v_pick, 1), 0) = 3 then
      v_ids := v_ids || v_pick;
      v_n := v_n + 1;
    end if;
  end loop;
  if v_n = 0 then
    raise exception 'Bu fenn ve sinif ucun kifayet qeder sual yoxdur.' using errcode = '22023';
  end if;

  v_close := now() + make_interval(days => p_days);
  v_title := 'Diaqnostika · ' || v_subj.name || ' · ' || v_lev.name
             || case when v_of > 1 then ' · ' || v_seq || '/' || v_of || '-ci hissə' else '' end;
  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title, description,
     status, gen_rule, shuffle_questions, shuffle_options, time_limit_sec,
     max_attempts, pass_percent, is_free, is_diagnostic)
  values ('educator', v_uid, v_lev.program_id, v_subj.id, v_lev.id, v_title,
          'Hər mövzudan 3 sual — hansı mövzudan başlamalı olduğunu göstərir.',
          'published',
          jsonb_build_object('kind', 'diagnostic', 'subject', v_subj.slug, 'level', v_lev.code, 'per_topic', 3,
                             'student', v_st.id, 'run', v_run, 'seq', v_seq, 'of', v_of, 'topics', to_jsonb(v_topics)),
          true, true, 75 * array_length(v_ids, 1), 1, 60, true, true)
  returning id into v_test;

  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.test_questions (test_id, question_id, ord) values (v_test, v_ids[i], i);
  end loop;

  perform public.rpc_assign_test(v_st.class_id, v_test, v_close, 1, v_st.id);

  return jsonb_build_object('test_id', v_test, 'existing', false,
                            'questions', array_length(v_ids, 1), 'topics', v_n,
                            'part', v_seq, 'of', v_of, 'closes_at', v_close, 'title', v_title);
end $$;
revoke all on function app.family_diag_session(uuid, text, int) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  914-den kopya: add_child (ilk 3 fenn ucun 1-ci hisse), children (state/done/of), diag (novbeti hisse)
-- ---------------------------------------------------------------------
create or replace function public.rpc_family_add_child(
  p_name text, p_level_code text, p_subjects text[], p_minutes int default 10, p_consent boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid;
  v_name  text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_subs  text[] := '{}';
  v_s     text;
  v_cls   jsonb;
  v_stu   jsonb;
  v_sid   uuid;
  v_diag  jsonb := '[]'::jsonb;
  v_res   jsonb;
  v_n     int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.family_ok() then
    raise exception 'Bu xidmət hələ açılmayıb. Tezliklə.' using errcode = '42501';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  if coalesce(p_consent, false) is not true then
    raise exception 'Uşağın məlumatlarının saxlanmasına razılıq lazımdır.' using errcode = '22023';
  end if;
  if length(v_name) < 2 or length(v_name) > 60 then
    raise exception 'Uşağın adını yazın (2–60 simvol).' using errcode = '22023';
  end if;
  if coalesce(btrim(p_level_code), '') !~ '^[0-9]{1,2}$'
     or not exists (select 1 from public.levels where code = btrim(p_level_code)) then
    raise exception 'Sinif seçin.' using errcode = '22023';
  end if;
  if p_minutes is null or p_minutes not in (5, 10, 15, 20, 30) then p_minutes := 10; end if;

  --  Fennler: yalniz movcud slug, tekrarsiz, en cox 5
  foreach v_s in array coalesce(p_subjects, '{}') loop
    if exists (select 1 from public.subjects where slug = v_s) and not (v_s = any(v_subs)) then
      v_subs := v_subs || v_s;
    end if;
    exit when array_length(v_subs, 1) >= 12;
  end loop;
  if coalesce(array_length(v_subs, 1), 0) = 0 then
    raise exception 'Ən azı bir fənn seçin.' using errcode = '22023';
  end if;

  select count(*) into v_n from public.students where account_id = v_acc and is_active;
  if v_n >= 6 then
    raise exception 'Bir hesaba ən çox 6 uşaq əlavə olunur.' using errcode = '22023';
  end if;

  --  gizli «self_study» qrup (sinifi ile) + sagird + kodlar (movcud RPC-ler, eyni qaydalar)
  v_cls := public.rpc_create_class(v_acc, v_name, 'self_study', null, btrim(p_level_code));
  v_stu := public.rpc_add_student((v_cls->>'id')::uuid, v_name, split_part(v_name, ' ', 1));      -- gorunen ad: ilk ad (Huseyn)
  v_sid := (v_stu->>'id')::uuid;

  insert into public.consents (student_id, granted_by, kind, evidence)
  values (v_sid, v_uid, 'parental',
          jsonb_build_object('version', 'aile-v3', 'text', 'Usagin adi ve neticeleri yalniz valideyne gorunur, hec yerde paylasilmir. Raziyam.',
                             'at', now(), 'source', 'family_add_child'));

  insert into public.family_kids (student_id, subjects, minutes) values (v_sid, v_subs, p_minutes);

  --  Baslangic diaqnostika: secilen fennlerin ilk 3-u (movcud rpc; alinmasa usaq elave edilmesi pozulmur)
  for v_s in select unnest(v_subs[1:3]) loop
    begin
      v_res := app.family_diag_session(v_sid, v_s, 14);
      v_diag := v_diag || jsonb_build_object('subject', v_s, 'ok', true, 'questions', coalesce(v_res->>'questions', null), 'part', v_res->>'part', 'of', v_res->>'of');
    exception when others then
      v_diag := v_diag || jsonb_build_object('subject', v_s, 'ok', false, 'error', left(sqlerrm, 160));
    end;
  end loop;

  return jsonb_build_object('ok', true, 'student_id', v_sid, 'name', v_stu->>'display_name',
                            'login_code', v_stu->>'login_code', 'diagnostics', v_diag,
                            'subjects_total', coalesce(array_length(v_subs, 1), 0));
end $$;

create or replace function public.rpc_family_children()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    return jsonb_build_object('has_account', false);
  end if;
  return jsonb_build_object(
    'has_account', true,
    'account', (select jsonb_build_object('name', a.name,
                        'locked', app.account_locked(a.id),
                        'active', app.has_active_subscription(a.id),
                        'trial_end', (select max(s.current_period_end) from public.subscriptions s
                                       where s.account_id = a.id and s.status in ('trialing', 'active')))
                  from public.accounts a where a.id = v_acc),
    'kids', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', st.id,
               'name', st.display_name,
               'sinif', (select l.code from public.classes c join public.levels l on l.id = c.level_id where c.id = st.class_id),
               'subjects', coalesce(fk.subjects, '{}'),
               'subject_names', coalesce((select jsonb_agg(sj.name order by sj.sort, sj.name) from public.subjects sj
                                           where sj.slug = any(coalesce(fk.subjects, '{}'))), '[]'::jsonb),
               'minutes', coalesce(fk.minutes, 10),
               'login_code', st.login_code,
               'subject_diag', coalesce((
                   select jsonb_agg(jsonb_build_object('slug', sj.slug, 'name', sj.name) || app.family_diag_state(st.id, sj.id)
                            order by sj.sort, sj.name)
                     from public.subjects sj where sj.slug = any(coalesce(fk.subjects, '{}'))), '[]'::jsonb),
               'diag_total', (select count(*) from public.assignments a join public.tests t on t.id = a.test_id
                               where a.student_id = st.id and t.is_diagnostic),
               'diag_done',  (select count(distinct at.test_id) from public.attempts at join public.tests t on t.id = at.test_id
                               where at.student_id = st.id and t.is_diagnostic and at.status = 'submitted'))
             order by st.created_at, st.id)
        from public.students st
        left join public.family_kids fk on fk.student_id = st.id
       where st.account_id = v_acc and st.is_active), '[]'::jsonb));
end $$;

create or replace function public.rpc_family_diag(p_student uuid, p_subject text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if not exists (select 1 from public.family_kids fk where fk.student_id = p_student and p_subject = any(fk.subjects)) then
    raise exception 'Bu fənn uşaq üçün seçilməyib.' using errcode = '22023';
  end if;
  v_res := app.family_diag_session(p_student, p_subject, 14);
  return jsonb_build_object('ok', true, 'existing', coalesce((v_res->>'existing')::boolean, false),
                            'complete', coalesce((v_res->>'complete')::boolean, false),
                            'questions', v_res->>'questions', 'part', v_res->>'part', 'of', v_res->>'of');
end $$;

revoke all on function public.rpc_family_add_child(text, text, text[], int, boolean) from public, anon;
grant execute on function public.rpc_family_add_child(text, text, text[], int, boolean) to authenticated;
revoke all on function public.rpc_family_children() from public, anon;
grant execute on function public.rpc_family_children() to authenticated;
revoke all on function public.rpc_family_diag(uuid, text) from public, anon;
grant execute on function public.rpc_family_diag(uuid, text) to authenticated;
