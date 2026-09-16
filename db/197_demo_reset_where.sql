-- =====================================================================
--  197 : rpc_demo_reset - «DELETE requires a WHERE clause» (2026-09-16)
--
--  Canlida gundelik temizleme (GitHub Actions «oyaq-saxla», her gun
--  05:17 UTC) BES GUNDUR ugursuz bitirdi:
--     HTTP 400 {"code":"21000","message":"DELETE requires a WHERE clause"}
--  Sebeb: Supabase PostgREST sessiyasinda «safeupdate» aciqdir - WHERE-siz
--  DELETE qadagandir.  rpc_demo_reset icinde muveqqeti cedveli
--  «delete from demo_old;» ile bosaldirdiq.  Yerli Postgres-de safeupdate
--  yoxdur, ona gore smoke testler kecirdi, canli ise dayanirdi.  Netice:
--  24 saatdan kohne numune nusxeleri SILINMIRDI - idareetmede «Nümunə
--  hesablar 21 MB · 52427 cavab · 745 şagird» (16.09, ekran sekli).
--
--  Duzelis: «where true» - safeupdate ucun WHERE var, menasi eynidir.
--  Funksiyanin qalan hissesi 159-dakinin eynisidir.
-- =====================================================================
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
  --  197: WHERE-siz DELETE canlida (safeupdate) qadagandir
  delete from demo_old where true;
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

revoke all on function public.rpc_demo_reset() from public;
grant execute on function public.rpc_demo_reset() to anon, authenticated;
