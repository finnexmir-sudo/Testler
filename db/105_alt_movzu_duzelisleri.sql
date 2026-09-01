-- =====================================================================
--  105_alt_movzu_duzelisleri.sql : ALT MOVZULARIN IKI ACIQ YERI
--
--  ONCE db/12_bank_rpc.sql, db/25_ders_plani.sql ve
--  db/101_ders_plani_alt.sql isledilmelidir.
--
--  db/101 alt movzulari getirdi, amma iki yerde nezere alinmamisdi.
--  Ikisi de db/74 (riyaziyyat 8) ile ARTIQ CANLI idi - db/83/84
--  onlari sadece gorunen etdi.
--
--  ============  1. QARISIQ TEST  ============
--
--  XETA
--  db/101 ders planini iki pilleli etdi: fesil -> alt movzu.  Plan
--  YARPAQLARDAN dolur, yeni bendler alt movzulardir.  Alt movzuya
--  SUAL BAGLANMIR - hovuz valideyndedir.  101 bunu tek movzuluq
--  rpc_plan_test-de nezere aldi, amma rpc_plan_test_multi ("bir nece
--  kecilmis movzudan birge test") kohne halinda qaldi: bend id-lerini
--  oldugu kimi generatora verirdi.
--
--  Netice: alt movzusu olan hansisa qrupda muellim iki fesil secib
--  "birge test" deyende generator
--      "Bu suzgecle yalniz 0 ferqli sual tapildi"
--  deyirdi.  Yeni bir fenn/sinif elave etmek lazim deyildi - riyaziyyat
--  8-de (db/74) artiq bele idi, db/82 ile 5-11 de qosuldu.
--
--  DUZELIS: bendin movzusu alt movzudursa valideynin id-si gonderilir
--  (coalesce(parent_id, id)), tekrarlar distinct ile atilir.
--
--  Baska hec ne deyismir - imza, huquqlar, tapsiriq axini eynidir.
--
--  ============  2. SUAL FORMASINDA MOVZU SIYAHISI  ============
--
--  XETA
--  rpc_bank_facets movzulari qaytaranda alt movzulari da verirdi.
--  Bank ekrani p_pool gonderir, ona gore orada "suali var" serti
--  onlari atirdi.  Sual YAZMA formasi ise p_pool gondermir - orada
--  siyahi 12 movzudan 85-e cixirdi ve "Umumilesdirici tapsiriqlar"
--  adi 11 defe tekrarlanirdi.  Muellim hansini sectiyini bilmirdi,
--  ustelik alt movzuya sual baglamaq onsuz da yanlisdir.
--
--  DUZELIS: rpc_bank_facets yalniz UST movzulari qaytarir
--  (t.parent_id is null).  Imza ve qalan hisseler eynidir.
--
--  Tekrar isledile biler.
-- =====================================================================
set search_path = public, extensions;

do $$
begin
  if to_regprocedure('public.rpc_plan_test_multi(uuid[], int)') is null then
    raise exception 'ONCE db/25_ders_plani.sql isledilmelidir';
  end if;
  if to_regprocedure('public.rpc_bank_facets(text, text, uuid, text)')
     is null then
    raise exception 'ONCE db/12_bank_rpc.sql isledilmelidir';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'topics'
                    and column_name = 'parent_id') then
    raise exception 'ONCE db/101_ders_plani_alt.sql isledilmelidir';
  end if;
end $$;

create or replace function public.rpc_plan_test_multi(
  p_item_ids uuid[], p_count int default 15)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_ids    uuid[];
  v_n      int;
  v_plan   public.class_plans%rowtype;
  v_topics jsonb;
  v_rule   jsonb;
  v_res    jsonb;
  v_test   uuid;
