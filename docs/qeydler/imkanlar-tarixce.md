# Qeydlər: Qalan imkanların tarixçəsi (db/NNN): admin, bizə yaz, nümunə hesab, ev tapşırığı, Bələdçi, ana səhifə, şagird/qrup təyinatı, sayğaclar

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## Test yığanda bir neçə sinif

Generatorda sinif seçimi **tək seçimli** idi: ya bir sinif, ya
«Hamısı». Ortası yox idi — repetitor 8-ci sinfi hazırlayarkən 7-ci
sinfin materialını qatmaq istəyəndə ya ayrıca test yığmalı, ya da
süzgəci tam açıb 1-11-i qarışdırmalı idi.

İndi `#gLevs` çipləridir, qayda `levels` **massivi** alır: `["8","7"]`.

- **Çəki qoyulmur.** Generator sualları mövzular arasında bərabər
  paylayır; müəllim 8 və 7-ni bilərəkdən seçirsə, bərabər paylama
  onun seçiminin dürüst oxunuşudur. «Cari sinif ağır, aşağılar
  yüngül» kimi gizli çəki müəllimin görmədiyi sehrdir. Ekranda
  açıq yazılır: «Seçilmiş N sinif arasında bərabər paylanır».
- **Köhnə qaydalar pozulmur** — mövcud testlərin `gen_rule`-unda
  `level` tək dəyər kimi durur («yenilə» onu təkrar işlədir), ona
  görə süzgəc hər iki formanı tanıyır (`db/103_cox_sinif.sql`).
- **Testin öz sinfi seçilənlərin ən yuxarısıdır**: 8+7 testi 8-ci
  sinif testidir (7 təkrardır), `rpc_available_tests` onu 8-ci sinif
  qrupuna göstərməlidir.
- **Təyinat siyahısı da aşağı sinifləri qəbul edir** (`db/112`).
  `103` işin yalnız YARISI idi: generator aşağı sinif seçməyə icazə
  verirdi, təyinat ekranı isə testləri DƏQİQ bərabərliklə süzürdü —
  müəllim 5-ci sinif testi yığıb 8-ci sinif qrupuna verə bilmirdi,
  ekran «sinfi qrupun sinfindən fərqlidir» deyib kəsirdi.
  İndi şərt `levels.sort <= qrupun sort`-udur. **Yuxarı sinif bağlı
  qalır** — səhv ehtimalı yüksəkdir və qrupun sinfini dəyişmək bir
  klikdir. Sətirdə testin sinfi yazılır ki, müəllim qarışdırmasın.
- **Mövzu nişanları yalnız TƏK sinif seçiləndə çıxır** — iki sinifdə
  siyahı ikiqat olur, mövzu seçimi onsuz da tək sinif işidir.

`103` faylı `13_generator.sql`-dən **proqramla** çıxarılıb: iki
funksiyanın gövdəsi hərfən eynidir, yalnız iki sətir dəyişib. Əl ilə
köçürməkdən qaçmağın səbəbi var — əvvəl `rpc_remedial_test`-i
əlqolla köçürəndə dörd şey təsadüfən dəyişmişdi.

## Şagirdi dayandırmaq

Yer limiti `students.is_active`-ə baxır (`app.account_student_count`),
amma paneldə şagirdi deaktiv etmək yolu **yox idi**: yer bir dəfə
tutulurdu və geri qayıtmırdı — keçən ilin şagirdi bu ilin yerini
yeyirdi. Repetitor-25 paketində ikinci ildən problemə çevriləcəkdi.

İndi hər aktiv şagird sətrində «**Dayandır**», dayandırılmışlar isə
ayrıca **yığılmış** bölmədədir (aktivlərlə qarışanda müəllim «niyə 8
şagird görünür, 6 yer tutulub?» deyə çaşırdı). Geri qayıdış:
«Davam etdir».

**Yeni RPC yoxdur** — mövcud mexanizm onsuz da kifayət edir və
`db/test/smoke_dayandir.sql` bunu sübut edir:

- RLS (`p_students_upd`) yalnız öz şagirdinə icazə verir
- `trg_students_seat_limit` geri qaytarmada limiti **yenidən yoxlayır**
  → dayandır-əlavə et-davam etdir ilə limiti yan keçmək mümkün deyil
- `app.session_student` `is_active` yoxlayır → dayandırılanda **açıq
  sessiya da dərhal kəsilir**, kod işləmir
- Dayandırmaq **silmək deyil**: sətir və keçmiş nəticələr qalır,
  «Hesabat» keçidi orada da var

Dayandırılmış sətirdə kod və «Göndər» **göstərilmir** — kod onsuz da
işləmir, göstərmək aldadıcı olardı.

## Nümunə (demo) hesab — «Müəllim kimi bax»

`db/136_numune_hesab.sql`. Yayılma üçün: müəllim qeydiyyatsız, dolu
hesabı görsün. **Canlıda Supabase → Authentication → Sign In / Providers
→ «Allow anonymous sign-ins» AÇIQ olmalıdır** — müəllim nümunəsi bunsuz
işləmir (panel «Nümunə hesab hazır deyil» deyir və qeydiyyat təklif edir).
- Üç giriş (ana səhifə `#demo` qutusu): `muellim/#/demo` → anonim giriş
  (`sb.signInAnon()`, boş gövdə ilə `/auth/v1/signup`) + `rpc_demo_start()`
  → ziyarətçinin **öz** nüsxəsi (`accounts.is_demo`, kodlar təsadüfi);
  `sagird/?kod=DEMO0001` və `valideyn/?kod=VDEMO001` → **paylaşılan**
  nümunə (sabit sahib `app.demo_owner()` = `d0000000-…-000000000001`,
  `numune@bil10.local`, heç kim onunla daxil olmur; hesab
  `app.demo_account()`). `?kod=` şagird/valideyn tətbiqində avtomatik
  giriş, ünvandan silinir.
- Qurucu `app.demo_build(owner, account, fixed)`: təmizləyir və yenidən
  qurur — 3 qrup (**7-ci sinif** 12 şagird əsas/zəngin, 3-cü sinif 8,
  11-ci sinif DİM 5 — repetitor auditoriyası 5–11-dir), abunə (1 il),
  plan (9 mövzu keçilib, tarixlər 45…3 gün əvvəl), hər keçilmiş mövzuya
  ev tapşırığı + cəhdlər (`app.demo_attempt`: bacarıq 0.42–0.92, zəif
  mövzularda −0.3; şablon suallar `pq_seed` ilə), son 3 mövzuya isinmə,
  6-cı mövzudan sonra rüb sınağı (`plan_exams`), diaqnostika (35 gün
  əvvəl), açıq tapşırıq (4 nəfər etməyib → «Bu günün dərsi»), mövzu
  məşqi (3 şagird), dəftər (şənbələr, bu ay 8 ödənib), «Bizə yaz», sual
  bildirişi. Zəif mövzular: ilk 9 dərsin fəsillərindən OLMAYAN ilk fəsil
  (diaqnostikada, hamıya, bacarıq −0.12) + 6-cı dərsin fəsli yalnız 5
  şagirdə (1, 7, 10, 11, 12; ilk 9 dərs eyni fəsildədir — hamıya versək
  bütün qrup «zəif» çıxırdı). Bacarıqlar 0.52–0.97, zəifdə −0.22 → orta
  ~70%, zonada 5–7 nəfər. 1-ci şagird (DEMO0001/VDEMO001) orta səviyyəli
  — zəif mövzu və səhv dəftəri görünsün. `setseed(0.4242)` → paylaşılan
  nümunə hər gün eyni. Səhv dəftəri trigger ilə özü dolur.
- `rpc_demo_reset()` (anon, 05_grants siyahısı 19): 10 dəqiqədə bir
  (`app_state.demo_reset`), paylaşılanı yenidən qurur, 24 saatdan köhnə
  anonim nüsxələri silir (sıra: qruplar → testlər → şagirdlər → hesab →
  `auth.users`; `owner_id`/`teacher_id` RESTRICT-dir). İş axını
  `oyaq-saxla.yml` hər gecə çağırır (404 = 136 hələ tətbiq olunmayıb,
  iş dayanmır). `rpc_demo_start()` (authenticated): öz hesabı olan
  istifadəçi ala bilmir; nümunə hesabı olan yenidən qurur.
- `rpc_my_context.accounts[].is_demo, demo_codes{student,parent}` →
  panel `#demoBar` zolağı («24 saat sonra silinir», kodlar, «Öz hesabımı
  aç» → çıxış + qeydiyyat). Mock `signup` boş gövdəni anonim istifadəçi
  kimi qəbul edir (`email null`).
- Yoxlama: `smoke_numune.sql` (4), `test/e2e_numune.py`; bələdçi FAQ
  «Nümunə hesab nədir?».

## Ev tapşırığı avtomatı və WhatsApp mətni (yol xəritəsi 21.2)

SQL yoxdur, yalnız panel. Üç yer:
- **Tapşırıqdan sonra** (`doAssign` → `ASG_FLASH` → `drawAssign` `#asgFlash`):
  «Tapşırıq verildi: «…»» + «WhatsApp-a göndər» (`wa.me/?text=`) +
  «Mətni kopyala». Mətn `waAsgText(title, closes, who)`: fərdi
  təyinatda şagirdin adı ilə. Şagirdə bildiriş göndərə bilmirik (xarici
  şəbəkə yoxdur) — müəllim bir toxunuşla qrupa atır.
- **Plan «Keçildi»** təklifi «Ev tapşırığı verilsinmi?», 10 sual (əvvəl 15);
  yığılandan sonra eyni WhatsApp qutusu (testin adı `tests`-dən bir
  sətirlik oxunur — RPC adı qaytarmır).
- **Generator «Tövsiyə olunan»** (`loadGenRec`): dərs planı olan qruplar
  üçün (qrupdan gəlmişiksə yalnız o, yoxsa 5-ə qədər) son keçilən
  fəsildən 10 sual; «Yığ» filtrləri qoyub `makeTest()` çağırır → test
  yığılır, tapşırıq ekranı təzə test seçili açılır (`PICKNEW`). Ad:
  «Fəsil — ev tapşırığı». Yalnız abunəli hesabda (hovuz «all»).
Testlər: `e2e_bugun.py` C və G bölmələri, `e2e_plan.py` təklif mətni.

## «Bu günün dərsi» — dərsə hazırlıq kartı (db/126)

