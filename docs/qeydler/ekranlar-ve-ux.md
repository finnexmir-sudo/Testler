# Qeydlər: Ekranlar və UX: valideyn/şagird/nəticə ekranları, geri düyməsi, hesabat sekmələri, kartlar, qrup ekranları

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## Valideyn girişi

Müəllim şagirdi əlavə edəndə valideyn girişi **YOXDUR**. Müəllim onu
qələmin altından (redaktə vərəqi) **özü açır** — və istədiyi vaxt
bağlayır. Susmaya görə bağlıdır, çünki bəzi müəllimlər işinin
şəffaflaşmasından narahat olur; məcburi etsək müəllimi itiririk.

```
students.parent_code   NULL = bağlı.  Kod «V» ilə başlayır - şagird
                       kodundan gözlə seçilsin deyə
parent_sessions        AYRI cədvəl, 30 gün
valideyn/              üçüncü tətbiq (muellim/, sagird/ ilə yanaşı)
```

**Niyə ayrı sessiya cədvəli.** Valideyn tokeni heç vaxt şagird
RPC-lərində işləməməlidir — əks halda valideyn kodu şagird koduna
çevrilir və uşağın adından test yazıla bilər. `student_sessions`-a
«rol» sütunu əlavə etmək bu səhvi bir gün mütləq yaradardı.

**Valideyn NƏ GÖRMÜR** (`rpc_parent_home` onları qaytarmır):
uşağın öz giriş kodu · tam adı (yalnız `display_name`) · düz cavablar ·
başqa uşaqların adları və balları · reytinq · qrupla müqayisə ·
müəllimin əlaqə məlumatı.

**Ekran bir səhifədir, naviqasiya yoxdur** — valideyn telefonda 40
saniyə baxır. Vəziyyət çılpaq faizlə deyil, **meyllə** verilir («keçən
aya görə 8 % yaxşılaşıb»): 64 % rəqəmi valideynə heç nə demir.

Bağlayanda açıq sessiyalar **dərhal ölür** — «bağladım, amma hələ də
baxır» olmamalıdır. `db/107_valideyn.sql`, `db/test/smoke_valideyn.sql`
(12 yoxlama, əsasən təhlükəsizlik iddiasıdır).

## Şagirdin öz ekranı — 4 yeni sahə

Əvvəl şagird öz ekranında YALNIZ tapşırıqları/sərbəst məşqi görürdü —
«necə gedirəm», «nə vaxt nə keçdik», «harada zəifəm» yalnız müəllim və
valideyn tərəfində idi. `db/114_sagird_paneli_zenginlesdirme.sql`
`rpc_student_tests`-ə 4 sahə əlavə etdi:

- **`best`** — ən yüksək faiz, bütün cəhdlər üzrə.
- **`streak`** — neçə gündür ARDICIL test yazır. Bu gün/dünən heç nə
  yazılmayıbsa zəncir qırılıb sayılır, `0` qayıdır — «3 gündür
  ardıcılsan» yalan motivasiya olmasın.
- **`next_lesson`** — dərs planından ilk bitirilməmiş mövzu (müəllim
  ekranındakı «NÖVBƏTİ DƏRS» kartı ilə eyni məntiq).
- **`weak`** — zəif mövzular (<60 %, ən azı 3 cavab).

**`weak` ABUNƏ TƏLƏB ETMİR** — bu, valideyn ekranındakı eyni sorğudan
(`107_valideyn.sql`) fərqlidir, orda abunə (müəllimin satdığı analitika)
şərtdir. Burda isə şagirdin öz zəifliyini bilməsi təhsil məzmunudur,
satılan analitika deyil. Qərar istifadəçi ilə açıq razılaşdırılıb —
başqa yerdə təkrarlanacaqsa bu fərqi qorumaq lazımdır.

**Tələ:** `rpc_student_tests`-i override edəndə 03-dəki İLK versiyadan
DEYİL, ən son override-dan (`28_ferdi_tapsiriq.sql`) başlamaq lazımdır.
Bunu bir dəfə səhv etdim — 03-dən köçürüb ferdi təyinat düzəlişini
(`personal` sahəsi, `a.student_id` filtri) öz-özünə geri qaytardım,
`smoke_ferdi.sql` bunu dərhal tutdu. Bir funksiyanı override edəndə
`grep -ln "create or replace function public.FUNKSIYA_ADI" *.sql` ilə
ƏVVƏLKİ BÜTÜN override-ları tap, ən sonuncunu əsas götür.

`db/115_sagird_kecdiyi_dersler.sql` beşinci sahəni əlavə etdi:
**`lessons`** — son 5 keçilmiş mövzu, tarixlə (valideyn ekranındakı
eyni sorğu). «Növbəti dərs» hara gedirik deyir, bu hardan gəldik.

## Nəticə ekranı — bütün suallar, düz cavab yox

Əvvəl şagird test bitirəndə yalnız SƏHV suallar görünürdü (sual mətni
+ izah), öz seçdiyi cavab heç göstərilmirdi. İstifadəçi soruşdu: «testi
tam görməyin faydası olarmı?» — bəli, amma sərt sərhədlə:
**`question_options.is_correct` heç vaxt qayıtmır** — Bil10 sual bankı
satır, düz cavab şagirdə çıxsa screenshot alınıb paylaşıla bilər.

`db/116_sagird_tam_netice.sql` (`rpc_test_result` — baxış rejimi) və
`db/117_sagird_tam_netice_submit.sql` (`rpc_submit_attempt` — təzə
bitirmə) `'wrong'` sahəsini `'questions'`-la əvəz etdi: BÜTÜN suallar
(düz + səhv), hər birində şagirdin **öz seçdiyi cavabın mətni**
(`picked` — mətn tipli sualda `text_answer`-dən, seçim tipində
`selected_option_ids`-dən) və `correct` boolean (hansı variantın düz
olduğu yox, sadəcə bəli/xeyr). Frontend: `.right`/`.wrong` sinifləri,
yaşıl/qırmızı `qmark`.

**Tələ (iki yerdə eyni RPC):** nəticə ekranı İKİ mənbədən qurulur —
təzəcə bitirəndə `rpc_submit_attempt`-in cavabından, təkrar baxanda
`rpc_test_result`-dan. Yalnız birini yeniləyib o birini unutmaq olar —
məhz bunu etdim, vizual yoxlamada "Suallar" bölməsi boş göründü (təzə
bitirmə hələ köhnə `'wrong'` qaytarırdı). `grep -ln "rpc_submit_attempt\|rpc_test_result" *.sql`
ilə hər ikisini tap, ikisini də yenilə.

