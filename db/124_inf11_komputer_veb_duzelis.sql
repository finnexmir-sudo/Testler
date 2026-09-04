-- =====================================================================
--  124_inf11_komputer_veb_duzelis.sql : INF-11-KOMPUTER-VEB DUZELISI
--
--  Movzu "Komputerin idare edilmesi. Veb-layihe" idi (Idareetme
--  paneli, Sesin idaresi, Enerji serfiyyati, Istifadeci hesablari/
--  Aile tehlukesizliyi, Uzaqdan idareetme, Veb-sayt layihesi, Word/
--  Excel/PowerPoint-de veb-sehife, Saytlarin nesri), amma bankdaki
--  20 sualin HAMISI umumi komputer aparati (CPU/RAM/SSD) ve umumi
--  veb-dizayn (HTML/CSS/JS) idi - kurikulumun konkret basliqlarina
--  toxunmurdu. Istifadeci auditinde tapildi.
--
--  Bu fayl hemin 20 sualin HAMISINI duz mezmunla evez edir (eyni
--  ext_key-ler, on conflict do update - tekrar isledilse zerer
--  vermir). Esl menbe db/51_bank_sinif11.sql bil10-bank PRIVATE
--  repo-dadir (700 sual, cox movzu) - db/122 ile eyni sebebden
--  yalniz bu 20 setiri here goturdum.
--
--  ON SERT: 49_movzular_orta11.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug = 'inf-11-komputer-veb') then
    raise exception 'ONCE 49_movzular_orta11.sql islenmis olmalidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'inf11-komputer-veb#%'
   and q.ext_key !~ 'comb';

