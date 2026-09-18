-- =====================================================================
--  214 : «DOSTUNA AT» - SUAL PAYLASIMI (2026-09-18)
--
--  !!! BU FAYL HELE QOSULMAYIB - CANLIDA ISLEDILMEYIB !!!
--  Istifadeci qerari: «dostuna gonderi heleki saxlayaq, sonra baxariq».
--  run.sh-da yoxdur, 05_grants.sql-da yoxdur, sagird tetbiqinde duyme
--  yoxdur.  Acmaq ucun addimlar: CLAUDE.md -> «db/214 ... QOSULMAYIB».
--
--  NIYE
--  Istifadeci: «biz bir yolla coxalmaliyiq».  Sagird odemir - MUELLIM
--  odeyir; ona gore zencir uzundur: sagird -> dostu -> DOSTUN MUELLIMI.
--  Bunun deyeri odur ki, xerc birdefelikdir, fayda ise aciq ucludur.
--
--  Paylasim GUNDELIK TEKRARA baglanmir.  Usaq onsuz da her hefte testin
--  NETICE ekranindadir - orada butun suallar gozunun qabagindadir, yeni
--  verdis lazim deyil.  Duyme ora qoyulur (+ sehv defteri, + gundelik
--  paketin sonu) - hamisi eyni RPC-ni cagirir.
--
--  BANK QAPISI - en vacib hisse
--  Girissiz acilan sehife bank sualı gosterir.  Ehtiyatsiz qursaq, bu
--  banki cixarmaq ucun aciq qapidir (19 000+ sual).  Bes sert:
--    1. YALNIZ sagirdin OZUNUN cavabladigi sual paylasila biler - en
--       guclu sert: paylasim hec bir YENI melumat acmir.
--    2. Token 72 bit tesaduf (9 bayt) - sira ile yigmaq olmur, linkde
--       sualin id-si yoxdur.
--    3. Gunde 3 link (app.share_daily_limit()).
--    4. 7 gun omur + bir link en coxu 50 defe acilir (WhatsApp qrupu
--       ucun bes edir, robot ucun yox).
--    5. Duz variant sehifeye GETMIR - cavab serverde yoxlanir.
--
--  OLCU birinci gunden icindedir: gonderildi -> acildi -> cavabladi ->
--  bil10.az-a klikledi.  Sonuncu addim ?src=sual ile qeydiyyata baglanir
--  (db/204).  Yoxsa uc aydan sonra «isledimi?» sualina tehminle cavab
--  vereceyik.
-- =====================================================================

create table if not exists public.shares (
  id          uuid primary key default gen_random_uuid(),
  k           text not null unique,
  student_id  uuid not null references public.students(id)  on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  --  sual parametrikdirse GORULEN nusxe saxlanilir - dost eyni sualı
  --  gorsun, basqa reqemlerle yox
  params      jsonb,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null,
  opens       int not null default 0,
  answers     int not null default 0,
  ok_n        int not null default 0,
  clicks      int not null default 0
);
create index if not exists shares_student_idx on public.shares (student_id, created_at desc);
alter table public.shares enable row level security;
revoke all on public.shares from public, anon, authenticated;
--  Siyaset yoxdur - yalniz definer RPC-ler toxunur.

create or replace function app.share_daily_limit() returns int
language sql immutable as $$ select 3 $$;
revoke all on function app.share_daily_limit() from public, anon, authenticated;

create or replace function app.share_max_opens() returns int
language sql immutable as $$ select 50 $$;
revoke all on function app.share_max_opens() from public, anon, authenticated;

--  URL-e yazila bilen qisa acar: 9 bayt -> 12 simvol
create or replace function app.share_key() returns text
language sql volatile as $$
  select translate(encode(extensions.gen_random_bytes(9), 'base64'), '+/=', '-_x')
$$;
revoke all on function app.share_key() from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Sagird: link duzeldir.  Yalniz OZ cavabladigi suala.
-- ---------------------------------------------------------------------
create or replace function public.rpc_share_make(p_token text, p_question_id uuid)
returns jsonb
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  v_day  date := (now() at time zone 'Asia/Baku')::date;
  v_k    text;
  v_par  jsonb;
  v_n    int;
  s      public.shares%rowtype;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  if not exists (select 1 from public.questions q
                  where q.id = p_question_id and q.status = 'published' and q.kind = 'single'
                    and exists (select 1 from public.question_options o
                                 where o.question_id = q.id and o.is_correct)) then
    raise exception 'Bu sual paylasila bilmir.' using errcode = '22023';
  end if;

  --  1-ci sert: sagird bu suala OZU cavab verib (test, sehv defteri ve
  --  ya gundelik paket).  Paylasim yeni melumat acmir.
  if not (
       exists (select 1 from public.attempt_answers aa
                 join public.attempts a on a.id = aa.attempt_id
                where a.student_id = v_st and a.status = 'submitted'
                  and aa.question_id = p_question_id)
    or exists (select 1 from public.mistakes m
                where m.student_id = v_st and m.question_id = p_question_id)
    or exists (select 1 from public.daily_packs d, jsonb_array_elements(d.answers) x
                where d.student_id = v_st and (x->>'q')::uuid = p_question_id)
  ) then
    raise exception 'Yalniz ozunun isledigi sualı paylasa bilersen.' using errcode = '42501';
  end if;

  --  Eyni sual ucun diri link varsa onu qaytar - kvota yanmasin
  select * into s from public.shares
   where student_id = v_st and question_id = p_question_id and expires_at > now()
   order by created_at desc limit 1;
  if s.id is not null then
    return jsonb_build_object('k', s.k, 'tekrar', true);
  end if;

  select count(*) into v_n from public.shares
   where student_id = v_st
     and (created_at at time zone 'Asia/Baku')::date = v_day;
  if v_n >= app.share_daily_limit() then
    raise exception 'Bu gün % link göndərmisən. Sabah davam et.', app.share_daily_limit()
      using errcode = '42901';
  end if;

  --  Gorulen nusxe: evvel hansi parametrlerle gorubse o, yoxsa yenisi
  select coalesce(
    (select x->'params' from public.daily_packs d, jsonb_array_elements(d.items) x
      where d.student_id = v_st and (x->>'q')::uuid = p_question_id
        and x ? 'params' limit 1),
    app.pq_seed(q.params, q.id)) into v_par
    from public.questions q where q.id = p_question_id;

  v_k := app.share_key();
  insert into public.shares (k, student_id, question_id, params, expires_at)
  values (v_k, v_st, p_question_id, v_par, now() + interval '7 days');
  return jsonb_build_object('k', v_k, 'tekrar', false,
                            'qaliq', app.share_daily_limit() - v_n - 1);
