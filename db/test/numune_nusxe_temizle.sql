-- =====================================================================
--  numune_nusxe_temizle.sql : YIGILIB QALMIS numune nusxelerini silir
--
--  NIYE LAZIM OLDU (2026-09-25).  Nusxeleri her gun GitHub Actions
--  («Supabase-i oyaq saxla») silirdi - rpc_demo_reset cagirir.  19
--  sentyabrdan beri hemin is HER GUN sinir:
--      HTTP 500  57014  canceling statement due to statement timeout
--  Funksiya BIR ifadedir - kesilende butun is geri qayidir, silme de.
--  Netice: nusxeler yigilir.  Ustelik qartopu olur - ne qeder cox
--  nusxe, silmek bir o qeder uzun, timeout bir o qeder deqiq.
--
--  Bu fayl BIR DEFELIK rahatliq ucundur: SQL Editor-un vaxt heddi
--  daha uzundur.  Kokundeki duzelis db/901-dedir.
--
--  TEHLUKESIZ:  paylasilan ESAS numune hesabina (app.demo_account())
--  TOXUNMUR - yalniz ziyaretcilerin anonim nusxeleri silinir.
--  Muvveqqeti cedvel ISLETMIR (Supabase hovuzlanmis baglanti - CLAUDE.md).
--
--  ISTIFADE: Supabase -> SQL Editor -> yapisdir -> Run.
--  Sonda nece nusxe silindiyini yazir.
-- =====================================================================
do $$
declare
  v_acc  uuid[];
  v_own  uuid[];
  v_n    int;
  v_yet  int;
begin
  --  24 saatdan kohne anonim nusxeler (esas numune haric)
  select array_agg(a.id), array_agg(a.owner_id) into v_acc, v_own
    from public.accounts a
   where a.is_demo
     and a.id <> app.demo_account()
     and a.created_at < now() - interval '24 hours';

  if v_acc is null then
    raise notice 'Silinesi nusxe yoxdur.';
    return;
  end if;
  v_n := array_length(v_acc, 1);
  raise notice 'Silinir: % nusxe', v_n;

  --  Sira VACIBDIR: accounts.owner_id ve classes.teacher_id RESTRICT-dir.
  --  Evvel qruplar/testler/sagirdler, sonra hesab, en sonda istifadeci
  --  (profiles kaskadla gedir).
  delete from public.classes  c where c.account_id = any(v_acc);
  delete from public.tests    t where t.owner_type = 'educator' and t.owner_id = any(v_own);
  delete from public.students s where s.account_id = any(v_acc);
  delete from public.accounts a where a.id = any(v_acc);
  delete from auth.users      u where u.id = any(v_own);

  --  Hesabsiz qalmis anonim istifadeciler: bot anonim giris edib,
  --  numune acmayib.  Onlar da yer tutur.
  delete from auth.users u
   where u.email is null
     and u.id <> app.demo_owner()
     and u.created_at < now() - interval '24 hours'
     and not exists (select 1 from public.accounts a where a.owner_id = u.id);
  get diagnostics v_yet = row_count;

  raise notice 'Hazirdir: % nusxe, % yetim anonim istifadeci silindi', v_n, v_yet;
end $$;

--  Qalan numune hesablari (1 sətir gozlenilir - paylasilan esas nusxe)
select count(*) as qalan_numune_hesabi,
       min(created_at at time zone 'Asia/Baku') as en_kohne
  from public.accounts where is_demo;
