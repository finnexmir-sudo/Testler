# Qeydlər: «HAZIRDIR» qaydasının tarixçəsi — niyə yazıldı, pozulma halları

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

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

**Bu siyahı bir gündə üç dəfə pozulduğu üçün yazıldı** (hamısı yeni
görünüşdə, hamısını istifadəçi canlıda tapdı):
- «10 şagird bir həftədir səssizdir» → basanda **Qruplar** açılırdı.
  «Hanı 10 şagird?» — `href`-i yazmışdım, basmamışdım (1-ci bənd).
- Hesabatda şagird sətirləri pilləli, kənarları yırtıq. Səbəb: o sətir
  `<button>`-dur, qalanları `<a>` (3-cü bənd). Telefonda da, masaüstündə
  də görünürdü — mən nə birinə, nə o birinə baxmışdım (2-ci bənd).
- «Nəticələr · zəif mövzu var» → basanda yenə **Qruplar**. Səhifə
  hələ yox idi, amma sətir onu vəd edirdi (1-ci bənd).
- «Geri» qrup ↔ hesabat arasında ilişirdi: düymə brauzerə təzə yazı
  əlavə edirdi, brauzerin geri düyməsi ona qayıdırdı (6-cı bənd).

### Eyni kökdən olan digər hallar (hamısı bu gün)

- Sürət «qüsuru» — ölçü statistikasız bazada aparılmışdı, 620 ms
  yalandı (`ANALYZE` bölməsi).
- «19 təkrar variant» — hərf böyüklüyünə baxmayan yoxlama.
- «Şəxsi» nişanı — düzəliş testi üçün əvəzedici siqnal götürüldü,
  altı nəticənin üçündə çıxdı.
- **bio-11-insan-muhit (2026-09).** İstifadəçi soruşdu: «testlərimiz
  mövzunun bütün əsas bilik və bacarıqlarını bilmək üçün kifayət
  edirmi?». Mövzu «İnsan, onun inkişafı və mühit» idi (embrional
  inkişaf + psixika + ailə sağlamlığı), 30 sualın **hamısı** isə
  ekologiya idi (çirklənmə, milli parklar) — başqa mövzunun məzmunu
  səhv slug-a yazılmışdı. Sual sayı düz idi (30/30), çətinlik bölgüsü
  də «məqbul» görünürdü — heç kim mövzu ADI ilə sualların MƏZMUNUNU
  tutuşdurmamışdı, çünki bunu ölçən avtomatik yoxlama yox idi.
- **inf-11-komputer-veb (2026-09, eyni audit).** Mövzu «Kompüterin
  idarə edilməsi. Veb-layihə» idi (İdarəetmə paneli, Ailə
  təhlükəsizliyi, Word/Excel/PowerPoint-də veb-səhifə və s. — 8
  konkret alt-başlıq), 20 sualın hamısı isə ÜMUMİ kompüter aparatı
  (CPU/RAM/SSD) və ümumi veb-dizayn (HTML/CSS/JS) idi — mövzunun heç
  bir konkret bacarığına toxunmurdu. Bu, `bio-11-insan-muhit`-dən
  fərqli tələ idi: məzmun tamam YAD deyildi (hələ də informatika,
  hətta «yaxın» görünürdü), sadəcə kurikulumun TƏLƏB ETDİYİ konkret
  bacarıqlar əvəzinə ümumi/tanış mövzu yazılmışdı — «fənnə aiddir»
  «mövzuya aiddir» demək deyil.
- **tarix-11-mustemleke (2026-09, eyni audit).** Bu ikisindən fərqli,
  daha yüngül hal: mövzunun 10 real alt-başlığından 8-i yaxşı
  örtülmüşdü, YALNIZ «Cənubi Azərbaycan XIX əsrdə» və «Məşrutə
  inqilabı» (IV fəsil) heç toxunulmamışdı — 31 sualın hamısı Şimali
  Azərbaycan idi. Nəticə: **hər mövzunun HƏR fəsli/alt-başlığı**
  yoxlanmalıdır, «əksəriyyəti düzdür» kifayət etmir — bir fəslin tam
  unudulması asanlıqla gözdən qaça bilər.