Yol xəritəsi 21.1. Qrup ekranında qrup kartından sonra, siqnallardan
əvvəl `#prep`: növbəti mövzu (plan üzrə ilk keçilməmiş ders, fəsil və
n/N), son keçilən (tarix, testi varsa ortalama və yazan sayı), ev
tapşırığını etməyənlər adbaad (açıq təyinat, submit yoxdur; qrup + fərdi,
fərdi yalnız sahibində), düymələr «… testi yığ» (generator: fənn, sinif,
son keçilən FƏSİL seçili — suallar fəslə bağlıdır) və «Tapşırıq ver».
Plan yoxdursa «Planı qur» linki plan sekməsini və formanı açır.
`rpc_lesson_prep(p_class_id)` — `app.plan_class` ilə qorunur; «keçildi»
olanda `planDone` → `loadPrep` kartı yeniləyir. Zəif/risk siqnalları
ayrıca (`rpc_class_alerts`) qalır. Testlər: `smoke_bu_gun.sql` (5),
`test/e2e_bugun.py` (17/17); bələdçi addım 8, şəkil `m11_bu_gun.png`.

## Ziyarət sayğacı (db/161)

«Ziyarətçi sayını görə bilərəm?» — GitHub Pages statistika vermir,
Cloudflare DNS-only trafiki görmür, kənar skript qadağandır. Öz sayğac:
`assets/visit.js` (ana səhifə + bələdçi, `muellim/config.js`-dən sonra
yüklənir, `body[data-page]`) anon açarla `rpc_visit(page, ev)` çağırır —
açılanda `view`, `[data-ev]` linklərində `demo_muellim/demo_sagird/
demo_valideyn/panel/beledci`. Cədvəl `visits` (RLS, siyasət yox);
unikal = `md5(günlük təsadüfi duz + IP + UA)`, duz `app_state.visit_salt`,
IP saxlanmır; PostgREST `request.headers` yoxdursa (yerli mock) `vid`
null. Spam: vid başına gündə 200. `rpc_admin_visits(p_days)`: bu gün /
7 / 30 (baxış, unikal, demo, qeydiyyat), günlər massivi, hadisə bölgüsü;
90 gündən köhnə sətirlər silinir. Panel: İdarəetmədə «Ziyarətlər» (4
lövhə, 30 günlük sütun qrafiki `.vchart` tək seriya, huni sətri).
Anon ağ siyahısı **20** (05_grants iki massiv, smoke_huquq 20).
e2e: `**/config.js*` marşrutu landing-də də mock-a yönləndirir, ona görə
kənar sorğu olmur. Yoxlama: `smoke_ziyaret.sql` (3), e2e_panel landing.

## Nümunə nüsxəsi həddi — bot müdafiəsi (db/159)

Təhlükəsizlik yoxlaması (2026-09-07): anonim giriş açıqdır, hər «Müəllim
kimi bax» ~1 MB nüsxə qurur, hədd yox idi — bot gündə ~700 nüsxə ilə
pulsuz bazanı doldura bilərdi. `db/159_demo_hedd.sql`: saatda ən çox
`app.demo_hour_limit()`=20 **yeni** nüsxə (keçəndə `53400` «Numune
hazirlanir - bir nece deqiqeden sonra yeniden cehd edin»; panel `#demoLim`
sakit kartı + `#demoRetry`); mövcud nüsxə 10 dəqiqədə birdən çox
qurulmur (`reused:true`, mövcud kodlar qayıdır); `rpc_demo_reset`
hesabsız anonim istifadəçiləri (`auth.users.email is null`, 24 saat+)
silir — bu silmə `get diagnostics`-dən SONRA gəlir, yoxsa
`deleted_copies` sayğacını pozur. Yoxlama: `smoke_numune.sql` 6,
`e2e_numune.py` F. Qalan tövsiyələr (edilməyib): CSP meta, Supabase
«Confirm email» + min parol 8, dörd hesabda 2FA.

## Nümunə məlumatı admin bölmələrinə düşmür (db/139, 140)

138-dən sonra görünən: «Sual bildirişləri 4» — hamısı demo qurucusunun
uydurduğu «Tural Q.» bildirişi (hər nüsxədə bir); «Sual keyfiyyəti 16» —
demo cəhdlərindən hesablanmış «ölü variant» siqnalları. `db/139`:
`rpc_admin_reports` / `rpc_admin_reports_count` `is_demo` hesabın
(müəllim və ya şagirdinin) bildirişini göstərmir; `app.qstat_rows` demo
şagirdlərinin cəhdlərini statistikaya salmır (migrasiya `question_stats`-ı
bir dəfə yenidən hesablayır). `db/140`: `rpc_admin_feedback` / `_count`
de eyni cür (`app.feedback_is_demo(account, student)`) — «Bizə yazılanlar»
da demo mesajını göstərmir. Demo qurucusu (136) dəyişmir. Qayda: **demo
məlumatı yalnız demo hesabın öz panelində görünməlidir** — yeni admin
bölməsi yazanda `is_demo`-nu çıxar. Yoxlama: `smoke_numune.sql` 5.

## Admin: kim nə vaxt girib (db/125)

İstifadəçi sualı: «admin olaraq kimlərin girdiyini izləyə bilərəm?».
«aktivlik» yalnız cəhd/test yığmağı ölçürdü. İndi hər hesab sətrində
«müəllim girişi: bu gün» və «şagird girişi: 3 gün əvvəl»; 5-ci lövhə
«girib · son 7 gün»; süzgəc «Girməyənlər» (7 gündür heç bir üzv
girməyib, 7 gündən köhnə giriş narıncı).

Mənbə: `profiles.last_seen_at` — panel açılanda `rpc_seen()` yazır
(15 dəqiqədə bir dəfədən çox yox; `boot()`-da çağırılır). Supabase-in
`auth.users.last_sign_in_at`-i yalnız parolla girişdə yenilənir, sessiya
aylarla qalır — ona görə ikisinin böyüyü götürülür. Şagird/valideyn
girişi = `student_sessions`/`parent_sessions.created_at` (kodla giriş).
Yerli stub `auth.users`-ə `last_sign_in_at` əlavə olundu, mock signup və
signin-də yazır. Test: `smoke_admin_giris.sql` (4), e2e_paket genişləndi.

## Şagird adları — tam ad müəllimə, qısa ad lövhəyə (db/124)

Canlı sual: «Kimə» seçimində «Hüseynov M.» iki nəfər — kim kimdir?
Qayda: müəllim panelindəki bütün şagird seçimləri (`aWho`, `pWho`,
diaqnostika qeydi) **tam adı** göstərir. Qısa ad (`display_name`) şagird
lövhəsi üçündür; `rpc_add_student` onu qrupda təkrarsız yaradır
(`app.unique_display_name`: «Murad H.» → «Murad Hə.» → «Murad Hədiyev»
→ «… 2»), 124 mövcud təkrarları bir dəfəlik düzəldir. Müəllimin əl ilə
verdiyi qısa ad toxunulmur.

Şagird hesabatında «Test tapşır» düyməsi: tapşırıq ekranı `#/a/<gid>/<sid>`
ilə açılır, «Kimə» həmin şagird seçili, Geri hesabata qaytarır (`ASG_PRE`).

## Qrup + fərdi təyinat eyni testə — db/123

Canlı hadisə (2026-09-05): şagird «Bitir» basanda «more than one row
returned by a subquery». 28-dən bəri eyni test həm bütün qrupa, həm də
ayrıca bir şagirdə təyin oluna bilir → iki açıq təyinat. `rpc_submit_attempt`
cəhd həddini «class + test + açıq» ilə skalyar alt-sorğuda axtarırdı.
`rpc_start_attempt` isə `select into` ilə ilk gələni götürürdü — xəta
yox, amma BAŞQA şagirdin fərdi təyinatı da düşə bilərdi.

Qayda: təyinat axtaranda həmişə `(student_id is null or student_id =
v_student)` + `order by student_id nulls last limit 1` (fərdi üstündür).
Test: `db/test/smoke_teyinat_ikili.sql` (4 yoxlama; düzəlişdən əvvəl 1-ci
eyni canlı xəta ilə düşür).

## «Bizə yaz» — istifadəçi təklifləri (db/122)

İstifadəçinin sözü: «real təcrübədən gələn təkliflər olacaq, biz
dəyərləndirəcəyik». Tətbiqdən kənara şəbəkə müraciəti yoxdur, ona görə
hər şey Supabase-də `public.feedback` cədvəlindədir. RLS açıq, siyasət
yoxdur → cədvələ birbaşa giriş yoxdur; yalnız security definer RPC-lər.

| Kim | Haradan | RPC | Hədd |
|-----|---------|-----|------|
| Müəllim | Profil → «Bizə yazın» kartı | `rpc_feedback_send(kind, body, page)` | 10 / gün |
| Şagird | test siyahısının sonu, yığılmış `<details>` | `rpc_student_feedback(token, …)` (anon) | 5 / gün |
| Valideyn | ev ekranının sonu, yığılmış `<details>` | `rpc_parent_feedback(token, …)` (anon) | 5 / gün |
| Admin | İdarəetmə → «Bizə yazılanlar» | `rpc_admin_feedback(status)`, `_count()`, `_set(id, status, note)` | `app.admin_ok` (2FA) |

Növ: `teklif · problem · sual · tesekkur`. Status: `new → seen → planned →
done → closed`. Mətn 10–2000 simvol (`app.feedback_check`). `page` —
müəllimdə hansı ekrandan Profilə gəlib (`FB_FROM`, route()-da yazılır:
«Qrup», «Sual bankı»…), şagird/valideyndə sabit.

**Dövrə bağlanır:** admin status + qeyd yazır → müəllim Profildə
«Yazdıqlarınız» siyahısında status nişanını və «Cavabımız» qutusunu
görür (`rpc_feedback_mine`, son 30, 5-dən sonra «Daha N»). Şagird və
valideynə cavab göstərilmir (onların hesabı yoxdur) — admin kartında
kimin valideyni / hansı sinif yazılır, müəllim vasitəsilə çatdırılır.
İcmalda admin kartı «N yeni müraciət» deyir (`rpc_admin_feedback_count`).

Anon ağ siyahı (05_grants, iki massiv) 13 RPC: `rpc_student_feedback`,
`rpc_parent_feedback` əlavə olundu. Testlər: `db/test/smoke_bize_yaz.sql`
(7), `test/e2e_bize.py` (16/16). Admin kartında müəllimin adı
`profiles.full_name`-dən, şagirdin `students.full_name`-dən gəlir.

## Bələdçi — `komek/`

«Necə işləyir» səhifəsi: müəllim / şagird / valideyn üçün addım-addım,
**real ekran şəkilləri ilə** (`komek/img/*.png`, 18 şəkil). İstifadəçinin
tələbi: ilk dəfə çətinlik çəkənlər girib oxusun. Keçidlər: landing
menyusu («Bələdçi») və «Üç addım» altı, müəllim panelində Profil,
şagird və valideyn giriş ekranlarında «Necə işləyir?».

