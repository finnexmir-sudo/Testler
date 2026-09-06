-- =====================================================================
--  132_parametrik_sual.sql : parametrik (sablon) suallar (yol xeritesi 22.a)
--
--  "245 + 138" sualini bir defe yazirsan, her sagird basqa reqemler
--  gorur - cavab ezberlenmir, bank "sonsuz" olur.
--
--  Sablon nece isleyir:
--    questions.params = {"vars":{"a":[100,999],"b":[100,999]},"cond":"a>b"}
--    body / variant / izah metninde  {a}  {b}  {a+b}  {a*b-1}  kimi yer
--    tutucular.  Mötərizədəki ifadə yalniz reqem ve + - * / % ( ) . ola
--    biler (deyisenler evvelce reqemle EVEZ olunur, sonra yoxlanir) -
--    execute-e yalniz bu simvollar catir, SQL inyeksiyasi mumkun deyil.
--
--  Qiymetler CEHD baslayanda bir defe secilir (attempts.params =
--  {sual_id: {a:245,b:138}}) ve cehdin sonuna qeder deyismir: davam
--  etdirilen cehd eyni reqemleri gorur, hesabat / cavab vereqi /
--  netice eyni qiymetlerle render olunur.  Ballama DEYISMIR: variantin
--  is_correct-i sablon seviyyesindedir ({a+b} hemise dogrudur), sagird
--  yene variant ID-si gonderir.  Yazili (text) sualda dogru cavab da
--  render olunub muqayise edilir.
--
--  Sehv defteri ve muellimin test vereqi her acilisda TEZE qiymet
--  gosterir (mesq ucun mehz bu lazimdir; vereq bir variantdir).
-- =====================================================================

alter table public.questions add column if not exists params jsonb;
alter table public.attempts  add column if not exists params jsonb;

-- ---------------------------------------------------------------------
--  Reqem formati: 383, 3.5, -12  (sonda sifirlar yox)
-- ---------------------------------------------------------------------
create or replace function app.pq_num(p numeric) returns text
language sql immutable as $$
  select case when p = trunc(p) then trunc(p)::bigint::text
              else rtrim(rtrim(p::text, '0'), '.') end
$$;

-- ---------------------------------------------------------------------
--  Deyisenleri reqemle evez edir.  Tek reqemlere ".0" elave olunur ki,
--  7/2 tam bolme (3) yox, 3.5 versin.
-- ---------------------------------------------------------------------
create or replace function app.pq_subst(p_expr text, p_vars jsonb) returns text
language plpgsql immutable as $$
declare
  e text := lower(btrim(coalesce(p_expr, '')));
  k text;
begin
  if e = '' or length(e) > 200 then
    raise exception 'Şablon ifadəsi boş və ya çox uzundur.' using errcode = '22023';
  end if;
  for k in select key from jsonb_each_text(coalesce(p_vars, '{}'::jsonb)) loop
    if k !~ '^[a-h]$' or (p_vars->>k) !~ '^-?[0-9]{1,9}$' then
      raise exception 'Şablon dəyişəni yanlışdır: %', k using errcode = '22023';
    end if;
    e := regexp_replace(e, '\m' || k || '\M', '(' || (p_vars->>k) || ')', 'g');
  end loop;
  return regexp_replace(e, '(?<![0-9.])([0-9]+)(?![0-9.])', '\1.0', 'g');
end $$;

create or replace function app.pq_eval(p_expr text, p_vars jsonb) returns text
language plpgsql volatile as $$
declare
  e text := app.pq_subst(p_expr, p_vars);
  v numeric;
begin
  if e !~ '^[0-9+\-*/%(). ]+$' then
    raise exception 'Şablon ifadəsi yanlışdır: {%} — yalnız dəyişən, rəqəm və + - * / %% ( ) olar.', p_expr
      using errcode = '22023';
  end if;
  execute 'select (' || e || ')::numeric' into v;
  return app.pq_num(v);
end $$;

create or replace function app.pq_cond(p_cond text, p_vars jsonb) returns boolean
language plpgsql volatile as $$
declare
  e text := app.pq_subst(p_cond, p_vars);
  v boolean;
begin
  if e !~ '^(?:[0-9+\-*/%(). <>=!]+|and|or)+$' then
    raise exception 'Şablon şərti yanlışdır: % — məsələn a>b, a%%b=0, a<>b and b>1', p_cond
      using errcode = '22023';
  end if;
  execute 'select (' || e || ')' into v;
  return coalesce(v, false);
end $$;

-- ---------------------------------------------------------------------
--  Metni render edir: {ifade} -> qiymet.  p_vars null = adi sual,
--  metn olduğu kimi qayidir (adi sualda { } ola biler).
-- ---------------------------------------------------------------------
create or replace function app.pq_render(p_tpl text, p_vars jsonb) returns text
language plpgsql volatile as $$
declare
  o text := p_tpl;
  m text[];
begin
  if p_tpl is null or p_vars is null or position('{' in p_tpl) = 0 then
    return p_tpl;
  end if;
  for m in select regexp_matches(p_tpl, '\{([^{}]+)\}', 'g') loop
    o := replace(o, '{' || m[1] || '}', app.pq_eval(m[1], p_vars));
  end loop;
  return o;
end $$;

-- ---------------------------------------------------------------------
--  Parametr tesviri yoxlanir ve normallasdirilir.
--  {"vars":{"a":[100,999],"b":[1,9]},"cond":"a>b"}
-- ---------------------------------------------------------------------
create or replace function app.pq_spec(p jsonb) returns jsonb
language plpgsql immutable as $$
declare
  v  jsonb := '{}'::jsonb;
  k  text;
  lo numeric; hi numeric;
  c  text;
  n  int := 0;
  t  text;
  probe jsonb := '{}'::jsonb;
