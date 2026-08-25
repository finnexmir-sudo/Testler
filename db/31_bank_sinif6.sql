-- =====================================================================
--  31_bank_sinif6.sql : 6-CI SINIF - AZ DILI, INGILIS DILI,
--                       INFORMATIKA, AZERBAYCAN TARIXI
--
--  BU FAYL ELLE YAZILMIR - tools/sinif6.py yaradir:
--      python3 tools/sinif6.py
--
--  Az dili 8 + Ingilis dili 8 + Informatika 5 + Tarix 3
--  = 24 movzu x 10 = 240.  ext_key: az6-/ing6-/inf6-/tarix6-...
--  ON SERT: 29_movzular_orta6.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('az-dili','az-6-fonetika'),
                                ('ingilis-dili','ing-6-town'),
                                ('informatika','inf-6-internet'),
                                ('tarix','tarix-6-ibtidai'))
     having count(*) = 4) then
    raise exception 'ONCE 29_movzular_orta6.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'az6-%' or q.ext_key like 'ing6-%'
        or q.ext_key like 'inf6-%' or q.ext_key like 'tarix6-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('az6-fonetika#1','az-dili','az-6-fonetika',2,1,'«Ağıl» sözünə saitlə başlanan şəkilçi artıranda (ağlım) hansı hadisə baş verir?','İkinci hecanın saiti düşür — səsdüşümü baş verir.',array['Səsdüşümü','Səsartımı','Vurğu dəyişməsi','Heç nə'],1),
