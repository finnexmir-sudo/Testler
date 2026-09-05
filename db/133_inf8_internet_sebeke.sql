-- =====================================================================
--  133_inf8_internet_sebeke.sql : INF-8-INTERNET SEBEKE BOSLUGU
--
--  "informatika ni yoxla" auditi: inf-8-internet movzusunun 4
--  alt-basligindan biri - "KOMPÜTER ŞƏBƏKƏLƏRİ" - hec bir sualla
--  ortulmemisdi. Movcud 20 sual yalniz "Cemiyyetin informasiyalasdirilmasi"
--  ve "Internet xidmetleri" hisselerini ehate edirdi (rəqəmsal iz,
--  kiberbullinq, parol, fişinq və s.) - şəbəkə anlayışına toxunulmurdu.
--
--  6 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: inf8-internet#21-26.
--
--  ON SERT: movzu agaci islenmis olmalidir (inf-8-internet movcud olmali).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-8-internet') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-8-internet tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf8-internet#%' and q.ext_key ~ '#(2[1-6])$';

with d(ext, diff, body, why, opts, correct) as (values
('inf8-internet#21',1,'Kompüterlər arasında sim (kabel) olmadan, havadan qurulan bağlantı necə adlanır?','Bu, simsiz (Wi-Fi) bağlantı adlanır.',array['Simsiz (Wi-Fi) bağlantı','Kabel bağlantısı','Server bağlantısı','Printer bağlantısı'],1),
('inf8-internet#22',2,'Kiçik bir ərazidə (məsələn, bir məktəbdə) qurulan şəbəkə necə adlanır?','Kiçik əraziyə xidmət edən şəbəkə lokal şəbəkə (LAN) adlanır.',array['Lokal şəbəkə (LAN)','Qlobal şəbəkə','Telefon şəbəkəsi','Kabel televiziyası'],1),
('inf8-internet#23',2,'Ev şəbəkəsində bir kompüterdəki sənədi başqa kompüterdən açmaq üçün əsas şərt nədir?','Hər iki kompüterin eyni şəbəkəyə qoşulu olması və fayl paylaşımının aktiv olması lazımdır.',array['Hər iki kompüterin eyni şəbəkəyə qoşulu olması','Yalnız internetin olması','Yalnız printerin olması','Heç bir şərt lazım deyil'],1),
('inf8-internet#24',2,'Kompüterləri məktəbin lokal şəbəkəsinə adətən hansı kabellə qoşurlar?','Adətən şəbəkə (Ethernet) kabeli ilə qoşulur.',array['Şəbəkə (Ethernet) kabeli','Elektrik kabeli','Antena kabeli','Enerji kabeli'],1),
('inf8-internet#25',1,'Kompüter internetə qoşulu olduqda hansı vəziyyətdə sayılır?','Bu vəziyyət onlayn adlanır.',array['Onlayn','Oflayn','Söndürülmüş','Bloklanmış'],1),
('inf8-internet#26',2,'Ev Wi-Fi şəbəkəsinin ekranda görünən adı necə adlanır?','Bu ad şəbəkə adı (SSID) adlanır.',array['Şəbəkə adı (SSID)','IP ünvanı','MAC ünvanı','Domen adı'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 4, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '8'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-8-internet'
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
   where ext_key like 'inf8-internet#%' and ext_key ~ '#(2[1-6])$';
  if n <> 6 then
    raise exception '133: 6 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf8-internet#%' and q.ext_key ~ '#(2[1-6])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '133: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '133 OK - 6 sual elave olundu (inf-8-internet, komputer sebekeleri bosluğu).';
end $$;
