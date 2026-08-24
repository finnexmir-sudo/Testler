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
