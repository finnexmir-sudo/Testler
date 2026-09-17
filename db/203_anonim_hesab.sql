-- =====================================================================
--  203 : anonim (numune) istifadecinin ustunde real hesab acilmasin
--        (2026-09-17)
--
--  Canlida gorulen: Idareetmede eyni adla IKI hesab - biri e-poctlu
--  (11 sagird, 2 qrup), digeri e-poctsuz (qrup yoxdur, 19 test).
--  auth.users-de ikinci hesabin sahibi is_anonymous = true.
--
--  Necə olub: muellim «Nümunəyə bax»-a girib.  Nusxe bir nece saniye
--  qurulur.  O anda sehifeni yenileyib (ya paneli ikinci tabda acib).
--  Panel anonim sessiyani gorub, hesabi hele gormeyib -> «Hesabı
--  quraşdırın» ekrani -> ad yazib «Davam et» -> anonim istifadecinin
--  ustunde is_demo = false hesab yaranib.  19 test = numunenin oz
--  testleri (owner_id eynidir, admin siyahisi sahiblik uzre sayir).
--
--  Duzelis (uc yer):
--    1. rpc_create_account: e-poctsuz (anonim) istifadeci hesab aca
--       bilmez - anlasilan xeta.
--    2. rpc_demo_start: eyni istifadeci ucun eyni anda iki cagiris
--       (iki tab) serialize olunur - pg_advisory_xact_lock; ikinci
--       cagiris birincinin nusxesini tapib «reused» qaytarir.
--    3. Bir defelik: e-poctsuz sahibli qeyri-numune hesablar is_demo
--       olur - gece temizlemesi (rpc_demo_reset) 24 saatdan sonra
--       testleri ve istifadecisi ile birlikde silir.
--  Panel terefi (app.js): anonim sessiya hesabsiz qalanda qurasdirma
--  ekrani yox, numune yeniden acilir.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. rpc_create_account (160-in eynisi + anonim yoxlamasi)
-- ---------------------------------------------------------------------
create or replace function public.rpc_create_account(p_type text, p_name text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_acc  uuid;
  v_role app_role;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  --  203: anonim (numune) sessiya - e-pocti yoxdur, real hesab ola bilmez
  if exists (select 1 from auth.users u where u.id = v_uid and u.email is null) then
    raise exception 'Nümunə sessiyasında hesab açılmır. «Nümunədən çıx» basıb e-poçtla qeydiyyatdan keçin.'
      using errcode = '42501';
  end if;
  if p_type not in ('parent','tutor','school','individual') then
    raise exception 'Hesab tipi yanlisdir.' using errcode = '22023';
  end if;
  if coalesce(btrim(p_name), '') = '' then
    raise exception 'Ad bos ola bilmez.' using errcode = '22023';
  end if;

  insert into public.accounts (type, name, owner_id)
  values (p_type::account_type, btrim(p_name), v_uid)
  returning id into v_acc;

  insert into public.account_members (account_id, user_id, is_admin)
  values (v_acc, v_uid, true);

  v_role := case p_type when 'tutor'  then 'tutor'
                        when 'school' then 'teacher'
                        when 'parent' then 'parent'
                        else 'learner' end;
  insert into public.user_roles (user_id, role) values (v_uid, v_role)
  on conflict do nothing;

  --  160: qosulana hediyye paket (ayar aciqdirsa) - repetitor/mekteb
  perform app.hediyye_grant(v_acc);

  return jsonb_build_object('id', v_acc, 'type', p_type, 'name', btrim(p_name));
end $$;
revoke all on function public.rpc_create_account(text, text) from public, anon;
grant execute on function public.rpc_create_account(text, text) to authenticated;

-- ---------------------------------------------------------------------
--  2. rpc_demo_start (159-un eynisi + istifadeci uzre kilid)
-- ---------------------------------------------------------------------
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
  --  203: eyni istifadecinin iki paralel cagirisi (iki tab, yenileme)
  --  novbeye durur - ikincisi birincinin nusxesini gorur, tezeden qurmur
  perform pg_advisory_xact_lock(hashtext('demo_start:' || v_uid::text));

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
revoke all on function public.rpc_demo_start() from public, anon;
grant execute on function public.rpc_demo_start() to authenticated;

-- ---------------------------------------------------------------------
--  3. Bir defelik temizleme: anonim sahibli «real» hesablar numune olur
--     (paylasilan numunenin sahibi e-poctludur - toxunulmur)
-- ---------------------------------------------------------------------
update public.accounts a
   set is_demo = true
  from auth.users u
 where u.id = a.owner_id
   and u.email is null
   and not a.is_demo
   and a.id <> app.demo_account();
