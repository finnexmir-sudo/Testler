-- =====================================================================
--  927 : app.pq_seed -- CEHD SAYI 40 -> 200 (2026-10-08)
--
--  NIYE
--  Riyaziyyatda sablon (parametrik) suallar bank fayllarina gelir.  Bezi sablonlarin
--  sherti SERTDIR (mes. a%b=0 ve ya a<>b and b>1 kimi: tesadufi qiymetin tutma ehtimali
--  1/15 ve ya az).  pq_seed 40 cehd edirdi:
--    * strict (yadda saxlayanda / pq_check): 40 cehdde tutmayan sablon YUKLEMEDE sinirdi
--      (1/15 sertde ehtimal ~6 %, her bank faylinda yuzlerle sual);
--    * strict deyil (cehd baslayanda / render): 40 cehd tutmasa SON (shertini POZAN)
--      qiymet qayidirdi - sagirde yalan sual.
--  200 cehdde (14/15)^200 ~ 1e-6: praktik olaraq bitir.  Qiymet: sert olmayan sablonda
--  ilk cehdde cixir, elave xerc yoxdur; yalniz cox sert sablon 200 dovr edir (ms).
--
--  Yalniz dovr sayi deyisir; qalan govde 926_sablon_reqem.sql-deki pq_seed-den EYNEN (METN ve IZAH da yoxlanir).
--  ON SERT: 132, 926_sablon_reqem.   Tekrar isledile biler.
-- =====================================================================

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
  for i in 1..200 loop  -- 927: 40 idi; sert shertli sablon yukleme/render zamani sinmasin
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

revoke all on function app.pq_seed(jsonb, uuid, boolean) from public, anon, authenticated;
