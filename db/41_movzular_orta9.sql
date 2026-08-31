-- =====================================================================
--  41_movzular_orta9.sql : 9-CU SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az mundericatlari (tools/mundericat.py).
--  Yalniz bolme adlari goturulub - derslik metni yox.
--
--  Kitablar:
--    Riyaziyyat 9        507 - 10 bolme
--    Azerbaycan dili 9   875 - tema esasli; qrammatika oxu kurikulum
--                        uzre (murekkeb cumle sintaksisi)
--    Ingilis dili 9      886 - 6 unit
--    Informatika 9       884 - 5 bolme
--    Azerbaycan tarixi 9 877 - 4 bolme (7 fesil, 6 movzuya birlesdirilib)
--    Fizika 9            472 - 4 fesil (6 movzuya bolunub)
--    Kimya 9             505 - 3 bolme (6 movzuya bolunub)
--    Biologiya 9         467 pleyerinde movzu paneli yoxdur; struktur
--                        eyni nesrin 479 (rus dilli) mundericatina uygundur
--    Cografiya 9         881 - 2 bolme + giris (8 movzuya bolunub)
--
--  ON SERT: 37_movzular_orta8.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: bank fayllari, en sonda 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-8-kvadrat-kok') then
    raise exception 'ONCE 37_movzular_orta8.sql isledilmelidir.';
  end if;
end $$;

--  9-cu sinif seviyyesi (kohne bazada yoxdursa yaradilir)
insert into public.levels (program_id, code, name, sort)
select p.id, '9', app.ordinal_az(9) || ' sinif', 90
  from public.programs p
 where p.slug = 'orta'
