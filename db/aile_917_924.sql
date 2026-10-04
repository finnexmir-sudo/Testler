-- =====================================================================
--  aile_917_924.sql : 917-924 bir faylda (Supabase SQL Editor-e BIR DEFE yapisdirmaq ucun)
--  Siralama vacibdir (hər biri evvelkinin funksiyasini genisledir).  Hamisi tekrar isledile biler.
--  Sonra canli_yoxla.sql ile 917-924 setirlerinin hamisi true olmali.
-- =====================================================================

-- >>>>>>>>>> 917_aile_mesq.sql
-- =====================================================================
--  917 : AILE YOLU - gundelik mesq + menimseme (2026-10-06)
--
--  Muellimsiz yolda «bu gun neyi mesq edek?» sualina cavab:
--   * paketin olcusu usagin sechdiyi gundelik vaxtdan gelir
--     (5/10/15/20/30 deq -> 5/10/14/18/24 sual);
--   * movzu dairesi = valideynin «Hazirda hansi fesildesiniz?» ile kecilmis fesiller (916);
--   * her cavab topic_events jurnalina yazilir; movzu MENIMSENIR eger
--     son 10 cavabdan >=8 duzdur, >=2 ferqli gunde, >=6 ferqli sualla;
--   * menimsenilen movzu tekrara duser: 3 -> 7 -> 21 -> 45 gun.  Tekrarda
--     2 suldan ikisi duz = novbeti merhele; biri sehvdirse 3 gunden sonra yeniden;
--     ikisi de sehvdirse bir merhele geri (1-ci merhelede -> yeniden «oyrenilir»);
--   * paketin terkibi: tekrar (vaxti catanlar) + sehv defteri (<=2) + cari fesil/oyrenilen
--     movzular (hamisindan novbe ile, bir movzudan <=3 sual).
--  Muellim yolu (classic) deyismir: daily_build artiq yalniz yonlendiricidir.
--  Statistika kod ile hesablanir; usaq melumati hec yere paylasilmir.
--  Tekrar isledile biler.
-- =====================================================================

create table if not exists public.topic_events (
  id          bigint generated always as identity primary key,
  student_id  uuid not null references public.students(id) on delete cascade,
  topic_id    uuid not null references public.topics(id)   on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  ok          boolean not null,
  src         text,
  at          timestamptz not null default now()
);
create index if not exists idx_topic_events_st on public.topic_events (student_id, topic_id, at desc);
alter table public.topic_events enable row level security;
revoke all on public.topic_events from public, anon, authenticated;

create table if not exists public.topic_mastery (
  student_id  uuid not null references public.students(id) on delete cascade,
  topic_id    uuid not null references public.topics(id)   on delete cascade,
  state       text not null default 'learning' check (state in ('learning', 'mastered')),
  stage       smallint not null default 0,
  mastered_at timestamptz,
  due_at      timestamptz,
  updated_at  timestamptz not null default now(),
  primary key (student_id, topic_id)
);
create index if not exists idx_topic_mastery_due on public.topic_mastery (student_id, state, due_at);
alter table public.topic_mastery enable row level security;
revoke all on public.topic_mastery from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Bir cavabin menimsemeye tesiri
-- ---------------------------------------------------------------------
create or replace function app.mastery_note(p_student uuid, p_topic uuid, p_q uuid, p_ok boolean, p_src text)
returns void
language plpgsql as $$
declare
  m     public.topic_mastery%rowtype;
  v_n   int;
  v_c   int;
  v_d   int;
  v_qs  int;
  v_iv  int[] := array[3, 7, 21, 45];
  v_st  smallint;
begin
  if p_ok is null then return; end if;
  insert into public.topic_events (student_id, topic_id, question_id, ok, src)
  values (p_student, p_topic, p_q, p_ok, p_src);
  insert into public.topic_mastery (student_id, topic_id) values (p_student, p_topic)
  on conflict do nothing;
  select * into m from public.topic_mastery where student_id = p_student and topic_id = p_topic for update;

  if m.state = 'learning' then
    select count(*), count(*) filter (where e.ok), count(distinct (e.at at time zone 'Asia/Baku')::date), count(distinct e.question_id)
      into v_n, v_c, v_d, v_qs
      from (select * from public.topic_events
             where student_id = p_student and topic_id = p_topic
             order by at desc, id desc limit 10) e;
    if v_n >= 10 and v_c >= 8 and v_d >= 2 and v_qs >= 6 then
      update public.topic_mastery
         set state = 'mastered', stage = 1, mastered_at = now(),
             due_at = now() + make_interval(days => v_iv[1]), updated_at = now()
       where student_id = p_student and topic_id = p_topic;
    end if;
  elsif p_src = 'tekrar' and m.due_at is not null and m.due_at <= now() then
    select count(*), count(*) filter (where e.ok) into v_n, v_c
      from public.topic_events e
     where e.student_id = p_student and e.topic_id = p_topic and e.src = 'tekrar' and e.at >= m.due_at;
    if v_n >= 2 then
      if v_c = v_n then                                   -- ikisi de duz: novbeti merhele
        v_st := least(m.stage + 1, 4);
        update public.topic_mastery set stage = v_st, due_at = now() + make_interval(days => v_iv[v_st]), updated_at = now()
         where student_id = p_student and topic_id = p_topic;
      elsif v_c = 0 then                                  -- ikisi de sehv: bir merhele geri
        if m.stage <= 1 then
          update public.topic_mastery set state = 'learning', stage = 0, mastered_at = null, due_at = null, updated_at = now()
           where student_id = p_student and topic_id = p_topic;
        else
          update public.topic_mastery set stage = m.stage - 1, due_at = now() + interval '1 day', updated_at = now()
           where student_id = p_student and topic_id = p_topic;
        end if;
      else                                                -- yarimcliq: merhele eynidir, 3 gunden sonra yeniden
        update public.topic_mastery set due_at = now() + interval '3 days', updated_at = now()
         where student_id = p_student and topic_id = p_topic;
      end if;
    end if;
  end if;
end $$;
revoke all on function app.mastery_note(uuid, uuid, uuid, boolean, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Paket qurucusu: muellim yolu (classic) + aile yolu
-- ---------------------------------------------------------------------
do $$
begin
  if to_regprocedure('app.daily_build_classic(uuid)') is null then
    alter function app.daily_build(uuid) rename to daily_build_classic;
  end if;
end $$;

create or replace function app.daily_build_family(p_student uuid)
returns jsonb
language plpgsql volatile as $$
declare
  v_min  int;
  v_n    int;
  v_acc  uuid;
  v_lvl  uuid;
  v_cov  uuid[];
  v_cur  uuid[];
  v_it   jsonb  := '[]'::jsonb;
  v_used uuid[] := '{}';
  v_q    uuid;
  v_t    uuid;
  r      record;
  k      int;
  v_e    int;
  v_tg   int;
begin
  select fk.minutes into v_min from public.family_kids fk where fk.student_id = p_student;
  v_n := case v_min when 5 then 5 when 10 then 10 when 15 then 14 when 20 then 18 when 30 then 24 else 10 end;
  select s.account_id, c.level_id into v_acc, v_lvl
    from public.students s left join public.classes c on c.id = s.class_id
   where s.id = p_student;

  v_cov := array(select z.topic_id from app.daily_topics(p_student) z);
  if coalesce(cardinality(v_cov), 0) = 0 then
    return '[]'::jsonb;
  end if;
  --  her fennin cari fesli: planda en son kecilmis movzunun fesli
  v_cur := array(select distinct on (p.id) coalesce(t.parent_id, t.id)
                   from public.class_plan_items i
                   join public.class_plans p on p.id = i.plan_id
                   join public.students st on st.class_id = p.class_id and st.id = p_student
                   join public.topics t on t.id = i.topic_id
                  where i.done_at is not null
                  order by p.id, i.ord desc);

  -- 1) TEKRAR: vaxti catan menimsenilmis movzular (movzu basina 2 sual)
  for r in select m.topic_id from public.topic_mastery m
            where m.student_id = p_student and m.state = 'mastered' and m.due_at <= now()
              and m.topic_id = any(v_cov)
            order by m.due_at limit greatest(1, v_n / 4) loop
    for k in 1..2 loop
      v_q := null;
      select x.id into v_q from app.daily_pool(r.topic_id, v_lvl, v_acc) x
       where not (x.id = any(v_used)) order by random() limit 1;
      exit when v_q is null;
      v_it := v_it || (app.daily_item(v_q, 'tekrar') || jsonb_build_object('tid', r.topic_id));
      v_used := v_used || v_q;
    end loop;
  end loop;

  -- 2) SEHV defteri: en cox 2 (kecilmis movzulardan)
  for k in 1..2 loop
    exit when jsonb_array_length(v_it) >= v_n;
    v_q := null; v_t := null;
    select m.question_id, q.topic_id into v_q, v_t
      from public.mistakes m
      join public.questions q on q.id = m.question_id and q.status = 'published' and q.kind = 'single'
     where m.student_id = p_student and m.status <> 'closed' and m.next_at <= now()
       and q.topic_id = any(v_cov) and not (m.question_id = any(v_used))
     order by (m.status = 'open') desc, m.first_at limit 1;
    exit when v_q is null;
    v_it := v_it || (app.daily_item(v_q, 'sehv') || jsonb_build_object('tid', v_t));
    v_used := v_used || v_q;
  end loop;

  -- 3) OYRENILEN movzular: cari fesil evvel, sonra en az calisilan; bir movzudan <=3 sual
  while jsonb_array_length(v_it) < v_n loop
    v_t := null;
    select c.tid into v_t
      from unnest(v_cov) as c(tid)
      left join public.topic_mastery m on m.student_id = p_student and m.topic_id = c.tid
     where coalesce(m.state, 'learning') = 'learning'
       and (select count(*) from jsonb_array_elements(v_it) e where e->>'tid' = c.tid::text) < 3
       and exists (select 1 from app.daily_pool(c.tid, v_lvl, v_acc) x where not (x.id = any(v_used)))
     order by (select count(*) from jsonb_array_elements(v_it) e where e->>'tid' = c.tid::text),
              (c.tid = any(v_cur)) desc,
              (select max(ev.at) from public.topic_events ev where ev.student_id = p_student and ev.topic_id = c.tid) asc nulls first,
              random()
     limit 1;
    exit when v_t is null;
    select count(*) into v_e from public.topic_events ev where ev.student_id = p_student and ev.topic_id = v_t;
    v_tg := case when v_e < 4 then 1 when v_e < 8 then 2 else 3 end;
    v_q := null;
    select x.id into v_q from app.daily_pool(v_t, v_lvl, v_acc) x
     where not (x.id = any(v_used))
     order by exists (select 1 from public.topic_events ev where ev.student_id = p_student and ev.question_id = x.id),
              abs(x.difficulty - v_tg), random()
     limit 1;
    exit when v_q is null;
    v_it := v_it || (app.daily_item(v_q, case when v_t = any(v_cur) then 'cari' else 'mesq' end) || jsonb_build_object('tid', v_t));
    v_used := v_used || v_q;
  end loop;

  -- 4) hele bosdursa: menimsenilmis movzulardan elave (tekrar sayilmir)
  while jsonb_array_length(v_it) < v_n loop
    v_q := null; v_t := null;
    select x.id, c.tid into v_q, v_t
      from unnest(v_cov) as c(tid)
      join lateral app.daily_pool(c.tid, v_lvl, v_acc) x on true
     where not (x.id = any(v_used))
     order by random() limit 1;
    exit when v_q is null;
    v_it := v_it || (app.daily_item(v_q, 'elave') || jsonb_build_object('tid', v_t));
    v_used := v_used || v_q;
  end loop;

  if jsonb_array_length(v_it) < 3 then
    return '[]'::jsonb;
  end if;
  return v_it;
