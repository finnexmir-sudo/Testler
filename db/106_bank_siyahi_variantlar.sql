-- =====================================================================
--  106_bank_siyahi_variantlar.sql — siyahida da variantlar gorunsun
--
--  NIYE
--  Bank ekraninda movzunun ustune basanda numune suallar variantlari
--  ve isarelenmis duz cavabi ile cixir.  "Bu movzunun butun suallarini
--  gor" duymesine basanda ise SIYAHIYA kecilir - orada yalniz sualin
--  basligi var, variantlar yox olur.  Muellim eyni suala baxir, amma
--  cavablari artiq gormur: genislendirdiyi halda AZ melumat alir.
--  Sebeb sadedir - rpc_bank_list variantlari hec vaxt qaytarmirdi.
--
--  NIYE SADECE ELAVE ETMEK OLMAZDI
--  rpc_bank_list ABUNE TELEB ETMIR: pulsuz qeydiyyatdan kecen istenilen
--  adam sehife-sehife (100-luk) butun platforma bankini oxuya biler.
--  Bu gun o, yalniz sual METNLERINI alir.  Variantlari serbest versek,
--  duz cavablarla birlikde butun bank pulsuz yuklenerdi - eynen
--  rpc_bank_samples-in 3-luk heddi ile bagladigi qapi.
--  12_bank_rpc.sql-deki "cavab acari siyahida gorunmur" yoxlamasi
--  mehz bunu qoruyurdu ve HAQLI idi.
--
--  NE EDIRIK
--  Variantlar SERTLE gelir:
--    - sual muellimin OZUNUNDURSA (owner_type = 'educator'), ve ya
--    - hesabin aktiv abunesi varsa, ve ya
--    - cagiran admindirse.
--  Qalan hallarda 'options' bos massivdir - siyahi eynen kohnesi kimi
--  isleyir, ekran da variant qutusunu gostermir.
--
--  Abuneci onsuz da cavablari gorur: movzudan test yigib veraqi acir.
--  Yeni sizma yolu acilmir - sadece movcud huquq rahat gosterilir.
--
--  Fayl 12_bank_rpc.sql-den PROQRAMLA cixarilib.
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
  --  Duz cavablari gostermek olarmi?  Abune / admin qapisi.
  v_keys  boolean := app.has_active_subscription(v_acc) or app.admin_ok();
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

-- --------------------------------------------------------------- huquq
revoke all on function public.rpc_bank_list(jsonb, int, int, uuid) from public, anon;
grant execute on function public.rpc_bank_list(jsonb, int, int, uuid) to authenticated;

do $x$
begin
  if has_function_privilege('anon',
      'public.rpc_bank_list(jsonb, int, int, uuid)', 'EXECUTE') then
    raise exception 'anon bank siyahisini cagira bilir';
  end if;
  raise notice 'Bank siyahisi variantlari da qaytarir.';
end $x$;
