-- =====================================================================
--  212 : «BU GUNUN 5 SUALI» - SAGIRD UCUN FERDI GUNDELIK TEKRAR
--        (2026-09-18)
--
--  NIYE
--  Sagird tetbiqe heftede bir-iki defe girir, cunki her defe OZU qerar
--  vermelidir: hansi movzu, hansi test, nece sual.  Bu qerar yuku
--  gundelik verdisi oldurur.  Indi qerar SERVERDEDIR: usaq acir, hazir
--  bes sual gorur, uc deqiqede bitirir.  Hiss: «mene ayrica repetitor
--  tutublar» - tetbiq menim kecmisime qayidir, tesadufi test vermir.
--
--  MUTLEQ QAYDA (istifadeci): suallar YALNIZ KECILEN DERSLERDEN olur.
--  Menbe class_plan_items.done_at - muellimin «kecildi» isareledigi
--  setirler.  Plan setri ALT movzudur, suallar ise BASLIGA baglidir
--  (101_ders_plani_alt.sql) - ona gore valideyn movzuya qalxiriq.
--  Plan hec isarelenmemisdirse FALLBACK: usagin OZU testde cavab
--  verdigi movzular (cavab verdi = hemin movzu onsuz da kecilib).
--  Bos ekran gostermekden yaxsidir.
--
--  BES SUALIN SIRASI (sabit, tesadufi deyil)
--    1  bildiyi     - kecilmis movzudan EVVEL DUZ cavabladigi sual
--                     (ilk 20 saniyede ugur hissi)
--    2  sehv        - en kohne, hele baglanmamis sehv (defterden)
--    3  eyni movzu  - ayni bacarigin basqa sualı
--    4  tekrar      - 5-60 gun evvel duz cavabladigi (araliqli tekrar)
--    5  yeni        - muellimin EN SON «kecildi» etdigi movzudan
--  Slot bosdursa kecilir, sonda hovuzdan doldurulur.  Uc sualdan az
--  yigilirsa paket QURULMUR - bir suallik «gundelik tekrar» gulunc
--  olardi.
--
--  ABUNE
--  Sehv defteri (211) abune paketindedir; gundelik paket 2-ci ve 3-cu
--  sualı ORADAN goturur - pulsuz buraxsaq 211-in qapisi arxa qapidan
--  acilardi.  Ona gore paket de abune ilədir: pulsuz hesabda sayğac ve
--  movzu adlari gorunur, sual gelmir.  Muellimin sinaq ayinda usaq
--  dadini gorur - qerar 211-dekinin eynidir.
--
--  GUN
--  Teqvim gunu Asia/Baku (166, 209 ile eyni).  Paket gun icinde SABIT
--  qalir (sehife yenilense eyni suallar), gun deyisende yenisi qurulur.
--  Qacirilan gun BORC YARATMIR - dunenin suallari bu gune yigilmir.
-- =====================================================================

-- ---------------------------------------------------------------------
--  DUZELIS (129): app.mistake_note-un INSERT qolu p_practice-i nezere
--  almirdi - ilk defe sehv edilen sual next_at = now() ile dusurdu, yeni
--  yaranan setir dérhal «gozleyir» olurdu.  Mesq/gundelik paket «sabah
--  yene gelecek» yazir, ona gore yeni setir de SABAHA qoyulur.  UPDATE
--  qolu onsuz da bele idi - iki qol arasindaki ziddiyyet gedir.
-- ---------------------------------------------------------------------
create or replace function app.mistake_note(p_student uuid, p_question uuid, p_ok boolean, p_practice boolean)
returns void
language plpgsql as $$
declare m public.mistakes%rowtype;
begin
  if p_ok is null then return; end if;     -- cavabsiz sual sehv deyil
  select * into m from public.mistakes where student_id = p_student and question_id = p_question;
  if not p_ok then
    if m.student_id is null then
      insert into public.mistakes (student_id, question_id, next_at)
      values (p_student, p_question,
              case when p_practice then now() + interval '1 day' else now() end);
    else
      update public.mistakes
         set status = 'open', wrong_n = wrong_n + 1, last_at = now(), cleared_at = null,
             next_at = case when p_practice then now() + interval '1 day' else now() end
       where student_id = p_student and question_id = p_question;
    end if;
  elsif m.student_id is not null and m.status <> 'closed' then
    if m.status = 'open' then
      update public.mistakes
         set status = 'review', last_at = now(),
             next_at = now() + (app.review_days() || ' days')::interval
       where student_id = p_student and question_id = p_question;
    elsif m.next_at <= now() then
      update public.mistakes
         set status = 'closed', last_at = now(), cleared_at = now()
       where student_id = p_student and question_id = p_question;
    end if;
  end if;
