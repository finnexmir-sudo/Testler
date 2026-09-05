-- =====================================================================
--  137_inf10_informasiya_miqdari.sql : INF-10-INFORMASIYA MIQDAR BOSLUGU
--
--  "informatika ni yoxla" auditi: inf-10-informasiya movzusunun 9
--  alt-basligindan biri - "İNFORMASİYANIN MİQDARI" (bit/bayt olcu
--  vahidleri) - hec bir sualla ortulmemisdi. Movcud 20 sual
--  tehlukesizlik/virus/sifrelemeye (qorunma, antivirus, kriptoqrafiya)
--  yigilmisdi.
--
--  5 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf10-informasiya#21-25.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-10-informasiya movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-10-informasiya') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-10-informasiya tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf10-informasiya#%' and q.ext_key ~ '#(2[1-5])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf10-informasiya#21',2,'İnformasiyanın ölçü vahidi olan 1 bit nəyi bildirir?','1 bit iki mümkün vəziyyətdən (0 və ya 1) birinin seçimidir.',array['İki vəziyyətdən (0/1) birini','Yalnız bir hərfi','Bir şəkli','Bir səsi'],1),
('inf10-informasiya#22',2,'8 bit neçə bayta bərabərdir?','8 bit = 1 bayt.',array['1 bayt','2 bayt','8 bayt','16 bayt'],1),
('inf10-informasiya#23',2,'1 kilobayt (KB) təxminən neçə baytdır?','1 KB = 1024 bayt.',array['1024 bayt','100 bayt','10 bayt','1000000 bayt'],1),
('inf10-informasiya#24',2,'Bir mətn sənədinin informasiya həcmi ilk növbədə nədən asılıdır?','Mətnin həcmi ilk növbədə simvolların sayından asılıdır.',array['Simvolların sayından','Şriftin rəngindən','Faylın adından','Yaradılma tarixindən'],1),
('inf10-informasiya#25',3,'1 meqabayt (MB) neçə kilobayta bərabərdir?','1 MB = 1024 KB.',array['1024 KB','100 KB','1000000 KB','10 KB'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 1, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '10'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-10-informasiya'
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
   where ext_key like 'inf10-informasiya#%' and ext_key ~ '#(2[1-5])$';
  if n <> 5 then
    raise exception '137: 5 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf10-informasiya#%' and q.ext_key ~ '#(2[1-5])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '137: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '137 OK - 5 sual elave olundu (inf-10-informasiya, informasiyanin miqdari bit/bayt).';
end $$;
