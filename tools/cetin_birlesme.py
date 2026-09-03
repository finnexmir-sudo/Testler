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

Ehate: pilot - 3 sual/fenn (riyaziyyat, az dili, ingilis, 11-ci
sinif). Boyutmek ucun RETROFIT-e yeni bend elave edib yeniden islet.

Islet:  python3 tools/cetin_birlesme.py
Netice: db/112_bank_cetin_birlesme.sql
"""
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(KOK, "db", "112_bank_cetin_birlesme.sql")

# her bend: (fenn_slug, proqram_slug, sinif_kodu, movzu_slug,
#            kohne_ext_key, yeni_ext_key, body, izah, [4 variant], duz_ord)
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
     ["1, 3", "1", "2, 4", "1, 2, 3"], 1),

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
     ["1, 3", "1", "2, 4", "1, 2, 3"], 1),

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
     ["1, 2, 3", "1, 2, 3, 4", "2, 3, 4", "1, 3"], 1),

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
     ["1, 2, 4", "1, 2, 3", "2, 3, 4", "1, 3, 4"], 1),

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
     ["2, 3", "1, 2", "1, 3, 4", "2, 3, 4"], 1),
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