begin
  if p is null or jsonb_typeof(p) <> 'object' or jsonb_typeof(p->'vars') <> 'object' then
    raise exception 'Şablon parametrləri yanlışdır: a = 100..999 kimi yazın.' using errcode = '22023';
  end if;
  for k in select jsonb_object_keys(p->'vars') loop
    n := n + 1;
    if k !~ '^[a-h]$' then
      raise exception 'Dəyişən adı a–h arası bir hərf olmalıdır: %', k using errcode = '22023';
    end if;
    if jsonb_typeof(p->'vars'->k) <> 'array' or jsonb_array_length(p->'vars'->k) <> 2
       or jsonb_typeof(p->'vars'->k->0) <> 'number' or jsonb_typeof(p->'vars'->k->1) <> 'number' then
      raise exception 'Dəyişən % üçün aralıq lazımdır: % = 1..9', k, k using errcode = '22023';
    end if;
    lo := (p->'vars'->k->>0)::numeric; hi := (p->'vars'->k->>1)::numeric;
    if lo <> trunc(lo) or hi <> trunc(hi) or lo > hi or abs(lo) > 1000000 or abs(hi) > 1000000 then
      raise exception 'Dəyişən % aralığı yanlışdır (tam ədəd, kiçik..böyük, ən çox 1 000 000).', k
        using errcode = '22023';
    end if;
    v := v || jsonb_build_object(k, jsonb_build_array(lo::bigint, hi::bigint));
    probe := probe || jsonb_build_object(k, 1);
  end loop;
  if n = 0 then
    raise exception 'Ən azı bir dəyişən lazımdır: a = 100..999' using errcode = '22023';
  end if;
  if n > 6 then
    raise exception 'Ən çoxu altı dəyişən ola bilər.' using errcode = '22023';
  end if;
  c := nullif(btrim(coalesce(p->>'cond', '')), '');
  if c is not null then
    if length(c) > 120 then
      raise exception 'Şərt çox uzundur.' using errcode = '22023';
    end if;
    perform app.pq_cond(c, probe);   -- sintaksis yoxlanisi
  end if;
  return jsonb_strip_nulls(jsonb_build_object('vars', v, 'cond', c));
end $$;

-- ---------------------------------------------------------------------
--  Bir cehd ucun qiymetler.  Sert odenene ve (sual verilibse) butun
--  variantlar FERQLI cixana qeder 40 cehd; strict = tapilmasa xeta
--  (yadda saxlayanda), yoxsa son qiymetler (test dayanmasin).
-- ---------------------------------------------------------------------
create or replace function app.pq_seed(p_params jsonb, p_qid uuid default null,
                                       p_strict boolean default false) returns jsonb
language plpgsql volatile as $$
declare
  vars jsonb;
  k    text;
  lo bigint; hi bigint;
  i    int;
  ok   boolean;
begin
  if p_params is null then return null; end if;
  for i in 1..40 loop
    vars := '{}'::jsonb;
    for k in select jsonb_object_keys(p_params->'vars') loop
      lo := (p_params->'vars'->k->>0)::bigint;
      hi := (p_params->'vars'->k->>1)::bigint;
      vars := vars || jsonb_build_object(k, lo + floor(random() * (hi - lo + 1))::bigint);
    end loop;
    begin
      ok := true;
      if p_params ? 'cond' then
        ok := app.pq_cond(p_params->>'cond', vars);
      end if;
      if ok and p_qid is not null then
        select count(distinct app.pq_render(o.body, vars)) = count(*) into ok
          from public.question_options o where o.question_id = p_qid;
      end if;
    exception when others then
      ok := false;     -- meselen sifira bolme - basqa qiymet yoxlanir
    end;
    if ok then return vars; end if;
  end loop;
  if p_strict then
    raise exception 'Şablon üçün uyğun qiymət tapılmadı: şərt çox sərtdir və ya variantlar eyni çıxır.'
      using errcode = '22023';
  end if;
  return vars;
end $$;

-- ---------------------------------------------------------------------
--  Yadda saxlamazdan evvel tam yoxlama: yer tutucu var, her ifade
--  hesablanir, variantlar sistematik ust-uste dusmur.
-- ---------------------------------------------------------------------
create or replace function app.pq_check(p_params jsonb, p_body text, p_options jsonb,
                                        p_expl text default '') returns void
language plpgsql volatile as $$
declare
  vars  jsonb;
  i     int;
  bad   int := 0;
  n_all int;
  n_dis int;
  ex    text;
begin
  if position('{' in coalesce(p_body, '')) = 0 and not exists (
       select 1 from jsonb_array_elements(coalesce(p_options, '[]'::jsonb)) o
        where position('{' in coalesce(o->>'body', '')) > 0) then
    raise exception 'Şablonda {a} kimi yer tutucu yoxdur — sualda və ya variantda yazın.'
      using errcode = '22023';
  end if;
  for i in 1..12 loop
    vars := app.pq_seed(p_params, null, true);
    perform app.pq_render(p_body, vars);
    perform app.pq_render(coalesce(p_expl, ''), vars);
    select count(*), count(distinct app.pq_render(o->>'body', vars))
      into n_all, n_dis
      from jsonb_array_elements(coalesce(p_options, '[]'::jsonb)) o;
    if n_dis < n_all then
      bad := bad + 1;
      ex := (select string_agg(k || '=' || (vars->>k), ', ') from jsonb_object_keys(vars) k);
    end if;
  end loop;
  if bad > 4 then
    raise exception 'Variantlar tez-tez eyni çıxır (məsələn %): ifadələri fərqləndirin və ya şərt qoyun.', ex
      using errcode = '22023';
  end if;
end $$;

