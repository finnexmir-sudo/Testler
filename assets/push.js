/* =====================================================================
   push.js - telefona bildiris (Web Push) - sagird ve valideyn ucun ORTAQ klient (db/910)

   Bu fayl yalniz brauzer teresidir: icaze sorusur, abune alir, SERVERE yazilmasini
   cagiran tetbiqe (register/unregister) verir.  Server (RPC + Edge Function) ayridir.

   QAYDALAR
   * Xidmet CFG.VAPID_PUBLIC bos olanda TAM GIZLIDIR (state() = "off") - acar qoyulmayana
     qeder heç bir yerde duyme/yazi cixmir.
   * Icaze YALNIZ duyme basilanda sorusulur; sehife acilanda ozu-ozune soruşmur.
   * iPhone: bildiris yalniz ANA EKRANA ELAVE OLUNMUS tetbiqde isleyir - evvel onu deyirik.
   * «Sondur» yalniz SERVER abunesini silir (bu cihazdaki bu sagird/valideyn ucun); brauzer
     abunesi qalir, cunki eyni cihazda basqa usaq da ola biler.  Secim (sondurulub) cihazda
     saxlanir: localStorage, «rol + sagird» acari ile - sessiya/token SAXLANMIR.
   * localStorage / Notification / PushManager ola da bilmeyebilir (gizli pencere, kohne
     brauzer): hec bir hal sehife islemesini pozmur.
   ===================================================================== */
(function () {
  "use strict";

  function pubKey() { return (window.CFG && window.CFG.VAPID_PUBLIC) || ""; }

  function toKey(b64) {                       // base64url -> Uint8Array (applicationServerKey)
    var pad = "=".repeat((4 - (b64.length % 4)) % 4);
    var raw = atob((b64 + pad).replace(/-/g, "+").replace(/_/g, "/"));
    var out = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
  }

  function isIos() {
    var ua = navigator.userAgent || "";
    return /iPad|iPhone|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  }
  function standalone() {
    try {
      return (window.matchMedia && window.matchMedia("(display-mode: standalone)").matches) || navigator.standalone === true;
    } catch (e) { return false; }
  }
  function supported() {
    return !!(window.isSecureContext && "serviceWorker" in navigator && "PushManager" in window && "Notification" in window);
  }

  function offKey(role, scope) { return "b10_push_off_" + role + "_" + (scope || ""); }
  function offGet(role, scope) { try { return localStorage.getItem(offKey(role, scope)) === "1"; } catch (e) { return false; } }
  function offSet(role, scope, v) {
    try { if (v) localStorage.setItem(offKey(role, scope), "1"); else localStorage.removeItem(offKey(role, scope)); } catch (e) {}
  }

  //  Service worker hazir olmaya bilmir (http, bloklanib) - sonsuz gozlemek olmaz
  function ready() {
    return Promise.race([
      navigator.serviceWorker.ready,
      new Promise(function (_, rej) { setTimeout(function () { rej(new Error("sw")); }, 8000); })
    ]);
  }
  function currentSub() {
    return ready().then(function (reg) { return reg.pushManager.getSubscription(); }).catch(function () { return null; });
  }

  /*  Veziyyet:  off | ios | denied | ask | on
      off    - xidmet qapali (acar yoxdur) ve ya brauzer desteklemir -> hec ne gosterilmir
      ios    - iPhone, tetbiq ana ekrana elave olunmayib
      denied - brauzerde bloklanib
      ask    - icaze verilmeyib ve ya abune yoxdur / sonduruldu
      on     - abune aktivdir  */
  function state(role, scope) {
    if (!pubKey()) return Promise.resolve("off");
    if (isIos() && !standalone()) return Promise.resolve("ios");
    if (!supported()) return Promise.resolve("off");
    if (Notification.permission === "denied") return Promise.resolve("denied");
    if (Notification.permission !== "granted" || offGet(role, scope)) return Promise.resolve("ask");
    return currentSub().then(function (sub) { return sub ? "on" : "ask"; });
  }

  //  register({endpoint, p256dh, auth}) -> Promise (servere yazir)
  function enable(role, scope, register) {
    return Notification.requestPermission().then(function (p) {
      if (p !== "granted") throw new Error(p === "denied" ? "denied" : "dismissed");
      return ready();
    }).then(function (reg) {
      return reg.pushManager.getSubscription().then(function (sub) {
        return sub || reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: toKey(pubKey()) });
      });
    }).then(function (sub) {
      var j = sub.toJSON ? sub.toJSON() : {};
      var k = j.keys || {};
      return register({ endpoint: j.endpoint || sub.endpoint, p256dh: k.p256dh, auth: k.auth });
    }).then(function (r) { offSet(role, scope, false); return r; });
  }

  //  unregister(endpoint) -> Promise (serverden silir)
  function disable(role, scope, unregister) {
    return currentSub().then(function (sub) {
      offSet(role, scope, true);                       // server cavab vermese de bu cihazda sonuk say
      return sub ? unregister(sub.endpoint) : null;
    });
  }

  //  Sessiya yenilenenden sonra abuneni sakitce tazele (icaze verilib, sonduruldu deyil)
  function sync(role, scope, register) {
    if (!pubKey() || !supported() || Notification.permission !== "granted" || offGet(role, scope)) return Promise.resolve(null);
    return currentSub().then(function (sub) {
      if (!sub) return null;
      var j = sub.toJSON ? sub.toJSON() : {};
      var k = j.keys || {};
      return register({ endpoint: j.endpoint || sub.endpoint, p256dh: k.p256dh, auth: k.auth });
    }).catch(function () { return null; });
  }

  //  Cixis: bu cihazdaki bu sagirdin/valideynin abunesi silinsin (basqasi girse, ona gelmesin)
  function leave(unregister) {
    if (!pubKey() || !supported()) return Promise.resolve(null);
    return currentSub().then(function (sub) { return sub ? unregister(sub.endpoint) : null; }).catch(function () { return null; });
  }

  window.B10Push = { state: state, enable: enable, disable: disable, sync: sync, leave: leave };
})();
