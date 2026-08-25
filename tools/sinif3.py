#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
3-cu sinfin qalan fennleri -> db/20_bank_sinif3.sql

    Azerbaycan dili 3   8 movzu x 10 = 80
    Heyat bilgisi 3     6 movzu x 10 = 60
    Informatika 3       4 movzu x 10 = 40
                                cemi  180

tools/sinif4.py qelibi ile.  Heca/sait suallari proqramla sayilir.
DIQQET: 07_seed_tests.sql-in az-3 suallari ile eyni cumle QELIBI
isledilmeyib (movcud: "«Kitab» sozunde nece sait var?", "Hansi soz
duzgun yazilib?", "Cumlenin sonunda hansi isare qoyulur?") - generator
>= 0.95 oxsarligi tekrar sayir.

Isletmek:
    python3 tools/sinif3.py
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "20_bank_sinif3.sql")

SAITLER = set("aeəiıoöuü")


def sait(soz):
    return sum(1 for h in soz.lower() if h in SAITLER)


def samit(soz):
    return sum(1 for h in soz.lower() if h.isalpha() and h not in SAITLER)


MOVZULAR = [
    ("az-dili", "az-3-sait-samit",   1),
    ("az-dili", "az-3-isim",         1),
    ("az-dili", "az-3-sifet",        2),
    ("az-dili", "az-3-fel",          2),
    ("az-dili", "az-3-soz-novleri",  3),
    ("az-dili", "az-3-cumle",        3),
    ("az-dili", "az-3-yazi-qaydasi", 4),
    ("az-dili", "az-3-metn",         4),
    ("hayat-bilgisi", "hey-3-cemiyyet",      1),
    ("hayat-bilgisi", "hey-3-saglamliq",     1),
    ("hayat-bilgisi", "hey-3-yer-ay",        2),
    ("hayat-bilgisi", "hey-3-materiallar",   3),
    ("hayat-bilgisi", "hey-3-bayramlar",     3),
    ("hayat-bilgisi", "hey-3-tehlukesizlik", 4),
    ("informatika", "inf-3-informasiya", 1),
    ("informatika", "inf-3-alqoritm",    2),
    ("informatika", "inf-3-kompyuter",   3),
    ("informatika", "inf-3-metn",        4),
]

