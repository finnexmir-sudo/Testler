-- =====================================================================
--  186_elaqe_kliki.sql — «WhatsApp» ve «E-poct» klikleri de sayilir
--
--  Tapilan bosluq (2026-09-11): ana sehifenin altliginda WhatsApp
--  linkinde data-ev="wa" var idi, amma rpc_visit-in icazeli hadise
--  siyahisinda 'wa' YOX idi - server sakitce {ok:false} qaytarirdi.
--  Yeni yene bir siqnal itirdi: «adam bize yazmaga cehd etdi».
--  Altliga e-poct da elave olundu (data-ev="mail") - eyni tele
--  tekrarlanmasin deye ikisi birlikde acilir.
--
--  Govde 185-den proqramla goturulub; yalniz hadise siyahisi deyisib:
--    ... 'panel','beledci'  ->  ... 'panel','beledci','wa','mail'
--  Sehife siyahisi ('home','komek','giris') TOXUNULMAYIB.
--  Yeni funksiya yaranmir - anon ag siyahisindaki 20 reqemi deyismir.
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
  if p_ev is null or p_ev not in ('view','demo_muellim','demo_sagird',
                                 'demo_valideyn','panel','beledci',
                                 'wa','mail') then
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
