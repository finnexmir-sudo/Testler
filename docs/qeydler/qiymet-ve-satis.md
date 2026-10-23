# Qeydlər: Qiymət modeli, satış qərarları, sınaq abunə, hədiyyə, tövsiyə kodu, valideyn ödənişi (08.10 qərar)

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## Mövzu məşqində gündəlik limit (abunəsiz)

`db/137_mesq_limit.sql` (istifadəçi qərarı, 2026-09-07). Mövzu məşqi hazır
bankın özüdür — abunəsiz hesabda şagird başına gündə
`app.practice_daily_limit()` = 20 cavab; müəllimin abunəsi ilə limitsiz;
səhv dəftəri limitsiz. `practice_days(student_id, day, n)` hər cavabda +1
(`rpc_student_practice_answer`). `app.practice_quota(student) →
(paid, used, max)`; `rpc_student_practice_topics.quota`, cavabda `quota`.
`rpc_student_practice_next` limit dolubsa rədd edir (`42501`, mətndə
«limit»), verilmiş cavabsız sual (1 saat) yenə qayıdır. Şagird tətbiqi:
ev kartında `.adq` «Bu gün 12 / 20 sual», cavabdan sonra limit dolanda
«Növbəti» yox, «Mövzulara qayıt»; `screenPractice` xətası «limit»
sözünü tanıyıb sakit kart göstərir. Yoxlama: `smoke_mesq_limit.sql` (2),
`e2e_adaptiv.py` sayğac yoxlaması.

## Qoşulana hədiyyə paket + ana səhifə kartı (db/160)

İstifadəçi ideyası: «yeni qeydiyyatdan keçənə admin mesaj versin».
Sistem özü edir: `app_state.hediyye = {on, days, beta_until}` (canlıda
on=true, 30 gün, beta 2026-12-31); `rpc_create_account` (repetitor/
məktəb) → `app.hediyye_grant`: Repetitor-25, `status='trialing'`,
`provider='gift'`, bitmə = max(beta_until günün sonu, indi+days) —
beta boyunca «hər şey pulsuzdur» vədi ilə ziddiyyət olmasın. Gəlirə
düşmür. `rpc_my_context.plan` → `status/ends/provider`; panel ana
səhifədə h1-in altında `#giftCard` («Tam paket sizə hədiyyədir 🎁 … Bitmə:
7 okt (30 gün)»), ≤7 gün qalanda `.soon` narıncı + WhatsApp
(`CONTACT_WHATSAPP` artıq config-də: reklamdakı nömrə). Boş hesabda ilk
qrup forması kartın ALTINA keçir. Admin: «Hesablar» kartında `#hedBox`
(açıq/bağlı, gün, beta tarixi) → `rpc_admin_hediyye(p_on, p_days,
p_beta_until, p_clear_beta)`. **Yerli test bazasında ayar bağlıdır**
(`run.sh --local` söndürür) — 27 e2e-nin «0 / 5» yoxlamaları pozulmasın;
`smoke_hediyye.sql` (5) və `e2e_panel` A1 ayarı özü açır. Beta bitəndə:
admin panelində beta tarixini sil (və ya keçmişə çək), ana səhifədəki
beta qeydini və nişanı çıxar. Bələdçi: Qeydiyyat addımı + FAQ.

## Sınaq abunə, admin daimi, nümunə saylarda yox (db/138)

Şikayət (2026-09-07): İdarəetmədə «aylıq gəlir 233 ₼» — halbuki hamısı
pulsuz sınaq idi; admin hesabına da abunə «verilirdi»; nümunə nüsxələri
4 dənə görünürdü. `db/138_sinaq_abune.sql`:
- **Sınaq abunə.** `rpc_admin_grant(p_email, p_plan, p_months, p_trial)`
  — köhnə üç-parametrli imza silinib. `p_trial=true` → `status='trialing'`,
  `provider='trial'`: müəllim paketin bütün imkanlarını alır (bütün
  qapılar `trialing`-i aktiv sayır), amma «pullu» sayına və gəlirə düşmür.
  Sınaq bitmədən ödənişli grant gələndə ödənişli müddət **bu gündən**
  başlayır (sınaq qalığı üstünə gəlmir). Ödənişli hesaba «Sınaq» vermək
  ödənişli saxlayır, müddəti uzadır (hədiyyə ay). Panel: sətirdə «Sınaq
  1 ay» düyməsi, göy `.pb.s` nişanı «sınaq · Repetitor…»; lövhə «N pullu ·
  M sınaq · K pulsuz»; gəlir lövhəsi «yalnız ödənişli»; süzgəc «Sınaq».
  Paket səhifəsi «· pulsuz sınaq» yazır.
- **Admin daimi.** `app.account_is_admin(hesab)` (sahibi admin rolludur)
  → `app.has_active_subscription` true, `app.account_seat_limit` sonsuz
  (02_rls-dəkilərin üstündən). Statistikada pullu/sınaq/gəlirdə yoxdur;
  siyahıda «admin · daimi» nişanı, düymə yoxdur; Paket səhifəsi və ana
  səhifə pill-i «Admin — daimi». Admin abunə almalı deyil.
- **Nümunə saylarda yox.** `rpc_admin_stats` bütün saylarda `is_demo`
  hesabları çıxarır (`demo_accounts` ayrıca gəlir → izah sətri);
  `rpc_admin_accounts` onları yalnız `p_f='numune'` süzgəcində verir
  (sətirdə `demo` bayrağı, «nümunə · özü silinir», düymə yoxdur). Hər
  «Müəllim kimi bax» kliki bir nüsxədir, 24 saat sonra `rpc_demo_reset`
  silir — əl ilə silmək lazım deyil.
- Canlıda köhnə «pulsuz verilmiş» aktiv abunələri sınağa çevirmək üçün
  (yalnız hamısı sınaqdırsa!): `update public.subscriptions set
  status='trialing', provider='trial' where status='active';`
- Yoxlama: `smoke_paket.sql` 11–14, `test/e2e_paket.py` D0 addımı.

## Qiymət modeli — şagird başına (db/165+169) — HƏLƏ GİZLİDİR

### QAYDA (tam, 2026-09-09) — bir yerdə

1. **Şagird və valideyn həmişə pulsuzdur.** Onlardan heç vaxt ödəniş
   istənmir. Valideyn paketləri bağlanıb.
2. **Müəllim üçün pilləli paket yoxdur** — yalnız **aktiv şagird başına
   ayda 1,50 ₼**. Baza haqqı yoxdur, şagird sayına məhdudiyyət yoxdur.
   «Aktiv şagird» = `students.is_active` — dayandırılmış şagird pul
   tutmur.
