// Captures the Kagoj demo screens with headless Chrome over the DevTools protocol.
// Usage: node tool/screenshots/shoot.mjs <baseUrl> <outDir>  (see run.sh)
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const [base, outDir] = process.argv.slice(2);
mkdirSync(outDir, { recursive: true });

const shots = [
  ['home', 'light'],
  ['nowreading', 'light'],
  ['meaning', 'light'],
  ['translate', 'light'],
  ['listen', 'light'],
  ['words', 'light'],
  ['addpaper', 'light'],
  ['settings', 'dark'],
  ['home', 'dark'],
  ['meaning', 'dark'],
  ['listen', 'dark'],
];

const port = 9333;
const chrome = spawn('google-chrome', [
  '--headless=new', `--remote-debugging-port=${port}`, '--no-first-run',
  '--no-default-browser-check', '--hide-scrollbars', '--disable-gpu',
  `--user-data-dir=${join(outDir, '.chrome')}`, 'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function devtoolsPage() {
  for (let i = 0; i < 50; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
      const page = list.find((t) => t.type === 'page');
      if (page) return page.webSocketDebuggerUrl;
    } catch {}
    await sleep(200);
  }
  throw new Error('Chrome DevTools not reachable');
}

const ws = new WebSocket(await devtoolsPage());
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let nextId = 1;
const pending = new Map();
ws.addEventListener('message', (e) => {
  const msg = JSON.parse(e.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
  }
});
const send = (method, params = {}) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  ws.send(JSON.stringify({ id, method, params }));
});

await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', {
  width: 390, height: 844, deviceScaleFactor: 3, mobile: true,
});
await send('Emulation.setTouchEmulationEnabled', { enabled: true });

for (const [screen, theme] of shots) {
  await send('Page.navigate', { url: `${base}/index.html?screen=${screen}&theme=${theme}` });
  await sleep(7000); // app boot + Google Fonts + sheet animation
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  const file = join(outDir, `${screen}-${theme}.png`);
  writeFileSync(file, Buffer.from(data, 'base64'));
  console.log('saved', file);
}

ws.close();
chrome.kill();
