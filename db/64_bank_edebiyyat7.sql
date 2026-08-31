-- =====================================================================
--  64_bank_edebiyyat7.sql : EDEBIYYAT 7 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat7.py yaradir:
--      python3 tools/edebiyyat7.py
--
--  5 movzu x 31 sual = 155.  Her movzuda 4 asan + 15 orta + 12 cetin.
--  ext_key: edeb11-...
--  ON SERT: 61_movzular_edebiyyat5_8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'edebiyyat' and t.slug in
           ('edeb-7-sifahi', 'edeb-7-tebiet')
     having count(*) = 2) then
    raise exception 'ONCE 61_movzular_edebiyyat5_8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb7-%';

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('edeb7-sifahi#1','edebiyyat','edeb-7-sifahi',1,1,'«Dərzi şagirdi Əhməd» hansı janrdadır?','Bu, xalq nağılıdır.',array['Nağıl','Şeir','Dram','Roman'],1),
('edeb7-sifahi#2','edebiyyat','edeb-7-sifahi',1,1,'«Durna teli» hansı dastandan götürülmüşdür?','«Durna teli» «Koroğlu» dastanının qoludur.',array['«Koroğlu»','«Kitabi-Dədə Qorqud»','«Əsli və Kərəm»','«Aşıq Qərib»'],1),
('edeb7-sifahi#3','edebiyyat','edeb-7-sifahi',1,1,'«Xəzinəqaya» mətni hansı janrdadır?','Bu, əfsanədir.',array['Əfsanə','Qəzəl','Povest','Komediya'],1),
('edeb7-sifahi#4','edebiyyat','edeb-7-sifahi',1,1,'Şifahi xalq ədəbiyyatı əsərləri necə yayılır?','Onlar ağızdan-ağıza, şifahi yolla yayılır.',array['Ağızdan-ağıza, şifahi yolla','Ancaq kitab vasitəsilə','Tərcümə yolu ilə','Rəsmi sənədlərlə'],1),
('edeb7-sifahi#5','edebiyyat','edeb-7-sifahi',2,1,'Nağılın sonunda hansı ənənəvi ifadə işlənir?','Nağıllar çox vaxt «Göydən üç alma düşdü» ilə bitir.',array['«Göydən üç alma düşdü»','«Biri var idi, biri yox idi»','«Salam verdim, almadılar»','«Bir zamanlar uzaqda»'],1),
('edeb7-sifahi#6','edebiyyat','edeb-7-sifahi',2,1,'«Koroğlu» dastanının qolları kim tərəfindən ifa olunurdu?','Qollar aşıqlar tərəfindən ifa olunurdu.',array['Aşıqlar tərəfindən','Saray katibləri tərəfindən','Məktəb müəllimləri tərəfindən','Karvan tacirləri tərəfindən'],1),
('edeb7-sifahi#7','edebiyyat','edeb-7-sifahi',2,1,'Əfsanəni nağıldan fərqləndirən əsas cəhət nədir?','Əfsanə real bir yerə, dağa, qayaya və ya hadisəyə bağlanır.',array['Əfsanə real yerə və hadisəyə bağlanır','Nağıl real yerə bağlanır','İkisi arasında fərq yoxdur','Əfsanə hökmən şeirlə söylənir'],1),
('edeb7-sifahi#8','edebiyyat','edeb-7-sifahi',2,1,'Nağıllarda hansı saylar daha çox işlənir?','Nağıllarda üç və yeddi sayları çox işlənir.',array['Üç və yeddi','İki və dörd','Beş və on','Səkkiz və doqquz'],1),
('edeb7-sifahi#9','edebiyyat','edeb-7-sifahi',2,1,'Nağıl qəhrəmanının yolunda nə olur?','Onun yolunda sınaqlar və çətinliklər olur.',array['Sınaqlar və çətinliklər','Ancaq asan tapşırıqlar','Heç bir maneə','Ticarət müqavilələri'],1),
('edeb7-sifahi#10','edebiyyat','edeb-7-sifahi',2,1,'«Dərzi şagirdi Əhməd» nağılının qəhrəmanı hansı peşə ilə bağlıdır?','Qəhrəman dərzilik peşəsi ilə bağlıdır.',array['Dərziliklə','Dəmirçiliklə','Balıqçılıqla','Çobanlıqla'],1),
('edeb7-sifahi#11','edebiyyat','edeb-7-sifahi',2,1,'Şifahi xalq ədəbiyyatı nümunələrinin müəllifi kimdir?','Onların konkret müəllifi bilinmir, yaradıcısı xalqdır.',array['Müəllifi bilinmir, yaradıcısı xalqdır','Bir konkret şair','Saray katibi','Xarici bir müəllif'],1),
('edeb7-sifahi#12','edebiyyat','edeb-7-sifahi',2,1,'Əfsanələr çox vaxt nəyi izah edir?','Yer adlarının, qayaların, təbiət hadisələrinin mənşəyini izah edir.',array['Yer adlarının mənşəyini','Riyazi qanunları','Ticarət qaydalarını','Hərbi taktikanı'],1),
('edeb7-sifahi#13','edebiyyat','edeb-7-sifahi',2,1,'Dastanların söylənməsində hansı musiqi aləti işlənir?','Aşıq dastanı sazın müşayiəti ilə söyləyir.',array['Saz','Tar','Piano','Ney'],1),
('edeb7-sifahi#14','edebiyyat','edeb-7-sifahi',2,1,'Nağılda sehrli əşyalar hansı rolu oynayır?','Onlar qəhrəmana kömək edir, ona güc verir.',array['Qəhrəmana kömək edir','Qəhrəmana mane olur','Heç bir rol oynamır','Ancaq bəzək üçündür'],1),
('edeb7-sifahi#15','edebiyyat','edeb-7-sifahi',2,1,'Nağıllarda xeyirlə şərin mübarizəsi necə bitir?','Nağıllar xeyirin qələbəsi ilə bitir.',array['Xeyirin qələbəsi ilə','Şərin qələbəsi ilə','Heç bir nəticə olmadan','Ticarət razılaşması ilə'],1),
('edeb7-sifahi#16','edebiyyat','edeb-7-sifahi',2,1,'Əfsanə hansı ədəbi növə aiddir?','Əfsanə epik növə aiddir.',array['Epik növə','Lirik növə','Dram növünə','Publisistikaya'],1),
('edeb7-sifahi#17','edebiyyat','edeb-7-sifahi',2,1,'Nağıl qəhrəmanı adətən hansı keyfiyyətlərə malik olur?','O, cəsarətli, zəkalı və xeyirxah olur.',array['Cəsarət, zəka və xeyirxahlıq','Xəsislik və qorxaqlıq','Laqeydlik və etinasızlıq','Tənbəllik və süstlük'],1),
('edeb7-sifahi#18','edebiyyat','edeb-7-sifahi',2,1,'«Koroğlu» dastanında Koroğlunun atının adı nədir?','Koroğlunun atı Qıratdır.',array['Qırat','Düldül','Rəxş','Şəbdiz'],1),
('edeb7-sifahi#19','edebiyyat','edeb-7-sifahi',2,1,'Şifahi xalq ədəbiyyatı hansı dildə yaranır?','O, xalqın canlı danışıq dilində yaranır.',array['Xalqın canlı danışıq dilində','Ancaq ərəb dilində','Ancaq fars dilində','Latın dilində'],1),
('edeb7-sifahi#20','edebiyyat','edeb-7-sifahi',3,1,'Yeddinci sinif materialı üzrə «əsər - janr» cütlüyü hansı düzgündür?','«Xəzinəqaya» əfsanə, «Dərzi şagirdi Əhməd» isə nağıldır.',array['«Xəzinəqaya» - əfsanə','«Dərzi şagirdi Əhməd» - əfsanə','«Xəzinəqaya» - nağıl','«Durna teli» - əfsanə'],1),
('edeb7-sifahi#21','edebiyyat','edeb-7-sifahi',3,1,'Şifahi ədəbiyyat bölməsi haqqında hansı fikir SƏHVDİR?','«Durna teli» «Koroğlu» dastanının qoludur.',array['«Durna teli» «Dədə Qorqud» dastanındandır','«Dərzi şagirdi Əhməd» nağıldır','Əfsanələr real yerlə bağlanır','Nağıllarda üç sayı çox işlənir'],1),
('edeb7-sifahi#22','edebiyyat','edeb-7-sifahi',3,1,'Şifahi xalq ədəbiyyatı ilə yazılı ədəbiyyatın əsas fərqi nədir?','Şifahi ədəbiyyatın müəllifi bilinmir, yazılı ədəbiyyatınkı bilinir.',array['Şifahi ədəbiyyatın müəllifi bilinmir','Yazılı ədəbiyyatın müəllifi bilinmir','Hər ikisinin müəllifi bilinmir','Hər ikisinin müəllifi dəqiq bilinir'],1),
('edeb7-sifahi#23','edebiyyat','edeb-7-sifahi',3,1,'Nağıllarda sehrli əşyaların olmasının səbəbi nədir?','Sehrli əşyalar xalqın arzu və istəklərinin bədii ifadəsidir.',array['Xalqın arzu və istəklərinin ifadəsi','Tarixi sənədlərin birbaşa təsiri','Elmi biliklərin geniş yayılması','Ticarət əlaqələrinin genişlənməsi'],1),
('edeb7-sifahi#24','edebiyyat','edeb-7-sifahi',3,1,'Şifahi ədəbiyyat üzrə «əsər - mənbə» cütlüyü hansı doğrudur?','«Durna teli» «Koroğlu» dastanından götürülmüşdür.',array['«Durna teli» - «Koroğlu» dastanı','«Durna teli» - «Kitabi-Dədə Qorqud»','«Dərzi şagirdi Əhməd» - «Koroğlu» dastanı','«Xəzinəqaya» - «Koroğlu» dastanı'],1),
('edeb7-sifahi#25','edebiyyat','edeb-7-sifahi',3,1,'Nağılda hadisələr necə sıralanır? (1 - qəhrəmanın sınaqlardan keçməsi, 2 - qəhrəmanın yola düşməsi, 3 - xeyirin qələbəsi)','Əvvəlcə qəhrəman yola düşür, sonra sınaqlardan keçir, sonda xeyir udur.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb7-sifahi#26','edebiyyat','edeb-7-sifahi',3,1,'Ədəbi növlər haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Əfsanə epik növə aiddir, lirik növə deyil.',array['Əfsanə lirik növə aiddir','Nağıl epik növə aiddir','Dastan şifahi yolla yayılır','Aşıq dastanı sazla ifa edir'],1),
('edeb7-sifahi#27','edebiyyat','edeb-7-sifahi',3,1,'Nağıl və əfsanənin ortaq cəhəti nədir?','Hər ikisi şifahi xalq ədəbiyyatı nümunəsidir.',array['Hər ikisi şifahi xalq ədəbiyyatı nümunəsidir','Hər ikisi yazılı ədəbiyyata aiddir','Biri şifahi, digəri yazılı ədəbiyyatdandır','Hər ikisi hökmən şeirlə söylənir'],1),
('edeb7-sifahi#28','edebiyyat','edeb-7-sifahi',3,1,'Aşağıdakı «obraz - əsər» cütlüklərindən hansı düzgündür?','Qırat «Koroğlu» dastanının obrazıdır.',array['Qırat - «Koroğlu» dastanı','Qırat - «Kitabi-Dədə Qorqud»','Basat - «Koroğlu» dastanı','Uruz - «Koroğlu» dastanı'],1),
('edeb7-sifahi#29','edebiyyat','edeb-7-sifahi',3,1,'Əfsanələrin konkret yer adları ilə bağlanmasının səbəbi nədir?','Xalq ətrafındakı dünyanı, yer adlarını izah etmək istəyirdi.',array['Ətrafdakı dünyanı izah etmək istəyi','Coğrafiya dərsinin tələbi','Rəsmi sənədlərin birbaşa təsiri','Xarici ədəbiyyatın güclü təsiri'],1),
('edeb7-sifahi#30','edebiyyat','edeb-7-sifahi',3,1,'Nağıl qəhrəmanı ilə dastan qəhrəmanının fərqi nədir?','Dastan qəhrəmanı çox vaxt real tarixi zəmində verilir.',array['Dastan qəhrəmanı real tarixi zəmindədir','Nağıl qəhrəmanı real tarixi zəmindədir','İkisi arasında heç bir fərq yoxdur','Hər ikisi ancaq sehrli aləmdə yaşayır'],1),
('edeb7-sifahi#31','edebiyyat','edeb-7-sifahi',3,1,'Aşağıdakı «janr - əlamət» cütlüklərindən hansı doğrudur?','Sehrli əşyalar və qeyri-adi qüvvələr nağıl üçün səciyyəvidir.',array['Nağıl - sehrli əşyalar','Atalar sözü - sehrli əşyalar','Bayatı - sehrli əşyalar','Tapmaca - sehrli əşyalar'],1),
('edeb7-veten#1','edebiyyat','edeb-7-veten',1,1,'Yeddinci sinifdə keçilən «Azərbaycan» şeirinin müəllifi kimdir?','Şeirin müəllifi Səməd Vurğundur.',array['Səməd Vurğun','Mirzə İbrahimov','Zahid Xəlil','Rahil Məmməd'],1),
('edeb7-veten#2','edebiyyat','edeb-7-veten',1,1,'«Azad» əsərinin müəllifi kimdir?','Əsərin müəllifi Mirzə İbrahimovdur.',array['Mirzə İbrahimov','Səməd Vurğun','Eyvaz Zeynallı','Zahid Xəlil'],1),
('edeb7-veten#3','edebiyyat','edeb-7-veten',1,1,'«Babəkin andı» əsərinin müəllifi kimdir?','Əsərin müəllifi Mikayıl Rzaquluzadədir.',array['Mikayıl Rzaquluzadə','Mirzə İbrahimov','Rahil Məmməd','Səməd Vurğun'],1),
('edeb7-veten#4','edebiyyat','edeb-7-veten',1,1,'«Kəşfiyyatçılar» əsərinin müəllifi kimdir?','Əsərin müəllifi Eyvaz Zeynallıdır.',array['Eyvaz Zeynallı','Zahid Xəlil','Mikayıl Rzaquluzadə','Mirzə İbrahimov'],1),
('edeb7-veten#5','edebiyyat','edeb-7-veten',2,1,'«Azərbaycan» şeiri hansı ədəbi növə aiddir?','Şeir lirik növə aiddir.',array['Lirik növə','Epik növə','Dram növünə','Publisistikaya'],1),
('edeb7-veten#6','edebiyyat','edeb-7-veten',2,1,'«Babəkin andı» hansı tarixi şəxsiyyətə həsr olunmuşdur?','Əsər Babəkə həsr olunmuşdur.',array['Babəkə','Koroğluya','Cavanşirə','Şah İsmayıla'],1),
('edeb7-veten#7','edebiyyat','edeb-7-veten',2,1,'Babək hansı hərəkatın rəhbəri olmuşdur?','O, ərəb işğalına qarşı azadlıq hərəkatının rəhbəri olmuşdur.',array['Ərəb işğalına qarşı hərəkatın','Monqol işğalına qarşı hərəkatın','Rus işğalına qarşı hərəkatın','Səlib yürüşlərinə qarşı hərəkatın'],1),
('edeb7-veten#8','edebiyyat','edeb-7-veten',2,1,'«Qələbə müjdəsi» əsərinin müəllifi kimdir?','Əsərin müəllifi Rahil Məmməddir.',array['Rahil Məmməd','Eyvaz Zeynallı','Zahid Xəlil','Mikayıl Rzaquluzadə'],1),
('edeb7-veten#9','edebiyyat','edeb-7-veten',2,1,'«Sonuncu güllə» əsərinin müəllifi kimdir?','Əsərin müəllifi Zahid Xəlildir.',array['Zahid Xəlil','Rahil Məmməd','Mirzə İbrahimov','Eyvaz Zeynallı'],1),
('edeb7-veten#10','edebiyyat','edeb-7-veten',2,1,'Zahid Xəlil ədəbiyyatın hansı sahəsində tanınır?','O, uşaq ədəbiyyatı sahəsində tanınır.',array['Uşaq ədəbiyyatında','Elmi fantastikada','Memarlıqda','Bəstəkarlıqda'],1),
('edeb7-veten#11','edebiyyat','edeb-7-veten',2,1,'Bu bölmənin əsas mövzusu nədir?','Vətən sevgisi və qəhrəmanlıq mövzusudur.',array['Vətən sevgisi və qəhrəmanlıq','Ticarət və sənaye','Kosmos və texnika','Dəniz macərası'],1),
('edeb7-veten#12','edebiyyat','edeb-7-veten',2,1,'Mirzə İbrahimov hansı ədəbi növdə tanınmışdır?','O, nəsrdə tanınmışdır.',array['Nəsrdə','Aşıq şeirində','Mənzum dramda','Qəsidədə'],1),
('edeb7-veten#13','edebiyyat','edeb-7-veten',2,1,'Səməd Vurğunun şeirlərində hansı ovqat üstünlük təşkil edir?','Nikbinlik və vətənpərvərlik ovqatı üstünlük təşkil edir.',array['Nikbinlik və vətənpərvərlik','Kədər və ümidsizlik','Yumor və zarafat','Quru elmi soyuqluq'],1),
('edeb7-veten#14','edebiyyat','edeb-7-veten',2,1,'Vətənpərvərlik mövzusunda yazılan əsərlərin məqsədi nədir?','Oxucuda vətənə bağlılıq hissi aşılamaqdır.',array['Vətənə bağlılıq hissi aşılamaq','Ticarəti öyrətmək','Coğrafiya öyrətmək','Riyaziyyat öyrətmək'],1),
('edeb7-veten#15','edebiyyat','edeb-7-veten',2,1,'«Kəşfiyyatçılar» əsərinin mövzusu nə ilə bağlıdır?','Mövzu müharibə və igidliklə bağlıdır.',array['Müharibə və igidliklə','Ticarət səfəri ilə','Kənd təsərrüfatı ilə','Dəniz səyahəti ilə'],1),
('edeb7-veten#16','edebiyyat','edeb-7-veten',2,1,'Qəhrəmanlıq mövzulu əsərlərdə baş obraz necə verilir?','Fədakar və cəsur insan kimi verilir.',array['Fədakar və cəsur','Qorxaq və laqeyd','Xəsis və tamahkar','Etinasız və süst'],1),
('edeb7-veten#17','edebiyyat','edeb-7-veten',2,1,'«Azərbaycan» şeirində vətən obrazı necə canlandırılır?','Vətən ana kimi doğma və müqəddəs varlıq kimi canlandırılır.',array['Ana kimi doğma və müqəddəs','Yad və uzaq bir yer kimi','Sadəcə coğrafi ərazi kimi','Ticarət meydanı kimi'],1),
('edeb7-veten#18','edebiyyat','edeb-7-veten',2,1,'Mikayıl Rzaquluzadə hansı mövzuya müraciət etmişdir?','O, tarixi qəhrəmanlıq mövzusuna müraciət etmişdir.',array['Tarixi qəhrəmanlıq mövzusuna','Kosmos mövzusuna','Dəniz macərası mövzusuna','Memarlıq mövzusuna'],1),
('edeb7-veten#19','edebiyyat','edeb-7-veten',2,1,'Bu bölmədəki əsərlər hansı ədəbi növlərdədir?','Bölmədə həm nəsr, həm də şeir nümunələri var.',array['Həm nəsr, həm şeir','Ancaq dram','Ancaq publisistika','Ancaq qəzəl'],1),
('edeb7-veten#20','edebiyyat','edeb-7-veten',3,1,'Vətən mövzusu üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Azad» Mirzə İbrahimovun, «Azərbaycan» isə Səməd Vurğunundur.',array['«Azad» - Mirzə İbrahimov','«Azad» - Zahid Xəlil','«Azərbaycan» - Mirzə İbrahimov','«Babəkin andı» - Eyvaz Zeynallı'],1),
('edeb7-veten#21','edebiyyat','edeb-7-veten',3,1,'Vətən bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Azərbaycan» şeirinin müəllifi Səməd Vurğundur.',array['«Azərbaycan» şeirinin müəllifi Zahid Xəlildir','«Azad» Mirzə İbrahimovun əsəridir','«Babəkin andı» Rzaquluzadənindir','«Sonuncu güllə» Zahid Xəlilindir'],1),
('edeb7-veten#22','edebiyyat','edeb-7-veten',3,1,'Şeir və hekayənin vətənpərvərlik mövzusunu açma yolu necə fərqlənir?','Şeir duyğu ilə, hekayə isə hadisə ilə açır.',array['Şeir duyğu ilə, hekayə hadisə ilə açır','Şeir hadisə ilə, hekayə duyğu ilə açır','Hər ikisi eyni yolla açır','Hər ikisi sənədli üsulla açır'],1),
('edeb7-veten#23','edebiyyat','edeb-7-veten',3,1,'Babək obrazının ədəbiyyata gətirilməsinin səbəbi nədir?','Babək azadlıq mübarizəsinin simvoluna çevrilmişdir.',array['Azadlıq mübarizəsinin simvolu olması','Yeni ticarət yolları açmış olması','Böyük şəhərlər saldırmış olması','Dəyərli elmi əsərlər yazması'],1),
('edeb7-veten#24','edebiyyat','edeb-7-veten',3,1,'Tarixi şəxsiyyətlər üzrə «şəxs - fəaliyyət» cütlüyü hansı doğrudur?','Babək ərəb işğalına qarşı azadlıq hərəkatının rəhbəridir.',array['Babək - azadlıq hərəkatının rəhbəri','Babək - saray şairi','Nizami - azadlıq hərəkatının rəhbəri','Babək - karvan taciri'],1),
('edeb7-veten#25','edebiyyat','edeb-7-veten',3,1,'Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? (1 - «Azərbaycan» şeirinin yazılması, 2 - Babək hərəkatı, 3 - «Koroğlu» dastanının formalaşması)','Babək hərəkatı IX əsrdə, dastan XVI-XVII əsrlərdə, şeir isə XX əsrdə meydana çıxmışdır.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb7-veten#26','edebiyyat','edeb-7-veten',3,1,'Bölmənin mövzusu haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Bölmənin mövzusu vətən sevgisi və qəhrəmanlıqdır.',array['Bu bölmənin mövzusu kosmos tədqiqatıdır','Bölmənin mövzusu vətən sevgisidir','«Azərbaycan» Səməd Vurğunun şeiridir','Babək tarixi şəxsiyyətdir'],1),
('edeb7-veten#27','edebiyyat','edeb-7-veten',3,1,'Səməd Vurğun və Mirzə İbrahimov haqqında hansı fikir doğrudur?','Səməd Vurğun şair, Mirzə İbrahimov isə nasirdir.',array['Vurğun şair, Mirzə İbrahimov nasirdir','Vurğun nasir, Mirzə İbrahimov şairdir','Hər ikisi ancaq şair olmuşdur','Hər ikisi ancaq dramaturq olmuşdur'],1),
('edeb7-veten#28','edebiyyat','edeb-7-veten',3,1,'Vətən bölməsi üzrə «əsər - mövzu» cütlüyü hansı düzgündür?','«Babəkin andı» tarixi qəhrəmanlıq mövzusundadır.',array['«Babəkin andı» - tarixi qəhrəmanlıq','«Azərbaycan» - tarixi qəhrəmanlıq','«Babəkin andı» - dəniz səfəri','«Kəşfiyyatçılar» - dəniz səfəri'],1),
('edeb7-veten#29','edebiyyat','edeb-7-veten',3,1,'Vətənpərvərlik mövzusunun dərslikdə geniş yer tutmasının səbəbi nədir?','Şagirddə vətənə bağlılıq tərbiyə etmək məqsədi güdülür.',array['Şagirddə vətənə bağlılıq tərbiyəsi','Dərsliyin həcmini artırmaq istəyi','Xarici dil öyrətmək məqsədi','Riyazi bacarıq qazandırmaq'],1),
('edeb7-veten#30','edebiyyat','edeb-7-veten',3,1,'Tarixi qəhrəman ilə uydurma qəhrəmanın fərqi nədir?','Tarixi qəhrəman real yaşamış, uydurma qəhrəman təxəyyül məhsuludur.',array['Biri real yaşamış, digəri təxəyyül məhsuludur','Biri təxəyyül məhsulu, digəri real yaşamışdır','Hər ikisi real yaşamış şəxslərdir','Hər ikisi təxəyyül məhsuludur'],1),
('edeb7-veten#31','edebiyyat','edeb-7-veten',3,1,'Bu bölmə üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?','«Azərbaycan» şeir, «Azad» isə nəsr əsəridir.',array['«Azərbaycan» - şeir','«Azad» - şeir','«Azərbaycan» - hekayə','«Sonuncu güllə» - şeir'],1),
('edeb7-menevi#1','edebiyyat','edeb-7-menevi',1,2,'«Manqurt» hansı yazıçının əsərindən götürülmüşdür?','Parça Çingiz Aytmatovun əsərindəndir.',array['Çingiz Aytmatovun','Abdulla Şaiqin','Mir Cəlalın','Viktor Hüqonun'],1),
('edeb7-menevi#2','edebiyyat','edeb-7-menevi',1,2,'«Hikmətin fəziləti» əsərinin müəllifi kimdir?','Əsərin müəllifi Abbasqulu ağa Bakıxanovdur.',array['Abbasqulu ağa Bakıxanov','Hikmət Ziya','Fikrət Qoca','Abdulla Şaiq'],1),
('edeb7-menevi#3','edebiyyat','edeb-7-menevi',1,2,'«Kərgədan və qarışqa» hansı janrdadır?','Bu, təmsildir.',array['Təmsil','Roman','Faciə','Qəsidə'],1),
('edeb7-menevi#4','edebiyyat','edeb-7-menevi',1,2,'«Usta Bəxtiyar» əsərinin müəllifi kimdir?','Əsərin müəllifi Abdulla Şaiqdir.',array['Abdulla Şaiq','Hikmət Ziya','Fikrət Qoca','Abbasqulu ağa Bakıxanov'],1),
('edeb7-menevi#5','edebiyyat','edeb-7-menevi',2,2,'«Manqurt» hansı romandan götürülmüşdür?','Parça «Gün var əsrə bərabər» romanındandır.',array['«Gün var əsrə bərabər»','«Səfillər»','«Qorxulu nağıllar»','«Gülüstani-İrəm»'],1),
('edeb7-menevi#6','edebiyyat','edeb-7-menevi',2,2,'Manqurt sözü nə deməkdir?','Yaddaşı silinmiş, kim olduğunu unudan insan deməkdir.',array['Yaddaşı silinmiş insan','Uzaq ölkə taciri','Saray məmuru','Aşıq sənətkarı'],1),
('edeb7-menevi#7','edebiyyat','edeb-7-menevi',2,2,'Manqurtu kimlər yaratmışdır?','Onu əsir götürən düşmənlər yaddaşını məhv etməklə yaratmışdır.',array['Əsir götürən düşmənlər','Öz doğma qohumları','Karvan tacirləri','Kənd müəllimləri'],1),
('edeb7-menevi#8','edebiyyat','edeb-7-menevi',2,2,'Naiman-Ana obrazı kimdir?','Naiman-Ana manqurtun anasıdır.',array['Manqurtun anası','Manqurtun bacısı','Düşmən başçısı','Karvan rəhbəri'],1),
('edeb7-menevi#9','edebiyyat','edeb-7-menevi',2,2,'Naiman-Ana ilə oğlunun görüşü necə bitir?','Oğul anasını tanımır və onu oxla vurur.',array['Oğul anasını tanımır və onu vurur','Ana və oğul birlikdə evə qayıdır','Oğul yaddaşını tam bərpa edir','Ana oğlunu heç tapa bilmir'],1),
('edeb7-menevi#10','edebiyyat','edeb-7-menevi',2,2,'«Manqurt» parçasının əsas ideyası nədir?','Yaddaşsızlığın, kökünü unutmağın faciəsidir.',array['Yaddaşsızlığın faciəsi','Ticarətin faydası','Ov ənənəsinin qorunması','Elmi kəşfin əhəmiyyəti'],1),
('edeb7-menevi#11','edebiyyat','edeb-7-menevi',2,2,'Təmsil nədir?','Heyvan obrazları vasitəsilə əxlaqi dərs verən qısa əsərdir.',array['Heyvan obrazları ilə dərs verən qısa əsər','Uzun tarixi roman','Səhnə faciəsi','Dörd misralı bayatı'],1),
('edeb7-menevi#12','edebiyyat','edeb-7-menevi',2,2,'Təmsilin sonunda adətən nə verilir?','Sonda əxlaqi nəticə verilir.',array['Əxlaqi nəticə','Müəllifin tərcümeyi-halı','Coğrafi xəritə','Riyazi düstur'],1),
('edeb7-menevi#13','edebiyyat','edeb-7-menevi',2,2,'Abbasqulu ağa Bakıxanovun məşhur tarixi əsəri hansıdır?','Onun məşhur tarixi əsəri «Gülüstani-İrəm»dir.',array['«Gülüstani-İrəm»','«Gün var əsrə bərabər»','«Qorxulu nağıllar»','«Səfillər»'],1),
('edeb7-menevi#14','edebiyyat','edeb-7-menevi',2,2,'Abbasqulu ağa Bakıxanovun ədəbi təxəllüsü nədir?','Onun təxəllüsü Qüdsidir.',array['Qüdsi','Hophop','Vaqif','Xətayi'],1),
('edeb7-menevi#15','edebiyyat','edeb-7-menevi',2,2,'«Anamın sözləri» şeirinin müəllifi kimdir?','Şeirin müəllifi Fikrət Qocadır.',array['Fikrət Qoca','Hikmət Ziya','Abdulla Şaiq','Çingiz Aytmatov'],1),
('edeb7-menevi#16','edebiyyat','edeb-7-menevi',2,2,'Mənəvi dəyərlər bölməsinin əsas mövzusu nədir?','Mənəvi dəyərlər və həmişəyaşar hikmətlərdir.',array['Mənəvi dəyərlər və hikmət','Sənaye tikintisi','Dəniz ticarəti','Kosmos tədqiqatı'],1),
('edeb7-menevi#17','edebiyyat','edeb-7-menevi',2,2,'Abdulla Şaiq hansı ədəbi növlərdə yazmışdır?','O, həm şeir, həm də nəsr yazmışdır.',array['Həm şeir, həm nəsr','Ancaq dram','Ancaq elmi məqalə','Ancaq tərcümə'],1),
('edeb7-menevi#18','edebiyyat','edeb-7-menevi',2,2,'Manqurt obrazı hansı təhlükəni xatırladır?','Kökü, dili və yaddaşı unutmaq təhlükəsini xatırladır.',array['Kökü və yaddaşı unutmaq təhlükəsini','Ticarətdə uduzmaq təhlükəsini','Yolu azmaq təhlükəsini','Xəstələnmək təhlükəsini'],1),
('edeb7-menevi#19','edebiyyat','edeb-7-menevi',2,2,'Didaktik əsərlərin məqsədi nədir?','Öyüd vermək, oxucunu tərbiyə etməkdir.',array['Öyüd vermək və tərbiyə etmək','Ancaq güldürmək','Tarixi salnamə yazmaq','Coğrafi xəritə vermək'],1),
('edeb7-menevi#20','edebiyyat','edeb-7-menevi',3,2,'Mənəvi dəyərlər bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Manqurt» Aytmatovun, «Usta Bəxtiyar» isə Abdulla Şaiqindir.',array['«Manqurt» - Çingiz Aytmatov','«Manqurt» - Abdulla Şaiq','«Usta Bəxtiyar» - Çingiz Aytmatov','«Hikmətin fəziləti» - Çingiz Aytmatov'],1),
('edeb7-menevi#21','edebiyyat','edeb-7-menevi',3,2,'Mənəvi dəyərlər bölməsi barədə hansı fikir SƏHVDİR?','«Gülüstani-İrəm» Abbasqulu ağa Bakıxanovun əsəridir.',array['«Gülüstani-İrəm» Aytmatovun əsəridir','«Manqurt» Aytmatovun əsərindəndir','«Hikmətin fəziləti» Bakıxanovundur','«Usta Bəxtiyar» Abdulla Şaiqindir'],1),
('edeb7-menevi#22','edebiyyat','edeb-7-menevi',3,2,'Təmsil ilə nağılın əsas fərqi nədir?','Təmsildə sonda açıq əxlaqi nəticə verilir.',array['Təmsildə sonda açıq əxlaqi nəticə verilir','Nağılda sonda açıq əxlaqi nəticə verilir','Hər ikisində nəticə verilmir','Hər ikisi hökmən şeirlə yazılır'],1),
('edeb7-menevi#23','edebiyyat','edeb-7-menevi',3,2,'Manqurtun anasını tanımamasının səbəbi nədir?','Onun yaddaşı zorla, işgəncə ilə məhv edilmişdi.',array['Yaddaşının zorla məhv edilməsi','Uzun müddət ayrı qalmaları','Gözlərinin görməməsi','Anasının çox dəyişməsi'],1),
('edeb7-menevi#24','edebiyyat','edeb-7-menevi',3,2,'Mənəvi dəyərlər bölməsi üzrə «obraz - əsər» cütlüyü hansı doğrudur?','Naiman-Ana «Manqurt» parçasının obrazıdır.',array['Naiman-Ana - «Manqurt»','Naiman-Ana - «Usta Bəxtiyar»','Usta Bəxtiyar - «Manqurt»','Nurəddin - «Manqurt»'],1),
('edeb7-menevi#25','edebiyyat','edeb-7-menevi',3,2,'«Manqurt» parçasında hadisələr necə sıralanır? (1 - ananın oğlunu tapması, 2 - oğlanın əsir düşməsi, 3 - ananın həlak olması)','Əvvəlcə oğlan əsir düşür, sonra ana onu tapır, sonda ana həlak olur.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb7-menevi#26','edebiyyat','edeb-7-menevi',3,2,'Təmsil janrı haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Təmsil qısa əsərdir, uzun tarixi roman deyil.',array['Təmsil uzun tarixi romandır','Təmsildə heyvan obrazları olur','Təmsil əxlaqi nəticə ilə bitir','Təmsil qısa həcmli əsərdir'],1),
('edeb7-menevi#27','edebiyyat','edeb-7-menevi',3,2,'Bakıxanov və Abdulla Şaiq haqqında hansı fikir doğrudur?','Hər ikisi maarifçi mövqedən yazıb, öyrədici əsərlər yaratmışdır.',array['Hər ikisi maarifçi mövqedən yazmışdır','Hər ikisi ancaq təmsil yazmışdır','Biri şair, digəri bəstəkar olmuşdur','Hər ikisi dünya ədəbiyyatı nümayəndəsidir'],1),
('edeb7-menevi#28','edebiyyat','edeb-7-menevi',3,2,'Aşağıdakı «parça - mənbə» cütlüklərindən hansı düzgündür?','«Manqurt» «Gün var əsrə bərabər» romanındandır.',array['«Manqurt» - «Gün var əsrə bərabər»','«Manqurt» - «Qorxulu nağıllar»','«Usta Bəxtiyar» - «Gün var əsrə bərabər»','«Anamın sözləri» - «Gün var əsrə bərabər»'],1),
('edeb7-menevi#29','edebiyyat','edeb-7-menevi',3,2,'«Manqurt» parçasının dünya oxucusuna doğma olmasının səbəbi nədir?','Yaddaşsızlıq problemi ümumbəşəri məsələ kimi qoyulmuşdur.',array['Problemin ümumbəşəri qoyulması','Parçanın qısa həcmli olması','Sənədli material olması','Uşaq nağılı olması'],1),
('edeb7-menevi#30','edebiyyat','edeb-7-menevi',3,2,'Didaktik əsər ilə lirik şeirin fərqi nədir?','Didaktik əsər öyüd verir, lirik şeir duyğu ifadə edir.',array['Biri öyüd verir, digəri duyğu ifadə edir','Biri duyğu ifadə edir, digəri öyüd verir','Hər ikisi ancaq öyüd verir','Hər ikisi ancaq duyğu ifadə edir'],1),
('edeb7-menevi#31','edebiyyat','edeb-7-menevi',3,2,'Aşağıdakı «şəxs - təxəllüs» cütlüklərindən hansı doğrudur?','Abbasqulu ağa Bakıxanovun təxəllüsü Qüdsidir.',array['Abbasqulu ağa Bakıxanov - Qüdsi','Abdulla Şaiq - Qüdsi','Abbasqulu ağa Bakıxanov - Hophop','Fikrət Qoca - Qüdsi'],1),
('edeb7-usaq#1','edebiyyat','edeb-7-usaq',1,3,'«Nurəddin» əsərinin müəllifi kimdir?','Əsərin müəllifi Süleyman Sani Axundovdur.',array['Süleyman Sani Axundov','Mir Cəlal','Ənvər Məmmədxanlı','Elçin Hüseynbəyli'],1),
('edeb7-usaq#2','edebiyyat','edeb-7-usaq',1,3,'«Qavroş» hansı yazıçının əsərindən götürülmüşdür?','Parça Viktor Hüqonun əsərindəndir.',array['Viktor Hüqonun','Mir Cəlalın','Çingiz Aytmatovun','Süleyman Sani Axundovun'],1),
('edeb7-usaq#3','edebiyyat','edeb-7-usaq',1,3,'Yeddinci sinifdə keçilən «Bahar» əsərinin müəllifi kimdir?','Əsərin müəllifi Mir Cəlaldır.',array['Mir Cəlal','Ənvər Məmmədxanlı','Elçin Hüseynbəyli','Viktor Hüqo'],1),
('edeb7-usaq#4','edebiyyat','edeb-7-usaq',1,3,'«Qızıl qönçələr» əsərinin müəllifi kimdir?','Əsərin müəllifi Ənvər Məmmədxanlıdır.',array['Ənvər Məmmədxanlı','Mir Cəlal','Süleyman Sani Axundov','Elçin Hüseynbəyli'],1),
('edeb7-usaq#5','edebiyyat','edeb-7-usaq',2,3,'«Nurəddin» hansı silsiləyə daxildir?','Əsər «Qorxulu nağıllar» silsiləsinə daxildir.',array['«Qorxulu nağıllar»','«Gün var əsrə bərabər»','«Səfillər»','«Xəmsə»'],1),
('edeb7-usaq#6','edebiyyat','edeb-7-usaq',2,3,'Nurəddin obrazı hansı vəziyyətdə olan uşaqdır?','O, yetim və kimsəsiz uşaqdır.',array['Yetim və kimsəsiz uşaq','Varlı ailənin oğlu','Saray uşağı','Xaricdən gələn qonaq'],1),
('edeb7-usaq#7','edebiyyat','edeb-7-usaq',2,3,'«Qavroş» hansı romandan götürülmüşdür?','Parça «Səfillər» romanındandır.',array['«Səfillər»','«Qorxulu nağıllar»','«Gün var əsrə bərabər»','«Gülüstani-İrəm»'],1),
('edeb7-usaq#8','edebiyyat','edeb-7-usaq',2,3,'Qavroş hansı şəhərin küçə uşağıdır?','Qavroş Paris küçələrinin uşağıdır.',array['Parisin','Londonun','Romanın','Bakının'],1),
('edeb7-usaq#9','edebiyyat','edeb-7-usaq',2,3,'Viktor Hüqo hansı ölkənin yazıçısıdır?','Viktor Hüqo Fransa yazıçısıdır.',array['Fransanın','İngiltərənin','Almaniyanın','İtaliyanın'],1),
('edeb7-usaq#10','edebiyyat','edeb-7-usaq',2,3,'Uşaq bölməsinin əsas mövzusu nədir?','Uşaq aləmi və uşaq taleyi mövzusudur.',array['Uşaq aləmi və uşaq taleyi','Dəniz ticarəti','Kosmos yarışı','Hərbi taktika'],1),
('edeb7-usaq#11','edebiyyat','edeb-7-usaq',2,3,'«Nəvə» əsərinin müəllifi kimdir?','Əsərin müəllifi Elçin Hüseynbəylidir.',array['Elçin Hüseynbəyli','Mir Cəlal','Ənvər Məmmədxanlı','Viktor Hüqo'],1),
('edeb7-usaq#12','edebiyyat','edeb-7-usaq',2,3,'«Qorxulu nağıllar» silsiləsinin əsas məqsədi nədir?','Yetim və kimsəsiz uşaqların ağır taleyini göstərməkdir.',array['Yetim uşaqların taleyini göstərmək','Ov qaydalarını öyrətmək','Ticarəti təbliğ etmək','Coğrafiya öyrətmək'],1),
('edeb7-usaq#13','edebiyyat','edeb-7-usaq',2,3,'Qavroş obrazı hansı keyfiyyəti ilə seçilir?','Cəsarəti və xeyirxahlığı ilə seçilir.',array['Cəsarəti və xeyirxahlığı','Xəsisliyi','Qorxaqlığı','Laqeydliyi'],1),
('edeb7-usaq#14','edebiyyat','edeb-7-usaq',2,3,'Uşaq ədəbiyyatının əsas vəzifəsi nədir?','Uşağa tərbiyə və dünyagörüşü verməkdir.',array['Tərbiyə və dünyagörüşü vermək','Ticarət öyrətmək','Hərbi hazırlıq vermək','Riyaziyyat öyrətmək'],1),
('edeb7-usaq#15','edebiyyat','edeb-7-usaq',2,3,'Mir Cəlal hansı ədəbi növdə tanınmışdır?','Mir Cəlal nəsrdə tanınmışdır.',array['Nəsrdə','Mənzum dramda','Qəsidədə','Aşıq şeirində'],1),
('edeb7-usaq#16','edebiyyat','edeb-7-usaq',2,3,'«Qavroş» parçasında uşağın taleyi necə göstərilir?','Yoxsulluq içində, lakin ruhdan düşmədən göstərilir.',array['Yoxsulluq içində, ruhdan düşmədən','Var-dövlət içində','Sarayda rahat şəraitdə','Xaricdə təhsil alarkən'],1),
('edeb7-usaq#17','edebiyyat','edeb-7-usaq',2,3,'Bədii əsərdə uşaq obrazının verilməsi nəyə imkan yaradır?','Cəmiyyətin vəziyyətini uşağın gözü ilə göstərməyə imkan verir.',array['Cəmiyyəti uşağın gözü ilə göstərməyə','Ordunun gücünü ölçməyə','Ticarətin həcmini saymağa','Coğrafi mövqeyi təyin etməyə'],1),
('edeb7-usaq#18','edebiyyat','edeb-7-usaq',2,3,'Elçin Hüseynbəyli hansı dövrün yazıçısıdır?','O, müasir dövrün yazıçısıdır.',array['Müasir dövrün','XII əsrin','XVI əsrin','XIX əsrin əvvəlinin'],1),
('edeb7-usaq#19','edebiyyat','edeb-7-usaq',2,3,'Ənvər Məmmədxanlı hansı ədəbi növdə çalışmışdır?','O, nəsr sahəsində çalışmışdır.',array['Nəsr sahəsində','Aşıq şeirində','Mənzum dramda','Elmi tənqiddə'],1),
('edeb7-usaq#20','edebiyyat','edeb-7-usaq',3,3,'Uşaq mövzusu üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Nurəddin» S.S.Axundovun, «Bahar» isə Mir Cəlalındır.',array['«Nurəddin» - Süleyman Sani Axundov','«Nurəddin» - Mir Cəlal','«Bahar» - Süleyman Sani Axundov','«Qavroş» - Mir Cəlal'],1),
('edeb7-usaq#21','edebiyyat','edeb-7-usaq',3,3,'Uşaq bölməsi haqqında hansı fikir SƏHVDİR?','«Qavroş» Viktor Hüqonun əsərindəndir.',array['«Qavroş» Mir Cəlalın əsəridir','«Qavroş» Viktor Hüqonun əsərindəndir','«Nurəddin» S.S.Axundovundur','«Nəvə» Elçin Hüseynbəylinindir'],1),
('edeb7-usaq#22','edebiyyat','edeb-7-usaq',3,3,'Nurəddin və Qavroş obrazlarının ortaq cəhəti nədir?','Hər ikisi çətin şəraitdə yaşayan uşaq obrazıdır.',array['Hər ikisi çətin şəraitdə yaşayan uşaqdır','Hər ikisi varlı ailə uşağıdır','Biri uşaq, digəri qoca obrazıdır','Hər ikisi saray mühitində böyüyür'],1),
('edeb7-usaq#23','edebiyyat','edeb-7-usaq',3,3,'«Qorxulu nağıllar» silsiləsinin belə adlandırılmasının səbəbi nədir?','Uşaq taleyinin ağır və acı olması bu adı doğurmuşdur.',array['Uşaq taleyinin ağır və acı olması','Qəhrəmanların sehrli olması','Hadisələrin gecə baş verməsi','Əsərlərin uzun olması'],1),
('edeb7-usaq#24','edebiyyat','edeb-7-usaq',3,3,'Aşağıdakı «parça - roman» cütlüklərindən hansı doğrudur?','«Qavroş» «Səfillər» romanından götürülmüşdür.',array['«Qavroş» - «Səfillər» romanı','«Qavroş» - «Qorxulu nağıllar»','«Nurəddin» - «Səfillər» romanı','«Bahar» - «Səfillər» romanı'],1),
('edeb7-usaq#25','edebiyyat','edeb-7-usaq',3,3,'Üç yazıçı yaşadıqları dövrün ardıcıllığı ilə necə düzülür? (1 - Elçin Hüseynbəyli, 2 - Viktor Hüqo, 3 - Süleyman Sani Axundov)','Hüqo XIX əsrdə, S.S.Axundov XIX əsrin sonu - XX əsrin əvvəlində, Elçin Hüseynbəyli isə müasir dövrdə yaşamışdır.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb7-usaq#26','edebiyyat','edeb-7-usaq',3,3,'Obrazlar haqqında aşağıdakı fikirlərdən hansı SƏHVDİR?','Qavroş küçədə yaşayan yoxsul uşaqdır.',array['Qavroş varlı ailənin uşağıdır','Qavroş Paris küçələrinin uşağıdır','Nurəddin yetim uşaqdır','Hər iki obraz uşaq obrazıdır'],1),
('edeb7-usaq#27','edebiyyat','edeb-7-usaq',3,3,'Viktor Hüqo və Süleyman Sani Axundov haqqında hansı fikir doğrudur?','Hüqo fransız, S.S.Axundov isə Azərbaycan yazıçısıdır.',array['Hüqo fransız, Axundov Azərbaycan yazıçısıdır','Hüqo Azərbaycan, Axundov fransız yazıçısıdır','Hər ikisi fransız yazıçısıdır','Hər ikisi Azərbaycan yazıçısıdır'],1),
('edeb7-usaq#28','edebiyyat','edeb-7-usaq',3,3,'Aşağıdakı «obraz - ölkə» cütlüklərindən hansı düzgündür?','Qavroş fransız ədəbiyyatının obrazıdır.',array['Qavroş - Fransa','Nurəddin - Fransa','Qavroş - Azərbaycan','Manqurt - Fransa'],1),
('edeb7-usaq#29','edebiyyat','edeb-7-usaq',3,3,'Yazıçıların uşaq obrazına müraciət etməsinin səbəbi nədir?','Cəmiyyətdəki ədalətsizliyi daha kəskin göstərmək üçün.',array['Ədalətsizliyi kəskin göstərmək üçün','Əsəri qısaltmaq istəyi ilə','Dərslik tələbi ilə','Tərcüməni asanlaşdırmaq üçün'],1),
('edeb7-usaq#30','edebiyyat','edeb-7-usaq',3,3,'Uşaq ədəbiyyatı ilə uşaq haqqında ədəbiyyatın fərqi nədir?','Biri uşaq üçün, digəri uşaq haqqında yazılır.',array['Biri uşaq üçün, digəri uşaq haqqında yazılır','Biri uşaq haqqında, digəri uşaq üçün yazılır','İkisi arasında heç bir fərq yoxdur','Hər ikisi ancaq böyüklər üçün yazılır'],1),
('edeb7-usaq#31','edebiyyat','edeb-7-usaq',3,3,'Uşaq bölməsi üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?','«Nurəddin» nəsr əsəri, «Anamın sözləri» isə şeirdir.',array['«Nurəddin» - nəsr əsəri','«Nurəddin» - şeir','«Anamın sözləri» - nəsr əsəri','«Azərbaycan» - nəsr əsəri'],1),
('edeb7-tebiet#1','edebiyyat','edeb-7-tebiet',1,4,'«Yağış yağarkən» şeirinin müəllifi kimdir?','Şeirin müəllifi Mikayıl Müşfiqdir.',array['Mikayıl Müşfiq','Əliağa Kürçaylı','Hüseyn Arif','Bayram Həsənov'],1),
('edeb7-tebiet#2','edebiyyat','edeb-7-tebiet',1,4,'«Qaranquş» şeirinin müəllifi kimdir?','Şeirin müəllifi Əliağa Kürçaylıdır.',array['Əliağa Kürçaylı','Mikayıl Müşfiq','Hüseyn Arif','İlyas Əfəndiyev'],1),
('edeb7-tebiet#3','edebiyyat','edeb-7-tebiet',1,4,'«Şəhərdən gələn ovçu» əsərinin müəllifi kimdir?','Əsərin müəllifi İlyas Əfəndiyevdir.',array['İlyas Əfəndiyev','Bayram Həsənov','Hüseyn Arif','Mikayıl Müşfiq'],1),
('edeb7-tebiet#4','edebiyyat','edeb-7-tebiet',1,4,'Təbiət bölməsinin əsas mövzusu nədir?','Təbiətə vurğunluq və təbiətə qayğı mövzusudur.',array['Təbiətə vurğunluq və qayğı','Hərbi taktika','Ticarət qaydaları','Kosmos tədqiqatı'],1),
('edeb7-tebiet#5','edebiyyat','edeb-7-tebiet',2,4,'«İki bala» əsərinin müəllifi kimdir?','Əsərin müəllifi Bayram Həsənovdur.',array['Bayram Həsənov','Hüseyn Arif','Əliağa Kürçaylı','İlyas Əfəndiyev'],1),
('edeb7-tebiet#6','edebiyyat','edeb-7-tebiet',2,4,'«Yaşıl işıq» əsərinin müəllifi kimdir?','Əsərin müəllifi Hüseyn Arifdir.',array['Hüseyn Arif','Bayram Həsənov','Mikayıl Müşfiq','İlyas Əfəndiyev'],1),
('edeb7-tebiet#7','edebiyyat','edeb-7-tebiet',2,4,'«Yağış yağarkən» şeirində nə təsvir olunur?','Yağışlı təbiət mənzərəsi təsvir olunur.',array['Yağışlı təbiət mənzərəsi','Şəhər tikintisi','Dəniz döyüşü','Ticarət bazarı'],1),
('edeb7-tebiet#8','edebiyyat','edeb-7-tebiet',2,4,'Mikayıl Müşfiqin şeirlərində təbiət necə verilir?','Təbiət canlı, duyğulu obrazlarla verilir.',array['Canlı və duyğulu obrazlarla','Quru rəqəmlərlə','Sənədli hesabat kimi','Xəritə üzərində'],1),
('edeb7-tebiet#9','edebiyyat','edeb-7-tebiet',2,4,'«Şəhərdən gələn ovçu» hansı ədəbi növə aiddir?','Əsər nəsrə aiddir.',array['Nəsrə','Poeziyaya','Dramaturgiyaya','Publisistikaya'],1),
('edeb7-tebiet#10','edebiyyat','edeb-7-tebiet',2,4,'Təbiət mövzulu əsərlərin əsas çağırışı nədir?','Təbiəti qorumaq çağırışıdır.',array['Təbiəti qorumaq','Ov etməyi öyrənmək','Ticarəti artırmaq','Yeni şəhər salmaq'],1),
('edeb7-tebiet#11','edebiyyat','edeb-7-tebiet',2,4,'Qaranquş obrazı şeirdə nəyi bildirir?','Baharı və doğma yurdu bildirir.',array['Baharı və doğma yurdu','Qışın gəlişini','Ticarət yolunu','Döyüş nişanını'],1),
('edeb7-tebiet#12','edebiyyat','edeb-7-tebiet',2,4,'Əliağa Kürçaylı hansı ədəbi növdə çalışmışdır?','O, poeziyada çalışmışdır.',array['Poeziyada','Dramaturgiyada','Elmi nəsrdə','Publisistikada'],1),
('edeb7-tebiet#13','edebiyyat','edeb-7-tebiet',2,4,'İlyas Əfəndiyev hansı ədəbi növlərdə tanınmışdır?','O, həm nəsrdə, həm də dramaturgiyada tanınmışdır.',array['Həm nəsrdə, həm dramaturgiyada','Ancaq aşıq şeirində','Ancaq qəsidədə','Ancaq tərcümədə'],1),
('edeb7-tebiet#14','edebiyyat','edeb-7-tebiet',2,4,'Təbiət təsvirində hansı bədii vasitələr çox işlənir?','Epitet və bənzətmə çox işlənir.',array['Epitet və bənzətmə','Sənədli statistika','Riyazi düstur','Xəritə işarəsi'],1),
('edeb7-tebiet#15','edebiyyat','edeb-7-tebiet',2,4,'«Şəhərdən gələn ovçu» adı hansı ziddiyyəti göstərir?','Şəhər adamı ilə təbiət arasındakı ziddiyyəti göstərir.',array['Şəhər adamı ilə təbiət arasındakı','İki ölkə arasındakı','İki nəsil arasındakı','İki dil arasındakı'],1),
('edeb7-tebiet#16','edebiyyat','edeb-7-tebiet',2,4,'Peyzaj nədir?','Bədii əsərdə təbiət təsviridir.',array['Bədii əsərdə təbiət təsviri','Qəhrəmanın portreti','Əsərin sonluğu','Şeirin vəzni'],1),
('edeb7-tebiet#17','edebiyyat','edeb-7-tebiet',2,4,'Ekoloji mövzu ədəbiyyatda nəyi qabardır?','İnsanın təbiət qarşısındakı məsuliyyətini qabardır.',array['İnsanın təbiət qarşısında məsuliyyətini','Ticarətin faydasını','Hərbi gücü','Şəhər memarlığını'],1),
('edeb7-tebiet#18','edebiyyat','edeb-7-tebiet',2,4,'Hüseyn Arif hansı ədəbi növün nümayəndəsidir?','Hüseyn Arif poeziyanın nümayəndəsidir.',array['Poeziyanın','Dramaturgiyanın','Elmi nəsrin','Publisistikanın'],1),
('edeb7-tebiet#19','edebiyyat','edeb-7-tebiet',2,4,'Təbiət mövzulu şeirlərdə lirik qəhrəmanın münasibəti necə olur?','Sevgi və heyranlıq münasibəti olur.',array['Sevgi və heyranlıq','Tam laqeydlik','Qorxu və nifrət','Soyuq etinasızlıq'],1),
('edeb7-tebiet#20','edebiyyat','edeb-7-tebiet',3,4,'Təbiət bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Qaranquş» Kürçaylının, «Yağış yağarkən» isə Müşfiqindir.',array['«Qaranquş» - Əliağa Kürçaylı','«Qaranquş» - Hüseyn Arif','«Yağış yağarkən» - Əliağa Kürçaylı','«Yaşıl işıq» - Mikayıl Müşfiq'],1),
('edeb7-tebiet#21','edebiyyat','edeb-7-tebiet',3,4,'Təbiət bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Yağış yağarkən» Mikayıl Müşfiqin şeiridir.',array['«Yağış yağarkən» İlyas Əfəndiyevindir','«Yağış yağarkən» Mikayıl Müşfiqindir','«Qaranquş» Əliağa Kürçaylınındır','«Yaşıl işıq» Hüseyn Arifindir'],1),
('edeb7-tebiet#22','edebiyyat','edeb-7-tebiet',3,4,'Şeirdə və nəsrdə təbiət təsvirinin fərqi nədir?','Şeirdə duyğu, nəsrdə isə hadisə fonu kimi verilir.',array['Şeirdə duyğu, nəsrdə hadisə fonu kimi verilir','Şeirdə hadisə fonu, nəsrdə duyğu kimi verilir','Hər ikisində eyni cür verilir','Heç birində təbiət təsviri olmur'],1),
('edeb7-tebiet#23','edebiyyat','edeb-7-tebiet',3,4,'Təbiət mövzusunun müasir ədəbiyyatda güclənməsinin səbəbi nədir?','Ekoloji problemlərin kəskinləşməsi bu mövzunu gücləndirmişdir.',array['Ekoloji problemlərin kəskinləşməsi','Şəhərlərin sayının azalması','Ov ənənəsinin tamam bitməsi','Kitab sayının kəskin artması'],1),
('edeb7-tebiet#24','edebiyyat','edeb-7-tebiet',3,4,'Təbiət bölməsi üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?','«Şəhərdən gələn ovçu» nəsr, «Qaranquş» isə şeirdir.',array['«Şəhərdən gələn ovçu» - nəsr','«Şəhərdən gələn ovçu» - şeir','«Qaranquş» - nəsr','«Yağış yağarkən» - nəsr'],1),
('edeb7-tebiet#25','edebiyyat','edeb-7-tebiet',3,4,'Üç şair-yazıçı dövr baxımından necə düzülür? (1 - Mikayıl Müşfiq, 2 - müasir dövr müəllifləri, 3 - Əliağa Kürçaylı)','Müşfiq 1930-cu illərdə, Kürçaylı XX əsrin ikinci yarısında, müasir müəlliflər isə daha sonra yazmışdır.',array['3 - 1 - 2','1 - 2 - 3','2 - 1 - 3','2 - 3 - 1'],1),
('edeb7-tebiet#26','edebiyyat','edeb-7-tebiet',3,4,'Ədəbiyyat nəzəriyyəsi üzrə aşağıdakı fikirlərdən hansı SƏHVDİR?','Peyzaj təbiət təsviridir, qəhrəmanın portreti deyil.',array['Peyzaj qəhrəmanın portretidir','Peyzaj bədii əsərdə təbiət təsviridir','Epitet bədii təyin yaradır','Bənzətmə oxşarlığa əsaslanır'],1),
('edeb7-tebiet#27','edebiyyat','edeb-7-tebiet',3,4,'Mikayıl Müşfiq və Əliağa Kürçaylı haqqında hansı fikir doğrudur?','Hər ikisi şair kimi tanınmışdır.',array['Hər ikisi şair kimi tanınmışdır','Hər ikisi nasir kimi tanınmışdır','Biri şair, digəri dramaturq olmuşdur','Hər ikisi ancaq tərcüməçi olmuşdur'],1),
('edeb7-tebiet#28','edebiyyat','edeb-7-tebiet',3,4,'Təbiət təsviri üzrə «anlayış - tərif» cütlüyü hansı düzgündür?','Peyzaj təbiət təsviri, portret isə xarici görünüş təsviridir.',array['Peyzaj - təbiət təsviri','Portret - təbiət təsviri','Peyzaj - qəhrəmanın xarici görünüşü','Süjet - təbiət təsviri'],1),
('edeb7-tebiet#29','edebiyyat','edeb-7-tebiet',3,4,'«Şəhərdən gələn ovçu» adının seçilməsinin səbəbi nədir?','Ad şəhərlə təbiət arasındakı ziddiyyəti vurğulayır.',array['Şəhərlə təbiət ziddiyyətini vurğulamaq','Ov qaydalarını öyrətmək','Şəhər memarlığını təsvir etmək','Ticarət yolunu göstərmək'],1),
('edeb7-tebiet#30','edebiyyat','edeb-7-tebiet',3,4,'Təbiəti vəsf etmək ilə təbiəti qorumağa çağırmaq arasında fərq nədir?','Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir.',array['Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir','Biri məsuliyyət tələb edir, digəri gözəlliyi göstərir','Hər ikisi eyni məqsəd daşıyır','Hər ikisi ancaq gözəlliyi göstərir'],1),
('edeb7-tebiet#31','edebiyyat','edeb-7-tebiet',3,4,'Bu bölmə üzrə «şair - əsər» cütlüyü hansı doğrudur?','«Yaşıl işıq» Hüseyn Arifin əsəridir.',array['Hüseyn Arif - «Yaşıl işıq»','Hüseyn Arif - «Qaranquş»','Mikayıl Müşfiq - «Yaşıl işıq»','Bayram Həsənov - «Yaşıl işıq»'],1)
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
   where owner_type = 'platform' and ext_key like 'edeb7-%';
  if n <> 155 then
    raise exception 'Edebiyyat 7 suallari: 155 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb7-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb7-%';
  if k <> 5 then
    raise exception 'movzu sayi 5 deyil: %', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb7-%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 7 banki: % sual, 5 movzu (her birinde 12 cetin).', n;
end $$;
