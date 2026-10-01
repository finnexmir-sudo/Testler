-- =====================================================================
--  906_cehd_vereqi_sekil.sql - MUELLIMIN CEHD VEREQINDE SUALIN SEKLI
--
--  BOSLUQ.  db/900 sekli uc yere qaytarmisdi: sagirdin netice ekrani
--  (rpc_submit_attempt, rpc_test_result), muellimin kagiz vereqi
--  (rpc_test_preview) ve sagird hesabatinin 'weak' siyahisi
--  (rpc_student_report).  DORDUNCU yer qalmisdi: muellimin CEHD VEREQI -
--  sagird hesabati -> Tarixce -> bir cehde basanda aciran sual-sual siyahi
--  (rpc_attempt_sheet).  Ekran fig(q.media_url) artiq cagirir, amma RPC sahəni
--  vermirdi - qrafikli suallar vereqde sekilsiz idi («Hansı qrafik
--  artandır?» - muellim ne cavab verildiyini gore bilmirdi).
--  Bankda 85 sekilli sual var (db/308: riyaziyyat 9, funksiyanin qrafiki).
--
--  SECILEN YOL (900-le eyni, orada sebebler yazilib): SUALA QOSULMAQ -
--  left join public.questions.  attempt_answers sualin METNINI nusxeleyir,
--  seklini yox; sema deyismir, kohne cehdler de sekli derhal gosterir.
--  ODENIS: bank sonradan hemin sualin SVG-sini deyisse, kohne vereq yeni sekli
--  gosterecek (metn kohne qalir) - sekil sualin izahidir, cavab deyil.
--  Sual TAM silinse left join null verir - vereq sekilsiz acilir, xeta yox.
--
--  TEHLUKESIZLIK.  is_correct YENE qaytarilmir (yalniz 'ok' - kohne kimi) -
--  bu fayl yalniz bir sahe elave edir.  Sekil <img src>-le cizilir ve unvan
--  suzgecinden kecir (fig()).
--
--  USUL.  Govde TAM yazilir, marker yox.  Cari govde pg_get_functiondef ile
--  goturulub (132-nin sonrasi: params/pq_render), elle kocurulmeyib;
--  yalniz iki setir elave olunub.  Imza deyismir - 05_grants lazim deyil.
--
--  ON SERT: 132 (rpc_attempt_sheet), 900.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.rpc_attempt_sheet(p_attempt_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_a  public.attempts%rowtype;
  v_st public.students%rowtype;
begin
  select * into v_a from public.attempts
   where id = p_attempt_id and status = 'submitted';
  if not found then
    raise exception 'Cehd tapilmadi.' using errcode = '22023';
  end if;
  if not app.can_read_student(v_a.student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  select * into v_st from public.students where id = v_a.student_id;
  if not app.has_active_subscription(v_st.account_id) then
    raise exception 'Cavab vereqi abune paketine daxildir.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'test',    (select t.title from public.tests t where t.id = v_a.test_id),
    'at',      v_a.finished_at,
    'percent', round(v_a.percent, 0),
    'items', coalesce((
      select jsonb_agg(x order by (x->>'ord')::int, x->>'body')
      from (
        select jsonb_build_object(
                 'ord',  coalesce(tq.ord, 999),
                 'body', aa.question_body,
                 'explanation', aa.question_explanation,
                 'ok',   aa.is_correct is true,
                 --  906: sualin sekli (questions.media_url) - 900-deki yol: suala QOSULMAQ, nusxe yox
                 'media_url', qq.media_url,
                 'chosen', coalesce((
                    select string_agg(app.pq_render(o.body, v_a.params->(aa.question_id::text)), ' · ' order by o.ord)
                      from public.question_options o
                     where o.id = any(aa.selected_option_ids)),
                    nullif(btrim(coalesce(aa.text_answer, '')), ''), '—'),
                 'correct', coalesce((
                    select string_agg(app.pq_render(o.body, v_a.params->(aa.question_id::text)), ' · ' order by o.ord)
                      from public.question_options o
                     where o.question_id = aa.question_id and o.is_correct), '')
               ) as x
          from public.attempt_answers aa
          left join public.test_questions tq
                 on tq.test_id = v_a.test_id and tq.question_id = aa.question_id
          left join public.questions qq on qq.id = aa.question_id
         where aa.attempt_id = p_attempt_id
      ) z), '[]'::jsonb));
end $function$;

revoke all on function public.rpc_attempt_sheet(uuid) from public, anon;
grant execute on function public.rpc_attempt_sheet(uuid) to authenticated;