SUALLAR = {
"az-3-sait-samit": [
 ("Azərbaycan dilində neçə sait səs var?",
  "Dilimizdə 9 sait var: a, e, ə, i, ı, o, ö, u, ü.",
  ["9", "6", "23", "32"], 1, None, 1),
 ("Hansı sırada yalnız saitlər verilib?",
  "a, ı, u — hamısı saitdir.",
  ["a, ı, u", "a, b, c", "m, n, o", "k, i, t"], 1, None, 1),
 ("«Dəniz» sözündə neçə sait var?",
  "Saitlər: ə, i — iki sait.",
  ["2", "3", "1", "5"], 1, str(sait("Dəniz")), 2),
 ("Qalın saitlər hansı sırada verilib?",
  "Qalın saitlər: a, ı, o, u.",
  ["a, ı, o, u", "ə, e, i, ö", "a, ə, i, o", "e, i, u, ü"], 1, None, 2),
 ("İncə saitlər hansı sırada verilib?",
  "İncə saitlər: ə, e, i, ö, ü.",
  ["ə, e, i, ö, ü", "a, ı, o, u", "a, e, i, o, u", "b, c, d, f, g"],
  1, None, 2),
 ("«Məktəb» sözündə neçə samit var?",
  "Samitlər: m, k, t, b — dörd samit.",
  ["4", "2", "6", "3"], 1, str(samit("Məktəb")), 2),
 ("Hansı samit kar samitdir?",
  "«p» kar samitdir, cingiltili qarşılığı «b»-dir.",
  ["p", "b", "d", "g"], 1, None, 3),
 ("Hansı samit cingiltilidir?",
  "«b» cingiltili samitdir, kar qarşılığı «p»-dir.",
  ["b", "p", "t", "k"], 1, None, 3),
 ("«Ana» sözü neçə səsdən ibarətdir?",
  "A-n-a: üç səs.",
  ["3", "2", "4", "5"], 1, str(len("ana")), 1),
 ("Saitlər necə tələffüz olunur?",
  "Saitlər səs yolunda maneəyə rast gəlmədən tələffüz olunur.",
  ["Maneəsiz", "Maneə ilə", "Yalnız pıçıltı ilə", "Tələffüz olunmur"],
  1, None, 2),
],
"az-3-isim": [
 ("İsim nəyi bildirir?",
  "İsim əşyanın adını bildirir.",
  ["Əşyanın adını", "Əlaməti", "Hərəkəti", "Miqdarı"], 1, None, 1),
 ("Hansı söz isimdir?",
  "«Dağ» — əşyanın adıdır, «nə?» sualına cavab verir.",
  ["dağ", "qaçmaq", "uca", "beş"], 1, None, 1),
 ("İsimlər hansı suallara cavab verir?",
  "İsimlər «kim? nə?» suallarına cavab verir.",
  ["Kim? Nə?", "Necə?", "Nə edir?", "Neçə?"], 1, None, 1),
 ("Hansı söz xüsusi isimdir?",
  "«Kür» — çayın xüsusi adıdır, böyük hərflə yazılır.",
  ["Kür", "çay", "şəhər", "uşaq"], 1, None, 2),
 ("Xüsusi isimlər necə yazılır?",
  "İnsan, şəhər, çay adları böyük hərflə yazılır.",
  ["Böyük hərflə", "Kiçik hərflə", "Dırnaqda", "Rəqəmlə"], 1, None, 1),
 ("«Quşlar» sözü təkdədir, yoxsa cəmdə?",
  "-lar şəkilçisi cəm bildirir.",
  ["Cəmdə", "Təkdə", "Heç biri", "Hər ikisi"], 1, None, 2),
 ("İsmin cəm şəkilçiləri hansılardır?",
  "Cəm şəkilçiləri -lar, -lər-dir.",
  ["-lar, -lər", "-da, -də", "-a, -ə", "-ın, -in"], 1, None, 2),
 ("Hansı sırada yalnız isimlər verilib?",
  "Kitab, meşə, günəş — hamısı əşya adıdır.",
  ["kitab, meşə, günəş", "kitab, oxumaq, gözəl",
   "meşə, yaşıl, getmək", "günəş, isti, beş"], 1, None, 2),
 ("«Bakı, Aysu, Araz» sözlərinin ümumi cəhəti nədir?",
  "Hamısı xüsusi isimdir — ad bildirir və böyük hərflə yazılır.",
  ["Hamısı xüsusi isimdir", "Hamısı feldir",
   "Hamısı sifətdir", "Hamısı cəmdədir"], 1, None, 2),
 ("«Uşaqlar bağçada oynayırlar» cümləsində «bağçada» sözü hansı "
  "nitq hissəsidir?",
  "«Bağça» əşya adıdır — isimdir.",
  ["İsim", "Fel", "Sifət", "Say"], 1, None, 3),
],
"az-3-sifet": [
 ("Sifət nəyi bildirir?",
  "Sifət əşyanın əlamətini bildirir.",
  ["Əşyanın əlamətini", "Əşyanın adını", "Hərəkəti", "Miqdarı"],
  1, None, 1),
 ("Hansı söz sifətdir?",
  "«Şirin» — əlamət bildirir: necə?",
  ["şirin", "alma", "yemək", "iki"], 1, None, 1),
 ("Sifətlər hansı suallara cavab verir?",
  "Sifətlər «necə? nə cür? hansı?» suallarına cavab verir.",
  ["Necə? Nə cür?", "Kim? Nə?", "Nə edir?", "Nə vaxt?"], 1, None, 1),
 ("«Hündür bina» birləşməsində sifət hansıdır?",
  "Bina necədir? — hündür.",
  ["hündür", "bina", "hər ikisi", "heç biri"], 1, None, 2),
 ("Hansı sırada yalnız sifətlər verilib?",
  "Gözəl, dar, isti — hamısı əlamət bildirir.",
  ["gözəl, dar, isti", "gözəl, ev, dar", "isti, yay, gün",
   "dar, küçə, uzun"], 1, None, 2),
 ("Sifət cümlədə adətən hansı sözdən əvvəl gəlir?",
  "Sifət ismin əlamətini bildirdiyi üçün isimdən əvvəl gəlir.",
  ["İsimdən", "Feldən", "Saydan", "Cümlənin sonundakı sözdən"],
  1, None, 2),
 ("«Soyuq» sözünün əks mənalısı hansıdır?",
  "Soyuq ↔ isti.",
  ["isti", "sərin", "buzlu", "yaş"], 1, None, 2),
 ("«Balaca pişik süd içir» cümləsində sifət hansıdır?",
  "Pişik necədir? — balaca.",
  ["balaca", "pişik", "süd", "içir"], 1, None, 2),
 ("Əşyanın rəngini bildirən söz hansı nitq hissəsidir?",
  "Rəng əlamətdir — sifətlə bildirilir.",
  ["Sifət", "İsim", "Fel", "Say"], 1, None, 2),
 ("Hansı söz sifət DEYİL?",
  "«Yazmaq» hərəkət bildirir — feldir.",
  ["yazmaq", "təmiz", "qısa", "dadlı"], 1, None, 3),
],
"az-3-fel": [
 ("Fel nəyi bildirir?",
  "Fel hərəkəti bildirir.",
  ["Hərəkəti", "Əşyanın adını", "Əlaməti", "Miqdarı"], 1, None, 1),
 ("Hansı söz feldir?",
  "«Oxumaq» hərəkət bildirir: nə etmək?",
  ["oxumaq", "kitab", "maraqlı", "səhifə"], 1, None, 1),
 ("Fellər hansı suallara cavab verir?",
  "Fellər «nə edir? nə etdi? nə edəcək?» suallarına cavab verir.",
  ["Nə edir?", "Kim? Nə?", "Necə?", "Hansı?"], 1, None, 1),
 ("«Quş yuvasına uçur» cümləsində fel hansıdır?",
  "Quş nə edir? — uçur.",
  ["uçur", "quş", "yuvasına", "cümlədə fel yoxdur"], 1, None, 2),
 ("Hansı sırada yalnız fellər verilib?",
  "Gəlmək, getmək, baxmaq — hamısı hərəkət bildirir.",
  ["gəlmək, getmək, baxmaq", "gəlmək, yol, uzaq",
   "baxmaq, göz, iri", "getmək, ayaq, tez"], 1, None, 2),
 ("«Getmək» felinin inkarı hansıdır?",
  "Felin inkarı -ma, -mə şəkilçisi ilə düzəlir: getməmək.",
  ["getməmək", "gəlmək", "getdi", "gedəcək"], 1, None, 3),
 ("Cümləni tamamlayın: «Şagirdlər şeiri əzbər …»",
  "Cümləni fel tamamlayır: deyirlər.",
  ["deyirlər", "kitab", "maraqlı", "məktəb"], 1, None, 2),
 ("Hansı söz fel DEYİL?",
  "«Qaçış» hərəkətin adıdır — isimdir; qalanları feldir.",
  ["qaçış", "qaçmaq", "tullanmaq", "üzmək"], 1, None, 3),
 ("«Danışmaq, gülmək, oxumaq» sözlərinin ümumi cəhəti nədir?",
  "Hər üçü hərəkət bildirir — feldir.",
  ["Hamısı feldir", "Hamısı isimdir", "Hamısı sifətdir",
   "Heç bir ümumi cəhəti yoxdur"], 1, None, 1),
 ("«Külək bərk əsir» cümləsindəki feli göstərin.",
  "Külək nə edir? — əsir.",
  ["əsir", "külək", "bərk", "cümlədə fel yoxdur"], 1, None, 2),
],
"az-3-soz-novleri": [
 ("Əşyanın adını bildirən sözlər necə adlanır?",
  "Ad bildirən sözlər isimdir.",
  ["İsim", "Sifət", "Fel", "Say"], 1, None, 1),
 ("«Sarı» sözü hansı söz növüdür?",
  "Rəng əlamətdir — sifətdir.",
  ["Sifət", "İsim", "Fel", "Say"], 1, None, 2),
 ("«Uçmaq» sözü hansı nitq hissəsinə aiddir?",
  "Hərəkət bildirir — feldir.",
  ["Fel", "İsim", "Sifət", "Say"], 1, None, 2),
 ("Hansı cərgədə «isim, sifət, fel» ardıcıllığı düzgündür?",
  "Ev — isim, geniş — sifət, tikmək — fel.",
  ["ev, geniş, tikmək", "geniş, ev, tikmək",
   "tikmək, geniş, ev", "ev, tikmək, geniş"], 1, None, 3),
 ("Əlamət bildirən sözü seçin.",
  "«Ağıllı» — necə? sualına cavab verir.",
  ["ağıllı", "uşaq", "oxuyur", "on"], 1, None, 1),
 ("Hərəkət bildirən sözü seçin.",
  "«Üzmək» — nə etmək? sualına cavab verir.",
  ["üzmək", "üzgüçü", "sürətli", "hovuz"], 1, None, 1),
 ("«Beş» sözü nəyi bildirir?",
  "«Beş» miqdar bildirir — saydır.",
  ["Miqdarı", "Əlaməti", "Hərəkəti", "Əşyanın adını"], 1, None, 3),
 ("«Qırmızı alma budaqdan düşdü» cümləsində hansı söz isimdir?",
  "«Alma» əşya adıdır (budaq da isimdir).",
  ["alma", "qırmızı", "düşdü", "cümlədə isim yoxdur"], 1, None, 2),
 ("«Kitabxana» sözü hansı söz növüdür?",
  "Yer adıdır — isimdir.",
  ["İsim", "Sifət", "Fel", "Say"], 1, None, 2),
 ("Hansı cüt «sifət + isim» qəlibinə uyğundur?",
  "Uzun (necə?) + yol (nə?).",
  ["uzun yol", "yol getmək", "tez qaçmaq", "beş kitab"], 1, None, 3),
],
"az-3-cumle": [
 ("Cümlə nədir?",
  "Cümlə bitmiş fikir bildirir.",
  ["Bitmiş fikir bildirən söz və ya söz birləşməsi",
   "Hərflərin yığını", "Təkcə bir söz", "Şəkilçilər toplusu"],
  1, None, 1),
 ("Cümlənin baş üzvləri hansılardır?",
  "Baş üzvlər mübtəda və xəbərdir.",
  ["Mübtəda və xəbər", "İsim və sifət", "Söz və heca",
   "Sual və cavab"], 1, None, 2),
 ("«Yarpaqlar töküldü» cümləsində mübtəda hansıdır?",
  "Tökülən nədir? — Yarpaqlar.",
  ["Yarpaqlar", "töküldü", "hər ikisi", "heç biri"], 1, None, 2),
 ("«Uşaq şirin-şirin gülür» cümləsində xəbər hansıdır?",
  "Uşaq nə edir? — gülür.",
  ["gülür", "Uşaq", "şirin-şirin", "cümlədə xəbər yoxdur"],
  1, None, 2),
 ("Cümlənin birinci sözü necə yazılır?",
  "Cümlə böyük hərflə başlanır.",
  ["Böyük hərflə", "Kiçik hərflə", "İxtisarla", "Rəqəmlə"], 1, None, 1),
 ("Azərbaycan dilində xəbər adətən cümlənin harasında olur?",
  "Xəbər adətən cümlənin sonunda gəlir.",
  ["Sonunda", "Əvvəlində", "Ortasında", "Qaydası yoxdur"], 1, None, 2),
 ("Hansı yazılış cümlədir?",
  "«Qar yağdı.» — bitmiş fikirdir.",
  ["Qar yağdı.", "sürətli qaçmaq", "gözəl hava", "mavi səma"],
  1, None, 2),
 ("«Anam bazardan təzə meyvə aldı» cümləsində mübtəda hansıdır?",
  "Alan kimdir? — Anam.",
  ["Anam", "bazardan", "meyvə", "aldı"], 1, None, 3),
 ("Cümlənin neçə baş üzvü var?",
  "İki baş üzv: mübtəda və xəbər.",
  ["2", "1", "3", "5"], 1, None, 2),
 ("«Oxuyur» sözü cümlədə adətən hansı üzv olur?",
  "Fel cümlədə əsasən xəbər olur.",
  ["Xəbər", "Mübtəda", "Üzv olmur", "Başlıq"], 1, None, 3),
],
"az-3-yazi-qaydasi": [
 ("Düzgün yazılışı seçin.",
  "Düzgün yazılış: məktəb.",
  ["məktəb", "məktəp", "mektəb", "məktap"], 1, None, 2),
 ("Xüsusi isimlər hansı hərflə başlanır?",
  "Şəxs, şəhər, çay adları böyük hərflə yazılır.",
  ["Böyük hərflə", "Kiçik hərflə", "İstənilən hərflə", "Saitlə"],
  1, None, 1),
 ("Söz sətirdən sətrə necə keçirilir?",
  "Söz yalnız hecalarla keçirilir.",
  ["Hecalarla", "Hərf-hərf", "İstənilən yerdən", "Keçirmək olmaz"],
  1, None, 2),
 ("Ay adları (yanvar, mart…) necə yazılır?",
  "Ay adları kiçik hərflə yazılır.",
  ["Kiçik hərflə", "Böyük hərflə", "Dırnaqda", "Rəqəmlə"], 1, None, 3),
 ("Nəqli cümlə hansı işarə ilə bitir?",
  "Adi məlumat bildirən cümlənin sonunda nöqtə qoyulur.",
  ["Nöqtə ilə", "Sual işarəsi ilə", "Vergüllə", "Tire ilə"], 1, None, 1),
 ("«Kitab» sözü hecalara necə bölünür?",
  "Ki-tab: iki heca.",
  ["ki-tab", "kit-ab", "k-itab", "kita-b"], 1, None, 2),
 ("«Dovşan» sözündə neçə heca var?",
  "Saitlər: o, a — iki sait, deməli iki heca.",
  ["2", "3", "1", "4"], 1, str(sait("Dovşan")), 2),
 ("Hansı sözü sətirdən sətrə keçirmək olmaz?",
  "Birhecalı sözlər keçirilmir.",
  ["el", "ana", "kitab", "dəftər"], 1, None, 3),
 ("«günəş» sözü nə vaxt böyük hərflə yazılır?",
  "Şəxs adı olanda: Günəş adlı qız.",
  ["Şəxs adı olanda", "Cəmdə olanda", "Heç vaxt", "Həmişə"],
  1, None, 3),
 ("«Ananas» sözündə neçə heca var?",
  "Saitlər: a, a, a — üç heca: a-na-nas.",
  ["3", "2", "4", "6"], 1, str(sait("Ananas")), 2),
],
"az-3-metn": [
 ("Mətni adi cümlələr yığınından fərqləndirən nədir?",
  "Mətndə cümlələr məzmunca bir-biri ilə bağlıdır.",
  ["Cümlələrin məzmunca bağlılığı", "Cümlələrin sayı",
   "Sözlərin uzunluğu", "Şəkilli olması"], 1, None, 2),
 ("Mətnin başlığı nəyə uyğun seçilir?",
  "Başlıq mətnin məzmununa uyğun olmalıdır.",
  ["Məzmuna", "İlk hərfə", "Cümlə sayına", "Müəllifin adına"],
  1, None, 2),
 ("Nitq neçə cür olur?",
  "Nitq şifahi və yazılı olur.",
  ["Şifahi və yazılı", "Yalnız şifahi", "Yalnız yazılı",
   "Sürətli və yavaş"], 1, None, 2),
 ("Hansı, şifahi nitqə aiddir?",
  "Danışıq şifahi nitqdir.",
  ["Nağıl danışmaq", "Məktub yazmaq", "İnşa yazmaq",
   "Dəftərə köçürmək"], 1, None, 1),
 ("Hansı, yazılı nitqə aiddir?",
  "Məktub yazmaq yazılı nitqdir.",
  ["Məktub yazmaq", "Telefonla danışmaq", "Mahnı oxumaq",
   "Sual vermək"], 1, None, 2),
 ("Mətndə cümlələr necə düzülməlidir?",
  "Cümlələr məntiqi ardıcıllıqla düzülür.",
  ["Ardıcıl, məntiqi", "Qarışıq", "Uzunluğa görə",
   "Əlifba sırası ilə"], 1, None, 2),
 ("Həmsöhbəti dinləyərkən nə etmək düzgündür?",
  "Sözünü kəsməmək hörmətin əlamətidir.",
  ["Sözünü kəsməmək", "Ucadan danışmaq", "Üzünə baxmamaq",
   "Telefonla oynamaq"], 1, None, 1),
 ("Mətn adətən neçə hissədən ibarət olur?",
  "Giriş, əsas hissə, nəticə — üç hissə.",
  ["3", "1", "5", "10"], 1, None, 2),
 ("Telefonla danışığa nədən başlamaq lazımdır?",
  "Əvvəlcə salamlaşırlar.",
  ["Salamlaşmaqdan", "Şikayətdən", "Sağollaşmaqdan", "Sualdan"],
  1, None, 1),
 ("Nağıl danışmaq hansı nitq növüdür?",
  "Danışıq — şifahi nitqdir.",
  ["Şifahi", "Yazılı", "Heç biri", "Hər ikisi"], 1, None, 2),
],
"hey-3-cemiyyet": [
 ("Cəmiyyətdə insanlar bir-biri ilə necə davranmalıdır?",
  "Qarşılıqlı hörmət cəmiyyətin təməlidir.",
  ["Hörmətlə", "Biganə", "Kobud", "Yalnız tanışlarla nəzakətli"],
  1, None, 1),
 ("Məktəb qaydalarına kim əməl etməlidir?",
  "Qaydalar hamı üçündür.",
  ["Bütün şagirdlər", "Yalnız növbətçilər", "Yalnız birincilər",
   "Heç kim"], 1, None, 1),
 ("Növbəyə riayət etmək nəyin əlamətidir?",
  "Növbə gözləmək mədəni davranışdır.",
  ["Mədəniyyətin", "Zəifliyin", "Tələsməyin", "Qorxaqlığın"],
  1, None, 2),
 ("Kollektiv nədir?",
  "Bir məqsəd üçün birgə çalışan insanlar kollektivdir.",
  ["Birgə fəaliyyət göstərən insanlar", "Bir nəfər",
   "Binaların cəmi", "Yalnız qonşular"], 1, None, 2),
 ("Hansı davranış SƏHVDİR?",
  "İctimai yerdə ucadan qışqırmaq başqalarını narahat edir.",
  ["Avtobusda ucadan qışqırmaq", "Salam vermək",
   "Növbə gözləmək", "Zibili qutuya atmaq"], 1, None, 1),
 ("Nəqliyyatda kimə yer vermək lazımdır?",
  "Yaşlılara, uşaqlı sərnişinlərə yer verilir.",
  ["Yaşlılara və körpəli sərnişinlərə", "Heç kimə",
   "Yalnız dostlara", "Sürücüyə"], 1, None, 2),
 ("Dostluq nəyə əsaslanır?",
  "Əsl dostluq etibar və sədaqət üzərində qurulur.",
  ["Etibara və sədaqətə", "Hədiyyələrə", "Qorxuya", "Paxıllığa"],
  1, None, 2),
 ("Ailə üzvlərinə kömək etmək kimin borcudur?",
  "Ev işlərində hamı iştirak etməlidir.",
  ["Hər bir ailə üzvünün", "Yalnız ananın", "Yalnız uşaqların",
   "Qonaqların"], 1, None, 1),
 ("Hansı, milli adət-ənənələrimizə aiddir?",
  "Novruzda tonqal qalamaq qədim adətimizdir.",
  ["Novruzda tonqal qalamaq", "Qonağı qarşılamamaq",
   "Böyüyə salam verməmək", "Süfrəni yığışdırmamaq"], 1, None, 2),
 ("Kiçiklərə münasibət necə olmalıdır?",
  "Kiçiklərə qayğı göstərmək böyüklüyün əlamətidir.",
  ["Qayğı ilə", "Biganə", "Kobud", "Əmrlə"], 1, None, 2),
],
"hey-3-saglamliq": [
 ("Gündəlik rejimə nə daxildir?",
  "Yuxu, qidalanma, dərs və istirahət vaxtlarının bölgüsü.",
  ["Yuxu, qida və məşğuliyyət vaxtları", "Yalnız oyun",
   "Yalnız yemək", "Yalnız dərs"], 1, None, 2),
 ("Səhər idmanı orqanizmə nə verir?",
  "Səhər hərəkəti bədəni gümrahlaşdırır.",
  ["Gümrahlıq", "Yorğunluq", "Yuxusuzluq", "Heç nə"], 1, None, 1),
 ("Dişləri gündə neçə dəfə fırçalamaq lazımdır?",
  "Səhər və axşam — 2 dəfə.",
  ["2 dəfə", "Həftədə 1 dəfə", "Ayda 2 dəfə", "Heç fırçalamamaq"],
  1, None, 1),
 ("Vitaminlər ən çox hansı qidalarda olur?",
  "Meyvə və tərəvəz vitamin mənbəyidir.",
  ["Meyvə və tərəvəzdə", "Şirniyyatda", "Çipslərdə",
   "Qazlı içkilərdə"], 1, None, 2),
 ("Gözləri qorumaq üçün nə etmək lazımdır?",
  "Ekrana yaxından və uzun müddət baxmaq gözləri yorur.",
  ["Ekrana yaxından uzun baxmamaq", "Qaranlıqda kitab oxumaq",
   "Günəşə birbaşa baxmaq", "Heç nə etməmək"], 1, None, 2),
 ("Yeməkdən əvvəl mütləq nə edilməlidir?",
  "Əllər sabunla yuyulmalıdır.",
  ["Əllər yuyulmalıdır", "Qaçmaq lazımdır", "Yatmaq lazımdır",
   "Su içmək olmaz"], 1, None, 1),
 ("Soyuqdəymədən qorunmaq üçün nə vacibdir?",
  "Havaya uyğun geyinmək lazımdır.",
  ["Havaya uyğun geyinmək", "Nazik geyinmək", "Buzlu su içmək",
   "Papaqsız gəzmək"], 1, None, 2),
 ("Uzun müddət fasiləsiz telefonda oynamaq nəyə zərərdir?",
  "Gözlərə və qamətə zərər verir.",
  ["Gözlərə və qamətə", "Heç nəyə", "Yalnız telefona",
   "Yalnız ayaqlara"], 1, None, 2),
 ("Təmiz havada gəzinti insana nə verir?",
  "Təmiz hava sağlamlığı möhkəmləndirir.",
  ["Sağlamlıq və gümrahlıq", "Xəstəlik", "Yorğunluq", "Qorxu"],
  1, None, 1),
 ("Mütəmadi idman nəyi möhkəmləndirir?",
  "İdman əzələləri və iradəni gücləndirir.",
  ["Əzələləri və iradəni", "Yalnız səsi", "Yalnız yaddaşı",
   "Heç nəyi"], 1, None, 2),
],
"hey-3-yer-ay": [
 ("Yer hansı formadadır?",
  "Yer kürə formasındadır.",
  ["Kürə", "Kvadrat", "Düz lövhə", "Üçbucaq"], 1, None, 1),
 ("Bizə işıq və istilik verən göy cismi hansıdır?",
  "Günəş işıq və istilik mənbəyidir.",
  ["Günəş", "Ay", "Ulduzlar", "Buludlar"], 1, None, 1),
 ("Ay nəyin peykidir?",
  "Ay Yerin təbii peykidir.",
  ["Yerin", "Günəşin", "Marsın", "Ulduzların"], 1, None, 2),
 ("Gecə və gündüz nəyə görə əmələ gəlir?",
  "Yer öz oxu ətrafında fırlanır.",
  ["Yerin öz oxu ətrafında fırlanmasına görə",
   "Günəşin sönməsinə görə", "Ayın böyüməsinə görə",
   "Buludların hərəkətinə görə"], 1, None, 3),
 ("Fəsillərin dəyişməsi nə ilə bağlıdır?",
  "Yer Günəş ətrafında dövr edir.",
  ["Yerin Günəş ətrafında hərəkəti ilə", "Küləklə",
   "Ayın işığı ilə", "Yağışla"], 1, None, 3),
 ("Yer Günəş ətrafında bir tam dövrü nə qədərə başa vurur?",
  "Bir dövrə bir ilə başa gəlir.",
  ["1 ilə", "1 günə", "1 aya", "1 saata"], 1, None, 2),
 ("Ay öz işığını yayırmı?",
  "Ay Günəşin işığını əks etdirir.",
  ["Xeyr, Günəş işığını əks etdirir", "Bəli, özü yanır",
   "Yalnız qışda yayır", "Yalnız gündüz yayır"], 1, None, 2),
 ("Qlobus nədir?",
  "Qlobus Yerin kiçildilmiş modelidir.",
  ["Yerin kiçildilmiş modeli", "Ayın xəritəsi", "Oyuncaq top",
   "Günəş saatı"], 1, None, 2),
 ("Yerin təbii peyki hansıdır?",
  "Yerin bir təbii peyki var — Ay.",
  ["Ay", "Günəş", "Mars", "Ulduz"], 1, None, 1),
 ("Gündüz göydə ən parlaq görünən göy cismi hansıdır?",
  "Gündüz Günəş görünür.",
  ["Günəş", "Ay", "Ulduzlar", "Planetlər"], 1, None, 1),
],
"hey-3-materiallar": [
 ("Şüşənin xassələri hansılardır?",
  "Şüşə şəffafdır, amma tez sınır.",
  ["Şəffafdır və kövrəkdir", "Yumşaqdır və əyilir",
   "Suda əriyir", "Yanmır və əyilir"], 1, None, 2),
 ("Hansı material suda batmır?",
  "Taxta sudan yüngüldür — üzür.",
  ["Taxta", "Dəmir", "Daş", "Şüşə"], 1, None, 2),
 ("Maqnitə hansı əşya yapışar?",
  "Maqnit dəmir əşyaları cəzb edir.",
  ["Dəmir mismar", "Taxta qələm", "Plastik qaşıq",
   "Kağız vərəq"], 1, None, 2),
 ("Kağız nədən hazırlanır?",
  "Kağız oduncaqdan istehsal olunur.",
  ["Oduncaqdan", "Daşdan", "Şüşədən", "Dəmirdən"], 1, None, 2),
 ("Hansı material elastikdir — dartılıb əvvəlki halına qayıdır?",
  "Rezin elastikdir.",
  ["Rezin", "Şüşə", "Daş", "Çini"], 1, None, 1),
 ("Metallar istiliyi necə keçirir?",
  "Metallar istiliyi yaxşı keçirir — qaynar qaba toxunmaq olmaz.",
  ["Yaxşı keçirir", "Heç keçirmir", "Yalnız qışda keçirir",
   "Yalnız suda keçirir"], 1, None, 3),
 ("Hansı əşya kövrəkdir — düşəndə sınar?",
  "Çini boşqab kövrəkdir.",
  ["Çini boşqab", "Rezin top", "Parça dəsmal", "Plastik vedrə"],
  1, None, 2),
 ("Plastik tullantılar təbiətə niyə zərərlidir?",
  "Plastik uzun illər çürümür, təbiəti çirkləndirir.",
  ["Uzun illər çürümür", "Tez əriyir", "Gübrəyə çevrilir",
   "Suda həll olur"], 1, None, 3),
 ("Suyu hansı qabda qaynatmaq təhlükəsizdir?",
  "Metal qab oda davamlıdır.",
  ["Metal qabda", "Plastik qabda", "Kağız qabda", "Şüşə olmayan karton qabda"],
  1, None, 2),
 ("Parçanın xassəsi hansıdır?",
  "Parça yumşaqdır, əyilir, tikilə bilir.",
  ["Yumşaqdır və əyilir", "Bərkdir və sınır", "Şəffafdır",
   "Suda batmır və əriyir"], 1, None, 1),
],
"hey-3-bayramlar": [
 ("Novruz bayramı hansı fəsildə qeyd olunur?",
  "Novruz yazın gəlişi bayramıdır.",
  ["Yazda", "Qışda", "Payızda", "Yayda"], 1, None, 1),
 ("Hansı, Novruzun rəmzlərindəndir?",
  "Səməni Novruzun əsas rəmzidir.",
  ["Səməni", "Yolka", "Balqabaq", "Şam ağacı"], 1, None, 1),
 ("31 Dekabr hansı gündür?",
  "31 Dekabr — Dünya Azərbaycanlılarının Həmrəyliyi Günüdür.",
  ["Dünya Azərbaycanlılarının Həmrəyliyi Günü", "Zəfər Günü",
   "Bilik Günü", "Müəllim Günü"], 1, None, 3),
 ("Qənaət nə deməkdir?",
  "Resurslardan israf etmədən istifadə etmək.",
  ["İsraf etmədən istifadə etmək", "Heç nə xərcləməmək",
   "Çox xərcləmək", "Hər şeyi yığıb saxlamaq"], 1, None, 2),
 ("Suya qənaət üçün nə etməliyik?",
  "Kranı boş yerə açıq qoymamaq lazımdır.",
  ["Kranı boş yerə açıq qoymamaq", "Kranı həmişə açıq saxlamaq",
   "Hər gün hovuz doldurmaq", "Suyu dadmamaq"], 1, None, 1),
 ("İşığa qənaət üçün nə etməliyik?",
  "Otaqdan çıxanda işığı söndürmək lazımdır.",
  ["Otaqdan çıxanda işığı söndürmək", "Bütün lampaları yandırmaq",
   "Gündüz də işıq yandırmaq", "Heç vaxt söndürməmək"], 1, None, 1),
 ("Çörəyə münasibət necə olmalıdır?",
  "Çörək zəhmətlə başa gəlir — israf etmək olmaz.",
  ["İsraf etməmək", "Artığını atmaq", "Oyun oynamaq",
   "Yerə atmaq"], 1, None, 2),
 ("9 Noyabr hansı gündür?",
  "9 Noyabr — Dövlət Bayrağı Günüdür.",
  ["Dövlət Bayrağı Günü", "Yeni il", "Novruz", "Bilik Günü"],
  1, None, 3),
 ("Novruz süfrəsinin şirniyyatları hansılardır?",
  "Şəkərbura, paxlava, qoğal Novruz şirniyyatlarıdır.",
  ["Şəkərbura və paxlava", "Tort və keks",
   "Dondurma", "Çips və qazlı içki"], 1, None, 2),
 ("Cib pulunu necə xərcləmək düzgündür?",
  "Düşünülmüş, qənaətlə xərcləmək lazımdır.",
  ["Düşünülmüş və qənaətlə", "Bir gündə hamısını",
   "Yalnız oyunlara", "Sayarkən itirmək"], 1, None, 2),
],
"hey-3-tehlukesizlik": [
 ("Yolu keçmək üçün svetoforun hansı işığını gözləməliyik?",
  "Piyada üçün yaşıl işıq yanmalıdır.",
  ["Yaşıl", "Qırmızı", "Sarı", "İstənilən"], 1, None, 1),
 ("Küçəni haradan keçmək təhlükəsizdir?",
  "Yalnız piyada keçidindən.",
  ["Piyada keçidindən", "İstənilən yerdən", "Maşınların arasından",
   "Döngədən qaçaraq"], 1, None, 1),
 ("Evdə qaz iyi hiss edəndə nə etmək OLMAZ?",
  "Qığılcım partlayışa səbəb ola bilər.",
  ["Kibrit yandırmaq", "Pəncərəni açmaq", "Böyüklərə demək",
   "Evi tərk etmək"], 1, None, 2),
 ("Yanğın zamanı ilk növbədə nə etmək lazımdır?",
  "112-yə zəng edib təhlükəli yerdən uzaqlaşmaq.",
  ["112-yə zəng edib evi tərk etmək", "Gizlənmək",
   "Özü söndürməyə çalışmaq", "Heç nə etməmək"], 1, None, 2),
 ("Küçədə tapılan naməlum çantaya nə etməli?",
  "Toxunmayıb böyüklərə xəbər vermək lazımdır.",
  ["Toxunmayıb böyüklərə demək", "Açıb baxmaq", "Evə aparmaq",
   "Təpik vurmaq"], 1, None, 2),
 ("Elektrik rozetkasına nə salmaq olmaz?",
  "Metal əşya cərəyan vurmasına səbəb olur.",
  ["Metal əşyalar", "Cihazın öz ştepselini", "Heç nə olmaz",
   "Yalnız gündüz salmaq olar"], 1, None, 1),
 ("Velosipedi harada sürmək təhlükəsizdir?",
  "Park və xüsusi zolaqlar bunun üçündür.",
  ["Parkda və xüsusi zolaqda", "Maşın yolunda",
   "Körpünün kənarında", "Pilləkəndə"], 1, None, 2),
 ("Tanımadığın itə yaxınlaşmaq olarmı?",
  "Naməlum heyvana yaxınlaşmaq təhlükəlidir.",
  ["Olmaz", "Olar", "Yalnız gecə olar", "Yalnız qaçaraq olar"],
  1, None, 1),
 ("Dərmanı uşağa kim verməlidir?",
  "Dərmanı yalnız böyüklər, həkim təyinatı ilə verir.",
  ["Böyüklər, həkim təyinatı ilə", "Uşaq özü",
   "Sinif yoldaşı", "Heç kim"], 1, None, 2),
 ("Su hövzəsində böyüksüz çimmək olarmı?",
  "Təkbaşına çimmək təhlükəlidir.",
  ["Olmaz — təhlükəlidir", "Olar", "Yalnız isti gündə olar",
   "Yalnız dayaz yerdə olar"], 1, None, 2),
],
"inf-3-informasiya": [
 ("İnformasiyanı hansı orqanlarla qəbul edirik?",
  "Görmə, eşitmə, iybilmə, dadbilmə, toxunma — hiss orqanları ilə.",
  ["Hiss orqanları ilə", "Yalnız əllərlə", "Yalnız qulaqla",
   "Saçla"], 1, None, 1),
 ("Gözlə qəbul edilən informasiya hansıdır?",
  "Şəkil, yazı, rəng — görmə informasiyasıdır.",
  ["Görmə", "Səs", "Dad", "Qoxu"], 1, None, 1),
 ("Musiqi hansı informasiya növüdür?",
  "Musiqini qulaqla qəbul edirik — səs informasiyasıdır.",
  ["Səs", "Görmə", "Dad", "Toxunma"], 1, None, 1),
 ("Hansı sırada hamısı informasiya mənbəyidir?",
  "Kitab da, televizor da, insan da məlumat verir.",
  ["Kitab, televizor, insan", "Kitab, daş, qum",
   "Televizor, boş vərəq, daş", "Divar, qapı, döşəmə"], 1, None, 2),
 ("Məktəb zənginin səsi bizə nə bildirir?",
  "Zəng dərsin başlandığını və ya bitdiyini bildirir.",
  ["Dərsin başlandığını və ya bitdiyini", "Havanın istiliyini",
   "Günün tarixini", "Heç nə"], 1, None, 2),
 ("Hansı, informasiya daşıyıcısıdır?",
  "Disk üzərində məlumat saxlanılır.",
  ["Disk", "Stul", "Pəncərə", "Ayaqqabı"], 1, None, 2),
 ("Dad informasiyasını hansı orqanla qəbul edirik?",
  "Dadı dil ilə hiss edirik.",
  ["Dil ilə", "Göz ilə", "Qulaq ilə", "Burun ilə"], 1, None, 2),
 ("Hansı hərəkət informasiyanın ötürülməsidir?",
  "Məktub göndərəndə məlumat başqasına çatdırılır.",
  ["Məktub göndərmək", "Yatmaq", "Qaçmaq", "Yemək yemək"],
  1, None, 2),
 ("Qədim dövrdə insanlar məlumatı necə ötürürdülər?",
  "Çaparlar və məktublarla.",
  ["Çaparla və məktubla", "Telefonla", "İnternetlə",
   "Televizorla"], 1, None, 3),
 ("Toxunmaqla əşyanın hansı xassəsini öyrənmək olar?",
  "Hamar və ya kobud olduğunu toxunmaqla bilirik.",
  ["Hamar və ya kobud olduğunu", "Rəngini", "Səsini",
   "Adını"], 1, None, 2),
],
"inf-3-alqoritm": [
 ("Hansı, alqoritmə misaldır?",
  "Yemək resepti addım-addım icra qaydasıdır.",
  ["Yemək resepti", "Şəkil", "Mahnı", "Rəng"], 1, None, 2),
 ("Alqoritmdə addımlar necə düzülür?",
  "Addımlar icra sırası ilə, ardıcıl düzülür.",
  ["Ardıcıl", "Qarışıq", "Sondan əvvələ", "İstənilən kimi"],
  1, None, 1),
 ("«Səhər oyan → ? → geyin» alqoritmində buraxılmış addım hansı "
  "ola bilər?",
  "Oyanandan sonra üz-əl yuyulur.",
  ["Üzünü yu", "Axşam yeməyi ye", "Yat", "Məktəbdən qayıt"],
  1, None, 2),
 ("Alqoritmi kim və ya nə icra edə bilər?",
  "İcraçı insan, robot və ya kompüter ola bilər.",
  ["İnsan, robot, kompüter", "Yalnız insan", "Yalnız daş",
   "Heç kim"], 1, None, 2),
 ("Alqoritmin addımları qarışdırılsa, nə olar?",
  "Ardıcıllıq pozulsa, nəticə səhv alınar.",
  ["Nəticə səhv alınar", "Heç nə dəyişməz", "Daha tez bitər",
   "Nəticə yaxşılaşar"], 1, None, 2),
 ("«Başla» və «Son» alqoritmin nəyini bildirir?",
  "Alqoritmin haradan başlayıb harada bitdiyini.",
  ["Başlanğıcını və sonunu", "Rəngini", "Çəkisini",
   "Müəllifini"], 1, None, 1),
 ("Hansı, alqoritm DEYİL?",
  "Mənasız söz yığınında ardıcıl addımlar yoxdur.",
  ["Mənasız söz yığını", "Çay dəmləmə qaydası",
   "Əl yuma qaydası", "Misal həlli qaydası"], 1, None, 3),
 ("Gülü suvarma alqoritmində birinci addım hansıdır?",
  "Əvvəlcə suqabına su doldurulur.",
  ["Suqabına su doldurmaq", "Gülü dibindən kəsmək",
   "Torpağı atmaq", "Yarpaqları yumaq"], 1, None, 2),
 ("«Alqoritm» sözü haradan yaranıb?",
  "Alim Əl-Xarəzminin adından yaranıb.",
  ["Alim Əl-Xarəzminin adından", "Şəhər adından",
   "Oyun adından", "Heyvan adından"], 1, None, 3),
 ("Misalın addım-addım həlli alqoritmdirmi?",
  "Bəli — ardıcıl icra olunan addımlardır.",
  ["Bəli", "Xeyr", "Yalnız çətin misallarda", "Yalnız dərslikdə"],
  1, None, 2),
],
"inf-3-kompyuter": [
 ("Kompüterin əsas qurğuları hansılardır?",
  "Sistem bloku, monitor, klaviatura və maus.",
  ["Sistem bloku, monitor, klaviatura, maus",
   "Stol, stul, lampa", "Kitab, dəftər, qələm",
   "Televizor və pult"], 1, None, 1),
 ("Klaviatura nə üçündür?",
  "Klaviatura ilə məlumat (hərf, rəqəm) daxil edilir.",
  ["Məlumat daxil etmək üçün", "Səs eşitmək üçün",
   "Şəkil göstərmək üçün", "Çap etmək üçün"], 1, None, 1),
 ("Ekrandakı oxu (kursoru) hansı qurğu ilə hərəkət etdiririk?",
  "Maus ekrandakı oxu idarə edir.",
  ["Maus", "Printer", "Dinamik", "Mikrofon"], 1, None, 1),
 ("Kompüter arxasında iş vaxtı necə olmalıdır?",
  "Məhdud vaxt, fasilələrlə işləmək lazımdır.",
  ["Məhdud, fasilələrlə", "Bütün günü", "Gecə boyu",
   "Fasiləsiz"], 1, None, 2),
 ("Sistem blokunun içində nə yerləşir?",
  "Prosessor və yaddaş sistem blokundadır.",
  ["Prosessor və yaddaş", "Kitablar", "Dinamik və mikrofon",
   "Kağız və mürəkkəb"], 1, None, 2),
 ("Noutbuku masaüstü kompüterdən nə fərqləndirir?",
  "Noutbuk yığcamdır, daşınabiləndir.",
  ["Daşına bilməsi", "Ekranının olmaması",
   "Klaviaturasının olmaması", "İşləməməsi"], 1, None, 2),
 ("Planşet əsasən nə ilə idarə olunur?",
  "Planşetin sensor ekranı toxunuşla işləyir.",
  ["Toxunuşla (sensor ekranla)", "Pultla", "Pedalla",
   "Açarla"], 1, None, 2),
 ("«Enter» düyməsi nə edir?",
  "Əmri təsdiqləyir, mətndə yeni sətrə keçirir.",
  ["Əmri təsdiqləyir", "Kompüteri söndürür", "Səsi artırır",
   "Ekranı silir"], 1, None, 3),
 ("Faylları kompüterin harasında saxlayırıq?",
  "Fayllar kompüterin yaddaşında saxlanılır.",
  ["Yaddaşında", "Monitorunda", "Mausunda", "Naqilində"],
  1, None, 2),
 ("Kompüter arxasında düzgün oturuş necədir?",
  "Kürək düz, ekran gözdən aralı olmalıdır.",
  ["Kürək düz, ekrandan aralı", "Ekrana yapışaraq",
   "Uzanaraq", "Ayaq üstə əyilərək"], 1, None, 2),
],
"inf-3-metn": [
 ("Mətn redaktoru nə üçündür?",
  "Mətn yazmaq və onu düzəltmək üçün proqramdır.",
  ["Mətn yazmaq və düzəltmək üçün", "Oyun oynamaq üçün",
   "Mahnı dinləmək üçün", "Şəkil çəkmək üçün"], 1, None, 1),
 ("Böyük hərf yazmaq üçün hansı düymədən istifadə olunur?",
  "Shift saxlanılıb hərf basılır.",
  ["Shift", "Space", "Esc", "Tab"], 1, None, 2),
 ("Sözlər arasında boşluq hansı düymə ilə qoyulur?",
  "Boşluq (Space) düyməsi ilə.",
  ["Boşluq (Space)", "Enter", "Shift", "Backspace"], 1, None, 1),
 ("Səhv yazılmış son hərfi hansı düymə silir?",
  "Backspace kursordan soldakı simvolu silir.",
  ["Backspace", "Enter", "Shift", "Caps Lock"], 1, None, 2),
 ("Yeni sətrə keçmək üçün hansı düymə basılır?",
  "Enter yeni sətrə keçirir.",
  ["Enter", "Space", "Shift", "Alt"], 1, None, 2),
 ("Hansı, mətn redaktorudur?",
  "Word mətn redaktorudur.",
  ["Word", "Kalkulyator", "Saat", "Musiqi pleyeri"], 1, None, 2),
 ("Yazdığın mətni itirməmək üçün nə etməlisən?",
  "Sənədi yadda saxlamaq (Save) lazımdır.",
  ["Yadda saxlamaq (Save)", "Kompüteri söndürmək",
   "Ekranı bağlamaq", "Heç nə"], 1, None, 2),
 ("Kursor nədir?",
  "Mətndə yazının qoyulacağı yeri göstərən işarədir.",
  ["Yazı yerini göstərən işarə", "Şəkil növü",
   "Proqram adı", "Düymə adı"], 1, None, 2),
 ("Hərfləri hansı qurğu ilə yığırıq?",
  "Mətn klaviatura ilə yığılır.",
  ["Klaviatura ilə", "Mausla", "Dinamiklə", "Printerlə"],
  1, None, 1),
 ("Yazdığınız mətni kağıza köçürən qurğu hansıdır?",
  "Printer mətni kağıza çap edir.",
  ["Printer", "Skaner", "Mikrofon", "Dinamik"], 1, None, 2),
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
                p.append("hesablanan «%s» != variant «%s»" % (expect, opts[correct - 1]))
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
    on = {"az-dili": "az3", "hayat-bilgisi": "hey3", "informatika": "inf3"}
    setirler = []
    for fenn, movzu, rub in MOVZULAR:
        qisa = movzu.split("-", 2)[2]
        for i, (body, why, opts, correct, _e, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "('%s-%s#%d','%s','%s',%d,%d,'%s','%s',array['%s','%s','%s','%s'],%d)"
                % (on[fenn], qisa, i, fenn, movzu, diff, rub, q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  20_bank_sinif3.sql : 3-CU SINIF - AZ DILI, HEYAT BILGISI, INFORMATIKA
--
--  BU FAYL ELLE YAZILMIR - tools/sinif3.py yaradir:
--      python3 tools/sinif3.py
--
--  Az dili 8 + Heyat bilgisi 6 + Informatika 4 = 18 movzu x 10 = %d.
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
   and (q.ext_key like 'az3-%%' or q.ext_key like 'hey3-%%'
        or q.ext_key like 'inf3-%%');

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
     and (ext_key like 'az3-%%' or ext_key like 'hey3-%%'
          or ext_key like 'inf3-%%');
  if n <> %d then
    raise exception 'sinif3 suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'az3-%%' or q.ext_key like 'hey3-%%'
          or q.ext_key like 'inf3-%%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'az3-%%' or ext_key like 'hey3-%%'
      or ext_key like 'inf3-%%';
  if k <> 18 then
    raise exception 'movzu sayi 18 deyil: %%', k;
  end if;
  raise notice '3-cu sinif banki: %% sual, 18 movzu (az dili, heyat bilgisi, informatika).', n;
end $$;
""" % (n, ",\n".join(setirler), n, n))
    print("yazildi: %s" % CIXIS)


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
