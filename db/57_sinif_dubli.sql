-- =====================================================================
--  57_sinif_dubli.sql : 9-11-CI SINIFLERIN IKILESMESINI ARADAN QALDIRIR
--
--  SEHV:  04_seed.sql 9-11-i 'buraxilis' proqraminda yaradirdi,
--         41/45/49_movzular_orta*.sql ise eyni siniflari 'orta'da
--         yaradib butun movzu ve suallari ORAYA yigdi.  Neticede her
--         sinif iki defe gorunur - biri dolu, biri bos:
--
--           orta      9   69 movzu / 2126 sual
--           buraxilis 9    0 movzu /    0 sual
--
--  Bu, panelde qrup yaratma formasinda siniflari ikileşdirir, ders
--  plani ise sinfi "where code = ... limit 1" ile tapdigi ucun bos
--  setri sece bilir - plan yaranmir.
--
--  QERAR:  mezmun 'orta'da qalir, bos 'buraxilis' setirleri silinir.
--          Sebeb: bankin mezmunu e-derslik dersliyidir - adi mektebi
--          proqramidir, buraxilis imtahani hazirligi deyil.  9-cu sinif
--          sagirdinin hefteli testini "Buraxilis imtahani" adi altinda
--          gostermek yanlis olardi.  'buraxilis' slug-i sonra ESL
--          imtahan hazirligi mezmunu ucun bos qalir (miq/sertifikasiya
--          kimi) - slug ile menanin ayrilmasi uzunmuddetli teledir.
--
--  Bos setire baglanmis qrup / test / sual varsa SILINMIR - eyni kodlu
--  'orta' seviyyesine kocurulur.  Muellimin "9-cu sinif" qrupu 9-cu
--  sinif olaraq qalir, sadece artiq dolu seviyyeye baxir.
--
--  ON SERT: 49_movzular_orta11.sql islenmis olmalidir.
--  Tekrar isledile biler.  SONRA: 05_grants.sql.
-- =====================================================================

do $$
declare n int;
begin
  select count(*) into n from public.levels l
    join public.programs p on p.id = l.program_id
   where p.slug = 'orta' and l.code in ('9', '10', '11');
  if n <> 3 then
    raise exception 'ONCE 41/45/49_movzular_orta*.sql isledilmelidir '
                    '(orta proqraminda 9-11 seviyyesi tapilmadi: %)', n;
  end if;
end $$;

-- ---------------------------------------------------- kocurme + silme
do $$
declare
  v_kod   text;
  v_bos   uuid;
  v_dolu  uuid;
  v_orta  uuid;
  k       int;
  v_qrup  int := 0; v_test int := 0; v_sual int := 0; v_movzu int := 0;
begin
  select id into v_orta from public.programs where slug = 'orta';
  foreach v_kod in array array['9', '10', '11'] loop
    select l.id into v_bos from public.levels l
      join public.programs p on p.id = l.program_id
     where p.slug = 'buraxilis' and l.code = v_kod;
    continue when v_bos is null;          -- artiq silinib

    select l.id into v_dolu from public.levels l
      join public.programs p on p.id = l.program_id
     where p.slug = 'orta' and l.code = v_kod;

    --  Movzu kocurulende slug toqqusa biler (topics: unique(subject_id, slug)).
    --  Praktikada bos setirde movzu yoxdur; olsa - susmasin, sinsin.
    select count(*) into k from public.topics t1
     where t1.level_id = v_bos
       and exists (select 1 from public.topics t2
                    where t2.level_id = v_dolu
                      and t2.subject_id = t1.subject_id
                      and t2.slug = t1.slug);
    if k > 0 then
      raise exception '% sinifde % movzu slug-u her iki seviyyede var - '
                      'elle bax', v_kod, k;
    end if;

    --  classes/tests hem program_id, hem level_id saxlayir - ikisi de
    --  kocurulmelidir, yoxsa qrup "buraxilis" proqraminda gorunub
    --  "orta" seviyyesine baxar
    update public.classes set level_id = v_dolu, program_id = v_orta
     where level_id = v_bos;
    get diagnostics k = row_count; v_qrup := v_qrup + k;
    update public.tests   set level_id = v_dolu, program_id = v_orta
     where level_id = v_bos;
    get diagnostics k = row_count; v_test := v_test + k;
    update public.questions set level_id = v_dolu where level_id = v_bos;
    get diagnostics k = row_count; v_sual := v_sual + k;
    update public.topics    set level_id = v_dolu where level_id = v_bos;
    get diagnostics k = row_count; v_movzu := v_movzu + k;

    delete from public.levels where id = v_bos;
  end loop;

  if v_qrup + v_test + v_sual + v_movzu > 0 then
    raise notice 'Kocuruldu: % qrup, % test, % sual, % movzu.',
                 v_qrup, v_test, v_sual, v_movzu;
  end if;
end $$;

-- --------------------------------- seviyyesiz qalan qrup/test qalmasin
--  Seviyye secmeden 'buraxilis' proqraminda yaradilmis qrup/test ola
--  biler (level_id null).  Onlar da artiq sinifsiz proqramda qalir.
do $$
declare v_orta uuid; v_bur uuid; k int; n int := 0;
begin
  select id into v_orta from public.programs where slug = 'orta';
  select id into v_bur  from public.programs where slug = 'buraxilis';
  if v_bur is null then return; end if;
  if exists (select 1 from public.levels where program_id = v_bur) then
    return;                       -- proqramda hele seviyye var, toxunma
  end if;
  update public.classes set program_id = v_orta where program_id = v_bur;
  get diagnostics k = row_count; n := n + k;
  update public.tests   set program_id = v_orta where program_id = v_bur;
  get diagnostics k = row_count; n := n + k;
  if n > 0 then
    raise notice 'Sinifsiz qalmis % qrup/test orta proqramina kocuruldu.', n;
  end if;
end $$;

-- ------------------------------------------------------ proqram adlari
--  'orta' artiq 5-11-i saxlayir; 'buraxilis' ise sinif saxlamir -
--  adinda "(9-11)" qalsa yalan deyer
update public.programs set name = 'Orta və yuxarı siniflər (5-11)'
 where slug = 'orta';
update public.programs set name = 'Buraxılış imtahanı'
 where slug = 'buraxilis';

-- ------------------------------------------------------- oz yoxlamasi
do $$
declare k int; v_ad text;
begin
  select count(*) into k from (
    select l.code from public.levels l
     where l.code ~ '^[0-9]+$'
     group by l.code having count(*) > 1) z;
  if k > 0 then
    raise exception '% sinif kodu hele de iki defe var', k;
  end if;

  select count(*) into k from public.levels where code ~ '^[0-9]+$';
  if k <> 11 then
    raise exception 'reqemli sinif sayi 11 deyil: %', k;
  end if;

  select count(*) into k from public.levels l
    join public.programs p on p.id = l.program_id
   where p.slug = 'orta' and l.code in ('9', '10', '11')
     and exists (select 1 from public.topics t where t.level_id = l.id);
  if k <> 3 then
    raise exception 'orta 9-11 seviyyesi movzusuz qaldi: %', k;
  end if;

  select name into v_ad from public.programs where slug = 'orta';
  raise notice 'Sinif dublikatlari aradan qalxdi. 1-11 bir defe, '
               'orta proqrami: %', v_ad;
end $$;