Şəkillər əl ilə çəkilmir — `test/beledci_sekil.py` mock üzərində real
axını gedib çəkir (qeydiyyat → qrup → şagird → tapşırıq → şagird test
yazır → hesabat → valideyn). **Ekran dəyişəndə skripti yenidən işlət**,
yoxsa bələdçi köhnə ekranı göstərər; işlətmə qaydası faylın başındadır.
FAQ-dakı iddialar (kod 8 simvol, pulsuz hədd 5 şagird, 30 gün valideyn
sessiyası, cəhd sayı) kodun faktlarıdır — kod dəyişəndə ora da bax.

`bump.sh` `komek/index.html`-i də bilir (base.css `?v=`).
Video hələ yoxdur: səssiz avtomatik video az fayda verir; istifadəçi
telefon/OBS ilə səsli çəksə, `<video>` ilə `komek/`-ə qoyulur (öz
serverimizdən — xarici embed CSP/qayda ilə bağlıdır).

## «Beta» nişanı (2026-09-07)

Pul alınmır, VÖEN yoxdur, paketlər sınaq kimi pulsuz verilir; canlıda
`SHOW_PLANS=false` (qiymət görünmür — hüquqi əsas budur, nişan yox).
Nişan gözləntini idarə etmək üçündür: üst zolaqda `.wm`-dən sonra
`<span class="beta">beta</span>` (müəllim/şagird/valideyn, stil
`assets/base.css .top .beta`; ≤640px gizlənir — telefonda hesab adı
kəsilirdi). Söz «sınaq» yox: bizdə «rüb sınağı» var, «sınaq layihəsi»
kimi oxunurdu, ana səhifədə loqo yanında `i.beta` +
`.beta-note` cümləsi, bələdçidə loqo nişanı + FAQ «Sınaq nişanı nədir».
İlk ödənişdən əvvəl: VÖEN → `SHOW_PLANS=true` → nişanı çıxar (dörd yer).
`.wm` mətni dəyişmir — e2e_bank onu `== "Bil10"` yoxlayır.

## İdarəetmə ekranı (db/173, 2026-09-09)

Admin səhifəni **hər gün** açır və böyüməyə baxır — quruluş buna görə
düzülüb, sıra belədir:

1. **Bu gün** — yeni qeydiyyat · giren müəllim · cəhd (Bakı günü ilə,
   `rpc_admin_stats.accounts_today / seen_today / attempts_today`)
2. **Ümumi** — hesab · pullu/sınaq/pulsuz · aylıq gəlir · şagird
3. **Ziyarətlər** — qrafik; yuxarıdadır, çünki səhifə bunun üçün açılır
4. **Hesablar** — axtarış + süzgəc + cədvəl. Uzun izah «Necə işləyir?»
   `<details>`-i altındadır: bir dəfə oxunur, sonra mane olur
5. **Diqqət** — sual bildirişləri · keyfiyyət · müraciətlər
6. **Ayarlar** — hədiyyə paket · təhlükəsizlik (yığılmış)

**`admFold(başlıq, say, iç)`** — bölmə dolu olanda özü açılır və sayı
göstərir, **boş olanda bir sətrə yığılır** və sağda yaşıl «təmizdir»
yazır. Səbəb: üç boş kart dolu kart qədər yer tuturdu. İçinə girmək
yenə mümkündür (köhnə bildirişlərə baxmaq lazım ola bilər).

**Test yazanda:** yığılmış bölmədəki element Playwright üçün
**görünmür**. Admin səhifəsini açandan sonra:
```python
pg.wait_for_selector(".fold", timeout=15000)
pg.eval_on_selector_all(".fold", "els => els.forEach(e => e.open = true)")
```
Ekran yenidən çizilirsə (məsələn bildiriş bağlananda) **təkrar** açmaq
lazımdır. 2FA açıqdırsa `#/adm` əvvəlcə **kilid ekranını** göstərir —
orada `.fold` yoxdur, gözləmə oraya qoyulmamalıdır.

**Hesablar cədvəli** (`admRows`) — 7 sütun, sətir **2 sətirdir**:
`# · Müəllim · Paket · Müddət · Şagird · Son giriş · ···`
- «Bitir»+«Qalan» birləşib **Müddət**: böyük «41 gün», altında «20 okt»
- «Şagird»: böyük rəqəm, altında **yalnız sıfır olmayanlar**
  («3 test · 12 cəhd») — köhnə «0 ş · 1 t · 0 c» oxunmurdu
- «Son giriş»: müəllimin girişi əsas siqnaldır; şagird girişi altda.
  **Şagirdi olmayan** hesabda «şagird yoxdur» yazılır — «hələ
  girməyib» xəbərdarlığı yalnız şagirdi olub heç girməyəndə çıxır
- Yalnız «Müəllim» sütunu sərbəstdir, qalanları sabit — artıq en bir
  yerə yığılır, sütunlar arasında boşluq açılmır. Səhifə eni
  `.wrap.wideadm` = **1100px** (məzmuna görə ölçülüb)

**Admin hesabı ödəmir:** `rpc_my_context` admin hesabına «Admin ·
daimi» qaytarır — qiymət, «hədiyyə bitir» və xatırlatma zolağı
görünmür (`rpc_paket` bunu onsuz da edirdi, my_context geridə qalmışdı).

## Öz testini silmək / adını dəyişmək (db/193, 2026-09-14)

İstifadəçi «Hazır testi tapşır» siyahısında «Samir 1» ×4 gördü — eyni adla
dəfələrlə yığılmış testlər, silmək yeri yox idi.

- `rpc_test_rename(test, ad)` (sahib, 1–120), `rpc_test_delete(test)` — sahib,
  yalnız educator testi, **heç bir cəhd yoxdursa** (şagird işləyibsə nəticə
  itməsin — server rədd edir, düymə də bağlıdır). Silinəndə test_questions /
  assignments cascade, plan bəndlərində test_id null olur; **suallar qalır**.
- Vərəqdə (`#/t/`) düymə sırasının sonunda «Adı dəyiş» (başlıq yerində giriş
  qutusu, Enter/Saxla) və «Sil» (təsdiq → `#/gen`).
- «Hazır testi tapşır» siyahısında öz testinin yanında qələm keçidi →
  vərəq (`.trw .tgo`); hazır bank testlərində yoxdur.
- Yoxlama: `smoke_test_sil`, `e2e_testsil` (35-ci mərhələ). Testdə tələ:
  eyni ünvana `goto` naviqasiya yaratmır — tam yüklənmə + hash.
- Canlıda: `db/193` (anon siyahısı dəyişmir).

## Vaxtlı test (db/192, 2026-09-14)

`tests.time_limit_sec` 01-dən bəri var idi, heç yerdə işləmirdi. İndi:

- **Müəllim** — vərəqdə (`#/t/`) çap düymələrinin yanında «⏱ vaxtsız / 5…90
  dəq» seçimi → `rpc_test_time_limit(test, dəq)` (sahib, ≤ 180). Vərəq
  başlığında və çapda «vaxt: N dəq»; «Hazır testi tapşır» siyahısında ⏱.
  Limit **testin özündədir**, bütün təyinatlara aiddir.
- **Şagird** — siyahıda «⏱ N dəq»; test ekranında geri sayan saat
  (`#tmr`, son dəqiqə qırmızı); 0-da cavablar **özü göndərilir**
  (təsdiq soruşulmur). Qalan vaxt `rpc_start_attempt → remaining_sec` ilə
  **serverdən** gəlir — telefonun saatı dəyişdirilsə də düz; yarımçıq
  cəhd davam edəndə də doğru qalır. `visibilitychange`-də saat yenilənir.
- **Server** (`rpc_submit_attempt`) — qərar buradadır: limit keçibsə
  `attempts.timed_out = true`; **limit + 60 s güzəşt** də keçibsə cavablar
  **sayılmır** (`late`, 0 bal). Güzəşt şəbəkə gecikməsi üçündür.
  `rpc_test_result` və submit `timed_out`/`late` qaytarır → şagird ekranında
  «Vaxt bitdi — avtomatik göndərildi» / «bal hesablanmadı» qeydi.
- Hər üç RPC-nin gövdəsi `pg_get_functiondef`-dən götürülüb, yalnız
  göstərilən sətirlər əlavə olunub; `rpc_test_preview` `time_limit_sec`
  qaytarmırdı — əlavə olundu.
- **Hələ yox:** müəllim hesabatında «⏱ vaxt bitdi» nişanı (cəhd siyahısı);
  bir cəhd üçün fərqli limit (təyinata bağlı); şagird tapşırıq siyahısında
  qalan vaxt.
- Yoxlama: `smoke_vaxtli_test` (sahib/yad, qalan saniyə, güzəştdə bal,
  gec cavab 0, limitsiz toxunulmur), `e2e_vaxt` (34-cü mərhələ: seçim →
  vərəq → şagird saatı → 0-da avtomatik → güzəşt → gec).
- Canlıda: `db/192` (anon siyahısı dəyişmir).

## Mətnlə ev tapşırığı (db/191, 2026-09-14)

İstifadəçi: «repetitor uşağa “filan dərsi oxu, təkrarla” deyir — bizdə
var?» Yox idi: «tapşırıq» həmişə **test** idi. İndi var — **müəllim,
şagird, valideyn üçü də görür.**

- `public.homework(class_id, student_id NULL=bütün qrup, body ≤ 500, due)`,
  `public.homework_done(homework_id, student_id)` — şagirdin «etdim»i.
- Müəllim (authenticated): `rpc_homework_add / _list / _del` — Tapşırıqlar
  ekranında «Ev tapşırığı — mətnlə» bölməsi: mətn, kimə (qrup/şagird),
  son tarix; siyahıda «N / M etdi — adlar». Girişi `app.homework_class_ok`
  (rpc_assign_test ilə eyni qayda). Gündə qrupa 50 limit.
- Şagird: `rpc_student_tests → 'homework'` (mövcud çağırış, yeni açar) —
  «Tapşırıqlar» başlığının altında, testlərin **üstündə**; «Etdim ✓» →
  `rpc_student_homework_done(p_token, p_id, p_done)` — **yeni anon RPC,
  siyahı 20 → 21** (05_grants iki massiv, smoke_huquq). Edilənlər «Edilib»
  altına qatlanır, «Geri al» var. Test tapşırığı yoxdursa boş mətn «Test
  tapşırığı yoxdur» deyir (ev tapşırığı varkən «tapşırıq yoxdur» yalan idi).
- Valideyn: `rpc_parent_home → 'homework'` — «Gözləyən tapşırıq»da
  testlərlə bir siyahıda, üstdə; «müəllimin tapşırığı · yalnız ona».
- Hər iki mövcud RPC-nin gövdəsi `pg_get_functiondef` ilə götürülüb, yalnız
  bir açar əlavə olunub (188-dəki dərs: əl ilə köçürmə sonrakı miqrasiyada
  itirdi).