**Tələ (variantlar qarışdırılır):** `tests.shuffle_options` susmaya
görə **doğrudur** — e2e testdə "həmişə birinci variantı klik et" ilə
"hamısı səhv olacaq" fərz etmək YANLIŞDIR, hansı variantın birinci
göründüyü hər cəhddə dəyişir. `test/e2e_student.py`-də bunu bir dəfə
səhv etdim (`.right` sayı == 0 gözlədim, təsadüfən 1 düz çıxdı, test
uğursuz oldu) — düzəliş: `.wrong.count() + .right.count() == cəmi sual`
kimi şuffle-dan asılı olmayan yoxlama yaz.

## Şagird tətbiqi — brauzerin «geri» düyməsi

`sagird/` tək səhifəli tətbiqdir, ekranlar `show()` ilə DOM-da dəyişir,
URL dəyişmir. Ona görə brauzer tarixində heç bir pillə yox idi — nəticə
ekranında «geri» basanda birbaşa tətbiqdən ƏVVƏLKİ səhifəyə (landing)
çıxırdı. İstifadəçi: «səhifələrdə geri mütləq olmalıdır».

Həll (`sagird/app.js`, `markScreen` + `popstate`): ev ekranından
(Testlər) uzaqlaşanda **bir dəfəlik** `history.pushState` qurulur
(`ON_HOME` bayrağı ilə idempotent — neçə ekran keçsən də bir pillə).
«Geri» o pilləni sındırır, `popstate` Testlərə qaytarır. Ev ekranından
ikinci «geri» əvvəlki kimi tətbiqdən çıxır (kökdür, normaldır).
Test ortasında «geri» `btnOut` ilə eyni «yarımçıq test» `confirm`-ini
verir; ləğv edəndə `pushState` yenidən çağırılır — «geri» geri alınır.

- Üst zolaqda **görünən «‹ Geri» düyməsi** (`#btnBack`) də var — brauzer
  oxu düzələndən sonra istifadəçi «hanı geri düyməsi?» dedi: ox deyil,
  səhifədə düymə gözləyirdi. `markScreen` onu göstərir/gizlədir (ev
  ekranında gizli), kliki `history.back()` çağırır — brauzer oxu ilə
  eyni `popstate` yolu, iki ayrı kod yolu yoxdur.
- Yeni ekran əlavə edəndə funksiyanın başına `markScreen(false)` yaz
  (ev/giriş ekranı isə `markScreen(true)`). Unudulsa o ekrandan «geri»
  yenə tətbiqdən çıxarar və «Geri» düyməsi görünməz.
- Dərin naviqasiya yığını (ekran-ekran geri) qəsdən qurulmayıb: kiçik
  tətbiqdə «geri həmişə Testlərə» proqnozlaşdırılandır, testi də sadədir.
- `muellim/` hash marşrutu (`#/g/<id>`) işlədir — orda «geri» onsuz da
  işləyir. `valideyn/` tək ekrandır — «geri» landing-ə çıxması düzgündür.
- e2e: `test/e2e_student.py` «G3» bölməsi fiziki `go_back()` yoxlayır.

## UX yoxlaması — qaydalar (2026-09-04)

Tam gəziş (27 ekran, telefon + masaüstü) bunları çıxardı; hamısı
düzəldilib. Yeni ekran yazanda eyni tələlərə düşmə:

- **Boş hal xəta deyil.** Yeni müəllimin öz sualı yoxdur: generator
  «0 sual tapıldı» qırmızısı əvəzinə sarı yol göstərir, bank «Öz
  suallarım» boşdursa Platforma ilə açılır (`f.auto`), İcmalda qrup
  yoxdursa «Qrup yarat» formu başlığın altına qalxır, rəqəm kartları
  gizlənir (`#hTop`, `#gForm.first`).
- **Bildiyimizi soruşma.** Profildə fənn təkdirsə generatorda seçili
  gəlir; bütün qruplar eyni sinifdirsə sinif də (`genInit`). Tapşırıq
  siyahısında müəllimin fənni birinci (`subjectNames()`).
- **Eyni siyahı iki dəfə göstərilmir.** Diaqnostika xəritəsi və
  «Mövzu üzrə mənimsəmə» yalnız zəif/orta sətirləri açıq göstərir,
  yaxşılar `<details>` altında; «Zəif mövzulardan test yığ» bir dənədir
  (`#btnRem`, `#dgRem` yoxdur). «Son nəticələr» yalnız İcmalda.
  Telefonda «Sürətli əməliyyatlar» gizlidir — alt menyu eyni üç düyməni
  daşıyır (`.quick`). Şagird tətbiqində «Geri» yalnız üst zolaqdadır.
- **İzah bir cümlə.** Formada boz izahlar birləşdirilib; «Dərs planı»
  plan yoxdursa bir sətir + «Planı qur» (`#btnPlOpen` → `#plForm`).
- **Nadir əməliyyat qələmin altında.** «Dayandır» şagird sətrində
  deyil, redaktə panelindədir (kod yeniləmək kimi).
- **Ad doğru olsun.** «Səhv edilən suallar» (say yalnız 2×-dan
  yuxarı görünür); «öz testiniz» diaqnostikanı saymır (`db/120`);
  «Dinamika» 3 testdən başlayır; işlənmiş testdə «son tarix» yazılmır.

Yoxlama skripti: `test/beledci_sekil.py` bələdçi şəkilləri üçündür;
tam UX gəzişi üçün onun genişi bu sessiyanın scratchpad-ında idi
(`audit.py`) — lazım olsa eyni axınla yenidən yazılır: hər ekran 390 və
1280 px, `innerText` uzunluğu, `.muted` uzunluğu, səhifə hündürlüyü.

## Böyüyən siyahılar — hədd qaydası

İl boyu böyüyən hər siyahının həddi var: ilk N açıq, qalanı «Daha N …»
düyməsi (`.morebtn`, sətirlər `.hide` ilə). Yerlər: müəllim — hesabat
sekmeləri (8), tarixçə (8), «Bağlı» tapşırıqlar (8, `AEXP`); şagird —
sərbəst məşq fənn çipləri + 12 (`PSUB/PEXP`), işlənmiş tapşırıqlar
«İşlənmiş (N)» altında (3-dən çoxdursa yığılmış, `#doneBox`), Nəticələrim
10, nəticədə düz cavablar «Düz cavablar (N)» altında (səhv yoxdursa
hamısı açıq). Yeni siyahı əlavə edəndə eyni qaydanı tətbiq et. Testlərdə
gizli sətrə klik olmaz — əvvəl «Daha N» və ya details aç.

## Qrup ekranı — iki sekme

`drawGroup`: **Şagirdlər N / Dərs planı** (`#gTabs`, `GTAB` sessionStorage-da
qalır — səhifə yenilənəndə də). «Yeni şagird» forması `#stuForm` gizlidir,
`#btnStuOpen` ilə açılır; şagird yoxdursa `loadStudents` avtomatik açır.
Testlərdə: qrup ekranı üçün `#gTabs` gözlə (köhnə `#btnStu` gizlidir),
`#sname` doldurmazdan əvvəl `#btnStuOpen` görünürsə klik et; plan üçün
`#gTabs [data-v='p']` klik et (bir dəfə bəsdir, reload-da qalır).

