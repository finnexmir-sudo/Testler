-- =====================================================================
--  04_seed.sql : baslangic kataloqu
--  Tekrar isledile biler (on conflict do nothing / update).
-- =====================================================================

insert into public.programs (slug, name, sort) values
  ('ibtidai',       'İbtidai siniflər (1-4)',        10),
  ('orta',          'Orta məktəb (5-8)',             20),
  ('buraxilis',     'Buraxılış imtahanı (9-11)',     30),
  ('miq',           'MİQ - müəllimlərin işə qəbulu', 40),
  ('sertifikasiya', 'Müəllim sertifikasiyası',       50)
on conflict (slug) do update set name = excluded.name, sort = excluded.sort;

insert into public.subjects (slug, name, sort) values
  ('riyaziyyat',   'Riyaziyyat',       10),
  ('az-dili',      'Azərbaycan dili',  20),
  ('ingilis-dili', 'İngilis dili',     30),
  ('hayat-bilgisi','Həyat bilgisi',    40),
  ('informatika',  'İnformatika',      50),
  ('fizika',       'Fizika',           60),
  ('kimya',        'Kimya',            70),
  ('biologiya',    'Biologiya',        80),
  ('tarix',        'Tarix',            90),
  ('cografiya',    'Coğrafiya',       100),
  ('kurikulum',    'Kurikulum',       110)
on conflict (slug) do update set name = excluded.name, sort = excluded.sort;

-- Azerbaycanca sira sayi sekilcisi sait ahengine gore deyisir:
-- 1-ci · 2-ci · 3-cü · 4-cü · 5-ci · 6-cı · 7-ci · 8-ci · 9-cu · 10-cu · 11-ci
create or replace function app.ordinal_az(n int) returns text
language sql immutable as $$
  select n::text || case n
    when 1 then '-ci' when 2 then '-ci' when 3 then '-cü' when 4 then '-cü'
    when 5 then '-ci' when 6 then '-cı' when 7 then '-ci' when 8 then '-ci'
    when 9 then '-cu' when 10 then '-cu' when 11 then '-ci'
    else '-ci' end
$$;

-- Ibtidai: 1-4 sinif
insert into public.levels (program_id, code, name, sort)
select p.id, g::text, app.ordinal_az(g) || ' sinif', g * 10
  from public.programs p, generate_series(1, 4) g
 where p.slug = 'ibtidai'
on conflict (program_id, code) do nothing;

-- Orta: 5-8
insert into public.levels (program_id, code, name, sort)
select p.id, g::text, app.ordinal_az(g) || ' sinif', g * 10
  from public.programs p, generate_series(5, 8) g
 where p.slug = 'orta'
on conflict (program_id, code) do nothing;

-- Buraxilis: 9-11
insert into public.levels (program_id, code, name, sort)
select p.id, g::text, app.ordinal_az(g) || ' sinif', g * 10
  from public.programs p, generate_series(9, 11) g
 where p.slug = 'buraxilis'
on conflict (program_id, code) do nothing;

-- MIQ ve sertifikasiya: sinif yox, ixtisas pilleleri
insert into public.levels (program_id, code, name, sort)
select p.id, v.code, v.name, v.sort
  from public.programs p,
       (values ('ibtidai-muellimi','İbtidai sinif müəllimi',10),
               ('riyaziyyat',      'Riyaziyyat müəllimi',   20),
               ('az-dili',         'Azərbaycan dili müəllimi',30),
               ('ingilis-dili',    'İngilis dili müəllimi', 40)) as v(code,name,sort)
 where p.slug in ('miq','sertifikasiya')
on conflict (program_id, code) do nothing;

-- Hansi fenn hansi programda var
insert into public.program_subjects (program_id, subject_id)
select p.id, s.id from public.programs p, public.subjects s
 where (p.slug = 'ibtidai'  and s.slug in ('riyaziyyat','az-dili','ingilis-dili','hayat-bilgisi'))
    or (p.slug = 'orta'     and s.slug in ('riyaziyyat','az-dili','ingilis-dili','informatika','fizika','kimya','biologiya','tarix','cografiya'))
    or (p.slug = 'buraxilis'and s.slug in ('riyaziyyat','az-dili','ingilis-dili','fizika','kimya','biologiya','tarix','cografiya','informatika'))
    or (p.slug in ('miq','sertifikasiya') and s.slug in ('kurikulum','riyaziyyat','az-dili','ingilis-dili'))
on conflict do nothing;

-- ----------------------------------------------------------------- paketler
--  price_minor ve price_per_seat_minor QEPIKLEDIR (999 = 9.99 AZN).
--  Reqemler yer tutucudur - satisdan evvel deqiqlesdirilecek.
insert into public.plans (slug, name, audience, price_minor, price_per_seat_minor,
                          max_students, period, sort, features) values
  ('pulsuz', 'Pulsuz', 'parent', 0, 0, 2, 'month', 10,
   '{"reports":false,"history_days":7,"weak_topics":false}'::jsonb),

  ('valideyn-aylik', 'Valideyn - aylıq', 'parent', 990, 0, 3, 'month', 20,
   '{"reports":true,"history_days":365,"weak_topics":true}'::jsonb),

  ('valideyn-illik', 'Valideyn - illik', 'parent', 9900, 0, 3, 'year', 30,
   '{"reports":true,"history_days":null,"weak_topics":true}'::jsonb),

  ('repetitor-25', 'Repetitor - 25 şagird', 'tutor', 2900, 0, 25, 'month', 40,
   '{"reports":true,"own_tests":true,"weak_topics":true,"class_analytics":true}'::jsonb),

  ('repetitor-60', 'Repetitor - 60 şagird', 'tutor', 5900, 0, 60, 'month', 50,
   '{"reports":true,"own_tests":true,"weak_topics":true,"class_analytics":true}'::jsonb),

  ('repetitor-acik', 'Repetitor - şagird sayına görə', 'tutor', 1500, 120, null, 'month', 60,
   '{"reports":true,"own_tests":true,"weak_topics":true,"class_analytics":true}'::jsonb),

  ('mekteb', 'Məktəb lisenziyası', 'school', 0, 90, null, 'year', 70,
   '{"reports":true,"own_tests":true,"weak_topics":true,"class_analytics":true,"multi_teacher":true}'::jsonb)
on conflict (slug) do update
  set name = excluded.name, audience = excluded.audience,
      price_minor = excluded.price_minor,
      price_per_seat_minor = excluded.price_per_seat_minor,
      max_students = excluded.max_students,
      period = excluded.period, sort = excluded.sort,
      features = excluded.features;
