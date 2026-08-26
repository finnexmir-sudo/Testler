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
2. ~~Sual bankının davamı~~ — hazırdır: 1-4-cü siniflər (ingilis dili
   daxil) + 5-8-ci siniflər (orta proqram, 9 fənn). Riyaziyyat 1-8-də
   hər mövzuda **40 sual**, Az dili 3-4-də **30 sual**, qalanlarda
   **20 sual** (cəmi ~9000 platforma sualı).
   Mövzu ağacları `db/25/29/33/37_movzular_orta*.sql`, banklar
   `db/23–40`. Davamı: 9-11-ci siniflər (eyni qəliblə).
3. **Dərs planı bölgüsü** — real tədris planına uyğun mövzu təqvimi,
   hər mövzunun ardınca hazır yoxlama testi. Məqsəd: proqram müəllimin
   «köməkçi işçisi» olsun.
4. **Vərəqin çap/PDF görünüşü** — cavabsız şagird + cavablı müəllim nüsxəsi.
5. **Dinamika qrafiki** — şagirdin nəticəsi həftə-həftə.
6. **«Səhvlər üzərində iş»** — səhv edilən sualların özündən bir kliklə test.
7. PWA quraşdırma (manifest + ikon), Riyaziyyat 2 mövzularının yenilənməsi
   (portala yeni nəşr gələndə).

Açıq qərarlar: abunə bitəndə öz suallarının taleyi; platforma bankının
mənbə strategiyası; bil10.az qeydiyyatı (istifadəçinin işi).

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
  (Az dili + Həyat bilgisi + İnformatika 3), `db/23/24_bank_sinif1/2.sql`
  (1-2-ci siniflər, 4 fənn bir yerdə), `db/28_bank_ing.sql` (İngilis
  dili 1-4). Orta məktəb: hər sinif üçün əvvəl mövzu ağacı
  (`25/29/33/37_movzular_orta5/6/7/8.sql`), sonra banklar —
  `26/30/34/38_bank_riy5/6/7/8.sql` (riyaziyyat),
  `27/31/35/39_bank_sinif5/6/7/8.sql` (az dili, ingilis, informatika,
  tarix), `32/36/40_bank_fenn6/7/8.sql` (fizika/kimya/biologiya/
  coğrafiya — hansı fənn o sinifdə varsa). **Əllə yazılmır** —
  `tools/riyN.py`, `tools/sinifN.py`, `tools/fennN.py`, `tools/ing.py`
  yaradır. Skript hər riyazi cavabı yenidən hesablayıb düzgün variantla
  tutuşdurur; düzəliş skriptdə edilir, sonra SQL yenidən çıxarılır.
  Yeni fənn/sinif bankı üçün eyni qəlibi izlə: `tools/<fənn><sinif>.py`
  → `db/NN_bank_<fənn><sinif>.sql`, ext_key `<qısaad>-<mövzu>#<sıra>`.
  Yeni bank hazır olanda: movzu daxilində və qonşu siniflərlə pg_trgm
  ≥0.95 təkrar yoxla, fənn üzrə eyni düzgün cavab ≤2 olsun,
  `rpc_generate_test` balans yoxlaması işlət (nümunə:
  `test/smoke_generator.sql`).

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
