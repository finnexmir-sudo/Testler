# Qeydlər: UX yoxlaması (23.10.2026) — icra siyahısı

Mənbə: üç müstəqil yoxlama — Claude (kod sessiyası, 4 agent, yerli nüsxə), Claude (söhbət, canlı demo),
ChatGPT (canlı demo). Birləşdirilmiş tapıntılar istifadəçidədir (`Bil10_uc_hesabat_muqayise.docx`).
Sıra (istifadəçi + rəhbər, 23.10): **1** testin düzgünlüyü → **2** hesabatın düzgünlüyü → **3** alıcıların
düzgünlüyü → **4** ilk istifadə → **5** telefon rahatlığı. Bu, təsdiqlənmiş və yoxlanmalı işlər siyahısıdır,
düzəliş hesabatı deyil. **Hər bənd bağlananda üç sual yazılır: nə dəyişdi · necə yoxlandı · canlıya keçdimi.**

## Sıra 0 — xətalar (23.10)

| # | Xəta | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|---|
| 0.1 | Çap/PDF: cavab açarı «A, A, A…» (bankda düz cavab 97 % birinci variantdır) | `muellim/app.js` `ppMix()` + `paperPrint`: variantlar test+sual toxumu ilə qarışdırılır, açar eyni massivdən qurulur. Onlayn test toxunulmayıb (server orada özü qarışdırır) | `test/e2e_sira0.py` C: köhnə kodda 30/30 «A» (SINIR), yenidə 9/30 «A»; açardakı hərf çap olunmuş sualda düz variant 30/30; ikinci çap eyni açar | **bəli** — JS, `main` `7a57a2d`, 23.10 09:48 (`v=810`) |
| 0.2 | İki sinif seçiləndə başqa siniflərin sualı düşür | `db/929_generator_cox_sinif.sql`: 223-ün `generate_pick` gövdəsi hərfən, yalnız sinif şərti 103-dəki `levels` ilə | `db/test/smoke_cox_sinif.sql`: 929-suz SINIR («kənar sinifdən 17 sual»), 929 ilə keçir; generator/plan/dərs testi suite-ləri keçir | **bəli** — SQL Editor, 23.10; `canli_yoxla` 929 = true |
| 0.3 | İcmal: «… zəif gedir» yanında həmişə 0 % | `app.js`: `tp.ratio` → `tp.avg` (server `db/219` «avg» verir) | `e2e_sira0.py` A: köhnə kodda 0 % (SINIR), yenidə 68 %, `#/zm` 67 % | **bəli** — JS, `main` `7a57a2d`, 23.10 09:48 (`v=810`) |
| 0.4 | Generator: fənn dəyişəndə köhnə sinif seçili qalır | `app.js` `gsub` change: `f.levels = []` | `e2e_sira0.py` D: köhnədə 1 sinif qalırdı (SINIR), yenidə 0 | **bəli** — JS, `main` `7a57a2d`, 23.10 09:48 (`v=810`) |
| 0.5 | «Çap / PDF» iki dəfə açılır | **Dəyişiklik yoxdur — xəta deyil.** Ölçmə səhvi idi: Playwright `evaluate("window.print = function(){…}")` ifadəsinin nəticəsi funksiya olduğu üçün onu özü bir dəfə çağırır | Stack izi: 1-ci çağırış `UtilityScript.evaluate`-dən, 2-ci düymədən. `e2e_sira0.py` B: bir basış = 1 çağırış | — |
| 0.6 | Canlıda «3-ci, 4-ci, 6-ci, 9-ci sinif» | `db/930_sinif_adi_sekilci.sql`: köhnə adlar `app.ordinal_az()` ilə yenidən yazılır (24.08 düzəlişi `on conflict do nothing` ucbatından canlıya çatmamışdı) | süni köhnə adlarla: 5 ad düzəlir, ikinci dəfə 0, əl ilə dəyişdirilmiş ad toxunulmur; `canli_yoxla.sql` 930 sətri `f` → `t` | **bəli** — SQL Editor, 23.10; `canli_yoxla` 930 = true |
| 0.7 | Yayımdan sonra ~10 dəq köhnə versiya açılır (canlıda: v=809, İcmal yenə 0 %) | `sw.js`: HTML sorğusu `fetch(req, {cache: "no-cache"})` — brauzerin HTTP keşi (GitHub Pages `max-age=600`) yan keçilir, server ilə yoxlanılır | `max-age=600` verən sınaq serveri: köhnə sw.js ilə yayımdan sonra köhnə səhifə (v1), yenisi ilə dərhal yeni (v2); 301 yönləndirmə və şəbəkəsiz açılış işləyir | **bəli** — `main` `c5fb7dc`, 23.10 10:44 (`v=812`) |
| 0.8 | Çox sinifli test (9 + 10) vərəqdə və çapda «10-cu sinif» yazılır | `app.js` `testLevel()`: `gen_rule.levels` > 1 olanda «9, 10 siniflər» (testin öz sinfi 103-dəki kimi ən yuxarı qalır — qrup siyahısı üçün) | `e2e_sira0.py` E; 390 və 1280 px ekran şəkli | **bəli** — `main` `c5fb7dc`, 23.10 10:44 (`v=812`) |
| 0.9 | Generator «2 sinif arasında bərabər paylanır» deyir, test 4/6 bölünür | Mətn: «Suallar seçilmiş 2 sinfin mövzularından növbə ilə götürülür» (generator siniflərə yox, mövzulara görə növbələşdirir) | `e2e_sira0.py` D | **bəli** — `main` `c5fb7dc`, 23.10 10:44 (`v=812`) |
| 0.10 | Qrupun şagird siyahısında axtarış süzmür («Aysel», «Orxan» — 12/12 qalır; GPT canlıda tapdı) | `app.js`: seçici yeni görünüşün sətrini (`#stu a.mrow`) da tutur; yalnız **ad** ilə süzülür; heç kim tapılmayanda «… adlı şagird tapılmadı» | `e2e_sira0.py` F: köhnə kodda 12/12 (SINIR), yenidə 1/12; «gir» yalnız adda; boş hal mesajı; 390 və 1280 px ekran şəkli | **bəli** — `main` `1b21b29`, 23.10 11:04 (`v=814`) |

