-- =====================================================================
--  178_sinif_mesaji.sql - qrupun sinfi yoxdursa NE oldugunu deyirik
--
--  NIYE
--  Sinif MECBURI DEYIL: classes.level_id bos qala biler, formada da
--  "Sinif secilmeyib" variantI var.  Muellim bilerekden bos qoya
--  biler - meselen 1-4 sinfi bir yerde hazirlayan repetitor.
--
--  Amma kohne metn ("Qrupun sinfi secilmeyib - qrup ayarlarinda sinfi
--  secin.") bunu SEHV kimi oxudurdu: emr verirdi, sebebini demirdi.
--  Muellim bilmirdi ki, sinfi qoymasa NE itirir.
--
--  Teze metn itkini adI ile deyir - qerarI muellim ozu verir:
--    "Sinif secilmeyib - diaqnostika ve sagirdin serbest mesqi baglidir."
--
--  Yol boyu diakritikler de duzeldi: bu setirler ISTIFADECIYE gorunur,
--  ona gore ASCII deyil, duzgun Azerbaycan herfleri ile yazilir
--  (kod serhleri ASCII qalir).  "Sagird hec bir qrupda deyil." de
--  hemin kartda cixir, o da duzeldi.
--
--  BU FAYL 118_diaqnostika.sql-DEN PROQRAMLA CIXARILIB - iki
--  funksiyanin govdesi herfen eynidir, yalniz metn setirleri
--  deyisib.  Elle kocurulmeyib ki, tesadufen basqa sey deyismesin.
--
--  db/133-deki sagird metni TOXUNULMUR: onu sagird oxuyur, sagird
--  sinfi ozu secə bilmir - ona "muelliminə de" demek dogrudur.
-- =====================================================================

create or replace function public.rpc_diagnostic_options(p_student_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_lev   public.levels%rowtype;
  v_paid  boolean;
begin
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  v_paid := app.has_active_subscription(v_st.account_id);
  if v_st.class_id is null then
    return jsonb_build_object('paid', v_paid, 'level', null, 'subjects', '[]'::jsonb,
                              'reason', 'Şagird heç bir qrupda deyil.');
  end if;
  select * into v_class from public.classes where id = v_st.class_id;
  if v_class.level_id is null then
    return jsonb_build_object('paid', v_paid, 'level', null, 'subjects', '[]'::jsonb,
                              'reason', 'Sinif seçilməyib — diaqnostika və şagirdin sərbəst məşqi bağlıdır.');
  end if;
  select * into v_lev from public.levels where id = v_class.level_id;

  return jsonb_build_object(
    'paid',  v_paid,
    'level', jsonb_build_object('code', v_lev.code, 'name', v_lev.name),
    'subjects', coalesce((
      select jsonb_agg(x order by (x->>'sort')::int, x->>'name')
        from (
          select jsonb_build_object(
                   'slug', s.slug, 'name', s.name, 'sort', s.sort,
                   'topics', (select count(*) from app.diag_topics(s.id, v_lev.id)),
                   'questions', (select count(*) from app.diag_topics(s.id, v_lev.id)) * app.min_topic_answers(),
                   --  bu fennde son diaqnostika (varsa)
                   'last', (
                     select jsonb_build_object(
                              'test_id',   t.id,
                              'assigned_at', a.created_at,
                              'closes_at', a.closes_at,
                              'open',      app.assignment_open(a.*),
                              'taken',     exists (select 1 from public.attempts at
                                                    where at.test_id = t.id and at.student_id = v_st.id
                                                      and at.status = 'submitted'),
                              'percent',   (select round(max(at.percent), 0) from public.attempts at
                                             where at.test_id = t.id and at.student_id = v_st.id
                                               and at.status = 'submitted'))
                       from public.assignments a
                       join public.tests t on t.id = a.test_id and t.is_diagnostic
                      where a.student_id = v_st.id and t.subject_id = s.id
                      order by a.created_at desc limit 1)) as x
            from public.subjects s
           where exists (select 1 from app.diag_topics(s.id, v_lev.id))
        ) z), '[]'::jsonb));
end $$;

create or replace function public.rpc_diagnostic_create(
  p_student_id uuid, p_subject text, p_days int default 7)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_lev   public.levels%rowtype;
  v_subj  public.subjects%rowtype;
  v_acc   uuid;
  v_open  uuid;
  v_ids   uuid[] := '{}';
  v_pick  uuid[];
  v_any   uuid[];
  r       record;
  d       int;
  i       int;
  v_n     int := 0;
  v_test  uuid;
  v_close timestamptz;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  if v_st.class_id is null then
    raise exception 'Şagird heç bir qrupda deyil.' using errcode = '22023';
  end if;
  select * into v_class from public.classes where id = v_st.class_id;
  if v_class.level_id is null then
    raise exception 'Sinif seçilməyib — diaqnostika və şagirdin sərbəst məşqi bağlıdır.' using errcode = '22023';
  end if;
  v_acc := v_st.account_id;
  if not app.has_active_subscription(v_acc) then
    raise exception 'Diaqnostik test platformanin sual bankindan yigilir - abune paketine daxildir.'
      using errcode = '42501';
  end if;
  if p_days is null or p_days < 1 or p_days > 60 then
    raise exception 'Muddet 1-60 gun araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_subj from public.subjects where slug = p_subject;
  if not found then
    raise exception 'Fenn tapilmadi.' using errcode = '22023';
  end if;
  select * into v_lev from public.levels where id = v_class.level_id;

  --  Acıq, hele yazilmamis diaqnostika varsa DUBLIKAT yaratma - onu qaytar
  select t.id into v_open
    from public.tests t
    join public.assignments a on a.test_id = t.id and a.student_id = v_st.id
   where t.is_diagnostic and t.subject_id = v_subj.id and app.assignment_open(a.*)
     and not exists (select 1 from public.attempts at
                      where at.test_id = t.id and at.student_id = v_st.id and at.status = 'submitted')
   order by a.created_at desc limit 1;
  if v_open is not null then
    return jsonb_build_object('test_id', v_open, 'existing', true,
             'questions', (select count(*) from public.test_questions where test_id = v_open),
             'closes_at', (select a.closes_at from public.assignments a
                            where a.test_id = v_open and a.student_id = v_st.id limit 1));
  end if;

  --  Her fesilden 3 sual: asan, orta, cetin - varsa; yoxsa ne varsa
  for r in select * from app.diag_topics(v_subj.id, v_lev.id) loop
    v_pick := '{}';
    for d in 1..3 loop
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_lev.code,
                 'topics', jsonb_build_array(r.topic_id::text),
                 'difficulty', jsonb_build_array(d::text),
                 'count', 1, 'pool', 'platform'), v_acc);
      if coalesce(array_length(v_any, 1), 0) >= 1 and not (v_any[1] = any(v_pick)) then
        v_pick := v_pick || v_any[1];
      end if;
    end loop;
    if coalesce(array_length(v_pick, 1), 0) < 3 then
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_lev.code,
                 'topics', jsonb_build_array(r.topic_id::text),
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
  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title, description,
     status, gen_rule, shuffle_questions, shuffle_options, time_limit_sec,
     max_attempts, pass_percent, is_free, is_diagnostic)
  values ('educator', v_uid, v_lev.program_id, v_subj.id, v_lev.id,
          'Diaqnostika · ' || v_subj.name || ' · ' || v_lev.name,
          'Hər mövzudan 3 sual — hansı mövzudan başlamalı olduğunu göstərir.',
          'published',
          jsonb_build_object('kind', 'diagnostic', 'subject', v_subj.slug,
                             'level', v_lev.code, 'per_topic', 3, 'student', v_st.id),
          true, true, 75 * array_length(v_ids, 1), 1, 60, true, true)
  returning id into v_test;

  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.test_questions (test_id, question_id, ord) values (v_test, v_ids[i], i);
  end loop;

  --  Teyinat YALNIZ bu sagirde - movcud yoxlamalar (28) ile
  perform public.rpc_assign_test(v_st.class_id, v_test, v_close, 1, v_st.id);

  return jsonb_build_object('test_id', v_test, 'existing', false,
                            'questions', array_length(v_ids, 1), 'topics', v_n,
                            'closes_at', v_close,
                            'title', 'Diaqnostika · ' || v_subj.name || ' · ' || v_lev.name);
end $$;

revoke all on function public.rpc_diagnostic_options(uuid)           from public, anon;
revoke all on function public.rpc_diagnostic_create(uuid, text, int) from public, anon;
grant execute on function public.rpc_diagnostic_options(uuid)           to authenticated;
grant execute on function public.rpc_diagnostic_create(uuid, text, int) to authenticated;
