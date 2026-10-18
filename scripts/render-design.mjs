// 디자인 캔버스(.dc.html 보드)를 PNG로 찍는다.
// 사용: node scripts/render-design.mjs <캔버스 project 폴더> <dc-runtime.js> <출력 폴더> <보드:파일명,...>
//   보드 항목 형식: "Main.dc.html=SCR-START-01.png" (=가 없으면 보드 이름 그대로 .png)
// 환경: CHROMIUM_PATH (선택)
import { chromium } from 'playwright';
import http from 'node:http';
import { readFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, resolve, extname, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const [, , projectDir, runtimePath, outDir, boardArg] = process.argv;
if (!projectDir || !runtimePath || !outDir || !boardArg) {
  console.error('사용: node scripts/render-design.mjs <project> <dc-runtime.js> <out> <Board.dc.html=out.png,...>');
  process.exit(2);
}
mkdirSync(outDir, { recursive: true });
const canvas = JSON.parse(readFileSync(join(projectDir, 'canvas.json'), 'utf8'));
const runtime = readFileSync(runtimePath);
const fontRoot = join(here, '..', 'node_modules', '@fontsource');

const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json',
  '.css': 'text/css', '.woff2': 'font/woff2', '.woff': 'font/woff', '.svg': 'image/svg+xml', '.png': 'image/png' };

function fontCss(port) {
  const parts = [];
  for (const w of [400, 500, 600, 700]) parts.push(readFileSync(join(fontRoot, 'ibm-plex-sans-kr', `${w}.css`), 'utf8')
    .replaceAll('url(./files/', `url(http://127.0.0.1:${port}/__fonts/ibm-plex-sans-kr/files/`));
  parts.push(readFileSync(join(fontRoot, 'ibm-plex-mono', '500.css'), 'utf8')
    .replaceAll('url(./files/', `url(http://127.0.0.1:${port}/__fonts/ibm-plex-mono/files/`));
  return parts.join('\n');
}

const server = http.createServer((req, res) => {
  const url = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let file;
  if (url === '/support.js') { res.writeHead(200, { 'content-type': TYPES['.js'] }); return res.end(runtime); }
  if (url.startsWith('/__fonts/')) file = join(fontRoot, url.slice('/__fonts/'.length));
  else file = join(projectDir, url);
  if (!resolve(file).startsWith(resolve(url.startsWith('/__fonts/') ? fontRoot : projectDir)) || !existsSync(file)) {
    res.writeHead(404); return res.end();
  }
  res.writeHead(200, { 'content-type': TYPES[extname(file)] || 'application/octet-stream', 'access-control-allow-origin': '*' });
  res.end(readFileSync(file));
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const port = server.address().port;
const css = fontCss(port);

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
let failed = 0;
try {
  for (const item of boardArg.split(',').map((s) => s.trim()).filter(Boolean)) {
    const [board, outName = board.replace(/\.dc\.html$/, '.png')] = item.split('=');
    const meta = canvas.boards[board];
    if (!meta) { console.error(`✗ canvas.json에 없는 보드: ${board}`); failed++; continue; }
    const page = await browser.newPage({ viewport: { width: meta.w, height: meta.h }, deviceScaleFactor: 2 });
    const errors = [];
    page.on('pageerror', (e) => errors.push(String(e)));
    await page.route('**/*', (route) => {
      const u = route.request().url();
      if (u.startsWith(`http://127.0.0.1:${port}/`)) return route.continue();
      if (u.startsWith('https://fonts.googleapis.com/css')) return route.fulfill({ status: 200, contentType: 'text/css', body: css });
      return route.abort();
    });
    await page.goto(`http://127.0.0.1:${port}/${board}`, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(400);
    await page.screenshot({ path: join(outDir, outName), clip: { x: 0, y: 0, width: meta.w, height: meta.h } });
    await page.close();
    console.log(`${errors.length ? '!' : '✓'} ${board} → ${outName}${errors.length ? '  오류: ' + errors[0] : ''}`);
    if (errors.length) failed++;
  }
} finally {
  await browser.close();
  server.close();
}
process.exit(failed ? 1 : 0);
