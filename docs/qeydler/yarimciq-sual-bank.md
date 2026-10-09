# Qeydlər: Yarımçıq: sual pilləsi, dərsbaşına test, sual keyfiyyəti «DİM səviyyəsi»

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

### 9. Sual PİLLƏSİ və görüntülü tapşırıqlar (2026-09-22, istifadəçi fikri)

**Haradan çıxdı.** Çıxma terminləri düzəlişindən sonra e-dərslik
səhifəsinə baxdıq (665/unit-1/səh. 75). Dörd tapşırıq **nərdivandır**,
hər pillədə yalnız bir şey dəyişir:

| Pillə | Tapşırıq | Nəyi yoxlayır |
|-------|----------|----------------|
| 1 · tanıma | «18 − 1 = 17, burada 18 necə adlanır?» | termini bilirmi |
| 2 · hesablama | «600 − 250 = ?» | əməli bacarırmı |
| 3 · tərs | «Azalan 600, fərq 250-dirsə, çıxılan?» | əlaqəni qurumu |

Dərslikdəki 3-cü tapşırıqda `11 − 1`, `16 − 0`, `12 − 12` **təsadüfi
deyil** — sonrakı bütün qaydalar adi məşqin içində əkilib.

**Problem.** Bankımızda demək olar hamısı 3-cü pillədir. Şagird səhv
yazanda «Çıxma zəifdir» deyirik, amma səbəbi bilmirik: hesablamanı
bacarmır, yoxsa «azalan» sözünü tanımır?

**Təklif.** `questions.tags` massivinə `pille:1|2|3` nişanı (sxem
dəyişikliyi lazım deyil). Onda:
- zəif mövzu sətri «Çıxmada **terminləri** bilmir» deyə bilər;
- təkrar testi bir pillə **aşağıdan** yığılar, eyni çətinlikdə yox.
Sınaq üçün bir mövzuda 5-6 yeni sual bəsdir.

**İstifadəçinin sualı:** «belə görüntülü sual və tapşırıqlar hazırlaya
bilirik?» — yoxlandı, cavab yarımdır:

| Dərslikdəki şey | Bizdə |
|-----------------|-------|
| şəkil, həndəsə çizgisi, rəngli düstur | **var** — `media_url`, SVG data-URI (`db/188`); `<img>` ilə çizilir, içindəki skript işləmir |
| parametrik rəqəmlər (`{b*10}`) | **var** — bankda onsuz da işlənir |
| bir neçə düz cavab / sərbəst mətn | **var** — `question_kind`: single · multi · text |
| rəngli söz sual MƏTNİNDƏ | **yox** — mətn həmişə `esc()`-dən keçir; rəng lazımdırsa SVG-yə yazılır |
| doldurulası cədvəl (dərslikdəki 4-cü tapşırıq) | **yox** — belə tip yoxdur; ya SVG şəkil + hər sütuna bir sual, ya yeni `kind` |
| şifahi / yazılı ayrımı (baş və əl nişanı) | **yox** — anlayış özü yoxdur |

Yəni «şəkilli sual» bu gün hazırlana bilər; «içində doldurulan cədvəl»
üçün yeni sual tipi lazımdır.


### 10. Dərsbaşına test — bank 22 963 sualdır, 52 200 lazımdır (2026-09-22)

**Haradan çıxdı:** Qızbəst müəllim «Bəzi mövzularda testlər yoxdur»
yazdı. Ölçü (`db/test/ders_basina_hovuz.sql`):

| rəqəm | dəyər |
|---|---|
| plan sətri (dərs) | 3480 |
| «test yığ» düyməsi olmayan dərs | **2846 = 82%** |
| bir dərsə düşən sual (orta) | **6.6** |
| hər dərsə 15 suallıq test üçün lazım olan bank | **52 200** |

Suallar fəsil hovuzundadır (bax «Mövzu ağacı» bölməsi), düymə fəsil
bitəndə çıxır. Qapını hər dərsə açmaq olmaz: 6.6 sualdan beş ardıcıl
dərsə fərqli test çıxmır — «hər dəfə eyni test gəlir» şikayəti
«test yoxdur»dan pisdir.

**2026-09-22-də edilən:** sətir artıq səbəbi yazır («fəsil sonunda ·
2/4»). Bu, qavrayışı düzəldir, hovuzu yox.

**Əsl həll, hələ başlanmayıb:** bankı dərs səviyyəsinə endirmək —
təxminən 30 000 yeni sual. Prioritet `ders_basina_hovuz.sql`-in `pay`
sütunundadır; ən dar yerlər Fizika 9 (1.9), Coğrafiya 7 (2.7),
İngilis 10-11 (2.7-2.9), Kimya 11 (2.7).

**Şərt:** qapını yalnız payı yetən fəsildə açmaq olar, həm də generator
əvvəl istifadə olunmuş sualı çıxarmalıdır — indi çıxarmır
(`db/13_generator.sql` təsadüfi seçir).


### 8. Sual keyfiyyəti — «DİM səviyyəsi»nə necə çatırıq (2026-09-12)

**İstifadəçinin sualı:** «Ən zəif yerimiz testləri tərtib etməkdir. Test
kitablarından çəkib dəyişdirərək hazırlaya bilmərik?» **Cavab: yox.**

