-- =====================================================================
--  910 : PUSH BILDIRISLER - 1-ci merhele: abunelik, novbe, qaydalar (2026-10-05)
--
--  QERAR (sahib, 04-05.10): sagirde ve valideyne telefona bildiris - «yeni test»
--  ve xatirlatmalar.  Bu fayl YALNIZ ALTLIQDIR: abunelik cedveli, gonderilecek
--  bildirisler novbesi, qaydalar.  Avtomatik tetikleyiciler 911-de, xatirlatmalar 912-de.
--
--  NECE ISLEYIR
--    brauzer (sagird/valideyn) -> rpc_push_subscribe (sessiya tokeni ile) -> push_subs
--    app.push_enqueue(...)    -> push_outbox (qaydalar: gecə, gunluk hedd, tekrar yox)
--    Edge Function push-send  -> rpc_push_claim -> push xidmeti (FCM/Mozilla/Apple)
--                             -> rpc_push_done (neticeni yazir, olu abuneleri silir)
--
--  ABUNELIK SESSIYAYA BAGLI DEYIL: sagird sessiyasi 12 saat, valideyn 30 gundur;
--  bildiris ise sessiya bitenden sonra da gelmelidir.  Ona gore abunelik
--  SAGIRDE (students.id) baglidir; yalniz ETIBARLI sessiya ile yazilir/silinir.
--  Eyni telefonu bir nece usaq bolusurse - eyni endpoint bir nece sagirdle baglana biler.
--
--  TEHLUKESIZLIK
--   * SSRF: gonderici abune unvanina POST edir.  Ona gore unvan YALNIZ bilinen
--     push xidmetlerinin unvanlarindan ola biler (app.push_host_ok) - Edge Function
--     da eyni yoxlamani tekrar edir.
--   * Cedveller RLS ile baglidir, siyaset yoxdur; yalniz definer RPC-ler toxunur.
--   * rpc_push_claim / rpc_push_done YALNIZ service_role-dur (anon/authenticated yox).
--   * Oldurme duymesi: app_state.push = {"on": false}.  Sonuk olanda novbeye YAZILMIR
--     ve gonderici hec ne almir.  Geri almaq: update public.app_state set val = '{"on": false}' where key = 'push';
--
--  ON SERT: 03 (app.session_student), 107 (app.session_parent), 905 (app.account_locked).
-- =====================================================================

insert into public.app_state (key, val)
values ('push', '{"on": false}'::jsonb)
on conflict (key) do nothing;

-- ------------------------------------------------------------ cedveller
create table if not exists public.push_subs (
  id         uuid primary key default gen_random_uuid(),
  role       text not null check (role in ('student', 'parent')),
  student_id uuid not null references public.students(id) on delete cascade,
  endpoint   text not null,
  p256dh     text not null,
  auth       text not null,
  ua         text,
  prefs      jsonb not null default '{}'::jsonb,   -- 912: valideyn «bu gun calismayib» acari
  created_at timestamptz not null default now(),
  last_ok_at timestamptz,
  fail_count int not null default 0,
  unique (endpoint, student_id, role)
);
create index if not exists idx_push_subs_student on public.push_subs(student_id, role);

create table if not exists public.push_outbox (
  id         bigserial primary key,
  role       text not null check (role in ('student', 'parent')),
  student_id uuid not null references public.students(id) on delete cascade,
  kind       text not null,                 -- test | yeni_test | son_tarix | gundelik | calismayib
  dedupe_key text unique,                   -- eyni hadise ikinci defe novbeye dusmesin
  title      text not null,
  body       text not null,
  url        text not null default './',
  send_after timestamptz not null default now(),
  claimed_at timestamptz,
  sent_at    timestamptz,
  status     text not null default 'pending' check (status in ('pending', 'sent', 'failed', 'skipped')),
  attempts   int not null default 0,
  last_error text,
  created_at timestamptz not null default now()
);
create index if not exists idx_push_outbox_due on public.push_outbox(status, send_after);
create index if not exists idx_push_outbox_who on public.push_outbox(role, student_id, created_at);

