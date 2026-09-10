-- =====================================================================
--  180_suret.sql - «sayt lengdirmi?» sualini OLCU ile cavablandirir
--
--  NIYE
--  Bu suala indiyedek yalniz "mene ele gelir ki" cavabi var idi.
--  Menim konteynerdən etdiyim olcme de cavab deyil: mesele
--  muellimin Baki-daki telefonunda nə qeder cekdiyidir, menim
--  serverimde yox.  Olcu ISTIFADECININ BRAUZERINDE goturulmelidir.
--
--  NE OLCULUR
--  Panelin ILK ACILISI: sehife acilmaga baslayandan Icmal ekrani
--  ISLEK olana qeder kecen vaxt (qruplar cizilir).  Bu, muellimin
--  "yavas" dediyi andir - sonraki kecidler onsuz da sürətlidir.
--
--  HECM: gunde UC setir (muellim/sagird/valideyn), setir-setir hadise
--  YOX.  Histoqram kovalari saxlanilir (<1s, 1-2s, 2-4s, 4-8s, 8s+),
--  ona gore medyani da, "nece faizi yavas idi"ni de vermek olur,
--  amma il erzinde cemi ~1000 setir yigilir.  db/179-da danisdigimiz
--  hecm derdini oz elimizle yaratmiriq.
--
--  OZ ACILISLARIMIZ SAYILIR - ziyaret saygacindan (db/175) FERQLI
--  olaraq.  Sebeb: ziyaretde meqsed "nece nefer geldi"dir, orada oz
--  girisimiz reqemi sisirir.  Burada meqsed "nece cekdi"dir - admin
--  de real istifadecidir, onun olcusu de dogrudur.  Istifadeci azken
--  numune toplamagin yegane yolu budur.
-- =====================================================================

create table if not exists public.perf_days (
  day    date   not null default app.baki_bugun(),
  page   text   not null,
  n      int    not null default 0,
  ms_sum bigint not null default 0,
  ms_max int    not null default 0,
  --  kovalar: <1s, 1-2s, 2-4s, 4-8s, 8s+
  b1 int not null default 0,
  b2 int not null default 0,
  b3 int not null default 0,
  b4 int not null default 0,
  b5 int not null default 0,
  primary key (day, page),
  constraint perf_page_ck check (page in ('muellim','sagird','valideyn'))
);
alter table public.perf_days enable row level security;
revoke all on public.perf_days from public, anon, authenticated;

comment on table public.perf_days is
  'Gunluk suret olcusu (db/180): setir-setir hadise yox, kovalar.';

--  Olcunu yazir.  Sessiya basina BIR defe cagirilir (muellim/app.js).
create or replace function public.rpc_perf(p_page text, p_ms int)
returns void
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_ms int;
begin
  if auth.uid() is null then return; end if;
  if p_page is null or p_page not in ('muellim','sagird','valideyn') then return; end if;
  --  Ag-qara deyerleri atmiriq, KIRPIRIK: 2 dəqiqədən uzun olcme
  --  brauzerin arxa fonda dayandirdigi tabdir, olcu deyil.
  v_ms := least(greatest(coalesce(p_ms, 0), 1), 120000);
  if v_ms >= 120000 then return; end if;

  insert into public.perf_days (day, page, n, ms_sum, ms_max, b1, b2, b3, b4, b5)
  values (app.baki_bugun(), p_page, 1, v_ms, v_ms,
          case when v_ms <  1000 then 1 else 0 end,
          case when v_ms >= 1000 and v_ms < 2000 then 1 else 0 end,
          case when v_ms >= 2000 and v_ms < 4000 then 1 else 0 end,
          case when v_ms >= 4000 and v_ms < 8000 then 1 else 0 end,
          case when v_ms >= 8000 then 1 else 0 end)
  on conflict (day, page) do update set
    n      = public.perf_days.n + 1,
    ms_sum = public.perf_days.ms_sum + excluded.ms_sum,
    ms_max = greatest(public.perf_days.ms_max, excluded.ms_max),
    b1 = public.perf_days.b1 + excluded.b1,
    b2 = public.perf_days.b2 + excluded.b2,
    b3 = public.perf_days.b3 + excluded.b3,
    b4 = public.perf_days.b4 + excluded.b4,
    b5 = public.perf_days.b5 + excluded.b5;
end $$;
revoke all on function public.rpc_perf(text, int) from public, anon;
grant  execute on function public.rpc_perf(text, int) to authenticated;

--  Admin ekrani ucun yekun.
create or replace function public.rpc_admin_suret(p_days int default 30)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_from date;
  v_n    bigint;
  v_sum  bigint;
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;
  v_from := app.baki_bugun() - least(greatest(coalesce(p_days, 30), 1), 180);

  select coalesce(sum(n), 0), coalesce(sum(ms_sum), 0) into v_n, v_sum
    from public.perf_days where day >= v_from and page = 'muellim';

  return jsonb_build_object(
    'n',    v_n,
    'gun',  (app.baki_bugun() - v_from),
    'orta', case when v_n > 0 then round(v_sum::numeric / v_n) end,
    'max',  (select max(ms_max) from public.perf_days
              where day >= v_from and page = 'muellim'),
    --  kovalar: ekranda "nece faizi yavas idi" bundan cixir
    'kova', (select jsonb_build_array(coalesce(sum(b1),0), coalesce(sum(b2),0),
                                      coalesce(sum(b3),0), coalesce(sum(b4),0),
                                      coalesce(sum(b5),0))
               from public.perf_days where day >= v_from and page = 'muellim'),
    --  gun-gun: kicik sutun qrafiki ucun
    'gunler', coalesce((
      select jsonb_agg(jsonb_build_object('d', to_char(day, 'YYYY-MM-DD'),
                                          'n', n,
                                          'orta', round(ms_sum::numeric / greatest(n, 1)))
                       order by day)
        from public.perf_days where day >= v_from and page = 'muellim'), '[]'::jsonb));
end $$;
revoke all on function public.rpc_admin_suret(int) from public, anon;
grant  execute on function public.rpc_admin_suret(int) to authenticated;
