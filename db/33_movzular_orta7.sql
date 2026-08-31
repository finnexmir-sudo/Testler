-- =====================================================================
--  33_movzular_orta7.sql : 7-CI SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az mundericatlari (tools/mundericat.py).
--  Yalniz bolme adlari goturulub - derslik metni yox.
--
--  Kitablar:
--    Riyaziyyat 7        714 - 10 bolme
--    Azerbaycan dili 7   696 + 697 - derslik tema esaslidir,
--                        qrammatika oxu kurikulum uzre (feil, zerf,
--                        komekci nitq hisseleri) cixarilib
--    Ingilis dili 7      710 - 6 unit
--    Informatika 7       708 - 5 bolme
--    Umumi tarix 7       723 - 2 bolme (Azerbaycan tarixi 7 portalda
--                        yoxdur - tarix fennine umumi tarix goturulub)
--    Fizika 7            867 + 868 - 7 bolme
--    Kimya 7             871 + 872 - 7 bolme (fenn 7-de baslayir)
--    Biologiya 7         863 + 864 - 7 bolme
--    Cografiya 7         922 + 923 - 7 bolme
--
--  Kimya fenni orta proqrama burada elave olunur (04_seed-in kohne
--  nusxelerinde yox idi).
--
--  ON SERT: 29_movzular_orta6.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: bank fayllari, en sonda 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-6-coxluqlar') then
    raise exception 'ONCE 29_movzular_orta6.sql isledilmelidir.';
  end if;
end $$;

--  Kimya orta proqramda (7-ci sinifden kecilir)
insert into public.program_subjects (program_id, subject_id)
select p.id, s.id from public.programs p, public.subjects s
 where p.slug = 'orta' and s.slug = 'kimya'
