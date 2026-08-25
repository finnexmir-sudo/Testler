-- =====================================================================
--  24_bank_sinif2.sql : 2-CI SINIF PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/sinif2.py yaradir:
--      python3 tools/sinif2.py
--
--  Riyaziyyat 9 + Az dili 7 + Heyat bilgisi 6 + Informatika 4
--  = 26 movzu x 10 = 260.  ext_key: riy2-/az2-/hey2-/inf2-...
--  ON SERT: 14_movzular.sql ve 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('riyaziyyat','riy-2-vurma-cedveli'),
                                ('az-dili','az-2-durgu'),
                                ('hayat-bilgisi','hey-2-yer-kuresi'),
                                ('informatika','inf-2-obyekt'))
     having count(*) = 4) then
    raise exception 'ONCE 14_movzular.sql ve 15_movzular_ederslik.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'riy2-%' or q.ext_key like 'az2-%'
        or q.ext_key like 'hey2-%' or q.ext_key like 'inf2-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('riy2-ededler-100#1','riyaziyyat','riy-2-ededler-100',1,1,'«Altmış beş» ədədi rəqəmlə necə yazılır?','60 + 5 = 65.',array['65','56','605','55'],1),
('riy2-ededler-100#2','riyaziyyat','riy-2-ededler-100',2,1,'78 ədədində onluqların sayı neçədir?','78 = 7 onluq və 8 təklik.',array['7','8','78','70'],1),
('riy2-ededler-100#3','riyaziyyat','riy-2-ededler-100',2,1,'9 onluq və 2 təklikdən ibarət ədəd hansıdır?','9 onluq = 90; 90 + 2 = 92.',array['92','29','902','11'],1),
('riy2-ededler-100#4','riyaziyyat','riy-2-ededler-100',1,1,'56-dan bilavasitə əvvəl gələn ədədi yazın.','56 − 1 = 55.',array['55','57','46','54'],1),
('riy2-ededler-100#5','riyaziyyat','riy-2-ededler-100',2,1,'Ən kiçik ikirəqəmli ədəd hansıdır?','İkirəqəmli ədədlər 10-dan başlayır.',array['10','11','99','1'],1),
('riy2-ededler-100#6','riyaziyyat','riy-2-ededler-100',2,1,'40, 60, 50 ədədlərini azalan sırada düzün.','Böyükdən kiçiyə: 60, 50, 40.',array['60, 50, 40','40, 50, 60','50, 60, 40','60, 40, 50'],1),
('riy2-ededler-100#7','riyaziyyat','riy-2-ededler-100',2,1,'83 və 38 ədədlərindən hansı kiçikdir?','38-də 3 onluq, 83-də 8 onluq var: 38 kiçikdir.',array['38','83','Bərabərdirlər','Bilmək olmaz'],1),
('riy2-ededler-100#8','riyaziyyat','riy-2-ededler-100',2,1,'Onluqlarla geriyə sayma: 90, 80, 70, ? Növbəti ədəd hansıdır?','Hər addımda 1 onluq azalır: 60.',array['60','50','65','80'],1),
('riy2-ededler-100#9','riyaziyyat','riy-2-ededler-100',2,1,'Hansı ədəd təkdir?','Sonu 1, 3, 5, 7, 9 ilə bitən ədədlər təkdir: 31.',array['31','14','32','48'],1),
('riy2-ededler-100#10','riyaziyyat','riy-2-ededler-100',3,1,'76 ədədi mərtəbə toplananlarının cəmi kimi necə yazılır?','76 = 7 onluq + 6 təklik = 70 + 6.',array['70 + 6','7 + 6','70 + 60','76 + 0'],1),
('riy2-toplama-cixma#1','riyaziyyat','riy-2-toplama-cixma',1,1,'34 + 23 neçə edər?','34 + 23 = 57.',array['57','56','67','11'],1),
('riy2-toplama-cixma#2','riyaziyyat','riy-2-toplama-cixma',2,1,'48 + 27 cəmini tapın.','8 + 7 = 15, biri onluğa keçir: 48 + 27 = 75.',array['75','65','74','615'],1),
('riy2-toplama-cixma#3','riyaziyyat','riy-2-toplama-cixma',1,1,'65 − 31 fərqini tapın.','65 − 31 = 34.',array['34','35','44','96'],1),
('riy2-toplama-cixma#4','riyaziyyat','riy-2-toplama-cixma',2,1,'72 − 46 neçə edər?','2-dən 6 çıxmır, onluqdan borc alınır: 72 − 46 = 26.',array['26','36','34','24'],1),
('riy2-toplama-cixma#5','riyaziyyat','riy-2-toplama-cixma',2,1,'80 − 37 fərqini hesablayın.','80 − 37 = 43.',array['43','53','47','117'],1),
('riy2-toplama-cixma#6','riyaziyyat','riy-2-toplama-cixma',1,1,'25 + 25 neçə edər?','25 + 25 = 50.',array['50','40','45','55'],1),
('riy2-toplama-cixma#7','riyaziyyat','riy-2-toplama-cixma',3,1,'Cəm 70-dir, toplananlardan biri 42-dir. O biri toplananı tapın.','70 − 42 = 28.',array['28','32','112','38'],1),
('riy2-toplama-cixma#8','riyaziyyat','riy-2-toplama-cixma',2,1,'19 + 19 neçə edər?','19 + 19 = 38.',array['38','28','37','39'],1),
('riy2-toplama-cixma#9','riyaziyyat','riy-2-toplama-cixma',3,1,'Hansı ifadənin qiyməti 100-dür?','64 + 36 = 100.',array['64 + 36','54 + 36','64 + 26','74 + 36'],1),
('riy2-toplama-cixma#10','riyaziyyat','riy-2-toplama-cixma',1,1,'53 + 20 neçə olar?','Onluqlar toplanır: 53 + 20 = 73.',array['73','55','63','83'],1),
('riy2-vurma#1','riyaziyyat','riy-2-vurma',1,2,'3 + 3 + 3 + 3 cəmini vurma ilə necə yazmaq olar?','3 ədədi 4 dəfə toplanır: 3 × 4.',array['3 × 4','3 × 3','4 × 4','3 + 4'],1),
('riy2-vurma#2','riyaziyyat','riy-2-vurma',2,2,'2 × 5 yazılışı nə deməkdir?','2 ədədinin 5 dəfə toplanması deməkdir.',array['2-nin 5 dəfə toplanması','2 ilə 5-in cəmi','5-dən 2-nin çıxılması','2-nin 5-ə bölünməsi'],1),
('riy2-vurma#3','riyaziyyat','riy-2-vurma',2,2,'4 + 4 + 4 = 4 × ? Sual işarəsinin yerinə hansı ədəd yazılmalıdır?','4 ədədi 3 dəfə toplanıb: 4 × 3.',array['3','4','12','2'],1),
('riy2-vurma#4','riyaziyyat','riy-2-vurma',2,2,'Vurma əməlinin nəticəsi necə adlanır?','Vurmanın nəticəsi hasildir.',array['Hasil','Cəm','Fərq','Qismət'],1),
('riy2-vurma#5','riyaziyyat','riy-2-vurma',1,2,'Ədədi 1-ə vuranda nə alınır?','İstənilən ədədi 1-ə vuranda ədədin özü alınır.',array['Ədədin özü','Sıfır','1','Ədədin iki misli'],1),
('riy2-vurma#6','riyaziyyat','riy-2-vurma',2,2,'6 × 0 neçə olar?','Sıfıra vurmanın hasili həmişə sıfırdır.',array['0','6','60','1'],1),
('riy2-vurma#7','riyaziyyat','riy-2-vurma',2,2,'2 × 3 və 3 × 2 hasilləri haqqında nə demək olar?','Vuruqların yeri dəyişəndə hasil dəyişmir.',array['Hasilləri bərabərdir','Birincisi böyükdür','İkincisi böyükdür','Müqayisə etmək olmaz'],1),
('riy2-vurma#8','riyaziyyat','riy-2-vurma',2,2,'Hər boşqabda 2 kotlet olmaqla 5 boşqabda neçə kotlet var?','2 × 5 = 10.',array['10','7','2','25'],1),
('riy2-vurma#9','riyaziyyat','riy-2-vurma',2,2,'Vuruqlar 5 və 3-dürsə, hasil neçədir?','5 × 3 = 15.',array['15','8','53','2'],1),
('riy2-vurma#10','riyaziyyat','riy-2-vurma',1,2,'Hansı yazılış vurma əməlidir?','«×» işarəsi vurmanı göstərir.',array['2 × 6','2 + 6','6 − 2','6 : 2'],1),
('riy2-vurma-cedveli#1','riyaziyyat','riy-2-vurma-cedveli',1,2,'2 × 7 neçə edər?','2 × 7 = 14.',array['14','12','16','9'],1),
('riy2-vurma-cedveli#2','riyaziyyat','riy-2-vurma-cedveli',2,2,'3 × 6 hasilini tapın.','3 × 6 = 18.',array['18','15','21','9'],1),
('riy2-vurma-cedveli#3','riyaziyyat','riy-2-vurma-cedveli',2,2,'4 × 8 neçə edər?','4 × 8 = 32.',array['32','28','36','12'],1),
('riy2-vurma-cedveli#4','riyaziyyat','riy-2-vurma-cedveli',1,2,'5 × 5 hasilini hesablayın.','5 × 5 = 25.',array['25','20','30','10'],1),
('riy2-vurma-cedveli#5','riyaziyyat','riy-2-vurma-cedveli',2,2,'3 × 9 neçə edər?','3 × 9 = 27.',array['27','24','30','12'],1),
('riy2-vurma-cedveli#6','riyaziyyat','riy-2-vurma-cedveli',1,2,'4 × 4 hasilini tapın.','4 × 4 = 16.',array['16','12','20','8'],1),
('riy2-vurma-cedveli#7','riyaziyyat','riy-2-vurma-cedveli',1,2,'4 × 3 neçə olar?','4 × 3 = 12.',array['12','9','16','7'],1),
('riy2-vurma-cedveli#8','riyaziyyat','riy-2-vurma-cedveli',2,2,'5 × 7 hasilini hesablayın.','5 × 7 = 35.',array['35','30','40','12'],1),
('riy2-vurma-cedveli#9','riyaziyyat','riy-2-vurma-cedveli',1,2,'3 × 3 neçə edər?','3 × 3 = 9.',array['9','6','12','33'],1),
('riy2-vurma-cedveli#10','riyaziyyat','riy-2-vurma-cedveli',3,2,'5-ə vurmanın hasili həmişə hansı rəqəmlərlə bitir?','5-in cədvəlində hasillər 5, 10, 15, 20… — sonu 0 və ya 5 olur.',array['0 və ya 5','1 və ya 2','Yalnız 5','İstənilən rəqəmlə'],1),
('riy2-bolme#1','riyaziyyat','riy-2-bolme',1,3,'10 : 2 neçə edər?','10 : 2 = 5, çünki 2 × 5 = 10.',array['5','4','8','20'],1),
('riy2-bolme#2','riyaziyyat','riy-2-bolme',1,3,'12 : 3 qismətini tapın.','12 : 3 = 4.',array['4','3','6','9'],1),
('riy2-bolme#3','riyaziyyat','riy-2-bolme',2,3,'18 : 2 neçə olar?','18 : 2 = 9.',array['9','8','16','7'],1),
('riy2-bolme#4','riyaziyyat','riy-2-bolme',2,3,'28 : 4 qismətini hesablayın.','28 : 4 = 7.',array['7','6','8','24'],1),
('riy2-bolme#5','riyaziyyat','riy-2-bolme',2,3,'40 : 5 neçə edər?','40 : 5 = 8.',array['8','7','9','35'],1),
('riy2-bolme#6','riyaziyyat','riy-2-bolme',1,3,'15 : 5 qismətini tapın.','15 : 5 = 3.',array['3','5','10','4'],1),
('riy2-bolme#7','riyaziyyat','riy-2-bolme',2,3,'30 : 5 neçə olar?','30 : 5 = 6.',array['6','5','7','25'],1),
('riy2-bolme#8','riyaziyyat','riy-2-bolme',2,3,'8 fındıq 4 dələyə bərabər bölündü. Hər dələyə neçə fındıq düşdü?','8 : 4 = 2.',array['2','4','12','32'],1),
('riy2-bolme#9','riyaziyyat','riy-2-bolme',2,3,'Bölmə əməlinin nəticəsi necə adlanır?','Bölmənin nəticəsi qismətdir.',array['Qismət','Hasil','Cəm','Fərq'],1),
('riy2-bolme#10','riyaziyyat','riy-2-bolme',3,3,'Bölmə hansı əməlin tərsidir?','Bölmə vurmanın tərs əməlidir.',array['Vurmanın','Toplamanın','Çıxmanın','Heç birinin'],1),
('riy2-zaman#1','riyaziyyat','riy-2-zaman',2,3,'Saatın qısa (kiçik) əqrəbi nəyi göstərir?','Kiçik əqrəb saatı, böyük əqrəb dəqiqəni göstərir.',array['Saatı','Dəqiqəni','Saniyəni','Günü'],1),
('riy2-zaman#2','riyaziyyat','riy-2-zaman',2,3,'Bir gecə-gündüz (sutka) neçə saatdır?','Sutkada 24 saat var.',array['24','12','60','7'],1),
('riy2-zaman#3','riyaziyyat','riy-2-zaman',1,3,'Həftənin neçə dərs günü var?','Şagirdlər həftədə 5 gün oxuyur.',array['5','7','6','4'],1),
('riy2-zaman#4','riyaziyyat','riy-2-zaman',2,3,'Saat 9-dan saat 11-ə qədər neçə saat keçir?','11 − 9 = 2 saat.',array['2','3','20','1'],1),
('riy2-zaman#5','riyaziyyat','riy-2-zaman',2,3,'Film saat 3-də başladı və 2 saat çəkdi. Film saat neçədə bitdi?','3 + 2 = 5-də.',array['5-də','6-da','4-də','1-də'],1),
('riy2-zaman#6','riyaziyyat','riy-2-zaman',1,3,'Payızdan sonra hansı fəsil gəlir?','Fəsillərin sırası: yaz, yay, payız, qış.',array['Qış','Yaz','Yay','Yenə payız'],1),
('riy2-zaman#7','riyaziyyat','riy-2-zaman',2,3,'Bir ay təxminən neçə həftədir?','Ayda təxminən 4 həftə var.',array['4','2','10','12'],1),
('riy2-zaman#8','riyaziyyat','riy-2-zaman',3,3,'Böyük əqrəb 6-nın üstündə olanda deyirik: saatın …','30 dəqiqə keçib — saatın yarısıdır.',array['yarısı','tamamı','rübü','sonu'],1),
('riy2-zaman#9','riyaziyyat','riy-2-zaman',3,3,'Hansı daha uzundur: 1 saat, yoxsa 100 dəqiqə?','1 saat = 60 dəqiqə; 100 > 60, deməli 100 dəqiqə uzundur.',array['100 dəqiqə','1 saat','Bərabərdirlər','Bilmək olmaz'],1),
('riy2-zaman#10','riyaziyyat','riy-2-zaman',2,3,'Sentyabr ilin neçənci ayıdır?','Sentyabr 9-cu aydır.',array['9-cu','8-ci','10-cu','1-ci'],1),
('riy2-olcu#1','riyaziyyat','riy-2-olcu',2,3,'1 desimetr neçə santimetrdir?','1 dm = 10 sm.',array['10 sm','100 sm','1 sm','5 sm'],1),
('riy2-olcu#2','riyaziyyat','riy-2-olcu',2,3,'1 metr neçə desimetrdir?','1 m = 10 dm.',array['10 dm','100 dm','2 dm','60 dm'],1),
('riy2-olcu#3','riyaziyyat','riy-2-olcu',2,3,'3 metr neçə desimetrdir?','3 × 10 = 30 dm.',array['30 dm','3 dm','300 dm','13 dm'],1),
('riy2-olcu#4','riyaziyyat','riy-2-olcu',1,3,'Mayeləri hansı vahidlə ölçürük?','Maye litrlə ölçülür.',array['Litrlə','Metrlə','Kiloqramla','Saatla'],1),
('riy2-olcu#5','riyaziyyat','riy-2-olcu',1,3,'Kütləni ölçən cihaz hansıdır?','Kütlə tərəzi ilə ölçülür.',array['Tərəzi','Xətkeş','Saat','Stəkan'],1),
('riy2-olcu#6','riyaziyyat','riy-2-olcu',2,3,'Bir səbətdə 5 kq, o birində 3 kq kartof var. Birlikdə neçə kiloqramdır?','5 + 3 = 8 kq.',array['8 kq','2 kq','15 kq','53 kq'],1),
('riy2-olcu#7','riyaziyyat','riy-2-olcu',3,3,'70 sm və 7 dm uzunluqlarını müqayisə edin.','7 dm = 70 sm — bərabərdirlər.',array['Bərabərdirlər','70 sm uzundur','7 dm uzundur','Müqayisə etmək olmaz'],1),
('riy2-olcu#8','riyaziyyat','riy-2-olcu',2,3,'Qapının hündürlüyünü hansı vahidlə ölçmək əlverişlidir?','Böyük uzunluqlar metrlə ölçülür.',array['Metrlə','Santimetrlə','Litrlə','Kiloqramla'],1),
('riy2-olcu#9','riyaziyyat','riy-2-olcu',3,3,'Hansı daha ağırdır: 1 kq dəmir, yoxsa 1 kq pambıq?','Hər ikisi 1 kq-dır — kütlələri bərabərdir.',array['Bərabərdirlər','Dəmir','Pambıq','Bilmək olmaz'],1),
('riy2-olcu#10','riyaziyyat','riy-2-olcu',3,3,'50 sm + 50 sm birlikdə neçə metr edir?','50 + 50 = 100 sm = 1 m.',array['1 m','10 m','100 m','55 m'],1),
('riy2-fiqurlar#1','riyaziyyat','riy-2-fiqurlar',2,4,'Düzbucaqlının qarşı tərəfləri necədir?','Düzbucaqlıda qarşı tərəflər bərabərdir.',array['Bərabərdir','Fərqlidir','Əyridir','Yoxdur'],1),
('riy2-fiqurlar#2','riyaziyyat','riy-2-fiqurlar',2,4,'Üçbucağın tərəflərinin sayı ilə təpələrinin sayı necədir?','Hər ikisi 3-dür — bərabərdir.',array['Bərabərdir — 3 və 3','Tərəf çoxdur','Təpə çoxdur','Tərəfi yoxdur'],1),
('riy2-fiqurlar#3','riyaziyyat','riy-2-fiqurlar',1,4,'Hansı fiqurun 4 təpəsi var?','Kvadratın 4 təpəsi var.',array['Kvadratın','Üçbucağın','Dairənin','Ovalın'],1),
('riy2-fiqurlar#4','riyaziyyat','riy-2-fiqurlar',3,4,'Kubu kvadratdan nə fərqləndirir?','Kub fəza fiqurudur, kvadrat müstəvi fiqurdur.',array['Kub fəza fiqurudur','Kub daha kiçikdir','Kvadratın üzləri var','Heç nə'],1),
('riy2-fiqurlar#5','riyaziyyat','riy-2-fiqurlar',2,4,'Konserv bankası hansı fəza fiquruna bənzəyir?','Banka silindr formasındadır.',array['Silindrə','Kuba','Konusa','Piramidaya'],1),
('riy2-fiqurlar#6','riyaziyyat','riy-2-fiqurlar',3,4,'Kəpənəyin açılmış qanadları bir-birinə görə necədir?','Qanadlar güzgüdəki kimi eynidir — simmetrikdir.',array['Simmetrikdir','Tamam fərqlidir','Biri yumrudur','Müqayisə olunmur'],1),
('riy2-fiqurlar#7','riyaziyyat','riy-2-fiqurlar',2,4,'Dairə və kürədən hansı müstəvi fiqurdur?','Dairə müstəvi, kürə fəza fiqurudur.',array['Dairə','Kürə','Hər ikisi','Heç biri'],1),
('riy2-fiqurlar#8','riyaziyyat','riy-2-fiqurlar',1,4,'Altıbucaqlının neçə tərəfi var?','Altıbucaqlının 6 tərəfi var.',array['6','5','8','3'],1),
('riy2-fiqurlar#9','riyaziyyat','riy-2-fiqurlar',1,4,'Yumurta hansı fiqura bənzəyir?','Yumurta oval formadadır.',array['Ovala','Kvadrata','Üçbucağa','Düzbucaqlıya'],1),
('riy2-fiqurlar#10','riyaziyyat','riy-2-fiqurlar',2,4,'Sınıq xətt nələrdən ibarətdir?','Sınıq xətt bir-birinə birləşən parçalardan ibarətdir.',array['Parçalardan','Dairələrdən','Nöqtələrsiz əyridən','Kürələrdən'],1),
('riy2-mesele#1','riyaziyyat','riy-2-mesele',1,4,'Rəfdə 45 kitab var idi. 12 kitab götürüldü. Rəfdə neçə kitab qaldı?','45 − 12 = 33.',array['33','34','57','43'],1),
('riy2-mesele#2','riyaziyyat','riy-2-mesele',2,4,'Bir boşqabda 5 peçenye var. 3 belə boşqabda birlikdə neçə peçenye var?','5 × 3 = 15.',array['15','8','10','35'],1),
('riy2-mesele#3','riyaziyyat','riy-2-mesele',2,4,'Aysu 27 səhifə oxudu, Tural ondan 5 səhifə az oxudu. Tural neçə səhifə oxudu?','«5 az» — çıxma deməkdir: 27 − 5 = 22.',array['22','32','23','5'],1),
('riy2-mesele#4','riyaziyyat','riy-2-mesele',3,4,'Lalənin 6 qələmi var. Nihadın qələmləri ondan 2 dəfə çoxdur. Nihadın neçə qələmi var?','«2 dəfə çox» — vurma deməkdir: 6 × 2 = 12.',array['12','8','4','62'],1),
('riy2-mesele#5','riyaziyyat','riy-2-mesele',2,4,'Ana 16 konfeti 2 qardaşa bərabər payladı. Hər birinə neçə konfet düşdü?','16 : 2 = 8.',array['8','14','18','32'],1),
('riy2-mesele#6','riyaziyyat','riy-2-mesele',3,4,'Avtobusda 24 sərnişin var idi. 8 nəfər düşdü, 5 nəfər mindi. İndi avtobusda neçə sərnişin var?','24 − 8 = 16; 16 + 5 = 21.',array['21','11','27','16'],1),
('riy2-mesele#7','riyaziyyat','riy-2-mesele',1,4,'Bir dondurma 1 manatdır. 5 dondurma neçə manatdır?','1 × 5 = 5 manat.',array['5 manat','6 manat','1 manat','4 manat'],1),
('riy2-mesele#8','riyaziyyat','riy-2-mesele',1,4,'Sinifdə 14 oğlan və 13 qız oxuyur. Sinifdə cəmi neçə şagird var?','14 + 13 = 27.',array['27','26','1','28'],1),
('riy2-mesele#9','riyaziyyat','riy-2-mesele',2,4,'Nərminin 90 qəpiyi var idi. 40 qəpiyə çörək aldı. Neçə qəpiyi qaldı?','90 − 40 = 50 qəpik.',array['50 qəpik','40 qəpik','60 qəpik','130 qəpik'],1),
('riy2-mesele#10','riyaziyyat','riy-2-mesele',1,4,'Hovuzda 9 ördək üzürdü. Daha 7 ördək gəldi. Hovuzda neçə ördək oldu?','9 + 7 = 16.',array['16','15','2','17'],1),
('az2-soz-novleri#1','az-dili','az-2-soz-novleri',2,1,'Sözlər mənasına görə hansı qruplara bölünür?','Ad, əlamət və hərəkət bildirən sözlərə bölünür.',array['Ad, əlamət, hərəkət bildirən sözlərə','Qısa və uzun sözlərə','Böyük və kiçik sözlərə','Asan və çətin sözlərə'],1),
('az2-soz-novleri#2','az-dili','az-2-soz-novleri',1,1,'«Dovşan» sözü hansı qrupa aiddir?','Dovşan heyvanın adıdır — ad bildirən sözdür.',array['Ad bildirən','Əlamət bildirən','Hərəkət bildirən','Heç birinə'],1),
('az2-soz-novleri#3','az-dili','az-2-soz-novleri',1,1,'«Yumşaq» sözü nə bildirir?','Yumşaq əşyanın əlamətidir.',array['Əlamət','Ad','Hərəkət','Say'],1),
('az2-soz-novleri#4','az-dili','az-2-soz-novleri',1,1,'«Tullanır» sözü nə bildirir?','Tullanmaq hərəkətdir.',array['Hərəkət','Ad','Əlamət','Yer'],1),
('az2-soz-novleri#5','az-dili','az-2-soz-novleri',2,1,'«Kim?» sualına hansı sözlər cavab verir?','İnsan bildirən adlar «kim?» sualına cavab verir.',array['İnsan bildirən adlar','Əşya bildirən adlar','Əlamət bildirən sözlər','Hərəkət bildirən sözlər'],1),
('az2-soz-novleri#6','az-dili','az-2-soz-novleri',3,1,'«Quş — balaca — uçur» sırasında sözlər hansı qaydada düzülüb?','Quş — ad, balaca — əlamət, uçur — hərəkət.',array['Ad, əlamət, hərəkət','Hərəkət, ad, əlamət','Əlamət, ad, hərəkət','Ad, hərəkət, əlamət'],1),
('az2-soz-novleri#7','az-dili','az-2-soz-novleri',2,1,'Cansız əşyanın adına hansı sual verilir?','Əşyalara «nə?» sualı verilir.',array['Nə?','Kim?','Necə?','Nə edir?'],1),
('az2-soz-novleri#8','az-dili','az-2-soz-novleri',2,1,'«Şirin, turş, duzlu» sözləri nəyi bildirir?','Bu sözlər dadı — əşyanın əlamətini bildirir.',array['Dadı (əlaməti)','Əşyanın adını','Hərəkəti','Sayı'],1),
('az2-soz-novleri#9','az-dili','az-2-soz-novleri',1,1,'«Oxuyur» sözünə hansı sualı veririk?','Hərəkət bildirən sözlərə «nə edir?» sualı verilir.',array['Nə edir?','Kim?','Necə?','Neçə?'],1),
('az2-soz-novleri#10','az-dili','az-2-soz-novleri',2,1,'«Bakı, kitab, quş» sözlərini birləşdirən cəhət nədir?','Üçü də addır — ad bildirən sözlərdir.',array['Hamısı ad bildirir','Hamısı əlamət bildirir','Hamısı hərəkət bildirir','Ümumi cəhətləri yoxdur'],1),
('az2-ad-bildiren#1','az-dili','az-2-ad-bildiren',1,1,'Ad bildirən sözlər nəyi göstərir?','İnsanların və əşyaların adını göstərir.',array['İnsan və əşyaların adını','Yalnız rəngi','Yalnız hərəkəti','Yalnız sayı'],1),
('az2-ad-bildiren#2','az-dili','az-2-ad-bildiren',1,1,'Hansı söz əşyanın adıdır?','Stol əşyadır; qırmızı — əlamət, yazır — hərəkətdir.',array['stol','qırmızı','yazır','tez'],1),
('az2-ad-bildiren#3','az-dili','az-2-ad-bildiren',1,1,'İnsan bildirən ada hansı sual verilir?','İnsanlara «kim?» sualı verilir.',array['Kim?','Nə?','Necə?','Hara?'],1),
('az2-ad-bildiren#4','az-dili','az-2-ad-bildiren',2,1,'«Nə?» sualına cavab verən sözü seçin.','Dəftər əşyadır — «nə?» sualına cavab verir.',array['dəftər','uca','gülür','yavaş'],1),
('az2-ad-bildiren#5','az-dili','az-2-ad-bildiren',2,1,'Hansı cərgədə yalnız ad bildirən sözlər var?','Çanta, qayçı, güzgü — hamısı əşya adıdır.',array['çanta, qayçı, güzgü','çanta, təzə, kəsir','qayçı, iti, parlaq','güzgü, baxır, hamar'],1),
('az2-ad-bildiren#6','az-dili','az-2-ad-bildiren',2,1,'«Həkim» sözü nəyi bildirir?','Həkim peşə sahibidir — insanı bildirir.',array['Peşə sahibini (insanı)','Əşyanı','Əlaməti','Hərəkəti'],1),
('az2-ad-bildiren#7','az-dili','az-2-ad-bildiren',2,1,'Şəhər adları hansı qrupa daxildir?','Şəhər adları da ad bildirən sözlərdir.',array['Ad bildirən sözlərə','Əlamət bildirən sözlərə','Hərəkət bildirən sözlərə','Heç bir qrupa'],1),
('az2-ad-bildiren#8','az-dili','az-2-ad-bildiren',3,1,'«Çay» sözü neçə mənada işlənə bilər?','Çay həm içki, həm də axar su mənasında işlənir.',array['İki mənada','Yalnız bir mənada','Heç bir mənada','Yalnız ad kimi işlənmir'],1),
('az2-ad-bildiren#9','az-dili','az-2-ad-bildiren',2,1,'«Quzular» sözü neçə quzunu bildirir?','-lar şəkilçisi çoxluq bildirir: birdən çox.',array['Birdən çox','Yalnız bir','Heç bir','Yalnız iki'],1),
('az2-ad-bildiren#10','az-dili','az-2-ad-bildiren',3,1,'Hansı söz insan adı DEYİL?','Alma meyvədir; Lalə, Samir, Aygün insan adlarıdır.',array['alma','Lalə','Samir','Aygün'],1),
('az2-elamet#1','az-dili','az-2-elamet',2,2,'Əlamət bildirən sözlər əşyanın nəyini göstərir?','Rəngini, dadını, formasını, ölçüsünü göstərir.',array['Rəngini, dadını, formasını','Yalnız adını','Yalnız hərəkətini','Yalnız sayını'],1),
('az2-elamet#2','az-dili','az-2-elamet',2,2,'«Cavan» və «qoca» sözləri bir-birinə görə necədir?','Bu sözlər əks mənalıdır.',array['Əks mənalıdır','Eyni mənalıdır','Hər ikisi addır','Hər ikisi hərəkətdir'],1),
('az2-elamet#3','az-dili','az-2-elamet',3,2,'Alma haqqında hansı söz əlamət bildirMİR?','«Yeyilir» hərəkətdir; şirin, qırmızı, yumru əlamətdir.',array['yeyilir','şirin','qırmızı','yumru'],1),
('az2-elamet#4','az-dili','az-2-elamet',1,2,'«Hündür» sözü hansı suala cavab verir?','Əlamət bildirən sözlərə «necə?» sualı verilir.',array['Necə?','Kim?','Nə edir?','Hara?'],1),
('az2-elamet#5','az-dili','az-2-elamet',2,2,'Hansı cərgədə yalnız əlamət bildirən sözlər var?','Geniş, təmiz, şirin — hamısı əlamətdir.',array['geniş, təmiz, şirin','geniş, otaq, təmiz','şirin, bal, arı','təmiz, yuyur, su'],1),
('az2-elamet#6','az-dili','az-2-elamet',1,2,'«Dərin göl» ifadəsində hansı söz əlamət bildirir?','Göl necədir? — dərin.',array['dərin','göl','hər ikisi','heç biri'],1),
('az2-elamet#7','az-dili','az-2-elamet',1,2,'Qarın rəngini bildirən söz hansıdır?','Qar ağ rəngdədir.',array['ağ','soyuq','yağır','qış'],1),
('az2-elamet#8','az-dili','az-2-elamet',2,2,'«Ağır» sözünün əksi hansı sözdür?','Ağırın əksi yüngüldür.',array['yüngül','böyük','bərk','hündür'],1),
('az2-elamet#9','az-dili','az-2-elamet',3,2,'Əşyanı dəqiq təsvir etmək üçün hansı sözlərdən istifadə olunur?','Əlamət bildirən sözlər təsviri dəqiqləşdirir.',array['Əlamət bildirən sözlərdən','Yalnız adlardan','Yalnız hərəkət sözlərindən','Saylardan'],1),
('az2-elamet#10','az-dili','az-2-elamet',1,2,'«Dadlı» sözü əşyanın hansı əlamətini bildirir?','Dadlı — dad əlamətidir.',array['Dadını','Rəngini','Formasını','Ölçüsünü'],1),
('az2-hereket#1','az-dili','az-2-hereket',1,2,'Hərəkət bildirən sözlər hansı suala cavab verir?','Hərəkət bildirən sözlərə «nə edir?» sualı verilir.',array['Nə edir?','Necə?','Kim?','Hansı?'],1),
('az2-hereket#2','az-dili','az-2-hereket',1,2,'Hansı söz hərəkət bildirir?','Qaçır — hərəkətdir.',array['qaçır','sürətli','yol','idmançı'],1),
('az2-hereket#3','az-dili','az-2-hereket',2,2,'«Yarpaq yerə düşdü» cümləsində hərəkət bildirən söz hansıdır?','Yarpaq nə etdi? — düşdü.',array['düşdü','yarpaq','yerə','cümlədə belə söz yoxdur'],1),
('az2-hereket#4','az-dili','az-2-hereket',2,2,'Hansı cərgədə yalnız hərəkət bildirən sözlər var?','Yazır, oxuyur, çəkir — hamısı hərəkətdir.',array['yazır, oxuyur, çəkir','yazır, qələm, dəftər','oxuyur, kitab, maraqlı','çəkir, şəkil, rəngli'],1),
('az2-hereket#5','az-dili','az-2-hereket',2,2,'«Gəldi» sözünün əks mənalısı hansıdır?','Gəlmək ↔ getmək.',array['getdi','çatdı','yaxınlaşdı','dayandı'],1),
('az2-hereket#6','az-dili','az-2-hereket',1,2,'Hansı söz «balıq» sözünə uyğun hərəkətdir?','Balıq suda üzür.',array['üzür','uçur','qaçır','oxuyur'],1),
('az2-hereket#7','az-dili','az-2-hereket',1,2,'«Danışır» sözü nəyi bildirir?','Danışmaq hərəkətdir.',array['Hərəkəti','Əşyanın adını','Əlaməti','Rəngi'],1),
('az2-hereket#8','az-dili','az-2-hereket',2,2,'«Aşpaz yemək …» — nöqtələrin yerinə hansı söz uyğundur?','Aşpaz yemək bişirir.',array['bişirir','dadlı','mətbəx','qazan'],1),
('az2-hereket#9','az-dili','az-2-hereket',3,2,'Hansı söz hərəkət bildirMİR?','«Gözəl» əlamətdir; baxır, gülür, yazır hərəkətdir.',array['gözəl','baxır','gülür','yazır'],1),
('az2-hereket#10','az-dili','az-2-hereket',2,2,'«Top yuvarlanır» cümləsində hərəkəti edən nədir?','Yuvarlanan topdur.',array['Top','Yuvarlanır','Cümlə','Heç nə'],1),
('az2-cumle-novleri#1','az-dili','az-2-cumle-novleri',2,3,'Məlumat vermək üçün işlədilən cümlə necə adlanır?','Məlumat bildirən cümlə nəqli cümlədir.',array['Nəqli cümlə','Sual cümləsi','Nida cümləsi','Söz birləşməsi'],1),
('az2-cumle-novleri#2','az-dili','az-2-cumle-novleri',1,3,'«Sən neçənci sinifdə oxuyursan?» — bu hansı cümlədir?','Sual verilir — sual cümləsidir.',array['Sual cümləsi','Nəqli cümlə','Nida cümləsi','Cümlə deyil'],1),
('az2-cumle-novleri#3','az-dili','az-2-cumle-novleri',2,3,'Nida cümləsi nəyi ifadə edir?','Sevinc, təəccüb kimi güclü hissləri bildirir.',array['Güclü hissləri','Adi məlumatı','Yalnız sualı','Heç nəyi'],1),
('az2-cumle-novleri#4','az-dili','az-2-cumle-novleri',2,3,'«Yaşasın Azərbaycan!» cümləsinin sonunda hansı işarə qoyulub?','Hiss bildirən cümlənin sonunda nida işarəsi olur.',array['Nida işarəsi','Nöqtə','Sual işarəsi','Vergül'],1),
('az2-cumle-novleri#5','az-dili','az-2-cumle-novleri',1,3,'Sual cümləsini seçin.','«Hara gedirsən?» — sual verilir.',array['Hara gedirsən?','Hava istidir.','Nə gözəl çiçək!','Kitabı oxudum.'],1),
('az2-cumle-novleri#6','az-dili','az-2-cumle-novleri',2,3,'«Payız gəldi.» cümləsinin növü hansıdır?','Adi məlumat verilir — nəqli cümlədir.',array['Nəqli','Sual','Nida','Əmr'],1),
('az2-cumle-novleri#7','az-dili','az-2-cumle-novleri',2,3,'Hansı cümlə sevinc hissi bildirir?','«Nə gözəl gün!» — sevinc ifadə edir.',array['Nə gözəl gün!','Bu gün hava necədir?','Dərs saat 9-da başlayır.','Kitab stolun üstündədir.'],1),
('az2-cumle-novleri#8','az-dili','az-2-cumle-novleri',2,3,'Sual cümlələrində çox vaxt hansı sözlər işlənir?','Kim, nə, hara, nə vaxt sual sözləridir.',array['kim, nə, hara, nə vaxt','gözəl, şirin, dadlı','gəldi, getdi, gördü','bir, iki, üç'],1),
('az2-cumle-novleri#9','az-dili','az-2-cumle-novleri',3,3,'«Qapını bağla» cümləsi nəyi bildirir?','Bu cümlə əmr və ya xahiş bildirir.',array['Əmr və ya xahişi','Adi məlumatı','Sualı','Təəccübü'],1),
('az2-cumle-novleri#10','az-dili','az-2-cumle-novleri',2,3,'Cümlənin üç əsas növünü sadalayın.','Cümlələr nəqli, sual və nida cümlələrinə bölünür.',array['Nəqli, sual, nida','Uzun, qısa, orta','Asan, çətin, qarışıq','Birinci, ikinci, üçüncü'],1),
('az2-durgu#1','az-dili','az-2-durgu',1,3,'Nöqtə hansı cümlənin sonunda qoyulur?','Nəqli cümlə nöqtə ilə bitir.',array['Nəqli cümlənin','Sual cümləsinin','Nida cümləsinin','Heç birinin'],1),
('az2-durgu#2','az-dili','az-2-durgu',1,3,'Sual işarəsi nə vaxt işlədilir?','Cümlədə sual veriləndə sonda sual işarəsi qoyulur.',array['Sual veriləndə','Sevinc bildiriləndə','Sadalama olanda','Heç vaxt'],1),
('az2-durgu#3','az-dili','az-2-durgu',2,3,'Sadalanan sözlərin arasına hansı işarə qoyulur?','Sadalamada vergül işlənir.',array['Vergül','Nöqtə','Nida işarəsi','Sual işarəsi'],1),
('az2-durgu#4','az-dili','az-2-durgu',2,3,'«Bazardan alma armud üzüm aldıq» cümləsində hansı işarələr çatışmır?','Sadalanan sözlərin arasına vergül qoyulmalıdır.',array['Vergüllər','Nöqtələr','Sual işarələri','Heç nə çatışmır'],1),
('az2-durgu#5','az-dili','az-2-durgu',3,3,'Nida işarəsi hansı cümlədə düzgün işlənib?','«Ura, qar yağdı!» — sevinc bildirir.',array['Ura, qar yağdı!','Bu gün bazar günüdür!','Sən haralısan!','Kitab masanın üstündədir!'],1),
('az2-durgu#6','az-dili','az-2-durgu',1,3,'Hansı işarə cümlənin bitdiyini göstərir?','Nöqtə cümlənin sonunu bildirir.',array['Nöqtə','Vergül','Defis','Dırnaq'],1),
('az2-durgu#7','az-dili','az-2-durgu',2,3,'«Sabah hava necə olacaq» — cümlənin sonuna nə qoyulmalıdır?','Sual verilir — sual işarəsi qoyulur.',array['Sual işarəsi','Nöqtə','Nida işarəsi','Vergül'],1),
('az2-durgu#8','az-dili','az-2-durgu',2,3,'Durğu işarələri nə üçün lazımdır?','Fikri düzgün, aydın çatdırmaq üçün.',array['Fikri aydın çatdırmaq üçün','Yazını uzatmaq üçün','Bəzək üçün','Heç nə üçün'],1),
('az2-durgu#9','az-dili','az-2-durgu',2,3,'Hansı sırada yalnız durğu işarələri sadalanıb?','Nöqtə, vergül, sual işarəsi — durğu işarələridir.',array['nöqtə, vergül, sual işarəsi','hərf, heca, söz','ad, əlamət, hərəkət','sait, samit, heca'],1),
('az2-durgu#10','az-dili','az-2-durgu',3,3,'«Əhməd, kitabı mənə ver» cümləsində vergül nəyi ayırır?','Vergül müraciət olunan şəxsin adını ayırır.',array['Müraciəti (çağırışı)','Sadalamanı','Cümlənin sonunu','Sualı'],1),
('az2-yazi-qaydasi#1','az-dili','az-2-yazi-qaydasi',2,4,'Sözün düzgün yazılışını seçin.','Düzgün yazılış: çörək.',array['çörək','çorək','çörəg','cörək'],1),
('az2-yazi-qaydasi#2','az-dili','az-2-yazi-qaydasi',2,4,'Şəxs adları ilə yanaşı daha hansı adlar böyük hərflə yazılır?','Şəhər, kənd, çay adları da böyük hərflə yazılır.',array['Şəhər və kənd adları','Meyvə adları','Rəng adları','Heç bir ad'],1),
('az2-yazi-qaydasi#3','az-dili','az-2-yazi-qaydasi',2,4,'Sətrin sonuna sığmayan sözü nəyə görə bölürük?','Söz yalnız hecalara görə bölünüb keçirilir.',array['Hecalara görə','Hərflərə görə','İstənilən yerdən','Saitlərinə görə yox, təsadüfi'],1),
('az2-yazi-qaydasi#4','az-dili','az-2-yazi-qaydasi',3,4,'Həftə günlərinin adları (bazar ertəsi, cümə…) necə yazılır?','Həftə günlərinin adları kiçik hərflə yazılır.',array['Kiçik hərflə','Böyük hərflə','Dırnaqda','Rəqəmlə'],1),
('az2-yazi-qaydasi#5','az-dili','az-2-yazi-qaydasi',2,4,'«Günəşli» sözü hansı sözdən yaranıb?','Günəş sözünə -li şəkilçisi artırılıb.',array['günəş','gün','şəkil','işıq'],1),
('az2-yazi-qaydasi#6','az-dili','az-2-yazi-qaydasi',2,4,'Hansı söz böyük hərflə yazılmalıdır: (xəzər) dənizi?','Xəzər dənizin xüsusi adıdır.',array['Xəzər','dənizi','hər ikisi kiçik','heç biri'],1),
('az2-yazi-qaydasi#7','az-dili','az-2-yazi-qaydasi',2,4,'«məktəbə gedirəm» sözləri cümlə kimi yazılanda nə dəyişməlidir?','Cümlə böyük hərflə başlar, sonda nöqtə qoyular.',array['Baş hərf böyük olmalı, sonda nöqtə qoyulmalı','Heç nə dəyişməməli','Bütün hərflər böyük olmalı','Sözlər bitişik yazılmalı'],1),
('az2-yazi-qaydasi#8','az-dili','az-2-yazi-qaydasi',1,4,'«Nənə» sözündə neçə «n» hərfi var?','N-ə-n-ə: iki n hərfi.',array['2','1','3','4'],1),
('az2-yazi-qaydasi#9','az-dili','az-2-yazi-qaydasi',1,4,'Vərəqdə yazıya haradan başlayırıq?','Yazı soldan sağa yazılır.',array['Soldan sağa','Sağdan sola','Aşağıdan yuxarı','Ortadan'],1),
('az2-yazi-qaydasi#10','az-dili','az-2-yazi-qaydasi',3,4,'Hansı say qoşa samitlə yazılır?','«Yeddi» sözündə qoşa d samiti var.',array['yeddi','altı','beş','on'],1),
('hey2-men-mektebim#1','hayat-bilgisi','hey-2-men-mektebim',1,1,'Sinif otağının təmizliyinə kim cavabdehdir?','Sinfin səliqəsi bütün şagirdlərin işidir.',array['Bütün şagirdlər','Yalnız növbətçi','Yalnız müəllim','Heç kim'],1),
('hey2-men-mektebim#2','hayat-bilgisi','hey-2-men-mektebim',1,1,'Dərs zamanı müəllimi necə dinləməliyik?','Müəllimi diqqətlə, sözünü kəsmədən dinləmək lazımdır.',array['Diqqətlə','Yataraq','Danışa-danışa','Oynayaraq'],1),
('hey2-men-mektebim#3','hayat-bilgisi','hey-2-men-mektebim',1,1,'Dərs üçün hansı ləvazimatlar lazımdır?','Kitab, dəftər, qələm əsas dərs ləvazimatlarıdır.',array['Kitab, dəftər, qələm','Top və ip','Oyuncaqlar','Telefon və planşet'],1),
('hey2-men-mektebim#4','hayat-bilgisi','hey-2-men-mektebim',2,1,'Növbətçi şagird nə edir?','Növbətçi sinfin səliqəsinə və lövhəyə baxır.',array['Sinfin səliqəsinə baxır','Dərs keçir','Qiymət yazır','Evə tez gedir'],1),
('hey2-men-mektebim#5','hayat-bilgisi','hey-2-men-mektebim',2,1,'Tənəffüsdə özümüzü necə aparmalıyıq?','Qaçmadan, başqalarına mane olmadan istirahət etməliyik.',array['Mədəni, başqalarına mane olmadan','Dəhlizdə qaçaraq','Qışqıraraq','İtələşərək'],1),
('hey2-men-mektebim#6','hayat-bilgisi','hey-2-men-mektebim',2,1,'Kitabxanadan götürülən kitabla necə davranmalıyıq?','Kitabı səliqəli saxlayıb vaxtında qaytarmaq lazımdır.',array['Səliqəli saxlayıb vaxtında qaytarmalıyıq','Səhifələrini qatlamalıyıq','Üstündə şəkil çəkməliyik','Qaytarmamalıyıq'],1),
('hey2-men-mektebim#7','hayat-bilgisi','hey-2-men-mektebim',2,1,'Dərs cədvəli nəyi göstərir?','Hansı gün hansı dərslərin olacağını göstərir.',array['Günlər üzrə dərsləri','Hava proqnozunu','Yemək siyahısını','Qiymətləri'],1),
('hey2-men-mektebim#8','hayat-bilgisi','hey-2-men-mektebim',1,1,'Yoldaşın dərsi başa düşmürsə, nə etməlisən?','Yoldaşa kömək etmək dostluğun əlamətidir.',array['Kömək etməliyəm','Gülməliyəm','Müəllimə şikayət etməliyəm','Fikir verməməliyəm'],1),
('hey2-men-mektebim#9','hayat-bilgisi','hey-2-men-mektebim',2,1,'İnsanlar bir-birindən nə ilə fərqlənir?','Görkəmi, xasiyyəti, maraqları ilə fərqlənir.',array['Görkəmi və xasiyyəti ilə','Heç nə ilə','Yalnız adı ilə','Yalnız yaşı ilə'],1),
('hey2-men-mektebim#10','hayat-bilgisi','hey-2-men-mektebim',2,1,'Birlikdə iş görəndə nəyə əməl etməliyik?','İşi bölüşdürüb bir-birimizi dinləməliyik.',array['Bir-birimizi dinləməliyik','Hərə öz bildiyini etməlidir','Yalnız bir nəfər işləməlidir','Mübahisə etməliyik'],1),
('hey2-deyerler#1','hayat-bilgisi','hey-2-deyerler',2,1,'Dövlətimizin rəmzləri hansılardır?','Bayraq, gerb və himn dövlət rəmzləridir.',array['Bayraq, gerb, himn','Kitab, qələm, dəftər','Dağ, çay, meşə','Ev, məktəb, bağça'],1),
('hey2-deyerler#2','hayat-bilgisi','hey-2-deyerler',2,1,'Dövlət himni səslənəndə nə etməliyik?','Himn səslənəndə ayağa qalxıb hörmətlə dinləmək lazımdır.',array['Ayağa qalxıb dinləməliyik','Oturub danışmalıyıq','Gülməliyik','Otaqdan çıxmalıyıq'],1),
('hey2-deyerler#3','hayat-bilgisi','hey-2-deyerler',1,1,'Düzgünlük (doğruçuluq) nə deməkdir?','Doğruçuluq yalan danışmamaq deməkdir.',array['Yalan danışmamaq','Çox danışmaq','Sirr saxlamamaq','Tez qaçmaq'],1),
('hey2-deyerler#4','hayat-bilgisi','hey-2-deyerler',2,1,'Verdiyin sözü tutmaq nəyin əlamətidir?','Sözünə əməl edən adam etibarlıdır.',array['Etibarlılığın','Qorxaqlığın','Tənbəlliyin','Paxıllığın'],1),
('hey2-deyerler#5','hayat-bilgisi','hey-2-deyerler',3,1,'Hər uşağın hansı hüququ var?','Hər uşağın oxumaq (təhsil almaq) hüququ var.',array['Təhsil almaq hüququ','Başqasını incitmək hüququ','Qaydaları pozmaq hüququ','Heç bir hüququ yoxdur'],1),
('hey2-deyerler#6','hayat-bilgisi','hey-2-deyerler',2,1,'Yalan danışmaq nəyə gətirib çıxarır?','Yalançıya bir daha inanmırlar — etibar itir.',array['Etibarın itməsinə','Dostluğun möhkəmlənməsinə','Hörmətin artmasına','Heç nəyə'],1),
('hey2-deyerler#7','hayat-bilgisi','hey-2-deyerler',2,1,'Sağlam qidalanma necə olmalıdır?','Qidalar müxtəlif və faydalı olmalıdır.',array['Müxtəlif və faydalı','Yalnız şirniyyatdan ibarət','Yalnız çörəkdən ibarət','Gündə bir dəfə'],1),
('hey2-deyerler#8','hayat-bilgisi','hey-2-deyerler',2,1,'Otağı niyə havalandırırıq?','Təmiz hava sağlamlıq üçün lazımdır.',array['Təmiz hava üçün','Səs-küy üçün','Toz artsın deyə','İşıq gəlsin deyə'],1),
('hey2-deyerler#9','hayat-bilgisi','hey-2-deyerler',1,1,'Başqasının əşyasını icazəsiz götürmək olarmı?','İcazəsiz götürmək olmaz — bu, pis əməldir.',array['Olmaz','Olar','Yalnız gizlicə olar','Yalnız oyuncaqları olar'],1),
('hey2-deyerler#10','hayat-bilgisi','hey-2-deyerler',1,1,'Xəstələnəndə kimə müraciət edirik?','Xəstəni həkim müalicə edir.',array['Həkimə','Sürücüyə','Satıcıya','Rəssama'],1),
('hey2-materiallar#1','hayat-bilgisi','hey-2-materiallar',2,2,'Hansı material təbii materialdır?','Daş təbiətdə hazır şəkildə var; şüşə, plastik, kağız insan əməyi ilə alınır.',array['Daş','Şüşə','Plastik','Kağız'],1),
('hey2-materiallar#2','hayat-bilgisi','hey-2-materiallar',2,2,'Dəmir əşyalar hansı xassəyə malikdir?','Dəmir bərk və möhkəmdir.',array['Bərkdir və möhkəmdir','Yumşaqdır','Şəffafdır','Suda əriyir'],1),
('hey2-materiallar#3','hayat-bilgisi','hey-2-materiallar',2,2,'Süngər suya salınanda nə edir?','Süngər suyu hopdurur (canına çəkir).',array['Suyu hopdurur','Suyu itələyir','Suyu dondurur','Suyu qaynadır'],1),
('hey2-materiallar#4','hayat-bilgisi','hey-2-materiallar',2,2,'Plastilindən nə üçün asanlıqla fiqur düzəltmək olur?','Plastilin yumşaqdır və istənilən formanı alır.',array['Yumşaq olduğu üçün','Bərk olduğu üçün','Şəffaf olduğu üçün','Maqnit olduğu üçün'],1),
('hey2-materiallar#5','hayat-bilgisi','hey-2-materiallar',2,2,'Odun yanında hansı material tez alışdığı üçün təhlükəlidir?','Kağız tez alışan materialdır.',array['Kağız','Daş','Dəmir','Şüşə'],1),
('hey2-materiallar#6','hayat-bilgisi','hey-2-materiallar',1,2,'Buz otaq istiliyində nə olur?','Buz istidə əriyib suya çevrilir.',array['Əriyir','Bərkiyir','Böyüyür','Dəyişmir'],1),
('hey2-materiallar#7','hayat-bilgisi','hey-2-materiallar',1,2,'Su donanda nəyə çevrilir?','Soyuqda su buza çevrilir.',array['Buza','Buxara','Duza','Yağa'],1),
('hey2-materiallar#8','hayat-bilgisi','hey-2-materiallar',1,2,'Qayçı ilə işləyərkən nəyə diqqət etməliyik?','İti alətlərlə ehtiyatla işləmək lazımdır.',array['Ehtiyatlı olmağa','Sürətli olmağa','Gözüyumulu işləməyə','Heç nəyə'],1),
('hey2-materiallar#9','hayat-bilgisi','hey-2-materiallar',2,2,'Elektrik cihazlarını kim işə salmalıdır?','Uşaqlar elektrik cihazlarını böyüklərin nəzarəti ilə işlətməlidir.',array['Böyüklər və ya onların nəzarəti ilə uşaqlar','Uşaqlar təkbaşına','Heç kim','Yalnız qonaqlar'],1),
('hey2-materiallar#10','hayat-bilgisi','hey-2-materiallar',3,2,'Dəmir qaşıq suya salınanda nə baş verir?','Dəmir sudan ağırdır — batır.',array['Batır','Üzür','Əriyir','Buxarlanır'],1),
('hey2-yer-kuresi#1','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Hansı göy cismi işıq mənbəyidir?','Günəş özü işıq saçır — işıq mənbəyidir.',array['Günəş','Ay','Yer','Buludlar'],1),
('hey2-yer-kuresi#2','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Süni işıq mənbəyi hansıdır?','Lampanı insan yaradıb — süni mənbədir.',array['Lampa','Günəş','Ulduzlar','İldırım'],1),
('hey2-yer-kuresi#3','hayat-bilgisi','hey-2-yer-kuresi',3,3,'Yer hansı sistemin planetidir?','Yer Günəş sisteminin planetidir.',array['Günəş sisteminin','Ay sisteminin','Ulduz yağışının','Heç bir sistemin'],1),
('hey2-yer-kuresi#4','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Yer kürəsinin səthinin çox hissəsini nə örtür?','Yerin çox hissəsi su ilə örtülüdür.',array['Su','Qum','Meşə','Buz'],1),
('hey2-yer-kuresi#5','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Xəritədə və qlobusda su hansı rənglə göstərilir?','Dənizlər və okeanlar mavi rənglə göstərilir.',array['Mavi','Yaşıl','Qəhvəyi','Qırmızı'],1),
('hey2-yer-kuresi#6','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Yerin quru hissəsində nələr yerləşir?','Quruda dağlar, düzənliklər, meşələr var.',array['Dağlar və düzənliklər','Yalnız okeanlar','Yalnız buludlar','Heç nə'],1),
('hey2-yer-kuresi#7','hayat-bilgisi','hey-2-yer-kuresi',1,3,'Gecə göy üzündə nələri görürük?','Gecə Ay və ulduzlar görünür.',array['Ayı və ulduzları','Günəşi','Göy qurşağını','Heç nəyi'],1),
('hey2-yer-kuresi#8','hayat-bilgisi','hey-2-yer-kuresi',1,3,'Canlılar su olmadan yaşaya bilərmi?','Su bütün canlılar üçün həyat mənbəyidir.',array['Yaşaya bilməz','Yaşayar','Yalnız qışda yaşayar','Yalnız heyvanlar yaşayar'],1),
('hey2-yer-kuresi#9','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Şəhəri kənddən fərqləndirən əsas cəhət nədir?','Şəhərdə çoxmərtəbəli binalar və çoxlu insan olur.',array['Çoxmərtəbəli binalar və çox insan','Təmiz hava','Heyvanların çoxluğu','Bağların çoxluğu'],1),
('hey2-yer-kuresi#10','hayat-bilgisi','hey-2-yer-kuresi',2,3,'Çaylar axıb hara tökülür?','Çaylar dənizlərə və göllərə tökülür.',array['Dənizlərə və göllərə','Dağlara','Buludlara','Quyulara'],1),
('hey2-canlilar#1','hayat-bilgisi','hey-2-canlilar',1,3,'Bitkilər, heyvanlar və insanlar hansı qrupa aiddir?','Hamısı qidalanır, böyüyür, çoxalır — canlıdır.',array['Canlılara','Cansızlara','Əşyalara','Materiallara'],1),
('hey2-canlilar#2','hayat-bilgisi','hey-2-canlilar',1,3,'Bitkinin hansı hissəsi torpağın altında olur?','Kök torpağın altındadır.',array['Kökü','Gövdəsi','Yarpağı','Çiçəyi'],1),
('hey2-canlilar#3','hayat-bilgisi','hey-2-canlilar',2,3,'Toxum əkiləndə ondan nə çıxır?','Toxumdan cücərti çıxıb bitkiyə çevrilir.',array['Cücərti','Daş','Yumurta','Heç nə'],1),
('hey2-canlilar#4','hayat-bilgisi','hey-2-canlilar',1,3,'Hansı heyvan ev heyvanıdır?','İnəyə insan qulluq edir — ev heyvanıdır.',array['İnək','Canavar','Tülkü','Ayı'],1),
('hey2-canlilar#5','hayat-bilgisi','hey-2-canlilar',1,3,'Hansı heyvan vəhşi heyvandır?','Canavar meşədə sərbəst yaşayır.',array['Canavar','İnək','Toyuq','Qoyun'],1),
('hey2-canlilar#6','hayat-bilgisi','hey-2-canlilar',2,3,'Quşların bədəni nə ilə örtülüdür?','Quşların bədənini lələk örtür.',array['Lələklə','Tüklə deyil, pulcuqla','Yalnız dəri ilə','Qabıqla'],1),
('hey2-canlilar#7','hayat-bilgisi','hey-2-canlilar',1,3,'Balıqlar harada yaşayır?','Balıqlar yalnız suda yaşaya bilir.',array['Suda','Meşədə','Səhrada','Yuvada'],1),
('hey2-canlilar#8','hayat-bilgisi','hey-2-canlilar',2,3,'İnəyin balası necə adlanır?','İnəyin balası buzovdur.',array['Buzov','Quzu','Çəpiş','Bala it'],1),
('hey2-canlilar#9','hayat-bilgisi','hey-2-canlilar',2,3,'Bitkinin böyüməsi üçün nə lazımdır?','Bitkiyə işıq, su və hava lazımdır.',array['İşıq, su və hava','Yalnız qaranlıq','Yalnız külək','Musiqi'],1),
('hey2-canlilar#10','hayat-bilgisi','hey-2-canlilar',2,3,'Hansı heyvan qışda yuxuya gedir?','Ayı qış yuxusuna yatır.',array['Ayı','Sərçə','İnək','At'],1),
('hey2-ehtiyat#1','hayat-bilgisi','hey-2-ehtiyat',1,4,'Velosiped sürərkən başımıza nə taxmalıyıq?','Dəbilqə başı zədədən qoruyur.',array['Dəbilqə','Papaq','Heç nə','Yaylıq'],1),
('hey2-ehtiyat#2','hayat-bilgisi','hey-2-ehtiyat',2,4,'Açıq elektrik naqilinə toxunmaq niyə təhlükəlidir?','Cərəyan vura bilər.',array['Cərəyan vurar','Rəngi əlimizə keçər','Soyuqdur','Heç bir təhlükəsi yoxdur'],1),
('hey2-ehtiyat#3','hayat-bilgisi','hey-2-ehtiyat',1,4,'Yol maşınlar üçündür, bəs səki kimlər üçündür?','Səki ilə piyadalar gedir.',array['Piyadalar üçün','Velosipedlər üçün','Maşınlar üçün','Heç kim üçün'],1),
('hey2-ehtiyat#4','hayat-bilgisi','hey-2-ehtiyat',3,4,'Suda batan adamı görən uşaq nə etməlidir?','Özü suya atılmamalı, dərhal böyükləri çağırmalıdır.',array['Böyükləri çağırmalıdır','Özü suya atılmalıdır','Baxıb getməlidir','Şəkil çəkməlidir'],1),
('hey2-ehtiyat#5','hayat-bilgisi','hey-2-ehtiyat',2,4,'Meşədə tapılan naməlum göbələyi yığmaq olarmı?','Naməlum göbələk zəhərli ola bilər.',array['Olmaz — zəhərli ola bilər','Olar','Yalnız yağışdan sonra olar','Yalnız böyük göbələkləri olar'],1),
('hey2-ehtiyat#6','hayat-bilgisi','hey-2-ehtiyat',2,4,'Mağazada azıb ailəsini itirən uşaq nə etməlidir?','Yerindən uzaqlaşmayıb işçidən və ya polisdən kömək istəməlidir.',array['İşçidən və ya polisdən kömək istəməlidir','Ağlayıb qaçmalıdır','Tanımadığı adamla getməlidir','Gizlənməlidir'],1),
('hey2-ehtiyat#7','hayat-bilgisi','hey-2-ehtiyat',1,4,'Kibrit və alışqanla oynamaq nəyə səbəb ola bilər?','Od yanğına səbəb olur.',array['Yanğına','Sevincə','Oyunun maraqlı olmasına','Heç nəyə'],1),
('hey2-ehtiyat#8','hayat-bilgisi','hey-2-ehtiyat',2,4,'Təmizlik vasitələri (kimyəvi maddələr) harada saxlanmalıdır?','Uşaqların əli çatmayan yerdə saxlanmalıdır.',array['Uşaqların əli çatmayan yerdə','Yemək rəfində','Oyuncaqların içində','Stolun üstündə'],1),
('hey2-ehtiyat#9','hayat-bilgisi','hey-2-ehtiyat',3,4,'Bütün təhlükəli hallar üçün vahid çağrı nömrəsi hansıdır?','112 — vahid təcili çağırış nömrəsidir.',array['112','212','911 deyil, 511','100'],1),
('hey2-ehtiyat#10','hayat-bilgisi','hey-2-ehtiyat',2,4,'Kağıza qənaət etmək üçün nə etmək olar?','Vərəqin hər iki üzündən istifadə etmək olar.',array['Vərəqin hər iki üzünə yazmaq','Vərəqləri cırıb atmaq','Təzə dəftər almaq','Heç nə yazmamaq'],1),
('inf2-obyekt#1','informatika','inf-2-obyekt',1,1,'İnformatikada ətrafımızdakı əşya və varlıqlar necə adlanır?','Ətrafımızdakı hər şey obyekt adlanır.',array['Obyekt','Proqram','Rəqəm','Cümlə'],1),
('inf2-obyekt#2','informatika','inf-2-obyekt',2,1,'Obyekti tanımaq üçün nəyi bilmək lazımdır?','Obyekt əlamətləri ilə tanınır.',array['Əlamətlərini','Qiymətini','Yaşını','Səsini'],1),
('inf2-obyekt#3','informatika','inf-2-obyekt',2,1,'Hansı obyekt insan əli ilə yaradılıb?','Evi insan tikir; dağ, çay, ağac təbiət obyektləridir.',array['Ev','Dağ','Çay','Ağac'],1),
('inf2-obyekt#4','informatika','inf-2-obyekt',2,1,'Hansı obyekt təbiət obyektidir?','Çay təbiətdə özü yaranıb.',array['Çay','Stol','Maşın','Telefon'],1),
('inf2-obyekt#5','informatika','inf-2-obyekt',2,1,'«Quş uçur» — burada obyektin nəyi göstərilib?','Uçmaq quşun hərəkətidir.',array['Hərəkəti','Rəngi','Ölçüsü','Qiyməti'],1),
('inf2-obyekt#6','informatika','inf-2-obyekt',2,1,'Obyektləri bir qrupda birləşdirmək üçün onların nəyi olmalıdır?','Qrup oxşar əlamətlərə görə yaradılır.',array['Oxşar əlamətləri','Eyni rəngi olması vacibdir','Eyni qiyməti','Heç nəyi'],1),
('inf2-obyekt#7','informatika','inf-2-obyekt',1,1,'«Alma, armud, gavalı» obyektlərini hansı ad altında birləşdirmək olar?','Üçü də meyvədir.',array['Meyvələr','Tərəvəzlər','Oyuncaqlar','Geyimlər'],1),
('inf2-obyekt#8','informatika','inf-2-obyekt',2,1,'Hansı obyekt «nəqliyyat» qrupuna aid DEYİL?','Ağac bitkidir; avtobus, qatar, gəmi nəqliyyatdır.',array['Ağac','Avtobus','Qatar','Gəmi'],1),
('inf2-obyekt#9','informatika','inf-2-obyekt',3,1,'İki obyekti fərqləndirmək üçün nəyə baxırıq?','Fərqləndirici əlamətlərinə baxırıq.',array['Fərqli əlamətlərinə','Yalnız adlarına','Yalnız yerlərinə','Heç nəyə'],1),
('inf2-obyekt#10','informatika','inf-2-obyekt',3,1,'«Sərçə, qartal, göyərçin» qrupuna daha hansı obyekt uyğundur?','Qrup quşlardan ibarətdir — qaranquş da quşdur.',array['Qaranquş','Kəpənək','Balıq','Dovşan'],1),
('inf2-informasiya#1','informatika','inf-2-informasiya',2,2,'Mətn, şəkil və səs — bunlar nəyin formalarıdır?','İnformasiya mətn, şəkil, səs formasında olur.',array['İnformasiyanın','Oyunun','Əşyanın','Rəngin'],1),
('inf2-informasiya#2','informatika','inf-2-informasiya',1,2,'Kitabdakı yazı hansı formada informasiyadır?','Yazı mətn formasında informasiyadır.',array['Mətn','Səs','Video','Qoxu'],1),
('inf2-informasiya#3','informatika','inf-2-informasiya',2,2,'Dərslikdəki xəritə hansı formada informasiyadır?','Xəritə qrafik (şəkil) informasiyadır.',array['Şəkil (qrafik)','Səs','Mətn','Rəqəm deyil, dad'],1),
('inf2-informasiya#4','informatika','inf-2-informasiya',2,2,'Qədim insanlar məlumatı saxlamaq üçün nəyin üzərinə yazırdılar?','Qədimdə daş və gil lövhələrə yazırdılar.',array['Daş və gil lövhələrə','Kompüterə','Telefona','Televizora'],1),
('inf2-informasiya#5','informatika','inf-2-informasiya',2,2,'Müasir dövrdə informasiya ən çox nə ilə ötürülür?','İndi məlumat telefon və internetlə ötürülür.',array['Telefon və internetlə','Göyərçinlə','Tonqal tüstüsü ilə','Çaparla'],1),
('inf2-informasiya#6','informatika','inf-2-informasiya',2,2,'Yaddaş kartı (fləş kart) nə üçündür?','İnformasiyanı saxlamaq üçün qurğudur.',array['İnformasiyanı saxlamaq üçün','Yemək bişirmək üçün','Şəkil çəkmək üçün','Otağı işıqlandırmaq üçün'],1),
('inf2-informasiya#7','informatika','inf-2-informasiya',3,2,'Şagird kitab oxuyur. O, informasiyanı nə edir?','Oxuyan adam informasiyanı qəbul edir (alır).',array['Qəbul edir','Ötürür','Silir','İtirir'],1),
('inf2-informasiya#8','informatika','inf-2-informasiya',3,2,'Müəllim mövzunu danışır. O, informasiyanı nə edir?','Danışan adam informasiyanı ötürür.',array['Ötürür','Qəbul edir','Saxlayır','Gizlədir'],1),
('inf2-informasiya#9','informatika','inf-2-informasiya',2,2,'Hansı cihazla səsi yazıb saxlamaq olar?','Diktofon (telefonun səsyazması) səsi yazır.',array['Diktofonla','Xətkeşlə','Tərəzi ilə','Qayçı ilə'],1),
('inf2-informasiya#10','informatika','inf-2-informasiya',2,2,'Multfilm hansı informasiya formalarını birləşdirir?','Multfilmdə həm görüntü, həm səs var.',array['Şəkil və səsi','Yalnız mətni','Yalnız qoxunu','Heç birini'],1),
('inf2-alqoritm#1','informatika','inf-2-alqoritm',1,3,'Müəyyən işi görmək üçün addımların ardıcıllığı necə adlanır?','Ardıcıl addımlar alqoritm adlanır.',array['Alqoritm','Cümlə','Oyun','Rəqəm'],1),
('inf2-alqoritm#2','informatika','inf-2-alqoritm',2,3,'Alqoritmin hər bir göstərişi necə adlanır?','Alqoritm addımlardan (əmrlərdən) ibarətdir.',array['Addım (əmr)','Hərf','Səhifə','Şəkil'],1),
('inf2-alqoritm#3','informatika','inf-2-alqoritm',2,3,'Süd içmək alqoritmində ilk addım hansıdır?','Əvvəlcə stəkana süd tökülür, sonra içilir.',array['Stəkana süd tökmək','Stəkanı yumaq','Südü içmək','Stəkanı yerinə qoymaq'],1),
('inf2-alqoritm#4','informatika','inf-2-alqoritm',2,3,'«Sağa dön, 2 addım irəli get» — bunlar nədir?','İcraçıya verilən əmrlərdir.',array['İcraçıya verilən əmrlər','Tapmacalar','Nağıl','Mahnı sözləri'],1),
('inf2-alqoritm#5','informatika','inf-2-alqoritm',2,3,'Robot hansı göstərişləri yerinə yetirir?','Robot yalnız ona verilən əmrləri icra edir.',array['Ona verilən əmrləri','Öz istədiyini','Heç bir göstərişi','Yalnız səsli musiqini'],1),
('inf2-alqoritm#6','informatika','inf-2-alqoritm',2,3,'Alqoritmi yerinə yetirən şəxs və ya qurğu necə adlanır?','Alqoritmi icra edən icraçı adlanır.',array['İcraçı','Tamaşaçı','Müəllif','Rəssam'],1),
('inf2-alqoritm#7','informatika','inf-2-alqoritm',2,3,'«5 böyükdür 3-dən» mülahizəsi necə mülahizədir?','5 həqiqətən 3-dən böyükdür — mülahizə doğrudur.',array['Doğru','Yalan','Qeyri-müəyyən','Sual'],1),
('inf2-alqoritm#8','informatika','inf-2-alqoritm',3,3,'«Sabah yağış yağacaq» mülahizəsi necə mülahizədir?','Sabahkı hava dəqiq bilinmir — mülahizə qeyri-müəyyəndir.',array['Qeyri-müəyyən','Doğru','Yalan','Əmr'],1),
('inf2-alqoritm#9','informatika','inf-2-alqoritm',3,3,'Evdən məktəbə bir neçə yol var. Alqoritm üçün adətən hansı yol seçilir?','Ən qısa və təhlükəsiz yol seçilir.',array['Ən qısa təhlükəsiz yol','Ən uzun yol','Ən dar yol','Təsadüfi yol'],1),
('inf2-alqoritm#10','informatika','inf-2-alqoritm',2,3,'Çanta yığmaq alqoritmi hansı addımla bitir?','Ləvazimat yığılandan sonra çanta bağlanır.',array['Çantanı bağlamaq','Kitabları çıxarmaq','Çantanı açmaq','Dəftər almaq'],1),
('inf2-kompyuter#1','informatika','inf-2-kompyuter',3,4,'Kompüterin «beyni» adlandırılan hissəsi hansıdır?','Prosessor bütün hesablamaları aparır.',array['Prosessor','Monitor','Maus','Naqil'],1),
('inf2-kompyuter#2','informatika','inf-2-kompyuter',2,4,'Skaner nə edir?','Skaner kağızdakı şəkli və yazını kompüterə köçürür.',array['Kağızdakı şəkli kompüterə köçürür','Səs yazır','Mətni kağıza çapır','Otağı işıqlandırır'],1),
('inf2-kompyuter#3','informatika','inf-2-kompyuter',1,4,'Dinamiklər nə üçündür?','Dinamiklər səsi eşitdirir.',array['Səsi eşitdirmək üçün','Şəkil göstərmək üçün','Yazı yazmaq üçün','Kağız kəsmək üçün'],1),
('inf2-kompyuter#4','informatika','inf-2-kompyuter',2,4,'Mikrofon nə üçün istifadə olunur?','Mikrofon səsi kompüterə daxil edir.',array['Səsi kompüterə daxil etmək üçün','Səsi eşitdirmək üçün','Şəkil çəkmək üçün','Mətni silmək üçün'],1),
('inf2-kompyuter#5','informatika','inf-2-kompyuter',3,4,'Kompüter işə düşəndə ekranda açılan əsas görüntü necə adlanır?','Əsas ekran iş masası adlanır.',array['İş masası','Pəncərə deyil, qapı','Kitab səhifəsi','Lövhə'],1),
('inf2-kompyuter#6','informatika','inf-2-kompyuter',2,4,'Kompüterdə şəkil çəkmək üçün hansı proqramdan istifadə olunur?','Şəkil qrafik redaktorda çəkilir.',array['Qrafik redaktordan','Kalkulyatordan','Saatdan','Musiqi pleyerindən'],1),
('inf2-kompyuter#7','informatika','inf-2-kompyuter',3,4,'Mausun sol düyməsini iki dəfə ardıcıl basmaq necə adlanır?','İki ardıcıl basma ikiqat klik adlanır.',array['İkiqat klik','Uzun basma','Sürüşdürmə','Yazma'],1),
('inf2-kompyuter#8','informatika','inf-2-kompyuter',2,4,'Kompüter sinfində hansı qaydaya əməl edilməlidir?','Yaş əllə cihazlara toxunmaq olmaz.',array['Yaş əllə cihaza toxunmamaq','Qaçıb oynamaq','Naqilləri dartmaq','Ekrana barmaqla döymək'],1),
('inf2-kompyuter#9','informatika','inf-2-kompyuter',2,4,'İşi bitirəndə kompüteri necə söndürməliyik?','Kompüter qaydasına uyğun söndürülməlidir.',array['Qaydasına uyğun, düzgün','Naqili dartmaqla','Ekranı örtməklə','Söndürməyə ehtiyac yoxdur'],1),
('inf2-kompyuter#10','informatika','inf-2-kompyuter',3,4,'Gözlərin yorulmaması üçün fasilədə nə etmək faydalıdır?','Ekrandan ayrılıb uzağa baxmaq gözləri dincəldir.',array['Uzağa baxmaq','Ekrana daha yaxın baxmaq','Gözləri ovuşdurub davam etmək','Qaranlıqda oturmaq'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '2'
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
     and (ext_key like 'riy2-%' or ext_key like 'az2-%'
          or ext_key like 'hey2-%' or ext_key like 'inf2-%');
  if n <> 260 then
    raise exception 'sinif2 suallari: 260 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'riy2-%' or q.ext_key like 'az2-%'
          or q.ext_key like 'hey2-%' or q.ext_key like 'inf2-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy2-%' or ext_key like 'az2-%'
      or ext_key like 'hey2-%' or ext_key like 'inf2-%';
  if k <> 26 then
    raise exception 'movzu sayi 26 deyil: %', k;
  end if;
  raise notice '2-ci sinif banki: % sual, 26 movzu (riy, az, hey, inf).', n;
end $$;
