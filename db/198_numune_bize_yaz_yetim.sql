-- =====================================================================
--  198 : numune hesabin «Bize yaz» yazisi silinen hesabdan sonra
--        idareetmede REAL muraciet kimi gorunurdu (2026-09-16)
--
--  Idareetme ekraninda «19 yeni müraciət» - hamisi eyni metn:
--     «Qrup hesabatında zəif mövzuların yanında «təkrar dərs» üçün
--      hazır test düyməsi çox yaxşı olardı.»
--  Bu metn numune hesabin qurucusunun (app.demo_build) yazdigi nümunə
--  yazidir - real muellim deyil.  Niye gorundu:
--    * feedback.account_id / user_id FK-lari ON DELETE SET NULL-dur;
--    * numune nusxesi silinende (rpc_demo_reset) hesab ve istifadeci
--      gedir, feedback setiri NULL-larla qalir;
--    * app.feedback_is_demo(NULL, NULL) = false -> suzgecden kecir,
--      adi/e-poctu olmadigi ucun «Müəllim» kimi gorunur.
--
--  Duzelis (uc hisse):
--    1. accounts BEFORE DELETE trigger-i: is_demo hesab silinende onun
--       feedback setirleri de silinir - hansi yolla silinmesinden asili
--       olmayaraq (rpc_demo_reset, admin, gelecek RPC-ler).
--    2. Bir defelik temizlik: hesabsiz, istifadecisiz, sagirdsiz qalmis
--       ve govdesi numune metni ile eyni olan setirler silinir.
--    3. app.feedback_is_demo: uc acar da NULL-dursa (yetim setir) true -
--       real muraciet hemise en azi bir acarla gelir (rpc_feedback /
--       rpc_student_feedback / rpc_parent_feedback), yetim yalniz silinmis
--       hesabdan qala biler.
-- =====================================================================

-- 1. trigger
create or replace function app.demo_account_cleanup() returns trigger
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if old.is_demo then
    delete from public.feedback f where f.account_id = old.id;
    delete from public.feedback f
     where f.student_id in (select s.id from public.students s where s.account_id = old.id);
  end if;
  return old;
end $$;

drop trigger if exists trg_accounts_demo_cleanup on public.accounts;
create trigger trg_accounts_demo_cleanup
  before delete on public.accounts
  for each row execute function app.demo_account_cleanup();

-- 2. bir defelik temizlik (yetim numune setirleri)
delete from public.feedback f
 where f.account_id is null and f.user_id is null and f.student_id is null
   and f.body = 'Qrup hesabatında zəif mövzuların yanında «təkrar dərs» üçün hazır test düyməsi çox yaxşı olardı.';

-- 3. yetim setir numune sayilir
create or replace function app.feedback_is_demo(p_account uuid, p_student uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select (p_account is null and p_student is null)
      or exists (
    select 1 from public.accounts da
     where da.is_demo
       and (da.id = p_account
            or da.id = (select st.account_id from public.students st where st.id = p_student))
  )
$$;
