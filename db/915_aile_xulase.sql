-- =====================================================================
--  915 : AILE YOLU - valideyn xulasesi + silme (2026-10-06)
--
--  1. rpc_family_summary : «Ailem» ekranindaki her usaq ucun «bu gun / bu hefte / diqqet»
--       bu gun    : neçə sual cavablandi, neçəsi duz (testler + gundelik paket)
--       bu hefte  : Bazar ertesi-Bazar, hansı gunlerde calisib (Baki vaxti)
--       diqqet    : en zeif movzu (en azi 4 cavab, duz faizi 70-den asagi) - yalniz atamli test cavablarindan
--  2. rpc_family_delete_child   : usagi ve BUTUN melumatini (cavablar, razilik, kod, abune, diaqnostika testleri) siler
--  3. rpc_family_delete_account : butun aileni ve valideyn hesabini siler (geri qaytarilmir)
--
--  Silme tam silmedir (cascade): usaq silinende nəticələri, razılığı, push abunəsi, valideyn sessiyaları da gedir.
--  ON SERT: 913, 914.
-- =====================================================================

create or replace function public.rpc_family_summary()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid;
  v_today date := (now() at time zone 'Asia/Baku')::date;
  v_mon   date;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then return '[]'::jsonb; end if;
  v_mon := v_today - (extract(isodow from v_today)::int - 1);       -- bu heftenin Bazar ertesi

  return coalesce((
    with kids as (
      select st.id from public.students st where st.account_id = v_acc and st.is_active
    ), ev as (
      --  testlerde verilen cavablar
      select a.student_id, (aa.answered_at at time zone 'Asia/Baku')::date as d, 1 as q, case when aa.is_correct then 1 else 0 end as ok
        from public.attempt_answers aa
        join public.attempts a on a.id = aa.attempt_id
        join kids k on k.id = a.student_id
       where aa.answered_at >= v_mon - 1
      union all
      --  «Bu gunun 5 suali» paketinden cavablar
      select dp.student_id, dp.day, jsonb_array_length(dp.answers),
             (select count(*) from jsonb_array_elements(dp.answers) e where (e->>'ok')::boolean)::int
        from public.daily_packs dp
        join kids k on k.id = dp.student_id
       where dp.day >= v_mon and jsonb_array_length(dp.answers) > 0
    )
    select jsonb_agg(jsonb_build_object(
             'id', k.id,
             'today_q',  coalesce((select sum(q) from ev where ev.student_id = k.id and ev.d = v_today), 0),
             'today_ok', coalesce((select sum(ok) from ev where ev.student_id = k.id and ev.d = v_today), 0),
             'week',     (select jsonb_agg(case when exists (select 1 from ev where ev.student_id = k.id and ev.d = v_mon + g and ev.q > 0) then 1 else 0 end order by g)
                            from generate_series(0, 6) g),
             'today_i',  v_today - v_mon,
             'weak',     (select jsonb_build_object('topic', z.name, 'percent', z.p, 'n', z.n)
                            from (select t.name, count(*)::int n,
                                         round(count(*) filter (where aa.is_correct) * 100.0 / count(*))::int p
                                    from public.attempt_answers aa
                                    join public.attempts at on at.id = aa.attempt_id and at.student_id = k.id and at.status = 'submitted'
                                    join public.topics t on t.id = aa.topic_id
                                   where aa.answered_at > now() - interval '45 days'
                                   group by t.id, t.name
                                  having count(*) >= 4
                                     and count(*) filter (where aa.is_correct) * 100.0 / count(*) < 70
                                   order by count(*) filter (where aa.is_correct) * 100.0 / count(*), count(*) desc
                                   limit 1) z)
           ))
      from kids k), '[]'::jsonb);
end $$;

create or replace function public.rpc_family_delete_child(p_student uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_cls uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  select st.class_id into v_cls from public.students st
   where st.id = p_student and st.account_id = v_acc;
  if v_acc is null or not found then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  --  uşağa verilmiş diaqnostika testləri (gen_rule-da şagirdin id-si) ayrıca silinir
  delete from public.tests where gen_rule->>'student' = p_student::text;
  delete from public.students where id = p_student;
  if v_cls is not null then
    delete from public.classes c where c.id = v_cls and not exists (select 1 from public.students s where s.class_id = c.id);
  end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.rpc_family_delete_account()
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if exists (select 1 from public.accounts a where a.owner_id = v_uid and a.type <> 'parent') then
    raise exception 'Bu istifadəçinin müəllim hesabı da var — onu bu yolla silmək olmaz. info@bil10.az ilə əlaqə saxlayın.' using errcode = '42501';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is not null then
    delete from public.tests where gen_rule->>'student' in (select s.id::text from public.students s where s.account_id = v_acc);
    delete from public.tests where owner_type = 'educator' and owner_id = v_uid;
    delete from public.accounts where id = v_acc;           -- qrup, usaq, abune, razilig, push... cascade
  end if;
  delete from public.user_roles where user_id = v_uid;
  delete from public.profiles where id = v_uid;
  delete from auth.users where id = v_uid;
  return jsonb_build_object('ok', true);
end $$;

revoke all on function public.rpc_family_summary()              from public, anon;
revoke all on function public.rpc_family_delete_child(uuid)     from public, anon;
revoke all on function public.rpc_family_delete_account()       from public, anon;
grant execute on function public.rpc_family_summary()           to authenticated;
grant execute on function public.rpc_family_delete_child(uuid)  to authenticated;
grant execute on function public.rpc_family_delete_account()    to authenticated;
