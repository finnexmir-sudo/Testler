-- =====================================================================
--  134_inf11_sistemler_bosluqlar.sql : INF-11-SISTEMLER 3 ALT-MOVZU BOSLUGU
--
--  "informatika ni yoxla" auditi: inf-11-sistemler movzusunun 9
--  alt-basligindan 3-u hec bir sualla ortulmemisdi - "COĞRAFİ
--  İNFORMASİYA SİSTEMLƏRİ" (GIS), "AXTARIŞ SİSTEMLƏRİ" ve
--  "BÖYÜK VERİLƏNLƏR" TEXNOLOGİYASI. Movcud 20 sual yalniz sistem
--  anlayisi, sistem tesnifati ve suni intellekt/ekspert sistemleri
--  hisselerini ehate edirdi.
--
--  6 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf11-sistemler#21-26.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-11-sistemler movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-11-sistemler') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-11-sistemler tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf11-sistemler#%' and q.ext_key ~ '#(2[1-6])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf11-sistemler#21',2,'Coğrafi informasiya sistemi (CİS/GIS) nəyi birləşdirir?','GİS xəritə (məkan) məlumatını verilənlər bazası ilə birləşdirir.',array['Məkan (xəritə) məlumatını verilənlər bazası ilə','Yalnız mətn sənədlərini','Yalnız musiqi fayllarını','Yalnız e-poçtları'],1),
('inf11-sistemler#22',3,'Naviqasiya proqramları (məsələn, xəritədə marşrut qurma) hansı texnologiyaya əsaslanır?','Bu proqramlar coğrafi informasiya sistemlərinə (GİS) əsaslanır.',array['Coğrafi informasiya sistemlərinə (GİS)','Ekspert sisteminə','Neyron şəbəkəyə yalnız','Kriptoqrafiyaya'],1),
('inf11-sistemler#23',2,'Axtarış sistemi (məsələn, Google) əsas olaraq nə edir?','İstifadəçinin sorğusuna uyğun veb-səhifələri tapıb sıralayır.',array['Sorğuya uyğun veb-səhifələri tapıb sıralayır','Yalnız fayl sıxır','Yalnız virus axtarır','Yalnız e-poçt göndərir'],1),
('inf11-sistemler#24',3,'Axtarış sistemi nəticələri sıralayarkən nəyə əsaslanır?','Səhifənin sorğuya uyğunluğuna və nüfuzuna (keyfiyyət göstəricilərinə) əsaslanır.',array['Sorğuya uyğunluq və nüfuz göstəricilərinə','Yalnız səhifənin rənginə','Yalnız yaradılma tarixinə','Təsadüfi seçimə'],1),
('inf11-sistemler#25',2,'«Böyük verilənlər» (Big Data) termini nəyi ifadə edir?','Ənənəvi vasitələrlə emalı çətin olan çox böyük həcmli verilənlər toplusunu.',array['Çox böyük həcmli verilənlər toplusunu','Kiçik mətn faylını','Bir şəklin ölçüsünü','Bir kompüterin yaddaşını'],1),
('inf11-sistemler#26',3,'Böyük verilənlər (Big Data) texnologiyası ən çox harada tətbiq olunur?','Milyonlarla istifadəçi davranışının təhlilində (sosial şəbəkə, ticarət).',array['İstifadəçi davranışının kütləvi təhlilində','Yalnız bir sənədin çapında','Yalnız bir şəklin redaktəsində','Yalnız bir e-poçtun yazılmasında'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 1, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-11-sistemler'
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
   where ext_key like 'inf11-sistemler#%' and ext_key ~ '#(2[1-6])$';
  if n <> 6 then
    raise exception '134: 6 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf11-sistemler#%' and q.ext_key ~ '#(2[1-6])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '134: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '134 OK - 6 sual elave olundu (inf-11-sistemler, GIS + axtaris sistemleri + boyuk verilenler).';
end $$;
