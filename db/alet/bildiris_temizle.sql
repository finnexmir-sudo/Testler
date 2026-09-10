-- =====================================================================
--  Bil10 — NÜMUNƏ HESABIN ADMİN BİLDİRİŞLƏRİNİ SİLİR
--
--  KİMİN ÜÇÜN:  samirmiroglu@gmail.com hesabı
--  NƏ EDİR:     həmin hesabın «Bizə yaz» mesajlarını və sual
--               bildirişlərini silir.  Başqa heç nəyə toxunmur —
--               qruplar, şagirdlər, testlər, kodlar yerində qalır.
--
--  NƏ ÜÇÜN LAZIMDIR
--    app.demo_build hesaba nümunə olaraq bir təklif və bir sual
--    bildirişi yazır.  Onlar admin səhifəsindəki «Bizə yaz» və
--    «Sual bildirişləri» siyahılarında görünür.  Göstərmə zamanı
--    siyahılar təmiz olsun deyə bu skript onları silir.
--
--    «Sual keyfiyyəti» kartı buradan gəlmir — o, şagird cavablarından
--    hesablanır (rpc_admin_qstats).  Silinəsi sətir yoxdur.
--
--  QEYD:  numune_doldur.sql-in özü də artıq bunu edir.  Bu fayl o
--         skripti təzədən işlətmək istəmədikdə lazımdır (təzədən
--         işlətsən şagird və valideyn kodları dəyişir).
--
--  İŞLƏTMƏ:  Supabase → SQL Editor → hamısını yapışdır → Run
-- =====================================================================
do $$
declare
  v_email text := 'samirmiroglu@gmail.com';
  v_acc   uuid;
  v_f     int;
  v_q     int;
begin
  select a.id into v_acc
    from public.accounts a
    join auth.users u on u.id = a.owner_id
   where lower(u.email) = lower(v_email)
   limit 1;

  if v_acc is null then
    raise exception 'Hesab tapilmadi: %', v_email;
  end if;

  delete from public.feedback where account_id = v_acc;
  get diagnostics v_f = row_count;

  delete from public.question_reports qr
   using public.students s
   where qr.student_id = s.id and s.account_id = v_acc;
  get diagnostics v_q = row_count;

  delete from public.question_reports where account_id = v_acc;

  raise notice 'Silindi — «Bizə yaz»: % · sual bildirişi: %', v_f, v_q;
end $$;

-- =====================================================================
--  YOXLAMA — sıfır olmalıdır
-- =====================================================================
select 'bizə yaz' as nə, count(*) as qalıb from public.feedback f
  join public.accounts a on a.id = f.account_id
  join auth.users u on u.id = a.owner_id
 where lower(u.email) = 'samirmiroglu@gmail.com'
union all
select 'sual bildirişi', count(*) from public.question_reports qr
  left join public.students s on s.id = qr.student_id
  left join public.accounts a on a.id = coalesce(qr.account_id, s.account_id)
  left join auth.users u on u.id = a.owner_id
 where lower(u.email) = 'samirmiroglu@gmail.com';
