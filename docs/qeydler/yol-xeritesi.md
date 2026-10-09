# Qeydlər: Yol xəritəsi — bütün nömrələnmiş maddələr

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## Yol xəritəsi

Sıra ilə (istifadəçi ilə razılaşdırılıb):

1. ~~Ödəniş axını (mərhələ 1)~~ — hazırdır: «Paket» səhifəsi
   (`#/p`, WhatsApp satışı, `CONTACT_WHATSAPP` config-də) + admin
   idarəetməsi (`#/adm`, `db/21_paket.sql`). İlk admin SQL ilə:
   `insert into user_roles (user_id, role) select id,'admin' from
   auth.users where email='...'`. Mərhələ 2 (kart ödənişi,
   Payriff/Epoint) müştəri sayı artanda.
   Admin **2FA ilə qorunur** (`db/24_admin_2fa.sql`): TOTP
   (Authenticator tətbiqi) + 4 birdəfəlik ehtiyat kod; kilid 12 saat,
   kod cəhdi 10 dəq/5. `app.admin_ok()` = rol + açılmış kilid — bütün
   admin RPC-ləri bu qapıdan keçir. Telefon itsə: SQL Editor-də
   `delete from admin_totp` kilidi sıfırlayır.
   **Səhv bildirişləri** (`db/23_bildiris.sql`): müəllim vərəqdən,
   şagird nəticə ekranından sualı bildirir (`question_reports`);
   admin `#/adm`-də baxır, platforma sualını **yerində düzəldir**
   (`rpc_admin_fix_question` — variant id-ləri qorunur) və ya rədd
   edir. Bildiriş suala toxunmur — qərar həmişə admindədir.
