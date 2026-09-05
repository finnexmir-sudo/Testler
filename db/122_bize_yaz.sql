-- =====================================================================
--  122  «BIZE YAZ» - istifadeci teklifleri, problem ve suallar
--
--  Istifadecinin sozu: "bize yaz kimi sey yaradariq, burda kiminse
--  maraqli teklifleri ola biler, biz onlari deyerlendirerik - bu artiq
--  real tecrubeden gelmis olacaq".
--
--  Kim yaza biler: muellim (authenticated), sagird ve valideyn (anon,
--  sessiya tokeni ile).  Kim oxuyur: yalniz admin (app.admin_ok - 2FA).
--  Muellim oz yazdiqlarini ve adminin cavabini gorur (dovre baglanir).
--
--  Qoruma: metn 10..2000 simvol, gunde muellim 10 / sagird 5 / valideyn
--  5 mesaj; heç bir cedvele birbasa giris yoxdur (RLS deny), her sey
--  security definer RPC ile.
-- =====================================================================

create table if not exists public.feedback (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  author_type  text not null check (author_type in ('teacher','student','parent')),
  user_id      uuid references auth.users(id) on delete set null,
  account_id   uuid references public.accounts(id) on delete set null,
  student_id   uuid references public.students(id) on delete set null,
  kind         text not null check (kind in ('teklif','problem','sual','tesekkur')),
  page         text,
  body         text not null check (char_length(body) between 10 and 2000),
  status       text not null default 'new'
               check (status in ('new','seen','planned','done','closed')),
  admin_note   text,
  answered_at  timestamptz
);
create index if not exists idx_feedback_status on public.feedback (status, created_at desc);
create index if not exists idx_feedback_user on public.feedback (user_id, created_at desc);

alter table public.feedback enable row level security;
revoke all on public.feedback from public, anon, authenticated;
--  siyasət yoxdur - RLS deny; yalniz security definer RPC-ler oxuyur/yazir

-- ------------------------------------------------- komekci
create or replace function app.feedback_check(p_kind text, p_body text)
returns text
language plpgsql immutable as $$
declare v text := btrim(coalesce(p_body, ''));
begin
  if p_kind not in ('teklif','problem','sual','tesekkur') then
    raise exception 'Mesajin novu duzgun deyil.' using errcode = '22023';
  end if;
  if char_length(v) < 10 then
    raise exception 'Mesaj cox qisadir - en azi 10 simvol yazin.' using errcode = '22023';
  end if;
  if char_length(v) > 2000 then
    raise exception 'Mesaj cox uzundur - 2000 simvola qeder.' using errcode = '22023';
  end if;
  return v;
end $$;

-- ------------------------------------------------- muellim yazir
create or replace function public.rpc_feedback_send(p_kind text, p_body text, p_page text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_acc uuid;
  v_body text := app.feedback_check(p_kind, p_body);
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  select account_id into v_acc from public.account_members
   where user_id = v_uid order by is_admin desc limit 1;
  if (select count(*) from public.feedback
       where user_id = v_uid and created_at > now() - interval '1 day') >= 10 then
    raise exception 'Bu gun kifayet qeder yazmisiniz - sabah davam edin.' using errcode = '22023';
  end if;
  insert into public.feedback (author_type, user_id, account_id, kind, page, body)
  values ('teacher', v_uid, v_acc, p_kind, left(coalesce(p_page, ''), 80), v_body)
  returning id into v_id;
  return jsonb_build_object('id', v_id);
end $$;

-- ------------------------------------------------- muellim oz yazdiqlari
create or replace function public.rpc_feedback_mine()
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', f.id, 'kind', f.kind, 'body', f.body, 'page', f.page,
             'status', f.status, 'note', f.admin_note,
             'at', f.created_at, 'answered_at', f.answered_at)
           order by f.created_at desc)
      from (select * from public.feedback where user_id = auth.uid()
             order by created_at desc limit 30) f), '[]'::jsonb);
end $$;

