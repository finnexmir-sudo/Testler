# Layihə: Bil10

İbtidai siniflər (1–4) üçün onlayn test platforması. Gələcəkdə yuxarı
siniflər, MİQ və sertifikasiya da əlavə olunacaq.

Kommersiya məhsuludur: valideyn abunəliyi, repetitor paketləri, məktəb
lisenziyası. Ödəniş şlüzü (Epoint) sonra qoşulacaq.

---

## Struktur

```
index.html      giriş səhifəsi
muellim/        müəllim / repetitor paneli (statik, Supabase ilə)
db/             SQL sxem, RLS, RPC, seed, hüquqlar
test/           uçdan-uca yoxlama (mock Supabase + Chromium)
```

---

## ƏN VACİB ÜÇ QAYDA

**1 · Bal həmişə serverdə hesablanır.**
`question_options.is_correct` şagird tərəfinə heç vaxt getmir. Şagird
`rpc_start_attempt()` ilə sualları cavabsız alır, `rpc_submit_attempt()`
cavabları qəbul edib balı bazada hesablayır. Şagirdin `attempts`
cədvəlinə yazmaq hüququ yoxdur. Bunu pozan dəyişiklik saxtakarlığa qapı
açır.

**2 · Şəxsi məlumat yalnız `students` cədvəlində.**
`display_name` müəllimin yazdığı bir şey deyil — tam addan avtomatik
qısaldılır (Aysu Məmmədova → Aysu M.) və yalnız liderlər lövhəsində
işlənir. Panelə ləqəb sahəsi qaytarma: müəllimə iş çıxarır və eyni
şagirdin iki adı olduğu üçün çaşdırır.
Ad-soyad başqa heç bir cədvəldə olmamalıdır. Liderlər lövhəsi
`display_name` göstərir. Tam doğum tarixi saxlanılmır — yalnız
`birth_year`. Yeni cədvəl əlavə edəndə ora ad yazma.

**3 · `db/05_grants.sql` cədvəl yaradan hər fayldan sonra işlədilir.**
Supabase hər yeni cədvələ avtomatik `anon` hüququ verir. `05` əvvəlcə hər
şeyi bağlayır, sonra yalnız lazım olanı verir. İşlətməsən `anon` həssas
cədvəlləri görər.

---

## Supabase-də qurmaq

SQL Editor-da: `01` → `02` → `03` → `06` → `04` → `05`.
`db/test/` qovluğundakı fayllar Supabase-də **işlədilmir** — onlar `auth`
sxemini təqlid edir.

Sonra `db/test/verify.sql` işlət — 7 sətir, hamısı `OK` olmalıdır.

