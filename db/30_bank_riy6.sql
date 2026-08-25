-- =====================================================================
--  30_bank_riy6.sql : RIYAZIYYAT 6 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy6.py yaradir:
--      python3 tools/riy6.py
--
--  9 movzu x 10 sual = 90.  ext_key: riy6-<movzu>#<sira>.
--  ON SERT: 29_movzular_orta6.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-6-coxluqlar') then
    raise exception 'ONCE 29_movzular_orta6.sql isledilmelidir (riy-6-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy6-%';

with d(ext, topic, diff, rub, body, why, opts, correct) as (values
('riy6-natural-ededler#1','riy-6-natural-ededler',2,1,'Hansı ədəd sadə ədəddir?','13-ün yalnız iki böləni var: 1 və 13.',array['13','9','15','21'],1),
('riy6-natural-ededler#2','riy-6-natural-ededler',2,1,'12 və 18 ədədlərinin ən böyük ortaq böləni (EBOB) neçədir?','12 = 2·2·3; 18 = 2·3·3; ortaq vuruqlar: 2·3 = 6.',array['6','3','36','2'],1),
('riy6-natural-ededler#3','riy-6-natural-ededler',2,1,'4 və 6 ədədlərinin ən kiçik ortaq bölünəni (EKOB) neçədir?','4-ə və 6-ya bölünən ən kiçik ədəd 12-dir.',array['12','24','6','2'],1),
('riy6-natural-ededler#4','riy-6-natural-ededler',2,1,'Hansı ədəd həm 2-yə, həm də 5-ə bölünür?','Sonu 0 ilə bitən ədədlər həm 2-yə, həm 5-ə bölünür: 90.',array['90','85','72','55'],1),
('riy6-natural-ededler#5','riy-6-natural-ededler',2,1,'2⁵ neçəyə bərabərdir?','2⁵ = 2·2·2·2·2 = 32.',array['32','10','25','64'],1),
('riy6-natural-ededler#6','riy-6-natural-ededler',3,1,'Hansı ədəd 9-a qalıqsız bölünür?','Rəqəmlərinin cəmi 9-a bölünən ədəd 9-a bölünür: 7+3+8 = 18.',array['738','728','745','703'],1),
('riy6-natural-ededler#7','riy-6-natural-ededler',2,1,'Hansı ədəd mürəkkəb ədəddir?','21 = 3 · 7 — ikidən çox böləni var; 11, 17, 23 sadədir.',array['21','11','17','23'],1),
('riy6-natural-ededler#8','riy-6-natural-ededler',3,1,'56 ədədinin sadə vuruqlara ayrılışı hansıdır?','56 = 2 · 2 · 2 · 7.',array['2 · 2 · 2 · 7','2 · 4 · 7','2 · 2 · 14','7 · 8'],1),
('riy6-natural-ededler#9','riy-6-natural-ededler',1,1,'10² + 10 neçə edər?','100 + 10 = 110.',array['110','30','1 010','120'],1),
('riy6-natural-ededler#10','riy-6-natural-ededler',2,1,'1 000 000 ədədi 10-un neçənci qüvvətidir?','1 000 000 = 10⁶ — altı sıfır.',array['6','5','7','100'],1),
('riy6-nisbet-faiz#1','riy-6-nisbet-faiz',2,1,'8 : 12 nisbətini sadələşdirin.','Hər iki həddi 4-ə bölək: 2 : 3.',array['2 : 3','3 : 2','4 : 6','1 : 2'],1),
('riy6-nisbet-faiz#2','riy-6-nisbet-faiz',3,1,'Tənasübdə x-i tapın: x : 10 = 6 : 4.','x = 10 · 6 : 4 = 15.',array['15','24','60','12'],1),
('riy6-nisbet-faiz#3','riy-6-nisbet-faiz',3,1,'Sinifdə oğlanların qızlara nisbəti 3 : 2-dir. 15 oğlan varsa, neçə qız var?','Bir pay: 15 : 3 = 5; qızlar: 5 · 2 = 10.',array['10','12','6','30'],1),
('riy6-nisbet-faiz#4','riy-6-nisbet-faiz',2,1,'300-ün 12%-i neçədir?','300 : 100 = 3; 3 · 12 = 36.',array['36','12','25','360'],1),
('riy6-nisbet-faiz#5','riy-6-nisbet-faiz',3,1,'Ədədin 40%-i 28-ə bərabərdirsə, ədədin özü neçədir?','1%: 28 : 40 = 0,7; ədəd: 0,7 · 100 = 70.',array['70','40','112','68'],1),
('riy6-nisbet-faiz#6','riy-6-nisbet-faiz',2,1,'Tənasübün əsas xassəsi hansıdır?','Kənar hədlərin hasili orta hədlərin hasilinə bərabərdir.',array['Kənar hədlərin hasili orta hədlərin hasilinə bərabərdir','Bütün hədlər bərabərdir','Hədlərin cəmi sabitdir','Hədlər həmişə cütdür'],1),
('riy6-nisbet-faiz#7','riy-6-nisbet-faiz',3,1,'Xəritənin miqyası 1 : 100 000-dir. Xəritədə 3 sm olan məsafə həqiqətdə neçə kilometrdir?','3 · 100 000 = 300 000 sm = 3 km.',array['3 km','30 km','300 km','1 km'],1),
('riy6-nisbet-faiz#8','riy-6-nisbet-faiz',2,1,'45-in 60-a nisbəti hansı kəsrlə ifadə olunur?','45/60 = 3/4.',array['3/4','4/3','5/6','1/4'],1),
('riy6-nisbet-faiz#9','riy-6-nisbet-faiz',3,1,'Qarışıqda şəkər və un 1 : 4 nisbətindədir. 500 q qarışıqda neçə qram şəkər var?','Cəmi 5 pay; bir pay: 500 : 5 = 100 q.',array['100 q','125 q','400 q','20 q'],1),
('riy6-nisbet-faiz#10','riy-6-nisbet-faiz',3,1,'20 ədədi 50-nin neçə faizidir?','20/50 = 0,4 = 40%.',array['40%','20%','50%','25%'],1),
('riy6-tam-ededler#1','riy-6-tam-ededler',1,2,'−7 və 3 ədədlərindən hansı böyükdür?','Müsbət ədəd mənfidən həmişə böyükdür.',array['3','−7','Bərabərdirlər','Müqayisə olunmur'],1),
('riy6-tam-ededler#2','riy-6-tam-ededler',2,2,'|−9| (modul) neçəyə bərabərdir?','Ədədin modulu onun sıfırdan məsafəsidir: 9.',array['9','−9','0','18'],1),
('riy6-tam-ededler#3','riy-6-tam-ededler',2,2,'−5 + 7 neçə edər?','Modullar fərqi, böyüyün işarəsi: 2.',array['2','−2','12','−12'],1),
('riy6-tam-ededler#4','riy-6-tam-ededler',2,2,'−4 − 6 neçə edər?','Mənfi ədəddən çıxanda modullar toplanır: −10.',array['−10','2','−2','10'],1),
('riy6-tam-ededler#5','riy-6-tam-ededler',2,2,'(−3) · (−6) hasilini tapın.','Mənfi ilə mənfinin hasili müsbətdir: 18.',array['18','−18','9','−9'],1),
('riy6-tam-ededler#6','riy-6-tam-ededler',2,2,'−20 : 4 neçə edər?','İşarələr fərqlidirsə, qismət mənfidir: −5.',array['−5','5','−16','−24'],1),
('riy6-tam-ededler#7','riy-6-tam-ededler',1,2,'−2 ədədinin əks ədədi hansıdır?','Əks ədədlərin cəmi sıfırdır: 2.',array['2','−2','0','1/2'],1),
('riy6-tam-ededler#8','riy-6-tam-ededler',2,2,'Termometr −3° göstərirdi. Temperatur 5° artdı. İndi termometr neçə dərəcəni göstərir?','−3 + 5 = 2°.',array['2°','−8°','8°','−2°'],1),
('riy6-tam-ededler#9','riy-6-tam-ededler',2,2,'−6, 0, 4 ədədləri hansı sırada düzülüb?','Hər sonrakı ədəd böyükdür — artan sıradadır.',array['Artan','Azalan','Qarışıq','Sıra yoxdur'],1),
('riy6-tam-ededler#10','riy-6-tam-ededler',3,2,'(−1) · (−1) · (−1) hasili neçədir?','Tək sayda mənfi vuruq — nəticə mənfidir: −1.',array['−1','1','−3','0'],1),
('riy6-koordinat#1','riy-6-koordinat',2,2,'Koordinat oxlarının kəsişdiyi nöqtə necə adlanır?','O(0; 0) — koordinat başlanğıcıdır.',array['Koordinat başlanğıcı','Təpə nöqtəsi','Mərkəz qövsü','Kəsişmə bucağı'],1),
('riy6-koordinat#2','riy-6-koordinat',2,2,'A(3; 5) nöqtəsinin yazılışında 3 ədədi nəyi göstərir?','Birinci ədəd absisdir (x koordinatı).',array['Absisi (x-i)','Ordinatı (y-i)','Məsafəni','Bucağı'],1),
('riy6-koordinat#3','riy-6-koordinat',2,2,'Üfüqi koordinat oxu necə adlanır?','Üfüqi ox absis oxudur (Ox).',array['Absis oxu (Ox)','Ordinat oxu (Oy)','Simmetriya oxu','Paralel ox'],1),
('riy6-koordinat#4','riy-6-koordinat',3,2,'B(0; 4) nöqtəsi harada yerləşir?','Absisi 0 olan nöqtə ordinat oxu üzərindədir.',array['Ordinat oxu üzərində','Absis oxu üzərində','Başlanğıcda','II rübdə'],1),
('riy6-koordinat#5','riy-6-koordinat',1,2,'Koordinat müstəvisi oxlarla neçə rübə bölünür?','Oxlar müstəvini 4 rübə bölür.',array['4','2','3','6'],1),
('riy6-koordinat#6','riy-6-koordinat',3,2,'C(−2; 3) nöqtəsi hansı rübdə yerləşir?','x < 0, y > 0 olduqda nöqtə II rübdədir.',array['II rübdə','I rübdə','III rübdə','IV rübdə'],1),
('riy6-koordinat#7','riy-6-koordinat',2,2,'Şaquli koordinat oxu necə adlanır?','Şaquli ox ordinat oxudur (Oy).',array['Ordinat oxu (Oy)','Absis oxu (Ox)','Diaqonal ox','Miqyas oxu'],1),
('riy6-koordinat#8','riy-6-koordinat',3,2,'D(5; 0) nöqtəsi harada yerləşir?','Ordinatı 0 olan nöqtə absis oxu üzərindədir.',array['Absis oxu üzərində','Ordinat oxu üzərində','I rübdə','Heç yerdə'],1),
('riy6-koordinat#9','riy-6-koordinat',3,2,'M(2; 7) və N(2; 1) nöqtələrindən keçən düz xətt hansı oxa paraleldir?','Absislər eynidirsə, xətt Oy oxuna paraleldir.',array['Oy oxuna','Ox oxuna','Heç birinə','Hər ikisinə'],1),
('riy6-koordinat#10','riy-6-koordinat',3,2,'Hansı nöqtə III rübdə yerləşir?','III rübdə hər iki koordinat mənfidir: (−4; −1).',array['(−4; −1)','(4; 1)','(−4; 1)','(4; −1)'],1),
('riy6-coxluqlar#1','riy-6-coxluqlar',1,3,'Çoxluğu təşkil edən obyektlərin hər biri necə adlanır?','Çoxluğun obyektləri onun elementləridir.',array['Element','Rəqəm','Hərf','Qrup'],1),
('riy6-coxluqlar#2','riy-6-coxluqlar',1,3,'A = {1; 2; 3} çoxluğunun neçə elementi var?','Çoxluqda 3 element var.',array['3','6','1','123'],1),
('riy6-coxluqlar#3','riy-6-coxluqlar',2,3,'İki çoxluğun ortaq elementlərindən ibarət çoxluq necə adlanır?','Ortaq elementlər kəsişməni əmələ gətirir.',array['Kəsişmə','Birləşmə','Fərq','Alt çoxluq'],1),
('riy6-coxluqlar#4','riy-6-coxluqlar',2,3,'A = {1; 2; 3}, B = {2; 3; 4}. A ∩ B çoxluğunu tapın.','Ortaq elementlər: 2 və 3.',array['{2; 3}','{1; 2; 3; 4}','{1; 4}','{1}'],1),
('riy6-coxluqlar#5','riy-6-coxluqlar',2,3,'A = {1; 2}, B = {2; 5}. A ∪ B çoxluğunu tapın.','Birləşməyə hər iki çoxluğun bütün elementləri daxildir.',array['{1; 2; 5}','{2}','{1; 5}','{1; 2; 2; 5}'],1),
('riy6-coxluqlar#6','riy-6-coxluqlar',2,3,'Heç bir elementi olmayan çoxluq necə adlanır?','Elementsiz çoxluq boş çoxluqdur.',array['Boş çoxluq','Tam çoxluq','Kiçik çoxluq','Sıfır ədədi'],1),
('riy6-coxluqlar#7','riy-6-coxluqlar',2,3,'Bütün elementləri başqa çoxluğa daxil olan çoxluq necə adlanır?','Belə çoxluq alt çoxluqdur.',array['Alt çoxluq','Üst çoxluq','Kəsişmə','Qalıq'],1),
('riy6-coxluqlar#8','riy-6-coxluqlar',3,3,'C = {a; b; c; d} çoxluğundan neçə birelementli alt çoxluq ayırmaq olar?','Hər elementdən bir alt çoxluq: 4.',array['4','1','16','2'],1),
('riy6-coxluqlar#9','riy-6-coxluqlar',3,3,'Cüt ədədlər çoxluğu ilə tək ədədlər çoxluğunun kəsişməsi nədir?','Həm cüt, həm tək ədəd yoxdur — kəsişmə boşdur.',array['Boş çoxluqdur','Bütün ədədlərdir','Yalnız sıfırdır','Yalnız 1-dir'],1),
('riy6-coxluqlar#10','riy-6-coxluqlar',2,3,'{5; 10; 15; 20; …} çoxluğunun elementlərini birləşdirən ümumi xassə hansıdır?','Hamısı 5-ə bölünür.',array['5-ə bölünmə','Cüt olma','Tək olma','Sadə olma'],1),
('riy6-ifade-tenlik#1','riy-6-ifade-tenlik',2,3,'7x − 2x ifadəsini sadələşdirin.','Oxşar hədlər: (7 − 2)x = 5x.',array['5x','9x','5','14x'],1),
('riy6-ifade-tenlik#2','riy-6-ifade-tenlik',2,3,'3(x + 4) mötərizəsini açın.','Paylama qanunu: 3x + 12.',array['3x + 12','3x + 4','x + 12','7x'],1),
('riy6-ifade-tenlik#3','riy-6-ifade-tenlik',2,3,'4x = −20 tənliyinin kökü neçədir?','x = −20 : 4 = −5.',array['−5','5','−16','−80'],1),
('riy6-ifade-tenlik#4','riy-6-ifade-tenlik',2,3,'x + 15 = 9 tənliyini həll edin.','x = 9 − 15 = −6.',array['−6','6','24','−24'],1),
('riy6-ifade-tenlik#5','riy-6-ifade-tenlik',2,3,'2x + 3 = 19 tənliyinin kökü neçədir?','2x = 16; x = 8.',array['8','11','16','38'],1),
('riy6-ifade-tenlik#6','riy-6-ifade-tenlik',2,3,'x : 3 = −7 tənliyində x-i tapın.','x = −7 · 3 = −21.',array['−21','21','−4','−10'],1),
('riy6-ifade-tenlik#7','riy-6-ifade-tenlik',3,3,'5 − x = 12 tənliyinin kökü neçədir?','x = 5 − 12 = −7.',array['−7','7','17','−17'],1),
('riy6-ifade-tenlik#8','riy-6-ifade-tenlik',2,3,'x > −2 bərabərsizliyini hansı ədəd ödəyir?','0 ədədi −2-dən böyükdür.',array['0','−3','−5','−10'],1),
('riy6-ifade-tenlik#9','riy-6-ifade-tenlik',3,3,'a = −2 olduqda 3a + 11 ifadəsinin qiyməti neçədir?','3 · (−2) = −6; −6 + 11 = 5.',array['5','17','−17','−5'],1),
('riy6-ifade-tenlik#10','riy-6-ifade-tenlik',3,3,'Ədədin 3 misli ilə 5-in cəmi 26-dır. Ədədi tapın.','3x + 5 = 26; 3x = 21; x = 7.',array['7','21','31','9'],1),
('riy6-ucbucaqlar#1','riy-6-ucbucaqlar',2,3,'Üçbucağın daxili bucaqlarının cəmi neçə dərəcədir?','İstənilən üçbucaqda bucaqların cəmi 180°-dir.',array['180°','90°','360°','100°'],1),
('riy6-ucbucaqlar#2','riy-6-ucbucaqlar',2,3,'Bərabərtərəfli üçbucağın hər bucağı neçə dərəcədir?','180 : 3 = 60°.',array['60°','90°','45°','120°'],1),
('riy6-ucbucaqlar#3','riy-6-ucbucaqlar',2,3,'Üçbucağın iki bucağı 50° və 60°-dirsə, üçüncü bucağı tapın.','180 − 50 − 60 = 70°.',array['70°','110°','80°','60°'],1),
('riy6-ucbucaqlar#4','riy-6-ucbucaqlar',2,3,'İki tərəfi bərabər olan üçbucaq necə adlanır?','İki bərabər tərəfli üçbucaq bərabəryanlıdır.',array['Bərabəryanlı','Bərabərtərəfli','Müxtəliftərəfli','Düzbucaqlı'],1),
('riy6-ucbucaqlar#5','riy-6-ucbucaqlar',3,3,'Düzbucaqlı üçbucaqda iti bucaqların cəmi neçə dərəcədir?','180 − 90 = 90°.',array['90°','180°','45°','100°'],1),
('riy6-ucbucaqlar#6','riy-6-ucbucaqlar',2,3,'Bütün bucaqları iti olan üçbucaq necə adlanır?','Hər üç bucağı iti olan üçbucaq itibucaqlıdır.',array['İtibucaqlı','Korbucaqlı','Düzbucaqlı','Bərabəryanlı'],1),
('riy6-ucbucaqlar#7','riy-6-ucbucaqlar',2,3,'Tərəfləri 6 sm, 8 sm və 10 sm olan üçbucağın perimetri neçədir?','P = 6 + 8 + 10 = 24 sm.',array['24 sm','22 sm','26 sm','48 sm'],1),
('riy6-ucbucaqlar#8','riy-6-ucbucaqlar',3,3,'Üçbucağın bir tərəfi digər iki tərəfin cəmindən böyük ola bilərmi?','Xeyr — üçbucaq bərabərsizliyinə görə ola bilməz.',array['Xeyr, ola bilməz','Bəli, həmişə','Yalnız düzbucaqlıda','Yalnız bərabəryanlıda'],1),
('riy6-ucbucaqlar#9','riy-6-ucbucaqlar',3,3,'Bərabəryanlı üçbucağın oturacağına bitişik bucaqları necədir?','Oturacaq bucaqları bərabərdir.',array['Bərabərdir','Fərqlidir','Həmişə 90°-dir','Kor bucaqdır'],1),
('riy6-ucbucaqlar#10','riy-6-ucbucaqlar',2,3,'Bucaqlarından biri kor olan üçbucaq necə adlanır?','Kor bucağı olan üçbucaq korbucaqlıdır.',array['Korbucaqlı','İtibucaqlı','Düzbucaqlı','Bərabərtərəfli'],1),
('riy6-sahe-hecm#1','riy-6-sahe-hecm',2,4,'Paraleloqramın sahəsi necə hesablanır?','S = oturacaq × hündürlük.',array['Oturacaq × hündürlük','Tərəflərin cəmi','Diaqonalların cəmi','Perimetr × 2'],1),
('riy6-sahe-hecm#2','riy-6-sahe-hecm',2,4,'Oturacağı 10 sm, hündürlüyü 6 sm olan paraleloqramın sahəsi neçədir?','S = 10 · 6 = 60 sm².',array['60 sm²','30 sm²','16 sm²','32 sm²'],1),
('riy6-sahe-hecm#3','riy-6-sahe-hecm',2,4,'Oturacağı 12 sm, hündürlüyü 5 sm olan üçbucağın sahəsini tapın.','S = (12 · 5) : 2 = 30 sm².',array['30 sm²','60 sm²','17 sm²','34 sm²'],1),
('riy6-sahe-hecm#4','riy-6-sahe-hecm',2,4,'Tili 5 sm olan kubun həcmini tapın.','V = 5³ = 125 sm³.',array['125 sm³','25 sm³','15 sm³','150 sm³'],1),
('riy6-sahe-hecm#5','riy-6-sahe-hecm',2,4,'Ölçüləri 7 sm, 4 sm və 3 sm olan düzbucaqlı paralelepipedin həcmi neçədir?','V = 7 · 4 · 3 = 84 sm³.',array['84 sm³','14 sm³','28 sm³','168 sm³'],1),
('riy6-sahe-hecm#6','riy-6-sahe-hecm',3,4,'1 sm² neçə kvadrat millimetrdir?','1 sm = 10 mm; 10 · 10 = 100 mm².',array['100 mm²','10 mm²','1 000 mm²','20 mm²'],1),
('riy6-sahe-hecm#7','riy-6-sahe-hecm',3,4,'Trapesiyanın sahəsi necə tapılır?','Oturacaqların cəminin yarısı hündürlüyə vurulur.',array['Oturacaqlar cəminin yarısı × hündürlük','Bütün tərəflərin cəmi','Diaqonalların hasili','Oturacaqların fərqi × 2'],1),
('riy6-sahe-hecm#8','riy-6-sahe-hecm',3,4,'Sahəsi 48 sm², oturacağı 8 sm olan paraleloqramın hündürlüyü neçədir?','h = S : a = 48 : 8 = 6 sm.',array['6 sm','8 sm','40 sm','384 sm'],1),
('riy6-sahe-hecm#9','riy-6-sahe-hecm',3,4,'Kubun bütün tillərinin uzunluqları cəmi 36 sm-dirsə, bir til neçə santimetrdir?','Kubun 12 tili var: 36 : 12 = 3 sm.',array['3 sm','6 sm','12 sm','4 sm'],1),
('riy6-sahe-hecm#10','riy-6-sahe-hecm',3,4,'Rombun sahəsi diaqonalları ilə necə tapılır?','S = diaqonalların hasilinin yarısı.',array['Diaqonalların hasilinin yarısı','Diaqonalların cəmi','Tərəflərin hasili','Perimetrin yarısı'],1),
('riy6-statistika#1','riy-6-statistika',3,4,'Zər atılanda cüt ədəd düşməsi ehtimalı neçədir?','6 üzdən 3-ü cütdür: 3/6 = 1/2.',array['1/2','1/6','1/3','2/3'],1),
('riy6-statistika#2','riy-6-statistika',2,4,'Ehtimal hansı qiymətlər arasında dəyişir?','Ehtimal 0 ilə 1 arasında olur.',array['0 ilə 1 arasında','1 ilə 10 arasında','−1 ilə 1 arasında','10 ilə 100 arasında'],1),
('riy6-statistika#3','riy-6-statistika',2,4,'Yəqin (mütləq baş verən) hadisənin ehtimalı neçədir?','Mütləq hadisənin ehtimalı 1-dir.',array['1','0','1/2','100'],1),
('riy6-statistika#4','riy-6-statistika',3,4,'Qutuda 2 qırmızı və 3 mavi kürəcik var. Qırmızı kürəcik çıxarma ehtimalı neçədir?','Cəmi 5 kürəcik: 2/5.',array['2/5','3/5','1/2','2/3'],1),
('riy6-statistika#5','riy-6-statistika',2,4,'5, 8, 8, 9, 10 sırasında moda (ən çox təkrarlanan) hansıdır?','8 iki dəfə təkrarlanır.',array['8','5','10','9'],1),
('riy6-statistika#6','riy-6-statistika',2,4,'12, 15, 18, 15 ədədlərinin ədədi ortası neçədir?','(12 + 15 + 18 + 15) : 4 = 60 : 4 = 15.',array['15','12','60','18'],1),
('riy6-statistika#7','riy-6-statistika',3,4,'Median nədir?','Sıralanmış sıranın ortasındakı qiymətdir.',array['Sıralanmış sıranın ortasındakı qiymət','Ən böyük qiymət','Qiymətlərin cəmi','Ən çox təkrarlanan qiymət'],1),
('riy6-statistika#8','riy-6-statistika',3,4,'3, 7, 9, 11, 20 sırasının medianı neçədir?','Beş ədədin ortadakısı üçüncüdür: 9.',array['9','7','10','11'],1),
('riy6-statistika#9','riy-6-statistika',2,4,'Mümkünsüz hadisənin ehtimalı neçədir?','Baş verə bilməyən hadisənin ehtimalı 0-dır.',array['0','1','1/2','−1'],1),
('riy6-statistika#10','riy-6-statistika',2,4,'Sütunlu diaqram nəyi göstərmək üçün əlverişlidir?','Kəmiyyətləri müqayisə etmək üçün əlverişlidir.',array['Kəmiyyətlərin müqayisəsini','Yalnız rəngləri','Xəritəni','Hərfləri'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = 'riyaziyyat'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '6'
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
   where owner_type = 'platform' and ext_key like 'riy6-%';
  if n <> 90 then
    raise exception 'riy6 suallari: 90 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy6-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy6-%';
  if k <> 9 then
    raise exception 'movzu sayi 9 deyil: %', k;
  end if;
  raise notice 'Riyaziyyat 6 banki: % sual, 9 movzu.', n;
end $$;
