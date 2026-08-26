-- =====================================================================
--  38_bank_riy8.sql : RIYAZIYYAT 8 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy8.py yaradir:
--      python3 tools/riy8.py
--
--  11 movzu x 20 sual = 220.  ext_key: riy8-<movzu>#<sira>.
--  ON SERT: 37_movzular_orta8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (
    select 1 from public.topics t
      join public.subjects s on s.id = t.subject_id
     where s.slug = 'riyaziyyat' and t.slug = 'riy-8-pifaqor') then
    raise exception 'ONCE 37_movzular_orta8.sql isledilmelidir (riy-8-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'riy8-%';

with d(ext, topic, diff, rub, body, why, opts, correct) as (values
('riy8-kvadrat-kok#1','riy-8-kvadrat-kok',1,1,'√49 neçəyə bərabərdir?','7² = 49, deməli √49 = 7.',array['7','9','24,5','49'],1),
('riy8-kvadrat-kok#2','riy-8-kvadrat-kok',2,1,'√81 + √16 cəmini tapın.','9 + 4 = 13.',array['13','12','97','5'],1),
('riy8-kvadrat-kok#3','riy-8-kvadrat-kok',3,1,'Hansı ədəd irrasional ədəddir?','√2 sonsuz dövrsüz onluq kəsrdir — irrasionaldır.',array['√2','0,5','3/4','7'],1),
('riy8-kvadrat-kok#4','riy-8-kvadrat-kok',2,1,'121 ədədinin kvadrat kökü neçədir?','11² = 121.',array['11','12','60,5','21'],1),
('riy8-kvadrat-kok#5','riy-8-kvadrat-kok',2,1,'(√5)² neçəyə bərabərdir?','Kökün kvadratı kökaltı ifadəyə bərabərdir: 5.',array['5','25','10','2,5'],1),
('riy8-kvadrat-kok#6','riy-8-kvadrat-kok',3,1,'√18 ifadəsini sadələşdirin.','√18 = √(9·2) = 3√2.',array['3√2','9√2','2√3','6√3'],1),
('riy8-kvadrat-kok#7','riy-8-kvadrat-kok',3,1,'√a · √b nəyə bərabərdir? (a, b ≥ 0)','Köklərin hasili hasilin kökünə bərabərdir: √(ab).',array['√(a·b)','√(a+b)','a·b','√a + √b'],1),
('riy8-kvadrat-kok#8','riy-8-kvadrat-kok',2,1,'Həqiqi ədədlər çoxluğuna hansı ədədlər daxildir?','Rasional və irrasional ədədlərin birliyi.',array['Rasional və irrasional ədədlər','Yalnız natural ədədlər','Yalnız kəsrlər','Yalnız mənfi ədədlər'],1),
('riy8-kvadrat-kok#9','riy-8-kvadrat-kok',2,1,'√36 · √25 hasilini tapın.','6 · 5 = 30.',array['30','61','11','900'],1),
('riy8-kvadrat-kok#10','riy-8-kvadrat-kok',2,1,'x² = 64 tənliyinin müsbət kökü neçədir?','8² = 64, müsbət kök 8-dir.',array['8','32','16','4'],1),
('riy8-kvadrat-kok#11','riy-8-kvadrat-kok',2,1,'√144 − √100 fərqini hesablayın.','12 − 10 = 2.',array['2','22','44','4'],1),
('riy8-kvadrat-kok#12','riy-8-kvadrat-kok',2,1,'√625 neçəyə bərabərdir?','25² = 625.',array['25','35','312,5','45'],1),
('riy8-kvadrat-kok#13','riy-8-kvadrat-kok',3,1,'√7 · √28 hasilini hesablayın.','√(7 · 28) = √196 = 14.',array['14','196','35','21'],1),
('riy8-kvadrat-kok#14','riy-8-kvadrat-kok',2,1,'√(16 · 25) neçəyə bərabərdir?','√16 · √25 = 4 · 5 = 20.',array['20','40','400','41'],1),
('riy8-kvadrat-kok#15','riy-8-kvadrat-kok',3,1,'√50 ifadəsini sadələşdirin.','√50 = √(25 · 2) = 5√2.',array['5√2','2√5','25√2','10√5'],1),
('riy8-kvadrat-kok#16','riy-8-kvadrat-kok',3,1,'Köklərin nisbəti √a : √b hansı ifadəyə bərabərdir? (a ≥ 0, b > 0)','Köklərin nisbəti nisbətin kökünə bərabərdir.',array['√(a : b)','√(a − b)','a : b','√a − √b'],1),
('riy8-kvadrat-kok#17','riy-8-kvadrat-kok',2,1,'Aşağıdakılardan hansı rasional ədəddir?','0,25 = 1/4 — rasionaldır; √3, √7 və π irrasionaldır.',array['0,25','√3','π','√7'],1),
('riy8-kvadrat-kok#18','riy-8-kvadrat-kok',2,1,'2√3 + 5√3 cəmini hesablayın.','Eyni köklü hədlər toplanır: 7√3.',array['7√3','7√6','10√3','2√15'],1),
('riy8-kvadrat-kok#19','riy-8-kvadrat-kok',2,1,'√225 neçəyə bərabərdir?','15² = 225.',array['15','25','112,5','16'],1),
('riy8-kvadrat-kok#20','riy-8-kvadrat-kok',1,1,'Ədəd oxunda √9 hansı nöqtəyə uyğun gəlir?','√9 = 3.',array['3','9','4,5','81'],1),
('riy8-pifaqor#1','riy-8-pifaqor',2,1,'Pifaqor teoremi hansı üçbucağa tətbiq olunur?','Teorem düzbucaqlı üçbucaq üçündür.',array['Düzbucaqlı üçbucağa','İstənilən üçbucağa','Yalnız bərabərtərəfliyə','Dördbucaqlıya'],1),
('riy8-pifaqor#2','riy-8-pifaqor',2,1,'Pifaqor teoreminin düsturu hansıdır?','Hipotenuzun kvadratı katetlərin kvadratları cəminə bərabərdir.',array['c² = a² + b²','c = a + b','c² = a² − b²','c = a · b'],1),
('riy8-pifaqor#3','riy-8-pifaqor',2,1,'Katetlər 3 və 4 olarsa, hipotenuz neçədir?','√(9 + 16) = √25 = 5.',array['5','7','12','25'],1),
('riy8-pifaqor#4','riy-8-pifaqor',2,1,'Katetlər 5 və 12 olarsa, hipotenuzu tapın.','√(25 + 144) = √169 = 13.',array['13','17','60','169'],1),
('riy8-pifaqor#5','riy-8-pifaqor',3,1,'Hipotenuz 13, katetlərdən biri 5-dirsə, o biri kateti tapın.','√(169 − 25) = √144 = 12.',array['12','8','18','144'],1),
('riy8-pifaqor#6','riy-8-pifaqor',2,1,'Hipotenuz üçbucağın hansı tərəfidir?','Düz bucağın qarşısındakı ən böyük tərəfdir.',array['Düz bucaq qarşısındakı tərəf','Ən kiçik tərəf','İstənilən tərəf','Hündürlük'],1),
('riy8-pifaqor#7','riy-8-pifaqor',3,1,'Tərəfləri 7, 24 və 25 olan üçbucaq düzbucaqlıdırmı?','7² + 24² = 49 + 576 = 625 = 25² — bəli.',array['Bəli','Xeyr','Yalnız bərabəryanlıdırsa','Müəyyən etmək olmaz'],1),
('riy8-pifaqor#8','riy-8-pifaqor',3,1,'Kvadratın diaqonalı tərəfindən neçə dəfə böyükdür?','d = a√2 — √2 dəfə böyükdür.',array['√2 dəfə','2 dəfə','4 dəfə','Bərabərdir'],1),
('riy8-pifaqor#9','riy-8-pifaqor',3,1,'Katetləri a olan bərabəryanlı düzbucaqlı üçbucağın hipotenuzu nəyə bərabərdir?','c = √(a² + a²) = a√2.',array['a√2','2a','a²','a/2'],1),
('riy8-pifaqor#10','riy-8-pifaqor',3,1,'Düzbucaqlının tərəfləri 9 və 12-dirsə, diaqonalı neçədir?','√(81 + 144) = √225 = 15.',array['15','21','13','225'],1),
('riy8-pifaqor#11','riy-8-pifaqor',2,1,'Düzbucaqlı üçbucağın katetləri 8 və 15-dirsə, hipotenuzunu hesablayın.','√(64 + 225) = √289 = 17.',array['17','23','120','289'],1),
('riy8-pifaqor#12','riy-8-pifaqor',3,1,'Hipotenuzu 25, bir kateti 7 olan üçbucağın o biri katetini hesablayın.','√(625 − 49) = √576 = 24.',array['24','18','32','576'],1),
('riy8-pifaqor#13','riy-8-pifaqor',3,1,'Tərəfləri 6, 8 və 11 olan üçbucaq düzbucaqlıdırmı?','6² + 8² = 100, 11² = 121 — bərabər deyil, düzbucaqlı deyil.',array['Xeyr','Bəli','Yalnız bərabəryanlıdırsa','Müəyyən etmək olmaz'],1),
('riy8-pifaqor#14','riy-8-pifaqor',3,1,'Bərabəryanlı düzbucaqlı üçbucağın hipotenuzu 4√2-dirsə, kateti neçədir?','c = a√2 olduğundan a = 4.',array['4','8','4√2','2√2'],1),
('riy8-pifaqor#15','riy-8-pifaqor',2,1,'Pifaqor üçlüyü nədir?','c² = a² + b² şərtini ödəyən üç natural ədəddir (məs. 3, 4, 5).',array['c² = a² + b² şərtini ödəyən üç natural ədəd','İstənilən üç ədəd','Üç cüt ədəd','Üç sadə ədəd'],1),
('riy8-pifaqor#16','riy-8-pifaqor',3,1,'Aşağıdakılardan hansı Pifaqor üçlüyüdür?','8² + 15² = 289 = 17² — Pifaqor üçlüyüdür.',array['8, 15, 17','5, 6, 7','2, 3, 4','10, 11, 12'],1),
('riy8-pifaqor#17','riy-8-pifaqor',3,1,'Kvadratın tərəfi 10-dursa, diaqonalı nəyə bərabərdir?','d = a√2 = 10√2.',array['10√2','20','100','10'],1),
('riy8-pifaqor#18','riy-8-pifaqor',3,1,'Düzbucaqlının eni 12, diaqonalı 20-dirsə, uzunluğunu tapın.','√(400 − 144) = √256 = 16.',array['16','8','32','256'],1),
('riy8-pifaqor#19','riy-8-pifaqor',3,1,'Divara söykənən 5 m-lik nərdivanın aşağı ucu divardan 3 m aralıdır. Nərdivan divarda hansı hündürlüyə çatır?','√(25 − 9) = √16 = 4 m.',array['4 m','2 m','8 m','16 m'],1),
('riy8-pifaqor#20','riy-8-pifaqor',3,1,'Katetləri 20 və 21 olan üçbucağın hipotenuzu neçədir?','√(400 + 441) = √841 = 29.',array['29','41','420','31'],1),
('riy8-kvadrat-tenlik#1','riy-8-kvadrat-tenlik',2,2,'Kvadrat tənliyin ümumi şəkli hansıdır?','ax² + bx + c = 0 (a ≠ 0).',array['ax² + bx + c = 0','ax + b = 0','a/x = b','ax³ = 0'],1),
('riy8-kvadrat-tenlik#2','riy-8-kvadrat-tenlik',2,2,'x² − 9 = 0 tənliyinin kökləri hansılardır?','x² = 9; x = 3 və x = −3.',array['3 və −3','Yalnız 3','9 və −9','Kökü yoxdur'],1),
('riy8-kvadrat-tenlik#3','riy-8-kvadrat-tenlik',2,2,'Diskriminant hansı düsturla hesablanır?','D = b² − 4ac.',array['D = b² − 4ac','D = b² + 4ac','D = 2a − b','D = a² − c²'],1),
('riy8-kvadrat-tenlik#4','riy-8-kvadrat-tenlik',3,2,'D < 0 olduqda kvadrat tənliyin neçə həqiqi kökü var?','Mənfi diskriminantda həqiqi kök yoxdur.',array['Həqiqi kökü yoxdur','Bir kökü var','İki kökü var','Sonsuz kökü var'],1),
('riy8-kvadrat-tenlik#5','riy-8-kvadrat-tenlik',3,2,'x² − 5x + 6 = 0 tənliyinin kökləri hansılardır?','Vietaya görə: cəm 5, hasil 6 — köklər 2 və 3.',array['2 və 3','1 və 6','−2 və −3','5 və 6'],1),
('riy8-kvadrat-tenlik#6','riy-8-kvadrat-tenlik',3,2,'x² + 4x = 0 tənliyini həll edin.','x(x + 4) = 0; x = 0 və x = −4.',array['0 və −4','Yalnız −4','0 və 4','2 və −2'],1),
('riy8-kvadrat-tenlik#7','riy-8-kvadrat-tenlik',3,2,'D = 0 olduqda tənliyin neçə kökü olur?','Bir (ikiqat) kök olur.',array['Bir (ikiqat) kök','İki müxtəlif kök','Kök olmur','Üç kök'],1),
('riy8-kvadrat-tenlik#8','riy-8-kvadrat-tenlik',3,2,'x² + px + q = 0 tənliyində köklərin cəmi nəyə bərabərdir?','Viet teoreminə görə cəm −p-yə bərabərdir.',array['−p','p','q','−q'],1),
('riy8-kvadrat-tenlik#9','riy-8-kvadrat-tenlik',3,2,'x² = 11x tənliyinin sıfırdan fərqli kökü neçədir?','x(x − 11) = 0; sıfırdan fərqli kök 11-dir.',array['11','−11','121','1'],1),
('riy8-kvadrat-tenlik#10','riy-8-kvadrat-tenlik',2,2,'2x² − 8 = 0 tənliyinin müsbət kökü neçədir?','x² = 4; müsbət kök 2.',array['2','4','8','16'],1),
('riy8-kvadrat-tenlik#11','riy-8-kvadrat-tenlik',2,2,'x² = 49 tənliyini həll edin.','x = 7 və x = −7.',array['7 və −7','Yalnız 7','49 və −49','Kökü yoxdur'],1),
('riy8-kvadrat-tenlik#12','riy-8-kvadrat-tenlik',2,2,'Diskriminant müsbət olduqda tənliyin kökləri haqqında nə demək olar?','D > 0 olduqda iki müxtəlif həqiqi kök var.',array['İki müxtəlif həqiqi kökü var','Kökü yoxdur','Bir kökü var','Sonsuz kökü var'],1),
('riy8-kvadrat-tenlik#13','riy-8-kvadrat-tenlik',3,2,'Viet teoreminə görə x² + px + q = 0 tənliyində köklərin hasili nəyə bərabərdir?','Hasil q-yə bərabərdir.',array['q','−q','p','−p'],1),
('riy8-kvadrat-tenlik#14','riy-8-kvadrat-tenlik',3,2,'x² − 7x + 10 = 0 tənliyinin kökləri hansılardır?','Cəmi 7, hasili 10 olan ədədlər: 2 və 5.',array['2 və 5','1 və 10','−2 və −5','3 və 4'],1),
('riy8-kvadrat-tenlik#15','riy-8-kvadrat-tenlik',2,2,'Hansı tənliyin kökləri 10 və −10-dur?','x² − 100 = 0 tənliyinin kökləri ±10-dur.',array['x² − 100 = 0','x² + 100 = 0','x² − 10 = 0','x + 10 = 0'],1),
('riy8-kvadrat-tenlik#16','riy-8-kvadrat-tenlik',3,2,'x² + 6x + 9 = 0 tənliyinin neçə kökü var?','D = 36 − 36 = 0 — bir (ikiqat) kök.',array['Bir (ikiqat) kök','İki müxtəlif kök','Kök yoxdur','Üç kök'],1),
('riy8-kvadrat-tenlik#17','riy-8-kvadrat-tenlik',2,2,'Kvadrat tənlikdə a əmsalı hansı şərti ödəməlidir?','a = 0 olsa tənlik xətti olar; a ≠ 0 olmalıdır.',array['a ≠ 0','a > 0','a = 1','a < 0'],1),
('riy8-kvadrat-tenlik#18','riy-8-kvadrat-tenlik',3,2,'x² − 18x + 77 = 0 tənliyinin köklərinin cəmi neçədir?','Viet teoreminə görə cəm 18-dir.',array['18','77','−18','9'],1),
('riy8-kvadrat-tenlik#19','riy-8-kvadrat-tenlik',2,2,'Aşağıdakılardan hansı natamam kvadrat tənlikdir?','c əmsalı sıfırdır: x² − 5x = 0 natamamdır.',array['x² − 5x = 0','x² + 3x + 2 = 0','x² − x + 1 = 0','2x + 1 = 0'],1),
('riy8-kvadrat-tenlik#20','riy-8-kvadrat-tenlik',2,2,'Kökləri 4 və 6 olan kvadrat tənlikdə köklərin hasili neçədir?','4 · 6 = 24.',array['24','10','46','2'],1),
('riy8-dordbucaqlilar#1','riy-8-dordbucaqlilar',2,2,'Paraleloqramın qarşı tərəfləri necədir?','Qarşı tərəflər paralel və bərabərdir.',array['Paralel və bərabərdir','Perpendikulyar','Həmişə fərqlidir','Kəsişir'],1),
('riy8-dordbucaqlilar#2','riy-8-dordbucaqlilar',2,2,'Rombun bütün tərəfləri haqqında nə demək olar?','Rombda bütün tərəflər bərabərdir.',array['Bərabərdir','Fərqlidir','Paralel deyil','Ölçüsüzdür'],1),
('riy8-dordbucaqlilar#3','riy-8-dordbucaqlilar',2,2,'Dördbucaqlının daxili bucaqlarının cəmi neçədir?','Dördbucaqlıda bucaqların cəmi 360°-dir.',array['360°','180°','90°','540°'],1),
('riy8-dordbucaqlilar#4','riy-8-dordbucaqlilar',3,2,'Paraleloqramın diaqonalları kəsişmə nöqtəsində nə edir?','Diaqonallar yarıya bölünür.',array['Yarıya bölünür','Perpendikulyar olur','Kəsişmir','Bərabərləşir'],1),
('riy8-dordbucaqlilar#5','riy-8-dordbucaqlilar',3,2,'Rombun diaqonalları bir-birinə necədir?','Diaqonallar perpendikulyardır və yarıya bölünür.',array['Perpendikulyardır','Paraleldir','Bərabərdir həmişə','Kəsişmir'],1),
('riy8-dordbucaqlilar#6','riy-8-dordbucaqlilar',2,2,'Trapesiyanın hansı tərəfləri paraleldir?','Oturacaqları paraleldir.',array['Oturacaqları','Yan tərəfləri','Bütün tərəfləri','Heç biri'],1),
('riy8-dordbucaqlilar#7','riy-8-dordbucaqlilar',3,2,'Kvadrat hansı fiqurların xüsusi halıdır?','Kvadrat həm düzbucaqlı, həm də rombdur.',array['Düzbucaqlının və rombun','Yalnız trapesiyanın','Yalnız üçbucağın','Dairənin'],1),
('riy8-dordbucaqlilar#8','riy-8-dordbucaqlilar',3,2,'Düzbucaqlının diaqonalları haqqında nə demək olar?','Düzbucaqlının diaqonalları bərabərdir.',array['Bərabərdirlər','Perpendikulyardırlar həmişə','Kəsişmirlər','Tərəfə bərabərdirlər'],1),
('riy8-dordbucaqlilar#9','riy-8-dordbucaqlilar',3,2,'Trapesiyanın orta xətti nəyə bərabərdir?','Oturacaqların cəminin yarısına.',array['Oturacaqlar cəminin yarısına','Yan tərəflərin cəminə','Hündürlüyə','Perimetrə'],1),
('riy8-dordbucaqlilar#10','riy-8-dordbucaqlilar',3,2,'Paraleloqramın qonşu bucaqlarının cəmi neçədir?','Qonşu bucaqların cəmi 180°-dir.',array['180°','90°','360°','60°'],1),
('riy8-dordbucaqlilar#11','riy-8-dordbucaqlilar',2,2,'Paraleloqramın qarşı bucaqları haqqında nə demək olar?','Qarşı bucaqlar bərabərdir.',array['Cüt-cüt bərabərdir','Cəmi 90°-dir','Həmişə itidir','Fərqlidir'],1),
('riy8-dordbucaqlilar#12','riy-8-dordbucaqlilar',2,2,'Yan tərəfləri bərabər olan trapesiya necə adlanır?','Bərabəryanlı trapesiya.',array['Bərabəryanlı trapesiya','Düzbucaqlı trapesiya','Paraleloqram','Romb'],1),
('riy8-dordbucaqlilar#13','riy-8-dordbucaqlilar',2,2,'Perimetri 72 olan kvadratın tərəfi neçədir?','72 : 4 = 18.',array['18','36','9','24'],1),
('riy8-dordbucaqlilar#14','riy-8-dordbucaqlilar',3,2,'Rombun diaqonalları onun bucaqlarını necə bölür?','Diaqonallar bucaqları yarıya bölür (bissektrisadır).',array['Yarıya bölür (bissektrisadır)','Üç yerə bölür','Bölmür','İxtiyari bölür'],1),
('riy8-dordbucaqlilar#15','riy-8-dordbucaqlilar',1,2,'Düzbucaqlının hər bucağı neçə dərəcədir?','Düzbucaqlıda bütün bucaqlar 90°-dir.',array['90°','60°','120°','45°'],1),
('riy8-dordbucaqlilar#16','riy-8-dordbucaqlilar',3,2,'Paraleloqramın diaqonalı onu hansı fiqurlara bölür?','Diaqonal paraleloqramı iki bərabər üçbucağa bölür.',array['İki bərabər üçbucağa','İki kvadrata','Dörd rombа','İki trapesiyaya'],1),
('riy8-dordbucaqlilar#17','riy-8-dordbucaqlilar',3,2,'Kvadratın diaqonalları haqqında hansı fikir doğrudur?','Kvadratda diaqonallar həm bərabərdir, həm perpendikulyardır.',array['Bərabər və perpendikulyardır','Yalnız bərabərdir','Yalnız perpendikulyardır','Kəsişmir'],1),
('riy8-dordbucaqlilar#18','riy-8-dordbucaqlilar',2,2,'Hansı dördbucaqlının yalnız bir cüt paralel tərəfi var?','Trapesiyanın yalnız oturacaqları paraleldir.',array['Trapesiya','Paraleloqram','Kvadrat','Romb'],1),
('riy8-dordbucaqlilar#19','riy-8-dordbucaqlilar',2,2,'Paraleloqramın tərəfləri 6 və 9-dursa, perimetri neçədir?','P = 2 · (6 + 9) = 30.',array['30','15','54','60'],1),
('riy8-dordbucaqlilar#20','riy-8-dordbucaqlilar',2,2,'Tərəfi 7 olan rombun perimetri neçədir?','P = 4 · 7 = 28.',array['28','14','49','21'],1),
('riy8-rasional-ifade#1','riy-8-rasional-ifade',2,2,'Rasional kəsrin məxrəci hansı qiyməti ala bilməz?','Məxrəc sıfır ola bilməz.',array['Sıfır','Bir','Mənfi ədəd','Kəsr'],1),
('riy8-rasional-ifade#2','riy-8-rasional-ifade',2,2,'x/(x − 3) ifadəsi x-in hansı qiymətində mənasızdır?','x = 3 olduqda məxrəc sıfırdır.',array['x = 3','x = 0','x = −3','Həmişə mənalıdır'],1),
('riy8-rasional-ifade#3','riy-8-rasional-ifade',3,2,'Qüvvətin qüvvəti qaydası ilə (a²)³ neçə olar?','Qüvvətin qüvvəti: üstlər vurulur — a⁶.',array['a⁶','a⁵','a⁸','a⁹'],1),
('riy8-rasional-ifade#4','riy-8-rasional-ifade',2,2,'6x² : (2x) ifadəsini sadələşdirin.','6 : 2 = 3; x² : x = x — nəticə 3x.',array['3x','3x²','4x','12x'],1),
('riy8-rasional-ifade#5','riy-8-rasional-ifade',3,2,'1/a + 1/b cəmi nəyə bərabərdir?','Ortaq məxrəc ab: (a + b)/(ab).',array['(a + b)/(ab)','2/(a + b)','1/(a + b)','(a·b)/(a+b)'],1),
('riy8-rasional-ifade#6','riy-8-rasional-ifade',2,2,'Kəsri ixtisar etmək nə deməkdir?','Surət və məxrəci eyni ifadəyə bölmək.',array['Surət və məxrəci eyni ifadəyə bölmək','Kəsri silmək','Məxrəci atmaq','Kəsri çevirmək'],1),
('riy8-rasional-ifade#7','riy-8-rasional-ifade',3,2,'x² − 4 kəsri x − 2 ifadəsinə bölünsə nə alınar? (x ≠ 2)','x² − 4 = (x − 2)(x + 2); nəticə x + 2.',array['x + 2','x − 2','x + 4','x² − 2'],1),
('riy8-rasional-ifade#8','riy-8-rasional-ifade',2,2,'a⁰ nəyə bərabərdir? (a ≠ 0)','Sıfırıncı qüvvət 1-ə bərabərdir.',array['1','0','a','−1'],1),
('riy8-rasional-ifade#9','riy-8-rasional-ifade',3,2,'Mənfi qüvvət qaydasına görə a⁻¹ necə yazılır?','Mənfi birinci qüvvət tərs ədəddir: 1/a.',array['1/a','−a','a','0'],1),
('riy8-rasional-ifade#10','riy-8-rasional-ifade',3,2,'(2x)³ neçə olar?','2³ · x³ = 8x³.',array['8x³','6x³','2x³','8x'],1),
('riy8-rasional-ifade#11','riy-8-rasional-ifade',2,2,'a⁴ · a³ hasili neçə olar?','Eyni əsaslı qüvvətlər vurulanda üstlər toplanır: a⁷.',array['a⁷','a¹²','a¹','2a⁷'],1),
('riy8-rasional-ifade#12','riy-8-rasional-ifade',2,2,'a⁸ : a² bölməsinin nəticəsi hansı qüvvətdir?','Bölmədə üstlər çıxılır: a⁶.',array['a⁶','a⁴','a¹⁰','a¹⁶'],1),
('riy8-rasional-ifade#13','riy-8-rasional-ifade',2,2,'3x ifadəsinin kvadratı neçədir?','(3x)² = 9x².',array['9x²','3x²','6x²','9x'],1),
('riy8-rasional-ifade#14','riy-8-rasional-ifade',3,2,'10x⁵ kəsri 5x²-yə bölündükdə nə alınar?','10 : 5 = 2, x⁵ : x² = x³ — nəticə 2x³.',array['2x³','5x³','2x⁷','15x³'],1),
('riy8-rasional-ifade#15','riy-8-rasional-ifade',2,2,'5/(x + 7) kəsrinin məxrəcini sıfır edən qiymət hansıdır?','x + 7 = 0, yəni x = −7.',array['x = −7','x = 7','x = 5','x = 0'],1),
('riy8-rasional-ifade#16','riy-8-rasional-ifade',3,2,'Fərqin kvadratı (a − b)² necə açılır?','Fərqin kvadratı: a² − 2ab + b².',array['a² − 2ab + b²','a² + b²','a² − b²','a² + 2ab − b²'],1),
('riy8-rasional-ifade#17','riy-8-rasional-ifade',3,2,'(a + b)(a − b) hasili nəyə bərabərdir?','Kvadratlar fərqi: a² − b².',array['a² − b²','a² + b²','(a + b)²','2a − 2b'],1),
('riy8-rasional-ifade#18','riy-8-rasional-ifade',3,2,'x² − 25 ifadəsini vuruqlara ayırıb (x + 5)-ə bölsək nə alınar?','x² − 25 = (x + 5)(x − 5); nəticə x − 5.',array['x − 5','x + 5','x − 25','5 − x'],1),
('riy8-rasional-ifade#19','riy-8-rasional-ifade',2,2,'Kəsrin surətini və məxrəcini eyni sıfırdan fərqli ifadəyə vursaq kəsr necə dəyişər?','Kəsrin qiyməti dəyişməz — əsas xassə.',array['Dəyişməz','İki dəfə artar','Sıfır olar','Tərsinə çevrilər'],1),
('riy8-rasional-ifade#20','riy-8-rasional-ifade',2,2,'2/x + 3/x cəmini hesablayın.','Məxrəclər eynidir: (2 + 3)/x = 5/x.',array['5/x','6/x','5/2x','6/x²'],1),
('riy8-sahe#1','riy-8-sahe',3,3,'Rombun diaqonalları 14 və 4 olarsa, sahəsi neçədir?','S = (14 · 4) : 2 = 28.',array['28','56','18','112'],1),
('riy8-sahe#2','riy-8-sahe',2,3,'Tərəfi 9 sm olan kvadratın sahəsi neçədir?','S = 9² = 81 sm².',array['81 sm²','36 sm²','18 sm²','27 sm²'],1),
('riy8-sahe#3','riy-8-sahe',2,3,'Üçbucağın sahə düsturu hansıdır?','S = (oturacaq · hündürlük) : 2.',array['S = (a · h) : 2','S = a · h','S = a + h','S = 2(a + h)'],1),
('riy8-sahe#4','riy-8-sahe',2,3,'Paraleloqramın oturacağı 7, hündürlüyü 8 olarsa, sahəsi neçədir?','S = 7 · 8 = 56.',array['56','28','15','30'],1),
('riy8-sahe#5','riy-8-sahe',3,3,'Oturacaqları 5 və 9, hündürlüyü 6 olan trapesiyanın sahəsini tapın.','S = (5 + 9) : 2 · 6 = 42.',array['42','84','20','70'],1),
('riy8-sahe#6','riy-8-sahe',2,3,'Katetləri 10 və 7 olan düzbucaqlı üçbucağın sahəsi neçədir?','S = (10 · 7) : 2 = 35.',array['35','70','17','34'],1),
('riy8-sahe#7','riy-8-sahe',3,3,'Çevrənin uzunluğu hansı düsturla tapılır?','C = 2πr.',array['C = 2πr','C = πr²','C = 4πr','C = r²'],1),
('riy8-sahe#8','riy-8-sahe',3,3,'Dairənin sahəsi hansı düsturla hesablanır?','S = πr².',array['S = πr²','S = 2πr','S = πd','S = r³'],1),
('riy8-sahe#9','riy-8-sahe',3,3,'Radiusu 10 olan dairənin sahəsi neçə π-dir?','S = π · 10² = 100π.',array['100π','20π','10π','1000π'],1),
('riy8-sahe#10','riy-8-sahe',2,3,'Fiqur iki hissəyə bölünərsə, sahəsi necə tapılır?','Hissələrin sahələrinin cəmi kimi.',array['Hissələrin sahələri cəmi kimi','Hissələrin fərqi kimi','Böyük hissəyə görə','Tapılmır'],1),
('riy8-sahe#11','riy-8-sahe',2,3,'Tərəfləri 8 və 12 olan düzbucaqlının sahəsi neçədir?','S = 8 · 12 = 96.',array['96','40','20','48'],1),
('riy8-sahe#12','riy-8-sahe',3,3,'Radiusu 6 olan çevrənin uzunluğu neçə π-dir?','C = 2π · 6 = 12π.',array['12π','36π','6π','3π'],1),
('riy8-sahe#13','riy-8-sahe',2,3,'Oturacağı 12, hündürlüyü 9 olan üçbucağın sahəsini hesablayın.','S = (12 · 9) : 2 = 54.',array['54','108','21','42'],1),
('riy8-sahe#14','riy-8-sahe',3,3,'Diaqonalları 10 və 12 olan rombun sahəsi neçədir?','S = (10 · 12) : 2 = 60.',array['60','120','22','44'],1),
('riy8-sahe#15','riy-8-sahe',2,3,'Sahəsi 121 sm² olan kvadratın tərəfinin uzunluğunu tapın.','a² = 121, a = 11 sm.',array['11 sm','22 sm','60,5 sm','121 sm'],1),
('riy8-sahe#16','riy-8-sahe',3,3,'Dairənin radiusu 5 vahiddirsə, sahəsi π ilə necə ifadə olunur?','S = π · 5² = 25π.',array['25π','10π','5π','125π'],1),
('riy8-sahe#17','riy-8-sahe',2,3,'Paraleloqramın sahə düsturu hansıdır?','S = oturacaq · hündürlük.',array['S = a · h','S = (a · h) : 2','S = a + h','S = 4a'],1),
('riy8-sahe#18','riy-8-sahe',3,3,'Trapesiyanın sahəsi hansı düsturla hesablanır?','Oturacaqların cəminin yarısı hündürlüyə vurulur.',array['S = (a + b) : 2 · h','S = a · b · h','S = 2(a + b)','S = a² + b²'],1),
('riy8-sahe#19','riy-8-sahe',3,3,'Kvadratın perimetri 40-dırsa, sahəsi neçədir?','Tərəf 40 : 4 = 10; S = 100.',array['100','80','1600','40'],1),
('riy8-sahe#20','riy-8-sahe',2,3,'Eni 4 m, uzunluğu 15 m olan otağın sahəsi neçə kvadratmetrdir?','S = 4 · 15 = 60 m².',array['60 m²','19 m²','38 m²','120 m²'],1),
('riy8-rasional-tenlik#1','riy-8-rasional-tenlik',2,3,'Rasional tənlik hansı tənlikdir?','Rasional ifadələrdən ibarət tənlikdir.',array['Rasional ifadələrdən ibarət tənlik','Yalnız kvadrat tənlik','Köklü tənlik','Bərabərsizlik'],1),
('riy8-rasional-tenlik#2','riy-8-rasional-tenlik',3,3,'x/(x − 1) = 0 tənliyinin kökü neçədir?','Kəsr sıfırdır — surət sıfır olmalıdır: x = 0.',array['0','1','−1','Kökü yoxdur'],1),
('riy8-rasional-tenlik#3','riy-8-rasional-tenlik',3,3,'Rasional tənliyi həll edərkən nəyi yoxlamaq vacibdir?','Məxrəci sıfır edən qiymətlər kök ola bilməz.',array['Məxrəci sıfır edən qiymətləri','Surəti','Tənliyin uzunluğunu','Heç nəyi'],1),
('riy8-rasional-tenlik#4','riy-8-rasional-tenlik',2,3,'12/x = 4 tənliyinin kökü neçədir?','x = 12 : 4 = 3.',array['3','48','8','4'],1),
('riy8-rasional-tenlik#5','riy-8-rasional-tenlik',2,3,'(x + 2)/5 = 2 tənliyini həll edin.','x + 2 = 10; x = 8.',array['8','12','0','10'],1),
('riy8-rasional-tenlik#6','riy-8-rasional-tenlik',2,3,'1/x = 1/9 tənliyinin kökü neçədir?','Kəsrlər bərabərdirsə, məxrəclər bərabərdir: x = 9.',array['9','1/9','−9','3'],1),
('riy8-rasional-tenlik#7','riy-8-rasional-tenlik',3,3,'Kənar kök nədir?','Çevirmələr zamanı alınan, lakin tənliyi ödəməyən kökdür.',array['Tənliyi ödəməyən alınmış kök','Ən böyük kök','Mənfi kök','İlk tapılan kök'],1),
('riy8-rasional-tenlik#8','riy-8-rasional-tenlik',3,3,'x/2 + x/3 = 5 tənliyinin kökü neçədir?','Ortaq məxrəc 6: 3x + 2x = 30; x = 6.',array['6','5','30','12'],1),
('riy8-rasional-tenlik#9','riy-8-rasional-tenlik',3,3,'20/x = x/5 tənliyinin müsbət kökü neçədir?','x² = 100; müsbət kök 10.',array['10','100','4','25'],1),
('riy8-rasional-tenlik#10','riy-8-rasional-tenlik',3,3,'Tənliyin iki tərəfini məxrəcə vuranda nə nəzərə alınmalıdır?','Məxrəcin sıfırdan fərqli olması.',array['Məxrəcin sıfır olmaması','Surətin böyüklüyü','Kökün işarəsi','Heç nə'],1),
('riy8-rasional-tenlik#11','riy-8-rasional-tenlik',2,3,'42/x = 2 tənliyində x neçəyə bərabərdir?','x = 42 : 2 = 21.',array['21','84','40','44'],1),
('riy8-rasional-tenlik#12','riy-8-rasional-tenlik',2,3,'x-in dörddə biri 9-a bərabərdirsə, x neçədir?','x/4 = 9; x = 36.',array['36','13','5','2,25'],1),
('riy8-rasional-tenlik#13','riy-8-rasional-tenlik',2,3,'(x − 4)/3 = 9 tənliyinin kökü neçədir?','x − 4 = 27; x = 31.',array['31','23','27','39'],1),
('riy8-rasional-tenlik#14','riy-8-rasional-tenlik',3,3,'1/x = 0,04 bərabərliyində x-i tapın.','x = 1 : 0,04 = 25.',array['25','0,04','4','40'],1),
('riy8-rasional-tenlik#15','riy-8-rasional-tenlik',3,3,'x/7 = 28/x tənliyinin müsbət kökü neçədir?','x² = 196; müsbət kök 14.',array['14','196','4','35'],1),
('riy8-rasional-tenlik#16','riy-8-rasional-tenlik',3,3,'10/(x − 18) = 2 tənliyinin kökü neçədir?','x − 18 = 5; x = 23.',array['23','13','28','20'],1),
('riy8-rasional-tenlik#17','riy-8-rasional-tenlik',3,3,'1/(x − 6) = 4 tənliyində hansı qiymət kök ola bilməz?','x = 6 məxrəci sıfır edir.',array['x = 6','x = 4','x = 0','x = −6'],1),
('riy8-rasional-tenlik#18','riy-8-rasional-tenlik',3,3,'x/3 − x/4 = 5 tənliyinin kökü neçədir?','Ortaq məxrəc 12: 4x − 3x = 60; x = 60.',array['60','35','5','12'],1),
('riy8-rasional-tenlik#19','riy-8-rasional-tenlik',2,3,'x : 5 = 8 : 2 nisbətindən x-i tapın.','x = 5 · 8 : 2 = 20.',array['20','80','13','11'],1),
('riy8-rasional-tenlik#20','riy-8-rasional-tenlik',3,3,'Tənliyin hər iki tərəfini (x − 1)-ə vurduqda hansı şərt qoyulmalıdır?','x − 1 sıfır olmamalıdır: x ≠ 1.',array['x ≠ 1','x > 1','x = 1','Şərt lazım deyil'],1),
('riy8-oxsarliq#1','riy-8-oxsarliq',2,3,'Oxşar fiqurlar necə fiqurlardır?','Formaca eyni, ölçüləri mütənasib fiqurlardır.',array['Formaca eyni, ölçücə mütənasib','Tamamilə eyni','Sahəcə bərabər','Həmişə konqruyent'],1),
('riy8-oxsarliq#2','riy-8-oxsarliq',3,3,'Oxşarlıq əmsalı nədir?','Uyğun tərəflərin nisbətidir.',array['Uyğun tərəflərin nisbəti','Bucaqların cəmi','Sahələrin fərqi','Perimetrlərin hasili'],1),
('riy8-oxsarliq#3','riy-8-oxsarliq',2,3,'Oxşar üçbucaqların uyğun bucaqları necədir?','Uyğun bucaqlar bərabərdir.',array['Bərabərdir','Mütənasibdir','Fərqlidir','Cəmi 90°-dir'],1),
('riy8-oxsarliq#4','riy-8-oxsarliq',3,3,'Oxşarlıq əmsalı 3 olarsa, sahələrin nisbəti neçədir?','Sahələr k² kimi nisbətdədir: 9.',array['9','3','6','27'],1),
('riy8-oxsarliq#5','riy-8-oxsarliq',3,3,'Üçbucaqların oxşarlıq əlamətlərindən biri hansıdır?','İki bucağa görə oxşarlıq.',array['İki bucağa görə','Perimetrə görə','Sahəyə görə','Rəngə görə'],1),
('riy8-oxsarliq#6','riy-8-oxsarliq',3,3,'Xəritə oxşarlığın hansı tətbiqidir?','Ərazinin kiçildilmiş oxşar təsviridir.',array['Ərazinin kiçildilmiş oxşarı','Böyüdülmüş şəkil','Təsadüfi çertyoj','Oxşarlıqla bağlı deyil'],1),
('riy8-oxsarliq#7','riy-8-oxsarliq',3,3,'Tərəfləri 2 dəfə böyüdülən kvadratın sahəsi neçə dəfə artar?','Sahə k² dəfə artır: 4 dəfə.',array['4','2','8','16'],1),
('riy8-oxsarliq#8','riy-8-oxsarliq',3,3,'Oxşar üçbucaqlarda perimetrlərin nisbəti nəyə bərabərdir?','Oxşarlıq əmsalına bərabərdir.',array['Oxşarlıq əmsalına','Əmsalın kvadratına','Həmişə 1-ə','Sahələr nisbətinə'],1),
('riy8-oxsarliq#9','riy-8-oxsarliq',3,3,'△ABC ~ △DEF və AB/DE = 1/2 olarsa, hansı üçbucaq böyükdür?','AB tərəfi DE-nin yarısıdır — DEF böyükdür.',array['DEF','ABC','Bərabərdirlər','Bilmək olmaz'],1),
('riy8-oxsarliq#10','riy-8-oxsarliq',2,3,'Gündəlik həyatda oxşar fiqurlara misal hansıdır?','Fotonun müxtəlif ölçülü çapları oxşar fiqurlardır.',array['Fotonun böyüdülmüş çapı','İki fərqli formalı daş','Kvadrat və dairə','Hərflər'],1),
('riy8-oxsarliq#11','riy-8-oxsarliq',3,3,'İki oxşar fiqurda əmsal k = 5-dirsə, sahələr hansı nisbətdədir?','Sahələr k² nisbətindədir: 25 : 1.',array['25 : 1','5 : 1','10 : 1','125 : 1'],1),
('riy8-oxsarliq#12','riy-8-oxsarliq',3,3,'Üç tərəfə görə oxşarlıq əlaməti nəyi tələb edir?','Uyğun tərəflərin mütənasib olmasını.',array['Uyğun tərəflərin mütənasibliyini','Bucaqların cəmini','Sahələrin bərabərliyini','Perimetrlərin bərabərliyini'],1),
('riy8-oxsarliq#13','riy-8-oxsarliq',3,3,'k = 3 və kiçik üçbucağın perimetri 12-dirsə, böyük üçbucağın perimetri neçədir?','Perimetr əmsala mütənasibdir: 12 · 3 = 36.',array['36','15','108','4'],1),
('riy8-oxsarliq#14','riy-8-oxsarliq',3,3,'Xəritədə 1 : 1000000 miqyası nəyi göstərir?','Xəritədəki 1 sm yerdə 10 km-ə uyğundur.',array['1 sm-in 10 km-ə uyğun olduğunu','1 sm-in 1 m-ə uyğun olduğunu','Xəritənin köhnə olduğunu','Ərazinin sahəsini'],1),
('riy8-oxsarliq#15','riy-8-oxsarliq',2,3,'Oxşar fiqurların uyğun tərəfləri 4 : 7 nisbətindədirsə, oxşarlıq əmsalı neçədir?','Əmsal tərəflərin nisbətidir: 4/7.',array['4/7','7/4','28','3/7'],1),
('riy8-oxsarliq#16','riy-8-oxsarliq',2,3,'İki kvadrat həmişə oxşardırmı?','Bəli — bütün kvadratlar formaca eynidir.',array['Bəli','Xeyr','Yalnız bərabərdirsə','Yalnız kiçikdirsə'],1),
('riy8-oxsarliq#17','riy-8-oxsarliq',3,3,'Bucaqları 90°, 60° və 30° olan bütün üçbucaqlar bir-birinə necədir?','Bucaqları eyni olan üçbucaqlar oxşardır.',array['Oxşardır','Bərabərdir','Perpendikulyardır','Paraleldir'],1),
('riy8-oxsarliq#18','riy-8-oxsarliq',3,3,'Oxşarlıq əmsalı 1 olan fiqurlar necə adlanır?','k = 1 olduqda fiqurlar bərabərdir (konqruyentdir).',array['Bərabər (konqruyent) fiqurlar','Simmetrik fiqurlar','Perpendikulyar fiqurlar','Qeyri-oxşar fiqurlar'],1),
('riy8-oxsarliq#19','riy-8-oxsarliq',3,3,'Kölgə üsulu ilə hündürlük ölçmək nəyə əsaslanır?','Cisim və kölgəsinin yaratdığı üçbucaqların oxşarlığına.',array['Üçbucaqların oxşarlığına','Pifaqor teoreminə','Çevrənin uzunluğuna','Simmetriyaya'],1),
('riy8-oxsarliq#20','riy-8-oxsarliq',3,3,'AB = 6, KL = 18 olarsa, KLM üçbucağının ABC-yə oxşarlıq əmsalı hansıdır?','k = 18 : 6 = 3.',array['k = 3','k = 12','k = 1/2','k = 24'],1),
('riy8-berabersizlik#1','riy-8-berabersizlik',2,4,'x + 5 > 9 bərabərsizliyinin həlli hansıdır?','x > 9 − 5 = 4.',array['x > 4','x < 4','x > 14','x = 4'],1),
('riy8-berabersizlik#2','riy-8-berabersizlik',3,4,'Bərabərsizliyin iki tərəfi mənfi ədədə vurulanda nə baş verir?','Bərabərsizlik işarəsi əksinə dəyişir.',array['İşarə əksinə dəyişir','İşarə dəyişmir','Bərabərlik alınır','Həll itir'],1),
('riy8-berabersizlik#3','riy-8-berabersizlik',2,4,'2x < 10 bərabərsizliyini həll edin.','x < 10 : 2 = 5.',array['x < 5','x > 5','x < 20','x = 5'],1),
('riy8-berabersizlik#4','riy-8-berabersizlik',3,4,'−3x > 12 bərabərsizliyinin həlli hansıdır?','Mənfiyə bölərkən işarə dəyişir: x < −4.',array['x < −4','x > −4','x < 4','x > 4'],1),
('riy8-berabersizlik#5','riy-8-berabersizlik',3,4,'x ≥ 2 həlləri ədəd oxunda necə göstərilir?','2 nöqtəsi daxil olmaqla sağa yönəlmiş şüa.',array['2-dən sağa şüa (2 daxil)','2-dən sola şüa','Yalnız 2 nöqtəsi','Bütün ox'],1),
('riy8-berabersizlik#6','riy-8-berabersizlik',2,4,'1 < x < 7 bərabərsizliyini ödəyən ən böyük tam ədəd neçədir?','7-dən kiçik ən böyük tam ədəd 6-dır.',array['6','7','5','1'],1),
('riy8-berabersizlik#7','riy-8-berabersizlik',2,4,'a > b və b > c olarsa, a ilə c arasında hansı münasibət var?','Tranzitivlik: a > c.',array['a > c','a < c','a = c','Münasibət yoxdur'],1),
('riy8-berabersizlik#8','riy-8-berabersizlik',2,4,'x − 7 ≤ 0 bərabərsizliyinin həlli hansıdır?','x ≤ 7.',array['x ≤ 7','x ≥ 7','x < 0','x = 7'],1),
('riy8-berabersizlik#9','riy-8-berabersizlik',2,4,'Bərabərsizliyin iki tərəfinə eyni ədəd əlavə edəndə işarə dəyişirmi?','Xeyr — toplama işarəni dəyişmir.',array['Xeyr, dəyişmir','Bəli, həmişə dəyişir','Yalnız mənfidə dəyişir','Bərabərlik olur'],1),
('riy8-berabersizlik#10','riy-8-berabersizlik',3,4,'5 − x > 1 bərabərsizliyini həll edin.','−x > −4; işarə dəyişir: x < 4.',array['x < 4','x > 4','x < −4','x > 6'],1),
('riy8-berabersizlik#11','riy-8-berabersizlik',2,4,'4x ≥ 20 bərabərsizliyinin həlli hansıdır?','x ≥ 20 : 4 = 5.',array['x ≥ 5','x ≤ 5','x ≥ 16','x = 5'],1),
('riy8-berabersizlik#12','riy-8-berabersizlik',2,4,'x + 3 < 1 bərabərsizliyini ödəyən x-lər hansılardır?','x < 1 − 3 = −2.',array['x < −2','x > −2','x < 4','x < 2'],1),
('riy8-berabersizlik#13','riy-8-berabersizlik',3,4,'−5 ≤ x ≤ 10 aralığında neçə tam ədəd var?','−5-dən 10-a qədər: 16 tam ədəd.',array['16','15','10','5'],1),
('riy8-berabersizlik#14','riy-8-berabersizlik',2,4,'2 < x < 6 bərabərsizliyini ödəyən tam ədədlər hansılardır?','Aralıqdakı tamlar: 3, 4 və 5.',array['3, 4 və 5','2, 3, 4, 5 və 6','3 və 4','4 və 5'],1),
('riy8-berabersizlik#15','riy-8-berabersizlik',2,4,'x² ≥ 0 bərabərsizliyi hansı x-lər üçün doğrudur?','İstənilən həqiqi ədədin kvadratı mənfi deyil.',array['Bütün həqiqi ədədlər üçün','Yalnız müsbətlər üçün','Yalnız mənfilər üçün','Heç bir x üçün'],1),
('riy8-berabersizlik#16','riy-8-berabersizlik',3,4,'6 − 2x ≤ 0 bərabərsizliyinin həlli hansıdır?','−2x ≤ −6; mənfiyə bölərkən işarə dəyişir: x ≥ 3.',array['x ≥ 3','x ≤ 3','x ≥ −3','x ≤ −3'],1),
('riy8-berabersizlik#17','riy-8-berabersizlik',2,4,'Bərabərsizliyin hər iki tərəfini müsbət ədədə böləndə işarə necə olur?','Müsbətə bölmə işarəni dəyişmir.',array['Dəyişmir','Əksinə dəyişir','Bərabərlik olur','İtir'],1),
('riy8-berabersizlik#18','riy-8-berabersizlik',2,4,'a < b olarsa, a + 10 ilə b + 10 arasında hansı münasibət olar?','Hər iki tərəfə eyni ədəd əlavə etmək işarəni saxlayır.',array['a + 10 < b + 10','a + 10 > b + 10','a + 10 = b + 10','Müqayisə etmək olmaz'],1),
('riy8-berabersizlik#19','riy-8-berabersizlik',2,4,'x/3 > 2 bərabərsizliyinin həlli hansıdır?','x > 2 · 3 = 6.',array['x > 6','x < 6','x > 2/3','x = 6'],1),
('riy8-berabersizlik#20','riy-8-berabersizlik',2,4,'Ədəd oxunda x < 0 bərabərsizliyi hansı hissəni göstərir?','Sıfırdan solda qalan bütün nöqtələri.',array['Sıfırdan solda qalan hissəni','Sıfırdan sağda qalan hissəni','Yalnız sıfırı','Bütün oxu'],1),
('riy8-triqonometrik#1','riy-8-triqonometrik',3,4,'Düzbucaqlı üçbucaqda bucağın sinusu nəyin nisbətidir?','Qarşı katetin hipotenuza nisbətidir.',array['Qarşı katetin hipotenuza','Bitişik katetin hipotenuza','Hipotenuzun katetə','Katetlərin bir-birinə'],1),
('riy8-triqonometrik#2','riy-8-triqonometrik',3,4,'Kosinus hansı nisbətdir?','Bitişik katetin hipotenuza nisbətidir.',array['Bitişik katetin hipotenuza','Qarşı katetin hipotenuza','Hipotenuzun katetə','Bucağın tərəfə'],1),
('riy8-triqonometrik#3','riy-8-triqonometrik',3,4,'Tangens nəyə bərabərdir?','Qarşı katetin bitişik katetə nisbətinə.',array['Qarşı katetin bitişik katetə nisbətinə','Katetin hipotenuza nisbətinə','Hipotenuzun yarısına','Bucaqların cəminə'],1),
('riy8-triqonometrik#4','riy-8-triqonometrik',3,4,'sin 30° neçəyə bərabərdir?','sin 30° = 1/2.',array['1/2','√3/2','1','√2/2'],1),
('riy8-triqonometrik#5','riy-8-triqonometrik',3,4,'cos 60° neçəyə bərabərdir?','cos 60° = 1/2.',array['1/2','√3/2','0','2'],1),
('riy8-triqonometrik#6','riy-8-triqonometrik',3,4,'tan 45° neçəyə bərabərdir?','45°-də katetlər bərabərdir: tan 45° = 1.',array['1','1/2','√2','0'],1),
('riy8-triqonometrik#7','riy-8-triqonometrik',3,4,'1 − sin²α ifadəsi nəyə bərabərdir?','Əsas eynilikdən: 1 − sin²α = cos²α.',array['cos²α','sin²α','tan²α','0'],1),
('riy8-triqonometrik#8','riy-8-triqonometrik',3,4,'Koordinat başlanğıcından A(6; 8) nöqtəsinə qədər məsafə neçədir?','√(36 + 64) = √100 = 10.',array['10','14','48','100'],1),
('riy8-triqonometrik#9','riy-8-triqonometrik',3,4,'Paralel köçürmə zamanı fiqurun nəyi dəyişmir?','Forması və ölçüləri dəyişmir, yalnız yeri dəyişir.',array['Forması və ölçüləri','Yeri','Hər şeyi dəyişir','Yalnız rəngi'],1),
('riy8-triqonometrik#10','riy-8-triqonometrik',3,4,'Ox simmetriyasında (inikasda) fiqur necə alınır?','Fiqurun güzgü əksi alınır, ölçülər saxlanır.',array['Güzgü əksi alınır','Fiqur böyüyür','Fiqur kiçilir','Fiqur itir'],1),
('riy8-triqonometrik#11','riy-8-triqonometrik',3,4,'30 dərəcəli bucağın kosinusu hansı qiymətə malikdir?','cos 30° = √3/2.',array['√3/2','1/2','√2/2','2'],1),
('riy8-triqonometrik#12','riy-8-triqonometrik',3,4,'sin 45° hansı qiymətə bərabərdir?','sin 45° = √2/2.',array['√2/2','√3/2','1/3','2/√3'],1),
('riy8-triqonometrik#13','riy-8-triqonometrik',3,4,'Əsas triqonometrik eynilik hansıdır?','sin²α + cos²α = 1.',array['sin²α + cos²α = 1','sin α + cos α = 1','sin²α − cos²α = 1','sin α · cos α = 1'],1),
('riy8-triqonometrik#14','riy-8-triqonometrik',3,4,'tan α sinus və kosinus vasitəsilə necə ifadə olunur?','tan α = sin α / cos α.',array['sin α / cos α','cos α / sin α','sin α · cos α','1 / sin α'],1),
('riy8-triqonometrik#15','riy-8-triqonometrik',2,4,'M(9; 23) nöqtəsinin ordinatı neçədir?','İkinci koordinat ordinatdır: 23.',array['23','9','32','14'],1),
('riy8-triqonometrik#16','riy-8-triqonometrik',2,4,'Koordinat müstəvisində oxların kəsişdiyi nöqtə necə adlanır?','Bu, koordinat başlanğıcıdır: O(0; 0).',array['Koordinat başlanğıcı','Absis','Ordinat','Vahid nöqtə'],1),
('riy8-triqonometrik#17','riy-8-triqonometrik',3,4,'Mərkəzi simmetriyada fiqur nəyə nəzərən əks olunur?','Bir nöqtəyə (simmetriya mərkəzinə) nəzərən.',array['Nöqtəyə nəzərən','Düz xəttə nəzərən','Müstəviyə nəzərən','Çevrəyə nəzərən'],1),
('riy8-triqonometrik#18','riy-8-triqonometrik',3,4,'Döndərmə zamanı fiqurun hansı xassəsi saxlanır?','Ölçülər dəyişmir — fiqur konqruyent qalır.',array['Ölçüləri (fiqur konqruyent qalır)','Vəziyyəti','Bucaqları böyüyür','Tərəfləri qısalır'],1),
('riy8-triqonometrik#19','riy-8-triqonometrik',3,4,'B(0; 7) nöqtəsi koordinat müstəvisində harada yerləşir?','Absisi sıfırdır — ordinat oxunun üzərindədir.',array['Ordinat oxunun üzərində','Absis oxunun üzərində','Başlanğıcda','III rübdə'],1),
('riy8-triqonometrik#20','riy-8-triqonometrik',3,4,'Başlanğıcdan C(20; 21) nöqtəsinə qədər məsafəni hesablayın.','√(400 + 441) = √841 = 29.',array['29','41','441','20'],1),
('riy8-ehtimal#1','riy-8-ehtimal',2,4,'Zər atılanda 6 düşməsi ehtimalı neçədir?','Altı üzdən biri: 1/6.',array['1/6','1/2','6','1/3'],1),
('riy8-ehtimal#2','riy-8-ehtimal',3,4,'Kartlar 1-dən 10-a qədər nömrələnib. Təsadüfi kartın 10-a bölünən olması ehtimalı neçədir?','Yalnız 10 uyğundur: 1/10.',array['1/10','1/5','10','1/2'],1),
('riy8-ehtimal#3','riy-8-ehtimal',3,4,'Qutuda 3 ağ və 7 qara kürə var. Ağ kürə çıxarma ehtimalı neçədir?','3/10.',array['3/10','7/10','3/7','1/3'],1),
('riy8-ehtimal#4','riy-8-ehtimal',3,4,'Statistik sıranın amplitudu nədir?','Ən böyük qiymətlə ən kiçiyin fərqidir.',array['Ən böyüklə ən kiçiyin fərqi','Qiymətlərin cəmi','Orta qiymət','Ən çox təkrarlanan'],1),
('riy8-ehtimal#5','riy-8-ehtimal',3,4,'7, 2, 9, 4 sırasının amplitudu neçədir?','9 − 2 = 7.',array['7','9','2','22'],1),
('riy8-ehtimal#6','riy-8-ehtimal',3,4,'Nisbi tezlik necə tapılır?','Hadisənin baş vermə sayı bütün təcrübələrin sayına bölünür.',array['Hadisə sayı təcrübə sayına bölünür','Təcrübə sayı vurulur','Cəm alınır','Fərq alınır'],1),
('riy8-ehtimal#7','riy-8-ehtimal',3,4,'Zərdə 3-ə bölünən ədəd düşməsi ehtimalı neçədir?','Uyğun hallar: 3 və 6 — 2/6 = 1/3.',array['1/3','1/2','1/6','2/3'],1),
('riy8-ehtimal#8','riy-8-ehtimal',3,4,'100 lotereya biletindən 5-i uduşludur. Uduş ehtimalı neçədir?','5/100 = 1/20.',array['1/20','1/5','5','1/100'],1),
('riy8-ehtimal#9','riy-8-ehtimal',3,4,'Bütün mümkün nəticələrin ehtimallarının cəmi nəyə bərabərdir?','Cəm həmişə vahidə (1-ə) bərabərdir.',array['Vahidə (1-ə)','Sıfıra','Yüzə','Nəticədən asılıdır'],1),
('riy8-ehtimal#10','riy-8-ehtimal',2,4,'İki zər atılanda düşən ədədlərin cəmi ən çoxu neçə ola bilər?','6 + 6 = 12.',array['12','6','36','11'],1),
('riy8-ehtimal#11','riy-8-ehtimal',2,4,'Mümkün olmayan hadisənin ehtimalı neçədir?','Baş verə bilməyən hadisənin ehtimalı sıfırdır.',array['0','1','1/2','−1'],1),
('riy8-ehtimal#12','riy-8-ehtimal',2,4,'Yəqin (hökmən baş verən) hadisənin ehtimalı neçədir?','Yəqin hadisənin ehtimalı vahiddir.',array['1 (vahid)','0','1/2','100'],1),
('riy8-ehtimal#13','riy-8-ehtimal',2,4,'Sikkə atılanda gerb düşməsi ehtimalı neçədir?','İki üzdən biri: 0,5.',array['0,5','0,25','1','2'],1),
('riy8-ehtimal#14','riy-8-ehtimal',3,4,'Zər atılanda 5-dən böyük ədəd düşməsi ehtimalı neçədir?','Yalnız 6 uyğundur: 1/6.',array['1/6','5/6','1/5','1/2'],1),
('riy8-ehtimal#15','riy-8-ehtimal',3,4,'Qutuda 4 qırmızı və 6 mavi kürə var. Mavi kürə çıxarma ehtimalı neçədir?','6/10 = 3/5.',array['3/5','2/5','6/4','1/6'],1),
('riy8-ehtimal#16','riy-8-ehtimal',3,4,'10, 20, 26, 30, 44 sırasının medianı neçədir?','Sıralanmış beş ədədin ortadakısı: 26.',array['26','20','30','44'],1),
('riy8-ehtimal#17','riy-8-ehtimal',2,4,'15, 25, 45 və 55 ədədlərinin ədədi ortası neçədir?','(15 + 25 + 45 + 55) : 4 = 140 : 4 = 35.',array['35','45','140','25'],1),
('riy8-ehtimal#18','riy-8-ehtimal',2,4,'Statistik məlumatın modası nədir?','Ən çox təkrarlanan qiymətdir.',array['Ən çox təkrarlanan qiymət','Ən böyük qiymət','Orta qiymət','İlk qiymət'],1),
('riy8-ehtimal#19','riy-8-ehtimal',3,4,'İki sikkə atılanda hər ikisinin gerb düşməsi ehtimalı neçədir?','1/2 · 1/2 = 1/4.',array['1/4','1/2','1/3','2/4'],1),
('riy8-ehtimal#20','riy-8-ehtimal',3,4,'1-dən 30-a qədər nömrələnmiş biletlərdən 7-yə bölünən nömrə çıxma ehtimalı neçədir?','Uyğun nömrələr: 7, 14, 21, 28 — 4/30 = 2/15.',array['2/15','7/30','1/7','4/7'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '8'
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
   where owner_type = 'platform' and ext_key like 'riy8-%';
  if n <> 220 then
    raise exception 'riy8 suallari: 220 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'riy8-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'riy8-%';
  if k <> 11 then
    raise exception 'movzu sayi 11 deyil: %', k;
  end if;
  raise notice 'Riyaziyyat 8 banki: % sual, 11 movzu.', n;
end $$;
