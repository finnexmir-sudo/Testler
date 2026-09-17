-- =====================================================================
--  200 : ICMAL KARTLARINDA HEFTELIK FERQ (2026-09-17)
--
--  Istifadeci (Replit eskizinden goturulen fikir): reqem kartlarinda
--  yalniz reqem var, hereket yoxdur - «18 şagird · +3 son 7 gün»,
--  «40 test · +12 son 7 gün», «78% · +6% əvvəlki həftəyə görə».
--  Muellim «ireliləyirəm?» sualinin cavabini bir baxisda gorur.
--
--  rpc_home.stats-a dord acar elave olunur:
--    tests_w     son 7 gunde yaradilan oz testleri (diaqnostiksiz)
--    students_w  son 7 gunde elave olunan aktiv sagirdler
--    attempts_w  son 7 gunde bitirilen cehdler
--    avg_w       son 7 gunun orta faizi (cehd yoxdursa null)
--    avg_pw      evvelki 7 gunun (8-14 gun evvel) orta faizi
--
--  Govde: pg_get_functiondef ile goturulur, 'stats' markeri
--  genislendirilir - 194-deki qalan hisse deyismir (195 usulu).
--  Marker funksiyada BIR defe var (smoke §1 yoxlayir).
-- =====================================================================
do $$
declare
  v_src text := pg_get_functiondef('public.rpc_home(uuid)'::regprocedure);
  v_mark text := '''stats'', jsonb_build_object(';
  v_add  text := '''stats'', jsonb_build_object(
      ''tests_w'',    (select count(*) from public.tests t
                        where t.owner_type = ''educator''
                          and not t.is_diagnostic
                          and t.created_at >= now() - interval ''7 days''
                          and t.owner_id in (select user_id from public.account_members
                                              where account_id = v_acc)),
      ''students_w'', (select count(*) from public.students s
                        where s.account_id = v_acc and s.is_active
                          and s.created_at >= now() - interval ''7 days''),
      ''attempts_w'', (select count(*) from public.attempts a
                        join public.students s on s.id = a.student_id
                       where s.account_id = v_acc and a.status = ''submitted''
                         and a.finished_at >= now() - interval ''7 days''),
      ''avg_w'',      (select round(avg(a.percent), 0)
                         from public.attempts a
                         join public.students s on s.id = a.student_id
                        where s.account_id = v_acc and a.status = ''submitted''
                          and a.finished_at >= now() - interval ''7 days''),
      ''avg_pw'',     (select round(avg(a.percent), 0)
                         from public.attempts a
                         join public.students s on s.id = a.student_id
                        where s.account_id = v_acc and a.status = ''submitted''
                          and a.finished_at >= now() - interval ''14 days''
                          and a.finished_at <  now() - interval ''7 days''),';
begin
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception 'rpc_home: stats markeri 1 defe olmalidir';
  end if;
  if position('tests_w' in v_src) > 0 then
    raise notice '200 artiq tetbiq olunub, kecilir';
    return;
  end if;
  execute replace(v_src, v_mark, v_add);
end $$;

revoke all on function public.rpc_home(uuid) from public, anon;
grant execute on function public.rpc_home(uuid) to authenticated;
