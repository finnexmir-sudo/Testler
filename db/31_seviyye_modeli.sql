-- =====================================================================
--  31_seviyye_modeli.sql — sinif (level) modelinin duzelisi
--
--  TAPILAN SEHV
--  Panel qrup yaradanda HEMISE p_program_slug = 'ibtidai' gonderirdi,
--  rpc_create_class ise sinfi PROQRAMIN ICINDE axtarirdi:
--
--      select id into v_level from public.levels
--       where program_id = v_prog and code = p_level_code;
--
--  8-ci sinif 'ibtidai'-de deyil, 'orta'-dadir.  Netice: muellim
--  siyahidan 8-ci sinfi secirdi, sorgu BOS qayidirdi ve qrup
--  SINIFSIZ yaranirdi - sessizce, xeberdarliqsiz.
--  Yalniz 1-4-cu sinifler islyirdi (onlar hegiqeten 'ibtidai'-dedir).
--
--  Bunun zenciri uzundur: sinifsiz qrupda rpc_available_tests sinif
--  suzgecini SONDURUR, ona gore tapsiriq ekranina butun fennlerin,
--  butun siniflerin testleri tokulurdu.
--
--  DUZELIS
--  1. Sinif artiq KODLA tapilir, proqram ondan TOREYIR - eksine yox.
--     Cagiran teref proqramı bilmek mecburiyyetinde deyil; sinif
--     onsuz da hansı proqrama aid oldugunu ozu bilir.
--  2. p_program_slug qalir (kohne cagirislar pozulmasin) - amma
--     yalniz sinif VERILMEYENDE isledilir.  Sinif verilibse onun
--     proqrami usttundur.
--  3. Reqem kodlu sinifler uzre TEKRARSIZLIQ indeksle qorunur.
--     Kecmisde 9/10/11 iki proqramda birden var idi; temizlenib,
--     amma bir daha yaranmasin deye baza seviyyesinde baglayiriq.
--     MIQ/sertifikasiya seviyyeleri sinif deyil (kodlari 'riyaziyyat'
--     kimidir) - onlara toxunmuruq, indeks yalniz reqemlere baxir.
--
--  TEHLUKESIZLIK deyismir: funksiyanin huquq yoxlamalari (uzvluk,
--  ad, tip) oldugu kimi qalir.
-- =====================================================================

-- ------------------------------------------------- tekrarsizliq qarantı
--  Qismi unikal indeks: yalniz reqem kodlu (sinif) seviyyeler.
--  Bu indeks qurula bilmirse, demeli bazada HELE tekrar var -
--  onda evvelce onu temizlemek lazimdir (asagidaki sorgu gosterir).
do $$
declare v_dup text;
begin
  select string_agg(code || ' (' || n || ' defe)', ', ')
    into v_dup
    from (select l.code, count(*) n from public.levels l
           where l.code ~ '^[0-9]+$'
           group by l.code having count(*) > 1) z;
  if v_dup is not null then
    raise exception
      'Sinif kodlari tekrarlanir: %.  Evvelce tekrarlari temizleyin, '
      'sonra bu fayli iseledin.', v_dup;
  end if;
end $$;

create unique index if not exists levels_sinif_kodu_tek
  on public.levels (code) where code ~ '^[0-9]+$';

-- --------------------------------------------------- qrup yaradilmasi
--  06_educator_rpc.sql-dekinin uzerine yazilir.  Yalniz sinif/proqram
--  tapma hissesi deyisir - qalan hər şey hərfen eynidir.
create or replace function public.rpc_create_class(
  p_account_id uuid, p_name text, p_kind text default 'tutor_group',
  p_program_slug text default null, p_level_code text default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class uuid;
  v_code  text;
  v_prog  uuid;
  v_level uuid;
  i int;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  if not app.is_account_member(p_account_id) then
    raise exception 'Bu hesaba giris huququnuz yoxdur.' using errcode = '42501';
  end if;
  if coalesce(btrim(p_name), '') = '' then
    raise exception 'Qrup adi bos ola bilmez.' using errcode = '22023';
  end if;
  if p_kind not in ('school_class','tutor_group','self_study') then
    raise exception 'Qrup tipi yanlisdir.' using errcode = '22023';
  end if;

  --  SINIF BIRINCIDIR.  Reqem kodlu seviyyeler uzre kod TEKDIR
  --  (yuxaridaki indeks bunu qorayir), ona gore proqram gostermeye
  --  ehtiyac yoxdur - proqram sinifden torenir.
  if nullif(btrim(coalesce(p_level_code, '')), '') is not null then
    select l.id, l.program_id into v_level, v_prog
      from public.levels l
     where l.code = btrim(p_level_code)
       and l.code ~ '^[0-9]+$';
    if v_level is null then
      raise exception 'Bele sinif yoxdur: %', p_level_code using errcode = '22023';
    end if;
  elsif p_program_slug is not null then
    --  Sinif verilmeyibse yalniz proqram yazilir (kohne davranis)
    select id into v_prog from public.programs where slug = p_program_slug;
  end if;

  for i in 1..20 loop
    v_code := app.gen_login_code(8);
    exit when not exists (select 1 from public.classes where join_code = v_code);
    v_code := null;
  end loop;
  if v_code is null then
    raise exception 'Qosulma kodu yaradila bilmedi, yeniden cehd edin.';
  end if;

  insert into public.classes (account_id, teacher_id, kind, name, join_code, program_id, level_id)
  values (p_account_id, v_uid, p_kind::group_kind, btrim(p_name), v_code, v_prog, v_level)
  returning id into v_class;

  return jsonb_build_object('id', v_class, 'name', btrim(p_name), 'join_code', v_code);
end $$;

-- --------------------------------------------- movcud qruplarin duzelisi
--  Sinfi ELLE teyin edilmis qruplarda program_id kohne qalib
--  ('ibtidai'), cunki panel onu birbasa update ile yazirdi.
--  Uygunlasdiririq - sinif hansı proqramdadirsa qrup da orada olsun.
update public.classes c
   set program_id = l.program_id
  from public.levels l
 where l.id = c.level_id
   and c.program_id is distinct from l.program_id;

-- --------------------------------------------------------------- huquq
revoke all on function
  public.rpc_create_class(uuid, text, text, text, text) from public, anon;
grant execute on function
  public.rpc_create_class(uuid, text, text, text, text) to authenticated;

do $$
declare v_n int;
begin
  if has_function_privilege('anon',
      'public.rpc_create_class(uuid, text, text, text, text)', 'EXECUTE') then
    raise exception 'anon qrup yarada bilir';
  end if;
  select count(*) into v_n from public.classes c
    join public.levels l on l.id = c.level_id
   where c.program_id is distinct from l.program_id;
  if v_n > 0 then
    raise exception 'hele % qrupda proqram sinifle uzlasmir', v_n;
  end if;
  raise notice 'Sinif modeli duzeldildi: proqram sinifden torenir.';
end $$;
