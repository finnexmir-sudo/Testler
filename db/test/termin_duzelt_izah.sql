-- =====================================================================
--  termin_duzelt_izah.sql : IZAH SUTUNU (questions.explanation)
--
--  termin_duzelt.sql yalniz SUAL METNINI ve VARIANTLARI duzeltdi -
--  «explanation» sutununu unutmusam.  Istifadeci panelde gordu:
--     sual:  «Azalan 600, fərq 250-dirsə, çıxılan neçədir?»   (duz)
--     izah:  «Çıxan = çıxılan − fərq = 600 − 250 = 350.»       (kohne)
--
--  Qayda eynidir:  çıxılan -> azalan,  sonra  çıxan -> çıxılan.
--  Hemin ucluk yuxaridaki faylda izah olunub.
--
--  ISTIFADE: bir sorgudur, BIR netice verir.
--    Birinci setir hokm: «N izah seçilib».
--    Setirlere bax, beyensen asagidaki UPDATE-in serhini ac ve isled.
-- =====================================================================
with hedef as (
  select q.id, q.body, coalesce(q.explanation, '') as izah
    from public.questions q
    join public.subjects s on s.id = q.subject_id
   where s.slug = 'riyaziyyat' and q.status <> 'archived'
),
istisna as (
  select unnest(array[
    '4b2274ba-8669-4d88-add4-3267903c0e69',   -- «S nöqtəsindən çıxan iki şüa»
    '9d8fe6ac-cdca-4d89-b494-c88cbaf09d82',   -- «teoremdən çıxan nəticə»
    '28561de0-8b68-4c8a-ac50-18903c616050'    -- «Sıfırı çıxanda ədəd dəyişmir»
  ]::uuid[]) as id
),
secim as (
  select id, body, izah,
         replace(replace(replace(replace(
           izah, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
                 'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan') as yeni
    from hedef
   where (izah ~ '[Çç][ıi]xan'
      or (izah ~* '[Çç][ıi]x[ıi]lan' and izah ~* 'f[əe]rq' and izah !~* 'azalan'))
     and id not in (select id from istisna)
)
select '0-YOXLAMA' as ne,
       (select count(*) from secim where izah <> yeni)::text || ' izah seçilib' as evvel,
       'sual mətni ARTIQ düzdür — burada yalnız izah' as sonra,
       null::uuid as id
union all
select 'izah', izah, yeni, id from secim where izah <> yeni
order by ne, evvel;

--  ---------- DUZELIS ----------
/*
with hedef as (
  select q.id, coalesce(q.explanation, '') as izah
    from public.questions q
    join public.subjects s on s.id = q.subject_id
   where s.slug = 'riyaziyyat' and q.status <> 'archived'
),
istisna as (
  select unnest(array[
    '4b2274ba-8669-4d88-add4-3267903c0e69',
    '9d8fe6ac-cdca-4d89-b494-c88cbaf09d82',
    '28561de0-8b68-4c8a-ac50-18903c616050'
  ]::uuid[]) as id
),
secim as (
  select id from hedef
   where (izah ~ '[Çç][ıi]xan'
      or (izah ~* '[Çç][ıi]x[ıi]lan' and izah ~* 'f[əe]rq' and izah !~* 'azalan'))
     and id not in (select id from istisna)
)
update public.questions q
   set explanation = replace(replace(replace(replace(
         q.explanation, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'),
       updated_at = now()
 where q.id in (select id from secim);
*/
