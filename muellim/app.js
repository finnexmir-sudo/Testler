/* =====================================================================
   Muellim / repetitor paneli
   Butun melumat Supabase-den gelir. Sagird kodlari, qrup kodlari ve
   yer limiti SERVERDE idare olunur - burada yalniz gosterilir.
   ===================================================================== */
(function () {
  "use strict";

  var main = document.getElementById("main");
  var RECOVERY = false;   // parol berpasi axini gedir
  var topWho = document.getElementById("topWho");
  var topTitle = document.getElementById("topTitle");
  var btnOut = document.getElementById("btnOut");

  /* Minimal xetli ikonlar. Emoji yerine SVG: her platformada eyni
     gorunur ve interfeysin tonu ciddi qalir. */
  var ICON = {
    group:  '<circle cx="7.4" cy="7.4" r="2.3"/><path d="M3.4 15.1a4 4 0 0 1 8 0"/>' +
            '<path d="M12.4 6.1a2.3 2.3 0 0 1 0 4.5"/><path d="M13.4 12.3a4 4 0 0 1 2.2 2.8"/>',
    person: '<circle cx="9.5" cy="7" r="2.8"/><path d="M4.5 16a5 5 0 0 1 10 0"/>',
    plus:   '<path d="M9.5 4v11M4 9.5h11"/>',
    x:      '<path d="M5 5l9 9M14 5l-9 9"/>',
    clip:   '<rect x="4.5" y="3.5" width="10" height="13" rx="2"/>' +
            '<path d="M7.5 3.5V2.6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v.9"/>' +
            '<path d="M7 9.5l1.6 1.6L12 7.6"/>',
    copy:   '<rect x="6.5" y="6.5" width="8" height="8" rx="1.6"/>' +
            '<path d="M11.5 4.5H5a1.5 1.5 0 0 0-1.5 1.5v6.5"/>',
    send:   '<path d="M16 3 8.5 10.5"/><path d="M16 3l-4.8 13-2.7-5.5L3 7.8 16 3z"/>',
    refresh:'<path d="M15.5 8A6 6 0 0 0 4.8 5.4"/><path d="M4 3v3h3"/>' +
            '<path d="M3.5 11a6 6 0 0 0 10.7 2.6"/><path d="M15 16v-3h-3"/>',
    back:   '<path d="M11.5 4.5 6 10l5.5 5.5"/>',
    right:  '<path d="M7.5 4.5 13 10l-5.5 5.5"/>',
    warn:   '<path d="M9.5 3.2 2.8 15.2h13.4L9.5 3.2z"/><path d="M9.5 7.8v3.4"/>' +
            '<path d="M9.5 13.4h.01"/>',
    info:   '<circle cx="9.5" cy="9.5" r="6.8"/><path d="M9.5 9v3.6"/><path d="M9.5 6.6h.01"/>',
    check:  '<path d="M4 10l3.6 3.6L15 5.8"/>',
    gen:    '<path d="M9.5 3l1.5 3.8L14.8 8.3l-3.8 1.5L9.5 13.6 8 9.8 4.2 8.3 8 6.8 9.5 3z"/>' +
            '<path d="M15 12l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8.8-2z"/>',
    key:    '<circle cx="6.5" cy="12.5" r="3"/><path d="M8.7 10.3 15.5 3.5"/>' +
            '<path d="M13 6l2 2"/>',
    chart:  '<path d="M3.5 15.5h12"/><rect x="5" y="9" width="2.6" height="4.5" rx=".7"/>' +
            '<rect x="9" y="5.5" width="2.6" height="8" rx=".7"/>' +
            '<rect x="13" y="11" width="2.6" height="2.5" rx=".7"/>',
    star:   '<path d="M9.5 3l1.9 3.9 4.3.6-3.1 3 .7 4.3-3.8-2-3.8 2 .7-4.3-3.1-3 ' +
            '4.3-.6L9.5 3z"/>',
    clock:  '<circle cx="9.5" cy="9.5" r="6.8"/><path d="M9.5 5.8v4l2.6 1.5"/>',
    lock:   '<rect x="4.2" y="8.4" width="10.6" height="7.4" rx="1.6"/><path d="M6.6 8.4V6.2a2.9 2.9 0 0 1 5.8 0v2.2"/>',
    pen:    '<path d="M12.4 3.6a1.7 1.7 0 0 1 2.4 2.4L6.6 14.2l-3.1.7.7-3.1 8.2-8.2z"/>',
    doc:    '<path d="M11 2.5H6a1.8 1.8 0 0 0-1.8 1.8v10.4A1.8 1.8 0 0 0 6 16.5h7a1.8 1.8 0 0 0 1.8-1.8V6.3L11 2.5z"/>' +
            '<path d="M11 2.5v3.8h3.8"/><path d="M7.2 10h4.6M7.2 12.8h3"/>'
  };
  function ic(name, cls) {
    return '<svg class="' + (cls || "") + '" viewBox="0 0 19 19" fill="none" ' +
      'stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" ' +
      'aria-hidden="true">' + (ICON[name] || "") + "</svg>";
  }

  var LEVELS = null;   // ibtidai sinif siyahisi - bir defe yuklenir
  var CTX = null;      // rpc_my_context() neticesi
  var ACC = null;      // aktiv hesab
  var busy = false;

  /* ------------------------------------------------------ komekciler */
  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function $(id) { return document.getElementById(id); }
  /* Yeni ekran cizilende "gozleyin" veziyyeti hemise sifirlanir -
     eks halda kecid ugurlu olanda duymeler olu qalir. */
  function show(html) { busy = false; main.innerHTML = html; main.scrollTop = 0; }
  function on(id, ev, fn) { var e = $(id); if (e) e.addEventListener(ev, fn); }

  function msg(kind, text) {
    var i = kind === "ok" ? "check" : (kind === "warn" ? "warn" : "info");
    return '<div class="' + kind + '">' + ic(i) + "<span>" + esc(text) + "</span></div>";
  }
  function fail(e) {
    var t = (e && e.message) ? e.message : String(e);
    if (/limit/i.test(t) || /check_violation/i.test(t)) {
      t = t.replace(/^.*?:\s*/, "");
    }
    //  Supabase Auth-un ingilisce mesajlari - istifadeciye oz dilinde
    if (/invalid login credentials/i.test(t)) {
      return "E-poçt və ya parol yanlışdır.";
    }
    if (/email not confirmed/i.test(t)) {
      return "E-poçt hələ təsdiqlənməyib — poçtunuzdakı linkə keçin " +
             "(spam qovluğunu da yoxlayın).";
    }
    if (/already registered|already been registered/i.test(t)) {
      return "Bu e-poçtla hesab artıq var — daxil olun.";
    }
    if (/rate limit|too many requests/i.test(t)) {
      return "Çox cəhd edildi — bir neçə dəqiqə sonra yenidən yoxlayın.";
    }
    if (/password should be at least/i.test(t)) {
      return "Parol çox qısadır.";
    }
    if (/unable to validate email|invalid format/i.test(t)) {
      return "E-poçt düzgün formatda deyil.";
    }
    return t;
  }
  function setBusy(id, state, label) {
    var b = $(id);
    if (!b) return;
    busy = state;
    b.disabled = state;
    if (label) b.textContent = state ? "Gözləyin…" : label;
  }

  /* ------------------------------------------------------ giris ekrani */
  function screenAuth(mode, note) {
    mode = mode || "in";
    topTitle.textContent = "Müəllim paneli";
    topWho.textContent = "";
    btnOut.classList.add("hide");

    var isUp = mode === "up";
    show(
      '<div class="card" style="margin-top:22px">' +
        "<h1>" + (isUp ? "Hesab yaradın" : "Daxil olun") + "</h1>" +
        '<p class="note">' + (isUp
          ? "Müəllim və ya repetitor hesabı. Şagirdlərin hesabı olmur — onlara giriş kodu verirsiniz."
          : "Panelə davam etmək üçün hesabınıza daxil olun.") + "</p>" +
        (note || "") +
        '<div id="authErr"></div>' +
        (isUp ? '<label for="fname">Ad, soyad</label><input id="fname" autocomplete="name">' : "") +
        '<label for="email">E-poçt</label>' +
        '<input id="email" type="email" autocomplete="email" inputmode="email">' +
        (isUp
          ? '<label for="pass">Parol</label>'
          : '<div class="lblrow"><label for="pass">Parol</label>' +
            '<button class="lnk" id="btnForgot" type="button">Parolu unutmusunuz?</button></div>') +
        '<input id="pass" type="password" autocomplete="' +
          (isUp ? "new-password" : "current-password") + '">' +
        '<button class="btn go wide" id="btnAuth">' +
          (isUp ? "Hesab yarat" : "Daxil ol") + "</button>" +
        '<div class="spacer"></div>' +
        '<button class="btn ghost wide" id="btnSwap">' +
          (isUp ? "Hesabım var — daxil ol" : "Hesabınız yoxdur? Yaradın") + "</button>" +
      "</div>"
    );

    on("btnSwap", "click", function () { screenAuth(isUp ? "in" : "up"); });
    on("btnForgot", "click", screenForgot);
    on("btnAuth", "click", doAuth);
    ["email", "pass", "fname"].forEach(function (id) {
      on(id, "keydown", function (e) { if (e.key === "Enter") doAuth(); });
    });

    function doAuth() {
      if (busy) return;
      var email = ($("email").value || "").trim();
      var pass = $("pass").value || "";
      var fname = $("fname") ? ($("fname").value || "").trim() : "";

      if (!email || !pass) {
        $("authErr").innerHTML = msg("err", "E-poçt və parol lazımdır.");
        return;
      }
      if (isUp && pass.length < 8) {
        $("authErr").innerHTML = msg("err", "Parol ən azı 8 simvol olmalıdır.");
        return;
      }
      $("authErr").innerHTML = "";
      setBusy("btnAuth", true, isUp ? "Hesab yarat" : "Daxil ol");

      var p = isUp ? sb.signUp(email, pass, fname) : sb.signIn(email, pass);
      p.then(function (d) {
        if (isUp && (!d || !d.access_token)) {
          setBusy("btnAuth", false, "Hesab yarat");
          screenAuth("in", msg("ok",
            "Hesab yaradıldı. E-poçtunuza təsdiq məktubu göndərildi — " +
            "linkə keçdikdən sonra bura qayıdıb daxil olun."));
          return;
        }
        boot();
      }).catch(function (e) {
        setBusy("btnAuth", false, isUp ? "Hesab yarat" : "Daxil ol");
        $("authErr").innerHTML = msg("err", fail(e));
      });
    }
  }

  /* --------------------------------------------- parol berpasi */
  function screenForgot() {
    topTitle.textContent = "Parol bərpası";
    show(
      '<div class="card" style="margin-top:22px">' +
        "<h1>Parolu bərpa edin</h1>" +
        '<p class="note">Qeydiyyatdakı e-poçtunuzu yazın — bərpa linki ' +
          "göndərəcəyik. Linkə keçəndə yeni parol təyin edəcəksiniz.</p>" +
        '<div id="fgErr"></div>' +
        '<label for="fgMail">E-poçt</label>' +
        '<input id="fgMail" type="email" autocomplete="email" inputmode="email">' +
        '<button class="btn go wide" id="btnFg">Bərpa linki göndər</button>' +
        '<div class="spacer"></div>' +
        '<button class="btn ghost wide" id="btnFgBack">Girişə qayıt</button>' +
      "</div>"
    );
    var inp = $("fgMail");
    if (inp) inp.focus();
    function go() {
      if (busy) return;
      var email = (($("fgMail") || {}).value || "").trim();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        $("fgErr").innerHTML = msg("err", "Düzgün e-poçt yazın.");
        return;
      }
      setBusy("btnFg", true, "Bərpa linki göndər");
      //  redirect: berpa linki mehz bu panele qaytarsin
      var back = location.origin + location.pathname;
      sb.recover(email, back).then(function () {
        busy = false;
        screenAuth("in", msg("ok",
          "Bu e-poçtla hesab varsa, bərpa linki göndərildi. Poçtunuzu " +
          "(spam qovluğu daxil) yoxlayın — link bir dəfəlikdir."));
      }).catch(function (e) {
        setBusy("btnFg", false, "Bərpa linki göndər");
        $("fgErr").innerHTML = msg("err", fail(e));
      });
    }
    on("btnFg", "click", go);
    on("fgMail", "keydown", function (e) { if (e.key === "Enter") go(); });
  }

  /* Berpa linkinden qayidis: yeni parol ekrani */
  function screenNewPass() {
    topTitle.textContent = "Yeni parol";
    btnOut.classList.add("hide");
    show(
      '<div class="card" style="margin-top:22px">' +
        "<h1>Yeni parol təyin edin</h1>" +
        '<div id="npErr"></div>' +
        '<label for="np1">Yeni parol</label>' +
        '<input id="np1" type="password" autocomplete="new-password">' +
        '<label for="np2">Təkrar yazın</label>' +
        '<input id="np2" type="password" autocomplete="new-password">' +
        '<button class="btn go wide" id="btnNp">Parolu dəyiş</button>' +
      "</div>"
    );
    function go() {
      if (busy) return;
      var p1 = ($("np1") || {}).value || "";
      var p2 = ($("np2") || {}).value || "";
      if (p1.length < 8) {
        $("npErr").innerHTML = msg("err", "Parol ən azı 8 simvol olmalıdır.");
        return;
      }
      if (p1 !== p2) {
        $("npErr").innerHTML = msg("err", "Parollar üst-üstə düşmür.");
        return;
      }
      setBusy("btnNp", true, "Parolu dəyiş");
      sb.updatePassword(p1).then(function () {
        busy = false;
        boot();
      }).catch(function (e) {
        setBusy("btnNp", false, "Parolu dəyiş");
        $("npErr").innerHTML = msg("err", fail(e));
      });
    }
    on("btnNp", "click", go);
    ["np1", "np2"].forEach(function (id) {
      on(id, "keydown", function (e) { if (e.key === "Enter") go(); });
    });
  }

  /* --------------------------------------------------- ilk quraşdirma */
  function screenSetup() {
    topTitle.textContent = "Hesab quraşdırılması";
    show(
      '<div class="card" style="margin-top:22px">' +
        "<h1>Hesabı quraşdırın</h1>" +
        '<p class="note">Necə işlədiyinizi seçin. Sonradan dəyişmək olar.</p>' +
        '<div id="setupErr"></div>' +
        '<label for="atype">Hesab tipi</label>' +
        '<select id="atype">' +
          '<option value="tutor">Repetitor — öz qruplarım</option>' +
          '<option value="school">Məktəb müəllimi — sinif</option>' +
        "</select>" +
        '<label for="aname">Hesabın adı</label>' +
        '<input id="aname" placeholder="məsələn: Leyla müəllim — riyaziyyat">' +
        '<button class="btn go wide" id="btnSetup">Davam et</button>' +
      "</div>"
    );

    on("btnSetup", "click", function () {
      if (busy) return;
      var name = ($("aname").value || "").trim();
      if (!name) {
        $("setupErr").innerHTML = msg("err", "Hesabın adını yazın.");
        return;
      }
      setBusy("btnSetup", true, "Davam et");
      sb.rpc("rpc_create_account", { p_type: $("atype").value, p_name: name })
        .then(boot)
        .catch(function (e) {
          setBusy("btnSetup", false, "Davam et");
          $("setupErr").innerHTML = msg("err", fail(e));
        });
    });
  }

  /* ------------------------------------------------------ qrup siyahisi */
  function screenHome() {
    topTitle.textContent = ACC.name;
    show("");
    var used = ACC.students_used, lim = ACC.students_limit;
    var pct = lim > 0 ? Math.min(100, Math.round(used * 100 / lim)) : 0;
    var cls = pct >= 100 ? "bar full" : (pct >= 80 ? "bar warn" : "bar");
    var ad = ((CTX.profile && CTX.profile.full_name) || "").split(" ")[0];

    var html =
      '<h1 class="hi">Xoş gəlmisiniz' + (ad ? ", " + esc(ad) : "") + "! 👋</h1>" +
      /* Reqemler bir baxisda - "Fealiyyet merkezi"nin ust lovheleri */
      '<div class="tiles" id="hTiles">' +
        '<div class="tile a"><b>—</b><span>qrup</span></div>' +
        '<div class="tile b"><b>—</b><span>test</span></div>' +
        '<div class="tile c"><b>—</b><span>şagird</span></div>' +
        '<div class="tile d"><b>—</b><span>orta bal</span></div>' +
      "</div>" +
      '<div id="hAlerts"></div>' +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        '<div class="seat">' +
          '<div><div class="num">' + used +
            ' <s>/ ' + (lim > 1000000 ? "∞" : lim) + "</s></div>" +
            '<div class="lbl">şagird yeri</div></div>' +
          '<span class="pill' + (ACC.plan ? " on" : "") + '">' +
            esc(ACC.plan ? ACC.plan.name : "Paketsiz") + "</span>" +
        "</div>" +
        '<div class="' + cls + '"><i style="width:' + pct + '%"></i></div>' +
        (pct >= 100
          ? '<div class="warn" style="margin:14px 0 0">' + ic("warn") +
            "<span>Paketin limiti dolub. Yeni şagird əlavə etmək üçün " +
            "paketi genişləndirin.</span></div>"
          : "") +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div class="card pad0"><button class="item" id="btnBank">' +
        '<div class="ic">' + ic("doc") + "</div>" +
        '<div class="g"><b>Sual bankı</b><i><span>Öz suallarınızı yazın, ' +
          "testlərə yığın</span></i></div>" +
        '<span class="arrow">' + ic("right") + "</span></button>" +
      '<button class="item" id="btnGen">' +
        '<div class="ic">' + ic("gen") + "</div>" +
        '<div class="g"><b>Test yığ</b><i><span>Mövzu və çətinliyə görə ' +
          "avtomatik test</span></i></div>" +
        '<span class="arrow">' + ic("right") + "</span></button>" +
      '<button class="item" id="btnPkt">' +
        '<div class="ic">' + ic("star") + "</div>" +
        '<div class="g"><b>Paket</b><i><span>' +
          (ACC.plan ? "Abunə paketiniz və müddəti" :
                      "Qiymətlər və abunə") + "</span></i></div>" +
        '<span class="arrow">' + ic("right") + "</span></button>" +
      (isAdmin()
        ? '<button class="item" id="btnAdm">' +
          '<div class="ic">' + ic("group") + "</div>" +
          '<div class="g"><b>İdarəetmə</b><i><span>Hesablar və ' +
            "abunələr (admin)</span></i></div>" +
          '<span class="arrow">' + ic("right") + "</span></button>"
        : "") +
      "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Qruplar</h2>" +
      '<div id="groups" class="card pad0"><div class="skel">Yüklənir…</div></div>' +
      '<div id="hRecent"></div>' +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        '<label for="gname">Yeni qrup</label>' +
        '<div class="fieldrow">' +
          '<div><input id="gname" placeholder="məsələn: Cümə qrupu"></div>' +
          '<div style="flex:0 0 148px"><select id="glevel">' +
            '<option value="">Sinif seçilməyib</option>' +
          "</select></div>" +
        "</div>" +
        '<div id="gErr"></div>' +
        '<button class="btn go" id="btnGroup">' + ic("plus") + "Qrup yarat</button>" +
      "</div>";
    show(html);

    loadLevels().then(function () {
      var sel = $("glevel");
      if (sel) sel.innerHTML = levelOptions(null);
      loadGroups();
    });
    loadHome();

    on("btnBank", "click", function () { nav("#/b"); });
    on("btnGen", "click", function () { nav("#/gen"); });
    on("btnPkt", "click", function () { nav("#/p"); });
    on("btnAdm", "click", function () { nav("#/adm"); });

    on("btnGroup", "click", function () {
      if (busy) return;
      var name = ($("gname").value || "").trim();
      if (!name) { $("gErr").innerHTML = msg("err", "Qrupun adını yazın."); return; }
      $("gErr").innerHTML = "";
      setBusy("btnGroup", true, "Qrup yarat");
      sb.rpc("rpc_create_class", {
        p_account_id: ACC.id,
        p_name: name,
        p_kind: ACC.type === "school" ? "school_class" : "tutor_group",
        p_program_slug: "ibtidai",
        p_level_code: $("glevel").value || null
      }).then(function () {
        $("gname").value = "";
        setBusy("btnGroup", false, "Qrup yarat");
        loadGroups();
      }).catch(function (e) {
        setBusy("btnGroup", false, "Qrup yarat");
        $("gErr").innerHTML = msg("err", fail(e));
      });
    });
  }

  /* Fealiyyet merkezi: reqemler, hesab-boyu siqnallar, son neticeler.
     Yardimci melumatdir - xetasi esas ekrani pozmasin. */
  function loadHome() {
    var live = guard();
    sb.rpc("rpc_home", {}).then(function (v) {
      if (!live() || !v) return;
      var st = v.stats || {};
      var t = $("hTiles");
      if (t) {
        t.innerHTML =
          '<div class="tile a"><b>' + (st.groups || 0) + "</b><span>qrup</span></div>" +
          '<div class="tile b"><b>' + (st.tests || 0) + "</b><span>öz testiniz</span></div>" +
          '<div class="tile c"><b>' + (st.students || 0) + "</b><span>şagird</span></div>" +
          '<div class="tile d"><b>' +
            (st.attempts ? pct(st.avg) + "%" : "—") + "</b><span>orta bal</span></div>";
      }

      var ab = $("hAlerts");
      if (ab && v.alerts && v.alerts.length) {
        ab.innerHTML = '<div class="spacer"></div>' +
          "<h2>Təhlükə zonası</h2>" +
          '<div class="card pad0">' + v.alerts.map(function (a) {
            var tx;
            if (a.kind === "risk") {
              tx = "son testlərdə geriləyir (" + pct(a.prev3) + "% → " +
                   pct(a.last3) + "%)" +
                   (a.topic ? " · zəif: " + esc(a.topic) : "");
            } else if (a.kind === "weak") {
              tx = "zəif mövzu: " + esc(a.topic || "") +
                   " (" + pct(a.topic_ratio) + "%)";
            } else {
              tx = "son 3 testdə sabit " + pct(a.last3) + "% — əla gedir";
            }
            return '<button class="al ' + a.kind + '" data-al="' +
              esc(a.student_id) + '" data-g="' + esc(a.class_id) + '">' +
              ic(a.kind === "star" ? "check" : "warn") +
              "<span><b>" + esc(a.name) + "</b> <span class=\"muted\">(" +
                esc(a.class || "") + ")</span> " + tx + "</span>" +
              '<span class="arrow">' + ic("right") + "</span></button>";
          }).join("") + "</div>";
        Array.prototype.forEach.call(ab.querySelectorAll("[data-al]"), function (b) {
          b.addEventListener("click", function () {
            nav("#/s/" + b.getAttribute("data-al") + "/" + b.getAttribute("data-g"));
          });
        });
      }

      var rc = $("hRecent");
      if (rc && v.recent && v.recent.length) {
        rc.innerHTML = '<div class="spacer"></div>' +
          "<h2>Son nəticələr</h2>" +
          '<div class="card pad0">' + v.recent.map(function (x) {
            return '<div class="trow"><div class="g"><b>' + esc(x.student || "") +
              "</b><i>" + esc(x.test || "") +
              (x["class"] ? " · " + esc(x["class"]) : "") +
              " · " + dateAz(x.at) + "</i></div>" +
              '<span class="pctv">' + pct(x.percent) + "%</span></div>";
          }).join("") + "</div>";
      }
    }).catch(function () {});
  }

  function loadGroups() {
    //  loadLevels() gozleyerken cixis edilibse ACC bosdur - sakit dayan
    if (!ACC) return;
    var groups = null;
    sb.select("classes", {
      select: "id,name,join_code,kind,level_id",
      eq: { account_id: ACC.id },
      order: "name"
    }).then(function (rows) {
      groups = rows || [];
      if (!groups.length) return [];
      return sb.select("students", {
        select: "id,class_id", eq: { account_id: ACC.id }
      });
    }).then(function (studs) {
      var cnt = {};
      (studs || []).forEach(function (s) {
        cnt[s.class_id] = (cnt[s.class_id] || 0) + 1;
      });
      var rows = groups;
      var box = $("groups");
      if (!box) return;
      if (!rows || !rows.length) {
        box.innerHTML = '<div class="empty"><div class="ic">' + ic("group") + "</div>" +
          "<b>Hələ qrup yoxdur</b>Aşağıdan birincisini yaradın.</div>";
        return;
      }
      box.innerHTML = rows.map(function (g) {
        var n = cnt[g.id] || 0;
        var lv = levelName(g.level_id);
        return '<button class="item" data-g="' + esc(g.id) + '">' +
          '<div class="ic">' + ic("group") + "</div>" +
          '<div class="g"><b>' + esc(g.name) + "</b>" +
          "<i>" + (lv ? "<span>" + esc(lv) + "</span><span>·</span>" : "") +
          "<span>" + n + " şagird</span><span>·</span>" +
          '<span class="code">' + esc(g.join_code) + "</span></i></div>" +
          '<span class="arrow">' + ic("right") + "</span></button>";
      }).join("");
      Array.prototype.forEach.call(box.querySelectorAll("[data-g]"), function (b) {
        b.addEventListener("click", function () { nav("#/g/" + b.getAttribute("data-g")); });
      });
    }).catch(function (e) {
      var box = $("groups");
      if (box) box.innerHTML = '<div class="skel">' + esc(fail(e)) + "</div>";
    });
  }

  /* ----------------------------------------------- tehluke zonasi
     Sistem OZU deyir: kim gerileyir, kim zeif movzudadir, kim
     sabitdir.  Muellim tek-tek hesabat acmaga mecbur deyil.
     Az melumatda server susur - yalan siqnal inami oldurur. */
  function loadAlerts(gid) {
    var live = guard();
    sb.rpc("rpc_class_alerts", { p_class_id: gid }).then(function (v) {
      if (!live()) return;
      var box = $("alerts");
      if (!box || !v) return;
      if (v.alerts === null) return;              // pulsuz hesab - sessiz
      var list = v.alerts || [];
      if (!list.length) return;                   // siqnal yoxdursa sakitlik
      box.innerHTML = '<div class="spacer"></div>' +
        '<div class="card pad0">' + list.map(function (a) {
          var t;
          if (a.kind === "risk") {
            t = "son testlərdə geriləyir (" + pct(a.prev3) + "% → " +
                pct(a.last3) + "%)" +
                (a.topic ? " · zəif: " + esc(a.topic) : "");
          } else if (a.kind === "weak") {
            t = "zəif mövzu: " + esc(a.topic || "") +
                " (" + pct(a.topic_ratio) + "%)";
          } else {
            t = "son 3 testdə sabit " + pct(a.last3) + "% — əla gedir";
          }
          return '<button class="al ' + a.kind + '" data-al="' +
            esc(a.student_id) + '">' +
            ic(a.kind === "star" ? "check" : "warn") +
            '<span><b>' + esc(a.name) + "</b> " + t + "</span>" +
            '<span class="arrow">' + ic("right") + "</span></button>";
        }).join("") + "</div>";
      Array.prototype.forEach.call(box.querySelectorAll("[data-al]"), function (b) {
        b.addEventListener("click", function () {
          nav("#/s/" + b.getAttribute("data-al") + "/" + gid);
        });
      });
    }).catch(function () {});   /* siqnal yardimcidir - xetasi ekrani pozmasin */
  }

  /* ------------------------------------------------------- qrup detali */
  /* ================================================================
     DERS PLANI - "komekci isci"
     Movzu agaci real derslik ardicilligindadir; plan TARIXLE yox,
     ARDICILLIQLA yasayir: "Kecildi" deyilmeyince cari movzu deyismir.
     "Kecildi"den sonra sistem ozu teklif edir: yoxlama testi yigilsin?
     Test yaranan kimi qrupa tapsiriq da verilir - sagird derhal gorur.
     ================================================================ */
  var PLD = null;   // son plan_get cavabi (redraw ucun)

  function loadPlan(g) {
    var live = guard();
    sb.rpc("rpc_plan_get", { p_class_id: g.id }).then(function (d) {
      if (!live()) return;
      PLD = d || {};
      drawPlan(g);
    }).catch(function () {
      var box = $("planBox");
      if (box) box.innerHTML = "";
    });
  }

  function drawPlan(g) {
    var box = $("planBox");
    if (!box) return;
    var d = PLD || {};
    var plans = d.plans || [];

    if (!plans.length) {
      if (!d.paid) {
        box.innerHTML =
          '<div class="card plock">' +
            '<div class="lic">' + ic("lock") + "</div>" +
            "<div><b>Dərs planı — abunə paketi ilə</b>" +
            '<p class="muted" style="margin:4px 0 0">Mövzu təqvimi, «keçildi» ' +
              "jurnalı və hər mövzudan sonra bir klikə yoxlama testi. " +
              '<a href="#/p">Paketlərə bax</a></p></div>' +
          "</div>";
        return;
      }
      box.innerHTML =
        '<div class="card">' +
          '<p class="muted" style="margin:0 0 12px">Fənn və sinif seçin — ' +
            "mövzular dərslik ardıcıllığı ilə plana düzüləcək. Hər mövzunu " +
            "keçəndə bir kliklə yoxlama testi yığılıb qrupa veriləcək.</p>" +
          '<div class="fieldrow">' +
            '<div><label for="plSub">Fənn</label><select id="plSub"></select></div>' +
            '<div style="flex:0 0 150px"><label for="plLev">Sinif</label>' +
              '<select id="plLev"></select></div>' +
          "</div>" +
          '<div id="plMsg"></div>' +
          '<button class="btn go" id="btnPlMk">' + ic("plus") + "Planı qur</button>" +
        "</div>";
      //  Siyahida YALNIZ movzu agaci olan fenn+sinif kombinasiyalari -
      //  agacsiz fenni ("Kurikulum" ve s.) secib xeta almaq olmasin.
      //  Sinif siyahisi fenne gore daralir.
      sb.rpc("rpc_plan_options", {}).then(function (opts) {
        opts = opts || [];
        var sel = $("plSub"), lev = $("plLev");
        if (!sel || !lev) return;
        sel.innerHTML = opts.map(function (x) {
          return '<option value="' + esc(x.slug) + '">' + esc(x.name) + "</option>";
        }).join("");
        function fillLev() {
          var cur = null;
          for (var i = 0; i < opts.length; i++) {
            if (opts[i].slug === sel.value) cur = opts[i];
          }
          lev.innerHTML = ((cur && cur.levels) || []).map(function (x) {
            return '<option value="' + esc(x.code) + '">' + esc(x.name) + "</option>";
          }).join("");
          //  qrupun oz sinfi siyahidadirsa, onu sec
          var gl = levelName(g.level_id);
          if (gl) {
            for (var j = 0; j < lev.options.length; j++) {
              if (lev.options[j].text === gl) lev.selectedIndex = j;
            }
          }
        }
        fillLev();
        sel.addEventListener("change", fillLev);
      }).catch(function () {});
      on("btnPlMk", "click", function () {
        if (busy) return;
        setBusy("btnPlMk", true, "Planı qur");
        sb.rpc("rpc_plan_create", {
          p_class_id: g.id,
          p_subject: ($("plSub") || {}).value || "",
          p_level: ($("plLev") || {}).value || ""
        }).then(function () { busy = false; loadPlan(g); })
          .catch(function (e) {
            setBusy("btnPlMk", false, "Planı qur");
            var m = $("plMsg");
            if (m) m.innerHTML = msg("err", fail(e));
          });
      });
      return;
    }

    box.innerHTML = plans.map(function (p) {
      var items = p.items || [];
      var cur = null, lastDone = null;
      for (var i = 0; i < items.length; i++) {
        if (!items[i].done && !cur) cur = items[i];
        if (items[i].done) lastDone = items[i];
      }
      var pct = p.total ? Math.round(p.done * 100 / p.total) : 0;
      return '<div class="card plan" data-p="' + esc(p.id) + '">' +
        '<div class="plhead"><b>' + esc(p.subject) + " · " + esc(p.level) + "</b>" +
          "<span>" + p.done + " / " + p.total + " mövzu</span></div>" +
        '<div class="plbar"><i style="width:' + pct + '%"></i></div>' +
        (cur
          ? '<div class="plcur"><span class="pltag">Növbəti mövzu</span>' +
            "<b>" + cur.ord + ". " + esc(cur.topic) + "</b>" +
            '<div class="plbtns">' +
              '<button class="btn go sm" data-pldone="' + esc(cur.id) + '"' +
                (d.paid ? "" : " disabled title=\"Abunə paketi ilə\"") + ">" +
                ic("check") + "Keçildi</button>" +
            "</div>" +
            '<div class="plslot" id="pls-' + esc(p.id) + '"></div></div>'
          : '<div class="plcur done"><b>🎉 Bütün mövzular keçilib!</b>' +
            '<p class="muted" style="margin:6px 0 0">Plan tamamlanıb — ' +
            "hesabatda zəif mövzulara baxıb təkrar testlər verə bilərsiniz.</p></div>") +
        "<details><summary>Bütün mövzular</summary>" +
          '<div class="pllist">' + items.map(function (it) {
            return '<div class="plrow' + (it.done ? " ok" : "") +
              (cur && it.id === cur.id ? " cur" : "") + '">' +
              "<i>" + (it.done ? "✓" : it.ord) + "</i>" +
              "<span>" + esc(it.topic) + "</span>" +
              (it.test_id
                ? '<a href="#/t/' + esc(it.test_id) + '" class="pltest">vərəq</a>' : "") +
              (lastDone && it.id === lastDone.id
                ? '<button class="plundo" data-plundo="' + esc(it.id) +
                  '" title="Geri qaytar">geri</button>' : "") +
            "</div>";
          }).join("") + "</div>" +
          '<button class="btn sm ghost" data-pldel="' + esc(p.id) +
            '" style="margin-top:10px">Planı sil</button>' +
        "</details>" +
        '<div id="plm-' + esc(p.id) + '"></div>' +
      "</div>";
    }).join("");
    bindPlan(g);
  }

  function bindPlan(g) {
    var box = $("planBox");
    if (!box || box.dataset.bound) { if (box) rebindOnly(); return; }
    box.dataset.bound = "1";
    box.addEventListener("click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("button") : null;
      if (!b || busy) return;
      var id = b.getAttribute("data-pldone");
      if (id) return planDone(g, b, id);
      id = b.getAttribute("data-plundo");
      if (id) return planUndo(g, id);
      id = b.getAttribute("data-pldel");
      if (id) {
        if (!confirm("Plan silinsin? İrəliləyiş jurnalı itəcək " +
                     "(yığılmış testlər qalır).")) return;
        busy = true;
        sb.rpc("rpc_plan_delete", { p_plan_id: id })
          .then(function () { busy = false; loadPlan(g); })
          .catch(function () { busy = false; });
        return;
      }
      id = b.getAttribute("data-pltest");
      if (id) return planTest(g, b, id);
      id = b.getAttribute("data-plskip");
      if (id) { var s2 = $("pls-" + id); if (s2) s2.innerHTML = ""; return; }
    });
    function rebindOnly() {}
  }

  function planDone(g, b, itemId) {
    busy = true; b.disabled = true;
    sb.rpc("rpc_plan_done", { p_item_id: itemId }).then(function () {
      busy = false;
      //  yerli veziyyeti yenile ve TEKLIF goster - "komekci isci" ani
      var plan = null, topic = "";
      (PLD.plans || []).forEach(function (p) {
        (p.items || []).forEach(function (it) {
          if (it.id === itemId) { it.done = true; p.done++; plan = p; topic = it.topic; }
        });
      });
      drawPlan(g);
      var slot = plan && $("pls-" + plan.id);
      if (slot) {
        slot.innerHTML =
          '<div class="ploffer">' +
            "<b>«" + esc(topic) + "» keçildi. Yoxlama testi yığılsınmı?</b>" +
            '<p class="muted" style="margin:4px 0 10px">Test bu mövzunun ' +
              "suallarından yığılır və qrupa dərhal tapşırıq verilir " +
              "(son tarix: 7 gün, 1 cəhd).</p>" +
            '<div class="plbtns">' +
              '<input id="plCnt" type="number" min="3" max="50" value="15">' +
              '<button class="btn go sm" data-pltest="' + esc(itemId) + '">' +
                "Yığ və tapşırıq ver</button>" +
              '<button class="btn sm ghost" data-plskip="' +
                esc(plan.id) + '">Sonra</button>' +
            "</div>" +
          "</div>";
      }
    }).catch(function (e) {
      busy = false; b.disabled = false;
      alert(fail(e));
    });
  }

  function planUndo(g, itemId) {
    busy = true;
    sb.rpc("rpc_plan_undo", { p_item_id: itemId })
      .then(function () { busy = false; loadPlan(g); })
      .catch(function (e) { busy = false; alert(fail(e)); });
  }

  function planTest(g, b, itemId) {
    var n = Number(($("plCnt") || {}).value) || 15;
    busy = true; b.disabled = true;
    b.textContent = "Yığılır…";
    sb.rpc("rpc_plan_test", { p_item_id: itemId, p_count: n })
      .then(function (r) {
        busy = false;
        //  itemin testini yerli olaraq bagla, netice mesaji goster
        var pid = null;
        (PLD.plans || []).forEach(function (p) {
          (p.items || []).forEach(function (it) {
            if (it.id === itemId) { it.test_id = r.test_id; pid = p.id; }
          });
        });
        drawPlan(g);
        var m = $("plm-" + pid);
        //  msg() metni esc edir - link ucun qutunu ozumuz yigiriq
        if (m) m.innerHTML = '<div class="ok">' + ic("check") +
          "<span>Test yığıldı və qrupa tapşırıq verildi. " +
          '<a href="#/t/' + esc(r.test_id) + '">Vərəqə bax</a></span></div>';
      })
      .catch(function (e) {
        busy = false; b.disabled = false;
        b.textContent = "Yığ və tapşırıq ver";
        var slot = b.closest(".plslot") || b.parentElement;
        var err = document.createElement("div");
        err.className = "rerr";
        err.textContent = fail(e);
        slot.appendChild(err);
      });
  }

  function screenGroup(id) {
    var live = guard();
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    Promise.all([
      sb.select("classes", { select: "id,name,join_code,account_id,level_id", eq: { id: id } }),
      loadLevels()
    ])
      .then(function (res) {
        if (!live()) return;
        var rows = res[0];
        if (!rows || !rows.length) throw new Error("Qrup tapılmadı.");
        drawGroup(rows[0]);
      })
      .catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawGroup(g) {
    topTitle.textContent = g.name;
    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Qruplar</button>" +
      '<div class="spacer"></div>' +
      '<div class="card tight" id="gCard">' +
        '<div class="ttl"><h1 id="gName">' + esc(g.name) + "</h1>" +
          '<button class="btn sm ghost icon" id="btnRen" title="Adı dəyiş" ' +
            'aria-label="Adı dəyiş">' + ic("pen") + "</button></div>" +
        '<div class="muted" style="display:flex;align-items:center;gap:7px;' +
          'margin-top:8px;flex-wrap:wrap" id="gMeta">' +
          (levelName(g.level_id)
            ? "<span>" + esc(levelName(g.level_id)) + "</span><span>·</span>" : "") +
          "<span>Qoşulma kodu</span>" +
          '<span class="code key">' + esc(g.join_code) + "</span>" +
          '<button class="btn sm ghost icon" id="gCopy" title="Kodu kopyala" ' +
            'aria-label="Kodu kopyala">' + ic("copy") + "</button></div>" +
        '<div class="spacer"></div>' +
        '<div class="row two">' +
          '<button class="btn wide" id="btnAsgs">' + ic("clip") + "Tapşırıqlar</button>" +
          '<button class="btn wide" id="btnRep">' + ic("chart") + "Hesabat</button>" +
        "</div>" +
      "</div>" +
      '<div id="alerts"></div>' +
      "<h2>Dərs planı</h2>" +
      '<div id="planBox"><div class="card"><div class="skel">Yüklənir…</div></div></div>' +
      "<h2>Şagirdlər</h2>" +
      '<div id="stu" class="card pad0"><div class="skel">Yüklənir…</div></div>' +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        '<label for="sname">Yeni şagird</label>' +
        '<input id="sname" placeholder="Ad və soyad">' +
        '<p class="muted" style="margin:-8px 0 14px">Lövhədə qısa ad: ' +
          "Aysu Məmmədova → Aysu M.</p>" +
        '<div id="sErr"></div>' +
        '<button class="btn go" id="btnStu">' + ic("plus") + "Şagird əlavə et</button>" +
      "</div>"
    );

    on("btnBack", "click", function () { nav("#/"); });
    on("btnRep", "click", function () { nav("#/r/" + g.id); });
    on("btnAsgs", "click", function () { nav("#/a/" + g.id); });
    on("gCopy", "click", function () { copyText(g.join_code, $("gCopy")); });
    loadAlerts(g.id);
    loadPlan(g);
    on("btnRen", "click", function () { renameGroup(g); });
    on("sname", "keydown", function (e) { if (e.key === "Enter") addStudent(); });
    on("btnStu", "click", addStudent);

    loadStudents(g.id);

    function addStudent() {
      if (busy) return;
      var nm = ($("sname").value || "").trim();
      if (!nm) { $("sErr").innerHTML = msg("err", "Şagirdin adını yazın."); return; }
      $("sErr").innerHTML = "";
      setBusy("btnStu", true, "Şagird əlavə et");
      sb.rpc("rpc_add_student", { p_class_id: g.id, p_full_name: nm })
        .then(function () {
        $("sname").value = "";
        setBusy("btnStu", false, "Şagird əlavə et");
        return refreshContext().then(function () { loadStudents(g.id); });
      }).catch(function (e) {
        setBusy("btnStu", false, "Şagird əlavə et");
        $("sErr").innerHTML = msg("err", fail(e));
      });
    }
  }

  /* Qrupun adini yerinde deyismek */
  function renameGroup(g) {
    var card = $("gCard");
    if (!card || card.querySelector("#gRen")) return;
    card.insertAdjacentHTML("afterbegin",
      '<div id="gRen"><div class="fieldrow">' +
        '<div><label for="gNew">Qrupun adı</label>' +
          '<input id="gNew" maxlength="80"></div>' +
        '<div style="flex:0 0 148px"><label for="gLev">Sinif</label>' +
          '<select id="gLev">' + levelOptions(g.level_id) + "</select></div>" +
      "</div>" +
      '<div id="gRenErr"></div>' +
      '<div class="row"><button class="btn go" id="gSave">Yadda saxla</button>' +
      '<button class="btn ghost" id="gCancel">Ləğv et</button></div>' +
      '<div class="spacer"></div></div>');
    var inp = $("gNew");
    inp.value = g.name;
    inp.focus(); inp.select();
    inp.addEventListener("keydown", function (e) {
      if (e.key === "Enter") save();
      if (e.key === "Escape") close();
    });
    on("gCancel", "click", close);
    on("gSave", "click", save);

    function close() { var el = $("gRen"); if (el) el.remove(); }

    function save() {
      var nm = (inp.value || "").trim();
      if (!nm) { $("gRenErr").innerHTML = msg("err", "Ad boş ola bilməz."); return; }
      var code = $("gLev") ? $("gLev").value : "";
      var lv = (LEVELS || []).filter(function (x) { return x.code === code; })[0];
      var newLevel = lv ? lv.id : null;
      if (nm === g.name && newLevel === g.level_id) { close(); return; }
      $("gRenErr").innerHTML = "";
      setBusy("gSave", true, "Yadda saxla");
      sb.update("classes", { id: g.id }, { name: nm, level_id: newLevel })
        .then(function () {
          g.name = nm; g.level_id = newLevel;
          topTitle.textContent = nm;
          if ($("gName")) $("gName").textContent = nm;
          var meta = $("gMeta");
          if (meta) {
            meta.innerHTML =
              (levelName(newLevel)
                ? "<span>" + esc(levelName(newLevel)) + "</span><span>·</span>" : "") +
              "<span>Qoşulma kodu</span>" +
              '<span class="code key">' + esc(g.join_code) + "</span>";
          }
          close();
        })
        .catch(function (e) {
          setBusy("gSave", false, "Yadda saxla");
          $("gRenErr").innerHTML = msg("err", fail(e));
        });
    }
  }

  /* Lovhede gorunen qisa ad: "Aysu Məmmədova" -> "Aysu M."
     Serverdeki rpc_add_student() ile eyni qayda. */
  function shortName(full) {
    var parts = String(full || "").trim().split(/\s+/);
    if (!parts[0]) return "";
    if (parts.length < 2) return parts[0];
    return parts[0] + " " + parts[1].charAt(0).toUpperCase() + ".";
  }

  /* Sagirdin adini deyismek */
  function renameStudent(s, classId) {
    var row = document.querySelector('[data-row="' + s.id + '"]');
    if (!row || row.querySelector(".edit")) return;
    row.insertAdjacentHTML("beforeend",
      '<div class="edit"><label>Ad və soyad</label>' +
      '<input class="eName" maxlength="120">' +
      '<div class="eErr"></div>' +
      '<div class="row"><button class="btn go sm eSave">Yadda saxla</button>' +
      '<button class="btn ghost sm eCancel">Ləğv et</button></div>' +
      /* Kod yenilemek nadir ve geri qaytarilmazdir - siyahida yer
         tutmasin deye burdadir, ayrica ve seyrek gorunusde. */
      '<div class="danger"><button class="btn sm ghost" data-reset="' +
        esc(s.id) + '">' + ic("refresh") + "Giriş kodunu yenilə</button>" +
      '<span class="muted">Köhnə kod etibarsız olur.</span></div>' +
      "</div>");
    var box = row.querySelector(".edit");
    var n1 = box.querySelector(".eName");
    n1.value = s.full_name;
    n1.focus(); n1.select();
    box.querySelector(".eCancel").addEventListener("click", function () { box.remove(); });
    box.querySelector(".eSave").addEventListener("click", save);
    box.querySelector("[data-reset]").addEventListener("click", function () {
      var b = this;
      if (!confirm("Kod yenilənsin?\n\nKöhnə kod dərhal etibarsız olacaq və " +
                   "şagird yenidən daxil olmalıdır.")) return;
      b.disabled = true;
      sb.rpc("rpc_reset_student_code", { p_student_id: s.id })
        .then(function () { loadStudents(classId); })
        .catch(function (e) { b.disabled = false; alert(fail(e)); });
    });
    n1.addEventListener("keydown", function (e) {
      if (e.key === "Enter") save();
      if (e.key === "Escape") box.remove();
    });

    function save() {
      var full = (n1.value || "").trim();
      if (!full) { box.querySelector(".eErr").innerHTML = msg("err", "Ad boş ola bilməz."); return; }
      var nick = shortName(full);
      var b = box.querySelector(".eSave");
      b.disabled = true; b.textContent = "Gözləyin…";
      sb.update("students", { id: s.id }, { full_name: full, display_name: nick })
        .then(function () { loadStudents(classId); })
        .catch(function (e) {
          b.disabled = false; b.textContent = "Yadda saxla";
          box.querySelector(".eErr").innerHTML = msg("err", fail(e));
        });
    }
  }

  function loadStudents(classId) {
    sb.select("students", {
      select: "id,full_name,display_name,login_code,is_active",
      eq: { class_id: classId },
      order: "full_name"
    }).then(function (rows) {
      var box = $("stu");
      if (!box) return;
      if (!rows || !rows.length) {
        box.innerHTML = '<div class="empty"><div class="ic">' + ic("person") + "</div>" +
          "<b>Hələ şagird yoxdur</b>Aşağıdan əlavə edin.</div>";
        return;
      }
      box.innerHTML = rows.map(function (s) {
        /* Telefonda bes duymenin hamisi eyni cekide idi ve setir
           dord sətirə dagilirdi.  Indi ierarxiya var: kodu GONDERMEK
           esas isdir, kopyalamaq ikinci, ad ve kod ise qelemin altinda. */
        return '<div class="stu" data-row="' + esc(s.id) + '">' +
          /* «Hesabat» kecid oldugu ucun ADIN yanindadir - asagida yer
             qalsin deye.  Asagida yalniz kodla bagli isler var. */
          '<div class="l1">' + av(s.full_name) + "<b>" + esc(s.full_name) + "</b>" +
            '<button class="btn sm ghost link" data-rep="' + esc(s.id) + '">' +
              "Hesabat" + ic("right") + "</button>" +
            '<button class="btn sm ghost icon" data-edit="' + esc(s.id) + '" ' +
              'title="Redaktə et" aria-label="Redaktə et">' + ic("pen") + "</button></div>" +
          '<div class="l2">' +
            '<span class="code key">' + esc(s.login_code) + "</span>" +
            '<button class="btn sm ghost icon" data-copy="' + esc(s.login_code) + '" ' +
              'title="Kodu kopyala" aria-label="Kodu kopyala">' + ic("copy") + "</button>" +
            '<button class="btn sm" data-wa="' + esc(s.id) + '">' +
              ic("send") + "Göndər</button>" +
          "</div></div>";
      }).join("");

      Array.prototype.forEach.call(box.querySelectorAll("[data-copy]"), function (b) {
        b.addEventListener("click", function () {
          copyText(b.getAttribute("data-copy"), b);
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-wa]"), function (b) {
        b.addEventListener("click", function () {
          var s = rows.filter(function (x) { return x.id === b.getAttribute("data-wa"); })[0];
          if (s) window.open(waLink(s), "_blank", "noopener");
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-edit]"), function (b) {
        b.addEventListener("click", function () {
          var st = rows.filter(function (x) { return x.id === b.getAttribute("data-edit"); })[0];
          if (st) renameStudent(st, classId);
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-rep]"), function (b) {
        b.addEventListener("click", function () {
          nav("#/s/" + b.getAttribute("data-rep") + "/" + classId);
        });
      });
    }).catch(function (e) {
      var box = $("stu");
      if (box) box.innerHTML = '<div class="skel">' + esc(fail(e)) + "</div>";
    });
  }

  function waLink(s) {
    var url = (window.CFG && window.CFG.STUDENT_URL) || "";
    var t = "Salam! " + s.full_name + " üçün test girişi:\n\n" +
            "Link: " + url + "\n" +
            "Giriş kodu: " + s.login_code + "\n\n" +
            "Linki açıb kodu yazmaq kifayətdir.";
    return "https://wa.me/?text=" + encodeURIComponent(t);
  }

  function copyText(t, btn) {
    var done = function () {
      var old = btn.innerHTML;
      btn.innerHTML = ic("check") + "Kopyalandı";
      setTimeout(function () { btn.innerHTML = old; }, 1500);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(t).then(done, function () { fallback(); });
    } else { fallback(); }

    function fallback() {
      var ta = document.createElement("textarea");
      ta.value = t; ta.setAttribute("readonly", "");
      ta.style.position = "fixed"; ta.style.opacity = "0";
      document.body.appendChild(ta); ta.select();
      try { document.execCommand("copy"); done(); } catch (e) { alert(t); }
      document.body.removeChild(ta);
    }
  }

  /* ------------------------------------------------------- hesabatlar */
  function pct(v) { return Math.round(Number(v) || 0); }

  function dateAz(iso) {
    if (!iso) return "—";
    var d = new Date(iso);
    if (isNaN(d)) return "—";
    var ay = ["yan","fev","mar","apr","may","iyn","iyl","avq","sen","okt","noy","dek"];
    return d.getDate() + " " + ay[d.getMonth()];
  }

  /* Nisbi vaxt: siyahilarda "3 gun evvel" tarixden tez oxunur */
  function agoAz(iso) {
    if (!iso) return "heç vaxt";
    var d = new Date(iso);
    if (isNaN(d)) return "heç vaxt";
    var g = Math.floor((Date.now() - d.getTime()) / 86400000);
    if (g <= 0) return "bu gün";
    if (g === 1) return "dünən";
    if (g < 30) return g + " gün əvvəl";
    return dateAz(iso);
  }

  /* Menimseme zolagi: 0-49 zeif, 50-74 orta, 75+ yaxsi */
  function meter(ratio) {
    var r = pct(ratio);
    /*  DIQQET: "ok" YAZMA - base.css-de umumi mesaj qutusudur;
        meter-i mint renge boyayib zolagi gizledirdi (3-cu toqqusma!) */
    var cls = r >= 75 ? "m-ok" : (r >= 50 ? "m-mid" : "m-low");
    return '<div class="meter ' + cls + '"><i style="width:' + r + '%"></i></div>';
  }

  function upsell(what) {
    return '<div class="upsell">' + ic("star") +
      "<div><b>" + esc(what) + "</b>" +
      "<span>Abunə paketində açılır: mövzu üzrə zəif nöqtələr, " +
      "təkrar səhv edilən suallar və tam irəliləyiş tarixçəsi.</span></div></div>";
  }

  function screenReport(gid, quiet) {
    var live = guard();
    if (!quiet) show('<div class="card"><div class="skel">Hesabat hazırlanır…</div></div>');

    sb.rpc("rpc_class_report", { p_class_id: gid }).then(function (r) {
      if (!live()) return;
      topTitle.textContent = (r.class && r.class.name) || "Hesabat";
      var sm = r.summary || {};
      var h =
        '<div class="row" style="justify-content:space-between;align-items:center">' +
          '<button class="btn sm ghost" id="btnB">' + ic("back") + "Qrup</button>" +
          '<button class="btn sm ghost" id="btnRef" title="Yenilə">' +
            ic("refresh") + "Yenilə</button></div>" +
        '<div class="spacer"></div>' +
        '<div class="stats">' +
          statTile(sm.active + " / " + sm.students, "aktiv şagird", "g1") +
          statTile(pct(sm.avg) + "%", "orta nəticə", "g2") +
          statTile(sm.attempts || 0, "işlənmiş test", "g3") +
        "</div>";

      if (!r.paid) {
        h += '<p class="muted" style="margin:2px 0 16px">' + ic("clock") +
             " Son " + 7 + " günün məlumatı göstərilir.</p>";
      }

      h += "<h2>Şagirdlər</h2>";
      var st = r.students || [];
      if (!st.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("person") +
             "</div><b>Şagird yoxdur</b></div></div>";
      } else {
        h += '<div class="card pad0">' + st.map(function (s) {
          return '<button class="item" data-s="' + esc(s.id) + '">' +
            av(s.full_name) +
            '<div class="g"><b>' + esc(s.full_name) + "</b>" +
            "<i><span>" + (s.attempts || 0) + " test</span><span>·</span>" +
            "<span>son: " + dateAz(s.last_at) + "</span></i>" +
            meter(s.avg) + "</div>" +
            '<span class="pctv">' + (s.attempts ? pct(s.avg) + "%" : "—") + "</span>" +
            '<span class="arrow">' + ic("right") + "</span></button>";
        }).join("") + "</div>";
      }

      h += "<h2>Mövzular</h2>";
      if (r.topics === null) {
        h += upsell("Mövzu üzrə analiz");
      } else if (!r.topics.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("chart") +
             "</div><b>Hələ kifayət qədər cavab yoxdur</b>" +
             "Mövzu üzrə nəticə üçün ən azı 3 cavab lazımdır.</div></div>";
      } else {
        h += '<div class="card pad0">' + r.topics.map(function (t) {
          return '<div class="trow"><div class="g"><b>' + esc(t.name) + "</b>" +
            "<i>" + esc(t.subject) + " · " + t.correct + " / " + t.total + "</i>" +
            meter(t.ratio) + "</div>" +
            '<span class="pctv">' + pct(t.ratio) + "%</span></div>";
        }).join("") + "</div>";
        /* Dovreni baglayan duyme: zeif movzular -> hazir test.
           Generator qrupun SEHV ETDIYI suallara benzeyenleri de
           avtomatik one cekir (rule.class). */
        var weak = r.topics.filter(function (t) { return Number(t.ratio) < 60; });
        if (weak.length) {
          h += '<div class="spacer"></div>' +
            '<button class="btn go wide" id="btnRem">' + ic("gen") +
            "Zəif mövzulardan test yığ (" + weak.length + ")</button>";
        }
      }

      if (r.recent && r.recent.length) {
        h += "<h2>Son fəaliyyət</h2><div class=\"card pad0\">" +
          r.recent.map(function (x) {
            return '<div class="trow"><div class="g"><b>' + esc(x.student) + "</b>" +
              "<i>" + esc(x.test) + " · " + dateAz(x.at) + "</i></div>" +
              '<span class="pctv">' + pct(x.percent) + "%</span></div>";
          }).join("") + "</div>";
      }

      show(h);
      stamp();
      on("btnB", "click", function () { nav("#/g/" + gid); });
      on("btnRef", "click", function () { screenReport(gid); });
      on("btnRem", "click", function () {
        var weak = (r.topics || []).filter(function (t) { return Number(t.ratio) < 60; });
        remedialGen(gid, weak);
      });
      Array.prototype.forEach.call(main.querySelectorAll("[data-s]"), function (b) {
        b.addEventListener("click", function () {
          nav("#/s/" + b.getAttribute("data-s") + "/" + gid);
        });
      });
    }).catch(function (e) {
      if (quiet || !live()) return;           // sessiz yenilemede ekrani pozma
      show(msg("err", fail(e)) + '<button class="btn wide" id="btnB2">Geri</button>');
      on("btnB2", "click", function () { nav("#/g/" + gid); });
    });
  }

  /* Son yenilenme vaxti - muellim melumatin teze oldugunu bilsin */
  function stamp() {
    var d = new Date();
    var t = ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
    var el = document.createElement("p");
    el.className = "muted";
    el.style.cssText = "text-align:center;margin:14px 0 0";
    el.textContent = "Son yenilənmə: " + t;
    main.appendChild(el);
  }

  /* Sinif siyahisi hem qrup yaratmaqda, hem de gostermekde lazimdir -
     bir defe yuklenib yaddasda saxlanilir. */
  function loadLevels() {
    if (LEVELS) return Promise.resolve(LEVELS);
    //  Sinif esasli seviyyeler (kod reqemdir: 1-11). MIQ/sertifikasiya
    //  pilleleri sinif deyil - bura dusmur.
    return sb.select("levels", { select: "id,code,name", order: "sort" })
      .then(function (rows) {
        LEVELS = (rows || []).filter(function (l) {
          return /^[0-9]+$/.test(l.code);
        });
        return LEVELS;
      })
      .catch(function () { LEVELS = []; return LEVELS; });
  }

  function levelName(id) {
    if (!id || !LEVELS) return "";
    var l = LEVELS.filter(function (x) { return x.id === id; })[0];
    return l ? l.name : "";
  }

  function levelOptions(sel) {
    return '<option value="">Sinif seçilməyib</option>' +
      (LEVELS || []).map(function (l) {
        return '<option value="' + esc(l.code) + '"' +
          (l.id === sel ? " selected" : "") + ">" + esc(l.name) + "</option>";
      }).join("");
  }

  /* ---------------------------------------------- valideyn xulasesi
     Repetitorun agrisi: pulu valideyn odeyir, amma neticeni gormur.
     Hazir metn - kopyala, WhatsApp-a yapisdir.  Iki uslub: semimi
     (emoji + zolaqlar) ve resmi.  Metn EKRANDAKI melumatdan qurulur -
     ayri sorgu yoxdur, yalan da yoxdur. */
  var VSTY = "isti";

  function velBar(ratio) {
    var k = Math.max(0, Math.min(5, Math.round(Number(ratio) / 20)));
    return new Array(k + 1).join("▰") + new Array(5 - k + 1).join("▱");
  }

  function velText(style, r) {
    var st = r.student || {};
    var name = (st.full_name || "").split(" ")[0] || "Şagird";
    var atts = r.attempts || [];
    var cut = Date.now() - 30 * 864e5;
    var use = atts.filter(function (a) {
      return new Date(a.at).getTime() >= cut;
    });
    var dovr = "son 30 gün";
    if (!use.length) { use = atts; dovr = "ümumi"; }
    var n = use.length;
    var sum = 0, best = 0;
    use.forEach(function (a) {
      var p = Number(a.percent) || 0;
      sum += p; if (p > best) best = p;
    });
    var avg = n ? Math.round(sum / n) : 0;

    /* Tereqqi: son 3 vs evvelki 3 - hesabatdaki qayda ile eyni */
    var tr = "";
    if (use.length >= 4) {
      var la = 0, pa = 0, l3 = use.slice(0, 3), p3 = use.slice(3, 6);
      l3.forEach(function (a) { la += (Number(a.percent) || 0) / l3.length; });
      p3.forEach(function (a) { pa += (Number(a.percent) || 0) / p3.length; });
      tr = la - pa >= 5 ? "up" : (pa - la >= 5 ? "down" : "flat");
    }

    var tops = (r.topics || []).slice().sort(function (a, b) {
      return Number(b.ratio) - Number(a.ratio);
    });
    var strong = tops.filter(function (t) { return Number(t.ratio) >= 80; }).slice(0, 2);
    var weak = tops.filter(function (t) { return Number(t.ratio) < 60; }).slice(-2);
    var teacher = (CTX && CTX.profile && CTX.profile.full_name) || "";
    var L = [];

    if (style === "resmi") {
      L.push("Hörmətli valideyn,");
      L.push("");
      L.push(name + " üzrə " + dovr + " nəticələri:");
      L.push("• İşlənən test: " + n);
      L.push("• Ortalama nəticə: " + avg + "% (ən yaxşısı " + best + "%)");
      if (tr === "up")   L.push("• Son testlərdə irəliləyiş müşahidə olunur.");
      if (tr === "down") L.push("• Son testlərdə nəticə enməyə meyllidir — birlikdə işləyirik.");
      if (strong.length) L.push("Güclü mövzular: " + strong.map(function (t) {
        return t.name + " (" + pct(t.ratio) + "%)"; }).join(", "));
      if (weak.length) L.push("Üzərində işlədiyimiz mövzular: " + weak.map(function (t) {
        return t.name + " (" + pct(t.ratio) + "%)"; }).join(", "));
      L.push("");
      L.push("Hörmətlə," + (teacher ? " " + teacher : ""));
    } else {
      L.push("📊 " + name + " — " + dovr + " (Bil10)");
      L.push("");
      L.push("✅ İşlənən test: " + n);
      L.push("📈 Ortalama: " + avg + "% · Ən yaxşısı: " + best + "%");
      if (tr === "up")   L.push("↗ Son testlərdə irəliləyiş var");
      if (tr === "down") L.push("↘ Son testlərdə enmə var — üzərində işləyirik");
      if (strong.length || weak.length) L.push("");
      strong.forEach(function (t) {
        L.push("💪 " + t.name + "  " + velBar(t.ratio) + " " + pct(t.ratio) + "%");
      });
      weak.forEach(function (t) {
        L.push("🎯 " + t.name + "  " + velBar(t.ratio) + " " + pct(t.ratio) + "%");
      });
      if (teacher) { L.push(""); L.push(teacher); }
    }
    return L.join("\n");
  }

  /* Ad avatari: bas herf + sabit reng (ada gore) - siyahilar cansiz
     gorunmesin */
  function av(name) {
    var n = String(name || "?").trim();
    var ch = n.charAt(0).toUpperCase() || "?";
    var k = 7;
    for (var i = 0; i < n.length; i++) k = (k * 31 + n.charCodeAt(i)) % 100003;
    k = k % 6;
    return '<span class="av c' + k + '">' + esc(ch) + "</span>";
  }

  function statTile(val, lbl, cls) {
    return '<div class="stat ' + (cls || "") + '"><b>' + esc(String(val)) +
      "</b><span>" + esc(lbl) + "</span></div>";
  }

  function screenStudent(id, classId) {
    var live = guard();
    topTitle.textContent = "Şagird hesabatı";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');

    sb.rpc("rpc_student_report", { p_student_id: id }).then(function (r) {
      if (!live()) return;
      var s = r.student || {}, sm = r.summary || {};
      var h =
        '<button class="btn sm ghost" id="btnB">' + ic("back") + "Geri</button>" +
        '<div class="spacer"></div>' +
        '<div class="card tight"><h1>' + esc(s.full_name) + "</h1>" +
          '<div class="muted" style="display:flex;align-items:center;gap:7px;margin-top:8px">' +
            "<span>" + esc(s.display_name) + "</span>" +
            '<span class="code key">' + esc(s.login_code) + "</span></div></div>" +
        '<div class="stats">' +
          statTile(sm.attempts || 0, "test", "g1") +
          statTile(pct(sm.avg) + "%", "orta", "g2") +
          statTile(pct(sm.best) + "%", "ən yaxşı", "g3") +
        "</div>";

      if (r.topics !== null) {
        h += "<h2>Valideyn üçün xülasə</h2>" +
          '<div class="card">' +
            '<div class="segs" id="vSty">' +
              seg("isti",  "Səmimi", VSTY) +
              seg("resmi", "Rəsmi",  VSTY) +
            "</div>" +
            '<textarea id="vTxt" class="veltxt" readonly rows="12"></textarea>' +
            '<p class="muted" style="margin:0 0 12px">Mətni kopyalayıb ' +
              "WhatsApp-da valideynə göndərin.</p>" +
            '<button class="btn go" id="vCopy">' + ic("clip") + "Kopyala</button>" +
          "</div>";
      }

      h += "<h2>Mövzu üzrə mənimsəmə</h2>";
      if (r.topics === null) {
        h += upsell("Mövzu üzrə mənimsəmə");
      } else if (!r.topics.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("chart") +
             "</div><b>Hələ kifayət qədər cavab yoxdur</b></div></div>";
      } else {
        h += '<div class="card pad0">' + r.topics.map(function (t) {
          return '<div class="trow"><div class="g"><b>' + esc(t.name) + "</b>" +
            "<i>" + esc(t.subject) + " · " + t.correct + " / " + t.total + "</i>" +
            meter(t.ratio) + "</div>" +
            '<span class="pctv">' + pct(t.ratio) + "%</span></div>";
        }).join("") + "</div>";
        var sweak = r.topics.filter(function (t) { return Number(t.ratio) < 60 && t.id; });
        if (sweak.length) {
          h += '<div class="spacer"></div>' +
            '<button class="btn go wide" id="btnRem">' + ic("gen") +
            "Zəif mövzulardan test yığ (" + sweak.length + ")</button>";
        }
      }

      if (r.weak !== null && r.weak && r.weak.length) {
        /* Uzun siyahi sehifeni yeyirdi - indi QATLANIR: bagli halda
           yalniz basliq + say gorunur, klikle acilir.  Setirler de
           yigcamdir: sual bir-iki setir, izah bir setir. */
        h += '<details class="more filt wrongbox">' +
          "<summary>Təkrar səhv edilən suallar " +
            '<span class="fn">' + r.weak.length + "</span></summary>" +
          '<div class="card pad0" style="margin-top:10px">' +
          r.weak.map(function (w) {
            return '<div class="wq"><div class="g"><b>' + esc(w.body) + "</b>" +
              (w.explanation ? "<i>" + esc(w.explanation) + "</i>" : "") +
              '</div><span class="wn">' + w.wrong + "×</span></div>";
          }).join("") + "</div></details>";
      }

      h += "<h2>Test tarixçəsi</h2>";
      var at = r.attempts || [];
      if (!at.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("clock") +
             "</div><b>Hələ test işləməyib</b></div></div>";
      } else {
        h += '<div class="card pad0">' + at.map(function (a) {
          return '<div class="trow"><div class="g"><b>' + esc(a.test) + "</b>" +
            "<i>" + dateAz(a.at) + " · " + a.score + " / " + a.max + "</i></div>" +
            '<span class="pctv">' + pct(a.percent) + "%</span></div>";
        }).join("") + "</div>";
      }

      show(h);
      if ($("vTxt")) {
        $("vTxt").value = velText(VSTY, r);
        on("vSty", "click", function (e) {
          var b = e.target.closest ? e.target.closest("[data-v]") : null;
          if (!b) return;
          VSTY = b.getAttribute("data-v");
          Array.prototype.forEach.call(
            document.querySelectorAll("#vSty .seg"), function (x) {
              x.classList.toggle("on", x.getAttribute("data-v") === VSTY);
            });
          $("vTxt").value = velText(VSTY, r);
        });
        on("vCopy", "click", function () { copyText($("vTxt").value, $("vCopy")); });
      }
      on("btnB", "click", function () { nav("#/r/" + classId); });
      on("btnRem", "click", function () {
        var sweak = (r.topics || []).filter(function (t) { return Number(t.ratio) < 60 && t.id; });
        remedialGen(classId, sweak);
      });
    }).catch(function (e) {
      if (!live()) return;
      show(msg("err", fail(e)) + '<button class="btn wide" id="btnB3">Geri</button>');
      on("btnB3", "click", function () { nav("#/r/" + classId); });
    });
  }

  /* --------------------------------------------------------- marsrut */
  /* Ekran unvanin hash hissesinde saxlanilir: sehife yenilenende muellim
     yerini itirmir, "geri" duymesi de brauzerde isleyir. */
  /* Sürətlə keçid edəndə köhnə sorğunun cavabı yeni ekranın üstünə
     yazıla bilər. Hər ekran başlayanda hansı ünvanda olduğunu yadda
     saxlayır; cavab gələndə ünvan dəyişibsə heç nə çizmir. */

  /* ================================================================
     TAPSIRIQLAR  -  muellim teste "son tarix" qoyub qrupa verir.
     Sagird panelinde bu testler "Tapsiriqlar" bolmesinde gorunur.
     ================================================================ */
  function screenAssign(gid) {
    var live = guard();
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    Promise.all([
      sb.select("classes", { select: "id,name,level_id", eq: { id: gid } }),
      sb.rpc("rpc_class_assignments", { p_class_id: gid }),
      loadLevels()
    ]).then(function (res) {
      if (!live()) return;
      var rows = res[0];
      if (!rows || !rows.length) throw new Error("Qrup tapılmadı.");
      drawAssign(rows[0], res[1] || {});
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawAssign(g, d) {
    topTitle.textContent = g.name;
    var items = d.items || [];
    var free  = d.free_practice !== false;

    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + esc(g.name) + "</button>" +
      '<div class="spacer"></div>' +
      '<div class="card tight">' +
        "<h1>Tapşırıqlar</h1>" +
        '<p class="muted" style="margin:8px 0 0">Seçdiyiniz test şagirdin ' +
          "səhifəsində «Tapşırıqlar» bölməsində görünür. Son tarix keçəndə " +
          "avtomatik bağlanır.</p>" +
        '<div class="spacer"></div>' +
        '<div class="swrap"><label class="switch" for="fp">' +
          '<input type="checkbox" id="fp"' + (free ? " checked" : "") + ">" +
          '<span class="track"><i></i></span>' +
          "<span><b>Sərbəst məşq</b>" +
            '<span class="muted">Şagird platformanın digər testlərini də ' +
              "istədiyi vaxt işləyə bilər.</span></span></label>" +
        '<div id="fpErr"></div></div>' +
      "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Verilmiş tapşırıqlar</h2>" +
      '<div id="asgList" class="card pad0">' + asgRows(items, d.students || 0) + "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Yeni tapşırıq</h2>" +
      '<div id="pick" class="card"><div class="skel">Testlər yüklənir…</div></div>'
    );

    on("btnBack", "click", function () { nav("#/g/" + g.id); });
    on("fp", "change", function () {
      var el = $("fp");
      var val = el.checked;
      el.disabled = true;
      $("fpErr").innerHTML = "";
      sb.update("classes", { id: g.id }, { free_practice: val })
        .then(function () { el.disabled = false; })
        .catch(function (e) {
          el.disabled = false; el.checked = !val;
          $("fpErr").innerHTML = msg("err", fail(e));
        });
    });

    bindAsgRows(g);
    loadPick(g);
  }

  function asgRows(items, students) {
    if (!items.length) {
      return '<div class="empty"><div class="ic">' + ic("clip") + "</div>" +
        "<b>Hələ tapşırıq verilməyib</b>" +
        "Aşağıdan test seçin — şagirdlər dərhal görəcək.</div>";
    }
    return items.map(function (a) {
      var open = a.open !== false;
      var done = Number(a.done) || 0;
      var tries = Number(a.max_attempts) === 0 ? "limitsiz cəhd"
                : (Number(a.max_attempts) || 1) + " cəhd";
      return '<div class="asg">' +
        '<div class="l1"><b>' + esc(a.title) + "</b>" +
          '<span class="pill' + (open ? " on" : "") + '">' +
            (open ? "Aktiv" : "Bağlı") + "</span>" +
          '<button class="btn sm ghost icon" data-del="' + esc(a.id) + '" ' +
            'title="Tapşırığı götür" aria-label="Tapşırığı götür">' + ic("x") + "</button>" +
        "</div>" +
        '<div class="l2">' + esc(a.subject || "") + " · " +
          (Number(a.questions) || 0) + " sual · " + tries +
          (a.closes_at ? " · son tarix " + dateAz(a.closes_at) : "") + "</div>" +
        '<div class="l2">' + done + "/" + students + " şagird bitirib" +
          (a.avg != null ? " · orta " + pct(a.avg) + "%" : "") + "</div>" +
      "</div>";
    }).join("");
  }

  function bindAsgRows(g) {
    var box = $("asgList");
    if (!box) return;
    box.addEventListener("click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("[data-del]") : null;
      if (!b || busy) return;
      var id = b.getAttribute("data-del");
      busy = true; b.disabled = true;
      sb.rpc("rpc_unassign_test", { p_assignment_id: id })
        .then(function () { busy = false; screenAssign(g.id); })
        .catch(function (e) {
          busy = false; b.disabled = false;
          box.insertAdjacentHTML("afterend", msg("err", fail(e)));
        });
    });
  }

  /* Teyin edile bilen testler: sinife uygun olanlar */
  function loadPick(g) {
    var live = guard();
    sb.rpc("rpc_available_tests", { p_class_id: g.id }).then(function (list) {
      if (!live()) return;
      var box = $("pick");
      if (!box) return;
      list = list || [];
      var free = list.filter(function (t) { return !t.assigned; });
      /* Iki ayri hal - eyni mesaji vermek olmaz:
         siyahi tamam bosdursa bu sinif ucun hele test YAZILMAYIB. */
      if (!list.length) {
        box.innerHTML = '<div class="empty"><div class="ic">' + ic("doc") + "</div>" +
          "<b>Bu sinif üçün hələ test yoxdur</b>" +
          "Test bazasına " + esc(levelName(g.level_id) || "bu sinif") +
          " materialları hələ əlavə olunmayıb. Qrupun sinfini dəyişsəniz " +
          "(yuxarıdakı qələm düyməsi) mövcud testlər açılacaq.</div>";
        return;
      }
      if (!free.length) {
        box.innerHTML = '<div class="empty"><div class="ic">' + ic("check") + "</div>" +
          "<b>Bütün testlər verilib</b>Bu sinif üçün başqa test qalmayıb.</div>";
        return;
      }
      box.innerHTML =
        '<label for="aTest">Test</label>' +
        '<select id="aTest">' + free.map(function (t) {
          /* Testin adi onsuz da fennle baslayirsa fenni tekrar yazmiriq:
             "Azerbaycan dili - Azerbaycan dili - 1" cirkin cixirdi. */
          var sub = String(t.subject || "");
          var ttl = String(t.title || "");
          var lbl = (sub && ttl.indexOf(sub) !== 0) ? sub + " — " + ttl : ttl;
          return '<option value="' + esc(t.id) + '">' + esc(lbl) +
            " (" + (Number(t.questions) || 0) + " sual)" +
            (t.is_free ? "" : " · abunə") + "</option>";
        }).join("") + "</select>" +
        '<div class="fieldrow">' +
          '<div><label for="aDate">Son tarix</label>' +
            '<input type="date" id="aDate"></div>' +
          '<div style="flex:0 0 148px"><label for="aTry">Cəhd sayı</label>' +
            '<select id="aTry"><option value="1">1 cəhd</option>' +
              '<option value="2">2 cəhd</option><option value="3">3 cəhd</option>' +
              '<option value="0">Limitsiz</option></select></div>' +
        "</div>" +
        '<p class="muted" style="margin:-8px 0 14px">Son tarix boş qalsa, ' +
          "tapşırıq siz götürənə qədər açıq qalır.</p>" +
        '<div id="aErr"></div>' +
        '<button class="btn go" id="btnAsg">' + ic("plus") + "Tapşırıq ver</button>";
      on("btnAsg", "click", function () { doAssign(g); });
    }).catch(function (e) {
      if (!live()) return;
      var box = $("pick");
      if (box) box.innerHTML = msg("err", fail(e));
    });
  }

  function doAssign(g) {
    if (busy) return;
    var tid = ($("aTest") || {}).value;
    if (!tid) return;
    var day = ($("aDate") || {}).value || "";
    var closes = null;
    if (day) {
      /* Gunun sonu - saat 23:59 yerli vaxtla */
      var d = new Date(day + "T23:59:00");
      if (isNaN(d)) { $("aErr").innerHTML = msg("err", "Tarix düzgün deyil."); return; }
      if (d.getTime() <= Date.now()) {
        $("aErr").innerHTML = msg("err", "Son tarix bu gündən sonra olmalıdır."); return;
      }
      closes = d.toISOString();
    }
    $("aErr").innerHTML = "";
    setBusy("btnAsg", true, "Tapşırıq ver");
    sb.rpc("rpc_assign_test", {
      p_class_id: g.id, p_test_id: tid,
      p_closes_at: closes, p_max_attempts: Number(($("aTry") || {}).value || 1)
    }).then(function () { screenAssign(g.id); })
      .catch(function (e) {
        setBusy("btnAsg", false, "Tapşırıq ver");
        $("aErr").innerHTML = msg("err", fail(e));
      });
  }


  /* ================================================================
     PAKET - qiymetler ve el ile satis (merhele 1)
     Odenis provayderi yoxdur: muellim WhatsApp-la yazir, pulu
     kocurur, admin abunesini acir.  Duyme CFG.CONTACT_WHATSAPP
     nomresine acilir - config.js-de teyin olunur.
     ================================================================ */
  function isAdmin() {
    return !!(CTX && CTX.roles && CTX.roles.indexOf("admin") >= 0);
  }

  function azn(minor) {
    var m = Number(minor) || 0;
    return (m % 100 === 0 ? String(m / 100) : (m / 100).toFixed(2)) + " ₼";
  }

  function screenPaket() {
    var live = guard();
    topTitle.textContent = "Paket";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_paket", {}).then(function (v) {
      if (!live()) return;
      drawPaket(v || {});
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawPaket(v) {
    var cur = v.current;
    var wa = (window.CFG && window.CFG.CONTACT_WHATSAPP) || "";
    var mail = (CTX && CTX.profile && CTX.profile.full_name) || "";
    var h =
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Əsas səhifə</button>" +
      '<div class="spacer"></div>' +
      '<div class="card tight">' +
        "<h1>Abunə</h1>" +
        (cur
          ? '<p class="muted" style="margin:8px 0 0">Hazırkı paket: <b>' +
            esc(cur.plan) + "</b>" +
            (cur.ends ? " · bitmə tarixi: " + dateAz(cur.ends) : "") + "</p>"
          : '<p class="muted" style="margin:8px 0 0">Hazırda abunəniz yoxdur. ' +
            "Öz suallarınız və əsas hesabat pulsuzdur; platforma sual bankı, " +
            "avtomatik test, dərin analitika və siqnallar paketə daxildir.</p>") +
      "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Paketlər</h2>" +
      (v.plans || []).map(function (p) {
        var price = azn(p.price_minor) + (p.period === "year" ? " / il" : " / ay") +
          (Number(p.price_per_seat_minor)
            ? " + " + azn(p.price_per_seat_minor) + " hər şagird" : "");
        return '<div class="card tight pkt' +
          (cur && cur.slug === p.slug ? " on" : "") + '">' +
          '<div class="seat"><div>' +
            "<b>" + esc(p.name) + "</b>" +
            '<div class="lbl">' +
              (p.max_students ? p.max_students + " şagird yeri · " : "") +
              "platforma bankı · generator · analitika · siqnallar</div>" +
          "</div>" +
          '<span class="pctv">' + esc(price) + "</span></div>" +
        "</div>";
      }).join("") +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        "<b>Necə almaq olar?</b>" +
        '<p class="muted" style="margin:8px 0 14px">Hələlik ödəniş əl ilə ' +
          "qəbul olunur: bizə yazın, paketi seçin, köçürmə ilə ödəyin — " +
          "abunəniz dərhal açılsın.</p>" +
        (wa
          ? '<a class="btn go" id="btnWa" target="_blank" rel="noopener" href="' +
            esc("https://wa.me/" + wa.replace(/[^0-9]/g, "") +
                "?text=" + encodeURIComponent(
                  "Salam! Bil10-da paket almaq istəyirəm." +
                  (mail ? " Hesab: " + mail : ""))) +
            '">WhatsApp-la yazın</a>'
          : '<p class="muted">Əlaqə nömrəsi hələ təyin olunmayıb ' +
            "(config.js → CONTACT_WHATSAPP).</p>") +
      "</div>";
    show(h);
    on("btnBack", "click", function () { nav("#/"); });
  }

  /* ---------------------------------------------------------- admin */
  var admFlash = "";   // redraw-dan sonra bir defe gosterilen netice mesaji

  var F2 = null;   // 2FA veziyyeti (enabled/unlocked)

  function screenAdmin() {
    var live = guard();
    topTitle.textContent = "İdarəetmə";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_admin_2fa_status", {}).then(function (st2) {
      if (!live()) return;
      F2 = st2 || {};
      if (F2.enabled && !F2.unlocked) return drawAdmLock();
      Promise.all([
        sb.rpc("rpc_admin_stats", {}),
        sb.rpc("rpc_admin_accounts", { p_q: null }),
        sb.rpc("rpc_admin_reports", { p_status: "new" })
      ]).then(function (r) {
        if (!live()) return;
        drawAdmin(r[0] || {}, r[1] || [], r[2] || []);
      }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  /* Kilid ekrani: Authenticator kodu ve ya birtefelik ehtiyat kod */
  function drawAdmLock() {
    show(
      '<div class="lock card">' +
        '<div class="lic">' + ic("lock") + "</div>" +
        "<h1>İdarəetmə kilidlidir</h1>" +
        '<p class="muted">Authenticator tətbiqindəki 6 rəqəmli kodu və ya ' +
          "birtəfəlik ehtiyat kodu daxil edin.</p>" +
        '<div class="lrow"><input id="ulCode" maxlength="9" autocomplete="one-time-code" ' +
          'placeholder="000000">' +
        '<button class="btn go" id="btnUl">Aç</button></div>' +
        '<div id="ulMsg"></div>' +
      "</div>"
    );
    var inp = $("ulCode");
    if (inp) inp.focus();
    function go() {
      if (busy) return;
      busy = true;
      sb.rpc("rpc_admin_unlock", { p_code: ($("ulCode") || {}).value || "" })
        .then(function (r) {
          busy = false;
          if (r && r.ok) return screenAdmin();
          $("ulMsg").innerHTML = msg("err", (r && r.err) || "Kod düzgün deyil.");
        }).catch(function (e) {
          busy = false;
          $("ulMsg").innerHTML = msg("err", fail(e));
        });
    }
    on("btnUl", "click", go);
    on("ulCode", "keydown", function (e) { if (e.key === "Enter") go(); });
  }

  function drawAdmin(st, rows, reps) {
    var plans = (st.plans && st.plans.length) ? st.plans
      : [{ slug: "repetitor-25", name: "Repetitor — 25 şagird" }];
    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Əsas səhifə</button>" +
      '<div class="spacer"></div>' +
      '<div class="tiles">' +
        '<div class="tile a"><b>' + (st.accounts || 0) + "</b><span>hesab" +
          ((st.accounts_week || 0) > 0 ? " · +" + st.accounts_week + " bu həftə" : "") +
          "</span></div>" +
        '<div class="tile b"><b>' + (st.paid_accounts || 0) + "</b><span>pullu · " +
          Math.max(0, (st.accounts || 0) - (st.paid_accounts || 0)) + " pulsuz</span></div>" +
        '<div class="tile c"><b>' + azn(st.mrr_minor || 0) + "</b><span>aylıq gəlir</span></div>" +
        '<div class="tile d"><b>' + (st.attempts_week || 0) + "</b><span>cəhd · son 7 gün</span></div>" +
      "</div>" +
      '<div class="card tight">' +
        "<h1>Hesablar</h1>" +
        '<p class="muted" style="margin:8px 0 0">«+1 ay / +6 ay» seçilmiş planı ' +
          "həmin hesaba açır. Eyni plan aktivdirsə, müddət " +
          "üstünə əlavə olunur.</p>" +
        '<div class="fieldrow" style="margin-top:12px">' +
          '<div><input id="admQ" placeholder="Ad və ya e-poçtla axtar…"></div>' +
          '<div style="flex:0 0 230px"><select id="admPlan">' +
            plans.map(function (pl) {
              return '<option value="' + esc(pl.slug) + '">' + esc(pl.name) + "</option>";
            }).join("") +
          "</select></div>" +
        "</div>" +
        '<div class="chips" id="admF">' +
          [["", "Hamısı"], ["pullu", "Pullu"], ["pulsuz", "Pulsuz"],
           ["bitir", "Bitmək üzrə"]]
            .map(function (f) {
              return '<button class="chip' + (f[0] === "" ? " on" : "") +
                '" data-f="' + f[0] + '">' + f[1] + "</button>";
            }).join("") +
        "</div>" +
        '<div id="admMsg">' + admFlash + "</div>" +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div id="admList" class="card pad0">' + admRows(rows) + "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Bildirişlər" + (reps.length
        ? ' <span class="rcnt">' + reps.length + "</span>" : "") + "</h2>" +
      '<div class="chips" id="repF">' +
        '<button class="chip on" data-rs="new">Yeni</button>' +
        '<button class="chip" data-rs="fixed">Düzəldilib</button>' +
        '<button class="chip" data-rs="rejected">Rədd edilib</button>' +
      "</div>" +
      '<div id="repList">' + (REPS_CACHE = reps, repCards(reps, "new")) + "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Təhlükəsizlik</h2>" +
      '<div class="card" id="secBox">' + secCard() + "</div>"
    );
    admFlash = "";
    //  standart secim - en cox satilan repetitor paketi
    var sel0 = $("admPlan");
    if (sel0 && sel0.querySelector('option[value="repetitor-25"]')) {
      sel0.value = "repetitor-25";
    }
    on("btnBack", "click", function () { nav("#/"); });
    function admQuery() {
      var fb = document.querySelector("#admF .chip.on");
      sb.rpc("rpc_admin_accounts", {
        p_q: (($("admQ") || {}).value || "").trim() || null,
        p_f: (fb && fb.getAttribute("data-f")) || null
      }).then(function (rows2) {
        var box = $("admList");
        if (box) box.innerHTML = admRows(rows2 || []);
      }).catch(function () {});
    }
    var t = null;
    on("admQ", "input", function () {
      clearTimeout(t); t = setTimeout(admQuery, 350);
    });
    on("admF", "click", function (ev) {
      var b = ev.target.closest ? ev.target.closest(".chip") : null;
      if (!b) return;
      var cur = document.querySelector("#admF .chip.on");
      if (cur) cur.classList.remove("on");
      b.classList.add("on");
      admQuery();
    });
    bindAdm();
    bindRep();
    on("repF", "click", function (ev) {
      var b = ev.target.closest ? ev.target.closest(".chip") : null;
      if (!b) return;
      var cur = document.querySelector("#repF .chip.on");
      if (cur) cur.classList.remove("on");
      b.classList.add("on");
      var st2 = b.getAttribute("data-rs");
      sb.rpc("rpc_admin_reports", { p_status: st2 }).then(function (r) {
        REPS_CACHE = r || [];
        var box = $("repList");
        if (box) box.innerHTML = repCards(REPS_CACHE, st2);
      }).catch(function () {});
    });
    bindSec();
  }

  function admRows(rows) {
    if (!rows.length) {
      return '<div class="empty"><div class="ic">' + ic("group") + "</div>" +
        "<b>Hesab tapılmadı</b></div>";
    }
    return rows.map(function (a) {
      var pl = a.plan, badge;
      if (pl) {
        //  bitmesine 7 gunden az qalibsa narinci - uzatmaq vaxtidir
        var gq = pl.ends
          ? Math.max(0, Math.ceil((new Date(pl.ends).getTime() - Date.now()) / 86400000))
          : null;
        //  basqa ilin tarixine il de yazilir - "25 avq · 365 gun"
        //  cashdirmasin (novbeti ilin 25 avqustudur)
        var yr = "";
        if (pl.ends) {
          var ed = new Date(pl.ends);
          if (!isNaN(ed) && ed.getFullYear() !== new Date().getFullYear()) {
            yr = " " + ed.getFullYear();
          }
        }
        badge = '<span class="pb ' + (gq !== null && gq < 7 ? "z" : "y") + '">' +
          esc(pl.name) +
          (pl.ends ? " → " + dateAz(pl.ends) + yr + " · " + gq + " gün" : "") +
          "</span>";
      } else {
        badge = '<span class="pb n">paketsiz</span>';
      }
      return '<div class="admr" data-em="' + esc(a.email || "") + '">' +
        av(a.name) +
        '<div class="g"><b>' + esc(a.name) + "</b>" + badge +
        "<i>" +
          "<span>" + esc(a.email || "") + "</span><span>·</span>" +
          "<span>" + (a.students || 0) + " şagird</span><span>·</span>" +
          "<span>" + (a.tests || 0) + " test</span><span>·</span>" +
          "<span>" + (a.attempts || 0) + " cəhd</span><span>·</span>" +
          "<span>aktivlik: " + agoAz(a.last_active) + "</span>" +
        "</i></div>" +
        '<div class="btns">' +
          '<button class="btn sm" data-m="1">+1 ay</button>' +
          '<button class="btn sm" data-m="6">+6 ay</button>' +
          (pl ? '<button class="btn sm ghost" data-stop="1">Dayandır</button>' : "") +
        "</div></div>";
    }).join("");
  }

  function bindAdm() {
    var box = $("admList");
    if (!box || box.dataset.bound) return;
    box.dataset.bound = "1";
    box.addEventListener("click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("button") : null;
      if (!b || busy) return;
      var row = b.closest(".admr");
      if (!row) return;
      var em = row.getAttribute("data-em");
      var call, args;
      if (b.getAttribute("data-stop")) {
        if (!confirm(em + " — abunəni dayandırmaq?")) return;
        call = "rpc_admin_stop"; args = { p_email: em };
      } else {
        var sel = $("admPlan");
        var ay = Number(b.getAttribute("data-m")) || 1;
        var ad = (sel && sel.selectedIndex >= 0)
          ? sel.options[sel.selectedIndex].text : "";
        if (!confirm(em + " → " + ad + " (+" + ay + " ay). Açılsın?")) return;
        call = "rpc_admin_grant";
        args = { p_email: em, p_plan: (sel || {}).value || "repetitor-25",
                 p_months: ay };
      }
      busy = true; b.disabled = true;
      sb.rpc(call, args).then(function (res) {
        busy = false;
        admFlash = msg("ok", em + " — yerinə yetirildi" +
          (res && res.ends ? ". Qüvvədədir: " + dateAz(res.ends) : "") + ".");
        screenAdmin();
      }).catch(function (e) {
        busy = false; b.disabled = false;
        $("admMsg").innerHTML = msg("err", fail(e));
      });
    });
  }


  /* --------------------------------------- admin: bildiris kartlari */
  var R_LBL = { cavab: "Cavab səhvdir", sert: "Şərt qüsurludur",
                yazi: "Yazı xətası", diger: "Digər" };

  function repCards(reps, st) {
    if (!reps.length) {
      return '<div class="card"><p class="muted" style="margin:0">' +
        (st === "new" ? "Yeni bildiriş yoxdur — bank təmizdir. 👌"
                      : "Bu siyahı boşdur.") + "</p></div>";
    }
    return reps.map(function (r) {
      var qid = r.question_id;
      return '<div class="card repc" data-q="' + esc(qid) + '">' +
        '<div class="rhead"><b>' + esc(r.body) + "</b>" +
          '<span class="rcnt">' + r.n + "</span></div>" +
        '<div class="qm">' +
          (r.subject ? "<span>" + esc(r.subject) + "</span>" : "") +
          (r.level ? "<span>·</span><span>" + esc(r.level) + "</span>" : "") +
          (r.topic ? "<span>·</span><span>" + esc(r.topic) + "</span>" : "") +
          "<span>·</span><span>" +
            (r.owner === "platform" ? "platforma" : "müəllimin öz sualı") +
          "</span></div>" +
        (r.options || []).map(function (o) {
          return '<div class="popt' + (o.is_correct ? " ok" : "") + '">' +
            (o.is_correct ? ic("check") : "") + "<span>" + esc(o.body) +
            "</span></div>";
        }).join("") +
        '<div class="rwho">' + (r.reports || []).map(function (x) {
          return '<div class="rline"><b>' + esc(x.who || "") + "</b>" +
            "<span>·</span><span>" + (x.kind === "sagird" ? "şagird" : "müəllim") +
            "</span><span>·</span><span>" + (R_LBL[x.reason] || x.reason) +
            "</span>" + (x.note ? '<i>«' + esc(x.note) + "»</i>" : "") + "</div>";
        }).join("") + "</div>" +
        (st === "new"
          ? '<div class="rbtns">' +
              (r.owner === "platform"
                ? '<button class="btn sm" data-fix="' + esc(qid) + '">Düzəlt</button>'
                : "") +
              '<button class="btn sm ghost" data-rej="' + esc(qid) + '">Rədd et</button>' +
              (r.owner === "platform"
                ? "" : '<button class="btn sm ghost" data-cls="' + esc(qid) +
                       '">Baxıldı</button>') +
            "</div>" +
            '<div class="fslot" id="fs-' + esc(qid) + '"></div>' +
            '<div id="fm-' + esc(qid) + '"></div>'
          : "") +
      "</div>";
    }).join("");
  }

  /* Yerinde duzelis redaktoru: metn + izah + variantlar, duz cavab radio */
  function fixForm(r) {
    return '<div class="ffrm">' +
      "<label>Sual mətni</label>" +
      '<textarea class="fbody" rows="2">' + esc(r.body) + "</textarea>" +
      "<label>İzah</label>" +
      '<textarea class="fexp" rows="2">' + esc(r.explanation || "") + "</textarea>" +
      "<label>Variantlar — düzgün olanı seçin</label>" +
      (r.options || []).map(function (o) {
        return '<div class="fopt"><input type="radio" name="fc-' + esc(r.question_id) +
          '"' + (o.is_correct ? " checked" : "") + ' data-oid="' + esc(o.id) + '">' +
          '<input type="text" class="fob" data-oid="' + esc(o.id) + '" value="' +
          esc(o.body).replace(/"/g, "&quot;") + '"></div>';
      }).join("") +
      '<div class="rbtns">' +
        '<button class="btn go sm" data-save="' + esc(r.question_id) + '">Saxla</button>' +
        '<button class="btn sm ghost" data-fcancel="' + esc(r.question_id) + '">İmtina</button>' +
      "</div></div>";
  }

  var REPS_CACHE = [];

  function bindRep() {
    var box = $("repList");
    if (!box || box.dataset.bound) return;
    box.dataset.bound = "1";
    box.addEventListener("click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("button") : null;
      if (!b || busy) return;
      var qid = b.getAttribute("data-fix");
      if (qid) {
        var card = b.closest(".repc");
        var slot = $("fs-" + qid);
        if (!slot) return;
        if (slot.innerHTML) { slot.innerHTML = ""; return; }
        //  kartin oz melumatindan forma yigilir - serverden tezeden istemirik
        var r = findRep(qid);
        if (r) slot.innerHTML = fixForm(r);
        return;
      }
      qid = b.getAttribute("data-fcancel");
      if (qid) { var s2 = $("fs-" + qid); if (s2) s2.innerHTML = ""; return; }
      qid = b.getAttribute("data-rej") || b.getAttribute("data-cls");
      if (qid) {
        if (!confirm(b.getAttribute("data-rej")
              ? "Bildirişlər rədd edilsin? Sual olduğu kimi qalır."
              : "Baxıldı kimi bağlansın?")) return;
        busy = true; b.disabled = true;
        sb.rpc("rpc_admin_report_set", { p_question: qid,
            p_status: b.getAttribute("data-rej") ? "rejected" : "fixed" })
          .then(function () { busy = false; screenAdmin(); })
          .catch(function (e) {
            busy = false; b.disabled = false;
            var m = $("fm-" + qid);
            if (m) m.innerHTML = msg("err", fail(e));
          });
        return;
      }
      qid = b.getAttribute("data-save");
      if (qid) {
        var slot3 = $("fs-" + qid);
        if (!slot3) return;
        var opts = [];
        Array.prototype.forEach.call(slot3.querySelectorAll(".fob"), function (inp) {
          var oid = inp.getAttribute("data-oid");
          var rad = slot3.querySelector('input[type="radio"][data-oid="' + oid + '"]');
          opts.push({ id: oid, body: inp.value,
                      is_correct: !!(rad && rad.checked) });
        });
        busy = true; b.disabled = true;
        sb.rpc("rpc_admin_fix_question", {
          p_question: qid,
          p_body: (slot3.querySelector(".fbody") || {}).value || "",
          p_explanation: (slot3.querySelector(".fexp") || {}).value || "",
          p_options: opts
        }).then(function () {
          busy = false;
          admFlash = msg("ok", "Sual düzəldildi, bildirişlər bağlandı.");
          screenAdmin();
        }).catch(function (e) {
          busy = false; b.disabled = false;
          var m2 = $("fm-" + qid);
          if (m2) m2.innerHTML = msg("err", fail(e));
        });
      }
    });
  }

  function findRep(qid) {
    for (var i = 0; i < REPS_CACHE.length; i++) {
      if (REPS_CACHE[i].question_id === qid) return REPS_CACHE[i];
    }
    return null;
  }

  /* --------------------------------------- admin: 2FA karti */
  function secCard() {
    if (F2 && F2.enabled) {
      return '<p style="margin:0 0 10px">' + ic("check", "okic") +
        " İkinci amil (Authenticator) <b>aktivdir</b>. Panel hər 12 saatdan " +
        "bir kod istəyəcək.</p>" +
        '<div class="lrow"><input id="s2Code" maxlength="9" placeholder="Kod">' +
        '<button class="btn sm ghost" id="btn2Off">Söndür</button></div>' +
        '<div id="s2Msg"></div>';
    }
    return '<p style="margin:0 0 10px">İdarəetməni ikinci amillə qoruyun: ' +
      "telefondakı <b>Google Authenticator</b> (və ya bənzər) tətbiqindən " +
      "6 rəqəmli kod istənəcək. Parol oğurlansa belə panel açılmayacaq.</p>" +
      '<button class="btn go sm" id="btn2On">' + ic("lock") + "2FA qur</button>" +
      '<div id="s2Box"></div><div id="s2Msg"></div>';
  }

  function bindSec() {
    on("btn2On", "click", function () {
      if (busy) return;
      busy = true;
      sb.rpc("rpc_admin_2fa_setup", {}).then(function (r) {
        busy = false;
        var box = $("s2Box");
        if (!box) return;
        box.innerHTML =
          '<div class="s2setup">' +
            "<p><b>1.</b> Authenticator tətbiqində «hesab əlavə et» → " +
              "«açarı əl ilə daxil et» seçin və bu açarı yazın:</p>" +
            '<code class="s2key">' + esc(r.secret || "") + "</code>" +
            "<p><b>2.</b> Bu birtəfəlik ehtiyat kodları təhlükəsiz yerdə " +
              "saxlayın — telefon itəndə hər biri bir dəfə giriş verir:</p>" +
            '<div class="s2bkp">' + (r.backup || []).map(function (c) {
              return "<code>" + esc(c) + "</code>";
            }).join("") + "</div>" +
            "<p><b>3.</b> Tətbiqin göstərdiyi kodu daxil edib təsdiqləyin:</p>" +
            '<div class="lrow"><input id="s2New" maxlength="6" placeholder="000000">' +
            '<button class="btn go sm" id="btn2Ok">Təsdiqlə</button></div>' +
          "</div>";
        on("btn2Ok", "click", function () {
          if (busy) return;
          busy = true;
          sb.rpc("rpc_admin_2fa_confirm", { p_code: ($("s2New") || {}).value || "" })
            .then(function (r2) {
              busy = false;
              if (r2 && r2.ok) {
                admFlash = msg("ok", "2FA aktivləşdi. Növbəti girişlər kodla olacaq.");
                return screenAdmin();
              }
              $("s2Msg").innerHTML = msg("err", (r2 && r2.err) || "Kod düzgün deyil.");
            }).catch(function (e) {
              busy = false;
              $("s2Msg").innerHTML = msg("err", fail(e));
            });
        });
      }).catch(function (e) {
        busy = false;
        $("s2Msg").innerHTML = msg("err", fail(e));
      });
    });
    on("btn2Off", "click", function () {
      if (busy) return;
      if (!confirm("2FA söndürülsün? Panel yalnız parolla qalacaq.")) return;
      busy = true;
      sb.rpc("rpc_admin_2fa_disable", { p_code: ($("s2Code") || {}).value || "" })
        .then(function (r) {
          busy = false;
          if (r && r.ok) { admFlash = msg("ok", "2FA söndürüldü."); return screenAdmin(); }
          $("s2Msg").innerHTML = msg("err", (r && r.err) || "Kod düzgün deyil.");
        }).catch(function (e) {
          busy = false;
          $("s2Msg").innerHTML = msg("err", fail(e));
        });
    });
  }


  /* ================================================================
     GENERATOR - suzgece gore avtomatik test
     Secimi SERVER edir (13_generator.sql): movzular arasinda beraber
     boluslur, yerdeyismis tekrarlar ve eyni cavab yigini atilir.
     Burda yalniz suzgec, onizleme ve veraq var.
     ================================================================ */
  var GF = null;

  function genFilter() {
    if (!GF) GF = { pool: (ACC && ACC.plan) ? "all" : "mine",
                    subject: "", level: "", topics: [], difficulty: [],
                    count: 10, title: "",
                    cls: "", remNames: [] };
    return GF;
  }

  function genRule(f) {
    var r = { pool: f.pool, count: f.count };
    if (f.subject) r.subject = f.subject;
    if (f.level) r.level = f.level;
    if (f.topics.length) r.topics = f.topics;
    if (f.difficulty.length) r.difficulty = f.difficulty;
    if (f.cls) r["class"] = f.cls;
    return r;
  }

  /* Hesabatdan gelen "duzelis testi" niyyeti: zeif movzular secili,
     qrup qeyd olunub - generator hemin qrupun sehvlerine benzeyen
     suallari one cekecek. */
  function remedialGen(gid, weak) {
    var f = genFilter();
    f.difficulty = [];
    f.topics = weak.map(function (t) { return t.id; });
    f.remNames = weak.map(function (t) { return t.name; });
    f.cls = gid;
    f.count = Math.min(10, Math.max(5, f.topics.length * 3));
    f.title = "Düzəliş testi";
    /* Fenn ve sinif de avtomatik secilir - muellim yalniz "Testi yig"
       basir.  Amma YALNIZ butun zeif movzular eyni fenn/sinifdedirse:
       qarisiq siyahida fenn suzgeci movzularin bir hissesini keserdi
       (qayda fenn VE movzu ile suzur). */
    var subs = {}, levs = {};
    weak.forEach(function (t) {
      if (t.subject_slug) subs[t.subject_slug] = 1;
      if (t.level) levs[t.level] = 1;
    });
    var sk = Object.keys(subs), lk = Object.keys(levs);
    f.subject = sk.length === 1 ? sk[0] : "";
    f.level   = lk.length === 1 ? lk[0] : "";
    nav("#/gen");
  }

  function screenGen() {
    var live = guard();
    var f = genFilter();
    topTitle.textContent = "Test yığ";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_bank_facets", { p_subject: f.subject || null,
                                p_level: f.level || null, p_pool: f.pool })
      .then(function (fac) { if (!live()) return; FAC = fac || {}; drawGen(); })
      .catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawGen() {
    var f = genFilter();
    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Əsas səhifə</button>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        "<h1>Avtomatik test</h1>" +
        '<p class="muted" style="margin:8px 0 0">Süzgəci seçin — sistem ' +
          "hovuzdan balanslı test yığacaq: mövzular arasında bərabər, " +
          "təkrarsız.</p>" +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div class="card tight">' +
        '<div class="segs" id="gPool">' +
          seg("mine", "Öz suallarım", f.pool) +
          seg("platform", "Platforma", f.pool) +
          seg("all", "Hamısı", f.pool) +
        "</div>" +
        (f.cls && f.topics.length
          ? '<div class="ok" style="margin:12px 0 0">' + ic("check") +
            "<span>Hesabatdan gələn zəif mövzular seçilib: " +
            esc(f.remNames.join(", ")) +
            ". Qrupun səhv etdiyi suallara bənzəyənlər önə çəkiləcək. " +
            '<a href="#" id="gRemOff">Təmizlə</a></span></div>'
          : "") +
        (f.pool !== "mine" && !(ACC && ACC.plan)
          ? '<div class="warn" style="margin:12px 0 0">' + ic("warn") +
            "<span>Platforma hovuzu abunə paketinə daxildir. " +
            "Öz suallarınızdan yığa bilərsiniz.</span></div>"
          : "") +
        '<div class="fieldrow" style="margin-top:12px">' +
          '<div><label for="gsub">Fənn</label>' +
            '<select id="gsub"><option value="">Bütün fənlər</option>' +
            (FAC.subjects || []).filter(function (x) {
              return Number(x.n) > 0 || f.subject === x.slug;
            }).map(function (x) {
              return '<option value="' + esc(x.slug) + '"' +
                (f.subject === x.slug ? " selected" : "") + ">" + esc(x.name) + "</option>";
            }).join("") + "</select></div>" +
          '<div style="flex:0 0 140px"><label for="glev">Sinif</label>' +
            '<select id="glev"><option value="">Hamısı</option>' +
            (FAC.levels || []).map(function (l) {
              return '<option value="' + esc(l.code) + '"' +
                (f.level === l.code ? " selected" : "") + ">" + esc(l.name) + "</option>";
            }).join("") + "</select></div>" +
        "</div>" +
        '<div class="chips" id="gDiff">' +
          [1, 2, 3].map(function (d) {
            return '<button class="chip' + (f.difficulty.indexOf(d) >= 0 ? " on" : "") +
              '" data-d="' + d + '">' + DIFF[d] + "</button>";
          }).join("") +
        "</div>" +
        /* Movzu nisanlari yalniz FENN + SINIF secilende cixir.  Sinifsiz
           fennin DORD sinfinin movzulari tokulur - telefonda 40+ nisan
           gozu yorurdu.  Sinifle en coxu ~12 nisan olur. */
        (!f.subject || !f.level
          ? '<p class="muted" style="margin:12px 0 0">' +
            (!f.subject
              ? "Mövzu seçmək üçün fənn və sinif seçin. "
              : "Mövzu seçmək üçün sinif də seçin. ") +
            "Mövzu seçilməsə, hamısından götürüləcək.</p>"
          : ((FAC.topics || []).length
              ? '<div class="chips" id="gTop">' + FAC.topics.map(function (t) {
                  return '<button class="chip' + (f.topics.indexOf(t.id) >= 0 ? " on" : "") +
                    '" data-t="' + esc(t.id) + '">' +
                    esc(topLabel(t, f.level)) + "</button>";
                }).join("") + "</div>"
              : '<p class="muted" style="margin:12px 0 0">Bu fənn üçün mövzu yoxdur.</p>')) +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        '<div class="fieldrow">' +
          '<div><label for="gTitle">Testin adı</label>' +
            '<input id="gTitle" maxlength="120" placeholder="məsələn: Riyaziyyat — 1-ci rüb" value="' +
            esc(f.title) + '"></div>' +
          '<div style="flex:0 0 140px"><label for="gCnt">Sual sayı</label>' +
            '<input id="gCnt" type="number" min="1" max="100" inputmode="numeric" value="' +
            f.count + '"></div>' +
        "</div>" +
        '<div id="gPrev"><div class="skel">Hovuz yoxlanılır…</div></div>' +
        '<div id="gErr"></div>' +
        '<button class="btn go" id="btnMake">' + ic("gen") + "Testi yığ</button>" +
      "</div>"
    );

    on("btnBack", "click", function () { nav("#/"); });
    on("gRemOff", "click", function (e) {
      e.preventDefault();
      f.cls = ""; f.remNames = []; f.topics = [];
      drawGen();
    });
    on("gPool", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
      //  hovuz deyisende siyahilar da deyisir - fenn/sinif/movzu
      //  secimleri sifirdan, serverden teze suzulur
      f.pool = b.getAttribute("data-v");
      f.subject = ""; f.level = ""; f.topics = [];
      screenGen();
    });
    on("gDiff", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-d]") : null;
      if (!b) return;
      var d = Number(b.getAttribute("data-d"));
      var i = f.difficulty.indexOf(d);
      if (i >= 0) f.difficulty.splice(i, 1); else f.difficulty.push(d);
      drawGen();
    });
    on("gTop", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-t]") : null;
      if (!b) return;
      var t = b.getAttribute("data-t");
      var i = f.topics.indexOf(t);
      if (i >= 0) f.topics.splice(i, 1); else f.topics.push(t);
      drawGen();
    });
    on("gsub", "change", function () {
      f.subject = $("gsub").value; f.topics = []; screenGen();
    });
    on("glev", "change", function () {
      f.level = $("glev").value; f.topics = []; screenGen();
    });
    on("gTitle", "input", function () { f.title = $("gTitle").value; });

    var t = null;
    on("gCnt", "input", function () {
      var n = Number($("gCnt").value);
      if (n >= 1 && n <= 100) f.count = Math.round(n);
      clearTimeout(t);
      t = setTimeout(genPreview, 350);
    });

    on("btnMake", "click", makeTest);
    genPreview();
  }

  /* Onizleme durust danisir: hovuzda o suzgecle HEQIQETEN nece
     ferqli sual var.  Az cixsa, muellim duymeni basmamis bilir. */
  function genPreview() {
    var live = guard();
    var f = genFilter();
    var my = JSON.stringify(genRule(f));
    sb.rpc("rpc_generate_preview", { p_rule: genRule(f) })
      .then(function (v) {
        if (!live()) return;
        var box = $("gPrev");
        /* Cavab gelene qeder suzgec deyisibse, kohne cavabi atiriq */
        if (!box || JSON.stringify(genRule(genFilter())) !== my) return;
        v = v || {};
        var found = Number(v.found) || 0, want = Number(v.want) || f.count;
        box.innerHTML = v.enough
          ? msg("ok", "Hovuzda kifayət qədər sual var — " + want +
                " sual yığılacaq.")
          : msg("err", "Bu süzgəclə yalnız " + found + " fərqli sual tapıldı (" +
                want + " istənilir). Süzgəci genişləndirin və ya sayı azaldın.");
      })
      .catch(function (e) {
        if (!live()) return;
        var box = $("gPrev");
        if (box) box.innerHTML = msg("err", fail(e));
      });
  }

  function makeTest() {
    if (busy) return;
    var f = genFilter();
    $("gErr").innerHTML = "";
    setBusy("btnMake", true, "Testi yığ");
    sb.rpc("rpc_generate_test", { p_rule: genRule(f), p_title: f.title || "" })
      .then(function (v) {
        busy = false;
        nav("#/t/" + v.test_id);
      })
      .catch(function (e) {
        setBusy("btnMake", false, "Testi yığ");
        var el = $("gErr");
        if (el) el.innerHTML = msg("err", fail(e));
      });
  }

  /* ---------------------------------------------------------- veraq */
  /* ------------------------------------------- sual sehvi bildirisi
     Veraqdaki "Sehv bildir" duymesi: sualin altinda kicik forma acilir,
     rpc_report_question-a gedir.  Sual DEYISMIR - admin baxib qerar
     verir.  Eyni suala tekrar bildiris serverde sakitce udulur. */
  var R_REASONS = [
    ["cavab", "Cavab səhvdir"], ["sert", "Şərt qüsurludur"],
    ["yazi", "Yazı xətası"], ["diger", "Digər"]
  ];

  function reportForm(qid) {
    return '<div class="rfrm">' +
      '<select class="rsel">' + R_REASONS.map(function (r) {
        return '<option value="' + r[0] + '">' + r[1] + "</option>";
      }).join("") + "</select>" +
      '<input class="rnote" maxlength="300" placeholder="Qeyd (istəyə görə)…">' +
      '<button class="btn sm" data-rsend="' + esc(qid) + '">Göndər</button>' +
      '<button class="btn sm ghost" data-rcancel="' + esc(qid) + '">İmtina</button>' +
    "</div>";
  }

  function bindReportLinks() {
    var root = $("main");
    if (!root || root.dataset.rbound) return;
    root.dataset.rbound = "1";
    root.addEventListener("click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("button") : null;
      if (!b) return;
      var qid = b.getAttribute("data-rq");
      if (qid) {
        var slot = $("rs-" + qid);
        if (slot) slot.innerHTML = slot.innerHTML ? "" : reportForm(qid);
        return;
      }
      qid = b.getAttribute("data-rcancel");
      if (qid) { var s2 = $("rs-" + qid); if (s2) s2.innerHTML = ""; return; }
      qid = b.getAttribute("data-rsend");
      if (qid && !busy) {
        var slot3 = $("rs-" + qid);
        if (!slot3) return;
        busy = true; b.disabled = true;
        sb.rpc("rpc_report_question", {
          p_question: qid,
          p_reason: (slot3.querySelector(".rsel") || {}).value || "diger",
          p_note: (slot3.querySelector(".rnote") || {}).value || ""
        }).then(function () {
          busy = false;
          slot3.innerHTML = '<div class="rok">Bildirildi — təşəkkürlər. ' +
            "Baxılandan sonra düzəldiləcək.</div>";
        }).catch(function (e) {
          busy = false; b.disabled = false;
          slot3.innerHTML = reportForm(qid) +
            '<div class="rerr">' + esc(fail(e)) + "</div>";
        });
      }
    });
  }

  function screenPaper(id) {
    var live = guard();
    topTitle.textContent = "Test vərəqi";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    Promise.all([
      sb.rpc("rpc_test_preview", { p_test_id: id }),
      sb.select("classes", { select: "id,name", eq: { account_id: ACC.id }, order: "name" })
    ]).then(function (res) {
      if (!live()) return;
      drawPaper(res[0] || {}, res[1] || []);
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawPaper(t, classes) {
    var qs = t.questions || [];
    var done = Number(t.done) || 0;
    topTitle.textContent = t.title || "Test vərəqi";

    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Test yığ</button>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        "<h1>" + esc(t.title || "") + "</h1>" +
        '<p class="muted" style="margin:8px 0 0">' +
          esc(t.subject || "") + (t.level ? " · " + esc(t.level) : "") +
          " · " + qs.length + " sual" +
          (done ? " · " + done + " şagird işləyib" : "") + "</p>" +
        '<div class="spacer"></div>' +
        (t.gen_rule
          ? (done
              ? '<p class="muted">Bu testi artıq şagird işlədiyi üçün ' +
                "yeniləmək olmaz — yeni test yığın.</p>"
              : '<button class="btn sm ghost" id="btnRegen">' + ic("gen") +
                "Yenidən yığ</button>")
          : "") +
        '<div id="pErr"></div>' +
      "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Qrupa təyin et</h2>" +
      '<div class="card">' +
        (classes.length
          ? '<div class="fieldrow">' +
              '<div><label for="pCls">Qrup</label><select id="pCls">' +
                classes.map(function (c) {
                  return '<option value="' + esc(c.id) + '">' + esc(c.name) + "</option>";
                }).join("") + "</select></div>" +
              '<div><label for="pDate">Son tarix</label>' +
                '<input type="date" id="pDate"></div>' +
              '<div style="flex:0 0 132px"><label for="pTry">Cəhd sayı</label>' +
                '<select id="pTry"><option value="1">1 cəhd</option>' +
                '<option value="2">2 cəhd</option><option value="3">3 cəhd</option>' +
                '<option value="0">Limitsiz</option></select></div>' +
            "</div>" +
            '<p class="muted" style="margin:-8px 0 14px">Son tarix boş qalsa, ' +
              "tapşırıq siz götürənə qədər açıq qalır. Cəhd sayı — şagirdin " +
              "testi neçə dəfə işləyə biləcəyidir; hesabatda həm orta, həm də " +
              "ən yaxşı nəticə görünür.</p>" +
            '<div id="pAsgMsg"></div>' +
            '<button class="btn go" id="btnPAsg">' + ic("plus") + "Tapşırıq ver</button>"
          : '<p class="muted">Əvvəlcə əsas səhifədə qrup yaradın — sonra bu ' +
            "testi ona təyin edə biləcəksiniz.</p>") +
      "</div>" +
      '<div class="spacer"></div>' +
      "<h2>Suallar</h2>" +
      '<div class="card pad0 paper">' +
        qs.map(function (q) {
          return '<div class="pq">' +
            '<div class="qh"><b>' + q.ord + ". " + esc(q.body) + "</b></div>" +
            '<div class="qm">' +
              (q.topic ? "<span>" + esc(q.topic) + "</span><span>·</span>" : "") +
              '<span class="dif d' + (Number(q.difficulty) || 2) + '">' +
                DIFF[Number(q.difficulty) || 2] + "</span>" +
              "<span>·</span><span>" + (q.mine ? "öz sualınız" : "platforma") + "</span>" +
              (q.remedial
                ? '<span class="rem">səhvə bənzər</span>' : "") +
              '<button class="rlink" data-rq="' + esc(q.id) + '">Səhv bildir</button>' +
            "</div>" +
            '<div class="rslot" id="rs-' + esc(q.id) + '"></div>' +
            (q.options || []).map(function (o) {
              return '<div class="popt' + (o.correct ? " ok" : "") + '">' +
                (o.correct ? ic("check") : "") + "<span>" + esc(o.body) + "</span></div>";
            }).join("") +
            (q.explanation
              ? '<div class="pex">' + esc(q.explanation) + "</div>" : "") +
          "</div>";
        }).join("") +
      "</div>"
    );

    on("btnBack", "click", function () { nav("#/gen"); });
    bindReportLinks();

    on("btnRegen", "click", function () {
      if (busy) return;
      setBusy("btnRegen", true, "Yenidən yığ");
      sb.rpc("rpc_regenerate_test", { p_test_id: t.id })
        .then(function () { busy = false; screenPaper(t.id); })
        .catch(function (e) {
          setBusy("btnRegen", false, "Yenidən yığ");
          var el = $("pErr");
          if (el) el.innerHTML = msg("err", fail(e));
        });
    });

    on("btnPAsg", "click", function () {
      if (busy) return;
      var cls = ($("pCls") || {}).value;
      if (!cls) return;
      var day = ($("pDate") || {}).value || "";
      var closes = null;
      if (day) {
        var d = new Date(day + "T23:59:00");
        if (isNaN(d)) { $("pAsgMsg").innerHTML = msg("err", "Tarix düzgün deyil."); return; }
        if (d.getTime() <= Date.now()) {
          $("pAsgMsg").innerHTML = msg("err", "Son tarix bu gündən sonra olmalıdır."); return;
        }
        closes = d.toISOString();
      }
      $("pAsgMsg").innerHTML = "";
      setBusy("btnPAsg", true, "Tapşırıq ver");
      sb.rpc("rpc_assign_test", {
        p_class_id: cls, p_test_id: t.id,
        p_closes_at: closes, p_max_attempts: Number(($("pTry") || {}).value || 1)
      }).then(function () {
        setBusy("btnPAsg", false, "Tapşırıq ver");
        $("pAsgMsg").innerHTML = msg("ok",
          "Tapşırıq verildi — şagirdlər testi artıq görür.");
      }).catch(function (e) {
        setBusy("btnPAsg", false, "Tapşırıq ver");
        $("pAsgMsg").innerHTML = msg("err", fail(e));
      });
    });
  }


  /* ================================================================
     SUAL BANKI
     Sual testden asilı deyil - burda yasayir, sonra generator onu
     testlere yigir.  Ekran iki hissedir: suzgecli siyahi ve forma.
     ================================================================ */
  var BF = null;    // hazirki suzgec
  var FAC = null;   // suzgec siyahilari (fenn/sinif/movzu)

  function bankFilter() {
    if (!BF) BF = { pool: "mine", subject: "", level: "", topics: [], difficulty: [], q: "" };
    return BF;
  }

  /* Suzgeci RPC-nin gozledi formaya salir - bos sahələr getmir */
  function bankRule(f) {
    var r = { pool: f.pool };
    if (f.subject) r.subject = f.subject;
    if (f.level) r.level = f.level;
    if (f.topics.length) r.topics = f.topics;
    if (f.difficulty.length) r.difficulty = f.difficulty;
    if (f.q) r.q = f.q;
    return r;
  }

  var DIFF = ["", "Asan", "Orta", "Çətin"];

  function screenBank() {
    var live = guard();
    var f = bankFilter();
    topTitle.textContent = "Sual bankı";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');

    sb.rpc("rpc_bank_facets", { p_subject: f.subject || null,
                                p_level: f.level || null, p_pool: f.pool || "mine" })
      .then(function (fac) {
        if (!live()) return;
        FAC = fac || {};
        drawBank();
      })
      .catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawBank() {
    var f = bankFilter();
    var use = (FAC.usage || {});
    var used = Number(use.used) || 0, lim = Number(use.limit) || 0;
    var pct = lim > 0 ? Math.min(100, Math.round(used * 100 / lim)) : 0;

    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Əsas səhifə</button>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        '<div class="seat"><div>' +
          '<div class="num">' + used + ' <s>/ ' + (lim > 100000 ? "∞" : lim) + "</s></div>" +
          '<div class="lbl">öz sualınız</div></div>' +
          '<button class="btn go" id="btnNewQ">' + ic("plus") + "Yeni sual</button>" +
        "</div>" +
        '<div class="' + (pct >= 100 ? "bar full" : (pct >= 80 ? "bar warn" : "bar")) +
          '"><i style="width:' + pct + '%"></i></div>' +
      "</div>" +
      '<div class="spacer"></div>' +

      /* ---- suzgec ---- */
      '<div class="card tight" id="bFilt">' +
        '<div class="segs" id="bPool">' +
          seg("mine", "Öz suallarım", f.pool) +
          seg("platform", "Platforma", f.pool) +
          seg("all", "Hamısı", f.pool) +
        "</div>" +
        '<div class="spacer"></div>' +
        '<input id="bq" placeholder="Sual mətnində axtar…" value="' + esc(f.q) + '">' +
        /* Telefonda 10 nisan siyahini ekrandan qovurdu.  Hovuz secicisi
           ve axtaris hemise gorunur, qalani yigilir. */
        '<details class="more filt"' + (nFilt(f) ? " open" : "") + ">" +
          "<summary>Süzgəc" +
            (nFilt(f) ? ' <span class="fn">' + nFilt(f) + "</span>" : "") +
          "</summary>" +
        '<div class="fieldrow" style="margin-top:10px">' +
          '<div><select id="bsub"><option value="">Bütün fənlər</option>' +
            /* Suali olmayan fenn siyahida cixmir - onu secmek menasizdir.
               Sual FORMASINDA ise butun fennler qalir. */
            (FAC.subjects || []).filter(function (s) {
              return Number(s.n) > 0 || f.subject === s.slug;
            }).map(function (s) {
              return '<option value="' + esc(s.slug) + '"' +
                (f.subject === s.slug ? " selected" : "") + ">" + esc(s.name) + "</option>";
            }).join("") + "</select></div>" +
          '<div style="flex:0 0 140px"><select id="blev">' +
            '<option value="">Bütün siniflər</option>' +
            (FAC.levels || []).map(function (l) {
              return '<option value="' + esc(l.code) + '"' +
                (f.level === l.code ? " selected" : "") + ">" + esc(l.name) + "</option>";
            }).join("") + "</select></div>" +
        "</div>" +
        '<div class="chips" id="bDiff">' +
          [1, 2, 3].map(function (d) {
            return '<button class="chip' + (f.difficulty.indexOf(d) >= 0 ? " on" : "") +
              '" data-d="' + d + '">' + DIFF[d] + "</button>";
          }).join("") +
        "</div>" +
        /* Movzular YALNIZ fenn secilende.  Fennsiz 110 nisan cixir -
           suzgec ekrani udur. */
        (!f.subject
          ? '<p class="muted" style="margin:12px 0 0">Mövzuları görmək üçün ' +
            "fənn seçin.</p>"
          : ((FAC.topics || []).length
              ? '<div class="chips" id="bTop">' + FAC.topics.map(function (t) {
                  return '<button class="chip' + (f.topics.indexOf(t.id) >= 0 ? " on" : "") +
                    '" data-t="' + esc(t.id) + '">' +
                    esc(topLabel(t, f.level)) + "</button>";
                }).join("") + "</div>"
              : '<p class="muted" style="margin:12px 0 0">Bu fənn üçün mövzu yoxdur.</p>')) +
        "</details>" +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div id="bList" class="card pad0"><div class="skel">Yüklənir…</div></div>'
    );

    on("btnBack", "click", function () { nav("#/"); });
    on("btnNewQ", "click", function () { nav("#/q/new"); });

    on("bPool", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
      f.pool = b.getAttribute("data-v");
      f.subject = ""; f.level = ""; f.topics = [];
      screenBank();
    });
    on("bDiff", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-d]") : null;
      if (!b) return;
      var d = Number(b.getAttribute("data-d"));
      var i = f.difficulty.indexOf(d);
      if (i >= 0) f.difficulty.splice(i, 1); else f.difficulty.push(d);
      drawBank();
    });
    on("bTop", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-t]") : null;
      if (!b) return;
      var t = b.getAttribute("data-t");
      var i = f.topics.indexOf(t);
      if (i >= 0) f.topics.splice(i, 1); else f.topics.push(t);
      drawBank();
    });
    on("bsub", "change", function () {
      f.subject = $("bsub").value; f.topics = []; screenBank();
    });
    on("blev", "change", function () {
      f.level = $("blev").value; f.topics = []; screenBank();
    });

    /* Yazarken her herfe sorgu getmesin */
    var t = null;
    on("bq", "input", function () {
      clearTimeout(t);
      t = setTimeout(function () { f.q = ($("bq").value || "").trim(); loadBank(); }, 350);
    });

    loadBank();
  }

  /* Nece suzgec aciqdir - yigilanda da gorunsun deye */
  function nFilt(f) {
    return (f.subject ? 1 : 0) + (f.level ? 1 : 0) +
           f.topics.length + f.difficulty.length;
  }

  function seg(v, label, cur) {
    return '<button class="seg' + (cur === v ? " on" : "") + '" data-v="' + v + '">' +
      label + "</button>";
  }

  function loadBank() {
    var live = guard();
    var f = bankFilter();
    /*  Suzgecsiz platforma/hamisi: minlerle suali tokmek evezine fenn
        secimi teklif olunur.  Oz banki ise derhal acilir - muellim oz
        suallarini gormek ucun gelir.  */
    if (f.pool !== "mine" && nFilt(f) === 0 && !(f.q || "").trim()) {
      var box0 = $("bList");
      if (box0) {
        var subs = (FAC.subjects || []).filter(function (x) {
          return (Number(x.n) || 0) > 0;
        });
        var total = subs.reduce(function (a, x) {
          return a + (Number(x.n) || 0);
        }, 0);
        box0.innerHTML = subs.length
          ? '<div class="bpick"><p>Bankda <b>' + total + "</b> sual var. " +
              "Siyahı üçün fənn seçin və ya yuxarıdan axtarın:</p>" +
              '<div class="g">' + subs.map(function (x) {
                return '<button class="pkb" data-s="' + esc(x.slug) + '">' +
                  esc(x.name) + "<i>" + x.n + " sual</i></button>";
              }).join("") + "</div></div>"
          : '<div class="empty"><div class="ic">' + ic("doc") + "</div>" +
            "<b>Bu hovuzda hələ sual yoxdur</b></div>";
        Array.prototype.forEach.call(
          box0.querySelectorAll("[data-s]"), function (b) {
            b.addEventListener("click", function () {
              f.subject = b.getAttribute("data-s");
              f.topics = [];
              screenBank();
            });
          });
      }
      return;
    }
    sb.rpc("rpc_bank_list", { p_filters: bankRule(f), p_limit: 50, p_offset: 0 })
      .then(function (d) {
        if (!live()) return;
        var box = $("bList");
        if (!box) return;
        d = d || {};
        var items = d.items || [];
        if (!items.length) {
          box.innerHTML = '<div class="empty"><div class="ic">' + ic("doc") + "</div>" +
            "<b>Sual tapılmadı</b>" +
            (f.pool === "mine"
              ? "Yuxarıdan «Yeni sual» ilə başlayın."
              : "Süzgəci genişləndirin.") + "</div>";
          return;
        }
        box.innerHTML =
          '<div class="bcount">' + (Number(d.total) || 0) + " sual" +
            (items.length < (Number(d.total) || 0)
              ? " · ilk " + items.length + "-i göstərilir" : "") + "</div>" +
          items.map(function (q) {
            var mine = !!q.mine;
            return '<button class="qrow" data-q="' + esc(q.id) + '"' +
              (mine ? "" : " disabled") + ">" +
              '<div class="g"><b>' + esc(q.body) + "</b><i>" +
                "<span>" + esc(q.subject || "") + "</span>" +
                (q.level ? "<span>·</span><span>" + esc(q.level) + "</span>" : "") +
                (q.topic ? "<span>·</span><span>" + esc(q.topic) + "</span>" : "") +
                '<span class="dif d' + (Number(q.difficulty) || 2) + '">' +
                  DIFF[Number(q.difficulty) || 2] + "</span>" +
                (mine ? "" : "<span>·</span><span>platforma</span>") +
              "</i></div>" +
              (mine ? '<span class="arrow">' + ic("right") + "</span>" : "") +
            "</button>";
          }).join("");

        Array.prototype.forEach.call(box.querySelectorAll("[data-q]"), function (b) {
          b.addEventListener("click", function () {
            nav("#/q/" + b.getAttribute("data-q"));
          });
        });
      })
      .catch(function (e) {
        if (!live()) return;
        var box = $("bList");
        if (box) box.innerHTML = msg("err", fail(e));
      });
  }


  /* ================================================================
     SUAL FORMASI
     Variantlar burda yasayir: elave et / sil / duzgununu isarele.
     Serverde de eyni qaydalar var - bura yalniz erken xeberdarliqdir.
     ================================================================ */
  var QD = null;   // redakte olunan sual

  function screenQuestion(id) {
    var live = guard();
    topTitle.textContent = id === "new" ? "Yeni sual" : "Sualı redaktə et";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');

    var f = bankFilter();
    Promise.all([
      loadLevels(),
      sb.rpc("rpc_bank_facets", { p_subject: null, p_level: null }),
      /* movzular AYRICA, secilen fenne gore */
      id === "new" ? Promise.resolve(null) : sb.rpc("rpc_bank_question", { p_id: id })
    ]).then(function (res) {
      if (!live()) return;
      FAC = res[1] || {};
      var q = res[2];
      QD = q ? {
        id: q.id, body: q.body || "", kind: q.kind || "single",
        explanation: q.explanation || "", difficulty: Number(q.difficulty) || 2,
        subject: q.subject || "", level: q.level || "",
        topic_id: q.topic_id || "", quarter: q.quarter || "", month: q.month || "",
        tags: q.tags || [],
        options: (q.options || []).map(function (o) {
          return { body: o.body, correct: !!o.correct };
        }),
        used_in: Number(q.used_in) || 0, answered: Number(q.answered) || 0
      } : {
        id: null, body: "", kind: "single", explanation: "", difficulty: 2,
        subject: f.subject || "riyaziyyat", level: f.level || "",
        topic_id: "", quarter: "", month: "", tags: [],
        options: [{ body: "", correct: true }, { body: "", correct: false }],
        used_in: 0, answered: 0
      };
      drawQuestion();
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawQuestion() {
    var q = QD;
    var isNew = !q.id;

    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Sual bankı</button>" +
      '<div class="spacer"></div>' +

      '<div class="card">' +
        '<label for="qbody">Sual</label>' +
        '<textarea id="qbody" rows="3" maxlength="2000" ' +
          'placeholder="məsələn: 6 × 7 neçə edər?">' + esc(q.body) + "</textarea>" +

        '<label>Sualın tipi</label>' +
        '<div class="segs" id="qkind">' +
          seg2("single", "Bir cavab", q.kind) +
          seg2("multi", "Çox cavab", q.kind) +
          seg2("text", "Yazılı", q.kind) +
        "</div>" +
        '<p class="muted" style="margin:8px 0 0" id="qkindNote"></p>' +
      "</div>" +
      '<div class="spacer"></div>' +

      '<h2 id="optTitle">Variantlar</h2>' +
      '<div class="card" id="qopts"></div>' +
      '<div class="spacer"></div>' +

      '<div class="card">' +
        '<div class="fieldrow">' +
          '<div><label for="qsub">Fənn</label><select id="qsub">' +
            (FAC.subjects || []).map(function (s) {
              return '<option value="' + esc(s.slug) + '"' +
                (q.subject === s.slug ? " selected" : "") + ">" + esc(s.name) + "</option>";
            }).join("") + "</select></div>" +
          '<div style="flex:0 0 140px"><label for="qlev">Sinif</label>' +
            '<select id="qlev"><option value="">Seçilməyib</option>' +
            (FAC.levels || []).map(function (l) {
              return '<option value="' + esc(l.code) + '"' +
                (q.level === l.code ? " selected" : "") + ">" + esc(l.name) + "</option>";
            }).join("") + "</select></div>" +
        "</div>" +

        '<label for="qtop">Mövzu</label>' +
        '<select id="qtop"><option value="">Seçilməyib</option>' +
          (FAC.topics || []).map(function (t) {
            return '<option value="' + esc(t.id) + '"' +
              (q.topic_id === t.id ? " selected" : "") + ">" + esc(t.name) + "</option>";
          }).join("") + "</select>" +
        '<p class="muted" style="margin:-8px 0 14px">Mövzu seçilməsə bu sual ' +
          "«zəif nöqtə» hesabatına düşmür.</p>" +

        '<label>Çətinlik</label>' +
        '<div class="segs" id="qdiff">' +
          [1, 2, 3].map(function (d) {
            return '<button class="seg' + (q.difficulty === d ? " on" : "") +
              '" data-v="' + d + '">' + DIFF[d] + "</button>";
          }).join("") +
        "</div>" +
      "</div>" +
      '<div class="spacer"></div>' +

      '<details class="more"' + (q.explanation || q.quarter ? " open" : "") + ">" +
        "<summary>Əlavə məlumat</summary>" +
        '<div class="card" style="margin-top:10px">' +
          '<label for="qexp">İzah</label>' +
          '<textarea id="qexp" rows="2" maxlength="1000" ' +
            'placeholder="Şagird səhv edəndə bunu görəcək">' + esc(q.explanation) + "</textarea>" +
          '<div class="fieldrow">' +
            '<div><label for="qq">Rüb</label><select id="qq">' +
              '<option value="">—</option>' +
              [1, 2, 3, 4].map(function (n) {
                return '<option value="' + n + '"' +
                  (String(q.quarter) === String(n) ? " selected" : "") + ">" +
                  n + "-ci rüb</option>";
              }).join("") + "</select></div>" +
            '<div><label for="qm">Ay</label><select id="qm">' +
              '<option value="">—</option>' +
              [9,10,11,12,1,2,3,4,5,6].map(function (n) {
                var ay = ["","yanvar","fevral","mart","aprel","may","iyun","iyul",
                          "avqust","sentyabr","oktyabr","noyabr","dekabr"];
                return '<option value="' + n + '"' +
                  (String(q.month) === String(n) ? " selected" : "") + ">" +
                  ay[n] + "</option>";
              }).join("") + "</select></div>" +
          "</div>" +
        "</div>" +
      "</details>" +
      '<div class="spacer"></div>' +

      '<div id="qErr"></div>' +
      '<div id="qSim"></div>' +
      '<button class="btn go wide" id="qSave">' + ic("check") +
        (isNew ? "Sualı yadda saxla" : "Dəyişikliyi saxla") + "</button>" +
      (isNew ? "" :
        '<div class="spacer"></div><div class="card tight"><div class="danger">' +
        '<button class="btn sm ghost" id="qDel">' + ic("x") + "Sualı sil</button>" +
        '<span class="muted">' +
          (q.answered > 0
            ? "Şagirdlər cavab verib — sual arxivlənəcək, nəticələr qalacaq."
            : (q.used_in > 0
                ? "Test(lər)də işlənib — arxivlənəcək."
                : "Tamamilə silinəcək.")) +
        "</span></div></div>")
    );

    on("btnBack", "click", function () { nav("#/b"); });
    drawOptions();
    bindOptions();
    kindNote();
    loadTopics(q.subject, q.level);

    on("qkind", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
      var y0 = keepY();
      collect();
      QD.kind = b.getAttribute("data-v");
      if (QD.kind === "text" && QD.options.length > 1) {
        QD.options = [QD.options[0]];
      }
      if (QD.kind === "single") {
        var seen = false;
        QD.options.forEach(function (o) {
          if (o.correct && seen) o.correct = false;
          if (o.correct) seen = true;
        });
      }
      Array.prototype.forEach.call($("qkind").children, function (x) {
        x.classList.toggle("on", x === b);
      });
      drawOptions();   /* butun forma YOX - yalniz variantlar */
      kindNote();
      y0();            /* sehife yerinde qalsin */
    });
    /* Cetinlik: butun formani yeniden cizmek olmaz - sehife yuxari
       atilir ve muellim yerini itirir.  Yalniz nisan deyisir. */
    on("qdiff", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
      QD.difficulty = Number(b.getAttribute("data-v"));
      Array.prototype.forEach.call($("qdiff").children, function (x) {
        x.classList.toggle("on", x === b);
      });
    });
    on("qSave", "click", saveQuestion);
    if (!isNew) on("qDel", "click", delQuestion);

    /* Fenn deyisende movzular da deyismelidir - riyaziyyat sualina
       "Sait ve samit" teklif etmek olmaz. */
    on("qsub", "change", function () {
      collect(); QD.topic_id = ""; loadTopics(QD.subject, QD.level);
    });
    /* Sinif deyisende de - 3-cu sinif sualina 1-ci sinif movzusu olmaz */
    on("qlev", "change", function () {
      collect(); QD.topic_id = ""; loadTopics(QD.subject, QD.level);
    });

    /* Oxsar sual xeberdarligi - BLOKLAMIR, yalniz gosterir */
    var t = null;
    on("qbody", "input", function () {
      clearTimeout(t);
      t = setTimeout(checkSimilar, 600);
    });
  }

  /* Movzu adi.  Sinif secilmeyibse ada sinifi de yaziriq - eks halda
     "Bolme" iki defe gorunur ve hansini sectiyin bilinmir. */
  function topLabel(t, lev) {
    return t.name + (!lev && t.level_name ? " · " + t.level_name : "");
  }

  /* Movzu siyahisi: secilen FENN ve SINIF uzre */
  function loadTopics(subject, level) {
    var sel = $("qtop");
    if (!sel) return;
    sel.disabled = true;
    sb.rpc("rpc_bank_facets", { p_subject: subject || null, p_level: level || null })
      .then(function (fac) {
        var el = $("qtop");
        if (!el) return;
        FAC.topics = (fac || {}).topics || [];
        el.innerHTML = '<option value="">Seçilməyib</option>' +
          FAC.topics.map(function (t) {
            return '<option value="' + esc(t.id) + '"' +
              (QD.topic_id === t.id ? " selected" : "") + ">" +
              esc(topLabel(t, level)) + "</option>";
          }).join("");
        el.disabled = false;
        if (!FAC.topics.length) {
          el.innerHTML = '<option value="">Bu fənn üçün mövzu yoxdur</option>';
        }
      })
      .catch(function () { var el = $("qtop"); if (el) el.disabled = false; });
  }

  function seg2(v, label, cur) {
    return '<button class="seg' + (cur === v ? " on" : "") + '" data-v="' + v + '">' +
      label + "</button>";
  }

  function kindNote() {
    var n = $("qkindNote"), t = $("optTitle");
    if (!n) return;
    if (QD.kind === "text") {
      n.textContent = "Şagird cavabı yazır. Aşağıda qəbul ediləcək cavabları sadalayın.";
      if (t) t.textContent = "Qəbul ediləcək cavablar";
    } else if (QD.kind === "multi") {
      n.textContent = "Bir neçə variant doğru ola bilər.";
      if (t) t.textContent = "Variantlar";
    } else {
      n.textContent = "Yalnız bir variant doğrudur.";
      if (t) t.textContent = "Variantlar";
    }
  }

  function drawOptions() {
    var box = $("qopts");
    if (!box) return;
    var txt = QD.kind === "text";
    box.innerHTML =
      QD.options.map(function (o, i) {
        return '<div class="opt-row">' +
          (txt ? '<span class="onum">' + (i + 1) + "</span>"
               : '<button class="okmark' + (o.correct ? " on" : "") + '" data-c="' + i + '" ' +
                 'title="Doğru cavab" aria-label="Doğru cavab">' + ic("check") + "</button>") +
          '<input class="obody" data-i="' + i + '" maxlength="500" value="' +
            esc(o.body) + '" placeholder="' +
            (txt ? "qəbul ediləcək cavab" : "variant " + (i + 1)) + '">' +
          (QD.options.length > (txt ? 1 : 2)
            ? '<button class="btn sm ghost icon" data-rm="' + i + '" ' +
              'title="Sil" aria-label="Sil">' + ic("x") + "</button>"
            : '<span class="rmpad"></span>') +
        "</div>";
      }).join("") +
      (QD.options.length < 8
        ? '<button class="btn sm ghost" id="qAdd">' + ic("plus") +
          (txt ? "Başqa cavab" : "Variant əlavə et") + "</button>"
        : "");

  }

  /*  Sehifenin yerini saxlayir.
      DIQQET: deyeri EMELIYYATDAN EVVEL tutmaq lazimdir - DOM deyisenden
      sonra oxusan artiq sifirlanmis olur.  Berpa hem derhal, hem de
      novbeti kadrda olur: brauzer klampi bir kadr gecikdire biler. */
  function keepY() {
    var y = window.pageYOffset || document.documentElement.scrollTop || 0;
    return function () {
      if (!y) return;
      window.scrollTo(0, y);
      if (window.requestAnimationFrame) {
        requestAnimationFrame(function () { window.scrollTo(0, y); });
      }
    };
  }

  /* Variantlari yeniden cizir, sehifenin YERINI saxlayir */
  function redrawOptions() {
    var back = keepY();
    drawOptions();
    back();
  }

  /* Dinleyici EKRAN uzre bir defe baglanir - drawOptions-da yox.
     Eks halda her yeniden cizilisde ustune bir dinleyici de qalir. */
  function bindOptions() {
    var box = $("qopts");
    if (!box || box.dataset.bound) return;
    box.dataset.bound = "1";
    box.addEventListener("click", function (e) {
      var m = e.target.closest ? e.target.closest("[data-c]") : null;
      if (m) {
        collect();
        var i = Number(m.getAttribute("data-c"));
        if (QD.kind === "single") {
          QD.options.forEach(function (o, k) { o.correct = (k === i); });
        } else {
          QD.options[i].correct = !QD.options[i].correct;
        }
        redrawOptions(); return;
      }
      var r = e.target.closest ? e.target.closest("[data-rm]") : null;
      if (r) {
        collect();
        QD.options.splice(Number(r.getAttribute("data-rm")), 1);
        if (QD.kind !== "text" && !QD.options.some(function (o) { return o.correct; })) {
          QD.options[0].correct = true;
        }
        redrawOptions(); return;
      }
      if (e.target.id === "qAdd" || (e.target.closest && e.target.closest("#qAdd"))) {
        collect();
        if (QD.options.length >= 8) return;   // sert hedd
        QD.options.push({ body: "", correct: QD.kind === "text" });
        redrawOptions();
        var last = box.querySelectorAll(".obody");
        if (last.length) last[last.length - 1].focus();
      }
    });
  }

  /* Ekrandaki deyerleri QD-ye yigir - yeniden cizmeden EVVEL cagirilir */
  function collect() {
    if ($("qbody")) QD.body = $("qbody").value || "";
    if ($("qexp")) QD.explanation = $("qexp").value || "";
    if ($("qsub")) QD.subject = $("qsub").value || "";
    if ($("qlev")) QD.level = $("qlev").value || "";
    if ($("qtop")) QD.topic_id = $("qtop").value || "";
    if ($("qq")) QD.quarter = $("qq").value || "";
    if ($("qm")) QD.month = $("qm").value || "";
    var box = $("qopts");
    if (box) {
      Array.prototype.forEach.call(box.querySelectorAll(".obody"), function (inp) {
        var i = Number(inp.getAttribute("data-i"));
        if (QD.options[i]) QD.options[i].body = inp.value || "";
      });
    }
  }

  function checkSimilar() {
    var body = ($("qbody") || {}).value || "";
    var box = $("qSim");
    if (!box) return;
    if (body.trim().length < 6) { box.innerHTML = ""; return; }
    sb.rpc("rpc_bank_similar", { p_body: body, p_exclude: QD.id || null })
      .then(function (list) {
        var b = $("qSim");
        if (!b) return;
        list = list || [];
        if (!list.length) { b.innerHTML = ""; return; }
        b.innerHTML = '<div class="warn">' + ic("warn") + "<span>" +
          (list[0].exact ? "Bankında EYNİ sual var: " : "Bankında buna oxşar sual var: ") +
          "«" + esc(list[0].body) + "»" +
          (list[0].exact ? " — eynisini iki dəfə saxlamaq olmur."
                         : " Yenə də saxlaya bilərsiniz.") +
          "</span></div>";
      })
      .catch(function () {});
  }

  function saveQuestion() {
    if (busy) return;
    collect();
    var q = QD;

    /* Erken yoxlama - serverde de eynisi var, amma bura daha tez deyir */
    var bad = null;
    if (!q.body.trim()) bad = "Sualın mətnini yazın.";
    else if (!q.subject) bad = "Fənni seçin.";
    else {
      var filled = q.options.filter(function (o) { return o.body.trim(); });
      var ok = filled.filter(function (o) { return o.correct; });
      if (q.kind === "text") {
        if (!filled.length) bad = "Ən azı bir qəbul ediləcək cavab yazın.";
      } else if (filled.length < 2) bad = "Ən azı iki variant yazın.";
      else if (q.kind === "single" && ok.length !== 1) bad = "Bir doğru cavab seçin.";
      else if (q.kind === "multi" && ok.length < 1) bad = "Ən azı bir doğru cavab seçin.";
    }
    if (bad) { $("qErr").innerHTML = msg("err", bad); return; }
    $("qErr").innerHTML = "";

    setBusy("qSave", true, q.id ? "Dəyişikliyi saxla" : "Sualı yadda saxla");
    sb.rpc("rpc_bank_save_question", {
      p_id: q.id, p_subject: q.subject, p_body: q.body,
      p_options: q.options.filter(function (o) { return o.body.trim(); })
                   .map(function (o) { return { body: o.body.trim(), correct: !!o.correct }; }),
      p_kind: q.kind,
      p_level: q.level || null,
      p_topic: q.topic_id || null,
      p_explanation: q.explanation || "",
      p_difficulty: q.difficulty,
      p_quarter: q.quarter ? Number(q.quarter) : null,
      p_month: q.month ? Number(q.month) : null,
      p_tags: q.tags || []
    }).then(function () { nav("#/b"); })
      .catch(function (e) {
        setBusy("qSave", false, q.id ? "Dəyişikliyi saxla" : "Sualı yadda saxla");
        var t = fail(e);
        if (/duplicate key|questions_dup_account/i.test(t)) {
          t = "Bu sual bankınızda artıq var.";
        }
        $("qErr").innerHTML = msg("err", t);
      });
  }

  function delQuestion() {
    if (busy || !QD.id) return;
    var arxiv = QD.answered > 0 || QD.used_in > 0;
    if (!confirm(arxiv
        ? "Sual testlərdə işlənib.\n\nSiyahıdan çıxacaq, amma şagirdlərin " +
          "nəticələri qorunacaq."
        : "Sual tamamilə silinsin?")) return;
    busy = true;
    sb.rpc("rpc_bank_delete_question", { p_id: QD.id })
      .then(function () { busy = false; nav("#/b"); })
      .catch(function (e) {
        busy = false;
        $("qErr").innerHTML = msg("err", fail(e));
      });
  }

  function guard() {
    var at = location.hash || "#/";
    return function () { return (location.hash || "#/") === at; };
  }

  function nav(h) {
    if (location.hash === h) route();
    else location.hash = h;
  }

  function route() {
    if (!ACC) { screenSetup(); return; }
    var m = (location.hash || "#/").replace(/^#/, "").split("/").filter(Boolean);
    if (m[0] === "g" && m[1]) return screenGroup(m[1]);
    if (m[0] === "r" && m[1]) return screenReport(m[1]);
    if (m[0] === "a" && m[1]) return screenAssign(m[1]);
    if (m[0] === "b") return screenBank();
    if (m[0] === "gen") return screenGen();
    if (m[0] === "t" && m[1]) return screenPaper(m[1]);
    if (m[0] === "p") return screenPaket();
    if (m[0] === "adm") return screenAdmin();
    if (m[0] === "q" && m[1]) return screenQuestion(m[1]);
    if (m[0] === "s" && m[1] && m[2]) return screenStudent(m[1], m[2]);
    screenHome();
  }

  window.addEventListener("hashchange", function () {
    if (sb.session() && CTX) route();
  });

  /* Muellim basqa tetbiqe kecib qayidanda hesabat ozu yenilenir -
     sehifeni yeniden yukleməye ehtiyac qalmir. */
  document.addEventListener("visibilitychange", function () {
    if (document.hidden || !sb.session() || !CTX) return;
    var m = (location.hash || "").replace(/^#/, "").split("/").filter(Boolean);
    if (m[0] === "r" && m[1]) screenReport(m[1], true);
  });

  /* ------------------------------------------------------------- boot */
  function refreshContext() {
    return sb.rpc("rpc_my_context").then(function (c) {
      CTX = c;
      if (CTX && CTX.accounts && CTX.accounts.length) {
        var keep = ACC ? ACC.id : null;
        ACC = CTX.accounts.filter(function (a) { return a.id === keep; })[0] || CTX.accounts[0];
      } else { ACC = null; }
      return CTX;
    });
  }

  function boot() {
    if (!window.CFG || !window.CFG.SUPABASE_URL || !window.CFG.SUPABASE_ANON_KEY) {
      btnOut.classList.add("hide");
      show(msg("err", "config.js doldurulmayıb. SUPABASE_URL və SUPABASE_ANON_KEY yazın.") +
           '<p class="note">Supabase → Settings → API bölməsindən götürün. ' +
           "anon açar ictimaidir, onu gizlətmək lazım deyil.</p>");
      return;
    }
    if (!sb.session()) { screenAuth("in"); return; }

    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    refreshContext().then(function () {
      btnOut.classList.remove("hide");
      topWho.textContent = (CTX.profile && CTX.profile.full_name) || "";
      route();
    }).catch(function (e) {
      if (e && e.status === 401) { sb.signOut().then(function () { screenAuth("in"); }); return; }
      show(msg("err", fail(e)));
    });
  }

  /* Sessiya bitende hec bir ekranda dalana diranmirik - giris ekrani
     xos xeberdarliqla acilir */
  window.addEventListener("sb:sessionend", function () {
    CTX = null; ACC = null;
    try { history.replaceState(null, "", location.pathname); } catch (e) {}
    screenAuth("in", msg("warn",
      "Sessiyanız bitdi — təhlükəsizlik üçün yenidən daxil olun."));
  });

  /* Loqo ve basliq klik = esas sehife */
  (function () {
    var head = document.querySelector(".mark");
    function goHome() {
      if (!sb.session()) { screenAuth("in"); return; }
      if (location.hash === "#/" || location.hash === "") { boot(); }
      else nav("#/");
    }
    if (head) {
      head.style.cursor = "pointer";
      head.addEventListener("click", goHome);
    }
    if (topTitle) {
      topTitle.style.cursor = "pointer";
      topTitle.addEventListener("click", goHome);
    }
  })();

  btnOut.addEventListener("click", function () {
    sb.signOut().then(function () {
      CTX = null; ACC = null;
      try { history.replaceState(null, "", location.pathname); } catch (e) {}
      screenAuth("in");
    });
  });

  /* Berpa linkinden qayidanda Supabase tokenleri hash-de gonderir:
     #access_token=...&refresh_token=...&type=recovery
     Bu, bizim #/ marsrutlarimiz deyil - evvel tutub sessiya qururuq. */
  (function () {
    var h = location.hash || "";
    if (h.indexOf("type=recovery") < 0 || h.indexOf("access_token=") < 0) return;
    var q = {};
    h.replace(/^#/, "").split("&").forEach(function (kv) {
      var i = kv.indexOf("=");
      if (i > 0) q[kv.slice(0, i)] = decodeURIComponent(kv.slice(i + 1));
    });
    if (!q.access_token) return;
    sb.setSession(q.access_token, q.refresh_token || "");
    try { history.replaceState(null, "", location.pathname); } catch (e) {}
    screenNewPass();
    RECOVERY = true;
  })();

  if (!RECOVERY) boot();
})();
