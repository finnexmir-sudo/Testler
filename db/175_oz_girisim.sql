-- =====================================================================
--  175_oz_girisim.sql — OZ ZIYARETIMIZ SAYILMIR
--
--  Istifadeci (2026-09-09): "admin panelindeki ziyaretci sayinda
--  adminin girisini saygac saymasin, men tez-tez girib cixiram deye
--  artima tesir etmesin."
--
--  IKI YER VAR, IKI AYRI HELL:
--
--  1. ANA SEHIFE SAYGACI (public.visits, db/161).  Ora ANONIM gelinir -
--     server orada kimin geldiyini BILE BILMIR (IP saxlanmir, JWT yox).
--     Ona gore hell BRAUZERDEDIR: panel admin girisini goren kimi
--     localStorage-a «bil10_oz» nisani qoyur, assets/visit.js hemin
--     nisani gorende rpc_visit-i hec cagirmir.  Eyni usul onbaxis
--     sayti (yeni.bil10.az) ucun artiq isleyirdi.  Adi muellim eyni
--     brauzere girse nisan silinir - baskasinin ziyareti itmesin.
--     ==> BU FAYLDA DEYIL, muellim/app.js + assets/visit.js icinde.
--
--  2. «BU GUN / HEFTE - giris eden» REQEMLERI (rpc_admin_stats).  Bura
--     JWT ile gelinir, yeni admin hesabini SERVER taniyir.  Admin
--     sahibli hesab artiq 'paid_accounts', 'trial_accounts' ve
--     'active_subs' saylarindan cixarilmisdi (db/173) - eyni qayda
--     indi 'seen_today' ve 'seen_week' ucun de tetbiq olunur.
--     ==> BU FAYL.
--
--  TOXUNULMAYAN: 'accounts', 'accounts_week', 'students', 'mrr_minor'.
--  Onlar HADISE deyil, MOVCUDLUQ sayir - admin hesabi bir defe yaranib,
--  her gun artmir, ona gore sise vurmur.  Sayin sabit «+1»-i cixarilsa,
--  kohne ekran sekilleri ile muqayise pozulur.
--
--  Davranis deyismir: ne abune, ne hedd, ne mebleg.  Yalniz ADMIN
--  ekranindaki iki reqem duzelir.
-- =====================================================================

do $$
begin
  if to_regclass('public.visits') is null then
    raise exception 'ONCE 161_ziyaret.sql isledilmelidir.';
  end if;
end $$;

--  Tam govde yazilir (173-un «bu gun» sahelerini de daxil edir) ki,
--  bu fayl TEK basina tetbiq olunanda da dogru netice versin.
create or replace function public.rpc_admin_stats()
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
begin
  if not app.admin_ok() then
    raise exception 'Bu emeliyyat yalniz admin ucundur.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    --  173: "Bu gün" zolagi ucun - Baki gunu ile.  Evvel yalniz heftelik
    --  reqemler var idi, admin ise sehifeni HER GUN acir.
    'accounts_today', (select count(*) from public.accounts a
                        where not a.is_demo
                          and (a.created_at at time zone 'Asia/Baku')::date
                              = (now() at time zone 'Asia/Baku')::date),
    'seen_today', (select count(*) from public.accounts a
                    where not a.is_demo
                      and not app.account_is_admin(a.id)
                      and exists (select 1 from auth.users u2
                                   where u2.id = a.owner_id
                                     and (u2.last_sign_in_at at time zone 'Asia/Baku')::date
                                         = (now() at time zone 'Asia/Baku')::date)),
    'attempts_today', (select count(*) from public.attempts att
                        join public.students st on st.id = att.student_id
                        join public.accounts a on a.id = st.account_id
                       where att.status = 'submitted' and not a.is_demo
                         and (att.finished_at at time zone 'Asia/Baku')::date
                             = (now() at time zone 'Asia/Baku')::date),
    --  numune nusxeleri hec bir sayda yoxdur
    'accounts', (select count(*) from public.accounts where not is_demo),
    'accounts_week', (select count(*) from public.accounts
                       where not is_demo
                         and created_at > now() - interval '7 days'),
    'demo_accounts', (select count(*) from public.accounts where is_demo),
    --  pullu = yalniz ODENISLI (active).  Admin sahibli hesab sayilmir.
    'paid_accounts', (select count(distinct s.account_id)
                       from public.subscriptions s
                       join public.accounts a on a.id = s.account_id
                      where s.status = 'active'
                        and not a.is_demo
                        and not app.account_is_admin(a.id)
                        and (s.current_period_end is null
                             or s.current_period_end > now())),
    'trial_accounts', (select count(distinct s.account_id)
                        from public.subscriptions s
                        join public.accounts a on a.id = s.account_id
                       where s.status = 'trialing'
                         and not a.is_demo
                         and not app.account_is_admin(a.id)
                         and (s.current_period_end is null
                              or s.current_period_end > now())),
    'active_subs', (select count(*) from public.subscriptions s
                     join public.accounts a on a.id = s.account_id
                     where s.status = 'active'
                       and not a.is_demo
                       and not app.account_is_admin(a.id)
                       and (s.current_period_end is null
                            or s.current_period_end > now())),
    --  169: gelir 's.seats' sutunundan yox, ANBAAN aktiv sagird sayindan
    'mrr_minor', app.mrr_minor(),
    'students', (select count(*) from public.students st
                  join public.accounts a on a.id = st.account_id
                 where st.is_active and not a.is_demo),
    'seen_week', (select count(*) from public.accounts a
                   where not a.is_demo
                     and not app.account_is_admin(a.id)
                     and (exists (select 1 from public.profiles p2
                                  where (p2.id = a.owner_id
                                     or p2.id in (select am.user_id from public.account_members am
                                                   where am.account_id = a.id))
                                    and p2.last_seen_at > now() - interval '7 days')
                      or exists (select 1 from auth.users u2
                                  where u2.id = a.owner_id
                                    and u2.last_sign_in_at > now() - interval '7 days'))),
    'attempts_week', (select count(*) from public.attempts att
                       join public.students st on st.id = att.student_id
                       join public.accounts a on a.id = st.account_id
                       where att.status = 'submitted'
                         and not a.is_demo
                         and att.finished_at > now() - interval '7 days'),
    'plans', coalesce((
      select jsonb_agg(jsonb_build_object('slug', p.slug, 'name', p.name)
                       order by (p.audience <> 'tutor'), p.sort)
        from public.plans p
       where p.is_active and p.slug <> 'pulsuz'), '[]'::jsonb));
end $$;
