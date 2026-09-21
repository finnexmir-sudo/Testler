/* Ziyaret saygaci (db/161).  Ana sehife ve beledci: acilanda "view",
   data-ev dugmesine basanda hadise.  Yalniz oz Supabase-imize gedir -
   kenar skript yoxdur.  IP saxlanmir (serverde gunluk duzla hash).
   Xeta olsa sakitce kecir - sehifenin isine tesir etmir.  */
(function () {
  var C = window.CFG;
  if (!C || !C.SUPABASE_URL || !C.SUPABASE_ANON_KEY) return;
  /*  NISANLAR SUZGECLERDEN EVVEL TUTULUR (217).
      Asagidaki suzgecler ZIYARETI SAYMAMAQ ucundur; nisani saxlamaq
      isə sayğac isi deyil - qeydiyyatda «kim getirdi» sualina cavabdir.
      Konkret hal: WhatsApp-in daxili brauzerinin ad setrinde «WhatsApp»
      sozu var ve robot suzgecine dusur.  Muellim linke MESAJIN ICINDEN
      basirsa (en adi hal!) nisan itirdi - aktivlesme «birbasa» kimi
      yazilardi.  Sayğac yene de sakit qalir: send() asagida, suzgeclerin
      arxasindadir.
        ?src=wa|hemkar|kurs|ig ...  - menbe (195, 204)
        ?r=WAGTYF                   - tovsiye kodu (217)  */
  var src = "";
  try {
    var m = /[?&]src=([a-z0-9_-]{1,20})(?:&|$)/i.exec(location.search || "");
    if (m) { src = m[1].toLowerCase(); sessionStorage.setItem("bil10_src", src); }
    else src = sessionStorage.getItem("bil10_src") || "";
    /*  Tovsiye kodu SESSIYADA yox, localStorage-de - 30 gun.  Sebeb:
        muellim linki acir, baxir, qapadir, sabah qeydiyyatdan kecir.
        Sessiya nisani hemin an itir ve getiren bilinmez.  30 gun
        reklam dunyasinda adi penceredir; kod sexsi melumat deyil.  */
    var mr = /[?&]r=([A-Za-z0-9]{4,12})(?:&|$)/.exec(location.search || "");
    if (mr) {
      localStorage.setItem("bil10_ref",
        JSON.stringify({ c: mr[1].toUpperCase(), t: Date.now() }));
    }
  } catch (e) {}

  /* Onbaxis sayti (yeni.bil10.az) sayilmir - orada yalniz biz baxiriq. */
  if (location.hostname.indexOf("yeni.") === 0) return;
  /* OZ ziyaretimiz sayilmir.  Nisani panel qoyur (admin girende) -
     ana sehife anonimdir, server orada kimin geldiyini bile bilmir.
     Adi muellim eyni brauzere girse panel nisani silir. */
  try { if (localStorage.getItem("bil10_oz")) return; } catch (e) {}
  /*  ROBOTLAR SAYILMIR.
      Olcu (2026-09-11): Search Console-da sitemap verdik ve "yenidən
      indeksle" dedik - hemin DEQIQEDE panelde dord teze "ziyaretci"
      cixdi, ikisi eyni saniyede.  Googlebot sehifeni acir ve JavaScript-i
      ISLEDIR, ona gore sayğac onu adam kimi yazirdi.  Bugunku 7-den 4-u
      bizim oz xahisimizin izi idi.
      Serverde ayird ede bilmirik: nə IP, nə brauzer adı saxlanılır
      (mexfilik siyasetinde bele yazmisiq) - ona gore süzgəc BURADA,
      brauzerdə olur.  Ad yoxlanır, heç yerə yazılmır.  */
  try {
    if (/bot|crawl|spider|slurp|googlebot|bingbot|yandex|duckduckbot|baiduspider|facebookexternalhit|whatsapp|telegrambot|twitterbot|linkedinbot|embedly|preview|headless|lighthouse|pagespeed/i
        .test(navigator.userAgent || "")) return;
    /*  Avtomatlasdirilmis brauzer (Playwright, Selenium) - oz
        testlerimiz de bura dusur.  */
    if (navigator.webdriver) return;
  } catch (e) {}
  var page = (document.body && document.body.getAttribute("data-page")) || "home";
  /*  MENBE (195): linkde ?src=wa kimi nisan - reklam sekli WhatsApp
      qruplarinda paylasilir, kimin haradan geldiyi bilinmirdi.  Nisan
      sessiyada saxlanir ki, ana sehifeden panele kecende de qalsin.
      Yalniz qisa, tehlukesiz deyer (server de yoxlayir).  */
  function send(ev) {
    try {
      fetch(C.SUPABASE_URL + "/rest/v1/rpc/rpc_visit", {
        method: "POST", keepalive: true,
        headers: { "Content-Type": "application/json", "apikey": C.SUPABASE_ANON_KEY,
                   "Authorization": "Bearer " + C.SUPABASE_ANON_KEY },
        body: JSON.stringify({ p_page: page, p_ev: ev, p_src: src || null })
      }).catch(function () {});
    } catch (e) {}
  }
  send("view");
  document.addEventListener("click", function (e) {
    var a = e.target && e.target.closest ? e.target.closest("[data-ev]") : null;
    if (a) send(a.getAttribute("data-ev"));
  }, true);
})();