revoke all on function app.pq_num(numeric)                    from public, anon, authenticated;
revoke all on function app.pq_subst(text, jsonb)              from public, anon, authenticated;
revoke all on function app.pq_eval(text, jsonb)               from public, anon, authenticated;
revoke all on function app.pq_cond(text, jsonb)               from public, anon, authenticated;
revoke all on function app.pq_render(text, jsonb)             from public, anon, authenticated;
revoke all on function app.pq_spec(jsonb)                     from public, anon, authenticated;
revoke all on function app.pq_seed(jsonb, uuid, boolean)      from public, anon, authenticated;
revoke all on function app.pq_check(jsonb, text, jsonb, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Redaktorda "Numune goster": bir qiymet desti ile render.
-- ---------------------------------------------------------------------
create or replace function public.rpc_pq_preview(p_params jsonb, p_body text, p_options jsonb,
                                                 p_explanation text default '')
returns jsonb
language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare
  spec jsonb;
  vars jsonb;
begin
  if auth.uid() is null then
    raise exception 'Giris lazimdir.' using errcode = '42501';
  end if;
  spec := app.pq_spec(p_params);
  perform app.pq_check(spec, p_body, p_options, p_explanation);
  vars := app.pq_seed(spec, null, true);
  return jsonb_build_object(
    'vars', vars,
    'body', app.pq_render(p_body, vars),
    'explanation', app.pq_render(coalesce(p_explanation, ''), vars),
    'options', coalesce((
      select jsonb_agg(jsonb_build_object(
               'body', app.pq_render(o->>'body', vars),
               'correct', coalesce((o->>'correct')::boolean, false)))
        from jsonb_array_elements(coalesce(p_options, '[]'::jsonb)) o), '[]'::jsonb));
end $$;
revoke all on function public.rpc_pq_preview(jsonb, text, jsonb, text) from public, anon;
grant execute on function public.rpc_pq_preview(jsonb, text, jsonb, text) to authenticated;

-- ---------------------------------------------------------------------
--  rpc_bank_save_question: + p_params.  Kohne imza silinir - iki imza
--  PostgREST-de "best candidate" xetasi verir.
-- ---------------------------------------------------------------------
drop function if exists public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid);
create or replace function public.rpc_bank_save_question(
  p_id          uuid,           -- null = yeni sual
  p_subject     text,           -- fennin slug-i
  p_body        text,
  p_options     jsonb,
  p_kind        text default 'single',
  p_level       text default null,   -- sinif kodu: '3'
  p_topic       uuid default null,
  p_explanation text default '',
  p_difficulty  int  default 2,
  p_quarter     int  default null,
  p_month       int  default null,
  p_tags        text[] default '{}',
  p_account     uuid default null,
  p_params      jsonb default null)  -- 132: sablon parametrleri
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid     uuid := auth.uid();
  v_acc     uuid;
  v_subject uuid;
  v_level   uuid;
  v_kind    question_kind;
  v_id      uuid;
  v_n_ok    int;
  v_n_all   int;
  v_used    int;
  v_limit   int;
  v_params  jsonb;
begin
  v_acc := app.pick_account(p_account);

  -- ---- fenn ve sinif
  select id into v_subject from public.subjects where slug = p_subject;
  if v_subject is null then
    raise exception 'Fenn tapilmadi: %', p_subject using errcode = '22023';
  end if;
  if p_level is not null then
    select l.id into v_level from public.levels l
     where l.code = p_level order by l.sort limit 1;
  end if;

  -- ---- movzu bu fennin olmalidir
  if p_topic is not null and not exists (
       select 1 from public.topics t where t.id = p_topic and t.subject_id = v_subject) then
    raise exception 'Movzu bu fenne aid deyil.' using errcode = '22023';
  end if;

  -- ---- metn ve hedler
  if p_body is null or length(btrim(p_body)) = 0 then
    raise exception 'Sualin metni bos ola bilmez.' using errcode = '22023';
  end if;
  if coalesce(p_difficulty, 2) not between 1 and 3 then
    raise exception 'Cetinlik 1, 2 ve ya 3 olmalidir.' using errcode = '22023';
  end if;

  begin v_kind := coalesce(p_kind, 'single')::question_kind;
  exception when invalid_text_representation then
    raise exception 'Sual tipi yanlisdir: %', p_kind using errcode = '22023';
  end;

  -- ---- variantlar
  v_n_all := coalesce(jsonb_array_length(p_options), 0);
  select count(*) into v_n_ok from jsonb_array_elements(coalesce(p_options,'[]'::jsonb)) o
   where coalesce((o->>'correct')::boolean, false)
      or v_kind = 'text';

  if v_kind = 'text' then
    if v_n_all < 1 then
      raise exception 'Metn sualinda en azi bir duzgun cavab yazilmalidir.' using errcode = '22023';
    end if;
  else
    if v_n_all < 2 then
      raise exception 'En azi iki variant lazimdir.' using errcode = '22023';
    end if;
    if v_n_all > 8 then
      raise exception 'En coxu sekkiz variant ola biler.' using errcode = '22023';
    end if;
    if v_kind = 'single' and v_n_ok <> 1 then
      raise exception 'Bir duzgun cavab secilmelidir (secilen: %).', v_n_ok using errcode = '22023';
    end if;
    if v_kind = 'multi' and v_n_ok < 1 then
      raise exception 'En azi bir duzgun cavab secilmelidir.' using errcode = '22023';
    end if;
  end if;

  if exists (select 1 from jsonb_array_elements(coalesce(p_options,'[]'::jsonb)) o
              where length(btrim(coalesce(o->>'body',''))) = 0) then
    raise exception 'Bos variant ola bilmez.' using errcode = '22023';
  end if;

  -- ---- 132: sablon - parametrler ve butun ifadeler yoxlanir
  if p_params is not null and jsonb_typeof(p_params) <> 'null' then
    v_params := app.pq_spec(p_params);
    perform app.pq_check(v_params, p_body, p_options, p_explanation);
  end if;

  -- ---- yeni sual: paket heddi
  if p_id is null then
    v_used  := app.account_question_count(v_acc);
    v_limit := app.account_question_limit(v_acc);
    if v_used >= v_limit then
      raise exception 'Paketin sual limiti dolub (% / %). Paketi genislendirin.',
        v_used, v_limit using errcode = '42501';
    end if;

    insert into public.questions
      (owner_type, owner_id, account_id, subject_id, level_id, topic_id, tags,
       quarter, month, kind, body, explanation, difficulty, status, created_by, params)
    values
      ('educator', v_uid, v_acc, v_subject, v_level, p_topic, coalesce(p_tags,'{}'),
       p_quarter, p_month, v_kind, btrim(p_body), coalesce(p_explanation,''),
       coalesce(p_difficulty,2), 'published', v_uid, v_params)
    returning id into v_id;
  else
    if not app.can_manage_question(p_id) then
      raise exception 'Bu sual sizin deyil.' using errcode = '42501';
    end if;
    update public.questions
       set subject_id = v_subject, level_id = v_level, topic_id = p_topic,
           tags = coalesce(p_tags,'{}'), quarter = p_quarter, month = p_month,
           kind = v_kind, body = btrim(p_body),
           explanation = coalesce(p_explanation,''),
           difficulty = coalesce(p_difficulty,2),
           params = v_params
     where id = p_id
    returning id into v_id;
    if v_id is null then
      raise exception 'Sual tapilmadi.' using errcode = '22023';
    end if;
    delete from public.question_options where question_id = v_id;
  end if;

  insert into public.question_options (question_id, ord, body, is_correct)
  select v_id, o.ord, btrim(o.val->>'body'),
         case when v_kind = 'text' then true
              else coalesce((o.val->>'correct')::boolean, false) end
    from jsonb_array_elements(coalesce(p_options,'[]'::jsonb))
         with ordinality as o(val, ord);

  return jsonb_build_object('id', v_id, 'created', p_id is null);
