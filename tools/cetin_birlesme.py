#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
"Coxmulahizeli birlesme sualı" retrofit-i (CLAUDE.md, "novbeti merhele"
bolmesi). Movcud CETIN (difficulty=3) sualin ozu ORTA (2) seviyyeye
enir - ARXIVLENMIR, movzuda qalir, kohne netice/hesabat toxunulmaz
qalir. Onun YERINE eyni movzuda 4 nomrelenmis mulahize + kombinasiya
variantlari olan yeni sual 3 (cetin) kimi yazilir.

Qayda: 4 mulahize YALNIZ hemin movzunun oz bankinda ARTIQ movcud olan
(evvelden dogru cavabi ile tesdiqlenmis) faktlardan qurulur - yeni
fakt UYDURULMUR. Bir erken pilotda uydurulmus elave detala real
sagird "derslikde yoxdur" deyib - bu qayda onun ucundur.

Elave sual YOX, mevcud `single` novun icindedir (sxeme toxunmur) -
sadece body coxsetirlidir, variantlar kombinasiya seklindedir
(A) 1,3  B) yalniz 1  C) 2,4  D) 1,2,3).

Diqqet: `questions.difficulty` sxemde 1..3 ile mehduddur (asan/orta/
cetin) - "Difficulty 4/5" kimi bir seviyye YOXDUR. Asagidaki pipeline
bu mehdud daxilinde CETIN (3) qutunun oz DAXILI keyfiyyetini artirmaq
ucundur - yeni reqem qatmaq ucun yox.

YENI BEND YAZANDA PIPELINE (mecburidir):
  FAKT -> SELECT ile tesdiq -> movzunun oz f(x)/cumlesi -> elaqe ->
  qerar noqtesi -> real sehv telesi -> validasiya

  1. Movzunun bankindan 3-4 fakti secmezden evvel HERESINI ayrica
     SELECT-le tesdiqle (bax asagida `bend_yaz`-in ustunde - RETROFIT
     siyahisinin her girisi ozunun mensei sualina istinad edir).
  2. Faktlar YAN-YANA DUZULMESIN - biri o birinin ustunde qurulmalidir
     (mes. bohran noqtesini tap -> onun maks/min olduğunu tesniflendir
     -> bu netice ile parca qaydasini tetbiq et). "A dogrudur, B
     dogrudur, C dogrudur, D dogrudur" formasi - hec biri bir-birinden
     asili olmayan 4 ayri fakt - CETIN sayilmir, hetta 4 fakt olsa da.
  3. Ən azi BIR QERAR NOQTESI olsun - sagird hansi qaydani, hansi
     movzudaki iki oxsar anlayisdan hansini tetbiq edeceyini OZU
     secmeli olsun (Duz/yalnis sadece tanima ile tapilmasin).
  4. Yanlis mulahize(ler) REAL sagird sehvinden qurulsun (bank
     icindeki oxsar/qonsu sualdan gorunen tipik qarisiqliq - mes.
     isare sehvi, oxsar qrammatik struktur, sebeb/zaman qarisdirmasi)
     - tesadufi yanlis fakt yox.
  5. Fenne gore "cetinlik" fergli menbeden gelir (CLAUDE.md-de artiq
     qismen yazilib, burada bir yerde toplanir):
       riyaziyyat  -> beheresablama/nomreleme deyil, bir nece qaydanin
                      ARDICIL tetbiqi + strategiya secimi
       az dili     -> oxsar gorunen iki dil hadisesinin ferqlendirilmesi
                      (mes. sebeb zerfliyi vs meqsed zerfliyi)
       ingilis     -> oxsar qrammatik struktur/zaman formasinin
                      kontekstde ferqlendirilmesi (mes. "been to" vs
                      "gone to", Present Perfect vs Past Simple + vaxt
                      qeydi)
     Humanitar fenlerde cetinliyi mətnin UZUNLUGU ile artirma - bu,
     oxu yukudur, dusunme yuku deyil.
  6. Final yoxlama (`yoxla()` bunun bir hissesini avtomatik edir,
     qalani elle):
     [ ] her mulahize movcud bankdan SELECT ile tesdiqlenib?
     [ ] hec bir yeni akademik/qrammatik fakt yaradilmayib?
     [ ] mulahizeler yan-yana yox, bir-biri ile elaqelidir?
     [ ] sagird en azi bir qerar vermelidir (birbasa tanima kifayet
         etmir)?
     [ ] yanlis mulahize real sehv tipinden qurulub (tesadufi yox)?
     [ ] cetinlik lazimsiz uzunluq/sun tele hesabina yaranmayib?

V2 STANDART (2026-09-03, xarici review-dan sonra - ilk 48 sual "V1"
bu standartdan evvel yazilib, geriye qaytarilmayib, amma YENI her
bend bunu izlemelidir):

  A. "ASILILIQ" ISTIQAMETINI DEQIQ YAZ - ISTIQAMETINI SISDIRME.
     Bir bendin diger benddeki NETICEYE (er. hesablanmis eded, teyin
     edilmis noqte) istinad etmesi kifayetdir - "bu ustundeki bendsiz
     HEC CUR helli mumkun deyil" kimi mutleq iddia YAZMA, cunki
     cox vaxt herfi surenmis ele bir alternativ yol da olur (mes.
     duz deyisen elave etmeden birbasa eded yerine yazmaq). Duzgun
     ifade: "N-ci bend N-1-ci bendin neticesini ISTIFADE EDIR ve onu
     eheiyyetli deremede sadelesdirir" - mutleq imkansizlq iddiasi yox.
  B. MUBAHISELI/DERSLIYE-GORE-DEYISEN MOVZULARDA YALNIZ BANKA
     ISTINAD ET. Morfologiya, sintaksis kimi sahelerde kok/sekilci
     serhedi, terminaloji tesnifat fergli dersliklerde ferqli izah
     oluna biler - bu bendlerde ozunden ("mence beledir") HEC BIR
     elave qerar vermə, YALNIZ bankin ozunun artiq yazdigi cavabi
     (SELECT ile) tekrarla. Bank ne deyirse o - bas­qa mueellifin
     baxisi yox.
  C. HEDEF 7-8/10-dur, 9-10/10 YOX. Suni coxmerheleli tehlil, sun
     tele, ya da mubahiseli detal elave etmekden qacin - hedd asilanda
     sual dersliyin serhedinden cixmaga baslayir. Bir bendin diger
     bende ISTINAD etmesi kifayetdir, uc-dord qat ic-ice mentiq lazim
     deyil.
  D. HER YENI BEND UCUN OZ-OZUNE AUDIT YAZ (serh kimi, bend-in
     ustunde, "Cetinlik:" basliqli):
       Cetinlik: [daxili qiymetlendirme, 1-10 arasi - YALNIZ sened
         ucundur, questions.difficulty yene de 1..3 qalir]
       Sebeb: [1-2 cumle - hansi elaqe/qerar noqtesi var]
       Addimlar: [mes. "1 -> 2 -> 4"]
       Derslikden kenar bilik? Xeyr (hemise Xeyr olmalidir)
       Birbasa ezberle cavablandirila biler? Xeyr

Ehate: 48 sual (V1) - riyaziyyat/az dili/ingilis, 10 ve 11-ci sinif,
her ikisi TAM (movzu-movzu). Boyutmek ucun RETROFIT-e yeni bend
elave edib yeniden islet - 9-cu sinifden basqa V2 standartla.