**Qərar (kod sessiyası, 23.10): «cavab açarı ilə» susmaya görə SÖNÜLÜ qalır.** Müəllim adətən vərəqi sinif üçün çoxlu nüsxədə çap edir; seçim yanılı gəlsə, hər nüsxəyə açar səhifəsi düşür və şagirdlərə paylanır. Bir əlavə basış açarın sızmasından ucuzdur. (Təhvil mətnində «seçili» yazılmışdı — orada yoxlayana «seçin» demək nəzərdə tutulurdu, susma halı deyil.)

Canlı yoxlama: 929 və 930-dan sonra `db/test/canli_yoxla.sql` — «929 …» və «930 …» sətirləri `true` (istifadəçi, 23.10). Canlıda düymələr hələ GPT/Claude tərəfindən yoxlanır (təhvil mətni istifadəçidədir).

### Yolda tapılanlar
- `smoke_family.sql` 4j: «Bilmirəm» cavabları mövzu **adı** ilə silinirdi (`limit 1`); eyni adlı ikinci mövzu (başqa sinif) seçiləndə 3 cavab qalırdı, 8-ci bölmə «7 sual» əvəzinə 10 görürdü. UUID-dən asılı, təsadüfi. Düzəliş: mövzu id-si ilə silinir.
- İcmal (219: şagird faizlərinin ortası) və `#/zm` (220: bütün cavabların cəmi) **iki düstur** işlədir — 67/68 kimi 1–2 bənd fərq. Sıra 2-yə (tək mənbə).
- **Bank üçün:** `inf9-texnologiya#196` izahı «Birinci variantda …» yazır — onlayn testdə variantlar qarışdırıldığı üçün indidən səhvdir. Bankda variant hərfinə başqa həqiqi istinad tapılmadı (38 958 sual yoxlandı; «A və B», «Cavab: A ∪ B» kimi həndəsə/çoxluq işarələri təsirlənmir).
- Əvvəldən sınıq testlər (bu işdən asılı deyil): `e2e_gen.py`, `e2e_assign.py`, `e2e_numune.py` — köhnə interfeys seçiciləri (`#glevel`, `#groups .gcard`), yeni (YENI) interfeysdə qeydiyyatda ilişir; `smoke_paylas.sql` — 929-suz bazada da sınır; `e2e_sagird_hesabat.py` — `panel_e2e`-də keçir, sıfırdan qurulan bazada qeydiyyatda ilişir (929-suz bazada da).

## Sıra 2 — hesabatın düzgünlüyü (23.10)

