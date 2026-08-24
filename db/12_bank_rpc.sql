-- =====================================================================
--  12_bank_rpc.sql : SUAL BANKI - yazmaq, redakte, suzgecli axtaris
--
--  11_sual_banki.sql-den SONRA isledilir.
--  Tekrar isledile biler.
--
--  Qaydalar:
--    · Muellim YALNIZ oz hesabinin sualini yazir/deyisir/silir
--    · Variantlar sualla BIR emeliyyatda yazilir (yarimciq sual qalmasin)
--    · Islenmis sual SILINMIR - arxivlenir
--    · Paketden asili sual limiti bazada tetbiq olunur
-- =====================================================================

-- ------------------------------------------------------- on sert
--  Bu fayl 11_sual_banki.sql-in qurdugu sutunlar uzerinde isleyir.
--  O islemeyibse ASAGIDA qaranliq xetalar cixir - ona gore burda,
--  daha bir sey deyismeden, aydin desin.
do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name='questions'
                    and column_name='account_id') then
    raise exception E'ONCE 11_sual_banki.sql isledilmelidir.\n'
      'Sira: 11_sual_banki.sql -> 12_bank_rpc.sql -> 13_generator.sql';
  end if;
end $$;

-- ------------------------------------------------------------ hedler
--  Pulsuz hesab bankı sonsuz doldura bilmez.
create or replace function app.free_question_limit() returns int
language sql immutable as $$ select 150 $$;

create or replace function app.account_question_limit(p_account uuid) returns int
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select coalesce(
    (select case when p.max_students is null then 2147483647
                 else greatest(p.max_students * 100, 2500) end
       from public.subscriptions s
       join public.plans p on p.id = s.plan_id
      where s.account_id = p_account
        and s.status in ('trialing','active')
        and (s.current_period_end is null or s.current_period_end > now())
      order by coalesce(p.max_students, 2147483647) desc
      limit 1),
    app.free_question_limit()
  )
$$;

create or replace function app.account_question_count(p_account uuid) returns int
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select count(*)::int from public.questions
   where account_id = p_account and status <> 'archived'
$$;

-- ----------------------------------------------- muellimin aktiv hesabi
--  Muellimin bir nece hesabi ola biler; sual hansina yazilir?
--  Verilmisse yoxlanilir, verilmeyibse birinci uzvluk goturulur.
create or replace function app.pick_account(p_account uuid) returns uuid
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_uid uuid := auth.uid(); v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if p_account is not null then
    if not app.is_account_member(p_account) then
      raise exception 'Bu hesaba giris huququnuz yoxdur.' using errcode = '42501';
    end if;
    return p_account;
  end if;
  select account_id into v_acc from public.account_members
   where user_id = v_uid order by account_id limit 1;
  if v_acc is null then
    raise exception 'Once hesab yaradin.' using errcode = '42501';
  end if;
  return v_acc;
end $$;

-- =====================================================================
--  SUAL YAZMAQ / REDAKTE ETMEK
--  p_options formati:
--    [{"body":"42","correct":true}, {"body":"36"}, ...]
--  kind = 'text' olanda variantlar duzgun cavab siyahisidir
--  (hamisi correct sayilir).
-- =====================================================================
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
  p_account     uuid default null)
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
       quarter, month, kind, body, explanation, difficulty, status, created_by)
    values
      ('educator', v_uid, v_acc, v_subject, v_level, p_topic, coalesce(p_tags,'{}'),
       p_quarter, p_month, v_kind, btrim(p_body), coalesce(p_explanation,''),
       coalesce(p_difficulty,2), 'published', v_uid)
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
           difficulty = coalesce(p_difficulty,2)
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

-- =====================================================================
--  SUALI SILMEK  -  islenmisse arxivlenir
-- =====================================================================
create or replace function public.rpc_bank_delete_question(p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_used boolean;
begin
  if not app.can_manage_question(p_id) then
    raise exception 'Bu sual sizin deyil.' using errcode = '42501';
  end if;

  v_used := exists (select 1 from public.test_questions where question_id = p_id)
         or exists (select 1 from public.attempt_answers where question_id = p_id);

  if v_used then
    -- Silmek olmaz: sagirdlerin neticeleri buna baglidir
    update public.questions set status = 'archived' where id = p_id;
    return jsonb_build_object('ok', true, 'archived', true);
  end if;

  delete from public.question_options where question_id = p_id;
  delete from public.questions where id = p_id;
  return jsonb_build_object('ok', true, 'archived', false);
end $$;

-- =====================================================================
--  BIR SUAL  -  redakte formasi ucun, variantlarla birlikde
-- =====================================================================
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

-- =====================================================================
--  SUZGECLI AXTARIS
--    p_filters:
--      { "subject":"riyaziyyat", "level":"3", "topics":["<uuid>"],
--        "difficulty":[1,2], "quarter":1, "month":9,
--        "tags":["meselə"], "q":"vurma", "pool":"mine|platform|all",
--        "status":"published" }
--    Generator da eyni suzgecden istifade edecek.
-- =====================================================================
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
begin
  with f as (
    select q.id, q.body, q.kind, q.difficulty, q.quarter, q.month, q.tags,
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
                    'difficulty', z.difficulty, 'quarter', z.quarter,
                    'month', z.month, 'tags', to_jsonb(z.tags),
                    'subject', z.subject, 'level', z.level_name, 'topic', z.topic,
                    'mine', z.owner_type = 'educator') order by z.rn)
                    from (select f.*, row_number() over (
                            order by f.created_at desc, f.id) rn
                            from f) z
                   where z.rn > v_off and z.rn <= v_off + v_lim), '[]'::jsonb)
    into v_total, v_rows
    from f;

  return jsonb_build_object(
    'total', v_total, 'limit', v_lim, 'offset', v_off, 'items', v_rows);
