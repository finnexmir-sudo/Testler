-- =====================================================================
--  termin_duzelt_izah.sql : IZAH SUTUNU (questions.explanation)
--
--  NIYE SABLON YOX, ADBAD SIYAHI?
--  Sual metnlerinde «çıxan» demek olar hemise TERMIN idi, ona gore
--  sablon isleyirdi.  IZAHLAR ise NESRDIR - orada «çıxan/çıxanda»
--  ekseren FEILDIR:
--      «Sıfır ÇIXANDA ədəd dəyişmir»        - feil
--      «Bir düz xətdən ÇIXAN yarımmüstəvi»  - feil
--      «Fərq + ÇIXAN = çıxılan olmalıdır»   - TERMIN
--  Sablonla ayirmaq alinmadi: «Çıxılan ədəddən ÇIXAN çıxılır» termindir,
--  «Başlanğıcdan ÇIXAN xətt» ise feil - eyni qelib, ferqli mena.
--  28 setrin hamisi el ile oxundu; asagida YALNIZ 16 termin hali var.
--  Qalan 12-si (feil) toxunulmur.
--
--  Evezleme eynidir:  çıxılan -> azalan,  sonra  çıxan -> çıxılan.
--
--  ISTIFADE: onbaxisi isled, setirlere bax, sonra asagidaki UPDATE-in
--  serhini ac.  Tekrar isledile biler.
-- =====================================================================
with hedef as (
  select unnest(array[
    '1a373346-a1db-40dd-ae0e-a2f4c52cdf65',
    'a82186ec-0008-4ff0-8d0f-dd55bb014003',
    'dbb585c3-016e-47ac-9f99-34c267423310',
    '1de0092f-e66b-4b53-9a7d-c3a636e0eac6',
    '623a6335-9fdb-4e93-ba2d-6f55066a8432',
    '85bfb9f8-da7f-4784-b31c-fbb9734483fe',
    '9a34a7f9-2999-4960-af5c-3a68b637bd2a',
    'b6dc806c-b055-4051-81ad-33cf312b4b38',
    '7f4c2d0e-1c5e-4dd9-b6c8-a593f3b679d9',
    '00191175-9cda-4875-92be-42380a33deb2',
    '98bd0ec8-ed7e-40ea-bf2e-71c19571bb74',
    'f3f6c7bd-e6d9-4446-a0bb-a14e6afb7e5b',
    'f447e599-2cc0-4cde-af53-b586f10492a5',
    'affc5668-7498-46a5-9e91-d975b22a7b3f',
    'c75209af-d146-4f5b-b2af-2222b3ded857',
    '13eb60aa-619d-45d1-8857-ddc76a3d85c0'
  ]::uuid[]) as id
),
secim as (
  select q.id, q.explanation as izah,
         replace(replace(replace(replace(
           q.explanation, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
                 'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan') as yeni
    from public.questions q
   where q.id in (select id from hedef)
)
select '0-YOXLAMA' as ne,
       (select count(*) from secim where izah <> yeni)::text || ' izah dəyişəcək' as evvel,
       '16 gözlənilir — az olsa, bir hissəsi artıq düzəlib' as sonra,
       null::uuid as id
union all
select 'izah', izah, yeni, id from secim where izah <> yeni
order by ne, evvel;

--  ---------- DUZELIS ----------
/*
with hedef as (
  select unnest(array[
    '1a373346-a1db-40dd-ae0e-a2f4c52cdf65','a82186ec-0008-4ff0-8d0f-dd55bb014003',
    'dbb585c3-016e-47ac-9f99-34c267423310','1de0092f-e66b-4b53-9a7d-c3a636e0eac6',
    '623a6335-9fdb-4e93-ba2d-6f55066a8432','85bfb9f8-da7f-4784-b31c-fbb9734483fe',
    '9a34a7f9-2999-4960-af5c-3a68b637bd2a','b6dc806c-b055-4051-81ad-33cf312b4b38',
    '7f4c2d0e-1c5e-4dd9-b6c8-a593f3b679d9','00191175-9cda-4875-92be-42380a33deb2',
    '98bd0ec8-ed7e-40ea-bf2e-71c19571bb74','f3f6c7bd-e6d9-4446-a0bb-a14e6afb7e5b',
    'f447e599-2cc0-4cde-af53-b586f10492a5','affc5668-7498-46a5-9e91-d975b22a7b3f',
    'c75209af-d146-4f5b-b2af-2222b3ded857','13eb60aa-619d-45d1-8857-ddc76a3d85c0'
  ]::uuid[]) as id
)
update public.questions q
   set explanation = replace(replace(replace(replace(
         q.explanation, 'Çıxılan', 'Azalan'), 'çıxılan', 'azalan'),
               'Çıxan',   'Çıxılan'), 'çıxan',   'çıxılan'),
       updated_at = now()
 where q.id in (select id from hedef);
*/
