-- =====================================================================
--  916 : AILE YOLU - «Hazirda hansi fesildesiniz?» (2026-10-06)
--
--  Gundelik paket (app.daily_topics) "kecilmis movzu"lardan qurulur.
--  Muellimsiz yolda kecileni valideyn deyir: bir fenn ucun CARI FESIL secir.
--   * fenn plani yoxdursa movcud rpc_plan_create ile yaradilir (usagin gizli sinfi + sinif kodu);
--   * secilen fesile QEDER (daxil) butun movzular "kecildi" olur, sonrakilar acilir;
--   * artiq kecilmis movzunun done_at tarixi saxlanilir (yeni tarix yazilmir).
--  rpc_family_chapters : fesil siyahisi + hazirki cari fesil (done olan son fesil).
--  rpc_family_set_current : cari fesli teyin edir (geri de qaytarmaq olar).
--  Tekrar isledile biler.
-- =====================================================================

create or replace function public.rpc_family_chapters(p_student uuid, p_subject text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_acc  uuid;
  v_lvl  uuid;
  v_subj uuid;
  v_cur  uuid;
  v_plan uuid;
  v_ch   jsonb;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  select c.level_id into v_lvl
    from public.students st join public.classes c on c.id = st.class_id
   where st.id = p_student and st.account_id = v_acc and st.is_active;
  if v_acc is null or v_lvl is null then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  select id into v_subj from public.subjects where slug = p_subject;
  if v_subj is null or not exists (select 1 from public.family_kids fk
                                    where fk.student_id = p_student and p_subject = any(fk.subjects)) then
    raise exception 'Bu fənn uşaq üçün seçilməyib.' using errcode = '22023';
  end if;

  select p.id into v_plan
    from public.class_plans p join public.students st on st.class_id = p.class_id
   where st.id = p_student and p.subject_id = v_subj;

  --  fesil = yarpaq movzularin valideyni (valideynsiz movzu ozu fesildir); sira = plan sirasi,
  --  plan hele yoxdursa agac sirasi (rpc_plan_create ile eyni)
  with src as (
    select t.id as tid, coalesce(par.id, t.id) as chid, coalesce(par.name, t.name) as chname,
           row_number() over (order by coalesce(par.sort, t.sort), coalesce(par.name, t.name), t.sort, t.name) as o
      from public.topics t
      left join public.topics par on par.id = t.parent_id
     where t.subject_id = v_subj and t.level_id = v_lvl
       and not exists (select 1 from public.topics c where c.parent_id = t.id)
  ),
  chs as (
    select s.chid, s.chname, min(s.o) as o, count(*) as n,
           count(i.done_at) as done_n
      from src s
      left join public.class_plan_items i on i.plan_id = v_plan and i.topic_id = s.tid
     group by s.chid, s.chname
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', c.chid, 'name', c.chname, 'topics', c.n,
                                               'done', c.done_n = c.n) order by c.o), '[]'::jsonb)
    into v_ch from chs c;

  --  cari fesil: keçilmiş movzusu olan en son fesil
  select (x->>'id')::uuid into v_cur
    from jsonb_array_elements(v_ch) with ordinality as e(x, n)
   where (x->>'done')::boolean
   order by e.n desc limit 1;

  return jsonb_build_object('ok', true, 'chapters', v_ch, 'current', v_cur);
end $$;
revoke all on function public.rpc_family_chapters(uuid, text) from public, anon;
grant execute on function public.rpc_family_chapters(uuid, text) to authenticated;

create or replace function public.rpc_family_set_current(p_student uuid, p_subject text, p_chapter uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid;
  v_cls   uuid;
  v_code  text;
  v_lvl   uuid;
  v_subj  uuid;
  v_plan  uuid;
  v_ord   int;
  v_n     int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  select st.class_id, l.code, l.id into v_cls, v_code, v_lvl
    from public.students st
    join public.classes c on c.id = st.class_id
    join public.levels l on l.id = c.level_id
   where st.id = p_student and st.account_id = v_acc and st.is_active;
  if v_acc is null or v_cls is null then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  select id into v_subj from public.subjects where slug = p_subject;
  if v_subj is null or not exists (select 1 from public.family_kids fk
                                    where fk.student_id = p_student and p_subject = any(fk.subjects)) then
    raise exception 'Bu fənn uşaq üçün seçilməyib.' using errcode = '22023';
  end if;

  select id into v_plan from public.class_plans where class_id = v_cls and subject_id = v_subj;
  if v_plan is null then
    perform public.rpc_plan_create(v_cls, p_subject, v_code);
    select id into v_plan from public.class_plans where class_id = v_cls and subject_id = v_subj;
  end if;

  --  secilen fesilin SON movzusunun sirasi
  select max(i.ord) into v_ord
    from public.class_plan_items i
    join public.topics t on t.id = i.topic_id
   where i.plan_id = v_plan and coalesce(t.parent_id, t.id) = p_chapter;
  if v_ord is null then
    raise exception 'Fəsil tapılmadı.' using errcode = '22023';
  end if;

  update public.class_plan_items set done_at = coalesce(done_at, now())
   where plan_id = v_plan and ord <= v_ord and done_at is null;
  update public.class_plan_items set done_at = null
   where plan_id = v_plan and ord > v_ord and done_at is not null;
  select count(*) into v_n from public.class_plan_items where plan_id = v_plan and done_at is not null;

  return jsonb_build_object('ok', true, 'done_topics', v_n);
end $$;
revoke all on function public.rpc_family_set_current(uuid, text, uuid) from public, anon;
grant execute on function public.rpc_family_set_current(uuid, text, uuid) to authenticated;
