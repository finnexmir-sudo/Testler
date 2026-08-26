-- =====================================================================
--  23_bildiris.sql : SUAL SEHVI BILDIRISLERI
--
--  Sual bankinda sehv gorulende istifadeci bir klikle bildirir:
--    - muellim veraq ekranindan (rpc_report_question)
--    - sagird netice ekranindan (rpc_report_question_student)
--  Bildiris SUALA TOXUNMUR - yalniz "bura bax" siqnalidir.  Admin
--  Idareetme sehifesinde baxir, qerari OZU verir:
--    - duzeldir (rpc_admin_fix_question - metn/izah/variantlar
--      YERINDE yenilenir, id-ler qorunur, kohne neticeler pozulmur)
--    - ve ya redd edir (rpc_admin_report_set)
--
--  Qorumalar: eyni istifadeci eyni suali tekrar bildire bilmez
--  (aciq bildiris varken), gundelik hedd (muellim 20 / sagird 10),
--  qeyd 300 herf, sagird yalniz OZ gordugu suali bildire biler.
--
--  ON SERT: 01, 03, 11, 21 islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
--  Tekrar isledile biler.
-- =====================================================================

do $$
begin
  if to_regclass('public.questions') is null
     or to_regprocedure('app.admin_ok()') is null then
    raise exception E'ONCE 11_sual_banki.sql ve 21_paket.sql islenmelidir.';
  end if;
end $$;

-- ------------------------------------------------------------- cedvel
create table if not exists public.question_reports (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  --  kim bildirib: muellim hesabi VE YA sagird (biri dolu olur)
  account_id  uuid references public.accounts(id) on delete cascade,
  student_id  uuid references public.students(id) on delete cascade,
  reason      text not null check (reason in ('cavab','sert','yazi','diger')),
  note        text not null default '',
  status      text not null default 'new'
              check (status in ('new','fixed','rejected')),
  created_at  timestamptz not null default now(),
  resolved_at timestamptz,
  constraint qr_reporter_ck check (
    (account_id is not null)::int + (student_id is not null)::int = 1)
);

--  Aciq bildiris varken eyni adam eyni suali tekrarlaya bilmez.
create unique index if not exists uq_qr_acc
  on public.question_reports(question_id, account_id)
  where status = 'new' and account_id is not null;
create unique index if not exists uq_qr_st
  on public.question_reports(question_id, student_id)
  where status = 'new' and student_id is not null;
create index if not exists idx_qr_status
  on public.question_reports(status, created_at desc);

alter table public.question_reports enable row level security;
--  Siyaset YOXDUR - cedvele yalniz asagidaki definer funksiyalar toxunur.

-- ------------------------------------------------- komekci: sebeb adi
create or replace function app.report_reason_ok(p text) returns boolean
language sql immutable as $$
  select p in ('cavab','sert','yazi','diger')
$$;

-- ------------------------------------------------- muellim bildirir
create or replace function public.rpc_report_question(
  p_question uuid, p_reason text, p_note text default '')
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid := app.pick_account(null);
  v_note text := left(btrim(coalesce(p_note, '')), 300);
begin
  if v_acc is null then
    raise exception 'Hesab tapilmadi.' using errcode = '28000';
  end if;
  if not app.report_reason_ok(p_reason) then
    raise exception 'Sebeb duzgun deyil.' using errcode = '22023';
  end if;
  --  yalniz gorunen sual: oz suali ve ya nesr olunmus platforma suali
  if not exists (select 1 from public.questions q
                  where q.id = p_question
                    and (q.account_id = v_acc
                         or (q.owner_type = 'platform'
                             and q.status = 'published'))) then
    raise exception 'Sual tapilmadi.' using errcode = '22023';
  end if;
  --  gundelik hedd - spam qorumasi
  if (select count(*) from public.question_reports
       where account_id = v_acc
         and created_at > now() - interval '1 day') >= 20 then
    raise exception 'Gundelik bildiris heddine catdiniz. Sabah davam edin.'
      using errcode = '22023';
  end if;

  insert into public.question_reports (question_id, account_id, reason, note)
  values (p_question, v_acc, p_reason, v_note)
  on conflict do nothing;   --  qismen unikal indeks tekrari udur

  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- sagird bildirir
create or replace function public.rpc_report_question_student(
  p_token text, p_question uuid, p_reason text, p_note text default '')
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_note    text := left(btrim(coalesce(p_note, '')), 300);
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil olun.' using errcode = '28000';
  end if;
  if not app.report_reason_ok(p_reason) then
    raise exception 'Sebeb duzgun deyil.' using errcode = '22023';
  end if;
  --  sagird yalniz OZ cavablandirdigi suali bildire biler - bankda
  --  gezib sual axtara bilmez
  if not exists (select 1
                   from public.attempt_answers aa
                   join public.attempts a on a.id = aa.attempt_id
                  where aa.question_id = p_question
                    and a.student_id = v_student) then
    raise exception 'Sual tapilmadi.' using errcode = '22023';
  end if;
  if (select count(*) from public.question_reports
       where student_id = v_student
         and created_at > now() - interval '1 day') >= 10 then
    raise exception 'Gundelik bildiris heddine catdiniz.'
      using errcode = '22023';
  end if;

  insert into public.question_reports (question_id, student_id, reason, note)
  values (p_question, v_student, p_reason, v_note)
  on conflict do nothing;   --  qismen unikal indeks tekrari udur

  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- admin: siyahi
