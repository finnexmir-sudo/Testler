# Qeydlər: Texniki tələlər və infrastruktur: Supabase, SQL Editor, miqrasiya, ANALYZE, marker, canlıda hansı miqrasiya, domen, oyaq saxlama, sürət

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## Supabase-də qurmaq

SQL Editor-da: `01` → `02` → `03` → `06` → `04` → `05`.
`db/test/` qovluğundakı fayllar Supabase-də **işlədilmir** — onlar `auth`
sxemini təqlid edir.

Sonra `db/test/verify.sql` işlət — 7 sətir, hamısı `OK` olmalıdır.

`muellim/config.js` doldurulmalıdır: `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
`service_role` açarı **heç vaxt** frontend faylına yazılmır.

---

## Sürət ölçəndə: əvvəlcə `ANALYZE`

Təzə qurulmuş bazada planlayıcının **heç bir statistikası olmur** və
tamam başqa plan seçir. Ölçdük:

| | `rpc_bank_facets` |
|---|---|
| statistikasız | **620 ms** |
| `analyze;`-dən sonra | **20 ms** |

Otuz dəfə fərq, kodda bir hərf dəyişmədən. Bu tələyə düşmək asandır:
bir dəfə «bankın süzgəci ağırdır, yenidən yazmaq lazımdır» deyə səhv
nəticə çıxarıldı — halbuki qüsur yox idi, sadəcə ölçü yalan idi.

`db/run.sh` artıq sonda `analyze` işlədir, ona görə yerli sınaq
bazaları düzgün ölçülür. **Canlıda** isə: bankın böyük yüklənməsindən
sonra (illik e-dərslik yeniləməsi, yeni fənn paketi) SQL Editor-da bir
dəfə `analyze;` işlədin. Supabase-in avtomatik `autoanalyze`-ı bunu
özü də edir, amma bir neçə dəqiqə gec — həmin aralıqda panel ağır
görünür.

Ölçmə qaydası: **əvvəl `analyze`, sonra ən azı iki dəfə çağır** (birinci
çağırış disk oxuyur), və nəticəni funksiyanın həqiqətən hesablandığı
formada al — `select 1 from (select f(...)) z` funksiyanı ümumiyyətlə
işlətmir.

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
dəyişmir. Hansı struktur faylının işlədildiyini və növbəti faylı deyir;
sonra sinif dublikatını yoxlayır və bankın vəziyyətini fənn-fənn
göstərir (mövzu/sual sayı, sualsız qalmış mövzu varsa xəbərdarlıq —
o, işlədilməmiş bank faylı deməkdir).

**`revoke ... from public` funksiya üçün kifayət deyil.** Supabase yeni
funksiyalara `anon` üçün EXECUTE-u **birbaşa** verir — PUBLIC-dən geri
almaq ona toxunmur. Müəllim funksiyası yazanda mütləq
`revoke all on function ... from public, anon` yaz.
İkinci qat: `05_grants.sql` sonda `anon`-dan bütün funksiyaları geri
alır və yalnız ağ siyahını (8 şagird + 3 valideyn + 2 «Bizə yaz» RPC-si) saxlayır —
unudulsa da sızmır.

**`05_grants.sql`-i köhnə sırada işlətmək huquq siləcək — özü bunu düzəldir.**
Bir dəfə canlıda belə oldu: `db/107_valideyn.sql` valideyn RPC-lərini
yaradıb `anon`-a EXECUTE verdi, sonra kimsə **köhnə** (valideyni
tanımayan) `05_grants.sql`-i yenidən işlətdi — o, ağ siyahıda olmayan
hər şeyi geri alır, nəticə: `permission denied for function
rpc_parent_login` canlıda. Faylı təkrar işlətmək də kömək etmirdi,
çünki köhnə versiya yalnız **geri alırdı**, heç nə **vermirdi**.
İndi `05_grants.sql` iki istiqamətdə işləyir: ağ siyahıda olmayanı
bağlayır, ağ siyahıda olub huququ itmişi **bərpa edir** — nə vaxt
işlənsə, nəticə eynidir, sıradan asılı deyil. Sınmış canlı bazanı tək
faylla düzəltmək üçün `db/113_valideyn_huquq_berpa.sql` da var (yalnız
o 3 valideyn RPC-sinə grant verir, başqa heç nəyə toxunmur).
Yoxlanır: `db/test/smoke_huquq.sql` — köhnə sıra ssenarisini qurub
`05_grants.sql`-in özünü sağaltdığını sınayır.

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

**`ok` / `warn` / `err` sinifləri `assets/base.css`-də mesaj qutusudur**
(padding, çərçivə, rəng). Vəziyyət sinfi kimi `class="plrow ok"` və ya
`class="dgrow ok"` yazanda sətir yaşıl karta çevrilir və şişir — canlıda
masaüstündə görünüb. Vəziyyət üçün `done`, `st-ok`, `st-mid`, `st-weak`
yaz. Eyni səbəbdən `<input type="checkbox">` `.plck` base `input`
qaydasından (40px, padding) azad edilir.

## Yeni sütun əlavə edəndə — RPC-yə də yaz (2026-09-23)

`db/192` testə vaxt limiti əlavə etdi: `tests.time_limit_sec` sütunu,
şagird tərəfi, server hesabı, güzəşt — hamısı düzgün. **Amma
`rpc_test_preview`-ə həmin sahəni yazmadı.**

Nəticə: müəllim 5 dəqiqə seçirdi, baza 300 saniyə yazırdı, ekran isə
heç nə göstərmirdi. Üç yer birdən boş qalırdı — vərəq başlığı, «vaxtsız»
çipi, çap başlığı. `t.time_limit_sec` sadəcə `undefined` idi.

**Bu imkan müəllim tərəfində heç vaxt işləməyib.** Şagird tərəfi
işləyirdi, çünki o, sütunu cədvəldən birbaşa oxuyur.

**Qayda:** cədvələ sütun əlavə edəndə, həmin sütunu oxuyan hər
`jsonb_build_object`-ə də əlavə et. Sütun var, RPC-də yoxdursa,
interfeys səssizcə boş qalır — nə xəta, nə xəbərdarlıq.

**Necə tapıldı:** başqa iş görərkən `e2e_vaxt.py` işlədildi və 3
uğursuzluq çıxdı. Əvvəl həmin testi «təmizdir» saymışdım — çünki
çıxışda `SEHV` sözünü sayırdım, bu test isə `UGURSUZ` yazır. Sayğac
sıfır verirdi.

**İkinci qayda:** testin nəticəsi **çıxış kodu ilə** oxunur, söz
saymaqla yox. `grep -c` fərqli yazılışı, çökməni və vaxt aşımını
görmür — üçü də «0 səhv» kimi görünür.

### Davamı: `db/224` eyni tələyə düşdü, əks istiqamətdə (2026-09-24)

`db/192`-nin buraxdığı sahəni `db/224` əlavə etdi — amma gövdəni
`pg_get_functiondef`-dən götürəndə `rpc_test_preview`-dən
**`'media_url', q.media_url,` sətrini itirdi**. Nəticə: müəllimin
kağız vərəqində sualın şəkli görünməz oldu. `db/188` məhz bundan
xəbərdarlıq etmişdi: «köhnə fayllarda media_url var idi, sonrakı
miqrasiyalar funksiyanı yenidən yazanda sütunu apardı».

`db/900` onu qaytardı.

**Qayda:** mövcud funksiyanı yenidən yazanda əlavə etdiyin sətri yox,
**itirdiyin sətri** axtar. Əvvəlki gövdə ilə yenisini sətir-sətir
tutuşdur (`diff`), «bir sətir əlavə etdim» deyib keçmə.

**Yoxlayıcı:** `test/e2e_sekil.py` — bu tələni tutan yeganə testdir
(«kağız vərəqdə şəkil var»). Vərəqə, nəticə ekranına və ya sual
payload-una toxunan hər dəyişiklikdən sonra onu işlət; `db/900`-dan
sonra `test/e2e_netice_sekli.py` də var.

### Üçüncü dəfə: `db/900` özü bir yeri qaçırdı — `rpc_attempt_sheet` (2026-10-01)

`db/900` şəkli üç yerdə qaytardı (şagirdin nəticəsi, kağız vərəq, hesabatın
`weak`-i). **Dördüncü yer qaldı:** müəllimin **cəhd vərəqi**
(`rpc_attempt_sheet`, şagird hesabatı → Tarixçə → cəhdə bas). Ekran
`fig(q.media_url)`-i çağırırdı, RPC isə sahəni vermirdi — qrafikli
sual vərəqdə şəkilsiz idi. `db/906` düzəltdi (eyni yol: `questions`-a
`left join`, nüsxə yox).

**Niyə qaçdı:** «hansı RPC-lər bu sahəni verir?» sualına **RPC-lərdən**
baxıb cavab axtardıq, ekrandan yox. Düzgün istiqamət tərsdir:
**ekran → onu bəsləyən RPC**. İnterfeysdə `fig(…media_url)` olan hər
yeri tap (`grep -n "media_url" muellim/app.js sagird/app.js`), hər biri
hansı RPC-dən oxuyur — hamısında sahə var?

**Hazır siyahı (səkkiz yer, hamısı `media_url` verməlidir):**

| kim | ekran | RPC |
|---|---|---|
| şagird | test | `rpc_start_attempt` |
| şagird | günlük 5 sual | `rpc_student_daily` |
| şagird | səhv dəftəri | `rpc_student_mistakes` |
| şagird | mövzu məşqi | `rpc_student_practice_next` |
| şagird | nəticə (təzə / sonradan) | `rpc_submit_attempt` / `rpc_test_result` |
| müəllim | kağız vərəq + çap | `rpc_test_preview` |
| müəllim | hesabat «Səhvlər» | `rpc_student_report` (`weak`) |
| müəllim | cəhd vərəqi | `rpc_attempt_sheet` |

`db/test/canli_yoxla.sql` bunu **canlıda** bir sorğu ilə yoxlayır
(`906b`). Yerli yoxlayıcılar: `test/e2e_sekil_netice.py` — vərəq, çap,
təzə və sonradan nəticə, **cəhd vərəqi**; 390 və 1280 px.
`test/e2e_netice_sekli.py` (900) — nəticə ekranı və hesabatın «Səhvlər»
sekməsi; `test/e2e_sekil.py` (188) — şagird test ekranı və bank.

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

## `run.sh` — bank faylı yoxdursa dayanmır (2026-09-07)

Tələ: bank sessiyası `run.sh`-ə 141–158 sətirlərini əlavə etdi, yerli
qovluqda fayl yox idi, `set -e` ilə `run.sh` yarıda kəsildi,
`test/01_grants.sql` və `05_grants.sql` işləmədi — harness **RLS-siz
bazada** iki suite xəta verdi (`ANON students cedvelini oxudu`, «Pulsuz
hedd asildi»), qalanı «keçdi». İndi bank məzmun faylları `bank <fayl>`
funksiyası ilə yüklənir: fayl yoxdursa stderr-ə `!! bank fayli yoxdur,
atlandi` yazır, davam edir. Kod faylları (11, 12, 29, 106) əvvəlki kimi
`psql -f`. Yeni bank faylı əlavə edəndə: `bil10-bank`-ı çək, `db/`-də
symlink qur (`ln -s ../../bil10-bank/db/<fayl> db/<fayl>`), `run.sh`-də
`bank <fayl>` sətri. Harnessdə «XETA» görəndə əvvəl `run.sh <db> --local`
çıxış kodunu yoxla.

## Domen — bil10.az (2026-09-07)

Sahiblik online.az (illik ~20 AZN, sənəd yoxlanışı «pending» → «aktiv»);
online.az DNS zonası vermir, ona görə nameserver **Cloudflare Free**-dədir
(`miles/zara.ns.cloudflare.com`), yazılar orada: 4 × A `@` →
185.199.108–111.153, CNAME `www` → `finnexmir-sudo.github.io`, hamısı
**DNS only** (boz bulud — narıncı olsa GitHub HTTPS sertifikatı verə
bilmir). Repo kökündə `CNAME` (= `bil10.az`) → GitHub Pages saytı kökdən
verir, köhnə `github.io/Testler/` ora yönlənir. `muellim/config.js`
STUDENT_URL/PARENT_URL `bil10.az`-dadır; parol bərpası `location.origin`
işlətdiyi üçün Supabase → Authentication → URL Configuration-da Site URL
`https://bil10.az` və Redirect `https://bil10.az/**` olmalıdır. Yeni domen
ilk günlər FortiGuard-da «Newly Observed Domain» kimi bloklana bilər
(iş/məktəb şəbəkəsi) — «re-evaluate» sorğusu göndərilib, vaxtla düşür.
Geri qaytarmaq: `CNAME` faylını sil, config ünvanlarını qaytar.

