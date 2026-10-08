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
