/* =====================================================================
   push-send - Supabase Edge Function (db/910)

   Cron (her deqiqe) bu funksiyani cagirir.  O, novbedeki bildirisleri
   rpc_push_claim ile goturur, Web Push ile gonderir, neticeni rpc_push_done ile yazir.

   SIRLER (Supabase -> Edge Functions -> Secrets):
     VAPID_PUBLIC   gizli olmayan acar (sagird/valideyn config.js-deki ile EYNI)
     VAPID_PRIVATE  GIZLI acar - heç yere yazilmir, yalniz burada
     VAPID_SUBJECT  elaqe: mailto:... (yalniz push xidmetleri gorur)
     PUSH_SECRET    cron-un bildiyi gizli soz (x-push-secret basliqi)
   SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY Supabase terefinden AVTOMATIK verilir.

   DEPLOY: «Verify JWT» SONDURULMELIDIR (cagiranin JWT-si yoxdur; qapi PUSH_SECRET-dir).
   Quraşdirma addimlari: supabase/functions/push-send/README.md

   TEHLUKESIZLIK
   * PUSH_SECRET tanimlanmayibsa ve ya uygun gelmirse 401 - funksiya HEC VAXT aciq qalmir.
   * Abune unvani YALNIZ bilinen push xidmetlerinden ola biler (SSRF).  Baza da yoxlayir,
     burada TEKRAR yoxlanir (baza gec yenilense de qorunmaq ucun).
   * Mesajin mezmunu yalniz bazadan gelir (novbe) - sorgudan hec ne qebul edilmir.
   ===================================================================== */

const HOST_RE =
  /^https:\/\/(fcm\.googleapis\.com|updates\.push\.services\.mozilla\.com|web\.push\.apple\.com|[a-z0-9-]+(\.[a-z0-9-]+)*\.push\.apple\.com|[a-z0-9-]+(\.[a-z0-9-]+)*\.notify\.windows\.com)\/[A-Za-z0-9_.~%\/:=+?&-]+$/;

export function hostOk(ep: unknown): boolean {
  return typeof ep === "string" && ep.length >= 20 && ep.length <= 1000 && HOST_RE.test(ep);
}

//  Sabit vaxtli muqayise (gizli sozu zamana gore tapmaq olmasin)
function same(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

type Sub = { id: string; endpoint: string; p256dh: string; auth: string };
type Msg = { id: number; kind: string; title: string; body: string; url: string; subs: Sub[] | null };

export type Deps = {
  env: Record<string, string | undefined>;
  fetch: typeof fetch;
  webpush: {
    setVapidDetails(subject: string, pub: string, priv: string): void;
    sendNotification(sub: unknown, payload: string, opts: unknown): Promise<unknown>;
  };
};

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), { status, headers: { "Content-Type": "application/json" } });
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  const env = deps.env;
  const secret = env.PUSH_SECRET || "";
  const given = req.headers.get("x-push-secret") || "";
  if (!secret || !same(given, secret)) return json({ error: "unauthorized" }, 401);
  if (req.method !== "POST") return json({ error: "method" }, 405);

  const pub = env.VAPID_PUBLIC, priv = env.VAPID_PRIVATE, subject = env.VAPID_SUBJECT;
  const base = env.SUPABASE_URL, key = env.SUPABASE_SERVICE_ROLE_KEY;
  if (!pub || !priv || !subject || !base || !key) return json({ error: "config" }, 500);
  deps.webpush.setVapidDetails(subject, pub, priv);

  async function rpc(name: string, args: unknown) {
    const r = await deps.fetch(`${base}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: { apikey: key!, Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify(args),
    });
    if (!r.ok) throw new Error(`${name} HTTP ${r.status}`);
    return await r.json();
  }

  let claimed: Msg[];
  try {
    claimed = await rpc("rpc_push_claim", { p_limit: 50 });
  } catch (e) {
    return json({ error: "claim", detail: String((e as Error).message || e) }, 502);
  }
  if (!Array.isArray(claimed) || claimed.length === 0) return json({ ok: true, claimed: 0, sent: 0 });

  const results: unknown[] = [];
  let sent = 0, dead = 0, failed = 0;
  for (const m of claimed) {
    const ok: string[] = [], deadIds: string[] = [], failedIds: string[] = [];
    let error = "";
    const payload = JSON.stringify({ title: m.title, body: m.body, url: m.url, tag: m.kind });
    for (const s of m.subs || []) {
      if (!hostOk(s.endpoint)) { deadIds.push(s.id); error = "endpoint tanınmadı"; continue; }   // SSRF
      try {
        await deps.webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          payload,
          { TTL: 3600, urgency: "normal", timeout: 10000 },
        );
        ok.push(s.id);
      } catch (e) {
        const st = (e as { statusCode?: number }).statusCode;
        if (st === 404 || st === 410) deadIds.push(s.id);           // abune olub
        else failedIds.push(s.id);
        error = `HTTP ${st || "şəbəkə"}`;
      }
    }
    sent += ok.length; dead += deadIds.length; failed += failedIds.length;
    results.push({ id: m.id, ok, dead: deadIds, failed: failedIds, error: ok.length ? "" : error });
  }

  try {
    await rpc("rpc_push_done", { p_results: results });
  } catch (e) {
    return json({ error: "done", detail: String((e as Error).message || e), sent }, 502);
  }
  return json({ ok: true, claimed: claimed.length, sent, dead, failed });
}

declare const Deno: any;
if (typeof Deno !== "undefined" && Deno.serve) {
  Deno.serve(async (req: Request) => {
    const webpush = (await import("npm:web-push@3.6.7")).default;
    return handle(req, { env: Deno.env.toObject(), fetch, webpush });
  });
}