**Kitabdan çəkib dəyişdirmək — YOX.** Səbəb əxlaq deyil:
- Hüquqi: e-dərslik üçün istifadəçinin öz qoyduğu qaydadır — yalnız
  mündəricat, məzmun yox. Rəqəmi/adı/variant sırasını dəyişmək əsəri
  «bizim» etmir — *törəmə əsərdir*, eyni qaydaya düşür.
- Praktiki: bazar kiçikdir, Hədəf/Araz müəllimləri öz sualını bir
  baxışdan tanır; 0 pullu hesabla bir məktub layihəni bağlar.
- Faydasız: bir kitab 500–1000 sualdır, bizdə 21 min var. Problem say
  deyil, **keyfiyyəti bilməməkdir**.

**Kitabdan almaq OLAR** — və əsl qiymətli hissə budur: imtahanın
*quruluşu* (mövzudan neçə sual, formatlar, variant sayı, vaxt),
*çətinlik kalibrasiyası* (oxuyub öyrənmək), kurikulum standartları
(dövlət sənədi, açıq), mövzu bölgüsü (fakt — fakt qorunmur).
**Almaq OLMAZ:** sual mətni, dəyişdirilmiş sual, izah, distraktor dəsti.
Keçmiş DİM rəsmi imtahanlarının lisenziyası aydın deyil — istifadədən
əvvəl yoxlanmalı, güman edilməməli.

**Əsl problem yazmaq deyil, sübut yoxluğudur.** DİM-in sualı yaxşıdır,
çünki imtahandan əvvəl minlərlə şagirddə sınanır; zəif sual imtahana
çatmır. Bizdə bu maşın **var** — `db/134_sual_keyfiyyeti.sql`: `p` (düz
faizi), `rpb` (nöqtə-biserial ayırdetmə), distraktor təhlili, «açar
səhv ola bilər» siqnalı. Çatmayan **məlumatdır**: hesablama n ≥ 20
cavabda başlayır, şagird 38-dir. Maşın qurulub, yem yoxdur. Bank
sessiyasının işinin faydası da buna görə indi ölçülə bilməz — yalnız
«struktur olaraq düz görünür». Ölçü: 100 qiymətlənmiş sualdan neçəsi
siqnal alır (`rpc_admin_qstats` → `rated`, `flags`).

#### Sual fabriki — beş qapı

```
spesifikasiya → yazılış → avtomat yoxlama → müəllim baxışı → şagird məlumatı
```

1. **Spesifikasiya (blueprint).** Hər fənn üçün cədvəl: *mövzu × idrak
   səviyyəsi (bilir / tətbiq edir / təhlil edir) × format × say*.
   Yaradıcı işi çeklistə çevirir — hansı hüceyrə boşdur, ölçülür.
   Mənbə: DİM-in açıq imtahan formatı + kurikulum. Bank sessiyasının
   ilk işi sual yazmaq yox, **bu cədvəli doldurmaq** olmalıdır.
2. **Yazılış.** Bank sessiyası hüceyrələri doldurur. Riyaziyyat, fizika,
   kimya üçün **şablon (db/132)** var və demək olar istifadə olunmur:
   bir dəfə yazılan sual `{a}`, `{b}` ilə sonsuz variant verir —
   hesablama fənlərində məzmun xərcini ~10 dəfə azaldır. «Məzmun xərci
   nəhəngdir» iddiasının əsas cavabı budur.
3. **Avtomat yoxlama.** Var: pg_trgm dublikat, cavab balansı, struktur
   təhlili (uzun cavab, mütləq sözlər, əks-səda — bank repo-sundakı
   `tools/cetinlik_analiz.py`). Əlavə olunmalı: hər sualın **kurikulum
   standartına bağlanması** — standarta bağlanmayan sual mündəricatdan
   kənara çıxıb (Qaribaldi hadisəsi, bax: «Çoxmülahizəli birləşmə»).
4. **Müəllim baxışı.** Yazan müəllim saatda ~10 sual, yoxlayan ~100.
   Ona görə yazdırmaq yox, **baxdırmaq** — təsadüfi 10 %, sual başına
   ödənişlə. Arzu və Samir müəllim buradadır.
5. **Şagird məlumatı (db/134).** Azərbaycanda heç kim bunu etmir —
   çap olunmuş kitab sualının pis olduğunu heç vaxt öyrənmir, bizimki
   hər cavabla özü-özünü düzəldir. Rəqabətdə yeganə real fərqimiz.

**1-ci fikir 4-cü fikirlə burada birləşir.** Qapı 5-ə yem lazımdır.
Bölmə 7-də 1-ci yerdəki **pulsuz şagird PWA-sı** həm hunidir, həm
məlumat toplayan maşındır. Abituriyent bankının keyfiyyəti **yazmaqla
yox, trafiklə alınır**: pulsuz tətbiq → on minlərlə cavab → db/134
zəif sualı göstərir → düzəldirik → *sonra* «DİM səviyyəsi» deyirik,
çünki sübutu var. Rəqiblərin heç birində bu sübut yoxdur.

**2-ci mərhələ üçün:** müəllimlər yazsın — «Platformaya təklif et»
düyməsi + baxış + mükafat (bir ay pulsuz). Ucuzdur, amma keyfiyyət
yükü 4-cü qapıya düşür; indi yox.

**Yekun:** zəif yerimiz «yazmaq» deyil, **sübut yoxluğudur**. Sübut
kitabdan çəkilmir — spesifikasiya + şablon + trafik ilə alınır.

---