on conflict (program_id, code) do nothing;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ==================== RIYAZIYYAT 9 (507) ==========================
    ('riyaziyyat','9','riy-9-kok',           'n-ci dərəcədən kök. Rasional üstlü qüvvət', 10),
    ('riyaziyyat','9','riy-9-cevre',         'Çevrə. Bucaqlar və vətərlər',   20),
    ('riyaziyyat','9','riy-9-funksiya',      'Funksiyalar və qrafiklər',      30),
    ('riyaziyyat','9','riy-9-cevre-tenliyi', 'Çevrənin tənliyi. Koordinatlar', 40),
    ('riyaziyyat','9','riy-9-tenlikler',     'Tənliklər və tənliklər sistemi', 50),
    ('riyaziyyat','9','riy-9-coxbucaqli',    'Çoxbucaqlılar',                 60),
    ('riyaziyyat','9','riy-9-berabersizlik', 'Bərabərsizliklər',              70),
    ('riyaziyyat','9','riy-9-vektorlar',     'Vektorlar. Hərəkət',            80),
    ('riyaziyyat','9','riy-9-silsile',       'Ədədi və həndəsi silsilələr',   90),
    ('riyaziyyat','9','riy-9-ehtimal',       'Statistika. Birləşmələr. Ehtimal', 100),
    -- ==================== AZERBAYCAN DILI 9 (875) =====================
    ('az-dili','9','az-9-tabesiz-baglayici', 'Tabesiz mürəkkəb cümlə',        10),
    ('az-dili','9','az-9-tabesiz-mena',      'Tabesiz mürəkkəb cümlədə məna əlaqələri', 20),
    ('az-dili','9','az-9-tabeli-qurulus',    'Tabeli mürəkkəb cümlənin quruluşu', 30),
    ('az-dili','9','az-9-mubteda-xeber-bc',  'Mübtəda və xəbər budaq cümləsi', 40),
    ('az-dili','9','az-9-tamamliq-teyin-bc', 'Tamamlıq və təyin budaq cümləsi', 50),
    ('az-dili','9','az-9-zerflik-bc',        'Zərflik budaq cümlələri',       60),
    ('az-dili','9','az-9-durgu-mc',          'Mürəkkəb cümlədə durğu işarələri', 70),
    ('az-dili','9','az-9-metn-nitq',         'Mətn və nitq mədəniyyəti',      80),
    -- ==================== INGILIS DILI 9 (886) ========================
    ('ingilis-dili','9','ing-9-identity',   'My Language - My Identity',     10),
    ('ingilis-dili','9','ing-9-books',      'Lost in a Book',                20),
    ('ingilis-dili','9','ing-9-traditions', 'Why Do We Do That?',            30),
    ('ingilis-dili','9','ing-9-ambitions',  'The Sky is the Limit',          40),
    ('ingilis-dili','9','ing-9-art',        'Worth a Thousand Words',        50),
    ('ingilis-dili','9','ing-9-skills',     'Shine with the Right Skills',   60),
    -- ==================== INFORMATIKA 9 (884) =========================
    ('informatika','9','inf-9-kodlasdirma',     'Kodlaşdırma. Qrafika və səs', 10),
    ('informatika','9','inf-9-komputer',        'Kompüter və xidməti proqramlar', 20),
    ('informatika','9','inf-9-cedvel',          'Elektron cədvəllər',          30),
    ('informatika','9','inf-9-proqramlasdirma', 'Proqramlaşdırma',             40),
    ('informatika','9','inf-9-texnologiya',     'Qraflar, şəbəkələr və veb',   50),
    -- ==================== AZERBAYCAN TARIXI 9 (877) ===================
    ('tarix','9','tarix-9-xix',         'Azərbaycan XIX yüzillikdə',         10),
    ('tarix','9','tarix-9-xx-evvel',    'Azərbaycan XX yüzilliyin əvvəllərində', 20),
    ('tarix','9','tarix-9-cumhuriyyet', 'Azərbaycan Xalq Cümhuriyyəti',      30),
    ('tarix','9','tarix-9-sovet',       'Azərbaycan SSR (1920-1980-ci illər)', 40),
    ('tarix','9','tarix-9-musteqillik', 'Müstəqilliyin bərpası. 1990-cı illər', 50),
    ('tarix','9','tarix-9-yeni-dovr',   'Yeni minillik. Vətən müharibəsi',   60),
    -- ==================== FIZIKA 9 (472) ==============================
    ('fizika','9','fiz-9-cereyan-muhit', 'Müxtəlif mühitlərdə elektrik cərəyanı', 10),
    ('fizika','9','fiz-9-maqnit-sahe',   'Maqnit sahəsi. Elektromaqnit induksiya', 20),
    ('fizika','9','fiz-9-isiq',          'İşığın yayılması, qayıtması və sınması', 30),
    ('fizika','9','fiz-9-guzgu-linza',   'Güzgülər və linzalar. Göz',         40),
    ('fizika','9','fiz-9-radioaktivlik', 'Radioaktivlik. Atomun quruluşu',    50),
    ('fizika','9','fiz-9-nuve',          'Nüvə reaksiyaları. Nüvə enerjisi',  60),
    -- ==================== KIMYA 9 (505) ===============================
    ('kimya','9','kim-9-metal-umumi',    'Metalların ümumi xarakteristikası', 10),
    ('kimya','9','kim-9-metallar',       'Yarımqrup metalları',               20),
    ('kimya','9','kim-9-halogen-kukurd', 'Halogenlər. Oksigen yarımqrupu',    30),
    ('kimya','9','kim-9-azot-fosfor',    'Azot yarımqrupu. Gübrələr',         40),
    ('kimya','9','kim-9-karbon-silisium','Karbon və silisium yarımqrupları',  50),
    ('kimya','9','kim-9-uzvi',           'Üzvi kimyaya giriş',                60),
    -- ==================== BIOLOGIYA 9 (467/479) =======================
    ('biologiya','9','bio-9-kimyevi-terkib', 'Canlıların kimyəvi tərkibi',    10),
    ('biologiya','9','bio-9-huceyre',        'Hüceyrə - quruluş vahidi',      20),
    ('biologiya','9','bio-9-mubadile',       'Maddələr mübadiləsi. Genetik kod', 30),
    ('biologiya','9','bio-9-bolunme',        'Hüceyrənin bölünməsi: mitoz və meyoz', 40),
    ('biologiya','9','bio-9-coxalma-inkisaf','Çoxalma və fərdi inkişaf',      50),
    ('biologiya','9','bio-9-nov-tekamul',    'Növ, populyasiya və təkamül',   60),
    ('biologiya','9','bio-9-ali-esb',        'Ali əsəb fəaliyyəti',           70),
    ('biologiya','9','bio-9-irsiyyet-muhit', 'İrsiyyət, mühit və sağlamlıq',  80),
    -- ==================== COGRAFIYA 9 (881) ===========================
    ('cografiya','9','cog-9-xerite',       'Coğrafi informasiya. Topoqrafik xəritələr', 10),
    ('cografiya','9','cog-9-relyef',       'Materiklərin relyefi',            20),
    ('cografiya','9','cog-9-iqlim',        'İqlim və Günəş radiasiyası',      30),
    ('cografiya','9','cog-9-sular',        'Daxili sular və Dünya okeanı',    40),
    ('cografiya','9','cog-9-bioehtiyat',   'Bioehtiyatlar və ekoloji siyasət', 50),
    ('cografiya','9','cog-9-sivilizasiya', 'Sivilizasiyalar və regionlar',    60),
    ('cografiya','9','cog-9-ehali',        'Dünya əhalisi',                   70),
    ('cografiya','9','cog-9-iqtisadiyyat', 'İqtisadi-sosial həyat',           80)
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
   where p.slug = 'orta' and l.code = '9';
  if n < 63 then
    raise exception '9-cu sinif movzulari: 63 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '9'
     group by s.slug) x
   where (x.slug = 'riyaziyyat'   and x.say <> 10)
      or (x.slug = 'az-dili'      and x.say <> 8)
      or (x.slug = 'ingilis-dili' and x.say <> 6)
      or (x.slug = 'informatika'  and x.say <> 5)
      or (x.slug = 'tarix'        and x.say <> 6)
      or (x.slug = 'fizika'       and x.say <> 6)
      or (x.slug = 'kimya'        and x.say <> 6)
      or (x.slug = 'biologiya'    and x.say <> 8)
      or (x.slug = 'cografiya'    and x.say <> 8);
  if bad is not null then
    raise exception 'Fenn uzre movzu sayi gozlenilenden ferqlidir: %', bad;
  end if;

  raise notice '9-cu sinif agaci: % movzu (riy 10, az 8, ing 6, inf 5, tarix 6, fiz 6, kim 6, bio 8, cog 8).', n;
end $$;
