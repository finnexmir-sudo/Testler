-- =====================================================================
--  96_alt_movzular_utarix8_9_11.sql : UMUMI TARIX 8,9,11 - ALT MOVZULAR
--
--  db/94-den sonra bu uc sinfin movzulari kitabin oz bolmelerine
--  bire-bir uygundur - hər bolme birbaşa öz movzusuna (8: serq/
--  avropa-amerika, 9 ve 11: dunya-1/2/3).  8-ci sinifin kitabinda
--  basdaki bos "1.Многочлены" bolmesi (basqa fennden qalma scraper
--  artefaktı) avtomatik xaric olunur - bendi yoxdur.
--
--  10-cu sinif AYRI paketdedir (97) - onun "Mədəniyyət" duzelisi bu
--  siniflerin oz "N. Mədəniyyət" bendlerine de tesadufen tetbiq
--  olardi (eyni paketde umumi ad-fallback toqquşurdu, bax 97-nin
--  basliq serhi).  Burada hər sinifin "Mədəniyyət" bendi zaten oz
--  ayrica bolmesinin (dunya-1/2/3) daxilindedir - toqquşma yoxdur,
--  duzelise ehtiyac da yoxdur.
--
--  YAZI QUSURU: 11-ci sinifde "2 .Fransa ve Almaniya" - nomre ile soz
--  arasinda sehv boşluqlu nöqte, dogru yazi "Fransa ve Almaniya".
--
--  MENBE: e-derslik.edu.az.  8: kitab 791.  9: 879.  11: 809.
--  Adlar EYNILE goturulur.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.  Duzelis skriptde
--  edilir, sonra SQL yeniden yaradilir.
--
--  XARIC EDILEN BENDLER: kitabin sonundaki aparat - "Sozluk",
--  "Cavablar", "Ozunuzu yoxlayin", "Mesele hellline numune",
--  "yarimil / sinif uzre umumilesdirici tapsiriqlar".  Bolmenin
--  dersi deyil.  db/74 de eyni qaydani tutub.
--
--  DIQQET
--   * questions cedveline TOXUNULMUR - suallar alt movzulara
--     baglanmir, teqler deyismir.  O, ayri merhelendir.
--   * Movcud ust movzu setirleri deyismir - yalniz parent kimi
--     islenir.  programs/levels-e de toxunulmur.
--   * Tekrar isledile biler (on conflict do update).
--   * db/102 movzu silmeyi bloklayir - bu fayl hec ne silmir.
-- =====================================================================
set search_path = public, extensions;

