-- =====================================================================
--  24_admin_2fa.sql : ADMIN UCUN IKINCI AMIL (TOTP)
--
--  Idareetme sehifesi parolla yanasi Authenticator kodu ile qorunur:
--  Google Authenticator / Aegis / 1Password - istenilen TOTP tetbiqi.
--
--  NECE ISLEYIR:
--    1. Admin bir defe "2FA qur" edir: server 20 baytliq gizli acar
--       yaradir, base32 seklinde gosterir; admin onu tetbiqe elave
--       edib ilk kodla tesdiqleyir (rpc_admin_2fa_confirm).
--    2. Bundan sonra HER admin sessiyasi kilidlidir: 6 reqemli kodla
--       acilir (rpc_admin_unlock), acilis 12 saat quvvededir.
--    3. app.admin_ok() yeniden yazilir: rol + acilmis kilid.  Butun
--       kohne admin RPC-leri (21, 23) avtomatik bu qapidan kecir.
--
--  QORUMA: kod yoxlamasi 10 deqiqede 5 cehdle mehdudlasir - kobud
--  guc yolu baglidir.  Gizli acar hec vaxt teze sorguda qaytarilmir
--  (yalniz qurulus aninda bir defe).
--
--  ON SERT: 21_paket.sql (app.admin_ok) islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
--  Tekrar isledile biler (movcud acar toxunulmaz qalir).
-- =====================================================================

do $$
begin
  if to_regprocedure('app.admin_ok()') is null then
    raise exception 'ONCE 21_paket.sql islenmelidir.';
  end if;
end $$;

-- ------------------------------------------------------------ cedveller
create table if not exists public.admin_totp (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  secret     bytea not null,
  enabled    boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_unlocks (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  unlocked_until timestamptz not null
);

--  Birtefelik ehtiyat kodlar - telefon itende giris itmesin.
--  Xam kod saxlanmir, yalniz SHA-256 ozeti; istifadeden sonra yanir.
create table if not exists public.admin_backup_codes (
  user_id   uuid not null references auth.users(id) on delete cascade,
  code_hash text not null,
  used_at   timestamptz,
  primary key (user_id, code_hash)
);

create table if not exists public.admin_code_attempts (
  user_id  uuid not null,
  tried_at timestamptz not null default now()
);
create index if not exists idx_aca_user
  on public.admin_code_attempts(user_id, tried_at desc);

alter table public.admin_totp          enable row level security;
alter table public.admin_backup_codes  enable row level security;
alter table public.admin_unlocks       enable row level security;
alter table public.admin_code_attempts enable row level security;
--  Siyaset yoxdur - yalniz definer funksiyalar toxunur.

-- ------------------------------------------------------------ base32
--  Authenticator tetbiqlerinin qebul etdiyi format (RFC 4648).
create or replace function app.b32(p bytea) returns text
language plpgsql immutable as $$
declare
  al   text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  bits int := 0; buf int := 0; res text := ''; i int;
begin
  for i in 0 .. length(p) - 1 loop
    buf  := (buf << 8) | get_byte(p, i);
    bits := bits + 8;
    while bits >= 5 loop
      bits := bits - 5;
      res  := res || substr(al, ((buf >> bits) & 31) + 1, 1);
      buf  := buf & ((1 << bits) - 1);
    end loop;
  end loop;
  if bits > 0 then
    res := res || substr(al, ((buf << (5 - bits)) & 31) + 1, 1);
  end if;
  return res;
end $$;

-- ------------------------------------------------------------ TOTP
--  RFC 6238: 30 saniyelik pencere, HMAC-SHA1, 6 reqem.
create or replace function app.totp_at(p_secret bytea, p_at timestamptz)
returns text
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  c   bigint := floor(extract(epoch from p_at) / 30)::bigint;
  h   bytea;
  o   int;
  bin bigint;
begin
  h := hmac(decode(lpad(to_hex(c), 16, '0'), 'hex'), p_secret, 'sha1');
  o := get_byte(h, 19) & 15;
  bin := ((get_byte(h, o) & 127)::bigint << 24)
       | (get_byte(h, o + 1)::bigint << 16)
       | (get_byte(h, o + 2)::bigint << 8)
       |  get_byte(h, o + 3)::bigint;
  return lpad((bin % 1000000)::text, 6, '0');
end $$;

--  Saat suruskenliyi ucun +-1 pencere (standart tetbiq).
create or replace function app.totp_verify(p_secret bytea, p_code text)
returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select btrim(coalesce(p_code, '')) in (
    app.totp_at(p_secret, now() - interval '30 seconds'),
    app.totp_at(p_secret, now()),
    app.totp_at(p_secret, now() + interval '30 seconds'))
$$;

-- ------------------------------------------------- cehd heddi
--  DIQQET: sehv kod EXCEPTION ile yox, ok:false ile qaytarilir.
--  Exception butun tranzaksiyani (cehd qeydi daxil) geri sarıyardı -
--  onda hedd hec vaxt dolmazdi ve kobud guc mumkun olardi.
drop function if exists app.code_attempt_gate(uuid);
create or replace function app.code_attempt_gate(p_user uuid)
returns boolean
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
begin
  delete from public.admin_code_attempts where tried_at < now() - interval '1 day';
  if (select count(*) from public.admin_code_attempts
       where user_id = p_user
         and tried_at > now() - interval '10 minutes') >= 5 then
    return false;
  end if;
  insert into public.admin_code_attempts (user_id) values (p_user);
  return true;
end $$;

-- ------------------------------------------------- admin qapisi (yeni)
--  21-in versiyasini ust-uste yazir: rol + (2FA qurulubsa acilmis kilid).
--  2FA hele qurulmayibsa panel kohne kimi acilir - qurulusa mane olmur.
create or replace function app.admin_ok() returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select app.is_admin()
     and (not exists (select 1 from public.admin_totp
                       where user_id = auth.uid() and enabled)
          or exists (select 1 from public.admin_unlocks
                      where user_id = auth.uid()
                        and unlocked_until > now()))
$$;

-- ------------------------------------------------- veziyyet
create or replace function public.rpc_admin_2fa_status()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'enabled',  exists (select 1 from public.admin_totp
                         where user_id = auth.uid() and enabled),
    'unlocked', exists (select 1 from public.admin_unlocks
                         where user_id = auth.uid()
                           and unlocked_until > now()));
