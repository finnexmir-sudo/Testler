-- =====================================================================
--  70_movzular_umumi_tarix7.sql : UMUMI TARIX 7 - IKI YENI MOVZU
--
--  NIYE BU FAYL VAR
--  e-derslik.edu.az portalinda 7-ci sinif ucun "Azerbaycan tarixi"
--  derslikyi YOXDUR - yalniz "Umumi tarix" (book_id 723) var
--  (mundericat/tarix-7-723.txt).  Deməli 29_movzular_orta7.sql-in
--  'tarix' fenni altinda acdigi alti movzu da dunya tarixi idi.
--  Onlarin 180 suali 71_bank_tarix_umumi7.sql ile 'umumi-tarix'
--  fennine kocurulur.
--
--  Kohne alti movzudan yalniz IKISI heqiqeten yeni movzudur - qalan
--  dordu icmal movzusudur (bir movzuda hem Bizans, hem xilafet, hem
--  feodalizm), onlarin suallari 66-nin alti movzusuna paylanir.
--  Ona gore burada cemi IKI movzu acilir:
--      utarix-7-turk-dovletleri   Erken orta esrlerde turk dovletleri
--      utarix-7-selcuq-osmanli    Selcuq, Monqol ve Osmanli dovletleri
--  Neticede 7-ci sinif Umumi tarix 8 movzu / 366 sual olur.
--
--  ON SERT: 66_movzular_umumi_tarix6_8.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: 71_bank_tarix_umumi7.sql, 05_grants.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'umumi-tarix' and t.slug = 'utarix-7-medeniyyet') then
    raise exception 'ONCE 66_movzular_umumi_tarix6_8.sql isledilmelidir.';
  end if;
  if (select count(*) from public.levels where code = '7') <> 1 then
    raise exception 'Kataloqda 7-ci sinif tek olmalidir '
                    '(57_sinif_dubli.sql isledilibmi?).';
  end if;
end $$;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from (values
    ('utarix-7-turk-dovletleri', 'Erkən orta əsrlərdə türk dövlətləri',  70),
    ('utarix-7-selcuq-osmanli',  'Səlcuq, Monqol və Osmanlı dövlətləri', 80)
  ) as v(slug, name, sort)
  join public.subjects s on s.slug = 'umumi-tarix'
  join public.levels   l on l.code = '7'
  join public.programs p on p.id = l.program_id and p.slug = 'orta'
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '7';
  if k <> 8 then
    raise exception 'Umumi tarix 7: 8 movzu gozlenilirdi, % tapildi', k;
  end if;
  raise notice 'Umumi tarix 7: 8 movzu hazir (suallar - 71 faylinda).';
end $$;
