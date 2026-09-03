-- =====================================================================
--  98_cografiya11_enerji_erzaq_duzelis.sql :
--  Cografiya 11 "Enerji ve erzaq tehlukesizliyi" alt movzusunu doldurur
--  ucun kohne (evvelki versiya) setirleri temizleyir
--
--  90_alt_movzular_cografiya6_11.sql ilk versiyada kitab 814-un
--  "5. QLOBAL PROBLEMLER" bolmesinin butun 11 bendini (o cumleden
--  "Alternativ enerji menbeleri" ve "Dunyanin erzaq problemi")
--  cog-11-ekoloji-qlobal movzusuna salmisdi - sehife serhedi ile aydin
--  bolunmurdu deye. Neticede cog-11-enerji-erzaq 0 alt movzu qalirdi.
--  Amma bu iki bendin öz METNI mövzunun adi ("Enerji ve erzaq
--  tehlukesizliyi") ile birbasa uygun gelir. tools/alt_movzular.py-a
--  bu sessiyada elave olunan "callable" (mezmuna gore tesnif) valideyn
--  formasi ile 90 yeniden cixarildi.
--
--  UCUNCU YAN TESIR: "Alternativ enerji menbeleri" ve "Dunyanin erzaq
--  problemi" cog-11-ekoloji-qlobal-dan cixanda, qalan bendlerin
--  sozluk-tezliyi hesabi da deyisdi - bu, "Dunyanin icmeli su
--  problemi" bendinin oz slug-unu da deyisdirdi (EYNI valideyn
--  daxilinde, sadece slug METNI - icmeli-problemi -> dunyanin-icmeli).
--
--  UC KOHNE SETIR (cog-11-ekoloji-qlobal-alternativ-enerji,
--  -erzaq-problemi, -icmeli-problemi) generator terefinden avtomatik
--  SILINMIR - generator hec vaxt silmir (ozunun qaydasidir).  Bu fayl
--  onlari BURADA, tek-tek slug ile, QEYD-SIZ silir.
--
--  SIRA VACIBDIR - BU FAYL 90-DAN EVVEL ISLEDILIR:
--  Canli bazada tapildi ki, Supabase SQL Editor bütün yapisdirilan
--  skripti TEK TRANZAKSIYA kimi isledir.  90 evvel islenib, sonra
--  YENIDEN (yenilenmis versiya ile) islense - onun oz sondaki
--  yoxlamasi kohne 3 setir hele silinmeyibse "gozlenilen saydan
--  artiq tapdim" deye xeta atir, ve BUTUN transaksiya (o cumleden
--  10 saniye evvel uğurla islenmis INSERT) GERI QAYIDIR (rollback) -
--  yeni setirler HEC VAXT yadda qalmir.  Ona gore: EVVELCE bu fayli
--  (98) islet - o, kohne 3 setiri BILAVASITƏ (90-in yeni setirlerini
--  gozlemeden) silir - SONRA 90-i (yenilenmis versiya) islet - o vaxt
--  onun öz sayi ilk defeden duz cixir, xeta olmur.
--
--  Tekrar isledile biler (hec bir sey yoxdursa sakitce kecir).
--  Fresh baza qurulanda da zererisizdir - kohne slug-lar hec vaxt
--  yaranmayib, DELETE sadece 0 setir tapir.
-- =====================================================================

do $$
declare
  v_subj uuid;
  v_kohne1 uuid;
  v_kohne2 uuid;
  v_kohne3 uuid;
  v_silinen int := 0;
begin
  select id into v_subj from public.subjects where slug = 'cografiya';
  if v_subj is null then
    return;                       -- cografiya fenni hele yoxdur (fresh baza erken merhele)
  end if;

  select id into v_kohne1 from public.topics
   where subject_id = v_subj and slug = 'cog-11-ekoloji-qlobal-alternativ-enerji';
  select id into v_kohne2 from public.topics
   where subject_id = v_subj and slug = 'cog-11-ekoloji-qlobal-erzaq-problemi';
  select id into v_kohne3 from public.topics
   where subject_id = v_subj and slug = 'cog-11-ekoloji-qlobal-icmeli-problemi';

  if v_kohne1 is not null then
    delete from public.topics where id = v_kohne1; v_silinen := v_silinen + 1;
  end if;
  if v_kohne2 is not null then
    delete from public.topics where id = v_kohne2; v_silinen := v_silinen + 1;
  end if;
  if v_kohne3 is not null then
    delete from public.topics where id = v_kohne3; v_silinen := v_silinen + 1;
  end if;

  if v_silinen = 0 then
    raise notice 'Cografiya 11: temizlenecek kohne setir yoxdur.';
  else
    raise notice 'Cografiya 11: % kohne setir silindi - indi 90-i '
                 '(yenilenmis versiya) islet.', v_silinen;
  end if;
end $$;
