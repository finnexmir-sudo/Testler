# Layihə: Bil10

İbtidai siniflər (1–4) üçün onlayn test platforması. Gələcəkdə yuxarı
siniflər, MİQ və sertifikasiya da əlavə olunacaq.

Kommersiya məhsuludur: valideyn abunəliyi, repetitor paketləri, məktəb
lisenziyası. Ödəniş şlüzü (Epoint) sonra qoşulacaq.

> **İlk oxunacaq bölmə:** ««HAZIRDIR» NƏ DEMƏKDİR» — orada
> **TƏHVİLDƏN ƏVVƏL — MEXANİKİ SİYAHI** var. Görünən hər
> dəyişiklikdən sonra o yeddi bənd bənd-bənd keçilir. Keçilməyibsə,
> «hazırdır» yazılmır — nəyin yoxlanmadığı açıq deyilir.

---

## Qeydlər — mövzu üzrə `docs/qeydler/` (08.10.2026)

Bu fayl QISA saxlanılır (hər sessiyanın hər addımında yüklənir). Tarixçə, qərarlar, yarımçıq işlər və hər imkanın izahı
**mövzu üzrə fayllara köçürülüb — heç nə silinməyib, yalnız yeri dəyişib.** Lazım olanda **başlığa görə axtar**:
`grep -n "db/212" docs/qeydler/*.md` (köhnə qeydlərdəki «3220-ci sətir» kimi nömrələr artıq keçərsizdir — başlığa bax).

**Yeni qeyd** uyğun `docs/qeydler/` faylına yazılır, bura yox. Bura yalnız «hazırdır» qaydası, ən vacib qaydalar, əmrlər və üslub aiddir (≈350 sətirdən çox olmasın).

| Fayl | Nə var |
|---|---|
| `docs/qeydler/yarimciq-isler.md` | Yarımçıq işlər (2FA, bank public repo, ödəniş şlüzü, növbəti il planı, xırdalar) |
| `docs/qeydler/yarimciq-fikirler.md` | Gələcək layihə fikirləri, həvəsləndirmə, «Dostuna at», önbaxış saytı (hələ edilmir / qoşulmayıb) |
| `docs/qeydler/yarimciq-sual-bank.md` | Yarımçıq: sual pilləsi, dərsbaşına test, sual keyfiyyəti «DİM səviyyəsi» |
| `docs/qeydler/aile-yolu-ve-push.md` | Ailə (müəllimsiz) yolu, valideyn bütün uşaqlar, push bildirişlər (§11–13) |
| `docs/qeydler/qiymet-ve-satis.md` | Qiymət modeli, satış qərarları, sınaq abunə, hədiyyə, tövsiyə kodu, valideyn ödənişi (08.10 qərar) |
| `docs/qeydler/hazirdir-tarixce.md` | «HAZIRDIR» qaydasının tarixçəsi — niyə yazıldı, pozulma halları |
| `docs/qeydler/yol-xeritesi.md` | Yol xəritəsi — bütün nömrələnmiş maddələr |
| `docs/qeydler/bank-ve-suallar.md` | Sual bankı: qaydalar, yazma, çətinlik, oxşarlıq, mövzu ağacı, kurikulum, parametrik, adaptiv, diaqnostik |
| `docs/qeydler/ekranlar-ve-ux.md` | Ekranlar və UX: valideyn/şagird/nəticə ekranları, geri düyməsi, hesabat sekmələri, kartlar, qrup ekranları |
| `docs/qeydler/dizayn.md` | Dizayn qaydaları: marka zolağı, dizayn dili v2, kart blokları, alt zolaq, kölgə qaydası, görünüş əvvəl şəkil |
| `docs/qeydler/texniki-teleler-ve-infra.md` | Texniki tələlər və infrastruktur: Supabase, SQL Editor, miqrasiya, ANALYZE, marker, canlıda hansı miqrasiya, domen, oyaq saxlama, sürət |
| `docs/qeydler/imkanlar-tarixce.md` | Qalan imkanların tarixçəsi (db/NNN): admin, bizə yaz, nümunə hesab, ev tapşırığı, Bələdçi, ana səhifə, şagird/qrup təyinatı, sayğaclar |

