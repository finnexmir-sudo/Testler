--  220: «X ZEIF GEDIR · 5 SAGIRD» -> HEMIN 5 SAGIRD
--
--  Istifadeci: «uygunsuzluq var, oldu 7? ilkinde say ver, acilanda
--  hemin sagirdleri gostersin».
--
--  Ne olmusdu: Icmal setri 5 deyirdi, acilan qrup hesabati 7.  Iki
--  ayri qayda idi:
--    rpc_home.topics          -> sagirde en azi app.alert_weak_min() (5) cavab
--    rpc_class_report.topics  -> en azi app.min_topic_answers()  (3) cavab
--  Eyni movzu, eyni qrup, iki reqem.  CLAUDE.md 5-ci bend: eyni reqem
--  iki yerde yazilirsa, EYNI sorgudan gelmelidir.
--
--  Bu funksiya Icmal setrinin OZ qaydasini isledir - ona gore setirdeki
--  say ile acilan siyahinin uzunlugu her zaman eyni olur.
set search_path = public, app;

create or replace function public.rpc_topic_weak(p_class_id uuid, p_topic_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
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
    raise exception 'Bu qrupun hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'class',   jsonb_build_object('id', v_class.id, 'name', v_class.name),
    'topic',   (select jsonb_build_object('id', t.id, 'name', t.name,
                         'subject', sub.name, 'subject_slug', sub.slug,
                         'level', lv.code)
                  from public.topics t
                  left join public.subjects sub on sub.id = t.subject_id
                  left join public.levels lv on lv.id = t.level_id
                 where t.id = p_topic_id),
    --  movzunun BUTUN qrup uzre menimseme faizi
    'ratio',   (select round(count(*) filter (where aa.is_correct) * 100.0 / nullif(count(*), 0), 0)
                  from public.attempt_answers aa
                  join public.attempts a on a.id = aa.attempt_id and a.status = 'submitted'
                  join public.students s on s.id = a.student_id
                                        and s.class_id = p_class_id and s.is_active
                 where aa.topic_id = p_topic_id),
    'students', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', w.id, 'name', w.full_name, 'n', w.n,
               'ok', w.ok, 'ratio', round(w.ok * 100.0 / w.n, 0))
             order by w.ok * 100.0 / w.n, w.full_name)
        from (
          select s.id, s.full_name, count(*) n,
                 count(*) filter (where aa.is_correct) ok
            from public.attempt_answers aa
            join public.attempts a on a.id = aa.attempt_id and a.status = 'submitted'
            join public.students s on s.id = a.student_id
                                  and s.class_id = p_class_id and s.is_active
           where aa.topic_id = p_topic_id
           group by s.id, s.full_name
          having count(*) >= app.alert_weak_min()
             and count(*) filter (where aa.is_correct) * 100.0 / count(*) < app.alert_weak_pct()
        ) w), '[]'::jsonb));
end $$;

revoke all on function public.rpc_topic_weak(uuid, uuid) from public, anon;
grant execute on function public.rpc_topic_weak(uuid, uuid) to authenticated;