2. ~~Sual bankının davamı~~ — hazırdır: **1-11-ci siniflər**
   (ibtidai + orta + yuxarı, ingilis dili daxil, 11 fənn).
   Tarix **iki ayrı fənndir**: «Tarix» (Azərbaycan tarixi) və
   «Ümumi tarix» — məktəbdə də ayrı dərslik, ayrı qiymətdir.
   Ümumi tarix **6-11-ci siniflərdədir** (10 daxil): 6 qədim dünya,
   7 orta əsrlər, 8 yeni dövr (XVI-XVIII), 9 XIX əsr, 10 icmal kursu,
   11 XX-XXI əsrlər. Fayllar: `db/53`, `54` (9 və 11);
   `db/66` + `db/67` (6, 7, 8 — 18 mövzu × 31 = 558,
   `tools/tarix_umumi68.py`); `db/68` + `db/69` (10 — 6 mövzu × 31 = 186,
   `tools/tarix_umumi10.py`).
   **10-cu sinifdə «Tarix» (Azərbaycan tarixi) yoxdur** — e-dərslik
   portalında o sinif üçün yalnız «Ümumi tarix» dərsliyi var
   (`mundericat/tarix-10-745.txt`). `45` artıq `tarix-10-*` mövzularını
   açmır, `47`/`tools/sinif10.py` isə həmin 180 sualı daşımır; köhnə
   baza üçün `68` onları `umumi-tarix`ə köçürüb `archived` edir
   (silinmir — hesabat tarixçəsi qorunur).
   **7-ci sinifdə də «Tarix» yoxdur** — eyni səbəbdən
   (`mundericat/tarix-7-723.txt` «Umumi tarix» yazır). `db/70` + `db/71`
   həmin 180 sualı `umumi-tarix`ə köçürür. Köhnə altı mövzudan yalnız
   **ikisi** yeni mövzudur (türk dövlətləri; Səlcuq-Monqol-Osmanlı),
   qalan dördü **icmal** mövzusu olduğu üçün sualları `66`-nın altı
   mövzusuna **dənə-dənə** paylanıb — yoxsa eyni mövzu iki dəfə yaranıb
   zəif nöqtə hesabatını bölərdi. 7-ci sinif Ümumi tarix: 8 mövzu,
   366 sual. Köçürülənlərin `ext_key`-i **`tarix7-` olaraq qalır**
   (canlı bazadakı sətirlər yerində yenilənsin deyə; `utarix7-`
   prefiksi `67`-də artıq işlənib).
   **Ədəbiyyat ayrıca fənndir** — «Az dili» mövzuları yalnız
   qrammatikadır, ədəbiyyatın öz dərsliyi və qiyməti var.
   Hazırdır: **5-11-ci siniflər** — 48 mövzu × 31 = 1488 sual
   (`db/55`, `56`, `58`, `59`, `60`, `61`, `62`, `63`, `64`, `65`;
   `tools/edebiyyat5…11.py`). Mövzu sayı dərsliyin **öz bölmə sayıdır**:
   5→7, 6→5, 7→5, 8→7, 9/10/11→8. 5-7-ci sinifdə bölmələr **tema**
   üzrədir («Yurd sevgisi», «Təbiətin gözəlliyi»), 8-11-də isə **dövr**
   üzrə — dərslik özü belə qurub, süni bölgü edilməyib.
   **Müasir müəlliflərin tələsi:** 5-7-ci sinif dərsliyində mətnini
   bilmədiyim çoxlu müasir müəllif var. Onların süjet təfərrüatı
   uydurulmur — sual mündəricatdan çıxan faktlar üzərində qurulur:
   müəllif-əsər cütü, bölmə, ədəbi növ, mündəricatın göstərdiyi janr.
   **Tələ:** eyni müəllif iki sinifdə olur (Vurğun, R.Rza, Şıxlı,
   Vahabzadə…), amma dərslik hər sinifdə BAŞQA əsərini verir. Sual
   həmin sinfin əsərinə görə yazılmalıdır — yoxsa siniflər arasında
   pg_trgm təkrarı çıxır.
   Riyaziyyat 1-11-də hər mövzuda **40 sual**, Az dili 3-11,
   ingilis 5-11, tarix 5-11 və təbiət fənləri
   (fizika/kimya/biologiya/coğrafiya) **30 sual**, qalanlarda
   **20 sual**, ədəbiyyatda və ümumi tarixdə **31 sual**
   (cəmi ~18 870 platforma sualı).
   Mövzu ağacları `db/25/29/33/37/41/45/49_movzular_orta*.sql`,
   banklar `db/30–52`, `54`, `56`, `59`, `60`, `62–65`, `67`, `69`, `71`,
   `75–81` (1, 2 və 5-ci sinif — əvvəl 23–29-da idi, bölgüyə görə köçürüldü).
   **«Tarix» fənni artıq 5, 6, 8, 9, 11-ci siniflərdədir** — 7 və 10-cu
   sinifdə Azərbaycan tarixi dərsliyi portalda yoxdur, hər ikisinin
   məzmunu «Ümumi tarix»dədir.
   **MİQ və sertifikasiya kataloqdan çıxarıldı** (`db/72_bos_fennler.sql`):
   «Kurikulum» fənni, `miq` və `sertifikasiya` proqramları illərlə boş
   qalmışdı — müəllim paneldə boş fənn və boş proqram görürdü. Bunlar
   **ayrı məhsuldur**: mənbəyi e-dərslik dərsliyi deyil, DİM proqramıdır;
   mövzu ağacı, çətinlik ölçüsü və qiymətləndirmə məntiqi də başqadır.
   Hazır olanda eyni slug-larla geri qaytarıla bilər — `04_seed.sql`-də
   nümunə sətirlər şərhdə saxlanılıb. `72` silmədən əvvəl hər sətrin boş
   olduğunu yoxlayır, bir mövzu/sual/qrup/test bağlıdırsa **dayanır**.
   `buraxilis` proqramı da silindi (`db/73_buraxilis_proqrami.sql`) —
   **səbəb məzmun deyil, forma:** `programs → levels → classes` müəllimin
   qrup yaratdığı ağacdır, repetitor isə «Buraxılış» qrupu yaratmır,
   «11-ci sinif» qrupu yaradıb ona buraxılış **tipli test** verir. Üstəlik
   real buraxılış imtahanı çoxfənnlidir, `tests.subject_id` isə tək və
   `not null` — bir test sətri tam imtahanı tuta bilmir. Ona görə
   buraxılış hazırlığı **imtahan şablonu** kimi qurulacaq (bax yol
   xəritəsində «Buraxılış sınaq imtahanı»). Kataloq: **2 proqram**
   (ibtidai, orta), 11 sinif, 14 fənn (2026-09-11: **Zəfər tarixi**
   (yalnız 9-cu sinif) və **Ortaq türk tarixi** (yalnız 8-ci sinif)
   əlavə olundu — e-derslik.edu.az kataloq auditində tapılan, əvvəllər
   izlənməyən iki müstəqil dərslik, `bil10-bank/db/236-238`. Hər ikisi
   «Tarix»dən ayrıdır — ayrı dərslik, ayrı qiymət, ədəbiyyat kimi eyni
   məntiq. 9+7=16 movzu, 496 sual, hər movzuda ≥12 çətin sual (yeni
   fənn ilk gündən norma ilə qurulub, retrofit lazım olmadı).
3. ~~Dərs planı bölgüsü~~ — hazırdır (`db/25_ders_plani.sql`): qrupda
   fənn+sinif seçilir, mövzular dərslik ardıcıllığı ilə plana düzülür.
   Plan TARİXLƏ yox, ARDICILLIQLA yaşayır («keçildi» deyilməyincə cari
   mövzu dəyişmir). «Keçildi» → təklif: «N suallıq yoxlama testi
   yığılsınmı?» → `rpc_plan_test` generatoru işlədir və qrupa dərhal
   tapşırıq verir (+7 gün, 1 cəhd). Keçilmiş mövzudan sonradan da test
   yığılır («test yığ»); bir neçə keçilmiş mövzu seçilib **birgə qarışıq
   test** də mümkündür (`rpc_plan_test_multi` — item-ə bağlanmır).
   Pullu qapı: yaratma/keçildi/test
   abunə istəyir, baxış sərbəstdir. Mərhələ 2 (sonra): mövzu testi
   zəif çıxanda növbəti dərsdən əvvəl xəbərdarlıq + düzəliş testi.
   **Tədris fənləri** (`db/26_fenn.sql`): hesabda `subjects text[]`
   (slug siyahısı) — quruluşda və `#/me` profilində (yuxarıdakı ada
   klik) seçilir, `rpc_set_subjects` yazır. Bank/generator/plan fənn
   siyahıları buna görə daralır — **filtrdir, məhdudiyyət deyil**: boş
   siyahı və ya uyğunsuzluq = tam siyahı. `rpc_my_context` 26-da
   genişləndirilib (06-nı dəyişəndə 26-dakı kopyanı da yenilə).
   **Alt mövzular** (`topics.parent_id`, `db/101_ders_plani_alt.sql` +
   `db/74_alt_movzular_riy8.sql` + `db/82_alt_movzular_riy5_11.sql`):
   plan yalnız mövzu başlığı ilə işləyəndə müəllim «Kvadrat tənliklər»in
   2 dərsini keçəndə qeyd edə bilmirdi — ya hamısını «keçildi» edirdi
   (yalan), ya heç nə. **Riyaziyyat 1-11-in 5-11 hissəsi bitib**:
   8-ci sinif `74`-də (müəllim yoxlayıb təsdiqləyib), qalan altı sinif
   `82`-də, ibtidai `83`-də — cəmi **769 alt mövzu** (1:70, 3:73,
   4:69, 5:89, 6:85, 7:63, 8:74, 9:92, 10:77, 11:77). **Həyat bilgisi
   1-4** də hazırdır (`84`, 125 alt mövzu — dərslik və baza dörd
   sinifdə də bire-bir uyğundur), **İnformatika 1-11** də (`85`,
   348 alt mövzu), **Fizika 6-11** də (`86`, 344 alt mövzu),
   **Kimya 7-11** də (`87`, 280 alt mövzu). Adlar e-dərslikdən eynilə,
   dərslikdəki sıra ilə. `82`/`83`/`84`/`85`/`86`/`87` əllə yazılmır —
   `tools/alt_movzular.py` çıxarır (paket-paket konfiqurasiya).
   **Ağac hər fənndə eyni formada deyil** — generator dörd hal tanıyır:
   bölmə → bir mövzu; bölmə **buraxılır** (informatika 5 «Giriş»,
   11 «Layihələr üçün yardımçı materiallar»); bölmə **səhifəyə görə**
   ikiyə bölünür (riyaziyyat 4 «Adi və onluq kəsrlər», informatika 2);
   bölmə **alt başlığa görə** bölünür (informatika 1, 3, 4 — alt başlıq
   nömrəsizdir və özündən sonrakı dərslə eyni səhifədədir, ona görə
   dərs sayılmır). İki bölmə bir mövzuya da düşə bilər (informatika
   10, 11; fizika 10-un V fəsli III-ə) — sətirlər birləşir, sort
   davam edir; bölmə **bir neçə səhifə sərhədi ilə növbələşərək**
   iki mövzuya paylanır (fizika 9 «İşıq hadisələri» — yayılma/qayıtma
   → güzgü → sınma → linza/göz sırası ilə iki dəfə keçid edir,
   sərhədlər 123/133/145; bölmə adları eyni qalır, movzu dəyişir).
   Dərslikdə mündəricat mötəbər olmaya bilər: fizika 7-də «Bölmə 4.
   Atomun quruluşu və ölçüsü» başlığı portalın öz mündəricat
   panelində ayrıca bölmə kimi deyil, əvvəlki bölmənin sətri kimi
   görünür (portal qüsuru) — generator bu sətri silib sərhəd kimi
   işlədir.
   **Kimya 9 və 11-ci sinifdə daha da dərindir**: dərslikdə cəmi
   3-4 böyük bölük var («I. METALLAR», «I. Hissə»), hər biri özünün
   içində «Fəsil N.» başlıqları ilə bir neçə mövzuya bölünür (kimya 9:
   sərhədlər 23/89/121; kimya 11: 50/97/118). «Fəsil N.» başlıqları
   (bəzən böyük, bəzən kiçik hərflə) mövzu deyil — hər biri ayrıca
   `xaric_ad`da adı ilə sadalanıb, səhifə üst-üstə düşmə riski
   olduğu üçün ümumi «bölmə başlığı» qaydasına (informatika kimi)
   güvənilmədi.
   **Slug generatorunda tələ tapıldı və düzəldildi**: bir bölmədə
   iki fərqli mövzunun başlıqları demək olar eyni sözlərlə qurulubsa
   (kimya 10 — «Alkadienlərin homoloji sırası…» / «Tsikloalkanların
   homoloji sırası…»), hər sözün öz kiçik qrupda «təkrarsız» sayılması
   səhv uzun slug seçirdi (`"-".join(tek)` heç bir hədd qoymadan bütün
   sözləri birləşdirirdi, halbuki qısa `ilk+son söz` namizədi
   arxada qalırdı). İndi bu namizəd 3 sözlə həddlənib — köhnə
   fayllar (82-86) təsirlənmədi, çünki fərq yalnız NƏ vaxt hədd
   aşılanda işə düşür.
   **Böyük hərflə yazılış toxunulmur**: informatika 3 və 4-ün
   başlıqları kitabın özündə də tam böyük hərflədir
   (`<h3>1. İNSAN VƏ İNFORMASİYA`), portal qüsuru deyil.
   **Azərbaycan dilinə alt mövzu yazıla bilməz** — dərslik temaya görə
   bölünüb («Fərd və toplum»), bizim ağac isə qrammatikadır; mündəricat
   plana «Qəribə heyvanlar» yazardı.
   **Alt mövzu gələn kimi iki yer sındı** (`db/105` düzəldir):
   `rpc_plan_test_multi` alt mövzunu valideynə yönəltmirdi (birgə
   qarışıq test «0 fərqli sual tapıldı» verirdi), `rpc_bank_facets`
   isə `p_pool` verilmədikdə alt mövzuları da qaytarırdı — sual yazma
   formasında siyahı 12-dən 85-ə çıxır, «Ümumiləşdirici tapşırıqlar»
   11 dəfə təkrarlanırdı. İkisi də `db/74` ilə artıq canlı idi.
   **Test yazanda**: plan YARPAQLARDAN dolur — mövzu sayını yox,
   yarpaq sayını gözlə; `.plan summary` seçicisi fəsil `<summary>`-si
   ilə toqquşur (`.plan details:not(.plgrp) > summary` yaz).
   **Alt mövzuya sual bağlanmır** — bank və generator yalnız sualı olan
   mövzuları göstərir, ona görə alt mövzular o ekranlarda görünmür.
   **Riyaziyyat 2 istisnadır** — portaldakı nəşr köhnədir (yalnız
   20-yə qədər, 2 bölmə), ona görə alt mövzusu yoxdur; `test/e2e_plan.py`
   məhz buna görə düz plan yoxlamalarını 2-ci sinifdə aparır.
   **Portalın mündəricat paneli etibarlı deyil**: düstur simvollarını
   atır (9-cu sinifdə 11 ad, 8-ci sinifdə 1), 10-cu sinfin 9/10-cu
   bölməsini isə rus nəşrindən yığıb (16 ad). Doğru ad kitabın öz
   səhifə başlığından götürülür — `82`-nin başlığında hamısı sadalanıb.
   Silmək əvəzinə **adı yenilə** (`db/102` silməni bloklayır): slug
   qalır, plan və «keçildi» tarixçəsi qalır.
4. ~~Vərəqin çap/PDF görünüşü~~ — hazırdır (`paperPrint()` + `@media
   print` `muellim/app.css`-də). «Çap / PDF» şagird nüsxəsini verir
   (ad/tarix/bal xanaları, A) B) C) hərflənmiş variantlar, açıq suala
   cavab xətti — cavab izi YOXDUR); «Cavab açarı ilə» sonuna ayrıca
   açar səhifəsi əlavə edir. Kitabxana yoxdur — brauzerin öz çap
   pəncərəsi, orada «PDF olaraq saxla». Hər səhifənin altında **su
   nişanı**: `Bil10 · çap edən müəllimin adı · tam tarix` — maneə deyil,
   izlənəbilirlik (və vərəq valideynə gedəndə pulsuz reklam). Altlıq
   `<tfoot>` ilə qurulub: `position:fixed` çoxsəhifəli vərəqdə mətnin
   üstünə düşürdü.
