# Qeydlər: Sual bankı: qaydalar, yazma, çətinlik, oxşarlıq, mövzu ağacı, kurikulum, parametrik, adaptiv, diaqnostik

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

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

## Cavabsız qalan sual «səhv» deyil

`rpc_submit_attempt` **iki faylda** yazılıb: `03_rpc.sql` (doğru,
təzə) və `11_sual_banki.sql` (köhnə surət). Hansı sonuncu işləyirsə,
o qalır. Təzə baza qurulanda `03` axırda olur; tarixi ardıcıllıqla
gedəndə isə `11` axırda qalır və **köhnə gövdə qayıdır**:

| | toxunulmamış sual |
|---|---|
| köhnə gövdə | `is_correct = false` — «səhv etdi» |
| təzə gövdə | `is_correct = null` — «çatdırmadı» |

Bal ikisində də sıfırdır, ona görə görünmürdü. Amma hesabatda
«mövzunu bilmir» ilə «vaxtı çatmadı» bir-birindən ayrılmalıdır —
müəllim ikisinə ayrı reaksiya verir.

`db/104_cavabsiz_sual.sql` sıranın sonunda doğru gövdəni bərpa edir.
Fayl `03_rpc.sql`-dən **proqramla** çıxarılıb. Köhnə cəhdlərə
toxunulmur: keçmiş nəticəni sonradan dəyişmək müəllimin gördüyü
hesabatı pozardı.

**Bu, `miqrasiya.sh` sərtləşdiriləndə tapıldı.** Əvvəl o, yalnız
`questions` indekslərini və üç cədvəlin sütunlarını tutuşdururdu —
funksiya gövdəsinə baxmırdı, ona görə `103` faylı siyahıdan düşdüyü
halda da yoxlama səssizcə keçirdi. İndi `public`/`app` sxemindəki
bütün funksiyaların gövdəsi də tutuşdurulur.

## Bank siyahısında variantlar — abunə ilə

`rpc_bank_list` **abunə tələb etmir**: pulsuz qeydiyyatdan keçən
istənilən hesab 100-lük səhifələrlə bütün platforma bankını oxuya
bilər. Ona görə sual mətnləri açıq, **düz cavablar isə bağlıdır** —
`rpc_bank_samples`-in 3-lük həddi də elə bunun üçündür.

`db/106_bank_siyahi_variantlar.sql` siyahıya variantları əlavə etdi,
amma bu qapını **açmadan**:

| Kim | Nə görür |
|---|---|
| öz sualı (`owner_type = 'educator'`) | həmişə variantlar |
| aktiv abunə və ya admin | variantlar |
| abunəsiz hesab, platforma sualı | `options: []` |

Abunəçi cavabları onsuz da görür (mövzudan test yığıb vərəqi açır) —
yəni yeni sızma yolu yaranmır, mövcud hüquq rahat göstərilir.

**Bunu dəyişməzdən əvvəl:** `smoke_bank_rpc.sql`-in 8-ci yoxlaması və
`smoke_siyahi_variant.sql`-in 6-cısı bu qapını qoruyur. Onlar sınırsa,
bank pulsuz yüklənə bilir deməkdir.

## Azərbaycan hərfləri — test yazanda tələ

İki dəfə eyni yerə düşdük, ona görə yazılır.

**1 · `base.css` `h2`-ni BÖYÜK HƏRFƏ çevirir.** Playwright-in
`inner_text()` ekranda **görünən** mətni qaytarır, ona görə
`"Gözləyən tapşırıq" in metn` tapmır — orada `GÖZLƏYƏN TAPŞIRIQ` var.

**2 · `.lower()` bunu DÜZƏLTMİR.** Python `"TAPŞIRIQ".lower()` →
`"tapşiriq"` verir: nöqtəsiz **ı** nöqtəli **i**-yə çevrilir. Yəni
kiçik hərfə salıb müqayisə etmək daha da yanıldır.

Qayda: yoxlamada nöqtəsiz `ı` olmayan hissəyə baxın (`"GÖZLƏYƏN"`),
və ya `data-*` nişanı ilə seçin — mətnlə yox.

## Kataloq — hər sinif BİR dəfə

`programs` təhsil kateqoriyasıdır, `levels` onun içindəki pillə.
Sinif kodu (`1`…`11`) bütün kataloqda **bir dəfə** olmalıdır.

Bir dəfə pozuldu: `04_seed.sql` 9-11-i `buraxilis` proqramında
yaradırdı, `41/45/49_movzular_orta*.sql` isə eyni sinifləri `orta`da
yaradıb bütün mövzu və sualları oraya yığdı. Nəticə: qrup yaratma
formasında siniflər ikiləşdi, dərs planı isə sinfi
`where code = ... limit 1` ilə tapdığı üçün **boş** sətri seçə bilirdi
— plan yaranmırdı, kod düzgün olsa belə.