Islet:  python3 tools/cetin_birlesme.py
Netice: db/112_bank_cetin_birlesme.sql
"""
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(KOK, "db", "112_bank_cetin_birlesme.sql")

# her bend: (fenn_slug, proqram_slug, sinif_kodu, movzu_slug,
#            kohne_ext_key, yeni_ext_key, body, izah, [4 variant], duz_ord)
# DIQQET: hemise ayni ord-da (mes. hemise 1-ci variant) duz cavab
# qoymaq oz-ozune bir "qelib" yaradir - sagird mezmuna baxmadan "hemise
# A" secib xal apara biler. Asagida duz cavabin ord-u qesden 1..4
# arasinda deyisdirilib (movzu/dogruluqla elaqesi yoxdur, sadece
# yerlesdirme).

RETROFIT = [
    ("riyaziyyat", "orta", "11", "riy-11-toreme",
     "riy11-toreme#11", "riy11-toreme#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) (sin x)′ = cos x\n"
     "2) (cos x)′ = sin x\n"
     "3) (eˣ)′ = eˣ\n"
     "4) (ln x)′ = x",
     "(sin x)′ = cos x və (eˣ)′ = eˣ doğrudur. 2-ci mülahizədə işarə "
     "səhvdir (doğrusu −sin x), 4-cü mülahizədə isə (ln x)′ əslində "
     "1/x-dir, x deyil.",
     ["1", "1, 3", "2, 4", "1, 2, 3"], 2),

    ("az-dili", "orta", "11", "az-11-murekkeb-t",
     "az11-murekkeb-t#12", "az11-murekkeb-t#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Külək əsdi, yarpaqlar töküldü» cümləsi tabesiz mürəkkəb cümlədir.\n"
     "2) «Yağış yağanda hava sərinləşir» cümləsindəki budaq cümlə səbəb bildirir.\n"
     "3) «Hava pis olduğu üçün gəzintini təxirə saldıq» cümləsindəki budaq cümlə səbəb bildirir.\n"
     "4) «Bilirəm ki, sən haqlısan» cümləsindəki budaq cümlə zaman bildirir.",
     "1 və 3 doğrudur. 2-ci mülahizədə əslində zaman bildirilir (səbəb "
     "yox), 4-cü mülahizədə isə budaq cümlə tamamlıq (xəbər) "
     "vəzifəsindədir, zaman yox.",
     ["1", "2, 4", "1, 2, 3", "1, 3"], 4),

    ("ingilis-dili", "orta", "11", "ing-11-regrets",
     "ing11-regrets#20", "ing11-regrets#comb1",
     "Which statements are TRUE?\n"
     "1) \"If they had left earlier, they would have caught the train\" is a Third Conditional sentence.\n"
     "2) \"He regrets leaving school early\" uses the -ing form after \"regret\".\n"
     "3) \"We could have taken a taxi instead of walking, but we did not\" describes a missed past possibility.\n"
     "4) \"She wishes she lived in a bigger city now\" uses the Past Perfect after \"wish\".",
     "1, 2 and 3 are true. Statement 4 is wrong - \"wishes...lived\" "
     "uses the Past Simple to express a present wish, not the Past Perfect.",
     ["1, 2, 3", "yalnız 1", "2, 4", "3, 4"], 1),

    # ---- ikinci dalğa: faktlar YAN-YANA yox, bir-birinin üstündə
    # qurulur (bax faylın başlığındakı pipeline). Hər fakt öz mənbə
    # sualına aşağıda şərhdə istinad edir - SELECT-lə ayrıca yoxlanıb.

    # riy11-arasdirma#13 (bohran noqteleri x=+-1) + #5 (musbetden
    # menfiye -> maksimum) + #14 (parcada eng boyuk qiymet bohran VE
    # uclarda axtarilir) - f(x)=x^3-3x hamisinin ustunde qurulur:
    # bohran noqte tap -> tebietini teyin et -> parca qaydasini
    # tetbiq et. 4-cu mulahize tuzaqdir: x=1 bu parcada MINIMUMdur,
    # parcanin oz maksimumu ucda (x=2) - Python-la yoxlanildi (f(0)=0,
    # f(1)=-2, f(2)=2).
    ("riyaziyyat", "orta", "11", "riy-11-arasdirma",
     "riy11-arasdirma#4", "riy11-arasdirma#comb1",
     "f(x) = x³ − 3x funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Funksiyanın böhran nöqtələri x = −1 və x = 1-dir.\n"
     "2) x = −1 nöqtəsində funksiyanın maksimumu var.\n"
     "3) x = 1 nöqtəsində funksiyanın minimumu var.\n"
     "4) f(x)-in [0; 2] parçasında ən böyük qiyməti f(1) nöqtəsindədir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: x = 1 elə bu parçanın "
     "öz MİNİMUMUDUR (f(1) = −2), parçanın ən böyük qiyməti isə ucda, "
     "x = 2-də (f(2) = 2) əldə olunur - böhran nöqtəsi həmişə parçanın "
     "ekstremumu demək deyil, uclar da yoxlanmalıdır.",
     ["1, 2, 3, 4", "2, 3, 4", "1, 2, 3", "1, 3"], 3),

    # az11-sintaksis-d#20 (hemcins mubteda -> "eyni suala cavab verib
    # eyni uzve baglanmaq" qaydasinin, #19-dan, paralel siyahiya
    # tetbiqi) + #17 (sevincinden = sebeb zerfliyi) + #18 (etmek ucun
    # = meqsed zerfliyi) - eyni iki cumle qelibi TEK cumlede
    # birlesdirilib. Tuzaq: 3-cu mulahize "etmek ucun"-u sebeb kimi
    # gosterir - bu, sebeb/meqsed zerfliyinin adi qarisdirilmasidir.
    ("az-dili", "orta", "11", "az-11-sintaksis-d",
     "az11-sintaksis-d#21", "az11-sintaksis-d#comb1",
     "«Aygün, Vüsal və Kamran sevincindən ağladılar, sonra müəllimlərinə "
     "təşəkkür etmək üçün sinfə qayıtdılar» cümləsi ilə bağlı "
     "aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Aygün, Vüsal və Kamran» həmcins mübtədadır.\n"
     "2) «Sevincindən ağladılar» hissəsində zərflik səbəb bildirir.\n"
     "3) «Müəllimlərinə təşəkkür etmək üçün» hissəsi səbəb zərfliyidir.\n"
     "4) Cümlədə iki fərqli zərflik növü (səbəb və məqsəd) iştirak edir.",
     "1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «təşəkkür etmək "
     "üçün» səbəb yox, MƏQSƏD zərfliyidir (nəyə görə deyil, nə üçün "
     "sualına cavab verir) - səbəb və məqsəd zərfliyi tez-tez "
     "qarışdırılır.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 3, 4"], 2),

    # ing11-experiences#18 (been to = qayidib, gone to = hele ordadir)
    # + #14/#25 (konkret kecmis vaxt qeydi -> Past Simple, Present
    # Perfect ile birlesmir). Tuzaq iki yerde: 1-ci mulahize "been
    # to"-nu "gone to" kimi oxuyur, 4-cu mulahize Present Perfect-i
    # konkret vaxt qeydi ("an hour ago") ile birlesdirir - ikisi de
    # bankdaki qaydalarin birbasa pozulmasidir.
    ("ingilis-dili", "orta", "11", "ing-11-experiences",
     "ing11-experiences#8", "ing11-experiences#comb1",
     "Tom has been to Italy three times. He has gone to Spain now, so "
     "he is not here. He arrived in London an hour ago.\n"
     "Which statements are TRUE?\n"
     "1) \"Tom has been to Italy three times\" means Tom is currently in Italy.\n"
     "2) \"He has gone to Spain now\" means he is currently away in Spain.\n"
     "3) \"He arrived in London an hour ago\" uses Past Simple because \"an hour ago\" is a specific past time expression.\n"
     "4) \"He arrived in London an hour ago\" could correctly be rewritten as \"He has arrived in London an hour ago\" without changing the meaning.",
     "2 and 3 are true. Statement 1 is wrong - \"has been to\" means he "
     "went and RETURNED, not that he is still there (that is \"has gone "
     "to\"). Statement 4 is wrong - Present Perfect cannot combine with "
     "a specific past-time expression like \"ago\".",
     ["1, 2", "1, 3, 4", "2, 3, 4", "2, 3"], 4),

    # ---- ucuncu dalga (2026-09-03): eyni 3 fennden daha bir movzu.

    # riy11-inteqral#22 (guc qaydasi: integral(x^3)=x^4/4+C) + #9
    # (sabitin inteqrali: integral(a)=ax+C) + #11 (cemin/ferqin
    # inteqrali = inteqrallarin cemi/ferqi) - bu ucu ile
    # F(x)=x^3/3-4x qurulur (f(x)=x^2-4-un ibtidaisi) + #40
    # (Nyuton-Leybniz: integral[a,b] = F(b)-F(a)) + #29 (menfi
    # qiymetli funksiyanin inteqrali sahenin EKS ISARELISIDIR).
    # f(x)=x^2-4 [0;2]-de HEMISE <=0 (Python-la yoxlanildi: f(0)=-4,
    # f(2)=0) - integral=-16/3, sahe=+16/3. Tuzaq: 4-cu mulahize
    # funksiyani "musbet" hesab edib inteqrali birbasa sahe kimi
    # oxuyur - #29-un tam eksi.
    ("riyaziyyat", "orta", "11", "riy-11-inteqral",
     "riy11-inteqral#7", "riy11-inteqral#comb1",
     "f(x) = x² − 4 funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) f(x)-in ibtidai funksiyası F(x) = x³/3 − 4x + C-dir.\n"
     "2) ∫₀² f(x) dx = −16/3-dür.\n"
     "3) f(x) [0; 2] parçasında mənfi qiymətli olduğu üçün əyri ilə x-oxu arasındakı sahə 16/3-dür.\n"
     "4) f(x) [0; 2] parçasında müsbət qiymətli olduğu üçün inteqralın nəticəsi birbaşa sahəyə bərabərdir.",
     "1, 2 və 3 doğrudur (F(2) − F(0) = −16/3 − 0 = −16/3, sahə isə əks "
     "işarəlisi 16/3-dür). 4-cü mülahizə yanlışdır: f(x) bu parçada "
     "mənfi (və ya sıfır) qiymətlidir, müsbət deyil - buna görə "
     "inteqral birbaşa sahə vermir, əks işarəli götürülməlidir.",
     ["1, 2, 3, 4", "2, 3, 4", "1, 3", "1, 2, 3"], 4),

    # az11-morfologiya-d#10/#11/#12/#9 - feilin 4 mena novunun
    # (mechul/qarsiliq/icbar/qayidis) EYNI qrammatik qelible qurulmus
    # 4 cumlede fergendirilmesi. Tuzaq: 3-cu mulahize icbari (#12-nin
    # qelibi - birine bir isi GORDURMEK) qayidis kimi gosterir - bu,
    # icbar/qayidis novlerinin klassik qarisdirilmasidir.
    ("az-dili", "orta", "11", "az-11-morfologiya-d",
     "az11-morfologiya-d#15", "az11-morfologiya-d#comb1",
     "«Qapı bağlandı. Uşaqlar öpüşdülər. Ana uşağa corabı geydirtdi. "
     "Aygün səhər tez yuyundu.» Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Qapı bağlandı» - məchul növdür.\n"
     "2) «Uşaqlar öpüşdülər» - qarşılıq növdür.\n"
     "3) «Ana uşağa corabı geydirtdi» - qayıdış növdür.\n"
     "4) «Aygün səhər tez yuyundu» - qayıdış növdür.",
     "1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «geydirtdi» İCBAR "
     "növdür (biri başqasına bir işi gördürür) - qayıdış (məs. "
     "«yuyundu») ilə icbar tez-tez qarışdırılır, çünki hər ikisi "
     "feilə əlavə şəkilçi qoşulmasıdır.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 3, 4"], 1),

    # ing11-whys#1 (because of = sebeb, + isim) + #14 (Despite = ziddiyet,
    # + isim) + #27 (As a result of = sebeb-netice, + gerund) - ucu de
    # eyni qrammatik qelibde (preposition + isim ifadesi), amma MENALARI
    # ZIDDIR. Tuzaq: 3-cu mulahize "despite" ve "because of"-u eyni
    # mena kimi ("although" ile evezlene bilen) gosterir - bu, hem
    # sebeb/ziddiyet qarisdirmasidir, hem de qrammatik sehvdir
    # ("although" clause isteyir, isim ifadesi yox).
    ("ingilis-dili", "orta", "11", "ing-11-whys",
     "ing11-whys#28", "ing11-whys#comb1",
     "He passed the exam because of hard studying. Despite the heavy "
     "rain, the match continued. As a result of eating too much junk "
     "food, she felt sick.\n"
     "Which statements are TRUE?\n"
     "1) \"He passed the exam because of hard studying\" shows a cause-result relationship.\n"
     "2) \"Despite the heavy rain, the match continued\" shows a contrast, not a cause.\n"
     "3) \"Despite\" and \"because of\" can both be replaced by \"although\" without changing the grammar, since all three introduce a reason.\n"
     "4) \"As a result of eating too much junk food, she felt sick\" shows a cause-result relationship, like \"because of\".",
     "1, 2 and 4 are true. Statement 3 is wrong - \"despite\" shows "
     "CONTRAST, not reason like \"because of\", and \"although\" needs a "
     "clause (subject + verb), not a noun phrase.",
     ["1, 3, 4", "1, 2, 4", "1, 2, 3", "2, 3, 4"], 2),

    # ---- dorduncu dalga (2026-09-03): riyaziyyat/az dili/ingilis-in
    # HAMISI 11-ci sinifde - qalan movzular teker-teker deyil, fenn/
    # sinif uzre TAM bitirilir (istifadecinin sorgusu). Riyaziyyatda
    # her fakt Python-la (yuxarida ayrica komanda ile) tekrar
    # yoxlanildi.

    # riy11-coxhedli#4 (P(a)=0 -> (x-a) voruqdur) + #2 (qaliq teoremi:
    # qaliq=P(a)) + #30 (P(1)=0 -> (x-1) qaliqsiz bolunur) - hamisi
    # P(x)=x^3-2x^2-5x+6 uzerinde: P(1)=P(3)=P(-2)=0 (Python-la
    # yoxlanildi). Tuzaq: 4-cu mulahize P(3)-u hesablamadan "qaliq
    # sifirdan ferqlidir" deyir - amma P(3)=0, yeni (x-3) de vuruqdur.
    ("riyaziyyat", "orta", "11", "riy-11-coxhedli",
     "riy11-coxhedli#26", "riy11-coxhedli#comb1",
     "P(x) = x³ − 2x² − 5x + 6 çoxhədlisi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) P(1) = 0-dır.\n"
     "2) Qalıq teoreminə görə, P(x)-in (x − 1)-ə bölünməsindən qalıq P(1)-ə bərabərdir.\n"
     "3) 1-ci və 2-ci mülahizələrə əsasən, (x − 1) P(x)-in vuruğudur.\n"
     "4) P(x)-in (x − 3)-ə bölünməsindən qalıq sıfırdan fərqlidir.",
     "1, 2 və 3 doğrudur (P(1)=1−2−5+6=0, deməli qalıq sıfırdır və "
     "(x−1) vuruqdur). 4-cü mülahizə yanlışdır: P(3)=27−18−15+6=0 - "
     "yəni (x−3) də vuruqdur, qalıq sıfırdan fərqli deyil, elə "
     "sıfırdır.",
     ["1, 2, 3, 4", "2, 3", "1, 2, 3", "1, 3"], 3),

    # riy11-feza-vektor#5 (a(1,2,2).b(2,1,-2)=0) + #6 (skalyar hasil=0
    # -> perpendikulyar) + #7 (kollinear=paralel istiqametli) + #2-nin
    # qelibi (uzunluq duesturu). Tuzaq: 3-cu mulahize eyni iki vektoru
    # HEM perpendikulyar, HEM kollinear elan edir - qeyri-sifir
    # vektorlar ucun bu ikisi eyni anda ola bilmez.
    ("riyaziyyat", "orta", "11", "riy-11-feza-vektor",
     "riy11-feza-vektor#23", "riy11-feza-vektor#comb1",
     "a(1; 2; 2) və b(2; 1; −2) vektorları verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) a·b skalyar hasili sıfırdır.\n"
     "2) Bu vektorlar bir-birinə perpendikulyardır.\n"
     "3) Eyni zamanda bu vektorlar kollineardır (paraleldir).\n"
     "4) a vektorunun uzunluğu 3-dür.",
     "1, 2 və 4 doğrudur (a·b=1·2+2·1+2·(−2)=0; |a|=√(1+4+4)=3). "
     "3-cü mülahizə yanlışdır: sıfır olmayan vektorlar eyni zamanda "
     "həm perpendikulyar, həm kollinear ola bilməz - bu, bir-birini "
     "istisna edən iki vəziyyətdir.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 3, 4"], 1),

    # riy11-limit#12 ((x^2-9)/(x-3) 0/0 -> 6) + #22 (0/0 ixtisar ile
    # aradan qaldirilir) + #7 (kesilmez funksiyada limit=qiymet) +
    # #15 (kesilme noqtesi anlayisi). Tuzaq: 4-cu mulahize "limit var
    # -> kesilmezdir" deyir, amma funksiya x=3-de TEYIN OLUNMAYIB -
    # limitin movcudlugu kesilmezlik ucun kifayet etmir.
    ("riyaziyyat", "orta", "11", "riy-11-limit",
     "riy11-limit#37", "riy11-limit#comb1",
     "g(x) = (x² − 9)/(x − 3) funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) x = 3 nöqtəsində g(x) 0/0 şəklində qeyri-müəyyənlikdir.\n"
     "2) Bu qeyri-müəyyənlik ifadəni çevirib ixtisar etməklə aradan qaldırılır.\n"
     "3) lim(x→3) g(x) = 6-dır.\n"
     "4) g(x) x = 3 nöqtəsində kəsilməzdir, çünki limit mövcuddur və 6-ya bərabərdir.",
     "1, 2 və 3 doğrudur (g(x)=(x−3)(x+3)/(x−3)=x+3, x→3-də → 6). "
     "4-cü mülahizə yanlışdır: g(3) ümumiyyətlə TƏYİN OLUNMAYIB "
     "(məxrəc sıfır olur) - limitin mövcudluğu funksiyanın həmin "
     "nöqtədə kəsilməz olması demək deyil, bu, aradan qaldırıla bilən "
     "kəsilmə nöqtəsidir.",
     ["1, 2, 4", "2, 3, 4", "1, 3", "1, 2, 3"], 4),

    # riy11-firlanma#5 (silindr r=3,h=5 yan sahe=30pi) + #9 (konus
    # r=3,l=5 yan sahe=15pi) + #25 (silindr radiusu 2x -> yan sahe 2x,
    # h sabit) - Python-la yoxlanildi. Tuzaq: 4-cu mulahize duesturun
    # radiusda XETTI (2pi*r*h) oldugunu unudub sahenin here zaman
    # kvadratik boyudugunu (4 defe) iddia edir.
    ("riyaziyyat", "orta", "11", "riy-11-firlanma",
     "riy11-firlanma#37", "riy11-firlanma#comb1",
     "Radiusu 3 olan silindr (hündürlüyü 5) və radiusu 3 olan konus (doğuranı 5) verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Silindrin yan səthinin sahəsi 30π-dir.\n"
     "2) Konusun yan səthinin sahəsi 15π-dir.\n"
     "3) Silindrin yan səthi konusunkindən 2 dəfə böyükdür.\n"
     "4) Silindrin radiusu 2 dəfə artırılsa (h sabit qalsa), yeni yan səthi 4 dəfə artıb 120π olar.",
     "1, 2 və 3 doğrudur (2π·3·5=30π, π·3·5=15π, 30π/15π=2). 4-cü "
     "mülahizə yanlışdır: yan səthi düsturu 2πrh radiusda XƏTTİDİR - "
     "yalnız r 2 dəfə artanda (h sabit qalanda) sahə də cəmi 2 dəfə "
     "(60π) artır, 4 dəfə yox.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 3"], 2),

    # riy11-firlanma-hecm#2 (silindr r=2,h=3 hecm=12pi) + #21 (r 2x,h
    # sabit -> hecm 4x) + #9 (h 2x,r sabit -> hecm 2x) + #8 (kure r 2x
    # -> hecm 8x) - Python-la yoxlanildi. Tuzaq: 4-cu mulahize HER IKI
    # olcu birlikde 2x olanda hecmin de sade "2 defe" artdigini iddia
    # edir - amma bu vezifelerin HASILIDIR (4x*2x=8x), cemi deyil.
    ("riyaziyyat", "orta", "11", "riy-11-firlanma-hecm",
     "riy11-firlanma-hecm#36", "riy11-firlanma-hecm#comb1",
     "Radiusu 2, hündürlüyü 3 olan silindr verilmişdir (həcmi 12π). Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Radiusu 2 dəfə artırılıb (h sabit qalsa), yeni həcm 48π olar (4 dəfə artıb).\n"
     "2) Hündürlüyü 2 dəfə artırılıb (r sabit qalsa), yeni həcm 24π olar (2 dəfə artıb).\n"
     "3) Eyni radiuslu kürənin radiusu 2 dəfə artırılsa, kürənin həcmi 8 dəfə artar.\n"
     "4) Silindrin radiusu VƏ hündürlüyü hər ikisi 2 dəfə artırılsa, yeni həcm cəmi 2 dəfə artar.",
     "1, 2 və 3 doğrudur (π·4²·3=48π, π·2²·6=24π; kürədə həcm r³-lə "
     "mütənasibdir). 4-cü mülahizə yanlışdır: hər iki ölçü birlikdə "
     "2 dəfə artanda təsirlər HASİL olunur (r-in kvadratik təsiri × "
     "h-in xətti təsiri = 4×2 = 8 dəfə, 96π), cəmlənmir.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # riy11-statistika#15 (P(A)=0.7 -> P(Abar)=0.3) + #16/#18 (asili
    # olmayan hadiselerin birge ehtimali = hasil) + #37
    # (P(A)+P(Abar)=1) - hamisi P(A)=0.6, P(B)=0.5 uzerinde, Python-la
    # yoxlanildi. Tuzaq: 4-cu mulahize BIRGE ehtimali (VƏ) CEMLE
    # (yalniz uyusmayan hadiselerin YA BIRI ucun duz olan qayda) qarisdirir.
    ("riyaziyyat", "orta", "11", "riy-11-statistika",
     "riy11-statistika#32", "riy11-statistika#comb1",
     "A və B asılı olmayan hadisələrdir, P(A) = 0,6 və P(B) = 0,5. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Ā (A-nın əksi) hadisəsinin ehtimalı 0,4-dür.\n"
     "2) A və B-nin birgə baş vermə ehtimalı 0,3-dür.\n"
     "3) Ā və B̄-nin birgə baş verməmə ehtimalı 0,2-dir.\n"
     "4) A və B-nin birgə baş vermə ehtimalı onların cəmi ilə (0,6+0,5=1,1) tapılır.",
     "1, 2 və 3 doğrudur (P(Ā)=0,4; P(A∩B)=0,6·0,5=0,3; P(Ā∩B̄)=0,4·0,5=0,2). "
     "4-cü mülahizə yanlışdır: birgə (VƏ) ehtimalı HASİLLƏ tapılır, "
     "cəmlə yox - üstəlik 1,1 ehtimal üçün mümkün olmayan qiymətdir "
     "(ehtimal 0 ilə 1 arasında olmalıdır).",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # riy11-tenlikler#4/#6/#21 (kvadrata yukselmede kenar kok yaranir,
    # yoxlanmalidir) - konkret misalda: sqrt(x-2)=x-4, kvadrata
    # yukseldib x^2-9x+18=0 (kokler 6 ve 3), Python-la yoxlanildi:
    # x=6 duz (2=2), x=3 kenar (1 != -1). Tuzaq: 3-cu ve 4-cu
    # mulahizeler hansi kokun kenar oldugunu YERINI DEYISIB gosterir.
    ("riyaziyyat", "orta", "11", "riy-11-tenlikler",
     "riy11-tenlikler#22", "riy11-tenlikler#comb1",
     "√(x − 2) = x − 4 tənliyi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Tənliyi kvadrata yüksəltdikdən sonra x² − 9x + 18 = 0 alınır.\n"
     "2) Bu kvadrat tənliyin kökləri x = 6 və x = 3-dür.\n"
     "3) x = 6 əsl tənliyin kökü deyil, kənar kökdür.\n"
     "4) x = 3 əsl tənliyin kökü deyil, kənar kökdür.",
     "1, 2 və 4 doğrudur (x=3-də √1=1, sağ tərəf isə 3−4=−1, uyğun "
     "gəlmir - kənar kök). 3-cü mülahizə yanlışdır: x=6 əslində "
     "DÜZGÜN kökdür (√4=2, sağ tərəf 6−4=2, uyğun gəlir) - hər kvadrat "
     "kök AYRICA yoxlanmalıdır, biri kənar çıxsa digəri də kənar "
     "olmalı deyil.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 3, 4"], 2),

    # az11-fonetika-leksika#9 (esr-esir=paronim) + #21 (bas=coxmenalilik)
    # + #26 (gul=omonim) - uc ayri leksik-semantik kateqoriyanin
    # ferqlendirilmesi. Tuzaq: 2-ci mulahize "bas"-i omonim kimi
    # gosterir (esasen coxmenalilik-dir - eyni sozun ELAQELI menalari),
    # 4-cu mulahize ucunu eyni hadise kimi birlesdirir.
    ("az-dili", "orta", "11", "az-11-fonetika-leksika",
     "az11-fonetika-leksika#13", "az11-fonetika-leksika#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Əsr - əsir» cütü paronimdir.\n"
     "2) «Baş» sözünün «dağın başı», «işin başı» mənaları omonimlikdir.\n"
     "3) «Gül» sözünün (çiçək / gülmək əmri) iki mənası omonimlikdir.\n"
     "4) Paronim, çoxmənalılıq və omonimlik eyni hadisədir - hamısı sözlərin səs baxımından üst-üstə düşməsini bildirir.",
     "1 və 3 doğrudur. 2-ci mülahizə yanlışdır: «baş»ın mənaları "
     "ÇOXMƏNALILIQDIR (eyni sözün əlaqəli mənaları), omonim isə "
     "əlaqəsiz mənalı sözlərdir (məs. «gül»). 4-cü mülahizə yanlışdır: "
     "bu, üç fərqli hadisədir, eyni deyil.",
     ["1, 2", "2, 3, 4", "1, 2, 3", "1, 3"], 4),

    # az11-soz-yaradiciligi#11 (yazici=duzeltme) + #12
    # (gunebaxan=murekkeb) + #5 (-lar qrammatik sekilcidir, soz
    # yaradiciligina aid deyil - yeni leksik mena yaratmir). Tuzaq:
    # 3-cu mulahize EYNI qaydani (qrammatik sekilci novu deyismir)
    # tetbiq edende YANLIS neticeye gelir.
    ("az-dili", "orta", "11", "az-11-soz-yaradiciligi",
     "az11-soz-yaradiciligi#29", "az11-soz-yaradiciligi#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Yazıçı» sözü quruluşca düzəltmə sözdür.\n"
     "2) «Yazıçılar» sözü (yazıçı + -lar) də quruluşca düzəltmə sözdür, çünki -lar şəkilçisi yeni leksik məna yaratmır.\n"
     "3) «Günəbaxanlar» sözü (günəbaxan + -lar) quruluşca artıq mürəkkəb söz deyil, sadə söz olur, çünki -lar əlavə olunub.\n"
     "4) Bir sözün quruluşca növünü (sadə/düzəltmə/mürəkkəb) yalnız leksik (yeni məna yaradan) şəkilçilər müəyyən edir, qrammatik şəkilçilər (cəm, hal və s.) yox.",
     "1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «günəbaxanlar» "
     "da hələ MÜRƏKKƏB sözdür - -lar qrammatik şəkilçisi (4-cü "
     "mülahizənin qaydasına görə) sözün quruluşca növünü dəyişmir, "
     "eynilə «yazıçılar»ın da düzəltmə qalması kimi.",
     ["1, 2, 3", "2, 3, 4", "1, 2, 4", "1, 3, 4"], 3),

    # az11-uslubiyyat#9 (aslan kimi = benzetme) + #3 (metafora=oxsarliga
    # esaslanir) + #4 (zal=metonimiya). Tuzaq: 3-cu mulahize "zal"-i
    # metafora kimi gosterir - esasen elaqeye (metonimiya) esaslanir,
    # oxsarliga yox.
    ("az-dili", "orta", "11", "az-11-uslubiyyat",
     "az11-uslubiyyat#23", "az11-uslubiyyat#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Aslan kimi döyüşdü» ifadəsində bənzətmə (təşbeh) var, çünki «kimi» sözü ilə açıq müqayisə edilir.\n"
     "2) Əgər «kimi» sözü çıxarılıb (əsgəri nəzərdə tutaraq) «Aslan döyüşdü» deyilsəydi, bu artıq metafora olardı, çünki metafora da oxşarlığa əsaslanır, amma gizli müqayisədir.\n"
     "3) «Zalın gurultulu alqışları» ifadəsindəki «zal» sözü də metaforadır, çünki bu da oxşarlığa əsaslanır.\n"
     "4) Bənzətmə və metafora eyni əsasa (oxşarlığa) söykənir, amma bənzətmə açıq müqayisə («kimi»), metafora isə gizli müqayisədir.",
     "1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: «zal» sözü "
     "METONİMİYADIR (zal - orada oturan tamaşaçılar arasındakı ƏLAQƏ, "
     "yəni yerlə insan arasında əlaqə əsasında), oxşarlığa yox.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 3, 4"], 1),

    # az11-metn-tehlili#14 (Baki paytaxtdir=fakt, Baki en gozeldir=serh)
    # + #13 (fakt yoxlanilir, serh subyektivdir) - eyni qaydanin YENI
    # nümunelere tetbiqi. Tuzaq: 4-cu mulahize "sebeb gostermek"-i
    # "yoxlanila bilmek"le qarisdirir - serhe sebeb elave etmek onu
    # fakta cevirmir.
    ("az-dili", "orta", "11", "az-11-metn-tehlili",
     "az11-metn-tehlili#9", "az11-metn-tehlili#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Bakı Azərbaycanın paytaxtıdır» faktdır, çünki yoxlanıla bilər.\n"
     "2) «Bakı dünyanın ən gözəl şəhəridir» şərhdir (rəydir), çünki subyektivdir.\n"
     "3) «Bakının əhalisi 2 milyondan çoxdur» cümləsi də faktdır, çünki bu, yoxlanıla bilən məlumatdır.\n"
     "4) «Bakı ən yaxşı şəhərdir, çünki mən orada doğulmuşam» cümləsi fakt sayılır, çünki səbəb göstərilib.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: bir subyektiv "
     "iddiaya (rəyə) SƏBƏB əlavə etmək onu FAKTA çevirmir - fakt "
     "olmaq üçün müstəqil yoxlanıla bilməlidir, müəllifin şəxsi "
     "əsaslandırması kifayət deyil.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # az11-isguzar#2 (erize unvanla baslayir) + #26/#19 (rasmi qelib,
    # "Xahis edirem...") + #3 (son: tarix+imza) - erize numunesinin
    # butov qurulusu. Tuzaq: 4-cu mulahize emosional/qeyri-rasmi
    # ifadelerin isguzar uslubda meqbul oldugunu iddia edir.
    ("az-dili", "orta", "11", "az-11-isguzar",
     "az11-isguzar#28", "az11-isguzar#comb1",
     "«Direktor cənab X-ə. Xahiş edirəm mənə 3 gün məzuniyyət verəsiniz. Ad-soyad, tarix, imza.» nümunə ərizəsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Bu ərizə düzgün başlayır, çünki ünvanlanan şəxsin adı və vəzifəsi ilə başlayıb.\n"
     "2) «Xahiş edirəm mənə 3 gün məzuniyyət verəsiniz» cümləsi ərizə üçün səciyyəvi rəsmi qəlibdir.\n"
     "3) Ərizənin sonunda tarix və imza olması mütləqdir.\n"
     "4) Ərizə mətnində «Öpürəm, hörmətlə gözləyirəm» kimi isti münasibət ifadə edən sözlərin işlədilməsi işgüzar üslub baxımından məqbuldur.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: işgüzar sənəddə "
     "rəsmi qəliblər qəbul olunub («Xahiş edirəm...»), əzizləmə "
     "formaları («Öpürəm») yox - bu, üslub səhvidir.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # ing11-conversation#1 (I am tired -> was tired) + #17 (saw...
    # yesterday -> had seen...the day before) + #18 (are here now ->
    # were there then) + #6/#7 (imperativ -> to+feil) - reported
    # speech-in BUTUN elementlerinin (zaman+yer+feil formasi) EYNI
    # cümlede birlesdirilmesi. Tuzaq: 4-cu mulahize deiktik
    # (zaman/yer) sozlerin deyismeye ehtiyaci olmadigini iddia edir.
    ("ingilis-dili", "orta", "11", "ing-11-conversation",
     "ing11-conversation#22", "ing11-conversation#comb1",
     "Ali said, \"I am tired now.\" Later he said, \"I saw this film yesterday here.\" His teacher told him, \"Do not be late.\"\n"
     "Which statements are TRUE?\n"
     "1) The reported form of \"I am tired now\" is \"Ali said that he was tired then.\"\n"
     "2) The reported form of \"I saw this film yesterday here\" is \"Ali said he had seen this film the day before there.\"\n"
     "3) The reported form of \"Do not be late\" is \"The teacher told him not to be late.\"\n"
     "4) The reported form of \"I saw this film yesterday here\" could also correctly keep \"yesterday\" and \"here\" unchanged, since the meaning stays clear either way.",
     "1, 2 and 3 are true. Statement 4 is wrong - time and place words "
     "like \"yesterday\"/\"here\" are deictic and MUST shift in reported "
     "speech (to \"the day before\"/\"there\") when the reporting "
     "happens at a different time or place.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # ing11-creativity#1 (was painted = passive) + #4 (had her
    # portrait painted = causative) + #16 (was built = passive) -
    # passive vs causative eyni sethi qelibde (be/have + V3) amma
    # FERQLI menada. Tuzaq: 3-cu mulahize hemin sethi oxsarliga
    # esasen ikisini EYNI struktur elan edir.
    ("ingilis-dili", "orta", "11", "ing-11-creativity",
     "ing11-creativity#19", "ing11-creativity#comb1",
     "Which statements are TRUE?\n"
     "1) \"This picture was painted by a young artist\" is PASSIVE VOICE - the picture itself received the action.\n"
     "2) \"She had her portrait painted last month\" is a CAUSATIVE construction - it means she arranged for someone else to paint it, she did not paint it herself.\n"
     "3) Since both sentences use a past participle after \"be/have\", passive and causative are grammatically the same structure.\n"
     "4) \"The concert hall was built two years ago\" uses passive voice, just like \"This picture was painted by a young artist.\"",
     "1, 2 and 4 are true. Statement 3 is wrong - despite the surface "
     "similarity (a participle after \"be/have\"), passive (\"be + V3\", "
     "subject RECEIVES the action) and causative (\"have + object + "
     "V3\", subject ARRANGES the action) are different structures "
     "with different meanings.",
     ["1, 2, 3", "2, 3, 4", "1, 2, 4", "1, 3, 4"], 3),

    # ing11-news#1 (It is reported that...) + #22 (is reported to have
    # destroyed - perfect infinitiv, tamamlanmis heretket) + #2 (is
    # said to be building - davamedici infinitiv, hele bitmemis
    # heretket) + #9 (is believed to have been damaged). Tuzaq: 4-cu
    # mulahize "to have V3" ve "to be V-ing"-i EYNI zaman elaqesi kimi
    # gosterir.
    ("ingilis-dili", "orta", "11", "ing-11-news",
     "ing11-news#13", "ing11-news#comb1",
     "Which statements are TRUE?\n"
     "1) \"It is reported that the president will visit tomorrow\" and \"The earthquake is reported to have destroyed hundreds of homes\" are both passive reporting structures, but grammatically different: the first uses \"It is reported THAT + clause\", the second uses \"SUBJECT is reported TO HAVE + V3\".\n"
     "2) \"The company is said to be building a new factory\" uses \"to be + V-ing\" because the action is ONGOING.\n"
     "3) \"The bridge is believed to have been damaged in the storm\" uses \"to have been + V3\" because the action happened BEFORE the reporting, i.e. it is already completed.\n"
     "4) Since \"is reported to have destroyed\" and \"is said to be building\" both use a \"to + verb\" pattern, they describe the SAME time relationship.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"to have destroyed\" "
     "(perfect infinitive = COMPLETED action) and \"to be building\" "
     "(continuous infinitive = ONGOING action) express different time "
     "relationships, despite the surface \"to + verb\" similarity.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # ---- besinci dalga (2026-09-03): 10-cu sinif, riy/az dili/ingilis
    # - istifadecinin sorgusu ile eyni qaydada FENN/SINIF UZRE TAM.
    # Riyaziyyat faktlari Python-la eded ile yoxlanildi.

    # riy10-funksiya#10 (x^3 tek) + #35 (1/x tek) + iki tek funksiyanin
    # cemi de tekdir (Python-la yoxlanildi) + tuzaq: tek funksiyaya
    # SABIT elave etmek onu artiq tek etmir (x^3+1 ne tek, ne cutdur).
    ("riyaziyyat", "orta", "10", "riy-10-funksiya",
     "riy10-funksiya#34", "riy10-funksiya#comb1",
     "f(x) = x³ və g(x) = 1/x funksiyaları verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) f(x) = x³ təkdir.\n"
     "2) g(x) = 1/x təkdir.\n"
     "3) h(x) = f(x) + g(x) = x³ + 1/x funksiyası da təkdir, çünki iki tək funksiyanın cəmi yenə təkdir.\n"
     "4) k(x) = x³ + 1 funksiyası da təkdir, çünki tək funksiyaya (x³) sadəcə ədəd əlavə olunub.",
     "1, 2 və 3 doğrudur (h(−x)=−h(x) hər zaman ödənir). 4-cü mülahizə "
     "yanlışdır: k(−x)=−x³+1, bu nə k(x)=x³+1-ə, nə də −k(x)=−x³−1-ə "
     "bərabərdir - sabit əlavə etmək tək funksiyanın simmetriyasını "
     "pozur, k(x) nə cüt, nə təkdir.",
     ["1, 2, 3, 4", "1, 2, 3", "2, 4", "1, 4"], 2),

    # riy10-feza#11 (perp=3,proyeksiya=4->mail=5) + #12 (mail=13,perp=5
    # ->proyeksiya=12) + #14 (beraber mailler -> beraber proyeksiyalar)
    # + #34 (mail perpendikulyardan uzundur) - eyni A noqtesinden iki
    # mail (AH=5 perpendikulyar, HB=HC=12), Python-la yoxlanildi:
    # AB=AC=13. Tuzaq: 4-cu mulahize mailin perpendikulyardan QISA
    # oldugunu iddia edir - #34-un tam eksi.
    ("riyaziyyat", "orta", "10", "riy-10-feza",
     "riy10-feza#30", "riy10-feza#comb1",
     "Nöqtə A-dan müstəviyə perpendikulyar AH = 5 sm-dir (H - əsas). Müstəvi üzərində B və C nöqtələri var, HB = HC = 12 sm. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) AB mailinin uzunluğu 13 sm-dir.\n"
     "2) HB = HC olduğu üçün AC mailinin uzunluğu da 13 sm-dir.\n"
     "3) Bərabər maillərin (AB=AC=13) proyeksiyaları da bərabərdir (HB=HC=12).\n"
     "4) AB mail AH perpendikulyarından qısadır.",
     "1, 2 və 3 doğrudur (Pifaqor: √(5²+12²)=13). 4-cü mülahizə "
     "yanlışdır: mail (13 sm) həmişə perpendikulyardan (5 sm) UZUNDUR, "
     "əksinə deyil - bu, üç perpendikulyar teoreminin əsas nəticəsidir.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # riy10-triq-ifade#12 (sin(90-a)=cosa) + #14 (sin(180-a)=sina) +
    # #16 (sin(-a)=-sina) - a=30 uzerinde, Python-la yoxlanildi:
    # sin(90-30)=cos30=0.866, sin(180-30)=sin30=0.5 - FERQLI qiymetler.
    # Tuzaq: 4-cu mulahize iki oxsar gorunen ifadeni ("sin(...30)")
    # eyni qiymetde gosterir.
    ("riyaziyyat", "orta", "10", "riy-10-triq-ifade",
     "riy10-triq-ifade#27", "riy10-triq-ifade#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) sin(90° − 30°) = cos 30° (çevirmə düsturuna görə).\n"
     "2) sin(180° − 30°) = sin 30° (çevirmə düsturuna görə).\n"
     "3) sin(−30°) = −sin(180° − 30°), çünki hər ikisi −sin 30°-a bərabərdir.\n"
     "4) sin(90° − 30°) və sin(180° − 30°) eyni qiymətdədir, çünki hər ikisi \"sin\"-dən başlayır.",
     "1, 2 və 3 doğrudur (sin(−30°)=−0,5=−sin(180°−30°)=−0,5). 4-cü "
     "mülahizə yanlışdır: sin(90°−30°)=cos30°≈0,866, sin(180°−30°)"
     "=sin30°=0,5 - fərqli qiymətlərdir, çünki fərqli çevirmə "
     "düsturları tətbiq olunur.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # riy10-sinus-kosinus#5 (a=5,b=8,C=60 -> c=7) + #26 (a^2+b^2>c^2 ->
    # C itidir) - Python-la yoxlanildi (89>49, C=60 itidir, uygun).
    # Tuzaq: 4-cu mulahize c-nin YALNIZ a,b-den asili oldugunu iddia
    # edir, C bucaginin rolunu unudur (C=90 olsaydi c=sqrt89=9,43 olardi).
    ("riyaziyyat", "orta", "10", "riy-10-sinus-kosinus",
     "riy10-sinus-kosinus#35", "riy10-sinus-kosinus#comb1",
     "Üçbucaqda a = 5, b = 8, C = 60° verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) c tərəfi 7-yə bərabərdir.\n"
     "2) a² + b² (=89) c²-dən (=49) böyükdür.\n"
     "3) 2-ci mülahizəyə əsasən, C bucağı itidir.\n"
     "4) Əgər C bucağı dəyişib 90° olsaydı (a, b sabit qalsa), c yenə də 7 olardı, çünki c yalnız a və b-dən asılıdır.",
     "1, 2 və 3 doğrudur (kosinuslar teoremi: c²=25+64−2·5·8·0,5=49). "
     "4-cü mülahizə yanlışdır: c bucaq C-dən DƏ asılıdır (−2ab·cosC "
     "həddi) - C=90° olsaydı c²=a²+b²=89, c=√89≈9,43 olardı, 7 yox.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # riy10-triq-qrafik#7 (2sinx amplitud=2) + #8 (sin2x dovru=pi) +
    # #21 (sinx+1 -> 1 vahid yuxari) + #11 (sinx+2 max=3) - y=2sin2x+1
    # uzerinde birlesir, Python-la yoxlanildi (max=2*1+1=3). Tuzaq:
    # 4-cu mulahize eng boyuk qiymeti YALNIZ amplitud kimi gosterir,
    # sürüşdürməni (+1) unudur.
    ("riyaziyyat", "orta", "10", "riy-10-triq-qrafik",
     "riy10-triq-qrafik#33", "riy10-triq-qrafik#comb1",
     "y = 2 sin(2x) + 1 funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Funksiyanın amplitudu 2-dir.\n"
     "2) Funksiyanın ən kiçik müsbət dövrü π-dir (arqumentdəki 2 əmsalına görə).\n"
     "3) Funksiyanın qrafiki y = sin x qrafikinə nisbətən 1 vahid yuxarı sürüşdürülüb.\n"
     "4) Funksiyanın ən böyük qiyməti 2-dir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ən böyük qiymət "
     "amplitud VƏ şaquli sürüşmənin cəmidir (2·1+1=3), amplitudun özü "
     "(2) deyil.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # riy10-coxuzlu#9 (tili5 -> tam saht=150) + #34 (4,4,7 paralele-
    # piped diaqonali=9) - Python-la yoxlanildi. Tuzaq: 4-cu mulahize
    # tili 5 olan KUBUN diaqonalini da 9 elan edir - amma kub xususi
    # paralelepiped kimi 5*sqrt(3)=8,66 verir, 9 yox.
    ("riyaziyyat", "orta", "10", "riy-10-coxuzlu",
     "riy10-coxuzlu#31", "riy10-coxuzlu#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Tili 5 sm olan kubun tam səthinin sahəsi 150 sm²-dir (6·5²).\n"
     "2) Ölçüləri 4, 4 və 7 sm olan paralelepipedin diaqonalı 9 sm-dir (√(4²+4²+7²)).\n"
     "3) Kub da xüsusi paralelepipeddir (bütün ölçülər bərabərdir), buna görə tili 5 olan kubun diaqonalı √(5²+5²+5²)=5√3 sm-dir.\n"
     "4) Tili 5 olan kubun diaqonalı da 9 sm-dir, çünki bütün paralelepipedlərin diaqonalı ölçülərdən asılı olmayaraq eynidir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: diaqonal ölçülərdən "
     "birbaşa asılıdır (düstur bunu göstərir) - tili 5 olan kubun "
     "diaqonalı 5√3≈8,66 sm-dir, 9 sm deyil (9 yalnız 4,4,7 ölçülü "
     "fərqli paralelepiped üçündür).",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # riy10-triq-tenlik#2 (arcsin(1/2)=pi/6) + #3 (arccos(1/2)=pi/3) +
    # #23 (arcsin(-a)=-arcsin a) - Python-la yoxlanildi. Tuzaq: 4-cu
    # mulahize arccos-un da HEM QAYDANI (mence teq) izlediyini iddia
    # edir - amma arccos(-a)=pi-arccos a-dir (#24), arcsin-in "eksini
    # goturme" qaydasindan FERQLIDIR.
    ("riyaziyyat", "orta", "10", "riy-10-triq-tenlik",
     "riy10-triq-tenlik#33", "riy10-triq-tenlik#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) arcsin(1/2) = π/6-dır.\n"
     "2) arcsin(−1/2) = −π/6-dır (çünki arcsin(−a) = −arcsin a).\n"
     "3) arccos(1/2) = π/3-dür.\n"
     "4) arccos(−1/2) = −π/3-dür, çünki arccos da arcsin kimi eyni \"əksini götür\" qaydasını izləyir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: arccos FƏRQLİ "
     "qaydaya tabedir - arccos(−a) = π − arccos(a), yəni "
     "arccos(−1/2) = π − π/3 = 2π/3, −π/3 deyil.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # riy10-hecm#14 (akvarium 40,30,50 -> 60 litr) + #10 (xetti olculer
    # 2x -> hecm 8x) - Python-la yoxlanildi (60->480, nisbet=8). Tuzaq:
    # 4-cu mulahize butun olculer 2x olanda hecmin CEMI 2 defe artdigini
    # iddia edir (xetti fikirlesme, kubik yerine).
    ("riyaziyyat", "orta", "10", "riy-10-hecm",
     "riy10-hecm#31", "riy10-hecm#comb1",
     "Ölçüləri 40, 30 və 50 sm olan akvariumun tutumu 60 litrdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Bütün ölçüləri 2 dəfə böyüdülmüş oxşar akvariumun (80,60,100 sm) tutumu 480 litr olar.\n"
     "2) Bu, birbaşa hesabla da yoxlanıla bilər: 80·60·100=480000 sm³=480 L.\n"
     "3) Nəticə xətti ölçülərin 2 dəfə artması qaydasına uyğundur (həcm 8 dəfə artır).\n"
     "4) Bütün ölçüləri 2 dəfə böyüdülmüş akvariumun tutumu 120 litr olar, çünki hər ölçü 2 dəfə artıb, tutum da cəmi 2 dəfə artır.",
     "1, 2 və 3 doğrudur (40·30·50=60000, 80·60·100=480000, nisbət=8). "
     "4-cü mülahizə yanlışdır: hər 3 ölçü birlikdə 2 dəfə artanda həcm "
     "2³=8 dəfə (xətti yox, KUBİK) artır, cəmi 2 dəfə yox.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # riy10-ustlu-loqarifm#8 (log2 8=3) + #11 (log2 32=5) + #22 (log2
    # x=5 -> x=32, #11-in tersi) + #30 (4^x=2 -> x=1/2). Tuzaq: 4-cu
    # mulahize 4^x=2-nin kokunu x=2 kimi gosterir (4=2*2-i sehv seklde
    # tetbiq edir), duz cavab 1/2-dir.
    ("riyaziyyat", "orta", "10", "riy-10-ustlu-loqarifm",
     "riy10-ustlu-loqarifm#33", "riy10-ustlu-loqarifm#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) log₂ 8 = 3 (çünki 2³=8).\n"
     "2) log₂ 32 = 5 (çünki 2⁵=32).\n"
     "3) log₂ x = 5 tənliyinin kökü x=32-dir (2-ci mülahizənin tərs əməliyyatıdır).\n"
     "4) 4ˣ = 2 tənliyinin kökü x=2-dir, çünki 4=2·2 münasibətinə görə 2 dəfə vurmaq lazımdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 4ˣ=2 → (2²)ˣ=2¹ → "
     "2x=1 → x=1/2-dir, 2 deyil - «4=2·2» münasibəti tənliyin həllinə "
     "birbaşa tətbiq edilə bilməz.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # riy10-statistika#12 (sikke 3 defe, 2 defe gerb=3/8, Bernulli) +
    # #21 (Bernulli dusturu) - Python-la yoxlanildi (k=2->0,375,
    # k=3->0,125). Tuzaq: 4-cu mulahize 3/8-i 1/8-den KICIK gosterir
    # ve "daha cox ugur = daha az ehtimal" umumilesdirmesini edir -
    # amma 3/8>1/8, ve k=2 elinde n=3,p=0,5 ucun MOD-dur.
    ("riyaziyyat", "orta", "10", "riy-10-statistika",
     "riy10-statistika#33", "riy10-statistika#comb1",
     "Simmetrik sikkə 3 dəfə atılır (uğur=gerb, p=1/2). Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Bernulli düsturuna görə, düz 2 dəfə gerb düşmə ehtimalı P=C(3,2)·(1/2)²·(1/2)¹ şəklində hesablanır.\n"
     "2) C(3,2)=3 olduğu üçün, bu ehtimal P=3/8-dir.\n"
     "3) Hər 3-də də gerb düşmə ehtimalı C(3,3)·(1/2)³·(1/2)⁰=1/8-dir.\n"
     "4) 3/8 ehtimalı 1/8-dən kiçikdir, çünki daha çox uğur əldə etmək həmişə daha az ehtimallıdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 3/8 (0,375) əslində "
     "1/8-dən (0,125) BÖYÜKDÜR - «daha çox uğur həmişə daha az "
     "ehtimallıdır» ümumiləşdirməsi yanlışdır, burada 2 uğur (k=2) elə "
     "ən ehtimallı nəticədir.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # az10-dil-unsiyyet#2 (Az dili turk qrupu) + #10 (dil=sistem,
    # nitq=tetbiq) + #22 (edebi dil - normalara tabe) + #21 (dialekt -
    # bolgeye xas yerli qol). Tuzaq: 4-cu mulahize edebi dil ve
    # dialekti EYNI sey elan edir - #21/#22-nin oz teriflerinin
    # birbasa ziddir.
    ("az-dili", "orta", "10", "az-10-dil-unsiyyet",
     "az10-dil-unsiyyet#10", "az10-dil-unsiyyet#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Azərbaycan dili mənşəyinə görə türk dilləri qrupuna daxildir.\n"
     "2) Dil sistemdir, nitq onun tətbiqidir - bu, dil ilə nitq arasındakı fərqdir.\n"
     "3) Ədəbi dil normalara tabe olan ümumxalq dili formasıdır, dialekt isə müəyyən bölgəyə xas yerli qoldur.\n"
     "4) Dialekt ədəbi dilin başqa adıdır, ikisi eyni şeyi bildirir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ədəbi dil (normativ, "
     "ümumxalq) və dialekt (yerli, qeyri-normativ) iki FƏRQLİ formadır, "
     "eyni şey deyil.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # az10-fonetika-tekrar#4 (alma/alma - vurgu yeri) + #16 (ton/don -
    # ilk samitin kar-cingiltili olmasi) + #6 (kitab[kitap] - sozson
    # cingiltili karlasma). Tuzaq: 3-cu mulahize iki FERQLI fonetik
    # mexanizmi (vurgu vs kar-cingiltili) EYNI elan edir.
    ("az-dili", "orta", "10", "az-10-fonetika-tekrar",
     "az10-fonetika-tekrar#29", "az10-fonetika-tekrar#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Alma» (meyvə) ilə «alma» (əmr) sözlərini tələffüzdə vurğunun yeri fərqləndirir.\n"
     "2) «Ton» ilə «don» sözlərini isə vurğu yox, ilk samitin kar-cingiltili olması fərqləndirir.\n"
     "3) Bu iki cüt söz eyni fonetik mexanizmlə (vurğu ilə) fərqlənir.\n"
     "4) «Kitab» sözü [kitap] kimi tələffüz olunur, çünki söz sonunda cingiltili samit karlaşır.",
     "1, 2 və 4 doğrudur. 3-cü mülahizə yanlışdır: bu iki cüt söz "
     "FƏRQLİ mexanizmlərlə fərqlənir - «alma/alma» vurğu ilə, «ton/don» "
     "isə samitin kar-cingiltili olması ilə.",
     ["1, 2, 3", "2, 3, 4", "1, 2, 4", "1, 3, 4"], 3),

    # az10-leksika#1/#2 (qizil uzuk=heqiqi, qizil urek=mecazi, EYNI soz
    # ELAQELI menalar) + #18 (coxmenali vs omonim - elaqeye gore
    # ferqlendirme) + #4 (bal/bal=omonim, ELAQESIZ menalar). Tuzaq:
    # 4-cu mulahize "bal/bal"-i da coxmenali elan edir - #4-un birbasa
    # eksi (o, omonimdir).
    ("az-dili", "orta", "10", "az-10-leksika",
     "az10-leksika#16", "az10-leksika#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Qızıl üzük» birləşməsində «qızıl» sözü həqiqi mənada işlənib.\n"
     "2) «Qızıl ürək» birləşməsində isə «qızıl» sözü məcazi mənadadır.\n"
     "3) Bu iki məna (üzük/ürək) əlaqəlidir (hər ikisi «dəyərli» ideyasından qaynaqlanır), buna görə bu, ÇOXMƏNALILIQ nümunəsidir, omonimlik deyil.\n"
     "4) «Bal» (şirin qida) və «bal» (rəqs gecəsi) sözləri də eyni səbəbdən çoxmənalılığa misaldır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «bal/bal»-ın iki "
     "mənası ƏLAQƏSİZDİR - bu, OMONİMLİKDİR, çoxmənalılıq deyil.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # az10-uslub#5 (erize/protokol - resmi-isguzar) + #15 (nagil/dastan
    # - bedii) + #14 (resmi senedde "opurem" yolverilmez). Tuzaq: 4-cu
    # mulahize uslublarin bir-birini evez ede biləcəyini iddia edir.
    ("az-dili", "orta", "10", "az-10-uslub",
     "az10-uslub#24", "az10-uslub#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Ərizə, protokol, arayış rəsmi-işgüzar üslubda yazılır.\n"
     "2) Nağıl və dastanlar isə bədii üslubun nümunəsidir.\n"
     "3) Rəsmi sənəddə «görüşənədək, öpürəm» kimi ifadələr yazmaq üslub uyğunsuzluğu yaradır, çünki bu, məişət üslubuna aiddir.\n"
     "4) Nağıl mətnində rəsmi-işgüzar üslubun leksik vasitələrindən istifadə etmək də normal sayılır, çünki bütün üslublar bir-birini əvəz edə bilər.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: üslublar bir-birini "
     "əvəz etmir - bədii mətndə rəsmi-işgüzar leksika işlətmək də, "
     "rəsmi sənəddə məişət ifadəsi işlətmək qədər uyğunsuzdur.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # az10-morfologiya-t#16 (oxuyan=feili sifet) + #17 (gelende=feili
    # baglama) - eyni cumlede birlesir. Tuzaq: 4-cu mulahize hər ikisinin
    # feilden duzelmesini eyni FORMA olmaqla qarisdirir.
    ("az-dili", "orta", "10", "az-10-morfologiya-t",
     "az10-morfologiya-t#28", "az10-morfologiya-t#comb1",
     "«Oxuyan şagird kitabı gələndə gətirdi» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Oxuyan» feili sifətdir (şagirdin əlamətini bildirir).\n"
     "2) «Gələndə» feili bağlamadır (əsas hərəkətin zamanını bildirir).\n"
     "3) Hər ikisi feildən əmələ gəlib, amma «oxuyan» isim üçün TƏYİN, «gələndə» isə ZƏRFLİK vəzifəsindədir.\n"
     "4) «Oxuyan» sözü də «gələndə» kimi feili bağlamadır, çünki hər ikisi feildən düzəlib.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: eyni köklə (feillə) "
     "bağlı olmaq eyni FORMA olmaq demək deyil - «oxuyan» feili "
     "SİFƏTDİR, feili bağlama yox.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # az10-sintaksis-t#6 (qirmizi=teyin) + #5 (qardasima=tamamliq) +
    # #7 (heyetde=zerflik) - eyni yeni cumlede birlesir. Tuzaq: 4-cu
    # mulahize "almani"-ni ilk isim oldugu ucun mubteda elan edir -
    # ferqin (hal sekilcisi vs sira) qarisdirilmasi.
    ("az-dili", "orta", "10", "az-10-sintaksis-t",
     "az10-sintaksis-t#28", "az10-sintaksis-t#comb1",
     "«Qırmızı almanı qardaşıma bağçada verdim» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Qırmızı» təyindir.\n"
     "2) «Qardaşıma» tamamlıqdır.\n"
     "3) «Bağçada» yer zərfliyidir.\n"
     "4) «Almanı» sözü mübtədadır, çünki cümlədə əşya kimi ilk qeyd olunan isimdir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «almanı» sözü "
     "tamamlıqdır (təsirlik hal şəkilçisi -nı ilə) - cümlədə İLK "
     "qeyd olunması onu mübtəda etmir, hal şəkilçisi onun üzvünü "
     "müəyyən edir.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # az10-metn#2 (giris-esas-netice) + #26 (esas hissede - movzunun
    # genis aciqlanmasi) + #27 (netice hissesinde - fikrin umumilesdi-
    # rilmesi) + #20 (evvelce/sonra/nehayet - ardicilliq). Tuzaq: 4-cu
    # mulahize bu baglayicilari "yeni movzu baslanmasi" kimi oxuyur.
    ("az-dili", "orta", "10", "az-10-metn",
     "az10-metn#29", "az10-metn#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Mətnin klassik quruluşu giriş, əsas hissə və nəticədən ibarətdir.\n"
     "2) Əsas hissədə mövzunun geniş açıqlanması yerləşir.\n"
     "3) Nəticə hissəsində isə fikrin ümumiləşdirilməsi olur, yeni mövzu başlanmır.\n"
     "4) «Əvvəlcə, sonra, nəhayət» sözləri nəticə hissəsində yeni mövzunun başlandığını göstərən əlamətdir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «əvvəlcə, sonra, "
     "nəhayət» ARDICILLIĞI göstərir, yeni mövzunun başlanmasını yox - "
     "üstəlik nəticə hissəsində yeni mövzu ümumiyyətlə başlanmamalıdır.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # az10-nitq-medeni#12 (tufeyli sozler=zeif nitq) + #22 (pauzalar=
    # fikri toplamaga xidmet edir, faydalidir). Tuzaq: 4-cu mulahize
    # ikisini EYNI funksiyali elan edir - amma biri qusur, digeri
    # faydali vasitedir.
    ("az-dili", "orta", "10", "az-10-nitq-medeni",
     "az10-nitq-medeni#27", "az10-nitq-medeni#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Deməli, yəni, zad» kimi sözlərin tez-tez təkrarı zəif nitqin (tüfeyli sözlərin) əlamətidir.\n"
     "2) Nitq zamanı pauzalar isə fikri ayırıb diqqəti cəmləməyə xidmət edir - faydalı vasitədir.\n"
     "3) Deməli, natiq fikrini toplamaq üçün pauza verməklə tüfeyli söz işlətməkdən daha yaxşı edər.\n"
     "4) Tüfeyli sözlər və pauzalar eyni funksiyanı daşıyır - ikisi arasında fərq yoxdur.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: hər ikisi natiqin "
     "fikrini toplaması üçün vaxt qazandırsa da, tüfeyli sözlər ZƏİF "
     "nitqin, pauzalar isə FAYDALI bir vasitənin əlamətidir.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # ing10-kindness#3 (man who helped) + #4 (town where I was born) +
    # #27 (reason why she helps). Tuzaq: 4-cu mulahize "which"-i UMUMI
    # evezedici kimi gosterir - amma which yalniz seyler ucundur.
    ("ingilis-dili", "orta", "10", "ing-10-kindness",
     "ing10-kindness#19", "ing10-kindness#comb1",
     "Which statements are TRUE?\n"
     "1) \"who\" is used because \"man\" is a person, as in \"The man who helped me carry the bags.\"\n"
     "2) \"where\" is used because \"town\" is a place, as in \"This is the town where I was born.\"\n"
     "3) \"why\" is used because \"reason\" needs a reason-relative-pronoun, as in \"The reason why she helps others.\"\n"
     "4) All three relative pronouns (who, where, why) could be replaced by \"which\" without changing correctness, since \"which\" is the general-purpose relative pronoun for everything.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"which\" is "
     "specifically used for THINGS, not people, places, or reasons - "
     "replacing \"who\"/\"where\"/\"why\" with \"which\" would be "
     "ungrammatical.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # ing10-victory#4 (because+clause) + #7 (because of+noun) + #15
    # (although=contrast). Tuzaq: 4-cu mulahize "because" ve "because
    # of"-u qarisiq isledile bileceyini iddia edir.
    ("ingilis-dili", "orta", "10", "ing-10-victory",
     "ing10-victory#18", "ing10-victory#comb1",
     "Which statements are TRUE?\n"
     "1) \"We stayed at home because it was raining heavily\" uses \"because\" + a clause (subject+verb).\n"
     "2) \"The roads were closed because of the heavy snow\" uses \"because of\" + a noun phrase, not a clause.\n"
     "3) \"Although he was tired, he continued the mission\" uses \"although\" to show CONTRAST, not cause.\n"
     "4) \"Because\" and \"because of\" can be used interchangeably in both sentences above, since they mean the same thing.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"because\" needs a "
     "clause and \"because of\" needs a noun phrase; swapping them "
     "makes the sentence ungrammatical, even though they express a "
     "similar idea.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # ing10-cultures#7 (Despite+noun) + #22 (Despite+gerund) + #19
    # (Even though+clause). Tuzaq: 4-cu mulahize despite ve even
    # though-u her yerde evezlene bilen elan edir.
    ("ingilis-dili", "orta", "10", "ing-10-cultures",
     "ing10-cultures#14", "ing10-cultures#comb1",
     "Which statements are TRUE?\n"
     "1) \"Despite the rain, the open-air concert continued\" uses \"despite\" + a noun phrase.\n"
     "2) \"Despite being far away, she joined the family holiday online\" uses \"despite\" + a gerund phrase.\n"
     "3) \"Even though he lives abroad, he keeps his traditions\" uses \"even though\" + a full clause (subject+verb).\n"
     "4) \"Despite\" and \"Even though\" are grammatically interchangeable everywhere, since \"despite he lives abroad\" would also be correct.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"despite\" cannot "
     "be directly followed by a clause with subject+verb (\"despite "
     "he lives abroad\" is ungrammatical); only \"even though\" can.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # ing10-environment#16 (have finished - Present Perfect Simple,
    # completed) + #19 (has been raining - Present Perfect Continuous,
    # ongoing) + #9 (Past Simple vs Present Perfect umumi ferqi).
    # Tuzaq: 4-cu mulahize ikisini EYNI mena elan edir.
    ("ingilis-dili", "orta", "10", "ing-10-environment",
     "ing10-environment#28", "ing10-environment#comb1",
     "Which statements are TRUE?\n"
     "1) \"I have finished my homework already\" uses Present Perfect Simple, emphasising a COMPLETED action with a present result.\n"
     "2) \"It has been raining since Monday\" uses Present Perfect Continuous, emphasising the ONGOING duration of the action.\n"
     "3) Both sentences connect a past action to the present moment, unlike Past Simple, which only describes a finished past action.\n"
     "4) Since both are Present Perfect forms, \"have finished\" and \"has been raining\" mean exactly the same thing: a completed action with no ongoing process.",
     "1, 2 and 3 are true. Statement 4 is wrong - Present Perfect "
     "Simple (completion) and Present Perfect Continuous (ongoing "
     "duration) express different meanings, despite both being "
     "\"Present Perfect\".",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # ing10-success#3 (had read - past perfect before exam) + #25 (had
    # completed - before finding job) + #5 (had been built - past
    # perfect passive). Tuzaq: 4-cu mulahize hamisini sade kecmisle
    # evezlenebilen elan edir, menanin itdiyini gormur.
    ("ingilis-dili", "orta", "10", "ing-10-success",
     "ing10-success#17", "ing10-success#comb1",
     "Which statements are TRUE?\n"
     "1) \"She said she had read the book before the exam\" uses Past Perfect because the reading happened before another past point.\n"
     "2) \"After she had completed the course, she found a good job\" also uses Past Perfect, because completing came before finding the job.\n"
     "3) \"The bridge had been built by 1950\" uses Past Perfect Passive, showing completion before a past deadline.\n"
     "4) In all three sentences, \"had + V3\" could be replaced by Simple Past forms without any change in meaning.",
     "1, 2 and 3 are true. Statement 4 is wrong - Past Perfect "
     "specifically marks which of two past events happened FIRST; "
     "replacing it with Simple Past loses that clear sequencing.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # ing10-media#3 (reported statement: was) + #6 (reported command:
    # to be) + #7 (reported yes/no question: if). Tuzaq: 4-cu mulahize
    # uc reported-speech novunun HAMISININ eyni qelibde oldugunu iddia
    # edir.
    ("ingilis-dili", "orta", "10", "ing-10-media",
     "ing10-media#28", "ing10-media#comb1",
     "Which statements are TRUE?\n"
     "1) \"She said that she was tired\" reports a STATEMENT, using backshift (is → was).\n"
     "2) \"The teacher asked us to be quiet\" reports a COMMAND, using the infinitive form (\"to be\").\n"
     "3) \"Mum asked me if I had done my homework\" reports a YES/NO QUESTION, using \"if\" instead of a question word.\n"
     "4) Since all three sentence types (statement, command, question) are being \"reported\", they all use the same grammatical pattern (\"asked/told/said + that + clause\").",
     "1, 2 and 3 are true. Statement 4 is wrong - reported statements "
     "use \"said/told that + clause\", reported commands use \"told/"
     "asked + object + infinitive\" (no \"that\"), and reported "
     "yes/no questions use \"asked + if/whether + clause\" - three "
     "different patterns, not one.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # ============================================================
    # ALTINCI DALGA (2026-09-03): 9-cu sinif - V2 STANDARTLA (bax
    # basliqdaki "V2 STANDART"). Her bend ucun oz-ozune audit serhi
    # (Cetinlik/Sebeb/Addimlar/Derslikden kenar?/Ezberle?) elave
    # olunub. Riyaziyyat faktlarinin hamisi Python-la eded ile
    # yoxlanildi (ayrica komandalarla, bu sessiyada).
    # ============================================================

    # Cetinlik: 6/10
    # Sebeb: iki koku ayri sadelesdirmek, neticeleri toplamaq, sonra
    #   bunu sehv "kok cemi" qaydasi ile mueqayise etmek.
    # Addimlar: 1 -> 2 -> 3 (1,2-nin neticesini toplayir) -> 4 (3-un
    #   neticesi ile ziddiyyet)
    # Derslikden kenar bilik? Xeyr (riy9-kok#14/#16-nin eyni qaydasi)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-kok",
     "riy9-kok#18", "riy9-kok#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) √12 sadələşəndə 2√3 alınır (√12=√(4·3)=2√3).\n"
     "2) √27 sadələşəndə 3√3 alınır (eyni üsulla, fərqli ədədlə: √27=√(9·3)=3√3).\n"
     "3) Bu iki nəticəni toplasaq, √12+√27=2√3+3√3=5√3 alınır.\n"
     "4) Eyni cəmi kökləri əvvəlcə toplayıb (12+27=39), sonra kökünü alaraq (√39) da tapmaq olar - bu da 5√3-ə bərabər nəticə verər.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: √a+√b ≠ √(a+b) - "
     "√39≈6,24, 5√3≈8,66, fərqli ədədlərdir. Kökləri əvvəlcə toplayıb "
     "sonra kök almaq səhv üsuldur.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 6/10
    # Sebeb: cevrenin uzunlugundan radiusu tapmaq, sonra radiusla qovs
    #   uzunlugunu, sonra hemin qovsden daxile cekilmis bucagi tapmaq.
    # Addimlar: 1 -> 2 (1-in radiusunu istifade edir) -> 3 (qovsun
    #   dereceesini istifade edir) -> 4 (xetti/xetti-olmayan qarisdirma)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-cevre",
     "riy9-cevre#38", "riy9-cevre#comb1",
     "Çevrənin uzunluğu 20π sm-dir, bu çevrədə 72°-lik qövs verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Çevrənin radiusu 10 sm-dir (uzunluq=2πr, 20π=2πr → r=10).\n"
     "2) 1-ci addımdakı radiusu l=πrα/180 düsturuna yazsaq, 72°-lik qövsün uzunluğu l=4π sm olar.\n"
     "3) Bu 72°-lik qövsə söykənən daxilə çəkilmiş bucaq 36°-dir (daxilə çəkilmiş bucaq=qövsün yarısı).\n"
     "4) Əgər qövs 72°-dən 144°-yə (2 dəfə) böyüsə, ona söykənən daxilə çəkilmiş bucaq da 2 dəfə artar, qövsün uzunluğu isə 4 dəfə artar.",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə "
     "yanlışdır: qövs uzunluğu düsturu (l=πrα/180) α-da XƏTTİDİR - "
     "qövs 2 dəfə artanda uzunluq da CƏMİ 2 dəfə (4 dəfə yox) artır, "
     "eynilə daxilə çəkilmiş bucaq kimi.",
     ["1, 2, 3, 4", "2, 3, 4", "1, 3", "1, 2, 3"], 4),

    # Cetinlik: 6/10
    # Sebeb: simmetriya oxu ve sifirlar ayri hesablanir, sonra
    #   aralarindaki ORTA NOQTE elaqesi qurulur, tepe noqtesinin
    #   ordinati ile qarisdirilma yoxlanilir.
    # Addimlar: 1,2 (paralel) -> 3 (1 ve 2-nin BIRGE neticesi) -> 4
    #   (yanlis umumilesme)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-funksiya",
     "riy9-funksiya#37", "riy9-funksiya#comb1",
     "y = x² − 6x + 5 funksiyası verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Funksiyanın simmetriya oxu x=3-dür (x=−b/2a=6/2=3).\n"
     "2) Funksiyanın sıfırları x=1 və x=5-dir.\n"
     "3) 1-ci və 2-ci mülahizələrə əsasən, simmetriya oxu iki sıfırın dəqiq orta nöqtəsindən keçir ((1+5)/2=3).\n"
     "4) Funksiyanın təpə nöqtəsinin ordinatı (y qiyməti) sıfırdır, çünki təpə simmetriya oxu üzərindədir.",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı: f(1)=f(5)=0, "
     "midpoint=3). 4-cü mülahizə yanlışdır: təpə nöqtəsi simmetriya "
     "oxu ÜZƏRİNDƏDİR (x=3), amma bu, absis oxunu (y=0) kəsdiyi demək "
     "deyil - f(3)=−4-dür, sıfır yox.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: nöqtenin baslangicdan mesafesini tapmaq, bunu radius kimi
    #   tetbiq etmek, sonra hemin radiusla cos/sin-i hesablamaq.
    # Addimlar: 1 -> 2 (1-in neticesini radius kimi istifade edir) ->
    #   3 (2-nin cevresi ustunde cos/sin) -> 4 (yanlis eded kopyalama)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-cevre-tenliyi",
     "riy9-cevre-tenliyi#35", "riy9-cevre-tenliyi#comb1",
     "M(9; 12) nöqtəsi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) M-in başlanğıcdan uzaqlığı 15 vahiddir (9²+12²=225=15²).\n"
     "2) 1-ci addıma əsasən, M nöqtəsi mərkəzi başlanğıcda, radiusu 15 olan çevrənin (x²+y²=225) üzərindədir.\n"
     "3) Bu çevrədə M-ə uyğun bucaq üçün cos α=9/15=0,6, sin α=12/15=0,8-dir.\n"
     "4) cos α=0,6 olduğu üçün, cos²α=0,64-dür (#24-dəki eyni ədədi nəticəni tətbiq edərək).",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə "
     "yanlışdır: cos²α=0,6²=0,36-dır - 0,64 fərqli bir bank sualında "
     "(sin α=0,6 verildikdə) alınan cavabdır, birbaşa köçürülə bilməz.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 6/10
    # Sebeb: bikvadrat tenlikde evezleme aparmaq, kvadrat tenliyi
    #   həll etmek, t qiymetlerini geri x^2-e qaytarmaq.
    # Addimlar: 1 -> 2 (evezleme) -> 3 (2-nin t qiymetlerini istifade
    #   edir) -> 4 (koklerin cemi - is+/- cutlerin legvi unudulur)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-tenlikler",
     "riy9-tenlikler#39", "riy9-tenlikler#comb1",
     "x⁴ − 5x² + 4 = 0 tənliyi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Bu, bikvadrat tənlikdir (yalnız cüt qüvvətlər iştirak edir).\n"
     "2) t=x² əvəzləməsi aparsaq, t²−5t+4=0 tənliyi alınır ki, bu da (t−1)(t−4)=0 kimi vuruqlara ayrılır - deməli t=1 və ya t=4.\n"
     "3) 2-ci addımdakı t qiymətlərini geri x²-ə qaytarsaq (x²=1 və x²=4), tənliyin kökləri x=±1 və x=±2 olur.\n"
     "4) Tənliyin bütün köklərinin (±1, ±2) cəmi 6-dır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ±1 və ±2-nin cəmi "
     "1−1+2−2=0-dır, 6 yox - simmetrik köklər (+ və −) bir-birini "
     "ləğv edir.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # Cetinlik: 6/10
    # Sebeb: tereфi 6 olan kvadratin daxili radiusunu, sonra diaqonalini,
    #   sonra diaqonaldan xarici radiusunu tapmaq - hersey ARDICIL.
    # Addimlar: 1 (mueqim) -> 2 (mueqim) -> 3 (2-nin diaqonalini
    #   istifade edir) -> 4 (nisbet sehvi - koke gore deyisir)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-coxbucaqli",
     "riy9-coxbucaqli#39", "riy9-coxbucaqli#comb1",
     "Tərəfi 6 sm olan kvadrat verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Kvadratın daxilinə çəkilmiş çevrənin radiusu 3 sm-dir (radius=tərəf/2).\n"
     "2) Kvadratın diaqonalı 6√2 sm-dir (Pifaqor: √(6²+6²)=6√2).\n"
     "3) 2-ci addımdakı diaqonaldan istifadə etsək, xaricinə çəkilmiş çevrənin radiusu 3√2 sm olur (radius=diaqonal/2).\n"
     "4) Xarici çevrənin radiusu daxili çevrənin radiusundan 2 dəfə böyükdür.",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə "
     "yanlışdır: 3√2/3=√2≈1,41-dir, 2 dəfə yox - bu nisbət hər "
     "kvadratda √2-dir (2 deyil).",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: kokleri tapmaq, aralig-usulunu tetbiq etmek, sonra STRICT
    #   berabersizlikde uc noqtelerin daxil olub-olmadigini yoxlamaq.
    # Addimlar: 1 -> 2 (1-in koklerini istifade edir) -> 3 (2-nin
    #   aralьgini istifade edir) -> 4 (uc noqte sehven daxil edilir)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-berabersizlik",
     "riy9-berabersizlik#39", "riy9-berabersizlik#comb1",
     "(x−2)(x−6)<0 bərabərsizliyi verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Uyğun tənliyin kökləri x=2 və x=6-dır.\n"
     "2) Bu köklərə əsasən, (x−2)(x−6) ifadəsi 2<x<6 aralığında mənfi, xaricində isə müsbətdir.\n"
     "3) Deməli (x−2)(x−6)<0 bərabərsizliyinin həlli 2<x<6 aralığıdır (uc nöqtələr daxil deyil).\n"
     "4) Bu aralığa (x=2 daxil olmaqla) düşən tam ədədlərin sayı 4-dür (2, 3, 4, 5).",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə "
     "yanlışdır: x=2-də ifadə sıfırdır (mənfi deyil), buna görə strict "
     "bərabərsizliyin həllinə daxil olmur - düz say 3-dür (3, 4, 5).",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: vektorlarin cemini tapmaq, hemin cemin modulunu hesablamaq,
    #   perpendikulyarlik faktini elave etmek, sonra oxsar gorunuslu
    #   AMMA FERQLI vektorla qarisdirmani yoxlamaq.
    # Addimlar: 1 -> 2 (1-in koordinatlarini istifade edir) -> 3
    #   (paralel fakt) -> 4 (1-in neticesi ile fərqli bank faktinin
    #   qarisdirilmasi)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-vektorlar",
     "riy9-vektorlar#40", "riy9-vektorlar#comb1",
     "a(1; 3) və b(2; −1) vektorları verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) a+b cəminin koordinatları (3; 2)-dir.\n"
     "2) 1-ci addımdakı nəticəyə əsasən, |a+b|=√(3²+2²)=√13-dür.\n"
     "3) Əgər a və b vektorları perpendikulyar olsaydı, |a+b|²=|a|²+|b|² olardı.\n"
     "4) 1-ci addımdakı (3; 2) vektorunun modulu 5-dir, çünki (3; 4) vektorunun modulu 5 olduğu kimi bu da eynidir.",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı: |a+b|=√13≈3,6). 4-cü "
     "mülahizə yanlışdır: (3; 2) vektoru (3; 4) vektorundan FƏRQLİDİR "
     "- modulu √13-dür, 5 yox, sadəcə ikisinin ilk koordinatı eyni "
     "olduğu üçün qarışdırılmamalıdır.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: ferqi tapmaq, geriye hesablayaraq ilk heddi tapmaq, sonra
    #   cemi hesablamaq - hersey ARDICIL bir-birinin ustunde qurulur.
    # Addimlar: 1 -> 2 (1-in ferqini istifade edir) -> 3 (2-nin a1-ini
    #   istifade edir) -> 4 (yanlis umumilesme - isaret)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-silsile",
     "riy9-silsile#37", "riy9-silsile#comb1",
     "Ədədi silsilədə a₅=20 və a₆=26-dır. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Silsilənin fərqi d=6-dır (a₆−a₅=26−20=6).\n"
     "2) 1-ci addımdakı fərqdən istifadə edib geriyə hesablasaq, a₁=a₅−4d=20−24=−4 olur.\n"
     "3) 2-ci addımdakı a₁ və d dəyərləri ilə Sₙ=n/2·(2a₁+(n−1)d) düsturuna əsasən, ilk 10 həddin cəmi S₁₀=230-dur.\n"
     "4) Silsilənin ilk həddi (a₁=−4) mənfi olduğu üçün, bütün hədləri mənfidir.",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı: d=6, a₁=−4, S₁₀=230). "
     "4-cü mülahizə yanlışdır: d=6>0 olduğu üçün hədlər artır - a₅=20 "
     "artıq müsbətdir, ilk həddin mənfi olması bütün hədlərin mənfi "
     "olması demək deyil.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: umumi seciim sayini (C) tapmaq, elverisli seciimleri
    #   tapmaq, klassik ehtimal duesturunu tetbiq etmek, sonra
    #   komanda olcusu deyisende nisbetin DEYISDIYINI yoxlamaq.
    # Addimlar: 1 -> 2 -> 3 (1 ve 2-nin neticesini nisbetlendirir) ->
    #   4 (yanlis umumilesme - nisbet sabit qalir iddiasi)
    # Derslikden kenar bilik? Xeyr
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "9", "riy-9-ehtimal",
     "riy9-ehtimal#37", "riy9-ehtimal#comb1",
     "6 nəfərdən 2 nəfərlik komanda seçilir (bütün seçimlər bərabər ehtimallıdır). Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Mümkün seçimlərin ümumi sayı C(6,2)=15-dir.\n"
     "2) Bu 6 nəfər arasındakı Aygün adlı şagirdin seçilmiş komandaya daxil olması üçün əlverişli seçimlərin sayı 5-dir (Aygün + qalan 5 nəfərdən biri).\n"
     "3) Klassik ehtimal düsturuna görə (əlverişli/mümkün), Aygünün komandaya düşmə ehtimalı 5/15=1/3-dür.\n"
     "4) Əgər komanda 2 yox, 3 nəfərlik olsaydı, Aygünün seçilmə ehtimalı da eyni (1/3) qalardı.",
     "1, 2 və 3 doğrudur (Python-la yoxlanıldı). 4-cü mülahizə "
     "yanlışdır: 3 nəfərlik komandada ehtimal C(5,2)/C(6,3)=10/20=1/2 "
     "olur, 1/3 yox - komanda ölçüsü böyüdükcə bir nəfərin seçilmə "
     "ehtimalı da artır.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 5/10
    # Sebeb: bagliliqsiz ve baglayicili formanin HANSI qaydaya gore
    #   vergul aldigi ferqlendirilir, sonra bu iki qaydanin AYNI
    #   NETICEYE (vergul) getirdiyi gorulur.
    # Addimlar: 1, 2 (paralel qaydalar) -> 3 (1 ve 2-ni birlesdirir) ->
    #   4 (yanlis umumilesme - vergul yalniz baglayici ile bagli sanilir)
    # Derslikden kenar bilik? Xeyr - yalniz bankin oz cavablarina
    #   (#7, #13, #26) istinad edilir, elave linqvistik hokm yoxdur
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-tabesiz-baglayici",
     "az9-tabesiz-baglayici#23", "az9-tabesiz-baglayici#comb1",
     "«Külək əsdi, yarpaqlar töküldü» və «Külək əsdi, lakin yarpaqlar tökülmədi» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Birinci cümlədə bağlayıcısız tabesiz mürəkkəb cümlədə tərəflər sadalama intonasiyası ilə (vergüllə) bağlanır.\n"
     "2) İkinci cümlədə isə «lakin» bağlayıcısından əvvəl vergül qoyulur.\n"
     "3) Deməli hər iki cümlədə də vergül var, amma səbəbi fərqlidir: birincidə bağlayıcı yoxluğu, ikincidə «lakin»in özünün tələbi.\n"
     "4) Əgər «lakin» sözü çıxarılıb «Külək əsdi, yarpaqlar tökülmədi» yazılsa, vergül artıq yanlış olar, çünki indi cümlə bağlayıcısızdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 1-ci mülahizənin "
     "özünə görə bağlayıcısız cümlədə DƏ vergül lazımdır (sadalama "
     "intonasiyası ilə) - «lakin»in çıxarılması vergülü yanlış "
     "etmir, sadəcə səbəbini dəyişir.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # Cetinlik: 5/10
    # Sebeb: iki ayri melumat elaqesini (zaman, qarsilasdirma)
    #   ferqlendirmek, sonra ucuncu terkib hisseni yeni elave olunan
    #   baglayici ile duz tesnif etmek.
    # Addimlar: 1, 2 (paralel tesnifat) -> 3 (1 ve 2-ni birlesdirir) ->
    #   4 (yanlis umumilesme - hamisi eyni elaqe sayilir)
    # Derslikden kenar bilik? Xeyr - yalniz bankin #2/#4/#14 faktlarina
    #   istinad edilir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-tabesiz-mena",
     "az9-tabesiz-mena#24", "az9-tabesiz-mena#comb1",
     "«Şimşək çaxdı, göy guruldadı, amma biz qorxmadıq» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Şimşək çaxdı, göy guruldadı» hissəsi zaman (ardıcıllıq) əlaqəsini bildirir.\n"
     "2) «..., amma biz qorxmadıq» hissəsi isə qarşılaşdırma əlaqəsini bildirir.\n"
     "3) Bu üç hissəli cümlədə iki fərqli məna əlaqəsi (zaman və qarşılaşdırma) birləşir.\n"
     "4) Cümlədəki bütün üç tərəf eyni məna əlaqəsini (zaman əlaqəsini) daşıyır, çünki hamısı bir-birinin ardınca gəlir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 3-cü hissə "
     "(«amma biz qorxmadıq») ilk ikisinə QARŞILAŞDIRMA əlaqəsi ilə "
     "bağlanır, zaman əlaqəsi ilə yox - bütün cümlə eyni əlaqə "
     "növündən ibarət deyil.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 5/10
    # Sebeb: iki ferqli movqeli (sonra/evvel) budaq cumle numunesini
    #   mueqayise etmek, sonra bu mueqayiseden YANLIS umumilesdirme
    #   qurulub-qurulmadigini yoxlamaq.
    # Addimlar: 1, 2 (paralel numuneler) -> 3 (her ikisinde ortaq
    #   netice) -> 4 (2-ci addimla birbasa ziddiyyet)
    # Derslikden kenar bilik? Xeyr - #6/#7/#8/#21-in oz cavablarina
    #   istinad edilir, yeni numune ("kim..o") de bankin oz #13-undendir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-tabeli-qurulus",
     "az9-tabeli-qurulus#27", "az9-tabeli-qurulus#comb1",
     "«Bilirəm ki, sən gələcəksən» və «Kim çalışsa, o qazanar» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Birinci cümlədə «Bilirəm» baş cümlə, «sən gələcəksən» isə budaq cümlədir - budaq cümlə burada baş cümlədən SONRA gəlir.\n"
     "2) İkinci cümlədə isə əksinə, budaq cümlə («kim çalışsa») baş cümlədən («o qazanar») ƏVVƏL gəlir.\n"
     "3) Hər iki cümlədə budaq cümləni buraxsaq, qalan hissə fikri natamam saxlayar.\n"
     "4) Bu iki nümunədən çıxan nəticə: budaq cümlə HƏMİŞƏ baş cümlədən sonra gəlməlidir, «kim çalışsa, o qazanar» isə bu qaydanın istisnasıdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 2-ci mülahizənin "
     "özü göstərir ki, budaq cümlə baş cümlədən ƏVVƏL də gəlir - bu, "
     "«istisna» yox, normal bir imkandır (budaq cümlənin yeri sabit "
     "deyil).",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # Cetinlik: 6/10
    # Sebeb: mubteda budaq cumlesini teyin etmek, onun icindeki
    #   qrammatik esasi tapmaq, sonra umumi qrammatik esas sayini
    #   dogru hesablamaq.
    # Addimlar: 1 -> 2 (1-i deqiqlesdirir) -> 3 (1 ve 2-ni #13/#28-in
    #   qaydasi ile birlesdirir) -> 4 (yanlis netice - esas sayi)
    # Derslikden kenar bilik? Xeyr - #3/#13/#28-in oz cavablarina
    #   istinad edilir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-mubteda-xeber-bc",
     "az9-mubteda-xeber-bc#26", "az9-mubteda-xeber-bc#comb1",
     "«Kim çox oxuyursa, o çox bilər» cümləsi ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Kim çox oxuyursa» mübtəda budaq cümləsidir.\n"
     "2) Bu cümlədə baş cümlənin öz mübtədası («o») mövcuddur, budaq cümlə ona əlavə izah verir.\n"
     "3) Cümlədə 2 qrammatik əsas var - biri budaq cümlədə («kim...oxuyursa»), biri baş cümlədə («o...bilər»).\n"
     "4) Budaq cümlə mübtəda vəzifəsində olduğu üçün ayrıca qrammatik əsas sayılmır - cümlədə yalnız 1 qrammatik əsas var.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: budaq cümlə hansı "
     "üzvün vəzifəsində olursa olsun, öz mübtəda-xəbərini (qrammatik "
     "əsasını) daşıyır - cümlədə 2 qrammatik əsas var, #28-in "
     "nümunəsindəki kimi.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 6/10
    # Sebeb: iki ferqli budaq cumle novunu (tamamliq/teyin) eyni
    #   qarsiliq soz mexanizmi ile ferqlendirmek, sonra bu ferqi
    #   yanlis umumilesdirib-umumilesdirmediyini yoxlamaq.
    # Addimlar: 1, 2 (paralel tesnifat) -> 3 (1 ve 2-ni #26-nin
    #   qaydasi ile birlesdirir) -> 4 (yanlis - eyni uzv sayilir)
    # Derslikden kenar bilik? Xeyr - #3/#6/#26-nin oz cavablarina
    #   istinad edilir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-tamamliq-teyin-bc",
     "az9-tamamliq-teyin-bc#16", "az9-tamamliq-teyin-bc#comb1",
     "«Onu deyim ki, işlər yaxşı gedir» və «Elə adam ol ki, hamı sənə hörmət etsin» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Birinci cümlədə budaq cümlə TAMAMLIQ budaq cümləsidir («onu» qarşılıq sözü ilə).\n"
     "2) İkinci cümlədə isə budaq cümlə TƏYİN budaq cümləsidir («elə» qarşılıq sözü ilə).\n"
     "3) Bu iki cümlə arasındakı fərq budaq cümlənin verdiyi cavab və aid olduğu üzvdəndir.\n"
     "4) Hər iki qarşılıq söz («onu» və «elə») eyni üzvü (tamamlığı) əvəz etdiyi üçün, hər iki cümlədəki budaq cümlə də eyni növdəndir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «elə» tamamlığın "
     "yox, TƏYİNİN qarşılıq sözüdür - 1-ci və 2-ci mülahizələr artıq "
     "bunları FƏRQLİ növ kimi təsnif edib, 4-cü mülahizə bununla "
     "ziddiyyət təşkil edir.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # Cetinlik: 6/10
    # Sebeb: iki ferqli zerflik novunu (sebeb/meqsed) zaman-istiqameti
    #   qaydasi ile tesnif etmek, sonra bu qaydanin butun "cunki"
    #   cumlelerine tetbiq oluna bilib-bilmediyini yoxlamaq.
    # Addimlar: 1, 2 (paralel tesnifat) -> 3 (1 ve 2-ni #21-in
    #   qaydasi ile birlesdirir) -> 4 (yanlis umumilesme)
    # Derslikden kenar bilik? Xeyr - #5/#7/#21-in oz cavablarina
    #   istinad edilir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-zerflik-bc",
     "az9-zerflik-bc#29", "az9-zerflik-bc#comb1",
     "«Gecikdim, çünki yol bağlı idi» və «Ona görə çalışıram ki, arzuma çatım» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Birinci cümlədə budaq cümlə səbəb bildirir («yol bağlı idi» - artıq olmuş iş).\n"
     "2) İkinci cümlədə isə budaq cümlə məqsəd bildirir («arzuma çatım» - hələ olmamış, gələcək iş).\n"
     "3) Səbəb artıq olmuş işi, məqsəd isə hələ olacaq işi bildirir - bu iki cümlə dəqiq bu fərqi göstərir.\n"
     "4) Bu qaydaya əsasən, «çünki» bağlayıcısı ilə başlayan HƏR budaq cümlə məqsəd bildirir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «çünki» SƏBƏB "
     "bağlayıcısıdır (1-ci mülahizənin özündə göründüyü kimi), "
     "məqsəd yox - iddia öz-özü ilə ziddiyyət təşkil edir.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: iki ferqli vergul qaydasini (ki-den sonra / budaq
    #   cumlenin sonunda) ferqlendirmek, sonra bu qaydalardan birinin
    #   umumilesdirilib-umumilesdirilmediyini yoxlamaq.
    # Addimlar: 1, 2 (paralel qaydalar) -> 3 (1 ve 2-ni ortaq
    #   mentiqle birlesdirir) -> 4 (yanlis umumilesme)
    # Derslikden kenar bilik? Xeyr - #4/#5/#7-nin oz cavablarina
    #   istinad edilir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-durgu-mc",
     "az9-durgu-mc#23", "az9-durgu-mc#comb1",
     "«Bilirəm ki, sən gələcəksən» və «Əgər çox çalışsan, nəticə görərsən» cümlələri ilə bağlı aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Birinci cümlədə vergül «ki» bağlayıcısından sonra qoyulur.\n"
     "2) İkinci cümlədə isə budaq cümlə (şərt) əvvəldə olduğu üçün, vergül budaq cümlədən sonra qoyulur.\n"
     "3) Hər iki qaydanın ortaq məntiqi: vergül budaq cümlənin bitdiyi yerdə qoyulur.\n"
     "4) Deməli, tabeli mürəkkəb cümlədə vergülün yeri həmişə sabitdir - istənilən konstruksiyada elə «ki» sözündən sonra qoyulur.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 2-ci cümlədə heç "
     "«ki» sözü belə yoxdur - vergül budaq cümlənin sonunda qoyulur, "
     "«ki»-yə bağlı deyil. 1-ci mülahizədəki xüsusi qayda BÜTÜN "
     "formalara ümumiləşdirilə bilməz.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 5/10
    # Sebeb: nitq temizliyi ve edebi dile aidlik anlayislarinin
    #   FERQLI meyarlara esaslandigini gostermek, sonra bu ferqin
    #   yanlis silinib-silinmediyini yoxlamaq.
    # Addimlar: 1, 2 (paralel qaydalar) -> 3 (1 ve 2-ni mueqayise
    #   edir) -> 4 (yanlis - sinonimi tufeyli soz sayir)
    # Derslikden kenar bilik? Xeyr - #24/#13-un oz cavablarina istinad
    #   edilir
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "9", "az-9-metn-nitq",
     "az9-metn-nitq#22", "az9-metn-nitq#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Nitqin təmizliyi kobud və artıq (tüfeyli) sözləri istisna edir.\n"
     "2) Ədəbi dilə isə dialekt və loru sözlər daxil deyil.\n"
     "3) Bu iki qayda fərqli meyarlara əsaslanır: nitq təmizliyi təkrar/mənasızlıq məsələsidir, ədəbi dilə aidlik isə sözün mənşəyi/yayılma dairəsi məsələsidir.\n"
     "4) Deməli, sinonimlər də nitq təmizliyi baxımından tüfeyli söz sayılır, çünki onlar da «artıq» sözlərdir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: sinonimlər üslubi "
     "məqsədlə işlədilən fərqli sözlərdir, tüfeyli (mənasız təkrar) "
     "söz deyil - bank bu ikisini açıq şəkildə ayırır.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Difficulty: 5/10
    # Reason: identify "bilingual" meaning, apply for-vs-since rule,
    #   apply neither-nor pairing, then check whether a DIFFERENT
    #   pair of languages (not spoken) affects the bilingual claim.
    # Steps: 1, 2, 3 (parallel facts) -> 4 (wrong inference from 2&3
    #   confused with 1)
    # Outside textbook knowledge? No - grounded in #2/#5/#19
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "9", "ing-9-identity",
     "ing9-identity#28", "ing9-identity#comb1",
     "Ayshe is bilingual: she has been learning English for five years, but she speaks neither French nor German. Which statements are TRUE?\n"
     "1) \"Bilingual\" means Ayshe speaks two languages.\n"
     "2) \"has been learning English for five years\" uses \"for\" because it states a DURATION, not a starting point.\n"
     "3) \"speaks neither French nor German\" uses \"nor\" to pair with \"neither\" and negate both.\n"
     "4) Since she speaks \"neither French nor German,\" she is not bilingual - she only knows one language.",
     "1, 2 and 3 are true. Statement 4 is wrong - not speaking French "
     "or German does not contradict being bilingual: she is bilingual "
     "because of Azerbaijani (her mother tongue) and English, two "
     "completely different languages from the \"neither...nor\" pair.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # Difficulty: 5/10
    # Reason: identify passive tense form, connect it to a factual
    #   claim about the novel's source, then check whether "based on
    #   real events" logically forces a fiction/non-fiction label.
    # Steps: 1, 2, 3 (parallel facts) -> 4 (wrong inference combining
    #   2 and the fiction definition)
    # Outside textbook knowledge? No - grounded in #4/#9/#28
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "9", "ing-9-books",
     "ing9-books#6", "ing9-books#comb1",
     "This novel, which is based on real events, was written a century ago. Which statements are TRUE?\n"
     "1) \"was written a century ago\" uses Past Simple Passive because the action happened at a specific point in the past.\n"
     "2) \"is based on real events\" describes the novel's source.\n"
     "3) \"Fiction\" means invented/imaginative literature.\n"
     "4) Since the novel \"is based on real events,\" it must be non-fiction, not fiction, because fiction can never be based on real events.",
     "1, 2 and 3 are true. Statement 4 is wrong - fiction (invented "
     "literature) very often draws on real events (e.g. historical "
     "novels) while still being fictionalised - \"based on real "
     "events\" does not make a work non-fiction.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Difficulty: 5/10
    # Reason: recognise "used to" as a past-habit marker, apply two
    #   preposition rules (in/with), then check whether "used to"
    #   implies the habit continues today.
    # Steps: 1, 2, 3 (parallel facts) -> 4 (wrong inference from 1)
    # Outside textbook knowledge? No - grounded in #18/#4/#7
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "9", "ing-9-traditions",
     "ing9-traditions#23", "ing9-traditions#comb1",
     "In the past, people used to travel by horse to celebrate Novruz, which is celebrated in spring. Nowadays, guests are welcomed with tea instead. Which statements are TRUE?\n"
     "1) \"used to travel by horse\" describes a PAST HABIT that is no longer true now.\n"
     "2) \"celebrated in spring\" uses \"in\" because spring is a season (a general time period), not a specific day.\n"
     "3) \"welcomed with tea\" uses \"with\" to show the means of welcoming.\n"
     "4) Since \"used to\" describes a past habit, it means people still travel by horse today to celebrate Novruz.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"used to\" "
     "specifically contrasts a past habit with the present, implying "
     "the habit has STOPPED, not that it continues.",
     ["1, 2, 4", "2, 3, 4", "1, 2, 3", "1, 4"], 3),

    # Difficulty: 6/10
    # Reason: distinguish First vs Second Conditional forms, connect
    #   each to its real/hypothetical meaning, then check whether the
    #   two forms can be mixed together.
    # Steps: 1, 2 (parallel forms) -> 3 (compares 1 and 2's meaning)
    #   -> 4 (wrong claim that forms are interchangeable)
    # Outside textbook knowledge? No - grounded in #4/#27
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "9", "ing-9-ambitions",
     "ing9-ambitions#19", "ing9-ambitions#comb1",
     "\"If you work hard, you will succeed\" and \"If she studied harder, she would pass the exam.\" Which statements are TRUE?\n"
     "1) The first sentence is First Conditional (If + present, will + verb) - a realistic/likely future outcome.\n"
     "2) The second sentence is Second Conditional (If + past, would + verb) - a hypothetical situation, implying she is NOT currently studying hard.\n"
     "3) The two sentences use different conditional forms because they express different degrees of likelihood.\n"
     "4) Since both sentences are about hard work leading to success, they can be mixed: \"If you worked hard, you will succeed\" would be equally correct.",
     "1, 2 and 3 are true. Statement 4 is wrong - mixing Past tense "
     "in the if-clause with \"will\" in the main clause is "
     "ungrammatical; First and Second Conditional forms must stay "
     "internally consistent.",
     ["1, 2, 3", "1, 2, 4", "2, 3, 4", "1, 4"], 1),

    # Difficulty: 5/10
    # Reason: apply the draw-vs-paint distinction, apply two
    #   preposition/passive rules, then check whether "draw" and
    #   "paint" are interchangeable once both describe "making art."
    # Steps: 1, 2 (parallel facts) -> 3 (applies the draw/paint
    #   distinction in sequence) -> 4 (wrong claim they're the same)
    # Outside textbook knowledge? No - grounded in #14/#19/#28
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "9", "ing-9-art",
     "ing9-art#30", "ing9-art#comb1",
     "Yesterday, the walls of the gallery were decorated with beautiful patterns, and the exhibition was opened. The artist first drew the design with a pencil, then painted it with bright colours. Which statements are TRUE?\n"
     "1) \"was opened\" uses Past Simple Passive because the action happened at a specific past time.\n"
     "2) \"were decorated with patterns\" uses \"with\" to show the means/material of decoration.\n"
     "3) The artist first drew (pencil), then painted (paint) - two different techniques.\n"
     "4) Since both \"drew\" and \"painted\" describe making art, they mean exactly the same thing and are interchangeable here.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"draw\" (with a "
     "pencil) and \"paint\" (with paint) are different techniques, "
     "not interchangeable synonyms, as the sentence itself shows by "
     "using them for two separate steps.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # Difficulty: 5/10
    # Reason: apply three distinct workplace-quality adjectives to one
    #   description, then check whether "positive workplace word"
    #   makes them all synonyms.
    # Steps: 1, 2, 3 (parallel facts about the same person) -> 4
    #   (wrong claim they're all interchangeable, contradicted by the
    #   passage's own "not flexible" contrast)
    # Outside textbook knowledge? No - grounded in #20/#17/#26
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "9", "ing-9-skills",
     "ing9-skills#29", "ing9-skills#comb1",
     "Rashad is a punctual employee - he always arrives on time. He is also reliable, so his manager trusts him with important tasks. However, he is not very flexible, and he struggles when his schedule changes suddenly. Which statements are TRUE?\n"
     "1) \"Punctual\" describes Rashad arriving on time - this is about TIME.\n"
     "2) \"Reliable\" describes that his manager trusts him - this is about DEPENDABILITY, a different quality from punctuality.\n"
     "3) \"Not very flexible\" means Rashad has difficulty adapting to sudden changes - a third, separate quality.\n"
     "4) Since punctual, reliable, and flexible are all positive workplace words, they all mean the same thing, so calling Rashad \"punctual\" is the same as calling him \"flexible\".",
     "1, 2 and 3 are true. Statement 4 is wrong - these are distinct "
     "qualities, and the passage itself contradicts it: Rashad is "
     "punctual and reliable BUT explicitly NOT flexible.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),
    # ============================================================
    # YEDDINCI DALGA (2026-09-03): 8-ci sinif - V2 STANDARTLA.
    # riyaziyyat (11 movzu), az-dili (8 movzu), ingilis-dili
    # (12 movzu) = 31 bend. Riyaziyyat faktlari Python-la yoxlanildi.
    # Qrammatika/uslub movzularinda (V2-B) YALNIZ bankin oz artiq
    # tesdiqlenmis cavablari restate olunur, yeni linqvistik hokm
    # elave edilmir.
    # ============================================================

    # Cetinlik: 6/10
    # Sebeb: iki ayri kok hasilini eyni qayda ile hesablamaq, sonra
    #   sadelesdirilmis formani yaddan cixarib xeta etmek.
    # Addimlar: 1,2 (eyni qaydanin iki misali) -> 3 (paralel fakt) ->
    #   4 (3-un sadelesdirilmis formasindan yanlis nice cixarma)
    # Derslikden kenar bilik? Xeyr (hamisi #6/#7/#9/#30-dan)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-kvadrat-kok",
     "riy8-kvadrat-kok#40", "riy8-kvadrat-kok#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) √a · √b = √(ab) qaydasına görə, √36 · √25 = √900 = 30 alınır.\n"
     "2) Eyni qaydaya görə, √13 · √52 = √676 = 26 alınır (13 · 52 = 676, 26² = 676).\n"
     "3) √18 ifadəsi tək başına sadələşəndə 3√2 alınır (18 = 9 · 2).\n"
     "4) Bu qaydaya əsasən, √18 · √2 hasilini 3√2 sadələşdirilmiş formasını 2-yə vuraraq 6√2 kimi tapmaq olar.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: √18 · √2 = √36 = 6 "
     "(eyni √a·√b=√(ab) qaydası ilə birbaşa), 6√2 yox - sadələşdirilmiş "
     "3√2 formasını √2-yə vuranda 3·(√2·√2)=3·2=6 alınır, artıq √2 qalmır.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 6/10
    # Sebeb: konkret nerdivan meselesini hell etmek, sonra 2 defe
    #   miqyaslamani tetbiq etmek, sonra QISMEN miqyaslama telesine
    #   dusmek.
    # Addimlar: 1 (Pifaqor) -> 2 (1-in HEM eseasi, HEM hipotenuzu
    #   miqyaslanir) -> 3 (2-nin izahi) -> 4 (qismen miqyaslama)
    # Derslikden kenar bilik? Xeyr (#19/#27-den)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-pifaqor",
     "riy8-pifaqor#35", "riy8-pifaqor#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Divara söykənən 5 m-lik nərdivanın aşağı ucu divardan 3 m aralıdırsa, nərdivan divarda 4 m hündürlüyə çatır.\n"
     "2) 3-4-5 üçlüyünü 2-yə vursaq, 6-8-10 üçlüyü alınır - yəni əsas 6 m, nərdivan 10 m olanda hündürlük 8 m-dir.\n"
     "3) Bu, Pifaqor üçlüyünün miqyaslana bilmə xassəsidir: bütün tərəflər eyni əmsalla vurulanda üçbucağın forması dəyişmir.\n"
     "4) Bu qaydaya əsasən, divardan məsafə 3 m saxlanılıb yalnız nərdivan 10 m-ə uzadılsa, hündürlük yenə 8 m olar.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: miqyaslama YALNIZ HƏR "
     "İKİ tərəf birgə dəyişəndə işləyir - əsas 3 m-də qalıb yalnız "
     "hipotenuz 10 m-ə uzansa, hündürlük √(10²−3²)=√91≈9,54 m olar, 8 m yox.",
     ["1, 3", "2, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 6/10
    # Sebeb: iki FERQLI tenliyin koklerini ayri-ayri tapmaq, Viet
    #   qaydasi ile yoxlamaq, sonra oxsar emsallara gore onlari
    #   qarisdirmaq telesine dusmek.
    # Addimlar: 1 (tenlik A) -> 2 (1-i Viet ile tesdiqleyir) -> 3
    #   (tenlik B, paralel fakt) -> 4 (A ve B-ni qarisdirir)
    # Derslikden kenar bilik? Xeyr (#14/#21/#8/#13-den)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-kvadrat-tenlik",
     "riy8-kvadrat-tenlik#34", "riy8-kvadrat-tenlik#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) x² − 7x + 10 = 0 tənliyinin kökləri 2 və 5-dir.\n"
     "2) Vietə görə bu köklərin cəmi (2+5=7) əmsalın əksinə (−(−7)=7), hasili (2·5=10) sərbəst həddə (10) uyğun gəlir.\n"
     "3) x² − 3x − 10 = 0 tənliyinin kökləri isə fərqlidir: −2 və 5-dir.\n"
     "4) Bu iki tənliyin oxşar əmsallarına əsasən, x² − 7x + 10 = 0 tənliyinin kökləri x² − 3x − 10 = 0 tənliyinin köklərinə də uyğun gəlir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: bu, iki FƏRQLİ "
     "tənliyin köklərini qarışdırmaqdır - {2,5} və {−2,5} ortaq yalnız "
     "5-i paylaşır, 2 ilə −2 tamam fərqlidir.",
     ["2, 3, 4", "1, 4", "1, 2, 3", "yalnız 1"], 3),

    # Cetinlik: 6/10
    # Sebeb: qonsu bucaqdan qarsi bucaga, sonra hamisini birlesdirib
    #   360-a cemlemek, sonra "hamisi eyni bucaq" ferziyyesini
    #   yoxlamaq.
    # Addimlar: 1 -> 2 (1-in netices ile parallel) -> 3 (1,2-ni
    #   birlesdirir) -> 4 (3-un yanlis umumilesmesi)
    # Derslikden kenar bilik? Xeyr (#21/#10/#11/#3-den)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-dordbucaqlilar",
     "riy8-dordbucaqlilar#37", "riy8-dordbucaqlilar#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Paraleloqramın bir bucağı 70°-dirsə, qonşu bucağı 110°-dir (qonşu bucaqların cəmi 180°).\n"
     "2) Paraleloqramın qarşı bucaqları bərabərdir - deməli 70°-lik bucağın qarşısındakı bucaq da 70°-dir.\n"
     "3) Beləliklə dörd bucaq ardıcıl 70°, 110°, 70°, 110°-dir, cəmləri 360°-yə bərabərdir.\n"
     "4) Bu nümunəyə əsasən, paraleloqramın bütün dörd bucağı 70°-dir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: yalnız qarşı-qarşıya "
     "olan bucaqlar bərabərdir, qonşu bucaqlar fərqlidir (70° və 110°) "
     "- hamısı 70° olsaydı cəm 280° olardı, 360° yox.",
     ["1, 3", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 6/10
    # Sebeb: vurma qaydasini, sonra qüvvetin qüvveti qaydasini, sonra
    #   bolme qaydasini ardicil tetbiq etmek, sonra bir addimi
    #   atlamaqla eyni neticeni "almaq" telesi.
    # Addimlar: 1 -> 2 (1-in neticesini kvadrata yukseldir) -> 3
    #   (2-nin neticesini bolur) -> 4 (2-ci addimi atlayir)
    # Derslikden kenar bilik? Xeyr (#11/#3/#12-nin eyni qaydalari)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-rasional-ifade",
     "riy8-rasional-ifade#29", "riy8-rasional-ifade#comb1",
     "(a⁴ · a³)² : a⁸ ifadəsi üçün aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) a⁴ · a³ = a⁷ (vurmada qüvvətlər toplanır).\n"
     "2) (a⁷)² = a¹⁴ (qüvvətin qüvvəti qaydasına görə üstlər vurulur).\n"
     "3) a¹⁴ : a⁸ = a⁶ (bölmədə qüvvətlər çıxılır).\n"
     "4) Kvadratlaşdırma addımını (2-ci addımı) atlayıb birbaşa a⁷ : a⁸ hesablasaq, yenə eyni a⁶ nəticəsi alınar.",
     "1, 2 və 3 doğrudur - nəticə a⁶-dır. 4-cü mülahizə yanlışdır: a⁷ : "
     "a⁸ = a⁻¹ (7<8 olduğu üçün mənfi qüvvət), a⁶ ilə heç bir əlaqəsi "
     "yoxdur - addımı atlamaq fərqli, səhv nəticə verir.",
     ["1, 4", "2, 3, 4", "1, 2, 3", "yalnız 2"], 3),

    # Cetinlik: 6/10
    # Sebeb: sahe ve cevre uzunlugunu eyni radiusdan tapmaq, sonra
    #   radiusu 2 defe artiranda sahenin NECE artdigini (4 defe,
    #   cevre kimi 2 defe yox) hesablamaq.
    # Addimlar: 1,2 (eyni r-in paralel neticeleri) -> 3 (1-in
    #   dusturunu yeni r-e tetbiq edir) -> 4 (3-u cevre kimi xetti
    #   sanmaq)
    # Derslikden kenar bilik? Xeyr (#9/#23/#8-den)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-sahe",
     "riy8-sahe#37", "riy8-sahe#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Radiusu 10 olan dairənin sahəsi 100π-dir (S=πr²=π·100).\n"
     "2) Eyni radiuslu çevrənin uzunluğu isə 20π-dir (uzunluq=2πr=2π·10).\n"
     "3) Radius 20-yə (2 dəfə) artırılsa, S=πr² düsturuna görə yeni sahə π·400=400π olar, yəni sahə 4 dəfə artır.\n"
     "4) Bu qaydaya əsasən, radius 2 dəfə artanda sahə də cəmi 2 dəfə artıb 200π olar.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: sahə (S=πr²) "
     "radiusdan KVADRATİK asılıdır, çevrənin uzunluğu (2πr) kimi xətti "
     "yox - radius 2 dəfə artanda sahə 4 dəfə (200π yox, 400π) artır.",
     ["1, 2, 4", "1, 4", "2, 3, 4", "1, 2, 3"], 4),

    # Cetinlik: 6/10
    # Sebeb: musbet ve menfi keki tapmaq, ikisini de yoxlamaq (kenar
    #   kok deyil), sonra "carpaz vurma HEMISE kenar kok yaradir"
    #   yanlis umumilesmesini tutmaq.
    # Addimlar: 1 -> 2 (1-in paralel menfi keki) -> 3 (1,2-ni
    #   birlikde yoxlayir) -> 4 (3-un yanlis umumilesmesi)
    # Derslikden kenar bilik? Xeyr (#22/#3/#33/#17-nin qaydalari)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-rasional-tenlik",
     "riy8-rasional-tenlik#16", "riy8-rasional-tenlik#comb1",
     "x/6 = 24/x tənliyi üçün aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Çarpaz vurma ilə x² = 144 alınır, müsbət kök x=12-dir.\n"
     "2) x² = 144 tənliyinin mənfi kökü də var: x=−12.\n"
     "3) Hər iki kökü (12 və −12) yoxlasaq, ikisi də tənliyi ödəyir - heç biri məxrəci (x=0-ı) sıfır etmir, ona görə kənar kök deyil.\n"
     "4) Çarpaz vurma HƏR ZAMAN kənar kök yaradır, ona görə x=12 və x=−12-dən biri mütləq kənar kökdür.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: çarpaz vurma YALNIZ "
     "məxrəci sıfır edən kök yaransa kənar kök yaradır - bu misalda heç "
     "bir kök məxrəci sıfır etmir, «hər zaman» ümumiləşdirməsi səhvdir.",
     ["yalnız 1", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Cetinlik: 6/10
    # Sebeb: emsali tapmaq, onu perimetre (xetti) tetbiq etmek, sonra
    #   sahe ucun FERQLI (kvadratik) qaydani tetbiq etmek, sonra
    #   ikisini qarisdirmaq.
    # Addimlar: 1 -> 2 (1-i perimetre tetbiq edir) -> 3 (1-i sahe ucun
    #   FERQLI tetbiq edir) -> 4 (2 ve 3-u qarisdirir)
    # Derslikden kenar bilik? Xeyr (#23/#13/#4-den)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-oxsarliq",
     "riy8-oxsarliq#33", "riy8-oxsarliq#comb1",
     "△ABC ~ △DEF, AB=4, DE=12 verilmişdir. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Oxşarlıq əmsalı k=3-dür (12:4=3).\n"
     "2) Bu əmsala görə, ABC-nin perimetri 12-dirsə, DEF-in perimetri 12·3=36 olar.\n"
     "3) Sahələrin nisbəti isə k²=9-dur, yəni DEF-in sahəsi ABC-nin sahəsindən 9 dəfə böyükdür.\n"
     "4) Bu qaydaya əsasən, sahələr də perimetrlər kimi əmsalla eyni (3 dəfə) artır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: sahə k² ilə (9 dəfə) "
     "artır, perimetr kimi xətti (3 dəfə) yox - sahə kvadratik, perimetr "
     "xəttidir.",
     ["1, 4", "2, 3, 4", "1, 2, 3", "yalnız 1"], 3),

    # Cetinlik: 6/10
    # Sebeb: tenliyi hell edib neticeni tapmaq, isare deyisme qaydasini
    #   iki defe tetbiq etmek, sonra bir defe qaydani UNUTMAQ (isareni
    #   deyismemek) telesine dusmek.
    # Addimlar: 1 (5x-3>2x+9 -> x>4) -> 2 (1-in neticesini -1-e vurur)
    #   -> 3 (1-in neticesini -3-e vurur) -> 4 (1-in neticesini -2-ye
    #   vurur, amma isareni deyismir)
    # Derslikden kenar bilik? Xeyr (#25/#2/#23/#17-nin qaydalari)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-berabersizlik",
     "riy8-berabersizlik#16", "riy8-berabersizlik#comb1",
     "5x − 3 > 2x + 9 bərabərsizliyi üçün aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Bərabərsizliyin həlli x > 4-dür (5x−2x>9+3 → 3x>12 → x>4).\n"
     "2) Bu nəticəyə əsasən, −x < −4 doğrudur (hər iki tərəfi −1-ə vuranda işarə dəyişir).\n"
     "3) Yenə bu nəticəyə əsasən, −3x < −12 doğrudur (hər iki tərəfi −3-ə vuranda işarə dəyişir).\n"
     "4) Eyni qaydaya əsasən, −2x > −8 doğrudur (hər iki tərəfi −2-yə vuraraq).",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: bərabərsizliyin hər "
     "iki tərəfini mənfi ədədə (−2) vuranda işarə mütləq dəyişməlidir - "
     "düzgün nəticə −2x < −8-dir, −2x > −8 yox (işarə dəyişdirilməyib).",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # Cetinlik: 6/10
    # Sebeb: sin/cos qiymetlerini tapmaq, eyniliklə yoxlamaq, sonra
    #   tangensi tapmaq, sonra kotangensi tangenslə qarisdirmaq
    #   (bir-birinin tersidir).
    # Addimlar: 1 -> 2 (1-i eyniliklə istifade edir) -> 3 (1,2-ni
    #   nisbetlendirir) -> 4 (3-u kotangenslə qarisdirir)
    # Derslikden kenar bilik? Xeyr (#4/#11/#25/#23/#34-den)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-triqonometrik",
     "riy8-triqonometrik#39", "riy8-triqonometrik#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) sin 30° = 1/2-dir.\n"
     "2) Bu qiymətə əsasən və sin²α+cos²α=1 eyniliyini tətbiq etsək, cos 30° = √3/2 alınır (cos²30°=1−1/4=3/4).\n"
     "3) sin 30° və cos 30°-nin bu qiymətlərinə əsasən, tan 30° = sin30°/cos30° = √3/3 alınır.\n"
     "4) Bu qiymətlərə əsasən, cot 30° = tan 30° ilə eynidir, yəni √3/3-dür.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: kotangens tangensin "
     "TƏRSİDİR (cot α = cos α/sin α) - cot 30° = √3, tan 30° = √3/3, "
     "bunlar bir-birindən fərqlidir, eyni deyil.",
     ["2, 4", "1, 2, 3", "1, 3", "yalnız 2"], 2),

    # Cetinlik: 6/10
    # Sebeb: bir ehtimali tapmaq, eks hadise qaydasini tetbiq etmek,
    #   nisbeti hesablamaq, sonra iki musteqil hadise ucun TOPLAMA
    #   (vurma evezine) telesine dusmek.
    # Addimlar: 1 -> 2 (1-in eks hadisesi) -> 3 (1,2-ni nisbetlendirir)
    #   -> 4 (mustqil hadiseleri sehv toplayir)
    # Derslikden kenar bilik? Xeyr (#15/#26/#19-un qaydalari)
    # Ezberle cavablandirila biler? Xeyr
    ("riyaziyyat", "orta", "8", "riy-8-ehtimal",
     "riy8-ehtimal#7", "riy8-ehtimal#comb1",
     "Qutuda 4 qırmızı və 6 mavi kürə var. Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Mavi kürə çıxarma ehtimalı 6/10=3/5-dir.\n"
     "2) Bu ehtimala əsasən, qırmızı kürə çıxarma ehtimalı (əks hadisə) 1−3/5=2/5-dir.\n"
     "3) Bu iki ehtimala əsasən, mavi kürə çıxma ehtimalı qırmızıdan 1,5 dəfə çoxdur ((3/5):(2/5)=1,5).\n"
     "4) Kürə geri qoyulmaqla iki dəfə ardıcıl çıxarılsa, hər ikisinin mavi olması ehtimalı 3/5+3/5=6/5-dir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: iki MÜSTƏQİL "
     "hadisənin İKİSİNİN BİRDƏN baş verməsi ehtimalı TOPLANMIR, "
     "VURULUR - düzgün nəticə (3/5)·(3/5)=9/25-dir; üstəlik ehtimal heç "
     "vaxt 1-dən böyük ola bilməz, 6/5 artıq özü-özlüyündə mümkünsüzdür.",
     ["1, 2, 4", "1, 4", "1, 2, 3", "2, 3, 4"], 3),

    # ---------------------------------------------------------- az-dili 8
    # V2-B qaydasi: qrammatik movzularda YALNIZ bankin oz artiq
    # tesdiqlenmis cavablari restate olunur, yeni linqvistik hokm
    # elave edilmir.

    # Cetinlik: 6/10
    # Sebeb: uc novun her birinin ozunemexsus baglanma qaydasini
    #   ayirmaq, sonra "her ikisi de sekilcili" qaydasini butun
    #   novlere yayib 1-ci novu unutmaq.
    # Addimlar: 1 -> 2 (1-den ferqli nov) -> 3 (1,2-den de ferqli,
    #   ucuncu nov) -> 4 (1,2,3-u yanlis umumilesdirir)
    # Derslikden kenar bilik? Xeyr (#12/#13/#14/#8/#7/#11-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-soz-birlesmesi",
     "az8-soz-birlesmesi#4", "az8-soz-birlesmesi#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Dəmir qapı» birləşməsi 1-ci növ təyini söz birləşməsidir (tərəflər şəkilçisiz yanaşır).\n"
     "2) «Sinif otağı» birləşməsi isə fərqli, 2-ci növdür, çünki ikinci tərəf mənsubiyyət şəkilçisi qəbul edib.\n"
     "3) «Şəhərin küçələri» birləşməsi isə 3-cü növdür, çünki birinci tərəf yiyəlik halda, ikinci tərəf mənsubiyyət şəkilçilidir - yəni HƏR İKİ tərəf şəkilçilidir.\n"
     "4) Bu üç nümunəyə əsasən, təyini söz birləşmələrinin bütün növlərində hər iki tərəf mütləq şəkilçi qəbul etməlidir.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: 1-ci növdə (məs. "
     "«dəmir qapı») HEÇ BİR tərəf şəkilçi qəbul etmir, tərəflər sadəcə "
     "yanaşır - «hər iki tərəf şəkilçili olmalıdır» qaydası yalnız 3-cü "
     "növə aiddir, hamısına yox.",
     ["1, 2, 4", "1, 4", "2, 3, 4", "1, 2, 3"], 4),

    # Cetinlik: 5/10
    # Sebeb: iki ferqli xeber novunu ayirmaq, umumi uzlasma qaydasini
    #   tetbiq etmek, sonra "ismi xeber yalniz isimle olur" yanlis
    #   umumilesmesine dusmek.
    # Addimlar: 1 -> 2 (1-den ferqli xeber novu) -> 3 (1,2-ye ortaq
    #   qayda) -> 4 (1-in adindan yanlis nice cixarma)
    # Derslikden kenar bilik? Xeyr (#13/#14/#5/#26/#15-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-mubteda-xeber",
     "az8-mubteda-xeber#17", "az8-mubteda-xeber#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Bakı Azərbaycanın paytaxtıdır» cümləsində xəbər ismi xəbərdir.\n"
     "2) «Quşlar uçur» cümləsindəki xəbər isə feili xəbərdir, çünki feillə ifadə olunub.\n"
     "3) Hər iki cümlədə xəbər mübtəda ilə uzlaşır - şəxsə və kəmiyyətə görə uyğunlaşır.\n"
     "4) Bu iki nümunəyə əsasən, ismi xəbər yalnız isimlə ifadə oluna bilər, feillə ifadə oluna bilməz.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: ismi xəbər təkcə "
     "isimlə deyil, bir neçə nitq hissəsi ilə ifadə oluna bilər - "
     "«yalnız isimlə» məhdudiyyəti yanlışdır.",
     ["1, 2, 3", "1, 4", "2, 3, 4", "yalnız 1"], 1),

    # Cetinlik: 6/10
    # Sebeb: eyni cumlede iki ferqli tamamliq novunu ayirmaq, ayri bir
    #   uzvu (zerflik) elave etmek, sonra hal (yonluk) esasinda
    #   zerflik ile tamamligi qarisdirmaq.
    # Addimlar: 1 -> 2 (1-den ferqli tamamliq novu, eyni cumlede) -> 3
    #   (paralel fakt, basqa cumle) -> 4 (1,2-nin qaydasini yanlis
    #   yerde tetbiq edir)
    # Derslikden kenar bilik? Xeyr (#1/#2/#23/#16/#7-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-ikinci-uzvler",
     "az8-ikinci-uzvler#4", "az8-ikinci-uzvler#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Kitabı rəfə qoydum» cümləsində «kitabı» sözü vasitəsiz tamamlıqdır (təsirlik haldadır).\n"
     "2) Eyni cümlədə «rəfə» sözü isə vasitəli tamamlıqdır (yönlük haldadır).\n"
     "3) «Oxumaq üçün kitabxanaya getdi» cümləsində «oxumaq üçün» məqsəd zərfliyidir.\n"
     "4) Bu nümunələrə əsasən, «kitabxanaya» sözü də cümlədə tamamlıqdır, çünki yönlük haldadır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «kitabxanaya» sözü "
     "«hara?» sualına cavab verir və yer zərfliyidir - üzvü təkcə HAL "
     "əsasında (yönlük) müəyyənləşdirmək olmaz, sual/məna da nəzərə "
     "alınmalıdır.",
     ["1, 4", "2, 3, 4", "1, 2, 3", "yalnız 3"], 3),

    # Cetinlik: 5/10
    # Sebeb: umumi vergul qaydasindan iki istisnani (iki noqte, tire)
    #   ayirmaq, sonra ayri bir istisnani (baglayici "ve") bu iki
    #   istisna ile qarisdirmaq.
    # Addimlar: 1 -> 2 (1-in istisnasi) -> 3 (2-den de ferqli ikinci
    #   istisna) -> 4 (basqa bir istisnani 1-e uygunlasdirir)
    # Derslikden kenar bilik? Xeyr (#3/#6/#9/#5-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-hemcins",
     "az8-hemcins#18", "az8-hemcins#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Həmcins üzvlər arasında adətən vergül qoyulur.\n"
     "2) Amma ümumiləşdirici söz bu üzvlərdən ƏVVƏL gələndə, ondan sonra vergül yox, iki nöqtə (:) qoyulur.\n"
     "3) Ümumiləşdirici söz üzvlərdən SONRA gələndə isə ondan əvvəl tire (—) qoyulur.\n"
     "4) Bu qaydalara əsasən, təkrarlanmayan «və» bağlayıcısından əvvəl də vergül qoyulmalıdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: təkrarlanmayan «və» "
     "bağlayıcısından əvvəl vergül QOYULMUR - bu, «həmcins üzvlər "
     "arasında vergül» əsas qaydasının bir istisnasıdır.",
     ["1, 2, 3", "2, 3, 4", "1, 4", "yalnız 2"], 1),

    # Cetinlik: 5/10
    # Sebeb: umumi vergul qaydasindan konkret hala kecmek, xitabin
    #   cumle uzvu olmadigini tetbiq etmek, sonra "ey" nida edatini
    #   xitabin ozu ile qarisdirmaq.
    # Addimlar: 1 -> 2 (1-in konkretlesmesi) -> 3 (paralel fakt) -> 4
    #   (basqa nümunede xitabi yanlis muyyenlesdirir)
    # Derslikden kenar bilik? Xeyr (#4/#25/#3/#15-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-xitab-ara",
     "az8-xitab-ara#27", "az8-xitab-ara#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Xitab yazıda vergüllə ayrılır.\n"
     "2) Xitab cümlənin ortasında gələndə hər iki tərəfdən vergüllə ayrılır.\n"
     "3) Xitab cümlə üzvü deyil - ona görə «Uşaqlar, sabahınız xeyir!» cümləsində «Uşaqlar» sözü mübtəda ola bilməz.\n"
     "4) «Ey Vətən!» müraciətində «Ey» sözü xitabdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «Vətən» sözü "
     "xitabdır, «Ey» isə xitabdan ƏVVƏL işlənən ayrıca nida ədatıdır, "
     "xitabın özü deyil.",
     ["1, 3", "2, 4", "1, 2, 3", "1, 4"], 3),

    # Cetinlik: 5/10
    # Sebeb: uc ferqli cumle novunu bir-bir ayirmaq (cuttorkibli,
    #   muellim sexsli, qeyri-muellim sexsli), sonra qeyri-muellim
    #   sexsli ile sexssiz cumleni qarisdirmaq.
    # Addimlar: 1 -> 2 (1-den ferqli, tektorkibli alt novu) -> 3
    #   (2-den de ferqli ikinci tektorkibli alt novu) -> 4 (yeni
    #   numuneni 3-un novune yanlis aid edir)
    # Derslikden kenar bilik? Xeyr (#11/#6/#5/#13/#23-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-cumle-novleri",
     "az8-cumle-novleri#17", "az8-cumle-novleri#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) «Payız gəldi» cümləsi cüttərkiblidir - həm mübtədası, həm xəbəri var.\n"
     "2) «Gəlirəm» cümləsi isə təktərkiblidir - müəyyən şəxsli, çünki mübtəda feilin şəxs şəkilçisindən aydın olduğu üçün buraxılıb.\n"
     "3) «Otağı səliqəyə saldılar» cümləsi də təktərkiblidir, lakin fərqli növdür - qeyri-müəyyən şəxsli, çünki işi görən şəxs məlum deyil.\n"
     "4) Bu üç nümunəyə əsasən, «Bayırda qaranlıq idi» cümləsi də qeyri-müəyyən şəxsli cümlədir, çünki mübtəda yoxdur.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: «Bayırda qaranlıq "
     "idi» cümləsi ŞƏXSSİZ cümlədir - qeyri-müəyyən şəxsli cümlədə "
     "naməlum bir ŞƏXS nəzərdə tutulur, şəxssiz cümlədə isə mübtəda "
     "ümumiyyətlə təsəvvür belə edilmir (təbiət hadisəsi).",
     ["1, 2, 4", "1, 4", "2, 3, 4", "1, 2, 3"], 4),

    # Cetinlik: 5/10
    # Sebeb: iki ferqli durgu qaydasini (soz sirasina gore) ayirmaq,
    #   sonra biri o birinin qaydasini yanlis yerde tetbiq etmek.
    # Addimlar: 1 -> 2 (1-in konkret qaydasi) -> 3 (2-den ferqli,
    #   paralel fakt) -> 4 (2-nin qaydasini 3-un sirasina tetbiq edir)
    # Derslikden kenar bilik? Xeyr (#1/#2/#12/#23/#19-dan)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-durgu",
     "az8-durgu#14", "az8-durgu#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Vasitəsiz nitq dırnaq içərisində yazılır.\n"
     "2) Müəllifin sözləri vasitəsiz nitqdən ƏVVƏL gələndə, aralarında iki nöqtə qoyulur, sonra dırnaqda vasitəsiz nitq yazılır.\n"
     "3) Vasitəsiz nitq vasitəli nitqə çevriləndə isə dırnaq işarələri tamamilə götürülür.\n"
     "4) Bu qaydaya əsasən, müəllifin sözləri vasitəsiz nitqdən SONRA gələndə də aralarında iki nöqtə qoyulmalıdır.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: müəllifin sözləri "
     "vasitəsiz nitqdən SONRA gələndə fərqli işarələr (vergül/tire) "
     "qoyulur - söz sırası dəyişəndə durğu qaydası da dəyişir, «əvvəl "
     "gələndə»ki iki nöqtə qaydası bura tətbiq olunmur.",
     ["2, 3, 4", "1, 2, 3", "1, 4", "yalnız 2"], 2),

    # Cetinlik: 5/10
    # Sebeb: uc ferqli uslubun ferqli meyarini ayirmaq (terminoloji,
    #   ifade vasitesi, sened formasi), sonra ferqli meyarla qurulmus
    #   ikinci uslubu birinciye ("send formasi") yanlis aid etmek.
    # Addimlar: 1 -> 2 (1-den ferqli meyar) -> 3 (1,2-den de ferqli
    #   ucuncu meyar) -> 4 (basqa uslubu 3-un meyarina yanlis aid edir)
    # Derslikden kenar bilik? Xeyr (#24/#25/#23/#21-den)
    # Ezberle cavablandirila biler? Xeyr
    ("az-dili", "orta", "8", "az-8-metn-uslub",
     "az8-metn-uslub#16", "az8-metn-uslub#comb1",
     "Aşağıdakı mülahizələrdən hansılar doğrudur?\n"
     "1) Elmi üslubda termin və elmi sözlər üstünlük təşkil edir.\n"
     "2) Bədii üslubun əsas ifadə vasitəsi isə fərqlidir - məcazi, obrazlı dildir.\n"
     "3) Rəsmi-işgüzar üslub isə bunların heç birinə deyil, sənəd formasına (ərizə, arayış və s.) əsaslanır.\n"
     "4) Bu fərqlərə əsasən, publisistik üslub da rəsmi-işgüzar üslub kimi yalnız sənəd formasında olur.",
     "1, 2 və 3 doğrudur. 4-cü mülahizə yanlışdır: publisistik üslub "
     "əsasən mətbuatda (KİV-də) işlənir - sənəd forması ilə əlaqəsi "
     "yoxdur, tamam fərqli sahədir.",
     ["1, 4", "1, 2, 3", "2, 3, 4", "yalnız 1"], 2),

    # ---------------------------------------------------------- ingilis-dili 8

    # Difficulty: 6/10
    # Reason: apply the too/adj vs adj/enough word-order rule to two
    #   examples, then reverse the order in the trap.
    # Steps: 1,2 (parallel word-order facts) -> 3 (applies rule 2) ->
    #   4 (reverses the exact order from rule 2)
    # Outside textbook knowledge? No - grounded in #18/#19/#20/#24
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-holidays",
     "ing8v2-ing-8-holidays#21", "ing8v2-ing-8-holidays#comb1",
     "Which statements are TRUE?\n"
     "1) \"too\" usually comes BEFORE an adjective and means \"more than needed\".\n"
     "2) \"enough\" comes AFTER an adjective, not before it.\n"
     "3) \"She is not old enough to travel alone.\" means she does not have enough age to travel alone (following rule 2's word order).\n"
     "4) \"This bag is enough big.\" is grammatically correct.",
     "1, 2 and 3 are true. Statement 4 is wrong - \"enough\" must come "
     "AFTER the adjective (\"big enough\"), not before it; \"enough "
     "big\" reverses the word order fixed by statement 2.",
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 4"], 2),

    # Difficulty: 6/10
    # Reason: apply the passive-voice structure rule to two examples,
    #   then misidentify what the passive actually foregrounds.
    # Steps: 1 -> 2 (applies rule 1) -> 3 (applies rule 1 again,
    #   parallel) -> 4 (wrong claim about focus, contradicts #14)
    # Outside textbook knowledge? No - grounded in #15/#3/#23/#14
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-inventions",
     "ing8-inventions#7", "ing8-inventions#comb1",
     "Which statements are TRUE?\n"
     "1) The Passive voice is built with \"was/were + the 3rd form of the verb\".\n"
     "2) By this structure, \"The telephone was invented by Bell.\" is in the Passive voice.\n"
     "3) By the same rule, \"Radio waves were discovered by scientists.\" is also in the Passive voice.\n"
     "4) Based on these two examples, the Passive voice puts the focus on the person after \"by\" (Bell, scientists).",
     "1, 2 and 3 are true. Statement 4 is wrong - the Passive voice "
     "actually shifts focus AWAY from the doer, onto the action or the "
     "object; the \"by\" phrase is often even left out.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # Difficulty: 6/10
    # Reason: apply the "used to" meaning, then its negative form,
    #   then wrongly keep the -d in the question form.
    # Steps: 1 -> 2 (applies rule 1) -> 3 (a different, negative form
    #   of the same structure) -> 4 (mixes rule 3's -d loss with the
    #   question form, contradicts #21)
    # Outside textbook knowledge? No - grounded in #17/#18/#22/#20/#21
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-hobbies",
     "ing8-hobbies#2", "ing8-hobbies#comb1",
     "Which statements are TRUE?\n"
     "1) \"used to\" describes a habit that continued in the past but does NOT continue now.\n"
     "2) \"I used to play chess every day.\" means this was a past habit that does not continue now.\n"
     "3) In the negative form, \"used to\" loses its \"-d\": \"did not use to\", not \"did not used to\".\n"
     "4) By the same rule, the question form is \"Did you used to collect stamps?\".",
     "1, 2 and 3 are true. Statement 4 is wrong - the question form "
     "also drops the \"-d\": \"Did you USE to collect stamps?\", the "
     "same as the negative form in statement 3.",
     ["2, 3, 4", "1, 4", "1, 2, 3", "yalnız 1"], 3),

    # Difficulty: 6/10
    # Reason: apply the Past Progressive structure, then the
    #   "ongoing action interrupted" timeline twice, then reverse
    #   that timeline in the trap.
    # Steps: 1 -> 2 (applies rule 1 to a timeline) -> 3 (applies the
    #   same timeline pattern again) -> 4 (reverses the timeline from
    #   2/3)
    # Outside textbook knowledge? No - grounded in #9/#11/#16/#19
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-real-heroes",
     "ing8v2-ing-8-real-heroes#29", "ing8v2-ing-8-real-heroes#comb1",
     "Which statements are TRUE?\n"
     "1) Past Progressive is built with \"was/were + verb-ing\".\n"
     "2) \"They were helping people when the fire started.\" - \"were helping\" began BEFORE \"started\" and was still going on.\n"
     "3) \"While she was helping the child, her phone rang.\" - \"was helping\" is the LONGER action, \"rang\" is the short, sudden one.\n"
     "4) By this pattern, in \"The children were playing when the storm began.\", the storm began BEFORE \"were playing\".",
     "1, 2 and 3 are true. Statement 4 is wrong - it reverses the "
     "timeline: \"were playing\" was the ongoing action that started "
     "first, and \"the storm began\" is the short action that "
     "interrupted it, not the other way round.",
     ["1, 2, 4", "1, 4", "2, 3, 4", "1, 2, 3"], 4),

    # Difficulty: 5/10
    # Reason: apply the negative Past Progressive form, then its
    #   contraction, then flip the meaning of a negated sentence.
    # Steps: 1 -> 2 (applies rule 1) -> 3 (applies rule 1 to a real
    #   sentence) -> 4 (flips the negation entirely, contradicts #12)
    # Outside textbook knowledge? No - grounded in #9/#13/#14/#12
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-choose-kind",
     "ing8v2-ing-8-choose-kind#30", "ing8v2-ing-8-choose-kind#comb1",
     "Which statements are TRUE?\n"
     "1) In the negative Past Progressive, \"not\" comes right after \"was/were\".\n"
     "2) \"was not\" is shortened to \"wasn't\".\n"
     "3) \"He was not crying, he was just tired.\" denies that he was crying, and offers tiredness instead.\n"
     "4) By this rule, \"They were not helping the new student.\" means \"They WERE helping the new student.\"",
     "1, 2 and 3 are true. Statement 4 is wrong - it reverses the "
     "meaning of the negative sentence completely: \"were not "
     "helping\" means they did NOT help, not that they did.",
     ["1, 4", "1, 2, 3", "2, 3, 4", "yalnız 1"], 2),

    # Difficulty: 6/10
    # Reason: apply the Past Progressive question order, then its
    #   short-answer form, then subject-agreement, then swap the
    #   agreeing pronoun for a wrong one.
    # Steps: 1 -> 2 (applies rule 1) -> 3 (a different fact, subject
    #   pronoun) -> 4 (misapplies rule 3's agreement, contradicts #26)
    # Outside textbook knowledge? No - grounded in #9/#12/#16/#26
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-travel-stories",
     "ing8v2-ing-8-travel-stories#17", "ing8v2-ing-8-travel-stories#comb1",
     "Which statements are TRUE?\n"
     "1) A Past Progressive question is built as \"Was/Were + subject + verb-ing\".\n"
     "2) By this rule, the short answer to \"Was she travelling alone?\" is \"Yes, she was.\" or \"No, she wasn't.\"\n"
     "3) In \"Who was waiting at the station?\", \"Who\" refers to the subject, which is why \"was\" (not \"were\") is used.\n"
     "4) By this rule, \"you and your friends\" in \"Were you and your friends exploring the old town?\" can be replaced with \"she\".",
     "1, 2 and 3 are true. Statement 4 is wrong - \"you and your "
     "friends\" is plural and matches \"were\", so it is replaced with "
     "\"you\" (plural), not \"she\" (singular, which would need \"was\").",
     ["1, 2, 3", "2, 3, 4", "1, 4", "yalnız 1"], 1),

    # Difficulty: 5/10
    # Reason: apply the "when" vs "while" tense rule, then combine
    #   both in one sentence, then reverse which action is the
    #   longer/background one.
    # Steps: 1,2 (parallel rules) -> 3 (combines 1 and 2 in one
    #   sentence) -> 4 (reverses the long/short roles from 3)
    # Outside textbook knowledge? No - grounded in #15/#16/#13/#10
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-celebrations",
     "ing8v2-ing-8-celebrations#21", "ing8v2-ing-8-celebrations#comb1",
     "Which statements are TRUE?\n"
     "1) \"when\" is usually used with Past Simple - a short, sudden action.\n"
     "2) \"while\" is usually used with Past Progressive - a longer, ongoing action.\n"
     "3) \"While we were decorating the hall, the guests arrived.\" - \"were decorating\" (rule 2) is the longer action, \"arrived\" (rule 1) is the short one.\n"
     "4) By this pattern, in the same sentence, \"the guests arrived\" is the longer, ongoing action.",
     "1, 2 and 3 are true. Statement 4 is wrong - it reverses the "
     "roles from statement 3: \"were decorating\" is the longer, "
     "background action, and \"arrived\" is the short Past Simple one.",
     ["1, 4", "2, 3, 4", "1, 2, 3", "yalnız 2"], 3),

    # Difficulty: 6/10
    # Reason: apply can (present ability) then could (past ability)
    #   then their negative forms, then swap which modal's negative
    #   belongs to which.
    # Steps: 1 -> 2 (parallel to 1, past form) -> 3 (applies the
    #   negative of 2) -> 4 (misapplies 3's negative form to rule 1)
    # Outside textbook knowledge? No - grounded in #9/#10/#28/#18
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-art",
     "ing8v2-ing-8-art#11", "ing8v2-ing-8-art#comb1",
     "Which statements are TRUE?\n"
     "1) \"can\" is used for general present ability.\n"
     "2) \"could\" expresses the same kind of ability, but in the PAST.\n"
     "3) The negative form of \"could\" is \"could not\" (\"couldn't\").\n"
     "4) By the same rule, the negative form of \"can\" is also \"could not\".",
     "1, 2 and 3 are true. Statement 4 is wrong - \"can\"'s negative "
     "form is \"cannot\" (\"can not\"), not \"could not\"; each modal "
     "keeps its own negative form matching its own tense.",
     ["2, 4", "1, 2, 3", "1, 3", "yalnız 2"], 2),

    # Difficulty: 6/10
    # Reason: apply the "must" bare-infinitive rule, the
    #   must-vs-have-to source distinction, the "do not have to"
    #   meaning, then equate it with "must not" which means the
    #   opposite.
    # Steps: 1 -> 2 (a different, parallel fact) -> 3 (the meaning of
    #   "do not have to", contrasted with "must not") -> 4 (equates
    #   3's two opposite meanings)
    # Outside textbook knowledge? No - grounded in #9/#10/#12/#13/#15
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-environment",
     "ing8v2-ing-8-environment#18", "ing8v2-ing-8-environment#comb1",
     "Which statements are TRUE?\n"
     "1) After \"must\", the main verb comes in the bare infinitive form (no \"to\").\n"
     "2) \"must\" usually expresses the speaker's own opinion, while \"have to\" expresses an outside rule - \"You have to recycle plastic in this city.\" is a city rule.\n"
     "3) \"do not have to\" means there is NO obligation, a free choice - unlike \"must not\", which means a strict prohibition.\n"
     "4) By this, \"You do not have to buy a new bag\" means exactly the same as \"You must not buy a new bag\".",
     "1, 2 and 3 are true. Statement 4 is wrong - these are OPPOSITE "
     "meanings: \"do not have to\" = free choice, no obligation; "
     "\"must not\" = strictly forbidden.",
     ["1, 2, 4", "1, 4", "2, 3, 4", "1, 2, 3"], 4),

    # Difficulty: 5/10
    # Reason: apply the Zero Conditional structure, its general-truth
    #   meaning, the if/when swap rule, then claim a specific example
    #   describes a one-time event instead.
    # Steps: 1 -> 2 (applies rule 1's meaning) -> 3 (applies rule 2
    #   further) -> 4 (contradicts rule 2 by calling a general-truth
    #   example a one-time event)
    # Outside textbook knowledge? No - grounded in #9/#10/#13/#11
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-people-life",
     "ing8v2-ing-8-people-life#14", "ing8v2-ing-8-people-life#comb1",
     "Which statements are TRUE?\n"
     "1) Zero Conditional is built as \"If + Present Simple, Present Simple\".\n"
     "2) By this structure, it expresses a general truth that is always true.\n"
     "3) In Zero Conditional, \"if\" can be replaced with \"when\" without changing the meaning, because both describe a general rule.\n"
     "4) By this, \"If you are kind to people, they trust you.\" describes one specific, one-time event, not a general rule.",
     "1, 2 and 3 are true. Statement 4 is wrong - it contradicts "
     "statement 2: this sentence is exactly the kind of ALWAYS-true "
     "general rule Zero Conditional describes, not a one-time event.",
     ["1, 4", "1, 2, 3", "2, 3, 4", "yalnız 1"], 2),

    # Difficulty: 6/10
    # Reason: apply the First Conditional structure, split it into
    #   its two clauses, then wrongly put "will" into the if-clause
    #   too.
    # Steps: 1 -> 2 (splits rule 1 into its two clauses) -> 3
    #   (applies rule 1's meaning to a real example) -> 4 (breaks
    #   rule 2 by putting "will" in the if-clause)
    # Outside textbook knowledge? No - grounded in #9/#13/#14/#10/#11
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-modern-technology",
     "ing8v2-ing-8-modern-technology#19", "ing8v2-ing-8-modern-technology#comb1",
     "Which statements are TRUE?\n"
     "1) First Conditional is built as \"If + Present Simple, will + bare infinitive\".\n"
     "2) In the if-clause, Present Simple is used; in the result clause, \"will\" is used.\n"
     "3) This structure expresses a real, possible future condition - \"If you charge your phone tonight, it will work tomorrow.\" is an example.\n"
     "4) By this rule, \"will\" can also be used in the if-clause, since both clauses refer to the future.",
     "1, 2 and 3 are true. Statement 4 is wrong - it breaks the rule "
     "from statement 2: the if-clause always uses Present Simple, "
     "never \"will\", even though the whole sentence refers to the "
     "future.",
     ["1, 2, 4", "2, 3, 4", "1, 4", "1, 2, 3"], 4),

    # Difficulty: 5/10
    # Reason: apply the subject-when-object-is-same rule, match two
    #   specific pronouns to their reflexive forms, then wrongly
    #   match a third pronoun using only "plural" instead of person.
    # Steps: 1 -> 2 (applies rule 1 to two specific pronouns) -> 3 (a
    #   different, idiomatic use) -> 4 (misapplies rule 2's pairing
    #   logic to a new pronoun)
    # Outside textbook knowledge? No - grounded in #9/#11/#12/#14/#16
    # Answerable by rote memory alone? No
    ("ingilis-dili", "orta", "8", "ing-8-important-skills",
     "ing8v2-ing-8-important-skills#19", "ing8v2-ing-8-important-skills#comb1",
     "Which statements are TRUE?\n"
     "1) Reflexive pronouns are used when the subject and the object of the verb are the same person.\n"
     "2) By this rule, \"he\" matches \"himself\", and \"she\" matches \"herself\" - each pronoun has its own reflexive form.\n"
     "3) \"They solved the problem by themselves.\" - here \"by themselves\" means \"without help, alone\".\n"
     "4) By this rule, \"we\" also matches \"themselves\", because both are plural.",
     "1, 2 and 3 are true. Statement 4 is wrong - being plural is not "
     "enough: person also has to match. \"we\" (1st person plural) "
     "matches \"ourselves\", and \"they\" (3rd person plural) matches "
     "\"themselves\" - they are not interchangeable.",
     ["2, 4", "1, 2, 3", "1, 3", "yalnız 2"], 2),
]


def yoxla():
    gorulen = set()
    for subj, prog, lvl, topic, kohne, yeni, body, why, opts, duz in RETROFIT:
        assert yeni not in gorulen, "tekrar ext_key: %s" % yeni
        gorulen.add(yeni)
        assert yeni != kohne, "kohne ve yeni ext_key eynidir: %s" % yeni
        assert len(opts) == 4, yeni
        assert len(set(opts)) == 4, "eyni variant: %s" % yeni
        assert 1 <= duz <= 4, yeni
        for i in (1, 2, 3, 4):
            assert ("%d)" % i) in body, "mulahize %d yoxdur: %s" % (i, yeni)
        assert why.strip(), "izah bos: %s" % yeni
    print("yoxlama OK - %d birlesme sual" % len(RETROFIT))


def sql(s):
    return "'" + s.replace("'", "''") + "'"


def bend_yaz(subj, prog, lvl, topic, kohne, yeni, body, why, opts, duz):
    o1, o2, o3, o4 = opts
    p = []
    p.append("-- ------------------------------------------------------------- %s\n" % yeni)
    p.append("update public.questions set difficulty = 2 where ext_key = %s;\n\n" % sql(kohne))
    p.append("with d(ext, topic, body, why, o1, o2, o3, o4, correct) as (values\n")
    p.append(" (%s, %s,\n  %s,\n  %s,\n  %s, %s, %s, %s, %d)\n" % (
        sql(yeni), sql(topic), sql(body), sql(why), sql(o1), sql(o2), sql(o3), sql(o4), duz))
    p.append("),\n")
    p.append("kohne_q as (\n")
    p.append("  select quarter from public.questions where ext_key = %s\n" % sql(kohne))
    p.append("),\n")
    p.append("ins as (\n")
    p.append("  insert into public.questions\n")
    p.append("    (ext_key, owner_type, subject_id, level_id, topic_id, kind,\n")
    p.append("     body, explanation, difficulty, quarter, status)\n")
    p.append("  select d.ext, 'platform', s.id, l.id, tp.id, 'single',\n")
    p.append("         d.body, d.why, 3, kq.quarter, 'published'\n")
    p.append("    from d\n")
    p.append("    cross join kohne_q kq\n")
    p.append("    join public.subjects s on s.slug = %s\n" % sql(subj))
    p.append("    join public.programs p on p.slug = %s\n" % sql(prog))
    p.append("    join public.levels   l on l.program_id = p.id and l.code = %s\n" % sql(lvl))
    p.append("    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic\n")
    p.append("  on conflict (ext_key) do update\n")
    p.append("    set body = excluded.body, explanation = excluded.explanation,\n")
    p.append("        difficulty = excluded.difficulty, quarter = excluded.quarter,\n")
    p.append("        topic_id = excluded.topic_id, level_id = excluded.level_id,\n")
    p.append("        subject_id = excluded.subject_id, status = 'published'\n")
    p.append("  returning id, ext_key\n")
    p.append(")\n")
    p.append("insert into public.question_options (question_id, ord, body, is_correct)\n")
    p.append("select ins.id, o.ord, o.txt, o.ord = d.correct\n")
    p.append("  from ins\n")
    p.append("  join d on d.ext = ins.ext_key,\n")
    p.append("  lateral unnest(array[d.o1, d.o2, d.o3, d.o4]) with ordinality as o(txt, ord)\n")
    p.append("on conflict (question_id, ord) do update set body = excluded.body, is_correct = excluded.is_correct;\n\n")
    return "".join(p)


def sql_yaz():
    basliq = """-- =====================================================================
