-- =====================================================================
--  112_asagi_sinif_testleri.sql — asagi sinif testi de teyin edile bilir
--
--  NIYE
--  103_cox_sinif.sql generatorda bir nece sinif secmeyi acdi: repetitor
--  8-ci sinfi hazirlayarken 7-nin materialini da qata bilir.  Amma
--  isin YARISI idi - teyinat ekrani testleri hele de DEQIQ beraberlikle
--  suzurdu:
--
--      and (... or t.level_id = v_class.level_id)
--
--  Neticede muellim generatorda 5-ci sinif secib test yigirdi, sonra
--  tapsiriq ekraninda onu TAPMIRDI; ekran "sinfi qrupun sinfinden
--  ferqlidir" deyib kesirdi.  Test itmirdi, amma islenmirdi.
--
--  NE EDIRIK
--  Testin sinfi qrupun sinfinden ASAGI ve ya BERABER olmalidir
--  (levels.sort uzre).  Sinifsiz testler evvelki kimi hemise gorunur.
--
--  NIYE YUXARI SINIF ACILMIR
--  8-ci sinif qrupuna 9-cu sinif testi vermek sehv ehtimali daha
--  yuksekdir (generatorda yanlis sinif secmek).  Real ehtiyac olsa,
--  qrupun sinfini deyismek bir kliklikdir.  Lazim gelse bu sert bir
--  setirle acilir.
--
--  Fayl 28_ferdi_tapsiriq.sql-den PROQRAMLA cixarilib.
-- =====================================================================

create or replace function public.rpc_available_tests(p_class_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_uid   uuid := auth.uid();
  v_class public.classes%rowtype;
begin
  select * into v_class from public.classes where id = p_class_id;
  if not found or (v_class.teacher_id <> v_uid
                   and not app.is_account_member(v_class.account_id)) then
    raise exception 'Bu qrupa giris huququnuz yoxdur.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(x order by x->>'subject', x->>'title')
    from (
      select jsonb_build_object(
               'id',        t.id,
               'title',     t.title,
               'subject',   sub.name,
               'level',     lv.name,
               'is_free',   t.is_free,
               'mine',      t.owner_type = 'educator',
               'questions', (select count(*) from public.test_questions tq where tq.test_id = t.id),
               'assigned',  (select a.id from public.assignments a
                              where a.class_id = p_class_id and a.test_id = t.id
                                and a.student_id is null),
               'assigned_n',(select count(*) from public.assignments a
                              where a.class_id = p_class_id and a.test_id = t.id
                                and a.student_id is not null)
             ) as x
        from public.tests t
        join public.subjects sub on sub.id = t.subject_id
        left join public.levels lv on lv.id = t.level_id
       where t.status = 'published'
         and (t.owner_type = 'platform' or t.owner_id = v_uid)
         --  ASAGI SINIFLER DE OLAR.  Evvel DEQIQ beraberlik teleb
         --  olunurdu: generatorda 5-ci sinif secib test yigan muellim
         --  onu 8-ci sinif qrupuna VERE BILMIRDI - ekran "sinfi qrupun
         --  sinfinden ferqlidir" deyib kesirdi.  Halbuki tekrar ucun
         --  asagi sinif materiali vermek muellimin adi isidir.
         --  Yuxari sinif bagli qalir: 8-ci sinif qrupuna 9-cu sinif
         --  testi vermek sehv ehtimali daha yuksekdir, ustelik qrupun
         --  sinfini deyismek bir kliklikdir.
         and (v_class.level_id is null or t.level_id is null
              or (select lv2.sort from public.levels lv2 where lv2.id = t.level_id)
                 <= (select lv3.sort from public.levels lv3
                      where lv3.id = v_class.level_id))
    ) z
  ), '[]'::jsonb);
end $$;

revoke all on function public.rpc_available_tests(uuid) from public, anon;
grant execute on function public.rpc_available_tests(uuid) to authenticated;

do $x$
declare v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'rpc_available_tests';
  if v_def like '%t.level_id = v_class.level_id%' then
    raise exception 'teyinat siyahisi hele de DEQIQ beraberlik teleb edir';
  end if;
  raise notice 'Teyinat siyahisi: asagi sinif testleri de gorunur.';
end $x$;
