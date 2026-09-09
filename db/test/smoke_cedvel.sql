-- =====================================================================
--  smoke_cedvel.sql : qrupun heftelik cedveli (db/177)
--
--  Uc iddia yoxlanilir:
--   1. ISTEYE BAGLI - cedvel qurulmayibsa 'on' false, valideynde null.
--      Bos kart hec bir ekranda cixmamalidir.
--   2. LEGV EDILEN DERS SIYAHIDA QALIR (hal='cancelled') - yoxsa
--      muellim onu geri qaytara bilmir (ilk qurulusda bele idi).
--   3. PULSUZDUR - abunesiz hesabda da tam isleyir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.lesson_changes;  delete from public.class_schedule;
delete from public.attendance;      delete from public.lessons;
delete from public.parent_sessions; delete from public.students;
delete from public.classes;         delete from public.subscriptions;
delete from public.account_members; delete from public.accounts;
delete from public.user_roles;      delete from public.profiles;
delete from auth.users;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11110000-0000-0000-0000-00000000cd01','cd@t.az','{"full_name":"Cedvel M"}'),
  ('11110000-0000-0000-0000-00000000cd02','yad@t.az','{"full_name":"Yad M"}');
insert into public.accounts (id, type, name, owner_id) values
  ('aaaa0000-0000-0000-0000-00000000cd01','tutor','Cedvel hesabi','11110000-0000-0000-0000-00000000cd01'),
  ('aaaa0000-0000-0000-0000-00000000cd02','tutor','Yad hesab','11110000-0000-0000-0000-00000000cd02');
insert into public.account_members values
  ('aaaa0000-0000-0000-0000-00000000cd01','11110000-0000-0000-0000-00000000cd01',true),
  ('aaaa0000-0000-0000-0000-00000000cd02','11110000-0000-0000-0000-00000000cd02',true);
insert into public.classes (id, account_id, teacher_id, kind, name, join_code) values
  ('cccc0000-0000-0000-0000-00000000cd01','aaaa0000-0000-0000-0000-00000000cd01',
   '11110000-0000-0000-0000-00000000cd01','tutor_group','9-A','KODCD001'),
  ('cccc0000-0000-0000-0000-00000000cd02','aaaa0000-0000-0000-0000-00000000cd01',
   '11110000-0000-0000-0000-00000000cd01','tutor_group','11-B','KODCD002');
insert into public.students (id, account_id, class_id, created_by, full_name,
                             display_name, login_code, parent_code) values
  ('5555000c-0000-0000-0000-00000000cd01','aaaa0000-0000-0000-0000-00000000cd01',
   'cccc0000-0000-0000-0000-00000000cd01','11110000-0000-0000-0000-00000000cd01',
   'Ayan Qasimova','Ayan Q.','SHVCD001','VLDCD001');

\echo '--- hazirliq tamam'
set role authenticated;
set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000cd01';

-- =====================================================================
--  1. Cedvel qurulmayib -> hec bir ekranda gorunmur
-- =====================================================================
do $$
declare w jsonb; v jsonb; tok text;
begin
  w := public.rpc_week();
  assert not (w->>'on')::boolean, 'cedvel yoxdur, amma on=true';
  assert jsonb_array_length(w->'days') = 0, 'cedvelsiz hesabda gun cixdi';
  reset role; reset request.jwt.claim.sub;
  tok := public.rpc_parent_login('VLDCD001')->>'token';
  v := public.rpc_parent_home(tok);
  assert v ? 'week', 'valideyn ekraninda week acari yoxdur';
  assert v->>'week' is null, 'cedvel yoxdur, amma valideynde bos kart cixir';
  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000cd01';
end $$;
\echo 'OK  1 · cedvel qurulmayanda hec bir ekranda gorunmur'

