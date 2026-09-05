-- =====================================================================
--  127  AD SIRASI: "Hüseynov Mirhüseyn" yazilanda qisa ad "Mirhüseyn H."
--
--  Canli musahide: muellim soyadi evvel yazdi, qisa ad "Hüseynov M."
--  oldu, valideyn metni "Hüseynov — son 30 gün" dedi.  Qayda: ilk soz
--  soyad sekilcisi ile bitirse (-ov/-ova/-yev/-yeva/-li/-lı/-zadə/
--  -oğlu/-qızı...) ve ikinci soz bitmirse, ikinci soz addir.
--  app.unique_display_name (124) uzerinde; tekrar qaydasi deyismir.
--  Panelde eyni qayda firstName() ile (valideyn metni, WhatsApp).
-- =====================================================================

create or replace function app.name_parts(p_full text, out o_first text, out o_last text)
language plpgsql immutable as $$
declare
  w1 text := split_part(btrim(p_full), ' ', 1);
  w2 text := split_part(btrim(p_full), ' ', 2);
  sfx text := '(ov|ova|yev|yeva|ev|eva|li|lı|lu|lü|zadə|zade|ski|skaya|oğlu|qızı)$';
begin
  if w2 <> '' and w1 ~* sfx and not (w2 ~* sfx) then
    o_first := w2; o_last := w1;
  else
    o_first := w1; o_last := w2;
  end if;
end $$;

create or replace function app.unique_display_name(p_class_id uuid, p_full text)
returns text
language plpgsql stable as $$
declare
  v_first text;
  v_last  text;
  v_try   text;
  v_cands text[];
  i int;
begin
  select o_first, o_last into v_first, v_last from app.name_parts(p_full);
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
  for i in 2..99 loop
    v_try := v_cands[array_length(v_cands, 1)] || ' ' || i;
    exit when not exists (select 1 from public.students s
                           where s.class_id = p_class_id and s.is_active
                             and lower(s.display_name) = lower(v_try));
  end loop;
  return v_try;
end $$;
revoke all on function app.name_parts(text) from public, anon, authenticated;
revoke all on function app.unique_display_name(uuid, text) from public, anon, authenticated;

--  Movcud "Soyad Ad" yazilmis sagirdlerin AVTOMATIK qisa adi duzeldilir:
--  yalniz qisa adi kohne qaydayla (ilk soz + ikinci sozun bas herfi)
--  yaranmis olanlar - muellimin el ile verdiyi ad toxunulmur.
do $$
declare r record; v_new text;
begin
  for r in
    select s.id, s.class_id, s.full_name, s.display_name
      from public.students s
     where s.is_active
       and split_part(btrim(s.full_name), ' ', 2) <> ''
       and lower(s.display_name) = lower(split_part(btrim(s.full_name), ' ', 1) || ' ' ||
                                         upper(left(split_part(btrim(s.full_name), ' ', 2), 1)) || '.')
       and (select o_first from app.name_parts(s.full_name)) <> split_part(btrim(s.full_name), ' ', 1)
     order by s.created_at, s.id
  loop
    v_new := app.unique_display_name(r.class_id, r.full_name);
    update public.students set display_name = v_new where id = r.id;
    raise notice '127: % -> % (evvel %)', r.full_name, v_new, r.display_name;
  end loop;
end $$;