## İlk açılış niyə yavaş idi — ölçüldü, düzəldildi (2026-09-09)

İstifadəçi: «ilk proqrama girəndə 3-4 saniyə çəkir, normaldır?»
**Ölçdüm** (bil10.az və canlı Supabase):

| Nə | Vaxt |
|---|---|
| HTML (şəbəkədən — `sw.js` network-first, bilərəkdən) | ~0,3 s |
| `app.js` + `app.css` — **sıxılmış 125 KB** (xam 453 KB) | ~0,3–0,5 s |
| Supabase-dən bir yüngül oxu | ən az 0,38 · **ortanca 0,60** · ən çox 3,4 s |

Yəni **fayl ölçüsü günahkar deyil** — vaxtı ardıcıl (serial) gediş-gəlişlər
yeyirdi. Tapılan üç yer, üçü də düzəldildi:

**1. Jeton 401 gözləyirdi (`muellim/sb.js`).** Giriş jetonu **1 saat**
yaşayır. `sb.js` bitmə vaxtını qabaqcadan yoxlamırdı — sorğunu göndərir,
**401** alır, *sonra* yeniləyib təkrarlayırdı: `sorğu → 401 → yenilə →
təkrar sorğu` (**3** gediş-gəliş). İndi `saveSession()` **öz möhürünü**
vurur (`sb_exp = indi + expires_in`) və vaxtı keçibsə əvvəlcə yenilənir:
`yenilə → sorğu` (**2**). **Bir gediş-gəliş silinir.**
- Möhür bizim saatla vurulur → telefonun saatı səhv qurulubsa da işləyir
  (serverin `expires_at`-ına güvənsək, geri qalmış saat jetonu «diri»
  göstərərdi).
