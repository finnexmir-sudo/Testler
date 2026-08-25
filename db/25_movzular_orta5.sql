-- =====================================================================
--  25_movzular_orta5.sql : 5-CI SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az - Tehsil Nazirliyinin resmi elektron
--          derslik portali.  Kitablarin MUNDERICATI (bolme adlari)
--          goturulub - derslik metni, calismalar, sekiller YOX.
--          Yigan skript: tools/mundericat.py -> mundericat/*.txt
--
--  Kitablar:
--    Riyaziyyat 5        840 (I hisse) + 841 (II hisse) - 8 bolme
--    Azerbaycan dili 5   837 + 838 - derslik MOVZUYA (temaya) gore
--                        bolunub, qrammatika derslerin ICINDEDIR;
--                        test banki ucun qrammatika oxu cixarilib
--                        (14_movzular.sql-deki istisna qaydasi ile)
--    Ingilis dili 5      850 (esas xarici dil) - 8 unit
--    Informatika 5       846 - 5 bolme
--    Azerbaycan tarixi 5 844 - 5 bolme
--
--  Fizika, kimya, biologiya, cografiya 5-ci sinifde kecilmir -
--  onlarin agaci oz sinfinde (6+) elave olunacaq.
--
--  ON SERT: 04_seed.sql ve 14_movzular.sql islenmis olmalidir.
--  Tekrar isledile biler (on conflict do update / do nothing).
--  SONRA: bank fayllari (26, 27), en sonda 05_grants.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
--  0. ON SERT
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from public.topics) then
    raise exception 'ONCE 04_seed.sql ve 14_movzular.sql isledilmelidir (movzu cedveli bosdur).';
  end if;
  if not exists (select 1 from public.programs where slug = 'orta') then
    raise exception 'ONCE 04_seed.sql isledilmelidir (orta proqrami yoxdur).';
  end if;
end $$;

-- ---------------------------------------------------------------------
--  1. SEVIYYELER (04_seed qelibi ile, tekrara davamli)
--     04_seed artiq 5-8 sinifleri yaradir; kohne bazada catismirsa
--     burada tamamlanir.
-- ---------------------------------------------------------------------
insert into public.levels (program_id, code, name, sort)
select p.id, g::text, app.ordinal_az(g) || ' sinif', g * 10
  from public.programs p, generate_series(5, 8) g
 where p.slug = 'orta'
on conflict (program_id, code) do nothing;

--  Orta mektebde kecilen fennler (04_seed ile eyni siyahi)
insert into public.program_subjects (program_id, subject_id)
select p.id, s.id from public.programs p, public.subjects s
 where p.slug = 'orta'
   and s.slug in ('riyaziyyat','az-dili','ingilis-dili','informatika',
                  'fizika','biologiya','tarix','cografiya')
on conflict do nothing;

-- ---------------------------------------------------------------------
--  2. AGAC  (e-derslik bolmeleri)
-- ---------------------------------------------------------------------
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ================== RIYAZIYYAT 5 (840 + 841) ======================
    ('riyaziyyat','5','riy-5-natural-ededler',  'Natural ədədlər və əməllər',      10),
    ('riyaziyyat','5','riy-5-adi-kesrler',      'Adi kəsrlər',                     20),
    ('riyaziyyat','5','riy-5-onluq-kesrler',    'Onluq kəsrlər',                   30),
    ('riyaziyyat','5','riy-5-faiz',             'Faiz',                            40),
    ('riyaziyyat','5','riy-5-ifade-tenlik',     'Dəyişənli ifadələr. Tənlik. Bərabərsizlik', 50),
    ('riyaziyyat','5','riy-5-mustevi-fiqurlar', 'Müstəvi fiqurlar',                60),
    ('riyaziyyat','5','riy-5-feza-fiqurlari',   'Fəza fiqurları',                  70),
    ('riyaziyyat','5','riy-5-statistika',       'Statistika və məlumatların təsviri', 80),

    -- ============ AZERBAYCAN DILI 5 (837 + 838, qrammatika oxu) =======
    ('az-dili','5','az-5-fonetika',      'Fonetika: saitlərin və samitlərin yazılışı', 10),
    ('az-dili','5','az-5-soz-menasi',    'Sözün mənası. Omonimlər',          20),
    ('az-dili','5','az-5-soz-qurulusu',  'Kök və şəkilçi. Sözün quruluşu',   30),
    ('az-dili','5','az-5-luget',         'Sinonim, antonim, alınma sözlər',  40),
    ('az-dili','5','az-5-isim',          'İsim',                             50),
    ('az-dili','5','az-5-sifet-say-feil','Sifət, say, feil, zərf',           60),
    ('az-dili','5','az-5-evezlik-tesrif','Təsriflənməyən feillər. Əvəzlik',  70),
    ('az-dili','5','az-5-cumle',         'Söz birləşmələri. Cümlə',          80),

    -- ================== INGILIS DILI 5 (850) ==========================
    ('ingilis-dili','5','ing-5-who-am-i',   'Unit 1. Who am I?',              10),
    ('ingilis-dili','5','ing-5-everywhere', 'Unit 2. English Everywhere',     20),
    ('ingilis-dili','5','ing-5-home',       'Unit 3. Where is home?',         30),
    ('ingilis-dili','5','ing-5-family',     'Unit 4. Family Matters',         40),
    ('ingilis-dili','5','ing-5-daily-life', 'Unit 5. A Day in the Life',      50),
    ('ingilis-dili','5','ing-5-school',     'Unit 6. School Time',            60),
    ('ingilis-dili','5','ing-5-clothes',    'Unit 7. What is he wearing?',    70),
    ('ingilis-dili','5','ing-5-movement',   'Unit 8. Get Moving!',            80),

    -- ================== INFORMATIKA 5 (846) ===========================
    ('informatika','5','inf-5-informasiya', 'İnformasiya',                    10),
    ('informatika','5','inf-5-kompyuter',   'Kompüter',                       20),
    ('informatika','5','inf-5-tetbiqi',     'Tətbiqi proqramlar',             30),
    ('informatika','5','inf-5-alqoritm',    'Alqoritm və proqram',            40),
    ('informatika','5','inf-5-internet',    'İnternet',                       50),

    -- ============== AZERBAYCAN TARIXI 5 (844) =========================
    ('tarix','5','tarix-5-qedim',      'Qədim Azərbaycan',                   10),
    ('tarix','5','tarix-5-dovletler',  'Azərbaycan dövlətləri',              20),
    ('tarix','5','tarix-5-qalalar',    'Qalalar və şəhərlər',                30),
    ('tarix','5','tarix-5-respublika', 'Azərbaycan respublikaları',          40),
    ('tarix','5','tarix-5-medeniyyet', 'Mədəniyyət inciləri',                50)
  ) as v(fenn, sinif, slug, name, sort)
  join public.subjects s on s.slug = v.fenn
  join public.programs p on p.slug = 'orta'
  join public.levels   l on l.program_id = p.id and l.code = v.sinif
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      level_id = excluded.level_id;

-- ---------------------------------------------------------------------
--  3. OZUNU YOXLAMA
-- ---------------------------------------------------------------------
do $$
declare n int; bad text;
begin
  select count(*) into n
    from public.topics t
    join public.levels l on l.id = t.level_id
    join public.programs p on p.id = l.program_id
   where p.slug = 'orta' and l.code = '5';
  if n < 34 then
    raise exception '5-ci sinif movzulari: 34 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '5'
     group by s.slug) x
   where (x.slug = 'riyaziyyat'   and x.say <> 8)
      or (x.slug = 'az-dili'      and x.say <> 8)
      or (x.slug = 'ingilis-dili' and x.say <> 8)
      or (x.slug = 'informatika'  and x.say <> 5)
      or (x.slug = 'tarix'        and x.say <> 5);
  if bad is not null then
    raise exception 'Fenn uzre movzu sayi gozlenilenden ferqlidir: %', bad;
  end if;

  raise notice '5-ci sinif agaci: % movzu (riy 8, az 8, ing 8, inf 5, tarix 5).', n;
end $$;