end $$;
revoke all on function app.daily_build_family(uuid) from public, anon, authenticated;

create or replace function app.daily_build(p_student uuid)
returns jsonb
language plpgsql volatile as $$
begin
  if exists (select 1 from public.family_kids fk where fk.student_id = p_student) then
    return app.daily_build_family(p_student);
  end if;
  return app.daily_build_classic(p_student);
end $$;
revoke all on function app.daily_build(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Valideyn ucun irelileyis (usaq basina): menimsenilen, cari fesiller
-- ---------------------------------------------------------------------
create or replace function public.rpc_family_progress()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', st.id,
             'mastered', (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered'),
             'learning',  (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'learning'),
             'due',       (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered' and m.due_at <= now()),
             'cur', coalesce((
               select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
                 from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                         from public.class_plan_items i
                         join public.class_plans p on p.id = i.plan_id and p.class_id = st.class_id
                         join public.subjects sb on sb.id = p.subject_id
                         join public.topics t on t.id = i.topic_id
                         left join public.topics par on par.id = t.parent_id
                        where i.done_at is not null
                        order by p.id, i.ord desc) y), '[]'::jsonb))
             order by st.created_at)
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.account_id = v_acc and st.is_active), '[]'::jsonb);
end $$;
revoke all on function public.rpc_family_progress() from public, anon;
grant execute on function public.rpc_family_progress() to authenticated;

-- ---------------------------------------------------------------------
--  212-den kopya: rpc_student_daily ('family' bayragi ile) ve
--  rpc_student_daily_answer (aile usagi ucun menimseme jurnalina yazir)
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
    'family', exists (select 1 from public.family_kids fk where fk.student_id = v_st),
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

  --  Ailə yolu: cavab mənimsəmə jurnalına da yazılır
  if exists (select 1 from public.family_kids fk where fk.student_id = v_st) then
    declare v_tp uuid;
    begin
      v_tp := coalesce(nullif(v_cur->>'tid', '')::uuid,
                       (select coalesce(t.parent_id, t.id) from public.questions q
                          join public.topics t on t.id = q.topic_id where q.id = p_question_id));
      if v_tp is not null then
        perform app.mastery_note(v_st, v_tp, p_question_id, v_ok, v_cur->>'src');
      end if;
    end;
  end if;
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

-- >>>>>>>>>> 918_aile_afarin_xulase.sql
-- =====================================================================
--  918 : AILE YOLU - «Aferin gonder» + heftelik xulase push (2026-10-06)
--
--  1. rpc_family_praise(usaq, 1..3) : valideyn hazir 3 mesajdan birini gonderir (serbest yazi YOXDUR).
--       * gunde 1 defe (usaq basina); mesaj usagin gundelik kartinda 2 gun gorunur
--         (telefonunda bildiris acilmasa da) + bildiris acilibsa push gedir;
--  2. Heftelik xulase: Bazar gunu 18:00-21:00 (Baki), hesab basina BIR push
--       «Lale: 4 gun, 62 sual (71 % duz), 1 movzu menimsedi.»
--       Yalniz bildiris acan ve usaqlari olan ailelere; hefte basina bir defe (dedupe).
--  3. rpc_family_push_subscribe/unsubscribe : valideyn «Ailem» ekranindan BIR toxunusla butun usaqlar ucun
--       bu cihazi yazdirir (usaq elave edilende cihaz yeniden sinxronlasdirilir).
--  Usaq melumati yalniz valideynin ozune gedir - heç yerde paylasilmir.
--  ON SERT: 910-917.   Tekrar isledile biler.
-- =====================================================================

create table if not exists public.family_praise (
  id         bigint generated always as identity primary key,
  student_id uuid not null references public.students(id) on delete cascade,
  msg        text not null,
  at         timestamptz not null default now()
);
create index if not exists idx_family_praise_st on public.family_praise (student_id, at desc);
alter table public.family_praise enable row level security;
revoke all on public.family_praise from public, anon, authenticated;

create or replace function public.rpc_family_praise(p_student uuid, p_kind int)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_acc  uuid;
  v_msgs text[] := array['Afərin! Bu gün yaxşı çalışdın 👏', 'Səninlə fəxr edirəm 💚', 'Davam et, çox yaxşı gedir!'];
  v_msg  text;
  v_day  date := (now() at time zone 'Asia/Baku')::date;
  v_id   bigint;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if p_kind is null or p_kind < 1 or p_kind > 3 then
    raise exception 'Mesaj seçin.' using errcode = '22023';
  end if;
  if exists (select 1 from public.family_praise fp
              where fp.student_id = p_student and (fp.at at time zone 'Asia/Baku')::date = v_day) then
    raise exception 'Bu gün artıq «Afərin» göndərmisiniz.' using errcode = '22023';
  end if;
  v_msg := v_msgs[p_kind];
  insert into public.family_praise (student_id, msg) values (p_student, v_msg);

  v_id := app.push_enqueue('student', p_student, 'afarin', 'afarin:' || p_student || ':' || v_day,
                           'Valideynindən mesaj', v_msg, null, 5);
  return jsonb_build_object('ok', true, 'push', v_id is not null);
end $$;
revoke all on function public.rpc_family_praise(uuid, int) from public, anon;
grant execute on function public.rpc_family_praise(uuid, int) to authenticated;

