-- =====================================================================
--  184_numune_cixis.sql — NUMUNEDEN CIXIS YOLU
--
--  Canli baxis (2026-09-10): "sagird kimi numuneye girirem ama cixa
--  bilmirem - loqoya basiram eyni sehifeye qayidir, «Çıxış» kod
--  ekranini acir".  Ziyaretci numuneni gorur, sonra sayta qayida
--  bilmirdi.
--
--  Serverin payi kicikdir: giris cavabina 'demo' acari elave olunur -
--  bu hesab numunedirse true.  Tetbiq (sagird/valideyn) bunu gorub
--  ust zolaqda «Çıxış» evezine «Nümunədən çıx» duymesi gosterir ve
--  ana sehifeye qaytarir.
--
--  Niye kodu yoxlamaqla kifayetlenmirik: paylasilan numunenin kodlari
--  sabitdir (DEMO0001 / VDEMO001), amma "Müəllim kimi bax" her
--  ziyaretciye AYRICA nusxe qurur - onun sagird kodlari tesadufidir.
--  Serverden gelen bayraq butun hallari tutur.
--
--  Govde 164 (sagird) ve 107 (valideyn) fayllarindan proqramla
--  cixarilib; yalniz 'demo' acari ve onu oxuyan select elave olunub.
-- =====================================================================

do $$
begin
  if to_regprocedure('public.rpc_student_login(text)') is null
     or to_regprocedure('public.rpc_parent_login(text)') is null then
    raise exception 'ONCE 164 ve 107 isledilmelidir.';
  end if;
end $$;

create or replace function public.rpc_student_login(p_code text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student public.students%rowtype;
  v_token   text;
  v_class   public.classes%rowtype;
  v_demo    boolean;
begin
  if p_code is null or length(btrim(p_code)) < 6 then
    return jsonb_build_object('ok', false, 'error', 'Kod qisadir.');
  end if;

  select * into v_student from public.students
   where login_code = upper(btrim(p_code)) and is_active;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'Bele kod tapilmadi.');
  end if;

  select * into v_class from public.classes where id = v_student.class_id;
  --  184: numune hesabin sagirdi.  Tetbiq bununla «Nümunədən çıx»
  --  duymesini gosterir - numuneye baxan ziyaretci kod ekraninda
  --  ilisib qalmasin.
  select coalesce(a.is_demo, false) into v_demo
    from public.accounts a where a.id = v_student.account_id;

  v_token := encode(gen_random_bytes(32), 'hex');
  --  164: 12 saat -> 30 gun (valideynle eyni)
  insert into public.student_sessions (token_hash, student_id, expires_at)
  values (app.hash_token(v_token), v_student.id, now() + interval '30 days');

  return jsonb_build_object(
    'ok',      true,
    'token',   v_token,
    'demo',    coalesce(v_demo, false),
    'student', jsonb_build_object(
                 'id',           v_student.id,
                 'display_name', v_student.display_name),
    'class',   case when v_class.id is null then null else jsonb_build_object(
                 'id',   v_class.id,
                 'name', v_class.name) end
  );
end $$;

create or replace function public.rpc_parent_login(p_code text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    public.students%rowtype;
  v_class public.classes%rowtype;
  v_token text;
  v_demo  boolean;
begin
  if p_code is null or length(btrim(p_code)) < 6 then
    return jsonb_build_object('ok', false, 'error', 'Kod qisadir.');
  end if;

  select * into v_st from public.students
   where parent_code = upper(btrim(p_code)) and is_active;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Bele kod tapilmadi.');
  end if;

  select * into v_class from public.classes where id = v_st.class_id;
  --  184: numune hesabin valideyni (yuxarida sagirdle eyni sebeb).
  select coalesce(a.is_demo, false) into v_demo
    from public.accounts a where a.id = v_st.account_id;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into public.parent_sessions (token_hash, student_id, expires_at)
  values (app.hash_token(v_token), v_st.id, now() + interval '30 days');

  --  DIQQET: login_code BURADA YOXDUR ve olmamalidir.
  return jsonb_build_object(
    'ok',    true,
    'token', v_token,
    'demo',  coalesce(v_demo, false),
    'child', jsonb_build_object('name', v_st.display_name),
    'class', case when v_class.id is null then null
                  else jsonb_build_object('name', v_class.name) end);
end $$;

revoke all on function public.rpc_student_login(text) from public;
grant execute on function public.rpc_student_login(text) to anon, authenticated;
revoke all on function public.rpc_parent_login(text)  from public;
grant execute on function public.rpc_parent_login(text)  to anon, authenticated;
