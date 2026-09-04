-- =====================================================================
--  123_tarix11_mustemleke_cenub.sql : TARIX-11 CENUBI AZERBAYCAN
--
--  "Musteml.dovru. Milli oyanis" movzusunun IV fesli "Cenubi
--  Azerbaycanin sosial-iqtisadi inkisaf xususiyyetleri"dir - iki
--  alt-basliq: "Cenubi Azerbaycan XIX esrde" ve "Mesrute inqilabi".
--  Movcud 31 sualin hamisi Simali Azerbaycan (Baki neft, metbuat,
--  medeniyyet) idi - Cenuba bir dene de sual yox idi. Istifadeci
--  auditinde tapildi.
--
--  Bu fayl 8 yeni sual elave edir (movzu agaci deyismir, movcud
--  suallara toxunulmur). ext_key: tarix11-mustemleke#31-38.
--
--  ON SERT: 49_movzular_orta11.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'tarix' and t.slug = 'tarix-11-mustemleke') then
    raise exception 'ONCE 49_movzular_orta11.sql islenmis olmalidir.';
  end if;
end $$;

with d(ext, diff, body, why, opts, correct) as (values
('tarix11-mustemleke#31',1,'Cənubi Azərbaycan XIX əsrdə hansı dövlətin tərkibində idi?','Cənubi Azərbaycan Qacarlar dövlətinin (İranın) tərkibində idi.',array['Qacarlar dövlətinin (İran)','Osmanlı imperiyasının','Rusiya imperiyasının','Əfqanıstanın'],1),
('tarix11-mustemleke#32',2,'Cənubi Azərbaycanın iqtisadi həyatında hansı münasibətlər üstünlük təşkil edirdi?','Yarımfeodal münasibətlər - kənd təsərrüfatı və sənətkarlıq əsas idi.',array['Yarımfeodal kənd təsərrüfatı münasibətləri','Sənaye kapitalizmi','Köçəri maldarlıq','Dəniz ticarəti'],1),
('tarix11-mustemleke#33',1,'Cənubi Azərbaycanın iqtisadi-mədəni mərkəzi hansı şəhər idi?','Təbriz Cənubi Azərbaycanın əsas mərkəzi idi.',array['Təbriz','İsfahan','Şiraz','Tehran'],1),
('tarix11-mustemleke#34',1,'Məşrutə inqilabı hansı illəri əhatə edir?','Məşrutə (Konstitusiya) inqilabı 1905-1911-ci illəri əhatə edir.',array['1905-1911','1917-1920','1828-1830','1870-1875'],1),
('tarix11-mustemleke#35',2,'Məşrutə inqilabının əsas tələbi nə idi?','İnqilabçılar konstitusiya və parlament (Məclis) qəbul edilməsini tələb edirdi.',array['Konstitusiya və parlamentin qəbulu','Ölkənin bölünməsi','Xarici hərbi müdaxilə','Dini hakimiyyətin gücləndirilməsi'],1),
('tarix11-mustemleke#36',2,'Məşrutə hərəkatında Cənubi Azərbaycanın rolu necə oldu?','Təbriz üsyanı ilə hərəkatın əsas mərkəzlərindən birinə çevrildi.',array['Təbriz üsyanı ilə əsas mərkəzlərdən biri oldu','Hərəkata heç qatılmadı','Yalnız maliyyə yardımı etdi','Hərəkata qarşı çıxdı'],1),
('tarix11-mustemleke#37',3,'Səttarxan Məşrutə hərəkatında hansı rolu oynamışdır?','Səttarxan Təbriz üsyanının hərbi rəhbərlərindən biri (sərdar-i milli) olmuşdur.',array['Təbriz üsyanının hərbi rəhbərlərindən biri','Qacar sarayının vəziri','Rusiya konsulu','Osmanlı sultanının səfiri'],1),
('tarix11-mustemleke#38',3,'Qacar hökmdarı Məşrutəçilərə qarşı hansı addımı atmışdı?','Məhəmmədəli şah çevriliş edib parlamenti bağlatmış, mütləqiyyəti bərpa etməyə çalışmışdı.',array['Parlamenti bağlatmış, mütləqiyyəti bərpaya çalışmışdı','Konstitusiyanı özü təklif etmişdi','Taxtdan tam imtina etmişdi','Məşrutəçilərlə ittifaq bağlamışdı'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 1, 'published'
    from d
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'tarix-11-mustemleke'
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
   where ext_key like 'tarix11-mustemleke#%' and ext_key ~ '#(3[1-8])$';
  if n <> 8 then
    raise exception '123: 8 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'tarix11-mustemleke#%' and q.ext_key ~ '#(3[1-8])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '123: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '123 OK - 8 sual elave olundu (tarix-11-mustemleke, Cenubi Azerbaycan + Mesrute inqilabi).';
end $$;
