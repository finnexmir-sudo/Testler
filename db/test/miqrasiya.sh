#!/usr/bin/env bash
#  Teze qurulmus baza ile MIQRASIYA olunmus baza eyni netice vermelidir.
#  Bir defe ferqli oldu: 11 qismen unikal indeks yaradirdi, 01 ise tam -
#  ve "on conflict (ext_key)" yalniz canli bazada sindi (42P10).
set -euo pipefail
cd "$(dirname "$0")/.."
export PGHOST=${PGHOST:-/tmp} PGPORT=${PGPORT:-55432} PGUSER=${PGUSER:-postgres}
#  Sual bankindan ONCEKI commit - SABIT olmalidir.  Evvel HEAD~12 yazilmisdi,
#  amma her yeni commit onu suruyurdu ve gunun birinde "kohne baza" artiq
#  banki olan bazaya cevrildi - migrasiya oz uzerinden isleyib sindi.
OLD=${1:-554e09a}
WT=$(mktemp -d)
trap 'git worktree remove --force "$WT" >/dev/null 2>&1 || true' EXIT

git -C .. worktree add -q -f "$WT" "$OLD" 2>/dev/null || \
  git worktree add -q -f "$WT" "$OLD"

dropdb --if-exists miq_test 2>/dev/null || true; createdb miq_test
( cd "$WT/db" && ./run.sh miq_test >/dev/null 2>&1 )
echo "kohne baza quruldu ($OLD)"

for f in 11_sual_banki.sql 12_bank_rpc.sql 13_generator.sql 14_movzular.sql \
         15_movzular_ederslik.sql \
         07_seed_tests.sql 16_bank_riy4.sql 17_bank_sinif4.sql 19_bank_riy3.sql \
         20_bank_sinif3.sql 23_bank_sinif1.sql 24_bank_sinif2.sql \
         25_movzular_orta5.sql 26_bank_riy5.sql 27_bank_sinif5.sql \
         28_bank_ing.sql 29_movzular_orta6.sql 30_bank_riy6.sql \
         31_bank_sinif6.sql 32_bank_fenn6.sql 33_movzular_orta7.sql \
         34_bank_riy7.sql 35_bank_sinif7.sql 36_bank_fenn7.sql \
         37_movzular_orta8.sql 38_bank_riy8.sql 39_bank_sinif8.sql \
         40_bank_fenn8.sql 41_movzular_orta9.sql 42_bank_riy9.sql 43_bank_sinif9.sql \
         44_bank_fenn9.sql 45_movzular_orta10.sql 46_bank_riy10.sql \
         47_bank_sinif10.sql 48_bank_fenn10.sql 49_movzular_orta11.sql \
         50_bank_riy11.sql \
         08_reports.sql 18_siqnal.sql 21_paket.sql 22_esas.sql 05_grants.sql; do
  printf "  %-22s" "$f"
  if psql -v ON_ERROR_STOP=1 -q -d miq_test -f "$f" >/dev/null 2>/tmp/miq.err; then
    echo "OK"
  else
    echo "XETA"; tail -3 /tmp/miq.err; exit 1
  fi
done

echo "--- sxem teze baza ile eynidirmi ---"
dropdb --if-exists miq_teze 2>/dev/null || true; createdb miq_teze
./run.sh miq_teze >/dev/null 2>&1
for db in miq_teze miq_test; do
  psql -Atq -d "$db" -c "
    select 'IDX '||indexdef from pg_indexes
     where schemaname='public' and tablename='questions'
     union all select 'COL '||table_name||'.'||column_name||':'||data_type
       from information_schema.columns
      where table_schema='public' and table_name in ('questions','test_questions','attempt_answers')
     order by 1" > "/tmp/$db.txt"
done
if diff -q /tmp/miq_teze.txt /tmp/miq_test.txt >/dev/null; then
  echo "  OK   teze ve miqrasiya olunmus sxem eynidir"
else
  echo "  FERQ:"; diff /tmp/miq_teze.txt /tmp/miq_test.txt | head -20; exit 1
fi
