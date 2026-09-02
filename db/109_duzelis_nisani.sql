-- =====================================================================
--  109_duzelis_nisani.sql — duzelis testi YARANANDA nisanlanir
--
--  NIYE
--  108-de valideyn ekraninda "sexsi" nisani qoydum: testin YALNIZ bir
--  sagirde verilmesine baxirdi.  Canlida gorunen budur ki, muellim adi
--  testi de ferdi verir - alti neticenin ucunde nisan cixdi.  Yarisinda
--  gorunen nisan hec ne ayirmir, sadece kur-kufdur.
--
--  Sehv seciminde idi: "duzelis testi" ucun EVEZEDICI siqnal
--  goturmusdum (ferdi verilib).  Duzgun yol - hadiseni bas verdiyi
--  anda yazmaqdir, sonradan tapmaga calismaq deyil.
--
--  NE EDIRIK
--  tests.is_remedial sutunu.  rpc_remedial_test onu true qoyur.
--  Movcud testler BIR DEFELIK basliga gore doldurulur - o basligi
--  mehz hemin funksiya yazir, ona gore burada dogru neticedir.
--  (Bundan sonra basliga bir daha baxilmir.)
-- =====================================================================

alter table public.tests
  add column if not exists is_remedial boolean not null default false;

comment on column public.tests.is_remedial is
  'Sehvler uzerinde is testi.  rpc_remedial_test yaradanda true qoyur.';

--  Birdefelik doldurma: bu basligi yalniz rpc_remedial_test yazir
update public.tests
   set is_remedial = true
 where not is_remedial
   and title like '% — səhvlər üzərində iş';

-- --------------------------------------------------- yaradan funksiya
--  28_ferdi_tapsiriq.sql-deki govde ile eyni, YEGANE ferq: insert-e
--  is_remedial elave olunur.
create or replace function public.rpc_remedial_test(
  p_student_id uuid, p_count int default 10)
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid  uuid := auth.uid();
  v_st   public.students%rowtype;
  v_qids uuid[];
  v_subj uuid;
  v_lev  uuid;
  v_prog uuid;
  v_test uuid;
  v_n    int;
begin
  if p_count is null or p_count < 1 or p_count > 50 then
    raise exception 'Sual sayi 1-50 araliginda olmalidir.' using errcode = '22023';
  end if;
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = p_student_id;
  if not app.has_active_subscription(v_st.account_id) then
    raise exception 'Sehvler uzerinde is abune paketine daxildir.' using errcode = '42501';
  end if;
  if v_st.class_id is null then
    raise exception 'Sagird hec bir qrupda deyil.' using errcode = '22023';
  end if;

  select array_agg(qid) into v_qids from (
    select aa.question_id as qid
      from public.attempt_answers aa
      join public.attempts a on a.id = aa.attempt_id
                            and a.student_id = p_student_id
                            and a.status = 'submitted'
      join public.questions q on q.id = aa.question_id
                             and q.status = 'published'
     where aa.is_correct is not true
     group by aa.question_id
     order by count(*) desc, max(aa.answered_at) desc
     limit p_count) z;

  v_n := coalesce(array_length(v_qids, 1), 0);
  if v_n = 0 then
    return jsonb_build_object('ok', false, 'error', 'Sehv edilmis sual tapilmadi.');
  end if;

  select q.subject_id into v_subj from public.questions q
   where q.id = any(v_qids) group by q.subject_id
   order by count(*) desc limit 1;
  select q.level_id into v_lev from public.questions q
   where q.id = any(v_qids) and q.level_id is not null
   group by q.level_id order by count(*) desc limit 1;
  select p.id into v_prog from public.programs p where p.slug = 'ibtidai';

  insert into public.tests
    (owner_type, owner_id, program_id, subject_id, level_id, title,
     status, shuffle_questions, shuffle_options, is_remedial)
  values ('educator', v_uid, v_prog, v_subj, v_lev,
          v_st.display_name || ' — səhvlər üzərində iş',
          'published', true, true, true)
  returning id into v_test;

  insert into public.test_questions (test_id, question_id, ord)
  select v_test, q, row_number() over ()
    from unnest(v_qids) q;

  perform public.rpc_assign_test(
    v_st.class_id, v_test, now() + interval '7 days', 1, p_student_id);

  return jsonb_build_object('ok', true, 'test_id', v_test, 'count', v_n);
end $$;

revoke all on function public.rpc_remedial_test(uuid, int) from public, anon;
grant execute on function public.rpc_remedial_test(uuid, int) to authenticated;

do $x$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name = 'tests' and column_name = 'is_remedial') then
    raise exception 'is_remedial sutunu yaranmadi';
  end if;
  raise notice 'Duzelis testi artiq YARANANDA nisanlanir.';
end $x$;
