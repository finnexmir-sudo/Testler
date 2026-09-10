# db/alet — əl ilə işlədilən skriptlər

Buradakı fayllar **miqrasiya deyil**. `run.sh` onları işlətmir və
işlətməməlidir — hər biri lazım olanda əl ilə, bir dəfəlik işlədilir.

| Fayl | Nə edir |
|---|---|
| `numune_doldur.sql` | Göstərmək üçün şəxsi hesabı nümunə məlumatı ilə doldurur: 3 qrup, 25 şagird, 45 günlük nəticə, dərs planı, davamiyyət, cədvəl, valideyn kodları. **Hesabın mövcud qrup və şagirdlərini silir.** |
| `bildiris_temizle.sql` | Nümunə hesabın «Bizə yaz» mesajlarını və sual bildirişlərini silir ki, admin səhifəsi göstərmə zamanı təmiz olsun. Başqa heç nəyə toxunmur. |

## numune_doldur.sql — işlətmədən əvvəl

Faylın başındakı `v_email` sətrində hesabın e-poçtu yazılıb. Başqa
hesabı doldurmaq istəsən, yalnız o sətri dəyiş.

Skript hesabı «nümunə» kimi işarələmir — yəni admin saylarında
görünməyə davam edir və 24 saatlıq təmizləməyə düşmür.

## bildiris_temizle.sql — nə üçün ayrıca fayldır

`app.demo_build` nümunə olaraq bir təklif və bir sual bildirişi yazır;
onlar admin səhifəsindəki siyahılarda görünür. `numune_doldur.sql`
artıq sonda onları özü silir — bu ayrıca fayl isə həmin skripti
təzədən işlətmək istəmədikdə lazımdır, çünki təzədən işlətsən
şagird və valideyn kodları dəyişir.

«Sual keyfiyyəti» kartı buradan gəlmir: o, şagird cavablarından
hesablanır (`rpc_admin_qstats`), silinəsi sətir yoxdur.