end $$;
revoke all on function public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid, jsonb) from public, anon;
grant execute on function public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid, jsonb) to authenticated;

-- rpc_bank_question: params da gelir
create or replace function public.rpc_bank_question(p_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v jsonb;
begin
  if not app.can_manage_question(p_id) then
    raise exception 'Bu sual sizin deyil.' using errcode = '42501';
  end if;

  select jsonb_build_object(
           'id', q.id, 'body', q.body, 'kind', q.kind,
           'params', q.params,
           'explanation', q.explanation, 'difficulty', q.difficulty,
           'quarter', q.quarter, 'month', q.month, 'tags', to_jsonb(q.tags),
           'subject', s.slug, 'subject_name', s.name,
           'level', l.code, 'level_name', l.name,
           'topic_id', q.topic_id, 'topic', tp.name,
           'status', q.status,
           'used_in', (select count(*) from public.test_questions tq
                        where tq.question_id = q.id),
           'answered', (select count(*) from public.attempt_answers aa
                         where aa.question_id = q.id),
           'options', coalesce((
              select jsonb_agg(jsonb_build_object(
                       'body', o.body, 'correct', o.is_correct) order by o.ord)
                from public.question_options o where o.question_id = q.id), '[]'::jsonb)
         ) into v
    from public.questions q
    join public.subjects s on s.id = q.subject_id
    left join public.levels l on l.id = q.level_id
    left join public.topics tp on tp.id = q.topic_id
   where q.id = p_id;
  return v;
end $$;

-- rpc_bank_list: 'tpl' nisani (sablon sual)
create or replace function public.rpc_bank_list(
  p_filters jsonb default '{}'::jsonb,
  p_limit   int   default 30,
  p_offset  int   default 0,
  p_account uuid  default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_acc   uuid := app.pick_account(p_account);
  v_pool  text := coalesce(p_filters->>'pool', 'all');
  v_lim   int  := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_off   int  := greatest(coalesce(p_offset, 0), 0);
  v_total int;
  v_rows  jsonb;
  --  Duz cavablari gostermek olarmi?  Abune / admin qapisi.
  v_keys  boolean := app.has_active_subscription(v_acc) or app.admin_ok();
begin
  with f as (
    select q.id, q.body, q.params, q.kind, q.difficulty, q.quarter, q.month, q.tags,
           q.status, q.owner_type, q.created_at,
           s.name as subject, l.name as level_name, tp.name as topic
      from public.questions q
      join public.subjects s on s.id = q.subject_id
      left join public.levels l on l.id = q.level_id
      left join public.topics tp on tp.id = q.topic_id
     where q.status = coalesce(p_filters->>'status', 'published')::content_status
       -- hovuz
       and (case v_pool
              when 'mine'     then q.account_id = v_acc
              when 'platform' then q.owner_type = 'platform'
              else q.account_id = v_acc or q.owner_type = 'platform' end)
       -- fenn / sinif
       and (p_filters->>'subject' is null
            or s.slug = p_filters->>'subject')
       and (p_filters->>'level' is null
            or l.code = p_filters->>'level')
       -- movzular
       and (p_filters->'topics' is null
            or jsonb_array_length(p_filters->'topics') = 0
            or q.topic_id::text in (
                 select jsonb_array_elements_text(p_filters->'topics')))
       -- cetinlik
       and (p_filters->'difficulty' is null
            or jsonb_array_length(p_filters->'difficulty') = 0
            or q.difficulty::text in (
                 select jsonb_array_elements_text(p_filters->'difficulty')))
       -- dovr
       and (p_filters->>'quarter' is null or q.quarter = (p_filters->>'quarter')::int)
       and (p_filters->>'month'   is null or q.month   = (p_filters->>'month')::int)
       -- etiketler: hamisi olmalidir
       and (p_filters->'tags' is null
            or jsonb_array_length(p_filters->'tags') = 0
            or q.tags @> (select array_agg(x)
                            from jsonb_array_elements_text(p_filters->'tags') x))
       -- azad axtaris
       and (p_filters->>'q' is null
            or q.body ilike '%' || btrim(p_filters->>'q') || '%')
  )
  select count(*)::int,
         coalesce((select jsonb_agg(jsonb_build_object(
                    'id', z.id, 'body', z.body, 'kind', z.kind,
                    'tpl', z.params is not null,
                    'difficulty', z.difficulty, 'quarter', z.quarter,
                    'month', z.month, 'tags', to_jsonb(z.tags),
                    'subject', z.subject, 'level', z.level_name, 'topic', z.topic,
                    'mine', z.owner_type = 'educator',
                    --  YENI: variantlar da gelir.  Siyahi "movzunun
                    --  butun suallari" ekranidir; numunede variantlar
                    --  gorunub siyahida yox olurdu - muellim eyni
                    --  suala baxir, amma cavablari gormurdu.
                    --  Oz sualin hemise aciqdir; ozgesinin cavabi
                    --  yalniz abune (ve ya admin) ucun.
                    'options', case when v_keys or z.owner_type = 'educator'
                       then coalesce((
                         select jsonb_agg(jsonb_build_object(
                                  'body', o.body, 'correct', o.is_correct)
                                order by o.ord)
                           from public.question_options o
                          where o.question_id = z.id), '[]'::jsonb)
                       else '[]'::jsonb end
                    ) order by z.rn)
                    from (select f.*, row_number() over (
                            order by f.created_at desc, f.id) rn
                            from f) z
                   where z.rn > v_off and z.rn <= v_off + v_lim), '[]'::jsonb)
    into v_total, v_rows
    from f;

  return jsonb_build_object(
    'total', v_total, 'limit', v_lim, 'offset', v_off, 'items', v_rows);
end $$;

-- ---------------------------------------------------------------------
--  rpc_start_attempt (esas: 123): qiymetler secilir, metn render olunur
-- ---------------------------------------------------------------------
create or replace function public.rpc_start_attempt(p_token text, p_test_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_class   uuid;
  v_account uuid;
  v_test    public.tests%rowtype;
  v_asg     public.assignments%rowtype;
  v_free    boolean;
  v_limit   int;
  v_done    int;
  v_attempt uuid;
  v_params  jsonb;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select class_id, account_id into v_class, v_account
    from public.students where id = v_student;

  select * into v_test from public.tests where id = p_test_id and status = 'published';
  if not found then
    raise exception 'Test tapilmadi.' using errcode = '22023';
  end if;

  -- ACIQ teyinat varsa onun qaydalari isleyir.
  -- Vaxti bitmis teyinat testi bloklamir: test yeniden serbest mesq
  -- hovuzuna qayidir (rpc_student_tests de onu orada gosterir).
  --  28-den beri eyni test hem butun qrupa, hem de ayrica bir sagirde
  --  teyin oluna bilir - iki ACIQ setir.  Yalniz bu sagirde aid olanlar
  --  sayilir (basqasinin ferdi teyinati yox); ferdi olan ustundur.
  select a.* into v_asg from public.assignments a
   where a.class_id = v_class and a.test_id = p_test_id
     and (a.student_id is null or a.student_id = v_student)
     and app.assignment_open(a.*)
   order by a.student_id nulls last limit 1;

  if v_asg.id is not null then
    v_limit := v_asg.max_attempts;
  else
    -- Acıq teyinat yoxdur: serbest mesq yolu
    select free_practice into v_free from public.classes where id = v_class;
    if v_test.owner_type <> 'platform' then
      -- Muellimin oz testi yalniz teyinatla acilir
      if exists (select 1 from public.assignments a
                  where a.class_id = v_class and a.test_id = p_test_id) then
        raise exception 'Bu tapsirigin vaxti bitib.' using errcode = '42501';
      end if;
      raise exception 'Bu test sizin qrup ucun teyin olunmayib.' using errcode = '42501';
    end if;
    if not coalesce(v_free, true) then
      if exists (select 1 from public.assignments a
                  where a.class_id = v_class and a.test_id = p_test_id) then
        raise exception 'Bu tapsirigin vaxti bitib.' using errcode = '42501';
      end if;
      raise exception 'Muelliminiz serbest mesqi baglayib.' using errcode = '42501';
    end if;
    v_limit := v_test.max_attempts;
  end if;

  -- Odenis heddi
  if not v_test.is_free and not app.has_active_subscription(v_account) then
    raise exception 'Bu test abune paketine daxildir.' using errcode = '42501';
  end if;

  -- Cehd limiti
  if v_limit > 0 then
    select count(*) into v_done from public.attempts
     where student_id = v_student and test_id = p_test_id and status = 'submitted';
    if v_done >= v_limit then
      raise exception 'Bu testi artiq % defe islemisiniz.', v_done using errcode = '42501';
    end if;
  end if;

  -- Yarimciq qalmis cehd varsa onu davam etdiririk
  select id into v_attempt from public.attempts
   where student_id = v_student and test_id = p_test_id and status = 'in_progress'
   order by started_at desc limit 1;

  if v_attempt is null then
    insert into public.attempts (student_id, test_id, class_id)
    values (v_student, p_test_id, v_class)
    returning id into v_attempt;
  end if;

  --  132: sablon suallara BU cehd ucun qiymetler.  Bir defe secilir,
  --  davam etdirilen cehd eyni reqemleri gorur.  Evvel baslamis cehdde
  --  catismayan sual varsa yalniz o elave olunur.
  select params into v_params from public.attempts where id = v_attempt;
  select coalesce(v_params, '{}'::jsonb)
         || coalesce(jsonb_object_agg(q.id::text, app.pq_seed(q.params, q.id)), '{}'::jsonb)
    into v_params
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
   where tq.test_id = p_test_id and q.params is not null
     and not (coalesce(v_params, '{}'::jsonb) ? q.id::text);
  if v_params <> '{}'::jsonb then
    update public.attempts set params = v_params where id = v_attempt;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt,
    'test', jsonb_build_object(
              'id', v_test.id, 'title', v_test.title,
              'time_limit_sec', v_test.time_limit_sec,
              'pass_percent',   v_test.pass_percent),
    'questions', coalesce((
      select jsonb_agg(qq order by qq->>'ord')
      from (
        select jsonb_build_object(
                 'id',   q.id,
                 'ord',  case when v_test.shuffle_questions
                              then lpad((row_number() over (order by md5(q.id::text || v_attempt::text)))::text, 4, '0')
                              else lpad(tq.ord::text, 4, '0') end,
                 'kind', q.kind,
                 'body', app.pq_render(q.body, v_params->(q.id::text)),
                 'media_url', q.media_url,
                 'options', coalesce((
                    select jsonb_agg(jsonb_build_object('id', o.id,
                                        'body', app.pq_render(o.body, v_params->(q.id::text)))
                             order by case when v_test.shuffle_options
                                           then md5(o.id::text || v_attempt::text)
                                           else lpad(o.ord::text, 4, '0') end)
                      from public.question_options o
                     where o.question_id = q.id), '[]'::jsonb)
               ) as qq
          from public.test_questions tq
          join public.questions q on q.id = tq.question_id
         where tq.test_id = p_test_id
      ) z), '[]'::jsonb)
  );
end $$;

-- ---------------------------------------------------------------------
--  rpc_submit_attempt (esas: 128): render olunmus metn ve cavablar
-- ---------------------------------------------------------------------
create or replace function public.rpc_submit_attempt(
  p_token text, p_attempt_id uuid, p_answers jsonb)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_att     public.attempts%rowtype;
  v_test    public.tests%rowtype;
  v_score   numeric(7,2) := 0;
  v_max     numeric(7,2) := 0;
  v_limit   int;
  r         record;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;

  select * into v_att from public.attempts
   where id = p_attempt_id and student_id = v_student;
  if not found then
    raise exception 'Cehd tapilmadi.' using errcode = '22023';
  end if;
  if v_att.status <> 'in_progress' then
    raise exception 'Bu cehd artiq baglanib.' using errcode = '42501';
  end if;

  select * into v_test from public.tests where id = v_att.test_id;
  -- Cehd limiti teyinatdan gelir; teyinat yoxdursa testin ozunden
  --  Qrup + ferdi teyinat eyni vaxtda acıq ola biler - "more than one
  --  row returned by a subquery" vermesin: ferdi olan ustundur, bir setir.
  select coalesce((select a.max_attempts from public.assignments a
                    where a.class_id = v_att.class_id and a.test_id = v_att.test_id
                      and (a.student_id is null or a.student_id = v_student)
                      and app.assignment_open(a.*)
                    order by a.student_id nulls last limit 1),
                  v_test.max_attempts) into v_limit;

  -- Her sual uzre serverde yoxlanis
  for r in
    select q.id, q.kind, coalesce(tq.points, q.points) as points, q.topic_id,
           --  132: sagirdin GORDUYU (render olunmus) metn yazilir
           app.pq_render(q.body, v_att.params->(q.id::text)) as q_body,
           app.pq_render(q.explanation, v_att.params->(q.id::text)) as q_expl,
           coalesce((select array_agg(o.id order by o.id) from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_ids,
           coalesce((select array_agg(lower(btrim(app.pq_render(o.body, v_att.params->(q.id::text)))))
                       from public.question_options o
                      where o.question_id = q.id and o.is_correct), '{}') as correct_texts,
           (select a from jsonb_array_elements(coalesce(p_answers,'[]'::jsonb)) a
             where a->>'q' = q.id::text limit 1) as ans
      from public.test_questions tq
      join public.questions q on q.id = tq.question_id
     where tq.test_id = v_att.test_id
  loop
    declare
      v_sel  uuid[] := '{}';
      v_txt  text;
      v_ok   boolean := false;   -- null = cavab verilmeyib
      v_sec  int;                -- sualda kecirilen saniye (tetbiq gonderir)
      v_sure boolean;            -- "eminem" (true) / "emin deyilem" (false)
    begin
      v_max := v_max + r.points;

      if r.ans is not null then
        --  128: cavab terzi.  Olmasa null - kohne tetbiq de isleyir.
        if (r.ans->>'s') ~ '^[0-9]+$' then
          v_sec := least(3600, (r.ans->>'s')::int);
        end if;
        if r.ans ? 'c' and jsonb_typeof(r.ans->'c') = 'boolean' then
          v_sure := (r.ans->>'c')::boolean;
        end if;
        if r.ans ? 'o' then
          select coalesce(array_agg((e)::uuid order by (e)::uuid), '{}') into v_sel
            from jsonb_array_elements_text(r.ans->'o') e
           where e ~ '^[0-9a-fA-F-]{36}$';
        end if;
        v_txt := nullif(btrim(coalesce(r.ans->>'t','')), '');
      end if;

      if r.ans is null or (array_length(v_sel,1) is null and v_txt is null) then
        --  Sagird bu suala HEC TOXUNMAYIB.  "Sehv cavab verdi" ile eyni
        --  sey deyil - hesabatda ayrilsin deye null yazilir.  Bal yene 0.
        v_ok := null;
      elsif r.kind = 'text' then
        v_ok := v_txt is not null and lower(v_txt) = any (r.correct_texts);
      else
        v_ok := array_length(r.correct_ids,1) is not null
                and v_sel @> r.correct_ids and r.correct_ids @> v_sel;
      end if;

      if v_ok is true then v_score := v_score + r.points; end if;

      --  Sualin metni de yazilir: muellim sonradan sual redakte etse,
      --  bu hesabat hele de sagirdin GORDUYU sual gosterecek.
      insert into public.attempt_answers
        (attempt_id, question_id, topic_id, selected_option_ids, text_answer,
         is_correct, points, question_body, question_explanation, seconds, sure)
      values
        (p_attempt_id, r.id, r.topic_id, v_sel, v_txt, v_ok,
         case when v_ok is true then r.points else 0 end, r.q_body, r.q_expl,
         v_sec, v_sure)
      on conflict (attempt_id, question_id) do update
        set selected_option_ids = excluded.selected_option_ids,
            text_answer         = excluded.text_answer,
            is_correct          = excluded.is_correct,
            points              = excluded.points,
            question_body        = excluded.question_body,
            question_explanation = excluded.question_explanation,
            seconds             = excluded.seconds,
            sure                = excluded.sure,
            answered_at         = now();
    end;
  end loop;

  update public.attempts
     set status       = 'submitted',
         finished_at  = now(),
         duration_sec = greatest(0, extract(epoch from (now() - started_at))::int),
         score        = v_score,
         max_score    = v_max,
         percent      = case when v_max > 0 then round(v_score * 100 / v_max, 2) else 0 end
   where id = p_attempt_id
   returning * into v_att;

  return jsonb_build_object(
    'attempt_id',   v_att.id,
    'score',        v_att.score,
    'max_score',    v_att.max_score,
    'percent',      v_att.percent,
    'passed',       v_att.percent >= v_test.pass_percent,
    'duration_sec', v_att.duration_sec,
    'diagnostic',   v_test.is_diagnostic,
    'topics',       app.diag_student_map(v_att.id, v_test.is_diagnostic),
    -- "Bir de cehd ede bilersen" yazisi ucun: hele cehd qalibmi?
    'can_retry',    v_limit = 0 or
                    (select count(*) from public.attempts a2
                      where a2.student_id = v_student and a2.test_id = v_att.test_id
                        and a2.status = 'submitted') < v_limit,
    'questions', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      --  "picked" - sagirdin sectiyi variantIN METNI (testi yazarken
      --  artiq gorub - yeni sizinti yoxdur).  Hansi variantin DOGRU
      --  oldugu (is_correct) heç vaxt qayıtmır - 116_sagird_tam_netice.sql-
      --  deki eyni qayda burada da isleyir.
      select jsonb_agg(x order by tq.ord)
        from public.attempt_answers aa
        join public.test_questions tq
          on tq.test_id = v_att.test_id and tq.question_id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'explanation', aa.question_explanation,
                   'correct',     aa.is_correct,
                   --  Metn tipli sual variant deyil, yazi qebul edir -
                   --  onda selected_option_ids bosdur, text_answer dolur.
                   'picked',      case
                     when aa.text_answer is not null and aa.text_answer <> ''
                       then jsonb_build_array(aa.text_answer)
                     else coalesce((
                       select jsonb_agg(app.pq_render(o.body, v_att.params->(aa.question_id::text)) order by o.ord)
                         from public.question_options o
                        where o.id = any(aa.selected_option_ids)), '[]'::jsonb)
                   end
                 ) as x
        ) q
       where aa.attempt_id = v_att.id), '[]'::jsonb)
  );
