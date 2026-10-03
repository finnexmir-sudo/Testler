-- =====================================================================
--  912 : PUSH BILDIRISLER - 3-cu merhele: xatirlatmalar (2026-10-05)
--
--  Iki avtomatik xatirlatma (saatda bir defe «push_tick» yoxlayir):
--    1. SON TARIX: muellimin verdiyi testin son tarixine 24 saatdan az qalib
--       ve sagird hele TEST ETMEYIB -> sagirde ve valideynine.
--    2. GUNDELIK: her gun 19:00-dan sonra «Bu gunun 5 suali hazirdir» -
--       yalniz abunesi aktiv, hesabi bagli olmayan, bu gun paketi bitirmeyen ve
--       kecilmis movzusu olan (yeni sual yigila bilen) sagirdlere.
--
--  QAYDALAR (910 ile eyni)
--   * Gunde en cox 2 bildiris (xatirlatmalar ucun), gece 21:00-10:00 sabaha kecir,
--     eyni hadise ikinci defe yazilmir (dedupe_key).
--   * «Yeni test» (911) ayridir ve 5-e qeder gedir.
--   * Sagirde ad yazilmir, valideynde usagin qisa adi yazilir.
--   * Xeta bir sagirde ucun olsa, qalanlara toxunmur (her biri ayri blokda).
--   * Oldurme duymesi (app_state.push = {"on": false}) bunlari da dayandirir.
--
--  PLANLAYICI.  Bu fayl pg_cron varsa «push-tick» tapsiriqini ozu yaradir (saatin 5-ci deqiqesi).
--  Elle:  select cron.schedule('push-tick', '5 * * * *', 'select app.push_tick()');
--  Dayandirmaq: select cron.unschedule('push-tick');
--
--  ON SERT: 910, 911.
-- =====================================================================

-- ------------------------------------------------ 1 · son tarix xatirlatmasi
create or replace function app.push_scan_deadlines() returns int
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  r      record;
  v_n    int := 0;
  v_when text;
  v_id   bigint;
  v_day  date := (now() at time zone 'Asia/Baku')::date;
begin
  if not app.push_on() then return 0; end if;

  for r in
    select a.id as aid, st.id as sid, st.display_name as nm, st.account_id as acc,
           t.title as title, a.closes_at as closes
      from public.assignments a
      join public.tests t     on t.id = a.test_id
      join public.students st on st.class_id = a.class_id and st.is_active
                             and (a.student_id is null or a.student_id = st.id)
     where a.closes_at > now() + interval '2 hours'
       and a.closes_at <= now() + interval '24 hours'
       and a.opens_at  <= now() - interval '6 hours'          -- yeni verilmis testi xatirlatmiriq («yeni test» artiq getdi)
       and not exists (select 1 from public.attempts at
                        where at.student_id = st.id and at.test_id = a.test_id and at.status = 'submitted')
       and exists (select 1 from public.push_subs s where s.student_id = st.id)
     order by a.closes_at
  loop
    begin
      if app.account_locked(r.acc) then continue; end if;
      if app.push_quiet_next(now()) >= r.closes then continue; end if;      -- bildiris son tarixden sonraya qalardi

      v_when := case when (r.closes at time zone 'Asia/Baku')::date = v_day then 'bu gün' else 'sabah' end
                || ' saat ' || to_char(r.closes at time zone 'Asia/Baku', 'HH24:MI');

      v_id := app.push_enqueue('student', r.sid, 'son_tarix', 'son:s:' || r.aid || ':' || r.sid,
        'Son tarix yaxınlaşır',
        '«' || left(btrim(coalesce(r.title, '')), 60) || '» testinin son tarixi ' || v_when || '. Hələ işləməmisən.',
        null);
      if v_id is not null then v_n := v_n + 1; end if;

      v_id := app.push_enqueue('parent', r.sid, 'son_tarix', 'son:p:' || r.aid || ':' || r.sid,
        'Son tarix yaxınlaşır',
        r.nm || ' üçün «' || left(btrim(coalesce(r.title, '')), 60) || '» testinin son tarixi ' || v_when || '. Hələ işlənməyib.',
        null);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push son tarix: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;

-- ------------------------------------------------ 2 · gundelik «5 sual»
--  p_now yalniz testler ucun (Baki saati ile 19:00-21:00 arasi isleyir; sonra gece sakitliyi).
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
        'Bu günün 5 sualı hazırdır',
        'Cəmi bir neçə dəqiqə — bu gün hələ çalışmamısan.',
        null);
      if v_id is not null then v_n := v_n + 1; end if;
    exception when others then
      raise warning 'push gundelik: % (%)', sqlerrm, sqlstate;
    end;
  end loop;
  return v_n;
end $$;

-- ------------------------------------------------ 3 · saatlig planlayici
create or replace function app.push_tick() returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_d int := 0;
  v_g int := 0;
begin
  if not app.push_on() then return jsonb_build_object('on', false); end if;
  begin v_d := app.push_scan_deadlines(); exception when others then raise warning 'push tick son tarix: %', sqlerrm; end;
  begin v_g := app.push_scan_daily();     exception when others then raise warning 'push tick gundelik: %', sqlerrm; end;
  begin perform app.push_cleanup();       exception when others then raise warning 'push tick temizlik: %', sqlerrm; end;
  return jsonb_build_object('on', true, 'son_tarix', v_d, 'gundelik', v_g);
end $$;

revoke all on function app.push_scan_deadlines()            from public, anon, authenticated;
revoke all on function app.push_scan_daily(timestamptz)     from public, anon, authenticated;
revoke all on function app.push_tick()                      from public, anon, authenticated;

-- ------------------------------------------------ planlayici (pg_cron varsa)
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'cron') then
    perform cron.schedule('push-tick', '5 * * * *', 'select app.push_tick()');
  else
    raise notice 'pg_cron yoxdur - push-tick planlayicisi yaradilmadi (elle yaradin).';
  end if;
end $$;
