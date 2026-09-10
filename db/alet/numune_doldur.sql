-- =====================================================================
--  Bil10 — ŞƏXSİ HESABI NÜMUNƏ MƏLUMATI İLƏ DOLDURUR
--
--  KİMİN ÜÇÜN:  samirmiroglu@gmail.com hesabı
--  NƏ EDİR:     həmin hesabın MÖVCUD qrup, şagird və testlərini silir,
--               yerinə dolu bir nümunə qurur: 3 qrup, 25 şagird,
--               45 günlük nəticə, dərs planı, davamiyyət, ödəniş
--               dəftəri, valideyn kodları və həftəlik cədvəl.
--               Sonda admin səhifəsi təmiz qalsın deyə nümunə
--               «Bizə yaz» və sual bildirişi sətirlərini silir.
--
--  TƏHLÜKƏSİZLİK
--    · Yalnız BU hesabın məlumatına toxunur.  Başqa müəllimlərin
--      qrupları, sual bankı və platforma testləri toxunulmaz qalır.
--    · Hər şey BİR əməliyyatdadır: səhv olsa heç nə dəyişmir.
--    · Hesab "nümunə" kimi işarələnmir — yəni admin saylarında
--      görünməyə davam edir və 24 saatlıq təmizləməyə DÜŞMÜR.
--      (Bu, ən vacib qorunmadır: app.demo_build hesabı is_demo
--       edir, biz onu dərhal geri qaytarırıq.)
--
--  İŞLƏTMƏ:  Supabase → SQL Editor → hamısını yapışdır → Run
-- =====================================================================
do $$
declare
  v_email  text := 'samirmiroglu@gmail.com';
  v_owner  uuid;
  v_acc    uuid;
  v_demo   boolean;
  v_subj   text[];
  v_ad     text;
  v_res    jsonb;
  r        record;
  i        int;
