-- =====================================================================
--  221 : REYE VERILEN CAVAB DA ICMALDA GORUNUR (2026-09-22)
--
--  QUSUR (istifadeci tapdi): «niye iki yere bolmusen? men indi her defe
--  bura gel, mesaja orda cavab verim?»  Haqlidir.  Admin -> muellim
--  yazisi IKI ayri yolla gedirdi:
--
--    1. «Cavabı göndər»  -> feedback.admin_note doldurulur
--       Muellim YALNIZ «Bizə yaz» ekranina girse gorurdu.
--       Icmalda kart yox, zengde say yox.
--    2. «Mesaj göndər»   -> feedback (author_type='admin') setri
--       Icmalda kart var, zengde say var.
--
--  Yani admin eyni seyi IKI DEFE gondermeli idi, yoxsa muellim
--  xeber tutmurdu.  Bu, istifadecinin isi deyil - bizim qusurumuz.
--
--  INDI: rpc_my_messages HER IKISINI qaytarir.
--    'kind' = 'mesaj'  -> admin ozu yazib
--    'kind' = 'cavab'  -> muellimin OZ qeydine cavab ('ask' - qeydin metni)
--  Oxunma da birlesir: rpc_message_seen setrin tipine gore ya seen_at,
--  ya da reply_seen_at qoyur.  Interfeys ferq bilmir - bir siyahi.
--
--  TEHLUKESIZLIK: ikisi de auth.uid()-e baglidir.  'cavab' setirleri
--  YALNIZ istifadecinin OZ yazdigi qeydlerdir (user_id = auth.uid()),
--  'mesaj' setirleri ise onun hesabina gonderilenler.  Anon siyahisina
--  toxunulmur (25 RPC oldugu kimi qalir).
--
--  ON SERT: 122 (feedback), 199 (rpc_my_messages), 208 (reply_seen_at).
-- =====================================================================

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'feedback'
                    and column_name = 'reply_seen_at') then
    raise exception 'ONCE 208_cavab_sagirde.sql isledilmelidir.';
  end if;
end $$;

-- ------------------------------------------------- birlesmis siyahi
--  TAM govde yazilir (marker uslubu istifade edilmir).
create or replace function public.rpc_my_messages()
returns jsonb
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
begin
  if auth.uid() is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', z.id, 'kind', z.kind, 'body', z.body, 'ask', z.ask,
             'at', z.at, 'seen_at', z.seen_at, 'replied', z.replied)
           order by z.at desc)
      from (
        --  1) adminin OZ yazdigi mesajlar
        select f.id,
               'mesaj'::text        as kind,
               f.body               as body,
               null::text           as ask,
               f.created_at         as at,
               f.seen_at            as seen_at,
               exists (select 1 from public.feedback r where r.reply_to = f.id) as replied
          from public.feedback f
         where f.author_type = 'admin'
           and f.account_id in (select account_id from public.account_members
                                 where user_id = auth.uid())
        union all
        --  2) OZ qeydine verilen cavab - «Bizə yaz»da gizli qalmasin
        select f.id,
               'cavab'::text        as kind,
               f.admin_note         as body,
               left(f.body, 160)    as ask,
               coalesce(f.answered_at, f.created_at) as at,
               f.reply_seen_at      as seen_at,
               true                 as replied
          from public.feedback f
         where f.user_id = auth.uid()
           and f.author_type <> 'admin'
           and f.admin_note is not null
           and btrim(f.admin_note) <> ''
        order by at desc
        limit 20) z), '[]'::jsonb);
end $$;

-- ------------------------------------------------- oxundu isaresi
--  Setrin tipi ozu deyir hansi sutun yazilmalidir.  Iki ayri duyme
--  olmasin - interfeys bir «Oxudum» gorur.
create or replace function public.rpc_message_seen(p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_row public.feedback%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Giris lazimdir.' using errcode = '28000';
  end if;
  select * into v_row from public.feedback where id = p_id;
  if not found then
    return jsonb_build_object('ok', false);
  end if;

  if v_row.author_type = 'admin' then
    --  adminin mesaji: hesabin uzvu oxuya biler
    if v_row.account_id not in (select account_id from public.account_members
                                 where user_id = auth.uid()) then
      raise exception 'Bu mesaj sizin deyil.' using errcode = '42501';
    end if;
    update public.feedback
       set seen_at = coalesce(seen_at, now())
     where id = p_id;
  else
    --  oz qeydine cavab: yalniz yazan oxuya biler
    if v_row.user_id is distinct from auth.uid() then
      raise exception 'Bu mesaj sizin deyil.' using errcode = '42501';
    end if;
    update public.feedback
       set reply_seen_at = coalesce(reply_seen_at, now())
     where id = p_id;
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- ------------------------------------------------- huquq
revoke all on function public.rpc_my_messages()       from public, anon;
revoke all on function public.rpc_message_seen(uuid)  from public, anon;
grant execute on function public.rpc_my_messages()      to authenticated;
grant execute on function public.rpc_message_seen(uuid) to authenticated;
