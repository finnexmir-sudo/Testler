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
