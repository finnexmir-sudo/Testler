-- =====================================================================
--  210 : «SEHVINI BAGLA» - MOVZU UZRE, YIGCAM PAKET (2026-09-18)
--
--  Sehv defterinin mexanikasi (129) hazir idi: acıq -> tekrar -> bagli,
--  aralarinda bir hefte.  Amma sagird ekranda BIR reqem gorurdu:
--  «10 sual gozleyir · Məşq et».  Konkret hedef yox idi.
--
--  Indi movzu-movzu: «Kəsrlər — 3 sual gözləyir» + «Bağla».  Ucunu de
--  duz cavablasa movzu TEMIZDIR (bir hefte sonra bir de yoxlanacaq).
--  Kicik, bitirile bilen is - «yene test isle» yox.
--
--  rpc_student_mistakes: 'topics' acari (movzu uzre gozleyen sual sayi)
--  + p_topic / p_limit parametrleri.  Kohne imza DROP edilir - anon
--  huquq siyahisi ad uzre isleyir, amma iki imza qalsa smoke_huquq
--  sayini pozardi.
-- =====================================================================
drop function if exists public.rpc_student_mistakes(text);

create or replace function public.rpc_student_mistakes(
  p_token text, p_topic uuid default null, p_limit int default 10)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_st uuid := app.session_student(p_token);
  v_n  int  := least(greatest(coalesce(p_limit, 10), 1), 20);
begin
  if v_st is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;
  return jsonb_build_object(
    'open',   (select count(*) from public.mistakes where student_id = v_st and status = 'open'),
    'review', (select count(*) from public.mistakes where student_id = v_st and status = 'review'),
    'closed', (select count(*) from public.mistakes where student_id = v_st and status = 'closed'),
    'due',    (select count(*) from public.mistakes
                where student_id = v_st and status <> 'closed' and next_at <= now()),
    --  210: MOVZU uzre gozleyen sual sayi - sagird «Kəsrlər — 3 sual»
    --  gorur ve onu baglayir.  Movzusuz suallar bir yerde («Digər»).
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
    --  mesq suallari: movzu verilibse yalniz ondan; DUZ VARIANT GETMIR
    'items', coalesce((
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
        cross join lateral (select app.pq_seed(q.params, q.id) as v) pv), '[]'::jsonb));
end $$;
revoke all on function public.rpc_student_mistakes(text, uuid, int) from public;
grant execute on function public.rpc_student_mistakes(text, uuid, int) to anon, authenticated;