Qərar: məzmun `orta`dadır (adı «Orta və yuxarı siniflər (5-11)»),
`buraxilis` sinif saxlamır. Səbəb: bankın məzmunu e-dərslik
dərsliyidir — adi məktəb proqramıdır, buraxılış imtahanı hazırlığı
deyil. 9-cu sinif şagirdinin həftəlik testini «Buraxılış imtahanı»
adı altında göstərmək yanlış olardı; `buraxilis` slug-ı sonra **əsl**
imtahan hazırlığı üçün boş qalır (slug ilə mənanın ayrılması
uzunmüddətli tələdir).

Köhnə baza üçün: `db/57_sinif_dubli.sql` — boş sətirə bağlanmış
qrup/test/sual **silinmir**, eyni kodlu `orta` səviyyəsinə köçürülür
(`classes`/`tests` həm `program_id`, həm `level_id` saxlayır — ikisi
də köçürülməlidir).

`test/smoke.sql` bunu daimi iddia kimi yoxlayır (12-ci yoxlama);
`db/test/hardayam.sql` isə bazaya baxıb «57 lazımdır/lazım deyil»
deyir. Yeni sinif və ya proqram əlavə edəndə əvvəlcə kataloqa bax.

---

## «Dərsə 20 sual» = 20 FƏRQLİ sual (2026-09-23)

Bank dərs nişanı yazmağa başlayanda hədd qoyduq: dərs testi açılmaq
üçün həmin dərsin **20 nişanlı sualı** olmalıdır (`app.ders_min()`).
Amma generator sualları **sadəcə saymır** — təkrarı özü atır
(`db/13_generator.sql`):

| süzgəc | qayda |
|---|---|
| gövdə oxşarlığı | trigram `similarity ≥ 0.95` → sual atılır |
| eyni düzgün cavab | `ceil(sual sayı / 7)` dəfədən çox olmaz |

İkincisi riyaziyyatda tez dolur: **10 suallıq testdə eyni cavab ən çoxu
2 dəfə.** «0», «1», «düzdür» kimi cavablar dörd sualda təkrarlansa,
ikisi atılır.

**Ölçüldü:** sınaq məlumatında 20 sual var idi, hamısının cavabı «düz» —
generator 2 sual gördü və «kifayət qədər fərqli sual tapılmadı» xətası
atdı. Yəni **hovuzda 20 sətir olması bəs etmir**, 20-si bir-birindən
fərqlənməlidir.

Bank yazanda: gövdələr qəlibcə eyni olmasın, düzgün cavablar bir
dəyərin ətrafında yığılmasın.

### Sual seçimində sıra (db/223)

`app.generate_pick` bu sıra ilə seçir:

1. **mövzu balansı** (`rn_topic`) — bir mövzu bütün testi udmasın
2. **səhv-bənzərlik** (`rem`) — təkrar testində şagirdin səhv etdiyi sual önə
3. **təzəlik** (`isk`) — qrupa əvvəl verilmiş sual növbədə geri qalır
4. təsadüf

Üçüncüsü **şərt deyil, meyildir**. Dar hovuzda sərt süzgəc «kifayət sual
yoxdur» xətası verərdi; meyil isə təzəni önə çəkir, çatmayanda köhnəsini
götürür — **test həmişə yığılır**.

## Mövzu ağacı — sual hovuzu FƏSİLDƏDİR, yarpaqda deyil

**2026-09-22.** Bank örtüyünü ölçəndə üç dəfə yanlış nəticə verdim,
çünki modeli yaddaşdan təxmin etdim. Model belədir:

- **Fəsil** (`topics.parent_id is null`) — **sual hovuzu buradadır.**
- **Alt mövzu** (yarpaq) — **plan ritmi üçündür, öz sualı yoxdur.**
  Dərs planının sətirləri yarpaqlardır ki «N/M mövzu» real dərs sayı
  olsun. `rpc_plan_test` fəsil bitəndə çıxır və **valideynin**
  mövzusundan yığır. `app.diag_topics` da `parent_id is null` ilə işləyir.

Yəni **yarpağın boş olması nasazlıq deyil, dizayndır.** Mənbə:
`db/101_ders_plani_alt.sql` — başlıqdaki şərh bunu açıq yazır.

Örtüyü ölçəndə ölçü vahidi **fəsildir** və sayım **alt ağacı bütöv**
götürməlidir (fəsil + bütün nəsli). Hazır sorğular:
`db/test/bos_fenn.sql` (fənn × sinif xülasəsi) və
`db/test/bos_movzular.sql` (adbaad).

**Ümumi dərs, ölçüdən kənar:** hər şeyi işarələyən ölçü heç nəyi
işarələməyən ölçü qədər yararsızdır. `asili_suallar.sql` 22 963 sualın
17 270-ni «itib» göstərdi — hamısı yerində idi. Silindi. Bir ölçü
qərar dəyişdirmirsə, onu yazmaq deyil, atmaq lazımdır.

## Arifmetik terminlər — mənbə e-dərslikdir, yaddaş yox

**2026-09-22.** Bankda çıxma sualları bir pillə sürüşmüş terminlə
yazılmışdı («çıxılan» = azalan, «çıxan» = çıxılan). Düzəlişi
hazırlayanda mübahisə çıxdı: başqa bir AI iddia etdi ki, Azərbaycan
dərsliklərində «çıxılan» yoxdur, «çıxan» var.

