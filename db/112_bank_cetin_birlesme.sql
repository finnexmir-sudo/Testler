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
  '1', '1, 3', '2, 4', '1, 2, 3', 2)
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
  '1', '2, 4', '1, 2, 3', '1, 3', 4)
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
  '1, 2, 3, 4', '2, 3, 4', '1, 2, 3', '1, 3', 3)
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
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 3, 4', 2)
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
  '1, 2', '1, 3, 4', '2, 3, 4', '2, 3', 4)
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

-- ------------------------------------------------------------- riy11-inteqral#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-inteqral#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-inteqral#comb1', 'riy-11-inteqral',
  'f(x) = x² − 4 funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) f(x)-in ibtidai funksiyası F(x) = x³/3 − 4x + C-dir.
2) ∫₀² f(x) dx = −16/3-dür.
3) f(x) [0; 2] parçasında mənfi qiymətli olduğu üçün əyri ilə x-oxu arasındakı sahə 16/3-dür.
4) f(x) [0; 2] parçasında müsbət qiymətli olduğu üçün inteqralın nəticəsi birbaşa sahəyə bərabərdir.',
  '1, 2 və 3 doğrudur (F(2) − F(0) = −16/3 − 0 = −16/3, sahə isə əks işarəlisi 16/3-dür). 4-cü mülahizə yanlışdır: f(x) bu parçada mənfi (və ya sıfır) qiymətlidir, müsbət deyil - buna görə inteqral birbaşa sahə vermir, əks işarəli götürülməlidir.',
  '1, 2, 3, 4', '2, 3, 4', '1, 3', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-inteqral#7'
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

-- ------------------------------------------------------------- az11-morfologiya-d#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-morfologiya-d#15';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-morfologiya-d#comb1', 'az-11-morfologiya-d',
  '«Qapı bağlandı. Uşaqlar öpüşdülər. Ana uşağa corabı geydirtdi. Aygün səhər tez yuyundu.» Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Qapı bağlandı» - məchul növdür.
2) «Uşaqlar öpüşdülər» - qarşılıq növdür.
3) «Ana uşağa corabı geydirtdi» - qayıdış növdür.
4) «Aygün səhər tez yuyundu» - qayıdış növdür.',
  '1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «geydirtdi» İCBAR növdür (biri başqasına bir işi gördürür) - qayıdış (məs. «yuyundu») ilə icbar tez-tez qarışdırılır, çünki hər ikisi feilə əlavə şəkilçi qoşulmasıdır.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 3, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-morfologiya-d#15'
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

-- ------------------------------------------------------------- ing11-whys#comb1
update public.questions set difficulty = 2 where ext_key = 'ing11-whys#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing11-whys#comb1', 'ing-11-whys',
  'He passed the exam because of hard studying. Despite the heavy rain, the match continued. As a result of eating too much junk food, she felt sick.
Which statements are TRUE?
1) "He passed the exam because of hard studying" shows a cause-result relationship.
2) "Despite the heavy rain, the match continued" shows a contrast, not a cause.
3) "Despite" and "because of" can both be replaced by "although" without changing the grammar, since all three introduce a reason.
4) "As a result of eating too much junk food, she felt sick" shows a cause-result relationship, like "because of".',
  '1, 2 and 4 are true. Statement 3 is wrong - "despite" shows CONTRAST, not reason like "because of", and "although" needs a clause (subject + verb), not a noun phrase.',
  '1, 3, 4', '1, 2, 4', '1, 2, 3', '2, 3, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing11-whys#28'
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

-- ------------------------------------------------------------- riy11-coxhedli#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-coxhedli#26';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-coxhedli#comb1', 'riy-11-coxhedli',
  'P(x) = x³ − 2x² − 5x + 6 çoxhədlisi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) P(1) = 0-dır.
2) Qalıq teoreminə görə, P(x)-in (x − 1)-ə bölünməsindən qalıq P(1)-ə bərabərdir.
3) 1-ci və 2-ci mülahizələrə əsasən, (x − 1) P(x)-in vuruğudur.
4) P(x)-in (x − 3)-ə bölünməsindən qalıq sıfırdan fərqlidir.',
  '1, 2 və 3 doğrudur (P(1)=1−2−5+6=0, deməli qalıq sıfırdır və (x−1) vuruqdur). 4-cü mülahizə yanlışdır: P(3)=27−18−15+6=0 - yəni (x−3) də vuruqdur, qalıq sıfırdan fərqli deyil, elə sıfırdır.',
  '1, 2, 3, 4', '2, 3', '1, 2, 3', '1, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-coxhedli#26'
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

-- ------------------------------------------------------------- riy11-feza-vektor#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-feza-vektor#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-feza-vektor#comb1', 'riy-11-feza-vektor',
  'a(1; 2; 2) və b(2; 1; −2) vektorları verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) a·b skalyar hasili sıfırdır.
2) Bu vektorlar bir-birinə perpendikulyardır.
3) Eyni zamanda bu vektorlar kollineardır (paraleldir).
4) a vektorunun uzunluğu 3-dür.',
  '1, 2 və 4 doğrudur (a·b=1·2+2·1+2·(−2)=0; |a|=√(1+4+4)=3). 3-cü mülahizə yanlışdır: sıfır olmayan vektorlar eyni zamanda həm perpendikulyar, həm kollinear ola bilməz - bu, bir-birini istisna edən iki vəziyyətdir.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 3, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-feza-vektor#23'
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

-- ------------------------------------------------------------- riy11-limit#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-limit#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-limit#comb1', 'riy-11-limit',
  'g(x) = (x² − 9)/(x − 3) funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) x = 3 nöqtəsində g(x) 0/0 şəklində qeyri-müəyyənlikdir.
2) Bu qeyri-müəyyənlik ifadəni çevirib ixtisar etməklə aradan qaldırılır.
3) lim(x→3) g(x) = 6-dır.
4) g(x) x = 3 nöqtəsində kəsilməzdir, çünki limit mövcuddur və 6-ya bərabərdir.',
  '1, 2 və 3 doğrudur (g(x)=(x−3)(x+3)/(x−3)=x+3, x→3-də → 6). 4-cü mülahizə yanlışdır: g(3) ümumiyyətlə TƏYİN OLUNMAYIB (məxrəc sıfır olur) - limitin mövcudluğu funksiyanın həmin nöqtədə kəsilməz olması demək deyil, bu, aradan qaldırıla bilən kəsilmə nöqtəsidir.',
  '1, 2, 4', '2, 3, 4', '1, 3', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-limit#37'
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

-- ------------------------------------------------------------- riy11-firlanma#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-firlanma#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-firlanma#comb1', 'riy-11-firlanma',
  'Radiusu 3 olan silindr (hündürlüyü 5) və radiusu 3 olan konus (doğuranı 5) verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Silindrin yan səthinin sahəsi 30π-dir.
2) Konusun yan səthinin sahəsi 15π-dir.
3) Silindrin yan səthi konusunkindən 2 dəfə böyükdür.
4) Silindrin radiusu 2 dəfə artırılsa (h sabit qalsa), yeni yan səthi 4 dəfə artıb 120π olar.',
  '1, 2 və 3 doğrudur (2π·3·5=30π, π·3·5=15π, 30π/15π=2). 4-cü mülahizə yanlışdır: yan səthi düsturu 2πrh radiusda XƏTTİDİR - yalnız r 2 dəfə artanda (h sabit qalanda) sahə də cəmi 2 dəfə (60π) artır, 4 dəfə yox.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 3', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-firlanma#37'
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

-- ------------------------------------------------------------- riy11-firlanma-hecm#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-firlanma-hecm#36';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-firlanma-hecm#comb1', 'riy-11-firlanma-hecm',
  'Radiusu 2, hündürlüyü 3 olan silindr verilmişdir (həcmi 12π). Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Radiusu 2 dəfə artırılıb (h sabit qalsa), yeni həcm 48π olar (4 dəfə artıb).
2) Hündürlüyü 2 dəfə artırılıb (r sabit qalsa), yeni həcm 24π olar (2 dəfə artıb).
3) Eyni radiuslu kürənin radiusu 2 dəfə artırılsa, kürənin həcmi 8 dəfə artar.
4) Silindrin radiusu VƏ hündürlüyü hər ikisi 2 dəfə artırılsa, yeni həcm cəmi 2 dəfə artar.',
  '1, 2 və 3 doğrudur (π·4²·3=48π, π·2²·6=24π; kürədə həcm r³-lə mütənasibdir). 4-cü mülahizə yanlışdır: hər iki ölçü birlikdə 2 dəfə artanda təsirlər HASİL olunur (r-in kvadratik təsiri × h-in xətti təsiri = 4×2 = 8 dəfə, 96π), cəmlənmir.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-firlanma-hecm#36'
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

-- ------------------------------------------------------------- riy11-statistika#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-statistika#32';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-statistika#comb1', 'riy-11-statistika',
  'A və B asılı olmayan hadisələrdir, P(A) = 0,6 və P(B) = 0,5. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ā (A-nın əksi) hadisəsinin ehtimalı 0,4-dür.
2) A və B-nin birgə baş vermə ehtimalı 0,3-dür.
3) Ā və B̄-nin birgə baş verməmə ehtimalı 0,2-dir.
4) A və B-nin birgə baş vermə ehtimalı onların cəmi ilə (0,6+0,5=1,1) tapılır.',
  '1, 2 və 3 doğrudur (P(Ā)=0,4; P(A∩B)=0,6·0,5=0,3; P(Ā∩B̄)=0,4·0,5=0,2). 4-cü mülahizə yanlışdır: birgə (VƏ) ehtimalı HASİLLƏ tapılır, cəmlə yox - üstəlik 1,1 ehtimal üçün mümkün olmayan qiymətdir (ehtimal 0 ilə 1 arasında olmalıdır).',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-statistika#32'
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

-- ------------------------------------------------------------- riy11-tenlikler#comb1
update public.questions set difficulty = 2 where ext_key = 'riy11-tenlikler#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy11-tenlikler#comb1', 'riy-11-tenlikler',
  '√(x − 2) = x − 4 tənliyi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Tənliyi kvadrata yüksəltdikdən sonra x² − 9x + 18 = 0 alınır.
2) Bu kvadrat tənliyin kökləri x = 6 və x = 3-dür.
3) x = 6 əsl tənliyin kökü deyil, kənar kökdür.
4) x = 3 əsl tənliyin kökü deyil, kənar kökdür.',
  '1, 2 və 4 doğrudur (x=3-də √1=1, sağ tərəf isə 3−4=−1, uyğun gəlmir - kənar kök). 3-cü mülahizə yanlışdır: x=6 əslində DÜZGÜN kökdür (√4=2, sağ tərəf 6−4=2, uyğun gəlir) - hər kvadrat kök AYRICA yoxlanmalıdır, biri kənar çıxsa digəri də kənar olmalı deyil.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 3, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy11-tenlikler#22'
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

-- ------------------------------------------------------------- az11-fonetika-leksika#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-fonetika-leksika#13';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-fonetika-leksika#comb1', 'az-11-fonetika-leksika',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Əsr - əsir» cütü paronimdir.
2) «Baş» sözünün «dağın başı», «işin başı» mənaları omonimlikdir.
3) «Gül» sözünün (çiçək / gülmək əmri) iki mənası omonimlikdir.
4) Paronim, çoxmənalılıq və omonimlik eyni hadisədir - hamısı sözlərin səs baxımından üst-üstə düşməsini bildirir.',
  '1 və 3 doğrudur. 2-ci mülahizə yanlışdır: «baş»ın mənaları ÇOXMƏNALILIQDIR (eyni sözün əlaqəli mənaları), omonim isə əlaqəsiz mənalı sözlərdir (məs. «gül»). 4-cü mülahizə yanlışdır: bu, üç fərqli hadisədir, eyni deyil.',
  '1, 2', '2, 3, 4', '1, 2, 3', '1, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-fonetika-leksika#13'
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

-- ------------------------------------------------------------- az11-soz-yaradiciligi#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-soz-yaradiciligi#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-soz-yaradiciligi#comb1', 'az-11-soz-yaradiciligi',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Yazıçı» sözü quruluşca düzəltmə sözdür.
2) «Yazıçılar» sözü (yazıçı + -lar) də quruluşca düzəltmə sözdür, çünki -lar şəkilçisi yeni leksik məna yaratmır.
3) «Günəbaxanlar» sözü (günəbaxan + -lar) quruluşca artıq mürəkkəb söz deyil, sadə söz olur, çünki -lar əlavə olunub.
4) Bir sözün quruluşca növünü (sadə/düzəltmə/mürəkkəb) yalnız leksik (yeni məna yaradan) şəkilçilər müəyyən edir, qrammatik şəkilçilər (cəm, hal və s.) yox.',
  '1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «günəbaxanlar» da hələ MÜRƏKKƏB sözdür - -lar qrammatik şəkilçisi (4-cü mülahizənin qaydasına görə) sözün quruluşca növünü dəyişmir, eynilə «yazıçılar»ın da düzəltmə qalması kimi.',
  '1, 2, 3', '2, 3, 4', '1, 2, 4', '1, 3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-soz-yaradiciligi#29'
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

-- ------------------------------------------------------------- az11-uslubiyyat#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-uslubiyyat#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-uslubiyyat#comb1', 'az-11-uslubiyyat',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Aslan kimi döyüşdü» ifadəsində bənzətmə (təşbeh) var, çünki «kimi» sözü ilə açıq müqayisə edilir.
2) Əgər «kimi» sözü çıxarılıb (əsgəri nəzərdə tutaraq) «Aslan döyüşdü» deyilsəydi, bu artıq metafora olardı, çünki metafora da oxşarlığa əsaslanır, amma gizli müqayisədir.
3) «Zalın gurultulu alqışları» ifadəsindəki «zal» sözü də metaforadır, çünki bu da oxşarlığa əsaslanır.
4) Bənzətmə və metafora eyni əsasa (oxşarlığa) söykənir, amma bənzətmə açıq müqayisə («kimi»), metafora isə gizli müqayisədir.',
  '1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «zal» sözü METONİMİYADIR (zal - orada oturan tamaşaçılar arasındakı ƏLAQƏ, yəni yerlə insan arasında əlaqə əsasında), oxşarlığa yox.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 3, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-uslubiyyat#23'
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

-- ------------------------------------------------------------- az11-metn-tehlili#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-metn-tehlili#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-metn-tehlili#comb1', 'az-11-metn-tehlili',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Bakı Azərbaycanın paytaxtıdır» faktdır, çünki yoxlanıla bilər.
2) «Bakı dünyanın ən gözəl şəhəridir» şərhdir (rəydir), çünki subyektivdir.
3) «Bakının əhalisi 2 milyondan çoxdur» cümləsi də faktdır, çünki bu, yoxlanıla bilən məlumatdır.
4) «Bakı ən yaxşı şəhərdir, çünki mən orada doğulmuşam» cümləsi fakt sayılır, çünki səbəb göstərilib.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: bir subyektiv iddiaya (rəyə) SƏBƏB əlavə etmək onu FAKTA çevirmir - fakt olmaq üçün müstəqil yoxlanıla bilməlidir, müəllifin şəxsi əsaslandırması kifayət deyil.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-metn-tehlili#9'
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

-- ------------------------------------------------------------- az11-isguzar#comb1
update public.questions set difficulty = 2 where ext_key = 'az11-isguzar#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az11-isguzar#comb1', 'az-11-isguzar',
  '«Direktor cənab X-ə. Xahiş edirəm mənə 3 gün məzuniyyət verəsiniz. Ad-soyad, tarix, imza.» nümunə ərizəsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bu ərizə düzgün başlayır, çünki ünvanlanan şəxsin adı və vəzifəsi ilə başlayıb.
2) «Xahiş edirəm mənə 3 gün məzuniyyət verəsiniz» cümləsi ərizə üçün səciyyəvi rəsmi qəlibdir.
3) Ərizənin sonunda tarix və imza olması mütləqdir.
4) Ərizə mətnində «Öpürəm, hörmətlə gözləyirəm» kimi isti münasibət ifadə edən sözlərin işlədilməsi işgüzar üslub baxımından məqbuldur.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: işgüzar sənəddə rəsmi qəliblər qəbul olunub («Xahiş edirəm...»), əzizləmə formaları («Öpürəm») yox - bu, üslub səhvidir.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az11-isguzar#28'
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

-- ------------------------------------------------------------- ing11-conversation#comb1
update public.questions set difficulty = 2 where ext_key = 'ing11-conversation#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing11-conversation#comb1', 'ing-11-conversation',
  'Ali said, "I am tired now." Later he said, "I saw this film yesterday here." His teacher told him, "Do not be late."
Which statements are TRUE?
1) The reported form of "I am tired now" is "Ali said that he was tired then."
2) The reported form of "I saw this film yesterday here" is "Ali said he had seen this film the day before there."
3) The reported form of "Do not be late" is "The teacher told him not to be late."
4) The reported form of "I saw this film yesterday here" could also correctly keep "yesterday" and "here" unchanged, since the meaning stays clear either way.',
  '1, 2 and 3 are true. Statement 4 is wrong - time and place words like "yesterday"/"here" are deictic and MUST shift in reported speech (to "the day before"/"there") when the reporting happens at a different time or place.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing11-conversation#22'
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

-- ------------------------------------------------------------- ing11-creativity#comb1
update public.questions set difficulty = 2 where ext_key = 'ing11-creativity#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing11-creativity#comb1', 'ing-11-creativity',
  'Which statements are TRUE?
1) "This picture was painted by a young artist" is PASSIVE VOICE - the picture itself received the action.
2) "She had her portrait painted last month" is a CAUSATIVE construction - it means she arranged for someone else to paint it, she did not paint it herself.
3) Since both sentences use a past participle after "be/have", passive and causative are grammatically the same structure.
4) "The concert hall was built two years ago" uses passive voice, just like "This picture was painted by a young artist."',
  '1, 2 and 4 are true. Statement 3 is wrong - despite the surface similarity (a participle after "be/have"), passive ("be + V3", subject RECEIVES the action) and causative ("have + object + V3", subject ARRANGES the action) are different structures with different meanings.',
  '1, 2, 3', '2, 3, 4', '1, 2, 4', '1, 3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing11-creativity#19'
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

-- ------------------------------------------------------------- ing11-news#comb1
update public.questions set difficulty = 2 where ext_key = 'ing11-news#13';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing11-news#comb1', 'ing-11-news',
  'Which statements are TRUE?
1) "It is reported that the president will visit tomorrow" and "The earthquake is reported to have destroyed hundreds of homes" are both passive reporting structures, but grammatically different: the first uses "It is reported THAT + clause", the second uses "SUBJECT is reported TO HAVE + V3".
2) "The company is said to be building a new factory" uses "to be + V-ing" because the action is ONGOING.
3) "The bridge is believed to have been damaged in the storm" uses "to have been + V3" because the action happened BEFORE the reporting, i.e. it is already completed.
4) Since "is reported to have destroyed" and "is said to be building" both use a "to + verb" pattern, they describe the SAME time relationship.',
  '1, 2 and 3 are true. Statement 4 is wrong - "to have destroyed" (perfect infinitive = COMPLETED action) and "to be building" (continuous infinitive = ONGOING action) express different time relationships, despite the surface "to + verb" similarity.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing11-news#13'
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

-- ------------------------------------------------------------- riy10-funksiya#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-funksiya#34';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-funksiya#comb1', 'riy-10-funksiya',
  'f(x) = x³ və g(x) = 1/x funksiyaları verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) f(x) = x³ təkdir.
2) g(x) = 1/x təkdir.
3) h(x) = f(x) + g(x) = x³ + 1/x funksiyası da təkdir, çünki iki tək funksiyanın cəmi yenə təkdir.
4) k(x) = x³ + 1 funksiyası da təkdir, çünki tək funksiyaya (x³) sadəcə ədəd əlavə olunub.',
  '1, 2 və 3 doğrudur (h(−x)=−h(x) hər zaman ödənir). 4-cü mülahizə yanlışdır: k(−x)=−x³+1, bu nə k(x)=x³+1-ə, nə də −k(x)=−x³−1-ə bərabərdir - sabit əlavə etmək tək funksiyanın simmetriyasını pozur, k(x) nə cüt, nə təkdir.',
  '1, 2, 3, 4', '1, 2, 3', '2, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-funksiya#34'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-feza#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-feza#30';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-feza#comb1', 'riy-10-feza',
  'Nöqtə A-dan müstəviyə perpendikulyar AH = 5 sm-dir (H - əsas). Müstəvi üzərində B və C nöqtələri var, HB = HC = 12 sm. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) AB mailinin uzunluğu 13 sm-dir.
2) HB = HC olduğu üçün AC mailinin uzunluğu da 13 sm-dir.
3) Bərabər maillərin (AB=AC=13) proyeksiyaları da bərabərdir (HB=HC=12).
4) AB mail AH perpendikulyarından qısadır.',
  '1, 2 və 3 doğrudur (Pifaqor: √(5²+12²)=13). 4-cü mülahizə yanlışdır: mail (13 sm) həmişə perpendikulyardan (5 sm) UZUNDUR, əksinə deyil - bu, üç perpendikulyar teoreminin əsas nəticəsidir.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-feza#30'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-triq-ifade#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-triq-ifade#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-triq-ifade#comb1', 'riy-10-triq-ifade',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) sin(90° − 30°) = cos 30° (çevirmə düsturuna görə).
2) sin(180° − 30°) = sin 30° (çevirmə düsturuna görə).
3) sin(−30°) = −sin(180° − 30°), çünki hər ikisi −sin 30°-a bərabərdir.
4) sin(90° − 30°) və sin(180° − 30°) eyni qiymətdədir, çünki hər ikisi "sin"-dən başlayır.',
  '1, 2 və 3 doğrudur (sin(−30°)=−0,5=−sin(180°−30°)=−0,5). 4-cü mülahizə yanlışdır: sin(90°−30°)=cos30°≈0,866, sin(180°−30°)=sin30°=0,5 - fərqli qiymətlərdir, çünki fərqli çevirmə düsturları tətbiq olunur.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-triq-ifade#27'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-sinus-kosinus#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-sinus-kosinus#35';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-sinus-kosinus#comb1', 'riy-10-sinus-kosinus',
  'Üçbucaqda a = 5, b = 8, C = 60° verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) c tərəfi 7-yə bərabərdir.
2) a² + b² (=89) c²-dən (=49) böyükdür.
3) 2-ci mülahizəyə əsasən, C bucağı itidir.
4) Əgər C bucağı dəyişib 90° olsaydı (a, b sabit qalsa), c yenə də 7 olardı, çünki c yalnız a və b-dən asılıdır.',
  '1, 2 və 3 doğrudur (kosinuslar teoremi: c²=25+64−2·5·8·0,5=49). 4-cü mülahizə yanlışdır: c bucaq C-dən DƏ asılıdır (−2ab·cosC həddi) - C=90° olsaydı c²=a²+b²=89, c=√89≈9,43 olardı, 7 yox.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-sinus-kosinus#35'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-triq-qrafik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-triq-qrafik#33';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-triq-qrafik#comb1', 'riy-10-triq-qrafik',
  'y = 2 sin(2x) + 1 funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Funksiyanın amplitudu 2-dir.
2) Funksiyanın ən kiçik müsbət dövrü π-dir (arqumentdəki 2 əmsalına görə).
3) Funksiyanın qrafiki y = sin x qrafikinə nisbətən 1 vahid yuxarı sürüşdürülüb.
4) Funksiyanın ən böyük qiyməti 2-dir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ən böyük qiymət amplitud VƏ şaquli sürüşmənin cəmidir (2·1+1=3), amplitudun özü (2) deyil.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-triq-qrafik#33'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-coxuzlu#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-coxuzlu#31';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-coxuzlu#comb1', 'riy-10-coxuzlu',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Tili 5 sm olan kubun tam səthinin sahəsi 150 sm²-dir (6·5²).
2) Ölçüləri 4, 4 və 7 sm olan paralelepipedin diaqonalı 9 sm-dir (√(4²+4²+7²)).
3) Kub da xüsusi paralelepipeddir (bütün ölçülər bərabərdir), buna görə tili 5 olan kubun diaqonalı √(5²+5²+5²)=5√3 sm-dir.
4) Tili 5 olan kubun diaqonalı da 9 sm-dir, çünki bütün paralelepipedlərin diaqonalı ölçülərdən asılı olmayaraq eynidir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: diaqonal ölçülərdən birbaşa asılıdır (düstur bunu göstərir) - tili 5 olan kubun diaqonalı 5√3≈8,66 sm-dir, 9 sm deyil (9 yalnız 4,4,7 ölçülü fərqli paralelepiped üçündür).',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-coxuzlu#31'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-triq-tenlik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-triq-tenlik#33';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-triq-tenlik#comb1', 'riy-10-triq-tenlik',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) arcsin(1/2) = π/6-dır.
2) arcsin(−1/2) = −π/6-dır (çünki arcsin(−a) = −arcsin a).
3) arccos(1/2) = π/3-dür.
4) arccos(−1/2) = −π/3-dür, çünki arccos da arcsin kimi eyni "əksini götür" qaydasını izləyir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: arccos FƏRQLİ qaydaya tabedir - arccos(−a) = π − arccos(a), yəni arccos(−1/2) = π − π/3 = 2π/3, −π/3 deyil.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-triq-tenlik#33'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-hecm#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-hecm#31';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-hecm#comb1', 'riy-10-hecm',
  'Ölçüləri 40, 30 və 50 sm olan akvariumun tutumu 60 litrdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bütün ölçüləri 2 dəfə böyüdülmüş oxşar akvariumun (80,60,100 sm) tutumu 480 litr olar.
2) Bu, birbaşa hesabla da yoxlanıla bilər: 80·60·100=480000 sm³=480 L.
3) Nəticə xətti ölçülərin 2 dəfə artması qaydasına uyğundur (həcm 8 dəfə artır).
4) Bütün ölçüləri 2 dəfə böyüdülmüş akvariumun tutumu 120 litr olar, çünki hər ölçü 2 dəfə artıb, tutum da cəmi 2 dəfə artır.',
  '1, 2 və 3 doğrudur (40·30·50=60000, 80·60·100=480000, nisbət=8). 4-cü mülahizə yanlışdır: hər 3 ölçü birlikdə 2 dəfə artanda həcm 2³=8 dəfə (xətti yox, KUBİK) artır, cəmi 2 dəfə yox.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-hecm#31'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-ustlu-loqarifm#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-ustlu-loqarifm#33';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-ustlu-loqarifm#comb1', 'riy-10-ustlu-loqarifm',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) log₂ 8 = 3 (çünki 2³=8).
2) log₂ 32 = 5 (çünki 2⁵=32).
3) log₂ x = 5 tənliyinin kökü x=32-dir (2-ci mülahizənin tərs əməliyyatıdır).
4) 4ˣ = 2 tənliyinin kökü x=2-dir, çünki 4=2·2 münasibətinə görə 2 dəfə vurmaq lazımdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 4ˣ=2 → (2²)ˣ=2¹ → 2x=1 → x=1/2-dir, 2 deyil - «4=2·2» münasibəti tənliyin həllinə birbaşa tətbiq edilə bilməz.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-ustlu-loqarifm#33'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy10-statistika#comb1
update public.questions set difficulty = 2 where ext_key = 'riy10-statistika#33';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy10-statistika#comb1', 'riy-10-statistika',
  'Simmetrik sikkə 3 dəfə atılır (uğur=gerb, p=1/2). Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bernulli düsturuna görə, düz 2 dəfə gerb düşmə ehtimalı P=C(3,2)·(1/2)²·(1/2)¹ şəklində hesablanır.
2) C(3,2)=3 olduğu üçün, bu ehtimal P=3/8-dir.
3) Hər 3-də də gerb düşmə ehtimalı C(3,3)·(1/2)³·(1/2)⁰=1/8-dir.
4) 3/8 ehtimalı 1/8-dən kiçikdir, çünki daha çox uğur əldə etmək həmişə daha az ehtimallıdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 3/8 (0,375) əslində 1/8-dən (0,125) BÖYÜKDÜR - «daha çox uğur həmişə daha az ehtimallıdır» ümumiləşdirməsi yanlışdır, burada 2 uğur (k=2) elə ən ehtimallı nəticədir.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy10-statistika#33'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-dil-unsiyyet#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-dil-unsiyyet#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-dil-unsiyyet#comb1', 'az-10-dil-unsiyyet',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Azərbaycan dili mənşəyinə görə türk dilləri qrupuna daxildir.
2) Dil sistemdir, nitq onun tətbiqidir - bu, dil ilə nitq arasındakı fərqdir.
3) Ədəbi dil normalara tabe olan ümumxalq dili formasıdır, dialekt isə müəyyən bölgəyə xas yerli qoldur.
4) Dialekt ədəbi dilin başqa adıdır, ikisi eyni şeyi bildirir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ədəbi dil (normativ, ümumxalq) və dialekt (yerli, qeyri-normativ) iki FƏRQLİ formadır, eyni şey deyil.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-dil-unsiyyet#10'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-fonetika-tekrar#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-fonetika-tekrar#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-fonetika-tekrar#comb1', 'az-10-fonetika-tekrar',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Alma» (meyvə) ilə «alma» (əmr) sözlərini tələffüzdə vurğunun yeri fərqləndirir.
2) «Ton» ilə «don» sözlərini isə vurğu yox, ilk samitin kar-cingiltili olması fərqləndirir.
3) Bu iki cüt söz eyni fonetik mexanizmlə (vurğu ilə) fərqlənir.
4) «Kitab» sözü [kitap] kimi tələffüz olunur, çünki söz sonunda cingiltili samit karlaşır.',
  '1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: bu iki cüt söz FƏRQLİ mexanizmlərlə fərqlənir - «alma/alma» vurğu ilə, «ton/don» isə samitin kar-cingiltili olması ilə.',
  '1, 2, 3', '2, 3, 4', '1, 2, 4', '1, 3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-fonetika-tekrar#29'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-leksika#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-leksika#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-leksika#comb1', 'az-10-leksika',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Qızıl üzük» birləşməsində «qızıl» sözü həqiqi mənada işlənib.
2) «Qızıl ürək» birləşməsində isə «qızıl» sözü məcazi mənadadır.
3) Bu iki məna (üzük/ürək) əlaqəlidir (hər ikisi «dəyərli» ideyasından qaynaqlanır), buna görə bu, ÇOXMƏNALILIQ nümunəsidir, omonimlik deyil.
4) «Bal» (şirin qida) və «bal» (rəqs gecəsi) sözləri də eyni səbəbdən çoxmənalılığa misaldır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «bal/bal»-ın iki mənası ƏLAQƏSİZDİR - bu, OMONİMLİKDİR, çoxmənalılıq deyil.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-leksika#16'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-uslub#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-uslub#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-uslub#comb1', 'az-10-uslub',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ərizə, protokol, arayış rəsmi-işgüzar üslubda yazılır.
2) Nağıl və dastanlar isə bədii üslubun nümunəsidir.
3) Rəsmi sənəddə «görüşənədək, öpürəm» kimi ifadələr yazmaq üslub uyğunsuzluğu yaradır, çünki bu, məişət üslubuna aiddir.
4) Nağıl mətnində rəsmi-işgüzar üslubun leksik vasitələrindən istifadə etmək də normal sayılır, çünki bütün üslublar bir-birini əvəz edə bilər.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: üslublar bir-birini əvəz etmir - bədii mətndə rəsmi-işgüzar leksika işlətmək də, rəsmi sənəddə məişət ifadəsi işlətmək qədər uyğunsuzdur.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-uslub#24'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-morfologiya-t#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-morfologiya-t#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-morfologiya-t#comb1', 'az-10-morfologiya-t',
  '«Oxuyan şagird kitabı gələndə gətirdi» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Oxuyan» feili sifətdir (şagirdin əlamətini bildirir).
