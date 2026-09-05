-- =====================================================================
--  127_hey4_dini_deyerler.sql : HEY-4-FERD-AILE DINI DEYERLER
--
--  "Ferd, aile ve cemiyyet" movzusunun alt-basligi "Dini deyerler"dir -
--  amma 20 sualin hec biri bu movzuya toxunmayib (qalan alt-basliqlar
--  - insan sosial varliq, ailenin rolu, menevi keyfiyyetler, menevi
--  borc - yaxsi ortulub). Istifadeci auditinde tapildi.
--
--  3 yeni sual elave edir (movcud suallara toxunulmur), umumi
--  vetendas-tehsili cercivesinde, neytral ve hormetli formada.
--  ext_key: hey4-ferd-aile#21-23.
--
--  ON SERT: 17_bank_sinif4.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'hayat-bilgisi' and t.slug = 'hey-4-ferd-aile') then
    raise exception 'ONCE 17_bank_sinif4.sql islenmis olmalidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'hey4-ferd-aile#%' and q.ext_key ~ '#(2[1-3])$';

with d(ext, diff, body, why, opts, correct) as (values
('hey4-ferd-aile#21',1,'Dini dəyərlərə hörmət etmək ailə həyatında nəyə kömək edir?','Ailə üzvləri arasında qarşılıqlı hörməti və anlaşmanı gücləndirir.',array['Qarşılıqlı hörməti gücləndirir','Ailəni parçalayır','Heç bir təsiri yoxdur','Yalnız bayramlarda lazımdır'],1),
('hey4-ferd-aile#22',2,'Ramazan və Qurban bayramları Azərbaycanda hansı əhəmiyyətə malikdir?','Bu bayramlar dini-mənəvi dəyərləri və ailə birliyini yaşadan ənənəvi bayramlardır.',array['Dini-mənəvi dəyərləri və ailə birliyini yaşadır','Yalnız adi iş günüdür','Heç bir əhəmiyyəti yoxdur','Yalnız uşaqlar üçündür'],1),
('hey4-ferd-aile#23',2,'Fərqli dini inanclara hörmətlə yanaşmaq nəyi göstərir?','Cəmiyyətdə tolerantlıq və qarşılıqlı anlaşmanı göstərir.',array['Tolerantlıq və qarşılıqlı anlaşmanı','Laqeydliyi','Zəifliyi','Maraqsızlığı'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 3, 'published'
    from d
    join public.subjects s on s.slug = 'hayat-bilgisi'
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '4'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'hey-4-ferd-aile'
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
   where ext_key like 'hey4-ferd-aile#%' and ext_key ~ '#(2[1-3])$';
  if n <> 3 then
    raise exception '127: 3 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'hey4-ferd-aile#%' and q.ext_key ~ '#(2[1-3])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '127: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '127 OK - 3 sual elave olundu (hey-4-ferd-aile, dini deyerler).';
end $$;