- `refresh()` **tək uçuşludur**: paralel beş sorğu bir yeniləmə çağırır.
  Supabase yeniləmə jetonunu hər istifadədə dəyişir — üst-üstə düşən iki
  yeniləmə sessiyanı qırardı.
- Başqa tab yeniləmiş ola bilər → əvvəlcə `adoptStored()`. **`loadSession()`
  işlətmə**: gizli rejimdə `localStorage` xəta atır və `S` sıfırlanardı —
  iş görən sessiya itərdi.
- **Yan tapıntı:** yeniləmə alınmayanda `sb:sessionend` siqnalı sinxron
  gedirdi; çağıran ekran ondan **sonra** öz «xəta» kartını çızıb giriş
  formasını üstələyirdi. İndi siqnal `setTimeout(...,0)` ilə gedir — giriş
  forması üstdə qalır.

**2. `rpc_home` iki dəfə çağırılırdı.** `boot()` zəng nöqtəsi üçün,
`screenHome()` lövhələr üçün — eyni anda, eyni cavab. `homeData()` **uçuşda**
olan sorğunu paylaşır (keş deyil: sorğu bitibsə növbəti çağırış təzə məlumat
alır — köhnə siqnal göstərmək olmaz). **Bir gediş-gəliş.**

**3. Səviyyələr və qruplar zəncir idi.** `loadLevels() → loadGroups() →
şagirdlər` = üç növbəli. İndi səviyyələr qruplarla **yanaşı** gedir;
`loadGroups(lvReady)` sinif adını çızmazdan əvvəl gözləyir — nəticə eynidir.
**Bir gediş-gəliş.**

