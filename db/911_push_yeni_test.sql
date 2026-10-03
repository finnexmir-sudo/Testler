-- =====================================================================
--  911 : PUSH BILDIRISLER - 2-ci merhele: «yeni test» (2026-10-05)
--
--  Muellim sinfe test teyin edende (public.assignments-e setir yazilanda) sagirde ve
--  onun valideynine telefona bildiris novbeye yazilir.  Gondermeni 910-dakı Edge Function edir.
--
--  QAYDALAR
--   * Trigger STATEMENT seviyyelidir: bir sorgu ile bir nece test/sinif teyin olunsa,
--     her sagirde BIR bildiris gedir («3 yeni test verildi»).
--   * Ferdi teyinat (assignments.student_id) yalniz hemin sagirde/valideynine gedir, sinfe yox.
--   * Sagirde ad yazilmir; valideynde usagin qisa adi yazilir (iki usagi ola biler).
--   * Qapali hesab (905) ve nümune hesab (abunesi olmur) ucun yazilmir.
--   * Vaxti hele gelmeyen / artıq bitmis teyinat: gelmeyen vaxta saxlanir, bitmis yazilmir.
--   * Gece 21:00-10:00 - sabaha (910 qaydasi).
--   * Gunluk hedd: «yeni test» ucun 5 (muellim ozu verir, sagird bilmelidir); xatirlatmalar 912-de 2 ile qalir.
--   * Bildiris novbeye yazilarkən nese xeta olsa, TEYINAT YARADILMASI POZULMUR (xeta udulur).
--   * Oldurme duymesi (app_state.push) sonukdurse hec ne edilmir.
--
--  ON SERT: 910.
-- =====================================================================

create or replace function app.trg_asg_push() returns trigger
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r    record;
  v_id bigint;
  v_t  text;
begin
  if not app.push_on() then return null; end if;

  for r in
    select st.id as sid, st.display_name as nm, st.account_id as acc,
           count(*)::int as n,
           (array_agg(t.title order by a.created_at, a.id))[1] as title,
           (array_agg(a.id    order by a.created_at, a.id))[1] as aid,
           min(a.opens_at) as opens
      from new_rows a
      join public.tests t    on t.id = a.test_id
      join public.students st on st.class_id = a.class_id and st.is_active
                              and (a.student_id is null or a.student_id = st.id)   -- ferdi teyinat YALNIZ hemin sagirde
     where a.closes_at is null or a.closes_at > now()
     group by st.id, st.display_name, st.account_id
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      v_t := left(btrim(coalesce(r.title, '')), 60);

      v_id := app.push_enqueue('student', r.sid, 'yeni_test', 'yeni:s:' || r.sid || ':' || r.aid,
        'Yeni test',
        case when r.n = 1 then '«' || v_t || '» testi verildi.' else r.n || ' yeni test verildi.' end,
        null, 5);
      if v_id is not null and r.opens > now() then
        update public.push_outbox set send_after = greatest(send_after, app.push_quiet_next(r.opens)) where id = v_id;
      end if;

      v_id := app.push_enqueue('parent', r.sid, 'yeni_test', 'yeni:p:' || r.sid || ':' || r.aid,
        'Yeni test',
        case when r.n = 1 then r.nm || ' üçün yeni test verildi: «' || v_t || '».'
             else r.nm || ' üçün ' || r.n || ' yeni test verildi.' end,
        null, 5);
      if v_id is not null and r.opens > now() then
        update public.push_outbox set send_after = greatest(send_after, app.push_quiet_next(r.opens)) where id = v_id;
      end if;
    exception when others then
      raise warning 'push yeni test: % (%)', sqlerrm, sqlstate;       -- teyinat yaranmasi pozulmasin
    end;
  end loop;
  return null;
end $$;

revoke all on function app.trg_asg_push() from public, anon, authenticated;

drop trigger if exists trg_asg_push on public.assignments;
create trigger trg_asg_push
  after insert on public.assignments
  referencing new table as new_rows
  for each statement execute function app.trg_asg_push();

-- ---------------------------------------------------------------------
--  SAKIT SAAT ACARI (yoxlama ucun).  Gece 21:00-10:00 qaydasi hele de ilkin vezyyetdir.
--  Yoxlayanda sondurmek ucun:   update public.app_state set val = val || '{"quiet": false}' where key = 'push';
--  Geri yandirmaq ucun:         update public.app_state set val = val || '{"quiet": true}'  where key = 'push';
--  (acar yoxdursa ve ya «true»-dursa sakit saat ISLEYIR.)
--  910-daki funksiya immutable idi - indi cedvele baxdigi ucun stable-dir.
-- ---------------------------------------------------------------------
create or replace function app.push_quiet_next(p_ts timestamptz) returns timestamptz
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select case
    when not coalesce((select (val->>'quiet')::boolean from public.app_state where key = 'push'), true)
      then p_ts
    when extract(hour from (p_ts at time zone 'Asia/Baku')) >= 21
      then (((p_ts at time zone 'Asia/Baku')::date + 1) + time '10:00') at time zone 'Asia/Baku'
    when extract(hour from (p_ts at time zone 'Asia/Baku')) < 10
      then (((p_ts at time zone 'Asia/Baku')::date) + time '10:00') at time zone 'Asia/Baku'
    else p_ts end
$$;
revoke all on function app.push_quiet_next(timestamptz) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Bildirise basanda dogru bolme acilsin: url verilmeyibse (ve ya './' - saytin kokudur)
--  sagird ucun ./sagird/, valideyn ucun ./valideyn/.  (910-daki './' bildirise basanda
--  esas sehifeye aparirdi.)  Funksiyanin qalani 910-la eynidir.
-- ---------------------------------------------------------------------
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
          left(p_title, 80), left(p_body, 200), left(case when p_url is null or p_url = './' then case p_role when 'parent' then './valideyn/' else './sagird/' end else p_url end, 300),
          case when p_kind = 'test' then now() else app.push_quiet_next(now()) end)
  on conflict (dedupe_key) do nothing
  returning id into v_id;
  return v_id;
end $$;
revoke all on function app.push_enqueue(text, uuid, text, text, text, text, text, int) from public, anon, authenticated;
