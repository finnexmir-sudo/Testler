-- =====================================================================
--  129_inf4_kompyuter_duzelis.sql : INF-4-KOMPYUTER DUZELISI
--
--  Movzu "Komputerde is" idi (metnlerin yigilmasi, metnlerle is,
--  metnin nizamlanmasi, senedin capa hazirlanmasi, "bu kitab nece
--  hazirlanib"), amma bankdaki 20 sualin HAMISI umumi komputer
--  aparati (monitor/maus/printer/noutbuk/planset) idi - kurikulumun
--  konkret mezmununa toxunmurdu. Istifadeci auditinde tapildi.
--
--  Bu fayl hemin 20 sualin HAMISINI duz mezmunla evez edir (eyni
--  ext_key-ler, on conflict do update - tekrar isledilse zerer
--  vermir). Esl menbe db/17_bank_sinif4.sql bil10-bank PRIVATE
--  repo-dadir (440 sual, cox fenn) - db/122 ile eyni sebebden
--  yalniz bu 20 setiri here goturdum.
--
--  ON SERT: 14_movzular.sql (ve ya movzu agacini quran fayl)
--  islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-4-kompyuter') then
    raise exception 'ONCE movzu agaci islenmis olmalidir (inf-4-kompyuter tapilmadi).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf4-kompyuter#%';

with d(ext, diff, body, why, opts, correct) as (values
('inf4-kompyuter#1','1','Mətn yazarkən sözlər arasında nə qoyulur?','Sözləri ayırmaq üçün boşluq (probel) qoyulur.',array['Boşluq (probel)','Vergül','Rəqəm','Şəkil'],1),
('inf4-kompyuter#2','2','Yazılmış mətndə bir abzasdan digərinə keçmək üçün hansı düymədən istifadə olunur?','Yeni abzasa Enter düyməsi ilə keçilir.',array['Enter','Boşluq','Shift','Tab yalnız'],1),
('inf4-kompyuter#3','1','Mətndə bir hissəni seçmək üçün nə edilir?','Maus (siçan) ilə mətnin üzərindən sürüşdürülür.',array['Siçanla üzərindən sürüşdürülür','Klaviatura sökülür','Ekran söndürülür','Printer işə salınır'],1),
('inf4-kompyuter#4','2','Seçilmiş mətni köçürmək (Copy) üçün hansı əməliyyat aparılır?','Copy əmri seçilmiş mətnin surətini yaddaşa (buferə) götürür.',array['Copy əmri seçilir','Fayl silinir','Printer açılır','Sənəd bağlanır'],1),
('inf4-kompyuter#5','2','Kəsilmiş (Cut) mətn haraya keçir?','Kəsilmiş mətn mübadilə buferinə (clipboard) keçir.',array['Mübadilə buferinə (clipboard)','Zibil qutusuna həmişəlik','Printerə','İnternetə'],1),
('inf4-kompyuter#6','2','Kopyalanmış mətni sənədə əlavə etmək üçün hansı əmr işlədilir?','Paste (Yerləşdir) əmri buferdəki mətni sənədə əlavə edir.',array['Paste (Yerləşdir)','Delete','Save','Print'],1),
('inf4-kompyuter#7','3','Kəsmə (Cut) ilə Kopyalama (Copy) arasındakı fərq nədir?','Cut mətni yerindən silir, Copy isə orijinalı yerində saxlayır.',array['Cut silir, Copy orijinalı saxlayır','Fərq yoxdur','Copy silir, Cut saxlayır','İkisi də çap edir'],1),
('inf4-kompyuter#8','1','Mətni səhifənin ortasına düzmək üçün hansı düzləndirmə üsulu işlədilir?','Mərkəzləşdirmə (Center) mətni ortaya düzür.',array['Mərkəzləşdirmə (Center)','Sola düzləndirmə','Sağa düzləndirmə','Kəsmə'],1),
('inf4-kompyuter#9','2','Mətni qalın (qara) etmək üçün hansı düymədən istifadə olunur?','Bold (B) düyməsi mətni qalınlaşdırır.',array['Bold (B)','Italic (I)','Underline (U)','Enter'],1),
('inf4-kompyuter#10','2','Mətni əyri (kursiv) yazmaq üçün hansı düymə işlədilir?','İtalic (I) düyməsi mətni əyri (kursiv) edir.',array['Italic (I)','Bold (B)','Underline (U)','Tab'],1),
('inf4-kompyuter#11','2','Mətnin altından xətt çəkmək üçün hansı düymədən istifadə olunur?','Underline (U) mətnin altından xətt çəkir.',array['Underline (U)','Bold (B)','Italic (I)','Delete'],1),
('inf4-kompyuter#12','2','Mətnin sağa, sola, ortaya və ya hər iki tərəfə düzülməsi necə adlanır?','Bu, mətnin düzləndirilməsi (alignment) adlanır.',array['Düzləndirmə (alignment)','Kəsmə','Kopyalama','Çap'],1),
('inf4-kompyuter#13','1','Sənədi çap etməzdən əvvəl onun necə görünəcəyini yoxlamaq üçün nə edilir?','Çapdan əvvəl baxış (Print Preview) sənədin çap görünüşünü göstərir.',array['Çapdan əvvəl baxış (Print Preview)','Faylı silmək','Sənədi bağlamaq','Şriftini dəyişmək'],1),
('inf4-kompyuter#14','2','Çap edilən vərəqin ölçüsünü və istiqamətini (üfüqi/şaquli) hansı bölmədə tənzimləmək olar?','Səhifə sazlaması (Page Setup) bölməsində tənzimlənir.',array['Səhifə sazlaması (Page Setup)','Şrift bölməsində','Fayl adı bölməsində','Səs bölməsində'],1),
('inf4-kompyuter#15','2','Sənədi çap etməzdən əvvəl səhvləri yoxlamaq nə üçün vacibdir?','Kağıza və vaxta qənaət etmək üçün vacibdir.',array['Kağıza və vaxta qənaət etmək üçün','Kompüteri sürətləndirmək üçün','Faylı böyütmək üçün','Vacib deyil'],1),
('inf4-kompyuter#16','2','Bu kitab kimi çap materialları hazırlanarkən mətnlə yanaşı nə əlavə olunur?','Mətnlə yanaşı şəkillər və sxemlər əlavə olunur.',array['Şəkillər və sxemlər','Yalnız rəqəmlər','Yalnız rənglər','Heç nə'],1),
('inf4-kompyuter#17','2','Kitab səhifələrinin nizamlı görünməsi üçün nəyə əməl olunur?','Vahid tərtibat (format, şrift) qaydalarına əməl olunur.',array['Vahid tərtibat (format, şrift) qaydalarına','Təsadüfi rəngə','Hər səhifədə fərqli şriftə','Heç bir qaydaya'],1),
('inf4-kompyuter#18','3','Çap məhsulu hazırlanarkən mətn və şəkillərin düzgün yerləşdirilməsi prosesi necə adlanır?','Bu proses səhifə tərtibatı (layout) adlanır.',array['Səhifə tərtibatı (layout)','Fayl saxlanması','Çap növbəsi','Mətn seçimi'],1),
('inf4-kompyuter#19','1','Kompüterdə hazırlanmış sənədi saxlamaq üçün hansı əmr işlədilir?','Save (Yadda saxla) əmri sənədi yaddaşa yazır.',array['Save (Yadda saxla)','Print','Cut','Center'],1),
('inf4-kompyuter#20','1','Mətndə səhv yazılmış hərfi silmək üçün hansı düymədən istifadə olunur?','Backspace (və ya Delete) səhv yazılmış hərfi silir.',array['Backspace / Delete','Shift','Enter','Tab'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 3, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '4'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-4-kompyuter'
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
   where ext_key like 'inf4-kompyuter#%';
  if n <> 20 then
    raise exception '129: 20 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf4-kompyuter#%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '129: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '129 OK - 20 sual duzeldildi (inf-4-kompyuter, umumi komputer aparatindan metnlerle is+capa hazirliga).';
end $$;
