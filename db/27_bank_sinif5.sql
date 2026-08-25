-- =====================================================================
--  27_bank_sinif5.sql : 5-CI SINIF - AZ DILI, INGILIS DILI,
--                       INFORMATIKA, AZERBAYCAN TARIXI
--
--  BU FAYL ELLE YAZILMIR - tools/sinif5.py yaradir:
--      python3 tools/sinif5.py
--
--  Az dili 8 + Ingilis dili 8 + Informatika 5 + Tarix 5
--  = 26 movzu x 10 = 260.  ext_key: az5-/ing5-/inf5-/tarix5-...
--  ON SERT: 25_movzular_orta5.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('az-dili','az-5-fonetika'),
                                ('ingilis-dili','ing-5-family'),
                                ('informatika','inf-5-internet'),
                                ('tarix','tarix-5-qedim'))
     having count(*) = 4) then
    raise exception 'ONCE 25_movzular_orta5.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'az5-%' or q.ext_key like 'ing5-%'
        or q.ext_key like 'inf5-%' or q.ext_key like 'tarix5-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('az5-fonetika#1','az-dili','az-5-fonetika',2,1,'Söz sonunda «b» hərfi ilə yazılan samit necə tələffüz olunur?','Söz sonunda cingiltili «b» kar qarşılığı «p» kimi deyilir: kitab — [kitap].',array['«p» kimi','«b» kimi','«m» kimi','Tələffüz olunmur'],1),
