-- =====================================================================
--  201 : «DİQQƏT TƏLƏB EDİR» - MOVZU UZRE YIGIM (2026-09-17)
--
--  Replit eskizinden ikinci fikir.  Icmalda Tehluke zonasi sagird-sagird
--  idi (12 oxsar setir).  Muellimin qerari movzu-movzudur: «bu movzunu
--  tekrar kecim».  Indi qrup + movzu uzre yigilir: «Faizlər · 7-ci sinif
--  — 6 şagirddən 3-ü zəif · orta 42%», adlar altda, bir duyme ile hemin
--  qrupa hemin movzudan test yigilir (remedialGen).
--
--  rpc_home-a 'topics' acari (marker: 'paid', v_paid,).  Qayda 18-deki
--  ile eynidir: sagird movzuda >= alert_weak_min() cavab verib VE dogru
--  nisbeti < alert_weak_pct().  Setir: zeif sayi >= 2, ya da qrupun
--  yarisi (kicik qrup).  Sira: zeif sayi cox -> orta asagi.  En cox 6.
--  Pulsuz hesabda null (siqnallar kimi).
-- =====================================================================
do $$
declare
  v_src text := pg_get_functiondef('public.rpc_home(uuid)'::regprocedure);
  v_mark text := '''paid'', v_paid,';
  v_add  text := '''paid'', v_paid,
    ''topics'', case when not v_paid then null else coalesce((
      with per as (
        select a.student_id, s.class_id, s.full_name, t.id topic_id, t.name topic,
               t.subject_id, t.level_id,
               count(*) n, count(*) filter (where aa.is_correct) ok
          from public.attempt_answers aa
          join public.attempts a  on a.id = aa.attempt_id and a.status = ''submitted''
          join public.students s  on s.id = a.student_id
                                 and s.account_id = v_acc and s.is_active
          join public.topics t    on t.id = aa.topic_id
         group by a.student_id, s.class_id, s.full_name, t.id, t.name, t.subject_id, t.level_id
        having count(*) >= app.alert_weak_min()
      ),
      agg as (
        select class_id, topic_id, topic, subject_id, level_id,
               count(*) n_st,
               count(*) filter (where ok * 100.0 / n < app.alert_weak_pct()) n_weak,
               round(avg(ok * 100.0 / n), 0) avg_ratio,
               (select jsonb_agg(jsonb_build_object(''id'', p2.student_id, ''name'', p2.full_name)
                                 order by p2.ok * 100.0 / p2.n)
                  from per p2
                 where p2.class_id = per.class_id and p2.topic_id = per.topic_id
                   and p2.ok * 100.0 / p2.n < app.alert_weak_pct()) weak
          from per
         group by class_id, topic_id, topic, subject_id, level_id
        having count(*) filter (where ok * 100.0 / n < app.alert_weak_pct()) >= 2
            or count(*) filter (where ok * 100.0 / n < app.alert_weak_pct()) * 2 >= count(*)
      )
      select jsonb_agg(jsonb_build_object(
               ''class_id'', c.id, ''class'', c.name,
               ''id'', g.topic_id, ''name'', g.topic,
               ''subject_slug'', sub.slug, ''level'', lv.code,
               ''n'', g.n_st, ''weak_n'', g.n_weak, ''avg'', g.avg_ratio, ''weak'', g.weak)
             order by g.n_weak desc, g.avg_ratio, c.name, g.topic)
        from (select * from agg order by n_weak desc, avg_ratio limit 6) g
        join public.classes c on c.id = g.class_id
        left join public.subjects sub on sub.id = g.subject_id
        left join public.levels lv on lv.id = g.level_id
    ), ''[]''::jsonb) end,';
begin
  if (length(v_src) - length(replace(v_src, v_mark, ''))) / length(v_mark) <> 1 then
    raise exception 'rpc_home: paid markeri 1 defe olmalidir';
  end if;
  if position('''topics''' in v_src) > 0 then
    raise notice '201 artiq tetbiq olunub, kecilir';
    return;
  end if;
  execute replace(v_src, v_mark, v_add);
end $$;

revoke all on function public.rpc_home(uuid) from public, anon;
grant execute on function public.rpc_home(uuid) to authenticated;
