-- =====================================================================
--  102_movzu_qoruyucu.sql — istifadede olan movzu SESSIZCE silinmesin
--
--  NIYE
--  Movzu agacimiz e-derslikden gelir ve derslik her il yenilene biler:
--  ad deyisir, sira deyisir, movzu elave olunur VE YA CIXARILIR.
--  Illik yenilemede kohne setirler silinende bir tehluke var:
--
--      class_plan_items.topic_id ... on delete CASCADE
--
--  Yeni movzu silinse, o, HER MUELLIMIN ders planindan yox olurdu -
--  "kecildi" tarixcesi ile birlikde.  Muellim planinin qisaldigini
--  hec bilmirdi.  Ustelik topics.parent_id de cascade-dir: bir bolme
--  silinse alt movzulari, onlar da plan setirlerini aparirdi.
--
--  15_movzular_ederslik.sql-deki movcud qoruyucu bunu GORMURDU - o,
--  yalniz sual ve generator qaydasina baxir.  Yeni suali olmayan,
--  amma muellimin planinda duran movzu silinebilerdi.
--
--  NE EDIRIK
--  1. FK "restrict" olur: plan setirinde duran movzu silinmek istense
--     baza XETA ATIR.  Itki sessiz olmur - yenileme skripti dayanir
--     ve insan qerar verir (adətən: silmek yox, ADINI yenilemek).
--  2. app.topu_islekdir(uuid) - movzunun istifadede olub-olmadigini
--     bir yerde cavablandirir: sual, plan setiri, generator qaydasi,
--     alt movzu.  Illik yenileme skriptleri bunu cagirsin, oz-ozune
--     sert yazmasin.
--
--  NE DEYISMIR
--  Plan SILINENDE setirler yene gedir - o, ayri FK-dir (plan_id),
--  ona toxunulmur.  Sual/cavab elaqeleri onsuz da "set null" idi:
--  movzu silinse suallar ve kecmis neticeler QALIR.
-- =====================================================================

-- ------------------------------------------------- FK: cascade -> restrict
alter table public.class_plan_items
  drop constraint if exists class_plan_items_topic_id_fkey;

alter table public.class_plan_items
  add constraint class_plan_items_topic_id_fkey
  foreign key (topic_id) references public.topics(id) on delete restrict;

-- ------------------------------------------------------ istifade yoxlamasi
--  Movzu "islekdir"se silinmemelidir.  Dord elaqe sayilir:
--    - sual ona baglidir
--    - muellimin ders planinda setirdir
--    - generator qaydasinda adi kecir (yigilmis testler tekrarlana bilsin)
--    - alt movzusu var (onu silsek ovladlari da gedir)
create or replace function app.topu_islekdir(p_topic uuid) returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (select 1 from public.questions q where q.topic_id = p_topic)
      or exists (select 1 from public.class_plan_items i where i.topic_id = p_topic)
      or exists (select 1 from public.topics c where c.parent_id = p_topic)
      or exists (select 1 from public.tests t
                  where jsonb_typeof(t.gen_rule->'topics') = 'array'
                    and t.gen_rule->'topics' ? p_topic::text)
$$;

revoke all on function app.topu_islekdir(uuid) from public, anon, authenticated;

-- --------------------------------------------------------------- yoxlama
do $$
declare v_del text;
begin
  select confdeltype into v_del from pg_constraint
   where conrelid = 'public.class_plan_items'::regclass
     and conname  = 'class_plan_items_topic_id_fkey';
  if v_del is distinct from 'r' then
    raise exception 'plan setiri hele de cascade ile silinir (confdeltype=%)', v_del;
  end if;
  --  plan_id tereferi DEYISMEMELIDIR - plan silinende setirler getmelidir
  select confdeltype into v_del from pg_constraint
   where conrelid = 'public.class_plan_items'::regclass
     and conname  = 'class_plan_items_plan_id_fkey';
  if v_del is distinct from 'c' then
    raise exception 'plan silinende setirler artiq getmir (confdeltype=%)', v_del;
  end if;
  raise notice 'Movzu qoruyucusu quruldu: istifadedeki movzu silinmir.';
end $$;