-- ------------------------------------------------ valideyn cihazi: butun usaqlar ucun
create or replace function public.rpc_family_push_subscribe(
  p_endpoint text, p_p256dh text, p_auth text, p_ua text default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  r     record;
  v_n   int := 0;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  if not app.push_host_ok(p_endpoint) then
    raise exception 'Bildiriş ünvanı tanınmadı.' using errcode = '22023';
  end if;
  if p_p256dh is null or length(p_p256dh) not between 40 and 200
     or p_auth is null or length(p_auth) not between 10 and 100 then
    raise exception 'Bildiriş açarları yanlışdır.' using errcode = '22023';
  end if;
  for r in select st.id from public.students st
            join public.family_kids fk on fk.student_id = st.id
           where st.account_id = v_acc and st.is_active loop
    if not exists (select 1 from public.push_subs where endpoint = p_endpoint and student_id = r.id and role = 'parent')
       and (select count(*) from public.push_subs where student_id = r.id and role = 'parent') >= 10 then
      delete from public.push_subs
       where id = (select id from public.push_subs where student_id = r.id and role = 'parent'
                    order by coalesce(last_ok_at, created_at) limit 1);
    end if;
    insert into public.push_subs (role, student_id, endpoint, p256dh, auth, ua)
    values ('parent', r.id, p_endpoint, p_p256dh, p_auth, left(p_ua, 200))
    on conflict (endpoint, student_id, role)
    do update set p256dh = excluded.p256dh, auth = excluded.auth, ua = excluded.ua, fail_count = 0;
    v_n := v_n + 1;
  end loop;
  return jsonb_build_object('ok', true, 'kids', v_n);
end $$;
revoke all on function public.rpc_family_push_subscribe(text, text, text, text) from public, anon;
grant execute on function public.rpc_family_push_subscribe(text, text, text, text) to authenticated;

create or replace function public.rpc_family_push_unsubscribe(p_endpoint text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_n   int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  delete from public.push_subs ps
   using public.students st
   where ps.student_id = st.id and st.account_id = v_acc and ps.role = 'parent' and ps.endpoint = p_endpoint;
  get diagnostics v_n = row_count;
  return jsonb_build_object('ok', true, 'removed', v_n);
end $$;
revoke all on function public.rpc_family_push_unsubscribe(text) from public, anon;
grant execute on function public.rpc_family_push_unsubscribe(text) to authenticated;

-- ------------------------------------------------ heftelik xulase (Bazar 18:00-21:00)
--  p_now yalniz testler ucun.  Hefte = bazar ertesi..bazar (Baki).
create or replace function app.push_scan_weekly(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r      record;
  k      record;
  v_n    int := 0;
  v_id   bigint;
  v_h    int  := extract(hour from (p_now at time zone 'Asia/Baku'))::int;
  v_day  date := (p_now at time zone 'Asia/Baku')::date;
  v_mon  date := ((p_now at time zone 'Asia/Baku')::date) - (extract(isodow from (p_now at time zone 'Asia/Baku'))::int - 1);
  v_from timestamptz;
  v_body text;
  v_part text;
  v_days int; v_q int; v_ok int; v_ms int;
begin
  if not app.push_on() then return 0; end if;
  if extract(isodow from (p_now at time zone 'Asia/Baku')) <> 7 or v_h < 18 or v_h >= 21 then return 0; end if;
  v_from := (v_mon::timestamp) at time zone 'Asia/Baku';

  --  hesab basina bir setir: usaqlari var ve bu cihazlar valideyn bildirisi acib
  for r in
    select st.account_id as acc, (array_agg(st.id order by st.created_at))[1] as first_sid
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.is_active
       and exists (select 1 from public.push_subs s where s.student_id = st.id and s.role = 'parent')
     group by st.account_id
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      v_body := '';
      for k in select st.id, st.display_name nm from public.students st
                 join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        select count(distinct e.d), coalesce(sum(e.q), 0), coalesce(sum(e.ok), 0)
          into v_days, v_q, v_ok
          from (
            select (aa.answered_at at time zone 'Asia/Baku')::date d, 1 q, case when aa.is_correct then 1 else 0 end ok
              from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
             where a.student_id = k.id and aa.answered_at >= v_from and aa.answered_at < v_from + interval '7 days'
            union all
            select dp.day, jsonb_array_length(dp.answers),
                   (select count(*) from jsonb_array_elements(dp.answers) x where (x->>'ok')::boolean)::int
              from public.daily_packs dp
             where dp.student_id = k.id and dp.day >= v_mon and dp.day < v_mon + 7 and jsonb_array_length(dp.answers) > 0
          ) e where e.q > 0;
        select count(*) into v_ms from public.topic_mastery m
         where m.student_id = k.id and m.state = 'mastered' and m.mastered_at >= v_from;
        if v_q = 0 then
          v_part := k.nm || ': bu həftə çalışmayıb';
        else
          v_part := k.nm || ': ' || v_days || ' gün, ' || v_q || ' sual (' || round(v_ok * 100.0 / v_q) || ' % düz)'
                    || case when v_ms > 0 then ', ' || v_ms || ' mövzu mənimsədi' else '' end;
        end if;
        v_body := v_body || case when v_body = '' then '' else '. ' end || v_part;
      end loop;
      if v_body = '' then continue; end if;

      v_id := app.push_enqueue('parent', r.first_sid, 'hefte', 'hefte:' || r.acc || ':' || v_mon,
                               'Həftənin xülasəsi', v_body || '.', null, 5);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push heftelik: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;
revoke all on function app.push_scan_weekly(timestamptz) from public, anon, authenticated;

create or replace function app.push_tick() returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_d int := 0;
  v_g int := 0;
  v_w int := 0;
begin
  if not app.push_on() then return jsonb_build_object('on', false); end if;
  begin v_d := app.push_scan_deadlines(); exception when others then raise warning 'push tick son tarix: %', sqlerrm; end;
  begin v_g := app.push_scan_daily();     exception when others then raise warning 'push tick gundelik: %', sqlerrm; end;
  begin v_w := app.push_scan_weekly();    exception when others then raise warning 'push tick heftelik: %', sqlerrm; end;
  begin perform app.push_cleanup();       exception when others then raise warning 'push tick temizlik: %', sqlerrm; end;
  return jsonb_build_object('on', true, 'son_tarix', v_d, 'gundelik', v_g, 'heftelik', v_w);
end $$;
revoke all on function app.push_tick() from public, anon, authenticated;

-- ------------------------------------------------ sagird: gundelik kart + «Aferin»
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
    'family', exists (select 1 from public.family_kids fk where fk.student_id = v_st),
    --  valideynin «Aferin»i (son 2 gun) - bildiris getmese de usaq gorsun
    'praise', (select fp.msg from public.family_praise fp
                where fp.student_id = v_st and fp.at > now() - interval '2 days'
                order by fp.at desc limit 1),
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

-- ------------------------------------------------ gundelik push basligi: ailede sual sayi deyisir
create or replace function app.push_scan_daily(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r     record;
  v_n   int := 0;
  v_id  bigint;
  v_h   int  := extract(hour from (p_now at time zone 'Asia/Baku'))::int;
  v_day date := (p_now at time zone 'Asia/Baku')::date;
begin
  if not app.push_on() then return 0; end if;
  if v_h < 19 or v_h >= 21 then return 0; end if;

  for r in
    select st.id as sid, st.account_id as acc
      from public.students st
     where st.is_active
       and exists (select 1 from public.push_subs s where s.student_id = st.id and s.role = 'student')
       --  bu gun paketi bitirmeyib (paket yoxdur, ve ya yarimcigdir)
       and not exists (select 1 from public.daily_packs dp
                        where dp.student_id = st.id and dp.day = v_day
                          and (dp.done_at is not null
                               or (jsonb_array_length(dp.items) > 0
                                   and jsonb_array_length(dp.answers) >= jsonb_array_length(dp.items))))
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      if not app.has_active_subscription(r.acc) then continue; end if;    -- abunesizde paket qurulmur (212)
      if not exists (select 1 from app.daily_topics(r.sid)) then continue; end if;   -- hele kecilmis movzu yoxdur

      v_id := app.push_enqueue('student', r.sid, 'gundelik', 'gun:' || r.sid || ':' || v_day,
        case when exists (select 1 from public.family_kids fk where fk.student_id = r.sid)
             then 'Bu günün məşqi hazırdır' else 'Bu günün 5 sualı hazırdır' end,
        'Cəmi bir neçə dəqiqə — bu gün hələ çalışmamısan.',
        null);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push gundelik: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;
revoke all on function app.push_scan_daily(timestamptz) from public, anon, authenticated;

-- >>>>>>>>>> 919_aile_seansli_yoxlama.sql
-- =====================================================================
--  919 : AILE YOLU - SEANSLI BASLANGIC YOXLAMA (2026-10-06)
--
--  Evvel: bir fenn = bir test = sinfin BUTUN fesillerinden 3 sual (24-36 sual).  Iki problem:
--    * bir oturumda cox uzun (usaq yorulur, tesadufi cavab verir - «Diqqet» 21 %-e dusurdu);
--    * hele KECILMEMIS fesillerden sual verilirdi - zeif netice yalan idi.
--  Indi: bir fenn = bir SERIYA (run) = bir nece HISSE (seans), her hisse <=5 fesil x 3 sual = 15 sual (~15-20 deq).
--    Seriyanin fesilleri: evvelki sinfin (N-1) BUTUN fesilleri + bu sinfin (N) ILK ucde biri (en azi 2) -
--    usagin bildiyi + indi kecdiyi materyal.  Siya ilk hissede gen_rule-da saxlanir (kitab bankasi deyisse seriya pozulmasin).
--    Valideyn her hisseni «Novbeti hisse ver» ile ozu verir (usaq bezmesin); netice hisseler uzre BIRLESIR:
--    «Diqqet» movzu uzre cavablari birlikde sayir (915), ayrica birlesdirme lazim deyil.
--  rpc_family_children: her fenn ucun state = none | open | partial | done  + done/of (hisse sayi).
--  Muellim yolu (rpc_diagnostic_create) deyismir.
--  ON SERT: 913-918.   Tekrar isledile biler.
-- =====================================================================

create or replace function app.family_diag_state(p_student uuid, p_subject uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_g    jsonb;
  v_run  text;
  v_of   int;
  v_done int;
  v_open boolean;
begin
  select t.gen_rule into v_g
    from public.assignments a join public.tests t on t.id = a.test_id
   where a.student_id = p_student and t.is_diagnostic and t.subject_id = p_subject
   order by a.created_at desc limit 1;
  if v_g is null then
    return jsonb_build_object('state', 'none');
  end if;
  v_run := v_g->>'run';
  if v_run is null then                        -- kohne, tek hisseli yoxlama
    if exists (select 1 from public.attempts at join public.tests t on t.id = at.test_id
                where at.student_id = p_student and t.is_diagnostic and t.subject_id = p_subject and at.status = 'submitted') then
      return jsonb_build_object('state', 'done', 'done', 1, 'of', 1);
    end if;
    return jsonb_build_object('state', 'open', 'done', 0, 'of', 1);
  end if;
  v_of := coalesce((v_g->>'of')::int, 1);
  select count(distinct t.id) into v_done
    from public.attempts at join public.tests t on t.id = at.test_id
   where at.student_id = p_student and t.is_diagnostic and t.gen_rule->>'run' = v_run and at.status = 'submitted';
  select exists (select 1 from public.assignments a join public.tests t on t.id = a.test_id
                  where a.student_id = p_student and t.is_diagnostic and t.subject_id = p_subject
                    and app.assignment_open(a.*)
                    and not exists (select 1 from public.attempts at where at.test_id = t.id and at.student_id = p_student and at.status = 'submitted'))
    into v_open;
  return jsonb_build_object('state', case when v_done >= v_of then 'done' when v_open then 'open' else 'partial' end,
                            'done', v_done, 'of', v_of);
end $$;
revoke all on function app.family_diag_state(uuid, uuid) from public, anon, authenticated;

create or replace function app.family_diag_session(p_student uuid, p_subject text, p_days int default 14)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid    uuid := auth.uid();
  v_st     public.students%rowtype;
  v_class  public.classes%rowtype;
  v_lev    public.levels%rowtype;
  v_prev   public.levels%rowtype;
  v_subj   public.subjects%rowtype;
  v_acc    uuid;
  v_open   uuid;
  v_g      jsonb;
  v_run    text;
  v_topics uuid[] := '{}';
  v_cur    uuid[];
  v_of     int;
  v_done   int;
  v_seq    int;
  v_chunk  uuid[];
  v_ids    uuid[] := '{}';
  v_pick   uuid[];
  v_any    uuid[];
  v_tid    uuid;
  v_code   text;
  d        int;
  i        int;
  v_n      int := 0;
  v_test   uuid;
  v_close  timestamptz;
  v_title  text;
  c_per    constant int := 5;          -- bir hissede fesil sayi (5 x 3 = 15 sual)
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.can_read_student(p_student) then
    raise exception 'Bu sagirde giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student;
  if v_st.class_id is null then
    raise exception 'Şagird heç bir qrupda deyil.' using errcode = '22023';
  end if;
  select * into v_class from public.classes where id = v_st.class_id;
  if v_class.level_id is null then
    raise exception 'Sinif seçilməyib.' using errcode = '22023';
  end if;
  v_acc := v_st.account_id;
  if not app.has_active_subscription(v_acc) then
    raise exception 'Diaqnostik test platformanin sual bankindan yigilir - abune paketine daxildir.' using errcode = '42501';
  end if;
  if p_days is null or p_days < 1 or p_days > 60 then
    raise exception 'Muddet 1-60 gun araliginda olmalidir.' using errcode = '22023';
  end if;
  select * into v_subj from public.subjects where slug = p_subject;
  if not found then
    raise exception 'Fenn tapilmadi.' using errcode = '22023';
  end if;
  select * into v_lev from public.levels where id = v_class.level_id;

  --  Acıq, hele yazilmamis hisse varsa DUBLIKAT yaratma - onu qaytar
  select t.id into v_open
    from public.tests t join public.assignments a on a.test_id = t.id and a.student_id = v_st.id
   where t.is_diagnostic and t.subject_id = v_subj.id and app.assignment_open(a.*)
     and not exists (select 1 from public.attempts at
                      where at.test_id = t.id and at.student_id = v_st.id and at.status = 'submitted')
   order by a.created_at desc limit 1;
  if v_open is not null then
    select t.gen_rule into v_g from public.tests t where t.id = v_open;
    return jsonb_build_object('test_id', v_open, 'existing', true,
             'questions', (select count(*) from public.test_questions where test_id = v_open),
             'part', coalesce((v_g->>'seq')::int, 1), 'of', coalesce((v_g->>'of')::int, 1),
             'closes_at', (select a.closes_at from public.assignments a
                            where a.test_id = v_open and a.student_id = v_st.id limit 1));
  end if;

  --  Cari seriya (son tapsirilan hisseden)
  select t.gen_rule into v_g
    from public.assignments a join public.tests t on t.id = a.test_id
   where a.student_id = v_st.id and t.is_diagnostic and t.subject_id = v_subj.id and t.gen_rule ? 'run'
   order by a.created_at desc limit 1;

  if v_g is not null then
    v_run := v_g->>'run';
    v_of  := coalesce((v_g->>'of')::int, 1);
    select count(distinct t.id) into v_done
      from public.attempts at join public.tests t on t.id = at.test_id
     where at.student_id = v_st.id and t.is_diagnostic and t.gen_rule->>'run' = v_run and at.status = 'submitted';
    if v_done >= v_of then
      return jsonb_build_object('complete', true, 'part', v_of, 'of', v_of);
    end if;
    v_topics := array(select x::uuid from jsonb_array_elements_text(v_g->'topics') x);
    v_seq := v_done + 1;
  else
    --  Yeni seriya: evvelki sinfin hamisi + bu sinfin ilk ucde biri (en azi 2)
    if v_lev.code ~ '^[0-9]+$' then
      select * into v_prev from public.levels where code = ((v_lev.code::int) - 1)::text order by sort limit 1;
    end if;
    if v_prev.id is not null then
      v_topics := array(select z.topic_id from app.diag_topics(v_subj.id, v_prev.id) z);
    end if;
    v_cur := array(select z.topic_id from app.diag_topics(v_subj.id, v_lev.id) z);
    if coalesce(cardinality(v_cur), 0) > 0 then
      v_topics := v_topics || v_cur[1 : greatest(2, ceil(cardinality(v_cur) / 3.0)::int)];
    end if;
    if coalesce(cardinality(v_topics), 0) = 0 then
      raise exception 'Bu fenn ve sinif ucun kifayet qeder sual yoxdur.' using errcode = '22023';
    end if;
    v_run := gen_random_uuid()::text;
    v_of  := ceil(cardinality(v_topics) / c_per::numeric)::int;
    v_seq := 1;
  end if;

  v_chunk := v_topics[(v_seq - 1) * c_per + 1 : v_seq * c_per];

  --  Her fesilden 3 sual: asan, orta, cetin - varsa; yoxsa ne varsa (fesil oz sinfinin kodu ile)
  foreach v_tid in array coalesce(v_chunk, '{}') loop
    select l.code into v_code from public.topics t join public.levels l on l.id = t.level_id where t.id = v_tid;
    v_pick := '{}';
    for d in 1..3 loop
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_code,
                 'topics', jsonb_build_array(v_tid::text),
                 'difficulty', jsonb_build_array(d::text),
                 'count', 1, 'pool', 'platform'), v_acc);
      if coalesce(array_length(v_any, 1), 0) >= 1 and not (v_any[1] = any(v_pick)) then
        v_pick := v_pick || v_any[1];
      end if;
    end loop;
    if coalesce(array_length(v_pick, 1), 0) < 3 then
      v_any := app.generate_pick(jsonb_build_object(
                 'subject', v_subj.slug, 'level', v_code,
                 'topics', jsonb_build_array(v_tid::text),
                 'count', 6, 'pool', 'platform'), v_acc);
      for i in 1 .. coalesce(array_length(v_any, 1), 0) loop
        exit when coalesce(array_length(v_pick, 1), 0) >= 3;
        if not (v_any[i] = any(v_pick)) then v_pick := v_pick || v_any[i]; end if;
      end loop;
    end if;
    if coalesce(array_length(v_pick, 1), 0) = 3 then
      v_ids := v_ids || v_pick;
      v_n := v_n + 1;
    end if;
  end loop;
  if v_n = 0 then
    raise exception 'Bu fenn ve sinif ucun kifayet qeder sual yoxdur.' using errcode = '22023';
  end if;

  v_close := now() + make_interval(days => p_days);
  v_title := 'Diaqnostika · ' || v_subj.name || ' · ' || v_lev.name
             || case when v_of > 1 then ' · ' || v_seq || '/' || v_of || '-ci hissə' else '' end;
  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title, description,
     status, gen_rule, shuffle_questions, shuffle_options, time_limit_sec,
     max_attempts, pass_percent, is_free, is_diagnostic)
  values ('educator', v_uid, v_lev.program_id, v_subj.id, v_lev.id, v_title,
          'Hər mövzudan 3 sual — hansı mövzudan başlamalı olduğunu göstərir.',
          'published',
          jsonb_build_object('kind', 'diagnostic', 'subject', v_subj.slug, 'level', v_lev.code, 'per_topic', 3,
                             'student', v_st.id, 'run', v_run, 'seq', v_seq, 'of', v_of, 'topics', to_jsonb(v_topics)),
          true, true, 75 * array_length(v_ids, 1), 1, 60, true, true)
  returning id into v_test;

  for i in 1 .. array_length(v_ids, 1) loop
    insert into public.test_questions (test_id, question_id, ord) values (v_test, v_ids[i], i);
  end loop;

  perform public.rpc_assign_test(v_st.class_id, v_test, v_close, 1, v_st.id);

  return jsonb_build_object('test_id', v_test, 'existing', false,
                            'questions', array_length(v_ids, 1), 'topics', v_n,
                            'part', v_seq, 'of', v_of, 'closes_at', v_close, 'title', v_title);
end $$;
revoke all on function app.family_diag_session(uuid, text, int) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  914-den kopya: add_child (ilk 3 fenn ucun 1-ci hisse), children (state/done/of), diag (novbeti hisse)
-- ---------------------------------------------------------------------
create or replace function public.rpc_family_add_child(
  p_name text, p_level_code text, p_subjects text[], p_minutes int default 10, p_consent boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid;
  v_name  text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_subs  text[] := '{}';
  v_s     text;
  v_cls   jsonb;
  v_stu   jsonb;
  v_sid   uuid;
  v_diag  jsonb := '[]'::jsonb;
  v_res   jsonb;
  v_n     int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.family_ok() then
    raise exception 'Bu xidmət hələ açılmayıb. Tezliklə.' using errcode = '42501';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  if coalesce(p_consent, false) is not true then
    raise exception 'Uşağın məlumatlarının saxlanmasına razılıq lazımdır.' using errcode = '22023';
  end if;
  if length(v_name) < 2 or length(v_name) > 60 then
    raise exception 'Uşağın adını yazın (2–60 simvol).' using errcode = '22023';
  end if;
  if coalesce(btrim(p_level_code), '') !~ '^[0-9]{1,2}$'
     or not exists (select 1 from public.levels where code = btrim(p_level_code)) then
    raise exception 'Sinif seçin.' using errcode = '22023';
  end if;
  if p_minutes is null or p_minutes not in (5, 10, 15, 20, 30) then p_minutes := 10; end if;

  --  Fennler: yalniz movcud slug, tekrarsiz, en cox 5
  foreach v_s in array coalesce(p_subjects, '{}') loop
    if exists (select 1 from public.subjects where slug = v_s) and not (v_s = any(v_subs)) then
      v_subs := v_subs || v_s;
    end if;
    exit when array_length(v_subs, 1) >= 12;
  end loop;
  if coalesce(array_length(v_subs, 1), 0) = 0 then
    raise exception 'Ən azı bir fənn seçin.' using errcode = '22023';
  end if;

  select count(*) into v_n from public.students where account_id = v_acc and is_active;
  if v_n >= 6 then
    raise exception 'Bir hesaba ən çox 6 uşaq əlavə olunur.' using errcode = '22023';
  end if;

  --  gizli «self_study» qrup (sinifi ile) + sagird + kodlar (movcud RPC-ler, eyni qaydalar)
  v_cls := public.rpc_create_class(v_acc, v_name, 'self_study', null, btrim(p_level_code));
  v_stu := public.rpc_add_student((v_cls->>'id')::uuid, v_name, split_part(v_name, ' ', 1));      -- gorunen ad: ilk ad (Huseyn)
  v_sid := (v_stu->>'id')::uuid;

  insert into public.consents (student_id, granted_by, kind, evidence)
  values (v_sid, v_uid, 'parental',
          jsonb_build_object('version', 'aile-v3', 'text', 'Usagin adi ve neticeleri yalniz valideyne gorunur, hec yerde paylasilmir. Raziyam.',
                             'at', now(), 'source', 'family_add_child'));

  insert into public.family_kids (student_id, subjects, minutes) values (v_sid, v_subs, p_minutes);

  --  Baslangic diaqnostika: secilen fennlerin ilk 3-u (movcud rpc; alinmasa usaq elave edilmesi pozulmur)
  for v_s in select unnest(v_subs[1:3]) loop
    begin
      v_res := app.family_diag_session(v_sid, v_s, 14);
      v_diag := v_diag || jsonb_build_object('subject', v_s, 'ok', true, 'questions', coalesce(v_res->>'questions', null), 'part', v_res->>'part', 'of', v_res->>'of');
    exception when others then
      v_diag := v_diag || jsonb_build_object('subject', v_s, 'ok', false, 'error', left(sqlerrm, 160));
    end;
  end loop;

  return jsonb_build_object('ok', true, 'student_id', v_sid, 'name', v_stu->>'display_name',
                            'login_code', v_stu->>'login_code', 'diagnostics', v_diag,
                            'subjects_total', coalesce(array_length(v_subs, 1), 0));
end $$;

create or replace function public.rpc_family_children()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    return jsonb_build_object('has_account', false);
  end if;
  return jsonb_build_object(
    'has_account', true,
    'account', (select jsonb_build_object('name', a.name,
                        'locked', app.account_locked(a.id),
                        'active', app.has_active_subscription(a.id),
                        'trial_end', (select max(s.current_period_end) from public.subscriptions s
                                       where s.account_id = a.id and s.status in ('trialing', 'active')))
                  from public.accounts a where a.id = v_acc),
    'kids', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', st.id,
               'name', st.display_name,
               'sinif', (select l.code from public.classes c join public.levels l on l.id = c.level_id where c.id = st.class_id),
               'subjects', coalesce(fk.subjects, '{}'),
               'subject_names', coalesce((select jsonb_agg(sj.name order by sj.sort, sj.name) from public.subjects sj
                                           where sj.slug = any(coalesce(fk.subjects, '{}'))), '[]'::jsonb),
               'minutes', coalesce(fk.minutes, 10),
               'login_code', st.login_code,
               'subject_diag', coalesce((
                   select jsonb_agg(jsonb_build_object('slug', sj.slug, 'name', sj.name) || app.family_diag_state(st.id, sj.id)
                            order by sj.sort, sj.name)
                     from public.subjects sj where sj.slug = any(coalesce(fk.subjects, '{}'))), '[]'::jsonb),
               'diag_total', (select count(*) from public.assignments a join public.tests t on t.id = a.test_id
                               where a.student_id = st.id and t.is_diagnostic),
               'diag_done',  (select count(distinct at.test_id) from public.attempts at join public.tests t on t.id = at.test_id
                               where at.student_id = st.id and t.is_diagnostic and at.status = 'submitted'))
             order by st.created_at, st.id)
        from public.students st
        left join public.family_kids fk on fk.student_id = st.id
       where st.account_id = v_acc and st.is_active), '[]'::jsonb));
