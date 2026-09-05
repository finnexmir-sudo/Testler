-- =====================================================================
--  135_inf3_informasiya_bosluqlar.sql : INF-3-INFORMASIYA 4 ALT-MOVZU BOSLUGU
--
--  "informatika ni yoxla" auditi: inf-3-informasiya movzusunun 8
--  alt-basligindan 4-u (TƏBİƏTDƏ İNFORMASİYA, İNFORMASİYANIN
--  KODLAŞDIRILMASI, REBUS, İNFORMASİYANIN EMALI) hec bir sualla
--  ortulmemisdi. Movcud 20 sual demek olar ki, hamisi "İNSAN VƏ
--  İNFORMASİYA" (bes hiss orqani) hissesine yigilmisdi.
--
--  8 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf3-informasiya#21-28.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-3-informasiya movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-3-informasiya') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-3-informasiya tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf3-informasiya#%' and q.ext_key ~ '#(2[1-8])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf3-informasiya#21',1,'Qara buludlar səmada görünəndə bu bizə nəyi bildirir?','Qara buludlar yağış yağacağı barədə informasiya verir.',array['Yağış yağacağını','Qar yağacağını yalnız','Günəş çıxacağını','Heç nəyi'],1),
('inf3-informasiya#22',2,'Payızda quşların isti ölkələrə uçması bizə nədən xəbər verir?','Bu, havaların soyuyacağından (qışın yaxınlaşdığından) xəbər verir.',array['Havaların soyuyacağından','Yağışın kəsiləcəyindən','Baharın gələcəyindən','Heç nədən'],1),
('inf3-informasiya#23',1,'Yol hərəkətində qırmızı işıq sürücüyə nəyi bildirir?','Qırmızı işıq dayanmaq lazım olduğunu bildirir.',array['Dayanmaq lazımdır','Sürətlə getmək lazımdır','Geri qayıtmaq lazımdır','Heç nə'],1),
('inf3-informasiya#24',3,'Morze əlifbəsində məlumat hansı iki işarə ilə kodlaşdırılır?','Morze əlifbəsi nöqtə və tire işarələrindən qurulur.',array['Nöqtə və tire','Hərf və rəqəm','Rəng və səs','Şəkil və söz'],1),
('inf3-informasiya#25',2,'Rebus nədir?','Rebus — sözün şəkillər, hərflər və işarələrlə verilmiş tapmacasıdır.',array['Şəkil və işarələrlə verilən söz tapmacası','Riyazi məsələ','Musiqi notu','Kompüter proqramı'],1),
('inf3-informasiya#26',2,'Rebusu həll etmək üçün nəyə diqqət etmək lazımdır?','Şəkil və işarələrin gizlətdiyi hərf və ya söz mənasına diqqət etmək lazımdır.',array['Şəkil və işarələrin gizlətdiyi mənaya','Şəklin rənginə yalnız','Kağızın ölçüsünə','Heç nəyə'],1),
('inf3-informasiya#27',2,'Riyazi məsələni həll edərək nəticə tapmaq informasiya ilə hansı əməliyyata misaldır?','Bu, informasiyanın emalına misaldır.',array['İnformasiyanın emalına','İnformasiyanın saxlanmasına','İnformasiyanın ötürülməsinə','Heç birinə'],1),
('inf3-informasiya#28',3,'Eşitdiyimiz bir tapşırığı düşünüb icra etmək beynimizdə informasiya ilə nə etdiyimizi göstərir?','Bu, informasiyanı emal etdiyimizi göstərir.',array['İnformasiyanı emal etdiyimizi','İnformasiyanı yalnız saxladığımızı','İnformasiyanı sildiyimizi','Heç nə etmədiyimizi'],1)
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
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-3-informasiya'
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
   where ext_key like 'inf3-informasiya#%' and ext_key ~ '#(2[1-8])$';
  if n <> 8 then
    raise exception '135: 8 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf3-informasiya#%' and q.ext_key ~ '#(2[1-8])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '135: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '135 OK - 8 sual elave olundu (inf-3-informasiya, tebietde+kodlasdirma+rebus+emal).';
end $$;
