# Qeydlər: Ailə (müəllimsiz) yolu, valideyn bütün uşaqlar, push bildirişlər (§11–13)

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

### 11. Valideyn: bütün uşaqlar bir ekranda (2026-10-05, «yadda saxla, sonra edərik»)

**İndi:** valideynin bir neçə uşağı ola bilər (`KIDS`, «+ uşaq»), amma
yuxarıdakı düymələrlə uşaq **bir-bir** dəyişilir. Bildirişlər isə artıq
hamısı üçün gəlir (bir düymə, hər uşağa ayrı abunə, mətndə uşağın adı).

**Ediləcək:** «Hər iki uşaq» ümumi xülasə kartı — hər uşağın adı, bu
həftəki testləri və gözləyən tapşırıqları bir ekranda. Real valideynlər
bunu istəyəndə (və ya iki uşaqlı valideyn şikayət edəndə) başlanır; əvvəl
real istifadəyə baxmaq lazımdır.

### 12. Push bildirişlər — qalan işlər (2026-10-05)

Hazırdır: 910 (altlıq), 911 («yeni test», gündəlik hədd 5), 912 (son tarix +
gündəlik 5 sual, saatlıq `push_tick`). Çıxışda həmin cihazın abunəsi
silinir (paylaşılan telefonda başqa uşaq əvvəlkinin xəbərini görməsin);
kartda bu yazılıb.

**Qalır:**
- Valideynə «bu gün çalışmayıb» bildirişi — AYRI açarla, susmaya görə
  söndürülü (`push_subs.prefs`), valideyn kartında açar.
- Chrome «Mümkün spam» xəbərdarlığı (yeni sayt, sınaq bildirişləri)
  real istifadəçilərdə çox görünsə: başlığa «Bil10 ·», daha konkret mətn.
- Sınaqdan sonra sakit saat açarını geri yandırmaq:
  `update public.app_state set val = val || '{"quiet": true}' where key = 'push';`
- Planşetdə (Android Chrome) «Bildirişləri aç» düyməsi cavab vermirdi —
  telefonda işləyir; diaqnostika əlavə olunub (v713), səbəb təsdiqlənməyib.

### 13. Müəllimsiz yol — şagird və valideyn müstəqil (2026-10-06, istifadəçi qərarı)

**Qərar.** Müəllimlər bəzən ehtiyat edir; ona görə şagird və valideyn
müəllimdən **asılı olmadan** işləyə bilməlidir. Müəllim məhsulu qalır
(əvəz yox, tamamlayıcı): müəllim varsa gündəlik paket onun planından
yığılır, yoxdursa şagirdin öz zəif mövzularından. Seçim meyarı:
**dünya praktikasında sübutlu üsullar** (xal/nişan yox, öyrənmə təsiri).
Ana fikir: **pulu ödəyən valideyn «uşaq həqiqətən irəliləyir» sübutunu
görməlidir.** Rəqiblər (otk.az, testup.az, AzSınaq, Abituriyentaze —
yalnız axtarış təsvirinə baxılıb) əsasən sınaq/yoxlama verir; biz
**öyrətməyə** çıxırıq.

**Baza artıq hazırdır:** `account_type` = parent/individual,
`group_kind` = self_study, `students.self_user_id` (müstəqil öyrənən),
diaqnostik test, səhv dəftəri (aralıqlı təkrar), gündəlik 5 sual
(`daily_topics` fallback: plan yoxdursa şagirdin öz cavab verdiyi
mövzular), parametrli suallar (`pq_seed`), push bildirişlər, valideyn
səhifəsi (bir neçə uşaq). **Çatışan: müstəqil başlanğıc yolu** — indi
şagird yalnız müəllimin verdiyi kodla girir.

**Sübut (qısa).** Aralıqlı təkrar (g≈0,74) · cavabı yaddan çıxarma
(testing effect, g≈0,61) · qarışıq məşq riyaziyyatda (24 saat sonra
38 %→77 %, amma tədqiqatdan tədqiqata dəyişir) · valideynə həftəlik xəbər
(kursdan kəsilmə −28 %, ümumi valideyn iştirakı təsiri kiçik, 0,12) ·
oyunlaşdırma ibtidaidə güclü (g≈1,29), amma xal/nişan/reytinq zamanla
zəifləyə bilər → **öz irəliləyişini göstər, reytinq yox**.
Mənbələr: Springer (spaced retrieval STEM, 2024) · Rohrer RCT (2019) ·
Taylor&Francis (technology-mediated parental engagement) · Wiley
(gamification K-12 meta-analysis).

