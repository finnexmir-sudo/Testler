-- =====================================================================
--  119  DIAQNOSTIK TEST QORUYUCULARI
--
--  Canli yoxlamada goruldu: diaqnostik test "Test yig" siyahisinda adi
--  test kimi acilir - orada "Yeniden yig" ve "Qrupa teyin et" var.
--    * "Yeniden yig" -> rpc_regenerate_test -> rpc_generate_test(gen_rule)
--      gen_rule {kind:'diagnostic', per_topic:3} umumi generator ucun
--      menasizdir: test tesadufi suallarla dolar, is_diagnostic qalar,
--      xerite sehv cixar.
--    * "Qrupa teyin et" -> butun qrup "her movzudan 3 sual" testini
--      adi test kimi yazar; rpc_diagnostic_result ferdi teyinata baxdigi
--      ucun xerite de tapilmaz.
--  Iki RPC-ye qoruyucu; UI (muellim/app.js drawPaper) hemin duymeleri
--  diaqnostik testde gizledir.
--
--  rpc_assign_test     28_ferdi_tapsiriq.sql-deki govde + qoruyucu
--  rpc_regenerate_test 13_generator.sql-deki govde + qoruyucu
--  Grant-lar deyismir (her ikisi authenticated-dedir); 05_grants.sql-i
--  yene isletmek zererli deyil.
-- =====================================================================

create or replace function public.rpc_assign_test(
  p_class_id uuid, p_test_id uuid,
  p_closes_at timestamptz default null,
  p_max_attempts int default 1,
  p_student_id uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_test  public.tests%rowtype;
  v_stu   public.students%rowtype;
  v_id    uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid and not app.is_account_member(v_class.account_id) then
    raise exception 'Bu qrupa test teyin ede bilmezsiniz.' using errcode = '42501';
  end if;

  select * into v_test from public.tests where id = p_test_id and status = 'published';
  if not found then
    raise exception 'Test tapilmadi.' using errcode = '22023';
  end if;
  -- Muellim yalniz platforma testini ve ya OZ testini teyin ede biler
  if v_test.owner_type = 'educator' and v_test.owner_id <> v_uid then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  if p_max_attempts is null or p_max_attempts < 0 or p_max_attempts > 20 then
    raise exception 'Cehd sayi 0-20 araliginda olmalidir.' using errcode = '22023';
  end if;
  if p_closes_at is not null and p_closes_at <= now() then
    raise exception 'Son tarix kecmisde ola bilmez.' using errcode = '22023';
  end if;

  --  Odenisli test abunesiz teyin olunsa DALAN yaranir: muellim teyin
  --  edir, sagird acanda "abune lazimdir" gorur ve ise dusmur.
  --  Ona gore teyin anindaca dayandiririq.  (09_assignments.sql-den)
  if not v_test.is_free and not app.has_active_subscription(v_class.account_id) then
    raise exception 'Bu test abune paketine daxildir. Sagird onu aca bilmeyecek - once paketi genislendirin.'
      using errcode = '42501';
  end if;

  --  Diaqnostik test yalniz OZ sagirdine teyin olunur (118).  Qrupa
  --  verilse xerite tapilmaz (rpc_diagnostic_result ferdi teyinata baxir)
  --  ve basqa sagirdler "her movzudan 3 sual" testini adi test kimi
  --  yazardi.  Test veraqi sehifesindeki "Qrupa teyin et" bunu gizledir;
  --  bura ehtiyat qoruyucudur.
  if v_test.is_diagnostic
     and (p_student_id is null
          or p_student_id::text is distinct from v_test.gen_rule->>'student') then
    raise exception 'Diaqnostik test yalniz oz sagirdine verilir - sagird ekranindan "Diaqnostik test ver".'
      using errcode = '22023';
  end if;

  --  Ferdi teyinat: sagird HEMIN qrupun aktiv sagirdi olmalidir.
  --  (Yoxsa basqa hesabin sagirdine tapsiriq yazmaq olardi.)
  if p_student_id is not null then
    select * into v_stu from public.students
     where id = p_student_id and class_id = p_class_id and is_active;
    if not found then
      raise exception 'Sagird bu qrupda tapilmadi.' using errcode = '22023';
    end if;
  end if;

  insert into public.assignments
    (class_id, test_id, student_id, assigned_by, closes_at, max_attempts)
  values (p_class_id, p_test_id, p_student_id, v_uid, p_closes_at, p_max_attempts)
  on conflict (class_id, test_id, student_id) do update
    set closes_at = excluded.closes_at,
        max_attempts = excluded.max_attempts,
        opens_at = now(),
        assigned_by = excluded.assigned_by
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'test', v_test.title,
                            'student', v_stu.display_name);
end $$;

create or replace function public.rpc_regenerate_test(p_test_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_rule jsonb; v_title text;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;
  select gen_rule, title into v_rule, v_title from public.tests where id = p_test_id;
  --  Diaqnostik test "her movzudan 3 sual" qaydasi ile yigilir (118);
  --  umumi generator o qaydani tanimir ve testi adi testə cevirerdi.
  if v_rule->>'kind' = 'diagnostic' then
    raise exception 'Diaqnostik test yeniden yigilmir - sagird ekraninda "Yeniden diaqnostika" verin.'
      using errcode = '22023';
  end if;
  if v_rule is null then
    raise exception 'Bu test el ile qurulub - avtomatik yenilenmir.' using errcode = '22023';
  end if;
  return public.rpc_generate_test(v_rule, v_title, p_test_id);
end $$;
