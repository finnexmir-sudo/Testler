-- =====================================================================
--  smoke_bank_axtaris.sql : 907 (bank axtarisi movzu adina da baxir) + 908 (rpc_topic_search)
--  Hamisi tranzaksiyada, sonda GERI alinir (baza deyismir).
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;
begin;

insert into auth.users (id, email) values ('11110000-0000-0000-0000-0000000009a1', 'axtaris@t.az');
insert into public.accounts (id, type, name, owner_id, is_demo)
values ('aaaa0000-0000-0000-0000-0000000009a1', 'tutor', 'Axtaris', '11110000-0000-0000-0000-0000000009a1', false);
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-0000000009a1', '11110000-0000-0000-0000-0000000009a1', true);

--  Sintetik fesil + alt movzu (yarpaq); bir platforma sualini ora kocururuk.
--  Sualin metninde «frazeoloji» SOZU YOXDUR - tapilmali olan yalniz adla.
insert into public.topics (id, subject_id, parent_id, slug, name, sort)
select '99990000-0000-0000-0000-0000000009a1', s.id, null, 'smoke-fesil-xyz', 'Smoke Fəsil Xyz', 999
  from public.subjects s where s.slug = 'az-dili';
insert into public.topics (id, subject_id, parent_id, slug, name, sort)
select '99990000-0000-0000-0000-0000000009a2', s.id, '99990000-0000-0000-0000-0000000009a1',
       'smoke-frazeoloji', 'Frazeoloji birləşmələr', 1
  from public.subjects s where s.slug = 'az-dili';
-- fesil altinda ayri bir movzu da: «kok fesil» yolunu yoxlamaq ucun
insert into public.topics (id, subject_id, parent_id, slug, name, sort)
select '99990000-0000-0000-0000-0000000009a3', s.id, '99990000-0000-0000-0000-0000000009a1',
       'smoke-alt-movzu', 'Smoke Alt Qeyd', 2
  from public.subjects s where s.slug = 'az-dili';

create temp table _q as
  select q.id from public.questions q
    join public.subjects s on s.id = q.subject_id
   where s.slug = 'az-dili' and q.owner_type = 'platform' and q.status = 'published'
   order by q.created_at limit 2;
grant select on _q to authenticated;

--  1-ci sual: fesilin ADI ile tapilir (topic_id = alt movzu a3, parent = fesil a1)
update public.questions set topic_id = '99990000-0000-0000-0000-0000000009a3',
       tags = array[]::text[], body = 'Smoke sual bir: sabit ifadəni seçin.'
 where id = (select id from _q order by id limit 1);
--  2-ci sual: topic_id = FESIL, alt movzu yalniz 'ders:' nisani ile bagli
update public.questions set topic_id = '99990000-0000-0000-0000-0000000009a1',
       tags = array['ders:smoke-frazeoloji'], body = 'Smoke sual iki: sabit ifadəni seçin.'
 where id = (select id from _q order by id desc limit 1);

set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-0000000009a1';

do $$
declare
  v_a jsonb; v_id1 uuid; v_id2 uuid;
  n_all int; n_blank int; n_real int;