end $$;

-- =====================================================================
--  SAYGAC  -  generatorun "bu suzgecle N sual var" gostericisi
-- =====================================================================
create or replace function public.rpc_bank_count(
  p_filters jsonb default '{}'::jsonb,
  p_account uuid  default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v jsonb;
begin
  v := public.rpc_bank_list(p_filters, 1, 0, p_account);
  return jsonb_build_object('total', v->'total');
end $$;

-- =====================================================================
--  SUZGEC SIYAHILARI  -  fenn, sinif, movzu, etiket
-- =====================================================================
create or replace function public.rpc_bank_facets(
  p_subject text default null,
  p_level   text default null,
  p_account uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_acc uuid := app.pick_account(p_account);
begin
  return jsonb_build_object(
    'subjects', coalesce((
      select jsonb_agg(jsonb_build_object('slug', s.slug, 'name', s.name) order by s.sort)
        from public.subjects s), '[]'::jsonb),
    'levels', coalesce((
      select jsonb_agg(distinct jsonb_build_object('code', l.code, 'name', l.name))
        from public.levels l
        join public.programs p on p.id = l.program_id and p.slug = 'ibtidai'), '[]'::jsonb),
    'topics', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.id, 'name', t.name) order by t.sort, t.name)
        from public.topics t
        join public.subjects s on s.id = t.subject_id
       where (p_subject is null or s.slug = p_subject)
         and (p_level is null or t.level_id is null
              or t.level_id in (select id from public.levels where code = p_level))
      ), '[]'::jsonb),
    'tags', coalesce((
      select jsonb_agg(distinct tg)
        from public.questions q, unnest(q.tags) tg
       where q.account_id = v_acc or q.owner_type = 'platform'), '[]'::jsonb),
    'usage', jsonb_build_object(
      'used',  app.account_question_count(v_acc),
      'limit', app.account_question_limit(v_acc))
  );
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid) from public;
revoke all on function public.rpc_bank_delete_question(uuid)        from public;
revoke all on function public.rpc_bank_question(uuid)               from public;
revoke all on function public.rpc_bank_list(jsonb, int, int, uuid)  from public;
revoke all on function public.rpc_bank_count(jsonb, uuid)           from public;
revoke all on function public.rpc_bank_facets(text, text, uuid)     from public;

grant execute on function public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid) to authenticated;
grant execute on function public.rpc_bank_delete_question(uuid)       to authenticated;
grant execute on function public.rpc_bank_question(uuid)              to authenticated;
grant execute on function public.rpc_bank_list(jsonb, int, int, uuid) to authenticated;
grant execute on function public.rpc_bank_count(jsonb, uuid)          to authenticated;
grant execute on function public.rpc_bank_facets(text, text, uuid)    to authenticated;

do $$
declare bad text;
begin
  select string_agg(f, ', ') into bad from unnest(array[
    'public.rpc_bank_save_question(uuid, text, text, jsonb, text, text, uuid, text, int, int, int, text[], uuid)',
    'public.rpc_bank_delete_question(uuid)',
    'public.rpc_bank_question(uuid)',
    'public.rpc_bank_list(jsonb, int, int, uuid)',
    'public.rpc_bank_count(jsonb, uuid)',
    'public.rpc_bank_facets(text, text, uuid)']) f
   where not has_function_privilege('authenticated', f, 'EXECUTE');
  if bad is not null then
    raise exception 'muellim bu funksiyalari cagira bilmir: %', bad;
  end if;
  -- Sagird bank funksiyalarina EL VURA BILMEMELIDIR
  if has_function_privilege('anon',
       'public.rpc_bank_list(jsonb, int, int, uuid)', 'EXECUTE') then
    raise exception 'anon sual bankini oxuya bilir - cavab acari sizir';
  end if;
  raise notice 'Sual banki RPC-leri authenticated ucun acildi.';
end $$;