alter table public.push_subs   enable row level security;
alter table public.push_outbox enable row level security;
--  Siyaset yoxdur - yalniz definer RPC-ler toxunur.
revoke all on public.push_subs, public.push_outbox from anon, authenticated;
revoke all on sequence public.push_outbox_id_seq from anon, authenticated;

-- ------------------------------------------------------------- yardimcilar
create or replace function app.push_on() returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select coalesce((select (val->>'on')::boolean from public.app_state where key = 'push'), false)
$$;

--  Abune unvani YALNIZ bilinen push xidmetlerinden ola biler (SSRF qorumasi).
--  Chrome/Samsung/Opera: fcm.googleapis.com · Firefox: updates.push.services.mozilla.com
--  Safari/iOS: web.push.apple.com · Edge: *.notify.windows.com
create or replace function app.push_host_ok(p_endpoint text) returns boolean
language sql immutable as $$
  select p_endpoint is not null
     and length(p_endpoint) between 20 and 1000
     and p_endpoint ~ '^https://(fcm\.googleapis\.com|updates\.push\.services\.mozilla\.com|web\.push\.apple\.com|[a-z0-9-]+(\.[a-z0-9-]+)*\.push\.apple\.com|[a-z0-9-]+(\.[a-z0-9-]+)*\.notify\.windows\.com)/[A-Za-z0-9_.~%/:=+?&-]+$'
$$;

--  Sakit saat: 21:00-10:00 (Baki) arasi yazilan bildiris sabah 10:00-a kecir.
--  (sahib, 05.10: «seher 10:00-dan sonra getse yaxsidir» - 08:00 tezdir, usaq/valideyn yuxudan durmayib)
create or replace function app.push_quiet_next(p_ts timestamptz) returns timestamptz
language sql immutable as $$
  select case
    when extract(hour from (p_ts at time zone 'Asia/Baku')) >= 21
      then (((p_ts at time zone 'Asia/Baku')::date + 1) + time '10:00') at time zone 'Asia/Baku'
    when extract(hour from (p_ts at time zone 'Asia/Baku')) < 10
      then (((p_ts at time zone 'Asia/Baku')::date) + time '10:00') at time zone 'Asia/Baku'
    else p_ts end
$$;

--  Bildirisi novbeye yazir.  Qaydalar:
--    * oldurme duymesi sonukdurse - yazilmir;
--    * abunesi olmayan alici ucun yazilmir (novbe sismesin);
--    * gunde en cox 2 bildiris (kind='test' istisnadir);
--    * gece sakitliyi (kind='test' istisnadir);
--    * dedupe_key eyni olsa ikinci defe yazilmir;
--    * qapali hesabda «gundelik» (oz basina mesq) yazilmir.
create or replace function app.push_enqueue(
  p_role text, p_student uuid, p_kind text, p_dedupe text,
  p_title text, p_body text, p_url text default './', p_cap int default 2)
returns bigint
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_id    bigint;
  v_acc   uuid;
  v_today timestamptz := (((now() at time zone 'Asia/Baku')::date) :: timestamp) at time zone 'Asia/Baku';
begin
  if not app.push_on() then return null; end if;
  if p_role not in ('student', 'parent') or p_student is null then return null; end if;
  if not exists (select 1 from public.push_subs s where s.role = p_role and s.student_id = p_student) then
    return null;
  end if;

  if p_kind = 'gundelik' then
    select s.account_id into v_acc from public.students s where s.id = p_student;
    if app.account_locked(v_acc) then return null; end if;
  end if;

  if p_kind <> 'test' and (
       select count(*) from public.push_outbox o
        where o.role = p_role and o.student_id = p_student
          and o.created_at >= v_today and o.status in ('pending', 'sent')
          and o.kind <> 'test') >= coalesce(p_cap, 2) then
    return null;
  end if;

  insert into public.push_outbox (role, student_id, kind, dedupe_key, title, body, url, send_after)
  values (p_role, p_student, p_kind, p_dedupe,
          left(p_title, 80), left(p_body, 200), left(coalesce(p_url, './'), 300),
          case when p_kind = 'test' then now() else app.push_quiet_next(now()) end)
  on conflict (dedupe_key) do nothing
  returning id into v_id;
  return v_id;
