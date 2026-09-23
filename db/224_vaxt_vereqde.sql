-- =====================================================================
--  224 : VAXT LIMITI VEREQDE GORUNMURDU (2026-09-23)
--
--  QUSUR
--  Muellim teste 5 deqiqe limit qoyur, baza duzgun yazir (300 s), amma
--  ekranda HEC NE deyismir:
--    * vereq basliginda «⏱ 5 dəq» cixmir
--    * vaxt cipi yene «vaxtsız» yazir - sanki secim itib
--    * cap basliginda «vaxt: 5 dəq» yoxdur
--
--  SEBEB
--  rpc_test_preview qaytardigi obyektde «time_limit_sec» YOXDUR.
--  192 vaxt limitini elave edende bu RPC-ye yazmagi unudub.  Interfeys
--  t.time_limit_sec oxuyur, undefined alir, uc yeri de bos buraxir.
--  Yani bu imkan MUELLIM terefinde hec vaxt islememisdir.
--
--  SAGIRD TEREFI SAGDIR: geri sayan saat, avtomatik gonderme, guzest,
--  server hesabi - hamisi isleyir, cunki onlar sutunu cedvelden
--  birbasa oxuyur.  e2e_vaxt.py-nin qalan 20 bendi bunu tesdiqleyir.
--
--  NECE TAPILDI
--  Test sehifesinin duymelerini yenidən quranda e2e_vaxt isledildi ve
--  3 ugursuzluq cixdi.  Yoxlanildi: KOHNE kodda da eynidir - yeni
--  deyil.  Demeli qusur 192-den beri orada durub.
--
--  TAM govde yazilir (marker uslubu istifade edilmir).
--  ON SERT: 132 (rpc_test_preview), 192 (time_limit_sec sutunu).
-- =====================================================================

create or replace function public.rpc_test_preview(p_test_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v jsonb;
  v_acc    uuid;
  v_class  uuid;
  v_wrongs text[] := null;
begin
  if not app.can_manage_test(p_test_id) then
    raise exception 'Bu test sizin deyil.' using errcode = '42501';
  end if;

  --  Test sehv-cutlesdirme ile yigilibsa, veraqda "sehve benzer"
  --  nisani gosterilir.  Qrup yeniden yoxlanir - qayda kohne ola biler.
  select nullif(t.gen_rule->>'class', '')::uuid into v_class
    from public.tests t where t.id = p_test_id;
  if v_class is not null then
    v_acc := app.pick_account(null);
    if exists (select 1 from public.classes c
                where c.id = v_class and c.account_id = v_acc) then
      select array_agg(w.b) into v_wrongs from (
        select distinct app.norm_body(coalesce(nullif(aa.question_body, ''), q.body)) b
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = 'submitted'
          join public.students st on st.id = a.student_id and st.class_id = v_class
          left join public.questions q on q.id = aa.question_id
         where aa.is_correct = false
         limit 300) w;
    end if;
  end if;

  select jsonb_build_object(
    'id', t.id, 'title', t.title, 'gen_rule', t.gen_rule,
    'subject', s.name, 'level', l.name,
    --  224: VAXT LIMITI.  192 bu imkani elave etdi, amma bu RPC-ye
    --  yazmadi - muellim 5 deq secirdi, baza yazirdi, ekran ise
    --  gostermirdi (sahe undefined idi).  Uc yer birden bos qalirdi:
    --  veraq basligi, «vaxtsiz» cipi, cap basligi.  Sagird terefi
    --  islyirdi, cunki o, sutunu cedvelden birbasa oxuyur.
    'time_limit_sec', t.time_limit_sec,
    'done', (select count(*) from public.attempts a
              where a.test_id = t.id and a.status = 'submitted'),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'ord',  tq.ord,
               'id',   q.id,
               'body', app.pq_render(q.body, pv.v),
               'tpl',  q.params is not null,
               'kind', q.kind,
               'difficulty', q.difficulty,
               'topic', tp.name,
               'explanation', app.pq_render(q.explanation, pv.v),
               'mine', q.owner_type = 'educator',
               'remedial', (v_wrongs is not null and exists (
                  select 1 from unnest(v_wrongs) w
                   where similarity(app.norm_body(q.body), w) >= app.rem_similarity())),
               'options', coalesce((
                  select jsonb_agg(jsonb_build_object(
                           'body', app.pq_render(o.body, pv.v), 'correct', o.is_correct) order by o.ord)
                    from public.question_options o
                   where o.question_id = q.id), '[]'::jsonb)
             ) order by tq.ord)
        from public.test_questions tq
        join public.questions q on q.id = tq.question_id
        left join public.topics tp on tp.id = q.topic_id
        --  132: vereq bir variantdir - her acilisda teze qiymet
        cross join lateral (select app.pq_seed(q.params, q.id) as v) pv
       where tq.test_id = t.id), '[]'::jsonb)
  ) into v
   from public.tests t
   join public.subjects s on s.id = t.subject_id
   left join public.levels l on l.id = t.level_id
  where t.id = p_test_id;
  return v;
end $$;

-- ------------------------------------------------- huquq
revoke all on function public.rpc_test_preview(uuid) from public, anon;
grant execute on function public.rpc_test_preview(uuid) to authenticated;