## Qrup hesabatı — üç sekme

`screenReport`: **Şagirdlər / Mövzular / Fəaliyyət** (`#rTabs`, `RTAB`).
Mövzularda fənn çipləri (`#rSub`), zəifdən yaxşıya, ilk 8 + «Daha N»,
≥80% yığılmış, `#btnRem` bu sekmədədir; Fəaliyyət ilk 8 + «Daha N».
Testdə `#btnRem`-dən əvvəl `#rTabs [data-v='m']` klik et.

## Şagird hesabatı — dörd sekme

`screenStudent` (muellim/app.js) hesabatı **Xülasə / Mövzular / Səhvlər /
Tarixçə** sekmələrində göstərir (`#sTabs`, `.stab`). Səbəb: bir uzun
səhifə 8 testlə 4000px idi, səhvlər və mövzular çoxaldıqca hara gedəcəyi
bilinmirdi. Seçilmiş sekme `STAB` dəyişənində sessiya boyu qalır —
müəllim A şagirddən B-yə keçəndə eyni sekmədə qalır. Testlərdə bunu
nəzərə al: gizli sekmədəki element `wait_for_selector`-a görünmür,
əvvəl `#sTabs [data-v='m']` klik et; `#dgGo`/`#vTxt` Xülasədə, `#btnRem`
Mövzularda, `#btnFix`/`.wrongbox` Səhvlərdə, `.atr`/`.dyn` Tarixçədədir.

Mövzular: fənn çipləri (`#tSub`, müəllimin tək fənni seçili gəlir),
zəifdən yaxşıya, ilk 8 sətir + «Daha N», ≥80% olanlar «Yaxşı mövzular»
altında. Səhvlər: server ən çox səhv edilən 10 sualı verir (27_hesabat),
ilk 5 açıq + «Daha N»; düymə siyahının üstündədir.

## Xırdalar (yol xəritəsi 20e, 20g)

- 10-dan çox aktiv şagirddə qrup siyahısının üstündə «Şagird axtar…»
  (`#stuQ`, client-side, sətir `.hide`).
- Test vərəqində «Yığcam» çap: `#printBox.compact` (11px, variantlar bir
  sətirdə) — 30 sual 2 səhifəyə.
- Lövhə: 6 nəfərdən az yazıbsa sıralama yoxdur, yalnız öz nəticəsi
  (`few`); e2e_student tək nəticə ilə keçir.
- İcmalda 4 lövhə yalnız 2+ qrupda görünür (`#hTiles.hide`).
- Valideyn mətnində Səmimi/Rəsmi seçimi çıxarıldı — tək (səmimi) mətn,
  `velText("isti")`; «resmi» şablonu kodda qalır.

## Fərdi plan (db/131, yol xəritəsi 18c)

`student_plans(student_id, subject_id unique, level_id, attempt_id)`,
`student_plan_items(plan_id, topic_id unique, ord, kind weak|mid,
done_at, test_id)`; RLS bağlı. `rpc_student_plan_make(student, subject)`:
son diaqnostikanın `app.diag_map`-indən zəif+orta fəsillər kurikulum
`sort` sırası ilə (3–6 sətir); yenidən qurulanda «ok» olan çıxır,
keçilmiş sətrin `done_at`-ı qalır. `rpc_student_plan_get`,
`rpc_student_plan_done(item, done)`, `rpc_student_plan_test(item, count)`
(fəsildən test → `rpc_assign_test` fərdi, 7 gün, ad «Fəsil — Ad»).
Abunə: plan qurmaq paid; hamısı `app.can_read_student`.
Panel: `drawDiag` sonunda `#splanBox` → `loadSPlan`: plan yoxdursa və
diaqnostika varsa «Fərdi plan qur (N mövzu)»; varsa sətirlər (№/✓,
fəsil, zəif/orta, test linki + %), «Keçildi/Geri», «Test ver»;
diaqnostika plandan yenidirsə «Yenilə». Valideyn: `plan {done,total}` →
«Fərdi plan: 2 / 5 mövzu keçilib». Testlər: `smoke_ferdi_plan.sql` (4),
`test/e2e_ferdi_plan.py`.

## Dəftər: davamiyyət və ödəniş (db/130, yol xəritəsi 21.4)

`lessons(class_id, held_on unique)`, `attendance(lesson_id, student_id,
present)`, `fee_payments(student_id, month, paid, amount_minor, note)` —
`payments` adı abunə sistemində məşğuldur, ona görə `fee_payments`.
RLS bağlı; RPC: `rpc_lesson_mark(class, date, present[], absent[])`
(upsert; yad şagird rədd; gələcək tarix rədd), `rpc_lesson_delete`,
`rpc_payment_set(student, month, paid, amount, note)` (məbləğ və qeyd
toggle-da itmir), `rpc_ledger_get(class, month)` → ay: dərslər, bu günün
vərəqi, şagird başına iştirak/ödəniş. Hamısı `app.plan_class` ilə
qorunur, abunə qapısı yoxdur (yapışqan, pulsuz).
Panel: qrup ekranında üçüncü sekmə «Dəftər» (`GTAB='d'`, `loadLedger`,
`LED_M` ay, `LED_EDIT` vərəq açıq): «Dərs oldu» → ad çipləri (hamı
seçili, toxunub söndür) → «Yadda saxla»; şagird sətrində «5/6 dərs» və
ödəniş düyməsi (toggle); «Dərslər» yığılmış siyahı, sil.
Valideyn: `rpc_parent_home.attendance` {lessons, attended, paid|null} →
«Davamiyyət · ay» kartı (ödəniş yalnız qeyd varsa).
Testlər: `smoke_davamiyyet.sql` (4), `test/e2e_davamiyyet.py`; bələdçi
addım 9 (`m12_defter.png`), valideyn addım 2.

## İrəliləyiş kartı (yol xəritəsi 21.3) və Səhv dəftəri (db/129, 21.5)

**İrəliləyiş kartı** — SQL yoxdur. Şagird hesabatı Xülasə, 2+ cəhddə:
`progData(r)` (ad, dövr: son 30 gün/bütün dövr, test sayı, əvvəl→indi
= ilk 3 / son 3 orta (4+ test) yoxsa ilk/son, ən yaxşı, güclü mövzular
≥80% (≥2 cavab), müəllim adı) → `drawProgCard(canvas)` 1080×1350
(brand→teal gradient, ad, «52% → 78%», kart: orta/ən yaxşı/dəyişmə,
güclü mövzular, «Müəllim: …»). «Paylaş» = `navigator.share({files})`
(Android Chrome), yoxsa «Şəkli yüklə» (`toDataURL` → `<a download>`).
Şəbəkə sorğusu yoxdur.

