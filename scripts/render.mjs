// HTML을 PNG로 찍는다. ERD 이미지와 화면 미리보기에 쓴다.
// 사용: node scripts/render.mjs <입력.html> <출력.png> [CSS 선택자, 기본 #root]
// 처음 한 번: npm install && npx playwright install chromium
import { chromium } from 'playwright';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , input, output, selector = '#root'] = process.argv;
if (!input || !output) {
  console.error('사용: node scripts/render.mjs <입력.html> <출력.png> [선택자]');
  process.exit(2);
}

const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {}
);
try {
  const page = await browser.newPage({ viewport: { width: 2400, height: 1600 }, deviceScaleFactor: 2 });
  await page.goto(pathToFileURL(resolve(input)).href);
  // 페이지가 그리기를 마쳤다고 표시하면(body[data-ready="1"]) 기다리고, 표시가 없으면 3초 뒤 진행한다
  await page.waitForSelector('body[data-ready="1"]', { timeout: 3000 }).catch(() => {});
  const target = page.locator(selector);
  if ((await target.count()) === 0) {
    await page.screenshot({ path: resolve(output), fullPage: true });
  } else {
    await target.first().screenshot({ path: resolve(output) });
  }
  console.log(`저장: ${output}`);
} finally {
  await browser.close();
}