end $$;

create or replace function public.rpc_family_diag(p_student uuid, p_subject text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if not exists (select 1 from public.family_kids fk where fk.student_id = p_student and p_subject = any(fk.subjects)) then
    raise exception 'Bu fənn uşaq üçün seçilməyib.' using errcode = '22023';
  end if;
  v_res := app.family_diag_session(p_student, p_subject, 14);
  return jsonb_build_object('ok', true, 'existing', coalesce((v_res->>'existing')::boolean, false),
                            'complete', coalesce((v_res->>'complete')::boolean, false),
                            'questions', v_res->>'questions', 'part', v_res->>'part', 'of', v_res->>'of');
end $$;

revoke all on function public.rpc_family_add_child(text, text, text[], int, boolean) from public, anon;
grant execute on function public.rpc_family_add_child(text, text, text[], int, boolean) to authenticated;
revoke all on function public.rpc_family_children() from public, anon;
grant execute on function public.rpc_family_children() to authenticated;
revoke all on function public.rpc_family_diag(uuid, text) from public, anon;
grant execute on function public.rpc_family_diag(uuid, text) to authenticated;

-- >>>>>>>>>> 920_aile_usaq_sehife.sql
-- =====================================================================
--  920 : AILE YOLU - usagin oz sehifesi (2026-10-06)
--
--  rpc_student_family(token): usaq tetbiqi bunu ana ekran cizilmezden evvel cagirir.
--    family   : bu sagird «Ailem» yolundandirmi (family_kids-de var)
--    minutes  : valideynin sechdiyi gundelik vaxt
--    week/today_i : bu hefte hansi gunlerde calisib (B..B, Baki vaxti; testler + gundelik paket)
--    mastered : menimsedyi movzu sayi (917)
--    cur      : «Hazirda» - her fennin cari fesli (916)
--  Yalniz oz melumati: token usagin ozunundur.  Muellim yolundaki sagird ucun {family:false}.
--  ON SERT: 913-917.   Sonra 05_grants.sql (anon whitelist-e elave olunub).
-- =====================================================================
create or replace function public.rpc_student_family(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    uuid := app.session_student(p_token);
  v_today date := (now() at time zone 'Asia/Baku')::date;
  v_mon   date;
  v_min   int;
  v_cls   uuid;
  v_out   jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select fk.minutes, st.class_id into v_min, v_cls
    from public.family_kids fk join public.students st on st.id = fk.student_id
   where fk.student_id = v_st;
  if not found then
    return jsonb_build_object('family', false);
  end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);

  with ev as (
    select (aa.answered_at at time zone 'Asia/Baku')::date as d
      from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
     where a.student_id = v_st and aa.answered_at >= v_mon - 1
    union all
    select dp.day from public.daily_packs dp
     where dp.student_id = v_st and dp.day >= v_mon and jsonb_array_length(dp.answers) > 0
  )
  select jsonb_build_object(
           'family', true,
           'minutes', coalesce(v_min, 10),
           'today_i', v_today - v_mon,
           'week', (select jsonb_agg(case when exists (select 1 from ev where ev.d = v_mon + g) then 1 else 0 end order by g)
                      from generate_series(0, 6) g),
           'mastered', (select count(*) from public.topic_mastery m where m.student_id = v_st and m.state = 'mastered'),
           'cur', coalesce((
             select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
               from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                       from public.class_plan_items i
                       join public.class_plans p on p.id = i.plan_id and p.class_id = v_cls
                       join public.subjects sb on sb.id = p.subject_id
                       join public.topics t on t.id = i.topic_id
                       left join public.topics par on par.id = t.parent_id
                      where i.done_at is not null
                      order by p.id, i.ord desc) y), '[]'::jsonb))
    into v_out;
  return v_out;