5. ~~Dinamika qrafiki~~ — şagird hesabatında mini sütun qrafiki var
   (son 12 test, rəng dərəcəli); həftəlik aqreqasiya gələcəyə qalır.
6. ~~«Səhvlər üzərində iş»~~ — hazırdır (`db/27_hesabat.sql`):
   `rpc_remedial_test` şagirdin səhv etdiyi sualların özündən test yığıb
   qrupa tapşırıq verir (hesabatda «Bu səhvlərdən təkrar testi yığ»).
   Əlavə: `rpc_attempt_sheet` — cəhdin cavab vərəqi (seçilən/düz cavab);
   `rpc_student_report` genişlənib (27-də override): mövzular eşiksiz +
   `min_answers` («az məlumat» nişanı), weak-də mövzu teqi + `qid`.
   Hamısı ödənişli qapının arxasındadır; 08-i dəyişəndə 27-dəki
   kopyanı da yenilə.
7. ~~Fərdi tapşırıq~~ — hazırdır (`db/28_ferdi_tapsiriq.sql`):
   `assignments.student_id` (**boş = bütün qrup**, köhnə sətirlərdə boş
   qalır — davranış dəyişmir). Unikallıq `(class_id, test_id, student_id)`
   `nulls not distinct` ilə. Müəllim tapşırıq ekranında və vərəqdə «Kimə»
   seçir. **Səbəb:** «səhvlər üzərində iş» testi bir şagirdin səhvlərindən
   yığılır, amma qrupdakı hamıya — adında həmin şagirdin adı ilə —
   görünürdü; indi yalnız sahibinə gedir. `rpc_assign_test`-ə beşinci
   parametr əlavə olundu, ona görə **köhnə 4 arqumentli funksiya silinir**
   (yoxsa PostgREST iki namizəd arasında seçim edə bilmir).
   `rpc_available_tests`-də `assigned` artıq yalnız QRUP təyinatını
   bildirir (`assigned_n` = neçə şagirdə fərdi verilib).
   **Tələ:** `rpc_assign_test`-in mənbəyi `09_assignments.sql`-dir —
   `10_teyinat_migrasiya.sql` `run.sh`-də yoxdur və orada abunə qapısı
   yoxdur; oradan kopyalama.
