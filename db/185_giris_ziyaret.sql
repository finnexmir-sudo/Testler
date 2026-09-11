-- =====================================================================
--  185_giris_ziyaret.sql — GIRIS EKRANI DA SAYILIR
--
--  Huni olculdu (2026-09-11, son 30 gun):
--    38 unikal ziyaretci -> 18-i «Panelə keç» -> 6 qeydiyyat ->
--    3 tesdiq -> 1 real istifade.
--  Yeni huninin en boyuk deliyi 18 -> 6-dir: 12 nefer formaya baxib
--  geri donub.  Numune ise onlarin artiq terk etdiyi sehifededir.
--
--  Giris ekranina «Nümunəyə bax» kecidi qoyulur.  Onun isleyib-
--  islemediyini BILMEK ucun klik sayilmalidir: rpc_visit indi
--  p_page = 'giris' qebul edir.  Belelikle ana sehifedeki klikle
--  qarismir - admin ikisini ayri gorur.
--
--  Govde 161-den proqramla goturulub; yalniz icazeli sehife siyahisi
--  deyisib ('home','komek' -> 'home','komek','giris').
-- =====================================================================

do $$
begin
  if to_regprocedure('public.rpc_visit(text, text)') is null then
    raise exception 'ONCE 161_ziyaret.sql isledilmelidir.';
  end if;
end $$;

create or replace function public.rpc_visit(p_page text, p_ev text default 'view')
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  h   jsonb;
  ip  text := '';
  ua  text := '';
  v_vid text;
begin
  if p_page is null or p_page not in ('home','komek','giris') then
    return jsonb_build_object('ok', false);
  end if;
  if p_ev is null or p_ev not in ('view','demo_muellim','demo_sagird','demo_valideyn','panel','beledci') then
    return jsonb_build_object('ok', false);
  end if;
  begin
    h := nullif(current_setting('request.headers', true), '')::jsonb;
  exception when others then h := null;
  end;
  if h is not null then
    ip := btrim(split_part(coalesce(h->>'x-forwarded-for', ''), ',', 1));
    ua := left(coalesce(h->>'user-agent', ''), 300);
  end if;
  if ip <> '' or ua <> '' then
    v_vid := md5(app.visit_salt() || '|' || ip || '|' || ua);
    --  spam: bir ziyaretci gunde 200 setirden cox yox
    if (select count(*) from public.visits v
         where v.vid = v_vid and v.at > now() - interval '1 day') >= 200 then
      return jsonb_build_object('ok', false, 'limit', true);
    end if;
  end if;
  insert into public.visits (page, ev, vid) values (p_page, p_ev, v_vid);
  return jsonb_build_object('ok', true);
end $$;

revoke all on function public.rpc_visit(text, text)   from public;
grant execute on function public.rpc_visit(text, text) to anon, authenticated;
