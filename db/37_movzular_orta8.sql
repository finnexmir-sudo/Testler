-- =====================================================================
--  37_movzular_orta8.sql : 8-CI SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az mundericatlari (tools/mundericat.py).
--  Yalniz bolme adlari goturulub - derslik metni yox.
--
--  Kitablar:
--    Riyaziyyat 8        393 - 11 bolme
--    Azerbaycan dili 8   784 - tema esasli, qrammatika oxu kurikulum
--                        uzre (soz birlesmesi, cumle uzvleri, hemcins
--                        uzvler, xitab-ara sozler)
--    Ingilis dili 8      824 esas derslikde portal mundericati yoxdur;
--                        ilk movzular 788-in dersleri, qalani kurikulum
--    Informatika 8       797 - 6 bolme
--    Azerbaycan tarixi 8 801 - 4 bolme
--    Fizika 8            931 + 932 - 6 bolme
--    Kimya 8             935 + 936 - 6 bolme
--    Biologiya 8         927 + 928 - 8 bolme
--    Cografiya 8         799 - 10 bolme (8 movzuya birlesdirilib)
--
--  ON SERT: 33_movzular_orta7.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: bank fayllari, en sonda 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-7-muxteser') then
    raise exception 'ONCE 33_movzular_orta7.sql isledilmelidir.';
  end if;
