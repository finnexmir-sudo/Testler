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
      //  Nisan sagirdin giris ekranindaki ile EYNIDIR - bir mehsuldur,
      //  iki giris ekrani eyni gorunmelidir.  Evvel valideyn ekraninda
      //  hec bir kimlik yox idi: saytin adi da, loqosu da gorunmurdu.
      '<div class="hero"><div class="mark"><svg viewBox="0 0 32 32" aria-hidden="true"><defs><linearGradient id="lgQ" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2b4acb"/><stop offset="1" stop-color="#0e9384"/></linearGradient></defs><path d="M12.5 3.5 H18 A8.4 8.4 0 0 1 26.4 11.9 A8.4 8.4 0 0 1 18 20.3 H13.1 L8.3 24.6 Q7.1 25.6 7.1 24 V19.1 A8.4 8.4 0 0 1 4.1 11.9 A8.4 8.4 0 0 1 12.5 3.5 Z" fill="url(#lgQ)"/><g fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round"><path d="M10.2 10.2 12.5 8.4 V16"/><ellipse cx="18.4" cy="12" rx="3.1" ry="4.1"/></g><path d="M22.5 19.5 h4.2 a3.6 3.6 0 0 1 3.6 3.6 a3.6 3.6 0 0 1-3.6 3.6 h-1 l2 3.4 -4.6-3.5 a3.6 3.6 0 0 1-4.2-3.5 a3.6 3.6 0 0 1 3.6-3.6 Z" fill="#ffc94d"/><path d="M23.4 23.2 l1.5 1.5 2.6-3" fill="none" stroke="#1a2233" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/></svg></div>' +
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
        "Kod yoxdursa müəllimdən istəyin. Giriş 30 gün açıq qalır.</p>" +
      '<p class="note" style="text-align:center;margin-top:10px">' +
        '<a href="../" class="homelink">← Bil10 ana səhifəsi</a> · ' +
        '<a href="../komek/#valideyn" class="helplink">Necə işləyir?</a></p>'
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
    topTitle.textContent = "Valideyn paneli";
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
            (p.fix ? '<em class="tag">düzəliş</em>' : "") +
            (p.diag ? '<em class="tag">diaqnostika</em>' : "") +
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
          /*  DUZELIS testi nisanlanir: valideyn 100%-i "ela yazdi"
              kimi oxumasin - o, usagin OZ sehvlerini tekrar islediyi
              testdir.  Nisan bazadaki sutundan gelir (109), teyinatdan
              tehmin edilmir: evvel "ferdi verilib"e baxirdiq ve alti
              neticenin ucunde cixirdi - hec ne ayirmirdi.  */
          return '<div class="row">' +
            "<div><b>" + esc(r.test) + "</b>" +
              (r.fix ? '<em class="tag">düzəliş</em>' : "") +
              (r.diag ? '<em class="tag">diaqnostika</em>' : "") +
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
      "Uşağınızla bağlı suallarınızı müəllimə verin — bu ekran yalnız baxmaq üçündür.</p>";

    /* ---- bize yazin: tetbiq haqqinda teklif/problem - admin oxuyur ---- */
    out += '<details class="fbd" id="fbBox"><summary>Tətbiq haqqında bizə yazın</summary>' +
      '<div class="card fbcard">' +
        '<p class="note" style="margin:0 0 10px">Nəsə aydın deyil, işləmir və ya ' +
          "təklifiniz var? Yazın — oxuyub nəzərə alacağıq.</p>" +
        '<div class="chips" id="fbK">' +
          [["teklif", "Təklif"], ["problem", "Problem"], ["sual", "Sual"],
           ["tesekkur", "Təşəkkür"]].map(function (k, i) {
            return '<button type="button" class="chip' + (i === 0 ? " on" : "") +
              '" data-k="' + k[0] + '">' + k[1] + "</button>";
          }).join("") + "</div>" +
        '<textarea id="fbT" rows="4" maxlength="2000" ' +
          'placeholder="Nə təklif edirsiniz, nə işləmir? Konkret yazın."></textarea>' +
        '<div class="fbrow"><span class="fbn" id="fbN">0 / 2000</span>' +
          '<button class="btn go" id="fbGo">Göndər</button></div>' +
        '<div id="fbM"></div>' +
      "</div></details>";

    show(out);
    on("fbK", "click", function (e) {
      var b = e.target.closest ? e.target.closest(".chip") : null;
      if (!b) return;
      Array.prototype.forEach.call(document.querySelectorAll("#fbK .chip"), function (x) {
        x.classList.toggle("on", x === b);
      });
    });
    on("fbT", "input", function () { $("fbN").textContent = $("fbT").value.length + " / 2000"; });
    on("fbGo", "click", function () {
      if (busy) return;
      var body = ($("fbT").value || "").trim();
      var k = document.querySelector("#fbK .chip.on");
      if (body.length < 10) {
        $("fbM").innerHTML = msg("warn", "Bir az ətraflı yazın — ən azı 10 simvol.");
        $("fbT").focus(); return;
      }
      setBusy("fbGo", true, "Göndər");
      sb.rpc("rpc_parent_feedback", {
        p_token: TOKEN, p_kind: (k && k.getAttribute("data-k")) || "teklif",
        p_body: body, p_page: "valideyn"
      }).then(function () {
        setBusy("fbGo", false, "Göndər");
        $("fbT").value = ""; $("fbN").textContent = "0 / 2000";
        $("fbM").innerHTML = msg("ok", "Təşəkkür edirik! Mesajınız çatdı.");
      }).catch(function (e) {
        setBusy("fbGo", false, "Göndər");
        $("fbM").innerHTML = msg("err", fail(e));
      });
    });
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
