-- =====================================================================
--  138_inf11_modellesdirme_bosluqlar.sql : INF-11-MODELLESDIRME 2 ALT-MOVZU BOSLUGU
--
--  "informatika ni yoxla" auditi: inf-11-modellesdirme movzusunun 5
--  alt-basligindan 2-si - "PROQRAMLAŞDIRMA DİLLƏRİNİN KÖMƏYİ İLƏ
--  RİYAZİ MƏSƏLƏLƏRİN MODELLƏŞDİRİLMƏSİ" ve "ÜÇÖLÇÜLÜ QRAFİK
--  MODELLƏR" - hec bir sualla ortulmemisdi. Movcud 20 sual ancaq
--  umumi modelleşdirme anlayislarini (verifikasiya, adekvatlıq,
--  simulyasiya) ve statistik/cedvel modelleşdirmesini ehate edirdi.
--
--  4 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf11-modellesdirme#21-24.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-11-modellesdirme movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-11-modellesdirme') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-11-modellesdirme tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf11-modellesdirme#%' and q.ext_key ~ '#(2[1-4])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf11-modellesdirme#21',2,'Riyazi məsələni proqramlaşdırma dili ilə modelləşdirməyin əsas üstünlüyü nədir?','Proqram mürəkkəb hesablamaları sürətlə və fərqli qiymətlərlə dəfələrlə təkrar edə bilir.',array['Mürəkkəb hesablamaları sürətlə təkrar etmək imkanı','Yalnız şəkil çəkmək imkanı','Yalnız mətn yazmaq imkanı','Heç bir üstünlük yoxdur'],1),
('inf11-modellesdirme#22',3,'Bir cismin sərbəst düşməsini proqram vasitəsilə modelləşdirmək üçün proqrama ilk növbədə nə daxil edilməlidir?','Hərəkəti təsvir edən riyazi düstur (asılılıq) daxil edilməlidir.',array['Hərəkəti təsvir edən riyazi düstur','Yalnız rəng','Yalnız musiqi','Yalnız mətn'],1),
('inf11-modellesdirme#23',2,'Üçölçülü (3D) qrafik modellər kompüter modelləşdirməsində nəyi vizual təqdim etməyə imkan verir?','3D qrafik modellər obyektin real formasını və məkan xüsusiyyətlərini vizual göstərir.',array['Obyektin real formasını və məkan xüsusiyyətlərini','Yalnız rəqəmləri','Yalnız mətni','Yalnız səsi'],1),
('inf11-modellesdirme#24',2,'Bir binanın zəlzələyə davamlılığını yoxlamazdan əvvəl onun üçölçülü kompüter modelinin qurulmasının məqsədi nədir?','Real tikintiyə başlamadan struktur davranışını sınamaq üçündür.',array['Real tikintidən əvvəl struktur davranışını sınamaq','Yalnız gözəl şəkil çəkmək','Yalnız reklam etmək','Heç bir məqsəd yoxdur'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 2, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-11-modellesdirme'
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
   where ext_key like 'inf11-modellesdirme#%' and ext_key ~ '#(2[1-4])$';
  if n <> 4 then
    raise exception '138: 4 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf11-modellesdirme#%' and q.ext_key ~ '#(2[1-4])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '138: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '138 OK - 4 sual elave olundu (inf-11-modellesdirme, proqramla modelleşdirme + 3D qrafik modeller).';
end $$;