**İdeyalar (istifadəçi «çoxunu bəyəndim» dedi), tövsiyə sırası:**

| # | İdeya | Qeyd |
|---|-------|------|
| 1 | **«Oxşar sual»** — səhvdən sonra eyni növdən yeni sual | **DÜZƏLİŞ (06.10):** `pq_seed` mexanizmi var, amma bankda cəmi **6** parametrli sual var (28 277-dən) — «hazırdır» demək səhv idi. Ucuz yol: eyni mövzu + yaxın çətinlik + hələ görmədiyi sual. Parametrləşdirmə sonra, riyaziyyatdan |
| 2 | **«Nə üçün səhv etdim?»** — «tələsdim / bilmirdim / hesabı səhv saldım», aylıq səhv növləri | bir toxunuş; konkret məsləhət |
| 3 | **Pilləli kömək** — ipucu 1, ipucu 2, həll; ipucu sayı = ustalıq siqnalı | tez təslim olmasın |
| 4 | **Qarışıq gündəlik 5 sual** — 2–3 mövzu, aralıqlı | mövcud paketin genişlənməsi |
| 5 | **Aylıq «inkişaf kartı»** — «mayda kəsrlər 55 %, indi 70 %», yenidən diaqnostika, WhatsApp-da paylaşılır | həm pul səbəbi, həm **paylanma** (ən zəif yerimiz) |
| 6 | **Valideynə həftəlik bir cümlə** (bazar axşamı) + «evdə soruşun…» + valideyn «Afərin» düyməsi | push hazırdır |
| 7 | **Şagirdin öz həftəlik hədəfi** (4 gün × 5 sual), fasilə günlü seriya | cəza yox, reytinq yox |
| 8 | **«Öyrənmə yolu» xəritəsi** — mövzu pillələri tanış→möhkəmləndir→yoxla (Azərbaycan şəhərləri temalı variant) | ikinci mərhələ |
| 9 | **İmtahan simulyasiyası** — vaxtla, bölmələrlə, «xalı harada itirdin: tələsmə / bilməmə» | |

**İstifadəçi qərarları (06.10):** PULSUZ HİSSƏ OLMAYACAQ — **1 aylıq sınaq**
(kartsız), sonra hesab bağlanır, məlumat qalır. **Qiymət uşaq başınadır**;
uşağın hazırlaşdığı sinif/qrupa görə fənlər üstün seçilir. Auditoriya:
**analar** (valideyn tanışları çoxdur — tez yayıla bilər; müəllim tanışı azdır).
Məqsəd: «uşaq nəzarətdə», **amma arxayınlıq çərçivəsində, casusluq yox**
(uşaq valideynin gördüyünü görür). Qiymət yer tutucusu: 9,90 AZN/ay uşaq
başına (04_seed `valideyn-aylik`), 2-ci uşağa endirim — **hipotez, ilk 10
ailədə yoxlanır**. Ödəniş: ilk ~20–30 ailə üçün əl ilə (köçürmə → admin
aktivləşdirir); Epoint (bölmə 4) çox yayılmadan əvvəl lazımdır.
**Məzmun dərinliyi (bankda, 06.10):** sinif başına 1 168–4 821 sual
(11-ci: 2 915, 10-cu: 2 571, fənn başına ~190–565 — gündə 5 sualla ~40
günə bitər). Abituriyent qrupları üçün bu **nazikdir** — vəd verməzdən
əvvəl dərinləşdirmək və ya «beta» yazmaq lazımdır. Qrup tərkibi DİM-in
rəsmi cədvəli ilə yoxlanmalıdır (yadda deyil, təsdiq olunmayıb).

**Mərhələlər:** (0) müstəqil başlanğıc: valideyn hesab açır, uşağı əlavə
edir (ad, sinif / abituriyent qrupu → fənlər avtomatik), uşaq kodla girir. (1) 1, 2, 5, 6.
(2) 4, 7, 3. (3) 8, 9. Hər mərhələni 5–10 real ailədə sınayırıq.

