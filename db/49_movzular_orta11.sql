-- =====================================================================
--  49_movzular_orta11.sql : 11-CI SINIF (ORTA MEKTEB) MOVZU AGACI
--
--  Menbe:  e-derslik.edu.az mundericatlari (tools/mundericat.py).
--  Yalniz bolme adlari goturulub - derslik metni yox.
--
--  Kitablar:
--    Riyaziyyat 11       817 - 10 bolme
--    Azerbaycan dili 11  812 - tema esasli; qrammatika oxu kurikulum
--                        uzre (umumi tekrar ve derinlesdirme)
--    Ingilis dili 11     805 - 6 unit
--    Informatika 11      822 - 6 bolme (5 movzuya birlesdirilib)
--    Azerbaycan tarixi 11 807 - 4 bolme (6 movzuya bolunub)
--    Fizika 11           282 - 4 fesil (6 movzuya bolunub)
--    Kimya 11            349 - 3 hisse (6 movzuya bolunub)
--    Biologiya 11        276 - 7 bolme (8 movzuya bolunub)
--    Cografiya 11        814 - 6 bolme (8 movzuya bolunub)
--
--  ON SERT: 45_movzular_orta10.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: bank fayllari, en sonda 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-10-funksiya') then
    raise exception 'ONCE 45_movzular_orta10.sql isledilmelidir.';
  end if;
end $$;

--  11-ci sinif seviyyesi (kohne bazada yoxdursa yaradilir)
insert into public.levels (program_id, code, name, sort)
select p.id, '11', app.ordinal_az(11) || ' sinif', 110
  from public.programs p
 where p.slug = 'orta'
