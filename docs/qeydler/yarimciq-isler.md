# Qeydlər: Yarımçıq işlər (2FA, bank public repo, ödəniş şlüzü, növbəti il planı, xırdalar)

> CLAUDE.md-dən köçürülüb (08.10.2026). Mətn dəyişməyib — yalnız yeri. Qısa indeks: `CLAUDE.md` → «Qeydlər».

## YARIMÇIQ İŞLƏR — iş arasında xatırlat

İstifadəçi bunları özü istəyib. **Boş vaxt olanda, yaxud mövzu
yaxınlaşanda xatırlat** — hər dəfə deyil, yerinə düşəndə.

### 0. Növbəti tədris ilinə plan — keyfiyyət hədəfi (2026-09-29, razılaşdırılıb)

**İstifadəçi hədəfi:** növbəti tədris ilinə qədər «tam optimal və sınaqdan
keçmiş» proqram. Müştəri cəlbi HƏLƏLİK prioritet DEYİL. Əsası beynəlxalq
araşdırma (ASSISTments, Sparx, Eedi, Yang 2021, Rohrer 2020, Bergman&Chan,
Bastani/PNAS və s.) — nəticələr söhbətdə verilib. Əsas müşahidə: uğuru
texnologiya yox, **ritm** (müəllimdən az zəhmət) və **ölçmə** həll edir.

İstifadəçinin qərarları (nömrə söhbətdəki təklif nömrəsidir):

1. **Avtomatik həftəlik tapşırıq (qarışıq təkrar).** İSTİFADƏÇİ: abunəlikdə
   şagirdin «istədiyi qədər test yığması» yox, **proqramın ona verdiyi**
   testləri işləməsi olsun — əlində olan şey maraqsız gəlir, gözləmə
   maraqlı edir («filan gün gəlsəm hansı test düşəcək?»). Yəni şagird
   tərəfdə seçim yerinə **proqramın təyin etdiyi növbəti test + «sabah/bu
   cümə nə düşəcək» ipucu**. Müəllim tərəfdə: bir dəfə qurur, hər həftə
   özü gedir (son 3–4 həftənin mövzuları qarışıq — fasilələrlə/qarışıq
   təkrar, sübutlu). Açıq qalan sual: şagirdin sərbəst məşq imkanı qalsınmı
   (Sparx-da «Independent learning» ayrıca sahə var) — istifadəçi «yerinə»
   dedi, ona görə susmaya görə **proqram verir**; sərbəst hissəni ayrıca
   müzakirə edirik.
2. **Pilot və ölçmə.** Bəyənildi. İSTİFADƏÇİ: gözləmə üçün əlverişlidir,
   «semestr suallarını necə verəcəyəm» — yəni əvvəl-sonra ölçmə **ilkin
   diaqnostik test + semestr sonu eyni səviyyəli test** ilə. 3–5 repetitorla
   bir rüb. Admin paneli: həftəlik aktiv şagird, tapşırığı tamamlama faizi,
   zəif mövzuda təkrar cəhddə irəliləyiş.
3. **Təxmin qorunması** — İSTİFADƏÇİ qərarı MƏNƏ verdi: EDİLƏCƏK. «Tələsik»
   cavablar zəif mövzu/mənimsəmə hesabına girmir, müəllimə ayrıca görünür.
4. **İzahı ən çox səhv edilən suallara yazmaq** (real cavab məlumatına görə,
   zamanla) — bəyənildi. Yalnız DÜZGÜN işlənmiş nümunə (öz-özünə izah
   tapşırığı əlavə etmək nəticəni pisləşdirib).
5. **Valideynə həftəlik xülasə** — mənə verildi: **ayrı «Valideynlər»
   səhifəsində**, müəllim istəsə, bir toxunuşla hazır WhatsApp mətni;
   susmaya görə söndürülü, əsas ekranı dolaşdırmır (istifadəçi əvvəl
   WhatsApp düymələrinin yer tutub səhifəni korladığını demişdi).
   Avtomatik göndərmə YOX (xarici şəbəkə qadağası).
6. **Zəif şəbəkədə real sınaq** — istifadəçi başa düşmədi, qərar mənə
   verildi: EDİLƏCƏK. Mənası: ucuz Android telefonda və zəif internetdə
   oflayn PWA-nın real yoxlanması.
7. **Səhv bildirişlərindən keyfiyyət dövrü** — olar.

**ETMƏMƏK:** süni intellekt söhbəti (çərçivəsiz öyrənməyə zərər verir),
xal/nişan oyunlaşdırması (təsir 1–3 aydan sonra sıfıra düşür), yeni
funksiyalar pilotdan ƏVVƏL.