end $$;
revoke all on function app.mistake_note(uuid, uuid, boolean, boolean) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Gunun paketi.  items: [{q, src, topic, params}] - sira sabitdir.
--  answers: [{q, ok, topic}] - cavablanan sayı = jsonb_array_length.
-- ---------------------------------------------------------------------
create table if not exists public.daily_packs (
  student_id uuid not null references public.students(id) on delete cascade,
  day        date not null,
  items      jsonb not null default '[]'::jsonb,
  answers    jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  done_at    timestamptz,
  primary key (student_id, day)
);
alter table public.daily_packs enable row level security;
revoke all on public.daily_packs from public, anon, authenticated;
--  Siyaset yoxdur - yalniz definer RPC-ler toxunur.

-- ---------------------------------------------------------------------
--  Kecilen movzular.  Birinci menbe muellimin plani; plan bosdursa
--  usagin ozunun cavab verdigi movzular.
-- ---------------------------------------------------------------------
create or replace function app.daily_topics(p_student uuid)
returns table (topic_id uuid, at timestamptz, src text)
language sql stable as $$
  with cls as (
    select class_id from public.students where id = p_student
  ),
  plan as (
    select coalesce(par.id, t.id) as tid, max(i.done_at) as at
      from public.class_plan_items i
      join public.class_plans p on p.id = i.plan_id
      join cls on cls.class_id = p.class_id
      join public.topics t on t.id = i.topic_id
      left join public.topics par on par.id = t.parent_id
     where i.done_at is not null
     group by coalesce(par.id, t.id)
  ),
  own as (
    select aa.topic_id as tid, max(aa.answered_at) as at
      from public.attempt_answers aa
      join public.attempts a on a.id = aa.attempt_id
     where a.student_id = p_student and a.status = 'submitted'
       and aa.topic_id is not null
     group by aa.topic_id
  )
  select p.tid, p.at, 'plan' from plan p
  union all
  select o.tid, o.at, 'ozu' from own o
   where not exists (select 1 from plan)
