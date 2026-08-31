-- =====================================================================
--  71_bank_tarix_umumi7.sql : 7-CI SINIF TARIXI 'umumi-tarix' FENNINE
--
--  BU FAYL ELLE YAZILMIR - tools/tarix_umumi7.py yaradir:
--      python3 tools/tarix_umumi7.py
--
--  Portalda 7-ci sinif ucun "Azerbaycan tarixi" derslikyi yoxdur -
--  yalniz "Umumi tarix" var (mundericat/tarix-7-723.txt).  Ona gore
--  29/31 fayllarinin 'tarix' altinda yazdigi 180 sual buraya kocur.
--  Kohne alti movzudan ikisi yeni movzu kimi qalir (turk dovletleri,
--  Selcuq-Monqol-Osmanli), qalan dordu ICMAL movzusu oldugu ucun
--  suallari 66/67-nin alti movzusuna dene-dene paylanib.
--
--  EXT_KEY DEYISMIR ('tarix7-...') - canli bazadaki setirler yerinde
--  yenilenir, dublikat yaranmir.
--
--  ON SERT: 70_movzular_umumi_tarix7.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'umumi-tarix' and t.slug in
           ('utarix-7-turk-dovletleri', 'utarix-7-selcuq-osmanli')
     having count(*) = 2) then
    raise exception 'ONCE 70_movzular_umumi_tarix7.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'tarix7-%';

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('tarix7-erken-orta-esrler#1','umumi-tarix','utarix-7-erken',3,1,'Qərbi Roma imperiyası neçənci ildə süqut etdi?','476-cı ildə süqut etdi — orta əsrlərin başlanğıcı sayılır.',array['476','1453','1492','622'],1),
('tarix7-erken-orta-esrler#6','umumi-tarix','utarix-7-erken',3,1,'Frank dövlətinin ən məşhur hökmdarı kim idi?','Böyük Karl Frank dövlətini imperiyaya çevirdi.',array['Böyük Karl','Çingiz xan','Osman bəy','Atropat'],1),
('tarix7-erken-orta-esrler#7','umumi-tarix','utarix-7-erken',2,1,'Bizansın paytaxtı və ən böyük şəhəri hansı idi?','Paytaxt Konstantinopol idi.',array['Konstantinopol','Roma','Paris','Bağdad'],1),
('tarix7-erken-orta-esrler#9','umumi-tarix','utarix-7-erken',2,1,'Orta əsrlərdə Avropada hansı din hakim idi?','Avropada xristianlıq hakim din idi.',array['Xristianlıq','Buddizm','Şintoizm','Heç bir din'],1),
('tarix7-erken-orta-esrler#10','umumi-tarix','utarix-7-erken',3,1,'Sasani dövləti uzun müharibələri hansı imperiya ilə aparırdı?','Sasanilər Bizansla uzun müharibələr aparırdılar.',array['Bizansla','Osmanlı ilə','Monqollarla','Franklarla'],1),
('tarix7-erken-orta-esrler#14','umumi-tarix','utarix-7-erken',3,1,'Böyük Karl neçənci ildə imperator elan edildi?','800-cü ildə.',array['800','622','1000','1492'],1),
('tarix7-erken-orta-esrler#16','umumi-tarix','utarix-7-erken',2,1,'Bizans imperiyası hansı imperiyanın varisi idi?','Şərqi Roma imperiyasının.',array['Şərqi Roma','Misir','Hun','Monqol'],1),
('tarix7-erken-orta-esrler#17','umumi-tarix','utarix-7-erken',3,1,'Slavyan yazısını yaradan qardaşlar kimlərdir?','Kirill və Mefodi.',array['Kirill və Mefodi','Romul və Rem','Toğrul və Çağrı','Osman və Orxan'],1),
('tarix7-erken-orta-esrler#21','umumi-tarix','utarix-7-erken',2,1,'476-cı il tarixdə nə ilə əlamətdardır?','Qərbi Roma imperiyası süqut etdi.',array['Qərbi Romanın süqutu ilə','Amerika kəşfi ilə','İslamın yaranması ilə','Xaçlı yürüşü ilə'],1),
('tarix7-erken-orta-esrler#25','umumi-tarix','utarix-7-erken',3,1,'Böyük Karlın imperiyası onun ölümündən sonra nə oldu?','Verden bölgüsü ilə üç yerə ayrıldı.',array['Üç yerə parçalandı','Genişləndi','Dəyişmədi','Bizansa birləşdi'],1),
('tarix7-erken-orta-esrler#26','umumi-tarix','utarix-7-erken',2,1,'Bizansda hansı dil rəsmi dil idi?','Yunan dili əsas dil idi.',array['Yunan dili','Ərəb dili','İngilis dili','İspan dili'],1),
('tarix7-erken-orta-esrler#29','umumi-tarix','utarix-7-erken',3,1,'Norman (vikinq) yürüşləri hansı əsrlərdə baş verirdi?','VIII-XI əsrlərdə Avropanı bürüdü.',array['VIII-XI əsrlərdə','II-III əsrlərdə','XV-XVI əsrlərdə','XX əsrdə'],1),
('tarix7-erken-orta-esrler#30','umumi-tarix','utarix-7-erken',1,1,'Şərqi Roma imperiyası tarixdə hansı adla tanınır?','Bizans imperiyası adlanır.',array['Bizans','Osmanlı','Səlcuq','Frank'],1),
('tarix7-avropa#18','umumi-tarix','utarix-7-erken',3,1,'Bizansın ən məşhur məbədi hansı idi?','Konstantinopoldakı Müqəddəs Sofiya məbədi idi.',array['Ayasofya','Kəbə','Panteon','Notr-Dam'],1),
('tarix7-avropa#19','umumi-tarix','utarix-7-erken',3,1,'Şərqi slavyanların yaratdığı dövlət hansı idi?','Şərqi slavyanlar Kiyev Rus dövlətini yaratdılar.',array['Kiyev Rus dövləti','Frank dövləti','Xəzər xaqanlığı','Din ölkəsi'],1),
('tarix7-avropa#28','umumi-tarix','utarix-7-erken',3,1,'Kiyev Rus dövləti hansı çay boyunda formalaşmışdı?','Dnepr çayı boyunca inkişaf etdi.',array['Dnepr boyunda','Nil boyunda','Qanq boyunda','Amazon boyunda'],1),
('tarix7-avropa#29','umumi-tarix','utarix-7-erken',2,1,'Ayasofya məbədi hansı şəhərdə tikilmişdi?','Bizansın paytaxtı Konstantinopolda.',array['Konstantinopolda','Romada','Parisdə','Afinada'],1),
('tarix7-erken-orta-esrler#3','umumi-tarix','utarix-7-ereb',2,1,'İslam dini neçənci əsrdə yaranmışdır?','İslam VII əsrdə Ərəbistanda yaranıb.',array['VII əsrdə','III əsrdə','XV əsrdə','XIX əsrdə'],1),
('tarix7-erken-orta-esrler#4','umumi-tarix','utarix-7-ereb',2,1,'Müsəlmanların müqəddəs kitabı hansıdır?','«Quran» müsəlmanların müqəddəs kitabıdır.',array['«Quran»','«İliada»','«Avesta»','«Odisseya»'],1),
('tarix7-erken-orta-esrler#11','umumi-tarix','utarix-7-ereb',2,1,'Məhəmməd peyğəmbər hansı şəhərdə anadan olmuşdur?','Məkkə şəhərində.',array['Məkkədə','Mədinədə','Bağdadda','Şamda'],1),
('tarix7-erken-orta-esrler#12','umumi-tarix','utarix-7-ereb',3,1,'Hicrət — Məkkədən Mədinəyə köçmə neçənci ildə baş verdi?','622-ci ildə.',array['622','476','800','1453'],1),
('tarix7-erken-orta-esrler#13','umumi-tarix','utarix-7-ereb',3,1,'Abbasilər dövründə xilafətin paytaxtı hansı şəhər idi?','Bağdad şəhəri.',array['Bağdad','Konstantinopol','Roma','Paris'],1),
('tarix7-erken-orta-esrler#20','umumi-tarix','utarix-7-ereb',1,1,'İslamda ibadət evi necə adlanır?','Məscid adlanır.',array['Məscid','Kilsə','Sinaqoq','Məbəd'],1),
('tarix7-erken-orta-esrler#27','umumi-tarix','utarix-7-ereb',3,1,'Mədinə şəhərinin islam tarixində rolu nədir?','İlk müsəlman icması burada quruldu.',array['İlk islam dövlətinin mərkəzi','Xilafətin son paytaxtı','Bizansın şərq sərhəd şəhəri','Səlibçilərin qala şəhəri'],1),
('tarix7-erken-orta-esrler#28','umumi-tarix','utarix-7-ereb',2,1,'«Xəlifə» sözünün mənası nədir?','Peyğəmbərin canişini deməkdir.',array['Canişin, varis','Döyüşçü','Tacir','Səyyah'],1),
('tarix7-ereb-xilafeti#1','umumi-tarix','utarix-7-ereb',2,1,'Ərəb xilafətinin ilk paytaxtı hansı şəhər idi?','İlk dövrdə xilafətin mərkəzi Mədinə idi.',array['Mədinə','Bağdad','Dəməşq','Qahirə'],1),
('tarix7-ereb-xilafeti#2','umumi-tarix','utarix-7-ereb',3,1,'Əməvilər dövründə xilafət hansı şəhərdən idarə olunurdu?','Əməvilər paytaxtı Dəməşqə köçürdülər.',array['Dəməşq','Məkkə','İstanbul','Kordova'],1),
('tarix7-ereb-xilafeti#3','umumi-tarix','utarix-7-ereb',2,1,'Məhəmməd peyğəmbərdən sonra müsəlmanlara rəhbərlik edənlər necə adlanırdı?','Dövlətə xəlifələr başçılıq edirdi.',array['Xəlifələr','Fironlar','Xaqanlar','İmperatorlar'],1),
('tarix7-ereb-xilafeti#4','umumi-tarix','utarix-7-ereb',2,1,'İslamın əsas şərtlərindən biri hansıdır?','Namaz qılmaq islamın beş şərtindən biridir.',array['Namaz qılmaq','Şəkil çəkmək','Dəniz səyahəti','İdman etmək'],1),
('tarix7-ereb-xilafeti#5','umumi-tarix','utarix-7-ereb',2,1,'Ərəb xilafəti hansı üç qitədə torpaqlara sahib idi?','Xilafət Asiya, Afrika və Avropada torpaqlar tuturdu.',array['Asiya, Afrika, Avropa','Yalnız Asiyada','Amerika və Avstraliyada','Yalnız Afrikada'],1),
('tarix7-ereb-xilafeti#6','umumi-tarix','utarix-7-ereb',3,1,'Ərəblərin İspaniyada yaratdığı dövlət necə adlanırdı?','Pireney yarımadasında Kordova əmirliyi yarandı.',array['Kordova əmirliyi','Frank krallığı','Papalıq','Qızıl Orda'],1),
('tarix7-ereb-xilafeti#7','umumi-tarix','utarix-7-ereb',3,1,'Abbasilər dövründə Bağdadda fəaliyyət göstərən elm mərkəzi necə adlanırdı?','«Hikmət evi» tərcümə və elm mərkəzi idi.',array['«Hikmət evi»','«Akademiya»','«Lisey»','«Universitet»'],1),
('tarix7-ereb-xilafeti#8','umumi-tarix','utarix-7-ereb',2,1,'Ərəb alimləri hansı elm sahələrində xüsusilə irəli getmişdilər?','Riyaziyyat, tibb və astronomiya yüksək inkişaf etdi.',array['Riyaziyyat, tibb, astronomiya','Yalnız musiqidə','Yalnız rəssamlıqda','Heç bir sahədə'],1),
('tarix7-ereb-xilafeti#9','umumi-tarix','utarix-7-ereb',2,1,'Müsəlmanların Məkkəyə ziyarəti necə adlanır?','Məkkə ziyarəti həcc adlanır.',array['Həcc','Hicrət','Cizyə','Xərac'],1),
('tarix7-ereb-xilafeti#10','umumi-tarix','utarix-7-ereb',3,1,'«Ərəb rəqəmləri» adlanan rəqəmlər əslində haradan götürülmüşdür?','Bu rəqəmləri ərəblər Hindistandan mənimsəyib yaymışlar.',array['Hindistandan','Qədim Romadan','Qədim Misirdən','Qədim Çindən'],1),
('tarix7-ereb-xilafeti#11','umumi-tarix','utarix-7-ereb',3,1,'İslam təqvimi hansı hadisədən başlanır?','Təqvim hicrətdən - 622-ci ildən hesablanır.',array['Hicrətdən','Roma süqutundan','Hz. İsanın doğumundan','Xilafətin süqutundan'],1),
('tarix7-ereb-xilafeti#12','umumi-tarix','utarix-7-ereb',3,1,'Xilafət ordusunun əsas zərbə qüvvəsi nə idi?','Yüngül silahlı süvari dəstələri əsas qüvvə idi.',array['Süvari dəstələri','Fil qoşunları','Donanma yalnız','Toplar'],1),
('tarix7-ereb-xilafeti#13','umumi-tarix','utarix-7-ereb',3,1,'Ərəbdilli elmi əsərlər Avropaya hansı yolla çatırdı?','Əsərlər latın dilinə tərcümələr vasitəsilə yayılırdı.',array['Tərcümələr vasitəsilə','Səfirlik yazışmaları ilə','Kilsə xronikaları ilə','Hərbi əsirlər vasitəsilə'],1),
('tarix7-ereb-xilafeti#14','umumi-tarix','utarix-7-ereb',3,1,'732-ci ildə ərəblərin Qərbi Avropada irəliləyişini hansı döyüş dayandırdı?','Puatye döyüşündə franklar ərəbləri məğlub etdi.',array['Puatye döyüşü','Malazgird döyüşü','Ankara döyüşü','Kulikovo döyüşü'],1),
('tarix7-ereb-xilafeti#15','umumi-tarix','utarix-7-ereb',3,1,'Əməvilərdən sonra xilafətdə hakimiyyətə hansı sülalə gəldi?','750-ci ildə hakimiyyət Abbasilərə keçdi.',array['Abbasilər','Səfəvilər','Osmanlılar','Səlcuqlar'],1),
('tarix7-ereb-xilafeti#16','umumi-tarix','utarix-7-ereb',3,1,'Xilafətdə torpaq vergisi necə adlanırdı?','Torpaqdan xərac vergisi alınırdı.',array['Xərac','Gömrük','Aksiz','Töycü'],1),
('tarix7-ereb-xilafeti#17','umumi-tarix','utarix-7-ereb',2,1,'Məscidlərin yanında fəaliyyət göstərən təhsil ocaqları necə adlanırdı?','Mədrəsələrdə dini və dünyəvi elmlər öyrədilirdi.',array['Mədrəsələr','Universitetlər','Liseylər','Gimnaziyalar'],1),
('tarix7-ereb-xilafeti#18','umumi-tarix','utarix-7-ereb',3,1,'Xilafətin zəifləməsinin səbəblərindən biri nə idi?','Yerli sülalələr mərkəzdən ayrılıb müstəqilləşirdi.',array['Yerli sülalələrin müstəqilləşməsi','Şəhər əhalisinin sürətlə artması','Elm mərkəzlərinin çoxalması','Karvan ticarətinin genişlənməsi'],1),
('tarix7-ereb-xilafeti#19','umumi-tarix','utarix-7-ereb',3,1,'Ərəb səyyahları və tacirləri hansı elmin inkişafına böyük töhfə verdilər?','Səyahətlər coğrafiya elmini zənginləşdirdi.',array['Coğrafiya elminə','Genetikaya','Kimyaya yalnız','İnformatikaya'],1),
('tarix7-ereb-xilafeti#20','umumi-tarix','utarix-7-ereb',2,1,'Qurani-Kərim hansı dildə nazil olmuşdur?','Müqəddəs kitab ərəb dilindədir.',array['Ərəb dilində','Latın dilində','Fars dilində','Yunan dilində'],1),
('tarix7-ereb-xilafeti#21','umumi-tarix','utarix-7-ereb',2,1,'Hicrət hansı iki şəhər arasında baş verdi?','Məkkədən Mədinəyə köç edildi.',array['Məkkə ilə Mədinə','Bağdad ilə Şam','Qahirə ilə Kufə','Bəsrə ilə Mosul'],1),
('tarix7-ereb-xilafeti#22','umumi-tarix','utarix-7-ereb',2,1,'Şəriət nədir?','İslam hüquq və davranış qaydalarıdır.',array['İslam hüquq qaydaları','Vergi növü','Şəhər adı','Ordu hissəsi'],1),
('tarix7-ereb-xilafeti#23','umumi-tarix','utarix-7-ereb',3,1,'Xilafətdə qeyri-ərəb müsəlmanlar necə adlanırdı?','Onlara məvali deyilirdi.',array['Məvali','Xəlifə','Əmir','Qazi'],1),
('tarix7-ereb-xilafeti#24','umumi-tarix','utarix-7-ereb',3,1,'Beytül-hikmətdə hansı işlər görülürdü?','Elmi əsərlər tərcümə və tədqiq olunurdu.',array['Tərcümə və elmi tədqiqat','Silah və zireh istehsalı','Ticarət gəmilərinin tikintisi','Xilafət pullarının kəsilməsi'],1),
('tarix7-ereb-xilafeti#25','umumi-tarix','utarix-7-ereb',3,1,'Əl-Xarəzmi hansı elmin inkişafında xüsusi rol oynayıb?','Cəbr elminin əsasını qoyub.',array['Cəbrin (riyaziyyatın)','Musiqi nəzəriyyəsinin','Təsviri sənətin','Dəniz naviqasiyasının'],1),
('tarix7-ereb-xilafeti#26','umumi-tarix','utarix-7-ereb',3,1,'Xilafət donanması hansı dənizdə üstünlük qazanmışdı?','Aralıq dənizində güclü idi.',array['Aralıq dənizində','Sakit okeanda','Baltik dənizində','Şimal dənizində'],1),
('tarix7-ereb-xilafeti#27','umumi-tarix','utarix-7-ereb',3,1,'Kordova hansı dövlətin mərkəzi idi?','İspaniyadakı ərəb dövlətinin.',array['Müsəlman İspaniyasının','Bizans imperiyasının','Frank krallığının','Səlcuq sultanlığının'],1),
('tarix7-ereb-xilafeti#28','umumi-tarix','utarix-7-ereb',2,1,'İbn Sina hansı elm sahəsində məşhurdur?','«Tibb qanunu» əsərinin müəllifidir.',array['Təbabətdə','Astronomiyada yalnız','Memarlıqda','Hərb işində'],1),
('tarix7-ereb-xilafeti#29','umumi-tarix','utarix-7-ereb',3,1,'Xilafətdə poçt-rabitə xidməti necə adlanırdı?','Bərid adlanırdı.',array['Bərid','Divan','Vəzir','Qazi'],1),
('tarix7-ereb-xilafeti#30','umumi-tarix','utarix-7-ereb',2,1,'Xilafətdə ərəb dili hansı funksiyanı yerinə yetirirdi?','Elmin və dövlətin dili idi.',array['Elm və dövlət dili','Yalnız məişət dili','Qadağan edilmişdi','Yalnız ticarət dili'],1),
('tarix7-erken-orta-esrler#15','umumi-tarix','utarix-7-feodal',2,2,'Orta əsrlərdə zadəgan döyüşçülər necə adlanırdı?','Cəngavərlər adlanırdı.',array['Cəngavərlər','Kəndlilər','Tacirlər','Rahiblər'],1),
('tarix7-erken-orta-esrler#19','umumi-tarix','utarix-7-feodal',3,2,'Orta əsr şəhərlərində sənətkarlar hansı təşkilatlarda birləşirdi?','Sex adlanan birliklərdə.',array['Sexlərdə','Bankalarda','Universitetlərdə','Ordularda'],1),
('tarix7-erken-orta-esrler#22','umumi-tarix','utarix-7-feodal',2,2,'Feodal iyerarxiyasının başında kim dururdu?','Ali senyor kral idi.',array['Kral','Kəndli','Sənətkar','Tacir'],1),
('tarix7-erken-orta-esrler#23','umumi-tarix','utarix-7-feodal',2,2,'Orta əsr kəndliləri hansı iki qrupa bölünürdü?','Azad və feodaldan asılı kəndlilər.',array['Azad və asılı','Zəngin və kral','Tacir və döyüşçü','Şəhərli və alim'],1),
('tarix7-erken-orta-esrler#24','umumi-tarix','utarix-7-feodal',3,2,'Vassal kimə deyilirdi?','Senyordan torpaq alıb xidmət edənə.',array['Senyora xidmət edənə','Kilsə başçısına','Şəhər tacirinə','Azad kəndliyə'],1),
('tarix7-orta-esrler#29','umumi-tarix','utarix-7-feodal',3,2,'Orta əsrlərdə Avropada ticarət şəhərləri hansı ittifaqda birləşirdi?','Hanza ittifaqı yaranmışdı.',array['Hanza ittifaqı','Şimal dəniz birliyi','Səlib cəngavər ordeni','Lombardiya birliyi'],1),
('tarix7-avropa#1','umumi-tarix','utarix-7-feodal',2,2,'Feodal cəmiyyətinin əsas iki təbəqəsi kimlər idi?','Cəmiyyət feodallardan və asılı kəndlilərdən ibarət idi.',array['Feodallar və asılı kəndlilər','Fəhlələr və mühəndislər','Tacirlər və dənizçilər','Alimlər və tələbələr'],1),
('tarix7-avropa#2','umumi-tarix','utarix-7-feodal',3,2,'Böyük feodala xidmət edən kiçik torpaq sahibi necə adlanırdı?','Xidmət müqabilində torpaq alan feodal vassal adlanırdı.',array['Vassal','Senator','Xəlifə','Konsul'],1),
('tarix7-avropa#16','umumi-tarix','utarix-7-feodal',2,2,'Feodal qəsrləri hansı məqsədlə tikilirdi?','Qalın divarlı qəsrlər müdafiə üçün idi.',array['Müdafiə məqsədilə','Ticarət üçün','Teatr üçün','Anbar üçün yalnız'],1),
('tarix7-avropa#17','umumi-tarix','utarix-7-feodal',3,2,'Orta əsr şəhərləri kimlərdən asılılıqdan azad olmağa çalışırdı?','Şəhərlər senyorların hakimiyyətindən qurtulmaq istəyirdi.',array['Senyorlardan','Tələbələrdən','Sənətkarlardan','Tacirlərdən'],1),
('tarix7-avropa#23','umumi-tarix','utarix-7-feodal',2,2,'Sex (gildiya) təşkilatları kimləri birləşdirirdi?','Eyni peşənin sənətkarlarını.',array['Eyni peşəli sənətkarları','Yalnız kəndliləri','Yalnız rahibləri','Döyüşçüləri'],1),
('tarix7-orta-esrler#28','umumi-tarix','utarix-7-serq',2,2,'Marko Polonun səyahətnaməsi hansı ölkədən bəhs edirdi?','Çin haqqında məlumat verirdi.',array['Çindən','Braziliyadan','Misirdən','Norveçdən'],1),
('tarix7-avropa#15','umumi-tarix','utarix-7-serq',3,2,'Barıt, kağız və kompas Avropaya haradan gəlmişdi?','Bu ixtiralar Şərqdən (Çindən) gətirilmişdi.',array['Şərqdən (Çindən)','Amerikadan','Avstraliyadan','Afrikadan'],1),
('tarix7-orta-esrler#6','umumi-tarix','utarix-7-avropa',3,3,'Xaçlı yürüşləri hansı istiqamətə təşkil olunurdu?','Şərqə — Yerusəlim istiqamətinə.',array['Şərqə (Yerusəlimə)','Şimala (Skandinaviyaya)','Amerikaya','Avstraliyaya'],1),
('tarix7-orta-esrler#8','umumi-tarix','utarix-7-avropa',2,3,'Amerika qitəsini 1492-ci ildə kim kəşf etdi?','Xristofor Kolumb Amerikaya çatdı.',array['Xristofor Kolumb','Magellan','Vasko da Qama','Marko Polo'],1),
('tarix7-orta-esrler#10','umumi-tarix','utarix-7-avropa',3,3,'Reformasiya hərəkatı hansı sahədə dəyişiklik tələb edirdi?','Kilsənin (dini qaydaların) islahatını tələb edirdi.',array['Kilsədə islahat','İdmanda dəyişiklik','Geyimdə dəyişiklik','Yeməkdə dəyişiklik'],1),
('tarix7-orta-esrler#14','umumi-tarix','utarix-7-avropa',3,3,'Yüzillik müharibə hansı dövlətlər arasında olub?','İngiltərə ilə Fransa arasında.',array['İngiltərə və Fransa','Roma və Misir','Osmanlı və Səfəvi','İspaniya və Portuqaliya'],1),
('tarix7-orta-esrler#17','umumi-tarix','utarix-7-avropa',3,3,'Reformasiya hərəkatının banisi kimdir?','Martin Lüter.',array['Martin Lüter','Böyük Karl','Kolumb','Qutenberq'],1),
('tarix7-orta-esrler#21','umumi-tarix','utarix-7-avropa',3,3,'Xaçlı yürüşlərinin nəticələrindən biri nə oldu?','Şərqlə Qərb arasında ticarət genişləndi.',array['Şərq-Qərb ticarəti canlandı','Avropada şəhər həyatı söndü','Bizans imperiyası möhkəmləndi','Şərqdə xristian dövlətləri qaldı'],1),
('tarix7-orta-esrler#23','umumi-tarix','utarix-7-avropa',2,3,'Vasko da Qamanın səyahəti hansı ölkəyə yol açdı?','Afrikanı dolanıb Hindistana çatdı.',array['Hindistana','Amerikaya','Avstraliyaya','Rusiyaya'],1),
('tarix7-orta-esrler#24','umumi-tarix','utarix-7-avropa',2,3,'Böyük coğrafi kəşflər hansı qitənin işğalına yol açdı?','Amerika müstəmləkələşdirildi.',array['Amerikanın','Avropanın','Antarktidanın','Asiyanın yalnız'],1),
('tarix7-avropa#3','umumi-tarix','utarix-7-avropa',3,3,'1066-cı ildə İngiltərəni fəth edən sərkərdə kim idi?','Normandiya hersoqu Vilhelm Fateh İngiltərəni tutdu.',array['Vilhelm Fateh','Frank kralı Böyük Karl','Hun hökmdarı Attila','Roma sərkərdəsi Sezar'],1),
('tarix7-avropa#4','umumi-tarix','utarix-7-avropa',3,3,'1215-ci ildə İngiltərədə imzalanan məşhur sənəd hansıdır?','Kral Böyük azadlıqlar xartiyasını imzalamağa məcbur oldu.',array['Böyük azadlıqlar xartiyası','Türkmənçay sülh müqaviləsi','Roma hüququ məcəlləsi','Çingiz xanın «Yasa»sı'],1),
('tarix7-avropa#5','umumi-tarix','utarix-7-avropa',2,3,'İngiltərədə yaranan silki nümayəndəlik orqanı necə adlanırdı?','XIII əsrdə İngiltərədə parlament yarandı.',array['Parlament','Senat','Məclis-i şura','Veçe'],1),
('tarix7-avropa#6','umumi-tarix','utarix-7-avropa',3,3,'Fransada silki nümayəndəlik orqanı necə adlanırdı?','Fransada Baş ştatlar çağırılırdı.',array['Baş ştatlar','Duma','Konqres','Xalq məclisi'],1),
('tarix7-avropa#7','umumi-tarix','utarix-7-avropa',3,3,'Yüzillik müharibədə fransızlara qələbələr qazandıran «Orlean qızı» kim idi?','Janna Dark Orleanı mühasirədən azad etdi.',array['Janna Dark','Kleopatra','Yelizaveta','Mariya Tereza'],1),
('tarix7-avropa#8','umumi-tarix','utarix-7-avropa',2,3,'Xaçlı yürüşlərinin əsas təşkilatçısı kim idi?','Yürüşlərə Roma papası çağırış edirdi.',array['Roma papası','Çin imperatoru','Monqol xanı','Rus knyazı'],1),
('tarix7-avropa#9','umumi-tarix','utarix-7-avropa',3,3,'Xaçlıların Şərqdə yaratdığı dövlətlərdən biri hansıdır?','Birinci yürüşdən sonra Yerusəlim krallığı quruldu.',array['Yerusəlim krallığı','Qızıl Orda dövləti','Ərəb xilafəti','Atropatena dövləti'],1),
('tarix7-avropa#10','umumi-tarix','utarix-7-avropa',3,3,'Reformasiya nəticəsində yaranan yeni xristian cərəyanı necə adlanır?','Katolik kilsəsindən ayrılanlar protestantlar adlandı.',array['Protestantlıq','Pravoslavlıq','Buddizm','Zərdüştilik'],1),
('tarix7-avropa#11','umumi-tarix','utarix-7-avropa',3,3,'Hindistana dəniz yolunu açan səyyah kimdir?','Vasko da Qama Afrikanı dolanaraq Hindistana çatdı.',array['Vasko da Qama','Xristofor Kolumb','Fernan Magellan','Marko Polo'],1),
('tarix7-avropa#12','umumi-tarix','utarix-7-avropa',3,3,'Dünya səyahətini ilk dəfə başa çatdıran ekspedisiyaya kim başçılıq etmişdi?','Magellanın ekspedisiyası Yerin kürə şəklində olduğunu sübut etdi.',array['Fernan Magellan','Vasko da Qama','Xristofor Kolumb','Ceyms Kuk'],1),
('tarix7-avropa#20','umumi-tarix','utarix-7-avropa',3,3,'Böyük coğrafi kəşflərin əsas səbəbi nə idi?','Avropalılar Şərqə yeni ticarət yolları axtarırdılar.',array['Şərqə yeni ticarət yolları axtarışı','Avropada əhalinin kəskin azalması','Xəritə elminin unudulması','Kilsənin dəniz səfərlərini qadağası'],1),
('tarix7-avropa#21','umumi-tarix','utarix-7-avropa',3,3,'Magna Carta (Azadlıqların Böyük Xartiyası) nəyi məhdudlaşdırırdı?','Kralın hakimiyyətini məhdudlaşdırırdı.',array['Kral hakimiyyətini','Kəndli əməyini','Şəhər ticarətini','Kilsə nəğmələrini'],1),
('tarix7-avropa#22','umumi-tarix','utarix-7-avropa',2,3,'Yüzillik müharibənin qəhrəmanı Janna hansı ölkə uğrunda vuruşurdu?','Fransanın azadlığı uğrunda.',array['Fransa uğrunda','İngiltərə uğrunda','İspaniya uğrunda','Polşa uğrunda'],1),
('tarix7-avropa#24','umumi-tarix','utarix-7-avropa',2,3,'Kolumbun səyahətini hansı ölkə maliyyələşdirmişdi?','İspaniya kralları dəstəklədi.',array['İspaniya','Rusiya','Çin','Misir'],1),
('tarix7-avropa#25','umumi-tarix','utarix-7-avropa',2,3,'Magellan ekspedisiyası nəyi sübut etdi?','Dünyanı dolanmaqla Yerin kürəliyini.',array['Yerin kürə olduğunu','Ayın quru olduğunu','Dənizlərin dayaz olduğunu','Heç nəyi'],1),
('tarix7-avropa#26','umumi-tarix','utarix-7-avropa',3,3,'Reformasiyanın banisi Lüter hansı ölkədə çıxış etdi?','Almaniyada 95 tezislə çıxış etdi.',array['Almaniyada','Portuqaliyada','Yunanıstanda','İsveçrədə yox, Misirdə'],1),
('tarix7-orta-esrler#9','umumi-tarix','utarix-7-medeniyyet',3,4,'Avropada kitab çapı dəzgahını kim ixtira etdi?','İohan Qutenberq çap dəzgahını ixtira etdi.',array['İohan Qutenberq','İsaak Nyuton','Xristofor Kolumb','Leonardo da Vinçi'],1),
('tarix7-orta-esrler#15','umumi-tarix','utarix-7-medeniyyet',3,4,'Orta əsr Avropa universitetlərində təhsil hansı dildə aparılırdı?','Latın dilində.',array['Latın dilində','İngilis dilində','Ərəb dilində','Rus dilində'],1),
('tarix7-orta-esrler#16','umumi-tarix','utarix-7-medeniyyet',2,4,'İntibah (Renessans) hərəkatı harada başladı?','İtaliyada başladı.',array['İtaliyada','Rusiyada','Misirdə','Çində'],1),
('tarix7-orta-esrler#22','umumi-tarix','utarix-7-medeniyyet',2,4,'Qutenberqin ixtirası nəyi ucuzlaşdırdı?','Çap dəzgahı kitabı kütləviləşdirdi.',array['Kitabları','Silahları','Gəmiləri','Paltarları'],1),
('tarix7-orta-esrler#25','umumi-tarix','utarix-7-medeniyyet',2,4,'İntibah mədəniyyəti hansı ideyanı önə çəkirdi?','İnsan və onun azadlığı — humanizm.',array['İnsanı (humanizmi)','Yalnız döyüşü','Köləliyi','Xurafatı'],1),
('tarix7-orta-esrler#26','umumi-tarix','utarix-7-medeniyyet',2,4,'Leonardo da Vinçi hansı sahələrdə çalışıb?','Həm rəssam, həm alim-mühəndis idi.',array['Rəssamlıq və elm','Yalnız musiqi','Yalnız idman','Yalnız ticarət'],1),
('tarix7-avropa#13','umumi-tarix','utarix-7-medeniyyet',3,4,'İntibah dövrünün dahi rəssamı, «Mona Liza»nın müəllifi kimdir?','Leonardo da Vinçi İntibahın ən böyük nümayəndələrindəndir.',array['Leonardo da Vinçi','Rafael Santi','Volfqanq Höte','Lüdviq van Bethoven'],1),
('tarix7-avropa#14','umumi-tarix','utarix-7-medeniyyet',2,4,'Orta əsr Avropasında ali təhsil mərkəzləri hansılar idi?','İlk universitetlər Bolonya, Paris və Oksfordda yarandı.',array['Universitetlər','Rəsədxanalar','Kitab mağazaları','Teatrlar'],1),
('tarix7-avropa#27','umumi-tarix','utarix-7-medeniyyet',3,4,'İntibah incəsənətinin mərkəzi hansı İtaliya şəhəri idi?','Florensiya İntibahın beşiyi sayılır.',array['Florensiya','Berlin şəhəri','London şəhəri','Madrid şəhəri'],1),
('tarix7-avropa#30','umumi-tarix','utarix-7-medeniyyet',3,4,'Universitetlərdə tədris olunan «yeddi azad sənət»ə nə daxil idi?','Qrammatika, ritorika, riyaziyyat və s.',array['Qrammatika, ritorika, riyaziyyat','Üzgüçülük, ovçuluq, at çapmaq','Rəqs, musiqi və şəkilçəkmə','Dülgərlik, dəmirçilik, toxuculuq'],1),
('tarix7-erken-orta-esrler#2','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Xalqların böyük köçü zamanı Avropaya gələn türk tayfaları hansılar idi?','Hunlar Avropaya gələrək dövlət qurdular.',array['Hunlar','Vikinqlər','Romalılar','Misirlilər'],1),
('tarix7-erken-orta-esrler#5','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Göytürk xaqanlığı hansı xalqın dövləti idi?','Göytürk xaqanlığını türklər qurmuşdular.',array['Türklərin','Romalıların','Frankların','Ərəblərin'],1),
('tarix7-erken-orta-esrler#8','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Xəzər xaqanlığı hansı ərazidə yerləşirdi?','Xəzər dənizi ətrafında — Şimali Qafqaz və Volqaboyunda.',array['Xəzər dənizi ətrafında','Şimali Afrikada','Şimali Amerikada','Skandinaviya yarımadasında'],1),
('tarix7-erken-orta-esrler#18','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Attila hansı dövlətin hökmdarı idi?','Hun imperiyasının.',array['Hun imperiyasının','Frank dövlətinin','Bizansın','Xilafətin'],1),
('tarix7-turk-dovletleri#1','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Avropa Hun dövlətinin ən qüdrətli hökmdarı kim olmuşdur?','Attilanın dövründə Hun dövləti ən güclü dövrünü yaşadı.',array['Attila','Bumın','Osman bəy','Böyük Karl'],1),
('tarix7-turk-dovletleri#2','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Xalqların böyük köçünə təkan verən əsas amil nə idi?','Hunların qərbə hərəkəti başqa xalqları da yerindən tərpətdi.',array['Hunların qərbə hərəkəti','Dəniz səviyyəsinin qalxması','Roma dəvəti','Kitab çapının yayılması'],1),
('tarix7-turk-dovletleri#3','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Göytürk xaqanlığı hansı əsrdə yaranmışdır?','Göytürk xaqanlığı VI əsrin ortalarında quruldu.',array['VI əsrdə','XV əsrdə','II əsrdə','XIX əsrdə'],1),
('tarix7-turk-dovletleri#4','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Göytürk dövlətinin banisi kim hesab olunur?','Dövləti Bumın xaqan qurmuşdur.',array['Bumın xaqan','Attila','Toğrul bəy','Çingiz xan'],1),
('tarix7-turk-dovletleri#5','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Orxon-Yenisey abidələri hansı xalqın yazılı abidələridir?','Bu daş kitabələr qədim türklərə məxsusdur.',array['Türklərin','Yunanların','Ərəblərin','Slavyanların'],1),
('tarix7-turk-dovletleri#6','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Ağ Hun (Eftalit) dövləti hansı əraziləri əhatə edirdi?','Ağ Hunlar Orta Asiyada güclü dövlət qurmuşdular.',array['Orta Asiyanı','Şimali Afrikanı','Skandinaviyanı','Amerikanı'],1),
('tarix7-turk-dovletleri#7','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Xəzər xaqanlığının paytaxtı hansı şəhər idi?','Xaqanlığın paytaxtı Volqa üzərindəki İtil şəhəri idi.',array['İtil','Bağdad','Konstantinopol','Qazaka'],1),
('tarix7-turk-dovletleri#8','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Xəzər xaqanlığında hansı dinlərə etiqad olunurdu?','Xəzərlərdə müxtəlif dinlər, o cümlədən iudaizm yayılmışdı.',array['Müxtəlif dinlər (o cümlədən iudaizm)','Ancaq xristianlıq yayılmışdı','Ancaq buddizm yayılmışdı','Dini etiqad qadağan idi'],1),
('tarix7-turk-dovletleri#9','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Avar xaqanlığı hansı ərazidə yaranmışdı?','Avarlar Mərkəzi Avropada məskunlaşmışdılar.',array['Mərkəzi Avropada','Şimali Hindistanda','Yuxarı Misirdə','Yaponiya adalarında'],1),
('tarix7-turk-dovletleri#10','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Bulqarların bir qolu Volqa boyunda hansı dövləti yaratdı?','Volqa Bulqarıstanı ticarət mərkəzi kimi tanınırdı.',array['Volqa Bulqarıstanını','Frank dövlətini','Ərəb xilafətini','Bizans imperiyasını'],1),
('tarix7-turk-dovletleri#11','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Uyğur xaqanlığı hansı dövlətin varisi kimi yarandı?','Göytürk xaqanlığının süqutundan sonra uyğurlar hakimiyyətə gəldi.',array['Göytürk xaqanlığının','Roma imperiyasının','Misir fironluğunun','Xilafətin'],1),
('tarix7-turk-dovletleri#12','umumi-tarix','utarix-7-turk-dovletleri',1,1,'Türk dövlətlərində hökmdar hansı titul daşıyırdı?','Türk hökmdarları xaqan titulu daşıyırdı.',array['Xaqan','Firon','Konsul','Papa'],1),
('tarix7-turk-dovletleri#13','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Oğuz dövləti hansı çayın hövzəsində yerləşirdi?','Oğuzlar Sırdərya boyunda məskunlaşmışdılar.',array['Sırdərya boyunda','Nil boyunda','Reyn boyunda','Amazon boyunda'],1),
('tarix7-turk-dovletleri#14','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Qaraxanlı dövlətində hansı din qəbul edildi?','Qaraxanlılar islamı qəbul edən ilk türk dövlətlərindəndir.',array['İslam','Buddizm yalnız','Şamanizm yalnız','Katoliklik'],1),
('tarix7-turk-dovletleri#15','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Qəznəvi dövlətinin ən məşhur hökmdarı kim idi?','Sultan Mahmud Qəznəvi dövləti qüdrətli imperiyaya çevirdi.',array['Sultan Mahmud Qəznəli','Hun hökmdarı Attila','Osmanlı bəyi Osman','Frank kralı Böyük Karl'],1),
('tarix7-turk-dovletleri#16','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Samani dövləti hansı ərazidə mövcud olmuşdur?','Samanilər Orta Asiya və Xorasanda hökmranlıq edirdilər.',array['Orta Asiyada və Xorasanda','İspaniya yarımadasında','Britaniya adalarında','Şimali Afrika sahilində'],1),
('tarix7-turk-dovletleri#17','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Türk xalqlarının qədim yazısı necə adlanır?','Qədim türklər runik (Orxon) yazısından istifadə edirdilər.',array['Runik (Orxon) yazısı','Misir heroqlifləri','Latın əlifbası','Şumer mixi yazısı'],1),
('tarix7-turk-dovletleri#18','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Xəzər xaqanlığı hansı dövlətlə uzun müharibələr aparırdı?','Xəzər-ərəb müharibələri yüz ilə yaxın davam etmişdir.',array['Ərəb xilafəti ilə','Yaponiya ilə','İngiltərə ilə','Hindistanla'],1),
('tarix7-turk-dovletleri#19','umumi-tarix','utarix-7-turk-dovletleri',3,1,'«Türk» sözü ilk dəfə hansı dövlətin adında rəsmi işlənmişdir?','Göytürk xaqanlığı adında türk sözü rəsmi işlənib.',array['Göytürk xaqanlığında','Roma imperiyasında','Frank dövlətində','Bizansda'],1),
('tarix7-turk-dovletleri#20','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Xalqların böyük köçü nəticəsində Avropada hansı proses sürətləndi?','Köç Qərbi Roma imperiyasının süqutunu sürətləndirdi.',array['Roma imperiyasının süqutu','Kitab çapının kəşfi','Amerikanın kəşfi','Xaç yürüşləri'],1),
('tarix7-turk-dovletleri#21','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Bilgə xaqan hansı dövlətin hökmdarı idi?','Göytürk xaqanlığının hökmdarı idi.',array['Göytürk xaqanlığının','Roma imperiyasının','Frank dövlətinin','Bizansın'],1),
('tarix7-turk-dovletleri#22','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Orxon-Yenisey yazılarında nədən bəhs olunur?','Dövlət işləri və qəhrəmanlıqlardan.',array['Dövlət və qəhrəmanlıqdan','Ancaq ticarət işlərindən','Dəniz səyahətlərindən','Əkinçilik qaydalarından'],1),
('tarix7-turk-dovletleri#23','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Attiladan sonra Avropa Hun dövləti nə oldu?','Zəifləyib dağıldı.',array['Tənəzzülə uğradı','Gücləndi','Romanı fəth etdi','Asiyaya qayıtdı'],1),
('tarix7-turk-dovletleri#24','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Uyğurlar hansı sahədə digər köçərilərdən fərqlənirdilər?','Şəhər salıb oturaq yaşayırdılar.',array['Oturaq şəhər həyatında','Dəniz ticarətində','Buzlaqda ov etməkdə','Dağ mədənçiliyində'],1),
('tarix7-turk-dovletleri#25','umumi-tarix','utarix-7-turk-dovletleri',2,1,'İtil şəhəri hansı dövlətin paytaxtı idi?','Xəzər xaqanlığının paytaxtı idi.',array['Xəzər xaqanlığının','Göytürklərin','Osmanlının','Səfəvilərin'],1),
('tarix7-turk-dovletleri#26','umumi-tarix','utarix-7-turk-dovletleri',2,1,'İslamı qəbul edən ilk türk dövlətlərindən biri hansıdır?','Qaraxanlılar islamı qəbul etdi.',array['Qaraxanlılar','Hunlar','Avarlar','Bulqarlar'],1),
('tarix7-turk-dovletleri#27','umumi-tarix','utarix-7-turk-dovletleri',3,1,'Sultan Mahmud Qəznəvi hansı ölkəyə yürüşlər edirdi?','Hindistana 17 yürüş etmişdi.',array['Hindistana','İngiltərəyə','Misirə','İspaniyaya'],1),
('tarix7-turk-dovletleri#28','umumi-tarix','utarix-7-turk-dovletleri',3,1,'«Kutadqu bilik» əsəri hansı dövrün abidəsidir?','Qaraxanlılar dövründə yazılıb.',array['Qaraxanlılar dövrünün','Qədim Roma dövrünün','Müasir dövrün','Daş dövrünün'],1),
('tarix7-turk-dovletleri#29','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Oğuzlar sonralar hansı böyük dövlətlərin əsasını qoydular?','Səlcuq və Osmanlı dövlətlərinin.',array['Səlcuq və Osmanlının','Roma və Bizansın','Çin və Yaponiyanın','Frank və Rusun'],1),
('tarix7-turk-dovletleri#30','umumi-tarix','utarix-7-turk-dovletleri',2,1,'Türk dövlətlərində ordunun əsasını nə təşkil edirdi?','Atlı qoşun əsas qüvvə idi.',array['Süvarilər','Donanma','Fillər','Toplar'],1),
('tarix7-orta-esrler#1','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Böyük Səlcuq dövlətinin banisi kimdir?','Dövlətin əsasını Toğrul bəy qoymuşdur.',array['Toğrul bəy','Osman bəy','Çingiz xan','Böyük Karl'],1),
('tarix7-orta-esrler#2','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Monqol imperiyasının banisi kimdir?','İmperiyanı Çingiz xan yaratmışdır.',array['Çingiz xan','Əmir Teymur','Toğrul bəy','Atilla'],1),
('tarix7-orta-esrler#3','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Osmanlı dövlətinin banisi kimdir?','Dövləti Osman bəy (Osman Qazi) qurmuşdur.',array['Osman bəy','II Mehmet','Səlim','Süleyman'],1),
('tarix7-orta-esrler#4','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Konstantinopol neçənci ildə osmanlılar tərəfindən fəth edildi?','1453-cü ildə fəth edildi.',array['1453','476','1492','1918'],1),
('tarix7-orta-esrler#5','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Konstantinopolu fəth edən sultan kimdir?','II Mehmet (Fateh) şəhəri fəth etdi.',array['II Mehmet (Fateh)','Sultan Osman bəy','Səlcuq hökmdarı Toğrul bəy','Monqol xaqanı Çingiz xan'],1),
('tarix7-orta-esrler#7','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Teymuri dövlətinin banisi kimdir?','Dövləti Əmir Teymur qurmuşdur.',array['Əmir Teymur','Çingiz xan','Osman bəy','Toğrul bəy'],1),
('tarix7-orta-esrler#11','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Səlcuqların Bizans üzərində 1071-ci il qələbəsi hansı döyüşdə oldu?','Malazgird döyüşündə.',array['Malazgird döyüşündə','Qavqamela döyüşündə','Poltava döyüşündə','Vaterloo döyüşündə'],1),
('tarix7-orta-esrler#12','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Monqol yürüşləri hansı əsrdə başladı?','XIII əsrdə.',array['XIII yüzillikdə','V yüzillikdə','XIX yüzillikdə','X yüzillikdə'],1),
('tarix7-orta-esrler#13','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Osmanlı dövləti hansı dövrdə yarandı?','XIII əsrin sonunda (1299).',array['XIII əsrin sonunda','V əsrin əvvəlində','XVIII əsrin ortasında','XX əsrin əvvəlində'],1),
('tarix7-orta-esrler#18','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Əmir Teymurun paytaxtı hansı şəhər idi?','Səmərqənd şəhəri.',array['Səmərqənd','Buxara','İstanbul','Qahirə'],1),
('tarix7-orta-esrler#19','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Qızıl Orda dövləti kimlər tərəfindən yaradılmışdı?','Batı xanın başçılığı ilə monqollar.',array['Monqollar (Batı xan)','Franklar (Böyük Karl)','Ərəblər (Əməvilər)','Vikinqlər (normanlar)'],1),
('tarix7-orta-esrler#20','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'1453-cü ildə hansı imperiya süqut etdi?','Konstantinopolun fəthi ilə Bizans süqut etdi.',array['Bizans imperiyası','Roma respublikası','Osmanlı dövləti','Səfəvi dövləti'],1),
('tarix7-orta-esrler#27','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Monqol yürüşlərindən sonra Şərqi Avropada hansı dövlət yarandı?','Qızıl Orda dövləti quruldu.',array['Qızıl Orda','Roma','Osmanlı','Frank'],1),
('tarix7-orta-esrler#30','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Bizansın süqutu Avropa tarixində hansı dövrü bağladı?','1453-cü il orta əsrlərin sonu sayılır.',array['Orta əsrləri','Daş dövrünü','Yeni dövrü','Antik dövrü'],1),
('tarix7-selcuq-osmanli#1','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Səlcuqlar hansı türk tayfa birliyindən çıxmışlar?','Səlcuqlar oğuzların qınıq boyundan idilər.',array['Oğuzlardan','Uyğurlardan','Bulqarlardan','Avarlardan'],1),
('tarix7-selcuq-osmanli#2','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Malazgird döyüşündə Səlcuq ordusuna kim başçılıq edirdi?','1071-ci ildə Alp Arslan Bizansı məğlub etdi.',array['Alp Arslan','Osman bəy','Attila','Çingiz xan'],1),
('tarix7-selcuq-osmanli#3','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Böyük Səlcuq dövlətinin məşhur vəziri kim idi?','Nizamülmülk dövlət quruculuğunda böyük rol oynadı.',array['Nizamülmülk','Sokrat','Aristotel','Marko Polo'],1),
('tarix7-selcuq-osmanli#4','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Nizamiyyə mədrəsələri hansı dövlətdə yaradılmışdı?','Bu mədrəsələr Səlcuq dövlətində açılmışdı.',array['Səlcuq dövlətində','Frank dövlətində','Bizansda','İngiltərədə'],1),
('tarix7-selcuq-osmanli#5','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Çingiz xanın əsl adı nə idi?','Onun əsl adı Temuçin idi.',array['Temuçin','Batı','Toxtamış','Bumın'],1),
('tarix7-selcuq-osmanli#6','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Monqol dövlətinin qanunlar toplusu necə adlanırdı?','Çingiz xanın qanunları «Yasa» adlanırdı.',array['«Yasa»','«Konstitusiya»','«Xartiya»','«Avesta»'],1),
('tarix7-selcuq-osmanli#7','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Qızıl Ordanın paytaxtı hansı şəhər idi?','Dövlətin mərkəzi Volqa üzərindəki Saray şəhəri idi.',array['Saray','Səmərqənd','Moskva','Dehli'],1),
('tarix7-selcuq-osmanli#8','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'1380-ci ildə Kulikovo döyüşündə monqollara qarşı kim qalib gəldi?','Moskva knyazı Dmitri Donskoy qələbə qazandı.',array['Moskva knyazı Dmitri','Frank kralı Böyük Karl','İngilis kralı Vilhelm','Bizans imperatoru Yustinian'],1),
('tarix7-selcuq-osmanli#9','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Osmanlı ordusunda seçmə piyada qoşunu hansı adla tanınırdı?','Yeniçərilər sultanın daimi qoşunu idi.',array['Yeniçərilər','Cəngavərlər','Leqionerlər','Qladiatorlar'],1),
('tarix7-selcuq-osmanli#10','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'1402-ci il Ankara döyüşündə hansı hökmdarlar qarşılaşdı?','Teymur İldırım Bəyazidi məğlub etdi.',array['Teymur və İldırım Bəyazid','Attila və Karl','Çingiz xan və Osman','Alp Arslan və Roman Diogen'],1),
('tarix7-selcuq-osmanli#11','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Dehli sultanlığı hansı ölkənin ərazisində yaranmışdı?','Sultanlıq Şimali Hindistanda qurulmuşdu.',array['Hindistanda','Misirdə','İspaniyada','İranda'],1),
('tarix7-selcuq-osmanli#12','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Böyük Moğol dövlətinin banisi kimdir?','Dövləti Teymurun nəslindən olan Babur qurdu.',array['Babur','Əkbər şah','Mahmud Qəznəli','Nadir şah'],1),
('tarix7-selcuq-osmanli#13','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Osmanlı dövlətində sultandan sonra ən yüksək vəzifə hansı idi?','Dövlət işlərinə sədrəzəm (baş vəzir) baxırdı.',array['Sədrəzəm (baş vəzir)','Konsul (ali məmur)','Senator (məclis üzvü)','Xaqan (türk hökmdarı)'],1),
('tarix7-selcuq-osmanli#14','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Teymuri hökmdarı Uluqbəy hansı elm sahəsi ilə məşğul olurdu?','Uluqbəy Səmərqənddə rəsədxana qurmuş astronom idi.',array['Astronomiya ilə','Dənizçiliklə','Kitab çapı ilə','Kimyagərliklə'],1),
('tarix7-selcuq-osmanli#15','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Monqol imperiyası Çingiz xanın ölümündən sonra necə idarə olundu?','İmperiya oğulları arasında uluslara bölündü.',array['Uluslara bölündü','Respublika oldu','Satıldı','Dəyişməz qaldı'],1),
('tarix7-selcuq-osmanli#16','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Osmanlıların Avropada ilk geniş fəthləri hansı ərazidə oldu?','Osmanlılar Balkanlarda möhkəmləndilər.',array['Balkanlarda','Skandinaviyada','İrlandiyada','Portuqaliyada'],1),
('tarix7-selcuq-osmanli#17','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Böyük Səlcuq dövləti hansı əsrdə zəifləyib parçalandı?','XII əsrdə dövlət ayrı-ayrı sultanlıqlara parçalandı.',array['XII əsrdə','XX əsrdə','V əsrdə','XVIII əsrdə'],1),
('tarix7-selcuq-osmanli#18','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Monqol yürüşləri hansı əraziləri xüsusilə viran qoydu?','Orta Asiya və Yaxın Şərq şəhərləri dağıdıldı.',array['Orta Asiya və Yaxın Şərqi','Avstraliya və Okeaniyanı','Skandinaviya yarımadasını','Şimali Amerika sahillərini'],1),
('tarix7-selcuq-osmanli#19','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Osmanlı dövlətində torpaqlar hərbçilərə hansı şərtlə verilirdi?','Torpaq hərbi xidmət müqabilində (timar) verilirdi.',array['Hərbi xidmət müqabilində (timar)','Əvəzsiz hədiyyə kimi bağışlanırdı','Açıq hərracda satış yolu ilə','İrsi mülkiyyət kimi ötürülürdü'],1),
('tarix7-selcuq-osmanli#20','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Konstantinopolun fəthindən sonra şəhər hansı adla tanınmağa başladı?','Şəhər İstanbul adlandırıldı və paytaxt oldu.',array['İstanbul','Ankara','Roma','Afina'],1),
('tarix7-selcuq-osmanli#21','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Malazgird qələbəsi hansı prosesə yol açdı?','Anadolu türk yurduna çevrildi.',array['Anadolunun türkləşməsinə','Romanın süqutuna','Amerikanın kəşfinə','Xilafətin yaranmasına'],1),
('tarix7-selcuq-osmanli#22','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Nizamülmülk hansı əsəri ilə tanınır?','«Siyasətnamə» əsərini yazıb.',array['«Siyasətnamə» ilə','«Xəmsə» ilə','«Avesta» ilə','«İliada» ilə'],1),
('tarix7-selcuq-osmanli#23','umumi-tarix','utarix-7-selcuq-osmanli',1,3,'Osmanlı dövlətinin adı kimin adından götürülüb?','Banisi Osman bəyin adından.',array['Osman bəyin adından','Şəhər adından','Çay adından','Dağ adından'],1),
('tarix7-selcuq-osmanli#24','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Yeniçəri ordusu kimlərdən formalaşdırılırdı?','Xüsusi toplanıb təlim keçən gənclərdən.',array['Toplanmış gənclərdən','Yalnız taciriərdən','Səyyahlardan','Dənizçilərdən'],1),
('tarix7-selcuq-osmanli#25','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'II Mehmetə «Fateh» adını hansı hadisə qazandırdı?','1453-də Konstantinopolu fəth etdi.',array['Konstantinopolun fəthi','Vyana mühasirəsi','Ankara döyüşü','Krım səfəri'],1),
('tarix7-selcuq-osmanli#26','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Teymurun Ankara qələbəsi Osmanlıya nə gətirdi?','Hakimiyyət böhranı — fetrət dövrü.',array['Fetrət (böhran) dövrü','Sürətli yüksəliş dövrü','Yeni paytaxtın salınması','Dənizdə tam üstünlük'],1),
('tarix7-selcuq-osmanli#27','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Səlcuq dövlətində «atabəy» kim idi?','Şahzadələrin tərbiyəçisi idi.',array['Şahzadə tərbiyəçisi','Saray baş aşpazı','Dəniz qoşunu komandanı','Vergi yığan məmur'],1),
('tarix7-selcuq-osmanli#28','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Osmanlıda dövlət məsələləri hansı şurada müzakirə olunurdu?','Divan məclisində müzakirə edilirdi.',array['Divanda','Parlamentdə','Senatda','Dumada'],1),
('tarix7-selcuq-osmanli#29','umumi-tarix','utarix-7-selcuq-osmanli',3,3,'Sultan Süleyman Qanuni hansı sahədəki fəaliyyəti ilə məşhurdur?','Qanunlar tərtib etdirmişdi.',array['Qanunvericilikdə','Rəssamlıqda','Əkinçilikdə','Dənizçilikdə yalnız'],1),
('tarix7-selcuq-osmanli#30','umumi-tarix','utarix-7-selcuq-osmanli',2,3,'Çingiz xanın «Yasa»sı nə idi?','Dövlətin qanunlar toplusu idi.',array['Qanunlar toplusu','Mahnı kitabı','Xəritə','Təqvim'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, tp.level_id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = d.fenn
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

-- ----------------------------------------------------------------------
--  Kohne 'tarix-7-*' movzulari artiq bosdur - silinir.
--  Teze bazada (db/run.sh) 29 onlari onsuz da acmir, bu blok bos isleyir.
-- ----------------------------------------------------------------------
do $$
declare r record; qaliq int;
begin
  for r in
    select t.id, t.slug from public.topics t
      join public.subjects s on s.id = t.subject_id and s.slug = 'tarix'
      join public.levels   l on l.id = t.level_id and l.code = '7'
  loop
    select count(*) into qaliq from public.questions where topic_id = r.id;
    if qaliq > 0 then
      raise exception 'Kohne movzu %-de hele % sual var - silinmir',
                      r.slug, qaliq;
    end if;
    delete from public.topics where id = r.id;
    raise notice 'Bosalmis movzu silindi: %', r.slug;
  end loop;
end $$;

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform' and ext_key like 'tarix7-%';
  if n <> 180 then
    raise exception 'Kocurulen 7-ci sinif suallari: 180 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'tarix7-%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;

  --  7-ci sinif Umumi tarix: 8 movzu, 366 sual
  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '7';
  if k <> 8 then
    raise exception 'Umumi tarix 7: 8 movzu gozlenilirdi, % tapildi', k;
  end if;
  select count(*) into k
    from public.questions q
    join public.topics t on t.id = q.topic_id
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id and l.code = '7'
   where q.status = 'published';
  if k <> 366 then
    raise exception 'Umumi tarix 7: 366 sual gozlenilirdi, % tapildi', k;
  end if;

  --  'tarix' fenni 7-ci sinifden tam cixmalidir
  select count(*) into k
    from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'tarix'
    join public.levels   l on l.id = t.level_id and l.code = '7';
  if k <> 0 then
    raise exception '7-ci sinifde hele de % "tarix" movzusu var', k;
  end if;

  --  her movzuda en azi 12 cetin sual
  select count(*) into k from (
    select t.id from public.topics t
      join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
      join public.levels   l on l.id = t.level_id and l.code = '7'
      left join public.questions q on q.topic_id = t.id and q.difficulty = 3
                                  and q.status = 'published'
     group by t.id having count(q.id) < 12) z;
  if k > 0 then
    raise exception '% movzuda 12-den az cetin sual var', k;
  end if;

  raise notice 'Umumi tarix 7: 8 movzu, 366 sual (% kocurulen).', n;
end $$;
