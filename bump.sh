#!/usr/bin/env bash
# Statik fayllarin versiya nisanini yenileyir.
# GitHub Pages CSS/JS-i 10 deqiqe kesde saxlayir (max-age=600); nisan
# olmasa istifadeci deyisiklikden sonra kohne nusxeni gorur.
# Her dizayn/kod deyisikliyinden SONRA, commit-den EVVEL isled:  ./bump.sh
set -euo pipefail
cd "$(dirname "$0")"
#  Saytda islenen fayl .min-dir; evvel onu yigiriq, sonra versiya
#  nisani vururuq.  Sira vacibdir: nisan .min fayla gore verilir.
./yig.sh

V=$(( $(git rev-list --count HEAD) + 1 ))
#  23.10: nisan HECVAXT geri getmir.  Qismen (shallow) klonda commit sayi kicik cixir
#  (814 evezine 61) - kohne ?v=61 service worker kesinde qala biler, ona gore movcud
#  en boyuk nisandan bir artiq goturulur.
CUR=$(grep -ho '?v=[0-9]*' index.html muellim/index.html sagird/index.html valideyn/index.html 2>/dev/null | tr -dc '0-9\n' | sort -n | tail -1)
[ -n "${CUR:-}" ] && [ "$CUR" -ge "$V" ] && V=$((CUR + 1))
for f in index.html muellim/index.html sagird/index.html valideyn/index.html komek/index.html mexfilik/index.html; do
  [ -f "$f" ] || continue
  sed -i -E "s|(href=\"[^\"]*\.css)(\?v=[0-9]+)?\"|\1?v=$V\"|g" "$f"
  sed -i -E "s|(src=\"[^\"]*\.js)(\?v=[0-9]+)?\"|\1?v=$V\"|g"  "$f"
done
echo "versiya -> $V"
grep -ho '[a-z]*\.\(css\|js\)?v=[0-9]*' index.html muellim/index.html sagird/index.html valideyn/index.html komek/index.html 2>/dev/null | sort -u
