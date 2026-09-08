-- =====================================================================
--  164_sagird_sessiya_30gun.sql — SAGIRD SESSIYASI 12 SAAT -> 30 GUN
--
--  Istifadeci sualı (2026-09-08): "her defe sagird kimi girmek mecbur
--  olur".  Sebeb: rpc_student_login sessiyani 12 saatliq verirdi -
--  sagird durub sabah acanda kod yeniden istenirdi.  Telefonda
--  qurulmus tetbiqde bu xususile pisdir: ikonu basir, giris ekrani
--  cixir, kod isə muellimin mesajindadir.
--
--  30 gun: valideyn sessiyasi (107_valideyn.sql) ONSUZ DA 30 gundur -
--  ferqli olmasi ucun sebeb yox idi.  Risk kicikdir: token yalniz oz
--  tapsiriqlarini gormeye ve test yazmaga imkan verir, kodun ozu ise
--  daimidir (kagizda/mesajda qalir - yeni token ondan tehlukesizdir).
--
--  Muellim istənilən vaxt kəsə bilir: "Giriş kodunu yenilə" ve
--  "Dayandır" sessiyalari silir (06_educator_rpc.sql).
--
--  Yalniz BIR funksiya deyisir - cedvel, huquq, anon siyahisi eynidir.
-- =====================================================================

create or replace function public.rpc_student_login(p_code text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_student public.students%rowtype;
  v_token   text;
  v_class   public.classes%rowtype;
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

  v_token := encode(gen_random_bytes(32), 'hex');
  --  164: 12 saat -> 30 gun (valideynle eyni)
  insert into public.student_sessions (token_hash, student_id, expires_at)
  values (app.hash_token(v_token), v_student.id, now() + interval '30 days');

  return jsonb_build_object(
    'ok',      true,
    'token',   v_token,
    'student', jsonb_build_object(
                 'id',           v_student.id,
                 'display_name', v_student.display_name),
    'class',   case when v_class.id is null then null else jsonb_build_object(
                 'id',   v_class.id,
                 'name', v_class.name) end
  );
end $$;

--  Huquqlar 03_rpc.sql-deki kimi qalir (create or replace onlari saxlayir),
--  amma miqrasiya tek isledilende de duz olsun deye tekrarlanir:
revoke all on function public.rpc_student_login(text) from public;
grant execute on function public.rpc_student_login(text) to anon, authenticated;