**ETMƏYƏK:** reytinq lövhəsi, seriya itirmə cəzası, kənar şəbəkədən AI
(memarlığa ziddir). Qayda: bölmə 7-dəki «paralel iki layihə yox»
qüvvədədir — bu, Bil10-un içində yeni giriş yoludur, ayrıca layihə deyil.

#### 13a. Tədqiqat nəticələri — 4 sessiya (2026-10-06; istifadəçi «əlavə et» dedi)

Tədqiqat sessiyaları (oxu-yalnız) dörd sahəni araşdırdı. **Bunlar tövsiyədir,
qərar deyil**; «yoxlanmayıb» yazılanlar sübut deyil. Kod və baza ölçmələri
birbaşa bazadandır, dünya praktikası hissəsi əsasən axtarış xülasələridir
(bəzi rəsmi səhifələr 403 verdi).

**1. Yerləşdirmə diaqnostikası («7-ci sinfə keçib», oktyabr).**
i-Ready/IXL/NWEA/Khan hamısı sinifdən ən azı BİR AŞAĞIDAN başlayır, adaptiv
irəliləyir, bir oturuşda hər şeyi sınamır. Bizim `rpc_diagnostic_create`
(db/118) dəyişdirmədən yararsızdır: tək sinifdən yığır (N-1 yoxdur), hələ
keçilməmiş fəsilləri də sınayır, 7-ci sinif tam diaqnostikası 70 fəsil/210
sual/~4,5 saatdır, nəticə yalnız SON cəhddən hesablanır (bölmək olmur),
yarımçıq qaralama yalnız həmin cihazda (localStorage, 2 gün).
**Tövsiyə:** dəst = (N-1)-in HAMISI + N-in yalnız Q1 etiketli fəsilləri;
əvvəl 3 əsas fənn (riyaziyyat, Az dili, İngilis); hər seans ≤5–6 fəsil/15–18
sual/~20 dəq = ayrı test, müddət 14 gün; rəng 3/3·2/3·0–1 qalır; N-1-də
qırmızıların ≥50 %-i varsa «bir sinif aşağı yoxla»; cari sinifdə qırmızı =
«yeni mövzu». Kod: yeni fayl (118-dən proqramla), `p_level_code`+`p_part`,
`gen_rule`-a `run`/`part`, nəticə eyni `run`-dakı bütün cəhdləri birləşdirir.
**Abituriyent:** `levels`-də abituriyent səviyyəsi YOXDUR (yerli bazada
yalnız 1–11) — əvvəl səviyyə və mövzu xəritəsi.
Yoxlanmayıb: bank `quarter` etiketinin real dərs təqvimi ilə uyğunluğu;
canlı bazada abituriyent səviyyəsi; 3 sualın statistik etibarlılığı.

**2. Bank əhatəsi (28 277 platforma sualı, yerli baza).** Dərin: riyaziyyat
5, 6, 8, 9 (1 296–2 106). NAZİK: **7-ci sinif riyaziyyat (529, 10 fəsil,
47–65)**, 6–7-ci sinif ədəbiyyat (5 fəsil), 7-ci sinif informatika (1 fəsil);
7 və 10-da «tarix» yox (yalnız ümumi tarix). Parametrli sual cəmi 6.
→ Bank sessiyasına prioritet: 7-ci sinif riyaziyyat, 6–7 ədəbiyyat.

