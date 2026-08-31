-- =====================================================================
--  63_bank_edebiyyat6.sql : EDEBIYYAT 6 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat6.py yaradir:
--      python3 tools/edebiyyat6.py
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
           ('edeb-6-sifahi', 'edeb-6-tebiet')
     having count(*) = 2) then
    raise exception 'ONCE 61_movzular_edebiyyat5_8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb6-%';

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('edeb6-sifahi#1','edebiyyat','edeb-6-sifahi',1,1,'«Alı kişi» parçası hansı xalq dastanının hissəsidir?','Parça «Koroğlu» dastanındandır.',array['«Koroğlu»','«Kitabi-Dədə Qorqud»','«Əsli və Kərəm»','«Aşıq Qərib»'],1),
('edeb6-sifahi#2','edebiyyat','edeb-6-sifahi',1,1,'Alı kişi «Koroğlu» dastanında kimdir?','Alı kişi Koroğlunun atasıdır.',array['Koroğlunun atası','Koroğlunun oğlu','Düşmən xanı','Çənlibelin aşığı'],1),
('edeb6-sifahi#3','edebiyyat','edeb-6-sifahi',1,1,'Şifahi xalq ədəbiyyatı nümunələrini kim yaradır?','Onları xalq yaradır, konkret müəllifi olmur.',array['Xalq','Saray katibi','Xarici tərcüməçi','Dövlət məmuru'],1),
('edeb6-sifahi#4','edebiyyat','edeb-6-sifahi',1,1,'«Su həsrəti» mətni hansı ədəbiyyata aiddir?','Mətn şifahi xalq ədəbiyyatına aiddir.',array['Şifahi xalq ədəbiyyatına','Yazılı saray ədəbiyyatına','Elmi ədəbiyyata','Tərcümə ədəbiyyatına'],1),
('edeb6-sifahi#5','edebiyyat','edeb-6-sifahi',2,1,'Alı kişi hansı peşə sahibidir?','O, xanın ilxısına baxan ilxıçıdır.',array['İlxıçı','Dəmirçi','Dərzi','Karvan taciri'],1),
('edeb6-sifahi#6','edebiyyat','edeb-6-sifahi',2,1,'Alı kişinin başına gələn faciə nədir?','Onun gözləri kor edilir.',array['Gözlərinin kor edilməsi','Evinin yanması','Sürüsünün itməsi','Uzaq sürgünə göndərilməsi'],1),
('edeb6-sifahi#7','edebiyyat','edeb-6-sifahi',2,1,'Bu faciə Koroğlunun taleyində nəyə səbəb olur?','Koroğlunun zülmə qarşı üsyana qalxmasına səbəb olur.',array['Zülmə qarşı üsyana','Ticarətə başlamasına','Şəhərə köçməsinə','Uzaqda təhsil almasına'],1),
('edeb6-sifahi#8','edebiyyat','edeb-6-sifahi',2,1,'Şifahi xalq ədəbiyyatının yaşamasında kimlər rol oynayır?','Söyləyicilər və aşıqlar rol oynayır.',array['Söyləyicilər və aşıqlar','Saray katibləri','Xarici tərcüməçilər','Dövlət məmurları'],1),
('edeb6-sifahi#9','edebiyyat','edeb-6-sifahi',2,1,'Dastan hansı ədəbi növə aiddir?','Dastan epik növə aiddir.',array['Epik növə','Lirik növə','Dram növünə','Publisistikaya'],1),
('edeb6-sifahi#10','edebiyyat','edeb-6-sifahi',2,1,'Alı kişi obrazı hansı keyfiyyəti ilə yadda qalır?','Səbri və mərdliyi ilə yadda qalır.',array['Səbir və mərdlik','Xəsislik','Qorxaqlıq','Laqeydlik'],1),
('edeb6-sifahi#11','edebiyyat','edeb-6-sifahi',2,1,'Xalq yaradıcılığında hansı obrazlar çox işlənir?','Xeyirxah qəhrəman və zalım obrazı çox işlənir.',array['Xeyirxah qəhrəman və zalım obrazı','Ancaq saray adamları','Ancaq xarici tacirlər','Ancaq alimlər'],1),
('edeb6-sifahi#12','edebiyyat','edeb-6-sifahi',2,1,'«Qanlı daş» mətni hansı ədəbiyyata aiddir?','Bu mətn də şifahi xalq ədəbiyyatına aiddir.',array['Şifahi xalq ədəbiyyatına','Yazılı divan ədəbiyyatına','Elmi ədəbiyyata','Xarici tərcümə ədəbiyyatına'],1),
('edeb6-sifahi#13','edebiyyat','edeb-6-sifahi',2,1,'Dastan söyləyən xalq sənətkarı necə adlanır?','O, aşıq adlanır.',array['Aşıq','Rəssam','Memar','Bəstəkar'],1),
('edeb6-sifahi#14','edebiyyat','edeb-6-sifahi',2,1,'Xalq yaradıcılığı nümunələri necə nəsildən-nəslə ötürülür?','Şifahi yolla, söyləyicilər vasitəsilə ötürülür.',array['Şifahi yolla','Rəsmi sənədlərlə','Xarici tərcümələrlə','Ancaq məktəb dərsliyi ilə'],1),
('edeb6-sifahi#15','edebiyyat','edeb-6-sifahi',2,1,'Koroğlu obrazı hansı ideyanı daşıyır?','Ədalət və azadlıq ideyasını daşıyır.',array['Ədalət və azadlıq','Var-dövlət toplamaq','Saray xidməti','Ticarət uğuru'],1),
('edeb6-sifahi#16','edebiyyat','edeb-6-sifahi',2,1,'«Alı kişi» parçasında ata-oğul münasibəti necə verilir?','Oğul atasının haqqını qorumağa hazırlaşır.',array['Oğul atasının haqqını qorumağa hazırlaşır','Oğul atasını tərk edir','Ata oğlunu evdən qovur','Ata və oğul ticarətə başlayır'],1),
('edeb6-sifahi#17','edebiyyat','edeb-6-sifahi',2,1,'Bu bölmədə hansı növ nümunələr toplanmışdır?','Bölmədə xalq yaradıcılığı nümunələri toplanmışdır.',array['Xalq yaradıcılığı nümunələri','Saray şeirləri','Elmi məqalələr','Xarici tərcümələr'],1),
('edeb6-sifahi#18','edebiyyat','edeb-6-sifahi',2,1,'Xalq qəhrəmanı obrazı adətən kimin tərəfini tutur?','O, zəiflərin və məzlumların tərəfini tutur.',array['Zəiflərin və məzlumların','Varlı bəylərin','Xarici tacirlərin','Saray əyanlarının'],1),
('edeb6-sifahi#19','edebiyyat','edeb-6-sifahi',2,1,'Dastanlarda söz və musiqi necə birləşir?','Aşıq dastanı sazın müşayiəti ilə söyləyir.',array['Aşıq sazın müşayiəti ilə söyləyir','Mətn ancaq oxunur','Musiqi ayrıca ifa olunur','Mətn yazılı paylanır'],1),
('edeb6-sifahi#20','edebiyyat','edeb-6-sifahi',3,1,'Altıncı sinif materialı üzrə «obraz - rol» cütlüyü hansı düzgündür?','Alı kişi Koroğlunun atasıdır.',array['Alı kişi - Koroğlunun atası','Alı kişi - Koroğlunun oğlu','Həsən xan - Koroğlunun atası','Nigar xanım - Koroğlunun atası'],1),
('edeb6-sifahi#21','edebiyyat','edeb-6-sifahi',3,1,'Şifahi ədəbiyyat bölməsi barədə hansı fikir SƏHVDİR?','«Alı kişi» «Koroğlu» dastanının hissəsidir.',array['«Alı kişi» «Dədə Qorqud» dastanındandır','«Alı kişi» «Koroğlu» dastanındandır','Alı kişi Koroğlunun atasıdır','Dastan şifahi yolla yayılır'],1),
('edeb6-sifahi#22','edebiyyat','edeb-6-sifahi',3,1,'Xalq qəhrəmanı ilə saray qəhrəmanının fərqi nədir?','Xalq qəhrəmanı xalqın, saray qəhrəmanı hakimiyyətin tərəfindədir.',array['Biri xalqın, digəri hakimiyyətin tərəfindədir','Biri hakimiyyətin, digəri xalqın tərəfindədir','Hər ikisi xalqın tərəfindədir','Hər ikisi hakimiyyətin tərəfindədir'],1),
('edeb6-sifahi#23','edebiyyat','edeb-6-sifahi',3,1,'Alı kişinin başına gələn faciənin dastandakı rolu nədir?','Bu faciə Koroğlunun üsyanına başlanğıc verir.',array['Koroğlunun üsyanına səbəb olması','Ticarətin başlanmasına səbəb olması','Yeni şəhərin salınmasına səbəb olması','Toyun təxirə düşməsinə səbəb olması'],1),
('edeb6-sifahi#24','edebiyyat','edeb-6-sifahi',3,1,'Şifahi ədəbiyyat üzrə «əsər - növ» cütlüyü hansı doğrudur?','«Koroğlu» xalq dastanıdır.',array['«Koroğlu» - xalq dastanı','«Koroğlu» - yazılı roman','«Kozetta» - xalq dastanı','«Qaz və Durna» - xalq dastanı'],1),
('edeb6-sifahi#25','edebiyyat','edeb-6-sifahi',3,1,'«Koroğlu» dastanında hadisələr necə sıralanır? (1 - Koroğlunun üsyana qalxması, 2 - Alı kişinin kor edilməsi, 3 - Çənlibelin qurulması)','Əvvəlcə Alı kişi kor edilir, sonra Koroğlu üsyana qalxır, sonra Çənlibel qurulur.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb6-sifahi#26','edebiyyat','edeb-6-sifahi',3,1,'Altıncı sinifdə xalq yaradıcılığı barədə hansı fikir SƏHVDİR?','Xalq yaradıcılığı ilk növbədə şifahi yolla yayılır.',array['Bu nümunələr ancaq yazılı yayılır','Xalq yaradıcılığının müəllifi bilinmir','Aşıq dastanı sazla söyləyir','Dastan epik növə aiddir'],1),
('edeb6-sifahi#27','edebiyyat','edeb-6-sifahi',3,1,'Alı kişi və Koroğlu obrazları haqqında hansı fikir doğrudur?','Alı kişi ata, Koroğlu isə onun oğludur.',array['Alı kişi ata, Koroğlu isə oğuldur','Alı kişi oğul, Koroğlu isə atadır','Hər ikisi qardaşdır','Aralarında qohumluq yoxdur'],1),
('edeb6-sifahi#28','edebiyyat','edeb-6-sifahi',3,1,'Aşağıdakı «sənətkar - alət» cütlüklərindən hansı düzgündür?','Aşığın əsas aləti sazdır.',array['Aşıq - saz','Aşıq - tar','Aşıq - kaman','Aşıq - piano'],1),
('edeb6-sifahi#29','edebiyyat','edeb-6-sifahi',3,1,'Xalq dastanlarının uzun əsrlər yaşamasının səbəbi nədir?','Onlar xalqın arzu və ideallarını ifadə etdiyi üçün yaşayır.',array['Xalqın arzularını ifadə etməsi','Kitab şəklində çap olunması','Məktəbdə əzbərlədilməsi','Xarici dilə tərcümə olunması'],1),
('edeb6-sifahi#30','edebiyyat','edeb-6-sifahi',3,1,'Dastanla nağılın quruluşca fərqi nədir?','Dastanda nəzm parçaları olur, nağıl bütövlükdə nəsrdir.',array['Dastanda nəzm parçaları olur','Nağılda nəzm parçaları olur','Hər ikisində nəzm parçaları olur','Heç birində nəzm parçası olmur'],1),
('edeb6-sifahi#31','edebiyyat','edeb-6-sifahi',3,1,'Aşağıdakı «əsər - qəhrəman» cütlüklərindən hansı doğrudur?','Koroğlu Alı kişinin oğludur.',array['«Koroğlu» - Alı kişinin oğlu','«Kozetta» - Alı kişinin oğlu','«Koroğlu» - Jan Valjan','«Balaca qara balıq» - Alı kişi'],1),
('edeb6-usaq#1','edebiyyat','edeb-6-usaq',1,2,'«Kozetta» parçasının müəllifi kimdir?','Parçanın müəllifi Viktor Hüqodur.',array['Viktor Hüqo','Zahid Xəlil','Naibə Yusif','Səməd Behrəngi'],1),
('edeb6-usaq#2','edebiyyat','edeb-6-usaq',1,2,'«Dostlar» əsərinin müəllifi kimdir?','Əsərin müəllifi Zahid Xəlildir.',array['Zahid Xəlil','Naibə Yusif','Viktor Hüqo','Mahirə Nağıqızı'],1),
('edeb6-usaq#3','edebiyyat','edeb-6-usaq',1,2,'«Dərs» əsərinin müəllifi kimdir?','Əsərin müəllifi Naibə Yusifdir.',array['Naibə Yusif','Zahid Xəlil','Viktor Hüqo','Ramiz Qusarçaylı'],1),
('edeb6-usaq#4','edebiyyat','edeb-6-usaq',1,2,'Altıncı sinif uşaq bölməsi nədən bəhs edir?','Uşaq düşüncəsi və uşaq dünyası mövzusudur.',array['Uşaq düşüncəsi və uşaq dünyası','Hərbi taktika','Ticarət qaydaları','Kosmos tədqiqatı'],1),
('edeb6-usaq#5','edebiyyat','edeb-6-usaq',2,2,'Kozetta obrazı hansı romanın qəhrəmanıdır?','Kozetta «Səfillər» romanının qəhrəmanıdır.',array['«Səfillər»','«Qorxulu nağıllar»','«Gün var əsrə bərabər»','«Ağ dəvə»'],1),
('edeb6-usaq#6','edebiyyat','edeb-6-usaq',2,2,'Kozetta hansı vəziyyətdə olan qızdır?','O, yetim və əziyyət çəkən qızdır.',array['Yetim və əziyyət çəkən','Varlı ailənin qızı','Saray xanımı','Xaricdən gələn qonaq'],1),
('edeb6-usaq#7','edebiyyat','edeb-6-usaq',2,2,'Kozettanı kim himayəsinə götürür?','Onu Jan Valjan himayəsinə götürür.',array['Jan Valjan','Qavroş','Tenardye','Marius'],1),
('edeb6-usaq#8','edebiyyat','edeb-6-usaq',2,2,'Kozettaya əziyyət verən ailənin adı nədir?','Ona Tenardyelər ailəsi əziyyət verir.',array['Tenardyelər','Valjanlar','Mariuslar','Hüqolar'],1),
('edeb6-usaq#9','edebiyyat','edeb-6-usaq',2,2,'Viktor Hüqo hansı əsrin yazıçısıdır?','O, XIX əsrin yazıçısıdır.',array['XIX əsrin','XII əsrin','XVI əsrin','XX əsrin sonunun'],1),
('edeb6-usaq#10','edebiyyat','edeb-6-usaq',2,2,'«Dostlar» əsəri hansı oxucu üçün yazılmışdır?','Əsər uşaq oxucular üçün yazılmışdır.',array['Uşaqlar üçün','Ancaq böyüklər üçün','Alimlər üçün','Hərbçilər üçün'],1),
('edeb6-usaq#11','edebiyyat','edeb-6-usaq',2,2,'Uşaq obrazı ədəbiyyatda niyə vacibdir?','Uşaq gözü dünyanı təmiz və saf göstərir.',array['Dünyanı təmiz gözlə göstərir','Ticarəti öyrədir','Hərbi taktika verir','Coğrafiya öyrədir'],1),
('edeb6-usaq#12','edebiyyat','edeb-6-usaq',2,2,'«Dərs» əsərinin adı nə ilə bağlıdır?','Ad qəhrəmanın aldığı həyat dərsi ilə bağlıdır.',array['Həyat dərsi ilə','Ticarət hesabı ilə','Hərbi təlimlə','Coğrafi xəritə ilə'],1),
('edeb6-usaq#13','edebiyyat','edeb-6-usaq',2,2,'Dostluq mövzusu uşaq ədəbiyyatında nəyi öyrədir?','Bir-birinə dayaq olmağı, sədaqəti öyrədir.',array['Bir-birinə dayaq olmağı','Rəqabət aparmağı','Xəsis olmağı','Laqeyd qalmağı'],1),
('edeb6-usaq#14','edebiyyat','edeb-6-usaq',2,2,'Kozettanın taleyi necə dəyişir?','O, himayəyə götürülərək ağır həyatdan xilas olur.',array['Himayəyə götürülüb xilas olur','Daha da ağırlaşır','Heç dəyişmir','Uzaq ölkəyə qaçır'],1),
('edeb6-usaq#15','edebiyyat','edeb-6-usaq',2,2,'Uşaq ədəbiyyatının dili necə olmalıdır?','Sadə və uşağa anlaşıqlı olmalıdır.',array['Sadə və anlaşıqlı','Ağır elmi dildə','Rəsmi sənəd dilində','Arxaik sözlərlə'],1),
('edeb6-usaq#16','edebiyyat','edeb-6-usaq',2,2,'Viktor Hüqo dünya ədəbiyyatında hansı ölkəni təmsil edir?','O, Fransanı təmsil edir.',array['Fransanı','İngiltərəni','İtaliyanı','İspaniyanı'],1),
('edeb6-usaq#17','edebiyyat','edeb-6-usaq',2,2,'Bu bölmədəki əsərlərdə hansı hisslər önə çıxır?','Mərhəmət və dostluq hissləri önə çıxır.',array['Mərhəmət və dostluq','Nifrət və qisas','Tam laqeydlik','Xəsislik'],1),
('edeb6-usaq#18','edebiyyat','edeb-6-usaq',2,2,'«Səfillər» romanının mövzusu nə ilə bağlıdır?','Roman yoxsulların, cəmiyyətin aşağı təbəqəsinin taleyi ilə bağlıdır.',array['Yoxsulların taleyi ilə','Saray həyatı ilə','Dəniz səfəri ilə','Kosmos tədqiqatı ilə'],1),
('edeb6-usaq#19','edebiyyat','edeb-6-usaq',2,2,'Uşaq obrazının çətinliklərə tab gətirməsi nəyi göstərir?','İnsan iradəsinin gücünü göstərir.',array['İnsan iradəsinin gücünü','Var-dövlətin əhəmiyyətini','Təsadüfün həlledici rolunu','Coğrafi şəraitin təsirini'],1),
('edeb6-usaq#20','edebiyyat','edeb-6-usaq',3,2,'Uşaq bölməsi üzrə «obraz - əsər» cütlüyü hansı düzgündür?','Kozetta «Səfillər» romanının obrazıdır.',array['Kozetta - «Səfillər»','Kozetta - «Dostlar»','Jan Valjan - «Dostlar»','Nurəddin - «Səfillər»'],1),
('edeb6-usaq#21','edebiyyat','edeb-6-usaq',3,2,'Kozetta obrazı barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Kozetta yetim və yoxsul qızdır.',array['Kozetta varlı ailənin qızıdır','Kozetta yetim qızdır','«Kozetta» Viktor Hüqonun əsərindəndir','Jan Valjan Kozettanı himayə edir'],1),
('edeb6-usaq#22','edebiyyat','edeb-6-usaq',3,2,'Kozetta və Qavroş obrazlarının ortaq cəhəti nədir?','Hər ikisi «Səfillər» romanının uşaq obrazıdır.',array['Hər ikisi «Səfillər» romanının uşaq obrazıdır','Hər ikisi varlı ailə uşağıdır','Biri uşaq, digəri böyük obrazıdır','Hər ikisi Azərbaycan ədəbiyyatındandır'],1),
('edeb6-usaq#23','edebiyyat','edeb-6-usaq',3,2,'Kozettanın əziyyət çəkməsinin səbəbi nədir?','O, yetim qalıb yad ailənin yanında yaşamağa məcbur olur.',array['Yetim qalıb yad ailədə yaşaması','Uzaq ölkəyə səfər etməsi','Məktəbi tərk etməsi','Ticarətdə uduzması'],1),
('edeb6-usaq#24','edebiyyat','edeb-6-usaq',3,2,'Uşaq bölməsi üzrə «obraz - rol» cütlüyü hansı doğrudur?','Jan Valjan Kozettanın himayədarıdır.',array['Jan Valjan - Kozettanın himayədarı','Tenardye - Kozettanın himayədarı','Jan Valjan - Kozettaya əziyyət verən','Qavroş - Kozettanın himayədarı'],1),
('edeb6-usaq#25','edebiyyat','edeb-6-usaq',3,2,'«Səfillər» romanında hadisələr necə sıralanır? (1 - Kozettanın xilas olunması, 2 - Kozettanın yetim qalması, 3 - yad ailənin yanında əziyyət çəkməsi)','Əvvəlcə qız yetim qalır, sonra yad ailədə əziyyət çəkir, sonra xilas olunur.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb6-usaq#26','edebiyyat','edeb-6-usaq',3,2,'Uşaq ədəbiyyatı barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Uşaq ədəbiyyatının dili sadə olmalıdır.',array['Uşaq ədəbiyyatının dili ağır elmi olmalıdır','Uşaq ədəbiyyatının dili sadə olmalıdır','Dostluq mövzusu bu ədəbiyyatda vacibdir','Uşaq obrazı dünyanı təmiz gözlə göstərir'],1),
('edeb6-usaq#27','edebiyyat','edeb-6-usaq',3,2,'Viktor Hüqo və Zahid Xəlil haqqında hansı fikir doğrudur?','Hüqo fransız, Zahid Xəlil isə Azərbaycan yazıçısıdır.',array['Hüqo fransız, Zahid Xəlil Azərbaycan yazıçısıdır','Hüqo Azərbaycan, Zahid Xəlil fransız yazıçısıdır','Hər ikisi fransız yazıçısıdır','Hər ikisi Azərbaycan yazıçısıdır'],1),
('edeb6-usaq#28','edebiyyat','edeb-6-usaq',3,2,'Uşaq bölməsi üzrə «əsər - müəllif» cütlüyü hansı doğrudur?','«Dostlar» Zahid Xəlilin, «Dərs» isə Naibə Yusifindir.',array['«Dostlar» - Zahid Xəlil','«Dostlar» - Naibə Yusif','«Dərs» - Zahid Xəlil','«Kozetta» - Zahid Xəlil'],1),
('edeb6-usaq#29','edebiyyat','edeb-6-usaq',3,2,'«Səfillər» romanının adının mənası nə ilə bağlıdır?','Ad cəmiyyətin ən yoxsul təbəqəsi ilə bağlıdır.',array['Cəmiyyətin ən yoxsul təbəqəsi ilə','Saray əyanlarının həyatı ilə','Dəniz səyyahları ilə','Elm adamlarının işi ilə'],1),
('edeb6-usaq#30','edebiyyat','edeb-6-usaq',3,2,'Uşaq obrazı ilə böyük obrazın bədii funksiyası necə fərqlənir?','Uşaq gözü hadisələri daha təmiz və birbaşa göstərir.',array['Uşaq gözü hadisələri daha təmiz göstərir','Böyük gözü hadisələri daha təmiz göstərir','Hər ikisi eyni funksiya daşıyır','Uşaq obrazı heç bir funksiya daşımır'],1),
('edeb6-usaq#31','edebiyyat','edeb-6-usaq',3,2,'Uşaq bölməsi üzrə «əsər - ədəbiyyat» cütlüyü hansı düzgündür?','«Kozetta» fransız ədəbiyyatına aiddir.',array['«Kozetta» - fransız ədəbiyyatı','«Dostlar» - fransız ədəbiyyatı','«Kozetta» - Azərbaycan ədəbiyyatı','«Dərs» - fransız ədəbiyyatı'],1),
('edeb6-yurd#1','edebiyyat','edeb-6-yurd',1,2,'«Azərbaycan bayrağı» şeirinin müəllifi kimdir?','Şeirin müəllifi Süleyman Abdulladır.',array['Süleyman Abdulla','Məmməd İsmayıl','Nəbi Xəzri','Eyvaz Zeynallı'],1),
('edeb6-yurd#2','edebiyyat','edeb-6-yurd',1,2,'«Vətən seçilməz» şeirinin müəllifi kimdir?','Şeirin müəllifi Məmməd İsmayıldır.',array['Məmməd İsmayıl','Nəbi Xəzri','Süleyman Abdulla','Mikayıl Rzaquluzadə'],1),
('edeb6-yurd#3','edebiyyat','edeb-6-yurd',1,2,'Altıncı sinifdə keçilən «İstiqlal marşı» şeirinin müəllifi kimdir?','Şeirin müəllifi Nəbi Xəzridir.',array['Nəbi Xəzri','Məmməd İsmayıl','Süleyman Abdulla','Eyvaz Zeynallı'],1),
('edeb6-yurd#4','edebiyyat','edeb-6-yurd',1,2,'Yurd bölməsinin əsas mövzusu nədir?','Yurd sevgisi və qəhrəmanlıq mövzusudur.',array['Yurd sevgisi və qəhrəmanlıq','Ticarət və sənaye','Kosmos və texnika','Dəniz macərası'],1),
('edeb6-yurd#5','edebiyyat','edeb-6-yurd',2,2,'«And» əsərinin müəllifi kimdir?','Əsərin müəllifi Mikayıl Rzaquluzadədir.',array['Mikayıl Rzaquluzadə','Eyvaz Zeynallı','Nəbi Xəzri','Süleyman Abdulla'],1),
('edeb6-yurd#6','edebiyyat','edeb-6-yurd',2,2,'«Tənha nar ağacı» əsərinin müəllifi kimdir?','Əsərin müəllifi Eyvaz Zeynallıdır.',array['Eyvaz Zeynallı','Mikayıl Rzaquluzadə','Məmməd İsmayıl','Nəbi Xəzri'],1),
('edeb6-yurd#7','edebiyyat','edeb-6-yurd',2,2,'Azərbaycan bayrağı neçə rənglidir?','Bayraq üçrənglidir.',array['Üç','İki','Dörd','Beş'],1),
('edeb6-yurd#8','edebiyyat','edeb-6-yurd',2,2,'Azərbaycan bayrağının ortasındakı nişanlar hansılardır?','Aypara və səkkizguşəli ulduzdur.',array['Aypara və səkkizguşəli ulduz','Qılınc və qalxan','Buğda sünbülü','Dəniz dalğası'],1),
('edeb6-yurd#9','edebiyyat','edeb-6-yurd',2,2,'Vətən mövzusunda yazılan şeirlərin əsas hissi nədir?','Vətənə sevgi və qürur hissidir.',array['Vətənə sevgi və qürur','Qorxu və nigarançılıq','Tam laqeydlik','Kədər və ümidsizlik'],1),
('edeb6-yurd#10','edebiyyat','edeb-6-yurd',2,2,'Nəbi Xəzri hansı ədəbi növün nümayəndəsidir?','Nəbi Xəzri poeziyanın nümayəndəsidir.',array['Poeziyanın','Dramaturgiyanın','Elmi nəsrin','Publisistikanın'],1),
('edeb6-yurd#11','edebiyyat','edeb-6-yurd',2,2,'«Vətən seçilməz» ifadəsi nə deməkdir?','Vətən doğulduğun yerdir, onu seçmək olmaz.',array['Vətən doğulduğun yerdir, seçilmir','Vətəni istənilən vaxt dəyişmək olar','Vətən ancaq coğrafi ərazidir','Vətən ticarət meydanıdır'],1),
('edeb6-yurd#12','edebiyyat','edeb-6-yurd',2,2,'Marş nədir?','Çağırış xarakterli, ruh yüksəkliyi verən əsərdir.',array['Çağırış xarakterli, ruhlandıran əsər','Kədərli xalq mahnısı','Uzun tarixi roman','Elmi məqalə'],1),
('edeb6-yurd#13','edebiyyat','edeb-6-yurd',2,2,'Bayraq bir dövlət üçün nəyi bildirir?','Müstəqilliyi və dövlətçiliyi bildirir.',array['Müstəqilliyi və dövlətçiliyi','Ticarətin həcmini','Əhalinin sayını','Ölkənin sahəsini'],1),
('edeb6-yurd#14','edebiyyat','edeb-6-yurd',2,2,'Məmməd İsmayıl hansı ədəbi növdə çalışır?','O, poeziyada çalışır.',array['Poeziyada','Dramaturgiyada','Elmi nəsrdə','Publisistikada'],1),
('edeb6-yurd#15','edebiyyat','edeb-6-yurd',2,2,'Bu bölmədəki şeirlərin əsas çağırışı nədir?','Vətəni sevmək və qorumaq çağırışıdır.',array['Vətəni sevmək və qorumaq','Ticarəti artırmaq','Yeni şəhər salmaq','Xaricə köçmək'],1),
('edeb6-yurd#16','edebiyyat','edeb-6-yurd',2,2,'Vətənpərvərlik şeirlərində hansı obraz tez-tez işlənir?','Bayraq və torpaq obrazı tez-tez işlənir.',array['Bayraq və torpaq obrazı','Dəniz gəmisi obrazı','Kosmos gəmisi obrazı','Ticarət karvanı obrazı'],1),
('edeb6-yurd#17','edebiyyat','edeb-6-yurd',2,2,'Dövlətin milli rəmzlərinə hansılar daxildir?','Bayraq, gerb və himn daxildir.',array['Bayraq, gerb, himn','Şeir, roman, dram','Saz, tar, kaman','Dağ, çay, göl'],1),
('edeb6-yurd#18','edebiyyat','edeb-6-yurd',2,2,'Vətən şeirlərində lirik qəhrəmanın münasibəti necə olur?','O, vətəni doğma və müqəddəs sayır.',array['Doğma və müqəddəs sayır','Yad bir yer sayır','Laqeyd yanaşır','Ticarət obyekti sayır'],1),
('edeb6-yurd#19','edebiyyat','edeb-6-yurd',2,2,'Bu bölmədəki əsərlər əsasən hansı ədəbi növdədir?','Bölmədə əsasən şeir nümunələri var.',array['Əsasən şeir','Ancaq roman','Ancaq dram','Ancaq elmi məqalə'],1),
('edeb6-yurd#20','edebiyyat','edeb-6-yurd',3,2,'Yurd bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Vətən seçilməz» Məmməd İsmayılın şeiridir.',array['«Vətən seçilməz» - Məmməd İsmayıl','«Vətən seçilməz» - Nəbi Xəzri','«Azərbaycan bayrağı» - Məmməd İsmayıl','«And» - Məmməd İsmayıl'],1),
('edeb6-yurd#21','edebiyyat','edeb-6-yurd',3,2,'Yurd bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Azərbaycan bayrağı» Süleyman Abdullanın şeiridir.',array['«Azərbaycan bayrağı» Nəbi Xəzrinindir','«Vətən seçilməz» Məmməd İsmayılındır','«And» Mikayıl Rzaquluzadənindir','«Tənha nar ağacı» Eyvaz Zeynallınındır'],1),
('edeb6-yurd#22','edebiyyat','edeb-6-yurd',3,2,'Bayraq və himn kimi rəmzlərin ədəbiyyatda yer alması nəyi göstərir?','Milli kimliyin ədəbiyyatda ifadə olunmasını göstərir.',array['Milli kimliyin bədii ifadəsini','Ticarətin genişləndiyini','Coğrafiyanın öyrənildiyini','Elmin sürətlə inkişaf etdiyini'],1),
('edeb6-yurd#23','edebiyyat','edeb-6-yurd',3,2,'Marş janrının çağırış ruhu daşımasının səbəbi nədir?','Marş kütləni birləşdirib ruhlandırmaq üçün yaranır.',array['Kütləni birləşdirmək məqsədi','Çox qısa həcmli olması','Nəsrlə yazılmış olması','Tərcüməsinin asan olması'],1),
('edeb6-yurd#24','edebiyyat','edeb-6-yurd',3,2,'Aşağıdakı «rəmz - məna» cütlüklərindən hansı doğrudur?','Bayraq dövlət müstəqilliyinin rəmzidir.',array['Bayraq - dövlət müstəqilliyi','Bayraq - ticarət nişanı','Himn - coğrafi xəritə','Gerb - şeir forması'],1),
('edeb6-yurd#25','edebiyyat','edeb-6-yurd',3,2,'Aşağıdakı üç hadisə zaman ardıcıllığı ilə necə düzülür? (1 - müstəqilliyin bərpası, 2 - Xalq Cümhuriyyətinin qurulması, 3 - günümüz)','Cümhuriyyət 1918-ci ildə qurulub, müstəqillik 1991-ci ildə bərpa olunub, sonra günümüzə gəlinib.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb6-yurd#26','edebiyyat','edeb-6-yurd',3,2,'Milli rəmzlər barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Saz, tar və kaman musiqi alətidir, milli dövlət rəmzi deyil.',array['Milli rəmzlərə saz, tar və kaman daxildir','Milli rəmzlərə bayraq daxildir','Milli rəmzlərə himn daxildir','Milli rəmzlərə gerb daxildir'],1),
('edeb6-yurd#27','edebiyyat','edeb-6-yurd',3,2,'Nəbi Xəzri və Məmməd İsmayıl haqqında hansı fikir doğrudur?','Hər ikisi şair kimi tanınır.',array['Hər ikisi şair kimi tanınır','Hər ikisi nasir kimi tanınır','Biri şair, digəri bəstəkardır','Hər ikisi dramaturq kimi tanınır'],1),
('edeb6-yurd#28','edebiyyat','edeb-6-yurd',3,2,'Yurd bölməsi üzrə «əsər - mövzu» cütlüyü hansı düzgündür?','«Azərbaycan bayrağı» milli rəmz mövzusundadır.',array['«Azərbaycan bayrağı» - milli rəmz','«Dostlar» - milli rəmz','«Azərbaycan bayrağı» - dostluq','«Kozetta» - milli rəmz'],1),
('edeb6-yurd#29','edebiyyat','edeb-6-yurd',3,2,'Şairlərin bayraq obrazına müraciət etməsinin səbəbi nədir?','Bayraq müstəqilliyi və dövlətçiliyi təcəssüm etdirir.',array['Bayrağın müstəqilliyi təcəssüm etdirməsi','Bayraq rənglərinin çox olması','Şeir yazmağın asan olması','Dərslik tələbinin olması'],1),
('edeb6-yurd#30','edebiyyat','edeb-6-yurd',3,2,'Adi şeir ilə marşın fərqi nədir?','Marş çağırış xarakterlidir və kütləvi ifa üçün nəzərdə tutulur.',array['Marş çağırış və kütləvi ifa üçündür','Adi şeir çağırış və kütləvi ifa üçündür','Hər ikisi eyni məqsəd daşıyır','Marş nəsrlə yazılır'],1),
('edeb6-yurd#31','edebiyyat','edeb-6-yurd',3,2,'Yurd bölməsi üzrə «şair - əsər» cütlüyü hansı doğrudur?','«İstiqlal marşı» şeiri Nəbi Xəzrinindir.',array['Nəbi Xəzri - «İstiqlal marşı»','Süleyman Abdulla - «İstiqlal marşı»','Nəbi Xəzri - «Vətən seçilməz»','Eyvaz Zeynallı - «İstiqlal marşı»'],1),
('edeb6-menevi#1','edebiyyat','edeb-6-menevi',1,3,'«Qurd və İlbiz» təmsilinin müəllifi kimdir?','Təmsilin müəllifi Abbasqulu ağa Bakıxanovdur.',array['Abbasqulu ağa Bakıxanov','Seyid Əzim Şirvani','Xəlil Rza Ulutürk','Mahirə Nağıqızı'],1),
('edeb6-menevi#2','edebiyyat','edeb-6-menevi',1,3,'«Qaz və Durna» təmsilinin müəllifi kimdir?','Təmsilin müəllifi Seyid Əzim Şirvanidir.',array['Seyid Əzim Şirvani','Abbasqulu ağa Bakıxanov','Səməd Behrəngi','Mahirə Nağıqızı'],1),
('edeb6-menevi#3','edebiyyat','edeb-6-menevi',1,3,'Altıncı sinifdə keçilən «Balaca qara balıq» əsərinin müəllifi kimdir?','Əsərin müəllifi Səməd Behrəngidir.',array['Səməd Behrəngi','Xəlil Rza Ulutürk','Naibə Yusif','Zahid Xəlil'],1),
('edeb6-menevi#4','edebiyyat','edeb-6-menevi',1,3,'«Ana dilim» şeirinin müəllifi kimdir?','Şeirin müəllifi Mahirə Nağıqızıdır.',array['Mahirə Nağıqızı','Xəlil Rza Ulutürk','Naibə Yusif','Seyid Əzim Şirvani'],1),
('edeb6-menevi#5','edebiyyat','edeb-6-menevi',2,3,'«Laylam mənim, nərəm mənim» şeirinin müəllifi kimdir?','Şeirin müəllifi Xəlil Rza Ulutürkdür.',array['Xəlil Rza Ulutürk','Mahirə Nağıqızı','Səməd Behrəngi','Abbasqulu ağa Bakıxanov'],1),
('edeb6-menevi#6','edebiyyat','edeb-6-menevi',2,3,'«Qurd və İlbiz» hansı janrdadır?','Əsər təmsil janrındadır.',array['Təmsil','Roman','Faciə','Qəsidə'],1),
('edeb6-menevi#7','edebiyyat','edeb-6-menevi',2,3,'Təmsildə əsasən hansı obrazlar iştirak edir?','Təmsildə əsasən heyvan obrazları iştirak edir.',array['Heyvan obrazları','Saray əyanları','Kosmos alimləri','Dəniz kapitanları'],1),
('edeb6-menevi#8','edebiyyat','edeb-6-menevi',2,3,'Səməd Behrəngi harada yaşayıb-yaratmışdır?','O, Cənubi Azərbaycanda - İranda yaşayıb-yaratmışdır.',array['Cənubi Azərbaycanda','Türkiyədə','Rusiyada','Fransada'],1),
('edeb6-menevi#9','edebiyyat','edeb-6-menevi',2,3,'«Balaca qara balıq» nağılında qəhrəman hara üz tutur?','Balaca balıq çayı tərk edib dənizə üz tutur.',array['Dənizə','Dağa','Səhraya','Meşəyə'],1),
('edeb6-menevi#10','edebiyyat','edeb-6-menevi',2,3,'Balaca qara balığın əsas məqsədi nədir?','Dünyanı görmək, çayın sonunu tapmaqdır.',array['Dünyanı görmək və axtarmaq','Var-dövlət toplamaq','Rahat yaşamaq','Başqalarına hökm etmək'],1),
('edeb6-menevi#11','edebiyyat','edeb-6-menevi',2,3,'«Ana dilim» şeirinin mövzusu nədir?','Ana dilinə məhəbbət mövzusudur.',array['Ana dilinə məhəbbət','Dəniz səfəri','Ticarət uğuru','Kosmos tədqiqatı'],1),
('edeb6-menevi#12','edebiyyat','edeb-6-menevi',2,3,'Ana dili insan üçün niyə vacibdir?','Ana dili milli kimliyin əsasıdır.',array['Milli kimliyin əsası olduğu üçün','Ticarəti asanlaşdırdığı üçün','Səfəri qısaltdığı üçün','Hesab aparmağa kömək etdiyi üçün'],1),
('edeb6-menevi#13','edebiyyat','edeb-6-menevi',2,3,'Altıncı sinifdə mənəvi dəyərlər bölməsi nədən bəhs edir?','Mənəvi dəyərlər və yaşayan hikmətlərdir.',array['Mənəvi dəyərlər və hikmətlər','Sənaye tikintisi','Dəniz ticarəti','Hərbi taktika'],1),
('edeb6-menevi#14','edebiyyat','edeb-6-menevi',2,3,'Təmsilin dili necə olur?','Yığcam, obrazlı və anlaşıqlı olur.',array['Yığcam və obrazlı','Uzun və mürəkkəb','Elmi terminlərlə dolu','Rəsmi sənəd dilində'],1),
('edeb6-menevi#15','edebiyyat','edeb-6-menevi',2,3,'Xəlil Rza Ulutürk hansı ədəbi növün nümayəndəsidir?','O, poeziyanın nümayəndəsidir.',array['Poeziyanın','Dramaturgiyanın','Elmi nəsrin','Publisistikanın'],1),
('edeb6-menevi#16','edebiyyat','edeb-6-menevi',2,3,'Səməd Behrənginin nağılları kimlər üçün yazılıb?','Uşaqlar üçün yazılıb, lakin böyük ictimai məna daşıyır.',array['Uşaqlar üçün, böyük məna ilə','Ancaq alimlər üçün','Ancaq hərbçilər üçün','Ancaq tacirlər üçün'],1),
('edeb6-menevi#17','edebiyyat','edeb-6-menevi',2,3,'Təmsildə əxlaqi nəticə harada verilir?','Əxlaqi nəticə əsərin sonunda verilir.',array['Əsərin sonunda','Əsərin əvvəlində','Əsərin ortasında','Ümumiyyətlə verilmir'],1),
('edeb6-menevi#18','edebiyyat','edeb-6-menevi',2,3,'Abbasqulu ağa Bakıxanov hansı dövrün nümayəndəsidir?','O, XIX əsr maarifçiliyinin nümayəndəsidir.',array['XIX əsr maarifçiliyinin','XII əsr intibahının','XVI əsr klassikasının','XX əsr romantizminin'],1),
('edeb6-menevi#19','edebiyyat','edeb-6-menevi',2,3,'Balaca qara balığın yolunda hansı təhlükələr olur?','Onu ovlamaq istəyən güclü canlılar təhlükə yaradır.',array['Onu ovlamaq istəyən canlılar','Ticarət rəqibləri','Məktəb imtahanları','Uzaq qohumları'],1),
('edeb6-menevi#20','edebiyyat','edeb-6-menevi',3,3,'Təmsil müəllifləri üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Qurd və İlbiz» Bakıxanovun, «Qaz və Durna» Şirvaninindir.',array['«Qurd və İlbiz» - Bakıxanov','«Qurd və İlbiz» - Seyid Əzim Şirvani','«Qaz və Durna» - Bakıxanov','«Ana dilim» - Bakıxanov'],1),
('edeb6-menevi#21','edebiyyat','edeb-6-menevi',3,3,'Təmsil və nağıllar barədə hansı fikir SƏHVDİR?','«Balaca qara balıq» Səməd Behrənginin nağılıdır.',array['«Balaca qara balıq» Bakıxanovun əsəridir','«Qurd və İlbiz» təmsildir','«Ana dilim» Mahirə Nağıqızınındır','«Qaz və Durna» Şirvaninindir'],1),
('edeb6-menevi#22','edebiyyat','edeb-6-menevi',3,3,'Təmsil ilə lirik şeirin əsas fərqi nədir?','Təmsildə süjet və əxlaqi nəticə, lirik şeirdə duyğu əsasdır.',array['Təmsildə süjet və nəticə, şeirdə duyğu əsasdır','Təmsildə duyğu, şeirdə süjet əsasdır','Hər ikisində süjet əsasdır','Hər ikisi eyni quruluşdadır'],1),
('edeb6-menevi#23','edebiyyat','edeb-6-menevi',3,3,'Balaca qara balığın çayı tərk etməsinin səbəbi nədir?','O, dünyanı tanımaq, çayın sonunu görmək istəyir.',array['Dünyanı tanımaq istəyi','Yem tapa bilməməsi','Ailəsi ilə mübahisəsi','Suyun soyuması'],1),
('edeb6-menevi#24','edebiyyat','edeb-6-menevi',3,3,'Təmsillər üzrə «əsər - janr» cütlüyü hansı doğrudur?','«Qaz və Durna» təmsil, «Ana dilim» isə şeirdir.',array['«Qaz və Durna» - təmsil','«Ana dilim» - təmsil','«Qaz və Durna» - şeir','«Balaca qara balıq» - təmsil'],1),
('edeb6-menevi#25','edebiyyat','edeb-6-menevi',3,3,'Aşağıdakı üç müəllif dövr baxımından necə düzülür? (1 - Abbasqulu ağa Bakıxanov, 2 - Səməd Behrəngi, 3 - Seyid Əzim Şirvani)','Bakıxanov XIX əsrin birinci yarısında, Şirvani XIX əsrin ikinci yarısında, Behrəngi isə XX əsrdə yaşamışdır.',array['1 - 3 - 2','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb6-menevi#26','edebiyyat','edeb-6-menevi',3,3,'Təmsil janrı barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Təmsil yığcam əsərdir, uzun tarixi roman deyil.',array['Təmsil uzun tarixi romandır','Təmsildə heyvan obrazları iştirak edir','Təmsil əxlaqi nəticə ilə bitir','Təmsilin dili yığcam və obrazlıdır'],1),
('edeb6-menevi#27','edebiyyat','edeb-6-menevi',3,3,'Bakıxanov və Seyid Əzim Şirvani haqqında hansı fikir doğrudur?','Hər ikisi təmsil yazmış maarifçi sənətkardır.',array['Hər ikisi təmsil yazmış maarifçidir','Hər ikisi ancaq roman yazmışdır','Biri şair, digəri bəstəkardır','Hər ikisi dünya ədəbiyyatı nümayəndəsidir'],1),
('edeb6-menevi#28','edebiyyat','edeb-6-menevi',3,3,'Mənəvi dəyərlər üzrə «əsər - mövzu» cütlüyü hansı düzgündür?','«Ana dilim» ana dili mövzusundadır.',array['«Ana dilim» - ana dili','«Qurd və İlbiz» - ana dili','«Ana dilim» - dəniz səfəri','«Balaca qara balıq» - ana dili'],1),
('edeb6-menevi#29','edebiyyat','edeb-6-menevi',3,3,'«Balaca qara balıq» nağılının böyük məna daşımasının səbəbi nədir?','Nağıl azadlıq və axtarış ideyasını rəmzi şəkildə verir.',array['Azadlıq və axtarış ideyasını verməsi','Çox uzun həcmli olması','Sənədli material üzərində qurulması','Xarici dildə yazılmış olması'],1),
('edeb6-menevi#30','edebiyyat','edeb-6-menevi',3,3,'Ana dili mövzusunun ədəbiyyatda güclü olmasının səbəbi nədir?','Dil milli kimliyin və yaddaşın əsasıdır.',array['Dilin milli kimliyin əsası olması','Dilin ticarəti asanlaşdırması','Dilin səfəri qısaltması','Dilin hesab aparmağa kömək etməsi'],1),
('edeb6-menevi#31','edebiyyat','edeb-6-menevi',3,3,'Altıncı sinif üzrə «şair - əsər» cütlüyü hansı doğrudur?','«Laylam mənim, nərəm mənim» Xəlil Rza Ulutürkündür.',array['Xəlil Rza Ulutürk - «Laylam mənim, nərəm mənim»','Mahirə Nağıqızı - «Laylam mənim, nərəm mənim»','Xəlil Rza Ulutürk - «Ana dilim»','Səməd Behrəngi - «Ana dilim»'],1),
('edeb6-tebiet#1','edebiyyat','edeb-6-tebiet',1,4,'«Qəsd edilmiş gözəllik» əsərinin müəllifi kimdir?','Əsərin müəllifi Elçin Hüseynbəylidir.',array['Elçin Hüseynbəyli','Ramiz Qusarçaylı','Rahil Məmməd','Bayram Həsənov'],1),
('edeb6-tebiet#2','edebiyyat','edeb-6-tebiet',1,4,'«Payız» şeirinin müəllifi kimdir?','Şeirin müəllifi Ramiz Qusarçaylıdır.',array['Ramiz Qusarçaylı','Rahil Məmməd','Bayram Həsənov','Elçin Hüseynbəyli'],1),
('edeb6-tebiet#3','edebiyyat','edeb-6-tebiet',1,4,'«Bulaq başında» əsərinin müəllifi kimdir?','Əsərin müəllifi Bayram Həsənovdur.',array['Bayram Həsənov','Ramiz Qusarçaylı','Rahil Məmməd','Elçin Hüseynbəyli'],1),
('edeb6-tebiet#4','edebiyyat','edeb-6-tebiet',1,4,'Altıncı sinifdə təbiət bölməsinin əsas mövzusu nədir?','Təbiətin gözəlliyi və təbiətə qayğı mövzusudur.',array['Təbiətin gözəlliyi və qayğı','Hərbi taktika','Ticarət qaydaları','Kosmos tədqiqatı'],1),
('edeb6-tebiet#5','edebiyyat','edeb-6-tebiet',2,4,'«İlin qızıl fəsli» əsərinin müəllifi kimdir?','Əsərin müəllifi Rahil Məmməddir.',array['Rahil Məmməd','Bayram Həsənov','Ramiz Qusarçaylı','Elçin Hüseynbəyli'],1),
('edeb6-tebiet#6','edebiyyat','edeb-6-tebiet',2,4,'«İlin qızıl fəsli» ifadəsi hansı fəsli bildirir?','Bu ifadə payız fəslini bildirir.',array['Payızı','Qışı','Yazı','Yayı'],1),
('edeb6-tebiet#7','edebiyyat','edeb-6-tebiet',2,4,'«Qəsd edilmiş gözəllik» adı nəyə işarə edir?','Təbiət gözəlliyinə vurulan zərbəyə işarə edir.',array['Təbiətə vurulan zərbəyə','Ticarət uğursuzluğuna','Hərbi əməliyyata','Məktəb imtahanına'],1),
('edeb6-tebiet#8','edebiyyat','edeb-6-tebiet',2,4,'Təbiət haqqında yazılan əsərlər oxucunu nəyə çağırır?','Təbiəti qorumaq və ona qayğı göstərmək çağırışıdır.',array['Təbiəti qorumaq və qayğı göstərmək','Ov etməyi öyrənmək','Ticarəti artırmaq','Yeni şəhər salmaq'],1),
('edeb6-tebiet#9','edebiyyat','edeb-6-tebiet',2,4,'Payız fəslinin təsvirində hansı rənglər önə çıxır?','Sarı və qızılı rənglər önə çıxır.',array['Sarı və qızılı','Ağ və mavi','Qara və boz','Yaşıl və çəhrayı'],1),
('edeb6-tebiet#10','edebiyyat','edeb-6-tebiet',2,4,'Şeirdə təbiət təsvirinə nə deyilir?','Bədii əsərdə təbiət təsvirinə peyzaj deyilir.',array['Peyzaj','Portret','Süjet','Kompozisiya'],1),
('edeb6-tebiet#11','edebiyyat','edeb-6-tebiet',2,4,'Elçin Hüseynbəyli hansı ədəbi növdə yazır?','O, nəsrdə yazır.',array['Nəsrdə','Ancaq mənzum dramda','Ancaq qəsidədə','Ancaq aşıq şeirində'],1),
('edeb6-tebiet#12','edebiyyat','edeb-6-tebiet',2,4,'Ramiz Qusarçaylı hansı ədəbi növdə yazır?','O, şeir - poeziya sahəsində yazır.',array['Şeirdə','Dramaturgiyada','Elmi nəsrdə','Publisistikada'],1),
('edeb6-tebiet#13','edebiyyat','edeb-6-tebiet',2,4,'Təbiət mənzərəsini canlandıran bədii vasitələr hansılardır?','Epitet və bənzətmə çox işlənir.',array['Epitet və bənzətmə','Sənədli statistika','Riyazi düstur','Xəritə işarəsi'],1),
('edeb6-tebiet#14','edebiyyat','edeb-6-tebiet',2,4,'Ekologiya mövzusu ədəbiyyatda nəyi qabardır?','İnsanın təbiət qarşısındakı məsuliyyətini qabardır.',array['İnsanın təbiət qarşısında məsuliyyətini','Ticarətin faydasını','Hərbi gücü','Şəhər memarlığını'],1),
('edeb6-tebiet#15','edebiyyat','edeb-6-tebiet',2,4,'Bulaq obrazı xalq təfəkküründə nəyi bildirir?','Saflığı, təmizliyi və həyat mənbəyini bildirir.',array['Saflıq və həyat mənbəyi','Var-dövlət','Döyüş gücü','Ticarət yolu'],1),
('edeb6-tebiet#16','edebiyyat','edeb-6-tebiet',2,4,'Təbiət mövzulu şeirlərdə lirik qəhrəman necə görünür?','Təbiətə vurğun, ona həssas münasibət bəsləyən insan kimi görünür.',array['Təbiətə vurğun və həssas insan kimi','Laqeyd müşahidəçi kimi','Təbiətdən qorxan insan kimi','Ticarətçi kimi'],1),
('edeb6-tebiet#17','edebiyyat','edeb-6-tebiet',2,4,'Fəsillərin ədəbiyyatda təsviri nəyə xidmət edir?','İnsan əhvalını təbiət mənzərəsi ilə bağlamağa xidmət edir.',array['İnsan əhvalını təbiətlə bağlamağa','Hesab öyrətməyə','Xəritə çəkməyə','Ticarət planı qurmağa'],1),
('edeb6-tebiet#18','edebiyyat','edeb-6-tebiet',2,4,'Təbiət bölməsindəki əsərlər hansı ədəbi növlərdədir?','Bölmədə həm şeir, həm də nəsr nümunələri var.',array['Həm şeir, həm nəsr','Ancaq dram','Ancaq elmi məqalə','Ancaq tərcümə'],1),
('edeb6-tebiet#19','edebiyyat','edeb-6-tebiet',2,4,'Təbiət təsvirində epitet hansı vəzifəni yerinə yetirir?','Epitet təsvirə bədii təyin verib onu canlandırır.',array['Bədii təyin verib canlandırır','Hadisələri sıralayır','Vəzni müəyyən edir','Bəndləri sayır'],1),
('edeb6-tebiet#20','edebiyyat','edeb-6-tebiet',3,4,'Altıncı sinif təbiət bölməsi üzrə «əsər - müəllif» cütlüyü hansıdır?','«Payız» Ramiz Qusarçaylının, «Bulaq başında» Bayram Həsənovundur.',array['«Payız» - Ramiz Qusarçaylı','«Payız» - Bayram Həsənov','«Bulaq başında» - Ramiz Qusarçaylı','«İlin qızıl fəsli» - Ramiz Qusarçaylı'],1),
('edeb6-tebiet#21','edebiyyat','edeb-6-tebiet',3,4,'Altıncı sinif təbiət bölməsi barədə hansı fikir SƏHVDİR?','«Qəsd edilmiş gözəllik» Elçin Hüseynbəylinin əsəridir.',array['«Qəsd edilmiş gözəllik» Rahil Məmmədindir','«Payız» Ramiz Qusarçaylınındır','«Bulaq başında» Bayram Həsənovundur','«İlin qızıl fəsli» Rahil Məmmədindir'],1),
('edeb6-tebiet#22','edebiyyat','edeb-6-tebiet',3,4,'Şeirdə və nəsrdə təbiətin verilməsi necə fərqlənir?','Şeirdə duyğu, nəsrdə isə hadisə fonu kimi verilir.',array['Şeirdə duyğu, nəsrdə hadisə fonu kimi','Şeirdə hadisə fonu, nəsrdə duyğu kimi','Hər ikisində eyni cür verilir','Heç birində təbiət təsviri olmur'],1),
('edeb6-tebiet#23','edebiyyat','edeb-6-tebiet',3,4,'«Qəsd edilmiş gözəllik» adının seçilməsinin səbəbi nədir?','Ad təbiətə vurulan zərbəni kəskin şəkildə vurğulayır.',array['Təbiətə vurulan zərbəni vurğulamaq','Ov qaydalarını öyrətmək','Şəhər memarlığını təsvir etmək','Ticarət yolunu göstərmək'],1),
('edeb6-tebiet#24','edebiyyat','edeb-6-tebiet',3,4,'Təbiət bölməsi üzrə «anlayış - tərif» cütlüyü hansı doğrudur?','Peyzaj bədii əsərdə təbiət təsviridir.',array['Peyzaj - təbiət təsviri','Portret - təbiət təsviri','Peyzaj - qəhrəmanın xarici görünüşü','Süjet - təbiət təsviri'],1),
('edeb6-tebiet#25','edebiyyat','edeb-6-tebiet',3,4,'Fəsillər il ərzində necə sıralanır? (1 - payız, 2 - yaz, 3 - yay)','Yazdan sonra yay, yaydan sonra payız gəlir.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb6-tebiet#26','edebiyyat','edeb-6-tebiet',3,4,'Təbiət mövzusu barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Təbiət mövzulu əsərlər təbiəti qorumağa çağırır.',array['Təbiət mövzulu əsərlər ova çağırır','Təbiət mövzulu əsərlər qorumağa çağırır','Peyzaj təbiət təsviridir','Epitet bədii təyin yaradır'],1),
('edeb6-tebiet#27','edebiyyat','edeb-6-tebiet',3,4,'Ramiz Qusarçaylı və Elçin Hüseynbəyli haqqında hansı fikir doğrudur?','Biri poeziyada, digəri nəsrdə yazır.',array['Qusarçaylı poeziyada, Hüseynbəyli nəsrdə yazır','Qusarçaylı nəsrdə, Hüseynbəyli poeziyada yazır','Hər ikisi ancaq nəsrdə yazır','Hər ikisi ancaq poeziyada yazır'],1),
('edeb6-tebiet#28','edebiyyat','edeb-6-tebiet',3,4,'Təbiət bölməsi üzrə «əsər - fəsil» cütlüyü hansı düzgündür?','«İlin qızıl fəsli» payız fəsli ilə bağlıdır.',array['«İlin qızıl fəsli» - payız','«İlin qızıl fəsli» - qış','«Payız» - yaz fəsli','«Bulaq başında» - qış'],1),
('edeb6-tebiet#29','edebiyyat','edeb-6-tebiet',3,4,'Ədəbiyyatda ekoloji mövzunun güclənməsinin səbəbi nədir?','Təbiətə vurulan zərərin get-gedə artmasıdır.',array['Təbiətə vurulan zərərin artması','Şəhərlərin sayının azalması','Ov ənənəsinin tamam bitməsi','Kitab sayının kəskin artması'],1),
('edeb6-tebiet#30','edebiyyat','edeb-6-tebiet',3,4,'Təbiəti vəsf etmək ilə təbiəti qorumağa çağırmağın fərqi nədir?','Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir.',array['Biri gözəlliyi göstərir, digəri məsuliyyət tələb edir','Biri məsuliyyət tələb edir, digəri gözəlliyi göstərir','Hər ikisi eyni məqsəd daşıyır','Hər ikisi ancaq gözəlliyi göstərir'],1),
('edeb6-tebiet#31','edebiyyat','edeb-6-tebiet',3,4,'Təbiət bölməsi üzrə «obraz - məna» cütlüyü hansı doğrudur?','Bulaq obrazı saflığın və həyat mənbəyinin nişanıdır.',array['Bulaq - saflıq və həyat mənbəyi','Bulaq - döyüş gücü','Payız - yenidən doğuluş','Bulaq - ticarət yolu'],1)
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
   where owner_type = 'platform' and ext_key like 'edeb6-%';
  if n <> 155 then
    raise exception 'Edebiyyat 6 suallari: 155 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb6-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb6-%';
  if k <> 5 then
    raise exception 'movzu sayi 5 deyil: %', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb6-%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 6 banki: % sual, 5 movzu (her birinde 12 cetin).', n;
end $$;