- Nümunə hesabda nümunə tapşırıq: `app.demo_homework` (eyni commit).
- **«Bu günün dərsi» kartı + bildiriş (db/194, 2026-09-14).** İstifadəçi:
  «bu da yaxşı fikirdir». `rpc_lesson_prep → 'hw'` — qrupun **son** yazılı
  tapşırığı (45 gün içində): mətn, kimə, son tarix, `done/total`, `undone`
  adlar. Kartda «Yazılı tapşırıq» sətri («etməyən: Aysu, Kənan · 0/2 etdi»
  / «Hamı edib ✓», «hamısı» → `#/a/qrup`). Test tapşırığı sətri («Etməyənlər»)
  olduğu kimi qalıb — ikisi ayrı şeydir. `rpc_home → 'hw_alerts'` — son
  tarixi **bu gün və ya keçmiş** (14 günədək), hələ etməyən olan
  tapşırıqlar (≤ 8) — **abunədən asılı deyil**. Siqnallar ekranında
  «Ev tapşırığı — vaxtı çatıb» kartı (`#nHw`, sətir `#/a/qrup`-a aparır),
  zəng nöqtəsi = siqnal + ev tapşırığı (üç yerdə: İcmal, Siqnallar, boot).
  Sıra `created_at desc, id desc` — eyni tranzaksiyada yazılan iki
  tapşırığın `now()`-u eynidir (smoke bunu tutdu). Canlıda: `db/194`
  (grants dəyişmir).
- **Kart sadələşdi (eyni gün).** İstifadəçi canlı ekranı göstərdi: «bu
  günün dərsi nədir? harada yazılıb? çox dolaşıqdır». Səbəb: eyni şeyə üç
  ad («Bu günün dərsi» / «Növbəti mövzu» / plan qutusunda «Növbəti dərs»),
  «3/7» nəyin 3-ü olduğu yazılmırdı, «Ev tapşırığı» sözü iki fərqli şeyə
  (test + yazılı) iki ayrı sətirdə. İndi: kart **«Dərsdən əvvəl»**, sətir
  **«Növbəti dərs»** («… fəsli · dərs 3/7» — plan qutusu ilə eyni ad),
  **«Ev tapşırığı»** bir sətir, içində «TEST · …» və «YAZILI · …»
  alt-sətirləri; başlıq statistikası (`gHw`) ikisini birlikdə deyir
  («etməyən var» / «hamı edib» / «yoxdur»). Plan sekməsindəki «Növbəti
  dərs» qutusu qalır — «Keçildi» düyməsi oradadır. Qayda: **bir şeyə bir
  ad**; «bu gün» sözü tarix olmayan yerdə yalan vəddir.
- **Plan siyahısında növbəti dərs seçilmirdi** (istifadəçi: «dərs planına
  bax, bugünün dərsi açıq-aydın bilinmir» — 3-cü sətir 4–7 ilə eyni
  görünürdü). İndi `.plrow.cur`: marka rəngli fon, sol zolaq, ad marka
  rəngində, yanında «NÖVBƏTİ» nişanı (`.plnext`); qutuda «‹fəsil› fəsli ·
  dərs 3/7» (kartla eyni ifadə). Qayda: **cari element siyahıda gözlə
  tapılmalıdır, oxumaqla yox.**
- **Ad: «Bu günün dərsi» (istifadəçi israr etdi).** Mən «Növbəti dərs»
  yazmışdım («tarix yoxdur, ‹bu gün› yalan vəddir»); istifadəçi: «hamısı
  növbəti, hanı bugünün dərsi?». Müəllimin dilində planın ilk keçilməmiş
  dərsi elə bu gün keçəcəyi dərsdir. İndi kartda sətir, plan qutusunun
  etiketi və siyahı nişanı («BU GÜN») — hamısı «Bu günün dərsi». Qayda:
  **termini müəllimin dili seçir, mənim dəqiqliyim yox.**
- Yoxlama: `smoke_ev_tapsirigi` (yad müəllim girmir, şagird başqasının
  fərdi tapşırığını görmür/işarələmir), `e2e_ev` (33-cü mərhələ: üç tətbiq,
  ayrı brauzer kontekstləri — eyni kontekstdə şagird sessiyası qalır).
- Canlıda: `db/191` → sonra **`db/05_grants.sql` yenidən**.

## Ana səhifə: əvvəl bax, sonra qeydiyyat; mənbə (db/195, 2026-09-14)

Ölçü (bu gün, `visits` üzrə yol): 7 ziyarətçi — 4-ü `home:view` ilə
bitdi (ilk ekranda getdi), 2-si `home:panel` (formanı görüb qaçdı), 1-i
şagird nümunəsi; heç kim müəllim nümunəsinə girmədi, heç kim qeydiyyatdan
keçmədi. Mənbə: istifadəçi **reklam şəklini** WhatsApp qruplarında
paylaşıb, adamlar ünvanı əl ilə yazıb gəlib — linksiz, deməli maraq var,
amma sayt «qeydiyyatdan keç» deyirdi.

- **İlk ekran:** üç qapı nümunəyə aparır («Müəllim kimi bax» →
  `muellim/#/demo`, «Şagird kimi bax» → `sagird/?kod=DEMO0001`, «Valideyn
  kimi bax» → `valideyn/?kod=VDEMO001`); «Panelə keç / Daxil ol / Valideyn
  girişi» altda kiçik `.hlinks` sətrində. Başlıqdakı «Panelə keç» qalır.
  Aşağıdakı `#demo` bloku (nümunə linkləri) **çıxarıldı** — istifadəçi:
  «bu təkrar qalıb»; yerində `#cta` «Bəyəndiniz? Hesab yaradın» (videodan
  sonra növbəti addım). `.hlinks` ağ çərçivəli düymələrdir («sönük qalıb»
  deyildi). Qayda: **adam nə alacağını görməmiş ondan heç nə istəmə;
  eyni düymə səhifədə iki dəfə olmasın.**
- **Bir alıcı — müəllim (15.09).** İstifadəçi: «biz bunu müəllimlərə
  satırıq; ‹şagird kimi bax›, ‹valideyn kimi bax› lazım deyil, əvvəlki
  dizaynı korladı». Şagird və valideyn saytdan yox, müəllimin verdiyi
  kodla gəlir. İndi ilk ekranda iki qapı: **«Müəllim kimi bax»** (nümunə)
  + **«Hesab yarat»**; kodu olanlara kiçik sətir («Şagird və ya
  valideynsiniz? Kodla daxil olun: şagird / valideyn»); nişan «Beta
  dövründə müəllimlər üçün pulsuz». Qayda: **ana səhifə alıcıya
  danışır; istifadəçilər (şagird, valideyn) alıcıdan gəlir.**
- **Diaqnostika-mərkəzli ilk ekran (15.09, GPT təklifi + istifadəçi).**
  Başlıq «Şagirdinizin nəyi bilmədiyini görün»; sağda illüstrasiya
  əvəzinə **real ekran** (`assets/hero_diag.png` — nümunə şagird kartının
  diaqnostika hissəsi, `test/_demo_shots.py`-dən kəsilib), telefonda da
  görünür; «Necə işləyir» dörd addımlı dövrə: diaqnostika → zəif mövzu →
  məşq → yenidən ölç. «Qrupu biz quraq» CTA-sı **qəbul edilmədi**
  (istifadəçi: «bir müəllim qrup yarada bilmirsə proqramı necə işlədəcək»).
  Rəqiblər (araşdırıldı): Kampus.az (idarəetmə: cədvəl, davamiyyət,
  imtahan, valideyn; 7 gün sınaq, «24 saata qururuq»), TestUp.az (imtahan
  aləti), oxuyan.az, e-sual.az, otk.az, teorem.az. Bizim fərq: kurikulum
  planı + diaqnostika + «bundan başla» + səhv dəftəri + şagirdin məşqi —
  satış mesajı bunun üstündədir. Sinif adları: `.ok` və `.free` səhifədə
  başqa mənada var — yeni sinif `hfree`. **Sağ tərəf (16.09):** real ekran şəkli
  («yaraşmır»), çəkilmiş diaqnostika kartı və illüstrasiya + nəticə nişanı
  sınandı; istifadəçi **təmiz illüstrasiyanı** seçdi (`assets/hero.png`,
  telefonda gizli). Videonun yanında fəsil siyahısı əvəzinə beş fakt
  (`.vfacts`). **Quruluş (16.09):** «başlıq → üstünə minmiş
  video kartı» silueti Oxuyan.az-a oxşayırdı (rəng də firuzə); istifadəçi
  rəngi saxladı, quruluşu dəyişdik: baş zolaq təmiz bitir (`.topband`
  padding 150→64, `.under` mənfi margin yoxdur), sonra dörd addım, video
  ayrı `#video-sec.tint` bölməsində. Qayda: **rəqiblə eyni siluet — eyni
  məhsul hissi; fərq məzmunda yox, ilk baxışda da olmalıdır.**
- **Mənbə:** linkdə `?src=wa` (yalnız `[a-z0-9_-]{1,20}`, uzun/pis dəyər
  atılır, kəsilmir); `assets/visit.js` onu `sessionStorage.bil10_src`-də
  saxlayır, panelin giriş ekranı da oradan oxuyur. `visits.src`,
  `rpc_visit(p_page, p_ev, p_src)` — **köhnə 2-parametrli imza silinib**
  (PostgREST iki imzanı qarışdırır), `app.visits_pub` görünüşünə sütun,
  `rpc_admin_visits → 'src'` (30 gün: baxış · nəfər). Admin Ziyarətlər
  kartında «Mənbə» sətri. `smoke_ziyaret` §4, `e2e_panel`.
- Canlıda: `db/195` → **`db/05_grants.sql` yenidən** (imza dəyişib).
  Paylaşımlarda link: `https://bil10.az/?src=wa` (Facebook üçün `fb`).
- **Video ilk ekranın altındadır** (istifadəçi: «videonu da birinci
  görünənlərdən et»). Əvvəl «Necə işləyir» bölməsinin sonunda idi, 7
  nəfərdən 4-ü ora çatmırdı. Panel mokapı (`.preview`) çıxarıldı — video
  elə canlı mokapdır. Videonun əvvəlinə reklam çarxı kimi giriş («Müəllim
  nə qazanır?» — 4 sətir bir-bir açılır, sonra «İndi baxaq»), üz şəklində
  böyük ▶ (`test/_video.py: intro()`, `poster_tam.png`); istifadəçi: «5
  saniyə sonra göstərməyə başlayır, ilk baxışdan şəkil hissi verir».
  İkinci dövrə (istifadəçi: «çarx çox sürətlidir, sürəti aşağı salıram,
  proqram lap ləngiyir; zövqsüz və faydasız»): giriş vaxtı dəqiq saniyə
  ilə (kartlar 1,8–3 s, SPEED-ə bölünür), hər qazanc kartında **real
  ekran** (nümunə hesabdan: generator, «Dərsdən əvvəl», hesabat, valideyn
  tətbiqi — `test/_demo_shots.py` → `/tmp/claude-0/video/shots/*.png`,
  video onları fayldan götürür: eyni gedişdə çəkəndə sonra hesabat
  ekranı açılmırdı, iki yığım boşa getdi), proqram hissəsi sakit
  (`SPEED` 1.8 → 2.3, `SHORT` 1.5 → 1.8; 5:26 → 7:04). Kart ölçüləri
  CSS px-dir (kadr 432×768, DPR 2.5) — 1020px «telefon» ekrandan böyük
  çıxmışdı. Sıra: `NEW_DB=1 test/tek.sh _demo_shots.py` → `VIDEO_TAM=1
  NEW_DB=1 test/tek.sh _video.py` → `python3 test/_video.py --tam --mp4`
  → `assets/teqdimat*.{mp4,jpg}` + `index.html` fəsil saniyələri.
