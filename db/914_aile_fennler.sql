-- =====================================================================
--  914 : AILE YOLU - butun fennler + yoxlamanin merheleli verilmesi (2026-10-06)
--
--  913-un ustune.  Sahib (06.10): «butun fennleri de secmek olarmi?»
--   * fenn secimi artiq 5 ile mehdud deyil (en cox 12);
--   * baslangic yoxlama secilen fennlerin ILK 3-u ucun derhal yaranir (usaq bezmesin: her fenn ~20 deq);
--   * qalan fennler ucun valideyn «Ailem» ekranindan bir toxunusla verir: rpc_family_diag;
--   * rpc_family_children her fenn ucun veziyyet qaytarir (none | open | done).
--   * gundelik vaxt secimi 5/10/15/20/30 deq (evvel max 15: abituriyent/yuxari sinifler ucun az idi);
--  913-deki iki funksiya (rpc_family_add_child, rpc_family_children) yeniden yazilir - qalan gövde hərfən eynidir.
-- =====================================================================

create or replace function public.rpc_family_add_child(
  p_name text, p_level_code text, p_subjects text[], p_minutes int default 10, p_consent boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid;
  v_name  text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_subs  text[] := '{}';
  v_s     text;
  v_cls   jsonb;
  v_stu   jsonb;
  v_sid   uuid;
  v_diag  jsonb := '[]'::jsonb;
  v_res   jsonb;
  v_n     int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.family_ok() then
    raise exception 'Bu xidmət hələ açılmayıb. Tezliklə.' using errcode = '42501';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    raise exception 'Əvvəl valideyn hesabı açın.' using errcode = '42501';
  end if;
  if coalesce(p_consent, false) is not true then
    raise exception 'Uşağın məlumatlarının saxlanmasına razılıq lazımdır.' using errcode = '22023';
  end if;
  if length(v_name) < 2 or length(v_name) > 60 then
    raise exception 'Uşağın adını yazın (2–60 simvol).' using errcode = '22023';
  end if;
  if coalesce(btrim(p_level_code), '') !~ '^[0-9]{1,2}$'
     or not exists (select 1 from public.levels where code = btrim(p_level_code)) then
    raise exception 'Sinif seçin.' using errcode = '22023';
  end if;
  if p_minutes is null or p_minutes not in (5, 10, 15, 20, 30) then p_minutes := 10; end if;

  --  Fennler: yalniz movcud slug, tekrarsiz, en cox 5
  foreach v_s in array coalesce(p_subjects, '{}') loop
    if exists (select 1 from public.subjects where slug = v_s) and not (v_s = any(v_subs)) then
      v_subs := v_subs || v_s;
    end if;
    exit when array_length(v_subs, 1) >= 12;
  end loop;
  if coalesce(array_length(v_subs, 1), 0) = 0 then
    raise exception 'Ən azı bir fənn seçin.' using errcode = '22023';
  end if;

  select count(*) into v_n from public.students where account_id = v_acc and is_active;
  if v_n >= 6 then
    raise exception 'Bir hesaba ən çox 6 uşaq əlavə olunur.' using errcode = '22023';
  end if;

  --  gizli «self_study» qrup (sinifi ile) + sagird + kodlar (movcud RPC-ler, eyni qaydalar)
  v_cls := public.rpc_create_class(v_acc, v_name, 'self_study', null, btrim(p_level_code));
  v_stu := public.rpc_add_student((v_cls->>'id')::uuid, v_name, split_part(v_name, ' ', 1));      -- gorunen ad: ilk ad (Huseyn)
  v_sid := (v_stu->>'id')::uuid;

  insert into public.consents (student_id, granted_by, kind, evidence)
  values (v_sid, v_uid, 'parental',
          jsonb_build_object('version', 'aile-v3', 'text', 'Usagin adi ve neticeleri yalniz valideyne gorunur, hec yerde paylasilmir. Raziyam.',
                             'at', now(), 'source', 'family_add_child'));

  insert into public.family_kids (student_id, subjects, minutes) values (v_sid, v_subs, p_minutes);

  --  Baslangic diaqnostika: secilen fennlerin ilk 3-u (movcud rpc; alinmasa usaq elave edilmesi pozulmur)
  for v_s in select unnest(v_subs[1:3]) loop
    begin
      v_res := public.rpc_diagnostic_create(v_sid, v_s, 14);
      v_diag := v_diag || jsonb_build_object('subject', v_s, 'ok', true, 'questions', coalesce(v_res->>'questions', null));
    exception when others then
      v_diag := v_diag || jsonb_build_object('subject', v_s, 'ok', false, 'error', left(sqlerrm, 160));
    end;
  end loop;

  return jsonb_build_object('ok', true, 'student_id', v_sid, 'name', v_stu->>'display_name',
                            'login_code', v_stu->>'login_code', 'diagnostics', v_diag,
                            'subjects_total', coalesce(array_length(v_subs, 1), 0));
end $$;

create or replace function public.rpc_family_children()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null then
    return jsonb_build_object('has_account', false);
  end if;
  return jsonb_build_object(
    'has_account', true,
    'account', (select jsonb_build_object('name', a.name,
                        'locked', app.account_locked(a.id),
                        'active', app.has_active_subscription(a.id),
                        'trial_end', (select max(s.current_period_end) from public.subscriptions s
                                       where s.account_id = a.id and s.status in ('trialing', 'active')))
                  from public.accounts a where a.id = v_acc),
    'kids', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', st.id,
               'name', st.display_name,
               'sinif', (select l.code from public.classes c join public.levels l on l.id = c.level_id where c.id = st.class_id),
               'subjects', coalesce(fk.subjects, '{}'),
               'subject_names', coalesce((select jsonb_agg(sj.name order by sj.sort, sj.name) from public.subjects sj
                                           where sj.slug = any(coalesce(fk.subjects, '{}'))), '[]'::jsonb),
               'minutes', coalesce(fk.minutes, 10),
               'login_code', st.login_code,
               'subject_diag', coalesce((
                   select jsonb_agg(jsonb_build_object('slug', sj.slug, 'name', sj.name, 'state',
                            case when exists (select 1 from public.attempts at join public.tests t on t.id = at.test_id
                                               where at.student_id = st.id and t.is_diagnostic and t.subject_id = sj.id and at.status = 'submitted')
                                 then 'done'
                                 when exists (select 1 from public.assignments a join public.tests t on t.id = a.test_id
                                               where a.student_id = st.id and t.is_diagnostic and t.subject_id = sj.id)
                                 then 'open'
                                 else 'none' end)
                            order by sj.sort, sj.name)
                     from public.subjects sj where sj.slug = any(coalesce(fk.subjects, '{}'))), '[]'::jsonb),
               'diag_total', (select count(*) from public.assignments a join public.tests t on t.id = a.test_id
                               where a.student_id = st.id and t.is_diagnostic),
               'diag_done',  (select count(distinct at.test_id) from public.attempts at join public.tests t on t.id = at.test_id
                               where at.student_id = st.id and t.is_diagnostic and at.status = 'submitted'))
             order by st.created_at, st.id)
        from public.students st
        left join public.family_kids fk on fk.student_id = st.id
       where st.account_id = v_acc and st.is_active), '[]'::jsonb));
end $$;

-- ------------------------------------------------------------ bir fenn ucun yoxlama ver
create or replace function public.rpc_family_diag(p_student uuid, p_subject text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_res jsonb;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  if v_acc is null or not exists (select 1 from public.students st where st.id = p_student and st.account_id = v_acc and st.is_active) then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  if not exists (select 1 from public.family_kids fk where fk.student_id = p_student and p_subject = any(fk.subjects)) then
    raise exception 'Bu fənn uşaq üçün seçilməyib.' using errcode = '22023';
  end if;
  v_res := public.rpc_diagnostic_create(p_student, p_subject, 14);
  return jsonb_build_object('ok', true, 'existing', coalesce((v_res->>'existing')::boolean, false),
                            'questions', v_res->>'questions');
end $$;
revoke all on function public.rpc_family_diag(uuid, text) from public, anon;
grant execute on function public.rpc_family_diag(uuid, text) to authenticated;

-- ------------------------------------------------------------ gundelik vaxt: 30 deq de olsun
alter table public.family_kids drop constraint if exists family_kids_minutes_check;
alter table public.family_kids add constraint family_kids_minutes_check check (minutes in (5, 10, 15, 20, 30));
