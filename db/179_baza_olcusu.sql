-- =====================================================================
--  179_baza_olcusu.sql - admin ekraninda BAZANIN HECMI
--
--  NIYE
--  Supabase-in tarifi hecme baglidir (Free 500 MB, Pro 8 GB).  Admin
--  bu reqemi hec yerde gormurdu - yalniz Supabase panelinde, o da
--  bolgusuz.  "Pulsuz istifadeciler nə vaxt sixinti yaradar?" sualina
--  cavab vermek ucun UC sey lazimdir: umumi hecm, bankin payi (sabit
--  xerc) ve istifadeci datasinin pullu/pulsuz bolgusu.
--
--  OLCU USULU - durust olmaq ucun aciq yazilir:
--  Postgres "bu setir hansi hesabindir" deye bayt saymir.  Ona gore
--  her cedvel ucun SETIR BASINA BAYT hesablanir (total_relation_size /
--  setir sayi, indekslerle birlikde), sonra hesab qruplarinin setir
--  saylarina vurulur.  Yeni yaxinlasmadir, deqiq bayt deyil - ekranda
--  da "təxmini" yazilir.  Bolunmemis qaliq ('qalan') GIZLEDILMIR:
--  sistem cedvelleri, auth sxemi, WAL - hamisi orada gorunur.
--
--  ARTIM: son 30 gunde cavablanan suallarin sayi x setir bayti.  Bu,
--  bazanin real boyume suretidir - qalan cedveller bunun yaninda
--  xirdadir.  Ondan "500 MB-a ne vaxt catir" hesablanir.
--
--  YALNIZ ADMIN.  Bank hecmi adi muellime gosterilmir (CLAUDE.md,
--  "Bank hecmi yalniz admine"), bu ekran onsuz da admin ekranidir.
-- =====================================================================

--  Setir basina bayt (indekslerle birlikde).
--
--  ESAS TELE - burada tutuldu (smoke_baza, 4 setirde 24 KB cixdi):
--  az setirli cedvelde total_relation_size/say ALDADIR.  Bos sehife,
--  dord indeksin oz sehifeleri - hamisi bir nece setire bolunur ve
--  reqem 50 defe siser.  Real amortize olunmus deyer 434 baytdir.
--  Ona gore ASAGI HEDD var: setir sayi p_min-den azdirsa NULL
--  qaytarilir - "hele olculmur".  Uydurma reqem yazmaqdansa
--  ekranda "—" yazmaq durustdur; bu kart onsuz da plan qurmaq
--  ucundur, 4 setirde planlasdirilasi sey yoxdur.
create or replace function app.baza_bpr(p_table regclass, p_min bigint default 1000)
returns numeric
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare n bigint;
begin
  execute format('select count(*) from %s', p_table) into n;
  if coalesce(n, 0) < greatest(p_min, 1) then return null; end if;
  return pg_total_relation_size(p_table)::numeric / n;
end $$;
revoke all on function app.baza_bpr(regclass, bigint) from public, anon, authenticated;

