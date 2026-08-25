-- =====================================================================
--  39_bank_sinif8.sql : 8-CI SINIF - AZ DILI, INGILIS DILI,
--                       INFORMATIKA, AZERBAYCAN TARIXI
--
--  BU FAYL ELLE YAZILMIR - tools/sinif8.py yaradir:
--      python3 tools/sinif8.py
--
--  Az dili 8 + Ingilis dili 6 + Informatika 6 + Tarix 4
--  = 24 movzu x 10 = 240.  ext_key: az8-/ing8-/inf8-/tarix8-...
--  ON SERT: 37_movzular_orta8.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('az-dili','az-8-hemcins'),
                                ('ingilis-dili','ing-8-media'),
                                ('informatika','inf-8-multimedia'),
                                ('tarix','tarix-8-xanliqlar'))
     having count(*) = 4) then
    raise exception 'ONCE 37_movzular_orta8.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'az8-%' or q.ext_key like 'ing8-%'
        or q.ext_key like 'inf8-%' or q.ext_key like 'tarix8-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('az8-soz-birlesmesi#1','az-dili','az-8-soz-birlesmesi',2,1,'Söz birləşmələri əsas tərəfinə görə hansı növlərə ayrılır?','İsmi və feili birləşmələrə ayrılır.',array['İsmi və feili','Sadə və mürəkkəb','Tək və cəm','Uzun və qısa'],1),