**Ölçüldü (A/B, `test/_olcu.py`).** Hər sorğuya **300 ms** süni gecikmə;
gecikmə **serverdə** verilir (`X-Test-Delay`, mock `ThreadingHTTPServer`-dir),
ona görə paralel sorğular həqiqətən paralel gedir:

| Ssenari | Köhnə | Yeni |
|---|---|---|
| jeton diri — ekran çıxır | 0,88 s | 0,88 s |
| jeton diri — səhifə tam | 1,69 s | **1,18 s** |
| jeton bitib (günün ilki) — ekran | 1,17 s | **0,87 s** |
| jeton bitib — səhifə tam | 2,49 s | **1,68 s** |

Yəni günün ilk açılışında **3 növbəli gediş-gəliş** silindi (0,81 s × 300 ms).
İstifadəçinin real gecikməsi 0,3–0,6 s olduğuna görə bu, **təxminən 1–2 saniyə**
deməkdir — 3-4 saniyə **2-3 saniyəyə** düşür, sıfıra yox. Qalanı HTML + JS
yüklənməsi və Supabase-in öz dəyişkənliyidir (bir yüngül oxu 0,38 s ilə 3,4 s
arasında ölçüldü).

**Ölçmədə tələ:** `route` işləyicisində `time.sleep(...)` ETMƏ. Playwright-in
sinxron API-si marşrutları **bir-bir** işləyir — paralel sorğular süni növbəyə
düşür və ölçmə «növbəli dərinlik» yerinə «sorğu sayı» ölçür. Gecikmə serverdə
verilməlidir.