--  AD DUZELISLERI (mezmun deyismeyib):
--   * yazi (1): yazi qusuru (bosluq, herf)
--       11-ci  s.12   2 .Fransa ve Almaniya
--                    -> Fransa ve Almaniya

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  8-ci sinif  ============
    --  Serq olkeleri XVII-XVIII yuzilliklerde  (utarix-8-serq)
    ('utarix-8-serq', 'utarix-8-serq-qizilbas-dovletleri',
     'Qızılbaş dövlətləri', 10),
    ('utarix-8-serq', 'utarix-8-serq-boyuk-mogol',
     'Böyük Moğol dövləti', 20),
    ('utarix-8-serq', 'utarix-8-serq-cin',
     'Çin', 30),
    ('utarix-8-serq', 'utarix-8-serq-osmanli-imperiyasi',
     'Osmanlı imperiyası', 40),
    ('utarix-8-serq', 'utarix-8-serq-volqaboyu-ural',
     'Volqaboyu və Ural, Sibir, Mərkəzi Asiyanın türk xalqları', 50),
    ('utarix-8-serq', 'utarix-8-serq-qafqaz',
     'Qafqaz', 60),
    ('utarix-8-serq', 'utarix-8-serq-medeniyyet',
     'Mədəniyyət', 70),
    --  Avropa ve Amerika XVII-XVIII yuzilliklerde  (utarix-8-avropa-amerika)
    ('utarix-8-avropa-amerika', 'utarix-8-avropa-amerika-ingiltere',
     'İngiltərə', 10),
    ('utarix-8-avropa-amerika', 'utarix-8-avropa-amerika-simali',
     'Şimali Amerika', 20),
    ('utarix-8-avropa-amerika', 'utarix-8-avropa-amerika-fransa',
     'Fransa', 30),
    ('utarix-8-avropa-amerika', 'utarix-8-avropa-amerika-rusiya',
     'Rusiya', 40),
    ('utarix-8-avropa-amerika', 'utarix-8-avropa-amerika-medeniyyet',
     'Mədəniyyət', 50),
    --  ============  9-cu sinif  ============
    --  Dunya olkeleri XIX-XX yuzilliyin evvellerinde  (utarix-9-dunya-1)
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-amerika-birlesmis',
     'Amerika Birləşmiş Ştatları', 10),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-boyuk-britaniya',
     'Böyük Britaniya və Fransa', 20),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-almaniya-italiya',
     'Almaniya və İtaliya', 30),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-rusiya-imperiyasi',
     'Rusiya imperiyası', 40),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-turk-qacarlar',
     'Türk dünyası. Qacarlar dövləti', 50),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-hindistan-cin',
     'Hindistan, Çin və Yaponiya', 60),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-birinci-muharibesi',
     'Birinci dünya müharibəsi', 70),
    ('utarix-9-dunya-1', 'utarix-9-dunya-1-medeniyyet',
     'Mədəniyyət', 80),
    --  Dunya olkeleri 1918-1945-ci illerde  (utarix-9-dunya-2)
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-versal-vasinqton',
     'Versal-Vaşinqton sistemi', 10),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-amerika-birlesmis',
     'Amerika Birləşmiş Ştatları, Böyük Britaniya və Fransa', 20),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-almaniya-italiya',
     'Almaniya və İtaliya', 30),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-ssri',
     'SSRİ', 40),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-turk-iran',
     'Türk dünyası və İran', 50),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-hindistan-cin',
     'Hindistan, Çin və Yaponiya', 60),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-ikinci-muharibesi',
     'İkinci dünya müharibəsi', 70),
    ('utarix-9-dunya-2', 'utarix-9-dunya-2-medeniyyet',
     'Mədəniyyət', 80),
    --  Dunya olkeleri Ikinci dunya muharibesinden sonra  (utarix-9-dunya-3)
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-amerika-birlesmis',
     'Amerika Birləşmiş Ştatları', 10),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-boyuk-britaniya',
     'Böyük Britaniya, Fransa, Almaniya və İtaliya', 20),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-ssri-rusiya',
     'SSRİ. Rusiya Federasiyası', 30),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-turk-iran',
     'Türk dünyası və İran', 40),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-hindistan-pakistan',
     'Hindistan, Pakistan və ərəb ölkələri', 50),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-cin-yaponiya',
     'Çin, Yaponiya, Koreya', 60),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-dovletlerarasi-munasibetler',
     'Dövlətlərarası münasibətlər', 70),
    ('utarix-9-dunya-3', 'utarix-9-dunya-3-medeniyyet',
     'Mədəniyyət', 80),
    --  ============  11-ci sinif  ============
    --  DUNYA OLKELERI XIX YUZILLIK-XX YUZILLIYIN EVVELLERINDE  (utarix-11-dunya-1)
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-abs-boyuk',
     'ABŞ və Böyük Britaniya', 10),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-fransa-almaniya',
     'Fransa və Almaniya', 20),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-rusiya',
     'Rusiya', 30),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-osmanli-imperiyasi',
     'Osmanlı imperiyası. Qacarlar dövləti', 40),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-hindistan-cin',
     'Hindistan, Çin və Yaponiya', 50),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-dovletlerarasi-munasibetler',
     'Dövlətlərarası münasibətlər', 60),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-birinci-muharibesi',
     'Birinci dünya müharibəsi', 70),
    ('utarix-11-dunya-1', 'utarix-11-dunya-1-medeniyyet',
     'Mədəniyyət', 80),
    --  DUNYA OLKELERI 1918-1945-CI ILLERDE  (utarix-11-dunya-2)
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-versal-vasinqton',
     'Versal-Vaşinqton sistemi', 10),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-abs-boyuk',
     'ABŞ, Böyük Britaniya və Fransa', 20),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-almaniya-ssri',
     'Almaniya və SSRİ', 30),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-turkiye-iran',
     'Türkiyə və İran', 40),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-hindistan-cin',
     'Hindistan, Çin və Yaponiya', 50),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-dovletlerarasi-munasibetler',
     'Dövlətlərarası münasibətlər', 60),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-ikinci-muharibesi',
     'İkinci dünya müharibəsi', 70),
    ('utarix-11-dunya-2', 'utarix-11-dunya-2-medeniyyet',
     'Mədəniyyət', 80),
    --  DUNYA OLKELERI IKINCI DUNYA MUHARIBESINDEN SONRA  (utarix-11-dunya-3)
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-amerika-birlesmis',
     'Amerika Birləşmiş Ştatları', 10),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-boyuk-britaniya',
     'Böyük Britaniya, Fransa və Almaniya', 20),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-ssri-rusiya',
     'SSRİ. Rusiya Federasiyası', 30),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-turkiye-iran',
     'Türkiyə və İran', 40),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-hindistan-pakistan',
     'Hindistan, Pakistan və ərəb ölkələri', 50),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-cin-yaponiya',
     'Çin, Yaponiya və Koreya', 60),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-soyuq-muharibe',
     'Soyuq müharibə və müasir dövrdə dövlətlərarası münasibətlər', 70),
    ('utarix-11-dunya-3', 'utarix-11-dunya-3-medeniyyet',
     'Mədəniyyət', 80)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'umumi-tarix')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 12 then
    raise exception 'umumi-tarix 8-ci alt movzulari: 12 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = p.level_id and l.code = '9';
  if k <> 24 then
    raise exception 'umumi-tarix 9-cu alt movzulari: 24 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 24 then
    raise exception 'umumi-tarix 11-ci alt movzulari: 24 gozlenilirdi, % tapildi', k;
  end if;

  --  alt movzuda sual OLMAMALIDIR
  select count(*) into k from public.questions q
    join public.topics t on t.id = q.topic_id
   where t.parent_id is not null;
  if k > 0 then
    raise exception '% sual alt movzuya baglanib - bu merhelede olmamalidir', k;
  end if;

  --  ust movzu sayi deyismemelidir
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and l.code in ('8','9','11');
  if k <> 8 then
    raise exception 'Umumi tarix ust movzu sayi (8,9,11) 8 deyil: %', k;
  end if;

  raise notice 'Umumi tarix 8, 9, 11: 60 alt movzu hazir.';
end $$;