end $$;

-- ------------------------------------------------- qurulus
--  Gizli acar YALNIZ burda, bir defe qaytarilir.
create or replace function public.rpc_admin_2fa_setup()
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_secret bytea;
  v_codes  jsonb;
  v_code   text;
  i        int;
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if exists (select 1 from public.admin_totp
              where user_id = auth.uid() and enabled) then
    raise exception '2FA artiq aktivdir. Deyismek ucun evvel sondurun.'
      using errcode = '22023';
  end if;
  v_secret := gen_random_bytes(20);
  insert into public.admin_totp (user_id, secret, enabled)
  values (auth.uid(), v_secret, false)
  on conflict (user_id) do update
    set secret = excluded.secret, enabled = false, created_at = now();

  --  4 birtefelik ehtiyat kod: XXXX-XXXX. Xam halda YALNIZ burda
  --  qaytarilir - bazada tekce ozet qalir.
  delete from public.admin_backup_codes where user_id = auth.uid();
  v_codes := '[]'::jsonb;
  for i in 1..4 loop
    v_code := upper(encode(gen_random_bytes(4), 'hex'));
    v_code := substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);
    insert into public.admin_backup_codes (user_id, code_hash)
    values (auth.uid(), app.hash_token(v_code));
    v_codes := v_codes || to_jsonb(v_code);
  end loop;

  return jsonb_build_object(
    'secret', app.b32(v_secret),
    'uri', 'otpauth://totp/Bil10:admin?secret=' || app.b32(v_secret) ||
           '&issuer=Bil10',
    'backup', v_codes);
end $$;

