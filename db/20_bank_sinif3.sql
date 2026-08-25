-- =====================================================================
--  20_bank_sinif3.sql : 3-CU SINIF - AZ DILI, HEYAT BILGISI, INFORMATIKA
--
--  BU FAYL ELLE YAZILMIR - tools/sinif3.py yaradir:
--      python3 tools/sinif3.py
--
--  Az dili 8 + Heyat bilgisi 6 + Informatika 4 = 18 movzu x 10 = 180.
--  ext_key: az3-/hey3-/inf3-...
--  ON SERT: 14_movzular.sql ve 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('az-dili','az-3-isim'),
                                ('hayat-bilgisi','hey-3-yer-ay'),
                                ('informatika','inf-3-metn'))
     having count(*) = 3) then
    raise exception 'ONCE 14_movzular.sql ve 15_movzular_ederslik.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'az3-%' or q.ext_key like 'hey3-%'
        or q.ext_key like 'inf3-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('az3-sait-samit#1','az-dili','az-3-sait-samit',1,1,'Azərbaycan dilində neçə sait səs var?','Dilimizdə 9 sait var: a, e, ə, i, ı, o, ö, u, ü.',array['9','6','23','32'],1),
('az3-sait-samit#2','az-dili','az-3-sait-samit',1,1,'Hansı sırada yalnız saitlər verilib?','a, ı, u — hamısı saitdir.',array['a, ı, u','a, b, c','m, n, o','k, i, t'],1),
('az3-sait-samit#3','az-dili','az-3-sait-samit',2,1,'«Dəniz» sözündə neçə sait var?','Saitlər: ə, i — iki sait.',array['2','3','1','5'],1),
('az3-sait-samit#4','az-dili','az-3-sait-samit',2,1,'Qalın saitlər hansı sırada verilib?','Qalın saitlər: a, ı, o, u.',array['a, ı, o, u','ə, e, i, ö','a, ə, i, o','e, i, u, ü'],1),
('az3-sait-samit#5','az-dili','az-3-sait-samit',2,1,'İncə saitlər hansı sırada verilib?','İncə saitlər: ə, e, i, ö, ü.',array['ə, e, i, ö, ü','a, ı, o, u','a, e, i, o, u','b, c, d, f, g'],1),
('az3-sait-samit#6','az-dili','az-3-sait-samit',2,1,'«Məktəb» sözündə neçə samit var?','Samitlər: m, k, t, b — dörd samit.',array['4','2','6','3'],1),
('az3-sait-samit#7','az-dili','az-3-sait-samit',3,1,'Hansı samit kar samitdir?','«p» kar samitdir, cingiltili qarşılığı «b»-dir.',array['p','b','d','g'],1),
('az3-sait-samit#8','az-dili','az-3-sait-samit',3,1,'Hansı samit cingiltilidir?','«b» cingiltili samitdir, kar qarşılığı «p»-dir.',array['b','p','t','k'],1),
('az3-sait-samit#9','az-dili','az-3-sait-samit',1,1,'«Ana» sözü neçə səsdən ibarətdir?','A-n-a: üç səs.',array['3','2','4','5'],1),
('az3-sait-samit#10','az-dili','az-3-sait-samit',2,1,'Saitlər necə tələffüz olunur?','Saitlər səs yolunda maneəyə rast gəlmədən tələffüz olunur.',array['Maneəsiz','Maneə ilə','Yalnız pıçıltı ilə','Tələffüz olunmur'],1),
('az3-isim#1','az-dili','az-3-isim',1,1,'İsim nəyi bildirir?','İsim əşyanın adını bildirir.',array['Əşyanın adını','Əlaməti','Hərəkəti','Miqdarı'],1),
('az3-isim#2','az-dili','az-3-isim',1,1,'Hansı söz isimdir?','«Dağ» — əşyanın adıdır, «nə?» sualına cavab verir.',array['dağ','qaçmaq','uca','beş'],1),
('az3-isim#3','az-dili','az-3-isim',1,1,'İsimlər hansı suallara cavab verir?','İsimlər «kim? nə?» suallarına cavab verir.',array['Kim? Nə?','Necə?','Nə edir?','Neçə?'],1),
('az3-isim#4','az-dili','az-3-isim',2,1,'Hansı söz xüsusi isimdir?','«Kür» — çayın xüsusi adıdır, böyük hərflə yazılır.',array['Kür','çay','şəhər','uşaq'],1),
('az3-isim#5','az-dili','az-3-isim',1,1,'Xüsusi isimlər necə yazılır?','İnsan, şəhər, çay adları böyük hərflə yazılır.',array['Böyük hərflə','Kiçik hərflə','Dırnaqda','Rəqəmlə'],1),
('az3-isim#6','az-dili','az-3-isim',2,1,'«Quşlar» sözü təkdədir, yoxsa cəmdə?','-lar şəkilçisi cəm bildirir.',array['Cəmdə','Təkdə','Heç biri','Hər ikisi'],1),
('az3-isim#7','az-dili','az-3-isim',2,1,'İsmin cəm şəkilçiləri hansılardır?','Cəm şəkilçiləri -lar, -lər-dir.',array['-lar, -lər','-da, -də','-a, -ə','-ın, -in'],1),
('az3-isim#8','az-dili','az-3-isim',2,1,'Hansı sırada yalnız isimlər verilib?','Kitab, meşə, günəş — hamısı əşya adıdır.',array['kitab, meşə, günəş','kitab, oxumaq, gözəl','meşə, yaşıl, getmək','günəş, isti, beş'],1),
('az3-isim#9','az-dili','az-3-isim',2,1,'«Bakı, Aysu, Araz» sözlərinin ümumi cəhəti nədir?','Hamısı xüsusi isimdir — ad bildirir və böyük hərflə yazılır.',array['Hamısı xüsusi isimdir','Hamısı feldir','Hamısı sifətdir','Hamısı cəmdədir'],1),
('az3-isim#10','az-dili','az-3-isim',3,1,'«Uşaqlar bağçada oynayırlar» cümləsində «bağçada» sözü hansı nitq hissəsidir?','«Bağça» əşya adıdır — isimdir.',array['İsim','Fel','Sifət','Say'],1),
('az3-sifet#1','az-dili','az-3-sifet',1,2,'Sifət nəyi bildirir?','Sifət əşyanın əlamətini bildirir.',array['Əşyanın əlamətini','Əşyanın adını','Hərəkəti','Miqdarı'],1),
('az3-sifet#2','az-dili','az-3-sifet',1,2,'Hansı söz sifətdir?','«Şirin» — əlamət bildirir: necə?',array['şirin','alma','yemək','iki'],1),
('az3-sifet#3','az-dili','az-3-sifet',1,2,'Sifətlər hansı suallara cavab verir?','Sifətlər «necə? nə cür? hansı?» suallarına cavab verir.',array['Necə? Nə cür?','Kim? Nə?','Nə edir?','Nə vaxt?'],1),
('az3-sifet#4','az-dili','az-3-sifet',2,2,'«Hündür bina» birləşməsində sifət hansıdır?','Bina necədir? — hündür.',array['hündür','bina','hər ikisi','heç biri'],1),
('az3-sifet#5','az-dili','az-3-sifet',2,2,'Hansı sırada yalnız sifətlər verilib?','Gözəl, dar, isti — hamısı əlamət bildirir.',array['gözəl, dar, isti','gözəl, ev, dar','isti, yay, gün','dar, küçə, uzun'],1),
('az3-sifet#6','az-dili','az-3-sifet',2,2,'Sifət cümlədə adətən hansı sözdən əvvəl gəlir?','Sifət ismin əlamətini bildirdiyi üçün isimdən əvvəl gəlir.',array['İsimdən','Feldən','Saydan','Cümlənin sonundakı sözdən'],1),
('az3-sifet#7','az-dili','az-3-sifet',2,2,'«Soyuq» sözünün əks mənalısı hansıdır?','Soyuq ↔ isti.',array['isti','sərin','buzlu','yaş'],1),
('az3-sifet#8','az-dili','az-3-sifet',2,2,'«Balaca pişik süd içir» cümləsində sifət hansıdır?','Pişik necədir? — balaca.',array['balaca','pişik','süd','içir'],1),
('az3-sifet#9','az-dili','az-3-sifet',2,2,'Əşyanın rəngini bildirən söz hansı nitq hissəsidir?','Rəng əlamətdir — sifətlə bildirilir.',array['Sifət','İsim','Fel','Say'],1),
('az3-sifet#10','az-dili','az-3-sifet',3,2,'Hansı söz sifət DEYİL?','«Yazmaq» hərəkət bildirir — feldir.',array['yazmaq','təmiz','qısa','dadlı'],1),
('az3-fel#1','az-dili','az-3-fel',1,2,'Fel nəyi bildirir?','Fel hərəkəti bildirir.',array['Hərəkəti','Əşyanın adını','Əlaməti','Miqdarı'],1),
('az3-fel#2','az-dili','az-3-fel',1,2,'Hansı söz feldir?','«Oxumaq» hərəkət bildirir: nə etmək?',array['oxumaq','kitab','maraqlı','səhifə'],1),
('az3-fel#3','az-dili','az-3-fel',1,2,'Fellər hansı suallara cavab verir?','Fellər «nə edir? nə etdi? nə edəcək?» suallarına cavab verir.',array['Nə edir?','Kim? Nə?','Necə?','Hansı?'],1),
('az3-fel#4','az-dili','az-3-fel',2,2,'«Quş yuvasına uçur» cümləsində fel hansıdır?','Quş nə edir? — uçur.',array['uçur','quş','yuvasına','cümlədə fel yoxdur'],1),
('az3-fel#5','az-dili','az-3-fel',2,2,'Hansı sırada yalnız fellər verilib?','Gəlmək, getmək, baxmaq — hamısı hərəkət bildirir.',array['gəlmək, getmək, baxmaq','gəlmək, yol, uzaq','baxmaq, göz, iri','getmək, ayaq, tez'],1),
('az3-fel#6','az-dili','az-3-fel',3,2,'«Getmək» felinin inkarı hansıdır?','Felin inkarı -ma, -mə şəkilçisi ilə düzəlir: getməmək.',array['getməmək','gəlmək','getdi','gedəcək'],1),
('az3-fel#7','az-dili','az-3-fel',2,2,'Cümləni tamamlayın: «Şagirdlər şeiri əzbər …»','Cümləni fel tamamlayır: deyirlər.',array['deyirlər','kitab','maraqlı','məktəb'],1),
('az3-fel#8','az-dili','az-3-fel',3,2,'Hansı söz fel DEYİL?','«Qaçış» hərəkətin adıdır — isimdir; qalanları feldir.',array['qaçış','qaçmaq','tullanmaq','üzmək'],1),
('az3-fel#9','az-dili','az-3-fel',1,2,'«Danışmaq, gülmək, oxumaq» sözlərinin ümumi cəhəti nədir?','Hər üçü hərəkət bildirir — feldir.',array['Hamısı feldir','Hamısı isimdir','Hamısı sifətdir','Heç bir ümumi cəhəti yoxdur'],1),
('az3-fel#10','az-dili','az-3-fel',2,2,'«Külək bərk əsir» cümləsindəki feli göstərin.','Külək nə edir? — əsir.',array['əsir','külək','bərk','cümlədə fel yoxdur'],1),
('az3-soz-novleri#1','az-dili','az-3-soz-novleri',1,3,'Əşyanın adını bildirən sözlər necə adlanır?','Ad bildirən sözlər isimdir.',array['İsim','Sifət','Fel','Say'],1),
('az3-soz-novleri#2','az-dili','az-3-soz-novleri',2,3,'«Sarı» sözü hansı söz növüdür?','Rəng əlamətdir — sifətdir.',array['Sifət','İsim','Fel','Say'],1),
('az3-soz-novleri#3','az-dili','az-3-soz-novleri',2,3,'«Uçmaq» sözü hansı nitq hissəsinə aiddir?','Hərəkət bildirir — feldir.',array['Fel','İsim','Sifət','Say'],1),
('az3-soz-novleri#4','az-dili','az-3-soz-novleri',3,3,'Hansı cərgədə «isim, sifət, fel» ardıcıllığı düzgündür?','Ev — isim, geniş — sifət, tikmək — fel.',array['ev, geniş, tikmək','geniş, ev, tikmək','tikmək, geniş, ev','ev, tikmək, geniş'],1),
('az3-soz-novleri#5','az-dili','az-3-soz-novleri',1,3,'Əlamət bildirən sözü seçin.','«Ağıllı» — necə? sualına cavab verir.',array['ağıllı','uşaq','oxuyur','on'],1),
('az3-soz-novleri#6','az-dili','az-3-soz-novleri',1,3,'Hərəkət bildirən sözü seçin.','«Üzmək» — nə etmək? sualına cavab verir.',array['üzmək','üzgüçü','sürətli','hovuz'],1),
('az3-soz-novleri#7','az-dili','az-3-soz-novleri',3,3,'«Beş» sözü nəyi bildirir?','«Beş» miqdar bildirir — saydır.',array['Miqdarı','Əlaməti','Hərəkəti','Əşyanın adını'],1),
('az3-soz-novleri#8','az-dili','az-3-soz-novleri',2,3,'«Qırmızı alma budaqdan düşdü» cümləsində hansı söz isimdir?','«Alma» əşya adıdır (budaq da isimdir).',array['alma','qırmızı','düşdü','cümlədə isim yoxdur'],1),
('az3-soz-novleri#9','az-dili','az-3-soz-novleri',2,3,'«Kitabxana» sözü hansı söz növüdür?','Yer adıdır — isimdir.',array['İsim','Sifət','Fel','Say'],1),
('az3-soz-novleri#10','az-dili','az-3-soz-novleri',3,3,'Hansı cüt «sifət + isim» qəlibinə uyğundur?','Uzun (necə?) + yol (nə?).',array['uzun yol','yol getmək','tez qaçmaq','beş kitab'],1),
('az3-cumle#1','az-dili','az-3-cumle',1,3,'Cümlə nədir?','Cümlə bitmiş fikir bildirir.',array['Bitmiş fikir bildirən söz və ya söz birləşməsi','Hərflərin yığını','Təkcə bir söz','Şəkilçilər toplusu'],1),
('az3-cumle#2','az-dili','az-3-cumle',2,3,'Cümlənin baş üzvləri hansılardır?','Baş üzvlər mübtəda və xəbərdir.',array['Mübtəda və xəbər','İsim və sifət','Söz və heca','Sual və cavab'],1),
('az3-cumle#3','az-dili','az-3-cumle',2,3,'«Yarpaqlar töküldü» cümləsində mübtəda hansıdır?','Tökülən nədir? — Yarpaqlar.',array['Yarpaqlar','töküldü','hər ikisi','heç biri'],1),
('az3-cumle#4','az-dili','az-3-cumle',2,3,'«Uşaq şirin-şirin gülür» cümləsində xəbər hansıdır?','Uşaq nə edir? — gülür.',array['gülür','Uşaq','şirin-şirin','cümlədə xəbər yoxdur'],1),
('az3-cumle#5','az-dili','az-3-cumle',1,3,'Cümlənin birinci sözü necə yazılır?','Cümlə böyük hərflə başlanır.',array['Böyük hərflə','Kiçik hərflə','İxtisarla','Rəqəmlə'],1),
('az3-cumle#6','az-dili','az-3-cumle',2,3,'Azərbaycan dilində xəbər adətən cümlənin harasında olur?','Xəbər adətən cümlənin sonunda gəlir.',array['Sonunda','Əvvəlində','Ortasında','Qaydası yoxdur'],1),
('az3-cumle#7','az-dili','az-3-cumle',2,3,'Hansı yazılış cümlədir?','«Qar yağdı.» — bitmiş fikirdir.',array['Qar yağdı.','sürətli qaçmaq','gözəl hava','mavi səma'],1),
('az3-cumle#8','az-dili','az-3-cumle',3,3,'«Anam bazardan təzə meyvə aldı» cümləsində mübtəda hansıdır?','Alan kimdir? — Anam.',array['Anam','bazardan','meyvə','aldı'],1),
('az3-cumle#9','az-dili','az-3-cumle',2,3,'Cümlənin neçə baş üzvü var?','İki baş üzv: mübtəda və xəbər.',array['2','1','3','5'],1),
('az3-cumle#10','az-dili','az-3-cumle',3,3,'«Oxuyur» sözü cümlədə adətən hansı üzv olur?','Fel cümlədə əsasən xəbər olur.',array['Xəbər','Mübtəda','Üzv olmur','Başlıq'],1),
('az3-yazi-qaydasi#1','az-dili','az-3-yazi-qaydasi',2,4,'Düzgün yazılışı seçin.','Düzgün yazılış: məktəb.',array['məktəb','məktəp','mektəb','məktap'],1),
('az3-yazi-qaydasi#2','az-dili','az-3-yazi-qaydasi',1,4,'Xüsusi isimlər hansı hərflə başlanır?','Şəxs, şəhər, çay adları böyük hərflə yazılır.',array['Böyük hərflə','Kiçik hərflə','İstənilən hərflə','Saitlə'],1),
('az3-yazi-qaydasi#3','az-dili','az-3-yazi-qaydasi',2,4,'Söz sətirdən sətrə necə keçirilir?','Söz yalnız hecalarla keçirilir.',array['Hecalarla','Hərf-hərf','İstənilən yerdən','Keçirmək olmaz'],1),
('az3-yazi-qaydasi#4','az-dili','az-3-yazi-qaydasi',3,4,'Ay adları (yanvar, mart…) necə yazılır?','Ay adları kiçik hərflə yazılır.',array['Kiçik hərflə','Böyük hərflə','Dırnaqda','Rəqəmlə'],1),
('az3-yazi-qaydasi#5','az-dili','az-3-yazi-qaydasi',1,4,'Nəqli cümlə hansı işarə ilə bitir?','Adi məlumat bildirən cümlənin sonunda nöqtə qoyulur.',array['Nöqtə ilə','Sual işarəsi ilə','Vergüllə','Tire ilə'],1),
('az3-yazi-qaydasi#6','az-dili','az-3-yazi-qaydasi',2,4,'«Kitab» sözü hecalara necə bölünür?','Ki-tab: iki heca.',array['ki-tab','kit-ab','k-itab','kita-b'],1),
('az3-yazi-qaydasi#7','az-dili','az-3-yazi-qaydasi',2,4,'«Dovşan» sözündə neçə heca var?','Saitlər: o, a — iki sait, deməli iki heca.',array['2','3','1','4'],1),
('az3-yazi-qaydasi#8','az-dili','az-3-yazi-qaydasi',3,4,'Hansı sözü sətirdən sətrə keçirmək olmaz?','Birhecalı sözlər keçirilmir.',array['el','ana','kitab','dəftər'],1),
('az3-yazi-qaydasi#9','az-dili','az-3-yazi-qaydasi',3,4,'«günəş» sözü nə vaxt böyük hərflə yazılır?','Şəxs adı olanda: Günəş adlı qız.',array['Şəxs adı olanda','Cəmdə olanda','Heç vaxt','Həmişə'],1),
('az3-yazi-qaydasi#10','az-dili','az-3-yazi-qaydasi',2,4,'«Ananas» sözündə neçə heca var?','Saitlər: a, a, a — üç heca: a-na-nas.',array['3','2','4','6'],1),
('az3-metn#1','az-dili','az-3-metn',2,4,'Mətni adi cümlələr yığınından fərqləndirən nədir?','Mətndə cümlələr məzmunca bir-biri ilə bağlıdır.',array['Cümlələrin məzmunca bağlılığı','Cümlələrin sayı','Sözlərin uzunluğu','Şəkilli olması'],1),
('az3-metn#2','az-dili','az-3-metn',2,4,'Mətnin başlığı nəyə uyğun seçilir?','Başlıq mətnin məzmununa uyğun olmalıdır.',array['Məzmuna','İlk hərfə','Cümlə sayına','Müəllifin adına'],1),
('az3-metn#3','az-dili','az-3-metn',2,4,'Nitq neçə cür olur?','Nitq şifahi və yazılı olur.',array['Şifahi və yazılı','Yalnız şifahi','Yalnız yazılı','Sürətli və yavaş'],1),
('az3-metn#4','az-dili','az-3-metn',1,4,'Hansı, şifahi nitqə aiddir?','Danışıq şifahi nitqdir.',array['Nağıl danışmaq','Məktub yazmaq','İnşa yazmaq','Dəftərə köçürmək'],1),
('az3-metn#5','az-dili','az-3-metn',2,4,'Hansı, yazılı nitqə aiddir?','Məktub yazmaq yazılı nitqdir.',array['Məktub yazmaq','Telefonla danışmaq','Mahnı oxumaq','Sual vermək'],1),
('az3-metn#6','az-dili','az-3-metn',2,4,'Mətndə cümlələr necə düzülməlidir?','Cümlələr məntiqi ardıcıllıqla düzülür.',array['Ardıcıl, məntiqi','Qarışıq','Uzunluğa görə','Əlifba sırası ilə'],1),
('az3-metn#7','az-dili','az-3-metn',1,4,'Həmsöhbəti dinləyərkən nə etmək düzgündür?','Sözünü kəsməmək hörmətin əlamətidir.',array['Sözünü kəsməmək','Ucadan danışmaq','Üzünə baxmamaq','Telefonla oynamaq'],1),
('az3-metn#8','az-dili','az-3-metn',2,4,'Mətn adətən neçə hissədən ibarət olur?','Giriş, əsas hissə, nəticə — üç hissə.',array['3','1','5','10'],1),
('az3-metn#9','az-dili','az-3-metn',1,4,'Telefonla danışığa nədən başlamaq lazımdır?','Əvvəlcə salamlaşırlar.',array['Salamlaşmaqdan','Şikayətdən','Sağollaşmaqdan','Sualdan'],1),
('az3-metn#10','az-dili','az-3-metn',2,4,'Nağıl danışmaq hansı nitq növüdür?','Danışıq — şifahi nitqdir.',array['Şifahi','Yazılı','Heç biri','Hər ikisi'],1),
('hey3-cemiyyet#1','hayat-bilgisi','hey-3-cemiyyet',1,1,'Cəmiyyətdə insanlar bir-biri ilə necə davranmalıdır?','Qarşılıqlı hörmət cəmiyyətin təməlidir.',array['Hörmətlə','Biganə','Kobud','Yalnız tanışlarla nəzakətli'],1),
('hey3-cemiyyet#2','hayat-bilgisi','hey-3-cemiyyet',1,1,'Məktəb qaydalarına kim əməl etməlidir?','Qaydalar hamı üçündür.',array['Bütün şagirdlər','Yalnız növbətçilər','Yalnız birincilər','Heç kim'],1),
('hey3-cemiyyet#3','hayat-bilgisi','hey-3-cemiyyet',2,1,'Növbəyə riayət etmək nəyin əlamətidir?','Növbə gözləmək mədəni davranışdır.',array['Mədəniyyətin','Zəifliyin','Tələsməyin','Qorxaqlığın'],1),
('hey3-cemiyyet#4','hayat-bilgisi','hey-3-cemiyyet',2,1,'Kollektiv nədir?','Bir məqsəd üçün birgə çalışan insanlar kollektivdir.',array['Birgə fəaliyyət göstərən insanlar','Bir nəfər','Binaların cəmi','Yalnız qonşular'],1),
('hey3-cemiyyet#5','hayat-bilgisi','hey-3-cemiyyet',1,1,'Hansı davranış SƏHVDİR?','İctimai yerdə ucadan qışqırmaq başqalarını narahat edir.',array['Avtobusda ucadan qışqırmaq','Salam vermək','Növbə gözləmək','Zibili qutuya atmaq'],1),
('hey3-cemiyyet#6','hayat-bilgisi','hey-3-cemiyyet',2,1,'Nəqliyyatda kimə yer vermək lazımdır?','Yaşlılara, uşaqlı sərnişinlərə yer verilir.',array['Yaşlılara və körpəli sərnişinlərə','Heç kimə','Yalnız dostlara','Sürücüyə'],1),
('hey3-cemiyyet#7','hayat-bilgisi','hey-3-cemiyyet',2,1,'Dostluq nəyə əsaslanır?','Əsl dostluq etibar və sədaqət üzərində qurulur.',array['Etibara və sədaqətə','Hədiyyələrə','Qorxuya','Paxıllığa'],1),
('hey3-cemiyyet#8','hayat-bilgisi','hey-3-cemiyyet',1,1,'Ailə üzvlərinə kömək etmək kimin borcudur?','Ev işlərində hamı iştirak etməlidir.',array['Hər bir ailə üzvünün','Yalnız ananın','Yalnız uşaqların','Qonaqların'],1),
('hey3-cemiyyet#9','hayat-bilgisi','hey-3-cemiyyet',2,1,'Hansı, milli adət-ənənələrimizə aiddir?','Novruzda tonqal qalamaq qədim adətimizdir.',array['Novruzda tonqal qalamaq','Qonağı qarşılamamaq','Böyüyə salam verməmək','Süfrəni yığışdırmamaq'],1),
('hey3-cemiyyet#10','hayat-bilgisi','hey-3-cemiyyet',2,1,'Kiçiklərə münasibət necə olmalıdır?','Kiçiklərə qayğı göstərmək böyüklüyün əlamətidir.',array['Qayğı ilə','Biganə','Kobud','Əmrlə'],1),
('hey3-saglamliq#1','hayat-bilgisi','hey-3-saglamliq',2,1,'Gündəlik rejimə nə daxildir?','Yuxu, qidalanma, dərs və istirahət vaxtlarının bölgüsü.',array['Yuxu, qida və məşğuliyyət vaxtları','Yalnız oyun','Yalnız yemək','Yalnız dərs'],1),
('hey3-saglamliq#2','hayat-bilgisi','hey-3-saglamliq',1,1,'Səhər idmanı orqanizmə nə verir?','Səhər hərəkəti bədəni gümrahlaşdırır.',array['Gümrahlıq','Yorğunluq','Yuxusuzluq','Heç nə'],1),
('hey3-saglamliq#3','hayat-bilgisi','hey-3-saglamliq',1,1,'Dişləri gündə neçə dəfə fırçalamaq lazımdır?','Səhər və axşam — 2 dəfə.',array['2 dəfə','Həftədə 1 dəfə','Ayda 2 dəfə','Heç fırçalamamaq'],1),
('hey3-saglamliq#4','hayat-bilgisi','hey-3-saglamliq',2,1,'Vitaminlər ən çox hansı qidalarda olur?','Meyvə və tərəvəz vitamin mənbəyidir.',array['Meyvə və tərəvəzdə','Şirniyyatda','Çipslərdə','Qazlı içkilərdə'],1),
('hey3-saglamliq#5','hayat-bilgisi','hey-3-saglamliq',2,1,'Gözləri qorumaq üçün nə etmək lazımdır?','Ekrana yaxından və uzun müddət baxmaq gözləri yorur.',array['Ekrana yaxından uzun baxmamaq','Qaranlıqda kitab oxumaq','Günəşə birbaşa baxmaq','Heç nə etməmək'],1),
('hey3-saglamliq#6','hayat-bilgisi','hey-3-saglamliq',1,1,'Yeməkdən əvvəl mütləq nə edilməlidir?','Əllər sabunla yuyulmalıdır.',array['Əllər yuyulmalıdır','Qaçmaq lazımdır','Yatmaq lazımdır','Su içmək olmaz'],1),
('hey3-saglamliq#7','hayat-bilgisi','hey-3-saglamliq',2,1,'Soyuqdəymədən qorunmaq üçün nə vacibdir?','Havaya uyğun geyinmək lazımdır.',array['Havaya uyğun geyinmək','Nazik geyinmək','Buzlu su içmək','Papaqsız gəzmək'],1),
('hey3-saglamliq#8','hayat-bilgisi','hey-3-saglamliq',2,1,'Uzun müddət fasiləsiz telefonda oynamaq nəyə zərərdir?','Gözlərə və qamətə zərər verir.',array['Gözlərə və qamətə','Heç nəyə','Yalnız telefona','Yalnız ayaqlara'],1),
('hey3-saglamliq#9','hayat-bilgisi','hey-3-saglamliq',1,1,'Təmiz havada gəzinti insana nə verir?','Təmiz hava sağlamlığı möhkəmləndirir.',array['Sağlamlıq və gümrahlıq','Xəstəlik','Yorğunluq','Qorxu'],1),
('hey3-saglamliq#10','hayat-bilgisi','hey-3-saglamliq',2,1,'Mütəmadi idman nəyi möhkəmləndirir?','İdman əzələləri və iradəni gücləndirir.',array['Əzələləri və iradəni','Yalnız səsi','Yalnız yaddaşı','Heç nəyi'],1),
('hey3-yer-ay#1','hayat-bilgisi','hey-3-yer-ay',1,2,'Yer hansı formadadır?','Yer kürə formasındadır.',array['Kürə','Kvadrat','Düz lövhə','Üçbucaq'],1),
('hey3-yer-ay#2','hayat-bilgisi','hey-3-yer-ay',1,2,'Bizə işıq və istilik verən göy cismi hansıdır?','Günəş işıq və istilik mənbəyidir.',array['Günəş','Ay','Ulduzlar','Buludlar'],1),
('hey3-yer-ay#3','hayat-bilgisi','hey-3-yer-ay',2,2,'Ay nəyin peykidir?','Ay Yerin təbii peykidir.',array['Yerin','Günəşin','Marsın','Ulduzların'],1),
('hey3-yer-ay#4','hayat-bilgisi','hey-3-yer-ay',3,2,'Gecə və gündüz nəyə görə əmələ gəlir?','Yer öz oxu ətrafında fırlanır.',array['Yerin öz oxu ətrafında fırlanmasına görə','Günəşin sönməsinə görə','Ayın böyüməsinə görə','Buludların hərəkətinə görə'],1),
('hey3-yer-ay#5','hayat-bilgisi','hey-3-yer-ay',3,2,'Fəsillərin dəyişməsi nə ilə bağlıdır?','Yer Günəş ətrafında dövr edir.',array['Yerin Günəş ətrafında hərəkəti ilə','Küləklə','Ayın işığı ilə','Yağışla'],1),
('hey3-yer-ay#6','hayat-bilgisi','hey-3-yer-ay',2,2,'Yer Günəş ətrafında bir tam dövrü nə qədərə başa vurur?','Bir dövrə bir ilə başa gəlir.',array['1 ilə','1 günə','1 aya','1 saata'],1),
('hey3-yer-ay#7','hayat-bilgisi','hey-3-yer-ay',2,2,'Ay öz işığını yayırmı?','Ay Günəşin işığını əks etdirir.',array['Xeyr, Günəş işığını əks etdirir','Bəli, özü yanır','Yalnız qışda yayır','Yalnız gündüz yayır'],1),
('hey3-yer-ay#8','hayat-bilgisi','hey-3-yer-ay',2,2,'Qlobus nədir?','Qlobus Yerin kiçildilmiş modelidir.',array['Yerin kiçildilmiş modeli','Ayın xəritəsi','Oyuncaq top','Günəş saatı'],1),
('hey3-yer-ay#9','hayat-bilgisi','hey-3-yer-ay',1,2,'Yerin təbii peyki hansıdır?','Yerin bir təbii peyki var — Ay.',array['Ay','Günəş','Mars','Ulduz'],1),
('hey3-yer-ay#10','hayat-bilgisi','hey-3-yer-ay',1,2,'Gündüz göydə ən parlaq görünən göy cismi hansıdır?','Gündüz Günəş görünür.',array['Günəş','Ay','Ulduzlar','Planetlər'],1),
('hey3-materiallar#1','hayat-bilgisi','hey-3-materiallar',2,3,'Şüşənin xassələri hansılardır?','Şüşə şəffafdır, amma tez sınır.',array['Şəffafdır və kövrəkdir','Yumşaqdır və əyilir','Suda əriyir','Yanmır və əyilir'],1),
('hey3-materiallar#2','hayat-bilgisi','hey-3-materiallar',2,3,'Hansı material suda batmır?','Taxta sudan yüngüldür — üzür.',array['Taxta','Dəmir','Daş','Şüşə'],1),
('hey3-materiallar#3','hayat-bilgisi','hey-3-materiallar',2,3,'Maqnitə hansı əşya yapışar?','Maqnit dəmir əşyaları cəzb edir.',array['Dəmir mismar','Taxta qələm','Plastik qaşıq','Kağız vərəq'],1),
('hey3-materiallar#4','hayat-bilgisi','hey-3-materiallar',2,3,'Kağız nədən hazırlanır?','Kağız oduncaqdan istehsal olunur.',array['Oduncaqdan','Daşdan','Şüşədən','Dəmirdən'],1),
('hey3-materiallar#5','hayat-bilgisi','hey-3-materiallar',1,3,'Hansı material elastikdir — dartılıb əvvəlki halına qayıdır?','Rezin elastikdir.',array['Rezin','Şüşə','Daş','Çini'],1),
('hey3-materiallar#6','hayat-bilgisi','hey-3-materiallar',3,3,'Metallar istiliyi necə keçirir?','Metallar istiliyi yaxşı keçirir — qaynar qaba toxunmaq olmaz.',array['Yaxşı keçirir','Heç keçirmir','Yalnız qışda keçirir','Yalnız suda keçirir'],1),
('hey3-materiallar#7','hayat-bilgisi','hey-3-materiallar',2,3,'Hansı əşya kövrəkdir — düşəndə sınar?','Çini boşqab kövrəkdir.',array['Çini boşqab','Rezin top','Parça dəsmal','Plastik vedrə'],1),
('hey3-materiallar#8','hayat-bilgisi','hey-3-materiallar',3,3,'Plastik tullantılar təbiətə niyə zərərlidir?','Plastik uzun illər çürümür, təbiəti çirkləndirir.',array['Uzun illər çürümür','Tez əriyir','Gübrəyə çevrilir','Suda həll olur'],1),
('hey3-materiallar#9','hayat-bilgisi','hey-3-materiallar',2,3,'Suyu hansı qabda qaynatmaq təhlükəsizdir?','Metal qab oda davamlıdır.',array['Metal qabda','Plastik qabda','Kağız qabda','Şüşə olmayan karton qabda'],1),
('hey3-materiallar#10','hayat-bilgisi','hey-3-materiallar',1,3,'Parçanın xassəsi hansıdır?','Parça yumşaqdır, əyilir, tikilə bilir.',array['Yumşaqdır və əyilir','Bərkdir və sınır','Şəffafdır','Suda batmır və əriyir'],1),
('hey3-bayramlar#1','hayat-bilgisi','hey-3-bayramlar',1,3,'Novruz bayramı hansı fəsildə qeyd olunur?','Novruz yazın gəlişi bayramıdır.',array['Yazda','Qışda','Payızda','Yayda'],1),
('hey3-bayramlar#2','hayat-bilgisi','hey-3-bayramlar',1,3,'Hansı, Novruzun rəmzlərindəndir?','Səməni Novruzun əsas rəmzidir.',array['Səməni','Yolka','Balqabaq','Şam ağacı'],1),
('hey3-bayramlar#3','hayat-bilgisi','hey-3-bayramlar',3,3,'31 Dekabr hansı gündür?','31 Dekabr — Dünya Azərbaycanlılarının Həmrəyliyi Günüdür.',array['Dünya Azərbaycanlılarının Həmrəyliyi Günü','Zəfər Günü','Bilik Günü','Müəllim Günü'],1),
('hey3-bayramlar#4','hayat-bilgisi','hey-3-bayramlar',2,3,'Qənaət nə deməkdir?','Resurslardan israf etmədən istifadə etmək.',array['İsraf etmədən istifadə etmək','Heç nə xərcləməmək','Çox xərcləmək','Hər şeyi yığıb saxlamaq'],1),
('hey3-bayramlar#5','hayat-bilgisi','hey-3-bayramlar',1,3,'Suya qənaət üçün nə etməliyik?','Kranı boş yerə açıq qoymamaq lazımdır.',array['Kranı boş yerə açıq qoymamaq','Kranı həmişə açıq saxlamaq','Hər gün hovuz doldurmaq','Suyu dadmamaq'],1),
('hey3-bayramlar#6','hayat-bilgisi','hey-3-bayramlar',1,3,'İşığa qənaət üçün nə etməliyik?','Otaqdan çıxanda işığı söndürmək lazımdır.',array['Otaqdan çıxanda işığı söndürmək','Bütün lampaları yandırmaq','Gündüz də işıq yandırmaq','Heç vaxt söndürməmək'],1),
('hey3-bayramlar#7','hayat-bilgisi','hey-3-bayramlar',2,3,'Çörəyə münasibət necə olmalıdır?','Çörək zəhmətlə başa gəlir — israf etmək olmaz.',array['İsraf etməmək','Artığını atmaq','Oyun oynamaq','Yerə atmaq'],1),
('hey3-bayramlar#8','hayat-bilgisi','hey-3-bayramlar',3,3,'9 Noyabr hansı gündür?','9 Noyabr — Dövlət Bayrağı Günüdür.',array['Dövlət Bayrağı Günü','Yeni il','Novruz','Bilik Günü'],1),
('hey3-bayramlar#9','hayat-bilgisi','hey-3-bayramlar',2,3,'Novruz süfrəsinin şirniyyatları hansılardır?','Şəkərbura, paxlava, qoğal Novruz şirniyyatlarıdır.',array['Şəkərbura və paxlava','Tort və keks','Dondurma','Çips və qazlı içki'],1),
('hey3-bayramlar#10','hayat-bilgisi','hey-3-bayramlar',2,3,'Cib pulunu necə xərcləmək düzgündür?','Düşünülmüş, qənaətlə xərcləmək lazımdır.',array['Düşünülmüş və qənaətlə','Bir gündə hamısını','Yalnız oyunlara','Sayarkən itirmək'],1),
('hey3-tehlukesizlik#1','hayat-bilgisi','hey-3-tehlukesizlik',1,4,'Yolu keçmək üçün svetoforun hansı işığını gözləməliyik?','Piyada üçün yaşıl işıq yanmalıdır.',array['Yaşıl','Qırmızı','Sarı','İstənilən'],1),
('hey3-tehlukesizlik#2','hayat-bilgisi','hey-3-tehlukesizlik',1,4,'Küçəni haradan keçmək təhlükəsizdir?','Yalnız piyada keçidindən.',array['Piyada keçidindən','İstənilən yerdən','Maşınların arasından','Döngədən qaçaraq'],1),
('hey3-tehlukesizlik#3','hayat-bilgisi','hey-3-tehlukesizlik',2,4,'Evdə qaz iyi hiss edəndə nə etmək OLMAZ?','Qığılcım partlayışa səbəb ola bilər.',array['Kibrit yandırmaq','Pəncərəni açmaq','Böyüklərə demək','Evi tərk etmək'],1),
('hey3-tehlukesizlik#4','hayat-bilgisi','hey-3-tehlukesizlik',2,4,'Yanğın zamanı ilk növbədə nə etmək lazımdır?','112-yə zəng edib təhlükəli yerdən uzaqlaşmaq.',array['112-yə zəng edib evi tərk etmək','Gizlənmək','Özü söndürməyə çalışmaq','Heç nə etməmək'],1),
('hey3-tehlukesizlik#5','hayat-bilgisi','hey-3-tehlukesizlik',2,4,'Küçədə tapılan naməlum çantaya nə etməli?','Toxunmayıb böyüklərə xəbər vermək lazımdır.',array['Toxunmayıb böyüklərə demək','Açıb baxmaq','Evə aparmaq','Təpik vurmaq'],1),
('hey3-tehlukesizlik#6','hayat-bilgisi','hey-3-tehlukesizlik',1,4,'Elektrik rozetkasına nə salmaq olmaz?','Metal əşya cərəyan vurmasına səbəb olur.',array['Metal əşyalar','Cihazın öz ştepselini','Heç nə olmaz','Yalnız gündüz salmaq olar'],1),
('hey3-tehlukesizlik#7','hayat-bilgisi','hey-3-tehlukesizlik',2,4,'Velosipedi harada sürmək təhlükəsizdir?','Park və xüsusi zolaqlar bunun üçündür.',array['Parkda və xüsusi zolaqda','Maşın yolunda','Körpünün kənarında','Pilləkəndə'],1),
('hey3-tehlukesizlik#8','hayat-bilgisi','hey-3-tehlukesizlik',1,4,'Tanımadığın itə yaxınlaşmaq olarmı?','Naməlum heyvana yaxınlaşmaq təhlükəlidir.',array['Olmaz','Olar','Yalnız gecə olar','Yalnız qaçaraq olar'],1),
('hey3-tehlukesizlik#9','hayat-bilgisi','hey-3-tehlukesizlik',2,4,'Dərmanı uşağa kim verməlidir?','Dərmanı yalnız böyüklər, həkim təyinatı ilə verir.',array['Böyüklər, həkim təyinatı ilə','Uşaq özü','Sinif yoldaşı','Heç kim'],1),
('hey3-tehlukesizlik#10','hayat-bilgisi','hey-3-tehlukesizlik',2,4,'Su hövzəsində böyüksüz çimmək olarmı?','Təkbaşına çimmək təhlükəlidir.',array['Olmaz — təhlükəlidir','Olar','Yalnız isti gündə olar','Yalnız dayaz yerdə olar'],1),
('inf3-informasiya#1','informatika','inf-3-informasiya',1,1,'İnformasiyanı hansı orqanlarla qəbul edirik?','Görmə, eşitmə, iybilmə, dadbilmə, toxunma — hiss orqanları ilə.',array['Hiss orqanları ilə','Yalnız əllərlə','Yalnız qulaqla','Saçla'],1),
('inf3-informasiya#2','informatika','inf-3-informasiya',1,1,'Gözlə qəbul edilən informasiya hansıdır?','Şəkil, yazı, rəng — görmə informasiyasıdır.',array['Görmə','Səs','Dad','Qoxu'],1),
('inf3-informasiya#3','informatika','inf-3-informasiya',1,1,'Musiqi hansı informasiya növüdür?','Musiqini qulaqla qəbul edirik — səs informasiyasıdır.',array['Səs','Görmə','Dad','Toxunma'],1),
('inf3-informasiya#4','informatika','inf-3-informasiya',2,1,'Hansı sırada hamısı informasiya mənbəyidir?','Kitab da, televizor da, insan da məlumat verir.',array['Kitab, televizor, insan','Kitab, daş, qum','Televizor, boş vərəq, daş','Divar, qapı, döşəmə'],1),
('inf3-informasiya#5','informatika','inf-3-informasiya',2,1,'Məktəb zənginin səsi bizə nə bildirir?','Zəng dərsin başlandığını və ya bitdiyini bildirir.',array['Dərsin başlandığını və ya bitdiyini','Havanın istiliyini','Günün tarixini','Heç nə'],1),
('inf3-informasiya#6','informatika','inf-3-informasiya',2,1,'Hansı, informasiya daşıyıcısıdır?','Disk üzərində məlumat saxlanılır.',array['Disk','Stul','Pəncərə','Ayaqqabı'],1),
('inf3-informasiya#7','informatika','inf-3-informasiya',2,1,'Dad informasiyasını hansı orqanla qəbul edirik?','Dadı dil ilə hiss edirik.',array['Dil ilə','Göz ilə','Qulaq ilə','Burun ilə'],1),
('inf3-informasiya#8','informatika','inf-3-informasiya',2,1,'Hansı hərəkət informasiyanın ötürülməsidir?','Məktub göndərəndə məlumat başqasına çatdırılır.',array['Məktub göndərmək','Yatmaq','Qaçmaq','Yemək yemək'],1),
('inf3-informasiya#9','informatika','inf-3-informasiya',3,1,'Qədim dövrdə insanlar məlumatı necə ötürürdülər?','Çaparlar və məktublarla.',array['Çaparla və məktubla','Telefonla','İnternetlə','Televizorla'],1),
('inf3-informasiya#10','informatika','inf-3-informasiya',2,1,'Toxunmaqla əşyanın hansı xassəsini öyrənmək olar?','Hamar və ya kobud olduğunu toxunmaqla bilirik.',array['Hamar və ya kobud olduğunu','Rəngini','Səsini','Adını'],1),
('inf3-alqoritm#1','informatika','inf-3-alqoritm',2,2,'Hansı, alqoritmə misaldır?','Yemək resepti addım-addım icra qaydasıdır.',array['Yemək resepti','Şəkil','Mahnı','Rəng'],1),
('inf3-alqoritm#2','informatika','inf-3-alqoritm',1,2,'Alqoritmdə addımlar necə düzülür?','Addımlar icra sırası ilə, ardıcıl düzülür.',array['Ardıcıl','Qarışıq','Sondan əvvələ','İstənilən kimi'],1),
('inf3-alqoritm#3','informatika','inf-3-alqoritm',2,2,'«Səhər oyan → ? → geyin» alqoritmində buraxılmış addım hansı ola bilər?','Oyanandan sonra üz-əl yuyulur.',array['Üzünü yu','Axşam yeməyi ye','Yat','Məktəbdən qayıt'],1),
('inf3-alqoritm#4','informatika','inf-3-alqoritm',2,2,'Alqoritmi kim və ya nə icra edə bilər?','İcraçı insan, robot və ya kompüter ola bilər.',array['İnsan, robot, kompüter','Yalnız insan','Yalnız daş','Heç kim'],1),
('inf3-alqoritm#5','informatika','inf-3-alqoritm',2,2,'Alqoritmin addımları qarışdırılsa, nə olar?','Ardıcıllıq pozulsa, nəticə səhv alınar.',array['Nəticə səhv alınar','Heç nə dəyişməz','Daha tez bitər','Nəticə yaxşılaşar'],1),
('inf3-alqoritm#6','informatika','inf-3-alqoritm',1,2,'«Başla» və «Son» alqoritmin nəyini bildirir?','Alqoritmin haradan başlayıb harada bitdiyini.',array['Başlanğıcını və sonunu','Rəngini','Çəkisini','Müəllifini'],1),
('inf3-alqoritm#7','informatika','inf-3-alqoritm',3,2,'Hansı, alqoritm DEYİL?','Mənasız söz yığınında ardıcıl addımlar yoxdur.',array['Mənasız söz yığını','Çay dəmləmə qaydası','Əl yuma qaydası','Misal həlli qaydası'],1),
('inf3-alqoritm#8','informatika','inf-3-alqoritm',2,2,'Gülü suvarma alqoritmində birinci addım hansıdır?','Əvvəlcə suqabına su doldurulur.',array['Suqabına su doldurmaq','Gülü dibindən kəsmək','Torpağı atmaq','Yarpaqları yumaq'],1),
('inf3-alqoritm#9','informatika','inf-3-alqoritm',3,2,'«Alqoritm» sözü haradan yaranıb?','Alim Əl-Xarəzminin adından yaranıb.',array['Alim Əl-Xarəzminin adından','Şəhər adından','Oyun adından','Heyvan adından'],1),
('inf3-alqoritm#10','informatika','inf-3-alqoritm',2,2,'Misalın addım-addım həlli alqoritmdirmi?','Bəli — ardıcıl icra olunan addımlardır.',array['Bəli','Xeyr','Yalnız çətin misallarda','Yalnız dərslikdə'],1),
('inf3-kompyuter#1','informatika','inf-3-kompyuter',1,3,'Kompüterin əsas qurğuları hansılardır?','Sistem bloku, monitor, klaviatura və maus.',array['Sistem bloku, monitor, klaviatura, maus','Stol, stul, lampa','Kitab, dəftər, qələm','Televizor və pult'],1),
('inf3-kompyuter#2','informatika','inf-3-kompyuter',1,3,'Klaviatura nə üçündür?','Klaviatura ilə məlumat (hərf, rəqəm) daxil edilir.',array['Məlumat daxil etmək üçün','Səs eşitmək üçün','Şəkil göstərmək üçün','Çap etmək üçün'],1),
('inf3-kompyuter#3','informatika','inf-3-kompyuter',1,3,'Ekrandakı oxu (kursoru) hansı qurğu ilə hərəkət etdiririk?','Maus ekrandakı oxu idarə edir.',array['Maus','Printer','Dinamik','Mikrofon'],1),
('inf3-kompyuter#4','informatika','inf-3-kompyuter',2,3,'Kompüter arxasında iş vaxtı necə olmalıdır?','Məhdud vaxt, fasilələrlə işləmək lazımdır.',array['Məhdud, fasilələrlə','Bütün günü','Gecə boyu','Fasiləsiz'],1),
('inf3-kompyuter#5','informatika','inf-3-kompyuter',2,3,'Sistem blokunun içində nə yerləşir?','Prosessor və yaddaş sistem blokundadır.',array['Prosessor və yaddaş','Kitablar','Dinamik və mikrofon','Kağız və mürəkkəb'],1),
('inf3-kompyuter#6','informatika','inf-3-kompyuter',2,3,'Noutbuku masaüstü kompüterdən nə fərqləndirir?','Noutbuk yığcamdır, daşınabiləndir.',array['Daşına bilməsi','Ekranının olmaması','Klaviaturasının olmaması','İşləməməsi'],1),
('inf3-kompyuter#7','informatika','inf-3-kompyuter',2,3,'Planşet əsasən nə ilə idarə olunur?','Planşetin sensor ekranı toxunuşla işləyir.',array['Toxunuşla (sensor ekranla)','Pultla','Pedalla','Açarla'],1),
('inf3-kompyuter#8','informatika','inf-3-kompyuter',3,3,'«Enter» düyməsi nə edir?','Əmri təsdiqləyir, mətndə yeni sətrə keçirir.',array['Əmri təsdiqləyir','Kompüteri söndürür','Səsi artırır','Ekranı silir'],1),
('inf3-kompyuter#9','informatika','inf-3-kompyuter',2,3,'Faylları kompüterin harasında saxlayırıq?','Fayllar kompüterin yaddaşında saxlanılır.',array['Yaddaşında','Monitorunda','Mausunda','Naqilində'],1),
('inf3-kompyuter#10','informatika','inf-3-kompyuter',2,3,'Kompüter arxasında düzgün oturuş necədir?','Kürək düz, ekran gözdən aralı olmalıdır.',array['Kürək düz, ekrandan aralı','Ekrana yapışaraq','Uzanaraq','Ayaq üstə əyilərək'],1),
('inf3-metn#1','informatika','inf-3-metn',1,4,'Mətn redaktoru nə üçündür?','Mətn yazmaq və onu düzəltmək üçün proqramdır.',array['Mətn yazmaq və düzəltmək üçün','Oyun oynamaq üçün','Mahnı dinləmək üçün','Şəkil çəkmək üçün'],1),
('inf3-metn#2','informatika','inf-3-metn',2,4,'Böyük hərf yazmaq üçün hansı düymədən istifadə olunur?','Shift saxlanılıb hərf basılır.',array['Shift','Space','Esc','Tab'],1),
('inf3-metn#3','informatika','inf-3-metn',1,4,'Sözlər arasında boşluq hansı düymə ilə qoyulur?','Boşluq (Space) düyməsi ilə.',array['Boşluq (Space)','Enter','Shift','Backspace'],1),
('inf3-metn#4','informatika','inf-3-metn',2,4,'Səhv yazılmış son hərfi hansı düymə silir?','Backspace kursordan soldakı simvolu silir.',array['Backspace','Enter','Shift','Caps Lock'],1),
('inf3-metn#5','informatika','inf-3-metn',2,4,'Yeni sətrə keçmək üçün hansı düymə basılır?','Enter yeni sətrə keçirir.',array['Enter','Space','Shift','Alt'],1),
('inf3-metn#6','informatika','inf-3-metn',2,4,'Hansı, mətn redaktorudur?','Word mətn redaktorudur.',array['Word','Kalkulyator','Saat','Musiqi pleyeri'],1),
('inf3-metn#7','informatika','inf-3-metn',2,4,'Yazdığın mətni itirməmək üçün nə etməlisən?','Sənədi yadda saxlamaq (Save) lazımdır.',array['Yadda saxlamaq (Save)','Kompüteri söndürmək','Ekranı bağlamaq','Heç nə'],1),
('inf3-metn#8','informatika','inf-3-metn',2,4,'Kursor nədir?','Mətndə yazının qoyulacağı yeri göstərən işarədir.',array['Yazı yerini göstərən işarə','Şəkil növü','Proqram adı','Düymə adı'],1),
('inf3-metn#9','informatika','inf-3-metn',1,4,'Hərfləri hansı qurğu ilə yığırıq?','Mətn klaviatura ilə yığılır.',array['Klaviatura ilə','Mausla','Dinamiklə','Printerlə'],1),
('inf3-metn#10','informatika','inf-3-metn',2,4,'Yazdığınız mətni kağıza köçürən qurğu hansıdır?','Printer mətni kağıza çap edir.',array['Printer','Skaner','Mikrofon','Dinamik'],1)
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
    join public.levels   l on l.program_id = p.id and l.code = '3'
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
     and (ext_key like 'az3-%' or ext_key like 'hey3-%'
          or ext_key like 'inf3-%');
  if n <> 180 then
    raise exception 'sinif3 suallari: 180 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'az3-%' or q.ext_key like 'hey3-%'
          or q.ext_key like 'inf3-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az3-%' or ext_key like 'hey3-%'
      or ext_key like 'inf3-%';
  if k <> 18 then
    raise exception 'movzu sayi 18 deyil: %', k;
  end if;
  raise notice '3-cu sinif banki: % sual, 18 movzu (az dili, heyat bilgisi, informatika).', n;
end $$;