- **Üçüncü dövrə — format dəyişdi (2026-09-15).** İstifadəçi: «7 dəq çox
  uzun və yorucudur, çarx fikri yaxşıdır; 2–3 dəq bəs edər, detallı izahla,
  şəkillə». Gəzinti (`tam`) saytdan çıxdı; indi **çarx** (`VIDEO_CARX=1`,
  `carx()`, `SCENES`): qarmaq → 10 səhnə (qrup, test yığ, tapşırıq, şagird,
  hesabat, şagird kartı, dərs planı, ev tapşırığı, valideyn, icmal), hər
  biri kicker + başlıq + 2 cümlə + nümunə hesabdan real ekran, 7–9 s →
  «Nümunəyə baxın · bil10.az». 1:31, 0,9 MB. Ekranlar `test/_demo_shots.py`
  (12 şəkil: müəllim 9, şagird 2, valideyn 1). Sıra: `NEW_DB=1 test/tek.sh
  _demo_shots.py` → `VIDEO_CARX=1 python3 test/_video.py` (server lazım
  deyil) → `python3 test/_video.py --carx --mp4` → `assets/teqdimat.mp4`,
  `teqdimat_uz.jpg`, `index.html` səhnə saniyələri. Uzun gəzinti
  generatoru (`tam`) qalır, istifadə olunmur. Qayda: **çarx sata bilər,
  gəzinti öyrədir — sayta çarx, bələdçiyə gəzinti.**