('az8-soz-birlesmesi#2','az-dili','az-8-soz-birlesmesi',2,1,'«Dağların gözəlliyi» hansı birləşmə növüdür?','Əsas tərəf isimdir — ismi birləşmədir.',array['İsmi','Feili','Zərf birləşməsi','Cümlədir'],1),
('az8-soz-birlesmesi#3','az-dili','az-8-soz-birlesmesi',3,1,'«Kitab oxuyan» birləşməsi hansı növdəndir?','Əsas tərəf feili sifətdir — feili birləşmədir.',array['Feili','İsmi','Say birləşməsi','Nida'],1),
('az8-soz-birlesmesi#4','az-dili','az-8-soz-birlesmesi',3,1,'Feili birləşmənin əsas tərəfi nə ilə ifadə olunur?','Feilin təsriflənməyən formaları ilə (məsdər, feili sifət, feili bağlama).',array['Feilin təsriflənməyən formaları ilə','Yalnız isimlə','Bağlayıcı ilə','Ədatla'],1),
('az8-soz-birlesmesi#5','az-dili','az-8-soz-birlesmesi',3,1,'Birləşmənin tərəfləri arasında hansı əlaqə var?','Asılı tərəf əsas tərəfə tabedir — tabelilik əlaqəsi.',array['Tabelilik (asılılıq)','Bərabərlik','Əlaqə yoxdur','Yalnız məna əlaqəsi yoxdur'],1),
('az8-soz-birlesmesi#6','az-dili','az-8-soz-birlesmesi',2,1,'«Qızıl payız» birləşməsində asılı tərəf hansıdır?','«Qızıl» sözü «payız» sözünü izah edir — asılıdır.',array['qızıl','payız','hər ikisi','heç biri'],1),
('az8-soz-birlesmesi#7','az-dili','az-8-soz-birlesmesi',3,1,'Üçüncü növ təyini söz birləşməsinin birinci tərəfi hansı haldadır?','Birinci tərəf yiyəlik haldadır: məktəbin həyəti.',array['Yiyəlik halda','Adlıq halda şəkilçisiz','Təsirlik halda','Çıxışlıq halda'],1),
('az8-soz-birlesmesi#8','az-dili','az-8-soz-birlesmesi',3,1,'«Şəhərin küçələri» neçənci növ təyini söz birləşməsidir?','Hər iki tərəf şəkilçilidir — üçüncü növdür.',array['Üçüncü','Birinci','İkinci','Beşinci'],1),
('az8-soz-birlesmesi#9','az-dili','az-8-soz-birlesmesi',3,1,'Söz birləşməsini mürəkkəb sözdən nə fərqləndirir?','Birləşmədə hər söz müstəqilliyini saxlayır və ayrı yazılır.',array['Sözlərin müstəqilliyini saxlaması','Bitişik yazılması','Bir vurğu daşıması','Fərq yoxdur'],1),
('az8-soz-birlesmesi#10','az-dili','az-8-soz-birlesmesi',3,1,'Sabit birləşmələr sərbəst birləşmələrdən nə ilə fərqlənir?','Sabit birləşmənin mənası tərkib sözlərdən çıxmır.',array['Mənası tərkib sözlərdən çıxmır','Daha uzun olur','Yalnız şeirdə işlənir','Fərqlənmir'],1),
('az8-mubteda-xeber#1','az-dili','az-8-mubteda-xeber',2,1,'Mübtəda hansı halda olur?','Mübtəda adlıq halda olur.',array['Adlıq halda','Yiyəlik halda','Təsirlik halda','Yerlik halda'],1),
('az8-mubteda-xeber#2','az-dili','az-8-mubteda-xeber',3,1,'Xəbər mübtəda ilə nəyə görə uzlaşır?','Şəxsə və kəmiyyətə görə uzlaşır.',array['Şəxsə və kəmiyyətə görə','Rəngə görə','Uzunluğa görə','Uzlaşmır'],1),
('az8-mubteda-xeber#3','az-dili','az-8-mubteda-xeber',2,1,'«Biz kitab oxuyuruq» cümləsində xəbər hansı şəxsdədir?','-uq şəxs sonluğu I şəxsin cəmidir.',array['I şəxs cəmdə','II şəxs təkdə','III şəxs cəmdə','Şəxsi yoxdur'],1),
('az8-mubteda-xeber#4','az-dili','az-8-mubteda-xeber',3,1,'İsmi xəbərə misal hansıdır?','«Atam həkimdir» — xəbər isimlə ifadə olunub.',array['Atam həkimdir.','Uşaq qaçır.','Quş uçdu.','Yağış yağacaq.'],1),
('az8-mubteda-xeber#5','az-dili','az-8-mubteda-xeber',2,1,'Feili xəbər nə ilə ifadə olunur?','Feilin təsriflənən formaları ilə.',array['Feillə','Yalnız isimlə','Sayla','Qoşma ilə'],1),
('az8-mubteda-xeber#6','az-dili','az-8-mubteda-xeber',2,1,'«Hava soyuqdur» cümləsində xəbər hansıdır?','Hava necədir? — soyuqdur (ismi xəbər).',array['soyuqdur','hava','cümlədə xəbər yoxdur','hər ikisi'],1),
('az8-mubteda-xeber#7','az-dili','az-8-mubteda-xeber',3,1,'Mübtəda hansı nitq hissələri ilə ifadə oluna bilər?','İsim, əvəzlik, məsdər və isimləşmiş sözlərlə.',array['İsim, əvəzlik, məsdərlə','Yalnız feillə','Yalnız bağlayıcı ilə','Nida ilə'],1),
('az8-mubteda-xeber#8','az-dili','az-8-mubteda-xeber',3,1,'«Oxumaq faydalıdır» cümləsində mübtəda nə ilə ifadə olunub?','«Oxumaq» məsdərdir.',array['Məsdərlə','İsimlə','Sifətlə','Zərflə'],1),
('az8-mubteda-xeber#9','az-dili','az-8-mubteda-xeber',3,1,'Cümlədə mübtəda buraxıla bilərmi?','Bəli — şəxs sonluğundan bilinərsə: Gəlirəm (mən).',array['Bəli, şəxs sonluğundan bilinərsə','Heç vaxt','Yalnız şeirdə','Yalnız sualda'],1),
('az8-mubteda-xeber#10','az-dili','az-8-mubteda-xeber',1,1,'«Sən gəl» cümləsində mübtəda hansıdır?','Kim gəlsin? — sən.',array['Sən','Gəl','Hər ikisi','Mübtəda yoxdur'],1),
('az8-ikinci-uzvler#1','az-dili','az-8-ikinci-uzvler',3,2,'Vasitəsiz tamamlıq hansı halda olur?','Təsirlik halda (müəyyən və qeyri-müəyyən).',array['Təsirlik halda','Yönlük halda','Yerlik halda','Adlıq halda'],1),
('az8-ikinci-uzvler#2','az-dili','az-8-ikinci-uzvler',3,2,'Vasitəli tamamlıq hansı hallarda olur?','Yönlük, yerlik və çıxışlıq hallarda.',array['Yönlük, yerlik, çıxışlıq','Yalnız təsirlik','Yalnız adlıq','Heç bir halda'],1),
('az8-ikinci-uzvler#3','az-dili','az-8-ikinci-uzvler',3,2,'«Məktuba cavab yazdım» cümləsində «məktuba» hansı tamamlıqdır?','Yönlük haldadır — vasitəli tamamlıqdır.',array['Vasitəli','Vasitəsiz','Təyin','Zərflik'],1),
('az8-ikinci-uzvler#4','az-dili','az-8-ikinci-uzvler',3,2,'Təyin əsasən hansı üzvləri izah edir?','İsimlə ifadə olunan üzvləri.',array['İsimlə ifadə olunan üzvləri','Yalnız xəbəri','Yalnız zərfliyi','Bağlayıcıları'],1),
('az8-ikinci-uzvler#5','az-dili','az-8-ikinci-uzvler',2,2,'Səbəb zərfliyi hansı suala cavab verir?','Niyə? Nə üçün? Nə səbəbə?',array['Niyə? Nə üçün?','Harada?','Nə zaman?','Necə?'],1),
('az8-ikinci-uzvler#6','az-dili','az-8-ikinci-uzvler',3,2,'«Sevincdən ağladı» cümləsində «sevincdən» hansı zərflikdir?','Niyə ağladı? — səbəb zərfliyi.',array['Səbəb zərfliyi','Zaman zərfliyi','Yer zərfliyi','Tamamlıq'],1),
('az8-ikinci-uzvler#7','az-dili','az-8-ikinci-uzvler',3,2,'Məqsəd zərfliyi hansı suala cavab verir?','Nə məqsədlə? sualına.',array['Nə məqsədlə?','Haradan?','Neçə?','Kimin?'],1),
('az8-ikinci-uzvler#8','az-dili','az-8-ikinci-uzvler',3,2,'«Şagird kimi danışdı» ifadəsində «şagird kimi» hansı üzvdür?','Necə danışdı? — tərzi-hərəkət zərfliyi.',array['Tərzi-hərəkət zərfliyi','Mübtəda','Təyin','Vasitəsiz tamamlıq'],1),
('az8-ikinci-uzvler#9','az-dili','az-8-ikinci-uzvler',3,2,'Kəmiyyət zərfliyi nəyi bildirir?','Hərəkətin miqdarını, dərəcəsini.',array['Hərəkətin miqdarını','Hərəkətin yerini','Əşyanın rəngini','Şəxsi'],1),
('az8-ikinci-uzvler#10','az-dili','az-8-ikinci-uzvler',3,2,'«Beş dəfə oxudum» cümləsində «beş dəfə» hansı üzvdür?','Neçə dəfə? — kəmiyyət zərfliyi.',array['Kəmiyyət zərfliyi','Tamamlıq','Təyin','Xəbər'],1),
('az8-hemcins#1','az-dili','az-8-hemcins',2,2,'Həmcins üzvlər hansı üzvlərdir?','Eyni suala cavab verib eyni üzvə aid olan üzvlərdir.',array['Eyni suala cavab verən eyni cür üzvlər','Müxtəlif suallara cavab verənlər','Yalnız xəbərlər','Yalnız mübtədalar'],1),
('az8-hemcins#2','az-dili','az-8-hemcins',2,2,'«Bağda alma, armud və gavalı yetişir» cümləsində həmcins üzvlər hansılardır?','Alma, armud, gavalı — həmcins mübtədalardır.',array['alma, armud, gavalı','bağda, yetişir','yalnız alma','cümlədə yoxdur'],1),
('az8-hemcins#3','az-dili','az-8-hemcins',2,2,'Həmcins üzvlər arasına adətən hansı işarə qoyulur?','Sadalanan həmcins üzvlər vergüllə ayrılır.',array['Vergül','Nöqtə','Tire','İki nöqtə'],1),
('az8-hemcins#4','az-dili','az-8-hemcins',3,2,'Həmcins üzvləri bağlayan bağlayıcılara misal hansıdır?','Və, həm, nə…nə, amma bağlayıcıları.',array['və, həm, amma','çünki, əgər','ki, deməli','kaş, təki'],1),
('az8-hemcins#5','az-dili','az-8-hemcins',3,2,'Təkrarlanmayan «və» bağlayıcısından əvvəl vergül qoyulurmu?','Xeyr — tək «və»-dən əvvəl vergül qoyulmur.',array['Xeyr, qoyulmur','Bəli, həmişə','Yalnız şeirdə','Yalnız sualda'],1),
('az8-hemcins#6','az-dili','az-8-hemcins',3,2,'Ümumiləşdirici söz həmcins üzvlərdən ƏVVƏL gələndə ondan sonra hansı işarə qoyulur?','İki nöqtə qoyulur.',array['İki nöqtə','Tire','Nöqtə','Sual işarəsi'],1),
('az8-hemcins#7','az-dili','az-8-hemcins',3,2,'«Hər şey: ağaclar, çiçəklər, quşlar oyandı» cümləsində ümumiləşdirici söz hansıdır?','«Hər şey» həmcins üzvləri ümumiləşdirir.',array['Hər şey','ağaclar','oyandı','quşlar'],1),
('az8-hemcins#8','az-dili','az-8-hemcins',3,2,'Həmcins xəbərli cümləyə misal hansıdır?','«Uşaq gülür, oynayır, oxuyurdu» — üç həmcins xəbər.',array['Uşaq gülür, oynayır, oxuyurdu.','Uşaq şəkil çəkdi.','Hava istidir.','Kitab masadadır.'],1),
('az8-hemcins#9','az-dili','az-8-hemcins',3,2,'Ümumiləşdirici söz həmcins üzvlərdən SONRA gələndə ondan əvvəl nə qoyulur?','Tire qoyulur.',array['Tire','İki nöqtə','Nöqtəli vergül','Mötərizə'],1),
('az8-hemcins#10','az-dili','az-8-hemcins',2,2,'Həmcins üzvlər cümləyə nə verir?','Fikri genişləndirir, ifadəliliyi artırır.',array['Genişlik və ifadəlilik','Qısalıq','Qeyri-müəyyənlik','Heç nə'],1),
('az8-xitab-ara#1','az-dili','az-8-xitab-ara',2,3,'Xitab nədir?','Müraciət olunan şəxsi və ya əşyanı bildirən sözdür.',array['Müraciət bildirən söz','Cümlənin xəbəri','Bağlayıcı söz','Say'],1),
('az8-xitab-ara#2','az-dili','az-8-xitab-ara',2,3,'«Uşaqlar, sabahınız xeyir!» cümləsində xitab hansıdır?','Müraciət «uşaqlar» sözünədir.',array['Uşaqlar','sabahınız','xeyir','xitab yoxdur'],1),
('az8-xitab-ara#3','az-dili','az-8-xitab-ara',3,3,'Xitab cümlə üzvüdürmü?','Xeyr — xitab cümlə üzvü deyil.',array['Xeyr, üzv deyil','Bəli, mübtədadır','Bəli, xəbərdir','Bəli, təyindir'],1),
('az8-xitab-ara#4','az-dili','az-8-xitab-ara',2,3,'Xitab yazıda nə ilə ayrılır?','Vergüllə (güclü hissdə nida işarəsi ilə).',array['Vergüllə','Nöqtə ilə','Mötərizə ilə','Ayrılmır'],1),
('az8-xitab-ara#5','az-dili','az-8-xitab-ara',3,3,'Ara sözlər nəyi ifadə edir?','Danışanın fikrə münasibətini: yəqinlik, güman, nəticə.',array['Fikrə münasibəti (yəqinlik, güman)','Əşyanın adını','Hərəkətin yerini','Sayı'],1),
('az8-xitab-ara#6','az-dili','az-8-xitab-ara',2,3,'«Deyəsən, yağış yağacaq» cümləsində ara söz hansıdır?','«Deyəsən» güman bildirən ara sözdür.',array['Deyəsən','yağış','yağacaq','ara söz yoxdur'],1),
('az8-xitab-ara#7','az-dili','az-8-xitab-ara',2,3,'Ara sözlər yazıda necə ayrılır?','Vergüllərlə ayrılır.',array['Vergüllərlə','Nöqtələrlə','Dırnaqlarla','Heç nə ilə'],1),
('az8-xitab-ara#8','az-dili','az-8-xitab-ara',2,3,'«Əzizim ana!» müraciəti cümlədə nə rolunu oynayır?','Bu, xitabdır.',array['Xitab','Mübtəda','Tamamlıq','Xəbər'],1),
('az8-xitab-ara#9','az-dili','az-8-xitab-ara',3,3,'Ara sözü cümlə üzvündən necə fərqləndirmək olar?','Ara sözə cümlə üzvü kimi sual vermək olmur.',array['Ona sual vermək olmur','Ara söz həmişə sondadır','Ara söz böyük hərflə yazılır','Fərqləndirmək olmur'],1),
('az8-xitab-ara#10','az-dili','az-8-xitab-ara',3,3,'«Beləliklə» ara sözü nəyi bildirir?','Nəticəni bildirir.',array['Nəticəni','Gümanı','Sevinci','Sualı'],1),
('az8-cumle-novleri#1','az-dili','az-8-cumle-novleri',2,3,'Cüttərkibli cümlə hansı cümlədir?','Hər iki baş üzvü (mübtəda və xəbəri) olan cümlə.',array['Hər iki baş üzvü olan','Yalnız xəbəri olan','Üzvsüz cümlə','İki xəbərli cümlə'],1),
('az8-cumle-novleri#2','az-dili','az-8-cumle-novleri',3,3,'Təktərkibli cümlədə nə olur?','Baş üzvlərdən yalnız biri olur.',array['Baş üzvlərdən yalnız biri','Hər iki baş üzv','Yalnız ikinci dərəcəli üzvlər','Heç bir üzv'],1),
('az8-cumle-novleri#3','az-dili','az-8-cumle-novleri',3,3,'«Qış. Şaxta.» — bu cümlələr hansı növdəndir?','Əşyanın adını bildirən adlıq cümlələrdir.',array['Adlıq cümlə','Şəxssiz cümlə','Yarımçıq cümlə','Cüttərkibli'],1),
('az8-cumle-novleri#4','az-dili','az-8-cumle-novleri',3,3,'Mübtədası olmayan və təsəvvür edilməyən cümlə necə adlanır?','Belə cümlə şəxssiz cümlədir.',array['Şəxssiz','Müəyyən şəxsli','Adlıq','Yarımçıq'],1),
('az8-cumle-novleri#5','az-dili','az-8-cumle-novleri',3,3,'Müəyyən şəxsli cümlədə mübtəda niyə buraxılır?','Şəxs sonluğundan kim olduğu bilinir.',array['Şəxs sonluğundan bilinir','Unudulur','Yazmaq qadağandır','Buraxılmır'],1),
('az8-cumle-novleri#6','az-dili','az-8-cumle-novleri',3,3,'«Gəlirəm» cümləsi hansı növ təktərkibli cümlədir?','Şəxs sonluğu «mən»i göstərir — müəyyən şəxslidir.',array['Müəyyən şəxsli','Qeyri-müəyyən şəxsli','Adlıq','Şəxssiz'],1),
('az8-cumle-novleri#7','az-dili','az-8-cumle-novleri',3,3,'Yarımçıq cümlə nədir?','Buraxılmış üzvü mətndən bərpa olunan cümlədir.',array['Üzvü mətndən bərpa olunan cümlə','Səhv cümlə','Uzun cümlə','Sual cümləsi'],1),
('az8-cumle-novleri#8','az-dili','az-8-cumle-novleri',3,3,'«Deyirlər ki, sabah qar yağacaq» — «deyirlər» hansı növ cümlənin xəbəridir?','İcraçı qeyri-müəyyəndir — qeyri-müəyyən şəxsli cümlədir.',array['Qeyri-müəyyən şəxsli','Müəyyən şəxsli','Adlıq','Şəxssiz'],1),
('az8-cumle-novleri#9','az-dili','az-8-cumle-novleri',2,3,'Geniş cümlə hansı cümlədir?','İkinci dərəcəli üzvləri olan cümlə.',array['İkinci dərəcəli üzvləri olan','Yalnız baş üzvlü','Ən uzun cümlə','Mürəkkəb cümlə'],1),
('az8-cumle-novleri#10','az-dili','az-8-cumle-novleri',3,3,'Müxtəsər cümləyə misal hansıdır?','«Külək əsdi» — yalnız baş üzvlərdən ibarətdir.',array['Külək əsdi.','Güclü külək səhərdən əsdi.','Dünən şəhərdə külək əsdi.','Külək əsdi və yağış yağdı.'],1),
('az8-durgu#1','az-dili','az-8-durgu',2,4,'Vasitəsiz nitq necə yazılır?','Dırnaq içində, olduğu kimi yazılır.',array['Dırnaq içində','Mötərizədə','Kursivlə','Sətirdən kənarda'],1),
('az8-durgu#2','az-dili','az-8-durgu',3,4,'Müəllifin sözlərindən sonra vasitəsiz nitqdən əvvəl nə qoyulur?','İki nöqtə qoyulur.',array['İki nöqtə','Vergül','Nöqtə','Heç nə'],1),
('az8-durgu#3','az-dili','az-8-durgu',3,4,'«Kitab — bilik mənbəyidir» cümləsində tire niyə qoyulub?','Hər iki baş üzv isimlə ifadə olunub — aralarına tire qoyulur.',array['Mübtəda ilə xəbər arasına','Sadalama üçün','Sual üçün','Səhv qoyulub'],1),
('az8-durgu#4','az-dili','az-8-durgu',2,4,'Dialoqda hər replikanın əvvəlində hansı işarə qoyulur?','Tire qoyulur.',array['Tire','Dırnaq','Nöqtə','Ulduz'],1),
('az8-durgu#5','az-dili','az-8-durgu',2,4,'Bədii əsərin adı mətndə necə yazılır?','Dırnaqda yazılır: «Xəmsə».',array['Dırnaqda','Mötərizədə','Böyük hərflərlə bütöv','Adi qaydada işarəsiz'],1),
('az8-durgu#6','az-dili','az-8-durgu',2,4,'Cümlənin sonunda üç nöqtə nəyi bildirir?','Fikrin bitmədiyini, davam etdiyini.',array['Fikrin bitmədiyini','Sualı','Əmri','Sevinci'],1),
('az8-durgu#7','az-dili','az-8-durgu',2,4,'Vergül hansı hallarda qoyulur?','Həmcins üzvlər, ara sözlər, xitablar ayrılarkən.',array['Həmcins üzv, ara söz, xitab ayrılarkən','Hər sözdən sonra','Yalnız cümlə sonunda','Heç vaxt'],1),
('az8-durgu#8','az-dili','az-8-durgu',2,4,'Mötərizə nə üçün işlənir?','Əlavə izahat vermək üçün.',array['Əlavə izahat üçün','Cümləni bitirmək üçün','Sual vermək üçün','Bəzək üçün'],1),
('az8-durgu#9','az-dili','az-8-durgu',3,4,'Sual və güclü hiss birləşəndə hansı işarələr qoyulur?','Sual və nida işarəsi birgə: ?!',array['?! (sual və nida)','Yalnız nöqtə','İki vergül','Üç tire'],1),
('az8-durgu#10','az-dili','az-8-durgu',3,4,'Dostum dedi: «Sabah gələcəyəm». — Dırnaqdakı hissə hansı nitqdir?','Sözlər olduğu kimi verilib — vasitəsiz nitqdir.',array['Vasitəsiz nitq','Vasitəli nitq','Ara söz','Xitab'],1),
('az8-metn-uslub#1','az-dili','az-8-metn-uslub',2,4,'Mətnin əsas fikri necə adlanır?','Əsas fikir mətnin ideyasıdır.',array['İdeya (əsas fikir)','Başlıq','Abzas','Sitat'],1),
('az8-metn-uslub#2','az-dili','az-8-metn-uslub',2,4,'Mətn hansı hissələrdən qurulur?','Giriş, əsas hissə və nəticədən.',array['Giriş, əsas hissə, nəticə','Yalnız girişdən','Yalnız nəticədən','Sözlükdən'],1),
('az8-metn-uslub#3','az-dili','az-8-metn-uslub',2,4,'Mətn üzərində plan tərtib etmək nəyə kömək edir?','Fikirləri ardıcıl qurmağa.',array['Fikirləri ardıcıl qurmağa','Mətni qısaltmağa','Sözləri saymağa','Heç nəyə'],1),
('az8-metn-uslub#4','az-dili','az-8-metn-uslub',3,4,'Esse hansı yazı növüdür?','Mövzu ətrafında sərbəst düşüncə yazısıdır.',array['Sərbəst düşüncə yazısı','Rəsmi sənəd','Elmi hesabat','Lüğət'],1),
('az8-metn-uslub#5','az-dili','az-8-metn-uslub',2,4,'Elektron rəsmi məktubda müraciət necə olmalıdır?','Nəzakətli və rəsmi olmalıdır.',array['Nəzakətli və rəsmi','Zarafatyana','Qısaltmalarla dolu','Müraciətsiz'],1),
('az8-metn-uslub#6','az-dili','az-8-metn-uslub',3,4,'Təsviri mətndə nə verilir?','Əşya və hadisənin əlamətlərinin təsviri.',array['Əşya və hadisənin təsviri','Yalnız dialoq','Yalnız rəqəmlər','Cədvəllər'],1),
('az8-metn-uslub#7','az-dili','az-8-metn-uslub',3,4,'Nəqli mətn nəyi əks etdirir?','Hadisələrin ardıcıllığını.',array['Hadisələrin ardıcıllığını','Yalnız təsviri','Yalnız mübahisəni','Düsturları'],1),
('az8-metn-uslub#8','az-dili','az-8-metn-uslub',3,4,'Mühakimə tipli mətndə nə olur?','Fikir irəli sürülür və əsaslandırılır.',array['Fikir və onun əsaslandırılması','Yalnız təsvir','Yalnız hadisə','Yalnız sitatlar'],1),
('az8-metn-uslub#9','az-dili','az-8-metn-uslub',2,4,'Konspekt nədir?','Mətnin əsas məzmununun qısa yazılışıdır.',array['Mətnin qısa yazılışı','Mətnin tam köçürülməsi','Şəkilli albom','Sözlərin siyahısı'],1),
('az8-metn-uslub#10','az-dili','az-8-metn-uslub',3,4,'Annotasiya nəyi bildirir?','Əsərin qısa məzmununu və təyinatını.',array['Əsərin qısa məzmununu','Müəllifin ünvanını','Kitabın qiymətini','Səhifə sayını'],1),
('ing8-holidays#1','ingilis-dili','ing-8-holidays',3,1,'«I have been to London.» cümləsi nəyi bildirir?','Londonda olmaq təcrübəsini bildirir.',array['Londonda olma təcrübəsini','Gələcək planı','Əmri','Peşmançılığı'],1),
('ing8-holidays#2','ingilis-dili','ing-8-holidays',2,1,'«Campsite» nə deməkdir?','Campsite — düşərgə yeri.',array['Düşərgə yeri','Hava limanı','Muzey','Bazar'],1),
('ing8-holidays#3','ingilis-dili','ing-8-holidays',2,1,'«Seaside» nə deməkdir?','Seaside — dəniz kənarı.',array['Dəniz kənarı','Dağ zirvəsi','Meşəlik','Şəhər mərkəzi'],1),
('ing8-holidays#4','ingilis-dili','ing-8-holidays',2,1,'«We stayed at a hotel.» — «stayed» hansı zamandadır?','-ed forması Past Simple-dır.',array['Past Simple','Present Perfect','Gələcək','Past Continuous'],1),
('ing8-holidays#5','ingilis-dili','ing-8-holidays',1,1,'«Excursion» sözünün mənası nədir?','Excursion — ekskursiya.',array['Ekskursiya','Yemək','Sənəd','Hədiyyə'],1),
('ing8-holidays#6','ingilis-dili','ing-8-holidays',2,1,'«Travel agency» nə üçündür?','Səyahətləri təşkil etmək üçün.',array['Səyahət təşkil etmək üçün','Paltar satmaq üçün','Kitab çap etmək üçün','Ev tikmək üçün'],1),
('ing8-holidays#7','ingilis-dili','ing-8-holidays',2,1,'«Journey, trip, voyage» sözlərini nə birləşdirir?','Üçü də səyahət mənasındadır.',array['Hamısı səyahət bildirir','Hamısı yemək bildirir','Hamısı idmandır','Ümumi cəhət yoxdur'],1),
('ing8-holidays#8','ingilis-dili','ing-8-holidays',2,1,'«Did you have a good time?» sualı nəyi soruşur?','Vaxtın yaxşı keçib-keçmədiyini.',array['Vaxtın necə keçdiyini','Saatın neçə olduğunu','Biletin qiymətini','Ünvanı'],1),
('ing8-holidays#9','ingilis-dili','ing-8-holidays',2,1,'«Souvenir shop» adətən harada yerləşir?','Turistlərin çox olduğu yerlərdə.',array['Turistik yerlərdə','Zavodlarda','Fermalarda','Xəstəxanalarda'],1),
('ing8-holidays#10','ingilis-dili','ing-8-holidays',3,1,'«Sunbathe» feili nə deməkdir?','Günəş vannası qəbul etmək.',array['Günəş vannası qəbul etmək','Üzmək','Qaçmaq','Yatmaq'],1),
('ing8-inventions#1','ingilis-dili','ing-8-inventions',1,1,'«Inventor» kimdir?','Inventor — ixtiraçı.',array['İxtiraçı','Müğənni','Sürücü','Satıcı'],1),
('ing8-inventions#2','ingilis-dili','ing-8-inventions',2,1,'«Device» sözünün mənası nədir?','Device — cihaz, qurğu.',array['Cihaz','İçki','Geyim','Bina'],1),
('ing8-inventions#3','ingilis-dili','ing-8-inventions',3,1,'«The telephone was invented by Bell.» cümləsi hansı formadadır?','Was + III forma — məchul növdür (Passive).',array['Məchul növ (Passive)','Əmr forması','Sual forması','Gələcək zaman'],1),
('ing8-inventions#4','ingilis-dili','ing-8-inventions',2,1,'«Create» feilinin mənası nədir?','Create — yaratmaq.',array['Yaratmaq','Dağıtmaq','İtirmək','Gizlətmək'],1),
('ing8-inventions#5','ingilis-dili','ing-8-inventions',2,1,'«Experiment» nə deməkdir?','Experiment — təcrübə, sınaq.',array['Təcrübə','Bayram','Mahnı','Rəsm'],1),
('ing8-inventions#6','ingilis-dili','ing-8-inventions',2,1,'«Young inventors» ifadəsi kimləri bildirir?','Gənc ixtiraçıları.',array['Gənc ixtiraçıları','Qoca müəllimləri','Peşəkar idmançıları','Aktyorları'],1),
('ing8-inventions#7','ingilis-dili','ing-8-inventions',3,1,'«Patent» nə üçün alınır?','İxtiranı hüquqi qorumaq üçün.',array['İxtiranı qorumaq üçün','Ev almaq üçün','Səyahət üçün','Yemək üçün'],1),
('ing8-inventions#8','ingilis-dili','ing-8-inventions',2,1,'«Improve» feili nə deməkdir?','Improve — yaxşılaşdırmaq, təkmilləşdirmək.',array['Təkmilləşdirmək','Korlamaq','Satmaq','Saymaq'],1),
('ing8-inventions#9','ingilis-dili','ing-8-inventions',3,1,'«Science fair» nədir?','Elmi layihələrin sərgi-yarışması.',array['Elm sərgisi (yarışması)','İdman meydançası','Musiqi festivalı','Kitab mağazası'],1),
('ing8-inventions#10','ingilis-dili','ing-8-inventions',2,1,'«How does it work?» sualı nəyi soruşur?','Qurğunun necə işlədiyini.',array['Necə işlədiyini','Neçəyə satıldığını','Harada olduğunu','Kimin aldığını'],1),
('ing8-hobbies#1','ingilis-dili','ing-8-hobbies',2,2,'«Photography» hansı məşğuliyyətdir?','Photography — fotoçəkmə.',array['Fotoçəkmə','Balıq tutma','Qaçış','Yemək bişirmə'],1),
('ing8-hobbies#2','ingilis-dili','ing-8-hobbies',3,2,'«Origami» sənəti haradan yaranıb?','Kağız qatlama sənəti Yaponiyadan yaranıb.',array['Yaponiyadan','Braziliyadan','Kanadadan','Misirdən'],1),
('ing8-hobbies#3','ingilis-dili','ing-8-hobbies',2,2,'«Knitting» nə deməkdir?','Knitting — toxuculuq (hörmə).',array['Toxuculuq (hörmə)','Rəqs','Üzgüçülük','Rəsm'],1),
('ing8-hobbies#4','ingilis-dili','ing-8-hobbies',3,2,'«I am keen on music.» ifadəsi nəyi bildirir?','Musiqiyə böyük həvəsi bildirir.',array['Musiqiyə həvəsi','Musiqiyə nifrəti','Musiqi alətini','Konsert biletini'],1),
('ing8-hobbies#5','ingilis-dili','ing-8-hobbies',2,2,'«Board games» hansı oyunlardır?','Masaüstü oyunlardır: şahmat, dama.',array['Masaüstü oyunlar','Su oyunları','İdman oyunları','Kompüter oyunları'],1),
('ing8-hobbies#6','ingilis-dili','ing-8-hobbies',2,2,'«Gardening» məşğuliyyəti nədir?','Gardening — bağçılıq.',array['Bağçılıq','Ovçuluq','Dənizçilik','Aşpazlıq'],1),
('ing8-hobbies#7','ingilis-dili','ing-8-hobbies',3,2,'«Take up a hobby» ifadəsi nə deməkdir?','Yeni məşğuliyyətə başlamaq.',array['Yeni məşğuliyyətə başlamaq','Məşğuliyyəti atmaq','Hobbini satmaq','İstirahət etmək'],1),
('ing8-hobbies#8','ingilis-dili','ing-8-hobbies',3,2,'«Be interested in» ifadəsindən sonra feil hansı formada işlənir?','-ing formasında: interested in reading.',array['-ing formasında','-ed formasında','will ilə','Əsas formada'],1),
('ing8-hobbies#9','ingilis-dili','ing-8-hobbies',3,2,'«Pottery» nə deməkdir?','Pottery — dulusçuluq.',array['Dulusçuluq','Şirniyyat','Xəttatlıq','Bağça'],1),
('ing8-hobbies#10','ingilis-dili','ing-8-hobbies',2,2,'«Hobbies around the world» ifadəsi nə deməkdir?','Dünyadakı (müxtəlif ölkələrdəki) hobbilər.',array['Dünya üzrə hobbilər','Bir kəndin işləri','Dərs cədvəli','İdman qaydaları'],1),
('ing8-present-perfect#1','ingilis-dili','ing-8-present-perfect',3,2,'Present Perfect necə düzəlir?','have/has + feilin III forması.',array['have/has + feilin III forması','will + feil','am/is + feil-ing','did + feil'],1),
('ing8-present-perfect#2','ingilis-dili','ing-8-present-perfect',2,2,'«She has ___ her homework.» (do feilinin III forması)','Do feilinin III forması: done.',array['done','did','doing','does'],1),
('ing8-present-perfect#3','ingilis-dili','ing-8-present-perfect',3,2,'«I have just seen him.» — «just» nə bildirir?','Hərəkətin indicə baş verdiyini.',array['İndicə baş verməyi','Çoxdan olmağı','Heç olmamağı','Gələcəyi'],1),
('ing8-present-perfect#4','ingilis-dili','ing-8-present-perfect',3,2,'«Ever» sözü Present Perfect-də əsasən harada işlənir?','Təcrübə soruşan sual cümlələrində.',array['Sual cümlələrində','Yalnız inkar cümlədə','Yalnız əmrdə','İşlənmir'],1),
('ing8-present-perfect#5','ingilis-dili','ing-8-present-perfect',3,2,'«They have lived here ___ 2010.» boşluğu doldurun.','Başlanğıc nöqtə ilə: since 2010.',array['since','for','ago','yet'],1),
('ing8-present-perfect#6','ingilis-dili','ing-8-present-perfect',3,2,'«For» və «since» sözlərinin fərqi nədir?','For müddəti, since başlanğıc anı bildirir.',array['For müddət, since başlanğıc','Eyni mənadadırlar','For yalnız keçmişdə','Since müddət bildirir'],1),
('ing8-present-perfect#7','ingilis-dili','ing-8-present-perfect',2,2,'«Go» feilinin III forması hansıdır?','Go — went — gone.',array['gone','went','goed','going'],1),
('ing8-present-perfect#8','ingilis-dili','ing-8-present-perfect',2,2,'«Have you finished? — Yes, I ___.»','Qısa cavab: Yes, I have.',array['have','did','am','will'],1),
('ing8-present-perfect#9','ingilis-dili','ing-8-present-perfect',2,2,'«Never» Present Perfect-də nəyi bildirir?','Təcrübənin heç vaxt olmadığını.',array['Heç vaxt etməməyi','Tez-tez etməyi','İndicə etməyi','Sabah edəcəyini'],1),
('ing8-present-perfect#10','ingilis-dili','ing-8-present-perfect',2,2,'«He has already left.» — «already» nə deməkdir?','Already — artıq.',array['Artıq','Hələ','Heç vaxt','Bəzən'],1),
('ing8-media#1','ingilis-dili','ing-8-media',1,3,'«Newspaper» nə deməkdir?','Newspaper — qəzet.',array['Qəzet','Jurnal','Kitab','Məktub'],1),
('ing8-media#2','ingilis-dili','ing-8-media',1,3,'«News» sözünün mənası nədir?','News — xəbərlər.',array['Xəbərlər','Mahnılar','Oyunlar','Şəkillər'],1),
('ing8-media#3','ingilis-dili','ing-8-media',2,3,'«Channel» televiziyada nəyi bildirir?','Channel — televiziya kanalı.',array['Kanalı','Ekranı','Pultu','Antenanı'],1),
('ing8-media#4','ingilis-dili','ing-8-media',2,3,'«Advertisement» nə deməkdir?','Advertisement — reklam.',array['Reklam','Xəbər','Hava proqnozu','Film'],1),
('ing8-media#5','ingilis-dili','ing-8-media',2,3,'«Headline» qəzetdə nədir?','Headline — məqalənin başlığı.',array['Başlıq','Səhifə nömrəsi','Şəkil','Qiymət'],1),
('ing8-media#6','ingilis-dili','ing-8-media',2,3,'«Journalist» nə ilə məşğuldur?','Xəbər və məqalələr hazırlayır.',array['Xəbər hazırlayır','Xəstə müalicə edir','Ev tikir','Yemək bişirir'],1),
('ing8-media#7','ingilis-dili','ing-8-media',3,3,'«Broadcast» feili nə deməkdir?','Broadcast — efirə vermək, yayımlamaq.',array['Yayımlamaq','Gizlətmək','Satmaq','Oxumaq'],1),
('ing8-media#8','ingilis-dili','ing-8-media',2,3,'«Social media» nə deməkdir?','Sosial şəbəkələr (media).',array['Sosial şəbəkələr','Dövlət qəzetləri','Kitabxanalar','Radio dalğaları'],1),
('ing8-media#9','ingilis-dili','ing-8-media',2,3,'«Interview» nədir?','Interview — müsahibə.',array['Müsahibə','Elan','Krossvord','Reseptlər'],1),
('ing8-media#10','ingilis-dili','ing-8-media',3,3,'«Mass media» ifadəsi nəyi əhatə edir?','Kütləvi informasiya vasitələrini: TV, radio, mətbuat.',array['Kütləvi informasiya vasitələrini','Yalnız kitabları','Yalnız telefonları','Məktəbləri'],1),
('ing8-environment#1','ingilis-dili','ing-8-environment',2,4,'«Pollution» nə deməkdir?','Pollution — çirklənmə.',array['Çirklənmə','Təmizlik','Yağış','Bitki'],1),
('ing8-environment#2','ingilis-dili','ing-8-environment',2,4,'«Recycle» feilinin mənası nədir?','Recycle — təkrar emal etmək.',array['Təkrar emal etmək','Atmaq','Yandırmaq','Almaq'],1),
('ing8-environment#3','ingilis-dili','ing-8-environment',2,4,'«Save energy» ifadəsi nəyə çağırır?','Enerjiyə qənaət etməyə.',array['Enerjiyə qənaətə','Enerjini israf etməyə','İşıqları yandırmağa','Su tökməyə'],1),
('ing8-environment#4','ingilis-dili','ing-8-environment',3,4,'«Endangered animals» hansı heyvanlardır?','Nəsli kəsilmək təhlükəsində olanlar.',array['Nəsli kəsilmək təhlükəsində olanlar','Ev heyvanları','Ən sürətli heyvanlar','Ən böyük heyvanlar'],1),
('ing8-environment#5','ingilis-dili','ing-8-environment',1,4,'«Plant trees» nə deməkdir?','Ağac əkmək.',array['Ağac əkmək','Ağac kəsmək','Meyvə yığmaq','Bağ satmaq'],1),
('ing8-environment#6','ingilis-dili','ing-8-environment',2,4,'«Global warming» nədir?','Qlobal istiləşmə — planetin orta temperaturunun artması.',array['Qlobal istiləşmə','Qlobal soyuma','Yerli yağışlar','Küləklər'],1),
('ing8-environment#7','ingilis-dili','ing-8-environment',2,4,'«Litter» sözü nəyi bildirir?','Litter — zibil.',array['Zibili','Suyu','İşığı','Torpağı'],1),
('ing8-environment#8','ingilis-dili','ing-8-environment',2,4,'«Protect wildlife» ifadəsi nə deməkdir?','Vəhşi təbiəti qorumaq.',array['Vəhşi təbiəti qorumaq','Heyvanları ovlamaq','Meşə yandırmaq','Zibil atmaq'],1),
('ing8-environment#9','ingilis-dili','ing-8-environment',3,4,'«Reduce, reuse, recycle» şüarı nəyə aiddir?','Tullantıların azaldılmasına və emalına.',array['Tullantıların azaldılmasına','İdman qaydalarına','Yemək reseptlərinə','Dərs cədvəlinə'],1),
('ing8-environment#10','ingilis-dili','ing-8-environment',3,4,'«Eco-friendly» sözünün mənası nədir?','Ətraf mühitə zərər verməyən.',array['Ətraf mühitə zərərsiz','Çox bahalı','Çox sürətli','Köhnəlmiş'],1),
('inf8-informasiya#1','informatika','inf-8-informasiya',3,1,'1 qiqabayt neçə meqabaytdır?','1 GB = 1024 MB.',array['1024','100','10','8'],1),
('inf8-informasiya#2','informatika','inf-8-informasiya',2,1,'İnformasiya prosesləri hansılardır?','Toplanma, saxlanma, emal və ötürülmə.',array['Toplanma, saxlanma, emal, ötürülmə','Yalnız çap','Yalnız oyun','Yalnız silmə'],1),
('inf8-informasiya#3','informatika','inf-8-informasiya',3,1,'Onaltılıq say sistemində neçə simvoldan istifadə olunur?','16 simvol: 0-9 rəqəmləri və A-F hərfləri.',array['16','10','2','8'],1),
('inf8-informasiya#4','informatika','inf-8-informasiya',3,1,'İkilik «100» ədədi onluq sistemdə neçədir?','1·4 + 0·2 + 0·1 = 4.',array['4','100','3','8'],1),
('inf8-informasiya#5','informatika','inf-8-informasiya',3,1,'Unicode kodlaşdırması nə üçündür?','Bütün dillərin simvollarını vahid kodlaşdırmaq üçün.',array['Bütün dillərin simvollarını kodlaşdırmaq üçün','Yalnız rəqəmlər üçün','Şəkil çəkmək üçün','Səs yazmaq üçün'],1),
('inf8-informasiya#6','informatika','inf-8-informasiya',3,1,'1 bayt ilə neçə müxtəlif simvol kodlaşdırmaq olar?','2⁸ = 256 müxtəlif kod.',array['256','8','16','1024'],1),
('inf8-informasiya#7','informatika','inf-8-informasiya',2,1,'Kompüterdə bütün informasiya hansı formada saxlanır?','İkilik kod (0 və 1) şəklində.',array['İkilik kodda','Hərflərlə','Şəkillərlə','Səslə'],1),
('inf8-informasiya#8','informatika','inf-8-informasiya',3,1,'Onaltılıq sistemdə 9-dan böyük qiymətlər hansı simvollarla göstərilir?','A-dan F-yə qədər hərflərlə.',array['A-F hərfləri ilə','Ulduzlarla','Nöqtələrlə','Göstərilmir'],1),
('inf8-informasiya#9','informatika','inf-8-informasiya',3,1,'İnformasiyanın emalı nədir?','Mövcud məlumat əsasında yeni məlumatın alınması.',array['Mövcud məlumatdan yenisinin alınması','Məlumatın silinməsi','Kompüterin təmiri','Kabellərin dəyişilməsi'],1),
('inf8-informasiya#10','informatika','inf-8-informasiya',3,1,'Verilənlər bazası nə üçün istifadə olunur?','Böyük həcmli məlumatı nizamlı saxlamaq üçün.',array['Məlumatı nizamlı saxlamaq üçün','Oyun oynamaq üçün','Şəkil çəkmək üçün','Musiqi bəstələmək üçün'],1),
('inf8-multimedia#1','informatika','inf-8-multimedia',2,1,'Multimedia nədir?','Mətn, səs, qrafika və videonun birləşməsidir.',array['Mətn, səs, qrafika və videonun birləşməsi','Yalnız mətn','Yalnız səs','Yalnız kağız'],1),
('inf8-multimedia#2','informatika','inf-8-multimedia',2,1,'Hansı format səs faylı formatıdır?','MP3 — səs faylı formatıdır.',array['MP3','PNG','TXT','EXE'],1),
('inf8-multimedia#3','informatika','inf-8-multimedia',3,1,'Video informasiya nədən ibarətdir?','Ardıcıl kadrlardan və səs cığırından.',array['Kadrlardan və səsdən','Yalnız mətndən','Yalnız cədvəldən','Düsturlardan'],1),
('inf8-multimedia#4','informatika','inf-8-multimedia',2,1,'Hansı format qrafik (şəkil) faylı formatıdır?','PNG — şəkil formatıdır.',array['PNG','MP3','WAV','DOC'],1),
('inf8-multimedia#5','informatika','inf-8-multimedia',3,1,'Animasiya necə yaranır?','Şəkillərin sürətlə ardıcıl göstərilməsi ilə.',array['Şəkillərin sürətli ardıcıl göstərilməsi','Bir şəklin çapı ilə','Mətnin oxunması ilə','Səsin yüksəldilməsi ilə'],1),
('inf8-multimedia#6','informatika','inf-8-multimedia',2,1,'Səs redaktoru nə üçündür?','Səsi yazmaq və emal etmək üçün.',array['Səsi yazıb emal etmək üçün','Şəkil kəsmək üçün','Mətn yazmaq üçün','Cədvəl qurmaq üçün'],1),
('inf8-multimedia#7','informatika','inf-8-multimedia',2,1,'Video emal edən proqramlar necə adlanır?','Video redaktorlar adlanır.',array['Video redaktorlar','Kalkulyatorlar','Brauzerlər','Antiviruslar'],1),
('inf8-multimedia#8','informatika','inf-8-multimedia',2,1,'Təqdimata hansı multimedia elementlərini əlavə etmək olar?','Səs, video və animasiya əlavə etmək olar.',array['Səs, video, animasiya','Yalnız mətn','Heç nə','Yalnız cədvəl'],1),
('inf8-multimedia#9','informatika','inf-8-multimedia',3,1,'Təsvirin piksel sayı (ölçüsü) nəyə təsir edir?','Təsvirin keyfiyyətinə və detallılığına.',array['Təsvirin keyfiyyətinə','Kompüterin rənginə','Səsin ucalığına','Klaviaturaya'],1),
('inf8-multimedia#10','informatika','inf-8-multimedia',3,1,'Kadr tezliyi (FPS) nəyi göstərir?','Saniyədə göstərilən kadrların sayını.',array['Saniyədəki kadr sayını','Faylın adını','Ekranın ölçüsünü','Rənglərin sayını'],1),
('inf8-proqramlasdirma#1','informatika','inf-8-proqramlasdirma',2,2,'Proqramlaşdırma dilinə misal hansıdır?','Python geniş yayılmış proqramlaşdırma dilidir.',array['Python','Windows','Google','Wi-Fi'],1),
('inf8-proqramlasdirma#2','informatika','inf-8-proqramlasdirma',3,2,'x = x + 1 yazılışı nə edir?','Dəyişənin qiymətini 1 vahid artırır.',array['Dəyişəni 1 vahid artırır','Dəyişəni silir','Tənliyi həll edir','Səhvdir, mümkün deyil'],1),
('inf8-proqramlasdirma#3','informatika','inf-8-proqramlasdirma',2,2,'Şərt operatoru hansı açar sözlərlə yazılır?','if / else (əgər / əks halda).',array['if / else','print / input','for / to','start / stop'],1),
('inf8-proqramlasdirma#4','informatika','inf-8-proqramlasdirma',3,2,'«while» dövrü nə vaxta qədər icra olunur?','Şərt doğru olduqca təkrarlanır.',array['Şərt doğru olduqca','Bir dəfə','Heç vaxt','Kompüter söndürülənədək'],1),
('inf8-proqramlasdirma#5','informatika','inf-8-proqramlasdirma',3,2,'Proqramda mətn tipli verilən necə adlanır?','Mətn tipi sətir (string) adlanır.',array['Sətir (string)','Tam ədəd','Məntiqi tip','Massiv'],1),
('inf8-proqramlasdirma#6','informatika','inf-8-proqramlasdirma',3,2,'Tam ədədləri saxlayan verilən tipi necə adlanır?','Tam tip (integer).',array['Tam tip (integer)','Sətir','Kəsr tip','Simvol'],1),
('inf8-proqramlasdirma#7','informatika','inf-8-proqramlasdirma',2,2,'Python-da nəticəni ekrana çıxaran əmr hansıdır?','print əmri nəticəni çap edir.',array['print','scan','get','write'],1),
('inf8-proqramlasdirma#8','informatika','inf-8-proqramlasdirma',3,2,'Sintaksis xətası nədir?','Proqramlaşdırma dilinin yazılış qaydalarının pozulması.',array['Dil qaydalarının pozulması','Kompüterin xarab olması','Elektrik kəsilməsi','Düzgün nəticə'],1),
('inf8-proqramlasdirma#9','informatika','inf-8-proqramlasdirma',3,2,'Məntiqi tip hansı qiymətləri alır?','True (doğru) və False (yalan).',array['True və False','0-dan 100-ə qədər','Yalnız mətn','Rənglər'],1),
('inf8-proqramlasdirma#10','informatika','inf-8-proqramlasdirma',2,2,'Proqramda şərh (komment) nə üçündür?','Kodu izah edir, icra olunmur.',array['Kodu izah etmək üçün','Proqramı sürətləndirmək üçün','Xətaları silmək üçün','Yaddaşı artırmaq üçün'],1),
('inf8-kompyuter#1','informatika','inf-8-kompyuter',3,2,'Ana plata (motherboard) nə üçündür?','Bütün qurğuları birləşdirir.',array['Qurğuları birləşdirmək üçün','Səs yazmaq üçün','Şəkil çəkmək üçün','Sənəd çap etmək üçün'],1),
('inf8-kompyuter#2','informatika','inf-8-kompyuter',3,2,'Videokart nəyə cavabdehdir?','Ekrandakı təsvirin formalaşdırılmasına.',array['Təsvirin formalaşdırılmasına','Səsin yazılmasına','Mətnin yoxlanmasına','İnternet sürətinə'],1),
('inf8-kompyuter#3','informatika','inf-8-kompyuter',3,2,'SSD yaddaşın HDD-dən üstünlüyü nədir?','Daha sürətlidir, hərəkətli hissəsi yoxdur.',array['Daha sürətlidir','Daha ağırdır','Daha səslidir','Fərq yoxdur'],1),
('inf8-kompyuter#4','informatika','inf-8-kompyuter',3,2,'Əməli yaddaşın (RAM) həcmi nəyə təsir edir?','Eyni anda işləyən proqramların sürətinə.',array['Proqramların işləmə sürətinə','Ekranın rənginə','Klaviaturanın dilinə','Korpusun ölçüsünə'],1),
('inf8-kompyuter#5','informatika','inf-8-kompyuter',3,2,'Periferiya qurğuları hansılardır?','Sistem blokuna xaricdən qoşulan qurğular.',array['Xaricdən qoşulan qurğular','Yalnız prosessor','Yalnız yaddaş','Proqramlar'],1),
('inf8-kompyuter#6','informatika','inf-8-kompyuter',3,2,'Drayver nədir?','Qurğunu idarə edən xüsusi proqramdır.',array['Qurğunu idarə edən proqram','Kompüter sürücüsü','Oyun növü','Kabel adı'],1),
('inf8-kompyuter#7','informatika','inf-8-kompyuter',3,2,'BIOS nə vaxt işə düşür?','Kompüter qoşulan kimi ilk işə düşən proqramdır.',array['Kompüter qoşulan kimi','Yalnız gecə','İnternet açılanda','Heç vaxt'],1),
('inf8-kompyuter#8','informatika','inf-8-kompyuter',2,2,'Kompüterin soyutma sistemi nə üçündür?','Qurğuları həddindən artıq qızmadan qorumaq üçün.',array['Qızmadan qorumaq üçün','Səsi artırmaq üçün','Yaddaşı silmək üçün','Bəzək üçün'],1),
('inf8-kompyuter#9','informatika','inf-8-kompyuter',2,2,'Noutbukun mobil enerji mənbəyi nədir?','Akkumulyator (batareya).',array['Akkumulyator','Günəş paneli','Külək','Buxar'],1),
('inf8-kompyuter#10','informatika','inf-8-kompyuter',2,2,'USB portu nə üçün istifadə olunur?','Xarici qurğuları qoşmaq üçün.',array['Xarici qurğuları qoşmaq üçün','Havanı dəyişmək üçün','Səsi yazmaq üçün','Ekranı işıqlandırmaq üçün'],1),
('inf8-tetbiqi#1','informatika','inf-8-tetbiqi',2,3,'Elektron cədvəl proqramına misal hansıdır?','Excel elektron cədvəl proqramıdır.',array['Excel','Paint','Notepad','Chrome'],1),
('inf8-tetbiqi#2','informatika','inf-8-tetbiqi',2,3,'Elektron cədvəldə xananın ünvanı necə yazılır?','Sütun hərfi və sətir nömrəsi ilə: A1.',array['Sütun hərfi + sətir nömrəsi (A1)','Yalnız rəqəmlə','Yalnız hərflə','Ünvanı olmur'],1),
('inf8-tetbiqi#3','informatika','inf-8-tetbiqi',2,3,'Elektron cədvəldə düstur hansı işarə ilə başlayır?','Düsturlar = işarəsi ilə başlayır.',array['=','+','%','#'],1),
('inf8-tetbiqi#4','informatika','inf-8-tetbiqi',2,3,'=A1+B1 düsturu nə edir?','A1 və B1 xanalarının cəmini hesablayır.',array['İki xananın cəmini hesablayır','Xanaları silir','Şrift dəyişir','Sətir əlavə edir'],1),
('inf8-tetbiqi#5','informatika','inf-8-tetbiqi',2,3,'SUM funksiyası nə üçündür?','Diapazonun cəmini hesablamaq üçün.',array['Cəmi hesablamaq üçün','Rəngləmək üçün','Silmək üçün','Çap etmək üçün'],1),
('inf8-tetbiqi#6','informatika','inf-8-tetbiqi',2,3,'Cədvəl məlumatları əsasında nə qurmaq olar?','Diaqram qurmaq olar.',array['Diaqram','Ev','Oyun','Mahnı'],1),
('inf8-tetbiqi#7','informatika','inf-8-tetbiqi',3,3,'Elektron cədvəli mətn prosessorundan fərqləndirən nədir?','Cədvəl avtomatik hesablamalar aparır.',array['Avtomatik hesablamalar','Yalnız mətn yazması','Şəkil çəkməsi','Fərq yoxdur'],1),
('inf8-tetbiqi#8','informatika','inf-8-tetbiqi',3,3,'Düsturda istifadə olunan xananın qiyməti dəyişəndə nəticə necə olur?','Nəticə avtomatik yenilənir.',array['Avtomatik yenilənir','Dəyişmir','Silinir','Xəta verir'],1),
('inf8-tetbiqi#9','informatika','inf-8-tetbiqi',2,3,'Verilənləri sıralamaq (sort) nə deməkdir?','Artan və ya azalan qaydada düzmək.',array['Artan/azalan qaydada düzmək','Silmək','Rəngləmək','Çap etmək'],1),
('inf8-tetbiqi#10','informatika','inf-8-tetbiqi',3,3,'Vektor qrafikası nədir?','Həndəsi obyektlərlə (xətt, əyri) qurulan təsvirdir.',array['Həndəsi obyektlərlə qurulan təsvir','Yalnız fotoşəkil','Mətn sənədi','Səs faylı'],1),
('inf8-internet#1','informatika','inf-8-internet',3,4,'İnformasiya cəmiyyəti nədir?','İnformasiyanın əsas resurs olduğu cəmiyyətdir.',array['İnformasiyanın əsas resurs olduğu cəmiyyət','Yalnız kitabxanalar','Kompüter mağazası','İnternet kafe'],1),
('inf8-internet#2','informatika','inf-8-internet',3,4,'Bulud texnologiyası nəyə imkan verir?','Məlumatı internet serverlərində saxlamağa.',array['Məlumatı internetdə saxlamağa','Yağış yağdırmağa','Kompüteri soyutmağa','Ekranı böyütməyə'],1),
('inf8-internet#3','informatika','inf-8-internet',3,4,'Elektron hökumət xidmətləri nəyə misaldır?','Onlayn dövlət xidmətlərinə.',array['Onlayn dövlət xidmətlərinə','Kompüter oyununa','Video redaktoruna','Qrafik redaktora'],1),
('inf8-internet#4','informatika','inf-8-internet',2,4,'Kiberbullinq nədir?','İnternetdə təhqir, təzyiq və qorxutmadır.',array['İnternetdə təhqir və təzyiq','İdman növü','Proqram adı','Kompüter hissəsi'],1),
('inf8-internet#5','informatika','inf-8-internet',2,4,'Güclü parol necə olmalıdır?','Uzun, hərf-rəqəm-simvol qarışığı.',array['Uzun və qarışıq simvollu','Ad və soyaddan ibarət','12345 kimi sadə','Doğum tarixi'],1),
('inf8-internet#6','informatika','inf-8-internet',3,4,'İkifaktorlu autentifikasiya nə üçündür?','Hesabın təhlükəsizliyini artırmaq üçün.',array['Hesabın təhlükəsizliyi üçün','Sürəti artırmaq üçün','Reklam üçün','Yaddaş üçün'],1),
('inf8-internet#7','informatika','inf-8-internet',3,4,'Fişinq nədir?','Saxta saytlarla şəxsi məlumatların oğurlanması.',array['Saxta saytlarla məlumat oğurluğu','Balıq ovu idmanı','Fayl formatı','Şəbəkə kabeli'],1),
('inf8-internet#8','informatika','inf-8-internet',2,4,'Antivirus proqramı nə edir?','Zərərli proqramları aşkarlayıb zərərsizləşdirir.',array['Zərərli proqramları aşkarlayır','Şəkil çəkir','Mahnı çalır','Sənəd yazır'],1),
('inf8-internet#9','informatika','inf-8-internet',3,4,'Şəxsi məlumatların qorunması necə adlanır?','Məxfilik (konfidensiallıq).',array['Məxfilik','Reklam','Yayım','Abunəlik'],1),
('inf8-internet#10','informatika','inf-8-internet',3,4,'Rəqəmsal iz nədir?','İstifadəçinin internetdə qalan fəaliyyət izləridir.',array['İnternetdə qalan fəaliyyət izləri','Ayaq izi','Printer izi','Kağız sənəd'],1),
('tarix8-xvi-xvii#1','tarix','tarix-8-xvi-xvii',2,1,'XVI əsrdə Azərbaycan torpaqları əsasən hansı dövlətin tərkibində idi?','Azərbaycan Səfəvi dövlətinin tərkibində idi.',array['Səfəvilər','Roma','Monqol imperiyası','Fransa'],1),
('tarix8-xvi-xvii#2','tarix','tarix-8-xvi-xvii',3,1,'I Təhmasib dövründə Səfəvi paytaxtı haraya köçürüldü?','Paytaxt Təbrizdən Qəzvinə köçürüldü.',array['Qəzvinə','Bakıya','İstanbula','Bağdada'],1),
('tarix8-xvi-xvii#3','tarix','tarix-8-xvi-xvii',3,1,'Şah I Abbasın apardığı əsas islahat hansı idi?','Nizami ordu yaratdı (ordu islahatı).',array['Ordu islahatı','Əlifba islahatı','Təqvim islahatı','Heç bir islahat'],1),
('tarix8-xvi-xvii#4','tarix','tarix-8-xvi-xvii',3,1,'Osmanlı-Səfəvi müharibələrinin əsas səbəbi nə idi?','Ərazi və ticarət yolları uğrunda mübarizə.',array['Ərazi uğrunda mübarizə','İdman yarışı','Elm mübahisəsi','Səbəbsiz'],1),
('tarix8-xvi-xvii#5','tarix','tarix-8-xvi-xvii',3,1,'1555-ci il Amasiya sülhü hansı dövlətlər arasında bağlandı?','Səfəvilərlə Osmanlı arasında.',array['Səfəvilərlə Osmanlı','Rusiya ilə Fransa','İngiltərə ilə İspaniya','Çinlə Yaponiya'],1),
('tarix8-xvi-xvii#6','tarix','tarix-8-xvi-xvii',3,1,'Səfəvi ordusunun əsasını əvvəllər hansı tayfalar təşkil edirdi?','Qızılbaş tayfaları təşkil edirdi.',array['Qızılbaş tayfaları','Vikinqlər','Səlibçilər','Kazaklar'],1),
('tarix8-xvi-xvii#7','tarix','tarix-8-xvi-xvii',3,1,'XVII əsrdə Azərbaycanda hansı təsərrüfat sahəsi xüsusilə gəlirli idi?','İpəkçilik mühüm gəlir mənbəyi idi.',array['İpəkçilik','Kosmik sənaye','Avtomobilqayırma','Neft emalı'],1),
('tarix8-xvi-xvii#8','tarix','tarix-8-xvi-xvii',3,1,'Şah I Abbas paytaxtı hansı şəhərə köçürdü?','Paytaxt İsfahana köçürüldü.',array['İsfahana','Gəncəyə','Şamaxıya','Qahirəyə'],1),
('tarix8-xvi-xvii#9','tarix','tarix-8-xvi-xvii',2,1,'XVII əsrdə Azərbaycan şəhərlərində hansı sənət növü şöhrət qazanmışdı?','Xalçaçılıq dünyada məşhur idi.',array['Xalçaçılıq','Saatsazlıq','Gəmiqayırma','Çap maşınları'],1),
('tarix8-xvi-xvii#10','tarix','tarix-8-xvi-xvii',1,1,'Səfəvi dövlətini kim idarə edirdi?','Dövləti şah idarə edirdi.',array['Şah','Prezident','Sultan','Parlament'],1),
('tarix8-xviii-1#1','tarix','tarix-8-xviii-1',2,2,'XVIII əsrin əvvəllərində Səfəvi dövləti hansı vəziyyətdə idi?','Dövlət zəifləmiş və tənəzzülə uğramışdı.',array['Zəifləmişdi','Ən qüdrətli dövründə idi','Yenicə yaranmışdı','Amerikaya köçmüşdü'],1),
('tarix8-xviii-1#2','tarix','tarix-8-xviii-1',3,2,'Nadir hansı ildə özünü şah elan etdi?','1736-cı ildə Muğan qurultayında şah seçildi.',array['1736','1918','1501','1828'],1),
('tarix8-xviii-1#3','tarix','tarix-8-xviii-1',3,2,'Nadir şahın hakimiyyəti necə bitdi?','1747-ci ildə sui-qəsdlə öldürüldü.',array['Sui-qəsdlə öldürüldü','Taxtdan könüllü getdi','Xaricə köçdü','Seçkidə uduzdu'],1),
('tarix8-xviii-1#4','tarix','tarix-8-xviii-1',3,2,'Nadir şah hansı ölkəyə məşhur yürüş etmişdi?','1739-cu ildə Hindistana (Dehliyə) yürüş etdi.',array['Hindistana','İspaniyaya','Norveçə','Yaponiyaya'],1),
('tarix8-xviii-1#5','tarix','tarix-8-xviii-1',3,2,'XVIII əsrin I yarısında Azərbaycan torpaqları hansı dövlətlər arasında bölüşdürülmüşdü?','Səfəvi, Osmanlı və Rusiya arasında.',array['Səfəvi, Osmanlı və Rusiya','İngiltərə və Fransa','Çin və Yaponiya','Heç kim arasında'],1),
('tarix8-xviii-1#6','tarix','tarix-8-xviii-1',3,2,'1724-cü il İstanbul müqaviləsi kimlər arasında bağlanmışdı?','Rusiya ilə Osmanlı arasında.',array['Rusiya ilə Osmanlı','Səfəvilərlə Fransa','İngiltərə ilə İspaniya','Xanlıqlar arasında'],1),
('tarix8-xviii-1#7','tarix','tarix-8-xviii-1',3,2,'Xəzərsahili torpaqlara yürüş edən rus çarı kim idi?','I Pyotr 1722–1723-cü illərdə yürüş etdi.',array['I Pyotr','II Yekaterina','İvan Qroznı','Nikolay'],1),
('tarix8-xviii-1#8','tarix','tarix-8-xviii-1',3,2,'Nadir şahın qurduğu dövlət hansı adla tanınır?','Əfşarlar dövləti adlanır.',array['Əfşarlar dövləti','Səlcuq dövləti','Atabəylər','Şirvanşahlar'],1),
('tarix8-xviii-1#9','tarix','tarix-8-xviii-1',3,2,'Muğan qurultayı hansı məqsədlə çağırılmışdı?','Nadirin şah seçilməsi üçün.',array['Nadirin şah seçilməsi üçün','İdman yarışı üçün','Bayram üçün','Ticarət üçün'],1),
('tarix8-xviii-1#10','tarix','tarix-8-xviii-1',2,2,'Nadir şahın ölümündən sonra Azərbaycanda nə yarandı?','Müstəqil xanlıqlar yarandı.',array['Müstəqil xanlıqlar','Vahid imperiya','Respublika','Koloniyalar'],1),
('tarix8-xanliqlar#1','tarix','tarix-8-xanliqlar',2,3,'Azərbaycanda xanlıqlar hansı dövrdə yarandı?','XVIII əsrin ortalarında yarandı.',array['XVIII əsrin ortalarında','XII əsrdə','XX əsrdə','E.ə. V əsrdə'],1),
('tarix8-xanliqlar#2','tarix','tarix-8-xanliqlar',2,3,'Qarabağ xanlığının banisi kimdir?','Xanlığı Pənahəli xan yaratmışdır.',array['Pənahəli xan','Fətəli xan','Hacı Çələbi','Cavad xan'],1),
('tarix8-xanliqlar#3','tarix','tarix-8-xanliqlar',3,3,'Quba xanlığının məşhur hökmdarı kim olmuşdur?','Fətəli xan Quba xanlığını gücləndirdi.',array['Fətəli xan','Pənahəli xan','Nadir şah','Şah İsmayıl'],1),
('tarix8-xanliqlar#4','tarix','tarix-8-xanliqlar',3,3,'Şəki xanlığının banisi kimdir?','Xanlığı Hacı Çələbi yaratmışdır.',array['Hacı Çələbi','Cavad xan','Fətəli xan','İbrahimxəlil xan'],1),
('tarix8-xanliqlar#5','tarix','tarix-8-xanliqlar',2,3,'İrəvan, Naxçıvan, Gəncə — bu şəhərlər XVIII əsrdə nə idi?','Ayrı-ayrı xanlıqların mərkəzləri idi.',array['Xanlıq mərkəzləri','Rusiya quberniyaları','Osmanlı paytaxtları','Kəndlər'],1),
('tarix8-xanliqlar#6','tarix','tarix-8-xanliqlar',3,3,'Quba xanı Fətəli xanın əsas məqsədi nə idi?','Azərbaycan torpaqlarını vahid dövlətdə birləşdirmək.',array['Torpaqları birləşdirmək','Xanlığı satmaq','Paytaxtı köçürmək','Dənizçilik qurmaq'],1),
('tarix8-xanliqlar#7','tarix','tarix-8-xanliqlar',1,3,'Xanlıqları kim idarə edirdi?','Xanlıqları xanlar idarə edirdi.',array['Xanlar','Prezidentlər','Qubernatorlar','Sultanlar'],1),
('tarix8-xanliqlar#8','tarix','tarix-8-xanliqlar',3,3,'Ağa Məhəmməd şah Qacar harada öldürüldü?','1797-ci ildə Şuşada öldürüldü.',array['Şuşada','Bakıda','Təbrizdə','Tehranda'],1),
('tarix8-xanliqlar#9','tarix','tarix-8-xanliqlar',3,3,'Xanlıqların zəifliyinin əsas səbəbi nə idi?','Ara müharibələri və vahid birliyin olmaması.',array['Ara müharibələri, birliyin olmaması','Torpağın azlığı','Əhalinin çoxluğu','Dənizin uzaqlığı'],1),
('tarix8-xanliqlar#10','tarix','tarix-8-xanliqlar',1,3,'Şəki xanlığının mərkəzi hansı şəhər idi?','Mərkəz Şəki şəhəri idi.',array['Şəki','Şamaxı','Lənkəran','Dərbənd'],1),
('tarix8-xix#1','tarix','tarix-8-xix',2,4,'XIX əsrin əvvəllərində Azərbaycan uğrunda hansı dövlətlər müharibə aparırdı?','Rusiya ilə Qacarlar İranı müharibə aparırdı.',array['Rusiya və Qacarlar İranı','İngiltərə və Fransa','Osmanlı və Misir','Çin və Hindistan'],1),
('tarix8-xix#2','tarix','tarix-8-xix',3,4,'1813-cü ildə hansı müqavilə imzalandı?','Gülüstan müqaviləsi imzalandı.',array['Gülüstan','Türkmənçay','Amasiya','İstanbul'],1),
('tarix8-xix#3','tarix','tarix-8-xix',3,4,'1828-ci il Türkmənçay müqaviləsi ilə nə baş verdi?','Azərbaycan torpaqları iki dövlət arasında bölündü.',array['Azərbaycan iki hissəyə bölündü','Xanlıqlar bərpa olundu','Müharibə başladı','Heç nə dəyişmədi'],1),
('tarix8-xix#4','tarix','tarix-8-xix',3,4,'Türkmənçay müqaviləsinə görə sərhəd hansı çay üzrə keçdi?','Sərhəd Araz çayı üzrə müəyyənləşdi.',array['Araz','Kür','Volqa','Nil'],1),
('tarix8-xix#5','tarix','tarix-8-xix',3,4,'Birinci Rusiya-İran müharibəsi hansı illərdə olmuşdur?','1804–1813-cü illərdə.',array['1804–1813','1918–1920','1700–1721','1941–1945'],1),
('tarix8-xix#6','tarix','tarix-8-xix',3,4,'İkinci Rusiya-İran müharibəsi hansı müqavilə ilə bitdi?','1828-ci il Türkmənçay müqaviləsi ilə.',array['Türkmənçay','Gülüstan','Amasiya','Versal'],1),
('tarix8-xix#7','tarix','tarix-8-xix',3,4,'Rusiya işğalından sonra xanlıqların taleyi necə oldu?','Xanlıqlar tədricən ləğv edildi.',array['Ləğv edildi','Gücləndirildi','Birləşdirildi','Müstəqil qaldı'],1),
('tarix8-xix#8','tarix','tarix-8-xix',3,4,'Gülüstan müqaviləsi harada imzalanmışdır?','Qarabağın Gülüstan kəndində.',array['Qarabağın Gülüstan kəndində','Moskvada','Parisdə','İstanbulda'],1),
('tarix8-xix#9','tarix','tarix-8-xix',3,4,'Gəncəni rus qoşunlarından qəhrəmancasına müdafiə edən xan kim idi?','Cavad xan Gəncənin müdafiəsində həlak oldu.',array['Cavad xan','Fətəli xan','Pənahəli xan','Hacı Çələbi'],1),
('tarix8-xix#10','tarix','tarix-8-xix',3,4,'Şimali Azərbaycanın Rusiyaya birləşdirilməsi hansı iki müqavilə ilə rəsmiləşdi?','Gülüstan (1813) və Türkmənçay (1828) müqavilələri ilə.',array['Gülüstan və Türkmənçay','Amasiya və İstanbul','Versal və Yalta','Heç bir müqavilə ilə'],1)
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
     and (ext_key like 'az8-%' or ext_key like 'ing8-%'
          or ext_key like 'inf8-%' or ext_key like 'tarix8-%');
  if n <> 240 then
    raise exception 'sinif8 suallari: 240 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'az8-%' or q.ext_key like 'ing8-%'
          or q.ext_key like 'inf8-%' or q.ext_key like 'tarix8-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az8-%' or ext_key like 'ing8-%'
      or ext_key like 'inf8-%' or ext_key like 'tarix8-%';
  if k <> 24 then
    raise exception 'movzu sayi 24 deyil: %', k;
  end if;
  raise notice '8-ci sinif banki: % sual, 24 movzu (az, ing, inf, tarix).', n;
end $$;
