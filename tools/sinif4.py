#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
4-cu sinfin qalan fennleri ucun platforma banki -> db/17_bank_sinif4.sql

    Azerbaycan dili 4   8 movzu x 10 = 80
    Heyat bilgisi 4     5 movzu x 10 = 50
    Informatika 4       3 movzu x 10 = 30
                                cemi  160

Riyaziyyatdaki kimi (tools/riy4.py) fayl elle yazilmir - bu skript
yaradir.  Dil suallarinda hesabla yoxlanan seyler: heca/sait sayi
(sait sayi = heca sayi qaydasi ile) proqramla sayilir.  Qalanlarda
struktur yoxlanir: 4 unikal variant, tek duzgun cavab, izah.

Isletmek:
    python3 tools/sinif4.py
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "17_bank_sinif4.sql")

SAITLER = set("aeəiıoöuü")


def sait(soz):
    """Sozdeki sait sayi (= heca sayi)."""
    return sum(1 for h in soz.lower() if h in SAITLER)


# (fenn-slug, movzu-slug, rub)
MOVZULAR = [
    ("az-dili", "az-4-isim-hallari",     1),
    ("az-dili", "az-4-metn-novleri",     1),
    ("az-dili", "az-4-sifet-dereceleri", 2),
    ("az-dili", "az-4-fel-zamanlari",    2),
    ("az-dili", "az-4-evezlik",          3),
    ("az-dili", "az-4-cumle-uzvleri",    3),
    ("az-dili", "az-4-durgu",            4),
    ("az-dili", "az-4-insa",             4),
    ("hayat-bilgisi", "hey-4-canli-heyat",   1),
    ("hayat-bilgisi", "hey-4-ferd-aile",     1),
    ("hayat-bilgisi", "hey-4-dovlet-huquq",  2),
    ("hayat-bilgisi", "hey-4-saglamliq-teh", 3),
    ("hayat-bilgisi", "hey-4-hereket-enerji",4),
    ("informatika", "inf-4-informasiya", 1),
    ("informatika", "inf-4-alqoritm",    2),
    ("informatika", "inf-4-kompyuter",   3),
]

