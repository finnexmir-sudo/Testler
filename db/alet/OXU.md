# db/alet — əl ilə işlədilən skriptlər

Buradakı fayllar **miqrasiya deyil**. `run.sh` onları işlətmir və
işlətməməlidir — hər biri lazım olanda əl ilə, bir dəfəlik işlədilir.

| Fayl | Nə edir |
|---|---|
| `numune_doldur.sql` | Göstərmək üçün şəxsi hesabı nümunə məlumatı ilə doldurur: 3 qrup, 25 şagird, 45 günlük nəticə, dərs planı, davamiyyət, cədvəl, valideyn kodları. **Hesabın mövcud qrup və şagirdlərini silir.** |

## numune_doldur.sql — işlətmədən əvvəl

Faylın başındakı `v_email` sətrində hesabın e-poçtu yazılıb. Başqa
hesabı doldurmaq istəsən, yalnız o sətri dəyiş.

Skript hesabı «nümunə» kimi işarələmir — yəni admin saylarında
görünməyə davam edir və 24 saatlıq təmizləməyə düşmür.