end $$;
revoke all on function public.rpc_student_family(text) from public;
grant execute on function public.rpc_student_family(text) to anon, authenticated;

-- >>>>>>>>>> 921_aile_hedef.sql
-- =====================================================================
--  921 : AILE YOLU - HEFTELIK HEDEF + gundelik vaxti deyismek (2026-10-06)
--
--  Evvel «Hedef 4 gun» sabit idi.  Indi:
--   * hedef (gun/hefte) usagin gundelik vaxtindan gelir: 5 dəq -> 5, 10 -> 5, 15 -> 4, 20 -> 4, 30 -> 3
--     (az vaxt = tez-tez, cox vaxt = az gun); valideyn 2-7 arasi deyise biler (goal_days);
--   * valideyn «Hedef»den gundelik vaxti ve hedefi bir yerde deyisir (rpc_family_set_plan);
--     vaxt deyiseni bu gunun hazir paketine tesir etmir - sabahdan;
--   * usaq «Menim heftem»de «2 / 4 gun» ve hedef dolanda tebrik gorur (rpc_student_family);
--   * heftelik xulase push «Lale: 3/4 gun, 40 sual …» yazir.
--  Gun «calisdi» sayilir: o gun en azi 1 sual cavablanib (915 ile eyni).
--  ON SERT: 913-920.   Tekrar isledile biler.
-- =====================================================================

alter table public.family_kids add column if not exists goal_days smallint;
alter table public.family_kids drop constraint if exists family_kids_goal_days_check;
alter table public.family_kids add constraint family_kids_goal_days_check check (goal_days is null or goal_days between 2 and 7);