| # | Nə | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|---|
| 2.2 | Zəif mövzu 3 ekranda 3 qayda ilə: İcmal «Statistika — 5», «Nə etməli» «Paralellik — 7», faiz 65/66 | `db/931`: `#/zm`-in qaydası əsas — zəif şagird ≥ 5 cavab, < 60 %; faiz = aktiv şagirdlərin bütün cavabları. `rpc_home` və `rpc_class_report` ona çəkilir. Nəticələrdə mövzu sətri `#/zm`-ə aparır (əvvəl `#/r`) | `smoke_zeif_movzu.sql` (931-suz sınır: 73/72); `e2e_sira0` A/A2: faiz, şagird sayı bərabər, keçid basılır | `main`-ə keçəndə + SQL 931 |
| 2.3 | Gedişat 4 düsturla: Siqnallar «geriləyir», kart «↗ +10», valideyn «yaxşılaşıb», mətn | `db/932` `app.student_trend` — Siqnalların düsturu (son 3 / əvvəlki 3, 4+ test) + «son 30 gün» (valideynin böyük rəqəmi). Kart, şəkil kartı, valideynə mətn, valideyn paneli ondan. İcmal «71 % orta · keçən həftə 80 %» → Nəticələrlə eyni cümlə «keçən həftəyə görə ±N bənd». Hər ortada dövr. Abunəsizdə gedişat yoxdur (valideyn kimi) | `smoke_gedisat.sql` 1–6; `e2e_sira2` A–D; 390/1280 px | `main`-ə keçəndə + SQL 932 |
| 2.4 | «cavab» = test, səhv sayı 81 / 78 + 3, 0/3 mövzu ən zəif kimi, Siqnallar və hesabat əlifba ilə | Say «test» (Nəticələr, qrup menyusu, şagird siyahısı, hesabat); Xülasə «78 gözləyir · 3 təkrarda»; < 5 cavablı mövzu «ilkin nəticə · N sual · tarix» (çəki dəyişmir), valideyn mətninə düşmür; hesabatın Şagirdlər sekməsi ən zəifdən; `db/933` Siqnallar növün içində ən ağırdan, «ilk 8» də eyni sıra ilə | `e2e_sira2` E–G; `smoke_gedisat` 6 (933-süz sınır) | `main`-ə keçəndə + SQL 933 |

Canlı üçün SQL Editor-da ardıcıllıq: **931 → 932 → 933** (933 931-in `rpc_home` gövdəsinə əsaslanır). Sonra `canli_yoxla.sql`-da 931, 932, 933 = true.
Panel kodu SQL-dən əvvəl də canlıya gedə bilər: `trend` gəlməyəndə kart gedişat göstərmir, valideyn köhnə «keçən ay» cümləsində qalır.
Əvvəldən sınıq (bu işdən asılı deyil): `smoke_numune.sql` («197 tətbiq olunmayıb»), `e2e_valideyn.py` (köhnə `#btnGroup`).

## Sıra 3 — alıcıların düzgünlüyü (23.10)

| # | Nə | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|---|
| 3.1 | «N şagirdə təkrar verin» düyməsi testi BÜTÜN qrupa verirdi | `db/934` `rpc_assign_test_many`: bir tranzaksiyada hər seçilmiş şagirdə fərdi sətir (model 28-dən var: `student_id`), hər sətir `rpc_assign_test`-in yoxlamalarından keçir; qrupa verilmiş testə rədd. «Nə etməli», `#/zm`, İcmal mövzu sətri zəif şagirdlərin siyahısını generatora ötürür; generatorda «Kimə: Yalnız zəif olanlar · N / Bütün qrup», düymə «Testi yığ və N şagirdə ver», təsdiq adları sadalayır | `smoke_hedefli.sql` 1–6 (atomik, yad müəllim, anon); `e2e_sira3` A, B (seçilən şagird görür, seçilməyən görmür), D | panel `main` v=816 + SQL 934 |
| 3.2 | Tapşırıqlar siyahısında N ayrı sətir olardı | eyni testin fərdi sətirləri bir sətirdə: «N şagirdə» + adlar, bitirənlər cəmlənir, «×» hamısını götürür; «etməyənlər →» düzgün adlar | `e2e_sira3` C | bəli, `main` v=816 |
| 3.3 | Vərəqdə «Kimə» yalnız qrup / tək şagird | «Bir neçə şagird seçin…» — işarələnən siyahı (toxunma 44 px) | `e2e_sira3` E; 390/1280 px | bəli, `main` v=816 |

