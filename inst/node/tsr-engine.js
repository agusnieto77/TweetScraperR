/*
 * tsr-engine.js — Motor de scraping de X/Twitter para TweetScraperR
 *
 * Playwright + stealth. Invocado por el paquete R como subproceso:
 *   node tsr-engine.js <comando>   (parametros JSON por stdin; salida JSON por stdout)
 *
 * Comandos:
 *   doctor   -> {ok, playwright, node, chromium}
 *   login    -> hace login con el modal actual de X y guarda storageState a disco
 *   collect  -> reusa storageState (SIN re-login), scrollea y extrae articles o urls
 *
 * Logs humanos van a stderr; el unico stdout es el JSON de resultado.
 */
'use strict';

const { chromium } = require('playwright-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
chromium.use(StealthPlugin());

const UA =
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/131.0.0.0 Safari/537.36';

function ctxOpts(extra) {
  return Object.assign(
    {
      locale: 'es-ES',
      timezoneId: 'America/Argentina/Buenos_Aires',
      viewport: { width: 1280, height: 860 },
      userAgent: UA,
    },
    extra || {}
  );
}

// Normaliza el parametro proxy: acepta un string "http://host:port" o
// "user:pass@host:port", o un objeto {server, username, password}.
function parseProxy(proxy) {
  if (!proxy) return null;
  if (typeof proxy === 'object') return proxy;
  let s = String(proxy);
  let creds = null;
  const at = s.lastIndexOf('@');
  if (at !== -1) {
    const schemeMatch = s.match(/^[a-z0-9]+:\/\//i);
    const scheme = schemeMatch ? schemeMatch[0] : '';
    const rest = s.slice(scheme.length);
    const at2 = rest.lastIndexOf('@');
    const userpass = rest.slice(0, at2);
    const hostport = rest.slice(at2 + 1);
    const colon = userpass.indexOf(':');
    creds = {
      username: colon === -1 ? userpass : userpass.slice(0, colon),
      password: colon === -1 ? '' : userpass.slice(colon + 1),
    };
    s = scheme + hostport;
  }
  const out = { server: s };
  if (creds) {
    out.username = creds.username;
    out.password = creds.password;
  }
  return out;
}

function elog(tag, msg) {
  process.stderr.write('[' + tag + '] ' + msg + '\n');
}

function readStdin() {
  return new Promise((resolve) => {
    let d = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => (d += c));
    process.stdin.on('end', () => resolve(d));
    // si no hay stdin conectado, resolver vacio
    if (process.stdin.isTTY) resolve('');
  });
}

// Escribe `value` en el primer input VISIBLE (offsetParent != null y NO
// aria-hidden) que matchea el selector, usando el setter nativo de value para
// que los inputs controlados de React de X registren el cambio. Robusto frente
// al DOM duplicado del modal de login (formulario visible vs. oculto).
async function fillVisible(page, selector, value) {
  return await page.evaluate(
    ({ selector, value }) => {
      function vis(el) {
        return (
          el &&
          el.offsetParent !== null &&
          el.getClientRects().length > 0 &&
          el.getAttribute('aria-hidden') !== 'true'
        );
      }
      const els = Array.from(document.querySelectorAll(selector)).filter(vis);
      if (!els.length) return 'NO-VISIBLE';
      const el = els[0];
      el.focus();
      const proto =
        el.tagName === 'TEXTAREA'
          ? window.HTMLTextAreaElement.prototype
          : window.HTMLInputElement.prototype;
      const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
      setter.call(el, value);
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      return 'OK';
    },
    { selector, value }
  );
}

// Como fillVisible pero TIPEANDO como humano (keystrokes reales con delay), en
// lugar de inyectar el valor por JS de forma instantanea. La inyeccion JS es una
// firma de automatizacion que X detecta; el tipeo real emite eventos de teclado
// genuinos. Marca el input visible con un atributo temporal para que Playwright
// pueda apuntarle aunque el DOM este duplicado.
async function humanFill(page, selector, value) {
  const marked = await page.evaluate((selector) => {
    function vis(el) {
      return (
        el &&
        el.offsetParent !== null &&
        el.getClientRects().length > 0 &&
        el.getAttribute('aria-hidden') !== 'true'
      );
    }
    document.querySelectorAll('[data-tsr-target]').forEach((e) => e.removeAttribute('data-tsr-target'));
    const els = Array.from(document.querySelectorAll(selector)).filter(vis);
    if (!els.length) return false;
    els[0].setAttribute('data-tsr-target', '1');
    return true;
  }, selector);
  if (!marked) return 'NO-VISIBLE';
  const loc = page.locator("[data-tsr-target='1']");
  await loc.click({ delay: 40 + Math.floor(Math.random() * 60) });
  await page.waitForTimeout(200 + Math.floor(Math.random() * 300));
  await loc.pressSequentially(String(value), { delay: 80 + Math.floor(Math.random() * 90) });
  await page.evaluate(() => {
    const e = document.querySelector('[data-tsr-target]');
    if (e) e.removeAttribute('data-tsr-target');
  });
  return 'OK';
}

// Clickea el primer boton/[role=button] VISIBLE cuyo texto coincide con alguno
// de `texts` (en orden de preferencia). Devuelve 'CLICK:<texto>' o 'NO-BTN:...'.
async function clickVisibleText(page, texts) {
  return await page.evaluate((texts) => {
    function vis(el) {
      return el && el.offsetParent !== null && el.getClientRects().length > 0;
    }
    const c = Array.from(document.querySelectorAll('button,[role=button]')).filter(vis);
    for (let i = 0; i < texts.length; i++) {
      const t = texts[i].toLowerCase();
      const el = c.find((e) => (e.innerText || '').trim().toLowerCase() === t);
      if (el) {
        el.click();
        return 'CLICK:' + texts[i];
      }
    }
    return 'NO-BTN:' + c.map((e) => (e.innerText || '').trim().slice(0, 18)).filter(Boolean).join('|');
  }, texts);
}

const LOGIN_URL = 'https://x.com/i/flow/login';
// Bilingues: X puede servir el modal en es o en en segun el contexto.
const NEXT_BTNS = ['Continuar', 'Continue', 'Siguiente', 'Next'];
const LOGIN_BTNS = [
  'Iniciar sesión',
  'Log in',
  'Sign in',
  'Acceder',
  'Entrar',
  'Continuar',
  'Continue',
];
const USER_SEL =
  "input[name='username_or_email'], input[name='text'], input[autocomplete~='username']";
const PASS_SEL = "input[name='password']";

function isLoginUrl(u) {
  return /\/(i\/flow\/login|login|i\/jf\/onboarding)/.test(u);
}

async function doctor() {
  let pw = null;
  try {
    pw = require('playwright/package.json').version;
  } catch (e) {
    pw = null;
  }
  let chromiumPath = null;
  try {
    chromiumPath = chromium.executablePath();
  } catch (e) {
    chromiumPath = null;
  }
  return { ok: true, playwright: pw, node: process.version, chromium: chromiumPath };
}

async function login(p) {
  const { user, pass, email, storageStatePath } = p;
  const headless = p.headless !== false;
  const shotDir = p.shotDir || null;
  if (!user || !pass) throw new Error('faltan credenciales (user/pass)');
  if (!storageStatePath) throw new Error('falta storageStatePath');

  const proxy = parseProxy(p.proxy);
  const browser = await chromium.launch(proxy ? { headless, proxy } : { headless });
  const context = await browser.newContext(ctxOpts());
  const page = await context.newPage();
  try {
    if (proxy) elog('login', 'usando proxy: ' + proxy.server);
    elog('login', 'navegando a ' + LOGIN_URL);
    await page.goto(LOGIN_URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(4500);

    elog('login', 'paso 1: usuario');
    // Esperar a que aparezca un input de usuario visible y tipearlo como humano
    let uf = 'NO-VISIBLE';
    for (let i = 0; i < 10 && uf !== 'OK'; i++) {
      uf = await humanFill(page, USER_SEL, user);
      if (uf !== 'OK') await page.waitForTimeout(1500);
    }
    elog('login', 'fill usuario: ' + uf);
    await page.waitForTimeout(800 + Math.floor(Math.random() * 600));
    elog('login', 'click next: ' + (await clickVisibleText(page, NEXT_BTNS)));
    await page.waitForTimeout(3500);

    // Paso intermedio opcional: verificacion de identidad (email/telefono/usuario).
    // Solo si NO aparecio aun el campo de password y hay un input de texto extra.
    let pf = await humanFill(page, PASS_SEL, pass);
    if (pf !== 'OK' && email) {
      const challengeFilled = await humanFill(
        page,
        "input[data-testid='ocfEnterTextTextInput'], input[name='text']",
        email
      );
      if (challengeFilled === 'OK') {
        elog('login', 'challenge de identidad: ingreso email');
        await page.waitForTimeout(700);
        await clickVisibleText(page, NEXT_BTNS);
        await page.waitForTimeout(3500);
      }
    }

    elog('login', 'paso 2: password');
    // El campo de password aparece recien tras avanzar del paso de usuario:
    // reintentar hasta que un input password VISIBLE acepte el valor.
    for (let i = 0; i < 8 && pf !== 'OK'; i++) {
      await page.waitForTimeout(1500);
      pf = await humanFill(page, PASS_SEL, pass);
    }
    elog('login', 'fill password: ' + pf);
    await page.waitForTimeout(800 + Math.floor(Math.random() * 600));
    elog('login', 'click login: ' + (await clickVisibleText(page, LOGIN_BTNS)));
    await page.waitForTimeout(7000);

    const url = page.url();
    let bodyText = '';
    try {
      bodyText = await page.locator('body').innerText({ timeout: 5000 });
    } catch (e) {
      bodyText = '';
    }
    const limited = /limitado temporalmente|temporarily limited|sospechos|unusual/i.test(bodyText);
    const loggedIn = !isLoginUrl(url);

    if (loggedIn) {
      await context.storageState({ path: storageStatePath });
      elog('login', 'OK -> storageState guardado en ' + storageStatePath);
      return { ok: true, loggedIn: true, url, storageStatePath };
    }
    let screenshot = null;
    if (shotDir) {
      screenshot = shotDir + '/login-fail.png';
      await page.screenshot({ path: screenshot }).catch(() => {});
    }
    return {
      ok: false,
      loggedIn: false,
      url,
      limited,
      reason: limited ? 'rate_limited' : 'login_failed',
      hint: bodyText.slice(0, 500),
      screenshot,
    };
  } finally {
    await browser.close().catch(() => {});
  }
}

async function manualLogin(p) {
  const storageStatePath = p.storageStatePath;
  const waitSeconds = p.waitSeconds || 420;
  if (!storageStatePath) throw new Error('falta storageStatePath');

  const browser = await chromium.launch({ headless: false, args: ['--start-maximized'] });
  const context = await browser.newContext(ctxOpts({ viewport: null }));
  const page = await context.newPage();
  try {
    await page.goto(LOGIN_URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
    elog('manual', 'Navegador ABIERTO. Esperando login manual del usuario (hasta ' + waitSeconds + 's)...');
    const start = Date.now();
    let loggedIn = false;
    while (Date.now() - start < waitSeconds * 1000) {
      await page.waitForTimeout(2500);
      let u;
      try {
        u = page.url();
      } catch (e) {
        break; // el usuario cerró la ventana
      }
      if (!isLoginUrl(u)) {
        const ok = await page
          .evaluate(
            () =>
              !!document.querySelector(
                '[data-testid="primaryColumn"], [data-testid="AppTabBar_Home_Link"], a[href="/home"], article'
              )
          )
          .catch(() => false);
        if (ok) {
          loggedIn = true;
          break;
        }
      }
    }
    if (loggedIn) {
      await page.waitForTimeout(1500);
      await context.storageState({ path: storageStatePath });
      elog('manual', 'Login detectado -> sesión guardada en ' + storageStatePath);
      return { ok: true, loggedIn: true, url: page.url(), storageStatePath };
    }
    let url = null;
    try {
      url = page.url();
    } catch (e) {
      url = null;
    }
    return { ok: false, loggedIn: false, url, reason: 'timeout_manual' };
  } finally {
    await browser.close().catch(() => {});
  }
}

// Bearer token publico del cliente web de X (constante conocida, no secreta).
const X_BEARER =
  'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA';
const GQL_BASE = 'https://x.com/i/api/graphql';

// Ejecuta una consulta GraphQL contra la API interna de X, desde el contexto
// de la pagina autenticada (reusa storageState). El fetch same-origin incluye
// las cookies; agregamos el bearer publico y x-csrf-token (=ct0). Devuelve el
// status HTTP y el body crudo para que R lo parsee.
async function graphql(p) {
  const { storageStatePath, opId, opName, variables, features } = p;
  if (!storageStatePath) throw new Error('falta storageStatePath');
  if (!opId || !opName) throw new Error('faltan opId/opName');
  const headless = p.headless !== false;
  const proxy = parseProxy(p.proxy);

  const browser = await chromium.launch(proxy ? { headless, proxy } : { headless });
  const context = await browser.newContext(ctxOpts({ storageState: storageStatePath }));
  const page = await context.newPage();
  try {
    await page.goto('https://x.com/home', { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(2500);
    if (isLoginUrl(page.url())) {
      return { ok: false, reason: 'not_logged_in', url: page.url() };
    }
    const cookies = await context.cookies();
    const ct0 = (cookies.find((c) => c.name === 'ct0') || {}).value || '';

    const qs =
      'variables=' +
      encodeURIComponent(JSON.stringify(variables || {})) +
      '&features=' +
      encodeURIComponent(JSON.stringify(features || {}));
    const url = GQL_BASE + '/' + opId + '/' + opName + '?' + qs;

    const res = await page.evaluate(
      async ({ url, bearer, ct0 }) => {
        try {
          const r = await fetch(url, {
            method: 'GET',
            headers: {
              authorization: bearer,
              'x-csrf-token': ct0,
              'x-twitter-active-user': 'yes',
              'x-twitter-auth-type': 'OAuth2Session',
              'x-twitter-client-language': 'en',
              'content-type': 'application/json',
            },
            credentials: 'include',
          });
          const text = await r.text();
          return { status: r.status, body: text };
        } catch (e) {
          return { status: -1, body: String(e) };
        }
      },
      { url, bearer: X_BEARER, ct0 }
    );
    elog('graphql', opName + ' -> HTTP ' + res.status + ' (' + res.body.length + ' bytes)');
    return { ok: res.status === 200, status: res.status, body: res.body };
  } finally {
    await browser.close().catch(() => {});
  }
}

// "Ride-along": navega a una pagina de X y COSECHA las respuestas JSON de la
// API GraphQL que la propia app dispara (que ya traen el x-client-transaction-id
// que ciertos endpoints, como SearchTimeline, exigen). Scrollea para gatillar
// mas paginas. Devuelve los bodies JSON crudos para que R los parsee.
async function harvest(p) {
  const { storageStatePath, url } = p;
  const opNames = p.opNames || [];
  const maxScrolls = p.maxScrolls || 25;
  const waitMs = p.waitMs || 2500;
  const scrollPx = p.scrollPx || 4000;
  const headless = p.headless !== false;
  if (!storageStatePath) throw new Error('falta storageStatePath');
  if (!url) throw new Error('falta url');
  const proxy = parseProxy(p.proxy);

  const browser = await chromium.launch(proxy ? { headless, proxy } : { headless });
  const context = await browser.newContext(ctxOpts({ storageState: storageStatePath }));
  const page = await context.newPage();
  const bodies = [];
  const matches = (u) =>
    u.includes('/i/api/graphql/') && opNames.some((n) => u.indexOf('/' + n) !== -1);
  page.on('response', async (resp) => {
    if (!matches(resp.url())) return;
    try {
      const t = await resp.text();
      if (t) bodies.push(t);
    } catch (e) {
      /* respuesta ya consumida o navegacion */
    }
  });

  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(4500);
    if (isLoginUrl(page.url())) {
      return { ok: false, reason: 'not_logged_in', url: page.url(), count: 0, bodies: [] };
    }
    let stable = 0;
    for (let i = 0; i < maxScrolls; i++) {
      const before = bodies.length;
      await page.mouse.wheel(0, scrollPx);
      await page.waitForTimeout(waitMs);
      if (bodies.length === before) {
        stable++;
        if (stable >= 3) break;
      } else {
        stable = 0;
      }
    }
    elog('harvest', 'cosechadas ' + bodies.length + ' respuestas (' + opNames.join('/') + ')');
    return { ok: true, count: bodies.length, bodies };
  } finally {
    await browser.close().catch(() => {});
  }
}

async function collect(p) {
  const { storageStatePath, url } = p;
  const mode = p.mode || 'articles';
  const nMax = p.nMax || 100;
  const maxAttempts = p.maxAttempts || 3;
  const scrollPx = p.scrollPx || 4000;
  const waitMs = p.waitMs || 2500;
  const headless = p.headless !== false;
  if (!storageStatePath) throw new Error('falta storageStatePath');
  if (!url) throw new Error('falta url');

  const proxy = parseProxy(p.proxy);
  const browser = await chromium.launch(proxy ? { headless, proxy } : { headless });
  const context = await browser.newContext(ctxOpts({ storageState: storageStatePath }));
  const page = await context.newPage();
  try {
    if (proxy) elog('collect', 'usando proxy: ' + proxy.server);
    elog('collect', 'navegando a ' + url);
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(4000);

    if (isLoginUrl(page.url())) {
      return { ok: false, reason: 'not_logged_in', url: page.url(), count: 0, items: [] };
    }

    const seen = new Set();
    const items = [];
    let attempts = 0;
    while (items.length < nMax && attempts < maxAttempts) {
      let batch;
      if (mode === 'urls') {
        batch = await page.$$eval("a[href*='/status/']", (els) =>
          els.map((e) => e.getAttribute('href'))
        );
      } else if (mode === 'users') {
        batch = await page.$$eval("[data-testid='UserCell']", (els) =>
          els.map((e) => e.outerHTML)
        );
      } else {
        batch = await page.$$eval('article', (els) => els.map((e) => e.outerHTML));
      }
      let added = 0;
      for (const it of batch) {
        if (!it) continue;
        let key;
        if (mode === 'urls') {
          key = it;
        } else if (mode === 'users') {
          const hm = it.match(/href="\/([A-Za-z0-9_]+)"/);
          key = hm ? hm[1] : it.slice(0, 400);
        } else {
          const m = it.match(/\/status\/(\d+)/);
          key = m ? m[1] : it.slice(0, 200);
        }
        if (!seen.has(key)) {
          seen.add(key);
          items.push(it);
          added++;
        }
      }
      if (added === 0) attempts++;
      else attempts = 0;
      await page.mouse.wheel(0, scrollPx);
      await page.waitForTimeout(waitMs);
    }
    elog('collect', 'recolectados ' + items.length + ' items (mode=' + mode + ')');
    return { ok: true, count: items.length, items: items.slice(0, nMax) };
  } finally {
    await browser.close().catch(() => {});
  }
}

(async () => {
  const cmd = process.argv[2];
  let params = {};
  try {
    const raw = await readStdin();
    if (raw && raw.trim()) params = JSON.parse(raw);
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: 'JSON de entrada invalido: ' + e.message }));
    process.exitCode = 1;
    return;
  }
  try {
    let out;
    if (cmd === 'doctor') out = await doctor(params);
    else if (cmd === 'login') out = await login(params);
    else if (cmd === 'manualLogin') out = await manualLogin(params);
    else if (cmd === 'graphql') out = await graphql(params);
    else if (cmd === 'harvest') out = await harvest(params);
    else if (cmd === 'collect') out = await collect(params);
    else throw new Error('comando desconocido: ' + cmd);
    process.stdout.write(JSON.stringify(out));
  } catch (e) {
    process.stdout.write(
      JSON.stringify({ ok: false, error: String((e && e.message) || e), stack: e && e.stack })
    );
    process.exitCode = 1;
  }
})();
