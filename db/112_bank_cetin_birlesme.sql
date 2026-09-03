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

-- ------------------------------------------------------------- riy11-arasdirma#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-arasdirma#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-arasdirma#comb1', 'riy-11-arasdirma',
  'f(x) = x³ − 3x funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Funksiyanın böhran nöqtələri x = −1 və x = 1-dir.
2) x = −1 nöqtəsində funksiyanın maksimumu var.
3) x = 1 nöqtəsində funksiyanın minimumu var.
4) f(x)-in [0; 2] parçasında ən böyük qiyməti f(1) nöqtəsindədir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: x = 1 elə bu parçanın öz MİNİMUMUDUR (f(1) = −2), parçanın ən böyük qiyməti isə ucda, x = 2-də (f(2) = 2) əldə olunur - böhran nöqtəsi həmişə parçanın ekstremumu demək deyil, uclar da yoxlanmalıdır.',
  '1, 2, 3', '1, 2, 3, 4', '2, 3, 4', '1, 3', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-arasdirma#4'
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

-- ------------------------------------------------------------- az11-sintaksis-d#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-sintaksis-d#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-sintaksis-d#comb1', 'az-11-sintaksis-d',
  '«Aygün, Vüsal və Kamran sevincindən ağladılar, sonra müəllimlərinə təşəkkür etmək üçün sinfə qayıtdılar» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Aygün, Vüsal və Kamran» həmcins mübtədadır.
2) «Sevincindən ağladılar» hissəsində zərflik səbəb bildirir.
3) «Müəllimlərinə təşəkkür etmək üçün» hissəsi səbəb zərfliyidir.
4) Cümlədə iki fərqli zərflik növü (səbəb və məqsəd) iştirak edir.',
  '1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «təşəkkür etmək üçün» səbəb yox, MƏQSƏD zərfliyidir (nəyə görə deyil, nə üçün sualına cavab verir) - səbəb və məqsəd zərfliyi tez-tez qarışdırılır.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 3, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-sintaksis-d#21'
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

-- ------------------------------------------------------------- ing11-experiences#comb1
update public.questions set difficulty = 2 where ext_key = 'ing11-experiences#8';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing11-experiences#comb1', 'ing-11-experiences',
  'Tom has been to Italy three times. He has gone to Spain now, so he is not here. He arrived in London an hour ago.
Which statements are TRUE?
1) "Tom has been to Italy three times" means Tom is currently in Italy.
2) "He has gone to Spain now" means he is currently away in Spain.
3) "He arrived in London an hour ago" uses Past Simple because "an hour ago" is a specific past time expression.
4) "He arrived in London an hour ago" could correctly be rewritten as "He has arrived in London an hour ago" without changing the meaning.',
  '2 and 3 are true. Statement 1 is wrong - "has been to" means he went and RETURNED, not that he is still there (that is "has gone to"). Statement 4 is wrong - Present Perfect cannot combine with a specific past-time expression like "ago".',
  '2, 3', '1, 2', '1, 3, 4', '2, 3, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing11-experiences#8'
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
  if v_n <> 6 then
    raise exception '112: 6 birlesme sual gozlenilirdi, % tapildi', v_n;
  end if;
  raise notice '112 OK - % birlesme sual', v_n;
end $$;
