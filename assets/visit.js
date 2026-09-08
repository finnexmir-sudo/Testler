/* Ziyaret saygaci (db/161).  Ana sehife ve beledci: acilanda "view",
   data-ev dugmesine basanda hadise.  Yalniz oz Supabase-imize gedir -
   kenar skript yoxdur.  IP saxlanmir (serverde gunluk duzla hash).
   Xeta olsa sakitce kecir - sehifenin isine tesir etmir.  */
(function () {
  var C = window.CFG;
  if (!C || !C.SUPABASE_URL || !C.SUPABASE_ANON_KEY) return;
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
