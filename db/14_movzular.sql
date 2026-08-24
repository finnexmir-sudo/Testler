-- =====================================================================
--  14_movzular.sql : IBTIDAI SINIFLER UCUN MOVZU AGACI (1-4)
--
--  Niye lazimdir:  "zeif noqte" analitikasi movzu uzerinde qurulub.
--  Movzusuz sual hec vaxt hesabata dusmur.  Movzular MERKEZDEN gelir -
--  muellim ozu yaza bilmir - cunki her muellim "Vurma", "Vurma cedveli",
--  "vurma" yazsaydi, hesabat uc yere bolunerdi ve menasini itirerdi.
--
--  Slug qaydasi:  <fenn>-<sinif>-<movzu>
--  topics-de unique(subject_id, slug) var, ona gore sinif slug-in
--  icinde olmalidir - eks halda 2-ci ve 3-cu sinif "vurma"si toqqusur.
--
--  DIQQET:  bu siyahi ibtidai tehsilin adi qurulusuna esaslanir.
--  Resmi kurikulumla tam uygunlugu MUELLIM YOXLAMALIDIR - ad ve sira
--  rahatca deyisdirile biler, id-ler qorunur (suallar itmir).
--
--  Tekrar isledile biler.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. KOHNE SLUG-LARI YENI QAYDAYA KECIRIRIK
--     id deyismir - hemin movzuya baglanmis suallar yerinde qalir.
-- ---------------------------------------------------------------------
update public.topics t
   set slug = 'riy-3-' || t.slug
  from public.subjects s
 where s.id = t.subject_id and s.slug = 'riyaziyyat'
   and t.slug in ('vurma-cedveli','bolme','toplama-cixma','mesele');

update public.topics t
   set slug = 'az-3-' || t.slug
  from public.subjects s
 where s.id = t.subject_id and s.slug = 'az-dili'
   and t.slug in ('sait-samit','soz-novleri','yazi-qaydasi');