8. ~~PWA quraşdırma~~ — hazırdır. Üç tətbiq ayrıca quraşdırılır:
   `muellim/`, `sagird/`, `valideyn/manifest.json` (fərqli ad, start_url,
   tema rəngi), ikonlar `assets/icons/` (192/512 + maskable). **Kökdə də
   `manifest.json`** var (ad «Bil10», `scope ./` = bütün sayt): ana
   səhifə və `komek/` onu göstərir — ana səhifədən quraşdırılan tətbiqin
   içində panel/şagird/valideyn/bələdçi linkləri brauzer zolağısız açılır
   (canlı şikayət: ana səhifə «vebdə açılmış kimi» görünürdü). Kökdə
   **bir** `sw.js`; `assets/pwa.js` kök ünvanı öz `src`-indən çıxarır
   (`ROOT + "sw.js"`, `{scope: ROOT}`) — əvvəlki `"../sw.js"` kökdəki ana
   səhifədə saytı tərk edirdi. `pwa.js` həm qeydiyyatı, həm «Ana ekrana
   əlavə et» zolağını idarə edir; ana səhifə və bələdçi də onu yükləyir.
   **Qaydalar — pozma:** (1) Supabase sorğuları HEÇ VAXT keşlənmir — sw.js
   yalnız öz mənşəyini emal edir; (2) HTML network-first, yoxsa `./bump.sh`
   ilə buraxılan yeni versiya istifadəçiyə çatmaz; (3) service worker yalnız
   `https`-də qeydiyyatdan keçir — e2e 127.0.0.1-də işləyir, keş yoxlamaları
   qeyri-müəyyən etməsin. Oflayn rejim **vəd edilmir**: yalnız karkas keşlənir.
   iOS-da `beforeinstallprompt` yoxdur — Safari üçün ayrıca izah zolağı çıxır.
9. ~~Cavab qaralaması~~ — hazırdır (`sagird/app.js`). Şagird cavab
   seçəndə və sual dəyişəndə vəziyyət `localStorage`-a yazılır
   (açar `sagird_qaralama`, cəhd id-si ilə açarlanır, 2 gün / ən çox
   5 cəhd saxlanılır). Eyni cəhd yenidən açılanda cavablar və mövqe
   qaytarılır, bir dəfəlik «N cavabınız qaytarıldı» bildirişi çıxır;
   uğurlu göndərişdən sonra qaralama silinir.
   **Səbəb:** cavablar yalnız yaddaşda idi — telefon sönsə, brauzer
   səhifəni atsa itirdi. **Server tərəfində heç nə dəyişmir**, bal
   yenə serverdə hesablanır, düzgün cavab klientə düşmür.
   Bu, oflayn rejim DEYİL — yalnız qısa bağlantı kəsilməsini keçirir.
10. ~~Tapşırıq ekranından test yığmaq~~ — hazırdır (`muellim/app.js`).
   «Yeni tapşırıq» bölməsi test YARATMIR, mövcud testi qrupa yönəldir —
   müəllimlər bunu qarışdırırdı («siyahıda yalnız köhnələr var, yenisini
   haradan yığım?»). İndi altında «Yeni test yığ» düyməsi var:
   generatora keçir, qrupun sinfi süzgəcə avtomatik qoyulur, test hazır
   olan kimi həmin tapşırıq ekranına qayıdır və siyahıda **seçilmiş**
   gəlir. Son tarix / cəhd sayı / «tək şagird» seçimi müəllimdə qalır —
   generator öz-özünə tapşırıq vermir (ona görə oradakı «Qrupa tapşırıq
   ver» sahəsi bu yolda gizlənir).
   Niyyət `GF.back`-də saxlanılır və `route()` generatordan çıxan kimi
   onu **təmizləyir** — yoxsa sonra adi «Test yığ»dan girəndə müəllim
   gözlənilmədən tapşırıq ekranına atılardı.
   Testin sinfi qrupun sinfindən fərqlidirsə siyahıya düşmür — o halda
   səbəb yazılır, test isə bazada qalır.
11. ~~Sual bankında əhatə görüntüsü~~ — hazırdır
   (`db/29_bank_katalog.sql` + `muellim/app.js`). Platforma hovuzu
   düz 50 sual tökürdü, sətirlər `disabled` idi (müəllim platforma
   sualını nə açır, nə redaktə edir), üstəlik `rpc_bank_list`
   `order by created_at desc` işlədiyi üçün ekranda **yalnız ən son
   yazılan sinfin kəsiyi** görünürdü — 1860 sualdan 50-si, hamısı
   11-ci sinif. Müəllim elə bilirdi bankda ancaq bu var.
   İndi platforma/hamısı hovuzunda siyahı yerinə **əhatə** gəlir:
   fənn → siniflər (sayla) → mövzular (say + asan/orta/çətin bölgüsü).
   Mövzuya basanda **3 nümunə sual** variantları və düz cavabı ilə
   açılır — `rpc_bank_samples`, server 3-də kəsir, abunə tələb
   olunmur (bu, satış ekranıdır: müəllim aldığı şeyin keyfiyyətini
   almazdan əvvəl görməlidir; test yığmaq yenə abunə istəyir).
   Əlavə üç düzəliş: «Daha 50 sual göstər» — `p_offset` həmişə 0
   göndərilirdi, 51-ci suala çatmaq mümkün deyildi; sətirdə süzgəcdə
   onsuz da seçilmiş fənn/sinif təkrarlanmır; mövzu nişanları 20-dən
   çox olanda sinif tələb olunur (şərt **saya** bağlıdır, hovuza yox —
   öz bankı kiçikdir, orada sinif istəmək artıq maneədir).
   Axtarış yazılanda və ya mövzu/çətinlik seçiləndə adi siyahıya
   qayıdılır — orada müəllim konkret sual axtarır; nişanlar da
   yalnız orada çıxır (kataloqda eyni adlar iki dəfə yazılırdı).
   **Sorğu nəsli:** `guard()` yalnız ünvanı tutuşdurur, bank
   ekranında isə hovuz/süzgəc dəyişəndə ünvan (`#/b`) dəyişmir —
   köhnə sorğunun cavabı təzə render-in üstünə düşürdü (seqmentdə
   «Platforma», siyahıda müəllimin öz sualları). `BFSEQ`/`BSEQ`
   sayğacları bunu bağlayır. Yoxlama üçün mock `X-Test-Delay`
   başlığını tanıyır — yarışı deterministik yaratmağın başqa yolu
   yoxdur (mock çoxaxınlıdır).
   **Sual yazma formasında (`#qtop`) da eyni sinif tələ var idi** —
   bank e2e-si (`test/e2e_bank.py`, F0 bölməsi) mövzu ağacı böyüdükcə
   (fizika 6-11 əlavəsi ilə `topics` cədvəli xeyli genişlədi) sabit
   `wait_for_timeout(900)` bəzən kifayət etmirdi: `#qlev`/`#qsub`
   dəyişəndə köhnə siyahı ekranda qalır, yoxlama səhv sinif/fənnin
   mövzularını görürdü. Sabit gözləmə yerinə `loadTopics()`-in
   `#qtop`-u yenidən aktivləşdirməsini (`disabled=false`) gözləyən
   `wait_for_function` qoyuldu — bank ekranındakı kimi ayrıca sayğac
   yazmadan, mövcud disabled/enabled keçidindən istifadə edir.
12. Riyaziyyat 2 mövzularının yenilənməsi
   (portala yeni nəşr gələndə).
