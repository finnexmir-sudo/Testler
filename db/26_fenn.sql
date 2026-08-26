-- =====================================================================
--  26_fenn.sql : muellimin tedris fennleri
--
--  Hesabda "hansi fennleri tedris edirem" siyahisi saxlanilir
--  (subjects text[] - fenn sluglari).  Interfeys bu siyahiya gore
--  fenn seceklerini daraldir: sual banki, generator, ders plani.
--
--  Bu MEHDUDIYYET deyil, FILTRDIR: bos siyahi = hamisi gorunur,
--  server terefde hec bir sorgu baglanmir.  Muellim profilden
--  istediyi vaxt deyisir.
--
--  rpc_my_context 06-dakini EYNI IMZA ile genislendirir (hesaba
--  'subjects' sahesi elave olunur) - 06-ya toxunulmur ki, movcud
--  bazada tek bu fayli isletmek kifayet etsin.
--
--  ON SERT: 01 (accounts), 04 (subjects), 06 (rpc_my_context).
--  SONRA:   hec ne - huquqlar bu faylin ozundedir.
--  Tekrar isledile biler.
-- =====================================================================

alter table public.accounts
  add column if not exists subjects text[] not null default '{}';

-- ------------------------------------------------- fennleri yazmaq
--  Yalniz movcud fenn sluglari saxlanilir - qalani sakitce atilir
--  (secim UI-dan gelir, seif slug ancaq elle duzeldilmis sorgudan
--  gele biler; ona xeta yox, temizleme kifayetdir).
create or replace function public.rpc_set_subjects(
  p_account_id uuid, p_subjects text[] default '{}')
returns jsonb
language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_clean text[];
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not exists (select 1 from public.account_members
                  where account_id = p_account_id and user_id = v_uid) then
    raise exception 'Bu hesaba giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  if coalesce(array_length(p_subjects, 1), 0) > 20 then
    raise exception 'Fenn sayi hedden coxdur.' using errcode = '22023';
  end if;

  v_clean := coalesce((
    select array_agg(distinct s.slug order by s.slug)
      from public.subjects s
      join unnest(coalesce(p_subjects, '{}'::text[])) x on x = s.slug),
    '{}'::text[]);

  update public.accounts set subjects = v_clean where id = p_account_id;

  return jsonb_build_object('ok', true, 'subjects', to_jsonb(v_clean));
end $$;

-- ------------------------------------------------- kontekst + fennler
--  06_educator_rpc.sql-deki rpc_my_context-in genislendirilmis kopyasi:
--  hesab obyektine 'subjects' elave olunur.  Orada deyisiklik etsen,
--  BURANI da yenile.
create or replace function public.rpc_my_context()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  return jsonb_build_object(
    'user_id', v_uid,
    'profile', (select jsonb_build_object('full_name', p.full_name, 'phone', p.phone)
                  from public.profiles p where p.id = v_uid),
    'roles',   coalesce((select jsonb_agg(role) from public.user_roles where user_id = v_uid), '[]'::jsonb),
    'accounts', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',    a.id,
               'type',  a.type,
               'name',  a.name,
               'is_owner', a.owner_id = v_uid,
               'subjects', to_jsonb(a.subjects),
               'students_used',  app.account_student_count(a.id),
               'students_limit', app.account_seat_limit(a.id),
               'plan', (select jsonb_build_object('slug', pl.slug, 'name', pl.name)
                          from public.subscriptions s2
                          join public.plans pl on pl.id = s2.plan_id
                         where s2.account_id = a.id
                           and s2.status in ('trialing','active')
                           and (s2.current_period_end is null or s2.current_period_end > now())
                         order by s2.started_at desc limit 1)
             ) order by a.name)
        from public.accounts a
        join public.account_members m on m.account_id = a.id and m.user_id = v_uid
    ), '[]'::jsonb)
  );
end $$;

-- ---------------------------------------------------------------- huquq
revoke all on function public.rpc_set_subjects(uuid, text[]) from public, anon;
revoke all on function public.rpc_my_context()               from public, anon;

grant execute on function public.rpc_set_subjects(uuid, text[]) to authenticated;
grant execute on function public.rpc_my_context()               to authenticated;

do $$
begin
  if has_function_privilege('anon', 'public.rpc_set_subjects(uuid, text[])', 'EXECUTE') then
    raise exception 'anon fenn yaza bilir!';
  end if;
  raise notice 'Tedris fennleri quruldu.';
end $$;
