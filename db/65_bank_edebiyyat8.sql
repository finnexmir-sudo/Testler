-- =====================================================================
--  65_bank_edebiyyat8.sql : EDEBIYYAT 8 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat8.py yaradir:
--      python3 tools/edebiyyat8.py
--
--  7 movzu x 31 sual = 217.  Her movzuda 4 asan + 15 orta + 12 cetin.
--  ext_key: edeb11-...
--  ON SERT: 61_movzular_edebiyyat5_8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'edebiyyat' and t.slug in
           ('edeb-8-qedim', 'edeb-8-romantizm')
     having count(*) = 2) then
    raise exception 'ONCE 61_movzular_edebiyyat5_8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb8-%';

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('edeb8-qedim#1','edebiyyat','edeb-8-qedim',1,1,'«Qazan bəyin oğlu Uruz bəyin dustaq olduğu boy» hansı abidədəndir?','Bu boy «Kitabi-Dədə Qorqud» dastanındandır.',array['«Kitabi-Dədə Qorqud»','«Koroğlu»','«Şahnamə»','«Xəmsə»'],1),
('edeb8-qedim#2','edebiyyat','edeb-8-qedim',1,1,'Uruz bəy kimin oğludur?','Uruz Qazan xanın oğludur.',array['Qazan xanın','Bayandır xanın','Dirsə xanın','Alı kişinin'],1),
('edeb8-qedim#3','edebiyyat','edeb-8-qedim',1,1,'«Kitabi-Dədə Qorqud» hansı ədəbi növə aiddir?','Dastan epik növə aiddir.',array['Epik növə','Lirik növə','Dram növünə','Publisistikaya'],1),
('edeb8-qedim#4','edebiyyat','edeb-8-qedim',1,1,'«Kitabi-Dədə Qorqud» dastanının hər bir hissəsi necə adlanır?','Dastanın hissələri boy adlanır.',array['Boy','Qol','Bənd','Pərdə'],1),
('edeb8-qedim#5','edebiyyat','edeb-8-qedim',2,1,'Uruz bəy bu boyda hansı vəziyyətə düşür?','O, düşmənə əsir düşür.',array['Düşmənə əsir düşür','Uzaq ticarətə çıxır','Xəzinə tapır','Toy məclisi qurur'],1),
('edeb8-qedim#6','edebiyyat','edeb-8-qedim',2,1,'Uruzu əsirlikdən qurtarmaq üçün kim yola çıxır?','Atası Qazan xan oğuz bəyləri ilə yola çıxır.',array['Atası Qazan xan','Dədə Qorqud','Bayandır xan','Qaraca Çoban'],1),
('edeb8-qedim#7','edebiyyat','edeb-8-qedim',2,1,'Bu boyda Uruzun anasının adı nədir?','Uruzun anası Burla xatundur.',array['Burla xatun','Banuçiçək','Selcan xatun','Nigar xanım'],1),
('edeb8-qedim#8','edebiyyat','edeb-8-qedim',2,1,'Bu boyun əsas mövzusu nədir?','Ata-oğul məhəbbəti və el uğrunda qəhrəmanlıqdır.',array['Ata-oğul məhəbbəti və qəhrəmanlıq','Ticarət səfəri','Elm öyrənmək yolu','Toy adətləri'],1),
('edeb8-qedim#9','edebiyyat','edeb-8-qedim',2,1,'«Qazılıq Qoca oğlu Yeynək boyu»nun qəhrəmanı kimdir?','Bu boyun qəhrəmanı Yeynəkdir.',array['Yeynək','Basat','Beyrək','Uruz'],1),
('edeb8-qedim#10','edebiyyat','edeb-8-qedim',2,1,'Dastanda oğuz igidlərinin qarşı tərəfi kimlər kimi verilir?','Onların qarşısında kafir hökmdarlar dayanır.',array['Kafir hökmdarlar','Yerli tacirlər','Qonşu çobanlar','Saray şairləri'],1),
('edeb8-qedim#11','edebiyyat','edeb-8-qedim',2,1,'Uruz obrazı hansı keyfiyyəti ilə seçilir?','Cəsarəti və ata adına layiq olmaq istəyi ilə seçilir.',array['Cəsarət və ata adına layiq olmaq','Var-dövlət hərisliyi','Səyahət həvəsi','Elmi maraq'],1),
('edeb8-qedim#12','edebiyyat','edeb-8-qedim',2,1,'Dastanın mətnində nəsrlə yanaşı nə verilir?','Nəsrlə yanaşı şeir parçaları verilir.',array['Şeir parçaları','Not yazıları','Cədvəllər','Xəritələr'],1),
('edeb8-qedim#13','edebiyyat','edeb-8-qedim',2,1,'«Kitabi-Dədə Qorqud» hansı türk boyunun həyatını əks etdirir?','Dastan oğuzların həyatını əks etdirir.',array['Oğuzların','Qıpçaqların','Uyğurların','Karluqların'],1),
('edeb8-qedim#14','edebiyyat','edeb-8-qedim',2,1,'Uruzun əsirlikdən qurtarmasında hansı qüvvə həlledici olur?','Oğuz igidlərinin birliyi həlledici olur.',array['Oğuz igidlərinin birliyi','Xarici elçilərin köməyi','Təsadüfi bir hadisə','Ticarət razılaşması'],1),
('edeb8-qedim#15','edebiyyat','edeb-8-qedim',2,1,'Dastanda ad qoymaq hüququ kimə məxsusdur?','Ad qoymaq hüququ Dədə Qorquda məxsusdur.',array['Dədə Qorquda','Bayandır xana','Qazan xana','Burla xatuna'],1),
('edeb8-qedim#16','edebiyyat','edeb-8-qedim',2,1,'Dastanın dili hansı xüsusiyyəti ilə seçilir?','Obrazlı, atalar sözü və deyimlərlə zəngin olması ilə seçilir.',array['Obrazlı və atalar sözü ilə zəngin','Quru elmi dil','Süni tərcümə dili','Rəsmi sənəd dili'],1),
('edeb8-qedim#17','edebiyyat','edeb-8-qedim',2,1,'Epos nə deməkdir?','Xalqın qəhrəmanlıq keçmişini əks etdirən iri epik əsərdir.',array['Qəhrəmanlıq keçmişini əks etdirən iri epik əsər','Dörd misralı kiçik şeir','Səhnə üçün yazılan əsər','Qısa gülməli hekayət'],1),
('edeb8-qedim#18','edebiyyat','edeb-8-qedim',2,1,'Boyların sonunda Dədə Qorqud nə edir?','O, dua edib alqış söyləyir.',array['Dua edib alqış söyləyir','Döyüşə başlayır','Səfərə çıxır','Xəzinə bölüşdürür'],1),
('edeb8-qedim#19','edebiyyat','edeb-8-qedim',2,1,'«Kitabi-Dədə Qorqud» hansı dövrün məhsulu sayılır?','Dastan erkən orta əsrlərin məhsulu sayılır.',array['Erkən orta əsrlərin','XIX əsrin','XVI əsrin','XX əsrin'],1),
('edeb8-qedim#20','edebiyyat','edeb-8-qedim',3,1,'Səkkizinci sinif materialı üzrə «boy - qəhrəman» cütlüyü hansı düzgündür?','Uruz Qazan xanın oğludur, Yeynək isə Qazılıq Qocanın oğludur.',array['Uruz boyu - Qazan xanın oğlu','Yeynək boyu - Qazan xanın oğlu','Uruz boyu - Bayandır xanın oğlu','Yeynək boyu - Dirsə xanın oğlu'],1),
('edeb8-qedim#21','edebiyyat','edeb-8-qedim',3,1,'«Kitabi-Dədə Qorqud» barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Dastan epik növə aiddir, lirik növə deyil.',array['Dastan lirik növə aiddir','«Kitabi-Dədə Qorqud»da Uruz Qazan xanın oğludur','Dastanın hissələri boy adlanır','Ad qoymaq hüququ Dədə Qorquddadır'],1),
('edeb8-qedim#22','edebiyyat','edeb-8-qedim',3,1,'«Kitabi-Dədə Qorqud» ilə «Koroğlu» dastanının quruluşca fərqi nədir?','Birinin hissələri boy, digərininki isə qol adlanır.',array['Birinin hissələri boy, digərininki qol adlanır','Birinin hissələri qol, digərininki boy adlanır','Hər ikisinin hissələri boy adlanır','Hər ikisi bütövlükdə nəzmlə söylənir'],1),
('edeb8-qedim#23','edebiyyat','edeb-8-qedim',3,1,'Boyda Qazan xanın oğlunu özü ilə aparmasının məqsədi nə kimi izah olunur?','O, oğlunu igidliyə və el işinə hazırlamaq istəyir.',array['Oğlunu igidliyə hazırlamaq istəyi','Ticarət yolunu göstərmək istəyi','Xəzinə axtarmaq niyyəti','Qonşu elə qonaq getmək məqsədi'],1),
('edeb8-qedim#24','edebiyyat','edeb-8-qedim',3,1,'Bu boy üzrə «obraz - rol» cütlüklərindən hansı doğrudur?','Burla xatun Uruzun anası, Qazan xan isə atasıdır.',array['Burla xatun - Uruzun anası','Burla xatun - Uruzun bacısı','Dədə Qorqud - Uruzun atası','Qazan xan - Uruzun dayısı'],1),
('edeb8-qedim#25','edebiyyat','edeb-8-qedim',3,1,'Boydakı üç hadisə ardıcıllıqla necə düzülür? (1 - Uruzun xilas edilməsi, 2 - Uruzun əsir düşməsi, 3 - Qazan xanın yola çıxması)','Əvvəlcə Uruz əsir düşür, sonra Qazan yola çıxır, sonda oğul xilas olur.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb8-qedim#26','edebiyyat','edeb-8-qedim',3,1,'Boylar haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','«Yeynək boyu»nun qəhrəmanı Yeynəkdir, Uruz deyil.',array['«Yeynək boyu»nun qəhrəmanı Uruzdur','Uruz boyunda oğul əsir düşür','Dastan oğuzların həyatını əks etdirir','Boylarda şeir parçaları verilir'],1),
('edeb8-qedim#27','edebiyyat','edeb-8-qedim',3,1,'Uruz və Yeynək obrazlarının ortaq cəhəti nədir?','Hər ikisi oğuz igidi, ata adını yaşadan oğul kimi verilir.',array['Hər ikisi oğuz igidi kimi verilir','Hər ikisi düşmən tərəfin obrazıdır','Biri igid, digəri tacir obrazıdır','Hər ikisi qadın obrazı kimi verilir'],1),
('edeb8-qedim#28','edebiyyat','edeb-8-qedim',3,1,'Aşağıdakı «anlayış - tərif» cütlüklərindən hansı düzgündür?','Boy dastanın bir hissəsidir, soylama isə şeir parçasıdır.',array['Boy - dastanın bir hissəsi','Boy - şeirin bir bəndi','Soylama - dastanın bir hissəsi','Epos - dörd misralı şeir'],1),
('edeb8-qedim#29','edebiyyat','edeb-8-qedim',3,1,'Boyda ata ilə oğulun bir yerdə vuruşması nəyi göstərir?','Nəsillərin davamlılığını və elin birliyini göstərir.',array['Nəsillərin davamlılığını, elin birliyini','Ticarət yollarının əhəmiyyətini','Uzaq səfərlərin çətinliyini','Saray mərasimlərinin qaydasını'],1),
('edeb8-qedim#30','edebiyyat','edeb-8-qedim',3,1,'Epik növ ilə lirik növün əsas fərqi nədir?','Epikdə hadisə, lirikada isə duyğu əsasdır.',array['Epikdə hadisə, lirikada duyğu əsasdır','Epikdə duyğu, lirikada hadisə əsasdır','Hər ikisində hadisə əsasdır','Hər ikisi səhnə üçün yazılır'],1),
('edeb8-qedim#31','edebiyyat','edeb-8-qedim',3,1,'Aşağıdakı «əsər - növ» cütlüklərindən hansı doğrudur?','«Kitabi-Dədə Qorqud» qəhrəmanlıq eposudur.',array['«Kitabi-Dədə Qorqud» - qəhrəmanlıq eposu','«Kitabi-Dədə Qorqud» - məhəbbət dastanı','«Sirlər xəzinəsi» - qəhrəmanlıq eposu','«Dəhnamə» - qəhrəmanlıq eposu'],1),
('edeb8-intibah#1','edebiyyat','edeb-8-intibah',1,1,'«Sultan Səncər və qarı» əsərinin müəllifi kimdir?','Bu hekayət Nizami Gəncəvinin qələmindəndir.',array['Nizami Gəncəvi','Xaqani Şirvani','İmadəddin Nəsimi','Məhəmməd Füzuli'],1),
('edeb8-intibah#2','edebiyyat','edeb-8-intibah',1,1,'«Gənclərə nəsihət» əsərinin müəllifi kimdir?','Əsərin müəllifi Xaqani Şirvanidir.',array['Xaqani Şirvani','Nizami Gəncəvi','Molla Pənah Vaqif','Qasım bəy Zakir'],1),
('edeb8-intibah#3','edebiyyat','edeb-8-intibah',1,1,'«Sultan Səncər və qarı» hansı poemadan götürülmüşdür?','Hekayət «Sirlər xəzinəsi» poemasındandır.',array['«Sirlər xəzinəsi»','«Yeddi gözəl»','«Dəhnamə»','«Xəmsə»'],1),
('edeb8-intibah#4','edebiyyat','edeb-8-intibah',1,1,'Xaqani Şirvani hansı şəhərlə bağlıdır?','Şair Şirvanla, Şamaxı mühiti ilə bağlıdır.',array['Şamaxı ilə','Gəncə ilə','Şuşa ilə','Naxçıvan ilə'],1),
('edeb8-intibah#5','edebiyyat','edeb-8-intibah',2,1,'«Sultan Səncər və qarı» hekayətinin əsas ideyası nədir?','Hökmdarın ədalətli olması, zülmün pislənməsi ideyasıdır.',array['Hökmdarın ədalətli olması','Var-dövlət toplamaq','Uzaq səfərə çıxmaq','Ov ənənəsini qorumaq'],1),
('edeb8-intibah#6','edebiyyat','edeb-8-intibah',2,1,'Hekayətdə qarı obrazı kimi təmsil edir?','O, haqsızlığa uğramış sadə xalqı təmsil edir.',array['Haqsızlığa uğramış xalqı','Saray əyanlarını','Xarici tacirləri','Din xadimlərini'],1),
('edeb8-intibah#7','edebiyyat','edeb-8-intibah',2,1,'Qarı Sultan Səncərə nə deyir?','O, hökmdarın ölkəsində ədalətin olmadığını üzünə deyir.',array['Ölkədə ədalətin olmadığını','Yeni vergi tələb etdiyini','Ticarətin genişləndiyini','Ordunun güclü olduğunu'],1),
('edeb8-intibah#8','edebiyyat','edeb-8-intibah',2,1,'Nizami Gəncəvi əsərlərini hansı dildə yazmışdır?','Şair əsərlərini fars dilində yazmışdır.',array['Fars dilində','Ərəb dilində','Yunan dilində','Rus dilində'],1),
('edeb8-intibah#9','edebiyyat','edeb-8-intibah',2,1,'«Gənclərə nəsihət» əsərində şair nəyi tövsiyə edir?','Elm öyrənməyi, kamil insan olmağı tövsiyə edir.',array['Elm öyrənməyi və kamilliyi','Var-dövlət yığmağı','Uzaq ölkəyə köçməyi','Ov öyrənməyi'],1),
('edeb8-intibah#10','edebiyyat','edeb-8-intibah',2,1,'Xaqani Şirvani hansı janrın böyük ustası sayılır?','O, qəsidə janrının böyük ustası sayılır.',array['Qəsidənin','Dastanın','Komediyanın','Romanın'],1),
('edeb8-intibah#11','edebiyyat','edeb-8-intibah',2,1,'İntibah dövrü Azərbaycan ədəbiyyatı hansı əsrləri əhatə edir?','Dövr XII-XIII əsrləri əhatə edir.',array['XII-XIII əsrləri','XVIII-XIX əsrləri','XX əsri','VII-VIII əsrləri'],1),
('edeb8-intibah#12','edebiyyat','edeb-8-intibah',2,1,'«Sirlər xəzinəsi» hansı səciyyəli poemadır?','Didaktik-fəlsəfi səciyyəli poemadır.',array['Didaktik-fəlsəfi','Sırf məhəbbət','Sənədli-tarixi','Yumoristik'],1),
('edeb8-intibah#13','edebiyyat','edeb-8-intibah',2,1,'Nizami «Xəmsə»sinə neçə poema daxildir?','«Xəmsə»yə beş poema daxildir.',array['Beş','Üç','Yeddi','On'],1),
('edeb8-intibah#14','edebiyyat','edeb-8-intibah',2,1,'İntibah dövrü ədəbiyyatında hansı ideya güclüdür?','İnsana və onun ağlına inam ideyası güclüdür.',array['İnsana və onun ağlına inam','Taleyə tam təslimiyyət','Var-dövlətin tərənnümü','Döyüş qəniməti ideyası'],1),
('edeb8-intibah#15','edebiyyat','edeb-8-intibah',2,1,'Xaqani Şirvani hansı dildə yazmışdır?','O da əsasən fars dilində yazmışdır.',array['Fars dilində','Yalnız ərəb dilində','Yunan dilində','Latın dilində'],1),
('edeb8-intibah#16','edebiyyat','edeb-8-intibah',2,1,'«Sultan Səncər və qarı» hansı formada yazılmışdır?','Hekayət nəzmlə - şeirlə yazılmışdır.',array['Nəzmlə','Nəsrlə','Qarışıq formada','Məktub formasında'],1),
('edeb8-intibah#17','edebiyyat','edeb-8-intibah',2,1,'Nizaminin didaktik hekayətlərində əsas məqsəd nədir?','Oxucuya əxlaqi dərs vermək, düşündürməkdir.',array['Əxlaqi dərs vermək','Əyləndirmək','Tarix yazmaq','Coğrafiya öyrətmək'],1),
('edeb8-intibah#18','edebiyyat','edeb-8-intibah',2,1,'İntibah sözünün mənası nədir?','Oyanış, yenidən dirçəliş deməkdir.',array['Oyanış, dirçəliş','Süqut, tənəzzül','Səfər, köç','Sükut, dayanma'],1),
('edeb8-intibah#19','edebiyyat','edeb-8-intibah',2,1,'Nizami hansı şəhərdə yaşamışdır?','Şair Gəncədə yaşayıb-yaratmışdır.',array['Gəncədə','Şamaxıda','Təbrizdə','Bakıda'],1),
('edeb8-intibah#20','edebiyyat','edeb-8-intibah',3,1,'İntibah dövrü üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Sultan Səncər və qarı» Nizaminin, «Gənclərə nəsihət» Xaqaninindir.',array['«Sultan Səncər və qarı» - Nizami','«Sultan Səncər və qarı» - Xaqani','«Gənclərə nəsihət» - Nizami','«Sirlər xəzinəsi» - Xaqani'],1),
('edeb8-intibah#21','edebiyyat','edeb-8-intibah',3,1,'İntibah dövrü haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','«Sultan Səncər və qarı» nəzmlə yazılmışdır.',array['«Sultan Səncər və qarı» nəsrlə yazılıb','Nizami Gəncədə yaşamışdır','Xaqani qəsidə ustası sayılır','«Sirlər xəzinəsi» didaktik poemadır'],1),
('edeb8-intibah#22','edebiyyat','edeb-8-intibah',3,1,'Qarının hökmdarla danışa bilməsi nəyi göstərir?','Nizaminin haqq sözünü hakimiyyətdən üstün tutduğunu göstərir.',array['Haqq sözünün hakimiyyətdən üstünlüyünü','Saray adətlərinin sadə olduğunu','Ticarətin sərbəst olduğunu','Ordunun zəif olduğunu'],1),
('edeb8-intibah#23','edebiyyat','edeb-8-intibah',3,1,'Nizami və Xaqani haqqında hansı fikir doğrudur?','Nizami Gəncə, Xaqani isə Şirvan ədəbi mühiti ilə bağlıdır.',array['Nizami Gəncə, Xaqani Şirvan mühitindəndir','Nizami Şirvan, Xaqani Gəncə mühitindəndir','Hər ikisi Şirvan mühitindəndir','Hər ikisi Təbriz mühitindəndir'],1),
('edeb8-intibah#24','edebiyyat','edeb-8-intibah',3,1,'Aşağıdakı «əsər - poema» cütlüklərindən hansı doğrudur?','«Sultan Səncər və qarı» «Sirlər xəzinəsi» poemasındandır.',array['«Sultan Səncər və qarı» - «Sirlər xəzinəsi»','«Sultan Səncər və qarı» - «Yeddi gözəl»','«Bahariyyə» - «Sirlər xəzinəsi»','«Gənclərə nəsihət» - «Sirlər xəzinəsi»'],1),
('edeb8-intibah#25','edebiyyat','edeb-8-intibah',3,1,'Nizaminin didaktik hekayətlərinin quruluşca səciyyəvi cəhəti nədir?','Kiçik süjetdən sonra müəllif nəticəsi - əxlaqi ümumiləşdirmə gəlir.',array['Süjetdən sonra əxlaqi nəticə verilir','Əxlaqi nəticədən sonra süjet verilir','Süjet ümumiyyətlə verilmir','Nəticə oxucuya buraxılır'],1),
('edeb8-intibah#26','edebiyyat','edeb-8-intibah',3,1,'İntibah dövrü ilə orta əsrlər dövrünün ardıcıllığı necədir? (1 - orta əsrlər, 2 - qədim dövr, 3 - intibah dövrü)','Əvvəlcə qədim dövr, sonra intibah dövrü, ardınca orta əsrlər gəlir.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb8-intibah#27','edebiyyat','edeb-8-intibah',3,1,'Nizami yaradıcılığı haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','«Xəmsə» beş poemadan ibarətdir.',array['«Xəmsə» üç poemadan ibarətdir','Nizami fars dilində yazmışdır','«Sirlər xəzinəsi» didaktik poemadır','Şair Gəncədə yaşamışdır'],1),
('edeb8-intibah#28','edebiyyat','edeb-8-intibah',3,1,'Xaqaninin «Gənclərə nəsihət» əsərini didaktik edən cəhət nədir?','Əsər birbaşa öyüd verir, oxucunu kamilliyə çağırır.',array['Öyüd verib kamilliyə çağırması','Döyüş səhnələrini təsvir etməsi','Sənədli hadisə danışması','Gülüş doğurmaq məqsədi'],1),
('edeb8-intibah#29','edebiyyat','edeb-8-intibah',3,1,'Aşağıdakı «şair - janr» cütlüklərindən hansı düzgündür?','Xaqani qəsidə, Nizami isə poema ustası kimi tanınır.',array['Xaqani - qəsidə','Nizami - qəsidə','Xaqani - poema','Nizami - komediya'],1),
('edeb8-intibah#30','edebiyyat','edeb-8-intibah',3,1,'Sultan Səncər obrazı ilə qarı obrazı nəyi qarşılaşdırır?','Hakimiyyət gücü ilə haqq sözünün gücünü qarşılaşdırır.',array['Hakimiyyət gücü ilə haqq sözünü','İki ayrı ölkənin ordusunu','İki tacirin var-dövlətini','İki şairin sənətkarlığını'],1),
('edeb8-intibah#31','edebiyyat','edeb-8-intibah',3,1,'İntibah dövrü ədəbiyyatının səciyyəvi cəhəti nədir?','İnsana, onun ağlına və kamilliyinə inam səciyyəvidir.',array['İnsana və onun ağlına inam','Taleyə tam təslimiyyət','Döyüş qənimətinin tərənnümü','Saray mərasimlərinin təsviri'],1),
('edeb8-orta#1','edebiyyat','edeb-8-orta',1,2,'«Ağrımaz» şeirinin müəllifi kimdir?','Şeirin müəllifi İmadəddin Nəsimidir.',array['İmadəddin Nəsimi','Məhəmməd Füzuli','Şah İsmayıl Xətayi','Qurbani'],1),
('edeb8-orta#2','edebiyyat','edeb-8-orta',1,2,'Orta əsrlər bölməsindəki «Söz» qəzəlinin müəllifi kimdir?','Bu qəzəlin müəllifi Məhəmməd Füzulidir.',array['Məhəmməd Füzuli','İmadəddin Nəsimi','Xaqani Şirvani','Qurbani'],1),
('edeb8-orta#3','edebiyyat','edeb-8-orta',1,2,'«Bahariyyə» hansı poemadan götürülmüşdür?','«Bahariyyə» «Dəhnamə» poemasından götürülmüşdür.',array['«Dəhnamə»','«Sirlər xəzinəsi»','«Leyli və Məcnun»','«Yeddi gözəl»'],1),
('edeb8-orta#4','edebiyyat','edeb-8-orta',1,2,'«Bənövşəni» şeirinin müəllifi kimdir?','Şeirin müəllifi aşıq Qurbanidir.',array['Qurbani','Aşıq Ələsgər','Molla Pənah Vaqif','Qasım bəy Zakir'],1),
('edeb8-orta#5','edebiyyat','edeb-8-orta',2,2,'Nəsimi şeirlərində insanı necə qiymətləndirir?','O, insanı ən uca varlıq kimi qiymətləndirir.',array['Ən uca varlıq kimi','Zəif və aciz varlıq kimi','Təbiətin sıravi hissəsi kimi','Təsadüfi varlıq kimi'],1),
('edeb8-orta#6','edebiyyat','edeb-8-orta',2,2,'«Bahariyyə» nə deməkdir?','Baharın təsvirinə həsr olunmuş şeir parçasıdır.',array['Baharın təsvirinə həsr olunmuş şeir','Qış mənzərəsinin təsviri','Döyüş salnaməsi','Ticarət hesabatı'],1),
('edeb8-orta#7','edebiyyat','edeb-8-orta',2,2,'Şah İsmayıl Xətayi «Dəhnamə»ni hansı dildə yazmışdır?','Poema Azərbaycan dilində - ana dilində yazılmışdır.',array['Azərbaycan dilində','Ərəb dilində','Yunan dilində','Rus dilində'],1),
('edeb8-orta#8','edebiyyat','edeb-8-orta',2,2,'Füzulinin «Söz» qəzəlində nə tərənnüm olunur?','Sözün və söz sənətinin qüdrəti tərənnüm olunur.',array['Sözün və sənətin qüdrəti','Döyüş qələbəsi','Ticarət uğuru','Ov səhnəsi'],1),
('edeb8-orta#9','edebiyyat','edeb-8-orta',2,2,'Qurbani hansı sənətin nümayəndəsidir?','Qurbani aşıq sənətinin nümayəndəsidir.',array['Aşıq sənətinin','Saray şeirinin','Dramaturgiyanın','Nəsrin'],1),
('edeb8-orta#10','edebiyyat','edeb-8-orta',2,2,'Qurbani hansı əsrdə yaşamışdır?','Qurbani XVI əsrdə - Şah İsmayıl dövründə yaşamışdır.',array['XVI əsrdə','XII əsrdə','XIX əsrdə','XX əsrdə'],1),
('edeb8-orta#11','edebiyyat','edeb-8-orta',2,2,'«Bənövşəni» hansı şeir formasındadır?','Şeir qoşma formasındadır.',array['Qoşma','Qəzəl','Rübai','Sonet'],1),
('edeb8-orta#12','edebiyyat','edeb-8-orta',2,2,'Orta əsrlər yazılı şeirində hansı vəzn hakim idi?','Yazılı şeirdə əruz vəzni hakim idi.',array['Əruz vəzni','Heca vəzni','Sərbəst şeir','Ağ şeir'],1),
('edeb8-orta#13','edebiyyat','edeb-8-orta',2,2,'Məhəmməd Füzuli hansı ədəbi növün böyük ustasıdır?','Füzuli lirikanın böyük ustasıdır.',array['Lirikanın','Dramaturgiyanın','Publisistikanın','Elmi nəsrin'],1),
('edeb8-orta#14','edebiyyat','edeb-8-orta',2,2,'Şah İsmayıl Xətayi eyni zamanda kim olmuşdur?','O, həm şair, həm də dövlət başçısı olmuşdur.',array['Həm şair, həm dövlət başçısı','Saray katibi','Karvan taciri','Sərhəd gözətçisi'],1),
('edeb8-orta#15','edebiyyat','edeb-8-orta',2,2,'İmadəddin Nəsimi hansı əsrlərdə yaşamışdır?','Nəsimi XIV-XV əsrlərdə yaşamışdır.',array['XIV-XV əsrlərdə','XII əsrdə','XVII əsrdə','XIX əsrdə'],1),
('edeb8-orta#16','edebiyyat','edeb-8-orta',2,2,'Orta əsrlər Azərbaycan yazılı ədəbiyyatında hansı janr aparıcı idi?','Aparıcı janr qəzəl idi.',array['Qəzəl','Roman','Hekayə','Komediya'],1),
('edeb8-orta#17','edebiyyat','edeb-8-orta',2,2,'Qəzəl adətən neçə beytdən ibarət olur?','Qəzəl adətən beş-on beş beyt arasında olur.',array['Beş-on beş beyt arasında','Yalnız iki beyt','Yüz beytdən çox','Yalnız bir beyt'],1),
('edeb8-orta#18','edebiyyat','edeb-8-orta',2,2,'Aşıq şeirində hansı vəzn işlənir?','Aşıq şeiri heca vəznində qurulur.',array['Heca vəzni','Əruz vəzni','Sərbəst şeir','Ağ şeir'],1),
('edeb8-orta#19','edebiyyat','edeb-8-orta',2,2,'Orta əsrlər lirikasında məhəbbət necə şərh olunurdu?','Dünyəvi eşqdən ilahi eşqə yüksəlmə kimi şərh olunurdu.',array['Dünyəvi eşqdən ilahi eşqə yüksəlmə kimi','Sadə məişət hadisəsi kimi','Ticarət razılaşması kimi','Döyüş səbəbi kimi'],1),
('edeb8-orta#20','edebiyyat','edeb-8-orta',3,2,'Orta əsrlər bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Ağrımaz» Nəsiminin, «Bənövşəni» isə Qurbanınindir.',array['«Ağrımaz» - Nəsimi','«Ağrımaz» - Füzuli','«Söz» - Nəsimi','«Bənövşəni» - Xətayi'],1),
('edeb8-orta#21','edebiyyat','edeb-8-orta',3,2,'Orta əsrlər əsərləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','«Bahariyyə» Xətayinin «Dəhnamə» poemasındandır.',array['«Bahariyyə» Füzulinin əsəridir','«Ağrımaz» Nəsiminindir','«Bənövşəni» Qurbanınindir','«Dəhnamə» Xətayinindir'],1),
('edeb8-orta#22','edebiyyat','edeb-8-orta',3,2,'Nəsimi və Qurbaninin şeir vəzni haqqında hansı fikir doğrudur?','Nəsimi əruz, Qurbani isə heca vəznində yazmışdır.',array['Nəsimi əruzda, Qurbani hecada yazmışdır','Nəsimi hecada, Qurbani əruzda yazmışdır','Hər ikisi əruz vəznində yazmışdır','Hər ikisi heca vəznində yazmışdır'],1),
('edeb8-orta#23','edebiyyat','edeb-8-orta',3,2,'Orta əsrlər şairləri üzrə «şair - forma» cütlüyü hansı doğrudur?','Qurbani qoşma, Füzuli isə qəzəl müəllifidir.',array['Qurbani - qoşma','Nəsimi - qoşma','Qurbani - qəzəl','Füzuli - qoşma'],1),
('edeb8-orta#24','edebiyyat','edeb-8-orta',3,2,'Üç şair yaşadıqları dövrün ardıcıllığı ilə necə düzülür? (1 - Nəsimi, 2 - Füzuli, 3 - Xətayi)','Nəsimi XIV-XV, Xətayi XV-XVI, Füzuli isə XVI əsrdə yaşamışdır.',array['1 - 3 - 2','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb8-orta#25','edebiyyat','edeb-8-orta',3,2,'Ədəbi janrlar haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Qəzəl lirik janrdır, səhnə üçün yazılmır.',array['Qəzəl səhnə əsəridir','Qoşma xalq şeiri formasıdır','Qəzəl lirik janrdır','Poema süjetli şeir əsəridir'],1),
('edeb8-orta#26','edebiyyat','edeb-8-orta',3,2,'Füzuli və Nəsiminin yaradıcılığındakı ortaq cəhət nədir?','Hər ikisi əruz vəznində qəzəl yazmışdır.',array['Hər ikisi əruzda qəzəl yazmışdır','Hər ikisi aşıq şeiri yazmışdır','Hər ikisi dram əsəri yazmışdır','Hər ikisi roman müəllifidir'],1),
('edeb8-orta#27','edebiyyat','edeb-8-orta',3,2,'Orta əsrlərdə qəzəlin geniş yayılmasının səbəbi nədir?','Qəzəl lirik duyğunu qısa və yığcam formada verə bilirdi.',array['Lirik duyğunu qısa formada verməsi','Səhnə üçün əlverişli olması','Sənədli məlumat verməsi','Uzun süjet tələb etməsi'],1),
('edeb8-orta#28','edebiyyat','edeb-8-orta',3,2,'Orta əsrlər əsərləri üzrə «əsər - forma» cütlüyü hansı düzgündür?','«Söz» qəzəl, «Bənövşəni» isə qoşmadır.',array['«Söz» - qəzəl','«Söz» - qoşma','«Bənövşəni» - qəzəl','«Bahariyyə» - qəzəl'],1),
('edeb8-orta#29','edebiyyat','edeb-8-orta',3,2,'Yazılı ədəbiyyat ilə aşıq şeirinin vəzn baxımından fərqi nədir?','Yazılı ədəbiyyat əruz, aşıq şeiri isə heca vəznindədir.',array['Yazılı ədəbiyyat əruzda, aşıq şeiri hecadadır','Yazılı ədəbiyyat hecada, aşıq şeiri əruzdadır','Hər ikisi əruz vəznindədir','Hər ikisi sərbəst şeirdədir'],1),
('edeb8-orta#30','edebiyyat','edeb-8-orta',3,2,'Orta əsrlər şairləri haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Qurbani XVI əsr aşığıdır, XIX əsr şairi deyil.',array['Qurbani XIX əsr şairidir','Nəsimi XIV-XV əsrlərdə yaşamışdır','Füzuli lirikanın ustasıdır','Xətayi ana dilində yazmışdır'],1),
('edeb8-orta#31','edebiyyat','edeb-8-orta',3,2,'Orta əsrlər əsərləri üzrə «əsər - mövzu» cütlüyü hansı doğrudur?','«Söz» sözün qüdrətindən, «Bahariyyə» isə bahardan bəhs edir.',array['«Söz» - sözün qüdrəti','«Bahariyyə» - sözün qüdrəti','«Söz» - bahar təsviri','«Bənövşəni» - sözün qüdrəti'],1),
('edeb8-erken#1','edebiyyat','edeb-8-erken',1,2,'«Koroğlu ilə Bolu bəy» hansı dastandan götürülmüşdür?','Bu qol «Koroğlu» dastanındandır.',array['«Koroğlu»','«Kitabi-Dədə Qorqud»','«Şahnamə»','«Dəhnamə»'],1),
('edeb8-erken#2','edebiyyat','edeb-8-erken',1,2,'«Hayıf ki, yoxdur...» şeirinin müəllifi kimdir?','Şeirin müəllifi Molla Pənah Vaqifdir.',array['Molla Pənah Vaqif','Qurbani','Saib Təbrizi','Aşıq Ələsgər'],1),
('edeb8-erken#3','edebiyyat','edeb-8-erken',1,2,'Saib Təbrizi hansı şəhərlə bağlıdır?','Şair Təbriz şəhəri ilə bağlıdır.',array['Təbrizlə','Şuşa ilə','Gəncə ilə','Şamaxı ilə'],1),
('edeb8-erken#4','edebiyyat','edeb-8-erken',1,2,'«Koroğlu» dastanının qəhrəmanı hansı dağda qərargah qurmuşdur?','Koroğlunun qərargahı Çənlibeldədir.',array['Çənlibeldə','Savalanda','Şahdağda','Kəpəzdə'],1),
('edeb8-erken#5','edebiyyat','edeb-8-erken',2,2,'Bolu bəy dastanda kimdir?','Bolu bəy Koroğlunun düşməni olan bəydir.',array['Koroğlunun düşməni olan bəy','Koroğlunun dəlisi','Koroğlunun atası','Çənlibelin aşığı'],1),
('edeb8-erken#6','edebiyyat','edeb-8-erken',2,2,'Molla Pənah Vaqif şeirlərini hansı dildə yazmışdır?','Vaqif şeirlərini ana dilində yazmışdır.',array['Ana dilində','Fars dilində','Ərəb dilində','Rus dilində'],1),
('edeb8-erken#7','edebiyyat','edeb-8-erken',2,2,'Saib Təbrizi əsərlərini hansı dildə yazmışdır?','O, əsasən fars dilində yazmışdır.',array['Əsasən fars dilində','Yalnız ərəb dilində','Yunan dilində','Latın dilində'],1),
('edeb8-erken#8','edebiyyat','edeb-8-erken',2,2,'«Hayıf ki, yoxdur...» şeirində şair nədən şikayətlənir?','Şair dövrün nöqsanlarından, ədalətsizlikdən şikayətlənir.',array['Dövrün nöqsanlarından','Uzun səfərdən','Soyuq havadan','Ticarət qiymətlərindən'],1),
('edeb8-erken#9','edebiyyat','edeb-8-erken',2,2,'Erkən yeni dövr Azərbaycan ədəbiyyatı hansı əsrləri əhatə edir?','Dövr XVI-XVIII əsrləri əhatə edir.',array['XVI-XVIII əsrləri','XII-XIII əsrləri','XIX-XX əsrləri','VII-VIII əsrləri'],1),
('edeb8-erken#10','edebiyyat','edeb-8-erken',2,2,'Koroğlu kimlərin haqqını müdafiə edir?','O, sadə xalqın haqqını müdafiə edir.',array['Sadə xalqın','Saray əyanlarının','Xarici tacirlərin','Din xadimlərinin'],1),
('edeb8-erken#11','edebiyyat','edeb-8-erken',2,2,'Dastanda Koroğlunun silahdaşları necə adlanır?','Onlar dəlilər adlanır.',array['Dəlilər','Ozanlar','Sərkərdələr','Elçilər'],1),
('edeb8-erken#12','edebiyyat','edeb-8-erken',2,2,'Molla Pənah Vaqif hansı yüzillikdə yaşamışdır?','Vaqif XVIII əsrdə yaşamışdır.',array['XVIII əsrdə','XII əsrdə','XVI əsrdə','XX əsrdə'],1),
('edeb8-erken#13','edebiyyat','edeb-8-erken',2,2,'Saib Təbrizi hansı üslubun nümayəndəsi sayılır?','O, hind üslubunun nümayəndəsi sayılır.',array['Hind üslubunun','Klassisizmin','Romantizmin','Realizmin'],1),
('edeb8-erken#14','edebiyyat','edeb-8-erken',2,2,'Koroğlu igidliklə yanaşı hansı bacarığa malikdir?','O, həm də aşıqdır, saz çalıb şeir deyir.',array['Aşıqdır, saz çalır','Karvan taciridir','Memardır','Həkimdir'],1),
('edeb8-erken#15','edebiyyat','edeb-8-erken',2,2,'Vaqifin şeirlərinin dili necədir?','Dili sadə, xalq danışığına yaxındır.',array['Sadə, xalq danışığına yaxın','Ağır ərəb-fars tərkibli','Süni tərcümə dili','Rəsmi sənəd dili'],1),
('edeb8-erken#16','edebiyyat','edeb-8-erken',2,2,'Saib Təbrizinin «Söz» şeirində nə önə çəkilir?','Sözün dəyəri və təsir gücü önə çəkilir.',array['Sözün dəyəri və təsir gücü','Ticarətin faydası','Ov qaydaları','Səfərin çətinliyi'],1),
('edeb8-erken#17','edebiyyat','edeb-8-erken',2,2,'«Koroğlu» dastanı necə yayılmışdır?','Dastan aşıqların ifasında, şifahi şəkildə yayılmışdır.',array['Aşıqların ifasında, şifahi','Yalnız kitab şəklində','Xarici dildən tərcümə yolu ilə','Məktəb dərsliyi kimi'],1),
('edeb8-erken#18','edebiyyat','edeb-8-erken',2,2,'Erkən yeni dövrdə ana dilli şeir necə inkişaf edir?','Xalq şeiri formaları güclənir, ana dilli şeir yayılır.',array['Xalq şeiri formaları güclənir','Ana dili tərk edilir','Şeir ancaq ərəbcə yazılır','Şeir yazılmır'],1),
('edeb8-erken#19','edebiyyat','edeb-8-erken',2,2,'Vaqifin yaradıcılığında hansı mövzu geniş yer tutur?','Gözəllik və real dünya həyatı geniş yer tutur.',array['Gözəllik və real həyat','Kosmos və texnika','Dəniz macərası','Elmi kəşflər'],1),
('edeb8-erken#20','edebiyyat','edeb-8-erken',3,2,'Erkən yeni dövr üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Hayıf ki, yoxdur...» Vaqifin şeiridir.',array['«Hayıf ki, yoxdur...» - Vaqif','«Hayıf ki, yoxdur...» - Saib Təbrizi','«Söz» - Vaqif','«Bənövşəni» - Vaqif'],1),
('edeb8-erken#21','edebiyyat','edeb-8-erken',3,2,'Erkən yeni dövr haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Vaqif ana dilində, sadə xalq dilində yazmışdır.',array['Vaqif əsərlərini fars dilində yazmışdır','Vaqif XVIII əsrdə yaşamışdır','Koroğlu xalq qəhrəmanı obrazıdır','Saib Təbrizi hind üslubundandır'],1),
('edeb8-erken#22','edebiyyat','edeb-8-erken',3,2,'Vaqif və Saib Təbrizinin yazdıqları dil baxımından fərqi nədir?','Vaqif ana dilində, Saib Təbrizi isə farsca yazmışdır.',array['Vaqif ana dilində, Saib farsca yazmışdır','Vaqif farsca, Saib ana dilində yazmışdır','Hər ikisi ana dilində yazmışdır','Hər ikisi ərəb dilində yazmışdır'],1),
('edeb8-erken#23','edebiyyat','edeb-8-erken',3,2,'Koroğlunun xalq arasında sevilməsinin səbəbi nədir?','O, zülmə qarşı çıxıb sadə adamların tərəfini tutur.',array['Zülmə qarşı xalqın tərəfini tutması','Saray adamlarına yaxın olması','Çoxlu var-dövlət toplaması','Uzaq ölkələrə səfərə çıxması'],1),
('edeb8-erken#24','edebiyyat','edeb-8-erken',3,2,'«Koroğlu» dastanı üzrə «obraz - rol» cütlüyü hansı doğrudur?','Bolu bəy Koroğlunun düşməni, Nigar xanım isə həyat yoldaşıdır.',array['Bolu bəy - Koroğlunun düşməni','Bolu bəy - Koroğlunun dəlisi','Nigar xanım - Koroğlunun düşməni','Alı kişi - Koroğlunun düşməni'],1),
('edeb8-erken#25','edebiyyat','edeb-8-erken',3,2,'Aşağıdakı üç ədəbi hadisə zaman ardıcıllığı ilə necə düzülür? (1 - Vaqifin yaradıcılığı, 2 - Zakirin yaradıcılığı, 3 - «Koroğlu» dastanının formalaşması)','Dastan XVI-XVII əsrlərdə formalaşıb, Vaqif XVIII, Zakir isə XIX əsrdə yaşamışdır.',array['3 - 1 - 2','1 - 2 - 3','2 - 3 - 1','1 - 3 - 2'],1),
('edeb8-erken#26','edebiyyat','edeb-8-erken',3,2,'Dövrün sərhədi haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Erkən yeni dövr XVI-XVIII əsrləri əhatə edir.',array['Erkən yeni dövr XX əsri əhatə edir','Vaqif bu dövrün şairidir','«Koroğlu» xalq dastanıdır','Saib Təbrizi bu dövrdə yaşamışdır'],1),
('edeb8-erken#27','edebiyyat','edeb-8-erken',3,2,'Koroğlu və Vaqif haqqında hansı fikir doğrudur?','Koroğlu dastan qəhrəmanı, Vaqif isə real tarixi şəxsiyyətdir.',array['Koroğlu dastan qəhrəmanı, Vaqif real şairdir','Koroğlu real şair, Vaqif dastan qəhrəmanıdır','Hər ikisi dastan qəhrəmanıdır','Hər ikisi real tarixi şairdir'],1),
('edeb8-erken#28','edebiyyat','edeb-8-erken',3,2,'Erkən yeni dövr şairləri üzrə «şair - üslub» cütlüyü hansı düzgündür?','Saib Təbrizi hind üslubunun nümayəndəsidir.',array['Saib Təbrizi - hind üslubu','Molla Pənah Vaqif - hind üslubu','Saib Təbrizi - aşıq üslubu','Qurbani - hind üslubu'],1),
('edeb8-erken#29','edebiyyat','edeb-8-erken',3,2,'Aşağıdakı «əsər - mənbə» cütlüklərindən hansı doğrudur?','«Koroğlu ilə Bolu bəy» «Koroğlu» dastanının qoludur.',array['«Koroğlu ilə Bolu bəy» - «Koroğlu» dastanı','«Koroğlu ilə Bolu bəy» - «Kitabi-Dədə Qorqud»','«Bahariyyə» - «Koroğlu» dastanı','«Bənövşəni» - «Koroğlu» dastanı'],1),
('edeb8-erken#30','edebiyyat','edeb-8-erken',3,2,'Dastan qəhrəmanı ilə lirik qəhrəman arasındakı fərq nədir?','Dastan qəhrəmanı hadisələr içində, lirik qəhrəman duyğu daşıyıcısıdır.',array['Biri hadisələr içində, digəri duyğu daşıyıcısıdır','Biri duyğu daşıyıcısı, digəri hadisələr içindədir','Hər ikisi eyni anlayışı bildirir','Hər ikisi ancaq dramda olur'],1),
('edeb8-erken#31','edebiyyat','edeb-8-erken',3,2,'Dastanın yayılma yolu barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Koroğlu» şifahi xalq ədəbiyyatı nümunəsidir.',array['«Koroğlu» yazılı ədəbiyyat nümunəsidir','«Koroğlu» aşıq ifasında yayılmışdır','Dəlilər Koroğlunun silahdaşlarıdır','Bolu bəy Koroğlunun düşmənidir'],1),
('edeb8-maarifci#1','edebiyyat','edeb-8-maarifci',1,3,'«Durnalar» şeirinin müəllifi kimdir?','Şeirin müəllifi Qasım bəy Zakirdir.',array['Qasım bəy Zakir','Aşıq Ələsgər','Seyid Əzim Şirvani','Aşıq Alı'],1),
('edeb8-maarifci#2','edebiyyat','edeb-8-maarifci',1,3,'«Qafqaz müsəlmanlarına xitab» əsərinin müəllifi kimdir?','Əsərin müəllifi Seyid Əzim Şirvanidir.',array['Seyid Əzim Şirvani','Qasım bəy Zakir','Aşıq Alı','Aşıq Ələsgər'],1),
('edeb8-maarifci#3','edebiyyat','edeb-8-maarifci',1,3,'«Bənzərsən» şeirinin müəllifi kimdir?','Şeirin müəllifi Aşıq Alıdır.',array['Aşıq Alı','Aşıq Ələsgər','Qurbani','Qasım bəy Zakir'],1),
('edeb8-maarifci#4','edebiyyat','edeb-8-maarifci',1,3,'Səkkizinci sinif dərsliyindəki «Dağlar» şeirinin müəllifi kimdir?','Şeirin müəllifi Aşıq Ələsgərdir.',array['Aşıq Ələsgər','Aşıq Alı','Qurbani','Seyid Əzim Şirvani'],1),
('edeb8-maarifci#5','edebiyyat','edeb-8-maarifci',2,3,'«Durnalar» şeirində hansı hiss ifadə olunur?','Qürbət həsrəti və vətən yanğısı ifadə olunur.',array['Qürbət həsrəti və vətən yanğısı','Ov sevinci','Ticarət uğuru','Elmi maraq'],1),
('edeb8-maarifci#6','edebiyyat','edeb-8-maarifci',2,3,'«Durnalar» şeirində durna obrazı nəyin daşıyıcısıdır?','Durna xəbərin və həsrətin daşıyıcısıdır.',array['Xəbər və həsrətin','Var-dövlətin','Döyüş gücünün','Ticarət yolunun'],1),
('edeb8-maarifci#7','edebiyyat','edeb-8-maarifci',2,3,'«Qafqaz müsəlmanlarına xitab» əsərində şair nəyə çağırır?','Şair elm öyrənməyə və maariflənməyə çağırır.',array['Elm öyrənməyə və maariflənməyə','Ticarətə başlamağa','Uzaq elə köçməyə','Ova çıxmağa'],1),
('edeb8-maarifci#8','edebiyyat','edeb-8-maarifci',2,3,'Aşıq Alı kimin ustadı olmuşdur?','Aşıq Alı Aşıq Ələsgərin ustadı olmuşdur.',array['Aşıq Ələsgərin','Qasım bəy Zakirin','Seyid Əzim Şirvaninin','Molla Pənah Vaqifin'],1),
('edeb8-maarifci#9','edebiyyat','edeb-8-maarifci',2,3,'Aşıq Ələsgərin «Dağlar» şeirində nə vəsf olunur?','Doğma təbiət, dağların gözəlliyi vəsf olunur.',array['Doğma təbiət və dağlar','Şəhər küçələri','Dəniz limanı','Saray otaqları'],1),
('edeb8-maarifci#10','edebiyyat','edeb-8-maarifci',2,3,'Maarifçi realizm dövrü hansı əsrə düşür?','Dövr XIX əsrə düşür.',array['XIX əsrə','XII əsrə','XVI əsrə','XX əsrin sonuna'],1),
('edeb8-maarifci#11','edebiyyat','edeb-8-maarifci',2,3,'Aşıq sənətində «ustad-şagird» ənənəsi nə deməkdir?','Sənətin ustaddan şagirdə ötürülməsi deməkdir.',array['Sənətin ustaddan şagirdə ötürülməsi','Kitab yazmaq qaydası','Saray xidməti qaydası','Ticarət şagirdliyi'],1),
('edeb8-maarifci#12','edebiyyat','edeb-8-maarifci',2,3,'Qasım bəy Zakirin yaradıcılığında hansı istiqamət güclüdür?','Onun yaradıcılığında satirik istiqamət güclüdür.',array['Satirik istiqamət','Elmi-fantastik istiqamət','Detektiv istiqamət','Sənədli xronika istiqaməti'],1),
('edeb8-maarifci#13','edebiyyat','edeb-8-maarifci',2,3,'Seyid Əzim Şirvani hansı dövrün nümayəndəsidir?','O, maarifçi realizm dövrünün nümayəndəsidir.',array['Maarifçi realizm dövrünün','İntibah dövrünün','Qədim dövrün','Müstəqillik dövrünün'],1),
('edeb8-maarifci#14','edebiyyat','edeb-8-maarifci',2,3,'Aşıq Ələsgər hansı şeir formalarında xüsusilə güclüdür?','O, qoşma və təcnis formalarında xüsusilə güclüdür.',array['Qoşma və təcnisdə','Qəzəl və qəsidədə','Sonet və balladada','Məsnəvi və rübaidə'],1),
('edeb8-maarifci#15','edebiyyat','edeb-8-maarifci',2,3,'Bu dövrdə ədəbiyyatın qarşısında hansı vəzifə dururdu?','Xalqı maarifləndirmək vəzifəsi dururdu.',array['Xalqı maarifləndirmək','Saray həyatını tərənnüm etmək','Ancaq təbiəti vəsf etmək','Döyüş salnaməsi yazmaq'],1),
('edeb8-maarifci#16','edebiyyat','edeb-8-maarifci',2,3,'Qasım bəy Zakir hansı bölgə ilə bağlıdır?','Şair Qarabağla, Şuşa mühiti ilə bağlıdır.',array['Qarabağla','Şirvanla','Göyçə ilə','Naxçıvanla'],1),
('edeb8-maarifci#17','edebiyyat','edeb-8-maarifci',2,3,'Aşıq Ələsgər hansı aşıq mühitinin nümayəndəsidir?','O, Göyçə aşıq mühitinin nümayəndəsidir.',array['Göyçə aşıq mühitinin','Şirvan aşıq mühitinin','Təbriz mühitinin','Bakı mühitinin'],1),
('edeb8-maarifci#18','edebiyyat','edeb-8-maarifci',2,3,'Bu dövrün şairləri əsasən hansı dildə yazırdılar?','Onlar ana dilində yazırdılar.',array['Ana dilində','Ancaq fars dilində','Ancaq ərəb dilində','Latın dilində'],1),
('edeb8-maarifci#19','edebiyyat','edeb-8-maarifci',2,3,'Maarifçilik nə deməkdir?','Elm və təhsil vasitəsilə cəmiyyəti dəyişdirmək fikridir.',array['Elm və təhsillə cəmiyyəti dəyişdirmək','Keçmişə qayıtmaq','Xəyali aləmə qaçmaq','Döyüşə çağırmaq'],1),
('edeb8-maarifci#20','edebiyyat','edeb-8-maarifci',3,3,'Maarifçi realizm bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Durnalar» Zakirin, «Dağlar» isə Aşıq Ələsgərindir.',array['«Durnalar» - Qasım bəy Zakir','«Durnalar» - Aşıq Ələsgər','«Dağlar» - Qasım bəy Zakir','«Bənzərsən» - Seyid Əzim Şirvani'],1),
('edeb8-maarifci#21','edebiyyat','edeb-8-maarifci',3,3,'Bu bölmə haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','«Bənzərsən» Aşıq Alının şeiridir.',array['«Bənzərsən» Seyid Əzim Şirvaninindir','«Dağlar» Aşıq Ələsgərindir','«Durnalar» Zakirindir','Aşıq Alı Aşıq Ələsgərin ustadıdır'],1),
('edeb8-maarifci#22','edebiyyat','edeb-8-maarifci',3,3,'Zakir və Seyid Əzim Şirvaninin ortaq cəhəti nədir?','Hər ikisi maarifçi realizm dövrünün yazılı ədəbiyyat nümayəndəsidir.',array['Hər ikisi maarifçi realizm nümayəndəsidir','Hər ikisi aşıq sənətinin nümayəndəsidir','Hər ikisi intibah dövrünə aiddir','Hər ikisi dramaturq olmuşdur'],1),
('edeb8-maarifci#23','edebiyyat','edeb-8-maarifci',3,3,'«Qafqaz müsəlmanlarına xitab» əsərinin yazılma məqsədi nədir?','Xalqı elmə, maarifə və oyanışa çağırmaq məqsədi daşıyır.',array['Xalqı elmə və maarifə çağırmaq','Ticarəti təbliğ etmək','Ov qaydalarını öyrətmək','Saray həyatını vəsf etmək'],1),
('edeb8-maarifci#24','edebiyyat','edeb-8-maarifci',3,3,'Aşıq sənətkarları üzrə «şəxs - mühit» cütlüyü hansı doğrudur?','Aşıq Ələsgər Göyçə aşıq mühitinin nümayəndəsidir.',array['Aşıq Ələsgər - Göyçə mühiti','Aşıq Ələsgər - Şirvan mühiti','Seyid Əzim Şirvani - Göyçə mühiti','Qasım bəy Zakir - Göyçə mühiti'],1),
('edeb8-maarifci#25','edebiyyat','edeb-8-maarifci',3,3,'Üç sənətkar zaman ardıcıllığı ilə necə düzülür? (1 - Vaqif, 2 - Aşıq Ələsgər, 3 - Zakir)','Vaqif XVIII əsrdə, Zakir XIX əsrin ortalarında, Aşıq Ələsgər isə XIX əsrin sonu - XX əsrin əvvəlində yaşamışdır.',array['1 - 3 - 2','1 - 2 - 3','2 - 3 - 1','3 - 1 - 2'],1),
('edeb8-maarifci#26','edebiyyat','edeb-8-maarifci',3,3,'Dövrün sərhədi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Maarifçi realizm XIX əsrə aiddir.',array['Maarifçi realizm XII əsrə aiddir','Dövrün əsas ideyası maarifçilikdir','Zakir bu dövrün şairidir','Şirvani maarifçi şair olmuşdur'],1),
('edeb8-maarifci#27','edebiyyat','edeb-8-maarifci',3,3,'Aşıq Alı və Aşıq Ələsgər haqqında hansı fikir doğrudur?','Aşıq Alı ustad, Aşıq Ələsgər isə onun şagirdi olmuşdur.',array['Aşıq Alı ustad, Aşıq Ələsgər şagird olmuşdur','Aşıq Ələsgər ustad, Aşıq Alı şagird olmuşdur','Hər ikisi eyni ustadın şagirdi olmuşdur','Aralarında sənət bağı olmamışdır'],1),
('edeb8-maarifci#28','edebiyyat','edeb-8-maarifci',3,3,'Bu bölmə üzrə «əsər - mövzu» cütlüyü hansı düzgündür?','«Durnalar» qürbət həsrətindən, «Dağlar» təbiətdən bəhs edir.',array['«Durnalar» - qürbət həsrəti','«Dağlar» - qürbət həsrəti','«Durnalar» - təbiət vəsfi','«Qafqaz müsəlmanlarına xitab» - qürbət həsrəti'],1),
('edeb8-maarifci#29','edebiyyat','edeb-8-maarifci',3,3,'XIX əsrdə maarifçilik ideyasının güclənməsinin səbəbi nədir?','Cəmiyyətin geriliyini elm və təhsillə aradan qaldırmaq istəyi.',array['Geriliyi elmlə aradan qaldırmaq istəyi','Saray sifarişlərinin artması','Ticarət yollarının açılması','Aşıq sənətinin zəifləməsi'],1),
('edeb8-maarifci#30','edebiyyat','edeb-8-maarifci',3,3,'Bu dövr sənətkarları üzrə «şair - janr» cütlüyü hansı doğrudur?','Qasım bəy Zakir satirik şeirin görkəmli nümayəndəsidir.',array['Qasım bəy Zakir - satirik şeir','Aşıq Ələsgər - satirik şeir','Qasım bəy Zakir - mənzum dram','Aşıq Alı - satirik şeir'],1),
('edeb8-maarifci#31','edebiyyat','edeb-8-maarifci',3,3,'Aşıq şeiri ilə yazılı maarifçi şeirin yayılma yolu necə fərqlənir?','Aşıq şeiri sazla ifa olunur, yazılı şeir isə oxunur.',array['Aşıq şeiri sazla ifa olunur, yazılı şeir oxunur','Aşıq şeiri oxunur, yazılı şeir sazla ifa olunur','Hər ikisi sazla ifa olunur','Hər ikisi ancaq kitabla yayılır'],1),
('edeb8-tenqidi#1','edebiyyat','edeb-8-tenqidi',1,3,'«Qurbanəli bəy» hekayəsinin müəllifi kimdir?','Hekayənin müəllifi Cəlil Məmmədquluzadədir.',array['Cəlil Məmmədquluzadə','Mirzə Ələkbər Sabir','Əbdürrəhim bəy Haqverdiyev','Abdulla Şaiq'],1),
('edeb8-tenqidi#2','edebiyyat','edeb-8-tenqidi',1,3,'«Bomba» hekayəsinin müəllifi kimdir?','Hekayənin müəllifi Əbdürrəhim bəy Haqverdiyevdir.',array['Əbdürrəhim bəy Haqverdiyev','Cəlil Məmmədquluzadə','Mirzə Ələkbər Sabir','Abdulla Şaiq'],1),
('edeb8-tenqidi#3','edebiyyat','edeb-8-tenqidi',1,3,'«Əkinçi» şeirinin müəllifi kimdir?','Şeirin müəllifi Mirzə Ələkbər Sabirdir.',array['Mirzə Ələkbər Sabir','Cəlil Məmmədquluzadə','Məhəmməd Hadi','Abdulla Şaiq'],1),
('edeb8-tenqidi#4','edebiyyat','edeb-8-tenqidi',1,3,'«Məktub yetişmədi» əsərinin müəllifi kimdir?','Əsərin müəllifi Abdulla Şaiqdir.',array['Abdulla Şaiq','Mirzə Ələkbər Sabir','Əbdürrəhim bəy Haqverdiyev','Məhəmməd Hadi'],1),
('edeb8-tenqidi#5','edebiyyat','edeb-8-tenqidi',2,3,'«Qurbanəli bəy» hekayəsində hansı xüsusiyyət gülüş hədəfidir?','Özünü olduğundan böyük göstərmək, riyakarlıq gülüş hədəfidir.',array['Özünü böyük göstərmək','Zəhmətkeşlik','Elm öyrənmək','Səxavətlilik'],1),
('edeb8-tenqidi#6','edebiyyat','edeb-8-tenqidi',2,3,'Səkkizinci sinifdə keçilən tənqidi realizm mərhələsi hansı illərə düşür?','Dövr əsasən XX əsrin əvvəllərini əhatə edir.',array['XX əsrin əvvəllərini','XII əsri','XVI əsri','1960-1990-cı illəri'],1),
('edeb8-tenqidi#7','edebiyyat','edeb-8-tenqidi',2,3,'Sabirin satirik şeirləri hansı jurnalda çap olunurdu?','Onun şeirləri «Molla Nəsrəddin» jurnalında çap olunurdu.',array['«Molla Nəsrəddin»də','«Əkinçi»də','«Füyuzat»da','«Kaspi»də'],1),
('edeb8-tenqidi#8','edebiyyat','edeb-8-tenqidi',2,3,'Sabirin «Əkinçi» şeirində kim təsvir olunur?','Şeirdə zəhmətkeş əkinçi obrazı təsvir olunur.',array['Zəhmətkeş əkinçi','Saray əyanı','Xarici tacir','Dəniz kapitanı'],1),
('edeb8-tenqidi#9','edebiyyat','edeb-8-tenqidi',2,3,'«Bomba» hekayəsi hansı üsulla yazılmışdır?','Hekayə satirik üsulla yazılmışdır.',array['Satirik üsulla','Sənədli üsulla','Elmi üsulla','Mərsiyə üslubunda'],1),
('edeb8-tenqidi#10','edebiyyat','edeb-8-tenqidi',2,3,'Tənqidi realizm nəyi əsas hədəf seçir?','Cəmiyyətin nöqsanlarını ifşa etməyi hədəf seçir.',array['Cəmiyyətin nöqsanlarını','Xəyali aləmi','Saray mərasimlərini','Kosmos tədqiqatını'],1),
('edeb8-tenqidi#11','edebiyyat','edeb-8-tenqidi',2,3,'Abdulla Şaiq ədəbiyyatla yanaşı hansı işlə məşğul olmuşdur?','O, müəllimlik etmiş, dərsliklər yazmışdır.',array['Müəllimlik və dərslik yazmaqla','Karvan ticarəti ilə','Memarlıqla','Həkimliklə'],1),
('edeb8-tenqidi#12','edebiyyat','edeb-8-tenqidi',2,3,'Cəlil Məmmədquluzadə hansı janrlarda güclü olmuşdur?','O, satirik hekayə və dram janrlarında güclü olmuşdur.',array['Satirik hekayə və dramda','Qəsidədə','Elmi traktatda','Aşıq şeirində'],1),
('edeb8-tenqidi#13','edebiyyat','edeb-8-tenqidi',2,3,'«Qurbanəli bəy» hansı ədəbi növə aiddir?','Hekayə epik növə aiddir.',array['Epik növə','Lirik növə','Dram növünə','Publisistikaya'],1),
('edeb8-tenqidi#14','edebiyyat','edeb-8-tenqidi',2,3,'Sabirin şeirlərində istifadə etdiyi əsas bədii vasitə nədir?','Satira və kinayə əsas vasitədir.',array['Satira və kinayə','Mübaliğəli qəhrəmanlıq','Mistik təsvir','Quru elmi şərh'],1),
('edeb8-tenqidi#15','edebiyyat','edeb-8-tenqidi',2,3,'Tənqidi realistlərin dili necə idi?','Sadə, xalqın başa düşdüyü dil idi.',array['Sadə, xalqın anladığı dil','Ağır ərəb-fars dili','Süni tərcümə dili','Rəsmi sənəd dili'],1),
('edeb8-tenqidi#16','edebiyyat','edeb-8-tenqidi',2,3,'Əbdürrəhim bəy Haqverdiyev hansı sahədə də çalışmışdır?','O, dramaturgiya sahəsində də çalışmışdır.',array['Dramaturgiyada','Aşıq şeirində','Elmi fantastikada','Memarlıqda'],1),
('edeb8-tenqidi#17','edebiyyat','edeb-8-tenqidi',2,3,'Bu dövrdə ədəbiyyat hansı ictimai vəzifəni daşıyırdı?','Cəhaləti ifşa edib xalqı oyatmaq vəzifəsini daşıyırdı.',array['Cəhaləti ifşa edib xalqı oyatmaq','Saray həyatını vəsf etmək','Ticarəti təbliğ etmək','Ov qaydalarını öyrətmək'],1),
('edeb8-tenqidi#18','edebiyyat','edeb-8-tenqidi',2,3,'«Bomba» hekayəsində gülüş nəyə yönəlmişdir?','Gülüş cəhalətə və nadanlığa yönəlmişdir.',array['Cəhalət və nadanlığa','Elmi kəşflərə','Zəhmətkeş kəndliyə','Müəllim peşəsinə'],1),
('edeb8-tenqidi#19','edebiyyat','edeb-8-tenqidi',2,3,'Qurbanəli bəy obrazı hansı ictimai təbəqəni təmsil edir?','Boş, iddialı bəy təbəqəsini təmsil edir.',array['Boş və iddialı bəy təbəqəsini','Zəhmətkeş kəndliləri','Maarifçi ziyalıları','Sənətkar aşıqları'],1),
('edeb8-tenqidi#20','edebiyyat','edeb-8-tenqidi',3,3,'Tənqidi realizm üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Bomba» Haqverdiyevin, «Qurbanəli bəy» Məmmədquluzadənindir.',array['«Bomba» - Haqverdiyev','«Bomba» - Məmmədquluzadə','«Qurbanəli bəy» - Haqverdiyev','«Əkinçi» - Haqverdiyev'],1),
('edeb8-tenqidi#21','edebiyyat','edeb-8-tenqidi',3,3,'Tənqidi realizm əsərləri barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Əkinçi» şeiri Sabirindir.',array['«Əkinçi» şeiri Məmmədquluzadənindir','«Qurbanəli bəy» Məmmədquluzadənindir','«Bomba» Haqverdiyevindir','Sabir satirik şair olmuşdur'],1),
('edeb8-tenqidi#22','edebiyyat','edeb-8-tenqidi',3,3,'Sabirin şeirləri ilə Məmmədquluzadənin hekayələrinin ortaq cəhəti nədir?','Hər ikisi satira ilə cəhaləti və nöqsanları ifşa edir.',array['Hər ikisi satira ilə cəhaləti ifşa edir','Hər ikisi saray həyatını vəsf edir','Hər ikisi tarixi salnamədir','Hər ikisi məhəbbət lirikasıdır'],1),
('edeb8-tenqidi#23','edebiyyat','edeb-8-tenqidi',3,3,'Qurbanəli bəyin gülünc vəziyyətə düşməsinin səbəbi nədir?','O, özünü olduğundan böyük göstərməyə çalışır.',array['Özünü olduğundan böyük göstərməsi','Uzaq ölkəyə səfərə çıxması','Ticarətdə uğursuzluğa düşməsi','Torpaq üstündə mübahisəsi'],1),
('edeb8-tenqidi#24','edebiyyat','edeb-8-tenqidi',3,3,'Bu bölmə üzrə «əsər - janr» cütlüyü hansı doğrudur?','«Qurbanəli bəy» hekayə, «Əkinçi» isə şeirdir.',array['«Qurbanəli bəy» - hekayə','«Əkinçi» - hekayə','«Qurbanəli bəy» - şeir','«Bomba» - şeir'],1),
('edeb8-tenqidi#25','edebiyyat','edeb-8-tenqidi',3,3,'Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? (1 - «Molla Nəsrəddin» jurnalı, 2 - «Əkinçi» qəzeti, 3 - 1937-ci il repressiyası)','«Əkinçi» 1875-ci, «Molla Nəsrəddin» 1906-cı ildə çıxıb, repressiya isə 1937-ci ildə olub.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb8-tenqidi#26','edebiyyat','edeb-8-tenqidi',3,3,'Dövrün çərçivəsi haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Tənqidi realizm XX əsrin əvvəlinə düşür.',array['Tənqidi realizm XII əsrdə formalaşmışdır','Dövr XX əsrin əvvəlinə düşür','Sabir bu dövrün şairidir','Satira dövrün əsas vasitəsidir'],1),
('edeb8-tenqidi#27','edebiyyat','edeb-8-tenqidi',3,3,'Məmmədquluzadə və Haqverdiyev haqqında hansı fikir doğrudur?','Hər ikisi satirik nəsr nümunələri yazmışdır.',array['Hər ikisi satirik nəsr yazmışdır','Hər ikisi ancaq şeir yazmışdır','Biri şair, digəri bəstəkar olmuşdur','Hər ikisi aşıq sənətkarı olmuşdur'],1),
('edeb8-tenqidi#28','edebiyyat','edeb-8-tenqidi',3,3,'Bu bölmə üzrə «əsər - tənqid hədəfi» cütlüyü hansı düzgündür?','«Bomba» cəhaləti və nadanlığı hədəfə alır.',array['«Bomba» - cəhalət və nadanlıq','«Əkinçi» - cəhalət və nadanlıq','«Bomba» - saray həyatı','«Qurbanəli bəy» - elmi kəşflər'],1),
('edeb8-tenqidi#29','edebiyyat','edeb-8-tenqidi',3,3,'Tənqidi realistlərin sadə dildə yazmasının səbəbi nədir?','Onlar geniş xalq kütləsinə çatmaq istəyirdilər.',array['Geniş xalq kütləsinə çatmaq istəyi','Klassik dili bilməmələri','Senzuradan yayınmaq cəhdi','Tərcümə asanlığı məqsədi'],1),
('edeb8-tenqidi#30','edebiyyat','edeb-8-tenqidi',3,3,'Satira ilə mədhiyyənin əsas fərqi nədir?','Satira nöqsanı ifşa edir, mədhiyyə isə tərifləyir.',array['Satira ifşa edir, mədhiyyə tərifləyir','Satira tərifləyir, mədhiyyə ifşa edir','Hər ikisi tərifləmə üzərində qurulur','Hər ikisi ifşa üzərində qurulur'],1),
('edeb8-tenqidi#31','edebiyyat','edeb-8-tenqidi',3,3,'Aşağıdakı «nəşr - şair» cütlüklərindən hansı doğrudur?','Sabirin satiraları «Molla Nəsrəddin» jurnalında çıxırdı.',array['«Molla Nəsrəddin» - Sabir','«Əkinçi» - Sabir','«Molla Nəsrəddin» - Xaqani','«Füyuzat» - Sabir'],1),
('edeb8-romantizm#1','edebiyyat','edeb-8-romantizm',1,4,'Mənzum dram «Ana»nın müəllifi kimdir?','Əsərin müəllifi Hüseyn Caviddir.',array['Hüseyn Cavid','Məhəmməd Hadi','Mirzə Ələkbər Sabir','Yusif Vəzir Çəmənzəminli'],1),
('edeb8-romantizm#2','edebiyyat','edeb-8-romantizm',1,4,'«Türkün nəğməsi» şeirinin müəllifi kimdir?','Şeirin müəllifi Məhəmməd Hadidir.',array['Məhəmməd Hadi','Hüseyn Cavid','Abdulla Şaiq','Qasım bəy Zakir'],1),
('edeb8-romantizm#3','edebiyyat','edeb-8-romantizm',1,4,'Türkiyənin dövlət himni olan «İstiqlal marşı»nın müəllifi kimdir?','Mətnin müəllifi Mehmet Akif Ersoydur.',array['Mehmet Akif Ersoy','Hüseyn Cavid','Məhəmməd Hadi','Nəbi Xəzri'],1),
('edeb8-romantizm#4','edebiyyat','edeb-8-romantizm',1,4,'«Zeynal bəy» əsərinin müəllifi kimdir?','Əsərin müəllifi Yusif Vəzir Çəmənzəminlidir.',array['Yusif Vəzir Çəmənzəminli','Hüseyn Cavid','Məhəmməd Hadi','Abdulla Şaiq'],1),
('edeb8-romantizm#5','edebiyyat','edeb-8-romantizm',2,4,'Hüseyn Cavidin «Ana» əsəri hansı janrdadır?','Əsər mənzum dram janrındadır.',array['Mənzum dram','Roman','Hekayə','Qəsidə'],1),
('edeb8-romantizm#6','edebiyyat','edeb-8-romantizm',2,4,'«Ana» əsərində ana obrazının adı nədir?','Ana obrazının adı Səlmadır.',array['Səlma','Burla xatun','Nigar','Sona'],1),
('edeb8-romantizm#7','edebiyyat','edeb-8-romantizm',2,4,'«Ana» əsərinin əsas ideyası nədir?','Bağışlamaq, mərhəmət göstərmək ideyasıdır.',array['Bağışlamaq və mərhəmət','İntiqam almaq','Var-dövlət toplamaq','Uzaq səfərə çıxmaq'],1),
('edeb8-romantizm#8','edebiyyat','edeb-8-romantizm',2,4,'Məhəmməd Hadi hansı ədəbi cərəyanın nümayəndəsidir?','O, romantizmin nümayəndəsidir.',array['Romantizmin','Realizmin','Klassisizmin','Naturalizmin'],1),
('edeb8-romantizm#9','edebiyyat','edeb-8-romantizm',2,4,'«İstiqlal marşı» hansı ölkənin dövlət himnidir?','Bu, Türkiyənin dövlət himnidir.',array['Türkiyənin','Azərbaycanın','İranın','Rusiyanın'],1),
('edeb8-romantizm#10','edebiyyat','edeb-8-romantizm',2,4,'Romantizm ədəbiyyatda nəyə üstünlük verir?','İdeala, güclü hisslərə və xəyala üstünlük verir.',array['İdeala və güclü hisslərə','Statistik dəqiqliyə','Sənədli təsvirə','Quru elmi şərhə'],1),
('edeb8-romantizm#11','edebiyyat','edeb-8-romantizm',2,4,'Hüseyn Cavidin əsərlərinin səciyyəvi cəhəti nədir?','Əsərlərinin mənzum və fəlsəfi olması səciyyəvidir.',array['Mənzum və fəlsəfi olması','Sənədli olması','Qısa lətifə forması','Elmi məqalə forması'],1),
('edeb8-romantizm#12','edebiyyat','edeb-8-romantizm',2,4,'«Zeynal bəy» hansı ədəbi növə aiddir?','Əsər nəsrə aiddir.',array['Nəsrə','Poeziyaya','Dramaturgiyaya','Publisistikaya'],1),
('edeb8-romantizm#13','edebiyyat','edeb-8-romantizm',2,4,'Məhəmməd Hadi hansı şəhərdə doğulmuşdur?','Şair Şamaxıda doğulmuşdur.',array['Şamaxıda','Naxçıvanda','Gəncədə','Bakıda'],1),
('edeb8-romantizm#14','edebiyyat','edeb-8-romantizm',2,4,'«Türkün nəğməsi» şeirində hansı hiss önə çıxır?','Milli qürur və oyanış hissi önə çıxır.',array['Milli qürur və oyanış','Ticarət həvəsi','Ov təəssüratı','Dəniz həsrəti'],1),
('edeb8-romantizm#15','edebiyyat','edeb-8-romantizm',2,4,'Mehmet Akif Ersoy hansı ölkənin şairidir?','O, Türkiyə şairidir.',array['Türkiyənin','Almaniyanın','Fransanın','İranın'],1),
('edeb8-romantizm#16','edebiyyat','edeb-8-romantizm',2,4,'Romantizm və realizm eyni dövrdə necə mövcud olurdu?','Onlar yan-yana, bir-birini tamamlayaraq mövcud olurdu.',array['Yan-yana, bir-birini tamamlayaraq','Biri digərini bütövlükdə əvəz edərək','Yüz il ara ilə','Eyni dövrdə heç vaxt olmadan'],1),
('edeb8-romantizm#17','edebiyyat','edeb-8-romantizm',2,4,'Hüseyn Cavid hansı dövrün nümayəndəsidir?','O, XX əsrin əvvəllərinin nümayəndəsidir.',array['XX əsrin əvvəlinin','XII əsrin','XVI əsrin','XIX əsrin əvvəlinin'],1),
('edeb8-romantizm#18','edebiyyat','edeb-8-romantizm',2,4,'Yusif Vəzir Çəmənzəminli hansı ədəbi növdə tanınmışdır?','O, nəsrdə tanınmışdır.',array['Nəsrdə','Aşıq şeirində','Mənzum dramda','Qəsidədə'],1),
('edeb8-romantizm#19','edebiyyat','edeb-8-romantizm',2,4,'Dərslikdə dünya ədəbiyyatından mətn verilməsinin məqsədi nədir?','Ədəbiyyatı müqayisəli şəkildə öyrənməkdir.',array['Ədəbiyyatı müqayisəli öyrənmək','Xarici dil öyrətmək','Tarix dərsini əvəz etmək','Coğrafiya öyrətmək'],1),
('edeb8-romantizm#20','edebiyyat','edeb-8-romantizm',3,4,'Romantizm bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Türkün nəğməsi» Hadinin, «Ana» isə Hüseyn Cavidindir.',array['«Türkün nəğməsi» - Məhəmməd Hadi','«Türkün nəğməsi» - Hüseyn Cavid','«Ana» - Məhəmməd Hadi','«Zeynal bəy» - Hüseyn Cavid'],1),
('edeb8-romantizm#21','edebiyyat','edeb-8-romantizm',3,4,'Bu bölmə barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«İstiqlal marşı»nın müəllifi Mehmet Akif Ersoydur.',array['«İstiqlal marşı» Hüseyn Cavidindir','«Ana» Hüseyn Cavidin əsəridir','«Türkün nəğməsi» Məhəmməd Hadinindir','«Zeynal bəy» Çəmənzəminlinindir'],1),
('edeb8-romantizm#22','edebiyyat','edeb-8-romantizm',3,4,'Cavidin dramları ilə Məmmədquluzadənin hekayələrinin fərqi nədir?','Biri mənzum və romantik, digəri nəsr və satirikdir.',array['Biri mənzum və romantik, digəri nəsr və satirikdir','Biri nəsr və satirik, digəri mənzum və romantikdir','Hər ikisi mənzum dram nümunəsidir','Hər ikisi satirik hekayədir'],1),
('edeb8-romantizm#23','edebiyyat','edeb-8-romantizm',3,4,'«Ana» əsərində ananın qatili bağışlaması nəyi göstərir?','İnsani mərhəmətin qisas hissindən üstün tutulmasını göstərir.',array['Mərhəmətin qisasdan üstün tutulmasını','Qanunun gücsüz olduğunu','Ailə adətinin dəyişdiyini','Ticarət razılaşmasının bağlandığını'],1),
('edeb8-romantizm#24','edebiyyat','edeb-8-romantizm',3,4,'Aşağıdakı «əsər - ölkə» cütlüklərindən hansı doğrudur?','«İstiqlal marşı» Türkiyənin dövlət himnidir.',array['«İstiqlal marşı» - Türkiyə','«İstiqlal marşı» - Azərbaycan','«Türkün nəğməsi» - Türkiyə','«Ana» - Türkiyə'],1),
('edeb8-romantizm#25','edebiyyat','edeb-8-romantizm',3,4,'Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? (1 - «Ana» mənzum dramı, 2 - «Molla Nəsrəddin» jurnalı, 3 - «Əkinçi» qəzeti)','«Əkinçi» 1875-ci, «Molla Nəsrəddin» 1906-cı, «Ana» isə 1910-cu ildə meydana çıxmışdır.',array['3 - 2 - 1','1 - 2 - 3','2 - 3 - 1','2 - 1 - 3'],1),
('edeb8-romantizm#26','edebiyyat','edeb-8-romantizm',3,4,'Ədəbi cərəyanlar barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Romantizm sənədli dəqiqliyə deyil, ideala üstünlük verir.',array['Romantizm sənədli dəqiqliyə üstünlük verir','Romantizm ideala üstünlük verir','Məhəmməd Hadi romantik şairdir','Hüseyn Cavid mənzum dram yazmışdır'],1),
('edeb8-romantizm#27','edebiyyat','edeb-8-romantizm',3,4,'Hüseyn Cavid və Məhəmməd Hadi haqqında hansı fikir doğrudur?','Hər ikisi romantizm cərəyanının nümayəndəsidir.',array['Hər ikisi romantizmin nümayəndəsidir','Hər ikisi tənqidi realistdir','Biri romantik, digəri aşıq sənətkarıdır','Hər ikisi maarifçi realistdir'],1),
('edeb8-romantizm#28','edebiyyat','edeb-8-romantizm',3,4,'Bu bölmə üzrə «əsər - janr» cütlüyü hansı düzgündür?','«Ana» mənzum dram, «Zeynal bəy» isə nəsr əsəridir.',array['«Ana» - mənzum dram','«Ana» - roman','«Zeynal bəy» - mənzum dram','«Türkün nəğməsi» - mənzum dram'],1),
('edeb8-romantizm#29','edebiyyat','edeb-8-romantizm',3,4,'XX əsrin əvvəlində milli mövzunun güclənməsinin səbəbi nədir?','Milli oyanış və istiqlal hərəkatı bu mövzunu gücləndirdi.',array['Milli oyanış və istiqlal hərəkatı','Sənaye tikintisinin artması','Yeni ticarət yollarının açılması','Aşıq sənətinin zəifləməsi'],1),
('edeb8-romantizm#30','edebiyyat','edeb-8-romantizm',3,4,'Mənzum dram ilə nəsr əsərinin fərqi nədir?','Mənzum dram şeirlə, nəsr əsəri isə nəsrlə yazılır.',array['Biri şeirlə, digəri nəsrlə yazılır','Biri nəsrlə, digəri şeirlə yazılır','Hər ikisi şeirlə yazılır','Hər ikisi nəsrlə yazılır'],1),
('edeb8-romantizm#31','edebiyyat','edeb-8-romantizm',3,4,'Aşağıdakı «şair - cərəyan» cütlüklərindən hansı doğrudur?','Məhəmməd Hadi romantizmin, Sabir isə tənqidi realizmin şairidir.',array['Məhəmməd Hadi - romantizm','Mirzə Ələkbər Sabir - romantizm','Məhəmməd Hadi - maarifçi realizm','Cəlil Məmmədquluzadə - romantizm'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, tp.level_id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = d.fenn
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
   where owner_type = 'platform' and ext_key like 'edeb8-%';
  if n <> 217 then
    raise exception 'Edebiyyat 8 suallari: 217 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb8-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb8-%';
  if k <> 7 then
    raise exception 'movzu sayi 7 deyil: %', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb8-%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 8 banki: % sual, 7 movzu (her birinde 12 cetin).', n;
end $$;
