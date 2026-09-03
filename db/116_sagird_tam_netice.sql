-- =====================================================================
--  116_sagird_tam_netice.sql : netice ekraninda BUTUN suallar gorunur
--
--  Evvel yalniz SEHV suallar gorunurdu (sual + izah), sagirdin OZUNUN
--  ne secdiyi hec vaxt gosterilmirdi.  Istifadeci teklif etdi: "testi
--  tam gormeyin faydasi olarmi?" - beli, amma sərt bir serhedle:
--
--  DUZ CAVAB (question_options.is_correct) HEC VAXT qayitmir - bu
--  qayda pozulmur.  Bil10 sual banki satir; duz cavab sagird terefine
--  cixsa, screenshot alinib paylasila biler ve gelecek imtahan yazanlar
--  (basqa muellimin sagirdleri daxil) o cavab acarindan aldana biler.
--
--  Netice: her sual ucun sagirdin OZ sectiyi variantlarin METNI
--  gosterilir (bunu artiq testi yazarken gorub - yeni sizinti yoxdur),
--  ve dogru/sehv olub-olmadigi (boolean, hansi variantin dogru oldugu
--  yox).  Duz suallar da siyahiya elave olundu - evvel yalniz sehvler
--  gorunurdu.
--
--  'wrong' saha adi 'questions'-a deyisdi ve BUTUN suallari daşıyır -
--  frontend (sagird/app.js) bu adla yenilendi.
-- =====================================================================

create or replace function public.rpc_test_result(p_token text, p_test_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_student uuid := app.session_student(p_token);
  v_att  public.attempts%rowtype;
  v_test public.tests%rowtype;
begin
  if v_student is null then
    raise exception 'Sessiya bitib. Yeniden daxil ol.' using errcode = '28000';
  end if;

  select * into v_att from public.attempts
   where student_id = v_student and test_id = p_test_id and status = 'submitted'
   order by percent desc, finished_at desc
   limit 1;
  if not found then
    raise exception 'Bu testin neticesi tapilmadi.' using errcode = '22023';
  end if;

  select * into v_test from public.tests where id = p_test_id;

  return jsonb_build_object(
    'attempt_id',   v_att.id,
    'score',        v_att.score,
    'max_score',    v_att.max_score,
    'percent',      v_att.percent,
    'passed',       v_att.percent >= v_test.pass_percent,
    'duration_sec', v_att.duration_sec,
    'finished_at',  v_att.finished_at,
    'can_retry',    false,   -- baxis rejimi: cehd bitib
    'test', jsonb_build_object('id', v_test.id, 'title', v_test.title,
                               'pass_percent', v_test.pass_percent),
    'questions', coalesce((
      --  Suret: sagird hansi sual gorubse, onu gosteririk.
      --  Sual sonradan redakte olunsa da bu netice deyismir.
      --  "picked" - sagirdin sectiyi variantIN METNI, o cavabi
      --  testi yazarken artiq gorub - burda YENI heç nə sızmır.
      --  Hansi variantin DOGRU oldugu (is_correct) heç vaxt qayıtmır.
      select jsonb_agg(x order by tq.ord)
        from public.attempt_answers aa
        join public.test_questions tq
          on tq.test_id = v_att.test_id and tq.question_id = aa.question_id
        cross join lateral (
          select jsonb_build_object(
                   'question_id', aa.question_id,
                   'body',        aa.question_body,
                   'explanation', aa.question_explanation,
                   'correct',     aa.is_correct,
                   --  Metn tipli sual variant deyil, yazi qebul edir -
                   --  onda selected_option_ids bosdur, text_answer dolur.
                   'picked',      case
                     when aa.text_answer is not null and aa.text_answer <> ''
                       then jsonb_build_array(aa.text_answer)
                     else coalesce((
                       select jsonb_agg(o.body order by o.ord)
                         from public.question_options o
                        where o.id = any(aa.selected_option_ids)), '[]'::jsonb)
                   end
                 ) as x
        ) q
       where aa.attempt_id = v_att.id), '[]'::jsonb)
  );
end $$;
