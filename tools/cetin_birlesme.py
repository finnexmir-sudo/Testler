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
