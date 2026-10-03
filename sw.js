/* =====================================================================
   sw.js — Bil10 service worker (muellim + sagird ucun ortaqdir)
   Kokde durur, ona gore ehatesi butun sayti tutur (/Testler/).

   MEQSED: tetbiq telefona qurasdirilsin ve TEZ acilsin.  Oflayn REJIM
   VED EDILMIR - suallar, tapsiriqlar, neticeler Supabase-den gelir,
   internet olmadan onlari gostermek olmaz.  Kes yalniz karkasi
   (HTML/CSS/JS) saxlayir.

   TEHLUKESIZLIK - iki qayda pozulmamalidir:
   1. Supabase sorgulari HEC VAXT keslenmir.  Bir defe keslense,
      sagird kohne tapsiriq siyahisini gorer ve ya bal itirer.
      Asagida yalniz OZ mexeyimiz emele alinir.
   2. HTML her defe sebekeden alinir (network-first).  Boyle olmasa
      ./bump.sh ile buraxilan yeni versiya istifadeciye catmazdi.

   VERSIYA: CACHE adi deyisende kohne kes tam silinir.  Karkas fayllari
   ?v=NNN ile gelir, ona gore adi elle artirmaq lazim deyil - kohne
   girisler onsuz da istifade olunmur.  Yene de sxem deyisende artir.
   ===================================================================== */

var CACHE = "bil10-v1";

//  Qurasdirmadan sonra dərhal isə dus - kohne worker gozlemesin
self.addEventListener("install", function (e) {
  self.skipWaiting();
});

//  Kohne versiyalarin kesini tomizle
self.addEventListener("activate", function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (k) {
        return k === CACHE ? null : caches.delete(k);
      }));
    }).then(function () { return self.clients.claim(); })
  );
});

function isHtml(req) {
  return req.mode === "navigate" ||
    (req.headers.get("accept") || "").indexOf("text/html") >= 0;
}

self.addEventListener("fetch", function (e) {
  var req = e.request;

  //  Yalniz GET.  POST/PATCH (Supabase yazilari) toxunulmur.
  if (req.method !== "GET") return;

  //  YALNIZ oz mexeyimiz.  Supabase (baska mexey) hec vaxt
  //  keslenmir - cavab birbasa sebekeden gedir.
  var url;
  try { url = new URL(req.url); } catch (err) { return; }
  if (url.origin !== self.location.origin) return;

  //  Video: Range sorgusu ile gelir (iOS bunsuz oynatmir), 5 MB-dir -
  //  kese qoyulmur, birbasa sebekeden gedir.
  if (/\.(mp4|webm)$/i.test(url.pathname) || req.headers.get("range")) return;

  if (isHtml(req)) {
    //  Sebeke birinci: yeni versiya derhal catsin.
    //  Internet yoxdursa kesdeki karkas acilir (sonra "baglanti yoxdur"
    //  mesajini tetbiqin ozu gosterir).
    e.respondWith(
      fetch(req).then(function (res) {
        var copy = res.clone();
        caches.open(CACHE).then(function (c) { c.put(req, copy); });
        return res;
      }).catch(function () {
        return caches.match(req).then(function (hit) {
          return hit || caches.match("./index.html");
        });
      })
    );
    return;
  }

  //  CSS/JS/ikon: ?v=NNN ile gelir, yeni versiya = yeni unvan.
  //  Ona gore kes birinci - ani acilis.
  e.respondWith(
    caches.match(req).then(function (hit) {
      if (hit) return hit;
      return fetch(req).then(function (res) {
        //  Yalniz ugurlu cavab saxlanilir
        if (res && res.status === 200 && res.type === "basic") {
          var copy = res.clone();
          caches.open(CACHE).then(function (c) { c.put(req, copy); });
        }
        return res;
      });
    })
  );
});

/* =====================================================================
   PUSH BILDIRISLER (db/910, 05.10)
   Server (Edge Function push-send) sifreli yuk gonderir: {title, body, url}.
   userVisibleOnly:true teleb edir ki, HER push-da bildiris GOSTERILSIN -
   ona gore burada bos/xeta halinda da bildiris cixir (sakitce itmir).

   TEHLUKESIZLIK:
   * Gelen metn yalniz bildiris olaraq GOSTERILIR (HTML deyil, kod deyil).
   * Basanda yalniz OZ SAYTIMIZIN unvani acilir - kenar unvan gelse, saytin koku acilir.
   ===================================================================== */
self.addEventListener("push", function (e) {
  var d = {};
  try { d = e.data ? e.data.json() : {}; } catch (x) {
    try { d = { body: e.data.text() }; } catch (y) { d = {}; }
  }
  var scope = self.registration.scope;
  e.waitUntil(self.registration.showNotification(String(d.title || "Bil10").slice(0, 80), {
    body: String(d.body || "").slice(0, 200),
    icon: scope + "assets/icons/icon-192.png",
    badge: scope + "assets/icons/icon-192.png",
    tag: d.tag ? String(d.tag).slice(0, 60) : undefined,
    data: { url: String(d.url || "") }
  }));
});

self.addEventListener("notificationclick", function (e) {
  e.notification.close();
  var scope = self.registration.scope;
  var target = scope;
  try {
    var u = new URL((e.notification.data && e.notification.data.url) || "", scope);
    if (u.origin === self.location.origin) target = u.href;      // kenar unvan - kok
  } catch (x) {}
  e.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(function (list) {
    for (var i = 0; i < list.length; i++) {
      var c = list[i];
      //  Eyni bolmede (sagird/valideyn) artiq aciq pencere varsa onu one cixar
      if (c.url.indexOf(target.replace(/[?#].*$/, "")) === 0 && "focus" in c) return c.focus();
    }
    return self.clients.openWindow(target);
  }));
});
