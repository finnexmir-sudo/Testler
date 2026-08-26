-- =====================================================================
--  16_bank_riy4.sql : RIYAZIYYAT 4 PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/riy4.py yaradir:
--      python3 tools/riy4.py
--  Skript her riyazi cavabi YENIDEN HESABLAYIB duzgun variantla
--  tutusdurur, sonra bu SQL-i cixarir.  Duzelis skriptde edilir.
--
--  12 movzu x 20 sual = 240.  Suallar orijinaldir - e-derslikden
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
('riy4-coxreqemli#11','riy-4-coxreqemli',1,1,'«Beş yüz altı min doxsan dörd» ədədinin rəqəmlə yazılışı hansıdır?','506 094: 506 minlik və 94 təklik.',array['506 094','560 094','506 904','50 694'],1),
('riy4-coxreqemli#12','riy-4-coxreqemli',1,1,'418 275 ədədində onluqlar mərtəbəsində hansı rəqəm durur?','Sağdan ikinci rəqəm onluqları göstərir: 7.',array['7','2','5','8'],1),
('riy4-coxreqemli#13','riy-4-coxreqemli',2,1,'63 849 ədədini on minliklərə qədər yuvarlaqlaşdırın.','Minliklər rəqəmi 3 < 5 olduğundan aşağı yuvarlaqlaşır: 60 000.',array['60 000','70 000','63 000','64 000'],1),
('riy4-coxreqemli#14','riy-4-coxreqemli',2,1,'Tərkibində 4 yüzminlik, 7 minlik, 2 yüzlük və 5 təklik olan ədəd hansıdır?','400 000 + 7 000 + 200 + 5 = 407 205.',array['407 205','47 205','470 250','407 250'],1),
('riy4-coxreqemli#15','riy-4-coxreqemli',1,1,'899 999 ədədindən bilavasitə əvvəl gələn ədəd hansıdır?','Bir vahid az: 899 998.',array['899 998','900 000','899 990','898 999'],1),
('riy4-coxreqemli#16','riy-4-coxreqemli',1,1,'Ən böyük altırəqəmli ədəd hansıdır?','Altı dənə 9 rəqəmi: 999 999.',array['999 999','100 000','900 000','999 990'],1),
('riy4-coxreqemli#17','riy-4-coxreqemli',2,1,'5, 3, 9, 1 rəqəmlərinin hər birini bir dəfə işlətməklə yazıla bilən ən böyük dördrəqəmli ədəd hansıdır?','Rəqəmlər azalan sıra ilə düzülür: 9 531.',array['9 531','9 513','9 351','5 931'],1),
('riy4-coxreqemli#18','riy-4-coxreqemli',2,1,'Hansı ədəddə yüzlüklər mərtəbəsində 0 durur?','35 067 ədədində yüzlüklər mərtəbəsində 0-dır.',array['35 067','35 670','36 507','30 567'],1),
('riy4-coxreqemli#19','riy-4-coxreqemli',2,1,'72 486 ədədi ilə 72 000 ədədinin fərqi neçədir?','72 486 − 72 000 = 486.',array['486','846','400','586'],1),
('riy4-coxreqemli#20','riy-4-coxreqemli',2,1,'Hansı sırada ədədlər böyükdən kiçiyə düzülüb?','8 810 > 8 180 > 8 108.',array['8 810, 8 180, 8 108','8 108, 8 180, 8 810','8 180, 8 810, 8 108','8 108, 8 810, 8 180'],1),
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
('riy4-toplama-cixma#11','riy-4-toplama-cixma',1,1,'36 478 + 21 522 cəmini tapın.','36 478 + 21 522 = 58 000.',array['58 000','57 000','58 900','57 990'],1),
('riy4-toplama-cixma#12','riy-4-toplama-cixma',2,1,'90 000 − 45 678 fərqini hesablayın.','90 000 − 45 678 = 44 322.',array['44 322','45 322','44 432','54 322'],1),
('riy4-toplama-cixma#13','riy-4-toplama-cixma',2,1,'Çıxan 18 750, fərq 11 250-dirsə, çıxılan neçədir?','Çıxılan = çıxan + fərq = 18 750 + 11 250 = 30 000.',array['30 000','7 500','29 000','31 000'],1),
('riy4-toplama-cixma#14','riy-4-toplama-cixma',2,1,'204 060 + 95 940 cəmini hesablayın.','204 060 + 95 940 = 300 000.',array['300 000','290 000','300 900','299 000'],1),
('riy4-toplama-cixma#15','riy-4-toplama-cixma',2,1,'Cəm 100 000-dir. Toplananlardan biri 64 380 olarsa, o biri neçədir?','100 000 − 64 380 = 35 620.',array['35 620','36 620','35 720','45 620'],1),
('riy4-toplama-cixma#16','riy-4-toplama-cixma',2,1,'57 803 − 29 456 fərqini tapın.','57 803 − 29 456 = 28 347.',array['28 347','28 447','27 347','29 347'],1),
('riy4-toplama-cixma#17','riy-4-toplama-cixma',3,1,'Aysel fikrində tutduğu ədədin üzərinə 25 750 gəldi və 60 000 aldı. Fikrində tutduğu ədəd neçədir?','60 000 − 25 750 = 34 250.',array['34 250','35 250','34 350','85 750'],1),
('riy4-toplama-cixma#18','riy-4-toplama-cixma',3,1,'12 345 + 23 456 + 34 567 cəmini tapın.','12 345 + 23 456 + 34 567 = 70 368.',array['70 368','70 468','69 368','70 358'],1),
('riy4-toplama-cixma#19','riy-4-toplama-cixma',2,1,'Hansı ifadənin qiyməti 50 000-ə bərabərdir?','26 500 + 23 500 = 50 000.',array['26 500 + 23 500','25 000 + 24 000','51 000 − 2 000','48 000 + 1 000'],1),
('riy4-toplama-cixma#20','riy-4-toplama-cixma',2,1,'400 000 − 275 300 neçə edər?','400 000 − 275 300 = 124 700.',array['124 700','125 700','124 300','134 700'],1),
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
('riy4-vurma-bolme#11','riy-4-vurma-bolme',2,1,'4 507 × 6 hasilini hesablayın.','4 507 × 6 = 27 042.',array['27 042','27 402','26 042','24 042'],1),
('riy4-vurma-bolme#12','riy-4-vurma-bolme',2,1,'8 316 : 4 qismətini tapın.','8 316 : 4 = 2 079.',array['2 079','2 179','2 079,5','2 019'],1),
('riy4-vurma-bolme#13','riy-4-vurma-bolme',2,1,'1 089 × 9 neçə edər?','1 089 × 9 = 9 801.',array['9 801','9 810','9 701','9 891'],1),
('riy4-vurma-bolme#14','riy-4-vurma-bolme',3,1,'25 480 : 7 qismətini hesablayın.','25 480 : 7 = 3 640.',array['3 640','3 540','3 740','3 604'],1),
('riy4-vurma-bolme#15','riy-4-vurma-bolme',2,1,'Bölünən 3 216, bölən 8 olarsa, qismət neçədir?','3 216 : 8 = 402.',array['402','42','412','302'],1),
('riy4-vurma-bolme#16','riy-4-vurma-bolme',3,1,'Hansı ədədi 5-ə vursaq 12 400 alarıq?','12 400 : 5 = 2 480.',array['2 480','2 840','62 000','2 400'],1),
('riy4-vurma-bolme#17','riy-4-vurma-bolme',2,1,'56 : 8 + 72 : 9 ifadəsinin qiyməti neçədir?','7 + 8 = 15.',array['15','16','14','13'],1),
('riy4-vurma-bolme#18','riy-4-vurma-bolme',2,1,'Bir gündə 1 250 ədəd dəftər istehsal olunur. 6 gündə neçə dəftər istehsal olunar?','1 250 × 6 = 7 500.',array['7 500','7 200','6 500','7 550'],1),
('riy4-vurma-bolme#19','riy-4-vurma-bolme',2,1,'9 000 : 9 − 1 000 neçə edər?','1 000 − 1 000 = 0.',array['0','1 000','100','10'],1),
('riy4-vurma-bolme#20','riy-4-vurma-bolme',2,1,'50 : 7 əməlində qalıq neçədir?','7 × 7 = 49, qalıq 50 − 49 = 1.',array['1','7','0','3'],1),
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
('riy4-ifade-tenlik#11','riy-4-ifade-tenlik',2,2,'Tənliyi həll edin: x − 145 = 355.','x = 355 + 145 = 500.',array['500','210','490','510'],1),
('riy4-ifade-tenlik#12','riy-4-ifade-tenlik',2,2,'48 : (14 − 8) ifadəsinin qiyməti neçədir?','Əvvəl mötərizə: 14 − 8 = 6, sonra 48 : 6 = 8.',array['8','6','12','4'],1),
('riy4-ifade-tenlik#13','riy-4-ifade-tenlik',3,2,'Tənliyin kökünü tapın: x : 9 = 108.','x = 108 × 9 = 972.',array['972','12','962','982'],1),
('riy4-ifade-tenlik#14','riy-4-ifade-tenlik',2,2,'7 · 8 − 36 : 6 ifadəsini hesablayın.','56 − 6 = 50.',array['50','62','48','46'],1),
('riy4-ifade-tenlik#15','riy-4-ifade-tenlik',2,2,'Tənliyi həll edin: 540 : x = 6.','x = 540 : 6 = 90.',array['90','80','9','540'],1),
('riy4-ifade-tenlik#16','riy-4-ifade-tenlik',3,2,'a = 12 olduqda 100 − 5 · a ifadəsinin qiyməti neçədir?','100 − 60 = 40.',array['40','60','1 140','35'],1),
('riy4-ifade-tenlik#17','riy-4-ifade-tenlik',2,2,'Hansı ədəd x + x = 86 tənliyinin köküdür?','İki bərabər toplananın cəmi 86-dırsa, hər biri 43-dür.',array['43','86','42','44'],1),
('riy4-ifade-tenlik#18','riy-4-ifade-tenlik',2,2,'(25 + 35) · 3 ifadəsinin qiymətini tapın.','60 · 3 = 180.',array['180','130','160','190'],1),
('riy4-ifade-tenlik#19','riy-4-ifade-tenlik',3,2,'Tənliyi həll edin: 4 · x + 20 = 100.','4 · x = 80, x = 20.',array['20','25','30','80'],1),
('riy4-ifade-tenlik#20','riy-4-ifade-tenlik',1,2,'90 − (26 + 34) neçə edər?','90 − 60 = 30.',array['30','50','98','60'],1),
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
('riy4-vurma-bolme-2#11','riy-4-vurma-bolme-2',2,2,'58 × 30 hasilini tapın.','58 × 3 = 174, deməli 58 × 30 = 1 740.',array['1 740','1 640','1 840','174'],1),
('riy4-vurma-bolme-2#12','riy-4-vurma-bolme-2',2,2,'4 800 : 16 qismətini hesablayın.','4 800 : 16 = 300.',array['300','30','320','280'],1),
('riy4-vurma-bolme-2#13','riy-4-vurma-bolme-2',2,2,'125 × 8 neçə edər?','125 × 8 = 1 000.',array['1 000','1 250','900','1 125'],1),
('riy4-vurma-bolme-2#14','riy-4-vurma-bolme-2',2,2,'91 × 11 hasilini hesablayın.','91 × 11 = 1 001.',array['1 001','1 010','991','1 011'],1),
('riy4-vurma-bolme-2#15','riy-4-vurma-bolme-2',2,2,'7 200 : 90 neçə edər?','720 : 9 = 80, deməli 7 200 : 90 = 80.',array['80','800','90','70'],1),
('riy4-vurma-bolme-2#16','riy-4-vurma-bolme-2',3,2,'34 × 27 hasilini tapın.','34 × 27 = 918.',array['918','928','908','816'],1),
('riy4-vurma-bolme-2#17','riy-4-vurma-bolme-2',2,2,'8 400 : 70 qismətini tapın.','840 : 7 = 120, deməli 8 400 : 70 = 120.',array['120','12','140','110'],1),
('riy4-vurma-bolme-2#18','riy-4-vurma-bolme-2',2,2,'19 × 500 hasilini tapın.','19 × 5 = 95, deməli 19 × 500 = 9 500.',array['9 500','9 050','950','10 500'],1),
('riy4-vurma-bolme-2#19','riy-4-vurma-bolme-2',2,2,'Hasili tapın: 45 × 22.','45 × 22 = 990.',array['990','900','980','1 090'],1),
('riy4-vurma-bolme-2#20','riy-4-vurma-bolme-2',3,2,'3 000 : 150 neçə edər?','300 : 15 = 20, deməli 3 000 : 150 = 20.',array['20','200','15','25'],1),
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
('riy4-fiqurlar#11','riy-4-fiqurlar',2,2,'Tərəfi 11 sm olan kvadratın sahəsini tapın.','11 × 11 = 121 sm².',array['121 sm²','44 sm²','111 sm²','22 sm²'],1),
('riy4-fiqurlar#12','riy-4-fiqurlar',2,2,'Uzunluğu 9 sm, eni 6 sm olan düzbucaqlının perimetri neçədir?','(9 + 6) × 2 = 30 sm.',array['30 sm','54 sm','15 sm','36 sm'],1),
('riy4-fiqurlar#13','riy-4-fiqurlar',3,2,'Perimetri 48 sm olan kvadratın sahəsi neçədir?','Tərəf 48 : 4 = 12 sm, sahə 12 × 12 = 144 sm².',array['144 sm²','48 sm²','124 sm²','96 sm²'],1),
('riy4-fiqurlar#14','riy-4-fiqurlar',2,2,'Kor bucaq hansı bucaqdır?','Kor bucaq 90°-dən böyük, 180°-dən kiçikdir.',array['90°-dən böyük, 180°-dən kiçik','90°-dən kiçik','Düz 90°','180°-yə bərabər'],1),
('riy4-fiqurlar#15','riy-4-fiqurlar',3,2,'Düzbucaqlının perimetri 26 sm, uzunluğu 8 sm-dir. Eni neçədir?','Yarımperimetr 13 sm, en 13 − 8 = 5 sm.',array['5 sm','18 sm','6 sm','4 sm'],1),
('riy4-fiqurlar#16','riy-4-fiqurlar',2,2,'Kubun neçə tili var?','Kubun 12 tili var.',array['12','6','8','10'],1),
('riy4-fiqurlar#17','riy-4-fiqurlar',2,2,'Bir tərəfi 14 sm olan bərabərtərəfli üçbucağın perimetri neçədir?','14 × 3 = 42 sm.',array['42 sm','28 sm','44 sm','56 sm'],1),
('riy4-fiqurlar#18','riy-4-fiqurlar',2,2,'Sahəsi 72 sm², eni 6 sm olan düzbucaqlının uzunluğu neçədir?','72 : 6 = 12 sm.',array['12 sm','66 sm','13 sm','11 sm'],1),
('riy4-fiqurlar#19','riy-4-fiqurlar',1,2,'İti bucaq neçə dərəcədən kiçik olan bucaqdır?','İti bucaq 90°-dən kiçikdir.',array['90°','180°','45°','60°'],1),
('riy4-fiqurlar#20','riy-4-fiqurlar',1,2,'Hansı fiqurun bütün tərəfləri həmişə bərabərdir?','Kvadratın dörd tərəfi də bərabərdir.',array['Kvadrat','Düzbucaqlı','Üçbucaq','Paraleloqram'],1),
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
('riy4-kesr#11','riy-4-kesr',2,3,'72-nin 1/8 hissəsi neçədir?','72 : 8 = 9.',array['9','8','64','12'],1),
('riy4-kesr#12','riy-4-kesr',2,3,'Hansı ədədin 1/4 hissəsi 15-ə bərabərdir?','15 × 4 = 60.',array['60','45','50','30'],1),
('riy4-kesr#13','riy-4-kesr',3,3,'56-nın 3/8 hissəsini tapın.','56 : 8 = 7, 7 × 3 = 21.',array['21','24','18','28'],1),
('riy4-kesr#14','riy-4-kesr',2,3,'2/9 və 7/9 kəsrlərinin cəmi nəyə bərabərdir?','2/9 + 7/9 = 9/9 = 1 tam.',array['1 tam','9/18','5/9','14/9'],1),
('riy4-kesr#15','riy-4-kesr',1,3,'Məxrəcləri eyni olan kəsrlərdən ən kiçiyi hansıdır: 3/10, 7/10, 9/10?','Məxrəc eynidirsə, surəti kiçik olan kəsr kiçikdir.',array['3/10','7/10','9/10','Hamısı bərabərdir'],1),
('riy4-kesr#16','riy-4-kesr',2,3,'1 saatın 1/4 hissəsi neçə dəqiqədir?','60 : 4 = 15 dəqiqə.',array['15 dəqiqə','20 dəqiqə','25 dəqiqə','4 dəqiqə'],1),
('riy4-kesr#17','riy-4-kesr',3,3,'Şagird 40 səhifəlik kitabın 3/5 hissəsini oxudu. Neçə səhifə oxudu?','40 : 5 = 8, 8 × 3 = 24.',array['24','8','16','35'],1),
('riy4-kesr#18','riy-4-kesr',1,3,'Hansı kəsr 1-ə bərabərdir?','Surətlə məxrəc bərabərdirsə, kəsr 1-ə bərabərdir: 6/6.',array['6/6','1/6','6/12','6/1'],1),
('riy4-kesr#19','riy-4-kesr',2,3,'1/2 kəsri hansı kəsrlə eyni qiymətlidir?','2/4 kəsri də tamın yarısını göstərir.',array['2/4','1/4','2/3','3/4'],1),
('riy4-kesr#20','riy-4-kesr',2,3,'Tortun 8 bərabər hissəsindən 3-ü yeyildi. Tortun hansı hissəsi qaldı?','8 − 3 = 5 hissə, yəni 5/8.',array['5/8','3/8','5/3','8/5'],1),
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
('riy4-onluq-kesr#11','riy-4-onluq-kesr',2,3,'6,4 + 1,9 cəmini hesablayın.','6,4 + 1,9 = 8,3.',array['8,3','8,13','7,3','8,5'],1),
('riy4-onluq-kesr#12','riy-4-onluq-kesr',2,3,'10 − 3,6 fərqini tapın.','10 − 3,6 = 6,4.',array['6,4','7,4','6,6','7,6'],1),
('riy4-onluq-kesr#13','riy-4-onluq-kesr',2,3,'0,3 × 100 neçə edər?','Vergül iki mərtəbə sağa keçir: 30.',array['30','3','300','0,300'],1),
('riy4-onluq-kesr#14','riy-4-onluq-kesr',2,3,'45 : 100 neçə edər?','Vergül iki mərtəbə sola keçir: 0,45.',array['0,45','4,5','0,045','45,00'],1),
('riy4-onluq-kesr#15','riy-4-onluq-kesr',2,3,'5,06 və 5,6 ədədlərindən hansı böyükdür?','5,60 > 5,06.',array['5,6','5,06','Bərabərdirlər','Müqayisə olunmur'],1),
('riy4-onluq-kesr#16','riy-4-onluq-kesr',2,3,'«12 tam yüzdə 7» onluq kəsrlə necə yazılır?','Yüzdə yeddi iki onluq rəqəmlə yazılır: 12,07.',array['12,07','12,7','12,007','127'],1),
('riy4-onluq-kesr#17','riy-4-onluq-kesr',2,3,'3,25 + 1,75 cəmini tapın.','3,25 + 1,75 = 5.',array['5','4,9','5,1','4,95'],1),
('riy4-onluq-kesr#18','riy-4-onluq-kesr',2,3,'9,1 − 2,8 fərqini hesablayın.','9,1 − 2,8 = 6,3.',array['6,3','6,7','7,3','6,13'],1),
('riy4-onluq-kesr#19','riy-4-onluq-kesr',2,3,'0,5 hansı adi kəsrə bərabərdir?','0,5 = 5/10 = 1/2.',array['1/2','1/5','5/1','1/50'],1),
('riy4-onluq-kesr#20','riy-4-onluq-kesr',2,3,'Onluq kəsrlərin hansı düzülüşü kiçikdən böyüyə doğrudur?','0,8 < 1,2 < 1,5.',array['0,8; 1,2; 1,5','1,5; 1,2; 0,8','1,2; 0,8; 1,5','0,8; 1,5; 1,2'],1),
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
('riy4-pullar#11','riy-4-pullar',2,3,'4 man 60 qəp + 3 man 55 qəp neçə edər?','460 qəp + 355 qəp = 815 qəp = 8 man 15 qəp.',array['8 man 15 qəp','7 man 15 qəp','8 man 05 qəp','7 man 95 qəp'],1),
('riy4-pullar#12','riy-4-pullar',2,3,'20 manatla 13 man 45 qəp ödənildi. Qalıq nə qədərdir?','20 man − 13 man 45 qəp = 6 man 55 qəp.',array['6 man 55 qəp','7 man 55 qəp','6 man 45 qəp','7 man 45 qəp'],1),
('riy4-pullar#13','riy-4-pullar',2,3,'Hər biri 85 qəpik olan 4 qələmin qiyməti nə qədərdir?','85 × 4 = 340 qəpik = 3 man 40 qəp.',array['3 man 40 qəp','3 man 20 qəp','2 man 40 qəp','4 man 25 qəp'],1),
('riy4-pullar#14','riy-4-pullar',1,3,'1 man 25 qəp neçə qəpikdir?','1 manat = 100 qəpik, üstəgəl 25: 125 qəpik.',array['125 qəpik','1 025 qəpik','12 qəpik','250 qəpik'],1),
('riy4-pullar#15','riy-4-pullar',3,3,'Dəftər 95 qəpik, kitab isə ondan 2 man 05 qəp bahadır. Kitabın qiyməti nə qədərdir?','95 qəp + 2 man 05 qəp = 3 manat.',array['3 manat','2 manat','2 man 90 qəp','3 man 10 qəp'],1),
('riy4-pullar#16','riy-4-pullar',2,3,'Üç bacı 12 manatı bərabər böldü. Hər birinə nə qədər düşdü?','12 : 3 = 4 manat.',array['4 manat','3 manat','6 manat','4 man 50 qəp'],1),
('riy4-pullar#17','riy-4-pullar',2,3,'20 qəpiklik sikkələrlə 3 manat yığmaq üçün neçə sikkə lazımdır?','300 : 20 = 15 sikkə.',array['15','10','20','30'],1),
('riy4-pullar#18','riy-4-pullar',2,3,'Hər ay 2 man 50 qəp yığan şagird 4 aya nə qədər yığar?','250 × 4 = 1 000 qəpik = 10 manat.',array['10 manat','8 manat','9 manat','10 man 50 qəp'],1),
('riy4-pullar#19','riy-4-pullar',3,3,'6 man 30 qəp − 4 man 80 qəp fərqini tapın.','630 − 480 = 150 qəpik = 1 man 50 qəp.',array['1 man 50 qəp','2 man 50 qəp','1 man 40 qəp','2 man 10 qəp'],1),
('riy4-pullar#20','riy-4-pullar',2,3,'Hər biri 2 man 20 qəp olan 3 şirniyyatın qiyməti nə qədərdir?','220 × 3 = 660 qəpik = 6 man 60 qəp.',array['6 man 60 qəp','6 man 20 qəp','5 man 60 qəp','6 man 66 qəp'],1),
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
('riy4-olcme#11','riy-4-olcme',2,4,'6 km 250 m neçə metrdir?','6 000 + 250 = 6 250 m.',array['6 250 m','6 025 m','625 m','62 500 m'],1),
('riy4-olcme#12','riy-4-olcme',1,4,'2 gün neçə saatdır?','24 × 2 = 48 saat.',array['48 saat','24 saat','36 saat','72 saat'],1),
('riy4-olcme#13','riy-4-olcme',2,4,'5 400 kq neçə ton, neçə kiloqramdır?','5 400 kq = 5 t 400 kq.',array['5 t 400 kq','54 t','5 t 40 kq','4 t 500 kq'],1),
('riy4-olcme#14','riy-4-olcme',2,4,'90 dəqiqə neçə saat, neçə dəqiqədir?','90 dəq = 1 saat 30 dəq.',array['1 saat 30 dəq','1 saat 20 dəq','2 saat','1 saat 40 dəq'],1),
('riy4-olcme#15','riy-4-olcme',2,4,'12 m neçə millimetrdir?','1 m = 1 000 mm, 12 m = 12 000 mm.',array['12 000 mm','1 200 mm','120 mm','120 000 mm'],1),
('riy4-olcme#16','riy-4-olcme',1,4,'Yarım kiloqram neçə qramdır?','1 kq = 1 000 q, yarısı 500 q.',array['500 q','50 q','250 q','5 000 q'],1),
('riy4-olcme#17','riy-4-olcme',1,4,'1 əsr neçə ildir?','1 əsr 100 ilə bərabərdir.',array['100 il','10 il','50 il','1 000 il'],1),
('riy4-olcme#18','riy-4-olcme',2,4,'8 l 500 ml neçə millilitrdir?','8 000 + 500 = 8 500 ml.',array['8 500 ml','8 050 ml','850 ml','85 000 ml'],1),
('riy4-olcme#19','riy-4-olcme',2,4,'3 kq 75 q neçə qramdır?','3 000 + 75 = 3 075 q.',array['3 075 q','3 750 q','375 q','3 705 q'],1),
('riy4-olcme#20','riy-4-olcme',3,4,'Saat 14:40-dan 25 dəqiqə sonra saat neçə olacaq?','14:40 + 20 dəq = 15:00, daha 5 dəq = 15:05.',array['15:05','14:65','15:15','16:05'],1),
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
('riy4-melumat#11','riy-4-melumat',1,4,'Cədvəl: Nərmin — 24, Tural — 31, Aygün — 28 kitab oxuyub. Ən az kitab oxuyan kimdir?','24 < 28 < 31 olduğundan ən az oxuyan Nərmindir.',array['Nərmin','Tural','Aygün','Hamısı bərabərdir'],1),
('riy4-melumat#12','riy-4-melumat',2,4,'Ardıcıllığı davam etdirin: 3, 6, 12, 24, …','Hər ədəd əvvəlkinin 2 mislidir: 24 × 2 = 48.',array['48','36','30','26'],1),
('riy4-melumat#13','riy-4-melumat',2,4,'Beş ədədin cəmi 350-dirsə, onların ədədi ortası neçədir?','350 : 5 = 70.',array['70','75','60','355'],1),
('riy4-melumat#14','riy-4-melumat',2,4,'Torbada yalnız qırmızı kürələr var. Çıxarılan kürənin qırmızı olması necə hadisədir?','Başqa rəng yoxdursa, hadisə hökmən baş verir - yəqin hadisədir.',array['Yəqin','Mümkünsüz','Təsadüfi','Qeyri-mümkün'],1),
('riy4-melumat#15','riy-4-melumat',1,4,'Qrafikdə temperatur: I gün 18°, II gün 22°, III gün 20°. Ən isti gün hansıdır?','22° ən böyük qiymətdir.',array['II gün','I gün','III gün','Hamısı eynidir'],1),
('riy4-melumat#16','riy-4-melumat',3,4,'Ardıcıllığın qaydası «+7»-dir, ilk ədəd 4-dür. Dördüncü ədəd neçədir?','4, 11, 18, 25.',array['25','28','18','32'],1),
('riy4-melumat#17','riy-4-melumat',2,4,'Sorğuda 45 şagirddən 18-i futbolu seçib. Neçə şagird başqa idman növü seçib?','45 − 18 = 27.',array['27','18','63','25'],1),
('riy4-melumat#18','riy-4-melumat',2,4,'Diaqramda satış: alma — 9, armud — 6, gilas — 13. Cəmi neçə meyvə satılıb?','9 + 6 + 13 = 28.',array['28','27','26','29'],1),
('riy4-melumat#19','riy-4-melumat',1,4,'İki oyun zəri atıldı: 5 və 6 düşdü. Xalların cəmi neçədir?','5 + 6 = 11.',array['11','12','1','56'],1),
('riy4-melumat#20','riy-4-melumat',3,4,'Cədvəldə 4 həftənin yağıntısı: 12, 8, 20, 16 mm. Ədədi orta neçə mm-dir?','(12 + 8 + 20 + 16) : 4 = 56 : 4 = 14 mm.',array['14 mm','16 mm','12 mm','56 mm'],1),
('riy4-mesele#1','riy-4-mesele',2,4,'Məktəb kitabxanasına 3 250 kitab gətirildi. 1 480-i şagirdlərə verildi. Neçə kitab qaldı?','3 250 − 1 480 = 1 770.',array['1 770','1 870','1 670','4 730'],1),
('riy4-mesele#2','riy-4-mesele',2,4,'Bir qutuda 24 karandaş var. 15 belə qutuda neçə karandaş var?','24 · 15 = 360.',array['360','340','390','39'],1),
('riy4-mesele#3','riy-4-mesele',2,4,'Avtobus 240 km yolu 4 saata getdi. Avtobusun sürətini tapın.','Sürət = yol : vaxt = 240 : 4 = 60 km/saat.',array['60 km/saat','56 km/saat','80 km/saat','960 km/saat'],1),
('riy4-mesele#4','riy-4-mesele',2,4,'Anara 5 manat verildi. O, 3 man 40 qəp xərclədi. Nə qədər pulu qaldı?','5 man − 3 man 40 qəp = 1 man 60 qəp.',array['1 man 60 qəp','2 man 60 qəp','1 man 40 qəp','2 man 40 qəp'],1),
('riy4-mesele#5','riy-4-mesele',2,4,'456 şagird 8 bərabər dəstəyə bölündü. Hər dəstədə neçə şagird var?','456 : 8 = 57.',array['57','47','56','64'],1),
('riy4-mesele#6','riy-4-mesele',2,4,'Bağda 125 alma ağacı var, armud ağacları isə ondan 3 dəfə çoxdur. Neçə armud ağacı var?','«3 dəfə çox» — vurma deməkdir: 125 · 3 = 375.',array['375','128','250','425'],1),
('riy4-mesele#7','riy-4-mesele',1,4,'Rəşad hər gün 250 m qaçır. Bir həftədə (7 gün) neçə metr qaçmış olur?','250 · 7 = 1 750 m.',array['1 750 m','1 450 m','1 700 m','257 m'],1),
('riy4-mesele#8','riy-4-mesele',3,4,'İki ədədin cəmi 900-dür. Biri o birindən 100 vahid çoxdur. Böyük ədədi tapın.','(900 + 100) : 2 = 500; kiçik ədəd 400-dür.',array['500','400','450','800'],1),
('riy4-mesele#9','riy-4-mesele',1,4,'20 m parçadan hər birinə 4 m gedən neçə pərdə tikmək olar?','20 : 4 = 5.',array['5','4','16','80'],1),
('riy4-mesele#10','riy-4-mesele',2,4,'240 səhifəlik kitabı Aysu gündə 30 səhifə oxuyur. Kitabı neçə günə bitirər?','240 : 30 = 8 gün.',array['8','7','6','12'],1),
('riy4-mesele#11','riy-4-mesele',2,4,'Bir traktor gündə 15 hektar sahə şumlayır. 12 gündə neçə hektar şumlayar?','15 × 12 = 180 hektar.',array['180','150','27','170'],1),
('riy4-mesele#12','riy-4-mesele',2,4,'Qatar saatda 85 km sürətlə 6 saat yol getdi. Neçə kilometr yol qət etdi?','85 × 6 = 510 km.',array['510 km','500 km','480 km','91 km'],1),
('riy4-mesele#13','riy-4-mesele',2,4,'Fəhlə 8 saatda 104 detal hazırlayır. Bir saatda neçə detal hazırlayır?','104 : 8 = 13.',array['13','12','14','96'],1),
('riy4-mesele#14','riy-4-mesele',2,4,'Mağazaya 15 yeşik alma gətirildi, hər yeşikdə 18 kq alma var. Cəmi neçə kiloqram alma gətirilib?','15 × 18 = 270 kq.',array['270 kq','260 kq','280 kq','33 kq'],1),
('riy4-mesele#15','riy-4-mesele',2,4,'Maşın 540 km yolu 6 saata getdi. Maşının sürəti neçə km/saatdır?','540 : 6 = 90 km/saat.',array['90 km/saat','80 km/saat','95 km/saat','534 km/saat'],1),
('riy4-mesele#16','riy-4-mesele',3,4,'Anbarda 2 400 kq un var idi. Hər biri 50 kq olan 30 kisə un satıldı. Anbarda neçə kiloqram un qaldı?','Satılan: 50 × 30 = 1 500 kq. Qalan: 2 400 − 1 500 = 900 kq.',array['900 kq','1 500 kq','850 kq','950 kq'],1),
('riy4-mesele#17','riy-4-mesele',2,4,'Sinifdəki 28 şagirdin hər birinə 3 dəftər paylandı. Cəmi neçə dəftər paylandı?','28 × 3 = 84.',array['84','31','74','86'],1),
('riy4-mesele#18','riy-4-mesele',3,4,'İki ədədin cəmi 640, fərqi 40-dır. Kiçik ədədi tapın.','Kiçik ədəd: (640 − 40) : 2 = 300.',array['300','340','320','280'],1),
('riy4-mesele#19','riy-4-mesele',2,4,'Hovuza hər saat 250 litr su dolur. 8 saatda neçə litr su yığılar?','250 × 8 = 2 000 l.',array['2 000 l','1 800 l','2 500 l','258 l'],1),
('riy4-mesele#20','riy-4-mesele',3,4,'Usta 3 gündə 27 stul düzəldir. Eyni sürətlə 63 stulu neçə günə düzəldər?','Gündə 27 : 3 = 9 stul. 63 : 9 = 7 gün.',array['7 gün','9 gün','6 gün','8 gün'],1)
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
  if n <> 240 then
    raise exception 'riy4 suallari: 240 gozlenilirdi, % tapildi', n;
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
