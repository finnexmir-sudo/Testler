-- =====================================================================
--  928 : PLAN - «KECILEN DERSLERDEN TEST»  (2026-10-08)
--
--  PROBLEM
--  Plan ekranindaki «Kecilen dersler dan test yig» dugmesi rpc_pack_exam
--  (p_all) cagirirdi.  O, sualları FESIL hovuzundan goturur (app.pack_topic):
--  fesil 2/7 kecilibse, hele kecilmemis dersin sualı da dusurdu.  Ders qapisi
--  (903) ele bunun olmamasi ucun qurulub - dugme onu yan kecirdi.
--
--  HELL
--  Yeni rpc_plan_test_done(plan, count): YALNIZ kecilmis VE hazir (>= app.ders_min
--  nisanli sual) dersleri goturur; her dersden OZ 'ders:<slug>' nisani ile
--  app.generate_pick cagirir (rpc_plan_test-in ders yolu ile eyni secim), neticeni
--  BIR testde birlesdirir.  Generator deyismir.
--    · p_item_ids verilibse YALNIZ secilmis (kecilmis + hazir) dersler; verilmeyibse hamisi;
--    · kecilmemis dersin sualı DUSMUR;
--    · kecilmis, amma hele hazir olmayan ders daxil edilmir - cavabda 'skipped' ile
--      deyilir (interfeys muellime yazir);
--    · hec bir hazir kecilmis ders yoxdursa - xeta;
--    · qrupa dərhal tapsirilir (7 gun, 1 cehd) - rpc_plan_test ile eyni;
--    · sual sayi dersler arasi beraber bolunur (qalıq ilk dersleri artirir);
--    · evvel verilmis suallar novbede geri qalir (exclude, 223).
--  rub sinagi (rpc_pack_exam) TOXUNULMUR.
--
--  ON SERT: 13/103 (generator), 223 (generate_pick), 903/926 (ders qapisi).
-- =====================================================================

drop function if exists public.rpc_plan_test_done(uuid, int);
create or replace function public.rpc_plan_test_done(
  p_plan_id uuid, p_count int default 20, p_item_ids uuid[] default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_plan   public.class_plans%rowtype;
  v_cls    public.classes%rowtype;
  v_subj   text;
  v_lev    text;
  v_excl   jsonb;
  r        record;
  v_tids   uuid[] := '{}';
  v_slugs  text[] := '{}';
  v_n      int := 0;          -- hazir, kecilmis dersler
  v_skip   int := 0;          -- kecilmis, amma hele hazir deyil
  v_base   int;
  v_rem    int;
  v_want   int;
  v_ids    uuid[];
  v_all    uuid[] := '{}';
  v_rule   jsonb;
  v_test   uuid;
  v_title  text;
  i        int;
begin
  if p_count is null or p_count < 5 or p_count > 50 then
    raise exception 'Sual sayi 5-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = p_plan_id;
  if not found then
    raise exception 'Plan tapilmadi.' using errcode = '22023';
  end if;
  v_cls := app.plan_class(v_plan.class_id);
  if not app.has_active_subscription(v_cls.account_id) then
    raise exception 'Platformanin sual bankindan test yigmaq abune paketine daxildir. Oz suallarinizdan yiga bilersiniz.'
      using errcode = '42501';
  end if;

  --  kecilmis dersler: hovuz VALIDEYNDEDIR (fesil), ders nisani oz slug-udur (rpc_plan_test kimi)
  for r in
    select coalesce(par.id, t.id) as tid, t.slug
      from public.class_plan_items i
      join public.topics t on t.id = i.topic_id
      left join public.topics par on par.id = t.parent_id
     where i.plan_id = p_plan_id and i.done_at is not null
       and (p_item_ids is null or i.id = any(p_item_ids))     -- 928: muellimin SECDIYI dersler
     order by i.ord
  loop
    if r.slug is not null and r.slug <> ''
       and app.ders_sual_sayi(r.tid, r.slug) >= app.ders_min() then
      v_tids  := v_tids  || r.tid;
      v_slugs := v_slugs || r.slug;
      v_n := v_n + 1;
    else
      v_skip := v_skip + 1;
    end if;
  end loop;
  if v_n = 0 then
    raise exception 'Kecilmis dersler ucun hele hazir sual yoxdur.' using errcode = '22023';
  end if;

  select s.slug into v_subj from public.subjects s where s.id = v_plan.subject_id;
  select l.code into v_lev  from public.levels   l where l.id = v_plan.level_id;

  --  223: bu qrupa SON 20 tapsiriqda verilmis suallar (sert deyil, novbede geri qalir)
  select coalesce(jsonb_agg(distinct tq.question_id::text), '[]'::jsonb)
    into v_excl
    from (select a.test_id from public.assignments a
           where a.class_id = v_plan.class_id
           order by a.created_at desc limit 20) z
    join public.test_questions tq on tq.test_id = z.test_id;

  --  sual sayi dersler arasi beraber; 20 sualdan cox ders varsa her birinden en azi 1 (sonda p_count-a kesilir)
  v_base := p_count / v_n;
  v_rem  := p_count % v_n;
  for i in 1 .. v_n loop
    v_want := greatest(1, v_base + case when i <= v_rem then 1 else 0 end);
    v_rule := jsonb_build_object(
      'pool', 'all', 'count', v_want,
      'subject', v_subj, 'level', v_lev,
      'topics',  jsonb_build_array(v_tids[i]::text),
      'tags',    jsonb_build_array(app.ders_tag(v_slugs[i])),
      'exclude', v_excl);
    v_ids := app.generate_pick(v_rule, v_cls.account_id);
    --  eyni sual iki dersde nisanlana biler - tekrar atilir
    select coalesce(array_agg(x), '{}') into v_ids
      from unnest(v_ids) x where x <> all (v_all);
    v_all := v_all || v_ids;
  end loop;
  if coalesce(array_length(v_all, 1), 0) < 3 then
    raise exception 'Kecilmis dersler uzre kifayet qeder ferqli sual tapilmadi.' using errcode = '22023';
  end if;
  if array_length(v_all, 1) > p_count then
    v_all := v_all[1:p_count];
  end if;

  v_title := 'Keçilənlərdən test — ' || (select name from public.subjects where id = v_plan.subject_id)
             || ' · ' || v_n || ' dərs';
  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title,
     status, gen_rule, shuffle_questions, shuffle_options)
  values ('educator', auth.uid(),
          (select p.id from public.programs p where p.slug = 'ibtidai'),
          v_plan.subject_id, v_plan.level_id, v_title, 'published',
          jsonb_build_object('pack', 'done', 'plan', p_plan_id::text,
                             'subject', v_subj, 'level', v_lev, 'count', array_length(v_all, 1)),
          true, true)
  returning id into v_test;
  for i in 1 .. array_length(v_all, 1) loop
    insert into public.test_questions (test_id, question_id, ord) values (v_test, v_all[i], i);
  end loop;

  perform public.rpc_assign_test(v_plan.class_id, v_test, now() + interval '7 days', 1);

  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', array_length(v_all, 1),
                            'lessons', v_n, 'skipped', v_skip);
end $$;

revoke all on function public.rpc_plan_test_done(uuid, int, uuid[]) from public, anon;
grant execute on function public.rpc_plan_test_done(uuid, int, uuid[]) to authenticated;
