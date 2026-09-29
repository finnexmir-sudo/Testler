-- =====================================================================
--  902_sehv_cavablari.sql — SAGIRD HESABATI: «SAGIRD NE YAZDI, DUZU NEDIR»
--
--  BOSLUQ.  Muellimin sagird hesabatinin «Sehvler» sekmesi en cox sehv
--  edilen 10 sualin METNINI ve izahini gosterirdi, amma sagirdin HANSI
--  cavabi secdiyini ve duz cavabin ne oldugunu YOX.  Bu, «cavab vereqi»nde
--  (Tarixce) var idi - ama teke-tek cehd acmaq lazim idi.
--
--  NIYE YENI FUNKSIYA (rpc_student_report-a elave yox).  rpc_student_report
--  400+ setirlik funksiyadir, govdesi pg_get_functiondef ile bir nece defe
--  kocurulub (900, 129, 133, 188...) - her kocurme bir setri itire biler
--  (CLAUDE.md: «Yeni sutun elave edende - RPC-ye de yaz», db/224 hadisesi).
--  Ayrica kicik funksiya: KOHNE hesabat oldugu kimi qalir, bu fayl isledilmese
--  ekran sadece «Yazdi/Duz» setrini gostermir (xeta yox).
--
--  TEHLUKESIZLIK.  Muellim artiq rpc_attempt_sheet ile eyni melumati
--  (chosen / correct) gorur - eyni yoxlamalar: app.can_read_student,
--  abune.  Sagirdin OZ tokeni bu funksiyaya catmir (yalniz authenticated).
--
--  Qaytarir: [{qid, chosen, correct}] - HER SUAL ucun sagirdin SON sehv
--  cavabi (en cox 200 sual).
--
--  ISLETMEK: bu fayl; qrant faylin oz icindedir (05_grants tekrar lazim deyil).
-- =====================================================================
create or replace function public.rpc_student_wrong_detail(p_student_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_st public.students%rowtype;
begin
  select * into v_st from public.students where id = p_student_id;
  if not found then
    raise exception 'Sagird tapilmadi.' using errcode = '22023';
  end if;
  if not app.can_read_student(p_student_id) then
    raise exception 'Bu sagirdin hesabatina giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  --  Sehv siyahisi abune ile acilir (rpc_student_report 'weak' de belədir) -
  --  abunesizde bos qaytaririq, xeta yox.
  if not app.has_active_subscription(v_st.account_id) then
    return '[]'::jsonb;
  end if;

  return coalesce((
    select jsonb_agg(z.x)
      from (
        select distinct on (aa.question_id)
               jsonb_build_object(
                 'qid', aa.question_id,
                 'chosen', coalesce((
                    select string_agg(o.body, ' · ' order by o.ord)
                      from public.question_options o
                     where o.id = any(aa.selected_option_ids)),
                    nullif(btrim(coalesce(aa.text_answer, '')), ''), '—'),
                 'correct', coalesce((
                    select string_agg(o.body, ' · ' order by o.ord)
                      from public.question_options o
                     where o.question_id = aa.question_id and o.is_correct), '')
               ) as x
          from public.attempt_answers aa
          join public.attempts a on a.id = aa.attempt_id
                                and a.student_id = p_student_id
                                and a.status = 'submitted'
         where aa.is_correct is not true
         order by aa.question_id, a.finished_at desc
         limit 200
      ) z), '[]'::jsonb);
end $$;

revoke all on function public.rpc_student_wrong_detail(uuid) from public, anon;
grant execute on function public.rpc_student_wrong_detail(uuid) to authenticated;
