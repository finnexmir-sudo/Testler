-- =====================================================================
--  smoke_pq_cehd.sql : 927 - app.pq_seed 200 cehd edir (evvel 40)
--
--  Sert shertli sablon: a,b = 1..15, shert a=b  (tesadufi tutma ehtimali 1/15).
--    40 cehd:  (14/15)^40  = 6 %   yuklemede sinir / render pozulmus qiymet verir
--    200 cehd: (14/15)^200 = 1e-6  praktik olaraq heç vaxt
--  400 cagiris: strict ile heç biri xeta atmamalidir; strict olmayanda heç bir
--  qaytarilan qiymet shertini POZMAMALIDIR.  Evvelki 40 cehdle bu test ~30 xeta tapir (34 / 400).
--
--  ISTIFADE:  psql -f db/test/smoke_pq_cehd.sql
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

do $$
declare
  p jsonb := '{"vars":{"a":[1,15],"b":[1,15]},"cond":"a=b"}'::jsonb;
  v jsonb; i int; v_xeta int := 0; v_poz int := 0;
begin
  for i in 1 .. 400 loop
    begin
      v := app.pq_seed(p, null, true);
      if (v->>'a') <> (v->>'b') then v_poz := v_poz + 1; end if;
    exception when others then
      v_xeta := v_xeta + 1;
    end;
  end loop;
  assert v_xeta = 0, 'strict: ' || v_xeta || ' / 400 cagirisda shert tapilmadi (200 cehd kifayet etmeli idi)';
  assert v_poz = 0, 'strict: shertini pozan qiymet qaytdi: ' || v_poz;

  v_poz := 0;
  for i in 1 .. 400 loop
    v := app.pq_seed(p, null, false);
    if (v->>'a') <> (v->>'b') then v_poz := v_poz + 1; end if;
  end loop;
  assert v_poz = 0, 'strict deyil: ' || v_poz || ' / 400 qiymet shertini pozdu';
end $$;
\echo 'OK  1 · sert shertli sablon (1/15): 400 cagirisda xeta yox, shertini pozan qiymet yox'

--  shert YOXDUR / asan shert: qiymet ilk cehdde cixir, davranis eynidir
do $$
declare v jsonb; i int;
begin
  for i in 1 .. 50 loop
    v := app.pq_seed('{"vars":{"a":[100,999],"b":[100,999]},"cond":"a>b"}'::jsonb, null, true);
    assert (v->>'a')::int > (v->>'b')::int, 'asan shert pozuldu';
    v := app.pq_seed('{"vars":{"a":[1,9]}}'::jsonb, null, true);
    assert (v->>'a')::int between 1 and 9, 'shertsiz sablon aralıqdan çıxdı';
  end loop;
end $$;
\echo 'OK  2 · asan shert / shertsiz sablon eyni isleyir'

--  tapilmaz shert: strict XETA atir (200 cehdden sonra), strict deyil son qiymeti qaytarir (test dayanmasin)
do $$
declare v jsonb; m text;
begin
  begin perform app.pq_seed('{"vars":{"a":[1,5]},"cond":"a>100"}'::jsonb, null, true); assert false, 'strict xeta atmadi';
  exception when others then m := sqlerrm; end;
  assert m like '%uyğun qiymət tapılmadı%', 'strict xeta mesaji: ' || m;
  v := app.pq_seed('{"vars":{"a":[1,5]},"cond":"a>100"}'::jsonb, null, false);
  assert v is not null and (v->>'a') is not null, 'strict deyil: son qiymet qaytarilmali idi';
end $$;
\echo 'OK  3 · tapilmaz shert: strict xeta, strict deyil son qiymet (test dayanmir)'
\echo 'smoke_pq_cehd: HAMISI KECDI'