with d(ext, diff, body, why, opts, correct) as (values
('inf11-komputer-veb#1','1','İdarəetmə paneli (Control Panel) nə üçün istifadə olunur?','Kompüterin ekran, səs, proqram, hesab kimi parametrlərini tənzimləmək üçün.',array['Sistem parametrlərini tənzimləmək üçün','Mətn yazmaq üçün','Şəkil çəkmək üçün','Fayl arxivləmək üçün'],1),
('inf11-komputer-veb#2','2','İdarəetmə panelindən ekranın ayırdetmə qabiliyyəti (rezolyusiya) necə dəyişdirilir?','Ekran parametrləri bölməsindən müvafiq ölçü seçilir.',array['Ekran parametrləri bölməsindən','Səs bölməsindən','İstifadəçi hesabları bölməsindən','Printer bölməsindən'],1),
('inf11-komputer-veb#3','2','Proqramların silinməsi (uninstall) adətən İdarəetmə panelinin hansı bölməsindən edilir?','Proqramlar (Programs) bölməsi quraşdırılmış proqramların siyahısını göstərir.',array['Proqramlar bölməsindən','Şəbəkə bölməsindən','Səs bölməsindən','Tarix və saat bölməsindən'],1),
('inf11-komputer-veb#4','1','Kompüterdə səs səviyyəsini tənzimləmək üçün hansı vasitədən istifadə olunur?','Səs parametrləri (volume mixer) proqram və sistem səsini ayrı-ayrı tənzimləyir.',array['Səs parametrləri (volume mixer)','Ekran parametrləri','Fayl menecerı','Printer sazlaması'],1),
('inf11-komputer-veb#5','2','Mikrofonun səsi qeydə alınmadıqda ilk növbədə nə yoxlanmalıdır?','Standart qeydəalma cihazının düzgün seçilib-seçilmədiyi.',array['Standart qeydəalma cihazının seçimi','Ekranın parlaqlığı','İnternet sürəti','Printer kartriji'],1),
('inf11-komputer-veb#6','1','Noutbukda enerjiyə qənaət (Power saver) planı seçildikdə nə baş verir?','Enerji sərfiyyatı azalır, batareya daha uzun müddət işləyir.',array['Enerji sərfiyyatı azalır','Prosessor sürəti artır','Ekran parlaqlığı artır','Fayl ölçüsü kiçilir'],1),
('inf11-komputer-veb#7','2','Kompüterin müəyyən müddət istifadə olunmadıqda avtomatik yuxu (sleep) rejiminə keçməsinin faydası nədir?','Enerjiyə qənaət edilir, kompüter tez oyanmağa hazır qalır.',array['Enerjiyə qənaət edilir','Fayllar silinir','İnternet sürəti artır','Ekran ölçüsü dəyişir'],1),
('inf11-komputer-veb#8','2','Kompüterdə administrator hesabı ilə standart istifadəçi hesabı arasındakı fərq nədir?','Administrator sistem parametrlərini sərbəst dəyişə bilər, standart istifadəçi məhduddur.',array['Administrator sistemi idarə edə bilər, standart məhduddur','Fərq yoxdur','Standart hesabın imkanı daha çoxdur','Yalnız adları fərqlidir'],1),
('inf11-komputer-veb#9','1','Ailə təhlükəsizliyi (Family Safety) funksiyası valideynlərə nə imkanı verir?','Uşağın ekran vaxtını və giriş etdiyi məzmunu məhdudlaşdırmaq imkanı verir.',array['Ekran vaxtını və məzmunu məhdudlaşdırmaq','İnterneti tamamilə söndürmək','Kompüteri sürətləndirmək','Faylları avtomatik silmək'],1),
('inf11-komputer-veb#10','2','Bir kompüterdə bir neçə istifadəçi hesabının olmasının əsas üstünlüyü nədir?','Hər istifadəçinin öz fərdi parametr və fayllarını ayrı saxlaya bilməsidir.',array['Hər kəsin öz fərdi parametr və faylları olur','Kompüter sürətlənir','İnternet sürəti artır','Yaddaş həcmi çoxalır'],1),
('inf11-komputer-veb#11','2','Uzaqdan idarəetmə (Remote Desktop) funksiyası nəyə imkan verir?','Başqa kompüterə şəbəkə üzərindən qoşulub onu idarə etməyə imkan verir.',array['Başqa kompüterə şəbəkədən qoşulub idarə etməyə','Yalnız fayl çap etməyə','Yalnız şəkil çəkməyə','Kompüteri söndürməyə'],1),
('inf11-komputer-veb#12','3','Uzaqdan idarəetmə funksiyasını aktiv edərkən diqqət edilməli əsas təhlükəsizlik məsələsi nədir?','İcazəsiz girişin qarşısını almaq üçün güclü parol və icazə tələbi lazımdır.',array['Güclü parol və icazə tələbi olmalıdır','Funksiya heç vaxt söndürülməməlidir','Yalnız açıq şəbəkədən işlədilməlidir','Təhlükəsizlik məsələsi yoxdur'],1),
('inf11-komputer-veb#13','1','Veb-sayt layihəsinə başlamazdan əvvəl ilk növbədə nə müəyyənləşdirilməlidir?','Saytın məqsədi və məzmun strukturu müəyyənləşdirilməlidir.',array['Saytın məqsədi və məzmun strukturu','Server rəngi','Domen adının şrifti','Printer modeli'],1),
('inf11-komputer-veb#14','2','Veb-sayt layihəsində səhifələr arasında keçidi təmin edən element necə adlanır?','Naviqasiya menyusu (keçidlər) istifadəçini bölmələr arasında yönləndirir.',array['Naviqasiya menyusu','Başlıq şrifti','Fon rəngi','Səhifə nömrəsi'],1),
('inf11-komputer-veb#15','2','Word sənədini veb-səhifə kimi saxlamaq üçün hansı yol izlənilir?','Fayl > Fərqli saxla seçilib fayl növü kimi Veb səhifə göstərilir.',array['Fayl > Fərqli saxla > Veb səhifə','Fayl > Çap et','Bax > Miqyas','Daxil et > Şəkil'],1),
('inf11-komputer-veb#16','3','Word sənədi veb-səhifə kimi saxlananda hansı fayl formatı yaranır?','Nəticə .htm və ya .html formatında olur.',array['.htm/.html','.docx','.pdf','.txt'],1),
('inf11-komputer-veb#17','2','Excel cədvəlini veb-səhifə kimi saxlamağın faydası nədir?','Cədvəli xüsusi proqram olmadan birbaşa brauzerdə açıb göstərmək mümkün olur.',array['Cədvəli brauzerdə göstərmək mümkün olur','Cədvəl avtomatik hesablanmır','Fayl ölçüsü böyüyür yalnız','Düsturlar itir, faydası yoxdur'],1),
('inf11-komputer-veb#18','2','PowerPoint təqdimatını veb-səhifə formatında saxlamaqla nəyə nail olunur?','Təqdimatı PowerPoint proqramı olmadan brauzerdə göstərmək mümkün olur.',array['Brauzerdə proqramsız göstərmək mümkün olur','Slaydlar avtomatik silinir','Animasiyalar sürətlənir','Fayl heç yerdə açılmır'],1),
('inf11-komputer-veb#19','1','Hazır veb-saytı internetdə hamıya əlçatan etmək üçün nə lazımdır?','Hostinq (server yeri) və domen adı lazımdır.',array['Hostinq və domen adı','Yalnız printer','Yalnız kağız','Yalnız telefon nömrəsi'],1),
('inf11-komputer-veb#20','2','Bir veb-saytın etibarlılığını qiymətləndirərkən nələrə diqqət etmək lazımdır?','Mənbənin müəllifinə, yenilənmə tarixinə və məzmunun dəqiqliyinə diqqət edilir.',array['Müəllif, tarix və məzmunun dəqiqliyi','Yalnız rənglərin sayı','Yalnız şriftin ölçüsü','Yalnız səhifə sayı'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '11'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'inf-11-komputer-veb'
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
   where ext_key like 'inf11-komputer-veb#%' and ext_key !~ 'comb';
  if n <> 20 then
    raise exception '124: 20 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'inf11-komputer-veb#%' and q.ext_key !~ 'comb'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '124: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '124 OK - 20 sual duzeldildi (inf-11-komputer-veb, umumi komputer/veb-den konkret idareetme+veb-layiheye).';
end $$;
