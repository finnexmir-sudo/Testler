-- =====================================================================
--  38_bank_riy8.sql : RIYAZIYYAT 8 PLATFORMA SUAL BANKI (orta mekteb)
--
--  BU FAYL ELLE YAZILMIR - tools/riy8.py yaradir:
--      python3 tools/riy8.py
--
--  11 movzu x 10 sual = 110.  ext_key: riy8-<movzu>#<sira>.
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
('riy8-rasional-ifade#1','riy-8-rasional-ifade',2,2,'Rasional kəsrin məxrəci hansı qiyməti ala bilməz?','Məxrəc sıfır ola bilməz.',array['Sıfır','Bir','Mənfi ədəd','Kəsr'],1),
('riy8-rasional-ifade#2','riy-8-rasional-ifade',2,2,'x/(x − 3) ifadəsi x-in hansı qiymətində mənasızdır?','x = 3 olduqda məxrəc sıfırdır.',array['x = 3','x = 0','x = −3','Həmişə mənalıdır'],1),
('riy8-rasional-ifade#3','riy-8-rasional-ifade',3,2,'(a²)³ neçə olar?','Qüvvətin qüvvəti: üstlər vurulur — a⁶.',array['a⁶','a⁵','a⁸','a⁹'],1),
('riy8-rasional-ifade#4','riy-8-rasional-ifade',2,2,'6x² : (2x) ifadəsini sadələşdirin.','6 : 2 = 3; x² : x = x — nəticə 3x.',array['3x','3x²','4x','12x'],1),
('riy8-rasional-ifade#5','riy-8-rasional-ifade',3,2,'1/a + 1/b cəmi nəyə bərabərdir?','Ortaq məxrəc ab: (a + b)/(ab).',array['(a + b)/(ab)','2/(a + b)','1/(a + b)','(a·b)/(a+b)'],1),
('riy8-rasional-ifade#6','riy-8-rasional-ifade',2,2,'Kəsri ixtisar etmək nə deməkdir?','Surət və məxrəci eyni ifadəyə bölmək.',array['Surət və məxrəci eyni ifadəyə bölmək','Kəsri silmək','Məxrəci atmaq','Kəsri çevirmək'],1),
('riy8-rasional-ifade#7','riy-8-rasional-ifade',3,2,'(x² − 4)/(x − 2) ifadəsini sadələşdirin (x ≠ 2).','x² − 4 = (x − 2)(x + 2); nəticə x + 2.',array['x + 2','x − 2','x + 4','x² − 2'],1),
('riy8-rasional-ifade#8','riy-8-rasional-ifade',2,2,'a⁰ nəyə bərabərdir? (a ≠ 0)','Sıfırıncı qüvvət 1-ə bərabərdir.',array['1','0','a','−1'],1),
('riy8-rasional-ifade#9','riy-8-rasional-ifade',3,2,'Mənfi qüvvət qaydasına görə a⁻¹ necə yazılır?','Mənfi birinci qüvvət tərs ədəddir: 1/a.',array['1/a','−a','a','0'],1),
('riy8-rasional-ifade#10','riy-8-rasional-ifade',3,2,'(2x)³ neçə olar?','2³ · x³ = 8x³.',array['8x³','6x³','2x³','8x'],1),
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
('riy8-ehtimal#1','riy-8-ehtimal',2,4,'Zər atılanda 6 düşməsi ehtimalı neçədir?','Altı üzdən biri: 1/6.',array['1/6','1/2','6','1/3'],1),
('riy8-ehtimal#2','riy-8-ehtimal',3,4,'Kartlar 1-dən 10-a qədər nömrələnib. Təsadüfi kartın 10-a bölünən olması ehtimalı neçədir?','Yalnız 10 uyğundur: 1/10.',array['1/10','1/5','10','1/2'],1),
('riy8-ehtimal#3','riy-8-ehtimal',3,4,'Qutuda 3 ağ və 7 qara kürə var. Ağ kürə çıxarma ehtimalı neçədir?','3/10.',array['3/10','7/10','3/7','1/3'],1),
('riy8-ehtimal#4','riy-8-ehtimal',3,4,'Statistik sıranın amplitudu nədir?','Ən böyük qiymətlə ən kiçiyin fərqidir.',array['Ən böyüklə ən kiçiyin fərqi','Qiymətlərin cəmi','Orta qiymət','Ən çox təkrarlanan'],1),
('riy8-ehtimal#5','riy-8-ehtimal',3,4,'7, 2, 9, 4 sırasının amplitudu neçədir?','9 − 2 = 7.',array['7','9','2','22'],1),
('riy8-ehtimal#6','riy-8-ehtimal',3,4,'Nisbi tezlik necə tapılır?','Hadisənin baş vermə sayı bütün təcrübələrin sayına bölünür.',array['Hadisə sayı təcrübə sayına bölünür','Təcrübə sayı vurulur','Cəm alınır','Fərq alınır'],1),
('riy8-ehtimal#7','riy-8-ehtimal',3,4,'Zərdə 3-ə bölünən ədəd düşməsi ehtimalı neçədir?','Uyğun hallar: 3 və 6 — 2/6 = 1/3.',array['1/3','1/2','1/6','2/3'],1),
('riy8-ehtimal#8','riy-8-ehtimal',3,4,'100 lotereya biletindən 5-i uduşludur. Uduş ehtimalı neçədir?','5/100 = 1/20.',array['1/20','1/5','5','1/100'],1),
('riy8-ehtimal#9','riy-8-ehtimal',3,4,'Bütün mümkün nəticələrin ehtimallarının cəmi nəyə bərabərdir?','Cəm həmişə vahidə (1-ə) bərabərdir.',array['Vahidə (1-ə)','Sıfıra','Yüzə','Nəticədən asılıdır'],1),
('riy8-ehtimal#10','riy-8-ehtimal',2,4,'İki zər atılanda düşən ədədlərin cəmi ən çoxu neçə ola bilər?','6 + 6 = 12.',array['12','6','36','11'],1)
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
  if n <> 110 then
    raise exception 'riy8 suallari: 110 gozlenilirdi, % tapildi', n;
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
