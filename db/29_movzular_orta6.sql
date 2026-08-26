-- =====================================================================
--  29_movzular_orta6.sql : 6-CI SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az mundericatlari (tools/mundericat.py).
--  Yalniz bolme adlari goturulub - derslik metni yox.
--
--  Kitablar:
--    Riyaziyyat 6        906 + 907 - 9 bolme
--    Azerbaycan dili 6   903 + 904 - tema esasli, qrammatika oxu
--    Ingilis dili 6      916 (esas xarici dil) - 8 unit
--    Informatika 6       912 - 5 bolme
--    Azerbaycan tarixi 6 910 - 3 bolme
--    Fizika 6            546 - 4 bolme (fenn 6-da baslayir)
--    Biologiya 6         538 - 8 fesil (fenn 6-da baslayir)
--    Cografiya 6         859 + 860 - 7 bolme (fenn 6-da baslayir)
--
--  ON SERT: 25_movzular_orta5.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: bank fayllari, en sonda 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-5-faiz') then
    raise exception 'ONCE 25_movzular_orta5.sql isledilmelidir.';
  end if;
end $$;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ================== RIYAZIYYAT 6 (906 + 907) ======================
    ('riyaziyyat','6','riy-6-natural-ededler', 'Natural ədədlər və əməllər',      10),
    ('riyaziyyat','6','riy-6-nisbet-faiz',     'Nisbət. Tənasüb. Faiz',           20),
    ('riyaziyyat','6','riy-6-tam-ededler',     'Tam ədədlər',                     30),
    ('riyaziyyat','6','riy-6-koordinat',       'Düzbucaqlı koordinat sistemi',    40),
    ('riyaziyyat','6','riy-6-coxluqlar',       'Çoxluqlar',                       50),
    ('riyaziyyat','6','riy-6-ifade-tenlik',    'Dəyişənli ifadələr. Tənlik. Bərabərsizlik', 60),
    ('riyaziyyat','6','riy-6-ucbucaqlar',      'Üçbucaqlar',                      70),
    ('riyaziyyat','6','riy-6-sahe-hecm',       'Fiqurların sahəsi və həcmi',      80),
    ('riyaziyyat','6','riy-6-statistika',      'Statistika və ehtimal',           90),

    -- ============ AZERBAYCAN DILI 6 (903 + 904, qrammatika oxu) =======
    ('az-dili','6','az-6-fonetika',      'Fonetika: səsdüşümü, səsartımı, tələffüz', 10),
    ('az-dili','6','az-6-yazi',          'Alınma və mürəkkəb sözlərin yazılışı', 20),
    ('az-dili','6','az-6-soz-luget',     'Sözün başlanğıc forması. Eyniköklü sözlər', 30),
    ('az-dili','6','az-6-isim-hal',      'İsim: hallar və mənsubiyyət',      40),
    ('az-dili','6','az-6-qosma-baglayici','Qoşma və bağlayıcılar',           50),
    ('az-dili','6','az-6-say-numerativ', 'Say və numerativ sözlər',          60),
    ('az-dili','6','az-6-cumle-uzvleri', 'Tamamlıq, təyin, zərflik',         70),
    ('az-dili','6','az-6-soz-sirasi',    'Söz sırası. Söz birləşmələri',     80),

    -- ================== INGILIS DILI 6 (916) ==========================
    ('ingilis-dili','6','ing-6-town',     'Unit 1. About Town',              10),
    ('ingilis-dili','6','ing-6-food',     'Unit 2. Delicious Diversity',     20),
    ('ingilis-dili','6','ing-6-holiday',  'Unit 3. What a Holiday!',         30),
    ('ingilis-dili','6','ing-6-stories',  'Unit 4. We all have a story',     40),
    ('ingilis-dili','6','ing-6-journeys', 'Unit 5. Incredible Journeys',     50),
    ('ingilis-dili','6','ing-6-heroes',   'Unit 6. Heroes Make a Difference',60),
    ('ingilis-dili','6','ing-6-ideas',    'Unit 7. Great Ideas',             70),
    ('ingilis-dili','6','ing-6-nature',   'Unit 8. Our Natural World',       80),

    -- ================== INFORMATIKA 6 (912) ===========================
    ('informatika','6','inf-6-kompyuter',       'Kompüter',                  10),
    ('informatika','6','inf-6-proqram-teminati','Proqram təminatı',          20),
    ('informatika','6','inf-6-alqoritm',        'Alqoritm',                  30),
    ('informatika','6','inf-6-proqramlasdirma', 'Proqramlaşdırma',           40),
    ('informatika','6','inf-6-internet',        'İnternet',                  50),

    -- ============== AZERBAYCAN TARIXI 6 (910) =========================
    ('tarix','6','tarix-6-ibtidai',          'Azərbaycanda ibtidai cəmiyyət', 10),
    ('tarix','6','tarix-6-qedim-dovletler',  'Azərbaycanda qədim dövlətlər',  20),
    ('tarix','6','tarix-6-manna',            'Manna dövləti',                 22),
    ('tarix','6','tarix-6-atropatena',       'Atropatena dövləti',            24),
    ('tarix','6','tarix-6-albaniya',         'Albaniya dövləti',              26),
    ('tarix','6','tarix-6-erken-orta',       'Azərbaycan III–VI yüzilliklərdə', 30),

    -- ==================== FIZIKA 6 (546) ==============================
    ('fizika','6','fiz-6-giris',    'Fizika nəyi öyrənir',                   10),
    ('fizika','6','fiz-6-olcmeler', 'Fiziki kəmiyyətlər və ölçmələr',        15),
    ('fizika','6','fiz-6-materiya', 'Materiya',                              20),
    ('fizika','6','fiz-6-madde',    'Maddə və onun xassələri',               30),
    ('fizika','6','fiz-6-hereket',  'Qarşılıqlı təsirlər və hərəkət',        40),
    ('fizika','6','fiz-6-enerji',   'Mexaniki hərəkət, cərəyan və enerji',   50),

    -- =================== BIOLOGIYA 6 (538) ============================
    ('biologiya','6','bio-6-tedqiqat',        'Biologiyanın tədqiqat obyektləri', 10),
    ('biologiya','6','bio-6-huceyre',         'Hüceyrə, toxuma və orqanlar',  20),
    ('biologiya','6','bio-6-vegetativ',       'Bitkilərin vegetativ orqanları', 30),
    ('biologiya','6','bio-6-generativ',       'Bitkilərin generativ orqanları', 40),
    ('biologiya','6','bio-6-hereket-qida',    'Hərəkət, dayaq, qidalanma, tənəffüs', 50),
    ('biologiya','6','bio-6-dasinma-coxalma', 'Maddələrin daşınması, çoxalma', 60),
    ('biologiya','6','bio-6-muhit',           'Orqanizm və mühit',            70),
    ('biologiya','6','bio-6-rol',             'Bitki və heyvanların rolu',    80),

    -- ================= COGRAFIYA 6 (859 + 860) ========================
    ('cografiya','6','cog-6-mekan',    'Məkanı tanıyaq',                     10),
    ('cografiya','6','cog-6-beledci',  'Məkanın bələdçisi: plan və xəritə',  20),
    ('cografiya','6','cog-6-col',      'Çöl tədqiqatı',                      30),
    ('cografiya','6','cog-6-kainat',   'Kainatı seyr edirəm',                40),
    ('cografiya','6','cog-6-tebiet',   'Təbiəti kəşf edirəm',                50),
    ('cografiya','6','cog-6-yurdumuz', 'Yurdumuzun təbiətinə səyahət',       60),
    ('cografiya','6','cog-6-dunya',    'Dünya bizim evimizdir',              70)
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
   where p.slug = 'orta' and l.code = '6';
  if n < 57 then
    raise exception '6-ci sinif movzulari: 57 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '6'
     group by s.slug) x
   where (x.slug = 'riyaziyyat'   and x.say <> 9)
      or (x.slug = 'az-dili'      and x.say <> 8)
      or (x.slug = 'ingilis-dili' and x.say <> 8)
      or (x.slug = 'informatika'  and x.say <> 5)
      or (x.slug = 'tarix'        and x.say <> 6)
      or (x.slug = 'fizika'       and x.say <> 6)
      or (x.slug = 'biologiya'    and x.say <> 8)
      or (x.slug = 'cografiya'    and x.say <> 7);
  if bad is not null then
    raise exception 'Fenn uzre movzu sayi gozlenilenden ferqlidir: %', bad;
  end if;

  raise notice '6-ci sinif agaci: % movzu (riy 9, az 8, ing 8, inf 5, tarix 6, fiz 6, bio 8, cog 7).', n;
end $$;