begin
  if p_count is null or p_count < 3 or p_count > 50 then
    raise exception 'Sual sayi 3-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  select array_agg(distinct x) into v_ids from unnest(p_item_ids) x;
  v_n := coalesce(array_length(v_ids, 1), 0);
  if v_n < 2 then
    raise exception 'En azi 2 movzu secin.' using errcode = '22023';
  end if;
  if (select count(*) from public.class_plan_items where id = any(v_ids)) <> v_n then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;
  if (select count(distinct plan_id)
        from public.class_plan_items where id = any(v_ids)) <> 1 then
    raise exception 'Movzular eyni plandan olmalidir.' using errcode = '22023';
  end if;

  select p.* into v_plan
    from public.class_plans p
    join public.class_plan_items i on i.plan_id = p.id
   where i.id = v_ids[1];
  perform app.plan_class(v_plan.class_id);

  if exists (select 1 from public.class_plan_items
              where id = any(v_ids) and done_at is null) then
    raise exception 'Yalniz kecilmis movzulardan test yigilir.'
      using errcode = '22023';
  end if;

  --  ALT MOVZU -> VALIDEYN.  Alt movzuya sual baglanmir (db/74, 82,
  --  83, 84), hovuz valideyndedir - db/101 tek movzuluq
  --  rpc_plan_test-de bunu edir, burada edilmemisdi.  Iki alt movzu
  --  eyni fesilden secilse valideyn bir defe getsin deye distinct.
  select jsonb_agg(distinct coalesce(par.id, t.id)::text) into v_topics
    from public.class_plan_items i
    join public.topics t on t.id = i.topic_id
    left join public.topics par on par.id = t.parent_id
   where i.id = any(v_ids);

  v_rule := jsonb_build_object(
    'pool', 'all',
    'count', p_count,
    'subject', (select slug from public.subjects where id = v_plan.subject_id),
    'level',   (select code from public.levels   where id = v_plan.level_id),
    'topics',  v_topics);

  --  generator abuneni ozu yoxlayir ('all' hovuzu pullu qapidir)
  v_res  := public.rpc_generate_test(
    v_rule,
    (select name from public.subjects where id = v_plan.subject_id) ||
      ' — qarışıq yoxlama (' || v_n || ' mövzu)');
  v_test := (v_res->>'test_id')::uuid;

  perform public.rpc_assign_test(
    v_plan.class_id, v_test, now() + interval '7 days', 1);

  return jsonb_build_object('ok', true, 'test_id', v_test,
                            'count', v_res->>'count');
end $$;

