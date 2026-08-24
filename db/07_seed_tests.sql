-- =====================================================================
--  07_seed_tests.sql : ilk platforma testleri (3-cu sinif)
--
--  Tekrar isledile biler: testler slug uzre taninir, suallar silinib
--  yeniden yazilir. Muellim testlerine toxunmur.
--
--  Her sual bir MOVZUYA baglanir - "zeif noqte analizi" bunun uzerinde
--  qurulacaq.
-- =====================================================================

-- ------------------------------------------------------- on hazirliq
--  Asagidaki "on conflict (ext_key)" TAM unikal indeks teleb edir.
--  Kohne miqrasiya QISMEN indeks yaradirdi (where ext_key is not null)
--  ve ON CONFLICT ona uygun gelmirdi (42P10).  Duzeldirik.
do $$
begin
  if exists (select 1 from pg_indexes
              where schemaname='public' and tablename='questions'
                and indexname='questions_ext_key_key'
                and indexdef ilike '%where%') then
    drop index public.questions_ext_key_key;
    raise notice 'Qismen ext_key indeksi tam indeksle evez olundu.';
  end if;
  if not exists (select 1 from pg_indexes
                  where schemaname='public' and tablename='questions'
                    and indexdef ilike '%ext_key%') then
    create unique index questions_ext_key_key on public.questions(ext_key);
  end if;
end $$;

-- ------------------------------------------------------------ movzular
--  Movzular artiq burda YARANMIR - 14_movzular.sql-dedir.
--  Sebeb: movzu agaci butun sinifler ucundur, bir testin seed-ine
--  bagli olmamalidir.  Burda yalniz istinad edilir.

-- --------------------------------------------------------------- testler
insert into public.tests (owner_type, program_id, subject_id, level_id, slug,
                          title, description, is_free, status, pass_percent,
                          time_limit_sec, max_attempts)
select 'platform', p.id, s.id, l.id, v.slug, v.title, v.descr,
       v.is_free, 'published', 60, v.tlimit, 1   -- bir cehd
  from (values
         ('riy-3-vurma-1', 'riyaziyyat', 'Vurma cədvəli — 1',
          '2, 3, 4 və 5-ə vurma', true,  600),
         ('riy-3-qarisiq-1','riyaziyyat', 'Qarışıq riyaziyyat — 1',
          'Toplama, çıxma, vurma və mətn məsələsi', true, 900),
         ('az-3-dil-1',     'az-dili',    'Azərbaycan dili — 1',
          'Sait-samit, söz növləri, yazı qaydası', true, 600),
         ('riy-3-analiz',   'riyaziyyat', 'Genişləndirilmiş analiz testi',
          'Zəif mövzuları müəyyən edir — abunə paketinə daxildir', false, 1200)
       ) as v(slug, subj, title, descr, is_free, tlimit)
  join public.subjects s on s.slug = v.subj
  join public.programs p on p.slug = 'ibtidai'
  join public.levels   l on l.program_id = p.id and l.code = '3'
on conflict (slug) do update
  set title = excluded.title, description = excluded.description,
      is_free = excluded.is_free, status = excluded.status,
      time_limit_sec = excluded.time_limit_sec,
      max_attempts = excluded.max_attempts;

-- Suallar SILINMIR - ext_key uzre uzerine yazilir.  Silmek olmaz:
-- sagird artiq cavab veribse test_questions restrict ile imtina edir,
-- ve her isletmede bank suallarla dolardi.
-- Yalniz variantlar temizlenir (asagida yeniden yazilir).
delete from public.question_options o
 using public.questions q
 where o.question_id = q.id and q.owner_type = 'platform'
   and q.ext_key like any (array['riy-3-vurma-1#%','riy-3-qarisiq-1#%',
                                 'az-3-dil-1#%','riy-3-analiz#%']);

