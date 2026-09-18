-- =====================================================================
--  211 : SEHV DEFTERI ABUNE PAKETINE KECIR (2026-09-18)
--
--  Qerar (istifadeci): «abunelikde edek».  Sebeb: usaq her gun tetbiqe
--  girir, lezzetini gorur; abune bitende ozu muellime deyir «bunlari
--  evvelki kimi nece isledim?» - abuneye maraq usaqdan da gelir.
--
--  AMMA tam gizletmirik: usaq NE ITIRDIYINI gormelidir, yoxsa
--  muelliminden istemez.  Ona gore:
--    * sayğaclar ve MOVZU siyahisi pulsuzda da gelir (nece sual gozleyir)
--    * mesq suallari ('items') ve cavab yazmaq abune ilədir
--    * 'paid' bayragi - sagird ekrani duymeni sondurur ve sebebi yazir
--
--  Numune hesab (136) abunelidir, ona gore numunede her sey isleyir.
-- =====================================================================
create or replace function public.rpc_student_mistakes(
  p_token text, p_topic uuid default null, p_limit int default 10)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st   uuid := app.session_student(p_token);
  v_n    int  := least(greatest(coalesce(p_limit, 10), 1), 20);
  v_acc  uuid;
  v_paid boolean;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  select account_id into v_acc from public.students where id = v_st;
  v_paid := app.has_active_subscription(v_acc);

  return jsonb_build_object(
    --  211: usaq gorur ki, nese var - amma acmaq muellimin abunesi ilədir
    'paid',   v_paid,
    'open',   (select count(*) from public.mistakes where student_id = v_st and status = 'open'),
    'review', (select count(*) from public.mistakes where student_id = v_st and status = 'review'),
    'closed', (select count(*) from public.mistakes where student_id = v_st and status = 'closed'),
    'due',    (select count(*) from public.mistakes
                where student_id = v_st and status <> 'closed' and next_at <= now()),
    'topics', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', x.tid, 'name', coalesce(x.tname, 'Digər'), 'due', x.n)
             order by x.n desc, x.tname)
        from (select t.id tid, t.name tname, count(*) n
                from public.mistakes m
                join public.questions q on q.id = m.question_id and q.status = 'published'
                left join public.topics t on t.id = q.topic_id
               where m.student_id = v_st and m.status <> 'closed' and m.next_at <= now()
               group by t.id, t.name) x), '[]'::jsonb),
    --  211: suallar YALNIZ abune ile - siyahi bos gelir, sayğaclar qalir
    'items', case when not v_paid then '[]'::jsonb else coalesce((
      select jsonb_agg(jsonb_build_object(
               'qid', q.id, 'body', app.pq_render(q.body, pv.v), 'kind', q.kind, 'media_url', q.media_url,
               'topic', t.name, 'status', m.status, 'wrong_n', m.wrong_n,
               'options', coalesce((
                 select jsonb_agg(jsonb_build_object('id', o.id, 'body', app.pq_render(o.body, pv.v)) order by o.ord)
                   from public.question_options o where o.question_id = q.id), '[]'::jsonb))
             order by (m.status = 'open') desc, m.next_at, m.last_at)
        from (select m2.* from public.mistakes m2
               join public.questions q2 on q2.id = m2.question_id and q2.status = 'published'
               where m2.student_id = v_st and m2.status <> 'closed' and m2.next_at <= now()
                 and (p_topic is null or q2.topic_id is not distinct from p_topic)
               order by (m2.status = 'open') desc, m2.next_at, m2.last_at limit v_n) m
        join public.questions q on q.id = m.question_id
        left join public.topics t on t.id = q.topic_id
        cross join lateral (select app.pq_seed(q.params, q.id) as v) pv), '[]'::jsonb) end);
end $$;
revoke all on function public.rpc_student_mistakes(text, uuid, int) from public;
grant execute on function public.rpc_student_mistakes(text, uuid, int) to anon, authenticated;

-- ---------------------------------------------------------------------
--  Cavab yazmaq da abune ile.
--
--  DIQQET (18.09): burada evvel MARKER usulu var idi - canlidaki
--  funksiyanin metnini herfbeherf tapib evez edirdi.  Canlida ise metn
--  bizimkinden ferqli cixdi (bosluq/setir sonu) ve fayl «markeri 1 defe
--  olmalidir» deyib DAYANDI.  Indi govde TAM yazilir (db/175-in etdiyi
--  kimi) - fayl tek basina, teleb olunan qeder defe islədilə bilər ve
--  canlidaki metnden asili deyil.
-- ---------------------------------------------------------------------
create or replace function public.rpc_student_mistake_answer(p_token text, p_question_id uuid, p_option_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st  uuid := app.session_student(p_token);
  v_ok  boolean;
  v_exp text;
  v_m   public.mistakes%rowtype;
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  --  211: sehv defteri abune paketine daxildir
  if not app.has_active_subscription(
       (select account_id from public.students where id = v_st)) then
    raise exception 'Səhv dəftəri abunə paketinə daxildir.' using errcode = '42501';
  end if;
  select * into v_m from public.mistakes where student_id = v_st and question_id = p_question_id;
  if v_m.student_id is null or v_m.status = 'closed' or v_m.next_at > now() then
    raise exception 'Bu sual defterde gozlemir.' using errcode = '22023';
  end if;
  select o.is_correct into v_ok from public.question_options o
   where o.id = p_option_id and o.question_id = p_question_id;
  if v_ok is null then
    raise exception 'Variant tapilmadi.' using errcode = '22023';
  end if;
  select coalesce(q.explanation, '') into v_exp from public.questions q where q.id = p_question_id;
  perform app.mistake_note(v_st, p_question_id, v_ok, true);
  select * into v_m from public.mistakes where student_id = v_st and question_id = p_question_id;
  return jsonb_build_object('correct', v_ok, 'explanation', v_exp, 'status', v_m.status,
                            'next_at', v_m.next_at,
                            'due', (select count(*) from public.mistakes
                                     where student_id = v_st and status <> 'closed' and next_at <= now()));
end $$;
revoke all on function public.rpc_student_mistake_answer(text, uuid, uuid) from public;
grant execute on function public.rpc_student_mistake_answer(text, uuid, uuid) to anon, authenticated;
