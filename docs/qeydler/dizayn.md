# Qeydlər: Dizayn qaydaları: marka zolağı, dizayn dili v2, kart blokları, alt zolaq, kölgə qaydası, görünüş əvvəl şəkil

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## Üst zolaq — marka rəngi

`assets/base.css` `.top` üç tətbiqdə `--top-bg` (#3559de, markadan bir
ton açıq — istifadəçi istədi), yazı, «Çıxış», «Geri» və zəng ağdır.
Nişan 32px ağ kvadratdadır (`.top .mark`, SVG 24px — e2e_bank ölçür),
yanında `<span class="wm">Bil10</span>` və nöqtə, sonra səhifə adı.
`theme-color` meta və manifestlərin `theme_color`-u da `#3559de`. Zolağa
yeni element qoyanda rəngini ağ ver.

## Yumşaq dərinlik — kölgə qaydası

İstifadəçi seçimi (3 variantdan «yumşaq»): kart (`base.css .card`) nazik
çərçivə + yayğın kölgə; rəngli kartlar (`.stat`, `.tile`, şagird `.st`)
mavi çalarlı kölgə; `.segs` içəri, `.seg.on` qalxmış; `.btn.go` altında
mavi kölgə; masaüstündə (`@media (hover:hover)`) `.item`/`button.trow`/
`.test` üstünə gələndə 1px qalxır. Sərt 3D (qabarıq düymə, qradiyent
çərçivə, tünd kölgə) yoxdur və əlavə edilmir. Yeni kart/sətir eyni qaydada.

## QAYDA: görünüş dəyişikliyi əvvəl şəkil, sonra push (2026-09-08)

İstifadəçi hər dəyişikliyi canlıda görməkdən narazıdır («nizamsızlıq»).
Görünən hər dəyişiklikdə (dizayn, mətn, yerləşmə) push-dan ƏVVƏL
kompüter + telefon ekran şəkli göndərilir (SendUserFile), «ok»
gözlənilir, sonra commit + push. Yalnız məntiq/baza dəyişikliyində
(görünüşə toxunmayan) birbaşa push olar. Aşağıdakı önbaxış saytı
qurulmayıb (istifadəçi «uzun oldu» dedi) — lazım olsa sonra.

## Dizayn şablonu — marka zolağı (2026-09-08, v374–377)

Ana səhifə Oxuyan üslubunda yenidən yığıldı (istifadəçi bəyəndi) və
eyni şablon üç tətbiqə köçürüldü. Qayda: **yeni ekran bu şablona uyğun
olmalıdır**, köhnə «geri düyməsi + başlıq kartı» üslubu qalmayıb.

- **Zolaq** (`#band`, `#main`-dən əvvəl, `assets/base.css`): indigo→teal
  gradient, ağ yazı. Məzmun: geri düyməsi (`.bback`, şüşə), kiçik alt
  başlıq (`.beye`), `h1`, bir sətir izah (`p`), solda `.av`, sağda `.br`
  düymələr (`.sasg` sarı CTA). İlk kart `#main.over` ilə zolağın alt
  kənarını kəsir.
- **Panel** (`muellim/app.js`): `bandHead({back,eye,title,sub,av,right,
  id,subId})` — `show()`-dan bir addım ƏVVƏL çağırılır (`BAND_KEEP`);
  `show()` özü zolağı təmizləyir. Şagird/valideyndə sadə `setBand(html)`.
- **Lövhələr** (`.tiles`, `.stats`, şagird `.stiles`): BİR ağ kart,
  aralarında nazik xətt, rəngli rəqəm, ikon çipi (`.ti`). Dolu rəngli
  qutu yoxdur.
- **h2** (`#main h2`, base.css): tünd, altında 30px gradient xətt; artıq
  boz CAPS deyil — testlər `inner_text`-də adi hərflə yoxlayır. Kart
  içi başlıq `h2.ch`.
- **Üst zolaq** `.top` eyni gradient. **Footer** `.afoot` (tünd, logo,
  keçidlər, il) üç `index.html`-də statikdir; `.wrap#main` alt boşluğu 20px.
- Salamlama/ad zolaqdadır → testlər `#band`-a baxır (e2e_gen,
  e2e_student, e2e_valideyn). Boş hesabda `#gForm` `main`-in üstünə.
- Ana səhifə: `.topband` gradient, `.doors` sarı/ağ CTA, `.under`
  önizləmə kartı, `.under2` nümunə + beta, bölmələr tam enli
  (`section.tint`), `.freesec` kartı `.foot`-u kəsir. GPT-nin «şəkli
  böyüt, kartı qaldır» polişi sınandı və qaytarıldı (istifadəçi fərq
  görmədi) — hero-ya daha toxunulmur.

## Dizayn dili v2 — «nanə + lacivərd + sarı» (2026-09-16, ana səhifə)

