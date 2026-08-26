-- =====================================================================
--  26_bank_riy5.sql : RIYAZIYYAT 5 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy5.py yaradir:
--      python3 tools/riy5.py
--
--  8 movzu x 20 sual = 160.  ext_key: riy5-<movzu>#<sira>.
--  ON SERT: 25_movzular_orta5.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-5-faiz') then
    raise exception 'ONCE 25_movzular_orta5.sql isledilmelidir (riy-5-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy5-%';

with d(ext, topic, diff, rub, body, why, opts, correct) as (values
('riy5-natural-ededler#1','riy-5-natural-ededler',2,1,'7 milyonluq, 2 minlik və 5 təklikdən ibarət natural ədəd hansıdır?','7 000 000 + 2 000 + 5 = 7 002 005.',array['7 002 005','7 200 005','7 002 500','72 005'],1),
('riy5-natural-ededler#2','riy-5-natural-ededler',2,1,'56 789 ədədini onluqlara qədər yuvarlaqlaşdırın.','Təkliklər mərtəbəsində 9 var — yuxarı yuvarlaqlaşır: 56 790.',array['56 790','56 780','56 700','56 800'],1),
('riy5-natural-ededler#3','riy-5-natural-ededler',2,1,'4 ədədinin kubu neçəyə bərabərdir?','4³ = 4 · 4 · 4 = 64.',array['64','12','16','43'],1),
('riy5-natural-ededler#4','riy-5-natural-ededler',1,1,'9 ədədinin kvadratı neçəyə bərabərdir?','9² = 9 · 9 = 81.',array['81','18','92','99'],1),
('riy5-natural-ededler#5','riy-5-natural-ededler',2,1,'54 : 9 + 6 × 3 ifadəsinin qiymətini tapın.','Əvvəl bölmə və vurma: 6 + 18 = 24.',array['24','36','72','21'],1),
('riy5-natural-ededler#6','riy-5-natural-ededler',3,1,'36 ədədinin neçə böləni var?','Bölənlər: 1, 2, 3, 4, 6, 9, 12, 18, 36 — cəmi 9.',array['9','6','7','36'],1),
('riy5-natural-ededler#7','riy-5-natural-ededler',2,1,'Hansı ədəd 3-ə qalıqsız bölünür?','Rəqəmlərinin cəmi 3-ə bölünən ədəd 3-ə bölünür: 2+3+4=9.',array['234','125','152','203'],1),
('riy5-natural-ededler#8','riy-5-natural-ededler',2,1,'1 205 × 30 hasilini tapın.','1 205 × 3 = 3 615; sonra 10-a vur: 36 150.',array['36 150','3 615','36 015','361 500'],1),
('riy5-natural-ededler#9','riy-5-natural-ededler',2,1,'8 400 : 40 qismətini tapın.','84 : 4 = 21, deməli 8 400 : 40 = 210.',array['210','21','2 100','240'],1),
('riy5-natural-ededler#10','riy-5-natural-ededler',1,1,'İki ədəddən hansı böyükdür: 456 789, yoxsa 456 798?','Onluqlar mərtəbəsinə baxın: 9 > 8, deməli 456 798 böyükdür.',array['456 798','456 789','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy5-natural-ededler#11','riy-5-natural-ededler',2,1,'3 605 042 ədədində 6 rəqəmi hansı mərtəbədədir?','Sağdan altıncı mərtəbə — yüz minlikdir.',array['Yüz minlik','On minlik','Minlik','Milyonluq'],1),
('riy5-natural-ededler#12','riy-5-natural-ededler',2,1,'2 ədədinin dördüncü qüvvəti neçədir?','2⁴ = 2·2·2·2 = 16.',array['16','8','24','6'],1),
('riy5-natural-ededler#13','riy-5-natural-ededler',3,1,'441, 442, 443 və 445 ədədlərindən hansı 9-a bölünür?','4 + 4 + 1 = 9 — 441 bölünür.',array['441','442','443','445'],1),
('riy5-natural-ededler#14','riy-5-natural-ededler',2,1,'Sonu 0 ilə bitən ədəd hansı ədədlərə mütləq bölünür?','Həm 2-yə, həm 5-ə, həm də 10-a bölünür.',array['2-yə, 5-ə və 10-a','Yalnız 3-ə','Yalnız 7-yə','Heç birinə'],1),
('riy5-natural-ededler#15','riy-5-natural-ededler',1,1,'999 + 1 cəmi neçədir?','999 + 1 = 1 000.',array['1 000','999','9 991','1 999'],1),
('riy5-natural-ededler#16','riy-5-natural-ededler',2,1,'72 : (12 − 3) neçə edər?','Əvvəl mötərizə: 12 − 3 = 9; sonra 72 : 9 = 8.',array['8','9','3','63'],1),
('riy5-natural-ededler#17','riy-5-natural-ededler',2,1,'Beş yüz min yeddi ədədi rəqəmlə necə yazılır?','500 000 + 7 = 500 007.',array['500 007','500 700','50 007','5 007'],1),
('riy5-natural-ededler#18','riy-5-natural-ededler',2,1,'34 × 11 hasilini tapın.','34 × 10 + 34 = 340 + 34 = 374.',array['374','344','364','3 411'],1),
('riy5-natural-ededler#19','riy-5-natural-ededler',3,1,'53 : 7 bölməsində qalıq neçədir?','7 · 7 = 49; qalıq 53 − 49 = 4.',array['4','7','49','0'],1),
('riy5-natural-ededler#20','riy-5-natural-ededler',1,1,'Ən kiçik üçrəqəmli natural ədəd hansıdır?','Üçrəqəmli ədədlər 100-dən başlayır.',array['100','111','999','10'],1),
('riy5-adi-kesrler#1','riy-5-adi-kesrler',1,1,'Hansı kəsr düzgün kəsrdir?','Düzgün kəsrdə surət məxrəcdən kiçikdir: 4/9.',array['4/9','9/4','7/7','12/5'],1),
('riy5-adi-kesrler#2','riy-5-adi-kesrler',2,1,'1/2 + 1/3 cəmini tapın.','Ortaq məxrəc 6: 3/6 + 2/6 = 5/6.',array['5/6','2/5','1/6','2/6'],1),
('riy5-adi-kesrler#3','riy-5-adi-kesrler',2,1,'3/4 − 1/8 fərqini tapın.','Ortaq məxrəc 8: 6/8 − 1/8 = 5/8.',array['5/8','2/4','1/2','4/8'],1),
('riy5-adi-kesrler#4','riy-5-adi-kesrler',2,1,'2 tam 1/5 qarışıq ədədini düzgün olmayan kəsr şəklində yazın.','2 · 5 + 1 = 11; deməli 11/5.',array['11/5','3/5','2/5','10/5'],1),
('riy5-adi-kesrler#5','riy-5-adi-kesrler',3,1,'2/3 × 3/8 hasilini tapın.','Surətlər və məxrəclər vurulur: 6/24 = 1/4.',array['1/4','5/11','6/11','3/4'],1),
('riy5-adi-kesrler#6','riy-5-adi-kesrler',3,1,'4/5 : 2/5 qismətini tapın.','Bölmə tərs kəsrə vurmadır: 4/5 × 5/2 = 2.',array['2','8/25','1/2','6/5'],1),
('riy5-adi-kesrler#7','riy-5-adi-kesrler',2,1,'40 kiloqram almanın 3/8 hissəsi satıldı. Neçə kiloqram alma satıldı?','40 : 8 = 5; 5 · 3 = 15 kq.',array['15 kq','5 kq','24 kq','3 kq'],1),
('riy5-adi-kesrler#8','riy-5-adi-kesrler',3,1,'Ədədin 2/7 hissəsi 10-a bərabərdirsə, ədədin özü neçədir?','1/7 hissə: 10 : 2 = 5; ədəd: 5 · 7 = 35.',array['35','20','70','14'],1),
('riy5-adi-kesrler#9','riy-5-adi-kesrler',3,1,'7/12 və 5/8 kəsrlərindən hansı böyükdür?','Ortaq məxrəc 24: 14/24 və 15/24 — deməli 5/8 böyükdür.',array['5/8','7/12','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy5-adi-kesrler#10','riy-5-adi-kesrler',3,1,'1 tam 3/4 + 2 tam 1/2 cəmini tapın.','Tamlar: 1 + 2 = 3; kəsrlər: 3/4 + 2/4 = 5/4 = 1 tam 1/4; cəmi 4 tam 1/4.',array['4 tam 1/4','3 tam 1/4','4 tam 1/2','3 tam 4/6'],1),
('riy5-adi-kesrler#11','riy-5-adi-kesrler',1,1,'5/9 kəsrinin surəti neçədir?','Xəttin üstündəki ədəd surətdir: 5.',array['5','9','59','14'],1),
('riy5-adi-kesrler#12','riy-5-adi-kesrler',2,1,'1/4 + 2/4 cəmini tapın.','Məxrəclər eynidir: (1 + 2)/4 = 3/4.',array['3/4','3/8','2/4','1/2'],1),
('riy5-adi-kesrler#13','riy-5-adi-kesrler',2,1,'Aşağıdakılardan hansı düzgün olmayan kəsrdir?','Surət məxrəcdən böyükdürsə, kəsr düzgün deyil: 9/2.',array['9/2','2/9','1/3','4/5'],1),
('riy5-adi-kesrler#14','riy-5-adi-kesrler',3,1,'17/5 kəsrini qarışıq ədəd şəklində yazın.','17 : 5 = 3, qalıq 2 — 3 tam 2/5.',array['3 tam 2/5','2 tam 3/5','5 tam 1/3','3 tam 1/5'],1),
('riy5-adi-kesrler#15','riy-5-adi-kesrler',2,1,'2/3 kəsrini 6 məxrəcinə gətirin.','Surəti və məxrəci 2-yə vur: 4/6.',array['4/6','2/6','3/6','5/6'],1),
('riy5-adi-kesrler#16','riy-5-adi-kesrler',3,1,'5/6 − 1/2 fərqini tapın.','5/6 − 3/6 = 2/6 = 1/3.',array['1/3','4/4','2/3','1/6'],1),
('riy5-adi-kesrler#17','riy-5-adi-kesrler',3,1,'3/10 × 5 hasilini tapın.','15/10 = 3/2 = 1 tam 1/2.',array['1 tam 1/2','3/50','15/50','3 tam 1/10'],1),
('riy5-adi-kesrler#18','riy-5-adi-kesrler',2,1,'60 səhifəlik kitabın 2/5 hissəsi oxundu. Neçə səhifə oxundu?','60 : 5 = 12; 12 · 2 = 24 səhifə.',array['24','12','30','36'],1),
('riy5-adi-kesrler#19','riy-5-adi-kesrler',2,1,'Aşağıdakı cütlərdən hansı bərabər kəsrlərdir?','2/4 ixtisar olunanda 1/2 alınır.',array['1/2 və 2/4','1/2 və 2/3','1/3 və 3/1','2/5 və 5/2'],1),
('riy5-adi-kesrler#20','riy-5-adi-kesrler',2,1,'Məxrəcləri eyni olan iki kəsrdən hansı böyükdür?','Məxrəclər eynidirsə, surəti böyük olan böyükdür.',array['Surəti böyük olan','Surəti kiçik olan','Həmişə birinci','Müqayisə olunmur'],1),
('riy5-onluq-kesrler#1','riy-5-onluq-kesrler',2,2,'6,08 və 6,2 ədədlərindən hansı kiçikdir?','6,08 və 6,20: onda birlər 0 < 2, deməli 6,08 kiçikdir.',array['6,08','6,2','Bərabərdirlər','Müqayisə etmək olmaz'],1),
('riy5-onluq-kesrler#2','riy-5-onluq-kesrler',2,2,'7,354 ədədini onda birlərə qədər yuvarlaqlaşdırın.','Yüzdə birlər mərtəbəsində 5 var — yuxarı: 7,4.',array['7,4','7,3','7,35','7'],1),
('riy5-onluq-kesrler#3','riy-5-onluq-kesrler',2,2,'3/5 kəsrini onluq kəsr şəklində yazın.','3 : 5 = 0,6.',array['0,6','0,35','3,5','0,3'],1),
('riy5-onluq-kesrler#4','riy-5-onluq-kesrler',2,2,'15,73 + 4,27 cəmini tapın.','15,73 + 4,27 = 20,00 = 20.',array['20','19,9','20,1','19,10'],1),
('riy5-onluq-kesrler#5','riy-5-onluq-kesrler',3,2,'9,1 − 3,45 fərqini tapın.','9,10 − 3,45 = 5,65.',array['5,65','6,65','5,75','6,35'],1),
('riy5-onluq-kesrler#6','riy-5-onluq-kesrler',2,2,'0,37 ədədini 100-ə vurun.','100-ə vuranda vergül iki mərtəbə sağa keçir: 37.',array['37','3,7','0,0037','370'],1),
('riy5-onluq-kesrler#7','riy-5-onluq-kesrler',2,2,'8,4 × 5 hasilini tapın.','84 × 5 = 420; bir onda bir mərtəbəsi: 42.',array['42','40,20','4,2','13,4'],1),
('riy5-onluq-kesrler#8','riy-5-onluq-kesrler',2,2,'7,2 : 6 qismətini tapın.','72 : 6 = 12; vergülü qaytar: 1,2.',array['1,2','12','0,12','1,02'],1),
('riy5-onluq-kesrler#9','riy-5-onluq-kesrler',3,2,'3 : 0,5 neçə edər?','Hər vahiddə iki dənə 0,5 var: 3 : 0,5 = 6.',array['6','1,5','0,6','60'],1),
('riy5-onluq-kesrler#10','riy-5-onluq-kesrler',2,2,'3/4 kəsrinin onluq yazılışı hansıdır?','3 : 4 = 0,75.',array['0,75','0,34','0,25','7,5'],1),
('riy5-onluq-kesrler#11','riy-5-onluq-kesrler',2,2,'0,5 + 0,25 cəmini tapın.','0,50 + 0,25 = 0,75.',array['0,75','0,30','0,7','0,255'],1),
('riy5-onluq-kesrler#12','riy-5-onluq-kesrler',2,2,'4,7 × 10 neçə edər?','10-a vuranda vergül bir mərtəbə sağa keçir: 47.',array['47','4,70','0,47','470'],1),
('riy5-onluq-kesrler#13','riy-5-onluq-kesrler',2,2,'62,5 : 10 qismətini tapın.','10-a bölanda vergül bir mərtəbə sola keçir: 6,25.',array['6,25','625','0,625','62,5'],1),
('riy5-onluq-kesrler#14','riy-5-onluq-kesrler',2,2,'Onluq kəsrdə vergüldən sonrakı birinci mərtəbə necə adlanır?','Birinci mərtəbə onda birlərdir.',array['Onda birlər','Yüzdə birlər','Təkliklər','Onluqlar'],1),
('riy5-onluq-kesrler#15','riy-5-onluq-kesrler',2,2,'2,09 ədədində 9 rəqəmi hansı mərtəbədədir?','Vergüldən sonra ikinci mərtəbə — yüzdə birlər.',array['Yüzdə birlər','Onda birlər','Təkliklər','Minlik'],1),
('riy5-onluq-kesrler#16','riy-5-onluq-kesrler',2,2,'1,8 ilə 1,75-i müqayisə edin: böyük olan hansıdır?','1,80 > 1,75.',array['1,8','1,75','Bərabərdirlər','Müqayisə olunmur'],1),
('riy5-onluq-kesrler#17','riy-5-onluq-kesrler',2,2,'0,9 + 0,1 cəmi neçədir?','0,9 + 0,1 = 1.',array['1','0,10','1,1','0,91'],1),
('riy5-onluq-kesrler#18','riy-5-onluq-kesrler',2,2,'12,3 − 4,3 fərqini hesablayın.','12,3 − 4,3 = 8.',array['8','8,6','7,9','16,6'],1),
('riy5-onluq-kesrler#19','riy-5-onluq-kesrler',3,2,'0,2 × 0,4 hasilini tapın.','2 · 4 = 8; iki onluq mərtəbə: 0,08.',array['0,08','0,8','0,6','8'],1),
('riy5-onluq-kesrler#20','riy-5-onluq-kesrler',2,2,'5,5 : 5 neçə edər?','55 : 5 = 11; vergülü qaytar: 1,1.',array['1,1','11','0,11','1,5'],1),
('riy5-faiz#1','riy-5-faiz',1,2,'Faiz nə deməkdir?','1 faiz — ədədin yüzdə bir hissəsidir.',array['Ədədin yüzdə bir hissəsi','Ədədin onda bir hissəsi','Ədədin yarısı','Ədədin iki misli'],1),
('riy5-faiz#2','riy-5-faiz',2,2,'1/2 kəsri neçə faizdir?','1/2 = 50/100 = 50%.',array['50%','12%','2%','25%'],1),
('riy5-faiz#3','riy-5-faiz',2,2,'0,07 onluq kəsri neçə faizdir?','0,07 = 7/100 = 7%.',array['7%','70%','0,7%','7,7%'],1),
('riy5-faiz#4','riy-5-faiz',2,2,'200-ün 15%-i neçədir?','200 : 100 = 2; 2 · 15 = 30.',array['30','15','300','3'],1),
('riy5-faiz#5','riy-5-faiz',2,2,'60-ın 25%-i neçədir?','25% — dörddə bir hissədir: 60 : 4 = 15.',array['15','25','45','6'],1),
('riy5-faiz#6','riy-5-faiz',3,2,'Ədədin 10%-i 12-yə bərabərdirsə, ədədin özü neçədir?','10% on dəfə az deməkdir: 12 · 10 = 120.',array['120','1,2','22','102'],1),
('riy5-faiz#7','riy-5-faiz',3,2,'80 manatlıq malın qiyməti 20% artdı. Yeni qiymət neçə manatdır?','20%: 80 · 20 : 100 = 16; 80 + 16 = 96 manat.',array['96 manat','100 manat','84 manat','16 manat'],1),
('riy5-faiz#8','riy-5-faiz',3,2,'150 manatlıq mal 10% ucuzlaşdı. Yeni qiyməti tapın.','10%: 15 manat; 150 − 15 = 135 manat.',array['135 manat','140 manat','15 manat','165 manat'],1),
('riy5-faiz#9','riy-5-faiz',2,2,'25% hansı adi kəsrə bərabərdir?','25/100 = 1/4.',array['1/4','1/2','1/25','2/5'],1),
('riy5-faiz#10','riy-5-faiz',3,2,'Sinifdə 20 şagird var, onlardan 5-i əlaçıdır. Əlaçılar sinfin neçə faizini təşkil edir?','5/20 = 1/4 = 25%.',array['25%','5%','20%','40%'],1),
('riy5-faiz#11','riy-5-faiz',2,2,'3/4 kəsri neçə faizdir?','3/4 = 75/100 = 75%.',array['75%','34%','43%','3%'],1),
('riy5-faiz#12','riy-5-faiz',2,2,'0,4 ədədini faizlə ifadə edin.','0,4 = 40/100 = 40%.',array['40%','4%','0,4%','44%'],1),
('riy5-faiz#13','riy-5-faiz',2,2,'500 ədədinin 30 faizini hesablayın.','500 : 100 = 5; 5 · 30 = 150.',array['150','30','170','15'],1),
('riy5-faiz#14','riy-5-faiz',2,2,'10% hansı adi kəsrə bərabərdir?','10/100 = 1/10.',array['1/10','1/100','10/10','1/5'],1),
('riy5-faiz#15','riy-5-faiz',3,2,'Yarısı (50%-i) 45 olan ədədi tapın.','Ədəd = 45 · 2 = 90.',array['90','45','22,5','95'],1),
('riy5-faiz#16','riy-5-faiz',3,2,'40 sualdan 32-sinə düzgün cavab verildi. Düzgün cavabların faizi neçədir?','32/40 = 0,8 = 80%.',array['80%','32%','72%','8%'],1),
('riy5-faiz#17','riy-5-faiz',1,2,'Ədədin 100%-i nəyə bərabərdir?','100% — ədədin özüdür.',array['Ədədin özünə','Ədədin yarısına','Sıfıra','Ədədin iki mislinə'],1),
('riy5-faiz#18','riy-5-faiz',3,2,'Köynək 60 manatdır, 5% endirim olunub. Endirim neçə manatdır?','60 · 5 : 100 = 3 manat.',array['3 manat','5 manat','12 manat','57 manat'],1),
('riy5-faiz#19','riy-5-faiz',3,2,'1%-i 7 olan ədəd neçədir?','Ədəd = 7 · 100 = 700.',array['700','70','7','107'],1),
('riy5-faiz#20','riy-5-faiz',2,2,'20% ilə 30%-in cəmi tamın hansı hissəsidir?','20% + 30% = 50% — tamın yarısı.',array['Tamın yarısı','Tamın hamısı','Dörddə biri','Onda biri'],1),
('riy5-ifade-tenlik#1','riy-5-ifade-tenlik',2,3,'x − 45 = 120 tənliyinin kökünü tapın.','x = 120 + 45 = 165.',array['165','75','155','120'],1),
('riy5-ifade-tenlik#2','riy-5-ifade-tenlik',2,3,'5x + 3x ifadəsini sadələşdirin.','Oxşar hədlər toplanır: (5 + 3)x = 8x.',array['8x','15x','8','2x'],1),
('riy5-ifade-tenlik#3','riy-5-ifade-tenlik',2,3,'y = 7 olduqda 4y − 9 ifadəsinin qiyməti neçədir?','4 · 7 = 28; 28 − 9 = 19.',array['19','28','2','37'],1),
('riy5-ifade-tenlik#4','riy-5-ifade-tenlik',1,3,'2x = 46 tənliyinin kökü neçədir?','x = 46 : 2 = 23.',array['23','44','92','48'],1),
('riy5-ifade-tenlik#5','riy-5-ifade-tenlik',2,3,'36 : x = 4 tənliyində x-i tapın.','Bölən = bölünən : qismət = 36 : 4 = 9.',array['9','144','32','40'],1),
('riy5-ifade-tenlik#6','riy-5-ifade-tenlik',2,3,'x < 4 bərabərsizliyini hansı natural ədəd ödəyir?','3 ədədi 4-dən kiçikdir.',array['3','5','4','7'],1),
('riy5-ifade-tenlik#7','riy-5-ifade-tenlik',2,3,'Ədədin 3 misli 51-ə bərabərdir. Ədədi tapın.','3x = 51; x = 51 : 3 = 17.',array['17','48','54','153'],1),
('riy5-ifade-tenlik#8','riy-5-ifade-tenlik',2,3,'a = 6, b = 2 olduqda (a + b) : 4 ifadəsinin qiyməti neçədir?','6 + 2 = 8; 8 : 4 = 2.',array['2','8','6,5','12'],1),
('riy5-ifade-tenlik#9','riy-5-ifade-tenlik',2,3,'Hansı yazılış bərabərsizlikdir?','«>» işarəsi bərabərsizlik bildirir.',array['x > 5','x = 5','x + 5','5 + 3 = 8'],1),
('riy5-ifade-tenlik#10','riy-5-ifade-tenlik',3,3,'y = 3x asılılığında x = 4 olduqda y neçəyə bərabərdir?','y = 3 · 4 = 12.',array['12','7','34','43'],1),
('riy5-ifade-tenlik#11','riy-5-ifade-tenlik',2,3,'Tənliyi həll edin: x + 27 = 63.','x = 63 − 27 = 36.',array['36','90','44','27'],1),
('riy5-ifade-tenlik#12','riy-5-ifade-tenlik',2,3,'Oxşar hədləri birləşdirin: 9x − 3x.','(9 − 3)x = 6x.',array['6x','12x','6','3x'],1),
('riy5-ifade-tenlik#13','riy-5-ifade-tenlik',2,3,'x · 8 = 104 tənliyində x neçədir?','x = 104 : 8 = 13.',array['13','96','112','12'],1),
('riy5-ifade-tenlik#14','riy-5-ifade-tenlik',2,3,'a = 4 olduqda 5a + 2 ifadəsinin qiymətini hesablayın.','5 · 4 + 2 = 22.',array['22','20','11','542'],1),
('riy5-ifade-tenlik#15','riy-5-ifade-tenlik',2,3,'x : 6 = 7 tənliyinin kökü neçədir?','x = 6 · 7 = 42.',array['42','13','67','1'],1),
('riy5-ifade-tenlik#16','riy-5-ifade-tenlik',2,3,'Aşağıdakılardan hansı tənlikdir?','Naməlumlu bərabərlik tənlikdir: x + 4 = 9.',array['x + 4 = 9','x + 4','7 > 5','3 + 6 = 9'],1),
('riy5-ifade-tenlik#17','riy-5-ifade-tenlik',2,3,'84 − x = 30 tənliyinin kökünü tapın.','x = 84 − 30 = 54.',array['54','114','64','30'],1),
('riy5-ifade-tenlik#18','riy-5-ifade-tenlik',2,3,'P = 4a düsturunda a = 7 sm olsa, kvadratın perimetri neçədir?','P = 4 · 7 = 28 sm.',array['28 sm','11 sm','47 sm','74 sm'],1),
('riy5-ifade-tenlik#19','riy-5-ifade-tenlik',3,3,'x > 9 bərabərsizliyini ödəyən ən kiçik natural ədəd hansıdır?','9-dan böyük ən kiçik natural ədəd 10-dur.',array['10','9','8','90'],1),
('riy5-ifade-tenlik#20','riy-5-ifade-tenlik',2,3,'İfadəni sadələşdirin: 10y − y.','10y − 1y = 9y.',array['9y','10','y','11y'],1),
('riy5-mustevi-fiqurlar#1','riy-5-mustevi-fiqurlar',1,3,'Açılmış bucaq neçə dərəcədir?','Açılmış bucağın tərəfləri bir düz xətt üzərindədir: 180°.',array['180°','90°','360°','100°'],1),
('riy5-mustevi-fiqurlar#2','riy-5-mustevi-fiqurlar',2,3,'Qonşu bucaqların cəmi neçə dərəcədir?','Qonşu bucaqlar birlikdə açılmış bucaq əmələ gətirir: 180°.',array['180°','90°','60°','120°'],1),
('riy5-mustevi-fiqurlar#3','riy-5-mustevi-fiqurlar',2,3,'Bucağı iki konqruyent (bərabər) hissəyə bölən şüa necə adlanır?','Bu şüa bucağın tənböləni adlanır.',array['Tənbölən','Perpendikulyar','Diaqonal','Oturacaq'],1),
('riy5-mustevi-fiqurlar#4','riy-5-mustevi-fiqurlar',2,3,'Katetləri 6 sm və 8 sm olan düzbucaqlı üçbucağın sahəsini tapın.','S = (6 · 8) : 2 = 24 sm².',array['24 sm²','48 sm²','14 sm²','28 sm²'],1),
('riy5-mustevi-fiqurlar#5','riy-5-mustevi-fiqurlar',3,3,'Qarşılıqlı bucaqlar bir-birinə görə necədir?','İki düz xətt kəsişəndə qarşılıqlı bucaqlar bərabər olur.',array['Bərabərdirlər','Cəmi 90° olur','Həmişə fərqlidirlər','Cəmi 100° olur'],1),
('riy5-mustevi-fiqurlar#6','riy-5-mustevi-fiqurlar',2,3,'Düzbucaqlı üçbucağın sahəsi eyni ölçülü düzbucaqlının sahəsinin hansı hissəsidir?','Diaqonal düzbucaqlını iki bərabər üçbucağa bölür: yarısı.',array['Yarısı','Dörddə biri','Özü qədər','İki misli'],1),
('riy5-mustevi-fiqurlar#7','riy-5-mustevi-fiqurlar',2,3,'Eyni müstəvidə yerləşən və kəsişməyən düz xətlər necə adlanır?','Belə düz xətlər paralel adlanır.',array['Paralel','Perpendikulyar','Kəsişən','Qonşu'],1),
('riy5-mustevi-fiqurlar#8','riy-5-mustevi-fiqurlar',2,3,'Perpendikulyar düz xətlər hansı bucaq altında kəsişir?','Perpendikulyar xətlər düz bucaq (90°) altında kəsişir.',array['Düz bucaq (90°) altında','İti bucaq altında','Kor bucaq altında','Açılmış bucaq altında'],1),
('riy5-mustevi-fiqurlar#9','riy-5-mustevi-fiqurlar',2,3,'45°-lik bucaq hansı növ bucaqdır?','90°-dən kiçik bucaq iti bucaqdır.',array['İti','Kor','Düz','Açılmış'],1),
('riy5-mustevi-fiqurlar#10','riy-5-mustevi-fiqurlar',3,3,'Kor bucaq hansı ölçüdə olur?','Kor bucaq 90°-dən böyük, 180°-dən kiçikdir.',array['90°-dən böyük, 180°-dən kiçik','90°-dən kiçik','Düz 90°','180°-dən böyük'],1),
('riy5-mustevi-fiqurlar#11','riy-5-mustevi-fiqurlar',1,3,'İti bucaq neçə dərəcədən kiçik olur?','İti bucaq 90°-dən kiçikdir.',array['90°-dən kiçik','180°-dən böyük','360°-dən kiçik','90°-dən böyük'],1),
('riy5-mustevi-fiqurlar#12','riy-5-mustevi-fiqurlar',2,3,'Tam dövrə (tam bucaq) neçə dərəcədir?','Tam dövrə 360°-dir.',array['360°','180°','90°','270°'],1),
('riy5-mustevi-fiqurlar#13','riy-5-mustevi-fiqurlar',1,3,'Kvadratın bütün bucaqları hansı bucaqdır?','Kvadratın hər bucağı düz bucaqdır.',array['Düz bucaq','İti bucaq','Kor bucaq','Açılmış bucaq'],1),
('riy5-mustevi-fiqurlar#14','riy-5-mustevi-fiqurlar',2,3,'Bucağın dərəcə ölçüsü hansı alətlə ölçülür?','Bucaq transportirlə ölçülür.',array['Transportirlə','Xətkeşlə','Pərgarla','Tərəzi ilə'],1),
('riy5-mustevi-fiqurlar#15','riy-5-mustevi-fiqurlar',2,3,'Kvadratın perimetri 44 sm-dirsə, bir tərəfi neçədir?','44 : 4 = 11 sm.',array['11 sm','22 sm','40 sm','12 sm'],1),
('riy5-mustevi-fiqurlar#16','riy-5-mustevi-fiqurlar',2,3,'Uzunluğu 8 sm, eni 5 sm olan düzbucaqlının perimetrini tapın.','P = 2 · (8 + 5) = 26 sm.',array['26 sm','13 sm','40 sm','52 sm'],1),
('riy5-mustevi-fiqurlar#17','riy-5-mustevi-fiqurlar',2,3,'Çevrənin mərkəzindən üzərindəki nöqtəyə qədər olan məsafə necə adlanır?','Bu məsafə radiusdur.',array['Radius','Diametr','Vətər','Qövs'],1),
('riy5-mustevi-fiqurlar#18','riy-5-mustevi-fiqurlar',2,3,'Diametr radiusdan neçə dəfə böyükdür?','d = 2r — iki dəfə.',array['2 dəfə','4 dəfə','Bərabərdir','10 dəfə'],1),
('riy5-mustevi-fiqurlar#19','riy-5-mustevi-fiqurlar',2,3,'Tərəfi 6 sm olan kvadratın sahəsi neçədir?','S = 6 · 6 = 36 sm².',array['36 sm²','12 sm²','24 sm²','66 sm²'],1),
('riy5-mustevi-fiqurlar#20','riy-5-mustevi-fiqurlar',1,3,'Düzbucaqlının sahəsi necə tapılır?','Uzunluq enə vurulur.',array['Uzunluq × en','Uzunluq + en','Tərəflərin cəmi × 2','Uzunluq × 4'],1),
('riy5-feza-fiqurlari#1','riy-5-feza-fiqurlari',3,4,'Tili 3 sm olan kubun səthinin sahəsini tapın.','Bir üzün sahəsi 9 sm²; 6 üz: 6 · 9 = 54 sm².',array['54 sm²','27 sm²','9 sm²','36 sm²'],1),
('riy5-feza-fiqurlari#2','riy-5-feza-fiqurlari',2,4,'Ölçüləri 5 sm, 4 sm və 2 sm olan kuboidin həcmini tapın.','V = 5 · 4 · 2 = 40 sm³.',array['40 sm³','11 sm³','22 sm³','80 sm³'],1),
('riy5-feza-fiqurlari#3','riy-5-feza-fiqurlari',2,4,'Tili 4 sm olan kubun həcmi neçədir?','V = 4 · 4 · 4 = 64 sm³.',array['64 sm³','16 sm³','12 sm³','96 sm³'],1),
('riy5-feza-fiqurlari#4','riy-5-feza-fiqurlari',3,4,'1 m³ neçə litrdir?','1 m³ = 1 000 litr.',array['1 000 litr','100 litr','10 litr','10 000 litr'],1),
('riy5-feza-fiqurlari#5','riy-5-feza-fiqurlari',3,4,'1 dm³ neçə kub santimetrdir?','1 dm = 10 sm; 10 · 10 · 10 = 1 000 sm³.',array['1 000 sm³','100 sm³','10 sm³','30 sm³'],1),
('riy5-feza-fiqurlari#6','riy-5-feza-fiqurlari',2,4,'Düz prizmanın həcmi necə hesablanır?','V = oturacağın sahəsi × hündürlük.',array['Oturacağın sahəsi × hündürlük','Bütün tillərin cəmi','Perimetr × 2','Üzlərin sayı × 6'],1),
('riy5-feza-fiqurlari#7','riy-5-feza-fiqurlari',2,4,'Kuboidin neçə tili var?','Kuboidin 12 tili var.',array['12','6','8','4'],1),
('riy5-feza-fiqurlari#8','riy-5-feza-fiqurlari',3,4,'1 hektar neçə kvadrat metrdir?','1 ha = 100 m · 100 m = 10 000 m².',array['10 000 m²','1 000 m²','100 m²','100 000 m²'],1),
('riy5-feza-fiqurlari#9','riy-5-feza-fiqurlari',3,4,'Ölçüləri 6 sm, 3 sm və 2 sm olan kuboidin səthinin sahəsini tapın.','S = 2 · (6·3 + 6·2 + 3·2) = 2 · 36 = 72 sm².',array['72 sm²','36 sm²','11 sm²','66 sm²'],1),
('riy5-feza-fiqurlari#10','riy-5-feza-fiqurlari',3,4,'Akvariumun ölçüləri 40 sm, 30 sm və 20 sm-dir. Onun tutumu neçə litrdir?','V = 40 · 30 · 20 = 24 000 sm³ = 24 litr.',array['24 litr','240 litr','90 litr','2,4 litr'],1),
('riy5-feza-fiqurlari#11','riy-5-feza-fiqurlari',1,4,'Kubun üzlərinin sayı neçədir?','Kubun 6 üzü var.',array['6 üz','4 üz','8 üz','12 üz'],1),
('riy5-feza-fiqurlari#12','riy-5-feza-fiqurlari',1,4,'Kubun hər üzü hansı həndəsi fiqurdur?','Hər üz kvadratdır.',array['Kvadrat','Düzbucaqlı','Üçbucaq','Dairə'],1),
('riy5-feza-fiqurlari#13','riy-5-feza-fiqurlari',2,4,'Kuboidin ölçüləri 8, 5 və 3 santimetrdir. Həcmi neçə kub santimetrdir?','V = 8 · 5 · 3 = 120 sm³.',array['120 sm³','16 sm³','40 sm³','240 sm³'],1),
('riy5-feza-fiqurlari#14','riy-5-feza-fiqurlari',2,4,'Hansı fiqurun bütün tilləri bərabərdir?','Kubun bütün tilləri bərabərdir.',array['Kubun','Kuboidin','Silindrin','Konusun'],1),
('riy5-feza-fiqurlari#15','riy-5-feza-fiqurlari',2,4,'Silindrin oturacağı hansı fiqurdur?','Silindrin oturacağı dairədir.',array['Dairə','Kvadrat','Üçbucaq','Altıbucaqlı'],1),
('riy5-feza-fiqurlari#16','riy-5-feza-fiqurlari',2,4,'Konusun neçə təpə nöqtəsi var?','Konusun bir təpəsi var.',array['1 təpə','2 təpə','4 təpə','Təpəsi yoxdur'],1),
('riy5-feza-fiqurlari#17','riy-5-feza-fiqurlari',3,4,'Bir litr həcm neçə kub santimetrə bərabərdir?','1 litr = 1 000 sm³.',array['1 000 sm³','100 sm³','10 sm³','10 000 sm³'],1),
('riy5-feza-fiqurlari#18','riy-5-feza-fiqurlari',2,4,'Kuboidin qarşı üzləri bir-birinə necədir?','Qarşı üzlər bərabərdir.',array['Bərabərdir','Perpendikulyardır','Fərqlidir','Üçbucaqdır'],1),
('riy5-feza-fiqurlari#19','riy-5-feza-fiqurlari',3,4,'Sahəsi 20 000 m² olan sahə neçə hektardır?','20 000 : 10 000 = 2 ha.',array['2 ha','20 ha','200 ha','0,2 ha'],1),
('riy5-feza-fiqurlari#20','riy-5-feza-fiqurlari',3,4,'Kubun tili 2 dəfə artırılsa, həcmi neçə dəfə artar?','V = a³ olduğundan həcm 2³ = 8 dəfə artar.',array['8 dəfə','2 dəfə','4 dəfə','6 dəfə'],1),
('riy5-statistika#1','riy-5-statistika',2,4,'7, 9 və 14 ədədlərinin ədədi ortasını tapın.','(7 + 9 + 14) : 3 = 30 : 3 = 10.',array['10','9','30','15'],1),
('riy5-statistika#2','riy-5-statistika',3,4,'Beş ədədin ədədi ortası 8-dirsə, bu ədədlərin cəmi neçədir?','Cəm = orta · say = 8 · 5 = 40.',array['40','13','8','85'],1),
('riy5-statistika#3','riy-5-statistika',2,4,'Dairəvi diaqram bütövlükdə neçə dərəcəlik dairədən ibarətdir?','Tam dairə 360°-dir.',array['360°','180°','100°','90°'],1),
('riy5-statistika#4','riy-5-statistika',2,4,'Dairəvi diaqramda yarım dairə bütövün neçə faizini göstərir?','Yarım dairə — yarısı, yəni 50%.',array['50%','25%','75%','100%'],1),
('riy5-statistika#5','riy-5-statistika',2,4,'Şagirdin qiymətləri: 4, 5, 3, 4. Qiymətlərin ədədi ortası neçədir?','(4 + 5 + 3 + 4) : 4 = 16 : 4 = 4.',array['4','5','3','16'],1),
('riy5-statistika#6','riy-5-statistika',2,4,'Məlumatları cədvəl və diaqramda göstərmək nə üçün faydalıdır?','Müqayisə etmək və nəticə çıxarmaq asanlaşır.',array['Müqayisə və təhlil asanlaşır','Yazı azalmır, çoxalır','Heç bir faydası yoxdur','Yalnız bəzək üçündür'],1),
('riy5-statistika#7','riy-5-statistika',2,4,'20, 30, 40 və 50 ədədlərinin ədədi ortası neçədir?','(20 + 30 + 40 + 50) : 4 = 140 : 4 = 35.',array['35','40','140','30'],1),
('riy5-statistika#8','riy-5-statistika',2,4,'Komanda üç oyunda 9, 3 və 6 xal topladı. Oyun başına orta xal neçədir?','(9 + 3 + 6) : 3 = 18 : 3 = 6.',array['6','9','18','3'],1),
('riy5-statistika#9','riy-5-statistika',3,4,'Dairəvi diaqramda 90°-lik sektor bütövün hansı hissəsidir?','90/360 = 1/4 — dörddə biri (25%).',array['Dörddə biri (25%)','Yarısı (50%)','Onda biri (10%)','Üçdə biri'],1),
('riy5-statistika#10','riy-5-statistika',2,4,'2, 5, 5, 3, 5, 2 sırasında ən çox təkrarlanan ədəd hansıdır?','5 ədədi üç dəfə təkrarlanır.',array['5','2','3','Hamısı bərabər'],1),
('riy5-statistika#11','riy-5-statistika',2,4,'11, 13 və 18 ədədlərinin ədədi ortasını tapın.','(11 + 13 + 18) : 3 = 42 : 3 = 14.',array['14','13','42','18'],1),
('riy5-statistika#12','riy-5-statistika',1,4,'Müşahidə nəticələri ilk növbədə haraya yazılır?','Nəticələr cədvələ qeyd olunur.',array['Cədvələ','Şeirə','Xəritəyə','Lüğətə'],1),
('riy5-statistika#13','riy-5-statistika',3,4,'72 dərəcəlik sektor tam dairənin hansı hissəsini tutur?','72/360 = 1/5 — beşdə biri.',array['Beşdə birini (1/5)','Yarısını','Dörddə birini','Onda birini'],1),
('riy5-statistika#14','riy-5-statistika',2,4,'Hansı ədəd 7, 7, 2, 9 siyahısında ən çox təkrarlanır?','7 iki dəfə təkrarlanır.',array['7','2','9','Hamısı bərabər'],1),
('riy5-statistika#15','riy-5-statistika',3,4,'İki ədədin ədədi ortası 20-dirsə, cəmləri neçədir?','Cəm = 20 · 2 = 40.',array['40','20','10','400'],1),
('riy5-statistika#16','riy-5-statistika',2,4,'Sütunlu diaqramda ən hündür sütun nəyi bildirir?','Ən böyük qiyməti göstərir.',array['Ən böyük qiyməti','Ən kiçik qiyməti','Orta qiyməti','Heç nəyi'],1),
('riy5-statistika#17','riy-5-statistika',1,4,'Sorğu keçirməzdən əvvəl nə hazırlanmalıdır?','Əvvəlcə suallar hazırlanır.',array['Suallar','Cavablar','Diaqram','Nəticə'],1),
('riy5-statistika#18','riy-5-statistika',3,4,'Sinifdəki 25 şagirddən 10-u idmanla məşğuldur. Bu, sinfin neçə faizidir?','10/25 = 0,4 = 40%.',array['40%','10%','25%','50%'],1),
('riy5-statistika#19','riy-5-statistika',2,4,'Üç günün temperaturu 12°, 16° və 20° olub. Orta temperatur neçədir?','(12 + 16 + 20) : 3 = 16°.',array['16°','12°','48°','18°'],1),
('riy5-statistika#20','riy-5-statistika',2,4,'Qrafik təqdimat oxucuya nə verir?','Məlumatı bir baxışla qavramağa imkan verir — əyanilik.',array['Əyanilik','Səs','Qoxu','Heç nə'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '5'
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
   where owner_type = 'platform' and ext_key like 'riy5-%';
  if n <> 160 then
    raise exception 'riy5 suallari: 160 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy5-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy5-%';
  if k <> 8 then
    raise exception 'movzu sayi 8 deyil: %', k;
  end if;
  raise notice 'Riyaziyyat 5 banki: % sual, 8 movzu.', n;
end $$;