begin
  -- ---------------------------------------------------------- hesabı tap
  select u.id into v_owner from auth.users u where lower(u.email) = lower(v_email);
  if v_owner is null then
    raise exception 'Bu e-poçtla istifadəçi tapılmadı: %', v_email;
  end if;

  select a.id, a.is_demo, a.subjects into v_acc, v_demo, v_subj
    from public.accounts a
   where a.owner_id = v_owner
   order by a.created_at
   limit 1;
  if v_acc is null then
    raise exception 'Bu istifadəçinin hesabı yoxdur: %', v_email;
  end if;

  select p.full_name into v_ad from public.profiles p where p.id = v_owner;

  raise notice 'Hesab tapıldı: % (%)', v_acc, v_email;

  -- --------------------------------------------- nümunə məlumatı qurulur
  --  p_fixed = false — DEMO0001 kimi sabit kodlar İŞLƏNMİR;
  --  onlar paylaşılan nümunə hesabındır, toqquşmasın.
  v_res := app.demo_build(v_owner, v_acc, false);

  -- ------------------------------------------- yan təsirləri geri qaytar
  --  demo_build hesabı is_demo edir və fənni riyaziyyata salır.
  --  is_demo qalsa, hesab 24 saat sonra SİLİNƏ bilər — geri qaytarılır.
  update public.accounts
     set is_demo  = coalesce(v_demo, false),
         subjects = coalesce(v_subj, subjects)
   where id = v_acc;

  --  Ad yalnız boş idisə dəyişir; hər ehtimala qarşı geri qoyulur.
  if coalesce(v_ad, '') <> '' then
    update public.profiles set full_name = v_ad where id = v_owner;
  end if;

  -- --------------------------------------------------------- paket
  --  demo_build hesaba 25 YERLİK paket qoyur və düz 25 şagird yaradır —
  --  nəticədə panel «Paketin limiti dolub» qırmızı xəbərdarlığı verir.
  --  Kiməsə göstərəndə bu, ən pis görünən şeydir.  Ona görə həmin
  --  paket götürülür; hesabda başqa aktiv abunə yoxdursa, şagird
  --  sayında limiti olmayan «Hər şagird üçün» paketi verilir.
  delete from public.subscriptions sub
   using public.plans p
   where sub.account_id = v_acc and p.id = sub.plan_id and p.slug = 'repetitor-25';

  if not app.has_active_subscription(v_acc) then
    insert into public.subscriptions (account_id, plan_id, status, current_period_end)
    select v_acc, p.id, 'active', now() + interval '365 days'
      from public.plans p where p.slug = 'sagird-basi';
  end if;

  -- ------------------------------------------ hər şagirdə valideyn kodu
  --  demo_build yalnız BİR şagirdə valideyn kodu verir.  Valideyn
  --  ekranını göstərə bilmək üçün hamısına verilir.
  for r in select s.id from public.students s
            where s.account_id = v_acc and s.parent_code is null
  loop
    for i in 1..20 loop
      begin
        update public.students set parent_code = 'V' || app.gen_login_code(7)
         where id = r.id;
        exit;
      exception when unique_violation then null;
      end;
    end loop;
  end loop;

  -- ------------------------------- 11-ci sinif qrupunu TAM doldur
  --  demo_build bu qrupda BİR test verir və bir şagirdi (4-cü)
  --  qəsdən buraxır — «kim işləməyib» halını göstərmək üçün.
  --  Kiməsə nümayiş edəndə isə boş tab pis görünür: hesabatda
  --  «Hələ test işləməyib» yazır.  Ona görə həmin qrupa daha üç
  --  test verilir və BÜTÜN şagirdlər hamısını işləyir.
  declare
    v_c3   uuid;
    v_riy  uuid;
    v_l11  record;
    v_pl3  uuid;
    v_it   uuid[];
    v_par  record;
    v_tad  text;
    v_test uuid;
    v_at   timestamptz;
    j      int;
  begin
    select id into v_riy from public.subjects where slug = 'riyaziyyat';
    select l.* into v_l11 from public.levels l where l.code = '11' order by l.sort limit 1;
    select c.id into v_c3 from public.classes c
      where c.account_id = v_acc and c.level_id = v_l11.id
      order by c.created_at limit 1;

    if v_c3 is not null then
      select id into v_pl3 from public.class_plans where class_id = v_c3 limit 1;
      select array_agg(id order by ord) into v_it
        from public.class_plan_items where plan_id = v_pl3;

      --  2-ci, 3-cü və 4-cü mövzudan ev tapşırığı
      if v_it is not null then
        for j in 2..least(4, cardinality(v_it)) loop
          v_at := now() - make_interval(days => 30 - j * 6);
          update public.class_plan_items set done_at = v_at where id = v_it[j];
          select * into v_par from app.pack_topic(
            (select topic_id from public.class_plan_items where id = v_it[j]));
          --  Başlıqda FƏSLİN yox, MÖVZUNUN öz adı işlənir: pack_topic
          --  fəsli qaytarır, ona görə üç testin adı eyni çıxırdı və
          --  tarixçə təkrar görünürdü.  Sual hovuzu yenə fəsildəndir.
          select t.name into v_tad
            from public.class_plan_items it
            join public.topics t on t.id = it.topic_id
           where it.id = v_it[j];
          v_test := app.demo_test(v_owner, v_riy, v_l11.id, v_l11.program_id,
                      array[v_par.o_id], 10,
                      coalesce(v_tad, v_par.o_name) || ' — yoxlama',
                      jsonb_build_object('pack','hw','topics',
                        jsonb_build_array(v_par.o_id::text)),
                      '{1,2,3}', null, false, v_at);
          update public.class_plan_items set test_id = v_test where id = v_it[j];
          insert into public.assignments
            (class_id, test_id, assigned_by, opens_at, closes_at, max_attempts, created_at)
          values (v_c3, v_test, v_owner, v_at, v_at + interval '7 days', 1, v_at);
        end loop;
      end if;

      --  Qrupun BÜTÜN şagirdləri, BÜTÜN tapşırıqları işləyir —
      --  buraxılmış şagird də daxil.  Bacarıq şagirdə görə sabitdir
      --  ki, hesabatda mənalı fərq görünsün.
      for r in
        select s.id as sid, a.test_id,
               row_number() over (order by s.created_at) as sira
          from public.students s
          join public.assignments a on a.class_id = s.class_id
         where s.class_id = v_c3
           and not exists (select 1 from public.attempts att
                            where att.student_id = s.id and att.test_id = a.test_id)
      loop
        perform app.demo_attempt(r.sid, r.test_id, v_c3,
                  (array[0.90, 0.82, 0.74, 0.64, 0.55])[((r.sira - 1) % 5) + 1],
                  '{}', now() - make_interval(days => 1 + floor(random() * 20)::int));
      end loop;
    end if;
  end;

  -- ------------------------------------------------- həftəlik cədvəl
  --  db/177 tətbiq olunubsa: qruplara dərs saatı verilir ki, İcmalda
  --  «Bu gün dərs var» və «Bütün həftə» görünsün.
  if to_regclass('public.class_schedule') is not null then
    delete from public.class_schedule cs
     using public.classes c
     where cs.class_id = c.id and c.account_id = v_acc;

    i := 0;
    for r in select c.id from public.classes c
              where c.account_id = v_acc order by c.created_at
    loop
      i := i + 1;
      --  1-ci qrup: B.e + C.a 16:00 · 2-ci: Ç.a + Cümə 18:00
      --  3-cü: Şənbə 11:00.  Bugünkü dərs mütləq düşsün deyə
      --  birinci qrupa bugünkü həftə günü də əlavə olunur.
      if i = 1 then
        insert into public.class_schedule (class_id, weekday, starts_at, mins)
        values (r.id, 1, '16:00', 60), (r.id, 4, '16:00', 60)
        on conflict do nothing;
        insert into public.class_schedule (class_id, weekday, starts_at, mins)
        values (r.id, extract(isodow from (now() at time zone 'Asia/Baku'))::int, '16:00', 60)
        on conflict do nothing;
      elsif i = 2 then
        insert into public.class_schedule (class_id, weekday, starts_at, mins)
        values (r.id, 2, '18:00', 90), (r.id, 5, '18:00', 90)
        on conflict do nothing;
      else
        insert into public.class_schedule (class_id, weekday, starts_at, mins)
        values (r.id, 6, '11:00', 90)
        on conflict do nothing;
      end if;
    end loop;
  end if;

  -- -------------------------------------------------------------------
  --  ADMİN EKRANI TƏMİZ QALSIN
  --  app.demo_build hesaba bir «Bizə yaz» təklifi və bir sual bildirişi
  --  yazır.  Göstərmə zamanı admin səhifəsində nümunə şikayət
  --  görünməsin deyə ikisini də silirik.
  --  Qeyd: «Sual keyfiyyəti» kartı buradan gəlmir — o, cavablardan
  --  hesablanır (rpc_admin_qstats), silinən sətir yoxdur.
  -- -------------------------------------------------------------------
  delete from public.feedback where account_id = v_acc;
  delete from public.question_reports qr
   using public.students s
   where qr.student_id = s.id and s.account_id = v_acc;
  delete from public.question_reports where account_id = v_acc;

  raise notice 'Hazırdır. Nəticə: %', v_res;
