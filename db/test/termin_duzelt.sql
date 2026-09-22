-- =====================================================================
--  termin_duzelt.sql : CIXMA TERMINLERININ DUZELISI
--
--  TAPINTI (2026-09-22, termin_yoxla.sql + el ile yoxlama)
--  Bankdaki cixma suallarinda terminler BIR PILLE SURUSUB:
--       bank yazir        duzgunu
--       ----------        --------
--       cixilan     ->    AZALAN      (azalan - cixilan = ferq)
--       cixan       ->    CIXILAN     («cıxan» ise termin deyil;
--                                      turkcedeki «çıkan»dan gelib)
--
--  ONEMLI: HESABLAR DUZDUR.  On bir sualin hamisinda isarelenmis cavab
--  bankin OZ adlandirmasi ile uygun gelir (9-2=7, 600-250=350, ...).
--  Yeni ise YALNIZ ADLARI duzeltmekdir - reqemlere, variantlara ve
--  duz cavaba TOXUNULMUR.  Ona gore evezleme tehlukesizdir.
--
--  NECE ISLEYIR
--    1) evvelce «çıxılan» -> «azalan»
--    2) sonra  «çıxan»    -> «çıxılan»
--  Sira vacibdir.  Kok evez olunur, sonluqlar oz yerinde qalir:
--    «Çıxılanla» -> «Azalanla»,  «çıxılana» -> «azalana»,
--    «Çıxan»     -> «Çıxılan»,   «çıxanı»   -> «çıxılanı».
--
--  ISTIFADE - IKI ADDIM
--    ADDIM 1: Asagidaki SELECT-i isled, «evvel / sonra» sutunlarini OXU.
--             Deyismemeli olan setir gorsen, DAYAN ve xebar ver.
--    ADDIM 2: Beyendinse, faylin sonundaki UPDATE bloklarinin serhini
--             ac (/* */ isaretlerini sil) ve onlari isled.
--
--  TEKRAR ISLEDILE BILER: duzelisden sonra suzgec hec ne tapmir
--  («çıxan» qalmir, «azalan» ise artiq var) - ikinci defe surusme olmur.
-- =====================================================================

--  ---------- ADDIM 1: ONBAXIS + TOQQUSMA YOXLAMASI ----------
--  BIR sorgudur, BIR netice cedveli verir.
--
--  NIYE BIR YERDE?  Supabase SQL Editor yalniz SONUNCU sorgunun
--  neticesini gosterir.  Ayri-ayri yazanda birincinin cavabi
--  sessizce udulurdu - istifadeci toqqusma yoxlamasini hec gormedi.
--
--  Neticenin BIRINCI setri «0-YOXLAMA»-dir:
--    «toqquşma yoxdur»  -> davam et
--    «N TOQQUŞMA VAR»    -> DAYAN, asagidaki «toqqusma» setirlerine bax
--
--  Toqqusma nedir: sualda hem «Azalan», hem «Çıxılan» variantı varsa,
--  «Çıxılan» -> «Azalan» olur ve IKI EYNI variant yaranir.  «Azalan»
--  deyismediyi ucun adi onbaxisda gorunmur - ona gore ayrica sayilir.
with hedef as (
  select q.id, q.body,
         coalesce((select string_agg(o.body, ' ') from public.question_options o
                    where o.question_id = q.id), '') as opt
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
  select id, body from hedef
   where ((body || ' ' || opt) ~ '[Çç][ıi]xan'
      or ((body || ' ' || opt) ~* '[Çç][ıi]x[ıi]lan'
          and (body || ' ' || opt) ~* 'f[əe]rq'
          and (body || ' ' || opt) !~* 'azalan'))
     and id not in (select id from istisna)
),
--  kok evezlemesi: evvel cixilan -> azalan, SONRA cixan -> cixilan
toqq as (
  select o.question_id,
         count(distinct o.body) as indi,
         count(distinct replace(replace(replace(replace(
           o.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
                 'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan')) as sonra
    from public.question_options o
   where o.question_id in (select id from secim)
   group by o.question_id
  having count(distinct o.body) > count(distinct replace(replace(replace(replace(
           o.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
                 'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'))
)
select '0-YOXLAMA' as ne,
       case when (select count(*) from toqq) = 0
            then 'toqquşma yoxdur — davam et'
            else (select count(*) from toqq)::text || ' TOQQUŞMA VAR — DAYAN' end as evvel,
       (select count(*) from secim)::text || ' sual seçilib' as sonra,
       null::uuid as id
union all
select 'toqqusma', 'variantlar birləşir: ' || t.indi::text || ' → ' || t.sonra::text,
       (select body from public.questions where id = t.question_id), t.question_id
  from toqq t
union all
select 'sual', body,
       replace(replace(replace(replace(
         body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'), id
  from secim
 where body <> replace(replace(replace(replace(
         body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan')
union all
select 'variant', o.body,
       replace(replace(replace(replace(
         o.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'),
       o.question_id
  from public.question_options o
 where o.question_id in (select id from secim)
   and o.body <> replace(replace(replace(replace(
         o.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan')
order by ne, evvel;


--  ---------- ADDIM 2: DUZELIS ----------
--  Onbaxisi beyendinse, asagidaki iki blokun serhini ac ve isled.
--  Sira: EVVEL variantlar, SONRA suallar (secim sualin metnine baxir -
--  sual duzelse, variantlar suzgecden kenarda qalardi).
/*
with hedef as (
  select q.id, q.body,
         coalesce((select string_agg(o.body, ' ') from public.question_options o
                    where o.question_id = q.id), '') as opt
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
   where ((body || ' ' || opt) ~ '[Çç][ıi]xan'
      or ((body || ' ' || opt) ~* '[Çç][ıi]x[ıi]lan'
          and (body || ' ' || opt) ~* 'f[əe]rq'
          and (body || ' ' || opt) !~* 'azalan'))
     and id not in (select id from istisna)
)
update public.question_options o
   set body = replace(replace(replace(replace(
         o.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan')
 where o.question_id in (select id from secim);

with hedef as (
  select q.id, q.body,
         coalesce((select string_agg(o.body, ' ') from public.question_options o
                    where o.question_id = q.id), '') as opt
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
   where ((body || ' ' || opt) ~ '[Çç][ıi]xan'
      or ((body || ' ' || opt) ~* '[Çç][ıi]x[ıi]lan'
          and (body || ' ' || opt) ~* 'f[əe]rq'
          and (body || ' ' || opt) !~* 'azalan'))
     and id not in (select id from istisna)
)
update public.questions q
   set body = replace(replace(replace(replace(
         q.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'),
       updated_at = now()
 where q.id in (select id from secim);
*/
