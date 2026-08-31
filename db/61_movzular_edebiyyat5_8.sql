-- =====================================================================
--  61_movzular_edebiyyat5_8.sql : EDEBIYYAT 5-8-CI SINIF MOVZULARI
--
--  Menbe:  e-derslik.edu.az mundericati (tools/mundericat.py)
--          Edebiyyat 5 - kitab id 845   Edebiyyat 7 - kitab id 701
--          Edebiyyat 6 - kitab id 911   Edebiyyat 8 - kitab id 793
--  Yalniz bolme ve movzu adlari goturulub - dersliyin BEDII METNI,
--  calisma ve suallari YOX (muellif huququ).
--
--  DIQQET - 5-7 ile 8 FERQLI qurulub, cunki DERSLIK ozu bele qurub:
--    5, 6, 7-ci sinifde bolmeler TEMA uzredir ("Yurd sevgisi",
--       "Tebietin gozelliyi"...), ona gore movzular da temadir;
--    8-ci sinifde bolmeler DOVR uzredir (Qedim, Intibah, Orta esrler...)
--       - 10 ve 11-ci sinifle eyni qelib.
--  Bolme sayi neceydise o qeder movzu var; sun'i bolgu edilmeyib.
--  Yalniz 8-ci sinifin "Tenqidi realizm VE romantizm" bolmesi ikiye
--  ayrilib - bolmenin oz adinda IKI ayri cereyan var.
--
--  ON SERT: 58_movzular_edebiyyat9_10.sql islenmis olmalidir.
--  Tekrar isledile biler.
--  SONRA: 62-65 bank fayllari, sonra 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'edebiyyat' and t.slug = 'edeb-9-dunya') then
    raise exception 'ONCE 58_movzular_edebiyyat9_10.sql isledilmelidir.';
  end if;
  if (select count(*) from public.levels
       where code in ('5', '6', '7', '8')) <> 4 then
    raise exception 'Kataloqda 5-8 sinifleri tek olmalidir '
                    '(57_sinif_dubli.sql isledilibmi?).';
  end if;
end $$;

-- ------------------------------------------------------- 5-ci sinif
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-5-sifahi',   'Şifahi xalq ədəbiyyatı inciləri',        10),
    ('edeb-5-yurd',     'Yurd sevgisi, ana məhəbbəti',            20),
    ('edeb-5-menevi',   'Mənəvi dəyərlər, həmişəyaşar hikmətlər',  30),
    ('edeb-5-muharibe', 'Müharibə və insan haqqı',                40),
    ('edeb-5-usaq',     'Uşaq dünyası, uşaq taleyi',              50),
    ('edeb-5-emek',     'Əməyə məhəbbət, zəhmətə çağırış',        60),
    ('edeb-5-tebiet',   'Təbiətin gözəlliyi, təbiətə qayğı',      70)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
  join public.levels   l on l.code = '5'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ------------------------------------------------------- 6-ci sinif
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-6-sifahi', 'Şifahi xalq ədəbiyyatından nümunələr',   10),
    ('edeb-6-usaq',   'Uşaq düşüncəsi, uşaq dünyası',           20),
    ('edeb-6-yurd',   'Yurd sevgisi, qəhrəmanlıq səhifələri',   30),
    ('edeb-6-menevi', 'Mənəvi dəyərlər, yaşayan hikmətlər',     40),
    ('edeb-6-tebiet', 'Təbiətin gözəlliyi, təbiətə qayğı',      50)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
  join public.levels   l on l.code = '6'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ------------------------------------------------------- 7-ci sinif
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-7-sifahi', 'Şifahi xalq ədəbiyyatından seçmələr',    10),
    ('edeb-7-veten',  'Vətən sevgisi, qəhrəmanlıq səhifələri',  20),
    ('edeb-7-menevi', 'Mənəvi dəyərlər, həmişəyaşar hikmətlər', 30),
    ('edeb-7-usaq',   'Uşaq aləmi, uşaq taleyi',                40),
    ('edeb-7-tebiet', 'Təbiətə vurğunluq, təbiətə qayğı',       50)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
  join public.levels   l on l.code = '7'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ------------------------------------------------------- 8-ci sinif
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-8-qedim',     'Qədim dövr: «Kitabi-Dədə Qorqud»',          10),
    ('edeb-8-intibah',   'İntibah dövrü: Xaqani, Nizami',             20),
    ('edeb-8-orta',      'Orta əsrlər: Nəsimi, Xətayi, Füzuli',       30),
    ('edeb-8-erken',     'Erkən yeni dövr: «Koroğlu», Vaqif',         40),
    ('edeb-8-maarifci',  'Maarifçi realizm: Zakir, Ələsgər, Şirvani', 50),
    ('edeb-8-tenqidi',   'Tənqidi realizm: Məmmədquluzadə, Sabir',    60),
    ('edeb-8-romantizm', 'Romantizm və dünya ədəbiyyatı',             70)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
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
   where s.slug = 'edebiyyat' and l.code in ('5', '6', '7', '8');
  if n <> 24 then
    raise exception 'Edebiyyat 5-8 movzulari: 24 gozlenilirdi, % tapildi', n;
  end if;

  --  9-11 movzularina toxunulmamalidir
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'edebiyyat' and l.code in ('9', '10', '11')) <> 24 then
    raise exception 'Edebiyyat 9-11 movzulari deyisib - bu fayl ona toxunmamalidir.';
  end if;

  raise notice 'Edebiyyat: 5-8-ci sinifler ucun % movzu acildi '
               '(5:7, 6:5, 7:5, 8:7).', n;
end $$;