**Yoxlama:** `test/e2e_jeton.py` (15 yoxlama). İsrafı **sayır**: vaxtı keçmiş
jetonla serverə gedən sorğu **sıfır** olmalıdır; `rpc_home` **bir**; qruplar
sorğusu səviyyələrin cavabından **əvvəl** başlamalıdır. Düzəliş geri alınsa
üçü də düşür (yoxlanıldı). Əks tərəf də qorunur: jeton diridirsə **nahaq
yeniləmə getmir**, yeniləmə alınmasa **giriş ekranı** çıxır.

**Testdə tələ:** `pg.goto(PANEL); pg.reload()` — iki naviqasiya yarış yaradır,
birinci açılış jetonu yeniləyərkən ikincisi səhifəni öldürür. **Bir** naviqasiya.

**Yol boyu tapılan köhnə səhv (mənim dəyişikliyim deyil — köhnə fayllarla da
təkrarlandı):** `#btnAdm` (İdarəetmə bəndi) `#hTop` blokunun **içində** idi.
Qrupu olmayan hesabda `loadGroups()` «ilk qrupunuzu yaradın» düzümünə keçib
`#hTop`-u gizlədir — **admin öz idarəetmə ekranını görmürdü**, yalnız ünvanı
əl ilə yazmaqla aça bilirdi. Bənd indi blokdan **kənardadır**; qruplu hesabda
görünüş dəyişmir. `e2e_paket` bunu indi açıq yoxlayır (əvvəl orada `ok(True, …)`
dayanırdı — heç nə iddia etmirdi).

**Hələ qalan:** `bump.sh` versiyanı dəyişəndə keşdəki bütün CSS/JS yeni ünvan
olur — hər push-dan sonra ilk açılış həmişə yavaşdır. Adi müəllim bunu yalnız
yeni versiya çıxanda bir dəfə görür, ona görə toxunulmadı.

## db/197 — canlıda nümunə nüsxələri silinmirdi (safeupdate, 2026-09-16)

