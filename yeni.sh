#!/usr/bin/env bash
# Onbaxis saytina gonderir:  https://yeni.bil10.az
#
#   ./yeni.sh            cari budagi (adeten "beta") onbaxisa cixarir
#   ./yeni.sh main       verilen budagi cixarir
#
# Onbaxis ayrica repo-dur (finnexmir-sudo/bil10-yeni), GitHub Pages ordan
# xidmet edir.  Kod eynidir, yalniz CNAME ferqlidir (yeni.bil10.az).
# Muveqqeti budaq yaradilir, CNAME deyisdirilir, force-push edilir,
# muveqqeti budaq silinir.  Esas repo-ya (bil10.az) toxunulmur.
#
# Beyenildikden sonra prodaksina:  git checkout main && git merge beta && git push
set -euo pipefail
cd "$(dirname "$0")"
SRC="${1:-$(git rev-parse --abbrev-ref HEAD)}"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "evvel commit et - is agaci temiz deyil" >&2; exit 1
fi
REMOTE="https://github.com/finnexmir-sudo/bil10-yeni"
TMP="_yeni_$$"
git remote get-url yeni >/dev/null 2>&1 || git remote add yeni "$REMOTE"
git branch -f "$TMP" "$SRC"
git checkout -q "$TMP"
echo "yeni.bil10.az" > CNAME
git commit -q -am "onbaxis: CNAME yeni.bil10.az" --no-verify
git push -q --force yeni "$TMP:main"
git checkout -q "$SRC"
git branch -D "$TMP" >/dev/null
echo "gonderildi: $SRC -> yeni.bil10.az  (1-2 deqiqeye cixir)"
