-- =====================================================================
--  907 : BANK AXTARISI MOVZU ADINA DA BAXIR (2026-10-01)
--
--  SIKAYET (real muellim, Ibtidai Az. dili 4-cu sinif): bankda
--  «frazeoloji birlesme» axtarib hec ne tapmadi.  SEBEB: rpc_bank_list
--  yalniz sualin METNINE baxirdi (q.body ilike).  Movzunun adi sual
--  metninde kecmirse - movzu var, amma axtarisla tapilmir.
--
--  NE DEYISIR: azad axtaris indi 4 yerde baxir -
--     1. sualin metni (evvelki kimi)
--     2. movzunun adi          (topics.name)
--     3. movzunun fesil adi    (topics.parent_id -> name)
--     4. alt movzunun adi      ('ders:<slug>' nisani -> o yarpagin adi)
--  Muellim movzu adini yazanda o movzunun BUTUN suallari cixir.
--
--  Yalniz q sertine toxunulur; qalan govde 188-den eynen goturulub
--  (proqramla kocurulub, el ile yox - itmis setir riski olmasin).
--  Bos / bosluq q indi «suzgec yoxdur» sayilir (evvel '%%' idi - ayni netice).
--  Geri almaq: 188_sual_sekli.sql-deki rpc_bank_list-i yeniden isletmek.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.rpc_bank_list(p_filters jsonb DEFAULT '{}'::jsonb, p_limit integer DEFAULT 30, p_offset integer DEFAULT 0, p_account uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
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
    select q.id, q.body, q.media_url, q.params, q.kind, q.difficulty, q.quarter, q.month, q.tags,
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
       and (nullif(btrim(p_filters->>'q'), '') is null
            or q.body ilike '%' || btrim(p_filters->>'q') || '%'
            --  907: movzunun adi - sual metninde sozu olmasa da movzu tapilsin
            or tp.name ilike '%' || btrim(p_filters->>'q') || '%'
            --  ... fesilin adi (movzu fesilin altindadirsa)
            or exists (select 1 from public.topics pt
                        where pt.id = tp.parent_id
                          and pt.name ilike '%' || btrim(p_filters->>'q') || '%')
            --  ... alt movzunun adi: 'ders:<slug>' nisani -> o yarpagin adi
            or exists (select 1
                         from unnest(q.tags) tg
                         join public.topics lt
                           on lt.subject_id = q.subject_id
                          and lt.slug = substr(tg, 6)
                        where tg like 'ders:%'
                          and lt.name ilike '%' || btrim(p_filters->>'q') || '%'))
  )
  select count(*)::int,
         coalesce((select jsonb_agg(jsonb_build_object(
                    'id', z.id, 'body', z.body, 'media_url', z.media_url, 'kind', z.kind,
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
end $function$;

revoke all on function public.rpc_bank_list(jsonb, int, int, uuid) from public, anon;
grant execute on function public.rpc_bank_list(jsonb, int, int, uuid) to authenticated;
