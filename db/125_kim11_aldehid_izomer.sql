-- =====================================================================
--  125_kim11_aldehid_izomer.sql : KIM-11-ALDEHID-TURSU IZOMERLIK
--
--  "Aldehidler ve karbon tursulari" movzusunun alt-basligi
--  "Adlandirilmasi ve izomerliyi" HEM aldehidler, HEM turshular
--  ucun ayri-ayri iki defe tekrarlanir - amma 31 sualin hec birinde
--  izomer sozu kecmir. Istifadeci auditinde tapildi.
--
--  4 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: kim11-aldehid-tursu#32-35.
--
--  ON SERT: 49_movzular_orta11.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'kimya' and t.slug = 'kim-11-aldehid-tursu') then
    raise exception 'ONCE 49_movzular_orta11.sql islenmis olmalidir.';
  end if;
end $$;

with d(ext, diff, body, why, opts, correct) as (values
('kim11-aldehid-tursu#32',1,'Aldehidlərin izomerliyi əsasən nə ilə bağlıdır?','Karbon zəncirinin düz və ya budaqlanmış olması ilə bağlıdır.',array['Karbon zəncirinin budaqlanması ilə','Molekulun rəngi ilə','Qaynama nöqtəsi ilə','İyi ilə'],1),
('kim11-aldehid-tursu#33',2,'C4H8O tərkibli butanalın struktur izomeri hansıdır?','2-metilpropanal (izobutiraldehid) butanalın struktur izomeridir.',array['2-metilpropanal','Butanol','Butan turşusu','Propanal'],1),
('kim11-aldehid-tursu#34',2,'Aldehidlərin IUPAC adlandırılmasında hansı şəkilçi istifadə olunur?','Aldehid adlarında "-al" şəkilçisi istifadə olunur (məsələn, etanal).',array['-al şəkilçisi','-ol şəkilçisi','-turşu sözü','-amin şəkilçisi'],1),
('kim11-aldehid-tursu#35',3,'Karbon turşularının izomerliyi hansı amillə bağlıdır?','Karbon zəncirinin quruluşu (düz və ya budaqlanmış olması) ilə bağlıdır.',array['Karbon zəncirinin quruluşu ilə','Turşuluq dərəcəsi ilə','Ərimə nöqtəsi ilə','Suda həllolma ilə'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 2, 'published'
    from d
    join public.subjects s on s.slug = 'kimya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'kim-11-aldehid-tursu'
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
   where ext_key like 'kim11-aldehid-tursu#%' and ext_key ~ '#(3[2-5])$';
  if n <> 4 then
    raise exception '125: 4 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'kim11-aldehid-tursu#%' and q.ext_key ~ '#(3[2-5])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '125: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '125 OK - 4 sual elave olundu (kim-11-aldehid-tursu, izomerlik + adlandirma).';
end $$;