end $$;

-- rpc_test_result (esas: 118): secilmis variantlar cehdin qiymetleri ile
create or replace function public.rpc_test_result(p_token text, p_test_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_att  public.attempts%rowtype;
  v_test public.tests%rowtype;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;

  select * into v_att from public.attempts
   where student_id = v_student and test_id = p_test_id and status = 'submitted'
   order by percent desc, finished_at desc
   limit 1;
  if not found then
    raise exception 'Bu testin neticesi tapilmadi.' using errcode = '22023';
  end if;

  select * into v_test from public.tests where id = p_test_id;

  return jsonb_build_object(
    'attempt_id',   v_att.id,
    'score',        v_att.score,
    'max_score',    v_att.max_score,
    'percent',      v_att.percent,
    'passed',       v_att.percent >= v_test.pass_percent,
    'duration_sec', v_att.duration_sec,
    'finished_at',  v_att.finished_at,
    'can_retry',    false,   -- baxis rejimi: cehd bitib
    'diagnostic',   v_test.is_diagnostic,
    'topics',       app.diag_student_map(v_att.id, v_test.is_diagnostic),
    'test', jsonb_build_object('id', v_test.id, 'title', v_test.title,
                               'pass_percent', v_test.pass_percent),
    'questions', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      --  "picked" - sagirdin sectiyi variantIN METNI, o cavabi
      --  testi yazarken artiq gorub - burda YENI heç nə sızmır.
      --  Hansi variantin DOGRU oldugu (is_correct) heç vaxt qayıtmır.
      select jsonb_agg(x order by tq.ord)
        from public.attempt_answers aa
        join public.test_questions tq
          on tq.test_id = v_att.test_id and tq.question_id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'explanation', aa.question_explanation,
                   'correct',     aa.is_correct,
                   --  Metn tipli sual variant deyil, yazi qebul edir -
                   --  onda selected_option_ids bosdur, text_answer dolur.
                   'picked',      case
                     when aa.text_answer is not null and aa.text_answer <> ''
                       then jsonb_build_array(aa.text_answer)
                     else coalesce((
                       select jsonb_agg(app.pq_render(o.body, v_att.params->(aa.question_id::text)) order by o.ord)
                         from public.question_options o
                        where o.id = any(aa.selected_option_ids)), '[]'::jsonb)
                   end
                 ) as x
        ) q
       where aa.attempt_id = v_att.id), '[]'::jsonb)
  );
