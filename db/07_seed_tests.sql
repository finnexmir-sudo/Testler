-- =====================================================================
--  07_seed_tests.sql : ilk platforma testleri (3-cu sinif)
--
--  Tekrar isledile biler: testler slug uzre taninir, suallar silinib
--  yeniden yazilir. Muellim testlerine toxunmur.
--
--  Her sual bir MOVZUYA baglanir - "zeif noqte analizi" bunun uzerinde
--  qurulacaq.
-- =====================================================================

-- ------------------------------------------------------------ movzular
insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from public.subjects s
  join public.programs p on p.slug = 'ibtidai'
  join public.levels   l on l.program_id = p.id and l.code = '3',
       (values ('vurma-cedveli','Vurma cədvəli',10),
               ('bolme',        'Bölmə',20),
               ('toplama-cixma','Toplama və çıxma',30),
               ('mesele',       'Mətn məsələləri',40)) as v(slug,name,sort)
 where s.slug = 'riyaziyyat'
on conflict (subject_id, slug) do update set name = excluded.name;

insert into public.topics (subject_id, level_id, slug, name, sort)
select s.id, l.id, v.slug, v.name, v.sort
  from public.subjects s
  join public.programs p on p.slug = 'ibtidai'
  join public.levels   l on l.program_id = p.id and l.code = '3',
       (values ('sait-samit','Sait və samit',10),
               ('soz-novleri','Söz növləri',20),
               ('yazi-qaydasi','Yazı qaydası',30)) as v(slug,name,sort)
 where s.slug = 'az-dili'
on conflict (subject_id, slug) do update set name = excluded.name;

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

-- Suallari her defe temiz yaziriq (yalniz platforma testlerinde)
delete from public.questions q
 using public.tests t
 where q.test_id = t.id and t.owner_type = 'platform'
   and t.slug in ('riy-3-vurma-1','riy-3-qarisiq-1','az-3-dil-1','riy-3-analiz');