13. ~~Sinif (level) modeli~~ — hazırdır (`db/100_seviyye_modeli.sql`).
   **Səhv:** panel qrup yaradanda həmişə `p_program_slug: "ibtidai"`
   göndərirdi, `rpc_create_class` isə sinfi **həmin proqramın içində**
   axtarırdı. 8-ci sinif `orta`-dadır → sorğu boş qayıdırdı → qrup
   **səssizcə sinifsiz** yaranırdı (xəta yox, xəbərdarlıq yox).
   1-4 işləyirdi, 5-11 yox. Zənciri uzundur: sinifsiz qrupda
   `rpc_available_tests` sinif süzgəcini söndürür, ona görə tapşırıq
   ekranına bütün fənlərin, bütün siniflərin testləri tökülürdü.
   **Düzəliş:** sinif birincidir, proqram ondan **törəyir** —
   çağıran tərəf proqramı bilmək məcburiyyətində deyil. Rəqəm kodlu
   siniflər üzrə təkrarsızlıq **qismən unikal indekslə** qorunur
   (`levels_sinif_kodu_tek`), yəni 9/10/11 təkrarı bir daha yarana
   bilməz. MİQ/sertifikasiya səviyyələrinə toxunulmur — kodları
   rəqəm deyil. Mövcud qruplarda `program_id` sinifə uyğunlaşdırılır.
14. **Sınaq imtahanı rejimi** (buraxılış / qəbul) — araşdırılıb, təcili
   deyil. Qərar: məzmun deyil, **alət** qururuq — qəlib → hər həftə
   yeni variant → sınaqdan-sınağa trend (sıra əsaslandırması və rəqabət
   mövqeyi ayrıca saxlanılıb).
   Rəsmi mənbə: DİM → Fəaliyyət → Qəbul və imtahanlar → Yekun
   qiymətləndirmə (menyuda «Sənədlər»də deyil).

   | İmtahan | Tapşırıq | Vaxt | Bal | Avtomatik yığıla bilən |
   |---|---|---|---|---|
   | 11-illik buraxılış (qəbul I mərhələ) | 85 | 3 saat | 300 | **56%** |
   | 9-illik buraxılış | 81 | 3 saat | 300 | **77%** |
   | Qəbul II mərhələ | 90 | 3 saat | 400 | **~82%** |

   I mərhələ 3 fənndir (tədris dili, riyaziyyat, xarici dil);
   **qalan fənlər II mərhələdədir** — 6 ixtisas qrupu, çəki əmsalları
   ilə, yəni bankın 11 fənnindən 10-u işlənir.

   **Dizaynı müəyyən edən dörd fakt:**
   - Yazılı açıq suallar **2× çəki** daşıyır. Ona görə yalnız qapalı
     hissədən 300-lük şkalaya **proporsional keçmək OLMAZ** — 11-ci
     sinifdə balı ~1,8 dəfə şişirdərdi. Ekranda dürüst yazılır:
     «avtomatik hissə: N/61». 300-lük proqnoz yalnız müəllim açıq
     sualları qiymətləndirəndən sonra.
   - **II mərhələdə mənfi bal var**: `NBq = (Dq − ¼·Yq)·100/33`.
     I mərhələdə yoxdur. `rpc_submit_attempt`-də mənfi bal anlayışı
     ümumiyyətlə yoxdur — yeni tələbdir.
   - Model **2027-dən dəyişir** (DİM 21.07.2026 tarixli sənədi).
     Şablon ilk gündən `tedris_ili` ilə versiyalanmalıdır — sonradan
     əlavə etmək olmaz.
   - Tədris dili azərbaycanca olmayanlar **əlavə** «Azərbaycan dili
     (dövlət dili kimi)» imtahanı verir: +30 tapşırıq, 100 bal.
     Bu balın 300-ə qatılıb-qatılmadığı sənəddə yazılmayıb — **açıq
     sual, təxmin etmirik**.

   **Arxitektura:** sınaq = **seans**, üç mövcud testi qruplaşdıran
   yeni cədvəl. `tests.subject_id` **not null**-dur (bir test = bir
   fənn); onu çoxfənnli etmək bank/generator/hesabat/tapşırıq —
   hamısına toxunardı. Seans yolu əlavədir, mövcud heç nəyi sökmür.

   **Bağlı yol:** mövcud çoxvariantlı riyaziyyat suallarını açıq tipə
   çevirmək ucuz qazanc DEYİL. 3680 sualdan 2337-də hesablanmış cavab
   (`expect`) ümumiyyətlə yoxdur, 162-si variantlara istinad edir
   («hansı düzdür»), asan namizədlərin çoxu isə 3-4-cü sinifdədir —
   9-cu sinifdə 77, 11-ci sinifdə cəmi 21. Yəni məhz lazım olan yerdə
   məhsul sıfıra yaxındır. İmtahan üçün açıq suallar **yenidən
   yazılmalıdır**.

   **Başlamazdan əvvəl:** «Azərbaycan dili (dövlət dili kimi)» balının
   300-ə qatılıb-qatılmadığı DİM-dən (1653) dəqiqləşdirilməlidir.

   **Sıra:** bu, `levels` modeli və pilotdan SONRA — imtahan auditoriyası
   səhvi bağışlamır, məhsul hələ real şagirdlə sınanmayıb.

15. **Valideyn girişi (tam portal / avtomatik kod)** — müzakirə olunub,
    pilotdan SONRA. Bu, yuxarıdakı «Valideyn girişi» bölməsindən
    (`db/107_valideyn.sql`, müəllimin şagird-şagird açdığı, susmaya
    görə bağlı model) **fərqlidir** — orada olan artıq hazırdır və
    işləyir. Burada müzakirə edilən daha böyük addımdır: hər şagird
    əlavə olunanda avtomatik valideyn kodu, tam valideyn ekranı, ya da
    (araşdırılan alternativ) müəllimə hazır həftəlik WhatsApp xülasəsi.

    Texniki əsas artıq bazadadır: `students.parent_id → profiles`,
    `app.can_read_student` `s.parent_id = auth.uid()` şərtinə icazə
    verir, `accounts.type = 'parent'`, `consents` cədvəli (valideyn
    razılığı). Kod mexanizmi şagird girişinin təkrarıdır (`login_code`
    üsulu) — parol yox, çünki valideyn hesab yaratmayacaq.

    Bazar sınağı və qiymət modeli müzakirəsi ayrıca saxlanılıb (bax:
    yerli strategiya qeydləri). Sıra hələ dəyişmir.

16. ~~**Bir valideyn — bir neçə uşaq.**~~ **EDİLDİ (yalnız tətbiqdə).**
    Hər uşağın kodu ayrı qalır; valideyn tətbiqi tokenləri bir siyahıda
    saxlayır (`KIDS`, `localStorage` `{kids:[{t,c}], cur}`; köhnə `{t,c}`
    formatı oxunur), ev ekranında ad çipləri (`.kids`), «uşaq əlavə et»
    → giriş ekranı «əlavə» rejimində (`ADD_MODE`). Bir uşağın sessiyası
    bitəndə yalnız o düşür (`kidDrop`); «Çıxış» hamısını bağlayır.
    Test: `test/e2e_valideyn_iki.py`.