create or replace function app.family_goal(p_minutes int, p_goal smallint)
returns int
language sql immutable as $$
  select coalesce(p_goal::int, case coalesce(p_minutes, 10) when 5 then 5 when 10 then 5 when 15 then 4 when 20 then 4 when 30 then 3 else 4 end)
$$;
revoke all on function app.family_goal(int, smallint) from public, anon, authenticated;

create or replace function public.rpc_family_set_plan(p_student uuid, p_minutes int, p_days int)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st
                                   join public.family_kids fk on fk.student_id = st.id
                                  where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if p_minutes is null or p_minutes not in (5, 10, 15, 20, 30) then
    raise exception 'Gündəlik vaxtı seçin.' using errcode = '22023';
  end if;
  if p_days is null or p_days < 2 or p_days > 7 then
    raise exception 'Həftəlik hədəf 2–7 gün arasında olmalıdır.' using errcode = '22023';
  end if;
  update public.family_kids set minutes = p_minutes, goal_days = p_days::smallint where student_id = p_student;
  return jsonb_build_object('ok', true, 'minutes', p_minutes, 'goal', p_days);
end $$;
revoke all on function public.rpc_family_set_plan(uuid, int, int) from public, anon;
grant execute on function public.rpc_family_set_plan(uuid, int, int) to authenticated;

-- ---------------------------------------------------------------------
--  917/920/918-den kopya: progress (goal, minutes), student_family (goal), heftelik push (x/y gun)
-- ---------------------------------------------------------------------
create or replace function public.rpc_family_progress()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', st.id,
             'goal', app.family_goal(fk.minutes, fk.goal_days),
             'minutes', fk.minutes,
             'mastered', (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered'),
             'learning',  (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'learning'),
             'due',       (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered' and m.due_at <= now()),
             'cur', coalesce((
               select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
                 from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                         from public.class_plan_items i
                         join public.class_plans p on p.id = i.plan_id and p.class_id = st.class_id
                         join public.subjects sb on sb.id = p.subject_id
                         join public.topics t on t.id = i.topic_id
                         left join public.topics par on par.id = t.parent_id
                        where i.done_at is not null
                        order by p.id, i.ord desc) y), '[]'::jsonb))
             order by st.created_at)
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.account_id = v_acc and st.is_active), '[]'::jsonb);
end $$;

create or replace function public.rpc_student_family(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    uuid := app.session_student(p_token);
  v_today date := (now() at time zone 'Asia/Baku')::date;
  v_mon   date;
  v_min   int;
  v_goal  int;
  v_cls   uuid;
  v_out   jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select fk.minutes, st.class_id, app.family_goal(fk.minutes, fk.goal_days) into v_min, v_cls, v_goal
    from public.family_kids fk join public.students st on st.id = fk.student_id
   where fk.student_id = v_st;
  if not found then
    return jsonb_build_object('family', false);
  end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);

  with ev as (
    select (aa.answered_at at time zone 'Asia/Baku')::date as d
      from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
     where a.student_id = v_st and aa.answered_at >= v_mon - 1
    union all
    select dp.day from public.daily_packs dp
     where dp.student_id = v_st and dp.day >= v_mon and jsonb_array_length(dp.answers) > 0
  )
  select jsonb_build_object(
           'family', true,
           'minutes', coalesce(v_min, 10),
           'goal', v_goal,
           'today_i', v_today - v_mon,
           'week', (select jsonb_agg(case when exists (select 1 from ev where ev.d = v_mon + g) then 1 else 0 end order by g)
                      from generate_series(0, 6) g),
           'mastered', (select count(*) from public.topic_mastery m where m.student_id = v_st and m.state = 'mastered'),
           'cur', coalesce((
             select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
               from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                       from public.class_plan_items i
                       join public.class_plans p on p.id = i.plan_id and p.class_id = v_cls
                       join public.subjects sb on sb.id = p.subject_id
                       join public.topics t on t.id = i.topic_id
                       left join public.topics par on par.id = t.parent_id
                      where i.done_at is not null
                      order by p.id, i.ord desc) y), '[]'::jsonb))
    into v_out;
  return v_out;
end $$;

create or replace function app.push_scan_weekly(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r      record;
  k      record;
  v_n    int := 0;
  v_id   bigint;
  v_h    int  := extract(hour from (p_now at time zone 'Asia/Baku'))::int;
  v_day  date := (p_now at time zone 'Asia/Baku')::date;
  v_mon  date := ((p_now at time zone 'Asia/Baku')::date) - (extract(isodow from (p_now at time zone 'Asia/Baku'))::int - 1);
  v_from timestamptz;
  v_body text;
  v_part text;
  v_days int; v_q int; v_ok int; v_ms int;
begin
  if not app.push_on() then return 0; end if;
  if extract(isodow from (p_now at time zone 'Asia/Baku')) <> 7 or v_h < 18 or v_h >= 21 then return 0; end if;
  v_from := (v_mon::timestamp) at time zone 'Asia/Baku';

  --  hesab basina bir setir: usaqlari var ve bu cihazlar valideyn bildirisi acib
  for r in
    select st.account_id as acc, (array_agg(st.id order by st.created_at))[1] as first_sid
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.is_active
       and exists (select 1 from public.push_subs s where s.student_id = st.id and s.role = 'parent')
     group by st.account_id
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      v_body := '';
      for k in select st.id, st.display_name nm, app.family_goal(fk.minutes, fk.goal_days) goal from public.students st
                 join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        select count(distinct e.d), coalesce(sum(e.q), 0), coalesce(sum(e.ok), 0)
          into v_days, v_q, v_ok
          from (
            select (aa.answered_at at time zone 'Asia/Baku')::date d, 1 q, case when aa.is_correct then 1 else 0 end ok
              from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
             where a.student_id = k.id and aa.answered_at >= v_from and aa.answered_at < v_from + interval '7 days'
            union all
            select dp.day, jsonb_array_length(dp.answers),
                   (select count(*) from jsonb_array_elements(dp.answers) x where (x->>'ok')::boolean)::int
              from public.daily_packs dp
             where dp.student_id = k.id and dp.day >= v_mon and dp.day < v_mon + 7 and jsonb_array_length(dp.answers) > 0
          ) e where e.q > 0;
        select count(*) into v_ms from public.topic_mastery m
         where m.student_id = k.id and m.state = 'mastered' and m.mastered_at >= v_from;
        if v_q = 0 then
          v_part := k.nm || ': bu həftə çalışmayıb';
        else
          v_part := k.nm || ': ' || v_days || '/' || k.goal || ' gün, ' || v_q || ' sual (' || round(v_ok * 100.0 / v_q) || ' % düz)'
                    || case when v_ms > 0 then ', ' || v_ms || ' mövzu mənimsədi' else '' end;
        end if;
        v_body := v_body || case when v_body = '' then '' else '. ' end || v_part;
      end loop;
      if v_body = '' then continue; end if;

      v_id := app.push_enqueue('parent', r.first_sid, 'hefte', 'hefte:' || r.acc || ':' || v_mon,
                               'Həftənin xülasəsi', v_body || '.', null, 5);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push heftelik: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;

revoke all on function public.rpc_family_progress() from public, anon;
grant execute on function public.rpc_family_progress() to authenticated;
revoke all on function public.rpc_student_family(text) from public;
grant execute on function public.rpc_student_family(text) to anon, authenticated;
revoke all on function app.push_scan_weekly(timestamptz) from public, anon, authenticated;

-- >>>>>>>>>> 922_aile_afarin_3.sql
-- =====================================================================
--  922 : AILE YOLU - «Aferin» gunde 3 defeyedek (2026-10-06)
--
--  Evvel gunde 1.  Indi: usaq basina gunde 3 (fergli mesaj - eyni mesaj gunde bir defe);
--  push YALNIZ ilk ikisine gedir (bildiris sayi artmasin), ucuncusu usagin gundelik kartinda gorunur.
--  rpc_family_progress: praise_n (bu gun nece defe), praise_last (Baki saati) - kart veziyyeti gostersin.
--  ON SERT: 913-921.   Tekrar isledile biler.
-- =====================================================================
create or replace function public.rpc_family_praise(p_student uuid, p_kind int)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_acc  uuid;
  v_msgs text[] := array['Afərin! Bu gün yaxşı çalışdın 👏', 'Səninlə fəxr edirəm 💚', 'Davam et, çox yaxşı gedir!'];
  v_msg  text;
  v_day  date := (now() at time zone 'Asia/Baku')::date;
  v_id   bigint;
  v_n    int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if p_kind is null or p_kind < 1 or p_kind > 3 then
    raise exception 'Mesaj seçin.' using errcode = '22023';
  end if;
  select count(*) into v_n from public.family_praise fp
   where fp.student_id = p_student and (fp.at at time zone 'Asia/Baku')::date = v_day;
  if v_n >= 3 then
    raise exception 'Bu gün üçün «Afərin» limiti doldu (3).' using errcode = '22023';
  end if;
  v_msg := v_msgs[p_kind];
  if exists (select 1 from public.family_praise fp
              where fp.student_id = p_student and fp.msg = v_msg and (fp.at at time zone 'Asia/Baku')::date = v_day) then
    raise exception 'Bu mesajı bu gün göndərmisiniz. Başqa mesaj seçin.' using errcode = '22023';
  end if;
  insert into public.family_praise (student_id, msg) values (p_student, v_msg);

  --  push yalniz ilk ikisi ucun (bildiris sayi artmasin); qalani usagin gundelik kartinda gorunur
  if v_n < 2 then
    v_id := app.push_enqueue('student', p_student, 'afarin', 'afarin:' || p_student || ':' || v_day || ':' || (v_n + 1),
                             'Valideynindən mesaj', v_msg, null, 5);
  end if;
  return jsonb_build_object('ok', true, 'push', v_id is not null, 'count', v_n + 1, 'left', 3 - (v_n + 1));
end $$;

create or replace function public.rpc_family_progress()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', st.id,
             'goal', app.family_goal(fk.minutes, fk.goal_days),
             'minutes', fk.minutes,
             'praise_n', (select count(*) from public.family_praise fp
                           where fp.student_id = st.id and (fp.at at time zone 'Asia/Baku')::date = (now() at time zone 'Asia/Baku')::date),
             'praise_last', (select to_char(max(fp.at) at time zone 'Asia/Baku', 'HH24:MI') from public.family_praise fp
                              where fp.student_id = st.id and (fp.at at time zone 'Asia/Baku')::date = (now() at time zone 'Asia/Baku')::date),
             'mastered', (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered'),
             'learning',  (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'learning'),
             'due',       (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered' and m.due_at <= now()),
             'cur', coalesce((
               select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
                 from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                         from public.class_plan_items i
                         join public.class_plans p on p.id = i.plan_id and p.class_id = st.class_id
                         join public.subjects sb on sb.id = p.subject_id
                         join public.topics t on t.id = i.topic_id
                         left join public.topics par on par.id = t.parent_id
                        where i.done_at is not null
                        order by p.id, i.ord desc) y), '[]'::jsonb))
             order by st.created_at)
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.account_id = v_acc and st.is_active), '[]'::jsonb);
end $$;