('az5-fonetika#2','az-dili','az-5-fonetika',2,1,'«Qonaq» sözünün sonundakı «q» səsi tələffüzdə necə deyilir?','Çoxhecalı sözlərin sonunda «q» səsi [x] kimi deyilir: [qonax].',array['«x» kimi','«q» kimi','«k» kimi','«ğ» kimi'],1),
('az5-fonetika#3','az-dili','az-5-fonetika',3,1,'«Dovşan» sözündə «ov» birləşməsi necə tələffüz olunur?','«Ov» birləşməsi uzun [o:] kimi deyilir: [do:şan].',array['Uzun «o» kimi','Yazıldığı kimi','«av» kimi','«uv» kimi'],1),
('az5-fonetika#4','az-dili','az-5-fonetika',2,1,'«Palıd» sözünün sonunda hansı səs tələffüz olunur?','Söz sonunda cingiltili «d» kar [t] kimi deyilir: [palıt].',array['[t]','[d]','[z]','[c]'],1),
('az5-fonetika#5','az-dili','az-5-fonetika',1,1,'Hecanı yaradan səslər hansılardır?','Sözdə neçə sait varsa, o qədər heca var — hecanı sait yaradır.',array['Saitlər','Samitlər','Kar samitlər','Cingiltili samitlər'],1),
('az5-fonetika#6','az-dili','az-5-fonetika',2,1,'Hansı sözdə qoşa samit yazılır?','«Səkkiz» sözü qoşa «k» ilə yazılır.',array['səkkiz','dəniz','qələm','kitab'],1),
('az5-fonetika#7','az-dili','az-5-fonetika',2,1,'«Çörək» sözünə «-i» şəkilçisi artıranda söz necə yazılır?','Saitlə başlanan şəkilçi artırılanda söz sonundakı «k» «y» ilə əvəz olunur: çörəyi.',array['çörəyi','çörəki','çörəgi','çörəqi'],1),
('az5-fonetika#8','az-dili','az-5-fonetika',2,1,'«Papaq» sözünə mənsubiyyət şəkilçisi artıranda hansı yazılış düzgündür?','Saitlə başlanan şəkilçidə söz sonundakı «q» «ğ» ilə əvəz olunur: papağı.',array['papağı','papaqı','papakı','papaxı'],1),
('az5-fonetika#9','az-dili','az-5-fonetika',3,1,'Hansı sözün deyilişi ilə yazılışı fərqlənir?','«Qonaq» [qonax] kimi deyilir; su, ana, gül yazıldığı kimi deyilir.',array['qonaq','su','ana','gül'],1),
('az5-fonetika#10','az-dili','az-5-fonetika',3,1,'Hansı sözdə sait uzun tələffüz olunur?','Bəzi alınma sözlərdə sait uzun deyilir: [a:lim].',array['alim','salam','qapı','dəniz'],1),
('az5-soz-menasi#1','az-dili','az-5-soz-menasi',2,1,'Sözün leksik mənası nədir?','Leksik məna sözün bildirdiyi əsas mənadır.',array['Sözün bildirdiyi əsas məna','Sözün şəkilçisi','Sözün heca sayı','Sözün yazılışı'],1),
('az5-soz-menasi#2','az-dili','az-5-soz-menasi',2,1,'«Dəmir iradə» birləşməsində «dəmir» sözü hansı mənadadır?','İradə metaldan ola bilməz — söz məcazi mənadadır (möhkəm).',array['Məcazi','Həqiqi','Heç bir mənada','Say mənasında'],1),
('az5-soz-menasi#3','az-dili','az-5-soz-menasi',2,1,'Hansı birləşmədə «şirin» sözü məcazi mənada işlənib?','Söhbətin dadı olmur — «şirin söhbət» məcazidir.',array['şirin söhbət','şirin çay','şirin alma','şirin konfet'],1),
('az5-soz-menasi#4','az-dili','az-5-soz-menasi',2,1,'Omonimlər necə sözlərdir?','Omonimlər deyilişi eyni, mənaları tamam fərqli sözlərdir.',array['Deyilişi eyni, mənaları fərqli','Mənaca yaxın','Əks mənalı','Eyni mənalı'],1),
('az5-soz-menasi#5','az-dili','az-5-soz-menasi',3,1,'«Yaz» sözünün omonimliyi hansı cütlükdə görünür?','«Yaz» həm fəsil adı, həm də yazmaq feilinin əmr formasıdır.',array['Fəsil adı və yazmaq əmri','Fəsil adı və ay adı','İki fəsil adı','İki feil forması'],1),
('az5-soz-menasi#6','az-dili','az-5-soz-menasi',2,1,'Çoxmənalı söz hansıdır?','«Dil» — insan orqanı, danışıq dili, açar dili və s.',array['dil','stol','dəftər','pəncərə'],1),
('az5-soz-menasi#7','az-dili','az-5-soz-menasi',2,1,'Hansı birləşmədə «qızıl» sözü HƏQİQİ mənada işlənib?','«Qızıl üzük» doğrudan qızıldan hazırlanır.',array['qızıl üzük','qızıl payız','qızıl əllər','qızıl söz'],1),
('az5-soz-menasi#8','az-dili','az-5-soz-menasi',3,1,'Qrammatik məna sözə nə ilə verilir?','Qrammatik məna şəkilçilərlə (cəm, hal, şəxs) yaranır.',array['Şəkilçilərlə','Vurğu ilə','Hərflərin sayı ilə','Sözün kökü ilə'],1),
('az5-soz-menasi#9','az-dili','az-5-soz-menasi',2,1,'Omonim cütü seçin.','«Bal» — şirin qida və «bal» — qiymət balı.',array['bal (qida) — bal (qiymət)','gözəl — qəşəng','isti — soyuq','ev — bina'],1),
('az5-soz-menasi#10','az-dili','az-5-soz-menasi',2,1,'Məcazi məna nitqdə əsasən nəyə xidmət edir?','Məcazlar nitqi obrazlı və təsirli edir.',array['Obrazlılığa və təsirliliyə','Sözü qısaltmağa','Yazını çətinləşdirməyə','Heç nəyə'],1),
('az5-soz-qurulusu#1','az-dili','az-5-soz-qurulusu',1,2,'Sözün dəyişməyən əsas hissəsi necə adlanır?','Sözün əsas hissəsi kökdür, şəkilçilər ona artırılır.',array['Kök','Şəkilçi','Heca','Sait'],1),
('az5-soz-qurulusu#2','az-dili','az-5-soz-qurulusu',3,2,'«Kitabça» sözündə «-ça» hansı şəkilçidir?','«-ça» yeni söz yaradır — leksik şəkilçidir.',array['Leksik','Qrammatik','Cəm','Hal'],1),
('az5-soz-qurulusu#3','az-dili','az-5-soz-qurulusu',3,2,'«Məktəblər» sözündə «-lər» hansı şəkilçidir?','«-lər» yalnız cəmlik bildirir — qrammatik şəkilçidir.',array['Qrammatik','Leksik','Söz yaradan','Kök'],1),
('az5-soz-qurulusu#4','az-dili','az-5-soz-qurulusu',2,2,'Ahəng qanunu nədir?','Sözdə qalın saitdən sonra qalın, incədən sonra incə sait gəlir.',array['Saitlərin bir-birini izləmə qaydası','Samitlərin düzülüşü','Cümlə qaydası','Durğu işarəsi qaydası'],1),
('az5-soz-qurulusu#5','az-dili','az-5-soz-qurulusu',3,2,'Hansı söz ahəng qanununa tabe DEYİL?','«İşıq» sözündə incə «i» ilə qalın «ı» yanaşı gəlir.',array['işıq','dəniz','yarpaq','ördək'],1),
('az5-soz-qurulusu#6','az-dili','az-5-soz-qurulusu',2,2,'Quruluşuna görə sadə söz hansıdır?','«Dağ» yalnız kökdən ibarətdir.',array['dağ','dağlıq','dəmiryol','gözlük'],1),
('az5-soz-qurulusu#7','az-dili','az-5-soz-qurulusu',2,2,'Düzəltmə söz hansıdır?','«Duzlu» = duz + leksik şəkilçi «-lu».',array['duzlu','duz','günəbaxan','yol'],1),
('az5-soz-qurulusu#8','az-dili','az-5-soz-qurulusu',2,2,'Mürəkkəb söz hansıdır?','«Günəbaxan» iki kökün birləşməsindən yaranıb.',array['günəbaxan','baxan','günlük','baxış'],1),
('az5-soz-qurulusu#9','az-dili','az-5-soz-qurulusu',3,2,'İki cür yazılan şəkilçi hansıdır?','«-lar, -lər» iki cür yazılan şəkilçidir; «-lıq, -lik, -luq, -lük» dörd cürdür.',array['-lar, -lər','-lıq, -lik, -luq, -lük','-çı, -çi, -çu, -çü','-sız, -siz, -suz, -süz'],1),
('az5-soz-qurulusu#10','az-dili','az-5-soz-qurulusu',1,2,'«Dənizçi» sözünün kökü hansıdır?','«-çi» şəkilçisini atsaq, kök «dəniz» qalar.',array['dəniz','dənizçi','çi','də'],1),
('az5-luget#1','az-dili','az-5-luget',1,2,'Sinonimlər necə sözlərdir?','Sinonimlər yazılışı fərqli, mənaca yaxın sözlərdir.',array['Mənaca yaxın','Əks mənalı','Deyilişi eyni','Mənasız'],1),
('az5-luget#2','az-dili','az-5-luget',1,2,'«Gözəl» sözünün sinonimi hansıdır?','Gözəl — qəşəng — göyçək mənaca yaxındır.',array['qəşəng','çirkin','böyük','gedir'],1),
('az5-luget#3','az-dili','az-5-luget',1,2,'«Dost» sözünün antonimi hansıdır?','Dostun əksi düşməndir.',array['düşmən','yoldaş','qonşu','qohum'],1),
('az5-luget#4','az-dili','az-5-luget',2,2,'Hansı cüt antonimdir?','Xeyir və şər əks mənalı sözlərdir.',array['xeyir — şər','igid — cəsur','ev — otaq','yol — cığır'],1),
('az5-luget#5','az-dili','az-5-luget',2,2,'Alınma sözlər hansılardır?','Başqa dillərdən dilimizə keçən sözlər alınma sözlərdir.',array['Başqa dillərdən keçən sözlər','Ən qədim sözlər','Uydurma sözlər','Yalnız adlar'],1),
('az5-luget#6','az-dili','az-5-luget',2,2,'Hansı söz alınma sözdür?','«Kompüter» ingilis dilindən keçib.',array['kompüter','su','daş','əl'],1),
('az5-luget#7','az-dili','az-5-luget',2,2,'Sözlərin mənasını öyrənmək üçün hansı lüğətdən istifadə olunur?','Sözlərin mənasını izahlı lüğət açıqlayır.',array['İzahlı lüğətdən','Telefon kitabçasından','Riyaziyyat cədvəlindən','Xəritədən'],1),
('az5-luget#8','az-dili','az-5-luget',1,2,'Lüğətdə sözlər hansı qaydada düzülür?','Lüğətlərdə sözlər əlifba sırası ilə verilir.',array['Əlifba sırası ilə','Uzunluğuna görə','Mənasına görə','Təsadüfi'],1),
('az5-luget#9','az-dili','az-5-luget',2,2,'«Cəsur» sözünə mənaca yaxın söz hansıdır?','Cəsur — igid — qoçaq sinonimlərdir.',array['igid','qorxaq','yavaş','zəif'],1),
('az5-luget#10','az-dili','az-5-luget',2,2,'Orfoqrafiya lüğəti nəyi göstərir?','Orfoqrafiya lüğəti sözlərin düzgün yazılışını verir.',array['Sözlərin düzgün yazılışını','Sözlərin mənasını','Şəhərlərin adlarını','Ədədlərin cədvəlini'],1),
('az5-isim#1','az-dili','az-5-isim',2,3,'Nitq hissələri hansı qruplara bölünür?','Nitq hissələri əsas və köməkçi olmaqla iki qrupdur.',array['Əsas və köməkçi','Uzun və qısa','Asan və çətin','Birinci və ikinci'],1),
('az5-isim#2','az-dili','az-5-isim',1,3,'Canlı və cansız varlıqların adını bildirən əsas nitq hissəsi hansıdır?','Varlıqların adını isim bildirir.',array['İsim','Sifət','Feil','Zərf'],1),
('az5-isim#3','az-dili','az-5-isim',3,3,'Toplu isim hansıdır?','«El» təklikdə çoxluq (insanlar toplusu) bildirir.',array['el','kitablar','ağac','qələm'],1),
('az5-isim#4','az-dili','az-5-isim',2,3,'«Kitabım» sözündə «-ım» şəkilçisi nəyi bildirir?','«-ım» I şəxsə aidliyi — mənsubiyyəti bildirir.',array['Mənsubiyyəti','Cəmliyi','Zamanı','İnkarlığı'],1),
('az5-isim#5','az-dili','az-5-isim',3,3,'«Məktəbimiz» sözü neçənci şəxsin mənsubiyyətini bildirir?','«-imiz» I şəxsin cəmini bildirir: bizim məktəb.',array['I şəxsin cəmini','II şəxsin təkini','III şəxsin cəmini','Heç bir şəxsi'],1),
('az5-isim#6','az-dili','az-5-isim',2,3,'«Xəzər, Nizami, Şuşa» isimlərinin ortaq cəhəti nədir?','Üçü də xüsusi isimdir və böyük hərflə yazılır.',array['Hamısı xüsusi isimdir','Hamısı ümumi isimdir','Hamısı toplu isimdir','Hamısı cəmdədir'],1),
('az5-isim#7','az-dili','az-5-isim',3,3,'«Atası» sözündə mənsubiyyət hansı şəxsə aiddir?','«-sı» III şəxsin təkini bildirir: onun atası.',array['III şəxsə','I şəxsə','II şəxsə','Heç bir şəxsə'],1),
('az5-isim#8','az-dili','az-5-isim',2,3,'Ümumi isim hansıdır?','«Şəhər» eyni cinsli əşyaların ümumi adıdır.',array['şəhər','Bakı','Gəncə','Şuşa'],1),
('az5-isim#9','az-dili','az-5-isim',2,3,'«Sürü» sözü hansı isim növüdür?','«Sürü» təklikdə çoxluq bildirir — toplu isimdir.',array['Toplu isim','Xüsusi isim','Cəm isim','Feil'],1),
('az5-isim#10','az-dili','az-5-isim',3,3,'İsim cümlədə ən çox hansı üzv olur?','İsim əşya bildirdiyi üçün ən çox mübtəda olur.',array['Mübtəda','Xəbər olmur','Yalnız təyin','Üzv olmur'],1),
('az5-sifet-say-feil#1','az-dili','az-5-sifet-say-feil',1,3,'Əşyanın əlamətini bildirən əsas nitq hissəsi hansıdır?','Əlaməti sifət bildirir.',array['Sifət','İsim','Say','Zərf'],1),
('az5-sifet-say-feil#2','az-dili','az-5-sifet-say-feil',1,3,'Miqdar və sıra bildirən nitq hissəsi necə adlanır?','Miqdar və sıranı say bildirir.',array['Say','Sifət','Feil','Əvəzlik'],1),
('az5-sifet-say-feil#3','az-dili','az-5-sifet-say-feil',2,3,'«Beşinci» sözü hansı say növüdür?','«-inci» şəkilçisi sıra bildirir.',array['Sıra sayı','Miqdar sayı','Kəsr sayı','Say deyil'],1),
('az5-sifet-say-feil#4','az-dili','az-5-sifet-say-feil',2,3,'Hansı söz miqdar sayıdır?','«On» miqdar bildirir; onuncu, birinci, sonuncu — sıra bildirir.',array['on','onuncu','birinci','sonuncu'],1),
('az5-sifet-say-feil#5','az-dili','az-5-sifet-say-feil',1,3,'Hərəkət bildirən əsas nitq hissəsi hansıdır?','Hərəkəti feil bildirir.',array['Feil','İsim','Sifət','Say'],1),
('az5-sifet-say-feil#6','az-dili','az-5-sifet-say-feil',3,3,'«Sabah» sözü hansı nitq hissəsidir?','«Sabah» hərəkətin zamanını bildirir — zərfdir.',array['Zərf','İsim','Sifət','Say'],1),
('az5-sifet-say-feil#7','az-dili','az-5-sifet-say-feil',2,3,'Zərf nəyi bildirir?','Zərf hərəkətin tərzini, yerini, zamanını bildirir.',array['Hərəkətin tərzini, yerini, zamanını','Əşyanın adını','Əşyanın sayını','Əşyanın sahibini'],1),
('az5-sifet-say-feil#8','az-dili','az-5-sifet-say-feil',2,3,'«Tez» sözü hərəkətin nəyini bildirir?','«Tez qaçdı» — hərəkətin tərzini bildirir.',array['Tərzini','Yerini','Səbəbini','Sahibini'],1),
('az5-sifet-say-feil#9','az-dili','az-5-sifet-say-feil',2,3,'«Danışdı» feili hansı zamandadır?','«-dı» şəkilçisi keçmiş zaman bildirir.',array['Keçmiş','İndiki','Gələcək','Zaman bildirmir'],1),
('az5-sifet-say-feil#10','az-dili','az-5-sifet-say-feil',2,3,'Gələcək zaman şəkilçisi hansıdır?','Gələcək zaman «-acaq, -əcək» ilə düzəlir.',array['-acaq, -əcək','-dı, -di','-ır, -ir','-mış, -miş'],1),
('az5-evezlik-tesrif#1','az-dili','az-5-evezlik-tesrif',2,4,'Məsdər hansı şəkilçi ilə düzəlir?','Məsdər «-maq, -mək» şəkilçisi ilə düzəlir.',array['-maq, -mək','-lar, -lər','-çı, -çi','-dı, -di'],1),
('az5-evezlik-tesrif#2','az-dili','az-5-evezlik-tesrif',2,4,'«Oxumaq» sözü feilin hansı formasıdır?','«-maq» şəkilçili forma məsdərdir.',array['Məsdər','Feili sifət','Feili bağlama','Əmr forması'],1),
('az5-evezlik-tesrif#3','az-dili','az-5-evezlik-tesrif',2,4,'Əvəzlik nəyi əvəz edir?','Əvəzlik ismi, sifəti, sayı əvəz edir.',array['İsmi, sifəti, sayı','Yalnız feili','Durğu işarələrini','Şəkilçiləri'],1),
('az5-evezlik-tesrif#4','az-dili','az-5-evezlik-tesrif',1,4,'«Mən, sən, o» hansı əvəzliklərdir?','Bunlar şəxs əvəzlikləridir.',array['Şəxs əvəzlikləri','İşarə əvəzlikləri','Sual əvəzlikləri','Qeyri-müəyyən əvəzliklər'],1),
('az5-evezlik-tesrif#5','az-dili','az-5-evezlik-tesrif',2,4,'«Bu, o, həmin» əvəzlikləri hansı növdəndir?','Bunlar işarə əvəzlikləridir.',array['İşarə','Şəxs','Sual','İnkar'],1),
('az5-evezlik-tesrif#6','az-dili','az-5-evezlik-tesrif',2,4,'«Kim?, nə?» əvəzlikləri hansı növə aiddir?','Sual bildirən əvəzliklər sual əvəzlikləridir.',array['Sual','Şəxs','İşarə','Təyin'],1),
('az5-evezlik-tesrif#7','az-dili','az-5-evezlik-tesrif',3,4,'Feili sifət nəyi bildirir?','Feili sifət hərəkətlə bağlı əlaməti bildirir.',array['Hərəkətlə bağlı əlaməti','Yalnız zamanı','Əşyanın sayını','Sözün kökünü'],1),
('az5-evezlik-tesrif#8','az-dili','az-5-evezlik-tesrif',3,4,'«Yazılmış məktub» birləşməsində «yazılmış» sözü nədir?','Hərəkətdən yaranan əlamət — feili sifətdir.',array['Feili sifət','Məsdər','Sifət deyil, isim','Zərf'],1),
('az5-evezlik-tesrif#9','az-dili','az-5-evezlik-tesrif',3,4,'Feili bağlama hansı şəkilçilərlə düzəlir?','Feili bağlama «-ıb, -ib, -ub, -üb», «-araq, -ərək» ilə düzəlir.',array['-ıb, -ib, -araq, -ərək','-maq, -mək','-lar, -lər','-lıq, -lik'],1),
('az5-evezlik-tesrif#10','az-dili','az-5-evezlik-tesrif',3,4,'Təsriflənməyən feil formaları hansılardır?','Məsdər, feili sifət və feili bağlama şəxsə görə dəyişmir.',array['Məsdər, feili sifət, feili bağlama','Keçmiş, indiki, gələcək','Tək və cəm','Əmr və xəbər'],1),
('az5-cumle#1','az-dili','az-5-cumle',2,4,'Söz birləşməsi nədir?','İki və daha artıq müstəqil sözün məna və qrammatik bağlılığıdır.',array['İki və artıq sözün məna bağlılığı','Bir sözün təkrarı','Hərflərin yığını','Şəkilçilər toplusu'],1),
('az5-cumle#2','az-dili','az-5-cumle',3,4,'Frazeoloji birləşmə hansıdır?','«Ağzını açmamaq» — susmaq mənasında sabit birləşmədir.',array['ağzını açmamaq','qapını açmaq','kitabı açmaq','pəncərəni açmaq'],1),
('az5-cumle#3','az-dili','az-5-cumle',3,4,'«Dabanına tüpürmək» frazeologizmi nə deməkdir?','Bu ifadə «sürətlə qaçmaq» mənasında işlənir.',array['Sürətlə qaçmaq','Yavaş getmək','Ayaqqabı geyinmək','Dayanmaq'],1),
('az5-cumle#4','az-dili','az-5-cumle',2,4,'Mübtəda hansı suallara cavab verir?','Mübtəda «kim? nə?» suallarına cavab verir.',array['Kim? Nə?','Necə?','Nə vaxt?','Harada?'],1),
('az5-cumle#5','az-dili','az-5-cumle',2,4,'Xəbər cümlədə nəyi bildirir?','Xəbər mübtəda haqqında məlumatı (hökmü) bildirir.',array['Mübtəda haqqında məlumatı','Yalnız zamanı','Sözün mənasını','Durğu işarəsini'],1),
('az5-cumle#6','az-dili','az-5-cumle',2,4,'Sadə cümlədə neçə qrammatik əsas olur?','Sadə cümlənin bir qrammatik əsası olur.',array['1','2','3','Heç biri'],1),
('az5-cumle#7','az-dili','az-5-cumle',2,4,'Mürəkkəb cümlə necə yaranır?','İki və daha artıq sadə cümlənin birləşməsindən yaranır.',array['Sadə cümlələrin birləşməsindən','Bir sözdən','Yalnız suallardan','Şəkilçilərdən'],1),
('az5-cumle#8','az-dili','az-5-cumle',3,4,'«Yağış yağdı və hava sərinləşdi» cümləsi hansı növdür?','İki qrammatik əsas var — mürəkkəb cümlədir.',array['Mürəkkəb','Sadə','Söz birləşməsi','Cümlə deyil'],1),
('az5-cumle#9','az-dili','az-5-cumle',3,4,'Cümlənin ikinci dərəcəli üzvləri hansılardır?','Tamamlıq, təyin və zərflik ikinci dərəcəli üzvlərdir.',array['Tamamlıq, təyin, zərflik','Mübtəda və xəbər','İsim və feil','Sait və samit'],1),
('az5-cumle#10','az-dili','az-5-cumle',3,4,'«Maraqlı kitab» birləşməsində əsas tərəf hansıdır?','Birləşmənin əsas (ikinci) tərəfi «kitab» sözüdür.',array['kitab','maraqlı','hər ikisi','heç biri'],1),
('ing5-who-am-i#1','ingilis-dili','ing-5-who-am-i',1,1,'Choose the correct sentence.','Düzgün forma: My name is Aysel.',array['My name is Aysel.','My name are Aysel.','Me name is Aysel.','My names is Aysel.'],1),
('ing5-who-am-i#2','ingilis-dili','ing-5-who-am-i',1,1,'How old ___ you?','«You» ilə «are» işlənir: How old are you?',array['are','is','am','be'],1),
('ing5-who-am-i#3','ingilis-dili','ing-5-who-am-i',1,1,'I ___ from Azerbaijan.','«I» ilə «am» işlənir: I am from Azerbaijan.',array['am','is','are','not'],1),
('ing5-who-am-i#4','ingilis-dili','ing-5-who-am-i',2,1,'Which word is a country?','Italy ölkə adıdır, qalanları dil və millət adlarıdır.',array['Italy','Italian','English','French'],1),
('ing5-who-am-i#5','ingilis-dili','ing-5-who-am-i',1,1,'What do we say when we meet someone?','Görüşəndə «Hello» deyilir.',array['Hello','Goodbye','Good night','Thanks'],1),
('ing5-who-am-i#6','ingilis-dili','ing-5-who-am-i',1,1,'«Eleven» sözü hansı ədədi bildirir?','Eleven — 11 deməkdir.',array['11','12','7','10'],1),
('ing5-who-am-i#7','ingilis-dili','ing-5-who-am-i',2,1,'What is the plural of «book»?','Cəm forma «-s» ilə düzəlir: books.',array['books','bookes','bookies','book'],1),
('ing5-who-am-i#8','ingilis-dili','ing-5-who-am-i',1,1,'___ is your name?','Ad soruşanda «What» işlənir.',array['What','Who','Where','When'],1),
('ing5-who-am-i#9','ingilis-dili','ing-5-who-am-i',1,1,'«Teacher» sözünün mənası nədir?','Teacher — müəllim deməkdir.',array['Müəllim','Şagird','Həkim','Sürücü'],1),
('ing5-who-am-i#10','ingilis-dili','ing-5-who-am-i',1,1,'Which word means «şagird»?','Şagird — student (pupil).',array['student','doctor','driver','singer'],1),
('ing5-everywhere#1','ingilis-dili','ing-5-everywhere',2,1,'How many letters are there in the English alphabet?','İngilis əlifbasında 26 hərf var.',array['26','32','24','30'],1),
('ing5-everywhere#2','ingilis-dili','ing-5-everywhere',2,1,'Which letter comes after «P»?','Əlifbada P-dən sonra Q gəlir.',array['Q','R','O','S'],1),
('ing5-everywhere#3','ingilis-dili','ing-5-everywhere',2,1,'Choose the correct spelling.','Düzgün yazılış: window.',array['window','windou','vindow','wındow'],1),
('ing5-everywhere#4','ingilis-dili','ing-5-everywhere',2,1,'People speak English in ___.','İngilis dili Böyük Britaniya və ABŞ-da əsas dildir.',array['the UK and the USA','only Azerbaijan','no country','only space'],1),
('ing5-everywhere#5','ingilis-dili','ing-5-everywhere',1,1,'When do we say «Good morning»?','«Good morning» səhər deyilir.',array['In the morning','At night','In the evening','After lunch'],1),
('ing5-everywhere#6','ingilis-dili','ing-5-everywhere',1,1,'What is «qapı» in English?','Qapı — door.',array['door','window','wall','floor'],1),
('ing5-everywhere#7','ingilis-dili','ing-5-everywhere',1,1,'Find the number «ten».','Ten — 10 deməkdir.',array['10','5','2','100'],1),
('ing5-everywhere#8','ingilis-dili','ing-5-everywhere',2,1,'Which word means «kitabxana»?','Library — kitabxana deməkdir.',array['library','hospital','market','garden'],1),
('ing5-everywhere#9','ingilis-dili','ing-5-everywhere',1,1,'How do you spell the word for «pişik»?','Pişik — cat: c-a-t.',array['c-a-t','k-a-t','c-e-t','s-a-t'],1),
('ing5-everywhere#10','ingilis-dili','ing-5-everywhere',2,1,'What do we answer to «Thank you»?','Təşəkkürə «You are welcome» cavabı verilir.',array['You are welcome.','Good night.','How are you?','It is a book.'],1),
('ing5-home#1','ingilis-dili','ing-5-home',2,2,'There ___ a sofa in the living room.','Təkdə «there is» işlənir.',array['is','are','am','have'],1),
('ing5-home#2','ingilis-dili','ing-5-home',2,2,'There ___ two beds in the room.','Cəmdə «there are» işlənir.',array['are','is','am','be'],1),
('ing5-home#3','ingilis-dili','ing-5-home',1,2,'We cook food in the ___.','Yemək mətbəxdə (kitchen) bişirilir.',array['kitchen','bedroom','bathroom','garage'],1),
('ing5-home#4','ingilis-dili','ing-5-home',1,2,'We sleep in the ___.','Yataq otağı — bedroom.',array['bedroom','kitchen','garden','hall'],1),
('ing5-home#5','ingilis-dili','ing-5-home',2,2,'Which word means «altında»?','Under — altında deməkdir.',array['under','on','in','next to'],1),
('ing5-home#6','ingilis-dili','ing-5-home',1,2,'«Bathroom» sözünün mənası nədir?','Bathroom — hamam otağı.',array['Hamam otağı','Qonaq otağı','Yataq otağı','Mətbəx'],1),
('ing5-home#7','ingilis-dili','ing-5-home',2,2,'Choose the word for «divar».','Divar — wall.',array['wall','roof','door','floor'],1),
('ing5-home#8','ingilis-dili','ing-5-home',2,2,'«On» sözü hansı mənanı bildirir?','On — üstündə deməkdir.',array['Üstündə','Altında','İçində','Yanında'],1),
('ing5-home#9','ingilis-dili','ing-5-home',2,2,'Choose the short answer: Is there a garden?','Qısa cavab: Yes, there is.',array['Yes, there is.','Yes, there are.','Yes, it does.','No, he is not.'],1),
('ing5-home#10','ingilis-dili','ing-5-home',2,2,'Which room has a TV and a sofa?','Televizor və divan qonaq otağında olur.',array['living room','bathroom','kitchen','garage'],1),
('ing5-family#1','ingilis-dili','ing-5-family',1,2,'My mother and my father are my ___.','Ana və ata birlikdə — parents.',array['parents','brothers','sisters','friends'],1),
('ing5-family#2','ingilis-dili','ing-5-family',2,2,'The mother of my mother is my ___.','Ananın anası — grandmother (nənə).',array['grandmother','aunt','sister','daughter'],1),
('ing5-family#3','ingilis-dili','ing-5-family',1,2,'«Qardaş» sözünün ingiliscə qarşılığı hansıdır?','Qardaş — brother.',array['brother','sister','father','uncle'],1),
('ing5-family#4','ingilis-dili','ing-5-family',2,2,'The brother of my father is my ___.','Atanın qardaşı — uncle (əmi).',array['uncle','cousin','grandfather','nephew'],1),
('ing5-family#5','ingilis-dili','ing-5-family',1,2,'«Sister» sözünün mənası nədir?','Sister — bacı deməkdir.',array['Bacı','Qardaş','Ana','Nənə'],1),
('ing5-family#6','ingilis-dili','ing-5-family',2,2,'Have you got a sister? — Yes, I ___.','Qısa cavab: Yes, I have.',array['have','am','is','does'],1),
('ing5-family#7','ingilis-dili','ing-5-family',2,2,'This is my brother. ___ name is Tural.','Oğlan üçün «his» işlənir.',array['His','Her','Its','My'],1),
('ing5-family#8','ingilis-dili','ing-5-family',2,2,'This is my sister. ___ name is Lale.','Qız üçün «her» işlənir.',array['Her','His','Our','Your'],1),
('ing5-family#9','ingilis-dili','ing-5-family',2,2,'Mother, father and two children — how many people are in the family?','2 + 2 = 4 — four.',array['Four','Three','Five','Two'],1),
('ing5-family#10','ingilis-dili','ing-5-family',2,2,'«Aunt» sözü kimi bildirir?','Aunt — xala və ya bibi deməkdir.',array['Xalanı və ya bibini','Əmini','Nənəni','Qonşunu'],1),
('ing5-daily-life#1','ingilis-dili','ing-5-daily-life',2,3,'I wake ___ at seven in the morning.','«Wake up» — yuxudan oyanmaq.',array['up','on','in','at'],1),
('ing5-daily-life#2','ingilis-dili','ing-5-daily-life',2,3,'She ___ breakfast every morning.','«She» ilə feil «-s» qəbul edir: has.',array['has','have','is','does not'],1),
('ing5-daily-life#3','ingilis-dili','ing-5-daily-life',2,3,'We go to school ___ the morning.','«In the morning» — səhər vaxtı.',array['in','on','at','under'],1),
('ing5-daily-life#4','ingilis-dili','ing-5-daily-life',1,3,'«Axşam» sözünün ingiliscə qarşılığı hansıdır?','Axşam — evening.',array['evening','morning','afternoon','night'],1),
('ing5-daily-life#5','ingilis-dili','ing-5-daily-life',2,3,'He ___ his teeth in the morning.','«He» ilə: brushes.',array['brushes','brush','brushing','is brush'],1),
('ing5-daily-life#6','ingilis-dili','ing-5-daily-life',2,3,'Sixty minutes make one ___.','60 dəqiqə bir saatdır: hour.',array['hour','day','week','minute'],1),
('ing5-daily-life#7','ingilis-dili','ing-5-daily-life',2,3,'«Nahar etmək» ingiliscə necə deyilir?','Nahar etmək — have lunch.',array['have lunch','have breakfast','go to bed','wash hands'],1),
('ing5-daily-life#8','ingilis-dili','ing-5-daily-life',2,3,'They ___ football after school.','«They» ilə feil dəyişmir: play.',array['play','plays','playing','is play'],1),
('ing5-daily-life#9','ingilis-dili','ing-5-daily-life',1,3,'«Get up» ifadəsinin mənası nədir?','Get up — yuxudan durmaq.',array['Yuxudan durmaq','Yemək yemək','Dərs oxumaq','Yatmaq'],1),
('ing5-daily-life#10','ingilis-dili','ing-5-daily-life',1,3,'How many days are there in a week?','Həftədə 7 gün var: seven.',array['Seven','Five','Six','Ten'],1),
('ing5-school#1','ingilis-dili','ing-5-school',1,3,'We write with a ___.','Qələmlə yazırıq: pen.',array['pen','bag','desk','chair'],1),
('ing5-school#2','ingilis-dili','ing-5-school',2,3,'«Dərslik» sözünün ingiliscə qarşılığı hansıdır?','Dərslik — textbook.',array['textbook','notebook','sketchbook','cookbook'],1),
('ing5-school#3','ingilis-dili','ing-5-school',2,3,'We do sums in the ___ lesson.','Hesablamalar riyaziyyat dərsində aparılır: Maths.',array['Maths','Music','Art','History'],1),
('ing5-school#4','ingilis-dili','ing-5-school',1,3,'«Open your books» nə deməkdir?','Open your books — kitablarınızı açın.',array['Kitablarınızı açın','Kitablarınızı bağlayın','Ayağa durun','Sakit olun'],1),
('ing5-school#5','ingilis-dili','ing-5-school',1,3,'The teacher writes on the ___.','Müəllim lövhədə yazır: board.',array['board','window','chair','bag'],1),
('ing5-school#6','ingilis-dili','ing-5-school',2,3,'Which school subject is «rəsm»?','Rəsm dərsi — Art.',array['Art','Maths','PE','English'],1),
('ing5-school#7','ingilis-dili','ing-5-school',1,3,'We put our books in a ___.','Kitablar çantaya qoyulur: bag.',array['bag','cup','shoe','clock'],1),
('ing5-school#8','ingilis-dili','ing-5-school',2,3,'«Ruler» nə üçün istifadə olunur?','Ruler — xətkeş, xətt çəkmək üçündür.',array['Xətt çəkmək üçün','Yemək üçün','Oynamaq üçün','Silmək üçün'],1),
('ing5-school#9','ingilis-dili','ing-5-school',2,3,'Our English lesson is ___ Monday.','Günlərlə «on» işlənir: on Monday.',array['on','in','at','under'],1),
('ing5-school#10','ingilis-dili','ing-5-school',2,3,'What do we say to come into the classroom?','İcazə istəyəndə: May I come in?',array['May I come in?','Good night!','See you!','It is a pen.'],1),
('ing5-clothes#1','ingilis-dili','ing-5-clothes',1,4,'She is wearing a red ___. (don)','Don — dress.',array['dress','sock','glove','boot'],1),
('ing5-clothes#2','ingilis-dili','ing-5-clothes',1,4,'«Papaq» sözünün ingiliscə qarşılığı hansıdır?','Papaq — hat.',array['hat','coat','shirt','skirt'],1),
('ing5-clothes#3','ingilis-dili','ing-5-clothes',2,4,'What ___ he wearing?','İndiki davamedici zaman: What is he wearing?',array['is','are','am','do'],1),
('ing5-clothes#4','ingilis-dili','ing-5-clothes',2,4,'In winter we wear a warm ___. (palto)','Palto — coat.',array['coat','T-shirt','dress','cap'],1),
('ing5-clothes#5','ingilis-dili','ing-5-clothes',1,4,'«Shoes» sözünün mənası nədir?','Shoes — ayaqqabı.',array['Ayaqqabı','Corab','Köynək','Şalvar'],1),
('ing5-clothes#6','ingilis-dili','ing-5-clothes',2,4,'___ they wearing school uniforms?','«They» ilə sual «Are» ilə başlayır.',array['Are','Is','Am','Does'],1),
('ing5-clothes#7','ingilis-dili','ing-5-clothes',2,4,'We wear ___ on our hands in winter.','Əllərə əlcək taxılır: gloves.',array['gloves','socks','hats','boots'],1),
('ing5-clothes#8','ingilis-dili','ing-5-clothes',1,4,'«T-shirt» nədir?','T-shirt — qısaqol köynək.',array['Qısaqol köynək','Qış paltosu','İdman ayaqqabısı','Baş örtüyü'],1),
('ing5-clothes#9','ingilis-dili','ing-5-clothes',2,4,'He is wearing blue ___. (şalvar)','Şalvar — trousers.',array['trousers','gloves','scarves','hats'],1),
('ing5-clothes#10','ingilis-dili','ing-5-clothes',2,4,'Which one do we wear on our feet?','Ayağa corab geyinilir: socks.',array['socks','hats','scarves','rings'],1),
('ing5-movement#1','ingilis-dili','ing-5-movement',2,4,'I can ___ a bike.','Velosiped sürmək — ride a bike.',array['ride','eat','read','sing'],1),
('ing5-movement#2','ingilis-dili','ing-5-movement',1,4,'«Üzmək» feilinin ingiliscə qarşılığı hansıdır?','Üzmək — swim.',array['swim','run','jump','fly'],1),
('ing5-movement#3','ingilis-dili','ing-5-movement',2,4,'Can you play chess? — Yes, I ___.','Qısa cavab: Yes, I can.',array['can','am','have','play'],1),
('ing5-movement#4','ingilis-dili','ing-5-movement',2,4,'We play ___ with a racket.','Raketka ilə tennis oynanılır.',array['tennis','football','chess','golf'],1),
('ing5-movement#5','ingilis-dili','ing-5-movement',1,4,'«Run» feilinin mənası nədir?','Run — qaçmaq.',array['Qaçmaq','Oturmaq','Yatmaq','Yazmaq'],1),
('ing5-movement#6','ingilis-dili','ing-5-movement',1,4,'Birds can ___.','Quşlar uça bilir: fly.',array['fly','read','drive','write'],1),
('ing5-movement#7','ingilis-dili','ing-5-movement',2,4,'Fish cannot ___.','Balıqlar üzə bilir, amma yeriyə bilmir: walk.',array['walk','swim','eat','move'],1),
('ing5-movement#8','ingilis-dili','ing-5-movement',1,4,'Which verb means «tullanmaq»?','Tullanmaq — jump.',array['jump','sit','sleep','stand'],1),
('ing5-movement#9','ingilis-dili','ing-5-movement',1,4,'We play football with a ___.','Futbol topla oynanılır: ball.',array['ball','racket','book','pen'],1),
('ing5-movement#10','ingilis-dili','ing-5-movement',2,4,'«Get moving» ifadəsi bizi nəyə çağırır?','Get moving — hərəkətə başla!',array['Hərəkətə','Yuxuya','Yeməyə','Susmağa'],1),
('inf5-informasiya#1','informatika','inf-5-informasiya',2,1,'İnformasiyanın kodlaşdırılması nədir?','Məlumatın şərti işarələrlə göstərilməsidir.',array['Məlumatın şərti işarələrlə göstərilməsi','Məlumatın silinməsi','Kompüterin təmiri','Şəklin çəkilməsi'],1),
('inf5-informasiya#2','informatika','inf-5-informasiya',2,1,'Morze əlifbası nəyə misaldır?','Nöqtə və tire ilə yazı — kodlaşdırmadır.',array['Kodlaşdırmaya','Rəsm əsərinə','Musiqiyə','İdmana'],1),
('inf5-informasiya#3','informatika','inf-5-informasiya',2,1,'İnformasiyanın ən kiçik ölçü vahidi hansıdır?','Ən kiçik vahid bitdir.',array['Bit','Bayt','Metr','Litr'],1),
('inf5-informasiya#4','informatika','inf-5-informasiya',2,1,'1 bayt neçə bitdir?','1 bayt = 8 bit.',array['8','2','10','100'],1),
('inf5-informasiya#5','informatika','inf-5-informasiya',3,1,'İnformasiya modeli nədir?','Obyektin vacib əlamətlərini əks etdirən təsviridir.',array['Obyektin vacib əlamətlərinin təsviri','Obyektin özü','Kompüter qurğusu','Oyun proqramı'],1),
('inf5-informasiya#6','informatika','inf-5-informasiya',2,1,'Xəritə nəyin informasiya modelidir?','Xəritə yer səthinin modelidir.',array['Yer səthinin','Kompüterin','İnsanın','Kitabın'],1),
('inf5-informasiya#7','informatika','inf-5-informasiya',3,1,'Kompüterdə informasiya hansı işarələrlə saxlanılır?','Kompüter ikilik say sistemində — 0 və 1 ilə işləyir.',array['0 və 1 ilə','Hərflərlə','Notlarla','Rənglərlə'],1),
('inf5-informasiya#8','informatika','inf-5-informasiya',2,1,'Hansı vahid daha böyükdür: bit, yoxsa bayt?','1 bayt 8 bitə bərabərdir — bayt böyükdür.',array['Bayt','Bit','Bərabərdirlər','Müqayisə olunmur'],1),
('inf5-informasiya#9','informatika','inf-5-informasiya',2,1,'Mətn informasiyası nə ilə kodlaşdırılır?','Mətn əlifbanın hərfləri ilə yazılır (kodlaşdırılır).',array['Hərflərlə','Yalnız şəkillərlə','Yalnız səslə','Qoxu ilə'],1),
('inf5-informasiya#10','informatika','inf-5-informasiya',3,1,'1 kilobayt neçə baytdır?','1 KB = 1024 bayt.',array['1024','100','10','8'],1),
('inf5-kompyuter#1','informatika','inf-5-kompyuter',2,2,'Fayl nədir?','Yaddaşda ad altında saxlanılan məlumat toplusudur.',array['Ad altında saxlanılan məlumat','Kompüterin hissəsi','Elektrik naqili','Ekranın rəngi'],1),
('inf5-kompyuter#2','informatika','inf-5-kompyuter',1,2,'Faylları qruplaşdırmaq üçün nədən istifadə olunur?','Fayllar qovluqlarda saxlanılır.',array['Qovluqdan','Printerdən','Dinamikdən','Mausdan'],1),
('inf5-kompyuter#3','informatika','inf-5-kompyuter',2,2,'İş masasındakı kiçik şəkilciklər necə adlanır?','Proqram və faylların işarələri nişan (ikon) adlanır.',array['Nişanlar (ikonlar)','Pəncərələr','Fayllar','Düymələr'],1),
('inf5-kompyuter#4','informatika','inf-5-kompyuter',1,2,'Proqram pəncərəsini bağlamaq üçün hansı düymə basılır?','Pəncərənin künclərindəki X (bağla) düyməsi.',array['X (bağla) düyməsi','Boşluq düyməsi','Rəqəm düyməsi','Ok düyməsi'],1),
('inf5-kompyuter#5','informatika','inf-5-kompyuter',2,2,'Menyu nədir?','Menyu əmrlərin siyahısıdır.',array['Əmrlərin siyahısı','Şəkil növü','Oyun adı','Qurğu adı'],1),
('inf5-kompyuter#6','informatika','inf-5-kompyuter',3,2,'Əməli yaddaş nə üçündür?','İşlək proqramları müvəqqəti saxlamaq üçündür.',array['İşlək proqramları müvəqqəti saxlamaq üçün','Şəkil çəkmək üçün','Səs ucaltmaq üçün','Ekranı təmizləmək üçün'],1),
('inf5-kompyuter#7','informatika','inf-5-kompyuter',2,2,'Məlumatı uzun müddət saxlayan qurğu hansıdır?','Sərt disk məlumatı daimi saxlayır.',array['Sərt disk','Monitor','Maus','Mikrofon'],1),
('inf5-kompyuter#8','informatika','inf-5-kompyuter',2,2,'Pəncərəni bütün ekrana açan düymə necə adlanır?','Böyütmə (maximize) düyməsi pəncərəni tam açır.',array['Böyütmə düyməsi','Bağlama düyməsi','Silmə düyməsi','Enter düyməsi'],1),
('inf5-kompyuter#9','informatika','inf-5-kompyuter',3,2,'Faylın adında nöqtədən sonra yazılan hissə necə adlanır?','Nöqtədən sonrakı hissə genişlənmə (uzantı) adlanır.',array['Genişlənmə (uzantı)','Qovluq','Parol','Nişan'],1),
('inf5-kompyuter#10','informatika','inf-5-kompyuter',3,2,'Kompüteri idarə edən əsas proqram necə adlanır?','Bütün işi əməliyyat sistemi idarə edir.',array['Əməliyyat sistemi','Oyun proqramı','Şəkil redaktoru','Kalkulyator'],1),
('inf5-tetbiqi#1','informatika','inf-5-tetbiqi',2,3,'Şəklin bir hissəsini köçürmək üçün əvvəlcə nə etmək lazımdır?','Əvvəlcə fraqment seçilir, sonra köçürülür.',array['Fraqmenti seçmək','Şəkli silmək','Proqramı bağlamaq','Printeri qoşmaq'],1),
('inf5-tetbiqi#2','informatika','inf-5-tetbiqi',1,3,'Qrafik redaktorda düz xətt hansı alətlə çəkilir?','Xətt aləti düz xətt çəkir.',array['Xətt aləti ilə','Silgi ilə','Mətn aləti ilə','Ləkə aləti ilə'],1),
('inf5-tetbiqi#3','informatika','inf-5-tetbiqi',2,3,'Şəklin fraqmentini döndərmək mümkündürmü?','Seçilmiş fraqmenti döndərmək və əymək olar.',array['Bəli, seçib döndərmək olar','Xeyr, heç vaxt','Yalnız çap edəndə','Yalnız silərkən'],1),
('inf5-tetbiqi#4','informatika','inf-5-tetbiqi',2,3,'Mətnin formatlanması nədir?','Mətnin görkəminin (şrift, ölçü, rəng) dəyişdirilməsidir.',array['Mətnin görkəminin dəyişdirilməsi','Mətnin silinməsi','Kompüterin söndürülməsi','Şəklin çəkilməsi'],1),
('inf5-tetbiqi#5','informatika','inf-5-tetbiqi',2,3,'Yazını qalın etmək üçün hansı düymədən istifadə olunur?','B (Bold) düyməsi yazını qalın edir.',array['B (Bold)','X (bağla)','Esc','Tab'],1),
('inf5-tetbiqi#6','informatika','inf-5-tetbiqi',1,3,'Mətn sənədinə şəkil əlavə etmək olarmı?','Bəli, şəkilli mətn yaratmaq mümkündür.',array['Bəli, olar','Xeyr, olmaz','Yalnız qışda','Yalnız printerlə'],1),
('inf5-tetbiqi#7','informatika','inf-5-tetbiqi',1,3,'Silgi aləti nə edir?','Silgi şəklin lazımsız hissəsini silir.',array['Şəklin hissəsini silir','Şəkli böyüdür','Səs yazır','Faylı bağlayır'],1),
('inf5-tetbiqi#8','informatika','inf-5-tetbiqi',2,3,'Mətndə bir sözü seçdirmək üçün nə edilir?','Söz mausla sürüşdürülərək seçdirilir.',array['Mausla üzərindən sürüşdürülür','Kompüter söndürülür','Printer qoşulur','Ekran silinir'],1),
('inf5-tetbiqi#9','informatika','inf-5-tetbiqi',2,3,'Rəngləmə («çəllək») aləti nə üçündür?','Qapalı sahəni seçilmiş rənglə doldurur.',array['Qapalı sahəni rənglə doldurmaq üçün','Mətn yazmaq üçün','Faylı silmək üçün','Səsi artırmaq üçün'],1),
('inf5-tetbiqi#10','informatika','inf-5-tetbiqi',2,3,'Hazır şəkli sənədə haradan əlavə etmək olar?','Yaddaşdakı fayldan əlavə etmək olar.',array['Fayldan (yaddaşdan)','Printerdən','Dinamikdən','Klaviaturanın altından'],1),
('inf5-alqoritm#1','informatika','inf-5-alqoritm',2,4,'Alqoritmi hansı üsullarla təqdim etmək olar?','Sözlə, cədvəllə və blok-sxemlə təqdim olunur.',array['Sözlə, cədvəllə, blok-sxemlə','Yalnız şəkillə','Yalnız musiqi ilə','Heç cür'],1),
('inf5-alqoritm#2','informatika','inf-5-alqoritm',3,4,'Blok-sxemdə alqoritmin başlanğıcı hansı fiqurla göstərilir?','Başlanğıc və son oval fiqurla göstərilir.',array['Oval','Düzbucaqlı','Romb','Üçbucaq'],1),
('inf5-alqoritm#3','informatika','inf-5-alqoritm',2,4,'Proqram nədir?','Kompüterin başa düşdüyü dildə yazılmış alqoritmdir.',array['Kompüter dilində yazılmış alqoritm','Kompüterin hissəsi','Elektrik cihazı','Oyun qaydası'],1),
('inf5-alqoritm#4','informatika','inf-5-alqoritm',2,4,'«Bağa» icraçısı ekranda nə edir?','Bağa hərəkət edərək arxasınca xətt çəkir.',array['Hərəkət edib xətt çəkir','Mahnı oxuyur','Fayl silir','Mətn yazır'],1),
('inf5-alqoritm#5','informatika','inf-5-alqoritm',3,4,'Bağa 100 addım irəli gedib 90° dönməyi 4 dəfə təkrarlasa, hansı fiqur alınar?','Dörd bərabər tərəf və dörd düz bucaq — kvadrat.',array['Kvadrat','Üçbucaq','Dairə','Beşbucaqlı'],1),
('inf5-alqoritm#6','informatika','inf-5-alqoritm',2,4,'Proqramda səhv olarsa, kompüter nə edər?','Kompüter yazılanı icra edir — səhv nəticə alınar.',array['Səhv nəticə verər','Səhvi özü düzəldər','Kompüter əriyər','Heç nə dəyişməz'],1),
('inf5-alqoritm#7','informatika','inf-5-alqoritm',3,4,'Blok-sxemdə icra addımı (əməliyyat) hansı fiqurda yazılır?','Əməliyyatlar düzbucaqlıda yazılır.',array['Düzbucaqlıda','Ovalda','Dairədə','Ulduzda'],1),
('inf5-alqoritm#8','informatika','inf-5-alqoritm',2,4,'Bağaya «sağa dön 90» əmri verildi. O nə edəcək?','Bağa yerindəcə 90 dərəcə sağa dönəcək.',array['90 dərəcə sağa dönəcək','100 addım gedəcək','Xətti siləcək','Dayanacaq'],1),
('inf5-alqoritm#9','informatika','inf-5-alqoritm',2,4,'Kompüter proqramları hansı dildə yazılır?','Proqramlar proqramlaşdırma dillərində yazılır.',array['Proqramlaşdırma dilində','Yalnız ana dilində','Heç bir dildə','Quş dilində'],1),
('inf5-alqoritm#10','informatika','inf-5-alqoritm',3,4,'Bağa üçbucaq çəkmək üçün hər dönüşdə neçə dərəcə dönməlidir?','Tam dövr 360°; üç dönüş: 360 : 3 = 120°.',array['120°','90°','60°','180°'],1),
('inf5-internet#1','informatika','inf-5-internet',1,4,'İnternet nədir?','Dünyadakı kompüterləri birləşdirən ümumdünya şəbəkəsidir.',array['Ümumdünya kompüter şəbəkəsi','Bir kompüterin adı','Oyun proqramı','Televiziya kanalı'],1),
('inf5-internet#2','informatika','inf-5-internet',2,4,'Veb-səhifələri açmaq üçün hansı proqramdan istifadə olunur?','Veb-səhifələr brauzerdə açılır.',array['Brauzerdən','Kalkulyatordan','Şəkil redaktorundan','Saatdan'],1),
('inf5-internet#3','informatika','inf-5-internet',2,4,'İnternetdə məlumat tapmaq üçün nədən istifadə olunur?','Axtarış sistemləri məlumatı tapmağa kömək edir.',array['Axtarış sistemindən','Printerdən','Silgidən','Tərəzidən'],1),
('inf5-internet#4','informatika','inf-5-internet',2,4,'Saytın internetdəki ünvanı necə adlanır?','Hər saytın öz internet ünvanı (URL) var.',array['İnternet ünvanı (URL)','Ev ünvanı','Poçt qutusu','Telefon nömrəsi'],1),
('inf5-internet#5','informatika','inf-5-internet',3,4,'«Dünya hörümçək toru» (WWW) nədir?','Bir-birinə keçidlərlə bağlı veb-səhifələr sistemidir.',array['Bir-birinə bağlı veb-səhifələr sistemi','Hörümçəklərin yuvası','Kompüter oyunu','Elektrik şəbəkəsi'],1),
('inf5-internet#6','informatika','inf-5-internet',2,4,'İnternetdə tanımadığın adama hansı məlumatı vermək OLMAZ?','Ev ünvanı və şəxsi məlumatlar gizli saxlanmalıdır.',array['Ev ünvanını və şəxsi məlumatları','Sevimli rəngini','Sevimli fəslini','Sevimli kitabının adını'],1),
('inf5-internet#7','informatika','inf-5-internet',2,4,'İnformasiya resursu nədir?','Məlumat mənbəyidir: kitabxana, sayt, arxiv.',array['Məlumat mənbəyi','Elektrik mənbəyi','Su mənbəyi','İşıq lampası'],1),
('inf5-internet#8','informatika','inf-5-internet',2,4,'Elektron poçt nə üçündür?','İnternetlə məktub göndərib almaq üçündür.',array['Məktub göndərib almaq üçün','Paltar yumaq üçün','Şəkil çəkmək üçün','Fayl silmək üçün'],1),
('inf5-internet#9','informatika','inf-5-internet',2,4,'Keçid (link) nə edir?','Klik ediləndə başqa səhifəyə aparır.',array['Başqa səhifəyə aparır','Kompüteri söndürür','Şəkli silir','Səsi artırır'],1),
('inf5-internet#10','informatika','inf-5-internet',2,4,'İnternetdəki hər məlumata inanmaq olarmı?','Xeyr — məlumatın mənbəyini yoxlamaq lazımdır.',array['Xeyr, mənbəni yoxlamaq lazımdır','Bəli, hamısı doğrudur','Yalnız gecə olar','Yalnız şəkillərə inanmaq olar'],1),
('tarix5-qedim#1','tarix','tarix-5-qedim',1,1,'Tarix elmi nəyi öyrənir?','Tarix bəşəriyyətin keçmişini öyrənir.',array['Keçmişi','Yalnız gələcəyi','Bitkiləri','Ulduzları'],1),
('tarix5-qedim#2','tarix','tarix-5-qedim',2,1,'Keçmişdən qalan maddi abidələri qazıntılarla öyrənən alimlər necə adlanır?','Qazıntı aparan alimlər arxeoloqlardır.',array['Arxeoloqlar','Coğrafiyaçılar','Riyaziyyatçılar','Həkimlər'],1),
('tarix5-qedim#3','tarix','tarix-5-qedim',2,1,'Azərbaycan ərazisində ilk insan məskənlərindən biri hansıdır?','Azıx mağarası ən qədim insan düşərgələrindəndir.',array['Azıx mağarası','Qız qalası','Şəki sarayı','İçərişəhər'],1),
('tarix5-qedim#4','tarix','tarix-5-qedim',1,1,'İlk əmək alətləri hansı materialdan hazırlanırdı?','Ən qədim alətlər daşdan idi.',array['Daşdan','Plastikdən','Şüşədən','Poladdan'],1),
('tarix5-qedim#5','tarix','tarix-5-qedim',2,1,'Ən qədim insanların ilk məşğuliyyətləri nə idi?','Qədim insanlar ovçuluq və yığıcılıqla dolanırdılar.',array['Ovçuluq və yığıcılıq','Kompüter proqramlaşdırması','Dəmiryol tikintisi','Kitab çapı'],1),
('tarix5-qedim#6','tarix','tarix-5-qedim',2,1,'Azərbaycanın ən qədim dövlətlərindən biri hansıdır?','Manna Azərbaycan ərazisindəki qədim dövlətdir.',array['Manna','Roma','Misir','Çin'],1),
('tarix5-qedim#7','tarix','tarix-5-qedim',3,1,'Atropatena dövləti Azərbaycanın hansı hissəsində yaranmışdı?','Atropatena cənub torpaqlarında yaranmışdı.',array['Cənubunda','Yalnız şimalında','Dənizin ortasında','Ərazidən kənarda'],1),
('tarix5-qedim#8','tarix','tarix-5-qedim',3,1,'Albaniya dövləti Azərbaycanın hansı hissəsində yerləşirdi?','Qafqaz Albaniyası şimal torpaqlarını əhatə edirdi.',array['Şimalında','Yalnız cənubunda','Qərb okeanında','Başqa qitədə'],1),
('tarix5-qedim#9','tarix','tarix-5-qedim',1,1,'Odun kəşfi qədim insanlara nə verdi?','Od istilik, işıq və yırtıcılardan qorunma verdi.',array['İstilik, işıq və qorunma','Kompüter','Təyyarə','Televizor'],1),
('tarix5-qedim#10','tarix','tarix-5-qedim',2,1,'Dövlət nə üçün lazımdır?','Dövlət ölkəni idarə edir və qoruyur.',array['Ölkəni idarə etmək və qorumaq üçün','Yalnız bayram keçirmək üçün','Oyun oynamaq üçün','Heç nə üçün'],1),
('tarix5-dovletler#1','tarix','tarix-5-dovletler',2,2,'Ərəb işğalçılarına qarşı üsyana başçılıq edən qəhrəman kimdir?','Babək azadlıq hərəkatının başçısı idi.',array['Babək','Nizami','Füzuli','Vaqif'],1),
('tarix5-dovletler#2','tarix','tarix-5-dovletler',2,2,'Səfəvi dövlətinin banisi kimdir?','Səfəvi dövlətini Şah İsmayıl Xətai yaratdı.',array['Şah İsmayıl Xətai','Qara Yusif','Nadir şah','Teymur'],1),
('tarix5-dovletler#3','tarix','tarix-5-dovletler',3,2,'Atabəylər dövlətinin banisi kimdir?','Atabəylər dövlətini Şəmsəddin Eldəniz qurmuşdur.',array['Şəmsəddin Eldəniz','Uzun Həsən','Babək','Sara xatun'],1),
('tarix5-dovletler#4','tarix','tarix-5-dovletler',3,2,'Qaraqoyunlu dövlətinin tanınmış hökmdarı kimdir?','Qara Yusif Qaraqoyunlu dövlətinin hökmdarı olub.',array['Qara Yusif','Şah İsmayıl','Nadir şah','Cavanşir'],1),
('tarix5-dovletler#5','tarix','tarix-5-dovletler',3,2,'Ağqoyunlu dövlətinin qüdrətli hökmdarı kim olmuşdur?','Uzun Həsən (Həsən padşah) Ağqoyunlu hökmdarı idi.',array['Uzun Həsən','Qara Yusif','Babək','Şəmsəddin Eldəniz'],1),
('tarix5-dovletler#6','tarix','tarix-5-dovletler',3,2,'«Şərqin son fatehi» adlandırılan hökmdar kimdir?','Nadir şah Əfşar «Şərqin son fatehi» adlanır.',array['Nadir şah','Şah İsmayıl','Uzun Həsən','Qara Yusif'],1),
('tarix5-dovletler#7','tarix','tarix-5-dovletler',3,2,'Dövlət işlərində, danışıqlarda ad çıxarmış Azərbaycan qadını kimdir?','Sara xatun Ağqoyunlu sarayının tanınmış diplomatı idi.',array['Sara xatun','Tomris','Kleopatra','Janna'],1),
('tarix5-dovletler#8','tarix','tarix-5-dovletler',2,2,'XVIII əsrin ortalarında Azərbaycan hansı kiçik dövlətlərə parçalandı?','Ölkə ayrı-ayrı xanlıqlara bölündü.',array['Xanlıqlara','Ştatlara','Krallıqlara','Koloniyalara'],1),
('tarix5-dovletler#9','tarix','tarix-5-dovletler',3,2,'Səlcuqlar hansı xalqın yaratdığı dövlət idi?','Səlcuq dövlətini oğuz türkləri qurmuşdu.',array['Oğuz türklərinin','Romalıların','Misirlilərin','Vikinqlərin'],1),
('tarix5-dovletler#10','tarix','tarix-5-dovletler',3,2,'Səfəvilər dövlətinin ilk paytaxtı hansı şəhər idi?','Səfəvilərin ilk paytaxtı Təbriz olmuşdur.',array['Təbriz','Bakı','Gəncə','Şamaxı'],1),
('tarix5-qalalar#1','tarix','tarix-5-qalalar',1,3,'Bakının rəmzi sayılan qədim qala-abidə hansıdır?','Qız qalası Bakının rəmzidir.',array['Qız qalası','Çıraq qala','Əlincə qalası','Gülüstan qalası'],1),
('tarix5-qalalar#2','tarix','tarix-5-qalalar',1,3,'İçərişəhər hansı şəhərdə yerləşir?','İçərişəhər Bakının qədim hissəsidir.',array['Bakıda','Gəncədə','Şəkidə','Naxçıvanda'],1),
('tarix5-qalalar#3','tarix','tarix-5-qalalar',1,3,'Qalalar əsasən nə üçün tikilirdi?','Qalalar düşməndən müdafiə üçün tikilirdi.',array['Müdafiə üçün','İdman üçün','Yalnız bəzək üçün','Anbar üçün'],1),
('tarix5-qalalar#4','tarix','tarix-5-qalalar',3,3,'«Azərbaycanın taxtı» adlandırılan şəhər hansıdır?','Təbriz uzun müddət paytaxt olduğu üçün belə adlanıb.',array['Təbriz','Sumqayıt','Mingəçevir','Lənkəran'],1),
('tarix5-qalalar#5','tarix','tarix-5-qalalar',2,3,'Qədim şəhərlər ən çox harada salınırdı?','Şəhərlər ticarət yolları üstündə, su mənbələri yanında yaranırdı.',array['Ticarət yolları üstündə','Buzlaqların içində','Vulkanların ağzında','Dəniz dibində'],1),
('tarix5-qalalar#6','tarix','tarix-5-qalalar',3,3,'Naxçıvandakı məşhur qədim türbə hansıdır?','Möminə xatın türbəsi Naxçıvan memarlığının incisidir.',array['Möminə xatın türbəsi','Qız qalası','Şirvanşahlar sarayı','Atəşgah'],1),
('tarix5-qalalar#7','tarix','tarix-5-qalalar',3,3,'Qəbələ hansı qədim dövlətin paytaxtı olmuşdur?','Qəbələ Qafqaz Albaniyasının paytaxtı idi.',array['Albaniyanın','Romanın','Misirin','Yunanıstanın'],1),
('tarix5-qalalar#8','tarix','tarix-5-qalalar',2,3,'Şəki şəhərindəki məşhur tarixi saray hansıdır?','Şəki xan sarayı dünya şöhrətli abidədir.',array['Şəki xan sarayı','Qış sarayı','Yay sarayı','Buz sarayı'],1),
('tarix5-qalalar#9','tarix','tarix-5-qalalar',3,3,'Şuşa qalasını kim saldırmışdır?','Şuşanı Qarabağ xanı Pənahəli xan saldırıb.',array['Pənahəli xan','Nadir şah','Şah İsmayıl','Babək'],1),
('tarix5-qalalar#10','tarix','tarix-5-qalalar',2,3,'Karvansaralar nə üçün tikilirdi?','Karvansaralar tacirlərin və karvanların dincəlməsi üçün idi.',array['Tacirlərin dincəlməsi üçün','Dərs keçmək üçün','İdman yarışları üçün','Gəmi saxlamaq üçün'],1),
('tarix5-respublika#1','tarix','tarix-5-respublika',2,3,'Müsəlman Şərqində ilk demokratik respublika hansıdır?','Azərbaycan Xalq Cümhuriyyəti Şərqdə ilk respublikadır.',array['Azərbaycan Xalq Cümhuriyyəti','Roma Respublikası','Fransa Respublikası','Afina dövləti'],1),
('tarix5-respublika#2','tarix','tarix-5-respublika',2,3,'Azərbaycan Xalq Cümhuriyyəti neçənci ildə yaranmışdır?','AXC 1918-ci il mayın 28-də elan olundu.',array['1918','1920','1991','1945'],1),
('tarix5-respublika#3','tarix','tarix-5-respublika',3,3,'Azərbaycan Xalq Cümhuriyyəti neçənci ildə sovet işğalı ilə süqut etdi?','1920-ci ilin aprelində sovet Rusiyası Azərbaycanı işğal etdi.',array['1920','1918','1939','1969'],1),
('tarix5-respublika#4','tarix','tarix-5-respublika',2,3,'Azərbaycan dövlət müstəqilliyini neçənci ildə bərpa etdi?','Müstəqillik 1991-ci ildə bərpa olundu.',array['1991','1981','2001','1970'],1),
('tarix5-respublika#5','tarix','tarix-5-respublika',1,3,'Azərbaycan xalqının ümummilli lideri kimdir?','Heydər Əliyev ümummilli lider sayılır.',array['Heydər Əliyev','Nizami Gəncəvi','Babək','Uzun Həsən'],1),
('tarix5-respublika#6','tarix','tarix-5-respublika',2,3,'44 günlük Vətən müharibəsi neçənci ildə baş verdi?','Vətən müharibəsi 2020-ci ildə oldu.',array['2020','2016','1994','2003'],1),
('tarix5-respublika#7','tarix','tarix-5-respublika',2,3,'Vətən müharibəsində Azərbaycan Ordusunun Ali Baş Komandanı kim idi?','Prezident İlham Əliyev Ali Baş Komandan idi.',array['İlham Əliyev','Nadir şah','Şah İsmayıl','Pənahəli xan'],1),
('tarix5-respublika#8','tarix','tarix-5-respublika',2,3,'8 Noyabr Azərbaycanda hansı gün kimi qeyd olunur?','8 Noyabr — Şuşanın azad edildiyi Zəfər Günüdür.',array['Zəfər Günü','Bilik Günü','Novruz bayramı','Dövlət Bayrağı Günü'],1),
('tarix5-respublika#9','tarix','tarix-5-respublika',3,3,'Aprel döyüşləri neçənci ildə olmuşdur?','Aprel döyüşləri 2016-cı ildə baş verib.',array['2016','2020','1918','1991'],1),
('tarix5-respublika#10','tarix','tarix-5-respublika',3,3,'İkinci Dünya müharibəsində qələbəyə Azərbaycan ən çox nə ilə töhfə verdi?','Cəbhə Bakı nefti ilə təmin olunurdu.',array['Bakı nefti ilə','Qızıl külçələrlə','Gəmilərlə','Kosmik texnika ilə'],1),
('tarix5-medeniyyet#1','tarix','tarix-5-medeniyyet',2,4,'Azərbaycan xalqının qəhrəmanlıq dastanı hansıdır?','«Kitabi-Dədə Qorqud» xalqımızın qəhrəmanlıq dastanıdır.',array['«Kitabi-Dədə Qorqud»','«Robinzon Kruzo»','«Min bir gecə»','«İliada»'],1),
('tarix5-medeniyyet#2','tarix','tarix-5-medeniyyet',2,4,'«Xəmsə» əsərinin müəllifi kimdir?','Beş poemadan ibarət «Xəmsə»ni Nizami Gəncəvi yazıb.',array['Nizami Gəncəvi','Üzeyir Hacıbəyli','Lütfi Zadə','Həsən bəy Zərdabi'],1),
('tarix5-medeniyyet#3','tarix','tarix-5-medeniyyet',3,4,'«Azərbaycan tarixinin atası» sayılan alim kimdir?','Abbasqulu ağa Bakıxanov ilk elmi tarix əsərini yazıb.',array['Abbasqulu ağa Bakıxanov','Nizami Gəncəvi','Şah İsmayıl','Babək'],1),
('tarix5-medeniyyet#4','tarix','tarix-5-medeniyyet',2,4,'İlk Azərbaycan qəzeti necə adlanırdı?','İlk milli qəzetimiz «Əkinçi» idi.',array['«Əkinçi»','«Molla Nəsrəddin»','«Kommunist»','«Azərbaycan»'],1),
('tarix5-medeniyyet#5','tarix','tarix-5-medeniyyet',3,4,'«Əkinçi» qəzetini kim nəşr edirdi?','Qəzeti Həsən bəy Zərdabi nəşr edirdi.',array['Həsən bəy Zərdabi','Üzeyir Hacıbəyli','Nizami','Bakıxanov'],1),
('tarix5-medeniyyet#6','tarix','tarix-5-medeniyyet',2,4,'Şərqdə ilk operanın («Leyli və Məcnun») müəllifi kimdir?','Üzeyir Hacıbəyli Şərqdə ilk operanı yaratdı.',array['Üzeyir Hacıbəyli','Həsən bəy Zərdabi','Lütfi Zadə','Nadir şah'],1),
('tarix5-medeniyyet#7','tarix','tarix-5-medeniyyet',3,4,'«Qeyri-səlis məntiq» nəzəriyyəsinin müəllifi, dünya şöhrətli alim kimdir?','Lütfi Zadə dünya şöhrətli Azərbaycan alimidir.',array['Lütfi Zadə','Nyuton','Eynşteyn','Arximed'],1),
('tarix5-medeniyyet#8','tarix','tarix-5-medeniyyet',2,4,'Nizami Gəncəvi hansı şəhərdə yaşayıb-yaratmışdır?','Nizami bütün ömrünü Gəncədə keçirib.',array['Gəncədə','Parisdə','İstanbulda','Qahirədə'],1),
('tarix5-medeniyyet#9','tarix','tarix-5-medeniyyet',3,4,'«Kitabi-Dədə Qorqud» dastanında nə vəsf olunur?','Dastanda oğuz igidlərinin qəhrəmanlığı vəsf olunur.',array['Oğuz igidlərinin qəhrəmanlığı','Kosmik uçuşlar','Dəniz səyahətləri','İdman yarışları'],1),
('tarix5-medeniyyet#10','tarix','tarix-5-medeniyyet',3,4,'Üzeyir Hacıbəylinin məşhur musiqili komediyası hansıdır?','«Arşın mal alan» dünyada tanınan komediyadır.',array['«Arşın mal alan»','«Hamlet»','«Otello»','«Karmen»'],1)
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
   where owner_type = 'platform'
     and (ext_key like 'az5-%' or ext_key like 'ing5-%'
          or ext_key like 'inf5-%' or ext_key like 'tarix5-%');
  if n <> 260 then
    raise exception 'sinif5 suallari: 260 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'az5-%' or q.ext_key like 'ing5-%'
          or q.ext_key like 'inf5-%' or q.ext_key like 'tarix5-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az5-%' or ext_key like 'ing5-%'
      or ext_key like 'inf5-%' or ext_key like 'tarix5-%';
  if k <> 26 then
    raise exception 'movzu sayi 26 deyil: %', k;
  end if;
  raise notice '5-ci sinif banki: % sual, 26 movzu (az, ing, inf, tarix).', n;
end $$;
