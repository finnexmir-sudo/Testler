-- =====================================================================
--  124  QISA AD QRUPDA TEKRARLANMASIN
--
--  Canli sual: secim siyahisinda "Huseynov M." iki nefer olanda kim
--  kimdir bilinmirdi.  Iki duzelis:
--    1. Muellim panelindeki butun "Kime" secimleri TAM adi gosterir
--       (app.js) - muellim sagirdini tam adla taniyir.  Qisa ad sagird
--       lovhesi ucundur (yoldaslari tam adi gormesin).
--    2. Qisa ad yaradilanda qrupda tekrar varsa uzadilir:
--       "Murad H." -> "Murad Hu." -> "Murad Huseynov" -> "Murad Huseynov 2".
--       Movcud tekrarlar da bir defelik duzeldilir (asagida).
--  rpc_add_student govdesi 06 uzerindedir - basqa hec ne deyismir.
-- =====================================================================

create or replace function app.unique_display_name(p_class_id uuid, p_full text)
returns text
language plpgsql stable as $$
declare
  v_first text := split_part(p_full, ' ', 1);
  v_last  text := split_part(p_full, ' ', 2);
  v_try   text;
  v_cands text[];
  i int;
begin
  if v_last = '' then
    v_cands := array[v_first];
  else
    v_cands := array[
      v_first || ' ' || upper(left(v_last, 1)) || '.',
      v_first || ' ' || initcap(left(v_last, 2)) || '.',
      v_first || ' ' || v_last];
  end if;
  foreach v_try in array v_cands loop
    if not exists (select 1 from public.students s
                    where s.class_id = p_class_id and s.is_active
                      and lower(s.display_name) = lower(v_try)) then
      return v_try;
    end if;
  end loop;
  --  tam ad da tekrardirsa (eyniadli iki sagird): say elave olunur
  for i in 2..99 loop
    v_try := v_cands[array_length(v_cands, 1)] || ' ' || i;
    exit when not exists (select 1 from public.students s
                           where s.class_id = p_class_id and s.is_active
                             and lower(s.display_name) = lower(v_try));
  end loop;
  return v_try;
end $$;
revoke all on function app.unique_display_name(uuid, text) from public, anon, authenticated;

create or replace function public.rpc_add_student(
  p_class_id uuid, p_full_name text, p_display_name text default null,
  p_birth_year int default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid     uuid := auth.uid();
  v_class   public.classes%rowtype;
  v_code    text;
  v_student uuid;
  v_disp    text;
  i int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;

  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid and not app.is_account_member(v_class.account_id) then
    raise exception 'Bu qrupa sagird elave ede bilmezsiniz.' using errcode = '42501';
  end if;
  if coalesce(btrim(p_full_name), '') = '' then
    raise exception 'Sagird adi bos ola bilmez.' using errcode = '22023';
  end if;

  -- Gorunen ad verilmeyibse addan ilk soz + soyadin bas herfi.
  -- Qrupda eyni qisa ad artiq varsa ("Murad H." iki nefer) uzadilir:
  -- 2 herf -> tam soyad -> tam ad + say (canli sual: "bu kimdir?").
  v_disp := nullif(btrim(coalesce(p_display_name, '')), '');
  if v_disp is null then
    v_disp := app.unique_display_name(p_class_id, btrim(p_full_name));
  end if;

  for i in 1..20 loop
    v_code := app.gen_login_code(8);
    exit when not exists (select 1 from public.students where login_code = v_code);
    v_code := null;
  end loop;
  if v_code is null then
    raise exception 'Giris kodu yaradila bilmedi, yeniden cehd edin.';
  end if;

  -- Yer limiti trigger-i burada isleyir; limit dolubsa check_violation atir.
  insert into public.students
    (account_id, class_id, created_by, full_name, display_name, birth_year, login_code)
  values
    (v_class.account_id, p_class_id, v_uid, btrim(p_full_name), v_disp, p_birth_year, v_code)
  returning id into v_student;

  return jsonb_build_object('id', v_student, 'full_name', btrim(p_full_name),
                            'display_name', v_disp, 'login_code', v_code);
end $$;


--  Movcud tekrarlar: eyni qrupda eyni qisa adli AKTIV sagirdlerden
--  ikinci ve sonrakilar (yaranma sirasi ile) yeniden adlandirilir.
do $$
declare r record; v_new text;
begin
  for r in
    select s.id, s.class_id, s.full_name
      from public.students s
     where s.is_active
       and exists (select 1 from public.students s2
                    where s2.class_id = s.class_id and s2.is_active and s2.id <> s.id
                      and lower(s2.display_name) = lower(s.display_name)
                      --  eyni aninda yaranan iki sagird: id ile sira
                      and (s2.created_at, s2.id) < (s.created_at, s.id))
     order by s.created_at, s.id
  loop
    v_new := app.unique_display_name(r.class_id, btrim(r.full_name));
    update public.students set display_name = v_new where id = r.id;
    raise notice '124: % -> %', r.full_name, v_new;
  end loop;
end $$;
