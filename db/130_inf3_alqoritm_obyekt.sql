-- =====================================================================
--  130_inf3_alqoritm_obyekt.sql : INF-3-ALQORITM OBYEKT/MENTIQ HISSESI
--
--  "Alqoritm" movzusunun 10 alt-basligindan 5-i (OBYEKTLER QRUPU,
--  OBYEKTIN FERQLENDIRICI ELAMETLERI, "HAMISI"/"HEC BIRI"/"BEZISI",
--  QANUNAUYGUNLUQ) heç bir sualla ortulmemisdi - movcud 20 sualin
--  hamisi yalniz esl alqoritm hissesini (xetti/budaqlanma/tekrar)
--  ehate edirdi. Istifadeci auditinde tapildi.
--
--  8 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf3-alqoritm#21-28.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-3-alqoritm movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-3-alqoritm') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-3-alqoritm tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf3-alqoritm#%' and q.ext_key ~ '#(2[1-8])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf3-alqoritm#21',1,'Ortaq əlamətinə görə əşyaları bir yerə toplamaq necə adlanır?','Ortaq əlamətə görə əşyaları toplamağa qruplaşdırma deyilir.',array['Qruplaşdırma','Ölçmə','Çəkmə','Yazma'],1),
('inf3-alqoritm#22',1,'Almalar və armudlar ayrı-ayrı qutulara qoyulursa, bu hansı əməliyyata misaldır?','Bu, obyektlərin növünə görə qruplaşdırılmasına misaldır.',array['Obyektlərin qruplaşdırılmasına','Alqoritm icrasına','Ölçüyə','Rənglənməyə'],1),
('inf3-alqoritm#23',2,'Bir obyekti başqasından fərqləndirən əlamətlərə misal hansıdır?','Rəng, forma və ölçü obyektləri fərqləndirən əsas əlamətlərdir.',array['Rəng, forma, ölçü','Ad, soyad', 'Ünvan', 'Telefon nömrəsi'],1),
('inf3-alqoritm#24',2,'İki əşyanın oxşar və fərqli cəhətlərini tapmaq üçün nə edilir?','İki əşyanın oxşar və fərqli cəhətlərini tapmaq üçün müqayisə aparılır.',array['Müqayisə aparılır','Alqoritm yazılır','Rəqəmlə ifadə olunur','Heç nə edilmir'],1),
('inf3-alqoritm#25',1,'«Bütün quşlar uça bilər» ifadəsində hansı söz qrupun tam əhatə olunduğunu bildirir?','«Bütün» sözü qrupun heç istisnasız tam əhatə olunduğunu bildirir.',array['Bütün (hamısı)','Bəzi','Heç bir','Yalnız bir'],1),
('inf3-alqoritm#26',2,'«Heç bir balıq quruda yaşaya bilməz» ifadəsindəki «heç bir» sözü nəyi bildirir?','«Heç bir» sözü istisnasız olaraq heç birinin belə olmadığını bildirir.',array['İstisnasız heç birinin olmadığını','Yalnız birinin olduğunu','Hamısının olduğunu','Bəzilərinin olduğunu'],1),
('inf3-alqoritm#27',2,'«Bəzi heyvanlar uça bilir» ifadəsindəki «bəzi» sözü nəyi bildirir?','«Bəzi» sözü qrupun yalnız bir hissəsinə aid olduğunu bildirir.',array['Qrupun yalnız bir hissəsini','Qrupun hamısını','Qrupun heç birini','Qrupun yarısını dəqiq'],1),
('inf3-alqoritm#28',3,'Əşyalar sırasında təkrarlanan qaydanı (məsələn, qırmızı-mavi-qırmızı-mavi) tapmaq necə adlanır?','Təkrarlanan qaydanı tapmağa qanunauyğunluğun aşkar edilməsi deyilir.',array['Qanunauyğunluğun tapılması','Alqoritmin icrası','Obyektin ölçülməsi','Rəngin dəyişdirilməsi'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 1, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '3'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-3-alqoritm'
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
   where ext_key like 'inf3-alqoritm#%' and ext_key ~ '#(2[1-8])$';
  if n <> 8 then
    raise exception '130: 8 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf3-alqoritm#%' and q.ext_key ~ '#(2[1-8])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '130: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '130 OK - 8 sual elave olundu (inf-3-alqoritm, obyekt qruplasdirma + mentiq kemiyyetleri).';
end $$;
