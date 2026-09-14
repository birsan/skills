#!/usr/bin/env node
// webreq - minimal HTTP request runner over a user-owned folder of contexts and collections.
// Zero dependencies. Node >= 18. Output is intentionally terse to save tokens.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const CONFIG = path.join(os.homedir(), '.claude', 'webreq.json');
const SECRET_RE = /token|secret|password|apikey|api_key|auth/i;
const args = process.argv.slice(2);
const cmd = args.shift();

// ---------- helpers ----------
const die = (m, code = 1) => { console.error('error: ' + m); process.exit(code); };
const readJson = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, o) => fs.writeFileSync(p, JSON.stringify(o, null, 2) + '\n');
const exists = (p) => fs.existsSync(p);
const BOOL_FLAGS = new Set(['--dry', '--full', '--json', '--local', '--shared']);
const flag = (name) => args.includes(name);
const opt = (name, def) => { const i = args.indexOf(name); return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : def; };
const optAll = (name) => { const out = []; for (let i = 0; i < args.length; i++) if (args[i] === name && args[i + 1] !== undefined) out.push(args[++i]); return out; };
const positional = () => args.filter((a, i) => !a.startsWith('-') && !(i > 0 && args[i - 1].startsWith('-') && !BOOL_FLAGS.has(args[i - 1])));

function root() {
  if (process.env.WEBREQ_ROOT) return process.env.WEBREQ_ROOT;
  if (exists(CONFIG)) return readJson(CONFIG).root;
  die('no root configured. Run: webreq init <folder>');
}
const dir = (sub) => path.join(root(), sub);

function deepMerge(a, b) {
  const out = { ...a };
  for (const [k, v] of Object.entries(b || {})) {
    const isObj = (x) => x && typeof x === 'object' && !Array.isArray(x);
    out[k] = isObj(v) && isObj(out[k]) ? deepMerge(out[k], v) : v;
  }
  return out;
}

// ${env:NAME} inside context values -> process.env.NAME
function resolveEnv(v) {
  if (typeof v === 'string') return v.replace(/\$\{env:([A-Za-z_][A-Za-z0-9_]*)\}/g, (_, n) => process.env[n] ?? '');
  if (Array.isArray(v)) return v.map(resolveEnv);
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, resolveEnv(x)]));
  return v;
}

const ctxFile = (name, local) => path.join(dir('contexts'), name + (local ? '.local.json' : '.json'));

function loadContext(name) {
  const base = ctxFile(name, false), local = ctxFile(name, true);
  if (!exists(base) && !exists(local)) die(`context '${name}' not found in ${dir('contexts')}`);
  let ctx = exists(base) ? readJson(base) : {};
  if (exists(local)) ctx = deepMerge(ctx, readJson(local));
  return resolveEnv(ctx);
}

function listCollections() {
  const d = dir('collections');
  if (!exists(d)) return [];
  return fs.readdirSync(d).filter((f) => f.endsWith('.json')).map((f) => ({ id: f.slice(0, -5), ...readJson(path.join(d, f)) }));
}

function findRequest(ref) {
  const [cid, rname] = (ref || '').split('/');
  if (!rname) die(`request ref must be <collection>/<request>, got '${ref}'`);
  const col = listCollections().find((c) => c.id === cid);
  if (!col) die(`collection '${cid}' not found`);
  const req = (col.requests || []).find((r) => r.name === rname);
  if (!req) die(`request '${rname}' not in collection '${cid}'`);
  return { col, req };
}

// {{a.b}} substitution; unresolved names are collected
function render(str, vars, missing) {
  return String(str).replace(/\{\{\s*([\w.-]+)\s*\}\}/g, (_, k) => {
    const v = k.split('.').reduce((o, p) => (o == null ? undefined : o[p]), vars);
    if (v === undefined || v === '') { missing.add(k); return `{{${k}}}`; }
    return typeof v === 'object' ? JSON.stringify(v) : String(v);
  });
}
const renderDeep = (x, vars, missing) =>
  typeof x === 'string' ? render(x, vars, missing)
  : Array.isArray(x) ? x.map((i) => renderDeep(i, vars, missing))
  : x && typeof x === 'object' ? Object.fromEntries(Object.entries(x).map(([k, v]) => [k, renderDeep(v, vars, missing)]))
  : x;

