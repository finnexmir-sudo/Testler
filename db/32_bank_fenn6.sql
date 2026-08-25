-- =====================================================================
--  32_bank_fenn6.sql : 6-CI SINIF - FIZIKA, BIOLOGIYA, COGRAFIYA
--
--  BU FAYL ELLE YAZILMIR - tools/fenn6.py yaradir:
--      python3 tools/fenn6.py
--
--  Fizika 4 + Biologiya 8 + Cografiya 7 = 19 movzu x 10 = 190.
--  ext_key: fiz6-/bio6-/cog6-...
--  ON SERT: 29_movzular_orta6.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('fizika','fiz-6-giris'),
                                ('biologiya','bio-6-huceyre'),
                                ('cografiya','cog-6-kainat'))
     having count(*) = 3) then
    raise exception 'ONCE 29_movzular_orta6.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'fiz6-%' or q.ext_key like 'bio6-%'
        or q.ext_key like 'cog6-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('fiz6-giris#1','fizika','fiz-6-giris',1,1,'Fizika elmi nəyi öyrənir?','Fizika təbiət hadisələrini və onların qanunlarını öyrənir.',array['Təbiət hadisələrini','Yalnız bitkiləri','Yalnız tarixi','Yalnız dilləri'],1),
('fiz6-giris#2','fizika','fiz-6-giris',2,1,'Hansı hadisə fiziki hadisədir?','Buzun əriməsi — maddənin halı dəyişir, özü dəyişmir.',array['Buzun əriməsi','Ağacın böyüməsi','Dəmirin paslanması','Südün turşuması'],1),
('fiz6-giris#3','fizika','fiz-6-giris',2,1,'Hansı fiziki kəmiyyətdir?','Kütlə ölçülə bilən fiziki kəmiyyətdir.',array['Kütlə','Sevinc','Dad','Yuxu'],1),
('fiz6-giris#4','fizika','fiz-6-giris',2,1,'Uzunluğun beynəlxalq sistemdə (BS) vahidi hansıdır?','Uzunluğun BS vahidi metrdir.',array['Metr','Kiloqram','Saniyə','Litr'],1),
('fiz6-giris#5','fizika','fiz-6-giris',2,1,'Zamanın BS vahidi hansıdır?','Zamanın BS vahidi saniyədir.',array['Saniyə','Metr','Dərəcə','Qram'],1),
('fiz6-giris#6','fizika','fiz-6-giris',2,1,'Mayelərin həcmini ölçmək üçün hansı cihazdan istifadə olunur?','Həcm menzurka (ölçü silindri) ilə ölçülür.',array['Menzurka','Tərəzi','Xətkeş','Kompas'],1),
('fiz6-giris#7','fizika','fiz-6-giris',2,1,'Fizikada əsas öyrənmə metodları hansılardır?','Müşahidə və təcrübə əsas metodlardır.',array['Müşahidə və təcrübə','Yalnız əzbərləmə','Yalnız şəkil çəkmə','Təxmin etmə'],1),
('fiz6-giris#8','fizika','fiz-6-giris',3,1,'Ölçmə nədir?','Kəmiyyətin qəbul olunmuş vahidlə müqayisəsidir.',array['Kəmiyyətin vahidlə müqayisəsi','Cihazın təmiri','Rəqəmlərin yazılması','Cədvəlin çəkilməsi'],1),
('fiz6-giris#9','fizika','fiz-6-giris',2,1,'Klassik mexanikanın banilərindən sayılan alim kimdir?','İsaak Nyuton mexanikanın əsasını qoymuşdur.',array['İsaak Nyuton','Şekspir','Motsart','Kolumb'],1),
('fiz6-giris#10','fizika','fiz-6-giris',3,1,'Ölçmənin dəqiqliyi nədən asılıdır?','Cihazın bölgü qiymətindən asılıdır.',array['Cihazın bölgü qiymətindən','Otağın rəngindən','Günün vaxtından','Ölçənin boyundan'],1),
('fiz6-materiya#1','fizika','fiz-6-materiya',2,2,'Materiya nədir?','Kainatda mövcud olan hər şey — maddə və fiziki sahə.',array['Kainatda mövcud olan hər şey','Yalnız su','Yalnız hava','Yalnız işıq'],1),
('fiz6-materiya#2','fizika','fiz-6-materiya',2,2,'Hansı maddəyə misaldır?','Su maddədir; sahələr maddə deyil, materiyanın başqa növüdür.',array['Su','Maqnit sahəsi','Elektrik sahəsi','Qravitasiya sahəsi'],1),
('fiz6-materiya#3','fizika','fiz-6-materiya',2,2,'Fiziki cisim nədir?','Maddədən təşkil olunmuş əşyadır: stol, daş, qələm.',array['Maddədən təşkil olunmuş əşya','İşıq şüası','Səs dalğası','Kölgə'],1),
('fiz6-materiya#4','fizika','fiz-6-materiya',2,2,'Atomun mərkəzində nə yerləşir?','Atomun mərkəzində nüvə yerləşir.',array['Nüvə','Molekul','Hüceyrə','Toz'],1),
('fiz6-materiya#5','fizika','fiz-6-materiya',2,2,'Molekul nədir?','Atomlardan təşkil olunmuş hissəcikdir.',array['Atomlardan təşkil olunmuş hissəcik','Ən böyük cisim','Planet','Mineral'],1),
('fiz6-materiya#6','fizika','fiz-6-materiya',2,2,'Maddənin neçə əsas aqreqat halı var?','Üç əsas hal: bərk, maye, qaz.',array['3','2','5','10'],1),
('fiz6-materiya#7','fizika','fiz-6-materiya',2,2,'Su buxarı maddənin hansı halıdır?','Buxar qaz halıdır.',array['Qaz','Bərk','Maye','Heç biri'],1),
('fiz6-materiya#8','fizika','fiz-6-materiya',2,2,'Bərk cisimlərin xarakterik xüsusiyyəti nədir?','Bərk cisimlər öz formasını saxlayır.',array['Öz formasını saxlayır','Qabın formasını alır','Bütün fəzanı doldurur','Görünmür'],1),
('fiz6-materiya#9','fizika','fiz-6-materiya',2,2,'Mayelərin xarakterik xüsusiyyəti hansıdır?','Maye tökuldüyü qabın formasını alır.',array['Qabın formasını alır','Formasını saxlayır','Sıxıla bilir','Yalnız isti olur'],1),
('fiz6-materiya#10','fizika','fiz-6-materiya',3,2,'Şüşə stəkan maddədir, yoxsa cisim?','Stəkan cisimdir, şüşə isə maddədir.',array['Cisimdir','Maddədir','Sahədir','Hadisədir'],1),
('fiz6-madde#1','fizika','fiz-6-madde',2,3,'Diffuziya nədir?','Bir maddə hissəciklərinin digərinin arasına yayılmasıdır.',array['Maddələrin qarışması (yayılması)','Suyun donması','Cismin düşməsi','İşığın sınması'],1),
('fiz6-madde#2','fizika','fiz-6-madde',2,3,'Ətrin otağa yayılması hansı hadisəyə misaldır?','Qoxu hissəcikləri havada yayılır — diffuziyadır.',array['Diffuziyaya','Zəlzələyə','Cazibəyə','Elektrikləşməyə'],1),
('fiz6-madde#3','fizika','fiz-6-madde',2,3,'Qızdırılan cisimlər adətən nə edir?','İstidən cisimlər genişlənir.',array['Genişlənir','Sıxılır','Yox olur','Dəyişmir'],1),
('fiz6-madde#4','fizika','fiz-6-madde',3,3,'Sıxlıq hansı düsturla hesablanır?','Sıxlıq = kütlə : həcm.',array['Kütlə : həcm','Kütlə × həcm','Həcm : kütlə','Kütlə + həcm'],1),
('fiz6-madde#5','fizika','fiz-6-madde',3,3,'Kütləsi 200 q, həcmi 100 sm³ olan cismin sıxlığı neçədir?','200 : 100 = 2 q/sm³.',array['2 q/sm³','20 q/sm³','0,5 q/sm³','300 q/sm³'],1),
('fiz6-madde#6','fizika','fiz-6-madde',2,3,'Kütlənin BS vahidi hansıdır?','Kütlənin BS vahidi kiloqramdır.',array['Kiloqram','Metr','Litr','Dərəcə'],1),
('fiz6-madde#7','fizika','fiz-6-madde',3,3,'Suyun sıxlığı təxminən neçə q/sm³-dür?','Suyun sıxlığı 1 q/sm³-dür.',array['1','10','100','0,1'],1),
('fiz6-madde#8','fizika','fiz-6-madde',2,3,'Normal şəraitdə su neçə dərəcədə qaynayır?','Su 100°C-də qaynayır.',array['100°C-də','50°C-də','0°C-də','1 000°C-də'],1),
('fiz6-madde#9','fizika','fiz-6-madde',2,3,'Su neçə dərəcədə donur?','Su 0°C-də donub buza çevrilir.',array['0°C-də','100°C-də','−100°C-də','10°C-də'],1),
('fiz6-madde#10','fizika','fiz-6-madde',3,3,'Menzurkaya salınmış cismin həcmi necə təyin olunur?','Mayenin səviyyəsinin nə qədər qalxdığına görə.',array['Mayenin səviyyəsinin dəyişməsinə görə','Cismin rənginə görə','Cismin səsinə görə','Təyin etmək olmur'],1),
('fiz6-hereket#1','fizika','fiz-6-hereket',2,4,'Mexaniki hərəkət nədir?','Cismin başqa cisimlərə nəzərən vəziyyətinin dəyişməsidir.',array['Cismin yerdəyişməsi','Cismin rənginin dəyişməsi','Cismin əriməsi','Cismin yanması'],1),
('fiz6-hereket#2','fizika','fiz-6-hereket',2,4,'Cisimləri Yerə tərəf çəkən qüvvə necə adlanır?','Bu, cazibə (qravitasiya) qüvvəsidir.',array['Cazibə qüvvəsi','Külək qüvvəsi','Maqnit qüvvəsi','Səs qüvvəsi'],1),
('fiz6-hereket#3','fizika','fiz-6-hereket',1,4,'Günəş sisteminin mərkəzində hansı göy cismi durur?','Mərkəzdə Günəş yerləşir, planetlər onun ətrafında dövr edir.',array['Günəş','Yer','Ay','Mars'],1),
('fiz6-hereket#4','fizika','fiz-6-hereket',2,4,'Sürtünmə ilə elektriklənmiş daraq kağız qırıntılarına necə təsir edir?','Elektriklənmiş cisim yüngül cisimləri cəzb edir.',array['Cəzb edir','İtələyir','Yandırır','Heç cür'],1),
('fiz6-hereket#5','fizika','fiz-6-hereket',3,4,'Maqnitin ən güclü cəzb edən hissələri necə adlanır?','Maqnitin qütbləri ən güclü hissələridir.',array['Qütblər','Ortası','Alt hissəsi','Səthi'],1),
('fiz6-hereket#6','fizika','fiz-6-hereket',3,4,'Elektrik cərəyanı nədir?','Yüklü hissəciklərin istiqamətlənmiş hərəkətidir.',array['Yüklü hissəciklərin istiqamətlənmiş hərəkəti','Suyun axını','Küləyin əsməsi','İşığın yayılması'],1),
('fiz6-hereket#7','fizika','fiz-6-hereket',2,4,'Enerji nədir?','Cismin iş görmə qabiliyyətidir.',array['İş görmə qabiliyyəti','Cismin rəngi','Cismin adı','Cismin forması'],1),
('fiz6-hereket#8','fizika','fiz-6-hereket',3,4,'Hərəkət edən cismin malik olduğu enerji necə adlanır?','Hərəkət enerjisi kinetik enerjidir.',array['Kinetik enerji','Potensial enerji','Maqnit enerjisi','Enerjisi olmur'],1),
('fiz6-hereket#9','fizika','fiz-6-hereket',3,4,'Elektrik cərəyanını keçirən materiallar necə adlanır?','Cərəyanı keçirənlər naqillər (keçiricilər) adlanır.',array['Keçiricilər','İzolyatorlar','Maqnitlər','Güzgülər'],1),
('fiz6-hereket#10','fizika','fiz-6-hereket',2,4,'Toxunma ilə baş verən qarşılıqlı təsirə misal hansıdır?','Topa ayaqla vurulan zərbə toxunma təsiridir.',array['Topa vurulan zərbə','Ayın Yeri cəzb etməsi','Maqnitin uzaqdan təsiri','Günəşin istiliyi'],1),
('bio6-tedqiqat#1','biologiya','bio-6-tedqiqat',1,1,'Biologiya elmi nəyi öyrənir?','Biologiya canlı orqanizmləri öyrənir.',array['Canlı orqanizmləri','Daşları','Ulduzları','Rəqəmləri'],1),
('bio6-tedqiqat#2','biologiya','bio-6-tedqiqat',2,1,'Canlıların əsas xüsusiyyətləri hansılardır?','Qidalanma, tənəffüs, çoxalma, böyümə canlılara xasdır.',array['Qidalanma, tənəffüs, çoxalma','Yalnız hərəkət','Yalnız səs çıxarma','Parlaqlıq'],1),
('bio6-tedqiqat#3','biologiya','bio-6-tedqiqat',3,1,'Canlıların təsnifatında ən böyük vahidlərdən biri hansıdır?','Canlılar aləmlərə bölünür.',array['Aləm','Küçə','Otaq','Səhifə'],1),
('bio6-tedqiqat#4','biologiya','bio-6-tedqiqat',3,1,'İnsan təsnifat sistemində hansı aləmə aid edilir?','İnsan heyvanlar aləminə aiddir.',array['Heyvanlar aləminə','Bitkilər aləminə','Göbələklərə','Bakteriyalara'],1),
('bio6-tedqiqat#5','biologiya','bio-6-tedqiqat',2,1,'Bitkiləri öyrənən elm sahəsi necə adlanır?','Bitkiləri botanika öyrənir.',array['Botanika','Zoologiya','Coğrafiya','Tarix'],1),
('bio6-tedqiqat#6','biologiya','bio-6-tedqiqat',2,1,'Heyvanları öyrənən elm necə adlanır?','Heyvanları zoologiya öyrənir.',array['Zoologiya','Botanika','Fizika','Astronomiya'],1),
('bio6-tedqiqat#7','biologiya','bio-6-tedqiqat',2,1,'Canlını cansızdan fərqləndirən əsas əlamət hansıdır?','Canlılar qidalanır, böyüyür və çoxalır.',array['Qidalanıb çoxalması','Ağır olması','Rəngli olması','Böyük olması'],1),
('bio6-tedqiqat#8','biologiya','bio-6-tedqiqat',3,1,'Göbələklər təsnifatda hansı yeri tutur?','Göbələklər ayrıca aləm təşkil edir.',array['Ayrıca aləmdir','Bitkidir','Heyvandır','Mineraldır'],1),
('bio6-tedqiqat#9','biologiya','bio-6-tedqiqat',2,1,'Təbiəti öyrənərkən hansı üsullardan istifadə olunur?','Müşahidə və təcrübə əsas üsullardır.',array['Müşahidə və təcrübədən','Yalnız yuxudan','Yalnız təxmindən','Fal açmaqdan'],1),
('bio6-tedqiqat#10','biologiya','bio-6-tedqiqat',2,1,'Bakteriyaları görmək üçün hansı cihaz lazımdır?','Bakteriyalar yalnız mikroskopla görünür.',array['Mikroskop','Teleskop','Kompas','Termometr'],1),
('bio6-huceyre#1','biologiya','bio-6-huceyre',1,1,'Bütün canlıların quruluş vahidi nədir?','Canlılar hüceyrələrdən təşkil olunub.',array['Hüceyrə','Daş','Qum dənəsi','Damcı'],1),
('bio6-huceyre#2','biologiya','bio-6-huceyre',2,1,'Hüceyrənin idarəedici hissəsi hansıdır?','Hüceyrəni nüvə idarə edir.',array['Nüvə','Qılaf','Kölgə','Su'],1),
('bio6-huceyre#3','biologiya','bio-6-huceyre',3,1,'Nüvəsi olmayan orqanizmlər necə adlanır?','Nüvəsizlər prokariotlardır (məs. bakteriyalar).',array['Prokariotlar','Eukariotlar','Nəhənglər','Parazitlər'],1),
('bio6-huceyre#4','biologiya','bio-6-huceyre',2,1,'Bakteriyalar hansı orqanizmlərdəndir?','Bakteriyalar birhüceyrəli orqanizmlərdir.',array['Birhüceyrəli','Çoxhüceyrəli','Cansız','Bitki'],1),
('bio6-huceyre#5','biologiya','bio-6-huceyre',3,1,'Virusların əsas xüsusiyyəti nədir?','Viruslar yalnız canlı hüceyrədə çoxala bilir.',array['Yalnız canlı hüceyrədə çoxalır','Torpaqda böyüyür','Fotosintez edir','Sərbəst qidalanır'],1),
('bio6-huceyre#6','biologiya','bio-6-huceyre',2,1,'Hüceyrələr necə çoxalır?','Hüceyrələr bölünmə yolu ilə çoxalır.',array['Bölünmə yolu ilə','Yanma ilə','Donma ilə','Çoxalmır'],1),
('bio6-huceyre#7','biologiya','bio-6-huceyre',2,1,'Çoxhüceyrəli orqanizmə misal hansıdır?','İnsan milyardlarla hüceyrədən ibarətdir.',array['İnsan','Bakteriya','Amöb','İnfuzor'],1),
('bio6-huceyre#8','biologiya','bio-6-huceyre',2,1,'Quruluşca oxşar hüceyrələrin birliyi necə adlanır?','Oxşar hüceyrələr toxuma əmələ gətirir.',array['Toxuma','Qrup','Dəstə','Sinif'],1),
('bio6-huceyre#9','biologiya','bio-6-huceyre',3,1,'Bitkidə su və qida maddələrini daşıyan toxuma hansıdır?','Daşımanı ötürücü toxuma yerinə yetirir.',array['Ötürücü toxuma','Örtük toxuması','Mexaniki toxuma','Törədici toxuma'],1),
('bio6-huceyre#10','biologiya','bio-6-huceyre',2,1,'Birgə iş görən orqanlar nəyi əmələ gətirir?','Orqanlar orqanlar sistemində birləşir.',array['Orqanlar sistemini','Toxumanı','Hüceyrəni','Aləmi'],1),
('bio6-vegetativ#1','biologiya','bio-6-vegetativ',2,2,'Bitkinin vegetativ orqanları hansılardır?','Kök, gövdə və yarpaq vegetativ orqanlardır.',array['Kök, gövdə, yarpaq','Çiçək və meyvə','Yalnız toxum','Ləçəklər'],1),
('bio6-vegetativ#2','biologiya','bio-6-vegetativ',2,2,'Kökün əsas funksiyaları hansılardır?','Bitkini torpağa bərkidir, su və mineralları çəkir.',array['Bərkitmək və su çəkmək','Fotosintez etmək','Çiçək açmaq','Meyvə vermək'],1),
('bio6-vegetativ#3','biologiya','bio-6-vegetativ',2,2,'Yarpağın əsas funksiyası nədir?','Yarpaqda fotosintez gedir — qida hazırlanır.',array['Fotosintez','Torpağı bərkitmək','Toxum yaymaq','Su saxlamaq'],1),
('bio6-vegetativ#4','biologiya','bio-6-vegetativ',2,2,'Fotosintez üçün nə lazımdır?','İşıq, su və karbon qazı lazımdır.',array['İşıq, su və karbon qazı','Qaranlıq və soyuq','Yalnız torpaq','Yalnız külək'],1),
('bio6-vegetativ#5','biologiya','bio-6-vegetativ',2,2,'Yarpağa yaşıl rəng verən maddə hansıdır?','Yaşıllığı xlorofil verir.',array['Xlorofil','Nişasta','Duz','Şəkər'],1),
('bio6-vegetativ#6','biologiya','bio-6-vegetativ',2,2,'Gövdənin funksiyası nədir?','Maddələri daşıyır, yarpaq və çiçəkləri saxlayır.',array['Maddələri daşımaq və saxlamaq','Toxum əmələ gətirmək','Torpağı yumşaltmaq','Heç bir funksiyası yoxdur'],1),
('bio6-vegetativ#7','biologiya','bio-6-vegetativ',3,2,'Kartof yumrusu hansı orqanın şəkildəyişməsidir?','Yumru yeraltı zoğun (gövdənin) şəkildəyişməsidir.',array['Gövdənin (zoğun)','Kökün','Yarpağın','Çiçəyin'],1),
('bio6-vegetativ#8','biologiya','bio-6-vegetativ',3,2,'Yerkökü hansı orqanın şəkildəyişməsidir?','Yerkökü kökümeyvədir — kökün şəkildəyişməsidir.',array['Kökün','Gövdənin','Yarpağın','Meyvənin'],1),
('bio6-vegetativ#9','biologiya','bio-6-vegetativ',3,2,'Tumurcuq nədir?','Tumurcuq rüşeym halında olan zoğdur.',array['Rüşeym halında zoğ','Yetişmiş meyvə','Quru yarpaq','Kök ucu'],1),
('bio6-vegetativ#10','biologiya','bio-6-vegetativ',3,2,'Kök sistemləri hansı növlərə ayrılır?','Mil kök və saçaqlı kök sistemləri var.',array['Mil və saçaqlı','Uzun və qısa','İsti və soyuq','Yaş və quru'],1),
('bio6-generativ#1','biologiya','bio-6-generativ',2,2,'Bitkinin generativ (çoxalma) orqanları hansılardır?','Çiçək, meyvə və toxum çoxalma orqanlarıdır.',array['Çiçək, meyvə, toxum','Kök və gövdə','Yalnız yarpaq','Tumurcuqlar'],1),
('bio6-generativ#2','biologiya','bio-6-generativ',2,2,'Çiçəyin parlaq rəngli hissəsi necə adlanır?','Parlaq hissə ləçəklərdir (tac).',array['Ləçəklər','Kök','Gövdə','Qabıq'],1),
('bio6-generativ#3','biologiya','bio-6-generativ',3,2,'Tozlanma nədir?','Tozcuğun dişiciyin ağzına düşməsidir.',array['Tozcuğun dişiciyə düşməsi','Yarpağın tökülməsi','Kökün böyüməsi','Meyvənin yetişməsi'],1),
('bio6-generativ#4','biologiya','bio-6-generativ',2,2,'Tozlanmada hansı həşərat mühüm rol oynayır?','Arılar çiçəkdən-çiçəyə tozcuq daşıyır.',array['Arı','Qarışqa yuvası','Hörümçək','Milçək sürfəsi'],1),
('bio6-generativ#5','biologiya','bio-6-generativ',2,2,'Toxumun içərisində nə yerləşir?','Toxumda gələcək bitkinin rüşeymi var.',array['Rüşeym','Daş','Su damcısı','Torpaq'],1),
('bio6-generativ#6','biologiya','bio-6-generativ',3,2,'Meyvə çiçəyin hansı hissəsindən əmələ gəlir?','Meyvə dişiciyin yumurtalığından əmələ gəlir.',array['Dişiciyin yumurtalığından','Ləçəkdən','Kasacıqdan','Saplaqdan'],1),
('bio6-generativ#7','biologiya','bio-6-generativ',2,2,'Hansı meyvə şirəli meyvədir?','Albalı şirəli meyvədir; fındıq, qoz, paxla qurudur.',array['Albalı','Fındıq','Qoz','Paxla'],1),
('bio6-generativ#8','biologiya','bio-6-generativ',3,2,'Çiçək qrupu nədir?','Xırda çiçəklərin bir yerdə toplanmasıdır.',array['Çiçəklərin birgə yerləşməsi','Yarpaq dəstəsi','Kök topası','Meyvə qutusu'],1),
('bio6-generativ#9','biologiya','bio-6-generativ',2,2,'Toxumlar təbiətdə necə yayılır?','Külək, su və heyvanlar toxumları yayır.',array['Külək, su və heyvanlarla','Yalnız insan əli ilə','Yayılmır','Telefon ilə'],1),
('bio6-generativ#10','biologiya','bio-6-generativ',2,2,'Quru meyvəyə misal hansıdır?','Fındıq quru meyvədir.',array['Fındıq','Albalı','Qarpız','Pomidor'],1),
('bio6-hereket-qida#1','biologiya','bio-6-hereket-qida',2,3,'Heyvanlarda dayaq funksiyasını nə yerinə yetirir?','Bədənə dayağı skelet verir.',array['Skelet','Dəri','Tük','Quyruq'],1),
('bio6-hereket-qida#2','biologiya','bio-6-hereket-qida',1,3,'Balıqlar nə ilə hərəkət edir?','Balıqlar üzgəclərlə üzür.',array['Üzgəclərlə','Qanadlarla','Ayaqlarla','Əllərlə'],1),
('bio6-hereket-qida#3','biologiya','bio-6-hereket-qida',2,3,'Bitkilər qidasını necə əldə edir?','Fotosintez yolu ilə özləri hazırlayır.',array['Özləri hazırlayır (fotosintez)','Ov edir','Mağazadan alır','Başqa bitkiləri yeyir'],1),
('bio6-hereket-qida#4','biologiya','bio-6-hereket-qida',2,3,'Heyvanlar tənəffüs zamanı hansı qazı qəbul edir?','Tənəffüsdə oksigen qəbul olunur.',array['Oksigeni','Karbon qazını','Heliumu','Buxarı'],1),
('bio6-hereket-qida#5','biologiya','bio-6-hereket-qida',2,3,'Balıqlar suda nə ilə tənəffüs edir?','Balıqlar qəlsəmələrlə tənəffüs edir.',array['Qəlsəmələrlə','Ağciyərlərlə','Burunla','Üzgəclərlə'],1),
('bio6-hereket-qida#6','biologiya','bio-6-hereket-qida',1,3,'Otyeyən heyvana misal hansıdır?','İnək otla qidalanır.',array['İnək','Canavar','Qartal','Tülkü'],1),
('bio6-hereket-qida#7','biologiya','bio-6-hereket-qida',1,3,'Ətlə qidalanan heyvan hansıdır?','Şir yırtıcıdır — ətlə qidalanır.',array['Şir','İnək','Dovşan','Keçi'],1),
('bio6-hereket-qida#8','biologiya','bio-6-hereket-qida',2,3,'İnsanın tənəffüs orqanı hansıdır?','İnsan ağciyərlərlə tənəffüs edir.',array['Ağciyərlər','Mədə','Ürək','Böyrəklər'],1),
('bio6-hereket-qida#9','biologiya','bio-6-hereket-qida',3,3,'Bitkilər tənəffüs edirmi?','Bəli, bitkilər sutka boyu tənəffüs edir.',array['Bəli, daim tənəffüs edir','Xeyr, heç vaxt','Yalnız qışda','Yalnız gündüz'],1),
('bio6-hereket-qida#10','biologiya','bio-6-hereket-qida',2,3,'Qidalanma orqanizmə nə verir?','Enerji və inkişaf üçün maddələr verir.',array['Enerji və qida maddələri','Yalnız rəng','Yalnız yuxu','Heç nə'],1),
('bio6-dasinma-coxalma#1','biologiya','bio-6-dasinma-coxalma',1,3,'İnsanda qanı hərəkət etdirən orqan hansıdır?','Qanı ürək hərəkət etdirir.',array['Ürək','Mədə','Ağciyər','Dalaq'],1),
('bio6-dasinma-coxalma#2','biologiya','bio-6-dasinma-coxalma',3,3,'Bitkidə su hansı istiqamətdə hərəkət edir?','Su kökdən yarpaqlara doğru qalxır.',array['Kökdən yarpaqlara','Yarpaqdan kökə','Yalnız gövdə boyu aşağı','Hərəkət etmir'],1),
('bio6-dasinma-coxalma#3','biologiya','bio-6-dasinma-coxalma',3,3,'İfrazat nədir?','Lazımsız maddələrin orqanizmdən xaric edilməsidir.',array['Lazımsız maddələrin xaric edilməsi','Qida qəbulu','Tənəffüs','Hərəkət'],1),
('bio6-dasinma-coxalma#4','biologiya','bio-6-dasinma-coxalma',2,3,'Toxumun cücərməsi üçün hansı şərtlər vacibdir?','Su, hava və istilik lazımdır.',array['Su, hava və istilik','Yalnız qaranlıq','Yalnız duz','Səs-küy'],1),
('bio6-dasinma-coxalma#5','biologiya','bio-6-dasinma-coxalma',3,3,'Vegetativ çoxalma nədir?','Bitkinin vegetativ orqanları ilə çoxalmasıdır.',array['Vegetativ orqanlarla çoxalma','Toxumla çoxalma','Yumurta ilə çoxalma','Bölünmə ilə çoxalma'],1),
('bio6-dasinma-coxalma#6','biologiya','bio-6-dasinma-coxalma',3,3,'Çiyələk hansı orqanla vegetativ çoxalır?','Çiyələk bığcıqlarla çoxalır.',array['Bığcıqlarla','Toxumla yalnız','Yarpaqla','Çiçəklə'],1),
('bio6-dasinma-coxalma#7','biologiya','bio-6-dasinma-coxalma',3,3,'Kəpənəyin inkişaf mərhələləri hansı ardıcıllıqladır?','Yumurta → tırtıl → pup → kəpənək.',array['Yumurta, tırtıl, pup, kəpənək','Kəpənək, pup, tırtıl','Tırtıl, yumurta, kəpənək','Pup, yumurta, tırtıl'],1),
('bio6-dasinma-coxalma#8','biologiya','bio-6-dasinma-coxalma',2,3,'Qanın funksiyalarından biri hansıdır?','Qan qida və oksigen daşıyır.',array['Qida və oksigen daşımaq','Sümük əmələ gətirmək','Görməni təmin etmək','Səs çıxarmaq'],1),
('bio6-dasinma-coxalma#9','biologiya','bio-6-dasinma-coxalma',2,3,'İnsanda tər hansı orqan vasitəsilə xaric olur?','Tər dəri vasitəsilə ifraz olunur.',array['Dəri ilə','Saçla','Dırnaqla','Dişlə'],1),
('bio6-dasinma-coxalma#10','biologiya','bio-6-dasinma-coxalma',2,3,'Heyvanlarda inkişaf necə gedir?','Balalar böyüyərək yetkin fərdə çevrilir.',array['Bala böyüyüb yetkinləşir','Heyvanlar dəyişmir','Yalnız kiçilirlər','İnkişaf olmur'],1),
('bio6-muhit#1','biologiya','bio-6-muhit',2,4,'Orqanizmin yaşadığı şərait necə adlanır?','Orqanizmi əhatə edən şərait yaşayış mühitidir.',array['Yaşayış mühiti','Mənzil','Sinif','Qab'],1),
('bio6-muhit#2','biologiya','bio-6-muhit',3,4,'Hansılar cansız təbiət amilləridir?','İşıq, temperatur, rütubət cansız amillərdir.',array['İşıq, temperatur, rütubət','Bitkilər və heyvanlar','İnsanlar','Bakteriyalar'],1),
('bio6-muhit#3','biologiya','bio-6-muhit',2,4,'Dəvənin səhra həyatına uyğunlaşması nədir?','Dəvə uzun müddət susuz qala bilir.',array['Susuzluğa davamlılıq','Suda üzmək','Ağacda yaşamaq','Uçmaq'],1),
('bio6-muhit#4','biologiya','bio-6-muhit',2,4,'Qışda xəzi ağaran heyvan hansıdır?','Ağ dovşan qışda ağarır — qarda gizlənir.',array['Ağ dovşan','İnək','At','Qoyun'],1),
('bio6-muhit#5','biologiya','bio-6-muhit',3,4,'Təbii birlik nədir?','Bir ərazidə birgə yaşayan orqanizmlər qrupudur (meşə, göl).',array['Birgə yaşayan orqanizmlər qrupu','Bir heyvan','Bir daş','Bir bulud'],1),
('bio6-muhit#6','biologiya','bio-6-muhit',2,4,'Meşələrin qırılması nəyə səbəb olur?','Canlıların yaşayış yeri məhv olur.',array['Canlıların yaşayış yerinin itməsinə','Havanın təmizlənməsinə','Heyvanların artmasına','Heç nəyə'],1),
('bio6-muhit#7','biologiya','bio-6-muhit',3,4,'Qida zənciri nədir?','Canlıların qidalanma ardıcıllığıdır.',array['Canlıların qidalanma ardıcıllığı','Mağaza növbəsi','Bitki kolleksiyası','Heyvan oyunu'],1),
('bio6-muhit#8','biologiya','bio-6-muhit',2,4,'«Ot → dovşan → canavar» sırası nəyə misaldır?','Bu, qida zənciridir.',array['Qida zəncirinə','Əlifba sırasına','Say ardıcıllığına','Təsnifata'],1),
('bio6-muhit#9','biologiya','bio-6-muhit',2,4,'Su hövzələrinin çirklənməsi kimlərə zərər verir?','Su canlılarına və insanlara zərər verir.',array['Su canlılarına və insana','Heç kimə','Yalnız daşlara','Yalnız qayıqlara'],1),
('bio6-muhit#10','biologiya','bio-6-muhit',3,4,'«Qırmızı kitab»a hansı canlılar daxil edilir?','Nəsli kəsilmək təhlükəsində olan növlər.',array['Nəsli kəsilməkdə olanlar','Ən çoxsaylılar','Ən böyüklər','Ev heyvanları'],1),
('bio6-rol#1','biologiya','bio-6-rol',2,4,'Bitkilər fotosintez zamanı atmosferə hansı qazı verir?','Bitkilər oksigen ifraz edir.',array['Oksigen','Karbon qazı','Tüstü','Metan'],1),
('bio6-rol#2','biologiya','bio-6-rol',2,4,'Dərman bitkisinə misal hansıdır?','Çobanyastığı dərman bitkisidir.',array['Çobanyastığı','Kaktus','Qamış','Mamır'],1),
('bio6-rol#3','biologiya','bio-6-rol',1,4,'Bal arısı insana nə verir?','Arıdan bal və mum alınır.',array['Bal və mum','Süd','Yumurta','Yun'],1),
('bio6-rol#4','biologiya','bio-6-rol',2,4,'Hansı bitki mədəni bitkidir?','Buğdanı insan əkib-becərir.',array['Buğda','Yovşan','Qanqal','Gicitkən'],1),
('bio6-rol#5','biologiya','bio-6-rol',1,4,'Ev heyvanları insana nə verir?','Süd, ət, yumurta, yun kimi məhsullar verir.',array['Qida və digər məhsullar','Heç nə','Yalnız səs-küy','Yalnız xəstəlik'],1),
('bio6-rol#6','biologiya','bio-6-rol',1,4,'Yun hansı heyvandan alınır?','Yun qoyundan qırxılır.',array['Qoyundan','Toyuqdan','Balıqdan','Arıdan'],1),
('bio6-rol#7','biologiya','bio-6-rol',3,4,'İpəkqurdu insana nə verir?','İpəkqurdunun baramasından ipək sapı alınır.',array['İpək sapı','Bal','Süd','Dəri'],1),
('bio6-rol#8','biologiya','bio-6-rol',2,4,'Bağlarda zərərverici həşəratları məhv edən canlılar hansılardır?','Quşlar zərərvericiləri yeyərək bağları qoruyur.',array['Quşlar','Zərərvericilərin özləri','Daşlar','Küləklər'],1),
('bio6-rol#9','biologiya','bio-6-rol',2,4,'Bitkilərin insan üçün əhəmiyyətlərindən biri nədir?','Bitkilər əsas qida mənbəyidir.',array['Qida mənbəyidir','Yalnız kölgədir','Yalnız bəzəkdir','Əhəmiyyəti yoxdur'],1),
('bio6-rol#10','biologiya','bio-6-rol',2,4,'Pambıqdan nə istehsal olunur?','Pambıqdan parça toxunur.',array['Parça','Şüşə','Dəmir','Plastik'],1),
('cog6-mekan#1','cografiya','cog-6-mekan',1,1,'Coğrafiya elmi nəyi öyrənir?','Yer səthini, təbiəti və əhalini öyrənir.',array['Yer səthini və təbiəti','Yalnız keçmişi','Yalnız rəqəmləri','Yalnız dilləri'],1),
('cog6-mekan#2','cografiya','cog-6-mekan',2,1,'Məkan dedikdə nə nəzərdə tutulur?','Bizi əhatə edən və yaşadığımız ərazi.',array['Yaşadığımız ərazi','Yalnız otaq','Yalnız kosmos','Yalnız dəniz'],1),
('cog6-mekan#3','cografiya','cog-6-mekan',2,1,'Lokal (yerli) məkana misal hansıdır?','Yaşadığımız məhəllə lokal məkandır.',array['Yaşadığımız məhəllə','Bütün Yer kürəsi','Günəş sistemi','Okean'],1),
('cog6-mekan#4','cografiya','cog-6-mekan',2,1,'Qlobal məkan nədir?','Bütöv Yer kürəsi qlobal məkandır.',array['Bütün Yer kürəsi','Bir küçə','Bir ev','Bir sinif'],1),
('cog6-mekan#5','cografiya','cog-6-mekan',2,1,'Azərbaycan hansı materikdə yerləşir?','Azərbaycan Avrasiya materikindədir.',array['Avrasiyada','Afrikada','Amerikada','Avstraliyada'],1),
('cog6-mekan#6','cografiya','cog-6-mekan',3,1,'Yaşadığımız məkanı hansı əlamətlər fərqləndirir?','Relyefi, təbiəti və əhalisi ilə fərqlənir.',array['Relyefi, təbiəti, əhalisi','Yalnız adı','Yalnız rəngi','Heç nə ilə'],1),
('cog6-mekan#7','cografiya','cog-6-mekan',3,1,'Məkanın miqyası nəyi bildirir?','Ərazinin böyüklük dərəcəsini bildirir.',array['Ərazinin böyüklüyünü','Havanın istiliyini','Əhalinin adlarını','Suyun dadını'],1),
('cog6-mekan#8','cografiya','cog-6-mekan',2,1,'«Ölkə» anlayışı hansı məkana aiddir?','Ölkə bir dövlətin ərazisidir.',array['Dövlətin ərazisinə','Bir otağa','Bir planetə','Bir ulduza'],1),
('cog6-mekan#9','cografiya','cog-6-mekan',3,1,'Regional məkana misal hansıdır?','Qafqaz bir regiondur.',array['Qafqaz','Bir məktəb','Bir həyət','Bir mənzil'],1),
('cog6-mekan#10','cografiya','cog-6-mekan',2,1,'Məkanları öyrənmək nə üçün lazımdır?','Ətraf aləmi tanımaq və düzgün istifadə etmək üçün.',array['Ətraf aləmi tanımaq üçün','Yalnız qiymət almaq üçün','Heç nə üçün','Yalnız şəkil üçün'],1),
('cog6-beledci#1','cografiya','cog-6-beledci',2,1,'Ərazinin şərti işarələrlə kiçildilmiş təsviri necə adlanır?','Bu, plan və ya xəritədir.',array['Plan (xəritə)','Şəkil','Fotoalbom','Kitab'],1),
('cog6-beledci#2','cografiya','cog-6-beledci',2,1,'Miqyas nəyi göstərir?','Məsafənin xəritədə neçə dəfə kiçildildiyini göstərir.',array['Məsafənin kiçilmə dərəcəsini','Havanın istiliyini','Əhalinin sayını','Dağın hündürlüyünü'],1),
('cog6-beledci#3','cografiya','cog-6-beledci',2,1,'Üfüqün əsas cəhətləri hansılardır?','Şimal, cənub, şərq və qərb.',array['Şimal, cənub, şərq, qərb','Yuxarı və aşağı','Sağ və sol','İrəli və geri'],1),
('cog6-beledci#4','cografiya','cog-6-beledci',2,1,'Kompasın əqrəbi həmişə hansı cəhəti göstərir?','Kompas əqrəbi şimalı göstərir.',array['Şimalı','Cənubu','Şərqi','Qərbi'],1),
('cog6-beledci#5','cografiya','cog-6-beledci',1,1,'Günəş hansı tərəfdən doğur?','Günəş şərqdən doğur.',array['Şərqdən','Qərbdən','Şimaldan','Cənubdan'],1),
('cog6-beledci#6','cografiya','cog-6-beledci',2,1,'Xəritədə şimal adətən hansı tərəfdə göstərilir?','Xəritənin yuxarısı şimaldır.',array['Yuxarıda','Aşağıda','Solda','Sağda'],1),
('cog6-beledci#7','cografiya','cog-6-beledci',2,1,'Xəritədəki şərti işarələr nə üçündür?','Obyektləri (yol, çay, meşə) göstərmək üçün.',array['Obyektləri göstərmək üçün','Bəzək üçün','Rəngləmək üçün','Heç nə üçün'],1),
('cog6-beledci#8','cografiya','cog-6-beledci',3,1,'Qlobus xəritədən nə ilə üstündür?','Yerin formasını təhrifsiz göstərir.',array['Yerin formasını düzgün göstərir','Daha ucuzdur','Cibə yerləşir','Daha rənglidir'],1),
('cog6-beledci#9','cografiya','cog-6-beledci',2,1,'Dağlar fiziki xəritədə hansı rənglə göstərilir?','Dağlıq ərazilər qəhvəyi rənglə verilir.',array['Qəhvəyi','Mavi','Yaşıl','Ağ'],1),
('cog6-beledci#10','cografiya','cog-6-beledci',3,1,'Şimal yarımkürəsində günorta Günəş hansı tərəfdə olur?','Günorta Günəş cənub tərəfdə olur.',array['Cənubda','Şimalda','Qərbdə','Şərqdə'],1),
('cog6-col#1','cografiya','cog-6-col',2,2,'Çöl tədqiqatı nədir?','Təbiəti bilavasitə yerində öyrənməkdir.',array['Təbiəti yerində öyrənmək','Evdə kitab oxumaq','Televizora baxmaq','Yuxu görmək'],1),
('cog6-col#2','cografiya','cog-6-col',1,2,'Tədqiqata çıxarkən özünlə nə götürmək lazımdır?','Bloknot, kompas və xəritə lazımdır.',array['Bloknot, kompas, xəritə','Yalnız oyuncaq','Televizor','Çarpayı'],1),
('cog6-col#3','cografiya','cog-6-col',2,2,'Hava müşahidəsində nələr qeyd olunur?','Temperatur, külək və yağıntı qeyd olunur.',array['Temperatur, külək, yağıntı','Yalnız quşların sayı','Yalnız maşınlar','Heç nə'],1),
('cog6-col#4','cografiya','cog-6-col',3,2,'Küləyin istiqamətini hansı cihaz göstərir?','Küləyin istiqamətini flüger göstərir.',array['Flüger','Tərəzi','Mikroskop','Saat'],1),
('cog6-col#5','cografiya','cog-6-col',3,2,'Yağıntının miqdarı hansı vahidlə ölçülür?','Yağıntı millimetrlə ölçülür.',array['Millimetrlə','Kiloqramla','Metrlə','Dərəcə ilə'],1),
('cog6-col#6','cografiya','cog-6-col',2,2,'Müşahidə nəticələri harada qeyd olunur?','Müşahidə gündəliyində (cədvəldə) qeyd olunur.',array['Müşahidə gündəliyində','Yaddaşda qalır','Qumun üstündə','Heç yerdə'],1),
('cog6-col#7','cografiya','cog-6-col',3,2,'Gün ərzində havanın temperaturu nə vaxt ən yüksək olur?','Günortadan sonra temperatur maksimuma çatır.',array['Günortadan sonra','Gecə yarısı','Səhər tezdən','Gün batan kimi'],1),
('cog6-col#8','cografiya','cog-6-col',2,2,'Relyef müşahidəsində nəyə diqqət edilir?','Ərazinin hündür-alçaqlığına baxılır.',array['Ərazinin hündür-alçaqlığına','Mağaza qiymətlərinə','Maşın markalarına','Paltarlara'],1),
('cog6-col#9','cografiya','cog-6-col',3,2,'Çayın axın sürətini sadə üsulla necə təyin etmək olar?','Üzən əşyanın müəyyən məsafəni qət etmə vaxtı ilə.',array['Üzən əşyanın hərəkətini izləməklə','Suyu dadmaqla','Sahildə oturmaqla','Təyin etmək olmaz'],1),
('cog6-col#10','cografiya','cog-6-col',1,2,'Tədqiqat zamanı təbiətə münasibət necə olmalıdır?','Təbiətə zərər vermədən öyrənmək lazımdır.',array['Zərər vermədən','Budaqları qıraraq','Zibil ataraq','Yuvaları dağıdaraq'],1),
('cog6-kainat#1','cografiya','cog-6-kainat',2,2,'Günəş sistemində neçə planet var?','Günəş sistemində 8 planet var.',array['8','9','7','12'],1),
('cog6-kainat#2','cografiya','cog-6-kainat',2,2,'Yer Günəşdən neçənci planetdir?','Yer Günəşdən üçüncü planetdir.',array['3-cü','1-ci','5-ci','8-ci'],1),
('cog6-kainat#3','cografiya','cog-6-kainat',2,2,'Yerə ən yaxın göy cismi hansıdır?','Ay Yerə ən yaxın göy cismidir.',array['Ay','Günəş','Mars','Venera'],1),
('cog6-kainat#4','cografiya','cog-6-kainat',2,2,'Günəş hansı göy cismidir?','Günəş ulduzdur.',array['Ulduz','Planet','Peyk','Komet'],1),
('cog6-kainat#5','cografiya','cog-6-kainat',3,2,'Günəş sisteminin ən böyük planeti hansıdır?','Yupiter ən böyük planetdir.',array['Yupiter','Yer','Mars','Merkuri'],1),
('cog6-kainat#6','cografiya','cog-6-kainat',2,2,'«Qırmızı planet» adlandırılan planet hansıdır?','Mars səthinin rənginə görə qırmızı planet adlanır.',array['Mars','Venera','Saturn','Neptun'],1),
('cog6-kainat#7','cografiya','cog-6-kainat',2,2,'Yer öz oxu ətrafında tam dövrü nə qədərə başa vurur?','Bir dövr bir sutkaya (24 saata) başa gəlir.',array['24 saata','1 ilə','1 aya','1 saata'],1),
('cog6-kainat#8','cografiya','cog-6-kainat',3,2,'Ulduzlardan təşkil olunmuş nəhəng sistemlər necə adlanır?','Ulduz sistemləri qalaktikalar adlanır.',array['Qalaktikalar','Kometlər','Peyklər','Buludlar'],1),
('cog6-kainat#9','cografiya','cog-6-kainat',3,2,'Bizim qalaktikamız necə adlanır?','Qalaktikamız Süd Yolu adlanır.',array['Süd Yolu','Andromeda','Qara dəlik','Böyük Ayı'],1),
('cog6-kainat#10','cografiya','cog-6-kainat',3,2,'Günəşə ən yaxın planet hansıdır?','Merkuri Günəşə ən yaxındır.',array['Merkuri','Yer','Yupiter','Neptun'],1),
('cog6-tebiet#1','cografiya','cog-6-tebiet',3,3,'Yerin bərk qabığı necə adlanır?','Bərk qabıq litosferdir.',array['Litosfer','Hidrosfer','Atmosfer','Biosfer'],1),
('cog6-tebiet#2','cografiya','cog-6-tebiet',3,3,'Yerin su təbəqəsi necə adlanır?','Su təbəqəsi hidrosferdir.',array['Hidrosfer','Litosfer','Atmosfer','Stratosfer'],1),
('cog6-tebiet#3','cografiya','cog-6-tebiet',2,3,'Atmosfer nədir?','Yeri əhatə edən hava təbəqəsidir.',array['Yerin hava təbəqəsi','Yerin su təbəqəsi','Dağ süxurları','Meşə zolağı'],1),
('cog6-tebiet#4','cografiya','cog-6-tebiet',3,3,'Canlıların yayıldığı təbəqə necə adlanır?','Canlılar aləmi biosferi təşkil edir.',array['Biosfer','Litosfer','Kosmos','Nüvə'],1),
('cog6-tebiet#5','cografiya','cog-6-tebiet',2,3,'Vulkan püskürəndə yer səthinə nə axır?','Yer səthinə lava axır.',array['Lava','Süd','Neft','Buz'],1),
('cog6-tebiet#6','cografiya','cog-6-tebiet',2,3,'Zəlzələ nədir?','Yer qabığının titrəyişləridir.',array['Yer qabığının titrəməsi','Küləyin əsməsi','Yağışın yağması','Suyun donması'],1),
('cog6-tebiet#7','cografiya','cog-6-tebiet',2,3,'Dünyanın ən hündür dağ zirvəsi hansıdır?','Everest (Comolunqma) — 8848 m.',array['Everest','Bazardüzü','Elbrus','Alp'],1),
('cog6-tebiet#8','cografiya','cog-6-tebiet',2,3,'Dünyanın ən böyük okeanı hansıdır?','Sakit okean ən böyükdür.',array['Sakit okean','Atlantik okean','Hind okeanı','Şimal Buzlu okean'],1),
('cog6-tebiet#9','cografiya','cog-6-tebiet',3,3,'Çayın başlandığı yer necə adlanır?','Çayın başlanğıcı mənbə adlanır.',array['Mənbə','Mənsəb','Sahil','Körpü'],1),
('cog6-tebiet#10','cografiya','cog-6-tebiet',3,3,'Küləyi yaradan əsas səbəb nədir?','Havanın yerdəyişməsi (təzyiq fərqi) küləyi yaradır.',array['Havanın yerdəyişməsi','Quşların uçuşu','Maşınların hərəkəti','Dənizin dadı'],1),
('cog6-yurdumuz#1','cografiya','cog-6-yurdumuz',1,3,'Azərbaycan hansı dənizin sahilində yerləşir?','Ölkəmiz Xəzər dənizinin sahilindədir.',array['Xəzər','Qara dəniz','Aralıq dənizi','Baltik'],1),
('cog6-yurdumuz#2','cografiya','cog-6-yurdumuz',2,3,'Azərbaycanın ən uzun çayı hansıdır?','Kür ən uzun çayımızdır.',array['Kür','Araz','Samur','Tərtər'],1),
('cog6-yurdumuz#3','cografiya','cog-6-yurdumuz',2,3,'Azərbaycanın ən hündür zirvəsi hansıdır?','Bazardüzü zirvəsi — 4466 m.',array['Bazardüzü','Everest','Elbrus','Savalan'],1),
('cog6-yurdumuz#4','cografiya','cog-6-yurdumuz',2,3,'Böyük Qafqaz dağları ölkəmizin hansı hissəsindədir?','Böyük Qafqaz şimaldadır.',array['Şimalında','Cənubunda','Mərkəzində','Şərq dənizində'],1),
('cog6-yurdumuz#5','cografiya','cog-6-yurdumuz',3,3,'Azərbaycan ərazisində dünyanın 11 iqlim tipindən neçəsi var?','Ölkəmizdə 9 iqlim tipi müşahidə olunur.',array['9','2','11','5'],1),
('cog6-yurdumuz#6','cografiya','cog-6-yurdumuz',2,3,'Kür çayı hansı dənizə tökülür?','Kür Xəzər dənizinə tökülür.',array['Xəzərə','Qara dənizə','Aralıq dənizinə','Okeana'],1),
('cog6-yurdumuz#7','cografiya','cog-6-yurdumuz',3,3,'Naxçıvan Muxtar Respublikasının xüsusiyyəti nədir?','Əsas ərazidən aralı yerləşən muxtar respublikadır.',array['Əsas ərazidən aralı yerləşir','Dənizin ortasındadır','Başqa materikdədir','Şəhər deyil, kənddir'],1),
('cog6-yurdumuz#8','cografiya','cog-6-yurdumuz',3,3,'Azərbaycan hansı vulkanların sayına görə dünyada öndədir?','Palçıq vulkanlarının sayına görə birincidir.',array['Palçıq vulkanlarının','Buz vulkanlarının','Lava göllərinin','Qeyzerlərin'],1),
('cog6-yurdumuz#9','cografiya','cog-6-yurdumuz',2,3,'Araz çayı hansı çayın qoludur?','Araz Kürün ən böyük qoludur.',array['Kürün','Volqanın','Nilin','Dunayın'],1),
('cog6-yurdumuz#10','cografiya','cog-6-yurdumuz',3,3,'Hirkan meşələrində qorunan nadir ağac hansıdır?','Dəmirağac Hirkan meşələrinin nadir ağacıdır.',array['Dəmirağac','Kaktus','Palma','Sekvoyya'],1),
('cog6-dunya#1','cografiya','cog-6-dunya',2,4,'Dünyada neçə materik var?','Altı materik var.',array['6','5','7','4'],1),
('cog6-dunya#2','cografiya','cog-6-dunya',2,4,'Ən böyük materik hansıdır?','Avrasiya ən böyük materikdir.',array['Avrasiya','Afrika','Avstraliya','Antarktida'],1),
('cog6-dunya#3','cografiya','cog-6-dunya',2,4,'Ən isti materik hansıdır?','Afrika ən isti materikdir.',array['Afrika','Antarktida','Avrasiya','Şimali Amerika'],1),
('cog6-dunya#4','cografiya','cog-6-dunya',2,4,'Ən soyuq materik hansıdır?','Antarktida buzla örtülü ən soyuq materikdir.',array['Antarktida','Afrika','Avstraliya','Cənubi Amerika'],1),
('cog6-dunya#5','cografiya','cog-6-dunya',3,4,'Dünyanın ən uzun çayı hansıdır?','Nil dünyanın ən uzun çayı sayılır.',array['Nil','Volqa','Kür','Dunay'],1),
('cog6-dunya#6','cografiya','cog-6-dunya',2,4,'Böyük Səhra hansı materikdədir?','Böyük Səhra Afrikadadır.',array['Afrikada','Avropada','Antarktidada','Avstraliyada'],1),
('cog6-dunya#7','cografiya','cog-6-dunya',3,4,'Dünya okeanı Yer səthinin təxminən nə qədərini tutur?','Səthin təxminən 71%-ni (dörddə üçünü) su tutur.',array['Təxminən 71%-ni','10%-ni','Yarıdan azını','99%-ni'],1),
('cog6-dunya#8','cografiya','cog-6-dunya',2,4,'Kenquru hansı materikdə yaşayır?','Kenquru Avstraliyada yaşayır.',array['Avstraliyada','Afrikada','Avropada','Antarktidada'],1),
('cog6-dunya#9','cografiya','cog-6-dunya',3,4,'Əhalisi ən çox olan qitə hansıdır?','Asiya əhalisinə görə birincidir.',array['Asiya','Avstraliya','Antarktida','Cənubi Amerika'],1),
('cog6-dunya#10','cografiya','cog-6-dunya',1,4,'Yer kürəsini qorumaq üçün insanlar nə etməlidir?','Təbiətə qayğı ilə yanaşmalı, çirkləndirməməlidir.',array['Təbiətə qayğı ilə yanaşmalı','Daha çox meşə qırmalı','Suları çirkləndirməli','Heç nə etməməli'],1)
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
   where owner_type = 'platform'
     and (ext_key like 'fiz6-%' or ext_key like 'bio6-%'
          or ext_key like 'cog6-%');
  if n <> 190 then
    raise exception 'fenn6 suallari: 190 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'fiz6-%' or q.ext_key like 'bio6-%'
          or q.ext_key like 'cog6-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'fiz6-%' or ext_key like 'bio6-%'
      or ext_key like 'cog6-%';
  if k <> 19 then
    raise exception 'movzu sayi 19 deyil: %', k;
  end if;
  raise notice '6-ci sinif tebiet fennleri banki: % sual, 19 movzu (fiz, bio, cog).', n;
end $$;