revoke all on function public.rpc_family_praise(uuid, int) from public, anon;
grant execute on function public.rpc_family_praise(uuid, int) to authenticated;
revoke all on function public.rpc_family_progress() from public, anon;
grant execute on function public.rpc_family_progress() to authenticated;

--  rpc_student_daily (918-den kopya): eyni anda gonderilen afarinlarda SON yazilan gorunsun (id)
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
    'family', exists (select 1 from public.family_kids fk where fk.student_id = v_st),
    --  valideynin «Aferin»i (son 2 gun) - bildiris getmese de usaq gorsun
    'praise', (select fp.msg from public.family_praise fp
                where fp.student_id = v_st and fp.at > now() - interval '2 days'
                order by fp.at desc, fp.id desc limit 1),
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

-- >>>>>>>>>> 923_aile_xeberdarliq.sql
-- =====================================================================
--  923 : AILE YOLU - valideynə istisna esasli bildirisler (2026-10-06)
--
--  Her gun xulase YOX (bildiris yorgunlugu) - yalniz valideynin bilmesi lazim olan an:
--   1. «Lale bu gun hele calismayib» - axsam (Baki 19:00-21:00, saatlıq tick 19:05-de tutur),
--      YALNIZ usaq o gun heç bir sual cavablamayibsa; usaq elave edildiyi gun gonderilmir;
--      bir hesaba bir bildiris (bir nece usaq varsa adlar birlikde).
--   2. «Lale bu heftenin hedefini tamamladi» - hedefe catan an (hefte basina usaq basina bir defe),
--      «Aferin gonder» teklifi ile.
--  Sakit saatlar (21:00-10:00) dayismir.  Valideyn «Ailem»den hər ikisini ayrica sondure biler
--  (family_prefs: hesab seviyyesinde; defolt hamisi acıqdır).
--  Heftelik xulase (918) ayridir.  ON SERT: 910-922.   Tekrar isledile biler.
-- =====================================================================

create table if not exists public.family_prefs (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  nostudy    boolean not null default true,
  goal       boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.family_prefs enable row level security;
revoke all on public.family_prefs from public, anon, authenticated;

create or replace function public.rpc_family_push_prefs_get()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'nostudy', coalesce((select p.nostudy from public.family_prefs p where p.account_id = v_acc), true),
    'goal',    coalesce((select p.goal    from public.family_prefs p where p.account_id = v_acc), true));
end $$;
revoke all on function public.rpc_family_push_prefs_get() from public, anon;
grant execute on function public.rpc_family_push_prefs_get() to authenticated;

create or replace function public.rpc_family_push_prefs_set(p_nostudy boolean, p_goal boolean)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  insert into public.family_prefs (account_id, nostudy, goal)
  values (v_acc, coalesce(p_nostudy, true), coalesce(p_goal, true))
  on conflict (account_id) do update set nostudy = excluded.nostudy, goal = excluded.goal, updated_at = now();
  return jsonb_build_object('ok', true, 'nostudy', coalesce(p_nostudy, true), 'goal', coalesce(p_goal, true));
end $$;
revoke all on function public.rpc_family_push_prefs_set(boolean, boolean) from public, anon;
grant execute on function public.rpc_family_push_prefs_set(boolean, boolean) to authenticated;