SUALLAR = {
"az-4-isim-hallari": [
 ("İsmin neçə halı var?",
  "İsmin 6 halı var: adlıq, yiyəlik, yönlük, təsirlik, yerlik, çıxışlıq.",
  ["6", "5", "4", "3"], 1, None, 1),
 ("«Kitabın» sözü ismin hansı halındadır?",
  "-ın şəkilçisi yiyəlik halın şəkilçisidir: kitabın (nəyin?).",
  ["Yiyəlik", "Yönlük", "Adlıq", "Yerlik"], 1, None, 2),
 ("«Məktəbə» sözü ismin hansı halındadır?",
  "-a, -ə şəkilçisi yönlük halı bildirir: məktəbə (haraya?).",
  ["Yönlük", "Yerlik", "Çıxışlıq", "Yiyəlik"], 1, None, 2),
 ("«Bağçada» sözü ismin hansı halındadır?",
  "-da, -də şəkilçisi yerlik halı bildirir: bağçada (harada?).",
  ["Yerlik", "Yönlük", "Təsirlik", "Adlıq"], 1, None, 2),
 ("«Şəhərdən» sözü ismin hansı halındadır?",
  "-dan, -dən şəkilçisi çıxışlıq halı bildirir: şəhərdən (haradan?).",
  ["Çıxışlıq", "Yerlik", "Yönlük", "Yiyəlik"], 1, None, 2),
 ("Hansı söz adlıq haldadır?",
  "Adlıq halda söz hal şəkilçisiz olur və «kim? nə?» sualına cavab verir.",
  ["qələm", "qələmin", "qələmə", "qələmdə"], 1, None, 2),
 ("«Aysu kitabı rəfə qoydu» cümləsində «kitabı» sözü hansı haldadır?",
  "-ı şəkilçisi burada təsirlik halı bildirir: kitabı (nəyi?).",
  ["Təsirlik", "Yiyəlik", "Yerlik", "Adlıq"], 1, None, 3),
 ("Yerlik halın şəkilçiləri hansılardır?",
  "Yerlik hal «harada?» sualına cavab verir, şəkilçiləri -da, -də-dir.",
  ["-da, -də", "-dan, -dən", "-a, -ə", "-ın, -in"], 1, None, 2),
 ("«Evin qapısı» birləşməsində «evin» sözü hansı haldadır?",
  "«Evin» (nəyin?) — yiyəlik haldadır, mənsubiyyət bildirir.",
  ["Yiyəlik", "Adlıq", "Yönlük", "Çıxışlıq"], 1, None, 3),
 ("Hansı sözdə çıxışlıq hal şəkilçisi var?",
  "Meşədən (haradan?) — çıxışlıq hal.",
  ["meşədən", "meşədə", "meşəyə", "meşəni"], 1, None, 2),
],
"az-4-metn-novleri": [
 ("Mətn nədir?",
  "Mətn məzmunca bir-biri ilə bağlı cümlələrin ardıcıllığıdır.",
  ["Bir-biri ilə bağlı cümlələrin ardıcıllığı", "Ayrı-ayrı sözlərin siyahısı",
   "Bir cümlə", "Hərflərin cərgəsi"], 1, None, 1),
 ("Mətnin hissələri hansılardır?",
  "Mətn giriş, əsas hissə və nəticədən ibarət olur.",
  ["Giriş, əsas hissə, nəticə", "Başlıq və şəkil",
   "Sual və cavab", "Söz və cümlə"], 1, None, 1),
 ("Hadisəni baş vermə ardıcıllığı ilə danışan mətn necə adlanır?",
  "Nəqli mətn hadisəni ardıcıllıqla nəql edir.",
  ["Nəqli mətn", "Təsviri mətn", "Mühakimə mətni", "Elan"], 1, None, 2),
 ("Əşyanı, təbiəti və ya insanı təsvir edən mətn necə adlanır?",
  "Təsviri mətn əlamətləri sadalayıb təsvir yaradır.",
  ["Təsviri mətn", "Nəqli mətn", "Mühakimə mətni", "Məktub"], 1, None, 2),
 ("Fikri əsaslandırıb sübut edən mətn necə adlanır?",
  "Mühakimə mətnində fikir irəli sürülür və səbəblərlə əsaslandırılır.",
  ["Mühakimə mətni", "Nəqli mətn", "Təsviri mətn", "Nağıl"], 1, None, 3),
 ("Nağıl hansı mətn növünə daha yaxındır?",
  "Nağılda hadisələr ardıcıl nəql olunur.",
  ["Nəqli", "Təsviri", "Mühakimə", "Elan"], 1, None, 2),
 ("«Payız meşəsi çox gözəldir. Yarpaqlar saralmış, hava sərindir…» — "
  "bu parça hansı mətn növüdür?",
  "Parça meşənin əlamətlərini təsvir edir.",
  ["Təsviri", "Nəqli", "Mühakimə", "Dialoq"], 1, None, 3),
 ("Mətnə başlıq nəyə əsasən seçilir?",
  "Başlıq mətnin əsas fikrini əks etdirməlidir.",
  ["Əsas fikrə", "Cümlələrin sayına", "İlk sözə", "Mətnin uzunluğuna"],
  1, None, 2),
 ("Şeiri hekayədən fərqləndirən əsas xüsusiyyət nədir?",
  "Şeir misralarla, çox vaxt qafiyəli yazılır.",
  ["Misralarla yazılması", "Uzun olması", "Başlığının olması",
   "Cümlələrdən ibarət olması"], 1, None, 2),
 ("Mətndəki cümlələr necə olmalıdır?",
  "Cümlələr məzmunca bağlı olmasa, mətn alınmaz.",
  ["Məzmunca bir-biri ilə bağlı", "Hamısı sual cümləsi",
   "Bir-birindən asılı olmayan", "Hamısı eyni sözlə başlayan"], 1, None, 1),
],
"az-4-sifet-dereceleri": [
 ("Sifət nəyi bildirir?",
  "Sifət əşyanın əlamətini bildirir: necə? nə cür? hansı?",
  ["Əşyanın əlamətini", "Hərəkəti", "Miqdarı", "Əşyanın adını"], 1, None, 1),
 ("Sifətin neçə dərəcəsi var?",
  "Sifətin üç dərəcəsi var: adi, azaltma, çoxaltma.",
  ["3", "2", "4", "6"], 1, None, 1),
 ("«Qıpqırmızı» sifəti hansı dərəcədədir?",
  "İlk hecanın təkrarı ilə düzələn belə sifətlər çoxaltma dərəcəsindədir.",
  ["Çoxaltma", "Azaltma", "Adi", "Heç biri"], 1, None, 2),
 ("«Sarımtıl» sifəti hansı dərəcədədir?",
  "-ımtıl şəkilçisi əlamətin azlığını bildirir.",
  ["Azaltma", "Çoxaltma", "Adi", "Heç biri"], 1, None, 2),
 ("«Hündür» sifəti hansı dərəcədədir?",
  "Şəkilçisiz, adi qaydada deyilən sifət adi dərəcədədir.",
  ["Adi", "Azaltma", "Çoxaltma", "Heç biri"], 1, None, 2),
 ("«Ən maraqlı» birləşməsində sifət hansı dərəcədədir?",
  "«Ən» sözü ilə çoxaltma dərəcəsi düzəlir.",
  ["Çoxaltma", "Azaltma", "Adi", "Heç biri"], 1, None, 2),
 ("Hansı sırada bütün sözlər sifətdir?",
  "Gözəl, uca, şirin — hamısı əlamət bildirir.",
  ["gözəl, uca, şirin", "gözəl, qaçmaq, beş",
   "dağ, uca, kitab", "şirin, oxumaq, alma"], 1, None, 2),
 ("Çoxaltma dərəcəsində olan sifəti seçin.",
  "«Dümağ» — əlamətin çoxluğunu bildirir.",
  ["dümağ", "sarımtıl", "göyümtül", "qara"], 1, None, 2),
 ("Azaltma dərəcəsində olan sifət hansıdır?",
  "-ımtıl şəkilçisi azaltma dərəcəsini düzəldir.",
  ["ağımtıl", "qapqara", "dümağ", "yamyaşıl"], 1, None, 2),
 ("«Daha güclü» birləşməsi sifətin hansı dərəcəsini bildirir?",
  "«Daha» sözü ilə əlamətin çoxluğu — çoxaltma dərəcəsi bildirilir.",
  ["Çoxaltma", "Azaltma", "Adi", "Heç biri"], 1, None, 3),
],
"az-4-fel-zamanlari": [
 ("Fel nəyi bildirir?",
  "Fel hərəkəti bildirir: nə edir? nə etdi? nə edəcək?",
  ["Hərəkəti", "Əlaməti", "Miqdarı", "Əşyanın adını"], 1, None, 1),
 ("Felin neçə zamanı var?",
  "Felin üç zamanı var: keçmiş, indiki, gələcək.",
  ["3", "2", "4", "5"], 1, None, 1),
 ("«Oxudu» feli hansı zamandadır?",
  "-du şəkilçisi keçmiş zamanı bildirir.",
  ["Keçmiş", "İndiki", "Gələcək", "Heç biri"], 1, None, 2),
 ("«Yazır» feli hansı zamandadır?",
  "-ır şəkilçisi indiki zamanı bildirir: hərəkət indi baş verir.",
  ["İndiki", "Keçmiş", "Gələcək", "Heç biri"], 1, None, 2),
 ("«Gedəcək» feli hansı zamandadır?",
  "-acaq, -əcək şəkilçisi gələcək zamanı bildirir.",
  ["Gələcək", "İndiki", "Keçmiş", "Heç biri"], 1, None, 2),
 ("Hansı fel indiki zamandadır?",
  "«Baxır» — hərəkət danışılan anda baş verir.",
  ["baxır", "baxdı", "baxacaq", "baxmışdı"], 1, None, 2),
 ("«Sabah kitab oxuyacağam» cümləsindəki fel hansı zamandadır?",
  "-acağ(am) şəkilçisi gələcək zamanı göstərir; «sabah» sözü də ipucudur.",
  ["Gələcək", "İndiki", "Keçmiş", "Heç biri"], 1, None, 2),
 ("Keçmiş zamanda olan feli seçin.",
  "«Gəldi» — hərəkət artıq baş verib.",
  ["gəldi", "gəlir", "gələcək", "gəl"], 1, None, 2),
 ("«Yağış yağırdı» cümləsindəki fel hansı zamana aiddir?",
  "Hərəkət keçmişdə davam edirdi — keçmiş zamandır.",
  ["Keçmiş", "İndiki", "Gələcək", "Heç biri"], 1, None, 3),
 ("Hansı söz feldir?",
  "Fellər «nə etmək?» sualına cavab verir: qaçmaq.",
  ["qaçmaq", "qaçış", "cəld", "yol"], 1, None, 3),
],
"az-4-evezlik": [
 ("Şəxs əvəzlikləri nəyi əvəz edir?",
  "Şəxs əvəzlikləri şəxs adlarının yerində işlənir.",
  ["Şəxs adlarını", "Felləri", "Sayları", "Bağlayıcıları"], 1, None, 1),
 ("Hansı söz əvəzlikdir?",
  "«Onlar» — III şəxsin cəmini bildirən şəxs əvəzliyidir.",
  ["onlar", "kitab", "oxuyur", "gözəl"], 1, None, 1),
 ("«Mən» əvəzliyi hansı şəxsdədir?",
  "Danışan özü — I şəxsin təki.",
  ["I şəxsin təki", "II şəxsin təki", "III şəxsin təki", "I şəxsin cəmi"],
  1, None, 2),
 ("«Siz» əvəzliyi hansı şəxsdədir?",
  "Müraciət olunan şəxslər — II şəxsin cəmi.",
  ["II şəxsin cəmi", "II şəxsin təki", "III şəxsin cəmi", "I şəxsin cəmi"],
  1, None, 2),
 ("III şəxsin təki hansı əvəzlikdir?",
  "Haqqında danışılan bir şəxs — «o».",
  ["o", "biz", "sən", "onlar"], 1, None, 2),
 ("«O, dərsə gecikdi» cümləsində əvəzlik hansıdır?",
  "«O» — III şəxsin təkini bildirən əvəzlikdir.",
  ["O", "dərsə", "gecikdi", "cümlədə əvəzlik yoxdur"], 1, None, 2),
 ("Hansı sırada yalnız əvəzliklər verilib?",
  "Mən, sən, biz — hamısı şəxs əvəzliyidir.",
  ["mən, sən, biz", "mən, kitab, o", "sən, gözəl, biz", "o, oxudu, siz"],
  1, None, 2),
 ("«Biz» əvəzliyi hansı şəxsdədir?",
  "Danışan özü ilə birlikdə başqalarını da nəzərdə tutur — I şəxsin cəmi.",
  ["I şəxsin cəmi", "I şəxsin təki", "II şəxsin cəmi", "III şəxsin cəmi"],
  1, None, 2),
 ("Cümləni tamamlayın: «… sabah teatra gedəcəyik.»",
  "Felin sonluğu (-ik) I şəxsin cəmini göstərir: biz.",
  ["Biz", "Mən", "Sən", "O"], 1, None, 3),
 ("«Bu» sözü hansı əvəzlikdir?",
  "«Bu, o» yaxındakı və uzaqdakı əşyaya işarə edir — işarə əvəzliyidir.",
  ["İşarə əvəzliyi", "Şəxs əvəzliyi", "Sual əvəzliyi", "Əvəzlik deyil"],
  1, None, 3),
],
"az-4-cumle-uzvleri": [
 ("Cümlənin baş üzvləri hansılardır?",
  "Cümlənin baş üzvləri mübtəda və xəbərdir.",
  ["Mübtəda və xəbər", "İsim və fel", "Söz və heca", "Sual və nida"],
  1, None, 1),
 ("Mübtəda hansı suallara cavab verir?",
  "Mübtəda «kim? nə?» suallarına cavab verir.",
  ["Kim? Nə?", "Nə edir?", "Harada?", "Necə?"], 1, None, 2),
 ("«Uşaqlar həyətdə oynayırlar» cümləsində mübtəda hansıdır?",
  "Oynayan kimdir? — Uşaqlar.",
  ["Uşaqlar", "həyətdə", "oynayırlar", "cümlədə mübtəda yoxdur"],
  1, None, 2),
 ("«Külək şiddətlə əsir» cümləsində xəbər hansıdır?",
  "Külək nə edir? — Əsir.",
  ["əsir", "Külək", "şiddətlə", "cümlədə xəbər yoxdur"], 1, None, 2),
 ("Xəbər adətən cümlənin harasında durur?",
  "Azərbaycan dilində xəbər adətən cümlənin sonunda gəlir.",
  ["Sonunda", "Əvvəlində", "Ortasında", "İstənilən yerdə qaydasızdır"],
  1, None, 2),
 ("«Aysu maraqlı kitab oxuyur» cümləsində mübtəda hansıdır?",
  "Oxuyan kimdir? — Aysu.",
  ["Aysu", "maraqlı", "kitab", "oxuyur"], 1, None, 2),
 ("«Qar yağır» cümləsində «yağır» sözü hansı üzvdür?",
  "Qar nə edir? — yağır: xəbərdir.",
  ["Xəbər", "Mübtəda", "Üzv deyil", "Başlıq"], 1, None, 2),
 ("Xəbər hansı suala cavab verir?",
  "Xəbər «nə edir? nə etdi? nə edəcək?» suallarına cavab verir.",
  ["Nə edir?", "Kim?", "Hansı?", "Neçə?"], 1, None, 2),
 ("Hansı cümlədə mübtəda ayrıca sözlə ifadə olunmayıb?",
  "«(Mən) dərsə gedirəm» — şəxs sonluğu mübtədanı əvəz edir.",
  ["Dərsə gedirəm.", "Aysu şəkil çəkir.", "Quşlar uçur.", "Müəllim danışır."],
  1, None, 3),
 ("«Şagirdlər müəllimi diqqətlə dinləyirdilər» cümləsində mübtəda hansıdır?",
  "Dinləyən kimdir? — Şagirdlər.",
  ["Şagirdlər", "müəllimi", "diqqətlə", "dinləyirdilər"], 1, None, 3),
],
"az-4-durgu": [
 ("Nəqli cümlənin sonunda hansı işarə qoyulur?",
  "Nəqli cümlə adi məlumat bildirir, sonunda nöqtə qoyulur.",
  ["Nöqtə", "Sual işarəsi", "Nida işarəsi", "Vergül"], 1, None, 1),
 ("Sual cümləsinin sonunda hansı işarə qoyulur?",
  "Sual bildirən cümlənin sonunda sual işarəsi qoyulur.",
  ["Sual işarəsi", "Nöqtə", "Nida işarəsi", "Tire"], 1, None, 1),
 ("Hansı cümlənin sonunda nida işarəsi qoyulmalıdır?",
  "Hiss-həyəcan bildirən cümlənin sonunda nida işarəsi qoyulur.",
  ["Nə gözəl mənzərədir", "Sən hara gedirsən",
   "Mən kitab oxuyuram", "Sabah hava necə olacaq"], 1, None, 2),
 ("Sadalanan üzvlər arasında hansı işarə qoyulur?",
  "Sadalanan sözlər vergüllə ayrılır.",
  ["Vergül", "Nöqtə", "Tire", "Sual işarəsi"], 1, None, 2),
 ("«Bakı(?) Gəncə və Şəki qədim şəhərlərdir» — mötərizənin yerinə "
  "hansı işarə qoyulmalıdır?",
  "Sadalanan sözlər arasında vergül qoyulur: Bakı, Gəncə və Şəki.",
  ["Vergül", "Nöqtə", "Nida işarəsi", "Heç nə"], 1, None, 2),
 ("«Aysu(?) bura gəl!» — xitabdan sonra hansı işarə qoyulmalıdır?",
  "Xitab cümlə üzvlərindən vergüllə ayrılır.",
  ["Vergül", "Nöqtə", "Sual işarəsi", "Heç nə"], 1, None, 3),
 ("Dialoqda replikaların əvvəlində hansı işarə qoyulur?",
  "Hər danışanın sözü yeni sətirdən tire ilə başlanır.",
  ["Tire", "Vergül", "Nöqtə", "Nida işarəsi"], 1, None, 3),
 ("Hansı cümlənin sonunda sual işarəsi qoyulmalıdır?",
  "«Dərslər neçədə başlayır» — sual bildirir.",
  ["Dərslər neçədə başlayır", "Dərslər doqquzda başlayır",
   "Məktəbimiz böyükdür", "Yaz gəldi"], 1, None, 2),
 ("Hansı cümlədə vergül düzgün qoyulub?",
  "Xitab («əziz dostum») vergüllə ayrılır.",
  ["Salam, əziz dostum!", "Salam əziz, dostum!",
   "Sa,lam əziz dostum!", "Salam əziz dostum,!"], 1, None, 3),
 ("«Sən sabah gələcəksənmi(?)» — cümlənin sonunda hansı işarə qoyulmalıdır?",
  "-mi ədatı cümləni sual cümləsi edir.",
  ["Sual işarəsi", "Nöqtə", "Vergül", "Tire"], 1, None, 2),
],
"az-4-insa": [
 ("İnşa yazmağa nədən başlamaq lazımdır?",
  "Əvvəlcə plan qurulur, sonra hissə-hissə yazılır.",
  ["Plan qurmaqdan", "Nəticədən", "Şəkil çəkməkdən", "Başlıqsız yazmaqdan"],
  1, None, 1),
 ("Cümlə hansı hərflə başlanır?",
  "Hər cümlə böyük hərflə başlanır.",
  ["Böyük hərflə", "Kiçik hərflə", "İstənilən hərflə", "Rəqəmlə"],
  1, None, 1),
 ("Hansı söz həmişə böyük hərflə yazılır?",
  "Xüsusi isimlər — şəhər, insan, çay adları — böyük hərflə yazılır.",
  ["Bakı", "kitab", "məktəb", "ağac"], 1, None, 1),
 ("Sözü sətirdən sətrə necə keçirirlər?",
  "Söz sətirdən sətrə hecalarla keçirilir.",
  ["Hecalarla", "Hərflərlə", "İstənilən yerdən", "Sözü keçirmək olmaz"],
  1, None, 2),
 ("«Məktəblilər» sözündə neçə heca var?",
  "Sözdə neçə sait varsa, o qədər heca var: mək-təb-li-lər.",
  ["4", "3", "5", "2"], 1, str(sait("Məktəblilər")), 2),
 ("Hansı sözü sətirdən sətrə keçirmək olmaz?",
  "Birhecalı sözlər sətirdən sətrə keçirilmir.",
  ["dağ", "kitab", "dəftər", "məktəb"], 1, None, 2),
 ("«Qaranquş» sözündə neçə sait var?",
  "Saitlər: a, a, u — üç sait, deməli üç heca.",
  ["3", "2", "4", "5"], 1, str(sait("Qaranquş")), 2),
 ("Məktuba adətən necə başlayırlar?",
  "Məktub müraciətlə başlanır: «Əziz ana!»",
  ["Müraciətlə: «Əziz ana!»", "Nəticə ilə", "İmza ilə", "Tarixsiz və adsız"],
  1, None, 2),
 ("İnşanın sonunda nə yazılır?",
  "Sonda yekun fikir — nəticə verilir.",
  ["Nəticə — yekun fikir", "Yeni mövzu", "Sual siyahısı", "Lüğət"],
  1, None, 2),
 ("«Kitabxana» sözü neçə hecadan ibarətdir?",
  "Ki-tab-xa-na: dörd heca.",
  ["4", "3", "5", "2"], 1, str(sait("Kitabxana")), 3),
],
"hey-4-canli-heyat": [
 ("Canlıları cansızlardan fərqləndirən əsas əlamət hansıdır?",
  "Canlılar qidalanır, böyüyür, çoxalır və tənəffüs edir.",
  ["Böyüməsi və çoxalması", "Yerində durması",
   "Rənginin olması", "Formasının olması"], 1, None, 1),
 ("Bitkilər qidasını əsasən harada hazırlayır?",
  "Bitkilər günəş işığının köməyi ilə yarpaqlarında qida hazırlayır.",
  ["Yarpaqlarında", "Köklərində saxlanan daşlarda",
   "Torpağın altında hazır alır", "Başqa bitkilərdən alır"], 1, None, 2),
 ("Hansı canlı məməlidir?",
  "Delfin balalarını süd ilə bəsləyir — məməlidir.",
  ["Delfin", "Qartal", "İlan", "Sazan balığı"], 1, None, 3),
 ("Toxumun cücərməsi üçün nə lazımdır?",
  "Su, hava və istilik olmasa, toxum cücərməz.",
  ["Su, hava və istilik", "Yalnız qaranlıq",
   "Yalnız külək", "Heç nə lazım deyil"], 1, None, 2),
 ("Hansı sırada yalnız canlılar verilib?",
  "Göbələk, qarışqa və palıd canlıdır; daş və su cansızdır.",
  ["göbələk, qarışqa, palıd", "daş, qarışqa, palıd",
   "göbələk, su, daş", "qum, daş, bulud"], 1, None, 2),
 ("Quşları başqa canlılardan fərqləndirən əlamət hansıdır?",
  "Bütün quşların bədəni lələklə örtülüdür; uçmaq hamısına aid deyil.",
  ["Bədənlərinin lələklə örtülməsi", "Uçmaları",
   "Suda üzmələri", "Yumurtadan çıxmaları"], 1, None, 3),
 ("Bitkinin hansı hissəsi onu torpağa bağlayır?",
  "Kök bitkini torpağa bağlayır, su və mineralları çəkir.",
  ["Kök", "Yarpaq", "Çiçək", "Meyvə"], 1, None, 1),
 ("Canlıların tənəffüsü üçün hansı qaz vacibdir?",
  "Canlılar oksigenlə tənəffüs edir.",
  ["Oksigen", "Karbon qazı", "Hidrogen", "Tüstü"], 1, None, 2),
 ("Hansı heyvan qış yuxusuna gedir?",
  "Ayı qışda yuxuya gedir, yazda oyanır.",
  ["Ayı", "Canavar", "Tülkü", "Dovşan"], 1, None, 2),
 ("Meyvə bitkinin hansı hissəsindən əmələ gəlir?",
  "Çiçək tozlanandan sonra onun yerində meyvə əmələ gəlir.",
  ["Çiçəkdən", "Kökdən", "Yarpaqdan", "Gövdədən"], 1, None, 3),
],
"hey-4-ferd-aile": [
 ("Ailə üzvləri bir-birinə necə davranmalıdır?",
  "Ailənin təməli qarşılıqlı hörmət və qayğıdır.",
  ["Hörmət və qayğı ilə", "Biganə", "Yalnız bayramlarda mehriban",
   "Kobud"], 1, None, 1),
 ("Cəmiyyət nədir?",
  "Bir yerdə yaşayıb bir-biri ilə əlaqədə olan insanlar cəmiyyət qurur.",
  ["Birlikdə yaşayan insanların birliyi", "Binaların cəmi",
   "Bir ailənin adı", "Yalnız bir sinifin şagirdləri"], 1, None, 2),
 ("Şagirdin məktəbdəki əsas vəzifəsi nədir?",
  "Oxumaq, öyrənmək və məktəb qaydalarına əməl etmək.",
  ["Oxumaq və qaydalara əməl etmək", "Yalnız oynamaq",
   "Dərsdən qaçmaq", "Başqalarına mane olmaq"], 1, None, 1),
 ("Böyüklərlə rastlaşanda necə davranmaq düzgündür?",
  "Nəzakətlə salamlaşmaq hörmətin əlamətidir.",
  ["Nəzakətlə salam vermək", "Görməzlikdən gəlmək",
   "Ucadan qışqırmaq", "Yolunu kəsmək"], 1, None, 1),
 ("Ailə büdcəsi nədir?",
  "Ailənin bütün gəlirləri və xərcləri birlikdə büdcəni təşkil edir.",
  ["Ailənin gəlir və xərclərinin cəmi", "Yalnız uşaqların cib pulu",
   "Mağazadakı qiymətlər", "Bankdakı növbə"], 1, None, 3),
 ("Hansı davranış düzgündür?",
  "İctimai yerlərdə növbəyə riayət etmək lazımdır.",
  ["Növbəyə riayət etmək", "Növbəsiz keçmək",
   "Ucadan musiqi açmaq", "Zibili yerə atmaq"], 1, None, 2),
 ("İnsan peşə seçərkən nəyi nəzərə almalıdır?",
  "Peşə bacarıq və maraqlara uyğun seçilməlidir.",
  ["Bacarıq və maraqlarını", "Yalnız adının gözəlliyini",
   "Dostunun seçimini", "Təsadüfü"], 1, None, 2),
 ("Qonşularla münasibətdə nə vacibdir?",
  "Qonşuluq mehribanlıq və qarşılıqlı yardım üzərində qurulur.",
  ["Mehribanlıq və qarşılıqlı yardım", "Yüksək səslə musiqi",
   "Küsülü qalmaq", "Bir-birini tanımamaq"], 1, None, 2),
 ("Birgə işdə vəzifələr necə bölünməlidir?",
  "İş ədalətlə, hər kəsin bacarığına görə bölünməlidir.",
  ["Ədalətlə, bacarığa görə", "Hamısı bir nəfərə",
   "Püşksüz və qaydasız", "Yalnız böyüklərə"], 1, None, 3),
 ("Hansı keyfiyyət insana hörmət qazandırır?",
  "Düz danışan adama etibar edirlər.",
  ["Düzlük", "Yalançılıq", "Paxıllıq", "Kobudluq"], 1, None, 1),
],
"hey-4-dovlet-huquq": [
 ("Azərbaycanın paytaxtı hansı şəhərdir?",
  "Azərbaycan Respublikasının paytaxtı Bakıdır.",
  ["Bakı", "Gəncə", "Sumqayıt", "Şəki"], 1, None, 1),
 ("Dövlət rəmzləri hansılardır?",
  "Dövlətin üç rəmzi var: bayraq, gerb, himn.",
  ["Bayraq, gerb, himn", "Pul, mahnı, şəkil",
   "Xəritə, kitab, bayraq", "Gerb, xalça, çay"], 1, None, 1),
 ("Azərbaycan bayrağında neçə rəng var?",
  "Bayrağımız üçrənglidir.",
  ["3", "2", "4", "5"], 1, None, 1),
 ("Bayrağımızın zolaqları yuxarıdan aşağı hansı sıra ilə düzülür?",
  "Mavi — türkçülük, qırmızı — müasirlik, yaşıl — islam mədəniyyəti.",
  ["Mavi, qırmızı, yaşıl", "Qırmızı, mavi, yaşıl",
   "Yaşıl, qırmızı, mavi", "Mavi, yaşıl, qırmızı"], 1, None, 2),
 ("Azərbaycan Respublikasının əsas qanunu necə adlanır?",
  "Dövlətin əsas qanunu Konstitusiyadır.",
  ["Konstitusiya", "Himn", "Nizamnamə", "Lüğət"], 1, None, 2),
 ("Bayrağımızın üzərindəki aypara və səkkizguşəli ulduz hansı rəngdədir?",
  "Qırmızı zolağın üzərində ağ aypara və ulduz təsvir olunub.",
  ["Ağ", "Sarı", "Qara", "Mavi"], 1, None, 3),
 ("8 Noyabr hansı bayramdır?",
  "8 Noyabr — Zəfər Günüdür.",
  ["Zəfər Günü", "Novruz bayramı", "Bilik Günü", "Yeni il"], 1, None, 2),
 ("Dövlət himni səslənəndə necə davranmaq lazımdır?",
  "Himnə hörmət əlaməti olaraq ayağa qalxırlar.",
  ["Ayağa qalxmaq", "Oturub danışmaq", "Gülmək", "Otaqdan çıxmaq"],
  1, None, 2),
 ("Azərbaycanın dövlət dili hansıdır?",
  "Dövlət dilimiz Azərbaycan dilidir.",
  ["Azərbaycan dili", "İngilis dili", "Rus dili", "Türk dili"], 1, None, 1),
 ("Vətəndaşın əsas borcu nədir?",
  "Vətəni sevmək, qorumaq və qanunlara əməl etmək hər kəsin borcudur.",
  ["Vətəni qorumaq və qanunlara əməl etmək", "Yalnız istirahət etmək",
   "Qanunları pozmaq", "Heç nə etməmək"], 1, None, 2),
],
"hey-4-saglamliq-teh": [
 ("Gündə neçə dəfə diş fırçalamaq məsləhətdir?",
  "Səhər və axşam — gündə 2 dəfə.",
  ["2 dəfə", "Həftədə 1 dəfə", "Ayda 1 dəfə", "Heç fırçalamamaq"],
  1, None, 1),
 ("Yeməkdən əvvəl nə etmək vacibdir?",
  "Əlləri sabunla yumaq mikroblardan qoruyur.",
  ["Əlləri yumaq", "Qaçmaq", "Yatmaq", "Televizora baxmaq"], 1, None, 1),
 ("Piyadalar yolu haradan keçməlidir?",
  "Yol yalnız piyada keçidindən keçilir.",
  ["Piyada keçidindən", "İstənilən yerdən", "Maşınların arasından",
   "Qaçaraq istənilən yerdən"], 1, None, 1),
 ("Svetoforun hansı işığında yolu keçmək olar?",
  "Yaşıl işıq piyadaya yol verir.",
  ["Yaşıl", "Qırmızı", "Sarı", "İstənilən"], 1, None, 1),
 ("Yanğın və digər fövqəladə hal zamanı hansı nömrəyə zəng edilməlidir?",
  "112 — fövqəladə hallar üçün vahid çağırış nömrəsidir.",
  ["112", "103", "999", "555"], 1, None, 2),
 ("Evdə tək olanda tanımadığın adam qapını döysə, nə etməlisən?",
  "Qapını açmamaq və böyüklərə xəbər vermək lazımdır.",
  ["Qapını açmamaq, böyüklərə xəbər vermək", "Dərhal qapını açmaq",
   "Qapını açıb kim olduğunu soruşmaq", "Qonaq çağırmaq"], 1, None, 2),
 ("Sağlam qidalanma üçün nə vacibdir?",
  "Meyvə-tərəvəz vitaminlərlə zəngindir.",
  ["Meyvə-tərəvəz yemək", "Yalnız şirniyyat yemək",
   "Gündə bir dəfə çips yemək", "Yalnız sərinləşdirici içmək"], 1, None, 2),
 ("Elektrik cihazları ilə davranarkən nə etmək olmaz?",
  "Yaş əllə elektrik cihazına toxunmaq təhlükəlidir.",
  ["Yaş əllə toxunmaq", "Böyüklə birlikdə işlətmək",
   "İşlətdikdən sonra söndürmək", "Təlimata baxmaq"], 1, None, 2),
 ("Kiçik məktəbli gecə təxminən neçə saat yatmalıdır?",
  "Bu yaşda 9-10 saat yuxu məsləhət görülür.",
  ["9-10 saat", "4-5 saat", "2-3 saat", "15-16 saat"], 1, None, 3),
 ("Velosiped sürərkən başa nə taxmaq lazımdır?",
  "Dəbilqə yıxılanda başı zədədən qoruyur.",
  ["Dəbilqə", "Panama", "Heç nə", "Qulaqlıq"], 1, None, 2),
],
"hey-4-hereket-enerji": [
 ("Günəş bizə nə verir?",
  "Günəş Yerə işıq və istilik verir.",
  ["İşıq və istilik", "Yalnız kölgə", "Külək", "Yağış"], 1, None, 1),
 ("Hansı cisim öz işığını yayır?",
  "Günəş işıq mənbəyidir; Ay yalnız onun işığını əks etdirir.",
  ["Günəş", "Ay", "Güzgü", "Pəncərə"], 1, None, 2),
 ("Enerjiyə qənaət üçün nə etməliyik?",
  "İstifadə olunmayan işıqları söndürmək enerjiyə qənaətdir.",
  ["İşlətmədiyimiz işığı söndürmək", "Bütün lampaları yandırmaq",
   "Suyu açıq qoymaq", "Televizoru söndürməmək"], 1, None, 1),
 ("Külək enerjisindən nə üçün istifadə olunur?",
  "Külək turbinləri elektrik enerjisi istehsal edir.",
  ["Elektrik almaq üçün", "Yağış yağdırmaq üçün",
   "Torpağı qızdırmaq üçün", "Səs yaratmaq üçün"], 1, None, 2),
 ("Hərəkət etmək üçün canlılara nə lazımdır?",
  "Canlılar hərəkət üçün enerji sərf edir.",
  ["Enerji", "Kölgə", "Səs", "Rəng"], 1, None, 1),
 ("Canlılar enerjini haradan alır?",
  "Canlıların enerji mənbəyi qidadır.",
  ["Qidadan", "Daşdan", "Səsdən", "Kölgədən"], 1, None, 2),
 ("Hansı yanacaq təbii sərvətdir?",
  "Neft yerin təkindən çıxarılan təbii sərvətdir.",
  ["Neft", "Plastik", "Şüşə", "Kağız"], 1, None, 2),
 ("Su qızdırıldıqda hansı hala keçir?",
  "Qaynayan su buxarlanır — qaz halına keçir.",
  ["Buxara çevrilir", "Buza çevrilir", "Daşlaşır", "Dəyişmir"],
  1, None, 2),
 ("Maqnit hansı əşyaları özünə çəkir?",
  "Maqnit dəmirdən olan əşyaları cəzb edir.",
  ["Dəmir əşyaları", "Taxta əşyaları", "Plastik əşyaları",
   "Kağız əşyaları"], 1, None, 2),
 ("Hansı cisim işıq mənbəyi deyil?",
  "Ay öz işığını yaymır, Günəş işığını əks etdirir.",
  ["Ay", "Günəş", "Yanan şam", "Elektrik lampası"], 1, None, 3),
],
"inf-4-informasiya": [
 ("İnformasiya nədir?",
  "Ətraf aləmdən aldığımız məlumatlar informasiyadır.",
  ["Ətraf aləmdən alınan məlumat", "Yalnız kitab",
   "Yalnız rəqəmlər", "Kompüterin adı"], 1, None, 1),
 ("İnsan informasiyanın çoxunu hansı orqanla alır?",
  "İnformasiyanın böyük hissəsini görmə ilə alırıq.",
  ["Gözlə", "Qulaqla", "Burunla", "Əllə"], 1, None, 2),
 ("Zəng səsi hansı informasiya növüdür?",
  "Qulaqla qəbul edilən informasiya səs informasiyasıdır.",
  ["Səs", "Qrafik", "Mətn", "Ədədi"], 1, None, 2),
 ("Kitabdakı yazı hansı informasiya formasıdır?",
  "Hərflərlə yazılmış məlumat mətn informasiyasıdır.",
  ["Mətn", "Səs", "Video", "Qoxu"], 1, None, 1),
 ("Svetofor informasiyanı necə ötürür?",
  "Svetofor rəngli işıq siqnalları ilə məlumat verir.",
  ["İşıq siqnalları ilə", "Səslə", "Yazı ilə", "Qoxu ilə"], 1, None, 2),
 ("İnformasiyanı saxlamaq üçün nədən istifadə olunur?",
  "Kitab, disk, fləş kart informasiya daşıyıcılarıdır.",
  ["İnformasiya daşıyıcılarından", "Güzgüdən", "Şüşədən", "Sudan"],
  1, None, 2),
 ("Hansı sırada yalnız informasiya daşıyıcıları verilib?",
  "Hamısı üzərində məlumat saxlanan vasitələrdir.",
  ["kitab, disk, fləş kart", "kitab, stol, stul",
   "disk, qələm, çanta", "telefon, alma, dəftər"], 1, None, 2),
 ("Şəkil hansı informasiya formasına aiddir?",
  "Şəkil və sxemlər qrafik informasiyadır.",
  ["Qrafik", "Səs", "Mətn", "Ədədi"], 1, None, 2),
 ("İnformasiyanı uzağa ötürmək üçün hansı vasitədən istifadə olunur?",
  "Telefonla informasiya məsafəyə ötürülür.",
  ["Telefon", "Güzgü", "Qayçı", "Xətkeş"], 1, None, 2),
 ("Hansı iş informasiyanın emalıdır?",
  "Misalı həll edəndə verilən informasiyadan yeni nəticə alınır.",
  ["Misalı həll etmək", "Kitabı rəfə qoymaq",
   "Dəftəri cırmaq", "Çantanı bağlamaq"], 1, None, 3),
],
"inf-4-alqoritm": [
 ("Alqoritm nədir?",
  "Məqsədə çatmaq üçün addımların ardıcıl icra qaydasıdır.",
  ["Addımların ardıcıl icra qaydası", "Kompüter oyunu",
   "Şəkil çəkmə proqramı", "Riyazi düstur"], 1, None, 1),
 ("Alqoritmin addımları necə yerinə yetirilməlidir?",
  "Addımlar verilmiş ardıcıllıqla icra olunur.",
  ["Ardıcıllıqla", "Sondan əvvələ", "Qarışıq", "İstəyə görə atlanaraq"],
  1, None, 1),
 ("Çay dəmləmə alqoritmində birinci addım hansıdır?",
  "Əvvəlcə çaydana su tökülür — susuz qaynatmaq olmaz.",
  ["Çaydana su tökmək", "Çayı süzmək", "Stəkanı yumaq",
   "Çaya şəkər atmaq"], 1, None, 2),
 ("Alqoritmi yerinə yetirən qurğu və ya canlı necə adlanır?",
  "Alqoritmi icra edən — icraçıdır (insan, robot, kompüter).",
  ["İcraçı", "Müəllif", "Tamaşaçı", "Rəssam"], 1, None, 2),
 ("Hansı ardıcıllıq düzgün alqoritmdir?",
  "Əvvəl əllər yuyulur, sonra qurulanır.",
  ["1. Əlini yu. 2. Dəsmalla qurula.", "1. Dəsmalla qurula. 2. Əlini yu.",
   "1. Yat. 2. Əlini yu.", "1. Qurula. 2. Qurula."], 1, None, 2),
 ("Alqoritmdə addımların yeri dəyişdirilsə, nə baş verə bilər?",
  "Ardıcıllıq pozulsa, nəticə səhv alınar.",
  ["Nəticə səhv ola bilər", "Heç nə dəyişməz",
   "Alqoritm sürətlənər", "Nəticə həmişə yaxşılaşar"], 1, None, 2),
 ("«Səhər durmaq → geyinmək → ? → məktəbə getmək» — buraxılmış addım "
  "hansı ola bilər?",
  "Məktəbə getməzdən əvvəl səhər yeməyi yeyilir.",
  ["Səhər yeməyi yemək", "Axşam yatmaq", "Məktəbdən qayıtmaq",
   "Gecə filmə baxmaq"], 1, None, 3),
 ("Eyni addımların dəfələrlə yerinə yetirildiyi alqoritm necə adlanır?",
  "Təkrarlanan addımlı alqoritm dövri alqoritmdir.",
  ["Dövri (təkrarlanan)", "Xətti", "Səhv", "Yarımçıq"], 1, None, 3),
 ("Robot icraçıya göstərişlər hansı formada verilir?",
  "İcraçı yalnız ona tanış əmrləri başa düşür.",
  ["Əmrlərlə", "Baxışla", "Mahnı ilə", "Şəkillə"], 1, None, 2),
 ("Alqoritm nə ilə bitməlidir?",
  "Düzgün alqoritm nəticə ilə tamamlanır.",
  ["Nəticə ilə", "Sualla", "Fasilə ilə", "Bitməməlidir"], 1, None, 2),
],
"inf-4-kompyuter": [
 ("Kompüterin «beyni» adlanan qurğu hansıdır?",
  "Prosessor bütün hesablamaları yerinə yetirir.",
  ["Prosessor", "Monitor", "Klaviatura", "Printer"], 1, None, 2),
 ("Mətn yığmaq üçün hansı qurğudan istifadə olunur?",
  "Hərflər klaviatura ilə yığılır.",
  ["Klaviatura", "Monitor", "Dinamik", "Printer"], 1, None, 1),
 ("Monitor nə üçündür?",
  "Monitor informasiyanı ekranda göstərir.",
  ["İnformasiyanı ekranda göstərmək", "Mətni çap etmək",
   "Səs yazmaq", "İnternetə qoşulmaq"], 1, None, 1),
 ("Siçanın (mausun) əsas vəzifəsi nədir?",
  "Maus ekrandakı obyektləri seçib idarə etməyə xidmət edir.",
  ["Ekrandakı obyektləri seçmək və idarə etmək", "Mətni çap etmək",
   "Səsi ucaltmaq", "Şəkil çəkmək üçün rəng qarışdırmaq"], 1, None, 2),
 ("Sənədi kağıza çap etmək üçün hansı qurğu lazımdır?",
  "Printer məlumatı kağıza çap edir.",
  ["Printer", "Skaner", "Dinamik", "Mikrofon"], 1, None, 1),
 ("İnformasiya kompüterdə harada saxlanılır?",
  "Məlumatlar kompüterin yaddaşında saxlanılır.",
  ["Yaddaşda", "Monitorda", "Klaviaturada", "Mausda"], 1, None, 2),
 ("Səsi eşitdirmək üçün hansı qurğudan istifadə olunur?",
  "Dinamik (səsucaldan) səsi çıxarır.",
  ["Dinamik", "Mikrofon", "Skaner", "Printer"], 1, None, 2),
 ("Kompüterdə şəkil çəkmək üçün hansı proqramdan istifadə olunur?",
  "Qrafik redaktorda (məsələn, Paint) şəkil çəkilir.",
  ["Qrafik redaktor (Paint)", "Kalkulyator", "Saat", "Musiqi pleyeri"],
  1, None, 2),
 ("Kompüterlə iş qurtaranda nə etmək lazımdır?",
  "Kompüter qaydasında söndürülməlidir.",
  ["Onu düzgün söndürmək", "Elektrik şnurunu dartmaq",
   "Ekranı örtüb getmək", "Su ilə silmək"], 1, None, 2),
 ("Kompüter arxasında uzun müddət oturmaq nəyə zərər verir?",
  "Fasiləsiz iş gözləri yorur, qaməti pozur.",
  ["Gözlərə və qamətə", "Heç nəyə", "Yalnız ayaqqabıya",
   "Yalnız kompüterə"], 1, None, 2),
],
}


