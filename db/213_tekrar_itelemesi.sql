-- =====================================================================
--  213 : GUNDELIK TEKRARIN IKI DAYAGI (2026-09-18)
--
--  212-ni qurduq, amma onun HER IKI ucu bosdur:
--
--  1. MUELLIM ASILILIGI.  Suallar yalniz «kecildi» isarelenen
--     derslerden gelir.  Muellim plani isaretlemirse usaga hec ne
--     catmir - ve hec kim bunu bilmir.  Ona gore «Bu gun» kartina bir
--     setir: «N sagirdin gundelik tekrari hazirlanmir - son dersi
--     kecildi isarele».  Bu, ittiham deyil, BIR TOXUNUSLUQ isaredir.
--
--  2. OLCU.  Gundelik verdisin isleyib-islemediyini bir reqem deyir:
--     ilk paketi BITIREN usagin 48 saat icinde ikinciye qayitma faizi
--     (D2).  Ikinci siqnal: baslayanlarin nece faizi bitirir - bu 75%
--     -den asagidirsa problem qayitmadan EVVEL baslayir (suallar
--     cetindir, ekran uzundur).  Hunide gorunur, admin ucundur.
--
--  Her ikisi MOVCUD funksiyalara marker ile elave olunur - yeni RPC
--  yoxdur, ona gore anon siyahisi da deyismir.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. rpc_home -> bugun.tekrar : muellimin kartindaki isare
-- ---------------------------------------------------------------------
do $$
declare
  v_src  text := pg_get_functiondef('public.rpc_home(uuid)'::regprocedure);
  v_mark text := '''bugun'', (';
  v_add  text;
begin
  if position('tekrar_plansiz' in v_src) > 0 then
    raise notice '213/1 artiq tetbiq olunub, kecilir';
  else
    if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
      raise exception '213: rpc_home markeri 1 defe olmalidir';
    end if;
    v_add := '''tekrar_plansiz'', (
      --  213: plani olan, amma hec bir dersi «kecildi» isarelenmeyen
      --  qruplardaki aktiv sagird sayi - onlara gundelik tekrar
      --  hazirlana bilmir.
      select count(*) from public.students st
        join public.classes c on c.id = st.class_id and c.account_id = v_acc
       where st.is_active
         and exists (select 1 from public.class_plans cp where cp.class_id = c.id)
         and not exists (select 1 from public.class_plan_items i
                          join public.class_plans cp2 on cp2.id = i.plan_id
                         where cp2.class_id = c.id and i.done_at is not null)),
    ''tekrar_qrup'', (
      --  hansi qrup - kart birbasa ders plani sekmesine aparir
      select jsonb_build_object(''id'', c.id, ''name'', c.name)
        from public.classes c
       where c.account_id = v_acc
         and exists (select 1 from public.students st
                      where st.class_id = c.id and st.is_active)
         and exists (select 1 from public.class_plans cp where cp.class_id = c.id)
         and not exists (select 1 from public.class_plan_items i
                          join public.class_plans cp2 on cp2.id = i.plan_id
                         where cp2.class_id = c.id and i.done_at is not null)
       order by c.created_at limit 1),
    ''tekrar_hazir'', (
      --  paketi qurula bilen sagird sayi (en azi bir «kecildi» ders)
      select count(*) from public.students st
        join public.classes c on c.id = st.class_id and c.account_id = v_acc
       where st.is_active
         and exists (select 1 from public.class_plan_items i
                       join public.class_plans cp on cp.id = i.plan_id
                      where cp.class_id = c.id and i.done_at is not null)),
    ''bugun'', (';
    execute replace(v_src, v_mark, v_add);
  end if;
end $$;

-- ---------------------------------------------------------------------
--  2. rpc_admin_huni -> tekrar : D2 qayitma + bitirme faizi
-- ---------------------------------------------------------------------
do $$
declare
  v_src  text := pg_get_functiondef('public.rpc_admin_huni(int)'::regprocedure);
  v_mark text := '''days'',       p_days,';
  v_add  text;
begin
  if position('''tekrar''' in v_src) > 0 then
    raise notice '213/2 artiq tetbiq olunub, kecilir';
    return;
  end if;
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception '213: rpc_admin_huni markeri 1 defe olmalidir';
  end if;
  v_add := '''days'',       p_days,
      --  213: gundelik tekrarin iki reqemi.  Numune hesab sayilmir -
      --  onun paketleri her gece sifirlanir ve statistikani yalan
      --  danisdirar.
      ''tekrar'', (
        with pk as (
          select d.* from public.daily_packs d
            join public.students st on st.id = d.student_id
            join public.accounts ac on ac.id = st.account_id and not ac.is_demo
           where jsonb_array_length(d.items) > 0
        ),
        basla as (select * from pk where jsonb_array_length(answers) > 0),
        ilk as (
          select student_id, min(day) d0 from pk where done_at is not null
           group by student_id
        )
        select jsonb_build_object(
          --  nece usaq basladi / bitirdi (butun vaxt)
          ''basladi'',  (select count(distinct student_id) from basla),
          ''bitirdi'',  (select count(distinct student_id) from pk where done_at is not null),
          --  BITIRME: baslanan paketlerin nece faizi sona catir
          --  (<75% -> problem qayitmadan evvel baslayir)
          ''bitirme'', (select case when count(*) = 0 then null
                               else round(count(*) filter (where done_at is not null) * 100.0 / count(*), 0)
                               end from basla),
          --  D2: ilk paketi bitirenin 48 saat icinde ikinciye qayitmasi
          ''d2_baza'', (select count(*) from ilk where d0 <= current_date - 2),
          ''d2'', (select case when count(*) = 0 then null
                          else round(count(*) filter (where exists (
                                 select 1 from pk p2
                                  where p2.student_id = ilk.student_id
                                    and p2.day > ilk.d0 and p2.day <= ilk.d0 + 2
                                    and jsonb_array_length(p2.answers) > 0)) * 100.0 / count(*), 0)
                          end from ilk where d0 <= current_date - 2))),';
  execute replace(v_src, v_mark, v_add);
end $$;

revoke all on function public.rpc_admin_huni(int) from public, anon;
grant execute on function public.rpc_admin_huni(int) to authenticated;
