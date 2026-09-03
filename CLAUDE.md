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

## «HAZIRDIR» NƏ DEMƏKDİR — pozulmaz qayda

**Baş verən (sentyabr 2026).** İstifadəçi dedi: «test yığanda dərs
keçdiyi sinif və **aşağı sinifləri də seçib verə bilsin**». `db/103`
generatorda çoxlu sinif seçməyi açdı, 7 SQL + e2e yoxlaması yaşıl
oldu, mən **«hazırdır»** dedim.

Yarısı işləmirdi. Təyinat ekranı testləri hələ də dəqiq bərabərliklə
süzürdü — müəllim 5-ci sinif testi yığırdı, sonra onu qrupa **verə
bilmirdi**. İstifadəçi bunu canlıda özü tapdı.

**Səhvin kökü:** dəyişdiyim funksiyanı yoxladım, istifadəçinin
cümləsini yox. Bütün yoxlamalar generatorda idi; zəncirin o biri ucuna
— «verə bilsin» hissəsinə — heç kim baxmamışdı.

### Qayda

**1 · İstifadəçinin cümləsinin FEİLİ deliverabldır.**
«…seçib **verə bilsin**» — deliverabl vermək, yığmaq yox.
«…valideyn **görsün**» — deliverabl görmək, RPC yazmaq yox.
Cümləni yazıb feilini altından xətlə: iş o feillə bitir.

**2 · Zənciri sonuna qədər yeri.** Dəyişiklikdən sonra istifadəçinin
yolunu addım-addım keç, HƏR addımda dayan:
yığıldı → siyahıda **görünür?** → təyin oluna **bilir?** → şagird
**görür?** → nəticə hesabata **düşür?**
Bir addım yoxlanmayıbsa, iş bitməyib.

**3 · Yaşıl testlər «hazırdır» demək DEYİL.** Testlər dəyişdiyim
kodu ölçür. Zəncirin toxunmadığım hissəsi sınmır — çünki heç kim ona
baxmır. «201 yoxlama keçir» ilə «istifadəçi istədiyini edə bilir»
fərqli iddialardır.

**4 · Dili dəqiq işlət.** «Hazırdır» yalnız zəncir sonuna qədər
yoxlanandan sonra. Yoxsa:
«Generator hissəsi hazırdır, təyinat tərəfini ölçməmişəm.»
Ölçmədiyimi **deməmək — aldatmaqdır**, «hələ bilmirəm» demək yox.

**5 · Şübhə varsa, açıq de.** «Bunu yoxladım, bunu yoxlamadım» həmişə
«hazırdır»dan yaxşıdır. İstifadəçi yarımçıq işi canlıda tapmamalıdır.

### Eyni kökdən olan digər hallar (hamısı bu gün)

- Sürət «qüsuru» — ölçü statistikasız bazada aparılmışdı, 620 ms
  yalandı (`ANALYZE` bölməsi).
- «19 təkrar variant» — hərf böyüklüyünə baxmayan yoxlama.
- «Şəxsi» nişanı — düzəliş testi üçün əvəzedici siqnal götürüldü,
  altı nəticənin üçündə çıxdı.

Ortaq kök birdir: **qurduğumu yoxlamaq, istənəni yoxlamaq deyil.**

---

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
   (ibtidai, orta), 11 sinif, 12 fənn.
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

16. **Bir valideyn — bir neçə uşaq.** İndi hər şagirdin ayrı valideyn
    kodu var: iki uşağı olan valideyn iki kod daşıyır. Müştəri sayı
    artanda bunlar bir girişdə birləşməlidir (bir kod → uşaq seçimi).
    İstifadəçi ilə razılaşdırılıb: **hələlik ayrı, gələcəkdə birgə.**

17. **Aktiv müəllimə aylıq endirim.** İstifadəçinin təklifi (ilk canlı
    müəllim söhbətindən sonra): proqramı fəal işlədən müəllimə növbəti
    ayın haqqından endirim — stimul. Ölçü sadə olmalıdır və müəllimin
    özü görməlidir («bu ay 12 tapşırıq, 40 cəhd → gələn ay −20 %»);
    gizli düstur inam qırar. Ödəniş mərhələ 2-yə (Payriff/Epoint)
    bağlıdır — ondan əvvəl mənasızdır. Bələdçi (`komek/`) ilə birlikdə
    «necə qazanılır» da orada yazılacaq.