**Rəsmi mənbə yoxlandı** — e-dərslik, Riyaziyyat, «çıxma əməlinin
komponentləri» (kitab 665, vahid 1, səh. 75):

```
a − b = c
a = azalan     b = çıxılan     c = fərq
18 − 1 = 17  ->  18 azalan, 1 çıxılan, 17 fərq
```

«Çıxan» sözü orada **ümumiyyətlə işlənmir**. Türkcədə «eksilen −
çıkan = fark»dır; bankdakı səhvin mənbəyi çox güman elə budur.

| Əməl | Komponentlər |
|------|--------------|
| toplama | toplanan + toplanan = **cəm** |
| çıxma | **azalan** − **çıxılan** = **fərq** |
| vurma | vuruq × vuruq = **hasil** |
| bölmə | bölünən : bölən = **qismət** |

**Qayda:** termin mübahisəsində heç kimin (nə mənim, nə başqa modelin)
yaddaşı dəlil deyil — e-dərslik açılır, sətir sitat gətirilir.
Süzgəc: `db/test/termin_yoxla.sql`, düzəliş: `db/test/termin_duzelt.sql`.

**İki düzəliş yolu, bir nəticə.** Canlı `termin_duzelt*.sql` ilə (uuid
üzrə) düzəldildi; mənbə bank faylları (75, 76, 19, 16, 78, 204, 231, 250,
251) isə ayrıca, əl ilə. İki yol eyni cümləni bəzən fərqli yazır və
köhnə böyük bank faylları canlıda təkrar işlədilə bilmir (son say
yoxlamaları köhnəlib). Ona görə **`bil10-bank/db/254`** var: 27 sualın
mətnini mənbə ilə birəbir eyniləşdirir, idempotentdir, bayrağa
toxunmur — canlıda `termin_duzelt`-dən sonra da işlədilməlidir.
Bank sessiyasının geniş süzgəci: `bil10-bank/db/test/termin_yoxla_bank.sql`
(§1 nişanlama, §2 «azalan» ayırıcısı ilə, §3–5).

**254 şablonu pozdu (2026-09-23).** 27 açardan biri (`riy3-cixma#16`) `db/251`-də
şablona çevrilmişdi; 254 onun üzərinə adi mətn yazdı, `params` qaldı — sual
hər cəhddə eyni rəqəmlə çıxırdı. 254-dən çıxarıldı (26 açar), `bil10-bank/db/260`
şablonu bərpa edir — canlıda 254-dən sonra işlədilməlidir. Hansı bank faylının
canlıda olduğunu `bil10-bank/db/test/canli_bank_yoxla.sql` deyir (yalnız oxuyur;
kod miqrasiyaları üçün `db/test/canli_yoxla.sql`). Qayda: yerində düzəliş faylı
yazanda `params is not null` olan sualları çıxar.

Mənbə: http://www.e-derslik.edu.az/books/665/units/unit-1/page75.xhtml

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
  (`tools/` və `mundericat/` `bil10-bank` private repo-dadır, bax
  yuxarı «db/ fayl nömrələri».)
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
  (1-2-ci siniflər, 4 fənn bir yerdə), `db/80_bank_ing.sql` (İngilis
  dili 1-4). Orta və yuxarı siniflər: hər sinif üçün əvvəl mövzu ağacı
  (`25/29/33/37/41/45/49_movzular_orta5…11.sql`), sonra banklar —
  `26/30/34/38/42/46/50_bank_riy5…11.sql` (riyaziyyat),
  `27/31/35/39/43/47/51_bank_sinif5…11.sql` (az dili, ingilis,
  informatika, tarix), `32/36/40/44/48/52_bank_fenn6…11.sql`
  (fizika/kimya/biologiya/coğrafiya — hansı fənn o sinifdə varsa).
  9-11-ci siniflərdə tarix Azərbaycan tarixidir, 10-cu sinifdə ümumi
  tarix. **Əllə yazılmır** —
  `tools/riyN.py`, `tools/sinifN.py`, `tools/fennN.py`, `tools/ing.py`
  yaradır. Skript hər riyazi cavabı yenidən hesablayıb düzgün variantla
  tutuşdurur; düzəliş skriptdə edilir, sonra SQL yenidən çıxarılır.
  Yeni fənn/sinif bankı üçün eyni qəlibi izlə: `tools/<fənn><sinif>.py`
  → `db/NN_bank_<fənn><sinif>.sql`, ext_key `<qısaad>-<mövzu>#<sıra>`.
  Yeni bank hazır olanda: movzu daxilində və qonşu siniflərlə pg_trgm
  ≥0.95 təkrar yoxla, fənn üzrə eyni düzgün cavab ≤2 olsun,
  `rpc_generate_test` balans yoxlaması işlət (nümunə:
  `test/smoke_generator.sql`).
  (Bu bənddə adı çəkilən bütün `db/NN_bank_*.sql` faylları və
  `tools/*.py` skriptləri `bil10-bank` private repo-dadır, bu repoda
  deyil — bax yuxarı «db/ fayl nömrələri».)
