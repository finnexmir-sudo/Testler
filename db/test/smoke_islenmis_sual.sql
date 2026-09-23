-- =====================================================================
--  smoke_islenmis_sual.sql : 223 - «exclude» MEYILDIR, sert deyil
--
--  app.generate_pick birbasa cagirilir (parametr qebul edir, interfeys
--  lazim deyil).  Uc hal:
--    A) exclude yoxdur              -> adi secim
--    B) evvelki 10 sual exclude     -> yeni 10 sual, UST-USTE DUSMUR
--    C) 25 sual exclude, 5 tezedir  -> YENE 10 sual qaytarir (xeta yox),
--       ve 5 tezenin HAMISI icindedir - meyil isledi, sert olmadi
--
--  C EN VACIBIDIR: sert suzgec olsaydi generator «kifayet sual yoxdur»
--  deyerdi ve muellim duymeni basib bos qayidardi.
--
--  ISTIFADE:  psql -f db/test/smoke_islenmis_sual.sql
--  Oz melumatini yaradir ve SONUNDA GERI QAYTARIR (rollback).
-- =====================================================================
\set ON_ERROR_STOP on
begin;

do $$
declare
  v_u uuid := gen_random_uuid();
  v_acc uuid; v_subj uuid; v_lev uuid; v_top uuid;
  v_q uuid; i int;
  a uuid[]; b uuid[]; c uuid[];
  v_kesis int; v_teze uuid[]; v_var int;
  v_rule jsonb;
begin
  select id into v_subj from public.subjects where slug = 'riyaziyyat';
  select id into v_lev  from public.levels   limit 1;

  insert into auth.users (id, email) values (v_u, 'sm' || left(v_u::text, 8) || '@t.az');
  --  profiles setri auth.users treyqeri ile ozu yaranir - elave etsek
  --  «duplicate key» olur.  Yalniz adini yaziriq.
  update public.profiles set full_name = 'Sınaq müəllim' where id = v_u;
  insert into public.accounts (owner_id, name, type) values (v_u, 'Sınaq hesab', 'tutor')
    returning id into v_acc;

  insert into public.topics (subject_id, level_id, parent_id, name, slug, sort)
       values (v_subj, v_lev, null, 'SINAQ fəsil 223', 'sm223-f', 995)
    returning id into v_top;

  --  30 FERQLI sual: govdeler ve duzgun cavablar ayri olmalidir,
  --  yoxsa generator onlari tekrar sayib atir (13: oxsarliq 0.95,
  --  eyni cavab ceil(say/7) defe).
  for i in 1 .. 30 loop
    insert into public.questions (owner_type, owner_id, account_id, subject_id,
                                  level_id, topic_id, kind, body, status)
         values ('educator', v_u, v_acc, v_subj, v_lev, v_top, 'single',
                 (array['%s ədədinin kvadratı neçədir?',
                        'Tənliyi həll edin: x - %s = 0',
                        '%s ədədini 3-ə vurun',
                        '%s ilə 7-nin fərqi nədir?',
                        '%s ədədinin yarısı nədir?'])[1 + (i % 5)]
                 || ' (' || i || ')',
                 'published')
      returning id into v_q;
    insert into public.question_options (question_id, ord, body, is_correct)
         values (v_q, 1, (i * 13 + 5)::text, true),
                (v_q, 2, (i * 13 + 6)::text, false),
                (v_q, 3, (i * 13 + 7)::text, false);
  end loop;

  v_rule := jsonb_build_object('pool', 'mine', 'count', 10,
                               'topics', jsonb_build_array(v_top::text));

  --  ---- A: adi secim
  a := app.generate_pick(v_rule, v_acc);
  if coalesce(array_length(a, 1), 0) <> 10 then
    raise exception 'SEHV 1: adi secimde 10 sual gozlenilirdi, % geldi',
      coalesce(array_length(a, 1), 0);
  end if;
  raise notice 'OK  1 · adi secim 10 sual verir';

  --  ---- B: evvelkiler novbede geri qalir
  b := app.generate_pick(
         v_rule || jsonb_build_object('exclude',
           (select jsonb_agg(x::text) from unnest(a) x)), v_acc);
  if coalesce(array_length(b, 1), 0) <> 10 then
    raise exception 'SEHV 2: ikinci secimde 10 sual gozlenilirdi, % geldi',
      coalesce(array_length(b, 1), 0);
  end if;
  select count(*) into v_kesis from unnest(b) x where x = any(a);
  if v_kesis <> 0 then
    raise exception 'SEHV 3: iki test % sualda ust-uste dusdu (0 gozlenilirdi)',
      v_kesis;
  end if;
  raise notice 'OK  2 · ikinci test birincisi ile HEC BIR sualda ust-uste dusmur';

  --  ---- C: hovuz catmayanda XETA YOX - kohnesi geri qayidir
  select array_agg(id) into v_teze from (
    select q.id from public.questions q
     where q.topic_id = v_top and q.id <> all(a) and q.id <> all(b)
     limit 5) z;                          -- 30 - 20 = 10, bunlardan 5-i
  c := app.generate_pick(
         v_rule || jsonb_build_object('exclude',
           (select jsonb_agg(q.id::text) from public.questions q
             where q.topic_id = v_top and not (q.id = any(v_teze)))), v_acc);
  if coalesce(array_length(c, 1), 0) <> 10 then
    raise exception 'SEHV 4: dar hovuzda test yigilmadi - % sual geldi. '
      'Demeli «exclude» SERT suzgec kimi islyir, MEYIL kimi yox.',
      coalesce(array_length(c, 1), 0);
  end if;
  select count(*) into v_var from unnest(v_teze) x where x = any(c);
  if v_var <> 5 then
    raise exception 'SEHV 5: 5 teze sualdan yalniz %-i secildi - meyil islemir',
      v_var;
  end if;
  raise notice 'OK  3 · dar hovuzda XETA YOX: 10 sual yigildi, 5 tezenin hamisi icinde';
  raise notice 'OK  4 · «exclude» MEYILDIR - sert suzgec deyil';
end $$;

rollback;