**Yarımçıq işlər** (`yarimciq-*.md`, `aile-yolu-ve-push.md`): istifadəçi özü istəyib — **boş vaxt olanda, yaxud mövzu yaxınlaşanda xatırlat**, hər dəfə yox, yerinə düşəndə.
**Pul işi:** aşağıdakı «QAYDA: pul işi» məcburidir; cari qərar (ödəniş VALİDEYNDƏDİR, müəllim ödəmir, 08.10) — `docs/qeydler/qiymet-ve-satis.md` sonunda.
**Ailə yolu** (`rpc_family_*`, `db/913–925`; `db/aile_917_925.sql` bir faylda): `docs/qeydler/aile-yolu-ve-push.md`.

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

### TƏHVİLDƏN ƏVVƏL — MEXANİKİ SİYAHI (2026-09-22)

**İstifadəçi:** «hər dəfə deyirəm, belə səhvlər etmə, qaydaya mütləq
yaz ki hər şey dəqiq yoxlanılmalıdır».

Yuxarıdakı beş bənd NİYƏ-ni deyir. Bu siyahı NƏ etməli olduğumu deyir.
Görünən hər dəyişiklikdən sonra, «hazırdır» sözündən ƏVVƏL, bənd-bənd
keçilir. Keçilməyən bənd varsa, «hazırdır» yazılmır — nəyin
yoxlanmadığı açıq yazılır.

**1 · Yeni və ya dəyişdirilmiş HƏR keçid basılır.** Sətir, düymə,
link, çip — hamısı. Hər biri üçün üç sual:
- hara aparır? — ünvanı açıb **öz gözümlə görmüşəm**, `href`-ə baxıb
  «düz olmalıdır» deməmişəm;
- sətirdəki VƏD ilə açılan səhifə üst-üstə düşürmü? «10 şagird
  səssizdir» yazırsa, açılan səhifədə **10 ad** olmalıdır — qrup
  siyahısı yox;
- sətirdə rəqəm varsa, o rəqəm açılan səhifədəki rəqəmlə **eynidirmi**?

**2 · Hər görünən dəyişiklik İKİ enlikdə yoxlanır.** Telefon (390 px)
və masaüstü (1280 px). İkisinin də ekran şəkli çəkilir və **baxılır** —
çəkib göndərmək baxmaq deyil.

**3 · Element növü yoxlanır.** `<a>` və `<button>` eyni CSS ilə eyni
görünmür: link `display:flex` ilə tam eni tutur, düymə `width:auto`
qalır və öz məzmununun eninə yığılır. Yeni sətir sinfi yazanda hər iki
növü sına, yaxud sinfə `width:100%` yaz.

**4 · Boş hal da ekranda yoxlanır.** Siyahı boşdursa nə çıxır? Rəqəm
`null`-dursa? Şagird hələ girməyibsə? Dolu hal işləyir deyə boş hal
işləmir.

**5 · Eyni rəqəm iki yerdə yazılırsa, EYNİ sorğudan gəlməlidir.**
Yoxsa müəllim bir ekranda «2 zəif mövzu», o birində «3 zəif mövzu»
görür və ikisinə də inanmır. İki mənbə varsa — biri silinir.

**6 · GERİ düyməsi hər yeni səhifədə basılır** — həm düymədəki «Geri»,
həm BRAUZERİN geri düyməsi. `location.hash` yazmaq brauzerə TƏZƏ yazı
əlavə edir, ona görə «geri» iki səhifə arasında ilişə bilər.
`test/e2e_geri.py` bunu yoxlayır.

**7 · Testlər keçdi ≠ yoxladım.** e2e sətrin ENİNƏ, çipin ÜNVANINA,
boş siyahıya baxmır. Gözlə baxılmayan şey yoxlanmamışdır.

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

## `db/` fayl nömrələri — iki sessiya arasında bölgü

Bankı ayrı sessiya doldurur. Nömrə bölgüsü belədir:

| Aralıq | Kim | Nə |
|---|---|---|
| 01–29 | kod | sxem, RLS, RPC — doludur, bu repodadır |
| 30–99 | bank | sual/mövzu məlumatı (o biri sessiya) |
| 100+ | kod | yeni RPC və miqrasiyalar, bu repodadır |

Yeni **kod** faylı 100-dən başlayır. Bank faylına toxunma; bank
sessiyası da 100+ aralığına girmir.

