#!/usr/bin/env bash
# Butun SQL fayllarini duzgun sira ile isledir.
# Lokal yoxlama:  ./run.sh tehsil --local
# Supabase-de:    01..05 fayllarini SQL Editor-a bu sira ile yapisdir
#                 (test/ qovlugundakilari YOX).
set -euo pipefail
DB="${1:-tehsil}"; LOCAL="${2:-}"
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
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 07_seed_tests.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 16_bank_riy4.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 17_bank_sinif4.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 19_bank_riy3.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 20_bank_sinif3.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 23_bank_sinif1.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 24_bank_sinif2.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 25_movzular_orta5.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 26_bank_riy5.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 27_bank_sinif5.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 28_bank_ing.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 29_movzular_orta6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 30_bank_riy6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 31_bank_sinif6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 32_bank_fenn6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 33_movzular_orta7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 34_bank_riy7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 35_bank_sinif7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 36_bank_fenn7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 37_movzular_orta8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 38_bank_riy8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 39_bank_sinif8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 40_bank_fenn8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 41_movzular_orta9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 42_bank_riy9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 43_bank_sinif9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 44_bank_fenn9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 45_movzular_orta10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 46_bank_riy10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 47_bank_sinif10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 48_bank_fenn10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 49_movzular_orta11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 50_bank_riy11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 51_bank_sinif11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 52_bank_fenn11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 53_movzular_umumi_tarix.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 54_bank_tarix_umumi.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 55_movzular_edebiyyat11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 56_bank_edebiyyat11.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 57_sinif_dubli.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 58_movzular_edebiyyat9_10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 59_bank_edebiyyat10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 60_bank_edebiyyat9.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 61_movzular_edebiyyat5_8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 62_bank_edebiyyat5.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 63_bank_edebiyyat6.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 64_bank_edebiyyat7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 65_bank_edebiyyat8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 66_movzular_umumi_tarix6_8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 67_bank_tarix_umumi6_8.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 68_movzular_umumi_tarix10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 69_bank_tarix_umumi10.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 70_movzular_umumi_tarix7.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 71_bank_tarix_umumi7.sql
# Supabase-in default huquqlarini tekrarlayiriq ki, revoke-larin
# hequiqeten isledigini yoxlaya bilek
[ "$LOCAL" = "--local" ] && psql -v ON_ERROR_STOP=1 -q -d "$DB" -f test/01_grants.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 05_grants.sql
