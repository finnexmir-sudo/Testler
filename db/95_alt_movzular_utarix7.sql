-- =====================================================================
--  95_alt_movzular_utarix7.sql : UMUMI TARIX 7 - ALT MOVZULAR
--
--  NIYE AYRI PAKET (8/9/10/11-den, hamisi 96-da)
--  Kitab 723-un OZ bolmeleri ("Dunya olkeleri III-XI yuzillikde",
--  "...XI-XVI yuzillikde") bazadaki 8 movzu ile HEC BIR seviyyede
--  uygun gəlmir - bu movzular (erken/ereb/feodal/serq/avropa/
--  medeniyyet/turk-dovletleri/selcuq-osmanli) db/66/70-de MEZMUNA
--  gore tesnif edilib, kitabin oz bolme basliqlarindan yox (izah
--  db/70-de var).  Ona gore sehife/altbaslıq serhedi ISLEMIR - hər
--  bendin METNİ UTARIX7_TESNIF xeritesi ile duz movzuya baglanir
--  (23 bend, hamisi xeritede var - yoxlanilib).  "Teymuri dovleti"
--  Selcuq/Monqol/Osmanli qrupuna (temporal qonşuluq), "Avropa Hun ve
--  Ag Hun dovletleri" turk-dovletleri qrupuna (erkən köç dovru turk
--  xalqlari kimi oxunur) verilib - ikisi de mueyyen deqreje
--  mubahiseli ola biler, amma her ikisi mundericatdaki mezmuna
--  esaslanir, uydurma yoxdur.
--
--  Ayri paketdir, cunki bu kitabin "10 Mədəniyyət" bendi 10-cu
--  sinifin eyni herfi bendi ile TEXTUAL toqquşur - eyni paketde eyni
--  duzelis acari ikisine de tetbiq olardi (bax 96-nin basliq serhi).
--
--  MENBE: e-derslik.edu.az kitab id 723.  Adlar EYNILE goturulur.
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

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  7-ci sinif  ============
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-7-feodal)
    ('utarix-7-feodal', 'utarix-7-feodal-munasibetlerin-meydana',
     'Feodal münasibətlərinin meydana gəlməsi', 10),
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-7-turk-dovletleri)
    ('utarix-7-turk-dovletleri', 'utarix-7-turk-dovletleri-xalqlarin-boyuk',
     'Xalqların böyük köçü. Avropa Hun və Ağ Hun dövlətləri', 10),
    ('utarix-7-turk-dovletleri', 'utarix-7-turk-dovletleri-goyturk-uygur',
     'Göytürk və Uyğur xaqanlıqları', 20),
    ('utarix-7-turk-dovletleri', 'utarix-7-turk-dovletleri-avar-xezer',
     'Avar, Xəzər və Bulqar dövlətləri', 30),
    ('utarix-7-turk-dovletleri', 'utarix-7-turk-dovletleri-samani-oguz',
     'Samani, Oğuz, Qaraxanlı, Qəznəli dövlətləri', 40),
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-7-erken)
    ('utarix-7-erken', 'utarix-7-erken-sasani-qafqaz',
     'Sasani dövləti. Qafqaz', 10),
    ('utarix-7-erken', 'utarix-7-erken-frank-dovleti',
     'Frank dövləti', 20),
    ('utarix-7-erken', 'utarix-7-erken-bizans-slavyanlar',
     'Bizans. Slavyanlar', 30),
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-7-ereb)
    ('utarix-7-ereb', 'utarix-7-ereb-xilafeti',
     'Ərəb xilafəti', 10),
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-7-medeniyyet)
    ('utarix-7-medeniyyet', 'utarix-7-medeniyyet-medeniyyet',
     'Mədəniyyət', 10),
    --  Dunya olkeleri XI-XVI yuzilliklerde  (utarix-7-selcuq-osmanli)
    ('utarix-7-selcuq-osmanli', 'utarix-7-selcuq-osmanli-boyuk-dovleti',
     'Böyük Səlcuq dövləti', 10),
    ('utarix-7-selcuq-osmanli', 'utarix-7-selcuq-osmanli-monqol-qizil',
     'Böyük Monqol imperiyası. Qızıl Ordu. Moskva knyazlığı', 20),
    ('utarix-7-selcuq-osmanli', 'utarix-7-selcuq-osmanli-imperiyasi',
     'Osmanlı imperiyası', 30),
    ('utarix-7-selcuq-osmanli', 'utarix-7-selcuq-osmanli-teymuri-dovleti',
     'Teymuri dövləti', 40),
    --  Dunya olkeleri XI-XVI yuzilliklerde  (utarix-7-serq)
    ('utarix-7-serq', 'utarix-7-serq-dehli-sultanligi',
     'Dehli sultanlığı. Böyük Moğol dövləti', 10),
    --  Dunya olkeleri XI-XVI yuzilliklerde  (utarix-7-avropa)
    ('utarix-7-avropa', 'utarix-7-avropa-xacli-yurusleri',
     'Xaçlı yürüşləri', 10),
    ('utarix-7-avropa', 'utarix-7-avropa-italiya',
     'İtaliya', 20),
    ('utarix-7-avropa', 'utarix-7-avropa-fransa',
     'Fransa', 30),
    ('utarix-7-avropa', 'utarix-7-avropa-ingiltere',
     'İngiltərə', 40),
    ('utarix-7-avropa', 'utarix-7-avropa-reformasiya',
     'Reformasiya', 50),
    ('utarix-7-avropa', 'utarix-7-avropa-texniki-ixtiralar',
     'Texniki ixtiralar. Böyük coğrafi kəşflər', 60),
    --  Dunya olkeleri XI-XVI yuzilliklerde  (utarix-7-medeniyyet)
    ('utarix-7-medeniyyet', 'utarix-7-medeniyyet-serq-xalqlarinin',
     'Şərq xalqlarının mədəniyyəti', 20),
    ('utarix-7-medeniyyet', 'utarix-7-medeniyyet-avropa-amerika',
     'Avropa və Amerika xalqlarının mədəniyyəti', 30)
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
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 23 then
    raise exception 'umumi-tarix 7-ci alt movzulari: 23 gozlenilirdi, % tapildi', k;
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
   where t.parent_id is null and l.code = '7';
  if k <> 8 then
    raise exception 'Umumi tarix ust movzu sayi (7) 8 deyil: %', k;
  end if;

  raise notice 'Umumi tarix 7 (mezmuna gore tesnif - bax CLAUDE.md): 23 alt movzu hazir.';
end $$;
