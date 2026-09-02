-- =====================================================================
--  94_umumi_tarix_8_9_11_restruktur.sql :
--  Umumi tarix 8, 9, 11-ci siniflerin movzu adlarini heqiqi derslik
--  bolme strukturuna uygunlasdirir.
--
--  TAPILAN UYGUNSUZLUQ: bu 558 sual (8/9/11-ci sinif, evvelki sessiya
--  yazib) e-derslik.edu.az-daki HEQIQI dersliyin bolme strukturuna
--  deyil, umumi tarixi bilikden qurulmus movzu adlarina baglanmisdi.
--  Portalda (istifadeci ozu kitab ID-lerini tapib yoxlayib tesdiqledi):
--
--    8-ci sinif (kitab 791) - 2 bolme:
--      "Serq olkeleri XVII-XVIII yuzilliklerde"
--      "Avropa ve Amerika XVII-XVIII yuzilliklerde"
--    9-cu sinif (kitab 879) - 3 bolme:
--      "Dunya olkeleri XIX-XX yuzilliyin evvellerinde"
--      "Dunya olkeleri 1918-1945-ci illerde"
--      "Dunya olkeleri Ikinci dunya muharibesinden sonra"
--    11-ci sinif (kitab 809) - eyni 3 bolme (11-ci sinif ucun)
--
--  Kohne agacimiz tema/dovr esasli idi (mes. "Boyuk cografi kesfler",
--  "Senaye cevrilisi") - derslikde bele bolme YOXDUR. Bu, "Ders plani"
--  muellim funksiyasini pozur: muellim "kecildi" qeyd edende gorduyu
--  ders adi ile bizim movzu adimiz uygun gelmirdi.
--
--  SEBEB: bu banki (8/9/11) evvelki sessiya umumi tarix biliyinden
--  yazib, hemin sinifler ucun heqiqi mundericat cekilmeyib (7 ve
--  10-cu sinifde cekilmisdi, onlar duzgun cixmisdi - bax db/66-71).
--
--  QERAR (istifadeci ile tesdiqlenib): kohne movzular real bolme
--  seviyyesine BIRLESIR. Butun 558 sualin metni oxunub tesdiqlenib ki,
--  hansi kohne movzu hansi bolmeye aiddir - HEC BIR SUAL ITMIR ve HEC
--  BIRI SEHV yerde qalmir:
--
--    8-ci sinif: "kesf/intibah/inqilablar/maarifcilik/abs-fransa"
--      besi de Avropa/Amerika mezmunudur -> "Avropa ve Amerika"
--      bolmesine birlesir (survivor: kohne "kesf" setri, slug/id
--      saxlanilir); "serq" oz-ozune "Serq olkeleri" bolmesidir (adi
--      yenilenir, sual toxunulmur).
--    9-cu sinif: movcud 186 sualin HAMISI I Dunya muharibesine qeder
--      olan dovru ehate edir (senaye/napoleon/birlesme/abs/serq/
--      birinci) -> "Dunya olkeleri XIX-XX evvelinde" bolmesine
--      birlesir (survivor: kohne "senaye" setri). Qalan 2 bolme
--      (1918-1945, IDM-den sonra) hazirda SUALSIZDIR - bos movzu
--      kimi acilir, gelecekde doldurulacaq.
--    11-ci sinif: movcud 186 sual esasen IDM-den sonraki dovrdur
--      (versal/bohran/ikinci -> "1918-1945"; soyuq/mustemleke/muasir
--      -> "IDM-den sonra"). Ilk bolme (XIX-XX evveli) bu sinifde
--      SUALSIZDIR - bos movzu kimi acilir.
--
--  "utarix-9-birlesme" (Italiya/Almaniya birlesmesi) bu sessiyada real
--  sagird pilotunda islenmis movzu idi - sualları itmir, sadece daha
--  genis bolmeye kocurulur (topic_id deyisir, mezmun eynidir).
--
--  attempt_answers.topic_id de eyni qaydada kocurulur (sadece
--  questions.topic_id yox) - yoxsa kecmis cehdlerin zeif-movzu
--  hesabati kohne movzu silinende sessizce null-a duserdi.
--
--  RISK (canli Supabase-de, burada test edile bilmir): eger hansisa
--  muellim artiq bu movzulardan birini oz ders planina salibsa,
--  `class_plan_items.topic_id` `on delete restrict`-dir - asagidaki
--  DELETE xeta ile dayanacaq. Bu SESSIZ itki demek deyil - xeta acig
--  gosterecek ki, hansi movzu plana baglidir; o halda muellimle elaqe
--  saxlanib movzu elle deyisdirilmelidir, sonra bu fayl yeniden
--  isledilir (tekrar isledile bilir).
--
--  ON SERT: 53_movzular_umumi_tarix.sql, 54_bank_tarix_umumi.sql,
--  66_movzular_umumi_tarix6_8.sql, 67_bank_tarix_umumi6_8.sql
--  islenmis olmalidir (8/9/11-ci sinif umumi tarix movzu + bank).
--  Tekrar isledile biler. SONRA: 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.subjects where slug = 'umumi-tarix') then
    raise exception 'ONCE 53_movzular_umumi_tarix.sql isledilmelidir '
                    '(umumi-tarix fenni tapilmadi)';
  end if;
