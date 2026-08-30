-- =====================================================================
--  hardayam.sql : bazanin hansi miqrasiyalari gorduyunu deyir
--  Heç ne deyismir - yalniz oxuyur.  Supabase SQL Editor-a yapisdir.
-- =====================================================================
with c(t, col) as (
  select table_name, column_name from information_schema.columns
   where table_schema = 'public'
),
t(name) as (
  select table_name from information_schema.tables where table_schema = 'public'
),
adim(ord, fayl, ne, var) as (values
  (1, '01..08',            'esas sxem',
      (select count(*) > 0 from t where name = 'attempts')),
  (2, '10_teyinat_migrasiya.sql', 'teyinatlar',
      (select count(*) > 0 from t where name = 'assignments')),
  (3, '11_sual_banki.sql',  'sual banki + terkib',
      (select count(*) > 0 from c where t = 'questions' and col = 'account_id')),
  (4, '11_sual_banki.sql',  'cavabin sureti',
      (select count(*) > 0 from c where t = 'attempt_answers' and col = 'question_body')),
  (5, '12_bank_rpc.sql',    'bankin RPC-leri',
      to_regprocedure('public.rpc_bank_list(jsonb, int, int, uuid)') is not null),
  (6, '13_generator.sql',   'generator',
      to_regprocedure('public.rpc_generate_test(jsonb, text, uuid, uuid)') is not null)
)
select ord as "#", fayl, ne as "ne verir",
       case when var then 'VAR' else '--- YOXDUR' end as veziyyet
  from adim
 order by ord;

-- Novbeti addim
do $$
declare v_next text;
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name='questions'
                    and column_name='account_id') then
    v_next := '11_sual_banki.sql';
  elsif to_regprocedure('public.rpc_bank_list(jsonb, int, int, uuid)') is null then
    v_next := '12_bank_rpc.sql';
  elsif to_regprocedure('public.rpc_generate_test(jsonb, text, uuid, uuid)') is null then
    v_next := '13_generator.sql';
  else
    v_next := null;
  end if;

  if v_next is null then
    raise notice 'Hər şey yerindədir - işlədiləsi fayl qalmayıb.';
  else
    raise notice 'NÖVBƏTİ İŞLƏDİLƏSİ FAYL:  %', v_next;
  end if;
end $$;

-- Sinif dublikatlari (04_seed 9-11-i 'buraxilis'de, 41/45/49 ise
-- 'orta'da yaradirdi - her sinif iki defe gorunurdu)
do $$
declare k int;
begin
  select count(*) into k from (
    select l.code from public.levels l
     where l.code ~ '^[0-9]+$'
     group by l.code having count(*) > 1) z;
  if k > 0 then
    raise notice 'DIQQET: % sinif kodu iki defe var - 57_sinif_dubli.sql '
                 'isledilmelidir.', k;
  else
    raise notice 'Sinif kodlari tekdir - 57_sinif_dubli.sql lazim deyil.';
  end if;
end $$;

-- ---------------------------------------------------------------------
--  BANKIN VEZIYYETI: hansi fenn hansi siniflerde doludur
--  Bos movzu = o fennin bank fayli hele isledilmeyib.
-- ---------------------------------------------------------------------
select s.name as "fenn",
       --  siniflar SINIF sirasi ile duzulur; sade string_agg metne gore
       --  duzur ve "1, 10, 11, 2" cixir - telefonda oxunmur
       (select string_agg(z.code, ', ' order by z.sort)
          from (select distinct l.code, l.sort
                  from public.topics t2
                  join public.levels l on l.id = t2.level_id
                 where t2.subject_id = s.id) z) as "sinifler",
       count(distinct t.id) as "movzu",
       count(q.id) as "sual"
  from public.subjects s
  join public.topics t on t.subject_id = s.id
  left join public.questions q
         on q.topic_id = t.id and q.owner_type = 'platform'
 group by s.id, s.name, s.sort
 order by s.sort;

do $$
declare k int; n int;
begin
  select count(*) into k from public.topics t
   where not exists (select 1 from public.questions q
                      where q.topic_id = t.id and q.owner_type = 'platform');
  select count(*) into n from public.questions where owner_type = 'platform';
  if k > 0 then
    raise notice 'DIQQET: % movzuda platforma sualı yoxdur - '
                 'hemin fennin bank fayli isledilmeyib.', k;
  else
    raise notice 'Butun movzularda sual var. Cemi % platforma sualı.', n;
  end if;
end $$;
