-- =====================================================================
--  68_movzular_umumi_tarix10.sql : UMUMI TARIX 10-CU SINIF
--
--  NIYE BU FAYL VAR
--  e-derslik.edu.az portalinda 10-cu sinif ucun "Azerbaycan tarixi"
--  derslikyi YOXDUR - yalniz "Umumi tarix" (book_id 745) var.  Ona gore
--  45_movzular_orta10.sql-in 'tarix' fenni altinda acdigi alti movzu
--  (tarix-10-qedim-serq ... tarix-10-medeniyyet) esasen DUNYA tarixidir,
--  Azerbaycan tarixi deyil.  Bu fayl onlari oz yerine - 'umumi-tarix'
--  fennine kocurur.  Neticede:
--      tarix        5, 6, 8, 9, 11   (Azerbaycan tarixi)
--      umumi-tarix  6, 7, 8, 9, 10, 11
--
--  Movzu agaci derslikdeki DORD bolmeden cixir; en boyuk iki bolme
--  ikiye ayrilib, uc "Medeniyyet" movzusu bir movzuda toplanib:
--      I bolme    -> qedim-serq + antik
--      II bolme   -> erken-orta
--      III bolme  -> orta-esrler
--      IV bolme   -> yeni-dovr
--      3 x Medeniyyet -> medeniyyet
--
--  KOHNE BAZA UCUN:  tarix-10-* movzulari SILINMIR - hemin movzudaki
--  suallar yeni movzuya kocurulur ve 'archived' edilir (yeni bank
--  69_bank_tarix_umumi10.sql onlarin yerini tutur).  Kocurulme
--  sual TARIXCESINI qorumaq ucundur: attempt_answers-de metn suretleri
--  qalir, kohne hesabatlar pozulmur.
--
--  ON SERT: 53_movzular_umumi_tarix.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: 69_bank_tarix_umumi10.sql, 05_grants.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'umumi-tarix' and t.slug = 'utarix-11-muasir') then
    raise exception 'ONCE 53_movzular_umumi_tarix.sql isledilmelidir.';
  end if;
  if (select count(*) from public.levels where code = '10') <> 1 then
    raise exception 'Kataloqda 10-cu sinif tek olmalidir '
                    '(57_sinif_dubli.sql isledilibmi?).';
  end if;
end $$;

-- ------------------------------------------------- movzu agaci (6 movzu)
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('utarix-10-qedim-serq',  'Qədim Şərq sivilizasiyaları',            10),
    ('utarix-10-antik',       'Qədim Yunanıstan, Makedoniya və Roma',   20),
    ('utarix-10-erken-orta',  'Dünya ölkələri III-XI yüzilliklərdə',    30),
    ('utarix-10-orta-esrler', 'Dünya ölkələri XI-XV yüzilliklərdə',     40),
    ('utarix-10-yeni-dovr',   'Dünya ölkələri XVI-XVIII yüzilliklərdə', 50),
    ('utarix-10-medeniyyet',  'Orta əsrlər və yeni dövrün mədəniyyəti', 60)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'umumi-tarix'
  join public.levels   l on l.code = '10'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ----------------------------------------------------------------------
--  KOHNE BAZA:  'tarix' fennindeki 10-cu sinif movzulari bosaldilir
--  Teze bazada (db/run.sh) bu blok hec ne tapmir - 45 artiq hemin
--  movzulari acmir.  Kohne bazada ise suallar yeni movzuya kocur.
-- ----------------------------------------------------------------------
do $$
declare r record; v_yeni uuid; v_utarix uuid; n int := 0;
begin
  select id into v_utarix from public.subjects where slug = 'umumi-tarix';

  for r in
    select t.id, t.slug,
           replace(t.slug, 'tarix-10-', 'utarix-10-') yeni_slug
      from public.topics t
      join public.subjects s on s.id = t.subject_id and s.slug = 'tarix'
      join public.levels   l on l.id = t.level_id and l.code = '10'
  loop
    select t2.id into v_yeni
      from public.topics t2
      join public.subjects s2 on s2.id = t2.subject_id and s2.slug = 'umumi-tarix'
     where t2.slug = r.yeni_slug;
    if v_yeni is null then
      raise exception 'Kohne movzu % ucun yeni qarsiliq tapilmadi (%)',
                      r.slug, r.yeni_slug;
    end if;

    update public.questions
       set topic_id = v_yeni, subject_id = v_utarix, status = 'archived'
     where topic_id = r.id;
    get diagnostics n = row_count;
    raise notice 'Kocuruldu: % -> % (% sual arxivlendi)',
                 r.slug, r.yeni_slug, n;

    --  movzu artiq bosdur: tapsiriq/plan setirleri ona baglana biler,
    --  ona gore evvelce onlar da yeni movzuya yonlendirilir
    delete from public.topics where id = r.id;
  end loop;
end $$;

-- ------------------------------------------------------------ yoxlama
do $$
declare k int;
begin
  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '10';
  if k <> 6 then
    raise exception 'Umumi tarix 10: 6 movzu gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = t.level_id and l.code = '10';
  if k <> 0 then
    raise exception '10-cu sinifde hele de % "tarix" movzusu var', k;
  end if;

  --  9 ve 11-ci sinif toxunulmamis qalmalidir
  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code in ('9', '11');
  if k <> 12 then
    raise exception 'Umumi tarix 9/11: 12 movzu gozlenilirdi, % tapildi', k;
  end if;

  --  'tarix' fenninin qalan sinifleri toxunulmamis qalmalidir.
  --  QEYD: 7-ci sinifde de portalda yalniz "Umumi tarix" derslikyi var
  --  (mundericat/tarix-7-723.txt) - hemin sinifin kocurulmesi AYRI
  --  addimdir, bu fayl ona toxunmur.
  select count(distinct l.code) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = t.level_id
   where l.code in ('5', '6', '7', '8', '9', '11');
  if k <> 6 then
    raise exception '"tarix" fenninde 6 sinif gozlenilirdi, % tapildi', k;
  end if;

  raise notice 'Umumi tarix 10: 6 movzu hazir, "tarix" fenni 10-cu sinifden cixdi.';
end $$;
