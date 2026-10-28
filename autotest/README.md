# Playwright cho Auto Test

Fork của [microsoft/playwright](https://github.com/microsoft/playwright) dùng cho app **Auto Test** (repo `auto-test`). App chỉ dùng gói
`playwright-core` (không tải trình duyệt kèm theo — chạy Chrome có sẵn của máy qua CDP). Ở đây sửa trực tiếp mã Playwright khi cần cho
chức năng của app; mỗi sửa đổi viết sao cho gửi được pull request lên upstream.

## Nhánh và phiên bản

- Nhánh `autotest/v<phiên bản>` tạo từ tag upstream `v<phiên bản>` (ví dụ `autotest/v1.64.1` từ `v1.64.1`). Nhánh `main` giữ nguyên như upstream.
- Mỗi sửa đổi là **một commit riêng** (mã + test) — dễ chuyển sang bản Playwright mới bằng `git cherry-pick` và dễ gửi lên upstream.
- Bản phát hành: tag `v<phiên bản>-autotest.<n>`, GitHub Release đính kèm `playwright-core-<phiên bản>-autotest.<n>.tgz`.
  `package.json` của gói **giữ nguyên số phiên bản upstream** (mã Playwright dùng số này); hậu tố `-autotest.<n>` chỉ nằm ở tag / tên tệp.

## Các sửa đổi so với upstream

| # | Sửa đổi | Tệp | Test | Lý do (auto-test) |
|---|---|---|---|---|
| 1 | Chromium: toạ độ phần tử trong iframe khác site (OOPIF) tính từ vùng nội dung của thẻ iframe — cộng viền + đệm như BiDi / `_checkFrameIsHitTarget`, làm tròn theo điểm ảnh thiết bị như Chromium vẽ khung. Trước đây ảnh chụp phần tử, `boundingBox()`, điểm bấm lệch đúng viền + đệm (iframe mặc định 2 px). Thẻ iframe / tổ tiên chỉ bị tịnh tiến (`translateZ(0)`, modal căn giữa…) vẫn cộng; co giãn / xoay / nghiêng giữ như cũ. Hai commit: «fix(chromium): account for iframe border and padding…» + «fix(chromium): keep OOPIF content box offset under translated ancestors…». | `packages/playwright-core/src/server/chromium/crPage.ts` (`_framePosition`) | `tests/library/chromium/oopif.spec.ts` (5 test «…border and padding…», «…translated ancestors», «…fractional…», «…translateZ(0) ancestor») | việc 10 trong `docs/viec-se-lam.md` |

## Phát hành một bản cho auto-test

```bash
# trên nhánh autotest/v<phiên bản>, đã commit hết
autotest/release.sh <n>             # build + đóng gói vào autotest/dist/
autotest/release.sh <n> --publish   # + đẩy nhánh, tạo GitHub Release đính kèm tệp .tgz, in URL
```

Trong repo `auto-test`: sửa URL ở `pnpm-workspace.yaml` › `catalog` › `playwright-core` (các `package.json` ghi `"playwright-core": "catalog:"`),
chạy `pnpm install` (lockfile ghi mã băm của tệp), chạy toàn bộ test + kiểm trên app, commit.

## Chuyển sang bản Playwright mới

```bash
git fetch upstream tag v<mới> --no-tags
git checkout -b autotest/v<mới> v<mới>
git cherry-pick <các commit sửa đổi ở bảng trên>   # sửa xung đột nếu có; sửa đổi upstream đã nhận thì bỏ khỏi bảng
npm ci && npm run build
CRPATH=/usr/bin/google-chrome npx playwright test --config=tests/library/playwright.config.ts --project=chromium-library tests/library/chromium/oopif.spec.ts
autotest/release.sh 1 --publish
```

Remote `upstream` = `https://github.com/microsoft/playwright.git` (`git remote add upstream …` nếu chưa có).