**Səhv dəftəri** — `public.mistakes(student_id, question_id, status
open/review/closed, wrong_n, next_at, cleared_at)`, RLS bağlı.
`app.mistake_note(student, question, ok, practice)`: səhv → open
(məşqdə next_at +1 gün — variantları bir-bir yoxlamaqla tapmasın);
düz → open isə review (+`app.review_days()`=7), review və vaxtı çatıbsa
closed. Trigger `attempt_answers` üzərində (test cavabları da dəftəri
yeniləyir); 129 mövcud səhvləri bir dəfəlik doldurur (son cavabı səhv
olanlar). RPC: `rpc_student_mistakes(token)` (sayğaclar + 10 gözləyən
sual, **düz variant getmir**), `rpc_student_mistake_answer(token, q, o)`
→ düz/səhv + izah + status; gözləməyən sual rədd. Anon ağ siyahı 15 RPC.
Şagird ev ekranında «Səhv dəftəri» kartı → məşq ekranı (bir-bir, dərhal
rəy). Müəllim: Səhvlər sekməsində sayğaclar (`r.mistakes`).
Testlər: `smoke_sehv_defteri.sql` (4), `smoke_huquq` 15, `test/e2e_defter.py`.

## Cavab tərzi və «Nə etməli» sətri (db/128, yol xəritəsi 22c və 20d)

`attempt_answers.seconds` (sualda keçirilən saniyə) və `sure` («əminəm»
true / «əmin deyiləm» false). Şagird tətbiqi hər cavabla `s` və `c`
göndərir (`tick()` sual ekranda olduğu müddəti yığır, geri qayıdanda
üstünə gəlir; qaralamada da saxlanır). Köhnə tətbiq göndərməsə null.
Hədd `app.hasty_sec()` = 5.

- Şagird hesabatı Xülasə: «Cavab tərzi» kartı (`r.style`: hasty,
  guess_ok, sure_wrong; yalnız `n_meta > 0` olanda). Səhvlər sekməsində
  «tələsik» / «əmin idi» nişanları (`weak[].hasty`, `sure_wrong`).
- Qrup hesabatı: `topics[].weak_students` (hər şagird ≥ min cavab,
  < 60%). Üstdə «Nə etməli» kartı: ən çox şagirdin zəif olduğu mövzu,
  adbaad linklər, «Bu mövzudan test yığ» → `remedialGen`.
- Şagird tətbiqi: variantlı sualda «Əmin deyiləm» düyməsi (susmaya
  görə əmin). Bala təsir etmir.
Testlər: `smoke_cavab_terzi.sql` (3), `test/e2e_inam.py`.

## Çaşdıran yerlər — bir dəfəyə (yol xəritəsi 20a, 20f)

- **Ad sırası (db/127).** `app.name_parts`: ilk söz soyad şəkilçisi ilə
  bitirsə (-ov/-ova/-yev/-yeva/-li/-lı/-zadə/-oğlu/-qızı…) və ikinci
  bitmirsə, ikinci söz addır → «Hüseynov Mirhüseyn» → «Mirhüseyn H.».
  127 köhnə qaydayla yaranmış qısa adları bir dəfəlik düzəldir (əl ilə
  verilənə toxunmur). Paneldə eyni qayda `firstName()` (valideyn mətni,
  WhatsApp). Şagird formasının ipucu «Əvvəl ad, sonra soyad».
- **«Platforma» → «Hazır bank»** müəllim tərəfində hər yerdə (hovuz
  seqmenti, tapşırıq optgroup, vərəq/bank meta, abunə xəbərdarlığı).
  Kodda `pool: "platform"` və admin bildirişindəki «platforma» qalır.
  Testlər: e2e_bank, e2e_gen «Hazır bank» axtarır.
- **«Bildirişlər» iki mənada idi:** zəng = «Siqnallar» (ekran başlığı,
  düymə, FB_PAGE), admin bölməsi = «Sual bildirişləri».
- **Tapşırıq ekranı:** «Hansı test nə vaxt?» yığılmış izah (hazır/öz test,
  ev tapşırığı, diaqnostik, səhvlərdən təkrar); «Sərbəst məşq» açarında
  «bağlasanız yalnız verdiyiniz tapşırıqları görər»; «götür» düyməsinin
  ipucu və Bağlı boş-halı «nəticələr qalır».

## Tapşırıq ekranında test seçimi (canlı şikayət: «qarışıq»)

`loadPick` (`muellim/app.js`). `<select id="aTest">` GİZLİDİR (`.hide`),
bütün testləri saxlayır — dəyər və testlər üçün. Görünən seçim `#aList`
sətirləridir (`.trow[data-t]`, ad + alt sətirdə fənn · sinif · N sual ·
abunə · «başqa qrupa da verilib»); toxunanda gizli select-in dəyəri
dəyişir. Telefonda doğma açılan pəncərə fənn düymələrini örtürdü — ona
görə siyahı səhifənin içindədir, >7 testdə `.scroll` (46vh). Üstdə
`#aSubs` fənn çipləri (≥2 fənn, «Hamısı» ilkin) və `#aQ` axtarış (>6 test)
`pickRedraw()` ilə siyahını süzür; seçili test süzgəcdən kənarda qalsa
ilk sətir seçilir. Testlərdə `select_option` yox — `#aList [data-t=…]`
klik; `wait_for_selector("#aList")`. Yoxlama: `e2e_assign.py`.

## Klik olunan yerlər dayanarkən də bilinsin (2026-09-10)

İstifadəçi: «klik olunacaq yerləri bir az diri edək, klik olunan olduğu
bilinsin». **Əsas səbəb: telefonda HOVER YOXDUR.** Yalnız `:hover`-ə
söykənən element barmaq üçün adi mətndən seçilmir — affordans
**istirahət halında** olmalıdır.

| Nə idi | Nə oldu |
|---|---|
| `.btn.ghost` şəffaf kənarlı — mətn kimi görünürdü | nazik kənar (`--line`) |
| `<summary>` boz mətn | **marka rəngi** + marka oxu |
| Mətn içindəki keçid yalnız rəngli | **dayanarkən altdan xətli** |
| Basılanda heç nə | `:active` — 0,985 kiçilir |
| Klaviatura görünmürdü | `:focus-visible` halqası |
| Toxunma cihazında hover «ilişirdi» | `@media (hover:none)` sıfırlayır |

Rəng tək başına siqnal deyil — **rəng kor istifadəçi üçün də** xətt lazımdır.

**TƏLƏ (tapıldı):** `assets/base.css` hər tətbiqin `app.css`-indən
**ƏVVƏL** yüklənir. Ona görə base.css-dən verilən `.fold>summary{color:…}`
kimi qaydalar app.css-dəki eyni spesifiklikli qayda ilə **əzilir**.
Ortaq qaydanı base.css-ə yaz, amma tətbiqin öz qaydası varsa **mənbədə**
düzəlt.