def yoxla():
    n = xeta = 0
    butun = set()
    movzu_fenn = {m: f for f, m, _r in MOVZULAR}
    for movzu, siyahi in SUALLAR.items():
        assert movzu in movzu_fenn, movzu
        for body, why, opts, correct, expect, diff in siyahi:
            n += 1
            p = []
            if len(opts) != 4: p.append("variant sayi %d" % len(opts))
            if len(set(opts)) != len(opts): p.append("tekrar variant")
            if not (1 <= correct <= 4): p.append("correct")
            if not why: p.append("izah bos")
            if diff not in (1, 2, 3): p.append("cetinlik")
            if body in butun: p.append("eyni sual iki defe")
            butun.add(body)
            if expect is not None and opts[correct - 1] != expect:
                p.append("hesablanan «%s» != variant «%s»"
                         % (expect, opts[correct - 1]))
            for t in [body, why] + opts:
                if "'" in t: p.append("apostrof var")
            if p:
                xeta += 1
                print("XETA  %s: %s\n      %s" % (movzu, body[:60], "; ".join(p)))
    hes = sum(1 for s in SUALLAR.values() for q in s if q[4] is not None)
    print("%d sual yoxlandı (%d-i hesabla təsdiqləndi), %d xəta" % (n, hes, xeta))
    return xeta == 0, n