end $$;

-- rpc_attempt_sheet (esas: 27): cavab vereqi cehdin qiymetleri ile
create or replace function public.rpc_attempt_sheet(p_attempt_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_a  public.attempts%rowtype;
  v_st public.students%rowtype;
begin
  select * into v_a from public.attempts
   where id = p_attempt_id and status = 'submitted';
  if not found then
    raise exception 'Cehd tapilmadi.' using errcode = '22023';
  end if;
  if not app.can_read_student(v_a.student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = v_a.student_id;
  if not app.has_active_subscription(v_st.account_id) then
    raise exception 'Cavab vereqi abune paketine daxildir.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'test',    (select t.title from public.tests t where t.id = v_a.test_id),
    'at',      v_a.finished_at,
    'percent', round(v_a.percent, 0),
    'items', coalesce((
      select jsonb_agg(x order by (x->>'ord')::int, x->>'body')
      from (
        select jsonb_build_object(
                 'ord',  coalesce(tq.ord, 999),
                 'body', aa.question_body,
                 'explanation', aa.question_explanation,
                 'ok',   aa.is_correct is true,
                 'chosen', coalesce((
                    select string_agg(app.pq_render(o.body, v_a.params->(aa.question_id::text)), ' · ' order by o.ord)
                      from public.question_options o
                     where o.id = any(aa.selected_option_ids)),
                    nullif(btrim(coalesce(aa.text_answer, '')), ''), '—'),
                 'correct', coalesce((
                    select string_agg(app.pq_render(o.body, v_a.params->(aa.question_id::text)), ' · ' order by o.ord)
                      from public.question_options o
                     where o.question_id = aa.question_id and o.is_correct), '')
               ) as x
          from public.attempt_answers aa
          left join public.test_questions tq
                 on tq.test_id = v_a.test_id and tq.question_id = aa.question_id
         where aa.attempt_id = p_attempt_id
      ) z), '[]'::jsonb));
end $$;

-- rpc_student_mistakes (esas: 129): sablon her mesqde teze reqemlerle
create or replace function public.rpc_student_mistakes(p_token text)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_st uuid := app.session_student(p_token);
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  return jsonb_build_object(
    'open',   (select count(*) from public.mistakes where student_id = v_st and status = 'open'),
    'review', (select count(*) from public.mistakes where student_id = v_st and status = 'review'),
    'closed', (select count(*) from public.mistakes where student_id = v_st and status = 'closed'),
    'due',    (select count(*) from public.mistakes
                where student_id = v_st and status <> 'closed' and next_at <= now()),
    --  mesq ucun 10 sual: evvel acıq, sonra tekrar; DUZ VARIANT GETMIR
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'qid', q.id, 'body', app.pq_render(q.body, pv.v), 'kind', q.kind, 'media_url', q.media_url,
               'topic', t.name, 'status', m.status, 'wrong_n', m.wrong_n,
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object('id', o.id, 'body', app.pq_render(o.body, pv.v)) order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
             order by (m.status = 'open') desc, m.next_at, m.last_at)
        from (select * from public.mistakes
               where student_id = v_st and status <> 'closed' and next_at <= now()
               order by (status = 'open') desc, next_at, last_at limit 10) m
        join public.questions q on q.id = m.question_id and q.status = 'published'
        left join public.topics t on t.id = q.topic_id
        --  132: sablon sual mesqde her defe TEZE reqemlerle
        cross join lateral (select app.pq_seed(q.params, q.id) as v) pv), '[]'::jsonb));
