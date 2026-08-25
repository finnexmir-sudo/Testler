-- =====================================================================
--  23_bank_sinif1.sql : 1-CI SINIF PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/sinif1.py yaradir:
--      python3 tools/sinif1.py
--
--  Riyaziyyat 12 + Az dili 6 + Heyat bilgisi 5 + Informatika 4
--  = 27 movzu x 10 = 270.  ext_key: riy1-/az1-/hey1-/inf1-...
--  ON SERT: 14_movzular.sql ve 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('riyaziyyat','riy-1-elamet'),
                                ('az-dili','az-1-heca'),
                                ('hayat-bilgisi','hey-1-etraf-muhit'),
                                ('informatika','inf-1-esyalar'))
     having count(*) = 4) then
    raise exception 'ONCE 14_movzular.sql ve 15_movzular_ederslik.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'riy1-%' or q.ext_key like 'az1-%'
        or q.ext_key like 'hey1-%' or q.ext_key like 'inf1-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('riy1-elamet#1','riyaziyyat','riy-1-elamet',1,1,'Hansı söz əşyanın rəngini bildirir?','Qırmızı rəng adıdır; böyük — ölçü, yumru — forma bildirir.',array['qırmızı','böyük','yumru','ağır'],1),
('riy1-elamet#2','riyaziyyat','riy-1-elamet',1,1,'Top hansı formadadır?','Top yumru formadadır.',array['Yumru','Dördkünc','Uzunsov','Düz'],1),
('riy1-elamet#3','riyaziyyat','riy-1-elamet',2,1,'«Böyük — kiçik» sözləri əşyanın hansı əlamətini bildirir?','Böyük və kiçik əşyanın ölçüsünü göstərir.',array['Ölçüsünü','Rəngini','Dadını','Qoxusunu'],1),
('riy1-elamet#4','riyaziyyat','riy-1-elamet',2,1,'Kitab stolun üstündə, top isə stolun altındadır. Aşağıda hansı əşya yerləşir?','Stolun altı aşağıdır — orada top var.',array['Top','Kitab','Stol','Heç biri'],1),
('riy1-elamet#5','riyaziyyat','riy-1-elamet',1,1,'Limonun dadı necədir?','Limon turş dadlı meyvədir.',array['Turş','Şirin','Duzlu','Dadsız'],1),
('riy1-elamet#6','riyaziyyat','riy-1-elamet',2,1,'Hansı sırada yalnız rəng adları yazılıb?','Sarı, yaşıl, mavi — hamısı rəngdir.',array['sarı, yaşıl, mavi','böyük, kiçik, orta','yumru, uzun, qısa','isti, soyuq, ilıq'],1),
('riy1-elamet#7','riyaziyyat','riy-1-elamet',1,1,'Qar hansı rəngdə olur?','Qar ağ rəngdədir.',array['Ağ','Qara','Yaşıl','Sarı'],1),
('riy1-elamet#8','riyaziyyat','riy-1-elamet',1,1,'Fil siçanla müqayisədə necədir?','Fil siçandan qat-qat böyükdür.',array['Böyükdür','Kiçikdir','Eynidir','Qısadır'],1),
('riy1-elamet#9','riyaziyyat','riy-1-elamet',2,1,'Hansı əşyanın forması dairəyə bənzəyir?','Boşqab dairə formasındadır.',array['Boşqab','Kitab','Qutu','Qapı'],1),
('riy1-elamet#10','riyaziyyat','riy-1-elamet',2,1,'Pambıq daşla müqayisədə necədir?','Pambıq yüngüldür, daş isə ağırdır.',array['Yüngüldür','Ağırdır','Bərkdir','İtidir'],1),
('riy1-ededler-10#1','riyaziyyat','riy-1-ededler-10',1,1,'«Üç» sözü rəqəmlə necə yazılır?','Üç ədədi 3 rəqəmi ilə yazılır.',array['3','2','4','8'],1),
('riy1-ededler-10#2','riyaziyyat','riy-1-ededler-10',1,1,'Sayma zamanı 6-dan sonra hansı ədəd deyilir?','6-dan sonra 7 gəlir.',array['7','5','8','6'],1),
('riy1-ededler-10#3','riyaziyyat','riy-1-ededler-10',1,1,'Sayma zamanı 4-dən əvvəl hansı ədəd deyilir?','4-dən əvvəl 3 gəlir.',array['3','5','2','4'],1),
('riy1-ededler-10#4','riyaziyyat','riy-1-ededler-10',1,1,'Bir əlimizdə neçə barmaq var?','Bir əldə 5 barmaq var.',array['5','10','4','6'],1),
('riy1-ededler-10#5','riyaziyyat','riy-1-ededler-10',2,1,'Heç bir əşyanın olmamasını hansı ədəd göstərir?','Heç nə yoxdursa, sıfır yazılır.',array['0','1','10','5'],1),
('riy1-ededler-10#6','riyaziyyat','riy-1-ededler-10',1,1,'Buraxılmış ədədi tapın: 1, 2, 3, ?, 5.','3-dən sonra 4 gəlir.',array['4','6','3','5'],1),
('riy1-ededler-10#7','riyaziyyat','riy-1-ededler-10',1,1,'«On» sözü rəqəmlə necə yazılır?','On ədədi 1 və 0 rəqəmləri ilə yazılır: 10.',array['10','01','1','100'],1),
('riy1-ededler-10#8','riyaziyyat','riy-1-ededler-10',2,1,'Cərgədə Aysu birincidir, Tural ondan dərhal sonra dayanıb. Tural neçəncidir?','Birincidən sonra ikinci gəlir.',array['İkinci','Birinci','Üçüncü','Beşinci'],1),
('riy1-ededler-10#9','riyaziyyat','riy-1-ededler-10',2,1,'Ən böyük birrəqəmli ədəd hansıdır?','Birrəqəmli ədədlərin ən böyüyü 9-dur.',array['9','10','8','1'],1),
('riy1-ededler-10#10','riyaziyyat','riy-1-ededler-10',1,1,'Səkkiz ədədi hansı rəqəmlə göstərilir?','Səkkiz 8 rəqəmi ilə yazılır.',array['8','9','6','3'],1),
('riy1-muqayise#1','riyaziyyat','riy-1-muqayise',1,1,'5 və 8 ədədlərindən hansı kiçikdir?','5 ədədi 8-dən əvvəl gəlir, deməli kiçikdir.',array['5','8','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-muqayise#2','riyaziyyat','riy-1-muqayise',2,1,'Hansı yazılış doğrudur?','3 ədədi 7-dən kiçikdir: 3 < 7.',array['3 < 7','7 < 3','3 > 7','3 = 7'],1),
('riy1-muqayise#3','riyaziyyat','riy-1-muqayise',2,1,'6 = 6 yazılışı nəyi bildirir?','Bərabərlik işarəsi ədədlərin bərabər olduğunu göstərir.',array['Ədədlər bərabərdir','Soldakı böyükdür','Sağdakı böyükdür','Ədədlər fərqlidir'],1),
('riy1-muqayise#4','riyaziyyat','riy-1-muqayise',2,1,'2, 9, 5 ədədlərini artan sırada düzün.','Kiçikdən böyüyə: 2, 5, 9.',array['2, 5, 9','9, 5, 2','2, 9, 5','5, 2, 9'],1),
('riy1-muqayise#5','riyaziyyat','riy-1-muqayise',3,1,'Ədəd oxunda 4-dən dərhal sağda hansı ədəd durur?','Ədəd oxunda sağa getdikcə ədədlər 1 vahid artır: 5.',array['5','3','6','4'],1),
('riy1-muqayise#6','riyaziyyat','riy-1-muqayise',1,1,'«>» işarəsi necə oxunur?','Açıq tərəf böyük ədədə baxır: böyükdür.',array['Böyükdür','Kiçikdir','Bərabərdir','Toplamaq'],1),
('riy1-muqayise#7','riyaziyyat','riy-1-muqayise',1,1,'Aysunun 7, Turalın 4 konfeti var. Kimin konfeti çoxdur?','7 ədədi 4-dən böyükdür, deməli Aysununku çoxdur.',array['Aysunun','Turalın','Bərabərdir','Bilmək olmaz'],1),
('riy1-muqayise#8','riyaziyyat','riy-1-muqayise',2,1,'6, 3, 8, 5 ədədlərindən ən kiçiyi hansıdır?','Sayma sırasında ən əvvəl 3 gəlir.',array['3','5','6','8'],1),
('riy1-muqayise#9','riyaziyyat','riy-1-muqayise',1,1,'1 və 0 ədədlərindən hansı böyükdür?','1 ədədi 0-dan sonra gəlir, deməli böyükdür.',array['1','0','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-muqayise#10','riyaziyyat','riy-1-muqayise',3,1,'Ədəd oxunda sola getdikcə ədədlər necə dəyişir?','Sola getdikcə ədədlər azalır.',array['Azalır','Artır','Dəyişmir','Gah artır, gah azalır'],1),
('riy1-toplama-10#1','riyaziyyat','riy-1-toplama-10',1,1,'2 + 3 cəmini tapın.','2 + 3 = 5.',array['5','4','6','1'],1),
('riy1-toplama-10#2','riyaziyyat','riy-1-toplama-10',1,1,'4 + 4 neçə edər?','4 + 4 = 8.',array['8','7','9','6'],1),
('riy1-toplama-10#3','riyaziyyat','riy-1-toplama-10',1,1,'Aysunun 3 şarı var idi. Anası ona 1 şar da verdi. Aysunun neçə şarı oldu?','3 + 1 = 4.',array['4','3','5','2'],1),
('riy1-toplama-10#4','riyaziyyat','riy-1-toplama-10',2,1,'6 + 0 neçə olar?','Sıfır əlavə edəndə ədəd dəyişmir: 6.',array['6','0','7','60'],1),
('riy1-toplama-10#5','riyaziyyat','riy-1-toplama-10',1,1,'1 + 8 cəmini hesablayın.','1 + 8 = 9.',array['9','8','10','7'],1),
('riy1-toplama-10#6','riyaziyyat','riy-1-toplama-10',3,1,'3 + 4 = 4 + ? Sual işarəsinin yerinə hansı ədəd yazılmalıdır?','Toplananların yerini dəyişəndə cəm dəyişmir: 3.',array['3','4','7','1'],1),
('riy1-toplama-10#7','riyaziyyat','riy-1-toplama-10',2,1,'2 + 2 + 3 ifadəsinin qiyməti neçədir?','2 + 2 = 4; 4 + 3 = 7.',array['7','6','8','4'],1),
('riy1-toplama-10#8','riyaziyyat','riy-1-toplama-10',2,1,'Hansı cütün cəmi 10 edir?','6 + 4 = 10.',array['6 və 4','5 və 4','7 və 2','6 və 3'],1),
('riy1-toplama-10#9','riyaziyyat','riy-1-toplama-10',2,1,'Toplananlar 5 və 1-dirsə, cəm neçədir?','5 + 1 = 6.',array['6','5','4','7'],1),
('riy1-toplama-10#10','riyaziyyat','riy-1-toplama-10',2,1,'Budaqda 4 quş oturmuşdu. Yanına daha 3 quş qondu. Budaqda neçə quş oldu?','4 + 3 = 7.',array['7','6','8','1'],1),
('riy1-cixma-10#1','riyaziyyat','riy-1-cixma-10',1,2,'7 − 2 fərqini tapın.','7 − 2 = 5.',array['5','6','4','9'],1),
('riy1-cixma-10#2','riyaziyyat','riy-1-cixma-10',1,2,'9 − 3 neçə edər?','9 − 3 = 6.',array['6','7','5','12'],1),
('riy1-cixma-10#3','riyaziyyat','riy-1-cixma-10',2,2,'5 − 5 neçə olar?','Ədəddən özünü çıxanda sıfır qalır.',array['0','5','1','10'],1),
('riy1-cixma-10#4','riyaziyyat','riy-1-cixma-10',2,2,'8 − 0 neçədir?','Sıfır çıxanda ədəd dəyişmir: 8.',array['8','0','7','9'],1),
('riy1-cixma-10#5','riyaziyyat','riy-1-cixma-10',1,2,'Turalın 6 konfeti var idi. O, 2 konfeti yedi. Neçə konfeti qaldı?','6 − 2 = 4.',array['4','3','5','8'],1),
('riy1-cixma-10#6','riyaziyyat','riy-1-cixma-10',1,2,'10 − 3 fərqini hesablayın.','10 − 3 = 7.',array['7','8','6','13'],1),
('riy1-cixma-10#7','riyaziyyat','riy-1-cixma-10',3,2,'Hansı ədədə 3 əlavə etsək, 9 alarıq?','9 − 3 = 6, deməli axtarılan ədəd 6-dır.',array['6','12','5','3'],1),
('riy1-cixma-10#8','riyaziyyat','riy-1-cixma-10',3,2,'8 − 5 = 3 çıxmasını yoxlamaq üçün hansı toplama uyğundur?','Fərqin üstünə çıxanı gələndə çıxılan alınmalıdır: 3 + 5 = 8.',array['3 + 5 = 8','8 + 5 = 13','3 + 8 = 11','5 − 3 = 2'],1),
('riy1-cixma-10#9','riyaziyyat','riy-1-cixma-10',3,2,'Fərq nə vaxt sıfıra bərabər olur?','Bərabər ədədləri çıxanda fərq sıfırdır.',array['Çıxılan və çıxan bərabər olanda','Çıxılan böyük olanda','Çıxan sıfır olanda','Heç vaxt'],1),
('riy1-cixma-10#10','riyaziyyat','riy-1-cixma-10',2,2,'Tabaqda 10 alma var idi. Uşaqlar 6 almanı götürdü. Tabaqda neçə alma qaldı?','10 − 6 = 4.',array['4','5','6','16'],1),
('riy1-ededler-20#1','riyaziyyat','riy-1-ededler-20',2,2,'1 onluq və 4 təklikdən ibarət ədəd hansıdır?','1 onluq = 10; 10 + 4 = 14.',array['14','41','4','104'],1),
('riy1-ededler-20#2','riyaziyyat','riy-1-ededler-20',2,2,'17 ədədində neçə onluq var?','17 = 1 onluq və 7 təklik.',array['1','7','17','10'],1),
('riy1-ededler-20#3','riyaziyyat','riy-1-ededler-20',1,2,'İrəli sayma: 15-dən sonra hansı ədəd gəlir?','15 + 1 = 16.',array['16','14','17','15'],1),
('riy1-ededler-20#4','riyaziyyat','riy-1-ededler-20',2,2,'Geri sayma: 18, 17, 16, ? Növbəti ədəd hansıdır?','Geri sayanda hər ədəd 1 vahid azalır: 15.',array['15','14','16','19'],1),
('riy1-ededler-20#5','riyaziyyat','riy-1-ededler-20',1,2,'12 və 19 ədədlərindən hansı kiçikdir?','12 sayma sırasında əvvəl gəlir.',array['12','19','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-ededler-20#6','riyaziyyat','riy-1-ededler-20',1,2,'«On doqquz» ədədi rəqəmlə necə yazılır?','On doqquz = 1 onluq və 9 təklik: 19.',array['19','91','9','109'],1),
('riy1-ededler-20#7','riyaziyyat','riy-1-ededler-20',2,2,'13 ədədi neçə onluq və neçə təklikdən ibarətdir?','13 = 1 onluq və 3 təklik.',array['1 onluq, 3 təklik','3 onluq, 1 təklik','13 onluq','10 onluq, 3 təklik'],1),
('riy1-ededler-20#8','riyaziyyat','riy-1-ededler-20',2,2,'11, 15, 13 ədədlərini artan sırada düzün.','Kiçikdən böyüyə: 11, 13, 15.',array['11, 13, 15','15, 13, 11','11, 15, 13','13, 11, 15'],1),
('riy1-ededler-20#9','riyaziyyat','riy-1-ededler-20',3,2,'20 ədədində təkliklər mərtəbəsində hansı rəqəm durur?','20 = 2 onluq və 0 təklik.',array['0','2','20','1'],1),
('riy1-ededler-20#10','riyaziyyat','riy-1-ededler-20',2,2,'2 onluq neçə edir?','2 onluq = 20.',array['20','2','12','22'],1),
('riy1-fiqurlar#1','riyaziyyat','riy-1-fiqurlar',1,2,'Üç tərəfi və üç küncü olan fiqur necə adlanır?','Üç tərəfi olan fiqur üçbucaqdır.',array['Üçbucaq','Kvadrat','Dairə','Düzbucaqlı'],1),
('riy1-fiqurlar#2','riyaziyyat','riy-1-fiqurlar',1,2,'Velosipedin təkəri hansı fiqura bənzəyir?','Təkər dairə formasındadır.',array['Dairəyə','Kvadrata','Üçbucağa','Düzbucaqlıya'],1),
('riy1-fiqurlar#3','riyaziyyat','riy-1-fiqurlar',1,2,'Kvadratın neçə tərəfi var?','Kvadratın 4 bərabər tərəfi var.',array['4','3','5','6'],1),
('riy1-fiqurlar#4','riyaziyyat','riy-1-fiqurlar',2,2,'Dairəni üçbucaqdan fərqləndirən nədir?','Dairənin küncü və düz tərəfi yoxdur.',array['Küncünün olmaması','Rənginin fərqli olması','Daha böyük olması','Tərəflərinin çox olması'],1),
('riy1-fiqurlar#5','riyaziyyat','riy-1-fiqurlar',2,2,'Futbol topu hansı fəza fiqurudur?','Top kürə formasındadır.',array['Kürə','Kub','Konus','Silindr'],1),
('riy1-fiqurlar#6','riyaziyyat','riy-1-fiqurlar',2,2,'Çörək tən ortadan iki bərabər hissəyə bölündü. Hər hissə necə adlanır?','Tamın iki bərabər hissəsindən hər biri yarıdır.',array['Yarı','Tam','Dörddə bir','Bütöv'],1),
('riy1-fiqurlar#7','riyaziyyat','riy-1-fiqurlar',1,2,'Pəncərə çərçivəsi adətən hansı fiqura bənzəyir?','Pəncərə düzbucaqlı formasındadır.',array['Düzbucaqlıya','Dairəyə','Üçbucağa','Kürəyə'],1),
('riy1-fiqurlar#8','riyaziyyat','riy-1-fiqurlar',2,2,'Bir tam neçə yarıdan ibarətdir?','İki yarı birlikdə bir tam edir.',array['2','1','3','4'],1),
('riy1-fiqurlar#9','riyaziyyat','riy-1-fiqurlar',3,2,'Hansı fiqur fəza fiqurudur?','Kub fəza fiqurudur; kvadrat, dairə, üçbucaq müstəvi fiqurlardır.',array['Kub','Kvadrat','Dairə','Üçbucaq'],1),
('riy1-fiqurlar#10','riyaziyyat','riy-1-fiqurlar',3,2,'Dondurma külahı hansı fəza fiquruna bənzəyir?','Külah konus formasındadır.',array['Konusa','Kuba','Kürəyə','Silindrə'],1),
('riy1-toplama-20#1','riyaziyyat','riy-1-toplama-20',1,3,'12 + 5 neçə edər?','12 + 5 = 17.',array['17','16','18','7'],1),
('riy1-toplama-20#2','riyaziyyat','riy-1-toplama-20',2,3,'9 + 6 cəmini tapın.','9-u 10-a tamamlayaq: 9 + 1 = 10; 10 + 5 = 15.',array['15','14','16','13'],1),
('riy1-toplama-20#3','riyaziyyat','riy-1-toplama-20',2,3,'8 + 8 neçə edər?','8 + 8 = 16.',array['16','15','17','14'],1),
('riy1-toplama-20#4','riyaziyyat','riy-1-toplama-20',1,3,'13 + 6 cəmini hesablayın.','13 + 6 = 19.',array['19','18','20','16'],1),
('riy1-toplama-20#5','riyaziyyat','riy-1-toplama-20',1,3,'7 + 7 neçə olar?','7 + 7 = 14.',array['14','13','15','12'],1),
('riy1-toplama-20#6','riyaziyyat','riy-1-toplama-20',1,3,'10 + 8 cəmini tapın.','10-un üstünə 8 gələndə 18 olur.',array['18','17','80','19'],1),
('riy1-toplama-20#7','riyaziyyat','riy-1-toplama-20',2,3,'Aysu səhər 6, axşam 7 səhifə oxudu. O, cəmi neçə səhifə oxudu?','6 + 7 = 13.',array['13','12','14','1'],1),
('riy1-toplama-20#8','riyaziyyat','riy-1-toplama-20',3,3,'Hansı cütün cəmi 20-dir?','12 + 8 = 20.',array['12 və 8','12 və 7','11 və 8','13 və 8'],1),
('riy1-toplama-20#9','riyaziyyat','riy-1-toplama-20',1,3,'9 + 2 neçə edər?','9 + 2 = 11.',array['11','10','12','7'],1),
('riy1-toplama-20#10','riyaziyyat','riy-1-toplama-20',2,3,'Qutuda 14 karandaş var idi. Üstünə 6 karandaş da qoyuldu. Qutuda neçə karandaş oldu?','14 + 6 = 20.',array['20','19','8','21'],1),
('riy1-cixma-20#1','riyaziyyat','riy-1-cixma-20',1,3,'16 − 4 fərqini tapın.','16 − 4 = 12.',array['12','11','13','20'],1),
('riy1-cixma-20#2','riyaziyyat','riy-1-cixma-20',2,3,'13 − 4 neçə edər?','13 − 3 = 10; 10 − 1 = 9.',array['9','10','8','11'],1),
('riy1-cixma-20#3','riyaziyyat','riy-1-cixma-20',1,3,'17 − 10 neçə olar?','1 onluq çıxanda təkliklər qalır: 7.',array['7','8','17','10'],1),
('riy1-cixma-20#4','riyaziyyat','riy-1-cixma-20',2,3,'11 − 5 fərqini hesablayın.','11 − 1 = 10; 10 − 4 = 6.',array['6','7','5','16'],1),
('riy1-cixma-20#5','riyaziyyat','riy-1-cixma-20',1,3,'20 − 10 neçə edər?','2 onluqdan 1 onluq çıxanda 1 onluq qalır: 10.',array['10','20','0','12'],1),
('riy1-cixma-20#6','riyaziyyat','riy-1-cixma-20',2,3,'14 − 9 neçə olar?','14 − 4 = 10; 10 − 5 = 5.',array['5','6','4','23'],1),
('riy1-cixma-20#7','riyaziyyat','riy-1-cixma-20',1,3,'18 − 10 fərqini tapın.','18 − 10 = 8.',array['8','9','18','28'],1),
('riy1-cixma-20#8','riyaziyyat','riy-1-cixma-20',3,3,'6 çıxılanda 8 qalan ədəd hansıdır?','8 + 6 = 14, deməli axtarılan ədəd 14-dür.',array['14','2','12','15'],1),
('riy1-cixma-20#9','riyaziyyat','riy-1-cixma-20',2,3,'Avtobusda 15 sərnişin var idi. Dayanacaqda 4 sərnişin düşdü. Avtobusda neçə sərnişin qaldı?','15 − 4 = 11.',array['11','12','10','19'],1),
('riy1-cixma-20#10','riyaziyyat','riy-1-cixma-20',2,3,'19 − 15 neçə edər?','19 − 15 = 4.',array['4','5','3','14'],1),
('riy1-ededler-100#1','riyaziyyat','riy-1-ededler-100',1,3,'Onluqlarla sayma: 10, 20, 30, ? Növbəti ədəd hansıdır?','Hər addımda 1 onluq artır: 40.',array['40','31','50','35'],1),
('riy1-ededler-100#2','riyaziyyat','riy-1-ededler-100',2,3,'5 onluqdan ibarət ədəd hansıdır?','5 onluq = 50.',array['50','5','15','55'],1),
('riy1-ededler-100#3','riyaziyyat','riy-1-ededler-100',2,3,'43 ədədində neçə onluq var?','43 = 4 onluq və 3 təklik.',array['4','3','43','40'],1),
('riy1-ededler-100#4','riyaziyyat','riy-1-ededler-100',2,3,'67 ədədində təkliklər mərtəbəsində hansı rəqəm durur?','67 = 6 onluq və 7 təklik.',array['7','6','67','0'],1),
('riy1-ededler-100#5','riyaziyyat','riy-1-ededler-100',2,3,'Sayma zamanı 100-dən əvvəl hansı ədəd deyilir?','100 − 1 = 99.',array['99','90','101','98'],1),
('riy1-ededler-100#6','riyaziyyat','riy-1-ededler-100',1,3,'Azərbaycanın pul vahidi necə adlanır?','Pul vahidimiz manatdır, xırda pul qəpikdir.',array['Manat','Dollar','Avro','Rubl'],1),
('riy1-ededler-100#7','riyaziyyat','riy-1-ededler-100',3,3,'Yarım manat neçə qəpikdir?','1 manat 100 qəpikdir; yarısı 50 qəpikdir.',array['50 qəpik','5 qəpik','100 qəpik','10 qəpik'],1),
('riy1-ededler-100#8','riyaziyyat','riy-1-ededler-100',3,3,'Alma 30 qəpikdir. Aysu satıcıya 50 qəpik verdi. Satıcı nə qədər qaytarmalıdır?','50 − 30 = 20 qəpik.',array['20 qəpik','30 qəpik','80 qəpik','10 qəpik'],1),
('riy1-ededler-100#9','riyaziyyat','riy-1-ededler-100',3,3,'10 qəpiklik sikkələrlə 1 manat yığmaq üçün neçə sikkə lazımdır?','1 manat = 100 qəpik; 100-də on dənə 10 var.',array['10','5','100','20'],1),
('riy1-ededler-100#10','riyaziyyat','riy-1-ededler-100',2,3,'34 və 43 ədədlərindən hansı böyükdür?','43-də 4 onluq, 34-də 3 onluq var: 43 böyükdür.',array['43','34','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-olcme#1','riyaziyyat','riy-1-olcme',1,4,'Karandaşın uzunluğunu hansı vahidlə ölçürük?','Kiçik əşyaların uzunluğu santimetrlə ölçülür.',array['Santimetrlə','Kiloqramla','Litrlə','Saatla'],1),
('riy1-olcme#2','riyaziyyat','riy-1-olcme',1,4,'Bir həftədə neçə gün var?','Həftədə 7 gün var.',array['7','5','10','12'],1),
('riy1-olcme#3','riyaziyyat','riy-1-olcme',2,4,'Bir ildə neçə ay var?','İldə 12 ay var.',array['12','10','7','24'],1),
('riy1-olcme#4','riyaziyyat','riy-1-olcme',1,4,'Uzunluğu ölçmək üçün hansı alətdən istifadə olunur?','Uzunluq xətkeşlə ölçülür.',array['Xətkeş','Tərəzi','Saat','Termometr'],1),
('riy1-olcme#5','riyaziyyat','riy-1-olcme',1,4,'Qarpız və alma tərəziyə qoyuldu. Hansı daha ağırdır?','Qarpız almadan xeyli ağırdır.',array['Qarpız','Alma','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-olcme#6','riyaziyyat','riy-1-olcme',3,4,'Saat tam 3-ü göstərəndə böyük əqrəb hansı rəqəmin üstündə olur?','Tam saatlarda böyük əqrəb həmişə 12-nin üstündə durur.',array['12','3','6','9'],1),
('riy1-olcme#7','riyaziyyat','riy-1-olcme',3,4,'Bu gün çərşənbədirsə, sabah hansı gün olacaq?','Çərşənbədən sonra cümə axşamı gəlir.',array['Cümə axşamı','Çərşənbə axşamı','Cümə','Bazar'],1),
('riy1-olcme#8','riyaziyyat','riy-1-olcme',2,4,'Vedrənin və stəkanın hansının tutumu böyükdür?','Vedrəyə daha çox su yerləşir.',array['Vedrənin','Stəkanın','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-olcme#9','riyaziyyat','riy-1-olcme',2,4,'Həftənin birinci iş günü hansıdır?','İş həftəsi bazar ertəsindən başlayır.',array['Bazar ertəsi','Bazar','Şənbə','Cümə'],1),
('riy1-olcme#10','riyaziyyat','riy-1-olcme',2,4,'Karandaş 10 sm, qələm 7 sm-dir. Hansı uzundur?','10 ədədi 7-dən böyükdür — karandaş uzundur.',array['Karandaş','Qələm','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-melumat#1','riyaziyyat','riy-1-melumat',1,4,'Piktoqramda hər şəkil 1 almanı göstərir. 4 şəkil neçə alma deməkdir?','4 şəkil = 4 alma.',array['4','1','8','2'],1),
('riy1-melumat#2','riyaziyyat','riy-1-melumat',1,4,'Cədvəl: Aysu — 3 kitab, Tural — 5 kitab oxuyub. Kim çox oxuyub?','5 ədədi 3-dən böyükdür — Tural çox oxuyub.',array['Tural','Aysu','Bərabərdirlər','Bilmək olmaz'],1),
('riy1-melumat#3','riyaziyyat','riy-1-melumat',2,4,'Sinifdə 4 qız və 3 oğlan var. Sinifdə cəmi neçə şagird var?','4 + 3 = 7.',array['7','6','8','1'],1),
('riy1-melumat#4','riyaziyyat','riy-1-melumat',3,4,'Naxış belə düzülür: 2, 4, 6, … Növbəti ədəd hansı olacaq?','Hər ədəd əvvəlkindən 2 vahid çoxdur: 8.',array['8','7','10','9'],1),
('riy1-melumat#5','riyaziyyat','riy-1-melumat',2,4,'Cədvəldə məlumatlar harada yerləşir?','Cədvəl sətir və sütunlardan ibarətdir.',array['Sətir və sütunlarda','Yalnız şəkillərdə','Dairələrdə','Xəritədə'],1),
('riy1-melumat#6','riyaziyyat','riy-1-melumat',2,4,'Diaqramda ən hündür sütun nəyi göstərir?','Sütun nə qədər hündürdürsə, say o qədər çoxdur.',array['Ən çox olanı','Ən az olanı','Ən kiçiyi','Heç nəyi'],1),
('riy1-melumat#7','riyaziyyat','riy-1-melumat',2,4,'Hava cədvəlində 2 günəşli, 5 yağışlı gün qeyd olunub. Hansı günlər çox olub?','5 ədədi 2-dən böyükdür — yağışlı günlər çox olub.',array['Yağışlı','Günəşli','Bərabər','Bilmək olmaz'],1),
('riy1-melumat#8','riyaziyyat','riy-1-melumat',3,4,'Səbətdə 5 alma, 2 armud var. Armudlar almalardan neçə dənə azdır?','5 − 2 = 3.',array['3','2','7','4'],1),
('riy1-melumat#9','riyaziyyat','riy-1-melumat',2,4,'Naxışı davam etdirin: dairə, üçbucaq, dairə, üçbucaq, dairə, …','Növbə ilə təkrarlanır — dairədən sonra üçbucaq gəlir.',array['Üçbucaq','Dairə','Kvadrat','Ulduz'],1),
('riy1-melumat#10','riyaziyyat','riy-1-melumat',2,4,'Uşaqların boyu: Lalə 110 sm, Nihad 105 sm. Kim hündürdür?','110 ədədi 105-dən böyükdür — Lalə hündürdür.',array['Lalə','Nihad','Bərabərdirlər','Bilmək olmaz'],1),
('az1-sesler-herfler#1','az-dili','az-1-sesler-herfler',2,1,'Azərbaycan əlifbasında neçə hərf var?','Əlifbamızda 32 hərf var.',array['32','23','9','26'],1),
('az1-sesler-herfler#2','az-dili','az-1-sesler-herfler',2,1,'Hərf nədir?','Hərf səsin yazıda göstərilən işarəsidir.',array['Səsin yazıdakı işarəsi','Eşitdiyimiz səs','Sözün mənası','Cümlənin sonu'],1),
('az1-sesler-herfler#3','az-dili','az-1-sesler-herfler',1,1,'Əlifbada «A» hərfindən sonra hansı hərf gəlir?','Əlifba sırası: A, B, C…',array['B','C','D','Z'],1),
('az1-sesler-herfler#4','az-dili','az-1-sesler-herfler',1,1,'«Su» sözü neçə səsdən ibarətdir?','S-u: iki səs.',array['2','3','1','4'],1),
('az1-sesler-herfler#5','az-dili','az-1-sesler-herfler',1,1,'Əlifbamızın birinci hərfi hansıdır?','Əlifba A hərfi ilə başlayır.',array['A','B','Ə','Z'],1),
('az1-sesler-herfler#6','az-dili','az-1-sesler-herfler',2,1,'Hansı hərf Azərbaycan əlifbasında YOXDUR?','W hərfi əlifbamızda yoxdur.',array['W','Ə','Ş','Ü'],1),
('az1-sesler-herfler#7','az-dili','az-1-sesler-herfler',2,1,'Səsi və hərfi necə fərqləndiririk?','Səsi eşidir və deyirik, hərfi yazır və görürük.',array['Səsi eşidirik, hərfi yazırıq','Səsi yazırıq, hərfi eşidirik','İkisi də yalnız yazılır','İkisi də yalnız eşidilir'],1),
('az1-sesler-herfler#8','az-dili','az-1-sesler-herfler',1,1,'«Qız» sözündə neçə səs var?','Q-ı-z: üç səs.',array['3','2','4','5'],1),
('az1-sesler-herfler#9','az-dili','az-1-sesler-herfler',2,1,'Əlifbamızın sonuncu hərfi hansıdır?','Əlifba Z hərfi ilə bitir.',array['Z','A','Y','Ü'],1),
('az1-sesler-herfler#10','az-dili','az-1-sesler-herfler',2,1,'«A» və «a» yazılışları nəyi göstərir?','Eyni hərfin böyük və kiçik yazılışıdır.',array['Eyni hərfin böyük və kiçik formasını','İki müxtəlif hərfi','İki müxtəlif səsi','Rəqəmləri'],1),
('az1-sait-samit#1','az-dili','az-1-sait-samit',2,1,'Dilimizdə saitlərin sayı neçədir?','Saitlər 9-dur: a, e, ə, i, ı, o, ö, u, ü.',array['9','32','23','6'],1),
('az1-sait-samit#2','az-dili','az-1-sait-samit',1,1,'«Ev» sözündə hansı hərf saitdir?','E saitdir, v samitdir.',array['e','v','hər ikisi','heç biri'],1),
('az1-sait-samit#3','az-dili','az-1-sait-samit',2,1,'«Balıq» sözündəki saitləri sayın.','Saitlər: a və ı — iki sait.',array['2','3','1','5'],1),
('az1-sait-samit#4','az-dili','az-1-sait-samit',3,1,'Tələffüz zamanı maneəyə rast gələn səslər necə adlanır?','Samitlər maneə ilə tələffüz olunur.',array['Samitlər','Saitlər','Hecalar','Sözlər'],1),
('az1-sait-samit#5','az-dili','az-1-sait-samit',1,1,'«k» səsi saitdir, yoxsa samit?','K samit səsdir.',array['Samitdir','Saitdir','Hər ikisidir','Səs deyil'],1),
('az1-sait-samit#6','az-dili','az-1-sait-samit',2,1,'Hansı cərgədə yalnız samit hərflər yazılıb?','B, d, k — hamısı samitdir.',array['b, d, k','a, ı, u','e, m, i','o, ö, t'],1),
('az1-sait-samit#7','az-dili','az-1-sait-samit',1,1,'«ü» hansı səsdir?','Ü sait səsdir.',array['Sait','Samit','Heca','Söz'],1),
('az1-sait-samit#8','az-dili','az-1-sait-samit',3,1,'Hər hecada mütləq hansı səs olmalıdır?','Hecanı sait yaradır — hecada mütləq bir sait olur.',array['Sait','Samit','İki samit','Heç bir səs'],1),
('az1-sait-samit#9','az-dili','az-1-sait-samit',2,1,'«Ana» sözündəki saitlər hansılardır?','A-n-a sözündə iki a saiti var.',array['a, a','a, n','n, n','a, n, a'],1),
('az1-sait-samit#10','az-dili','az-1-sait-samit',2,1,'«Qapı» sözündə neçə samit var?','Samitlər: q və p — iki samit.',array['2','3','1','4'],1),
('az1-heca#1','az-dili','az-1-heca',3,2,'Sözlər hecalara nəyə görə bölünür?','Sözdə neçə sait varsa, o qədər də heca var.',array['Saitlərin sayına görə','Samitlərin sayına görə','Hərflərin sayına görə','Sözün uzunluğuna görə'],1),
('az1-heca#2','az-dili','az-1-heca',1,2,'«Ata» sözü neçə hecadan ibarətdir?','A-ta: iki heca (iki sait).',array['2','1','3','4'],1),
('az1-heca#3','az-dili','az-1-heca',2,2,'«Lalə» sözünün hecalara bölünüşü hansıdır?','Düzgün bölgü: la-lə.',array['la-lə','lal-ə','l-alə','lalə-'],1),
('az1-heca#4','az-dili','az-1-heca',2,2,'Birhecalı sözü seçin.','«Gül» sözündə bir sait var — bir hecadır.',array['gül','araba','lalə','kəpənək'],1),
('az1-heca#5','az-dili','az-1-heca',2,2,'«Kəpənək» sözündə hecaların sayı neçədir?','Kə-pə-nək: üç heca.',array['3','2','4','7'],1),
('az1-heca#6','az-dili','az-1-heca',3,2,'Üçhecalı söz hansıdır?','A-ra-ba: üç heca; gül — bir, dəftər və kitab — iki hecadır.',array['araba','gül','dəftər','kitab'],1),
('az1-heca#7','az-dili','az-1-heca',3,2,'Sözdəki hecaların sayı nəyə bərabərdir?','Heca sayı sait səslərin sayına bərabərdir.',array['Sait səslərin sayına','Samit səslərin sayına','Bütün hərflərin sayına','Sözlərin sayına'],1),
('az1-heca#8','az-dili','az-1-heca',2,2,'«O» sözü neçə hecadır?','Tək bir sait də heca sayılır: bir heca.',array['1','2','0','3'],1),
('az1-heca#9','az-dili','az-1-heca',1,2,'Hansı bölgü düzgündür?','Düzgün bölgü: a-na.',array['a-na','an-a','ana-','-ana'],1),
('az1-heca#10','az-dili','az-1-heca',2,2,'«Şagird» sözündə neçə heca var?','Şa-gird: iki heca.',array['2','3','1','6'],1),
('az1-soz-cumle#1','az-dili','az-1-soz-cumle',2,2,'Bitmiş fikri nə ifadə edir?','Cümlə bitmiş fikir bildirir.',array['Cümlə','Heca','Hərf','Səs'],1),
('az1-soz-cumle#2','az-dili','az-1-soz-cumle',2,2,'Sözlərdən cümlə qurun: «məktəbə», «Aysu», «gedir».','Düzgün sıra: Aysu məktəbə gedir.',array['Aysu məktəbə gedir.','Məktəbə gedir Aysu gedir.','Gedir Aysu.','Məktəbə Aysu.'],1),
('az1-soz-cumle#3','az-dili','az-1-soz-cumle',1,2,'«Quş uçur» cümləsində neçə söz var?','Quş və uçur — iki söz.',array['2','1','3','4'],1),
('az1-soz-cumle#4','az-dili','az-1-soz-cumle',2,2,'Hansı sırada bitmiş fikir ifadə olunub?','«Yağış yağır.» — bitmiş fikirdir; qalanları söz birləşməsidir.',array['Yağış yağır.','yaşıl yarpaq','böyük ev','şirin alma'],1),
('az1-soz-cumle#5','az-dili','az-1-soz-cumle',2,2,'Söz nədən ibarətdir?','Söz səslərdən (yazıda hərflərdən) ibarətdir.',array['Səslərdən','Cümlələrdən','Mətnlərdən','Rəqəmlərdən'],1),
('az1-soz-cumle#6','az-dili','az-1-soz-cumle',2,2,'«Mən kitab oxuyuram» cümləsində sözlərin sayı neçədir?','Mən, kitab, oxuyuram — üç söz.',array['3','2','4','5'],1),
('az1-soz-cumle#7','az-dili','az-1-soz-cumle',2,2,'Sual bildirən cümlənin sonunda hansı işarə qoyulur?','Sual cümləsi sual işarəsi ilə bitir.',array['Sual işarəsi','Nöqtə','Vergül','Tire'],1),
('az1-soz-cumle#8','az-dili','az-1-soz-cumle',3,2,'Sözləri əlifba sırası ilə düzün: alma, banan, armud.','Al… ar… ba…: alma, armud, banan.',array['alma, armud, banan','banan, alma, armud','alma, banan, armud','armud, banan, alma'],1),
('az1-soz-cumle#9','az-dili','az-1-soz-cumle',2,2,'Fikri aydın çatdırmaq üçün cümlədə sözlər necə düzülməlidir?','Sözlər mənalı ardıcıllıqla düzülməlidir.',array['Mənalı ardıcıllıqla','Qarışıq','Əlifba sırası ilə','Uzunluğuna görə'],1),
('az1-soz-cumle#10','az-dili','az-1-soz-cumle',1,2,'«Ay», «ev», «su» — bunlar nədir?','Hər biri ayrıca sözdür.',array['Sözlərdir','Cümlələrdir','Hecalardır','Hərflərdir'],1),
('az1-boyuk-herf#1','az-dili','az-1-boyuk-herf',1,3,'İnsan adları hansı hərflə yazılmağa başlanır?','Adlar böyük hərflə yazılır.',array['Böyük hərflə','Kiçik hərflə','İstənilən hərflə','Rəqəmlə'],1),
('az1-boyuk-herf#2','az-dili','az-1-boyuk-herf',2,3,'Hansı söz həmişə böyük hərflə yazılır?','Bakı şəhər adıdır — xüsusi ad böyük hərflə yazılır.',array['Bakı','şəhər','küçə','ev'],1),
('az1-boyuk-herf#3','az-dili','az-1-boyuk-herf',1,3,'Cümləyə başlayanda birinci hərf necə yazılır?','Cümlənin ilk hərfi böyük yazılır.',array['Böyük','Kiçik','Rəngli','Qoşa'],1),
('az1-boyuk-herf#4','az-dili','az-1-boyuk-herf',2,3,'Qızın adının düzgün yazılışını seçin.','Ad böyük hərflə başlayır, qalan hərflər kiçik olur: Aysu.',array['Aysu','aysu','AYsu','aySU'],1),
('az1-boyuk-herf#5','az-dili','az-1-boyuk-herf',3,3,'İtin adı «Alabaş»dır. Bu ad necə yazılmalıdır?','Heyvanlara verilən adlar da böyük hərflə yazılır.',array['Böyük hərflə','Kiçik hərflə','Dırnaq içində kiçik hərflə','Rəqəmlə'],1),
('az1-boyuk-herf#6','az-dili','az-1-boyuk-herf',2,3,'Hansı sıradakı sözlərin hamısı böyük hərflə yazılmalıdır?','Araz, Gəncə, Aygün — hamısı xüsusi addır.',array['Araz, Gəncə, Aygün','kitab, qələm, dəftər','araz, gəncə, aygün','məktəb, sinif, dərs'],1),
('az1-boyuk-herf#7','az-dili','az-1-boyuk-herf',3,3,'«bakı şəhəri gözəldir.» cümləsində hansı səhv var?','Bakı xüsusi addır və cümlənin əvvəlidir — böyük hərflə yazılmalıdır.',array['Bakı böyük hərflə yazılmalıdır','Nöqtə artıqdır','Söz sırası səhvdir','Səhv yoxdur'],1),
('az1-boyuk-herf#8','az-dili','az-1-boyuk-herf',2,3,'Kür nədir və niyə böyük hərflə yazılır?','Kür çayın adıdır — çay adları xüsusi addır.',array['Çay adıdır, xüsusi addır','Adi sözdür','Kiçik hərflə yazılmalıdır','Heca adıdır'],1),
('az1-boyuk-herf#9','az-dili','az-1-boyuk-herf',1,3,'Ölkəmizin adı necə yazılır?','Azərbaycan xüsusi addır — böyük hərflə yazılır.',array['Azərbaycan','azərbaycan','AZƏRbaycan','azərBaycan'],1),
('az1-boyuk-herf#10','az-dili','az-1-boyuk-herf',2,3,'Hansı söz kiçik hərflə yazılır?','«Şagird» ümumi sözdür; Leyla, Şəki, Qəbələ xüsusi adlardır.',array['şagird','Leyla','Şəki','Qəbələ'],1),
('az1-oxu#1','az-dili','az-1-oxu',1,4,'Mətn: «Aysu bağçada gül əkdi. O, hər gün gülə su verdi.» Aysu nə əkdi?','Mətndə deyilir: Aysu gül əkdi.',array['Gül','Ağac','Tərəvəz','Çiçək toxumu'],1),
('az1-oxu#2','az-dili','az-1-oxu',2,4,'Nağıllar adətən hansı sözlərlə başlayır?','Nağılın ənənəvi başlanğıcı: biri var idi, biri yox idi.',array['Biri var idi, biri yox idi','Sonra nə oldu','Beləliklə bitdi','Salam, uşaqlar'],1),
('az1-oxu#3','az-dili','az-1-oxu',2,4,'Şeir nədən ibarət olur?','Şeir misralardan ibarətdir.',array['Misralardan','Cədvəllərdən','Rəqəmlərdən','Xəritələrdən'],1),
('az1-oxu#4','az-dili','az-1-oxu',1,4,'Mətn: «Tural topu atdı. Top qapıya dəydi.» Top haraya dəydi?','Mətndə deyilir: top qapıya dəydi.',array['Qapıya','Pəncərəyə','Divara','Ağaca'],1),
('az1-oxu#5','az-dili','az-1-oxu',2,4,'Oxuduğunu yaxşı anlamaq üçün necə oxumaq lazımdır?','Diqqətlə, tələsmədən oxumaq lazımdır.',array['Diqqətlə, tələsmədən','Çox sürətlə','Sözləri ötürərək','Yalnız şəkillərə baxaraq'],1),
('az1-oxu#6','az-dili','az-1-oxu',2,4,'Tapmacanın cavabını tapın: «Qışda yağar, hər yeri ağ edər».','Qışda yağan və hər yeri ağardan qardır.',array['Qar','Yağış','Külək','Duman'],1),
('az1-oxu#7','az-dili','az-1-oxu',2,4,'«Kitab bilik mənbəyidir» cümləsi nə haqqındadır?','Cümlə kitabın faydasından danışır.',array['Kitab haqqında','Oyun haqqında','Hava haqqında','Yemək haqqında'],1),
('az1-oxu#8','az-dili','az-1-oxu',3,4,'Nağıllarda tülkü adətən necə təsvir olunur?','Nağıllarda tülkü hiyləgər obrazdır.',array['Hiyləgər','Qorxaq','Tənbəl','Güclü'],1),
('az1-oxu#9','az-dili','az-1-oxu',2,4,'Kitabın üz qabığında adətən nə yazılır?','Üz qabığında kitabın adı və müəllifi göstərilir.',array['Kitabın adı','Qiymətlər cədvəli','Hava proqnozu','Riyazi misallar'],1),
('az1-oxu#10','az-dili','az-1-oxu',3,4,'Mətn: «Nərmin nənəsinə kömək etdi. Nənəsi ona təşəkkür etdi.» Nənə niyə təşəkkür etdi?','Nərmin kömək etdiyi üçün nənə təşəkkür etdi.',array['Nərmin kömək etdiyi üçün','Nərmin mahnı oxuduğu üçün','Nərmin şəkil çəkdiyi üçün','Səbəbsiz'],1),
('hey1-men-kimem#1','hayat-bilgisi','hey-1-men-kimem',1,1,'Yaşadığımız ölkənin adı nədir?','Bizim ölkəmiz Azərbaycandır.',array['Azərbaycan','Türkiyə','Gürcüstan','İran'],1),
('hey1-men-kimem#2','hayat-bilgisi','hey-1-men-kimem',1,1,'Azərbaycanın paytaxtı hansı şəhərdir?','Paytaxtımız Bakı şəhəridir.',array['Bakı','Gəncə','Sumqayıt','Şəki'],1),
('hey1-men-kimem#3','hayat-bilgisi','hey-1-men-kimem',1,1,'Ailənin üzvləri kimlərdir?','Ailə ata, ana və uşaqlardan ibarətdir.',array['Ata, ana və uşaqlar','Yalnız qonşular','Sinif yoldaşları','Müəllimlər'],1),
('hey1-men-kimem#4','hayat-bilgisi','hey-1-men-kimem',1,1,'Məktəbdə bizə dərs deyən şəxs kimdir?','Dərsi müəllim keçir.',array['Müəllim','Həkim','Sürücü','Aşpaz'],1),
('hey1-men-kimem#5','hayat-bilgisi','hey-1-men-kimem',2,1,'Dövlət bayrağımızda neçə rəng var?','Bayrağımız üçrənglidir.',array['3','2','4','5'],1),
('hey1-men-kimem#6','hayat-bilgisi','hey-1-men-kimem',2,1,'Bayrağımızın rəngləri hansılardır?','Bayrağımız mavi, qırmızı və yaşıl zolaqlardan ibarətdir.',array['Mavi, qırmızı, yaşıl','Ağ, qırmızı, qara','Sarı, yaşıl, göy','Qırmızı, ağ, mavi'],1),
('hey1-men-kimem#7','hayat-bilgisi','hey-1-men-kimem',1,1,'Salamlaşmaq nəyin əlamətidir?','Salam vermək nəzakətli davranışdır.',array['Nəzakətin','Qorxunun','Tənbəlliyin','Acığın'],1),
('hey1-men-kimem#8','hayat-bilgisi','hey-1-men-kimem',2,1,'Dərsə necə gəlmək lazımdır?','Dərsə vaxtında gəlmək intizamın əlamətidir.',array['Vaxtında','Gecikərək','İstənilən vaxt','Günortadan sonra'],1),
('hey1-men-kimem#9','hayat-bilgisi','hey-1-men-kimem',1,1,'Böyüklərlə necə danışmalıyıq?','Böyüklərlə hörmətlə danışmaq lazımdır.',array['Hörmətlə','Qışqıraraq','Sözünü kəsərək','Üz döndərərək'],1),
('hey1-men-kimem#10','hayat-bilgisi','hey-1-men-kimem',2,1,'Sinifdə cavab vermək istəyəndə nə etməliyik?','Əl qaldırıb icazə gözləmək lazımdır.',array['Əl qaldırmalıyıq','Yerimizdən qışqırmalıyıq','Ayağa qalxıb qaçmalıyıq','Partanı döyməliyik'],1),
('hey1-saglamliq#1','hayat-bilgisi','hey-1-saglamliq',1,1,'İnsan ətrafı hansı orqanla görür?','Görmə orqanımız gözdür.',array['Gözlə','Qulaqla','Burunla','Əllə'],1),
('hey1-saglamliq#2','hayat-bilgisi','hey-1-saglamliq',1,1,'Qulaqlar nə üçündür?','Qulaq eşitmə orqanıdır.',array['Eşitmək üçün','Görmək üçün','Dadmaq üçün','İy hiss etmək üçün'],1),
('hey1-saglamliq#3','hayat-bilgisi','hey-1-saglamliq',1,1,'Yatmazdan əvvəl dişlərimizlə nə etməliyik?','Axşam dişləri fırçalamaq lazımdır.',array['Fırçalamalıyıq','Heç nə etməməliyik','Konfet yeməliyik','Yalnız su içməliyik'],1),
('hey1-saglamliq#4','hayat-bilgisi','hey-1-saglamliq',1,1,'Çöldən evə gələndə ilk növbədə nə etməliyik?','Bayırdan gələndə əllər sabunla yuyulmalıdır.',array['Əllərimizi yumalıyıq','Dərhal yemək yeməliyik','Televizora baxmalıyıq','Yatmalıyıq'],1),
('hey1-saglamliq#5','hayat-bilgisi','hey-1-saglamliq',1,1,'Hansı qida sağlamlıq üçün faydalıdır?','Meyvə vitaminlərlə zəngindir.',array['Meyvə','Çips','Qazlı içki','Çoxlu konfet'],1),
('hey1-saglamliq#6','hayat-bilgisi','hey-1-saglamliq',2,1,'Bədənimizi təmiz saxlamaq üçün nədən istifadə edirik?','Təmizlik üçün su və sabun lazımdır.',array['Su və sabundan','Yalnız ətirdən','Tozdan','Heç nədən'],1),
('hey1-saglamliq#7','hayat-bilgisi','hey-1-saglamliq',2,1,'İy hiss etmə orqanımız hansıdır?','Qoxunu burunla hiss edirik.',array['Burun','Göz','Qulaq','Dil'],1),
('hey1-saglamliq#8','hayat-bilgisi','hey-1-saglamliq',2,1,'Dırnaqları niyə vaxtında kəsmək lazımdır?','Uzun dırnağın altına mikroblar yığılır.',array['Altına mikrob yığılmasın deyə','Gözəl görünmək üçün yox','Heç bir səbəb yoxdur','Dırnaq kəsilməz'],1),
('hey1-saglamliq#9','hayat-bilgisi','hey-1-saglamliq',2,1,'Gecə yuxusu insana nə verir?','Yuxu zamanı bədən istirahət edib güc toplayır.',array['İstirahət və güc','Yorğunluq','Xəstəlik','Aclıq'],1),
('hey1-saglamliq#10','hayat-bilgisi','hey-1-saglamliq',3,1,'Səhər yeməyini ötürmək düzgündürmü?','Səhər yeməyi günə güclə başlamaq üçün vacibdir.',array['Düzgün deyil — səhər yeməyi vacibdir','Düzgündür','Fərqi yoxdur','Yalnız yayda düzgündür'],1),
('hey1-insanlar-esyalar#1','hayat-bilgisi','hey-1-insanlar-esyalar',1,2,'Stəkan adətən hansı materialdan hazırlanır?','Stəkan şüşədən hazırlanır.',array['Şüşədən','Kağızdan','Parçadan','Pambıqdan'],1),
('hey1-insanlar-esyalar#2','hayat-bilgisi','hey-1-insanlar-esyalar',1,2,'Dəftər və kitab hansı materialdan hazırlanır?','Dəftər və kitab kağızdan hazırlanır.',array['Kağızdan','Dəmirdən','Şüşədən','Daşdan'],1),
('hey1-insanlar-esyalar#3','hayat-bilgisi','hey-1-insanlar-esyalar',1,2,'Hansı əşya taxtadan hazırlanır?','Stul adətən taxtadan düzəldilir.',array['Stul','Stəkan','Corab','Qazan'],1),
('hey1-insanlar-esyalar#4','hayat-bilgisi','hey-1-insanlar-esyalar',1,2,'Paltarlarımız nədən tikilir?','Paltar parçadan tikilir.',array['Parçadan','Şüşədən','Daşdan','Kağızdan'],1),
('hey1-insanlar-esyalar#5','hayat-bilgisi','hey-1-insanlar-esyalar',1,2,'Soyuducu nə üçündür?','Soyuducu qidaları təzə və soyuq saxlayır.',array['Qidaları soyuq saxlamaq üçün','Paltar yumaq üçün','Otağı qızdırmaq üçün','Musiqi dinləmək üçün'],1),
('hey1-insanlar-esyalar#6','hayat-bilgisi','hey-1-insanlar-esyalar',2,2,'Paltarları hansı məişət avadanlığı yuyur?','Paltarları paltaryuyan maşın yuyur.',array['Paltaryuyan maşın','Soyuducu','Televizor','Ütü'],1),
('hey1-insanlar-esyalar#7','hayat-bilgisi','hey-1-insanlar-esyalar',2,2,'Dayanan topu itələsək, nə baş verər?','İtələnən əşya hərəkətə gəlir.',array['Hərəkət edər','Yerində qalar','Yox olar','Böyüyər'],1),
('hey1-insanlar-esyalar#8','hayat-bilgisi','hey-1-insanlar-esyalar',2,2,'Ölkəmizdə insanlar əsasən hansı dildə danışır?','Dövlət dilimiz Azərbaycan dilidir.',array['Azərbaycan dilində','İngilis dilində','Fransız dilində','Ərəb dilində'],1),
('hey1-insanlar-esyalar#9','hayat-bilgisi','hey-1-insanlar-esyalar',2,2,'Şüşə əşyalarla necə davranmaq lazımdır?','Şüşə tez sınır — ehtiyatlı olmaq lazımdır.',array['Ehtiyatla','Ataraq','Döyəcləyərək','Fərqi yoxdur'],1),
('hey1-insanlar-esyalar#10','hayat-bilgisi','hey-1-insanlar-esyalar',2,2,'Yoldaşınla oyuncaqları necə oynamaq düzgündür?','Oyuncaqları bölüşmək, növbə ilə oynamaq lazımdır.',array['Bölüşərək, növbə ilə','Heç kimə verməyərək','Əlindən alaraq','Gizlədərək'],1),
('hey1-etraf-muhit#1','hayat-bilgisi','hey-1-etraf-muhit',1,3,'Bir ildə neçə fəsil var?','Fəsillər dörddür: yaz, yay, payız, qış.',array['4','3','5','12'],1),
('hey1-etraf-muhit#2','hayat-bilgisi','hey-1-etraf-muhit',1,3,'Qar adətən hansı fəsildə yağır?','Qar qışda yağır.',array['Qışda','Yayda','Yazda','Payızda'],1),
('hey1-etraf-muhit#3','hayat-bilgisi','hey-1-etraf-muhit',1,3,'Yayda hava adətən necə olur?','Yay ilin ən isti fəslidir.',array['İsti','Soyuq','Şaxtalı','Qarlı'],1),
('hey1-etraf-muhit#4','hayat-bilgisi','hey-1-etraf-muhit',1,3,'Payızda ağacların yarpaqları nə edir?','Payızda yarpaqlar saralıb tökülür.',array['Saralıb tökülür','Göyərir','Çiçək açır','Böyüyür'],1),
('hey1-etraf-muhit#5','hayat-bilgisi','hey-1-etraf-muhit',2,3,'Hansı varlıq canlıdır?','Ağac böyüyür, qidalanır — canlıdır.',array['Ağac','Daş','Qum','Dəmir'],1),
('hey1-etraf-muhit#6','hayat-bilgisi','hey-1-etraf-muhit',2,3,'Canlılar yaşamaq üçün nəyə möhtacdır?','Canlılara su, hava və qida lazımdır.',array['Su, hava və qidaya','Yalnız oyuncağa','Televizora','Heç nəyə'],1),
('hey1-etraf-muhit#7','hayat-bilgisi','hey-1-etraf-muhit',2,3,'Hansı varlıq cansızdır?','Daş böyümür, qidalanmır — cansızdır.',array['Daş','Quş','Balıq','Gül'],1),
('hey1-etraf-muhit#8','hayat-bilgisi','hey-1-etraf-muhit',2,3,'Yağışdan sonra göydə bəzən nə görünür?','Günəş çıxanda göy qurşağı görünə bilər.',array['Göy qurşağı','Qar dənələri','Ulduzlar','Ay'],1),
('hey1-etraf-muhit#9','hayat-bilgisi','hey-1-etraf-muhit',3,3,'Küləyin əsdiyini nədən bilirik?','Külək əsəndə budaqlar yellənir.',array['Ağac budaqlarının yellənməsindən','Günəşin çıxmasından','Qarın əriməsindən','Gecənin düşməsindən'],1),
('hey1-etraf-muhit#10','hayat-bilgisi','hey-1-etraf-muhit',2,3,'Yazda təbiətdə nə baş verir?','Yazda hava istiləşir, ağaclar çiçək açır.',array['Ağaclar çiçək açır','Yarpaqlar tökülür','Çaylar donur','Günlər qısalır'],1),
('hey1-ehtiyat#1','hayat-bilgisi','hey-1-ehtiyat',2,4,'Yolu keçməzdən əvvəl əvvəlcə hansı tərəfə baxmaq lazımdır?','Əvvəl sola, yolun ortasında sağa baxılır.',array['Sola','Sağa','Yuxarı','Arxaya'],1),
('hey1-ehtiyat#2','hayat-bilgisi','hey-1-ehtiyat',1,4,'Yol üzərindəki ağ zolaqlar («zebra») nə üçündür?','Zebra piyadaların yolu keçdiyi yerdir.',array['Piyadaların yol keçməsi üçün','Maşınların dayanması üçün','Oyun oynamaq üçün','Bəzək üçün'],1),
('hey1-ehtiyat#3','hayat-bilgisi','hey-1-ehtiyat',1,4,'Svetoforun qırmızı işığı piyadaya nə deyir?','Qırmızı işıq «dayan» deməkdir.',array['Dayan','Keç','Qaç','Hazırlaş'],1),
('hey1-ehtiyat#4','hayat-bilgisi','hey-1-ehtiyat',2,4,'Yanğın zamanı hansı nömrəyə zəng edilir?','Yanğınsöndürmə xidmətinin nömrəsi 101-dir.',array['101','102','103','104'],1),
('hey1-ehtiyat#5','hayat-bilgisi','hey-1-ehtiyat',2,4,'Təcili tibbi yardımın nömrəsi hansıdır?','Təcili tibbi yardım 103 nömrəsi ilə çağırılır.',array['103','101','102','105'],1),
('hey1-ehtiyat#6','hayat-bilgisi','hey-1-ehtiyat',1,4,'Hansı nəqliyyat vasitəsidir?','Avtobus sərnişin daşıyan nəqliyyat vasitəsidir.',array['Avtobus','Stol','Kitab','Ağac'],1),
('hey1-ehtiyat#7','hayat-bilgisi','hey-1-ehtiyat',2,4,'Avtobusda özümüzü necə aparmalıyıq?','Sakit dayanıb tutacaqdan tutmaq lazımdır.',array['Sakit dayanıb tutacaqdan tutmalıyıq','Qaçıb oynamalıyıq','Pəncərədən sallanmalıyıq','Qışqırmalıyıq'],1),
('hey1-ehtiyat#8','hayat-bilgisi','hey-1-ehtiyat',2,4,'Evdə tək olanda tanımadığın adam qapını döysə, nə etməlisən?','Qapını açmamaq və böyüklərə xəbər vermək lazımdır.',array['Qapını açmamalıyam','Qapını dərhal açmalıyam','Onunla söhbət etməliyəm','Evə dəvət etməliyəm'],1),
('hey1-ehtiyat#9','hayat-bilgisi','hey-1-ehtiyat',3,4,'Sel təhlükəsi olanda hara getmək lazımdır?','Sel zamanı hündür yerə qalxmaq lazımdır.',array['Hündür yerə','Çaya yaxın yerə','Zirzəmiyə','Körpünün altına'],1),
('hey1-ehtiyat#10','hayat-bilgisi','hey-1-ehtiyat',1,4,'Top oynamaq üçün təhlükəsiz yer haradır?','Yoldan uzaq həyət meydançası təhlükəsizdir.',array['Həyət meydançası','Yolun kənarı','Maşın dayanacağı','Körpünün üstü'],1),
('inf1-esyalar#1','informatika','inf-1-esyalar',2,1,'Almanı təsvir edərkən onun hansı əlamətlərini deyirik?','Əşya rənginə, formasına, ölçüsünə görə təsvir olunur.',array['Rəngini, formasını, ölçüsünü','Yalnız qiymətini','Yalnız adını','Yalnız yerini'],1),
('inf1-esyalar#2','informatika','inf-1-esyalar',2,1,'Əşyanın forması dedikdə nəyi nəzərdə tuturuq?','Forma — əşyanın yumru, dördkünc və s. olmasıdır.',array['Yumru və ya dördkünc olmasını','Rəngini','Qoxusunu','Səsini'],1),
('inf1-esyalar#3','informatika','inf-1-esyalar',2,1,'İki əşyanı müqayisə edəndə nəyi tapırıq?','Müqayisədə oxşar və fərqli cəhətlər tapılır.',array['Oxşar və fərqli cəhətləri','Yalnız qiyməti','Yalnız çəkini','Heç nəyi'],1),
('inf1-esyalar#4','informatika','inf-1-esyalar',1,1,'Kitab rəfin yuxarısında, top rəfin aşağısındadır. Yuxarıda nə var?','Yuxarıdakı əşya kitabdır.',array['Kitab','Top','Rəf','Heç nə'],1),
('inf1-esyalar#5','informatika','inf-1-esyalar',1,1,'«Sağ» tərəfin əksi hansı tərəfdir?','Sağın əksi soldur.',array['Sol','Yuxarı','Aşağı','Ön'],1),
('inf1-esyalar#6','informatika','inf-1-esyalar',2,1,'Maşının hansı hissəsi onu hərəkət etdirir?','Maşın təkərlər üzərində hərəkət edir.',array['Təkərləri','Pəncərəsi','Oturacağı','Rəngi'],1),
('inf1-esyalar#7','informatika','inf-1-esyalar',2,1,'Hansı iki əşya formasına görə oxşardır?','Top da, qarpız da yumrudur.',array['Top və qarpız','Kitab və top','Qələm və boşqab','Stul və alma'],1),
('inf1-esyalar#8','informatika','inf-1-esyalar',1,1,'Qələm və karandaşın oxşar cəhəti nədir?','Hər ikisi yazı yazmaq üçündür.',array['Hər ikisi yazmaq üçündür','Hər ikisi yeyiləndir','Hər ikisi geyimdir','Oxşarlıqları yoxdur'],1),
('inf1-esyalar#9','informatika','inf-1-esyalar',2,1,'Fil, it və siçanı böyüklüyünə görə düzsək, birinci hansı olar?','Ən böyük heyvan fildir.',array['Fil','İt','Siçan','Hamısı eynidir'],1),
('inf1-esyalar#10','informatika','inf-1-esyalar',3,1,'Şagird lövhəyə üzü dayanıb. Lövhə şagirdə görə hansı tərəfdədir?','Üzü lövhəyə duran adam üçün lövhə öndədir.',array['Öndə','Arxada','Sağda','Solda'],1),
('inf1-ardicilliq#1','informatika','inf-1-ardicilliq',2,2,'Hadisələri düzgün sıralayın: toxum əkilir → ? → meyvə yığılır.','Toxum əkiləndən sonra bitki böyüyür, sonra meyvə yığılır.',array['Bitki böyüyür','Meyvə satılır','Qış gəlir','Toxum atılır'],1),
('inf1-ardicilliq#2','informatika','inf-1-ardicilliq',2,2,'Çay dəmləmək üçün əvvəlcə nə etmək lazımdır?','Əvvəlcə çaynikə su töküb qaynatmaq lazımdır.',array['Su qaynatmaq','Stəkana süd tökmək','Çayı içmək','Stəkanı yumaq'],1),
('inf1-ardicilliq#3','informatika','inf-1-ardicilliq',1,2,'«Gündüz» sözünün əksi nədir?','Gündüzün əksi gecədir.',array['Gecə','Səhər','Axşam','Günorta'],1),
('inf1-ardicilliq#4','informatika','inf-1-ardicilliq',1,2,'«Balıqlar havada uçur» fikri doğrudur, yoxsa yalan?','Balıqlar suda üzür — fikir yalandır.',array['Yalandır','Doğrudur','Bəzən doğrudur','Bilmək olmaz'],1),
('inf1-ardicilliq#5','informatika','inf-1-ardicilliq',1,2,'«Qış soyuq fəsildir» fikri necə fikirdir?','Qış həqiqətən soyuqdur — fikir doğrudur.',array['Doğrudur','Yalandır','Nə doğru, nə yalan','Sualdır'],1),
('inf1-ardicilliq#6','informatika','inf-1-ardicilliq',2,2,'Əvvəl ayaqqabı, sonra corab geyinmək — bu ardıcıllıq necədir?','Ardıcıllıq pozulub: əvvəl corab, sonra ayaqqabı geyinilir.',array['Səhvdir — əvvəl corab geyinilir','Düzgündür','Fərqi yoxdur','Hər ikisi eyni vaxtda geyinilir'],1),
('inf1-ardicilliq#7','informatika','inf-1-ardicilliq',2,2,'Günün hissələrini düzgün ardıcıllıqla düzün.','Ardıcıllıq: səhər, günorta, axşam, gecə.',array['Səhər, günorta, axşam, gecə','Gecə, günorta, səhər, axşam','Axşam, səhər, gecə, günorta','Günorta, gecə, səhər, axşam'],1),
('inf1-ardicilliq#8','informatika','inf-1-ardicilliq',1,2,'Yumurtadan hansı canlı çıxır?','Toyuğun yumurtasından cücə çıxır.',array['Cücə','Bala pişik','Buzov','Dovşan'],1),
('inf1-ardicilliq#9','informatika','inf-1-ardicilliq',2,2,'Hansı cüt əks əlamətləri göstərir?','Uzun və qısa bir-birinin əksidir.',array['uzun — qısa','uzun — hündür','qısa — balaca','isti — ilıq'],1),
('inf1-ardicilliq#10','informatika','inf-1-ardicilliq',3,2,'Əl yumanın addımlarını sıralayın: 1) əlləri sabunla, 2) kranı aç, 3) dəsmalla qurula.','Düzgün sıra: kranı aç, sabunla, qurula — 2, 1, 3.',array['2, 1, 3','1, 2, 3','3, 2, 1','1, 3, 2'],1),
('inf1-informasiya#1','informatika','inf-1-informasiya',1,3,'Ətrafımızdan aldığımız xəbər və məlumatlar necə adlanır?','Aldığımız məlumatlar informasiya adlanır.',array['İnformasiya','Oyun','İdman','Yemək'],1),
('inf1-informasiya#2','informatika','inf-1-informasiya',1,3,'Televizor bizə nə çatdırır?','Televizor xəbər və verilişlər — informasiya çatdırır.',array['İnformasiya','Yemək','Paltar','Oyuncaq'],1),
('inf1-informasiya#3','informatika','inf-1-informasiya',1,3,'Şəkildəki informasiyanı hansı orqanla qəbul edirik?','Şəkilə baxırıq — gözlə qəbul edirik.',array['Gözlə','Qulaqla','Burunla','Dillə'],1),
('inf1-informasiya#4','informatika','inf-1-informasiya',2,3,'Telefonun zəng səsi bizə nə bildirir?','Zəng səsi kiminsə zəng etdiyini xəbər verir.',array['Kiminsə zəng etdiyini','Yağış yağacağını','Yeməyin hazır olduğunu','Heç nəyi'],1),
('inf1-informasiya#5','informatika','inf-1-informasiya',2,3,'İnformasiyanı başqasına hansı yollarla çatdırmaq olar?','Danışmaqla, yazmaqla, şəkil çəkməklə çatdırmaq olar.',array['Danışmaqla, yazmaqla, şəkillə','Yalnız yatmaqla','Yalnız qaçmaqla','Heç cür'],1),
('inf1-informasiya#6','informatika','inf-1-informasiya',2,3,'Yol nişanları sürücülərə nəyi bildirir?','Yol nişanları yol qaydaları haqqında məlumat verir.',array['Yol qaydalarını','Hava proqnozunu','Mağaza qiymətlərini','Futbol nəticələrini'],1),
('inf1-informasiya#7','informatika','inf-1-informasiya',1,3,'Kitabdan informasiyanı necə alırıq?','Kitabı oxuyaraq məlumat alırıq.',array['Oxumaqla','İyləməklə','Silkələməklə','Dadmaqla'],1),
('inf1-informasiya#8','informatika','inf-1-informasiya',2,3,'Radio informasiyanı hansı formada çatdırır?','Radionu dinləyirik — informasiya səslə gəlir.',array['Səslə','Şəkillə','Yazı ilə','Qoxu ilə'],1),
('inf1-informasiya#9','informatika','inf-1-informasiya',2,3,'Sabahkı hava haqqında məlumatı haradan öyrənmək olar?','Hava proqnozu havanı qabaqcadan bildirir.',array['Hava proqnozundan','Yemək kitabından','Xəritədən','Riyaziyyat dərsliyindən'],1),
('inf1-informasiya#10','informatika','inf-1-informasiya',1,3,'Müəllimin danışdığını hansı orqanla qəbul edirik?','Danışığı qulaqla eşidirik.',array['Qulaqla','Gözlə','Əllə','Burunla'],1),
('inf1-kompyuter#1','informatika','inf-1-kompyuter',1,4,'Kompüterin ekranlı hissəsi necə adlanır?','Ekranı olan qurğu monitordur.',array['Monitor','Klaviatura','Maus','Printer'],1),
('inf1-kompyuter#2','informatika','inf-1-kompyuter',1,4,'Üzərində hərf və rəqəm düymələri olan qurğu hansıdır?','Hərf və rəqəmlər klaviaturanın düymələrindədir.',array['Klaviatura','Monitor','Dinamik','Kamera'],1),
('inf1-kompyuter#3','informatika','inf-1-kompyuter',2,4,'Kompüterdə şəkil çəkərkən ən çox hansı qurğudan istifadə olunur?','Şəkil çəkmə proqramında maus ilə çəkirik.',array['Mausdan','Printerdən','Dinamikdən','Mikrofondan'],1),
('inf1-kompyuter#4','informatika','inf-1-kompyuter',2,4,'Kompüterdə hesablama aparmaq üçün hansı proqramdan istifadə etmək olar?','Kalkulyator proqramı hesablama aparır.',array['Kalkulyatordan','Şəkil çəkmə proqramından','Musiqi pleyerindən','Saatdan'],1),
('inf1-kompyuter#5','informatika','inf-1-kompyuter',1,4,'Kompüteri işə salmaq üçün nə edirik?','Qoşma düyməsini basırıq.',array['Qoşma düyməsini basırıq','Ekranı silkələyirik','Üstünə su tökürük','Gözləyirik'],1),
('inf1-kompyuter#6','informatika','inf-1-kompyuter',2,4,'Kompüterə ən çox nə zərər verə bilər?','Su və digər mayelər kompüteri sıradan çıxarır.',array['Üstünə tökülən su','Təmiz stol','Sərin otaq','Səliqəli istifadə'],1),
('inf1-kompyuter#7','informatika','inf-1-kompyuter',2,4,'Kompüterdə çox oturanda gözlərimiz nə edir?','Ekrana uzun baxanda gözlər yorulur.',array['Yorulur','Güclənir','Dəyişmir','Daha iti görür'],1),
('inf1-kompyuter#8','informatika','inf-1-kompyuter',1,4,'Kompüterdə çəkdiyimiz şəkli harada görürük?','Çəkdiyimiz şəkil ekranda (monitorda) görünür.',array['Ekranda','Klaviaturada','Mausda','Naqildə'],1),
('inf1-kompyuter#9','informatika','inf-1-kompyuter',2,4,'Kompüter oyunlarını nə qədər oynamaq düzgündür?','Oyun vaxtı məhdud olmalıdır — gözlər və bədən yorulmasın.',array['Müəyyən olunmuş qədər, az','Bütün günü','Gecə boyu','Dayanmadan'],1),
('inf1-kompyuter#10','informatika','inf-1-kompyuter',3,4,'Maus düyməsini bir dəfə basmaq necə adlanır?','Maus düyməsini basmaq klik adlanır.',array['Klik','Yazı','Çap','Zəng'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '1'
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
     and (ext_key like 'riy1-%' or ext_key like 'az1-%'
          or ext_key like 'hey1-%' or ext_key like 'inf1-%');
  if n <> 270 then
    raise exception 'sinif1 suallari: 270 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'riy1-%' or q.ext_key like 'az1-%'
          or q.ext_key like 'hey1-%' or q.ext_key like 'inf1-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy1-%' or ext_key like 'az1-%'
      or ext_key like 'hey1-%' or ext_key like 'inf1-%';
  if k <> 27 then
    raise exception 'movzu sayi 27 deyil: %', k;
  end if;
  raise notice '1-ci sinif banki: % sual, 27 movzu (riy, az, hey, inf).', n;
end $$;
