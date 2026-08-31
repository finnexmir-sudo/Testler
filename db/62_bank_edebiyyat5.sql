-- =====================================================================
--  62_bank_edebiyyat5.sql : EDEBIYYAT 5 BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/edebiyyat5.py yaradir:
--      python3 tools/edebiyyat5.py
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
           ('edeb-5-sifahi', 'edeb-5-tebiet')
     having count(*) = 2) then
    raise exception 'ONCE 61_movzular_edebiyyat5_8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'edeb5-%';

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('edeb5-sifahi#1','edebiyyat','edeb-5-sifahi',1,1,'«Ana maral» mətni hansı janrdadır?','«Ana maral» əfsanədir.',array['Əfsanə','Roman','Qəzəl','Dram'],1),
('edeb5-sifahi#2','edebiyyat','edeb-5-sifahi',1,1,'«Üç qardaş» hansı xalqın nağılıdır?','«Üç qardaş» özbək xalq nağılıdır.',array['Özbək xalqının','Fransız xalqının','Yunan xalqının','Alman xalqının'],1),
('edeb5-sifahi#3','edebiyyat','edeb-5-sifahi',1,1,'«Yetim İbrahimin nağılı» hansı janrdadır?','Bu, xalq nağılıdır.',array['Nağıl','Şeir','Faciə','Təmsil'],1),
('edeb5-sifahi#4','edebiyyat','edeb-5-sifahi',1,1,'Nağıl və əfsanələr kimin yaradıcılığının məhsuludur?','Onlar xalqın yaradıcılığının məhsuludur.',array['Xalqın','Bir saray şairinin','Xarici tərcüməçinin','Məktəb müəlliminin'],1),
('edeb5-sifahi#5','edebiyyat','edeb-5-sifahi',2,1,'«Xalq öz vətənini necə tapdı» hansı xalqın əfsanəsidir?','Bu, Şimali Amerika xalqının əfsanəsidir.',array['Şimali Amerika xalqının','Özbək xalqının','Yunan xalqının','Ərəb xalqının'],1),
('edeb5-sifahi#6','edebiyyat','edeb-5-sifahi',2,1,'Əfsanə nədir?','Real bir yerlə bağlı, qeyri-adi hadisəni izah edən şifahi əsərdir.',array['Qeyri-adi hadisəni izah edən şifahi əsər','Səhnə üçün yazılan əsər','Elmi məqalə','Uzun tarixi roman'],1),
('edeb5-sifahi#7','edebiyyat','edeb-5-sifahi',2,1,'Nağılın səciyyəvi cəhəti nədir?','Nağıl xəyali, uydurma hadisələr üzərində qurulur.',array['Xəyali hadisələr üzərində qurulması','Sənədli faktlara əsaslanması','Elmi dildə yazılması','Səhnə üçün nəzərdə tutulması'],1),
('edeb5-sifahi#8','edebiyyat','edeb-5-sifahi',2,1,'«Yetim İbrahimin nağılı»nın qəhrəmanı hansı vəziyyətdədir?','Qəhrəman yetim uşaqdır.',array['Yetim uşaqdır','Varlı tacirdir','Saray əyanıdır','Xarici elçidir'],1),
('edeb5-sifahi#9','edebiyyat','edeb-5-sifahi',2,1,'Nağılda qəhrəmanın qələbəsinə nə kömək edir?','Zəkası, cəsarəti və köməkçiləri kömək edir.',array['Zəka, cəsarət və köməkçilər','Var-dövləti','Yüksək vəzifəsi','Uzaq qohumları'],1),
('edeb5-sifahi#10','edebiyyat','edeb-5-sifahi',2,1,'«Ana maral» əfsanəsində hansı canlı əsas obrazdır?','Əsas obraz maraldır.',array['Maral','Qurd','Qartal','Balıq'],1),
('edeb5-sifahi#11','edebiyyat','edeb-5-sifahi',2,1,'«Üç qardaş» nağılında neçə qardaş iştirak edir?','Nağılda üç qardaş iştirak edir.',array['Üç','İki','Dörd','Yeddi'],1),
('edeb5-sifahi#12','edebiyyat','edeb-5-sifahi',2,1,'Şifahi ədəbiyyat nümunələri harada qorunub saxlanılır?','Onlar söyləyicilərin yaddaşında qorunur.',array['Söyləyicilərin yaddaşında','Dövlət arxivində','Muzey vitrinində','Xarici kitabxanada'],1),
('edeb5-sifahi#13','edebiyyat','edeb-5-sifahi',2,1,'Beşinci sinifdə şifahi ədəbiyyat bölməsi necə adlanır?','Bölmə «Şifahi xalq ədəbiyyatı inciləri» adlanır.',array['«Şifahi xalq ədəbiyyatı inciləri»','«Uşaq dünyası»','«Yurd sevgisi»','«Təbiətin gözəlliyi»'],1),
('edeb5-sifahi#14','edebiyyat','edeb-5-sifahi',2,1,'Nağıl hansı ədəbi növə aiddir?','Nağıl epik növə aiddir.',array['Epik növə','Lirik növə','Dram növünə','Publisistikaya'],1),
('edeb5-sifahi#15','edebiyyat','edeb-5-sifahi',2,1,'Xalq nağıllarında sehrli köməkçilər kimlərdir?','Qeyri-adi qüvvələr və köməyə gələn heyvanlardır.',array['Qeyri-adi qüvvələr və heyvanlar','Saray məmurları','Xarici tacirlər','Məktəb müəllimləri'],1),
('edeb5-sifahi#16','edebiyyat','edeb-5-sifahi',2,1,'Dərslikdə başqa xalqların nağıllarının verilməsi nəyi göstərir?','Xalqların yaradıcılığının bir-birinə yaxınlığını göstərir.',array['Xalqların yaradıcılığının yaxınlığını','Ticarətin genişliyini','Coğrafi məsafəni','Dil fərqini'],1),
('edeb5-sifahi#17','edebiyyat','edeb-5-sifahi',2,1,'Nağıl dili nə ilə seçilir?','Sadəliyi və obrazlılığı ilə seçilir.',array['Sadəliyi və obrazlılığı ilə','Elmi terminlərlə','Rəsmi ifadələrlə','Xarici sözlərlə'],1),
('edeb5-sifahi#18','edebiyyat','edeb-5-sifahi',2,1,'Nağılın sonunda qəhrəman nəyə nail olur?','O, arzusuna çatır, xeyir qalib gəlir.',array['Arzusuna çatır','Hər şeyi itirir','Vətənindən uzaqlaşır','Heç nə dəyişmir'],1),
('edeb5-sifahi#19','edebiyyat','edeb-5-sifahi',2,1,'Əfsanələr çox vaxt nə ilə bağlı olur?','Konkret bir dağ, qaya, çay və ya yer adı ilə bağlı olur.',array['Konkret yer və ya ad ilə','Riyazi hesablamalarla','Ticarət qaydaları ilə','Hərbi əmrlərlə'],1),
('edeb5-sifahi#20','edebiyyat','edeb-5-sifahi',3,1,'Beşinci sinif şifahi ədəbiyyat bölməsi üzrə «əsər - janr» cütlüyü hansı düzgündür?','«Ana maral» əfsanə, «Üç qardaş» isə nağıldır.',array['«Ana maral» - əfsanə','«Ana maral» - nağıl','«Üç qardaş» - əfsanə','«Yetim İbrahimin nağılı» - əfsanə'],1),
('edeb5-sifahi#21','edebiyyat','edeb-5-sifahi',3,1,'Şifahi ədəbiyyat inciləri barədə hansı fikir SƏHVDİR?','«Üç qardaş» özbək xalq nağılıdır.',array['«Üç qardaş» fransız nağılıdır','«Ana maral» əfsanədir','«Yetim İbrahimin nağılı» nağıldır','Nağıllar xalq yaradıcılığıdır'],1),
('edeb5-sifahi#22','edebiyyat','edeb-5-sifahi',3,1,'Əfsanə ilə nağılın əsas fərqi nədir?','Əfsanə real yerlə bağlanır, nağıl isə xəyali aləmdə keçir.',array['Əfsanə real yerlə bağlanır, nağıl xəyalidir','Nağıl real yerlə bağlanır, əfsanə xəyalidir','İkisi arasında heç bir fərq yoxdur','Hər ikisi sənədli əsərdir'],1),
('edeb5-sifahi#23','edebiyyat','edeb-5-sifahi',3,1,'Nağıllarda qəhrəmanın köməkçilərinin olmasının səbəbi nədir?','Xalq xeyirin tək qalmadığı fikrini ifadə edir.',array['Xeyirin tək qalmadığı fikri','Süjeti uzatmaq ehtiyacı','Tarixi sənəd tələbi','Coğrafi məlumat vermək'],1),
('edeb5-sifahi#24','edebiyyat','edeb-5-sifahi',3,1,'Aşağıdakı «əsər - xalq» cütlüklərindən hansı doğrudur?','«Üç qardaş» özbək, «Xalq öz vətənini necə tapdı» isə Şimali Amerika xalqının əsəridir.',array['«Üç qardaş» - özbək xalqı','«Üç qardaş» - Şimali Amerika xalqı','«Ana maral» - özbək xalqı','«Yetim İbrahimin nağılı» - özbək xalqı'],1),
('edeb5-sifahi#25','edebiyyat','edeb-5-sifahi',3,1,'Nağılda hadisələr necə sıralanır? (1 - qəhrəmanın çətinliklərlə üzləşməsi, 2 - qəhrəmanın yola düşməsi, 3 - qəhrəmanın arzusuna çatması)','Qəhrəman əvvəlcə yola düşür, sonra çətinliklərlə üzləşir, sonda arzusuna çatır.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb5-sifahi#26','edebiyyat','edeb-5-sifahi',3,1,'Şifahi ədəbiyyat barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Şifahi ədəbiyyatın konkret müəllifi olmur.',array['Şifahi ədəbiyyatın müəllifi dəqiq bilinir','Şifahi ədəbiyyat xalq yaradıcılığıdır','Nağıl epik növə aiddir','Əfsanə real yerlə bağlana bilir'],1),
('edeb5-sifahi#27','edebiyyat','edeb-5-sifahi',3,1,'«Ana maral» və «Yetim İbrahimin nağılı» arasındakı ortaq cəhət nədir?','Hər ikisi şifahi xalq ədəbiyyatı nümunəsidir.',array['Hər ikisi şifahi xalq ədəbiyyatındandır','Hər ikisi yazılı ədəbiyyata aiddir','Hər ikisi xarici müəllifin əsəridir','Hər ikisi şeirlə yazılıb'],1),
('edeb5-sifahi#28','edebiyyat','edeb-5-sifahi',3,1,'Aşağıdakı «anlayış - izah» cütlüklərindən hansı düzgündür?','Əfsanə qeyri-adi hadisəni izah edən şifahi əsərdir.',array['Əfsanə - qeyri-adi hadisənin izahı','Nağıl - sənədli tarixi mətn','Təmsil - uzun roman','Şeir - səhnə əsəri'],1),
('edeb5-sifahi#29','edebiyyat','edeb-5-sifahi',3,1,'Müxtəlif xalqların nağıllarının bir-birinə oxşamasının səbəbi nədir?','Bütün xalqların arzu və dəyərlərinin ortaq olmasıdır.',array['Arzu və dəyərlərin ortaq olması','Nağılların tərcümə edilməsi','Bir müəllifin yazması','Coğrafi qonşuluq'],1),
('edeb5-sifahi#30','edebiyyat','edeb-5-sifahi',3,1,'Nağıl qəhrəmanı ilə əfsanə qəhrəmanının fərqi nədir?','Əfsanə qəhrəmanı konkret yerlə, nağıl qəhrəmanı xəyali aləmlə bağlıdır.',array['Əfsanə qəhrəmanı konkret yerlə bağlıdır','Nağıl qəhrəmanı konkret yerlə bağlıdır','Hər ikisi eyni cür verilir','Hər ikisi tarixi şəxsiyyətdir'],1),
('edeb5-sifahi#31','edebiyyat','edeb-5-sifahi',3,1,'Beşinci sinif şifahi ədəbiyyat üzrə «əsər - obraz» cütlüyü hansıdır?','«Ana maral» əfsanəsinin əsas obrazı maraldır.',array['«Ana maral» - maral obrazı','«Üç qardaş» - maral obrazı','«Ana maral» - qurd obrazı','«Yetim İbrahimin nağılı» - maral obrazı'],1),
('edeb5-yurd#1','edebiyyat','edeb-5-yurd',1,1,'«Azərbaycan! Azərbaycan!» şeirinin müəllifi kimdir?','Şeirin müəllifi Əhməd Cavaddır.',array['Əhməd Cavad','Əli Tudə','Hüseyn Arif','Fikrət Qoca'],1),
('edeb5-yurd#2','edebiyyat','edeb-5-yurd',1,1,'«Analar» şeirinin müəllifi kimdir?','Şeirin müəllifi Hüseyn Arifdir.',array['Hüseyn Arif','Əhməd Cavad','Əli Tudə','Əhməd Cəmil'],1),
('edeb5-yurd#3','edebiyyat','edeb-5-yurd',1,1,'«Yaşayanlar görəcəkdir» şeirinin müəllifi kimdir?','Şeirin müəllifi Əli Tudədir.',array['Əli Tudə','Hüseyn Arif','Əhməd Cavad','Xəlil Rza Ulutürk'],1),
('edeb5-yurd#4','edebiyyat','edeb-5-yurd',1,1,'Beşinci sinifdə yurd bölməsinin mövzusu nədir?','Yurd sevgisi və ana məhəbbəti mövzusudur.',array['Yurd sevgisi və ana məhəbbəti','Ticarət və sənaye','Kosmos və texnika','Dəniz macərası'],1),
('edeb5-yurd#5','edebiyyat','edeb-5-yurd',2,1,'«Azərbaycan! Azərbaycan!» şeirində hansı hiss ifadə olunur?','Vətənə sonsuz məhəbbət hissi ifadə olunur.',array['Vətənə məhəbbət','Ticarət həvəsi','Ov təəssüratı','Elmi maraq'],1),
('edeb5-yurd#6','edebiyyat','edeb-5-yurd',2,1,'«Analar» şeirinin mövzusu nədir?','Ana məhəbbəti və ananın fədakarlığıdır.',array['Ana məhəbbəti və fədakarlıq','Dəniz səfəri','Şəhər memarlığı','Kosmos uçuşu'],1),
('edeb5-yurd#7','edebiyyat','edeb-5-yurd',2,1,'Əli Tudə hansı ədəbiyyatla bağlıdır?','O, Cənubi Azərbaycan mövzusu ilə bağlı şairdir.',array['Cənubi Azərbaycan mövzusu ilə','Dəniz ədəbiyyatı ilə','Elmi fantastika ilə','Detektiv janrı ilə'],1),
('edeb5-yurd#8','edebiyyat','edeb-5-yurd',2,1,'Bu bölmədəki əsərlər hansı ədəbi növə aiddir?','Bölmədəki əsərlər lirik növə - şeirə aiddir.',array['Lirik növə','Dram növünə','Publisistikaya','Elmi ədəbiyyata'],1),
('edeb5-yurd#9','edebiyyat','edeb-5-yurd',2,1,'Ana obrazı ədəbiyyatda çox vaxt nə ilə eyniləşdirilir?','Ana obrazı çox vaxt vətənlə eyniləşdirilir.',array['Vətənlə','Ticarətlə','Ordu ilə','Şəhərlə'],1),
('edeb5-yurd#10','edebiyyat','edeb-5-yurd',2,1,'Vətən mövzulu şeirlərdə lirik qəhrəman nə hiss edir?','Vətənə qürur və bağlılıq hiss edir.',array['Qürur və bağlılıq','Qorxu və narahatlıq','Laqeydlik','Peşmançılıq'],1),
('edeb5-yurd#11','edebiyyat','edeb-5-yurd',2,1,'Əhməd Cavad hansı dövrün şairidir?','O, XX əsrin əvvəllərinin şairidir.',array['XX əsrin əvvəlinin','XII əsrin','XVI əsrin','XIX əsrin əvvəlinin'],1),
('edeb5-yurd#12','edebiyyat','edeb-5-yurd',2,1,'Hüseyn Arif hansı ədəbi növdə yazmışdır?','O, şeir sahəsində yazmışdır.',array['Şeirdə','Elmi nəsrdə','Dramaturgiyada','Publisistikada'],1),
('edeb5-yurd#13','edebiyyat','edeb-5-yurd',2,1,'Şeirdə təkrarlanan misra və ifadələr nəyə xidmət edir?','Hissin gücləndirilməsinə xidmət edir.',array['Hissin gücləndirilməsinə','Səhifə sayının artmasına','Vəznin dəyişməsinə','Süjetin qurulmasına'],1),
('edeb5-yurd#14','edebiyyat','edeb-5-yurd',2,1,'Vətən sözü ədəbiyyatda hansı geniş mənada işlənir?','Doğulub böyüdüyün torpaq, xalq və dil mənasında işlənir.',array['Doğma torpaq, xalq və dil mənasında','Yalnız şəhər mənasında','Yalnız ev mənasında','Yalnız məktəb mənasında'],1),
('edeb5-yurd#15','edebiyyat','edeb-5-yurd',2,1,'«Yaşayanlar görəcəkdir» adı hansı ovqatı bildirir?','Gələcəyə ümid ovqatını bildirir.',array['Gələcəyə ümid','Keçmişə peşmançılıq','Ticarət hesabı','Elmi şübhə'],1),
('edeb5-yurd#16','edebiyyat','edeb-5-yurd',2,1,'Lirik şeirdə əsas nədir?','Duyğu və hissin ifadəsi əsasdır.',array['Duyğu və hissin ifadəsi','Uzun süjet','Sənədli fakt','Riyazi hesablama'],1),
('edeb5-yurd#17','edebiyyat','edeb-5-yurd',2,1,'Ana haqqında yazılan şeirlərdə hansı münasibət önə çıxır?','Sevgi, hörmət və minnətdarlıq münasibəti önə çıxır.',array['Sevgi, hörmət və minnətdarlıq','Laqeydlik','Rəqabət','Etinasızlıq'],1),
('edeb5-yurd#18','edebiyyat','edeb-5-yurd',2,1,'Şeirdə vətən obrazı necə canlandırılır?','Doğma, müqəddəs və gözəl bir varlıq kimi canlandırılır.',array['Doğma və müqəddəs varlıq kimi','Yad bir yer kimi','Ticarət meydanı kimi','Uzaq ada kimi'],1),
('edeb5-yurd#19','edebiyyat','edeb-5-yurd',2,1,'Beşinci sinifdə bu bölmə hansı adı daşıyır?','Bölmə «Yurd sevgisi, ana məhəbbəti» adlanır.',array['«Yurd sevgisi, ana məhəbbəti»','«Uşaq dünyası»','«Əməyə məhəbbət»','«Müharibə və insan haqqı»'],1),
('edeb5-yurd#20','edebiyyat','edeb-5-yurd',3,1,'Yurd bölməsi üzrə «şeir - müəllif» cütlüyü hansı düzgündür?','«Analar» Hüseyn Arifin, «Azərbaycan! Azərbaycan!» Əhməd Cavadındır.',array['«Analar» - Hüseyn Arif','«Analar» - Əhməd Cavad','«Azərbaycan! Azərbaycan!» - Hüseyn Arif','«Yaşayanlar görəcəkdir» - Hüseyn Arif'],1),
('edeb5-yurd#21','edebiyyat','edeb-5-yurd',3,1,'Beşinci sinif yurd bölməsi barədə hansı fikir SƏHVDİR?','«Yaşayanlar görəcəkdir» Əli Tudənin şeiridir.',array['«Yaşayanlar görəcəkdir» Hüseyn Arifindir','«Analar» Hüseyn Arifindir','«Azərbaycan! Azərbaycan!» Əhməd Cavadındır','Bölmənin mövzusu yurd sevgisidir'],1),
('edeb5-yurd#22','edebiyyat','edeb-5-yurd',3,1,'Ana obrazı ilə vətən obrazının ədəbiyyatda birləşməsinin səbəbi nədir?','Hər ikisi insan üçün doğma və müqəddəs sayılır.',array['Hər ikisinin doğma və müqəddəs sayılması','Hər ikisinin uzaqda olması','Hər ikisinin tarixi sənəd olması','Hər ikisinin ticarətlə bağlılığı'],1),
('edeb5-yurd#23','edebiyyat','edeb-5-yurd',3,1,'Lirik şeir ilə nağılın əsas fərqi nədir?','Şeirdə duyğu, nağılda isə hadisə əsasdır.',array['Şeirdə duyğu, nağılda hadisə əsasdır','Şeirdə hadisə, nağılda duyğu əsasdır','Hər ikisində duyğu əsasdır','Hər ikisində hadisə əsasdır'],1),
('edeb5-yurd#24','edebiyyat','edeb-5-yurd',3,1,'Aşağıdakı «şair - mövzu» cütlüklərindən hansı doğrudur?','Əli Tudənin yaradıcılığı Cənub mövzusu ilə bağlıdır.',array['Əli Tudə - Cənub mövzusu','Hüseyn Arif - Cənub mövzusu','Əli Tudə - kosmos mövzusu','Əhməd Cavad - dəniz macərası mövzusu'],1),
('edeb5-yurd#25','edebiyyat','edeb-5-yurd',3,1,'Şeirdə təkrarların işlədilməsinin səbəbi nədir?','Təkrar hissi gücləndirir və oxucunun yadında qalır.',array['Hissi gücləndirib yadda saxlatması','Səhifə sayını süni artırması','Şeirin vəznini dəyişməsi','Əsərin süjetini qurması'],1),
('edeb5-yurd#26','edebiyyat','edeb-5-yurd',3,1,'Ədəbi növlər barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Şeir lirik növə, nağıl isə epik növə aiddir.',array['Şeir epik növə aiddir','Nağıl epik növə aiddir','Şeir lirik növə aiddir','Dram ayrıca ədəbi növdür'],1),
('edeb5-yurd#27','edebiyyat','edeb-5-yurd',3,1,'Əhməd Cavad və Hüseyn Arif haqqında hansı fikir doğrudur?','Hər ikisi şair kimi tanınmışdır.',array['Hər ikisi şair kimi tanınmışdır','Hər ikisi nasir kimi tanınmışdır','Biri şair, digəri bəstəkardır','Hər ikisi dramaturqdur'],1),
('edeb5-yurd#28','edebiyyat','edeb-5-yurd',3,1,'Beşinci sinif yurd bölməsi üzrə «əsər - mövzu» cütlüyü hansıdır?','«Analar» ana məhəbbəti, «Azərbaycan! Azərbaycan!» vətən mövzusundadır.',array['«Analar» - ana məhəbbəti','«Azərbaycan! Azərbaycan!» - ana məhəbbəti','«Analar» - dəniz səfəri','«Analar» - kosmos mövzusu'],1),
('edeb5-yurd#29','edebiyyat','edeb-5-yurd',3,1,'Vətən mövzusunun beşinci sinif dərsliyinə salınmasının səbəbi nədir?','Şagirddə erkən yaşdan vətənə bağlılıq tərbiyə etməkdir.',array['Erkən yaşda vətənə bağlılıq tərbiyəsi','Dərslik həcminin artırılması','Xarici dil öyrətmək məqsədi','Riyazi bacarıq qazandırmaq'],1),
('edeb5-yurd#30','edebiyyat','edeb-5-yurd',3,1,'Şeirdə lirik qəhrəman ilə müəllif arasındakı əlaqə necədir?','Lirik qəhrəman müəllifin duyğularını ifadə edən obrazdır.',array['Müəllifin duyğularını ifadə edən obrazdır','Müəllifdən tamam ayrı bir şəxsdir','Ancaq nağıl qəhrəmanı sayılır','Ancaq dram personajı sayılır'],1),
('edeb5-yurd#31','edebiyyat','edeb-5-yurd',3,1,'Aşağıdakı «bölmə - mövzu» cütlüklərindən hansı doğrudur?','«Yurd sevgisi, ana məhəbbəti» bölməsi vətən və ana mövzusundadır.',array['Yurd bölməsi - vətən və ana mövzusu','Yurd bölməsi - təbiət mövzusu','Şifahi ədəbiyyat bölməsi - vətən və ana mövzusu','Yurd bölməsi - əmək mövzusu'],1),
('edeb5-menevi#1','edebiyyat','edeb-5-menevi',1,2,'«Kiş haqqında hekayət» əsərinin müəllifi kimdir?','Əsərin müəllifi Cek Londondur.',array['Cek London','Mark Tven','Ənvər Əlibəyli','Süleyman Rəhimov'],1),
('edeb5-menevi#2','edebiyyat','edeb-5-menevi',1,2,'«İlan və Qurbağa» əsərinin müəllifi kimdir?','Əsərin müəllifi Ənvər Əlibəylidir.',array['Ənvər Əlibəyli','Cek London','Mark Tven','Hüseyn Arif'],1),
('edeb5-menevi#3','edebiyyat','edeb-5-menevi',1,2,'«İlan və Qurbağa» hansı janrdadır?','Bu, təmsildir.',array['Təmsil','Roman','Faciə','Qəsidə'],1),
('edeb5-menevi#4','edebiyyat','edeb-5-menevi',1,2,'Cek London hansı ölkənin yazıçısıdır?','Cek London Amerika yazıçısıdır.',array['ABŞ-ın','Fransanın','Almaniyanın','İtaliyanın'],1),
('edeb5-menevi#5','edebiyyat','edeb-5-menevi',2,2,'Kiş obrazı hansı xalqın həyatından götürülüb?','O, şimal xalqlarının həyatından götürülmüş obrazdır.',array['Şimal xalqlarının','Ərəb xalqlarının','Hind xalqlarının','Afrika xalqlarının'],1),
('edeb5-menevi#6','edebiyyat','edeb-5-menevi',2,2,'Kiş ovda hansı üstünlüyü ilə seçilir?','O, güclə deyil, ağıl və hiylə ilə seçilir.',array['Ağıl və zəkası ilə','Yalnız bədən gücü ilə','Var-dövləti ilə','Yüksək vəzifəsi ilə'],1),
('edeb5-menevi#7','edebiyyat','edeb-5-menevi',2,2,'Kiş nəyin uğrunda mübarizə aparır?','Ailəsinin və özünün haqqı uğrunda mübarizə aparır.',array['Ailəsinin haqqı uğrunda','Uzaq səfər uğrunda','Ticarət yolu uğrunda','Saray vəzifəsi uğrunda'],1),
('edeb5-menevi#8','edebiyyat','edeb-5-menevi',2,2,'Kiş sonda hansı mövqe qazanır?','O, tayfada hörmət qazanıb başçı olur.',array['Tayfada hörmət qazanıb başçı olur','Vətənindən uzaqlaşır','Ovçuluqdan əl çəkir','Ticarətə başlayır'],1),
('edeb5-menevi#9','edebiyyat','edeb-5-menevi',2,2,'Təmsildə obrazlar kimi təmsil edir?','Heyvan obrazları insan xarakterlərini təmsil edir.',array['İnsan xarakterlərini','Coğrafi əraziləri','Tarixi hadisələri','Riyazi anlayışları'],1),
('edeb5-menevi#10','edebiyyat','edeb-5-menevi',2,2,'Təmsilin sonunda müəllif nə verir?','Müəllif əxlaqi nəticə verir.',array['Əxlaqi nəticə','Coğrafi xəritə','Riyazi düstur','Tarixi sənəd'],1),
('edeb5-menevi#11','edebiyyat','edeb-5-menevi',2,2,'Beşinci sinifdə bu bölmə necə adlanır?','Bölmə «Mənəvi dəyərlər, həmişəyaşar hikmətlər» adlanır.',array['«Mənəvi dəyərlər, həmişəyaşar hikmətlər»','«Uşaq dünyası, uşaq taleyi»','«Əməyə məhəbbət, zəhmətə çağırış»','«Təbiətin gözəlliyi, təbiətə qayğı»'],1),
('edeb5-menevi#12','edebiyyat','edeb-5-menevi',2,2,'Cek Londonun əsərlərində hansı mühit çox təsvir olunur?','Sərt şimal təbiəti və orada yaşayan insanlar təsvir olunur.',array['Sərt şimal təbiəti','İsti səhra','Böyük şəhər küçələri','Saray otaqları'],1),
('edeb5-menevi#13','edebiyyat','edeb-5-menevi',2,2,'«Kiş haqqında hekayət» hansı ədəbi növə aiddir?','Əsər epik növə - nəsrə aiddir.',array['Epik növə','Lirik növə','Dram növünə','Publisistikaya'],1),
('edeb5-menevi#14','edebiyyat','edeb-5-menevi',2,2,'Kiş obrazı gənclərə nə öyrədir?','Ədalət uğrunda ağılla mübarizə aparmağı öyrədir.',array['Ədalət uğrunda ağılla mübarizəni','Var-dövlət toplamağı','Səfərdən qaçmağı','Laqeyd qalmağı'],1),
('edeb5-menevi#15','edebiyyat','edeb-5-menevi',2,2,'Təmsildə hansı bədii üsul əsasdır?','Alleqoriya - obrazın rəmzi mənada işlədilməsi əsasdır.',array['Alleqoriya','Sənədli təsvir','Elmi şərh','Statistik hesabat'],1),
('edeb5-menevi#16','edebiyyat','edeb-5-menevi',2,2,'Ənvər Əlibəyli hansı oxucu üçün yazmışdır?','O, əsasən uşaq oxucular üçün yazmışdır.',array['Uşaqlar üçün','Ancaq alimlər üçün','Ancaq hərbçilər üçün','Ancaq tacirlər üçün'],1),
('edeb5-menevi#17','edebiyyat','edeb-5-menevi',2,2,'Bu bölmədəki əsərlər oxucuya nə verir?','Həyat hikməti və əxlaqi dərs verir.',array['Həyat hikməti və əxlaqi dərs','Ticarət təlimatı','Coğrafi məlumat','Hərbi bilik'],1),
('edeb5-menevi#18','edebiyyat','edeb-5-menevi',2,2,'Hikmət sözü nə deməkdir?','Dərin həyat müdrikliyi deməkdir.',array['Dərin həyat müdrikliyi','Uzun səfər','Böyük var-dövlət','Yüksək vəzifə'],1),
('edeb5-menevi#19','edebiyyat','edeb-5-menevi',2,2,'Kiş obrazının kiçik yaşda böyük iş görməsi nəyi göstərir?','Yaşın deyil, ağıl və iradənin həlledici olduğunu göstərir.',array['Ağıl və iradənin həlledici olduğunu','Var-dövlətin gücünü','Təsadüfün rolunu','Coğrafi şəraitin təsirini'],1),
('edeb5-menevi#20','edebiyyat','edeb-5-menevi',3,2,'Beşinci sinif hikmət bölməsi üzrə «əsər - müəllif» cütlüyü hansıdır?','«Kiş haqqında hekayət» Cek Londonun, «İlan və Qurbağa» Ənvər Əlibəylinindir.',array['«Kiş haqqında hekayət» - Cek London','«Kiş haqqında hekayət» - Mark Tven','«İlan və Qurbağa» - Cek London','«İlan və Qurbağa» - Mark Tven'],1),
('edeb5-menevi#21','edebiyyat','edeb-5-menevi',3,2,'Hikmət bölməsi haqqında hansı fikir SƏHVDİR?','«İlan və Qurbağa» təmsildir, roman deyil.',array['«İlan və Qurbağa» romandır','«İlan və Qurbağa» təmsildir','«Kiş haqqında hekayət» Cek Londonundur','Təmsildə heyvan obrazları olur'],1),
('edeb5-menevi#22','edebiyyat','edeb-5-menevi',3,2,'Təmsil ilə hekayənin əsas fərqi nədir?','Təmsildə obrazlar rəmzi, hekayədə isə real insanlardır.',array['Təmsildə obrazlar rəmzi, hekayədə realdır','Təmsildə obrazlar real, hekayədə rəmzidir','Hər ikisində obrazlar rəmzidir','Hər ikisində obrazlar realdır'],1),
('edeb5-menevi#23','edebiyyat','edeb-5-menevi',3,2,'Kişin tayfada hörmət qazanmasının səbəbi nədir?','O, ağlı və cəsarəti ilə ailəsinin haqqını qorudu.',array['Ağlı və cəsarəti ilə haqqı qoruması','Çoxlu var-dövlət toplaması','Uzaq ölkəyə səfərə çıxması','Hamıdan yaşca böyük olması'],1),
('edeb5-menevi#24','edebiyyat','edeb-5-menevi',3,2,'Beşinci sinif üzrə «əsər - ölkə» cütlüyü hansı doğrudur?','«Kiş haqqında hekayət» Amerika ədəbiyyatına aiddir.',array['«Kiş haqqında hekayət» - ABŞ','«Kiş haqqında hekayət» - Fransa','«İlan və Qurbağa» - ABŞ','«Analar» - ABŞ'],1),
('edeb5-menevi#25','edebiyyat','edeb-5-menevi',3,2,'Kiş haqqında hekayətdə hadisələr necə sıralanır? (1 - Kişin ov üsulunu tapması, 2 - Kişin haqq tələb etməsi, 3 - Kişin başçı seçilməsi)','Kiş əvvəlcə haqq tələb edir, sonra öz ov üsulunu tapır, sonda hörmət qazanıb başçı olur.',array['2 - 1 - 3','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb5-menevi#26','edebiyyat','edeb-5-menevi',3,2,'Beşinci sinifdə təmsil janrı barədə hansı fikir SƏHVDİR?','Təmsildə alleqoriya əsas üsuldur.',array['Təmsildə alleqoriyadan istifadə olunmur','Təmsildə heyvan obrazları insanı təmsil edir','Təmsil əxlaqi nəticə ilə bitir','Təmsil yığcam əsərdir'],1),
('edeb5-menevi#27','edebiyyat','edeb-5-menevi',3,2,'Cek London və Ənvər Əlibəyli haqqında hansı fikir doğrudur?','Biri Amerika, digəri Azərbaycan ədəbiyyatını təmsil edir.',array['Cek London ABŞ, Əlibəyli Azərbaycan ədəbiyyatındandır','Cek London Azərbaycan, Əlibəyli ABŞ ədəbiyyatındandır','Hər ikisi ABŞ ədəbiyyatındandır','Hər ikisi Azərbaycan ədəbiyyatındandır'],1),
('edeb5-menevi#28','edebiyyat','edeb-5-menevi',3,2,'Mənəvi dəyərlər bölməsi üzrə «əsər - janr» cütlüyü hansı doğrudur?','«İlan və Qurbağa» təmsil, «Kiş haqqında hekayət» isə nəsr əsəridir.',array['«İlan və Qurbağa» - təmsil','«Kiş haqqında hekayət» - təmsil','«İlan və Qurbağa» - nəsr hekayəsi','«Analar» - təmsil'],1),
('edeb5-menevi#29','edebiyyat','edeb-5-menevi',3,2,'Yazıçıların heyvan obrazlarından istifadə etməsinin səbəbi nədir?','İnsan xarakterlərini rəmzi şəkildə göstərmək üçün.',array['İnsan xarakterlərini rəmzi göstərmək','Təbiət elmini şagirdə öyrətmək','Coğrafi biliyi genişləndirmək','Ov qaydalarını izah etmək'],1),
('edeb5-menevi#30','edebiyyat','edeb-5-menevi',3,2,'Kiş obrazı ilə nağıl qəhrəmanının oxşarlığı nədədir?','Hər ikisi ağıl və cəsarətlə çətinliyi dəf edir.',array['Hər ikisi ağıl və cəsarətlə qalib gəlir','Hər ikisi sehrli qüvvələrlə qalib gəlir','Hər ikisi var-dövlətlə qalib gəlir','Hər ikisi kömək gözləmədən uduzur'],1),
('edeb5-menevi#31','edebiyyat','edeb-5-menevi',3,2,'Aşağıdakı «anlayış - izah» cütlüklərindən hansı doğrudur?','Alleqoriya obrazın rəmzi mənada işlədilməsidir.',array['Alleqoriya - rəmzi məna','Peyzaj - rəmzi məna','Alleqoriya - təbiət təsviri','Süjet - rəmzi məna'],1),
('edeb5-muharibe#1','edebiyyat','edeb-5-muharibe',1,2,'«Oğul həsrəti» şeirinin müəllifi kimdir?','Şeirin müəllifi Xəlil Rza Ulutürkdür.',array['Xəlil Rza Ulutürk','Maqsud İbrahimbəyov','Elçin Hüseynbəyli','Əhməd Cəmil'],1),
('edeb5-muharibe#2','edebiyyat','edeb-5-muharibe',1,2,'«Püstə ağacı» əsərinin müəllifi kimdir?','Əsərin müəllifi Maqsud İbrahimbəyovdur.',array['Maqsud İbrahimbəyov','Elçin Hüseynbəyli','Xəlil Rza Ulutürk','Süleyman Rəhimov'],1),
('edeb5-muharibe#3','edebiyyat','edeb-5-muharibe',1,2,'«Firuzə qaşlı xəncər» əsərinin müəllifi kimdir?','Əsərin müəllifi Elçin Hüseynbəylidir.',array['Elçin Hüseynbəyli','Maqsud İbrahimbəyov','Xəlil Rza Ulutürk','Mark Tven'],1),
('edeb5-muharibe#4','edebiyyat','edeb-5-muharibe',1,2,'Beşinci sinifdə bu bölmənin mövzusu nədir?','Müharibə və insan haqqı mövzusudur.',array['Müharibə və insan haqqı','Ticarət və sənaye','Kosmos və texnika','Dəniz macərası'],1),
('edeb5-muharibe#5','edebiyyat','edeb-5-muharibe',2,2,'«Oğul həsrəti» şeirində hansı hiss ifadə olunur?','Övlad həsrəti və itki ağrısı ifadə olunur.',array['Övlad həsrəti və itki ağrısı','Ticarət sevinci','Ov təəssüratı','Elmi maraq'],1),
('edeb5-muharibe#6','edebiyyat','edeb-5-muharibe',2,2,'Müharibə mövzulu əsərlərin əsas ideyası nədir?','Sülhün dəyəri və müharibənin faciəsidir.',array['Sülhün dəyəri və müharibənin faciəsi','Ticarətin genişlənməsi','Səyahətin faydası','Elmi kəşflərin sürəti'],1),
('edeb5-muharibe#7','edebiyyat','edeb-5-muharibe',2,2,'Xəlil Rza Ulutürk əsasən hansı ədəbi növdə yazmışdır?','O, poeziya sahəsində yazmışdır.',array['Poeziyada','Dramaturgiyada','Elmi nəsrdə','Publisistikada'],1),
('edeb5-muharibe#8','edebiyyat','edeb-5-muharibe',2,2,'Maqsud İbrahimbəyov hansı ədəbi növdə yazmışdır?','O, nəsrdə yazmışdır.',array['Nəsrdə','Ancaq şeirdə','Ancaq mənzum dramda','Ancaq qəsidədə'],1),
('edeb5-muharibe#9','edebiyyat','edeb-5-muharibe',2,2,'Müharibə mövzulu əsərlərdə uşaq obrazı nə üçün verilir?','Müharibənin ən günahsızlara vurduğu zərbəni göstərmək üçün.',array['Günahsızlara dəyən zərbəni göstərmək üçün','Ticarəti təsvir etmək üçün','Coğrafiya öyrətmək üçün','Ov qaydalarını vermək üçün'],1),
('edeb5-muharibe#10','edebiyyat','edeb-5-muharibe',2,2,'İnsan haqqı anlayışı nə deməkdir?','Hər insanın yaşamaq, azad olmaq hüququ deməkdir.',array['Yaşamaq və azad olmaq hüququ','Ticarət etmək icazəsi','Səfərə çıxmaq icazəsi','Ov etmək icazəsi'],1),
('edeb5-muharibe#11','edebiyyat','edeb-5-muharibe',2,2,'«Püstə ağacı» əsəri hansı ədəbi növə aiddir?','Əsər nəsrə aiddir.',array['Nəsrə','Poeziyaya','Dramaturgiyaya','Publisistikaya'],1),
('edeb5-muharibe#12','edebiyyat','edeb-5-muharibe',2,2,'Elçin Hüseynbəyli ədəbiyyata hansı dövrdə gəlmişdir?','O, müasir dövrün yazıçısıdır.',array['Müasir dövrdə','XII əsrdə','XVI əsrdə','XIX əsrin əvvəlində'],1),
('edeb5-muharibe#13','edebiyyat','edeb-5-muharibe',2,2,'Müharibə mövzulu şeirlərdə ovqat necə olur?','Kədərli, düşündürücü ovqat olur.',array['Kədərli və düşündürücü','Şən və zarafatlı','Laqeyd və soyuq','Sənədli və quru'],1),
('edeb5-muharibe#14','edebiyyat','edeb-5-muharibe',2,2,'Ağac obrazı ədəbiyyatda çox vaxt nəyi bildirir?','Həyatı, kökü və davamlılığı bildirir.',array['Həyat, kök və davamlılıq','Ticarət yolu','Hərbi güc','Şəhər memarlığı'],1),
('edeb5-muharibe#15','edebiyyat','edeb-5-muharibe',2,2,'Bu bölmə oxucuya hansı fikri aşılayır?','Sülhü qorumaq və insan haqqına hörmət fikrini aşılayır.',array['Sülhü qorumaq və insana hörmət','Ticarəti artırmaq','Uzaq səfərə çıxmaq','Ov öyrənmək'],1),
('edeb5-muharibe#16','edebiyyat','edeb-5-muharibe',2,2,'Xəncər obrazı bədii əsərdə nəyi bildirə bilər?','Yaddaşı, nəsildən-nəslə keçən əmanəti bildirə bilər.',array['Nəsildən-nəslə keçən əmanəti','Ticarət hesabını','Coğrafi mövqeyi','Riyazi ölçünü'],1),
('edeb5-muharibe#17','edebiyyat','edeb-5-muharibe',2,2,'Müharibə mövzusunun ədəbiyyatda daim yaşamasının səbəbi nədir?','Müharibənin insan taleyinə ağır təsiridir.',array['İnsan taleyinə ağır təsiri','Ticarətə faydası','Səyahəti asanlaşdırması','Elmi inkişafa təkanı'],1),
('edeb5-muharibe#18','edebiyyat','edeb-5-muharibe',2,2,'Şeirdə həsrət hissi necə ifadə olunur?','Obrazlı sözlər və təkrarlarla ifadə olunur.',array['Obrazlı sözlər və təkrarlarla','Riyazi düsturlarla','Cədvəllərlə','Xəritələrlə'],1),
('edeb5-muharibe#19','edebiyyat','edeb-5-muharibe',2,2,'Bu bölmədəki əsərlər hansı ədəbi növləri əhatə edir?','Bölmədə həm şeir, həm də nəsr nümunələri var.',array['Həm şeir, həm nəsr','Ancaq dram','Ancaq elmi məqalə','Ancaq tərcümə'],1),
('edeb5-muharibe#20','edebiyyat','edeb-5-muharibe',3,2,'Müharibə bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Püstə ağacı» Maqsud İbrahimbəyovun, «Oğul həsrəti» Xəlil Rza Ulutürkündür.',array['«Püstə ağacı» - Maqsud İbrahimbəyov','«Püstə ağacı» - Xəlil Rza Ulutürk','«Oğul həsrəti» - Maqsud İbrahimbəyov','«Firuzə qaşlı xəncər» - Xəlil Rza Ulutürk'],1),
('edeb5-muharibe#21','edebiyyat','edeb-5-muharibe',3,2,'Müharibə bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Oğul həsrəti» Xəlil Rza Ulutürkün şeiridir.',array['«Oğul həsrəti» Maqsud İbrahimbəyovundur','«Püstə ağacı» Maqsud İbrahimbəyovundur','«Firuzə qaşlı xəncər» Elçin Hüseynbəylinindir','Bölmənin mövzusu müharibə və insan haqqıdır'],1),
('edeb5-muharibe#22','edebiyyat','edeb-5-muharibe',3,2,'Şeirdə və nəsrdə müharibə mövzusunun açılması necə fərqlənir?','Şeirdə duyğu, nəsrdə isə hadisə vasitəsilə açılır.',array['Şeirdə duyğu, nəsrdə hadisə vasitəsilə','Şeirdə hadisə, nəsrdə duyğu vasitəsilə','Hər ikisində eyni cür açılır','Heç birində bu mövzu açılmır'],1),
('edeb5-muharibe#23','edebiyyat','edeb-5-muharibe',3,2,'Müharibə mövzulu əsərlərdə uşaq obrazının verilməsinin səbəbi nədir?','Müharibənin ən günahsızlara vurduğu zərbəni göstərmək üçün.',array['Günahsızlara dəyən zərbəni göstərmək','Süjeti uzatmaq ehtiyacının olması','Dərslik tələbinin belə olması','Tərcüməni asanlaşdırmaq istəyi'],1),
('edeb5-muharibe#24','edebiyyat','edeb-5-muharibe',3,2,'Müharibə bölməsi üzrə «əsər - ədəbi növ» cütlüyü hansı doğrudur?','«Oğul həsrəti» şeir, «Püstə ağacı» isə nəsr əsəridir.',array['«Oğul həsrəti» - şeir','«Oğul həsrəti» - nəsr','«Püstə ağacı» - şeir','«Firuzə qaşlı xəncər» - şeir'],1),
('edeb5-muharibe#25','edebiyyat','edeb-5-muharibe',3,2,'Üç müəllif dövr baxımından necə düzülür? (1 - Elçin Hüseynbəyli, 2 - Xəlil Rza Ulutürk, 3 - Maqsud İbrahimbəyov)','Xəlil Rza və Maqsud İbrahimbəyov XX əsrin ikinci yarısında, Elçin Hüseynbəyli isə müasir dövrdə yazmışdır.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb5-muharibe#26','edebiyyat','edeb-5-muharibe',3,2,'Müharibə mövzusu barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Müharibə mövzulu əsərlər sülhün dəyərini vurğulayır.',array['Bu əsərlər müharibəni tərifləyir','Bu əsərlər sülhün dəyərini vurğulayır','Bu əsərlərdə kədərli ovqat olur','İnsan haqqı bu bölmənin mövzusudur'],1),
('edeb5-muharibe#27','edebiyyat','edeb-5-muharibe',3,2,'Xəlil Rza Ulutürk və Maqsud İbrahimbəyov haqqında hansı fikir doğrudur?','Biri poeziyada, digəri nəsrdə yazmışdır.',array['Ulutürk poeziyada, İbrahimbəyov nəsrdə yazmışdır','Ulutürk nəsrdə, İbrahimbəyov poeziyada yazmışdır','Hər ikisi ancaq poeziyada yazmışdır','Hər ikisi ancaq nəsrdə yazmışdır'],1),
('edeb5-muharibe#28','edebiyyat','edeb-5-muharibe',3,2,'Müharibə bölməsi üzrə «obraz - məna» cütlüyü hansı düzgündür?','Ağac obrazı həyatı və kökü, xəncər isə əmanəti bildirir.',array['Ağac - həyat və kök','Ağac - ticarət yolu','Xəncər - coğrafi mövqe','Xəncər - riyazi ölçü'],1),
('edeb5-muharibe#29','edebiyyat','edeb-5-muharibe',3,2,'Müharibə mövzusunun uşaq dərsliyinə salınmasının səbəbi nədir?','Şagirddə sülhün dəyərini və insan haqqına hörməti formalaşdırmaq.',array['Sülhün dəyərini formalaşdırmaq','Hərbi hazırlıq öyrətmək','Ticarət təlimi vermək','Coğrafi bilik vermək'],1),
('edeb5-muharibe#30','edebiyyat','edeb-5-muharibe',3,2,'Bədii əsərdə həsrət hissi ilə sevinc hissinin ifadəsi necə fərqlənir?','Həsrət kədərli, sevinc isə nikbin ovqat yaradır.',array['Həsrət kədərli, sevinc nikbin ovqat yaradır','Həsrət nikbin, sevinc kədərli ovqat yaradır','Hər ikisi eyni ovqat yaradır','Hər ikisi ovqata təsir etmir'],1),
('edeb5-muharibe#31','edebiyyat','edeb-5-muharibe',3,2,'Müharibə bölməsi üzrə «bölmə - mövzu» cütlüyü hansı doğrudur?','«Müharibə və insan haqqı» bölməsi sülh və insan hüququ mövzusundadır.',array['Müharibə bölməsi - sülh və insan hüququ','Müharibə bölməsi - təbiət gözəlliyi','Yurd bölməsi - sülh və insan hüququ','Müharibə bölməsi - əmək mövzusu'],1),
('edeb5-usaq#1','edebiyyat','edeb-5-usaq',1,3,'«Can nənə, bir nağıl de» şeirinin müəllifi kimdir?','Şeirin müəllifi Əhməd Cəmildir.',array['Əhməd Cəmil','Mark Tven','Hüseyn Arif','Əli Tudə'],1),
('edeb5-usaq#2','edebiyyat','edeb-5-usaq',1,3,'«Fərasətli oğlan» əsərinin müəllifi kimdir?','Əsərin müəllifi Mark Tvendir.',array['Mark Tven','Cek London','Əhməd Cəmil','Ənvər Əlibəyli'],1),
('edeb5-usaq#3','edebiyyat','edeb-5-usaq',1,3,'Mark Tven hansı ölkənin yazıçısıdır?','Mark Tven Amerika yazıçısıdır.',array['ABŞ-ın','İngiltərənin','Fransanın','Almaniyanın'],1),
('edeb5-usaq#4','edebiyyat','edeb-5-usaq',1,3,'Beşinci sinifdə uşaq bölməsinin mövzusu nədir?','Uşaq dünyası və uşaq taleyi mövzusudur.',array['Uşaq dünyası və uşaq taleyi','Ticarət və sənaye','Hərbi taktika','Kosmos tədqiqatı'],1),
('edeb5-usaq#5','edebiyyat','edeb-5-usaq',2,3,'«Can nənə, bir nağıl de» şeirində uşaq nənədən nə istəyir?','Uşaq nənədən nağıl danışmasını istəyir.',array['Nağıl danışmasını','Yeni oyuncaq','Uzaq səfər','Çoxlu pul'],1),
('edeb5-usaq#6','edebiyyat','edeb-5-usaq',2,3,'Nənə obrazı uşaq ədəbiyyatında nəyi bildirir?','Mehribanlığı, nağıl və yaddaş daşıyıcısını bildirir.',array['Mehribanlıq və yaddaş daşıyıcısını','Ticarət ustasını','Hərbi komandiri','Elmi tədqiqatçını'],1),
('edeb5-usaq#7','edebiyyat','edeb-5-usaq',2,3,'«Fərasətli oğlan» adı hansı keyfiyyəti bildirir?','Uşağın zəkasını, ağıllı davranışını bildirir.',array['Zəka və ağıllı davranışı','Bədən gücünü','Var-dövləti','Uzaq qohumluğu'],1),
('edeb5-usaq#8','edebiyyat','edeb-5-usaq',2,3,'Mark Tvenin əsərlərində hansı cəhət güclüdür?','Yumor və uşaq dünyasının canlı təsviri güclüdür.',array['Yumor və uşaq dünyasının təsviri','Sənədli hesabat','Elmi şərh','Hərbi salnamə'],1),
('edeb5-usaq#9','edebiyyat','edeb-5-usaq',2,3,'Əhməd Cəmil hansı ədəbi növdə yazmışdır?','O, şeir - poeziya sahəsində yazmışdır.',array['Şeirdə','Dramaturgiyada','Elmi nəsrdə','Publisistikada'],1),
('edeb5-usaq#10','edebiyyat','edeb-5-usaq',2,3,'Uşaq şeirlərində dil necə olmalıdır?','Sadə, ahəngdar və uşağa doğma olmalıdır.',array['Sadə və ahəngdar','Ağır elmi','Rəsmi sənəd dilində','Arxaik sözlərlə dolu'],1),
('edeb5-usaq#11','edebiyyat','edeb-5-usaq',2,3,'«Fərasətli oğlan» hansı ədəbi növə aiddir?','Əsər nəsrə aiddir.',array['Nəsrə','Poeziyaya','Dramaturgiyaya','Publisistikaya'],1),
('edeb5-usaq#12','edebiyyat','edeb-5-usaq',2,3,'Uşaq ədəbiyyatında nağıl niyə mühüm yer tutur?','Nağıl uşağın təxəyyülünü inkişaf etdirir.',array['Təxəyyülü inkişaf etdirdiyi üçün','Ticarət öyrətdiyi üçün','Hesab öyrətdiyi üçün','Xəritə göstərdiyi üçün'],1),
('edeb5-usaq#13','edebiyyat','edeb-5-usaq',2,3,'Uşaq obrazı bədii əsərdə hansı baxışı təmsil edir?','Dünyaya saf və təmiz baxışı təmsil edir.',array['Saf və təmiz baxışı','Soyuq hesabı','Hərbi nizamı','Ticarət marağını'],1),
('edeb5-usaq#14','edebiyyat','edeb-5-usaq',2,3,'«Can nənə, bir nağıl de» şeirində hansı iki nəsil qarşılaşır?','Uşaq və nənə - iki nəsil qarşılaşır.',array['Uşaq və nənə','Müəllim və şagird','Tacir və alıcı','Əsgər və komandir'],1),
('edeb5-usaq#15','edebiyyat','edeb-5-usaq',2,3,'Uşaq mövzulu bölmə beşinci sinifdə necə adlanır?','Bölmə «Uşaq dünyası, uşaq taleyi» adlanır.',array['«Uşaq dünyası, uşaq taleyi»','«Mənəvi dəyərlər, həmişəyaşar hikmətlər»','«Yurd sevgisi, ana məhəbbəti»','«Əməyə məhəbbət, zəhmətə çağırış»'],1),
('edeb5-usaq#16','edebiyyat','edeb-5-usaq',2,3,'Yumor nədir?','Xoş, mehriban gülüş doğuran bədii vasitədir.',array['Xoş gülüş doğuran vasitə','Kəskin ittiham','Elmi sübut','Rəsmi bildiriş'],1),
('edeb5-usaq#17','edebiyyat','edeb-5-usaq',2,3,'Uşaq ədəbiyyatı əsərləri hansı sonluğa üstünlük verir?','Nikbin, ümidverici sonluğa üstünlük verilir.',array['Nikbin və ümidverici sonluğa','Ümidsiz sonluğa','Sonluqsuz quruluşa','Sənədli hesabata'],1),
('edeb5-usaq#18','edebiyyat','edeb-5-usaq',2,3,'Uşaq şeirində təkrarlar hansı rolu oynayır?','Şeiri yaddaqalan və ahəngdar edir.',array['Şeiri yaddaqalan və ahəngdar edir','Süjeti qurur','Sənəd rolunu oynayır','Vəzni ləğv edir'],1),
('edeb5-usaq#19','edebiyyat','edeb-5-usaq',2,3,'Bu bölmədəki əsərlərin ortaq cəhəti nədir?','Hər ikisinin mərkəzində uşaq obrazı dayanır.',array['Mərkəzində uşaq obrazının dayanması','Hərbi mövzu','Ticarət mövzusu','Kosmos mövzusu'],1),
('edeb5-usaq#20','edebiyyat','edeb-5-usaq',3,3,'Uşaq bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Fərasətli oğlan» Mark Tvenin, «Can nənə, bir nağıl de» Əhməd Cəmilindir.',array['«Fərasətli oğlan» - Mark Tven','«Fərasətli oğlan» - Əhməd Cəmil','«Can nənə, bir nağıl de» - Mark Tven','«Can nənə, bir nağıl de» - Cek London'],1),
('edeb5-usaq#21','edebiyyat','edeb-5-usaq',3,3,'Uşaq bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Mark Tven Amerika yazıçısıdır.',array['Mark Tven fransız yazıçısıdır','Mark Tven Amerika yazıçısıdır','«Fərasətli oğlan» nəsr əsəridir','Əhməd Cəmil şairdir'],1),
('edeb5-usaq#22','edebiyyat','edeb-5-usaq',3,3,'Şeir ilə hekayənin uşaq mövzusunu açma yolu necə fərqlənir?','Şeir duyğu, hekayə isə hadisə vasitəsilə açır.',array['Şeir duyğu, hekayə hadisə ilə açır','Şeir hadisə, hekayə duyğu ilə açır','Hər ikisi eyni yolla açır','Hər ikisi sənədli üsulla açır'],1),
('edeb5-usaq#23','edebiyyat','edeb-5-usaq',3,3,'Uşaq şeirlərində sadə dilin seçilməsinin səbəbi nədir?','Şeirin uşaq üçün anlaşıqlı və yaddaqalan olması üçün.',array['Uşaq üçün anlaşıqlı olması üçün','Yazmağın asan olması üçün','Dərslik tələbi üçün','Tərcümənin asanlığı üçün'],1),
('edeb5-usaq#24','edebiyyat','edeb-5-usaq',3,3,'Beşinci sinif uşaq bölməsi üzrə «əsər - ədəbi növ» cütlüyü hansıdır?','«Can nənə, bir nağıl de» şeir, «Fərasətli oğlan» isə nəsrdir.',array['«Can nənə, bir nağıl de» - şeir','«Can nənə, bir nağıl de» - nəsr','«Fərasətli oğlan» - şeir','«Analar» - nəsr'],1),
('edeb5-usaq#25','edebiyyat','edeb-5-usaq',3,3,'Aşağıdakı üç müəllif dövr baxımından necə düzülür? (1 - Mark Tven, 2 - müasir uşaq yazıçıları, 3 - Əhməd Cəmil)','Mark Tven XIX əsrdə, Əhməd Cəmil XX əsrdə, müasir müəlliflər isə daha sonra yazmışdır.',array['1 - 3 - 2','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb5-usaq#26','edebiyyat','edeb-5-usaq',3,3,'Beşinci sinifdə uşaq ədəbiyyatı barədə hansı fikir SƏHVDİR?','Uşaq ədəbiyyatı nikbin sonluğa üstünlük verir.',array['Bu ədəbiyyat ümidsiz sonluğa üstünlük verir','Uşaq ədəbiyyatının dili sadə olur','Nağıl təxəyyülü inkişaf etdirir','Uşaq obrazı saf baxışı təmsil edir'],1),
('edeb5-usaq#27','edebiyyat','edeb-5-usaq',3,3,'Mark Tven və Əhməd Cəmil haqqında hansı fikir doğrudur?','Biri Amerika, digəri Azərbaycan ədəbiyyatını təmsil edir.',array['Mark Tven ABŞ, Əhməd Cəmil Azərbaycan ədəbiyyatındandır','Mark Tven Azərbaycan, Əhməd Cəmil ABŞ ədəbiyyatındandır','Hər ikisi ABŞ ədəbiyyatındandır','Hər ikisi Azərbaycan ədəbiyyatındandır'],1),
('edeb5-usaq#28','edebiyyat','edeb-5-usaq',3,3,'Uşaq bölməsi üzrə «obraz - məna» cütlüyü hansı düzgündür?','Nənə obrazı mehribanlığı və yaddaşı bildirir.',array['Nənə - mehribanlıq və yaddaş','Nənə - hərbi nizam','Nənə - ticarət ustalığı','Nənə - elmi tədqiqat'],1),
('edeb5-usaq#29','edebiyyat','edeb-5-usaq',3,3,'Yazıçıların yumor vasitəsindən istifadə etməsinin səbəbi nədir?','Fikri xoş gülüşlə, uşağa doğma şəkildə çatdırmaq üçün.',array['Fikri xoş gülüşlə çatdırmaq üçün','Əsəri uzatmaq üçün','Sənəd rolunu oynamaq üçün','Vəzni dəyişmək üçün'],1),
('edeb5-usaq#30','edebiyyat','edeb-5-usaq',3,3,'Nağılın uşaq üçün əhəmiyyəti ilə şeirin əhəmiyyəti necə fərqlənir?','Nağıl təxəyyülü, şeir isə duyğunu inkişaf etdirir.',array['Nağıl təxəyyülü, şeir duyğunu inkişaf etdirir','Nağıl duyğunu, şeir təxəyyülü inkişaf etdirir','Hər ikisi eyni bacarığı inkişaf etdirir','Heç biri uşağa təsir etmir'],1),
('edeb5-usaq#31','edebiyyat','edeb-5-usaq',3,3,'Uşaq bölməsi üzrə «anlayış - izah» cütlüyü hansı doğrudur?','Yumor xoş gülüş doğuran bədii vasitədir.',array['Yumor - xoş gülüş doğuran vasitə','Peyzaj - xoş gülüş doğuran vasitə','Yumor - təbiət təsviri','Süjet - xoş gülüş'],1),
('edeb5-emek#1','edebiyyat','edeb-5-emek',1,3,'«Kərpickəsən kişinin dastanı» əsərinin müəllifi kimdir?','Əsərin müəllifi Nizami Gəncəvidir.',array['Nizami Gəncəvi','Süleyman Rəhimov','Cek London','Mark Tven'],1),
('edeb5-emek#2','edebiyyat','edeb-5-emek',1,3,'«Qara torpaq və sarı qızıl» əsərinin müəllifi kimdir?','Əsərin müəllifi Süleyman Rəhimovdur.',array['Süleyman Rəhimov','Nizami Gəncəvi','Əhməd Cəmil','Maqsud İbrahimbəyov'],1),
('edeb5-emek#3','edebiyyat','edeb-5-emek',1,3,'Beşinci sinifdə əmək bölməsinin mövzusu nədir?','Əməyə məhəbbət və zəhmətə çağırış mövzusudur.',array['Əməyə məhəbbət və zəhmətə çağırış','Kosmos tədqiqatı','Dəniz macərası','Hərbi taktika'],1),
('edeb5-emek#4','edebiyyat','edeb-5-emek',1,3,'«Kərpickəsən kişinin dastanı» hansı poemadan götürülmüşdür?','Hekayət «Sirlər xəzinəsi» poemasındandır.',array['«Sirlər xəzinəsi»','«Yeddi gözəl»','«Dəhnamə»','«Koroğlu»'],1),
('edeb5-emek#5','edebiyyat','edeb-5-emek',2,3,'«Kərpickəsən kişinin dastanı»nın əsas ideyası nədir?','Halal zəhmətin ucalığı ideyasıdır.',array['Halal zəhmətin ucalığı','Var-dövlət toplamaq','Uzaq səfərə çıxmaq','Ov öyrənmək'],1),
('edeb5-emek#6','edebiyyat','edeb-5-emek',2,3,'Kərpickəsən kişi gəncə nəyi öyrədir?','Öz zəhməti ilə yaşamağın dəyərini öyrədir.',array['Öz zəhməti ilə yaşamağı','Ticarətdə hiylə işlətməyi','Səfərdən qaçmağı','Başqasına güvənməyi'],1),
('edeb5-emek#7','edebiyyat','edeb-5-emek',2,3,'Nizami Gəncəvi hansı şəhərdə yaşamışdır?','Nizami Gəncədə yaşayıb-yaratmışdır.',array['Gəncədə','Şamaxıda','Təbrizdə','Şuşada'],1),
('edeb5-emek#8','edebiyyat','edeb-5-emek',2,3,'Süleyman Rəhimov hansı ədəbi növdə yazmışdır?','O, nəsrdə yazmışdır.',array['Nəsrdə','Ancaq şeirdə','Ancaq mənzum dramda','Ancaq qəsidədə'],1),
('edeb5-emek#9','edebiyyat','edeb-5-emek',2,3,'«Qara torpaq və sarı qızıl» adında hansı iki dəyər qarşılaşdırılır?','Torpaq - əmək ilə qızıl - var-dövlət qarşılaşdırılır.',array['Əmək ilə var-dövlət','Dəniz ilə səhra','Şəhər ilə kənd','Elm ilə sənət'],1),
('edeb5-emek#10','edebiyyat','edeb-5-emek',2,3,'Əmək mövzulu əsərlərin əsas çağırışı nədir?','Zəhmətlə yaşamağa, əməyə hörmətə çağırışdır.',array['Zəhmətlə yaşamağa çağırış','Rahatlıq axtarmağa çağırış','Səfərə çağırış','Ova çağırış'],1),
('edeb5-emek#11','edebiyyat','edeb-5-emek',2,3,'Nizaminin hekayətləri hansı səciyyə daşıyır?','Didaktik - öyrədici səciyyə daşıyır.',array['Didaktik - öyrədici','Sənədli-tarixi','Yumoristik','Detektiv'],1),
('edeb5-emek#12','edebiyyat','edeb-5-emek',2,3,'«Kərpickəsən kişinin dastanı» hansı formada yazılmışdır?','Hekayət nəzmlə - şeirlə yazılmışdır.',array['Nəzmlə','Nəsrlə','Qarışıq formada','Məktub formasında'],1),
('edeb5-emek#13','edebiyyat','edeb-5-emek',2,3,'Torpaq obrazı xalq təfəkküründə nəyi bildirir?','Ruzi mənbəyini, doğma vətəni bildirir.',array['Ruzi mənbəyi və doğma vətəni','Ticarət yolunu','Hərbi mövqeyi','Elmi anlayışı'],1),
('edeb5-emek#14','edebiyyat','edeb-5-emek',2,3,'Əmək mövzulu bölmə beşinci sinifdə necə adlanır?','Bölmə «Əməyə məhəbbət, zəhmətə çağırış» adlanır.',array['«Əməyə məhəbbət, zəhmətə çağırış»','«Uşaq dünyası, uşaq taleyi»','«Müharibə və insan haqqı»','«Şifahi xalq ədəbiyyatı inciləri»'],1),
('edeb5-emek#15','edebiyyat','edeb-5-emek',2,3,'Halal zəhmət ifadəsi nə deməkdir?','Öz əməyi ilə, düz yolla qazanmaq deməkdir.',array['Öz əməyi ilə düz yolla qazanmaq','Tez varlanmaq','Başqasından borc almaq','Səfərdən qayıtmaq'],1),
('edeb5-emek#16','edebiyyat','edeb-5-emek',2,3,'Nizaminin əsərləri hansı dildə yazılmışdır?','Nizami əsərlərini fars dilində yazmışdır.',array['Fars dilində','Yunan dilində','Latın dilində','Rus dilində'],1),
('edeb5-emek#17','edebiyyat','edeb-5-emek',2,3,'Əmək mövzulu əsərlərdə hansı obraz müsbət verilir?','Zəhmətkeş, öz əməyi ilə yaşayan insan müsbət verilir.',array['Zəhmətkeş insan','Tənbəl adam','Hiyləgər tacir','Laqeyd müşahidəçi'],1),
('edeb5-emek#18','edebiyyat','edeb-5-emek',2,3,'Didaktik əsərin oxucuya təsiri necə olur?','Oxucuya əxlaqi dərs verir, düşündürür.',array['Əxlaqi dərs verib düşündürür','Ancaq güldürür','Ancaq qorxudur','Heç bir təsir etmir'],1),
('edeb5-emek#19','edebiyyat','edeb-5-emek',2,3,'Əmək bölməsindəki əsərlər hansı ədəbi növləri əhatə edir?','Bölmədə həm nəzm, həm də nəsr nümunəsi var.',array['Həm nəzm, həm nəsr','Ancaq dram','Ancaq elmi məqalə','Ancaq tərcümə'],1),
('edeb5-emek#20','edebiyyat','edeb-5-emek',3,3,'Əmək bölməsi üzrə «əsər - müəllif» cütlüyü hansı düzgündür?','«Kərpickəsən kişinin dastanı» Nizaminin, «Qara torpaq və sarı qızıl» Süleyman Rəhimovundur.',array['«Kərpickəsən kişinin dastanı» - Nizami','«Kərpickəsən kişinin dastanı» - Süleyman Rəhimov','«Qara torpaq və sarı qızıl» - Nizami','«Qara torpaq və sarı qızıl» - Cek London'],1),
('edeb5-emek#21','edebiyyat','edeb-5-emek',3,3,'Əmək bölməsi barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','«Kərpickəsən kişinin dastanı» «Sirlər xəzinəsi» poemasındandır.',array['Hekayət «Koroğlu» dastanındandır','Nizami Gəncədə yaşayıb-yaratmışdır','Süleyman Rəhimov nasir olmuşdur','Bölmənin mövzusu əməyə məhəbbətdir'],1),
('edeb5-emek#22','edebiyyat','edeb-5-emek',3,3,'Nizaminin hekayətini didaktik edən cəhət nədir?','Süjetdən sonra oxucuya birbaşa əxlaqi nəticə verilməsidir.',array['Süjetdən sonra əxlaqi nəticə verilməsi','Uzun döyüş səhnələrinin olması','Sənədli faktların sıralanması','Gülüş doğurmaq məqsədi'],1),
('edeb5-emek#23','edebiyyat','edeb-5-emek',3,3,'Kərpickəsən kişinin gəncə verdiyi dərsin mahiyyəti nədir?','İnsanın öz zəhməti ilə yaşamasının ucalığıdır.',array['Öz zəhməti ilə yaşamağın ucalığı','Tez varlanmağın yolları','Səfərə hazırlıq qaydası','Ticarətdə uduş üsulu'],1),
('edeb5-emek#24','edebiyyat','edeb-5-emek',3,3,'Əmək bölməsi üzrə «əsər - forma» cütlüyü hansı doğrudur?','«Kərpickəsən kişinin dastanı» nəzmlə yazılmışdır.',array['«Kərpickəsən kişinin dastanı» - nəzm','«Kərpickəsən kişinin dastanı» - nəsr','«Qara torpaq və sarı qızıl» - nəzm','«Fərasətli oğlan» - nəzm'],1),
('edeb5-emek#25','edebiyyat','edeb-5-emek',3,3,'Üç müəllif dövr baxımından necə düzülür? (1 - Nizami Gəncəvi, 2 - müasir yazıçılar, 3 - Süleyman Rəhimov)','Nizami XII əsrdə, Süleyman Rəhimov XX əsrdə, müasir yazıçılar isə daha sonra yazmışdır.',array['1 - 3 - 2','1 - 2 - 3','3 - 2 - 1','2 - 3 - 1'],1),
('edeb5-emek#26','edebiyyat','edeb-5-emek',3,3,'Əmək mövzusu barədə aşağıdakı fikirlərdən hansı SƏHVDİR?','Əmək mövzulu əsərlər zəhmətkeş insanı ucaldır.',array['Əmək mövzulu əsərlər tənbəlliyi tərifləyir','Bu əsərlər zəhmətkeş insanı ucaldır','Halal zəhmət düz yolla qazanmaqdır','Torpaq ruzi mənbəyi sayılır'],1),
('edeb5-emek#27','edebiyyat','edeb-5-emek',3,3,'Nizami və Süleyman Rəhimov haqqında hansı fikir doğrudur?','Biri nəzmlə, digəri nəsrlə yazmışdır.',array['Nizami nəzmlə, Rəhimov nəsrlə yazmışdır','Nizami nəsrlə, Rəhimov nəzmlə yazmışdır','Hər ikisi nəzmlə yazmışdır','Hər ikisi nəsrlə yazmışdır'],1),
('edeb5-emek#28','edebiyyat','edeb-5-emek',3,3,'Əmək bölməsi üzrə «obraz - məna» cütlüyü hansı düzgündür?','Torpaq obrazı ruzi mənbəyini və doğma vətəni bildirir.',array['Torpaq - ruzi mənbəyi və vətən','Torpaq - hərbi mövqe','Qızıl - halal zəhmət','Torpaq - ticarət yolu'],1),
('edeb5-emek#29','edebiyyat','edeb-5-emek',3,3,'Əmək mövzusunun uşaq dərsliyinə salınmasının səbəbi nədir?','Şagirddə zəhmətə hörmət hissi formalaşdırmaqdır.',array['Zəhmətə hörmət hissi formalaşdırmaq','Dərsliyin həcmini artırmaq istəyi','Xarici dil öyrətmək məqsədi','Coğrafi bilik qazandırmaq'],1),
('edeb5-emek#30','edebiyyat','edeb-5-emek',3,3,'Didaktik əsər ilə əyləncəli əsərin fərqi nədir?','Didaktik əsər öyrədir, əyləncəli əsər isə xoş vaxt keçirtdirir.',array['Biri öyrədir, digəri xoş vaxt keçirtdirir','Biri xoş vaxt keçirtdirir, digəri öyrədir','Hər ikisi ancaq öyrədir','Hər ikisi ancaq əyləndirir'],1),
('edeb5-emek#31','edebiyyat','edeb-5-emek',3,3,'Əmək bölməsi üzrə «bölmə - mövzu» cütlüyü hansı doğrudur?','«Əməyə məhəbbət, zəhmətə çağırış» bölməsi əmək mövzusundadır.',array['Əmək bölməsi - zəhmət və əmək mövzusu','Əmək bölməsi - təbiət mövzusu','Uşaq bölməsi - zəhmət və əmək mövzusu','Əmək bölməsi - müharibə mövzusu'],1),
('edeb5-tebiet#1','edebiyyat','edeb-5-tebiet',1,4,'«Çinarın şikayəti» şeirinin müəllifi kimdir?','Şeirin müəllifi Səməd Vurğundur.',array['Səməd Vurğun','Abdulla Şaiq','Fikrət Qoca','Hüseyn Arif'],1),
('edeb5-tebiet#2','edebiyyat','edeb-5-tebiet',1,4,'«Köç» əsərinin müəllifi kimdir?','Əsərin müəllifi Abdulla Şaiqdir.',array['Abdulla Şaiq','Səməd Vurğun','Fikrət Qoca','Əhməd Cəmil'],1),
('edeb5-tebiet#3','edebiyyat','edeb-5-tebiet',1,4,'«Şuşa» şeirinin müəllifi kimdir?','Şeirin müəllifi Fikrət Qocadır.',array['Fikrət Qoca','Səməd Vurğun','Abdulla Şaiq','Əli Tudə'],1),
('edeb5-tebiet#4','edebiyyat','edeb-5-tebiet',1,4,'Beşinci sinifdə təbiət bölməsinin mövzusu nədir?','Təbiətin gözəlliyi və təbiətə qayğı mövzusudur.',array['Təbiətin gözəlliyi və qayğı','Ticarət qaydaları','Hərbi taktika','Kosmos tədqiqatı'],1),
('edeb5-tebiet#5','edebiyyat','edeb-5-tebiet',2,4,'«Çinarın şikayəti» şeirində kim şikayətlənir?','Şeirdə çinar ağacı şikayətlənir.',array['Çinar ağacı','Dağ çayı','Köçəri quş','Dəniz dalğası'],1),
('edeb5-tebiet#6','edebiyyat','edeb-5-tebiet',2,4,'Çinar nədən şikayətlənir?','İnsanların təbiətə etinasız münasibətindən şikayətlənir.',array['İnsanların etinasızlığından','Havanın soyuqluğundan','Quşların çoxluğundan','Suyun şirinliyindən'],1),
('edeb5-tebiet#7','edebiyyat','edeb-5-tebiet',2,4,'«Çinarın şikayəti» şeirində hansı bədii üsul işlənir?','Ağaca insan kimi danışmaq qabiliyyəti verilir.',array['Ağaca insan kimi dil verilir','Riyazi hesablama aparılır','Sənədli fakt sıralanır','Xəritə təsvir olunur'],1),
('edeb5-tebiet#8','edebiyyat','edeb-5-tebiet',2,4,'«Şuşa» şeirində hansı yer vəsf olunur?','Şuşa şəhəri və onun təbiəti vəsf olunur.',array['Şuşa şəhəri və təbiəti','Dəniz limanı','Səhra karvanı','Kosmos stansiyası'],1),
('edeb5-tebiet#9','edebiyyat','edeb-5-tebiet',2,4,'Abdulla Şaiq hansı sahədə də çalışmışdır?','O, müəllim kimi çalışmış, dərsliklər hazırlamışdır.',array['Müəllimlik və dərslik hazırlamaqla','Karvan ticarəti ilə','Dənizçiliklə','Memarlıqla'],1),
('edeb5-tebiet#10','edebiyyat','edeb-5-tebiet',2,4,'Təbiət mövzulu şeirlərdə hansı bədii vasitə çox işlənir?','Epitet və bənzətmə çox işlənir.',array['Epitet və bənzətmə','Riyazi düstur','Sənədli statistika','Xəritə işarəsi'],1),
('edeb5-tebiet#11','edebiyyat','edeb-5-tebiet',2,4,'Bədii əsərdə təbiət təsvirinə nə deyilir?','Ona peyzaj deyilir.',array['Peyzaj','Portret','Süjet','Kompozisiya'],1),
('edeb5-tebiet#12','edebiyyat','edeb-5-tebiet',2,4,'Səməd Vurğun hansı ədəbi növdə yazmışdır?','O, lirik şeir sahəsində yazmışdır.',array['Lirik şeirdə','Elmi nəsrdə','Publisistikada','Sənədli janrda'],1),
('edeb5-tebiet#13','edebiyyat','edeb-5-tebiet',2,4,'Təbiətə qayğı mövzusu oxucuya nə aşılayır?','Təbiəti qorumaq məsuliyyətini aşılayır.',array['Təbiəti qorumaq məsuliyyətini','Ov etmək bacarığını','Ticarət qaydalarını','Hərbi nizamı'],1),
('edeb5-tebiet#14','edebiyyat','edeb-5-tebiet',2,4,'«Köç» sözü hansı hadisəni bildirir?','Bir yerdən başqa yerə köçməyi, yerdəyişməni bildirir.',array['Bir yerdən başqa yerə köçməyi','Yeni ev tikməyi','Ticarət etməyi','Məktəbə getməyi'],1),
('edeb5-tebiet#15','edebiyyat','edeb-5-tebiet',2,4,'Şuşa hansı bölgənin şəhəridir?','Şuşa Qarabağ bölgəsinin şəhəridir.',array['Qarabağın','Şirvanın','Naxçıvanın','Lənkəranın'],1),
('edeb5-tebiet#16','edebiyyat','edeb-5-tebiet',2,4,'Beşinci sinifdə təbiət bölməsi necə adlanır?','Bölmə «Təbiətin gözəlliyi, təbiətə qayğı» adlanır.',array['«Təbiətin gözəlliyi, təbiətə qayğı»','«Uşaq dünyası, uşaq taleyi»','«Müharibə və insan haqqı»','«Yurd sevgisi, ana məhəbbəti»'],1),
('edeb5-tebiet#17','edebiyyat','edeb-5-tebiet',2,4,'Təbiət obrazlarına insan xüsusiyyəti verilməsi nəyə xidmət edir?','Təbiəti canlı və doğma göstərməyə xidmət edir.',array['Təbiəti canlı və doğma göstərməyə','Hesab öyrətməyə','Xəritə çəkməyə','Ticarət planı qurmağa'],1),
('edeb5-tebiet#18','edebiyyat','edeb-5-tebiet',2,4,'Fikrət Qoca hansı ədəbi növün nümayəndəsidir?','O, poeziyanın nümayəndəsidir.',array['Poeziyanın','Elmi nəsrin','Dramaturgiyanın','Publisistikanın'],1),
('edeb5-tebiet#19','edebiyyat','edeb-5-tebiet',2,4,'Təbiət bölməsindəki əsərlərin ortaq cəhəti nədir?','Hamısında təbiətə sevgi və qayğı hissi var.',array['Təbiətə sevgi və qayğı hissi','Hərbi mövzu','Ticarət mövzusu','Kosmos mövzusu'],1),
('edeb5-tebiet#20','edebiyyat','edeb-5-tebiet',3,4,'Beşinci sinif təbiət bölməsi üzrə «əsər - müəllif» cütlüyü hansıdır?','«Çinarın şikayəti» Səməd Vurğunun, «Köç» Abdulla Şaiqindir.',array['«Çinarın şikayəti» - Səməd Vurğun','«Çinarın şikayəti» - Abdulla Şaiq','«Köç» - Səməd Vurğun','«Şuşa» - Abdulla Şaiq'],1),
('edeb5-tebiet#21','edebiyyat','edeb-5-tebiet',3,4,'Beşinci sinif təbiət bölməsi barədə hansı fikir SƏHVDİR?','«Şuşa» şeirinin müəllifi Fikrət Qocadır.',array['«Şuşa» şeirinin müəllifi Səməd Vurğundur','«Çinarın şikayəti» Səməd Vurğunundur','«Köç» Abdulla Şaiqindir','Bölmənin mövzusu təbiətə qayğıdır'],1),
('edeb5-tebiet#22','edebiyyat','edeb-5-tebiet',3,4,'Çinarın dilə gəlib şikayətlənməsi hansı bədii üsuldur?','Cansız varlığa insan xüsusiyyəti verilməsi üsuludur.',array['Cansıza insan xüsusiyyəti vermək','Hadisələri sənədləşdirmək','Rəqəmlərlə sübut etmək','Xəritə üzərində göstərmək'],1),
('edeb5-tebiet#23','edebiyyat','edeb-5-tebiet',3,4,'«Çinarın şikayəti» şeirinin yazılma məqsədi nədir?','İnsanı təbiətə qarşı məsuliyyətə çağırmaqdır.',array['Təbiətə qarşı məsuliyyətə çağırmaq','Ov qaydalarını şagirdə öyrətmək','Ticarət işini geniş təbliğ etmək','Coğrafi bilik qazandırmaq'],1),
('edeb5-tebiet#24','edebiyyat','edeb-5-tebiet',3,4,'Beşinci sinif təbiət bölməsi üzrə «anlayış - izah» cütlüyü hansıdır?','Peyzaj bədii əsərdə təbiət təsviridir.',array['Peyzaj - təbiət təsviri','Portret - təbiət təsviri','Peyzaj - qəhrəmanın görünüşü','Süjet - təbiət təsviri'],1),
('edeb5-tebiet#25','edebiyyat','edeb-5-tebiet',3,4,'Aşağıdakı üç şair dövr baxımından necə düzülür? (1 - Fikrət Qoca, 2 - Abdulla Şaiq, 3 - Səməd Vurğun)','Abdulla Şaiq XX əsrin əvvəlində, Səməd Vurğun XX əsrin ortalarında, Fikrət Qoca isə daha sonra yazmışdır.',array['2 - 3 - 1','1 - 2 - 3','3 - 2 - 1','2 - 1 - 3'],1),
('edeb5-tebiet#26','edebiyyat','edeb-5-tebiet',3,4,'Beşinci sinifdə təbiət mövzusu barədə hansı fikir SƏHVDİR?','Təbiət mövzulu əsərlər təbiəti qorumağa çağırır.',array['Təbiət mövzulu əsərlər ağac kəsməyə çağırır','Bu əsərlər təbiəti qorumağa çağırır','Peyzaj təbiət təsviridir','Epitet bədii təyin yaradır'],1),
('edeb5-tebiet#27','edebiyyat','edeb-5-tebiet',3,4,'Səməd Vurğun və Abdulla Şaiq haqqında hansı fikir doğrudur?','Hər ikisi Azərbaycan ədəbiyyatının nümayəndəsidir.',array['Hər ikisi Azərbaycan ədəbiyyatındandır','Hər ikisi Amerika ədəbiyyatındandır','Biri Azərbaycan, digəri fransız ədəbiyyatındandır','Hər ikisi fransız ədəbiyyatındandır'],1),
('edeb5-tebiet#28','edebiyyat','edeb-5-tebiet',3,4,'Beşinci sinif təbiət bölməsi üzrə «əsər - mövzu» cütlüyü hansıdır?','«Şuşa» doğma şəhər, «Çinarın şikayəti» isə təbiətə qayğı mövzusundadır.',array['«Şuşa» - doğma şəhər mövzusu','«Şuşa» - dəniz səfəri mövzusu','«Çinarın şikayəti» - dəniz mövzusu','«Köç» - kosmos mövzusu'],1),
('edeb5-tebiet#29','edebiyyat','edeb-5-tebiet',3,4,'Ədəbiyyatda ekoloji mövzunun yaranmasının səbəbi nədir?','İnsan fəaliyyətinin təbiətə vurduğu zərərdir.',array['İnsanın təbiətə vurduğu zərər','Şəhərlərin sayının azalması','Kitab sayının artması','Ov ənənəsinin bitməsi'],1),
('edeb5-tebiet#30','edebiyyat','edeb-5-tebiet',3,4,'Təbiəti vəsf edən şeir ilə təbiəti müdafiə edən şeirin fərqi nədir?','Biri gözəlliyi göstərir, digəri narahatlıq və çağırış ifadə edir.',array['Biri gözəlliyi, digəri narahatlığı ifadə edir','Biri narahatlığı, digəri gözəlliyi ifadə edir','Hər ikisi eyni məqsəd daşıyır','Hər ikisi ancaq gözəlliyi göstərir'],1),
('edeb5-tebiet#31','edebiyyat','edeb-5-tebiet',3,4,'Beşinci sinif təbiət bölməsi üzrə «şair - əsər» cütlüyü hansıdır?','«Şuşa» şeiri Fikrət Qocanındır.',array['Fikrət Qoca - «Şuşa»','Səməd Vurğun - «Şuşa»','Fikrət Qoca - «Köç»','Abdulla Şaiq - «Şuşa»'],1)
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
   where owner_type = 'platform' and ext_key like 'edeb5-%';
  if n <> 217 then
    raise exception 'Edebiyyat 5 suallari: 217 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'edeb5-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'edeb5-%';
  if k <> 7 then
    raise exception 'movzu sayi 7 deyil: %', k;
  end if;
  --  Her movzuda en azi 12 cetin sual olmalidir ki, muellim BIR
  --  movzudan 10 sualliq cetin test yiga bilsin
  select count(*) into k from (
    select q.topic_id from public.questions q
     where q.ext_key like 'edeb5-%' and q.difficulty = 3
     group by q.topic_id having count(*) < 12) z;
  if k > 0 then
    raise exception '% movzuda 12-den az cetin sual var', k;
  end if;
  raise notice 'Edebiyyat 5 banki: % sual, 7 movzu (her birinde 12 cetin).', n;
end $$;