2) «Gələndə» feili bağlamadır (əsas hərəkətin zamanını bildirir).
3) Hər ikisi feildən əmələ gəlib, amma «oxuyan» isim üçün TƏYİN, «gələndə» isə ZƏRFLİK vəzifəsindədir.
4) «Oxuyan» sözü də «gələndə» kimi feili bağlamadır, çünki hər ikisi feildən düzəlib.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: eyni köklə (feillə) bağlı olmaq eyni FORMA olmaq demək deyil - «oxuyan» feili SİFƏTDİR, feili bağlama yox.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-morfologiya-t#28'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-sintaksis-t#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-sintaksis-t#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-sintaksis-t#comb1', 'az-10-sintaksis-t',
  '«Qırmızı almanı qardaşıma bağçada verdim» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Qırmızı» təyindir.
2) «Qardaşıma» tamamlıqdır.
3) «Bağçada» yer zərfliyidir.
4) «Almanı» sözü mübtədadır, çünki cümlədə əşya kimi ilk qeyd olunan isimdir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «almanı» sözü tamamlıqdır (təsirlik hal şəkilçisi -nı ilə) - cümlədə İLK qeyd olunması onu mübtəda etmir, hal şəkilçisi onun üzvünü müəyyən edir.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-sintaksis-t#28'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-metn#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-metn#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-metn#comb1', 'az-10-metn',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Mətnin klassik quruluşu giriş, əsas hissə və nəticədən ibarətdir.
2) Əsas hissədə mövzunun geniş açıqlanması yerləşir.
3) Nəticə hissəsində isə fikrin ümumiləşdirilməsi olur, yeni mövzu başlanmır.
4) «Əvvəlcə, sonra, nəhayət» sözləri nəticə hissəsində yeni mövzunun başlandığını göstərən əlamətdir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «əvvəlcə, sonra, nəhayət» ARDICILLIĞI göstərir, yeni mövzunun başlanmasını yox - üstəlik nəticə hissəsində yeni mövzu ümumiyyətlə başlanmamalıdır.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-metn#29'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- az10-nitq-medeni#comb1
update public.questions set difficulty = 2 where ext_key = 'az10-nitq-medeni#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az10-nitq-medeni#comb1', 'az-10-nitq-medeni',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Deməli, yəni, zad» kimi sözlərin tez-tez təkrarı zəif nitqin (tüfeyli sözlərin) əlamətidir.
2) Nitq zamanı pauzalar isə fikri ayırıb diqqəti cəmləməyə xidmət edir - faydalı vasitədir.
3) Deməli, natiq fikrini toplamaq üçün pauza verməklə tüfeyli söz işlətməkdən daha yaxşı edər.
4) Tüfeyli sözlər və pauzalar eyni funksiyanı daşıyır - ikisi arasında fərq yoxdur.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: hər ikisi natiqin fikrini toplaması üçün vaxt qazandırsa da, tüfeyli sözlər ZƏİF nitqin, pauzalar isə FAYDALI bir vasitənin əlamətidir.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az10-nitq-medeni#27'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- ing10-kindness#comb1
update public.questions set difficulty = 2 where ext_key = 'ing10-kindness#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing10-kindness#comb1', 'ing-10-kindness',
  'Which statements are TRUE?
1) "who" is used because "man" is a person, as in "The man who helped me carry the bags."
2) "where" is used because "town" is a place, as in "This is the town where I was born."
3) "why" is used because "reason" needs a reason-relative-pronoun, as in "The reason why she helps others."
4) All three relative pronouns (who, where, why) could be replaced by "which" without changing correctness, since "which" is the general-purpose relative pronoun for everything.',
  '1, 2 and 3 are true. Statement 4 is wrong - "which" is specifically used for THINGS, not people, places, or reasons - replacing "who"/"where"/"why" with "which" would be ungrammatical.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing10-kindness#19'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- ing10-victory#comb1
update public.questions set difficulty = 2 where ext_key = 'ing10-victory#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing10-victory#comb1', 'ing-10-victory',
  'Which statements are TRUE?
1) "We stayed at home because it was raining heavily" uses "because" + a clause (subject+verb).
2) "The roads were closed because of the heavy snow" uses "because of" + a noun phrase, not a clause.
3) "Although he was tired, he continued the mission" uses "although" to show CONTRAST, not cause.
4) "Because" and "because of" can be used interchangeably in both sentences above, since they mean the same thing.',
  '1, 2 and 3 are true. Statement 4 is wrong - "because" needs a clause and "because of" needs a noun phrase; swapping them makes the sentence ungrammatical, even though they express a similar idea.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing10-victory#18'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- ing10-cultures#comb1
update public.questions set difficulty = 2 where ext_key = 'ing10-cultures#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing10-cultures#comb1', 'ing-10-cultures',
  'Which statements are TRUE?
1) "Despite the rain, the open-air concert continued" uses "despite" + a noun phrase.
2) "Despite being far away, she joined the family holiday online" uses "despite" + a gerund phrase.
3) "Even though he lives abroad, he keeps his traditions" uses "even though" + a full clause (subject+verb).
4) "Despite" and "Even though" are grammatically interchangeable everywhere, since "despite he lives abroad" would also be correct.',
  '1, 2 and 3 are true. Statement 4 is wrong - "despite" cannot be directly followed by a clause with subject+verb ("despite he lives abroad" is ungrammatical); only "even though" can.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing10-cultures#14'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- ing10-environment#comb1
update public.questions set difficulty = 2 where ext_key = 'ing10-environment#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing10-environment#comb1', 'ing-10-environment',
  'Which statements are TRUE?
1) "I have finished my homework already" uses Present Perfect Simple, emphasising a COMPLETED action with a present result.
2) "It has been raining since Monday" uses Present Perfect Continuous, emphasising the ONGOING duration of the action.
3) Both sentences connect a past action to the present moment, unlike Past Simple, which only describes a finished past action.
4) Since both are Present Perfect forms, "have finished" and "has been raining" mean exactly the same thing: a completed action with no ongoing process.',
  '1, 2 and 3 are true. Statement 4 is wrong - Present Perfect Simple (completion) and Present Perfect Continuous (ongoing duration) express different meanings, despite both being "Present Perfect".',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing10-environment#28'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- ing10-success#comb1
update public.questions set difficulty = 2 where ext_key = 'ing10-success#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing10-success#comb1', 'ing-10-success',
  'Which statements are TRUE?
1) "She said she had read the book before the exam" uses Past Perfect because the reading happened before another past point.
2) "After she had completed the course, she found a good job" also uses Past Perfect, because completing came before finding the job.
3) "The bridge had been built by 1950" uses Past Perfect Passive, showing completion before a past deadline.
4) In all three sentences, "had + V3" could be replaced by Simple Past forms without any change in meaning.',
  '1, 2 and 3 are true. Statement 4 is wrong - Past Perfect specifically marks which of two past events happened FIRST; replacing it with Simple Past loses that clear sequencing.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing10-success#17'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- ing10-media#comb1
update public.questions set difficulty = 2 where ext_key = 'ing10-media#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing10-media#comb1', 'ing-10-media',
  'Which statements are TRUE?
1) "She said that she was tired" reports a STATEMENT, using backshift (is → was).
2) "The teacher asked us to be quiet" reports a COMMAND, using the infinitive form ("to be").
3) "Mum asked me if I had done my homework" reports a YES/NO QUESTION, using "if" instead of a question word.
4) Since all three sentence types (statement, command, question) are being "reported", they all use the same grammatical pattern ("asked/told/said + that + clause").',
  '1, 2 and 3 are true. Statement 4 is wrong - reported statements use "said/told that + clause", reported commands use "told/asked + object + infinitive" (no "that"), and reported yes/no questions use "asked + if/whether + clause" - three different patterns, not one.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing10-media#28'
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
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- riy9-kok#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-kok#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-kok#comb1', 'riy-9-kok',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) √12 sadələşəndə 2√3 alınır (√12=√(4·3)=2√3).
2) √27 sadələşəndə 3√3 alınır (eyni üsulla, fərqli ədədlə: √27=√(9·3)=3√3).
3) Bu iki nəticəni toplasaq, √12+√27=2√3+3√3=5√3 alınır.
4) Eyni cəmi kökləri əvvəlcə toplayıb (12+27=39), sonra kökünü alaraq (√39) da tapmaq olar - bu da 5√3-ə bərabər nəticə verər.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: √a+√b ≠ √(a+b) - √39≈6,24, 5√3≈8,66, fərqli ədədlərdir. Kökləri əvvəlcə toplayıb sonra kök almaq səhv üsuldur.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-kok#18'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-cevre#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-cevre#38';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-cevre#comb1', 'riy-9-cevre',
  'Çevrənin uzunluğu 20π sm-dir, bu çevrədə 72°-lik qövs verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Çevrənin radiusu 10 sm-dir (uzunluq=2πr, 20π=2πr → r=10).
2) 1-ci addımdakı radiusu l=πrα/180 düsturuna yazsaq, 72°-lik qövsün uzunluğu l=4π sm olar.
3) Bu 72°-lik qövsə söykənən daxilə çəkilmiş bucaq 36°-dir (daxilə çəkilmiş bucaq=qövsün yarısı).
4) Əgər qövs 72°-dən 144°-yə (2 dəfə) böyüsə, ona söykənən daxilə çəkilmiş bucaq da 2 dəfə artar, qövsün uzunluğu isə 4 dəfə artar.',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə yanlışdır: qövs uzunluğu düsturu (l=πrα/180) α-da XƏTTİDİR - qövs 2 dəfə artanda uzunluq da CƏMİ 2 dəfə (4 dəfə yox) artır, eynilə daxilə çəkilmiş bucaq kimi.',
  '1, 2, 3, 4', '2, 3, 4', '1, 3', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-cevre#38'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-funksiya#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-funksiya#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-funksiya#comb1', 'riy-9-funksiya',
  'y = x² − 6x + 5 funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Funksiyanın simmetriya oxu x=3-dür (x=−b/2a=6/2=3).
2) Funksiyanın sıfırları x=1 və x=5-dir.
3) 1-ci və 2-ci mülahizələrə əsasən, simmetriya oxu iki sıfırın dəqiq orta nöqtəsindən keçir ((1+5)/2=3).
4) Funksiyanın təpə nöqtəsinin ordinatı (y qiyməti) sıfırdır, çünki təpə simmetriya oxu üzərindədir.',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı: f(1)=f(5)=0, midpoint=3). 4-cü mülahizə yanlışdır: təpə nöqtəsi simmetriya oxu ÜZƏRİNDƏDİR (x=3), amma bu, absis oxunu (y=0) kəsdiyi demək deyil - f(3)=−4-dür, sıfır yox.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-funksiya#37'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-cevre-tenliyi#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-cevre-tenliyi#35';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-cevre-tenliyi#comb1', 'riy-9-cevre-tenliyi',
  'M(9; 12) nöqtəsi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) M-in başlanğıcdan uzaqlığı 15 vahiddir (9²+12²=225=15²).
2) 1-ci addıma əsasən, M nöqtəsi mərkəzi başlanğıcda, radiusu 15 olan çevrənin (x²+y²=225) üzərindədir.
3) Bu çevrədə M-ə uyğun bucaq üçün cos α=9/15=0,6, sin α=12/15=0,8-dir.
4) cos α=0,6 olduğu üçün, cos²α=0,64-dür (#24-dəki eyni ədədi nəticəni tətbiq edərək).',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə yanlışdır: cos²α=0,6²=0,36-dır - 0,64 fərqli bir bank sualında (sin α=0,6 verildikdə) alınan cavabdır, birbaşa köçürülə bilməz.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-cevre-tenliyi#35'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-tenlikler#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-tenlikler#39';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-tenlikler#comb1', 'riy-9-tenlikler',
  'x⁴ − 5x² + 4 = 0 tənliyi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bu, bikvadrat tənlikdir (yalnız cüt qüvvətlər iştirak edir).
2) t=x² əvəzləməsi aparsaq, t²−5t+4=0 tənliyi alınır ki, bu da (t−1)(t−4)=0 kimi vuruqlara ayrılır - deməli t=1 və ya t=4.
3) 2-ci addımdakı t qiymətlərini geri x²-ə qaytarsaq (x²=1 və x²=4), tənliyin kökləri x=±1 və x=±2 olur.
4) Tənliyin bütün köklərinin (±1, ±2) cəmi 6-dır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ±1 və ±2-nin cəmi 1−1+2−2=0-dır, 6 yox - simmetrik köklər (+ və −) bir-birini ləğv edir.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-tenlikler#39'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-coxbucaqli#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-coxbucaqli#39';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-coxbucaqli#comb1', 'riy-9-coxbucaqli',
  'Tərəfi 6 sm olan kvadrat verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Kvadratın daxilinə çəkilmiş çevrənin radiusu 3 sm-dir (radius=tərəf/2).
2) Kvadratın diaqonalı 6√2 sm-dir (Pifaqor: √(6²+6²)=6√2).
3) 2-ci addımdakı diaqonaldan istifadə etsək, xaricinə çəkilmiş çevrənin radiusu 3√2 sm olur (radius=diaqonal/2).
4) Xarici çevrənin radiusu daxili çevrənin radiusundan 2 dəfə böyükdür.',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə yanlışdır: 3√2/3=√2≈1,41-dir, 2 dəfə yox - bu nisbət hər kvadratda √2-dir (2 deyil).',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-coxbucaqli#39'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-berabersizlik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-berabersizlik#39';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-berabersizlik#comb1', 'riy-9-berabersizlik',
  '(x−2)(x−6)<0 bərabərsizliyi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Uyğun tənliyin kökləri x=2 və x=6-dır.
2) Bu köklərə əsasən, (x−2)(x−6) ifadəsi 2<x<6 aralığında mənfi, xaricində isə müsbətdir.
3) Deməli (x−2)(x−6)<0 bərabərsizliyinin həlli 2<x<6 aralığıdır (uc nöqtələr daxil deyil).
4) Bu aralığa (x=2 daxil olmaqla) düşən tam ədədlərin sayı 4-dür (2, 3, 4, 5).',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə yanlışdır: x=2-də ifadə sıfırdır (mənfi deyil), buna görə strict bərabərsizliyin həllinə daxil olmur - düz say 3-dür (3, 4, 5).',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-berabersizlik#39'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-vektorlar#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-vektorlar#40';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-vektorlar#comb1', 'riy-9-vektorlar',
  'a(1; 3) və b(2; −1) vektorları verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) a+b cəminin koordinatları (3; 2)-dir.
2) 1-ci addımdakı nəticəyə əsasən, |a+b|=√(3²+2²)=√13-dür.
3) Əgər a və b vektorları perpendikulyar olsaydı, |a+b|²=|a|²+|b|² olardı.
4) 1-ci addımdakı (3; 2) vektorunun modulu 5-dir, çünki (3; 4) vektorunun modulu 5 olduğu kimi bu da eynidir.',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı: |a+b|=√13≈3,6). 4-cü mülahizə yanlışdır: (3; 2) vektoru (3; 4) vektorundan FƏRQLİDİR - modulu √13-dür, 5 yox, sadəcə ikisinin ilk koordinatı eyni olduğu üçün qarışdırılmamalıdır.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-vektorlar#40'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-silsile#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-silsile#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-silsile#comb1', 'riy-9-silsile',
  'Ədədi silsilədə a₅=20 və a₆=26-dır. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Silsilənin fərqi d=6-dır (a₆−a₅=26−20=6).
2) 1-ci addımdakı fərqdən istifadə edib geriyə hesablasaq, a₁=a₅−4d=20−24=−4 olur.
3) 2-ci addımdakı a₁ və d dəyərləri ilə Sₙ=n/2·(2a₁+(n−1)d) düsturuna əsasən, ilk 10 həddin cəmi S₁₀=230-dur.
4) Silsilənin ilk həddi (a₁=−4) mənfi olduğu üçün, bütün hədləri mənfidir.',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı: d=6, a₁=−4, S₁₀=230). 4-cü mülahizə yanlışdır: d=6>0 olduğu üçün hədlər artır - a₅=20 artıq müsbətdir, ilk həddin mənfi olması bütün hədlərin mənfi olması demək deyil.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-silsile#37'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy9-ehtimal#comb1
update public.questions set difficulty = 2 where ext_key = 'riy9-ehtimal#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy9-ehtimal#comb1', 'riy-9-ehtimal',
  '6 nəfərdən 2 nəfərlik komanda seçilir (bütün seçimlər bərabər ehtimallıdır). Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Mümkün seçimlərin ümumi sayı C(6,2)=15-dir.
2) Bu 6 nəfər arasındakı Aygün adlı şagirdin seçilmiş komandaya daxil olması üçün əlverişli seçimlərin sayı 5-dir (Aygün + qalan 5 nəfərdən biri).
3) Klassik ehtimal düsturuna görə (əlverişli/mümkün), Aygünün komandaya düşmə ehtimalı 5/15=1/3-dür.
4) Əgər komanda 2 yox, 3 nəfərlik olsaydı, Aygünün seçilmə ehtimalı da eyni (1/3) qalardı.',
  '1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə yanlışdır: 3 nəfərlik komandada ehtimal C(5,2)/C(6,3)=10/20=1/2 olur, 1/3 yox - komanda ölçüsü böyüdükcə bir nəfərin seçilmə ehtimalı da artır.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy9-ehtimal#37'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-tabesiz-baglayici#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-tabesiz-baglayici#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-tabesiz-baglayici#comb1', 'az-9-tabesiz-baglayici',
  '«Külək əsdi, yarpaqlar töküldü» və «Külək əsdi, lakin yarpaqlar tökülmədi» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Birinci cümlədə bağlayıcısız tabesiz mürəkkəb cümlədə tərəflər sadalama intonasiyası ilə (vergüllə) bağlanır.
2) İkinci cümlədə isə «lakin» bağlayıcısından əvvəl vergül qoyulur.
3) Deməli hər iki cümlədə də vergül var, amma səbəbi fərqlidir: birincidə bağlayıcı yoxluğu, ikincidə «lakin»in özünün tələbi.
4) Əgər «lakin» sözü çıxarılıb «Külək əsdi, yarpaqlar tökülmədi» yazılsa, vergül artıq yanlış olar, çünki indi cümlə bağlayıcısızdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 1-ci mülahizənin özünə görə bağlayıcısız cümlədə DƏ vergül lazımdır (sadalama intonasiyası ilə) - «lakin»in çıxarılması vergülü yanlış etmir, sadəcə səbəbini dəyişir.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-tabesiz-baglayici#23'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-tabesiz-mena#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-tabesiz-mena#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-tabesiz-mena#comb1', 'az-9-tabesiz-mena',
  '«Şimşək çaxdı, göy guruldadı, amma biz qorxmadıq» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Şimşək çaxdı, göy guruldadı» hissəsi zaman (ardıcıllıq) əlaqəsini bildirir.
2) «..., amma biz qorxmadıq» hissəsi isə qarşılaşdırma əlaqəsini bildirir.
3) Bu üç hissəli cümlədə iki fərqli məna əlaqəsi (zaman və qarşılaşdırma) birləşir.
4) Cümlədəki bütün üç tərəf eyni məna əlaqəsini (zaman əlaqəsini) daşıyır, çünki hamısı bir-birinin ardınca gəlir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 3-cü hissə («amma biz qorxmadıq») ilk ikisinə QARŞILAŞDIRMA əlaqəsi ilə bağlanır, zaman əlaqəsi ilə yox - bütün cümlə eyni əlaqə növündən ibarət deyil.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-tabesiz-mena#24'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-tabeli-qurulus#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-tabeli-qurulus#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-tabeli-qurulus#comb1', 'az-9-tabeli-qurulus',
  '«Bilirəm ki, sən gələcəksən» və «Kim çalışsa, o qazanar» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Birinci cümlədə «Bilirəm» baş cümlə, «sən gələcəksən» isə budaq cümlədir - budaq cümlə burada baş cümlədən SONRA gəlir.
2) İkinci cümlədə isə əksinə, budaq cümlə («kim çalışsa») baş cümlədən («o qazanar») ƏVVƏL gəlir.
3) Hər iki cümlədə budaq cümləni buraxsaq, qalan hissə fikri natamam saxlayar.
4) Bu iki nümunədən çıxan nəticə: budaq cümlə HƏMİŞƏ baş cümlədən sonra gəlməlidir, «kim çalışsa, o qazanar» isə bu qaydanın istisnasıdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 2-ci mülahizənin özü göstərir ki, budaq cümlə baş cümlədən ƏVVƏL də gəlir - bu, «istisna» yox, normal bir imkandır (budaq cümlənin yeri sabit deyil).',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-tabeli-qurulus#27'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-mubteda-xeber-bc#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-mubteda-xeber-bc#26';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-mubteda-xeber-bc#comb1', 'az-9-mubteda-xeber-bc',
  '«Kim çox oxuyursa, o çox bilər» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Kim çox oxuyursa» mübtəda budaq cümləsidir.
2) Bu cümlədə baş cümlənin öz mübtədası («o») mövcuddur, budaq cümlə ona əlavə izah verir.
3) Cümlədə 2 qrammatik əsas var - biri budaq cümlədə («kim...oxuyursa»), biri baş cümlədə («o...bilər»).
4) Budaq cümlə mübtəda vəzifəsində olduğu üçün ayrıca qrammatik əsas sayılmır - cümlədə yalnız 1 qrammatik əsas var.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: budaq cümlə hansı üzvün vəzifəsində olursa olsun, öz mübtəda-xəbərini (qrammatik əsasını) daşıyır - cümlədə 2 qrammatik əsas var, #28-in nümunəsindəki kimi.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-mubteda-xeber-bc#26'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-tamamliq-teyin-bc#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-tamamliq-teyin-bc#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-tamamliq-teyin-bc#comb1', 'az-9-tamamliq-teyin-bc',
  '«Onu deyim ki, işlər yaxşı gedir» və «Elə adam ol ki, hamı sənə hörmət etsin» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Birinci cümlədə budaq cümlə TAMAMLIQ budaq cümləsidir («onu» qarşılıq sözü ilə).
2) İkinci cümlədə isə budaq cümlə TƏYİN budaq cümləsidir («elə» qarşılıq sözü ilə).
3) Bu iki cümlə arasındakı fərq budaq cümlənin verdiyi cavab və aid olduğu üzvdəndir.
4) Hər iki qarşılıq söz («onu» və «elə») eyni üzvü (tamamlığı) əvəz etdiyi üçün, hər iki cümlədəki budaq cümlə də eyni növdəndir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «elə» tamamlığın yox, TƏYİNİN qarşılıq sözüdür - 1-ci və 2-ci mülahizələr artıq bunları FƏRQLİ növ kimi təsnif edib, 4-cü mülahizə bununla ziddiyyət təşkil edir.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-tamamliq-teyin-bc#16'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-zerflik-bc#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-zerflik-bc#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-zerflik-bc#comb1', 'az-9-zerflik-bc',
  '«Gecikdim, çünki yol bağlı idi» və «Ona görə çalışıram ki, arzuma çatım» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Birinci cümlədə budaq cümlə səbəb bildirir («yol bağlı idi» - artıq olmuş iş).
2) İkinci cümlədə isə budaq cümlə məqsəd bildirir («arzuma çatım» - hələ olmamış, gələcək iş).
3) Səbəb artıq olmuş işi, məqsəd isə hələ olacaq işi bildirir - bu iki cümlə dəqiq bu fərqi göstərir.
4) Bu qaydaya əsasən, «çünki» bağlayıcısı ilə başlayan HƏR budaq cümlə məqsəd bildirir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «çünki» SƏBƏB bağlayıcısıdır (1-ci mülahizənin özündə göründüyü kimi), məqsəd yox - iddia öz-özü ilə ziddiyyət təşkil edir.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-zerflik-bc#29'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-durgu-mc#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-durgu-mc#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-durgu-mc#comb1', 'az-9-durgu-mc',
  '«Bilirəm ki, sən gələcəksən» və «Əgər çox çalışsan, nəticə görərsən» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Birinci cümlədə vergül «ki» bağlayıcısından sonra qoyulur.
2) İkinci cümlədə isə budaq cümlə (şərt) əvvəldə olduğu üçün, vergül budaq cümlədən sonra qoyulur.
3) Hər iki qaydanın ortaq məntiqi: vergül budaq cümlənin bitdiyi yerdə qoyulur.
4) Deməli, tabeli mürəkkəb cümlədə vergülün yeri həmişə sabitdir - istənilən konstruksiyada elə «ki» sözündən sonra qoyulur.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 2-ci cümlədə heç «ki» sözü belə yoxdur - vergül budaq cümlənin sonunda qoyulur, «ki»-yə bağlı deyil. 1-ci mülahizədəki xüsusi qayda BÜTÜN formalara ümumiləşdirilə bilməz.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-durgu-mc#23'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- az9-metn-nitq#comb1
update public.questions set difficulty = 2 where ext_key = 'az9-metn-nitq#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az9-metn-nitq#comb1', 'az-9-metn-nitq',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Nitqin təmizliyi kobud və artıq (tüfeyli) sözləri istisna edir.
2) Ədəbi dilə isə dialekt və loru sözlər daxil deyil.
3) Bu iki qayda fərqli meyarlara əsaslanır: nitq təmizliyi təkrar/mənasızlıq məsələsidir, ədəbi dilə aidlik isə sözün mənşəyi/yayılma dairəsi məsələsidir.
4) Deməli, sinonimlər də nitq təmizliyi baxımından tüfeyli söz sayılır, çünki onlar da «artıq» sözlərdir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: sinonimlər üslubi məqsədlə işlədilən fərqli sözlərdir, tüfeyli (mənasız təkrar) söz deyil - bank bu ikisini açıq şəkildə ayırır.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az9-metn-nitq#22'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- ing9-identity#comb1
update public.questions set difficulty = 2 where ext_key = 'ing9-identity#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing9-identity#comb1', 'ing-9-identity',
  'Ayshe is bilingual: she has been learning English for five years, but she speaks neither French nor German. Which statements are TRUE?
1) "Bilingual" means Ayshe speaks two languages.
2) "has been learning English for five years" uses "for" because it states a DURATION, not a starting point.
3) "speaks neither French nor German" uses "nor" to pair with "neither" and negate both.
4) Since she speaks "neither French nor German," she is not bilingual - she only knows one language.',
  '1, 2 and 3 are true. Statement 4 is wrong - not speaking French or German does not contradict being bilingual: she is bilingual because of Azerbaijani (her mother tongue) and English, two completely different languages from the "neither...nor" pair.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing9-identity#28'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- ing9-books#comb1
update public.questions set difficulty = 2 where ext_key = 'ing9-books#6';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing9-books#comb1', 'ing-9-books',
  'This novel, which is based on real events, was written a century ago. Which statements are TRUE?
1) "was written a century ago" uses Past Simple Passive because the action happened at a specific point in the past.
2) "is based on real events" describes the novel''s source.
3) "Fiction" means invented/imaginative literature.
4) Since the novel "is based on real events," it must be non-fiction, not fiction, because fiction can never be based on real events.',
  '1, 2 and 3 are true. Statement 4 is wrong - fiction (invented literature) very often draws on real events (e.g. historical novels) while still being fictionalised - "based on real events" does not make a work non-fiction.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing9-books#6'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- ing9-traditions#comb1
update public.questions set difficulty = 2 where ext_key = 'ing9-traditions#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing9-traditions#comb1', 'ing-9-traditions',
  'In the past, people used to travel by horse to celebrate Novruz, which is celebrated in spring. Nowadays, guests are welcomed with tea instead. Which statements are TRUE?
1) "used to travel by horse" describes a PAST HABIT that is no longer true now.
2) "celebrated in spring" uses "in" because spring is a season (a general time period), not a specific day.
3) "welcomed with tea" uses "with" to show the means of welcoming.
4) Since "used to" describes a past habit, it means people still travel by horse today to celebrate Novruz.',
  '1, 2 and 3 are true. Statement 4 is wrong - "used to" specifically contrasts a past habit with the present, implying the habit has STOPPED, not that it continues.',
  '1, 2, 4', '2, 3, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing9-traditions#23'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- ing9-ambitions#comb1
update public.questions set difficulty = 2 where ext_key = 'ing9-ambitions#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing9-ambitions#comb1', 'ing-9-ambitions',
  '"If you work hard, you will succeed" and "If she studied harder, she would pass the exam." Which statements are TRUE?
1) The first sentence is First Conditional (If + present, will + verb) - a realistic/likely future outcome.
2) The second sentence is Second Conditional (If + past, would + verb) - a hypothetical situation, implying she is NOT currently studying hard.
3) The two sentences use different conditional forms because they express different degrees of likelihood.
4) Since both sentences are about hard work leading to success, they can be mixed: "If you worked hard, you will succeed" would be equally correct.',
  '1, 2 and 3 are true. Statement 4 is wrong - mixing Past tense in the if-clause with "will" in the main clause is ungrammatical; First and Second Conditional forms must stay internally consistent.',
  '1, 2, 3', '1, 2, 4', '2, 3, 4', '1, 4', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing9-ambitions#19'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- ing9-art#comb1
update public.questions set difficulty = 2 where ext_key = 'ing9-art#30';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing9-art#comb1', 'ing-9-art',
  'Yesterday, the walls of the gallery were decorated with beautiful patterns, and the exhibition was opened. The artist first drew the design with a pencil, then painted it with bright colours. Which statements are TRUE?
1) "was opened" uses Past Simple Passive because the action happened at a specific past time.
2) "were decorated with patterns" uses "with" to show the means/material of decoration.
3) The artist first drew (pencil), then painted (paint) - two different techniques.
4) Since both "drew" and "painted" describe making art, they mean exactly the same thing and are interchangeable here.',
  '1, 2 and 3 are true. Statement 4 is wrong - "draw" (with a pencil) and "paint" (with paint) are different techniques, not interchangeable synonyms, as the sentence itself shows by using them for two separate steps.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing9-art#30'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- ing9-skills#comb1
update public.questions set difficulty = 2 where ext_key = 'ing9-skills#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing9-skills#comb1', 'ing-9-skills',
  'Rashad is a punctual employee - he always arrives on time. He is also reliable, so his manager trusts him with important tasks. However, he is not very flexible, and he struggles when his schedule changes suddenly. Which statements are TRUE?
