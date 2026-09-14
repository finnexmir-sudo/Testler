-- =====================================================================
--  193_test_sil_adi.sql : oz testini silmek / adini deyismek
--
--  Muellim eyni adla defelerle test yigir («Samir 1» x4) - siyahi
--  zibillenir, silmek yeri yox idi.  Indi vereqde «Adi deyis» ve «Sil».
--    rpc_test_rename(test, ad)   sahib; 1..120 herf
--    rpc_test_delete(test)       sahib; YALNIZ hec bir cehd yoxdursa
--                                (sagird isleyibse netice itmesin) -
--                                test_questions / assignments cascade,
--                                plan bendlerinde test_id null olur.
-- =====================================================================

create or replace function public.rpc_test_rename(p_test_id uuid, p_title text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_t text := btrim(coalesce(p_title, ''));
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  if length(v_t) < 1 then
    raise exception 'Testin adını yazın.' using errcode = '22023';
  end if;
  if length(v_t) > 120 then
    raise exception 'Ad 120 hərfdən uzun olmasın.' using errcode = '22023';
  end if;
  update public.tests set title = v_t where id = p_test_id and owner_type = 'educator';
  return jsonb_build_object('ok', true, 'title', v_t);
end $$;
revoke all on function public.rpc_test_rename(uuid, text) from public, anon;
grant execute on function public.rpc_test_rename(uuid, text) to authenticated;

create or replace function public.rpc_test_delete(p_test_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_n int;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  if not exists (select 1 from public.tests where id = p_test_id and owner_type = 'educator') then
    raise exception 'Hazır bank testi silinmir.' using errcode = '42501';
  end if;
  select count(*) into v_n from public.attempts where test_id = p_test_id;
  if v_n > 0 then
    raise exception 'Bu testi % şagird işləyib — silinmir, nəticələr itər. Tapşırığı geri götürün, siyahıdan çıxar.', v_n
      using errcode = '23503';
  end if;
  delete from public.tests where id = p_test_id;
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.rpc_test_delete(uuid) from public, anon;
grant execute on function public.rpc_test_delete(uuid) to authenticated;