--  Suala gore qruplanmis: eyni suala 5 bildiris = 1 kart, say ile.
--  Cox bildirilen sual yuxarida - ehtimal boyukdur ki, hequqi sehvdir.
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
       group by q.id, s.name, l.name, t.name
       limit 50
    ) z), '[]'::jsonb);
end $$;

--  Sayi ayrica - Idareetme lovhesindeki nisan ucun yungul sorgu.
create or replace function public.rpc_admin_reports_count()
returns int
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  return (select count(distinct question_id)::int
            from public.question_reports where status = 'new');
end $$;

-- ------------------------------------------------- admin: status
--  Sualin BUTUN aciq bildirislerini birden baglayir.
create or replace function public.rpc_admin_report_set(
  p_question uuid, p_status text)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_n int;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if p_status not in ('fixed','rejected') then
    raise exception 'Status duzgun deyil.' using errcode = '22023';
  end if;
  update public.question_reports
     set status = p_status, resolved_at = now()
   where question_id = p_question and status = 'new';
  get diagnostics v_n = row_count;
  return jsonb_build_object('ok', true, 'closed', v_n);
end $$;

-- ------------------------------------------------- admin: duzelis
--  YERINDE duzelis: variant id-leri deyismir, yalniz metnler ve
--  duzgun cavab bayragi yenilenir.  Kohne cehd neticeleri pozulmur
--  (netice snapshotu onsuz attempt_answers-dedir).  Yalniz platforma
--  suallari - muellimin oz sualini ozu redakte edir.
create or replace function public.rpc_admin_fix_question(
  p_question uuid, p_body text, p_explanation text, p_options jsonb)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_body text := btrim(coalesce(p_body, ''));
  v_expl text := btrim(coalesce(p_explanation, ''));
  v_opt  jsonb;
  v_n    int := 0;
  v_corr int := 0;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  if not exists (select 1 from public.questions
                  where id = p_question and owner_type = 'platform') then
    raise exception 'Yalniz platforma suali duzeldile biler.'
      using errcode = '22023';
  end if;
  if length(v_body) < 3 or length(v_body) > 1000 then
    raise exception 'Sual metni 3-1000 herf olmalidir.' using errcode = '22023';
  end if;
  if length(v_expl) > 1000 then
    raise exception 'Izah 1000 herfden uzundur.' using errcode = '22023';
  end if;
  if p_options is null or jsonb_typeof(p_options) <> 'array' then
    raise exception 'Variantlar duzgun deyil.' using errcode = '22023';
  end if;

  --  her variant movcud olmali ve mehz bu suala aid olmalidir
  for v_opt in select * from jsonb_array_elements(p_options) loop
    if not exists (select 1 from public.question_options
                    where id = (v_opt->>'id')::uuid
                      and question_id = p_question) then
      raise exception 'Variant bu suala aid deyil.' using errcode = '22023';
    end if;
    if length(btrim(coalesce(v_opt->>'body',''))) < 1
       or length(v_opt->>'body') > 400 then
      raise exception 'Variant metni 1-400 herf olmalidir.'
        using errcode = '22023';
    end if;
    v_n := v_n + 1;
    if (v_opt->>'is_correct')::boolean then v_corr := v_corr + 1; end if;
  end loop;

  if v_n <> (select count(*) from public.question_options
              where question_id = p_question) then
    raise exception 'Butun variantlar gonderilmelidir.' using errcode = '22023';
  end if;
  if v_corr <> 1 then
    raise exception 'Duz cavab tam bir dene olmalidir.' using errcode = '22023';
  end if;

  update public.questions
     set body = v_body, explanation = v_expl, updated_at = now()
   where id = p_question;

  for v_opt in select * from jsonb_array_elements(p_options) loop
    update public.question_options
       set body = btrim(v_opt->>'body'),
           is_correct = (v_opt->>'is_correct')::boolean
     where id = (v_opt->>'id')::uuid and question_id = p_question;
  end loop;

  --  duzelis bildirisleri avtomatik baglayir - ayrica klik istemesin
  update public.question_reports
     set status = 'fixed', resolved_at = now()
   where question_id = p_question and status = 'new';

  return jsonb_build_object('ok', true);
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_report_question(uuid, text, text)                from public, anon;
revoke all on function public.rpc_report_question_student(text, uuid, text, text)  from public;
revoke all on function public.rpc_admin_reports(text)                              from public, anon;
revoke all on function public.rpc_admin_reports_count()                            from public, anon;
revoke all on function public.rpc_admin_report_set(uuid, text)                     from public, anon;
revoke all on function public.rpc_admin_fix_question(uuid, text, text, jsonb)      from public, anon;

grant execute on function public.rpc_report_question(uuid, text, text)               to authenticated;
--  sagird anon acari ile isleyir - qapi p_token-dir (basqa sagird RPC-leri kimi)
grant execute on function public.rpc_report_question_student(text, uuid, text, text) to anon, authenticated;
grant execute on function public.rpc_admin_reports(text)                             to authenticated;
grant execute on function public.rpc_admin_reports_count()                           to authenticated;
grant execute on function public.rpc_admin_report_set(uuid, text)                    to authenticated;
grant execute on function public.rpc_admin_fix_question(uuid, text, text, jsonb)     to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_admin_fix_question(uuid, text, text, jsonb)', 'EXECUTE') then
    raise exception 'anon sual duzelde bilir!';
  end if;
  raise notice 'Bildiris sistemi quruldu.';
end $$;
