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

do $$
declare v_n int;
begin
  select count(*) into v_n from public.questions where ext_key like '%#comb%';
  if v_n <> 24 then
    raise exception '112: 24 birlesme sual gozlenilirdi, % tapildi', v_n;
  end if;
  raise notice '112 OK - % birlesme sual', v_n;
end $$;
