// Edge Function push-send (supabase/functions/push-send/index.ts) - Node-da, saxta Supabase ve saxta web-push ile.
//   node test/push_sender_test.mjs
// TypeScript esbuild ile kecici ESM faylina cevrilir (Deno burada lazim deyil).
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createRequire } from "node:module";
import assert from "node:assert/strict";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const out = join(mkdtempSync(join(tmpdir(), "pushfn-")), "push-send.mjs");
execFileSync(join(root, "node_modules/.bin/esbuild"),
  [join(root, "supabase/functions/push-send/index.ts"), "--format=esm", "--target=node20", "--outfile=" + out, "--log-level=error"]);
const { handle, hostOk } = await import(pathToFileURL(out).href);

let fails = 0;
function ok(cond, label, extra = "") {
  console.log((cond ? "  OK   " : "  FAIL ") + label + (cond || !extra ? "" : "  " + extra));
  if (!cond) fails++;
}
const ENV = { PUSH_SECRET: "gizli-soz", VAPID_PUBLIC: "PUB", VAPID_PRIVATE: "PRIV", VAPID_SUBJECT: "mailto:a@b.az",
              SUPABASE_URL: "https://x.supabase.co", SUPABASE_SERVICE_ROLE_KEY: "SRV" };
const req = (method = "POST", secret = "gizli-soz") =>
  new Request("https://f/push-send", { method, headers: secret == null ? {} : { "x-push-secret": secret } });

function fakeDeps({ claim = [], status = {}, claimFail = false, doneFail = false, env = ENV } = {}) {
  const calls = { rpc: [], sent: [], vapid: null };
  return {
    calls,
    deps: {
      env,
      fetch: async (url, init) => {
        const name = String(url).split("/rpc/")[1];
        calls.rpc.push({ name, body: JSON.parse(init.body), headers: init.headers });
        if (name === "rpc_push_claim") return claimFail ? new Response("x", { status: 500 }) : new Response(JSON.stringify(claim), { status: 200 });
        if (name === "rpc_push_done") return doneFail ? new Response("x", { status: 500 }) : new Response(JSON.stringify({ ok: true }), { status: 200 });
        return new Response("?", { status: 404 });
      },
      webpush: {
        setVapidDetails: (s, p, k) => { calls.vapid = [s, p, k]; },
        sendNotification: async (sub, payload, opts) => {
          calls.sent.push({ sub, payload: JSON.parse(payload), opts });
          const st = status[sub.endpoint];
          if (st) { const e = new Error("push " + st); e.statusCode = st; throw e; }
          return { statusCode: 201 };
        },
      },
    },
  };
}
const FCM = "https://fcm.googleapis.com/fcm/send/";
const sub = (id, ep = FCM + id + "-aaaaaaaaaaaaaaaa") => ({ id, endpoint: ep, p256dh: "P", auth: "A" });

console.log("1 · qapi: gizli soz ve metod");
{
  const { deps, calls } = fakeDeps();
  let r = await handle(req("POST", "yanlis"), deps);
  ok(r.status === 401, "yanlis gizli soz -> 401"); 
  r = await handle(req("POST", null), deps);
  ok(r.status === 401, "baslıq yoxdur -> 401");
  r = await handle(req("POST", ""), { ...deps, env: { ...ENV, PUSH_SECRET: "" } });
  ok(r.status === 401, "PUSH_SECRET tanimlanmayibsa BOS baslıq da kecmir (funksiya aciq qalmir)");
  r = await handle(req("GET"), deps);
  ok(r.status === 405, "GET -> 405");
  ok(calls.rpc.length === 0, "yetkisiz sorgu bazaya toxunmur");
  r = await handle(req(), { ...deps, env: { ...ENV, VAPID_PRIVATE: "" } });
  ok(r.status === 500, "VAPID_PRIVATE yoxdursa -> 500 (config)");
}

console.log("2 · bos novbe");
{
  const { deps, calls } = fakeDeps({ claim: [] });
  const r = await handle(req(), deps); const j = await r.json();
  ok(r.status === 200 && j.claimed === 0, "bos novbe -> claimed 0");
  ok(calls.rpc.length === 1 && calls.rpc[0].name === "rpc_push_claim", "yalniz claim cagirilir, done yox");
  ok(calls.vapid && calls.vapid[0] === "mailto:a@b.az", "VAPID konfiqurasiya olunur");
  ok(calls.rpc[0].headers.apikey === "SRV" && calls.rpc[0].headers.Authorization === "Bearer SRV", "service_role acari ile cagirilir");
}