end $$;

-- -------------------------------------------------- brauzer: abune ol / cix
create or replace function public.rpc_push_subscribe(
  p_token text, p_role text, p_endpoint text, p_p256dh text, p_auth text, p_ua text default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid;
  v_demo    boolean;
begin
  if p_role = 'student' then v_student := app.session_student(p_token);
  elsif p_role = 'parent' then v_student := app.session_parent(p_token);
  else raise exception 'Rol yanlisdir.' using errcode = '22023'; end if;
  if v_student is null then
    raise exception 'Sessiya bitdi. Kodu bir də yaz.' using errcode = '42501';
  end if;
  if not app.push_host_ok(p_endpoint) then
    raise exception 'Bildiriş ünvanı tanınmadı.' using errcode = '22023';
  end if;
  if p_p256dh is null or length(p_p256dh) not between 40 and 200
     or p_auth is null or length(p_auth) not between 10 and 100 then
    raise exception 'Bildiriş açarları yanlışdır.' using errcode = '22023';
  end if;

  --  Numune hesablarda abunelik saxlanmir (ziyaretciye bildiris getmesin)
  select a.is_demo into v_demo
    from public.students s join public.accounts a on a.id = s.account_id
   where s.id = v_student;
  if coalesce(v_demo, false) then
    return jsonb_build_object('ok', true, 'demo', true);
  end if;

  --  Bir sagird/valideyn ucun en cox 10 cihaz: en kohne silinir
  if not exists (select 1 from public.push_subs
                  where endpoint = p_endpoint and student_id = v_student and role = p_role)
     and (select count(*) from public.push_subs where student_id = v_student and role = p_role) >= 10 then
    delete from public.push_subs
     where id = (select id from public.push_subs where student_id = v_student and role = p_role
                  order by coalesce(last_ok_at, created_at) limit 1);
  end if;

  insert into public.push_subs (role, student_id, endpoint, p256dh, auth, ua)
  values (p_role, v_student, p_endpoint, p_p256dh, p_auth, left(p_ua, 200))
  on conflict (endpoint, student_id, role)
  do update set p256dh = excluded.p256dh, auth = excluded.auth, ua = excluded.ua, fail_count = 0;

  return jsonb_build_object('ok', true);
end $$;

--  Etibarli sessiya olmasa HEC NE silinmir (basqasinin abunesini silmek olmaz).
create or replace function public.rpc_push_unsubscribe(p_token text, p_role text, p_endpoint text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid;
  v_n int := 0;
begin
  if p_role = 'student' then v_student := app.session_student(p_token);
  elsif p_role = 'parent' then v_student := app.session_parent(p_token);
  else raise exception 'Rol yanlisdir.' using errcode = '22023'; end if;
  if v_student is not null then
    delete from public.push_subs
     where student_id = v_student and role = p_role and endpoint = p_endpoint;
    get diagnostics v_n = row_count;
  end if;
  return jsonb_build_object('ok', true, 'removed', v_n);
end $$;

-- ------------------------------------------- gonderici (Edge Function) ucun
--  YALNIZ service_role.  Novbeden hazir bildirisleri goturur, abuneleri ile birlikde.
create or replace function public.rpc_push_claim(p_limit int default 50)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_ids bigint[];
begin
  if not app.push_on() then return '[]'::jsonb; end if;

  select coalesce(array_agg(id), '{}') into v_ids from (
    select o.id from public.push_outbox o
     where o.status = 'pending' and o.send_after <= now() and o.attempts < 3
       and (o.claimed_at is null or o.claimed_at < now() - interval '5 minutes')
     order by o.send_after, o.id
     limit least(greatest(coalesce(p_limit, 50), 1), 200)
     for update skip locked) x;

  update public.push_outbox set claimed_at = now(), attempts = attempts + 1 where id = any(v_ids);

  --  abunesi qalmayanlar (silinib / cixis) - bos yere gondericiye verilmir
  update public.push_outbox o set status = 'skipped', last_error = 'abune yoxdur'
   where o.id = any(v_ids)
     and not exists (select 1 from public.push_subs s where s.role = o.role and s.student_id = o.student_id);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', o.id, 'kind', o.kind, 'title', o.title, 'body', o.body, 'url', o.url,
             'attempts', o.attempts,
             'subs', (select jsonb_agg(jsonb_build_object(
                         'id', s.id, 'endpoint', s.endpoint, 'p256dh', s.p256dh, 'auth', s.auth))
                        from public.push_subs s
                       where s.role = o.role and s.student_id = o.student_id
                         and app.push_host_ok(s.endpoint)))
           order by o.id)
      from public.push_outbox o
     where o.id = any(v_ids) and o.status = 'pending'), '[]'::jsonb);
