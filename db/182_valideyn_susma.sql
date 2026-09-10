-- =====================================================================
--  182_valideyn_susma.sql - valideyn girisi SUSMAYA GORE ACIQ
--
--  NIYE QERAR DEYISDI
--  db/107-de bele yazmisdiq: «Muellim ozu acir - susmaya gore bagli.
--  Bezi muellimler isinin seffaflasmasindan narahat olacaq; mecburi
--  etsek muellimi itiririk.»
--
--  O ehtiyat hedden artiq idi.  Uc sebeb:
--
--  1. REPETITORUN MUSTERISI VALIDEYNDIR.  Pulu valideyn verir.
--     Valideynden gedisati gizleden repetitor onsuz da bizim hedef
--     istifadecimiz deyil.  Muellim hemin melumati her axsam elle
--     yazir - biz onun ISINI yungullesdiririk, ustune nezaret
--     qoymuruq.
--
--  2. SUSMA DEYERI HER SEYI HELL EDIR.  Bagli gelen funksiyani
--     praktikada hec kim acmir.  Yeni kohne qerar «valideyn girisi
--     var» yox, «valideyn girisi kagiz uzerindedir» demek idi.
--
--  3. Reqib valideyn girisini 60 manatliq paketden verir; bizde
--     pulsuz heddedir.  Bagli qalsa, bu ustunluk gorunmur.
--
--  NIYE QRUP SEVIYYESINDE, sagird seviyyesinde yox
--  Muellimlerin bir hissesi BOYUKLERE ders deyir (IELTS, ali mekteb
--  hazirligi).  25 yasli adama valideyn kodu yaratmaq menasizdir.
--  Qrup dogru bolgudur: «5-ci sinif» -> aciq, «Boyukler» -> muellim
--  bir defe baglayir, hemin qrupun butun sagirdlerine sirayet edir.
--  Sagird seviyyesinde istisna yene mumkundur (rpc_parent_access).
--
--  «ARXAMCA IS GORULDU» HISSI OLMASIN
--  Kod avtomatik yaransa da, onu valideyne CATDIRAN muellimdir - kod
--  yaranmaqla hec kim hec ne gormur.  Yene de sagird setrinde
--  «Valideyn girisi aciqdir» aydin gorunur ki, muellim ilk baxisda
--  bilsin ve istese bir kliklə baglasin.
--
--  KOHNE QRUPLAR: susma yalniz YENI qruplara aiddir.  Movcud
--  qruplarda muellim onsuz da oz qerarini verib - onu geri
--  cevirmirik.  Ona gore sutun default true ile elave olunur, amma
--  movcud setirler update EDILMIR.
-- =====================================================================

--  Sutun: yeni qruplarda aciq, kohnelerde... asagida bax
do $$ begin
  alter table public.classes
    add column parent_access boolean not null default true;
exception when duplicate_column then null; end $$;

comment on column public.classes.parent_access is
  'true: qrupa elave olunan sagirde valideyn kodu OZU yaranir (db/182)';

--  KOHNE QRUPLAR.  Sutun default true ile geldiyi ucun movcud
--  setirler de true oldu.  Bu, muellimin kohne qerarini pozardi:
--  valideyn girisini QESDEN acmayan muellim var idi.  Ona gore
--  miqrasiya ani: sagirdlerinin HEC BIRINDE valideyn kodu olmayan
--  kohne qruplarda bayraq soundurulur.  Bir sagirdinde de olsa
--  kod varsa - muellim bu yolu onsuz da secib, aciq qalir.
--
--  YENI hesablar bundan tesirlenmir: onlarin qrupu hele yoxdur.
update public.classes c set parent_access = false
 where c.created_at < now()
   and not exists (select 1 from public.students s
                    where s.class_id = c.id and s.parent_code is not null);

-- ---------------------------------------------------------------------
--  Valideyn kodu yaradan komekci - eyni mentiq iki yerde lazimdir
--  (sagird elave olunanda ve rpc_parent_access-de).
-- ---------------------------------------------------------------------
create or replace function app.parent_code_new()
returns text
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_code text; i int;
begin
  for i in 1..20 loop
    v_code := 'V' || app.gen_login_code(7);
    exit when not exists (select 1 from public.students where parent_code = v_code);
    v_code := null;
  end loop;
  return v_code;
end $$;
revoke all on function app.parent_code_new() from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  rpc_add_student - db/124-den goturulub, YALNIZ valideyn kodu
--  hissesi elave olunub.  Qalan govde herfen eynidir.
-- ---------------------------------------------------------------------
create or replace function public.rpc_add_student(
  p_class_id uuid, p_full_name text, p_display_name text default null,
  p_birth_year int default null)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid     uuid := auth.uid();
  v_class   public.classes%rowtype;
  v_code    text;
  v_pcode   text;
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

  --  182: qrup aciqdirsa valideyn kodu da elə indi yaranir.  Kod
  --  yaranmaqla hec kim hec ne gormur - onu valideyne muellim verir.
  if coalesce(v_class.parent_access, true) then
    v_pcode := app.parent_code_new();
  end if;

  insert into public.students
    (account_id, class_id, created_by, full_name, display_name, birth_year,
     login_code, parent_code)
  values
    (v_class.account_id, p_class_id, v_uid, btrim(p_full_name), v_disp, p_birth_year,
     v_code, v_pcode)
  returning id into v_student;

  return jsonb_build_object('id', v_student, 'full_name', btrim(p_full_name),
                            'display_name', v_disp, 'login_code', v_code,
                            'parent_code', v_pcode);
end $$;

-- ---------------------------------------------------------------------
--  Qrup ayari: valideyn girisi aciq / bagli
--  Baglayanda MOVCUD sagirdlerin kodu ve acilmis sessiyalari da olur -
--  «bagladim, amma hele de baxir» olmasin (db/107-nin qaydasi).
--  Acanda kodu olmayan sagirdlere kod yaranir.
-- ---------------------------------------------------------------------
create or replace function public.rpc_class_parent_access(
  p_class_id uuid, p_on boolean default true)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
  v_n     int := 0;
  r       record;
begin
  if v_uid is null then
    raise exception 'Daxil olmamisiniz.' using errcode = '28000';
  end if;
  select * into v_class from public.classes where id = p_class_id;
  if not found then
    raise exception 'Qrup tapilmadi.' using errcode = '22023';
  end if;
  if v_class.teacher_id <> v_uid and not app.is_account_member(v_class.account_id) then
    raise exception 'Bu qrup sizin deyil.' using errcode = '42501';
  end if;

  update public.classes set parent_access = coalesce(p_on, true) where id = p_class_id;

  if coalesce(p_on, true) then
    for r in select id from public.students
              where class_id = p_class_id and parent_code is null and is_active
    loop
      update public.students set parent_code = app.parent_code_new() where id = r.id;
      v_n := v_n + 1;
    end loop;
  else
    for r in select id from public.students
              where class_id = p_class_id and parent_code is not null
    loop
      update public.students set parent_code = null where id = r.id;
      delete from public.parent_sessions where student_id = r.id;
      v_n := v_n + 1;
    end loop;
  end if;

  return jsonb_build_object('class_id', p_class_id,
                            'parent_access', coalesce(p_on, true),
                            'deyisen', v_n);
end $$;

revoke all on function public.rpc_class_parent_access(uuid, boolean) from public, anon;
grant  execute on function public.rpc_class_parent_access(uuid, boolean) to authenticated;
