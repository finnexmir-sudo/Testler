-- =====================================================================
--  bayraq_yoxla.sql : duz cavab bayragi SEHV variantdadirmi?  (yalniz oxuyur)
--
--  Niye var: db/242-de emit sehvi ile 108 sualin HAMISINDA 2-ci (yanlis)
--  variant duz kimi isarelenmisdi.  Ozunuyoxlama («tam 1 duz variant»),
--  dublikat, balans, tam smoke suite - hamisi YASIL idi.  Hec biri
--  «bayraq DUZ cavabdadirmi?» sorusmurdu: quruluşu olcurduler, mezmunu yox.
--  Tutan, push-dan evvel 3 suali [duz] formasinda oxumaq oldu.
--
--  Bu skript hemin sualı butun banka verir.  Hec ne DEYISMIR.  Canli
--  Supabase SQL Editor-da da isleyir (muveqqeti cedvel yoxdur, yalniz CTE).
--
--  UC ekran:
--   B  242 IMZASI - bir movzuda duz cavab HEMISE eyni qeyri-1 sirada.
--      Generatorlar duz cavabi 1-ci qoyur ve ya qarisdirir; «hemise 2-ci»
--      sistematik emit sehvidir.  GOZLENILEN: 0 setir.
--   C1 EDEDI - izahin SON reqemi hansi variantla ust-uste dusur?  SUBHELI =
--      basqa bir variantla dusur, bayraqli ile YOX.
--   C2 METN - bayraqli variantin metni izahda YOXDUR, basqa variantin VAR.
--
--  YALANCI SIQNALLAR (2026-09-12-de 22 255 sual uzre 170 siqnal oxundu,
--  0 heqiqi sehv):
--   * «hansi SEHVDIR / DEYIL?» qelibi - bayraq yanlis mulahizededir, izah
--     duz fakti deyir.  Sual metnine bax: sehvi sorusursa bayraq DUZDUR.
--   * izahin son reqemi ara deyer/distraktordur («407 = 4 yuzluk, 0 onluq,
--     7 teklik» -> cavab 0; «(900+100):2=500; kicik 400» -> sual boyuyu
--     sorusur).  Formul cavablarinda (π/2, √3/3) reqem-suzgec herfi atir.
--  Yeni siqnal cixanda: sual metnini oxu, sonra qerar ver.  Sayin ozu
--  («147 subheli») hec ne demir.
--
--  Hedd: yalniz izahin cavabi adlandirdigi suallara baxir; agentin SECDIYI
--  variant ucun yazdigi izah sehvi gizleder.  Canlida esl hakim
--  question_stats.acar siqnalidir (db/134): distraktor duzden cox
--  secilende, >=20 cavabdan sonra.
-- =====================================================================

-- ---------- A) quruluş (her sualda tam 1 duz, 4 variant) - gozlenilen 0 | 0
select 'A quruluş' as ekran,
       count(*) filter (where nc <> 1) as duz_sayi_1_olmayan,
       count(*) filter (where no <> 4) as variant_4_olmayan
  from (select q.id, count(o.*) filter (where o.is_correct) nc, count(o.*) no
          from public.questions q left join public.question_options o on o.question_id = q.id
         where q.owner_type = 'platform' group by q.id) s;

-- ---------- B) 242 imzasi - gozlenilen: 0 setir
with c as (
  select t.slug, o.ord, count(*) n
    from public.questions q
    join public.topics t on t.id = q.topic_id
    join public.question_options o on o.question_id = q.id and o.is_correct
   where q.owner_type = 'platform'
   group by t.slug, o.ord),
tot as (select slug, sum(n) n from c group by slug)
select 'B imza' as ekran, c.slug as movzu, c.ord as hemise_bu_sirada, c.n as sual
  from c join tot using (slug)
 where c.n = tot.n and tot.n >= 10 and c.ord <> 1
 order by c.n desc;

-- ---------- C1) ededi: say
with q as (
  select q.id, q.ext_key, s.slug subj, q.explanation,
         replace((regexp_match(q.explanation, '(-?\d+(?:[.,]\d+)?)\D*$'))[1], ',', '.') as son_reqem
    from public.questions q join public.subjects s on s.id = q.subject_id
   where q.owner_type = 'platform' and q.kind = 'single'),
o as (
  select o.question_id, o.ord, o.is_correct, o.body,
         regexp_replace(replace(lower(o.body), ',', '.'), '[^0-9.\-/]', '', 'g') as norm
    from public.question_options o),
