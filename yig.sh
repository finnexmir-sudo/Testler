#!/usr/bin/env bash
# =====================================================================
# yig.sh — statik fayllari sixir (esbuild).
#
# NIYE:  2026-09-21-de olculdu — panelin soyuq acilisi zeif 3G-de
# 3,5 saniye cekir, vaxtin ~60%-i FAYL YUKLEMESIDIR.  app.js tek
# basina sixisdirilmis 142 KB idi (menbede 484 KB: butun ekranlar bir
# fayldadir).  Minifikasiya onu 80 KB-a salir — umumi yuk 241 -> 178 KB.
#
# QAYDA:  MENBE app.js / app.css-dir, onlar redakte olunur.  Saytda
# ISLENEN fayl app.min.js / app.min.css-dir — bu skript yaradir.
# Ona gore ./bump.sh her defe evvel bunu cagirir; ayrica cagirmaga
# ehtiyac yoxdur.  test/tek.sh ve test/run_e2e.sh de cagirir — e2e
# yoxlamalari SAYTDA ISLEYEN faylla gedir.
#
# esbuild tapilmasa skript DAYANIR — sessizce kohne .min faylla
# yayimlamaq en pis haldir.
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"

EB="node_modules/.bin/esbuild"
if [ ! -x "$EB" ]; then
  echo "esbuild yoxdur — qurulur (bir defelik)..."
  npm install --silent --no-save esbuild >/dev/null 2>&1 || {
    echo "XETA: esbuild qurula bilmedi.  node/npm lazimdir." >&2
    echo "      Sixmadan yayimlamaq olmaz - .min fayllar kohne qalar." >&2
    exit 1
  }
fi
[ -x "$EB" ] || { echo "XETA: $EB tapilmadi." >&2; exit 1; }

FAYLLAR="
muellim/app.js
muellim/sb.js
muellim/app.css
sagird/app.js
sagird/sb.js
sagird/app.css
valideyn/app.js
valideyn/sb.js
valideyn/app.css
assets/base.css
"
TOP_A=0; TOP_B=0
for f in $FAYLLAR; do
  [ -f "$f" ] || continue
  out="${f%.*}.min.${f##*.}"
  "$EB" "$f" --minify --charset=utf8 --target=es2017 --outfile="$out" --log-level=warning
  a=$(stat -c%s "$f"); b=$(stat -c%s "$out")
  TOP_A=$((TOP_A + a)); TOP_B=$((TOP_B + b))
  printf "  %-22s %6d KB -> %6d KB\n" "$out" $((a / 1024)) $((b / 1024))
done
printf "yigildi: %d KB -> %d KB\n" $((TOP_A / 1024)) $((TOP_B / 1024))
