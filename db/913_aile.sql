-- =====================================================================
--  913 : AILE YOLU (muellimsiz) - 1-ci hisse: valideyn hesabi, usaq elave etme (2026-10-06)
--
--  QERAR (sahib, 06.10): sagird ve valideyn muelliminden ASILI OLMADAN islesin.  Pulsuz hisse yoxdur -
--  1 aylıq (kartsiz) sinaq, sonra usaq basina qiymet.  Bu, 165-deki «sagird ve valideyn hemise pulsuzdur»
--  qeydini muellimsiz yol ucun evez edir (muellim yolu deyismir).
--
--  NECE ISLEYIR (movcud sistemin uzerinde - sifirdan hecne yoxdur)
--    valideyn e-poctla qeydiyyat (auth) -> rpc_family_start : 'parent' tipli hesab + 30 gun sinaq
--    rpc_family_add_child : usaq ucun GIZLI «self_study» qrup (sinifi ile) + sagird + giris kodu +
--                           valideyn razilisi (consents) + secilen fennlerden BASLANGIC diaqnostika
--    rpc_family_children  : «Ailem» ekrani
--    rpc_family_open      : valideyn sessiyasi verir - MOVCUD valideyn ekrani (rpc_parent_home) deyismeden isleyir
--
--  BAYRAQ: app_state.family = {"on": false, "emails": []}.  Sonuk olanda yalniz «emails» siyahisindaki
--  e-poctlar istifade ede bilir (canli sinaq).  Hamiya acmaq:
--    update public.app_state set val = jsonb_set(val, '{on}', 'true') where key = 'family';
--
--  TEHLUKESIZLIK: yeni cedvel RLS-le baglidir (siyaset yoxdur), yalniz definer RPC-ler toxunur; hec bir
--  RPC anon-a verilmir (yalniz rpc_family_status - yalniz «aciqdir/baglidir»).  Usagin adi/sinfi/neticesi
--  yalniz hesab sahibine gorunur.
--
--  ON SERT: 100 (rpc_create_class), 124/182 (rpc_add_student), 178 (rpc_diagnostic_create), 107/184 (parent_sessions).
-- =====================================================================

insert into public.app_state (key, val)
values ('family', '{"on": false, "emails": []}'::jsonb)
on conflict (key) do nothing;

-- ------------------------------------------------------------ plan: usaq basina
--  Qiymet YER TUTUCUDUR (9.90 AZN/usaq) - ilk ailelerde yoxlanir.  Sinaq muddetinde pul alinmir.
insert into public.plans (slug, name, audience, price_minor, price_per_seat_minor, max_students, period, sort, features)
values ('aile-usaq', 'Ailə — uşaq başına', 'parent', 0, 990, null, 'month', 25,
        '{"reports":true,"history_days":null,"weak_topics":true}'::jsonb)
on conflict (slug) do nothing;

-- ------------------------------------------------------------ yardimcilar
create or replace function app.family_ok() returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select coalesce((select (val->>'on')::boolean from public.app_state where key = 'family'), false)
      or exists (
           select 1
             from public.app_state s, jsonb_array_elements_text(coalesce(s.val->'emails', '[]'::jsonb)) e(m),
                  auth.users u
            where s.key = 'family' and u.id = auth.uid()
              and lower(u.email) = lower(btrim(e.m)))
$$;

create or replace function app.family_account(p_uid uuid) returns uuid
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select a.id from public.accounts a
   where a.owner_id = p_uid and a.type = 'parent' and not a.is_demo
   order by a.created_at limit 1
$$;

-- ------------------------------------------------------------ cedvel
create table if not exists public.family_kids (
  student_id uuid primary key references public.students(id) on delete cascade,
  subjects   text[] not null default '{}',
  minutes    smallint not null default 10 check (minutes in (5, 10, 15, 20)),
  created_at timestamptz not null default now()
);
alter table public.family_kids enable row level security;
revoke all on public.family_kids from public, anon, authenticated;     -- siyaset yoxdur: yalniz definer RPC-ler

-- ------------------------------------------------------------ status (anon: yalniz «aciqdir»)
create or replace function public.rpc_family_status()
returns jsonb
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select jsonb_build_object('on', coalesce((select (val->>'on')::boolean from public.app_state where key = 'family'), false))
$$;

