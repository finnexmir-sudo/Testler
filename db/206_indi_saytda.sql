-- =====================================================================
--  206 : «INDI SAYTDA» - rpc_seen 15 deq -> 2 deq (2026-09-17)
--
--  Istifadeci: «hal-hazirda saytda olani bilim?»  Panel 3 deqiqede bir
--  «nebz» gonderir (tab gorunende), server last_seen_at-i 2 deqiqede
--  bir yenileyir.  Idareetme: son giris 5 deqiqeden tezedirse yasil
--  noqte «indi saytda», yuxarida say.  Yeni cedvel/RPC yoxdur -
--  rpc_admin_accounts.last_login onsuz da profiles.last_seen_at-dir.
--  Yuk: bir muellim ucun 3 deqiqede bir xirda sorgu.
-- =====================================================================
create or replace function public.rpc_seen()
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false);
  end if;
  update public.profiles
     set last_seen_at = now()
   where id = auth.uid()
     and (last_seen_at is null or last_seen_at < now() - interval '2 minutes');
  --  190: 2FA kilidinden asili deyil
  perform app.own_mark();
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.rpc_seen() from public, anon;
grant execute on function public.rpc_seen() to authenticated;
