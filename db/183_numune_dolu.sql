-- =====================================================================
--  183_numune_dolu.sql — NUMUNE HESABDAKI BOSLUQLAR
--
--  Canli baxis (2026-09-10, telefon): "muellim kimi numune girisinde
--  bosluqlar gordum, tam dolu veziyyet gostersin".
--
--  UC BOSLUQ:
--   1. PAKET.  136 numuneye 'repetitor-25' verirdi (25 yer).  169-da o
--      paket satisdan cixdi, mehsul 'sagird-basi' oldu - limitsiz.
--      Numunede 25 sagird var idi, yeni limit HEMISE dolu: Icmalda
--      "Paketin limiti dolub" xeberdarligi cixirdi.  Gosterisde bu
--      hem sehv (o paketi artiq satmiriq), hem de pis gorunurdu.
--   2. BOS SAGIRDLER.  2-ci qrupda 5-ci ve 8-ci, 3-cu qrupda 4-cu
--      sagird HEC BIR test etmemisdi - hesabatlari tamam bos acilirdi
--      (0 test, 0%, "Hələ test işləməyib").  Indi herkesin en azi bir
--      neticesi var; "kim etmeyib" kartı yene isleyir, cunki hemin
--      neferler yalniz SON tapsirigi etmeyib.
--   3. BOS TABLAR.  Davamiyyet, odenis defteri ve hefte cedveli yalniz
--      1-ci qrupda var idi.  Indi ucunde de var, ucuncu qrupa bugunku
--      hefte gunu de yazilir - Icmalda "Bu gün dərs var" gorunsun.
--
--  Elave: 3-cu qrupda bir movzu evezine uc movzu kecilib, uc testle.
--  Testin adinda YARPAG movzunun adi islenir - app.pack_topic FESIL
--  adini qaytarir ve uc test eyni adla cixirdi.
--
--  Govde 136-dan proqramla cixarilib (yalniz yuxaridaki bloklar
--  deyisib), demo_attempt / demo_test / rpc_demo_start toxunulmayib.
-- =====================================================================

do $$
begin
  if to_regprocedure('app.demo_build(uuid, uuid, boolean)') is null then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
  if not exists (select 1 from public.plans where slug = 'sagird-basi') then
    raise exception 'ONCE 165_sagird_basi_qiymet.sql isledilmelidir.';
  end if;
end $$;

