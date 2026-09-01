-- =====================================================================
--  84_alt_movzular_hb1_4.sql : HEYAT BILGISI 1-4 - ALT MOVZULAR
--
--  NIYE
--  Riyaziyyatdan sonra ikinci fenn.  Heyat bilgisi derslikleri
--  bolme -> ders quruluşundadir ve bazadaki movzu agaci ile
--  DORD SINIFDE DE bire-bir uygundur (5+6+6+5 = 22 bolme) - ona
--  gore ilk secilen odur, xeritede muzakire teleb eden yer yoxdur.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 762 (1),
--  829 (2), 900 (3), 769 (4).  Adlar EYNILE goturulub.
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
--   * yazi (2): yazi qusuru (bosluq, herf)
--       1-ci   s.12   3. olkem
--                    -> Olkem
--       2-ci   s.42   11. Matenallarin istifadesi
--                    -> Materiallarin istifadesi

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  1-ci sinif  ============
    --  1. MEN KIMEM  (hey-1-men-kimem)
    ('hey-1-men-kimem', 'hey-1-men-kimem-mektebim',
     'Məktəbim', 10),
    ('hey-1-men-kimem', 'hey-1-men-kimem-ailem',
     'Ailəm', 20),
    ('hey-1-men-kimem', 'hey-1-men-kimem-olkem',
     'Ölkəm', 30),
    ('hey-1-men-kimem', 'hey-1-men-kimem-men-azerbaycanliya',
     'Mən azərbaycanlıyam', 40),
    ('hey-1-men-kimem', 'hey-1-men-kimem-harada-yasayiram',
     'Mən harada yaşayıram', 50),
    ('hey-1-men-kimem', 'hey-1-men-kimem-unsiyyet',
     'Ünsiyyət', 60),
    ('hey-1-men-kimem', 'hey-1-men-kimem-intizam',
     'İntizam', 70),
    ('hey-1-men-kimem', 'hey-1-men-kimem-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  2. SAGLAMLIQ  (hey-1-saglamliq)
    ('hey-1-saglamliq', 'hey-1-saglamliq-beden-hisseleri',
     'Bədən hissələri', 10),
    ('hey-1-saglamliq', 'hey-1-saglamliq-oxsarliq-ferqlilik',
     'Oxşarlıq və fərqlilik', 20),
    ('hey-1-saglamliq', 'hey-1-saglamliq-bedenimizi-nece',
     'Bədənimizi necə təmiz saxlayaq', 30),
    ('hey-1-saglamliq', 'hey-1-saglamliq-qidalanma',
     'Sağlam qidalanma', 40),
    ('hey-1-saglamliq', 'hey-1-saglamliq-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  3. INSANLAR VE ESYALAR  (hey-1-insanlar-esyalar)
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-diller',
     'Dillər', 10),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-dinler',
     'Dinlər', 20),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-men-yoldaslarim',
     'Mən və yoldaşlarım', 30),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-evdeki',
     'Evdəki əşyalarımız', 40),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-neden-hazirlanir',
     'Əşyalar nədən hazırlanır', 50),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-materiallarin-xasseleri',
     'Materialların xassələri', 60),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-hereketi',
     'Əşyaların hərəkəti', 70),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-evimizdeki-avadanliqlar',
     'Evimizdəki avadanlıqlar', 80),
    ('hey-1-insanlar-esyalar', 'hey-1-insanlar-esyalar-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  4. ETRAF MUHIT  (hey-1-etraf-muhit)
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-nece-oyrenirik',
     'Ətrafı necə öyrənirik', 10),
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-ses-haradan',
     'Səs haradan gəlir', 20),
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-bugun-hava',
     'Bugün hava necədir', 30),
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-fesiller-bize',
     'Fəsillər bizə necə təsir edir', 40),
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-canli-cansiz',
     'Canlı və cansız', 50),
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-yasamaq-lazimdir',
     'Yaşamaq üçün nə lazımdır', 60),
    ('hey-1-etraf-muhit', 'hey-1-etraf-muhit-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  5. EHTIYATLI DAVRANAQ  (hey-1-ehtiyat)
    ('hey-1-ehtiyat', 'hey-1-ehtiyat-neqliyyat-vasiteleri',
     'Nəqliyyat vasitələri', 10),
    ('hey-1-ehtiyat', 'hey-1-ehtiyat-diqqetli-olaq',
     'Diqqətli olaq', 20),
    ('hey-1-ehtiyat', 'hey-1-ehtiyat-selden-nece',
     'Seldən necə qorunmaq olar', 30),
    ('hey-1-ehtiyat', 'hey-1-ehtiyat-tecili-zeng',
     'Təcili zəng', 40),
    ('hey-1-ehtiyat', 'hey-1-ehtiyat-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  ============  2-ci sinif  ============
    --  1. MEN VE MEKTEBIM  (hey-2-men-mektebim)
    ('hey-2-men-mektebim', 'hey-2-men-mektebim-mektebimiz',
     'Məktəbimiz', 10),
    ('hey-2-men-mektebim', 'hey-2-men-mektebim-hem-oxsar',
     'Həm oxşar, həm fərqliyik', 20),
    ('hey-2-men-mektebim', 'hey-2-men-mektebim-birlikde',
     'Birlikdə', 30),
    ('hey-2-men-mektebim', 'hey-2-men-mektebim-birimizi-dinleyirik',
     'Bir-birimizi dinləyirik', 40),
    ('hey-2-men-mektebim', 'hey-2-men-mektebim-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  2. DEYERLER VE SAGLAMLIQ  (hey-2-deyerler)
    ('hey-2-deyerler', 'hey-2-deyerler-dovletimiz',
     'Dövlətimiz', 10),
    ('hey-2-deyerler', 'hey-2-deyerler-muxteliflik',
     'Müxtəliflik', 20),
    ('hey-2-deyerler', 'hey-2-deyerler-huquqlarimiz',
     'Hüquqlarımız', 30),
    ('hey-2-deyerler', 'hey-2-deyerler-saglam-heyat',
     'Sağlam həyat', 40),
    ('hey-2-deyerler', 'hey-2-deyerler-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  3. MATERIALLAR VE TEHLUKESIZLIK  (hey-2-materiallar)
    ('hey-2-materiallar', 'hey-2-materiallar-tebii-olmayan',
     'Təbii və təbii olmayan materiallar', 10),
    ('hey-2-materiallar', 'hey-2-materiallar-xasseleri',
     'Materialların xassələri', 20),
    ('hey-2-materiallar', 'hey-2-materiallar-istifadesi',
     'Materialların istifadəsi', 30),
    ('hey-2-materiallar', 'hey-2-materiallar-elektrikle-isleyen',
     'Elektriklə işləyən avadanlıqlar', 40),
    ('hey-2-materiallar', 'hey-2-materiallar-elektron-cihazlar',
     'Elektron cihazlar və biz', 50),
    ('hey-2-materiallar', 'hey-2-materiallar-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  4. YER KURESI  (hey-2-yer-kuresi)
    ('hey-2-yer-kuresi', 'hey-2-yer-kuresi-isiq-menbeleri',
     'İşıq mənbələri', 10),
    ('hey-2-yer-kuresi', 'hey-2-yer-kuresi-gunes-sistemini',
     'Günəş sistemini tanıyaq', 20),
    ('hey-2-yer-kuresi', 'hey-2-yer-kuresi-yer-planeti',
     'Yer planeti', 30),
    ('hey-2-yer-kuresi', 'hey-2-yer-kuresi-yasayis-yeri',
     'Yaşayış yeri', 40),
    ('hey-2-yer-kuresi', 'hey-2-yer-kuresi-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  5. CANLILAR  (hey-2-canlilar)
    ('hey-2-canlilar', 'hey-2-canlilar-heyvanlari-taniyaq',
     'Heyvanları tanıyaq', 10),
    ('hey-2-canlilar', 'hey-2-canlilar-coxalmasi-boyumesi',
     'Canlıların çoxalması və böyüməsi', 20),
    ('hey-2-canlilar', 'hey-2-canlilar-bitkileri-taniyaq',
     'Bitkiləri tanıyaq', 30),
    ('hey-2-canlilar', 'hey-2-canlilar-bitkilerin-lazimdir',
     'Bitkilərin böyüməsi üçün nə lazımdır', 40),
    ('hey-2-canlilar', 'hey-2-canlilar-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  6. EHTIYATLI DAVRANAQ  (hey-2-ehtiyat)
    ('hey-2-ehtiyat', 'hey-2-ehtiyat-neqliyyatda-yolda',
     'Nəqliyyatda və yolda', 10),
    ('hey-2-ehtiyat', 'hey-2-ehtiyat-tebii-felaketler',
     'Təbii fəlakətlər', 20),
    ('hey-2-ehtiyat', 'hey-2-ehtiyat-tehlukelerden-nece',
     'Təhlükələrdən necə qorunaq', 30),
    ('hey-2-ehtiyat', 'hey-2-ehtiyat-qenaet',
     'Qənaət', 40),
    ('hey-2-ehtiyat', 'hey-2-ehtiyat-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  ============  3-cu sinif  ============
    --  1 MEN VE CEMIYYET  (hey-3-cemiyyet)
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-huquqlarimiz',
     'Hüquqlarımız', 10),
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-musbet-keyfiyyetlerim',
     'Müsbət keyfiyyətlərimiz', 20),
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-esitmek-dinlemek',
     'Eşitmək və dinləmək', 30),
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-biz-dostlarimiz',
     'Biz və dostlarımız', 40),
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-birlikde-yasamaq',
     'Birlikdə yaşamaq', 50),
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-milli-birlik',
     'Milli birlik', 60),
    ('hey-3-cemiyyet', 'hey-3-cemiyyet-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  2 INSAN VE SAGLAMLIQ  (hey-3-saglamliq)
    ('hey-3-saglamliq', 'hey-3-saglamliq-canlilar-fosiller',
     'Canlılar və fosillər', 10),
    ('hey-3-saglamliq', 'hey-3-saglamliq-beden-uzvleri',
     'Bədən üzvləri', 20),
    ('hey-3-saglamliq', 'hey-3-saglamliq-skelet-ezeleler',
     'Skelet və əzələlər', 30),
    ('hey-3-saglamliq', 'hey-3-saglamliq-qidalanma',
     'Sağlamlıq və qidalanma', 40),
    ('hey-3-saglamliq', 'hey-3-saglamliq-qida-mehsullari',
     'Qida məhsulları', 50),
    ('hey-3-saglamliq', 'hey-3-saglamliq-xestelik',
     'Xəstəlik və sağlamlıq', 60),
    ('hey-3-saglamliq', 'hey-3-saglamliq-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  3 YER VE AY  (hey-3-yer-ay)
    ('hey-3-yer-ay', 'hey-3-yer-ay-yer-kuresi',
     'Yer kürəsi və Ay', 10),
    ('hey-3-yer-ay', 'hey-3-yer-ay-yerin-firlanmasi',
     'Yerin fırlanması', 20),
    ('hey-3-yer-ay', 'hey-3-yer-ay-isiq-kolge',
     'İşıq və kölgə', 30),
    ('hey-3-yer-ay', 'hey-3-yer-ay-kolgenin-yerini',
     'Kölgənin yerini dəyişməsi', 40),
    ('hey-3-yer-ay', 'hey-3-yer-ay-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  4 MATERIALLAR VE XASSELERI  (hey-3-materiallar)
    ('hey-3-materiallar', 'hey-3-materiallar-xasseleri',
     'Materialların xassələri', 10),
    ('hey-3-materiallar', 'hey-3-materiallar-istifadesi',
     'Materialların istifadəsi', 20),
    ('hey-3-materiallar', 'hey-3-materiallar-istilik-temperatur',
     'İstilik və temperatur', 30),
    ('hey-3-materiallar', 'hey-3-materiallar-istiliyi-yaxsi',
     'İstiliyi yaxşı və pis keçirən materiallar', 40),
    ('hey-3-materiallar', 'hey-3-materiallar-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  5 BAYRAMLAR VE QENAET  (hey-3-bayramlar)
    ('hey-3-bayramlar', 'hey-3-bayramlar-bayramlar',
     'Bayramlar', 10),
    ('hey-3-bayramlar', 'hey-3-bayramlar-28-may',
     '28 May', 20),
    ('hey-3-bayramlar', 'hey-3-bayramlar-ehtiyaclarimiz-isteklerimiz',
     'Ehtiyaclarımız və istəklərimiz', 30),
    ('hey-3-bayramlar', 'hey-3-bayramlar-umumi',
     'Ümumiləşdirici tapşırıqlar', 40),
    --  6 TEHLUKESIZLIK VE QAYDALAR  (hey-3-tehlukesizlik)
    ('hey-3-tehlukesizlik', 'hey-3-tehlukesizlik-tebii-felaketler',
     'Təbii fəlakətlər', 10),
    ('hey-3-tehlukesizlik', 'hey-3-tehlukesizlik-diqqetli-ehtiyatli',
     'Diqqətli və ehtiyatlı olaq', 20),
    ('hey-3-tehlukesizlik', 'hey-3-tehlukesizlik-nisanlari',
     'Təhlükəsizlik nişanları', 30),
    ('hey-3-tehlukesizlik', 'hey-3-tehlukesizlik-danisan-nisanlar',
     'Danışan nişanlar', 40),
    ('hey-3-tehlukesizlik', 'hey-3-tehlukesizlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 50),
    --  ============  4-cu sinif  ============
    --  I BOLME. CANLI HEYAT  (hey-4-canli-heyat)
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-orqanlarimiz',
     'Orqanlarımız', 10),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-bitkilerin-rolu',
     'Bitkilərin həyatımızda rolu', 20),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-heyvanlarin-rolu',
     'Heyvanların həyatımızda rolu', 30),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-insan-mikroorqanizml',
     'İnsan və mikroorqanizmlər', 40),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-insana-tesir',
     'İnsana təsir edən amillər', 50),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-saglamligimizi-qaygisina',
     'Sağlamlığımızın qayğısına qalaq', 60),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-muhit-amillerinin',
     'Mühit amillərinin canlılara təsiri', 70),
    ('hey-4-canli-heyat', 'hey-4-canli-heyat-etraf-muhitin',
     'Ətraf mühitin qorunması', 80),
    --  II BOLME. FERD, AILE VE CEMIYYET  (hey-4-ferd-aile)
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-insan-sosial',
     'İnsan sosial varlıq kimi', 10),
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-cemiyyetde-rolu',
     'Ailənin cəmiyyətdə rolu', 20),
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-kollektivde-vezifelerimiz',
     'Ailədə və kollektivdə vəzifələrimiz', 30),
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-unsiyyetin-rolu',
     'Cəmiyyətdə ünsiyyətin rolu', 40),
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-menevi-keyfiyyetlerim',
     'Mənəvi keyfiyyətlərimiz', 50),
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-menevi-borc',
     'Mənəvi borc', 60),
    ('hey-4-ferd-aile', 'hey-4-ferd-aile-dini-deyerler',
     'Dini dəyərlər', 70),
    --  III BOLME. DOVLET VE HUQUQ  (hey-4-dovlet-huquq)
    ('hey-4-dovlet-huquq', 'hey-4-dovlet-huquq-orqanlari',
     'Dövlət orqanları', 10),
    ('hey-4-dovlet-huquq', 'hey-4-dovlet-huquq-huquqlarimiz',
     'Hüquqlarımız', 20),
    ('hey-4-dovlet-huquq', 'hey-4-dovlet-huquq-budcesi',
     'Dövlət büdcəsi', 30),
    ('hey-4-dovlet-huquq', 'hey-4-dovlet-huquq-pullar',
     'Pullar', 40),
    --  IV BOLME. SAGLAMLIQ VE TEHLUKESIZLIK  (hey-4-saglamliq-teh)
    ('hey-4-saglamliq-teh', 'hey-4-saglamliq-teh-hallar-nisanlar',
     'Fövqəladə hallar və nişanlar', 10),
    ('hey-4-saglamliq-teh', 'hey-4-saglamliq-teh-hallarda-davranis',
     'Fövqəladə hallarda davranış qaydaları', 20),
    ('hey-4-saglamliq-teh', 'hey-4-saglamliq-teh-planin-cekilmesi',
     'Planın çəkilməsi', 30),
    ('hey-4-saglamliq-teh', 'hey-4-saglamliq-teh-ilk-tibbi',
     'İlk tibbi yardım', 40),
    ('hey-4-saglamliq-teh', 'hey-4-saglamliq-teh-yol-hereketi',
     'Yol hərəkəti qaydaları', 50),
    --  V. HEREKET VE ENERJI  (hey-4-hereket-enerji)
    ('hey-4-hereket-enerji', 'hey-4-hereket-enerji-cografi-obyektler',
     'Coğrafi obyektlər xəritədə', 10),
    ('hey-4-hereket-enerji', 'hey-4-hereket-enerji-tebii-zonalar',
     'Təbii zonalar', 20),
    ('hey-4-hereket-enerji', 'hey-4-hereket-enerji-tebii-ehtiyatlar',
     'Təbii ehtiyatlar', 30)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'hayat-bilgisi')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'hayat-bilgisi'
    join public.levels   l on l.id = p.level_id and l.code = '1';
  if k <> 34 then
    raise exception 'Heyat bilgisi 1-ci alt movzulari: 34 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'hayat-bilgisi'
    join public.levels   l on l.id = p.level_id and l.code = '2';
  if k <> 31 then
    raise exception 'Heyat bilgisi 2-ci alt movzulari: 31 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'hayat-bilgisi'
    join public.levels   l on l.id = p.level_id and l.code = '3';
  if k <> 33 then
    raise exception 'Heyat bilgisi 3-cu alt movzulari: 33 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'hayat-bilgisi'
    join public.levels   l on l.id = p.level_id and l.code = '4';
  if k <> 27 then
    raise exception 'Heyat bilgisi 4-cu alt movzulari: 27 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'hayat-bilgisi'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and l.code in ('1','2','3','4');
  if k <> 22 then
    raise exception 'Heyat bilgisi ust movzu sayi 22 deyil: %', k;
  end if;

  raise notice 'Heyat bilgisi 1-4: 125 alt movzu hazir.';
end $$;
