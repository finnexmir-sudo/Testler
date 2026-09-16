-- =====================================================================
--  199 : ADMIN -> MUELLIM MESAJI (2026-09-16)
--
--  Indiyedek yalniz bir istiqamet vardi: muellim «Bize yaz»-dan yazir,
--  admin Idareetmede cavab qeydi qoyur.  Admin BIRINCI yaza bilmirdi -
--  yeni qeydiyyatdan kecib qrup qurmayan muellime «komek edim?» demek
--  ucun yol yox idi.  E-pocta bizde bakan yoxdur (istifadeci) - yol
--  panelin icinden olmalidir.
--
--  Eyni cedvel (feedback), yeni muellif tipi 'admin':
--    author_type='admin', user_id=admin, account_id=hedef hesab,
--    kind='mesaj', status='closed' (yeni muraciet sayina dusmur),
--    seen_at - muellim gorende, reply_to - muellimin cavabi hansi
--    mesaja aiddir.
--  Panel: muellim Icmalin ustunde «Bil10-dan mesaj» kartini gorur,
--  «Cavab yaz» Profil -> Bize yaz-a aparir (reply_to ile); cavab
--  Idareetme -> Bize yazilanlarda «cavab» nisani ile cixir.
--
--  RPC-ler: rpc_admin_message(email, body) · rpc_my_messages() ·
--  rpc_message_seen(id) · rpc_feedback_send(+p_reply_to).
--  Hamisi authenticated; anon ag siyahisi deyismir.
-- =====================================================================

alter table public.feedback drop constraint if exists feedback_author_type_check;
alter table public.feedback add constraint feedback_author_type_check
  check (author_type in ('teacher','student','parent','admin'));
alter table public.feedback drop constraint if exists feedback_kind_check;
alter table public.feedback add constraint feedback_kind_check
  check (kind in ('teklif','problem','sual','tesekkur','mesaj'));
alter table public.feedback add column if not exists seen_at  timestamptz;
alter table public.feedback add column if not exists reply_to uuid
  references public.feedback(id) on delete set null;
create index if not exists idx_feedback_admin_msg
  on public.feedback (account_id, created_at desc) where author_type = 'admin';

-- ------------------------------------------------- admin yazir
create or replace function public.rpc_admin_message(p_email text, p_body text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid;
  v_body text := btrim(coalesce(p_body, ''));
  v_id   uuid;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if char_length(v_body) < 10 then
    raise exception 'Mesaj cox qisadir - en azi 10 simvol yazin.' using errcode = '22023';
  end if;
  if char_length(v_body) > 2000 then
    raise exception 'Mesaj cox uzundur - 2000 simvola qeder.' using errcode = '22023';
  end if;
  select a.id into v_acc
    from public.accounts a
    join auth.users u on u.id = a.owner_id
   where lower(u.email) = lower(btrim(p_email))
   order by a.created_at limit 1;
  if v_acc is null then
    raise exception 'Bu e-poctla hesab tapilmadi: %', p_email using errcode = '22023';
  end if;
  if (select is_demo from public.accounts where id = v_acc) then
    raise exception 'Numune hesaba mesaj gonderilmir.' using errcode = '22023';
  end if;
  insert into public.feedback (author_type, user_id, account_id, kind, page, body, status)
  values ('admin', auth.uid(), v_acc, 'mesaj', 'admin', v_body, 'closed')
  returning id into v_id;
  return jsonb_build_object('id', v_id);
end $$;

-- ------------------------------------------------- muellim oxuyur
create or replace function public.rpc_my_messages()
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', f.id, 'body', f.body, 'at', f.created_at, 'seen_at', f.seen_at,
             'replied', exists (select 1 from public.feedback r where r.reply_to = f.id))
           order by f.created_at desc)
      from (select * from public.feedback fb
             where fb.author_type = 'admin'
               and fb.account_id in (select account_id from public.account_members
                                      where user_id = auth.uid())
             order by fb.created_at desc limit 20) f), '[]'::jsonb);
end $$;

