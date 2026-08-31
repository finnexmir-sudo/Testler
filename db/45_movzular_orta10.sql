-- =====================================================================
--  45_movzular_orta10.sql : 10-CU SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az mundericatlari (tools/mundericat.py).
--  Yalniz bolme adlari goturulub - derslik metni yox.
--
--  Kitablar:
--    Riyaziyyat 10       741 - 10 bolme
--    Azerbaycan dili 10  725/726 - tema esasli; qrammatika oxu kurikulum
--                        uzre (dil, uslub, tekrar kurs, nitq medeniyyeti)
--    Ingilis dili 10     738 - 9 unit (6 movzuya birlesdirilib)
--    Informatika 10      736 - 6 bolme (5 movzuya birlesdirilib)
--    Umumi tarix 10      745 - 4 bolme (6 movzuya bolunub;
--                        Azerbaycan tarixi 10 kitabi portalda yoxdur)
--    Fizika 10           734 - 7 fesil (6 movzuya birlesdirilib)
--    Kimya 10            739 - 7 bolme (6 movzuya birlesdirilib)
--    Biologiya 10        727 - 5 bolme (8 movzuya bolunub)
--    Cografiya 10        729 - 2 hisse + giris (8 movzuya bolunub)
--
--  ON SERT: 41_movzular_orta9.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: bank fayllari, en sonda 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-9-kok') then
    raise exception 'ONCE 41_movzular_orta9.sql isledilmelidir.';
  end if;
end $$;

--  10-cu sinif seviyyesi (kohne bazada yoxdursa yaradilir)
insert into public.levels (program_id, code, name, sort)
select p.id, '10', app.ordinal_az(10) || ' sinif', 100
  from public.programs p
 where p.slug = 'orta'