-- ------------------------------------------------- tesdiq (ilk kod)
create or replace function public.rpc_admin_2fa_confirm(p_code text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_secret bytea;
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if not app.code_attempt_gate(auth.uid()) then
    return jsonb_build_object('ok', false,
      'err', 'Çox cəhd. 10 dəqiqə sonra yenidən yoxlayın.');
  end if;
  select secret into v_secret from public.admin_totp
   where user_id = auth.uid() and not enabled;
  if v_secret is null then
    raise exception 'Evvel qurulus aparilmalidir.' using errcode = '22023';
  end if;
  if not app.totp_verify(v_secret, p_code) then
    return jsonb_build_object('ok', false, 'err', 'Kod düzgün deyil.');
  end if;
  delete from public.admin_code_attempts where user_id = auth.uid();
  update public.admin_totp set enabled = true where user_id = auth.uid();
  insert into public.admin_unlocks (user_id, unlocked_until)
  values (auth.uid(), now() + interval '12 hours')
  on conflict (user_id) do update set unlocked_until = excluded.unlocked_until;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- kilidi acmaq
create or replace function public.rpc_admin_unlock(p_code text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_secret bytea;
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if not app.code_attempt_gate(auth.uid()) then
    return jsonb_build_object('ok', false,
      'err', 'Çox cəhd. 10 dəqiqə sonra yenidən yoxlayın.');
  end if;
  select secret into v_secret from public.admin_totp
   where user_id = auth.uid() and enabled;
  if v_secret is null then
    raise exception '2FA qurulmayib.' using errcode = '22023';
  end if;
  if not app.totp_verify(v_secret, p_code) then
    --  Authenticator kodu deyil - belke birtefelik ehtiyat koddur?
    update public.admin_backup_codes
       set used_at = now()
     where user_id = auth.uid()
       and code_hash = app.hash_token(upper(btrim(coalesce(p_code, ''))))
       and used_at is null;
    if not found then
      return jsonb_build_object('ok', false, 'err', 'Kod düzgün deyil.');
    end if;
  end if;
  delete from public.admin_code_attempts where user_id = auth.uid();
  insert into public.admin_unlocks (user_id, unlocked_until)
  values (auth.uid(), now() + interval '12 hours')
  on conflict (user_id) do update set unlocked_until = excluded.unlocked_until;
  return jsonb_build_object('ok', true,
    'backup_left', (select count(*) from public.admin_backup_codes
                     where user_id = auth.uid() and used_at is null));
end $$;

-- ------------------------------------------------- sondurmek
--  Sondurmek ucun de kod lazimdir - parolu ele kecirenin 2FA-ni
--  sakitce sondurmesi mumkun olmasin.
create or replace function public.rpc_admin_2fa_disable(p_code text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_secret bytea;
begin
  if not app.is_admin() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if not app.code_attempt_gate(auth.uid()) then
    return jsonb_build_object('ok', false,
      'err', 'Çox cəhd. 10 dəqiqə sonra yenidən yoxlayın.');
  end if;
  select secret into v_secret from public.admin_totp
   where user_id = auth.uid() and enabled;
  if v_secret is null then
    raise exception '2FA onsuz qurulmayib.' using errcode = '22023';
  end if;
  if not app.totp_verify(v_secret, p_code) then
    return jsonb_build_object('ok', false, 'err', 'Kod düzgün deyil.');
  end if;
  delete from public.admin_code_attempts where user_id = auth.uid();
  delete from public.admin_totp         where user_id = auth.uid();
  delete from public.admin_unlocks      where user_id = auth.uid();
  delete from public.admin_backup_codes where user_id = auth.uid();
  return jsonb_build_object('ok', true);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_admin_2fa_status()        from public, anon;
revoke all on function public.rpc_admin_2fa_setup()         from public, anon;
revoke all on function public.rpc_admin_2fa_confirm(text)   from public, anon;
revoke all on function public.rpc_admin_unlock(text)        from public, anon;
revoke all on function public.rpc_admin_2fa_disable(text)   from public, anon;

grant execute on function public.rpc_admin_2fa_status()      to authenticated;
grant execute on function public.rpc_admin_2fa_setup()       to authenticated;
grant execute on function public.rpc_admin_2fa_confirm(text) to authenticated;
grant execute on function public.rpc_admin_unlock(text)      to authenticated;
grant execute on function public.rpc_admin_2fa_disable(text) to authenticated;

do $$
begin
  --  ozunu-yoxlama: melum RFC 6238 test vektoru (sha1, "12345678901234567890",
  --  t=59s -> addim 1) kodu 287082 vermelidir
  if app.totp_at('12345678901234567890'::bytea,
                 to_timestamp(59)) <> '287082' then
    raise exception 'TOTP hesablamasi sehvdir!';
  end if;
  if app.b32('\x48656c6c6f21deadbeef'::bytea) <> 'JBSWY3DPEHPK3PXP' then
    raise exception 'base32 kodlamasi sehvdir!';
  end if;
  if has_function_privilege('anon', 'public.rpc_admin_unlock(text)', 'EXECUTE') then
    raise exception 'anon kilid aca bilir!';
  end if;
  raise notice 'Admin 2FA quruldu.';
end $$;