-- ------------------------------------------------------- suallar yazilir
--  DIQQET: muveqqeti cedvel ISLETMIRIK. Supabase SQL Editor skripti
--  havuzlanmis baglanti uzerinden isledir - "create temporary table"
--  novbeti emrde artiq movcud olmur (relation "_q" does not exist).
--  Bunun evezine melumat CTE-dedir ve iki insert bir emrde gedir:
--  birinci suallari yazir ve RETURNING ile id-leri verir, ikinci hemin
--  id-lere variantlari baglayir.
with d(test, ord, topic, body, why, opts, correct) as (values
-- Vurma cedveli
('riy-3-vurma-1',1,'riy-3-vurma-cedveli','6 × 7 neçə edər?',
 'Altı dəfə yeddi qırx iki edər.', array['42','36','48','54'],1),
('riy-3-vurma-1',2,'riy-3-vurma-cedveli','9 × 8 neçə edər?',
 'Doqquz dəfə səkkiz yetmiş iki edər.', array['64','72','81','78'],2),
('riy-3-vurma-1',3,'riy-3-vurma-cedveli','4 × 9 neçə edər?',
 'Dörd dəfə doqquz otuz altı edər.', array['32','35','36','40'],3),
('riy-3-vurma-1',4,'riy-3-vurma-cedveli','5 × 6 neçə edər?',
 'Beşə vuranda cavab həmişə 0 və ya 5 ilə bitir.', array['25','30','35','36'],2),
('riy-3-vurma-1',5,'riy-3-vurma-cedveli','3 × 8 neçə edər?',
 'Üç dəfə səkkiz iyirmi dörd edər.', array['21','24','27','28'],2),
('riy-3-vurma-1',6,'riy-3-vurma-cedveli','7 × 7 neçə edər?',
 'Yeddi dəfə yeddi qırx doqquz edər.', array['42','49','56','63'],2),

-- Qarisiq
('riy-3-qarisiq-1',1,'riy-3-toplama-cixma','245 + 138 neçə edər?',
 'Vahidlər: 5+8=13, biri onluğa keçir.', array['373','383','393','483'],2),
('riy-3-qarisiq-1',2,'riy-3-toplama-cixma','500 − 264 neçə edər?',
 'Beş yüzdən iki yüz altmış dörd çıxsaq iki yüz otuz altı qalır.',
 array['236','246','336','244'],1),
('riy-3-qarisiq-1',3,'riy-3-vurma-cedveli','8 × 6 neçə edər?',
 'Səkkiz dəfə altı qırx səkkiz edər.', array['42','46','48','54'],3),
('riy-3-qarisiq-1',4,'riy-3-bolme','56 : 8 neçə edər?',
 'Səkkizə vurulanda 56 verən ədəd 7-dir.', array['6','7','8','9'],2),
('riy-3-qarisiq-1',5,'riy-3-mesele',
 'Aysunun 24 konfeti var. O, konfetləri 4 dostuna bərabər payladı. Hər dosta neçə konfet düşdü?',
 'Bərabər paylamaq bölmə deməkdir: 24 : 4 = 6.', array['4','5','6','8'],3),
('riy-3-qarisiq-1',6,'riy-3-mesele',
 'Bir qutuda 9 qələm var. 5 belə qutuda neçə qələm var?',
 'Hər qutuda eyni sayda olduğu üçün vururuq: 9 × 5 = 45.',
 array['40','45','49','54'],2),
('riy-3-qarisiq-1',7,'riy-3-toplama-cixma',
 'Kənanın 150 manatı var idi. 65 manat xərclədi. Neçə manatı qaldı?',
 'Xərclənən pul çıxılır: 150 − 65 = 85.', array['75','85','95','115'],2),
('riy-3-qarisiq-1',8,'riy-3-bolme','63 : 9 neçə edər?',
 'Doqquza vurulanda 63 verən ədəd 7-dir.', array['6','7','8','9'],2),

-- Azerbaycan dili
('az-3-dil-1',1,'az-3-sait-samit','«Kitab» sözündə neçə sait var?',
 'Saitlər: i və a. Cəmi 2 sait.', array['1','2','3','4'],2),
('az-3-dil-1',2,'az-3-sait-samit','Hansı sıradakı hərflərin hamısı saitdir?',
 'a, e, ı, i, o, ö, u, ü — bunlar saitlərdir.',
 array['a, b, c','e, ı, ö','k, l, m','s, ş, t'],2),
('az-3-dil-1',3,'az-3-soz-novleri','«Qaçmaq» sözü hansı söz növüdür?',
 'İş, hərəkət bildirən sözlər feildir.', array['isim','sifət','feil','say'],3),
('az-3-dil-1',4,'az-3-soz-novleri','«Gözəl» sözü hansı söz növüdür?',
 'Əşyanın əlamətini bildirən sözlər sifətdir.',
 array['isim','sifət','feil','əvəzlik'],2),
('az-3-dil-1',5,'az-3-yazi-qaydasi','Hansı söz düzgün yazılıb?',
 'Şəhər adları böyük hərflə yazılır.',
 array['bakı','Bakı','BAkı','baKı'],2),
('az-3-dil-1',6,'az-3-yazi-qaydasi','Cümlənin sonunda hansı işarə qoyulur?',
 'Nəqli cümlənin sonunda nöqtə qoyulur.',
 array['vergül','nöqtə','tire','iki nöqtə'],2),

-- Odenisli analiz testi
('riy-3-analiz',1,'riy-3-vurma-cedveli','12 × 4 neçə edər?',
 'On iki dörd dəfə qırx səkkiz edər.', array['42','44','46','48'],4),
('riy-3-analiz',2,'riy-3-bolme','81 : 9 neçə edər?',
 'Doqquza vurulanda 81 verən ədəd 9-dur.', array['7','8','9','11'],3),
('riy-3-analiz',3,'riy-3-mesele',
 'Sinifdə 28 şagird var. Onların yarısı qızdır. Neçə qız var?',
 'Yarısını tapmaq üçün 2-yə bölürük: 28 : 2 = 14.',
 array['12','14','16','18'],2)
),
ins as (
  -- Sual BANKA yazilir: hansi testde islendiyi burda deyil
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind, body,
     explanation, difficulty, points, status)
  select d.test || '#' || d.ord, 'platform', t.subject_id, t.level_id, tp.id,
         'single', d.body, d.why, 2, 1, 'published'
    from d
    join public.tests    t  on t.slug = d.test
    join public.subjects s  on s.id = t.subject_id
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        topic_id = excluded.topic_id, subject_id = excluded.subject_id,
        level_id = excluded.level_id, status = excluded.status
  returning id, ext_key
),
tq as (
  -- Terkib: hansi test hansi sualı hansi sira ile goturur
  insert into public.test_questions (test_id, question_id, ord)
  select t.id, ins.id, d.ord
    from ins join d on ins.ext_key = d.test || '#' || d.ord
    join public.tests t on t.slug = d.test
  on conflict (test_id, question_id) do update set ord = excluded.ord
  returning question_id
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.body, o.ord = d.correct
  from ins
  join d on ins.ext_key = d.test || '#' || d.ord,
  lateral unnest(d.opts) with ordinality as o(body, ord);

-- ------------------------------------------------------------- hesabat
do $$
declare n_t int; n_q int; n_o int; bad text;
begin
  select count(*) into n_t from public.tests where owner_type = 'platform';
  select count(*) into n_q from public.questions where owner_type = 'platform';
  select count(*) into n_o from public.question_options o
    join public.questions q on q.id = o.question_id
   where q.owner_type = 'platform';

  -- Her sualin DEQIQ bir duzgun cavabi olmalidir
  select string_agg(x.body, ' | ') into bad from (
    select q.body from public.questions q
     where q.owner_type = 'platform'
     group by q.id, q.body
    having count(*) filter (where exists (
             select 1 from public.question_options o
              where o.question_id = q.id and o.is_correct)) <> 1
        or (select count(*) from public.question_options o
             where o.question_id = q.id and o.is_correct) <> 1
  ) x;
  if bad is not null then
    raise exception 'Bu suallarda duzgun cavab sayi 1 deyil: %', bad;
  end if;

  -- Movzusuz sual qalmasin
  select count(*)::text into bad from public.questions q
   where q.owner_type = 'platform' and q.topic_id is null;
  if bad <> '0' then
    raise exception '% sual movzuya baglanmayib', bad;
  end if;

  --  Movzu slug-i sehv olsa join kesir ve sual SESSIZCE yazilmir.
  --  Bir defe bele oldu: 23 sualdan 16-si dusdu, xeta cixmadi.
  if n_q <> 23 then
    raise exception 'Gozlenilen 23 sual, yazilan %.  Movzu slug-i sehv ola biler '
      '(14_movzular.sql-deki adlarla uygunlasdirin).', n_q;
  end if;

  raise notice 'Platforma testleri: % test, % sual, % variant', n_t, n_q, n_o;
end $$;