console.log("3 · gonderme: ugurlu, olu (410), kecici xeta (503), SSRF");
{
  const EVIL = "https://evil.example.com/fcm/send/aaaaaaaaaaaaaaaa";
  const claim = [
    { id: 1, kind: "yeni_test", title: "Bil10 · Yeni test", body: "Test var", url: "./sagird/",
      subs: [sub("s1"), sub("s2"), sub("s3"), sub("s4", EVIL)] },
    { id: 2, kind: "gundelik", title: "T2", body: "B2", url: "./", subs: null },
  ];
  const { deps, calls } = fakeDeps({ claim, status: { [FCM + "s2-aaaaaaaaaaaaaaaa"]: 410, [FCM + "s3-aaaaaaaaaaaaaaaa"]: 503 } });
  const r = await handle(req(), deps); const j = await r.json();
  ok(r.status === 200 && j.sent === 1 && j.dead === 2 && j.failed === 1, "sayim: 1 ugurlu, 2 olu (410 + SSRF), 1 xeta", JSON.stringify(j));
  ok(calls.sent.length === 3, "kenar unvana HEC VAXT gonderilmir (3 cehd, 4 abune)", calls.sent.length);
  ok(!calls.sent.some((x) => x.sub.endpoint === EVIL), "evil.example.com-a sorgu getmeyib");
  ok(calls.sent[0].payload.title === "Bil10 · Yeni test" && calls.sent[0].payload.url === "./sagird/" && calls.sent[0].payload.tag === "yeni_test", "yuk: title/url/tag");
  ok(calls.sent[0].opts.TTL === 3600 && calls.sent[0].opts.timeout === 10000, "TTL 1 saat, taym-aut 10 san");
  const done = calls.rpc.find((c) => c.name === "rpc_push_done").body.p_results;
  ok(done.length === 2, "done: iki bildiris");
  ok(JSON.stringify(done[0].ok) === '["s1"]' && JSON.stringify(done[0].dead.sort()) === '["s2","s4"]' && JSON.stringify(done[0].failed) === '["s3"]',
     "done[0]: ok=s1, dead=s2+s4, failed=s3", JSON.stringify(done[0]));
  ok(done[1].ok.length === 0 && done[1].dead.length === 0 && done[1].failed.length === 0, "done[1]: abunesiz bildiris bos neticə ile");
}

console.log("4 · baza xetalari");
{
  let { deps } = fakeDeps({ claimFail: true });
  let r = await handle(req(), deps);
  ok(r.status === 502, "claim xetasi -> 502");
  ({ deps } = fakeDeps({ claim: [{ id: 1, kind: "k", title: "t", body: "b", url: "./", subs: [sub("s1")] }], doneFail: true }));
  r = await handle(req(), deps);
  ok(r.status === 502 && (await r.json()).sent === 1, "done xetasi -> 502, amma gonderilenler sayilir");
}

console.log("5 · unvan yoxlamasi (hostOk) - SQL ile eyni qayda");
for (const [u, want] of [
  [FCM + "abc:APA91b-_x", true],
  ["https://updates.push.services.mozilla.com/wpush/v2/gAAAAAB", true],
  ["https://web.push.apple.com/QJ4_x-abc", true],
  ["https://api.sandbox.push.apple.com/3/device/abc", true],
  ["https://wns2-par02p.notify.windows.com/w/?token=BQYAAAB%2b&x=1", true],
  ["http://fcm.googleapis.com/fcm/send/abcdefgh", false],
  ["https://evil.com/fcm.googleapis.com/abcdefghij", false],
  ["https://fcm.googleapis.com.evil.com/fcm/send/abcd", false],
  ["https://fcm.googleapis.com@evil.com/fcm/send/abcd", false],
  ["https://127.0.0.1/fcm/send/abcdefghijk", false],
  ["https://localhost/abcdefghijklmnop", false],
  [null, false], [undefined, false], [123, false],
]) ok(hostOk(u) === want, `hostOk(${String(u).slice(0, 55)}) = ${want}`);

console.log("6 · HEQIQI web-push kitabxanasi (oflayn): VAPID + yukun sifrelenmesi isleyir");
try {
  const wpDir = process.env.WEBPUSH_DIR || "/tmp/claude-0/wp";
  const require = createRequire(join(wpDir, "x.js"));
  const webpush = require("web-push");
  const crypto = await import("node:crypto");
  const keys = webpush.generateVAPIDKeys();
  webpush.setVapidDetails("mailto:a@b.az", keys.publicKey, keys.privateKey);
  const ecdh = crypto.createECDH("prime256v1"); ecdh.generateKeys();
  const subReal = { endpoint: FCM + "real-test-aaaaaaaaaaaaaaaaaaaa",
    keys: { p256dh: ecdh.getPublicKey().toString("base64url"), auth: crypto.randomBytes(16).toString("base64url") } };
  const d = webpush.generateRequestDetails(subReal, JSON.stringify({ title: "Bil10", body: "Test", url: "./" }), { TTL: 3600, urgency: "normal" });
  ok(d.method === "POST" && d.endpoint === subReal.endpoint, "sorgu detallari: POST + dogru unvan");
  ok(String(d.headers.Authorization || d.headers.authorization).startsWith("vapid t="), "VAPID Authorization basligi var");
  ok(d.headers.TTL === 3600 || d.headers.TTL === "3600", "TTL basligi");
  ok(Buffer.isBuffer(d.body) && d.body.length > 50, "yuk sifrelenib (Buffer)");
  ok(!d.body.toString("utf8").includes("Test"), "yuk aciq metn kimi gedmir");
  ok(keys.publicKey.length === 87, "VAPID aciq acar 87 simvol (base64url)");
} catch (e) {
  ok(false, "web-push kitabxanasi tapilmadi/iseleme xetasi (npm i web-push@3.6.7 --prefix /tmp/claude-0/wp)", String(e.message || e));
}

console.log("\nNETICE:", fails ? "XETALAR: " + fails : "HAMISI KECDI");
process.exit(fails ? 1 : 0);
