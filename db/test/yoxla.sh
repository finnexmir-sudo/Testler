#!/usr/bin/env bash
# Butun SQL smoke testlerini isledir.
#
# NIYE HER DEFE BAZANI YENIDEN QURURUQ:
#   smoke_educator.sql muellim panelini yoxlayarken testleri ve suallari
#   silir.  Ondan sonra isleyen suite platforma testlerini tapa bilmir
#   ve "Test tapilmadi" verir - kod dogru olsa bele.  Suite-ler bir-birine
#   qarismasin deye her biri TEMIZ bazada isleyir.
#
#   ./test/yoxla.sh          -> tehsil_t bazasinda
#   ./test/yoxla.sh mybaza
set -uo pipefail
cd "$(dirname "$0")/.."
DB="${1:-tehsil_t}"
SUITES=(smoke.sql smoke_educator.sql smoke_reports.sql smoke_assign.sql smoke_siqnal.sql smoke_paket.sql smoke_bildiris.sql smoke_plani.sql
        smoke_fenn.sql smoke_hesabat.sql smoke_ferdi.sql smoke_bank.sql smoke_bank_rpc.sql smoke_generator.sql)
umumi=0; xeta=0
for s in "${SUITES[@]}"; do
  dropdb --if-exists "$DB" >/dev/null 2>&1
  createdb "$DB"
  ./run.sh "$DB" --local >/dev/null 2>&1
  printf "  %-24s" "$s"
  if psql -v ON_ERROR_STOP=1 -q -d "$DB" -f "test/$s" >/tmp/yoxla.out 2>&1; then
    n=$(grep -cE '^OK' /tmp/yoxla.out)
    umumi=$((umumi + n)); echo "$n OK"
  else
    xeta=$((xeta + 1)); echo "XETA"; tail -8 /tmp/yoxla.out
  fi
done
dropdb --if-exists "$DB" >/dev/null 2>&1
echo
if [ "$xeta" -gt 0 ]; then echo "$xeta suite XETA verdi"; exit 1; fi
echo "cemi $umumi yoxlama - hamisi kecdi"
