-- =====================================================================
--  222 : DERS TESTI - «ders:<slug>» nisani ile (2026-09-23)
--
--  NIYE
--  Indiyedek plan testi FESIL hovuzundan yigilirdi: alt movzunun oz
--  sualı yox idi (101).  Bank sessiyasi indi her suala DERS nisani
--  yazir: questions.tags -> 'ders:<alt-movzu-slug>'.  Sxem deyismir,
--  topic_id yerinde qalir - sual yene fesle baglidir, nisan onu dersе
--  daraldir.
--
--  BU FAYL YALNIZ BIRINCI ADDIMDIR (3 addimdan):
--    1) BU: rpc_plan_test nisanli hovuzdan yigir, az olsa fesle dusur
--    2) generator islenmis suali cixarsin (p_rule->'exclude')
--    3) can_test her kecilmis dersde acilsin
--  Sira qesdendir: qapi EN SONDA acilir.  Acilan kimi muellimler
--  basacaq - arxasindaki iki sey hazir olmalidir.
--
--  GENERATORA TOXUNULMUR.  p_rule->'tags' onsuz da isleyir
--  (13_generator.sql: q.tags @> ...).  Tek nisan ucun bu yeterlidir.
--  rpc_plan_test_multi HELE fesil hovuzundan yigir: orada bir nece
--  ders secilir, «@>» ise HAMISINI teleb edir (AND), bize ISE biri
--  (OR) lazimdir.  Onun ucun generatora 'any_tags' acari lazimdir -
--  2-ci addimda, generator onsuz da acilanda elave olunacaq.
--
--  HEDDLER BIR YERDE
--  Dunen «12 fənn» dersi: eyni reqem iki yerde yazilanda biri
--  kohnelir.  Ona gore hedd ve test olcusu FUNKSIYADIR - qapi (3-cu
--  addim) ve bu fayl EYNI funksiyani cagirir.
--
--  ON SERT: 101 (rpc_plan_test), 13 (generator), 11 (idx_q_tags).
-- =====================================================================

-- ------------------------------------------------- heddler
--  Niye 20?  Test 10 sualdir; hovuz test olcusune beraberdirse secim
--  YOXDUR - her defe eyni test cixar, «tekrar yig» de eynisini verer.
--  Qayda: hovuz >= 2 x test.  10-19 arasi yalniz isinme (5 sual) ucun
--  bes edir, ders testi ucun yox.
create or replace function app.ders_min() returns int
language sql immutable as $$ select 20 $$;

--  Ders testi FESIL testinden qisadir: bir ders, 10 sual.
--  Qalan 10 sual «tekrar yig» ucun saxlanilir.
create or replace function app.ders_test_count() returns int
language sql immutable as $$ select 10 $$;

--  Nisanin yazilisi BIR yerdedir - iki yerde iki qayda olmasin.
create or replace function app.ders_tag(p_slug text) returns text
language sql immutable as $$ select 'ders:' || coalesce(p_slug, '') $$;

-- ------------------------------------------------- hovuz sayi
--  DIQQET: bu sayim generatorun suzgeci ile EYNI olmalidir, yoxsa
--  qapi «22 sual var» deyer, generator 18 tapar ve xeta atar.
--  Ona gore burada da: fesil movzusu + nisan + platform/published.
--  Muellimin OZ sualları sayilmir - onlar yalniz ARTIRA biler, yani
--  bu reqem doseme'dir, sisirdilmis deyil.
create or replace function app.ders_sual_sayi(p_fesil uuid, p_slug text)
returns int
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select count(*)::int
    from public.questions q
   where q.topic_id = p_fesil
     and q.owner_type = 'platform'
     and q.status = 'published'
     and q.tags @> array[app.ders_tag(p_slug)]
$$;

-- ------------------------------------------------- plan testi
--  TAM govde yazilir (marker uslubu istifade edilmir).
--  101-deki govdenin uzerine YALNIZ nisan secimi elave olunur.
create or replace function public.rpc_plan_test(
  p_item_id uuid, p_count int default 15)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_item   public.class_plan_items%rowtype;
  v_plan   public.class_plans%rowtype;
  v_topic  text;
  v_tid    uuid;
  v_slug   text;
  v_leaf   text;
  v_n      int := 0;
  v_ders   boolean := false;
  v_count  int;
  v_rule   jsonb;
  v_res    jsonb;
  v_test   uuid;
begin
  if p_count is null or p_count < 3 or p_count > 50 then
    raise exception 'Sual sayi 3-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_item from public.class_plan_items where id = p_item_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  select * into v_plan from public.class_plans where id = v_item.plan_id;
  perform app.plan_class(v_plan.class_id);
  if v_item.done_at is null then
    raise exception 'Evvel movzunu "kecildi" isareleyin.' using errcode = '22023';
  end if;

  --  Hovuz VALIDEYNDEDIR (101).  Alt movzunun oz slug-u nisan ucundur.
  select coalesce(par.id, t.id), coalesce(par.name, t.name), t.slug, t.name
    into v_tid, v_topic, v_slug, v_leaf
    from public.topics t
    left join public.topics par on par.id = t.parent_id
   where t.id = v_item.topic_id;

  --  Nisanli sual yeterlidirse DERS testi, deyilse kohne kimi FESIL.
  if v_slug is not null and v_slug <> '' then
    v_n := app.ders_sual_sayi(v_tid, v_slug);
    v_ders := v_n >= app.ders_min();
  end if;

  if v_ders then
    --  Ders testi qisadir; hovuzdan cox istemirik ki generator
    --  «N sual tapildi» xetasi atmasin.
    v_count := least(app.ders_test_count(), v_n);
    v_rule := jsonb_build_object(
      'pool', 'all',
      'count', v_count,
      'subject', (select slug from public.subjects where id = v_plan.subject_id),
      'level',   (select code from public.levels   where id = v_plan.level_id),
      'topics',  jsonb_build_array(v_tid::text),
      'tags',    jsonb_build_array(app.ders_tag(v_slug)));
    v_res := public.rpc_generate_test(v_rule, v_leaf || ' — yoxlama');
  else
    v_count := p_count;
    v_rule := jsonb_build_object(
      'pool', 'all',
      'count', v_count,
      'subject', (select slug from public.subjects where id = v_plan.subject_id),
      'level',   (select code from public.levels   where id = v_plan.level_id),
      'topics',  jsonb_build_array(v_tid::text));
    v_res := public.rpc_generate_test(v_rule, v_topic || ' — yoxlama');
  end if;

  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  update public.class_plan_items set test_id = v_test where id = p_item_id;

  --  'scope' interfeys ucundur: setir «dərs testi» yoxsa «fəsil
  --  testi» yigildigini yaza bilsin - muellim ne aldigini bilsin.
  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count',
                            'scope', case when v_ders then 'ders' else 'fesil' end,
                            'pool',  v_n);
end $$;

-- ------------------------------------------------- huquq
revoke all on function public.rpc_plan_test(uuid, int) from public, anon;
grant execute on function public.rpc_plan_test(uuid, int) to authenticated;
