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
