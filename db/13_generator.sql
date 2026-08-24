-- =====================================================================
--  13_generator.sql : AGILLI TEST GENERATORU
--
--  12_bank_rpc.sql-den SONRA isledilir.  Tekrar isledile biler.
--
--  Icinde:
--    1. Tekrar sualin qarsisi (hash + oxsarliq)
--    2. rpc_generate_test    - suzgecle test yigir
--    3. rpc_regenerate_test  - eyni qayda ile yeniden yigir
--    4. rpc_test_preview     - muellim kagizi gorur (cavablarla)
--
--  OLCULMUS QERAR:  trigram oxsarligi MENANI yox, cumle QELIBINI olcur.
--    '6 × 7 nece eder?' ~ '7 × 6 nece eder?'  = 1.00  (eyni sual)
--    '6 × 7 nece eder?' ~ '6 × 8 nece eder?'  = 0.75  (FERQLI sual)
--    '6 × 7 nece eder?' ~ '9 × 4 nece eder?'  = 0.56  (TAMAM ferqli)
--  Ona gore orta hedd (0.6-0.8) YARAMAZ - qanuni suallari atardi.
--  Yalniz >= 0.95 etibarlidir: yerdeyismis tekrari tutur, ferqli suala
--  toxunmur.  Riyaziyyatda esl tekrar siqnali ise DUZGUN CAVABDIR.
-- =====================================================================
create extension if not exists pg_trgm;

-- =====================================================================
--  1. TEKRARIN QARSISI
-- =====================================================================
--  Normalizasiya: kicik herf, boşluqlar birlesir, son durgu isaresi
--  dusur, vurma isareleri birlesir.  Bundan ARTIQ normalizasiya
--  etmirik - yalan uygunluq riski baslayir.
create or replace function app.norm_body(p text) returns text
language sql immutable set search_path = public, extensions, pg_temp as $$
  select btrim(regexp_replace(
           regexp_replace(
             translate(lower(coalesce(p,'')), '×⋅*', 'xxx'),
             '\s+', ' ', 'g'),
           '[?.!:;,\s]+$', ''))
$$;

create or replace function app.body_hash(p text) returns text
language sql immutable set search_path = public, extensions, pg_temp as $$
  select encode(digest(app.norm_body(p), 'sha256'), 'hex')
$$;

alter table public.questions add column if not exists body_hash text;

update public.questions set body_hash = app.body_hash(body) where body_hash is null;

--  Hesab DAXILINDE unikal.  Qlobal deyil: iki muellimin eyni sualı
--  olmasi normaldir, onlar bir-birinin hovuzunda deyil.
create unique index if not exists questions_dup_account
  on public.questions(account_id, body_hash)
  where account_id is not null and status <> 'archived';

create index if not exists idx_q_body_trgm
  on public.questions using gin (body extensions.gin_trgm_ops);

--  Yazanda hash ozu qurulur
create or replace function app.questions_set_hash() returns trigger
language plpgsql set search_path = public, extensions, pg_temp as $$
begin new.body_hash := app.body_hash(new.body); return new; end $$;

drop trigger if exists trg_questions_hash on public.questions;
create trigger trg_questions_hash before insert or update of body on public.questions
  for each row execute function app.questions_set_hash();

-- =====================================================================
--  OXSAR SUAL AXTARISI  -  yazma aninda XEBERDARLIQ, bloklama deyil
-- =====================================================================
create or replace function public.rpc_bank_similar(
  p_body    text,
  p_exclude uuid default null,
  p_account uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_acc uuid := app.pick_account(p_account);
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', q.id, 'body', q.body,
             'exact', q.body_hash = app.body_hash(p_body),
             'score', round(similarity(q.body, p_body)::numeric, 2))
           order by similarity(q.body, p_body) desc)
      from public.questions q
     where q.account_id = v_acc
       and q.status <> 'archived'
       and (p_exclude is null or q.id <> p_exclude)
       and (q.body_hash = app.body_hash(p_body)
            or similarity(q.body, p_body) >= 0.95)
     limit 5
  ), '[]'::jsonb);
end $$;

-- =====================================================================
--  2. TEST YIGMAQ
--     p_rule:
--       { "subject":"riyaziyyat", "level":"3",
--         "topics":["<uuid>", ...], "difficulty":[1,2],
--         "quarter":1, "month":9, "tags":[...],
--         "pool":"mine|platform|all", "count":20 }
-- =====================================================================
create or replace function app.generate_pick(p_rule jsonb, p_account uuid)
returns uuid[]
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_want   int  := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
  v_pool   text := coalesce(p_rule->>'pool', 'all');
  v_paid   boolean := app.has_active_subscription(p_account);
  v_out    uuid[] := '{}';
  v_bodies text[] := '{}';
  v_ans    text[] := '{}';
  v_ansmax int;
  r        record;
  v_dup    boolean;
  i        int;
