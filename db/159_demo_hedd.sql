-- =====================================================================
--  159_demo_hedd.sql — NUMUNE NUSXESI HEDDI (BOT MUDAFIESI)
--
--  Tehlukesizlik yoxlamasi (2026-09-07): anonim giris aciqdir, her
--  "Muellim kimi bax" ayrica nusxe qurur (25 sagird, ~150 cehd, ~1600
--  cavab, ~1 MB).  Hedd yox idi - bot saatda 30 anonim giris (Supabase
--  heddi) x 24 = gunde ~700 nusxe ile pulsuz bazani bir gune doldura
--  bilerdi.  Nusxeler 24 saatdan sonra silinir, amma bir gun beсdir.
--
--  Uc mudafie:
--   1. Saatda en cox app.demo_hour_limit() = 20 YENI nusxe.  Kecende
--      acıq mesaj: "Numune hazirlanir - bir nece deqiqeden sonra
--      yeniden cehd edin" (panel bunu sakit kartla gosterir, "Yeniden
--      cehd et" duymesi).  Real muellimler bu hedde hec vaxt deymir.
--   2. Movcud nusxeni 10 deqiqede birden cox yeniden qurmaq olmur
--      (bir anonim istifadeci ile tekrar rpc_demo_start = CPU yuku):
--      hedd icinde movcud kodlar qaytarilir, qurulmur.
--   3. rpc_demo_reset hesabsiz qalmis anonim istifadecileri de silir
--      (auth.users, email null, 24 saatdan kohne).
--
--  Govde: rpc_demo_start yeniden yazilib, rpc_demo_reset 136-dan
--  proqramla (gen159.py).
-- =====================================================================

do $$
begin
  if to_regprocedure('public.rpc_demo_start()') is null then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

create or replace function app.demo_hour_limit() returns int
language sql immutable as $$ select 20 $$;

create or replace function public.rpc_demo_start()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_created timestamptz;
  v_res jsonb;
  v_n int;
begin
  if v_uid is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  --  artiq hesabi varsa: numunedirse yeniden qurulur, deyilse toxunulmur
  select a.id, a.created_at into v_acc, v_created
    from public.accounts a where a.owner_id = v_uid order by a.created_at limit 1;
  if v_acc is not null and not (select is_demo from public.accounts where id = v_acc) then
    raise exception 'Bu istifadecinin oz hesabi var - numune yalniz yeni ziyaretci ucundur.' using errcode = '42501';
  end if;

  if v_acc is not null then
    --  2. movcud nusxe: 10 deqiqede bir defeden cox qurulmur
    if v_created > now() - interval '10 minutes'
       and exists (select 1 from public.students s where s.account_id = v_acc) then
      return jsonb_build_object(
        'ok', true, 'account_id', v_acc, 'reused', true,
        'student_code', (select s.login_code from public.students s
                          where s.account_id = v_acc order by s.created_at, s.id limit 1),
        'parent_code',  (select s.parent_code from public.students s
                          where s.account_id = v_acc order by s.created_at, s.id limit 1));
    end if;
  else
    --  1. saatliq hedd - yalniz YENI nusxeler sayilir
    select count(*) into v_n from public.accounts a
     where a.is_demo and a.id <> app.demo_account()
       and a.created_at > now() - interval '1 hour';
    if v_n >= app.demo_hour_limit() then
      raise exception 'Numune hazirlanir - bir nece deqiqeden sonra yeniden cehd edin.'
        using errcode = '53400';
    end if;
    insert into public.profiles (id, full_name) values (v_uid, 'Nümunə Müəllim') on conflict (id) do nothing;
    insert into public.accounts (type, name, owner_id, is_demo) values ('tutor', 'Nümunə hesabı', v_uid, true)
    returning id into v_acc;
    insert into public.account_members (account_id, user_id, is_admin) values (v_acc, v_uid, true);
    insert into public.user_roles (user_id, role) values (v_uid, 'tutor') on conflict do nothing;
  end if;
  v_res := app.demo_build(v_uid, v_acc, false);
  return v_res;
end $$;

create or replace function public.rpc_demo_reset()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_last timestamptz;
  v_res  jsonb;
  v_del  int := 0;
begin
  select (val->>'at')::timestamptz into v_last from public.app_state where key = 'demo_reset';
  if v_last is not null and v_last > now() - interval '10 minutes' then
    return jsonb_build_object('ok', true, 'skipped', true, 'last', v_last);
  end if;
  insert into public.app_state (key, val, updated_at) values ('demo_reset', jsonb_build_object('at', now()), now())
  on conflict (key) do update set val = excluded.val, updated_at = now();

  perform app.demo_ensure_shared();
  v_res := app.demo_build(app.demo_owner(), app.demo_account(), true);

  --  24 saatdan kohne anonim nusxeler.  accounts.owner_id ve
  --  classes.teacher_id RESTRICT-dir - evvel qruplar/testler/hesab,
  --  sonra istifadeci (profil kaskadla gedir).
  create temp table if not exists demo_old (owner_id uuid, account_id uuid) on commit drop;
  delete from demo_old;
  insert into demo_old select a.owner_id, a.id from public.accounts a
   where a.is_demo and a.id <> app.demo_account() and a.created_at < now() - interval '24 hours';
  delete from public.classes c using demo_old o where c.account_id = o.account_id;
  delete from public.tests t using demo_old o where t.owner_type = 'educator' and t.owner_id = o.owner_id;
  delete from public.students s using demo_old o where s.account_id = o.account_id;
  delete from public.accounts a using demo_old o where a.id = o.account_id;
  delete from auth.users u using demo_old o where u.id = o.owner_id;
  get diagnostics v_del = row_count;
  --  159: hesabsiz qalmis anonim istifadeciler (bot yalniz anonim giris
  --  edib demo acmayib, ya da demo acilmadan hedd kesib) - 24 saatdan sonra
  delete from auth.users u
   where u.email is null
     and u.id <> app.demo_owner()
     and u.created_at < now() - interval '24 hours'
     and not exists (select 1 from public.accounts a where a.owner_id = u.id);
  return v_res || jsonb_build_object('deleted_copies', v_del);
end $$;

revoke all on function app.demo_hour_limit()      from public, anon, authenticated;
revoke all on function public.rpc_demo_start()    from public, anon;
grant execute on function public.rpc_demo_start() to authenticated;
revoke all on function public.rpc_demo_reset()    from public;
grant execute on function public.rpc_demo_reset() to anon, authenticated;
