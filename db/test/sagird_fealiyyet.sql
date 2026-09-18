-- =====================================================================
--  sagird_fealiyyet.sql : BIR MUELLIMIN sagirdleri ne edir - AD-AD
--
--  NIYE
--  «190 sual islenib» kimi ceml reqem casdiricidir: bir usaq 180,
--  qalan yeddisi 0 ede biler - ceml eyni gorunur.  Muellim ucun
--  faydali olan ceml deyil, BOLGUDUR: kim isleyir, kim yox.
--
--  Sutunlar:
--    mesq     - movzu mesqi cavablari (practice.answered)
--    test     - bitirilmis test cehdi (attempts, submitted)
--    sual     - hemin testlerde cavabladigi SUAL sayi
--    bagli    - defterde baglanan sehv (closed)
--    tekrarda - defterde tekrar gozleyen (review)
--    gun      - nece AYRI gunde isleyib  (bir gunluk partlayis mi,
--               yoxsa davamli isdir?)
--    son      - en son fealiyyet
--
--  ISTIFADE: asagidaki E-POCTU DEYIS, Supabase SQL Editor-da isled.
-- =====================================================================
with muellim as (
  select 'teraneimanli68@gmail.com'::text as email      --  <<< BURANI DEYIS
),
acc as (
  select a.id from public.accounts a
    join auth.users u on u.id = a.owner_id
    join muellim m on lower(u.email) = lower(m.email)
   where not a.is_demo
   limit 1
),
stu as (
  select s.id, s.display_name, s.is_active, c.name as qrup
    from public.students s
    join acc on s.account_id = acc.id
    left join public.classes c on c.id = s.class_id
)
select
  stu.display_name                                        as sagird,
  stu.qrup,
  coalesce((select sum(p.answered) from public.practice p
             where p.student_id = stu.id), 0)             as mesq,
  (select count(*) from public.attempts a
    where a.student_id = stu.id and a.status = 'submitted') as test,
  (select count(*) from public.attempt_answers aa
     join public.attempts a on a.id = aa.attempt_id
    where a.student_id = stu.id and a.status = 'submitted') as sual,
  (select count(*) from public.mistakes m
    where m.student_id = stu.id and m.status = 'closed')  as bagli,
  (select count(*) from public.mistakes m
    where m.student_id = stu.id and m.status = 'review')  as tekrarda,
  --  nece AYRI gunde fealiyyet olub (Baki gunu)
  (select count(distinct d) from (
      select (a.finished_at at time zone 'Asia/Baku')::date d
        from public.attempts a
       where a.student_id = stu.id and a.status = 'submitted'
      union
      select (p.updated_at at time zone 'Asia/Baku')::date
        from public.practice p where p.student_id = stu.id and p.answered > 0
      union
      select (m.last_at at time zone 'Asia/Baku')::date
        from public.mistakes m where m.student_id = stu.id and m.status <> 'open'
   ) z)                                                    as gun,
  greatest(
    (select max(a.finished_at) from public.attempts a
      where a.student_id = stu.id and a.status = 'submitted'),
    (select max(p.updated_at) from public.practice p
      where p.student_id = stu.id and p.answered > 0),
    (select max(ss.created_at) from public.student_sessions ss
      where ss.student_id = stu.id))                       as son
from stu
order by mesq desc, test desc, stu.display_name;
