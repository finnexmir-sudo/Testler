-- =====================================================================
--  128_utarix8_qafqaz_medeniyyet.sql : UTARIX-8-SERQ QAFQAZ/MEDENIYYET
--
--  "Serq olkeleri XVII-XVIII yuzilliklerde" movzusunun 7 alt-basligindan
--  3-u (Qafqaz, Volqaboyu-Ural-Sibir-Merkezi Asiya turk xalqlari,
--  Medeniyyet) 31 sualin hecbirinde toxunulmayib - hamisi Osmanli/
--  Sefevi/Baburiler/Cin/Yaponiya idi. Istifadeci auditinde tapildi.
--
--  4 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: utarix8-serq#32-35.
--
--  ON SERT: 66_movzular_umumi_tarix6_8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'umumi-tarix' and t.slug = 'utarix-8-serq') then
    raise exception 'ONCE 66_movzular_umumi_tarix6_8.sql islenmis olmalidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'utarix8-serq#%' and q.ext_key ~ '#(3[2-5])$';

with d(ext, diff, body, why, opts, correct) as (values
('utarix8-serq#32',2,'XVII-XVIII əsrlərdə Qafqaz bölgəsi əsasən hansı iki dövlətin təsir dairəsi uğrunda mübarizə meydanına çevrilmişdi?','Qafqaz bu dövrdə Osmanlı və Səfəvi dövlətləri arasında təsir dairəsi mübarizəsinin mərkəzlərindən biri idi.',array['Osmanlı və Səfəvi dövlətləri','Rusiya və Çin','Fransa və Britaniya','Hindistan və İran'],1),
('utarix8-serq#33',2,'XVII-XVIII əsrlərdə Volqaboyu türk xalqları (məsələn tatarlar) hansı dövlətin tərkibinə qatılmışdı?','Volqaboyu türk xalqları bu dövrdə Rusiya dövlətinin tərkibinə qatılmışdı.',array['Rusiya dövlətinin','Osmanlı imperiyasının','Çin imperiyasının','Səfəvi dövlətinin'],1),
('utarix8-serq#34',3,'XVII-XVIII əsrlərdə Mərkəzi Asiya və Sibir türk xalqlarının siyasi vəziyyətini səciyyələndirən əsas proses nə idi?','Bu bölgələr get-gedə Rusiyanın müstəmləkəçilik siyasətinin təsirinə düşürdü.',array['Rusiyanın müstəmləkəçilik siyasətinin təsirinə düşmə','Tam müstəqilliyin qorunması','Osmanlıya birləşmə','Sənayeləşmənin sürətlənməsi'],1),
('utarix8-serq#35',2,'XVI-XVIII əsrlərdə Şərq ölkələrinin mədəniyyətində hansı sahə xüsusilə inkişaf etmişdi?','Memarlıq (məscid, saray kompleksləri) və miniatür sənəti bu dövrün Şərq mədəniyyətinin görkəmli nailiyyətləri idi.',array['Memarlıq və miniatür sənəti','Kosmik texnologiyalar','Yalnız dəniz nəqliyyatı','Kağız pul dövriyyəsi'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 1, 'published'
    from d
    join public.subjects s on s.slug = 'umumi-tarix'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '8'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'utarix-8-serq'
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
   where ext_key like 'utarix8-serq#%' and ext_key ~ '#(3[2-5])$';
  if n <> 4 then
    raise exception '128: 4 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'utarix8-serq#%' and q.ext_key ~ '#(3[2-5])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '128: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '128 OK - 4 sual elave olundu (utarix-8-serq, Qafqaz + Volqaboyu + Medeniyyet).';
end $$;
