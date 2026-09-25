-- =====================================================================
--  muellim_veziyyet.sql : BIR MUELLIMIN veziyyeti - «olmur» deyende
--
--  Niye lazimdir: «testi gondermek olmur» sikayetine cavab yazmazdan
--  EVVEL onun hesabinda NE OLDUGUNU gormek lazimdir.  2026-09-24-de
--  eyni muellime «bazada test yoxdur» kimi metn gostermisdik ve metn
--  YALAN idi - sebebi yoxlamadan cavab yazmagin qiymeti budur.
--
--  ISTIFADE: asagidaki e-poctu deyis, Supabase SQL Editor-da isled.
-- =====================================================================
\set muellim '''jamilvalibayli@gmail.com'''

with m as (
  select u.id uid, u.email, u.last_sign_in_at,
         a.id acc, a.name hesab, a.type
    from auth.users u
    join public.accounts a on a.owner_id = u.id
   where u.email = :muellim
)
select 'hesab' as nə, m.hesab as ad,
       m.email as elave,
       to_char(m.last_sign_in_at at time zone 'Asia/Baku', 'DD.MM HH24:MI') as vaxt
  from m
union all
select 'qrup', c.name,
       (select count(*)::text || ' şagird' from public.students s where s.class_id = c.id),
       to_char(c.created_at at time zone 'Asia/Baku', 'DD.MM HH24:MI')
  from m join public.classes c on c.account_id = m.acc
union all
select 'test', t.title,
       (select count(*)::text || ' sual' from public.test_questions tq where tq.test_id = t.id)
         || ' · ' || t.status,
       to_char(t.created_at at time zone 'Asia/Baku', 'DD.MM HH24:MI')
  from m join public.tests t on t.owner_type = 'educator' and t.owner_id = m.uid
union all
select 'TAPSIRIQ', t.title,
       coalesce(c.name, '(silinmiş qrup)')
         || case when asg.student_id is not null then ' · yalnız bir şagird' else '' end,
       to_char(asg.created_at at time zone 'Asia/Baku', 'DD.MM HH24:MI')
  from m
  join public.assignments asg on asg.assigned_by = m.uid
  join public.tests t on t.id = asg.test_id
  left join public.classes c on c.id = asg.class_id
union all
select 'cehd', s.full_name, t.title || ' · ' || round(att.percent)::text || '%',
       to_char(att.finished_at at time zone 'Asia/Baku', 'DD.MM HH24:MI')
  from m
  join public.classes c on c.account_id = m.acc
  join public.students s on s.class_id = c.id
  join public.attempts att on att.student_id = s.id and att.status = 'submitted'
  join public.tests t on t.id = att.test_id
order by 1, 4 nulls first;
