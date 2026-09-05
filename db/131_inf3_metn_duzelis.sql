-- =====================================================================
--  131_inf3_metn_duzelis.sql : INF-3-METN NOQTEVI BOSLUQ
--
--  "Metn redaktoru" movzusunun 3 alt-basligina (WORDPAD PROQRAMI,
--  METNE SEKLIN ELAVE EDILMESI, METNDE SOZLERIN EVEZ OLUNMASI,
--  KOMPUTERDE HESABLAMALARIN APARILMASI) heç sual yox idi - qalani
--  yaxsi ortulmusdu. Istifadeci auditinde tapildi.
--
--  4 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf3-metn#21-24.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-3-metn movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-3-metn') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-3-metn tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf3-metn#%' and q.ext_key ~ '#(2[1-4])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf3-metn#21',1,'WordPad hansı növ proqramdır?','WordPad sadə imkanlara malik bir mətn redaktorudur.',array['Mətn redaktoru','Qrafik redaktor','Cədvəl proqramı','Oyun proqramı'],1),
('inf3-metn#22',2,'Mətnə şəkil əlavə etmək üçün hansı bölmədən istifadə olunur?','Şəkil «Daxil et» (Insert) bölməsindən əlavə olunur.',array['Daxil et (Insert)','Fayl','Bax','Kömək'],1),
('inf3-metn#23',2,'Mətndə bir sözü tapıb başqası ilə əvəz etmək üçün hansı əmrdən istifadə olunur?','Bu iş üçün «Tap və Əvəz et» (Find and Replace) əmri işlədilir.',array['Tap və Əvəz et (Find and Replace)','Çap et (Print)','Yadda saxla (Save)','Kəs (Cut)'],1),
('inf3-metn#24',2,'Mətn redaktorunda sənəd yazarkən tez bir hesablama lazım olsa, nə etmək məsləhətdir?','Mətn redaktorundan çıxmadan ayrıca Kalkulyator proqramını açmaq məsləhətdir.',array['Ayrıca Kalkulyator proqramını açmaq','Sənədi silmək','Printerə göndərmək','Kompüteri söndürmək'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 2, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '3'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-3-metn'
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct::int
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(d.opts) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where ext_key like 'inf3-metn#%' and ext_key ~ '#(2[1-4])$';
  if n <> 4 then
    raise exception '131: 4 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf3-metn#%' and q.ext_key ~ '#(2[1-4])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '131: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '131 OK - 4 sual elave olundu (inf-3-metn, WordPad + sekil + evez + hesablama).';
end $$;
