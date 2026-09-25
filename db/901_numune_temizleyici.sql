-- =====================================================================
--  901_numune_temizleyici.sql — NUMUNE NUSXELERI YIGILIB QALIRDI
--
--  ISTIFADECI GORDU (2026-09-25): Idareetmede «Nümunə hesabı» setirleri
--  28-e catmisdi, hamisinda «özü silinir» yazirdi - amma silinmirdi.
--
--  SEBEB (tapinti, fərziyyə deyil).  Nusxeleri her gun GitHub Actions
--  («Supabase-i oyaq saxla», .github/workflows/oyaq-saxla.yml) silir:
--  anon acarla rpc_demo_reset cagirir.  Hemin is 19 sentyabrdan beri
--  HER GUN sinirdi:
--      HTTP 500  {"code":"57014",
--                 "message":"canceling statement due to statement timeout"}
--  Sorgu ~3,4 saniyede kesilir.  Funksiya BIR ifadedir - kesilende
--  butun is geri qayidir, silme de.  Son ugurlu is 18 sentyabr; ekranda
--  en kohne nusxe «7 gun evvel» - deqiq uygun gelir.
--
--  QARTOPU.  Ne qeder cox nusxe yigilir, silme bir o qeder uzun cekir,
--  timeout bir o qeder deqiq olur.  Oz-ozune duzelmirdi - her gun
--  pislesirdi.
--
--  UC DUZELIS
--
--  1. IS BOLUNUR.  Silme artiq ayri, YUNGUL funksiyadadir:
--     app.demo_gc(p_limit) - en cox p_limit nusxe silir ve necesinin
--     qaldigini deyir.  Bir cagiris kicikdir, hec bir hedde catmir.
--     Is axini sifir qayidana qeder cagirir.  Bele olanda yenidenqurma
--     sinsa bele TEMIZLIK GEDIB CIXIR - biri o birini bataqliga salmir.
--
--  2. VAXT HEDDI.  rpc_demo_reset-e oz statement_timeout-u verilir
--     (60 s).  Funksiya sevviyyesinde SET rol ayarindan ustundur ve
--     yalniz hemin cagirisa aiddir - qonsu sorgular tesirlenmir.
--
--  3. MUVEQQETI CEDVEL GEDIR.  Kohne govde «create temp table demo_old»
--     islediridi.  Supabase hovuzlanmis baglanti uzerinden isleyir -
--     CLAUDE.md-de bu ayrica tele kimi yazilib.  Yerine adi massiv.
--
--  TEHLUKESIZLIK.  Paylasilan ESAS numune hesabi (app.demo_account())
--  HEC VAXT silinmir - her iki funksiyada sert var.  Silinen yalniz
--  ziyaretcinin 24 saatdan kohne anonim nusxesidir.
--
--  QRANTLAR: rpc_demo_gc anon ag siyahisina elave olunur (05_grants.sql,
--  IKI massiv) - is axini anon acarla cagirir.  Ag siyahi 25 -> 26.
--  Bu faylı isletdikden SONRA 05_grants.sql da isledilmelidir.
-- =====================================================================

--  ---- app.demo_gc : porsiya-porsiya silir -----------------------------
create or replace function app.demo_gc(p_limit int default 5)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc uuid[];
  v_own uuid[];
  v_n   int := 0;
  v_yet int := 0;
  v_qal int := 0;
begin
  if p_limit is null or p_limit < 1 then p_limit := 5; end if;
  if p_limit > 50 then p_limit := 50; end if;

  --  Massiv - MUVEQQETI CEDVEL DEYIL (Supabase hovuzlanmis baglanti)
  select array_agg(z.id), array_agg(z.owner_id) into v_acc, v_own
    from (select a.id, a.owner_id from public.accounts a
           where a.is_demo
             and a.id <> app.demo_account()
             and a.created_at < now() - interval '24 hours'
           order by a.created_at
           limit p_limit) z;

  if v_acc is not null then
    v_n := array_length(v_acc, 1);
    --  Sira VACIBDIR: accounts.owner_id ve classes.teacher_id RESTRICT-dir
    delete from public.classes  c where c.account_id = any(v_acc);
    delete from public.tests    t where t.owner_type = 'educator' and t.owner_id = any(v_own);
    delete from public.students s where s.account_id = any(v_acc);
    delete from public.accounts a where a.id = any(v_acc);
    delete from auth.users      u where u.id = any(v_own);
  end if;

  --  Hesabsiz qalmis anonim istifadeciler (bot anonim girib, numune
  --  acmayib).  Burada da porsiya - hedd asilmasin.
  delete from auth.users u
   where u.id in (select u2.id from auth.users u2
                   where u2.email is null
                     and u2.id <> app.demo_owner()
                     and u2.created_at < now() - interval '24 hours'
                     and not exists (select 1 from public.accounts a
                                      where a.owner_id = u2.id)
                   limit p_limit);
  get diagnostics v_yet = row_count;

  select count(*) into v_qal from public.accounts a
   where a.is_demo and a.id <> app.demo_account()
     and a.created_at < now() - interval '24 hours';

  return jsonb_build_object('deleted', v_n, 'orphans', v_yet, 'left', v_qal);
end $$;

comment on function app.demo_gc(int) is
  'Kohne anonim numune nusxelerini porsiya-porsiya silir.  «left» sifir olana qeder cagirilir.';

--  ---- rpc_demo_gc : is axini bunu cagirir -----------------------------
create or replace function public.rpc_demo_gc(p_limit int default 5)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp
set statement_timeout = '30s' as $$
begin
  return app.demo_gc(p_limit);
end $$;

comment on function public.rpc_demo_gc(int) is
  'Numune nusxelerinin yigisdirilmasi - anon acarla is axinindan cagirilir.';

--  ---- rpc_demo_reset : temp cedvel gedir, oz vaxt heddi gelir ---------
--  Govde db/197-den goturulub; silme hissesi app.demo_gc-ye verilib.
create or replace function public.rpc_demo_reset()
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp
set statement_timeout = '60s' as $$
declare
  v_last timestamptz;
  v_res  jsonb;
  v_gc   jsonb;
begin
  select (val->>'at')::timestamptz into v_last from public.app_state where key = 'demo_reset';
  if v_last is not null and v_last > now() - interval '10 minutes' then
    return jsonb_build_object('ok', true, 'skipped', true, 'last', v_last);
  end if;
  insert into public.app_state (key, val, updated_at)
       values ('demo_reset', jsonb_build_object('at', now()), now())
  on conflict (key) do update set val = excluded.val, updated_at = now();

  perform app.demo_ensure_shared();
  v_res := app.demo_build(app.demo_owner(), app.demo_account(), true);

  --  Temizlik burada da edilir (kicik porsiya) - is axini ayrica
  --  rpc_demo_gc cagirsa da, tek bu funksiya isledilende de is gorulsun.
  v_gc := app.demo_gc(5);

  return v_res || jsonb_build_object('deleted_copies', (v_gc->>'deleted')::int,
                                     'left', (v_gc->>'left')::int);
end $$;

--  Huquqlar: 05_grants.sql ag siyahini yeniden qurur, amma bu fayl tek
--  isledilende de is axini isləsin deye burada da verilir.
grant execute on function public.rpc_demo_gc(int) to anon, authenticated;