-- =====================================================================
--  2. rpc_bank_facets - alt movzular siyahiya dusmur
-- =====================================================================
create or replace function public.rpc_bank_facets(
  p_subject text default null,
  p_level   text default null,
  p_account uuid default null,
  p_pool    text default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_acc uuid := app.pick_account(p_account);
begin
  return jsonb_build_object(
    --  Her fennin gorunen sual sayi da qaytarilir ('n').  Suzgec
    --  ekranlari n=0 fenni GIZLEDIR - bos fenni secmek menasizdir.
    --  Sual FORMASI ise hamisini gosterir (ilk suali yazmaq ucun).
    --  Sinif secilibse, say O SINIF uzre hesablanir - 4-cu sinifde
    --  suali olmayan fenn siyahiya dusmesin.
    'subjects', coalesce((
      select jsonb_agg(jsonb_build_object('slug', z.slug, 'name', z.name, 'n', z.n)
                       order by z.sort)
        from (
          select s.slug, s.name, s.sort,
                 (select count(*) from public.questions q
                   where q.subject_id = s.id
                     and (p_level is null or q.level_id in
                          (select id from public.levels where code = p_level))
                     and case coalesce(p_pool, 'all')
                         when 'mine'     then q.account_id = v_acc
                         when 'platform' then q.owner_type = 'platform'
                                              and q.status = 'published'
                         else q.account_id = v_acc
                              or (q.owner_type = 'platform'
                                  and q.status = 'published')
                         end) as n
            from public.subjects s) z), '[]'::jsonb),
    --  Yalniz gorunen suali OLAN sinifler qaytarilir - fennler kimi.
    --  Yeni sinfin banki yuklenen kimi siyahida ozu peyda olur;
    --  bos sinfi secmek menasizdir.
    'levels', coalesce((
      select jsonb_agg(jsonb_build_object('code', z.code, 'name', z.name)
                       order by z.sort)
        from (
          select l.code, min(l.name) as name, min(l.sort) as sort
            from public.levels l
            join public.questions q on q.level_id = l.id
           where case coalesce(p_pool, 'all')
                 when 'mine'     then q.account_id = v_acc
                 when 'platform' then q.owner_type = 'platform'
                                      and q.status = 'published'
                 else q.account_id = v_acc
                      or (q.owner_type = 'platform'
                          and q.status = 'published')
                 end
             and (p_subject is null or q.subject_id in
                  (select id from public.subjects where slug = p_subject))
           group by l.code) z), '[]'::jsonb),
    --  Sinif de qaytarilir: eyni ad bir nece sinifde ola biler
    --  ("Bolme" 2-ci ve 3-cu sinifde).  Onsuz muellim hansini
    --  sectiyini bilmir.
    'topics', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', t.id, 'name', t.name,
               'level', l.code, 'level_name', l.name)
             order by l.sort nulls first, t.sort, t.name)
        from public.topics t
        join public.subjects s on s.id = t.subject_id
        left join public.levels l on l.id = t.level_id
       --  ALT MOVZULAR SIYAHIYA DUSMUR.  Onlar ders plani ucundur,
       --  suala baglanmir (db/74, 82, 83, 84).  p_pool verilende
       --  asagidaki "suali var" serti onlari onsuz da atirdi, amma
       --  sual FORMASI p_pool gondermir - orada 74 alt movzu, hem de
       --  11 defe "Umumilesdirici tapsiriqlar" adi ile tokulurdu.
       where t.parent_id is null
         and (p_subject is null or s.slug = p_subject)
         and (p_level is null or t.level_id is null
              or t.level_id in (select id from public.levels where code = p_level))
         and (p_pool is null or exists (
                select 1 from public.questions q
                 where q.topic_id = t.id
                   and case p_pool
                       when 'mine'     then q.account_id = v_acc
                       when 'platform' then q.owner_type = 'platform'
                                            and q.status = 'published'
                       else q.account_id = v_acc
                            or (q.owner_type = 'platform'
                                and q.status = 'published')
                       end))
      ), '[]'::jsonb),
    'tags', coalesce((
      select jsonb_agg(distinct tg)
        from public.questions q, unnest(q.tags) tg
       where q.account_id = v_acc or q.owner_type = 'platform'), '[]'::jsonb),
    'usage', jsonb_build_object(
      'used',  app.account_question_count(v_acc),
      'limit', app.account_question_limit(v_acc))
  );
end $$;;

-- --------------------------------------------------------------- huquq
revoke all on function public.rpc_plan_test_multi(uuid[], int) from public, anon;
revoke all on function
  public.rpc_bank_facets(text, text, uuid, text) from public, anon;
grant execute on function
  public.rpc_bank_facets(text, text, uuid, text) to authenticated;
grant execute on function public.rpc_plan_test_multi(uuid[], int) to authenticated;

do $$
begin
  if has_function_privilege('anon',
        'public.rpc_plan_test_multi(uuid[], int)', 'EXECUTE') then
    raise exception 'anon qarisiq test yiga bilir';
  end if;
  if has_function_privilege('anon',
        'public.rpc_bank_facets(text, text, uuid, text)', 'EXECUTE') then
    raise exception 'anon bank suzgeclerini gorur';
  end if;
  raise notice 'Alt movzular: qarisiq test valideynden yigir, '
               'sual formasinda alt movzu gorunmur.';
end $$;
