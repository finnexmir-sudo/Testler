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
        './', 5);
      if v_id is not null and r.opens > now() then
        update public.push_outbox set send_after = greatest(send_after, app.push_quiet_next(r.opens)) where id = v_id;
      end if;

      v_id := app.push_enqueue('parent', r.sid, 'yeni_test', 'yeni:p:' || r.sid || ':' || r.aid,
        'Yeni test',
        case when r.n = 1 then r.nm || ' üçün yeni test verildi: «' || v_t || '».'
             else r.nm || ' üçün ' || r.n || ' yeni test verildi.' end,
        './', 5);
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
