-- =====================================================================
--  926 - Sablon (parametrik) suallarda reqem formati
--
--  Problem (2026-10-08 olculdu):
--    {a/b}, a=7, b=2  ->  "3.5"                    (noqte, vergul yox)
--    {a/3}, a=1       ->  "0.33333333333333333333" (sonsuz kesr)
--    {a-b}, a<b       ->  "-3"                     (bankda menfi "−" ile yazilir)
--  Azerbaycan dilinde onluq kesr VERGULLE yazilir; sonsuz kesr ise sual
--  ola bilmez.  Sablonlar az idi (6 sual, hamisi tam ededli) - ona gore
--  gorunmurdu.  Riyaziyyat banki sablona kecir, bu indi lazimdir.
--
--  Ne deyisir:
--    1. app.pq_num  - "3,5", "−3", "−0,25".  Tam eded olduğu kimi.
--    2. app.pq_eval - netice 4 onluq reqemden uzundursa XETA.  Yeni
--       sablonun saxlanmasi (pq_check, 12 numune) bunu tutur; muellif
--       sert yazir (a%b=0).
--    3. app.pq_seed - qiymet secende sualin METNINI de yoxlayir (evvel
--       yalniz variantlari).  Uzun kesr / sifira bolme veren qiymet
--       atilir, basqasi secilir - test sinmir.
--
--  Hesablama deyismir: pq_cond ve pq_subst eyni qalir.  Movcud 6 sablon
--  tam ededli ve musbetdir - gorunusu deyismir (smoke 1 yoxlayir).
--
--  Idempotent; 132-den sonra isledilir.
-- =====================================================================

do $$ begin
  if to_regprocedure('app.pq_seed(jsonb, uuid, boolean)') is null then
    raise exception 'ONCE 132_parametrik_sual.sql isledilmelidir';
  end if;
end $$;

-- ---------------------------------------------------------------------
--  Reqem: 383 · 3,5 · −12 · −0,25   (sonda sifir yox)
-- ---------------------------------------------------------------------
create or replace function app.pq_num(p numeric) returns text
language sql immutable as $$
  select case when p < 0 then '−' else '' end
      || replace(case when p = trunc(p) then trunc(abs(p))::bigint::text
                      else rtrim(rtrim(abs(p)::text, '0'), '.') end, '.', ',')
$$;

-- ---------------------------------------------------------------------
--  Hesab: netice ən çox 4 onluq reqemli olmalidir (1/3 olmaz).
-- ---------------------------------------------------------------------
create or replace function app.pq_eval(p_expr text, p_vars jsonb) returns text
language plpgsql volatile as $$
declare
  e text := app.pq_subst(p_expr, p_vars);
  v numeric;
begin
  if e !~ '^[0-9+\-*/%(). ]+$' then
    raise exception 'Şablon ifadəsi yanlışdır: {%} — yalnız dəyişən, rəqəm və + - * / %% ( ) olar.', p_expr
      using errcode = '22023';
  end if;
  execute 'select (' || e || ')::numeric' into v;
  if v <> round(v, 4) then
    raise exception 'Şablon ifadəsi {%} sonsuz və ya çox uzun kəsr verir (%) — şərt yazın, məsələn a%%b=0.',
      p_expr, (select string_agg(k || '=' || (p_vars->>k), ', ') from jsonb_object_keys(p_vars) k)
      using errcode = '22023';
  end if;
  return app.pq_num(v);
end $$;

-- ---------------------------------------------------------------------
--  Qiymet secimi: sert + variantlar ferqli + METN ve IZAH hesablanir.
-- ---------------------------------------------------------------------
create or replace function app.pq_seed(p_params jsonb, p_qid uuid default null,
                                       p_strict boolean default false) returns jsonb
language plpgsql volatile as $$
declare
  vars jsonb;
  k    text;
  lo bigint; hi bigint;
  i    int;
  ok   boolean;
begin
  if p_params is null then return null; end if;
  for i in 1..40 loop
    vars := '{}'::jsonb;
    for k in select jsonb_object_keys(p_params->'vars') loop
      lo := (p_params->'vars'->k->>0)::bigint;
      hi := (p_params->'vars'->k->>1)::bigint;
      vars := vars || jsonb_build_object(k, lo + floor(random() * (hi - lo + 1))::bigint);
    end loop;
    begin
      ok := true;
      if p_params ? 'cond' then
        ok := app.pq_cond(p_params->>'cond', vars);
      end if;
      if ok and p_qid is not null then
        perform app.pq_render(q.body, vars), app.pq_render(coalesce(q.explanation, ''), vars)
           from public.questions q where q.id = p_qid;
        select count(distinct app.pq_render(o.body, vars)) = count(*) into ok
          from public.question_options o where o.question_id = p_qid;
      end if;
    exception when others then
      ok := false;     -- sifira bolme, uzun kesr - basqa qiymet yoxlanir
    end;
    if ok then return vars; end if;
  end loop;
  if p_strict then
    raise exception 'Şablon üçün uyğun qiymət tapılmadı: şərt çox sərtdir və ya variantlar eyni çıxır.'
      using errcode = '22023';
  end if;
  return vars;
end $$;

revoke all on function app.pq_num(numeric)               from public, anon, authenticated;
revoke all on function app.pq_eval(text, jsonb)          from public, anon, authenticated;
revoke all on function app.pq_seed(jsonb, uuid, boolean) from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  Ozunu yoxlama
-- ---------------------------------------------------------------------
do $$
declare
  ok boolean;
begin
  if app.pq_render('{a/b}', '{"a":7,"b":2}') <> '3,5'
     or app.pq_render('{a-b}', '{"a":2,"b":5}') <> '−3'
     or app.pq_render('{a/b}', '{"a":-1,"b":4}') <> '−0,25'
     or app.pq_render('{a*b}', '{"a":12,"b":34}') <> '408' then
    raise exception '926: reqem formati yanlisdir';
  end if;
  begin
    perform app.pq_render('{a/3}', '{"a":1}');
    ok := false;
  exception when sqlstate '22023' then ok := true;
  end;
  if not ok then raise exception '926: 1/3 redd olunmadi'; end if;
end $$;