18. **Diaqnostik test → şagird üzrə mövzu xəritəsi → fərdi dərs planı.**
    (a) və (b) **hazırdır** — `db/118_diaqnostika.sql`, bax «Diaqnostik
    test» bölməsi; (c) fərdi plan açıqdır.
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
    `07_seed_tests.sql`-dəki «Genişləndirilmiş analiz testi» bunun
    nümunə-yer tutucusudur, məhsul deyil (canlıda yoxdur).

19. **«Bizə yaz» — istifadəçi təklifləri.** İstifadəçinin sözü: real
    təcrübədən gələn təkliflər olacaq, biz dəyərləndirəcəyik. Qayda:
    tətbiqdən kənara şəbəkə müraciəti yoxdur → təklif Supabase-də
    cədvələ yazılır (`feedback`: kim, hansı tətbiq, mətn, tarix), RLS
    bağlı, yazmaq RPC ilə (müəllim `auth.uid()`, şagird/valideyn öz
    tokeni ilə), oxumaq yalnız İdarəetmədə. Müəllim Profildə,
    şagird/valideyn giriş/ev ekranında kiçik «Bizə yaz» forması.
    WhatsApp linki bunu əvəz etmir: təkliflər bir yerə yığılmalıdır ki,
    dəyərləndirilsin. Kiçik iş — pilotla eyni vaxtda faydalıdır.

Açıq qərarlar: abunə bitəndə öz suallarının taleyi; platforma bankının
mənbə strategiyası; bil10.az qeydiyyatı (istifadəçinin işi); valideyn
girişində qiymət modeli — pilotdan sonra (təfərrüat: yerli strategiya
qeydləri).

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

## `db/` fayl nömrələri — iki sessiya arasında bölgü

Bankı ayrı sessiya doldurur. Nömrə bölgüsü belədir:

| Aralıq | Kim | Nə |
|---|---|---|
| 01–29 | kod | sxem, RLS, RPC — doludur, bu repodadır |
| 30–99 | bank | sual/mövzu məlumatı (o biri sessiya) |
| 100+ | kod | yeni RPC və miqrasiyalar, bu repodadır |

Yeni **kod** faylı 100-dən başlayır. Bank faylına toxunma; bank
sessiyası da 100+ aralığına girmir.

**2026-09-03-dən bank fayllarının (16,17,19,20 və 30-99 aralığı) +
`tools/` + `mundericat/` yeri dəyişib: ayrıca PRIVATE repo-dadır —
`finnexmir-sudo/bil10-bank`.** Səbəb: bu repo (`Testler`) PUBLIC-dir,
bank faylları isə sual mətni + düz cavab + izahı açıq mətn kimi
daşıyırdı — `rpc_bank_samples`/`rpc_bank_list`-dəki abunə qapısı
faktiki mənasız olurdu, çünki kimsə sadəcə bu faylları GitHub-dan
oxuyub bütün bankı pulsuz götürə bilərdi. Bank sessiyası işini
`bil10-bank`-da davam etdirir, eyni nömrələmə qaydası ilə. Bu repoda
bank fayllarına ehtiyac olsa (məs. `db/test/miqrasiya.sh`), `bil10-bank`-ı
`Testler`-in yanına (bacı qovluq kimi, `../bil10-bank`) klonla.

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
alır və yalnız ağ siyahını (8 şagird + 3 valideyn RPC-si) saxlayır —
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
`sagird/app.js` `diagMap`. Testlər: `db/test/smoke_diaqnostika.sql` (9),
`test/e2e_diaq.py`.

`07_seed_tests.sql`-dəki «Genişləndirilmiş analiz testi» bunun köhnə
yer tutucusudur — məhsul deyil, bələdçi şəkillərində gizlədilir.

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

---

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