1) "Punctual" describes Rashad arriving on time - this is about TIME.
2) "Reliable" describes that his manager trusts him - this is about DEPENDABILITY, a different quality from punctuality.
3) "Not very flexible" means Rashad has difficulty adapting to sudden changes - a third, separate quality.
4) Since punctual, reliable, and flexible are all positive workplace words, they all mean the same thing, so calling Rashad "punctual" is the same as calling him "flexible".',
  '1, 2 and 3 are true. Statement 4 is wrong - these are distinct qualities, and the passage itself contradicts it: Rashad is punctual and reliable BUT explicitly NOT flexible.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing9-skills#29'
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
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- riy8-kvadrat-kok#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-kvadrat-kok#40';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-kvadrat-kok#comb1', 'riy-8-kvadrat-kok',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) √a · √b = √(ab) qaydasına görə, √36 · √25 = √900 = 30 alınır.
2) Eyni qaydaya görə, √13 · √52 = √676 = 26 alınır (13 · 52 = 676, 26² = 676).
3) √18 ifadəsi tək başına sadələşəndə 3√2 alınır (18 = 9 · 2).
4) Bu qaydaya əsasən, √18 · √2 hasilini 3√2 sadələşdirilmiş formasını 2-yə vuraraq 6√2 kimi tapmaq olar.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: √18 · √2 = √36 = 6 (eyni √a·√b=√(ab) qaydası ilə birbaşa), 6√2 yox - sadələşdirilmiş 3√2 formasını √2-yə vuranda 3·(√2·√2)=3·2=6 alınır, artıq √2 qalmır.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-kvadrat-kok#40'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-pifaqor#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-pifaqor#35';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-pifaqor#comb1', 'riy-8-pifaqor',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Divara söykənən 5 m-lik nərdivanın aşağı ucu divardan 3 m aralıdırsa, nərdivan divarda 4 m hündürlüyə çatır.
2) 3-4-5 üçlüyünü 2-yə vursaq, 6-8-10 üçlüyü alınır - yəni əsas 6 m, nərdivan 10 m olanda hündürlük 8 m-dir.
3) Bu, Pifaqor üçlüyünün miqyaslana bilmə xassəsidir: bütün tərəflər eyni əmsalla vurulanda üçbucağın forması dəyişmir.
4) Bu qaydaya əsasən, divardan məsafə 3 m saxlanılıb yalnız nərdivan 10 m-ə uzadılsa, hündürlük yenə 8 m olar.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: miqyaslama YALNIZ HƏR İKİ tərəf birgə dəyişəndə işləyir - əsas 3 m-də qalıb yalnız hipotenuz 10 m-ə uzansa, hündürlük √(10²−3²)=√91≈9,54 m olar, 8 m yox.',
  '1, 3', '2, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-pifaqor#35'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-kvadrat-tenlik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-kvadrat-tenlik#34';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-kvadrat-tenlik#comb1', 'riy-8-kvadrat-tenlik',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) x² − 7x + 10 = 0 tənliyinin kökləri 2 və 5-dir.
2) Vietə görə bu köklərin cəmi (2+5=7) əmsalın əksinə (−(−7)=7), hasili (2·5=10) sərbəst həddə (10) uyğun gəlir.
3) x² − 3x − 10 = 0 tənliyinin kökləri isə fərqlidir: −2 və 5-dir.
4) Bu iki tənliyin oxşar əmsallarına əsasən, x² − 7x + 10 = 0 tənliyinin kökləri x² − 3x − 10 = 0 tənliyinin köklərinə də uyğun gəlir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: bu, iki FƏRQLİ tənliyin köklərini qarışdırmaqdır - {2,5} və {−2,5} ortaq yalnız 5-i paylaşır, 2 ilə −2 tamam fərqlidir.',
  '2, 3, 4', '1, 4', '1, 2, 3', 'yalnız 1', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-kvadrat-tenlik#34'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-dordbucaqlilar#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-dordbucaqlilar#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-dordbucaqlilar#comb1', 'riy-8-dordbucaqlilar',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Paraleloqramın bir bucağı 70°-dirsə, qonşu bucağı 110°-dir (qonşu bucaqların cəmi 180°).
2) Paraleloqramın qarşı bucaqları bərabərdir - deməli 70°-lik bucağın qarşısındakı bucaq da 70°-dir.
3) Beləliklə dörd bucaq ardıcıl 70°, 110°, 70°, 110°-dir, cəmləri 360°-yə bərabərdir.
4) Bu nümunəyə əsasən, paraleloqramın bütün dörd bucağı 70°-dir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: yalnız qarşı-qarşıya olan bucaqlar bərabərdir, qonşu bucaqlar fərqlidir (70° və 110°) - hamısı 70° olsaydı cəm 280° olardı, 360° yox.',
  '1, 3', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-dordbucaqlilar#37'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-rasional-ifade#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-rasional-ifade#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-rasional-ifade#comb1', 'riy-8-rasional-ifade',
  '(a⁴ · a³)² : a⁸ ifadəsi üçün aşağıdakı mülahizələrdən hansılar doğrudur?
1) a⁴ · a³ = a⁷ (vurmada qüvvətlər toplanır).
2) (a⁷)² = a¹⁴ (qüvvətin qüvvəti qaydasına görə üstlər vurulur).
3) a¹⁴ : a⁸ = a⁶ (bölmədə qüvvətlər çıxılır).
4) Kvadratlaşdırma addımını (2-ci addımı) atlayıb birbaşa a⁷ : a⁸ hesablasaq, yenə eyni a⁶ nəticəsi alınar.',
  '1, 2 və 3 doğrudur - nəticə a⁶-dır. 4-cü mülahizə yanlışdır: a⁷ : a⁸ = a⁻¹ (7<8 olduğu üçün mənfi qüvvət), a⁶ ilə heç bir əlaqəsi yoxdur - addımı atlamaq fərqli, səhv nəticə verir.',
  '1, 4', '2, 3, 4', '1, 2, 3', 'yalnız 2', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-rasional-ifade#29'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-sahe#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-sahe#37';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-sahe#comb1', 'riy-8-sahe',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Radiusu 10 olan dairənin sahəsi 100π-dir (S=πr²=π·100).
2) Eyni radiuslu çevrənin uzunluğu isə 20π-dir (uzunluq=2πr=2π·10).
3) Radius 20-yə (2 dəfə) artırılsa, S=πr² düsturuna görə yeni sahə π·400=400π olar, yəni sahə 4 dəfə artır.
4) Bu qaydaya əsasən, radius 2 dəfə artanda sahə də cəmi 2 dəfə artıb 200π olar.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: sahə (S=πr²) radiusdan KVADRATİK asılıdır, çevrənin uzunluğu (2πr) kimi xətti yox - radius 2 dəfə artanda sahə 4 dəfə (200π yox, 400π) artır.',
  '1, 2, 4', '1, 4', '2, 3, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-sahe#37'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-rasional-tenlik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-rasional-tenlik#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-rasional-tenlik#comb1', 'riy-8-rasional-tenlik',
  'x/6 = 24/x tənliyi üçün aşağıdakı mülahizələrdən hansılar doğrudur?
1) Çarpaz vurma ilə x² = 144 alınır, müsbət kök x=12-dir.
2) x² = 144 tənliyinin mənfi kökü də var: x=−12.
3) Hər iki kökü (12 və −12) yoxlasaq, ikisi də tənliyi ödəyir - heç biri məxrəci (x=0-ı) sıfır etmir, ona görə kənar kök deyil.
4) Çarpaz vurma HƏR ZAMAN kənar kök yaradır, ona görə x=12 və x=−12-dən biri mütləq kənar kökdür.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: çarpaz vurma YALNIZ məxrəci sıfır edən kök yaransa kənar kök yaradır - bu misalda heç bir kök məxrəci sıfır etmir, «hər zaman» ümumiləşdirməsi səhvdir.',
  'yalnız 1', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-rasional-tenlik#16'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-oxsarliq#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-oxsarliq#33';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-oxsarliq#comb1', 'riy-8-oxsarliq',
  '△ABC ~ △DEF, AB=4, DE=12 verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Oxşarlıq əmsalı k=3-dür (12:4=3).
2) Bu əmsala görə, ABC-nin perimetri 12-dirsə, DEF-in perimetri 12·3=36 olar.
3) Sahələrin nisbəti isə k²=9-dur, yəni DEF-in sahəsi ABC-nin sahəsindən 9 dəfə böyükdür.
4) Bu qaydaya əsasən, sahələr də perimetrlər kimi əmsalla eyni (3 dəfə) artır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: sahə k² ilə (9 dəfə) artır, perimetr kimi xətti (3 dəfə) yox - sahə kvadratik, perimetr xəttidir.',
  '1, 4', '2, 3, 4', '1, 2, 3', 'yalnız 1', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-oxsarliq#33'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-berabersizlik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-berabersizlik#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-berabersizlik#comb1', 'riy-8-berabersizlik',
  '5x − 3 > 2x + 9 bərabərsizliyi üçün aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bərabərsizliyin həlli x > 4-dür (5x−2x>9+3 → 3x>12 → x>4).
2) Bu nəticəyə əsasən, −x < −4 doğrudur (hər iki tərəfi −1-ə vuranda işarə dəyişir).
3) Yenə bu nəticəyə əsasən, −3x < −12 doğrudur (hər iki tərəfi −3-ə vuranda işarə dəyişir).
4) Eyni qaydaya əsasən, −2x > −8 doğrudur (hər iki tərəfi −2-yə vuraraq).',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: bərabərsizliyin hər iki tərəfini mənfi ədədə (−2) vuranda işarə mütləq dəyişməlidir - düzgün nəticə −2x < −8-dir, −2x > −8 yox (işarə dəyişdirilməyib).',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-berabersizlik#16'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-triqonometrik#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-triqonometrik#39';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-triqonometrik#comb1', 'riy-8-triqonometrik',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) sin 30° = 1/2-dir.
2) Bu qiymətə əsasən və sin²α+cos²α=1 eyniliyini tətbiq etsək, cos 30° = √3/2 alınır (cos²30°=1−1/4=3/4).
3) sin 30° və cos 30°-nin bu qiymətlərinə əsasən, tan 30° = sin30°/cos30° = √3/3 alınır.
4) Bu qiymətlərə əsasən, cot 30° = tan 30° ilə eynidir, yəni √3/3-dür.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: kotangens tangensin TƏRSİDİR (cot α = cos α/sin α) - cot 30° = √3, tan 30° = √3/3, bunlar bir-birindən fərqlidir, eyni deyil.',
  '2, 4', '1, 2, 3', '1, 3', 'yalnız 2', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-triqonometrik#39'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- riy8-ehtimal#comb1
update public.questions set difficulty = 2 where ext_key = 'riy8-ehtimal#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('riy8-ehtimal#comb1', 'riy-8-ehtimal',
  'Qutuda 4 qırmızı və 6 mavi kürə var. Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Mavi kürə çıxarma ehtimalı 6/10=3/5-dir.
2) Bu ehtimala əsasən, qırmızı kürə çıxarma ehtimalı (əks hadisə) 1−3/5=2/5-dir.
3) Bu iki ehtimala əsasən, mavi kürə çıxma ehtimalı qırmızıdan 1,5 dəfə çoxdur ((3/5):(2/5)=1,5).
4) Kürə geri qoyulmaqla iki dəfə ardıcıl çıxarılsa, hər ikisinin mavi olması ehtimalı 3/5+3/5=6/5-dir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: iki MÜSTƏQİL hadisənin İKİSİNİN BİRDƏN baş verməsi ehtimalı TOPLANMIR, VURULUR - düzgün nəticə (3/5)·(3/5)=9/25-dir; üstəlik ehtimal heç vaxt 1-dən böyük ola bilməz, 6/5 artıq özü-özlüyündə mümkünsüzdür.',
  '1, 2, 4', '1, 4', '1, 2, 3', '2, 3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'riy8-ehtimal#7'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-soz-birlesmesi#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-soz-birlesmesi#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-soz-birlesmesi#comb1', 'az-8-soz-birlesmesi',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Dəmir qapı» birləşməsi 1-ci növ təyini söz birləşməsidir (tərəflər şəkilçisiz yanaşır).
2) «Sinif otağı» birləşməsi isə fərqli, 2-ci növdür, çünki ikinci tərəf mənsubiyyət şəkilçisi qəbul edib.
3) «Şəhərin küçələri» birləşməsi isə 3-cü növdür, çünki birinci tərəf yiyəlik halda, ikinci tərəf mənsubiyyət şəkilçilidir - yəni HƏR İKİ tərəf şəkilçilidir.
4) Bu üç nümunəyə əsasən, təyini söz birləşmələrinin bütün növlərində hər iki tərəf mütləq şəkilçi qəbul etməlidir.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 1-ci növdə (məs. «dəmir qapı») HEÇ BİR tərəf şəkilçi qəbul etmir, tərəflər sadəcə yanaşır - «hər iki tərəf şəkilçili olmalıdır» qaydası yalnız 3-cü növə aiddir, hamısına yox.',
  '1, 2, 4', '1, 4', '2, 3, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-soz-birlesmesi#4'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-mubteda-xeber#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-mubteda-xeber#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-mubteda-xeber#comb1', 'az-8-mubteda-xeber',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Bakı Azərbaycanın paytaxtıdır» cümləsində xəbər ismi xəbərdir.
2) «Quşlar uçur» cümləsindəki xəbər isə feili xəbərdir, çünki feillə ifadə olunub.
3) Hər iki cümlədə xəbər mübtəda ilə uzlaşır - şəxsə və kəmiyyətə görə uyğunlaşır.
4) Bu iki nümunəyə əsasən, ismi xəbər yalnız isimlə ifadə oluna bilər, feillə ifadə oluna bilməz.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ismi xəbər təkcə isimlə deyil, bir neçə nitq hissəsi ilə ifadə oluna bilər - «yalnız isimlə» məhdudiyyəti yanlışdır.',
  '1, 2, 3', '1, 4', '2, 3, 4', 'yalnız 1', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-mubteda-xeber#17'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-ikinci-uzvler#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-ikinci-uzvler#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-ikinci-uzvler#comb1', 'az-8-ikinci-uzvler',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Kitabı rəfə qoydum» cümləsində «kitabı» sözü vasitəsiz tamamlıqdır (təsirlik haldadır).
2) Eyni cümlədə «rəfə» sözü isə vasitəli tamamlıqdır (yönlük haldadır).
3) «Oxumaq üçün kitabxanaya getdi» cümləsində «oxumaq üçün» məqsəd zərfliyidir.
4) Bu nümunələrə əsasən, «kitabxanaya» sözü də cümlədə tamamlıqdır, çünki yönlük haldadır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «kitabxanaya» sözü «hara?» sualına cavab verir və yer zərfliyidir - üzvü təkcə HAL əsasında (yönlük) müəyyənləşdirmək olmaz, sual/məna da nəzərə alınmalıdır.',
  '1, 4', '2, 3, 4', '1, 2, 3', 'yalnız 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-ikinci-uzvler#4'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-hemcins#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-hemcins#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-hemcins#comb1', 'az-8-hemcins',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Həmcins üzvlər arasında adətən vergül qoyulur.
2) Amma ümumiləşdirici söz bu üzvlərdən ƏVVƏL gələndə, ondan sonra vergül yox, iki nöqtə (:) qoyulur.
3) Ümumiləşdirici söz üzvlərdən SONRA gələndə isə ondan əvvəl tire (—) qoyulur.
4) Bu qaydalara əsasən, təkrarlanmayan «və» bağlayıcısından əvvəl də vergül qoyulmalıdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: təkrarlanmayan «və» bağlayıcısından əvvəl vergül QOYULMUR - bu, «həmcins üzvlər arasında vergül» əsas qaydasının bir istisnasıdır.',
  '1, 2, 3', '2, 3, 4', '1, 4', 'yalnız 2', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-hemcins#18'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-xitab-ara#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-xitab-ara#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-xitab-ara#comb1', 'az-8-xitab-ara',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Xitab yazıda vergüllə ayrılır.
2) Xitab cümlənin ortasında gələndə hər iki tərəfdən vergüllə ayrılır.
3) Xitab cümlə üzvü deyil - ona görə «Uşaqlar, sabahınız xeyir!» cümləsində «Uşaqlar» sözü mübtəda ola bilməz.
4) «Ey Vətən!» müraciətində «Ey» sözü xitabdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «Vətən» sözü xitabdır, «Ey» isə xitabdan ƏVVƏL işlənən ayrıca nida ədatıdır, xitabın özü deyil.',
  '1, 3', '2, 4', '1, 2, 3', '1, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-xitab-ara#27'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-cumle-novleri#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-cumle-novleri#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-cumle-novleri#comb1', 'az-8-cumle-novleri',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Payız gəldi» cümləsi cüttərkiblidir - həm mübtədası, həm xəbəri var.
2) «Gəlirəm» cümləsi isə təktərkiblidir - müəyyən şəxsli, çünki mübtəda feilin şəxs şəkilçisindən aydın olduğu üçün buraxılıb.
3) «Otağı səliqəyə saldılar» cümləsi də təktərkiblidir, lakin fərqli növdür - qeyri-müəyyən şəxsli, çünki işi görən şəxs məlum deyil.
4) Bu üç nümunəyə əsasən, «Bayırda qaranlıq idi» cümləsi də qeyri-müəyyən şəxsli cümlədir, çünki mübtəda yoxdur.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «Bayırda qaranlıq idi» cümləsi ŞƏXSSİZ cümlədir - qeyri-müəyyən şəxsli cümlədə naməlum bir ŞƏXS nəzərdə tutulur, şəxssiz cümlədə isə mübtəda ümumiyyətlə təsəvvür belə edilmir (təbiət hadisəsi).',
  '1, 2, 4', '1, 4', '2, 3, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-cumle-novleri#17'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-durgu#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-durgu#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-durgu#comb1', 'az-8-durgu',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Vasitəsiz nitq dırnaq içərisində yazılır.
2) Müəllifin sözləri vasitəsiz nitqdən ƏVVƏL gələndə, aralarında iki nöqtə qoyulur, sonra dırnaqda vasitəsiz nitq yazılır.
3) Vasitəsiz nitq vasitəli nitqə çevriləndə isə dırnaq işarələri tamamilə götürülür.
4) Bu qaydaya əsasən, müəllifin sözləri vasitəsiz nitqdən SONRA gələndə də aralarında iki nöqtə qoyulmalıdır.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: müəllifin sözləri vasitəsiz nitqdən SONRA gələndə fərqli işarələr (vergül/tire) qoyulur - söz sırası dəyişəndə durğu qaydası da dəyişir, «əvvəl gələndə»ki iki nöqtə qaydası bura tətbiq olunmur.',
  '2, 3, 4', '1, 2, 3', '1, 4', 'yalnız 2', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-durgu#14'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- az8-metn-uslub#comb1
update public.questions set difficulty = 2 where ext_key = 'az8-metn-uslub#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('az8-metn-uslub#comb1', 'az-8-metn-uslub',
  'Aşağıdakı mülahizələrdən hansılar doğrudur?
1) Elmi üslubda termin və elmi sözlər üstünlük təşkil edir.
2) Bədii üslubun əsas ifadə vasitəsi isə fərqlidir - məcazi, obrazlı dildir.
3) Rəsmi-işgüzar üslub isə bunların heç birinə deyil, sənəd formasına (ərizə, arayış və s.) əsaslanır.
4) Bu fərqlərə əsasən, publisistik üslub da rəsmi-işgüzar üslub kimi yalnız sənəd formasında olur.',
  '1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: publisistik üslub əsasən mətbuatda (KİV-də) işlənir - sənəd forması ilə əlaqəsi yoxdur, tamam fərqli sahədir.',
  '1, 4', '1, 2, 3', '2, 3, 4', 'yalnız 1', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'az8-metn-uslub#16'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-holidays#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-holidays#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-holidays#comb1', 'ing-8-holidays',
  'Which statements are TRUE?
1) "too" usually comes BEFORE an adjective and means "more than needed".
2) "enough" comes AFTER an adjective, not before it.
3) "She is not old enough to travel alone." means she does not have enough age to travel alone (following rule 2''s word order).
4) "This bag is enough big." is grammatically correct.',
  '1, 2 and 3 are true. Statement 4 is wrong - "enough" must come AFTER the adjective ("big enough"), not before it; "enough big" reverses the word order fixed by statement 2.',
  '1, 2, 4', '1, 2, 3', '2, 3, 4', '1, 4', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-holidays#21'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8-inventions#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8-inventions#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8-inventions#comb1', 'ing-8-inventions',
  'Which statements are TRUE?
1) The Passive voice is built with "was/were + the 3rd form of the verb".
2) By this structure, "The telephone was invented by Bell." is in the Passive voice.
3) By the same rule, "Radio waves were discovered by scientists." is also in the Passive voice.
4) Based on these two examples, the Passive voice puts the focus on the person after "by" (Bell, scientists).',
  '1, 2 and 3 are true. Statement 4 is wrong - the Passive voice actually shifts focus AWAY from the doer, onto the action or the object; the "by" phrase is often even left out.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8-inventions#7'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8-hobbies#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8-hobbies#2';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8-hobbies#comb1', 'ing-8-hobbies',
  'Which statements are TRUE?
1) "used to" describes a habit that continued in the past but does NOT continue now.
2) "I used to play chess every day." means this was a past habit that does not continue now.
3) In the negative form, "used to" loses its "-d": "did not use to", not "did not used to".
4) By the same rule, the question form is "Did you used to collect stamps?".',
  '1, 2 and 3 are true. Statement 4 is wrong - the question form also drops the "-d": "Did you USE to collect stamps?", the same as the negative form in statement 3.',
  '2, 3, 4', '1, 4', '1, 2, 3', 'yalnız 1', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8-hobbies#2'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-real-heroes#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-real-heroes#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-real-heroes#comb1', 'ing-8-real-heroes',
  'Which statements are TRUE?
1) Past Progressive is built with "was/were + verb-ing".
2) "They were helping people when the fire started." - "were helping" began BEFORE "started" and was still going on.
3) "While she was helping the child, her phone rang." - "was helping" is the LONGER action, "rang" is the short, sudden one.
4) By this pattern, in "The children were playing when the storm began.", the storm began BEFORE "were playing".',
  '1, 2 and 3 are true. Statement 4 is wrong - it reverses the timeline: "were playing" was the ongoing action that started first, and "the storm began" is the short action that interrupted it, not the other way round.',
  '1, 2, 4', '1, 4', '2, 3, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-real-heroes#29'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-choose-kind#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-choose-kind#30';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-choose-kind#comb1', 'ing-8-choose-kind',
  'Which statements are TRUE?
1) In the negative Past Progressive, "not" comes right after "was/were".
2) "was not" is shortened to "wasn''t".
3) "He was not crying, he was just tired." denies that he was crying, and offers tiredness instead.
4) By this rule, "They were not helping the new student." means "They WERE helping the new student."',
  '1, 2 and 3 are true. Statement 4 is wrong - it reverses the meaning of the negative sentence completely: "were not helping" means they did NOT help, not that they did.',
  '1, 4', '1, 2, 3', '2, 3, 4', 'yalnız 1', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-choose-kind#30'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-travel-stories#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-travel-stories#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-travel-stories#comb1', 'ing-8-travel-stories',
  'Which statements are TRUE?
1) A Past Progressive question is built as "Was/Were + subject + verb-ing".
2) By this rule, the short answer to "Was she travelling alone?" is "Yes, she was." or "No, she wasn''t."
3) In "Who was waiting at the station?", "Who" refers to the subject, which is why "was" (not "were") is used.
4) By this rule, "you and your friends" in "Were you and your friends exploring the old town?" can be replaced with "she".',
  '1, 2 and 3 are true. Statement 4 is wrong - "you and your friends" is plural and matches "were", so it is replaced with "you" (plural), not "she" (singular, which would need "was").',
  '1, 2, 3', '2, 3, 4', '1, 4', 'yalnız 1', 1)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-travel-stories#17'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-celebrations#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-celebrations#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-celebrations#comb1', 'ing-8-celebrations',
  'Which statements are TRUE?
1) "when" is usually used with Past Simple - a short, sudden action.
2) "while" is usually used with Past Progressive - a longer, ongoing action.
3) "While we were decorating the hall, the guests arrived." - "were decorating" (rule 2) is the longer action, "arrived" (rule 1) is the short one.
4) By this pattern, in the same sentence, "the guests arrived" is the longer, ongoing action.',
  '1, 2 and 3 are true. Statement 4 is wrong - it reverses the roles from statement 3: "were decorating" is the longer, background action, and "arrived" is the short Past Simple one.',
  '1, 4', '2, 3, 4', '1, 2, 3', 'yalnız 2', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-celebrations#21'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-art#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-art#11';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-art#comb1', 'ing-8-art',
  'Which statements are TRUE?
1) "can" is used for general present ability.
2) "could" expresses the same kind of ability, but in the PAST.
3) The negative form of "could" is "could not" ("couldn''t").
4) By the same rule, the negative form of "can" is also "could not".',
  '1, 2 and 3 are true. Statement 4 is wrong - "can"''s negative form is "cannot" ("can not"), not "could not"; each modal keeps its own negative form matching its own tense.',
  '2, 4', '1, 2, 3', '1, 3', 'yalnız 2', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-art#11'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-environment#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-environment#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-environment#comb1', 'ing-8-environment',
  'Which statements are TRUE?
1) After "must", the main verb comes in the bare infinitive form (no "to").
2) "must" usually expresses the speaker''s own opinion, while "have to" expresses an outside rule - "You have to recycle plastic in this city." is a city rule.
3) "do not have to" means there is NO obligation, a free choice - unlike "must not", which means a strict prohibition.
4) By this, "You do not have to buy a new bag" means exactly the same as "You must not buy a new bag".',
  '1, 2 and 3 are true. Statement 4 is wrong - these are OPPOSITE meanings: "do not have to" = free choice, no obligation; "must not" = strictly forbidden.',
  '1, 2, 4', '1, 4', '2, 3, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-environment#18'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-people-life#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-people-life#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-people-life#comb1', 'ing-8-people-life',
  'Which statements are TRUE?
1) Zero Conditional is built as "If + Present Simple, Present Simple".
2) By this structure, it expresses a general truth that is always true.
3) In Zero Conditional, "if" can be replaced with "when" without changing the meaning, because both describe a general rule.
4) By this, "If you are kind to people, they trust you." describes one specific, one-time event, not a general rule.',
  '1, 2 and 3 are true. Statement 4 is wrong - it contradicts statement 2: this sentence is exactly the kind of ALWAYS-true general rule Zero Conditional describes, not a one-time event.',
  '1, 4', '1, 2, 3', '2, 3, 4', 'yalnız 1', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-people-life#14'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-modern-technology#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-modern-technology#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-modern-technology#comb1', 'ing-8-modern-technology',
  'Which statements are TRUE?
1) First Conditional is built as "If + Present Simple, will + bare infinitive".
2) In the if-clause, Present Simple is used; in the result clause, "will" is used.
3) This structure expresses a real, possible future condition - "If you charge your phone tonight, it will work tomorrow." is an example.
4) By this rule, "will" can also be used in the if-clause, since both clauses refer to the future.',
  '1, 2 and 3 are true. Statement 4 is wrong - it breaks the rule from statement 2: the if-clause always uses Present Simple, never "will", even though the whole sentence refers to the future.',
  '1, 2, 4', '2, 3, 4', '1, 4', '1, 2, 3', 4)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-modern-technology#19'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- ing8v2-ing-8-important-skills#comb1
update public.questions set difficulty = 2 where ext_key = 'ing8v2-ing-8-important-skills#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('ing8v2-ing-8-important-skills#comb1', 'ing-8-important-skills',
  'Which statements are TRUE?
1) Reflexive pronouns are used when the subject and the object of the verb are the same person.
2) By this rule, "he" matches "himself", and "she" matches "herself" - each pronoun has its own reflexive form.
3) "They solved the problem by themselves." - here "by themselves" means "without help, alone".
4) By this rule, "we" also matches "themselves", because both are plural.',
  '1, 2 and 3 are true. Statement 4 is wrong - being plural is not enough: person also has to match. "we" (1st person plural) matches "ourselves", and "they" (3rd person plural) matches "themselves" - they are not interchangeable.',
  '2, 4', '1, 2, 3', '1, 3', 'yalnız 2', 2)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'ing8v2-ing-8-important-skills#19'
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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

-- ------------------------------------------------------------- tarix11-zefer#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix11-zefer#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix11-zefer#comb1', 'tarix-11-zefer',
  '2020-ci il Vətən müharibəsi hadisələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Cəbrayıl (4 oktyabr) ilə Zəngilan (20 oktyabr) arasındakı fərq, Zəngilan ilə Qubadlı (25 oktyabr) arasındakı fərqdən böyükdür - deməli bu üç şəhər arasında Qubadlı SONUNCU azad edilmişdir.
2) 1-ci mülahizədəki sonuncu tarixdən (25 oktyabr) sonra, lakin Üçtərəfli bəyanatın imzalanmasından (10 noyabr) əvvəl Şuşa (8 noyabr) azad edilmişdir.
3) Üçtərəfli bəyanat Şuşanın azad edilməsindən DƏRHAL ƏVVƏL, hərbi əməliyyatların davamı kimi imzalanmışdır.
4) Bəyanatdan sonra təhvil verilən sonuncu rayon olan Laçın (1 dekabr) Zəfər paradından (10 dekabr) əvvəl baş vermişdir.',
  '1, 2 və 4 doğrudur: Cəbrayıl-Zəngilan fərqi 16 gün, Zəngilan-Qubadlı fərqi isə 5 gündür (16 > 5), deməli üç şəhər arasında Qubadlı (25 oktyabr) sonuncu azad edilib; Şuşa bundan sonra, 8 noyabrda azad olunub - bu, 10 noyabr bəyanatından ƏVVƏLDİR. Laçının təhvili (1 dekabr) isə Zəfər paradından (10 dekabr) əvvəldir. 3-cü mülahizə yanlışdır: Şuşanın hərbi yolla azad edilməsi (8 noyabr) Üçtərəfli bəyanatın imzalanmasından (10 noyabr) ƏVVƏL baş vermişdir - bəyanat qələbədən SONRA gəlib, əvvəl yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix11-zefer#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
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

-- ------------------------------------------------------------- cog11-demoqrafiya#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-demoqrafiya#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-demoqrafiya#comb1', 'cog-11-demoqrafiya',
  'Demoqrafiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İnkişaf etmiş ölkələrdə doğum və ölüm aşağıdır, əhali qocalır - bu ölkələrin yaş-cins piramidası, deməli, gənc, yüksək doğumlu ölkələrə xas geniş əsaslı (üçbucaq formalı) piramidanın ƏKSİNƏDİR.
2) 1-ci mülahizəyə əsasən, bu ölkələrdə pensiya yükü artır və işçi qüvvəsi azalır.
3) Əhalinin qocalmasının əsas səbəbi beyin axınıdır - yüksəkixtisaslı gənclərin xaricə köçməsi ölkəni yaşlı əhali ilə tək qoyur.
4) Şəhər əhalisinin payının 40 %-dən 70 %-ə qalxması (urbanizasiya) ilə əhalinin qocalması eyni demoqrafik hadisə deyil - biri məskunlaşma NÖVÜNÜ, digəri yaş QURULUŞUNU dəyişir.',
  '1, 2 və 4 doğrudur: inkişaf etmiş ölkələrdə aşağı doğum/ölüm əhalini qocaldır, bu, gənc əhaliyə xas üçbucaq piramidanın əksidir; qocalma pensiya yükünü artırır, işçi qüvvəsini azaldır; urbanizasiya (məskunlaşma növü) ilə qocalma (yaş quruluşu) fərqli demoqrafik proseslərdir. 3-cü mülahizə yanlışdır: qocalmanın səbəbi aşağı doğum/ölüm əmsallarıdır, beyin axını yox - beyin axını ölkəyə fərqli ziyan (insan kapitalının itirilməsi) vurur, əhalinin yaş quruluşunu deyil.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-demoqrafiya#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- fiz11-atom#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz11-atom#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz11-atom#comb1', 'fiz-11-atom',
  'Nüvə enerjisi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Nüvənin xüsusi rabitə enerjisi dəmir ətrafındakı orta kütləli elementlərdə ən böyükdür.
