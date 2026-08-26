-- =====================================================================
--  17_bank_sinif4.sql : 4-CU SINIF - AZ DILI, HEYAT BILGISI, INFORMATIKA
--
--  BU FAYL ELLE YAZILMIR - tools/sinif4.py yaradir:
--      python3 tools/sinif4.py
--
--  Az dili 8 movzu + Heyat bilgisi 5 + Informatika 3 = 16 movzu x 10
--  sual = 160.  Suallar orijinaldir.  ext_key: az4-/hey4-/inf4-...
--
--  ON SERT: 14_movzular.sql ve 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('az-dili','az-4-isim-hallari'),
                                ('hayat-bilgisi','hey-4-canli-heyat'),
                                ('informatika','inf-4-informasiya'))
     having count(*) = 3) then
    raise exception 'ONCE 14_movzular.sql ve 15_movzular_ederslik.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'az4-%' or q.ext_key like 'hey4-%'
        or q.ext_key like 'inf4-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('az4-isim-hallari#1','az-dili','az-4-isim-hallari',1,1,'İsmin neçə halı var?','İsmin 6 halı var: adlıq, yiyəlik, yönlük, təsirlik, yerlik, çıxışlıq.',array['6','5','4','3'],1),
('az4-isim-hallari#2','az-dili','az-4-isim-hallari',2,1,'«Kitabın» sözü ismin hansı halındadır?','-ın şəkilçisi yiyəlik halın şəkilçisidir: kitabın (nəyin?).',array['Yiyəlik','Yönlük','Adlıq','Yerlik'],1),
('az4-isim-hallari#3','az-dili','az-4-isim-hallari',2,1,'«Məktəbə» sözü ismin hansı halındadır?','-a, -ə şəkilçisi yönlük halı bildirir: məktəbə (haraya?).',array['Yönlük','Yerlik','Çıxışlıq','Yiyəlik'],1),
('az4-isim-hallari#4','az-dili','az-4-isim-hallari',2,1,'«Bağçada» sözü ismin hansı halındadır?','-da, -də şəkilçisi yerlik halı bildirir: bağçada (harada?).',array['Yerlik','Yönlük','Təsirlik','Adlıq'],1),
('az4-isim-hallari#5','az-dili','az-4-isim-hallari',2,1,'«Şəhərdən» sözü ismin hansı halındadır?','-dan, -dən şəkilçisi çıxışlıq halı bildirir: şəhərdən (haradan?).',array['Çıxışlıq','Yerlik','Yönlük','Yiyəlik'],1),
('az4-isim-hallari#6','az-dili','az-4-isim-hallari',2,1,'Hansı söz adlıq haldadır?','Adlıq halda söz hal şəkilçisiz olur və «kim? nə?» sualına cavab verir.',array['qələm','qələmin','qələmə','qələmdə'],1),
('az4-isim-hallari#7','az-dili','az-4-isim-hallari',3,1,'«Aysu kitabı rəfə qoydu» cümləsində «kitabı» sözü hansı haldadır?','-ı şəkilçisi burada təsirlik halı bildirir: kitabı (nəyi?).',array['Təsirlik','Yiyəlik','Yerlik','Adlıq'],1),
('az4-isim-hallari#8','az-dili','az-4-isim-hallari',2,1,'Yerlik halın şəkilçiləri hansılardır?','Yerlik hal «harada?» sualına cavab verir, şəkilçiləri -da, -də-dir.',array['-da, -də','-dan, -dən','-a, -ə','-ın, -in'],1),
('az4-isim-hallari#9','az-dili','az-4-isim-hallari',3,1,'«Evin qapısı» birləşməsində «evin» sözü hansı haldadır?','«Evin» (nəyin?) — yiyəlik haldadır, mənsubiyyət bildirir.',array['Yiyəlik','Adlıq','Yönlük','Çıxışlıq'],1),
('az4-isim-hallari#10','az-dili','az-4-isim-hallari',2,1,'Hansı sözdə çıxışlıq hal şəkilçisi var?','Meşədən (haradan?) — çıxışlıq hal.',array['meşədən','meşədə','meşəyə','meşəni'],1),
('az4-metn-novleri#1','az-dili','az-4-metn-novleri',1,1,'Mətn nədir?','Mətn məzmunca bir-biri ilə bağlı cümlələrin ardıcıllığıdır.',array['Bir-biri ilə bağlı cümlələrin ardıcıllığı','Ayrı-ayrı sözlərin siyahısı','Bir cümlə','Hərflərin cərgəsi'],1),
('az4-metn-novleri#2','az-dili','az-4-metn-novleri',1,1,'Mətnin hissələri hansılardır?','Mətn giriş, əsas hissə və nəticədən ibarət olur.',array['Giriş, əsas hissə, nəticə','Başlıq və şəkil','Sual və cavab','Söz və cümlə'],1),
('az4-metn-novleri#3','az-dili','az-4-metn-novleri',2,1,'Hadisəni baş vermə ardıcıllığı ilə danışan mətn necə adlanır?','Nəqli mətn hadisəni ardıcıllıqla nəql edir.',array['Nəqli mətn','Təsviri mətn','Mühakimə mətni','Elan'],1),
('az4-metn-novleri#4','az-dili','az-4-metn-novleri',2,1,'Əşyanı, təbiəti və ya insanı təsvir edən mətn necə adlanır?','Təsviri mətn əlamətləri sadalayıb təsvir yaradır.',array['Təsviri mətn','Nəqli mətn','Mühakimə mətni','Məktub'],1),
('az4-metn-novleri#5','az-dili','az-4-metn-novleri',3,1,'Fikri əsaslandırıb sübut edən mətn necə adlanır?','Mühakimə mətnində fikir irəli sürülür və səbəblərlə əsaslandırılır.',array['Mühakimə mətni','Nəqli mətn','Təsviri mətn','Nağıl'],1),
('az4-metn-novleri#6','az-dili','az-4-metn-novleri',2,1,'Nağıl hansı mətn növünə daha yaxındır?','Nağılda hadisələr ardıcıl nəql olunur.',array['Nəqli','Təsviri','Mühakimə','Elan'],1),
('az4-metn-novleri#7','az-dili','az-4-metn-novleri',3,1,'«Payız meşəsi çox gözəldir. Yarpaqlar saralmış, hava sərindir…» — bu parça hansı mətn növüdür?','Parça meşənin əlamətlərini təsvir edir.',array['Təsviri','Nəqli','Mühakimə','Dialoq'],1),
('az4-metn-novleri#8','az-dili','az-4-metn-novleri',2,1,'Mətnə başlıq nəyə əsasən seçilir?','Başlıq mətnin əsas fikrini əks etdirməlidir.',array['Əsas fikrə','Cümlələrin sayına','İlk sözə','Mətnin uzunluğuna'],1),
('az4-metn-novleri#9','az-dili','az-4-metn-novleri',2,1,'Şeiri hekayədən fərqləndirən əsas xüsusiyyət nədir?','Şeir misralarla, çox vaxt qafiyəli yazılır.',array['Misralarla yazılması','Uzun olması','Başlığının olması','Cümlələrdən ibarət olması'],1),
('az4-metn-novleri#10','az-dili','az-4-metn-novleri',1,1,'Mətndəki cümlələr necə olmalıdır?','Cümlələr məzmunca bağlı olmasa, mətn alınmaz.',array['Məzmunca bir-biri ilə bağlı','Hamısı sual cümləsi','Bir-birindən asılı olmayan','Hamısı eyni sözlə başlayan'],1),
('az4-sifet-dereceleri#1','az-dili','az-4-sifet-dereceleri',1,2,'Sifət əşyanın nəyini bildirir?','Sifət əşyanın əlamətini bildirir: necə? nə cür? hansı?',array['Əşyanın əlamətini','Hərəkəti','Miqdarı','Əşyanın adını'],1),
('az4-sifet-dereceleri#2','az-dili','az-4-sifet-dereceleri',1,2,'Sifətin neçə dərəcəsi var?','Sifətin üç dərəcəsi var: adi, azaltma, çoxaltma.',array['3','2','4','6'],1),
('az4-sifet-dereceleri#3','az-dili','az-4-sifet-dereceleri',2,2,'«Qıpqırmızı» sifəti hansı dərəcədədir?','İlk hecanın təkrarı ilə düzələn belə sifətlər çoxaltma dərəcəsindədir.',array['Çoxaltma','Azaltma','Adi','Heç biri'],1),
('az4-sifet-dereceleri#4','az-dili','az-4-sifet-dereceleri',2,2,'«Sarımtıl» sifəti hansı dərəcədədir?','-ımtıl şəkilçisi əlamətin azlığını bildirir.',array['Azaltma','Çoxaltma','Adi','Heç biri'],1),
('az4-sifet-dereceleri#5','az-dili','az-4-sifet-dereceleri',2,2,'«Hündür» sifəti hansı dərəcədədir?','Şəkilçisiz, adi qaydada deyilən sifət adi dərəcədədir.',array['Adi','Azaltma','Çoxaltma','Heç biri'],1),
('az4-sifet-dereceleri#6','az-dili','az-4-sifet-dereceleri',2,2,'«Ən maraqlı» birləşməsində sifət hansı dərəcədədir?','«Ən» sözü ilə çoxaltma dərəcəsi düzəlir.',array['Çoxaltma','Azaltma','Adi','Heç biri'],1),
('az4-sifet-dereceleri#7','az-dili','az-4-sifet-dereceleri',2,2,'Hansı sırada bütün sözlər sifətdir?','Gözəl, uca, şirin — hamısı əlamət bildirir.',array['gözəl, uca, şirin','gözəl, qaçmaq, beş','dağ, uca, kitab','şirin, oxumaq, alma'],1),
('az4-sifet-dereceleri#8','az-dili','az-4-sifet-dereceleri',2,2,'Çoxaltma dərəcəsində olan sifəti seçin.','«Dümağ» — əlamətin çoxluğunu bildirir.',array['dümağ','sarımtıl','göyümtül','qara'],1),
('az4-sifet-dereceleri#9','az-dili','az-4-sifet-dereceleri',2,2,'Azaltma dərəcəsində olan sifət hansıdır?','-ımtıl şəkilçisi azaltma dərəcəsini düzəldir.',array['ağımtıl','qapqara','dümağ','yamyaşıl'],1),
('az4-sifet-dereceleri#10','az-dili','az-4-sifet-dereceleri',3,2,'«Daha güclü» birləşməsi sifətin hansı dərəcəsini bildirir?','«Daha» sözü ilə əlamətin çoxluğu — çoxaltma dərəcəsi bildirilir.',array['Çoxaltma dərəcəsi','Azaltma','Adi','Heç biri'],1),
('az4-fel-zamanlari#1','az-dili','az-4-fel-zamanlari',1,2,'Fel hansı mənanı ifadə edir?','Fel hərəkəti bildirir: nə edir? nə etdi? nə edəcək?',array['Hərəkəti','Əlaməti','Miqdarı','Əşyanın adını'],1),
('az4-fel-zamanlari#2','az-dili','az-4-fel-zamanlari',1,2,'Felin neçə zamanı var?','Felin üç zamanı var: keçmiş, indiki, gələcək.',array['3 (keçmiş, indiki, gələcək)','2','4','5'],1),
('az4-fel-zamanlari#3','az-dili','az-4-fel-zamanlari',2,2,'«Oxudu» feli hansı zamandadır?','-du şəkilçisi keçmiş zamanı bildirir.',array['Keçmiş','İndiki','Gələcək','Heç biri'],1),
('az4-fel-zamanlari#4','az-dili','az-4-fel-zamanlari',2,2,'«Yazır» feli hansı zamandadır?','-ır şəkilçisi indiki zamanı bildirir: hərəkət indi baş verir.',array['İndiki','Keçmiş','Gələcək','Heç biri'],1),
('az4-fel-zamanlari#5','az-dili','az-4-fel-zamanlari',2,2,'«Gedəcək» feli hansı zamandadır?','-acaq, -əcək şəkilçisi gələcək zamanı bildirir.',array['Gələcək','İndiki','Keçmiş','Heç biri'],1),
('az4-fel-zamanlari#6','az-dili','az-4-fel-zamanlari',2,2,'Hansı fel indiki zamandadır?','«Baxır» — hərəkət danışılan anda baş verir.',array['baxır','baxdı','baxacaq','baxmışdı'],1),
('az4-fel-zamanlari#7','az-dili','az-4-fel-zamanlari',2,2,'«Sabah kitab oxuyacağam» cümləsindəki fel hansı zamandadır?','-acağ(am) şəkilçisi gələcək zamanı göstərir; «sabah» sözü də ipucudur.',array['Gələcək','İndiki','Keçmiş','Heç biri'],1),
('az4-fel-zamanlari#8','az-dili','az-4-fel-zamanlari',2,2,'Keçmiş zamanda olan feli seçin.','«Gəldi» — hərəkət artıq baş verib.',array['gəldi','gəlir','gələcək','gəl'],1),
('az4-fel-zamanlari#9','az-dili','az-4-fel-zamanlari',3,2,'«Yağış yağırdı» cümləsindəki fel hansı zamana aiddir?','Hərəkət keçmişdə davam edirdi — keçmiş zamandır.',array['Keçmiş','İndiki','Gələcək','Heç biri'],1),
('az4-fel-zamanlari#10','az-dili','az-4-fel-zamanlari',3,2,'Verilmiş sözlərdən hansı feldir?','Fellər «nə etmək?» sualına cavab verir: qaçmaq.',array['qaçmaq','qaçış','cəld','yol'],1),
('az4-evezlik#1','az-dili','az-4-evezlik',1,3,'Şəxs əvəzlikləri nəyi əvəz edir?','Şəxs əvəzlikləri şəxs adlarının yerində işlənir.',array['Şəxs adlarını','Felləri','Sayları','Bağlayıcıları'],1),
('az4-evezlik#2','az-dili','az-4-evezlik',1,3,'Hansı söz əvəzlikdir?','«Onlar» — III şəxsin cəmini bildirən şəxs əvəzliyidir.',array['onlar','kitab','oxuyur','gözəl'],1),
('az4-evezlik#3','az-dili','az-4-evezlik',2,3,'«Mən» əvəzliyi hansı şəxsdədir?','Danışan özü — I şəxsin təki.',array['I şəxsin təki','II şəxsin təki','III şəxsin təki','I şəxsin cəmi'],1),
('az4-evezlik#4','az-dili','az-4-evezlik',2,3,'«Siz» əvəzliyi hansı şəxsdədir?','Müraciət olunan şəxslər — II şəxsin cəmi.',array['II şəxsin cəmi','II şəxsin təki','III şəxsin cəmi','I şəxsin cəmi'],1),
('az4-evezlik#5','az-dili','az-4-evezlik',2,3,'III şəxsin təki hansı əvəzlikdir?','Haqqında danışılan bir şəxs — «o».',array['o','biz','sən','onlar'],1),
('az4-evezlik#6','az-dili','az-4-evezlik',2,3,'«O, dərsə gecikdi» cümləsində əvəzlik hansıdır?','«O» — III şəxsin təkini bildirən əvəzlikdir.',array['O','dərsə','gecikdi','cümlədə əvəzlik yoxdur'],1),
('az4-evezlik#7','az-dili','az-4-evezlik',2,3,'Hansı sırada yalnız əvəzliklər verilib?','Mən, sən, biz — hamısı şəxs əvəzliyidir.',array['mən, sən, biz','mən, kitab, o','sən, gözəl, biz','o, oxudu, siz'],1),
('az4-evezlik#8','az-dili','az-4-evezlik',2,3,'«Biz» əvəzliyi hansı şəxsdədir?','Danışan özü ilə birlikdə başqalarını da nəzərdə tutur — I şəxsin cəmi.',array['I şəxsin cəmi','I şəxsin təki','II şəxsin cəmi','III şəxsin cəmi'],1),
('az4-evezlik#9','az-dili','az-4-evezlik',3,3,'Cümləni tamamlayın: «… sabah teatra gedəcəyik.»','Felin sonluğu (-ik) I şəxsin cəmini göstərir: biz.',array['Biz','Mən','Sən','O'],1),
('az4-evezlik#10','az-dili','az-4-evezlik',3,3,'«Bu» sözü hansı əvəzlikdir?','«Bu, o» yaxındakı və uzaqdakı əşyaya işarə edir — işarə əvəzliyidir.',array['İşarə əvəzliyi','Şəxs əvəzliyi','Sual əvəzliyi','Əvəzlik deyil'],1),
('az4-cumle-uzvleri#1','az-dili','az-4-cumle-uzvleri',1,3,'Hansı üzvlər cümlənin əsasını təşkil edir?','Cümlənin baş üzvləri mübtəda və xəbərdir.',array['Mübtəda və xəbər','İsim və fel','Söz və heca','Sual və nida'],1),
('az4-cumle-uzvleri#2','az-dili','az-4-cumle-uzvleri',2,3,'Mübtəda hansı suallara cavab verir?','Mübtəda «kim? nə?» suallarına cavab verir.',array['Kim? Nə?','Nə edir?','Harada?','Necə?'],1),
('az4-cumle-uzvleri#3','az-dili','az-4-cumle-uzvleri',2,3,'«Uşaqlar həyətdə oynayırlar» cümləsində mübtəda hansıdır?','Oynayan kimdir? — Uşaqlar.',array['Uşaqlar','həyətdə','oynayırlar','cümlədə mübtəda yoxdur'],1),
('az4-cumle-uzvleri#4','az-dili','az-4-cumle-uzvleri',2,3,'«Külək şiddətlə əsir» cümləsində xəbər hansıdır?','Külək nə edir? — Əsir.',array['əsir','Külək','şiddətlə','cümlədə xəbər yoxdur'],1),
('az4-cumle-uzvleri#5','az-dili','az-4-cumle-uzvleri',2,3,'Xəbər adətən cümlənin harasında durur?','Azərbaycan dilində xəbər adətən cümlənin sonunda gəlir.',array['Sonunda','Əvvəlində','Ortasında','İstənilən yerdə qaydasızdır'],1),
('az4-cumle-uzvleri#6','az-dili','az-4-cumle-uzvleri',2,3,'«Aysu maraqlı kitab oxuyur» cümləsində mübtəda hansıdır?','Oxuyan kimdir? — Aysu.',array['Aysu','maraqlı','kitab','oxuyur'],1),
('az4-cumle-uzvleri#7','az-dili','az-4-cumle-uzvleri',2,3,'«Qar yağır» cümləsində «yağır» sözü hansı üzvdür?','Qar nə edir? — yağır: xəbərdir.',array['Xəbər','Mübtəda','Üzv deyil','Başlıq'],1),
('az4-cumle-uzvleri#8','az-dili','az-4-cumle-uzvleri',2,3,'Xəbər hansı suala cavab verir?','Xəbər «nə edir? nə etdi? nə edəcək?» suallarına cavab verir.',array['Nə edir?','Kim?','Hansı?','Neçə?'],1),
('az4-cumle-uzvleri#9','az-dili','az-4-cumle-uzvleri',3,3,'Hansı cümlədə mübtəda ayrıca sözlə ifadə olunmayıb?','«(Mən) dərsə gedirəm» — şəxs sonluğu mübtədanı əvəz edir.',array['Dərsə gedirəm.','Aysu şəkil çəkir.','Quşlar uçur.','Müəllim danışır.'],1),
('az4-cumle-uzvleri#10','az-dili','az-4-cumle-uzvleri',3,3,'«Şagirdlər müəllimi diqqətlə dinləyirdilər» cümləsində mübtəda hansıdır?','Dinləyən kimdir? — Şagirdlər.',array['Şagirdlər','müəllimi','diqqətlə','dinləyirdilər'],1),
('az4-durgu#1','az-dili','az-4-durgu',1,4,'Nəqli cümlənin sonunda hansı işarə qoyulur?','Nəqli cümlə adi məlumat bildirir, sonunda nöqtə qoyulur.',array['Nöqtə','Sual işarəsi','Nida işarəsi','Vergül'],1),
('az4-durgu#2','az-dili','az-4-durgu',1,4,'Sual cümləsinin sonunda hansı işarə qoyulur?','Sual bildirən cümlənin sonunda sual işarəsi qoyulur.',array['Sual işarəsi','Nöqtə','Nida işarəsi','Tire'],1),
('az4-durgu#3','az-dili','az-4-durgu',2,4,'Hansı cümlənin sonunda nida işarəsi qoyulmalıdır?','Hiss-həyəcan bildirən cümlənin sonunda nida işarəsi qoyulur.',array['Nə gözəl mənzərədir','Sən hara gedirsən','Mən kitab oxuyuram','Sabah hava necə olacaq'],1),
('az4-durgu#4','az-dili','az-4-durgu',2,4,'Sadalanan üzvlər arasında hansı işarə qoyulur?','Sadalanan sözlər vergüllə ayrılır.',array['Vergül işarəsi','Nöqtə','Tire','Sual işarəsi'],1),
('az4-durgu#5','az-dili','az-4-durgu',2,4,'«Bakı(?) Gəncə və Şəki qədim şəhərlərdir» — mötərizənin yerinə hansı işarə qoyulmalıdır?','Sadalanan sözlər arasında vergül qoyulur: Bakı, Gəncə və Şəki.',array['Vergül','Nöqtə','Nida işarəsi','Heç nə'],1),
('az4-durgu#6','az-dili','az-4-durgu',3,4,'«Aysu(?) bura gəl!» — xitabdan sonra hansı işarə qoyulmalıdır?','Xitab cümlə üzvlərindən vergüllə ayrılır.',array['Vergül','Nöqtə','Sual işarəsi','Heç nə'],1),
('az4-durgu#7','az-dili','az-4-durgu',3,4,'Dialoqda replikaların əvvəlində hansı işarə qoyulur?','Hər danışanın sözü yeni sətirdən tire ilə başlanır.',array['Tire','Vergül','Nöqtə','Nida işarəsi'],1),
('az4-durgu#8','az-dili','az-4-durgu',2,4,'Hansı cümlənin sonunda sual işarəsi qoyulmalıdır?','«Dərslər neçədə başlayır» — sual bildirir.',array['Dərslər neçədə başlayır','Dərslər doqquzda başlayır','Məktəbimiz böyükdür','Yaz gəldi'],1),
('az4-durgu#9','az-dili','az-4-durgu',3,4,'Hansı cümlədə vergül düzgün qoyulub?','Xitab («əziz dostum») vergüllə ayrılır.',array['Salam, əziz dostum!','Salam əziz, dostum!','Sa,lam əziz dostum!','Salam əziz dostum,!'],1),
('az4-durgu#10','az-dili','az-4-durgu',2,4,'«Sən sabah gələcəksənmi(?)» — cümlənin sonunda hansı işarə qoyulmalıdır?','-mi ədatı cümləni sual cümləsi edir.',array['Sual işarəsi','Nöqtə','Vergül','Tire'],1),
('az4-insa#1','az-dili','az-4-insa',1,4,'İnşa yazmağa nədən başlamaq lazımdır?','Əvvəlcə plan qurulur, sonra hissə-hissə yazılır.',array['Plan qurmaqdan','Nəticədən','Şəkil çəkməkdən','Başlıqsız yazmaqdan'],1),
('az4-insa#2','az-dili','az-4-insa',1,4,'Cümlə hansı hərflə başlanır?','Hər cümlə böyük hərflə başlanır.',array['Böyük hərflə','Kiçik hərflə','İstənilən hərflə','Rəqəmlə'],1),
('az4-insa#3','az-dili','az-4-insa',1,4,'Hər yerdə böyük hərflə yazılan söz hansıdır?','Xüsusi isimlər — şəhər, insan, çay adları — böyük hərflə yazılır.',array['Bakı','kitab','məktəb','ağac'],1),
('az4-insa#4','az-dili','az-4-insa',2,4,'Sözü sətirdən sətrə necə keçirirlər?','Söz sətirdən sətrə hecalarla keçirilir.',array['Hecalarla','Hərflərlə','İstənilən yerdən','Sözü keçirmək olmaz'],1),
('az4-insa#5','az-dili','az-4-insa',2,4,'«Məktəblilər» sözündə neçə heca var?','Sözdə neçə sait varsa, o qədər heca var: mək-təb-li-lər.',array['4','3','5','2'],1),
('az4-insa#6','az-dili','az-4-insa',2,4,'Sətirdən sətrə keçirilə bilməyən söz hansıdır?','Birhecalı sözlər sətirdən sətrə keçirilmir.',array['dağ','kitab','dəftər','məktəb'],1),
('az4-insa#7','az-dili','az-4-insa',2,4,'«Qaranquş» sözündə neçə sait var?','Saitlər: a, a, u — üç sait, deməli üç heca.',array['3','2','4','5'],1),
('az4-insa#8','az-dili','az-4-insa',2,4,'Məktuba adətən necə başlayırlar?','Məktub müraciətlə başlanır: «Əziz ana!»',array['Müraciətlə: «Əziz ana!»','Nəticə ilə','İmza ilə','Tarixsiz və adsız'],1),
('az4-insa#9','az-dili','az-4-insa',2,4,'İnşanın sonunda nə yazılır?','Sonda yekun fikir — nəticə verilir.',array['Nəticə — yekun fikir','Yeni mövzu','Sual siyahısı','Lüğət'],1),
('az4-insa#10','az-dili','az-4-insa',3,4,'«Kitabxana» sözü neçə hecadan ibarətdir?','Ki-tab-xa-na: dörd heca.',array['4','3','5','2'],1),
('hey4-canli-heyat#1','hayat-bilgisi','hey-4-canli-heyat',1,1,'Canlıları cansızlardan fərqləndirən əsas əlamət hansıdır?','Canlılar qidalanır, böyüyür, çoxalır və tənəffüs edir.',array['Böyüməsi və çoxalması','Yerində durması','Rənginin olması','Formasının olması'],1),
('hey4-canli-heyat#2','hayat-bilgisi','hey-4-canli-heyat',2,1,'Bitkilər qidasını əsasən harada hazırlayır?','Bitkilər günəş işığının köməyi ilə yarpaqlarında qida hazırlayır.',array['Yarpaqlarında','Köklərində saxlanan daşlarda','Torpağın altında hazır alır','Başqa bitkilərdən alır'],1),
('hey4-canli-heyat#3','hayat-bilgisi','hey-4-canli-heyat',3,1,'Hansı canlı məməlidir?','Delfin balalarını süd ilə bəsləyir — məməlidir.',array['Delfin','Qartal','İlan','Sazan balığı'],1),
('hey4-canli-heyat#4','hayat-bilgisi','hey-4-canli-heyat',2,1,'Toxumun cücərməsi üçün nə lazımdır?','Su, hava və istilik olmasa, toxum cücərməz.',array['Su, hava və istilik','Yalnız qaranlıq','Yalnız külək','Heç nə lazım deyil'],1),
('hey4-canli-heyat#5','hayat-bilgisi','hey-4-canli-heyat',2,1,'Hansı sırada yalnız canlılar verilib?','Göbələk, qarışqa və palıd canlıdır; daş və su cansızdır.',array['göbələk, qarışqa, palıd','daş, qarışqa, palıd','göbələk, su, daş','qum, daş, bulud'],1),
('hey4-canli-heyat#6','hayat-bilgisi','hey-4-canli-heyat',3,1,'Quşları başqa canlılardan fərqləndirən əlamət hansıdır?','Bütün quşların bədəni lələklə örtülüdür; uçmaq hamısına aid deyil.',array['Bədənlərinin lələklə örtülməsi','Uçmaları','Suda üzmələri','Yumurtadan çıxmaları'],1),
('hey4-canli-heyat#7','hayat-bilgisi','hey-4-canli-heyat',1,1,'Bitkinin hansı hissəsi onu torpağa bağlayır?','Kök bitkini torpağa bağlayır, su və mineralları çəkir.',array['Kök','Yarpaq','Çiçək','Meyvə'],1),
('hey4-canli-heyat#8','hayat-bilgisi','hey-4-canli-heyat',2,1,'Canlıların tənəffüsü üçün hansı qaz vacibdir?','Canlılar oksigenlə tənəffüs edir.',array['Oksigen','Karbon qazı','Hidrogen','Tüstü'],1),
('hey4-canli-heyat#9','hayat-bilgisi','hey-4-canli-heyat',2,1,'Hansı heyvan qış yuxusuna gedir?','Ayı qışda yuxuya gedir, yazda oyanır.',array['Ayı','Canavar','Tülkü','Dovşan'],1),
('hey4-canli-heyat#10','hayat-bilgisi','hey-4-canli-heyat',3,1,'Meyvə bitkinin hansı hissəsindən əmələ gəlir?','Çiçək tozlanandan sonra onun yerində meyvə əmələ gəlir.',array['Çiçəkdən','Kökdən','Yarpaqdan','Gövdədən'],1),
('hey4-ferd-aile#1','hayat-bilgisi','hey-4-ferd-aile',1,1,'Ailə üzvləri bir-birinə necə davranmalıdır?','Ailənin təməli qarşılıqlı hörmət və qayğıdır.',array['Hörmət və qayğı ilə','Biganə','Yalnız bayramlarda mehriban','Kobud'],1),
('hey4-ferd-aile#2','hayat-bilgisi','hey-4-ferd-aile',2,1,'Cəmiyyət nədir?','Bir yerdə yaşayıb bir-biri ilə əlaqədə olan insanlar cəmiyyət qurur.',array['Birlikdə yaşayan insanların birliyi','Binaların cəmi','Bir ailənin adı','Yalnız bir sinifin şagirdləri'],1),
('hey4-ferd-aile#3','hayat-bilgisi','hey-4-ferd-aile',1,1,'Şagirdin məktəbdəki əsas vəzifəsi nədir?','Oxumaq, öyrənmək və məktəb qaydalarına əməl etmək.',array['Oxumaq və qaydalara əməl etmək','Yalnız oynamaq','Dərsdən qaçmaq','Başqalarına mane olmaq'],1),
('hey4-ferd-aile#4','hayat-bilgisi','hey-4-ferd-aile',1,1,'Böyüklərlə rastlaşanda necə davranmaq düzgündür?','Nəzakətlə salamlaşmaq hörmətin əlamətidir.',array['Nəzakətlə salam vermək','Görməzlikdən gəlmək','Ucadan qışqırmaq','Yolunu kəsmək'],1),
('hey4-ferd-aile#5','hayat-bilgisi','hey-4-ferd-aile',3,1,'Ailə büdcəsi nədir?','Ailənin bütün gəlirləri və xərcləri birlikdə büdcəni təşkil edir.',array['Ailənin gəlir və xərclərinin cəmi','Yalnız uşaqların cib pulu','Mağazadakı qiymətlər','Bankdakı növbə'],1),
('hey4-ferd-aile#6','hayat-bilgisi','hey-4-ferd-aile',2,1,'Hansı davranış düzgündür?','İctimai yerlərdə növbəyə riayət etmək lazımdır.',array['Növbəyə riayət etmək','Növbəsiz keçmək','Ucadan musiqi açmaq','Zibili yerə atmaq'],1),
('hey4-ferd-aile#7','hayat-bilgisi','hey-4-ferd-aile',2,1,'İnsan peşə seçərkən nəyi nəzərə almalıdır?','Peşə bacarıq və maraqlara uyğun seçilməlidir.',array['Bacarıq və maraqlarını','Yalnız adının gözəlliyini','Dostunun seçimini','Təsadüfü'],1),
('hey4-ferd-aile#8','hayat-bilgisi','hey-4-ferd-aile',2,1,'Qonşularla münasibətdə nə vacibdir?','Qonşuluq mehribanlıq və qarşılıqlı yardım üzərində qurulur.',array['Mehribanlıq və qarşılıqlı yardım','Yüksək səslə musiqi','Küsülü qalmaq','Bir-birini tanımamaq'],1),
('hey4-ferd-aile#9','hayat-bilgisi','hey-4-ferd-aile',3,1,'Birgə işdə vəzifələr necə bölünməlidir?','İş ədalətlə, hər kəsin bacarığına görə bölünməlidir.',array['Ədalətlə, bacarığa görə','Hamısı bir nəfərə','Püşksüz və qaydasız','Yalnız böyüklərə'],1),
('hey4-ferd-aile#10','hayat-bilgisi','hey-4-ferd-aile',1,1,'Hansı keyfiyyət insana hörmət qazandırır?','Düz danışan adama etibar edirlər.',array['Düzlük','Yalançılıq','Paxıllıq','Kobudluq'],1),
('hey4-dovlet-huquq#1','hayat-bilgisi','hey-4-dovlet-huquq',1,2,'Azərbaycanın paytaxtı hansı şəhərdir?','Azərbaycan Respublikasının paytaxtı Bakıdır.',array['Bakı','Gəncə','Sumqayıt','Şəki'],1),
('hey4-dovlet-huquq#2','hayat-bilgisi','hey-4-dovlet-huquq',1,2,'Dövlət rəmzləri hansılardır?','Dövlətin üç rəmzi var: bayraq, gerb, himn.',array['Bayraq, gerb, himn','Pul, mahnı, şəkil','Xəritə, kitab, bayraq','Gerb, xalça, çay'],1),
('hey4-dovlet-huquq#3','hayat-bilgisi','hey-4-dovlet-huquq',1,2,'Azərbaycan bayrağında neçə rəng var?','Bayrağımız üçrənglidir.',array['3','2','4','5'],1),
('hey4-dovlet-huquq#4','hayat-bilgisi','hey-4-dovlet-huquq',2,2,'Bayrağımızın zolaqları yuxarıdan aşağı hansı sıra ilə düzülür?','Mavi — türkçülük, qırmızı — müasirlik, yaşıl — islam mədəniyyəti.',array['Mavi, qırmızı, yaşıl','Qırmızı, mavi, yaşıl','Yaşıl, qırmızı, mavi','Mavi, yaşıl, qırmızı'],1),
('hey4-dovlet-huquq#5','hayat-bilgisi','hey-4-dovlet-huquq',2,2,'Azərbaycan Respublikasının əsas qanunu necə adlanır?','Dövlətin əsas qanunu Konstitusiyadır.',array['Konstitusiya','Himn','Nizamnamə','Lüğət'],1),
('hey4-dovlet-huquq#6','hayat-bilgisi','hey-4-dovlet-huquq',3,2,'Bayrağımızın üzərindəki aypara və səkkizguşəli ulduz hansı rəngdədir?','Qırmızı zolağın üzərində ağ aypara və ulduz təsvir olunub.',array['Ağ','Sarı','Qara','Mavi'],1),
('hey4-dovlet-huquq#7','hayat-bilgisi','hey-4-dovlet-huquq',2,2,'8 Noyabr hansı bayramdır?','8 Noyabr — Zəfər Günüdür.',array['Zəfər Günü','Novruz bayramı','Bilik Günü','Yeni il'],1),
('hey4-dovlet-huquq#8','hayat-bilgisi','hey-4-dovlet-huquq',2,2,'Dövlət himni səslənəndə necə davranmaq lazımdır?','Himnə hörmət əlaməti olaraq ayağa qalxırlar.',array['Ayağa qalxmaq','Oturub danışmaq','Gülmək','Otaqdan çıxmaq'],1),
('hey4-dovlet-huquq#9','hayat-bilgisi','hey-4-dovlet-huquq',1,2,'Azərbaycanın dövlət dili hansıdır?','Dövlət dilimiz Azərbaycan dilidir.',array['Azərbaycan dili','İngilis dili','Rus dili','Türk dili'],1),
('hey4-dovlet-huquq#10','hayat-bilgisi','hey-4-dovlet-huquq',2,2,'Vətəndaşın əsas borcu nədir?','Vətəni sevmək, qorumaq və qanunlara əməl etmək hər kəsin borcudur.',array['Vətəni qorumaq və qanunlara əməl etmək','Yalnız istirahət etmək','Qanunları pozmaq','Heç nə etməmək'],1),
('hey4-saglamliq-teh#1','hayat-bilgisi','hey-4-saglamliq-teh',1,3,'Gündə neçə dəfə diş fırçalamaq məsləhətdir?','Səhər və axşam — gündə 2 dəfə.',array['2 dəfə','Həftədə 1 dəfə','Ayda 1 dəfə','Heç fırçalamamaq'],1),
('hey4-saglamliq-teh#2','hayat-bilgisi','hey-4-saglamliq-teh',1,3,'Yeməkdən əvvəl nə etmək vacibdir?','Əlləri sabunla yumaq mikroblardan qoruyur.',array['Əlləri yumaq','Qaçmaq','Yatmaq','Televizora baxmaq'],1),
('hey4-saglamliq-teh#3','hayat-bilgisi','hey-4-saglamliq-teh',1,3,'Piyadalar yolu haradan keçməlidir?','Yol yalnız piyada keçidindən keçilir.',array['Piyada keçidindən','İstənilən yerdən','Maşınların arasından','Qaçaraq istənilən yerdən'],1),
('hey4-saglamliq-teh#4','hayat-bilgisi','hey-4-saglamliq-teh',1,3,'Svetoforun hansı işığında yolu keçmək olar?','Yaşıl işıq piyadaya yol verir.',array['Yaşıl','Qırmızı','Sarı','İstənilən'],1),
('hey4-saglamliq-teh#5','hayat-bilgisi','hey-4-saglamliq-teh',2,3,'Yanğın və digər fövqəladə hal zamanı hansı nömrəyə zəng edilməlidir?','112 — fövqəladə hallar üçün vahid çağırış nömrəsidir.',array['112','103','999','555'],1),
('hey4-saglamliq-teh#6','hayat-bilgisi','hey-4-saglamliq-teh',2,3,'Evdə tək olanda tanımadığın adam qapını döysə, nə etməlisən?','Qapını açmamaq və böyüklərə xəbər vermək lazımdır.',array['Qapını açmamaq, böyüklərə xəbər vermək','Dərhal qapını açmaq','Qapını açıb kim olduğunu soruşmaq','Qonaq çağırmaq'],1),
('hey4-saglamliq-teh#7','hayat-bilgisi','hey-4-saglamliq-teh',2,3,'Sağlam qidalanma üçün nə vacibdir?','Meyvə-tərəvəz vitaminlərlə zəngindir.',array['Meyvə-tərəvəz yemək','Yalnız şirniyyat yemək','Gündə bir dəfə çips yemək','Yalnız sərinləşdirici içmək'],1),
('hey4-saglamliq-teh#8','hayat-bilgisi','hey-4-saglamliq-teh',2,3,'Elektrik cihazları ilə davranarkən nə etmək olmaz?','Yaş əllə elektrik cihazına toxunmaq təhlükəlidir.',array['Yaş əllə toxunmaq','Böyüklə birlikdə işlətmək','İşlətdikdən sonra söndürmək','Təlimata baxmaq'],1),
('hey4-saglamliq-teh#9','hayat-bilgisi','hey-4-saglamliq-teh',3,3,'Kiçik məktəbli gecə təxminən neçə saat yatmalıdır?','Bu yaşda 9-10 saat yuxu məsləhət görülür.',array['9-10 saat','4-5 saat','2-3 saat','15-16 saat'],1),
('hey4-saglamliq-teh#10','hayat-bilgisi','hey-4-saglamliq-teh',2,3,'Velosiped sürərkən başa nə taxmaq lazımdır?','Dəbilqə yıxılanda başı zədədən qoruyur.',array['Dəbilqə','Panama','Heç nə','Qulaqlıq'],1),
('hey4-hereket-enerji#1','hayat-bilgisi','hey-4-hereket-enerji',1,4,'Günəş bizə nə verir?','Günəş Yerə işıq və istilik verir.',array['İşıq və istilik','Yalnız kölgə','Külək','Yağış'],1),
('hey4-hereket-enerji#2','hayat-bilgisi','hey-4-hereket-enerji',2,4,'Hansı cisim öz işığını yayır?','Günəş işıq mənbəyidir; Ay yalnız onun işığını əks etdirir.',array['Günəş','Ay','Güzgü','Pəncərə'],1),
('hey4-hereket-enerji#3','hayat-bilgisi','hey-4-hereket-enerji',1,4,'Enerjiyə qənaət üçün nə etməliyik?','İstifadə olunmayan işıqları söndürmək enerjiyə qənaətdir.',array['İşlətmədiyimiz işığı söndürmək','Bütün lampaları yandırmaq','Suyu açıq qoymaq','Televizoru söndürməmək'],1),
('hey4-hereket-enerji#4','hayat-bilgisi','hey-4-hereket-enerji',2,4,'Külək enerjisindən nə üçün istifadə olunur?','Külək turbinləri elektrik enerjisi istehsal edir.',array['Elektrik almaq üçün','Yağış yağdırmaq üçün','Torpağı qızdırmaq üçün','Səs yaratmaq üçün'],1),
('hey4-hereket-enerji#5','hayat-bilgisi','hey-4-hereket-enerji',1,4,'Hərəkət etmək üçün canlılara nə lazımdır?','Canlılar hərəkət üçün enerji sərf edir.',array['Enerji','Kölgə','Səs','Rəng'],1),
('hey4-hereket-enerji#6','hayat-bilgisi','hey-4-hereket-enerji',2,4,'Canlılar enerjini haradan alır?','Canlıların enerji mənbəyi qidadır.',array['Qidadan','Daşdan','Səsdən','Kölgədən'],1),
('hey4-hereket-enerji#7','hayat-bilgisi','hey-4-hereket-enerji',2,4,'Hansı yanacaq təbii sərvətdir?','Neft yerin təkindən çıxarılan təbii sərvətdir.',array['Neft','Plastik','Şüşə','Kağız'],1),
('hey4-hereket-enerji#8','hayat-bilgisi','hey-4-hereket-enerji',2,4,'Su qızdırıldıqda hansı hala keçir?','Qaynayan su buxarlanır — qaz halına keçir.',array['Buxara çevrilir','Buza çevrilir','Daşlaşır','Dəyişmir'],1),
('hey4-hereket-enerji#9','hayat-bilgisi','hey-4-hereket-enerji',2,4,'Maqnit hansı əşyaları özünə çəkir?','Maqnit dəmirdən olan əşyaları cəzb edir.',array['Dəmir əşyaları','Taxta əşyaları','Plastik əşyaları','Kağız əşyaları'],1),
('hey4-hereket-enerji#10','hayat-bilgisi','hey-4-hereket-enerji',3,4,'Hansı cisim işıq mənbəyi deyil?','Ay öz işığını yaymır, Günəş işığını əks etdirir.',array['Ay','Günəş','Yanan şam','Elektrik lampası'],1),
('inf4-informasiya#1','informatika','inf-4-informasiya',1,1,'İnformasiya nədir?','Ətraf aləmdən aldığımız məlumatlar informasiyadır.',array['Ətraf aləmdən alınan məlumat','Yalnız kitab','Yalnız rəqəmlər','Kompüterin adı'],1),
('inf4-informasiya#2','informatika','inf-4-informasiya',2,1,'İnsan informasiyanın çoxunu hansı orqanla alır?','İnformasiyanın böyük hissəsini görmə ilə alırıq.',array['Gözlə','Qulaqla','Burunla','Əllə'],1),
('inf4-informasiya#3','informatika','inf-4-informasiya',2,1,'Zəng səsi hansı informasiya növüdür?','Qulaqla qəbul edilən informasiya səs informasiyasıdır.',array['Səs','Qrafik','Mətn','Ədədi'],1),
('inf4-informasiya#4','informatika','inf-4-informasiya',1,1,'Kitabdakı yazı hansı informasiya formasıdır?','Hərflərlə yazılmış məlumat mətn informasiyasıdır.',array['Mətn','Səs','Video','Qoxu'],1),
('inf4-informasiya#5','informatika','inf-4-informasiya',2,1,'Svetofor informasiyanı necə ötürür?','Svetofor rəngli işıq siqnalları ilə məlumat verir.',array['İşıq siqnalları ilə','Səslə','Yazı ilə','Qoxu ilə'],1),
('inf4-informasiya#6','informatika','inf-4-informasiya',2,1,'İnformasiyanı saxlamaq üçün nədən istifadə olunur?','Kitab, disk, fləş kart informasiya daşıyıcılarıdır.',array['İnformasiya daşıyıcılarından','Güzgüdən','Şüşədən','Sudan'],1),
('inf4-informasiya#7','informatika','inf-4-informasiya',2,1,'Hansı sırada yalnız informasiya daşıyıcıları verilib?','Hamısı üzərində məlumat saxlanan vasitələrdir.',array['kitab, disk, fləş kart','kitab, stol, stul','disk, qələm, çanta','telefon, alma, dəftər'],1),
('inf4-informasiya#8','informatika','inf-4-informasiya',2,1,'Şəkil hansı informasiya formasına aiddir?','Şəkil və sxemlər qrafik informasiyadır.',array['Qrafik','Səs','Mətn','Ədədi'],1),
('inf4-informasiya#9','informatika','inf-4-informasiya',2,1,'İnformasiyanı uzağa ötürmək üçün hansı vasitədən istifadə olunur?','Telefonla informasiya məsafəyə ötürülür.',array['Telefon','Güzgü','Qayçı','Xətkeş'],1),
('inf4-informasiya#10','informatika','inf-4-informasiya',3,1,'Hansı iş informasiyanın emalıdır?','Misalı həll edəndə verilən informasiyadan yeni nəticə alınır.',array['Misalı həll etmək','Kitabı rəfə qoymaq','Dəftəri cırmaq','Çantanı bağlamaq'],1),
('inf4-alqoritm#1','informatika','inf-4-alqoritm',1,2,'Alqoritm nədir?','Məqsədə çatmaq üçün addımların ardıcıl icra qaydasıdır.',array['Addımların ardıcıl icra qaydası','Kompüter oyunu','Şəkil çəkmə proqramı','Riyazi düstur'],1),
('inf4-alqoritm#2','informatika','inf-4-alqoritm',1,2,'Alqoritmin addımları necə yerinə yetirilməlidir?','Addımlar verilmiş ardıcıllıqla icra olunur.',array['Ardıcıllıqla','Sondan əvvələ','Qarışıq','İstəyə görə atlanaraq'],1),
('inf4-alqoritm#3','informatika','inf-4-alqoritm',2,2,'Çay dəmləmə alqoritmində birinci addım hansıdır?','Əvvəlcə çaydana su tökülür — susuz qaynatmaq olmaz.',array['Çaydana su tökmək','Çayı süzmək','Stəkanı yumaq','Çaya şəkər atmaq'],1),
('inf4-alqoritm#4','informatika','inf-4-alqoritm',2,2,'Alqoritmi yerinə yetirən qurğu və ya canlı necə adlanır?','Alqoritmi icra edən — icraçıdır (insan, robot, kompüter).',array['İcraçı','Müəllif','Tamaşaçı','Rəssam'],1),
('inf4-alqoritm#5','informatika','inf-4-alqoritm',2,2,'Hansı ardıcıllıq düzgün alqoritmdir?','Əvvəl əllər yuyulur, sonra qurulanır.',array['1. Əlini yu. 2. Dəsmalla qurula.','1. Dəsmalla qurula. 2. Əlini yu.','1. Yat. 2. Əlini yu.','1. Qurula. 2. Qurula.'],1),
('inf4-alqoritm#6','informatika','inf-4-alqoritm',2,2,'Alqoritmdə addımların yeri dəyişdirilsə, nə baş verə bilər?','Ardıcıllıq pozulsa, nəticə səhv alınar.',array['Nəticə səhv ola bilər','Heç nə dəyişməz','Alqoritm sürətlənər','Nəticə həmişə yaxşılaşar'],1),
('inf4-alqoritm#7','informatika','inf-4-alqoritm',3,2,'«Səhər durmaq → geyinmək → ? → məktəbə getmək» — buraxılmış addım hansı ola bilər?','Məktəbə getməzdən əvvəl səhər yeməyi yeyilir.',array['Səhər yeməyi yemək','Axşam yatmaq','Məktəbdən qayıtmaq','Gecə filmə baxmaq'],1),
('inf4-alqoritm#8','informatika','inf-4-alqoritm',3,2,'Eyni addımların dəfələrlə yerinə yetirildiyi alqoritm necə adlanır?','Təkrarlanan addımlı alqoritm dövri alqoritmdir.',array['Dövri (təkrarlanan)','Xətti','Səhv','Yarımçıq'],1),
('inf4-alqoritm#9','informatika','inf-4-alqoritm',2,2,'Robot icraçıya göstərişlər hansı formada verilir?','İcraçı yalnız ona tanış əmrləri başa düşür.',array['Əmrlərlə','Baxışla','Mahnı ilə','Şəkillə'],1),
('inf4-alqoritm#10','informatika','inf-4-alqoritm',2,2,'Alqoritm nə ilə bitməlidir?','Düzgün alqoritm nəticə ilə tamamlanır.',array['Nəticə ilə','Sualla','Fasilə ilə','Bitməməlidir'],1),
('inf4-kompyuter#1','informatika','inf-4-kompyuter',2,3,'Kompüterin «beyni» adlanan qurğu hansıdır?','Prosessor bütün hesablamaları yerinə yetirir.',array['Prosessor','Monitor','Klaviatura','Printer'],1),
('inf4-kompyuter#2','informatika','inf-4-kompyuter',1,3,'Mətn yığmaq üçün hansı qurğudan istifadə olunur?','Hərflər klaviatura ilə yığılır.',array['Klaviatura','Monitor','Dinamik','Printer'],1),
('inf4-kompyuter#3','informatika','inf-4-kompyuter',1,3,'Monitor nə üçündür?','Monitor informasiyanı ekranda göstərir.',array['İnformasiyanı ekranda göstərmək','Mətni çap etmək','Səs yazmaq','İnternetə qoşulmaq'],1),
('inf4-kompyuter#4','informatika','inf-4-kompyuter',2,3,'Siçanın (mausun) əsas vəzifəsi nədir?','Maus ekrandakı obyektləri seçib idarə etməyə xidmət edir.',array['Ekrandakı obyektləri seçmək və idarə etmək','Mətni çap etmək','Səsi ucaltmaq','Şəkil çəkmək üçün rəng qarışdırmaq'],1),
('inf4-kompyuter#5','informatika','inf-4-kompyuter',1,3,'Sənədi kağıza çap etmək üçün hansı qurğu lazımdır?','Printer məlumatı kağıza çap edir.',array['Printer','Skaner','Dinamik','Mikrofon'],1),
('inf4-kompyuter#6','informatika','inf-4-kompyuter',2,3,'İnformasiya kompüterdə harada saxlanılır?','Məlumatlar kompüterin yaddaşında saxlanılır.',array['Yaddaşda','Monitorda','Klaviaturada','Mausda'],1),
('inf4-kompyuter#7','informatika','inf-4-kompyuter',2,3,'Səsi eşitdirmək üçün hansı qurğudan istifadə olunur?','Dinamik (səsucaldan) səsi çıxarır.',array['Dinamik','Mikrofon','Skaner','Printer'],1),
('inf4-kompyuter#8','informatika','inf-4-kompyuter',2,3,'Şəkil çəkmək üçün hansı qrafik proqram işlədilir?','Qrafik redaktorda (məsələn, Paint) şəkil çəkilir.',array['Qrafik redaktor (Paint)','Kalkulyator','Saat','Musiqi pleyeri'],1),
('inf4-kompyuter#9','informatika','inf-4-kompyuter',2,3,'Kompüterlə iş qurtaranda nə etmək lazımdır?','Kompüter qaydasında söndürülməlidir.',array['Onu düzgün söndürmək','Elektrik şnurunu dartmaq','Ekranı örtüb getmək','Su ilə silmək'],1),
('inf4-kompyuter#10','informatika','inf-4-kompyuter',2,3,'Kompüter arxasında uzun müddət oturmaq nəyə zərər verir?','Fasiləsiz iş gözləri yorur, qaməti pozur.',array['Gözlərə və qamətə','Heç nəyə','Yalnız ayaqqabıya','Yalnız kompüterə'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = d.fenn
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = '4'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, quarter = excluded.quarter,
        topic_id = excluded.topic_id, level_id = excluded.level_id,
        subject_id = excluded.subject_id, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(d.opts) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform'
     and (ext_key like 'az4-%' or ext_key like 'hey4-%'
          or ext_key like 'inf4-%');
  if n <> 160 then
    raise exception 'sinif4 suallari: 160 gozlenilirdi, % tapildi', n;
  end if;

  select count(*) into k from public.questions q
   where (q.ext_key like 'az4-%' or q.ext_key like 'hey4-%'
          or q.ext_key like 'inf4-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;

  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az4-%' or ext_key like 'hey4-%'
      or ext_key like 'inf4-%';
  if k <> 16 then
    raise exception 'movzu sayi 16 deyil: %', k;
  end if;

  raise notice '4-cu sinif banki: % sual, 16 movzu (az dili, heyat bilgisi, informatika).', n;
end $$;