on conflict do nothing;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ==================== RIYAZIYYAT 7 (714) ==========================
    ('riyaziyyat','7','riy-7-statistika',    'Statistika. Ehtimal',           10),
    ('riyaziyyat','7','riy-7-rasional',      'Rasional ədədlər',              20),
    ('riyaziyyat','7','riy-7-paralellik',    'Paralellik. Perpendikulyarlıq', 30),
    ('riyaziyyat','7','riy-7-coxhedliler',   'Birhədlilər. Çoxhədlilər',      40),
    ('riyaziyyat','7','riy-7-ucbucaqlar',    'Üçbucaqlar',                    50),
    ('riyaziyyat','7','riy-7-muxteser',      'Müxtəsər vurma düsturları',     60),
    ('riyaziyyat','7','riy-7-funksiya',      'Funksiya',                      70),
    ('riyaziyyat','7','riy-7-tenlikler-sistemi', 'Xətti tənliklər sistemi',   80),
    ('riyaziyyat','7','riy-7-konqruyentlik', 'Üçbucaqların konqruyentliyi',   90),
    ('riyaziyyat','7','riy-7-situasiya',     'Situasiya məsələləri',         100),

    -- ========= AZERBAYCAN DILI 7 (kurikulum qrammatika oxu) ===========
    ('az-dili','7','az-7-feil-zaman',   'Feilin zamanları',                  10),
    ('az-dili','7','az-7-feil-sekil',   'Feilin şəkilləri',                  20),
    ('az-dili','7','az-7-feil-qurulus', 'Feilin quruluşu. Təsirli-təsirsiz', 30),
    ('az-dili','7','az-7-zerf',         'Zərf',                              40),
    ('az-dili','7','az-7-qosma-baglayici', 'Qoşma və bağlayıcı',             50),
    ('az-dili','7','az-7-edat-modal',   'Ədat və modal sözlər',              60),
    ('az-dili','7','az-7-nida',         'Nida. Yamsılamalar',                70),
    ('az-dili','7','az-7-uslub',        'Nitq mədəniyyəti. Üslub',           80),

    -- ==================== INGILIS DILI 7 (710) ========================
    ('ingilis-dili','7','ing-7-schools',    'Unit 1. Schools Around the World', 10),
    ('ingilis-dili','7','ing-7-technology', 'Unit 2. A World of Technology',    20),
    ('ingilis-dili','7','ing-7-talent',     'Unit 3. What a Talent!',           30),
    ('ingilis-dili','7','ing-7-travel',     'Unit 4. Travel',                   40),
    ('ingilis-dili','7','ing-7-friends',    'Unit 5. Friends Forever',          50),
    ('ingilis-dili','7','ing-7-future',     'Unit 6. Life in the Future',       60),

    -- ==================== INFORMATIKA 7 (708) =========================
    ('informatika','7','inf-7-kompyuter',       'Kompüter',                  10),
    ('informatika','7','inf-7-tetbiqi',         'Tətbiqi proqramlar',        20),
    ('informatika','7','inf-7-informasiya',     'İnformasiya',               30),
    ('informatika','7','inf-7-proqramlasdirma', 'Proqramlaşdırma',           40),
    ('informatika','7','inf-7-internet',        'İnternet',                  50),

    -- ================== UMUMI TARIX 7 (723) ===========================
    --  DIQQET: 7-ci sinifde "Azerbaycan tarixi" derslikyi YOXDUR -
    --  portalda (book_id 723) yalniz "Umumi tarix" var.  Ona gore bu
    --  sinifin dunya tarixi movzulari 'tarix' fenninde deyil,
    --  'umumi-tarix' fennindedir: db/66 + db/70, bank db/67 + db/71.

    -- ==================== FIZIKA 7 (867 + 868) ========================
    ('fizika','7','fiz-7-olcme',      'Fiziki kəmiyyətlər və ölçmə',         10),
    ('fizika','7','fiz-7-duzxetli',   'Düzxətli hərəkət',                    20),
    ('fizika','7','fiz-7-eyrixetli',  'Əyrixətli hərəkət',                   30),
    ('fizika','7','fiz-7-atom',       'Atomun quruluşu və ölçüsü',           40),
    ('fizika','7','fiz-7-elektrik-sahe', 'Elektrik yükü və elektrik sahəsi', 50),
    ('fizika','7','fiz-7-dovre',      'Elektrik dövrəsi',                    60),
    ('fizika','7','fiz-7-maqnit',     'Sabit maqnit və maqnit sahəsi',       70),

    -- ==================== KIMYA 7 (871 + 872) =========================
    ('kimya','7','kim-7-elementler',  'Kimya nəyi öyrənir. Kimyəvi elementlər', 10),
    ('kimya','7','kim-7-atom',        'Atomun quruluşu',                     20),
    ('kimya','7','kim-7-birlesmeler', 'Kimyəvi birləşmələr',                 30),
    ('kimya','7','kim-7-qarisiqlar',  'Qarışıqlar',                          40),
    ('kimya','7','kim-7-ayrilma',     'Qarışıqların ayrılma üsulları',       50),
    ('kimya','7','kim-7-reaksiyalar', 'Kimyəvi reaksiyalar',                 60),
    ('kimya','7','kim-7-tursu-esas',  'Turşular və əsaslar',                 70),

    -- =================== BIOLOGIYA 7 (863 + 864) ======================
    ('biologiya','7','bio-7-huceyre-orqanizm', 'Hüceyrə və orqanizm',        10),
    ('biologiya','7','bio-7-bitki',       'Bitki orqanizmi',                 20),
    ('biologiya','7','bio-7-coxalma',     'Bitkilərdə çoxalma',              30),
    ('biologiya','7','bio-7-heyvanlar',   'Heyvanların bədən quruluşu',      40),
    ('biologiya','7','bio-7-muxteliflik', 'Bioloji müxtəliflik',             50),
    ('biologiya','7','bio-7-ekosistem',   'Ekosistemlərdə enerji axını',     60),
    ('biologiya','7','bio-7-saglam-heyat','Sağlam həyat tərzi',              70),

    -- =================== COGRAFIYA 7 (922 + 923) ======================
    ('cografiya','7','cog-7-movqe',       'Coğrafi mövqe',                   10),
    ('cografiya','7','cog-7-daxili',      'Yerin daxili prosesləri',         20),
    ('cografiya','7','cog-7-seth',        'Yer səthinin quruluşu',           30),
    ('cografiya','7','cog-7-hava',        'Hava şəraiti',                    40),
    ('cografiya','7','cog-7-iqlim',       'İqlim',                           50),
    ('cografiya','7','cog-7-mesken',      'Məskunlaşma: mağaradan göydələnə',60),
    ('cografiya','7','cog-7-iqtisadi',    'İqtisadi fəaliyyət',              70)
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
   where p.slug = 'orta' and l.code = '7';
  if n < 57 then
    raise exception '7-ci sinif movzulari: 57 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '7'
     group by s.slug) x
   where (x.slug = 'riyaziyyat'   and x.say <> 10)
      or (x.slug = 'az-dili'      and x.say <> 8)
      or (x.slug = 'ingilis-dili' and x.say <> 6)
      or (x.slug = 'informatika'  and x.say <> 5)
      or (x.slug = 'fizika'       and x.say <> 7)
      or (x.slug = 'kimya'        and x.say <> 7)
      or (x.slug = 'biologiya'    and x.say <> 7)
      or (x.slug = 'cografiya'    and x.say <> 7);
  if bad is not null then
    raise exception 'Fenn uzre movzu sayi gozlenilenden ferqlidir: %', bad;
  end if;

  if not exists (
    select 1 from public.program_subjects ps
      join public.programs p on p.id = ps.program_id
      join public.subjects s on s.id = ps.subject_id
     where p.slug = 'orta' and s.slug = 'kimya') then
    raise exception 'Kimya orta proqrama elave olunmayib.';
  end if;

  raise notice '7-ci sinif agaci: % movzu (riy 10, az 8, ing 6, inf 5, fiz 7, kim 7, bio 7, cog 7). Tarix 7 - bax 66/70.', n;
end $$;
