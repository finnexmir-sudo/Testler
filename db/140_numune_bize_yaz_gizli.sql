-- =====================================================================
--  140_numune_bize_yaz_gizli.sql — NUMUNE "BIZE YAZ" MESAJI ADMINDE GORUNMESIN
--
--  139-dan sonra qaldi (2026-09-07): "Bize yazilanlar 4" - hamisi demo
--  qurucusunun yazdigi "Numune Muellim" teklifi (her nusxede bir).
--  Eyni qayda: demo melumati yalniz demo hesabin oz panelinde gorunur.
--
--  app.feedback_is_demo(account, student): yazan hesab ve ya sagirdin
--  hesabi is_demo-dursa true.  rpc_admin_feedback / _count onu cixarir.
--  Govdeler 122-den proqramla (gen140.py).  Demo qurucusu deyismir -
--  demo muellim "Bize yaz"-da oz mesajini gormelidir (rpc_feedback_mine).
-- =====================================================================

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'accounts'
                    and column_name = 'is_demo') then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

create or replace function app.feedback_is_demo(p_account uuid, p_student uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (
    select 1 from public.accounts da
     where da.is_demo
       and (da.id = p_account
            or da.id = (select st.account_id from public.students st where st.id = p_student))
  )
$$;

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
      from (select * from public.feedback fb
             where (p_status = 'all' or fb.status = p_status)
               --  140: numune hesabinin (muellim/sagird/valideyn) yazisi gorunmur
               and not app.feedback_is_demo(fb.account_id, fb.student_id)
             order by fb.created_at desc limit 200) f
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
              then (select count(*)::int from public.feedback fb
                     where fb.status = 'new'
                       and not app.feedback_is_demo(fb.account_id, fb.student_id))
              else 0 end
$$;

revoke all on function public.rpc_admin_feedback(text)   from public, anon;
revoke all on function public.rpc_admin_feedback_count() from public, anon;
grant execute on function public.rpc_admin_feedback(text)   to authenticated;
grant execute on function public.rpc_admin_feedback_count() to authenticated;
