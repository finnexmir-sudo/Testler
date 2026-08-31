-- =====================================================================
--  29_bank_katalog.sql — sual bankinin EHATE gorüntüsü
--
--  NIYE LAZIM OLDU
--  Sual banki ekraninda platforma hovuzu duz 50 sual tokurdu ve
--  onlarin hamisi disabled idi: muellim baxirdi, hec ne ede bilmirdi.
--  Ustelik rpc_bank_list "order by created_at desc" ile isleyir - bank
--  sinif-sinif dolduruldugu ucun ekranda YALNIZ en son yazilan sinfin
--  kesiyi gorunurdu (1860 sualdan 50-si, hamisi 11-ci sinif).  Muellim
--  ele bilirdi bankda ancaq bu var.
--
--  Muellimin heqiqeten sorusdugu sual "son 50 sual hansidir" deyil,
--  "MENIM fennimde, MENIM sinfimde ne qeder var ve keyfiyyeti necedir".
--  Bu fayl hemin suali cavablandiran IKI OXU funksiyasi elave edir.
--  rpc_bank_list toxunulmur - axtaris ve "oz suallarim" yene ondan gedir.
--
--    rpc_bank_coverage(fenn, sinif, hovuz)
--      sinif verilmeyibse -> siniflər + her birinde sual sayi
--      sinif verilibse    -> hemin sinfin movzulari + saylar + cetinlik
--                            bolgusu (asan/orta/cetin)
--      sinifsiz / movzusuz suallar AYRICA saylanir - gizledilmir,
--      cunki "cemi 240" ile setirlerin cemi uzlasmalidir.
--
--    rpc_bank_samples(movzu, say, hovuz)
--      movzudan bir nece numune sual, variantlari ve duz cavabi ile.
--
--  NUMUNE VE ABUNE
--  Numune sayi SERVERDE 3-le mehdudlasir (p_limit boyuk gelse de) ve
--  abune telebi YOXDUR.  Bu bilerekdendir: ekran satis ekranidir,
--  muellim aldigi seyin keyfiyyetini almazdan EVVEL gormelidir.
--  Butun bankdan test yigmaq yene abune isteyir - rpc_generate_test
--  ve rpc_start_attempt-deki qapilara TOXUNULMUR.
--
--  TEHLUKESIZLIK
--  Her iki funksiya yalniz authenticated-e verilir, anon-dan revoke
--  olunur.  is_correct burada MUELLIME aciqdir - o, onsuz da yigdigi
--  testin veraqinde duz cavaglari gorur.  SAGIRD tetbiqi bu
--  funksiyalari cagira bilmir; asagida bunu yoxlayan assert var.
--  Bu fayldan sonra 05_grants.sql-i yeniden isletmek lazim deyil,
--  amma isletsen de zerer vermir - anon siyahisinda bu adlar yoxdur.
-- =====================================================================

-- ------------------------------------------------------- ehate sayları
create or replace function public.rpc_bank_coverage(
  p_subject text,
  p_level   text default null,
  p_pool    text default 'platform')
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_acc      uuid := app.pick_account(null);   -- giris yoxlamasi da burada
  v_pool     text := coalesce(nullif(btrim(p_pool), ''), 'platform');
  v_lev      text := nullif(btrim(coalesce(p_level, '')), '');
  v_sub      uuid;
  v_total    int;
  v_nolevel  int  := 0;
  v_notopic  int  := 0;
  v_levels   jsonb := '[]'::jsonb;
  v_topics   jsonb := null;