def sql_yaz(n):
    q = lambda t: t.replace("'", "''")
    on = {"az-dili": "az4", "hayat-bilgisi": "hey4", "informatika": "inf4"}
    setirler = []
    for fenn, movzu, rub in MOVZULAR:
        qisa = movzu.split("-", 2)[2]          # az-4-isim-hallari -> isim-hallari
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('%s-%s#%d','%s','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (on[fenn], qisa, i, fenn, movzu, diff, rub, q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  17_bank_sinif4.sql : 4-CU SINIF - AZ DILI, HEYAT BILGISI, INFORMATIKA
--
--  BU FAYL ELLE YAZILMIR - tools/sinif4.py yaradir:
--      python3 tools/sinif4.py
--
--  Az dili 8 movzu + Heyat bilgisi 5 + Informatika 3 = 16 movzu x 10
--  sual = %d.  Suallar orijinaldir.  ext_key: az4-/hey4-/inf4-...
--
--  ON SERT: 14_movzular.sql ve 15_movzular_ederslik.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('az-dili','az-4-isim-hallari'),
                                ('hayat-bilgisi','hey-4-canli-heyat'),
                                ('informatika','inf-4-informasiya'))
     having count(*) = 3) then
    raise exception 'ONCE 14_movzular.sql ve 15_movzular_ederslik.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'az4-%%' or q.ext_key like 'hey4-%%'
        or q.ext_key like 'inf4-%%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
%s
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
    join public.levels   l on l.program_id = p.id and l.code = '4'
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
     and (ext_key like 'az4-%%' or ext_key like 'hey4-%%'
          or ext_key like 'inf4-%%');
  if n <> %d then
    raise exception 'sinif4 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;

  select count(*) into k from public.questions q
   where (q.ext_key like 'az4-%%' or q.ext_key like 'hey4-%%'
          or q.ext_key like 'inf4-%%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;

  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az4-%%' or ext_key like 'hey4-%%'
      or ext_key like 'inf4-%%';
  if k <> 16 then
    raise exception 'movzu sayi 16 deyil: %%', k;
  end if;

  raise notice '4-cu sinif banki: %% sual, 16 movzu (az dili, heyat bilgisi, informatika).', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
