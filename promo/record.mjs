// Renders index.html frame by frame in headless Chrome and encodes an MP4 with ffmpeg.
//   node record.mjs                 → onelineplanner-promo.mp4 (1920×1080, 30 fps)
//   node record.mjs --stills 2,9,15 → stills/frame-<t>.png for quick checks
//   --lang en                       → English version (onelineplanner-promo-en.mp4, stills/en-frame-<t>.png)
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const DIR = path.dirname(fileURLToPath(import.meta.url));
const FPS = 30;
const CHROME =
  process.env.CHROME_PATH ||
  ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/usr/bin/google-chrome', '/usr/bin/chromium'].find(existsSync);

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--hide-scrollbars'] });
const page = await browser.newPage();
await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
const langArg = process.argv.indexOf('--lang');
const lang = langArg !== -1 ? process.argv[langArg + 1] : 'az';
const suffix = lang === 'az' ? '' : `-${lang}`;
await page.goto(pathToFileURL(path.join(DIR, 'index.html')).href + `?record&lang=${lang}`, { waitUntil: 'load' });
await page.evaluate(() => document.fonts.ready);
const duration = await page.evaluate(() => window.DURATION);

const stillsArg = process.argv.indexOf('--stills');
if (stillsArg !== -1) {
  const next = process.argv[stillsArg + 1];
  const times = (next && !next.startsWith('--') ? next : '1,2.5,4.5,6.5,9,11,15,17,21,23,25.5,27,29.5').split(',').map(Number);
  mkdirSync(path.join(DIR, 'stills'), { recursive: true });
  for (const t of times) {
    await page.evaluate((x) => window.render(x), t);
    writeFileSync(path.join(DIR, 'stills', `${lang === 'az' ? '' : lang + '-'}frame-${t}.png`), await page.screenshot({ type: 'png' }));
  }
  console.log(`saved ${times.length} stills`);
  await browser.close();
  process.exit(0);
}

const out = path.join(DIR, `onelineplanner-promo${suffix}.mp4`);
const ffmpeg = spawn(
  'ffmpeg',
  ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-',
   '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out],
  { stdio: ['pipe', 'ignore', 'inherit'] },
);
const done = new Promise((resolve, reject) => ffmpeg.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`ffmpeg exited ${code}`)))));

const total = Math.round(duration * FPS);
for (let i = 0; i < total; i++) {
  await page.evaluate((x) => window.render(x), i / FPS);
  const buf = await page.screenshot({ type: 'png' });
  if (!ffmpeg.stdin.write(buf)) await new Promise((r) => ffmpeg.stdin.once('drain', r));
  if (i % 60 === 0) process.stdout.write(`\rframe ${i}/${total}`);
}
ffmpeg.stdin.end();
await done;
await browser.close();
console.log(`\nsaved ${out}`);
