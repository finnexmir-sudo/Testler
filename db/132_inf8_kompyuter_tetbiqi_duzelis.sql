-- =====================================================================
--  132_inf8_kompyuter_tetbiqi_duzelis.sql : IKI TAM UYGUNSUZLUQ
--
--  "informatika ni yoxla" auditinde iki ciddi bosluq tapildi:
--
--  1) inf-8-kompyuter movzusunun alt-basliqlari (İŞ MASASININ
--     NİZAMLANMASI, İNFORMASİYA MODELİNİN AĞAC FORMASI, FAYLLARIN
--     AXTARIŞI, AĞACŞƏKİLLİ STRUKTUR ƏSASINDA MƏSƏLƏ HƏLLİ) haqqinda
--     TEK sual yox idi - movcud 20 sualin HAMISI kompyuter aparati
--     (ana plata, prosessor, RAM, videokart və s.) haqqinda idi -
--     bu, tamam basqa movzunun (inf-9-komputer) mezmunudur.
--  2) inf-8-tetbiqi movzusunun 6 alt-basligindan 4-u (ÜÇÖLÇÜLÜ
--     QRAFİKA, TİLLƏR VƏ ÜZLƏR, ÜÇÖLÇÜLÜ MODELLƏRİN QURULMASI,
--     MƏTN REDAKTORUNUN OBYEKTLƏRİ) heç toxunulmamisdi - 20 sualin
--     hamisi yalniz elektron cedvel (SUM/MAX/filtr) haqqinda idi.
--
--  Hər iki halda sual SAYI düz idi (20/20), çətinlik bölgüsü də
--  "məqbul" görünürdü - "HAZIRDIR" qaydasinin 4-cu bendine gore
--  (movzu ADI ile sualların MƏZMUNUNU tutuşdurmaq) bu, mundericati
--  oxumadan tapila bilmeyen bir bosluq idi.
--
--  Bu fayl movcud 40 sualin (20+20) HAMISINI evez edir - `tools/sinif8.py`-da
--  (bil10-bank) yenidən yazılıb, buradan SQL ile cixarilib.
--  ext_key deyismir: inf8-kompyuter#1-20, inf8-tetbiqi#1-20.
--
--  ON SERT: 39_bank_sinif8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'informatika' and t.slug in ('inf-8-kompyuter','inf-8-tetbiqi')
     having count(*) = 2) then
    raise exception 'ONCE 39_bank_sinif8.sql islenmis olmalidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and (q.ext_key like 'inf8-kompyuter#%' or q.ext_key like 'inf8-tetbiqi#%');