2) 1-ci mülahizəyə əsasən, ağır (uran kimi) bir nüvə bölünəndə əmələ gələn orta kütləli məhsul nüvələrinin rabitə enerjisi başlanğıc nüvədən böyük olur - buna görə nüvə bölünməsində enerji ayrılır.
3) Eyni qayda (rabitə enerjisi dəmirdə maksimumdur) yüngül nüvələrin BİRLƏŞMƏSİNDƏ (termonüvə sintezində) enerjinin ayrıla BİLMƏYƏCƏYİNİ göstərir, çünki yüngül nüvələr onsuz da dəmirdən aşağı rabitə enerjisinə malikdir.
4) Termonüvə sintezinin enerji mənbəyi kimi üstünlüyü yanacağın (hidrogen izotoplarının) bol olması və az radioaktiv tullantı yaratmasıdır.',
  '1, 2 və 4 doğrudur: rabitə enerjisi dəmirdə maksimumdur, ona görə ağır nüvə bölünəndə (uran → orta kütləli məhsullar) rabitə enerjisi artır və enerji ayrılır; termonüvə sintezinin üstünlüyü yanacaq bolluğu və az tullantıdır. 3-cü mülahizə yanlışdır: eyni "dəmirdə maksimum" qanunu əslində YÜNGÜL nüvələrin BİRLƏŞMƏSİNDƏ də (dəmirə doğru) rabitə enerjisinin artacağını, deməli sintezdə DƏ enerji ayrılacağını göstərir - məhz buna görə termonüvə sintezi ümumiyyətlə enerji mənbəyi kimi işlədilir.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz11-atom#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
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

-- ------------------------------------------------------------- kim11-karbohidrat#comb1
update public.questions set difficulty = 2 where ext_key = 'kim11-karbohidrat#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim11-karbohidrat#comb1', 'kim-11-karbohidrat',
  'Karbohidratlarla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Saxaroza hidroliz olunanda qlükoza VƏ fruktoza (iki fərqli maddə) alınır, maltoza hidroliz olunanda isə iki EYNİ molekul (2 qlükoza) alınır - deməli saxarozanın və maltozanın monomer tərkibi fərqlidir.
2) Qlükoza tərkibindəki aldehid qrupuna görə gümüş güzgü reaksiyası verir; 1-ci mülahizəyə əsasən, maltozanın hidrolizindən yalnız qlükoza alındığı üçün, bu hidroliz məhsulları da gümüş güzgü reaksiyası verməyə qadirdir.
3) Qlükoza həm aldehid, həm spirt xassəsi göstərdiyi üçün aldehidospirt adlanır - bu ad onun YALNIZ TƏK funksional qrup daşıdığını göstərir.
4) Nişasta və sellüloza eyni monomerdən (qlükoza) qurulsa da, zəncirin quruluş fərqi onların fərqli xassələr göstərməsinə səbəb olur.',
  '1, 2 və 4 doğrudur: saxaroza fərqli iki şəkərə (qlükoza+fruktoza), maltoza isə iki eyni qlükozaya parçalanır - fərqli monomer tərkibi deməkdir; maltozanın hidroliz məhsulu olan qlükoza aldehid qrupu daşıdığı üçün gümüş güzgü reaksiyası verə bilər; nişasta və sellüloza eyni monomerdən olsa da zəncir quruluş fərqi xassələri fərqləndirir. 3-cü mülahizə yanlışdır: "aldehidospirt" adı əksinə, qlükozanın İKİ (aldehid VƏ spirt) funksional qrup daşıdığını göstərir, tək qrup yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim11-karbohidrat#18'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
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

-- ------------------------------------------------------------- bio11-seleksiya#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-seleksiya#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-seleksiya#comb1', 'bio-11-seleksiya',
  'Seleksiya üsulları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Heteroziz F1 hibridlərinin valideynlərdən ÜSTÜN olması hadisəsidir, amma bu effekt sonrakı nəsillərdə tədricən ZƏİFLƏYİR - deməli heteroziz effektindən sabit deyil, yalnız İLK NƏSİLDƏ tam faydalanmaq olar.
2) İnbridinq (qohumluq çarpazlaşdırması) isə əksinə, zərərli RESESSİV əlamətlərin üzə çıxmasına gətirir - bu, heterozizin ƏKS təsiridir.
3) Heteroziz və inbridinq EYNİ genetik mexanizmin (heterozigotluğun) nəticəsidir, ona görə hər ikisi nəsildən-nəslə eyni istiqamətdə GÜCLƏNİR.
4) Uzaq hibridləşdirmə (fərqli növlərin çarpazlaşdırılması) tez-tez QISIR nəsillər verir - bu, uzaq hibridləşdirmənin praktik məhdudiyyətidir.',
  '1, 2 və 4 doğrudur: heteroziz F1-də üstünlük verir, amma sonrakı nəsillərdə zəifləyir - yalnız ilk nəsildə tam fayda var; inbridinq isə əksinə zərərli resessiv əlamətləri üzə çıxarır; uzaq hibridləşdirmə isə tez-tez qısır nəsillər problemi yaradır. 3-cü mülahizə yanlışdır: heteroziz və inbridinq EYNİ mexanizmin nəticəsi deyil, ƏKS proseslərdir - heteroziz heterozigotluqla bağlıdır və zəifləyir, inbridinq isə homozigotluğu artıraraq zərərli əlamətləri üzə çıxarır; ikisi eyni istiqamətdə güclənmir.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-seleksiya#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- inf11-baza-layihe#comb1
update public.questions set difficulty = 2 where ext_key = 'inf11-baza-layihe#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf11-baza-layihe#comb1', 'inf-11-baza-layihe',
  'Verilənlər bazası dizaynı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Şagird - Sinif» və «Şagird - Qiymət» əlaqələrinin İKİSİ də birin-çoxa əlaqədir (bir sinifdə çox şagird, bir şagirddə çox qiymət olur).
2) 1-ci mülahizəyə əsasən, hər ikisi «birin-çoxa əlaqə ayrıca cədvəl tələb edir» qaydasına tabedir, amma «Şagird - Dərnək» əlaqəsi FƏRQLİ tipdir - çoxun-çoxadır (hər şagird çox dərnəyə, hər dərnəyə çox şagird gedir) - buna görə bu qayda ona birbaşa tətbiq olunmur.
3) Bütün bu üç əlaqə (Sinif, Qiymət, Dərnək) eyni tip (birin-çoxa) əlaqədir, ona görə eyni qaydayla modelləşdirilir.
4) Normallaşdırmanın məqsədi təkrarlanmanı azaltmaqdır - qiymətləri ayrıca cədvəldə saxlamaq da bu məqsədə xidmət edir.',
  '1, 2 və 4 doğrudur: Sinif və Qiymət əlaqələri ikisi də birin-çoxadır və «ayrıca cədvəl» qaydasına tabedir; Dərnək əlaqəsi isə çoxun-çoxa olduğu üçün bu qayda ona birbaşa tətbiq olunmur; normallaşdırma təkrarlanmanı azaltmaq üçündür, qiymətlərin ayrıca cədvəldə saxlanması da bunun nümunəsidir. 3-cü mülahizə yanlışdır: Sinif/Qiymət əlaqələri birin-çoxa, Dərnək əlaqəsi isə çoxun-çoxadır - üçü EYNİ tip deyil.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf11-baza-layihe#19'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
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

-- ------------------------------------------------------------- edeb11-romantizm#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-romantizm#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-romantizm#comb1', 'edeb-11-romantizm',
  'Hüseyn Cavidlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «İblis»in yazılması (1918), Cavidin repressiyaya məruz qalması (1937) və nəşinin vətənə qaytarılması (1982) tarixləri arasında ƏN BÖYÜK interval repressiya ilə nəşin qaytarılması arasındadır (45 il).
2) 1-ci mülahizəyə əsasən, «İblis»in yazılması ilə repressiya arasındakı fasilə (19 il) nəşin qaytarılması ilə repressiya arasındakı fasilədən (45 il) QISADIR.
3) Cavid repressiyadan sonra mühacirətə gedib, Türkiyədə vəfat edib, nəşi buna görə 1982-ci ildə oradan gətirilib.
4) Romantizmin bədii dilində rəmz və yüksək üslub üstünlük təşkil edir - bu, «Füyuzat»ın romantik-ideal mövqeyi ilə üst-üstə düşür, «Molla Nəsrəddin»in satirik-realist mövqeyindən fərqlənir.',
  '1, 2 və 4 doğrudur: repressiya (1937) ilə nəşin qaytarılması (1982) arası 45 il, «İblis» (1918) ilə repressiya arası isə 19 ildir - 19 < 45; romantizmin rəmzli, yüksək üslublu dili «Füyuzat»ın romantik-ideal mövqeyinə uyğun gəlir, «Molla Nəsrəddin»in satirik-realist mövqeyindən fərqlənir. 3-cü mülahizə yanlışdır: Cavid mühacirətə GETMƏMİŞ, repressiyaya məruz qalıb Sibirdə vəfat etmişdir - nəşi ORADAN 1982-ci ildə vətənə gətirilmişdir, Türkiyədən yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-romantizm#22'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- tarix11-cumhuriyyet#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix11-cumhuriyyet#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix11-cumhuriyyet#comb1', 'tarix-11-cumhuriyyet',
  'AXC-nin tarixi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İstiqlal Bəyannaməsi 28 may 1918-də Tiflisdə qəbul edildi; paytaxt Bakıya isə yalnız sentyabr 1918-də köçdü - deməli istiqlal elan ediləndə paytaxt hələ Bakı deyil, Tiflis idi.
2) 1-ci mülahizəyə əsasən, parlamentin ilk iclası (7 dekabr 1918) artıq Bakıda keçirilə bilərdi, çünki bu tarix paytaxtın Bakıya köçməsindən (sentyabr 1918) SONRADIR.
3) Parlamentdə yalnız müsəlman deputatlar təmsil olunurdu, milli azlıqların nümayəndəsi yox idi.
4) F.Xoyski ilk baş nazir, M.Ə.Rəsulzadə isə Milli Şuranın sədri idi - bu iki vəzifə eyni şəxsə aid deyildi.',
  '1, 2 və 4 doğrudur: istiqlal Tiflisdə elan edildi, paytaxt Bakıya sentyabr 1918-də köçdü - istiqlal zamanı paytaxt hələ Tiflis idi; parlamentin ilk iclası (7 dekabr) bu köçdən sonradır, Bakıda keçirilə bilərdi; Xoyski baş nazir, Rəsulzadə Milli Şuranın sədri idi - fərqli vəzifələr. 3-cü mülahizə yanlışdır: parlamentdə müsəlman deputatlarla yanaşı rus, erməni, yəhudi və alman millətlərinin nümayəndələri də təmsil olunurdu.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix11-cumhuriyyet#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
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

-- ------------------------------------------------------------- tarix11-isgal#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix11-isgal#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix11-isgal#comb1', 'tarix-11-isgal',
  'Şimali Azərbaycanın işğalı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Kürəkçay (1805) ilə Gülüstan (1813) arasındakı fərq (8 il), Gülüstan (1813) ilə Türkmənçay (1828) arasındakı fərqdən (15 il) KİÇİKDİR.
2) 1-ci mülahizəyə əsasən, İrəvan və Naxçıvan xanlıqları (Türkmənçayla, 1828) Kürəkçay/Gülüstanla tutulan digər xanlıqlardan daha GEC Rusiyaya keçmişdir.
3) Gülüstan müqaviləsi İKİNCİ Rusiya-Qacar müharibəsini bitirdi, Türkmənçay isə BİRİNCİNİ.
4) Naxçıvan xanlığı 1827-ci ildə, yəni Türkmənçay müqaviləsinin imzalanmasından (1828) BİR İL ƏVVƏL artıq faktiki tutulmuşdu - müqavilə bunu yalnız hüquqi cəhətdən təsdiqlədi.',
  '1, 2 və 4 doğrudur: Kürəkçay-Gülüstan fərqi 8 il, Gülüstan-Türkmənçay fərqi isə 15 ildir (8 < 15); İrəvan/Naxçıvan Türkmənçayla (1828) - bu, Kürəkçay/Gülüstanla tutulan xanlıqlardan sonradır; Naxçıvan 1827-də artıq faktiki tutulmuşdu, Türkmənçay (1828) bunu hüquqi təsdiqlədi. 3-cü mülahizə yanlışdır: Gülüstan BİRİNCİ, Türkmənçay isə İKİNCİ Rusiya-Qacar müharibəsini bitirdi - əksinə deyil.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix11-isgal#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
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

-- ------------------------------------------------------------- tarix11-mustemleke#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix11-mustemleke#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix11-mustemleke#comb1', 'tarix-11-mustemleke',
  'XIX əsr Bakı neft sənayesi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Tağıyevin şirkəti YERLİ kapitalı təmsil edirdi, Branobel isveç, Rotşildlər isə fransız kapitalı idi - deməli yerli və əcnəbi kapital paralel fəaliyyət göstərirdi.
2) 1-ci mülahizəyə əsasən, bu qarışıq kapital bazası ilə Bakı dünya neft hasilatının təqribən YARISINI verə bildi.
3) Bakı-Tiflis dəmir yolunun (1880-ci illər) açılması ilə Şollar su kəmərinin işə düşməsi EYNİ VAXTDA baş verdi.
4) Rusiya bazarına inteqrasiya nəticəsində ucuz fabrik malları yerli əl əməyini sıxışdırdı, ənənəvi sənətkarlıq tənəzzülə uğradı.',
  '1, 2 və 4 doğrudur: yerli (Tağıyev) və əcnəbi (Branobel-isveç, Rotşild-fransız) kapital paralel işləyirdi, bu, Bakının dünya hasilatının yarısını verməsinə imkan verdi; Rusiya bazarına inteqrasiya ucuz fabrik mallarını gətirib yerli sənətkarlığı sıxışdırdı. 3-cü mülahizə yanlışdır: Bakı-Tiflis dəmir yolu 1880-ci illərdə açıldı, Şollar su kəməri isə YALNIZ 1917-ci ildə - eyni vaxtda deyil, otuz ildən çox fərqlə.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix11-mustemleke#7'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
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

-- ------------------------------------------------------------- tarix11-musteqillik#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix11-musteqillik#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix11-musteqillik#comb1', 'tarix-11-musteqillik',
  'Azərbaycanın neft strategiyası ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Neft kəmərləri bu ardıcıllıqla açıldı: Bakı-Novorossiysk (1997), Bakı-Supsa (1999), Bakı-Tbilisi-Ceyhan (2006) - Dövlət Neft Fondu (1999) məhz Bakı-Supsa kəməri ilə EYNİ ildə yaradıldı.
2) 1-ci mülahizəyə əsasən, Neft Fondu yaradılanda («Əsrin müqaviləsi»ndən, 1994-dən, 5 il sonra) hələ Bakı-Tbilisi-Ceyhan kəməri (2006) fəaliyyətdə deyildi, yalnız iki kəmər işləyirdi.
3) Səngəçal terminalı emal zavodu ilə benzin doldurma məntəqələri arasındakı halqadır.
4) Bu üç kəmərin hamısı Səngəçal terminalından (dəniz yataqları ilə ixrac kəmərləri arasındakı halqadan) başlayır.',
  '1, 2 və 4 doğrudur: Neft Fondu (1999) Bakı-Supsa kəməri (1999) ilə eyni ildə yaradıldı, «Əsrin müqaviləsi»ndən (1994) 5 il sonra - o zaman BTC (2006) hələ yox idi; hər üç kəmər Səngəçal terminalından başlayır. 3-cü mülahizə yanlışdır: Səngəçal terminalı dəniz yataqları İLƏ ixrac kəmərləri arasındakı halqadır, emal zavodu-benzin doldurma məntəqəsi arasında deyil.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix11-musteqillik#7'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
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

-- ------------------------------------------------------------- tarix11-sovet#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix11-sovet#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix11-sovet#comb1', 'tarix-11-sovet',
  'Sovet dövrü Azərbaycanı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Neft Daşları (1949) ilə Mingəçevir SES (1953) arasındakı fərq (4 il), Mingəçevir SES (1953) ilə Bakı metrosu (1967) arasındakı fərqdən (14 il) KİÇİKDİR.
2) 1-ci mülahizəyə əsasən, ilk televiziya yayımı (1956) Neft Daşlarının açılışından (1949) sonra, lakin Bakı metrosunun açılışından (1967) ƏVVƏL baş verib.
3) Hərbi kommunizm siyasəti NEP-dən (1921-ci ildən) SONRA, 1930-cu illərdə tətbiq olundu.
4) Neft Daşları (1949) kollektivləşdirmənin (1930-cu illər) artıq başa çatmasından sonrakı dövrün məhsuludur.',
  '1, 2 və 4 doğrudur: Neft Daşları-Mingəçevir fərqi 4 il, Mingəçevir-metro fərqi isə 14 ildir (4 < 14); televiziya (1956) bu iki tarix arasındadır; Neft Daşları kollektivləşdirmədən (1930-cu illər) sonrakı dövrün məhsuludur. 3-cü mülahizə yanlışdır: hərbi kommunizm (1918-1921) NEP-dən (1921-) ƏVVƏL tətbiq olundu, sonra yox - ardıcıllıq əksinədir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix11-sovet#4'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
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

-- ------------------------------------------------------------- cog11-ekoloji-qlobal#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-ekoloji-qlobal#8';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-ekoloji-qlobal#comb1', 'cog-11-ekoloji-qlobal',
  'Qlobal ekoloji problemlərlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ozon təbəqəsinin nazilməsinə freonlar səbəb olub; Monreal protokolu bu maddələrin istehsalını məhdudlaşdırır - deməli protokol birbaşa bu problemin həllinə yönəlib.
2) 1-ci mülahizəyə əsasən, Monreal protokolu karbon neytrallığı ilə EYNİ hədəfi güdür, çünki hər ikisi «atmosferə zərərli qazların tənzimlənməsi»dir.
3) Davamlı İnkişaf Məqsədləri (DİM) 2015-ci ildə qəbul edilib.
4) Beynəlxalq ekoloji sazişlərin icrasında əsas çətinlik ölkələrin iqtisadi maraqlarının uyğunlaşdırılmasıdır.',
  '1, 3 və 4 doğrudur: freonlar ozonu dağıdır, Monreal protokolu bunları məhdudlaşdırır - problem və həll uyğundur; DİM 2015-ci ildə qəbul edilib; ekoloji sazişlərin icrasında əsas çətinlik ölkələrin iqtisadi maraqlarının uyğunlaşdırılmasıdır. 2-ci mülahizə yanlışdır: Monreal protokolu OZONDAĞIDICI maddələri (freonlar) hədəfləyir, karbon neytrallığı isə KARBON qazının tarazlığına aiddir - fərqli iki qlobal problemdir, eyni hədəf deyil.',
  '1, 2, 3, 4', '1, 2, 3', '1, 3, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-ekoloji-qlobal#8'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- cog11-enerji-erzaq#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-enerji-erzaq#6';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-enerji-erzaq#comb1', 'cog-11-enerji-erzaq',
  'Enerji və ərzaq təhlükəsizliyi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Yaşıl inqilab yüksək məhsuldar sortlar, gübrə və suvarma ilə kənd təsərrüfatı məhsuldarlığını artırdı; eyni zamanda bu artım gübrə/pestisid yükünü, torpaq-su çirklənməsini də gətirdi - məhsuldarlıq artımı və çirklənmə EYNİ prosesin (gübrələmənin artmasının) iki nəticəsidir.
2) 1-ci mülahizəyə əsasən, yaşıl inqilabın «xalis» (yalnız müsbət) nəticə olduğunu iddia etmək yanlışdır.
3) Geotermal enerji İslandiya kimi vulkanik ölkələrdə geniş yayılıbsa, hidrogen enerjisi də eyni səbəbdən (vulkanik fəallıqdan) asılıdır.
4) Hidrogen enerjisinin perspektivi onun yanma məhsulunun yalnız su olması ilə bağlıdır, coğrafi mövqedən asılı deyil.',
  '1, 2 və 4 doğrudur: yaşıl inqilabın məhsuldarlıq artımı və çirklənməsi eyni prosesin iki üzüdür - xalis müsbət deyil; hidrogenin üstünlüyü yanma məhsulunun təmizliyi ilə bağlıdır, coğrafi mövqedən asılı deyil. 3-cü mülahizə yanlışdır: geotermal enerji vulkanik fəallıqdan (coğrafi amil) asılıdır, hidrogen enerjisi isə kimyəvi xüsusiyyətindən (yanma məhsulu) asılıdır - ikisini eyni səbəbə bağlamaq olmaz.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-enerji-erzaq#6'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- cog11-inteqrasiya#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-inteqrasiya#3';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-inteqrasiya#comb1', 'cog-11-inteqrasiya',
  'İqtisadi inteqrasiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İnteqrasiyanın ən sadə forması (azad ticarət zonası) ölkələr arası gömrük rüsumlarını azaldır; gömrük ittifaqı isə bundan fərqli olaraq ÜÇÜNCÜ ölkələrə qarşı VAHİD tarif tətbiq edir - gömrük ittifaqı azad ticarət zonasından DAHA DƏRİN inteqrasiya formasıdır.
2) 1-ci mülahizəyə əsasən, gömrük ittifaqına keçid ölkənin öz gömrük siyasətini müstəqil müəyyən etmək sərbəstliyini azaldır.
3) İnteqrasiyanın dərinləşməsi HƏMİŞƏ bütün üzv ölkələrə bərabər fayda verir, mənfi tərəfi yoxdur.
4) TAP kəməri Cənub Qaz Dəhlizinin son həlqəsi olaraq qazı Avropa bazarına (İtaliyaya) çatdırır.',
  '1, 2 və 4 doğrudur: gömrük ittifaqı üçüncü ölkələrə vahid tarif tətbiq etməklə azad ticarət zonasından dərinləşir, bu, üzv ölkənin öz gömrük siyasətini müstəqil müəyyənləşdirmə sərbəstliyini azaldır; TAP Cənub Qaz Dəhlizinin son həlqəsidir. 3-cü mülahizə yanlışdır: inteqrasiyanın mənfi tərəfi də var - zəif iqtisadiyyatlar güclü rəqiblərin təzyiqi altında qala bilər.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-inteqrasiya#3'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- cog11-iqtisadi-inkisaf#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-iqtisadi-inkisaf#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-iqtisadi-inkisaf#comb1', 'cog-11-iqtisadi-inkisaf',
  'Sənayenin yerləşməsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Metallurgiya müəssisələri xammal/yanacaq amilinə görə, yüngül sənaye isə işçi qüvvəsi/bazar amilinə görə yerləşdirilir - bu iki sənaye növü FƏRQLİ amillərə görə yer seçir.
2) 1-ci mülahizəyə əsasən, elmtutumlu sahələr (kadr/elm mərkəzi amili) bu ikisindən DƏ fərqli, ÜÇÜNCÜ bir amilə əsaslanır - deməli sənaye yerləşməsi tək universal qaydaya tabe deyil.
3) Bakı Beynəlxalq Dəniz Ticarət Limanının Ələtdə yerləşməsi məhz metallurgiyanın xammal amilinə görədir.
4) Ələtdəki azad ticarət zonasının məqsədi güzəştli rejimlə xarici investisiya və tranzit ticarətini cəlb etməkdir.',
  '1, 2 və 4 doğrudur: metallurgiya xammal/yanacağa, yüngül sənaye işçi qüvvəsi/bazara, elmtutumlu sahələr isə kadr/elm mərkəzlərinə görə yerləşir - üç fərqli amil, tək universal qayda yoxdur; Ələtdəki azad ticarət zonasının məqsədi investisiya/tranzit cəlbidir. 3-cü mülahizə yanlışdır: limanın Ələtdə yerləşməsi tranzit-coğrafi mövqe səbəbindəndir, metallurgiyanın xammal amili ilə heç bir əlaqəsi yoxdur - fərqli sənaye amillərinin səhv qarışdırılmasıdır.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-iqtisadi-inkisaf#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- cog11-qloballasma#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-qloballasma#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-qloballasma#comb1', 'cog-11-qloballasma',
  'Qloballaşma ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Konteyner daşımaları yükü ucuzlaşdırıb standartlaşdırdı - bu, qlobal tədarük zəncirlərinin mümkün olmasına şərait yaratdı.
2) 1-ci mülahizəyə əsasən, bu zəncirlərin ZƏİF nöqtəsi var - bir həlqədəki fasilə bütün zənciri dayandıra bilər, deməli ucuzluq eyni zamanda KIRILGANLIQ gətirib.
3) Maliyyə bazarlarının qloballaşması riskləri azaldır, çünki böhran bir ölkədə qalıb yayılmır.
4) Kiçik ölkələrin strategiyası konkret sahələrdə ixtisaslaşıb rəqabət üstünlüyü qazanmaqdır - qlobal tədarük zəncirində öz «həlqəsini» tapmaq deməkdir.',
  '1, 2 və 4 doğrudur: konteyner daşımaları qlobal tədarük zəncirlərini mümkün etdi, amma bu zəncirlər kırılgandır (bir həlqə kəsilsə hamısı dayanır); kiçik ölkələr ixtisaslaşaraq zəncirdə öz yerini tapmalıdır. 3-cü mülahizə yanlışdır: maliyyə bazarlarının qloballaşması riski AZALTMIR, ƏKSİNƏ artırır - bir ölkədəki böhran sürətlə digərlərinə yayıla bilir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-qloballasma#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- cog11-tebii-ehtiyat#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-tebii-ehtiyat#5';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-tebii-ehtiyat#comb1', 'cog-11-tebii-ehtiyat',
  'Təbii ehtiyatlarla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Yanacaq-energetika xammalı əsasən çökmə süxurlarda, filiz faydalı qazıntılar isə qırışıqlıq zonalarında/qalxanlarda toplanır - bu, iki mineral qrupunun FƏRQLİ geoloji strukturlarda formalaşdığını göstərir.
2) 1-ci mülahizəyə əsasən, eyni ərazidə HƏM yanacaq, HƏM filiz ehtiyatının bol olması gözlənilməz haldır, çünki onlar əks tip geoloji strukturlar tələb edir.
3) Resurslarla təminat göstəricisi ehtiyatın ƏHALİYƏ nisbəti ilə hesablanır.
4) Təbii ehtiyatların iqtisadi qiymətləndirilməsi təkcə kəmiyyəti yox, keyfiyyəti, yerləşmə şəraitini və çıxarma xərcini də nəzərə alır.',
  '1, 2 və 4 doğrudur: yanacaq-energetika çökmə süxurlarda, filiz isə qırışıqlıq zonalarında toplanır - əks geoloji strukturlar, eyni ərazidə hər ikisinin bol olması gözlənilməzdir; iqtisadi qiymətləndirmə kəmiyyət, keyfiyyət, yerləşmə və xərci nəzərə alır. 3-cü mülahizə yanlışdır: resurslarla təminat göstəricisi ehtiyatın İLLİK HASİLATA nisbəti ilə hesablanır, əhaliyə nisbətlə yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-tebii-ehtiyat#5'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- cog11-xerite-cis#comb1
update public.questions set difficulty = 2 where ext_key = 'cog11-xerite-cis#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog11-xerite-cis#comb1', 'cog-11-xerite-cis',
  'Xəritə və CİS ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Xəritə proyeksiyası kürə səthini müstəviyə keçirmək üçün istifadə olunur; bu zaman təhriflərin olması QAÇILMAZDIR - kürəni tam təhrifsiz müstəviyə keçirmək mümkün deyil.
2) 1-ci mülahizəyə əsasən, hər bir xəritə (proyeksiyaya əsaslandığı üçün) müəyyən dərəcədə TƏHRİF daşıyır - «təhrifsiz xəritə» anlayışı mövcud deyil.
3) Yalnız KİÇİK miqyaslı xəritələrdə təhrif olur, böyük miqyaslılarda olmur.
4) CİS-in əsas üstünlüyü müxtəlif məlumat qatlarını üst-üstə salıb birgə təhlil etmək imkanıdır.',
  '1, 2 və 4 doğrudur: proyeksiya kürəni müstəviyə keçirir, bu, qaçılmaz təhrif yaradır - hər xəritə müəyyən təhrif daşıyır; CİS-in üstünlüyü fərqli qatları üst-üstə salıb birgə təhlil etməkdir. 3-cü mülahizə yanlışdır: təhrif YALNIZ kiçik xəritələrə aid deyil - bütün proyeksiyalarda, miqyasından asılı olmayaraq, qaçılmazdır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog11-xerite-cis#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
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

-- ------------------------------------------------------------- fiz11-cereyan-qanunlari#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz11-cereyan-qanunlari#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz11-cereyan-qanunlari#comb1', 'fiz-11-cereyan-qanunlari',
  'Elektrik cərəyanı qanunları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Coul-Lens qanununa görə ayrılan istilik (Q = I²Rt) cərəyanın KVADRATI ilə düz mütənasibdir; elektrik enerjisi uzaq məsafəyə YÜKSƏK gərginlikdə ötürülür ki, cərəyan KİÇİK olsun - yüksək gərginlik seçimi məhz bu kvadratik asılılıqdan irəli gəlir.
2) 1-ci mülahizəyə əsasən, cərəyanı 2 dəfə azaltmaq (gərginliyi 2 dəfə artırmaqla) xətdəki istilik itkisini 4 dəfə azaldır.
3) Ampermetrin müqaviməti PARALEL qoşulduğu üçün kiçik olmalıdır.
4) Voltmetrin müqavimətinin böyük olması PARALEL qoşulmuş dövrəni az pozmasına xidmət edir.',
  '1, 2 və 4 doğrudur: Coul-Lens qanununa görə istilik cərəyanın kvadratı ilə mütənasibdir, ona görə yüksək gərginliklə cərəyanı azaltmaq itkini kvadratik azaldır (2 dəfə azaltsan, itki 4 dəfə azalır); voltmetrin böyük müqaviməti paralel qoşulmuş dövrəni az pozur. 3-cü mülahizə yanlışdır: ampermetr ARDICIL qoşulur (paralel yox), ona görə müqaviməti kiçik olmalıdır ki, dövrədəki cərəyanı dəyişməsin.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz11-cereyan-qanunlari#16'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
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

-- ------------------------------------------------------------- fiz11-elektrostatika#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz11-elektrostatika#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz11-elektrostatika#comb1', 'fiz-11-elektrostatika',
  'Elektrostatika ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ekvipotensial səth bütün nöqtələrində potensialın eyni olduğu səthdir; sahə xətləri bu səthə PERPENDİKULYARDIR (90°).
