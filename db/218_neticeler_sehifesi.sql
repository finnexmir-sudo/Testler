--  218: NETICELER SEHIFESI - qruplar uzre xulase
--
--  Yeni gorunusde Icmaldaki «Neticeler» setri hec yere aparmirdi -
--  «#/gs», yeni Qruplar siyahisina.  Muellim «Neticeler» basirdi,
--  qrup adlarini gorurdu.  Indi oz sehifesi var: «#/nt».
--
--  Sehifenin ust hissesi rpc_home-dan gelir (umumi orta, zeif movzular,
--  son neticeler).  Catmayan yeganə sey QRUP UZRE ortadir - bu funksiya
--  onu verir.  rpc_home-a elave etmedim: o, ilk aciliş yolundadir,
--  agirlasdirmaq istemedim; bu funksiya yalniz «#/nt» acilanda isleyir.
--
--  Reqemler rpc_home.stats ile EYNI qayda ile hesablanir (tarix penceresi
--  qoyulmur) - yoxsa sehifenin usti ile siyahisi bir-birini yalanlayardi.
set search_path = public, app;

create or replace function public.rpc_groups_summary(p_account uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc uuid := app.pick_account(p_account);
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id',       c.id,
             'name',     c.name,
             'level',    lv.code,
             'students', (select count(*) from public.students s
                           where s.class_id = c.id and s.is_active),
             'attempts', coalesce(z.n, 0),
             'avg',      z.avg,
             'avg_w',    z.avg_w,
             'active',   coalesce(z.active, 0),
             'last_at',  z.last_at)
           order by c.name)
      from public.classes c
      left join public.levels lv on lv.id = c.level_id
      left join lateral (
        select count(*) n,
               round(avg(a.percent), 0) avg,
               round(avg(a.percent) filter (
                 where a.finished_at >= now() - interval '7 days'), 0) avg_w,
               count(distinct a.student_id) active,
               max(a.finished_at) last_at
          from public.attempts a
          join public.students s on s.id = a.student_id
         where s.class_id = c.id and s.is_active and a.status = 'submitted'
      ) z on true
     where c.account_id = v_acc), '[]'::jsonb);
end $$;

revoke all on function public.rpc_groups_summary(uuid) from public, anon;
grant execute on function public.rpc_groups_summary(uuid) to authenticated;

--  «N sagird bir heftedir sessizdir» setri Icmalda var idi, amma
--  basilanda Qruplar siyahisina aparirdi - istifadeci hakli soruşdu:
--  «hani 10 sagird?».  Setir ADLARI vəd edir, ona gore adlari verir.
--  Sayim rpc_home.bugun.susan ILE EYNI qayda ile gedir (aktiv, en azi
--  bir heftelik, son 7 gunde tesdiqlenmis cehdi yoxdur) - yoxsa setirde
--  bir reqem, siyahida basqa reqem olardi.
create or replace function public.rpc_silent_students(p_account uuid default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc uuid := app.pick_account(p_account);
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id',        s.id,
             'class_id',  s.class_id,
             'class',     c.name,
             'full_name', s.full_name,
             --  sagird HELE GIRMEYIBSE ayri cumle yazilir: kodu
             --  gondermek ile tapsiriq vermek eyni is deyil
             'seen_at',   (select max(ss.created_at) from public.student_sessions ss
                            where ss.student_id = s.id),
             'last_at',   (select max(a.finished_at) from public.attempts a
                            where a.student_id = s.id and a.status = 'submitted'))
           order by c.name, s.full_name)
      from public.students s
      left join public.classes c on c.id = s.class_id
     where s.account_id = v_acc and s.is_active
       and s.created_at < now() - interval '7 days'
       and not exists (select 1 from public.attempts a
                        where a.student_id = s.id and a.status = 'submitted'
                          and a.finished_at >= now() - interval '7 days')), '[]'::jsonb);
end $$;

revoke all on function public.rpc_silent_students(uuid) from public, anon;
grant execute on function public.rpc_silent_students(uuid) to authenticated;
