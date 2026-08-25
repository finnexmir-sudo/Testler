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
# Supabase-in default huquqlarini tekrarlayiriq ki, revoke-larin
# hequiqeten isledigini yoxlaya bilek
[ "$LOCAL" = "--local" ] && psql -v ON_ERROR_STOP=1 -q -d "$DB" -f test/01_grants.sql
psql -v ON_ERROR_STOP=1 -q -d "$DB" -f 05_grants.sql