- **Kiril oxşarı hərf tələsi.** `а е о р с х у М Т В` latın hərfləri
  ilə eyni görünür, amma fərqli koddur — belə hərf düşən sual
  axtarışda tapılmır və pg_trgm yoxlaması onu təkrar saymır.
  `tools/fenn11.py`-dəki `yoxla()` bunu tutur (`Ѐ`–`ӿ` aralığı);
  yeni skript yazanda həmin yoxlamanı da köçür.

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

## Diaqnostik test — «bu uşaq nəyi bilmir?»

`db/118_diaqnostika.sql`. Yeni şagird gələndə müəllim şagird hesabatında
«Diaqnostik test ver» basır: sinfin **bütün** fəsillərindən (üst
səviyyə mövzu; suallar fəslə bağlıdır, alt mövzunun hovuzu yoxdur) hər
birinə **3 sual** — asan/orta/çətin varsa, yoxsa nə varsa — bir cəhd,
yalnız o şagirdə, 75 san/sual. Nəticə **mövzu xəritəsi**: 3/3 yaxşı,
2/3 orta, 0–1 zəif (`app.diag_status`, hesabatdakı meter hədləri 75/50),
«bundan başla» (qırmızılar, sonra narıncılar, kurikulum sırası, ən çoxu
3), eyni fənndə əvvəlki diaqnostika ilə fərq («1 zəif → 0», hər sətirdə
↑/↓/=). Zəif fəsillərdən bir klikə düzəliş testi (`remedialGen`).

**Niyə 3 sual.** `app.min_topic_answers()` = 3 — ondan az cavabla mövzu
analizi susur. 15 mövzuya 30 sual versən mövzu başına 2 düşür, xəritə
boş qalır: say mövzudan çıxır, əksi yox. Ümumi tarix 9/11-də bəzi
fəsillərdə <3 sual var — onlar testə düşmür (`app.diag_topics`).

**Abunə.** Test platforma bankından yığılır → `rpc_generate_test` və
`rpc_remedial_test` kimi abunə paketində (bir diaqnostika 30+ platforma
sualını pulsuz açardı — bank sızması). Müəllimin xəritəsi hesabatdakı
`topics` kimi abunə ilə; abunə bitəndə xəritə bağlanır, bal qalır.
**Şagirdin öz xəritəsi pulsuzdur** (114-dəki «öz zəif mövzuları»
qərarı ilə eyni) — `rpc_submit_attempt`/`rpc_test_result` diaqnostik
testdə `topics` qaytarır, düz cavab yox, yalnız say.

**Dublikat yoxdur:** açıq, yazılmamış diaqnostika varsa `rpc_diagnostic_create`
onu qaytarır (`existing: true`). Yazılandan sonra yenisi yaranır — fərq
üçün. Pilot müəlliminə abunə sətri əl ilə verilir (`subscriptions`).

RPC-lər (authenticated): `rpc_diagnostic_options(student)` — sinif,
fənnlər (fəsil/sual sayı, son diaqnostika), `rpc_diagnostic_create(student,
subject, days)`, `rpc_diagnostic_result(student, subject)`. Nişanlar:
şagird siyahısında `diagnostic`, valideyndə `diag`, başlıq «Diaqnostika ·
Fənn · Sinif». UI: `muellim/app.js` `loadDiag/drawDiag` (`#diagBox`),
`sagird/app.js` `diagMap`. Testlər: `db/test/smoke_diaqnostika.sql` (10),
`test/e2e_diaq.py`.

**Tələ — diaqnostik test «Test yığ» siyahısında adi test kimi açılır.**
Orada «Yenidən yığ» (`rpc_regenerate_test` → ümumi generator `kind:
'diagnostic'` qaydasını tanımır, testi təsadüfi suallarla doldurar) və
«Qrupa təyin et» (bütün qrup «hər mövzudan 3 sual» yazar, xəritə fərdi
təyinata baxdığı üçün tapılmaz) var idi. `119_diaqnostika_qoruyucu.sql`
ikisini də serverdə rədd edir (yalnız öz şagirdinə təyinat keçir —
müddəti uzatmaq üçün), `drawPaper` isə diaqnostik testdə həmin
düymələrin yerinə «Diaqnostika» qeydi və şagird ekranına keçid göstərir.
Yeni RPC diaqnostik testə toxunursa `is_diagnostic`-i yoxla.

`07_seed_tests.sql`-dəki «Nümunə — ödənişli test» (slug riy-3-analiz,
köhnə adı «Genişləndirilmiş analiz testi») bunun köhnə yer tutucusudur —
məhsul deyil; canlıda `121_numune_test_gizli.sql` ilə draft-dır, yerli
test bazasında qalır (`run.sh --local` 121-i keçir, kilid yoxlaması ona
bağlıdır), bələdçi şəkillərində gizlədilir.

## Bank həcmi yalnız adminə