- **Dördüncü dövrə — v2 dizaynla təkrar çəkiliş (2026-09-16).** İstifadəçi:
  «videodakı ekranlar indikinə uyğun deyil». Məzmun dəyişmədi, yalnız
  ekranlar (eyni 3 addım), `/tmp/claude-0/shot/logo.svg` rəngləri yeni
  loqoya (#087f75→#42bcae, sarı #f4c94f), üz şəklində «1,5 dəqiqəlik çarx»
  (əvvəl «2 dəqiqəlik» yazılırdı, çarx 1:31-dir). Qayda: **dizayn
  dəyişəndə çarx yenidən yığılır** — 3 əmr, 3 dəqiqə.

## db/202 — Təsdiqsiz giriş + İdarəetmədə huni (2026-09-17)

Üç AI turu (funksiya · distribusiya · aktivləşmə) + öz rəqəmlərimiz: 6
qeydiyyat → 3 təsdiq → 3 giriş → 0 qrup. İki iş:

1. **Təsdiqsiz giriş.** Supabase → Authentication → Sign In / Providers →
   Email → **«Confirm email» söndürülür** (istifadəçi, dashboard) — signUp
   sessiyanı elə qeydiyyatda verir, `doAuth` onsuz da `access_token`
   gələndə `boot()` edir. Paneldə `mailBar()` (`boot` → `demoBar`-dan
   sonra): `sb.me()` (GET `/auth/v1/user`) → `email_confirmed_at` boşdursa
   sarı `.demobar.mailbar` — «Məktubu yenidən göndər» (`sb.resendSignup`,
   POST `/auth/v1/resend` type=signup) və «Sonra» (`sessionStorage
   bil10_mailbar`, bu sessiya). Hesab hələ yoxsa da (quruluş ekranı) çıxır;
   nümunədə yox. Eyni e-poçt → Supabase «already registered» → «Bu e-poçtla
   hesab artıq var». Yerli stub `auth.users.email_confirmed_at` (00_supabase_stub,
   `add column if not exists`); mock: GET `/auth/v1/user`, POST `/auth/v1/resend`.
   Səhv yazılmış ünvan (gamil…) indi də içəri düşür — TYPO xəritəsi + zolaq.
2. **`rpc_admin_huni(p_days)`**: qeydiyyat → e-poçt təsdiqi → panelə giriş
   (`profiles.last_seen_at` və ya `last_sign_in_at`) → qrup → şagird → test
   (diaqnostiksiz) → şagird cavabı (submitted) → ödəniş (`active`, trialing
   deyil); nümunə və admin sayılmır; `p_days=0` bütün tarix; `stuck` = qrup
   yaratmayan son 50 (email, ad, tarix, girib?, təsdiq?). Panel `huniSection`
   «Ümumi»dən sonra, faizlər qeydiyyata görə; siyahı avatar · ad · e-poçt +
   nişanlar («ünvan səhv?» gamil/gemail/mail.tu…, təsdiq, giriş, tarix),
   `.hlist` 320px-dən sonra öz içində sürüşür. `smoke_huni.sql`, e2e_panel 3
   iddia, `test/_v2_huni.py`. **Canlıya əl ilə** (05_grants lazım deyil).

AI turlarından qalan növbəti işlər (razılaşdırılıb, sıra ilə): boş hesabda
ilk addım «ilk testini yığ» (qrupsuz), «adları yapışdır» toplu şagird,
«nümunəyə bax» keçidi; sonra distribusiya: çap vərəqində «Bil10 ilə
hazırlanıb», müəllimin həftəlik nəticə kartı (şəkil), həmkarla paylaş linki.
Ödəniş axını (kart, sınaq mesajları) istifadəçi qərarı ilə SONRAYA.

## Öz ziyarətimiz sayılmır (db/175, 2026-09-09)

İstifadəçi: «mən tez-tez girib çıxıram deyə artıma təsir etməsin».
**İki yer, iki ayrı həll:**

1. **Ana səhifə sayğacı** (`public.visits`) — ora **anonim** gəlinir,
   server kimin gəldiyini bilə bilmir (IP saxlanmır, JWT yox). Həll
   brauzerdədir: `refreshContext()` admin girişini görəndə
   `localStorage.bil10_oz = "1"` qoyur (`ozBrauzer()`), `assets/visit.js`
   nişanı görəndə `rpc_visit`-i **heç çağırmır**. Eyni üsul önbaxış saytı
   (`yeni.`) üçün artıq işləyirdi. Adi müəllim həmin brauzerə girsə nişan
   **silinir** — başqasının ziyarəti itməsin.
2. **«Bu gün / həftə — girən müəllim»** (`rpc_admin_stats`) — bura JWT ilə
   gəlinir, admin hesabı serverdə tanınır: `seen_today` və `seen_week`-ə
   `not app.account_is_admin(a.id)` əlavə olundu (pullu/sınaq saylarında
   bu qayda db/173-dən bəri var idi).
3. **Serverdə (db/189, 2026-09-12)** — brauzer nişanı IP dəyişəndə,
   başqa brauzerdə, önbelleksiz açılışda itirdi; istifadəçi: «mən özümü
   aldadıram». İndi `public.own_vids(vid, day)`: admin panelə girəndə
   (`rpc_seen`) cihazının `vid`-i o Bakı günü üçün nişanlanır, bütün
   hesablamalar `app.visits_pub` görünüşündən oxuyur (nişanlı sətirlər
   yoxdur — **geriyə də** işləyir). Sətirlər silinmir, `own_today`
   neçəsinin sayılmadığını deyir («Bu gün sizin N baxışınız sayılmadı»).
4. **2FA dəliyi (db/190, 2026-09-13)** — canlı ölçü: «7 baxış · 1 unikal»,
   14 sətir `view → panel` hər 3 dəqiqədən bir, saat 22:03–22:16 — admin
   özü. Səbəb: 189 nişanı `admin_ok()` ilə qoyurdu, o isə 2FA kilidinin
   açıq olmasını tələb edir; `rpc_seen` panel yüklənəndə **kod yazılmazdan
   əvvəl** bir dəfə çağırılır → kilid bağlı → nişan yox → «kənar
   ziyarətçi». Düzəliş: `app.own_mark()` nişanı `is_admin()` ilə qoyur
   (öz baxışını gizlətmək həssas oxunuş deyil), `rpc_admin_visits` isə
   **rəqəmlərə baxan anda** cari cihazı nişanlayır — IP dəyişsə də
   baxdığın rəqəm səni saymır. Serverin düzəldə **bilmədiyi**: sessiyasız
   brauzer (WhatsApp/Telegram içindəki) — linki öz brauzerindən yoxla.
   `smoke_oz_ziyaret` 7–9.

**Toxunulmayan:** `accounts`, `accounts_week`, `students`, `mrr_minor`.
Onlar **hadisə** deyil, **mövcudluq** sayır — admin hesabı bir dəfə
yaranıb, hər gün artmır. Sabit «+1» çıxarılsa köhnə ekran şəkilləri ilə
müqayisə pozulur.

Yoxlama: `smoke_admin_giris` 5 (admin bu gün girib → `seen_today` **1**,
yəni yalnız adi müəllim; 175 olmadan **2** olur), `e2e_paket` («girən
müəllim» lövhəsi bu ssenaridə **0**, çünki yeganə müəllim admindir).

## db/199 — admin → müəllim mesajı (2026-09-16)

E-poçta bizdə baxan yoxdur (istifadəçi), ona görə yeni müəllimə «kömək
edim?» demək yolu panelin içindədir. Eyni `feedback` cədvəli, yeni
`author_type='admin'`, `kind='mesaj'`, `status='closed'` (yeni müraciət
sayına düşmür), `seen_at`, `reply_to`. RPC: `rpc_admin_message(email, body)`
(nümunə hesaba yox), `rpc_my_messages()`, `rpc_message_seen(id)`,
`rpc_feedback_send(+p_reply_to)` (köhnə 3-parametrli imza drop edilir).
Panel: İdarəetmə → sətir «···» → textarea + «Mesaj göndər»; müəllim İcmalın
üstündə `.card.gift.amsg` kartı («Cavab yaz» → Profil, `REPLY_TO` +
`#fbReply` nişanı; «Oxudum» → seen); Profil → «Bil10-dan mesajlar» siyahısı;
İdarəetmə → Bizə yazılanlarda cavab `.fbctx` ilə sənin mətnin üstündə,
`oxuyub / hələ oxumayıb`. `smoke_bize_yaz.sql` §8. Şəkil skripti
`test/_v2_msg.py` (#/demo hər ziyarətçiyə nüsxə açır — mesaj nüsxəyə
yazılır). **Canlıya əl ilə tətbiq olunmalıdır**, 05_grants lazım deyil.
Məhdudiyyət: müəllim mesajı yalnız girəndə görür.

## db/203 — anonim (nümunə) istifadəçinin üstündə real hesab (2026-09-17)

Canlıda İdarəetmədə eyni adla iki hesab çıxdı: biri e-poçtlu (11 şagird,
2 qrup), biri e-poçtsuz («qrup yoxdur · 19 test»). İkincinin sahibi
`auth.users`-də `is_anonymous = true`. 19 test = nümunənin öz testləri
(7-ci sinif 9 ev tapşırığı + 3 isinmə + rüb sınağı + diaqnostika = 14,
3-cü sinif 2, 11-ci sinif 3); admin siyahısı testləri sahiblik üzrə sayır.

Səbəb: müəllim «Nümunəyə bax»-a girib, nüsxə qurulan bir neçə saniyədə
səhifəni yeniləyib (ya paneli ikinci tabda açıb). Panel anonim sessiyanı
görüb, hesabı hələ görməyib → «Hesabı quraşdırın» → ad yazıb «Davam et»
→ anonimin üstündə `is_demo = false` hesab.

Düzəliş:
- `rpc_create_account`: sahibin e-poçtu yoxdursa (anonim) `42501` xəta.
- `rpc_demo_start`: `pg_advisory_xact_lock` istifadəçi üzrə — iki tab
  eyni anda çağıranda ikincisi birincinin nüsxəsini tapır («reused»).
- Bir dəfəlik: e-poçtsuz sahibli qeyri-nümunə hesablar `is_demo = true`
  olur → gecə `rpc_demo_reset` 24 saatdan sonra testləri ilə silir.
- Panel `route()` → `noAccount()`: hesab yoxdursa `sb.me()` soruşur;
  `is_anonymous` və ya e-poçt yoxdursa `screenDemo()`, yoxsa `screenSetup()`.
- Mock `/auth/v1/user` `is_anonymous` qaytarır (e-poçt null olanda).

Testlər: `smoke_numune.sql` §11, `e2e_numune.py` H.

## «Bizə yaz» yuxarı zolaqda, öz ekranı `#/bize` (2026-09-17)

İstifadəçi: forma Profilin içində gizli qalırdı, ilk günlərdə müəllim
çətinliyini bir toxunuşla deyə bilsin. İndi:
- Yuxarı zolaqda `#btnFb` («Bizə yaz», `.btn.sm.ghost.fbtop`), zəngin
  solunda; telefonda (≤560px) yalnız qələm ikonu. `bnavShow/bnavHide`
  zənglə birlikdə göstərir/gizlədir.
- `screenBize()` — `#/bize`: forma (`fbForm("fb")`), Bil10-dan mesajlar +
  Yazdıqlarınız (`fbMineLoad`), altda WhatsApp + bələdçi. Geri:
  `backLabel("Əsas səhifə")` — gəldiyi ekrana.
- `FB_FROM` bu keçiddə dəyişmir (admin «hansı ekrandan» görür).
- Profil: forma çıxdı, `.item` keçidi `#btnMeFb` qaldı. Sol menyu Hesab
  altında «Bizə yazın». Altlıq linki və bələdçi mətni yeniləndi.
- `amsgReply` → `#/bize`. `routeTitle` `bize`.
- Testlər: `e2e_bize.py` B (düymə, Profildə forma yoxdur, Geri = Qrup).
  Şəkil: `test/_v2_bize.py`.

## db/204 — reklam: çap altlığı, kart ünvanı, «Həmkarına göndər», mənbə qeydiyyata qədər (2026-09-17)

- Çap vərəqi altlığı (`paperPrint` → `foot`): «Bil10 ilə hazırlanıb · bil10.az · müəllim · tarix».
- Nəticə kartı (`drawProgCard`) altında «bil10.az · şagird və valideynə pulsuz».
- Test vərəqi ekranında `#btnHemkar` → `hemkarShare(t, n)`: mətn + `https://bil10.az/?src=hemkar`;
  telefonda `navigator.share`, masaüstündə buferə + `#hemkarMsg .hmtxt`.
- Mənbə: `visit.js` `sessionStorage bil10_src` (əvvəldən) → `sb.signUp(email, pass, name, src)`
  → `raw_user_meta_data.src` → `app.handle_new_user` → `profiles.src` (≤20, `[a-z0-9_-]`, yoxsa null).
- `rpc_admin_huni`: `src` ({"wa":3,"":12}) + `stuck[].src`; paneldə «Haradan gəlib» sətri (`.hsrc`),
  ad xəritəsi `SRC` (wa→WhatsApp, hemkar→həmkar, kurs, ig→Instagram, kart→nəticə kartı).
- Testlər: `smoke_huni.sql` (src bölgüsü, pis dəyər null), `e2e_panel` (qeydiyyatda src),
  `e2e_gen` (altlıqda bil10.az; həmkar mətni). Şəkil: `test/_v2_reklam.py`.
- Canlıda: `db/204_menbe_qeydiyyat.sql` işə salınmalı.

## db/205 — qrup ekranında şagird siyahısı nəticə ilə (2026-09-17)

İstifadəçi indiki siyahını bəyənmədi (ad + iki kod + dörd düymə, nəticə yox);
GPT-nin cədvəl dizaynı Bil10 üslubuna uyğunlaşdırıldı.
- `rpc_class_students(p_class_id)` → `paid, since, assigned` + hər şagird:
  `attempts, avg, last_pct, last_at, assigned_own, seen_at, parent_seen_at`
  (dayandırılmışlar da gəlir). Pulsuz hədddə `free_history_days` pəncərəsi.
- `loadStudents` artıq bu RPC-ni çağırır (əvvəl `sb.select("students")`).
- Sətir (grid): telefon `ad | Hesabat+qələm` / `nəticə xətti` / kodlar;
  masaüstü `ad | nəticə | düymələr`. `.stline`: `.sres` (good/mid/low,
  `pctCls`), `.sbar` («işləyib N/M»), `.sst` («girib 2 gün əvvəl» /
  «hələ girməyib»). Cəhd yoxdursa `.stline.mini` bir qısa sətir.
- Düymə «Şagirdə bax» (ad da `data-rep`, klik olunur). «girib» = `seen_at || last_at`. Girənə qədər `.l2` və `.l3` açıq (ilk gün
  ikisi birdən göndərilir); girəndən sonra ikisi də `details.stk` «Kodlar»
  altında («Giriş kodları — şagird · valideyn»). `.stu.off` köhnə qəlibdə qalır.
- Siyahının üstündə `.stsum`: orta bal · işləyib · hələ işləməyib · hələ girməyib.
- Test hədləri: `e2e_panel` telefon sətri 145 → 160 (ölçüldü 153px).
  `smoke_reports.sql` §2b. Şəkil: `test/_v2_stu.py`.
- Canlıda: `db/205_sagird_siyahi.sql` işə salınmalı — yoxsa siyahı açılmır.

## İdarəetmə: öz mesajınızda status/cavab yoxdur (2026-09-17)

`fbCards`: `author_type === "admin"` sətrində status siyahısı və cavab qutusu
çıxmır (istifadəçi: «bu nə məna verir?»); yerinə `.fbseen` — «Hələ oxumayıb»
/ `.fbseen.seen` «Oxuyub · tarix». Sinif adı `.seen`-dir, qlobal `.ok` ilə
toqquşurdu (düymə kimi görünürdü).

## db/206 — «indi saytda» (2026-09-17)

İstifadəçi: «hal-hazırda saytda olanı bilim?». Yeni cədvəl/RPC yoxdur:
- `rpc_seen` yazma aralığı 15 → 2 dəq.
- Panel `pulseStart()`: tab görünəndə 3 dəqiqədə bir `rpc_seen`; tab
  qayıdanda dərhal bir dəfə; arxa planda göndərmir.
- İdarəetmə sətri: `last_login` 5 dəqiqədən təzədirsə `.lg-now` «indi saytda»
  (yaşıl nöqtə); «Bu gün» → «girən müəllim» lövhəsində `.tnow` «N indi saytda»
  (admin sayılmır, `rows`-dan hesablanır).
- Yük: müəllim başına 3 dəqiqədə bir xırda sorğu.
- Testlər: `smoke_admin_giris.sql` §1 (2 dəq), `e2e_paket` (nişan; lövhədə admin yox).
- Canlıda: `db/206_indi_saytda.sql`.

## db/208 — «Bizə yaz» cavabı şagirdə və valideynə çatır (2026-09-17)

İstifadəçi tapdı: şagird Ayşə yazdı, admin cavab yazdı, cavab **heç kimə**
getmədi. 122-də şagird/valideyn yalnız YAZA bilirdi, oxuya bilmirdi; müəllim
də görmürdü (`rpc_feedback_mine` `user_id = auth.uid()` süzür, şagird sətrində
`user_id` boşdur). Üstəlik cavab yazılandan sonra status «Yeni» qalırdı, ona
görə «Bizə yazılanlar 1» nişanı sönmürdü.

- `feedback.reply_seen_at` (admin mesajının `seen_at`-ından ayrı).
- `rpc_student_feedback_mine(p_token, p_seen)` / `rpc_parent_feedback_mine`:
  öz yazıları + `note` (admin cavabı) + `fresh`. `p_seen=false` yalnız oxuyur
  (nişan üçün), `p_seen=true` «oxundu» yazır və `fresh` false qaytarır —
  yoxsa nişan öz-özünü söndürür / sönmür.
- `rpc_admin_feedback_set`: cavab yazılıb, status hələ «new»-dirsə özü «seen»
  olur; status əl ilə seçilibsə toxunulmur. Cavab **dəyişdirilsə**
  `reply_seen_at` sıfırlanır (təzə cavabdır).
- `rpc_admin_feedback`: `reply_seen_at` → panel «Cavabı oxudu · tarix» /
  «Cavab göndərildi — hələ açmayıb» (`.fbseen`, yalnız şagird/valideyn sətrində).
- Şagird və valideyn tətbiqi: `#fbMine` siyahısı + summary-də `.fbdot`
  «Bil10 cavab yazdı»; qutu `toggle` olanda `p_seen=true`.
- **Anon ağ siyahı 21 → 23** (`db/05_grants.sql` İKİ massiv, `smoke_huquq.sql`
  üç yerdə: §1 sayı, §6 təkrar işlətmə). `db/113` bərpa faylı yalnız 11 şagird/
  valideyn RPC-sini qaytarır, ona toxunulmadı.
- Testlər: `smoke_bize_yaz.sql` §9, `smoke_huquq.sql`, `e2e_bize.py` H2.
  Şəkil: `test/_v2_cavab.py`.
- **Dərs:** yeni kanal açanda hər iki istiqaməti (yaz + oxu) eyni anda qur.
- Düymənin adı (istifadəçi: «yadda saxlanıldı düz ad deyil, mesaja cavab
  göndərilirsə göndər olar da»): qutuda mətn varsa «Cavabı göndər», boşdursa
  «Yadda saxla» (orada yalnız status dəyişir); yazarkən `input` ilə dəyişir.
  İpucu `fbPh(r)`: şagird/valideyn üçün «tətbiqində görür», müəllim üçün
  «profilində görür». Uğur mesajı `.fbc[data-who]`-dan: «Cavab göndərildi —
  şagird tətbiqini açanda görəcək».

## db/209 — «Bu gün» kartı: müəllimin gündəlik bir dəqiqəsi (2026-09-18)

Hunidə görünən problem: müəllim qayıtmır, çünki hər dəfə özü qərar verməlidir
(nə göndərim, kimə?). İcmalda rəqəm lövhələri «neçə var» deyirdi, «indi nə et»
demirdi. İndi zolağın altında bir sətir + bir toxunuş.

- `rpc_home` → `bugun` (marker: `'paid', v_paid,`, db/200–201 kimi):
  `dunen`, `bu_gun` (neçə ŞAGİRD işlədi, cəhd sayı yox), `susan` (7 gündür
  heç nə etməyən aktiv şagird), `aktiv`, `verdim` (bu gün verilmiş tapşırıq).
  Təqvim günü `Asia/Baku`. Pulsuzda da gəlir; ən zəif mövzu isə `topics`-dəndir
  (db/201, yalnız abunəli).
- `rpc_quick_assign(class_id, topic_id, count)`: test yığır **və** tapşırıq
  kimi verir, bir çağırışda. Əvvəl üç addım idi: Test yığ → generator →
  tapşırıq forması. Daxildə `rpc_generate_test` + `rpc_assign_test`.
  Abunəsiz hesabda anlaşılan xəta (hazır bank abunə ilədir).
- Panel `buGunKart(v)` → `#hBugun`, `.card.bugun`. Şagirdsiz hesabda görünmür.
  Göndərəndən sonra düymə itir, yerinə «Göndərildi — mövzu · N sual · qrup»
  və «Vərəqə bax».
- Testlər: `smoke_bu_gun_kart.sql` (yoxla.sh siyahısına əlavə olundu),
  `e2e_panel` (şagirdsiz hesabda kart yoxdur). Şəkil: `test/_v2_bugun.py`.
- Canlıda: `db/209_gunluk_kart.sql`.

## db/210 — «Səhvini bağla»: mövzu-mövzu, yığcam paket (2026-09-18)

Səhv dəftərinin mexanikası (db/129) hazır idi: açıq → təkrar → bağlı,
aralarında bir həftə. Amma şagird ekranda bir rəqəm görürdü: «10 sual
gözləyir · Məşq et». Konkret hədəf yox idi.

- `rpc_student_mistakes(p_token, p_topic, p_limit)`: `topics` açarı
  (mövzu üzrə bu gün gözləyən sual sayı, ən çoxdan aza) + mövzu süzgəci.
  Köhnə tək parametrli imza **drop** edildi, yoxsa `smoke_huquq` anon
  sayını pozardı (overload).
- Şagird kartı: «Statistika. Ehtimal — 28 sual gözləyir» + «3 sual işlə».
  Düymə nə edəcəyini deyir; «Bağla (3)» çaşdırırdı (sətirdə 28, düymədə 3).
- Mövzu seçiləndə 3 sual gəlir. Hamısı düz olsa bitiş ekranı «<mövzu>
  təmizləndi ✅» deyir (`MQ.tname` + `bad === 0`).
- Üst zolaq dar olduğu üçün başlıq «Səhv dəftəri» qalır, mövzu adı ekranda.
- Testlər: `smoke_sehv_bagla.sql` (yoxla.sh siyahısına əlavə),
  `e2e_defter` 3 suallıq paketə uyğunlaşdırıldı. Şagird kartında
  «gözləyən» = `next_at <= now()`, müəllim sayğacı isə `open` sayır —
  səhv cavablanan sual sabaha keçdiyi üçün iki rəqəm fərqlidir.
- Canlıda: `db/210_sehvini_bagla.sql`.

## db/211 — Səhv dəftəri abunə paketinə keçdi (2026-09-18)

İstifadəçi qərarı: «abunəlikdə edək». Səbəb: uşaq hər gün girir, ləzzətini
görür; abunə bitəndə özü müəllimə deyir «bunları əvvəlki kimi necə işlədim?».

**Amma tam gizlədilmir** — uşaq nə itirdiyini görməlidir, yoxsa istəməz:
- sayğaclar və mövzu siyahısı pulsuzda da gəlir (neçə sual gözləyir),
- `items` boş qaytarılır, `rpc_student_mistake_answer` `42501` verir,
- `paid` bayrağı → şagird ekranında düymə əvəzinə kilid nişanı,
  «Səhvlərin mövzu-mövzu toplanır. Məşq müəlliminin abunəsi ilə açılır.»
  və «Səhvlərin itmir — abunə açılan kimi buradan davam edəcəksən.»
- Abunəli halda «Mövzunu seç…» mətni qalır; kilidli halda o cümlə YAZILMIR
  (seçmək olmurdusa, «seç» demək ziddiyyət idi).
- `mistake_answer` gövdəsi marker ilə genişləndi (`Sessiya bitib…` bloku).
- Testlər: `smoke_sehv_bagla.sql` §5, `e2e_defter` C2 (kilid, səbəb, abunə
  qayıdanda düymə geri gəlir).
- Canlıda: `db/211_sehv_abune.sql`.

## db/212 — «Bu günün 5 sualı»: şagirdin fərdi gündəlik təkrarı (2026-09-18)

Şagird tətbiqə həftədə bir-iki dəfə girirdi, çünki hər dəfə **özü** qərar
verməli idi: hansı mövzu, hansı test, neçə sual. Bu qərar yükü gündəlik
vərdişi öldürür. İndi qərar serverdədir: uşaq açır, hazır beş sual görür,
üç dəqiqədə bitirir.

Üç xarici AI-ın (GPT, Gemini, Perplexity) üçü də eyni şeyi dedi və yalnız
bunlar götürüldü: dəqiq 5 sual, bir düymə, mövzu/test seçimi YOX, seriya
və medal YOX, qaçırılan gün borc yaratmır, sessiya 5-də bitir («daha 20
sual» təklifi qəsdən yoxdur).

**Məcburi qayda (istifadəçi):** suallar YALNIZ keçilən dərslərdən olur.
Mənbə `class_plan_items.done_at`. Plan sətri **alt mövzudur**, suallar isə
**başlığa** bağlıdır (db/101) — ona görə `coalesce(parent_id, id)` ilə
valideyn mövzuya qalxırıq. Plan heç işarələnməyibsə **fallback**: uşağın
özünün testdə cavab verdiyi mövzular (cavab verdi = mövzu onsuz da
keçilib). Boş ekran göstərmək ən pis variantdır.

**Beş slotun sırası** (sabit, təsadüfi deyil) — hər biri boş qala bilər,
sonda hovuzdan doldurulur; 3 sualdan az yığılsa paket **qurulmur**:

| # | `src` | Nə |
|---|-------|-----|
| 1 | `bilirem` | keçilmiş mövzudan əvvəl DÜZ cavabladığı sual (ilk 20 saniyədə uğur) |
| 2 | `sehv` | ən köhnə, hələ bağlanmamış səhv (dəftərdən) |
| 3 | `eyni` | eyni bacarığın başqa sualı |
| 4 | `tekrar` | 5–60 gün əvvəl düz cavabladığı (aralıqlı təkrar) |
| 5 | `yeni` | müəllimin ən son «keçildi» etdiyi mövzudan |

- `public.daily_packs (student_id, day, items, answers, done_at)` — paket
  gün içində **sabitdir** (səhifə yenilənsə eyni suallar), gün dəyişəndə
  yenisi qurulur. Təqvim günü `Asia/Baku`.
- `rpc_student_daily(p_token)` — paketi qurur/qaytarır, cari sualı
  göndərir (düz variant getmir), `yesterday` (dünən N/M) və bitəndə
  `result` (mövzu-mövzu hesabat).
- `rpc_student_daily_answer(p_token, q, o)` — **yalnız növbəti** suala;
  sıra serverdədir. `app.mistake_note(..., p_practice := true)` çağırır.
- **Abunə:** paket 2-ci və 3-cü sualı səhv dəftərindən (db/211) götürür —
  pulsuz buraxsaq 211-in qapısı arxa qapıdan açılardı. Ona görə abunəsizdə
  paket **qurulmur** (sual sızmır), amma kart mövzu adlarını yazır və
  kilid göstərir.
- Sual hovuzu `kind = 'single'` — gündəlik dövrə bir toxunuşdur.

**Yol boyu düzəldilən köhnə səhv:** `app.mistake_note`-un INSERT qolu
`p_practice`-i nəzərə almırdı — ilk dəfə səhv edilən sual `next_at = now()`
ilə düşürdü, halbuki UPDATE qolu «sabaha» qoyurdu. İnterfeys «sabah yenə
gələcək» yazdığı üçün iki qol arasındakı ziddiyyət aradan qaldırıldı.

- Testlər: `db/test/smoke_gunluk_5.sql` (10 bölmə, yoxla.sh siyahısında),
  `test/e2e_gunluk.py` (run_e2e.sh-də).
- Anon siyahısı **23 → 25** (`db/05_grants.sql` iki massivdə,
  `smoke_huquq.sql` üç yerdə).
- Canlıda: `db/212_gunluk_5_sual.sql`.

## db/213 — Gündəlik təkrarın iki dayağı (2026-09-18)

db/212 quruldu, amma onun **hər iki ucu** boş idi.

**1. Müəllim asılılığı** (bu riski üç AI-dan yalnız Gemini gördü). Suallar
yalnız «keçildi» işarələnən dərslərdən gəlir; müəllim planı işarələmirsə
uşağa heç nə çatmır və bunu heç kim bilmir. «Bu gün» kartına bir sətir:
«N şagirdə gündəlik təkrar hazırlana bilmir — keçdiyiniz dərsi «Keçildi»
işarələyin» + birbaşa həmin qrupun dərs planına keçid.
`rpc_home` → `tekrar_plansiz`, `tekrar_qrup`, `tekrar_hazir`
(marker: `'bugun', (`). «Plansız» yalnız **planı olan, amma heç nə
işarələnməyən** qruplardır — planı olmayana «işarələ» demək mənasızdır.

**2. Ölçü** (Perplexity-nin metrikası). `rpc_admin_huni` → `tekrar`
(marker: `'days',       p_days,`):
- **D2 qayıtma** — ilk paketi bitirənin 48 saat içində ikinciyə qayıtması.
  Hədəf ≥40%, <25% olsa «fərdi repetitor» yox, «əlavə test» kimi qəbul
  olunur. Bu, vərdişin yaranıb-yaranmadığını deyən yeganə rəqəmdir.
- **Bitirmə faizi** — başlanan paketlərin neçə faizi sona çatır. <75%
  olsa problem qayıtmadan ƏVVƏL başlayır (suallar çətin, ekran uzun).
- Nümunə hesab sayılmır (paketləri hər gecə sıfırlanır).

Hər ikisi mövcud funksiyalara marker ilə əlavə olundu — yeni RPC yoxdur,
anon siyahısı dəyişmir.

- Testlər: `smoke_gunluk_5.sql` §9–10, `e2e_gunluk.py` B3.
- Canlıda: `db/213_tekrar_itelemesi.sql`.

## Qeydiyyat: e-poçt yazı səhvi ipucu (2026-09-19)

Huniyə baxanda «97 ziyarətçi → 4 qeydiyyat» göründü və ilk fikir
«məktublar çatmır» oldu. **Yanlış idi.** `auth.users`-ə baxdıq:
təsdiqləyənlərin hamısı **0–2 dəqiqə** içində təsdiqləyib — məktub
dərhal gəlir.

Əsl səbəb başqa idi. 30 günlük 16 qeydiyyatın üçündə **ünvan səhv
yazılmışdı**:

| Yazılan | Nə olub |
|---|---|
| `...@ge**mail**.com` | domen səhvi — məktub heç vaxt çata bilməzdi |
| `...@ga**mil**.com` | domen səhvi; iki gün sonra düzünü yazıb girib |
| `huseynovasekin**12937**@` | rəqəm səhvi; 9 dəqiqə sonra düzünü yazıb girib |

Üstəlik təsdiqlənməyən 9 sətrin yarısı **ayrı adam deyil** — eyni
adamların təkrar cəhdləridir (Teranə üç dəfə qeydiyyatdan keçib).
Gerçək itirilən adam sayı 4-5-dir.

**Həll: forma mane olmur, yalnız soruşur.** Domen tanınmış siyahıdan
2 hərfdən az fərqlənirsə: «Bunu nəzərdə tuturdunuz? ...@gmail.com» —
bir toxunuşla düzəlir. Qərar istifadəçinindir; iş domeni ola bilər,
biz bilmirik.

- `MAIL_OK` — tanınmış domenlər (gmail, mail.ru, inbox.ru, hotmail,
  box.az, edu.az …). `lev()` — Levenshtein, kitabxanasız.
- Həddlər: 0 fərq → susur · >2 fərq → susur (başqa domendir) ·
  2 fərq + qısa domen → susur (yalan xəbərdarlıq olmasın).
- Enter ilə birbaşa göndərəndə `blur` baş vermir, ipucu heç görünmürdü —
  ona görə şübhə varsa **bir dəfə** saxlayır; ikinci toxunuşda göndərilir.
- Test: `test/e2e_mail_sehvi.py` — 5 bölmə. C bölməsi vacibdir: düz
  ünvan, iş domeni, universitet domeni, protonmail, box.az — hamısında
  ipucu **çıxmamalıdır**.

**Həmçinin (ölçüdən çıxan nəticə):** «Confirm email» db/202 ilə artıq
söndürülüb (17.09). Təsdiqlənməyən 9 hesabın hamısı ondan ƏVVƏLdir və
onlar **bu gün öz parolları ilə daxil ola bilərlər** — sadəcə bilmirlər.
Etibarlı ünvanı olanlara əl ilə məktub yazmaq lazımdır.

**Dərs:** rəqəmə baxıb səbəb uydurma. «Məktub çatmır» ağlabatan idi,
amma `email_confirmed_at - created_at` fərqi bir baxışda onu təkzib etdi.
Əvvəl məlumata bax, sonra düzəlt.

## İdarəetmə — «Dayandır» mesaj qutusunun yanında idi (2026-09-19)

İstifadəçi telefondan müəllimə mesaj yazarkən gördü: **«Dayandır»**
düyməsi mesaj qutusunun **düz üstündə** idi. O düymə abunəni kəsir —
səhvən vurulsa müəllim pullu imkanlarını itirir. Üstəlik qutuda **kimə
yazıldığı heç yerdə görünmürdü**: telefonda sətir başlığı yuxarıda qalır,
adam kimə yazdığını görmür.

Üç düzəliş (yalnız `muellim/app.js` + `app.css`):

1. **«Dayandır» mesajın altına keçdi və `<details>` içindədir** —
   «Təhlükəli əməliyyat» sətrini qəsdən açmaq lazımdır. Açılanda düymə
   qırmızıdır və bütün eni tutur, yəni nə etdiyi aydındır.
2. **Mesaj qutusunun üstündə alıcının adı yazılır** («Teranə riyazzyat —
   mesaj»).
3. **Təsdiq pəncərəsində ad + e-poçt + nəticə** yazılır: «Abunəni
   DAYANDIRMAQ? Müəllim pullu imkanları itirəcək.» Əvvəl yalnız e-poçt
   var idi — oxşar ünvanlarda çaşdırıcı.

Abunə düymələri (+1 ay · +6 ay · Sınaq 1 ay) öz sətrində qaldı.

- Test: `e2e_paket.py` §F — «Dayandır» **görünmür** (qapalı bölmədədir),
  «Təhlükəli əməliyyat» bölməsi var, qutuda alıcının adı yazılır.
  `menu_bas()` köməkçisi artıq sətirdəki **bütün** `<details>`-ləri açır.

**Dərs:** dağıdıcı əməliyyat ilə gündəlik əməliyyat bir-birinə yapışıq
dura bilməz. Masaüstündə fərq görünmürdü, telefonda hər şey bir sütuna
düzülür və «Dayandır» mətn qutusuna toxunur.

## 216 — Səhv dəftəri: «Mövzunu seç» yazırdı, seçiləcək mövzu yox idi (2026-09-18)

İstifadəçi (canlı ekran): kartda «17 sual gözləyir» yazırdı, mətn «Mövzunu
seç — …» deyirdi, amma **aşağıda heç bir mövzu sətri yox idi**. Şagird
üçün bu, iki dəfə pisdir: mətn olmayan bir şeyi vəd edir, və **heç bir
düymə olmadığı üçün uşaq ilişib qalır** — dəftərdəki 17 sualı işləyə
bilmir.

Səbəb interfeysdə idi: mətn `due > 0` şərti ilə yazılırdı, mövzu sətirləri
isə `topics` massivindən gəlirdi — ikisi bir-birindən asılı deyildi.
`topics` boş qala bilər (məsələn sualların `status` sütunu `published`
deyilsə; `due` isə `mistakes` cədvəlini heç bir join olmadan sayır).

Üç düzəliş (yalnız `sagird/app.js`, SQL dəyişmir):
1. «Mövzunu seç» **yalnız** `tps.length > 0` olanda yazılır; əks halda
   «Səhvlərin burada toplanıb. Bir neçəsini indi işlə.»
2. Mövzu sətri yoxdursa **ümumi «N sual işlə» düyməsi** çıxır
   (`data-mt=""` → `p_topic = null`) — şagird ilişib qalmır.
3. Server hələ **köhnə tək parametrli imzada** ola bilər (db/210
   işlədilməyibsə). O halda üç parametrli çağırış PostgREST-dən
   «funksiya tapılmadı» alır; indi `catch` onu tutub köhnə çağırışa
   qayıdır. Mövzu süzgəci olmur, məşq isə işləyir.

- Test: `test/e2e_defter_bos.py` — A: mövzu sətri boş (suallar `draft`),
  mətn «Mövzunu seç» **demir**, düymə var · B: köhnə imza qurulur, geriyə
  qayıdış işləyir və məşq açılır.
- **Diaqnostika** (canlıda `topics` niyə boşdur): `rpc_student_mistakes`-in
  imzasına bax — `(text)` qalıbsa db/210 + db/211 işlədilməyib;
  `(text, uuid, integer)`-dirsə səbəb sualların `status`-udur.

**Dərs:** eyni kartda mətn və siyahı ayrı-ayrı şərtdən gəlirsə, gec-tez
bir-birini təkzib edirlər. Bu, üçüncü dəfədir (əvvəl «Bağla (3)», sonra
abunəsiz haldakı «Mövzunu seç»). Mətni **göstərilən şeydən** törət.

## db/215 — «Bu gün · girən müəllim» sayğacı yanlış idi (2026-09-18)

İstifadəçi: «Teranə bu gün giriş edib, amma yuxarıda 0 göstərir». Doğru
idi — eyni ekranda iki rəqəm bir-birini təkzib edirdi:

| Yer | Nə deyirdi |
|---|---|
| Hesablar cədvəli | «son giriş — **bu gün 12:54**» ✓ |
| «Bu gün» lövhəsi | «**0** girən müəllim» ✗ |

**Səbəb.** `seen_today` yalnız `auth.users.last_sign_in_at`-ə baxırdı.
Supabase onu **ancaq parolla girişdə** yeniləyir. Müəllimin sessiyası
diridirsə (refresh token), o hər gün paneli açır, amma parol yazmır —
deməli `last_sign_in_at` köhnə tarixdə qalır. Nəticə: sayğac demək olar
həmişə 0 göstərirdi və «heç kim girmir» kimi yalan mənzərə verirdi.

Doğru mənbə `profiles.last_seen_at`-dir — paneli açanda `rpc_seen()` onu
yazır (db/206-dan sonra hər 2 dəqiqədə). Hesablar cədvəli (125/138/174)
**onsuz da** ikisinin böyüyünü götürürdü, `seen_week` də (db/175) hər iki
mənbəyə baxırdı. Yaddan çıxan **tək yer `seen_today`** idi.

**Yol boyu buraxdığım səhv — və onu tutan şey.** İlk düzəlişdə iki mənbəni
mötərizəyə almadım. SQL-də `AND` `OR`-dan güclü bağlayır, ona görə sondakı
`or` yuxarıdakı «nümunə deyil / admin deyil» şərtlərini qırdı və **adminin
öz hesabı sayılmağa başladı**. Bunu `smoke_admin_giris.sql` §5 tutdu
(db/175-in öz testi). Dərs: `and ... or ...` yazanda mötərizə məcburidir;
`seen_week` onu düz etmişdi, mən oradan köçürmədim.

- Test: `db/test/smoke_giren_saygaci.sql` — 3 bölmə: diri sessiya ilə girən
  sayılır · lövhə və cədvəl **eyni rəqəmi** deyir (ziddiyyət qayıtmasın) ·
  dünənki giriş bu günə yox, həftəyə sayılır. Fiksturda admin bu gün
  **parolla da** girir — mötərizə sızması bir də gizlənməsin.
- Marker ilə tətbiq olunur; qoruyucu nişan `215b: IKI MENBE MOTERIZEDE`
  (səhv nüsxə də köhnə nişanı daşıyırdı, ona görə nişan dəyişdirildi).
- Canlıda: `db/215_giren_muellim_saygaci.sql`.
