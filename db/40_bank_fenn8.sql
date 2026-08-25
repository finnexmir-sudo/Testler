-- =====================================================================
--  40_bank_fenn8.sql : 8-CI SINIF - FIZIKA, KIMYA, BIOLOGIYA, COGRAFIYA
--
--  BU FAYL ELLE YAZILMIR - tools/fenn8.py yaradir:
--      python3 tools/fenn8.py
--
--  Fizika 8 (6) + Kimya 8 (6) + Biologiya 8 (8) + Cografiya 8 (8)
--  = 28 movzu x 10 = 280.  ext_key: fiz8-/kim8-/bio8-/cog8-...
--  ON SERT: 37_movzular_orta8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('fizika','fiz-8-dalgalar'),
                                ('kimya','kim-8-oksidlesme'),
                                ('biologiya','bio-8-qan-dovrani'),
                                ('cografiya','cog-8-atmosfer'))
     having count(*) = 4) then
    raise exception 'ONCE 37_movzular_orta8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'fiz8-%' or q.ext_key like 'kim8-%'
        or q.ext_key like 'bio8-%' or q.ext_key like 'cog8-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('fiz8-quvve#1','fizika','fiz-8-quvve',1,1,'Qüvvənin BS-də vahidi hansıdır?','Qüvvə nyutonla (N) ölçülür.',array['Nyuton (N)','Coul (J)','Vatt (Vt)','Paskal (Pa)'],1),
