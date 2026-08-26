-- =====================================================================
--  16_bank_riy4.sql : RIYAZIYYAT 4 PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/riy4.py yaradir:
--      python3 tools/riy4.py
--  Skript her riyazi cavabi YENIDEN HESABLAYIB duzgun variantla
--  tutusdurur, sonra bu SQL-i cixarir.  Duzelis skriptde edilir.
--
--  12 movzu x 10 sual = 120.  Suallar orijinaldir - e-derslikden
--  yalniz movzu adlari goturulub (15_movzular_ederslik.sql).
--
--  Suallar ext_key ile taninir (riy4-<movzu>#<sira>) - tekrar
--  isledilende coxalmir, uzerine yazilir.  07-deki qayda ile:
--  suallar SILINMIR (test_questions restrict), yalniz variantlar
--  temizlenib yeniden yazilir.
--
--  ON SERT: 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-4-coxreqemli') then
    raise exception 'ONCE 15_movzular_ederslik.sql isledilmelidir (riy-4-* movzulari yoxdur).';
  end if;
end $$;

-- Kohne variantlar temizlenir (suallar yox - onlara cavablar bagli ola biler)
delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy4-%';

with d(ext, topic, diff, rub, body, why, opts, correct) as (values
('riy4-coxreqemli#1','riy-4-coxreqemli',2,1,'«Üç yüz qırx beş min iki yüz on səkkiz» ədədi rəqəmlə necə yazılır?','300 000 + 45 000 + 218 = 345 218.',array['345 218','34 518','345 281','3 045 218'],1),
('riy4-coxreqemli#2','riy-4-coxreqemli',2,1,'507 090 ədədində minlər mərtəbəsində hansı rəqəm durur?','507 090 — burada 507 min var: minlər mərtəbəsində 7-dir.',array['7','0','5','9'],1),
('riy4-coxreqemli#3','riy-4-coxreqemli',2,1,'82 356 ədədini yüzlüklərə qədər yuvarlaqlaşdırın.','Onluqlar mərtəbəsində 5 olduğu üçün yuxarı yuvarlaqlaşır.',array['82 400','82 300','82 000','82 360'],1),
('riy4-coxreqemli#4','riy-4-coxreqemli',2,1,'Ədədlər hansı sırada artan ardıcıllıqla düzülüb?','Əvvəl minlər, sonra yüzlər müqayisə olunur: 9 099 < 9 909 < 9 990.',array['9 099, 9 909, 9 990','9 909, 9 099, 9 990','9 990, 9 909, 9 099','9 099, 9 990, 9 909'],1),
('riy4-coxreqemli#5','riy-4-coxreqemli',1,1,'199 999 ədədindən bilavasitə sonra gələn ədəd hansıdır?','Sonra gələn ədəd 1 vahid çoxdur: 199 999 + 1 = 200 000.',array['200 000','199 998','210 000','199 990'],1),
('riy4-coxreqemli#6','riy-4-coxreqemli',3,1,'Tərkibində 6 yüzminlik, 3 minlik və 8 təklik olan ədəd hansıdır?','600 000 + 3 000 + 8 = 603 008.',array['603 008','63 008','600 308','603 800'],1),
('riy4-coxreqemli#7','riy-4-coxreqemli',2,1,'745 632 ədədində 4 rəqəmi hansı mərtəbədə durur?','745 632: 7 — yüz minlər, 4 — on minlər, 5 — minlər mərtəbəsidir.',array['On minlər','Minlər','Yüz minlər','Yüzlər'],1),
('riy4-coxreqemli#8','riy-4-coxreqemli',3,1,'Ən böyük beşrəqəmli ədədlə ən kiçik beşrəqəmli ədədin fərqi neçədir?','99 999 − 10 000 = 89 999.',array['89 999','90 000','99 999','89 990'],1),
('riy4-coxreqemli#9','riy-4-coxreqemli',3,1,'340 500 ədədini minliklərə qədər yuvarlaqlaşdırın.','Yüzlər mərtəbəsində 5 olduğundan yuxarı yuvarlaqlaşır.',array['341 000','340 000','340 500','350 000'],1),
('riy4-coxreqemli#10','riy-4-coxreqemli',3,1,'2, 0, 4, 7 rəqəmlərinin hər birini bir dəfə işlətməklə yazıla bilən ən kiçik dördrəqəmli ədəd hansıdır?','Ədəd 0 ilə başlaya bilməz, ona görə ən kiçiyi 2 047-dir.',array['2 047','2 074','2 407','7 420'],1),
('riy4-toplama-cixma#1','riy-4-toplama-cixma',2,1,'45 236 + 28 457 əməlini yerinə yetirin.','Mərtəbə-mərtəbə toplayın: 45 236 + 28 457 = 73 693.',array['73 693','73 583','73 793','63 693'],1),
('riy4-toplama-cixma#2','riy-4-toplama-cixma',2,1,'60 000 − 24 375 fərqini tapın.','Sıfırlardan borc alınır: 60 000 − 24 375 = 35 625.',array['35 625','35 635','36 625','45 625'],1),
('riy4-toplama-cixma#3','riy-4-toplama-cixma',2,1,'123 456 + 76 544 cəmini hesablayın.','123 456 + 76 544 = 200 000.',array['200 000','199 000','200 010','190 000'],1),
('riy4-toplama-cixma#4','riy-4-toplama-cixma',2,1,'İki ədədin cəmi 90 000-dir. Onlardan biri 36 250 olarsa, o biri neçədir?','90 000 − 36 250 = 53 750.',array['53 750','54 750','53 250','63 750'],1),
('riy4-toplama-cixma#5','riy-4-toplama-cixma',3,1,'500 000 − 123 456 neçə edər?','500 000 − 123 456 = 376 544.',array['376 544','376 644','386 544','377 544'],1),
('riy4-toplama-cixma#6','riy-4-toplama-cixma',1,1,'8 704 + 12 296 cəmini tapın.','8 704 + 12 296 = 21 000.',array['21 000','20 990','21 100','20 000'],1),
('riy4-toplama-cixma#7','riy-4-toplama-cixma',3,1,'Çıxılan 40 000, fərq 15 380-dirsə, çıxan neçədir?','Çıxan = çıxılan − fərq = 40 000 − 15 380 = 24 620.',array['24 620','25 620','24 720','55 380'],1),
('riy4-toplama-cixma#8','riy-4-toplama-cixma',1,1,'25 634 + 25 634 neçə edər?','Ədədin 2 misli: 25 634 + 25 634 = 51 268.',array['51 268','50 268','51 168','51 368'],1),
('riy4-toplama-cixma#9','riy-4-toplama-cixma',2,1,'71 205 − 34 618 fərqini tapıb toplama ilə yoxlayın.','36 587 + 34 618 = 71 205 — deməli fərq düzgündür.',array['36 587','36 687','37 587','36 597'],1),
('riy4-toplama-cixma#10','riy-4-toplama-cixma',3,1,'Ardıcıl iki natural ədədin cəmi 4 001-dir. Kiçik ədədi tapın.','(4 001 − 1) : 2 = 2 000; ədədlər 2 000 və 2 001-dir.',array['2 000','2 001','1 999','2 500'],1),
('riy4-vurma-bolme#1','riy-4-vurma-bolme',1,1,'1 234 × 4 hasilini tapın.','1 234 × 4 = 4 936.',array['4 936','4 836','4 946','5 936'],1),
('riy4-vurma-bolme#2','riy-4-vurma-bolme',2,1,'2 508 × 7 neçə edər?','2 508 × 7 = 17 556.',array['17 556','17 456','18 556','17 656'],1),
('riy4-vurma-bolme#3','riy-4-vurma-bolme',2,1,'9 648 : 8 qismətini tapın.','9 648 : 8 = 1 206.',array['1 206','1 216','1 106','1 260'],1),
('riy4-vurma-bolme#4','riy-4-vurma-bolme',2,1,'15 435 : 5 neçə edər?','15 435 : 5 = 3 087.',array['3 087','3 187','3 077','3 870'],1),
('riy4-vurma-bolme#5','riy-4-vurma-bolme',2,1,'3 006 × 9 hasilini hesablayın.','3 006 × 9 = 27 054; aradakı sıfırlar unudulmamalıdır.',array['27 054','27 154','26 954','27 540'],1),
('riy4-vurma-bolme#6','riy-4-vurma-bolme',1,1,'36 000 : 6 neçə edər?','36 : 6 = 6, deməli 36 000 : 6 = 6 000.',array['6 000','600','6 100','60 000'],1),
('riy4-vurma-bolme#7','riy-4-vurma-bolme',3,1,'7 214 × 6 hasilini tapın.','7 214 × 6 = 43 284.',array['43 284','43 184','42 284','43 294'],1),
('riy4-vurma-bolme#8','riy-4-vurma-bolme',3,1,'45 927 : 9 qismətini hesablayın.','45 927 : 9 = 5 103.',array['5 103','5 113','5 013','5 130'],1),
('riy4-vurma-bolme#9','riy-4-vurma-bolme',3,1,'48 ədədinin bütün bölənləri hansı sırada tam göstərilib?','Hər biri 48-i qalıqsız bölür və siyahı tam olmalıdır.',array['1, 2, 3, 4, 6, 8, 12, 16, 24, 48','1, 2, 4, 6, 8, 12, 24, 48','2, 3, 4, 6, 8, 12, 16, 24','1, 2, 3, 4, 6, 8, 12, 24, 48'],1),
('riy4-vurma-bolme#10','riy-4-vurma-bolme',2,1,'Hasil 5 600-dür. Vuruqlardan biri 8 olarsa, o biri neçədir?','Naməlum vuruq = hasil : məlum vuruq = 5 600 : 8 = 700.',array['700','70','800','7 000'],1),
('riy4-ifade-tenlik#1','riy-4-ifade-tenlik',2,2,'36 + 24 : 6 ifadəsinin qiymətini tapın.','Əvvəl bölmə: 24 : 6 = 4; sonra 36 + 4 = 40.',array['40','10','42','30'],1),
('riy4-ifade-tenlik#2','riy-4-ifade-tenlik',1,2,'x + 250 = 600 tənliyində x-i tapın.','x = 600 − 250 = 350.',array['350','850','450','250'],1),
('riy4-ifade-tenlik#3','riy-4-ifade-tenlik',2,2,'x · 8 = 720 tənliyinin kökü neçədir?','x = 720 : 8 = 90.',array['90','80','5 760','712'],1),
('riy4-ifade-tenlik#4','riy-4-ifade-tenlik',2,2,'(90 − 54) : 4 ifadəsinin qiyməti neçədir?','Əvvəl mötərizə: 90 − 54 = 36; sonra 36 : 4 = 9.',array['9','36','13','18'],1),
('riy4-ifade-tenlik#5','riy-4-ifade-tenlik',2,2,'x : 7 = 60 tənliyində x neçədir?','Bölünən = qismət · bölən = 60 · 7 = 420.',array['420','67','8','350'],1),
('riy4-ifade-tenlik#6','riy-4-ifade-tenlik',3,2,'5 · (18 − 9) + 12 ifadəsini hesablayın.','5 · 9 = 45; 45 + 12 = 57.',array['57','45','93','62'],1),
('riy4-ifade-tenlik#7','riy-4-ifade-tenlik',1,2,'100 − x = 37 tənliyinin kökü neçədir?','x = 100 − 37 = 63.',array['63','137','73','53'],1),
('riy4-ifade-tenlik#8','riy-4-ifade-tenlik',3,2,'640 : 8 · 3 ifadəsinin qiymətini tapın.','Bölmə və vurma soldan sağa yerinə yetirilir: 80 · 3 = 240.',array['240','27','80','1 920'],1),
('riy4-ifade-tenlik#9','riy-4-ifade-tenlik',3,2,'a = 25, b = 4 olduqda a · b − a ifadəsinin qiyməti neçədir?','25 · 4 = 100; 100 − 25 = 75.',array['75','100','4','79'],1),
('riy4-ifade-tenlik#10','riy-4-ifade-tenlik',2,2,'Tənliyi həll edin: 3 · x = 96.','x = 96 : 3 = 32.',array['32','93','99','288'],1),
('riy4-vurma-bolme-2#1','riy-4-vurma-bolme-2',1,2,'240 × 10 neçə edər?','10-a vuranda ədədin sağına bir sıfır əlavə olunur.',array['2 400','240','24 000','2 500'],1),
('riy4-vurma-bolme-2#2','riy-4-vurma-bolme-2',1,2,'35 600 : 100 neçə edər?','100-ə bölanda sağdan iki sıfır atılır.',array['356','3 560','36','355'],1),
('riy4-vurma-bolme-2#3','riy-4-vurma-bolme-2',2,2,'46 × 25 hasilini tapın.','46 × 25 = 46 × 100 : 4 = 1 150.',array['1 150','1 050','1 140','1 250'],1),
('riy4-vurma-bolme-2#4','riy-4-vurma-bolme-2',3,2,'84 × 36 neçə edər?','84 × 36 = 84 × 30 + 84 × 6 = 2 520 + 504 = 3 024.',array['3 024','3 004','2 924','3 124'],1),
('riy4-vurma-bolme-2#5','riy-4-vurma-bolme-2',3,2,'1 728 : 12 qismətini hesablayın.','1 728 : 12 = 144.',array['144','134','154','1 440'],1),
('riy4-vurma-bolme-2#6','riy-4-vurma-bolme-2',2,2,'950 : 25 neçə edər?','950 : 25 = 38, çünki 25 × 38 = 950.',array['38','36','45','380'],1),
('riy4-vurma-bolme-2#7','riy-4-vurma-bolme-2',1,2,'70 × 40 hasilini tapın.','7 × 4 = 28; sıfırları əlavə edin: 2 800.',array['2 800','2 400','280','2 700'],1),
('riy4-vurma-bolme-2#8','riy-4-vurma-bolme-2',2,2,'13 × 15 neçə edər?','13 × 15 = 13 × 10 + 13 × 5 = 130 + 65 = 195.',array['195','185','205','145'],1),
('riy4-vurma-bolme-2#9','riy-4-vurma-bolme-2',3,2,'2 448 : 24 qismətini tapın.','2 448 : 24 = 102; qismətdəki sıfır unudulmamalıdır.',array['102','12','120','112'],1),
('riy4-vurma-bolme-2#10','riy-4-vurma-bolme-2',2,2,'72 × 50 hasilini hesablayın.','72 × 5 = 360; bir sıfır əlavə edin: 3 600.',array['3 600','360','3 500','3 700'],1),
('riy4-fiqurlar#1','riy-4-fiqurlar',1,2,'Tərəfi 8 sm olan kvadratın perimetrini tapın.','P = 4 · a = 4 · 8 = 32 sm.',array['32 sm','16 sm','64 sm','24 sm'],1),
('riy4-fiqurlar#2','riy-4-fiqurlar',2,2,'Uzunluğu 12 sm, eni 7 sm olan düzbucaqlının sahəsini tapın.','S = a · b = 12 · 7 = 84 sm².',array['84 sm²','38 sm²','19 sm²','74 sm²'],1),
('riy4-fiqurlar#3','riy-4-fiqurlar',2,2,'Perimetri 36 sm olan kvadratın tərəfi neçə santimetrdir?','a = P : 4 = 36 : 4 = 9 sm.',array['9 sm','6 sm','12 sm','18 sm'],1),
('riy4-fiqurlar#4','riy-4-fiqurlar',3,2,'Düzbucaqlının sahəsi 96 sm², uzunluğu 12 sm-dir. Enini tapın.','b = S : a = 96 : 12 = 8 sm.',array['8 sm','84 sm','6 sm','12 sm'],1),
('riy4-fiqurlar#5','riy-4-fiqurlar',1,2,'Tərəfləri 7 sm, 9 sm və 12 sm olan üçbucağın perimetri neçədir?','P = 7 + 9 + 12 = 28 sm.',array['28 sm','26 sm','30 sm','63 sm'],1),
('riy4-fiqurlar#6','riy-4-fiqurlar',2,2,'Sahəsi 49 sm² olan kvadratın tərəfi neçə santimetrdir?','7 · 7 = 49, deməli tərəf 7 sm-dir.',array['7 sm','12 sm','14 sm','9 sm'],1),
('riy4-fiqurlar#7','riy-4-fiqurlar',1,2,'Düz bucaq neçə dərəcədir?','Düz bucaq 90°-dir.',array['90°','45°','180°','60°'],1),
('riy4-fiqurlar#8','riy-4-fiqurlar',2,2,'Uzunluğu 15 sm, eni 4 sm olan düzbucaqlının perimetrini tapın.','P = 2 · (15 + 4) = 38 sm.',array['38 sm','60 sm','19 sm','34 sm'],1),
('riy4-fiqurlar#9','riy-4-fiqurlar',2,2,'Kubun neçə üzü var?','Kubun 6 üzü, 12 tili, 8 təpəsi var.',array['6','4','8','12'],1),
('riy4-fiqurlar#10','riy-4-fiqurlar',3,2,'1 m² neçə kvadrat santimetrdir?','1 m = 100 sm; 100 · 100 = 10 000 sm².',array['10 000 sm²','100 sm²','1 000 sm²','100 000 sm²'],1),
('riy4-kesr#1','riy-4-kesr',1,3,'3/8 və 5/8 kəsrlərindən hansı böyükdür?','Məxrəclər eynidirsə, surəti böyük olan kəsr böyükdür.',array['5/8','3/8','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy4-kesr#2','riy-4-kesr',2,3,'60-ın 1/5 hissəsi neçədir?','60 : 5 = 12.',array['12','5','20','300'],1),
('riy4-kesr#3','riy-4-kesr',3,3,'84-ün 3/7 hissəsini tapın.','84 : 7 = 12; 12 · 3 = 36.',array['36','12','28','63'],1),
('riy4-kesr#4','riy-4-kesr',3,3,'Hansı ədədin 1/6 hissəsi 9-a bərabərdir?','9 · 6 = 54.',array['54','15','45','3'],1),
('riy4-kesr#5','riy-4-kesr',2,3,'1/2, 1/3 və 1/4 kəsrlərindən ən böyüyü hansıdır?','Surətlər eynidirsə, məxrəci kiçik olan kəsr böyükdür.',array['1/2','1/3','1/4','Hamısı bərabərdir'],1),
('riy4-kesr#6','riy-4-kesr',2,3,'45-in 2/9 hissəsi neçədir?','45 : 9 = 5; 5 · 2 = 10.',array['10','5','18','90'],1),
('riy4-kesr#7','riy-4-kesr',1,3,'5/5 kəsri nəyə bərabərdir?','Surət məxrəcə bərabərdirsə, kəsr 1 tama bərabərdir.',array['1 tam','0','5','1/5'],1),
('riy4-kesr#8','riy-4-kesr',1,3,'7/10 kəsrində məxrəc hansı ədəddir?','Kəsr xəttinin altındakı ədəd məxrəcdir.',array['10','7','17','70'],1),
('riy4-kesr#9','riy-4-kesr',2,3,'100-ün 3/4 hissəsini tapın.','100 : 4 = 25; 25 · 3 = 75.',array['75','25','30','60'],1),
('riy4-kesr#10','riy-4-kesr',2,3,'Hansı kəsr 1-dən böyükdür?','Surəti məxrəcindən böyük olan kəsr 1-dən böyükdür.',array['9/7','7/9','5/5','3/8'],1),
('riy4-onluq-kesr#1','riy-4-onluq-kesr',2,3,'3,7 + 2,5 cəmini tapın.','Vergüllər alt-alta yazılır: 3,7 + 2,5 = 6,2.',array['6,2','5,2','6,12','5,12'],1),
('riy4-onluq-kesr#2','riy-4-onluq-kesr',2,3,'5 − 1,8 fərqini hesablayın.','5,0 − 1,8 = 3,2.',array['3,2','4,2','3,8','4,8'],1),
('riy4-onluq-kesr#3','riy-4-onluq-kesr',2,3,'0,9 və 0,45 ədədlərindən hansı böyükdür?','0,9 = 0,90; 90 > 45 olduğundan 0,9 böyükdür.',array['0,9','0,45','Bərabərdirlər','Müqayisə mümkün deyil'],1),
('riy4-onluq-kesr#4','riy-4-onluq-kesr',2,3,'2,45 + 3,55 neçə edər?','2,45 + 3,55 = 6,00 = 6.',array['6','5,90','6,10','5,100'],1),
('riy4-onluq-kesr#5','riy-4-onluq-kesr',1,3,'«7 tam onda 3» onluq kəsrlə necə yazılır?','Tam hissə 7, onda birlər 3: 7,3.',array['7,3','7,03','73','3,7'],1),
('riy4-onluq-kesr#6','riy-4-onluq-kesr',2,3,'4,6 × 10 neçə edər?','10-a vuranda vergül bir mərtəbə sağa keçir: 46.',array['46','4,60','460','0,46'],1),
('riy4-onluq-kesr#7','riy-4-onluq-kesr',2,3,'38 : 10 neçə edər?','10-a bölanda vergül bir mərtəbə sola keçir: 3,8.',array['3,8','0,38','380','3,08'],1),
('riy4-onluq-kesr#8','riy-4-onluq-kesr',3,3,'12,5 − 4,7 fərqini tapın.','12,5 − 4,7 = 7,8.',array['7,8','8,8','7,2','8,2'],1),
('riy4-onluq-kesr#9','riy-4-onluq-kesr',3,3,'0,25 hansı adi kəsrə bərabərdir?','0,25 = 25/100 = 1/4.',array['1/4','1/2','2/5','1/25'],1),
('riy4-onluq-kesr#10','riy-4-onluq-kesr',3,3,'Hansı bərabərlik doğrudur?','Onluq kəsrin sonuna sıfır artırmaq qiymətini dəyişmir.',array['1,05 = 1,050','1,5 = 1,05','0,3 > 0,30','2,4 < 2,04'],1),
('riy4-pullar#1','riy-4-pullar',1,3,'Bir manatda neçə qəpik var?','1 manat = 100 qəpik.',array['100 qəpik','10 qəpik','50 qəpik','1 000 qəpik'],1),
('riy4-pullar#2','riy-4-pullar',2,3,'3 man 45 qəp + 2 man 80 qəp neçə edər?','45 + 80 = 125 qəpik = 1 man 25 qəp; cəmi 6 man 25 qəp.',array['6 man 25 qəp','5 man 25 qəp','6 man 15 qəp','5 man 65 qəp'],1),
('riy4-pullar#3','riy-4-pullar',2,3,'Aysu 10 manatla 2 man 75 qəp ödədi. Qalığı neçədir?','10 man − 2 man 75 qəp = 7 man 25 qəp.',array['7 man 25 qəp','8 man 25 qəp','7 man 75 qəp','6 man 25 qəp'],1),
('riy4-pullar#4','riy-4-pullar',2,3,'Hər biri 60 qəpik olan 5 dəftərin qiyməti neçədir?','60 · 5 = 300 qəpik = 3 manat.',array['3 manat','2 man 40 qəp','3 man 60 qəp','65 qəpik'],1),
('riy4-pullar#5','riy-4-pullar',2,3,'Qiyməti 12 man 50 qəp olan kitabdan 2 ədəd alındı. Cəmi nə qədər ödənildi?','12 man 50 qəp · 2 = 25 manat.',array['25 manat','24 manat','25 man 50 qəp','24 man 50 qəp'],1),
('riy4-pullar#6','riy-4-pullar',1,3,'50 qəp + 20 qəp + 20 qəp + 10 qəp neçə edər?','50 + 20 + 20 + 10 = 100 qəpik = 1 manat.',array['1 manat','90 qəpik','1 man 10 qəp','80 qəpik'],1),
('riy4-pullar#7','riy-4-pullar',3,3,'Kitab 8 man 40 qəp, jurnal ondan 3 man 15 qəp ucuzdur. Jurnalın qiyməti neçədir?','8 man 40 qəp − 3 man 15 qəp = 5 man 25 qəp.',array['5 man 25 qəp','5 man 35 qəp','11 man 55 qəp','5 man 15 qəp'],1),
('riy4-pullar#8','riy-4-pullar',2,3,'100 manat 4 nəfər arasında bərabər bölünərsə, hərəyə nə qədər düşər?','100 : 4 = 25 manat.',array['25 manat','20 manat','40 manat','50 manat'],1),
('riy4-pullar#9','riy-4-pullar',2,3,'Hər biri 1 man 50 qəp olan 6 şirənin qiyməti neçədir?','1 man 50 qəp · 6 = 9 manat.',array['9 manat','6 man 50 qəp','7 man 50 qəp','9 man 50 qəp'],1),
('riy4-pullar#10','riy-4-pullar',3,3,'7 man 05 qəp − 2 man 30 qəp fərqini tapın.','05 qəpikdən 30 çıxmaq üçün 1 manat xırdalanır: 4 man 75 qəp.',array['4 man 75 qəp','5 man 25 qəp','4 man 35 qəp','5 man 75 qəp'],1),
('riy4-olcme#1','riy-4-olcme',1,4,'3 km neçə metrdir?','1 km = 1 000 m; 3 km = 3 000 m.',array['3 000 m','300 m','30 m','30 000 m'],1),
('riy4-olcme#2','riy-4-olcme',2,4,'250 sm neçə metr, neçə santimetrdir?','250 sm = 200 sm + 50 sm = 2 m 50 sm.',array['2 m 50 sm','25 m','2 m 5 sm','20 m 50 sm'],1),
('riy4-olcme#3','riy-4-olcme',2,4,'4 500 qram neçə kiloqramdır?','1 000 q = 1 kq; 4 500 q = 4 kq 500 q.',array['4 kq 500 q','45 kq','4 kq 50 q','450 kq'],1),
('riy4-olcme#4','riy-4-olcme',2,4,'2 saat 30 dəqiqə neçə dəqiqədir?','2 · 60 + 30 = 150 dəqiqə.',array['150 dəq','230 dəq','120 dəq','90 dəq'],1),
('riy4-olcme#5','riy-4-olcme',1,4,'1 ton neçə kiloqramdır?','1 t = 1 000 kq.',array['1 000 kq','100 kq','10 000 kq','500 kq'],1),
('riy4-olcme#6','riy-4-olcme',3,4,'7 m 8 sm neçə santimetrdir?','7 m = 700 sm; 700 + 8 = 708 sm.',array['708 sm','78 sm','780 sm','7 008 sm'],1),
('riy4-olcme#7','riy-4-olcme',3,4,'3 600 saniyə neçə saatdır?','1 saat = 3 600 saniyə.',array['1 saat','6 saat','36 saat','2 saat'],1),
('riy4-olcme#8','riy-4-olcme',3,4,'5 kq − 750 q fərqini tapın.','5 000 q − 750 q = 4 250 q = 4 kq 250 q.',array['4 kq 250 q','4 kq 750 q','3 kq 250 q','4 kq 350 q'],1),
('riy4-olcme#9','riy-4-olcme',3,4,'1 həftə neçə saatdır?','7 · 24 = 168 saat.',array['168 saat','24 saat','148 saat','170 saat'],1),
('riy4-olcme#10','riy-4-olcme',1,4,'40 mm neçə santimetrdir?','10 mm = 1 sm; 40 mm = 4 sm.',array['4 sm','400 sm','40 sm','0,4 sm'],1),
('riy4-melumat#1','riy-4-melumat',1,4,'Balların siyahısı: Aysu — 85, Kənan — 92, Ləman — 78. Ən yüksək bal kimindir?','92 > 85 > 78.',array['Kənan','Aysu','Ləman','Hamısınınkı bərabərdir'],1),
('riy4-melumat#2','riy-4-melumat',2,4,'Ardıcıllığın qaydasını tapıb davam etdirin: 5, 10, 20, 40, …','Hər ədəd əvvəlkinin 2 mislidir: 40 · 2 = 80.',array['80','50','60','100'],1),
('riy4-melumat#3','riy-4-melumat',1,4,'Sinifdə 12 oğlan və 14 qız var. Cədvəldə cəmi neçə şagird qeyd olunmalıdır?','12 + 14 = 26.',array['26','24','28','2'],1),
('riy4-melumat#4','riy-4-melumat',2,4,'Mağazada satış: I gün — 120, II gün — 150, III gün — 90 kitab. Üç gündə cəmi neçə kitab satılıb?','120 + 150 + 90 = 360.',array['360','350','270','460'],1),
('riy4-melumat#5','riy-4-melumat',1,4,'Satış: I gün — 120, II gün — 150, III gün — 90 kitab. Ən çox satış hansı gündə olub?','150 üç ədədin ən böyüyüdür.',array['II gün','I gün','III gün','Hamısında eyni'],1),
('riy4-melumat#6','riy-4-melumat',3,4,'Dörd ədədin cəmi 200-dür. Onların ədədi ortası neçədir?','Ədədi orta = cəm : say = 200 : 4 = 50.',array['50','40','100','800'],1),
('riy4-melumat#7','riy-4-melumat',3,4,'Qaydanı tapın: 2, 5, 11, 23, … Növbəti ədəd hansıdır?','Hər ədəd əvvəlkinin 2 mislindən 1 çoxdur: 23 · 2 + 1 = 47.',array['47','46','35','29'],1),
('riy4-melumat#8','riy-4-melumat',2,4,'İdmançı həftədə 5 gün, hər gün 45 dəqiqə məşq edir. Həftəlik məşq vaxtı neçə dəqiqədir?','5 · 45 = 225 dəqiqə.',array['225','205','240','50'],1),
('riy4-melumat#9','riy-4-melumat',2,4,'Oyun zərində «7» düşməsi necə hadisədir?','Zərin üzlərində 1-dən 6-ya qədər ədədlər var — 7 düşə bilməz.',array['Mümkünsüz','Mütləq','Mümkün','Təsadüfi'],1),
('riy4-melumat#10','riy-4-melumat',2,4,'Siyahıdakı ən kiçik ədəd hansıdır: 3 407; 3 470; 3 047; 3 740?','Yüzlər mərtəbəsinə baxın: 0 < 4 < 7.',array['3 047','3 407','3 470','3 740'],1),
('riy4-mesele#1','riy-4-mesele',2,4,'Məktəb kitabxanasına 3 250 kitab gətirildi. 1 480-i şagirdlərə verildi. Neçə kitab qaldı?','3 250 − 1 480 = 1 770.',array['1 770','1 870','1 670','4 730'],1),
('riy4-mesele#2','riy-4-mesele',2,4,'Bir qutuda 24 karandaş var. 15 belə qutuda neçə karandaş var?','24 · 15 = 360.',array['360','340','390','39'],1),
('riy4-mesele#3','riy-4-mesele',2,4,'Avtobus 240 km yolu 4 saata getdi. Avtobusun sürətini tapın.','Sürət = yol : vaxt = 240 : 4 = 60 km/saat.',array['60 km/saat','56 km/saat','80 km/saat','960 km/saat'],1),
('riy4-mesele#4','riy-4-mesele',2,4,'Anara 5 manat verildi. O, 3 man 40 qəp xərclədi. Nə qədər pulu qaldı?','5 man − 3 man 40 qəp = 1 man 60 qəp.',array['1 man 60 qəp','2 man 60 qəp','1 man 40 qəp','2 man 40 qəp'],1),
('riy4-mesele#5','riy-4-mesele',2,4,'456 şagird 8 bərabər dəstəyə bölündü. Hər dəstədə neçə şagird var?','456 : 8 = 57.',array['57','47','56','64'],1),
('riy4-mesele#6','riy-4-mesele',2,4,'Bağda 125 alma ağacı var, armud ağacları isə ondan 3 dəfə çoxdur. Neçə armud ağacı var?','«3 dəfə çox» — vurma deməkdir: 125 · 3 = 375.',array['375','128','250','425'],1),
('riy4-mesele#7','riy-4-mesele',1,4,'Rəşad hər gün 250 m qaçır. Bir həftədə (7 gün) neçə metr qaçmış olur?','250 · 7 = 1 750 m.',array['1 750 m','1 450 m','1 700 m','257 m'],1),
('riy4-mesele#8','riy-4-mesele',3,4,'İki ədədin cəmi 900-dür. Biri o birindən 100 vahid çoxdur. Böyük ədədi tapın.','(900 + 100) : 2 = 500; kiçik ədəd 400-dür.',array['500','400','450','800'],1),
('riy4-mesele#9','riy-4-mesele',1,4,'20 m parçadan hər birinə 4 m gedən neçə pərdə tikmək olar?','20 : 4 = 5.',array['5','4','16','80'],1),
('riy4-mesele#10','riy-4-mesele',2,4,'240 səhifəlik kitabı Aysu gündə 30 səhifə oxuyur. Kitabı neçə günə bitirər?','240 : 30 = 8 gün.',array['8','7','6','12'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = 'riyaziyyat'
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

-- ---------------------------------------------------------------- yoxlama
do $$
declare n int; k int; bad text;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform' and ext_key like 'riy4-%';
  if n <> 120 then
    raise exception 'riy4 suallari: 120 gozlenilirdi, % tapildi', n;
  end if;

  select count(*) into k from public.questions q
   where q.ext_key like 'riy4-%'
     and (select count(*) from public.question_options o
           where o.question_id = q.id) <> 4;
  if k > 0 then
    raise exception '% sualda variant sayi 4 deyil', k;
  end if;

  select count(*) into k from public.questions q
   where q.ext_key like 'riy4-%'
     and (select count(*) from public.question_options o
           where o.question_id = q.id and o.is_correct) <> 1;
  if k > 0 then
    raise exception '% sualda duzgun cavab sayi 1 deyil', k;
  end if;

  select string_agg(distinct t.slug, ', ') into bad
    from public.questions q
    join public.topics t on t.id = q.topic_id
   where q.ext_key like 'riy4-%'
  having count(distinct t.slug) <> 12;
  if bad is not null then
    raise exception 'movzu sayi 12 deyil: %', bad;
  end if;

  raise notice 'Riyaziyyat 4 banki: % sual, 12 movzu.', n;
end $$;
