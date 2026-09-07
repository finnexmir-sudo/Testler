-- =====================================================================
--  139_numune_admin_gizli.sql — NUMUNE MELUMATI ADMIN BOLMELERINE DUSMESIN
--
--  138-den sonra istifadeci gordu (2026-09-07): Idareetmede "Sual
--  bildirisleri 4" - hamisi demo qurucusunun uydurdugu "Tural Q." bildirisi
--  (her nusxede bir dene); "Sual keyfiyyeti 16" - demo cehdlerinden
--  hesablanmis "olu variant" siqnallari.  138 yalniz lovheleri ve hesab
--  siyahisini temizlemisdi.
--
--  Indi:
--    rpc_admin_reports / rpc_admin_reports_count  - is_demo hesabin
--      (muellim ve ya sagirdinin) bildirisi gorunmur, sayilmir.
--    app.qstat_rows  - is_demo hesabin sagirdlerinin cehdleri statistikaya
--      dusmur (question_stats novbeti yenilenmede temizlenir).
--
--  Govdeler 23 ve 134-den proqramla (gen139.py).  Numune qurucusu (136)
--  deyismir - demo muellim oz panelinde bildirisi gormelidir.
-- =====================================================================

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'accounts'
                    and column_name = 'is_demo') then
    raise exception 'ONCE 136_numune_hesab.sql isledilmelidir.';
  end if;
end $$;

create or replace function public.rpc_admin_reports(p_status text default 'new')
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_status not in ('new','fixed','rejected') then
    raise exception 'Status duzgun deyil.' using errcode = '22023';
  end if;

  return coalesce((
    select jsonb_agg(x order by (x->>'n')::int desc, x->>'last' desc)
    from (
      select jsonb_build_object(
               'question_id', q.id,
               'body',        q.body,
               'explanation', q.explanation,
               'owner',       q.owner_type,
               'subject',     s.name,
               'level',       l.name,
               'topic',       t.name,
               'n',           count(*),
               'last',        max(r.created_at),
               'options', (select jsonb_agg(jsonb_build_object(
                             'id', o.id, 'body', o.body,
                             'is_correct', o.is_correct)
                             order by o.ord, o.id)
                             from public.question_options o
                            where o.question_id = q.id),
               'reports', jsonb_agg(jsonb_build_object(
                            'id', r.id,
                            'reason', r.reason,
                            'note', r.note,
                            'who', case when r.account_id is not null
                                   then coalesce(a.name, 'Müəllim')
                                   else coalesce(st.display_name, 'Şagird')
                                   end,
                            'kind', case when r.account_id is not null
                                    then 'muellim' else 'sagird' end,
                            'created', r.created_at)
                          order by r.created_at desc)
             ) as x
        from public.question_reports r
        join public.questions q on q.id = r.question_id
        left join public.subjects s  on s.id = q.subject_id
        left join public.levels   l  on l.id = q.level_id
        left join public.topics   t  on t.id = q.topic_id
        left join public.accounts a  on a.id = r.account_id
        left join public.students st on st.id = r.student_id
       where r.status = p_status
         --  139: numune hesabinin (muellim ve ya sagird) bildirisi sayilmir
         and not coalesce(a.is_demo, false)
         and not exists (select 1 from public.accounts da
                          where da.id = st.account_id and da.is_demo)
       group by q.id, s.name, l.name, t.name
       limit 50
    ) z), '[]'::jsonb);
end $$;

create or replace function public.rpc_admin_reports_count()
returns int
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  --  139: numune hesabinin bildirisi sayilmir
  return (select count(distinct r.question_id)::int
            from public.question_reports r
            left join public.accounts a  on a.id = r.account_id
            left join public.students st on st.id = r.student_id
            left join public.accounts da on da.id = st.account_id
           where r.status = 'new'
             and not coalesce(a.is_demo, false)
             and not coalesce(da.is_demo, false));
end $$;

create or replace function app.qstat_rows(p_q uuid default null)
returns table (question_id uuid, n int, p numeric, rpb numeric, opts jsonb, flags text[], sev int)
language sql stable as $$
  with ans as (
    select aa.question_id, (aa.is_correct)::int as ok, aa.selected_option_ids as sel, a.percent
      from public.attempt_answers aa
      join public.attempts a on a.id = aa.attempt_id and a.status = 'submitted'
      --  139: numune hesabinin suni cehdleri statistikaya dusmur
      join public.students st on st.id = a.student_id
      join public.accounts ac on ac.id = st.account_id and not ac.is_demo
     where aa.is_correct is not null and (p_q is null or aa.question_id = p_q)
  ),
  per_q as (
    select question_id, count(*)::int as n,
           round(avg(ok) * 100, 1) as p,
           round(corr(ok::float, percent::float)::numeric, 2) as rpb
      from ans group by question_id
  ),
  per_o as (
    select o.question_id,
           jsonb_agg(jsonb_build_object(
             'id', o.id, 'body', o.body, 'correct', o.is_correct,
             'n', c.n, 'pct', round(c.n * 100.0 / q.n, 0)) order by o.ord, o.id) as opts,
           bool_or(not o.is_correct and c.n * 100.0 / q.n < 2) as dead,
           coalesce(max(c.n) filter (where o.is_correct), 0)     as cmax,
           coalesce(max(c.n) filter (where not o.is_correct), 0) as dmax
      from per_q q
      join public.question_options o on o.question_id = q.question_id
      join lateral (select count(*) as n from ans x
                     where x.question_id = o.question_id and o.id = any(x.sel)) c on true
     group by o.question_id
  )
  select q.question_id, q.n, q.p, q.rpb, coalesce(po.opts, '[]'::jsonb), f.flags,
         (select coalesce(max(case fl when 'acar' then 4 when 'menfi' then 3 when 'cetin' then 2
                                      when 'olu' then 1 when 'zeif' then 1 else 0 end), 0)
            from unnest(f.flags) fl) as sev
    from per_q q
    join public.questions qq on qq.id = q.question_id
    left join per_o po on po.question_id = q.question_id
    cross join lateral (
      select array_remove(array[
        case when q.n >= app.qstat_min() and qq.kind <> 'text' and po.dmax > po.cmax then 'acar' end,
        case when q.n >= app.qstat_min() and q.rpb < 0 then 'menfi' end,
        case when q.n >= app.qstat_min() and q.p < 20 then 'cetin' end,
        case when q.n >= app.qstat_min() and qq.kind <> 'text' and po.dead then 'olu' end,
        case when q.n >= app.qstat_min() + 10 and q.rpb >= 0 and q.rpb < 0.10 then 'zeif' end,
        case when q.n >= app.qstat_min() * 2 and q.p > 95 then 'asan' end], null) as flags
    ) f
$$;

revoke all on function app.qstat_rows(uuid) from public, anon, authenticated;
revoke all on function public.rpc_admin_reports(text)    from public, anon;
revoke all on function public.rpc_admin_reports_count()  from public, anon;
grant execute on function public.rpc_admin_reports(text)   to authenticated;
grant execute on function public.rpc_admin_reports_count() to authenticated;

--  kohne (demo daxil) statistika bir defe yeniden hesablanir
select app.qstat_refresh();
delete from public.question_stats qs
 where not exists (select 1 from app.qstat_rows(qs.question_id));
