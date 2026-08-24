# Layihə: Test platforması

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

## Yerli yoxlama

```bash
# SQL testləri
createdb tehsil && cd db && ./run.sh tehsil --local
psql -d tehsil -f test/smoke.sql
psql -d tehsil -f test/smoke_educator.sql
psql -d tehsil -f test/smoke_reports.sql
psql -d tehsil -f test/smoke_assign.sql
psql -d tehsil -f test/smoke_bank.sql
psql -d tehsil -f test/smoke_bank_rpc.sql
psql -d tehsil -f test/smoke_generator.sql

# panel uçdan-uca (mock Supabase + Chromium)
./test/run_e2e.sh
```

Sxem və ya RLS dəyişəndə **mütləq** hamısını işlət. Bu testlər
təhlükəsizlik iddialarıdır, yalnız «işləyir/işləmir» yoxlaması deyil.

Hər test faylı **öz təmiz bazasında** işlədilməlidir — bir-birinin
arxasınca eyni bazada işlətsən sonrakılar uğursuz olur (`run_e2e.sh`
elə edir). 

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

**Uzantının sxemini sərt yazma.** `pg_trgm` bəzi bazalarda `public`,
bəzilərində `extensions` sxemindədir. `extensions.gin_trgm_ops` yazsan
bir bazada işləyir, o birində «operator class does not exist» verir.
`set search_path = public, extensions` qoy, adı qısa yaz.

---

## CSS sinif adları — toqquşma

`assets/base.css` ortaq sistemdir. Yeni sinif adı verəndə **əvvəlcə
axtar** — bir dəfə `.mark` adını verdim, o ad artıq başlıqdakı loqo
nişanınındır (`.top .mark`) və onu sındırdı. Testlərdə də `.item` kimi
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
- Platforma seed sualları `ext_key` (`test-slug#sıra`) ilə tanınır —
  `07_seed_tests.sql` təkrar işlədiləndə sual çoxalmır, üzərinə yazılır.

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