Ana səhifə Replit Design eskizindən (istifadəçi: «çox qəşəngdir,
xüsusilə sarı zolaq») bizim adi HTML/CSS-ə köçürüldü. **Bundan sonra hər
yeni ekran bu ailədən olmalıdır**; panel/şagird/valideyn hələ köhnə
zolaq şablonundadır (yuxarıdakı bölmə) — sıra: panel karkası → boş hesab
ekranı → Qrup → Hesabat. Masaüstündə sol menyu istifadəçi tərəfindən
QƏBUL edilib (16.09), telefonda alt zolaq.

- **Tokenlər** (`index.html` `:root`, gələcəkdə `base.css`-ə):
  fon `#f7fbf9`, yazı `#173b50`, lacivərd `#123a51`, teal `#087f75`
  (tünd `#05625d`, yumşaq `#eaf7f3`, nanə `#d9f5ef`, parlaq `#64d2c3`),
  sarı `#f4c94f` (tünd `#d7a931`, yumşaq `#fff1c6`), mərcan `#e98773`,
  yaşıl `#42bcae`, xətt `#dcebe6`, boz yazı `#67817f`.
  Dörd reng, hər bölmədə eyni rol: teal = əsas düymə/vurğu, sarı = CTA və
  xəbərdarlıq, lacivərd = tünd bölmə/altlıq, nanə = fon çaları.
- **Şrift** Plus Jakarta Sans (OFL), `assets/fonts/pjs-latin*.woff2`
  (dəyişkən çəki 200–800, ~49 KB). `@font-face` adı `"PJS"`. Kənar
  yükləmə YOXDUR — Google Fonts linki qadağandır (siyasət). Ağırlıq:
  başlıq 800, `letter-spacing:-.06em`; mətn 400–600.
- **Bölmə ritmi:** hero (nanə, üstdə 4px sarı xətt) → qərar zolağı →
  krem `#fffdf8` (addımlar) → nanə (video + CTA) → lacivərd (imkanlar,
  `.dark`) → krem (hədd) → nanə (etibar) → **sarı** son çağırış → lacivərd
  altlıq.
- **Hero sağ tərəf:** hesabat kartı (`.rcard`), illüstrasiya çıxdı.
  Kartın dili bizim realdır: faiz, «zəif · orta · yaxşı», «Bundan başla»;
  bal («7,8/10») YOXDUR, paneldə də yoxdur. Altında «nümunə məlumat».
- **Düymələr:** `.btn.teal` (5px tünd alt kölgə), `.btn.yellow`,
  `.btn.navy`, `.btn.line`. Qapılar `.door` **SARI** (16.09, variant A —
  səhifədə tək sarı düymə) / `.door.b` (kontur); başlıqdakı `.enter`
  konturdur. Sınanıb-qaytarılıb: teal qapı, lacivərd/sarı başlıq düyməsi.
- **Testlərin baxdığı seçicilər saxlanıb:** `.doors a` (tam 2:
  `muellim/#/demo` + `muellim/`), `.hlinks a[href=muellim/]` tək,
  `#cta a[href=muellim/]` tək, `#demo` yox, `a.pdoor` yox, `#tqVid`,
  `.vspeed button`, `#heddBox`, `data-ev` düymələri, `.enter .lg/.sm`.
- Replit-in yalan vədləri («müəllim komandası», «məlumatı silin»,
  qeydiyyat modalı) köçürülmədi. Replit-dən kod istəyəndə: «single static
  HTML, inline CSS, no React/Tailwind, no external fonts» — TSX lazım
  deyil, ekran şəkli + statik HTML bəsdir.

## Dizayn dili v2 — panel, şagird, valideyn karkası (2026-09-16, v503)

Ana səhifədən sonra üç tətbiq də v2-yə keçdi. Tokenlər indi
`assets/base.css` `:root`-dadır (indigo `--brand` → teal `#087f75`,
`--bg` nanə, `--line` `#dcebe6`, `--navy`, `--yellow`, `--coral`,
`--purple`…); köhnə `#2b4acb/#0e9384/#ffc94d` heks dəyərləri
app.css-lərdən təmizlənib. Şrift `"PJS"` (`assets/fonts/`, base.css
`@font-face`, url `fonts/…` — base.css-ə görə nisbi).

- **Üst zolaq `.top`** ağ-bulanıq, tünd yazı, 60px. `.top .mark` 32/24
  ölçüsü QALIR (e2e_bank H ölçür), `.top .wm` «Bil10» qalır.
- **Zolaq `#band`** tam enli deyil: `.bandin` yuvarlaq teal KARTDIR
  (`--grad` 120°), `#main.over{margin-top:0}` — ilk kart artıq zolağı
  kəsmir. `.bandin` max-width = `.wrap` − 40 (720 / panel ≥1100: 880 /
  şagird-valideyn: 560), yoxsa kart altdakı kartlardan enli çıxır.
- **Sol menyu `#snav`** (panel, ≥900px, `body.bnav-on`): lacivərd sütun
  232px, «İş masası» (BNAV bəndləri) + «Hesab» (Siqnallar, Profil) + ipucu
  qutusu; `body.bnav-on{padding-left:232px}`. AYRI elementdir — `#bnav`
  masaüstündə gizli qalmalıdır (e2e_panel «masaüstündə alt panel gizlidir»,
  `#bnav a` sayı 4). `bnavShow()` ikisini də doldurur. Telefonda `#bnav`
  ağ, «on» bəndi teal çiplə.