with d(ext, diff, body, why, opts, correct) as (values
('inf8-kompyuter#1','2','İş masasında piktoqramları avtomatik düzmək üçün hansı əlamətlərdən istifadə edilə bilər?','Ad, ölçü, tarix və növünə görə avtomatik düzmək olar.',array['Ad, ölçü, tarix, növ','Yalnız rəngə görə','Yalnız səsə görə','Mümkün deyil'],1),
('inf8-kompyuter#2','1','İş masasının fon şəklini (divar kağızını) dəyişmək üçün hansı əməliyyat aparılır?','Boş yerə sağ klik edib «Fərdiləşdirmə»ni seçmək lazımdır.',array['Sağ klik → Fərdiləşdirmə','Faylı silmək','Kompüteri yenidən qurmaq','Printerə göndərmək'],1),
('inf8-kompyuter#3','2','Tapşırıqlar panelində (Taskbar) adətən nə göstərilir?','Açıq proqramlar, sürətli işə salma nişanları və saat göstərilir.',array['Açıq proqramlar və saat','Yalnız divar kağızı','Yalnız fayllar','Yalnız internet səhifələri'],1),
('inf8-kompyuter#4','3','İş masasındakı qısayol (shortcut) nişanını əsl fayldan hansı əlamət fərqləndirir?','Qısayol nişanının küncündə kiçik ox işarəsi olur.',array['Kiçik ox işarəsi','Qırmızı rəng','Böyük ölçü','Səs siqnalı'],1),
('inf8-kompyuter#5','2','Piktoqramları əlifba sırası ilə düzmək istəyəndə hansı əlamətə görə sıralama seçilir?','Ad əlamətinə görə sıralama seçilir.',array['Ad','Ölçü','Tarix','Növ'],1),
('inf8-kompyuter#6','2','Kompüterdə qovluqların bir-birinin içində yerləşdirilməsi hansı informasiya modelinə uyğun gəlir?','Bu, ağac modelinə uyğun gəlir.',array['Ağac modeli','Cədvəl modeli','Siyahı modeli','Xəritə modeli'],1),
('inf8-kompyuter#7','2','Ağac modelində ən yuxarıda duran, başlanğıc element necə adlanır?','Ağacın ən yuxarı başlanğıc elementi kök adlanır.',array['Kök','Yarpaq','Budaq','Gövdə'],1),
('inf8-kompyuter#8','2','Bir qovluğun daxilində yerləşən digər qovluq ağac modelində necə adlanır?','Bu, alt qovluq (budaq elementi) adlanır.',array['Alt qovluq (budaq)','Kök','Fayl uzantısı','Sürücü hərfi'],1),
('inf8-kompyuter#9','2','Ailə şəcərəsi (nəsil ağacı) hansı informasiya modelinə misaldır?','Ailə şəcərəsi ağac modelinə misaldır.',array['Ağac modelinə','Cədvəl modelinə','Qrafik modelinə','Mətn modelinə'],1),
('inf8-kompyuter#10','3','Ağac modelinin əsas xüsusiyyəti nədir?','Kökdən başqa hər elementin yalnız bir yuxarı (valideyn) elementi olur.',array['Kökdən başqa hər elementin bir yuxarı səviyyəsi olur','Bütün elementlər bərabər səviyyədədir','Elementlər arasında əlaqə yoxdur','Yalnız bir element ola bilər'],1),
('inf8-kompyuter#11','3','Fayl axtarışında * (ulduz) işarəsi nəyi bildirir?','İstənilən sayda simvolu əvəz edən xüsusi (wildcard) işarədir.',array['İstənilən sayda simvolu əvəz edir','Yalnız bir hərfi əvəz edir','Faylı silir','Qovluğu bağlayır'],1),
('inf8-kompyuter#12','2','Faylın adını unutsaq, lakin uzantısını bilsək, necə axtarmaq olar?','*.uzantı yazaraq həmin uzantılı bütün faylları tapmaq olar.',array['*.uzantı yazmaqla','Yalnız ad yazmaqla','Kompüteri yenidən başlatmaqla','Mümkün deyil'],1),
('inf8-kompyuter#13','2','Fayl axtarışı zamanı hansı əlamətlərə görə axtarış aparmaq olar?','Ad, uzantı, ölçü və dəyişdirilmə tarixinə görə axtarış aparıla bilər.',array['Ad, uzantı, ölçü, tarix','Yalnız rəngə görə','Yalnız müəllifin boyuna görə','Yalnız kağız formatına görə'],1),
('inf8-kompyuter#14','3','Müəyyən bir qovluqda axtarış apararkən nəticələr haradan gətirilir?','Nəticələr o qovluq və onun alt qovluqlarından gətirilir.',array['O qovluq və alt qovluqlarından','Bütün kompüterdən hökmən','Yalnız Zibil qutusundan','Yalnız İnternetdən'],1),
('inf8-kompyuter#15','2','Fayl adında axtarış aparanda böyük və kiçik hərflər fərqləndirilirmi?','Xeyr, adətən fayl adının böyük/kiçik hərfi fərqləndirilmir.',array['Xeyr, fərqlənmir','Bəli, həmişə fərqlənir','Yalnız rəqəmlərdə fərqlənir','Yalnız ilk hərfdə fərqlənir'],1),
('inf8-kompyuter#16','2','Bir qovluqda 3 alt qovluq var, hər alt qovluqda 4 fayl yerləşir. Bu qovluqda (alt qovluqlarla birlikdə) cəmi neçə fayl var?','3 alt qovluq × 4 fayl = 12 fayl.',array['12','7','3','4'],1),
('inf8-kompyuter#17','2','Kökdən konkret fayla qədər olan ardıcıl qovluqlar zənciri necə adlanır?','Bu zəncir yol (marşrut) adlanır.',array['Yol (marşrut)','Ünvan zolağı','Etiket','Format'],1),
('inf8-kompyuter#18','3','Ağac strukturunda «yarpaq» termini nəyi bildirir?','Yarpaq — daxilində başqa alt element olmayan son elementdir.',array['Daxilində alt element olmayan son elementi','Ən yuxarı elementi','Ən böyük faylı','Zibil qutusunu'],1),
('inf8-kompyuter#19','2','A qovluğunda B və C adlı 2 alt qovluq var. B-də 5, C-də 3 fayl yerləşir. A qovluğunda (alt qovluqlarla birlikdə) cəmi neçə fayl var?','5 + 3 = 8 fayl.',array['8','5','3','2'],1),
('inf8-kompyuter#20','3','Bir ağac strukturunda kökdən sonra 2 səviyyə var və hər budaqdan 3 alt budaq çıxır. İkinci səviyyədə neçə element olar?','3 × 3 = 9 element.',array['9','6','3','12'],1),
('inf8-tetbiqi#1','2','Üçölçülü (3D) qrafikanı ikiölçülü (2D) qrafikadan fərqləndirən əsas cəhət nədir?','3D qrafikada dərinlik — Z oxu üzrə ölçü əlavə olunur.',array['Dərinliyin (Z oxu) əlavə olunması','Yalnız rənglərin çoxluğu','Faylın adı','Ekranın ölçüsü'],1),
('inf8-tetbiqi#2','2','3D modeldə obyektin en, uzunluq və hündürlüyü hansı oxlarla ifadə olunur?','X, Y və Z oxları ilə ifadə olunur.',array['X, Y, Z oxları ilə','Yalnız X oxu ilə','A, B, C hərfləri ilə','Rəqəmlərlə deyil, sözlərlə'],1),
('inf8-tetbiqi#3','2','3D qrafika ilə hazırlanan modellərdən harada geniş istifadə olunur?','Animasiya, kompüter oyunları və arxitektura layihələrində.',array['Animasiya, oyun, arxitektura layihələrində','Yalnız mətn yazmaqda','Yalnız musiqi yazmaqda','Yalnız cədvəl qurmaqda'],1),
('inf8-tetbiqi#4','2','3D modeldə iki təpə nöqtəsini (vertex) birləşdirən xətt necə adlanır?','Bu xətt til (kənar) adlanır.',array['Til (kənar)','Üz','Kök','Budaq'],1),
('inf8-tetbiqi#5','2','3D modeldə bir neçə tildən əmələ gələn müstəvi hissə necə adlanır?','Bu hissə üz adlanır.',array['Üz','Til','Nöqtə','Kölgə'],1),
('inf8-tetbiqi#6','3','Kubun neçə üzü və neçə tili vardır?','Kubun 6 üzü və 12 tili vardır.',array['6 üz, 12 til','4 üz, 6 til','8 üz, 6 til','6 üz, 8 til'],1),
('inf8-tetbiqi#7','2','3D model qurarkən adətən ilk addım nədir?','Sadə həndəsi fiqurdan (kub, kürə, silindr) başlamaqdır.',array['Sadə həndəsi fiqurdan başlamaq','Dərhal rəngləmək','Faylı çap etmək','Səs əlavə etmək'],1),
('inf8-tetbiqi#8','2','Hazır 3D modelə rəng və toxuma (texture) əlavə etmək nə üçündür?','Modelə real görünüş vermək üçün.',array['Real görünüş vermək üçün','Faylın həcmini azaltmaq üçün','Modeli silmək üçün','Modeli sadələşdirmək üçün'],1),
('inf8-tetbiqi#9','3','3D printerlə çap etmək üçün hazırlanan model hansı formada olmalıdır?','Xüsusi üçölçülü fayl formatında olmalıdır.',array['Xüsusi 3D fayl formatında','Yalnız mətn sənədi kimi','Yalnız şəkil kimi (JPG)','Səs faylı kimi'],1),
('inf8-tetbiqi#10','2','Mətn sənədinə əlavə olunan cədvəl, şəkil, diaqram kimi elementlər ümumi necə adlanır?','Bu elementlər obyekt adlanır.',array['Obyekt','Şrift','Format','Sənəd'],1),
('inf8-tetbiqi#11','2','Mətn redaktorunda WordArt vasitəsilə nə yaradılır?','Bəzəkli, effektli mətn yaradılır.',array['Bəzəkli (effektli) mətn','Cədvəl','Diaqram','Şəkil çərçivəsi'],1),
('inf8-tetbiqi#12','3','Sənəddə obyektin ətrafında mətnin necə yerləşdiyini müəyyən edən parametr necə adlanır?','Bu parametr mətnin dövrələnməsi (Wrap Text) adlanır.',array['Mətnin dövrələnməsi (Wrap Text)','Şriftin ölçüsü','Səhifənin istiqaməti','Sətir aralığı'],1),
('inf8-tetbiqi#13','2','Elektron cədvəl proqramına misal hansıdır?','Excel elektron cədvəl proqramıdır.',array['Excel','Paint','Notepad','Chrome'],1),
('inf8-tetbiqi#14','2','Elektron cədvəldə xananın ünvanı necə yazılır?','Sütun hərfi və sətir nömrəsi ilə: A1.',array['Sütun hərfi + sətir nömrəsi (A1)','Yalnız rəqəmlə','Yalnız hərflə','Ünvanı olmur'],1),
('inf8-tetbiqi#15','2','Cədvəl məlumatları əsasında nə qurmaq olar?','Diaqram qurmaq olar.',array['Diaqram','Ev','Oyun','Mahnı'],1),
('inf8-tetbiqi#16','2','Verilənləri sıralamaq (sort) nə deməkdir?','Artan və ya azalan qaydada düzmək.',array['Artan/azalan qaydada düzmək','Silmək','Rəngləmək','Çap etmək'],1),
('inf8-tetbiqi#17','2','Elektron cədvəldə düstur hansı işarə ilə başlayır?','Düsturlar = işarəsi ilə başlayır.',array['=','+','%','#'],1),
('inf8-tetbiqi#18','2','=A1+B1 düsturu nə edir?','A1 və B1 xanalarının cəmini hesablayır.',array['İki xananın cəmini hesablayır','Xanaları silir','Şrift dəyişir','Sətir əlavə edir'],1),
('inf8-tetbiqi#19','2','SUM funksiyası nə üçündür?','Diapazonun cəmini hesablamaq üçün.',array['Cəmi hesablamaq üçün','Rəngləmək üçün','Silmək üçün','Çap etmək üçün'],1),
('inf8-tetbiqi#20','3','Düsturu digər xanalara sürükləyəndə nə baş verir?','Xana ünvanları avtomatik dəyişir.',array['Ünvanlar avtomatik dəyişir','Düstur silinir','Cədvəl bağlanır','Heç nə'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 2, 'published'
    from d
    join public.subjects s on s.slug = 'informatika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '8'
    join public.topics   tp on tp.subject_id = s.id
      and tp.slug = case when d.ext like 'inf8-kompyuter%' then 'inf-8-kompyuter'
                          else 'inf-8-tetbiqi' end
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
   where ext_key like 'inf8-kompyuter#%' or ext_key like 'inf8-tetbiqi#%';
  if n <> 40 then
    raise exception '132: 40 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'inf8-kompyuter#%' or q.ext_key like 'inf8-tetbiqi#%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '132: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '132 OK - inf-8-kompyuter (is masasi+agac+axtaris) ve inf-8-tetbiqi (3D qrafika+metn obyektleri+cedvel) duzeldildi.';
end $$;