Əvvəldən sınıq (bu işdən asılı deyil): `smoke_bize_yaz.sql` («boş siyahı gözlənirdi» — köhnə bazada da).

## Qrup səhifəsi — 1-ci addım (23.10)

İstifadəçinin şərtləri: yalnız mövcud, yoxlanmış məlumat; qrafik, tamamlanan tapşırıq sayı, avtomatik rəy cümlələri SONRA; telefonda 4 sekmə + «Daha»; «son dərsin nəticəsi» plan irəliləyişi kimi göstərilmir; canlıdan əvvəl 390/1280 əvvəl–sonra şəkilləri.

| # | Nə | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|---|
| Q1.1 | Qrup səhifəsi 5 sətirlik menyu idi — bölməyə keçəndə menyu itirdi, «hansı bölmədəyəm» görünmürdü | Zolaq yığcam (Geri · ad · «sinif · N şagird» · **Test ver**). Altında sekmələr: İcmal · Şagirdlər · Tapşırıqlar · Hesabat · Dərs planı · Dəftər · ayarlar (kompüter); telefonda ilk 4 + «Daha» (Dərs planı, Dəftər, Qrup ayarları; aktivdirsə «Daha» onun adını yazır). Sekmə qrupun bütün ekranlarındadır (`#/g/id[/s/p/d/x]`, `#/a/id`, `#/r/id`), ünvanlar dəyişmir. Sekmə keçidi tarixçəyə təzə yazı yazmır (`tabGo` + `route()` `TAB_SW`) — «Geri» və brauzerin geri düyməsi qrupa haradan gəlinibsə ora | `e2e_qrup_sekme` A, A2, B (4 sekmədən sonra «Geri» → Qruplar; brauzer geri → Qruplar; sekmənin içindən şagird kartı → «Geri» → Hesabat); `e2e_qrup_menyu_telefon` (375/360: sığır, yana sürüşmə yox, 44 px); `e2e_geri`, `e2e_kecid` | bəli, `main` v=816 |
| Q1.2 | İcmal: «Bu günün dərsi» | `rpc_lesson_prep.next`: mövzu + **«Plandakı yeri» — «fəsil» · dərs N / M** və zolaq (yalnız plan yeri). **Ayrı blokda** «Son keçilən dərs · tarix»: mövzu, «X % bu dərsin testi · N şagird yazıb» (`last`). Plan yoxdursa «Planı qur» | `e2e_qrup_sekme` D: «Plandakı yeri»ndə faiz yoxdur, faiz yalnız son dərs blokunda | bəli, `main` v=816 |
| Q1.3 | İcmal: «Diqqət tələb edir» | test etməyənlər (`prep.pending`, `#/ht` ilə eyni say) → «Kim etməyib»; yazılı tapşırıq etməyənlər (`prep.hw`) → Tapşırıqlar; zəif mövzu — Hesabatın «Nə etməli»si ilə EYNİ funksiya (`repTodo`) → «Təkrar ver» (Sıra 3 yolu, həmin şagirdlərə). Heç biri yoxdursa «Hər şey qaydasındadır»; şagird yoxdursa «Qrupda hələ şagird yoxdur» + «Şagird əlavə et» | `e2e_qrup_sekme` C (say `#/ht` ilə, mövzu və şagird sayı «Nə etməli» ilə), E (keçidlər), F (boş qrup) | bəli, `main` v=816 |
| Q1.4 | İcmal: «Son tapşırıqlar», «Son nəticələr» | aktiv tapşırıqlardan ilk 3 (Tapşırıqlar sekməsi kimi qruplanır, «bitirən / hədəf») → «Hamısına bax» `#/a/id`; Hesabat · Fəaliyyətin ilk 5 sətri → «Hamısına bax» `#/r/id/f` (Fəaliyyət sekməsi açıq). Qrafik, «dəyişmə» sütunu, rəy cümləsi YOXDUR | `e2e_qrup_sekme` C: «8 / 12» Tapşırıqlar sətri ilə, 5 nəticə Fəaliyyətin ilk 5-i ilə eyni | bəli, `main` v=816 |