2) 1-ci mülahizəyə əsasən, yükü ekvipotensial səth boyunca hərəkət etdirəndə GÖRÜLƏN İŞ SIFIRDIR, çünki potensiallar fərqi sıfırdır.
3) Ardıcıl birləşmiş kondensatorların ümumi tutumu tək kondensatorların CƏMİNƏ bərabərdir.
4) Paralel birləşmiş kondensatorların ümumi tutumu tək-tək tutumların cəminə bərabərdir.',
  '1, 2 və 4 doğrudur: ekvipotensial səth sahə xəttinə perpendikulyardır, bu səth boyunca hərəkətdə iş sıfırdır (potensiallar fərqi yoxdur); paralel kondensatorlarda tutumlar toplanır. 3-cü mülahizə yanlışdır: ARDICIL birləşmədə ümumi tutum ən kiçik kondensatordan da kiçik olur - cəminə bərabər olan PARALEL birləşmədir, ardıcıl deyil.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz11-elektrostatika#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
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

-- ------------------------------------------------------------- fiz11-em-reqs#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz11-em-reqs#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz11-em-reqs#comb1', 'fiz-11-em-reqs',
  'Dəyişən cərəyan və rəqslərlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Dəyişən cərəyan dövrəsində sarğacın induktiv müqaviməti tezliklə DÜZ mütənasibdir, kondensatorun tutum müqaviməti isə tezliklə TƏRS mütənasibdir - bu iki elementin tezliyə reaksiyası ƏKSDİR.
2) 1-ci mülahizəyə əsasən, tezlik ARTANDA sarğacın müqaviməti artır, kondensatorun müqaviməti isə azalır.
3) Hər ikisi (sarğac və kondensator) tezliklə eyni istiqamətdə (düz mütənasib) dəyişir.
4) Konturda tutum 4 dəfə artarsa, rəqs dövrü (kökaltı asılılığa görə) 2 dəfə artar.',
  '1, 2 və 4 doğrudur: induktiv müqavimət tezliklə düz, tutum müqaviməti tezliklə tərs mütənasibdir - əks reaksiyalar, tezlik artanda biri artır, digəri azalır; tutum 4 dəfə artanda Tomson düsturuna görə dövr kökaltı asılılıqla 2 dəfə artır. 3-cü mülahizə yanlışdır: sarğac və kondensatorun müqaviməti tezliyə ƏKS istiqamətdə reaksiya verir, eyni istiqamətdə yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz11-em-reqs#29'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
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

-- ------------------------------------------------------------- fiz11-maqnit-induksiya#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz11-maqnit-induksiya#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz11-maqnit-induksiya#comb1', 'fiz-11-maqnit-induksiya',
  'Elektromaqnit induksiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Lens qaydasına görə, sarğaca maqnit yaxınlaşdıranda induksiya cərəyanının maqnit sahəsi bu yaxınlaşmaya MANE OLAN istiqamətdə yönəlir; özüninduksiya da EYNİ prinsipin xüsusi halıdır - dövrədə cərəyan dəyişəndə yaranan EHQ bu dəyişikliyə MANE OLUR.
2) 1-ci mülahizəyə əsasən, dövrə açılan anda özüninduksiya EHQ-si bu kəsilməyə mane olmağa çalışır, nəticədə gərginlik sıçrayışı və qığılcım yaranır.
3) Transformator nüvəsi nazik lövhələrdən yığılır ki, maqnit selini GÜCLƏNDİRSİN.
4) Fuko (burulğan) cərəyanları HƏMİŞƏ zərərli deyil - induksiya sobalarında metalın əridilməsi kimi faydalı tətbiqi də var.',
  '1, 2 və 4 doğrudur: Lens qaydası və özüninduksiya eyni prinsipin (dəyişikliyə müqavimət) təzahürüdür - dövrə açılanda özüninduksiya EHQ-si kəsilməyə mane olur, qığılcım yaranır; Fuko cərəyanlarının faydalı tətbiqi də var (induksiya sobaları). 3-cü mülahizə yanlışdır: transformator lövhələri burulğan cərəyanı İTKİSİNİ AZALTMAQ üçün nazikdir, seli gücləndirmək üçün yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz11-maqnit-induksiya#14'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
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

-- ------------------------------------------------------------- fiz11-optika#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz11-optika#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz11-optika#comb1', 'fiz-11-optika',
  'Foton və fotoeffektlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Foton enerjisi E = hν düsturu ilə hesablanır - tezlik nə qədər böyükdürsə, foton enerjisi də o qədər böyükdür.
2) 1-ci mülahizəyə əsasən, fotoeffektin baş verməsi üçün minimum (qırmızı sərhəd) tezlik tələb olunması, əslində minimum FOTON ENERJİSİNİN tələb olunması deməkdir.
3) Fotoeffektdə qopan elektronların maksimal kinetik enerjisi işığın İNTENSİVLİYİNDƏN asılıdır.
4) Prizmadan keçən ağ işıqda bənövşəyi şüa ən çox sınır - bu, dispersiya hadisəsinin (sındırma əmsalının dalğa uzunluğundan asılılığının) nəticəsidir.',
  '1, 2 və 4 doğrudur: E=hν-ə görə tezlik artdıqca foton enerjisi artır; fotoeffektin qırmızı sərhədi minimum foton enerjisi tələbidir; bənövşəyi işığın ən çox sınması dispersiyanın nəticəsidir. 3-cü mülahizə yanlışdır: fotoeffektdə maksimal kinetik enerji İŞIĞIN TEZLİYİNDƏN asılıdır, intensivlikdən DEYİL - intensivlik yalnız qopan elektronların SAYINI artırır, enerjisini yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz11-optika#14'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
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

-- ------------------------------------------------------------- kim11-aldehid-tursu#comb1
update public.questions set difficulty = 2 where ext_key = 'kim11-aldehid-tursu#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim11-aldehid-tursu#comb1', 'kim-11-aldehid-tursu',
  'Aldehid, keton və turşularla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Aldehidlər gümüş güzgü reaksiyası ilə təyin olunur; aseton isə keton sinfinə aiddir - aldehid və keton FƏRQLİ sinif adları daşısa da, hər ikisində karbonil qrupu (C=O) var.
2) 1-ci mülahizəyə əsasən, karbonil qrupunun ortaqlığı aldehid və ketonların bəzi kimyəvi oxşarlıqlara malik olmasına səbəb olur, amma bu, onları EYNİ sinif etmir.
3) Aseton da gümüş güzgü reaksiyası verir, çünki tərkibində aldehidlər kimi karbonil qrupu var.
4) Karbon turşularının turşuluğu karbon zənciri uzandıqca zəifləyir.',
  '1, 2 və 4 doğrudur: aldehid gümüş güzgü ilə təyin olunur, aseton isə keton sinfinə aiddir - hər ikisində karbonil qrupu olsa da, bu, onları eyni sinif etmir; karbon turşularının turşuluğu zəncir uzandıqca zəifləyir. 3-cü mülahizə yanlışdır: gümüş güzgü reaksiyası məhz ALDEHİD qrupunu (tərkibində H olan karbonil) aşkarlayır - ketonlarda (aseton kimi) bu H yoxdur, ona görə ketonlar bu reaksiyanı vermir; karbonil qrupunun ortaqlığı reaktivlik ortaqlığı demək deyil.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim11-aldehid-tursu#18'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
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

-- ------------------------------------------------------------- kim11-azotlu#comb1
update public.questions set difficulty = 2 where ext_key = 'kim11-azotlu#30';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim11-azotlu#comb1', 'kim-11-azotlu',
  'Zülallarla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Zülalın birincili quruluşu aminturşuların zəncirdəki ARDICILLIĞINI bildirir; ikincili quruluş isə bu zəncirin fəzada spiral/büküş FORMASINI alması deməkdir - ikincili quruluş birincili quruluşun üzərində formalaşır.
2) 1-ci mülahizəyə əsasən, ağır metal duzlarının yaratdığı dönməz denaturasiya zülalın FƏZA formasını pozur, amma aminturşu ARDICILLIĞINI (birincili quruluşu) DƏYİŞMİR.
3) Denaturasiya zülalın aminturşu ardıcıllığını (birincili quruluşunu) dəyişdiyi üçün zəhərlidir.
4) Biuret reaksiyası zülalın mövcudluğunu bənövşəyi rənglə göstərən keyfiyyət reaksiyasıdır.',
  '1, 2 və 4 doğrudur: birincili quruluş aminturşu ardıcıllığı, ikincili isə bu zəncirin fəza formasıdır - ikincili birincilinin üzərində qurulur; ağır metal duzları fəza formasını (denaturasiya) pozur, amma ardıcıllığı dəyişmir; biuret reaksiyası zülalı bənövşəyi rənglə aşkarlayır. 3-cü mülahizə yanlışdır: denaturasiya FƏZA QURULUŞUNU pozur, aminturşu ARDICILLIĞINI dəyişmir.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim11-azotlu#30'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
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

-- ------------------------------------------------------------- kim11-efir-yag#comb1
update public.questions set difficulty = 2 where ext_key = 'kim11-efir-yag#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim11-efir-yag#comb1', 'kim-11-efir-yag',
  'Yağlar və sabunla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Sabun molekulunun bir ucu suya (polyar), digər ucu yağa (qeyri-polyar) meyllidir - bu ikili quruluş sayəsində kir hissəcikləri əhatələnir; yağ molekulları isə TAMAMİLƏ qeyri-polyar olduğu üçün suda həll OLMUR.
2) 1-ci mülahizəyə əsasən, sabun yağdan fərqli olaraq HƏM polyar, HƏM qeyri-polyar hissəyə malikdir - bu quruluş fərqi onun yuyuculuq qabiliyyətinin mənbəyidir.
3) Cod suda sabunun yuyuculuq qabiliyyəti sadəcə suyun temperaturundan asılıdır.
4) Bitki yağlarının maye, heyvan piylərinin isə bərk olmasının səbəbi doymamış turşuların nisbətidir.',
  '1, 2 və 4 doğrudur: sabun molekulunun ikili (polyar+qeyri-polyar) quruluşu onu yağdan (tamamilə qeyri-polyar) fərqləndirir və yuyuculuq qabiliyyəti verir; bitki yağlarının maye olması doymamış turşuların çoxluğundandır. 3-cü mülahizə yanlışdır: cod suda sabunun yuyuculuğunun azalması Ca/Mg ionları ilə həll olmayan duzların əmələ gəlməsindən irəli gəlir, temperaturdan yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim11-efir-yag#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
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

-- ------------------------------------------------------------- kim11-polimer#comb1
update public.questions set difficulty = 2 where ext_key = 'kim11-polimer#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim11-polimer#comb1', 'kim-11-polimer',
  'Polimerlərlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Termoplastik polimer qızdırıldıqda yumşalır, soyuduqda bərkiyir - TƏKRAR emal oluna bilir; termoreaktiv polimer isə bir dəfə bərkidikdən sonra təkrar ƏRİDİLƏ BİLMİR - bu iki tip davranış baxımından ƏKSDİR.
2) 1-ci mülahizəyə əsasən, xətti quruluşlu polimerlər (elastik/plastik) termoplastik davranışa daha yaxındır, fəza (şəbəkəli) quruluşlular isə termoreaktiv davranışa.
3) Vulkanizasiya prosesi (kauçuka kükürd qatılması) kauçuku TERMOPLASTİK edir, çünki rezin daha çevik olur.
4) Polimerlər quruluşuna görə xətti, budaqlanmış və fəza (şəbəkəli) olmaqla üç növə bölünür.',
  '1, 2 və 4 doğrudur: termoplastik təkrar emal olunur, termoreaktiv olunmur - əks davranış; xətti quruluş termoplastikə, fəza (şəbəkəli) quruluş isə termoreaktivə yaxındır; polimerlər xətti/budaqlanmış/fəza olaraq üç növə bölünür. 3-cü mülahizə yanlışdır: vulkanizasiya kauçuk zəncirləri arasında kükürd körpüləri yaradaraq FƏZA quruluş formalaşdırır - bu, kauçuku TERMOREAKTİV xassəyə yaxınlaşdırır, termoplastikə yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim11-polimer#10'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
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

-- ------------------------------------------------------------- kim11-spirtler#comb1
update public.questions set difficulty = 2 where ext_key = 'kim11-spirtler#11';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim11-spirtler#comb1', 'kim-11-spirtler',
  'Spirtlər və fenolla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Spirtlərin qaynama temperaturunun eyni kütləli karbohidrogenlərdən yüksək olması hidrogen rabitəsi ilə bağlıdır; spirtlərin suda həllolması da eyni mexanizmə əsaslanır, amma karbon zənciri UZANDIQCA bu həllolma AZALIR.
2) 1-ci mülahizəyə əsasən, kiçik spirt molekulları (məsələn, metanol) böyük (uzun zəncirli) spirt molekullarından suda DAHA YAXŞI həll olur.
3) Çoxatomlu spirtləri təyin etmək üçün dəmir(III) xlorid reaktivindən istifadə olunur.
4) Fenolun məhlulunu təyin etmək üçün dəmir(III) xlorid bənövşəyi rəng verir.',
  '1, 2 və 4 doğrudur: spirtlərin yüksək qaynama temperaturu və suda həllolması eyni hidrogen rabitəsi mexanizminə əsaslanır, amma zəncir uzandıqca həllolma azalır - kiçik spirtlər daha yaxşı həll olur; fenol dəmir(III) xloridlə bənövşəyi rəng verir. 3-cü mülahizə yanlışdır: çoxatomlu spirtlər MİS (II) HİDROKSİDLƏ təyin olunur, dəmir(III) xlorid isə FENOLUN reaktividir - fərqli maddələr, fərqli reaktivlər.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim11-spirtler#11'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
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

-- ------------------------------------------------------------- bio11-bakteriyalar#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-bakteriyalar#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-bakteriyalar#comb1', 'bio-11-bakteriyalar',
  'Bakteriyalarla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Sporlar yüksək temperatura və quruluğa davamlıdır; konservlərin sterilizasiyası buna görə YÜKSƏK temperaturda aparılır, çünki adi qaynatma sporları öldürmür.
2) 1-ci mülahizəyə əsasən, pasterizasiya (aşağı temperaturda mikrobların yalnız BÖYÜK hissəsini məhv edən proses) sporlu bakteriyaları TAM məhv ETMİR - bu, pasterizasiyanın sterilizasiyadan fərqli, daha yüngül proses olmasının səbəbidir.
3) Pasterizasiya da sterilizasiya kimi bütün mikroorqanizmləri (sporlar daxil) tam məhv edir.
4) Antibiotiklərin nəzarətsiz istifadəsi bakteriyalarda davamlılıq (rezistentlik) yaradır - bu, sporun davamlılığından fərqli, tamamilə ayrı bir mexanizmdir.',
  '1, 2 və 4 doğrudur: sporlar yüksək temp/quruluğa davamlıdır, ona görə konserv sterilizasiyası yüksək temperatur tələb edir; pasterizasiya isə aşağı temperaturda yalnız mikrobların böyük hissəsini məhv edir, sporlu bakteriyaları tam yox etmir; antibiotik rezistentliyi tamam fərqli, qazanılmış bir müdafiə mexanizmidir. 3-cü mülahizə yanlışdır: pasterizasiya sterilizasiya DEYİL - tam mikrob yox etmə deyil, yalnız azaltmadır.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-bakteriyalar#7'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- bio11-biosfer#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-biosfer#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-biosfer#comb1', 'bio-11-biosfer',
  'Ekologiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ekoloji piramidada hər səviyyəyə keçdikdə enerjinin ~90%-i itir, yalnız 10%-i ötürülür; BUNA GÖRƏ qida zəncirinin uzunluğu adətən 4-5 həlqədən çox olmur - enerji itkisi zəncirin uzunluğunu MƏHDUDLAŞDIRAN səbəbdir.
2) 1-ci mülahizəyə əsasən, 6-cı həlqəyə çatan enerji miqdarı ilk səviyyədəkindən təxminən 100 000 (10⁵) dəfə az olardı.
3) Vulkan lavası üzərində həyatın yenidən başlaması İKİNCİLİ suksessiyaya misaldır, çünki torpaq artıq mövcuddur.
4) Yanmış meşənin yerində bərpa isə İKİNCİLİ suksessiyadır, çünki torpaq qalıb.',
  '1, 2 və 4 doğrudur: enerjinin yalnız 10%-i növbəti səviyyəyə keçir, bu, zəncirin 4-5 həlqədən uzun olmamasının səbəbidir; 5 keçiddən sonra enerji 10⁵ dəfə azalar - artıq həlqəni dəstəkləməz; yanmış meşədə torpaq qaldığı üçün bərpa ikincili suksessiyadır. 3-cü mülahizə yanlışdır: vulkan lavası üzərində torpaq YOXDUR, bu, İLKİN suksessiyaya misaldır, ikincili yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-biosfer#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- bio11-biotexnologiya#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-biotexnologiya#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-biotexnologiya#comb1', 'bio-11-biotexnologiya',
  'Biotexnologiya üsulları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) PZR (polimeraza zəncir reaksiyası) az miqdarda DNT parçasını ÇOXALTMAQ üçün istifadə olunur; gen terapiyası isə zədəli genin işini DÜZƏLTMƏK və ya ƏVƏZ etmək üçündür - bu iki texnologiya FƏRQLİ məqsədlərə xidmət edir.
2) 1-ci mülahizəyə əsasən, PZR gen terapiyasının ƏVƏZİ DEYİL - biri analiz/çoxaltma, digəri müalicə/düzəliş vasitəsidir.
3) PZR həm DNT-ni çoxaldır, həm də zədəli geni düzəldir, ona görə PZR gen terapiyasının bir növüdür.
4) Mikroklonal çoxaltma (bitki toxuma kulturası) sənaye mikrobiologiyasında ştamın seleksiya və gen mühəndisliyi ilə təkmilləşdirilməsindən FƏRQLİ bir texnologiyadır.',
  '1, 2 və 4 doğrudur: PZR DNT-ni çoxaldır (analiz aləti), gen terapiyası isə zədəli geni düzəldir/əvəz edir (müalicə aləti) - fərqli məqsədlər; mikroklonal çoxaltma (bitki) və ştam təkmilləşdirmə (mikrob) də fərqli texnologiyalardır. 3-cü mülahizə yanlışdır: PZR yalnız mövcud DNT-nin SURƏTİNİ çoxaldır, geni dəyişdirmir/düzəltmir - bu, gen terapiyasının funksiyasıdır, PZR-in yox.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-biotexnologiya#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- bio11-bolunme-nezaret#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-bolunme-nezaret#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-bolunme-nezaret#comb1', 'bio-11-bolunme-nezaret',
  'Hüceyrə bölünməsi və nəzarəti ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Meyoz olmasaydı, hər mayalanmadan sonra xromosom sayı nəsildən-nəslə İKİQAT artardı; krossinqover isə meyozun BİRİNCİ bölünməsinin profazasında baş verir və homoloji xromosomlar arasında gen mübadiləsi ilə yeni kombinasiyalar yaradır - meyoz HƏM xromosom sayını sabit saxlayır, HƏM DƏ genetik müxtəliflik yaradır.
2) 1-ci mülahizəyə əsasən, meyozun bu iki funksiyası (say sabitliyi və müxtəliflik) BİR-BİRİNDƏN ASILI DEYİL - biri bölünmə SAYI, digəri krossinqoverin BAŞ VERMƏSİ ilə bağlıdır.
3) Apoptoz (proqramlaşdırılmış hüceyrə ölümü) bədxassəli şişin əsas əlaməti kimi baş verir.
4) Xoşxassəli şişin bədxassəlidən fərqi metastaz VERMƏMƏSİDİR.',
  '1, 2 və 4 doğrudur: meyoz həm xromosom sayını sabit saxlayır, həm krossinqoverlə (profaza I-də) genetik müxtəliflik yaradır - bu iki funksiya bir-birindən asılı deyil; xoşxassəli şiş metastaz vermir. 3-cü mülahizə yanlışdır: apoptoz FAYDALI, nəzarətli prosesdir - zədəli hüceyrələri təmizləyir; əksinə, apoptozun POZULMASI (hüceyrələrin ölməməsi) bədxassəli şişin səbəblərindəndir, apoptozun özü yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-bolunme-nezaret#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- bio11-heyatin-yaranmasi#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-heyatin-yaranmasi#8';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-heyatin-yaranmasi#comb1', 'bio-11-heyatin-yaranmasi',
  'Həyatın yaranması ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İlk canlılar heterotrof idi (ilkin bulyondan hazır üzvi maddə alırdılar); avtotrof qidalanma isə bu üzvi maddə ehtiyatı TÜKƏNƏNDƏ həyatın davamını təmin etdi - avtotrofluq heterotrofluqdan SONRA, zərurətdən yaranıb.
2) 1-ci mülahizəyə əsasən, Miller-Yurin təcrübəsi (aminturşuların abiogen alınması) heterotrof mərhələni DƏSTƏKLƏYİR, çünki bu aminturşular İLKİN BULYONUN tərkib hissəsi idi.
3) İlk canlılar avtotrof idi, çünki fotosintez ən sadə qidalanma üsuludur.
4) Mitoxondri və plastidlərin öz DNT-sinin olması onların simbioz bakteriyalardan yarandığı fikrini (simbiogenez) dəstəkləyir.',
  '1, 2 və 4 doğrudur: ilk canlılar heterotrof idi, avtotrofluq üzvi ehtiyat tükənəndə zərurətdən yarandı; Miller-Yurin təcrübəsi ilkin bulyondakı aminturşuların mənbəyini göstərərək heterotrof mərhələni dəstəkləyir; mitoxondrinin öz DNT-si simbiogenezi dəstəkləyir. 3-cü mülahizə yanlışdır: ilk canlılar HETEROTROF idi, avtotrof deyil - avtotrofluq sonradan yaranıb.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-heyatin-yaranmasi#8'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- bio11-insan-muhit#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-insan-muhit#8';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-insan-muhit#comb1', 'bio-11-insan-muhit',
  'İnsan və ətraf mühitlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bioakkumulyasiya nəticəsində pestisidlər qida zəncirində toplanır; bu toplanma səbəbindən qida zəncirinin YUXARI həlqələrində (yırtıcılarda) zəhərli maddələrin qatılığı ƏN YÜKSƏK olur.
2) 1-ci mülahizəyə əsasən, insan qida zəncirinin YUXARI həlqəsindəki heyvanların (məsələn, iri yırtıcı balıqların) ətini istehlak edərkən DAHA ÇOX zəhərli maddə qəbul etmə riski daşıyır.
3) Bioakkumulyasiya nəticəsində zəhərli maddələrin qatılığı qida zəncirinin AŞAĞI həlqələrində ən yüksək olur.
4) Milli parkda (qoruqdan fərqli olaraq) tənzimlənən turizm və maarifləndirmə mümkündür.',
  '1, 2 və 4 doğrudur: bioakkumulyasiya nəticəsində zəhərli maddə qida zəncirinin yuxarı həlqələrində toplanır, buna görə insan yuxarı həlqədəki heyvanları istehlak edərkən daha çox risk daşıyır; milli parkda tənzimlənən turizmə icazə verilir. 3-cü mülahizə yanlışdır: zəhərli maddə qatılığı YUXARI həlqələrdə ən yüksəkdir, aşağıda yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-insan-muhit#8'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- bio11-viruslar#comb1
update public.questions set difficulty = 2 where ext_key = 'bio11-viruslar#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio11-viruslar#comb1', 'bio-11-viruslar',
  'İmmunitetlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Virus infeksiyasından sonra qazanılan immunitet TƏBİİ AKTİV immunitet adlanır; zərdab (hazır antitellər) yeridilməsi isə SÜNİ PASSİV immunitet yaradır və MÜVƏQQƏTİDİR - bu iki immunitet növü həm mənbəyinə, həm davamlılığına görə fərqlənir.
2) 1-ci mülahizəyə əsasən, təbii aktiv immunitet orqanizmin öz immun sisteminin reaksiyası olduğu üçün adətən süni passiv immunitetdən DAHA UZUNMÜDDƏTLİ olur.
3) Zərdab yeridilməsi təbii aktiv immunitet yaradır, çünki orqanizm antitelləri özü istehsal edir.
4) Kollektiv (sürü) immuniteti əhalinin böyük hissəsi immun olduqda xəstəliyin yayılmasının azalmasıdır - bu, FƏRDİ immunitetdən fərqli, populyasiya səviyyəsində bir hadisədir.',
  '1, 2 və 4 doğrudur: virus keçirtmə təbii aktiv, zərdab isə süni passiv (müvəqqəti) immunitet yaradır - mənbə və davamlılıqla fərqlənir; təbii aktiv immunitet adətən daha uzunmüddətlidir; kollektiv immunitet isə fərdi immunitetdən fərqli, populyasiya səviyyəli hadisədir. 3-cü mülahizə yanlışdır: zərdab SÜNİ PASSİV immunitet yaradır - orqanizm antitelləri özü istehsal etmir, hazır alır.',
  '1, 2, 3, 4', '1, 3, 4', '1, 2, 4', '2, 3', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio11-viruslar#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
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

-- ------------------------------------------------------------- inf11-komputer-veb#comb1
update public.questions set difficulty = 2 where ext_key = 'inf11-komputer-veb#19';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf11-komputer-veb#comb1', 'inf-11-komputer-veb',
  'Kompüter və veb texnologiyaları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Kompüter yüklənəndə (boot) İLK NÖVBƏDƏ mikroproqram (BIOS/UEFI) aparatı yoxlayıb sistemi başladır.
2) 1-ci mülahizəyə əsasən, sistem işə düşdükdən sonra tez-tez istifadə olunan verilənlər sürəti artırmaq üçün prosessora yaxın KEŞ YADDAŞDA saxlanılır.
3) Veb səhifələrdə şəkillərə alternativ mətn (alt) yazılmasının məqsədi səhifənin YÜKLƏNMƏ SÜRƏTİNİ artırmaqdır.
4) Veb formalarda daxil edilən məlumatın validasiya olunması səhv və zərərli verilənlərin qarşısını almaq üçün vacibdir.',
  '1, 2 və 4 doğrudur: yüklənmə BIOS/UEFI ilə başlayır, sistem işə düşdükdən sonra tez-tez lazım olan verilən sürət üçün keş yaddaşda saxlanılır, forma validasiyası isə səhv/zərərli verilənin qarşısını alır. 3-cü mülahizə yanlışdır: alt mətnin məqsədi sürət yox, ƏLÇATANLIQ (görmə məhdudiyyətli istifadəçilər) və axtarış sistemləridir - keş yaddaşın sürət funksiyası ilə səhv qarışdırılıb.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf11-komputer-veb#19'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
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

-- ------------------------------------------------------------- inf11-modellesdirme#comb1
update public.questions set difficulty = 2 where ext_key = 'inf11-modellesdirme#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf11-modellesdirme#comb1', 'inf-11-modellesdirme',
  'Modelləşdirmə anlayışları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Modelin VERİFİKASİYASI modelin düzgün qurulub-qurulmadığını (səhvsiz işlədiyini) yoxlayır.
2) 1-ci mülahizəyə əsasən, bu, modelin ADEKVATLIĞINDAN fərqli anlayışdır: adekvatlıq modelin real obyektin öyrənilən xassələrini kifayət qədər düzgün əks etdirib-etdirmədiyini yoxlayır.
3) Cədvəl prosessorunda «əgər-onda» ssenarilərinin yoxlanması (parametri dəyişib nəticəni izləmək) modelin VERİFİKASİYASINA aid bir əməliyyatdır.
4) Təsadüfi prosesləri modelləşdirmək üçün təsadüfi ədədlərlə çoxsaylı sınağa əsaslanan Monte-Karlo üsulundan istifadə olunur.',
  '1, 2 və 4 doğrudur: verifikasiya modelin texniki cəhətdən düzgün (səhvsiz) qurulmasını, adekvatlıq isə reallığı düzgün əks etdirməsini yoxlayır - ikisi fərqli anlayışdır; Monte-Karlo təsadüfi proseslərin modelləşdirilməsində işlədilir. 3-cü mülahizə yanlışdır: əgər-onda ssenarilərinin yoxlanması SSENARİ TƏHLİLİNƏ aiddir, verifikasiyaya yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf11-modellesdirme#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
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

-- ------------------------------------------------------------- inf11-sebeke-tex#comb1
update public.questions set difficulty = 2 where ext_key = 'inf11-sebeke-tex#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf11-sebeke-tex#comb1', 'inf-11-sebeke-tex',
  'İnternet və şəbəkə texnologiyaları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) VPN xidməti istifadəçinin internet trafikini şifrələyib təhlükəsiz tunel yaradır.
2) 1-ci mülahizəyə əsasən, HTTPS protokolundakı «S» hərfi də bənzər şəkildə əlaqənin ŞİFRƏLƏNDİYİNİ (Secure) bildirir - VPN kimi HTTPS də verilənləri üçüncü tərəflərdən qoruyur.
3) Şəbəkədə verilənlərin paketlərlə ötürülməsinin məqsədi trafiki ŞİFRƏLƏMƏKDİR.
4) DNS xidməti domen adını (sayt ünvanını) IP ünvana çevirir.',
  '1, 2 və 4 doğrudur: VPN və HTTPS hər ikisi şifrələmə yolu ilə təhlükəsizlik təmin edir; DNS isə ayrıca, domen adını IP-yə çevirən xidmətdir. 3-cü mülahizə yanlışdır: paketlərlə ötürmənin məqsədi şifrələmə deyil, ETİBARLI VƏ ÇEVİK ötürmədir - itən paket başqa yolla yenidən göndərilə bilir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf11-sebeke-tex#14'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
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

-- ------------------------------------------------------------- inf11-sistemler#comb1
update public.questions set difficulty = 2 where ext_key = 'inf11-sistemler#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf11-sistemler#comb1', 'inf-11-sistemler',
  'Sistemlər və süni intellektlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Avtomatik sistemdə insan iştirak etmir, avtomatlaşdırılmış sistemdə isə insan iştirakı olur - bu ikisinin əsas fərqidir.
2) 1-ci mülahizəyə əsasən, insansız işləyən avtomatik sistemlərdə əks əlaqə (geri bildirim) nəticəni ölçüb idarəni ona uyğun tənzimləmək üçün vacibdir.
3) Ekspert sistemi sensor ölçmələrinə əsaslanan əks əlaqə (geri bildirim) prinsipi ilə işləyən proqramdır.
4) Süni intellektdən istifadədə əsas etik problemlər şəxsi məlumatların qorunması (məxfilik) və qərarların qərəzsizliyidir.',
  '1, 2 və 4 doğrudur: avtomatik sistem insansız işlədiyi üçün nəticəyə görə özünü tənzimləyən əks əlaqə mexanizminə ehtiyac duyur; Sİ-də əsas etik problemlər məxfilik və qərəzsizlikdir. 3-cü mülahizə yanlışdır: ekspert sistemi sensor/əks əlaqə əsasında yox, MÜTƏXƏSSİS BİLİYİ əsasında nəticə çıxaran proqramdır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf11-sistemler#16'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
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

-- ------------------------------------------------------------- edeb11-cabbarli-vurgun#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-cabbarli-vurgun#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-cabbarli-vurgun#comb1', 'edeb-11-cabbarli-vurgun',
  'Cəfər Cabbarlı və Səməd Vurğunun yaradıcılığı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Cəfər Cabbarlının «Sevil» və «Od gəlini» pyesləri EYNİ ildə - 1928-ci ildə yazılmışdır.