end $$;

-- rpc_test_preview (esas: 13): vereqde numune qiymetler, 'tpl' nisani
create or replace function public.rpc_test_preview(p_test_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v jsonb;
  v_acc    uuid;
  v_class  uuid;
  v_wrongs text[] := null;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;

  --  Test sehv-cutlesdirme ile yigilibsa, veraqda "sehve benzer"
  --  nisani gosterilir.  Qrup yeniden yoxlanir - qayda kohne ola biler.
  select nullif(t.gen_rule->>'class', '')::uuid into v_class
    from public.tests t where t.id = p_test_id;
  if v_class is not null then
    v_acc := app.pick_account(null);
    if exists (select 1 from public.classes c
                where c.id = v_class and c.account_id = v_acc) then
      select array_agg(w.b) into v_wrongs from (
        select distinct app.norm_body(coalesce(nullif(aa.question_body, ''), q.body)) b
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = 'submitted'
          join public.students st on st.id = a.student_id and st.class_id = v_class
          left join public.questions q on q.id = aa.question_id
         where aa.is_correct = false
         limit 300) w;
    end if;
  end if;

  select jsonb_build_object(
    'id', t.id, 'title', t.title, 'gen_rule', t.gen_rule,
    'subject', s.name, 'level', l.name,
    'done', (select count(*) from public.attempts a
              where a.test_id = t.id and a.status = 'submitted'),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'ord',  tq.ord,
               'id',   q.id,
               'body', app.pq_render(q.body, pv.v),
               'tpl',  q.params is not null,
               'kind', q.kind,
               'difficulty', q.difficulty,
               'topic', tp.name,
               'explanation', app.pq_render(q.explanation, pv.v),
               'mine', q.owner_type = 'educator',
               'remedial', (v_wrongs is not null and exists (
                  select 1 from unnest(v_wrongs) w
                   where similarity(app.norm_body(q.body), w) >= app.rem_similarity())),
               'options', coalesce((
                  select jsonb_agg(jsonb_build_object(
                           'body', app.pq_render(o.body, pv.v), 'correct', o.is_correct) order by o.ord)
                    from public.question_options o
                   where o.question_id = q.id), '[]'::jsonb)
             ) order by tq.ord)
        from public.test_questions tq
        join public.questions q on q.id = tq.question_id
        left join public.topics tp on tp.id = q.topic_id
        --  132: vereq bir variantdir - her acilisda teze qiymet
        cross join lateral (select app.pq_seed(q.params, q.id) as v) pv
       where tq.test_id = t.id), '[]'::jsonb)
  ) into v
   from public.tests t
   join public.subjects s on s.id = t.subject_id
   left join public.levels l on l.id = t.level_id
  where t.id = p_test_id;
  return v;
end $$;