17. **Aktiv müəllimə aylıq endirim.** İstifadəçinin təklifi (ilk canlı
    müəllim söhbətindən sonra): proqramı fəal işlədən müəllimə növbəti
    ayın haqqından endirim — stimul. Ölçü sadə olmalıdır və müəllimin
    özü görməlidir («bu ay 12 tapşırıq, 40 cəhd → gələn ay −20 %»);
    gizli düstur inam qırar. Ödəniş mərhələ 2-yə (Payriff/Epoint)
    bağlıdır — ondan əvvəl mənasızdır. Bələdçi (`komek/`) ilə birlikdə
    «necə qazanılır» da orada yazılacaq.

18. **Diaqnostik test → şagird üzrə mövzu xəritəsi → fərdi dərs planı.**
    (a) və (b) **hazırdır** — `db/118_diaqnostika.sql`, bax «Diaqnostik
    test» bölməsi; (c) fərdi plan **EDİLDİ** — `db/131_ferdi_plan.sql`,
    bax «Fərdi plan» bölməsi aşağıda.
    İstifadəçi «möhtəşəm» dedi, ilk pilot müəllimindən sonra. Üç pillə:
    (a) «Diaqnostik test ver» — sinfin BÜTÜN mövzularından hər birinə
    3 sual (`app.min_topic_answers()` = 3 olmasa analiz susur; fəsil
    səviyyəsində, ~30–45 sual, bir cəhd); (b) nəticə — mövzu xəritəsi
    (yaşıl/narıncı/qırmızı) + «bundan başla» + hər zəif mövzuya «səhvlər
    üzərində iş»; (c) **fərdi plan**: zəif mövzular kurikulum sırası ilə
    şagirdin öz planına düşür («Keçildi» şagird üzrə). İndi plan yalnız
    qrup üzrədir (`class_plans.class_id`) — fərdi plan üçün `student_id`
    (nullable) və UI-də yüngül görünüş lazımdır: 12 şagirdə 12 plan
    olacaq, hər biri 3–6 sətir olmalıdır, 74 yox. Təkrar diaqnostika
    irəliləyişi rəqəmlə göstərir («3 qırmızı → 1») — valideyn hesabatına
    (yol xəritəsi «aylıq hesabat» təklifi) da düşür.
    `07_seed_tests.sql`-dəki «Nümunə — ödənişli test» (riy-3-analiz) bunun
    nümunə-yer tutucusudur, məhsul deyil (canlıda yoxdur).

19. ~~**«Bizə yaz» — istifadəçi təklifləri.**~~ **EDİLDİ** —
    `db/122_bize_yaz.sql`, bax «Bizə yaz» bölməsi aşağıda.

20. **Müəllim gözü ilə audit (2026-09-05) — istifadəçi «bunları edə
    bilərik, yadda saxla» dedi.** Sıra ilə:
    a. **Ad sırası.** Şagird formasında «Ad Soyad» yönləndirməsi (və ya
       iki ayrı sahə); «Hüseynov Mirhüseyn» yazılanda qısa ad və valideyn
       mətni soyadı ad kimi işlədir.
    b. **«Test yığ» ağırdır.** «Tövsiyə olunan» tək düymə: qrupun
       sinfi + planda növbəti/son keçilən mövzu + 10 sual; parametrlər
       «Özüm seçim» altında.
    c. **Tapşırıq verildi, sonra nə?** Tapşırıqdan sonra hazır WhatsApp
       mətni «Tapşırıq verdim: … son tarix …» + «Göndər» düyməsi
       (şagirdə bildiriş göndərə bilmirik — şəbəkə qaydası).
    d. **Hesabatda «nə edim» sətri.** Qrup hesabatının üstündə tək
       cümlə: «Bu həftə 3 uşağa vurma cədvəlini təkrar ver» (mövzu
       mənimsəməsindən çıxarılır, «Səhvlərdən test» düyməsi ilə).
    e. 10-dan çox şagirddə ad axtarışı; test vərəqi yığcam çap rejimi.
    f. Çətin başa düşülənlər: üç test növünün (adi · diaqnostik ·
       səhvlər) bir sətir izahı tapşırıq ekranında; «Sərbəst məşq»
       açarında «bağlasanız uşaq yalnız tapşırıqları görər»;
       «Platforma» → «Hazır bank»; tapşırığı götürəndə «nəticələr
       qalır» izahı; «Bildirişlər» sözü iki mənada (admin sual
       bildirişi / müəllim siqnalları) — ad ayrılmalıdır.
    g. Tez olanlar: ana səhifədə 4 lövhə tək qruplu müəllimə boşdur;
       valideyn mətnində Səmimi/Rəsmi iki üslub artıqdır; lövhə
       (liderlik) 6-dan az şagirddə gizlənsin.

21. **Böyük təkliflər (2026-09-05, istifadəçi «yadda saxla» dedi).**
    Repetitorun üç ağrısı: dərsə hazırlıq vaxtı, valideynə dəyəri sübut
    etmək, yeni şagird tapmaq. Sıra: 1–2 ucuz və dərhal hiss olunur,
    3–4 müəllimi saxlayır və gətirir, 5 uşağa, 6–7 böyük iş.
    1. **«Bu günün dərsi» ekranı** — dərsdən əvvəl bir kart: kim
       tapşırığı etməyib, kim hansı mövzuda zəifdir, növbəti mövzu,
       hazır test «Ver». Məlumat bazadadır, yalnız bir ekranda yığılır.
    2. **Ev tapşırığı avtomatı** — planda «keçdik» → həmin mövzudan 10
       sual yığılır, növbəti dərsə qədər tapşırılır, WhatsApp mətni hazır.
    3. **Paylaşılan irəliləyiş kartı** — brauzerdə şəkil: «Ayan,
       sentyabr: 52% → 78%, müəllim Arzu». Müəllimin öz reklamı =
       Bil10-un reklamı. Şəbəkə lazım deyil (canvas → PNG → paylaş).
    4. **Davamiyyət və ödəniş dəftəri** — «iştirak etdi», ay sonu «8 dərs,
       6 ödənilib», valideyn iştirak sayını görür. Gündəlik istifadə
       gətirən yapışqan xüsusiyyət.
    5. **Şagirdin səhv dəftəri** — səhv sual düz cavablanana qədər qalır,
       bir həftə sonra yenə gəlir (aralıqlı təkrar); müəllim yalnız
       «12 qalıb, 30 bağlanıb» görür.
    6. **DİM formatında sınaq imtahanı** — 9/11-ci sinif, vaxt limiti,
       DİM ballama; bank tərəfi böyükdür, bazar ən çox bunu ödəyir.
    7. **Sinifdə canlı yarış** — müəllim başladır, uşaqlar telefondan
       cavab verir, lövhədə canlı sıralama (3 saniyəlik RPC sorğusu ilə,
       realtime lazım deyil).