Əvvəl–sonra şəkilləri (390, 1280): nümunə hesab, `scratchpad/qrup/evvel_*`, `sonra_*`. Köhnə menyu testləri yeni quruluşa uyğunlaşdırıldı (`e2e_qrup_menyu_telefon`, `e2e_geri`, `e2e_kecid`, `e2e_dord_is` A).
Əvvəldən sınıq (bu işdən asılı deyil, köhnə kodla da): `e2e_dord_is` C («Test ver» səhifəsində `#pick .trow`), `e2e_tapsiriq_bos`; köhnə görünüş seçiciləri (`#btnGroup`, `#gForm`): `e2e_bugun`, `e2e_kurikulum`, `e2e_plan`, `e2e_defter`, `e2e_tovsiye`, `e2e_cedvel`.

## Şagird səhifəsi — Xülasə (23.10, GPT siyahısında 1-ci)

Şərt qrup səhifəsi ilə eyni: yalnız mövcud, yoxlanmış məlumat; canlıdan əvvəl 390/1280 əvvəl–sonra.

| # | Nə | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|---|
| Ş1.1 | Rəqəmlər bir sətirdə idi, əsası «bütün dövr» | Xülasənin başında kart: **orta · son 30 gün**, gedişat (son 3 / əvvəlki 3, Siqnallar düsturu), **test · son 30 gün**; altında kiçik sətir «N test · X % orta · bütün dövr». Son 30 gün rəqəmləri valideyn mətni ilə eyni funksiyadan (`velSay`). Abunəsizdə / 30 gündə test yoxdursa köhnə sətir; heç test yoxdursa «0 test · 0 %» yazılmır | `e2e_sagird_xulase` A (sətir = valideyn cümləsi = valideyn mətni), F; `e2e_sira2` (müəllim = valideyn paneli) | bəli, `main` v=817 |
| Ş1.2 | Zəif mövzu, səhvlər və gözləyən tapşırıq bir qarışıq kartda idi; düymə səhvlərdən test idi | **Təkrar tövsiyəsi**: ən zəif ETİBARLI mövzu (ilkin nəticə sona), «Son nəticə: X % · N sual əsasında», **«5 suallıq təkrar ver»** → generator həmin mövzu və YALNIZ bu şagirdlə; «Daha N zəif mövzu — Mövzular»; altında səhv dəftəri və «Səhvlərdən təkrar test» (köhnə düymə). **Gözləyən tapşırıqlar** ayrı kart, boşdursa «Gözləyən tapşırıq yoxdur» | `e2e_sagird_xulase` B (mövzu və faiz Mövzular sekmesindəki sətirlə eyni; generator), D (#/ht ilə eyni); `e2e_sagird_hesabat` B, G | bəli, `main` v=817 |
| Ş1.3 | «Valideynə göndər» səhifənin ən altında böyük mətn qutusu idi | **Valideyn üçün hesabat** kartı: «Son 30 gündə N test işləyib. Orta nəticə X %.» + «Mətni kopyala» + «Mətnə bax» (mətn və şəkil kartı açılır) | `e2e_sagird_xulase` E (kopyalanan = mətn); `e2e_sagird_hesabat` C | bəli, `main` v=817 |
| Ş1.4 | Son nəticələr yalnız Tarixçədə idi | **Son nəticələr**: Tarixçənin ilk 5 sətri, «Hamısına bax» Tarixçə sekmesini açır | `e2e_sagird_xulase` C | bəli, `main` v=817 |
| Ş1.5 | Diaqnostika, fərdi plan, öyrənmə tərzi Xülasəni 3 ekran uzadırdı | **Mövzular** sekmesinin sonuna köçdü (mövzu işidir); «Test tapşır → Diaqnostik test» ora aparır | `e2e_sagird_hesabat` D; `e2e_sagird_xulase` B | bəli, `main` v=817 |

Hələ edilməyib (sonraya): yığcam başlıq (qrup adı · sinif · fənn), «Giriş kodu» düyməsinin başlığa keçməsi.
Testlərdə tapılan: `e2e_tapsiriq_bos` sınanda bütün platforma testlərini `draft`-da qoyub qaytarmırdı — sonrakı testlər boş siyahı görürdü (`#pick .trow`). Bu, əvvəlki «əvvəldən sınıq» qeydlərinin bir hissəsinin səbəbidir; baza bərpa olunanda `e2e_dord_is`, `e2e_etmeyenler`, `e2e_sagird_hesabat` keçir. `e2e_dord_is` yeni qrup səhifəsinə uyğunlaşdırıldı.

## Yığcamlıq — qrup və şagird səhifəsi (24.10)

İstifadəçi: «GPT maketindəki yığcamlıq canlıda alınmayıb — başlıq, kartların daxili boşluqları və kölgələr böyükdür; telefonda bir kart ekranın çoxunu tutur. Şrifti və toxunma düymələrini kiçiltmə, artıq boşluğu azalt.»

| # | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|
| Y1 | Yaşıl başlıq bir sətirdə (Geri · ad · əsas düymə): telefonda qrup ~140 → ~80 px, şagird ~210 → ~70 px (avatar telefonda gizlənir). Şrift və 44 px toxunma dəyişmədi | 390/1280 əvvəl–sonra; `e2e_qrup_menyu_telefon`, `e2e_qrup_sekme` A2 (44 px) | bəli, `main` v=818 |
| Y2 | Kartların daxili boşluğu 16→12 (telefon 12→10), aralar 12→10, «Hamısına bax» / «Dərs planı» kartın başlığına (ayrıca alt sətir yox), sekmə zolağının ara boşluğu azaldı | eyni | bəli, `main` v=818 |
| Y3 | Kölgələr zəif (yalnız 1 px), panel fonu bir ton açıq (`--bg` #dfeee8 → #ecf5f1) | gözlə: 390/1280 | bəli, `main` v=818 |
| Y4 | «Son keçilən dərs» açılıb-bağlanan: başlıqda tarix və faiz, içində mövzu və «testi yığ». Gözləyən tapşırıq mətni telefonda 2 sətir (tam mətn «Mesajı kopyala»da) | `e2e_qrup_sekme` D (bağlı gəlir, açılır) | bəli, `main` v=818 |
| Y5 | 360 px (istifadəçi canlıda tutdu): kart başlığı «Son / tapşırıqlar · 2 / aktiv · Hamısına / bax» bölünürdü, «Diqqət» sətrində link/düymə mətni 3–4 sətrə sıxırdı. Dar ekranda başlıq bölünmür, «N aktiv» gizlənir, link və «Təkrar ver» mətnin altına keçir | 360 px əvvəl–sonra; `e2e_qrup_sekme`, `e2e_dord_is` | bəli, `main` v=819 |
| Y6 | Ölçü yoxlaması (istifadəçi: «yığcamlıq yazı və düymənin kiçilməsi hesabına olmasın»): telefonda başlıq 23.10-da 20→18 (qrup), 22→18 (şagird) endirilmişdi — **qaytarıldı**; «Test ver» 40, «Təkrar ver» 32, «Kim etməyib» 36, şagird səhifəsinin düymələri 32 px idi — hamısı **44 px**. 360 px-də rəqəmlər kartında gedişat ayrıca sətirdə, şagird başlığında qısa ad gizlənir (kod qalır) | ölçülər əvvəl/sonra eyni səhifədə (`getComputedStyle`); `e2e_qrup_sekme` A2, `e2e_sagird_xulase` G (≥ 44 px, 20/22 px) | bəli, `main` v=819 |

## Sıra 1–5 — gözləyir

1. **Testin düzgünlüyü** — 0.1, 0.2, 0.4 bağlandı (yuxarı). Qalan: tək pis sualı əvəz etmək (vərəqdə).
2. **Hesabatın düzgünlüyü** — **bağlandı (yuxarı, Sıra 2)**. Əvvəlki siyahı: «zəif mövzu», «orta», «gedişat» bir sorğu və bir qayda; hər rəqəmdə dövr («bütün dövr» / «son 30 gün»); «test / sual / cavab» sözləri; az məlumatlı mövzu «ilkin nəticə · N sual · tarix» nişanı (çəki avtomatik dəyişmir); hesabat və Siqnallarda «ən zəifdən» sıra (davamiyyət və adi siyahı əlifba qalır).
3. **Alıcıların düzgünlüyü** — **bağlandı (yuxarı, Sıra 3)**. Əvvəlki siyahı: tövsiyədəki şagirdlərə hədəfli tapşırıq: seçim, saxlama (tapşırıq modeli indi yalnız qrup / tək şagird) və şagirdin gördüyü tapşırıqlar birlikdə; şəxsi testin səhvən qrupa verilməsinin qarşısı.
4. **İlk istifadə** — boş qrupda «Şagird əlavə et»; yapışdırma ilə toplu əlavə; kodların toplu kopyası və çapı; başlanğıc kartı işlək yola; qrupun sinfinə uyğun test; server xəta mətnlərində diakritika.
5. **Telefon** — başlıq bloku, şagird Xülasəsi, bölmələrarası keçidlər; təkrar yollar azalır, yerində olan «Təkrar ver» qalır.
