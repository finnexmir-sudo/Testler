/* Ziyaret saygaci (db/161).  Ana sehife ve beledci: acilanda "view",
   data-ev dugmesine basanda hadise.  Yalniz oz Supabase-imize gedir -
   kenar skript yoxdur.  IP saxlanmir (serverde gunluk duzla hash).
   Xeta olsa sakitce kecir - sehifenin isine tesir etmir.  */
(function () {
  var C = window.CFG;
  if (!C || !C.SUPABASE_URL || !C.SUPABASE_ANON_KEY) return;
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
  function send(ev) {
    try {
      fetch(C.SUPABASE_URL + "/rest/v1/rpc/rpc_visit", {
        method: "POST", keepalive: true,
        headers: { "Content-Type": "application/json", "apikey": C.SUPABASE_ANON_KEY,
                   "Authorization": "Bearer " + C.SUPABASE_ANON_KEY },
        body: JSON.stringify({ p_page: page, p_ev: ev })
      }).catch(function () {});
    } catch (e) {}
  }
  send("view");
  document.addEventListener("click", function (e) {
    var a = e.target && e.target.closest ? e.target.closest("[data-ev]") : null;
    if (a) send(a.getAttribute("data-ev"));
  }, true);
})();