- **Additiv sual faylları — idempotentlik (2026-09).** `db/141-148`
  (mövcud mövzuya bir neçə əlavə sual yazan kiçik fayllar) yazanda
  `questions` sətrini `on conflict (ext_key) do update` ilə düzgün
  qurdum, amma `question_options`-u əvvəlcədən silmədim — yalnız
  db/142 və db/144-də (tam-əvəzləmə tipli fayllar) bu addım var idi,
  qalan 6 faylda YOX idi. İkinci dəfə işlədiləndə `question_options`
  unique constraint-ə (question_id, ord) çırpılırdı. İstifadəçi
  bunu **canlı Supabase-də** tapdı, mən tapmadım — çünki commit
  mesajında «idempotentlik yoxlanıldı» yazsam da, əslində yalnız
  db/142 və db/144-ü iki dəfə işlədib yoxlamışdım, qalan 6 faylı
  YOX. «Yoxladım» dedim, amma hamısını yoxlamamışdım — məhz «HAZIRDIR»
  qaydasının 4-cü bəndinin pozulması («ölçmədiyimi deməmək —
  aldatmaqdır»). Düzəlişdən sonra HƏR additiv faylı — 142/144 daxil,
  hamısını — İKİ, bəzilərini ÜÇ dəfə ardıcıl işlədib sual/variant
  sayının sabit qaldığını təsdiqlədim. **Qayda:** yeni additiv sual
  faylı yazanda başına həmişə `delete from question_options ...
  where ext_key like '<prefiks>%' and ext_key ~ '<son suallar
  aralığı>'` sətri qoy — tam-əvəzləmə fayllarında olduğu kimi, sayı
  az olsa da fərq etmir.
- **`inf-8-kompyuter` (2026-09, «informatika ni yoxla» auditi).**
  Mövzu «İş masasının nizamlanması, İnformasiya modelinin ağac
  forması, Faylların axtarışı, Ağacşəkilli struktur əsasında məsələ
  həlli» idi (37_movzular_orta8.sql-ə görə), 20 sualın **hamısı** isə
  kompüter aparatı (ana plata, prosessor, RAM, videokart, SSD/HDD) —
  bu, tamam başqa mövzunun (`inf-9-komputer`) məzmunu idi. `bio-11-
  insan-muhit` ilə eyni tələ: sual sayı düz (20/20), çətinlik bölgüsü
  «məqbul», amma mövzu adı ilə məzmun arasında sıfır əlaqə. Eyni
  auditdə `inf-8-tetbiqi`də ikinci, daha yüngül hal: 6 alt-başlıqdan
  4-ü («Üçölçülü qrafika», «Tillər və üzlər», «Üçölçülü modellərin
  qurulması», «Mətn redaktorunun obyektləri») heç toxunulmamışdı, 20
  sualın hamısı yalnız elektron cədvəl (SUM/MAX/filtr) haqqında idi —
  `tarix-11-mustemleke` tipli «bir fəsil tam unudulub» tələsi, sadəcə
  burada dörd fəsil idi. Hər ikisi `db/152`-də tam yenidən yazıldı.
  **Əlavə tapıntı:** yeni yazılan əvəzləyici suallardan biri
  (`inf8-internet` üçün şəbəkə sualları, ilk qaralamada) qonşu
  siniflərin (`inf-9-texnologiya`, `inf-10-sebeke`) suallarına
  pg_trgm-də **1.00 (tam eyni)** çıxdı — özüm yazdığım YENİ məzmunda
  da köhnə tələ təkrarlana bilər, «yeni yazdım» «unikaldır» demək
  deyil. Hər yeni fayldan sonra pg_trgm yoxlaması bütöv fənn üzrə
  aparılmalıdır, təkcə köhnə bankla deyil, öz-özü ilə də.
  Nəticə: `db/152` (tam əvəz, 2 mövzu), `db/153` (`inf-8-internet`,
  «Kompüter şəbəkələri» bölməsi 6 sual), `db/154` (`inf-11-sistemler`,
  3 alt-başlıq — CİS/GİS, axtarış sistemləri, böyük verilənlər — 6
  sual), `db/155`/`db/156` (`inf-3-informasiya`/`inf-3-kompyuter`,
  daha kiçik alt-başlıq boşluqları), `db/157` (`inf-10-informasiya`,
  «İnformasiyanın miqdarı» — bit/bayt ölçü vahidləri — 5 sual),
  `db/158` (`inf-11-modellesdirme`, «Proqramlaşdırma dillərinin
  köməyi ilə riyazi modelləşdirmə» + «Üçölçülü qrafik modellər» 4
  sual). Cəmi 56 informatika mövzusunun **hamısı** tək-tək
  yoxlanıldı (alt-başlıq siyahısı ↔ sual mətnləri) — bu, təkcə bir
  neçə nümunə mövzu yox, bütöv fənn üzrə ilk tam audit idi. Bu 18
  fayl əvvəlcə `Testler/db/121-138` kimi yazılmışdı (bank sessiyası
  budağı), amma eyni müddətdə kod sessiyası `main`-də HƏMİN nömrələri
  (121-140) tamam başqa fayllarla tutmuşdu — 2026-09-07 razılaşması
  ilə 141-158-ə köçürüldü, `_bank` şəkilçisi əlavə olundu, fayllar
  `bil10-bank/db/`-yə daşındı (bax yuxarı «db/ fayl nömrələri»).