**2026-09-07 razılaşması:** kod faylları 140-a qədər doludur (121–140
bu sessiya). Bank sessiyası **141–158** aralığını götürür (18 bank-content
düzəlişi, faylın adında `_bank` olsun, yeri `bil10-bank/db/`, burada
yalnız symlink); kod sessiyası **159-dan** davam edir. Bank faylı bu
repoya heç vaxt commit olunmur — commit-dən əvvəl yoxlama artıq nömrəyə
yox, private repo-da eyni adlı faylın olmasına baxır:
`git diff --cached --name-only | while read f; do [ -e "../bil10-bank/db/$(basename "$f")" ] && echo "BANK: $f"; done`
(112 bu yoxlamadan keçməmişdi — 103 sual açıq repoda qalmışdı, 2026-09-07
private-ə köçürüldü).

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

## Yerli yoxlama

```bash
# SQL testləri — hər suite öz təmiz bazasında
./db/test/yoxla.sh
./db/test/miqrasiya.sh          # təzə vs miqrasiya olunmuş sxem

# panel uçdan-uca (mock Supabase + Chromium)
./test/run_e2e.sh

# TƏK e2e skripti (sürətli — bazanı yenidən qurmur)
./test/tek.sh e2e_paket.py
NEW_DB=1 ./test/tek.sh e2e_paket.py   # miqrasiyadan sonra
```

**`tek.sh` niyə var:** `mock_supabase.py` parolları yaddaşda saxlayır
(`PASSWORDS`), ona görə bir testi ikinci dəfə işlədəndə qeydiyyat
mərhələsi (`#btnSetup`) tapılmır. Lazım olan **yalnız mock-u yenidən
qaldırmaqdır** — bazanı hər test özü təmizləyir. Bazanı da yenidən
qurmaq 3-4 dəqiqə aparırdı; `tek.sh` ilə 14 saniyədir.

**Postgres-i qaldırmazdan əvvəl `status` yoxla — `postmaster.pid`-i
kor-koranə SİLMƏ.** Səhv resept (2026-09-09-da test dəstini üç dəfə
yarımçıq kəsdi):
```bash
rm -f postmaster.pid && pg_ctl start      # PİS
```
İşləyən server varkən pid faylını silsən, yeni server qalxmır
(«pre-existing shared memory block is still in use»), **köhnə server
isə** lock faylını yararsız görüb **özünü dayandırır** («immediate
shutdown because data directory lock file is invalid»). Nəticə: sağlam
baza sönür, 44 suite «XETA» verir və səbəb konteyner kimi görünür.
Düzgünü:
```bash
pg_ctl -D /var/lib/postgresql/tdata status || \
  { rm -f /var/lib/postgresql/tdata/postmaster.pid; \
    pg_ctl -D /var/lib/postgresql/tdata -o '-p 55432 -k /tmp' -l /tmp/pg.log start; }
```
pid faylı yalnız **status «no server running»** deyəndə silinir.

**`pkill` naxışını həmişə lövbərlə (`^`).** `pkill -f "yoxla.sh"` və
`pkill -f "http.server 8010"` **öz bash sarmalayıcımızı da tapıb
öldürür** — test səssizcə boş qayıdır və ya sessiya kəsilir (iki dəfə
baş verib). Düzgün: `pkill -f "^bash ./test/yoxla.sh"`,
`pkill -f "^python3 -m http.server 8010"`.

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

## QAYDA: pul işi — 100 ölç, bir biç (2026-09-08)

İstifadəçinin qoyduğu qayda: **«Pul işi riskli işdir. Bir dəfə səhv
bütün inamı öldürər.»** Ödəniş, abunə, məbləğ, geri qaytarma —
bunlara toxunan hər dəyişiklik adi kod deyil.

**Sürətdən çox etibarlılıq.** Bu sahədə «sonra düzəldərik» yoxdur:
səhv silinmiş pul geri qaytarılsa belə, müştəri qayıtmır.

Pula toxunan hər işdə **məcburi**:

1. **Məbləğ HEÇ VAXT müştəridən gəlmir.** Frontend yalnız «X hesabı
   üçün ödəmək istəyirəm» deyir. Məbləği server hesablayır.
