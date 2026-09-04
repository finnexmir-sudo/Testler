-- =====================================================================
--  122_bio11_insan_muhit_duzelis.sql : BIO-11-INSAN-MUHIT DUZELISI
--
--  Movzu "Insan, onun inkisafi ve muhit" idi (embrional inkisaf +
--  psixika + aile saglamligi), amma bankdaki 30 sualin HAMISI eslinde
--  EKOLOGIYA idi (basqa movzunun mezmunu sehv slug-a yazilmisdi) -
--  istifadeci auditinde tapildi. Bu fayl hemin 30 sualin HAMISINI
--  duz mezmunla evez edir (eyni ext_key-ler, on conflict do update -
--  tekrar isledilse zerer vermir).
--
--  Sebeb bu ayrica faylin yaradilmasi: esl menbe db/52_bank_fenn11.sql
--  bil10-bank PRIVATE repo-dadir (840 sual, 28 movzu, hamisini yeniden
--  yazir) - istifadeciye bir usaqcaliq movzunu duzeltmek ucun 840
--  setirlik fayl vermek evezine, yalniz bu 30 setiri here goturdum.
--
--  ON SERT: 49_movzular_orta11.sql islenmis olmalidir (bio-11-insan-
--  muhit movzusu movcud olmalidir).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'biologiya' and t.slug = 'bio-11-insan-muhit') then
    raise exception 'ONCE 49_movzular_orta11.sql islenmis olmalidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'bio11-insan-muhit#%'
   and q.ext_key !~ 'comb';

