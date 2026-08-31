-- =====================================================================
--  66_movzular_umumi_tarix6_8.sql : UMUMI TARIX 6, 7, 8-CI SINIF
--
--  53_movzular_umumi_tarix.sql 9 ve 11-ci sinfi acmisdi.  Burada
--  kurikulumun qalan uc pillesi elave olunur:
--    6-ci sinif   Qedim dunya tarixi (ibtidai icmadan Romaya qeder)
--    7-ci sinif   Orta esrler tarixi (III-XV esrler)
--    8-ci sinif   Yeni dovr, birinci hisse (XVI-XVIII esrler)
--  9-cu sinif XIX esr, 11-ci sinif XX-XXI esrler artiq 53-dedir.
--
--  DIQQET:  'tarix' fenni (Azerbaycan tarixi) 6, 7, 8-ci sinifde
--  oz movzulari ile toxunulmaz qalir - mektebde de iki ayri kursdur.
--  10-cu sinifin dunya tarixi hele de 'tarix' fenni altindadir
--  (45_movzular_orta10.sql) - onun kocurulmesi AYRI addimdir.
--
--  ON SERT: 53_movzular_umumi_tarix.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: 67_bank_tarix_umumi6_8.sql, 05_grants.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'umumi-tarix' and t.slug = 'utarix-11-muasir') then
    raise exception 'ONCE 53_movzular_umumi_tarix.sql isledilmelidir.';
  end if;
  if (select count(*) from public.levels
       where code in ('6', '7', '8')) <> 3 then
    raise exception 'Kataloqda 6-8 sinifleri tek olmalidir '
                    '(57_sinif_dubli.sql isledilibmi?).';
  end if;
end $$;

-- -------------------------------------------------- 6-ci sinif (qedim)
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('utarix-6-ibtidai',      'İbtidai icma quruluşu',            10),
    ('utarix-6-mesopotamiya', 'Qədim Mesopotamiya və Misir',      20),
    ('utarix-6-serq',         'Qədim Hindistan, Çin və İran',     30),
    ('utarix-6-yunanistan',   'Qədim Yunanıstan',                 40),
    ('utarix-6-roma',         'Qədim Roma',                       50),
    ('utarix-6-medeniyyet',   'Qədim dünya mədəniyyəti',          60)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'umumi-tarix'
  join public.levels   l on l.code = '6'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- --------------------------------------------- 7-ci sinif (orta esrler)
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('utarix-7-erken',      'Erkən orta əsrlər: Bizans və franklar', 10),
    ('utarix-7-ereb',       'Ərəb xilafəti və İslam dünyası',        20),
    ('utarix-7-feodal',     'Feodal cəmiyyəti və orta əsr şəhərləri', 30),
    ('utarix-7-serq',       'Orta əsrlərdə Hindistan, Çin, Yaponiya', 40),
    ('utarix-7-avropa',     'Orta əsrlərdə Avropa dövlətləri',       50),
    ('utarix-7-medeniyyet', 'Orta əsrlər mədəniyyəti',               60)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'umumi-tarix'
  join public.levels   l on l.code = '7'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ----------------------------------------------- 8-ci sinif (yeni dovr)
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('utarix-8-kesf',        'Böyük coğrafi kəşflər',              10),
    ('utarix-8-intibah',     'İntibah və Reformasiya',             20),
    ('utarix-8-inqilablar',  'Niderland və İngiltərə inqilabları',  30),
    ('utarix-8-maarifcilik', 'Maarifçilik dövrü',                  40),
    ('utarix-8-abs-fransa',  'ABŞ-ın yaranması və Fransa inqilabı', 50),
    ('utarix-8-serq',        'XVI-XVIII əsrlərdə Şərq ölkələri',   60)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'umumi-tarix'
  join public.levels   l on l.code = '8'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ------------------------------------------------------- oz yoxlamasi
do $$
declare n int;
begin
  select count(*) into n from public.topics t
    join public.subjects s on s.id = t.subject_id
    join public.levels   l on l.id = t.level_id
   where s.slug = 'umumi-tarix' and l.code in ('6', '7', '8');
  if n <> 18 then
    raise exception 'Umumi tarix 6-8 movzulari: 18 gozlenilirdi, % tapildi', n;
  end if;

  --  9 ve 11-ci sinfe toxunulmamalidir
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'umumi-tarix' and l.code in ('9', '11')) <> 12 then
    raise exception 'Umumi tarix 9/11 movzulari deyisib - bu fayl ona toxunmamalidir.';
  end if;
  --  Azerbaycan tarixi 6-8 movzulari da toxunulmamalidir
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'tarix' and l.code in ('6', '7', '8')) < 3 then
    raise exception 'Azerbaycan tarixi 6-8 movzulari itib - bu fayl ona toxunmamalidir.';
  end if;

  raise notice 'Umumi tarix: 6, 7, 8-ci sinif ucun % movzu acildi.', n;
end $$;