('az6-fonetika#2','az-dili','az-6-fonetika',2,1,'«Oğul» sözü «oğlu» formasında işlənəndə hansı sait düşür?','Oğul → oğlu: ikinci hecadakı «u» saiti düşür.',array['u','o','ğ','l'],1),
('az6-fonetika#3','az-dili','az-6-fonetika',2,1,'«Qapı» sözünə yönlük hal şəkilçisi artıranda (qapıya) hansı samit əlavə olunur?','İki sait arasına bitişdirici «y» samiti artırılır.',array['y','n','s','ş'],1),
('az6-fonetika#4','az-dili','az-6-fonetika',3,1,'«Dostlar» sözünün tələffüzündə hansı samit düşür?','Üç samit yanaşı gələndə ortadakı düşür: [doslar].',array['t','d','s','r'],1),
('az6-fonetika#5','az-dili','az-6-fonetika',2,1,'Vurğu nədir?','Sözdə hecalardan birinin daha qüvvətli deyilməsidir.',array['Hecanın qüvvətli deyilməsi','Sözün mənası','Hərflərin sayı','Cümlənin sonu'],1),
('az6-fonetika#6','az-dili','az-6-fonetika',2,1,'Azərbaycan dilində vurğu adətən hansı hecaya düşür?','Dilimizdə vurğu əsasən son hecaya düşür.',array['Son hecaya','İlk hecaya','Orta hecaya','İstənilən hecaya'],1),
('az6-fonetika#7','az-dili','az-6-fonetika',3,1,'«Haqq» sözünə saitlə başlanan şəkilçi artıranda necə yazılır?','Qoşa samit saxlanılır: haqqı.',array['haqqı','haqı','hağı','haqqqı'],1),
('az6-fonetika#8','az-dili','az-6-fonetika',3,1,'«Stəkan» tipli sözlərin tələffüzündə bəzən nə baş verir?','Söz əvvəlindəki qoşa samitin qarşısına sait artırılır: [istəkan] — səsartımı.',array['Səsartımı','Səsdüşümü','Vurğu itir','Samit düşür'],1),
('az6-fonetika#9','az-dili','az-6-fonetika',1,1,'Danışıq səslərini öyrənən dilçilik bölməsi necə adlanır?','Səsləri fonetika öyrənir.',array['Fonetika','Leksika','Qrammatika','Orfoqrafiya'],1),
('az6-fonetika#10','az-dili','az-6-fonetika',2,1,'«Meyvə» sözündə neçə səs və neçə hərf var?','M-e-y-v-ə: 5 səs, 5 hərf.',array['5 səs, 5 hərf','4 səs, 5 hərf','5 səs, 4 hərf','6 səs, 5 hərf'],1),
('az6-yazi#1','az-dili','az-6-yazi',2,1,'Hansı söz defislə yazılır?','Təkrar sözlər defislə yazılır: qaça-qaça.',array['qaça-qaça','dəmiryol','günəbaxan','kitabxana'],1),
('az6-yazi#2','az-dili','az-6-yazi',2,1,'Sözlərin təkrarından yaranan mürəkkəb sözlər necə yazılır?','Təkrardan yaranan sözlər defislə yazılır.',array['Defislə','Bitişik','Ayrı','Dırnaqda'],1),
('az6-yazi#3','az-dili','az-6-yazi',2,1,'Mürəkkəb şəxs adları (Əli + ağa) necə yazılır?','Mürəkkəb adlar bitişik yazılır: Əlağa.',array['Bitişik','Defislə','Ayrı','Kiçik hərflə'],1),
('az6-yazi#4','az-dili','az-6-yazi',2,1,'Hansı mürəkkəb yer adı düzgün yazılıb?','Mürəkkəb yer adları bitişik yazılır: Ağdam.',array['Ağdam','Ağ-dam','Ağ dam','ağdam'],1),
('az6-yazi#5','az-dili','az-6-yazi',3,1,'«Alma-armud» tipli sözlər nəyi bildirir?','Yaxın əşyaların ümumiləşmiş toplusunu bildirir.',array['Ümumiləşmiş topluluğu','Yalnız bir əşyanı','Hərəkəti','Rəngi'],1),
('az6-yazi#6','az-dili','az-6-yazi',3,1,'«Foto-» hissəsi ilə başlanan alınma sözlər necə yazılır?','Bitişik yazılır: fotoaparat.',array['Bitişik','Defislə','Ayrı','Dırnaqda'],1),
('az6-yazi#7','az-dili','az-6-yazi',2,1,'Hansı söz bitişik yazılır?','Kitabxana mürəkkəb söz kimi bitişik yazılır.',array['kitabxana','qaça-qaça','az-çox','beş-üç'],1),
('az6-yazi#8','az-dili','az-6-yazi',2,1,'«Az çox», «azçox», «az-çox» yazılışlarından hansı düzgündür?','Əks mənalı təkrar sözlər defislə yazılır: az-çox.',array['az-çox','azçox','az çox','az. çox'],1),
('az6-yazi#9','az-dili','az-6-yazi',3,1,'«Vitse-» hissəsi ilə düzələn vəzifə adları necə yazılır?','Defislə yazılır: vitse-prezident.',array['Defislə','Bitişik','Ayrı','Böyük hərflə bitişik'],1),
('az6-yazi#10','az-dili','az-6-yazi',3,1,'Hiperonim nədir?','Ümumi anlayış bildirən sözdür: «meyvə» — «alma» üçün hiperonimdir.',array['Ümumi anlayış bildirən söz','Əks mənalı söz','Alınma söz','Təkrar söz'],1),
('az6-soz-luget#1','az-dili','az-6-soz-luget',2,2,'Sözün başlanğıc forması necə olur?','Qrammatik şəkilçilərsiz forma başlanğıc formadır.',array['Qrammatik şəkilçisiz','Cəm şəkilçili','Hal şəkilçili','Mənsubiyyət şəkilçili'],1),
('az6-soz-luget#2','az-dili','az-6-soz-luget',2,2,'«Kitablarımızdan» sözünün başlanğıc forması hansıdır?','Şəkilçiləri atsaq: kitab.',array['kitab','kitablar','kitabımız','kitabdan'],1),
('az6-soz-luget#3','az-dili','az-6-soz-luget',2,2,'Hansı cərgədə eyniköklü sözlər verilib?','Duz, duzlu, duzsuz — hamısı «duz» kökündəndir.',array['duz, duzlu, duzsuz','duz, dad, tam','su, çay, göl','gəl, get, dur'],1),
('az6-soz-luget#4','az-dili','az-6-soz-luget',2,2,'«Yazı, yazıçı, yazmaq» sözlərini birləşdirən cəhət nədir?','Üçü də «yaz» kökündən yaranıb — eyniköklüdür.',array['Eyni kökdən yaranmaları','Eyni şəkilçi','Eyni heca sayı','Əks mənalı olmaları'],1),
('az6-soz-luget#5','az-dili','az-6-soz-luget',2,2,'«Su» kökündən yaranan sözü seçin.','Sulu = su + lu.',array['sulu','sükan','sürü','süd'],1),
('az6-soz-luget#6','az-dili','az-6-soz-luget',2,2,'Sözün lüğəvi (leksik) mənasını daşıyan hissəsi hansıdır?','Əsas mənanı kök daşıyır.',array['Kök','Cəm şəkilçisi','Hal şəkilçisi','Sonluq'],1),
('az6-soz-luget#7','az-dili','az-6-soz-luget',3,2,'«Dənizçilik» sözündə neçə şəkilçi var?','Dəniz + çi + lik: iki leksik şəkilçi.',array['2','1','3','0'],1),
('az6-soz-luget#8','az-dili','az-6-soz-luget',2,2,'«Başla» sözünün kökü hansıdır?','Başla = baş + la.',array['baş','başla','la','aş'],1),
('az6-soz-luget#9','az-dili','az-6-soz-luget',3,2,'Eyniköklü sözlər hansı yolla yaranır?','Kökə leksik (sözdüzəldici) şəkilçilər artırmaqla.',array['Kökə leksik şəkilçilər artırmaqla','Sözü təkrarlamaqla','Vurğunu dəyişməklə','Hərfləri dəyişməklə'],1),
('az6-soz-luget#10','az-dili','az-6-soz-luget',2,2,'«Duzlu» və «dadlı» sözləri eyniköklüdürmü?','Kökləri fərqlidir (duz və dad) — eyniköklü deyil.',array['Xeyr, kökləri fərqlidir','Bəli, eyniköklüdür','Hər ikisi köksüzdür','Bilmək olmaz'],1),
('az6-isim-hal#1','az-dili','az-6-isim-hal',2,2,'İsmin neçə halı var?','İsmin 6 halı var.',array['6','5','4','9'],1),
('az6-isim-hal#2','az-dili','az-6-isim-hal',2,2,'«Kitabı oxudum» cümləsində «kitabı» hansı haldadır?','Nəyi? sualına cavab verir — təsirlik haldadır.',array['Təsirlik','Adlıq','Yönlük','Yerlik'],1),
('az6-isim-hal#3','az-dili','az-6-isim-hal',1,2,'Adlıq hal hansı suallara cavab verir?','Adlıq hal «kim? nə? hara?» suallarına cavab verir.',array['Kim? Nə?','Kimin? Nəyin?','Kimə? Nəyə?','Kimdən? Nədən?'],1),
('az6-isim-hal#4','az-dili','az-6-isim-hal',2,2,'«Məktəbin həyəti» birləşməsində «məktəbin» hansı haldadır?','Kimin? nəyin? — yiyəlik haldadır.',array['Yiyəlik','Təsirlik','Çıxışlıq','Adlıq'],1),
('az6-isim-hal#5','az-dili','az-6-isim-hal',3,2,'Qeyri-müəyyən yiyəlik hala uyğun nümunə hansıdır?','«Sinif otağı» — birinci tərəf şəkilçisizdir.',array['sinif otağı','sinfin otağı','sinifdə otaq','sinifdən otaq'],1),
('az6-isim-hal#6','az-dili','az-6-isim-hal',2,2,'«Evə» sözü hansı haldadır?','Haraya? — yönlük haldadır.',array['Yönlük','Yerlik','Çıxışlıq','Yiyəlik'],1),
('az6-isim-hal#7','az-dili','az-6-isim-hal',2,2,'«Şəhərdə» sözünün halı hansıdır?','Harada? — yerlik haldır.',array['Yerlik','Yönlük','Təsirlik','Adlıq'],1),
('az6-isim-hal#8','az-dili','az-6-isim-hal',2,2,'«Kənddən» sözü hansı haldadır?','Haradan? — çıxışlıq haldadır.',array['Çıxışlıq','Yerlik','Yönlük','Yiyəlik'],1),
('az6-isim-hal#9','az-dili','az-6-isim-hal',3,2,'«Kitab oxuyuram» cümləsində «kitab» sözü hansı halda işlənib?','Şəkilçisiz təsirlik — qeyri-müəyyən təsirlik haldadır.',array['Qeyri-müəyyən təsirlik','Adlıq','Yiyəlik','Yerlik'],1),
('az6-isim-hal#10','az-dili','az-6-isim-hal',3,2,'«Suyu içdim» və «su içdim» ifadələrinin fərqi nədir?','Birincidə müəyyən, ikincidə qeyri-müəyyən təsirlik hal işlənib.',array['Müəyyən və qeyri-müəyyən təsirlik','Hal fərqi yoxdur','Birinci cəmdir','İkinci yiyəlikdədir'],1),
('az6-qosma-baglayici#1','az-dili','az-6-qosma-baglayici',2,3,'Qoşma hansı nitq hissələri qrupuna aiddir?','Qoşma köməkçi nitq hissəsidir.',array['Köməkçi','Əsas','İsim qrupuna','Feil qrupuna'],1),
('az6-qosma-baglayici#2','az-dili','az-6-qosma-baglayici',2,3,'«Məktəbə qədər» birləşməsində «qədər» sözü nədir?','Qədər — məsafə/hüdud bildirən qoşmadır.',array['Qoşma','İsim','Feil','Sifət'],1),
('az6-qosma-baglayici#3','az-dili','az-6-qosma-baglayici',2,3,'Bağlayıcılar nəyi bağlayır?','Sözləri və cümlələri bir-birinə bağlayır.',array['Sözləri və cümlələri','Yalnız hecaları','Yalnız hərfləri','Heç nəyi'],1),
('az6-qosma-baglayici#4','az-dili','az-6-qosma-baglayici',1,3,'«Və, amma, lakin» sözləri hansı nitq hissəsidir?','Bunlar bağlayıcılardır.',array['Bağlayıcı','Qoşma','Əvəzlik','Zərf'],1),
('az6-qosma-baglayici#5','az-dili','az-6-qosma-baglayici',2,3,'«Üçün» qoşması əsasən hansı mənanı bildirir?','Üçün — məqsəd və səbəb bildirir.',array['Məqsəd və səbəb','Zaman','Rəng','Say'],1),
('az6-qosma-baglayici#6','az-dili','az-6-qosma-baglayici',2,3,'«Yağış yağdı, amma biz gəzintiyə çıxdıq» cümləsində bağlayıcı hansıdır?','Amma — qarşılaşdırma bağlayıcısıdır.',array['amma','yağış','biz','çıxdıq'],1),
('az6-qosma-baglayici#7','az-dili','az-6-qosma-baglayici',3,3,'«Qədər, kimi, üçün» qoşmaları əsasən hansı sözlərə qoşulur?','Qoşmalar adlara (isimlərə, əvəzliklərə) qoşulur.',array['Adlara','Yalnız feillərə','Bağlayıcılara','Nidalara'],1),
('az6-qosma-baglayici#8','az-dili','az-6-qosma-baglayici',3,3,'Hansı cümlədə «ilə» birgəlik bildirir?','«Dostu ilə gəldi» — birlikdə gəlmə bildirir.',array['Dostu ilə gəldi.','Qatarla getdi.','Qələm ilə yazdı.','Sevinclə danışdı.'],1),
('az6-qosma-baglayici#9','az-dili','az-6-qosma-baglayici',2,3,'Hansı cərgədə yalnız qoşmalar verilib?','Kimi, qədər, üçün — hamısı qoşmadır.',array['kimi, qədər, üçün','və, ki, amma','mən, sən, o','tez, gec, indi'],1),
('az6-qosma-baglayici#10','az-dili','az-6-qosma-baglayici',3,3,'«Lakin» bağlayıcısı cümlələr arasında hansı əlaqəni yaradır?','Lakin — qarşılaşdırma (ziddiyyət) bildirir.',array['Qarşılaşdırma','Səbəb','Zaman ardıcıllığı','Bərabərlik'],1),
('az6-say-numerativ#1','az-dili','az-6-say-numerativ',2,3,'Saylardan sonra gələn isimlər hansı formada işlənir?','Saydan sonra isim təkdə olur: beş kitab.',array['Təkdə','Cəmdə','Yiyəlik halda','Çıxışlıq halda'],1),
('az6-say-numerativ#2','az-dili','az-6-say-numerativ',2,3,'«Beş kitablar» ifadəsindəki səhv nədir?','Saydan sonra isim cəmlənmir — «beş kitab» olmalıdır.',array['İsim cəmdə olmamalıdır','Say səhv yazılıb','Söz sırası səhvdir','Səhv yoxdur'],1),
('az6-say-numerativ#3','az-dili','az-6-say-numerativ',3,3,'Numerativ sözlər hansılardır?','Sayla isim arasında işlənən sözlərdir: nəfər, ədəd, baş.',array['Sayla isim arasında işlənən sözlər','Yalnız sıra sayları','Rəng bildirən sözlər','Bağlayıcılar'],1),
('az6-say-numerativ#4','az-dili','az-6-say-numerativ',2,3,'«Üç nəfər tələbə» ifadəsində numerativ söz hansıdır?','İnsanlar üçün «nəfər» numerativi işlənir.',array['nəfər','üç','tələbə','ifadədə yoxdur'],1),
('az6-say-numerativ#5','az-dili','az-6-say-numerativ',3,3,'Heyvanların sayını bildirmək üçün hansı numerativ söz işlənir?','Heyvanlar üçün «baş» işlənir: on baş qoyun.',array['baş','nəfər','cild','top'],1),
('az6-say-numerativ#6','az-dili','az-6-say-numerativ',2,3,'«Dənə» numerativ sözü nə üçün işlənir?','Ayrı-ayrı əşyaların sayı üçün: beş dənə alma.',array['Əşyaların sayı üçün','İnsanların sayı üçün','Kitabların cildi üçün','Vaxt üçün'],1),
('az6-say-numerativ#7','az-dili','az-6-say-numerativ',2,3,'Hansı ifadə düzgündür?','Ayaqqabı cütlə sayılır: iki cüt ayaqqabı.',array['iki cüt ayaqqabı','iki nəfər ayaqqabı','iki baş ayaqqabı','iki cild ayaqqabı'],1),
('az6-say-numerativ#8','az-dili','az-6-say-numerativ',2,3,'Sıra sayları rəqəmlə necə yazılır?','Şəkilçi defislə yazılır: 5-ci.',array['5-ci','5ci','5 ci','5.ci'],1),
('az6-say-numerativ#9','az-dili','az-6-say-numerativ',3,3,'«Yüzlərlə insan» ifadəsində say nəyi bildirir?','Dəqiq olmayan çoxluğu bildirir.',array['Qeyri-müəyyən çoxluğu','Dəqiq sayı','Sıranı','Kəsri'],1),
('az6-say-numerativ#10','az-dili','az-6-say-numerativ',2,3,'«Xeyli» sözü hansı miqdarı bildirir?','Xeyli — qeyri-müəyyən miqdar bildirir.',array['Qeyri-müəyyən miqdarı','Dəqiq miqdarı','Sıra sayını','Kəsr sayını'],1),
('az6-cumle-uzvleri#1','az-dili','az-6-cumle-uzvleri',2,4,'Tamamlıq hansı suallara cavab verir?','Tamamlıq hallara uyğun «kimi? nəyi? kimə? nəyə?» və s. suallarına cavab verir.',array['Kimi? Nəyi? Kimə? Nəyə?','Necə? Nə cür?','Nə vaxt? Harada?','Neçə? Neçənci?'],1),
('az6-cumle-uzvleri#2','az-dili','az-6-cumle-uzvleri',2,4,'«Şagird kitabı oxudu» cümləsində tamamlıq hansıdır?','Nəyi oxudu? — kitabı.',array['kitabı','şagird','oxudu','cümlədə yoxdur'],1),
('az6-cumle-uzvleri#3','az-dili','az-6-cumle-uzvleri',2,4,'Təyin cümlədə nəyi bildirir?','Təyin əşyanın əlamətini bildirir.',array['Əşyanın əlamətini','Hərəkətin vaxtını','Hərəkətin yerini','Hökmü'],1),
('az6-cumle-uzvleri#4','az-dili','az-6-cumle-uzvleri',2,4,'«Maraqlı film izlədik» cümləsində təyin hansıdır?','Hansı film? — maraqlı.',array['maraqlı','film','izlədik','cümlədə yoxdur'],1),
('az6-cumle-uzvleri#5','az-dili','az-6-cumle-uzvleri',2,4,'Zərflik cümlədə hansı suallara cavab verir?','Zərflik «necə? harada? nə vaxt?» suallarına cavab verir.',array['Necə? Harada? Nə vaxt?','Kim? Nə?','Kimin? Nəyin?','Neçənci?'],1),
('az6-cumle-uzvleri#6','az-dili','az-6-cumle-uzvleri',2,4,'«Uşaqlar həyətdə oynayır» cümləsində zərflik hansıdır?','Harada oynayır? — həyətdə.',array['həyətdə','uşaqlar','oynayır','cümlədə yoxdur'],1),
('az6-cumle-uzvleri#7','az-dili','az-6-cumle-uzvleri',3,4,'«Dünən qonaq gəldi» cümləsində «dünən» hansı üzvdür?','Nə vaxt? — zaman zərfliyidir.',array['Zaman zərfliyi','Tamamlıq','Təyin','Mübtəda'],1),
('az6-cumle-uzvleri#8','az-dili','az-6-cumle-uzvleri',2,4,'«Hansı?» sualına cavab verən cümlə üzvü hansıdır?','Əlamət bildirən üzv təyindir.',array['Təyin','Tamamlıq','Zərflik','Xəbər'],1),
('az6-cumle-uzvleri#9','az-dili','az-6-cumle-uzvleri',3,4,'«Kitabı dostuma verdim» cümləsində «dostuma» hansı üzvdür?','Kimə verdim? — tamamlıqdır.',array['Tamamlıq','Təyin','Zərflik','Mübtəda'],1),
('az6-cumle-uzvleri#10','az-dili','az-6-cumle-uzvleri',3,4,'İkinci dərəcəli üzvlər cümlədə nə edir?','Baş üzvlərin məzmununu genişləndirib dəqiqləşdirir.',array['Baş üzvləri izah edib genişləndirir','Cümləni qısaldır','Yalnız bəzək üçündür','Fikri dəyişdirir'],1),
('az6-soz-sirasi#1','az-dili','az-6-soz-sirasi',2,4,'Azərbaycan dilində mübtəda adətən cümlənin harasında durur?','Mübtəda adətən cümlənin əvvəlində gəlir.',array['Əvvəlində','Sonunda','Yalnız ortasında','Qaydası yoxdur'],1),
('az6-soz-sirasi#2','az-dili','az-6-soz-sirasi',3,4,'«Kitabı Aysu oxudu» cümləsində söz sırası nəyi qüvvətləndirir?','Önə çəkilən «kitabı» sözü məntiqi vurğu alır.',array['«Kitabı» sözünü','«Oxudu» sözünü','Heç nəyi','Cümlənin sonunu'],1),
('az6-soz-sirasi#3','az-dili','az-6-soz-sirasi',3,4,'Söz birləşməsində asılı tərəf adətən harada durur?','Asılı tərəf əsas tərəfdən əvvəl gəlir: dəniz sahili.',array['Əsas tərəfdən əvvəl','Əsas tərəfdən sonra','Cümlənin sonunda','İstənilən yerdə'],1),
('az6-soz-sirasi#4','az-dili','az-6-soz-sirasi',3,4,'«Dağların zirvəsi» birləşməsində tərəflər nə ilə bağlanıb?','Yiyəlik hal (-ların) və mənsubiyyət (-i) şəkilçiləri ilə.',array['Yiyəlik hal və mənsubiyyət şəkilçiləri ilə','Yalnız vurğu ilə','Bağlayıcı ilə','Qoşma ilə'],1),
('az6-soz-sirasi#5','az-dili','az-6-soz-sirasi',2,4,'Söz sırası dəyişəndə cümlədə nə dəyişə bilər?','Məna çaları və məntiqi vurğu dəyişir.',array['Məna çaları və vurğu','Hərflərin sayı','Sözlərin kökü','Heç nə'],1),
('az6-soz-sirasi#6','az-dili','az-6-soz-sirasi',2,4,'Söz birləşməsi cümlədən nə ilə fərqlənir?','Birləşmə bitmiş fikir bildirmir.',array['Bitmiş fikir bildirməməsi ilə','Sözlərin çoxluğu ilə','Böyük hərflə','Nöqtə ilə'],1),
('az6-soz-sirasi#7','az-dili','az-6-soz-sirasi',2,4,'İsmi birləşmənin əsas tərəfi adətən hansı nitq hissəsi olur?','Əsas tərəf isim olur: gözəl mənzərə.',array['İsim','Feil','Bağlayıcı','Nida'],1),
('az6-soz-sirasi#8','az-dili','az-6-soz-sirasi',3,4,'«Oxumaq arzusu» birləşməsində birinci tərəf hansı formadadır?','Oxumaq — məsdərdir.',array['Məsdər','Feili sifət','Sifət','Say'],1),
('az6-soz-sirasi#9','az-dili','az-6-soz-sirasi',2,4,'Cümlədə sözlər arasında əlaqəni nə yaradır?','Şəkilçilər və söz sırası əlaqə yaradır.',array['Şəkilçilər və söz sırası','Yalnız nöqtələr','Hərflərin rəngi','Sətirlər'],1),
('az6-soz-sirasi#10','az-dili','az-6-soz-sirasi',3,4,'«Mən məktəbə gedirəm» cümləsi hansı sıra qaydasına uyğundur?','Mübtəda + tamamlıq/zərflik + xəbər sırası ilə qurulub.',array['Mübtəda + zərflik + xəbər','Xəbər + mübtəda','Təyin + təyin + təyin','Sıra pozulub'],1),
('ing6-town#1','ingilis-dili','ing-6-town',2,1,'Which place sells bread and cakes?','Çörək və tort çörəkxanada (bakery) satılır.',array['bakery','library','bank','stadium'],1),
('ing6-town#2','ingilis-dili','ing-6-town',1,1,'A library is a place where we can ___.','Kitabxanada kitab oxuyuruq.',array['read books','swim','buy shoes','play football'],1),
('ing6-town#3','ingilis-dili','ing-6-town',1,1,'There ___ a big park in our town.','Təkdə: there is.',array['is','are','am','be'],1),
('ing6-town#4','ingilis-dili','ing-6-town',2,1,'Where can we buy medicine?','Dərman aptekdə satılır: at the chemist.',array['at the chemist','at the bakery','at the stadium','at the cinema'],1),
('ing6-town#5','ingilis-dili','ing-6-town',1,1,'«Museum» nə üçündür?','Muzeydə tarixi əşyalara baxırıq.',array['Tarixi əşyalara baxmaq üçün','Yemək almaq üçün','Üzmək üçün','Avtobus gözləmək üçün'],1),
('ing6-town#6','ingilis-dili','ing-6-town',2,1,'«I ___ go to the cinema on Sundays.» (həmişə)','Həmişə — always.',array['always','never','town','where'],1),
('ing6-town#7','ingilis-dili','ing-6-town',1,1,'«Never» nə deməkdir?','Never — heç vaxt.',array['Heç vaxt','Həmişə','Bəzən','Tez-tez'],1),
('ing6-town#8','ingilis-dili','ing-6-town',2,1,'«The bank is ___ the post office and the cafe.»','İkisinin arasında: between.',array['between','under','on','up'],1),
('ing6-town#9','ingilis-dili','ing-6-town',2,1,'«Are there any shops near here?» sualına qısa cavab hansıdır?','Cəmdə qısa cavab: Yes, there are.',array['Yes, there are.','Yes, there is.','Yes, it does.','No, they can.'],1),
('ing6-town#10','ingilis-dili','ing-6-town',2,1,'«Town» və «city» sözlərinin fərqi nədir?','City böyük şəhərdir, town kiçik şəhərdir.',array['City daha böyükdür','Town daha böyükdür','Eyni sözlərdir','İkisi də kənddir'],1),
('ing6-food#1','ingilis-dili','ing-6-food',2,1,'«Can I have some water, please?» cümləsi nəyi bildirir?','Can burada icazə və xahiş bildirir.',array['Nəzakətli xahişi','Əmri','Qadağanı','Təəccübü'],1),
('ing6-food#2','ingilis-dili','ing-6-food',2,1,'Which word is a vegetable?','Carrot (kök) tərəvəzdir; qalanları meyvədir.',array['carrot','apple','cherry','peach'],1),
('ing6-food#3','ingilis-dili','ing-6-food',1,1,'«Delicious» nə deməkdir?','Delicious — çox dadlı.',array['Çox dadlı','Acı','Soyuq','Boş'],1),
('ing6-food#4','ingilis-dili','ing-6-food',2,1,'«___ likes pizza.» (o — qız)','Qız üçün mübtəda əvəzliyi: She.',array['She','Her','Him','Us'],1),
('ing6-food#5','ingilis-dili','ing-6-food',2,1,'«I see ___ every day.» (onu — oğlanı)','Tamamlıq əvəzliyi: him.',array['him','he','his','she'],1),
('ing6-food#6','ingilis-dili','ing-6-food',2,1,'«Let us make a salad» cümləsi nədir?','Bu, təklifdir (gəlin salat hazırlayaq).',array['Təklif','Sual','Qadağa','Təəssüf'],1),
('ing6-food#7','ingilis-dili','ing-6-food',2,1,'«Fry» feili nə deməkdir?','Fry — qızartmaq.',array['Qızartmaq','Qaynatmaq','Doğramaq','Soyutmaq'],1),
('ing6-food#8','ingilis-dili','ing-6-food',2,1,'«Boil» feili hansı hərəkəti bildirir?','Boil — qaynatmaq.',array['Qaynatmaq','Qızartmaq','Kəsmək','Yumaq'],1),
('ing6-food#9','ingilis-dili','ing-6-food',2,1,'Which meal is in the middle of the day?','Günorta yeməyi — lunch.',array['lunch','breakfast','dinner','supper'],1),
('ing6-food#10','ingilis-dili','ing-6-food',2,1,'«Would you like some tea?» sualına nəzakətli cavab hansıdır?','Nəzakətli qəbul: Yes, please.',array['Yes, please.','Give me!','No!','Go away.'],1),
('ing6-holiday#1','ingilis-dili','ing-6-holiday',2,2,'«I was in Paris last summer» cümləsi hansı zamandadır?','Was — be feilinin keçmiş formasıdır: Past Simple.',array['Past Simple','Present Simple','Gələcək zaman','Past Continuous'],1),
('ing6-holiday#2','ingilis-dili','ing-6-holiday',2,2,'«There ___ many tourists on the beach yesterday.»','Cəmdə keçmiş: there were.',array['were','was','is','am'],1),
('ing6-holiday#3','ingilis-dili','ing-6-holiday',2,2,'«She ___ very happy on holiday.» (keçmiş)','She ilə: was.',array['was','were','are','be'],1),
('ing6-holiday#4','ingilis-dili','ing-6-holiday',1,2,'«Beach» nə deməkdir?','Beach — çimərlik.',array['Çimərlik','Dağ','Meşə','Muzey'],1),
('ing6-holiday#5','ingilis-dili','ing-6-holiday',1,2,'«Hotel» sözünün mənası nədir?','Hotel — mehmanxana.',array['Mehmanxana','Xəstəxana','Məktəb','Mağaza'],1),
('ing6-holiday#6','ingilis-dili','ing-6-holiday',2,2,'«Sightseeing» nə deməkdir?','Sightseeing — görməli yerləri gəzmək.',array['Görməli yerləri gəzmək','Yemək bişirmək','Ev tapşırığı etmək','Yatmaq'],1),
('ing6-holiday#7','ingilis-dili','ing-6-holiday',2,2,'Which one do you need to travel to another country?','Başqa ölkəyə pasportla gedirik.',array['passport','sofa','fridge','pillow'],1),
('ing6-holiday#8','ingilis-dili','ing-6-holiday',2,2,'«There was a swimming pool at the hotel.» — Oteldə nə var idi?','Swimming pool — üzgüçülük hovuzu.',array['Üzgüçülük hovuzu','Kitabxana','Stadion','Meşə'],1),
('ing6-holiday#9','ingilis-dili','ing-6-holiday',2,2,'«Suitcase» nədir?','Suitcase — çamadan.',array['Çamadan','Papaq','Xəritə','Bilet'],1),
('ing6-holiday#10','ingilis-dili','ing-6-holiday',2,2,'«What a holiday!» nidası nəyi ifadə edir?','Heyranlığı bildirir: necə də gözəl tətil!',array['Heyranlığı','Qəzəbi','Yorğunluğu','Sualı'],1),
('ing6-stories#1','ingilis-dili','ing-6-stories',2,2,'«Walk» feilinin Past Simple forması hansıdır?','Qaydalı feil: walked.',array['walked','walking','walks','wolk'],1),
('ing6-stories#2','ingilis-dili','ing-6-stories',2,2,'«Write» feilinin keçmiş forması hansıdır?','Qaydasız feil: wrote.',array['wrote','writed','written by','writes'],1),
('ing6-stories#3','ingilis-dili','ing-6-stories',2,2,'«Once upon a time» ifadəsi nə deməkdir?','Nağıl başlanğıcı: biri var idi, biri yox idi.',array['Biri var idi, biri yox idi','Sonra görüşərik','Sabahın xeyir','Nə baş verdi'],1),
('ing6-stories#4','ingilis-dili','ing-6-stories',2,2,'«Tell» feilinin keçmişi hansıdır?','Qaydasız feil: told.',array['told','telled','tells','telling'],1),
('ing6-stories#5','ingilis-dili','ing-6-stories',3,2,'«They did not ___ the film.» boşluğu doldurun.','Did not-dan sonra əsas forma: like.',array['like','liked','likes','liking'],1),
('ing6-stories#6','ingilis-dili','ing-6-stories',2,2,'«___ week» (keçən həftə) — boşluğu doldurun.','Keçən — last: last week.',array['last','next','this','every'],1),
('ing6-stories#7','ingilis-dili','ing-6-stories',1,2,'Nağılda əsas obraz necə adlanır? (ingiliscə)','Əsas qəhrəman — hero.',array['hero','table','window','lesson'],1),
('ing6-stories#8','ingilis-dili','ing-6-stories',3,2,'«Begin» feilinin Past Simple forması hansıdır?','Qaydasız feil: began.',array['began','beginned','begins','begun to'],1),
('ing6-stories#9','ingilis-dili','ing-6-stories',2,2,'«The story ended happily.» — Hekayə necə bitdi?','Happily — xoşbəxt sonluqla.',array['Xoşbəxt sonluqla','Kədərlə','Sualla','Bitmədi'],1),
('ing6-stories#10','ingilis-dili','ing-6-stories',2,2,'«First, then, finally» sözləri mətndə nə üçün işlənir?','Hadisələrin ardıcıllığını göstərmək üçün.',array['Hadisələrin ardıcıllığı üçün','Rəngləri saymaq üçün','Sual vermək üçün','Salamlaşmaq üçün'],1),
('ing6-journeys#1','ingilis-dili','ing-6-journeys',1,3,'Which is water transport?','Gəmi su nəqliyyatıdır: ship.',array['ship','bus','train','bike'],1),
('ing6-journeys#2','ingilis-dili','ing-6-journeys',1,3,'«Train» nə deməkdir?','Train — qatar.',array['Qatar','Təyyarə','Gəmi','Tramvay'],1),
('ing6-journeys#3','ingilis-dili','ing-6-journeys',2,3,'«Did they arrive on time?» sualına qısa cavab hansıdır?','Past Simple sualına: Yes, they did.',array['Yes, they did.','Yes, they do.','Yes, they are.','Yes, they can.'],1),
('ing6-journeys#4','ingilis-dili','ing-6-journeys',3,3,'«Could» feili nəyi bildirir?','Could — keçmişdə bacarığı bildirir.',array['Keçmişdə bacarığı','Gələcək planı','İndiki hərəkəti','Sahibliyi'],1),
('ing6-journeys#5','ingilis-dili','ing-6-journeys',2,3,'«When I was five, I ___ already swim.» (bacarırdım)','Keçmiş bacarıq: could.',array['could','can','will','am'],1),
('ing6-journeys#6','ingilis-dili','ing-6-journeys',2,3,'«Drive» feili hansı nəqliyyat vasitəsinə aiddir?','Maşını sürürük: drive a car.',array['Maşına','Ata','Velosipedə','Qayığa'],1),
('ing6-journeys#7','ingilis-dili','ing-6-journeys',2,3,'«Ride a horse» nə deməkdir?','Ata minmək.',array['Ata minmək','Maşın sürmək','Qaçmaq','Uçmaq'],1),
('ing6-journeys#8','ingilis-dili','ing-6-journeys',2,3,'«Where did you go last year?» sualı nə haqqındadır?','Keçən ilki səyahət haqqındadır.',array['Keçmiş səyahət haqqında','Gələcək plan haqqında','Bu günkü dərs haqqında','Yemək haqqında'],1),
('ing6-journeys#9','ingilis-dili','ing-6-journeys',2,3,'«By bus» ifadəsi nəyi bildirir?','Avtobusla getməyi bildirir.',array['Avtobusla getməyi','Avtobusu almağı','Avtobusda yaşamağı','Avtobusu yumağı'],1),
('ing6-journeys#10','ingilis-dili','ing-6-journeys',2,3,'«Journey» sözünün mənası nədir?','Journey — səyahət, yol.',array['Səyahət','Jurnal','Gündəlik','Hakim'],1),
('ing6-heroes#1','ingilis-dili','ing-6-heroes',1,3,'«Brave» sifəti nə deməkdir?','Brave — cəsur.',array['Cəsur','Qorxaq','Tənbəl','Yorğun'],1),
('ing6-heroes#2','ingilis-dili','ing-6-heroes',1,3,'«Kind» sözünün mənası nədir?','Kind — mehriban, xeyirxah.',array['Mehriban','Qəzəbli','Paxıl','Kobud'],1),
('ing6-heroes#3','ingilis-dili','ing-6-heroes',3,3,'Past Continuous necə düzəlir?','was/were + feilin -ing forması.',array['was/were + feil-ing','do + feil','will + feil','have + feil-ed'],1),
('ing6-heroes#4','ingilis-dili','ing-6-heroes',2,3,'«She ___ reading a book at 5 oclock yesterday.»','She ilə Past Continuous: was reading.',array['was','were','is','do'],1),
('ing6-heroes#5','ingilis-dili','ing-6-heroes',2,3,'«They were ___ football when it started to rain.»','Past Continuous: were playing.',array['playing','play','played','plays'],1),
('ing6-heroes#6','ingilis-dili','ing-6-heroes',2,3,'«Scared» hansı hissi bildirir?','Scared — qorxmuş.',array['Qorxunu','Sevinci','Yorğunluğu','Aclığı'],1),
('ing6-heroes#7','ingilis-dili','ing-6-heroes',3,3,'«What were you doing at 7?» sualı hansı zamandadır?','Were + doing — Past Continuous.',array['Past Continuous','Present Simple','Past Simple','Gələcək zaman'],1),
('ing6-heroes#8','ingilis-dili','ing-6-heroes',2,3,'«Honest» sifəti necə insanı təsvir edir?','Honest — dürüst, düz danışan.',array['Dürüst insanı','Yalançı insanı','Tənbəl insanı','Qəzəbli insanı'],1),
('ing6-heroes#9','ingilis-dili','ing-6-heroes',2,3,'«Was he sleeping? — No, he ___.»','İnkar qısa cavab: was not.',array['was not','were not','did not','is not'],1),
('ing6-heroes#10','ingilis-dili','ing-6-heroes',1,3,'Qəhrəman (hero) adlandırdığımız insan nə edir?','Başqalarına kömək edir, cəsarət göstərir.',array['Başqalarına kömək edir','Yalnız yatır','Heç nə etmir','Qaçıb gizlənir'],1),
('ing6-ideas#1','ingilis-dili','ing-6-ideas',2,4,'«Invent» feili nə deməkdir?','Invent — ixtira etmək.',array['İxtira etmək','İtirmək','Silmək','Yemək'],1),
('ing6-ideas#2','ingilis-dili','ing-6-ideas',2,4,'«Discover» nə deməkdir?','Discover — kəşf etmək.',array['Kəşf etmək','Gizlətmək','Unutmaq','Satmaq'],1),
('ing6-ideas#3','ingilis-dili','ing-6-ideas',2,4,'«This book is ___.» (mənimki)','Yiyəlik əvəzliyi: mine.',array['mine','my','me','I'],1),
('ing6-ideas#4','ingilis-dili','ing-6-ideas',2,4,'«Yours» nə deməkdir?','Yours — səninki.',array['Səninki','Mənimki','Onunku','Bizimki'],1),
('ing6-ideas#5','ingilis-dili','ing-6-ideas',3,4,'«While I was cooking, the phone ___.» (Past Simple)','Qısa hadisə Past Simple ilə: rang.',array['rang','ring','ringing','rings'],1),
('ing6-ideas#6','ingilis-dili','ing-6-ideas',2,4,'«Technology» sözü nəyi əhatə edir?','Texniki vasitələri və ixtiraları.',array['Texniki vasitələri','Yalnız kitabları','Yalnız yeməkləri','Heyvanları'],1),
('ing6-ideas#7','ingilis-dili','ing-6-ideas',2,4,'«Design» feilinin mənası nədir?','Design — layihələndirmək, dizayn etmək.',array['Layihələndirmək','Dağıtmaq','Gözləmək','Oxumaq'],1),
('ing6-ideas#8','ingilis-dili','ing-6-ideas',3,4,'Uzun davam edən keçmiş hərəkəti hansı zaman bildirir?','Davamlı hərəkət — Past Continuous.',array['Past Continuous','Past Simple','Present Simple','Əmr forması'],1),
('ing6-ideas#9','ingilis-dili','ing-6-ideas',1,4,'«Screen» nə deməkdir?','Screen — ekran.',array['Ekran','Klaviatura','Printer','Naqil'],1),
('ing6-ideas#10','ingilis-dili','ing-6-ideas',1,4,'«Great idea!» ifadəsi nəyi bildirir?','Fikri bəyənməni bildirir: əla fikirdir!',array['Bəyənməni','Etirazı','Qorxunu','Yuxusuzluğu'],1),
('ing6-nature#1','ingilis-dili','ing-6-nature',1,4,'«Forest» nə deməkdir?','Forest — meşə.',array['Meşə','Dəniz','Səhra','Şəhər'],1),
('ing6-nature#2','ingilis-dili','ing-6-nature',1,4,'«River» sözünün mənası nədir?','River — çay.',array['Çay','Göl','Dağ','Ada'],1),
('ing6-nature#3','ingilis-dili','ing-6-nature',2,4,'«I want to protect nature.» — Danışan nə istəyir?','Protect — qorumaq: təbiəti qorumaq istəyir.',array['Təbiəti qorumaq','Təbiəti çirkləndirmək','Evdə qalmaq','Ağac kəsmək'],1),
('ing6-nature#4','ingilis-dili','ing-6-nature',1,4,'«Mountain» nə deməkdir?','Mountain — dağ.',array['Dağ','Düzənlik','Vadi','Sahil'],1),
('ing6-nature#5','ingilis-dili','ing-6-nature',3,4,'«Like, want, need» feilləri nəyi ifadə edir?','Bəyənməni, istəyi və ehtiyacı bildirir.',array['Bəyənmə, istək və ehtiyacı','Yalnız hərəkəti','Yalnız rəngi','Zamanı'],1),
('ing6-nature#6','ingilis-dili','ing-6-nature',2,4,'«We need clean air.» cümləsi nəyi bildirir?','Təmiz havaya ehtiyacımızı bildirir.',array['Təmiz havaya ehtiyacı','Yeməyə istəyi','Oyuna dəvəti','Yuxu vaxtını'],1),
('ing6-nature#7','ingilis-dili','ing-6-nature',2,4,'«Waterfall» nədir?','Waterfall — şəlalə.',array['Şəlalə','Quyu','Bulaq','Buzlaq'],1),
('ing6-nature#8','ingilis-dili','ing-6-nature',2,4,'«Wild animals» ifadəsi hansı heyvanları bildirir?','Wild — vəhşi (təbiətdə yaşayan) heyvanlar.',array['Vəhşi heyvanları','Ev heyvanlarını','Oyuncaqları','Balıqları'],1),
('ing6-nature#9','ingilis-dili','ing-6-nature',2,4,'«Desert» nə deməkdir?','Desert — səhra.',array['Səhra','Meşə','Bataqlıq','Çəmənlik'],1),
('ing6-nature#10','ingilis-dili','ing-6-nature',2,4,'«Do not drop litter!» xəbərdarlığı nə tələb edir?','Litter — zibil: zibil atmamağı tələb edir.',array['Zibil atmamağı','Sürətli qaçmağı','Səs salmamağı','Su içməməyi'],1),
('inf6-kompyuter#1','informatika','inf-6-kompyuter',2,1,'İkilik say sistemində hansı rəqəmlərdən istifadə olunur?','İkilik sistemdə yalnız 0 və 1 rəqəmləri var.',array['0 və 1','0-dan 9-a qədər','1 və 2','Yalnız 1'],1),
('inf6-kompyuter#2','informatika','inf-6-kompyuter',3,1,'1 meqabayt neçə kilobaytdır?','1 MB = 1024 KB.',array['1024','100','10','8'],1),
('inf6-kompyuter#3','informatika','inf-6-kompyuter',3,1,'«101» ikilik ədədi onluq say sistemində neçədir?','1·4 + 0·2 + 1·1 = 5.',array['5','101','3','6'],1),
('inf6-kompyuter#4','informatika','inf-6-kompyuter',2,1,'Hansı vahid daha böyükdür: meqabayt, yoxsa kilobayt?','1 MB = 1024 KB — meqabayt böyükdür.',array['Meqabayt','Kilobayt','Bərabərdirlər','Müqayisə olunmur'],1),
('inf6-kompyuter#5','informatika','inf-6-kompyuter',3,1,'Kompüterin daimi və müvəqqəti yaddaşları hansılardır?','Daimi — sərt disk, müvəqqəti — əməli yaddaş.',array['Sərt disk və əməli yaddaş','Monitor və maus','Printer və skaner','Dinamik və mikrofon'],1),
('inf6-kompyuter#6','informatika','inf-6-kompyuter',3,1,'Mətndəki hər simvol yaddaşda təxminən nə qədər yer tutur?','Bir simvol təxminən 1 bayt yer tutur.',array['1 bayt','1 kilobayt','1 meqabayt','100 bayt'],1),
('inf6-kompyuter#7','informatika','inf-6-kompyuter',3,1,'İkilik «1010» yazılışının onluq qarşılığını tapın.','1·8 + 0·4 + 1·2 + 0·1 = 10.',array['10','1010','4','20'],1),
('inf6-kompyuter#8','informatika','inf-6-kompyuter',2,1,'Verilənlərin ölçü vahidlərini kiçikdən böyüyə düzün.','bit < bayt < kilobayt < meqabayt.',array['bit, bayt, KB, MB','MB, KB, bayt, bit','bayt, bit, MB, KB','KB, MB, bit, bayt'],1),
('inf6-kompyuter#9','informatika','inf-6-kompyuter',2,1,'Monitordakı təsvir nələrdən yığılır?','Təsvir xırda nöqtələrdən — piksellərdən ibarətdir.',array['Piksellərdən','Hərflərdən','Damcılardan','Xətlərdən'],1),
('inf6-kompyuter#10','informatika','inf-6-kompyuter',3,1,'Kompüter söndürüləndə hansı yaddaşın məzmunu silinir?','Əməli (müvəqqəti) yaddaş təmizlənir.',array['Əməli yaddaşın','Sərt diskin','Fləş kartın','Heç birinin'],1),
('inf6-proqram-teminati#1','informatika','inf-6-proqram-teminati',2,2,'Proqram təminatı nədir?','Kompüterdə işləyən bütün proqramların məcmusudur.',array['Kompüter proqramlarının məcmusu','Kompüterin qurğuları','Elektrik naqilləri','Kağız sənədlər'],1),
('inf6-proqram-teminati#2','informatika','inf-6-proqram-teminati',1,2,'Proqramı başlatmağın üsullarından biri hansıdır?','Nişanı üzərində ikiqat klik etmək.',array['Nişan üzərində ikiqat klik','Monitoru silkələmək','Naqili çıxarmaq','Ekranı söndürmək'],1),
('inf6-proqram-teminati#3','informatika','inf-6-proqram-teminati',3,2,'Abzasın formatlanmasına nə daxildir?','Sətirlərin düzləndirilməsi və abzas boşluğu.',array['Düzləndirmə və abzas boşluğu','Faylın silinməsi','Kompüterin təmiri','Şəklin çəkilməsi'],1),
('inf6-proqram-teminati#4','informatika','inf-6-proqram-teminati',2,2,'Elektron təqdimatın əsas elementi nədir?','Təqdimat slaydlardan ibarətdir.',array['Slayd','Cədvəl','Qovluq','Parol'],1),
('inf6-proqram-teminati#5','informatika','inf-6-proqram-teminati',2,2,'Slayda nələri əlavə etmək olar?','Mətn, şəkil, cədvəl və digər obyektləri.',array['Mətn, şəkil, cədvəl','Yalnız mətn','Yalnız rəqəmlər','Heç nə'],1),
('inf6-proqram-teminati#6','informatika','inf-6-proqram-teminati',2,2,'Təqdimat zamanı slaydlar necə göstərilir?','Müəyyən olunmuş ardıcıllıqla bir-birini əvəz edir.',array['Müəyyən ardıcıllıqla','Təsadüfi','Hamısı bir yerdə','Göstərilmir'],1),
('inf6-proqram-teminati#7','informatika','inf-6-proqram-teminati',2,2,'Mətnin görünüşünü yaxşılaşdırmaq üçün nəyi dəyişmək olar?','Şrifti, ölçünü və rəngi dəyişmək olar.',array['Şrifti və ölçünü','Kompüterin markasını','Otağın rəngini','Heç nəyi'],1),
('inf6-proqram-teminati#8','informatika','inf-6-proqram-teminati',3,2,'Cədvəl şəklində informasiya modelinə misal hansıdır?','Dərs cədvəli informasiya modelidir.',array['Dərs cədvəli','Futbol topu','Qələm','Çanta'],1),
('inf6-proqram-teminati#9','informatika','inf-6-proqram-teminati',2,2,'Hansı proqram elektron təqdimat hazırlamaq üçündür?','PowerPoint təqdimat proqramıdır.',array['PowerPoint','Kalkulyator','Saat','Paint'],1),
('inf6-proqram-teminati#10','informatika','inf-6-proqram-teminati',3,2,'Əməliyyat sistemi ilə tətbiqi proqramın fərqi nədir?','ƏS kompüteri idarə edir, tətbiqi proqram konkret iş görür.',array['ƏS idarə edir, tətbiqi proqram konkret iş görür','Fərq yoxdur','Tətbiqi proqram kompüteri yandırır','ƏS yalnız oyundur'],1),
('inf6-alqoritm#1','informatika','inf-6-alqoritm',2,3,'Alqoritmin xassələrindən biri hansıdır?','Hər addım dəqiq və birmənalı olmalıdır — müəyyənlik.',array['Müəyyənlik (dəqiqlik)','Rənglilik','Uzunluq','Gizlilik'],1),
('inf6-alqoritm#2','informatika','inf-6-alqoritm',2,3,'Xətti alqoritm necə icra olunur?','Addımlar ardıcıl, hər biri bir dəfə icra olunur.',array['Addımlar ardıcıl, bir dəfə','Yalnız şərtlə','Sonsuz təkrarla','Sondan əvvələ'],1),
('inf6-alqoritm#3','informatika','inf-6-alqoritm',2,3,'Budaqlanan alqoritmdə nə baş verir?','Şərtdən asılı olaraq yol seçilir.',array['Şərtə görə yol seçilir','Addımlar silinir','Alqoritm dayanmır','Yalnız təkrar olur'],1),
('inf6-alqoritm#4','informatika','inf-6-alqoritm',2,3,'Dövri alqoritm nədir?','Addımların müəyyən sayda təkrarlandığı alqoritmdir.',array['Addımları təkrarlanan alqoritm','Tək addımlı alqoritm','Səhv alqoritm','Yazısız alqoritm'],1),
('inf6-alqoritm#5','informatika','inf-6-alqoritm',2,3,'«Əgər yağış yağırsa, çətir götür» — bu hansı alqoritm növüdür?','Şərt var — budaqlanan alqoritmdir.',array['Budaqlanan','Xətti','Dövri','Alqoritm deyil'],1),
('inf6-alqoritm#6','informatika','inf-6-alqoritm',2,3,'«Hasarın 20 taxtasını rənglə» məsələsi hansı alqoritmlə həll olunur?','Eyni iş 20 dəfə təkrarlanır — dövri alqoritm.',array['Dövri','Xətti','Budaqlanan','Heç biri'],1),
('inf6-alqoritm#7','informatika','inf-6-alqoritm',3,3,'Alqoritmin sonluluq xassəsi nə deməkdir?','Alqoritm sonlu sayda addımdan sonra bitməlidir.',array['Sonlu addımdan sonra bitməlidir','Heç vaxt bitməməlidir','Bir addımdan ibarət olmalıdır','Yazılmamalıdır'],1),
('inf6-alqoritm#8','informatika','inf-6-alqoritm',3,3,'Blok-sxemdə şərt (seçim) hansı fiqurla göstərilir?','Şərt romb fiqurunda yazılır.',array['Romb','Oval','Düzbucaqlı','Dairə'],1),
('inf6-alqoritm#9','informatika','inf-6-alqoritm',3,3,'Alqoritmin anlaşıqlılıq xassəsi nəyi tələb edir?','İcraçı hər əmri başa düşməlidir.',array['İcraçının əmrləri başa düşməsini','Rəngli yazılmasını','Uzun olmasını','Gizli qalmasını'],1),
('inf6-alqoritm#10','informatika','inf-6-alqoritm',2,3,'Alqoritmin icrasını kim və ya nə dayandıra bilər?','Son addım yerinə yetiriləndə alqoritm bitir.',array['Son addımın icrası','Küləyin əsməsi','Kağızın rəngi','Heç nə'],1),
('inf6-proqramlasdirma#1','informatika','inf-6-proqramlasdirma',3,3,'Proqramda dəyişən nədir?','Qiyməti dəyişə bilən adlandırılmış yaddaş sahəsidir.',array['Qiyməti dəyişən adlandırılmış sahə','Sabit ədəd','Kompüterin hissəsi','Şəkil faylı'],1),
('inf6-proqramlasdirma#2','informatika','inf-6-proqramlasdirma',2,3,'Scratch tipli mühitlərdə proqram nədən yığılır?','Hazır komanda bloklarından yığılır.',array['Bloklardan','Kağızdan','Naqillərdən','Şəkillərdən'],1),
('inf6-proqramlasdirma#3','informatika','inf-6-proqramlasdirma',2,3,'Proqramda «əgər … onda …» konstruksiyası nəyi həyata keçirir?','Şərtə görə seçimi (budaqlanmanı).',array['Seçimi (budaqlanmanı)','Təkrarı','Səs yazısını','Çapı'],1),
('inf6-proqramlasdirma#4','informatika','inf-6-proqramlasdirma',2,3,'Dövr (təkrarlama) əmri nə üçün istifadə olunur?','Eyni əmrləri dəfələrlə icra etmək üçün.',array['Əmrləri təkrarlamaq üçün','Proqramı silmək üçün','Ekranı söndürmək üçün','Fayl axtarmaq üçün'],1),
('inf6-proqramlasdirma#5','informatika','inf-6-proqramlasdirma',2,3,'Kvadrat çəkmək üçün «irəli get, sağa dön 90» əmrlərini neçə dəfə təkrarlamaq lazımdır?','Kvadratın 4 tərəfi var: 4 dəfə.',array['4','3','6','90'],1),
('inf6-proqramlasdirma#6','informatika','inf-6-proqramlasdirma',3,3,'ALPLogo-da «təkrar 6 [irəli 50 sağa 60]» proqramı hansı fiquru çəkər?','360 : 60 = 6 dönüş — altıbucaqlı alınır.',array['Altıbucaqlı','Kvadrat','Üçbucaq','Dairə'],1),
('inf6-proqramlasdirma#7','informatika','inf-6-proqramlasdirma',3,3,'Dəyişənə qiymət vermək əməliyyatı necə adlanır?','Qiymət vermə mənimsətmə adlanır.',array['Mənimsətmə','Silmə','Çapetmə','Axtarış'],1),
('inf6-proqramlasdirma#8','informatika','inf-6-proqramlasdirma',2,3,'Proqramlaşdırma mühitində musiqi necə səsləndirilir?','Not və səs əmrlərinin ardıcıllığı ilə.',array['Not əmrlərinin ardıcıllığı ilə','Mikrofonu sındırmaqla','Ekranı boyamaqla','Səsləndirmək olmur'],1),
('inf6-proqramlasdirma#9','informatika','inf-6-proqramlasdirma',2,3,'Proqramdakı səhv necə adlanır?','Proqram səhvi xəta (baq) adlanır.',array['Xəta (baq)','Blok','Slayd','Kursor'],1),
('inf6-proqramlasdirma#10','informatika','inf-6-proqramlasdirma',2,3,'Dövrün icrası nə vaxt dayanır?','Verilmiş təkrar sayı bitəndə dayanır.',array['Təkrar sayı bitəndə','Heç vaxt','Kompüter istəyəndə','Təsadüfi anda'],1),
('inf6-internet#1','informatika','inf-6-internet',2,4,'İnternetdə axtarış üçün açar sözlər necə seçilməlidir?','Qısa və dəqiq sözlər daha yaxşı nəticə verir.',array['Qısa və dəqiq','Çox uzun cümlələr','Təsadüfi hərflər','Yalnız rəqəmlər'],1),
('inf6-internet#2','informatika','inf-6-internet',1,4,'Elektron poçt ünvanında hansı işarə mütləq olur?','E-poçt ünvanında @ işarəsi olur.',array['@','%','&','№'],1),
('inf6-internet#3','informatika','inf-6-internet',2,4,'E-məktuba fayl əlavə etmək necə adlanır?','Əlavə olunan fayl qoşma (attachment) adlanır.',array['Qoşma (attachment)','Slayd','Blok','Kursor'],1),
('inf6-internet#4','informatika','inf-6-internet',3,4,'İnformasiya resursları ilə işin ilk mərhələsi nədir?','Əvvəlcə axtarışın məqsədi müəyyən edilir.',array['Məqsədi müəyyən etmək','Nəticəni çap etmək','Kompüteri söndürmək','Şəkil çəkmək'],1),
('inf6-internet#5','informatika','inf-6-internet',2,4,'Brauzerin ünvan sətrinə nə yazılır?','Saytın ünvanı (URL) yazılır.',array['Saytın ünvanı','Parol','Ev ünvanı','Telefon nömrəsi'],1),
('inf6-internet#6','informatika','inf-6-internet',2,4,'Naməlum göndəricidən gələn e-məktubun qoşmasını açmaq olarmı?','Olmaz — virus ola bilər.',array['Olmaz — virus ola bilər','Olar, təhlükəsizdir','Yalnız gecə olar','Yalnız şəkildirsə olar'],1),
('inf6-internet#7','informatika','inf-6-internet',3,4,'«WWW» qısaltması nəyi bildirir?','World Wide Web — Dünya hörümçək toru.',array['World Wide Web','Windows Word Work','Web Windows World','Wide Word Web'],1),
('inf6-internet#8','informatika','inf-6-internet',2,4,'E-məktubda «Mövzu» (Subject) sətri nə üçündür?','Məktubun nə haqqında olduğunu qısa bildirmək üçün.',array['Məktubun mövzusunu bildirmək üçün','Parol yazmaq üçün','Şəkil çəkmək üçün','Heç nə üçün'],1),
('inf6-internet#9','informatika','inf-6-internet',3,4,'Axtarış nəticələrindən etibarlı olanı necə seçmək olar?','Rəsmi və tanınmış mənbələrə üstünlük verilir.',array['Rəsmi mənbələrə üstünlük verməklə','İlk çıxana inanmaqla','Ən rəngli sayta girməklə','Təsadüfi seçməklə'],1),
('inf6-internet#10','informatika','inf-6-internet',2,4,'İnternet hesabının parolunu kimə demək olar?','Parol yalnız valideynlə bölüşülə bilər, başqa heç kimə.',array['Yalnız valideynə','Bütün dostlara','İnternetdəki tanışlara','Hamıya'],1),
('tarix6-ibtidai#1','tarix','tarix-6-ibtidai',1,1,'«E.ə.» qısaltması nə deməkdir?','Eramızdan əvvəl deməkdir.',array['Eramızdan əvvəl','Ən əvvəl','Erkən əsr','Əsrdən əvvəl'],1),
('tarix6-ibtidai#2','tarix','tarix-6-ibtidai',1,1,'100 il hansı zaman vahidini təşkil edir?','100 il bir əsrdir (yüzillik).',array['Əsr','Minillik','Onillik','Ay'],1),
('tarix6-ibtidai#3','tarix','tarix-6-ibtidai',2,1,'Azıx mağarasında tapılmış qədim insan necə adlandırılır?','Azıx mağarasının qədim sakini azıxantrop adlanır.',array['Azıxantrop','Neandertal','Firon','Sərkərdə'],1),
('tarix6-ibtidai#4','tarix','tarix-6-ibtidai',1,1,'İbtidai insanlar əvvəlcə harada yaşayırdılar?','İlk insanlar mağaralarda məskunlaşırdılar.',array['Mağaralarda','Çoxmərtəbəli binalarda','Gəmilərdə','Qalalarda'],1),
('tarix6-ibtidai#5','tarix','tarix-6-ibtidai',2,1,'Qobustan qayaüstü rəsmləri nəyi əks etdirir?','Qədim insanların həyatını: ov, rəqs, qayıqlar.',array['Qədim insanların həyatını','Müasir şəhərləri','Kosmik gəmiləri','Dəmir yollarını'],1),
('tarix6-ibtidai#6','tarix','tarix-6-ibtidai',2,1,'İbtidai insanlar niyə birlikdə (icma halında) yaşayırdılar?','Tək yaşamaq təhlükəli idi — birgə ovlanıb qorunurdular.',array['Birgə ovlanmaq və qorunmaq üçün','Şəhər salmaq üçün','Ticarət üçün','Yarış üçün'],1),
('tarix6-ibtidai#7','tarix','tarix-6-ibtidai',2,1,'Əkinçilik və maldarlıq yarananda insanların həyatında nə dəyişdi?','İnsanlar oturaq həyata keçdilər.',array['Oturaq həyata keçdilər','Mağaraya qayıtdılar','Ovçuluğu tam atdılar və ac qaldılar','Heç nə dəyişmədi'],1),
('tarix6-ibtidai#8','tarix','tarix-6-ibtidai',2,1,'Tunc dövrü hansı dövrdən sonra başlayır?','Əvvəl daş dövrü, sonra tunc dövrü gəlir.',array['Daş dövründən','Dəmir dövründən','Orta əsrlərdən','Müasir dövrdən'],1),
('tarix6-ibtidai#9','tarix','tarix-6-ibtidai',3,1,'Tarixi hadisələrin zamanını öyrənən sahə necə adlanır?','Zaman hesabını xronologiya öyrənir.',array['Xronologiya','Biologiya','Coğrafiya','Astronomiya'],1),
('tarix6-ibtidai#10','tarix','tarix-6-ibtidai',2,1,'Erkən dövlətlər hansı ehtiyacdan yaranırdı?','İdarəetmə və müdafiə ehtiyacından.',array['İdarəetmə və müdafiə ehtiyacından','Oyun üçün','Bayram keçirmək üçün','Təsadüfən'],1),
('tarix6-qedim-dovletler#1','tarix','tarix-6-qedim-dovletler',3,2,'Manna dövləti hansı ərazidə yaranmışdır?','Manna Urmiya gölü ətrafında yaranmışdır.',array['Urmiya gölü ətrafında','Xəzərin şimalında','Qara dəniz sahilində','Kür çayının mənbəyində'],1),
('tarix6-qedim-dovletler#2','tarix','tarix-6-qedim-dovletler',3,2,'Manna dövləti təxminən nə vaxt yaranmışdır?','Manna e.ə. IX əsrdə yaranmışdır.',array['E.ə. IX əsrdə','Eramızın X əsrində','1918-ci ildə','E.ə. I əsrdə'],1),
('tarix6-qedim-dovletler#3','tarix','tarix-6-qedim-dovletler',3,2,'Atropatena dövlətinin banisi kimdir?','Dövləti sərkərdə Atropat yaratmışdır.',array['Atropat','İranzu','Cavanşir','Babək'],1),
('tarix6-qedim-dovletler#4','tarix','tarix-6-qedim-dovletler',3,2,'Albaniyada IV əsrdə hansı din dövlət dini elan olundu?','Albaniyada xristianlıq qəbul edildi.',array['Xristianlıq','Buddizm','Şamanizm','Heç bir din'],1),
('tarix6-qedim-dovletler#5','tarix','tarix-6-qedim-dovletler',3,2,'Skiflər Azərbaycan ərazisində hansı qurumu yaratmışdılar?','Skif (işğuz) padşahlığı yaranmışdı.',array['Skif padşahlığı','Roma imperiyası','Misir fironluğu','Xanlıq'],1),
('tarix6-qedim-dovletler#6','tarix','tarix-6-qedim-dovletler',3,2,'Manna dövlətinin qüdrətli hökmdarı kim olmuşdur?','İranzu Mannanın qüdrətli hökmdarı idi.',array['İranzu','Atropat','Tomris','Nadir şah'],1),
('tarix6-qedim-dovletler#7','tarix','tarix-6-qedim-dovletler',2,2,'Qədim dövlətlərin əhalisi əsasən nə ilə məşğul olurdu?','Əkinçilik və maldarlıq əsas təsərrüfat sahələri idi.',array['Əkinçilik və maldarlıqla','Kosmik tədqiqatlarla','Kino çəkilişi ilə','Neft hasilatı ilə'],1),
('tarix6-qedim-dovletler#8','tarix','tarix-6-qedim-dovletler',3,2,'Atropatenanın paytaxtı hansı şəhər idi?','Paytaxt Qazaka şəhəri idi.',array['Qazaka','Bakı','Gəncə','Şamaxı'],1),
('tarix6-qedim-dovletler#9','tarix','tarix-6-qedim-dovletler',2,2,'Albaniya ərazisindən axan əsas çay hansı idi?','Kür çayı Albaniyanın əsas çayı idi.',array['Kür','Nil','Dunay','Volqa'],1),
('tarix6-qedim-dovletler#10','tarix','tarix-6-qedim-dovletler',3,2,'Azərbaycan e.ə. VI əsrdə hansı imperiyanın tərkibinə qatılmışdı?','Əhəmənilər imperiyasının tərkibinə qatılmışdı.',array['Əhəmənilər','Roma','Osmanlı','Monqol'],1),
('tarix6-erken-orta#1','tarix','tarix-6-erken-orta',2,3,'III əsrdə Azərbaycan hansı imperiyanın hakimiyyəti altına düşdü?','Azərbaycan Sasani imperiyasının tərkibinə qatıldı.',array['Sasanilər','Roma','Osmanlı','Britaniya'],1),
('tarix6-erken-orta#2','tarix','tarix-6-erken-orta',3,3,'Feodal münasibətləri nəyə əsaslanırdı?','İri torpaq sahibliyinə əsaslanırdı.',array['Torpaq sahibliyinə','Zavod istehsalına','İnternet ticarətinə','Dəniz quldurluğuna'],1),
('tarix6-erken-orta#3','tarix','tarix-6-erken-orta',2,3,'Sasani imperiyası hansı ölkənin ərazisində yaranmışdı?','Sasanilər dövləti İran ərazisində yaranmışdı.',array['İranda','Misirdə','Yunanıstanda','Hindistanda'],1),
('tarix6-erken-orta#4','tarix','tarix-6-erken-orta',2,3,'Feodalizmdə torpağın əsas sahibləri kimlər idi?','Torpaqlar feodallara məxsus idi.',array['Feodallar','Kəndlilər','Uşaqlar','Tacirlər'],1),
('tarix6-erken-orta#5','tarix','tarix-6-erken-orta',2,3,'Asılı kəndlilər feodal üçün nə edirdilər?','Torpağı becərir, vergi və mükəlləfiyyətlər ödəyirdilər.',array['Torpağı becərib vergi verirdilər','Dövləti idarə edirdilər','Orduya komandanlıq edirdilər','Heç nə etmirdilər'],1),
('tarix6-erken-orta#6','tarix','tarix-6-erken-orta',3,3,'Mehranilər sülaləsi harada hakimiyyətdə olmuşdur?','Mehranilər Albaniyada hakimiyyətdə idilər.',array['Albaniyada','Misirdə','Romada','Çində'],1),
('tarix6-erken-orta#7','tarix','tarix-6-erken-orta',3,3,'Cavanşir hansı dövlətin hökmdarı idi?','Cavanşir Albaniya dövlətinin hökmdarı idi.',array['Albaniyanın','Mannanın','Səfəvilərin','Osmanlının'],1),
('tarix6-erken-orta#8','tarix','tarix-6-erken-orta',3,3,'Sasanilər dövründə Azərbaycanda hansı din geniş yayılmışdı?','Zərdüştilik (atəşpərəstlik) yayılmışdı.',array['Zərdüştilik','Buddizm','Protestantlıq','Şintoizm'],1),
('tarix6-erken-orta#9','tarix','tarix-6-erken-orta',2,3,'Atəşgahlar nə idi?','Od (atəş) məbədləri idi.',array['Od məbədləri','Bazarlar','Məktəblər','Limanlar'],1),
('tarix6-erken-orta#10','tarix','tarix-6-erken-orta',3,3,'Sasani hakimiyyətinə qarşı üsyanların əsas səbəbi nə idi?','Ağır vergilər və zülm üsyanlara səbəb olurdu.',array['Ağır vergilər və zülm','Bayramların çoxluğu','Torpağın bolluğu','Səbəb yox idi'],1)
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
     and (ext_key like 'az6-%' or ext_key like 'ing6-%'
          or ext_key like 'inf6-%' or ext_key like 'tarix6-%');
  if n <> 240 then
    raise exception 'sinif6 suallari: 240 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'az6-%' or q.ext_key like 'ing6-%'
          or q.ext_key like 'inf6-%' or q.ext_key like 'tarix6-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az6-%' or ext_key like 'ing6-%'
      or ext_key like 'inf6-%' or ext_key like 'tarix6-%';
  if k <> 24 then
    raise exception 'movzu sayi 24 deyil: %', k;
  end if;
  raise notice '6-ci sinif banki: % sual, 24 movzu (az, ing, inf, tarix).', n;
end $$;