on conflict (program_id, code) do nothing;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ==================== RIYAZIYYAT 10 (741) =========================
    ('riyaziyyat','10','riy-10-funksiya',       'Funksiyalar və xassələri',    10),
    ('riyaziyyat','10','riy-10-feza',           'Fəzada düz xətt və müstəvi',  20),
    ('riyaziyyat','10','riy-10-triq-ifade',     'Triqonometrik ifadələr və çevrilmələr', 30),
    ('riyaziyyat','10','riy-10-sinus-kosinus',  'Sinuslar və kosinuslar teoremi', 40),
    ('riyaziyyat','10','riy-10-triq-qrafik',    'Triqonometrik funksiyaların qrafikləri', 50),
    ('riyaziyyat','10','riy-10-coxuzlu',        'Çoxüzlülər: prizma və piramida', 60),
    ('riyaziyyat','10','riy-10-triq-tenlik',    'Triqonometrik tənliklər',     70),
    ('riyaziyyat','10','riy-10-hecm',           'Fəza fiqurlarının həcmi',     80),
    ('riyaziyyat','10','riy-10-ustlu-loqarifm', 'Üstlü və loqarifmik funksiyalar', 90),
    ('riyaziyyat','10','riy-10-statistika',     'Seçmə. Binom. Bernulli sınaqları', 100),
    -- ==================== AZERBAYCAN DILI 10 (725/726) ================
    ('az-dili','10','az-10-dil-unsiyyet',    'Dil və ünsiyyət. Yazının tarixi', 10),
    ('az-dili','10','az-10-fonetika-tekrar', 'Fonetika. Orfoqrafiya və orfoepiya', 20),
    ('az-dili','10','az-10-leksika',         'Leksika və frazeologiya',       30),
    ('az-dili','10','az-10-uslub',           'Funksional üslublar',           40),
    ('az-dili','10','az-10-morfologiya-t',   'Morfologiya: təkrar kurs',      50),
    ('az-dili','10','az-10-sintaksis-t',     'Sintaksis: təkrar kurs',        60),
    ('az-dili','10','az-10-metn',            'Mətn quruluşu və təhlili',      70),
    ('az-dili','10','az-10-nitq-medeni',     'Nitq mədəniyyəti və natiqlik',  80),
    -- ==================== INGILIS DILI 10 (738) =======================
    ('ingilis-dili','10','ing-10-kindness',    'Kindness',                    10),
    ('ingilis-dili','10','ing-10-victory',     'We are Victorious',           20),
    ('ingilis-dili','10','ing-10-cultures',    'Cultures',                    30),
    ('ingilis-dili','10','ing-10-environment', 'Environmental Problems',      40),
    ('ingilis-dili','10','ing-10-success',     'Success and Health',          50),
    ('ingilis-dili','10','ing-10-media',       'Stages of Life. Media',       60),
    -- ==================== INFORMATIKA 10 (736) ========================
    ('informatika','10','inf-10-informasiya', 'İnformasiya və təhlükəsizlik', 10),
    ('informatika','10','inf-10-model',       'Modelləşdirmə',                20),
    ('informatika','10','inf-10-baza',        'Verilənlər bazası',            30),
    ('informatika','10','inf-10-sebeke',      'Kompüter şəbəkələri',          40),
    ('informatika','10','inf-10-veb',         'Veb və informasiya cəmiyyəti', 50),
    -- ==================== TARIX 10 ====================================
    --  DIQQET: 10-cu sinifde "Azerbaycan tarixi" derslikyi YOXDUR -
    --  portalda (book_id 745) yalniz "Umumi tarix" var.  Ona gore bu
    --  sinifin dunya tarixi movzulari 'tarix' fenninde deyil,
    --  'umumi-tarix' fennindedir: db/68_movzular_umumi_tarix10.sql.
    -- ==================== FIZIKA 10 (734) =============================
    ('fizika','10','fiz-10-kinematika',    'Kinematikanın əsasları',         10),
    ('fizika','10','fiz-10-dinamika',      'Dinamika. Nyuton qanunları',     20),
    ('fizika','10','fiz-10-saxlanma',      'Saxlanma qanunları. İş və enerji', 30),
    ('fizika','10','fiz-10-reqs-dalga',    'Mexaniki rəqslər və dalğalar',   40),
    ('fizika','10','fiz-10-molekulyar',    'Molekulyar-kinetik nəzəriyyə',   50),
    ('fizika','10','fiz-10-termodinamika', 'Termodinamikanın əsasları',      60),
    -- ==================== KIMYA 10 (739) ==============================
    ('kimya','10','kim-10-alkan',          'Alkanlar',                       10),
    ('kimya','10','kim-10-alken',          'Alkenlər',                       20),
    ('kimya','10','kim-10-alkin',          'Alkinlər',                       30),
    ('kimya','10','kim-10-dien-tsiklo',    'Alkadienlər və tsikloalkanlar',  40),
    ('kimya','10','kim-10-aromatik',       'Aromatik karbohidrogenlər',      50),
    ('kimya','10','kim-10-neft',           'Karbohidrogenlərin təbii mənbələri', 60),
    -- ==================== BIOLOGIYA 10 (727) ==========================
    ('biologiya','10','bio-10-heyat-prosesleri', 'Canlılarda həyat prosesləri', 10),
    ('biologiya','10','bio-10-istehsal',         'Biosintez və enerji mübadiləsi', 20),
    ('biologiya','10','bio-10-deyiskenlik',      'Dəyişkənliyin formaları',   30),
    ('biologiya','10','bio-10-saglam-heyat',     'Mübadilə və sağlam həyat',  40),
    ('biologiya','10','bio-10-epidemiologiya',   'Epidemiologiya',            50),
    ('biologiya','10','bio-10-tekamul',          'Üzvi aləmin təkamülü. İnsanın mənşəyi', 60),
    ('biologiya','10','bio-10-genetika',         'Genetikanın əsasları',      70),
    ('biologiya','10','bio-10-ekologiya',        'Ekologiya və biomüxtəliflik', 80),
    -- ==================== COGRAFIYA 10 (729) ==========================
    ('cografiya','10','cog-10-yer-kainat',   'Yer səma cismidir',            10),
    ('cografiya','10','cog-10-kartoqrafiya', 'Kartoqrafik proyeksiyalar',    20),
    ('cografiya','10','cog-10-geologiya',    'Yer qabığının geoloji inkişafı', 30),
    ('cografiya','10','cog-10-iqlim-ehtiyat','İqlim ehtiyatları',            40),
    ('cografiya','10','cog-10-quru-sulari',  'Quru suları. Xəzər dənizi',    50),
    ('cografiya','10','cog-10-tebeqe',       'Coğrafi təbəqə. Fiziki-coğrafi vilayətlər', 60),
    ('cografiya','10','cog-10-ehali-siyasi', 'Əhali və siyasi xəritə',       70),
    ('cografiya','10','cog-10-eti',          'Elmi-texniki inqilab və təsərrüfat', 80)
  ) as v(fenn, sinif, slug, name, sort)
  join public.subjects s on s.slug = v.fenn
  join public.programs p on p.slug = 'orta'
  join public.levels   l on l.program_id = p.id and l.code = v.sinif
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      level_id = excluded.level_id;

do $$
declare n int; bad text;
begin
  select count(*) into n
    from public.topics t
    join public.levels l on l.id = t.level_id
    join public.programs p on p.id = l.program_id
   where p.slug = 'orta' and l.code = '10';
  if n < 57 then
    raise exception '10-cu sinif movzulari: 57 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '10'
     group by s.slug) x
   where (x.slug = 'riyaziyyat'   and x.say <> 10)
      or (x.slug = 'az-dili'      and x.say <> 8)
      or (x.slug = 'ingilis-dili' and x.say <> 6)
      or (x.slug = 'informatika'  and x.say <> 5)
      or (x.slug = 'fizika'       and x.say <> 6)
      or (x.slug = 'kimya'        and x.say <> 6)
      or (x.slug = 'biologiya'    and x.say <> 8)
      or (x.slug = 'cografiya'    and x.say <> 8);
  if bad is not null then
    raise exception 'Fenn uzre movzu sayi gozlenilenden ferqlidir: %', bad;
  end if;

  raise notice '10-cu sinif agaci: % movzu (riy 10, az 8, ing 6, inf 5, fiz 6, kim 6, bio 8, cog 8). Tarix 10 - bax 68.', n;
end $$;