-- ------------------------------------------------------------ hesab + sinaq
create or replace function public.rpc_family_start(p_name text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_acc  uuid;
  v_type account_type;
  v_plan uuid;
  v_end  timestamptz;
  v_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if exists (select 1 from auth.users u where u.id = v_uid and u.email is null) then
    raise exception 'Nümunə sessiyasında hesab açılmır.' using errcode = '42501';
  end if;
  if not app.family_ok() then
    raise exception 'Bu xidmət hələ açılmayıb. Tezliklə.' using errcode = '42501';
  end if;
  if length(v_name) < 2 or length(v_name) > 80 then
    raise exception 'Adınızı yazın (2–80 simvol).' using errcode = '22023';
  end if;

  --  Eyni istifadecinin ikinci cagirisi (yenileme, iki tab) ikinci hesab yaratmasin
  perform pg_advisory_xact_lock(hashtext('family_start:' || v_uid::text));

  select a.id, a.type into v_acc, v_type
    from public.accounts a where a.owner_id = v_uid and not a.is_demo order by a.created_at limit 1;
  if v_acc is not null then
    if v_type <> 'parent' then
      raise exception 'Bu e-poçt müəllim hesabına bağlıdır. Valideyn üçün başqa e-poçt istifadə edin.' using errcode = '42501';
    end if;
    return jsonb_build_object('ok', true, 'account_id', v_acc, 'existing', true);
  end if;

  perform public.rpc_create_account('parent', v_name);
  v_acc := app.family_account(v_uid);

  select id into v_plan from public.plans where slug = 'aile-usaq' and is_active;
  if v_plan is not null then
    v_end := now() + interval '30 days';
    insert into public.subscriptions (account_id, plan_id, status, seats, started_at, current_period_end, provider)
    values (v_acc, v_plan, 'trialing', 1, now(), v_end, 'family-trial');
  end if;

  update public.profiles set full_name = v_name where id = v_uid and coalesce(btrim(full_name), '') = '';
  return jsonb_build_object('ok', true, 'account_id', v_acc, 'trial_end', v_end);
end $$;

-- ------------------------------------------------------------ sinfe gore movcud fennler
create or replace function public.rpc_family_subjects(p_level_code text)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v_lvl uuid;
begin
  if auth.uid() is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  select id into v_lvl from public.levels where code = btrim(coalesce(p_level_code, '')) and code ~ '^[0-9]+$';
  if v_lvl is null then return '[]'::jsonb; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('slug', s.slug, 'name', s.name, 'n', c.n) order by s.sort, s.name)
      from (select q.subject_id, count(*) n
              from public.questions q
             where q.status = 'published' and q.owner_type = 'platform' and q.level_id = v_lvl
             group by q.subject_id having count(*) >= 20) c
      join public.subjects s on s.id = c.subject_id), '[]'::jsonb);
end $$;

-- ------------------------------------------------------------ usaq elave et
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
  if p_minutes is null or p_minutes not in (5, 10, 15, 20) then p_minutes := 10; end if;

  --  Fennler: yalniz movcud slug, tekrarsiz, en cox 5
  foreach v_s in array coalesce(p_subjects, '{}') loop
    if exists (select 1 from public.subjects where slug = v_s) and not (v_s = any(v_subs)) then
      v_subs := v_subs || v_s;
    end if;
    exit when array_length(v_subs, 1) >= 5;
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
                            'login_code', v_stu->>'login_code', 'diagnostics', v_diag);
end $$;

-- ------------------------------------------------------------ «Ailem» ekrani
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
               'diag_total', (select count(*) from public.assignments a join public.tests t on t.id = a.test_id
                               where a.student_id = st.id and t.is_diagnostic),
               'diag_done',  (select count(distinct at.test_id) from public.attempts at join public.tests t on t.id = at.test_id
                               where at.student_id = st.id and t.is_diagnostic and at.status = 'submitted'))
             order by st.created_at, st.id)
        from public.students st
        left join public.family_kids fk on fk.student_id = st.id
       where st.account_id = v_acc and st.is_active), '[]'::jsonb));
end $$;

-- ------------------------------------------------------------ usagin valideyn ekranini ac
--  Movcud valideyn tetbiqi (rpc_parent_home) token ile isleyir - burada hesab sahibine usagin tokeni verilir.
create or replace function public.rpc_family_open(p_student uuid)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_acc   uuid;
  v_st    public.students%rowtype;
  v_token text;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  v_acc := app.family_account(v_uid);
  select * into v_st from public.students where id = p_student and account_id = v_acc and is_active;
  if v_acc is null or not found then
    raise exception 'Uşaq tapılmadı.' using errcode = '22023';
  end if;
  v_token := encode(gen_random_bytes(32), 'hex');
  insert into public.parent_sessions (token_hash, student_id, expires_at)
  values (app.hash_token(v_token), v_st.id, now() + interval '30 days');
  return jsonb_build_object('ok', true, 'token', v_token,
                            'child', jsonb_build_object('name', v_st.display_name));
end $$;

-- ------------------------------------------------------------ huquqlar
revoke all on function app.family_ok()           from public, anon, authenticated;
revoke all on function app.family_account(uuid)  from public, anon, authenticated;
revoke all on function public.rpc_family_status()                              from public;
revoke all on function public.rpc_family_start(text)                            from public, anon;
revoke all on function public.rpc_family_subjects(text)                         from public, anon;
revoke all on function public.rpc_family_add_child(text, text, text[], int, boolean) from public, anon;
revoke all on function public.rpc_family_children()                             from public, anon;
revoke all on function public.rpc_family_open(uuid)                             from public, anon;
grant execute on function public.rpc_family_status()                              to anon, authenticated;
grant execute on function public.rpc_family_start(text)                            to authenticated;
grant execute on function public.rpc_family_subjects(text)                         to authenticated;
grant execute on function public.rpc_family_add_child(text, text, text[], int, boolean) to authenticated;
grant execute on function public.rpc_family_children()                             to authenticated;
grant execute on function public.rpc_family_open(uuid)                             to authenticated;