create or replace function app.demo_build(p_owner uuid, p_account uuid, p_fixed boolean)
returns jsonb
language plpgsql as $$
declare
  v_riy  uuid; v_lm record; v_l3 record; v_l11 record;   -- esas qrup 7-ci sinif
  v_c1 uuid; v_c2 uuid;
  v_names1 text[] := array['Ayan Məmmədova','Murad Həsənov','Nigar Əliyeva','Tural Quliyev','Leyla Hüseynova',
                           'Elvin Rəhimov','Aysel Kərimova','Kənan İbrahimov','Zəhra Abbasova','Rəşad Nəbiyev',
                           'Fidan Səfərova','Orxan Mustafayev'];
  v_names2 text[] := array['Aytac Cəfərova','Nihad Vəliyev','Günel Əhmədova','Rauf Ağayev',
                           'Səbinə Qasımova','Tunar Bağırov','Lalə Hacıyeva','Ülvi Salmanov'];
  v_names3 text[] := array['Cavid Məmmədli','Nərmin Əsgərova','Emil Tağıyev','Aylin Şirinova','Fərid Zeynalov'];
  v_abil3 numeric[] := array[0.88,0.80,0.72,0.66,0.58];
  v_c3 uuid; v_stu3 uuid[] := '{}'; v_plan3 uuid;
  --  1-ci sagird (DEMO0001 / VDEMO001 - numune girisleri) ORTA seviyyeli:
  --  zeif movzu ve sehv defteri gorunsun.  Gucluler 3 ve 4-dur.
  --  Canli baxisdan sonra qaldirildi: orta 50% ve 7 nefer tehluke zonasinda
  --  hedden artiq zeif gorunurdu; hedef orta 60-65%, zonada 3-4 nefer.
  v_abil1 numeric[] := array[0.82,0.94,0.97,0.88,0.85,0.82,0.80,0.78,0.74,0.68,0.60,0.52];
  v_abil2 numeric[] := array[0.90,0.82,0.78,0.74,0.70,0.66,0.60,0.52];
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
  --  183: 169-dan sonra 'repetitor-25' satisdan cixdi (25 yer limiti).
  --  Numunede o paket qalmisdi ve deqiq 25 sagirdle limit HEMISE dolu
  --  idi - gosterisde "Paketin limiti dolub" xeberdarligi cixirdi.
  --  Indi numune canli mehsulun ozunu gosterir: 'sagird-basi', limitsiz.
  delete from public.subscriptions s
   using public.plans p
   where s.account_id = p_account and p.id = s.plan_id and p.slug <> 'sagird-basi';
  if not app.has_active_subscription(p_account) then
    insert into public.subscriptions (account_id, plan_id, status, seats, current_period_end)
    select p_account, p.id, 'active', 1, now() + interval '30 days'
      from public.plans p where p.slug = 'sagird-basi';
  else
    --  Kohne nusxede muddet neceyse qalmisdisa taze yazilir: numune
    --  hemise "aylik abune, novbeti odenis bir aydan sonra" kimi
    --  gorunsun (evvel 365 gun yazilirdi - aylik mehsula uygun deyil).
    update public.subscriptions
       set status = 'active', current_period_end = now() + interval '30 days'
     where account_id = p_account;
  end if;

  select id into v_riy from public.subjects where slug = 'riyaziyyat';
  select l.* into v_lm  from public.levels l where l.code = '7'  order by l.sort limit 1;
  select l.* into v_l3  from public.levels l where l.code = '3'  order by l.sort limit 1;
  select l.* into v_l11 from public.levels l where l.code = '11' order by l.sort limit 1;

  -- ---- qrup 1 (esas, zengin): 7-ci sinif, 12 sagird
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_lm.program_id, v_lm.id, '7-ci sinif — şənbə qrupu', app.gen_login_code(8))
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

  -- ---- plan: riyaziyyat (esas sinif), yarpaqlar, ilk 9 kecilib
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c1, v_riy, v_lm.id, now() - interval '48 days') returning id into v_plan;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_lm.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan;

  --  zeif movzu (diaqnostikada, hamiya): ilk 9 dersin fesillerinden OLMAYAN
  --  ilk fesil - hovuz ferqli olsun deye
  select t.id into v_topic from public.topics t
   where t.subject_id = v_riy and t.level_id = v_lm.id and t.parent_id is null
     and t.id not in (select tp.o_id from unnest(v_items[1:least(9, cardinality(v_items))]) x
                        join public.class_plan_items it on it.id = x
                        cross join lateral app.pack_topic(it.topic_id) tp)
   order by t.sort limit 1;
  if v_topic is null then
    select tp.o_id into v_topic from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[cardinality(v_items)])) tp;
  end if;
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
    v_test := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, array[v_par.o_id], 10,
                v_par.o_name || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_item;
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c1, v_test, p_owner, v_at, case when i = 9 then now() + interval '4 days' else v_at + interval '7 days' end, 1, v_at);
    for k in 1..12 loop
      --  sonuncu (acıq) tapsiriq: 4 nefer hele etmeyib
      if i = 9 then
        if k in (3, 7, 10, 12) then continue; end if;
        perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k], case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, now() - make_interval(hours => 6 + floor(random() * 60)::int));
      elsif random() < 0.86 then
        perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k], case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, v_at + make_interval(hours => 20 + floor(random() * 96)::int));
      end if;
    end loop;
    --  isinme: son uc movzuda
    if i >= 7 then
      v_test := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, array[v_par.o_id], 5,
                  'İsinmə — ' || v_par.o_name, jsonb_build_object('pack','warm','topics',jsonb_build_array(v_par.o_id::text)),
                  '{1,2}', null, false, v_at - interval '1 day');
      update public.class_plan_items set warm_test_id = v_test where id = v_item;
      insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
      values (v_c1, v_test, p_owner, v_at - interval '1 day', v_at, 1, v_at - interval '1 day');
      for k in 1..12 loop
        if random() < 0.7 then
          perform app.demo_attempt(v_stu1[k], v_test, v_c1, v_abil1[k] + 0.1, case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, v_at - make_interval(hours => 2 + floor(random() * 14)::int));
        end if;
      end loop;
    end if;
    --  rub sinagi: 6-ci movzudan sonra
    if i = 6 then
      select array_agg(distinct tp.o_id) into v_topics
        from unnest(v_items[1:6]) x join public.class_plan_items it on it.id = x
        cross join lateral app.pack_topic(it.topic_id) tp;
      v_exam := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, v_topics, 20,
                  'Rüb sınağı — Riyaziyyat · 6 mövzu', jsonb_build_object('pack','exam','plan',v_plan::text,'topics',to_jsonb(v_topics)),
                  '{1,2,3}', null, false, v_at + interval '1 day');
      insert into public.plan_exams (plan_id, test_id, item_ids, created_at) values (v_plan, v_exam, v_items[1:6], v_at + interval '1 day');
      insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
      values (v_c1, v_exam, p_owner, v_at + interval '1 day', v_at + interval '8 days', 1, v_at + interval '1 day');
      for k in 1..12 loop
        if k <> 6 and k <> 11 then
          perform app.demo_attempt(v_stu1[k], v_exam, v_c1, v_abil1[k], case when k in (1, 7, 10, 11, 12) then v_weak else v_weak[1:1] end, v_at + make_interval(days => 2, hours => floor(random() * 96)::int));
        end if;
      end loop;
    end if;
  end loop;

  -- ---- diaqnostika (35 gun evvel): her kok movzudan 3 sual
  select array_agg(t.id) into v_topics from public.topics t
   where t.subject_id = v_riy and t.level_id = v_lm.id and t.parent_id is null;
  v_at := now() - interval '35 days';
  v_diag := app.demo_test(p_owner, v_riy, v_lm.id, v_lm.program_id, v_topics, 3 * cardinality(v_topics),
              'Diaqnostika · Riyaziyyat · ' || v_lm.name,
              jsonb_build_object('kind','diagnostic','subject','riyaziyyat','level',v_lm.code,'per_topic',3),
              '{1,2,3}', 3, true, v_at);
  insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
  values (v_c1, v_diag, p_owner, v_at, v_at + interval '7 days', 1, v_at);
  --  diaqnostika dersden EVVELdir: bacariq 0.12 asagi, Kesrler hamiya zeif
  --  (qrup hesabatinda "axsayan movzu" gorunsun)
  for k in 1..12 loop
    perform app.demo_attempt(v_stu1[k], v_diag, v_c1, v_abil1[k] - 0.12, v_weak, v_at + make_interval(hours => 10 + floor(random() * 100)::int));
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

  -- ---- qrup 2: 3-cu sinif, 8 sagird, plan 2 movzu
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_l3.program_id, v_l3.id, '3-cü sinif — ibtidai', app.gen_login_code(8))
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
  values (v_c2, v_riy, v_l3.id, now() - interval '28 days') returning id into v_plan2;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan2, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_l3.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan2;
  if cardinality(v_items) >= 2 then
    update public.class_plan_items set done_at = now() - interval '20 days' where id = v_items[1];
    update public.class_plan_items set done_at = now() - interval '12 days' where id = v_items[2];
    --  183: birinci movzunun testini HAMI edib.  Evvel yalniz bir test
    --  var idi ve 5-ci ile 8-ci sagird hec ne etmemis qalirdi - numunede
    --  bos hesabat acilirdi.  "Kim etmeyib" yene isleyir: o iki nefer
    --  ASAGIDAKI (son) tapsirigi etmeyib.
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[1]));
    select t.name into v_tname from public.topics t
     where t.id = (select topic_id from public.class_plan_items where id = v_items[1]);
    v_at := now() - interval '20 days';
    v_test := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, array[v_par.o_id], 10,
                v_tname || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_items[1];
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c2, v_test, p_owner, v_at, v_at + interval '7 days', 1, v_at);
    for k in 1..8 loop
      perform app.demo_attempt(v_stu2[k], v_test, v_c2, v_abil2[k], '{}', v_at + make_interval(hours => 20 + floor(random() * 96)::int));
    end loop;
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[2]));
    v_at := now() - interval '12 days';
    v_test := app.demo_test(p_owner, v_riy, v_l3.id, v_l3.program_id, array[v_par.o_id], 10,
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

  -- ---- qrup 3: 11-ci sinif DIM hazirliq, 5 sagird, 1 movzu kecilib
  insert into public.classes (account_id, teacher_id, kind, program_id, level_id, name, join_code)
  values (p_account, p_owner, 'tutor_group', v_l11.program_id, v_l11.id, '11-ci sinif — DİM hazırlıq', app.gen_login_code(8))
  returning id into v_c3;
  for i in 1..5 loop
    v_code := case when p_fixed then 'DEMO' || lpad((20 + i)::text, 4, '0') else app.gen_login_code(8) end;
    insert into public.students (account_id, class_id, created_by, full_name, display_name, login_code, created_at)
    values (p_account, v_c3, p_owner, v_names3[i], app.unique_display_name(v_c3, v_names3[i]), v_code,
            now() - interval '20 days' + make_interval(mins => i))
    returning id into v_sid;
    v_stu3 := v_stu3 || v_sid;
  end loop;
  insert into public.class_plans (class_id, subject_id, level_id, created_at)
  values (v_c3, v_riy, v_l11.id, now() - interval '18 days') returning id into v_plan3;
  insert into public.class_plan_items (plan_id, topic_id, ord)
  select v_plan3, t.id, row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name)
    from public.topics t left join public.topics par on par.id = t.parent_id
   where t.subject_id = v_riy and t.level_id = v_l11.id
     and not exists (select 1 from public.topics c where c.parent_id = t.id);
  select array_agg(id order by ord) into v_items from public.class_plan_items where plan_id = v_plan3;
  --  183: evvel BIR movzu, BIR test var idi ve 4-cu sagird onu da
  --  etmemisdi - numunede o sagirdin butun tablari bos acilirdi.
  --  Indi uc movzu kecilib, ucu de testli; 4-cu sagird yalniz SON
  --  tapsirigi etmeyib ("kim etmeyib" gorunsun deye).
  --  Basliqda YARPAG movzunun adi islenir: pack_topic FESIL adini
  --  qaytarir, uc test eyni adla cixirdi.
  if cardinality(v_items) >= 1 then
   for i in 1..least(3, cardinality(v_items)) loop
    v_at := now() - make_interval(days => 9 + (3 - i) * 7);
    update public.class_plan_items set done_at = v_at where id = v_items[i];
    select * into v_par from app.pack_topic((select topic_id from public.class_plan_items where id = v_items[i]));
    select t.name into v_tname from public.topics t
     where t.id = (select topic_id from public.class_plan_items where id = v_items[i]);
    v_test := app.demo_test(p_owner, v_riy, v_l11.id, v_l11.program_id, array[v_par.o_id], 10,
                v_tname || ' — yoxlama', jsonb_build_object('pack','hw','topics',jsonb_build_array(v_par.o_id::text)),
                '{1,2,3}', null, false, v_at);
    update public.class_plan_items set test_id = v_test where id = v_items[i];
    insert into public.assignments (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
    values (v_c3, v_test, p_owner, v_at, v_at + interval '7 days', 1, v_at);
    for k in 1..5 loop
      if i = least(3, cardinality(v_items)) and k = 4 then continue; end if;
      perform app.demo_attempt(v_stu3[k], v_test, v_c3, v_abil3[k], '{}', v_at + make_interval(hours => 20 + floor(random() * 96)::int));
    end loop;
   end loop;
  end if;

  -- ---- 183: valideyn kodu HER sagirde.  182-den sonra yeni qrupda
  --  kodlar ozu yaranir; numunede yalniz bir sagirdde var idi ve
  --  gosterisde valideyn hissesi gorunmurdu.  Birinci sagirdin kodu
  --  (VDEMO001) toxunulmur - ana sehifedeki "Valideyn kimi bax" ona
  --  baglidir.
  --  Bir statement icinde tekrar yoxlamasi isini gormezdi (hele
  --  yazilmamis setirler gorunmur), ona gore bir-bir verilir -
  --  students_parent_code_key unikal indeksdir.
  for v_sid in select s.id from public.students s
                where s.account_id = p_account and s.parent_code is null
  loop
    update public.students set parent_code = app.parent_code_new() where id = v_sid;
  end loop;

  -- ---- 183: qrup 2 ve 3 ucun de davamiyyet, odenis defteri ve cedvel.
  --  Evvel yalniz 1-ci qrupda var idi - o biri iki qrupun «Davamiyyət»
  --  ve «Ödəniş» tablari numunede bos acilirdi.
  for k in 0..3 loop
    v_d := (date_trunc('week', current_date)::date + 4) - k * 7;    -- cume
    if v_d <= current_date then
      insert into public.lessons (class_id, held_on, created_by) values (v_c2, v_d, p_owner) returning id into v_les;
      insert into public.attendance (lesson_id, student_id, present)
      select v_les, s, random() > 0.1 from unnest(v_stu2) s;
    end if;
    v_d := (date_trunc('week', current_date)::date + 3) - k * 7;    -- cume axsami
    if v_d <= current_date then
      insert into public.lessons (class_id, held_on, created_by) values (v_c3, v_d, p_owner) returning id into v_les;
      insert into public.attendance (lesson_id, student_id, present)
      select v_les, s, random() > 0.1 from unnest(v_stu3) s;
    end if;
  end loop;
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu2[g.n], v_month, g.n <= 6, case when g.n <= 6 then now() - make_interval(days => 3 + g.n) end, p_owner
    from generate_series(1, 8) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu2[g.n], (v_month - interval '1 month')::date, true, v_month - make_interval(days => 18 - g.n), p_owner
    from generate_series(1, 8) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu3[g.n], v_month, g.n <= 4, case when g.n <= 4 then now() - make_interval(days => 4 + g.n) end, p_owner
    from generate_series(1, 5) as g(n);
  insert into public.fee_payments (student_id, month, paid, paid_at, updated_by)
  select v_stu3[g.n], (v_month - interval '1 month')::date, true, v_month - make_interval(days => 16 - g.n), p_owner
    from generate_series(1, 5) as g(n);

  --  Hefte cedveli (177).  Cedvel yoxdursa Icmalda «Bu gün dərs var»
  --  ve «Bütün həftə» kartlari hec vaxt gorunmurdu.  Ucuncu qrupa
  --  bugunku hefte gunu de elave olunur ki, numune hemise "canli" olsun.
  if to_regclass('public.class_schedule') is not null then
    delete from public.class_schedule cs using public.classes c
     where cs.class_id = c.id and c.account_id = p_account;
    insert into public.class_schedule (class_id, weekday, starts_at, mins) values
      (v_c1, 6, '11:00', 90),
      (v_c2, 2, '18:00', 60), (v_c2, 5, '18:00', 60),
      (v_c3, 1, '16:00', 90), (v_c3, 4, '16:00', 90)
    on conflict do nothing;
    insert into public.class_schedule (class_id, weekday, starts_at, mins)
    values (v_c3, extract(isodow from (now() at time zone 'Asia/Baku'))::int, '16:00', 90)
    on conflict do nothing;
  end if;

  return jsonb_build_object('ok', true, 'account_id', p_account, 'student_code', v_code1, 'parent_code', v_pcode1,
                            'classes', 3, 'students', 25);
end $$;
revoke all on function app.demo_build(uuid, uuid, boolean) from public, anon, authenticated;