$$;
revoke all on function app.daily_topics(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Movzunun gundelik hovuzu.  Yalniz TEK SECIMLI derc olunmus sual:
--  gundelik dovre bir toxunusdur, yazili cavab onu uzadir.
-- ---------------------------------------------------------------------
create or replace function app.daily_pool(p_topic uuid, p_level uuid, p_account uuid)
returns table (id uuid, difficulty smallint, params jsonb)
language sql stable as $$
  select q.id, q.difficulty, q.params
    from public.questions q
   where q.topic_id = p_topic and q.status = 'published' and q.kind = 'single'
     and (q.level_id = p_level or q.level_id is null)
     and (q.owner_type = 'platform' or q.account_id = p_account)
     and exists (select 1 from public.question_options o
                  where o.question_id = q.id and o.is_correct)
$$;
revoke all on function app.daily_pool(uuid, uuid, uuid) from public, anon, authenticated;

--  Bir sətir paket elementi.  jsonb_strip_nulls VACIBDIR: parametrsiz
--  sualda 'params' acari jsonb null olsa, pq_render onu SQL NULL kimi
--  gormur ve sablonu hesablamaga calisir.
create or replace function app.daily_item(p_q uuid, p_src text)
returns jsonb
language sql volatile as $$
  select jsonb_strip_nulls(jsonb_build_object(
           'q', q.id, 'src', p_src,
           'topic', coalesce(t.name, ''),
           'params', app.pq_seed(q.params, q.id)))
    from public.questions q
    left join public.topics t on t.id = q.topic_id
   where q.id = p_q
$$;
revoke all on function app.daily_item(uuid, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Paketi qurur.  Bes slot, her biri bos qala biler; sonda hovuzdan
--  doldurulur.  Uc sualdan az yigilirsa bos massiv qayidir.
-- ---------------------------------------------------------------------
create or replace function app.daily_build(p_student uuid)
returns jsonb
language plpgsql volatile as $$
declare
  v_acc  uuid;
  v_lvl  uuid;
  v_cov  uuid[];
  v_new  uuid;
  v_used uuid[] := '{}';
  v_it   jsonb  := '[]'::jsonb;
  v_q    uuid;
  v_t    uuid;
begin
  select s.account_id, c.level_id into v_acc, v_lvl
    from public.students s
    left join public.classes c on c.id = s.class_id
   where s.id = p_student;

  select array_agg(z.topic_id order by z.at desc nulls last)
    into v_cov from app.daily_topics(p_student) z;
  if v_cov is null or cardinality(v_cov) = 0 then
    return '[]'::jsonb;
  end if;
  v_new := v_cov[1];

  -- 1) BILDIYI: evvel duz cavabladigi, defterde acıq olmayan sual
  select x.id into v_q
    from unnest(v_cov) with ordinality as c(tid, ord)
    join lateral app.daily_pool(c.tid, v_lvl, v_acc) x on true
   where exists (select 1 from public.attempt_answers aa
                   join public.attempts a on a.id = aa.attempt_id
                  where a.student_id = p_student and a.status = 'submitted'
                    and aa.question_id = x.id and aa.is_correct)
     and not exists (select 1 from public.mistakes m
                      where m.student_id = p_student and m.question_id = x.id
                        and m.status <> 'closed')
   order by x.difficulty, c.ord, random() limit 1;
  if v_q is null then
    --  hele duz cavabi yoxdur - en son dersin EN ASAN sualı
    select x.id into v_q from app.daily_pool(v_new, v_lvl, v_acc) x
     order by x.difficulty, random() limit 1;
  end if;
  if v_q is not null then
    v_it := v_it || app.daily_item(v_q, 'bilirem');
    v_used := v_used || v_q;
  end if;

  -- 2) SEHV: en kohne, hele baglanmamis sehv (yalniz kecilmis movzudan)
  v_q := null;
  select m.question_id, q.topic_id into v_q, v_t
    from public.mistakes m
    join public.questions q on q.id = m.question_id
                           and q.status = 'published' and q.kind = 'single'
   where m.student_id = p_student and m.status <> 'closed' and m.next_at <= now()
     and q.topic_id = any(v_cov)
     and not (m.question_id = any(v_used))
   order by (m.status = 'open') desc, m.first_at limit 1;
  if v_q is not null then
    v_it := v_it || app.daily_item(v_q, 'sehv');
    v_used := v_used || v_q;
  else
    v_t := null;
  end if;

  -- 3) EYNI MOVZU: ayni bacarigin basqa sualı
  if v_t is not null then
    v_q := null;
    select x.id into v_q from app.daily_pool(v_t, v_lvl, v_acc) x
     where not (x.id = any(v_used))
     order by x.difficulty, random() limit 1;
    if v_q is not null then
      v_it := v_it || app.daily_item(v_q, 'eyni');
      v_used := v_used || v_q;
    end if;
  end if;

  -- 4) TEKRAR: 5-60 gun evvel duz cavabladigi sual («yadinda qalib?»)
  v_q := null;
  select aa.question_id into v_q
    from public.attempt_answers aa
    join public.attempts a on a.id = aa.attempt_id
    join public.questions q on q.id = aa.question_id
                           and q.status = 'published' and q.kind = 'single'
   where a.student_id = p_student and a.status = 'submitted' and aa.is_correct
     and aa.answered_at <  now() - interval '5 days'
     and aa.answered_at >= now() - interval '60 days'
     and q.topic_id = any(v_cov)
     and not (aa.question_id = any(v_used))
     and not exists (select 1 from public.mistakes m
                      where m.student_id = p_student and m.question_id = aa.question_id
                        and m.status <> 'closed')
   order by aa.answered_at limit 1;
  if v_q is not null then
    v_it := v_it || app.daily_item(v_q, 'tekrar');
    v_used := v_used || v_q;
  end if;

  -- 5) YENI: en son «kecildi» movzusundan hele gormediyi sual
  v_q := null;
  select x.id into v_q from app.daily_pool(v_new, v_lvl, v_acc) x
   where not (x.id = any(v_used))
     and not exists (select 1 from public.attempt_answers aa
                       join public.attempts a on a.id = aa.attempt_id
                      where a.student_id = p_student and aa.question_id = x.id)
   order by x.difficulty, random() limit 1;
  if v_q is null then
    select x.id into v_q from app.daily_pool(v_new, v_lvl, v_acc) x
     where not (x.id = any(v_used))
     order by x.difficulty, random() limit 1;
  end if;
  if v_q is not null then
    v_it := v_it || app.daily_item(v_q, 'yeni');
    v_used := v_used || v_q;
  end if;

  -- Bese kimi doldur: en yeni kecilen movzular evvel
  while jsonb_array_length(v_it) < 5 loop
    v_q := null;
    select x.id into v_q
      from unnest(v_cov) with ordinality as c(tid, ord)
      join lateral app.daily_pool(c.tid, v_lvl, v_acc) x on true
     where not (x.id = any(v_used))
     order by c.ord, x.difficulty, random() limit 1;
    exit when v_q is null;
    v_it := v_it || app.daily_item(v_q, 'elave');
    v_used := v_used || v_q;
  end loop;

  --  «Gundelik 5 sual» adi ile 1-2 sual gostermek sozu pozur
  if jsonb_array_length(v_it) < 3 then
    return '[]'::jsonb;
  end if;
  return v_it;