`muellim/config.js` doldurulmalıdır: `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
`service_role` açarı **heç vaxt** frontend faylına yazılmır.

---

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
2. **Sual bankının davamı** — 3-4-cü siniflər hazır; qalır 1-2-ci
   siniflər və ingilis dili.
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
8. ~~PWA quraşdırma~~ — hazırdır. Hər iki tətbiq ayrıca quraşdırılır:
   `muellim/manifest.json` və `sagird/manifest.json` (fərqli ad, start_url,
   tema rəngi), ikonlar `assets/icons/` (192/512 + maskable). Kökdə **bir**
   `sw.js` — hər iki tətbiqi əhatə edir (`register("../sw.js", {scope:"../"})`;
   ehatə skriptin yerinə görə müəyyən olunur, ona görə alt qovluqdan da
   qeydiyyat keçir). `assets/pwa.js` həm qeydiyyatı, həm «Ana ekrana əlavə et»
   zolağını idarə edir.
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
   deyil. Qərar: **məzmun məhsulu qurmuruq** (Hədəf/Araz tipli
   nəşriyyatlarla məzmun yarışında şansımız yoxdur), **alət** qururuq:
   qəlib → hər həftə yeni variant → sınaqdan-sınağa trend.
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

   **Sıra:** bu, `levels` modeli və pilotdan SONRA. İmtahan auditoriyası
   ən bağışlamayandır — bir səhv cavab açarı etibarı birdəfəlik alır,
   biz isə məhsulu hələ bir ay real şagirdlə işlətməmişik. Amma
   imtahana hazırlaşdıran real bir repetitor «sınayaram» desə, sıra
   dəyişir: onda təxminlə yox, konkret ehtiyacla qururuq.

Açıq qərarlar: abunə bitəndə öz suallarının taleyi; platforma bankının
mənbə strategiyası; bil10.az qeydiyyatı (istifadəçinin işi).

## E-dərslik yenilənməsi — hər il avqustda

Mövzu ağacımız e-dərslikdən gəlir. Dərslik hər il yenilənə bilər: ad
dəyişir, sıra dəyişir, mövzu əlavə olunur və ya **çıxarılır**.
**Sistem bunu özü yoxlamır və yoxlaya bilməz** — tətbiqin xarici
şəbəkə müraciəti yoxdur (CSP və layihə qaydası). Yoxlama insan işidir,
bank sessiyası edir, dərslər başlamamış.

Nə qorunur:

- Açar `slug`-dur, ad deyil → **ad dəyişikliyi təhlükəsizdir**
  (`on conflict (subject_id, slug) do update`)
- `questions.topic_id` və `attempt_answers.topic_id` → `on delete set
  null`: mövzu silinsə suallar və keçmiş nəticələr **qalır**
- `class_plan_items.topic_id` → **`on delete restrict`**
  (`db/102_movzu_qoruyucu.sql`). Əvvəl `cascade` idi: silinən mövzu
  hər müəllimin planından «keçildi» tarixçəsi ilə birlikdə **səssizcə**
  yox olurdu. İndi baza xəta atır — itki səssiz olmur.
- `app.topu_islekdir(uuid)` — mövzu istifadədədirmi: sual, plan sətri,
  generator qaydası, alt mövzu. İllik yeniləmə skriptləri bunu
  çağırsın, öz-özünə şərt yazmasın. Yalnız baxım üçündür, `anon` və
  `authenticated` çağıra bilmir.

Praktikada: silmək əvəzinə **adı yeniləmək** demək olar həmişə
düzgündür — slug qalır, tarixçə qalır.

## `db/` fayl nömrələri — iki sessiya arasında bölgü

Bankı ayrı sessiya doldurur və onun faylları **hələ repoya
verilməyib** (yerli nüsxədə 30…73 aralığındadır). Ona görə nömrələr
toqquşurdu. Bölgü belədir:

| Aralıq | Kim | Nə |
|---|---|---|
| 01–29 | kod | sxem, RLS, RPC — doludur |
| 30–99 | bank | sual/mövzu məlumatı (o biri sessiya) |
| 100+ | kod | yeni RPC və miqrasiyalar |

Yeni **kod** faylı 100-dən başlayır. Bank faylına toxunma; bank
sessiyası da 100+ aralığına girmir.

## Yerli yoxlama

```bash
# SQL testləri — hər suite öz təmiz bazasında
./db/test/yoxla.sh
./db/test/miqrasiya.sh          # təzə vs miqrasiya olunmuş sxem