2. **Məbləğ sifariş anında DONDURULUR** (`seats_snapshot`,
   `period_start`, `period_end` sifariş sətrində). Müştəri bank
   səhifəsində ikən şagird əlavə etsə, ödəyəcəyi məbləğ gördüyü
   məbləğ olmalıdır.
3. **Callback-ə yalnız status və provider_ref üçün etibar edilir.**
   Hesab, plan, məbləğ — öz sifariş sətrimizdən oxunur. Callback-dəki
   məbləğ uyğun gəlmirsə: aktivləşdirmə YOXDUR, admin siqnalı VAR.
4. **Hər şey idempotent olmalıdır.** Şlüz callback-i təkrar göndərir —
   bu normaldır. `unique (provider, provider_ref)` + aktivləşdirmə
   eyni tranzaksiyada. Təkrar icra heç nəyi dəyişməməlidir.
5. **İtən callback üçün reconciliation MƏCBURİDİR**, opsional deyil.
   Callback və reconciliation EYNİ aktivləşdirmə funksiyasını çağırır —
   iki ayrı yol yazılmır.
6. **Müddəti bitmiş pending sifariş SİLİNMİR.** İstifadəçi hələ bank
   səhifəsində ola bilər. `expired` işarələnir, gec gələn uğurlu
   callback yenə qəbul edilir. Silmək = pul gəlir, abunə açılmır.
7. **Kart tokeni saxlanmır** (`card_id` yoxdur, təkrarlanan ödəniş
   yoxdur, yalnız redirect). Maskalanmış kart (son 4 rəqəm) token
   deyil — `payments.raw`-da qala bilər.
8. **Şlüzün gizli açarı `service_role` ilə eyni sinifdir.** Repoya,
   `config.js`-ə, frontendə HEÇ VAXT düşmür. Yalnız Edge Function
   secrets.
9. **Xam callback saxlanılır** (`payments.raw`) — mübahisədə yeganə
   sübutdur.
10. **Tarix hesablamaları `Asia/Baku` ilə.** Baza UTC-dədir; gecə
    yarısına yaxın gün fərqi bir gün sürüşür. Yazıda zərərsizdir,
    pulda deyil.

**Yazmadan əvvəl:** Epoint-in imza düsturu, status adları və status
sorğusu **rəsmi sənəddən** götürülür — yaddaşdan yazılmır.

**Buraxmadan əvvəl:** sandbox-da sınanır, reconciliation sınanır,
təkrar callback sınanır, məbləğ uyğunsuzluğu sınanır. Bunlar
smoke testə yazılır.

**Nə deyilmir:** «hər şey nəzərə alınıb». Nəyə əmin olduğumuzu və
nəyi hələ bilmədiyimizi açıq yazırıq.

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

## MƏNBƏ ≠ YAYIMLANAN FAYL (2026-09-21)

Saytda işlənən fayl **`app.min.js` / `app.min.css`**-dir — `index.html`
onları göstərir. Sən isə **`app.js` / `app.css`**-i redaktə edirsən.
Aradakı körpü `./yig.sh`-dir (esbuild).

`./bump.sh` hər dəfə əvvəl `./yig.sh`-i çağırır, `test/tek.sh` və
`test/run_e2e.sh` də çağırır — yəni e2e yoxlamaları **saytda işləyən
faylla** gedir. Ayrıca çağırmağa ehtiyaq yoxdur.

`.min` fayllar repoya girir (GitHub Pages onları verir), `node_modules/`
girmir. esbuild tapılmasa `yig.sh` **dayanır** — səssizcə köhnə `.min`
faylla yayımlamaq ən pis haldır.

Sıxılan fayllar: `muellim|sagird|valideyn` × `app.js, sb.js, app.css` +
`assets/base.css`. `config.js`, `ferq.js`, `pwa.js`, `visit.js` toxunulmur
(kiçikdirlər), `s/` qovluğu da kənardadır.

## Üslub

- İnterfeys mətnləri Azərbaycan dilində, düzgün diakritiklərlə (ə, ş, ğ, ı, ö, ü, ç)
- SQL şərhləri Azərbaycanca, amma ASCII ilə
- Panel açıq temadır, toxunma sahələri ən azı 44px
- Xarici kitabxana yoxdur — CDN yüklənmir. `muellim/sb.js` Supabase üçün
  öz yüngül qatımızdır; onu böyütməkdənsə lazım olan hissəni əlavə et.

---
