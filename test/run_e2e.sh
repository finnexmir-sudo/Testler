#!/usr/bin/env bash
# Paneli uçdan-uca yoxlayir: temiz baza + mock Supabase + Chromium.
# Lazimdir: postgres isleyir, playwright ve psycopg2-binary qurulub.
set -euo pipefail
cd "$(dirname "$0")/.."

export PGHOST=${PGHOST:-/tmp} PGPORT=${PGPORT:-55432} PGUSER=${PGUSER:-postgres}
DB=${DB:-panel_e2e}
API_PORT=${API_PORT:-54321}
WEB_PORT=${WEB_PORT:-8010}

cleanup() { [ -n "${MOCK_PID:-}" ] && kill "$MOCK_PID" 2>/dev/null || true
            [ -n "${WEB_PID:-}"  ] && kill "$WEB_PID"  2>/dev/null || true; }
trap cleanup EXIT

echo "1/4  temiz baza: $DB"
dropdb --if-exists "$DB" >/dev/null 2>&1 || true
createdb "$DB"
( cd db && ./run.sh "$DB" --local ) 2>&1 | grep -vi notice || true

echo "2/4  mock supabase :$API_PORT"
MOCK_DSN="host=$PGHOST port=$PGPORT user=$PGUSER dbname=$DB" \
  python3 test/mock_supabase.py "$API_PORT" >/dev/null 2>&1 &
MOCK_PID=$!

echo "3/4  statik server :$WEB_PORT"
python3 -m http.server "$WEB_PORT" >/dev/null 2>&1 &
WEB_PID=$!
sleep 2

echo "4/4  brauzer yoxlamasi"
python3 test/e2e_panel.py
echo
echo "5/6  sagird tetbiqi"
python3 test/e2e_student.py
echo
echo "6/7  tapsiriq axini"
python3 test/e2e_assign.py
echo
echo "7/8  sual banki"
python3 test/e2e_bank.py
echo
echo "8/9  generator"
python3 test/e2e_gen.py
echo
echo "9/9  paket ve admin"
python3 test/e2e_paket.py
echo
echo "10/11 bildirisler ve 2FA"
python3 test/e2e_bildiris.py
echo
echo "11/12 ders plani"
python3 test/e2e_plan.py
echo
echo "12/13 parol berpasi"
python3 test/e2e_parol.py
echo
echo "13/14 tedris fennleri"
python3 test/e2e_fenn.py
echo
echo "14/17 valideyn girisi"
python3 test/e2e_valideyn.py
echo
echo "15/17 diaqnostika"
python3 test/e2e_diaq.py
echo
echo "16/17 bize yaz"
python3 test/e2e_bize.py
echo
echo "17/17 bu gunun dersi"
python3 test/e2e_bugun.py
