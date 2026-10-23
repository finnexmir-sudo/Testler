-- =====================================================================
--  930 : SINIF ADLARININ SEKILCISI - KOHNE BAZADA DA  (2026-10-23)
--
--  PROBLEM (UX yoxlamasi, 23.10 - canlida goruldu)
--  Canli sayt «3-ci, 4-ci, 6-ci, 9-ci sinif» yazir (qrup yaratma, Sual
--  banki, movzu siyahisi «… · 3-ci sinif»).  Duzgunu: 3-cü, 4-cü, 6-cı, 9-cu.
--
--  SEBEB
--  e1b14b9 (24.08) app.ordinal_az() funksiyasini yazdi ve 04_seed-de
--  sinif adlarini onunla qurdu.  Amma setirler «on conflict do nothing»
--  ile yazilir: TEZE bazada ad duzgun cixir, ondan EVVEL yaranmis canli
--  setirler ise hec vaxt yenilenmeyib.  Yerli yoxlamalar teze bazada
--  getdiyi ucun xeta gorunmurdu.
--
--  HELL
--  Bir defelik: adi «<reqem>-c? sinif» qelibinde olan ve ordinal_az ile
--  ferqlenen setirler duzgun ada cekilir.  Basqa ad (el ile deyisdirilmis)
--  toxunulmur.  Tekrar isledilende hec ne deyismir (idempotent).
--  Muellimlerin oz yazdigi metnlere (test adi, qrup adi) TOXUNULMUR.
--
--  ON SERT: 04 (app.ordinal_az).
-- =====================================================================

do $$
declare n int;
begin
  update public.levels l
     set name = app.ordinal_az(l.code::int) || ' sinif'
   where l.code ~ '^[0-9]{1,2}$'
     and l.name ~ '^[0-9]{1,2}-c[iıuü] sinif$'
     and l.name <> app.ordinal_az(l.code::int) || ' sinif';
  get diagnostics n = row_count;
  raise notice '930 OK - % sinif adi duzeldildi.', n;
end $$;
