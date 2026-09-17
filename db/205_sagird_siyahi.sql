-- =====================================================================
--  205 : QRUP EKRANINDA SAGIRD SIYAHISI - NETICE ILE (2026-09-17)
--
--  Evvel siyahi students cedvelinden birbasa gelirdi: ad + iki kod +
--  dord duyme.  Netice gorunmurdu, kodlar her setirde daimi yer
--  tuturdu (istifadeci: «bu siyahini beyenmirem»).
--
--  rpc_class_students(p_class_id): her sagird ucun (dayandirilmislar
--  daxil) ad, kodlar, aktivlik + son netice, cehd/tapsiriq sayi, son
--  giris (sagird ve valideyn).  Panel bunlarla setri qurur: netice
--  rengli, «isleyib 4/5» zolagi, «girib 2 gün əvvəl» / «hələ girməyib».
--  Kod xetleri yalniz hele GIRMEYEN ucun aciq qalir - girenden sonra
--  «Kodlar» altina yigilir.
--
--  Pulsuz hedd: son netice ve cehdler rpc_class_report kimi
--  app.free_history_days() pencerəsindən goturulur ('since').
-- =====================================================================
create or replace function public.rpc_class_students(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_paid  boolean;
  v_since timestamptz;
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
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  v_paid  := app.has_active_subscription(v_class.account_id);
  v_since := case when v_paid then '-infinity'::timestamptz
                  else now() - (app.free_history_days() || ' days')::interval end;

  return jsonb_build_object(
    'paid', v_paid,
    'since', case when v_paid then null else v_since end,
    --  qrupa verilmis tapsiriqlar (aciq olanlar): «isleyib N/M»-in M-i
    'assigned', (select count(*) from public.assignments asg
                  where asg.class_id = p_class_id and asg.student_id is null
                    and asg.opens_at <= now()),
    'students', coalesce((
      select jsonb_agg(x order by (x->>'is_active') desc, x->>'full_name')
      from (
        select jsonb_build_object(
                 'id',           s.id,
                 'full_name',    s.full_name,
                 'display_name', s.display_name,
                 'login_code',   s.login_code,
                 'parent_code',  s.parent_code,
                 'is_active',    s.is_active,
                 'attempts',     (select count(*) from public.attempts a
                                   where a.student_id = s.id and a.status = 'submitted'
                                     and a.finished_at >= v_since),
                 'avg',          (select round(avg(a.percent)) from public.attempts a
                                   where a.student_id = s.id and a.status = 'submitted'
                                     and a.finished_at >= v_since),
                 'last_pct',     (select a.percent from public.attempts a
                                   where a.student_id = s.id and a.status = 'submitted'
                                     and a.finished_at >= v_since
                                   order by a.finished_at desc limit 1),
                 'last_at',      (select max(a.finished_at) from public.attempts a
                                   where a.student_id = s.id and a.status = 'submitted'),
                 --  tek sagirde verilmis tapsiriqlar da sayilir
                 'assigned_own', (select count(*) from public.assignments asg
                                   where asg.student_id = s.id and asg.opens_at <= now()),
                 'seen_at',      (select max(ss.created_at) from public.student_sessions ss
                                   where ss.student_id = s.id),
                 'parent_seen_at', (select max(ps.created_at) from public.parent_sessions ps
                                     where ps.student_id = s.id)
               ) as x
          from public.students s
         where s.class_id = p_class_id
      ) z), '[]'::jsonb)
  );
end $$;
revoke all on function public.rpc_class_students(uuid) from public, anon;
grant execute on function public.rpc_class_students(uuid) to authenticated;