-- ------------------------------------------------------- suallar yazilir
--  DIQQET: muveqqeti cedvel ISLETMIRIK. Supabase SQL Editor skripti
--  havuzlanmis baglanti uzerinden isledir - "create temporary table"
--  novbeti emrde artiq movcud olmur (relation "_q" does not exist).
--  Bunun evezine melumat CTE-dedir ve iki insert bir emrde gedir:
--  birinci suallari yazir ve RETURNING ile id-leri verir, ikinci hemin
--  id-lere variantlari baglayir.
with d(test, ord, topic, body, why, opts, correct) as (values
-- Vurma cedveli
('riy-3-vurma-1',1,'vurma-cedveli','6 × 7 neçə edər?',
 'Altı dəfə yeddi qırx iki edər.', array['42','36','48','54'],1),
('riy-3-vurma-1',2,'vurma-cedveli','9 × 8 neçə edər?',
 'Doqquz dəfə səkkiz yetmiş iki edər.', array['64','72','81','78'],2),
('riy-3-vurma-1',3,'vurma-cedveli','4 × 9 neçə edər?',
 'Dörd dəfə doqquz otuz altı edər.', array['32','35','36','40'],3),
('riy-3-vurma-1',4,'vurma-cedveli','5 × 6 neçə edər?',
 'Beşə vuranda cavab həmişə 0 və ya 5 ilə bitir.', array['25','30','35','36'],2),
('riy-3-vurma-1',5,'vurma-cedveli','3 × 8 neçə edər?',
 'Üç dəfə səkkiz iyirmi dörd edər.', array['21','24','27','28'],2),
('riy-3-vurma-1',6,'vurma-cedveli','7 × 7 neçə edər?',
 'Yeddi dəfə yeddi qırx doqquz edər.', array['42','49','56','63'],2),

-- Qarisiq
('riy-3-qarisiq-1',1,'toplama-cixma','245 + 138 neçə edər?',
 'Vahidlər: 5+8=13, biri onluğa keçir.', array['373','383','393','483'],2),
('riy-3-qarisiq-1',2,'toplama-cixma','500 − 264 neçə edər?',
 'Beş yüzdən iki yüz altmış dörd çıxsaq iki yüz otuz altı qalır.',
 array['236','246','336','244'],1),
('riy-3-qarisiq-1',3,'vurma-cedveli','8 × 6 neçə edər?',
 'Səkkiz dəfə altı qırx səkkiz edər.', array['42','46','48','54'],3),
('riy-3-qarisiq-1',4,'bolme','56 : 8 neçə edər?',
 'Səkkizə vurulanda 56 verən ədəd 7-dir.', array['6','7','8','9'],2),
('riy-3-qarisiq-1',5,'mesele',
 'Aysunun 24 konfeti var. O, konfetləri 4 dostuna bərabər payladı. Hər dosta neçə konfet düşdü?',
 'Bərabər paylamaq bölmə deməkdir: 24 : 4 = 6.', array['4','5','6','8'],3),
('riy-3-qarisiq-1',6,'mesele',
 'Bir qutuda 9 qələm var. 5 belə qutuda neçə qələm var?',
 'Hər qutuda eyni sayda olduğu üçün vururuq: 9 × 5 = 45.',
 array['40','45','49','54'],2),
('riy-3-qarisiq-1',7,'toplama-cixma',
 'Kənanın 150 manatı var idi. 65 manat xərclədi. Neçə manatı qaldı?',
 'Xərclənən pul çıxılır: 150 − 65 = 85.', array['75','85','95','115'],2),
('riy-3-qarisiq-1',8,'bolme','63 : 9 neçə edər?',
 'Doqquza vurulanda 63 verən ədəd 7-dir.', array['6','7','8','9'],2),

-- Azerbaycan dili
('az-3-dil-1',1,'sait-samit','«Kitab» sözündə neçə sait var?',
 'Saitlər: i və a. Cəmi 2 sait.', array['1','2','3','4'],2),
('az-3-dil-1',2,'sait-samit','Hansı sıradakı hərflərin hamısı saitdir?',
 'a, e, ı, i, o, ö, u, ü — bunlar saitlərdir.',
 array['a, b, c','e, ı, ö','k, l, m','s, ş, t'],2),
('az-3-dil-1',3,'soz-novleri','«Qaçmaq» sözü hansı söz növüdür?',
 'İş, hərəkət bildirən sözlər feildir.', array['isim','sifət','feil','say'],3),
('az-3-dil-1',4,'soz-novleri','«Gözəl» sözü hansı söz növüdür?',
 'Əşyanın əlamətini bildirən sözlər sifətdir.',
 array['isim','sifət','feil','əvəzlik'],2),
('az-3-dil-1',5,'yazi-qaydasi','Hansı söz düzgün yazılıb?',
 'Şəhər adları böyük hərflə yazılır.',
 array['bakı','Bakı','BAkı','baKı'],2),
('az-3-dil-1',6,'yazi-qaydasi','Cümlənin sonunda hansı işarə qoyulur?',
 'Nəqli cümlənin sonunda nöqtə qoyulur.',
 array['vergül','nöqtə','tire','iki nöqtə'],2),

-- Odenisli analiz testi
('riy-3-analiz',1,'vurma-cedveli','12 × 4 neçə edər?',
 'On iki dörd dəfə qırx səkkiz edər.', array['42','44','46','48'],4),
('riy-3-analiz',2,'bolme','81 : 9 neçə edər?',
 'Doqquza vurulanda 81 verən ədəd 9-dur.', array['7','8','9','11'],3),
('riy-3-analiz',3,'mesele',
 'Sinifdə 28 şagird var. Onların yarısı qızdır. Neçə qız var?',
 'Yarısını tapmaq üçün 2-yə bölürük: 28 : 2 = 14.',
 array['12','14','16','18'],2)
),
ins as (
  insert into public.questions
    (test_id, topic_id, ord, kind, body, explanation, points)
  select t.id, tp.id, d.ord, 'single', d.body, d.why, 1
    from d
    join public.tests    t  on t.slug = d.test
    join public.subjects s  on s.id = t.subject_id
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  returning id, test_id, ord
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.body, o.ord = d.correct
  from ins
  join public.tests t on t.id = ins.test_id
  join d on d.test = t.slug and d.ord = ins.ord,
  lateral unnest(d.opts) with ordinality as o(body, ord);

-- ------------------------------------------------------------- hesabat
do $$
declare n_t int; n_q int; n_o int; bad text;
begin
  select count(*) into n_t from public.tests where owner_type = 'platform';
  select count(*) into n_q from public.questions q join public.tests t on t.id = q.test_id
   where t.owner_type = 'platform';
  select count(*) into n_o from public.question_options o
    join public.questions q on q.id = o.question_id
    join public.tests t on t.id = q.test_id where t.owner_type = 'platform';

  -- Her sualin DEQIQ bir duzgun cavabi olmalidir
  select string_agg(x.body, ' | ') into bad from (
    select q.body from public.questions q
      join public.tests t on t.id = q.test_id and t.owner_type = 'platform'
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
    join public.tests t on t.id = q.test_id and t.owner_type = 'platform'
   where q.topic_id is null;
  if bad <> '0' then
    raise exception '% sual movzuya baglanmayib', bad;
  end if;

  raise notice 'Platforma testleri: % test, % sual, % variant', n_t, n_q, n_o;
end $$;
