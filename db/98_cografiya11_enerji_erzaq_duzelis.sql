-- =====================================================================
--  98_cografiya11_enerji_erzaq_duzelis.sql :
--  Cografiya 11 "Enerji ve erzaq tehlukesizliyi" alt movzusunu doldurur
--
--  90_alt_movzular_cografiya6_11.sql ilk versiyada kitab 814-un
--  "5. QLOBAL PROBLEMLER" bolmesinin butun 11 bendini (o cumleden
--  "Alternativ enerji menbeleri" ve "Dunyanin erzaq problemi")
--  cog-11-ekoloji-qlobal movzusuna salmisdi - sehife serhedi ile aydin
--  bolunmurdu deye. Neticede cog-11-enerji-erzaq 0 alt movzu qalirdi.
--
--  Amma bu iki bendin öz METNI mövzunun adi ("Enerji ve erzaq
--  tehlukesizliyi") ile birbasa uygun gelir. tools/alt_movzular.py-a
--  bu sessiyada elave olunan "callable" (mezmuna gore tesnif) valideyn
--  formasi ile 90 yeniden cixarildi - bu iki bend indi duz oz
--  movzusuna gedir, qalan 9 bend (diaqnostik/layihe/umumilesdirici +
--  4 ekoloji ders) cog-11-ekoloji-qlobal-da qalir.
--
--  Movzu yeniden cixarilanda KOHNE setirler (cog-11-ekoloji-qlobal-*
--  slug-i ile) avtomatik silinmir - generator hec vaxt silmir (ozunun
--  qaydasidir).  Bu fayl onlari YENI setirler artiq movcud oldugunu
--  YOXLAYIB silir - itki sessiz olmur, yoxlama uğursuz olsa xeta atir.
--
--  UCUNCU YAN TESIR (ilk versiyada gozden qacib, canli bazada
--  "66 gozlenilirdi, 69 tapildi" xetasi ile tapildi): "Alternativ
--  enerji menbeleri" ve "Dunyanin erzaq problemi" cog-11-ekoloji-
--  qlobal-dan cixanda, qalan bendlerin sozluk-tezliyi hesabi da
--  deyisdi - "Dunyanin icmeli su problemi" bendinin oz slug-u da
--  YAN TESIR kimi deyisdi (cog-11-ekoloji-qlobal-icmeli-problemi ->
--  cog-11-ekoloji-qlobal-dunyanin-icmeli, EYNI valideyn daxilinde,
--  sadece slug METNI deyisib).  Bu da 3-cu kohne setir kimi qalir.
--
--  ON SERT: 90_alt_movzular_cografiya6_11.sql (yenilenmis versiya)
--  islenmis olmalidir. Tekrar isledile biler.  SONRA: 05_grants.sql.
-- =====================================================================

do $$
declare
  v_subj uuid;
  v_yeni1 uuid;
  v_yeni2 uuid;
  v_yeni3 uuid;
  v_kohne1 uuid;
  v_kohne2 uuid;
  v_kohne3 uuid;
  v_silinen int := 0;
begin
  select id into v_subj from public.subjects where slug = 'cografiya';

  select id into v_yeni1 from public.topics
   where subject_id = v_subj and slug = 'cog-11-enerji-erzaq-alternativ-menbeleri';
  select id into v_yeni2 from public.topics
   where subject_id = v_subj and slug = 'cog-11-enerji-erzaq-dunyanin-problemi';
  select id into v_yeni3 from public.topics
   where subject_id = v_subj and slug = 'cog-11-ekoloji-qlobal-dunyanin-icmeli';
  if v_yeni1 is null or v_yeni2 is null or v_yeni3 is null then
    raise exception 'ONCE 90_alt_movzular_cografiya6_11.sql (yenilenmis) '
                    'isledilmelidir - yeni alt movzular tapilmadi';
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
    raise notice 'Kohne setirler artiq yoxdur - fayl evvel isledilib.';
  else
    raise notice 'Kohne % setir silindi.', v_silinen;
  end if;
end $$;

-- ------------------------------------------------------- oz yoxlamasi
do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id and p.slug = 'cog-11-enerji-erzaq'
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya';
  if k <> 2 then
    raise exception 'cog-11-enerji-erzaq: 2 alt movzu gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'cografiya'
   where t.slug in ('cog-11-ekoloji-qlobal-alternativ-enerji',
                     'cog-11-ekoloji-qlobal-erzaq-problemi',
                     'cog-11-ekoloji-qlobal-icmeli-problemi');
  if k > 0 then
    raise exception 'kohne setirler heleki qalib: %', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'cografiya'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 66 then
    raise exception 'cografiya 11-ci alt movzulari: 66 gozlenilirdi, % tapildi', k;
  end if;

  raise notice 'Cografiya 11 enerji-erzaq duzeldi: 66 alt movzu, hamisi yerinde.';
end $$;
