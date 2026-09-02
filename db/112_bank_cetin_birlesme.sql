-- =====================================================================
--  112_bank_cetin_birlesme.sql :
--  "Coxmulahizeli birlesme sualı" retrofit-i (CLAUDE.md, "novbeti
--  merhele" bolmesinde sened edilmis format).
--
--  Her bend: movcud CETIN (difficulty=3) sualin ozu ORTA (2)
--  seviyyeye enir - ARXIVLENMIR, movzuda qalir, kohne netice ve
--  hesabatlar toxunulmaz qalir. Onun YERINE eyni movzuda 4
--  nomrelenmis mulahize + kombinasiya variantlari olan yeni sual 3
--  (cetin) kimi yazilir.
--
--  Qayda: 4 mulahize YALNIZ hemin movzunun oz bankinda ARTIQ movcud
--  olan (evvelden dogru cavabi ile tesdiqlenmis) faktlardan qurulur -
--  yeni fakt UYDURULMUR (erken pilotdaki ders - uydurulmus elave
--  detala real sagird "derslikde yoxdur" deyib).
--
--  Elave sual novu YOX, movcud `single` novun icindedir (sxeme
--  toxunmur) - body coxsetirlidir, variantlar kombinasiya seklindedir
--  (A) 1,3  B) yalniz 1  C) 2,4  D) 1,2,3).
--
--  Yeni sual kohne sualin QUARTER-ini alt sorgu ile goturur - elle
--  yazilmir, kohne setirle uygunsuzluk yaranmasin deye.
--
--  Ehate: pilot - 1 sual/fenn (riyaziyyat, az dili, ingilis, 11-ci
--  sinif). tools/cetin_birlesme.py-in RETROFIT siyahisina yeni bend
--  elave edib yeniden isledaraq boyudulur.
--
--  Tekrar isledile biler (on conflict (ext_key) do update).
-- =====================================================================

set search_path = public, extensions;

-- ------------------------------------------------------------- riy11-toreme#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-toreme#11';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-toreme#comb1', 'riy-11-toreme',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) (sin x)′ = cos x
2) (cos x)′ = sin x
3) (eˣ)′ = eˣ
4) (ln x)′ = x',
  '(sin x)′ = cos x və (eˣ)′ = eˣ doğrudur. 2-ci mülahizədə işarə səhvdir (doğrusu −sin x), 4-cü mülahizədə isə (ln x)′ əslində 1/x-dir, x deyil.',
  '1, 3', '1', '2, 4', '1, 2, 3', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-toreme#11'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'riyaziyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, quarter = excluded.quarter,
        topic_id = excluded.topic_id, level_id = excluded.level_id,
        subject_id = excluded.subject_id, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(array[d.o1, d.o2, d.o3, d.o4]) with ordinality as o(txt, ord)
on conflict (question_id, ord) do update set body = excluded.body, is_correct = excluded.is_correct;

-- ------------------------------------------------------------- az11-murekkeb-t#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-murekkeb-t#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-murekkeb-t#comb1', 'az-11-murekkeb-t',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Külək əsdi, yarpaqlar töküldü» cümləsi tabesiz mürəkkəb cümlədir.
2) «Yağış yağanda hava sərinləşir» cümləsindəki budaq cümlə səbəb bildirir.
3) «Hava pis olduğu üçün gəzintini təxirə saldıq» cümləsindəki budaq cümlə səbəb bildirir.
4) «Bilirəm ki, sən haqlısan» cümləsindəki budaq cümlə zaman bildirir.',
  '1 və 3 doğrudur. 2-ci mülahizədə əslində zaman bildirilir (səbəb yox), 4-cü mülahizədə isə budaq cümlə tamamlıq (xəbər) vəzifəsindədir, zaman yox.',
  '1, 3', '1', '2, 4', '1, 2, 3', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-murekkeb-t#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'az-dili'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, quarter = excluded.quarter,
        topic_id = excluded.topic_id, level_id = excluded.level_id,
        subject_id = excluded.subject_id, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(array[d.o1, d.o2, d.o3, d.o4]) with ordinality as o(txt, ord)
on conflict (question_id, ord) do update set body = excluded.body, is_correct = excluded.is_correct;

-- ------------------------------------------------------------- ing11-regrets#comb1
update public.questions set difficulty = 2 where ext_key = 'ing11-regrets#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing11-regrets#comb1', 'ing-11-regrets',
  'Which statements are TRUE?
1) "If they had left earlier, they would have caught the train" is a Third Conditional sentence.
2) "He regrets leaving school early" uses the -ing form after "regret".
3) "We could have taken a taxi instead of walking, but we did not" describes a missed past possibility.
4) "She wishes she lived in a bigger city now" uses the Past Perfect after "wish".',
  '1, 2 and 3 are true. Statement 4 is wrong - "wishes...lived" uses the Past Simple to express a present wish, not the Past Perfect.',
  '1, 2, 3', 'yalnız 1', '2, 4', '3, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing11-regrets#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'ingilis-dili'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, quarter = excluded.quarter,
        topic_id = excluded.topic_id, level_id = excluded.level_id,
        subject_id = excluded.subject_id, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(array[d.o1, d.o2, d.o3, d.o4]) with ordinality as o(txt, ord)
on conflict (question_id, ord) do update set body = excluded.body, is_correct = excluded.is_correct;

do $$
declare v_n int;
begin
  select count(*) into v_n from public.questions where ext_key like '%#comb%';
  if v_n <> 3 then
    raise exception '112: 3 birlesme sual gozlenilirdi, % tapildi', v_n;
  end if;
  raise notice '112 OK - % birlesme sual', v_n;
end $$;