# panel uçdan-uca (mock Supabase + Chromium)
./test/run_e2e.sh
```

Sxem və ya RLS dəyişəndə **mütləq** hamısını işlət. Bu testlər
təhlükəsizlik iddialarıdır, yalnız «işləyir/işləmir» yoxlaması deyil.

Hər test faylı **öz təmiz bazasında** işlədilməlidir — bir-birinin
arxasınca eyni bazada işlətsən sonrakılar uğursuz olur: `smoke_educator.sql`
müəllim panelini yoxlayarkən testləri silir, ondan sonrakı suite platforma
testini tapmır və «Test tapılmadı» verir, kod düzgün olsa belə.
`yoxla.sh` və `run_e2e.sh` bazanı hər dəfə yenidən qurur.

`anon` rolu altında işləyən yoxlamalarda `public.tests`, `questions` və
`question_options` **oxunmur** — `05_grants.sql` bunu qadağan edir. Test
üçün lazım olan id-ləri rol dəyişməzdən əvvəl `test_fixtures` /
`answer_fixtures` cədvəlinə yığ (`smoke_assign.sql` nümunədir).

---

## Mövcud bazanı yeniləmək

Təzə baza: `db/run.sh` bütün faylları düzgün sıra ilə işlədir.

Artıq işləyən Supabase layihəsi üçün isə **miqrasiya faylı** var —
`db/10_teyinat_migrasiya.sql` (təyinatlar), `db/11_sual_banki.sql`
(sual bankının strukturu) `db/12_bank_rpc.sql` (bankın RPC-ləri) və `db/13_generator.sql`
(generator).
Hər biri əvvəlki faylları işlətmiş bazaya tək başına
əlavə olunur, təkrar işlədilsə zərər vermir və sonda özünü yoxlayır.
Yeni belə dəyişiklik edəndə eyni qaydada `14_...`, `15_...` yaz —
istifadəçiyə beş faylı yenidən yapışdırtma.

**Hər miqrasiya faylı öz ön şərtini yoxlamalıdır.** Əvvəlki fayl
işlədilməyibsə, faylın başında aydın desin (`ÖNCƏ 11_... işlədilməlidir`)
— yoxsa 300-cü sətirdə `column "account_id" does not exist` kimi
qaranlıq xəta çıxır və səbəb görünmür.

Baza harada qaldığını bilmək üçün: `db/test/hardayam.sql` — heç nə
dəyişmir, hansı faylın işlədildiyini və növbəti faylı deyir.

**`revoke ... from public` funksiya üçün kifayət deyil.** Supabase yeni
funksiyalara `anon` üçün EXECUTE-u **birbaşa** verir — PUBLIC-dən geri
almaq ona toxunmur. Müəllim funksiyası yazanda mütləq
`revoke all on function ... from public, anon` yaz.
İkinci qat: `05_grants.sql` sonda `anon`-dan bütün funksiyaları geri
alır və yalnız 6 şagird RPC-sini saxlayır — unudulsa da sızmır.

**Miqrasiya təzə sxemlə EYNİ nəticə verməlidir.** Bir dəfə `11` qismən
unikal indeks yaratdı (`where ext_key is not null`), `01` isə tam
`unique` — və `on conflict (ext_key)` yalnız canlı bazada sındı
(`42P10`). `db/test/miqrasiya.sh` köhnə bazanı qurub bütün miqrasiyaları
işlədir və sxemi təzə baza ilə tutuşdurur — yeni miqrasiya yazanda onu
işlət.

**Uzantının sxemini sərt yazma.** `pg_trgm` bəzi bazalarda `public`,
bəzilərində `extensions` sxemindədir. `extensions.gin_trgm_ops` yazsan
bir bazada işləyir, o birində «operator class does not exist» verir.
`set search_path = public, extensions` qoy, adı qısa yaz.

---

## Sürüşmə qaçır — tələ

Formada bir düymə basılanda **bütün ekranı yenidən çəkmə** — səhifə
yuxarı atılır və müəllim yerini itirir. Yalnız dəyişən hissəni yenilə
(nişanı `classList.toggle`, siyahını `drawOptions`).

DOM qısalanda brauzer sürüşməni kəsir. Ona görə `keepY()` dəyəri
**əməliyyatdan əvvəl** tutur — sonra oxusan artıq sıfırlanmış olur.

Testdə ölçü mənalı olmalıdır: səhifə sıfırdan fərqli yerdə dayanmalı və
Playwright-in öz «scroll into view»-si ölçünü pozmamalıdır — düyməni
əvvəlcə görünən yerə gətir. «0 → 0» heç nə sübut etmir.

---

## Dinləyici yığılması — tələ

`innerHTML` dəyişdirmək elementin ÖZÜNÜ dəyişmir. Ona görə hər yenidən
çəkilişdə `addEventListener` çağırsan, dinləyicilər **üst-üstə yığılır**:
iki klik → 4 dinləyici → bir klikdə 4 əməliyyat. Bir dəfə belə oldu —
«Variant əlavə et» bir klikdə 19 variant yaratdı.

Qayda: dinləyici **ekran çəkiləndə bir dəfə** bağlanır (`show()` yeni
düyün yaradır), yenidən çəkilişdə yox. Şübhəlisənsə `dataset.bound`
nişanı qoy.

---

## CSS sinif adları — toqquşma

`assets/base.css` ortaq sistemdir. Yeni sinif adı verəndə **əvvəlcə
axtar** — iki dəfə toqquşdu: `.mark` (başlıqdakı loqo nişanı) və `.top`
(tətbiqin başlıq zolağı, `display:flex` — ilk səhifəni yan-yana düzdü).
İkisi də yalnız gözlə göründü, ona görə `e2e_panel` artıq ilk səhifəni
də yoxlayır: yana sürüşmə, boş ikon, üstlüyün yeri. Testlərdə də `.item` kimi
ümumi seçicilər `#groups .item` şəklində dəqiqləşdirilməlidir.