2) 1-ci mülahizəyə əsasən, «Almaz» pyesi isə bir qədər sonra, 1931-ci ildə yazılmışdır - yəni bu üç əsər «Sevil»/«Od gəlini» (1928) → «Almaz» (1931) xronoloji ardıcıllığı ilə düzülür.
3) «Oqtay Eloğlu» pyesi neft sənayesinin problemlərinə həsr olunmuşdur.
4) Cəfər Cabbarlı ilə Səməd Vurğunun yaradıcılığındakı ortaq cəhət hər ikisinin dram janrına müraciət etməsidir.',
  '1, 2 və 4 doğrudur: Sevil və Od gəlini 1928-ci ildə, Almaz isə 1931-ci ildə yazılıb - xronoloji ardıcıllıqla düzülür; Cabbarlı və Vurğun hər ikisi dram janrında əsər yazıb. 3-cü mülahizə yanlışdır: «Oqtay Eloğlu» milli TEATRIN yaranması problemlərinə həsr olunub, neft sənayesinə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-cabbarli-vurgun#23'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- edeb11-cenub-dunya#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-cenub-dunya#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-cenub-dunya#comb1', 'edeb-11-cenub-dunya',
  'Cənub və dünya ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Məhəmmədhüseyn Şəhriyar Təbrizdə doğulmuşdur, «Heydərbabaya salam» poemasındakı Heydərbaba isə həmin şəhər yaxınlığındakı bir dağın adıdır.
2) 1-ci mülahizəyə əsasən, Şəhriyar öz doğma yerini xatırladan bu poemanı Azərbaycan dilində - ana dilində yazmışdır.
3) «Sazımın sözü» əsəri də Məhəmmədhüseyn Şəhriyarın qələmindən çıxmışdır və «Kitabi-Dədə Qorqud» motivlərinə əsaslanır.
4) Çingiz Aytmatov qırğız ədəbiyyatının görkəmli nümayəndəsidir.',
  '1, 2 və 4 doğrudur: Şəhriyar Təbrizdə doğulub, Heydərbaba da elə oradakı dağdır, poema ana dilində yazılıb; Aytmatov isə qırğız ədəbiyyatının nümayəndəsidir - ayrı fakt. 3-cü mülahizə yanlışdır: «Sazımın sözü» Şəhriyarın yox, Bulud Qaraçorlu SƏHƏNDİN əsəridir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-cenub-dunya#22'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- edeb11-istiqlal#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-istiqlal#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-istiqlal#comb1', 'edeb-11-istiqlal',
  'İstiqlal ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bəxtiyar Vahabzadənin «Gülüstan» poeması 1959-cu ildə, «Şəhidlər» əsəri isə 1990-cı ildə - 20 Yanvar faciəsindən dərhal sonra yazılmışdır.
2) 1-ci mülahizəyə əsasən, bu iki əsərin yazılması arasında 31 il keçmişdir.
3) «Rənglər» şeir silsiləsi Bəxtiyar Vahabzadəyə məxsusdur.
4) Xəlil Rza Ulutürk ədəbiyyat tarixinə istiqlal şairi kimi düşmüşdür.',
  '1, 2 və 4 doğrudur: Gülüstan 1959-cu, Şəhidlər 1990-cı ildə yazılıb, aralarında 31 il var; Xəlil Rza Ulutürk isə istiqlal şairi kimi tanınır. 3-cü mülahizə yanlışdır: «Rənglər» silsiləsi Bəxtiyar Vahabzadəyə yox, RƏSUL RZAYA məxsusdur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-istiqlal#22'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- edeb11-nezeriyye#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-nezeriyye#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-nezeriyye#comb1', 'edeb-11-nezeriyye',
  'Ədəbiyyat nəzəriyyəsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ədəbi cərəyanlar tarixi ardıcıllıqla klassisizm → romantizm → realizm ardıcıllığı ilə formalaşmışdır.
2) 1-ci mülahizəyə əsasən, romantizm cərəyanı ideal aləmə və güclü hisslərə üstünlük verir, ondan sonra formalaşan realizm isə həyatı olduğu kimi, gerçək təsvir edir - bu, ikisinin əsas fərqidir.
3) Epitet sözün oxşarlıq əsasında məcazi mənada işlədilməsidir, metafora isə bədii təyin yaradır.
4) Sonet on dörd misradan ibarətdir.',
  '1, 2 və 4 doğrudur: cərəyanlar klassisizm-romantizm-realizm ardıcıllığı ilə formalaşıb, romantizm ideala, realizm gerçəkliyə üstünlük verir; sonet 14 misradır. 3-cü mülahizə yanlışdır: EPİTET bədii təyin, METAFORA isə məcazi məna yaradır - tərslə yazılıb.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-nezeriyye#23'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- edeb11-ozunuderk#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-ozunuderk#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-ozunuderk#comb1', 'edeb-11-ozunuderk',
  'Özünüdərk mövzusunu işləyən yazıçılarla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Dəli Kür» romanının müəllifi İsmayıl Şıxlıdır, romanın baş qəhrəmanı isə Cahandar ağadır.
2) 1-ci mülahizəyə əsasən, Cahandar ağa dağılmaqda olan patriarxal dünyanın son nümayəndəsi kimi təsvir olunur, onun faciəsi dəyişən zamanla köhnə həyat qaydalarının toqquşmasından doğur.
3) «Söyüdlü arx» romanı da İsmayıl Şıxlının qələmindən çıxmışdır.
4) İlyas Əfəndiyev Azərbaycan teatrında lirik-psixoloji dram üslubunun banisi sayılır.',
  '1, 2 və 4 doğrudur: «Dəli Kür» İsmayıl Şıxlının romanıdır, Cahandar ağa onun mərkəzi obrazıdır, faciəsi köhnə qaydalarla zamanın toqquşmasından doğur; İlyas Əfəndiyev isə lirik-psixoloji dramın banisidir. 3-cü mülahizə yanlışdır: «Söyüdlü arx» İsmayıl Şıxlının yox, İLYAS ƏFƏNDİYEVİN romanıdır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-ozunuderk#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- edeb11-rza-mircelal#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-rza-mircelal#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-rza-mircelal#comb1', 'edeb-11-rza-mircelal',
  'Rəsul Rza və Mir Cəlalın yaradıcılığı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Mir Cəlal ilk növbədə nasir kimi tanınır, «Bir gəncin manifesti» romanının baş qəhrəmanı Mərdandır.
2) 1-ci mülahizəyə əsasən, bu roman XX əsrin əvvəllərindəki sosial ədalətsizliyi və yoxsul ailənin faciəsini əks etdirir - Mərdanın taleyi məhz bu ictimai problem fonunda göstərilir.
3) «Rənglər» şeir silsiləsi Mir Cəlalın qələmindən çıxmışdır.
4) Rəsul Rzanın həyat yoldaşı şairə Nigar Rəfibəyli olmuşdur.',
  '1, 2 və 4 doğrudur: Bir gəncin manifesti Mir Cəlalın romanıdır, Mərdan onun qəhrəmanı, əsər sosial ədalətsizliyi əks etdirir; Rəsul Rzanın həyat yoldaşı isə Nigar Rəfibəyli idi. 3-cü mülahizə yanlışdır: «Rənglər» Mir Cəlalın yox, RƏSUL RZANIN şeir silsiləsidir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-rza-mircelal#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- edeb11-tenqidi-realizm#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb11-tenqidi-realizm#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb11-tenqidi-realizm#comb1', 'edeb-11-tenqidi-realizm',
  'Tənqidi realizm dövrü ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Molla Nəsrəddin» jurnalını 1906-cı ildə Tiflisdə Cəlil Məmmədquluzadə nəşr etdirmişdir.
2) 1-ci mülahizəyə əsasən, Sabirin satirik şeirlərinin çoxu da elə həmin jurnalda - «Molla Nəsrəddin»də çap olunurdu.
3) Sabirin şeirlər toplusu «Anamın kitabı» adlanır.
4) «Molla Nəsrəddin» jurnalının satirik gücünü karikaturalar artırırdı.',
  '1, 2 və 4 doğrudur: jurnal 1906-cı ildə Tiflisdə Məmmədquluzadə tərəfindən nəşr olundu, Sabirin şeirləri də elə orada çap olunurdu, karikaturalar jurnalın gücünü artırırdı. 3-cü mülahizə yanlışdır: Sabirin toplusu «HOPHOPNAMƏ»dir, «Anamın kitabı» isə Məmmədquluzadənin dram əsəridir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb11-tenqidi-realizm#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
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

-- ------------------------------------------------------------- tarix9-cumhuriyyet#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix9-cumhuriyyet#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix9-cumhuriyyet#comb1', 'tarix-9-cumhuriyyet',
  'Azərbaycan Xalq Cümhuriyyəti ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bakı 1918-ci il sentyabrın 15-də azad olunduqdan sonra Cümhuriyyətin paytaxtı oldu.
2) 1-ci mülahizəyə əsasən, Cümhuriyyət parlamenti də elə bu paytaxtda - Bakıda - 1918-ci il dekabrın 7-də ilk iclasını keçirdi.
3) Cümhuriyyət Paris sülh konfransında tam DE-YURE tanınmışdı.
4) Şeyx Məhəmməd Xiyabani rəhbərliyi ilə Cənubi Azərbaycanda 1920-ci il hərəkatı baş verdi və ölkəyə Azadıstan adı verildi.',
  '1, 2 və 4 doğrudur: Bakı paytaxt oldu, parlament orada açıldı; Xiyabani hərəkatı Cənubda baş verdi, ölkəyə Azadıstan adı verildi. 3-cü mülahizə yanlışdır: Cümhuriyyət Paris konfransında yalnız DE-FAKTO tanınmışdı, de-yure yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix9-cumhuriyyet#16'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- tarix9-musteqillik#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix9-musteqillik#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix9-musteqillik#comb1', 'tarix-9-musteqillik',
  'Müstəqillik dövrü ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Azərbaycan 1992-ci ilin martında BMT-yə üzv qəbul edildi, elə həmin il milli valyuta - manat da dövriyyəyə buraxıldı.
2) 1-ci mülahizəyə əsasən, gənc dövlətin bu institusional addımlarından sonra, 1995-ci il Konstitusiyası ilə idarəetmə forması rəsmən prezidentli respublika kimi təsbit olundu.
3) Cəbhədə atəşkəs sazişi 1993-cü ilin iyununda imzalandı.
4) Bakı-Tbilisi-Ceyhan neft kəməri yeni neft strategiyasının nəticəsidir.',
  '1, 2 və 4 doğrudur: BMT üzvlüyü və manat 1992-ci ildə, 1995-ci il Konstitusiyası prezidentli respublikanı təsbit etdi; BTC yeni neft strategiyasının məhsuludur. 3-cü mülahizə yanlışdır: atəşkəs sazişi 1993-cü ildə yox, 1994-CÜ İLİN MAYINDA imzalandı.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix9-musteqillik#10'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- tarix9-sovet#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix9-sovet#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix9-sovet#comb1', 'tarix-9-sovet',
  'Sovet dövrü ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Azərbaycan SSR 1920-ci ilin aprel işğalından sonra yaradıldı, ilk hökumət başçısı Nəriman Nərimanov oldu.
2) 1-ci mülahizəyə əsasən, sovet rejiminin sonrakı onilliklərində - 1937-ci il repressiyalarının qurbanları arasında Hüseyn Cavid və Mikayıl Müşfiq kimi məşhur ziyalılar da oldu.
3) Qarabağ münaqişəsi 20 Yanvar faciəsindən SONRA, 1990-cı ildə başladı.
4) Heydər Əliyev 1969-cu ildə Azərbaycana rəhbər seçildi.',
  '1, 2 və 4 doğrudur: SSR 1920-ci ildə yaradıldı, Nərimanov başçı oldu, 1937-ci il repressiyasında Cavid/Müşfiq qurban oldu; Heydər Əliyev 1969-cu ildə rəhbər seçildi. 3-cü mülahizə yanlışdır: Qarabağ münaqişəsi 1990-cı ildən yox, 1988-Cİ İLDƏN başladı - 20 Yanvardan ƏVVƏL.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix9-sovet#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- tarix9-xix#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix9-xix#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix9-xix#comb1', 'tarix-9-xix',
  'XIX əsr Azərbaycan tarixi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) 1848-ci ildə Bibiheybətdə dünyada ilk sənaye üsullu neft quyusu qazıldı.
2) 1-ci mülahizəyə əsasən, bu neft sənayesinin sürətli inkişafı nəticəsində XIX əsrin sonunda Bakı dünya neft hasilatının təxminən yarısını verirdi.
3) 1870-ci il kəndli islahatı Azərbaycan kəndlilərinə tam azadlıq və torpağı pulsuz verdi.
4) Qori seminariyası Azərbaycanlı müəllim kadrları hazırlayırdı.',
  '1, 2 və 4 doğrudur: Bibiheybət ilk neft quyusudur, əsr sonunda Bakı dünya hasilatının yarısını verirdi; Qori seminariyası müəllim hazırlayırdı. 3-cü mülahizə yanlışdır: 1870-ci il islahatı kəndlilərə YALNIZ TORPAQ PAYI ALMAQ HÜQUQU verdi, pulsuz/tam azadlıq yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix9-xix#4'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- tarix9-xx-evvel#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix9-xx-evvel#8';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix9-xx-evvel#comb1', 'tarix-9-xx-evvel',
  'XX əsrin əvvəllərində milli hərəkat ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Difai» təşkilatı xalqı erməni hücumlarından qorumaq məqsədilə yaradılmışdı.
2) 1-ci mülahizəyə əsasən, bu milli özünümüdafiə hərəkatının ideoloji davamı kimi «Müsavat» partiyası 1911-ci ildə təsis olundu.
3) Səttarxana Salari-milli, Bağırxana isə Sərdari-milli adı verilmişdi.
4) Zaqafqaziya seyminin dağılması müstəqil milli dövlətlərin elan olunmasına yol açdı.',
  '1, 2 və 4 doğrudur: Difai özünümüdafiə üçün yarandı, Müsavat 1911-ci ildə quruldu; Seymin dağılması müstəqil dövlətlərin yolunu açdı. 3-cü mülahizə yanlışdır: adlar TƏRSİNƏ yazılıb - Səttarxan SƏRDARİ-MİLLİ, Bağırxan isə SALARİ-MİLLİ idi.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix9-xx-evvel#8'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- tarix9-yeni-dovr#comb1
update public.questions set difficulty = 2 where ext_key = 'tarix9-yeni-dovr#15';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('tarix9-yeni-dovr#comb1', 'tarix-9-yeni-dovr',
  'Müasir dövr Azərbaycan tarixi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bakı-Tbilisi-Ceyhan neft kəməri 2006-cı ildə, Bakı-Tbilisi-Qars dəmir yolu isə 2017-ci ildə tam istifadəyə verildi.
2) 1-ci mülahizəyə əsasən, bu nəqliyyat-enerji infrastrukturunun davamı kimi Zəngəzur dəhlizi də Naxçıvanla birbaşa nəqliyyat əlaqəsini nəzərdə tutur.
3) Ağdam, Kəlbəcər və Laçın rayonları uzun döyüşlərlə hərbi yolla azad edildi.
4) 2023-cü ilin sentyabrında Azərbaycanın suverenliyi lokal antiterror tədbirləri ilə tam bərpa edildi.',
  '1, 2 və 4 doğrudur: BTC 2006-cı, BTQ 2017-ci ildə açıldı, Zəngəzur dəhlizi Naxçıvanla əlaqəni nəzərdə tutur; 2023-cü il sentyabrında suverenlik antiterror tədbirləri ilə bərpa edildi. 3-cü mülahizə yanlışdır: Ağdam, Kəlbəcər və Laçın bəyanata əsasən DÖYÜŞSÜZ, sülh yolu ilə qaytarıldı.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'tarix9-yeni-dovr#15'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-bioehtiyat#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-bioehtiyat#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-bioehtiyat#comb1', 'cog-9-bioehtiyat',
  'Azərbaycanın təbii ehtiyatları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Hirkan milli parkı Lənkəran zonasındakı qədim meşələri qoruyur, buradakı dəmirağac üçüncü dövrdən qalmış relikt növdür.
2) 1-ci mülahizəyə əsasən, Hirkan MİLLİ PARK statusunda olduğu üçün, qoruqdan fərqli olaraq, mühafizə ilə yanaşı turizmə də icazə verilir.
3) Azərbaycanda meşələr ölkə ərazisinin təqribən 60 faizini əhatə edir.
4) Qırmızı kitaba nəsli kəsilməkdə olan bitki və heyvan növləri daxil edilir.',
  '1, 2 və 4 doğrudur: Hirkan milli parkı dəmirağacı qoruyur, milli park statusu turizmə icazə verir; Qırmızı kitaba nəsli kəsilməkdə olan növlər daxil edilir. 3-cü mülahizə yanlışdır: Azərbaycanda meşələr 60% yox, TƏQRİBƏN 11-12 FAİZ təşkil edir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-bioehtiyat#4'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-ehali#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-ehali#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-ehali#comb1', 'cog-9-ehali',
  'Əhali coğrafiyası ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Emiqrasiya əhalinin öz ölkəsindən başqa ölkəyə getməsi, immiqrasiya isə başqa ölkədən gəlib məskunlaşmasıdır.
2) 1-ci mülahizəyə əsasən, doğum azaldığı Avropa ölkələrində immiqrasiya əhali artımını dəstəkləyən mənbələrdən biri olsa da, bu ölkələrdə əhalinin qocalması hələ də ciddi problemdir.
3) Bir-birinə qovuşmuş şəhər aqlomerasiyalarının əmələ gətirdiyi nəhəng zolağa kənd deyilir.
4) Hazırda dünya əhalisinin yarıdan çoxu şəhərlərdə yaşayır.',
  '1, 2 və 4 doğrudur: emiqrasiya/immiqrasiya tərifləri doğrudur, Avropa ölkələrində əhali qocalır; dünya əhalisinin yarıdan çoxu şəhərlərdə yaşayır. 3-cü mülahizə yanlışdır: bu zolaq kənd yox, MEQAPOLİS adlanır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-ehali#17'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-iqlim#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-iqlim#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-iqlim#comb1', 'cog-9-iqlim',
  'İqlim qurşaqları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Aralıq dənizi iqlimində yay quru və isti, qış isə yumşaq və yağıntılı keçir.
2) 1-ci mülahizəyə əsasən, bu cür sahil iqliminin əksinə olaraq, kontinentin dərinliyindəki KONTİNENTAL iqlimdə yay-qış temperatur fərqi (amplitud) daha böyük olur.
3) Passat küləkləri qütblərdən qütblərə əsən daimi küləklərdir.
4) İsti Qolfstrim cərəyanı Qərbi Avropanın iqlimini xeyli yumşaldır.',
  '1, 2 və 4 doğrudur: Aralıq dənizi iqlimi yumşaq-yağışlı qışla seçilir, kontinental iqlimdə amplitud böyükdür; Qolfstrim Qərbi Avropanı yumşaldır. 3-cü mülahizə yanlışdır: passatlar qütblərdən yox, TROPİKLƏRDƏN EKVATORA doğru əsir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-iqlim#18'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-iqtisadiyyat#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-iqtisadiyyat#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-iqtisadiyyat#comb1', 'cog-9-iqtisadiyyat',
  'İqtisadi coğrafiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ölkənin öz tələbatı üçün xaricdən mal alıb gətirməsi idxal adlanır.
2) 1-ci mülahizəyə əsasən, bu mal mübadiləsinin sürətli və ucuz aparılmasında infrastruktur (yol, rabitə, enerji qurğuları) həlledici rol oynayır - kütləvi yüklərin uzaq məsafəyə daşınmasında ən ucuz nəqliyyat növü isə dəniz nəqliyyatıdır.
3) Gəncə-Qazax bölgəsi Azərbaycanda əsasən çayçılıq rayonlarındandır.
4) Sənaye müəssisəsi yerləşdirilərkən xammala, əmək ehtiyatlarına və istehlakçıya yaxınlıq nəzərə alınır.',
  '1, 2 və 4 doğrudur: idxal doğru tərif olunub, infrastruktur və dəniz nəqliyyatı mal mübadiləsində vacibdir; müəssisə yeri xammal/əmək/istehlakçıya görə seçilir. 3-cü mülahizə yanlışdır: Gəncə-Qazax çayçılıq yox, ÜZÜMÇÜLÜK bölgəsidir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-iqtisadiyyat#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-relyef#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-relyef#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-relyef#comb1', 'cog-9-relyef',
  'Azərbaycanın relyefi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Azərbaycan ərazisinin təqribən 60 faizi dağlıq sahələrdir, qalanı düzənlikdir.
2) 1-ci mülahizəyə əsasən, bu dağlıq ərazinin bir hissəsini təşkil edən Naxçıvan Muxtar Respublikasının ən uca zirvəsi Qapıcıqdır (3906 m).
3) Küləyin səhralarda yaratdığı aypara şəkilli qum təpələrinə platformalar deyilir.
4) Düzənliklər hündürlüyünə görə ovalıqlara, təpəliklərə və yaylalara bölünür.',
  '1, 2 və 4 doğrudur: Azərbaycan ərazisinin 60%-i dağlıqdır, Qapıcıq Naxçıvanın ən uca zirvəsidir (3906 m); düzənliklər ovalıq/təpəlik/yaylaya bölünür. 3-cü mülahizə yanlışdır: bu qum təpələri platforma yox, BARXAN adlanır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-relyef#22'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-sivilizasiya#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-sivilizasiya#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-sivilizasiya#comb1', 'cog-9-sivilizasiya',
  'Sivilizasiyalar coğrafiyası ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Qədim Misir sivilizasiyası Nil çayının vadisində, Mesopotamiya sivilizasiyası isə Dəclə və Fərat çayları arasında yaranmışdır.
2) 1-ci mülahizəyə əsasən, bu iki nümunə kimi, qədim sivilizasiyalar ümumilikdə əsasən böyük, münbit çay vadilərində formalaşmışdır.
3) Azərbaycanın UNESCO Dünya İrsi siyahısına daxil edilmiş qədim şəhər hissəsi Yeni Yasamaldır.
4) Türk Dövlətləri Təşkilatı türkdilli ölkələri birləşdirən siyasi-iqtisadi əməkdaşlıq qurumudur.',
  '1, 2 və 4 doğrudur: Misir Nil, Mesopotamiya Dəclə-Fərat vadisindədir, sivilizasiyalar çay vadilərində yaranıb; Türk Dövlətləri Təşkilatı türkdilli ölkələri birləşdirir. 3-cü mülahizə yanlışdır: UNESCO siyahısındakı qədim şəhər hissəsi Yeni Yasamal yox, İÇƏRİŞƏHƏRDİR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-sivilizasiya#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-sular#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-sular#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-sular#comb1', 'cog-9-sular',
  'Sular coğrafiyası ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Göygöl 1139-cu il zəlzələsində baş vermiş dağ uçqununun çayın qabağını kəsməsi nəticəsində yaranmışdır.
2) 1-ci mülahizəyə əsasən, bu kimi təbii fəlakət mənşəli göllər ümumilikdə tektonik, buzlaq və vulkanik mənşəli göllər sırasına aid edilir.
3) Okean sahillərində suyun gündə iki dəfə qalxıb-enməsinin (qabarma-çəkilmə) əsas səbəbi küləyin əsməsidir.
4) Yerin şirin su ehtiyatının ən böyük hissəsi buzlaqlarda saxlanılır.',
  '1, 2 və 4 doğrudur: Göygöl zəlzələ nəticəsində yaranıb, göllər mənşəyinə görə təsnif olunur; şirin suyun böyük hissəsi buzlaqlardadır. 3-cü mülahizə yanlışdır: qabarma-çəkilmənin səbəbi külək yox, AYIN CAZİBƏ QÜVVƏSİDİR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-sular#17'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog9-xerite#comb1
update public.questions set difficulty = 2 where ext_key = 'cog9-xerite#25';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog9-xerite#comb1', 'cog-9-xerite',
  'Xəritəçilik ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Horizontalın üzərindəki kiçik cizgi - berqştrix yamacın hansı tərəfə alçaldığını göstərir.
2) 1-ci mülahizəyə əsasən, relyefin xəritədə eyni qiymətli nöqtələri birləşdirən xətlərlə (izoxətlər üsulu ilə) təsvir edilməsində berqştrixlər yamacın istiqamətini dəqiqləşdirən əlavə işarədir.
3) 1:1 000 000 miqyası 1:25 000 miqyasından daha iridir.
4) Coğrafi informasiya sistemləri (CİS) məkan məlumatlarını kompüterdə toplayıb təhlil edən sistemdir.',
  '1, 2 və 4 doğrudur: berqştrix yamac istiqamətini göstərir, izoxətlər üsulu ilə əlaqəlidir; CİS məkan məlumatlarını emal edir. 3-cü mülahizə yanlışdır: 1:25 000 miqyası 1:1 000 000-dan DAHA İRİDİR - məxrəc kiçik olduqca miqyas iri olur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog9-xerite#25'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- fiz9-cereyan-muhit#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz9-cereyan-muhit#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz9-cereyan-muhit#comb1', 'fiz-9-cereyan-muhit',
  'Elektrik cərəyanı və müxtəlif mühitlərlə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Metal qızdırıldıqda müqaviməti artır, çünki ionların rəqsi güclənir və elektronlara mane olur.
2) 1-ci mülahizəyə əsasən, yarımkeçiricidə isə əksinə - temperatur artdıqca keçiricilik YAXŞILAŞIR, çünki bu, metaldan fərqli bir mexanizmdir.
3) p-n keçidi cərəyanı hər iki istiqamətdə bərabər keçirir, ona görə yarımkeçirici diod səsi ucaltmaq üçün istifadə olunur.
4) Fotorezistorun müqaviməti işıq düşdükdə azalır.',
  '1, 2 və 4 doğrudur: metalda qızma müqaviməti artırır, yarımkeçiricidə əksinə keçiricilik yaxşılaşır; fotorezistor işıqda müqavimətini azaldır. 3-cü mülahizə yanlışdır: p-n keçidi cərəyanı YALNIZ BİR İSTİQAMƏTDƏ keçirir, diod isə cərəyanı DÜZLƏNDİRMƏK üçün istifadə olunur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz9-cereyan-muhit#22'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- fiz9-guzgu-linza#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz9-guzgu-linza#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz9-guzgu-linza#comb1', 'fiz-9-guzgu-linza',
  'Güzgü və linzalarla bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Müstəvi güzgüdə xəyal mövhumi, düz və cisimlə eyni boydadır.
2) 1-ci mülahizəyə əsasən, qabarıq güzgüdə isə xəyal həmişə kiçilmiş, düz və mövhumi olur - müstəvi güzgüdən fərqli olaraq ölçü dəyişir.
3) Cisim toplayıcı linzanın fokusu ilə linza arasında olanda xəyal kiçilmiş, tərs və həqiqi olur.
4) Toplayıcı linzanın ortası kənarlarından qalındır.',
  '1, 2 və 4 doğrudur: müstəvi güzgüdə xəyal cisim boyda, qabarıqda kiçilmiş-mövhumidir; toplayıcı linzanın ortası qalındır. 3-cü mülahizə yanlışdır: cisim fokusla linza arasında olanda xəyal BÖYÜDÜLMÜŞ, DÜZ VƏ MÖVHUMİ olur, kiçilmiş/tərs/həqiqi yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz9-guzgu-linza#14'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- fiz9-isiq#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz9-isiq#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz9-isiq#comb1', 'fiz-9-isiq',
  'İşığın sınması və qayıtması ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İşıq optik sıx mühitə keçəndə sınma bucağı düşmə bucağından kiçik olur, çünki optik sıx mühitdə işığın sürəti azalır.
2) 1-ci mülahizəyə əsasən, tam daxili qayıtma da sıx mühitdən böyük bucaq altında düşəndə baş verir və bu, məhz almazın güclü parıltısının səbəbidir.
3) Tam daxili qayıtma hadisəsi lifli optikada (optik kabellərdə) tətbiq olunmur.
4) Optikada bucaqlar səthə qaldırılmış perpendikulyardan (normaldan) ölçülür.',
  '1, 2 və 4 doğrudur: sıx mühitə keçəndə sınma bucağı kiçilir, tam daxili qayıtma almazın parıltısının səbəbidir; bucaqlar normaldan ölçülür. 3-cü mülahizə yanlışdır: tam daxili qayıtma məhz LİFLİ OPTİKADA (optik kabellərdə) tətbiq olunur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz9-isiq#16'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- fiz9-maqnit-sahe#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz9-maqnit-sahe#26';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz9-maqnit-sahe#comb1', 'fiz-9-maqnit-sahe',
  'Maqnit sahəsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Sabit maqnitin sahəsini əslində atomdaxili elektronların hərəkəti - mikro cərəyanlar yaradır.
2) 1-ci mülahizəyə əsasən, bu mikroskopik cərəyanların təbiətinə bənzər olaraq, eyni istiqamətli cərəyanlı iki paralel naqil öz sahələri vasitəsilə bir-birini CƏZB edir.
3) Alüminium tozunun maqnitlə yığılmaması onun çox ağır olmasındandır.
4) İnduksiya cərəyanının istiqaməti Lens qaydası ilə müəyyən olunur.',
  '1, 2 və 4 doğrudur: sabit maqnitin sahəsi atomdaxili cərəyanlardan yaranır, paralel eyniistiqamətli naqillər cəzb olunur; induksiya cərəyanının istiqaməti Lens qaydası ilə tapılır. 3-cü mülahizə yanlışdır: alüminium tozu maqnitlə yığılmır, çünki FERROMAQNİT DEYİL, ağırlığa görə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz9-maqnit-sahe#26'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- fiz9-nuve#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz9-nuve#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz9-nuve#comb1', 'fiz-9-nuve',
  'Nüvə enerjisi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Zəncirvari reaksiyada Uran-235 nüvəsinin bölünməsində ayrılan neytronlar yeni nüvələri bölür, bu proses davam edir.
2) 1-ci mülahizəyə əsasən, bu reaksiyanın başlaya bilməsi üçün minimal - kritik kütlə tələb olunur.
3) İstilik nüvə (sintez) reaksiyası ağır nüvələrin bölünərək yüngül nüvə yaratmasıdır.
4) Bir uran nüvəsinin bölünməsində ayrılan enerji adi kimyəvi reaksiyadakından milyonlarla dəfə çoxdur.',
  '1, 2 və 4 doğrudur: zəncirvari reaksiya Uran-235-də neytronlarla davam edir, kritik kütlə tələb olunur; nüvə bölünməsində enerji kimyəvi reaksiyadan milyonlarla dəfə çoxdur. 3-cü mülahizə yanlışdır: sintez reaksiyası YÜNGÜL nüvələrin BİRLƏŞMƏSİDİR, ağır nüvələrin bölünməsi (fissiya) yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz9-nuve#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- fiz9-radioaktivlik#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz9-radioaktivlik#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz9-radioaktivlik#comb1', 'fiz-9-radioaktivlik',
  'Radioaktivlik ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Alfa şüaları helium nüvələrindən ibarətdir və adi kağız vərəqi belə onları saxlaya bilir.
2) 1-ci mülahizəyə əsasən, alfa çevrilməsində nüvənin yük ədədi 2 vahid azalır - çünki alfa hissəciyi (helium nüvəsi) 2 protonla birlikdə nüvədən ayrılır.
3) Beta çevrilməsində nüvənin yük ədədi 2 vahid azalır.
4) İzotoplar bir-birindən nüvədəki neytronların sayı ilə fərqlənir.',
  '1, 2 və 4 doğrudur: alfa şüaları helium nüvəsidir, kağızla saxlanır, alfa çevrilməsində yük 2 vahid azalır; izotoplar neytron sayı ilə fərqlənir. 3-cü mülahizə yanlışdır: beta çevrilməsində yük 2 vahid azalmır, 1 VAHİD ARTIR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz9-radioaktivlik#16'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- kim9-azot-fosfor#comb1
