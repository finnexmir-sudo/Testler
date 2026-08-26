-- =====================================================================
--  15_movzular_ederslik.sql : MOVZU AGACI ARTIQ REAL DERSLIKDEN GELIR
--
--  Menbe:  e-derslik.edu.az - Tehsil Nazirliyinin resmi elektron
--          derslik portali.  Kitablarin MUNDERICATI (bolme adlari)
--          goturulub - derslik metni, calismalar, sekiller YOX.
--          Mundericat faktdir; muellif huququ mesele deyil.
--          Yigan skript: tools/mundericat.py -> mundericat/*.txt
--
--  Niye lazimdir:  14_movzular.sql-deki agac umumi biliyle yazilmisdi.
--  Muellim oz sinif jurnalinda "3. Vurma ve bolme" gorur - proqramda
--  da eynisini gormelidir, yoxsa hesabata inanmayacaq.
--
--  Neyi deyisdirir:
--    Riyaziyyat 1, 3, 4   -> e-dersliyin bolmeleri (kitab 419/420,
--                            680/681, 774/775)
--    Heyat bilgisi 1-4    -> e-dersliyin bolmeleri (762, 829, 900, 769)
--    Informatika 1-4      -> e-dersliyin bolmeleri (417, 520, 676, 360)
--
--  Neyi TOXUNMUR ve NIYE:
--    Riyaziyyat 2   - portaldaki 664/665 kohne nesrdir (yalniz 20-ye
--                     qeder gedir, 9 movzu).  Etibarli deyil, ona gore
--                     1-ci ve 3-cu sinifin arasindan qurulmus siyahi
--                     saxlanilir.  Yeni nesr portala qoyulanda
--                     tools/mundericat.py 664 665 ile yenilenmelidir.
--    Azerbaycan dili- derslik MOVZUYA gore deyil, MEVZUYA gore bolunub
--                     ("Ferd ve toplum", "Qarabag - ana yurdum").
--                     Qrammatika (isim, sifet, durgu isareleri) dersin
--                     ICINDEDIR, mundericatde gorunmur.  Test banki
--                     ucun qrammatika oxu daha faydalidir - ona gore
--                     14-deki siyahi qalir.
--    Ingilis dili   - ibtidai sinifde vahid resmi derslik yoxdur
--                     (1-ci sinifde umumiyyetle ingilis dili kitabi
--                     portalda yoxdur), ona gore 14-deki siyahi qalir.
--
--  TEHLUKESIZLIK:  hec bir movzu sadece silinmir.  Suala ve ya
--  generator qaydasina baglanmis movzu YERINDE QALIR - notice ile
--  bildirilir ki, muellim ozu kocursun.
--
--  Tekrar isledile biler.
--  DIQQET: 14_movzular.sql-i BUNDAN SONRA isletmek olmaz - kohne
--  movzulari geri qaytarar.
-- =====================================================================

-- ---------------------------------------------------------------------
--  0. ON SERT: 14 islemis olmalidir
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from public.topics) then
    raise exception 'Movzu cedveli bosdur. Once 04_seed.sql ve 14_movzular.sql islet.';
  end if;
end $$;

-- ---------------------------------------------------------------------
--  1. KOHNE SLUG -> YENI SLUG  (id deyismir, suallar yerinde qalir)
-- ---------------------------------------------------------------------
update public.topics t
   set slug = m.yeni
  from (values
    ('riyaziyyat',   'riy-1-toplama',       'riy-1-toplama-10'),
    ('riyaziyyat',   'riy-1-cixma',         'riy-1-cixma-10'),
    ('riyaziyyat',   'riy-3-toplama-cixma', 'riy-3-toplama'),
    ('riyaziyyat',   'riy-3-vurma-cedveli', 'riy-3-vurma-bolme'),
    ('riyaziyyat',   'riy-3-bolme',         'riy-3-vurma-bolme-2'),
    ('riyaziyyat',   'riy-3-perimetr',      'riy-3-fiqurlar'),
    ('riyaziyyat',   'riy-3-zaman-olcu',    'riy-3-olcme'),
    ('riyaziyyat',   'riy-4-vurma',         'riy-4-vurma-bolme'),
    ('riyaziyyat',   'riy-4-bolme',         'riy-4-vurma-bolme-2'),
    ('riyaziyyat',   'riy-4-sahe',          'riy-4-fiqurlar'),
    ('riyaziyyat',   'riy-4-olcu',          'riy-4-olcme'),
    ('hayat-bilgisi','hey-1-men-ailem',     'hey-1-men-kimem'),
    ('hayat-bilgisi','hey-1-fesiller',      'hey-1-etraf-muhit'),
    ('hayat-bilgisi','hey-1-tehlukesizlik', 'hey-1-ehtiyat'),
    ('hayat-bilgisi','hey-2-emek',          'hey-2-men-mektebim'),
    ('hayat-bilgisi','hey-2-dostluq',       'hey-2-deyerler'),
    ('hayat-bilgisi','hey-2-tebiet',        'hey-2-yer-kuresi'),
    ('hayat-bilgisi','hey-2-heyvanlar',     'hey-2-canlilar'),
    ('hayat-bilgisi','hey-3-su-hava',       'hey-3-yer-ay'),
    ('hayat-bilgisi','hey-3-servetler',     'hey-3-materiallar'),
    ('hayat-bilgisi','hey-3-ekologiya',     'hey-3-tehlukesizlik'),
    ('hayat-bilgisi','hey-4-iqlim',         'hey-4-canli-heyat'),
    ('hayat-bilgisi','hey-4-veten-tarixi',  'hey-4-ferd-aile'),
    ('hayat-bilgisi','hey-4-remzler',       'hey-4-dovlet-huquq')
  ) as m(fenn, kohne, yeni)
  join public.subjects s on s.slug = m.fenn
 where t.subject_id = s.id
   and t.slug = m.kohne
   --  Yeni slug artiq varsa toqqusmasin - onda kohne oz yerinde qalir
   and not exists (select 1 from public.topics t2
                    where t2.subject_id = s.id and t2.slug = m.yeni);

-- ---------------------------------------------------------------------
--  2. AGAC  (e-derslik bolmeleri)
-- ---------------------------------------------------------------------
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ====================== RIYAZIYYAT 1 (419 + 420) ==================
    ('riyaziyyat','1','riy-1-elamet',        'Əşyanın əlaməti',                 10),
    ('riyaziyyat','1','riy-1-ededler-10',    'Ədədlər (10-a qədər)',            20),
    ('riyaziyyat','1','riy-1-muqayise',      'Ədədlərin müqayisəsi',            30),
    ('riyaziyyat','1','riy-1-toplama-10',    'Toplama (10-a qədər)',            40),
    ('riyaziyyat','1','riy-1-cixma-10',      'Çıxma (10-a qədər)',              50),
    ('riyaziyyat','1','riy-1-ededler-20',    'Ədədlər (20-yə qədər)',           60),
    ('riyaziyyat','1','riy-1-fiqurlar',      'Həndəsi fiqurlar',                70),
    ('riyaziyyat','1','riy-1-toplama-20',    'Toplama (20-yə qədər)',           80),
    ('riyaziyyat','1','riy-1-cixma-20',      'Çıxma (20-yə qədər)',             90),
    ('riyaziyyat','1','riy-1-ededler-100',   'Ədədlər (100-ə qədər). Pullar',  100),
    ('riyaziyyat','1','riy-1-olcme',         'Ölçmə',                          110),
    ('riyaziyyat','1','riy-1-melumat',       'Məlumatların təsviri',           120),

    -- ============ RIYAZIYYAT 2 (portalda kohne nesr - 14-den) =========
    ('riyaziyyat','2','riy-2-ededler-100',   'Ədədlər 100-ə qədər',             10),
    ('riyaziyyat','2','riy-2-toplama-cixma', 'Toplama və çıxma',                20),
    ('riyaziyyat','2','riy-2-vurma',         'Vurma anlayışı',                  30),
    ('riyaziyyat','2','riy-2-vurma-cedveli', 'Vurma cədvəli (2–5)',             40),
    ('riyaziyyat','2','riy-2-bolme',         'Bölmə',                           50),
    ('riyaziyyat','2','riy-2-zaman',         'Zaman və saat',                   60),
    ('riyaziyyat','2','riy-2-olcu',          'Ölçü vahidləri',                  70),
    ('riyaziyyat','2','riy-2-fiqurlar',      'Həndəsi fiqurlar',                80),
    ('riyaziyyat','2','riy-2-mesele',        'Mətn məsələləri',                 90),

    -- ====================== RIYAZIYYAT 3 (680 + 681) ==================
    ('riyaziyyat','3','riy-3-ededler-1000',  'Ədədlər (1000-ə qədər)',          10),
    ('riyaziyyat','3','riy-3-toplama',       'Toplama (1000-ə qədər)',          20),
    ('riyaziyyat','3','riy-3-cixma',         'Çıxma (1000-ə qədər)',            30),
    ('riyaziyyat','3','riy-3-vurma-bolme',   'Vurma və bölmə',                  40),
    ('riyaziyyat','3','riy-3-ifade-tenlik',  'Riyazi ifadələr. Tənlik',         50),
    ('riyaziyyat','3','riy-3-fiqurlar',      'Həndəsi fiqurlar',                60),
    ('riyaziyyat','3','riy-3-vurma-bolme-2', 'Vurma və bölmə (davamı)',         70),
    ('riyaziyyat','3','riy-3-kesr',          'Kəsrlər',                         80),
    ('riyaziyyat','3','riy-3-ededler-10000', 'Ədədlər (10 000-ə qədər). Pullar',90),
    ('riyaziyyat','3','riy-3-olcme',         'Ölçmə',                          100),
    ('riyaziyyat','3','riy-3-melumat',       'Məlumatların təsviri. Hadisələr',110),
    ('riyaziyyat','3','riy-3-mesele',        'Mətn məsələləri',                120),

    -- ====================== RIYAZIYYAT 4 (774 + 775) ==================
    ('riyaziyyat','4','riy-4-coxreqemli',    'Ədədlər (1 000 000-a qədər)',     10),
    ('riyaziyyat','4','riy-4-toplama-cixma', 'Toplama və çıxma',                20),
    ('riyaziyyat','4','riy-4-vurma-bolme',   'Vurma və bölmə',                  30),
    ('riyaziyyat','4','riy-4-ifade-tenlik',  'Riyazi ifadələr. Tənlik',         40),
    ('riyaziyyat','4','riy-4-vurma-bolme-2', 'Vurma və bölmə (davamı)',         50),
    ('riyaziyyat','4','riy-4-fiqurlar',      'Həndəsi fiqurlar',                60),
    ('riyaziyyat','4','riy-4-kesr',          'Adi kəsrlər',                     70),
    ('riyaziyyat','4','riy-4-onluq-kesr',    'Onluq kəsrlər',                   80),
    ('riyaziyyat','4','riy-4-pullar',        'Pullar',                          90),
    ('riyaziyyat','4','riy-4-olcme',         'Ölçmə',                          100),
    ('riyaziyyat','4','riy-4-melumat',       'Məlumatların təsviri',           110),
    ('riyaziyyat','4','riy-4-mesele',        'Mətn məsələləri',                120),

    -- ===================== HEYAT BILGISI (762/829/900/769) ============
    ('hayat-bilgisi','1','hey-1-men-kimem',        'Mən kiməm',                 10),
    ('hayat-bilgisi','1','hey-1-saglamliq',        'Sağlamlıq',                 20),
    ('hayat-bilgisi','1','hey-1-insanlar-esyalar', 'İnsanlar və əşyalar',       30),
    ('hayat-bilgisi','1','hey-1-etraf-muhit',      'Ətraf mühit',               40),
    ('hayat-bilgisi','1','hey-1-ehtiyat',          'Ehtiyatlı davranaq',        50),

    ('hayat-bilgisi','2','hey-2-men-mektebim',     'Mən və məktəbim',           10),
    ('hayat-bilgisi','2','hey-2-deyerler',         'Dəyərlər və sağlamlıq',     20),
    ('hayat-bilgisi','2','hey-2-materiallar',      'Materiallar və təhlükəsizlik',30),
    ('hayat-bilgisi','2','hey-2-yer-kuresi',       'Yer kürəsi',                40),
    ('hayat-bilgisi','2','hey-2-canlilar',         'Canlılar',                  50),
    ('hayat-bilgisi','2','hey-2-ehtiyat',          'Ehtiyatlı davranaq',        60),

    ('hayat-bilgisi','3','hey-3-cemiyyet',         'Mən və cəmiyyət',           10),
    ('hayat-bilgisi','3','hey-3-saglamliq',        'İnsan və sağlamlıq',        20),
    ('hayat-bilgisi','3','hey-3-yer-ay',           'Yer və Ay',                 30),
    ('hayat-bilgisi','3','hey-3-materiallar',      'Materiallar və xassələri',  40),
    ('hayat-bilgisi','3','hey-3-bayramlar',        'Bayramlar və qənaət',       50),
    ('hayat-bilgisi','3','hey-3-tehlukesizlik',    'Təhlükəsizlik və qaydalar', 60),

    ('hayat-bilgisi','4','hey-4-canli-heyat',      'Canlı həyat',               10),
    ('hayat-bilgisi','4','hey-4-ferd-aile',        'Fərd, ailə və cəmiyyət',    20),
    ('hayat-bilgisi','4','hey-4-dovlet-huquq',     'Dövlət və hüquq',           30),
    ('hayat-bilgisi','4','hey-4-saglamliq-teh',    'Sağlamlıq və təhlükəsizlik',40),
    ('hayat-bilgisi','4','hey-4-hereket-enerji',   'Hərəkət və enerji',         50),

    -- ====================== INFORMATIKA (417/520/676/360) =============
    ('informatika','1','inf-1-esyalar',      'Əşyaların təsviri və müqayisəsi', 10),
    ('informatika','1','inf-1-ardicilliq',   'Hadisələr və hərəkətlər ardıcıllığı',20),
    ('informatika','1','inf-1-informasiya',  'İnformasiya',                     30),
    ('informatika','1','inf-1-komp-imkanlar','Kompüterin imkanları',            45),
    ('informatika','1','inf-1-kompyuter',    'Kompüter',                        40),

    ('informatika','2','inf-2-obyekt',       'Obyekt',                          10),
    ('informatika','2','inf-2-informasiya',  'İnformasiya',                     20),
    ('informatika','2','inf-2-alqoritm',     'Alqoritm',                        30),
    ('informatika','2','inf-2-proqramlar',   'Proqramlarla iş',                 45),
    ('informatika','2','inf-2-kompyuter',    'Kompüter',                        40),

    ('informatika','3','inf-3-informasiya',  'İnformasiya',                     10),
    ('informatika','3','inf-3-alqoritm',     'Alqoritm',                        20),
    ('informatika','3','inf-3-kompyuter',    'Kompüter',                        30),
    ('informatika','3','inf-3-qrafik',       'Qrafik redaktor (Paint)',         35),
    ('informatika','3','inf-3-metn',         'Mətn redaktoru',                  40),

    ('informatika','4','inf-4-informasiya',  'İnformasiya',                     10),
    ('informatika','4','inf-4-alqoritm',     'Alqoritm',                        20),
    ('informatika','4','inf-4-mentiq',       'Məntiq: mülahizələr',             25),
    ('informatika','4','inf-4-kompyuter',    'Kompüterdə iş',                   30),
    ('informatika','4','inf-4-qrafik',       'Qrafik redaktor',                 40)
  ) as v(fenn, sinif, slug, name, sort)
  join public.subjects s on s.slug = v.fenn
  join public.programs p on p.slug = 'ibtidai'
  join public.levels   l on l.program_id = p.id and l.code = v.sinif
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      level_id = excluded.level_id;

-- ---------------------------------------------------------------------
--  3. ARTIQ QALAN KOHNE MOVZULAR
--     Yalniz BOS olanlar silinir.  Suali ve ya generator qaydasi olan
--     movzu qalir - itki olmasin deye.
-- ---------------------------------------------------------------------
do $$
declare
  silindi int := 0;
  qalan   text;
begin
  --  Yalniz bu migrasiyanin toxundugu fenn/prefikslerde isleyirik
  with hedef as (
    select t.id, t.slug
      from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug in ('riyaziyyat','hayat-bilgisi','informatika')
       and t.slug ~ '^(riy|hey|inf)-[1-4]-'
       and t.slug not in (
         'riy-1-elamet','riy-1-ededler-10','riy-1-muqayise','riy-1-toplama-10',
         'riy-1-cixma-10','riy-1-ededler-20','riy-1-fiqurlar','riy-1-toplama-20',
         'riy-1-cixma-20','riy-1-ededler-100','riy-1-olcme','riy-1-melumat',
         'riy-2-ededler-100','riy-2-toplama-cixma','riy-2-vurma','riy-2-vurma-cedveli',
         'riy-2-bolme','riy-2-zaman','riy-2-olcu','riy-2-fiqurlar','riy-2-mesele',
         'riy-3-ededler-1000','riy-3-toplama','riy-3-cixma','riy-3-vurma-bolme',
         'riy-3-ifade-tenlik','riy-3-fiqurlar','riy-3-vurma-bolme-2','riy-3-kesr',
         'riy-3-ededler-10000','riy-3-olcme','riy-3-melumat','riy-3-mesele',
         'riy-4-coxreqemli','riy-4-toplama-cixma','riy-4-vurma-bolme',
         'riy-4-ifade-tenlik','riy-4-vurma-bolme-2','riy-4-fiqurlar','riy-4-kesr',
         'riy-4-onluq-kesr','riy-4-pullar','riy-4-olcme','riy-4-melumat','riy-4-mesele',
         'hey-1-men-kimem','hey-1-saglamliq','hey-1-insanlar-esyalar',
         'hey-1-etraf-muhit','hey-1-ehtiyat',
         'hey-2-men-mektebim','hey-2-deyerler','hey-2-materiallar',
         'hey-2-yer-kuresi','hey-2-canlilar','hey-2-ehtiyat',
         'hey-3-cemiyyet','hey-3-saglamliq','hey-3-yer-ay','hey-3-materiallar',
         'hey-3-bayramlar','hey-3-tehlukesizlik',
         'hey-4-canli-heyat','hey-4-ferd-aile','hey-4-dovlet-huquq',
         'hey-4-saglamliq-teh','hey-4-hereket-enerji',
         'inf-1-esyalar','inf-1-ardicilliq','inf-1-informasiya','inf-1-kompyuter',
         'inf-1-komp-imkanlar',
         'inf-2-obyekt','inf-2-informasiya','inf-2-alqoritm','inf-2-kompyuter',
         'inf-2-proqramlar',
         'inf-3-informasiya','inf-3-alqoritm','inf-3-kompyuter','inf-3-metn',
         'inf-3-qrafik',
         'inf-4-informasiya','inf-4-alqoritm','inf-4-kompyuter',
         'inf-4-mentiq','inf-4-qrafik')
  ),
  islek as (
    select h.id from hedef h
     where exists (select 1 from public.questions q where q.topic_id = h.id)
        or exists (select 1 from public.topics c where c.parent_id = h.id)
        or exists (select 1 from public.tests t
                    where jsonb_typeof(t.gen_rule->'topics') = 'array'
                      and t.gen_rule->'topics' ? h.id::text)
  ),
  sil as (
    delete from public.topics
     where id in (select id from hedef except select id from islek)
    returning 1
  )
  select count(*) into silindi from sil;

  select string_agg(h.slug, ', ' order by h.slug) into qalan
    from public.topics h
    join public.subjects s on s.id = h.subject_id
   where s.slug in ('riyaziyyat','hayat-bilgisi','informatika')
     and h.slug ~ '^(riy|hey|inf)-[1-4]-'
     and exists (select 1 from public.questions q where q.topic_id = h.id)
     and h.slug in ('riy-1-mesele','hey-1-mektebim','hey-1-temizlik',
                    'hey-2-bitkiler','hey-2-vetenim','hey-3-peseler',
                    'hey-4-iqtisadiyyat','hey-4-texnologiya','hey-4-huquq');

  raise notice 'Kohne movzu silindi: %', silindi;
  if qalan is not null then
    raise notice 'Bu kohne movzularda sual var, silinmedi - ozunuz kocurun: %', qalan;
  end if;
end $$;

-- ---------------------------------------------------------------------
--  4. HESABAT VE YOXLAMA
-- ---------------------------------------------------------------------
do $$
declare n int; bad text; k int;
begin
  select count(*) into n from public.topics;

  select string_agg(t.slug, ', ') into bad
    from public.topics t where t.level_id is null;
  if bad is not null then
    raise exception 'Bu movzular sinife baglanmayib: %', bad;
  end if;

  --  Kocurme yarimciq qalibsa bilek
  select string_agg(t.slug, ', ') into bad
    from public.topics t
    join public.subjects s on s.id = t.subject_id
   where (s.slug, t.slug) in (
     ('riyaziyyat','riy-1-toplama'), ('riyaziyyat','riy-1-cixma'),
     ('riyaziyyat','riy-3-toplama-cixma'), ('riyaziyyat','riy-3-vurma-cedveli'),
     ('riyaziyyat','riy-3-bolme'), ('riyaziyyat','riy-3-perimetr'),
     ('riyaziyyat','riy-3-zaman-olcu'), ('riyaziyyat','riy-4-vurma'),
     ('riyaziyyat','riy-4-bolme'), ('riyaziyyat','riy-4-sahe'),
     ('riyaziyyat','riy-4-olcu'));
  if bad is not null then
    raise exception 'Kohne slug-lar qalib (kocurme islemedi): %', bad;
  end if;

  --  Suali olan movzu yoxa cixmasin
  select count(*) into k from public.questions where topic_id is null
     and owner_type = 'platform';
  if k > 0 then
    raise exception 'Movzusuz platforma suali qaldi: % ede', k;
  end if;

  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id
   where s.slug = 'riyaziyyat' and t.slug ~ '^riy-4-';
  if k <> 12 then
    raise exception 'Riyaziyyat 4 movzulari: 12 gozlenilirdi, % var', k;
  end if;

  raise notice 'Movzu agaci e-dersliye uygunlasdirildi: % movzu.', n;
end $$;
