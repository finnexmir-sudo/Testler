/* =====================================================================
   Valideyn tetbiqi
   Axin: kod -> BIR ekran (veziyyet, gozleyen tapsiriq, netice, zeif
   movzu, kecilen ders).  Naviqasiya YOXDUR - valideyn telefonda 40
   saniye baxir, tetbiq oyrenmek ucun gelmir.

   Bu kodda YOXDUR ve olmamalidir:
     - duz cavablar
     - usagin oz giris kodu (yoxsa valideyn onun adindan test yazar)
     - basqa usaqlarin adlari ve ballari
   Serverde de yoxdur - rpc_parent_home onlari qaytarmir (db/107).
   ===================================================================== */
(function () {
  "use strict";

  var main     = document.getElementById("main");
  var topBar   = document.getElementById("topBar");
  var topTitle = document.getElementById("topTitle");
  var btnOut   = document.getElementById("btnOut");

  var TOKEN = null;
  var CHILD = null;
  var busy  = false;

  var LS = "valideyn_ses";

  function $(id) { return document.getElementById(id); }
  function on(id, ev, fn) { var e = $(id); if (e) e.addEventListener(ev, fn); }
  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function show(html) { busy = false; main.innerHTML = html; window.scrollTo(0, 0); }
  function msg(kind, text) {
    return '<div class="' + kind + '"><span>' + esc(text) + "</span></div>";
  }
  function fail(e) {
    var t = (e && e.message) ? e.message : String(e);
    if (/Failed to fetch|NetworkError/i.test(t)) {
      return "İnternet bağlantısı yoxdur. Yenidən cəhd et.";
    }
    if (/Sessiya bitib/i.test(t)) return "Giriş vaxtı bitib. Kodu yenidən yaz.";
    return t;
  }
  function setBusy(id, on2, label) {
    var b = $(id); busy = on2;
    if (b) { b.disabled = on2; b.textContent = on2 ? "Gözləyin…" : label; }
  }

  //  Tarix: "12 sen" - valideyn ucun qisa ve tanis
  var AY = ["yan","fev","mar","apr","may","iyn","iyl","avq","sen","okt","noy","dek"];
  function dateAz(iso) {
    if (!iso) return "";
    var d = new Date(iso);
    if (isNaN(d)) return "";
    return d.getDate() + " " + AY[d.getMonth()];
  }
  //  Son tarixe ne qalib - valideynin en cox baxdigi rəqəm
  function qalan(iso) {
    if (!iso) return "";
    var ms = new Date(iso) - new Date();
    if (isNaN(ms)) return "";
    if (ms < 0) return "vaxtı bitib";
    var gun = Math.floor(ms / 86400000);
    if (gun >= 2) return gun + " gün qalıb";
    if (gun === 1) return "sabah bitir";
    var saat = Math.floor(ms / 3600000);
    return saat >= 1 ? saat + " saat qalıb" : "bu gün bitir";
  }
  //  Faizin rengi: valideyn rəqəmi yox, RENGI oxuyur
  function faizSinif(p) {
    var n = Number(p);
    return n >= 80 ? "pv-h" : (n >= 60 ? "pv-m" : "pv-l");
  }

  /* ================================================================
     GIRIS
     ================================================================ */
  function screenLogin(note) {
    topBar.classList.add("hide");
    show(
      '<div class="hero">' +
        "<h1>Uşağınızı izləyin</h1>" +
        "<p>Müəllimin verdiyi valideyn kodunu yazın.</p></div>" +
      '<div class="card" style="margin-top:18px">' +
        (note || "") +
        '<div id="lErr"></div>' +
        '<label for="code">Valideyn kodu</label>' +
        '<input id="code" maxlength="10" autocomplete="off" autocorrect="off" ' +
          'autocapitalize="characters" spellcheck="false" placeholder="VABCD123" ' +
          'inputmode="text" enterkeyhint="go">' +
        '<button class="btn go wide" id="btnIn">Daxil ol</button>' +
      "</div>" +
      '<p class="note" style="text-align:center;margin-top:16px">' +
        "Kod yoxdursa müəllimdən istəyin. Giriş 30 gün açıq qalır.</p>"
    );
    var inp = $("code");
    inp.focus();
    inp.addEventListener("input", function () {
      inp.value = inp.value.toUpperCase().replace(/[^A-Z0-9]/g, "");
    });
    inp.addEventListener("keydown", function (e) { if (e.key === "Enter") go(); });
    on("btnIn", "click", go);

    function go() {
      if (busy) return;
      var code = (inp.value || "").trim();
      if (code.length < 6) {
        $("lErr").innerHTML = msg("err", "Kod ən azı 6 simvoldur.");
        return;
      }
      $("lErr").innerHTML = "";
      setBusy("btnIn", true, "Daxil ol");
      sb.rpc("rpc_parent_login", { p_code: code }).then(function (d) {
        if (!d || d.ok !== true) {
          setBusy("btnIn", false, "Daxil ol");
          $("lErr").innerHTML = msg("err", (d && d.error) || "Kod yanlışdır.");
          return;
        }
        TOKEN = d.token; CHILD = d.child;
        try {
          localStorage.setItem(LS, JSON.stringify({ t: TOKEN, c: CHILD }));
        } catch (e) {}
        screenHome();
      }).catch(function (e) {
        setBusy("btnIn", false, "Daxil ol");
        $("lErr").innerHTML = msg("err", fail(e));
      });
    }
  }

  /* ================================================================
     ESAS EKRAN - bir sorgu, bir sehife
     ================================================================ */
  function screenHome() {
    topBar.classList.remove("hide");
    //  Ad sehifenin ozunde iri yazilir - zolaqda tekrarlamaq telefonda
    //  ekranin basindan yer yeyirdi.
    topTitle.textContent = "Uşağım";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_parent_home", { p_token: TOKEN })
      .then(function (d) { drawHome(d || {}); })
      .catch(function (e) {
        var t = (e && e.message) || "";
        if (/Sessiya bitib/i.test(t)) { logout(true); return; }
        show(msg("err", fail(e)) +
          '<button class="btn wide" id="btnRetry" style="margin-top:12px">' +
          "Yenidən cəhd et</button>");
        on("btnRetry", "click", screenHome);
      });
  }

  function drawHome(d) {
    var s   = d.summary || {};
    var out = "";

    /* ---- basliq: kimin ekranidir ---- */
    out +=
      '<div class="who">' +
        "<b>" + esc((d.child && d.child.name) || "Uşağım") + "</b>" +
        '<span class="muted">' +
          //  Adi bos olan muellimde "müəllim: " yazib bos qoymuruq
          [ (d.child && d.child.class) || "",
            (d.teacher || "").trim() ? "müəllim: " + d.teacher.trim() : "" ]
            .filter(Boolean).map(esc).join(" · ") +
        "</span>" +
      "</div>";

    /* ---- veziyyet: CILPAQ FAIZ YOX, MEYL ----
       Valideyn "64%" gorende bunun yaxsi olub-olmadigini bilmir.
       "Kecen aya gore 8% yaxsilasib" ise derhal anlasilir. */
    out += '<div class="card sum">';
    if (s.attempts30 > 0 && s.avg30 != null) {
      out +=
        '<div class="big ' + faizSinif(s.avg30) + '">' + Math.round(s.avg30) + "%</div>" +
        "<p>Son 30 gündə <b>" + s.attempts30 + "</b> test yazıb.</p>";
      if (s.delta != null) {
        var dl = Math.round(s.delta);
        out += '<p class="trend ' + (dl >= 0 ? "up" : "down") + '">' +
          (dl > 0 ? "Keçən aya görə " + dl + "% yaxşılaşıb."
           : dl < 0 ? "Keçən aya görə " + Math.abs(dl) + "% aşağı düşüb."
           : "Keçən ayla eynidir.") + "</p>";
      } else {
        out += '<p class="muted">Müqayisə üçün keçən ayın nəticəsi yoxdur.</p>';
      }
    } else {
      out += '<p class="muted">Son 30 gündə test yazılmayıb.</p>';
    }
    out += "</div>";

    /* ---- gozleyen tapsiriq: ekranin en vacib hissesi ---- */
    var pend = d.pending || [];
    out += '<h2>Gözləyən tapşırıq</h2>';
    if (!pend.length) {
      out += '<div class="card ok-box">Gözləyən tapşırıq yoxdur.</div>';
    } else {
      out += '<div class="card pad0">' + pend.map(function (p) {
        return '<div class="row">' +
          "<div><b>" + esc(p.title) + "</b>" +
            (p.personal ? '<em class="tag">şəxsi</em>' : "") +
            "<i>" + [ p.subject, (p.questions || 0) + " sual" ]
              .filter(Boolean).map(esc).join(" · ") + "</i></div>" +
          (p.closes_at
            ? '<span class="due' + (qalan(p.closes_at).indexOf("bitir") >= 0 ||
                                    qalan(p.closes_at).indexOf("bitib") >= 0
                                    ? " soon" : "") + '">' +
              esc(qalan(p.closes_at)) + "</span>"
            : "") +
        "</div>";
      }).join("") + "</div>";
    }

    /* ---- son neticeler ---- */
    var res = d.results || [];
    if (res.length) {
      out += "<h2>Son nəticələr</h2><div class='card pad0'>" +
        res.map(function (r) {
          /*  Sexsi tapsiriq nisanlanir: "sehvler uzerinde is" testi
              adi testle qarisirdi ve valideyn 100%-i "ela yazdi" kimi
              oxuyurdu.  Gizletmek melumat gizletmek olardi - nisan
              dogru yoldur.  */
          return '<div class="row">' +
            "<div><b>" + esc(r.test) + "</b>" +
              (r.personal ? '<em class="tag">şəxsi</em>' : "") +
            "<i>" +
              [ r.subject, dateAz(r.at) ].filter(Boolean).map(esc).join(" · ") +
            "</i></div>" +
            '<span class="pct ' + faizSinif(r.percent) + '">' +
              Math.round(r.percent) + "%</span>" +
          "</div>";
        }).join("") + "</div>";
    }

    /* ---- zeif movzular ---- */
    /*  Bos bolme SESSIZCE yox olmamalidir.  Valideyn ekrani yarimciq
        gorur ve sebebini bilmir - halbuki sebebler tam ferqlidir:
        "hele az cavab var" ile "zeif movzu yoxdur" eyni sey deyil,
        ikincisi ise YAXSI xeberdir ve deyilmelidir.  */
    var weak = d.weak;
    if (weak === null) {
      out += "<h2>Zəif mövzular</h2>" +
        '<div class="card muted">Bu bölmə müəllimin abunə paketinə daxildir.</div>';
    } else if (!(weak || []).length) {
      out += "<h2>Zəif mövzular</h2>" +
        '<div class="card ok-box">' +
        ((d.results || []).length
          ? "Zəif mövzu görünmür. Bir mövzu siyahıya düşmək üçün ən azı " +
            "üç cavab lazımdır."
          : "Test yazıldıqca burada hansı mövzunun axsadığı görünəcək.") +
        "</div>";
    } else if ((weak || []).length) {
      out += "<h2>Zəif mövzular</h2><div class='card pad0'>" +
        weak.map(function (w) {
          return '<div class="row">' +
            "<div><b>" + esc(w.topic) + "</b><i>" +
              [ w.subject, w.answers + " cavab" ].filter(Boolean).map(esc).join(" · ") +
            "</i></div>" +
            '<span class="pct ' + faizSinif(w.percent) + '">' +
              Math.round(w.percent) + "%</span>" +
          "</div>";
        }).join("") + "</div>";
    }

    /* ---- kecilen dersler ---- */
    var les = d.lessons || [];
    if (!les.length) {
      out += "<h2>Keçilən dərslər</h2>" +
        '<div class="card muted">Müəllim hələ dərs planını işlətmir — ' +
        "keçilən mövzular burada görünəcək.</div>";
    } else if (les.length) {
      out += "<h2>Keçilən dərslər</h2><div class='card pad0'>" +
        les.map(function (l) {
          return '<div class="row">' +
            "<div><b>" + esc(l.topic) + "</b><i>" + esc(l.subject || "") + "</i></div>" +
            '<span class="muted sm">' + esc(dateAz(l.at)) + "</span>" +
          "</div>";
        }).join("") + "</div>";
    }

    out += '<p class="note" style="text-align:center;margin:18px 0 4px">' +
      "Suallarınızı müəllimə verin — bu ekran yalnız baxmaq üçündür.</p>";

    show(out);
  }

  /* ================================================================
     CIXIS
     ================================================================ */
  function logout(expired) {
    var t = TOKEN;
    TOKEN = null; CHILD = null;
    try { localStorage.removeItem(LS); } catch (e) {}
    if (t) { sb.rpc("rpc_parent_logout", { p_token: t }).catch(function () {}); }
    screenLogin(expired ? msg("warn", "Giriş vaxtı bitib. Kodu yenidən yazın.") : "");
  }

  btnOut.addEventListener("click", function () { logout(false); });

  /* ================================================================
     BASLANGIC
     ================================================================ */
  function boot() {
    var raw = null;
    try { raw = JSON.parse(localStorage.getItem(LS) || "null"); } catch (e) {}
    if (raw && raw.t) {
      TOKEN = raw.t; CHILD = raw.c || null;
      screenHome();
    } else {
      screenLogin("");
    }
  }

  boot();
})();