begin
  --  Platformanin hovuzu abune telebidir; oz suallarin her zaman acıq
  if v_pool in ('platform','all') and not v_paid then
    v_pool := 'mine';
  end if;

  --  Eyni cavab en coxu bu qeder tekrarlana biler (20 sualda 3)
  v_ansmax := greatest(2, ceil(v_want / 7.0)::int);

  for r in
    --  Movzular arasinda BERABER: her movzudan novbe ile goturulur,
    --  eks halda tesaduf 20 sualin 19-unu bir movzudan gotura biler.
    select z.id, z.body, z.answer
      from (
        select q.id, q.body,
               coalesce((select string_agg(lower(btrim(o.body)), '|' order by o.body)
                           from public.question_options o
                          where o.question_id = q.id and o.is_correct), '') as answer,
               row_number() over (partition by q.topic_id order by random()) as rn_topic,
               random() as rnd
          from public.questions q
          join public.subjects s on s.id = q.subject_id
          left join public.levels l on l.id = q.level_id
         where q.status = 'published'
           and (case v_pool
                  when 'mine'     then q.account_id = p_account
                  when 'platform' then q.owner_type = 'platform'
                  else q.account_id = p_account or q.owner_type = 'platform' end)
           and (p_rule->>'subject' is null or s.slug = p_rule->>'subject')
           and (p_rule->>'level'   is null or l.code = p_rule->>'level')
           and (p_rule->'topics' is null or jsonb_array_length(p_rule->'topics') = 0
                or q.topic_id::text in (select jsonb_array_elements_text(p_rule->'topics')))
           and (p_rule->'difficulty' is null or jsonb_array_length(p_rule->'difficulty') = 0
                or q.difficulty::text in (select jsonb_array_elements_text(p_rule->'difficulty')))
           and (p_rule->>'quarter' is null or q.quarter = (p_rule->>'quarter')::int)
           and (p_rule->>'month'   is null or q.month   = (p_rule->>'month')::int)
           and (p_rule->'tags' is null or jsonb_array_length(p_rule->'tags') = 0
                or q.tags @> (select array_agg(x)
                                from jsonb_array_elements_text(p_rule->'tags') x))
           --  Sualsiz test olmaz
           and exists (select 1 from public.question_options o
                        where o.question_id = q.id and o.is_correct)
      ) z
     order by z.rn_topic, z.rnd
  loop
    exit when array_length(v_out, 1) >= v_want;

    --  Acgoz suzgec: yerdeyismis tekrari at (>= 0.95).
    --  Bu hedd OLCULEREK secilib - asagisi qanuni suallari atirdi.
    v_dup := false;
    if array_length(v_bodies, 1) is not null then
      for i in 1 .. array_length(v_bodies, 1) loop
        if similarity(v_bodies[i], r.body) >= 0.95 then
          v_dup := true; exit;
        end if;
      end loop;
    end if;

    --  Eyni duzgun cavab hedden cox tekrarlanmasin - riyaziyyatda
    --  esl tekrar siqnali metn yox, CAVABDIR.
    if not v_dup and r.answer <> '' then
      if (select count(*) from unnest(v_ans) a where a = r.answer) >= v_ansmax then
        v_dup := true;
      end if;
    end if;

    if not v_dup then
      v_out    := v_out    || r.id;
      v_bodies := v_bodies || r.body;
      v_ans    := v_ans    || r.answer;
    end if;
  end loop;

  return v_out;
end $$;