**3. Cari fəsil və mənimsəmə.** `app.daily_topics` YALNIZ
`class_plan_items.done_at`-dən oxuyur (`student_plan_items.done_at` yox) —
müəllimsiz yolda yeni mənbə lazımdır. `topics`-də temp saxlanmır (`sort`
dərslik sırasıdır, `ord` yalnız plan sətirlərindədir). **Cari fəsil, tövsiyə
(variant 3):** təqvimə görə təxmini TƏKLİF (sentyabrdan mayadək xətti) +
həftədə bir toxunuşla «hazırda hansı mövzudayıq?»; seçilmişdən əvvəlki hər
şey «keçilib»; 10 gün toxunuş olmasa təklif bir pillə irəliləyir; «özü
cavab verdiyi mövzular» ehtiyatı qalır. **Mənimsəmə (tədqiqatlardan
çıxarılmış eşiklər, uşaqda SINANMAYIB):** son 10 cavabdan ≥8, ən azı 10
cavab, ≥2 fərqli gün, ≥6 fərqli sual; bir dəfə düz ≠ mənimsəmə; təkrar
3→7→21 gün (paketin 4-cü slotu); geriləmə bir pillə (yaşıl→sarı),
tarixçə silinmir; hədəf ~85 % uğur; valideynə «təkrar vaxtıdır» yazılır.
**DİQQƏT:** mənimsəmə artıq var — `practice` (db/133, 137, `score` 0–100,
100 olanda `mastered_at`). İki fərqli «mənimsənildi» olmaz; birləşdirmək
lazımdır. Cavab tarixçəsi PARÇALANIB (`attempt_answers` yalnız test,
`practice` yalnız yekun say, `daily_packs.answers`-də mövzunun ADI var, id
və vaxt yox) → `answer_log(student_id, topic_id, question_id, ok, at, src)`
+ `topic_mastery(student_id, topic_id, level, step, next_at, mastered_at)`.
Yoxlanmayıb: məktəbin real tempi; kurikulum ardıcıllığı; eşiklərin uşaq
üçün optimallığı.

**4. Dərs cədvəli ideyası (istifadəçi: «cədvəli də salaq»).** Tədqiqatçı
SONRAYA dedi, səbəbləri: cədvəl FƏNNİ bilir, MÖVZUNU yox (paket mövzu
üzrə qurulur); bildiriş vaxtını çox dəyişmir (19:00 hər iki növbəyə
yarayır), əsas faydası bildirişin MƏTNİdir; gün×dərs şəbəkəsi ~35 toxunuşdur;
«sabah dərs var → ön hazırlıq» üçün sübut tapılmadı. Daha ucuz alternativ:
gündəlik kartda «Bu gün hansı fənlər keçdi?» çipləri (10 saniyə, boşsa adi
paket). Azərbaycan: II növbədə 309 560 şagird (2022/23); dərs 45 dəq;
II növbənin saatları yoxlanmayıb. Data: `student_schedule(student_id,
weekday 1..6, subject_id)` + `students.school_shift`; mövcud `class_schedule`
yaramır (müəllim qrupu üçündür). Kilid ekranında növbə/saat yazılmasın.

**5. Hüquqi və qeydiyyat (hüquqi məsləhət DEYİL; qanunun tam mətni oxunmayıb).**
«Fərdi məlumatlar haqqında» qanun (2010, № 998-IIIQ): yazılı razılıq,
razılıq verə bilməyənlər üçün valideyn (m. 8.3), silmə (m. 7.1, 9.4), xaricə
ötürmə razılıqla (m. 14), informasiya sistemlərinin qeydiyyatı (m. 15,
1000-dən az istisnası TƏSDİQLƏNMƏYİB). 14–18 yaş qaydası yoxlanmayıb.
**Layihədə:** `public.consents` sxemdə var, amma HEÇ BİR RPC/kod ona
yazmır (yoxlanıb: `insert into public.consents` yoxdur); `mexfilik/index.html`
müəllimsiz yola UYĞUN DEYİL («razılığın alınması müəllimin öhdəliyidir»,
valideyn hesabı yoxdur); silmə yalnız info@bil10.az ilə əl ilə; Supabase
xaricdədir, siyasət xaricə ötürməyə açıq razılıq almır; «hesab bağlanır,
məlumat qalır» saxlama müddəti olmadan m. 9.4 ilə ziddiyyət ola bilər.
**Mərhələ 0 üçün MÜTLƏQ:** (1) `consents`-ə faktiki yazan RPC, açıq
(əvvəlcədən işarələnməmiş) razılıq qutusu, `evidence`-də versiya+vaxt;
(2) xaricdə saxlama üçün ayrıca aydın cümlə; (3) hesab və uşaq
məlumatının özünəxidmət silməsi + razılığı geri götürmə; (4) məxfilik
siyasətinin yenilənməsi (valideyn hesabı, e-poçt, saxlama müddəti);
(5) uşaq kodunun yenilənməsi (köhnə sessiyalar ölür). **Buraxılışdan əvvəl
hüquqşünasa bir baxış tövsiyə olunur.** Onboarding: ana e-poçtla bir
ekranda; kod iri, «WhatsApp-a göndər» + QR + «yenisini ver» (ClassDojo/
Seesaw/Khan nümunələri). Telefon/WhatsApp OTP sonraya (Supabase WhatsApp
yalnız Twilio ilə; Azərbaycan əhatəsi/qiyməti yoxlanmayıb). Valideyn
ekranı: həftədə bir xülasə, qınaq yox dəstək tonu, güclü tərəf əvvəl, sonda
bir «evdə soruşun…»; uşaq valideynin gördüyünü görür, valideyn cavab
mətnini görmür; gündəlik «çalışmayıb» susmaya görə BAĞLI.