-- ------------------------------------------------- sagird yazir (anon, token)
create or replace function public.rpc_student_feedback(p_token text, p_kind text, p_body text, p_page text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st uuid := app.session_student(p_token);
  v_acc uuid;
  v_body text := app.feedback_check(p_kind, p_body);
  v_id uuid;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil olun.' using errcode = '28000';
  end if;
  select account_id into v_acc from public.students where id = v_st;
  if (select count(*) from public.feedback
       where student_id = v_st and author_type = 'student'
         and created_at > now() - interval '1 day') >= 5 then
    raise exception 'Bu gun kifayet qeder yazmisan - sabah davam et.' using errcode = '22023';
  end if;
  insert into public.feedback (author_type, account_id, student_id, kind, page, body)
  values ('student', v_acc, v_st, p_kind, left(coalesce(p_page, ''), 80), v_body)
  returning id into v_id;
  return jsonb_build_object('id', v_id);
end $$;

-- ------------------------------------------------- valideyn yazir (anon, token)
create or replace function public.rpc_parent_feedback(p_token text, p_kind text, p_body text, p_page text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st uuid := app.session_parent(p_token);
  v_acc uuid;
  v_body text := app.feedback_check(p_kind, p_body);
  v_id uuid;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil olun.' using errcode = '28000';
  end if;
  select account_id into v_acc from public.students where id = v_st;
  if (select count(*) from public.feedback
       where student_id = v_st and author_type = 'parent'
         and created_at > now() - interval '1 day') >= 5 then
    raise exception 'Bu gun kifayet qeder yazmisiniz - sabah davam edin.' using errcode = '22023';
  end if;
  insert into public.feedback (author_type, account_id, student_id, kind, page, body)
  values ('parent', v_acc, v_st, p_kind, left(coalesce(p_page, ''), 80), v_body)
  returning id into v_id;
  return jsonb_build_object('id', v_id);
end $$;

-- ------------------------------------------------- admin: siyahi
create or replace function public.rpc_admin_feedback(p_status text default 'new')
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_status not in ('new','seen','planned','done','closed','all') then
    raise exception 'Status duzgun deyil.' using errcode = '22023';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', f.id, 'kind', f.kind, 'body', f.body, 'page', f.page,
             'status', f.status, 'note', f.admin_note, 'at', f.created_at,
             'author_type', f.author_type,
             'who', case f.author_type
                      when 'teacher' then coalesce(nullif(pr.full_name, ''), u.email, 'Müəllim')
                      when 'student' then coalesce(s.full_name, s.display_name, 'Şagird')
                      else 'Valideyn' || coalesce(' · ' || coalesce(s.full_name, s.display_name), '')
                    end,
             'account', a.name, 'email', u.email, 'class', c.name)
           order by f.created_at desc)
      from (select * from public.feedback
             where p_status = 'all' or status = p_status
             order by created_at desc limit 200) f
      left join public.accounts a on a.id = f.account_id
      left join auth.users u on u.id = f.user_id
      left join public.profiles pr on pr.id = f.user_id
      left join public.students s on s.id = f.student_id
      left join public.classes c on c.id = s.class_id), '[]'::jsonb);
end $$;

create or replace function public.rpc_admin_feedback_count()
returns int
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select case when app.admin_ok()
              then (select count(*)::int from public.feedback where status = 'new')
              else 0 end
$$;

-- ------------------------------------------------- admin: status + cavab
create or replace function public.rpc_admin_feedback_set(p_id uuid, p_status text, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_status not in ('new','seen','planned','done','closed') then
    raise exception 'Status duzgun deyil.' using errcode = '22023';
  end if;
  update public.feedback
     set status = p_status,
         admin_note = case when p_note is null then admin_note else nullif(left(btrim(p_note), 1000), '') end,
         answered_at = case when p_note is not null and btrim(p_note) <> '' then now() else answered_at end
   where id = p_id;
  if not found then
    raise exception 'Mesaj tapilmadi.' using errcode = '22023';
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- huquqlar
revoke all on function app.feedback_check(text, text) from public, anon, authenticated;
revoke all on function public.rpc_feedback_send(text, text, text) from public, anon;
grant execute on function public.rpc_feedback_send(text, text, text) to authenticated;
revoke all on function public.rpc_feedback_mine() from public, anon;
grant execute on function public.rpc_feedback_mine() to authenticated;
revoke all on function public.rpc_admin_feedback(text) from public, anon;
grant execute on function public.rpc_admin_feedback(text) to authenticated;
revoke all on function public.rpc_admin_feedback_count() from public, anon;
grant execute on function public.rpc_admin_feedback_count() to authenticated;
revoke all on function public.rpc_admin_feedback_set(uuid, text, text) from public, anon;
grant execute on function public.rpc_admin_feedback_set(uuid, text, text) to authenticated;
--  sagird/valideyn RPC-leri anon-a 05_grants.sql-in ag siyahisi ile acilir
--  (siyahiya elave edilib); burada da veririk ki, 05 unudulsa isleye bilsin
revoke all on function public.rpc_student_feedback(text, text, text, text) from public;
grant execute on function public.rpc_student_feedback(text, text, text, text) to anon, authenticated;
revoke all on function public.rpc_parent_feedback(text, text, text, text) from public;
grant execute on function public.rpc_parent_feedback(text, text, text, text) to anon, authenticated;