--  112_bank_cetin_birlesme.sql :
--  "Coxmulahizeli birlesme sualı" retrofit-i (CLAUDE.md, "novbeti
--  merhele" bolmesinde sened edilmis format).
--
--  Her bend: movcud CETIN (difficulty=3) sualin ozu ORTA (2)
--  seviyyeye enir - ARXIVLENMIR, movzuda qalir, kohne netice ve
--  hesabatlar toxunulmaz qalir. Onun YERINE eyni movzuda 4
--  nomrelenmis mulahize + kombinasiya variantlari olan yeni sual 3
--  (cetin) kimi yazilir.
--
--  Qayda: 4 mulahize YALNIZ hemin movzunun oz bankinda ARTIQ movcud
--  olan (evvelden dogru cavabi ile tesdiqlenmis) faktlardan qurulur -
--  yeni fakt UYDURULMUR (erken pilotdaki ders - uydurulmus elave
--  detala real sagird "derslikde yoxdur" deyib).
--
--  Elave sual novu YOX, movcud `single` novun icindedir (sxeme
--  toxunmur) - body coxsetirlidir, variantlar kombinasiya seklindedir
--  (A) 1,3  B) yalniz 1  C) 2,4  D) 1,2,3).
--
--  Yeni sual kohne sualin QUARTER-ini alt sorgu ile goturur - elle
--  yazilmir, kohne setirle uygunsuzluk yaranmasin deye.
--
--  Ehate: pilot - 1 sual/fenn (riyaziyyat, az dili, ingilis, 11-ci
--  sinif). tools/cetin_birlesme.py-in RETROFIT siyahisina yeni bend
--  elave edib yeniden isledaraq boyudulur.
--
--  Tekrar isledile biler (on conflict (ext_key) do update).
-- =====================================================================

set search_path = public, extensions;

"""
    hisseler = [basliq]
    for bend in RETROFIT:
        hisseler.append(bend_yaz(*bend))

    hisseler.append("do $$\n")
    hisseler.append("declare v_n int;\n")
    hisseler.append("begin\n")
    hisseler.append("  select count(*) into v_n from public.questions where ext_key like '%#comb%';\n")
    hisseler.append("  if v_n <> {0} then\n".format(len(RETROFIT)))
    hisseler.append("    raise exception '112: {0} birlesme sual gozlenilirdi, % tapildi', v_n;\n".format(len(RETROFIT)))
    hisseler.append("  end if;\n")
    hisseler.append("  raise notice '112 OK - % birlesme sual', v_n;\n")
    hisseler.append("end $$;\n")

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("".join(hisseler))
    print("yazildi: %s" % OUT)


if __name__ == "__main__":
    yoxla()
    sql_yaz()