3. **Məbləğ ödəniş günündəki sayla hesablanır.** Ay ərzində əlavə
   olunan şagird üçün ayrıca pul alınmır — növbəti ayın hesabında
   görünür. Proporsional bölgü yoxdur (istifadəçi qərarı: «ayın
   ortasında uşaq əlavə edəndə 1-2 manat xərcə düşür, böyük məbləğ
   deyil»).
4. **Yeni müəllimə ilk ay hədiyyədir — eyni məhsul, 0 ₼.**
   Hədiyyə ayında **şagird limiti yoxdur** (db/169). Əvvəl hədiyyə
   `repetitor-25` idi: pulsuz ay ödənişli məhsuldan **daha məhdud**
   olurdu — tərsinə idi, düzəldildi.
5. **Hədiyyənin uzunluğu həmişə `days` (30 gün)**, təklifin son
   tarixinə uzanmır (db/168). `beta_until` = **təklifin** son günü;
   keçibsə yeni müəllimə hədiyyə verilmir.
6. **Bir hesab hədiyyəni bir dəfə alır** (aktiv abunəsi varsa
   verilmir). Admin istənilən vaxt əl ilə ay hədiyyə edə bilər.
7. **Vaxt bitəndə 3 gün güzəşt** — hesab tam işləyir, ekranda
   xatırlatma zolağı görünür.
8. **Güzəştdən sonra pulsuz həddə (5 yer) düşür**: mövcud şagirdlər
   işləməkdə davam edir, yenisi əlavə olunmur, **heç bir məlumat
   silinmir**.
9. **Məbləği həmişə server hesablayır** (`rpc_paket`, `rpc_my_context`).
   Brauzer vurma əməliyyatı aparmır — «pul işi: 100 ölç, bir biç».
10. **Bütün tarixlər Bakı günü ilə** (db/166).

Gəlir göstəricisi (`rpc_admin_stats.mrr_minor` → `app.mrr_minor()`)
də **anbaan aktiv şagird sayından** hesablanır — `subscriptions.seats`
sütunu şagird başına modeldə doldurulmur (db/169).

### Ödəniş nə vaxtdan başlayır (db/172)

Məbləğ müəllimə **indidən** göstərilir ki, sonra sürpriz olmasın —
amma **şərti dildə**: «Beta bitəndən sonra aylıq **6 ₼**», altında
«İndi ödəniş yoxdur — məbləğ məlumat üçündür». Hədiyyə kartında
konkret hesab da var: «Sizdə indi 4 aktiv şagird var — bu, 6 ₼ / ay
edərdi».

Tarix `app_state.qiymet.odenis_start`-dədir və **hazırda boşdur** —
tarixsiz vəd verilir, çünki **tarix vermək vəddir**. Hazır olanda:

```sql
update public.app_state
   set val = val || jsonb_build_object('odenis_start','2027-01-01')
 where key = 'qiymet';
```

Onda ekran «Ödəniş 1 yan-dən başlayır» yazır. Geri qaytarmaq:
`jsonb_build_object('odenis_start', null)`.

Bu ayar **heç bir hesabın davranışını dəyişmir** — nə abunə, nə hədd,
nə məbləğ. Yalnız ekrandakı cümlədir. Kodda `betaAdi()` (məbləğ
sətrinin başlığı) və `betaQeyd()` (uzun cümlə) funksiyalarıdır.

### DİQQƏT — 2026-12-31 (təklifin son günü)

`app_state.hediyye.beta_until` = **2026-12-31**. Bu tarixdən sonra
`hediyye_grant` **heç nə vermir** (db/168 qaydası) — yeni müəllim
birbaşa pulsuz 5 yerə düşür. Amma `index.html`-də hələ də yazılıb:
«Bu dövrdə bütün imkanlar müəllimlər üçün pulsuzdur».

**O tarixə qədər ikisindən biri edilməlidir:**
1. `beta_until` uzadılsın (İdarəetmə → Hədiyyə paket → tarix), **və ya**
2. `index.html`-dəki «beta-note» vədi dəyişdirilsin.

Bu, **səssiz sınan** növ problemdir: heç bir xəta verilmir, sadəcə
yeni müəllim vəd ediləni almır və bunu heç kim görmür. Yoxlamaq
üçün: İdarəetmədə yeni hesabın «PAKET» sütunu «paketsiz» yazırsa,
təklif bitib.

### Limitsiz test bizə ziyan verirmi? (2026-09-09 hesablaması)

Sual: şagird başına 1,50 ₼ ödəyib **istənilən qədər** test etmək bizi
zərərə salarmı? **Xeyr.** Səbəb: runtime-da **hər testin ayrıca xərci
yoxdur** — nə AI, nə üçüncü tərəf API. Xərc yalnız baza yeri və
trafikdir.

Ölçülüb (`attempt_answers`, indekslərlə, sual mətninin surəti daxil):
**cavablanan bir sual = 436 bayt.**

| Ən aktiv şagird (ayda 30 test × 20 sual) | |
|---|---|
| Baza artımı | 600 × 436 B = **262 KB / ay** |
| Trafik | ~540 KB / ay |
| Gəlir | **1,50 ₼ / ay** |

1 000 belə şagird: 262 MB/ay baza, 540 MB/ay trafik. Supabase Pro
($25/ay) 8 GB baza + 250 GB trafik verir — trafikin **0,2%-i**.
Gəlir 1 500 ₼. Bir şagirdin xərci 1,50 ₼-ə çatması üçün ayda **7 GB**
yaratmalıdır (ayda 16 mln sual) — mümkün deyil.

**Limit qoymaq ziyan verər:** ən çox test edən müəllim ən yaxşı
müştəridir. Lazım olsa düzgün alət «ədalətli istifadə tavanı»dır —
real heç kimin çatmadığı rəqəm (məs. ayda 300 test), sırf
sui-istifadəyə qarşı. **İndi ehtiyac yoxdur.**

**Əsl risklər başqa yerdədir** (buna sonra qayıdılacaq):

1. **Şagird paylaşımı** — pul itkisi məhz buradadır: 1,50 ₼/şagird
   müəllimi 4 uşağı bir kod altında yığmağa təşviq edir. Tutmaq olar:
   bir kod, çox cihaz, üst-üstə düşən sessiyalar. Hazırda cihaz limiti
   yoxdur, sessiya 30 gündür (db/164).
2. **Pulsuz 5 yer × çox hesab** — bir nəfər neçə müəllim hesabı açır.
   E-poçt/IP ilə görünür.
3. **`attempt_answers` sonsuza qədər böyüyür** — heç vaxt təmizlənmir.
   Hesabatlar onsuz da son 12 ayı işlədir, köhnə cəhdlər
   arxivləşdirilə bilər. Təcili deyil, planda olsun.