-- ------------------------------------------------ 1 · «bu gun hele calismayib»
create or replace function app.push_scan_family_nostudy(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r       record;
  k       record;
  v_n     int := 0;
  v_id    bigint;
  v_h     int  := extract(hour from (p_now at time zone 'Asia/Baku'))::int;
  v_day   date := (p_now at time zone 'Asia/Baku')::date;
  v_names text[];
  v_body  text;
begin
  if not app.push_on() then return 0; end if;
  if v_h < 19 or v_h >= 21 then return 0; end if;

  for r in
    select st.account_id as acc, (array_agg(st.id order by st.created_at))[1] as first_sid
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.is_active
       and exists (select 1 from public.push_subs s where s.student_id = st.id and s.role = 'parent')
     group by st.account_id
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      if not app.has_active_subscription(r.acc) then continue; end if;
      if not coalesce((select p.nostudy from public.family_prefs p where p.account_id = r.acc), true) then continue; end if;
      v_names := '{}';
      for k in select st.id, st.display_name nm, st.created_at
                 from public.students st join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        continue when (k.created_at at time zone 'Asia/Baku')::date = v_day;      -- bu gun elave olunub: tezdir
        continue when exists (select 1 from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
                               where a.student_id = k.id and (aa.answered_at at time zone 'Asia/Baku')::date = v_day)
                   or exists (select 1 from public.daily_packs dp
                               where dp.student_id = k.id and dp.day = v_day and jsonb_array_length(dp.answers) > 0);
        v_names := v_names || k.nm;
      end loop;
      if cardinality(v_names) = 0 then continue; end if;
      v_body := array_to_string(v_names, ' və ') ||
                case when cardinality(v_names) = 1 then ' bu gün hələ çalışmayıb.' else ' bu gün hələ çalışmayıblar.' end ||
                ' Bir neçə dəqiqəlik məşqə həvəsləndirin.';
      v_id := app.push_enqueue('parent', r.first_sid, 'bugun_yox', 'yox:' || r.acc || ':' || v_day,
                               'Bu gün hələ çalışmayıb', v_body, './valideyn/?aile=1', 5);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push bugun yox: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;
revoke all on function app.push_scan_family_nostudy(timestamptz) from public, anon, authenticated;

-- ------------------------------------------------ 2 · hedef tamamlandi
create or replace function app.push_scan_family_goal(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r      record;
  k      record;
  v_n    int := 0;
  v_id   bigint;
  v_day  date := (p_now at time zone 'Asia/Baku')::date;
  v_mon  date := ((p_now at time zone 'Asia/Baku')::date) - (extract(isodow from (p_now at time zone 'Asia/Baku'))::int - 1);
  v_from timestamptz;
  v_days int;
begin
  if not app.push_on() then return 0; end if;
  v_from := (v_mon::timestamp) at time zone 'Asia/Baku';

  for r in
    select st.account_id as acc, (array_agg(st.id order by st.created_at))[1] as first_sid
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.is_active
       and exists (select 1 from public.push_subs s where s.student_id = st.id and s.role = 'parent')
     group by st.account_id
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      if not app.has_active_subscription(r.acc) then continue; end if;
      if not coalesce((select p.goal from public.family_prefs p where p.account_id = r.acc), true) then continue; end if;
      for k in select st.id, st.display_name nm, app.family_goal(fk.minutes, fk.goal_days) goal
                 from public.students st join public.family_kids fk on fk.student_id = st.id
                where st.account_id = r.acc and st.is_active order by st.created_at loop
        select count(distinct e.d) into v_days from (
          select (aa.answered_at at time zone 'Asia/Baku')::date d
            from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
           where a.student_id = k.id and aa.answered_at >= v_from and aa.answered_at < v_from + interval '7 days'
          union all
          select dp.day from public.daily_packs dp
           where dp.student_id = k.id and dp.day >= v_mon and dp.day < v_mon + 7 and jsonb_array_length(dp.answers) > 0
        ) e;
        if v_days >= k.goal then
          v_id := app.push_enqueue('parent', r.first_sid, 'hedef', 'hedef:' || k.id || ':' || v_mon,
                                   'Həftənin hədəfi tamamlandı 🎉',
                                   k.nm || ' bu həftənin hədəfini tamamladı (' || v_days || ' / ' || k.goal || ' gün). «Afərin göndər» ilə təbrik edə bilərsiniz.',
                                   './valideyn/?aile=1', 5);
          if v_id is not null then v_n := v_n + 1; end if;
        end if;
      end loop;
    exception when others then
      raise warning 'push hedef: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;
revoke all on function app.push_scan_family_goal(timestamptz) from public, anon, authenticated;

-- ------------------------------------------------ saatlig planlayici (918-den + 2 yeni)
create or replace function app.push_tick() returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_d int := 0;
  v_g int := 0;
  v_w int := 0;
  v_y int := 0;
  v_h int := 0;
begin
  if not app.push_on() then return jsonb_build_object('on', false); end if;
  begin v_d := app.push_scan_deadlines();      exception when others then raise warning 'push tick son tarix: %', sqlerrm; end;
  begin v_g := app.push_scan_daily();          exception when others then raise warning 'push tick gundelik: %', sqlerrm; end;
  begin v_w := app.push_scan_weekly();         exception when others then raise warning 'push tick heftelik: %', sqlerrm; end;
  begin v_y := app.push_scan_family_nostudy(); exception when others then raise warning 'push tick bugun yox: %', sqlerrm; end;
  begin v_h := app.push_scan_family_goal();    exception when others then raise warning 'push tick hedef: %', sqlerrm; end;
  begin perform app.push_cleanup();            exception when others then raise warning 'push tick temizlik: %', sqlerrm; end;
  return jsonb_build_object('on', true, 'son_tarix', v_d, 'gundelik', v_g, 'heftelik', v_w, 'bugun_yox', v_y, 'hedef', v_h);
end $$;
revoke all on function app.push_tick() from public, anon, authenticated;

-- >>>>>>>>>> 924_aile_personaj.sql
-- =====================================================================
--  924 : AILE YOLU - personaj («Tumurcuq»), zencir, nisanlar, valideynin mukafati (2026-10-06)
--
--  Hamisi USAGA ozeldir - hec bir melumat basqasina getmir (yarisi/reytinq YOXDUR, qerar 06.10).
--   * personaj mərhələsi cəmi calisdigi gunlerden (days_total) cixir: 0 toxum · 3 cucerti · 7 bitki · 14 agac · 30 cicekli agac;
--     MƏRHƏLƏ HEC VAXT GERI GETMIR (calismayanda cəza yoxdur - «seni gozleyirem»);
--   * zencir: ardicil calisdigi gunler, BIR gun buraxmaq zənciri pozmur (aralıq <=2 gun);
--   * 7 nisan: ilk gun, 3/7 gun ardicil, ilk movzu, 5 movzu, 100 sual, hedef heftesi (hesablanir, cedvel yoxdur);
--   * valideyn «Gundelik mesq -> deyis»de mukafat yaza biler (<=80 simvol): hedef dolanda usaq gorur.
--  rpc_student_family: days_total, streak, best_streak, answers_total, badges, reward.
--  rpc_family_progress: reward.   rpc_family_set_reward(usaq, metn).
--  ON SERT: 913-923.   Tekrar isledile biler.
-- =====================================================================

alter table public.family_kids add column if not exists reward text;
alter table public.family_kids drop constraint if exists family_kids_reward_check;
alter table public.family_kids add constraint family_kids_reward_check check (reward is null or length(reward) <= 80);

create or replace function public.rpc_family_set_reward(p_student uuid, p_text text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_t   text := nullif(btrim(regexp_replace(coalesce(p_text, ''), '[[:cntrl:]]+', ' ', 'g')), '');
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st
                                   join public.family_kids fk on fk.student_id = st.id
                                  where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if v_t is not null and length(v_t) > 80 then
    raise exception 'Mükafat mətni ən çox 80 simvol ola bilər.' using errcode = '22023';
  end if;
  update public.family_kids set reward = v_t where student_id = p_student;
  return jsonb_build_object('ok', true, 'reward', v_t);
end $$;
revoke all on function public.rpc_family_set_reward(uuid, text) from public, anon;
grant execute on function public.rpc_family_set_reward(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
--  usagin oz sehifesi (920/921-den genisletilib)
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_family(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st      uuid := app.session_student(p_token);
  v_today   date := (now() at time zone 'Asia/Baku')::date;
  v_mon     date;
  v_min     int;
  v_goal    int;
  v_reward  text;
  v_cls     uuid;
  v_total   int;
  v_best    int;
  v_cur     int;
  v_answers int;
  v_gweeks  int;
  v_mast    int;
  v_out     jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select fk.minutes, st.class_id, app.family_goal(fk.minutes, fk.goal_days), fk.reward
    into v_min, v_cls, v_goal, v_reward
    from public.family_kids fk join public.students st on st.id = fk.student_id
   where fk.student_id = v_st;
  if not found then
    return jsonb_build_object('family', false);
  end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);

  --  butun calisdigi gunler (testler + gundelik paket); zencir: aralıq <=2 gun (bir gun buraxmaq pozmur)
  with days as (
    select distinct d from (
      select (aa.answered_at at time zone 'Asia/Baku')::date as d
        from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
       where a.student_id = v_st
      union all
      select dp.day from public.daily_packs dp
       where dp.student_id = v_st and jsonb_array_length(dp.answers) > 0
    ) x
  ), ordered as (
    select d, lag(d) over (order by d) as prev from days
  ), grp as (
    select d, sum(case when prev is null or d - prev > 2 then 1 else 0 end) over (order by d) as g from ordered
  ), runs as (
    select g, count(*)::int as n, max(d) as last_d from grp group by g
  )
  select (select count(*) from days),
         coalesce((select max(n) from runs), 0),
         coalesce((select n from runs where last_d >= v_today - 2 order by last_d desc limit 1), 0),
         (select count(*) from (select date_trunc('week', d::timestamp) w, count(*) c from days group by 1) q where q.c >= v_goal)
    into v_total, v_best, v_cur, v_gweeks;

  select (select count(*) from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id where a.student_id = v_st)
         + coalesce((select sum(jsonb_array_length(dp.answers)) from public.daily_packs dp where dp.student_id = v_st), 0)
    into v_answers;
  select count(*) into v_mast from public.topic_mastery m where m.student_id = v_st and m.state = 'mastered';

  with ev as (
    select (aa.answered_at at time zone 'Asia/Baku')::date as d
      from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
     where a.student_id = v_st and aa.answered_at >= v_mon - 1
    union all
    select dp.day from public.daily_packs dp
     where dp.student_id = v_st and dp.day >= v_mon and jsonb_array_length(dp.answers) > 0
  )
  select jsonb_build_object(
           'family', true,
           'minutes', coalesce(v_min, 10),
           'goal', v_goal,
           'reward', v_reward,
           'today_i', v_today - v_mon,
           'week', (select jsonb_agg(case when exists (select 1 from ev where ev.d = v_mon + g) then 1 else 0 end order by g)
                      from generate_series(0, 6) g),
           'mastered', v_mast,
           'days_total', v_total,
           'streak', v_cur,
           'best_streak', v_best,
           'answers_total', v_answers,
           'badges', jsonb_build_array(
             jsonb_build_object('k', 'first', 't', 'İlk gün',          'd', 'İlk dəfə çalışdın',                'on', v_total >= 1),
             jsonb_build_object('k', 's3',    't', '3 gün ardıcıl',    'd', '3 gün ardıcıl çalışdın',           'on', v_best >= 3),
             jsonb_build_object('k', 's7',    't', '7 gün ardıcıl',    'd', '7 gün ardıcıl çalışdın',           'on', v_best >= 7),
             jsonb_build_object('k', 'm1',    't', 'İlk mövzu',        'd', 'Bir mövzunu mənimsədin',           'on', v_mast >= 1),
             jsonb_build_object('k', 'm5',    't', '5 mövzu',          'd', '5 mövzunu mənimsədin',             'on', v_mast >= 5),
             jsonb_build_object('k', 'q100',  't', '100 sual',         'd', '100 sual həll etdin',              'on', v_answers >= 100),
             jsonb_build_object('k', 'g1',    't', 'Hədəf həftəsi',    'd', 'Həftəlik hədəfi tamamladın',       'on', v_gweeks >= 1)),
           'cur', coalesce((
             select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
               from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                       from public.class_plan_items i
                       join public.class_plans p on p.id = i.plan_id and p.class_id = v_cls
                       join public.subjects sb on sb.id = p.subject_id
                       join public.topics t on t.id = i.topic_id
                       left join public.topics par on par.id = t.parent_id
                      where i.done_at is not null
                      order by p.id, i.ord desc) y), '[]'::jsonb))
    into v_out;
  return v_out;
end $$;
revoke all on function public.rpc_student_family(text) from public;
grant execute on function public.rpc_student_family(text) to anon, authenticated;

-- ---------------------------------------------------------------------
--  922-den kopya: rpc_family_progress ('reward' elave)
-- ---------------------------------------------------------------------
create or replace function public.rpc_family_progress()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', st.id,
             'goal', app.family_goal(fk.minutes, fk.goal_days),
             'minutes', fk.minutes,
             'reward', fk.reward,
             'praise_n', (select count(*) from public.family_praise fp
                           where fp.student_id = st.id and (fp.at at time zone 'Asia/Baku')::date = (now() at time zone 'Asia/Baku')::date),
             'praise_last', (select to_char(max(fp.at) at time zone 'Asia/Baku', 'HH24:MI') from public.family_praise fp
                              where fp.student_id = st.id and (fp.at at time zone 'Asia/Baku')::date = (now() at time zone 'Asia/Baku')::date),
             'mastered', (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered'),
             'learning',  (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'learning'),
             'due',       (select count(*) from public.topic_mastery m where m.student_id = st.id and m.state = 'mastered' and m.due_at <= now()),
             'cur', coalesce((
               select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
                 from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                         from public.class_plan_items i
                         join public.class_plans p on p.id = i.plan_id and p.class_id = st.class_id
                         join public.subjects sb on sb.id = p.subject_id
                         join public.topics t on t.id = i.topic_id
                         left join public.topics par on par.id = t.parent_id
                        where i.done_at is not null
                        order by p.id, i.ord desc) y), '[]'::jsonb))
             order by st.created_at)
      from public.students st
      join public.family_kids fk on fk.student_id = st.id
     where st.account_id = v_acc and st.is_active), '[]'::jsonb);
end $$;

revoke all on function public.rpc_family_progress() from public, anon;
grant execute on function public.rpc_family_progress() to authenticated;
