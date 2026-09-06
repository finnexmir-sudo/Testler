-- =====================================================================
--  134_sual_keyfiyyeti.sql : sual keyfiyyeti tehlili (yol xeritesi 22.g)
--
--  Cehdlerden cixarilan gostericiler - bank ozu-ozunu temizleyir:
--    n    cavablanmis (is_correct not null) sayi, yalniz submit olunmus cehd
--    p    duz faizi (asanliq)
--    rpb  noqte-biserial ayirdetme = corr(duz/sehv, cehdin faizi):
--         gucluler daha cox duz edirse musbet; MENFI = gucluler daha cox
--         sehv edir - acar sehv ola biler ve ya sual ikimenali
--    opts her variant nece defe secilib (distraktor tehlili)
--
--  Siqnallar (n >= app.qstat_min() = 20 olanda):
--    acar   distraktor duz variantdan cox secilib     (sev 4)
--    menfi  rpb < 0                                   (sev 3)
--    cetin  p < 20%                                   (sev 2)
--    olu    hec secilmeyen distraktor (< 2%)          (sev 1)
--    zeif   0 <= rpb < 0.10, n >= 30                  (sev 1)
--    asan   p > 95%, n >= 40 - melumat, qusur deyil   (sev 0)
--
--  Hesablama app.qstat_rows() - set-esasli; admin ekrani acilanda 1 saat
--  kohnedirse question_stats yenilenir ("Yenile" - derhal).  Muellim oz
--  sualinin redaktorunda canli hesablanmis setri gorur.  "Baxildi"
--  (hidden_at) siyahidan cixarir; yeniden hesablama onu geri getirmir.
-- =====================================================================

create table if not exists public.question_stats (
  question_id uuid primary key references public.questions(id) on delete cascade,
  n           int not null default 0,
  p           numeric(5,1),
  rpb         numeric(4,2),
  opts        jsonb not null default '[]'::jsonb,
  flags       text[] not null default '{}',
  sev         int not null default 0,
  hidden_at   timestamptz,
  computed_at timestamptz not null default now()
);
alter table public.question_stats enable row level security;
revoke all on public.question_stats from public, anon, authenticated;

create or replace function app.qstat_min() returns int
language sql immutable as $$ select 20 $$;
revoke all on function app.qstat_min() from public, anon, authenticated;

