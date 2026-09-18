-- =====================================================================
--  209 : «BU GUN» KARTI - MUELLIMIN GUNDELIK BIR DEQIQESI (2026-09-18)
--
--  Problem: muellim panele girir, ekranda ON reqem var, amma «indi ne
--  edim?» sualina cavab yoxdur.  Hunide gorunur: qeydiyyatdan kecenin
--  ucde biri qrup qurur, qrup quranin yarisi sagird elave edir, biri
--  cehd alir.  Muellim geri qayitmir, cunki her defe ozu qerar
--  vermelidir (decision fatigue).
--
--  Indi Icmalin ustunde bir setir: «Dunen 8 sagird isledi · 3-u
--  Kesrlerde ilisdi» ve BIR TOXUNUS: «5 sual gonder».
--
--  Iki hisse:
--    1. rpc_home -> 'bugun' (marker: 'paid', v_paid,).  Pulsuzda da
--       gelir - «dunen nece sagird isledi» abune teleb etmir.
--       En zeif movzu ise 'topics'-dendir (201, yalniz abuneli).
--    2. rpc_quick_assign(qrup, movzu, say): test yigir VE tapsiriq
--       kimi verir - bir cagirisda.  Evvel uc addim idi: Test yig ->
--       generator -> tapsiriq formasi.
--
--  Vaxt zonasi: Asia/Baku (175-deki kimi) - «dunen» teqvim gunudur.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. rpc_home -> 'bugun'
-- ---------------------------------------------------------------------
do $$
declare
  v_src  text := pg_get_functiondef('public.rpc_home(uuid)'::regprocedure);
  v_mark text := '''paid'', v_paid,';
  v_add  text := '''paid'', v_paid,
    ''bugun'', (
      with gun as (
        select (now() at time zone ''Asia/Baku'')::date d
      ),
      cehd as (
        select a.student_id,
               (a.finished_at at time zone ''Asia/Baku'')::date d
          from public.attempts a
          join public.students s on s.id = a.student_id
         where s.account_id = v_acc and s.is_active and a.status = ''submitted''
           and a.finished_at >= now() - interval ''30 days''
      )
      select jsonb_build_object(
        --  dunen / bu gun nece SAGIRD isledi (cehd sayi yox - adam sayi)
        ''dunen'',  (select count(distinct student_id) from cehd, gun where cehd.d = gun.d - 1),
        ''bu_gun'', (select count(distinct student_id) from cehd, gun where cehd.d = gun.d),
        --  7 gundur hec ne etmeyen aktiv sagird
        ''susan'', (select count(*) from public.students s
                     where s.account_id = v_acc and s.is_active
                       and not exists (select 1 from public.attempts a
                                        where a.student_id = s.id and a.status = ''submitted''
                                          and a.finished_at >= now() - interval ''7 days'')),
        ''aktiv'', (select count(*) from public.students s
                     where s.account_id = v_acc and s.is_active),
        --  bu gun tapsiriq verilibmi (kart «gonderdiniz» desin)
        ''verdim'', (select count(*) from public.assignments asg
                      join public.classes c on c.id = asg.class_id
                     where c.account_id = v_acc
                       and (asg.created_at at time zone ''Asia/Baku'')::date
                           = (select d from gun)))
    ),';
begin
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception 'rpc_home: paid markeri 1 defe olmalidir';
  end if;
  if position('''bugun''' in v_src) > 0 then
    raise notice '209 artiq tetbiq olunub, kecilir';
    return;
  end if;
  execute replace(v_src, v_mark, v_add);
end $$;

revoke all on function public.rpc_home(uuid) from public, anon;
grant execute on function public.rpc_home(uuid) to authenticated;

-- ---------------------------------------------------------------------
--  2. Bir toxunus: test yig + tapsiriq ver
-- ---------------------------------------------------------------------
create or replace function public.rpc_quick_assign(
  p_class_id uuid, p_topic_id uuid, p_count int default 5)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_top   record;
  v_n     int := least(greatest(coalesce(p_count, 5), 3), 20);
  v_rule  jsonb;
  v_gen   jsonb;
  v_test  uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid
     and not app.is_account_member(v_class.account_id)
     and not app.is_admin() then
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  --  hazir bankdan yigmaq abune paketine daxildir (generator da yoxlayir,
  --  amma burada ANLASILAN xeta veririk - kart duymesi ucun)
  if not app.has_active_subscription(v_class.account_id) then
    raise exception 'Hazir suallardan test yigmaq abune paketi ilədir.' using errcode = '42501';
  end if;

  select t.id, t.name, sub.slug subject_slug, lv.code level
    into v_top
    from public.topics t
    left join public.subjects sub on sub.id = t.subject_id
    left join public.levels   lv  on lv.id  = t.level_id
   where t.id = p_topic_id;
  if not found then
    raise exception 'Movzu tapilmadi.' using errcode = '22023';
  end if;

  v_rule := jsonb_build_object(
    'pool', 'all', 'count', v_n,
    'topics', jsonb_build_array(p_topic_id::text),
    'class', p_class_id::text);
  if v_top.subject_slug is not null then v_rule := v_rule || jsonb_build_object('subject', v_top.subject_slug); end if;
  if v_top.level is not null then v_rule := v_rule || jsonb_build_object('level', v_top.level); end if;

  v_gen := public.rpc_generate_test(v_rule, 'Düzəliş — ' || v_top.name, null, v_class.account_id);
  v_test := (v_gen->>'test_id')::uuid;
  if v_test is null then
    raise exception 'Test yigilmadi - bu movzuda kifayet qeder sual yoxdur.' using errcode = '22023';
  end if;
  perform public.rpc_assign_test(p_class_id, v_test);

  return jsonb_build_object(
    'ok', true, 'test_id', v_test,
    'count', coalesce((v_gen->>'count')::int, v_n),
    'topic', v_top.name, 'class', v_class.name);
end $$;
revoke all on function public.rpc_quick_assign(uuid, uuid, int) from public, anon;
grant execute on function public.rpc_quick_assign(uuid, uuid, int) to authenticated;