with d(ext, diff, body, why, opts, correct) as (values
('bio11-insan-muhit#1','1','Bətndaxili inkişafın ilk mərhələsində mayalanmış yumurta hüceyrəsi necə adlanır?','Mayalanmadan əmələ gələn ilk hüceyrə zigotdur.',array['Zigot','Qastrula','Blastula','Morula'],1),
('bio11-insan-muhit#2','1','Xordalıların bütün nümayəndələrində rüşeym dövründə əmələ gələn oxvari dayaq skeleti necə adlanır?','Xordalıları digər heyvanlardan fərqləndirən əsas əlamət notoxorddur.',array['Notoxord (xorda)','Onurğa beyni','Sümük skeleti','Əzələ borusu'],1),
('bio11-insan-muhit#3','2','Qastrulyasiya prosesi nəticəsində neçə rüşeym vərəqi əmələ gəlir?','Üç rüşeym vərəqi yaranır: ektoderma, mezoderma, endoderma.',array['Üç','İki','Dörd','Bir'],1),
('bio11-insan-muhit#4','2','Sinir sistemi və dərinin xarici qatı hansı rüşeym vərəqindən inkişaf edir?','Sinir sistemi və epidermis ektodermadan formalaşır.',array['Ektodermadan','Mezodermadan','Endodermadan','Notoxorddan'],1),
('bio11-insan-muhit#5','2','Əzələ toxuması, skelet və ürək-damar sistemi hansı rüşeym vərəqindən inkişaf edir?','Bu orqanlar mezodermadan formalaşır.',array['Mezodermadan','Ektodermadan','Endodermadan','Xoriondan'],1),
('bio11-insan-muhit#6','3','Həzm və tənəffüs sisteminin daxili epitel qatı hansı rüşeym vərəqindən əmələ gəlir?','Daxili orqanların epitelisi endodermadan yaranır.',array['Endodermadan','Ektodermadan','Mezodermadan','Amniondan'],1),
('bio11-insan-muhit#7','1','Mayalanmış yumurta hüceyrəsi uşaqlıq borusundan hara doğru hərəkət edir?','Mayalanmış hüceyrə borular vasitəsilə uşaqlıq boşluğuna doğru irəliləyir.',array['Uşaqlıq boşluğuna','Yumurtalığa','Sidik kisəsinə','Böyrəyə'],1),
('bio11-insan-muhit#8','2','Embrionun uşaqlıq divarına yeridilməsi prosesi necə adlanır?','Bu proses implantasiya adlanır.',array['İmplantasiya','Ovulyasiya','Menstruasiya','Laktasiya'],1),
('bio11-insan-muhit#9','2','İnsanın bətndaxili inkişafının ilk neçə həftəsi embrion dövrü sayılır?','İlk səkkiz həftə embrion dövrü, sonrası fetal dövr adlanır.',array['İlk 8 həftə','İlk 20 həftə','İlk 4 həftə','Bütün hamiləlik dövrü'],1),
('bio11-insan-muhit#10','3','Embrion dövründən sonrakı bətndaxili inkişaf mərhələsi necə adlanır?','Səkkizinci həftədən doğuşa qədər fetal (döl) dövrü adlanır.',array['Fetal (döl) dövrü','Postnatal dövr','Zigot dövrü','Blastula dövrü'],1),
('bio11-insan-muhit#11','2','Ana ilə döl arasında qida, oksigen və tullantı mübadiləsini əsasən hansı orqan təmin edir?','Bu mübadilə plasenta vasitəsilə həyata keçir.',array['Plasenta','Yumurtalıq','Uşaqlıq boynu','Sidik kisəsi'],1),
('bio11-insan-muhit#12','3','Teratogen amillərin dölə ən təhlükəli təsir göstərdiyi dövr hansıdır?','Orqanların əsası qoyulduğu ilk üç ay (embrion dövrü) ən həssas dövrdür.',array['Hamiləliyin ilk üç ayı','Doğuşdan sonrakı ilk ay','Hamiləliyin son ayı','Doğuş anı'],1),
('bio11-insan-muhit#13','1','İnsan psixikasının inkişafında ən sürətli dəyişikliklər hansı yaş dövründə baş verir?','Uşaqlıq və yeniyetməlik dövründə psixi inkişaf ən sürətli gedir.',array['Uşaqlıq və yeniyetməlik dövründə','Yaşlılıq dövründə','Doğuşdan əvvəl yalnız','Heç vaxt dəyişmir'],1),
('bio11-insan-muhit#14','2','Yeniyetməlik dövrünün psixoloji baxımdan əsas xüsusiyyəti nədir?','Bu dövrdə şəxsiyyət və özünüdərk formalaşır.',array['Şəxsiyyətin və özünüdərkin formalaşması','Psixi inkişafın dayanması','Yaddaşın zəifləməsi','Emosional dəyişməzlik'],1),
('bio11-insan-muhit#15','2','Psixikanın inkişafında irsiyyətlə yanaşı hansı amil həlledici rol oynayır?','Tərbiyə və sosial mühit psixi inkişafda mühüm rol oynayır.',array['Mühit (tərbiyə və sosial ətraf)','Yalnız qidalanma','Yalnız iqlim','Heç bir xarici amil'],1),
('bio11-insan-muhit#16','1','Əsassız, davamlı narahatlıq hissi ilə səciyyələnən pozuntu necə adlanır?','Bu, təşviş (narahatlıq) pozuntusudur.',array['Təşviş (narahatlıq) pozuntusu','Depressiya','Amneziya','Fobiya'],1),
('bio11-insan-muhit#17','2','Fobiya nə deməkdir?','Fobiya konkret obyekt və ya vəziyyətdən yaranan qeyri-adekvat, güclü qorxudur.',array['Konkret obyekt/vəziyyətdən qeyri-adekvat güclü qorxu','Ümumi yorğunluq hissi','Yaddaş pozuntusu','Diqqətin artması'],1),
('bio11-insan-muhit#18','2','Panik atak zamanı hansı əlamətlər müşahidə olunur?','Ürəkdöyünmənin sürətlənməsi, nəfəs darlığı və güclü qorxu hissi tipikdir.',array['Ürəkdöyünmə, nəfəs darlığı, güclü qorxu','Yalnız yuxululuq','Yalnız iştahsızlıq','Əlamətsiz keçir'],1),
('bio11-insan-muhit#19','3','Sosial fobiya nəyi ifadə edir?','Sosial fobiya ictimai yerlərdə tənqid olunmaq qorxusundan yaranan güclü narahatlıqdır.',array['İctimai mühitdə tənqid olunmaq qorxusu','Yalnız hündürlükdən qorxu','Yalnız qaranlıqdan qorxu','Ümumi yorğunluq'],1),
('bio11-insan-muhit#20','1','Davamlı kefsizlik, maraq itkisi və yorğunluqla səciyyələnən psixi pozuntu necə adlanır?','Bu əlamətlər depressiyaya xasdır.',array['Depressiya','Eyforiya','Fobiya','Amneziya'],1),
('bio11-insan-muhit#21','2','Depressiya adi kefsizlik halından nə ilə fərqlənir?','Depressiya adətən iki həftədən artıq davam edir və gündəlik həyata mane olur.',array['Uzun müddət davam edib gündəlik həyata mane olması','Yalnız bir gün davam etməsi','Yalnız uşaqlarda olması','Heç bir fərqi yoxdur'],1),
('bio11-insan-muhit#22','2','Depressiyanın müalicəsində hansı yanaşmalar tətbiq olunur?','Psixoterapiya, zərurət yaranarsa dərman müalicəsi ilə birgə aparılır.',array['Psixoterapiya və zərurətdə dərman müalicəsi','Yalnız istirahət','Yalnız pəhriz','Müalicə tələb olunmur'],1),
('bio11-insan-muhit#23','2','Reallıqla əlaqənin pozulması, hallüsinasiya və sanrılarla müşayiət olunan ağır psixi pozuntu necə adlanır?','Bu, psixozdur.',array['Psixoz','Fobiya','Stress','Adaptasiya pozuntusu'],1),
('bio11-insan-muhit#24','3','Şizofreniya hansı qrup pozuntulara aiddir?','Şizofreniya psixotik pozuntular qrupuna aiddir.',array['Psixotik pozuntulara','Yalnız təşviş pozuntularına','Yalnız əhval pozuntularına','Yaddaş pozuntularına'],1),
('bio11-insan-muhit#25','2','Psixoz zamanı xəstənin öz vəziyyətinə münasibəti nevrozdan (məsələn, təşviş pozuntusundan) nə ilə fərqlənir?','Psixozda xəstə çox vaxt öz vəziyyətini tənqidi qiymətləndirə bilmir.',array['Xəstə vəziyyətini tənqidi qiymətləndirə bilmir','Xəstə vəziyyətini tam dərk edir','Fərq yoxdur','Psixozda simptom olmur'],1),
('bio11-insan-muhit#26','1','Sağlam ailə münasibətlərinin əsasını ilk növbədə nə təşkil edir?','Qarşılıqlı hörmət, açıq ünsiyyət və etibar sağlam münasibətlərin bünövrəsidir.',array['Qarşılıqlı hörmət, ünsiyyət və etibar','Maddi gəlirin miqdarı','Ailə üzvlərinin sayı','Yaş fərqi'],1),
('bio11-insan-muhit#27','1','Ailədə emosional dəstəyin əsas rolu nədir?','Emosional dəstək ailə üzvlərinin çətinliklərə davamlılığını artırır.',array['Çətinliklərə davamlılığı artırmaq','Maddi vəziyyəti yaxşılaşdırmaq','Yalnız əyləncə təmin etmək','Heç bir təsiri yoxdur'],1),
('bio11-insan-muhit#28','1','Ailədaxili münaqişələrin həllində ən düzgün yanaşma hansıdır?','Sakit, açıq ünsiyyət və qarşılıqlı dinləmə münaqişəni sağlam həll edir.',array['Sakit ünsiyyət və qarşılıqlı dinləmə','Münaqişədən tam qaçıb susmaq','Səsini yüksəltmək','Münasibəti kəsmək'],1),
('bio11-insan-muhit#29','2','Sağlam həyat tərzinin əsas komponentlərinə aiddir:','Düzgün qidalanma, fiziki aktivlik və yuxu rejimi sağlam həyat tərzinin əsasıdır.',array['Düzgün qidalanma, fiziki aktivlik, yuxu rejimi','Yalnız pəhriz','Yalnız idman','Yalnız yuxu'],1),
('bio11-insan-muhit#30','1','Zərərli vərdişlərdən (siqaret, alkoqol) çəkinmək ailə sağlamlığına necə təsir edir?','Zərərli vərdişlərdən uzaq durmaq ailə üzvlərinin fiziki və psixi sağlamlığını qoruyur.',array['Fiziki və psixi sağlamlığı qoruyur','Heç bir təsiri yoxdur','Yalnız xərci artırır','Ailə münasibətlərinə təsir etmir'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 4, 'published'
    from d
    join public.subjects s on s.slug = 'biologiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'bio-11-insan-muhit'
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
   where ext_key like 'bio11-insan-muhit#%' and ext_key !~ 'comb';
  if n <> 30 then
    raise exception '122: 30 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'bio11-insan-muhit#%' and q.ext_key !~ 'comb'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '122: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '122 OK - 30 sual duzeldildi (bio-11-insan-muhit, ekologiyadan embrional inkisaf+psixika+aile saglamligina).';
end $$;