`showBankN()` (= `isAdmin()`) — bankın ölçüsü («Bankda 19 270 sual»,
fənn/sinif/mövzu başına say, çətinlik bölgüsü, diaqnostika seçimində
«· 36 sual») adi müəllimə göstərilmir (istifadəçi qərarı: rəqibə bank
ölçüsü və zəif fənn görünməsin). Testin öz sual sayı («6 sual», «36 sual
yığılacaq») hər yerdə qalır. Öz sualları hovuzunda say qalır — müəllimin
özünündür. e2e_bank say yoxlamalarından əvvəl müəllimi admin edir.

## Kurikulum paketi — dərs paketi (yol xəritəsi 22.d)

`db/135_kurikulum_paketi.sql`. Mövcud generator + təyinat üzərində:
- `class_plan_items.warm_test_id` (isinmə; `test_id` ev tapşırığıdır),
  `plan_exams(plan_id, test_id, item_ids[], created_at)`.
- `rpc_pack_warm(item, count=5)` — mövzu keçilməmiş də olar; qayda
  `{pool all, topics [fəsil], difficulty ["1","2"], pack 'warm'}`, ad
  «İsinmə — Fəsil», 1 gün, 1 cəhd; ikinci dəfə rədd.
- `rpc_pack_exam(plan, count=20, all=false)` — keçilmiş və hələ heç bir
  sınaqda olmayan mövzular (`all` → hamısı), ad «Rüb sınağı — Fənn · N
  mövzu», 7 gün, 1 cəhd, `plan_exams` sətri; `gen_rule.pack='exam',
  plan`.
- Ev tapşırığı — mövcud `rpc_plan_test(item, 10)`.
- `rpc_pack_get(plan)` → `{plan{…,total,done}, paid, students,
  exam_pending, items[{…, warm{test_id,avg,takers}|null, hw{…}|null,
  examined}], exams[…]}`. `rpc_lesson_prep.next` + `warm_test_id/
  warm_avg/warm_takers`, üst `plan_id`; `rpc_plan_get` item +
  `warm_test_id`.
- Panel: `#/pk/<plan>` `screenPack/drawPack` (`.pktab` cədvəl
  `.pkr[data-i]`, `[data-pkwarm]/[data-pkhw]`, `.pkc.has` nəticə,
  `#pkExam/#pkExamAll/#pkCnt`, `#pkMsg` — `PK_FLASH` yenidən yükləmədə
  qalır); plan kartında `.plpack` linki; «Bu günün dərsi»də `#prepWarm`.
- Yoxlama: `smoke_kurikulum.sql` (3), `test/e2e_kurikulum.py`; bələdçi
  müəllim addım 11 + addım 8 bullet, şəkil `m14_paket`.

## Sual keyfiyyəti təhlili (yol xəritəsi 22.g)

`db/134_sual_keyfiyyeti.sql`. Cədvəl `question_stats(question_id, n, p,
rpb, opts, flags[], sev, hidden_at, computed_at)`. `app.qstat_rows(q)`
set-əsaslı hesablayır (yalnız submit olunmuş cəhdlər, `is_correct not
null`): `p` düz faizi, `rpb = corr(düz/səhv, cəhdin faizi)` nöqtə-biserial
ayırdetmə, `opts[{id,body,correct,n,pct}]`. Siqnallar `n ≥ app.qstat_min()
= 20`: `acar` (distraktor düzdən çox seçilib, sev 4), `menfi` (rpb<0, 3),
`cetin` (p<20, 2), `olu` (seçilməyən distraktor <2%, 1), `zeif`
(0≤rpb<0.1, n≥30, 1), `asan` (p>95, n≥40, 0). Yazılı sualda acar/olu yoxdur.
- `rpc_admin_qstats(flag, limit, force)` — 1 saatdan köhnədirsə və ya
  `force` `app.qstat_refresh()`; `{computed_at, min_n, rated, counts{all,
  acar,…,hidden}, items[…]}` sev/n sırası; `flag='hidden'` baxılanlar.
  `rpc_admin_qstat_hide(q, bool)` «Baxıldı»/«Geri qaytar»; yenidən
  hesablama gizlini geri gətirmir. Düzəliş (`rpc_admin_fix_question`)
  sonra panel özü `hide` çağırır — köhnə cəhdlər köhnə açarla sayılıb.
- `rpc_bank_question.stats{n,p,rpb,flags}` canlı (bir sual üçün) —
  redaktorda `.qstat` sətri (`qstatText`, n≥10).
- Panel: admin ekranında «Sual keyfiyyəti» (`qsSection/qsCards/bindQs`,
  `#qsF` çipləri sayğacla + `#qsRefresh`, `.qsc` kart: `.qsflags`,
  `.qso` variant zolaqları, «Düzəlt» = `fixForm` (opts `correct` →
  `is_correct` çevrilir), `[data-qhide]/[data-qshow]`).
- Yoxlama: `smoke_keyfiyyet.sql` (3), `test/e2e_keyfiyyet.py`; bələdçi
  müəllim addım 5 bullet.