// precedence: -v overrides > request var defaults > collection vars > context
function resolve(ref, ctxName, overrides) {
  const { col, req } = findRequest(ref);
  const ctx = ctxName ? loadContext(ctxName) : {};
  const defaults = Object.fromEntries(Object.entries(req.vars || {}).filter(([, v]) => v && v.default !== undefined).map(([k, v]) => [k, v.default]));
  const vars = { ...ctx, ...(col.vars || {}), ...defaults, ...overrides };
  const missing = new Set();
  const out = {
    method: (req.method || 'GET').toUpperCase(),
    url: render(req.url, vars, missing),
    headers: renderDeep({ ...(col.headers || {}), ...(req.headers || {}) }, vars, missing),
    body: req.body === undefined ? undefined : renderDeep(req.body, vars, missing),
  };
  return { out, missing: [...missing], req, col };
}

const mask = (k, v) => (SECRET_RE.test(k) && typeof v === 'string' && v.length > 8 ? v.slice(0, 4) + '...' + v.slice(-3) : v);
const maskDeep = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, v && typeof v === 'object' && !Array.isArray(v) ? maskDeep(v) : mask(k, v)]));

function pick(obj, p) {
  return p.split('.').reduce((o, k) => {
    if (o == null) return undefined;
    const m = k.match(/^(\w*)\[(\d+)\]$/);
    return m ? (m[1] ? o[m[1]] : o)?.[Number(m[2])] : o[k];
  }, obj);
}