-- =====================================================================
--  2. Cedvel qurulur - hefte dolur
-- =====================================================================
do $$
declare d jsonb; w jsonb; n int;
begin
  d := public.rpc_schedule_set('cccc0000-0000-0000-0000-00000000cd01',
        '[{"weekday":3,"starts_at":"16:00","mins":90},
          {"weekday":6,"starts_at":"11:00","mins":60}]'::jsonb);
  assert (d->>'n')::int = 2, 'iki ders yazilmadi';
  assert jsonb_array_length(d->'rows') = 2, 'rows iki deyil';
  w := public.rpc_week();
  assert (w->>'on')::boolean, 'cedvel var, amma on=false';
  select count(*) into n from jsonb_array_elements(w->'days') x
   where x->>'class' = '9-A';
  assert n = 2, format('heftede 9-A ucun 2 ders olmalidir, %s var', n);
end $$;
\echo 'OK  2 · cedvel qurulur, hefte dolur'

-- =====================================================================
--  3. Toqqusma XEBERDARLIQDIR - yazmaga mane olmur
-- =====================================================================
do $$
declare d jsonb;
begin
  d := public.rpc_schedule_set('cccc0000-0000-0000-0000-00000000cd02',
        '[{"weekday":3,"starts_at":"16:30","mins":60}]'::jsonb);
  assert (d->>'n')::int = 1, 'toqqusma yazmaga mane oldu - xeberdarliq olmalidir';
  assert jsonb_array_length(d->'conflicts') = 1,
    format('toqqusma tapilmadi: %s', d->'conflicts');
  assert d->'conflicts'->0->>'class' = '9-A', 'toqqusan qrupun adi yanlisdir';
end $$;
\echo 'OK  3 · ust-uste dusen saat xeberdarliq verir, yazmaga mane olmur'

-- =====================================================================
--  4. LEGV: ders siyahidan SILINMIR, «cancelled» olur
--     (yoxsa «Bərpa et» ucun tutacaq qalmir)
-- =====================================================================
do $$
declare g date; w jsonb; x jsonb;
begin
  select (r->>'date')::date into g from jsonb_array_elements(public.rpc_week()->'days') r
   where r->>'class' = '9-A' order by 1 limit 1;
  perform public.rpc_lesson_move('cccc0000-0000-0000-0000-00000000cd01', g);
  w := public.rpc_week();
  select r into x from jsonb_array_elements(w->'days') r
   where r->>'class' = '9-A' and (r->>'date')::date = g;
  assert x is not null, 'legv edilen ders siyahidan ITDI - berpa mumkun olmur';
  assert x->>'hal' = 'cancelled', format('hal cancelled deyil: %s', x->>'hal');
  --  geri al
  perform public.rpc_lesson_restore('cccc0000-0000-0000-0000-00000000cd01', g);
  select r into x from jsonb_array_elements(public.rpc_week()->'days') r
   where r->>'class' = '9-A' and (r->>'date')::date = g;
  assert x->>'hal' = 'plan', 'legv geri alinmadi';
end $$;
\echo 'OK  4 · legv edilen ders siyahida qalir, geri alina bilir'

-- =====================================================================
--  5. KOCURME: kohne gunde moved_out, yeni gunde moved_in
-- =====================================================================
do $$
declare g date; w jsonb; a jsonb; b jsonb;
begin
  select (r->>'date')::date into g from jsonb_array_elements(public.rpc_week()->'days') r
   where r->>'class' = '9-A' order by 1 limit 1;
  perform public.rpc_lesson_move('cccc0000-0000-0000-0000-00000000cd01', g, g + 1, '18:00');
  w := public.rpc_week();
  select r into a from jsonb_array_elements(w->'days') r
   where r->>'class' = '9-A' and (r->>'date')::date = g;
  select r into b from jsonb_array_elements(w->'days') r
   where r->>'class' = '9-A' and (r->>'date')::date = g + 1;
  assert a->>'hal' = 'moved_out', format('kohne gun moved_out deyil: %s', a->>'hal');
  assert (a->>'other')::date = g + 1, 'kohne gunde hara kocduyu yazilmayib';
  assert b->>'hal' = 'moved_in', format('yeni gun moved_in deyil: %s', b->>'hal');
  assert b->>'time' = '18:00', format('yeni saat yanlisdir: %s', b->>'time');
  perform public.rpc_lesson_restore('cccc0000-0000-0000-0000-00000000cd01', g);