end $$;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ==================== RIYAZIYYAT 8 (393) ==========================
    ('riyaziyyat','8','riy-8-kvadrat-kok',    'Kvadrat kök. Həqiqi ədədlər',  10),
    ('riyaziyyat','8','riy-8-pifaqor',        'Pifaqor teoremi',              20),
    ('riyaziyyat','8','riy-8-kvadrat-tenlik', 'Kvadrat tənliklər',            30),
    ('riyaziyyat','8','riy-8-dordbucaqlilar', 'Dördbucaqlılar',               40),
    ('riyaziyyat','8','riy-8-rasional-ifade', 'Rasional ifadələr',            50),
    ('riyaziyyat','8','riy-8-sahe',           'Fiqurların sahəsi',            60),
    ('riyaziyyat','8','riy-8-rasional-tenlik','Rasional tənliklər',           70),
    ('riyaziyyat','8','riy-8-oxsarliq',       'Fiqurların oxşarlığı',         80),
    ('riyaziyyat','8','riy-8-berabersizlik',  'Bərabərsizliklər',             90),
    ('riyaziyyat','8','riy-8-triqonometrik',  'Triqonometrik nisbətlər. Koordinatlar', 100),
    ('riyaziyyat','8','riy-8-ehtimal',        'Məlumat və ehtimal',          110),

    -- ========= AZERBAYCAN DILI 8 (kurikulum qrammatika oxu) ===========
    ('az-dili','8','az-8-soz-birlesmesi', 'Söz birləşmələri',                10),
    ('az-dili','8','az-8-mubteda-xeber',  'Mübtəda və xəbər',                20),
    ('az-dili','8','az-8-ikinci-uzvler',  'İkinci dərəcəli üzvlər',          30),
    ('az-dili','8','az-8-hemcins',        'Həmcins üzvlər',                  40),
    ('az-dili','8','az-8-xitab-ara',      'Xitab və ara sözlər',             50),
    ('az-dili','8','az-8-cumle-novleri',  'Sadə cümlənin növləri',           60),
    ('az-dili','8','az-8-durgu',          'Durğu işarələri',                 70),
    ('az-dili','8','az-8-metn-uslub',     'Mətn və üslub',                   80),

    -- ==================== INGILIS DILI 8 ==============================
    ('ingilis-dili','8','ing-8-holidays',        'Holidays and Travel',      10),
    ('ingilis-dili','8','ing-8-inventions',      'Young Inventors',          20),
    ('ingilis-dili','8','ing-8-hobbies',         'Hobbies Around the World', 30),
    ('ingilis-dili','8','ing-8-present-perfect', 'Present Perfect',          40),
    ('ingilis-dili','8','ing-8-media',           'Mass Media',               50),
    ('ingilis-dili','8','ing-8-environment',     'Environment',              60),

    -- ==================== INFORMATIKA 8 (797) =========================
    ('informatika','8','inf-8-informasiya',     'İnformasiya',               10),
    ('informatika','8','inf-8-multimedia',      'Multimedia',                20),
    ('informatika','8','inf-8-proqramlasdirma', 'Proqramlaşdırma',           30),
    ('informatika','8','inf-8-kompyuter',       'Kompüter',                  40),
    ('informatika','8','inf-8-tetbiqi',         'Tətbiqi proqramlar',        50),
    ('informatika','8','inf-8-internet',        'İnformasiya cəmiyyəti və İnternet', 60),

    -- ============== AZERBAYCAN TARIXI 8 (801) =========================
    ('tarix','8','tarix-8-xvi-xvii',  'Azərbaycan XVI–XVII əsrlərdə',        10),
    ('tarix','8','tarix-8-xviii-1',   'Azərbaycan XVIII əsrin I yarısında',  20),
    ('tarix','8','tarix-8-xanliqlar', 'Xanlıqlar dövrü',                     30),
    ('tarix','8','tarix-8-xix',       'Azərbaycan XIX əsrin əvvəllərində',   40),

    -- ==================== FIZIKA 8 (931 + 932) ========================
    ('fizika','8','fiz-8-quvve',        'Qüvvə',                             10),
    ('fizika','8','fiz-8-is-enerji',    'İş və enerji',                      20),
    ('fizika','8','fiz-8-tezyiq',       'Təzyiq',                            30),
    ('fizika','8','fiz-8-dalgalar',     'Dalğalar',                          40),
    ('fizika','8','fiz-8-istilik',      'İstilik hərəkəti. Daxili enerji',   50),
    ('fizika','8','fiz-8-istilik-qanun','İstilikdə enerjinin saxlanması',    60),

    -- ==================== KIMYA 8 (935 + 936) =========================
    ('kimya','8','kim-8-dovri-cedvel',     'Atomun quruluşu və dövri cədvəl', 10),
    ('kimya','8','kim-8-rabite',           'Kimyəvi rabitə',                20),
    ('kimya','8','kim-8-reaksiya-tesnifat','Reaksiyaların təsnifatı',       30),
    ('kimya','8','kim-8-reaksiya-sureti',  'Reaksiyaların sürəti',          40),
    ('kimya','8','kim-8-oksidlesme',       'Oksidləşmə və reduksiya',       50),
    ('kimya','8','kim-8-tursu-esas',       'Turşular və əsaslar',           60),

    -- =================== BIOLOGIYA 8 (927 + 928) ======================
    ('biologiya','8','bio-8-heyat-kimyasi', 'Həyatın kimyası',              10),
    ('biologiya','8','bio-8-bitki',         'Bitki orqanizmi',              20),
    ('biologiya','8','bio-8-qan-dovrani',   'Qan dövranı sistemi',          30),
    ('biologiya','8','bio-8-teneffus',      'Tənəffüs sistemi',             40),
    ('biologiya','8','bio-8-hezm',          'Həzm və qidalanma',            50),
    ('biologiya','8','bio-8-coxalma',       'Heyvanlarda və insanda çoxalma', 60),
    ('biologiya','8','bio-8-tesnifat',      'Canlı aləmin təsnifatı',       70),
    ('biologiya','8','bio-8-saglamliq',     'İnsan sağlamlığı və mühit',    80),

    -- =================== COGRAFIYA 8 (799) ============================
    ('cografiya','8','cog-8-kesfler',    'Coğrafi kəşflər və tədqiqatlar',  10),
    ('cografiya','8','cog-8-xerite',     'Xəritələr və təsvir üsulları',    20),
    ('cografiya','8','cog-8-yer-hereketi','Yerin hərəkəti və nəticələri',   30),
    ('cografiya','8','cog-8-tektonik',   'Yerin fəal tektonik təbəqəsi',    40),
    ('cografiya','8','cog-8-atmosfer',   'Atmosfer',                        50),
    ('cografiya','8','cog-8-hidrosfer',  'Su təbəqəsi və biosfer',          60),
    ('cografiya','8','cog-8-olkeler',    'Dünya ölkələri və əhali',         70),
    ('cografiya','8','cog-8-ekologiya',  'Ekoloji mühit və mühafizə',       80)
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
   where p.slug = 'orta' and l.code = '8';
  if n < 63 then
    raise exception '8-ci sinif movzulari: 63 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '8'
     group by s.slug) x
   where (x.slug = 'riyaziyyat'   and x.say <> 11)
      or (x.slug = 'az-dili'      and x.say <> 8)
      or (x.slug = 'ingilis-dili' and x.say <> 6)
      or (x.slug = 'informatika'  and x.say <> 6)
      or (x.slug = 'tarix'        and x.say <> 4)
      or (x.slug = 'fizika'       and x.say <> 6)
      or (x.slug = 'kimya'        and x.say <> 6)
      or (x.slug = 'biologiya'    and x.say <> 8)
      or (x.slug = 'cografiya'    and x.say <> 8);
  if bad is not null then
    raise exception 'Fenn uzre movzu sayi gozlenilenden ferqlidir: %', bad;
  end if;

  raise notice '8-ci sinif agaci: % movzu (riy 11, az 8, ing 6, inf 6, tarix 4, fiz 6, kim 6, bio 8, cog 8).', n;
end $$;
