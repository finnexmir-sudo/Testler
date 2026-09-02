-- =====================================================================
--  97_alt_movzular_utarix10.sql : UMUMI TARIX 10 - ALT MOVZULAR
--
--  Kitabin 4 bolmesi bazadaki 6 movzuya deyisir - I bolme ("Qedim
--  Serq ve Avropa sivilizasiyalari") sehife 30-dan bolunur (Ibtidai/
--  Misir-Mesopotamiya/Iran-Hindistan/Hun-Cin -> qedim-serq,
--  Yunanistan/Makedoniya/Roma -> antik) - eyni qayda 6-ci sinifde
--  artiq islenib.  II/III/IV bolmelerin HƏR BIRININ öz "Mədəniyyət"
--  bendi standalone "medeniyyet" movzusuna dusur (sehife serhedi ile
--  ayrilir) - uc bend eyni HƏRFI adla ("Mədəniyyət") gəldiyi ucun
--  aydinliq ucun dovr adi elave olunub (asagida AD DUZELISLERI).
--
--  AYRI PAKETDIR (96-dan): duzelis xeritesi RAW METNI TAPMAYANDA
--  strip-lenmis ada (yeni "Mədəniyyət"-e) geri düşür - bu, 8/9/11-in
--  oz "N. Mədəniyyət" bendlerine də TESADUFEN tetbiq olardi, cunki
--  onlarin da strip-lenmis adi eyni "Mədəniyyət"-dir.  Ayri paketde
--  bu problem yoxdur, cunki bu kitabda hər üç bend RAW METNLƏ
--  ("10 Mədəniyyət", "18 Mədəniyyət", bare "Mədəniyyət") birbaşa
--  tapılır - ad-fallback-a ehtiyac qalmır.
--
--  MENBE: e-derslik.edu.az kitab id 745.  Adlar EYNILE goturulur.
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
--   * aydinliq (3): eyni ad (mes. 'Medeniyyet') bir nece dovrden bir movzuya birlesir - siyahida aydin gorunmesi ucun dovr elave edilib, mezmun deyismeyib
--       10-cu  s.62   10 Medeniyyet
--                    -> Medeniyyet (III-XI esrler)
--       10-cu  s.106  18 Medeniyyet
--                    -> Medeniyyet (XI-XV esrler)
--       10-cu  s.146  Medeniyyet
--                    -> Medeniyyet (XVI-XVIII esrler)

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  10-cu sinif  ============
    --  Qedim Serq ve Avropa sivilizasiyalari  (utarix-10-qedim-serq)
    ('utarix-10-qedim-serq', 'utarix-10-qedim-serq-ibtidai-cemiyyet',
     'İbtidai cəmiyyət', 10),
    ('utarix-10-qedim-serq', 'utarix-10-qedim-serq-misir-mesopotamiya',
     'Qədim Misir və Mesopotamiya', 20),
    ('utarix-10-qedim-serq', 'utarix-10-qedim-serq-iran-hindistan',
     'Qədim İran və Hindistan', 30),
    ('utarix-10-qedim-serq', 'utarix-10-qedim-serq-boyuk-hun',
     'Böyük Hun dövləti. Çin', 40),
    --  Qedim Serq ve Avropa sivilizasiyalari  (utarix-10-antik)
    ('utarix-10-antik', 'utarix-10-antik-qedim-yunanistan',
     'Qədim Yunanıstan, Makedoniya və Roma', 10),
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-10-erken-orta)
    ('utarix-10-erken-orta', 'utarix-10-erken-orta-turk-dovletleri',
     'Türk dövlətləri', 10),
    ('utarix-10-erken-orta', 'utarix-10-erken-orta-ereb-xilafeti',
     'Ərəb xilafəti', 20),
    ('utarix-10-erken-orta', 'utarix-10-erken-orta-qerbi-avropa',
     'Qərbi Avropa', 30),
    ('utarix-10-erken-orta', 'utarix-10-erken-orta-bizans',
     'Bizans', 40),
    --  Dunya olkeleri III-XI yuzilliklerde  (utarix-10-medeniyyet)
    ('utarix-10-medeniyyet', 'utarix-10-medeniyyet-iii-esrler',
     'Mədəniyyət (III-XI əsrlər)', 10),
    --  Dunya olkeleri XI-XV yuzilliklerde  (utarix-10-orta-esrler)
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-selcuq-dovleti',
     'Böyük Səlcuq dövləti', 10),
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-osmanli-imperiyasi',
     'Osmanlı imperiyası', 20),
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-dehli-sultanligi',
     'Dehli sultanlığı', 30),
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-monqol-qizil',
     'Böyük Monqol imperiyası. Qızıl Ordu', 40),
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-teymuri-dovleti',
     'Teymuri dövləti', 50),
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-xacli-yurusleri',
     'Xaçlı yürüşləri', 60),
    ('utarix-10-orta-esrler', 'utarix-10-orta-esrler-qerbi-avropada',
     'Qərbi Avropada mərkəzləşdirilmiş dövlətlərin yaranması', 70),
    --  Dunya olkeleri XI-XV yuzilliklerde  (utarix-10-medeniyyet)
    ('utarix-10-medeniyyet', 'utarix-10-medeniyyet-esrler',
     'Mədəniyyət (XI-XV əsrlər)', 20),
    --  Dunya olkeleri XVI-XVIII yuzilliklerde  (utarix-10-yeni-dovr)
    ('utarix-10-yeni-dovr', 'utarix-10-yeni-dovr-avropada-reformasiya',
     'Avropada reformasiya. Otuzillik müharibə', 10),
    ('utarix-10-yeni-dovr', 'utarix-10-yeni-dovr-ingiltere-fransa',
     'İngiltərə və Fransa', 20),
    ('utarix-10-yeni-dovr', 'utarix-10-yeni-dovr-cografi-kesfler',
     'Böyük coğrafi kəşflər. ABŞ-ın yaranması', 30),
    ('utarix-10-yeni-dovr', 'utarix-10-yeni-dovr-rusiya',
     'Rusiya', 40),
    ('utarix-10-yeni-dovr', 'utarix-10-yeni-dovr-osmanli-imperiyasi',
     'Osmanlı imperiyası', 50),
    ('utarix-10-yeni-dovr', 'utarix-10-yeni-dovr-mogol-dovleti',
     'Böyük Moğol dövləti', 60),
    --  Dunya olkeleri XVI-XVIII yuzilliklerde  (utarix-10-medeniyyet)
    ('utarix-10-medeniyyet', 'utarix-10-medeniyyet-xvi-xviii',
     'Mədəniyyət (XVI-XVIII əsrlər)', 30)
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
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 25 then
    raise exception 'umumi-tarix 10-cu alt movzulari: 25 gozlenilirdi, % tapildi', k;
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
   where t.parent_id is null and l.code = '10';
  if k <> 6 then
    raise exception 'Umumi tarix ust movzu sayi (10) 6 deyil: %', k;
  end if;

  raise notice 'Umumi tarix 10: 25 alt movzu hazir.';
end $$;