Valideyn və şagird tətbiqlərində eyni qayda `#main a[href]` üzərindən
verilir.

## Bütün həftə — «hansı gün hansı saat doludur» (2026-09-10)

İstifadəçi: «müəllimin bütün qrupları üzrə bir cədvəl kimi bir şey olsun».
Məlumat **artıq var idi** — `rpc_week` bütün qrupların 7 gününü qaytarır,
ekran isə yalnız bugünü göstərirdi. **Yeni sorğu yoxdur.**

İcmaldakı kartın içində yığılmış «Bütün həftə» bölməsi: hər gün bir sətir,
dərslər çip kimi («**16:00** Ev qrup»). **Boş gün də sətir tutur** və «—»
yazır — «boş günüm hansıdır?» sualının cavabı elə odur; yalnız dolu günləri
yazsaq, boşluq görünməz. Eyni gündə iki dərs yan-yana durur — «bu saat
doludur» siqnalı budur. Ləğv edilən dərsin üstündən xətt çəkilir.

Yoxlama: `e2e_cedvel` D2 — yeddi sətrin hamısı, boş günün «—»-i, bugünün
işarəsi, eyni gündə iki dərs.

**Testdə tələ:** D2 ikinci qrupa da cədvəl qurur; F bölməsi cədvəli
silərkən **hesabın bütün** sətirlərini silməlidir, yoxsa kart haqlı olaraq
yerində qalır və test yanlış düşür.

## Qrupun həftəlik cədvəli (db/177, 2026-09-09)

**Niyə.** Rəqib (kampus.az) cədvəli **üç pillənin hamısında** satır —
repetitor üçün təməldir. Bizdə ümumiyyətlə yox idi. Vertikal SaaS
araşdırması da bunu deyir: cədvəl istifadəçinin gündəlik iş axınının
mərkəzindədir və ən güclü bağlayıcı funksiyadır.

**PULSUZDUR.** Abunə qapısı yoxdur. İki səbəb: (1) gündəlik vərdiş
yaradan hissədir, (2) **davamiyyəti özü doldurur** — «bu gün dərs var»
kartı çıxır, müəllim tarix seçmir.

### İstifadəçinin qoyduğu qayda — pozulmamalıdır

**Cədvəl qurulmayıbsa heç bir ekranda görünməsin.** Nə İcmalda, nə
valideyndə. Boş «Cədvəl» kartı istifadəçini yanıldır («deməli dərs
yoxdur?»). `rpc_week.on = false` və `rpc_parent_home.week = null` —
frontend bunları görəndə **heç nə çızmır**. Söndürmək = sətirləri
silmək; keçmiş dərslər `public.lessons`-da qalır.

### Quruluş

| | |
|---|---|
| `class_schedule` | qayda: `weekday` (ISO 1–7), `starts_at`, `mins` |
| `lesson_changes` | istisna: `new_date` null → **ləğv**, dolu → **köçürmə** |

**Dərslər ÖNCƏDƏN yazılmır.** Cədvəldən `public.lessons`-a sətir
yaradılsaydı, cədvəl dəyişəndə gələcək sətirlər köhnə qalar və **iki
həqiqət** yaranardı. Burada qayda saxlanılır, həftə **anbaan**
hesablanır; `lessons` yalnız **faktı** (davamiyyət alınıb) saxlayır.

### Hal (state) — dörd dəyər

`plan` · `cancelled` · `moved_out` (buradan köçürülüb, `other` = hara) ·
`moved_in` (bura köçürülüb, `other` = haradan).

**Ləğv edilən dərs siyahıdan SİLİNMİR.** İlk quruluşda silinirdi —
onda müəllim üçün «Bərpa et» tutacağı qalmırdı. İndi üstündən xətt
çəkilir. Valideyn üçün də ən vacib xəbər elə odur.

### Tələlər

- **Toqquşma xətadır deyil, xəbərdarlıqdır.** Repetitor bəzən iki qrupu
  bilərəkdən eyni saata qoyur (iki uşaq eyni masada). Yazmağa mane
  olmuruq, yalnız deyirik.
- **`<input type="time">` İŞLƏDİLMİR.** Brauzerin dili `en-US` olanda
  «04:00 PM» yazır — Azərbaycanda saat 24-lükdür. Seçim siyahısı
  (07:00–22:00, 15 dəq addım) hər yerdə eynidir və telefonda bir
  toxunuşdur.
- **«Bu gün» BAKI günü ilədir**, brauzerin tarixi ilə yox. Saat
  00:00–04:00 arasında başqa vaxt zonasındakı telefon səhv günü
  işarələyərdi. Server `today` qaytarır, ekran onu müqayisə edir.
  (Yoxlama zamanı bu özünü göstərdi: UTC 20:44 = Bakı 00:44, artıq
  cümə axşamı — server düz, test skripti səhv idi.)
- `app.baki_bugun()` və `app.cedvel_araliq()` **daxilidir** —
  `authenticated`-ə də verilmir.

### v1-də olmayanlar

Otaq, çoxmüəllimli cədvəl, ödənişlə əlaqə, **şagird tətbiqində həftə**
(valideyndə var). Gündə bir dərs — baza çoxunu saxlaya bilir
(`class_schedule` açarı gün+saatdır), ekran v1-də sadəni göstərir.

**Yoxlama:** `smoke_cedvel.sql` (8) · `e2e_cedvel.py` (13).

## Geri düyməsi — haradan gəlibsə ora (2026-09-14)

İstifadəçi: «yuxarıdakı düymələr bəzi yerlərə qaytarır, çaşdırıcıdır».
Hər ekranın geri düyməsi **sabit** yerə gedirdi: vərəq → həmişə «Test yığ»,
hesabat → həmişə qrup. Tapşırıqlar siyahısından qələmlə vərəqə keçən müəllim
geri basanda Test yığ-a düşürdü.

- `HIST` — tətbiq içindəki keçidlərin yığını, `route()` doldurur (`BACKING`
  bayrağı geri gedişi yığına yazmır). `goBack(susma)` sonuncunu çıxarıb ora
  gedir, yoxdursa (səhifə yenilənib) susma ünvanına. `backLabel(susma)` düymə
  yazısını əvvəlki ekranın adından götürür (`routeTitle`: g→Qrup, a→Tapşırıqlar,
  r→Hesabat, t→Vərəq, gen→Test yığ …).
- Tətbiq olunan ekranlar: hesabat, şagird kartı, tapşırıqlar, dərs paketi,
  vərəq, sual redaktoru. **Toxunulmayan:** qrup ekranı (hub-dır — geri həmişə
  İcmal; öz alt ekranına «geri» getmək çaşdırır, `e2e_panel` bunu yoxlayır),
  alt menyu bölmələri
  (İcmal, Suallar, Test yığ, Profil, İdarəetmə, Bildirişlər) — onların geri
  düyməsi həmişə «Əsas səhifə»; Test yığ-ın «tapşırığa qayıt» niyyəti
  (`GF.back`) və Tapşırıqların `ASG_PRE` (şagird kartından) öz məntiqini
  saxlayır — niyyət yığından üstündür.