update public.questions set difficulty = 2 where ext_key = 'kim9-azot-fosfor#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim9-azot-fosfor#comb1', 'kim-9-azot-fosfor',
  'Azot və fosfor birləşmələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Havanın həcmcə təqribən 78 faizi azotdur, azot molekulu (N2) ikiatomludur.
2) 1-ci mülahizəyə əsasən, N2 molekulunda atomlar möhkəm üçqat rabitə ilə bağlı olduğu üçün azot adi şəraitdə az aktivdir - buna görə közərmə lampalarının içi telin oksidləşməsinin qarşısını almaq üçün azotla doldurulur.
3) Nitrat turşusunda (HNO3) azotun oksidləşmə dərəcəsi -3-dür.
4) Ağ fosfor havada öz-özünə alışdığı üçün su altında saxlanılır.',
  '1, 2 və 4 doğrudur: azot 78%, N2 üçqat rabitəli olduğundan az aktivdir və lampalarda işlədilir; ağ fosfor su altında saxlanılır. 3-cü mülahizə yanlışdır: HNO3-də azot -3 yox, +5 OKSİDLƏŞMƏ DƏRƏCƏSİNDƏDİR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim9-azot-fosfor#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- kim9-halogen-kukurd#comb1
update public.questions set difficulty = 2 where ext_key = 'kim9-halogen-kukurd#25';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim9-halogen-kukurd#comb1', 'kim-9-halogen-kukurd',
  'Halogenlər və kükürd birləşmələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Xlorid ionu məhlulda gümüş-nitratla ağ çöküntü (AgCl) əmələ gətirməklə təyin edilir.
2) 1-ci mülahizəyə əsasən, sulfat ionu isə fərqli bir reaktivlə - barium duzları ilə - suda həll olmayan ağ çöküntü (BaSO4) əmələ gətirməklə təyin olunur.
3) Mis qatı sulfat turşusu ilə qızdırıldıqda hidrogen qazı ayrılır.
4) Duru xlorid turşusu misllə reaksiyaya girib hidrogen çıxara bilmir, çünki mis gərginlik sırasında hidrogendən sağda durur.',
  '1, 2 və 4 doğrudur: xlorid və sulfat ionları müvafiq reaktivlərlə (AgCl/BaSO4) təyin edilir; mis duru turşu ilə hidrogen çıxarmır. 3-cü mülahizə yanlışdır: mis qatı H2SO4 ilə qızdırıldıqda hidrogen yox, KÜKÜRD QAZI (SO2) ayrılır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim9-halogen-kukurd#25'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- kim9-karbon-silisium#comb1
update public.questions set difficulty = 2 where ext_key = 'kim9-karbon-silisium#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim9-karbon-silisium#comb1', 'kim-9-karbon-silisium',
  'Karbon və silisium birləşmələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Karbon təbiətdə almaz və qrafit kimi iki allotropik şəkildə rast gəlinir; hər ikisi eyni karbondur, lakin atomların kristal qəfəsdə düzülüşü fərqlidir.
2) 1-ci mülahizəyə əsasən, bu struktur fərqi nəticəsində qrafit (almazdan fərqli olaraq) qeyri-metal olsa da, elektrik cərəyanını yaxşı keçirir - elektrodlar ondan hazırlanır.
3) Dəm qazı (CO) kəskin qoxusu olduğu üçün asanlıqla hiss edilir və buna görə təhlükəlidir.
4) Karbon qazı (CO2) özü yanmır və yanmanı saxlamır, ona görə odsöndürmədə işlədilir.',
  '1, 2 və 4 doğrudur: almaz/qrafit eyni karbonun fərqli struktur formalarıdır, qrafit bu struktura görə cərəyan keçirir; CO2 yanmanı saxlamadığı üçün odsöndürmədə işlədilir. 3-cü mülahizə yanlışdır: dəm qazı (CO) RƏNGSİZ VƏ QOXUSUZ olduğu üçün təhlükəlidir - kəskin qoxusu yoxdur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim9-karbon-silisium#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- kim9-metal-umumi#comb1
update public.questions set difficulty = 2 where ext_key = 'kim9-metal-umumi#30';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim9-metal-umumi#comb1', 'kim-9-metal-umumi',
  'Metalların ümumi xassələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Elektrokimyəvi gərginlik sırasında soldan sağa getdikcə metalların aktivliyi azalır.
2) 1-ci mülahizəyə əsasən, sink bu sırada misdən solda durduğu üçün mis duzunun məhlulundan misi sıxışdırıb çıxara bilir.
3) Yer qabığında metallar arasında ən geniş yayılmış metal xromdur.
4) Ən aktiv metallar dövri sistemin I qrupunun əsas yarımqrupunda - qələvi metallar sırasında yerləşir.',
  '1, 2 və 4 doğrudur: gərginlik sırasında aktivlik soldan sağa azalır, sink misi sıxışdırır; ən aktiv metallar qələvi metallardır (I qrup). 3-cü mülahizə yanlışdır: yer qabığında ən geniş yayılmış metal xrom yox, ALÜMİNİUMDUR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim9-metal-umumi#30'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- kim9-metallar#comb1
update public.questions set difficulty = 2 where ext_key = 'kim9-metallar#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim9-metallar#comb1', 'kim-9-metallar',
  'Metallar (Na, Ca, Al, Fe) ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Alüminium havada nazik, möhkəm oksid təbəqəsi ilə örtülür və bu təbəqə onu korroziyadan qoruyur.
2) 1-ci mülahizəyə əsasən, bu qoruyucu xassəyə baxmayaraq, alüminium kimyəvi cəhətdən aktivdir - həm turşularla, həm də qələvilərlə reaksiyaya girə bilir, bu xassə amfoterlik adlanır.
3) Çuqunda karbonun miqdarı poladdan azdır.
4) Alüminium sənayedə əsasən boksit filizindən alınır.',
  '1, 2 və 4 doğrudur: alüminiumun oksid təbəqəsi onu qoruyur, amfoter xassəsi var; boksit onun əsas filizidir. 3-cü mülahizə yanlışdır: çuqunda karbon poladdan az deyil, ÇOXDUR (2%-dən çox, poladda isə 2%-ə qədər).',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim9-metallar#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- kim9-uzvi#comb1
update public.questions set difficulty = 2 where ext_key = 'kim9-uzvi#15';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim9-uzvi#comb1', 'kim-9-uzvi',
  'Üzvi birləşmələr ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Etilen (C2H4) molekulunda karbon atomları arasında ikiqat rabitə, asetilendə (C2H2) isə üçqat rabitə var.
2) 1-ci mülahizəyə əsasən, bu çoxqat rabitəyə malik karbohidrogenlərdən fərqli olaraq, doymuş karbohidrogenlər (alkanlar) yalnız təkqat rabitəyə malikdir və ümumi CnH2n+2 formuluna tabedir.
3) Yağlar qlükoza ilə yağ turşularının mürəkkəb efirləridir.
4) Nişastanı yod məhlulu ilə təyin edirlər - yod nişastaya düşdükdə göy rəng alınır.',
  '1, 2 və 4 doğrudur: etilen ikiqat, asetilen üçqat rabitəlidir; alkanlar təkqat rabitəli, CnH2n+2 formuludur; nişasta yodla göy rəng verir. 3-cü mülahizə yanlışdır: yağlar qlükoza yox, QLİSERİNLƏ yağ turşularının mürəkkəb efirləridir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim9-uzvi#15'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-ali-esb#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-ali-esb#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-ali-esb#comb1', 'bio-9-ali-esb',
  'Ali sinir fəaliyyəti ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İkinci siqnal sistemi sözlə - nitqlə bağlıdır və yalnız insana xasdır.
2) 1-ci mülahizəyə əsasən, heyvanlarda isə yalnız birinci siqnal sistemi olur - hiss orqanlarının bilavasitə qıcıqlarına əsaslanır.
3) Coşqun, tez qızışan, fəal temperament tipi fleqmatikdir.
4) Temperamentin dörd tipə bölünməsi qədim həkim Hippokratın adı ilə bağlıdır.',
  '1, 2 və 4 doğrudur: ikinci siqnal sistemi insana xasdır (nitq), heyvanlarda yalnız birinci var; temperament təlimi Hippokratdan gəlir. 3-cü mülahizə yanlışdır: coşqun, tez qızışan tip fleqmatik yox, XOLERİKDİR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-ali-esb#17'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-bolunme#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-bolunme#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-bolunme#comb1', 'bio-9-bolunme',
  'Hüceyrə bölünməsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Meyozda iki ardıcıl bölünmə gedir, DNT isə yalnız bir dəfə ikiləşir - nəticədə haploid (tək dəstli) cinsiyyət hüceyrələri əmələ gəlir.
2) 1-ci mülahizəyə əsasən, mayalanma zamanı iki haploid hüceyrə birləşərək diploid ziqot yaradır - beləliklə növün xromosom sayı bərpa olunur.
3) Mitozda xromosomların hüceyrənin ekvator müstəvisində düzülməsi anafazada baş verir.
4) Homoloji xromosomlar forma və ölçücə bir-birinə uyğun gələn cüt xromosomlardır.',
  '1, 2 və 4 doğrudur: meyoz iki bölünmədir, mayalanma diploidliyi bərpa edir; homoloji xromosomlar oxşar cüt xromosomlardır. 3-cü mülahizə yanlışdır: xromosomların ekvatorda düzülməsi METAFAZADA baş verir, anafazada yox (anafazada qütblərə çəkilirlər).',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-bolunme#14'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-coxalma-inkisaf#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-coxalma-inkisaf#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-coxalma-inkisaf#comb1', 'bio-9-coxalma-inkisaf',
  'Çoxalma və inkişaf ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Qeyri-cinsi çoxalmada bir valideyn iştirak edir və nəsil ona bənzəyir; cinsi çoxalmada isə iki valideynin əlamətləri birləşərək nəsildə irsi müxtəliflik yaranır.
2) 1-ci mülahizəyə əsasən, kəpənək kimi tam çevrilmə ilə inkişaf edən həşəratlarda sürfə (tırtıl) ilə yetkin fərd arasında əlavə bir mərhələ - pup mərhələsi olur.
3) Çəyirtkə də kəpənək kimi tam çevrilmə ilə inkişaf edir, sürfə pup mərhələsindən keçir.
4) Cinsiyyət hüceyrələri meyoz nəticəsində əmələ gəlir.',
  '1, 2 və 4 doğrudur: qeyri-cinsi/cinsi çoxalmanın fərqi doğrudur, kəpənəkdə pup mərhələsi var; cinsiyyət hüceyrələri meyozla yaranır. 3-cü mülahizə yanlışdır: çəyirtkə NATAMAM çevrilmə ilə inkişaf edir, pup mərhələsi YOXDUR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-coxalma-inkisaf#17'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-huceyre#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-huceyre#22';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-huceyre#comb1', 'bio-9-huceyre',
  'Hüceyrənin quruluşu ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Endoplazmatik şəbəkə kanalları ilə maddələr hüceyrə daxilində daşınır.
2) 1-ci mülahizəyə əsasən, bu şəbəkə ilə daşınan maddələr sonra Qolci aparatına çatır - burada toplanır, qablaşdırılır və hüceyrədən xaric edilir.
3) Suyun hüceyrə membranından çox qatılıqlı mühitdən az qatılıqlı mühitə keçməsi osmos adlanır.
4) Heyvan hüceyrəsinin bölünməsində iştirak edən, nüvə yaxınlığında yerləşən orqanoid hüceyrə mərkəzidir.',
  '1, 2 və 4 doğrudur: EPŞ maddə daşıyır, Qolci aparatı toplayıb ifraz edir; hüceyrə mərkəzi bölünmə iyini yaradır. 3-cü mülahizə yanlışdır: osmos AZ qatılıqlı mühitdən ÇOX qatılıqlı mühitə doğru gedir, əksinə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-huceyre#22'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-irsiyyet-muhit#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-irsiyyet-muhit#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-irsiyyet-muhit#comb1', 'bio-9-irsiyyet-muhit',
  'İrsiyyət və dəyişkənlik ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Genotip orqanizmin bütün genlərinin məcmusudur, fenotip isə orqanizmin bütün xarici və daxili əlamətlərinin məcmusudur.
2) 1-ci mülahizəyə əsasən, fenotip təkcə genotipdən deyil, həm də mühitin təsirindən formalaşır - bu iki amilin qarşılıqlı təsiridir.
3) Mühitin yaratdığı modifikasiya dəyişkənliyi genotipə təsir edir və nəsildən-nəslə irsən ötürülür.
4) Resessiv əlamət yalnız hər iki valideyndən keçdikdə üzə çıxır.',
  '1, 2 və 4 doğrudur: genotip/fenotip tərifləri doğrudur, fenotip genotip və mühitdən formalaşır; resessiv əlamət hər iki valideyndən keçəndə görünür. 3-cü mülahizə yanlışdır: modifikasiya dəyişkənliyi genotipə TOXUNMUR və İRSƏN ÖTÜRÜLMÜR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-irsiyyet-muhit#10'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-kimyevi-terkib#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-kimyevi-terkib#30';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-kimyevi-terkib#comb1', 'bio-9-kimyevi-terkib',
  'Hüceyrənin kimyəvi tərkibi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) DNT-nin tərkibində timin azotlu əsası var, RNT-də isə timinin yerini urasil tutur.
2) 1-ci mülahizəyə əsasən, bu iki nuklein turşusunun zənciri aminturşulardan yox, nukleotidlərdən qurulur.
3) Zülal zəncirində aminturşular bir-biri ilə hidrogen qazı ilə birləşir.
4) DNT molekulunun fəza quruluşu ikiqat spiraldır.',
  '1, 2 və 4 doğrudur: DNT-də timin, RNT-də urasil var; DNT ikiqat spiraldır, hər ikisi nukleotidlərdən qurulur. 3-cü mülahizə yanlışdır: aminturşular PEPTİD RABİTƏSİ ilə birləşir, hidrogen qazı ilə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-kimyevi-terkib#30'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-mubadile#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-mubadile#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-mubadile#comb1', 'bio-9-mubadile',
  'Maddələr mübadiləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Transkripsiya prosesində DNT üzərində məlumat RNT-si sintez olunur, translyasiya prosesində isə bu məlumat əsasında ribosomlarda zülal yığılır.
2) 1-ci mülahizəyə əsasən, bu prosesdə hər aminturşuya DNT-də üç nukleotiddən ibarət triplet uyğun gəlir - genetik kod məhz bu üçlüklərlə oxunur.
3) Qlükozanın oksigensiz şəraitdə parçalanması fotosintez adlanır.
4) Gərgin işləyən əzələdə oksigen çatışmadıqda süd turşusu toplanır.',
  '1, 2 və 4 doğrudur: transkripsiya/translyasiya prosesləri və triplet kodu doğru təsvir olunub; oksigen çatışmazlığında əzələdə süd turşusu toplanır. 3-cü mülahizə yanlışdır: qlükozanın oksigensiz parçalanması QLİKOLİZ adlanır, fotosintez yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-mubadile#10'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- bio9-nov-tekamul#comb1
update public.questions set difficulty = 2 where ext_key = 'bio9-nov-tekamul#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio9-nov-tekamul#comb1', 'bio-9-nov-tekamul',
  'Növ və təkamül ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Çarlz Darvinə görə təkamülün əsas hərəkətverici qüvvəsi təbii seçmədir - mühitə uyğunlaşan fərdlər sağ qalıb daha çox nəsil verir.
2) 1-ci mülahizəyə əsasən, insanın lazımlı əlamətli fərdləri özü seçib artırması isə fərqli bir proses - süni seçmədir; bu yolla it, göyərçin və toyuğun çoxsaylı cinsləri yaradılıb.
3) Appendiks kimi orqanlar mimikriyaya misaldır - müdafiəsiz canlının qorunan canlıya bənzəməsidir.
4) Populyasiyada tamamilə yeni əlamətlərin ilkin mənbəyi mutasiyalardır.',
  '1, 2 və 4 doğrudur: təbii seçmə/süni seçmə fərqi doğrudur; yeni əlamətlərin mənbəyi mutasiyadır. 3-cü mülahizə yanlışdır: appendiks RUDİMENT orqana misaldır (təkamüldə əhəmiyyətini itirmiş orqan), mimikriya yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio9-nov-tekamul#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- inf9-cedvel#comb1
update public.questions set difficulty = 2 where ext_key = 'inf9-cedvel#4';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf9-cedvel#comb1', 'inf-9-cedvel',
  'Elektron cədvəl funksiyaları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) IF funksiyası şərtə görə müxtəlif qiymət qaytarmaq üçün istifadə olunur.
2) 1-ci mülahizəyə əsasən, filtr də bənzər məntiqlə - müəyyən şərtə uyğun sətirləri seçib göstərmək üçün istifadə olunur.
3) Mütləq istinad ($A$1) düstur köçürüləndə yeni mövqeyə uyğunlaşaraq dəyişir.
4) AVERAGE funksiyası diapazondakı ədədlərin ortasını hesablayır.',
  '1, 2 və 4 doğrudur: IF şərtə görə qiymət qaytarır, filtr şərtə uyğun sətirləri göstərir; AVERAGE ortanı hesablayır. 3-cü mülahizə yanlışdır: mütləq istinad ($A$1) köçürüləndə DƏYİŞMİR, sabit qalır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf9-cedvel#4'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- inf9-kodlasdirma#comb1
update public.questions set difficulty = 2 where ext_key = 'inf9-kodlasdirma#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf9-kodlasdirma#comb1', 'inf-9-kodlasdirma',
  'Verilənlərin kodlaşdırılması ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Şəklin rəng dərinliyi bir pikselin kodlanmasına düşən bitlərin sayını göstərir; 8 bit rəng dərinliyi 2⁸ = 256 rəng verir.
2) 1-ci mülahizəyə əsasən, rastr şəklin fayl həcmi piksel sayından və rəng dərinliyindən asılıdır - bit sayı artdıqca fayl da böyüyür.
3) Vektor qrafikası fotoşəkillərdə rastr qrafikadan üstündür.
4) Səsin diskretləşdirilməsi səs dalğasının hissələrə bölünüb ölçülməsidir.',
  '1, 2 və 4 doğrudur: rəng dərinliyi bit sayıdır, 8 bit 256 rəng verir, fayl həcmi piksel və dərinlikdən asılıdır; diskretləşdirmə səsin ölçülməsidir. 3-cü mülahizə yanlışdır: vektor qrafikası LOQO VƏ ÇERTYOJLARDA üstündür, fotoşəkillərdə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf9-kodlasdirma#18'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- inf9-komputer#comb1
update public.questions set difficulty = 2 where ext_key = 'inf9-komputer#16';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf9-komputer#comb1', 'inf-9-komputer',
  'Kompüterin quruluşu ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Prosessorun nüvələrinin çoxluğu əməliyyatların paralel yerinə yetirilməsinə imkan verir.
2) 1-ci mülahizəyə əsasən, bu paralel işləmənin sürətini daha da artırmaq üçün keş yaddaş tez-tez işlənən verilənləri prosessora yaxın saxlayır.
3) Fayl sistemində fraqmentasiya kompüter söndürüləndə yaranır.
4) Müvəqqəti fayllar sistemin xüsusi qovluqlarında yığılır.',
  '1, 2 və 4 doğrudur: çoxnüvəlilik paralel əməliyyata imkan verir, keş yaddaş sürəti artırır; müvəqqəti fayllar sistem qovluqlarında yığılır. 3-cü mülahizə yanlışdır: fraqmentasiya kompüter söndürüləndə yox, FAYLLAR DƏFƏLƏRLƏ SİLİNİB YENİDƏN YAZILDIQCA yaranır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf9-komputer#16'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- inf9-proqramlasdirma#comb1
update public.questions set difficulty = 2 where ext_key = 'inf9-proqramlasdirma#13';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf9-proqramlasdirma#comb1', 'inf-9-proqramlasdirma',
  'Python proqramlaşdırma ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Python-da tam ədədlər int, kəsr ədədlər isə float tipində saxlanılır.
2) 1-ci mülahizəyə əsasən, funksiya def açar sözü ilə yaradılır və nəticəni return əmri ilə qaytarır.
3) 7 // 2 əməliyyatının nəticəsi 3,5-dir.
4) Sətri böyük hərflərə çevirən metod upper()-dır.',
  '1, 2 və 4 doğrudur: int/float tipləri doğrudur, def/return funksiya yaradır; upper() böyük hərfə çevirir. 3-cü mülahizə yanlışdır: 7 // 2 TAM BÖLMƏDİR, nəticə 3-dür - 3,5 adi bölmənin (/) nəticəsi olardı.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf9-proqramlasdirma#13'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- inf9-texnologiya#comb1
update public.questions set difficulty = 2 where ext_key = 'inf9-texnologiya#14';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('inf9-texnologiya#comb1', 'inf-9-texnologiya',
  'Veb texnologiyaları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Veb-səhifələrin əsas quruluşu HTML dilində qurulur, CSS isə səhifənin görünüşünü və tərtibatını təmin edir.
2) 1-ci mülahizəyə əsasən, bu struktur və tərtibata əlavə olaraq, JavaScript veb-səhifəyə interaktivlik və dinamiklik qatır.
3) bil10.az kimi domen adı hostinq xidmətini əvəz edir.
4) Şəbəkədəki hər qurğuya verilən rəqəmsal ünvan IP ünvan adlanır.',
  '1, 2 və 4 doğrudur: HTML/CSS/JavaScript birlikdə saytı qurur; IP ünvan qurğunu identifikasiya edir. 3-cü mülahizə yanlışdır: domen adı HOSTİNQİ yox, RƏQƏMSAL IP ÜNVANI əvəz edir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'inf9-texnologiya#14'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-cenub#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-cenub#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-cenub#comb1', 'edeb-9-cenub',
  'Cənub ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Səhəndiyyə» Məhəmmədhüseyn Şəhriyarın, «Səhənd dağı» isə Həbib Sahirin şeiridir.
2) 1-ci mülahizəyə əsasən, Şəhriyar 1906-cı ildə doğulub, 1988-ci ildə vəfat edib - beləliklə onun ömrü 82 il olub.
3) «Heydərbabaya salam» poeması əruz vəznindədir, klassik divan şeiri kimi.
4) «Heydərbabaya salam»ın hər iki tayda geniş yayılmasının səbəbi onun ana dilində, hamıya doğma dildə yazılmasıdır.',
  '1, 2 və 4 doğrudur: Səhəndiyyə-Şəhriyar, Səhənd dağı-Sahir; Şəhriyar 82 il yaşayıb; poema ana dilində yazıldığı üçün geniş yayılıb. 3-cü mülahizə yanlışdır: «Heydərbabaya salam» HECA vəznindədir, əruz divan şeiri yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '3, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-cenub#27'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-dunya#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-dunya#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-dunya#comb1', 'edeb-9-dunya',
  'Dünya ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Qoca və dəniz» əsərinin müəllifi Ernest Heminqueydir, əsərdə Manolin qocanın şagirdi kimi təsvir olunur.
2) 1-ci mülahizəyə əsasən, əsərdəki dəniz obrazı da simvolik məna daşıyır - həyatı və mübarizə meydanını simvolizə edir.
3) Qoca sahilə böyük balığı bütöv halda çatdırır.
4) Heminqueyin qısa cümlələrdən istifadə etməsi mətnə gərginlik və təmkinli ifadə gücü verir.',
  '1, 2 və 4 doğrudur: Heminquey/Manolin, dəniz simvolu doğrudur; qısa cümlələr gərginlik yaradır. 3-cü mülahizə yanlışdır: qoca balığı bütöv yox, YALNIZ SKELETİ ilə qaytarır - köpək balıqları yolda onu yeyir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-dunya#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-milli-demokratik#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-milli-demokratik#31';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-milli-demokratik#comb1', 'edeb-9-milli-demokratik',
  'Milli-demokratik dövr ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Azərbaycan bayrağına» şeirinin müəllifi Əhməd Cavaddır, dövlət himninin sözlərini də o yazmışdır, musiqisini isə Üzeyir Hacıbəyli bəstələmişdir.
2) 1-ci mülahizəyə əsasən, bayraq mövzusunun ədəbiyyata gəlməsi məhz müstəqil Xalq Cümhuriyyətinin qurulması ilə bağlıdır.
3) Bayraq rənglərindən yaşıl türkçülüyü, mavi isə islam mədəniyyətini bildirir.
4) Əhməd Cavad Şəmkirdə, Cəfər Cabbarlı isə Xızıda doğulmuşdur.',
  '1, 2 və 4 doğrudur: Azərbaycan bayrağına-Əhməd Cavad, himn sözləri onundur, bayraq mövzusu Cümhuriyyətlə bağlıdır; doğum yerləri doğrudur. 3-cü mülahizə yanlışdır: MAVİ türkçülüyü, YAŞIL islam mədəniyyətini bildirir - tərsinə yazılıb.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-milli-demokratik#31'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-muharibe#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-muharibe#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-muharibe#comb1', 'edeb-9-muharibe',
  'Müharibə dövrü ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Gələcək gün» roman, «Vətən yaraları» isə hekayə janrındadır.
2) 1-ci mülahizəyə əsasən, bu dövr nəsri ilə yanaşı, Süleyman Rüstəmin «Təbrizim» kimi şeirləri də Cənub həsrətini publisistik pafosla, mübarizəyə çağırış ruhu ilə əks etdirirdi.
3) «Gələcək gün» hekayədir, roman deyil.
4) Mirzə İbrahimov roman, Mir Cəlal isə hekayə yazmışdır.',
  '1, 2 və 4 doğrudur: Gələcək gün-roman, Vətən yaraları-hekayə; Təbrizim publisistik pafosla Cənub həsrətini əks etdirir; Mirzə İbrahimov/Mir Cəlal janrları doğrudur. 3-cü mülahizə yanlışdır: «Gələcək gün» ROMANDIR, hekayə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-muharibe#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-mustaqillik#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-mustaqillik#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-mustaqillik#comb1', 'edeb-9-mustaqillik',
  'Müstəqillik dövrü ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Azərbaycan dövlət müstəqilliyini 1991-ci ildə bərpa etmişdir, «İstiqlal» şeirinin müəllifi Bəxtiyar Vahabzadədir.
2) 1-ci mülahizəyə əsasən, bu tarixi hadisələr zaman ardıcıllığı ilə düzülür: əvvəlcə 20 Yanvar faciəsi (1990), sonra müstəqilliyin bərpası (1991), sonra Xocalı faciəsi (1992).
3) 20 Yanvar faciəsi 1992-ci ildə baş vermişdir.
4) Senzuranın aradan qalxması uzun illər qadağan olunmuş mövzuların açılmasına imkan verdi.',
  '1, 2 və 4 doğrudur: İstiqlal-Vahabzadə, müstəqillik 1991; hadisələr 20 Yanvar (1990) → müstəqillik (1991) → Xocalı (1992) sırası ilə düzülür; senzuranın qalxması yeni mövzulara imkan verdi. 3-cü mülahizə yanlışdır: 20 Yanvar faciəsi 1992 yox, 1990-CI İLDƏ baş verdi.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-mustaqillik#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-ozunuderk-nesr#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-ozunuderk-nesr#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-ozunuderk-nesr#comb1', 'edeb-9-ozunuderk-nesr',
  'Özünüdərk dövrü nəsri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Anar Rəsul Rza ilə Nigar Rəfibəylinin oğlu, Elçin isə İlyas Əfəndiyevin oğludur - hər ikisi tanınmış ədəbi ailədən çıxmışdır.
2) 1-ci mülahizəyə əsasən, bu ədəbi mühitdə böyüyən Anar özü də ədəbiyyatdan başqa kino sahəsində - ssenari və rejissorluqla məşğul olmuşdur.
3) «Məhşər» romanı Anarın əsəridir.
4) «Talvar» Elçinin, «Zəhər» isə İsa Hüseynovun əsəridir.',
  '1, 2 və 4 doğrudur: Anar/Elçin ədəbi ailə mənsublarıdır, Anar kino ilə də məşğul olub; Talvar-Elçin, Zəhər-İsa Hüseynov. 3-cü mülahizə yanlışdır: «Məhşər» Anarın yox, İSA HÜSEYNOVUN romanıdır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-ozunuderk-nesr#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-ozunuderk-seir#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-ozunuderk-seir#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-ozunuderk-seir#comb1', 'edeb-9-ozunuderk-seir',
  'Özünüdərk dövrü poeziyası ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Sağ ol, ana dilim!» və «Çinar ömrü» Rəsul Rzanın, «Əsgər məktubu» isə Məmməd Arazın əsərləridir.
2) 1-ci mülahizəyə əsasən, bu dövrdə ana dili mövzusunun poeziyada güclü olmasının səbəbi dilin milli kimliyin əsası sayılmasıdır.
3) «Sağ ol, ana dilim!» Sabir Rüstəmxanlının əsəridir.
4) Məmməd Araz Naxçıvanda doğulmuşdur.',
  '1, 2 və 4 doğrudur: Sağ ol ana dilim/Çinar ömrü-Rəsul Rza, ana dili mövzusu milli kimliklə bağlıdır; Məmməd Araz Naxçıvanda doğulub. 3-cü mülahizə yanlışdır: «Sağ ol, ana dilim!» Sabir Rüstəmxanlının yox, RƏSUL RZANIN əsəridir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-ozunuderk-seir#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- edeb9-repressiya#comb1
update public.questions set difficulty = 2 where ext_key = 'edeb9-repressiya#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('edeb9-repressiya#comb1', 'edeb-9-repressiya',
  'Repressiya dövrü ədəbiyyatı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Həyat sevgisi» Mikayıl Müşfiqin, «Anabacı» isə Abdulla Şaiqin əsəridir və poema janrındadır.
2) 1-ci mülahizəyə əsasən, bu dövrün digər tanınmış simalarından Çəmənzəminli Cümhuriyyətin Türkiyədəki səfiri olmuşdur.
3) Almas İldırım xaricdə təhsil almaq istəyi ilə vətəni tərk etmişdir.
4) Abdulla Şaiq uşaq ədəbiyyatı, Mikayıl Müşfiq isə lirik poeziya ilə tanınır.',
  '1, 2 və 4 doğrudur: Həyat sevgisi-Müşfiq, Anabacı-Şaiq (poema); Çəmənzəminli səfir olub; Şaiq/Müşfiq janr fərqi doğrudur. 3-cü mülahizə yanlışdır: Almas İldırım SOVET REJİMİNİN TƏZYİQİ ilə mühacirətə getmişdir, təhsil istəyi ilə yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'edeb9-repressiya#23'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'edebiyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '9'
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

-- ------------------------------------------------------------- cog10-ehali-siyasi#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-ehali-siyasi#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-ehali-siyasi#comb1', 'cog-10-ehali-siyasi',
  'Əhali və siyasi coğrafiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) «Demoqrafik partlayış» inkişaf etməkdə olan Afrika-Asiya ölkələrinə xasdır.
