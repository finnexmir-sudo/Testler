-- =====================================================================
--  934 : HEDEFLI TAPSIRIQ - QRUPUN BIR HISSESINE  (2026-10-23, Sira 3)
--
--  PROBLEM (UX yoxlamasi, 23.10 - uc agent, Samir ve ChatGPT ayrica tapdi)
--  Qrup hesabati «Paralellik movzusunu 6 sagirde tekrar verin» deyir, duyme
--  ise testi BUTUN qrupa verirdi.  «Kime» secimi ya butun qrup, ya tek sagird
--  idi - 6 sagird ucun 6 defe ayrica tapsiriq vermek lazim gelirdi.  Bu,
--  mehsulun esas vedini (diaqnostika -> hedefli mesq) qirirdi.
--
--  MODEL DEYISMIR.  28-den beri assignments.student_id var: dolu setri YALNIZ
--  hemin sagird gorur, unikalliq (class_id, test_id, student_id).  Sagird
--  ekrani, rpc_start_attempt, «etmeyenler», hesabat bu yolu artiq taniyir.
--  «Qrupun bir hissesi» = eyni test ucun her secilmis sagirde bir setir.
--
--  rpc_assign_test_many(qrup, test, sagirdler[], son tarix, cehd):
--    * BIR tranzaksiya: bir sagird uygun deyilse HEC BIRI yazilmir;
--    * her setir rpc_assign_test-den kecir - huquq, abune, diaqnostika,
--      «sagird bu qrupun aktiv sagirdidir» yoxlamalari EYNI qalir;
--    * siyahi bos ola bilmez, tekrar id atilir;
--    * test bu qrupa artiq BUTUN QRUP kimi verilibse redd: sagird eyni
--      testi iki defe gorerdi, muellim ise «6 sagirde» verdiyini sanardi.
--  Qaytarir: {count, test, students[] (gorunen adlar)}.
--
--  ON SERT: 28 (rpc_assign_test, student_id).
-- =====================================================================

create or replace function public.rpc_assign_test_many(
  p_class_id uuid, p_test_id uuid, p_student_ids uuid[],
  p_closes_at timestamptz default null,
  p_max_attempts int default 1)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_ids   uuid[];
  v_sid   uuid;
  v_res   jsonb;
  v_names text[] := '{}';
  v_title text;
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  select array_agg(distinct x) into v_ids from unnest(p_student_ids) x where x is not null;
  if v_ids is null or array_length(v_ids, 1) = 0 then
    raise exception 'Sagird secilmeyib.' using errcode = '22023';
  end if;
  if exists (select 1 from public.assignments a
              where a.class_id = p_class_id and a.test_id = p_test_id and a.student_id is null) then
    raise exception 'Bu test bu qrupa artiq butun qrup kimi verilib - sagirdler onu onsuz da gorur.'
      using errcode = '22023';
  end if;

  --  sira sabit olsun (ad uzre) - qaytarilan adlar da bu siradadir
  for v_sid in select s.id from public.students s where s.id = any(v_ids) order by s.full_name, s.id loop
    v_res := public.rpc_assign_test(p_class_id, p_test_id, p_closes_at, p_max_attempts, v_sid);
    v_names := v_names || (v_res->>'student');
    v_title := v_res->>'test';
  end loop;
  --  qrupda olmayan id - rpc_assign_test onsuz da dayandirir; siyahida olmayan
  --  (bazada hec yoxdur) id ise donguye dusmur, ona gore ayrica yoxlanilir
  if array_length(v_names, 1) is distinct from array_length(v_ids, 1) then
    raise exception 'Sagird bu qrupda tapilmadi.' using errcode = '22023';
  end if;

  return jsonb_build_object('count', array_length(v_ids, 1), 'test', v_title,
                            'students', to_jsonb(v_names));
end $$;

revoke all on function public.rpc_assign_test_many(uuid, uuid, uuid[], timestamptz, int) from public, anon;
grant execute on function public.rpc_assign_test_many(uuid, uuid, uuid[], timestamptz, int) to authenticated;

do $$ begin
  raise notice '934 OK - test qrupun secilmis sagirdlerine bir emeliyyatla verilir.';
end $$;