- Eyni ekranın öz-özünə yenilənməsi (`screenPaper(t.id)` ad dəyişəndən sonra)
  hash dəyişmir → yığına düşmür.
- **Brauzerin öz «geri»si** tətbiq keçidindən necə ayrılır: hər yeni keçidə
  `history.replaceState({i: Date.now()})` vurulur. `location.hash=` ilə
  yaranan təzə yazı state-siz gəlir (yeni keçid → yığına yazılır); brauzer
  geri/irəli edəndə köhnə yazı öz nömrəsi ilə qayıdır — nömrə kiçikdirsə geri
  gedişdir, yığından çıxarılır. İki səhv cəhd: «eyni ekrana qayıdış = geri»
  (şagird kartı → qrup → şagird kartı irəli keçidini də geri sayırdı) və
  sayaçla nömrələmə (səhifə yenilənəndə sıfırlanır, köhnə yazılar «irəli»
  oxunurdu) — vaxt möhürü ikisini də həll edir.
- Niyyətli qayıdışlar da yığından çıxarır (`goBack`): Tapşırıqlar → şagird
  kartı (`ASG_PRE`), Test yığ → Tapşırıqlar (`GF.back`) — `nav` ilə olsaydı
  irəli keçid kimi yazılır, sonra kartın öz «geri»si yenidən ora qaytarırdı
  (dövr; `e2e_assign` 324 tutdu).
- Yoxlama: `e2e_testsil` — Tapşırıqlar → qələm → vərəq → geri «Tapşırıqlar»
  → geri qrup → hesabat → geri «Qrup» → İcmal; birbaşa vərəq → «Əsas səhifə».

## Dərs planı və Dəftər — telefon düzəlişləri (2026-09-16)

İstifadəçi (Ev qrup, telefon): (1) «birini seçəndə test yığ çıxmır, ikisini
seçəndə çıxır» — düymə qəsdən 2+ idi (server `rpc_plan_test_multi` ≥2
istəyir); indi 1 seçimdə də çıxır, tək mövzu `rpc_plan_test` yolu ilə
(vergülsüz id → `planTest` özü ayırır). Düymə (`.plmbar`) siyahının
bilavasitə altında, «Növbətilərə bax»dan əvvəl. (2) «Planı sil» test
düyməsinin dibində idi — indi `.pldelrow`: ayrı sətir, sağ kənar, boz
`.lnk.del`. (3) Cədvəl qatlananı telefonda açılan kimi görünmürdü —
`.schedit` nişanı sağda («Dəyiş»/«Qur», açıqda «Bağla»), «▸» gizli.
(4) «Dərs oldu» → «Davamiyyət al» (Dəftər + İcmal həftə kartı), izah
«şagird siyahısı açılır». (5) «geri» → «⟲ geri al» (`title`: Keçildi
işarəsini geri al). Telefonda (`≤520px`) `.plrow` `flex-wrap`: ad tam en,
faiz · vərəq · geri al · ☐ ikinci sətirdə — əvvəl ad söz-söz qırılırdı.
`e2e_plan` tək seçim iddiası dəyişdi; şəkil skripti `test/_v2_plan.py`.
Bələdçidəki m12_defter.png hələ «Dərs oldu» göstərir.

**«Dərsdən əvvəl» kartı səliqə (16.09, istifadəçi: «dağınıq»):** başlıq
altındakı «bu günün dərsi · son keçilən · ev tapşırığı» çıxdı; fəsil və tarix
`.sub` ilə öz sətrində («· » prefiksi yoxdur); `.prep .warmline` tək sətir
(ad solda, `Hazırla` sağda, pill); `.prep .pbtns` 2 sütun grid, tək düymə
tam en. **Ev tapşırığı** iki qutu (`hwBox`: `.hwl > .hwh(i, s, .hwst) +
.hwb + .hwn + .hwf`); vəziyyət sinifləri `.hwst.w / .k / .m` — `.warn`/
`.ok` adları QLOBAL qutu stilləri ilə toqquşurdu (sarı pill çıxırdı).
Test mətnləri saxlanıb: «Açıq tapşırıq yoxdur», «Etməyənlər · 4/12 şagird»,
«etməyən: …», «0/2 etdi», «Hamı edib ✓», «bütün qrup», «son tarix», «hamısı».
Plan sətrində `.acts` sinfi (faiz/vərəq/test yığ olanda) — telefonda yalnız
o sətirlər iki sətrə qatlanır; yalnız ☐ + «geri al» olan sətir bir sətirdə.

## db/200 — İcmal kartlarında həftəlik fərq (2026-09-17)

Replit eskizindən götürülən ilk fikir: rəqəmin altında hərəkət. `rpc_home.stats`
+5 açar (`tests_w`, `students_w`, `attempts_w`, `avg_w`, `avg_pw` — son 7 gün
və 8–14 gün əvvəl). Gövdə `pg_get_functiondef` ilə götürülüb `'stats',
jsonb_build_object(` markeri genişləndirilir (marker 1 dəfə olmalıdır,
təkrar tətbiq keçilir). Panel: `.tile .td` sətri — «+2 son 7 gün» (yaşıl),
«+7% / −4% əvvəlki həftəyə görə», «əvvəlki həftə ilə eyni», «son 7 gün: 70%»;
qrup kartında «25 cəhd son 7 gün»; sıfır olanda sətir boş (hündürlük sabit,
«+0» yox). `smoke_icmal_hefte.sql` (yoxla.sh siyahısında), `test/_v2_tiles.py`.
**Canlıya əl ilə**, 05_grants lazım deyil. Qalan Replit fikirləri (sırayla):
«Diqqət tələb edir» mövzu üzrə yığım + «bu mövzudan test yığ»; qrupda «Mövzu
mənzərəsi» zolaqları; Son nəticələr sətri (avatar · ad · mövzu · faiz).

## db/201 — Təhlükə zonası mövzu üzrə (2026-09-17)