end $$;
revoke all on function app.daily_build(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Sagird: gunun paketi.  Yoxdursa qurulur; varsa oldugu kimi qayidir
--  (sehife yenilenende suallar deyismir).
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_daily(p_token text)
returns jsonb
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  v_acc  uuid;
  v_paid boolean;
  v_day  date := (now() at time zone 'Asia/Baku')::date;
  p      public.daily_packs%rowtype;
  v_n    int;
  v_i    int;
  v_cur  jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select account_id into v_acc from public.students where id = v_st;
  v_paid := app.has_active_subscription(v_acc);

  select * into p from public.daily_packs where student_id = v_st and day = v_day;
  if p.student_id is null then
    --  Abunesiz hesabda paket QURULMUR - sual sizmasin.  Sayğac ve
    --  movzu adlari asagida ayrica gelir (usaq ne itirdiyini gorur).
    insert into public.daily_packs (student_id, day, items)
    values (v_st, v_day, case when v_paid then app.daily_build(v_st) else '[]'::jsonb end)
    on conflict (student_id, day) do nothing;
    select * into p from public.daily_packs where student_id = v_st and day = v_day;
  elsif v_paid and jsonb_array_length(p.items) = 0 and p.done_at is null then
    --  abune gun icinde acildi - paketi indi qur
    update public.daily_packs set items = app.daily_build(v_st)
     where student_id = v_st and day = v_day and jsonb_array_length(items) = 0;
    select * into p from public.daily_packs where student_id = v_st and day = v_day;
  end if;

  v_n := jsonb_array_length(p.items);
  v_i := jsonb_array_length(p.answers);
  if v_n > 0 and v_i >= v_n and p.done_at is null then
    update public.daily_packs set done_at = now()
     where student_id = v_st and day = v_day;
    p.done_at := now();
  end if;
  v_cur := case when v_i < v_n then p.items->v_i else null end;

  return jsonb_build_object(
    'paid',  v_paid,
    'day',   v_day,
    'total', v_n,
    'i',     v_i,
    'ok',    (select count(*) from jsonb_array_elements(p.answers) a
               where (a->>'ok')::boolean),
    'done',  v_n > 0 and v_i >= v_n,
    --  «Muellimin kecdiyi Kəsrlər və Faizlər uzre ferdi tekrar»
    'topics', coalesce((
      select jsonb_agg(y.name order by y.at desc)
        from (select t.name, z.at from app.daily_topics(v_st) z
                join public.topics t on t.id = z.topic_id
               order by z.at desc nulls last limit 2) y), '[]'::jsonb),
    --  plan hec isarelenmeyibse UI muellime isare eden setir yazir
    'src', (select z.src from app.daily_topics(v_st) z limit 1),
    --  «Dunen 3/5 -> bu gun 4/5» - sexsi irelileyis, reytinq yox
    'yesterday', (
      select case when jsonb_array_length(d.answers) = 0 then null else
               jsonb_build_object(
                 'total', jsonb_array_length(d.items),
                 'ok', (select count(*) from jsonb_array_elements(d.answers) a
                         where (a->>'ok')::boolean)) end
        from public.daily_packs d
       where d.student_id = v_st and d.day = v_day - 1),
    --  bitmis paketin movzu-movzu hesabati
    'result', case when not (v_n > 0 and v_i >= v_n) then null else coalesce((
      select jsonb_agg(jsonb_build_object('topic', x.tp, 'ok', x.ok, 'n', x.n)
                       order by x.n desc, x.tp)
        from (select coalesce(nullif(a->>'topic', ''), 'Digər') tp,
                     count(*) n,
                     count(*) filter (where (a->>'ok')::boolean) ok
                from jsonb_array_elements(p.answers) a
               group by 1) x), '[]'::jsonb) end,
    'question', case when v_cur is null then null else (
      select jsonb_build_object(
               'id',   q.id,
               'src',  v_cur->>'src',
               'topic', v_cur->>'topic',
               'body', app.pq_render(q.body, v_cur->'params'),
               'media_url', q.media_url,
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object(
                          'id', o.id, 'body', app.pq_render(o.body, v_cur->'params'))
                        order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
        from public.questions q where q.id = (v_cur->>'q')::uuid) end);
end $$;
revoke all on function public.rpc_student_daily(text) from public;
grant execute on function public.rpc_student_daily(text) to anon, authenticated;

-- ---------------------------------------------------------------------
--  Sagird: cavab.  Yalniz NOVBETI suala - sira serverdedir.
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_daily_answer(
  p_token text, p_question_id uuid, p_option_id uuid)
returns jsonb
language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  v_day  date := (now() at time zone 'Asia/Baku')::date;
  p      public.daily_packs%rowtype;
  v_n    int;
  v_i    int;
  v_cur  jsonb;
  v_ok   boolean;
  v_exp  text;
  v_m    public.mistakes%rowtype;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  if not app.has_active_subscription(
       (select account_id from public.students where id = v_st)) then
    raise exception 'Gundelik tekrar abune paketine daxildir.' using errcode = '42501';
  end if;

  select * into p from public.daily_packs where student_id = v_st and day = v_day for update;
  v_n := coalesce(jsonb_array_length(p.items), 0);
  v_i := coalesce(jsonb_array_length(p.answers), 0);
  if v_n = 0 or v_i >= v_n then
    raise exception 'Bugünkü təkrar bitdi.' using errcode = '22023';
  end if;
  v_cur := p.items->v_i;
  if (v_cur->>'q')::uuid <> p_question_id then
    raise exception 'Bu sual artıq cavablanıb — səhifəni yenilə.' using errcode = '22023';
  end if;

  select o.is_correct into v_ok from public.question_options o
   where o.id = p_option_id and o.question_id = p_question_id;
  if v_ok is null then
    raise exception 'Variant tapilmadi.' using errcode = '22023';
  end if;
  select app.pq_render(coalesce(q.explanation, ''), v_cur->'params')
    into v_exp from public.questions q where q.id = p_question_id;

  --  Sehv defterine test kimi DEYIL, mesq kimi yazilir: sehv cavab
  --  SABAHA qalir, bu gunun paketinde bir de cixmir.
  perform app.mistake_note(v_st, p_question_id, v_ok, true);
  select * into v_m from public.mistakes
   where student_id = v_st and question_id = p_question_id;

  update public.daily_packs
     set answers = p.answers || jsonb_build_object(
                     'q', p_question_id, 'ok', v_ok, 'topic', v_cur->>'topic'),
         done_at = case when v_i + 1 >= v_n then now() else done_at end
   where student_id = v_st and day = v_day;

  return jsonb_build_object(
    'correct', v_ok,
    'explanation', v_exp,
    'closed', v_m.status = 'closed',
    'i', v_i + 1, 'total', v_n,
    'done', v_i + 1 >= v_n,
    'ok', (select count(*) from public.daily_packs d,
                  jsonb_array_elements(d.answers) a
            where d.student_id = v_st and d.day = v_day and (a->>'ok')::boolean));
end $$;
revoke all on function public.rpc_student_daily_answer(text, uuid, uuid) from public;
grant execute on function public.rpc_student_daily_answer(text, uuid, uuid) to anon, authenticated;
