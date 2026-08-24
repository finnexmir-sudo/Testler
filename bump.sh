#!/usr/bin/env bash
# Statik fayllarin versiya nisanini yenileyir.
# GitHub Pages CSS/JS-i 10 deqiqe kesde saxlayir (max-age=600); nisan
# olmasa istifadeci deyisiklikden sonra kohne nusxeni gorur.
# Her dizayn/kod deyisikliyinden SONRA, commit-den EVVEL isled:  ./bump.sh
set -euo pipefail
cd "$(dirname "$0")"
V=$(( $(git rev-list --count HEAD) + 1 ))
for f in index.html muellim/index.html sagird/index.html; do
  [ -f "$f" ] || continue
  sed -i -E "s|(href=\"[^\"]*\.css)(\?v=[0-9]+)?\"|\1?v=$V\"|g" "$f"
  sed -i -E "s|(src=\"[^\"]*\.js)(\?v=[0-9]+)?\"|\1?v=$V\"|g"  "$f"
done
echo "versiya -> $V"
grep -ho '[a-z]*\.\(css\|js\)?v=[0-9]*' index.html muellim/index.html sagird/index.html 2>/dev/null | sort -u
