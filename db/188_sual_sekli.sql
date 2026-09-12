-- =====================================================================
--  188_sual_sekli.sql — SUALIN SEKLI: SVG data-URI + qoruyucular
--
--  BOSLUQ (bank sessiyasi olcdu, 2026-09-12): bezi movzularda
--  derslikdeki sual SEKLE soykenir - hendese ucbucagi, elektrik dovresi,
--  bloksxem, xerite, huceyre.  Bizde eyni elaqe sozle yazilir.
--  Teqriben 45-60 movzu, bankin ~10-11%-i.
--
--  Sxemde 'questions.media_url' sutunu ILK GUNDEN var (01_schema) ve
--  DOQQUZ RPC onu artiq qaytarir - 03, 10, 11, 123, 129, 132 (iki
--  yerde), 133, 137.  Frontendde ise HEC BIR ekranda cekilmirdi:
--  server danisirdi, ekran qulaq asmirdi.  Bu miqrasiya sutunu
--  ISLEK edir; RPC-lere toxunmur (ehtiyac yoxdur).
--
--  SEKIL NECE SAXLANIR.  Xarici fayl yox, data-URI:
--      media_url = 'data:image/svg+xml,%3Csvg ... %3C/svg%3E'
--  Sebeb: (1) xarici sorgu yoxdur - CDN qadagasi pozulmur, oflayn
--  isleyir; (2) sekil sualla BIR yerde gelir, elave gedis-gelis yox
--  (suret olculur - db/180); (3) capda da cixir.
--
--  TEHLUKESIZLIK - iki qat:
--   1. Ekranda <img src="..."> ile cizilir, innerHTML-e DUSMUR.
--      Brauzer <img>-in icindeki SVG-de skript ISLETMIR - bu, standart
--      davranisdir.  Yeni sekil, hetta sehven pis yazilsa da, kod
--      isletmir.  (CLAUDE.md: "istifadeci girisi hec vaxt innerHTML-e
--      catmir" qaydasi ile eyni xetdedir.)
--   2. Bazada CHECK: yalniz platforma suali sekil dasiya biler; unvan
--      yalniz 'data:image/svg+xml' ve ya 'https://' ola biler; suphali
--      soz varsa (script, onload, onerror, javascript:) yazilmir.
--      Muellimin oz suali onsuz da media_url yaza bilmir - sual yazan
--      RPC (132) o sutuna toxunmur; CHECK ikinci qapidir.
--
--  BANK SESSIYASI UCUN: app.svg_uri() funksiyasi xam SVG-ni data-URI-ye
--  cevirir - miqrasiyada elle kodlasdirmaq lazim deyil:
--      update public.questions set media_url = app.svg_uri($$<svg ...>$$)
--       where ext_key = 'riy7-ucbucaq#3';
-- =====================================================================

do $$
begin
  if to_regclass('public.questions') is null then
    raise exception 'ONCE 01_schema.sql isledilmelidir.';
  end if;
end $$;

--  ------------------------------------------------ xam SVG -> data-URI
--  Yalniz data-URI ucun VACIB simvollar kodlasdirilir - qalani oldugu
--  kimi qalir ki, unvan qisa olsun (baza setri kicik qalsin).
--  Sira vacibdir: '%' BIRINCI kodlasdirilir, yoxsa oz kodlarimizi
--  ikinci defe kodlayardiq.
create or replace function app.svg_uri(p_svg text) returns text
language sql immutable as $$
  --  xmlns MECBURIDIR: <img>-in icindeki SVG onsuz ACILMIR - bos qutu
  --  gorunur, hec bir xeta da vermir (tapmasi cetin sehvdir).  Ona gore
  --  unutmagi mumkunsuz edirik: yoxdursa ozumuz elave edirik.
  with a as (
    select case when p_svg is null or btrim(p_svg) = '' then null
                when position('xmlns' in p_svg) > 0 then btrim(p_svg)
                else regexp_replace(btrim(p_svg), '^<svg',
                       '<svg xmlns="http://www.w3.org/2000/svg"') end as v)
  select case when a.v is null then null else
    'data:image/svg+xml,' ||
    replace(replace(replace(replace(replace(replace(replace(replace(
      regexp_replace(a.v, '[\r\n\t]+', ' ', 'g'),
      '%', '%25'), '#', '%23'), '"', ''''), '<', '%3C'), '>', '%3E'),
      '&', '%26'), '?', '%3F'), '  ', ' ')
  end from a
$$;

--  ---------------------------------------------------- qoruyucu (CHECK)
--  Qayda TETBIQ OLUNMAMISDAN evvel: movcud setirlerden hansisa yeni
--  qaydani pozursa, miqrasiya DAYANIR - gozden qacmis melumatin
--  ustunden sakitce kecmirik.  (Bos ve ya artiq duzgun olan setirler
--  maneə deyil: miqrasiya tekrar isledile biler.)
do $$
declare n int;
begin
  select count(*) into n from public.questions
   where media_url is not null
     and not (owner_type = 'platform' and length(media_url) <= 24000
              and (media_url like 'data:image/svg+xml,%' or media_url like 'data:image/svg+xml;%'
                   or media_url like 'https://%')
              and position('script'      in lower(media_url)) = 0
              and position('onload'      in lower(media_url)) = 0
              and position('onerror'     in lower(media_url)) = 0
              and position('javascript:' in lower(media_url)) = 0);
  if n > 0 then
    raise exception 'Yeni qaydaya uymayan % setir var - once onlara baxin.', n;
  end if;
end $$;

alter table public.questions drop constraint if exists questions_media_ok;
alter table public.questions add constraint questions_media_ok check (
  media_url is null
  or (
    --  yalniz platforma bankinda sekil olur
    owner_type = 'platform'
    --  bir sekil 24 KB-dan boyuk olmamalidir: sual sorgusu ile birlikde
    --  gelir, telefonda hisse-hisse acilmamalidir
    and length(media_url) <= 24000
    and (media_url like 'data:image/svg+xml,%'
      or media_url like 'data:image/svg+xml;%'
      or media_url like 'https://%')
    and position('script'     in lower(media_url)) = 0
    and position('onload'     in lower(media_url)) = 0
    and position('onerror'    in lower(media_url)) = 0
    and position('javascript:' in lower(media_url)) = 0
  )
);

comment on column public.questions.media_url is
  'Sualin sekli: SVG data-URI (app.svg_uri ile yazilir) ve ya https unvan. '
  'Yalniz platforma suallarinda.  Ekranda <img> ile cizilir - innerHTML-e dusmur.';

-- ---------------------------------------------------------------------
--  RPC-LER: 'media_url' cavaba qaytarilir
--
--  DIQQET - burada bir tapinti var.  Kohne fayllarda (03, 10, 11, 123,
--  129, 132, 133, 137) 'media_url' cavabda VAR IDI, amma sonrakı
--  miqrasiyalar hemin funksiyalari yeniden yazanda sutunu APARDI.
--  Bazadaki CANLI veziyyet olculdu (2026-09-12): sutun yalniz UC
--  funksiyada qalmisdi - rpc_start_attempt, rpc_student_mistakes,
--  rpc_student_practice_next.  Yeni sagird testi islerken sekli
--  gorurdu, muellim ise bankda GORMURDU.
--
--  Asagidaki dord govde bazadan (pg_get_functiondef) oxunub, yalniz
--  bir sətir elave olunub - baska hec ne deyismeyib.  Huquqlar
--  'create or replace' ile oldugu kimi qalir.
--
--  HELE QALIR (ayrica is): rpc_attempt_sheet, rpc_test_result,
--  rpc_student_report - onlar sual metnini 'attempt_answers'-deki
--  ANLIQ NUSXEDEN goturur (aa.question_body), yeni cehd anindaki
--  vəziyyəti saxlayir.  Sekli orada gostermek ucun ya sekli de nusxeye
--  yazmaq, ya da suala qosulmaq lazimdir - bu, bal tarixcesine toxunan
--  qerardir, ona gore bu miqrasiyaya salinmadi.  Ekran kodu hazirdir:
--  payload sekli getirende ozu cizecek.
-- ---------------------------------------------------------------------

--  ---- rpc_test_preview
CREATE OR REPLACE FUNCTION public.rpc_test_preview(p_test_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
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
               'media_url', q.media_url,
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
end $function$;

--  ---- rpc_bank_list
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
       and (p_filters->>'q' is null
            or q.body ilike '%' || btrim(p_filters->>'q') || '%')
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

--  ---- rpc_bank_samples
CREATE OR REPLACE FUNCTION public.rpc_bank_samples(p_topic uuid, p_limit integer DEFAULT 3, p_pool text DEFAULT 'platform'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
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
             'media_url',  z.media_url,
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
        select q.id, q.body, q.media_url, q.kind, q.difficulty,
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
end $function$;

--  ---- rpc_bank_question
CREATE OR REPLACE FUNCTION public.rpc_bank_question(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare v jsonb;
begin
  if not app.can_manage_question(p_id) then
    raise exception 'Bu sual sizin deyil.' using errcode = '42501';
  end if;

  select jsonb_build_object(
           'id', q.id, 'body', q.body, 'media_url', q.media_url, 'kind', q.kind,
           'params', q.params,
           --  134: oz sualinin canli statistikasi (n, duz faizi, ayirdetme, siqnallar)
           'stats', (select jsonb_build_object('n', st.n, 'p', st.p, 'rpb', st.rpb, 'flags', to_jsonb(st.flags))
                       from app.qstat_rows(q.id) st),
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
end $function$;