end $$;
\echo 'OK  5 · kocurme iki terefde de gorunur'

-- =====================================================================
--  6. Valideyn heftesi - PULSUZ (abune yoxdur)
-- =====================================================================
do $$
declare tok text; v jsonb;
begin
  if exists (select 1 from public.subscriptions
              where account_id = 'aaaa0000-0000-0000-0000-00000000cd01') then
    raise exception 'yoxlama qurulusu: hesabda abune OLMAMALIDIR';
  end if;
  reset role; reset request.jwt.claim.sub;
  tok := public.rpc_parent_login('VLDCD001')->>'token';
  v := public.rpc_parent_home(tok);
  assert not (v->>'paid')::boolean, 'hesab abunesiz olmalidir';
  assert v->>'week' is not null, 'cedvel abune ile baglanib - PULSUZ olmalidir';
  assert jsonb_array_length(v->'week') = 2, format('valideynde 2 ders gozlenilir: %s', v->'week');
  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000cd01';
end $$;
\echo 'OK  6 · valideyn heftesi abunesiz de gorunur (pulsuzdur)'

-- =====================================================================
--  7. Cedvel silinende her sey temizlenir
-- =====================================================================
do $$
declare tok text; v jsonb; n int;
begin
  perform public.rpc_lesson_move('cccc0000-0000-0000-0000-00000000cd01',
            (current_date + 1));
  perform public.rpc_schedule_set('cccc0000-0000-0000-0000-00000000cd01', '[]'::jsonb);
  reset role; reset request.jwt.claim.sub;
  --  cedvel setirleri RLS ile baglidir - superuser kimi baxiriq
  select count(*) into n from public.lesson_changes
   where class_id = 'cccc0000-0000-0000-0000-00000000cd01';
  assert n = 0, 'cedvel silindi, amma legv/kocurme setirleri qaldi';
  tok := public.rpc_parent_login('VLDCD001')->>'token';
  v := public.rpc_parent_home(tok);
  assert v->>'week' is null, 'cedvel silindi, amma valideynde hele gorunur';
  set role authenticated;
  set request.jwt.claim.sub = '11110000-0000-0000-0000-00000000cd01';
end $$;
\echo 'OK  7 · cedvel silinende legv/kocurmeler de temizlenir'

-- =====================================================================
--  8. Huquqlar: yad muellim toxuna bilmir, anon cagira bilmir
-- =====================================================================
do $$
declare ok1 boolean := false;
begin
  set local request.jwt.claim.sub = '11110000-0000-0000-0000-00000000cd02';
  begin
    perform public.rpc_schedule_set('cccc0000-0000-0000-0000-00000000cd01',
              '[{"weekday":1,"starts_at":"09:00"}]'::jsonb);
  exception when others then ok1 := true; end;
  assert ok1, 'yad muellim ozge qrupun cedvelini deyisdi';
end $$;
do $$
begin
  if has_function_privilege('anon','public.rpc_week(date)','EXECUTE') then
    raise exception 'anon cedveli oxuya bilir';
  end if;
  if has_function_privilege('anon','public.rpc_schedule_set(uuid, jsonb)','EXECUTE') then
    raise exception 'anon cedveli deyise bilir';
  end if;
  if has_function_privilege('authenticated','app.cedvel_araliq(uuid, date, integer)','EXECUTE') then
    raise exception 'daxili funksiya birbasa cagirila bilir';
  end if;
end $$;
\echo 'OK  8 · huquqlar duzgun bolusdurulub'

\echo 'CEDVEL: BUTUN YOXLAMALAR KECDI'