end $$;

-- --------------------------------------------------------- 8-ci sinif
do $$
declare
  v_subj uuid;
  v_serq uuid;
  v_amer uuid;
  v_old  uuid;
  v_slug text;
  k int; v_sual int := 0;
begin
  select id into v_subj from public.subjects where slug = 'umumi-tarix';

  if not exists (select 1 from public.topics
                  where subject_id = v_subj and slug = 'utarix-8-kesf') then
    raise notice '8-ci sinif artiq restruktur olunub, kecdim.';
    return;
  end if;

  update public.topics
     set name = 'Şərq ölkələri XVII-XVIII yüzilliklərdə', sort = 10
   where subject_id = v_subj and slug = 'utarix-8-serq'
  returning id into v_serq;

  update public.topics
     set slug = 'utarix-8-avropa-amerika',
         name = 'Avropa və Amerika XVII-XVIII yüzilliklərdə',
         sort = 20
   where subject_id = v_subj and slug = 'utarix-8-kesf'
  returning id into v_amer;

  if v_serq is null or v_amer is null then
    raise exception '8-ci sinif: serq/kesf movzusu tapilmadi';
  end if;

  foreach v_slug in array array['utarix-8-intibah', 'utarix-8-inqilablar',
                                 'utarix-8-maarifcilik', 'utarix-8-abs-fransa']
  loop
    select id into v_old from public.topics
     where subject_id = v_subj and slug = v_slug;
    continue when v_old is null;

    update public.questions set topic_id = v_amer where topic_id = v_old;
    get diagnostics k = row_count; v_sual := v_sual + k;
    update public.attempt_answers set topic_id = v_amer where topic_id = v_old;

    delete from public.topics where id = v_old;
  end loop;

  raise notice '8-ci sinif restruktur olundu: % sual "Avropa ve Amerika" '
               'movzusuna kocuruldu.', v_sual;
end $$;

-- --------------------------------------------------------- 9-cu sinif
do $$
declare
  v_subj uuid;
  v_lvl  uuid;
  v_d1   uuid;
  v_old  uuid;
  v_slug text;
  k int; v_sual int := 0;
begin
  select id into v_subj from public.subjects where slug = 'umumi-tarix';
  select l.id into v_lvl from public.levels l
    join public.programs p on p.id = l.program_id
   where l.code = '9' and p.slug = 'orta';

  if not exists (select 1 from public.topics
                  where subject_id = v_subj and slug = 'utarix-9-senaye') then
    raise notice '9-cu sinif artiq restruktur olunub, kecdim.';
    return;
  end if;
  if v_lvl is null then
    raise exception '9-cu sinif "orta" proqraminda tapilmadi';
  end if;

  update public.topics
     set slug = 'utarix-9-dunya-1',
         name = 'Dünya ölkələri XIX-XX yüzilliyin əvvəllərində',
         sort = 10
   where subject_id = v_subj and slug = 'utarix-9-senaye'
  returning id into v_d1;

  foreach v_slug in array array['utarix-9-napoleon', 'utarix-9-birlesme',
                                 'utarix-9-abs', 'utarix-9-serq',
                                 'utarix-9-birinci']
  loop
    select id into v_old from public.topics
     where subject_id = v_subj and slug = v_slug;
    continue when v_old is null;

    update public.questions set topic_id = v_d1 where topic_id = v_old;
    get diagnostics k = row_count; v_sual := v_sual + k;
    update public.attempt_answers set topic_id = v_d1 where topic_id = v_old;

    delete from public.topics where id = v_old;
  end loop;

  insert into public.topics (subject_id, level_id, slug, name, sort) values
    (v_subj, v_lvl, 'utarix-9-dunya-2',
     'Dünya ölkələri 1918-1945-ci illərdə', 20),
    (v_subj, v_lvl, 'utarix-9-dunya-3',
     'Dünya ölkələri İkinci dünya müharibəsindən sonra', 30)
  on conflict (subject_id, slug) do nothing;

  raise notice '9-cu sinif restruktur olundu: % sual kocuruldu, '
               '2 bos movzu (1918-1945, IDM-den sonra) acildi.', v_sual;