22. **Dünya praktikasından yüksək məhsuldarlıqlı təkliflər (2026-09-05).**
    a. ~~**Parametrik (şablon) suallar**~~ **EDİLDİ** — `db/132`,
       bax «Parametrik (şablon) suallar» bölməsi aşağıda.
    b. ~~**Adaptiv məşq (IXL/Khan mənimsəmə)**~~ **EDİLDİ** — `db/133`,
       bax «Adaptiv mövzu məşqi» bölməsi aşağıda.
    c. **«Tələsik səhv» və inam göstəricisi** — cavab vaxtı artıq var
       (<5 san + səhv = diqqətsizlik); cavabda «əminəm / əmin deyiləm»
       seçimi → «bilmədən düz» görünür. Ucuz, dərin.
    d. ~~**Kurikulum paketi («course in a box»)**~~ **EDİLDİ** — `db/135`,
       bax «Kurikulum paketi» bölməsi aşağıda.
    e. **Müəllimin öz səhifəsi (Classplus/Teachmint modeli)** —
       bil10.az/arzu: profil, nəticələr, əlaqə; sonra valideyn
       müəllim axtarır (ikitərəfli bazar).
    f. **Ölkə üzrə müqayisə** — anonim benchmark: «sizin 5-ci sinif
       ortalama 62%, ölkə 58%»; valideynə «ilk 20%». Data yığıldıqca
       özü işləyir.
    g. ~~**Sual keyfiyyəti təhlili**~~ **EDİLDİ** — `db/134`, bax
       «Sual keyfiyyəti təhlili» bölməsi aşağıda.
    h. **Müəllim bankı (UGC)** — müəllim öz sualını platformaya
       «bağışlayır», qəbul olunanda pulsuz ay; moderasiya mövcud
       bildiriş axını ilə. Bank ucuz böyüyür.
    i. **Foto ilə sual soruş** — şagird ev tapşırığının şəklini atır,
       müəllim tətbiqdə cavablayır (Supabase Storage, eyni host).
    j. **Məktəb rejimi** — sinif müəllimi 30 şagird, məktəb admini
       lövhəsi; özəl məktəblərə B2B.
    k. **Dəvət dövrəsi** — müəllim müəllimi dəvət edir → pulsuz ay.
    Qayda: heç biri tətbiqdən xarici şəbəkəyə çıxmır; AI ilə izah/variant
    yaradılması yalnız oflayn, admin tərəfində, banka yazılaraq.

23. **İzah qatı: ipucu · həll addımları · mövzu kartı (2026-09-06,
    müzakirə olunub, HƏLƏ EDİLMƏYİB — istifadəçi «yadda saxla» dedi).**
    Vəziyyət: hər sualda izah var, amma orta 40 simvol — bir cümləlik
    fakt, «niyə» yoxdur; şəkilli sual 0. Eskiz (üç işləyən ekran):
    https://claude.ai/code/artifact/ab21a607-df7e-4ceb-90f1-a3f1f6fc9c09
    Qərarlar:
    - Üç pillə: **ipucu** (cavabdan əvvəl, yalnız mövzu məşqində, bal
      yarıya), **həll addımları** (səhvdən sonra bir-bir açılır; mövcud
      `explanation` sahəsi «1) 2) 3)» ilə başlayanda addım kimi göstərilir,
      sxem dəyişmir), **mövzu kartı** (kök mövzuya bir dəfə: qayda, 2
      nümunə, tipik səhv, özünü yoxla; «Mövzunu oxu» səhvdən, məşqdən,
      plandan açılır). Hər səhv varianta «niyə səhvdir» cümləsi.
    - Fənn növünə görə: riyaziyyat/fizika/kimya/informatika — addımlar
      (7+ sinifdə düstur göstəricisi lazımdır: kəsr, kök, dərəcə, indeks,
      kənar kitabxanasız); Az dili/ingilis — «qayda → nümunə → tətbiq»;
      tarix/ədəbiyyat/coğrafiya/biologiya — yalnız kart + distraktor
      cümləsi (ipucu işləmir). Bilik fənləri bankın yarısından çoxudur.
    - Hamısına yox: kart 618 kök mövzuya (bütün sualları bir dəfəyə
      örtür); addım/distraktor yalnız `question_stats`-ın göstərdiyi ən
      çox səhv edilən suallara («izah gözləyən» növbə, ən çox səhv əvvəl).
      Şablon suallarda addımlar da şablondur (`{a%10}`).
    - Bölgü: **bu depo** — sxem (sualda `hint`, variantda `why`, mövzuda
      `card`), «1)» addım göstərilməsi, ipucu/«Həlli göstər»/«Mövzunu
      oxu», düstur göstəricisi, müəllimin «İzah yaz» + admin təsdiqi +
      pulsuz gün, «izah aydın deyil» bildiriş səbəbi, bank faylları üçün
      format nümunəsi + yoxlayıcı (riyaziyyatda addımların son cavabı
      açarla düz gəlməlidir), növbə skripti. **bil10-bank** (o biri
      sessiya; format: hər fənn-sinif bir SQL, sətir = ext_key, mövzu,
      diff, rüb, body, why, opts[], correct; `tools/*.py` yaradır) —
      sətirlərə `ipucu`, `sehv_niye[]` sütunları (izah «1)» ilə), yeni
      `kart_<fenn><sinif>.sql` fayl tipi, riyaziyyat suallarının şablona
      çevrilməsi. Görüş nöqtəsi yalnız sütun adlarıdır.
    - Sıra və qapı: kod (2–3 gün) → məzmun yalnız 3-cü sinif riyaziyyat
      (8 kart + o fəsillərin sualları) → ölçü: səhv dəftərində bağlanma
      payı, mövzu məşqində mənimsəmə faizi, «izah aydın deyil» sayı,
      izahlı/izahsız mövzu müqayisəsi → rəqəm göstərsə genişlənir, yoxsa
      618 kart yazılmır. Bələdçiyə edilməmiş iş yazılmır.
    - Dəyər qiymətləndirməsi: şagirdə çox (izahsız səhv dəftəri və məşq
      təxminetməyə çevrilir), valideynə orta (abunənin qalması), müəllimə
      az (alış qərarını dəyişmir; bəzi repetitor istəməyəcək). Pilot
      üçün lazım deyil; «test sistemi»ndən «öyrənmə sistemi»nə keçid
      üçün lazımdır. Hər halda həqiqi istifadəçi rəyi bundan vacibdir.