('fiz8-quvve#2','fizika','fiz-8-quvve',2,1,'Kütləsi 5 kq olan cismə təsir edən ağırlıq qüvvəsi neçə nyutondur? (g = 10 N/kq)','F = m·g = 5 · 10 = 50 N.',array['50 N','5 N','15 N','500 N'],1),
('fiz8-quvve#3','fizika','fiz-8-quvve',1,1,'Yayın uzanması ilə elastiklik qüvvəsi arasındakı asılılığı hansı qanun ifadə edir?','Huk qanunu: F = k·x.',array['Huk qanunu','Paskal qanunu','Arximed qanunu','Om qanunu'],1),
('fiz8-quvve#4','fizika','fiz-8-quvve',2,1,'Sərtliyi 200 N/m olan yay 0,1 m uzanmışdır. Elastiklik qüvvəsi neçə nyutondur?','F = k·x = 200 · 0,1 = 20 N.',array['20 N','2 N','200 N','2000 N'],1),
('fiz8-quvve#5','fizika','fiz-8-quvve',1,1,'Toxunan səthlər arasında hərəkətə mane olan qüvvə necə adlanır?','Bu, sürtünmə qüvvəsidir.',array['Sürtünmə qüvvəsi','Elastiklik qüvvəsi','Cazibə qüvvəsi','Arximed qüvvəsi'],1),
('fiz8-quvve#6','fizika','fiz-8-quvve',2,1,'Bir düz xətt üzrə əks istiqamətdə təsir edən 30 N və 20 N qüvvələrin əvəzləyicisi neçə nyutondur?','Əks istiqamətdə fərq götürülür: 30 − 20 = 10 N.',array['10 N','50 N','600 N','25 N'],1),
('fiz8-quvve#7','fizika','fiz-8-quvve',2,1,'Eyni istiqamətdə təsir edən 40 N və 25 N qüvvələrin əvəzləyicisi neçə nyutondur?','Eyni istiqamətdə qüvvələr toplanır: 40 + 25 = 65 N.',array['65 N','15 N','40 N','1000 N'],1),
('fiz8-quvve#8','fizika','fiz-8-quvve',1,1,'Yer bütün cisimləri özünə hansı qüvvə ilə çəkir?','Bu, cazibə (qravitasiya) qüvvəsidir.',array['Cazibə qüvvəsi','Sürtünmə qüvvəsi','Elastiklik qüvvəsi','Maqnit qüvvəsi'],1),
('fiz8-quvve#9','fizika','fiz-8-quvve',1,1,'Qüvvəni ölçmək üçün hansı cihazdan istifadə olunur?','Qüvvə dinamometrlə ölçülür.',array['Dinamometr','Termometr','Barometr','Ampermetr'],1),
('fiz8-quvve#10','fizika','fiz-8-quvve',1,1,'Xarici təsir nəticəsində cismin formasının və ölçüsünün dəyişməsi necə adlanır?','Bu hadisə deformasiyadır.',array['Deformasiya','Diffuziya','İnersiya','Konveksiya'],1),
('fiz8-is-enerji#1','fizika','fiz-8-is-enerji',1,1,'Mexaniki iş hansı düsturla hesablanır?','İş qüvvə ilə yerdəyişmənin hasilinə bərabərdir: A = F·s.',array['A = F · s','A = F / s','A = m · v','A = F · t'],1),
('fiz8-is-enerji#2','fizika','fiz-8-is-enerji',2,1,'100 N qüvvə cismi qüvvə istiqamətində 3 m yerini dəyişdirir. Görülən iş neçə couldur?','A = F·s = 100 · 3 = 300 J.',array['300 J','33 J','103 J','3000 J'],1),
('fiz8-is-enerji#3','fizika','fiz-8-is-enerji',1,1,'İşin BS-də vahidi hansıdır?','İş coulla (J) ölçülür.',array['Coul (J)','Nyuton (N)','Vatt (Vt)','Kelvin (K)'],1),
('fiz8-is-enerji#4','fizika','fiz-8-is-enerji',1,1,'Güc hansı düsturla təyin olunur?','Güc vahid zamanda görülən işdir: P = A/t.',array['P = A / t','P = A · t','P = F / s','P = m · g'],1),
('fiz8-is-enerji#5','fizika','fiz-8-is-enerji',2,1,'600 J iş 30 saniyəyə görülür. Güc neçə vattdır?','P = A/t = 600 / 30 = 20 Vt.',array['20 Vt','570 Vt','630 Vt','18000 Vt'],1),
('fiz8-is-enerji#6','fizika','fiz-8-is-enerji',1,1,'Hərəkətdə olan cismin malik olduğu enerji necə adlanır?','Hərəkət enerjisi kinetik enerjidir.',array['Kinetik enerji','Potensial enerji','Daxili enerji','İstilik miqdarı'],1),
('fiz8-is-enerji#7','fizika','fiz-8-is-enerji',2,1,'Kütləsi 4 kq olan cisim 2 m hündürlüyə qaldırılıb. Potensial enerjisi neçə couldur? (g = 10 N/kq)','E = m·g·h = 4 · 10 · 2 = 80 J.',array['80 J','8 J','40 J','800 J'],1),
('fiz8-is-enerji#8','fizika','fiz-8-is-enerji',2,1,'Kinetik enerji hansı düsturla hesablanır?','E = m·v²/2.',array['E = m · v² / 2','E = m · g · h','E = F · s','E = m · v'],1),
('fiz8-is-enerji#9','fizika','fiz-8-is-enerji',1,1,'Ling və tərpənməz blok nəyə aid edilir?','Bunlar sadə mexanizmlərdir.',array['Sadə mexanizmlərə','İstilik mühərriklərinə','Ölçü cihazlarına','Elektrik qurğularına'],1),
('fiz8-is-enerji#10','fizika','fiz-8-is-enerji',2,1,'Qapalı sistemdə kinetik və potensial enerjilərin cəmi zamanla necə dəyişir?','Mexaniki enerjinin saxlanması qanununa görə cəm dəyişmir.',array['Dəyişmir, saxlanır','Daim artır','Daim azalır','Sıfra bərabər olur'],1),
('fiz8-tezyiq#1','fizika','fiz-8-tezyiq',1,2,'Təzyiq hansı düsturla hesablanır?','Təzyiq qüvvənin sahəyə nisbətidir: p = F/S.',array['p = F / S','p = F · S','p = m / V','p = A / t'],1),
('fiz8-tezyiq#2','fizika','fiz-8-tezyiq',2,2,'60 N qüvvə 0,2 m² sahəyə perpendikulyar təsir edir. Təzyiq neçə paskaldır?','p = F/S = 60 / 0,2 = 300 Pa.',array['300 Pa','12 Pa','30 Pa','1200 Pa'],1),
('fiz8-tezyiq#3','fizika','fiz-8-tezyiq',1,2,'Təzyiqin BS-də vahidi hansıdır?','Təzyiq paskalla (Pa) ölçülür.',array['Paskal (Pa)','Nyuton (N)','Coul (J)','Kelvin (K)'],1),
('fiz8-tezyiq#4','fizika','fiz-8-tezyiq',2,2,'Mayenin qabın dibinə təzyiqi hansı düsturla tapılır?','Hidrostatik təzyiq: p = ρ·g·h.',array['p = ρ · g · h','p = F · S','p = m · g','p = c · m · Δt'],1),
('fiz8-tezyiq#5','fizika','fiz-8-tezyiq',2,2,'Suyun 2 m dərinliyində hidrostatik təzyiq neçə paskaldır? (ρ = 1000 kq/m³, g = 10 N/kq)','p = ρ·g·h = 1000 · 10 · 2 = 20000 Pa.',array['20000 Pa','2000 Pa','200 Pa','5000 Pa'],1),
('fiz8-tezyiq#6','fizika','fiz-8-tezyiq',1,2,'Atmosfer təzyiqini ölçən cihaz necə adlanır?','Atmosfer təzyiqi barometrlə ölçülür.',array['Barometr','Dinamometr','Areometr','Termometr'],1),
('fiz8-tezyiq#7','fizika','fiz-8-tezyiq',2,2,'Normal atmosfer təzyiqi neçə millimetr civə sütununa bərabərdir?','Normal təzyiq 760 mm civə sütunudur.',array['760 mm','100 mm','1000 mm','376 mm'],1),
('fiz8-tezyiq#8','fizika','fiz-8-tezyiq',1,2,'Mayeyə salınmış cismi yuxarı itələyən qüvvə kimin adı ilə adlanır?','Bu, Arximed qüvvəsidir.',array['Arximed','Nyuton','Paskal','Qaliley'],1),
('fiz8-tezyiq#9','fizika','fiz-8-tezyiq',2,2,'Mayeyə edilən təzyiqin bütün istiqamətlərdə dəyişmədən ötürülməsini hansı qanun ifadə edir?','Bu, Paskal qanunudur.',array['Paskal qanunu','Huk qanunu','Arximed qanunu','Enerjinin saxlanması qanunu'],1),
('fiz8-tezyiq#10','fizika','fiz-8-tezyiq',3,2,'Cisim mayenin səthində hansı halda üzür?','Arximed qüvvəsi ağırlıq qüvvəsinə bərabər olduqda cisim üzür.',array['Arximed qüvvəsi ağırlıq qüvvəsinə bərabər olduqda','Arximed qüvvəsi sıfır olduqda','Ağırlıq qüvvəsi Arximed qüvvəsindən böyük olduqda','Cismin sıxlığı mayeninkindən böyük olduqda'],1),
('fiz8-dalgalar#1','fizika','fiz-8-dalgalar',1,3,'Rəqsin bir tam dövrünə sərf olunan zaman necə adlanır?','Bu, rəqsin periodudur.',array['Period','Tezlik','Amplitud','Faza'],1),
('fiz8-dalgalar#2','fizika','fiz-8-dalgalar',1,3,'Tezliyin BS-də vahidi hansıdır?','Tezlik herslə (Hz) ölçülür.',array['Hers (Hz)','Saniyə (s)','Metr (m)','Desibel (dB)'],1),
('fiz8-dalgalar#3','fizika','fiz-8-dalgalar',2,3,'Periodu 0,5 s olan rəqsin tezliyi neçə hersdir?','ν = 1/T = 1 / 0,5 = 2 Hz.',array['2 Hz','0,5 Hz','5 Hz','20 Hz'],1),
('fiz8-dalgalar#4','fizika','fiz-8-dalgalar',2,3,'Dalğa uzunluğu hansı düsturla tapılır?','λ = v/ν — sürətin tezliyə nisbəti.',array['λ = v / ν','λ = v · t²','λ = m / V','λ = F / S'],1),
('fiz8-dalgalar#5','fizika','fiz-8-dalgalar',2,3,'Sürəti 340 m/s, tezliyi 170 Hz olan səs dalğasının uzunluğu neçə metrdir?','λ = v/ν = 340 / 170 = 2 m.',array['2 m','170 m','510 m','0,5 m'],1),
('fiz8-dalgalar#6','fizika','fiz-8-dalgalar',1,3,'Səs havada təqribən hansı sürətlə yayılır?','Səsin havada sürəti təqribən 340 m/s-dir.',array['340 m/s','3 m/s','300000 km/s','34 km/s'],1),
('fiz8-dalgalar#7','fizika','fiz-8-dalgalar',2,3,'Səs vakuumda nə üçün yayılmır?','Səs mexaniki dalğadır, yayılması üçün mühit lazımdır.',array['Rəqsi ötürən mühit olmadığı üçün','Temperatur aşağı olduğu üçün','İşıq olmadığı üçün','Təzyiq yüksək olduğu üçün'],1),
('fiz8-dalgalar#8','fizika','fiz-8-dalgalar',2,3,'Səsin ucalığı rəqsin hansı xarakteristikasından asılıdır?','Amplitud böyük olduqca səs uca olur.',array['Amplituddan','Periodun işarəsindən','Mühitin rəngindən','Mənbənin kütləsindən'],1),
('fiz8-dalgalar#9','fizika','fiz-8-dalgalar',2,3,'Səsin hündürlüyü (zil və ya bəm olması) nədən asılıdır?','Tezlik böyük olduqca səs zil olur.',array['Tezlikdən','Amplituddan','Mühitin həcmindən','Dinləyicinin məsafəsindən'],1),
('fiz8-dalgalar#10','fizika','fiz-8-dalgalar',1,3,'Maneədən qayıdan səsin təkrar eşidilməsi necə adlanır?','Bu hadisə əks-sədadır.',array['Əks-səda','Rezonans','İnterferensiya','Diffuziya'],1),
('fiz8-istilik#1','fizika','fiz-8-istilik',1,3,'Cismin bütün molekullarının kinetik və potensial enerjilərinin cəmi necə adlanır?','Bu, cismin daxili enerjisidir.',array['Daxili enerji','Mexaniki enerji','Kinetik enerji','Potensial enerji'],1),
('fiz8-istilik#2','fizika','fiz-8-istilik',2,3,'Daxili enerjini dəyişməyin iki yolu hansıdır?','İş görmək və istilikvermə.',array['İş görmək və istilikvermə','Yalnız qızdırmaq','Yalnız soyutmaq','Cismi hərəkət etdirmək və boyamaq'],1),
('fiz8-istilik#3','fizika','fiz-8-istilik',1,3,'Bərk cisimlərdə istilik əsasən hansı yolla ötürülür?','Bərk cisimlərdə istilikkeçirmə üstünlük təşkil edir.',array['İstilikkeçirmə ilə','Konveksiya ilə','Şüalanma ilə','Diffuziya ilə'],1),
('fiz8-istilik#4','fizika','fiz-8-istilik',1,3,'Maye və qazlarda istiliyin axınlar vasitəsilə ötürülməsi necə adlanır?','Bu, konveksiyadır.',array['Konveksiya','İstilikkeçirmə','Şüalanma','Deformasiya'],1),
('fiz8-istilik#5','fizika','fiz-8-istilik',1,3,'Günəşin istiliyi Yerə hansı yolla çatır?','Kosmos boşluğundan istilik yalnız şüalanma ilə keçir.',array['Şüalanma ilə','Konveksiya ilə','İstilikkeçirmə ilə','Külək vasitəsilə'],1),
('fiz8-istilik#6','fizika','fiz-8-istilik',2,3,'Qızdırılan cismin aldığı istilik miqdarı hansı düsturla hesablanır?','Q = c·m·Δt.',array['Q = c · m · Δt','Q = F · s','Q = m · g · h','Q = P · S'],1),
('fiz8-istilik#7','fizika','fiz-8-istilik',3,3,'2 kq suyu 10 °C qızdırmaq üçün neçə coul istilik lazımdır? (c = 4200 J/(kq·°C))','Q = c·m·Δt = 4200 · 2 · 10 = 84000 J.',array['84000 J','8400 J','42000 J','840 J'],1),
('fiz8-istilik#8','fizika','fiz-8-istilik',3,3,'Temperatur molekulların hansı xarakteristikası ilə bağlıdır?','Temperatur molekulların orta kinetik enerjisinin ölçüsüdür.',array['Orta kinetik enerjisi ilə','Sayı ilə','Rəngi ilə','Ölçüsü ilə'],1),
('fiz8-istilik#9','fizika','fiz-8-istilik',1,3,'İstilik miqdarı hansı vahidlə ölçülür?','İstilik miqdarı enerji kimi coulla ölçülür.',array['Coul (J)','Kelvin (K)','Vatt (Vt)','Paskal (Pa)'],1),
('fiz8-istilik#10','fizika','fiz-8-istilik',2,3,'Diffuziya hadisəsi nəyi sübut edir?','Maddə hissəcikləri daim xaotik hərəkətdədir.',array['Molekulların daim hərəkətdə olduğunu','Cisimlərin bərk olduğunu','İstiliyin işıqdan yarandığını','Molekulların hərəkətsiz olduğunu'],1),
('fiz8-istilik-qanun#1','fizika','fiz-8-istilik-qanun',1,4,'Maddənin bərk haldan maye hala keçməsi necə adlanır?','Bu proses ərimədir.',array['Ərimə','Donma','Buxarlanma','Kondensasiya'],1),
('fiz8-istilik-qanun#2','fizika','fiz-8-istilik-qanun',1,4,'Buzun ərimə temperaturu neçə dərəcədir?','Buz 0 °C-də əriyir.',array['0 °C','10 °C','100 °C','−10 °C'],1),
('fiz8-istilik-qanun#3','fizika','fiz-8-istilik-qanun',1,4,'Normal atmosfer təzyiqində suyun qaynama temperaturu neçə dərəcədir?','Su normal təzyiqdə 100 °C-də qaynayır.',array['100 °C','0 °C','60 °C','212 °C'],1),
('fiz8-istilik-qanun#4','fizika','fiz-8-istilik-qanun',1,4,'Buxarın maye hala keçməsi necə adlanır?','Bu proses kondensasiyadır.',array['Kondensasiya','Buxarlanma','Sublimasiya','Ərimə'],1),
('fiz8-istilik-qanun#5','fizika','fiz-8-istilik-qanun',2,4,'Qaynamanın buxarlanmadan əsas fərqi nədir?','Qaynama mayenin bütün həcmində, buxarlanma isə səthindən gedir.',array['Qaynama bütün həcmdə gedir','Qaynama yalnız səthdə gedir','Qaynamada istilik tələb olunmur','Fərq yoxdur'],1),
('fiz8-istilik-qanun#6','fizika','fiz-8-istilik-qanun',2,4,'Yanacağın tam yanmasında ayrılan istilik hansı düsturla hesablanır?','Q = q·m — yanma istiliyinin kütləyə hasili.',array['Q = q · m','Q = c · m · Δt','Q = F · s','Q = m · g · h'],1),
('fiz8-istilik-qanun#7','fizika','fiz-8-istilik-qanun',2,4,'Daxili yanma mühərriki hansı enerjini mexaniki enerjiyə çevirir?','Yanacağın yanmasında ayrılan daxili (istilik) enerjini.',array['Yanacağın istilik enerjisini','Günəş enerjisini','Elektrik enerjisini','Maqnit enerjisini'],1),
('fiz8-istilik-qanun#8','fizika','fiz-8-istilik-qanun',3,4,'İstilik mühərrikinin faydalı iş əmsalı nəyin nisbətidir?','FİƏ faydalı işin sərf olunan enerjiyə nisbətidir.',array['Faydalı işin sərf olunan enerjiyə','Sərf olunan enerjinin zamana','Qüvvənin sahəyə','İstiliyin temperatura'],1),
('fiz8-istilik-qanun#9','fizika','fiz-8-istilik-qanun',3,4,'Mühərrik 1000 J enerji alıb 250 J faydalı iş görür. Faydalı iş əmsalı neçə faizdir?','FİƏ = 250/1000 · 100 = 25 %.',array['25 %','40 %','75 %','4 %'],1),
('fiz8-istilik-qanun#10','fizika','fiz-8-istilik-qanun',2,4,'Ərimə gedən müddətdə maddənin temperaturu necə dəyişir?','Verilən istilik kristal quruluşun dağılmasına sərf olunur, temperatur sabit qalır.',array['Sabit qalır','Daim artır','Daim azalır','Sıçrayışla artır'],1),
('kim8-dovri-cedvel#1','kimya','kim-8-dovri-cedvel',1,1,'Kimyəvi elementlərin dövri qanununu kim kəşf etmişdir?','Dövri qanunu 1869-cu ildə D.Mendeleyev kəşf etmişdir.',array['D. Mendeleyev','M. Lomonosov','A. Lavuazye','C. Dalton'],1),
('kim8-dovri-cedvel#2','kimya','kim-8-dovri-cedvel',2,1,'Elementin dövri cədvəldəki sıra nömrəsi nəyə bərabərdir?','Sıra nömrəsi nüvədəki protonların sayına bərabərdir.',array['Nüvədəki protonların sayına','Neytronların sayına','Elektron təbəqələrinin sayına','Atom kütləsinə'],1),
('kim8-dovri-cedvel#3','kimya','kim-8-dovri-cedvel',1,1,'Dövri cədvəldə üfüqi sıra necə adlanır?','Üfüqi sıra dövr adlanır.',array['Dövr','Qrup','Sinif','Ailə'],1),
('kim8-dovri-cedvel#4','kimya','kim-8-dovri-cedvel',1,1,'Dövri cədvəldə şaquli sütun necə adlanır?','Şaquli sütun qrup adlanır.',array['Qrup','Dövr','Cərgə','Blok'],1),
('kim8-dovri-cedvel#5','kimya','kim-8-dovri-cedvel',2,1,'Natriumun sıra nömrəsi 11-dir. Neytral atomunda neçə elektron var?','Neytral atomda elektronların sayı protonların sayına, yəni sıra nömrəsinə bərabərdir.',array['11','22','12','1'],1),
('kim8-dovri-cedvel#6','kimya','kim-8-dovri-cedvel',1,1,'Oksigen atomunun nüvəsində 8 proton var. Elementin sıra nömrəsi neçədir?','Sıra nömrəsi proton sayına bərabərdir: 8.',array['8','16','4','10'],1),
('kim8-dovri-cedvel#7','kimya','kim-8-dovri-cedvel',2,1,'Dövrün nömrəsi atomda nəyi göstərir?','Dövr nömrəsi elektron təbəqələrinin sayını göstərir.',array['Elektron təbəqələrinin sayını','Protonların sayını','Neytronların sayını','Valentliyi'],1),
('kim8-dovri-cedvel#8','kimya','kim-8-dovri-cedvel',2,1,'Əsas yarımqrupun nömrəsi atomda nəyi göstərir?','Qrup nömrəsi xarici təbəqədəki elektronların sayını göstərir.',array['Xarici təbəqədəki elektronların sayını','Nüvədəki neytronların sayını','Təbəqələrin ümumi sayını','Atomun ölçüsünü'],1),
('kim8-dovri-cedvel#9','kimya','kim-8-dovri-cedvel',2,1,'Atom nüvəsinin müsbət yükünü hansı hissəciklər yaradır?','Nüvənin müsbət yükü protonlardan yaranır.',array['Protonlar','Neytronlar','Elektronlar','İonlar'],1),
('kim8-dovri-cedvel#10','kimya','kim-8-dovri-cedvel',3,1,'Dövr üzrə soldan sağa getdikcə elementlərin metal xassələri necə dəyişir?','Dövr üzrə soldan sağa metal xassələri zəifləyir, qeyri-metal xassələri güclənir.',array['Zəifləyir','Güclənir','Dəyişmir','Əvvəl artır, sonra sabitləşir'],1),
('kim8-rabite#1','kimya','kim-8-rabite',1,1,'Natrium və xlor atomları arasında hansı kimyəvi rabitə yaranır?','Metalla qeyri-metal arasında ion rabitəsi yaranır (NaCl).',array['İon rabitəsi','Qeyri-polyar kovalent','Metal rabitəsi','Hidrogen rabitəsi'],1),
('kim8-rabite#2','kimya','kim-8-rabite',2,1,'Eyni qeyri-metalın atomları arasında (məsələn H₂ molekulunda) hansı rabitə olur?','Eyni elektromənfilikli atomlar arasında qeyri-polyar kovalent rabitə yaranır.',array['Qeyri-polyar kovalent','Polyar kovalent','İon rabitəsi','Metal rabitəsi'],1),
('kim8-rabite#3','kimya','kim-8-rabite',2,1,'Su molekulunda (H₂O) hansı rabitə növü var?','Müxtəlif qeyri-metallar arasında polyar kovalent rabitə yaranır.',array['Polyar kovalent','Qeyri-polyar kovalent','İon rabitəsi','Metal rabitəsi'],1),
('kim8-rabite#4','kimya','kim-8-rabite',1,1,'Ümumi elektron cütləri hesabına yaranan rabitə necə adlanır?','Bu, kovalent rabitədir.',array['Kovalent rabitə','İon rabitəsi','Metal rabitəsi','Van-der-Vaals rabitəsi'],1),
('kim8-rabite#5','kimya','kim-8-rabite',2,1,'Atomun elektronları özünə tərəf çəkmə qabiliyyəti necə adlanır?','Bu xassə elektromənfilikdir.',array['Elektromənfilik','Valentlik','Oksidləşmə dərəcəsi','Radioaktivlik'],1),
('kim8-rabite#6','kimya','kim-8-rabite',1,1,'Metal kristallarında atomları birləşdirən rabitə necə adlanır?','Metallarda metal rabitəsi olur.',array['Metal rabitəsi','İon rabitəsi','Kovalent rabitə','Hidrogen rabitəsi'],1),
('kim8-rabite#7','kimya','kim-8-rabite',2,1,'İonlar necə əmələ gəlir?','Atom elektron verdikdə və ya aldıqda yüklü hissəciyə — iona çevrilir.',array['Atom elektron verdikdə və ya aldıqda','Atom proton itirdikdə','Nüvə parçalandıqda','Molekullar toqquşduqda'],1),
('kim8-rabite#8','kimya','kim-8-rabite',1,1,'Müsbət yüklü ion necə adlanır?','Elektron vermiş atom müsbət iona — kationa çevrilir.',array['Kation','Anion','İzotop','Radikal'],1),
('kim8-rabite#9','kimya','kim-8-rabite',1,1,'Mənfi yüklü ion necə adlanır?','Elektron almış atom mənfi iona — aniona çevrilir.',array['Anion','Kation','Neytron','Dipol'],1),
('kim8-rabite#10','kimya','kim-8-rabite',3,1,'Elektromənfiliyi ən yüksək olan element hansıdır?','Flüor bütün elementlər arasında ən elektromənfidir.',array['Flüor','Natrium','Dəmir','Hidrogen'],1),
('kim8-reaksiya-tesnifat#1','kimya','kim-8-reaksiya-tesnifat',1,2,'İki və daha çox maddədən bir mürəkkəb maddə əmələ gəldiyi reaksiya necə adlanır?','Bu, birləşmə reaksiyasıdır.',array['Birləşmə','Parçalanma','Əvəzetmə','Mübadilə'],1),
('kim8-reaksiya-tesnifat#2','kimya','kim-8-reaksiya-tesnifat',1,2,'Bir mürəkkəb maddədən iki və daha çox maddə alındığı reaksiya necə adlanır?','Bu, parçalanma reaksiyasıdır.',array['Parçalanma','Birləşmə','Neytrallaşma','Yanma'],1),
('kim8-reaksiya-tesnifat#3','kimya','kim-8-reaksiya-tesnifat',2,2,'Zn + 2HCl = ZnCl₂ + H₂ reaksiyası hansı tipə aiddir?','Bəsit maddə mürəkkəb maddədəki elementi əvəz edir — əvəzetmə.',array['Əvəzetmə','Birləşmə','Parçalanma','Mübadilə'],1),
('kim8-reaksiya-tesnifat#4','kimya','kim-8-reaksiya-tesnifat',2,2,'İki mürəkkəb maddənin öz tərkib hissələrini dəyişdiyi reaksiya necə adlanır?','Bu, mübadilə reaksiyasıdır.',array['Mübadilə','Əvəzetmə','Birləşmə','Parçalanma'],1),
('kim8-reaksiya-tesnifat#5','kimya','kim-8-reaksiya-tesnifat',2,2,'İstiliyin ayrılması ilə gedən reaksiya necə adlanır?','İstilik ayrılırsa reaksiya ekzotermikdir.',array['Ekzotermik','Endotermik','Katalitik','Dönər'],1),
('kim8-reaksiya-tesnifat#6','kimya','kim-8-reaksiya-tesnifat',2,2,'İstiliyin udulması ilə gedən reaksiya necə adlanır?','İstilik udulursa reaksiya endotermikdir.',array['Endotermik','Ekzotermik','İon reaksiyası','Yanma'],1),
('kim8-reaksiya-tesnifat#7','kimya','kim-8-reaksiya-tesnifat',2,2,'Kimyəvi tənlikdə əmsallar nə üçün qoyulur?','Kütlənin saxlanması qanununa görə hər elementin atom sayı bərabərləşdirilir.',array['Atomların sayını bərabərləşdirmək üçün','Tənliyi qısaltmaq üçün','Maddələrin rəngini göstərmək üçün','Reaksiyanın sürətini göstərmək üçün'],1),
('kim8-reaksiya-tesnifat#8','kimya','kim-8-reaksiya-tesnifat',2,2,'Maddələrin kütləsinin saxlanması qanununu kim müəyyən etmişdir?','Qanunu M.Lomonosov (sonralar A.Lavuazye də) təcrübə ilə əsaslandırmışdır.',array['M. Lomonosov','D. Mendeleyev','İ. Nyuton','N. Bor'],1),
('kim8-reaksiya-tesnifat#9','kimya','kim-8-reaksiya-tesnifat',1,2,'2H₂ + O₂ = 2H₂O tənliyində su molekulunun əmsalı neçədir?','Tənlikdə suyun qarşısındakı əmsal 2-dir.',array['2','1','3','4'],1),
('kim8-reaksiya-tesnifat#10','kimya','kim-8-reaksiya-tesnifat',1,2,'Yanma reaksiyaları adətən hansı qazın iştirakı ilə gedir?','Yanma oksigenin iştirakı ilə gedir.',array['Oksigen','Azot','Hidrogen','Karbon qazı'],1),
('kim8-reaksiya-sureti#1','kimya','kim-8-reaksiya-sureti',1,3,'Reaksiyanı sürətləndirən, özü isə sərf olunmayan maddə necə adlanır?','Bu, katalizatordur.',array['Katalizator','İndikator','İnhibitor','Oksidləşdirici'],1),
('kim8-reaksiya-sureti#2','kimya','kim-8-reaksiya-sureti',1,3,'Temperatur yüksəldikdə reaksiyanın sürəti adətən necə dəyişir?','Hissəciklərin toqquşması tezləşir — sürət artır.',array['Artır','Azalır','Dəyişmir','Sıfra düşür'],1),
('kim8-reaksiya-sureti#3','kimya','kim-8-reaksiya-sureti',2,3,'Bərk maddəni xırdaladıqda reaksiya sürəti nə üçün artır?','Toxunma səthi böyüyür, toqquşan hissəciklərin sayı artır.',array['Toxunma səthi böyüdüyü üçün','Kütlə azaldığı üçün','Temperatur düşdüyü üçün','Maddə buxarlandığı üçün'],1),
('kim8-reaksiya-sureti#4','kimya','kim-8-reaksiya-sureti',2,3,'Aşağıdakılardan hansı reaksiyanın sürətinə təsir etmir?','Qabın rəngi reaksiya sürətinə təsir etmir.',array['Qabın rəngi','Temperatur','Qatılıq','Katalizator'],1),
('kim8-reaksiya-sureti#5','kimya','kim-8-reaksiya-sureti',2,3,'Canlı orqanizmlərdəki bioloji katalizatorlar necə adlanır?','Bunlar fermentlərdir.',array['Fermentlər','Hormonlar','Vitaminlər','İndikatorlar'],1),
('kim8-reaksiya-sureti#6','kimya','kim-8-reaksiya-sureti',3,3,'Reaksiyanın sürəti nə ilə qiymətləndirilir?','Vahid zamanda maddənin qatılığının dəyişməsi ilə.',array['Vahid zamanda qatılığın dəyişməsi ilə','Qabın həcmi ilə','Məhlulun rəngi ilə','Maddənin qiyməti ilə'],1),
('kim8-reaksiya-sureti#7','kimya','kim-8-reaksiya-sureti',2,3,'Qida soyuducuda nə üçün gec xarab olur?','Aşağı temperaturda kimyəvi proseslər yavaş gedir.',array['Aşağı temperatur reaksiyaları yavaşıdır','Soyuducuda işıq yoxdur','Soyuducuda hava yoxdur','Mikroblar soyuqda çoxalır'],1),
('kim8-reaksiya-sureti#8','kimya','kim-8-reaksiya-sureti',2,3,'Eyni kütləli dəmir tozu və dəmir mismardan hansı turşu ilə daha sürətli reaksiyaya girir?','Tozun toxunma səthi böyükdür — reaksiya sürətlidir.',array['Dəmir tozu','Dəmir mismar','Hər ikisi eyni sürətlə','Heç biri reaksiyaya girmir'],1),
('kim8-reaksiya-sureti#9','kimya','kim-8-reaksiya-sureti',2,3,'Məhlulun qatılığı nəyi göstərir?','Vahid həcmdə həll olmuş maddənin miqdarını.',array['Vahid həcmdəki maddə miqdarını','Məhlulun temperaturunu','Qabın tutumunu','Mayenin rəngini'],1),
('kim8-reaksiya-sureti#10','kimya','kim-8-reaksiya-sureti',1,3,'Katalizatorun iştirakı ilə gedən reaksiya necə adlanır?','Belə reaksiya katalitik reaksiyadır.',array['Katalitik','Ekzotermik','Endotermik','Zəncirvari'],1),
('kim8-oksidlesme#1','kimya','kim-8-oksidlesme',1,3,'Atomun elektron vermə prosesi necə adlanır?','Elektron vermə oksidləşmədir.',array['Oksidləşmə','Reduksiya','Neytrallaşma','Dissosiasiya'],1),
('kim8-oksidlesme#2','kimya','kim-8-oksidlesme',1,3,'Atomun elektron alma prosesi necə adlanır?','Elektron alma reduksiyadır.',array['Reduksiya','Oksidləşmə','Buxarlanma','Kondensasiya'],1),
('kim8-oksidlesme#3','kimya','kim-8-oksidlesme',2,3,'Reaksiyada elektron verən hissəcik necə adlanır?','Elektron verən özü oksidləşir və reduksiyaedicidir.',array['Reduksiyaedici','Oksidləşdirici','Katalizator','İndikator'],1),
('kim8-oksidlesme#4','kimya','kim-8-oksidlesme',2,3,'Reaksiyada elektron alan hissəcik necə adlanır?','Elektron alan özü reduksiya olunur və oksidləşdiricidir.',array['Oksidləşdirici','Reduksiyaedici','Ferment','Anion'],1),
('kim8-oksidlesme#5','kimya','kim-8-oksidlesme',2,3,'Sərbəst haldakı bəsit maddədə elementin oksidləşmə dərəcəsi neçədir?','Bəsit maddədə oksidləşmə dərəcəsi sıfırdır.',array['0','+1','−1','+2'],1),
('kim8-oksidlesme#6','kimya','kim-8-oksidlesme',2,3,'Birləşmələrdə hidrogenin oksidləşmə dərəcəsi adətən neçədir?','Hidrogen birləşmələrdə adətən +1 göstərir.',array['+1','−2','0','+2'],1),
('kim8-oksidlesme#7','kimya','kim-8-oksidlesme',2,3,'Birləşmələrdə oksigenin oksidləşmə dərəcəsi adətən neçədir?','Oksigen birləşmələrdə adətən −2 göstərir.',array['−2','+2','+1','0'],1),
('kim8-oksidlesme#8','kimya','kim-8-oksidlesme',3,3,'Neytral molekulda elementlərin oksidləşmə dərəcələrinin cəmi neçə olur?','Molekul neytraldır — cəm sıfırdır.',array['0','+1','−1','Molekulun kütləsi qədər'],1),
('kim8-oksidlesme#9','kimya','kim-8-oksidlesme',2,3,'Na atomu Na⁺ ionuna çevrilərkən neçə elektron verir?','Na⁺ yaranması üçün 1 elektron verilir.',array['1','2','11','Heç bir elektron vermir'],1),
('kim8-oksidlesme#10','kimya','kim-8-oksidlesme',2,3,'Oksidləşmə-reduksiya reaksiyalarında nə dəyişir?','Elementlərin oksidləşmə dərəcələri dəyişir.',array['Elementlərin oksidləşmə dərəcəsi','Atomların ümumi sayı','Maddələrin ümumi kütləsi','Nüvələrin yükü'],1),
('kim8-tursu-esas#1','kimya','kim-8-tursu-esas',1,4,'Bütün turşuların tərkibində hansı element mütləq olur?','Turşular tərkibində metalla əvəz oluna bilən hidrogen saxlayır.',array['Hidrogen','Oksigen','Karbon','Xlor'],1),
('kim8-tursu-esas#2','kimya','kim-8-tursu-esas',1,4,'Lakmus turşu mühitində hansı rəngə boyanır?','Turşu mühitində lakmus qırmızı olur.',array['Qırmızı','Göy','Sarı','Yaşıl'],1),
('kim8-tursu-esas#3','kimya','kim-8-tursu-esas',2,4,'Fenolftalein qələvi mühitində hansı rəngi alır?','Qələvi mühitdə fenolftalein moruğu rəngə boyanır.',array['Moruğu','Rəngsiz qalır','Qara','Narıncı'],1),
('kim8-tursu-esas#4','kimya','kim-8-tursu-esas',2,4,'Turşu ilə əsas arasındakı reaksiya necə adlanır?','Bu, neytrallaşma reaksiyasıdır.',array['Neytrallaşma','Oksidləşmə','Parçalanma','Əvəzetmə'],1),
('kim8-tursu-esas#5','kimya','kim-8-tursu-esas',2,4,'Neytrallaşma reaksiyasının məhsulları hansılardır?','Turşu + əsas = duz + su.',array['Duz və su','Yalnız qaz','Metal və su','İki turşu'],1),
('kim8-tursu-esas#6','kimya','kim-8-tursu-esas',2,4,'pH = 7 olan mühit necə xarakterizə olunur?','pH 7 neytral mühitdir.',array['Neytral','Turş','Qələvi','Doymuş'],1),
('kim8-tursu-esas#7','kimya','kim-8-tursu-esas',2,4,'pH 7-dən kiçik olan məhlul hansı mühitə malikdir?','pH < 7 turş mühiti göstərir.',array['Turş','Qələvi','Neytral','Duzlu'],1),
('kim8-tursu-esas#8','kimya','kim-8-tursu-esas',1,4,'HCl birləşməsinin turşu kimi adı nədir?','HCl xlorid turşusudur.',array['Xlorid turşusu','Sulfat turşusu','Nitrat turşusu','Karbonat turşusu'],1),
('kim8-tursu-esas#9','kimya','kim-8-tursu-esas',1,4,'NaOH hansı maddələr sinfinə aiddir?','NaOH suda həll olan əsasdır — qələvidir.',array['Əsaslara (qələvilərə)','Turşulara','Duzlara','Oksidlərə'],1),
('kim8-tursu-esas#10','kimya','kim-8-tursu-esas',1,4,'H₂SO₄ hansı turşudur?','H₂SO₄ sulfat turşusudur.',array['Sulfat turşusu','Xlorid turşusu','Fosfat turşusu','Sirkə turşusu'],1),
('bio8-heyat-kimyasi#1','biologiya','bio-8-heyat-kimyasi',1,1,'Hüceyrədə miqdarca ən çox olan qeyri-üzvi maddə hansıdır?','Hüceyrənin böyük hissəsi sudur.',array['Su','Zülal','Yağ','Mineral duzlar'],1),
('bio8-heyat-kimyasi#2','biologiya','bio-8-heyat-kimyasi',1,1,'Orqanizmin əsas tikinti materialı olan üzvi maddə hansıdır?','Hüceyrələrin quruluşunda əsas rolu zülallar oynayır.',array['Zülal','Karbohidrat','Su','Vitamin'],1),
('bio8-heyat-kimyasi#3','biologiya','bio-8-heyat-kimyasi',2,1,'Orqanizmin əsas enerji mənbəyi olan üzvi maddələr hansılardır?','Enerjini ilk növbədə karbohidratlar verir.',array['Karbohidratlar','Mineral duzlar','Vitaminlər','Fermentlər'],1),
('bio8-heyat-kimyasi#4','biologiya','bio-8-heyat-kimyasi',1,1,'İrsi məlumatı saxlayan molekul hansıdır?','İrsi məlumat DNT molekulunda kodlaşdırılıb.',array['DNT','Zülal','Qlükoza','Hemoqlobin'],1),
('bio8-heyat-kimyasi#5','biologiya','bio-8-heyat-kimyasi',2,1,'Zülalların tikinti vahidi (monomeri) nədir?','Zülallar amin turşularından qurulur.',array['Amin turşuları','Qlükoza','Nukleotidlər','Yağ turşuları'],1),
('bio8-heyat-kimyasi#6','biologiya','bio-8-heyat-kimyasi',2,1,'Dəri altında ehtiyat enerji mənbəyi kimi hansı maddələr toplanır?','Yağlar ehtiyat enerji mənbəyidir.',array['Yağlar','Zülallar','Su','Duzlar'],1),
('bio8-heyat-kimyasi#7','biologiya','bio-8-heyat-kimyasi',3,1,'C vitamininin uzunmüddətli çatışmazlığı hansı xəstəliyə səbəb olur?','C vitamini çatışmazlığı sinqa xəstəliyi yaradır.',array['Sinqa','Raxit','Anemiya','Qrip'],1),
('bio8-heyat-kimyasi#8','biologiya','bio-8-heyat-kimyasi',3,1,'Qanda qlükozanın səviyyəsini azaldan hormon hansıdır?','İnsulin qlükozanın hüceyrələrə keçməsini təmin edir.',array['İnsulin','Adrenalin','Tiroksin','Melatonin'],1),
('bio8-heyat-kimyasi#9','biologiya','bio-8-heyat-kimyasi',3,1,'Fermentlər kimyəvi təbiətinə görə əsasən hansı maddələrdir?','Fermentlərin əksəriyyəti zülal təbiətlidir.',array['Zülal','Karbohidrat','Yağ','Mineral'],1),
('bio8-heyat-kimyasi#10','biologiya','bio-8-heyat-kimyasi',2,1,'D vitamini orqanizmdə əsasən nəyin təsiri ilə sintez olunur?','D vitamini günəş şüalarının təsiri ilə dəridə əmələ gəlir.',array['Günəş şüalarının','Suyun','Duzun','Səs dalğalarının'],1),
('bio8-bitki#1','biologiya','bio-8-bitki',1,1,'Bitkini torpağa bərkidən və su ilə mineral duzları sovuran orqan hansıdır?','Bu funksiyaları kök yerinə yetirir.',array['Kök','Gövdə','Yarpaq','Çiçək'],1),
('bio8-bitki#2','biologiya','bio-8-bitki',1,1,'Fotosintez əsasən bitkinin hansı orqanında gedir?','Fotosintez xlorofilli yarpaq hüceyrələrində gedir.',array['Yarpaqda','Kökdə','Toxumda','Meyvədə'],1),
('bio8-bitki#3','biologiya','bio-8-bitki',1,1,'Fotosintez zamanı atmosferə hansı qaz buraxılır?','Fotosintezin əlavə məhsulu oksigendir.',array['Oksigen','Karbon qazı','Azot','Hidrogen'],1),
('bio8-bitki#4','biologiya','bio-8-bitki',3,1,'Yarpaqdan suyun buxarlanması necə adlanır?','Bu proses transpirasiyadır.',array['Transpirasiya','Fotosintez','Tənəffüs','Mayalanma'],1),
('bio8-bitki#5','biologiya','bio-8-bitki',2,1,'Yarpaqda qaz mübadiləsi hansı strukturlardan gedir?','Qazlar ağızcıqlardan daxil olub çıxır.',array['Ağızcıqlardan','Köklərdən','Ləçəklərdən','Toxumlardan'],1),
('bio8-bitki#6','biologiya','bio-8-bitki',1,1,'Çiçəyin əsas funksiyası nədir?','Çiçək bitkinin çoxalma orqanıdır.',array['Çoxalma','Fotosintez','Suyun sorulması','Qidanın toplanması'],1),
('bio8-bitki#7','biologiya','bio-8-bitki',2,1,'Tozcuğun dişiciyin ağzına düşməsi necə adlanır?','Bu proses tozlanmadır.',array['Tozlanma','Mayalanma','Cücərmə','Şitilləmə'],1),
('bio8-bitki#8','biologiya','bio-8-bitki',2,1,'Mayalanmadan sonra çiçəyin yumurtalığından nə inkişaf edir?','Yumurtalıqdan meyvə əmələ gəlir.',array['Meyvə','Kök','Yarpaq','Gövdə'],1),
('bio8-bitki#9','biologiya','bio-8-bitki',2,1,'Gövdənin əsas funksiyalarından biri hansıdır?','Gövdə maddələri köklə yarpaqlar arasında daşıyır.',array['Maddələri orqanlar arasında daşımaq','Tozlanmanı aparmaq','Torpaqdan duz sormaq','Toxum yaymaq'],1),
('bio8-bitki#10','biologiya','bio-8-bitki',2,1,'Xlorofil piqmenti hüceyrənin hansı orqanoidində yerləşir?','Xlorofil xloroplastlarda olur.',array['Xloroplastlarda','Nüvədə','Mitoxondridə','Vakuolda'],1),
('bio8-qan-dovrani#1','biologiya','bio-8-qan-dovrani',1,2,'İnsan ürəyi neçə kameradan ibarətdir?','Ürək 2 qulaqcıq və 2 mədəcikdən — 4 kameradan ibarətdir.',array['4','2','3','6'],1),
('bio8-qan-dovrani#2','biologiya','bio-8-qan-dovrani',1,2,'Qanı ürəkdən orqanlara aparan damarlar necə adlanır?','Ürəkdən qan arteriyalarla çıxır.',array['Arteriyalar','Venalar','Kapilyarlar','Limfa damarları'],1),
('bio8-qan-dovrani#3','biologiya','bio-8-qan-dovrani',1,2,'Qanı orqanlardan ürəyə gətirən damarlar necə adlanır?','Ürəyə qan venalarla qayıdır.',array['Venalar','Arteriyalar','Aorta','Bronxlar'],1),
('bio8-qan-dovrani#4','biologiya','bio-8-qan-dovrani',1,2,'Oksigeni daşıyan qan hüceyrələri hansılardır?','Eritrositlər hemoqlobin vasitəsilə oksigen daşıyır.',array['Eritrositlər','Leykositlər','Trombositlər','Neyronlar'],1),
('bio8-qan-dovrani#5','biologiya','bio-8-qan-dovrani',2,2,'Orqanizmi mikroblardan qoruyan qan hüceyrələri hansılardır?','Leykositlər orqanizmin müdafiəsində iştirak edir.',array['Leykositlər','Eritrositlər','Trombositlər','Hormonlar'],1),
('bio8-qan-dovrani#6','biologiya','bio-8-qan-dovrani',2,2,'Qanın laxtalanmasında hansı qan hüceyrələri iştirak edir?','Trombositlər laxtalanmanı təmin edir.',array['Trombositlər','Eritrositlər','Leykositlər','Qan plazması'],1),
('bio8-qan-dovrani#7','biologiya','bio-8-qan-dovrani',2,2,'Eritrositlərə qırmızı rəng verən maddə nədir?','Bu, dəmir tərkibli hemoqlobindir.',array['Hemoqlobin','Xlorofil','İnsulin','Melanin'],1),
('bio8-qan-dovrani#8','biologiya','bio-8-qan-dovrani',1,2,'Ən nazik divarlı, ən kiçik qan damarları hansılardır?','Maddələr mübadiləsi kapilyarlarda gedir.',array['Kapilyarlar','Arteriyalar','Venalar','Aorta'],1),
('bio8-qan-dovrani#9','biologiya','bio-8-qan-dovrani',3,2,'Böyük qan dövranı ürəyin hansı şöbəsindən başlayır?','Böyük dövran sol mədəcikdən başlayır.',array['Sol mədəcikdən','Sağ qulaqcıqdan','Sağ mədəcikdən','Sol qulaqcıqdan'],1),
('bio8-qan-dovrani#10','biologiya','bio-8-qan-dovrani',2,2,'Sakit halda sağlam insanın ürəyi dəqiqədə təqribən neçə dəfə döyünür?','Norma dəqiqədə təqribən 60-80 vurğudur.',array['60-80 dəfə','10-20 dəfə','150-200 dəfə','300-400 dəfə'],1),
('bio8-teneffus#1','biologiya','bio-8-teneffus',1,2,'Tənəffüs sisteminin qaz mübadiləsini aparan əsas orqanı hansıdır?','Qaz mübadiləsi ağciyərlərdə gedir.',array['Ağciyərlər','Ürək','Mədə','Böyrəklər'],1),
('bio8-teneffus#2','biologiya','bio-8-teneffus',2,2,'Ağciyərlərdə qaz mübadiləsi hansı strukturlarda baş verir?','Mübadilə alveol adlanan hava kisəciklərində gedir.',array['Alveollarda','Bronxlarda','Qırtlaqda','Plevrada'],1),
('bio8-teneffus#3','biologiya','bio-8-teneffus',1,2,'Nəfəsalma zamanı qana hansı qaz keçir?','Alveollardan qana oksigen keçir.',array['Oksigen','Karbon qazı','Azot','Helium'],1),
('bio8-teneffus#4','biologiya','bio-8-teneffus',1,2,'Nəfəsvermə zamanı orqanizmdən hansı qaz xaric olur?','Orqanizmdən karbon qazı çıxarılır.',array['Karbon qazı','Oksigen','Hidrogen','Metan'],1),
('bio8-teneffus#5','biologiya','bio-8-teneffus',2,2,'Səs telləri hansı orqanda yerləşir?','Səs telləri qırtlaqdadır.',array['Qırtlaqda','Burunda','Bronxlarda','Dildə'],1),
('bio8-teneffus#6','biologiya','bio-8-teneffus',2,2,'Döş boşluğunu qarın boşluğundan ayıran tənəffüs əzələsi necə adlanır?','Bu, diafraqmadır.',array['Diafraqma','Plevra','Qabırğaarası əzələ','Traxeya'],1),
('bio8-teneffus#7','biologiya','bio-8-teneffus',2,2,'Nəfəs borusu aşağı hissədə nəyə ayrılır?','Nəfəs borusu iki bronxa şaxələnir.',array['İki bronxa','İki qırtlağa','Alveollara','Udlağa'],1),
('bio8-teneffus#8','biologiya','bio-8-teneffus',2,2,'Burunla nəfəs almağın üstünlüyü nədir?','Burun boşluğunda hava təmizlənir, isinir və nəmlənir.',array['Hava təmizlənir, isinir və nəmlənir','Hava daha sürətli keçir','Səs daha ucadan çıxır','Heç bir üstünlüyü yoxdur'],1),
('bio8-teneffus#9','biologiya','bio-8-teneffus',3,2,'Toxuma tənəffüsündə oksigen haradan haraya keçir?','Oksigen qandan toxuma hüceyrələrinə keçir.',array['Qandan hüceyrələrə','Hüceyrələrdən qana','Havadan dəriyə','Mədədən bağırsağa'],1),
('bio8-teneffus#10','biologiya','bio-8-teneffus',1,2,'Siqaret çəkmə ilk növbədə hansı orqanlar sistemini zədələyir?','Tüstü birbaşa tənəffüs yollarına təsir edir.',array['Tənəffüs sistemini','Dayaq-hərəkət sistemini','Görmə orqanını','İfrazat sistemini'],1),
('bio8-hezm#1','biologiya','bio-8-hezm',1,3,'Qidanın həzmi hansı orqanda başlayır?','Həzm ağız boşluğunda — çeynəmə və tüpürcəklə başlayır.',array['Ağız boşluğunda','Mədədə','Nazik bağırsaqda','Qida borusunda'],1),
('bio8-hezm#2','biologiya','bio-8-hezm',2,3,'Mədə şirəsinin tərkibində hansı turşu var?','Mədə şirəsində xlorid turşusu olur.',array['Xlorid turşusu','Sulfat turşusu','Limon turşusu','Sirkə turşusu'],1),
('bio8-hezm#3','biologiya','bio-8-hezm',2,3,'Qida maddələrinin qana sorulması əsasən harada gedir?','Sorulma əsasən nazik bağırsaqda baş verir.',array['Nazik bağırsaqda','Mədədə','Qida borusunda','Ağızda'],1),
('bio8-hezm#4','biologiya','bio-8-hezm',2,3,'Öd hansı orqanda hazırlanır?','Ödü qaraciyər ifraz edir.',array['Qaraciyərdə','Mədədə','Böyrəklərdə','Dalaqda'],1),
('bio8-hezm#5','biologiya','bio-8-hezm',2,3,'Tüpürcəyin tərkibindəki hansı maddələr qidanı parçalamağa başlayır?','Tüpürcək fermentləri nişastanı parçalamağa başlayır.',array['Fermentlər','Vitaminlər','Duzlar','Piqmentlər'],1),
('bio8-hezm#6','biologiya','bio-8-hezm',3,3,'Nazik bağırsağın daxili səthini örtən çıxıntılar necə adlanır?','Sorulma səthini böyüdən xovlardır.',array['Xovlar','Alveollar','Neyronlar','Vəzilər'],1),
('bio8-hezm#7','biologiya','bio-8-hezm',3,3,'Suyun əsas hissəsi bağırsağın hansı şöbəsində sorulur?','Su əsasən yoğun bağırsaqda sorulur.',array['Yoğun bağırsaqda','Qida borusunda','Ağız boşluğunda','Qırtlaqda'],1),
('bio8-hezm#8','biologiya','bio-8-hezm',3,3,'Zülallar həzm prosesində son nəticədə nəyə parçalanır?','Zülallar amin turşularına qədər parçalanır.',array['Amin turşularına','Qlükozaya','Yağ turşularına','Suya'],1),
('bio8-hezm#9','biologiya','bio-8-hezm',2,3,'İnsulin hormonu hansı vəzidə hazırlanır?','İnsulini mədəaltı vəzi ifraz edir.',array['Mədəaltı vəzidə','Qalxanabənzər vəzidə','Böyrəküstü vəzidə','Tüpürcək vəzisində'],1),
('bio8-hezm#10','biologiya','bio-8-hezm',1,3,'Sağlam qidalanma üçün gün ərzində neçə dəfə yemək məsləhət görülür?','Gündə 3-4 dəfə, az-az yemək məsləhətdir.',array['3-4 dəfə','1 dəfə','8-10 dəfə','Yalnız gecə'],1),
('bio8-coxalma#1','biologiya','bio-8-coxalma',1,3,'İki valideyn fərdin iştirakı ilə gedən çoxalma necə adlanır?','Bu, cinsi çoxalmadır.',array['Cinsi çoxalma','Qeyri-cinsi çoxalma','Tumurcuqlama','Bölünmə'],1),
('bio8-coxalma#2','biologiya','bio-8-coxalma',1,3,'Yumurta hüceyrə ilə spermatozoidin birləşməsi necə adlanır?','Bu proses mayalanmadır.',array['Mayalanma','Tozlanma','Cücərmə','Bölünmə'],1),
('bio8-coxalma#3','biologiya','bio-8-coxalma',2,3,'Kəpənəyin yumurta - tırtıl - pup - yetkin fərd inkişafı necə adlanır?','Bu, tam çevrilmə (metamorfoz) ilə inkişafdır.',array['Metamorfozla inkişaf','Birbaşa inkişaf','Tumurcuqlama','Regenerasiya'],1),
('bio8-coxalma#4','biologiya','bio-8-coxalma',1,3,'Məməlilər balalarını nə ilə qidalandırır?','Məməlilər balalarını südlə bəsləyir.',array['Südlə','Nektarla','Yalnız otla','Yalnız həşəratla'],1),
('bio8-coxalma#5','biologiya','bio-8-coxalma',1,3,'Quşlarda embrionun inkişafı harada gedir?','Quş embrionu yumurtanın içində inkişaf edir.',array['Yumurtada','Ana bətnində','Suda sərbəst','Yuvada torpaqda'],1),
('bio8-coxalma#6','biologiya','bio-8-coxalma',2,3,'Aşağıdakılardan hansı qeyri-cinsi çoxalmaya misaldır?','Hidrada tumurcuqlama qeyri-cinsi çoxalmadır.',array['Hidranın tumurcuqlaması','Quşların yumurta qoyması','Balıqların kürü tökməsi','Məməlilərin balalaması'],1),
('bio8-coxalma#7','biologiya','bio-8-coxalma',2,3,'Mayalanmış yumurta hüceyrə necə adlanır?','Mayalanmanın məhsulu ziqotdur.',array['Ziqot','Qamet','Spora','Embrion'],1),
('bio8-coxalma#8','biologiya','bio-8-coxalma',2,3,'İnsanda embrion hansı orqanda inkişaf edir?','Embrion uşaqlıqda (balalıqda) inkişaf edir.',array['Uşaqlıqda','Mədədə','Qaraciyərdə','Ağciyərdə'],1),
('bio8-coxalma#9','biologiya','bio-8-coxalma',1,3,'Çoxalmanın bioloji əhəmiyyəti nədir?','Çoxalma növün nəslinin davamını təmin edir.',array['Nəslin davamını təmin edir','Orqanizmi qidalandırır','Bədəni istilədir','Hərəkəti sürətləndirir'],1),
('bio8-coxalma#10','biologiya','bio-8-coxalma',2,3,'Qurbağanın suda yaşayan quyruqlu sürfəsi necə adlanır?','Qurbağanın sürfəsi çömçəquyruqdur.',array['Çömçəquyruq','Tırtıl','Pup','Kürü'],1),
('bio8-tesnifat#1','biologiya','bio-8-tesnifat',2,4,'Canlıların təsnifatını öyrənən biologiya sahəsi necə adlanır?','Bu elm sistematikadır.',array['Sistematika','Anatomiya','Ekologiya','Genetika'],1),
('bio8-tesnifat#2','biologiya','bio-8-tesnifat',2,4,'Təsnifatın ən kiçik əsas vahidi hansıdır?','Əsas təsnifat vahidi növdür.',array['Növ','Cins','Fəsilə','Aləm'],1),
('bio8-tesnifat#3','biologiya','bio-8-tesnifat',2,4,'Canlılara ikiadlı elmi ad vermə sistemini hansı alim tətbiq etmişdir?','İkiadlı nomenklaturanı Karl Linney tətbiq etmişdir.',array['Karl Linney','Çarlz Darvin','Lui Paster','Qreqor Mendel'],1),
('bio8-tesnifat#4','biologiya','bio-8-tesnifat',1,4,'Onurğa sütunu olan heyvanlar necə adlanır?','Belə heyvanlar onurğalılardır.',array['Onurğalılar','Onurğasızlar','Buğumayaqlılar','Molyusklar'],1),
('bio8-tesnifat#5','biologiya','bio-8-tesnifat',2,4,'Delfin hansı sinfə aiddir?','Delfin suda yaşasa da, balalarını südlə bəsləyən məməlidir.',array['Məməlilər','Balıqlar','Suda-quruda yaşayanlar','Sürünənlər'],1),
('bio8-tesnifat#6','biologiya','bio-8-tesnifat',2,4,'Göbələklər hansı aləmə aid edilir?','Göbələklər ayrıca aləm təşkil edir.',array['Ayrıca göbələklər aləminə','Bitkilər aləminə','Heyvanlar aləminə','Bakteriyalar aləminə'],1),
('bio8-tesnifat#7','biologiya','bio-8-tesnifat',3,4,'Bakteriya hüceyrəsini bitki hüceyrəsindən fərqləndirən əsas xüsusiyyət nədir?','Bakteriyalarda formalaşmış nüvə yoxdur.',array['Formalaşmış nüvənin olmaması','Qlafın olması','Sitoplazmanın olması','Ölçüsünün böyük olması'],1),
('bio8-tesnifat#8','biologiya','bio-8-tesnifat',1,4,'Quşları digər onurğalılardan fərqləndirən bədən örtüyü nədir?','Yalnız quşların bədəni lələklə örtülüdür.',array['Lələk','Pulcuq','Tük','Buynuz lövhələr'],1),
('bio8-tesnifat#9','biologiya','bio-8-tesnifat',1,4,'Aşağıdakılardan hansı suda-quruda yaşayanlara aiddir?','Qurbağa suda-quruda yaşayanlar sinfindəndir.',array['Qurbağa','Kərtənkələ','Delfin','Alabalıq'],1),
('bio8-tesnifat#10','biologiya','bio-8-tesnifat',2,4,'Növün latınca elmi adı neçə sözdən ibarətdir?','İkiadlı sistemdə növ adı 2 sözdən ibarətdir: cins + növ.',array['2','1','3','4'],1),
('bio8-saglamliq#1','biologiya','bio-8-saglamliq',1,4,'Orqanizmin yoluxucu xəstəliklərə qarşı davamlılığı necə adlanır?','Bu, immunitetdir.',array['İmmunitet','Metabolizm','Refleks','Adaptasiya'],1),
('bio8-saglamliq#2','biologiya','bio-8-saglamliq',2,4,'Zəiflədilmiş və ya öldürülmüş mikroblardan hazırlanan qoruyucu preparat necə adlanır?','Bu, peyvənddir (vaksindir).',array['Peyvənd (vaksin)','Antibiotik','Vitamin','Zərdab'],1),
('bio8-saglamliq#3','biologiya','bio-8-saglamliq',3,4,'Çiçək xəstəliyinə qarşı ilk peyvəndi hansı alim tətbiq etmişdir?','İlk peyvəndi E.Cenner tətbiq etmişdir.',array['E. Cenner','L. Paster','İ. Meçnikov','R. Kox'],1),
('bio8-saglamliq#4','biologiya','bio-8-saglamliq',2,4,'Xəstəlik zamanı bədən temperaturunun yüksəlməsi nəyi göstərir?','Temperatur orqanizmin infeksiya ilə mübarizəsinin əlamətidir.',array['Orqanizmin infeksiya ilə mübarizəsini','Qidanın çatışmadığını','Yuxunun pozulduğunu','Əzələlərin böyüdüyünü'],1),
('bio8-saglamliq#5','biologiya','bio-8-saglamliq',1,4,'Gün rejiminə əməl etmək orqanizm üçün nə üçün faydalıdır?','Rejim iş qabiliyyətini və sağlamlığı qoruyur.',array['İş qabiliyyətini və sağlamlığı qoruyur','Boyu dərhal uzadır','Yaddaşı silir','Heç bir təsiri yoxdur'],1),
('bio8-saglamliq#6','biologiya','bio-8-saglamliq',2,4,'Güclü qanaxma zamanı ilk yardım necə göstərilir?','Yara sıxılır və sıxıcı sarğı qoyulur.',array['Yaranı sıxıb sarğı qoymaq','Yaranı su ilə doldurmaq','Heç nə etməmək','Yalnız dərman içmək'],1),
('bio8-saglamliq#7','biologiya','bio-8-saglamliq',1,4,'Hansı zərərli vərdiş ağciyər xərçəngi riskini kəskin artırır?','Siqaret tüstüsündəki maddələr xərçəngə səbəb ola bilir.',array['Siqaret çəkmə','Gec yatmaq','Çox oxumaq','Şirniyyat yemək'],1),
('bio8-saglamliq#8','biologiya','bio-8-saglamliq',2,4,'Orqanizmdə vitaminlərin uzunmüddətli çatışmazlığı necə adlanır?','Bu hal avitaminozdur.',array['Avitaminoz','Allergiya','İnfeksiya','Hipertoniya'],1),
('bio8-saglamliq#9','biologiya','bio-8-saglamliq',1,4,'Məktəbli gecə ərzində təqribən neçə saat yatmalıdır?','Yeniyetmə üçün 8-9 saat yuxu normaldır.',array['8-9 saat','3-4 saat','12-14 saat','5 saatdan az'],1),
('bio8-saglamliq#10','biologiya','bio-8-saglamliq',2,4,'Təmiz hava, günəş və su ilə orqanizmin möhkəmləndirilməsi necə adlanır?','Bu, bədənin bərkidilməsidir.',array['Bərkidilmə','Müalicə','Dezinfeksiya','Karantin'],1),
('cog8-kesfler#1','cografiya','cog-8-kesfler',1,1,'1492-ci ildə Amerikanı kəşf etmiş səyyah kimdir?','X.Kolumb 1492-ci ildə Amerika sahillərinə çatmışdır.',array['X. Kolumb','F. Magellan','Vasko da Qama','C. Kuk'],1),
('cog8-kesfler#2','cografiya','cog-8-kesfler',2,1,'İlk dünya səyahətinə başçılıq etmiş dənizçi kimdir?','F.Magellanın ekspedisiyası ilk dəfə dünyanı dolanmışdır.',array['F. Magellan','X. Kolumb','Marko Polo','A. Nikitin'],1),
('cog8-kesfler#3','cografiya','cog-8-kesfler',2,1,'Afrikanı dolanaraq dəniz yolu ilə Hindistana çatmış səyyah kimdir?','Vasko da Qama 1498-ci ildə Hindistana dəniz yolu açmışdır.',array['Vasko da Qama','C. Kuk','F. Magellan','Bellinshauzen'],1),
('cog8-kesfler#4','cografiya','cog-8-kesfler',2,1,'Magellanın ekspedisiyası nəyi əməli olaraq sübut etdi?','Dünyanı dolanmaq Yerin kürə formasında olduğunu sübut etdi.',array['Yerin kürə formasında olduğunu','Ayın Yerdən böyük olduğunu','Okeanların dayaz olduğunu','Qitələrin birləşdiyini'],1),
('cog8-kesfler#5','cografiya','cog-8-kesfler',2,1,'Avstraliya və Yeni Zelandiya sahillərini geniş tədqiq etmiş ingilis səyyahı kimdir?','C.Kuk bu əraziləri XVIII əsrdə tədqiq etmişdir.',array['C. Kuk','Vasko da Qama','X. Kolumb','D. Livinqston'],1),
('cog8-kesfler#6','cografiya','cog-8-kesfler',3,1,'1820-ci ildə Antarktidanı kəşf etmiş ekspedisiyaya kimlər başçılıq edirdi?','Antarktidanı Bellinshauzen və Lazarevin ekspedisiyası kəşf etmişdir.',array['Bellinshauzen və Lazarev','Kolumb və Vespuççi','Kuk və Magellan','Amundsen və Skott'],1),
('cog8-kesfler#7','cografiya','cog-8-kesfler',2,1,'Şərq ölkələri haqqında məşhur səyahət kitabının müəllifi olan venesiyalı tacir kimdir?','Marko Polonun kitabı Avropada Şərq haqqında əsas mənbə idi.',array['Marko Polo','İbn Bətutə','Kolumb','Vasko da Qama'],1),
('cog8-kesfler#8','cografiya','cog-8-kesfler',3,1,'Böyük coğrafi kəşflərin əsas səbəbi nə idi?','Avropalılar Şərqə yeni dəniz ticarət yolları axtarırdılar.',array['Şərqə yeni ticarət yolları axtarışı','İdman marağı','Yeni dillər öyrənmək istəyi','Xəritələrin çox olması'],1),
('cog8-kesfler#9','cografiya','cog-8-kesfler',2,1,'Yeni qitə kimin şərəfinə Amerika adlandırılmışdır?','Qitə Ameriqo Vespuççinin adı ilə adlandırılmışdır.',array['Ameriqo Vespuççi','Xristofor Kolumb','Ferdinand Magellan','Ceyms Kuk'],1),
('cog8-kesfler#10','cografiya','cog-8-kesfler',2,1,'Kolumb çatdığı torpaqları hara hesab edirdi?','Kolumb Hindistana çatdığını düşünürdü, ona görə yerliləri hindular adlandırdı.',array['Hindistan','Çin','Afrika','Avstraliya'],1),
('cog8-xerite#1','cografiya','cog-8-xerite',2,1,'Miqyası 1 : 100000 olan xəritədə 1 sm məsafə yerdə neçə kilometrə uyğundur?','100000 sm = 1 km. Deməli 1 sm xəritədə 1 km yerdədir.',array['1 km','10 km','100 km','0,1 km'],1),
('cog8-xerite#2','cografiya','cog-8-xerite',1,1,'Yer səthinin müstəvi üzərində kiçildilmiş şərti təsviri necə adlanır?','Bu, coğrafi xəritədir.',array['Xəritə','Qlobus','Fotoşəkil','Cədvəl'],1),
('cog8-xerite#3','cografiya','cog-8-xerite',2,1,'Xəritədə relyef əsasən hansı üsullarla göstərilir?','Relyef horizontallar və rəng qatları ilə təsvir olunur.',array['Horizontallar və rənglə','Yalnız oxlarla','Şəkillərlə','Cədvəllərlə'],1),
('cog8-xerite#4','cografiya','cog-8-xerite',1,1,'Ekvatora paralel çəkilmiş şərti xətlər necə adlanır?','Bunlar paralellərdir.',array['Paralellər','Meridianlar','Horizontallar','İzoxətlər'],1),
('cog8-xerite#5','cografiya','cog-8-xerite',1,1,'Qütbləri birləşdirən şərti yarımdairələr necə adlanır?','Bunlar meridianlardır.',array['Meridianlar','Paralellər','Tropiklər','Qütb dairələri'],1),
('cog8-xerite#6','cografiya','cog-8-xerite',2,1,'Coğrafi enlik hansı xətdən başlayaraq ölçülür?','Enlik ekvatordan şimala və cənuba ölçülür.',array['Ekvatordan','Qrinviç meridianından','Şimal qütbündən','Tropikdən'],1),
('cog8-xerite#7','cografiya','cog-8-xerite',2,1,'Coğrafi uzunluq hansı meridiandan başlayaraq ölçülür?','Uzunluq başlanğıc (Qrinviç) meridianından ölçülür.',array['Qrinviç meridianından','Ekvatordan','180° meridianından','Bakı meridianından'],1),
('cog8-xerite#8','cografiya','cog-8-xerite',1,1,'Yerin formasını ən düzgün əks etdirən model hansıdır?','Qlobus Yerin kiçildilmiş dəqiq modelidir.',array['Qlobus','Divar xəritəsi','Plan','Atlas'],1),
('cog8-xerite#9','cografiya','cog-8-xerite',2,1,'Miqyasın üç ifadə forması: ədədi, adlı və hansıdır?','Miqyas ədədi, adlı və xətti formada göstərilir.',array['Xətti','Rəqəmsal','Şaquli','Çəki'],1),
('cog8-xerite#10','cografiya','cog-8-xerite',2,1,'Bakı təqribən 40° şimal enliyində yerləşir. Bu nə deməkdir?','Bakı ekvatordan 40° şimalda yerləşir.',array['Ekvatordan 40° şimaldadır','Qütbdən 40° cənubdadır','Qrinviçdən 40° qərbdədir','Dəniz səviyyəsindən 40 m yüksəkdədir'],1),
('cog8-yer-hereketi#1','cografiya','cog-8-yer-hereketi',1,2,'Yer öz oxu ətrafında bir tam dövrünü nə qədər müddətə başa vurur?','Sutkalıq fırlanma 24 saat çəkir.',array['24 saata','12 saata','365 günə','30 günə'],1),
('cog8-yer-hereketi#2','cografiya','cog-8-yer-hereketi',1,2,'Yer Günəş ətrafında bir tam dövrünü nə qədər müddətə başa vurur?','İllik hərəkət təqribən 365 gün 6 saat çəkir.',array['365 gün 6 saata','24 saata','28 günə','100 günə'],1),
('cog8-yer-hereketi#3','cografiya','cog-8-yer-hereketi',2,2,'Gecə və gündüzün əvəzlənməsinin səbəbi nədir?','Yer öz oxu ətrafında fırlandığı üçün gecə-gündüz əvəzlənir.',array['Yerin öz oxu ətrafında fırlanması','Günəşin Yer ətrafında dövr etməsi','Ayın hərəkəti','Buludların hərəkəti'],1),
('cog8-yer-hereketi#4','cografiya','cog-8-yer-hereketi',2,2,'Fəsillərin əvəzlənməsinin səbəbi nədir?','Ox mailliyi ilə birlikdə Günəş ətrafında hərəkət fəsilləri yaradır.',array['Ox mailliyi və Günəş ətrafında hərəkət','Yerin öz oxu ətrafında fırlanması','Ayın cazibəsi','Okean axınları'],1),
('cog8-yer-hereketi#5','cografiya','cog-8-yer-hereketi',2,2,'Yer kürəsi neçə saat qurşağına bölünür?','Yer 24 saat qurşağına bölünüb.',array['24','12','36','60'],1),
('cog8-yer-hereketi#6','cografiya','cog-8-yer-hereketi',2,2,'21 mart və 23 sentyabr tarixləri necə adlanır?','Bu günlərdə gecə ilə gündüz bərabər olur.',array['Gecə-gündüz bərabərliyi günləri','Gündönümü günləri','Qütb günləri','Ay tutulması günləri'],1),
('cog8-yer-hereketi#7','cografiya','cog-8-yer-hereketi',1,2,'Qonşu saat qurşaqları arasında vaxt fərqi nə qədərdir?','Qonşu qurşaqlar arasında fərq 1 saatdır.',array['1 saat','30 dəqiqə','2 saat','15 dəqiqə'],1),
('cog8-yer-hereketi#8','cografiya','cog-8-yer-hereketi',2,2,'Şimal yarımkürəsində ən uzun gündüz hansı tarixə düşür?','22 iyun yay gündönümü — ən uzun gündüzdür.',array['22 iyun','22 dekabr','21 mart','1 yanvar'],1),
('cog8-yer-hereketi#9','cografiya','cog-8-yer-hereketi',3,2,'Qütb dairələrindən yüksək enliklərdə yayda Günəşin batmaması necə adlanır?','Bu hadisə qütb günüdür.',array['Qütb günü','Qütb gecəsi','Ağ gecələr','Günəş tutulması'],1),
('cog8-yer-hereketi#10','cografiya','cog-8-yer-hereketi',2,2,'Fevrala bir gün əlavə olunan il necə adlanır?','Hər 4 ildən bir fevral 29 gün olur — uzun il.',array['Uzun il','Qısa il','Günəş ili','Ay ili'],1),
('cog8-tektonik#1','cografiya','cog-8-tektonik',1,2,'Yerin bərk üst təbəqəsi necə adlanır?','Yer qabığı və üst mantiyanın bərk hissəsi litosferdir.',array['Litosfer','Atmosfer','Hidrosfer','Biosfer'],1),
('cog8-tektonik#2','cografiya','cog-8-tektonik',2,2,'Litosfer hansı hissələrdən təşkil olunub?','Litosfer iri tavalardan ibarətdir və onlar yavaş hərəkət edir.',array['İri tavalardan','Bütöv bir lövhədən','Maye qatlardan','Yalnız qumdan'],1),
('cog8-tektonik#3','cografiya','cog-8-tektonik',1,2,'Yer qabığında qırılma və sürüşmələr nəticəsində yaranan təkanlar necə adlanır?','Bu təbii hadisə zəlzələdir.',array['Zəlzələ','Vulkan püskürməsi','Qasırğa','Daşqın'],1),
('cog8-tektonik#4','cografiya','cog-8-tektonik',2,2,'Zəlzələləri qeydə alan cihaz necə adlanır?','Zəlzələlər seysmoqrafla qeydə alınır.',array['Seysmoqraf','Barometr','Termometr','Anemometr'],1),
('cog8-tektonik#5','cografiya','cog-8-tektonik',1,2,'Maqmanın Yer səthinə püskürdüyü dağ necə adlanır?','Bu, vulkandır.',array['Vulkan','Platforma','Yayla','Dərə'],1),
('cog8-tektonik#6','cografiya','cog-8-tektonik',1,2,'Yer səthinə çıxmış maqma necə adlanır?','Səthə çıxan maqma lava adlanır.',array['Lava','Kül','Qranit','Bazalt'],1),
('cog8-tektonik#7','cografiya','cog-8-tektonik',3,2,'Zəlzələnin yerin dərinliyindəki mənbəyi necə adlanır?','Dərinlikdəki mənbə ocaq (hiposentr) adlanır.',array['Ocaq (hiposentr)','Episentr','Krater','Mantiya'],1),
('cog8-tektonik#8','cografiya','cog-8-tektonik',2,2,'Litosfer tavalarının toqquşduğu sərhədlərdə adətən nə əmələ gəlir?','Toqquşma zonalarında dağ sistemləri yaranır.',array['Dağ sistemləri','Düzənliklər','Səhralar','Buzlaqlar'],1),
('cog8-tektonik#9','cografiya','cog-8-tektonik',3,2,'Sakit okeanın ətrafındakı vulkan və zəlzələ qurşağı necə adlanır?','Bu zona Odlu həlqə adlanır.',array['Odlu həlqə','Qızıl qurşaq','Buz həlqəsi','Qara dairə'],1),
('cog8-tektonik#10','cografiya','cog-8-tektonik',2,2,'Azərbaycanda geniş yayılmış vulkan növü hansıdır?','Azərbaycan palçıq vulkanlarının sayına görə dünyada öndədir.',array['Palçıq vulkanları','Lava vulkanları','Buz vulkanları','Qalxanvari vulkanlar'],1),
('cog8-atmosfer#1','cografiya','cog-8-atmosfer',1,3,'Atmosferin hava hadisələri baş verən ən aşağı qatı necə adlanır?','Bütün hava hadisələri troposferdə gedir.',array['Troposfer','Stratosfer','Mezosfer','Termosfer'],1),
('cog8-atmosfer#2','cografiya','cog-8-atmosfer',2,3,'Havanın rütubətini ölçən cihaz necə adlanır?','Rütubət hiqrometrlə ölçülür.',array['Hiqrometr','Barometr','Seysmoqraf','Dinamometr'],1),
('cog8-atmosfer#3','cografiya','cog-8-atmosfer',2,3,'Küləyin yaranmasının səbəbi nədir?','Külək təzyiq fərqi nəticəsində yaranır.',array['Təzyiq fərqi','Yağışın yağması','Günəşin batması','Dağların hündürlüyü'],1),
('cog8-atmosfer#4','cografiya','cog-8-atmosfer',3,3,'Yüksəkliyə qalxdıqca havanın temperaturu hər 1000 metrdə orta hesabla necə dəyişir?','Troposferdə hər 1000 m-də temperatur təqribən 6 °C azalır.',array['6 °C azalır','6 °C artır','Dəyişmir','20 °C azalır'],1),
('cog8-atmosfer#5','cografiya','cog-8-atmosfer',2,3,'Külək hansı təzyiq sahəsindən hansına doğru əsir?','Hava yüksək təzyiqdən alçaq təzyiqə hərəkət edir.',array['Yüksək təzyiqdən alçağa','Alçaq təzyiqdən yüksəyə','Yalnız şimaldan cənuba','Yalnız dənizdən quruya'],1),
('cog8-atmosfer#6','cografiya','cog-8-atmosfer',2,3,'Küləyin sürətini ölçən cihaz necə adlanır?','Küləyin sürəti anemometrlə ölçülür.',array['Anemometr','Hiqrometr','Termometr','Areometr'],1),
('cog8-atmosfer#7','cografiya','cog-8-atmosfer',1,3,'Buludlardan yerə düşən yağış, qar və dolu birlikdə necə adlanır?','Bunlar atmosfer yağıntılarıdır.',array['Yağıntılar','Buxarlanma','Şeh','Duman'],1),
('cog8-atmosfer#8','cografiya','cog-8-atmosfer',2,3,'Düşən yağıntının miqdarını ölçmək üçün hansı cihazdan istifadə olunur?','Yağıntının miqdarı yağıntıölçənlə təyin edilir.',array['Yağıntıölçən','Anemometr','Kompas','Areometr'],1),
('cog8-atmosfer#9','cografiya','cog-8-atmosfer',2,3,'Gün ərzində ən yüksək temperatur 24 °C, ən aşağı 10 °C olub. Sutkalıq amplitud neçə dərəcədir?','Amplitud = 24 − 10 = 14 °C.',array['14 °C','34 °C','24 °C','10 °C'],1),
('cog8-atmosfer#10','cografiya','cog-8-atmosfer',1,3,'Hər hansı ərazi üçün havanın çoxillik rejimi necə adlanır?','Çoxillik hava rejimi iqlimdir.',array['İqlim','Hava proqnozu','Fəsil','Sinoptik xəritə'],1),
('cog8-hidrosfer#1','cografiya','cog-8-hidrosfer',2,3,'Hidrosferin ən böyük hissəsini nə təşkil edir?','Hidrosferin təqribən 96 faizi Dünya okeanının payına düşür.',array['Dünya okeanı','Çaylar','Göllər','Yeraltı sular'],1),
('cog8-hidrosfer#2','cografiya','cog-8-hidrosfer',1,3,'Dünyanın ən böyük və ən dərin okeanı hansıdır?','Sakit okean həm sahəcə, həm dərinlikcə birincidir.',array['Sakit okean','Atlantik okeanı','Hind okeanı','Şimal Buzlu okeanı'],1),
('cog8-hidrosfer#3','cografiya','cog-8-hidrosfer',2,3,'Okean suyunu içməli sudan fərqləndirən əsas xüsusiyyət nədir?','Okean suyu duzludur.',array['Duzluluğu','Rəngi','İstiliyi','Qoxusu'],1),
('cog8-hidrosfer#4','cografiya','cog-8-hidrosfer',2,3,'Çayın dənizə, gölə və ya başqa çaya töküldüyü yer necə adlanır?','Çayın töküldüyü yer mənsəb adlanır.',array['Mənsəb','Mənbə','Şəlalə','Körfəz'],1),
('cog8-hidrosfer#5','cografiya','cog-8-hidrosfer',2,3,'Çayın axdığı uzunsov çökəklik necə adlanır?','Çay öz dərəsində — yatağında axır.',array['Çay dərəsi','Zirvə','Yayla','Aşırım'],1),
('cog8-hidrosfer#6','cografiya','cog-8-hidrosfer',2,3,'Dünyanın ən uzun çaylarından biri hesab edilən Afrika çayı hansıdır?','Nil təqribən 6700 km uzunluğundadır.',array['Nil','Volqa','Kür','Dunay'],1),
('cog8-hidrosfer#7','cografiya','cog-8-hidrosfer',2,3,'Dünyanın ən dərin gölü hansıdır?','Baykalın dərinliyi 1600 metrdən çoxdur.',array['Baykal','Xəzər','Göygöl','Urmiya'],1),
('cog8-hidrosfer#8','cografiya','cog-8-hidrosfer',3,3,'Yer üzündə şirin suyun ən böyük ehtiyatı harada toplanmışdır?','Şirin suyun çoxu buzlaqlardadır.',array['Buzlaqlarda','Çaylarda','Göllərdə','Quyularda'],1),
('cog8-hidrosfer#9','cografiya','cog-8-hidrosfer',3,3,'Dünya okeanı suyunun orta duzluluğu təqribən neçə promildir?','Okean suyunun orta duzluluğu təqribən 35 promildir.',array['35 promil','5 promil','100 promil','350 promil'],1),
('cog8-hidrosfer#10','cografiya','cog-8-hidrosfer',1,3,'Azərbaycanın ən böyük çayı hansıdır?','Kür Azərbaycanın ən uzun və bol sulu çayıdır.',array['Kür','Araz','Samur','Tərtər'],1),
('cog8-olkeler#1','cografiya','cog-8-olkeler',2,4,'Dünya əhalisi ən sıx hansı regionda məskunlaşmışdır?','Əhalinin böyük hissəsi Şərqi və Cənubi Asiyada yaşayır.',array['Şərqi və Cənubi Asiyada','Antarktidada','Səhra zonasında','Yüksək dağlıq ərazilərdə'],1),
('cog8-olkeler#2','cografiya','cog-8-olkeler',2,4,'Hazırda əhalisinin sayına görə dünyada birinci olan ölkə hansıdır?','2023-cü ildən Hindistan əhali sayına görə birincidir.',array['Hindistan','Rusiya','ABŞ','Braziliya'],1),
('cog8-olkeler#3','cografiya','cog-8-olkeler',2,4,'Şəhərlərin və şəhər əhalisinin payının artması prosesi necə adlanır?','Bu proses urbanizasiyadır.',array['Urbanizasiya','Miqrasiya','Demoqrafiya','İnteqrasiya'],1),
('cog8-olkeler#4','cografiya','cog-8-olkeler',1,4,'Ərazisinə görə dünyanın ən böyük dövləti hansıdır?','Rusiya 17 milyon km²-dən artıq əraziyə malikdir.',array['Rusiya','Kanada','Çin','ABŞ'],1),
('cog8-olkeler#5','cografiya','cog-8-olkeler',2,4,'Əhalinin bir ərazidən başqa əraziyə köçməsi necə adlanır?','Əhalinin yerdəyişməsi miqrasiya adlanır.',array['Miqrasiya','Urbanizasiya','Demoqrafiya','Repatriasiya'],1),
('cog8-olkeler#6','cografiya','cog-8-olkeler',1,4,'Azərbaycan hansı coğrafi regionda yerləşir?','Azərbaycan Cənubi Qafqazda yerləşir.',array['Cənubi Qafqazda','Mərkəzi Asiyada','Şərqi Avropada','Yaxın Şərqdə'],1),
('cog8-olkeler#7','cografiya','cog-8-olkeler',3,4,'Birləşmiş Millətlər Təşkilatının mənzil-qərargahı hansı şəhərdədir?','BMT-nin mənzil-qərargahı Nyu-Yorkdadır.',array['Nyu-York','London','Paris','Cenevrə'],1),
('cog8-olkeler#8','cografiya','cog-8-olkeler',2,4,'Sahəsinə görə dünyanın ən kiçik dövləti hansıdır?','Vatikanın sahəsi yarım km²-dən azdır.',array['Vatikan','Monako','Lüksemburq','Malta'],1),
('cog8-olkeler#9','cografiya','cog-8-olkeler',2,4,'Əhalinin təbii artımı necə müəyyən olunur?','Doğulanların sayından ölənlərin sayı çıxılır.',array['Doğulanlarla ölənlərin fərqi ilə','Gələn turistlərin sayı ilə','Şəhərlərin böyüməsi ilə','Məktəblilərin sayı ilə'],1),
('cog8-olkeler#10','cografiya','cog-8-olkeler',1,4,'Azərbaycanın əhalisi təqribən neçə milyondur?','Azərbaycan əhalisi təqribən 10 milyondur.',array['10 milyon','1 milyon','50 milyon','100 milyon'],1),
('cog8-ekologiya#1','cografiya','cog-8-ekologiya',1,4,'Nadir və nəsli kəsilməkdə olan növlərin daxil edildiyi siyahı necə adlanır?','Belə növlər Qırmızı kitaba yazılır.',array['Qırmızı kitab','Yaşıl jurnal','Ağ siyahı','Qara kitab'],1),
('cog8-ekologiya#2','cografiya','cog-8-ekologiya',2,4,'Canlıları Günəşin ultrabənövşəyi şüalarından qoruyan atmosfer qatı hansıdır?','Ozon qatı ultrabənövşəyi şüaları tutur.',array['Ozon qatı','Duman qatı','Buz qatı','Toz qatı'],1),
('cog8-ekologiya#3','cografiya','cog-8-ekologiya',2,4,'Şəhərlərdə havanı ən çox çirkləndirən mənbələr hansılardır?','Əsas mənbələr nəqliyyat və sənaye müəssisələridir.',array['Nəqliyyat və sənaye','Parklar və bağlar','Məktəblər','Kitabxanalar'],1),
('cog8-ekologiya#4','cografiya','cog-8-ekologiya',1,4,'Təbiəti qorumaq və istirahət üçün yaradılan xüsusi mühafizə olunan ərazi necə adlanır?','Belə ərazilərdən biri milli parkdır.',array['Milli park','Sənaye zonası','Yaşayış massivi','Ticarət mərkəzi'],1),
('cog8-ekologiya#5','cografiya','cog-8-ekologiya',2,4,'İstixana effektini gücləndirən əsas qaz hansıdır?','Karbon qazının artması istixana effektini gücləndirir.',array['Karbon qazı','Oksigen','Azot','Helium'],1),
('cog8-ekologiya#6','cografiya','cog-8-ekologiya',2,4,'Meşələrin kütləvi qırılması torpaqda hansı prosesə səbəb olur?','Bitki örtüyü itən torpaq yuyulur — eroziyaya uğrayır.',array['Eroziyaya','Münbitləşməyə','Şoranlaşmanın azalmasına','Rütubətin artmasına'],1),
('cog8-ekologiya#7','cografiya','cog-8-ekologiya',2,4,'İşlənmiş kağız və plastikin yenidən istehsala qaytarılması necə adlanır?','Bu, tullantıların təkrar emalıdır.',array['Təkrar emal','Yandırılma','Basdırılma','Daşınma'],1),
('cog8-ekologiya#8','cografiya','cog-8-ekologiya',3,4,'Azərbaycanda yaradılmış ilk qoruq hansıdır?','Göygöl qoruğu 1925-ci ildə yaradılmışdır.',array['Göygöl qoruğu','Qızılağac qoruğu','Şirvan qoruğu','Zaqatala qoruğu'],1),
('cog8-ekologiya#9','cografiya','cog-8-ekologiya',2,4,'Xəzər dənizinin əsas ekoloji problemi nədir?','Xəzərin əsas problemi sənaye və məişət tullantıları ilə çirklənmədir.',array['Çirklənmə','Suyun tam şirinləşməsi','Buz bağlaması','Adaların çoxalması'],1),
('cog8-ekologiya#10','cografiya','cog-8-ekologiya',1,4,'Enerjiyə qənaət üçün məişətdə ən sadə addım hansıdır?','İstifadə olunmayan işıqları söndürmək enerjiyə qənaətdir.',array['Lazımsız işıqları söndürmək','Bütün cihazları daim işlətmək','Pəncərələri qışda açıq saxlamaq','Suyu axar saxlamaq'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = d.fenn
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
   where owner_type = 'platform'
     and (ext_key like 'fiz8-%' or ext_key like 'kim8-%'
          or ext_key like 'bio8-%' or ext_key like 'cog8-%');
  if n <> 280 then
    raise exception 'fenn8 suallari: 280 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'fiz8-%' or q.ext_key like 'kim8-%'
          or q.ext_key like 'bio8-%' or q.ext_key like 'cog8-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'fiz8-%' or ext_key like 'kim8-%'
      or ext_key like 'bio8-%' or ext_key like 'cog8-%';
  if k <> 28 then
    raise exception 'movzu sayi 28 deyil: %', k;
  end if;
  raise notice '8-ci sinif tebiet fennleri banki: % sual, 28 movzu (fiz, kim, bio, cog).', n;
end $$;
