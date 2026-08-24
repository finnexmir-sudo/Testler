#!/usr/bin/env bash
# Statik fayllarin versiya nisanini yenileyir.
# GitHub Pages CSS/JS-i 10 deqiqe kesde saxlayir (max-age=600); nisan
# olmasa istifadeci deyisiklikden sonra kohne nusxeni gorur.
# Her dizayn/kod deyisikliyinden SONRA, commit-den EVVEL isled:  ./bump.sh
set -euo pipefail
cd "$(dirname "$0")"
V=$(( $(git rev-list --count HEAD) + 1 ))
sed -i -E "s|(href=\"muellim/app\.css)(\?v=[0-9]+)?\"|\1?v=$V\"|" index.html
sed -i -E "s|(href=\"app\.css)(\?v=[0-9]+)?\"|\1?v=$V\"|" muellim/index.html
sed -i -E "s|(src=\"(config\|sb\|app)\.js)(\?v=[0-9]+)?\"|\1?v=$V\"|g" muellim/index.html
echo "versiya -> $V"
grep -o 'app\.css?v=[0-9]*' index.html muellim/index.html
