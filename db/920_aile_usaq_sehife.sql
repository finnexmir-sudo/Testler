-- =====================================================================
--  920 : AILE YOLU - usagin oz sehifesi (2026-10-06)
--
--  rpc_student_family(token): usaq tetbiqi bunu ana ekran cizilmezden evvel cagirir.
--    family   : bu sagird «Ailem» yolundandirmi (family_kids-de var)
--    minutes  : valideynin sechdiyi gundelik vaxt
--    week/today_i : bu hefte hansi gunlerde calisib (B..B, Baki vaxti; testler + gundelik paket)
--    mastered : menimsedyi movzu sayi (917)
--    cur      : «Hazirda» - her fennin cari fesli (916)
--  Yalniz oz melumati: token usagin ozunundur.  Muellim yolundaki sagird ucun {family:false}.
--  ON SERT: 913-917.   Sonra 05_grants.sql (anon whitelist-e elave olunub).
-- =====================================================================
create or replace function public.rpc_student_family(p_token text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st    uuid := app.session_student(p_token);
  v_today date := (now() at time zone 'Asia/Baku')::date;
  v_mon   date;
  v_min   int;
  v_cls   uuid;
  v_out   jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select fk.minutes, st.class_id into v_min, v_cls
    from public.family_kids fk join public.students st on st.id = fk.student_id
   where fk.student_id = v_st;
  if not found then
    return jsonb_build_object('family', false);
  end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);

  with ev as (
    select (aa.answered_at at time zone 'Asia/Baku')::date as d
      from public.attempt_answers aa join public.attempts a on a.id = aa.attempt_id
     where a.student_id = v_st and aa.answered_at >= v_mon - 1
    union all
    select dp.day from public.daily_packs dp
     where dp.student_id = v_st and dp.day >= v_mon and jsonb_array_length(dp.answers) > 0
  )
  select jsonb_build_object(
           'family', true,
           'minutes', coalesce(v_min, 10),
           'today_i', v_today - v_mon,
           'week', (select jsonb_agg(case when exists (select 1 from ev where ev.d = v_mon + g) then 1 else 0 end order by g)
                      from generate_series(0, 6) g),
           'mastered', (select count(*) from public.topic_mastery m where m.student_id = v_st and m.state = 'mastered'),
           'cur', coalesce((
             select jsonb_agg(jsonb_build_object('subject', y.sname, 'chapter', y.cname) order by y.sname)
               from (select distinct on (p.id) sb.name sname, coalesce(par.name, t.name) cname
                       from public.class_plan_items i
                       join public.class_plans p on p.id = i.plan_id and p.class_id = v_cls
                       join public.subjects sb on sb.id = p.subject_id
                       join public.topics t on t.id = i.topic_id
                       left join public.topics par on par.id = t.parent_id
                      where i.done_at is not null
                      order by p.id, i.ord desc) y), '[]'::jsonb))
    into v_out;
  return v_out;
end $$;
revoke all on function public.rpc_student_family(text) from public;
grant execute on function public.rpc_student_family(text) to anon, authenticated;
