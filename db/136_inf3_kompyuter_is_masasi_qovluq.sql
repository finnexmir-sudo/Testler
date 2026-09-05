-- =====================================================================
--  136_inf3_kompyuter_is_masasi_qovluq.sql : INF-3-KOMPYUTER ZEIF ALT-MOVZULAR
--
--  "informatika ni yoxla" auditi: inf-3-kompyuter movzusunun 3
--  alt-basligindan ikisi - "İŞ MASASI" ve "QOVLUQ" - movcud 20 sualda
--  praktiki toxunulmamisdi (yalnix "faylları harada saxlayırıq"
--  sualı qovluğa uzaqdan işarə edirdi, "iş masası" termini heç
--  keçmirdi) - hər ikisi "KOMPÜTER VƏ İNFORMASİYA" (aparat hissələri)
--  ilə əvəzlənmişdi.
--
--  4 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf3-kompyuter#21-24.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-3-kompyuter movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-3-kompyuter') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-3-kompyuter tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf3-kompyuter#%' and q.ext_key ~ '#(2[1-4])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf3-kompyuter#21',1,'Kompüteri işə saldıqda ekranda ilk görünən əsas sahə necə adlanır?','Bu sahə iş masası adlanır.',array['İş masası','Sistem bloku','Klaviatura','Printer'],1),
('inf3-kompyuter#22',2,'İş masasında bir proqramı açmaq üçün adətən onun nişanının üzərinə neçə dəfə klikləmək lazımdır?','Proqramı açmaq üçün nişanın üzərinə adətən 2 dəfə (double-click) klikləmək lazımdır.',array['2 dəfə','1 dəfə','3 dəfə','Heç vaxt klikləmək olmaz'],1),
('inf3-kompyuter#23',1,'Fayllarımızı nizamlı saxlamaq üçün onları harada topluyuruq?','Faylları nizamlı saxlamaq üçün qovluqlarda topluyuruq.',array['Qovluqlarda','Zibil qutusunda','Printerdə','Ekranın kənarında'],1),
('inf3-kompyuter#24',2,'Bir qovluğun daxilində daha kiçik qovluq da ola bilərmi?','Bəli, bir qovluğun daxilində alt qovluq da ola bilər.',array['Bəli, ola bilər','Xeyr, əsla ola bilməz','Yalnız bir dənə ola bilər','Yalnız rəngli olarsa'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 3, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '3'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-3-kompyuter'
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct::int
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(d.opts) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where ext_key like 'inf3-kompyuter#%' and ext_key ~ '#(2[1-4])$';
  if n <> 4 then
    raise exception '136: 4 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf3-kompyuter#%' and q.ext_key ~ '#(2[1-4])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '136: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '136 OK - 4 sual elave olundu (inf-3-kompyuter, is masasi + qovluq).';
end $$;
