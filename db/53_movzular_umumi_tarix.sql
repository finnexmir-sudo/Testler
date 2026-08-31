-- =====================================================================
--  53_movzular_umumi_tarix.sql : UMUMI TARIX FENNI VE MOVZU AGACI
--
--  Azerbaycan mektebinde tarix IKI ayri kursdur: "Azerbaycan tarixi"
--  ve "Umumi tarix" - ayri derslik, ayri qiymet.  Banada da ayri fenn
--  olmalidir ki, muellim "Tarix 11" secende dunya tarixi qarismasin.
--
--  Ona gore burada YENI fenn acilir: 'umumi-tarix'.
--  Movcud 'tarix' fenni oz movzulari ile toxunulmaz qalir - 41 ve 49
--  fayllarinin oz-ozunu yoxlamasi ("tarix = 6 movzu") pozulmur.
--
--  Sinif bolgusu kurikuluma uygundur:
--    9-cu sinif   XIX esr - XX esrin evveli (senaye cevrilisinden
--                 Birinci Dunya muharibesine qeder)
--    11-ci sinif  XX-XXI esrler (Versal sistemindən qloballasmaya)
--  10-cu sinifin dunya tarixi (qedim dovrden XVIII esre qeder) artiq
--  45_movzular_orta10.sql-de 'tarix' fenni altindadir - orada qalir.
--
--  ON SERT: 49_movzular_orta11.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: 54_bank_tarix_umumi.sql, 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s on s.id = t.subject_id
     where s.slug = 'tarix' and t.slug = 'tarix-11-zefer') then
    raise exception 'ONCE 49_movzular_orta11.sql isledilmelidir.';
  end if;
end $$;

-- ------------------------------------------------------------- fenn
--  sort = 95: siyahida "Tarix" (90) ile "Cografiya" (100) arasinda
insert into public.subjects (slug, name, sort) values
  ('umumi-tarix', 'Ümumi tarix', 95)
on conflict (slug) do update set name = excluded.name, sort = excluded.sort;

insert into public.program_subjects (program_id, subject_id)
select p.id, s.id from public.programs p, public.subjects s
 where s.slug = 'umumi-tarix' and p.slug in ('orta', 'buraxilis')
on conflict do nothing;

-- ---------------------------------------------------------- movzular
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    -- ==================== 9-CU SINIF: XIX ESR =========================
    ('9',  'utarix-9-senaye',      'Sənaye çevrilişi və cəmiyyət',        10),
    ('9',  'utarix-9-napoleon',    'Fransa inqilabı və Napoleon dövrü',   20),
    ('9',  'utarix-9-birlesme',    'İtaliya və Almaniyanın birləşməsi',   30),
    ('9',  'utarix-9-abs',         'ABŞ XIX əsrdə. Vətəndaş müharibəsi',  40),
    ('9',  'utarix-9-serq',        'Şərq ölkələri və müstəmləkəçilik',    50),
    ('9',  'utarix-9-birinci',     'Birinci Dünya müharibəsi',            60),
    -- ==================== 11-CI SINIF: XX-XXI ESR =====================
    ('11', 'utarix-11-versal',     'Versal-Vaşinqton sistemi',            10),
    ('11', 'utarix-11-bohran',     'Dünya iqtisadi böhranı. Totalitarizm',20),
    ('11', 'utarix-11-ikinci',     'İkinci Dünya müharibəsi',             30),
    ('11', 'utarix-11-soyuq',      'Soyuq müharibə',                      40),
    ('11', 'utarix-11-mustemleke', 'Müstəmləkə sisteminin dağılması',     50),
    ('11', 'utarix-11-muasir',     'Müasir dünya. Qloballaşma',           60)
  ) as v(sinif, slug, name, sort)
  join public.subjects s on s.slug = 'umumi-tarix'
  join public.programs p on p.slug = 'orta'
  join public.levels   l on l.program_id = p.id and l.code = v.sinif
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ------------------------------------------------------- oz yoxlamasi
do $$
declare n int; n9 int; n11 int;
begin
  select count(*) into n from public.topics t
    join public.subjects s on s.id = t.subject_id
   where s.slug = 'umumi-tarix';
  if n <> 12 then
    raise exception 'Umumi tarix movzulari: 12 gozlenilirdi, % tapildi', n;
  end if;

  select count(*) into n9 from public.topics t
    join public.subjects s on s.id = t.subject_id
    join public.levels   l on l.id = t.level_id
   where s.slug = 'umumi-tarix' and l.code = '9';
  select count(*) into n11 from public.topics t
    join public.subjects s on s.id = t.subject_id
    join public.levels   l on l.id = t.level_id
   where s.slug = 'umumi-tarix' and l.code = '11';
  if n9 <> 6 or n11 <> 6 then
    raise exception 'Sinif uzre bolgu sehvdir: 9=%, 11=%', n9, n11;
  end if;

  --  "Tarix" fenninin movzulari toxunulmamis qalmalidir
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'tarix' and l.code = '11') <> 6 then
    raise exception 'Tarix 11 movzulari deyisib - bu fayl ona toxunmamalidir.';
  end if;

  raise notice 'Umumi tarix fenni: % movzu (9-cu sinif 6, 11-ci sinif 6).', n;
end $$;
