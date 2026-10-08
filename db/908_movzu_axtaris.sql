-- =====================================================================
--  908 : MOVZU AXTARISI (rpc_topic_search) (2026-10-01)
--
--  NIYE: muellim «frazeoloji birlesme» yazir - movzunun ADINI.  907 sual
--  siyahisini movzu adina gore tapdirir, amma muellimin isi test yigmaqdir:
--  Test yig ekrani ise movzunu yalniz FENN + TEK SINIF secenden sonra,
--  duzme-duz nisan siyahisi kimi gosterir.  Bu RPC adla axtarir, fenn/sinifden
--  asili olmadan movzunu fenni, sinfi ve sual sayi ile qaytarir; ekran bir
--  duymeyle «Test yig»-a kecir.
--
--  NE QAYTARIR: yalniz SUALI OLAN movzular (hovuz secimine gore); her biri:
--     id, name, subject, subject_slug, level (kod), level_name, n (sual sayi).
--  Siralama: adi axtarisla BASLAYAN evvel, sonra sual sayi coxdan aza.
--  Hedd: p_limit (en cox 20).  2 simvoldan qisa axtaris bos siyahi verir.
--
--  HUQUQ: yalniz authenticated (hovuz/hesab app.pick_account ile - rpc_bank_list
--  kimi).  Yeni cedvel/sutun yoxdur.  Geri almaq: drop function.
-- =====================================================================

create or replace function public.rpc_topic_search(
  p_q       text,
  p_pool    text    default 'platform',
  p_limit   integer default 8,
  p_account uuid    default null)
returns jsonb
language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_acc  uuid := app.pick_account(p_account);
  v_q    text := btrim(coalesce(p_q, ''));
  v_pool text := coalesce(nullif(btrim(p_pool), ''), 'platform');
  v_lim  int  := least(greatest(coalesce(p_limit, 8), 1), 20);
begin
  if v_pool not in ('mine', 'platform', 'all') then
    raise exception 'Hovuz yanlisdir.' using errcode = '22023';
  end if;
  if length(v_q) < 2 then return '[]'::jsonb; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', z.id, 'name', z.name,
             'subject', z.subject, 'subject_slug', z.subject_slug,
             'level', z.level_code, 'level_name', z.level_name, 'n', z.n)
           order by z.starts desc, z.n desc, z.name)
      from (
        select * from (
          select t.id, t.name, s.name as subject, s.slug as subject_slug,
                 l.code as level_code, l.name as level_name, t.sort,
                 (lower(t.name) like lower(v_q) || '%') as starts,
                 (select count(*) from public.questions q
                   where q.topic_id = t.id
                     and case v_pool
                         when 'mine'     then q.account_id = v_acc
                         when 'platform' then q.owner_type = 'platform'
                                              and q.status = 'published'
                         else q.account_id = v_acc
                              or (q.owner_type = 'platform'
                                  and q.status = 'published')
                         end)::int as n
            from public.topics t
            join public.subjects s on s.id = t.subject_id
            left join public.levels l on l.id = t.level_id
           where t.name ilike '%' || v_q || '%'
        ) y
        where y.n > 0
        order by y.starts desc, y.n desc, y.name
        limit v_lim
      ) z), '[]'::jsonb);
end $$;

revoke all on function public.rpc_topic_search(text, text, integer, uuid) from public, anon;
grant execute on function public.rpc_topic_search(text, text, integer, uuid) to authenticated;