4. **Generator hesablama yükü** — `rpc_generate_test` ən ağır
   sorğudur; təkrar test yığmaq bazanı test həll etməkdən çox yorur.
   Problem olsa, ilk limit burada qoyulmalıdır.
5. **Runtime-da AI əlavə etsək bu cavab DƏYİŞİR.** Hər sorğuda LLM
   çağırılsa xərc sıfır olmayacaq və limitsizlik təhlükəli olacaq.
   «AI yalnız oflayn/admin tərəfdə» qaydası təkcə təhlükəsizlik yox,
   **pul qaydasıdır**.

**Qərar (istifadəçi ilə müzakirə):**

- **Şagird və valideyn həmişə pulsuzdur.** Bazadakı `valideyn-aylik`
  (9.90 ₼) və `valideyn-illik` (99 ₼) paketləri **bağlandı** —
  ana səhifədəki «həmişə pulsuz» vədi ilə ziddiyyət təşkil edirdi.
- **Müəllim: paket yox, şagird başına — aktiv şagird başına ayda 1.50 ₼.**
  Səbəb: repetitorların çoxunda **6–10 şagird** olur (istifadəçinin
  bazar məlumatı). Pilləli paketlərdə 25→26 keçidi qiyməti iki qat
  artırırdı və müəllimi şagird əlavə etməməyə sövq edirdi.
- **Güzəşt müddəti 3 gün.** Vaxt bitəndə hesab dərhal dayanmır:
  3 gün tam işləyir, ekranda xatırlatma görünür. Sonra pulsuz həddə
  (5 yer) düşür — **mövcud şagirdlər işləməkdə davam edir**, yalnız
  yenisi əlavə olunmur.
- Ödəniş: gələcəkdə **bankın öz səhifəsi** (yönləndirmə + Supabase
  Edge Function webhook). CSP kənar skripti bloklayır — kart forması
  sayta yerləşdirilə bilməz. Hazırda abunə admin panelindən əl ilə
  verilir; 20+ ödəyən müştəriyə qədər bu kifayətdir.
- Fərdi güzəşti admin əl ilə verir (rpc_admin_grant).

**HAZIRDA HEÇ NƏ DƏYİŞMİR.** Plan (`sagird-basi`) yaradılıb, amma
heç bir hesaba verilməyib; qiymət səhifəsi gizlidir
(`config.js` → `SHOW_PLANS: false`); saytda qiymət yazılmayıb —
istifadəçi əvvəl müəllimlərlə danışır. Tək real dəyişiklik güzəşt
müddətidir, o da hamıya xeyrinədir (+3 gün).

**Ayarlar miqrasiyasız dəyişir:** `app_state.qiymet` =
`{"per_seat_minor": 150, "grace_days": 3}`.

**Kod:**
- `app.qiymet_cfg()`, `app.grace_days()` — ayarlar
- `app.has_active_subscription()`, `app.account_seat_limit()` —
  bitmə tarixinə güzəşt əlavə olunur
- `rpc_my_context().accounts[].plan` — `per_seat_minor`, `due_minor`
  (aktiv şagird × tarif), `days_left` (**mənfi = güzəştdə**),
  `grace_days`. Güzəşt bitənə qədər plan qaytarılır ki, xatırlatma
  göstərmək üçün məlumat qalsın.
- `app.hediyye_grant()` — `sagird-basi` (məktəb hesabına `mekteb`)
- `rpc_paket()` — abunə səhifəsinin bütün rəqəmləri: `students`,
  `free_limit`, `grace_days`, `base_minor`, `per_seat_minor`,
  `due_minor`, `current.days_left`, `current.gift`