- **db/242 — düz cavab bayrağı 2-ci variantda (2026-09-12).** 11 riyaziyyat
  mövzusuna 108 cəbri sintez sualı yazdım. Generator düz cavabı həmişə
  1-ci variant kimi qoyur və `correct=1` (1-əsaslı) göndərirdi; SQL
  emit-də isə `correct_idx+1` yazmışdım (0-əsaslı sandım) → **108 sualın
  hamısında ilk YANLIŞ variant düz kimi işarələndi.** Faylın özünüyoxlaması
  («hər sualda düz 1 variant var»), pg_trgm dublikat, cavab balansı,
  idempotentlik, tam smoke suite — **HAMISI YAŞIL idi.** Heç biri
  «bayraq düz variantdadırmı?» soruşmurdu, çünki quruluşu ölçürdülər,
  məzmunu yox. Tutan yeganə şey push-dan əvvəl 3 sualı insanın gördüyü
  formada (`4 | [6] | 5 | 9`) oxumaq oldu — mötərizə səhv yerdə idi.
  Push olsaydı, düz cavab verən şagird səhv sayılacaqdı — məzmun
  qüsurlarının ən pisi. **Qayda:** hər yeni bank faylı üçün push-dan
  əvvəl bir neçə sualı `[düz]` formasında oxu; faylın son DO blokuna
  «düz cavab gözlənilən sırada/dəyərdədir» iddiasını yaz (242-də
  `o.ord <> 1 → raise`), «tam 1 düz variant var» kifayət DEYİL.
  **Bütün bank üzrə:** `db/test/bayraq_yoxla.sql` (yalnız oxuyur, canlı
  SQL Editor-da da işləyir) — 242 imzası + izah↔bayraq tutuşdurması.
  2026-09-12-də 22 255 sual üzrə 170 siqnalın hamısı oxundu: 0 həqiqi
  səhv (hamısı «hansı SƏHVDİR» qəlibi və ya izahın son rəqəminin
  distraktor olması). Siqnal sayı özü heç nə demir — sual mətnini oxu.

Ortaq kök birdir: **qurduğumu yoxlamaq, istənəni yoxlamaq deyil.**

---