İdarəetmədə «Nümunə hesablar 21 MB · 52 427 cavab · 745 şagird» (≈30
nüsxə). Səbəb: GitHub Actions «oyaq-saxla» işi 12–16 sentyabr hər gün
`rpc_demo_reset`-də **HTTP 400 «DELETE requires a WHERE clause»** ilə
uğursuz bitirdi — Supabase PostgREST sessiyasında `safeupdate` var,
funksiyadakı `delete from demo_old;` (müvəqqəti cədvəl) qadağandır. Yerli
Postgres-də safeupdate yoxdur, smoke keçirdi. **Qayda: RPC gövdəsində
WHERE-siz DELETE/UPDATE yazma** — `where true` yaz; `smoke_numune.sql` §9
bütün `public.rpc_%` funksiyalarını bu naxışa yoxlayır. `db/197` yalnız
funksiyanı yenidən yaradır (imza eyni, grant içindədir, 05_grants lazım
deyil). **Canlıya əl ilə tətbiq olunmalıdır**; sonra Actions → «Supabase-i
oyaq saxla» → Run workflow ilə yoxlanır (HTTP 200 + `deleted_copies`).
Actions uğursuzluğu heç kimə görünmürdü — nəticələrə arabir bax.

## db/198 — nümunə «Bizə yaz» yazısı silinmiş hesabdan sonra real görünürdü (2026-09-16)

İdarəetmədə «19 yeni müraciət» — hamısı eyni mətn («Qrup hesabatında zəif
mövzuların yanında «təkrar dərs» üçün hazır test düyməsi…»), göndərən
«Müəllim», ad/e-poçt boş. Bu, `app.demo_build`-in nümunə hesaba yazdığı
nümunə yazıdır. `feedback.account_id / user_id` FK-ları ON DELETE SET NULL
olduğu üçün nüsxə silinəndə sətir NULL-larla qalır, `feedback_is_demo(NULL,
NULL)` false verir və sətir real müraciət kimi çıxır. `db/198`: (1)
`accounts` BEFORE DELETE trigger-i `is_demo` hesabın feedback sətirlərini
silir, (2) bir dəfəlik yetim təmizliyi, (3) üç açarı da NULL olan sətir
nümunə sayılır. `smoke_numune.sql` §10. **Canlıya əl ilə tətbiq
olunmalıdır**, 05_grants lazım deyil. Qayda: nümunə quruluşuna yeni cədvəl
əlavə edəndə FK-nın SET NULL olub-olmadığına bax — SET NULL-dursa silinmə
yolunda ayrıca təmizlə.

## Marker üsulu canlıda sındı — gövdəni TAM yaz (2026-09-18)

`db/211` canlıda işlədiləndə dayandı:

```
ERROR: 211: rpc_student_mistake_answer markeri 1 defe olmalidir
```

**Nə baş verirdi.** Bir neçə miqrasiya mövcud funksiyanı «marker» ilə
genişləndirirdi: `pg_get_functiondef()` ilə gövdəni oxu, içindəki bir
mətn parçasını tap, onu əvəz et, `execute` et. Bu üsul **canlıdakı mətnin
bizim fayldakı ilə hərfbəhərf eyni olmasını** tələb edir — boşluq, sətir
sonu, hər şey. Canlıda fərqli çıxdı və fayl dayandı.

Yaxşı tərəfi: səssiz sınmadı, açıq xəta verdi. Pis tərəfi: uzaqdan
diaqnostika etmək lazım gəldi və istifadəçi gözlədi.

**Qayda: mövcud funksiyanı dəyişirsənsə, gövdəni TAM yaz.** `db/175`
bunu artıq etmişdi və səbəbini də yazmışdı («fayl TƏK BAŞINA tətbiq
olunanda da doğru nəticə versin») — mən o dərsi təkrarlamadım.