- `muellim/app.js` → `drawPaket()` (Abunə səhifəsi: vəziyyət + hesab
  qutusu `.abn` + qayda `.rul` + ödəniş), `seatCard()` (şagird başına
  planda «Bu ay N ₼», hədiyyə ayında «Növbəti ay N ₼»),
  `payBar()` (#payBar — 7 gün qalanda sakit, vaxt keçəndə qırmızı).
  Sınaq abunəsinin xatırlatması `giftCard()`-dədir; güzəştdə susur ki,
  iki kart olmasın.

**`days_left` tam GÜN fərqidir** (`::date - current_date`), saniyə ilə
yox — yoxsa «5 gün sonra bitir» saniyə qırıntısına görə «4» yazırdı.

**Test yazanda diqqət:** bitmiş abunə fikstürü artıq `now() - 1 day`
deyil — güzəştə düşür. Güzəşti keçmək üçün `now() - 10 days` yazın
(`smoke_reports.sql`-də belə düzəldildi). `status='canceled'` qoyulan
fiksturlara güzəşt təsir etmir. Həmçinin `app.has_active_subscription()`
**admin üçün həmişə true**-dur — e2e-də admin hesabla güzəşt yoxlamayın
(`smoke_qiymet.sql` düzgün hesabla yoxlayır).

## «Sınaq» sözü — müəllim mətnlərində İŞLƏDİLMİR (2026-09-10)

İstifadəçi zolaqda «**Sınaq bitir** · 3 okt» görüb soruşdu: düzdürmü?
Yox. İki səbəb:

**1. Eyni ekranda bir şeyin iki adı.** Zolağın altındakı kart hər
`trialing` müəllimə «Tam paket sizə **hədiyyədir** 🎁» deyir. Kart
`status`-a baxırdı, zolaq isə **`provider`**-ə — admin əl ilə sınaq
verəndə (`provider='trial'`) sözlər ayrılırdı. Bu, **yarımçıq
düzəldilmiş köhnə səhvdir**: `e2e_paket`-in şərhi eyni sinfi artıq
yazır («Əvvəl ekran yalnız provider='gift'-ə baxırdı») — o vaxt
**məbləğ** sətri `status`-a keçirilmişdi, **etiket** isə `provider`-də
qalmışdı.

**2. Bil10-da «sınaq» İMTAHAN deməkdir.** «**Sınaq** yığ və tapşır»,
«rüb **sınağına** düşüb», «son **sınaqdan** sonra 2 mövzu keçilib».
«Sınaq bitir 3 okt» — imtahanın bitməsi kimi oxunur. Bu, beta üçün
qoyulmuş qaydanın (CLAUDE.md: beta yerinə «sınaq» yazma) eynisidir.

**Qayda: `status === 'trialing'` → hər yerdə «hədiyyə».** `provider`
(gift / trial) müəllimə görünən mətndə **fərq yaratmır** — onun üçün
ikisi də pulsuz aydır. Dəyişən yerlər: zolaqdakı «Hədiyyə bitir»,
Abunə səhifəsindəki «Hədiyyə ayı» və oradakı nişan.

Yol boyu: «Hədiyyə **ay**» → «Hədiyyə **ayı**» (yiyəlik şəkilçisi
çatmırdı).

**Admin ekranlarına toxunulmur** — «0 pullu · 1 sınaq · 2 pulsuz»
lövhəsi və cədvəldəki «sınaq» nişanı texniki mənadadır və yalnız admin
görür.

Yoxlama: `e2e_paket` — əl ilə verilmiş sınaqda da «Hədiyyə ayı» yazır
və **`.abn` qutusunda «sınaq» sözü olmadığı** ayrıca ölçülür.

## Qiymət mətni: «hər şagird üçün», qayda sətri, siyahı auditi (db/176, 2026-09-09)

İstifadəçi iki şey tutdu, ikisi də haqlı idi.

**1. «Limitsiz şagird» abunə siyahısında çaşdırıcı idi.** Siyahıdakı qalan
bəndlərin hamısı «abunə alanda **açılan** imkandır»; şagird sayı isə
**ödədiyin vahiddir**. Eyni siyahıda, rəqəmsiz duranda göz onu da
«daxildir» kimi oxuyur. «Yuxarıda yazılıb» arqumenti işləmir: zolaqdakı
qiymət telefonda həmin siyahı ilə **eyni ekranda deyil**. Hesab gələndə
«limitsiz yazılmışdı» deyilir — pul işində ən bahalı növ səhv budur.

→ Bənd siyahıdan çıxdı, başlığın altına **qayda sətri** kimi məbləğlə
birlikdə qoyuldu (`ferqBasliq()`, `.fseat`). **Məbləğ serverdən gəlir**
(`rpc_my_context.qiymet.per_seat_minor`) — koda rəqəm yazılmır, yoxsa
qiymət dəyişəndə ekran köhnə rəqəmi göstərər. Məbləğ bilinmirsə yalnız
qayda yazılır, **uydurma rəqəm yox**.

**2. «şagird başına» kobud səslənir.** Qrammatik olaraq düzdür
(«adambaşına» kimi), amma **uşaqlar** haqqında məhsulda «baş» sözü
baş-say çalarını gətirir. «hər şagird üçün» eyni uzunluqda, eyni
dəqiqlikdə, çaları təmizdir. Paketin **görünən adı** da dəyişdi;
**slug `sagird-basi` qalır** — onu heç kim görmür, dəyişmək nahaq risqdir
(abunələr, testlər, admin siyahısı ona bağlıdır).

**Qiymət DƏYİŞMİR:** 1,50 ₼ hər şagird üçün, ayda. Yalnız mətn.

### Siyahı auditi — 60-dan çox abunə qapısı yoxlandı

`app.has_active_subscription` çağırılan **hər** yer oxundu. Nəticə:

**Siyahıda YOX idi, əlavə olundu:** hazır sualların **variantları və düz
cavabı** bank siyahısında (`db/106` + `db/132`, `v_keys`). Abunəsiz hesab
sualın **mətnini** görür, variantları və düz cavabı yox.

**PULSUZDUR — siyahıya YAZMA** (yoxlandı, iddia deyil):
«Ən yaxşı şagirdlər» və «Son nəticələr» (`db/163` şərhi açıq deyir:
abunəsiz hesabda da görünür) · irəliləyiş kartı və paylaşma şəkli
(brauzerdə çəkilir, qapı yoxdur) · davamiyyət və ödəniş dəftəri ·
valideyn girişi · səhv dəftəri · cavab tərzi (yalnız tarixçə pəncərəsi
məhduddur).

**Onsuz da örtülü idi:** kilidli platforma testləri (`db/03/10/11/114/115/123`)
→ «Hazır suallar» · hesabat tarixçəsi pəncərəsi (`db/08/128/129/133`)
→ «Bütün hesabat tarixçəsi» · generator hovuzu (`db/13/103`) → «Avtomatik
test yığımı» · dərs planı, kurikulum, «bugünkü dərs» (`db/101/126/135`)
→ bir bənddə birləşib.

Bəndlər adlarını yox, **nə etdiklərini** deyir (təhlükə siqnalları: «kim
geriləyir, kim ilişib»). Şişirtmə yoxdur — hər bənd koddakı qapıya
uyğundur.

### Yol boyu tapılan köhnə səhv: `msg("info", …)` üslubsuz idi

`assets/base.css`-də `.warn`, `.err`, `.ok` var idi, **`.info` yox idi**.
`msg("info", …)` iki yerdə çağırılır — ikon öz təbii ölçüsündə, **kartın
eni qədər** açılırdı (Abunə səhifəsində nəhəng «i»). Yeni bildiriş növü
əlavə edəndə **hər üç sətirdə** yazılmalıdır: gövdə, `svg`, rəng.
`e2e_paket` indi ikonun ≤24px olduğunu ölçür.

**Yoxlama:** `smoke_qiymet` 11 (paketin adı + `rpc_my_context.qiymet`;
176-sız düşür) · `e2e_paket` (qayda sətri ayrıca, məbləği özü ilə daşıyır,
«Limitsiz şagird» artıq bənd deyil, yeni bənd görünür, info ikonu 16px).

## Valideyn ekranı — pulsuz / abunə bölgüsü (db/174, 2026-09-09)

İstifadəçi ideyası: müəllimi valideynə **hesabat vermək əziyyətindən**
qurtaran hissə abunənin içində olsun. Valideyn 1–2 ay rahatlığa öyrəşir;
abunə bitəndə həmin hissə bağlanır və **davam etməyi valideyn istəyir**.
Valideyn heç vaxt ödəmir — pulu müəllim verir, rahatlığı da o alır.

Düzəliş (mən əlavə etdim, istifadəçi qəbul etdi): **kəsmirik, azaldırıq.**
Qapıda qalan valideyn müəllimi günahlandırır, hekayə pis yayılır.

| Həmişə pulsuz | Abunə ilə |
|---|---|
| «Son nəticələr» siyahısı (test-test faiz, tarix) | ortalama faiz (`avg30`) |
| «son 30 gündə N test yazıb» sayı | keçən ayla müqayisə (`prev30`, `delta`) |
| gözləyən tapşırıqlar, fərdi plan, mövzu məşqi | ən yaxşı nəticə (`best`) |
| davamiyyət və ödəniş dəftəri | zəif mövzular (onsuz da belə idi) |

Bölgü `rpc_parent_home` içində, `v_paid = app.has_active_subscription()`
ilə: bağlı sahələr **`null` qaytarır, açar itmir** — frontend `undefined`
ilə `null` arasında fərq qoymur, açar itsə səhv budaq seçilər
(`smoke_valideyn` 13 açarın **özünü** yoxlayır).

Mətn valideyn ekranında **neytraldır** — «müəllim ödəməyib» kimi oxunan
heç nə yazılmır. Bil10 müəllimi öz müştərisinin qarşısında utandıran şey
olmamalıdır.

**Beta dövründə heç kimə heç nə olmur:** hədiyyə/sınaq abunəsi olan
hesabda `v_paid = true`.

**Ölçü birinci.** Eyni miqrasiya `rpc_admin_accounts`-da şagird və
valideyn girişini **ayırdı**: `student_login`, `parent_login`, `parents`
(neçə şagirdin valideyni ən azı bir dəfə girib). Cədvəldə «Son giriş»
sütununda üçüncü sətir kimi görünür (heç bir valideyn girməyibsə sətir
yazılmır). Səbəb: valideyn ekranı az işlənirsə, bu lever zəifdir — qərarı
məlumatla veririk.

## Pulsuzda şagird məşqi: gündə 5 sual (db/196, 2026-09-15)

İstifadəçi: «pulsuzda şagird məşqi gündə 20 sual çoxdur, 5 edək». Mən 20
(ən azı 10) qalmasını məsləhət gördüm — məşq şagirdin dəyəridir, pulu
müəllim verir, 5 sual nə vərdiş yaradır, nə nəticə göstərir; istifadəçi
5 dedi, 5 oldu. Hədd bir yerdədir: `app.practice_daily_limit()` (db/137
→ 196), `practice_quota / next / answer` oradan oxuyur; şagird kartı
«Bu gün 3 / 5» serverdən gələn `quota.max` ilə yazır. Mətnlər:
`assets/ferq.js` («Şagird məşqi: gündə 5 sual»), `komek`. Yoxlama:
`smoke_mesq_limit` (5/6), `e2e_adaptiv` («/ 5»), `e2e_paket`. Canlıda:
`db/196` (grants dəyişmir).

## Satış və model qərarları (2026-09-20)

Mənbə: öz söhbətimiz + Claude/Gemini/GPT rəyləri (iki ayrı dövr: birincisi
«ilk ödəyən müştəri», ikincisi «şagirdə ayrıca abunə»).

### Rəqəmlər (bu qərarların əsası)

- 13 gün: 114 ziyarətçi (gündə ~9), 26-sı nümunəyə basıb — **23%**.
  Ana səhifə normadan yaxşı işləyir; problem trafik həcmidir.
- 30 gün: 16 fərqli adam qeydiyyat. 7-si e-poçt təsdiqi ucbatından heç
  vaxt girə bilməyib (2-si ünvanı səhv yazıb: gemail.com, gamil.com).
  Təsdiq 17 sentyabrda söndürülüb, yazı səhvi tutucusu canlıdır.
- Hesabı olan 9 müəllimdən: 4-ü qrup qurmayıb, 1-i şagird əlavə etməyib,
  1-i (3 qrup + 5 şagird) **16 gündür test göndərə bilməyib**, 2-si bütün
  yolu keçib.
- Müştəri şagirdləri: hamısı **dəqiq 10 cavab, bir dəfə**. Yəni test axını
  uçdan-uca işləyir (9 şagirddə), dayanan şey **ikinci testdir** — onu
  göndərən müəllimdir.
- Öz-özünə mövzu məşqi: 11 şagirddən **4-ü** edib (36%), amma **3-ü bir
  daha qayıtmayıb**. Ayşə 135 cavab — hamısı BİR gündə.
  DİQQƏT: `app.practice_daily_limit()` = **5** (db/196; db/137-də 20 idi)
  və yalnız ABUNƏSİZ hesabda tətbiq olunur; hədiyyə abunəsi varsa
  limitsizdir. «135 bir gündə ola bilməz» mühakiməsi səhvdir.

### Qərarlar

1. **Şagird/valideynə ayrıca abunə — DONDURULDU** (atılmadı).
   Üç müstəqil rəy + mən: eyni nəticə. Səbəblər: 250 xırda ödəyən vs 25
   müəllim (tək adam idarə etməz); kart saxlanmır/avtomatik təkrar yoxdur →
   2 AZN aylıq ikinci ay yenilənməz; üç tərəfli satış (dəyəri şagird hiss
   edir, valideyn ödəyir, müəllim tanıdır); **və əsası — müəllimə satış
   hələ SINANMAYIB** (0 zəng; 600 mesaj Instagram SƏHİFƏLƏRİNƏ gedib,
   müəllimlərin özünə yox).
   Qayıdış şərti: ya 20+ ödəyən müəllim, ya 30-40 zəngdən sonra 0 ödəniş.

2. **«Həmişə pulsuz» vədi mətnlərdən çıxarılır**, pulsuz yol qalır.
   Yeni çərçivə: *müəllim vasitəsilə gəlirsə pulsuz; müstəqil əlavə
   imkanlar istəyirsə ödənişli.* Dəyişiləsi yerlər:
   - `index.html:703` `<span class="tbadge">Həmişə pulsuz</span>`
   - `index.html:752` «Şagird və valideyn üçün həmişə pulsuz.»
   - `index.html:43,50` og/twitter description
   - `muellim/app.js:5740` «Şagird və valideyn — həmişə pulsuz. Onlardan
     heç vaxt ödəniş istənmir.» ← ən bağlayıcı vəd, mütləq dəyişsin
   - `muellim/app.js:4119` kətan mətni «şagird və valideynə pulsuz»
   `db/174_valideyn_abune.sql` başlığındakı «Valideyn HEÇ VAXT ödəmir»
   qeydi də yenilənməlidir.

3. **Pulsuz 5 şagird həddi** (`app.free_seat_limit()`): götürülməsi
   qərarlaşdırıldı, AMMA ödəniş qəbul edə bilməmişdən əvvəl yox.
   Satış mətnlərindən «5 şagirdə qədər ödənişsiz» cümləsi indi çıxır.
   Hədiyyə bitəndə qayda dəyişmir: **KƏSMİRİK, AZALDIRIQ** — məlumat
   görünən qalır, yeni tapşırıq göndərmək bağlanır.

4. **Ödəniş infrastrukturu** — VÖEN/POS indi lazım DEYİL (istifadəçi
   qərarı, razılaşdırıldı). İlk 5 müştəri kart köçürməsi ilə ödəyir,
   paket əl ilə açılır. Müntəzəm gəlir başlayanda rəsmiləşdirmə.

### Növbəti 30 günün ölçüsü

Ziyarətçi sayı DEYİL. **Neçə müəllim öz real qrupuna real test göndərdi.**
Hədəf: 5.

### Siyahı (sıra ilə, hələ EDİLMİR)

1. **«Bu testi qrupa ver» düyməsi** — generatorda test yığılandan sonra
   qrupa göndərmə yolu görünmür (`PICKNEW` mesajı yalnız qrupdan
   girildikdə çıxır). İki müşahidə: a44785271 (16 gün) + İSRA (WhatsApp).
   Həm sizin datanız, həm iki müstəqil rəy eyni yeri göstərir. 1 gün.
2. **Hədiyyə bitəndə görünən ekran** (kəsmə yox, azaltma). Yuxarıdakı
   3-cü qərardan asılıdır.
3. **Xatırlatma / push bildiriş (Duolingo kimi).** ƏVVƏL PULSUZ SINAQ:
   müəllim WhatsApp qrupuna bir xatırlatma yazsın, `practice_days`-ə
   baxaq — 4 uşaqdan 3-ü qayıdırsa push qurmağa dəyər, 0-1 qayıdırsa
   dəyməz. Texniki vəziyyət: `sw.js`-də push işləyicisi YOXDUR, sıfırdan
   qurulur. iPhone-da yalnız «Ana ekrana əlavə et» edilibsə işləyir
   (iOS 16.4+); Android/Chrome-da quraşdırmadan da işləyir. Lazımdır:
   VAPID açarları, `push_subs` cədvəli, Supabase Edge Function + pg_cron
   (təmiz SQL-də Web Push mümkün deyil — JWT imzası + yük şifrələməsi).
   2-3 gün. Uşaq olduğu üçün `consents` işə salınmalı; məxfilik mətni
   push provayderini (Google/Apple) yazmalıdır.
4. **Rüblük sınaq + reytinq (valideynə satış).** DİQQƏT: rüb sınağının
   özü ARTIQ VAR — `db/135_kurikulum_paketi.sql`, «Dərs paketi: isinmə ·
   ev tapşırığı · rüb sınağı», keçilmiş mövzulardan 20 sual, 7 gün,
   `plan_exams` təkrarın qarşısını alır. Çatışmayan: kross-sinif reytinqi,
   sabit tarix, birbaşa satış. Reytinq 200+ eyni vaxtda iştirakçı tələb
   edir (11 nəfərin içində «3-cü» heç nə demir) + nəzarətsiz onlayn
   imtahanın sırası inandırıcı deyil. Ona görə əvvəlcə **müəllimə**
   satılır (sinfin rüblük qiymətləndirməsi), valideyn versiyası sonra.
5. **Şagird qeydiyyatı / valideyn qeydiyyatı + yarışlar-oyunlar.**
   1-ci qərarla dondurulub. Pulsuz sınağı: istifadəçinin öz iki uşağı
   iki həftə HEÇ NƏ DEMƏDƏN buraxılsın; `practice_days`-ə baxılsın.
   Öz uşağı girmirsə, özgə uşağı heç girməyəcək.

### Satış qaydaları (üç rəyin ortaq nəticəsi)

- Səhifələrə yox, **müəllimin özünə** yaz (riyaziyyat repetitoru,
  dil müəllimi, hazırlıq müəllimi). Səhifə reklam alır, müəllim dərs keçir.
- «Platformama bax» yox, **«ilk testinizi birlikdə keçirək»**.
- İlk 10 müəllimə **əl ilə quraşdırma** (ekran paylaşımı, şagird adlarını
  özün yaz, ilk testi özün göndər). Bu, xidmət deyil — ölçmə üsuludur.
  QEYD: istifadəçi əvvəl bunun əksini demişdi («biz hazırlamayaqda, özü
  edər»); üç rəy də bu qərara qarşı çıxdı.
- Elan formatı (maddələr, 👉, emoji) soyuq şəxsi yazışmada işləmir —
  «reklam» kimi oxunur, bir nəfər məhz buna görə əsəbləşdi. Salam +
  cümlə formalı mətn işləyir.
- Rədd edilən təklif (Gemini, iki dəfə): «müəllim valideynlərdən uşaq
  başına 1 AZN yığsın». Müəllimi pul yığana çevirir, valideynlə
  münasibətini korlayır.

### 6. Valideyn məhsulu — ödəniş + uşağın gündəliyi (2026-09-20, istifadəçi fikri)

Bu, 5-ci bənddəki «valideyn qeydiyyatı»nın konkretləşmiş halıdır və
ondan fərqli olaraq **müəllimdən asılı deyil** — valideyn özü doldurur.

İstifadəçinin təsviri:
- Valideyn öz uşağı üçün ödəniş edir
- **Uşağın gündəliyini yaratmaq imkanı**: hansı gün hansı dərslər
- Valideyn «bu gün nə keçdiniz?» deyə bilər, çünki fənləri artıq bilir
- Valideyn uşağına test verə bilir
- Nəticə: valideyn uşağının təhsili ilə maraqlanan tərəfə çevrilir

**Niyə bu, 2 AZN-lik məşq abunəsindən güclüdür:** valideynə tətbiqi hər gün
açmaq üçün səbəb verir. Əvvəlki təklifdə valideyn heç nə etmirdi, sadəcə
ödəyirdi — ona görə ikinci ay yadından çıxardı. Gündəlik isə gündəlik
əməliyyatdır.

**Nə qədəri artıq var:**
- `class_schedule` (db/177) — həftəlik cədvəl, AMMA sinfə bağlıdır
  (`class_id`), müəllim qurur. Valideynin qurduğu MƏKTƏB cədvəli yoxdur.
- `lesson_changes` — dərsin ləğvi/köçürülməsi. Eyni şəkildə sinfə bağlı.
- Valideyn ekranında «**Keçilən dərslər**» bölməsi var — amma müəllimin
  «Keçildi» işarəsindən doldurulur, valideyn yaza bilmir.
- «Valideyn uşağına test versin» — müəllimin tapşırıq axınının tək
  şagirdlik variantıdır; server tərəfi əsasən hazırdır, valideyn
  ekranında UI yoxdur.

**Çatışmayan (əsl iş):**
- Valideynin özünün yaratdığı uşaq (müəllimsiz) — `students.account_id`
  indi müəllimin hesabına bağlıdır. Bu, 1-ci qərardakı məlumat modeli
  məsələsinin elə özüdür.
- Valideyn tərəfdə cədvəl redaktoru (məktəb dərs cədvəli, fənn adları)
- Valideyn tərəfdə test seçib göndərmə ekranı
- Valideyn ödənişi (audience='parent' paketləri `04_seed.sql`-də var:
  valideyn-aylıq 990, valideyn-illik 9900 — rəqəmlər yer tutucudur)

**Vəziyyət:** 1-ci qərarla birlikdə dondurulub. Açılış şərti eynidir:
ya 20+ ödəyən müəllim, ya 30-40 zəngdən sonra 0 ödəniş.
Pulsuz sınağı da eynidir — istifadəçinin öz iki uşağı, iki həftə,
heç nə demədən.

**Pulsuz/ödənişli çərçivəsi:** istifadəçi düşünüb deyəcək (2026-09-20).

### QƏRAR: pulsuz hədd — A variantı (2026-09-21)

Üç AI rəyi (Perplexity, Gemini, GPT) + istifadəçi + mən: **yekdil A**.
Hədd ŞAGİRD SAYINDAN çıxarılır, DƏRİNLİYƏ qoyulur.

Bir cümlə: **«Test göndərmək və yoxlamaq pulsuz; nəyi bilmədiyini
tapmaq abunə ilə.»**

PULSUZ (limitsiz, həmişəlik):
- limitsiz şagird və qrup
- öz sualları, öz testləri
- test göndərmək (qrupa və tək şagirdə), son tarix, cəhd sayı
- avtomatik yoxlama, bal
- şagirdin hansı suala düz/səhv cavab verdiyi
- valideyn girişi — uşağın nəticəsi
- son 7 günün tarixçəsi

ABUNƏ:
hazır bank · avtomatik test yığımı · diaqnostika · zəif mövzu analizi ·
səhv dəftərində məşq · **gündəlik 5 sual** · limitsiz mövzu məşqi ·
dərs planı və kurikulum · fərdi plan · təhlükə siqnalları ·
düzəliş testi · cavab vərəqi · tam tarixçə

«Gündəlik 5 sual» abunəyə keçir (GPT-nin təklifi, qəbul edildi): o,
şagirdin öz səhvlərindən qurulur — yəni «nəyi bilmədiyini tapmaq»
kateqoriyasıdır.  Pulsuzda qalsa, xətt istisna ilə başlayır.

DƏYİŞİLƏSİ YERLƏR: `app.free_seat_limit()` · `assets/ferq.js` (tək
mənbə, üç ekranı idarə edir) · ana səhifə «Nə pulsuz» bölməsi ·
`db/test/smoke_qiymet.sql` · hədiyyə bitmə ekranı (KƏSMİRİK, AZALDIRIQ).

ŞƏRT: ödəniş qəbul edə bilmədən tətbiq edilmir (kart köçürməsi kifayət).

HƏDDLƏR (rəy fərqləri, seçilən qalın):
- Valideyn məhsulu: Perplexity 5 ödəyən+30 gün / Gemini 10 ödəyən /
  **GPT 3 ödəyən** ← seçildi
- Yarış: Perplexity 200 şagird / Gemini 500 /
  **GPT 100 aktiv + 30-40 eyni sınaqda** ← seçildi
- Valideyn qiyməti: aylıq 4.90 TEKLIF EDILDI, **rədd edildi** — kart
  saxlanmır, aylıq mikro-ödəniş yığılmaz.  **Rüblük və ya illik**
  (Gemini: rüblük 10 AZN / tədris ili 25 AZN).

AI-ların TƏKLİF ETDİYİ, AMMA ARTIQ MÖVCUD OLAN (onlar bilmirdi):
«Həmkarına göndər» (var, db/204) · «Səhvini bağla» (var, db/210+211) ·
«Təkrar/düzəliş testi» (var, db/109) · cavab vərəqi PDF (var; QR-kodlu
OMR hissəsi yenidir) · «Şagird şagirdə test» (= db/214, yazılıb,
qoşulmayıb) · «Bu həftə nə dəyişdi» (siyahıda «Öz rekordun», qurulmayıb).

---

## TÖVSİYƏ KODU — «bu müəllimi kim gətirdi» (db/217, 2026-09-21)

db/204 linkdəki `?src=hemkar` nişanını qeydiyyata qədər daşıyırdı, amma
**linki kimin paylaşdığı** heç yerdə qalmırdı. Canlı hal: Atilla Yaverli
«həmkar» nişanı ilə gəldi — kimin linki olduğunu yalnız təxmin etmək
olurdu.

Zəncir:

1. `rpc_ref_link()` müəllimin kodunu qaytarır (`profiles.ref_code`, ilk
   paylaşmada yaranır, `app.gen_login_code(6)`).
2. «Həmkarına göndər» linki: `bil10.az/?src=hemkar&r=<kod>`.
3. `assets/visit.js` kodu **localStorage**-də 30 gün saxlayır
   (`bil10_ref` = `{c, t}`). Mənbə (`src`) isə sessiyada qalır — köhnə
   davranış dəyişmədi.
4. Panel qeydiyyatda `sb.signUp(..., src, ref)` göndərir.
5. `app.handle_new_user()` kodu tanıyıb `profiles.ref_by` yazır.
   Özünü gətirmək və tanınmayan kod — ikisi də boş qalır.
6. İdarəetmədə «Tövsiyələr» bölməsi (`rpc_admin_ref`): kim kimi
   gətirib, neçə nəfər. **Hədiyyə qərarı bu siyahıya görə verilir.**

DİQQƏT: nişanların tutulması `assets/visit.js`-də **süzgəclərdən
əvvəldədir**. Səbəb: WhatsApp-ın daxili brauzerinin ad sətrində
«WhatsApp» sözü var və robot süzgəcinə düşür — müəllim linkə mesajın
içindən basırsa (ən adi hal) nişan itərdi. Ziyarət sayğacı yenə də
süzgəclərin arxasındadır.

Yoxlama: `test/e2e_tovsiye.py` (uçdan-uca: paylaş → gəl → qeydiyyat →
say), `test/_v2_tovsiye.py` (idarəetmə bölməsinin şəkli).

## QƏRAR (08.10.2026): ödəniş VALİDEYNDƏDİR, müəllim ödəmir

**Köhnə qərarları əvəz edir:** «şagird və valideyn həmişə pulsuzdur» və «müəllim şagird başına 1,50 ₼» (bax yuxarıda, 3220/3340-cı sətirlər).

**Niyə:** sahibin bazar müşahidəsi — müəllimlər ödəmək istəmir («niyə mən ödəyim, uşaq test edəcək»). Hələ real istifadəçi yoxdur, ona görə
modeli dəyişmək pulsuzdur. Sahib müəllimlərə artıq deyəcək: «hər uşaq özü ödəyir» — bu, onları cəlb edir.

**Model (plan, hələ kodlanmır):**
- **Müəllim və şagird üçün əsas hissə PULSUZDUR:** qrup, tapşırıq, test, nəticə. Müəllimin qrupu heç vaxt «kim ödədi, kim ödəmədi» ucbatından pozulmur —
  ödəməyən şagird müəllimin testlərini yenə həll edir.
- **Valideyn uşaq başına ödəyir (öz səhifəsində):** «ev qatı» — gündəlik məşq, həftəlik xülasə, bildirişlər, mənimsəmə, zəif mövzular, personaj
  (ailə yolunda artıq qurulub: `aile-usaq` planı, 1 ay kartsız sınaq).
- **Müəllim siyahıda yalnız vəziyyəti görür:** «Valideyn: qoşulub ✓ / qoşulmayıb». Heç kimə xəbərdarlıq getmir. Müəllimə izah: «Siz heç nə ödəmirsiniz,
  valideynlərə bir link göndərirsiniz.»
- **Birdəfəlik müəllim ödənişi RƏD edildi:** gəlir bir dəfə, xərc (dəstək, server, sual) hər ay; müəllim yenə «niyə mən» deyir.

**Qiymət (AÇIQ sual):** sahib 2–3 ₼/uşaq/ay düşünür; ailə yolunda hazırda 9,90 ₼ yazılıb (`aile-usaq`). Ev qatı eynidir — fərqi qiymətləndirmək lazımdır.
Rəqəm yoxlaması: 8 şagirdli qrupda müəllim indi 12 ₼ (1,50 × 8) verərdi; valideyn 3 ₼ ödəsə hamı qoşulanda 24 ₼, yarısı qoşulanda 12 ₼ — yəni müəllim
modelindən pis deyil və daha çox müəllim gəlir. Diqqət: Epoint/bank komissiyasının sabit hissəsi 2–3 ₼-lik ödənişdə nisbətən böyükdür — 3 aylıq paket
(məs. 3 ay = 7 ₼) yumşaldır.

**Sıra:**
1. Ödəniş kodu YAZILMIR (Epoint yoxdur; abunə admin paneldən əl ilə verilir).
2. Pilot müddətində (≈3 ay) hamı pulsuzdur; ilk istifadəçilərə «pilot güzəşti» vədi.
3. 3 aydan sonra real valideynlərlə qiymət: 3 ₼ / 5 ₼ / 9,9 ₼.
4. Müəllimlərlə söhbət: «hər uşaq özü ödəyir» — və əlavə sual: «valideynə təklif edərdinizmi?».

**Kod tərəfi (sonra):** müəllim hesabında şagird başına «valideyn qoşulub» göstəricisi; müəllim yolundakı şagirdin valideyni «ev qatı»na necə əlavə olunur
(ailə yolu hazırda ayrıdır: gizli `self_study` qrup) — ayrıca dizayn lazımdır. Müəllim hesabının `has_active_subscription` qapıları (test yığma, plan,
diaqnostika) pulsuz müəllim üçün yenidən düşünülməlidir.

**Gələcək fikir (sahib, 08.10): ödəməyən valideyn üçün «gözləmə jesti».** Hələ edilmir. Yumşaq olmalıdır: əlavə pulsuz günlər / bir dəfəlik xatırlatma /
«Lale bu həftə 3 gün çalışdı — ev qatını açsanız həftəlik xülasə də gələr» kimi dəvət; müəllimə «ödəməyib» xəbərdarlığı GETMİR, heç kimə utandırıcı
görünüş yoxdur, qrup və uşağın müəllim testləri bloklanmır.

## Valideyn ödənişi: aylıq uşaq qiyməti — TƏKLİF (09.10, təsdiqlənməyib)

**Status:** yalnız təklif. Qərar bank/şlüz tarifi və valideyn sorğusundan sonra. Ödəniş kodu hələ yazılmayıb.

**Fakt (istifadəçi, 09.10):** repetitorun aylıq haqqı **ən azı 50 ₼-dən** başlayır və yuxarı gedir. Deməli valideynin repetitora verdiyi aylıq məbləğin yanında 4 ₼ ≈ **≤ 8 %** (50 ₼-də), daha bahalı repetitorda daha az. Əvvəlki «bir dərsin altıda biri» arqumenti (15–25 ₼) bu faktla əvəz olundu: ölçü **aylıq repetitor haqqının ~5–10 %-i** olmalıdır.

**Qiymət təklifi (birinci uşaq):**

| Paket | Qiymət | Aylıq | Endirim |
|---|---|---|---|
| 1 ay | 4 ₼ | 4,00 | — |
| 3 ay | 10 ₼ | 3,33 | ~17 % |
| 6 ay | 18 ₼ | 3,00 | 25 % |

- İkinci uşaq: −30 % (≈ 2,80 ₼/ay), ailəyə **bir ödəniş** (bank sabit haqqı bir dəfə).
- Uzun paket əsas yoldur: aylıq kiçik ödənişdə bank itkisi sabit haqqa görə ~6–9 %-ə çata bilər (3 ₼ + 0,10–0,20 ₼ sabit), 3–6 aylıqda ~3–4,5 %.
- **Yuxarı hədd boşluğu:** 50+ ₼ aylıq haqla müqayisədə **5 ₼ də** (≈ 10 %) məqbul ola bilər — valideyn sorğusu göstərməlidir; 4 ₼ ehtiyatlı başlanğıcdır.
- **Qurucu qiyməti:** pilotda (≈3 ay pulsuz) olan ailələrə «bu qiymət həmişə qalır» — ilk ailələri bağlayır, sonrakı qiymət artımı narazılıq yaratmır.
- Minimum ödəniş məbləği (məs. 5 ₼-dən aşağı yox), kart yadda saxlama / avtomatik yenilənmə — şlüzdən asılıdır.

**Valideyn sorğusu (10 valideyn, 5 dəqiqə):** (1) ayda neçə ₼ düşünmədən verərdiniz; (2) neçə ₼-dən sonra «baha olar»; (3) neçə ₼-dən aşağı olsa «keyfiyyətsizdir» deyə şübhələnərdiniz.

**Bank/şlüzdən soruşulacaq (istifadəçi özü soruşur):** faiz, **sabit haqq**, minimum məbləğ, hesaba çıxarma haqqı, hüquqi şəxs tələbi.

**Blok qaydası (təklif):** ödənişi valideyn öz səhifəsindən edir; sistem **hansı uşağın ödəmədiyini** bilir və **yalnız həmin uşağın** girişini bağlayır (yumşaq blok: «ödəniş gözlənilir» + valideynə göndərmə linki; 3–5 gün tolerantlıq; nəticələr və mastery silinmir; qrupun qalanı normal işləyir; müəllim yanında «ödəniş gözləyir» nişanı görür). **Məktəb qrupu** (valideyn ödəmir) heç vaxt bloklanmır — qrupun «ödənişli/pulsuz» işarəsi lazım olacaq. Texniki: hazırda abunə **hesaba** bağlıdır (`has_active_subscription(account_id)`), uşaq səviyyəsində abunə ayrı cədvəl tələb edir. Pilotda blok YOXDUR, yalnız status göstərilir.

**Ödəyən dəyişə bilsin (sonrakı seçim):** abunə uşağa bağlı, ödəyən valideyn (əsas) və ya müəllim (sonradan «bütün şagirdlərim üçün ödəyirəm»). Müəllim birdən ödəmə yolu müəllimin avans və valideyn gecikməsi riskini ona keçirir — əsas yol olmasın.