**Vaxt xətti (təklif):** okt–dek: 1, 2, 3 · yan–fev: pilot · mart–may: 4, 7, 6
· iyun–avq: cilalama + e-dərslik yenilənməsi · sentyabr: buraxılış.

### 1. 2FA — ən yüksək prioritet (2026-09-09, «sabah edəcəm»)

Üç hesabda ikinci amil YOXDUR. Ən təhlükəli yol: **GitHub parolu
oğurlanarsa** yad adam `main`-ə push edir və **bil10.az onun kodunu
verir** — müəllim parolunu oğurlayan səhifə qoya bilər.

- **GitHub** → Settings → Password and authentication → Two-factor
  authentication → **Authenticator app** (SMS YOX — SIM dəyişdirmə ilə
  keçilir)
- **Supabase** → Account settings → Security → Enable MFA
- **Cloudflare** → My Profile → Authentication → 2FA
- **Domen qeydiyyatçısı** (bil10.az)

**Ehtiyat kodları mütləq kağızda saxlansın.** Ən çox düşülən tələ:
2FA açıb telefonu itirmək və öz layihəsindən kilidlənmək — GitHub-da
bərpa uzun sürür, o müddətdə canlı sayta push edilə bilmir.

İzah üçün istinad: **istifadəçi bunu onsuz da bilir** — `db/24_admin_2fa.sql`
Bil10-un öz 2FA-sıdır (TOTP + birtəfəlik ehtiyat kodlar), İdarəetmə →
Təhlükəsizlik. GitHub-dakı eyni mexanizmdir.

2FA **nədən qorumur**: artıq verilmiş OAuth icazələri (vaxtaşırı
GitHub → Settings → Applications yoxlanmalıdır) və sızmış
`service_role` açarı (onu **dəyişmək** lazımdır, Supabase → API).

### 2. Bank məzmunu public repo tarixçəsində (2026-09-09 ölçüldü)

**116 blob, ~10,3 MB** köhnə commitlərdə. İndiki `main` **təmizdir** —
oradakı 3 «bank» faylı koddur (`12_bank_rpc`, `29_bank_katalog`,
`106_bank_siyahi_variantlar`), sual yoxdur.

43 fayldan 35-i onsuz da `bil10-bank`-dadır; yalnız tarixçədə olanlar:
`23_bank_sinif1` · `24_bank_sinif2` · `26_bank_riy5` · `27_bank_sinif5`
· `28_bank_ing`. Suallar Supabase-də işləyir, itki yoxdur.

Plan (istifadəçi «et» deməyincə BAŞLAMA): ehtiyat mirror → o 5 faylı
`bil10-bank`-a çıxart → `git filter-repo` ilə bütün bank fayllarını
tarixçədən sil → force-push. Kod tarixçəsi qalır, yalnız hash-lar
dəyişir. **Bank sessiyasının da klonu var — əvvəlcə ona xəbər
verilməlidir.** GitHub köhnə obyektləri saxlayır (tam təmizlik üçün
dəstəyə yazmaq lazımdır), artıq klonlamış adamda nüsxə qalır.

`service_role` açarı tarixçədə **YOXDUR** — 4 849 blob tarandı,
0 tapıntı (2026-09-09).

### 3. `rpc_student_login`-də sürət məhdudiyyəti yoxdur

Kod: 31 hərflik əlifba × 8 = **853 milyard** variant, ~20 şagirdlə
tutma şansı 43 milyarda 1 — **bu gün real təhlükə deyil**. Şagird sayı
on minlərə çatanda əlavə edilməlidir.

### 4. Ödəniş şlüzü (Epoint + Supabase Edge Function)

Hazırda abunə yalnız admin panelindən əl ilə verilir. ~20 ödəyən
müştəriyə qədər dözülür. «Pul işi — 100 ölç, bir biç» qaydası tətbiq
olunmalıdır.

### 5. Xırda, hazır olanda

- Abunə bitmə xəbərdarlığı **yalnız ekrandadır** — e-poçt getmir
- Güzəşt bitəndən sonra ekranda izah itir (plan qaytarılmır)
- Ödəniş tarixçəsi/qəbz müəllimə görünmür
- Hüquqi tərəf: ictimai oferta, qaytarma qaydası
- Qiymət ana səhifədə yazılmayıb (`SHOW_PLANS: false`)
- Məktəb axını (`mekteb` planı) sınaqdan keçməyib
- `attempt_answers` sonsuz böyüyür — arxivləşdirmə planı
- İdarəetmə: bölmə naviqasiyası · paket bölgüsü qrafiki · «Son
  ziyarətlər» siyahısı
- Yan menyu — istifadəçi bəyəndiyi dizayn tapanda (2026-09-09-da
  sınandı, «pis deyil, amma o deyil», geri qaytarıldı)