**Mənbələr (seçmə):** Springer — spaced retrieval STEM (2024) · Rohrer RCT
(2019) · Cepeda 2008 (ED505660) · Rawson & Dunlosky 2011 (EJ934616) ·
Khan «Mastery levels» · ALEKS manual · FSRS/Anki docs · Duolingo HLR (ACL
P16-1174) · meclis.gov.az (qanun mətni, id=1201) · DLA Piper AZ · Supabase
phone-login & regions · ClassDojo/Seesaw/Khan parent-login səhifələri ·
azedu.az/news/34410 (növbələr) · teston.az (II növbə sayı).

#### 13b. Ailə yolu — 1-ci hissə QURULDU (2026-10-06, db/913, bayraqla bağlı)

**Nə var:** valideyn e-poçtla hesab açır (`valideyn/` səhifəsi, `rpc_family_start`, 30 gün kartsız sınaq,
plan `aile-usaq` — **9,90 AZN/uşaq yer tutucusu**) → «Uşaq əlavə et» (ad, sinif 1–11, fənlər sinfə görə
`rpc_family_subjects`, gündə 5/10/15 dəq, **razılıq qutusu** → `consents`) → gizli `self_study` qrup + şagird + giriş
kodu + seçilən ilk 3 fənndən **başlanğıc diaqnostika** (mövcud `rpc_diagnostic_create`, 14 gün) → «Ailəm» ekranı (kod,
WhatsApp, diaqnostika sayı) → «Ətraflı» mövcud valideyn ekranını `rpc_family_open` tokeni ilə açır (dəyişməyib).
Uşaq mövcud şagird girişi ilə kodla girir. **Bayraq:** `app_state.family = {"on": false, "emails": []}`; sönükdə yalnız
`emails` siyahısındakılar işləyir (server `app.family_ok()` yoxlayır). Girişdə «e-poçtla» keçidi yalnız bayraq açıqdırsa
və ya `?aile=1` ilə görünür. `valideyn/sb.js` açarı `valideyn_auth`-a dəyişdi (şagird tətbiqi ilə toqquşmasın).
Testlər: `db/test/smoke_family.sql`, `test/e2e_aile.py` (390 və 1280 px).

**Hələ YOXDUR (sonrakı hissələr):** abituriyent (düymə «tezliklə»), seanslı diaqnostika (N-1 + N-in Q1-i; indi
mövcud tək-sinif diaqnostika), `answer_log`/`topic_mastery`, cari fəsil seçimi, gündəlik 5 sualın yeni mənbəyi, «bu gün ✓»
valideyn kartı, həftəlik xülasə push, **özünəxidmət silmə və razılığı geri götürmə**, məxfilik səhifəsinin yenilənməsi
(`mexfilik/` hələ «razılıq müəllimin öhdəliyidir» deyir), uşaq kodunu yeniləmə, ödəniş (admin əl ilə aktivləşdirir).
Məlum xırda: hər «Ətraflı» basılışı yeni 30 günlük valideyn sessiyası yaradır (təmizləmə yoxdur).

**Qərar (06.10, canlı sınaqdan sonra): uşaq məlumatı GİZLİ qalır.** Razılıq mətni yalnız xidmət üçündür (ad, sinif,
məşq nəticələri Bil10-da saxlanır, silinməsi istənilə bilər) — «ad çıxarılmaqla ümumi statistika» cümləsi
**əlavə EDİLMİR**. Sual keyfiyyəti statistikası uşağa bağlı olmadan (sual üzrə) aparılır. Gələcəkdə kiminsə nəticəsi
əla olsa və saytda paylaşmaq istəsək — **ayrıca, konkret, yazılı icazə** soruşulur (hər hal üçün; ümumi razılıqdan
istifadə olunmur). Açıq: fənn seçimi hazırda ən çox 5-dir və başlanğıc yoxlama yalnız ilk 3 fənn üçün avtomatik yaranır
(ekranda yazılmayıb); bütün fənləri açıb yoxlamanı mərhələli vermək təklif olunub, cavab gözlənilir.