create or replace function app.qstat_rows(p_q uuid default null)
returns table (question_id uuid, n int, p numeric, rpb numeric, opts jsonb, flags text[], sev int)
language sql stable as $$
  with ans as (
    select aa.question_id, (aa.is_correct)::int as ok, aa.selected_option_ids as sel, a.percent
      from public.attempt_answers aa
      join public.attempts a on a.id = aa.attempt_id and a.status = 'submitted'
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

create or replace function app.qstat_refresh() returns int
language plpgsql as $$
declare v int;
begin
  insert into public.question_stats (question_id, n, p, rpb, opts, flags, sev, computed_at)
  select r.question_id, r.n, r.p, r.rpb, r.opts, r.flags, r.sev, now()
    from app.qstat_rows(null) r
  on conflict (question_id) do update
    set n = excluded.n, p = excluded.p, rpb = excluded.rpb, opts = excluded.opts,
        flags = excluded.flags, sev = excluded.sev, computed_at = now();
  get diagnostics v = row_count;
  return v;
end $$;
revoke all on function app.qstat_refresh() from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Admin: siyahi (lazim gelse yenilenir), sayğaclar
-- ---------------------------------------------------------------------
create or replace function public.rpc_admin_qstats(p_flag text default null,
                                                   p_limit int default 50,
                                                   p_force boolean default false)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_at  timestamptz;
  v_lim int := least(greatest(coalesce(p_limit, 50), 1), 200);
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_flag is not null and p_flag not in ('acar','menfi','cetin','olu','zeif','asan','hidden') then
    raise exception 'Suzgec duzgun deyil.' using errcode = '22023';
  end if;
  select max(computed_at) into v_at from public.question_stats;
  if p_force or v_at is null or v_at < now() - interval '1 hour' then
    perform app.qstat_refresh();
    select max(computed_at) into v_at from public.question_stats;
  end if;
  return jsonb_build_object(
    'computed_at', v_at,
    'min_n', app.qstat_min(),
    'rated', (select count(*) from public.question_stats s where s.n >= app.qstat_min()),
    'counts', (select jsonb_build_object(
                 'all',    count(*) filter (where cardinality(s.flags) > 0 and s.hidden_at is null),
                 'acar',   count(*) filter (where 'acar'  = any(s.flags) and s.hidden_at is null),
                 'menfi',  count(*) filter (where 'menfi' = any(s.flags) and s.hidden_at is null),
                 'cetin',  count(*) filter (where 'cetin' = any(s.flags) and s.hidden_at is null),
                 'olu',    count(*) filter (where 'olu'   = any(s.flags) and s.hidden_at is null),
                 'zeif',   count(*) filter (where 'zeif'  = any(s.flags) and s.hidden_at is null),
                 'asan',   count(*) filter (where 'asan'  = any(s.flags) and s.hidden_at is null),
                 'hidden', count(*) filter (where s.hidden_at is not null))
                 from public.question_stats s),
    'items', coalesce((
      select jsonb_agg(x order by (x->>'sev')::int desc, (x->>'n')::int desc, x->>'question_id')
        from (
          select jsonb_build_object(
                   'question_id', q.id, 'body', q.body, 'explanation', q.explanation,
                   'kind', q.kind, 'owner', q.owner_type,
                   'subject', sub.name, 'level', l.name, 'topic', t.name,
                   'n', s.n, 'p', s.p, 'rpb', s.rpb, 'flags', to_jsonb(s.flags), 'sev', s.sev,
                   'hidden', s.hidden_at is not null,
                   'options', s.opts) as x
            from public.question_stats s
            join public.questions q on q.id = s.question_id
            left join public.subjects sub on sub.id = q.subject_id
            left join public.levels l on l.id = q.level_id
            left join public.topics t on t.id = q.topic_id
           where case when p_flag = 'hidden' then s.hidden_at is not null
                      when p_flag is null then cardinality(s.flags) > 0 and s.hidden_at is null
                      else p_flag = any(s.flags) and s.hidden_at is null end
           order by s.sev desc, s.n desc, q.id
           limit v_lim
        ) z), '[]'::jsonb));
end $$;
revoke all on function public.rpc_admin_qstats(text, int, boolean) from public, anon;
grant execute on function public.rpc_admin_qstats(text, int, boolean) to authenticated;

create or replace function public.rpc_admin_qstat_hide(p_question uuid, p_hidden boolean default true)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  update public.question_stats
     set hidden_at = case when p_hidden then now() else null end
   where question_id = p_question;
  if not found then
    raise exception 'Sual statistikada yoxdur.' using errcode = '22023';
  end if;
  return jsonb_build_object('ok', true, 'hidden', p_hidden);
end $$;
revoke all on function public.rpc_admin_qstat_hide(uuid, boolean) from public, anon;
grant execute on function public.rpc_admin_qstat_hide(uuid, boolean) to authenticated;

-- rpc_bank_question (esas: 132): 'stats'
create or replace function public.rpc_bank_question(p_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v jsonb;
begin
  if not app.can_manage_question(p_id) then
    raise exception 'Bu sual sizin deyil.' using errcode = '42501';
  end if;

  select jsonb_build_object(
           'id', q.id, 'body', q.body, 'kind', q.kind,
           'params', q.params,
           --  134: oz sualinin canli statistikasi (n, duz faizi, ayirdetme, siqnallar)
           'stats', (select jsonb_build_object('n', st.n, 'p', st.p, 'rpb', st.rpb, 'flags', to_jsonb(st.flags))
                       from app.qstat_rows(q.id) st),
           'explanation', q.explanation, 'difficulty', q.difficulty,
           'quarter', q.quarter, 'month', q.month, 'tags', to_jsonb(q.tags),
           'subject', s.slug, 'subject_name', s.name,
           'level', l.code, 'level_name', l.name,
           'topic_id', q.topic_id, 'topic', tp.name,
           'status', q.status,
           'used_in', (select count(*) from public.test_questions tq
                        where tq.question_id = q.id),
           'answered', (select count(*) from public.attempt_answers aa
                         where aa.question_id = q.id),
           'options', coalesce((
              select jsonb_agg(jsonb_build_object(
                       'body', o.body, 'correct', o.is_correct) order by o.ord)
                from public.question_options o where o.question_id = q.id), '[]'::jsonb)
         ) into v
    from public.questions q
    join public.subjects s on s.id = q.subject_id
    left join public.levels l on l.id = q.level_id
    left join public.topics tp on tp.id = q.topic_id
   where q.id = p_id;
  return v;
end $$;