end $$;

-- =====================================================================
--  YOXLAMA — nə yarandı
-- =====================================================================
select 'qrup'     as nə, count(*) as say from public.classes  c
  join public.accounts a on a.id = c.account_id
  join auth.users u on u.id = a.owner_id where lower(u.email)='samirmiroglu@gmail.com'
union all
select 'şagird', count(*) from public.students s
  join public.accounts a on a.id = s.account_id
  join auth.users u on u.id = a.owner_id where lower(u.email)='samirmiroglu@gmail.com'
union all
select 'test', count(*) from public.tests t
  join auth.users u on u.id = t.owner_id
 where t.owner_type='educator' and lower(u.email)='samirmiroglu@gmail.com'
union all
select 'cəhd', count(*) from public.attempts at
  join public.students s on s.id = at.student_id
  join public.accounts a on a.id = s.account_id
  join auth.users u on u.id = a.owner_id where lower(u.email)='samirmiroglu@gmail.com';

-- =====================================================================
--  GÖSTƏRMƏK ÜÇÜN KODLAR — şagird və valideyn girişini canlı aç
-- =====================================================================
select c.name as qrup, s.display_name as şagird,
       s.login_code as şagird_kodu, s.parent_code as valideyn_kodu
  from public.students s
  join public.classes c on c.id = s.class_id
  join public.accounts a on a.id = s.account_id
  join auth.users u on u.id = a.owner_id
 where lower(u.email) = 'samirmiroglu@gmail.com'
 order by c.created_at, s.created_at
 limit 6;