**Yeniləmə (06.10, db/914–915, v739):** (914) bütün fənlər seçilə bilir (≤12), başlanğıc yoxlama ilk 3 fənn üçün dərhal, qalanı
«Ailəm»-dən `rpc_family_diag` ilə; gündəlik vaxt 5/10/15/20/30 dəq (tövsiyə: 1–4→10, 5–8→15, 9–11→20; dəyər hələ YALNIZ
saxlanır, heç nəyi idarə etmir); razılıq mətni `aile-v3` («Uşağın adı və nəticələri yalnız sizə görünür, heç yerdə paylaşılmır.
Razıyam.»). (915) `rpc_family_summary` — «Bu gün N sual·M düz», həftə nöqtələri (B.e–B, Bakı vaxtı), «Hədəf x/4 gün» (4 sabit),
«Diqqət» (ən zəif mövzu: ≥4 cavab, <70 %, 45 gün), «Evdə soruşun»; `rpc_family_delete_child`, `rpc_family_delete_account`
(cascade + auth.users silinir; müəllim hesabı bu yolla silinmir); `mexfilik/` səhifəsi ailə yolunu əks etdirir.
(916, v743) «Hazırda hansı fəsildəsiniz?»: `rpc_family_chapters` (fəsil siyahısı + cari = keçilmiş son fəsil), `rpc_family_set_current`
(plan yoxdursa `rpc_plan_create` ilə yaranır; seçilən fəslə QƏDƏR bütün mövzular `done_at` alır, sonrakılar açılır) — beləliklə
`app.daily_topics` və gündəlik paket mövcud müəllim plan mexanizminə söykənir. «Diqqət» mətni yumşaldıldı (<6 cavab → «gücləndirmək faydalı olar»).
(917, v745) gündəlik məşq + mənimsəmə: paketin ölçüsü seçilmiş dəqiqədən (5/10/15/20/30 → 5/10/14/18/24 sual; `app.daily_build` indi yönləndiricidir:
ailə uşağı → `daily_build_family`, qalanı → `daily_build_classic`, müəllim yolu dəyişmir). Hər cavab `topic_events` jurnalına yazılır
(`app.mastery_note`, yalnız `family_kids`-də olan şagirdlər üçün; vahid = FƏSİL, yəni `coalesce(parent_id, id)` — suallar fəslə bağlıdır).
**Mənimsəmə:** son 10 cavabdan ≥8 düz, ≥2 fərqli gündə, ≥6 fərqli sualla. **Təkrar:** 3→7→21→45 gün; təkrarda 2 sualdan ikisi düz → növbəti
mərhələ, biri düz → eyni mərhələ +3 gün, ikisi səhv → bir mərhələ geri (1-ci mərhələdə → yenidən «öyrənilir»). **Paket:** təkrar (≤n/4 mövzu×2) +
səhv dəftəri (≤2) + cari fəsil/öyrənilən mövzular (növbə ilə, bir mövzudan ≤3; çətinlik cavab sayına görə 1→2→3). Mənbə etiketləri: `cari`, `mesq`.
`rpc_family_progress()` valideynə «Mənimsənilib N mövzu», «Hazırda: fənn — fəsil» göstərir. DİQQƏT: bu qaydalar uşaqlar üzərində yoxlanmayıb (§13a) —
canlıda real nəticəyə görə düzəldilməlidir.
(918, v746) «Afərin göndər»: `rpc_family_praise(usaq, 1..3)` — 3 hazır mesaj (sərbəst yazı YOXDUR), gündə 1 dəfə, `family_praise` cədvəli; uşağa push
(`kind='afarin'`) + `rpc_student_daily.praise` ilə gündəlik kartda 2 gün görünür (push açıq olmasa da). Həftəlik xülasə: `app.push_scan_weekly` (bazar 18–21 Bakı,
hesab başına BİR push, `hefte:<hesab>:<bazar ertəsi>` dedupe; `push_tick` onu da çağırır). Valideyn cihazı «Ailəm»dən bir toxunuşla bütün uşaqlar üçün yazılır
(`rpc_family_push_subscribe/unsubscribe`, scope `fam`; «Çıxış»da silinir; cihaz hər açılışda sinxronlaşır). Gündəlik push başlığı ailədə «Bu günün məşqi hazırdır».
DİQQƏT: ailə push qutusu e2e-də YOXDUR (e2e-də VAPID açarı boşdur) — real telefonda yoxlanmalıdır.
(919, v747) seanslı başlanğıc yoxlama: bir fənn = bir SERİYA (`gen_rule.run`) = bir neçə HİSSƏ (≤5 fəsil × 3 sual = 15 sual). Fəsillər: əvvəlki sinfin (N-1)
HAMISI + bu sinfin ilk üçdə biri (≥2), seriya ilk hissədə `gen_rule.topics`-də saxlanır. Valideyn hər hissəni «Növbəti hissə ver» ilə özü verir
(`app.family_diag_session`; `rpc_family_diag` indi onu çağırır, `rpc_family_children.subject_diag[].state` = none|open|partial|done + done/of).
Nəticə hissələr üzrə «Diqqət»də (915, mövzu üzrə cavablar) öz-özünə birləşir. Müəllim yolu (`rpc_diagnostic_create`) dəyişməyib. Hələ yox: «bir sinif aşağı yoxla» təklifi
(N-2), plan seçiləndə N sinfi fəsillərinin planla uyğunlaşması.
(920, v749) uşağın öz ana ekranı: `rpc_student_family(token)` (anon, `{family,minutes,week,today_i,mastered,cur}`; müəllim yolu şagirdi üçün `{family:false}`).
Ailə uşağında `screenTests` `FAM` ilə: «Mənim həftəm» bloku (7 gün + «N mövzu mənimsədin» + «Hazırda»), nəticə tile-ları/«Növbəti dərs»/«Keçdiyi dərslər» gizli,
«Tapşırıqlar» → «Başlanğıc yoxlama», «Zəif mövzular» → «Təkrar edək» (faizsiz, ≤3), gündəlik kartda seçilmiş dəqiqə. Giriş/footer mətni neytral
(«Müəllimin və ya valideynin verdiyi kod»). Anon whitelist 30 RPC (05_grants + smoke_huquq).
(921, v750) həftəlik hədəf: `family_kids.goal_days` (2–7, null = standart: 5 dəq→5, 10→5, 15→4, 20→4, 30→3 gün), `app.family_goal`; valideyn «Gündəlik məşq → dəyiş» ilə
vaxtı və hədəfi birlikdə dəyişir (`rpc_family_set_plan`; yeni vaxt sabahkı paketdən). Gün «çalışdı» = ≥1 cavab. Uşaq «Bu həftə: X / Y gün» + hədəf dolanda təbrik;
həftəlik push «Lale: 3/4 gün, 40 sual (71 % düz)…».
(922, v751) «Afərin» gündə 3-ə qədər (eyni mesaj gündə bir dəfə; push yalnız ilk ikisinə, 3-cü uşağın gündəlik kartında). Kart vəziyyəti: «Afərin göndər» /
«Bu gün N dəfə göndərilib ✓ · sonuncu HH:MM · Yenə göndər» / «Bu günlük limit doldu ✓ (3 / 3)»; xəta panelin içində çıxır (`rpc_family_progress.praise_n/praise_last`).
(923, v752) valideynə İSTİSNA bildirişləri (hər gün xülasə YOX — yorğunluq): (1) `push_scan_family_nostudy` — axşam 19:05/20:05 tick-i, YALNIZ uşaq o gün 0 sual cavablayıbsa,
elavə olunduğu gün yox, hesaba bir push (adlar birlikdə), `kind=bugun_yox`; (2) `push_scan_family_goal` — həftəlik hədəfə çatanda, uşaq başına həftədə bir dəfə, `kind=hedef`
(«Afərin göndər» təklifi, url `./valideyn/?aile=1`). Hər ikisi `family_prefs` (hesab səviyyəsində, defolt açıq) ilə «Ailəm»dən söndürülür; sakit saatlar dəyişməyib.
«Ailəm» push qutusu: «Vacib xəbərlər telefonunuza gəlsin» + «Hansı xəbərlər gəlsin?» (e2e-də saxta Notification/PushManager ilə yoxlanır, real push yox).
Düzəliş: valideyn «Afərin» göndərəndə gecədirsə «səhər 10:00-da gedəcək», uşağın push-u açıq deyilsə izah yazılır.
Həftəlik dərs cədvəli (söhbət 06.10): indi YOX — əvvəl real valideynlər hansı addımda dayandığını göstərsin; lazım olsa yüngül «gün → fənn chips» variantı
(paketdə sabahkı fənlər əvvəl + «Sabah … var» bildirişi).
(924, v753) OYUN ELEMENTLƏRİ (yalnız uşağa özəl; reytinq/yarış YOXDUR): personaj «Tumurcuq» (SVG, mərhələ cəmi çalışdığı günlərdən: 0 toxum · 3 cücərti · 7 bitki · 14 ağac · 30 çiçəkli ağac,
HEÇ VAXT geri getmir, cəza yoxdur), gün zənciri (aralıq ≤2 gün — bir gün buraxmaq pozmur), 7 hesablanan nişan (cədvəl yoxdur), valideynin yazdığı mükafat
(`family_kids.reward` ≤80, «Gündəlik məşq → dəyiş»dən, hədəf dolanda uşaq görür). `rpc_student_family`: days_total/streak/best_streak/answers_total/badges/reward; `rpc_family_set_reward`.
Qərar (06.10): uşaqlar arası yarış/«Dost çağırışı» — pilotdan və hüquqşünas baxışından SONRA; formatı: dəvətlə, hər iki valideynin razılığı, nəticə səyə görə (gün sayı),
əməkdaşlıq (komanda hədəfi) əvvəl, qalib/uduzan mesajı yox, başqa ailəyə yalnız ilk ad + gün sayı.
`db/aile_917_925.sql` — 917–925 bir faylda (Supabase SQL Editor-ə BİR dəfə yapışdırmaq üçün; təkrar işlədilə bilər). Yeni miqrasiya əlavə olunanda bu fayl yenidən yığılmalıdır
(`cat 917…924` ardıcıl). Səbəb: sahib faylları ayrı-ayrı əl ilə işlədir, bir-ikisi atılanda «Bu imkan hələ aktiv deyil» çıxır (06.10-da 921 atılmışdı).
(925, v754) yoxlama yorğunluğu: hissənin ölçüsü sinfə görə (1–4: 3 fəsil/9 sual, 5–7: 4/12, 8+: 5/15; `gen_rule.per`-də saxlanır), yeni uşaq əlavə olunanda YALNIZ ilk fənnin
1-ci hissəsi (qalanı valideyn gündə bir «Növbəti hissə ver»), «Bilmirəm, keç» (`is_correct` null) artıq «zəif» sayılmır (zəif yalnız cavab verilənlərdən, ≥3), ayrıca
`skipped_topics` → «Diqqət»də «N mövzuda uşaq “Bilmirəm” dedi — hələ keçilməmiş ola bilər». Uşaq tərəfdə: 1-ci sualda «təxmin etmə» izahı, siyahıda «≈ N dəq» (75 san limiti yox).
Məktəb elektron gündəliyi (07.10, sahibin dostunun telefonundan): cədvəl, formativ (hər dərsin «Mövzu»su), ev tapşırığı (kitab səhifəsi/nömrə), davamiyyət, menyu — YALNIZ məlumat,
məşq/öyrənmə yoxdur; 130 oxunmamış bildiriş. Qərarlar: (1) fərqimiz «uşaq bu gün nəyi təkrar etsin + çalışdımı»; (2) cədvəl/ev tapşırığı TƏKRARLANMIR (gündəlikdə var);
(3) «məktəb mövzusunu yapışdır» funksiyası LAZIM DEYİL — valideyn fəsli özü seçir (sahib, 07.10); (4) yalnız Azərbaycan bölməsi (suallar Azərbaycan dilindədir; rus bölməsi ayrıca qərar, tərcümə lazım).
Hələ yox: abituriyent, «bir sinif aşağı yoxla» (N-2), «Afərin»in oxunduğunun görünməsi, mənimsəmə bildirişi (3-cü növ), Dost çağırışı,
yoxlamanın 5-ci sinif hissəsini valideynin «Hazırda hansı fəsildəsiniz?» seçiminə bağlamaq (indi «ilk üçdə bir» təxmini).