---

## Sual bankı — qayda

Sual **testin içində deyil, bankdadır**. `test_questions` hansı testin
hansı sualı hansı sıra ilə götürdüyünü saxlayır.

- `questions` sətrini **silmə** — `test_questions` `restrict` ilə imtina
  edir (təsadüfən tarixçə silinməsin deyə). Gizlətmək üçün
  `status = 'archived'` — generator onu görmür, köhnə nəticələr qalır.
- Cavab yazılanda sualın mətni `attempt_answers.question_body`-ə
  **surət** kimi düşür. Sual sonradan redaktə olunsa da köhnə hesabat
  şagirdin gördüyü sualı göstərir. Yeni cavab yolu yazırsansa
  `question_body` və `question_explanation` sütunlarını doldur.
- Hesabatlarda səhv sualları **surətdən** oxu, `questions`-dan yox.
- Mövzular **mərkəzdən** gəlir (`db/14_movzular.sql` →
  `db/15_movzular_ederslik.sql`), müəllim özü
  yaza bilmir — hər müəllim «Vurma» / «Vurma cədvəli» / «vurma» yazsaydı
  zəif nöqtə hesabatı üç yerə bölünərdi. Çatışmayan yer üçün `tags`.
  Slug qaydası: `<fənn>-<sinif>-<mövzu>` — `topics`-də
  `unique(subject_id, slug)` var, sinif slug-in içində olmalıdır.
- Ağacın **mənbəyi e-derslik.edu.az-dır** — Təhsil Nazirliyinin rəsmi
  portalı. `tools/mundericat.py` kitabların **mündəricatını** yığır
  (`mundericat/*.txt`), `15_...sql` isə ondan mövzu ağacını qurur.
  Dərsliyin mətni, çalışmaları, şəkilləri **götürülmür** — onlar müəllif
  hüququ ilə qorunur; mündəricat isə faktdır.
  Azərbaycan dili istisnadır: dərslik mövzuya yox, **mövzuya (temaya)**
  görə bölünüb («Fərd və toplum»), qrammatika dərsin içindədir — test
  bankı üçün qrammatika oxu (isim, sifət, durğu işarələri) saxlanılır.
  Riyaziyyat 2 də istisnadır: portaldakı nəşr köhnədir (yalnız 20-yə
  qədər gedir).
- Təhlükə zonası (`db/18_siqnal.sql`): qrup ekranı özü xəbər verir —
  gerileyən (son 3 vs əvvəlki 3, ≥10 bənd), zəif mövzu (≥5 cavab, <60%),
  ulduz (son 3-ün hamısı ≥90%). **Az məlumatda susur** — hədlər
  `app.alert_*()` funksiyalarındadır. Abunəsiz `alerts=null`.
- Səhv cütləşdirmə: generator qaydasında `class` açarı — həmin qrupun
  səhv cavablandığı sualların **surətdəki mətninə** qəlibcə bənzəyənlər
  (`similarity ≥ app.rem_similarity()` = 0.5) mövzu daxilində önə keçir;
  vərəqdə «səhvə bənzər» nişanı. Qrup hökmən çağıranın hesabına aid
  olmalıdır — yoxlanılır.
- Mövzu slug-u dəyişəndə **testlər də dəyişməlidir** —
  `07_seed_tests.sql`, `test/smoke_generator.sql`, `test/e2e_bank.py`
  slug-a görə axtarır. Tapılmayanda **susmasın, sınsın**: `if tp:` yox,
  `assert tp`.