Tam gövdə yazmağın üstünlükləri:
- canlıdakı mətndən **asılı deyil** (boşluq, sətir sonu fərq etmir);
- **idempotentdir** — neçə dəfə işlədilsə eyni nəticə;
- əvvəlki miqrasiya atlanıbsa belə düzgün nəticə verir;
- oxuyan adam funksiyanın son halını **bir yerdə** görür.

Yeganə xərci: fayl uzanır. Dəyər.

Düzəldilənlər: `db/211` (rpc_student_mistake_answer) və `db/215`
(rpc_admin_stats) — ikisi də artıq tam gövdə yazır, `pg_get_functiondef`
işlətmir. Yoxlandı: canlıdakı kimi **fərqli mətnli** gövdə quruldu, fayl
yenə keçdi; iki dəfə ardıcıl işlədildi, problem yoxdur.

**Hələ marker işlədən fayllar:** `db/209` və `db/213` (`rpc_home`),
`db/214` (qoşulmayıb). Onlar canlıda keçib, amma növbəti dəfə eyni şey
təkrarlana bilər — toxunanda tam gövdəyə keçir.

## Canlıda hansı miqrasiyalar var? — `db/test/canli_yoxla.sql` (2026-09-18)

**Sistemli problem.** Miqrasiyalar Supabase SQL Editor-a **əl ilə**
yapışdırılır. Bir fayl atlanırsa **heç bir xəta çıxmır** — sadəcə həmin
imkan işləmir və biz bunu aylar sonra, təsadüfən görürük.

2026-09-18-də məhz belə oldu: `db/210` və `db/211` atlanmışdı. Nəticə:
- şagird «Səhv dəftəri»ndəki 17 sualın **heç birini işləyə bilmirdi**
  (mövzu sətri yox idi, düymə yox idi);
- `db/211`-in abunə qapısı da qüvvədə deyildi — məşq pulsuz hesabda da
  açıq qalmışdı, halbuki qərar əksinə idi.

İkisi də səssiz idi. Nə panel xəta verirdi, nə də biz bilirdik.

**Həll:** `db/test/canli_yoxla.sql` — bir sorğu, hər miqrasiya üçün bir
sətir (`var_mi = true/false`). Supabase SQL Editor-a yapışdır, Run.
`false` olan hər sətir işlədilməmiş fayldır.

**Qayda:** yeni miqrasiya yazanda bu fayla **bir sətir əlavə et**. Barmaq
izi kimi yalnız həmin faylda olan bir şey seç: funksiya gövdəsindəki
unikal söz, yeni sütun və ya yeni cədvəl. Fayl əlavə etmək 30 saniyədir;
atlanmış miqrasiyanı sonradan tapmaq bir gün apardı.

**Həmçinin:** hər dəfə SQL işlədəndən sonra bunu bir dəfə işlət — «hamısı
true» görmədən «canlıya çıxdı» demə.

## Supabase-i oyaq saxlamaq — `.github/workflows/oyaq-saxla.yml`

Pulsuz Supabase 7 gün sorğu olmayanda layihəni dayandırır. GitHub
Actions hər gün 05:17 UTC-də `plans` kataloqundan bir sətir oxuyur
(anon açar `muellim/config.js`-dən götürülür — onsuz da açıqdır; sirr
yoxdur). Uğursuz olanda GitHub e-poçt bildirişi göndərir. GitHub 60 gün
commit olmayan repoda cədvəlli işi söndürür — Actions sekməsində
«Enable workflow». Bu körpüdür: real istifadə başlayanda ehtiyac qalmır.

NİYƏ: ölçüldü (`test/_suret.py`) — panelin soyuq açılışı zəif 3G-də
3,5 saniyə çəkirdi, vaxtın ~60%-i fayl yükləməsi idi. Sıxılmadan sonra:

| şərait | əvvəl | sonra |
|---|---|---|
| yaxşı 4G | 913 ms | 417 ms |
| adi 4G | 1738 ms | 1147 ms |
| zəif 3G | 3480 ms | 2659 ms |

Ümumi yük 241 KB → 160 KB (sıxışdırılmış).

---
