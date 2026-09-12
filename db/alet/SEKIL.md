# Suala şəkil qoşmaq (db/188)

Bank sualına həndəsə cizgisi, elektrik dövrəsi, blok-sxem qoşmaq üçün
**inline SVG** işlədilir. Xarici fayl yoxdur: şəkil sualın öz sətrində,
`media_url` sütununda saxlanır. Ona görə şəbəkə sorğusu getmir, oflayn
işləyir, çapda çıxır.

## Necə yazılır

```sql
update public.questions
   set media_url = app.svg_uri($$
<svg viewBox="0 0 200 130" xmlns="http://www.w3.org/2000/svg">
  <path d="M20 110 L180 110 L60 20 Z" fill="none" stroke="#1a2233" stroke-width="2.5"/>
  <text x="26" y="104" font-family="sans-serif" font-size="13" fill="#1a2233">A</text>
  <text x="172" y="104" font-family="sans-serif" font-size="13" fill="#1a2233">B</text>
  <text x="56" y="16" font-family="sans-serif" font-size="13" fill="#1a2233">C</text>
</svg>$$)
 where ext_key = 'riy7-ucbucaq#3';
```

`app.svg_uri()` xam SVG-ni data-URI-yə çevirir — əl ilə kodlaşdırmaq
lazım deyil.

## Qaydalar

1. **`viewBox` məcburidir**, `width`/`height` yazılmır — şəkil ekranın
   eninə uyğunlaşır. Nisbət təxminən 3:2 və ya 4:3 olsun.
2. **Rənglər açıq yazılır.** `currentColor` işləmir: şəkil `<img>` ilə
   çəkilir, səhifənin rəngini görmür. Cizgi `#1a2233`, vurğu `#2b4acb`,
   ikinci vurğu `#0e9384`. Fon verilmir — ağ üzərində oxunmalıdır.
3. **Yazı**: `font-family="sans-serif"`, ölçü ən azı 12. Azərbaycan
   hərfləri (ə, ş, ğ) işləyir, amma **mətnin ağırlığını SVG-yə yığmayın** —
   sualın şərti `body` sahəsində qalsın, şəkildə yalnız etiketlər olsun
   (A, B, C, 30°, R₁).
4. **Ölçü həddi**: kodlaşdırılmış unvan 24 000 simvoldan böyük ola
   bilməz (baza qəbul etmir). Praktikada 3 KB-dan kiçik saxlayın —
   şagirdin telefonu bunu hər sualla birlikdə yükləyir.
5. **Qadağan**: `<script>`, `on...=` hadisələri, `<foreignObject>`,
   `<image>`, xarici `href`/`xlink:href`, base64 şəkil. Baza da bunları
   rədd edir (`questions_media_ok`), amma çəkəndə də yazmayın.
6. **Yalnız platforma sualı** şəkil daşıya bilər. Müəllimin öz sualına
   `media_url` yazmaq olmaz — baza icazə vermir.
7. **Şəkil olmasa da sual anlaşılmalıdır** — mümkün olan yerdə. «Şəkildə
   göstərilən üçbucaqda…» əvəzinə «ABC üçbucağında A bucağı 40°-dir…»
   yazın; şəkil onda köməkçi olur, şərt olmur. Şəkil sınsa da (köhnə
   brauzer, çap) şagird ilişib qalmır.

## Yoxlama

```sql
--  Sekli olan suallar
select ext_key, length(media_url) from public.questions
 where media_url is not null order by 2 desc limit 20;
```

## Hansı ekranda görünür

**İndi işləyir:**

| Ekran | Kimin |
|---|---|
| Test işləmə (sual + variantlar) | şagird |
| Mövzu məşqi, adaptiv məşq | şagird |
| Səhv dəftəri | şagird |
| Sual bankı siyahısı | müəllim |
| Sualın öz səhifəsi / redaktə | müəllim |
| Generatorun nümunə sualları | müəllim |
| Test önizləmə və **kağız vərəq (çap)** | müəllim |

**Hələ işləmir** (ayrıca iş): testi bitirəndən sonrakı **nəticə baxışı** və
müəllimin **şagird hesabatı**. Səbəb texnikidir: o ekranlar sualın mətnini
`attempt_answers` cədvəlindəki anlıq nüsxədən götürür (cəhd anındakı
vəziyyət saxlanılır), sual cədvəlinə baxmır. Şəkli ora çıxarmaq üçün ya
şəkli də nüsxəyə yazmaq, ya da suala qoşulmaq lazımdır — bu, bal
tarixçəsinə toxunan qərardır. Ekran kodu hazırdır: gələn gün payload
şəkli gətirəndə özü çəkəcək.

## Yoxlama

```sql
--  Şəkli olan suallar
select ext_key, length(media_url) from public.questions
 where media_url is not null order by 2 desc limit 20;
```

Testlər: `db/test/smoke_sual_sekli.sql` (bazadakı qapılar),
`test/e2e_sekil.py` (şagird görür, müəllim görür, pis ünvan çəkilmir).