## Adaptiv mövzu məşqi (yol xəritəsi 22.b)

`db/133_adaptiv_mesq.sql`. Cədvəl `practice(student_id, topic_id, score
0..100, streak, answered, correct, seen uuid[] (son 30), cur jsonb
{q, params, at}, mastered_at)`. Üç anon RPC (05_grants siyahısı 18):
- `rpc_student_practice_topics(token)` → `{enabled, reason, level,
  mastered, active, subjects[{name, topics[{id,name,n,score,answered,
  mastered,level,why(zəif|dərs),at}]}]}`. Əhatə `app.practice_scope`:
  qrupun `free_practice` bağlıdırsa və ya `level_id` yoxdursa `enabled=false`
  (səbəblə). Mövzular: **kök** mövzular (platforma sualları kök mövzuya
  bağlıdır), qrupun sinfi, hesabın `subjects` (boşdursa hamısı), hovuzda
  ≥5 sual (`app.practice_pool`: platforma + hesabın öz dərc olunmuş
  sualları, `level_id` = sinif və ya null).
- `rpc_student_practice_next(token, topic)` → sual (düz variantsız,
  şablon 132 təzə rəqəmlə). `cur` 1 saat ərzində cavabsızdırsa eynisi
  qayıdır (səhifə yeniləmə). Seçim: çətinlik `app.practice_level(score)`-ə
  ən yaxın (<35 → 1, <75 → 2, sonra 3), `seen`-də olmayan əvvəl, sonra ən
  köhnə, sonra random.
- `rpc_student_practice_answer(token, topic, q, option_ids[], text)` —
  yalnız `cur.q`-ya qəbul (təkrar göndərmə yoxdur). Bal: düz `+8+4·çətinlik`
  (bal<80) / `+4+2·çətinlik` (≥80); səhv `−8` / `−12`; 100 → `mastered_at`
  (`just_mastered` bir dəfə). Səhv `app.mistake_note(…, false)` ilə
  dəftərə düşür. Qaytarır `correct, gain, score, level, streak, mastered,
  just_mastered, explanation` (yalnız səhvdə).
- Hesabat: `rpc_student_report.practice{mastered,active,answered,items[6]}`,
  `rpc_parent_home.practice{mastered,active}`.
- UI: şagird ev ekranı `#adBox` (`loadPractice`: üstdə davam edən +
  tövsiyə ≤4, `details` «Bütün mövzular»), `screenPractice/drawPrac`
  (`.adhead/.adprog`, `#popts/#pans/#btnPAns`, `#pFb`, `#btnPNext/#btnPHome`);
  müəllim Xülasə «Mövzu məşqi» kartı (`.mkbox`, səhv olmasa da çəkilir),
  valideyn `.plan2` sətri.
- Yoxlama: `smoke_adaptiv.sql` (4), `test/e2e_adaptiv.py`; bələdçi şagird
  addım 7, şəkil `s7_mesq`.

## Parametrik (şablon) suallar (yol xəritəsi 22.a)

`db/132_parametrik_sual.sql`. `questions.params` =
`{"vars":{"a":[100,999],"b":[100,999]},"cond":"a>b"}`; sual/variant/izah
mətnində `{a}`, `{a+b}` yer tutucuları. Ad `a`–`h` tək hərf, ən çox 6
dəyişən, tam ədəd aralığı ≤ 1 000 000, şərt ≤ 120 simvol.

- **Hesablama** `app.pq_eval(expr, vars)`: dəyişənlər əvvəlcə rəqəmlə
  əvəz olunur, tək rəqəmlərə `.0` qoşulur (7/2 = 3.5), sonra
  `^[0-9+\-*/%(). ]+$` yoxlanır və yalnız ondan sonra `execute` —
  inyeksiya mümkün deyil (smoke 1 bunu sınayır). `app.pq_render`
  `{…}`-ləri əvəz edir; `p_vars` null olanda mətnə toxunmur (adi sualda
  `{1, 2}` çoxluğu qalır). `app.pq_cond` şərt üçün eyni yol
  (`and`/`or` icazəlidir).
- **Qiymətlər cəhdə bağlıdır**: `rpc_start_attempt` yeni cəhddə
  `attempts.params = {sual_id: {a,b}}` yazır (`app.pq_seed`: şərt
  ödənənə və variantlar fərqli çıxana qədər 40 cəhd), davam edən cəhd
  eyni rəqəmləri alır. Ballama dəyişmir — variantın `is_correct`-i
  şablon səviyyəsindədir, şagird ID göndərir; yazılı sualda düz cavab
  render olunub müqayisə edilir. `attempt_answers.question_body` və
  izah render olunmuş yazılır; `rpc_test_result`, `rpc_attempt_sheet`
  seçilmiş/düz variantı cəhdin qiymətləri ilə render edir.
- **Təzə rəqəm** hər dəfə: `rpc_student_mistakes` (məşq) və
  `rpc_test_preview` (vərəq, `tpl` nişanı).