create or replace function public.rpc_admin_baza()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_db      bigint;
  v_bpr_aa  numeric;    -- attempt_answers: bir cavabin bayti
  v_bpr_at  numeric;    -- attempts
  v_bpr_st  numeric;    -- students
  v_bank    numeric;
  v_pullu   numeric := 0;
  v_pulsuz  numeric := 0;
  v_demo    numeric := 0;
  --  SETIR SAYLARI da qaytarilir: bayt TEXMINIDIR, say deqiqdir.
  --  Az data olanda bpr yanilda biler (bir setirlik cedvel de bir
  --  sehife + indeks tutur), say ise hemise duzdur.
  c_pullu   bigint := 0;  s_pullu  bigint := 0;
  c_pulsuz  bigint := 0;  s_pulsuz bigint := 0;
  c_demo    bigint := 0;  s_demo   bigint := 0;
  v_artim   numeric := 0;
  v_gun     numeric;
  v_olcu    boolean;
  r         record;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  v_db     := pg_database_size(current_database());
  --  Bolgu ucun esas cedvel attempt_answers-dir.  O olculmurse
  --  (setir azdir), bolgu de olculmur - qalanlari onun yaninda
  --  xirdadir, tek baslarina yanildici seklde boyuk gorunerdiler.
  v_bpr_aa := app.baza_bpr('public.attempt_answers');
  v_bpr_at := coalesce(app.baza_bpr('public.attempts'), 0);
  v_bpr_st := coalesce(app.baza_bpr('public.students'), 0);
  v_olcu   := v_bpr_aa is not null;

  --  BANK = platforma suallari + onlarin variantlari + movzu agaci.
  --  Suallar cedvelinde muellimin oz suallari da var, ona gore setir
  --  sayina gore bolunur.
  v_bank :=
      coalesce(app.baza_bpr('public.questions'), 0)
        * (select count(*) from public.questions where owner_type = 'platform')
    + coalesce(app.baza_bpr('public.question_options'), 0)
        * (select count(*) from public.question_options o
            join public.questions q on q.id = o.question_id
           where q.owner_type = 'platform')
    + pg_total_relation_size('public.topics');

  --  ISTIFADECI DATASI - hesab qruplari uzre.  Agir cedvel
  --  attempt_answers-dir (bir cavab ~430 bayt), sonra attempts ve
  --  students; qalanlari bunlarin yaninda xirdadir.
  for r in
    with acc as (
      select a.id, a.is_demo,
             app.has_active_subscription(a.id) as paid
        from public.accounts a
    )
    select acc.is_demo, acc.paid,
           (select count(*) from public.attempt_answers aa
              join public.attempts att on att.id = aa.attempt_id
              join public.students s   on s.id = att.student_id
             where s.account_id = acc.id) as n_aa,
           (select count(*) from public.attempts att
              join public.students s on s.id = att.student_id
             where s.account_id = acc.id) as n_at,
           (select count(*) from public.students s where s.account_id = acc.id) as n_st
      from acc
  loop
    declare v numeric := r.n_aa * coalesce(v_bpr_aa, 0)
                       + r.n_at * v_bpr_at + r.n_st * v_bpr_st;
    begin
      if r.is_demo then
        v_demo := v_demo + v;  c_demo := c_demo + r.n_aa;  s_demo := s_demo + r.n_st;
      elsif r.paid then
        v_pullu := v_pullu + v;  c_pullu := c_pullu + r.n_aa;  s_pullu := s_pullu + r.n_st;
      else
        v_pulsuz := v_pulsuz + v;  c_pulsuz := c_pulsuz + r.n_aa;  s_pulsuz := s_pulsuz + r.n_st;
      end if;
    end;
  end loop;

  --  ARTIM: son 30 gunun cavablari.  Demo hesab sayilmir - onun datasi
  --  numunedir, real yuk deyil.
  v_artim := coalesce(v_bpr_aa, 0) * (
    select count(*) from public.attempt_answers aa
      join public.attempts att on att.id = aa.attempt_id
      join public.students s   on s.id = att.student_id
      join public.accounts a   on a.id = s.account_id
     where not a.is_demo
       and aa.answered_at > now() - interval '30 days');

  --  500 MB-a ne qeder qalib?  Artim sifirdirsa null - "hesablanmir".
  v_gun := case when v_artim > 0
                then greatest(0, (500::numeric * 1024 * 1024 - v_db)) / (v_artim / 30.0)
                else null end;

  return jsonb_build_object(
    'db',      v_db,
    'bank',    round(v_bank),
    --  «olculur» yalanci reqemin qarsisini alir: false olanda ekran
    --  bayt yerine «—» yazir, saylar ise hemise dogrudur.
    'olculur', v_olcu,
    'pullu',   jsonb_build_object('bayt', case when v_olcu then round(v_pullu) end,
                                  'cavab', c_pullu,  'sagird', s_pullu),
    'pulsuz',  jsonb_build_object('bayt', case when v_olcu then round(v_pulsuz) end,
                                  'cavab', c_pulsuz, 'sagird', s_pulsuz),
    'demo',    jsonb_build_object('bayt', case when v_olcu then round(v_demo) end,
                                  'cavab', c_demo,   'sagird', s_demo),
    --  bolunmemis qaliq: sistem cedvelleri, auth sxemi, indeks bosluqlari
    'qalan',   greatest(0, round(v_db - v_bank - v_pullu - v_pulsuz - v_demo)),
    'artim30', case when v_olcu then round(v_artim) end,
    'gun500',  case when v_olcu and v_gun is not null then round(v_gun) end,
    'bpr',     case when v_olcu then round(v_bpr_aa) end);
end $$;

revoke all on function public.rpc_admin_baza() from public, anon;
grant  execute on function public.rpc_admin_baza() to authenticated;