-- ---------------------------------------------------------------------
--  2. MOVZULAR
-- ---------------------------------------------------------------------
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- =========================== RIYAZIYYAT ===========================
    ('riyaziyyat','1','riy-1-ededler-10',    'Ədədlər 1–10',              10),
    ('riyaziyyat','1','riy-1-ededler-20',    'Ədədlər 11–20',             20),
    ('riyaziyyat','1','riy-1-toplama',       'Toplama',                   30),
    ('riyaziyyat','1','riy-1-cixma',         'Çıxma',                     40),
    ('riyaziyyat','1','riy-1-muqayise',      'Müqayisə: böyük, kiçik',    50),
    ('riyaziyyat','1','riy-1-fiqurlar',      'Həndəsi fiqurlar',          60),
    ('riyaziyyat','1','riy-1-olcme',         'Ölçmə və uzunluq',          70),
    ('riyaziyyat','1','riy-1-mesele',        'Sadə məsələlər',            80),

    ('riyaziyyat','2','riy-2-ededler-100',   'Ədədlər 100-ə qədər',       10),
    ('riyaziyyat','2','riy-2-toplama-cixma', 'Toplama və çıxma',          20),
    ('riyaziyyat','2','riy-2-vurma',         'Vurma anlayışı',            30),
    ('riyaziyyat','2','riy-2-vurma-cedveli', 'Vurma cədvəli (2–5)',       40),
    ('riyaziyyat','2','riy-2-bolme',         'Bölmə',                     50),
    ('riyaziyyat','2','riy-2-zaman',         'Zaman və saat',             60),
    ('riyaziyyat','2','riy-2-olcu',          'Ölçü vahidləri',            70),
    ('riyaziyyat','2','riy-2-fiqurlar',      'Həndəsi fiqurlar',          80),
    ('riyaziyyat','2','riy-2-mesele',        'Mətn məsələləri',           90),

    ('riyaziyyat','3','riy-3-ededler-1000',  'Ədədlər 1000-ə qədər',      10),
    ('riyaziyyat','3','riy-3-toplama-cixma', 'Toplama və çıxma',          20),
    ('riyaziyyat','3','riy-3-vurma-cedveli', 'Vurma cədvəli',             30),
    ('riyaziyyat','3','riy-3-bolme',         'Bölmə',                     40),
    ('riyaziyyat','3','riy-3-kesr',          'Kəsrlər',                   50),
    ('riyaziyyat','3','riy-3-perimetr',      'Perimetr',                  60),
    ('riyaziyyat','3','riy-3-zaman-olcu',    'Zaman və ölçü vahidləri',   70),
    ('riyaziyyat','3','riy-3-mesele',        'Mətn məsələləri',           80),

    ('riyaziyyat','4','riy-4-coxreqemli',    'Çoxrəqəmli ədədlər',        10),
    ('riyaziyyat','4','riy-4-vurma',         'Çoxrəqəmli vurma',          20),
    ('riyaziyyat','4','riy-4-bolme',         'Çoxrəqəmli bölmə',          30),
    ('riyaziyyat','4','riy-4-kesr',          'Kəsrlər',                   40),
    ('riyaziyyat','4','riy-4-onluq-kesr',    'Onluq kəsrlər',             50),
    ('riyaziyyat','4','riy-4-sahe',          'Sahə və perimetr',          60),
    ('riyaziyyat','4','riy-4-olcu',          'Ölçü vahidləri',            70),
    ('riyaziyyat','4','riy-4-mesele',        'Mətn məsələləri',           80),

    -- ========================= AZERBAYCAN DILI ========================
    ('az-dili','1','az-1-sesler-herfler', 'Səslər və hərflər',            10),
    ('az-dili','1','az-1-sait-samit',     'Sait və samit',                20),
    ('az-dili','1','az-1-heca',           'Heca',                         30),
    ('az-dili','1','az-1-soz-cumle',      'Söz və cümlə',                 40),
    ('az-dili','1','az-1-boyuk-herf',     'Böyük hərf',                   50),
    ('az-dili','1','az-1-oxu',            'Oxu və anlama',                60),

    ('az-dili','2','az-2-soz-novleri',    'Söz növləri',                  10),
    ('az-dili','2','az-2-ad-bildiren',    'Ad bildirən sözlər',           20),
    ('az-dili','2','az-2-elamet',         'Əlamət bildirən sözlər',       30),
    ('az-dili','2','az-2-hereket',        'Hərəkət bildirən sözlər',      40),
    ('az-dili','2','az-2-cumle-novleri',  'Cümlə növləri',                50),
    ('az-dili','2','az-2-durgu',          'Durğu işarələri',              60),
    ('az-dili','2','az-2-yazi-qaydasi',   'Yazı qaydası',                 70),

    ('az-dili','3','az-3-sait-samit',     'Sait və samit',                10),
    ('az-dili','3','az-3-isim',           'İsim',                         20),
    ('az-dili','3','az-3-sifet',          'Sifət',                        30),
    ('az-dili','3','az-3-fel',            'Fel',                          40),
    ('az-dili','3','az-3-soz-novleri',    'Söz növləri',                  50),
    ('az-dili','3','az-3-cumle',          'Cümlənin baş üzvləri',         60),
    ('az-dili','3','az-3-yazi-qaydasi',   'Yazı qaydası',                 70),
    ('az-dili','3','az-3-metn',           'Mətn və nitq',                 80),

    ('az-dili','4','az-4-isim-hallari',   'İsmin halları',                10),
    ('az-dili','4','az-4-sifet-dereceleri','Sifətin dərəcələri',          20),
    ('az-dili','4','az-4-fel-zamanlari',  'Felin zamanları',              30),
    ('az-dili','4','az-4-evezlik',        'Əvəzlik',                      40),
    ('az-dili','4','az-4-cumle-uzvleri',  'Cümlə üzvləri',                50),
    ('az-dili','4','az-4-durgu',          'Durğu işarələri',              60),
    ('az-dili','4','az-4-metn-novleri',   'Mətn növləri',                 70),
    ('az-dili','4','az-4-insa',           'Yazı və inşa',                 80),

    -- =========================== INGILIS DILI =========================
    ('ingilis-dili','1','ing-1-alphabet',  'Alphabet — əlifba',           10),
    ('ingilis-dili','1','ing-1-greetings', 'Greetings — salamlaşma',      20),
    ('ingilis-dili','1','ing-1-numbers',   'Numbers 1–10',                30),
    ('ingilis-dili','1','ing-1-colours',   'Colours — rənglər',           40),
    ('ingilis-dili','1','ing-1-family',    'Family — ailə',               50),
    ('ingilis-dili','1','ing-1-animals',   'Animals — heyvanlar',         60),

    ('ingilis-dili','2','ing-2-numbers',   'Numbers 1–100',               10),
    ('ingilis-dili','2','ing-2-school',    'School — məktəb',             20),
    ('ingilis-dili','2','ing-2-body',      'Body — bədən üzvləri',        30),
    ('ingilis-dili','2','ing-2-food',      'Food — yeməklər',             40),
    ('ingilis-dili','2','ing-2-toys',      'Toys — oyuncaqlar',           50),
    ('ingilis-dili','2','ing-2-verbs',     'Verbs — sadə fellər',         60),

    ('ingilis-dili','3','ing-3-time',      'Time — vaxt',                 10),
    ('ingilis-dili','3','ing-3-clothes',   'Clothes — geyim',             20),
    ('ingilis-dili','3','ing-3-weather',   'Weather — hava',              30),
    ('ingilis-dili','3','ing-3-house',     'House — ev',                  40),
    ('ingilis-dili','3','ing-3-present',   'Present Simple',              50),
    ('ingilis-dili','3','ing-3-prepositions','Prepositions — sözönləri',  60),

    ('ingilis-dili','4','ing-4-past',      'Past Simple',                 10),
    ('ingilis-dili','4','ing-4-jobs',      'Jobs — peşələr',              20),
    ('ingilis-dili','4','ing-4-hobbies',   'Hobbies — maraqlar',          30),
    ('ingilis-dili','4','ing-4-comparative','Comparatives — müqayisə',    40),
    ('ingilis-dili','4','ing-4-questions', 'Questions — sual cümlələri',  50),
    ('ingilis-dili','4','ing-4-reading',   'Reading — oxu və anlama',     60),

    -- =========================== HEYAT BILGISI ========================
    ('hayat-bilgisi','1','hey-1-men-ailem',   'Mən və ailəm',             10),
    ('hayat-bilgisi','1','hey-1-mektebim',    'Məktəbim',                 20),
    ('hayat-bilgisi','1','hey-1-saglamliq',   'Sağlamlıq və gigiyena',    30),
    ('hayat-bilgisi','1','hey-1-tehlukesizlik','Təhlükəsizlik',           40),
    ('hayat-bilgisi','1','hey-1-fesiller',    'Fəsillər',                 50),
    ('hayat-bilgisi','1','hey-1-temizlik',    'Səliqə və təmizlik',       60),

    ('hayat-bilgisi','2','hey-2-emek',        'Ailədə əmək',              10),
    ('hayat-bilgisi','2','hey-2-dostluq',     'Dostluq və davranış',      20),
    ('hayat-bilgisi','2','hey-2-tebiet',      'Təbiət',                   30),
    ('hayat-bilgisi','2','hey-2-heyvanlar',   'Heyvanlar aləmi',          40),
    ('hayat-bilgisi','2','hey-2-bitkiler',    'Bitkilər aləmi',           50),
    ('hayat-bilgisi','2','hey-2-vetenim',     'Vətənim',                  60),

    ('hayat-bilgisi','3','hey-3-cemiyyet',    'Cəmiyyət və qaydalar',     10),
    ('hayat-bilgisi','3','hey-3-peseler',     'Peşələr',                  20),
    ('hayat-bilgisi','3','hey-3-su-hava',     'Su və hava',               30),
    ('hayat-bilgisi','3','hey-3-servetler',   'Təbii sərvətlər',          40),
    ('hayat-bilgisi','3','hey-3-bayramlar',   'Bayramlar və adətlər',     50),
    ('hayat-bilgisi','3','hey-3-ekologiya',   'Ətraf mühit',              60),

    ('hayat-bilgisi','4','hey-4-veten-tarixi','Vətənin tarixi',           10),
    ('hayat-bilgisi','4','hey-4-remzler',     'Dövlət rəmzləri',          20),
    ('hayat-bilgisi','4','hey-4-iqtisadiyyat','Sadə iqtisadiyyat',        30),
    ('hayat-bilgisi','4','hey-4-texnologiya', 'Texnologiya və rabitə',    40),
    ('hayat-bilgisi','4','hey-4-iqlim',       'İqlim və coğrafiya',       50),
    ('hayat-bilgisi','4','hey-4-huquq',       'Hüquq və vəzifələr',       60)
  ) as v(fenn, sinif, slug, name, sort)
  join public.subjects s on s.slug = v.fenn
  join public.programs p on p.slug = 'ibtidai'
  join public.levels   l on l.program_id = p.id and l.code = v.sinif
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      level_id = excluded.level_id;

-- ---------------------------------------------------------------------
--  3. HESABAT
-- ---------------------------------------------------------------------
do $$
declare n int; bad text;
begin
  select count(*) into n from public.topics;

  --  Sinifsiz movzu qalmasin - eks halda suzgecde gorunmur
  select string_agg(t.slug, ', ') into bad
    from public.topics t where t.level_id is null;
  if bad is not null then
    raise exception 'Bu movzular sinife baglanmayib: %', bad;
  end if;

  --  Kohne slug qalibsa kocurme yarimciqdir
  select string_agg(t.slug, ', ') into bad
    from public.topics t
   where t.slug in ('vurma-cedveli','bolme','toplama-cixma','mesele',
                    'sait-samit','soz-novleri','yazi-qaydasi');
  if bad is not null then
    raise exception 'Kohne slug-lar qalib: %', bad;
  end if;

  raise notice 'Movzu agaci quruldu: % movzu (1-4 sinif, 4 fenn).', n;
end $$;