Replit eskizindən ikinci fikir. `rpc_home` +`topics` (marker `'paid', v_paid,`,
1 dəfə; təkrar tətbiq keçilir): qrup + mövzu üzrə zəif yığımı — şagird
mövzuda ≥ `alert_weak_min()` cavab, düz nisbəti < `alert_weak_pct()`; sətir
zəif ≥ 2 və ya qrupun yarısı; sıra zəif sayı ↓, orta ↑; ən çox 6; pulsuz
hesabda null. Hər element `remedialGen` üçün `id, name, subject_slug, level`
+ `class_id, class, n, weak_n, avg, weak[{id,name}]`. Panel `topicRow`
(`.al.tp`): «Statistika. Ehtimal (7-ci sinif) 12 şagirddən 5-i zəif · orta
68%», adlar → `#/s/`, «Test yığ» → `remedialGen(class_id, [t])` (Test yığ
ekranı mövzu+fənn+sinif seçilmiş). Mövzu sətri varsa `kind='weak'` şagird
sətirləri İcmalda gizlənir (Siqnallarda qalır); risk/star qalır. `sayS(n)`
say şəkilçisi («5-i», «6-sı», «3-ü»). `smoke_icmal_hefte` §3 (abunə lazımdır —
topics siqnallar kimi pulsuzda null). `test/_v2_topics.py`. **Canlıya əl ilə.**

## Qrup ekranında «Mövzu mənzərəsi» (2026-09-17)

Replit eskizindən üçüncü fikir. `#gTopics` (`#prep`-dən sonra), `loadTopicMap(g)`
`rpc_class_report.topics`-dən (əlavə sorğu yoxdur, hesabat sorğusu; pulsuzda
null → kart çıxmır). `topicBand`: ≥80 Möhkəm (yaşıl) · 60–79 Təkrar (sarı) ·
<60 Dəstək (narıncı). `total < 5` mövzu sayılmır; zəif birinci, 5 sətir,
«Bütün N mövzu → Hesabat». Başlıqda xülasə «10 mövzu · 2 dəstək · 7 təkrar ·
1 möhkəm». Sinif adları `tm-` prefiksli — `.ok/.th/.trow` qlobal stillərlə
toqquşurdu (zolaq görünmürdü, «1 möhkəm» qutu olurdu). Qayda: yeni kart
yazanda sinif adlarını prefikslə ver. `test/_v2_tmap.py`. Qalan Replit fikri:
Son nəticələr sətri (CSS, istəyə görə).

## Başlanğıc kartı v2 — əvvəl test, sonra qrup (2026-09-17)

Üçüncü AI turu + rəqəm (3 girişdən 0 qrup): «qrup yarat» müəllim üçün iş
idi, dəyər sonra gəlirdi. Yeni sıra: 1 «İlk testinizi yığın» (`#onbGen` →
`#/gen`, qrupsuz; «Necə görünür? Bələdçi» → `komek/#muellim`), 2 «Şagirdləri
əlavə edin» (`#gForm` kartın içində + `#onbNames` textarea «hər sətirdə bir
ad» → `onbNames()` təmizləyir, ≤60; `bindGroupForm` qrupu yaradıb `onbAddMany`
ilə adları ardıcıl `rpc_add_student` edir; qrup varsa yalnız textarea +
`#onbAdd`; limit dolanda «N şagird əlavə olundu, qalanı yox: …»), 3 «Testi
göndərin» (`#onbAsg` → `#/a/<gid>`). Addımın «edilib» olması MƏLUMATDAN:
`stats.tests>0`, şagird var, `stats.attempts>0`; `cur` = ilk edilməmiş; hamısı
edilib → kart yox; «Bağla» (`localStorage bil10_onb_off`, yalnız 3-cü addımda).
2-ci addımın forması 1-ci addımda da görünür (`.ost.todo .obody` gizlədilmir —
e2e `#onb #gForm` gözləyir). Bank SAYI yazılmır (qayda). `e2e_panel` «İlk
testinizi yığın» + `#onbGen` + `#onbNames`; şəkil `test/_v2_onb2.py`
(qeydiyyat → quruluş → SQL ilə test → adlar yapışdır → 3-cü addım).

- **Ders plani seliqesi (08.10)**: fesil = nomreli kart (acilanda brend rengli nomre + «2/7» + chevron), ders = ad + 2-ci setirde tarix / «fesil sonunda · n/N», kecilen ders dolu yasil ✓, «test yig» dolu, «vereq»/«geri al» cerciveli; «Son kecilen» ayri kart (etiket / ad / tarix). Yalniz CSS blogu (app.css sonu) + plRow-da tarixdeki «· » ve fesil nomresi; DOM/data-* eyni. Onbaxis: `test/tek.sh _plan_sekil2.py` (telefon sekli /tmp/claude-0/plansekil2). Qeyd: `e2e_plan.py` bu deyisiklikden evvel de `#gForm` timeout ile yiqilir (kohne test, ayrica baxilmali).

- **Plan: seçimlə test (08.10, db/928)**: sətirlərdə «test yığ» düyməsi YOXDUR. Hazır (`ders_hazir`) keçilmiş dərsdə checkbox (`data-plsel`); seçiləndə planın küncündə (sticky) BİR «Test yığ [· N dərs]» düyməsi (`data-plsgo`). Tək dərs → mövcud yol (`rpc_plan_test` ders, «vərəq» sətirdə qalır); 2+ dərs → `rpc_plan_test_done(plan, count, item_ids)`: hər seçilmiş dərsdən öz `ders:<slug>` nişanı ilə `app.generate_pick`, bir testdə birləşir (fəsil hovuzu YOX, keçilməmiş dərsin sualı düşmür; generatorda dəyişiklik yoxdur). İlk variant `rpc_pack_exam(p_all)` fəsil hovuzundan götürürdü - səhv idi, ləğv olundu. Fəslin başlığındakı «fəsildən test yığ» və zəif nəticədə «təkrar yığ» qalır. e2e: `e2e_ders_qapisi.py`, smoke: `smoke_plan_kecilen.sql`. `e2e_plan.py` bu işdən əvvəl də `#gForm` timeout ilə yıxılır.

- **Plan: nəticə görünsün (08.10)**: `#plm-<plan>` qutusu «Bütün mövzular»-dan ƏVVƏL (`<details>`-dən kənar) - yığılandan sonra siyahı bağlı olsa da «göndərildi» görünür; `drawPlan` yenidən çəkəndə «Bütün mövzular» açıq qalır (`wasOpen`). «Həmkarına göndər» mətni testə istinad etmir (link ana səhifəyə `?src=hemkar&r=KOD` aparır, həmkar sualları görmür); test üçün ayrı paylaşma linki YOXDUR - lazım olsa ayrıca iş (açıq önizləmə tokeni). `e2e_gen.py` bu işdən əvvəl də `#glevel` gözləməsində yıxılır (köhnə test).

- **«Həmkarına göndər» Profilə köçdü (08.10)**: test səhifəsində (suallar bölməsi) YOXDUR - link ana səhifəyə aparır, testə aid deyildi. Yeri: Profil → «Həmkarınıza göndərin» (`#btnHemkar`, `#hemkarMsg`); mətn heç bir testə istinad etmir; `rpc_ref_link` kodu qalır. Testin açıq önizləmə linki (həmkar hesabsız suallara baxsın) İSTƏNMİR (istifadəçi qərarı).

