-- =====================================================================
--  19_bank_riy3.sql : RIYAZIYYAT 3 PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/riy3.py yaradir:
--      python3 tools/riy3.py
--
--  12 movzu x 20 sual = 240.  ext_key: riy3-<movzu>#<sira>.
--  ON SERT: 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-3-vurma-bolme-2') then
    raise exception 'ONCE 15_movzular_ederslik.sql isledilmelidir (riy-3-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy3-%';

with d(ext, topic, diff, rub, body, why, opts, correct) as (values
('riy3-ededler-1000#1','riy-3-ededler-1000',1,1,'«Beş yüz altmış üç» ədədi rəqəmlə necə yazılır?','500 + 60 + 3 = 563.',array['563','536','653','530'],1),
('riy3-ededler-1000#2','riy-3-ededler-1000',2,1,'407 ədədində onluqlar mərtəbəsində hansı rəqəm durur?','407 = 4 yüzlük, 0 onluq, 7 təklik.',array['0','4','7','47'],1),
('riy3-ededler-1000#3','riy-3-ededler-1000',1,1,'289 ədədindən bilavasitə sonra gələn ədəd hansıdır?','289 + 1 = 290.',array['290','288','280','300'],1),
('riy3-ededler-1000#4','riy-3-ededler-1000',2,1,'3 yüzlük, 5 onluq və 2 təklikdən ibarət ədəd hansıdır?','300 + 50 + 2 = 352.',array['352','325','532','3502'],1),
('riy3-ededler-1000#5','riy-3-ededler-1000',2,1,'Ədədlər hansı sırada azalan ardıcıllıqla düzülüb?','981 > 918 > 891.',array['981, 918, 891','918, 981, 891','891, 918, 981','981, 891, 918'],1),
('riy3-ededler-1000#6','riy-3-ededler-1000',1,1,'545 və 554 ədədlərindən hansı böyükdür?','Onluqlar mərtəbəsinə baxın: 5 > 4, deməli 554 böyükdür.',array['554','545','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy3-ededler-1000#7','riy-3-ededler-1000',1,1,'Ən böyük üçrəqəmli ədəd hansıdır?','Üçrəqəmli ədədlərin ən böyüyü 999-dur.',array['999','998','900','1 000'],1),
('riy3-ededler-1000#8','riy-3-ededler-1000',2,1,'700 + 60 + 4 cəmi hansı ədədi verir?','Mərtəbə toplananlarının cəmi: 764.',array['764','746','7 604','674'],1),
('riy3-ededler-1000#9','riy-3-ededler-1000',3,1,'3 yüzlük neçə onluqdur?','1 yüzlük = 10 onluq; 3 yüzlük = 30 onluq.',array['30','3','300','13'],1),
('riy3-ededler-1000#10','riy-3-ededler-1000',2,1,'Hansı ədəd cütdür?','Sonu 0, 2, 4, 6, 8 ilə bitən ədədlər cütdür.',array['348','431','567','209'],1),
('riy3-ededler-1000#11','riy-3-ededler-1000',1,1,'«Səkkiz yüz on iki» ədədi rəqəmlə necə yazılır?','800 + 12 = 812.',array['812','821','802','8012'],1),
('riy3-ededler-1000#12','riy-3-ededler-1000',1,1,'925 ədədində yüzlüklər mərtəbəsində hansı rəqəm durur?','Soldan birinci rəqəm yüzlükləri göstərir: 9.',array['9','2','5','92'],1),
('riy3-ededler-1000#13','riy-3-ededler-1000',1,1,'499 ədədindən bilavasitə əvvəl gələn ədəd hansıdır?','Bir vahid az: 498.',array['498','500','489','400'],1),
('riy3-ededler-1000#14','riy-3-ededler-1000',2,1,'6 yüzlük, 0 onluq və 8 təklikdən ibarət ədəd hansıdır?','600 + 0 + 8 = 608.',array['608','680','068','806'],1),
('riy3-ededler-1000#15','riy-3-ededler-1000',2,1,'870 ədədində cəmi neçə onluq var?','870 : 10 = 87 onluq.',array['87','8','870','78'],1),
('riy3-ededler-1000#16','riy-3-ededler-1000',1,1,'236, 263, 326 ədədlərindən ən böyüyü hansıdır?','326 > 263 > 236.',array['326','263','236','Hamısı bərabərdir'],1),
('riy3-ededler-1000#17','riy-3-ededler-1000',1,1,'465, 348, 210, 136 ədədlərindən hansı təkdir?','Təklər mərtəbəsində 5 duran ədəd təkdir: 465.',array['465','348','210','136'],1),
('riy3-ededler-1000#18','riy-3-ededler-1000',1,1,'500 + 40 + 9 cəmi hansı ədədi verir?','500 + 40 + 9 = 549.',array['549','594','5409','459'],1),
('riy3-ededler-1000#19','riy-3-ededler-1000',1,1,'380 ədədi sözlə necə oxunur?','380 — üç yüz səksən.',array['Üç yüz səksən','Üç yüz on səkkiz','Otuz səksən','Üç min səksən'],1),
('riy3-ededler-1000#20','riy-3-ededler-1000',2,1,'999 ədədinin üzərinə 1 gəlsək hansı ədəd alınar?','999 + 1 = 1 000.',array['1 000','998','9 991','1 100'],1),
('riy3-toplama#1','riy-3-toplama',1,1,'245 + 132 cəmini tapın.','245 + 132 = 377.',array['377','367','387','477'],1),
('riy3-toplama#2','riy-3-toplama',2,1,'368 + 254 neçə edər?','368 + 254 = 622; keçidləri unutmayın.',array['622','612','522','632'],1),
('riy3-toplama#3','riy-3-toplama',2,1,'470 + 280 cəmini hesablayın.','470 + 280 = 750.',array['750','650','740','760'],1),
('riy3-toplama#4','riy-3-toplama',2,1,'İki ədədin cəmi 600-dür. Onlardan biri 280-dirsə, o biri neçədir?','600 − 280 = 320.',array['320','380','330','420'],1),
('riy3-toplama#5','riy-3-toplama',2,1,'156 + 244 neçə edər?','156 + 244 = 400.',array['400','390','410','300'],1),
('riy3-toplama#6','riy-3-toplama',2,1,'305 + 486 cəmini tapın.','305 + 486 = 791.',array['791','781','891','701'],1),
('riy3-toplama#7','riy-3-toplama',3,1,'623 + 189 neçə edər?','623 + 189 = 812.',array['812','802','712','822'],1),
('riy3-toplama#8','riy-3-toplama',1,1,'348 + 267 = 267 + ? Bərabərlik doğru olsun deyə sual işarəsinin yerinə hansı ədəd yazılmalıdır?','Toplananların yeri dəyişəndə cəm dəyişmir.',array['348','267','615','81'],1),
('riy3-toplama#9','riy-3-toplama',1,1,'138 + 162 cəmini hesablayın.','138 + 162 = 300.',array['300','290','310','200'],1),
('riy3-toplama#10','riy-3-toplama',3,1,'Cəmi 1 000 olan cütü seçin.','550 + 450 = 1 000.',array['550 və 450','540 və 450','550 və 550','600 və 500'],1),
('riy3-toplama#11','riy-3-toplama',1,1,'234 + 345 cəmini hesablayın.','234 + 345 = 579.',array['579','589','569','578'],1),
('riy3-toplama#12','riy-3-toplama',2,1,'417 + 263 neçə edər?','417 + 263 = 680.',array['680','670','690','681'],1),
('riy3-toplama#13','riy-3-toplama',2,1,'Cəm 500-dür. Toplananlardan biri 175-dirsə, o birini tapın.','500 − 175 = 325.',array['325','375','335','675'],1),
('riy3-toplama#14','riy-3-toplama',2,1,'146 + 154 + 200 cəmini tapın.','146 + 154 = 300, üstəgəl 200 = 500.',array['500','400','480','510'],1),
('riy3-toplama#15','riy-3-toplama',2,1,'289 + 131 neçə edər?','289 + 131 = 420.',array['420','410','430','418'],1),
('riy3-toplama#16','riy-3-toplama',2,1,'356 + 244 cəmini hesablayın.','356 + 244 = 600.',array['600','590','610','612'],1),
('riy3-toplama#17','riy-3-toplama',2,1,'72 + 189 cəmini tapın.','72 + 189 = 261.',array['261','251','271','262'],1),
('riy3-toplama#18','riy-3-toplama',2,1,'Hansı cütün cəmi 700-dür?','420 + 280 = 700.',array['420 və 280','350 və 250','400 və 200','500 və 150'],1),
('riy3-toplama#19','riy-3-toplama',1,1,'530 + 270 neçə edər?','530 + 270 = 800.',array['800','790','810','700'],1),
('riy3-toplama#20','riy-3-toplama',1,1,'Toplamada toplananların yerini dəyişdikdə cəm necə olur?','Yerdəyişmə xassəsi: cəm dəyişmir.',array['Dəyişmir','Böyüyür','Kiçilir','Sıfır olur'],1),
('riy3-cixma#1','riy-3-cixma',1,1,'568 − 234 fərqini tapın.','568 − 234 = 334.',array['334','324','344','234'],1),
('riy3-cixma#2','riy-3-cixma',2,1,'700 − 358 neçə edər?','Sıfırlardan borc alınır: 700 − 358 = 342.',array['342','352','442','332'],1),
('riy3-cixma#3','riy-3-cixma',3,1,'903 − 476 fərqini hesablayın.','903 − 476 = 427.',array['427','437','527','417'],1),
('riy3-cixma#4','riy-3-cixma',2,1,'Çıxılan 600, fərq 250-dirsə, çıxan neçədir?','Çıxan = çıxılan − fərq = 600 − 250 = 350.',array['350','850','250','450'],1),
('riy3-cixma#5','riy-3-cixma',1,1,'645 − 45 neçə edər?','645 − 45 = 600.',array['600','640','605','500'],1),
('riy3-cixma#6','riy-3-cixma',2,1,'812 − 407 fərqini tapın.','812 − 407 = 405.',array['405','415','305','495'],1),
('riy3-cixma#7','riy-3-cixma',2,1,'1 000 − 630 neçə edər?','1 000 − 630 = 370.',array['370','430','470','360'],1),
('riy3-cixma#8','riy-3-cixma',2,1,'500 − 213 = 287 əməlini toplama ilə necə yoxlamaq olar?','Fərq + çıxan = çıxılan olmalıdır.',array['287 + 213 = 500','287 − 213 = 74','500 + 213 = 713','500 + 287 = 787'],1),
('riy3-cixma#9','riy-3-cixma',3,1,'555 − 267 fərqini hesablayın.','555 − 267 = 288.',array['288','298','278','388'],1),
('riy3-cixma#10','riy-3-cixma',3,1,'Hansı ədəddən 140 çıxsaq, 260 alarıq?','260 + 140 = 400.',array['400','120','300','260'],1),
('riy3-cixma#11','riy-3-cixma',2,1,'864 − 329 fərqini tapın.','864 − 329 = 535.',array['535','545','525','534'],1),
('riy3-cixma#12','riy-3-cixma',2,1,'600 − 264 neçə edər?','600 − 264 = 336.',array['336','346','436','334'],1),
('riy3-cixma#13','riy-3-cixma',3,1,'Fərq 180, çıxan 320-dirsə, çıxılan neçədir?','Çıxılan = fərq + çıxan = 180 + 320 = 500.',array['500','140','480','520'],1),
('riy3-cixma#14','riy-3-cixma',2,1,'741 − 286 fərqini hesablayın.','741 − 286 = 455.',array['455','465','445','545'],1),
('riy3-cixma#15','riy-3-cixma',2,1,'940 − 550 neçə edər?','940 − 550 = 390.',array['390','490','380','410'],1),
('riy3-cixma#16','riy-3-cixma',3,1,'Hansı ədəddən 230 çıxsaq 470 alarıq?','230 + 470 = 700.',array['700','240','670','710'],1),
('riy3-cixma#17','riy-3-cixma',2,1,'802 − 396 fərqini tapın.','802 − 396 = 406.',array['406','416','396','506'],1),
('riy3-cixma#18','riy-3-cixma',1,1,'1 000 − 1 neçə edər?','1 000 − 1 = 999.',array['999','1 001','990','909'],1),
('riy3-cixma#19','riy-3-cixma',2,1,'678 − 218 neçə edər?','678 − 218 = 460.',array['460','450','470','440'],1),
('riy3-cixma#20','riy-3-cixma',1,1,'Sinifdə 32 şagird var idi, 7-si evə getdi. Neçə şagird qaldı?','32 − 7 = 25.',array['25','24','26','39'],1),
('riy3-vurma-bolme#1','riy-3-vurma-bolme',1,2,'7 × 4 neçə edər?','7 × 4 = 28.',array['28','24','32','21'],1),
('riy3-vurma-bolme#2','riy-3-vurma-bolme',2,2,'9 × 6 hasilini tapın.','9 × 6 = 54.',array['54','56','45','63'],1),
('riy3-vurma-bolme#3','riy-3-vurma-bolme',1,2,'8 × 8 neçə edər?','8 × 8 = 64.',array['64','72','56','68'],1),
('riy3-vurma-bolme#4','riy-3-vurma-bolme',2,2,'36 : 4 qismətini tapın.','36 : 4 = 9, çünki 4 × 9 = 36.',array['9','8','7','6'],1),
('riy3-vurma-bolme#5','riy-3-vurma-bolme',2,2,'42 : 6 neçə edər?','42 : 6 = 7.',array['7','6','8','9'],1),
('riy3-vurma-bolme#6','riy-3-vurma-bolme',2,2,'9 × 9 hasilini hesablayın.','9 × 9 = 81.',array['81','72','89','99'],1),
('riy3-vurma-bolme#7','riy-3-vurma-bolme',1,2,'0 × 25 neçə edər?','Sıfırla vurmanın hasili həmişə sıfırdır.',array['0','25','250','1'],1),
('riy3-vurma-bolme#8','riy-3-vurma-bolme',2,2,'48 : 6 qismətini tapın.','48 : 6 = 8.',array['8','7','9','6'],1),
('riy3-vurma-bolme#9','riy-3-vurma-bolme',2,2,'35 : 5 = 7 bölməsini vurma ilə necə yoxlamaq olar?','Qismət × bölən = bölünən olmalıdır.',array['5 × 7 = 35','35 × 5 = 175','7 + 5 = 12','35 − 5 = 30'],1),
('riy3-vurma-bolme#10','riy-3-vurma-bolme',3,2,'Hasili 24 olan cütü seçin.','4 × 6 = 24.',array['4 və 6','5 və 6','3 və 9','4 və 8'],1),
('riy3-vurma-bolme#11','riy-3-vurma-bolme',1,2,'Hasili hesablayın: 7 × 9.','7 × 9 = 63.',array['63','56','72','64'],1),
('riy3-vurma-bolme#12','riy-3-vurma-bolme',1,2,'45 : 9 qismətini tapın.','45 : 9 = 5.',array['5','4','9','6'],1),
('riy3-vurma-bolme#13','riy-3-vurma-bolme',1,2,'8 × 5 hasilini hesablayın.','8 × 5 = 40.',array['40','45','35','13'],1),
('riy3-vurma-bolme#14','riy-3-vurma-bolme',2,2,'66 : 6 neçə edər?','66 : 6 = 11.',array['11','10','12','16'],1),
('riy3-vurma-bolme#15','riy-3-vurma-bolme',1,2,'4 × 7 hasilini tapın.','4 × 7 = 28.',array['28','24','21','32'],1),
('riy3-vurma-bolme#16','riy-3-vurma-bolme',1,2,'1 × 58 neçə edər?','İstənilən ədədi 1-ə vurduqda ədədin özü alınır: 58.',array['58','1','59','0'],1),
('riy3-vurma-bolme#17','riy-3-vurma-bolme',2,2,'Bölünən 70, bölən 7 olarsa, qismət neçədir?','70 : 7 = 10.',array['10','7','63','77'],1),
('riy3-vurma-bolme#18','riy-3-vurma-bolme',2,2,'Hasil 35, vuruqlardan biri 5-dirsə, o biri neçədir?','35 : 5 = 7.',array['7','5','30','40'],1),
('riy3-vurma-bolme#19','riy-3-vurma-bolme',1,2,'43 : 43 neçə edər?','Ədədi özünə böldükdə 1 alınır.',array['1','0','43','4'],1),
('riy3-vurma-bolme#20','riy-3-vurma-bolme',1,2,'İstənilən ədədi 1-ə böldükdə nə alınır?','Ədədin özü alınır.',array['Ədədin özü','1','0','Ədədin yarısı'],1),
('riy3-ifade-tenlik#1','riy-3-ifade-tenlik',3,2,'20 + 30 : 5 ifadəsinin qiymətini tapın.','Əvvəl bölmə: 30 : 5 = 6; sonra 20 + 6 = 26.',array['26','10','50','56'],1),
('riy3-ifade-tenlik#2','riy-3-ifade-tenlik',1,2,'x + 60 = 140 tənliyində x-i tapın.','x = 140 − 60 = 80.',array['80','200','90','70'],1),
('riy3-ifade-tenlik#3','riy-3-ifade-tenlik',2,2,'x · 4 = 32 tənliyinin kökü neçədir?','x = 32 : 4 = 8.',array['8','28','36','128'],1),
('riy3-ifade-tenlik#4','riy-3-ifade-tenlik',2,2,'(45 − 15) : 2 ifadəsinin qiyməti neçədir?','Əvvəl mötərizə: 30, sonra 30 : 2 = 15.',array['15','6','30','12'],1),
('riy3-ifade-tenlik#5','riy-3-ifade-tenlik',2,2,'x : 3 = 20 tənliyində x neçədir?','x = 20 · 3 = 60.',array['60','23','17','50'],1),
('riy3-ifade-tenlik#6','riy-3-ifade-tenlik',1,2,'90 − x = 55 tənliyinin kökü neçədir?','x = 90 − 55 = 35.',array['35','145','45','25'],1),
('riy3-ifade-tenlik#7','riy-3-ifade-tenlik',2,2,'6 · 3 + 12 ifadəsini hesablayın.','6 · 3 = 18; 18 + 12 = 30.',array['30','90','21','36'],1),
('riy3-ifade-tenlik#8','riy-3-ifade-tenlik',2,2,'a = 7 olduqda a · 5 ifadəsinin qiyməti neçədir?','7 · 5 = 35.',array['35','12','57','75'],1),
('riy3-ifade-tenlik#9','riy-3-ifade-tenlik',2,2,'100 − (20 + 30) ifadəsinin qiymətini tapın.','Əvvəl mötərizə: 20 + 30 = 50; sonra 100 − 50 = 50.',array['50','110','80','70'],1),
('riy3-ifade-tenlik#10','riy-3-ifade-tenlik',3,2,'Hansı yazılış tənlikdir?','Tənlikdə naməlum (x) və bərabərlik işarəsi olur.',array['x + 5 = 12','7 + 5','12 > 7','x + 5'],1),
('riy3-ifade-tenlik#11','riy-3-ifade-tenlik',2,2,'Tənliyi həll edin: x + 45 = 100.','x = 100 − 45 = 55.',array['55','45','65','145'],1),
('riy3-ifade-tenlik#12','riy-3-ifade-tenlik',2,2,'50 − 20 : 4 ifadəsinin qiyməti neçədir?','Əvvəl bölmə: 20 : 4 = 5, sonra 50 − 5 = 45.',array['45','7','30','40'],1),
('riy3-ifade-tenlik#13','riy-3-ifade-tenlik',2,2,'x · 6 = 66 tənliyinin kökü neçədir?','x = 66 : 6 = 11.',array['11','60','72','12'],1),
('riy3-ifade-tenlik#14','riy-3-ifade-tenlik',2,2,'(28 + 12) : 4 ifadəsinin qiyməti neçədir?','Əvvəl mötərizə: 40, sonra 40 : 4 = 10.',array['10','31','40','12'],1),
('riy3-ifade-tenlik#15','riy-3-ifade-tenlik',2,2,'x − 130 = 170 tənliyində x neçədir?','x = 170 + 130 = 300.',array['300','40','290','310'],1),
('riy3-ifade-tenlik#16','riy-3-ifade-tenlik',3,2,'a = 6 olduqda 48 − a · 4 ifadəsinin qiyməti neçədir?','48 − 24 = 24.',array['24','168','44','28'],1),
('riy3-ifade-tenlik#17','riy-3-ifade-tenlik',3,2,'Tənliyi həll edin: 80 : x = 4.','x = 80 : 4 = 20.',array['20','76','320','40'],1),
('riy3-ifade-tenlik#18','riy-3-ifade-tenlik',2,2,'5 · 9 − 5 ifadəsini hesablayın.','45 − 5 = 40.',array['40','45','20','50'],1),
('riy3-ifade-tenlik#19','riy-3-ifade-tenlik',2,2,'Hansı ədəd x : 2 = 50 tənliyinin köküdür?','x = 50 × 2 = 100.',array['100','25','52','48'],1),
('riy3-ifade-tenlik#20','riy-3-ifade-tenlik',1,2,'Tənlik nəyə deyilir?','Tərkibində məchul olan bərabərliyə tənlik deyilir.',array['Məchulu olan bərabərliyə','İstənilən ifadəyə','Cavabı olmayan suala','Ədədlərin cəminə'],1),
('riy3-fiqurlar#1','riy-3-fiqurlar',1,2,'Üçbucağın neçə təpəsi var?','Üçbucağın 3 tərəfi, 3 təpəsi, 3 bucağı var.',array['3','4','2','6'],1),
('riy3-fiqurlar#2','riy-3-fiqurlar',1,2,'Kvadratın tərəfləri haqqında hansı fikir doğrudur?','Kvadratın bütün tərəfləri bərabərdir.',array['Hamısı bərabərdir','Yalnız qarşı tərəflər bərabərdir','Hamısı fərqlidir','Tərəfi yoxdur'],1),
('riy3-fiqurlar#3','riy-3-fiqurlar',2,2,'Tərəfi 6 sm olan kvadratın perimetrini tapın.','P = 4 · 6 = 24 sm.',array['24 sm','12 sm','36 sm','10 sm'],1),
('riy3-fiqurlar#4','riy-3-fiqurlar',2,2,'Tərəfləri 5 sm, 7 sm və 9 sm olan üçbucağın perimetri neçədir?','P = 5 + 7 + 9 = 21 sm.',array['21 sm','19 sm','23 sm','35 sm'],1),
('riy3-fiqurlar#5','riy-3-fiqurlar',3,2,'Uzunluğu 8 sm, eni 3 sm olan düzbucaqlının perimetrini tapın.','P = 2 · (8 + 3) = 22 sm.',array['22 sm','11 sm','24 sm','16 sm'],1),
('riy3-fiqurlar#6','riy-3-fiqurlar',1,2,'Küncləri (təpələri) olmayan fiqur hansıdır?','Dairənin təpəsi və tərəfi yoxdur.',array['Dairə','Kvadrat','Üçbucaq','Düzbucaqlı'],1),
('riy3-fiqurlar#7','riy-3-fiqurlar',3,2,'Perimetri 20 sm olan kvadratın tərəfi neçə santimetrdir?','a = P : 4 = 20 : 4 = 5 sm.',array['5 sm','4 sm','10 sm','16 sm'],1),
('riy3-fiqurlar#8','riy-3-fiqurlar',1,2,'Düzbucaqlının neçə bucağı var?','Düzbucaqlının 4 bucağı var və hamısı düz bucaqdır.',array['4','2','3','6'],1),
('riy3-fiqurlar#9','riy-3-fiqurlar',2,2,'Parça nədir?','Parça düz xəttin iki nöqtə arasındakı hissəsidir.',array['Düz xəttin iki nöqtə arasındakı hissəsi','Sonsuz düz xətt','Əyri xətt','Dairənin yarısı'],1),
('riy3-fiqurlar#10','riy-3-fiqurlar',2,2,'Kubun üzləri hansı fiqurdur?','Kubun 6 üzünün hamısı kvadratdır.',array['Kvadrat','Üçbucaq','Dairə','Düzbucaqlı olmayan dördbucaqlı'],1),
('riy3-fiqurlar#11','riy-3-fiqurlar',2,2,'Tərəfi 9 sm olan kvadratın perimetri neçədir?','9 × 4 = 36 sm.',array['36 sm','18 sm','13 sm','81 sm'],1),
('riy3-fiqurlar#12','riy-3-fiqurlar',2,2,'Uzunluğu 10 sm, eni 4 sm olan düzbucaqlının perimetri neçədir?','(10 + 4) × 2 = 28 sm.',array['28 sm','14 sm','40 sm','24 sm'],1),
('riy3-fiqurlar#13','riy-3-fiqurlar',1,2,'Bütün tərəfləri bərabər olan dördbucaqlı necə adlanır?','Dörd tərəfi bərabər olan düzbucaqlı kvadratdır.',array['Kvadrat','Üçbucaq','Dairə','Beşbucaqlı'],1),
('riy3-fiqurlar#14','riy-3-fiqurlar',2,2,'Perimetri 24 sm olan kvadratın tərəfi neçədir?','24 : 4 = 6 sm.',array['6 sm','8 sm','12 sm','20 sm'],1),
('riy3-fiqurlar#15','riy-3-fiqurlar',2,2,'Həndəsədə şüa necə izah olunur?','Şüanın başlanğıc nöqtəsi var, sonu yoxdur.',array['Başlanğıcı olan, sonu olmayan xətt','İki ucu olan parça','Qapalı əyri xətt','Dörd tərəfi olan fiqur'],1),
('riy3-fiqurlar#16','riy-3-fiqurlar',2,2,'Tərəfləri 4 sm, 6 sm və 7 sm olan üçbucağın perimetri neçədir?','4 + 6 + 7 = 17 sm.',array['17 sm','16 sm','18 sm','27 sm'],1),
('riy3-fiqurlar#17','riy-3-fiqurlar',2,2,'Dairənin mərkəzindən kənarına çəkilən parça necə adlanır?','Mərkəzlə çevrə üzərindəki nöqtəni birləşdirən parça radiusdur.',array['Radius','Perimetr','Diaqonal','Bucaq'],1),
('riy3-fiqurlar#18','riy-3-fiqurlar',2,2,'Hansı fiqur həcmli fiqurdur?','Kub həcmli (fəza) fiqurudur, qalanları müstəvi fiqurlardır.',array['Kub','Kvadrat','Dairə','Üçbucaq'],1),
('riy3-fiqurlar#19','riy-3-fiqurlar',2,2,'Çevrə çəkmək üçün hansı alətdən istifadə olunur?','Çevrə pərgarla çəkilir.',array['Pərgar','Xətkeş','Tərəzi','Termometr'],1),
('riy3-fiqurlar#20','riy-3-fiqurlar',3,2,'Uzunluğu 7 sm, eni 5 sm olan düzbucaqlının sahəsi neçədir?','7 × 5 = 35 sm².',array['35 sm²','24 sm²','12 sm²','70 sm²'],1),
('riy3-vurma-bolme-2#1','riy-3-vurma-bolme-2',1,3,'23 × 3 hasilini tapın.','23 × 3 = 69.',array['69','66','63','96'],1),
('riy3-vurma-bolme-2#2','riy-3-vurma-bolme-2',2,3,'45 × 4 neçə edər?','45 × 4 = 180.',array['180','160','170','185'],1),
('riy3-vurma-bolme-2#3','riy-3-vurma-bolme-2',2,3,'99 : 3 qismətini tapın.','99 : 3 = 33.',array['33','32','36','31'],1),
('riy3-vurma-bolme-2#4','riy-3-vurma-bolme-2',2,3,'84 : 4 neçə edər?','84 : 4 = 21.',array['21','22','24','12'],1),
('riy3-vurma-bolme-2#5','riy-3-vurma-bolme-2',2,3,'120 × 4 hasilini hesablayın.','120 × 4 = 480.',array['480','440','460','484'],1),
('riy3-vurma-bolme-2#6','riy-3-vurma-bolme-2',2,3,'260 × 3 neçə edər?','260 × 3 = 780.',array['780','680','760','790'],1),
('riy3-vurma-bolme-2#7','riy-3-vurma-bolme-2',2,3,'690 : 3 qismətini tapın.','690 : 3 = 230.',array['230','220','203','330'],1),
('riy3-vurma-bolme-2#8','riy-3-vurma-bolme-2',1,3,'57 × 2 neçə edər?','57 × 2 = 114.',array['114','104','124','112'],1),
('riy3-vurma-bolme-2#9','riy-3-vurma-bolme-2',3,3,'17 : 5 bölməsində qismət və qalıq neçədir?','5 × 3 = 15; 17 − 15 = 2: qismət 3, qalıq 2.',array['Qismət 3, qalıq 2','Qismət 2, qalıq 3','Qismət 3, qalıq 0','Qismət 4, qalıq 3'],1),
('riy3-vurma-bolme-2#10','riy-3-vurma-bolme-2',1,3,'800 : 4 neçə edər?','8 : 4 = 2, deməli 800 : 4 = 200.',array['200','20','240','400'],1),
('riy3-vurma-bolme-2#11','riy-3-vurma-bolme-2',1,3,'34 × 2 hasilini tapın.','34 × 2 = 68.',array['68','36','64','72'],1),
('riy3-vurma-bolme-2#12','riy-3-vurma-bolme-2',2,3,'72 : 4 qismətini hesablayın.','72 : 4 = 18.',array['18','16','24','68'],1),
('riy3-vurma-bolme-2#13','riy-3-vurma-bolme-2',2,3,'150 × 3 neçə edər?','150 × 3 = 450.',array['450','350','453','550'],1),
('riy3-vurma-bolme-2#14','riy-3-vurma-bolme-2',3,3,'91 : 7 qismətini tapın.','91 : 7 = 13.',array['13','12','14','17'],1),
('riy3-vurma-bolme-2#15','riy-3-vurma-bolme-2',2,3,'68 × 5 hasilini hesablayın.','68 × 5 = 340.',array['340','330','350','305'],1),
('riy3-vurma-bolme-2#16','riy-3-vurma-bolme-2',2,3,'480 : 6 neçə edər?','480 : 6 = 80.',array['80','60','86','90'],1),
('riy3-vurma-bolme-2#17','riy-3-vurma-bolme-2',2,3,'26 × 6 neçə edər?','26 × 6 = 156.',array['156','146','166','126'],1),
('riy3-vurma-bolme-2#18','riy-3-vurma-bolme-2',3,3,'22 : 5 bölməsində qalıq neçədir?','5 × 4 = 20, qalıq 22 − 20 = 2.',array['2','4','5','0'],1),
('riy3-vurma-bolme-2#19','riy-3-vurma-bolme-2',2,3,'Hasili tapın: 105 × 4.','105 × 4 = 420.',array['420','410','425','440'],1),
('riy3-vurma-bolme-2#20','riy-3-vurma-bolme-2',2,3,'560 : 8 qismətini tapın.','560 : 8 = 70.',array['70','80','60','78'],1),
('riy3-kesr#1','riy-3-kesr',1,3,'Tamın yarısı hansı kəsrlə göstərilir?','Yarı — tamın 2 bərabər hissəsindən biridir: 1/2.',array['1/2','2/1','1/4','2/2'],1),
('riy3-kesr#2','riy-3-kesr',1,3,'1/4 kəsri nəyi bildirir?','Tam 4 bərabər hissəyə bölünüb, onlardan biri götürülüb.',array['Tamın 4 bərabər hissəsindən birini','4 tamı','Tamın 4 mislini','4 fərqli hissəni'],1),
('riy3-kesr#3','riy-3-kesr',2,3,'12-nin 1/3 hissəsi neçədir?','12 : 3 = 4.',array['4','3','6','36'],1),
('riy3-kesr#4','riy-3-kesr',2,3,'20-nin 1/4 hissəsini tapın.','20 : 4 = 5.',array['5','4','10','80'],1),
('riy3-kesr#5','riy-3-kesr',2,3,'2/6 və 5/6 kəsrlərindən hansı böyükdür?','Məxrəclər eynidirsə, surəti böyük olan böyükdür.',array['5/6','2/6','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy3-kesr#6','riy-3-kesr',3,3,'1/5 və 1/8 kəsrlərindən hansı böyükdür?','Surətlər eynidirsə, məxrəci kiçik olan böyükdür.',array['1/5','1/8','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy3-kesr#7','riy-3-kesr',3,3,'18-in 2/3 hissəsini tapın.','18 : 3 = 6; 6 · 2 = 12.',array['12','6','9','27'],1),
('riy3-kesr#8','riy-3-kesr',1,3,'Kəsrdə xəttin üstündəki ədəd necə adlanır?','Üstdəki — surət, altdakı — məxrəcdir.',array['Surət','Məxrəc','Qismət','Vuruq'],1),
('riy3-kesr#9','riy-3-kesr',2,3,'8/8 kəsri nəyə bərabərdir?','Surət məxrəcə bərabərdirsə, kəsr 1 tama bərabərdir.',array['1 tam','0','8','1/8'],1),
('riy3-kesr#10','riy-3-kesr',3,3,'24-ün 1/2 hissəsi ilə 1/4 hissəsinin fərqi neçədir?','24 : 2 = 12; 24 : 4 = 6; 12 − 6 = 6.',array['6','12','18','3'],1),
('riy3-kesr#11','riy-3-kesr',2,3,'16-nın 1/8 hissəsi neçədir?','16 : 8 = 2.',array['2','8','4','16'],1),
('riy3-kesr#12','riy-3-kesr',2,3,'3/7 və 6/7 kəsrlərindən hansı kiçikdir?','Məxrəclər eynidirsə, surəti kiçik olan kəsr kiçikdir.',array['3/7','6/7','Bərabərdirlər','Müqayisə olunmur'],1),
('riy3-kesr#13','riy-3-kesr',1,3,'Kəsr xəttinin altında yazılan ədəd kəsrin hansı hissəsidir?','Xəttin altındakı ədəd məxrəcdir.',array['Məxrəc','Surət','Tam hissə','Qalıq'],1),
('riy3-kesr#14','riy-3-kesr',1,3,'Tamın dörddə biri hansı kəsrlə göstərilir?','Dörd bərabər hissədən biri: 1/4.',array['1/4','4/1','1/2','2/4'],1),
('riy3-kesr#15','riy-3-kesr',2,3,'65-in 1/5 hissəsini tapın.','65 : 5 = 13.',array['13','15','12','60'],1),
('riy3-kesr#16','riy-3-kesr',2,3,'1/2 və 1/6 kəsrlərindən hansı böyükdür?','Surətlər eynidirsə, məxrəci kiçik olan kəsr böyükdür.',array['1/2','1/6','Bərabərdirlər','Müqayisə olunmur'],1),
('riy3-kesr#17','riy-3-kesr',2,3,'Pizza 6 bərabər dilimə bölündü, 1 dilim yeyildi. Hansı hissə yeyilib?','6 hissədən biri: 1/6.',array['1/6','1/5','6/1','5/6'],1),
('riy3-kesr#18','riy-3-kesr',2,3,'9/9 kəsri hansı ədədə bərabərdir?','Surətlə məxrəc bərabərdirsə, kəsr 1 tama bərabərdir.',array['1 tam','9','0','9/18'],1),
('riy3-kesr#19','riy-3-kesr',3,3,'20-nin yarısı ilə 1/5 hissəsinin cəmi neçədir?','Yarısı 10, beşdə biri 4; 10 + 4 = 14.',array['14','12','15','16'],1),
('riy3-kesr#20','riy-3-kesr',1,3,'Hansı kəsr tamın üçdə birini göstərir?','Üç bərabər hissədən biri: 1/3.',array['1/3','3/1','1/2','3/3'],1),
('riy3-ededler-10000#1','riy-3-ededler-10000',1,3,'«İki min dörd yüz on» ədədi rəqəmlə necə yazılır?','2 000 + 400 + 10 = 2 410.',array['2 410','2 401','24 010','2 041'],1),
('riy3-ededler-10000#2','riy-3-ededler-10000',1,3,'3 999 ədədindən sonra gələn ədəd hansıdır?','3 999 + 1 = 4 000.',array['4 000','3 998','3 000','4 999'],1),
('riy3-ededler-10000#3','riy-3-ededler-10000',2,3,'5 306 ədədində yüzlər mərtəbəsində hansı rəqəm durur?','5 306: 5 — minlər, 3 — yüzlər, 0 — onluqlar, 6 — təkliklər.',array['3','5','0','6'],1),
('riy3-ededler-10000#4','riy-3-ededler-10000',2,3,'4 minlik və 7 yüzlükdən ibarət ədəd hansıdır?','4 000 + 700 = 4 700.',array['4 700','4 070','47 000','4 007'],1),
('riy3-ededler-10000#5','riy-3-ededler-10000',2,3,'6 099 və 6 100 ədədlərindən hansı böyükdür?','6 100 = 6 099 + 1.',array['6 100','6 099','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy3-ededler-10000#6','riy-3-ededler-10000',1,3,'1 manat neçə qəpikdir?','1 manat = 100 qəpik.',array['100 qəpik','10 qəpik','1 000 qəpik','60 qəpik'],1),
('riy3-ededler-10000#7','riy-3-ededler-10000',2,3,'2 man 50 qəp + 1 man 50 qəp neçə edər?','50 + 50 = 100 qəpik = 1 manat; cəmi 4 manat.',array['4 manat','3 manat','3 man 50 qəp','4 man 50 qəp'],1),
('riy3-ededler-10000#8','riy-3-ededler-10000',3,3,'Alıcı 5 manatla 3 man 20 qəp ödədi. Qalığı neçədir?','5 man − 3 man 20 qəp = 1 man 80 qəp.',array['1 man 80 qəp','2 man 20 qəp','1 man 20 qəp','2 man 80 qəp'],1),
('riy3-ededler-10000#9','riy-3-ededler-10000',2,3,'Ən kiçik dördrəqəmli ədəd hansıdır?','Dördrəqəmli ədədlər 1 000-dən başlayır.',array['1 000','1 001','9 999','100'],1),
('riy3-ededler-10000#10','riy-3-ededler-10000',2,3,'9 999 + 1 neçə edər?','9 999 + 1 = 10 000.',array['10 000','9 998','99 991','10 999'],1),
('riy3-ededler-10000#11','riy-3-ededler-10000',2,3,'«Yeddi min otuz» ədədi rəqəmlə necə yazılır?','7 000 + 30 = 7 030.',array['7 030','7 300','730','7 003'],1),
('riy3-ededler-10000#12','riy-3-ededler-10000',1,3,'1 462 ədədində minlər mərtəbəsində hansı rəqəm durur?','Soldan birinci rəqəm minlikləri göstərir: 1.',array['1','4','6','2'],1),
('riy3-ededler-10000#13','riy-3-ededler-10000',3,3,'4 500 ədədində cəmi neçə yüzlük var?','4 500 : 100 = 45 yüzlük.',array['45','4','5','450'],1),
('riy3-ededler-10000#14','riy-3-ededler-10000',2,3,'7 999 ədədindən sonra gələn ədəd hansıdır?','7 999 + 1 = 8 000.',array['8 000','7 998','8 999','7 990'],1),
('riy3-ededler-10000#15','riy-3-ededler-10000',2,3,'2 060 və 2 600 ədədlərindən hansı kiçikdir?','2 060 < 2 600.',array['2 060','2 600','Bərabərdirlər','Müqayisə olunmur'],1),
('riy3-ededler-10000#16','riy-3-ededler-10000',2,3,'3 minlik, 2 yüzlük və 5 təklikdən ibarət ədəd hansıdır?','3 000 + 200 + 5 = 3 205.',array['3 205','3 250','325','3 025'],1),
('riy3-ededler-10000#17','riy-3-ededler-10000',2,3,'5 man 75 qəp + 25 qəp neçə edər?','575 + 25 = 600 qəpik = 6 manat.',array['6 manat','5 manat','6 man 50 qəp','7 manat'],1),
('riy3-ededler-10000#18','riy-3-ededler-10000',3,3,'Aysu 10 manat verib 6 man 40 qəp ödədi. Ona nə qədər qalıq qayıtmalıdır?','1 000 − 640 = 360 qəpik = 3 man 60 qəp.',array['3 man 60 qəp','4 man 60 qəp','3 man 40 qəp','4 man 40 qəp'],1),
('riy3-ededler-10000#19','riy-3-ededler-10000',3,3,'4 070 ədədində 0 rəqəmi hansı mərtəbələrdə durur?','4 070: yüzlər mərtəbəsində 0, təklər mərtəbəsində 0.',array['Yüzlər və təklər','Minlər və onlar','Yalnız təklər','Yalnız minlər'],1),
('riy3-ededler-10000#20','riy-3-ededler-10000',2,3,'6 500 ədədinin mərtəbə toplananlarına ayrılışı hansıdır?','6 500 = 6 000 + 500.',array['6 000 + 500','600 + 50','6 000 + 50','65 + 100'],1),
('riy3-olcme#1','riy-3-olcme',1,4,'1 metr neçə santimetrdir?','1 m = 100 sm.',array['100 sm','10 sm','1 000 sm','60 sm'],1),
('riy3-olcme#2','riy-3-olcme',1,4,'4 metr neçə santimetrdir?','4 · 100 = 400 sm.',array['400 sm','40 sm','4 000 sm','104 sm'],1),
('riy3-olcme#3','riy-3-olcme',1,4,'1 saat neçə dəqiqədir?','1 saat = 60 dəqiqə.',array['60 dəq','100 dəq','30 dəq','24 dəq'],1),
('riy3-olcme#4','riy-3-olcme',2,4,'300 sm neçə metrdir?','300 : 100 = 3 m.',array['3 m','30 m','13 m','300 m'],1),
('riy3-olcme#5','riy-3-olcme',2,4,'2 kiloqram neçə qramdır?','1 kq = 1 000 q; 2 kq = 2 000 q.',array['2 000 q','200 q','20 q','1 002 q'],1),
('riy3-olcme#6','riy-3-olcme',2,4,'1 dəqiqə neçə saniyədir?','1 dəq = 60 saniyə.',array['60 saniyə','100 saniyə','30 saniyə','10 saniyə'],1),
('riy3-olcme#7','riy-3-olcme',3,4,'5 m 20 sm neçə santimetrdir?','5 m = 500 sm; 500 + 20 = 520 sm.',array['520 sm','52 sm','5 020 sm','502 sm'],1),
('riy3-olcme#8','riy-3-olcme',2,4,'Yarım saat neçə dəqiqədir?','60 : 2 = 30 dəqiqə.',array['30 dəq','50 dəq','15 dəq','45 dəq'],1),
('riy3-olcme#9','riy-3-olcme',3,4,'1 500 qram neçə kiloqram, neçə qramdır?','1 500 q = 1 000 q + 500 q = 1 kq 500 q.',array['1 kq 500 q','15 kq','1 kq 50 q','150 kq'],1),
('riy3-olcme#10','riy-3-olcme',1,4,'Termometr nəyi ölçür?','Termometr temperaturu (istiliyi) ölçür.',array['Temperaturu','Uzunluğu','Kütləni','Vaxtı'],1),
('riy3-olcme#11','riy-3-olcme',1,4,'3 metr neçə santimetrdir?','1 m = 100 sm, 3 m = 300 sm.',array['300 sm','30 sm','3 000 sm','130 sm'],1),
('riy3-olcme#12','riy-3-olcme',1,4,'2 saat neçə dəqiqədir?','60 × 2 = 120 dəq.',array['120 dəq','60 dəq','100 dəq','90 dəq'],1),
('riy3-olcme#13','riy-3-olcme',2,4,'3 kq neçə qramdır?','1 kq = 1 000 q, 3 kq = 3 000 q.',array['3 000 q','300 q','30 q','3 100 q'],1),
('riy3-olcme#14','riy-3-olcme',2,4,'2 dəqiqə neçə saniyədir?','60 × 2 = 120 saniyə.',array['120 saniyə','60 saniyə','20 saniyə','200 saniyə'],1),
('riy3-olcme#15','riy-3-olcme',2,4,'9 m 40 sm neçə santimetrdir?','900 + 40 = 940 sm.',array['940 sm','904 sm','490 sm','9 040 sm'],1),
('riy3-olcme#16','riy-3-olcme',3,4,'Dərs 45 dəqiqə çəkir. Saat 9:00-da başlayan dərs saat neçədə bitər?','9:00 + 45 dəq = 9:45.',array['9:45','9:30','10:00','9:50'],1),
('riy3-olcme#17','riy-3-olcme',1,4,'Tərəzi nəyi ölçmək üçündür?','Tərəzi ilə kütlə (çəki) ölçülür.',array['Kütləni','Uzunluğu','Temperaturu','Vaxtı'],1),
('riy3-olcme#18','riy-3-olcme',2,4,'70 sm + 30 sm cəmi neçə metrdir?','70 + 30 = 100 sm = 1 m.',array['1 m','2 m','10 m','100 m'],1),
('riy3-olcme#19','riy-3-olcme',1,4,'Məsafəni ölçmək üçün hansı vahiddən istifadə olunur?','Uzunluq və məsafə metrlə ölçülür.',array['Metr','Kiloqram','Litr','Saat'],1),
('riy3-olcme#20','riy-3-olcme',3,4,'3 saat 15 dəqiqə neçə dəqiqədir?','180 + 15 = 195 dəq.',array['195 dəq','185 dəq','315 dəq','165 dəq'],1),
('riy3-melumat#1','riy-3-melumat',1,4,'Satış cədvəli: alma — 12 kq, armud — 8 kq, gilas — 15 kq. Ən çox hansı meyvə satılıb?','15 > 12 > 8.',array['Gilas','Alma','Armud','Hamısı bərabər'],1),
('riy3-melumat#2','riy-3-melumat',2,4,'Həmin cədvələ görə cəmi neçə kiloqram meyvə satılıb?','12 + 8 + 15 = 35 kq.',array['35 kq','20 kq','27 kq','45 kq'],1),
('riy3-melumat#3','riy-3-melumat',1,4,'Ardıcıllığı davam etdirin: 3, 6, 9, 12, …','Hər ədəd əvvəlkindən 3 vahid çoxdur: 12 + 3 = 15.',array['15','13','14','16'],1),
('riy3-melumat#4','riy-3-melumat',2,4,'Ardıcıllığı davam etdirin: 40, 35, 30, …','Hər ədəd əvvəlkindən 5 vahid azdır: 30 − 5 = 25.',array['25','20','28','24'],1),
('riy3-melumat#5','riy-3-melumat',2,4,'I gün 24, II gün 18 kitab satılıb. II gün neçə kitab az satılıb?','24 − 18 = 6.',array['6','8','42','4'],1),
('riy3-melumat#6','riy-3-melumat',2,4,'Adi oyun zərində «9» düşməsi necə hadisədir?','Zərin üzlərində 1-dən 6-ya qədər ədədlər var.',array['Mümkünsüz','Mütləq','Mümkün','Hər dəfə baş verən'],1),
('riy3-melumat#7','riy-3-melumat',3,4,'Qutuda yalnız qırmızı toplar var. Çıxarılan topun qırmızı olması necə hadisədir?','Başqa rəng yoxdursa, qırmızı çıxması yəqin (mütləq) hadisədir.',array['Yəqin (mütləq)','Mümkünsüz','Təsadüfi','Az ehtimallı'],1),
('riy3-melumat#8','riy-3-melumat',3,4,'Ardıcıllığı davam etdirin: 2, 4, 8, 16, …','Hər ədəd əvvəlkinin 2 mislidir: 16 · 2 = 32.',array['32','18','24','20'],1),
('riy3-melumat#9','riy-3-melumat',1,4,'Siyahıdakı ən kiçik ədəd hansıdır: 507; 570; 705; 750?','Yüzlər mərtəbəsi kiçik olan ədəd kiçikdir: 507.',array['507','570','705','750'],1),
('riy3-melumat#10','riy-3-melumat',2,4,'Ballar: Aynur — 7, Tural — 9, Nərmin — 8. Ən yüksək bal kimindir?','9 > 8 > 7.',array['Tural','Aynur','Nərmin','Hamısınınkı bərabərdir'],1),
('riy3-melumat#11','riy-3-melumat',1,4,'Cədvəl: I sinif — 28, II sinif — 31, III sinif — 26 şagird. Ən az şagird hansı sinifdədir?','26 ən kiçik ədəddir.',array['III sinif','I sinif','II sinif','Hamısı bərabərdir'],1),
('riy3-melumat#12','riy-3-melumat',2,4,'Ardıcıllığı davam etdirin: 11, 22, 33, …','Hər dəfə 11 artır: 33 + 11 = 44.',array['44','43','34','55'],1),
('riy3-melumat#13','riy-3-melumat',2,4,'Zər atılanda hansı xallar düşə bilər?','Adi oyun zərinin üzlərində 1-dən 6-ya qədər xal var.',array['1-dən 6-ya qədər','0-dan 9-a qədər','Yalnız cüt ədədlər','1-dən 10-a qədər'],1),
('riy3-melumat#14','riy-3-melumat',2,4,'25 şagirddən 8-i futbol seçib, qalanları şahmat. Şahmatı neçə şagird seçib?','25 − 8 = 17.',array['17','18','16','33'],1),
('riy3-melumat#15','riy-3-melumat',2,4,'Diaqram: bazar ertəsi 4, çərşənbə 7, cümə 5 kitab oxunub. Cəmi neçə kitab oxunub?','4 + 7 + 5 = 16.',array['16','15','17','14'],1),
('riy3-melumat#16','riy-3-melumat',3,4,'Ardıcıllıqda qayda «−6»-dır, ilk ədəd 50-dir. Üçüncü ədəd neçədir?','50, 44, 38.',array['38','44','32','36'],1),
('riy3-melumat#17','riy-3-melumat',2,4,'Torbada 3 qırmızı və 3 yaşıl top var. Çıxarılan topun sarı olması necə hadisədir?','Torbada sarı top yoxdur - hadisə mümkünsüzdür.',array['Mümkünsüz','Yəqin','Təsadüfi','Mütləq'],1),
('riy3-melumat#18','riy-3-melumat',1,4,'Cədvəldə: Aysu 90 xal, Leyla 85 xal, Nigar 95 xal toplayıb. Qalib kimdir?','95 ən yüksək baldır.',array['Nigar','Aysu','Leyla','Hamısı bərabərdir'],1),
('riy3-melumat#19','riy-3-melumat',2,4,'Ən böyük ədədi seçin: 909; 990; 899; 900.','990 ən böyükdür.',array['990','909','899','900'],1),
('riy3-melumat#20','riy-3-melumat',2,4,'İki günün temperaturu: dünən 12°, bu gün 18°. Temperatur neçə dərəcə artıb?','18 − 12 = 6°.',array['6°','30°','12°','18°'],1),
('riy3-mesele#1','riy-3-mesele',1,4,'Mağazada 350 dəftər var idi. 120 dəftər satıldı. Neçə dəftər qaldı?','350 − 120 = 230.',array['230','240','220','470'],1),
('riy3-mesele#2','riy-3-mesele',1,4,'Bir tabaqda 8 alma var. 4 belə tabaqda neçə alma var?','8 · 4 = 32.',array['32','24','12','36'],1),
('riy3-mesele#3','riy-3-mesele',2,4,'Hər sinifdə 25 şagird olmaqla 3 sinifdə cəmi neçə şagird var?','25 · 3 = 75.',array['75','65','28','85'],1),
('riy3-mesele#4','riy-3-mesele',2,4,'96 konfet 8 uşağa bərabər paylanıldı. Hər uşağa neçə konfet düşdü?','96 : 8 = 12.',array['12','11','13','88'],1),
('riy3-mesele#5','riy-3-mesele',2,4,'Kitab 78 səhifədir. Aysu 35 səhifə oxuyub. Neçə səhifə qalıb?','78 − 35 = 43.',array['43','53','33','113'],1),
('riy3-mesele#6','riy-3-mesele',1,4,'Biletin qiyməti 2 manatdır. 4 bilet üçün nə qədər ödənilməlidir?','2 · 4 = 8 manat.',array['8 manat','6 manat','2 man 40 qəp','12 manat'],1),
('riy3-mesele#7','riy-3-mesele',3,4,'5 qutunun hərəsində 20 karandaş var. 30 karandaş paylanılsa, neçəsi qalar?','5 · 20 = 100; 100 − 30 = 70.',array['70','100','50','90'],1),
('riy3-mesele#8','riy-3-mesele',2,4,'İki ədədin cəmi 90-dır. Onlardan biri 54-dürsə, o biri neçədir?','90 − 54 = 36.',array['36','46','34','144'],1),
('riy3-mesele#9','riy-3-mesele',2,4,'3 həftə neçə gündür?','7 · 3 = 21 gün.',array['21','14','24','10'],1),
('riy3-mesele#10','riy-3-mesele',3,4,'Anarın 9 yaşı var. Atası ondan 4 dəfə böyükdür. Atasının neçə yaşı var?','«4 dəfə böyük» — vurma deməkdir: 9 · 4 = 36.',array['36','13','27','45'],1),
('riy3-mesele#11','riy-3-mesele',1,4,'Bağçada 45 gül əkildi, 18-i qurudu. Neçə gül qaldı?','45 − 18 = 27.',array['27','28','63','17'],1),
('riy3-mesele#12','riy-3-mesele',2,4,'Hər rəfdə 9 kitab olmaqla 6 rəfdə cəmi neçə kitab var?','9 × 6 = 54.',array['54','15','45','56'],1),
('riy3-mesele#13','riy-3-mesele',2,4,'64 şagird 4 avtobusa bərabər bölündü. Hər avtobusda neçə şagird var?','64 : 4 = 16.',array['16','14','18','60'],1),
('riy3-mesele#14','riy-3-mesele',2,4,'Dükanda 240 kq kartof var idi. 60 kq satıldı. Nə qədər kartof qaldı?','240 − 60 = 180 kq.',array['180 kq','300 kq','160 kq','190 kq'],1),
('riy3-mesele#15','riy-3-mesele',3,4,'Aslanın 28 markası var. Qardaşının markaları ondan 2 dəfə azdır. Qardaşının neçə markası var?','28 : 2 = 14.',array['14','26','56','12'],1),
('riy3-mesele#16','riy-3-mesele',3,4,'Bir dəftər 40 qəpikdir. 3 dəftərin qiyməti nə qədərdir?','40 × 3 = 120 qəpik = 1 man 20 qəp.',array['1 man 20 qəp','1 man 40 qəp','43 qəpik','1 manat'],1),
('riy3-mesele#17','riy-3-mesele',1,4,'Yeməkxanada 14 oğlan və 12 qız oturub. Cəmi neçə uşaq var?','14 + 12 = 26.',array['26','24','2','28'],1),
('riy3-mesele#18','riy-3-mesele',2,4,'Aynur həftədə 5 gün məktəbə gedir. 4 həftədə neçə gün məktəbə gedər?','5 × 4 = 20.',array['20','9','25','24'],1),
('riy3-mesele#19','riy-3-mesele',2,4,'Hər masada 4 stul olmaqla 6 masada cəmi neçə stul var?','4 × 6 = 24.',array['24','10','20','26'],1),
('riy3-mesele#20','riy-3-mesele',2,4,'Kərim 80 qəpiyi 4 uşağa bərabər payladı. Hər uşağa neçə qəpik düşdü?','80 : 4 = 20 qəpik.',array['20 qəpik','40 qəpik','84 qəpik','25 qəpik'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '3'
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
   where owner_type = 'platform' and ext_key like 'riy3-%';
  if n <> 240 then
    raise exception 'riy3 suallari: 240 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy3-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy3-%';
  if k <> 12 then
    raise exception 'movzu sayi 12 deyil: %', k;
  end if;
  raise notice 'Riyaziyyat 3 banki: % sual, 12 movzu.', n;
end $$;