j as (
  select q.ext_key, q.subj,
         bool_or(o.is_correct and o.norm = q.son_reqem) as bayraq_uygun,
         bool_or((not o.is_correct) and o.norm = q.son_reqem and o.norm <> '') as basqa_uygun
    from q join o on o.question_id = q.id
   where q.son_reqem is not null
   group by q.ext_key, q.subj)
select 'C1 ededi' as ekran,
       count(*) as yoxlanan,
       count(*) filter (where bayraq_uygun) as bayraq_uygun,
       count(*) filter (where basqa_uygun and not bayraq_uygun) as subheli,
       count(*) filter (where not bayraq_uygun and not basqa_uygun) as neytral
  from j;

-- ---------- C1) ededi: subheli setirler ([duz] formasinda - GOZLE OXU)
with q as (
  select q.id, q.ext_key, s.slug subj, q.body, q.explanation,
         replace((regexp_match(q.explanation, '(-?\d+(?:[.,]\d+)?)\D*$'))[1], ',', '.') as son_reqem
    from public.questions q join public.subjects s on s.id = q.subject_id
   where q.owner_type = 'platform' and q.kind = 'single'),
o as (
  select o.question_id, o.ord, o.is_correct, o.body,
         regexp_replace(replace(lower(o.body), ',', '.'), '[^0-9.\-/]', '', 'g') as norm
    from public.question_options o),
j as (
  select q.ext_key, q.subj, left(q.body, 70) sual, left(q.explanation, 70) izah,
         bool_or(o.is_correct and o.norm = q.son_reqem) as bayraq_uygun,
         bool_or((not o.is_correct) and o.norm = q.son_reqem and o.norm <> '') as basqa_uygun,
         string_agg(case when o.is_correct then '[' || o.body || ']' else o.body end, ' | ' order by o.ord) as variantlar
    from q join o on o.question_id = q.id
   where q.son_reqem is not null
   group by q.ext_key, q.subj, q.body, q.explanation)
select 'C1 subheli' as ekran, ext_key, sual, variantlar, izah
  from j where basqa_uygun and not bayraq_uygun
 order by subj, ext_key;

-- ---------- C2) metn: say
with o as (
  select o.question_id, o.is_correct, o.body, lower(trim(o.body)) lb from public.question_options o),
j as (
  select q.ext_key, s.slug subj,
         bool_or(o.is_correct and position(o.lb in lower(q.explanation)) > 0) as bayraq_izahda,
         bool_or((not o.is_correct) and length(o.lb) >= 4 and position(o.lb in lower(q.explanation)) > 0) as basqa_izahda
    from public.questions q join public.subjects s on s.id = q.subject_id
    join o on o.question_id = q.id
   where q.owner_type = 'platform' and q.kind = 'single'
     and q.explanation !~ '\d\D*$'          -- C1-in ortmediyi: izah reqemle bitmir
   group by q.ext_key, s.slug, q.explanation)
select 'C2 metn' as ekran,
       count(*) as yoxlanan,
       count(*) filter (where bayraq_izahda) as bayraq_izahda,
       count(*) filter (where basqa_izahda and not bayraq_izahda) as subheli,
       count(*) filter (where not bayraq_izahda and not basqa_izahda) as neytral
  from j;

-- ---------- C2) metn: subheli setirler
with o as (
  select o.question_id, o.ord, o.is_correct, o.body, lower(trim(o.body)) lb from public.question_options o),
j as (
  select q.ext_key, s.slug subj, left(q.body, 70) sual, left(q.explanation, 70) izah,
         bool_or(o.is_correct and position(o.lb in lower(q.explanation)) > 0) as bayraq_izahda,
         bool_or((not o.is_correct) and length(o.lb) >= 4 and position(o.lb in lower(q.explanation)) > 0) as basqa_izahda,
         string_agg(case when o.is_correct then '[' || o.body || ']' else o.body end, ' | ' order by o.ord) as variantlar
    from public.questions q join public.subjects s on s.id = q.subject_id
    join o on o.question_id = q.id
   where q.owner_type = 'platform' and q.kind = 'single'
     and q.explanation !~ '\d\D*$'
   group by q.ext_key, s.slug, q.body, q.explanation)
select 'C2 subheli' as ekran, ext_key, sual, variantlar, izah
  from j where basqa_izahda and not bayraq_izahda
 order by subj, ext_key;
