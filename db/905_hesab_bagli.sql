-- =====================================================================
--  905 : PULSUZ HAL YOXDUR — SINAQ BITENDE HESAB BAGLANIR (2026-10-01)
--
--  QERAR (sahib, 01.10): ilk qeydiyyatdan kecene 1 ay sinaq verilir; ondan
--  sonra HECNE pulsuz qalmir.  Muddeti sahib EL ILE uzadir.
--  Evvel: abunesi olmayan hesab «pulsuz hedde» dusurdu (5 sagird yeri, oz
--  suallar/testler, 7 gunluk hesabat, sagirde gunde 5 sual).  Bu hal SOKULUR.
--
--  NE EDIR (1-A / 2-B):
--    1-A  Muellimin sinagi/guzesti bitibse HESAB BAGLIDIR: serverde YENI
--         qrup, sagird, tapsiriq, ev tapsirigi, dars, plan, sual YARATMAQ
--         olmur (trigger); muellim panelinde bir bagli ekran gorunur.
--         Melumat SILINMIR.  Muddet uzadilan kimi her sey geri qayidir.
--    2-B  Sagird ve valideyn: ARTIQ VERILMIS testlere ve oz neticelerine
--         baxmaqda davam edir; yeni tapsiriq gelmir (muellim yarada bilmir)
--         ve oz basina mesq (gunde 5 sual) BAGLANIR.
--
--  AYAR (oldurme duymesi):  app_state.hesab_bagli = {"on": true}
--    Sehv olsa, tam geri almaq ucun:
--      update public.app_state set val = '{"on": false}' where key = 'hesab_bagli';
--    on=false olanda butun kohne davranis (pulsuz hedd) qayidir.
--
--  KIM BAGLANMIR: admin hesabi (has_active_subscription admini sayir),
--  numune (is_demo) hesablari, aktiv sinaq/abune - guzest gunleri daxil
--  (app.grace_days).  Yerli test bazasinda ayar SONDURULUR (run.sh) - qalan
--  testler abunesiz hesabla isleyir.
--
--  NIYE TRIGGER (RPC govdesi deyil): yazma yollari onlarladir, cox RPC birbasa
--  cedvele yazir.  Trigger HAMISINI bir yerde tutur, RPC govdelerini
--  kocurmek (itmis setir riski) lazim gelmir.
--
--  ON SERT: 25 (class_plan_items), 137/196 (practice_quota), 222-904.
-- =====================================================================

insert into public.app_state (key, val)
values ('hesab_bagli', '{"on": true}'::jsonb)
on conflict (key) do nothing;

create or replace function app.hesab_bagli_on() returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select coalesce((select (val->>'on')::boolean from public.app_state
                    where key = 'hesab_bagli'), false)
$$;

--  Hesab baglidir: ayar acigdir, aktiv abune/sinaq YOXDUR, numune ve admin deyil.
create or replace function app.account_locked(p_account uuid) returns boolean
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select app.hesab_bagli_on()
     and p_account is not null
     and not app.has_active_subscription(p_account)
     and not coalesce((select a.is_demo from public.accounts a
                        where a.id = p_account), false)
$$;

-- ------------------------------------------------- trigger: yaratma baglanir
create or replace function app.trg_hesab_bagli() returns trigger
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  j     jsonb;
  v_acc uuid;
begin
  if not app.hesab_bagli_on() then return new; end if;     --  tez cixis
  j := to_jsonb(new);
  v_acc := nullif(j->>'account_id', '')::uuid;
  if v_acc is null and nullif(j->>'class_id', '') is not null then
    select c.account_id into v_acc from public.classes c
     where c.id = (j->>'class_id')::uuid;
  end if;
  if v_acc is not null and app.account_locked(v_acc) then
    raise exception 'Hesabın müddəti bitib. Davam etmək üçün bizə yazın.'
      using errcode = '42501';
  end if;
  return new;
end $$;

--  plan setri «Kecildi» (UPDATE done_at: null -> deyer)
create or replace function app.trg_hesab_bagli_plan() returns trigger
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_acc uuid;
begin
  if not app.hesab_bagli_on() then return new; end if;
  select c.account_id into v_acc
    from public.class_plans p join public.classes c on c.id = p.class_id
   where p.id = new.plan_id;
  if v_acc is not null and app.account_locked(v_acc) then
    raise exception 'Hesabın müddəti bitib. Davam etmək üçün bizə yazın.'
      using errcode = '42501';
  end if;
  return new;
end $$;

drop trigger if exists hesab_bagli on public.classes;
create trigger hesab_bagli before insert on public.classes
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli on public.students;
create trigger hesab_bagli before insert on public.students
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli on public.assignments;
create trigger hesab_bagli before insert on public.assignments
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli on public.homework;
create trigger hesab_bagli before insert on public.homework
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli on public.lessons;
create trigger hesab_bagli before insert on public.lessons
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli on public.class_plans;
create trigger hesab_bagli before insert on public.class_plans
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli on public.questions;
create trigger hesab_bagli before insert on public.questions
  for each row execute function app.trg_hesab_bagli();
drop trigger if exists hesab_bagli_plan on public.class_plan_items;
create trigger hesab_bagli_plan before update of done_at on public.class_plan_items
  for each row when (old.done_at is null and new.done_at is not null)
  execute function app.trg_hesab_bagli_plan();

-- ------------------------------------------------- sagird: oz basina mesq (2-B)
--  Gunluk limit baglı hesabin sagirdi ucun 0.  Verilmis testler ve neticeler
--  bu funksiyaya baxmir - toxunulmur.  137/196-dan govde ayni, yalniz o_max.
create or replace function app.practice_quota(p_student uuid,
  out o_paid boolean, out o_used int, out o_max int)
language sql stable as $$
  select app.has_active_subscription(s.account_id),
         coalesce((select d.n from public.practice_days d
                    where d.student_id = s.id and d.day = current_date), 0),
         case when app.account_locked(s.account_id) then 0
              else app.practice_daily_limit() end
    from public.students s where s.id = p_student
$$;
revoke all on function app.practice_quota(uuid) from public, anon, authenticated;

-- ------------------------------------------------- panel: «baglidirmi?» (1-A)
--  Netice SEBEBI de deyir ki, ekran duz yazsin: sinaq bitibse «Sınaq müddəti bitib», PULLU abune
--  bitibse «Abunə müddəti bitib».  Son abunenin statusu hokm edir (trialing = sinaq).
--  kind: 'sinaq' | 'abune' | 'yox' (hec vaxt abunesi olmayib).
drop function if exists public.rpc_account_locked(uuid);
create or replace function public.rpc_account_lock(p_account uuid)
returns jsonb
language sql stable security definer
set search_path = public, extensions, pg_temp as $$
  select case when app.is_account_member(p_account) then
    jsonb_build_object(
      'locked', app.account_locked(p_account),
      'kind', coalesce((select case when s.status = 'trialing' then 'sinaq' else 'abune' end
                          from public.subscriptions s
                         where s.account_id = p_account
                         order by s.current_period_end desc nulls last, s.created_at desc limit 1), 'yox'),
      'ends', (select max(s.current_period_end) from public.subscriptions s
                where s.account_id = p_account))
    else jsonb_build_object('locked', false) end
$$;
revoke all on function public.rpc_account_lock(uuid) from public, anon;
grant execute on function public.rpc_account_lock(uuid) to authenticated;
