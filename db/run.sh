#!/usr/bin/env bash
# Butun SQL fayllarini duzgun sira ile isledir.
# Lokal yoxlama:  ./run.sh tehsil --local
# Supabase-de:    01..05 fayllarini SQL Editor-a bu sira ile yapisdir
#                 (test/ qovlugundakilari YOX).
set -euo pipefail
DB="${1:-tehsil}"; LOCAL="${2:-}"
#  Bank MEZMUN fayllari private bil10-bank repo-sundadir (symlink ile
#  gelir).  Fayl yoxdursa DAYANMIRIQ - xeberdarliqla atlayirig.  Sebeb:
#  2026-09-07 141-158 setirleri elave olundu, yerli qovluqda fayl yox idi,
#  set -e ile run.sh yarida kesildi, 01/05_grants islemedi ve harness
#  RLS-siz bazada "kecdi" - sessiz tehluke.
bank() {
  if [ -f "$1" ]; then psql -v ON_ERROR_STOP=1 -q -d "$DB" -f "$1"
  else echo "  !! bank fayli yoxdur, atlandi: $1  (../bil10-bank klonla, symlink qur)" >&2; fi
}
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f test/00_supabase_stub.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 01_schema.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 02_rls.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 03_rpc.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 06_educator_rpc.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 09_assignments.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 12_bank_rpc.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 13_generator.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 04_seed.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 14_movzular.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 15_movzular_ederslik.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 08_reports.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 18_siqnal.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 21_paket.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 22_esas.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 23_bildiris.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 24_admin_2fa.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 25_ders_plani.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 26_fenn.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 27_hesabat.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 28_ferdi_tapsiriq.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 29_bank_katalog.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 100_seviyye_modeli.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 101_ders_plani_alt.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 102_movzu_qoruyucu.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 103_cox_sinif.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 104_cavabsiz_sual.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 105_alt_movzu_duzelisleri.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 106_bank_siyahi_variantlar.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 107_valideyn.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 108_valideyn_duzelis.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 109_duzelis_nisani.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 110_valideyn_duzelis_nisani.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 111_admin_test_sayi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 112_asagi_sinif_testleri.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 113_valideyn_huquq_berpa.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 114_sagird_paneli_zenginlesdirme.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 115_sagird_kecdiyi_dersler.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 116_sagird_tam_netice.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 117_sagird_tam_netice_submit.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 118_diaqnostika.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 119_diaqnostika_qoruyucu.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 120_icmal_diaqnostikasiz.sql
#  121 yer tutucu testi gizledir - yerli testler onu acıq gozleyir
[ "$LOCAL" = "--local" ] || psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 121_numune_test_gizli.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 122_bize_yaz.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 123_teyinat_ikili.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 124_qisa_ad_tekrar.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 125_admin_giris.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 126_bu_gunun_dersi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 127_ad_sirasi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 128_cavab_terzi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 129_sehv_defteri.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 130_davamiyyet.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 131_ferdi_plan.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 132_parametrik_sual.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 133_adaptiv_mesq.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 134_sual_keyfiyyeti.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 135_kurikulum_paketi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 136_numune_hesab.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 137_mesq_limit.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 138_sinaq_abune.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 139_numune_admin_gizli.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 140_numune_bize_yaz_gizli.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 159_demo_hedd.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 160_hediyye_paket.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 161_ziyaret.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 162_ziyaret_huni.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 163_icmal_liderler.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 164_sagird_sessiya_30gun.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 165_sagird_basi_qiymet.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 166_baki_vaxti.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 167_liderler_qrup_uzre.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 168_hediyye_bir_ay.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 169_sagird_basi_hediyye.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 170_hediyye_uzun_duzelis.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 171_kohne_sinaqlar_sagird_basi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 172_odenis_baslangici.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 173_admin_ekrani.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 174_valideyn_abune.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 175_oz_girisim.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 176_qiymet_metni.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 177_cedvel.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 178_sinif_mesaji.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 179_baza_olcusu.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 180_suret.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 181_suret_duzelis.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 07_seed_tests.sql
bank 16_bank_riy4.sql
bank 17_bank_sinif4.sql
bank 19_bank_riy3.sql
bank 20_bank_sinif3.sql
bank 75_bank_sinif1.sql
bank 76_bank_sinif2.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 77_movzular_orta5.sql
bank 78_bank_riy5.sql
bank 79_bank_sinif5.sql
bank 80_bank_ing.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 81_movzular_orta6.sql
bank 30_bank_riy6.sql
bank 31_bank_sinif6.sql
bank 32_bank_fenn6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 33_movzular_orta7.sql
bank 34_bank_riy7.sql
bank 35_bank_sinif7.sql
bank 36_bank_fenn7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 37_movzular_orta8.sql
bank 38_bank_riy8.sql
bank 39_bank_sinif8.sql
bank 40_bank_fenn8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 41_movzular_orta9.sql
bank 42_bank_riy9.sql
bank 43_bank_sinif9.sql
bank 44_bank_fenn9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 45_movzular_orta10.sql
bank 46_bank_riy10.sql
bank 47_bank_sinif10.sql
bank 48_bank_fenn10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 49_movzular_orta11.sql
bank 50_bank_riy11.sql
bank 51_bank_sinif11.sql
bank 52_bank_fenn11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 53_movzular_umumi_tarix.sql
bank 54_bank_tarix_umumi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 55_movzular_edebiyyat11.sql
bank 56_bank_edebiyyat11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 57_sinif_dubli.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 58_movzular_edebiyyat9_10.sql
bank 59_bank_edebiyyat10.sql
bank 60_bank_edebiyyat9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 61_movzular_edebiyyat5_8.sql
bank 62_bank_edebiyyat5.sql
bank 63_bank_edebiyyat6.sql
bank 64_bank_edebiyyat7.sql
bank 65_bank_edebiyyat8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 66_movzular_umumi_tarix6_8.sql
bank 67_bank_tarix_umumi6_8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 68_movzular_umumi_tarix10.sql
bank 69_bank_tarix_umumi10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 70_movzular_umumi_tarix7.sql
bank 71_bank_tarix_umumi7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 72_bos_fennler.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 73_buraxilis_proqrami.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 74_alt_movzular_riy8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 82_alt_movzular_riy5_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 83_alt_movzular_riy1_4.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 84_alt_movzular_hb1_4.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 85_alt_movzular_inf1_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 86_alt_movzular_fizika6_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 87_alt_movzular_kimya7_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 88_alt_movzular_biologiya6_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 98_cografiya11_enerji_erzaq_duzelis.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 90_alt_movzular_cografiya6_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 91_alt_movzular_edebiyyat5_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 92_alt_movzular_tarix5_8_9_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 93_alt_movzular_utarix6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 94_umumi_tarix_8_9_11_restruktur.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 95_alt_movzular_utarix7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 96_alt_movzular_utarix8_9_11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 97_alt_movzular_utarix10.sql
bank 99_bank_ingilis8_788.sql
# 89, digerlerinden ferqli olaraq, BURADA (99-dan sonra) islenir - 8-ci
# sinif alt-movzulari 99-un yaratdigi/adini deyisdiyi movzulara baglanir
# (94-den sonra 96-nin islenmesi ile eyni sebeb).
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 89_alt_movzular_ingilis6_11.sql
bank 118_bank_umumi_tarix_bosluqlar.sql
bank 112_bank_cetin_birlesme.sql
# 141-158: bank sessiyasinin movzu-uygunsuzluq/bosluq duzelisleri
# (2026-09-07 nomre razilasmasi, CLAUDE.md "db/ fayl nomreleri").
bank 141_bank_cografiya6_dunya_ictimai.sql
bank 142_bank_bio11_insan_muhit_duzelis.sql
bank 143_bank_tarix11_mustemleke_cenub.sql
bank 144_bank_inf11_komputer_veb_duzelis.sql
bank 145_bank_kim11_aldehid_izomer.sql
bank 146_bank_fiz7_skalyar_vektorial.sql
bank 147_bank_hey4_dini_deyerler.sql
bank 148_bank_utarix8_qafqaz_medeniyyet.sql
bank 149_bank_inf4_kompyuter_duzelis.sql
bank 150_bank_inf3_alqoritm_obyekt.sql
bank 151_bank_inf3_metn_duzelis.sql
bank 152_bank_inf8_kompyuter_tetbiqi_duzelis.sql
bank 153_bank_inf8_internet_sebeke.sql
bank 154_bank_inf11_sistemler_bosluqlar.sql
bank 155_bank_inf3_informasiya_bosluqlar.sql
bank 156_bank_inf3_kompyuter_is_masasi_qovluq.sql
bank 157_bank_inf10_informasiya_miqdari.sql
bank 158_bank_inf11_modellesdirme_bosluqlar.sql
# 200-299: bank sessiyasinin YENI nomre araligi (2026-09-08 razilasmasi) -
# 141-158 bitib, kod sessiyasi ile toqqusma olmasin deye ayrica diapazon
# verildi (kod fayllari 199-a qeder).
bank 201_bank_cog8_hidrosfer_biosfer.sql
bank 202_bank_hey4_alt_movzu_temizlik.sql
bank 203_bank_tarix_cetin_norma.sql
bank 204_bank_riy1_cetin_norma.sql
bank 205_bank_riy5_10_cetin_norma.sql
bank 206_bank_informatika1_4_cetin_norma.sql
bank 207_bank_informatika5_8_cetin_norma.sql
bank 208_bank_informatika9_11_cetin_norma.sql
bank 209_bank_azdili1_cetin_norma.sql
bank 210_bank_azdili2_cetin_norma.sql
bank 211_bank_azdili3_cetin_norma.sql
bank 212_bank_azdili4_cetin_norma.sql
bank 213_bank_azdili5_cetin_norma.sql
bank 214_bank_azdili6_cetin_norma.sql
bank 215_bank_azdili7_cetin_norma.sql
bank 216_bank_azdili8_cetin_norma.sql
bank 217_bank_azdili9_cetin_norma.sql
bank 218_bank_azdili10_cetin_norma.sql
bank 219_bank_azdili11_cetin_norma.sql
bank 220_bank_ingilis1_cetin_norma.sql
bank 221_bank_ingilis2_cetin_norma.sql
bank 222_bank_ingilis3_cetin_norma.sql
bank 223_bank_ingilis4_cetin_norma.sql
bank 224_bank_ingilis5_cetin_norma.sql
bank 225_bank_ingilis6_cetin_norma.sql
bank 226_bank_ingilis7_cetin_norma.sql
bank 227_bank_ingilis8_cetin_norma.sql
bank 228_bank_ingilis9_cetin_norma.sql
bank 229_bank_ingilis10_cetin_norma.sql
bank 230_bank_ingilis11_cetin_norma.sql
bank 231_bank_riy2_4_cetin_norma.sql
bank 232_bank_cografiya_cetin_norma.sql
bank 233_bank_biologiya_cetin_norma.sql
bank 234_bank_fizika_cetin_norma.sql
bank 235_bank_kimya_cetin_norma.sql
# Supabase-in default huquqlarini tekrarlayiriq ki, revoke-larin
# hequiqeten isledigini yoxlaya bilek
[ "$LOCAL" = "--local" ] && psql -v ON_ERROR_STOP=1 -q -d "$DB" -f test/01_grants.sql
#  160: yerli test bazasinda hediyye paket SONDURULUR - e2e/smoke-lerin pulsuz
#  hedd (0 / 5) yoxlamalari pozulmasin; smoke_hediyye ve e2e_panel ozu acir.
[ "$LOCAL" = "--local" ] && psql -v ON_ERROR_STOP=1 -q -d "$DB" -c "update public.app_state set val = val || jsonb_build_object('on', false) where key = 'hediyye'"
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 05_grants.sql
# Statistika toplanir.  Teze qurulmus bazada planlayicinin hec bir
# statistikasi olmur ve TAM BASQA plan secir: olcduk, rpc_bank_facets
# 620 ms cekirdi, "analyze"den sonra 20 ms.  Yeni surat olcen her kes
# (biz de daxil) bu tələyə dusurdu.  251 ms cekir - pulsuzdur.
psql -v ON_ERROR_STOP=1 -q -d "$DB" -c "analyze;"
