-- =====================================================================
--  208 : «BIZE YAZ» CAVABI SAGIRDE VE VALIDEYNE CATIR (2026-09-17)
--
--  Qusur (istifadeci tapdi): sagird Ayse «Bize yaz»dan yazdi, admin
--  cavab yazdi - cavab HEC KIME getmedi.  Sebeb: 122-de sagird/valideyn
--  YALNIZ yaza bilirdi, oxuya bilmirdi.  Muellim de gormurdu, cunki
--  rpc_feedback_mine «user_id = auth.uid()» suzur, sagird setrinde ise
--  user_id bosdur (student_id dolur).  Cavab yalniz admin panelinde
--  qeyd kimi qalirdi.
--
--  Ikinci qusur: admin cavab yazib saxlayanda status «Yeni» qalirdi,
--  ona gore «Bize yazilanlar 1» nisani sonmurdu.
--
--  Indi:
--    * rpc_student_feedback_mine / rpc_parent_feedback_mine (anon, token):
--      oz yazdiqlari + admin cavabi.  Siyahi acilanda cavab OXUNMUS
--      sayilir (reply_seen_at) - ona gore VOLATILE.
--    * rpc_admin_feedback_set: cavab yazilib, status hele «new»-dirse
--      ozu «seen»-e kecir (cavab verildi - artiq yeni deyil).
--    * rpc_admin_feedback: 'reply_seen_at' - admin «catdi, oxudu» gorur.
--
--  ON SERT: 122 (feedback), 199 (seen_at, reply_to).
-- =====================================================================
do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'feedback'
                    and column_name = 'admin_note') then
    raise exception 'ONCE 122_bize_yaz.sql isledilmelidir.';
  end if;
end $$;

--  cavabi sagird/valideyn NE VAXT gordu (admin mesajinin seen_at-indan ayri)
alter table public.feedback add column if not exists reply_seen_at timestamptz;

-- ---------------------------------------------------------------------
--  1. Admin: status + qeyd.  Cavab yazilibsa «Yeni» -> «Baxilib».
-- ---------------------------------------------------------------------
create or replace function public.rpc_admin_feedback_set(p_id uuid, p_status text, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  v_st   text := p_status;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_status not in ('new','seen','planned','done','closed') then
    raise exception 'Status duzgun deyil.' using errcode = '22023';
  end if;
  --  208: cavab yazildi, amma status «Yeni» qalib - ozu «Baxilib»a kecir.
  --  Yoxsa siyahidaki «N yeni» nisani cavabdan sonra da sonmurdu.
  if v_note is not null and v_st = 'new' then
    v_st := 'seen';
  end if;
  update public.feedback
     set status = v_st,
         admin_note = case when p_note is null then admin_note
                           else nullif(left(btrim(p_note), 1000), '') end,
         answered_at = case when v_note is not null then now() else answered_at end,
         --  cavab deyisdise, «oxudu» nisani sifirlanir - teze cavabdir
         reply_seen_at = case when v_note is not null
                                and v_note is distinct from admin_note then null
                              else reply_seen_at end
   where id = p_id;
  if not found then
    raise exception 'Muraciet tapilmadi.' using errcode = '22023';
  end if;
  return jsonb_build_object('ok', true, 'status', v_st);
end $$;
revoke all on function public.rpc_admin_feedback_set(uuid, text, text) from public, anon;
grant execute on function public.rpc_admin_feedback_set(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------
--  2. Sagird: oz yazdiqlari + cavab.  Acilanda cavab oxunmus sayilir.
-- ---------------------------------------------------------------------
--  p_seen: siyahi EKRANDA gorundu (qutu acildi) - cavab oxunmus sayilir.
--  Ekran yuklenende false ile cagirilir: nisan («Bil10 cavab yazdi»)
--  gorunsun deye - yoxsa nisan oz-ozunu derhal sondururdu.
create or replace function public.rpc_student_feedback_mine(p_token text, p_seen boolean default false)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st uuid := app.session_student(p_token);
  v_rows jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', x.id, 'kind', x.kind, 'body', x.body, 'at', x.created_at,
           'note', x.admin_note, 'answered_at', x.answered_at,
           --  p_seen=true = cavab ELE INDI ekranda gorunur, artiq teze deyil
           'fresh', not p_seen and x.admin_note is not null and x.reply_seen_at is null)
         order by x.created_at desc), '[]'::jsonb)
    into v_rows
    from (select * from public.feedback
           where student_id = v_st and author_type = 'student'
           order by created_at desc limit 10) x;
  --  cavab ekranda gorundu - «oxudu» yazilir (admin panelinde gorunur)
  if p_seen then
    update public.feedback
       set reply_seen_at = now()
     where student_id = v_st and author_type = 'student'
       and admin_note is not null and reply_seen_at is null;
  end if;
  return v_rows;
end $$;
revoke all on function public.rpc_student_feedback_mine(text, boolean) from public;
grant execute on function public.rpc_student_feedback_mine(text, boolean) to anon, authenticated;

-- ---------------------------------------------------------------------
--  3. Valideyn: eyni
-- ---------------------------------------------------------------------
create or replace function public.rpc_parent_feedback_mine(p_token text, p_seen boolean default false)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st uuid := app.session_parent(p_token);
  v_rows jsonb;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil olun.' using errcode = '28000';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', x.id, 'kind', x.kind, 'body', x.body, 'at', x.created_at,
           'note', x.admin_note, 'answered_at', x.answered_at,
           'fresh', not p_seen and x.admin_note is not null and x.reply_seen_at is null)
         order by x.created_at desc), '[]'::jsonb)
    into v_rows
    from (select * from public.feedback
           where student_id = v_st and author_type = 'parent'
           order by created_at desc limit 10) x;
  if p_seen then
    update public.feedback
       set reply_seen_at = now()
     where student_id = v_st and author_type = 'parent'
       and admin_note is not null and reply_seen_at is null;
  end if;
  return v_rows;
end $$;
revoke all on function public.rpc_parent_feedback_mine(text, boolean) from public;
grant execute on function public.rpc_parent_feedback_mine(text, boolean) to anon, authenticated;

-- ---------------------------------------------------------------------
--  4. Admin siyahisi: «cavabi oxudu?» (199-un govdesi + reply_seen_at)
-- ---------------------------------------------------------------------
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
             --  208: cavabi sagird/valideyn oxuyub?
             'reply_seen_at', f.reply_seen_at,
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
revoke all on function public.rpc_admin_feedback(text) from public, anon;
grant execute on function public.rpc_admin_feedback(text) to authenticated;