create or replace function public.rpc_message_seen(p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_n int;
begin
  if auth.uid() is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  update public.feedback f set seen_at = coalesce(f.seen_at, now())
   where f.id = p_id and f.author_type = 'admin'
     and f.account_id in (select account_id from public.account_members
                           where user_id = auth.uid());
  get diagnostics v_n = row_count;
  return jsonb_build_object('ok', v_n > 0);
end $$;

-- ------------------------------------------------- muellim yazir (+cavab)
drop function if exists public.rpc_feedback_send(text, text, text);
create or replace function public.rpc_feedback_send(
  p_kind text, p_body text, p_page text default null, p_reply_to uuid default null)
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
  if p_reply_to is not null and not exists (
       select 1 from public.feedback m
        where m.id = p_reply_to and m.author_type = 'admin'
          and m.account_id in (select account_id from public.account_members
                                where user_id = v_uid)) then
    raise exception 'Cavab verilen mesaj tapilmadi.' using errcode = '22023';
  end if;
  if (select count(*) from public.feedback
       where user_id = v_uid and author_type = 'teacher'
         and created_at > now() - interval '1 day') >= 10 then
    raise exception 'Bu gun kifayet qeder yazmisiniz - sabah davam edin.' using errcode = '22023';
  end if;
  insert into public.feedback (author_type, user_id, account_id, kind, page, body, reply_to)
  values ('teacher', v_uid, v_acc, p_kind, left(coalesce(p_page, ''), 80), v_body, p_reply_to)
  returning id into v_id;
  --  cavab gelen mesaj gorulmus sayilir
  if p_reply_to is not null then
    update public.feedback set seen_at = coalesce(seen_at, now()) where id = p_reply_to;
  end if;
  return jsonb_build_object('id', v_id);
end $$;

-- ------------------------------------------------- muellim oz yazdiqlari
--  admin oz gonderdiyi mesajlari Profildeki «Yazdiqlariniz»da gormesin
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
             'at', f.created_at, 'answered_at', f.answered_at,
             'reply_to', f.reply_to)
           order by f.created_at desc)
      from (select * from public.feedback
             where user_id = auth.uid() and author_type <> 'admin'
             order by created_at desc limit 30) f), '[]'::jsonb);
end $$;

-- ------------------------------------------------- admin siyahisi
--  140-dakinin uzerine: reply_to + adminin oz mesajinin qisa metni;
--  'admin' setirleri (status closed) yalniz closed/all suzgecinde.
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
                      when 'admin'   then 'Siz'
                      else 'Valideyn' || coalesce(' · ' || coalesce(s.full_name, s.display_name), '')
                    end,
             'account', a.name, 'email', coalesce(u.email, ou.email), 'class', c.name,
             'seen_at', f.seen_at, 'reply_to', f.reply_to,
             'reply_body', (select case when char_length(m.body) > 160 then left(m.body, 158) || '…' else m.body end
                              from public.feedback m where m.id = f.reply_to))
           order by f.created_at desc)
      from (select * from public.feedback fb
             where (p_status = 'all' or fb.status = p_status)
               and not app.feedback_is_demo(fb.account_id, fb.student_id)
             order by fb.created_at desc limit 200) f
      left join public.accounts a on a.id = f.account_id
      left join auth.users u on u.id = f.user_id and f.author_type <> 'admin'
      left join auth.users ou on ou.id = a.owner_id
      left join public.profiles pr on pr.id = f.user_id
      left join public.students s on s.id = f.student_id
      left join public.classes c on c.id = s.class_id), '[]'::jsonb);
end $$;

create or replace function public.rpc_admin_feedback_count()
returns int
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select case when app.admin_ok()
              then (select count(*)::int from public.feedback fb
                     where fb.status = 'new' and fb.author_type <> 'admin'
                       and not app.feedback_is_demo(fb.account_id, fb.student_id))
              else 0 end
$$;

-- ------------------------------------------------- huquqlar
revoke all on function public.rpc_admin_message(text, text) from public, anon;
grant execute on function public.rpc_admin_message(text, text) to authenticated;
revoke all on function public.rpc_my_messages() from public, anon;
grant execute on function public.rpc_my_messages() to authenticated;
revoke all on function public.rpc_message_seen(uuid) from public, anon;
grant execute on function public.rpc_message_seen(uuid) to authenticated;
revoke all on function public.rpc_feedback_send(text, text, text, uuid) from public, anon;
grant execute on function public.rpc_feedback_send(text, text, text, uuid) to authenticated;
revoke all on function public.rpc_feedback_mine() from public, anon;
grant execute on function public.rpc_feedback_mine() to authenticated;
revoke all on function public.rpc_admin_feedback(text) from public, anon;
grant execute on function public.rpc_admin_feedback(text) to authenticated;
revoke all on function public.rpc_admin_feedback_count() from public, anon;
grant execute on function public.rpc_admin_feedback_count() to authenticated;