- **Yadda saxlama** `rpc_bank_save_question(..., p_params)` — köhnə 13
  parametrli imza SİLİNİB (iki imza PostgREST-də «best candidate»
  xətası verir); `app.pq_spec` + `app.pq_check` (yer tutucu var, hər
  ifadə hesablanır, 12 nümunədə 4-dən çox toqquşma → rədd).
  `rpc_pq_preview` redaktorun «Nümunə göstər» düyməsi.
- **Panel**: redaktorda «Şablon» `<details>` (`#qpar` mətn sahəsi
  `a = 100..999, b = 1..9; şərt: a > b` ↔ `parseParams/paramsToStr`,
  `#qparTry/#qparOut`), siyahıda və vərəqdə «şablon» nişanı
  (`rpc_bank_list.tpl`). Şagird tətbiqi dəyişmir — hər şey serverdə
  render olunur.
- Yoxlama: `smoke_parametrik.sql` (5), `test/e2e_parametrik.py`;
  bələdçi addım 10, şəkil `m13_sablon`.

## db/207 — Sual keyfiyyəti: keşdə qalan nümunə sətirləri (2026-09-17)

Canlıda «Sual keyfiyyəti 3»: 7-ci sinif Rasional ədədlər / Statistika, 20–27
cavab — nümunənin öz mövzuları. 139 `qstat_rows`-dan nümunəni çıxarmışdı, amma
`question_stats` keşi yalnız upsert ilə yenilənirdi: təzə hesablamada olmayan
sual köhnə rəqəmləri ilə qalırdı. `app.qstat_refresh` indi müvəqqəti cədvələ
hesablayır, upsert edir, hesablamada olmayan sətirləri silir.
Canlıda: `db/207_keyfiyyet_kohne_setir.sql`, sonra İdarəetmədə «↻ Yenilə».
Test: `smoke_keyfiyyet.sql` §1b.

## Sual YAZMA qaydası — tək mənbə (2026-09-24)

**Baş verən.** db/306 (9-cu sinif, statistika) müəllim nümunəsi 21 sualdan 8-də
QURULUŞ qüsuru tapdı: «3-ün tezliyi neçədir?» → cavab 3 (qiymətlə tezliyi
qarışdıran da düz cavab verir); düz variantda mötərizəli səbəb («Birinci
sinifdə (6/20 böyükdür)»); absurd distraktor («qiymətləri dəyişdirir»);
yerləşdirmə dərsində C ilə izah (kombinezon sonra keçilir); «niyə
bərabərdir?» sualında «bərabər deyillər» variantı; «rast gəlinir» yönlüksüz.
Düz cavabların hamısı düz idi, rəyçi agent də keçirmişdi — çünki rəyçi
tapşırığı DÜZLÜYÜ yoxlayırdı, QURULUŞU yox. Yanaşmalar dörd yerə səpələnmişdi
(bu fayl, qeydlər, common.py, scratchpad-dakı TASK.md).

**Mexanizm indi:**
- **Qayda faylı:** `bil10-bank/plan/sual_yazma_qaydasi.md` — A quruluş,
  B dərs sırası, C cavab hovuzu/təkrar, D dil, E metadata, F proses. Yeni səhv
  sinfi → bura bənd + yoxlayıcıya kod + rəyçi tapşırığına sual.
- **Avtomatik:** `bil10-bank/tools/riy_ders/qurulus_yoxla.py itemsNUM.json`
  — TEZLIK-CAVAB, IPUCU, DUZ-UZUN, ZIDDIYYET, DERS-SIRASI (`yarpaq_sira.tsv` +
  `GETIRIR`/`getirir_<sinif>.json`), MEXANIZMSIZ, DIL. `q.py`-dən sonra,
  `emit.py`-dən əvvəl; 0 olmalıdır.
- **Rəyçi:** `bil10-bank/tools/riy_ders/REY_TAPSIRIGI.md` — A–G, D bəndi
  quruluşdur (tutmalı olduğu səhvi tuturmu, ipucu, absurd distraktor,
  ziddiyyət, tam şərt), E dərs sırası.
- Bütün alətlər repodadır: `ders_yoxla.sh`, `kor_ders.py`, `muellim_ders.py`,
  `plan_elave.py` (`bil10-bank/tools/riy_ders/`). Scratchpad-da heç nə qalmır.

## Çətinlik səviyyəsi — ölçülür, təxmin edilmir

Real sınaqda «çətin» suallar çətin çıxmadı. Səbəb faktın nadirliyi
deyil, **variantların qurulusu** idi: bir düzgün cavab + üç «təhlükəsiz»
yanlış → şagird faktı bilməsə də eliminasiya ilə tapır.

**Çətin (3) sualın şərtləri:**

- ən azı **iki faktın tutuşdurulması** tələb olunur;
- dörd variantın hamısı **eyni dövrdən və eyni kateqoriyadan**;
- düzgün variant qalanlardan **uzun olmamalı** (uzunluq özü nişandır);
- yanlışlarda «yalnız / heç / tamamilə» kimi mütləq sözlər olmamalı;
- düzgün cavab sualın açar sözünü təkrarlamamalı.