begin
  select id into v_id1 from _q order by id limit 1;
  select id into v_id2 from _q order by id desc limit 1;

  --  alt movzunun adi ('ders:' nisani): sual metninde sozu yoxdur
  v_a := public.rpc_bank_list('{"pool":"platform","q":"frazeoloji birləşmə"}'::jsonb, 100, 0);
  assert (select count(*) from jsonb_array_elements(v_a->'items') i where (i->>'id')::uuid = v_id2) = 1,
         'alt movzu adi (ders: nisani) ile sual tapilmadi';

  --  movzunun adi
  v_a := public.rpc_bank_list('{"pool":"platform","q":"smoke alt qeyd"}'::jsonb, 100, 0);
  assert (select count(*) from jsonb_array_elements(v_a->'items') i where (i->>'id')::uuid = v_id1) = 1,
         'movzu adi ile sual tapilmadi';

  --  fesilin adi: HER IKI sual fesilin altindadir
  v_a := public.rpc_bank_list('{"pool":"platform","q":"Smoke Fəsil Xyz"}'::jsonb, 100, 0);
  assert (v_a->>'total')::int = 2, 'fesil adi ile 2 sual gozlenirdi, ' || (v_a->>'total');

  --  sual metni evvelki kimi
  v_a := public.rpc_bank_list('{"pool":"platform","q":"Smoke sual iki"}'::jsonb, 100, 0);
  assert (v_a->>'total')::int = 1, 'sual metni ile axtaris pozuldu';

  --  hec ne tapilmayan soz
  v_a := public.rpc_bank_list('{"pool":"platform","q":"zzqqxx-yoxdur"}'::jsonb, 100, 0);
  assert (v_a->>'total')::int = 0, 'olmayan soz netice verdi';

  --  bos / bosluq q = suzgec yoxdur
  n_all := (public.rpc_bank_list('{"pool":"platform"}'::jsonb, 1, 0)->>'total')::int;
  n_blank := (public.rpc_bank_list('{"pool":"platform","q":"   "}'::jsonb, 1, 0)->>'total')::int;
  assert n_all = n_blank, 'bosluq q suzgec kimi iseledi: ' || n_all || ' vs ' || n_blank;

  --  real movzu (sual metninde adi kecmeyen suallar): evvel yalniz metnle tapilirdi
  v_a := public.rpc_bank_list('{"pool":"platform","subject":"az-dili","q":"Söz birləşmələri"}'::jsonb, 1, 0);
  n_real := (v_a->>'total')::int;
  assert n_real >= 50, 'real movzu adi ile az sual tapildi: ' || n_real;
  assert (select count(*) from public.questions q join public.topics t on t.id = q.topic_id
           where q.owner_type = 'platform' and q.status = 'published' and t.name = 'Söz birləşmələri') <= n_real,
         'movzunun bezi suallari axtarisda yoxdur';


  ---------------------------------------------------------------- 908: rpc_topic_search
  v_a := public.rpc_topic_search('smoke alt qeyd', 'platform');
  assert jsonb_array_length(v_a) = 1, '908: 1 movzu gozlenirdi: ' || v_a::text;
  assert v_a->0->>'name' = 'Smoke Alt Qeyd' and (v_a->0->>'n')::int = 1, '908: ad/say: ' || v_a::text;
  assert v_a->0->>'subject_slug' = 'az-dili' and v_a->0->>'subject' is not null, '908: fenn qaytarilmadi: ' || v_a::text;

  --  fesil adi de movzudur (ona suallar birbasa bagli olanda): 2 movzu, ikisi de «Smoke ...» ile baslayir
  v_a := public.rpc_topic_search('Smoke', 'platform');
  assert jsonb_array_length(v_a) = 2, '908: «Smoke» ucun 2 movzu gozlenirdi: ' || v_a::text;

  --  suali olmayan movzu (alt movzu yarpagi) cixmir
  v_a := public.rpc_topic_search('frazeoloji', 'platform');
  assert jsonb_array_length(v_a) = 0, '908: suali olmayan movzu cixdi: ' || v_a::text;

  --  2 simvoldan qisa / bos
  assert jsonb_array_length(public.rpc_topic_search('s', 'platform')) = 0, '908: 1 simvol netice verdi';
  assert jsonb_array_length(public.rpc_topic_search('   ', 'platform')) = 0, '908: bosluq netice verdi';

  --  hovuz: «oz suallarim» - muellimin oz sualı yoxdur, platforma movzusu cixmir
  assert jsonb_array_length(public.rpc_topic_search('smoke alt qeyd', 'mine')) = 0, '908: mine hovuzunda platforma movzusu cixdi';

  --  real movzu: sual sayi sifirdan boyuk, limit isleyir
  v_a := public.rpc_topic_search('Söz birləşmələri', 'platform', 1);
  assert jsonb_array_length(v_a) = 1 and (v_a->0->>'n')::int > 0, '908: real movzu: ' || v_a::text;

  --  yanlis hovuz
  begin
    perform public.rpc_topic_search('smoke', 'xyz');
    assert false, '908: yanlis hovuz xeta vermedi';
  exception when sqlstate '22023' then null; end;

  raise warning 'smoke_bank_axtaris: HAMISI KECDI (real movzu: % sual)', n_real;
end $$;

reset role; reset request.jwt.claim.sub;
rollback;
