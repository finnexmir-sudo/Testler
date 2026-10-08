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