- **Qrup kartından «testi yığ» (08.10)**: «Dərsdən əvvəl» kartındakı «… testi yığ» (`#prepGen`) artıq tapşırıq ekranına QAYITMIR - `GEN_ENTRY` (bir dəfəlik niyyət) ilə `f.asg = qrup`, `f.fromG` qoyulur; «Testi yığ və qrupa ver» → test dərhal həmin qrupa verilir (7 gün, 1 cəhd), qrup seçimi yoxdur, nəticədə vərəq açılır. Generatorda «Tövsiyə olunan → Yığ» da həmin qrup üçün eyni yolla. Tapşırıq ekranından (`f.back`) və menyudan gələndə köhnə davranış: son tarix/cəhd/tək şagird orada seçilir. Son tarix/cəhd dəyişmək lazımdırsa vərəq səhifəsindən «Qrupa təyin et». `e2e_bugun.py` bu işdən əvvəl də `#btnGroup` gözləməsində yıxılır (köhnə).

- **Geri düyməsi hər yerdə «Geri» (08.10, istifadəçi)**: `bandHead` YENI görünüşdə `back.label`-i nəzərə almır, həmişə «Geri» yazır (qrup/ekran adı yox); `#btnBack` işləyiciləri `nav("#/")` əvəzinə `goBack("#/")` (gəldiyi yerə qayıdır). Köhnə görünüş (`?yeni=0`) əvvəlki adları saxlayır. Köhnə testlər `#btnBack` mətnini «Qrup/Tapşırıqlar/Əsas səhifə» gözləyirdi - «Geri» ilə yeniləndi. QEYD: `e2e_testsil.py`, `e2e_bize.py`, `e2e_bugun.py`, `e2e_assign.py`, `e2e_gen.py` bu işdən əvvəl də `#btnGroup`/`#glevel` gözləməsində yıxılır - ortaq köhnə başlanğıc (ayrıca düzəliş lazımdır).

- **Vərəq: «Başqa qrupa da ver» bağlıdır (08.10, istifadəçi)**: tapşırıq artıq verilibsə (və ya başqa qrupa verilib) vərəq səhifəsində «Kimə / Qrup / Son tarix / Cəhd / Testi ver» forması `<details class="fold pother">` içində bağlı gəlir (başlıq: «Başqa qrupa da ver»); verilmə XƏTA ilə bitibsə forma açıq qalır (müəllim özü verməlidir). Hələ heç yerə verilməyibsə forma əvvəlki kimi açıqdır.

- **Vərəqdə suallar bağlı gəlir (08.10, istifadəçi)**: test səhifəsində «Suallar · N sual» `<details class="qfold" id="qFold">` içindədir, bağlı; basanda açılır (30-50 sual səhifəni uzadırdı). Çap/PDF `paperPrint` öz nüsxəsini qurur - təsir etmir. Testlərdə `.paper`/`.pq` gözləməsi `state="attached"` + `#qFold.open=true` ilə yazılır.

- **Tapşırığı götürmək (X) təsdiq soruşur (08.10)**: `rpc_unassign_test` assignments sətrini SİLİR (attempts/nəticələr assignment-ə bağlı deyil - qalır; bitirməyən şagird testi görmür; yarımçıq qoyan `rpc_start_attempt`-də «təyin olunmayıb» xətası alır, hazırda içində olan isə bitirə bilir). Düymə `confirm()` ilə soruşur: neçə şagird bitirib, nəticələr qalır, bitirməyən görməyəcək. «Bağla» (closes_at=now) seçimi HƏLƏ YOXDUR - istifadəçi yalnız təsdiq seçdi.

- **«Etməyənlər» səhifəsi: dövr yox (09.10, istifadəçi)**: `#/ht/<qrup>` səhifəsinin sonundakı «Tapşırıqlara bax» sətri yalnız başqa yerdən (İcmal) gələndə çıxır; Tapşırıqlar ekranındakı «etməyənlər →»-dan gəliblərsə (`HIST` son = `#/a/<qrup>`) gizlədilir - əks halda elə həmin ekrana qaytarırdı. Geri düyməsi onsuz da oraya aparır.

- **İcmal menyusu: ayrı kartlar + yüngül 3D (09.10, istifadəçi)**: `#yMenu` içindəki sətirlər (Qruplar, Test yığ, Nəticələr, Sual bankı, Profil, İdarəetmə) artıq bir kartın xətləri deyil - hər biri ayrıca kart (12 px aralı, qat-qat kölgə, üst işıq xətti, alt «qalınlıq»); ikon 38 px yumşaq kvadrat, üzərinə gələndə azca qalxır, basanda çökür. Yalnız `#yMenu` - başqa ekranların `.menu`-su dəyişməyib. «Bu həftə» xəbərdarlıq kartı ayrıdır, toxunulmayıb (istənsə eyni üslub).

- **3D kart üslubu genişləndi (09.10, istifadəçi «burada da eyni fikirlə»)**: eyni CSS blok indi `:is(#yMenu,#yDiq,#gMenu,#stu) .mrow`-a aiddir - İcmal menyusu, İcmalın «Bu həftə» xəbərdarlıqları (#yDiq), qrup menyusu (#gMenu: Şagirdlər/Tapşırıqlar/Hesabat/Dərs planı/Dəftər) və Şagirdlər siyahısı (#stu; xülasə zolağı ayrıca kart). Yeni ekran əlavə etmək üçün həmin siyahıya id əlavə et, yeni qayda yazma. Başqa `.menu` siyahıları (Etməyənlər, Profil, Hesabat şagird sətirləri) hələ köhnə üslubdadır.

- **Kart üslubu hər yerdə (09.10, «bəli et»)**: ayrı kartlar + yüngül 3D artıq GLOBAL: hər `.menu` siyahısı (`.menu .mrow`: Etməyənlər, Hesabat, Son cavablar, Qruplar siyahısı və s.) və köhnə `.item` sətirləri (`.card.pad0>.item`: Profil, Qruplar və s.). Əvvəlki id-li (`#yMenu` və s.) qayda ümumi `.menu`-ya çevrildi. Bir siyahını köhnə düz görünüşdə saxlamaq lazımdırsa, ona `.flat` sinfi əlavə edib `.menu.flat` istisnası yaz (hələ yoxdur).

- **Qrup səhifəsi «Dərsdən əvvəl» səliqəyə salındı (09.10, istifadəçi «dağınıq və səliqəsiz»)**: dörd fərqli rəngli sol zolaq getdi (zolaq yalnız «Bu günün dərsi» və xəbərdarlıqda); bütün kartlar eyni padding/ikon/başlıq ölçüsündə; Test/Yazılı kartında nişan solda + keçid («Yaz →», «hamısı →») sağda eyni sətirdə; «etməyənlər» adları artıq «həb» yox, sadə vergüllü sətir (say muted). CSS: app.css sonu. DOM dəyişməyib (testlər eyni selektorlara baxır).