**Beş çətinləşdirmə qəlibi:** xronoloji düzülüş (`2 - 4 - 1 - 3`),
yaxın tarixlər (aralıq ≤ 12 il), səbəb-nəticə (dörd variant da real
hadisə), «hansı SƏHVDİR» (üç doğru, bir yanlış), «şəxs - vəzifə» /
«sənəd - il» cütlük uyğunluğu.

Yeni bank yazanda çətinlik bölgüsü **hər mövzuda 12 çətin sual**
olmalıdır. Az olsa, müəllim bir mövzu + «Çətin» seçəndə generator
«yalnız 8 fərqli sual tapıldı» deyir (`tools/tarix_umumi.py` bunu
`BOLGU` ilə yoxlayır).

`tools/cetinlik_analiz.py` bunu ölçür — banka toxunmur, yalnız
variantların qurulusuna baxır (həm humanitar, həm riyaziyyat sətir
formasını tanıyır):

```bash
python3 tools/cetinlik_analiz.py tarix11        # yalnız difficulty=3
python3 tools/cetinlik_analiz.py tarix9 --hamisi
```

Nişanlar: `ILLER-ARALIQ` (çılpaq il variantları, aralıq > 12 il),
`ERA-QARISIQ`, `UZUN-CAVAB` (düzgün ≥ 1.6 dəfə uzun), `MUTLEQ-SOZ`,
`EKO-CAVAB`. **Yeni bank hazır olanda bu yoxlama 0 verməlidir** —
pg_trgm və cavab balansı ilə bir sırada.

Xronoloji sualda cavab sətri (`2 - 3 - 1`) da cavab sayılır — eyni
sıralama bir bankda ikidən çox təkrarlanmamalıdır.

---

## Çoxmülahizəli birləşmə sualı — təsdiqlənmiş format (növbəti mərhələ)

Real DİM səviyyəsinə yaxınlaşdırmaq üçün sınanıb təsdiqlənmiş əlavə
qəlib: **4 nömrələnmiş mülahizə + kombinasiya variantları**
(`A) 1,3  B) yalnız 1  C) 2,4  D) 1,2,3  E) 3,4`). Sxemə toxunmur —
mövcud `single` növünün içindədir, sual mətni sadəcə çoxsətirli yazılır.

> **Çoxsətirli sual mətni — hər ekranda `white-space:pre-wrap` lazımdır.**
> Sual mətni `\n` və abzasla gəlirsə (proqram kodu, mülahizə siyahısı),
> `white-space` verilməyən yerdə sətirlər **birləşir** — kod yenidən
> səhv sintaksis kimi görünür, mülahizələr bir abzasa yığılır.
> Ortaq qayda `muellim/app.css`-dədir (`.paper .qh b, #printBox .ppb,
> .shq > b, .repc .rhead b, .smp .sq b, .qrow .g b, .wq .g > b, .fbb`);
> şagird `.q .body`, valideyn `.hwr b`.
> **Sual mətnini göstərən yeni ekran yazanda selektoru həmin qaydaya əlavə et.**
> Kəsim də yadda saxla: `-webkit-line-clamp:2` olan siyahıda 6 sətirlik
> kod iki sətirə yığılır — pre-wrap tək başına bəs etmir.
> Yoxlayıcı: `test/e2e_kod_setirleri.py` — CSS-i yox, `innerText`-i ölçür,
> yəni ekranda **görünəni**.

Pilot: `utarix-9-birlesme` mövzusunda real şagird üzərində sınandı.
Nəticə: format işlədi («vaxt aparan, düşündürücü, çətin orta»),
amma **əl ilə yazılan yeni fakt riskli oldu** — bir sınaq sualında
Qaribaldi/Kavur haqqında əlavə diplomatik detal yazılmışdı, şagird
«dərslikdə yoxdur» dedi. Səbəb detalın yalançı olması deyildi —
mündəricatın göstərdiyi dərinlikdən kənara çıxmışdı.

**Qayda: retrofit yalnız mövzunun ÖZ bankında artıq mövcud olan
faktlardan qurulur.** Yəni 4 mülahizə yeni tarixi bilik yazmaqla yox,
həmin mövzunun mövcud (asan/orta/çətin) suallarının cütlük, ardıcıllıq
və müqayisə faktlarını bir sualda birləşdirməklə alınır. Bu, iki şeyi
eyni anda verir: mündəricat sərhədini aşmır (bütün faktlar onsuz da
təsdiqlənib) və analitik çətinliyi artırır (şagird 4 ayrı faktı
yadda saxlayıb müqayisə etməlidir, təkini yox).

**Sıra:** əvvəlcə mövzu ağacları (alt-mövzular) bitsin — bu, ayrı
məsələdir. Sonra bu format bütün fənlərə (təkcə tarixə yox) mövcud
"çətin" sualların üzərində tətbiq olunacaq. Venn diaqramı formatı
(şəkilli/analitik) ayrı, sonrakı qərardır — `media_url` heç bir
ekranda render olunmur, ona görə real frontend işi tələb edir; hələ
başlanmayıb.

---