end $$;

--  p_results: [{id, ok:[subId..], dead:[subId..], failed:[subId..], error:'..'}]
--  Bir bildiris en azi bir cihaza catibsa 'sent'; hec bir cihaza catmayibsa 3 cehde qeder yeniden cehd.
create or replace function public.rpc_push_done(p_results jsonb)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r        jsonb;
  v_ok     uuid[];
  v_dead   uuid[];
  v_failed uuid[];
  v_n      int := 0;
begin
  for r in select * from jsonb_array_elements(coalesce(p_results, '[]'::jsonb)) loop
    v_ok     := coalesce(array(select (jsonb_array_elements_text(coalesce(r->'ok', '[]'::jsonb)))::uuid), '{}');
    v_dead   := coalesce(array(select (jsonb_array_elements_text(coalesce(r->'dead', '[]'::jsonb)))::uuid), '{}');
    v_failed := coalesce(array(select (jsonb_array_elements_text(coalesce(r->'failed', '[]'::jsonb)))::uuid), '{}');

    update public.push_subs set last_ok_at = now(), fail_count = 0 where id = any(v_ok);
    delete from public.push_subs where id = any(v_dead);                    -- 404/410: abune olub
    update public.push_subs set fail_count = fail_count + 1 where id = any(v_failed);
    delete from public.push_subs where id = any(v_failed) and fail_count >= 5;

    update public.push_outbox o
       set status     = case when cardinality(v_ok) > 0 then 'sent'
                             when o.attempts >= 3 then 'failed'
                             when cardinality(v_failed) = 0 then 'skipped'      -- hamisi olu idi
                             else 'pending' end,
           sent_at    = case when cardinality(v_ok) > 0 then now() else o.sent_at end,
           claimed_at = case when cardinality(v_ok) = 0 and cardinality(v_failed) > 0 and o.attempts < 3
                             then null else o.claimed_at end,
           send_after = case when cardinality(v_ok) = 0 and cardinality(v_failed) > 0 and o.attempts < 3
                             then now() + interval '2 minutes' * o.attempts else o.send_after end,
           last_error = left(nullif(r->>'error', ''), 300)
     where o.id = (r->>'id')::bigint;
    v_n := v_n + 1;
  end loop;
  return jsonb_build_object('ok', true, 'n', v_n);
end $$;

--  Temizlik (912-de cron ile): kohne novbe, 90 gun cavab vermeyen abune
create or replace function app.push_cleanup() returns void
language sql security definer
set search_path = public, extensions, pg_temp as $$
  delete from public.push_outbox where created_at < now() - interval '14 days';
  delete from public.push_subs
   where coalesce(last_ok_at, created_at) < now() - interval '90 days';
$$;

-- ----------------------------------------------------------------- huquqlar
revoke all on function public.rpc_push_subscribe(text, text, text, text, text, text) from public;
revoke all on function public.rpc_push_unsubscribe(text, text, text) from public;
grant execute on function public.rpc_push_subscribe(text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.rpc_push_unsubscribe(text, text, text) to anon, authenticated;

revoke all on function public.rpc_push_claim(int) from public, anon, authenticated;
revoke all on function public.rpc_push_done(jsonb) from public, anon, authenticated;
grant execute on function public.rpc_push_claim(int) to service_role;
grant execute on function public.rpc_push_done(jsonb) to service_role;

revoke all on function app.push_enqueue(text, uuid, text, text, text, text, text, int) from public, anon, authenticated;
revoke all on function app.push_cleanup() from public, anon, authenticated;