- Loqolar (3 index.html + afoot + snav): gradient teal→firuzəyi, çip
  `#f4c94f`. `theme-color` `#087f75`.
- Yoxlama şəkilləri: `test/_v2_shots.py` (panel, masaüstü+telefon),
  `test/_v2_sv.py` (şagird, valideyn) → `/tmp/claude-0/v2/`.
- Növbəti: boş hesab ekranı (girişdən sonra 3 addım), sonra Qrup və
  Hesabat ekranlarının məzmun səviyyəsində v2-yə uyğunlaşdırılması.

## Başlanğıc kartı + İcmal kart-blokları + rəng pilləsi (2026-09-16, v504)

- **Başlanğıc (`#onb`, `onbDraw/onbPaint/onbOff`, app.js):** ölçü — 6
  qeydiyyatdan 3-ü panelə girib qrup yaratmadı. Üç addım: 1 qrup (forma
  `#gForm` kartın içinə köçür, `.inonb`; `#btnGroup` yerində — 15 test
  basır) → 2 şagird (`#onbStu` → `#/g/<id>`, orada forma özü açılır) →
  3 ilk test (`#onbGen` → `#/gen`). Hansı addım: qrup sayı / şagird sayı /
  `rpc_home.stats.tests`. İlk test gedəndə kart yox olur. Kart görünərkən
  zolağın `.bacts` düymələri və `#freeCard` («pulsuz hədd», uzun
  siyahı) gizlənir — `style.display`, çünki `hidden` atributu
  `display:flex`-i əzmir (`.h2row`, `.bacts`, `.card.gift` — hamısı belə).
  `#giftCard` QALIR (e2e_panel A1 oxuyur). Boş hesabda `#groups` boşdur,
  «Hələ qrup yoxdur» yazısı YOXDUR — testlər `#onb .ost.cur`-a baxır.
- **İcmal blokları kart kimi** (`#hAlerts/#hRecent/#hTop5:not(:empty)`):
  başlıq kartın içində, nazik xətt, siyahı kənarsız. HTML dəyişməyib.
- **Rəng pilləsi (istifadəçi seçdi, «bu vəziyyətdə push et»):** fon
  nanə `#dfeee8`, xətt `#c9ddd6`, kart kənarı `#cfe0da`; yazı 500 çəki,
  `--fg-2 #3f5f66`, `--fg-3 #5d7876`; zolaq qradiyenti doyğun
  (`#05897c→#2cc9b5`), üstündə 4px sarı, `.beye` sarı, `.bcta.pri` sarı.
  SINANIB VƏ QAYTARILIB: neytral boz fon (`#e9eef2`) və İcmalda «rəng
  ritmi» (sarı «bu gün», mərcan «təhlükə», lacivərd «sürətli
  əməliyyatlar») — Lovable eyni nəticəni verdi, istifadəçi nanə halı
  seçdi. Tünd mövzu hələ sınanmayıb (variant kimi qalır).
- Dizayn alətinə şəkil atanda mətn: «keep all text, change only visual
  design, tokens …, output static HTML, no React/Tailwind/external fonts».

## Alt zolaq: Suallar → Qruplar; notranslate; e-poçt yoxlaması (2026-09-16, v507)

- **BNAV** `İcmal · Qruplar (#/gs) · Test yığ · Profil` (istifadəçi: gündəlik
  dövr qrup→test→nəticədir, sual bankı arabir). `screenGroups()`: zolaq +
  `#groups` kartları + eyni forma (`groupFormHtml()` / `bindGroupForm()` —
  Icmalla ORTAQ, id-lər `#gForm #gname #glevel #btnGroup` qalır). `g/r/a/s`
  ekranlarında da «Qruplar» bəndi «on». Sual bankı: Profildə `#btnMeBank`
  sətri + masaüstü sol menyuda ayrıca bənd. Boş hesabda Qruplar ekranı
  `.empty` kart + forma (orada `#onb` yoxdur). Testlər: e2e_bank Profildən
  gedir, e2e_panel «Qruplar var, Suallar yoxdur» + ekran yoxlayır.
- **`<meta name="google" content="notranslate">`** altı səhifədə: telefonu
  ingilis dilində olan adamda Chrome paneli özü ingilisləşdirirdi («Teacher
  panel», «See example» — 16.09 ekran şəkli).
- **Giriş/qeydiyyat e-poçtu** (`doAuth`): boşluqlar silinir, kiçik hərf,
  format yoxlanır («ad@gmail.com» nümunəsi), `gamil.com/gmial.com/…`
  səhvində düzəldilmiş ünvan sahəyə yazılır. Səbəb: `imani terane1982@.com`,
  `…@gamil.com` — adam «parol yanlışdır» görüb gedirdi.