24. **Kurs rejimi: rəhbər lövhəsi (2026-09-06, istifadəçi «yaz saxla»
    dedi; 22.j «məktəb rejimi»nin dəqiqləşməsi, HƏLƏ EDİLMƏYİB).**
    Ssenari: çoxlu qrupu olan kurs; rəhbər bütün qrupların gedişini,
    şagirdlərin vəziyyətini və səviyyəsini bir yerdən izləyir.
    Niyə asandır: baza hazırdır — bir hesabda bir neçə müəllim
    (`account_members`), qrup müəllimə bağlı, nəticə/dəftər/davamiyyət/
    ödəniş qrup səviyyəsində yığılır; rəhbər ekranı yeni məlumat yaratmır,
    mövcudu bir pillə yuxarıda cəmləyir.
    Rəhbər ekranı (bölmələr):
    - Lövhə: qrup sayı, şagird sayı, bu həftə tapşırıq edənlər, ortalama,
      davamiyyət, ödənilməmiş şagirdlər.
    - Qruplar cədvəli: müəllim · sinif · fənn · şagird · son 30 gün
      ortalama · tapşırıq edilmə faizi · sonuncu dərs tarixi; zəif gedən
      qrup qırmızı.
    - Müəllimlər: hər müəllimin qrupları üzrə eyni göstəricilər (müqayisə
      — ən qiymətli və ən həssas hissə).
    - Şagird axtarışı bütün kurs üzrə: qrupu, səviyyəsi, ödənişi.
    - Siqnallar: 3 həftə tapşırıq verilməyən qrup, davamiyyəti düşən
      şagird, ödənişi gecikən.
    Lazım olan işlər:
    1. Rol: «üzv»dən ayrı «rəhbər» (hər şeyi görür; müəllim yalnız öz
       qruplarını) — RLS-ə toxunur, diqqətli iş. `app.can_read_student`,
       `app.plan_class` və qrup RPC-lərinin hamısı rol qaydasına uymalıdır.
    2. Hesab səviyyəli hesabat RPC-ləri (`rpc_course_overview`,
       `rpc_course_groups`, `rpc_course_teachers`, `rpc_course_find`) —
       mövcud `rpc_class_report`/`rpc_student_report`/`rpc_ledger_get`-in
       cəmi; `last_seen_at` (db/125) müəllim aktivliyi üçün.
    3. Müəllimi hesaba dəvət (şagird kodu kimi bir kod; indi yalnız
       `rpc_admin_grant`-la əl ilə).
    4. Paket: 25 yerdən böyük (100–300 şagird) kurs paketi və qiyməti.
    5. Qərar: müəllim kursdan gedəndə qrupları kimə qalır (hesaba, yəni
       rəhbərə — təklif budur); müəllimin öz sualları hesabda qalır.
    Xəbərdarlıq: rəhbər ekranı müəllimə nəzarət alətidir — müəllim
    hiss edən kimi az işlədə bilər. Yumşaltma: eyni göstəriciləri
    müəllimin özünə də açmaq, müqayisəni «reytinq» yox, «kömək lazım
    olan qrup» dilində vermək.
    Dəyər: bir kurs bir dəfəyə 10–30 müəllim gətirir, satış bir nəfərlə;
    repetitor-repetitor satmaqdan qat-qat sürətli. D qrupunun bəzi
    bəndlərindən (ölkə müqayisəsi, müəllimin səhifəsi) vacibdir.
    Bələdçiyə edilməmiş iş yazılmır.

25. **Unutma əyrisi: gündəlik 5 dəqiqə (2026-09-06, istifadəçi «çox
    bəyəndim» dedi, HƏLƏ EDİLMƏYİB).** Səhv dəftəri səhvləri qaytarır;
    düz bilinən mövzular da unudulur. Hər gün 5 sual: keçmiş mövzulardan,
    aralıqlı təkrar cədvəli ilə (mövzu keçiləndən / mənimsəniləndən 1
    həftə, 1 ay, 3 ay sonra; düz cavab intervalı uzadır, səhv qısaldır).
    Mənbə: plandakı keçilmiş mövzular (`class_plan_items.done_at`), mövzu
    məşqində mənimsənilənlər (`practice.mastered_at`), yazılmış testlərin
    mövzuları. Sual seçimi `app.practice_pool`-dan (görülməmiş əvvəl,
    şablon suallar təzə rəqəmlə); düz variant getmir; səhv `mistake_note`
    ilə dəftərə. Şagird ev ekranında «Bu günün 5-i» kartı + ardıcıllıq
    (streak) sayğacı; 5-i bitirəndə «sabah yenə». Müəllim hesabatında
    «unutma»: hansı köhnə mövzu yenidən zəifləyib (təkrar dərs siqnalı).
    Cədvəl: `review_topics(student_id, topic_id, next_at, interval_days,
    ok_n, bad_n)`. Elmi əsas ən möhkəm öyrənmə üsuludur (aralıqlı
    təkrar); bütün məlumat var, həcm orta.

26. **Kağız rejimi: QR vərəq (2026-09-06, istifadəçi «çox bəyəndim»
    dedi, HƏLƏ EDİLMƏYİB).** Çox müəllim dərsdə telefonu qadağan edir.
    Axın: test vərəqi çap olunur (mövcud `#/t/` vərəqi), üstündə test
    kodu/QR; şagird kağızda işləyir; müəllim telefonunda «Kağızdan daxil
    et» ekranında şagirdi seçib cavabları hərflə vurur (A C B D … — bir
    sətir, 20 saniyə); sistem `rpc_paper_submit(class, test, student,
    answers text)` ilə cəhd yaradır (`attempts` + `attempt_answers`,
    `source='paper'`), bal serverdə, hesabat/səhv dəftəri/mövzu xəritəsi
    eyni işləyir. Vərəqdə hər sualın variantları çapda sabit sırada
    olmalıdır (shuffle söndürülür, vərəqdəki sıra = daxiletmə sırası —
    `paper_seed` ilə saxlanır). Şablon suallar vərəqdə bir variantla
    çıxır — daxiletmə həmin variantın açarı ilə yoxlanır (vərəq
    yaradılanda `params` saxlanmalıdır). Boş cavab «-» = cavabsız
    (null). Yazılı sual dəstəklənmir (yalnız variantlı). Toplu rejim:
    bir ekranda bütün qrup, sətir-sətir. Yerli bazarda kağız + rəqəm
    birləşməsini heç kim vermir; həcm orta.

27. **Kiçik faydalı ideyalar (2026-09-06, hələ seçilməyib).**
    a. Ayrılma xəbərdarlığı: tapşırıq edilmə düşür + valideyn ekranı
       açılmır + davamiyyət seyrəlir → müəllimə «ayrılma riski» sətri.
    b. Köçürmə siqnalı: evdə yazılan testdə iki şagirdin səhvləri eyni
       və vaxtları yaxın → sakit nişan, hökm yox.
    c. Plan sürəti: plan × təqvim → «bu sürətlə iyunda 4 fəsil qalır».
    d. Valideynə həftəlik hazır mesaj (cümə): tapşırıq sayı, faiz,
       zəif mövzu, gələn həftə — bir toxunuşla WhatsApp.
    e. Ödəniş xatırlatması: dəftərdə «ödənilməyib» → nəzakətli hazır
       mətn, bir toxunuşla göndərmə.
    f. Valideyndən «bu gün gələ bilmir» düyməsi → müəllimin dəftərində.
    g. İl sonu sertifikatı: mənimsənilmiş mövzular, ən yaxşı nəticələr,
       müəllimin adı ilə şəkil (irəliləyiş kartının il versiyası).

Açıq qərarlar: abunə bitəndə öz suallarının taleyi; platforma bankının
mənbə strategiyası; bil10.az qeydiyyatı (istifadəçinin işi); valideyn
girişində qiymət modeli — pilotdan sonra (təfərrüat: yerli strategiya
qeydləri).