end $$;
revoke all on function public.rpc_share_make(text, uuid) from public;
grant execute on function public.rpc_share_make(text, uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
--  Dost: linki acir.  Giris yoxdur, kod yoxdur.  DUZ VARIANT GETMIR.
--  p_ev = 'click' eyni RPC ile bil10.az klikini sayir (ayrica anon
--  funksiya acmiriq - her yeni anon RPC bir hucum sethidir).
-- ---------------------------------------------------------------------
create or replace function public.rpc_share_open(p_k text, p_ev text default 'open')
returns jsonb
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare
  s public.shares%rowtype;
begin
  select * into s from public.shares where k = p_k;
  if s.id is null then
    return jsonb_build_object('ok', false, 'reason', 'yox');
  end if;
  if s.expires_at <= now() then
    return jsonb_build_object('ok', false, 'reason', 'vaxt');
  end if;
  if s.opens >= app.share_max_opens() then
    return jsonb_build_object('ok', false, 'reason', 'hedd');
  end if;

  if p_ev = 'click' then
    update public.shares set clicks = clicks + 1 where id = s.id;
    return jsonb_build_object('ok', true, 'klik', true);
  end if;
  update public.shares set opens = opens + 1 where id = s.id;

  return jsonb_build_object(
    'ok', true,
    'kim', (select st.display_name from public.students st where st.id = s.student_id),
    'question', (
      select jsonb_build_object(
               'body', app.pq_render(q.body, s.params),
               'media_url', q.media_url,
               'topic', (select t.name from public.topics t where t.id = q.topic_id),
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object(
                          'id', o.id, 'body', app.pq_render(o.body, s.params)) order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
        from public.questions q where q.id = s.question_id));
end $$;
revoke all on function public.rpc_share_open(text, text) from public;
grant execute on function public.rpc_share_open(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------
--  Dost: cavab.  Bal serverde yoxlanir; duz variant CAVABDAN SONRA
--  bildirilir (usaq oyrensin deye) - evvel yox.
-- ---------------------------------------------------------------------
create or replace function public.rpc_share_answer(p_k text, p_option_id uuid)
returns jsonb
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare
  s     public.shares%rowtype;
  v_ok  boolean;
begin
  select * into s from public.shares where k = p_k;
  if s.id is null or s.expires_at <= now() then
    raise exception 'Link artiq islemir.' using errcode = '22023';
  end if;
  select o.is_correct into v_ok from public.question_options o
   where o.id = p_option_id and o.question_id = s.question_id;
  if v_ok is null then
    raise exception 'Variant tapilmadi.' using errcode = '22023';
  end if;
  update public.shares
     set answers = answers + 1, ok_n = ok_n + case when v_ok then 1 else 0 end
   where id = s.id;
  return jsonb_build_object(
    'correct', v_ok,
    'right_id', (select o.id from public.question_options o
                  where o.question_id = s.question_id and o.is_correct order by o.ord limit 1),
    'explanation', (select app.pq_render(coalesce(q.explanation, ''), s.params)
                      from public.questions q where q.id = s.question_id));
end $$;
revoke all on function public.rpc_share_answer(text, uuid) from public;
grant execute on function public.rpc_share_answer(text, uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
--  Olcu: hunide paylasim zenciri (marker: 213-un 'tekrar' bloku)
-- ---------------------------------------------------------------------
do $$
declare
  v_src  text := pg_get_functiondef('public.rpc_admin_huni(int)'::regprocedure);
  v_mark text := '''days'',       p_days,';
  v_add  text;
begin
  if position('''paylasim''' in v_src) > 0 then
    raise notice '214 olcu artiq tetbiq olunub, kecilir';
    return;
  end if;
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception '214: rpc_admin_huni markeri 1 defe olmalidir';
  end if;
  v_add := '''days'',       p_days,
      --  214: paylasim zenciri.  Numune hesab sayilmir.
      ''paylasim'', (
        select jsonb_build_object(
          ''gonderildi'', count(*),
          ''sagird'',     count(distinct sh.student_id),
          ''acildi'',     coalesce(sum(sh.opens), 0),
          ''cavabladi'',  coalesce(sum(sh.answers), 0),
          ''klik'',       coalesce(sum(sh.clicks), 0),
          --  zencirin sonu: bu kanaldan gelen QEYDIYYAT
          ''qeydiyyat'',  (select count(*) from public.profiles pr where pr.src = ''sual''))
          from public.shares sh
          join public.students st on st.id = sh.student_id
          join public.accounts ac on ac.id = st.account_id and not ac.is_demo),';
  execute replace(v_src, v_mark, v_add);
end $$;
revoke all on function public.rpc_admin_huni(int) from public, anon;
grant execute on function public.rpc_admin_huni(int) to authenticated;
