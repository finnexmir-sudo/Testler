-- =====================================================================
--  58_movzular_edebiyyat9_10.sql : EDEBIYYAT 9 ve 10-CU SINIF MOVZULARI
--
--  Menbe:  e-derslik.edu.az mundericati (tools/mundericat.py)
--          Edebiyyat 9  - kitab id 883 (4 bolme, 44 movzu)
--          Edebiyyat 10 - kitab id 732 (6 dovr bolmesi, 39 movzu)
--  Yalniz bolme ve movzu adlari goturulub - dersliyin BEDII METNI,
--  calisma ve suallari YOX (muellif huququ).
--
--  Bolgu dersliyin OZ bolmeleri (dovr / muellif qrupu) uzredir.
--  Iki bolme ikiye ayrilib, cunki derslikde ozleri de iki-uc
--  muellifi ayrica "Heyati, yaradiciliq yolu" ile verir ve bir
--  movzuda 31 keyfiyyetli sual cixmir:
--    10:  "Orta esrler" -> Nesimi+Xetayi | Fuzuli
--         "Maarifci realizm" -> Axundzade | Zakir/Elesger/Sirvani/Vezirov
--     9:  "Ozunuderk dovru" -> poeziya | nesr
--
--  ON SERT: 55_movzular_edebiyyat11.sql islenmis olmalidir.
--  Tekrar isledile biler.
--  SONRA: 59_bank_edebiyyat10.sql, 60_bank_edebiyyat9.sql, 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.subjects where slug = 'edebiyyat') then
    raise exception 'ONCE 55_movzular_edebiyyat11.sql isledilmelidir.';
  end if;
  --  57 islenmeyibse 9/10 kodu iki proqramda ola biler ve movzular
  --  bos seviyyeye dusub itir
  if (select count(*) from public.levels where code in ('9', '10')) <> 2 then
    raise exception 'ONCE 57_sinif_dubli.sql isledilmelidir '
                    '(9/10 sinif kodu kataloqda tek olmalidir).';
  end if;
end $$;

-- ------------------------------------------------------- 10-cu sinif
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-10-sifahi',        'Şifahi xalq ədəbiyyatı',                   10),
    ('edeb-10-dede-qorqud',   'Qədim dövr: «Kitabi-Dədə Qorqud»',         20),
    ('edeb-10-nizami',        'İntibah dövrü: Nizami Gəncəvi',            30),
    ('edeb-10-nesimi-xetayi', 'Orta əsrlər: Nəsimi və Xətayi',            40),
    ('edeb-10-fuzuli',        'Orta əsrlər: Məhəmməd Füzuli',             50),
    ('edeb-10-koroglu-vaqif', 'Erkən yeni dövr: «Koroğlu», Vaqif',        60),
    ('edeb-10-axundzade',     'Maarifçi realizm: M.F.Axundzadə',          70),
    ('edeb-10-maarifci',      'Maarifçi realizm: Zakir, Ələsgər, Vəzirov', 80)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
  join public.levels   l on l.code = '10'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- -------------------------------------------------------- 9-cu sinif
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-9-milli-demokratik', 'Milli-demokratik hərəkat dövrü',          10),
    ('edeb-9-repressiya',       'Repressiya dövrü ədəbiyyatı (1920-1940)', 20),
    ('edeb-9-muharibe',         'Müharibə və mülayimləşmə dövrü (1941-1960)', 30),
    ('edeb-9-ozunuderk-seir',   'Özünüdərk dövrü: poeziya (1961-1990)',    40),
    ('edeb-9-ozunuderk-nesr',   'Özünüdərk dövrü: nəsr (1961-1990)',       50),
    ('edeb-9-mustaqillik',      'Dövlət müstəqilliyi dövrü (1991-)',       60),
    ('edeb-9-cenub',            'Cənubi Azərbaycan ədəbiyyatı',            70),
    ('edeb-9-dunya',            'Dünya ədəbiyyatı',                        80)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
  join public.levels   l on l.code = '9'
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
   where s.slug = 'edebiyyat' and l.code in ('9', '10');
  if n <> 16 then
    raise exception 'Edebiyyat 9-10 movzulari: 16 gozlenilirdi, % tapildi', n;
  end if;

  --  11-ci sinfe ve "Azerbaycan dili" fennine toxunulmamalidir
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'edebiyyat' and l.code = '11') <> 8 then
    raise exception 'Edebiyyat 11 movzulari deyisib - bu fayl ona toxunmamalidir.';
  end if;
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'az-dili' and l.code in ('9', '10')) <> 16 then
    raise exception 'Az dili 9-10 movzulari deyisib - bu fayl ona toxunmamalidir.';
  end if;

  raise notice 'Edebiyyat: 9 ve 10-cu sinif ucun % movzu acildi.', n;
end $$;