// ---------- commands ----------
const commands = {
  init() {
    const target = positional()[0];
    if (!target) die('usage: webreq init <folder>');
    const abs = path.resolve(target);
    for (const s of ['contexts', 'collections']) fs.mkdirSync(path.join(abs, s), { recursive: true });
    const gi = path.join(abs, '.gitignore');
    if (!exists(gi)) fs.writeFileSync(gi, '# secrets live in local overlays, never committed\ncontexts/*.local.json\n.out/\n');
    fs.mkdirSync(path.dirname(CONFIG), { recursive: true });
    writeJson(CONFIG, { root: abs });
    console.log(`root=${abs}`);
  },

  root() { console.log(root()); },

  contexts() {
    const d = dir('contexts');
    if (!exists(d)) return console.log('(none)');
    const names = [...new Set(fs.readdirSync(d).filter((f) => f.endsWith('.json')).map((f) => f.replace(/\.local\.json$|\.json$/, '')))];
    if (!names.length) return console.log('(none)');
    for (const n of names) console.log(`${n}: ${Object.keys(loadContext(n)).join(', ')}`);
  },

  context() {
    const n = positional()[0]; if (!n) die('usage: webreq context <name>');
    console.log(JSON.stringify(maskDeep(loadContext(n)), null, 1));
  },

  // set <ctx> k=v ... ; secret-looking keys go to the .local.json overlay unless --shared; --local forces overlay
  set() {
    const [n, ...pairs] = positional();
    if (!n || !pairs.length) die('usage: webreq set <context> key=value ... [--local|--shared]');
    const files = { shared: ctxFile(n, false), local: ctxFile(n, true) };
    const data = { shared: exists(files.shared) ? readJson(files.shared) : {}, local: exists(files.local) ? readJson(files.local) : {} };
    const touched = new Set();
    for (const kv of pairs) {
      const i = kv.indexOf('='); if (i < 0) die(`expected key=value, got '${kv}'`);
      const k = kv.slice(0, i), v = kv.slice(i + 1);
      const where = flag('--local') ? 'local' : flag('--shared') ? 'shared' : SECRET_RE.test(k) ? 'local' : 'shared';
      data[where][k] = v; touched.add(where);
    }
    fs.mkdirSync(dir('contexts'), { recursive: true });
    for (const w of touched) writeJson(files[w], data[w]);
    console.log(`${n}: wrote ${[...touched].map((w) => path.basename(files[w])).join(', ')}`);
  },

  // one dense line per request: collection/name METHOD url - description [vars]
  list() {
    const q = positional().join(' ').toLowerCase();
    let n = 0;
    for (const c of listCollections()) {
      for (const r of c.requests || []) {
        const line = `${c.id}/${r.name} ${(r.method || 'GET').toUpperCase()} ${r.url} - ${r.description || ''}`;
        const vars = Object.keys(r.vars || {});
        const hay = (line + ' ' + (c.description || '') + ' ' + (r.tags || []).join(' ') + ' ' + vars.join(' ')).toLowerCase();
        if (q && !q.split(/\s+/).every((w) => hay.includes(w))) continue;
        console.log(line + (vars.length ? `  [${vars.join(', ')}]` : '')); n++;
      }
    }
    if (!n) console.log(q ? `(no match for '${q}')` : '(no requests yet)');
  },

  show() {
    const { col, req } = findRequest(positional()[0]);
    console.log(JSON.stringify({ collection: col.id, collectionHeaders: col.headers, collectionVars: col.vars, ...req }, null, 1));
  },

  async run() {
    const ref = positional()[0];
    if (!ref) die('usage: webreq run <col>/<req> -c <context> [-v k=v]... [--dry] [--full] [--max N] [--pick path] [--out file]');
    const ctxName = opt('-c', opt('--context'));
    const overrides = Object.fromEntries(optAll('-v').map((kv) => { const i = kv.indexOf('='); return [kv.slice(0, i), kv.slice(i + 1)]; }));
    const { out, missing } = resolve(ref, ctxName, overrides);
    if (missing.length) die(`unresolved vars: ${missing.join(', ')}  -> pass -v name=value, or store: webreq set ${ctxName || '<ctx>'} name=value`, 3);
    if (flag('--dry')) return console.log(JSON.stringify({ ...out, headers: maskDeep(out.headers) }, null, 1));

    const init = { method: out.method, headers: { ...out.headers } };
    if (out.body !== undefined && out.method !== 'GET') {
      init.body = typeof out.body === 'string' ? out.body : JSON.stringify(out.body);
      if (!Object.keys(init.headers).some((h) => h.toLowerCase() === 'content-type')) init.headers['Content-Type'] = 'application/json';
    }
    const t0 = Date.now();
    let res;
    try { res = await fetch(out.url, init); } catch (e) { die(`${out.method} ${out.url} failed: ${e.cause?.message || e.message}`); }
    const text = await res.text();
    const ms = Date.now() - t0;
    let body = text;
    try { body = JSON.parse(text); } catch { /* not json */ }

    const outFile = opt('--out');
    if (outFile) { fs.mkdirSync(path.dirname(path.resolve(outFile)), { recursive: true }); fs.writeFileSync(outFile, text); }

    const p = opt('--pick');
    if (p && typeof body === 'object') body = pick(body, p);
    const rendered = typeof body === 'string' ? body : JSON.stringify(body);
    const limit = flag('--full') ? Infinity : Number(opt('--max', 2000));
    const note = rendered.length > limit ? `  ...(${rendered.length} chars; use --full, --pick or --out)` : '';
    console.log(`${res.status} ${res.statusText} ${ms}ms ${out.method} ${out.url}${outFile ? `  -> ${outFile}` : ''}`);
    if (rendered.length) console.log(rendered.slice(0, limit) + note);
    if (res.status === 401 || res.status === 403) {
      console.log(`hint: auth rejected. Ask the user for a valid bearer for context '${ctxName || '?'}' then: webreq set ${ctxName || '<ctx>'} token=<value>`);
    }
    if (!res.ok) process.exitCode = 2;
  },

  // add a request to a collection (creates the collection if missing). Definition is a JSON string or a file path.
  add() {
    const cid = positional()[0];
    if (!cid) die('usage: webreq add <collection> --def <json-or-file> [--description "collection desc"]');
    let def = opt('--def') || die('--def required');
    if (exists(def)) def = fs.readFileSync(def, 'utf8');
    const req = JSON.parse(def);
    if (!req.name || !req.url) die('request needs at least name and url');
    fs.mkdirSync(dir('collections'), { recursive: true });
    const file = path.join(dir('collections'), cid + '.json');
    const col = exists(file) ? readJson(file) : { description: opt('--description', ''), headers: { Authorization: 'Bearer {{token}}' }, requests: [] };
    const i = col.requests.findIndex((r) => r.name === req.name);
    if (i >= 0) col.requests[i] = req; else col.requests.push(req);
    writeJson(file, col);
    console.log(`${i >= 0 ? 'updated' : 'added'} ${cid}/${req.name}`);
  },

  help() {
    console.log(`webreq <command>
  init <folder>                    set the requests root (creates contexts/ collections/ .gitignore)
  root                             print root
  contexts                         list contexts and their keys
  context <name>                   show a context (secrets masked)
  set <ctx> k=v ... [--local|--shared]  write context values (secret-like keys default to <ctx>.local.json)
  list [words]                     one line per request matching all words (name, url, description, tags, vars)
  show <col>/<req>                 full request definition
  run <col>/<req> -c <ctx> [-v k=v]... [--dry] [--full] [--max N] [--pick a.b[0]] [--out file]
  add <col> --def <json|file>      add/replace a request in a collection
exit codes: 0 ok | 1 usage/config | 2 http error | 3 unresolved vars`);
  },
};

const fn = commands[cmd] || commands.help;
Promise.resolve(fn()).catch((e) => die(e.message));
