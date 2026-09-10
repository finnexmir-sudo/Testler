-- =====================================================================
--  Bil10 — ŞƏXSİ HESABI NÜMUNƏ MƏLUMATI İLƏ DOLDURUR
--
--  KİMİN ÜÇÜN:  samirmiroglu@gmail.com hesabı
--  NƏ EDİR:     həmin hesabın MÖVCUD qrup, şagird və testlərini silir,
--               yerinə dolu bir nümunə qurur: 3 qrup, 25 şagird,
--               45 günlük nəticə, dərs planı, davamiyyət, ödəniş
--               dəftəri, valideyn kodları və həftəlik cədvəl.
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
