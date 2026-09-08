/* =====================================================================
   pwa.js — tetbiqin qurasdirilmasi (muellim + sagird + valideyn)

   Iki is gorur:
   1. service worker-i qeydiyyatdan kecirir (yalniz https-de);
   2. "Ana ekrana elave et" teklifini gosterir.

   NIYE YALNIZ HTTPS:  service worker http-de onsuz da islemir, ustelik
   e2e yoxlamalari 127.0.0.1:8010 uzerinde gedir - orada worker
   qurulsa, kes yoxlamalari qeyri-muyyen edir.  Ona gore sert acikdir.

   IKI HAL VAR:
   - Android/masaustu Chrome: brauzer "beforeinstallprompt" verir,
     duymeye basanda ozu sorusur.
   - iPhone Safari: bele hadise YOXDUR.  Yalniz izah gostermek olur:
     "Paylas duymesi -> Ana ekrana elave et".
   ===================================================================== */
(function () {
  "use strict";

  var KEY = "bil10_pwa_gizlet";   // istifadeci bagladisa bir daha cixmasin
  var deferred = null;            // beforeinstallprompt hadisesi

  /*  ANA SEHIFE VE BELEDCI TETBIQ DEYIL - tanitim sehifeleridir.
      Evvel teklif hemin sehifelerde de cixirdi; oradan qurulan
      tetbiqin start_url-i kok ("/") olur, yeni acilanda tanitim
      gorunurdu ve sagird her defe "Sagird girisi"ne basmali idi
      (istifadeci).  Indi teklif YALNIZ tetbiqin ozunde cixir -
      orada manifest start_url onsuz da oz qovlugunu gosterir.  */
  var PAGE = (document.body && document.body.getAttribute("data-page")) || "";
  var SITE = PAGE === "home" || PAGE === "komek";

  function hidden() {
    try { return localStorage.getItem(KEY) === "1"; } catch (e) { return false; }
  }
  function hide() {
    try { localStorage.setItem(KEY, "1"); } catch (e) {}
    var el = document.getElementById("pwaBar");
    if (el) el.remove();
  }

  //  Artiq qurasdirilibsa teklif etmek menasizdir
  function installed() {
    return (window.matchMedia &&
            window.matchMedia("(display-mode: standalone)").matches) ||
           window.navigator.standalone === true;
  }

  function isIosSafari() {
    var ua = navigator.userAgent || "";
    var ios = /iPad|iPhone|iPod/.test(ua) ||
              //  iPadOS 13+ ozunu Mac kimi gosterir
              (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
    var safari = /Safari/.test(ua) && !/CriOS|FxiOS|EdgiOS/.test(ua);
    return ios && safari;
  }

  function bar(html) {
    if (document.getElementById("pwaBar")) return;
    var d = document.createElement("div");
    d.id = "pwaBar";
    d.className = "pwabar";
    d.innerHTML = html +
      '<button class="pwax" id="pwaNo" aria-label="Bağla">&#215;</button>';
    document.body.appendChild(d);
    var no = document.getElementById("pwaNo");
    if (no) no.addEventListener("click", hide);
  }

  /*  Toxunma ekrani var, yoxsa siçan?  "beforeinstallprompt" masaustu
      Chrome-da da isə dusur - eyni metni gostersek kompüterde
      "Tətbiqi telefona qur" yazirdiq, ki bu, sadəcə yalandir.  */
  function isTouch() {
    return (window.matchMedia &&
            window.matchMedia("(pointer: coarse)").matches) ||
           (navigator.maxTouchPoints || 0) > 0;
  }

  function showInstall() {
    bar(isTouch()
      ? '<span><b>Tətbiqi telefona qur</b>' +
        "Ana ekrandan bir toxunuşla açılsın.</span>" +
        '<button class="btn sm go" id="pwaYes">Quraşdır</button>'
      : '<span><b>Tətbiqi kompüterə qur</b>' +
        "Ayrıca pəncərədə, brauzer sətri olmadan açılsın.</span>" +
        '<button class="btn sm go" id="pwaYes">Quraşdır</button>');
    var yes = document.getElementById("pwaYes");
    if (!yes) return;
    yes.addEventListener("click", function () {
      if (!deferred) return;
      deferred.prompt();
      deferred.userChoice.then(function () {
        deferred = null;
        hide();          // cavab ne olursa olsun bir daha soruşmuruq
      });
    });
  }

  function showIosHint() {
    bar('<span><b>Ana ekrana əlavə et</b>' +
        "Aşağıdakı «Paylaş» düyməsi → «Ana ekrana əlavə et».</span>");
  }

  //  ---------------------------------------------------------- qurulus
  //  Kok unvani skriptin oz yolundan: .../assets/pwa.js -> .../
  //  (ana sehife kokdedir, panel/sagird/valideyn/beledci bir pille altda -
  //  "../sw.js" kokde sayti terk edirdi)
  var ROOT = (function () {
    var s = document.currentScript && document.currentScript.src;
    return s ? s.replace(/assets\/pwa\.js.*$/, "") : "../";
  })();
  if (location.protocol === "https:" && "serviceWorker" in navigator) {
    window.addEventListener("load", function () {
      //  Kokdeki sw.js butun sayti ehate edir (/Testler/).
      navigator.serviceWorker.register(ROOT + "sw.js", { scope: ROOT })
        .catch(function () { /* qurulmadisa tetbiq yene isleyir */ });
    });
  }

  window.addEventListener("beforeinstallprompt", function (e) {
    e.preventDefault();          // brauzerin oz cubugu cixmasin
    deferred = e;
    if (!SITE && !hidden() && !installed()) showInstall();
  });

  //  iPhone-da hadise gelmir - sehife yuklenende ozumuz teklif edirik
  window.addEventListener("load", function () {
    if (!SITE && isIosSafari() && !hidden() && !installed()) {
      setTimeout(showIosHint, 1200);
    }
  });

  window.addEventListener("appinstalled", hide);

  /* ------------------------------------------------- kokden qurulmuslar
     Yuxaridaki qayda bundan sonrasi ucundur.  Tetbiqi ARTIQ ana
     sehifeden qurmus olanlarda start_url yene kokdur - onlari da
     duzeltmek lazimdir: qurulmus tetbiq acilanda, istifadeci onsuz
     da giribse, birbasa oz bolmesine kecir.

     BRAUZERDE HEC NE DEYISMIR - ana sehife oz yerinde qalir (sayti
     kimese gostermek isteyene mane olmuruq).  Yalniz "standalone"
     pencerede, yalniz ana sehifede islenir.  */
  function signedInto() {
    function ses(k, f) {
      var v = null;
      try { v = JSON.parse(localStorage.getItem(k) || "null"); } catch (e) { return false; }
      return !!(v && f(v));
    }
    if (ses("sagird_ses", function (v) { return !!v.t; })) return "sagird/";
    if (ses("valideyn_ses", function (v) { return !!v.cur; })) return "valideyn/";
    if (ses("panel_session", function (v) { return !!v.access_token; })) return "muellim/";
    return "";
  }
  if (PAGE === "home" && installed()) {
    var go = signedInto();
    if (go) location.replace(ROOT + go);
  }
})();
