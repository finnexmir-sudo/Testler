# Qeydlər: UX yoxlaması (23.10.2026) — icra siyahısı

Mənbə: üç müstəqil yoxlama — Claude (kod sessiyası, 4 agent, yerli nüsxə), Claude (söhbət, canlı demo),
ChatGPT (canlı demo). Birləşdirilmiş tapıntılar istifadəçidədir (`Bil10_uc_hesabat_muqayise.docx`).
Sıra (istifadəçi + rəhbər, 23.10): **1** testin düzgünlüyü → **2** hesabatın düzgünlüyü → **3** alıcıların
düzgünlüyü → **4** ilk istifadə → **5** telefon rahatlığı. Bu, təsdiqlənmiş və yoxlanmalı işlər siyahısıdır,
düzəliş hesabatı deyil. **Hər bənd bağlananda üç sual yazılır: nə dəyişdi · necə yoxlandı · canlıya keçdimi.**

## Sıra 0 — xətalar (23.10)

| # | Xəta | Nə dəyişdi | Necə yoxlandı | Canlıda? |
|---|---|---|---|---|
| 0.1 | Çap/PDF: cavab açarı «A, A, A…» (bankda düz cavab 97 % birinci variantdır) | `muellim/app.js` `ppMix()` + `paperPrint`: variantlar test+sual toxumu ilə qarışdırılır, açar eyni massivdən qurulur. Onlayn test toxunulmayıb (server orada özü qarışdırır) | `test/e2e_sira0.py` C: köhnə kodda 30/30 «A» (SINIR), yenidə 9/30 «A»; açardakı hərf çap olunmuş sualda düz variant 30/30; ikinci çap eyni açar | JS: `main`-ə keçəndə |
| 0.2 | İki sinif seçiləndə başqa siniflərin sualı düşür | `db/929_generator_cox_sinif.sql`: 223-ün `generate_pick` gövdəsi hərfən, yalnız sinif şərti 103-dəki `levels` ilə | `db/test/smoke_cox_sinif.sql`: 929-suz SINIR («kənar sinifdən 17 sual»), 929 ilə keçir; generator/plan/dərs testi suite-ləri keçir | **SQL Editor-da 929 işlədilməlidir** |
| 0.3 | İcmal: «… zəif gedir» yanında həmişə 0 % | `app.js`: `tp.ratio` → `tp.avg` (server `db/219` «avg» verir) | `e2e_sira0.py` A: köhnə kodda 0 % (SINIR), yenidə 68 %, `#/zm` 67 % | JS: `main`-ə keçəndə |
| 0.4 | Generator: fənn dəyişəndə köhnə sinif seçili qalır | `app.js` `gsub` change: `f.levels = []` | `e2e_sira0.py` D: köhnədə 1 sinif qalırdı (SINIR), yenidə 0 | JS: `main`-ə keçəndə |
| 0.5 | «Çap / PDF» iki dəfə açılır | **Dəyişiklik yoxdur — xəta deyil.** Ölçmə səhvi idi: Playwright `evaluate("window.print = function(){…}")` ifadəsinin nəticəsi funksiya olduğu üçün onu özü bir dəfə çağırır | Stack izi: 1-ci çağırış `UtilityScript.evaluate`-dən, 2-ci düymədən. `e2e_sira0.py` B: bir basış = 1 çağırış | — |
| 0.6 | Canlıda «3-ci, 4-ci, 6-ci, 9-ci sinif» | `db/930_sinif_adi_sekilci.sql`: köhnə adlar `app.ordinal_az()` ilə yenidən yazılır (24.08 düzəlişi `on conflict do nothing` ucbatından canlıya çatmamışdı) | süni köhnə adlarla: 5 ad düzəlir, ikinci dəfə 0, əl ilə dəyişdirilmiş ad toxunulmur; `canli_yoxla.sql` 930 sətri `f` → `t` | **SQL Editor-da 930 işlədilməlidir** |

Canlı yoxlama: 929 və 930-dan sonra `db/test/canli_yoxla.sql` — «929 …» və «930 …» sətirləri `true` olmalıdır.

### Yolda tapılanlar
- `smoke_family.sql` 4j: «Bilmirəm» cavabları mövzu **adı** ilə silinirdi (`limit 1`); eyni adlı ikinci mövzu (başqa sinif) seçiləndə 3 cavab qalırdı, 8-ci bölmə «7 sual» əvəzinə 10 görürdü. UUID-dən asılı, təsadüfi. Düzəliş: mövzu id-si ilə silinir.
- İcmal (219: şagird faizlərinin ortası) və `#/zm` (220: bütün cavabların cəmi) **iki düstur** işlədir — 67/68 kimi 1–2 bənd fərq. Sıra 2-yə (tək mənbə).
- **Bank üçün:** `inf9-texnologiya#196` izahı «Birinci variantda …» yazır — onlayn testdə variantlar qarışdırıldığı üçün indidən səhvdir. Bankda variant hərfinə başqa həqiqi istinad tapılmadı (38 958 sual yoxlandı; «A və B», «Cavab: A ∪ B» kimi həndəsə/çoxluq işarələri təsirlənmir).
- Əvvəldən sınıq testlər (bu işdən asılı deyil): `e2e_gen.py`, `e2e_assign.py`, `e2e_numune.py` — köhnə interfeys seçiciləri (`#glevel`, `#groups .gcard`), yeni (YENI) interfeysdə qeydiyyatda ilişir; `smoke_paylas.sql` — 929-suz bazada da sınır; `e2e_sagird_hesabat.py` — `panel_e2e`-də keçir, sıfırdan qurulan bazada qeydiyyatda ilişir (929-suz bazada da).

## Sıra 1–5 — gözləyir

1. **Testin düzgünlüyü** — 0.1, 0.2, 0.4 bağlandı (yuxarı). Qalan: tək pis sualı əvəz etmək (vərəqdə).
2. **Hesabatın düzgünlüyü** — «zəif mövzu», «orta», «gedişat» bir sorğu və bir qayda; hər rəqəmdə dövr («bütün dövr» / «son 30 gün»); «test / sual / cavab» sözləri; az məlumatlı mövzu «ilkin nəticə · N sual · tarix» nişanı (çəki avtomatik dəyişmir); hesabat və Siqnallarda «ən zəifdən» sıra (davamiyyət və adi siyahı əlifba qalır).
3. **Alıcıların düzgünlüyü** — tövsiyədəki şagirdlərə hədəfli tapşırıq: seçim, saxlama (tapşırıq modeli indi yalnız qrup / tək şagird) və şagirdin gördüyü tapşırıqlar birlikdə; şəxsi testin səhvən qrupa verilməsinin qarşısı.
4. **İlk istifadə** — boş qrupda «Şagird əlavə et»; yapışdırma ilə toplu əlavə; kodların toplu kopyası və çapı; başlanğıc kartı işlək yola; qrupun sinfinə uyğun test; server xəta mətnlərində diakritika.
5. **Telefon** — başlıq bloku, şagird Xülasəsi, bölmələrarası keçidlər; təkrar yollar azalır, yerində olan «Təkrar ver» qalır.
