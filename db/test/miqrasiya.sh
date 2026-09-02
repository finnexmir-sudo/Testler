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
         20_bank_sinif3.sql 75_bank_sinif1.sql 76_bank_sinif2.sql \
         77_movzular_orta5.sql 78_bank_riy5.sql 79_bank_sinif5.sql \
         80_bank_ing.sql 81_movzular_orta6.sql 30_bank_riy6.sql \
         31_bank_sinif6.sql 32_bank_fenn6.sql 33_movzular_orta7.sql \
         34_bank_riy7.sql 35_bank_sinif7.sql 36_bank_fenn7.sql \
         37_movzular_orta8.sql 38_bank_riy8.sql 39_bank_sinif8.sql \
         40_bank_fenn8.sql 41_movzular_orta9.sql 42_bank_riy9.sql 43_bank_sinif9.sql \
         44_bank_fenn9.sql 45_movzular_orta10.sql 46_bank_riy10.sql \
         47_bank_sinif10.sql 48_bank_fenn10.sql 49_movzular_orta11.sql \
         50_bank_riy11.sql 51_bank_sinif11.sql 52_bank_fenn11.sql \
         53_movzular_umumi_tarix.sql 54_bank_tarix_umumi.sql \
         55_movzular_edebiyyat11.sql 56_bank_edebiyyat11.sql \
         57_sinif_dubli.sql 58_movzular_edebiyyat9_10.sql \
         59_bank_edebiyyat10.sql 60_bank_edebiyyat9.sql \
         61_movzular_edebiyyat5_8.sql 62_bank_edebiyyat5.sql \
         63_bank_edebiyyat6.sql 64_bank_edebiyyat7.sql \
         65_bank_edebiyyat8.sql 66_movzular_umumi_tarix6_8.sql \
         67_bank_tarix_umumi6_8.sql 68_movzular_umumi_tarix10.sql \
         69_bank_tarix_umumi10.sql 70_movzular_umumi_tarix7.sql \
         71_bank_tarix_umumi7.sql 72_bos_fennler.sql \
         73_buraxilis_proqrami.sql 74_alt_movzular_riy8.sql \
         82_alt_movzular_riy5_11.sql 83_alt_movzular_riy1_4.sql \
         84_alt_movzular_hb1_4.sql 85_alt_movzular_inf1_11.sql \
         86_alt_movzular_fizika6_11.sql \
         87_alt_movzular_kimya7_11.sql \
         88_alt_movzular_biologiya6_11.sql \
         89_alt_movzular_ingilis6_11.sql \
         90_alt_movzular_cografiya6_11.sql \
         91_alt_movzular_edebiyyat5_11.sql \
         92_alt_movzular_tarix5_8_9_11.sql \
         93_alt_movzular_utarix6.sql \
         94_umumi_tarix_8_9_11_restruktur.sql \
         08_reports.sql 18_siqnal.sql 21_paket.sql 22_esas.sql \
         23_bildiris.sql 24_admin_2fa.sql 25_ders_plani.sql 26_fenn.sql \
         27_hesabat.sql 28_ferdi_tapsiriq.sql 29_bank_katalog.sql \
         100_seviyye_modeli.sql 101_ders_plani_alt.sql 102_movzu_qoruyucu.sql \
         103_cox_sinif.sql 104_cavabsiz_sual.sql \
         105_alt_movzu_duzelisleri.sql 106_bank_siyahi_variantlar.sql \
         107_valideyn.sql 108_valideyn_duzelis.sql \
         109_duzelis_nisani.sql 110_valideyn_duzelis_nisani.sql \
         05_grants.sql; do
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
  #  Funksiya govdeleri de tutusdurulur.  Ustunden yazan fayl
  #  (mes. 103_cox_sinif.sql) yuxaridaki siyahiya salinmasa, teze
  #  bazada YENI, miqrasiya olunmusda KOHNE govde qalir - bu setir
  #  onu tapir.  Evvel yalniz sutun/indeks baxilirdi, ona gore
  #  103 siyahidan dusdugu halda yoxlama sakitce kecirdi.
  psql -Atq -d "$db" -c "
    select p.oid::regprocedure::text || md5(pg_get_functiondef(p.oid))
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname in ('public','app') and p.prokind = 'f'
     order by 1" > "/tmp/$db.fn.txt"
done
if diff -q /tmp/miq_teze.txt /tmp/miq_test.txt >/dev/null; then
  echo "  OK   teze ve miqrasiya olunmus sxem eynidir"
else
  echo "  FERQ:"; diff /tmp/miq_teze.txt /tmp/miq_test.txt | head -20; exit 1
fi
if diff -q /tmp/miq_teze.fn.txt /tmp/miq_test.fn.txt >/dev/null; then
  echo "  OK   funksiya govdeleri de eynidir"
else
  echo "  FERQ (funksiya):"
  diff /tmp/miq_teze.fn.txt /tmp/miq_test.fn.txt | head -20
  echo "  Ehtimal: run.sh-de olan bir fayl bu skriptdeki siyahida yoxdur."
  exit 1
fi
