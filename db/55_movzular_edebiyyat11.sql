-- =====================================================================
--  55_movzular_edebiyyat11.sql : EDEBIYYAT FENNI + 11-CI SINIF MOVZULARI
--
--  Mektebde Edebiyyat 5-ci sinifden AYRI fenndir: ayri derslik, ayri
--  qiymet, buraxilis imtahaninda da var.  Bankda ise umumiyyetle yox
--  idi - 'az-dili' movzulari yalniz qrammatikadir.
--
--  Menbe:  e-derslik.edu.az mundericati (tools/mundericat.py),
--          Edebiyyat 11 - kitab id 821, 6 bolme.
--  Yalniz bolme ve movzu adlari goturulub - dersliyin BEDII METNI yox.
--
--  Movzu bolgusu DOVR/muellif qrupu uzredir, tek-tek sair uzre yox:
--  bir sair uzre movzuda 31 keyfiyyetli sual cixmir, dovr uzre cixir
--  ve derslik ozu de bele bolunub.  Daha ince bolgu lazim olsa 'tags'.
--
--  ON SERT: 53_movzular_umumi_tarix.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: 56_bank_edebiyyat11.sql, 05_grants.sql.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.subjects where slug = 'umumi-tarix') then
    raise exception 'ONCE 53_movzular_umumi_tarix.sql isledilmelidir.';
  end if;
end $$;

-- ------------------------------------------------------------- fenn
--  sort = 25: siyahida "Azerbaycan dili" (20) ile "Ingilis dili" (30)
--  arasinda - muellim ucun tebii qonsuluqdur
insert into public.subjects (slug, name, sort) values
  ('edebiyyat', 'Ədəbiyyat', 25)
on conflict (slug) do update set name = excluded.name, sort = excluded.sort;

insert into public.program_subjects (program_id, subject_id)
select p.id, s.id from public.programs p, public.subjects s
 where s.slug = 'edebiyyat' and p.slug in ('orta', 'buraxilis')
on conflict do nothing;

-- ---------------------------------------------------------- movzular
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('edeb-11-tenqidi-realizm', 'Tənqidi realizm: Məmmədquluzadə, Sabir', 10),
    ('edeb-11-romantizm',       'Romantizm: Hüseyn Cavid, Əhməd Cavad',   20),
    ('edeb-11-cabbarli-vurgun', 'Cəfər Cabbarlı və Səməd Vurğun',         30),
    ('edeb-11-rza-mircelal',    'Rəsul Rza və Mir Cəlal',                 40),
    ('edeb-11-ozunuderk',       'Özünüdərk: İ.Əfəndiyev, İ.Şıxlı',        50),
    ('edeb-11-istiqlal',        'İstiqlal ədəbiyyatı: B.Vahabzadə',       60),
    ('edeb-11-cenub-dunya',     'Cənubi Azərbaycan və dünya ədəbiyyatı',  70),
    ('edeb-11-nezeriyye',       'Ədəbi cərəyanlar və nəzəriyyə',          80)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'edebiyyat'
  join public.programs p on p.slug = 'orta'
  join public.levels   l on l.program_id = p.id and l.code = '11'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

-- ------------------------------------------------------- oz yoxlamasi
do $$
declare n int;
begin
  select count(*) into n from public.topics t
    join public.subjects s on s.id = t.subject_id
    join public.levels   l on l.id = t.level_id
   where s.slug = 'edebiyyat' and l.code = '11';
  if n <> 8 then
    raise exception 'Edebiyyat 11 movzulari: 8 gozlenilirdi, % tapildi', n;
  end if;

  --  "Azerbaycan dili" fenninin movzularina toxunulmamalidir
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id
        join public.levels   l on l.id = t.level_id
       where s.slug = 'az-dili' and l.code = '11') <> 8 then
    raise exception 'Az dili 11 movzulari deyisib - bu fayl ona toxunmamalidir.';
  end if;

  raise notice 'Edebiyyat fenni acildi, 11-ci sinif: % movzu.', n;
end $$;