begin
  if v_pool not in ('mine', 'platform', 'all') then
    raise exception 'Hovuz yanlisdir.' using errcode = '22023';
  end if;

  select id into v_sub from public.subjects where slug = p_subject;
  if v_sub is null then
    raise exception 'Fenn tapilmadi.' using errcode = '22023';
  end if;

  --  Cemi: sinif verilibse O SINIF uzre, yoxsa butun fenn uzre
  select count(*) into v_total
    from public.questions q
   where q.subject_id = v_sub
     and case v_pool
         when 'mine'     then q.account_id = v_acc
         when 'platform' then q.owner_type = 'platform' and q.status = 'published'
         else q.account_id = v_acc
              or (q.owner_type = 'platform' and q.status = 'published')
         end
     and (v_lev is null or q.level_id in
          (select id from public.levels where code = v_lev));

  --  Sinifler.  "group by code" vacibdir: levels cedvelinde eyni kod
  --  (9/10/11) bir nece defe var - yoxsa siyahi ikilesir.
  select coalesce(jsonb_agg(jsonb_build_object(
           'code', z.code, 'name', z.name, 'n', z.n) order by z.sort), '[]'::jsonb)
    into v_levels
    from (
      select l.code, min(l.name) as name, min(l.sort) as sort, count(q.id) as n
        from public.levels l
        join public.questions q on q.level_id = l.id
       where q.subject_id = v_sub
         and case v_pool
             when 'mine'     then q.account_id = v_acc
             when 'platform' then q.owner_type = 'platform' and q.status = 'published'
             else q.account_id = v_acc
                  or (q.owner_type = 'platform' and q.status = 'published')
             end
       group by l.code
    ) z;

  --  Sinfi gosterilmeyen suallar: gizletmirik, ayrica saylayiriq ki,
  --  setirlerin cemi ile "cemi N" uzlassin.
  select count(*) into v_nolevel
    from public.questions q
   where q.subject_id = v_sub and q.level_id is null
     and case v_pool
         when 'mine'     then q.account_id = v_acc
         when 'platform' then q.owner_type = 'platform' and q.status = 'published'
         else q.account_id = v_acc
              or (q.owner_type = 'platform' and q.status = 'published')
         end;

  --  Movzular YALNIZ sinif secilende - fennin butun movzulari
  --  (11 sinif) bir siyahiya sigmir, ekran problemi elə ondan cixmisdi.
  if v_lev is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', z.id, 'name', z.name, 'n', z.n,
             'd1', z.d1, 'd2', z.d2, 'd3', z.d3) order by z.sort, z.name), '[]'::jsonb)
      into v_topics
      from (
        select t.id, t.name, min(t.sort) as sort, count(q.id) as n,
               count(q.id) filter (where q.difficulty = 1) as d1,
               count(q.id) filter (where q.difficulty = 2) as d2,
               count(q.id) filter (where q.difficulty = 3) as d3
          from public.topics t
          join public.questions q on q.topic_id = t.id
         where t.subject_id = v_sub
           and q.subject_id = v_sub
           and q.level_id in (select id from public.levels where code = v_lev)
           and case v_pool
               when 'mine'     then q.account_id = v_acc
               when 'platform' then q.owner_type = 'platform' and q.status = 'published'
               else q.account_id = v_acc
                    or (q.owner_type = 'platform' and q.status = 'published')
               end
         group by t.id, t.name
      ) z;

    select count(*) into v_notopic
      from public.questions q
     where q.subject_id = v_sub and q.topic_id is null
       and q.level_id in (select id from public.levels where code = v_lev)
       and case v_pool
           when 'mine'     then q.account_id = v_acc
           when 'platform' then q.owner_type = 'platform' and q.status = 'published'
           else q.account_id = v_acc
                or (q.owner_type = 'platform' and q.status = 'published')
           end;
  end if;

  return jsonb_build_object(
    'subject',  p_subject,
    'level',    v_lev,
    'pool',     v_pool,
    'total',    coalesce(v_total, 0),
    'levels',   v_levels,
    'no_level', coalesce(v_nolevel, 0),
    'topics',   v_topics,          -- sinif secilmeyibse null
    'no_topic', coalesce(v_notopic, 0));
end $$;

-- ------------------------------------------------------ numune suallar
create or replace function public.rpc_bank_samples(
  p_topic uuid,
  p_limit int  default 3,
  p_pool  text default 'platform')
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid := app.pick_account(null);
  v_pool text := coalesce(nullif(btrim(p_pool), ''), 'platform');
  --  SERT HED: p_limit ne gonderilse de 3-den cox numune verilmir.
  --  Bu, "bankı numune-numune bosaltmaq" yolunu baglayir.
  v_lim  int  := least(greatest(coalesce(p_limit, 3), 1), 3);
begin
  if v_pool not in ('mine', 'platform', 'all') then
    raise exception 'Hovuz yanlisdir.' using errcode = '22023';
  end if;
  if p_topic is null then
    raise exception 'Movzu secilmeyib.' using errcode = '22023';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id',         z.id,
             'body',       z.body,
             'kind',       z.kind,
             'difficulty', z.difficulty,
             'options', coalesce((
                select jsonb_agg(jsonb_build_object(
                         'body', o.body, 'correct', o.is_correct) order by o.ord)
                  from public.question_options o
                 where o.question_id = z.id), '[]'::jsonb))
           order by z.rn, z.difficulty)
      from (
        --  Cetinlik uzre bir-bir goturulur: 3 numune "asan, orta,
        --  cetin" olur, uc dene eyni cetinlikde yox.  Siralama
        --  deterministikdir - yoxlamalar da buna baglidir.
        select q.id, q.body, q.kind, q.difficulty,
               row_number() over (partition by q.difficulty order by q.id) rn
          from public.questions q
         where q.topic_id = p_topic
           and case v_pool
               when 'mine'     then q.account_id = v_acc
               when 'platform' then q.owner_type = 'platform' and q.status = 'published'
               else q.account_id = v_acc
                    or (q.owner_type = 'platform' and q.status = 'published')
               end
         order by rn, q.difficulty, q.id
         limit v_lim
      ) z), '[]'::jsonb);
end $$;

-- --------------------------------------------------------------- huquq
revoke all on function public.rpc_bank_coverage(text, text, text) from public, anon;
revoke all on function public.rpc_bank_samples(uuid, int, text)   from public, anon;

grant execute on function public.rpc_bank_coverage(text, text, text) to authenticated;
grant execute on function public.rpc_bank_samples(uuid, int, text)   to authenticated;

do $$
begin
  if has_function_privilege('anon',
      'public.rpc_bank_coverage(text, text, text)', 'EXECUTE') then
    raise exception 'anon bank ehatesini gore bilir';
  end if;
  if has_function_privilege('anon',
      'public.rpc_bank_samples(uuid, int, text)', 'EXECUTE') then
    raise exception 'anon numune suallari gore bilir';
  end if;
  raise notice 'Bank katalogu quruldu: rpc_bank_coverage + rpc_bank_samples.';
end $$;
