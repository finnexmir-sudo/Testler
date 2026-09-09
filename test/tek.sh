#!/usr/bin/env bash
# TEK e2e skriptini isledir:  test/tek.sh e2e_paket.py
#
# Niye ayrica skript?  mock_supabase parollari YADDASDA saxlayir
# (PASSWORDS sozlugu).  Bir testi ikinci defe isletsen qeydiyyat
# merhelesi ("#btnSetup") tapilmir - mock e-poctu "artiq var" sayir.
# Deva: MOCK-u yeniden qaldirmaqdir.  Baza her testin ozu tereqinden
# temizlenir (her skript basda 'delete from auth.users' edir), ona
# gore BAZANI HER DEFE YENIDEN QURMAQ LAZIM DEYIL - o, 13 min setrlik
# bank fayllari ile birlikde 3-4 deqiqe aparirdi.
#   test/tek.sh e2e_paket.py            movcud bazada (surətli)
#   NEW_DB=1 test/tek.sh e2e_paket.py   sifirdan baza (miqrasiyadan sonra)
# Butun destə ucun run_e2e.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

export PGHOST=${PGHOST:-/tmp} PGPORT=${PGPORT:-55432} PGUSER=${PGUSER:-postgres}
DB=${DB:-panel_e2e}
API_PORT=${API_PORT:-54321}
WEB_PORT=${WEB_PORT:-8010}
T="${1:?istifade: test/tek.sh e2e_paket.py}"

#  DIQQET: naxis LOVBERLENIR (^).  'pkill -f "http.server 8010"' oz bash
#  sarmalayicimizi da tapib oldururdu - test sessizce bos qayidirdi.
pkill -f "^python3 -m http.server $WEB_PORT"   2>/dev/null || true
pkill -f "^python3 test/mock_supabase.py"      2>/dev/null || true
sleep 1

if [ -n "${NEW_DB:-}" ] || ! psql -lqt | cut -d\| -f1 | grep -qw "$DB"; then
  dropdb --if-exists "$DB" >/dev/null 2>&1 || true
  createdb "$DB"
  ( cd db && ./run.sh "$DB" --local ) 2>&1 | grep -vi notice | grep -v '^$' || true
fi

MOCK_DSN="host=$PGHOST port=$PGPORT user=$PGUSER dbname=$DB" \
  python3 test/mock_supabase.py "$API_PORT" >/tmp/tek_mock.log 2>&1 &
MOCK_PID=$!
python3 -m http.server "$WEB_PORT" >/tmp/tek_web.log 2>&1 &
WEB_PID=$!
cleanup() { kill "$MOCK_PID" "$WEB_PID" 2>/dev/null || true; }
trap cleanup EXIT
sleep 2

python3 "test/$T"