- Platforma seed sualları `ext_key` (`test-slug#sıra`) ilə tanınır —
  `07_seed_tests.sql` təkrar işlədiləndə sual çoxalmır, üzərinə yazılır.
- Platforma sual bankı: `db/16_bank_riy4.sql` (Riyaziyyat 4),
  `db/17_bank_sinif4.sql` (Az dili + Həyat bilgisi + İnformatika 4),
  `db/19_bank_riy3.sql` (Riyaziyyat 3), `db/20_bank_sinif3.sql`
  (Az dili + Həyat bilgisi + İnformatika 3). **Əllə yazılmır** —
  `tools/riy4.py`, `tools/sinif4.py`, `tools/riy3.py`, `tools/sinif3.py`
  yaradır. Skript hər riyazi cavabı yenidən hesablayıb düzgün variantla
  tutuşdurur; düzəliş skriptdə edilir, sonra SQL yenidən çıxarılır.
  Yeni fənn/sinif bankı üçün eyni qəlibi izlə: `tools/<fənn><sinif>.py`
  → `db/1X_bank_<fənn><sinif>.sql`, ext_key `<qısaad>-<mövzu>#<sıra>`.

---

## Oxşarlıq həddi — ölçülüb, təxmin deyil

`pg_trgm` **mənanı yox, cümlə qəlibini** ölçür. Ölçmə:

| Cüt | Bal | Reallıq |
|---|---|---|
| `6 × 7 neçə edər?` ↔ `7 × 6 neçə edər?` | 1.00 | eyni |
| `6 × 7 neçə edər?` ↔ `6 × 8 neçə edər?` | 0.75 | **fərqli** |
| `6 × 7 neçə edər?` ↔ `9 × 4 neçə edər?` | 0.56 | **tamam fərqli** |
| `Su neçə dərəcədə qaynayır?` ↔ `Suyun qaynama temperaturu neçə dərəcədir?` | 0.40 | eyni |

Ona görə **orta hədd (0.5–0.9) işlətmə** — o zolaq qanuni, fərqli
suallarla doludur. Yalnız `>= 0.95` etibarlıdır.

Riyaziyyatda əsl təkrar siqnalı mətn yox, **düzgün cavabdır** —
generator ona görə eyni cavabın təkrarını da məhdudlaşdırır.

---

## Supabase SQL Editor — tələ

**Müvəqqəti cədvəl (`create temporary table`) işlətmə.** Supabase skripti
hovuzlanmış bağlantı üzərindən işlədir, ona görə müvəqqəti cədvəl növbəti
əmrdə artıq mövcud olmur:

```
ERROR: 42P01: relation "_q" does not exist
```

Lokal `psql`-də işləyir, Supabase-də işləmir — ona görə testlərdə tutulmur.
Əvəzinə **CTE** işlət: `with d as (values ...), ins as (insert ... returning ...) insert ...`
`db/07_seed_tests.sql` bunun nümunəsidir.

---

## Keş — vacib

GitHub Pages CSS/JS-i **10 dəqiqə** keşdə saxlayır (`max-age=600`). Nişan
olmadan istifadəçi dəyişiklikdən sonra köhnə nüsxəni görür — səhifə
yarımçıq stilləşmiş kimi görünür.

Ona görə `index.html` fayllarında bütün CSS/JS linkləri `?v=N` nişanı
daşıyır. **Dizayn və ya kod dəyişikliyindən sonra, commit-dən əvvəl:**

```bash
./bump.sh
```

Unutsan, dəyişiklik canlıda 10 dəqiqə görünməyəcək və sən onu «işləmir»
sanacaqsan.

---

## Üslub

- İnterfeys mətnləri Azərbaycan dilində, düzgün diakritiklərlə (ə, ş, ğ, ı, ö, ü, ç)
- SQL şərhləri Azərbaycanca, amma ASCII ilə
- Panel açıq temadır, toxunma sahələri ən azı 44px
- Xarici kitabxana yoxdur — CDN yüklənmir. `muellim/sb.js` Supabase üçün
  öz yüngül qatımızdır; onu böyütməkdənsə lazım olan hissəni əlavə et.
