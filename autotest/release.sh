#!/bin/bash
# Đóng gói playwright-core của nhánh autotest thành tệp .tgz cho dự án auto-test (xem autotest/README.md).
#   autotest/release.sh <n>            build + đóng gói → autotest/dist/playwright-core-<phiên bản>-autotest.<n>.tgz
#   autotest/release.sh <n> --publish  như trên, rồi đẩy nhánh hiện tại và tạo GitHub Release v<phiên bản>-autotest.<n> đính kèm tệp
set -euo pipefail
N=${1:?Thiếu số bản autotest (1, 2, …)}
PUBLISH=${2:-}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in autotest/*) ;; *) echo "Đang ở nhánh «$BRANCH» — chỉ phát hành từ nhánh autotest/v<phiên bản>." >&2; exit 1 ;; esac
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then echo "Còn thay đổi chưa commit — commit trước khi phát hành." >&2; exit 1; fi

[ -d node_modules ] || npm ci --no-audit --no-fund
npm run build

VER=$(node -p "require('./packages/playwright-core/package.json').version")
TAG="v$VER-autotest.$N"
OUT="$ROOT/autotest/dist"
mkdir -p "$OUT"
# giấy phép Apache-2.0: gói phải kèm LICENSE + NOTICE — upstream chép từ gốc repo lúc phát hành (utils/workspace.js), ở packages/* bị gitignore
cp LICENSE NOTICE packages/playwright-core/
FILE=$(cd packages/playwright-core && npm pack --silent --pack-destination "$OUT" | tail -1)
TGZ="$OUT/playwright-core-$VER-autotest.$N.tgz"
mv "$OUT/$FILE" "$TGZ"
echo "Đã đóng gói: $TGZ"
echo "integrity: sha512-$(openssl dgst -sha512 -binary "$TGZ" | base64 -w0)"

if [ "$PUBLISH" = "--publish" ]; then
  # lấy từ remote origin — với fork, `gh repo view` tự chọn repo gốc microsoft/playwright
  REPO=$(git remote get-url origin | sed -E 's#^(https://github.com/|git@github.com:)##; s#\.git$##')
  case "$REPO" in microsoft/*) echo "origin trỏ về $REPO — chỉ phát hành lên fork." >&2; exit 1 ;; esac
  git push -u origin "$BRANCH"
  gh release create "$TAG" "$TGZ" --repo "$REPO" --target "$(git rev-parse HEAD)" \
    --title "playwright-core $VER (autotest $N)" \
    --notes "Bản playwright-core $VER kèm các sửa đổi cho app Auto Test — danh sách trong autotest/README.md của nhánh $BRANCH."
  echo "URL cho pnpm-workspace.yaml › catalog: https://github.com/$REPO/releases/download/$TAG/$(basename "$TGZ")"
fi
