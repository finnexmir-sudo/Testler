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
--  Cavab yazmaq da abune ile (129-un govdesi + yoxlama)
-- ---------------------------------------------------------------------
do $$
declare
  v_src  text := pg_get_functiondef('public.rpc_student_mistake_answer(text, uuid, uuid)'::regprocedure);
  v_mark text := 'raise exception ''Sessiya bitib. Yeniden daxil ol.'' using errcode = ''28000'';
  end if;';
  v_add  text;
begin
  if position('abune paketine daxildir' in v_src) > 0 then
    raise notice '211 artiq tetbiq olunub, kecilir';
    return;
  end if;
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception '211: rpc_student_mistake_answer markeri 1 defe olmalidir';
  end if;
  v_add := v_mark || '
  --  211: sehv defteri abune paketine daxildir
  if not app.has_active_subscription(
       (select account_id from public.students where id = v_st)) then
    raise exception ''Səhv dəftəri abune paketine daxildir.'' using errcode = ''42501'';
  end if;';
  execute replace(v_src, v_mark, v_add);
end $$;
revoke all on function public.rpc_student_mistake_answer(text, uuid, uuid) from public;
grant execute on function public.rpc_student_mistake_answer(text, uuid, uuid) to anon, authenticated;