2) 1-ci mülahizəyə əsasən, bu ölkələrdə əhali sürətlə artdıqca urbanizasiyanın sürəti də inkişaf etməkdə olan ölkələrdə daha yüksək olur.
3) Anklav dövlət ada dövlətidir.
4) Bakı aqlomerasiyasına Bakı, Sumqayıt və Abşeron qəsəbələri daxildir.',
  '1, 2 və 4 doğrudur: demoqrafik partlayış/urbanizasiya sürəti inkişaf etməkdə olan ölkələrlə bağlıdır; Bakı aqlomerasiyası doğru təsvir olunub. 3-cü mülahizə yanlışdır: anklav dövlət ada yox, HƏR TƏRƏFDƏN BİR DÖVLƏTLƏ ƏHATƏ OLUNMUŞ dövlətdir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-ehali-siyasi#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-eti#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-eti#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-eti#comb1', 'cog-10-eti',
  'Elmi-texniki inqilab (ETİ) ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Elmi-texniki inqilab (ETİ) elmin bilavasitə istehsal qüvvəsinə çevrilməsi sıçrayışıdır.
2) 1-ci mülahizəyə əsasən, bu sıçrayış nəticəsində əmək ehtiyatlarının strukturunda zehni əməyin payı artır, yüksək texnologiyalar sənayesi isə elmi mərkəzlərə və ixtisaslı kadrlara xüsusilə bağlı olur.
3) «Ozon dəlikləri» suyun təsiri ilə əlaqələndirilir.
4) Beynəlxalq əmək bölgüsü ölkələrin müəyyən məhsul istehsalında ixtisaslaşmasıdır.',
  '1, 2 və 4 doğrudur: ETİ elmi istehsala çevirir, zehni əmək payı artır, yüksək texnologiyalar elm/kadra bağlıdır; beynəlxalq əmək bölgüsü ixtisaslaşmadır. 3-cü mülahizə yanlışdır: ozon dəlikləri suyun yox, FREON TİPLİ BİRLƏŞMƏLƏRİN təsiri ilə bağlıdır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-eti#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-geologiya#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-geologiya#11';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-geologiya#comb1', 'cog-10-geologiya',
  'Azərbaycanın geoloji quruluşu ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Azərbaycan ərazisi Alp-Himalay qırışıqlıq qurşağına daxildir, bu qurşağın dağları (Alp, Qafqaz, Himalay) alp qırışıqlıq mərhələsində yaranmışdır.
2) 1-ci mülahizəyə əsasən, bu cavan qırışıqlıq zonasında olduğu üçün Azərbaycanda zəlzələlər tez-tez baş verir.
3) Yarğanlar daxili (endogen) qüvvələrlə yaranan relyef formasına misaldır.
4) Azərbaycanın filiz yataqlarından Daşkəsən dəmir filizi məşhurdur.',
  '1, 2 və 4 doğrudur: Azərbaycan Alp-Himalay qurşağındadır, cavan qırışıqlıq zonası olduğu üçün zəlzələ baş verir; Daşkəsən dəmir filizi məşhurdur. 3-cü mülahizə yanlışdır: yarğanlar EKZOGEN (xarici, axar suların işi ilə yaranan) relyef formasıdır, endogen yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-geologiya#11'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-iqlim-ehtiyat#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-iqlim-ehtiyat#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-iqlim-ehtiyat#comb1', 'cog-10-iqlim-ehtiyat',
  'Azərbaycanın iqlim ehtiyatları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Rütubətlilik əmsalı yağıntının mümkün buxarlanmaya nisbətidir; bu əmsal vahiddən kiçik olan ərazilər quraq sayılır.
2) 1-ci mülahizəyə əsasən, Kür-Araz və Abşeron zonasında rütubətlilik əmsalı aşağı olduğu üçün orada yarımsəhra iqlimi hakimdir.
3) Azərbaycanda dünyanın 11 iqlim tipindən yalnız 2-si müşahidə olunur.
4) Aqroiqlim ehtiyatları iqlimin kənd təsərrüfatı üçün imkanlarını bildirir.',
  '1, 2 və 4 doğrudur: rütubətlilik əmsalı doğru tərif olunub, Kür-Araz/Abşeronda buna görə yarımsəhra iqlimi var; aqroiqlim ehtiyatları kənd təsərrüfatı imkanlarını bildirir. 3-cü mülahizə yanlışdır: Azərbaycanda dünyanın 11 iqlim tipindən 2 yox, 9-U müşahidə olunur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-iqlim-ehtiyat#10'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-kartoqrafiya#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-kartoqrafiya#26';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-kartoqrafiya#comb1', 'cog-10-kartoqrafiya',
  'Xəritəçilik ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Silindrik proyeksiya ekvator ətrafını daha dəqiq göstərir, azimutal proyeksiya isə qütb ərazilərini təsvir etmək üçün daha əlverişlidir.
2) 1-ci mülahizəyə əsasən, silindrik proyeksiyada yüksək enliklərdə sahə təhrif olunur - buna görə dünya xəritəsində Qrenlandiya həddindən artıq böyük görünür.
3) Miqyası 1:1000000 olan xəritədə 1 sm 100 km-ə uyğundur.
4) Coğrafi İnformasiya Sistemləri məkan məlumatlarını toplayır, təhlil edir və təqdim edir.',
  '1, 2 və 4 doğrudur: silindrik/azimutal proyeksiyaların üstünlükləri doğrudur, silindrikdə yüksək enlik təhrifi Qrenlandiyanı böyüdür; CİS məlumatı toplayıb təhlil edir. 3-cü mülahizə yanlışdır: 1:1000000 miqyasında 1 sm 100 km yox, 10 KM-Ə uyğundur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-kartoqrafiya#26'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-quru-sulari#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-quru-sulari#25';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-quru-sulari#comb1', 'cog-10-quru-sulari',
  'Azərbaycanın su ehtiyatları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Xəzər dənizinin səviyyəsi dünya okeanı səviyyəsindən aşağıdır.
2) 1-ci mülahizəyə əsasən, yeraltı sular da səthdən dərinliyinə görə fərqlənir: qrunt suları ilk su keçirməyən qat üzərindəki təzyiqsiz sulardır, artezian suları isə iki su keçirməyən qat arasında yerləşən təzyiqli sulardır.
3) Azərbaycanda ən böyük su anbarı Şollar su kəməri ilə bağlıdır.
4) Yuxarı Qarabağ kanalı Kür çayından su götürür.',
  '1, 2 və 4 doğrudur: Xəzər okean səviyyəsindən aşağıdır, qrunt/artezian suların fərqi doğrudur; Yuxarı Qarabağ kanalı Kürdən qidalanır. 3-cü mülahizə yanlışdır: ən böyük su anbarı Şollar yox, MİNGƏÇEVİR SES-İ ilə bağlıdır (Şollar isə Bakını su ilə təmin edən kəmərdir, anbar deyil).',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-quru-sulari#25'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-tebeqe#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-tebeqe#8';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-tebeqe#comb1', 'cog-10-tebeqe',
  'Coğrafi təbəqə ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Coğrafi təbəqə litosfer, atmosfer, hidrosfer və biosferin qovuşub qarşılıqlı təsirdə olduğu təbəqədir.
2) 1-ci mülahizəyə əsasən, bu təbəqənin daxilindəki kiçik təbii ərazi kompleksləri landşaft adlanır - hər landşaft təbii komponentlərin qarşılıqlı əlaqəsindən ibarətdir.
3) Qızılağac qoruğu əsasən dağ keçilərini qoruyur.
4) Zaqatala qoruğu Böyük Qafqazın cənub yamacındadır.',
  '1, 2 və 4 doğrudur: coğrafi təbəqə/landşaft tərifləri doğrudur; Zaqatala qoruğu Böyük Qafqazın cənub yamacındadır. 3-cü mülahizə yanlışdır: Qızılağac qoruğu dağ keçilərini yox, KÖÇƏRİ SU QUŞLARININ QIŞLAMA YERLƏRİNİ qoruyur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-tebeqe#8'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- cog10-yer-kainat#comb1
update public.questions set difficulty = 2 where ext_key = 'cog10-yer-kainat#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('cog10-yer-kainat#comb1', 'cog-10-yer-kainat',
  'Yer və kainat ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Günəş sistemi qaz-toz dumanlığından yaranmışdır.
2) 1-ci mülahizəyə əsasən, bu dumanlıqdan yaranan Yerin maqnit sahəsi (maqnitosfer) planeti zərərli kosmik şüalanmadan qoruyur - bu qoruyucu qat həyatın davam etməsi üçün vacibdir.
3) Yer öz oxu ətrafında fırlandığı üçün qütblərdən deyil, ekvatordan basıqdır.
4) Yerin özünəməxsus, qeyri-ideal həndəsi forması geoid adlanır.',
  '1, 2 və 4 doğrudur: Günəş sistemi qaz-toz dumanlığından yarandı, maqnitosfer kosmik şüalanmadan qoruyur; geoid Yerin formasıdır. 3-cü mülahizə yanlışdır: Yer QÜTBLƏRDƏN basıqdır, ekvatordan yox - fırlanma ekvatorda genişlənmə yaradır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'cog10-yer-kainat#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- fiz10-dinamika#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz10-dinamika#12';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz10-dinamika#comb1', 'fiz-10-dinamika',
  'Dinamika ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Huk qanununa görə elastiklik qüvvəsi uzanma ilə düz mütənasibdir: F = kx.
2) 1-ci mülahizəyə əsasən, cismin tarazlıqda qalması üçün ona təsir edən qüvvələrin əvəzləyicisi sıfır olmalıdır - məsələn, dəyişməz sürətlə üzən gəmiyə təsir edən qüvvələrin əvəzləyicisi də sıfırdır.
3) Çəkisizlik halı cisim masada duranda yaranır.
4) Qravitasiya sahəsi cazibə qarşılıqlı təsirinin ötürüldüyü sahədir.',
  '1, 2 və 4 doğrudur: Huk qanunu doğrudur, tarazlıqda qüvvələr cəmi sıfırdır (gəmi nümunəsi); qravitasiya sahəsi cazibəni ötürür. 3-cü mülahizə yanlışdır: çəkisizlik SƏRBƏST DÜŞMƏ zamanı yaranır, masada duranda yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz10-dinamika#12'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- fiz10-kinematika#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz10-kinematika#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz10-kinematika#comb1', 'fiz-10-kinematika',
  'Kinematika ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Avtobusda oturan sərnişin yol kənarındakı ağaca nəzərən hərəkətdədir - çünki hərəkət nisbidir.
2) 1-ci mülahizəyə əsasən, sükunət halı da mütləq deyil, nisbidir - hansı cismə nəzərən baxıldığından asılıdır.
3) Cisim tam bir dövrə vurduqda həm yolu, həm də yerdəyişməsi sıfır olur.
4) Çevrə üzrə hərəkətdə mərkəzəqaçma təcili çevrənin mərkəzinə doğru yönəlir.',
  '1, 2 və 4 doğrudur: hərəkət/sükunət nisbidir; mərkəzəqaçma təcili mərkəzə yönəlir. 3-cü mülahizə yanlışdır: tam dövrdə YOL SIFIR DEYİL (çevrənin uzunluğuna bərabərdir), yalnız YERDƏYİŞMƏ sıfırdır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz10-kinematika#27'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- fiz10-molekulyar#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz10-molekulyar#27';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz10-molekulyar#comb1', 'fiz-10-molekulyar',
  'Molekulyar-kinetik nəzəriyyə ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Sabit temperaturda gedən proses izotermik, sabit təzyiqdə gedən proses izobar, sabit həcmdə gedən proses isə izoxor adlanır.
2) 1-ci mülahizəyə əsasən, Boyl-Mariott qanunu məhz izotermik prosesi təsvir edir: sabit temperaturda pV = sabit.
3) Qaynamadan fərqli olaraq buxarlanma mayenin bütün həcmindən gedir.
4) Su damcısının kürə forması alması səthi gərilmə ilə bağlıdır.',
  '1, 2 və 4 doğrudur: izotermik/izobar/izoxor tərifləri doğrudur, Boyl-Mariott izotermik prosesi təsvir edir; damcının kürə forması səthi gərilmədəndir. 3-cü mülahizə yanlışdır: buxarlanma YALNIZ MAYENİN SƏTHİNDƏN gedir, bütün həcmdən yox - bu, qaynamanın xüsusiyyətidir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz10-molekulyar#27'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- fiz10-reqs-dalga#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz10-reqs-dalga#9';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz10-reqs-dalga#comb1', 'fiz-10-reqs-dalga',
  'Rəqslər və dalğalar ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Riyazi rəqqasın dövrü sapın uzunluğundan (və g-dən) asılıdır, yükün kütləsindən isə asılı deyil.
2) 1-ci mülahizəyə əsasən, yaylı rəqqasda isə vəziyyət fərqlidir - onun dövrü həm yükün kütləsindən, həm də yayın sərtliyindən asılıdır.
3) Rezonans hadisəsi temperatur artdıqda baş verir.
4) Dalğa yayılarkən maddəni daşımadan enerji ötürür.',
  '1, 2 və 4 doğrudur: riyazi rəqqas kütlədən asılı deyil, yaylı rəqqas kütlə+sərtlikdən asılıdır; dalğa enerji daşıyır, maddə yox. 3-cü mülahizə yanlışdır: rezonans temperaturdan yox, XARİCİ QÜVVƏNİN TEZLİYİ SİSTEMİN ÖZ TEZLİYİNƏ BƏRABƏR OLDUQDA baş verir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz10-reqs-dalga#9'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- fiz10-saxlanma#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz10-saxlanma#23';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz10-saxlanma#comb1', 'fiz-10-saxlanma',
  'Saxlanma qanunları ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) İmpuls sürət istiqamətində yönəlmiş vektor kəmiyyətdir, impulsun saxlanması qanunu isə xarici qüvvələrin təsiri olmayan qapalı sistemlərdə ödənilir.
2) 1-ci mülahizəyə əsasən, raketin hərəkəti və atəş zamanı silahın geri təpməsi məhz bu qanuna - impulsun saxlanmasına əsaslanır.
3) Cismin sürəti 2 dəfə artdıqda kinetik enerjisi də 2 dəfə artır.
4) Əbədi mühərrik yaratmaq mümkün deyil, çünki bu, enerjinin saxlanması qanununa ziddir.',
  '1, 2 və 4 doğrudur: impuls vektordur, qapalı sistemdə saxlanır, raket/silah nümunələri buna əsaslanır; əbədi mühərrik enerjinin saxlanması qanununa ziddir. 3-cü mülahizə yanlışdır: sürət 2 dəfə artanda kinetik enerji 2 dəfə yox, 4 DƏFƏ artır (Ek sürətin kvadratı ilə mütənasibdir).',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz10-saxlanma#23'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- fiz10-termodinamika#comb1
update public.questions set difficulty = 2 where ext_key = 'fiz10-termodinamika#7';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('fiz10-termodinamika#comb1', 'fiz-10-termodinamika',
  'Termodinamika ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Termodinamikanın birinci qanununa görə verilən istilik daxili enerjinin dəyişməsinə və işə sərf olunur: Q = ΔU + A.
2) 1-ci mülahizəyə əsasən, qaz sıxılarkən onun üzərində iş görüldükdə (sistemə iş ötürüldükdə) daxili enerjisi artır - qaz qızır.
3) İstilik mühərrikinin FİƏ-si 100%-ə bərabər ola bilər, çünki bütün istilik faydalı işə çevrilir.
4) İstilik mühərrikinin əsas hissələri qızdırıcı, işçi cisim və soyuducudan ibarətdir.',
  '1, 2 və 4 doğrudur: I qanun Q = ΔU + A doğrudur, sıxılan qazın daxili enerjisi artır; mühərrik qızdırıcı/işçi cisim/soyuducudan ibarətdir. 3-cü mülahizə yanlışdır: FİƏ heç vaxt 100%-ə çatmır, çünki istiliyin bir hissəsi mütləq SOYUDUCUYA verilir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'fiz10-termodinamika#7'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- kim10-alkan#comb1
update public.questions set difficulty = 2 where ext_key = 'kim10-alkan#29';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim10-alkan#comb1', 'kim-10-alkan',
  'Alkanlar ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Alkanların ümumi formulu CnH2n+2-dir; n = 6 olduqda C6H14 (heksan) molekulu alınır.
2) 1-ci mülahizəyə əsasən, eyni molekul formuluna (C4H10) malik olan n-butan və izobutan bir-birinin izomerləridir - fərqli quruluşa malikdirlər.
3) Alkanlar doymamış olduqları üçün asanlıqla polimerləşir.
4) Metanın xlorla işıqda reaksiyası əvəzetmə reaksiyasıdır.',
  '1, 2 və 4 doğrudur: alkan formulu və izomerlik doğrudur, metan+xlor əvəzetmədir. 3-cü mülahizə yanlışdır: alkanlar DOYMUŞ olduqları üçün POLİMERLƏŞMİR, doymamış deyil.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim10-alkan#29'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- kim10-alken#comb1
update public.questions set difficulty = 2 where ext_key = 'kim10-alken#24';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim10-alken#comb1', 'kim-10-alken',
  'Alkenlər ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Alkenin bromlu suyu rəngsizləşdirməsi molekulda ikiqat rabitənin - doymamışlığın olduğunu göstərir.
2) 1-ci mülahizəyə əsasən, bu doymamışlıq səbəbindən etilenə hidrogen birləşdirildikdə doymamışlıq aradan qalxaraq doymuş alkan - etan alınır.
3) Alkenlərə hidrogen-halogenidlərin birləşməsi Hess qanununa tabedir.
4) Alkenlər sənayedə əsasən neft məhsullarının krekinqindən alınır.',
  '1, 2 və 4 doğrudur: bromlu su doymamışlığı göstərir, etilen+H2→etan doğrudur; alkenlər krekinqdən alınır. 3-cü mülahizə yanlışdır: hidrogen-halogenidlərin birləşməsi Hess qanununa yox, MARKOVNİKOV QAYDASINA tabedir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim10-alken#24'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- kim10-alkin#comb1
update public.questions set difficulty = 2 where ext_key = 'kim10-alkin#21';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim10-alkin#comb1', 'kim-10-alkin',
  'Alkinlər ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Üçqat rabitə bir siqma və iki pi rabitəsindən ibarətdir; asetilen sənayedə kalsium-karbidin su ilə reaksiyasından alınır.
2) 1-ci mülahizəyə əsasən, bu çoxsaylı rabitələr üçqat rabitəni ikiqat rabitədən daha qısa edir.
3) Alkin adındakı rəqəm (məsələn, butin-1) molekulun yaşını göstərir.
4) Kalsium-karbidin formulu CaC2-dir.',
  '1, 2 və 4 doğrudur: üçqat rabitə tərkibi və asetilen alınması doğrudur, üçqat rabitə qısadır; CaC2 doğru formuldur. 3-cü mülahizə yanlışdır: rəqəm molekulun yaşını yox, ÜÇQAT RABİTƏNİN YERİNİ göstərir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim10-alkin#21'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- kim10-aromatik#comb1
update public.questions set difficulty = 2 where ext_key = 'kim10-aromatik#10';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim10-aromatik#comb1', 'kim-10-aromatik',
  'Aromatik karbohidrogenlər ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Benzolun molekul formulu C6H6-dır, altı karbon atomu müntəzəm altıbucaqlı halqa əmələ gətirir; bu halqavi quruluşu ilk dəfə Kekule təklif etmişdir.
2) 1-ci mülahizəyə əsasən, benzolun homoloqları ümumi CnH2n−6 formuluna tabedir.
3) Benzol doymamış olduğu üçün bromlu suyu dərhal rəngsizləşdirir.
4) Toluolun kimyəvi adı metilbenzoldur.',
  '1, 2 və 4 doğrudur: benzol formulu/quruluşu və Kekule doğrudur, homoloqlar CnH2n−6 formulundadır; toluol metilbenzoldur. 3-cü mülahizə yanlışdır: benzol adi şəraitdə bromlu suyu RƏNGSİZLƏŞDİRMİR - aromatik rabitənin sabitliyi buna imkan vermir.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim10-aromatik#10'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- kim10-dien-tsiklo#comb1
update public.questions set difficulty = 2 where ext_key = 'kim10-dien-tsiklo#20';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim10-dien-tsiklo#comb1', 'kim-10-dien-tsiklo',
  'Alkadienlər və tsikloalkanlar ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Alkadienlərin molekulunda iki ikiqat rabitə olur, ümumi formulu isə CnH2n−2-dir.
2) 1-ci mülahizəyə əsasən, təbii kauçuk da belə bir dien - izoprenin polimeridir, kauçuku rezinə çevirən proses isə kükürdlə aparılan vulkanizasiyadır.
3) Tsikloalkanla eyni formullu alken bir-birinin homoloqlarıdır.
4) Ən kiçik tsikloalkan tsiklopropandır.',
  '1, 2 və 4 doğrudur: alkadien tərifi/kauçuk-vulkanizasiya doğrudur; tsiklopropan ən kiçik tsikloalkandır. 3-cü mülahizə yanlışdır: eyni formullu (CnH2n) tsikloalkan və alken homoloq yox, SİNİFLƏRARASI İZOMERLƏRDİR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim10-dien-tsiklo#20'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- kim10-neft#comb1
update public.questions set difficulty = 2 where ext_key = 'kim10-neft#17';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('kim10-neft#comb1', 'kim-10-neft',
  'Neft emalı ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Krekinq prosesi iri molekulların qızdırılmaqla kiçik molekullara parçalanmasıdır, bu proses daha çox benzin almaq üçün aparılır.
2) 1-ci mülahizəyə əsasən, əldə edilən benzinin keyfiyyəti oktan ədədi ilə qiymətləndirilir - yüksək oktan ədədi benzinin detonasiyaya daha davamlı olduğunu göstərir.
3) Distillə kalonunda ən yuxarıda ən ağır fraksiya (mazut) toplanır.
4) Neftin mənşəyi haqqında əsas fərziyyəyə görə o, qədim üzvi qalıqların çevrilməsindən yaranmışdır.',
  '1, 2 və 4 doğrudur: krekinq/oktan ədədi doğrudur; neft üzvi qalıqlardan yaranıb. 3-cü mülahizə yanlışdır: distillə kalonunda yuxarıda ƏN YÜNGÜL (benzin) fraksiya toplanır, ağır fraksiya yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'kim10-neft#17'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-deyiskenlik#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-deyiskenlik#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-deyiskenlik#comb1', 'bio-10-deyiskenlik',
  'Dəyişkənlik ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Modifikasiya dəyişkənliyi yalnız fenotipi dəyişir, genotipə toxunmur; buna görə də modifikasiya irsi deyil, mutasiya isə irsidir.
2) 1-ci mülahizəyə əsasən, mutasiyaların irsiliyi onların harada baş verməsindən asılıdır: cinsiyyət hüceyrələrindəki mutasiyalar nəslə ötürülə bilir.
3) Bədən (somatik) hüceyrələrindəki mutasiyalar da cinsi yolla nəslə ötürülür.
4) Reaksiya normasının hədlərini genotip müəyyən edir.',
  '1, 2 və 4 doğrudur: modifikasiya fenotipi dəyişir və irsi deyil, cinsiyyət hüceyrəsi mutasiyaları ötürülür; reaksiya norması genotiplə müəyyən olunur. 3-cü mülahizə yanlışdır: SOMATİK mutasiyalar nəslə ÖTÜRÜLMÜR, yalnız cinsiyyət hüceyrələrindəkilər ötürülür.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-deyiskenlik#18'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-ekologiya#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-ekologiya#3';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-ekologiya#comb1', 'bio-10-ekologiya',
  'Ekologiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Ekoloji piramida qida səviyyələri üzrə enerjinin azalmasını göstərir - bir səviyyədən digərinə təqribən 10% enerji keçir.
2) 1-ci mülahizəyə əsasən, biosfer haqqındakı bu qanunauyğunluqları öyrənən təlimin banisi Vernadskidir, o həmçinin insan zəkasının idarə etdiyi biosfer mərhələsini - noosferi də araşdırmışdır.
3) Şibyə iki bitkinin simbiozudur.
4) Populyasiyanın sıxlığı vahid sahəyə düşən fərdlərin sayıdır.',
  '1, 2 və 4 doğrudur: ekoloji piramida/10% enerji doğrudur, Vernadski biosfer/noosfer təliminin banisidir; sıxlıq tərifi doğrudur. 3-cü mülahizə yanlışdır: şibyə iki bitki yox, GÖBƏLƏK VƏ YOSUNUN simbiozudur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-ekologiya#3'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-epidemiologiya#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-epidemiologiya#18';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-epidemiologiya#comb1', 'bio-10-epidemiologiya',
  'Epidemiologiya ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Yoluxucu xəstəliyin bir ölkə daxilində kütləvi yayılması epidemiya, qitələri əhatə edən qlobal yayılması isə pandemiya adlanır.
2) 1-ci mülahizəyə əsasən, bu cür geniş yayılan infeksiyalarla mübarizədə antibiotiklər yalnız bakterial infeksiyalara təsir edir, viruslara qarşı təsirsizdir.
3) QİÇS-in törədicisi bakteriyadır.
4) Heyvanlardan insana keçən xəstəliklər zoonozlar adlanır.',
  '1, 2 və 4 doğrudur: epidemiya/pandemiya fərqi doğrudur, antibiotiklər viruslara təsir etmir; zoonozlar heyvandan insana keçir. 3-cü mülahizə yanlışdır: QİÇS-in törədicisi bakteriya yox, VİRUSDUR (İİV).',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-epidemiologiya#18'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-genetika#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-genetika#6';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-genetika#comb1', 'bio-10-genetika',
  'Genetika ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Monohibrid çarpazlaşmada F2 nəslində parçalanma 3:1 nisbətindədir, dihibrid çarpazlaşmada isə 9:3:3:1 nisbətindədir.
2) 1-ci mülahizəyə əsasən, bu qanunauyğunluqlardan fərqli olaraq, bir xromosomda yerləşən genlər ayrı-ayrı deyil, birlikdə - ilişikli irsən keçir; bunu Tomas Morqan drozofil milçəyi üzərində sübut etmişdir.
3) Homozibot orqanizmin genotipi Aa kimi yazılır.
4) Analiz çarpazlaşması dominant fenotipli fərdin genotipini müəyyən etmək üçün aparılır.',
  '1, 2 və 4 doğrudur: monohibrid/dihibrid parçalanma nisbətləri və ilişikli irsiyyət (Morqan) doğrudur; analiz çarpazlaşması genotipi müəyyən edir. 3-cü mülahizə yanlışdır: Aa HETEROZİBOTUN genotipidir, homozibot AA və ya aa yazılır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-genetika#6'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-heyat-prosesleri#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-heyat-prosesleri#28';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-heyat-prosesleri#comb1', 'bio-10-heyat-prosesleri',
  'Canlıların həyat prosesləri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Həşəratlar traxeya borucuqları ilə, torpaq (yağış) qurdu isə nəm dəri səthi ilə tənəffüs edir.
2) 1-ci mülahizəyə əsasən, bu tənəffüs formalarından fərqli olaraq, anaerob orqanizmlər ümumiyyətlə oksigensiz mühitdə yaşayır.
3) Oksigenli tənəffüs oksigensiz tənəffüsdən daha az enerji verir.
4) Böyrəklərdə qandan mübadilə tullantıları süzülərək sidik əmələ gəlir.',
  '1, 2 və 4 doğrudur: həşərat/torpaq qurdu tənəffüs üsulları və anaerob orqanizmlər doğrudur; böyrəklər tullantıları süzür. 3-cü mülahizə yanlışdır: oksigenli tənəffüs oksigensizdən DAHA ÇOX enerji verir, az yox.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-heyat-prosesleri#28'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-istehsal#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-istehsal#11';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-istehsal#comb1', 'bio-10-istehsal',
  'Plastik mübadilə ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Fotosintezin işıq fazasında su parçalanır və ATF sintez olunur, qaranlıq fazasında isə karbon qazından üzvi maddə (qlükoza) sintez olunur.
2) 1-ci mülahizəyə əsasən, bəzi bakteriyalarda isə işıq əvəzinə kimyəvi reaksiyaların enerjisi ilə üzvi maddə sintez olunur - bu, xemosintezdir.
3) Bir molekul qlükozanın tam oksidləşməsindən cəmi 2 ATF sintez olunur.
4) Energetik mübadilənin oksigensiz mərhələsində qlükoza süd turşusuna qədər parçalanır.',
  '1, 2 və 4 doğrudur: fotosintez faza fərqi və xemosintez doğrudur; oksigensiz mərhələdə qlükoza süd turşusuna parçalanır. 3-cü mülahizə yanlışdır: qlükozanın tam oksidləşməsindən 2 yox, 38 ATF sintez olunur.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-istehsal#11'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-saglam-heyat#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-saglam-heyat#26';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-saglam-heyat#comb1', 'bio-10-saglam-heyat',
  'Sağlam həyat tərzi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Bazal mübadilə tam sakitlik halında sərf olunan minimal enerjidir; bu mübadilənin sürətini qalxanabənzər vəzin hormonları tənzimləyir.
2) 1-ci mülahizəyə əsasən, orqanizmin daxili mühitinin bu cür sabit saxlanılması homeostaz adlanır.
3) Beyin fəaliyyəti üçün əsas enerji mənbəyi yağ turşularıdır.
4) Bioritmlər orqanizmdəki proseslərin dövri dəyişməsidir.',
  '1, 2 və 4 doğrudur: bazal mübadilə/homeostaz doğrudur; bioritmlər dövri dəyişmədir. 3-cü mülahizə yanlışdır: beyinin əsas enerji mənbəyi yağ turşuları yox, QLÜKOZADIR.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-saglam-heyat#26'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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

-- ------------------------------------------------------------- bio10-tekamul#comb1
update public.questions set difficulty = 2 where ext_key = 'bio10-tekamul#13';

with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values
 ('bio10-tekamul#comb1', 'bio-10-tekamul',
  'Təkamül ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?
1) Homoloji orqanlar mənşəyi eyni, funksiyası fərqli olan orqanlardır (insanın əli, balinanın üzgəci); analoji orqanlar isə funksiyası eyni, mənşəyi fərqli olan orqanlardır (kəpənək qanadı, quş qanadı).
2) 1-ci mülahizəyə əsasən, quşlarda istiqanlılığın yaranması kimi quruluşu əsaslı mürəkkəbləşdirən iri təkamül dəyişiklikləri aromorfoz adlanır.
3) Parazitlərdə orqanların sadələşməsi aromorfoz adlanır.
4) İdioadaptasiya ümumi səviyyəni dəyişməyən xüsusi uyğunlaşmadır.',
  '1, 2 və 4 doğrudur: homoloji/analoji orqanlar və aromorfoz doğru təsvir olunub; idioadaptasiya xüsusi uyğunlaşmadır. 3-cü mülahizə yanlışdır: parazitlərdə sadələşmə aromorfoz yox, DEGENERASİYA adlanır.',
  '1, 2, 3, 4', '1, 2, 3', '1, 2, 4', '2, 4', 3)
),
kohne_q as (
  select quarter from public.questions where ext_key = 'bio10-tekamul#13'
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, 3, kq.quarter, 'published'
    from d
    cross join kohne_q kq
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
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
  if v_n <> 225 then
    raise exception '112: 225 birlesme sual gozlenilirdi, % tapildi', v_n;
  end if;
  raise notice '112 OK - % birlesme sual', v_n;
end $$;