-- ------------------------------------------------- hovuzun sayı
create or replace function public.rpc_generate_preview(
  p_rule jsonb, p_account uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_ids  uuid[];
  v_want int := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
begin
  v_ids := app.generate_pick(p_rule, v_acc);
  return jsonb_build_object(
    'want',  v_want,
    'found', coalesce(array_length(v_ids, 1), 0),
    'enough', coalesce(array_length(v_ids, 1), 0) >= v_want,
    'paid',  app.has_active_subscription(v_acc));
end $$;

-- ------------------------------------------------------- testi yigmaq
create or replace function public.rpc_generate_test(
  p_rule    jsonb,
  p_title   text,
  p_test_id uuid default null,       -- verilibse YENIDEN yigilir
  p_account uuid default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid := app.pick_account(p_account);
  v_want  int  := least(greatest(coalesce((p_rule->>'count')::int, 10), 1), 100);
  v_pool  text := coalesce(p_rule->>'pool', 'all');
  v_ids   uuid[];
  v_test  uuid := p_test_id;
  v_prog  uuid;
  v_subj  uuid;
  v_lev   uuid;
  v_done  int;
  i       int;
begin
  if v_pool in ('platform','all') and not app.has_active_subscription(v_acc) then
    raise exception 'Platformanin sual bankindan test yigmaq abune paketine daxildir. Oz suallarinizdan yiga bilersiniz.'
      using errcode = '42501';
  end if;

  -- ---- yeniden yigmaq: islenmis test DEYISMIR
  if v_test is not null then
    if not app.can_manage_test(v_test) then
      raise exception 'Bu test sizin deyil.' using errcode = '42501';
    end if;
    select count(*) into v_done from public.attempts
     where test_id = v_test and status = 'submitted';
    if v_done > 0 then
      raise exception 'Bu testi % sagird artiq isleyib - yenilemek olmaz. Yeni variant yaradin.',
        v_done using errcode = '42501';
    end if;
  end if;

  -- ---- suallari sec
  v_ids := app.generate_pick(p_rule, v_acc);
  if coalesce(array_length(v_ids, 1), 0) < v_want then
    raise exception 'Bu suzgecle yalniz % ferqli sual tapildi (% istenilir). Suzgeci genislendirin ve ya sual sayini azaldin.',
      coalesce(array_length(v_ids, 1), 0), v_want using errcode = '22023';
  end if;

  -- ---- fenn / sinif
  select id into v_subj from public.subjects where slug = p_rule->>'subject';
  if v_subj is null then
    select q.subject_id into v_subj from public.questions q where q.id = v_ids[1];
  end if;
  select l.id into v_lev from public.levels l where l.code = p_rule->>'level' order by l.sort limit 1;
  select p.id into v_prog from public.programs p where p.slug = 'ibtidai';

  -- ---- test
  if v_test is null then
    insert into public.tests
      (owner_type, owner_id, program_id, subject_id, level_id, title,
       status, gen_rule, shuffle_questions, shuffle_options)
    values ('educator', v_uid, v_prog, v_subj, v_lev,
            coalesce(nullif(btrim(p_title), ''), 'Avtomatik test'),
            'published', p_rule, true, true)
    returning id into v_test;
  else
    update public.tests
       set title = coalesce(nullif(btrim(p_title), ''), title),
           subject_id = v_subj, level_id = v_lev, gen_rule = p_rule
     where id = v_test;
    delete from public.test_questions where test_id = v_test;
  end if;

  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.test_questions (test_id, question_id, ord)
    values (v_test, v_ids[i], i);
  end loop;

  return jsonb_build_object('test_id', v_test, 'count', array_length(v_ids, 1),
                            'regenerated', p_test_id is not null);
end $$;

-- --------------------------------------------- eyni qayda ile yeniden
create or replace function public.rpc_regenerate_test(p_test_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_rule jsonb; v_title text;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  select gen_rule, title into v_rule, v_title from public.tests where id = p_test_id;
  if v_rule is null then
    raise exception 'Bu test el ile qurulub - avtomatik yenilenmir.' using errcode = '22023';
  end if;
  return public.rpc_generate_test(v_rule, v_title, p_test_id);
end $$;

-- =====================================================================
--  4. KAGIZA BAXIS  -  muellim cavablarla gorur (cap ucun de bu)
-- =====================================================================
create or replace function public.rpc_test_preview(p_test_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v jsonb;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
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
               'body', q.body,
               'kind', q.kind,
               'difficulty', q.difficulty,
               'topic', tp.name,
               'explanation', q.explanation,
               'mine', q.owner_type = 'educator',
               'options', coalesce((
                  select jsonb_agg(jsonb_build_object(
                           'body', o.body, 'correct', o.is_correct) order by o.ord)
                    from public.question_options o
                   where o.question_id = q.id), '[]'::jsonb)
             ) order by tq.ord)
        from public.test_questions tq
        join public.questions q on q.id = tq.question_id
        left join public.topics tp on tp.id = q.topic_id
       where tq.test_id = t.id), '[]'::jsonb)
  ) into v
   from public.tests t
   join public.subjects s on s.id = t.subject_id
   left join public.levels l on l.id = t.level_id
  where t.id = p_test_id;
  return v;
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_bank_similar(text, uuid, uuid)          from public;
revoke all on function public.rpc_generate_preview(jsonb, uuid)           from public;
revoke all on function public.rpc_generate_test(jsonb, text, uuid, uuid)  from public;
revoke all on function public.rpc_regenerate_test(uuid)                   from public;
revoke all on function public.rpc_test_preview(uuid)                      from public;

grant execute on function public.rpc_bank_similar(text, uuid, uuid)         to authenticated;
grant execute on function public.rpc_generate_preview(jsonb, uuid)          to authenticated;
grant execute on function public.rpc_generate_test(jsonb, text, uuid, uuid) to authenticated;
grant execute on function public.rpc_regenerate_test(uuid)                  to authenticated;
grant execute on function public.rpc_test_preview(uuid)                     to authenticated;

do $$
declare bad text;
begin
  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_bank_similar(text, uuid, uuid)',
    'public.rpc_generate_preview(jsonb, uuid)',
    'public.rpc_generate_test(jsonb, text, uuid, uuid)',
    'public.rpc_regenerate_test(uuid)',
    'public.rpc_test_preview(uuid)']) f
   where not has_function_privilege('authenticated', f, 'EXECUTE');
  if bad is not null then
    raise exception 'muellim bu funksiyalari cagira bilmir: %', bad;
  end if;
  if has_function_privilege('anon', 'public.rpc_test_preview(uuid)', 'EXECUTE') then
    raise exception 'anon kagiza baxa bilir - cavab acari sizir';
  end if;
  raise notice 'Generator quruldu.';
end $$;
