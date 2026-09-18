-- =====================================================================
--  muellim_istifade_qisa.sql : eyni sorgu, AMMA IKI SETIR
--
--  Telefonda 21 setri ekran sekline salmaq cetindir.  Bu variant
--  «islədir» ve «islətmir» siyahilarini iki setirde verir.
--
--  NIYE
--  Yeni muellim qeydiyyatdan kecir, bir-iki seyi tapir, qalanini hec
--  vaxt gormur.  Huni «nece nefer qaldi» deyir, bu sorgu ise «hemin
--  adam NEYI ISLETMIR» deyir - ona nə yazacagimizi bilek.
--
--  ISTIFADE:  asagidaki E-POCTU DEYIS, Supabase SQL Editor-da isled.
--  Netice: iki setir - ISLEDIR / ISLETMIR.  Tam siyahi (say ve tarix
--  ile) muellim_istifade.sql-dedir.
--
--  DIQQET: psql-in «\set» emri Supabase SQL Editor-da ISLEMIR, ona gore
--  e-poct asagida DUZ metnle yazilib.  Yalniz orani deyismek lazimdir.
-- =====================================================================
with muellim as (
  select 'teraneimanli68@gmail.com'::text as email      --  <<< BURANI DEYIS
),
acc as (
  select a.id, a.name, a.owner_id, a.created_at
    from public.accounts a
    join auth.users u on u.id = a.owner_id
    join muellim m on lower(u.email) = lower(m.email)
   where not a.is_demo
   limit 1
),
cls as (select c.id from public.classes c join acc on c.account_id = acc.id),
stu as (select s.id from public.students s join acc on s.account_id = acc.id),
tst as (select t.* from public.tests t join acc on t.owner_id = acc.owner_id
         where t.owner_type = 'educator'),
sayim as (
  select * from (values

 ('1 · Qrup',
  (select count(*) from cls),
  (select max(c.created_at) from public.classes c join acc on c.account_id = acc.id)),

 ('2 · Şagird',
  (select count(*) from stu),
  (select max(s.created_at) from public.students s join acc on s.account_id = acc.id)),

 ('3 · Şagird tətbiqinə girib',
  (select count(distinct ss.student_id) from public.student_sessions ss
    join stu on stu.id = ss.student_id),
  (select max(ss.created_at) from public.student_sessions ss
    join stu on stu.id = ss.student_id)),

 ('4 · Test yığıb',
  (select count(*) from tst),
  (select max(created_at) from tst)),

 ('5 · Tapşırıq verib',
  (select count(*) from public.assignments asg join cls on cls.id = asg.class_id),
  (select max(asg.created_at) from public.assignments asg join cls on cls.id = asg.class_id)),

 ('6 · Şagird cavabı gəlib',
  (select count(*) from public.attempts at join stu on stu.id = at.student_id
    where at.status = 'submitted'),
  (select max(at.finished_at) from public.attempts at join stu on stu.id = at.student_id
    where at.status = 'submitted')),

 ('7 · DƏRS PLANI qurub',
  (select count(*) from public.class_plans cp join cls on cls.id = cp.class_id),
  (select max(cp.created_at) from public.class_plans cp join cls on cls.id = cp.class_id)),

 ('8 · Dərsi «Keçildi» işarələyib',
  (select count(*) from public.class_plan_items i
     join public.class_plans cp on cp.id = i.plan_id join cls on cls.id = cp.class_id
    where i.done_at is not null),
  (select max(i.done_at) from public.class_plan_items i
     join public.class_plans cp on cp.id = i.plan_id join cls on cls.id = cp.class_id)),

 ('9 · Diaqnostika testi',
  (select count(*) from tst where is_diagnostic),
  (select max(created_at) from tst where is_diagnostic)),

 ('10 · Düzəliş testi',
  (select count(*) from tst where is_remedial),
  (select max(created_at) from tst where is_remedial)),

 ('11 · Ev tapşırığı (mətnlə)',
  (select count(*) from public.homework h join cls on cls.id = h.class_id),
  (select max(h.created_at) from public.homework h join cls on cls.id = h.class_id)),

 ('12 · Davamiyyət',
  (select count(*) from public.lessons l join cls on cls.id = l.class_id),
  (select max(l.created_at) from public.lessons l join cls on cls.id = l.class_id)),

 ('13 · Ödəniş qeydi',
  (select count(*) from public.fee_payments fp join stu on stu.id = fp.student_id),
  (select max(fp.updated_at) from public.fee_payments fp join stu on stu.id = fp.student_id)),

 ('14 · Dərs cədvəli',
  (select count(*) from public.class_schedule cs join cls on cls.id = cs.class_id),
  null::timestamptz),

 ('15 · Fərdi plan (şagirdə)',
  (select count(*) from public.student_plans sp join stu on stu.id = sp.student_id),
  (select max(sp.created_at) from public.student_plans sp join stu on stu.id = sp.student_id)),

 ('16 · VALİDEYN girib',
  (select count(distinct ps.student_id) from public.parent_sessions ps
    join stu on stu.id = ps.student_id),
  (select max(ps.created_at) from public.parent_sessions ps join stu on stu.id = ps.student_id)),

 ('17 · Öz sualını yazıb',
  (select count(*) from public.questions q join acc on q.account_id = acc.id),
  (select max(q.created_at) from public.questions q join acc on q.account_id = acc.id)),

 ('18 · Şagird MÖVZU MƏŞQİ edib',
  (select coalesce(sum(p.answered), 0) from public.practice p join stu on stu.id = p.student_id),
  (select max(p.updated_at) from public.practice p join stu on stu.id = p.student_id)),

 ('19 · Şagird SƏHV DƏFTƏRİ işlədib',
  (select count(*) from public.mistakes m join stu on stu.id = m.student_id
    where m.status <> 'open'),
  (select max(m.last_at) from public.mistakes m join stu on stu.id = m.student_id
    where m.status <> 'open')),

 ('20 · Şagird GÜNDƏLİK TƏKRAR edib',
  (select count(*) from public.daily_packs d join stu on stu.id = d.student_id
    where jsonb_array_length(d.answers) > 0),
  (select max(d.created_at) from public.daily_packs d join stu on stu.id = d.student_id
    where jsonb_array_length(d.answers) > 0)),

 ('21 · «Bizə yaz» yazıb',
  (select count(*) from public.feedback f, acc
    where f.account_id = acc.id or f.user_id = acc.owner_id
       or f.student_id in (select id from stu)),
  (select max(f.created_at) from public.feedback f, acc
    where f.account_id = acc.id or f.user_id = acc.owner_id
       or f.student_id in (select id from stu)))

  ) as t(imkan, say, son_defe)
)
select 'ISLƏDİR' as hal,
       string_agg(split_part(imkan, ' · ', 2), ' · '
                  order by split_part(imkan, ' · ', 1)::int) as imkanlar
  from sayim where say > 0
union all
select 'İŞLƏTMİR',
       string_agg(split_part(imkan, ' · ', 2), ' · '
                  order by split_part(imkan, ' · ', 1)::int)
  from sayim where say = 0;