on conflict (program_id, code) do nothing;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ==================== RIYAZIYYAT 11 (817) =========================
    ('riyaziyyat','11','riy-11-coxhedli',       'Çoxhədlilər. Kompleks ədədlər', 10),
    ('riyaziyyat','11','riy-11-feza-vektor',    'Fəzada vektorlar və koordinatlar', 20),
    ('riyaziyyat','11','riy-11-limit',          'Limit və kəsilməzlik',        30),
    ('riyaziyyat','11','riy-11-firlanma',       'Silindr, konus, kürə. Səthlər', 40),
    ('riyaziyyat','11','riy-11-toreme',         'Funksiyanın törəməsi',        50),
    ('riyaziyyat','11','riy-11-firlanma-hecm',  'Fırlanma fiqurlarının həcmi', 60),
    ('riyaziyyat','11','riy-11-arasdirma',      'Törəmə ilə funksiyanın araşdırılması', 70),
    ('riyaziyyat','11','riy-11-inteqral',       'İnteqral',                    80),
    ('riyaziyyat','11','riy-11-statistika',     'Statistik göstəricilər. Ehtimal', 90),
    ('riyaziyyat','11','riy-11-tenlikler',      'İrrasional, üstlü, loqarifmik tənliklər', 100),
    -- ==================== AZERBAYCAN DILI 11 (812) ====================
    ('az-dili','11','az-11-fonetika-leksika', 'Fonetika və leksika: ümumi təkrar', 10),
    ('az-dili','11','az-11-soz-yaradiciligi', 'Söz yaradıcılığı',            20),
    ('az-dili','11','az-11-morfologiya-d',    'Morfologiya: dərinləşdirilmiş təhlil', 30),
    ('az-dili','11','az-11-sintaksis-d',      'Sintaksis: dərinləşdirilmiş təhlil', 40),
    ('az-dili','11','az-11-murekkeb-t',       'Mürəkkəb cümlə: təkrar',      50),
    ('az-dili','11','az-11-uslubiyyat',       'Üslubiyyat və redaktə',       60),
    ('az-dili','11','az-11-metn-tehlili',     'Mətn təhlili',                70),
    ('az-dili','11','az-11-isguzar',          'Nitq mədəniyyəti. İşgüzar sənədlər', 80),
    -- ==================== INGILIS DILI 11 (805) =======================
    ('ingilis-dili','11','ing-11-whys',         'The Whys and Wherefores',   10),
    ('ingilis-dili','11','ing-11-experiences',  'Lifetime Experiences',      20),
    ('ingilis-dili','11','ing-11-conversation', 'The Art of Conversation',   30),
    ('ingilis-dili','11','ing-11-regrets',      'No Regrets',                40),
    ('ingilis-dili','11','ing-11-creativity',   'Creativity',                50),
    ('ingilis-dili','11','ing-11-news',         'In the News',               60),
    -- ==================== INFORMATIKA 11 (822) ========================
    ('informatika','11','inf-11-sistemler',     'İnformasiya sistemləri. Süni intellekt', 10),
    ('informatika','11','inf-11-modellesdirme', 'Kompüter modelləşdirməsi',  20),
    ('informatika','11','inf-11-baza-layihe',   'Verilənlər bazası layihəsi', 30),
    ('informatika','11','inf-11-sebeke-tex',    'Şəbəkə və mobil texnologiyalar', 40),
    ('informatika','11','inf-11-komputer-veb',  'Kompüterin idarə edilməsi. Veb-layihə', 50),
    -- ==================== AZERBAYCAN TARIXI 11 (807) ==================
    ('tarix','11','tarix-11-isgal',       'Şimali Azərbaycanın işğalı',      10),
    ('tarix','11','tarix-11-mustemleke',  'Müstəmləkə dövrü. Milli oyanış',  20),
    ('tarix','11','tarix-11-cumhuriyyet', 'Birinci respublika - AXC',        30),
    ('tarix','11','tarix-11-sovet',       'İkinci respublika - Azərbaycan SSR', 40),
    ('tarix','11','tarix-11-musteqillik', 'Üçüncü respublika. 1990-cı illər', 50),
    ('tarix','11','tarix-11-zefer',       'Yeni minillik. Böyük Zəfər',      60),
    -- ==================== FIZIKA 11 (282) =============================
    ('fizika','11','fiz-11-elektrostatika',   'Elektrostatika. Kondensator', 10),
    ('fizika','11','fiz-11-maqnit-induksiya', 'Maqnit sahəsi. İnduksiya qanunları', 20),
    ('fizika','11','fiz-11-cereyan-qanunlari','Sabit cərəyan qanunları',     30),
    ('fizika','11','fiz-11-em-reqs',          'Elektromaqnit rəqsləri və dalğaları', 40),
    ('fizika','11','fiz-11-optika',           'İşığın dalğa təbiəti',        50),
    ('fizika','11','fiz-11-atom',             'Atom və nüvə fizikası',       60),
    -- ==================== KIMYA 11 (349) ==============================
    ('kimya','11','kim-11-spirtler',      'Spirtlər və fenollar',            10),
    ('kimya','11','kim-11-aldehid-tursu', 'Aldehidlər və karbon turşuları',  20),
    ('kimya','11','kim-11-efir-yag',      'Mürəkkəb efirlər. Yağlar',        30),
    ('kimya','11','kim-11-karbohidrat',   'Karbohidratlar',                  40),
    ('kimya','11','kim-11-azotlu',        'Azotlu üzvi birləşmələr',         50),
    ('kimya','11','kim-11-polimer',       'İrimolekullu birləşmələr',        60),
    -- ==================== BIOLOGIYA 11 (276) ==========================
    ('biologiya','11','bio-11-heyatin-yaranmasi', 'Həyatın yaranması',       10),
    ('biologiya','11','bio-11-bakteriyalar',      'Mikrobiologiya: bakteriyalar', 20),
    ('biologiya','11','bio-11-viruslar',          'Mikrobiologiya: viruslar', 30),
    ('biologiya','11','bio-11-seleksiya',         'Seleksiya',               40),
    ('biologiya','11','bio-11-biotexnologiya',    'Biotexnologiya və bionika', 50),
    ('biologiya','11','bio-11-biosfer',           'Biosfer',                 60),
    ('biologiya','11','bio-11-insan-muhit',       'İnsan, onun inkişafı və mühit', 70),
    ('biologiya','11','bio-11-bolunme-nezaret',   'Nəzarətli və nəzarətsiz bölünmə', 80),
    -- ==================== COGRAFIYA 11 (814) ==========================
    ('cografiya','11','cog-11-xerite-cis',      'Xəritə - coğrafi informasiya vasitəsi', 10),
    ('cografiya','11','cog-11-tebii-ehtiyat',   'Təbiətdən səmərəli istifadə', 20),
    ('cografiya','11','cog-11-demoqrafiya',     'Dünyanın demoqrafik mənzərəsi', 30),
    ('cografiya','11','cog-11-iqtisadi-inkisaf','İqtisadi inkişafın istiqamətləri', 40),
    ('cografiya','11','cog-11-enerji-erzaq',    'Enerji və ərzaq problemləri', 50),
    ('cografiya','11','cog-11-ekoloji-qlobal',  'Qlobal ekoloji problemlər', 60),
    ('cografiya','11','cog-11-inteqrasiya',     'Beynəlxalq inteqrasiya',    70),
    ('cografiya','11','cog-11-qloballasma',     'Qloballaşma',               80)
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
   where p.slug = 'orta' and l.code = '11';
  if n < 63 then
    raise exception '11-ci sinif movzulari: 63 gozlenilirdi, % tapildi', n;
  end if;

  select string_agg(x.slug || '=' || x.say, ', ') into bad from (
    select s.slug, count(*) say
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      join public.levels l on l.id = t.level_id
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = '11'
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

  raise notice '11-ci sinif agaci: % movzu (riy 10, az 8, ing 6, inf 5, tarix 6, fiz 6, kim 6, bio 8, cog 8).', n;
end $$;
