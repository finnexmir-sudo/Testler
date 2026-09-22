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

--  ---------- ADDIM 1: ONBAXIS (hec ne deyismir) ----------
with hedef as (
  select q.id, q.body,
         --  suala aid variantlarin metni de yoxlanilir: qusur bezen
         --  yalniz cavabda olur («fərq çıxılana bərabərdir»)
         coalesce((select string_agg(o.body, ' ') from public.question_options o
                    where o.question_id = q.id), '') as opt
    from public.questions q
    join public.subjects s on s.id = q.subject_id
   where s.slug = 'riyaziyyat'
     and q.status <> 'archived'
),
secim as (
  select id, body from hedef
   where (body || ' ' || opt) ~ '[Çç][ıi]xan'
      or ((body || ' ' || opt) ~* '[Çç][ıi]x[ıi]lan'
          and (body || ' ' || opt) ~* 'f[əe]rq'
          and (body || ' ' || opt) !~* 'azalan')
),
--  kok evezlemesi: evvel cixilan -> azalan, SONRA cixan -> cixilan
duz as (
  select id, body as evvel,
         replace(replace(replace(replace(
           body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
                 'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan') as sonra
    from secim
)
select 'sual' as ne, evvel, sonra, id from duz where evvel <> sonra
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
secim as (
  select id from hedef
   where (body || ' ' || opt) ~ '[Çç][ıi]xan'
      or ((body || ' ' || opt) ~* '[Çç][ıi]x[ıi]lan'
          and (body || ' ' || opt) ~* 'f[əe]rq'
          and (body || ' ' || opt) !~* 'azalan')
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
secim as (
  select id from hedef
   where (body || ' ' || opt) ~ '[Çç][ıi]xan'
      or ((body || ' ' || opt) ~* '[Çç][ıi]x[ıi]lan'
          and (body || ' ' || opt) ~* 'f[əe]rq'
          and (body || ' ' || opt) !~* 'azalan')
)
update public.questions q
   set body = replace(replace(replace(replace(
         q.body, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'),
       updated_at = now()
 where q.id in (select id from secim);
*/