end $$;

-- -------------------------------------------------------- 11-ci sinif
do $$
declare
  v_subj uuid;
  v_lvl  uuid;
  v_d2   uuid;
  v_d3   uuid;
  v_old  uuid;
  v_slug text;
  k int; v_sual int := 0;
begin
  select id into v_subj from public.subjects where slug = 'umumi-tarix';
  select l.id into v_lvl from public.levels l
    join public.programs p on p.id = l.program_id
   where l.code = '11' and p.slug = 'orta';

  if not exists (select 1 from public.topics
                  where subject_id = v_subj and slug = 'utarix-11-versal') then
    raise notice '11-ci sinif artiq restruktur olunub, kecdim.';
    return;
  end if;
  if v_lvl is null then
    raise exception '11-ci sinif "orta" proqraminda tapilmadi';
  end if;

  update public.topics
     set slug = 'utarix-11-dunya-2',
         name = 'Dünya ölkələri 1918-1945-ci illərdə',
         sort = 20
   where subject_id = v_subj and slug = 'utarix-11-versal'
  returning id into v_d2;

  foreach v_slug in array array['utarix-11-bohran', 'utarix-11-ikinci']
  loop
    select id into v_old from public.topics
     where subject_id = v_subj and slug = v_slug;
    continue when v_old is null;

    update public.questions set topic_id = v_d2 where topic_id = v_old;
    get diagnostics k = row_count; v_sual := v_sual + k;
    update public.attempt_answers set topic_id = v_d2 where topic_id = v_old;

    delete from public.topics where id = v_old;
  end loop;

  update public.topics
     set slug = 'utarix-11-dunya-3',
         name = 'Dünya ölkələri İkinci dünya müharibəsindən sonra',
         sort = 30
   where subject_id = v_subj and slug = 'utarix-11-soyuq'
  returning id into v_d3;

  if v_d2 is null or v_d3 is null then
    raise exception '11-ci sinif: versal/soyuq movzusu tapilmadi';
  end if;

  foreach v_slug in array array['utarix-11-mustemleke', 'utarix-11-muasir']
  loop
    select id into v_old from public.topics
     where subject_id = v_subj and slug = v_slug;
    continue when v_old is null;

    update public.questions set topic_id = v_d3 where topic_id = v_old;
    get diagnostics k = row_count; v_sual := v_sual + k;
    update public.attempt_answers set topic_id = v_d3 where topic_id = v_old;

    delete from public.topics where id = v_old;
  end loop;

  insert into public.topics (subject_id, level_id, slug, name, sort) values
    (v_subj, v_lvl, 'utarix-11-dunya-1',
     'Dünya ölkələri XIX yüzillik-XX yüzilliyin əvvəllərində', 10)
  on conflict (subject_id, slug) do nothing;

  raise notice '11-ci sinif restruktur olundu: % sual kocuruldu, '
               '1 bos movzu (XIX-XX evveli) acildi.', v_sual;
end $$;

-- ------------------------------------------------------- oz yoxlamasi
do $$
declare k int; n int;
begin
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '8'
   where t.parent_id is null;
  if k <> 2 then
    raise exception '8-ci sinif umumi tarixde 2 movzu gozlenilirdi, % tapildi', k;
  end if;
  select count(*) into n from public.questions q
    join public.topics   t on t.id = q.topic_id
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '8';
  if n <> 186 then
    raise exception '8-ci sinifde 186 sual gozlenilirdi, % tapildi', n;
  end if;

  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '9'
   where t.parent_id is null;
  if k <> 3 then
    raise exception '9-cu sinifde 3 movzu gozlenilirdi, % tapildi', k;
  end if;
  select count(*) into n from public.questions q
    join public.topics   t on t.id = q.topic_id
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '9';
  if n <> 186 then
    raise exception '9-cu sinifde 186 sual gozlenilirdi, % tapildi', n;
  end if;

  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '11'
   where t.parent_id is null;
  if k <> 3 then
    raise exception '11-ci sinifde 3 movzu gozlenilirdi, % tapildi', k;
  end if;
  select count(*) into n from public.questions q
    join public.topics   t on t.id = q.topic_id
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '11';
  if n <> 186 then
    raise exception '11-ci sinifde 186 sual gozlenilirdi, % tapildi', n;
  end if;

  raise notice 'Restruktur tesdiqlendi: 8/9/11-ci sinif umumi tarix - '
               '2/3/3 movzu, 186/186/186 sual, hec biri itmeyib.';
end $$;
