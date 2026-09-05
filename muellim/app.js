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
    home:   '<path d="M3.4 9.4 9.5 3.9l6.1 5.5"/><path d="M5.3 8.7v6.8h8.4V8.7"/>',
    bell:   '<path d="M9.5 3.1a4.3 4.3 0 0 0-4.3 4.3c0 3.2-1.1 4.4-1.6 4.9h11.8c-.5-.5-1.6-1.7-1.6-4.9A4.3 4.3 0 0 0 9.5 3.1z"/><path d="M8 14.8a1.6 1.6 0 0 0 3 0"/>',
    pen:    '<path d="M12.4 3.6a1.7 1.7 0 0 1 2.4 2.4L6.6 14.2l-3.1.7.7-3.1 8.2-8.2z"/>',
    doc:    '<path d="M11 2.5H6a1.8 1.8 0 0 0-1.8 1.8v10.4A1.8 1.8 0 0 0 6 16.5h7a1.8 1.8 0 0 0 1.8-1.8V6.3L11 2.5z"/>' +
            '<path d="M11 2.5v3.8h3.8"/><path d="M7.2 10h4.6M7.2 12.8h3"/>',
    print:  '<path d="M5.8 7.2V3.4h7.4v3.8"/>' +
            '<path d="M5.8 13.2H3.4V8.4a1.2 1.2 0 0 1 1.2-1.2h9.8a1.2 1.2 0 0 1 1.2 1.2v4.8h-2.4"/>' +
            '<rect x="5.8" y="11" width="7.4" height="5" rx=".8"/>'
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
    if (typeof bnavHide === "function") bnavHide();

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
        '<label for="pass">Parol</label>' +
        '<input id="pass" type="password" autocomplete="' +
          (isUp ? "new-password" : "current-password") + '">' +
        (isUp ? "" :
          '<div class="fglink"><button class="lnk" id="btnForgot" ' +
            'type="button">Parolu unutmusunuz?</button></div>') +
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
        "<label>Tədris etdiyiniz fənlər (istəyə görə)</label>" +
        '<p class="note" style="margin-top:-4px">Seçsəniz, siyahılarda yalnız ' +
          "öz fənləriniz görünəcək. Sonradan profildən dəyişmək olar.</p>" +
        '<div class="chips subpick" id="setSubs"></div>' +
        '<button class="btn go wide" id="btnSetup">Davam et</button>' +
      "</div>"
    );
    subChips("setSubs", []);

    on("btnSetup", "click", function () {
      if (busy) return;
      var name = ($("aname").value || "").trim();
      if (!name) {
        $("setupErr").innerHTML = msg("err", "Hesabın adını yazın.");
        return;
      }
      setBusy("btnSetup", true, "Davam et");
      sb.rpc("rpc_create_account", { p_type: $("atype").value, p_name: name })
        .then(function (r) {
          //  fenn secimi konu deyil - alinmasa da hesab yaranib
          var subs = chipVals("setSubs");
          if (!subs.length || !r || !r.id) return null;
          return sb.rpc("rpc_set_subjects",
                        { p_account_id: r.id, p_subjects: subs })
                   .catch(function () {});
        })
        .then(boot)
        .catch(function (e) {
          setBusy("btnSetup", false, "Davam et");
          $("setupErr").innerHTML = msg("err", fail(e));
        });
    });
  }

  /* ------------------------------------------------- bildirisler ekrani */
  function screenNotif() {
    var live = guard();
    topTitle.textContent = "Bildirişlər";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_home", {}).then(function (v) {
      if (!live()) return;
      v = v || {};
      var al = v.alerts || [];
      bellDot(al.length);
      var h = '<button class="btn sm ghost" id="btnBack">' + ic("back") +
        "Əsas səhifə</button>" + '<div class="spacer"></div>' +
        "<h2>Siqnallar</h2>";
      if (v.alerts === null) {
        h += '<div class="card"><p class="muted" style="margin:0">Geriləyən və ' +
          "zəif mövzuda ilişən şagird siqnalları abunə paketi ilə açılır." +
          (plansOn() ? ' <a href="#/p">Paketlərə bax</a>' : "") + "</p></div>";
      } else if (!al.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' +
          ic("bell") + "</div><b>Yeni siqnal yoxdur</b>" +
          "Geriləyən və ya zəif mövzuda ilişən şagird olanda burada görünəcək.</div></div>";
      } else {
        h += '<div class="card pad0" id="nAl">' + al.map(alertRow).join("") + "</div>";
      }
      //  "Son neticeler" burada tekrar idi (Icmalda var) - cixarildi
      show(h);
      bindAlerts($("nAl"));
      on("btnBack", "click", function () { nav("#/"); });
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  /* ------------------------------------------------------ «Bizə yazın»
     Muellim profildən, sagird ve valideyn oz ekranindan yazir; admin
     Idareetmede oxuyur, status ve qeyd qoyur - muellim qeydi burada
     gorur.  FB_FROM: profile hansi ekrandan gelib (admin ucun kontekst). */
  var FB_FROM = "İcmal";
  var FB_KIND = [["teklif", "Təklif"], ["problem", "Problem"],
                 ["sual", "Sual"], ["tesekkur", "Təşəkkür"]];
  var FB_ST = { "new": "Yeni", seen: "Baxılıb", planned: "Planda",
                done: "Edilib", closed: "Bağlı" };
  var FB_PAGE = { "": "İcmal", g: "Qrup", r: "Qrup hesabatı", a: "Tapşırıq",
                  b: "Sual bankı", gen: "Test yığ", t: "Test vərəqi", p: "Paket",
                  adm: "İdarəetmə", n: "Bildirişlər", q: "Sual", s: "Şagird hesabatı" };
  function fbKind(k) {
    for (var i = 0; i < FB_KIND.length; i++) if (FB_KIND[i][0] === k) return FB_KIND[i][1];
    return k;
  }
  function fbForm(id) {
    return '<div class="chips fbk" id="' + id + 'K">' +
        FB_KIND.map(function (k, i) {
          return '<button type="button" class="chip' + (i === 0 ? " on" : "") +
            '" data-k="' + k[0] + '">' + k[1] + "</button>";
        }).join("") + "</div>" +
      '<textarea id="' + id + 'T" rows="4" maxlength="2000" ' +
        'placeholder="Nə təklif edirsiniz, nə işləmir, nə maraqlıdır? Konkret yazın — belə daha tez kömək edə bilirik."></textarea>' +
      '<div class="fbrow"><span class="fbn" id="' + id + 'N">0 / 2000</span>' +
        '<button class="btn go" id="' + id + 'Go">Göndər</button></div>' +
      '<div id="' + id + 'M"></div>';
  }
  function fbBind(id, send, after) {
    var ta = $(id + "T"), n = $(id + "N");
    on(id + "K", "click", function (ev) {
      var b = ev.target.closest ? ev.target.closest(".chip") : null;
      if (!b) return;
      Array.prototype.forEach.call(document.querySelectorAll("#" + id + "K .chip"), function (x) {
        x.classList.toggle("on", x === b);
      });
    });
    on(id + "T", "input", function () {
      if (n) n.textContent = ta.value.length + " / 2000";
    });
    on(id + "Go", "click", function () {
      if (busy) return;
      var k = document.querySelector("#" + id + "K .chip.on");
      var body = (ta.value || "").trim();
      if (body.length < 10) {
        $(id + "M").innerHTML = msg("warn", "Bir az ətraflı yazın — ən azı 10 simvol.");
        ta.focus(); return;
      }
      setBusy(id + "Go", true, "Göndər");
      send((k && k.getAttribute("data-k")) || "teklif", body).then(function () {
        setBusy(id + "Go", false, "Göndər");
        ta.value = ""; if (n) n.textContent = "0 / 2000";
        $(id + "M").innerHTML = msg("ok", "Təşəkkür edirik! Mesajınız çatdı — oxuyub cavab yazacağıq.");
        if (after) after();
      }).catch(function (e) {
        setBusy(id + "Go", false, "Göndər");
        $(id + "M").innerHTML = msg("err", fail(e));
      });
    });
  }
  function fbMineLoad() {
    var live = guard();
    sb.rpc("rpc_feedback_mine", {}).then(function (rows) {
      if (!live()) return;
      var box = $("fbMine");
      if (!box) return;
      rows = rows || [];
      if (!rows.length) { box.innerHTML = ""; return; }
      var CAP = 5;
      box.innerHTML = '<div class="spacer"></div><h2>Yazdıqlarınız</h2>' +
        '<div class="card pad0" id="fbList">' + rows.map(function (r, i) {
          return '<div class="fbi' + (i >= CAP ? " hide" : "") + '">' +
            '<div class="fbh"><span class="pill">' + esc(fbKind(r.kind)) + "</span>" +
              '<span class="fbst st-' + esc(r.status) + '">' + (FB_ST[r.status] || r.status) + "</span>" +
              '<span class="fbat">' + dateAz(r.at) + "</span></div>" +
            '<p class="fbb">' + esc(r.body) + "</p>" +
            (r.note
              ? '<div class="fbre">' + ic("check") + "<div><b>Cavabımız</b>" +
                esc(r.note) + "</div></div>"
              : "") +
          "</div>";
        }).join("") +
        (rows.length > CAP
          ? '<button class="morebtn" id="fbMore">Daha ' + (rows.length - CAP) + " mesaj</button>"
          : "") + "</div>";
      on("fbMore", "click", function () {
        Array.prototype.forEach.call(document.querySelectorAll("#fbList .fbi.hide"), function (x) {
          x.classList.remove("hide");
        });
        $("fbMore").remove();
      });
    }).catch(function () {});
  }

  /* ----------------------------------------------------------- profil */
  function screenMe() {
    topTitle.textContent = "Profil";
    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") +
        "Əsas səhifə</button>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        "<h1>Tədris etdiyiniz fənlər</h1>" +
        '<p class="note">Seçilmiş fənlər sual bankı, test yığma və dərs planı ' +
          "siyahılarını daraldır. Boş saxlasanız bütün fənlər görünür.</p>" +
        '<div class="chips subpick" id="meSubs"><span class="skel">Yüklənir…</span></div>' +
        '<div id="meErr"></div>' +
        '<button class="btn go" id="btnMeSave">Yadda saxla</button>' +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div class="card" id="fbCard">' +
        "<h1>Bizə yazın</h1>" +
        '<p class="note">Təklifiniz, rastlaşdığınız problem və ya sualınız — ' +
          "birbaşa bizə çatır. Cavabımızı burada, mesajın altında görəcəksiniz.</p>" +
        fbForm("fb") +
      "</div>" +
      '<div id="fbMine"></div>' +
      '<div class="spacer"></div>' +
      '<div class="card tight">' +
        "<b>Necə işləyir?</b>" +
        '<p class="note" style="margin:4px 0 0">Qrup, şagird kodu, tapşırıq, hesabat — ' +
          "addım-addım, ekran şəkilləri ilə. " +
          '<a href="../komek/#muellim" target="_blank" rel="noopener">Bələdçini aç →</a></p>' +
      "</div>");
    on("btnBack", "click", function () { nav("#/"); });
    subChips("meSubs", mySubs());
    fbBind("fb", function (kind, body) {
      return sb.rpc("rpc_feedback_send", { p_kind: kind, p_body: body, p_page: FB_FROM });
    }, function () { fbMineLoad(); });
    fbMineLoad();
    on("btnMeSave", "click", function () {
      if (busy) return;
      setBusy("btnMeSave", true, "Yadda saxla");
      sb.rpc("rpc_set_subjects",
             { p_account_id: ACC.id, p_subjects: chipVals("meSubs") })
        .then(function () { return refreshContext(); })
        .then(function () {
          setBusy("btnMeSave", false, "Yadda saxla");
          $("meErr").innerHTML = msg("ok", "Yadda saxlanıldı.");
        })
        .catch(function (e) {
          setBusy("btnMeSave", false, "Yadda saxla");
          $("meErr").innerHTML = msg("err", fail(e));
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
      /*  Bos hesabda (qrup yoxdur) bu blok gizlenir ve "Qrup yarat"
          formasi basliğin altina qalxir - yeni muellim ilk isi
          sehifenin dibinde axtarmasin (loadGroups).  */
      '<div id="hTop">' +
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
      /* Suretli emeliyyatlar - masaustu ucun; telefonda alt menyu eyni
         uc duymeni dasidigi ucun gizlenir (CSS .quick) */
      '<div class="card quick">' +
        '<div class="qhead">Sürətli əməliyyatlar</div>' +
        '<div class="qgrid">' +
          '<button class="qact qa" id="btnGen">' + ic("gen") +
            "<b>Test yığ</b><span>mövzu və çətinliyə görə</span></button>" +
          '<button class="qact qb" id="btnBank">' + ic("doc") +
            "<b>Sual bankı</b><span>öz suallarınız</span></button>" +
          (plansOn()
            ? '<button class="qact qc" id="btnPkt">' + ic("star") +
              "<b>Paket</b><span>" +
              (ACC.plan ? "abunə və müddət" : "qiymətlər və abunə") +
              "</span></button>"
            : "") +
          '<button class="qact qd" id="btnMe">' + ic("person") +
            "<b>Profil</b><span>fənlər · bizə yazın</span></button>" +
        "</div>" +
      "</div>" +
      (isAdmin()
        ? '<div class="spacer"></div>' +
          '<div class="card pad0"><button class="item" id="btnAdm">' +
          '<div class="ic">' + ic("group") + "</div>" +
          '<div class="g"><b>İdarəetmə</b><i><span id="admSub">Hesablar və ' +
            "abunələr (admin)</span></i></div>" +
          '<span class="arrow">' + ic("right") + "</span></button></div>"
        : "") +
      '<div class="spacer"></div>' +
      "</div>" +
      "<h2>Qruplar</h2>" +
      '<div id="groups" class="card pad0"><div class="skel">Yüklənir…</div></div>' +
      '<div id="hRecent"></div>' +
      '<div class="spacer"></div>' +
      '<div class="card" id="gForm">' +
        '<label for="gname">Qrup adı</label>' +
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
    on("btnMe", "click", function () { nav("#/me"); });
    on("btnAdm", "click", function () { nav("#/adm"); });
    if (isAdmin()) {
      sb.rpc("rpc_admin_feedback_count", {}).then(function (n) {
        var e = $("admSub");
        if (e && n > 0) e.innerHTML = "Hesablar, abunələr · <b>" + n + " yeni müraciət</b>";
      }).catch(function () {});
    }

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
        //  Proqram GONDERILMIR: server onu sinifden ozu tapir.
        //  Evvel burada sert "ibtidai" yazilirdi, server ise sinfi
        //  HEMIN proqramin icinde axtarirdi - 8-ci sinif orada
        //  olmadigi ucun qrup SINIFSIZ yaranirdi (db/31).
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

      bellDot(v.alerts ? v.alerts.length : 0);
      var ab = $("hAlerts");
      if (ab && v.alerts && v.alerts.length) {
        ab.innerHTML = '<div class="spacer"></div>' +
          "<h2>Təhlükə zonası</h2>" +
          '<div class="card pad0">' + v.alerts.map(alertRow).join("") + "</div>";
        bindAlerts(ab);
      }

      var rc = $("hRecent");
      if (rc && v.recent && v.recent.length) {
        /* Qrup cipleri: sagird coxaldiqca lent qarismasin - bir
           toxunusla qrupa suzulur.  Tek qrupda cipler gorunmur. */
        var recAll = v.recent;
        var rgs = [];
        recAll.forEach(function (x) {
          if (x.class_id && !rgs.some(function (g) { return g.id === x.class_id; })) {
            rgs.push({ id: x.class_id, name: x["class"] || "" });
          }
        });
        var RF = "", REXP = false, RCAP = 6;
        function recRows() {
          var list = RF ? recAll.filter(function (x) {
            return x.class_id === RF;
          }) : recAll;
          /* Sagird coxaldiqca sehife uzanmasin: ilk 6 setir gorunur,
             qalani "Daha N netice" duymesi ile acilir. */
          var vis = REXP ? list : list.slice(0, RCAP);
          return vis.map(function (x) {
            //  qrup adi yalniz lazim olanda: tek qrupda ve ya cip ile
            //  suzulende o, onsuz da bellidir (basliqla tekrar olurdu)
            return '<div class="trow"><div class="g"><b>' + esc(x.student || "") +
              "</b><i>" + esc(x.test || "") +
              (x["class"] && rgs.length > 1 && !RF ? " · " + esc(x["class"]) : "") +
              " · " + dateAz(x.at) + "</i></div>" +
              pctChip(x.percent) + "</div>";
          }).join("") +
          (list.length > RCAP && !REXP
            ? '<button class="morebtn" id="recMore">Daha ' +
              (list.length - RCAP) + " nəticə göstər</button>"
            : "");
        }
        function recDraw() {
          var rl = $("recList");
          if (!rl) return;
          rl.innerHTML = recRows();
          var mb = $("recMore");
          if (mb) mb.addEventListener("click", function () {
            REXP = true;
            recDraw();
          });
        }
        rc.innerHTML = '<div class="spacer"></div>' +
          "<h2>Son nəticələr</h2>" +
          (rgs.length > 1
            ? '<div class="chips recf" id="recF">' +
              '<button class="chip on" data-rg="">Hamısı</button>' +
              rgs.map(function (g) {
                return '<button class="chip" data-rg="' + esc(g.id) + '">' +
                  esc(g.name) + "</button>";
              }).join("") + "</div>"
            : "") +
          '<div class="card pad0" id="recList"></div>';
        recDraw();
        var rf = $("recF");
        if (rf) rf.addEventListener("click", function (ev) {
          var b = ev.target.closest ? ev.target.closest("[data-rg]") : null;
          if (!b) return;
          RF = b.getAttribute("data-rg");
          REXP = false;
          Array.prototype.forEach.call(rf.querySelectorAll(".chip"), function (c) {
            c.classList.toggle("on", c === b);
          });
          recDraw();
        });
      }
    }).catch(function () {});
  }

  function loadGroups() {
    //  loadLevels() gozleyerken cixis edilibse ACC bosdur - sakit dayan
    if (!ACC) return;
    var groups = null;
    sb.select("classes", {
      select: "id,name,kind,level_id",
      eq: { account_id: ACC.id },
      order: "name"
    }).then(function (rows) {
      groups = rows || [];
      if (!groups.length) return [];
      //  Dayandirilmis sagird qrupda GORUNMEMELIDIR - yer limiti de
      //  yalniz aktivleri sayir (app.account_student_count).
      return sb.select("students", {
        select: "id,class_id", eq: { account_id: ACC.id, is_active: true }
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
          "<b>Hələ qrup yoxdur</b>Şagirdlər və tapşırıqlar qrupun içindədir.</div>";
        //  ilk addim ustde: forma basliğin altina, reqemler gizli
        var top = $("hTop"), gf = $("gForm"), h1 = document.querySelector("h1.hi");
        if (top) top.hidden = true;
        if (gf && h1 && !gf.classList.contains("first")) {
          gf.classList.add("first");
          gf.insertAdjacentHTML("afterbegin", '<div class="fttl">İlk qrupunuzu yaradın</div>');
          h1.insertAdjacentElement("afterend", gf);
        }
        return;
      }
      //  ilk qrup indi yarandi - ekran adi qurulusuna qayidir
      if ($("hTop") && $("hTop").hidden) { screenHome(); return; }
      box.innerHTML = rows.map(function (g) {
        var n = cnt[g.id] || 0;
        var lv = levelName(g.level_id);
        return '<button class="item" data-g="' + esc(g.id) + '">' +
          av(g.name) +
          '<div class="g"><b>' + esc(g.name) + "</b>" +
          "<i>" + (lv ? "<span>" + esc(lv) + "</span><span>·</span>" : "") +
          "<span>" + n + " şagird</span></i></div>" +
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
  /* ------------------------------------------------ «Bu gunun dersi»
     Dersden evvel bir kart: novbeti movzu, son kecilen, tapsirigi
     etmeyenler, hazir addimlar.  Melumat rpc_lesson_prep-den (db/126).
     Plan "kecildi" olanda da yenilenir (planDone -> loadPrep).  */
  function loadPrep(g) {
    var live = guard();
    sb.rpc("rpc_lesson_prep", { p_class_id: g.id }).then(function (d) {
      if (!live()) return;
      var box = $("prep");
      if (!box || !d) return;
      var nx = d.next, ls = d.last, pend = d.pending || [];
      function row(icon, label, body, cls) {
        return '<div class="prow' + (cls ? " " + cls : "") + '">' + ic(icon) +
          '<div><span class="pl">' + label + "</span>" + body + "</div></div>";
      }
      var h = '<div class="spacer"></div><div class="card prep">' +
        '<div class="pt"><b>Bu günün dərsi</b>' +
          '<span class="muted">dərsdən əvvəl bir baxış</span></div>';
      //  1. novbeti movzu
      if (!d.has_plan) {
        h += row("doc", "Növbəti mövzu",
          '<span class="muted">Dərs planı yoxdur. Plan qursanız növbəti mövzu və hazır test burada olacaq. ' +
          '<a href="#" id="prepPlan">Planı qur</a></span>');
      } else if (nx) {
        h += row("doc", "Növbəti mövzu", "<b>" + esc(nx.topic) + "</b>" +
          (nx.group ? ' <s class="muted">· ' + esc(nx.group) + " · " + nx.gpos + "/" + nx.gtotal + "</s>" : ""));
      } else {
        h += row("doc", "Növbəti mövzu", '<span class="muted">Plan tam keçilib. 🎉</span>');
      }
      //  2. son kecilen
      if (ls) {
        h += row("check", "Son keçilən", "<b>" + esc(ls.topic) + "</b>" +
          ' <s class="muted">· ' + dateAz(ls.done_at) +
          (ls.test_id
            ? (ls.avg != null ? " · test " + Math.round(ls.avg) + "% · " + (ls.takers || 0) + " şagird"
                               : " · test verilib, hələ yazan yoxdur")
            : "") + "</s>");
      }
      //  3. tapsirigi etmeyenler
      if (!d.open) {
        h += row("clip", "Ev tapşırığı", '<span class="muted">Açıq tapşırıq yoxdur.</span>');
      } else if (!pend.length) {
        h += row("clip", "Ev tapşırığı", '<span class="pok">Hamı edib ✓</span>');
      } else {
        h += row("clip", "Etməyənlər", pend.slice(0, 8).map(function (x) {
          return '<a href="#/s/' + esc(x.student_id) + "/" + esc(g.id) + '">' + esc(x.name) + "</a>" +
            (x.n > 1 ? " (" + x.n + ")" : "");
        }).join(", ") + (pend.length > 8 ? " və daha " + (pend.length - 8) : "") +
          ' <s class="muted">· ' + pend.length + "/" + d.students + " şagird</s>", "pwarn");
      }
      //  4. addimlar
      h += '<div class="pbtns">' +
        (ls && d.paid
          //  suallar fesle baglidir - duymede fesil adi (alt movzu deyil)
          ? '<button class="btn sm" id="prepGen">' + ic("gen") + "«" + esc(ls.group || ls.topic) + "» testi yığ</button>"
          : "") +
        '<button class="btn sm ghost" id="prepAsg">' + ic("clip") + "Tapşırıq ver</button>" +
      "</div></div>";
      box.innerHTML = h;
      on("prepAsg", "click", function () { nav("#/a/" + g.id); });
      on("prepPlan", "click", function (e) {
        e.preventDefault();
        var b = document.querySelector('#gTabs [data-v="p"]');
        if (b) b.click();
        var op = $("btnPlOpen");
        if (op && !op.classList.contains("hide")) op.click();
      });
      on("prepGen", "click", function () {
        //  generator: qrupun fenn/sinfi + son kecilen fesil secili
        var f = genFilter();
        f.subject = d.subject || ""; f.levels = d.level ? [d.level] : [];
        f.topics = ls.topic_id ? [ls.topic_id] : []; f.remNames = [];
        f.difficulty = []; f.cls = ""; f.title = ""; f.asg = "";
        f.count = 10;
        f.back = g.id; f.backName = g.name || "";
        nav("#/gen");
      });
    }).catch(function () {});   /* kart yardimcidir - xetasi ekrani pozmasin */
  }

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
              "jurnalı və hər mövzudan sonra bir klikə yoxlama testi." +
              (plansOn() ? ' <a href="#/p">Paketlərə bax</a>' : "") + "</p></div>" +
          "</div>";
        return;
      }
      /*  Plan yoxdursa bir setir + duyme; forma duymeye basanda acilir.
          Evvel iki cumle izah ve iki secim her qrupda daim acıq idi
          (UX yoxlamasi).  */
      box.innerHTML =
        '<div class="card">' +
          '<div class="plopen">' +
            '<span class="muted">Mövzu təqvimi, «keçildi» jurnalı, hər mövzudan ' +
              "sonra bir klikə yoxlama testi.</span>" +
            '<button class="btn sm" id="btnPlOpen">' + ic("plus") + "Planı qur</button>" +
          "</div>" +
          '<div id="plForm" hidden>' +
            '<div class="fieldrow" style="margin-top:14px">' +
              '<div><label for="plSub">Fənn</label><select id="plSub"></select></div>' +
              '<div style="flex:0 0 150px"><label for="plLev">Sinif</label>' +
                '<select id="plLev"></select></div>' +
            "</div>" +
            '<div id="plMsg"></div>' +
            '<button class="btn go" id="btnPlMk">' + ic("plus") + "Planı qur</button>" +
          "</div>" +
        "</div>";
      on("btnPlOpen", "click", function () {
        var fm = $("plForm"), op = $("btnPlOpen");
        if (fm) fm.hidden = false;
        if (op) op.parentNode.hidden = true;
      });
      //  Siyahida YALNIZ movzu agaci olan fenn+sinif kombinasiyalari -
      //  agacsiz fenni ("Kurikulum" ve s.) secib xeta almaq olmasin.
      //  Sinif siyahisi fenne gore daralir.
      sb.rpc("rpc_plan_options", {}).then(function (opts) {
        opts = subFilter(opts || []);
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
      }).catch(function (e) {
        //  siyahi gelmese sebebi gizletme - bos select cashdirir
        var m = $("plMsg");
        if (m) m.innerHTML = msg("err", "Fənn siyahısı yüklənmədi: " + fail(e));
      });
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
      /*  Alt movzular varsa setirler artiq FESIL deyil, DERSDIR -
          "2 / 47 ders" demek "2 / 11 movzu"dan durustdur.  */
      var grouped = items.some(function (x) { return !!x.group_id; });
      var unit = grouped ? " dərs · " : " mövzu · ";
      /*  Ardicil setirleri feslere boluruk.  Fesil DB-de setir deyil -
          server onu topics.parent_id-den toredir, biz burada yigiriq.  */
      var blocks = [];
      items.forEach(function (it) {
        var last = blocks[blocks.length - 1];
        if (it.group_id && last && last.gid === it.group_id) {
          last.items.push(it); return;
        }
        blocks.push({ gid: it.group_id || null, name: it.group || "", items: [it] });
      });
      return '<div class="card plan" data-p="' + esc(p.id) + '">' +
        '<div class="plhead"><b>' + esc(p.subject) + " · " + esc(p.level) + "</b>" +
          "<span>" + p.done + " / " + p.total + unit + pct + "%</span></div>" +
        '<div class="plbar"><i style="width:' + pct + '%"></i></div>' +
        (cur
          ? '<div class="plcur"><span class="pltag">Növbəti ' +
              (cur.group ? "dərs" : "mövzu") + "</span>" +
            (cur.group
              ? '<span class="plgn">' + esc(cur.group) +
                (cur.gtotal ? " · " + cur.gpos + "/" + cur.gtotal : "") + "</span>"
              : "") +
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
          '<div class="pllist">' + (function () {
            /*  Gelecek fesiller gizli: 8-ci sinifde 11 fesil siyahini
                uzadirdi, muellime ise kecilen + cari lazimdir.  Qalani
                "Novbetilere bax" altinda acilir (istifadeci teklifi).  */
            var ci = -1;
            blocks.forEach(function (bl, i) {
              if (cur && bl.items.some(function (x) { return x.id === cur.id; })) ci = i;
            });
            if (ci < 0) ci = blocks.length - 1;
            function grp(bl, i) {
              var rows = bl.items.map(plRow).join("");
              if (!bl.gid) return rows;          //  fesilsiz - duz setir
              /*  Fesil YIGILMIS gelir.  Yalniz cari dersin fesli acıq acilir.  */
              var nd = bl.items.filter(function (x) { return x.done; }).length;
              return '<details class="plgrp"' + (i === ci ? " open" : "") + ">" +
                "<summary><b>" + esc(bl.name) + "</b>" +
                '<span class="plgc' + (nd === bl.items.length ? " full" : "") + '">' +
                  nd + "/" + bl.items.length + "</span></summary>" +
                rows + "</details>";
            }
            var now = blocks.slice(0, ci + 1), next = blocks.slice(ci + 1);
            var h = now.map(grp).join("");
            //  fesilsiz duz planda cari dersden sonrakilar da gizlenir
            if (blocks.length === 1 && !blocks[0].gid && cur) {
              var it = blocks[0].items, k = -1;
              it.forEach(function (x, i) { if (x.id === cur.id) k = i; });
              if (k >= 0 && k < it.length - 1) {
                h = it.slice(0, k + 1).map(plRow).join("");
                next = [{ items: it.slice(k + 1), flat: true }];
              }
            }
            if (next.length) {
              var nn = next.reduce(function (a, b) { return a + b.items.length; }, 0);
              h += '<details class="plnext"><summary>Növbətilərə bax ' +
                '<span class="fn">' + (next[0].flat ? nn + " mövzu" : next.length + " fəsil · " + nn + " dərs") +
                "</span></summary>" +
                next.map(function (bl, j) {
                  return bl.flat ? bl.items.map(plRow).join("") : grp(bl, ci + 1 + j);
                }).join("") + "</details>";
            }
            return h;
          })() + "</div>" +
          '<div class="plmbar" id="plmb-' + esc(p.id) + '"></div>' +
          '<button class="btn sm ghost" data-pldel="' + esc(p.id) +
            '" style="margin-top:10px">Planı sil</button>' +
        "</details>" +
        '<div id="plm-' + esc(p.id) + '"></div>' +
      "</div>";

      function plRow(it) {
            /* Movzu testinin qrup ortalamasi - plan adaptiv olsun:
               zeif cixan movzu qirmizi gorunur, "tekrar yig" teklif olunur */
            var avgN = it.avg == null ? null : Number(it.avg);
            var avgChip = "";
            if (it.done && avgN != null) {
              avgChip = '<b class="plavg ' +
                (avgN >= 80 ? "pvh" : (avgN >= 60 ? "pvm" : "pvl")) +
                '" title="Qrup ortalaması · ' + (Number(it.takers) || 0) +
                ' şagird">' + Math.round(avgN) + "%</b>";
            }
            var weak = it.done && it.test_id && avgN != null && avgN < 60;
            //  "ok" YOX: base.css-de .ok yasil netice qutusudur - setir sisirdi
            return '<div class="plrow' + (it.done ? " done" : "") +
              (cur && it.id === cur.id ? " cur" : "") + '">' +
              "<i>" + (it.done ? "✓" : it.ord) + "</i>" +
              "<span>" + esc(it.topic) +
                (it.done && it.done_at
                  ? ' <s class="pldate">· ' + dateAz(it.done_at) + "</s>" : "") +
              "</span>" +
              avgChip +
              (it.done && d.paid
                ? '<input type="checkbox" class="plck" data-plck="' + esc(p.id) +
                  '" value="' + esc(it.id) + '" title="Birgə test üçün seç">'
                : "") +
              (it.test_id
                ? '<a href="#/t/' + esc(it.test_id) + '" class="pltest">vərəq</a>'
                /*  can_test serverden gelir: fesilsiz movzuda ozu,
                    fesildə ise YALNIZ son dersde.  Suallar fesle
                    baglidir - hər dersde teklif etsek bes ders eyni
                    hovuzdan demek olar eyni testi yigardi.  */
                : (it.can_test
                    ? '<button class="plmk" data-plmk="' + esc(it.id) + '"' +
                      (d.paid ? "" : ' disabled title="Abunə paketi ilə"') +
                      ">test yığ</button>"
                    : "")) +
              (weak && d.paid
                ? '<button class="plmk plre" data-plmk="' + esc(it.id) +
                  '" title="Qrup zəif nəticə göstərib — yeni yoxlama yığ">' +
                  "təkrar yığ</button>"
                : "") +
              (lastDone && it.id === lastDone.id
                ? '<button class="plundo" data-plundo="' + esc(it.id) +
                  '" title="Geri qaytar">geri</button>' : "") +
            "</div>";
      }
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
      id = b.getAttribute("data-plmk");
      if (id) return planOfferLate(id);
      id = b.getAttribute("data-plmulti");
      if (id) {
        var ids = [];
        Array.prototype.forEach.call(
          box.querySelectorAll('[data-plck="' + id + '"]:checked'),
          function (c) { ids.push(c.value); });
        if (ids.length < 2) return;
        var s3 = $("pls-" + id); if (s3) s3.innerHTML = "";
        var m3 = $("plm-" + id);
        if (m3) {
          m3.innerHTML = offerHtml(
            "Seçilən " + ids.length + " mövzudan qarışıq test yığılsınmı?",
            ids.join(","), id);
          m3.scrollIntoView({ block: "nearest" });
        }
        return;
      }
      id = b.getAttribute("data-plskip");
      if (id) {
        var s2 = $("pls-" + id); if (s2) s2.innerHTML = "";
        var m2 = $("plm-" + id); if (m2) m2.innerHTML = "";
        return;
      }
    });
    //  birge test: 2+ movzu secilende duyme cixir
    box.addEventListener("change", function (ev) {
      var c = ev.target;
      var pid = c && c.getAttribute ? c.getAttribute("data-plck") : null;
      if (!pid) return;
      var n = box.querySelectorAll('[data-plck="' + pid + '"]:checked').length;
      var bar = $("plmb-" + pid);
      if (bar) bar.innerHTML = n >= 2
        ? '<button class="btn sm" data-plmulti="' + esc(pid) + '">' +
          "Seçilən " + n + " mövzudan birgə test yığ</button>"
        : "";
    });
    function rebindOnly() {}
  }

  /*  can_test-i YERLI olaraq yeniden hesablayir.
      Serverin qaydasi ile eynidir (db/32): fesilsiz movzuda ozu,
      fesildə ise YALNIZ son ders.  Niye tekrarlanir: "Kecildi"
      basilanda ekran DERHAL yenilenir, serverden yeniden sorusmuruq -
      yoxsa acilan "test yigilsinmi?" teklifi silinerdi.  Server yene
      de esas menbedir: sehife yenilenende onun deyeri gelir.  */
  function planCanTest(p) {
    var items = p.items || [];
    items.forEach(function (it, i) {
      if (!it.done) { it.can_test = false; return; }
      if (!it.group_id) { it.can_test = true; return; }
      var son = true;
      for (var j = i + 1; j < items.length; j++) {
        if (items[j].group_id === it.group_id) { son = false; break; }
      }
      it.can_test = son;
    });
  }

  function planDone(g, b, itemId) {
    busy = true; b.disabled = true;
    sb.rpc("rpc_plan_done", { p_item_id: itemId }).then(function () {
      busy = false;
      //  yerli veziyyeti yenile ve TEKLIF goster - "komekci isci" ani
      var plan = null, topic = "";
      (PLD.plans || []).forEach(function (p) {
        (p.items || []).forEach(function (it) {
          if (it.id === itemId) {
            it.done = true;
            //  done_at-i da qoyuruq: yoxsa setirde tarix yalniz
            //  sehife yenilenenden sonra cixirdi
            it.done_at = new Date().toISOString();
            p.done++; plan = p; topic = it.topic;
          }
        });
        planCanTest(p);
      });
      drawPlan(g);
      loadPrep(g);
      var slot = plan && $("pls-" + plan.id);
      if (slot) {
        slot.innerHTML = offerHtml(
          "«" + esc(topic) + "» keçildi. Ev tapşırığı verilsinmi?",
          itemId, plan.id);
      }
    }).catch(function (e) {
      busy = false; b.disabled = false;
      alert(fail(e));
    });
  }

  /* Test teklifi qutusu - hem "Kecildi" aninda, hem sonradan siyahidan */
  function offerHtml(head, itemId, planId) {
    return '<div class="ploffer">' +
      "<b>" + head + "</b>" +
      '<p class="muted" style="margin:4px 0 10px">Sistem bu fəsildən test yığır ' +
        "və qrupa dərhal tapşırır (son tarix 7 gün, 1 cəhd). Sonra şagirdlərə " +
        "hazır WhatsApp mətni çıxır.</p>" +
      '<div class="plbtns">' +
        '<input id="plCnt" type="number" min="3" max="50" value="10">' +
        '<button class="btn go sm" data-pltest="' + esc(itemId) + '">' +
          "Yığ və tapşırıq ver</button>" +
        '<button class="btn sm ghost" data-plskip="' + esc(planId) +
          '">Sonra</button>' +
      "</div>" +
    "</div>";
  }

  /* "Sonra" deyilmis (ve ya bir nece movzu kecilmis) halda siyahidan
     istenilen KECILMIS movzu ucun teklifi yeniden acmaq */
  function planOfferLate(itemId) {
    var plan = null, topic = "";
    (PLD && PLD.plans || []).forEach(function (p) {
      (p.items || []).forEach(function (it) {
        if (it.id === itemId) { plan = p; topic = it.topic; }
      });
    });
    if (!plan) return;
    var s = $("pls-" + plan.id);
    if (s) s.innerHTML = "";
    var m = $("plm-" + plan.id);
    if (m) {
      m.innerHTML = offerHtml(
        "«" + esc(topic) + "» — ev tapşırığı verilsinmi?", itemId, plan.id);
      m.scrollIntoView({ block: "nearest" });
    }
  }

  function planUndo(g, itemId) {
    busy = true;
    sb.rpc("rpc_plan_undo", { p_item_id: itemId })
      .then(function () { busy = false; loadPlan(g); })
      .catch(function (e) { busy = false; alert(fail(e)); });
  }

  function planTest(g, b, itemId) {
    var n = Number(($("plCnt") || {}).value) || 15;
    //  vergullu id = bir nece movzudan QARISIQ test
    var multi = itemId.indexOf(",") >= 0;
    var card = b.closest ? b.closest(".plan") : null;
    busy = true; b.disabled = true;
    b.textContent = "Yığılır…";
    (multi
      ? sb.rpc("rpc_plan_test_multi",
               { p_item_ids: itemId.split(","), p_count: n })
      : sb.rpc("rpc_plan_test", { p_item_id: itemId, p_count: n }))
      .then(function (r) {
        busy = false;
        //  tek movzuda itemin testini yerli olaraq bagla; qarisiq test
        //  item-e baglanmir - netice mesaji linki verir
        var pid = card ? card.getAttribute("data-p") : null;
        if (!multi) {
          (PLD.plans || []).forEach(function (p) {
            (p.items || []).forEach(function (it) {
              if (it.id === itemId) { it.test_id = r.test_id; pid = p.id; }
            });
          });
        }
        drawPlan(g);
        loadPrep(g);
        var m = $("plm-" + pid);
        //  msg() metni esc edir - link ucun qutunu ozumuz yigiriq
        if (m) {
          m.innerHTML = '<div class="ok">' + ic("check") +
            "<span>Test yığıldı və qrupa tapşırıq verildi. " +
            '<a href="#/t/' + esc(r.test_id) + '">Vərəqə bax</a></span></div>' +
            '<div id="plwa-' + esc(pid) + '"></div>';
          //  testin adi RPC-den gelmir - bir setirlik oxuma, sonra WhatsApp qutusu
          sb.select("tests", { select: "title", eq: { id: r.test_id } }).then(function (rows) {
            var w = $("plwa-" + pid);
            if (!w) return;
            var ttl = (rows && rows[0] && rows[0].title) || "Ev tapşırığı";
            w.innerHTML = asgShareBox(ttl, new Date(Date.now() + 7 * 864e5).toISOString(), "")
              .replace(/^<div class="ok asgok">[\s\S]*?<\/div>/, "");
            bindWaCopy(w);
          }).catch(function () {});
        }
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
      sb.select("classes", { select: "id,name,account_id,level_id", eq: { id: id } }),
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

  //  Qrup ekraninda secilmis sekme - sehife yenilenende de qalir (sessionStorage)
  var GTAB = (function () { try { return sessionStorage.getItem("gtab") || "s"; } catch (e) { return "s"; } })();
  //  "Yeni sagird" formasi: duyme ile acilir; acilandan sonra bagliya qeder qalir
  function openStuForm(focus) {
    var f = $("stuForm"), b = $("btnStuOpen");
    if (!f) return;
    f.hidden = false;
    if (b) b.classList.add("hide");   // .btn display qaydasi hidden atributunu ezir
    if (focus && $("sname")) $("sname").focus();
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
            ? "<span>" + esc(levelName(g.level_id)) + "</span>" : "") +
          "</div>" +
        '<div class="spacer"></div>' +
        '<div class="row two">' +
          '<button class="btn wide" id="btnAsgs">' + ic("clip") + "Tapşırıqlar</button>" +
          '<button class="btn wide" id="btnRep">' + ic("chart") + "Hesabat</button>" +
        "</div>" +
      "</div>" +
      '<div id="prep"></div>' +
      '<div id="alerts"></div>' +
      /*  Iki sekme (istifadeci teklifi): plan + 30 sagird + forma alt-alta
          on ekran olurdu.  Sagirdler acıq gelir; "Yeni sagird" formasi
          duyme ile acilir (sagird yoxdursa - avtomatik acıq).  */
      '<div class="segs stabs" id="gTabs">' +
        seg("s", 'Şagirdlər <span class="tn hide" id="gTabN"></span>', GTAB) +
        seg("p", "Dərs planı", GTAB) +
      "</div>" +
      '<div class="stab" id="gtab-s"' + (GTAB === "s" ? "" : " hidden") + ">" +
        '<div id="stu" class="card pad0"><div class="skel">Yüklənir…</div></div>' +
        '<button class="btn wide" id="btnStuOpen" style="margin-top:10px">' + ic("plus") +
          "Şagird əlavə et</button>" +
        '<div class="card" id="stuForm" hidden style="margin-top:10px">' +
          '<label for="sname">Yeni şagird</label>' +
          '<input id="sname" placeholder="Ad və soyad">' +
          '<p class="muted" style="margin:-8px 0 14px">Lövhədə qısa ad: ' +
            "Aysu Məmmədova → Aysu M.</p>" +
          '<div id="sErr"></div>' +
          '<button class="btn go" id="btnStu">' + ic("plus") + "Şagird əlavə et</button>" +
        "</div>" +
      "</div>" +
      '<div class="stab" id="gtab-p"' + (GTAB === "p" ? "" : " hidden") + ">" +
        '<div id="planBox"><div class="card"><div class="skel">Yüklənir…</div></div></div>' +
      "</div>"
    );
    on("gTabs", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
      GTAB = b.getAttribute("data-v");
      try { sessionStorage.setItem("gtab", GTAB); } catch (e) {}
      Array.prototype.forEach.call(document.querySelectorAll("#gTabs .seg"), function (x) {
        x.classList.toggle("on", x.getAttribute("data-v") === GTAB);
      });
      Array.prototype.forEach.call(document.querySelectorAll(".stab"), function (x) {
        x.hidden = x.id !== "gtab-" + GTAB;
      });
    });
    on("btnStuOpen", "click", function () { openStuForm(true); });

    on("btnBack", "click", function () { nav("#/"); });
    on("btnRep", "click", function () { nav("#/r/" + g.id); });
    on("btnAsgs", "click", function () { nav("#/a/" + g.id); });
    loadPrep(g);
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
      //  Sinif deyisirse proqram da onunla getmelidir - yoxsa qrup
      //  "orta" sinifde, "ibtidai" proqramda qalir (uygunsuz melumat).
      var patch = { name: nm, level_id: newLevel };
      if (lv) patch.program_id = lv.program_id || null;
      sb.update("classes", { id: g.id }, patch)
        .then(function () {
          g.name = nm; g.level_id = newLevel;
          topTitle.textContent = nm;
          if ($("gName")) $("gName").textContent = nm;
          var meta = $("gMeta");
          if (meta) {
            meta.innerHTML =
              (levelName(newLevel)
                ? "<span>" + esc(levelName(newLevel)) + "</span>" : "");
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
      /*  Valideyn girisi burdadir, setirde yox: acmaq birdefelik
          qerardir, gundelik emeliyyat deyil.  Acilandan SONRA kod
          setirde gorunur - onu her defe kopyalamaq lazim olur.  */
      (s.parent_code ? "" :
        '<div class="pbox"><button class="btn sm ghost" data-pon="' +
          esc(s.id) + '">Valideyn girişini aç</button>' +
        '<span class="muted">Valideyn uşağın dərslərini və ' +
          "nəticələrini görəcək. İstədiyiniz vaxt bağlaya bilərsiniz." +
        "</span></div>") +
      '<div class="danger"><button class="btn sm ghost" data-reset="' +
        esc(s.id) + '">' + ic("refresh") + "Giriş kodunu yenilə</button>" +
      '<span class="muted">Köhnə kod etibarsız olur.</span></div>' +
      /*  Dayandirmaq nadir isdir - setirden bura kecdi ki, her sagirdde
          bes duyme durmasin (UX yoxlamasi).  */
      '<div class="danger"><button class="btn sm ghost arch" data-arch="' +
        esc(s.id) + '">Dayandır</button>' +
      '<span class="muted">Giriş bağlanır, yer boşalır, nəticələr qalır.</span></div>' +
      "</div>");
    var box = row.querySelector(".edit");
    var n1 = box.querySelector(".eName");
    n1.value = s.full_name;
    n1.focus(); n1.select();
    box.querySelector(".eCancel").addEventListener("click", function () { box.remove(); });
    box.querySelector(".eSave").addEventListener("click", save);
    var pon = box.querySelector("[data-pon]");
    if (pon) pon.addEventListener("click", function () {
      parentAccess(s.id, true, pon, classId);
    });
    box.querySelector("[data-arch]").addEventListener("click", function () {
      if (!confirm("«" + s.full_name + "» dayandırılsın?\n\n" +
                   "Giriş kodu dərhal işləməyi dayandırır və şagird " +
                   "paketdə yer tutmur. Keçmiş nəticələri qalır — " +
                   "istənilən vaxt davam etdirə bilərsiniz.")) return;
      setActive(s, false, this, classId);
    });
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
      select: "id,full_name,display_name,login_code,is_active,parent_code",
      eq: { class_id: classId },
      order: "full_name"
    }).then(function (rows) {
      //  sekme basligina say; sagird yoxdursa forma avtomatik acıq
      var tn = $("gTabN");
      if (tn) {
        var na = (rows || []).filter(function (x) { return x.is_active; }).length;
        tn.textContent = na; tn.classList.toggle("hide", !na);   // inline-block hidden-i ezir
      }
      if (!rows || !rows.length) openStuForm(false);
      var box = $("stu");
      if (!box) return;
      if (!rows || !rows.length) {
        box.innerHTML = '<div class="empty"><div class="ic">' + ic("person") + "</div>" +
          "<b>Hələ şagird yoxdur</b>Aşağıdan əlavə edin.</div>";
        return;
      }
      /*  Dayandirilmislar AYRICA bolmededir.  Sebeb: yer limiti yalniz
          aktivleri sayir, ona gore dayandirilmis sagird siyahida
          aktivlerle qarisib muellimi caşdirirdi ("niye 8 sagird
          gorunur, 6 yer tutulub?").  Bolme yigilmis gelir.  */
      var aktiv = rows.filter(function (s) { return s.is_active !== false; });
      var dayan = rows.filter(function (s) { return s.is_active === false; });

      box.innerHTML = aktiv.map(stuRow).join("") +
        (dayan.length
          ? '<details class="arxiv"><summary>Dayandırılmış <span>' + dayan.length +
            "</span></summary>" + dayan.map(stuRow).join("") + "</details>"
          : "");

      function stuRow(s) {
        //  Dayandirilmis sagirdin kodu ONSUZ DA islemir (app.session_student
        //  is_active yoxlayir), ona gore kod/gonder duymeleri cixmir.
        //  "Hesabat" qalir - kecmis neticeler itmeyib.
        if (s.is_active === false) {
          return '<div class="stu off" data-row="' + esc(s.id) + '">' +
            '<div class="l1">' + av(s.full_name) + "<b>" + esc(s.full_name) + "</b>" +
              '<button class="btn sm ghost link" data-rep="' + esc(s.id) + '">' +
                "Hesabat" + ic("right") + "</button></div>" +
            '<div class="l2"><span class="muted">Dayandırılıb — yer tutmur</span>' +
              '<button class="btn sm" data-unarch="' + esc(s.id) + '">' +
                "Davam etdir</button></div></div>";
        }
        return stuRowActive(s);
      }

      function stuRowActive(s) {
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
          "</div>" +
          /*  VALIDEYN GIRISI - susmaya gore BAGLI.
              Bezi muellimler isinin seffaflasmasindan narahat olur;
              mecburi etsek muellimi itiririk.

              BAGLI ikən setirde HEC NE gorunmur: acmaq nadir, birdefelik
              emeliyyatdir ve qelemin altindadir (kod yenilemek kimi).
              Telefonda setir onsuz da uc duyme dasiyir - dorduncusu onu
              sisirdirdi (e2e heddi 120px, olculdu: 142px).
              Kod VARSA ise ayrica setir lazimdir: muellim onu her defe
              kopyalayib gonderecek, qelemin altinda gizli qalmamalidir.  */
          (s.parent_code
            ? '<div class="l3">' +
                '<span class="pcap">Valideyn</span>' +
                '<span class="code key">' + esc(s.parent_code) + "</span>" +
                '<button class="btn sm ghost icon" data-copy="' + esc(s.parent_code) +
                  '" title="Valideyn kodunu kopyala" ' +
                  'aria-label="Valideyn kodunu kopyala">' + ic("copy") + "</button>" +
                '<button class="btn sm" data-pwa="' + esc(s.id) + '">' +
                  ic("send") + "Göndər</button>" +
                '<button class="btn sm ghost link" data-pnew="' + esc(s.id) + '">' +
                  "Yenilə</button>" +
                '<button class="btn sm ghost link arch" data-poff="' + esc(s.id) + '">' +
                  "Bağla</button>" +
              "</div>"
            : "") +
          "</div>";
      }

      Array.prototype.forEach.call(box.querySelectorAll("[data-copy]"), function (b) {
        b.addEventListener("click", function () {
          copyText(b.getAttribute("data-copy"), b);
        });
      });
      //  Valideyn girisi: ac / yenile / bagla
      Array.prototype.forEach.call(box.querySelectorAll("[data-pon]"), function (b) {
        b.addEventListener("click", function () {
          parentAccess(b.getAttribute("data-pon"), true, b, classId);
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-poff]"), function (b) {
        b.addEventListener("click", function () {
          if (!confirm("Valideyn girişi bağlansın?\n\nAçıq baxış dərhal " +
                       "kəsiləcək və kod işləməyəcək.")) return;
          parentAccess(b.getAttribute("data-poff"), false, b, classId);
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-pwa]"), function (b) {
        b.addEventListener("click", function () {
          var s = rows.filter(function (x) {
            return x.id === b.getAttribute("data-pwa");
          })[0];
          if (s) window.open(waLinkParent(s), "_blank", "noopener");
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-pnew]"), function (b) {
        b.addEventListener("click", function () {
          if (!confirm("Valideyn kodu yenilənsin?\n\nKöhnə kod dərhal " +
                       "etibarsız olacaq.")) return;
          var id = b.getAttribute("data-pnew");
          b.disabled = true; b.textContent = "Gözləyin…";
          sb.rpc("rpc_parent_code_reset", { p_student_id: id })
            .then(function () { loadStudents(classId); })
            .catch(function (e) {
              b.disabled = false; b.textContent = "Yenilə"; alert(fail(e));
            });
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
      Array.prototype.forEach.call(box.querySelectorAll("[data-arch]"), function (b) {
        b.addEventListener("click", function () {
          var st = rows.filter(function (x) {
            return x.id === b.getAttribute("data-arch"); })[0];
          if (!st) return;
          if (!confirm("«" + st.full_name + "» dayandırılsın?\n\n" +
                       "Giriş kodu dərhal işləməyi dayandırır və şagird " +
                       "paketdə yer tutmur. Keçmiş nəticələri qalır — " +
                       "istənilən vaxt davam etdirə bilərsiniz.")) return;
          setActive(st, false, b, classId);
        });
      });
      Array.prototype.forEach.call(box.querySelectorAll("[data-unarch]"), function (b) {
        b.addEventListener("click", function () {
          var st = rows.filter(function (x) {
            return x.id === b.getAttribute("data-unarch"); })[0];
          if (st) setActive(st, true, b, classId);
        });
      });
    }).catch(function (e) {
      var box = $("stu");
      if (box) box.innerHTML = '<div class="skel">' + esc(fail(e)) + "</div>";
    });
  }

  /*  Dayandirmaq / davam etdirmek.
      Ayrica RPC lazim deyil: RLS onsuz da yalniz oz sagirdine icaze
      verir, yer limiti ise BAZA TRIGGER-indedir (trg_students_seat_limit).
      Trigger geri qaytarmada limiti YENIDEN yoxlayir - yerler dolubsa
      xeta atir ve mesaji oldugu kimi gosteririk.  */
  /*  Valideyn girisini acir/baglayir.  Ekran YENIDEN cizilir ki, kod
      (ve ya onun yoxlugu) derhal gorunsun.  */
  function parentAccess(id, on2, btn, classId) {
    var kohne = btn.textContent;
    btn.disabled = true;
    btn.textContent = on2 ? "Açılır…" : "Bağlanır…";
    sb.rpc("rpc_parent_access", { p_student_id: id, p_on: !!on2 })
      .then(function () { loadStudents(classId); })
      .catch(function (e) {
        btn.disabled = false; btn.textContent = kohne; alert(fail(e));
      });
  }

  function setActive(st, aktiv, btn, classId) {
    if (busy) return;
    busy = true; btn.disabled = true;
    btn.textContent = aktiv ? "Açılır…" : "Dayandırılır…";
    sb.update("students", { id: st.id }, { is_active: aktiv })
      .then(function () {
        busy = false;
        loadStudents(classId);      //  siyahi yeniden bolunsun
        //  Yer sayğaci ACC-de kesledirilib (rpc_my_context) - dayandirma
        //  onu deyisdiyi ucun kesi tezelemek lazimdir, yoxsa ev
        //  sehifesinde kohne rəqəm qalir.
        refreshContext().catch(function () {});
      })
      .catch(function (e) {
        busy = false; btn.disabled = false;
        btn.textContent = aktiv ? "Davam etdir" : "Dayandır";
        alert(fail(e));
      });
  }

  /*  Valideynə göndərilən mesaj.  Şagirdinki ilə eyni qəlibdə, amma
      AYRI ünvan və AYRI kod - qarışsa valideyn uşağın kodunu alar. */
  function waLinkParent(s) {
    var url = (window.CFG && window.CFG.PARENT_URL) || "";
    var t = "Salam! " + s.full_name + " üçün valideyn girişi:\n\n" +
            "Link: " + url + "\n" +
            "Valideyn kodu: " + s.parent_code + "\n\n" +
            "Linki açıb kodu yazın — dərsləri, tapşırıqları və " +
            "nəticələri görəcəksiniz.";
    return "https://wa.me/?text=" + encodeURIComponent(t);
  }

  function waLink(s) {
    var url = (window.CFG && window.CFG.STUDENT_URL) || "";
    var t = "Salam! " + s.full_name + " üçün test girişi:\n\n" +
            "Link: " + url + "\n" +
            "Giriş kodu: " + s.login_code + "\n\n" +
            "Linki açıb kodu yazmaq kifayətdir.";
    return "https://wa.me/?text=" + encodeURIComponent(t);
  }

  /*  Tapsiriqdan sonra hazir WhatsApp metni.  Sagirde bildiris gondere
      bilmirik (xarici sebeke yoxdur) - muellim bir toxunusla qrupa atir.  */
  function waAsgText(title, closes, who) {
    var url = (window.CFG && window.CFG.STUDENT_URL) || "";
    return "Salam" + (who ? ", " + who.split(" ")[0] : "") + "! Bil10-da yeni tapşırıq var: «" +
      title + "».\n" +
      (closes ? "Son tarix: " + dateAz(closes) + ".\n" : "") +
      "Link: " + url + "\nKodunla gir — «Tapşırıqlar»da gözləyir.";
  }
  function asgShareBox(title, closes, who) {
    var t = waAsgText(title, closes, who);
    return '<div class="ok asgok">' + ic("check") +
      "<span><b>Tapşırıq verildi:</b> «" + esc(title) + "»" +
      (who ? " — yalnız " + esc(who) : "") + ". Şagirdlərə xəbər verin:</span></div>" +
      '<div class="asgwa">' +
        '<a class="btn sm go" target="_blank" rel="noopener" href="https://wa.me/?text=' +
          encodeURIComponent(t) + '">' + ic("send") + "WhatsApp-a göndər</a>" +
        '<button class="btn sm ghost" type="button" data-wacopy="1">' + ic("copy") + "Mətni kopyala</button>" +
        '<textarea class="watxt" readonly rows="4">' + esc(t) + "</textarea>" +
      "</div>";
  }
  function bindWaCopy(root) {
    Array.prototype.forEach.call((root || document).querySelectorAll("[data-wacopy]"), function (b) {
      if (b.dataset.bound) return; b.dataset.bound = "1";
      b.addEventListener("click", function () {
        var ta = b.parentElement.querySelector(".watxt");
        if (ta) copyText(ta.value, b);
      });
    });
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

  var RTAB = "s";   // qrup hesabatinda secilmis sekme (sessiya boyu)
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

      /*  Uc sekme: Sagirdler / Movzular / Fealiyyet.  Movzular butun
          fennlerden 30+ setir, fealiyyet 11 setir - bir sehifede
          uzanirdi (istifadeci teklifi, sagird hesabati ile eyni qayda).  */
      var st = r.students || [];
      var hS = "";
      if (!st.length) {
        hS += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("person") +
             "</div><b>Şagird yoxdur</b></div></div>";
      } else {
        hS += '<div class="card pad0">' + st.map(function (s) {
          return '<button class="item" data-s="' + esc(s.id) + '">' +
            av(s.full_name) +
            '<div class="g"><b>' + esc(s.full_name) + "</b>" +
            "<i><span>" + (s.attempts || 0) + " test</span><span>·</span>" +
            "<span>son: " + dateAz(s.last_at) + "</span></i>" +
            meter(s.avg) + "</div>" +
            (s.attempts ? pctChip(s.avg) : '<span class="pctv">—</span>') +
            '<span class="arrow">' + ic("right") + "</span></button>";
        }).join("") + "</div>";
      }

      var hM = "";
      var rt = r.topics || [];
      var weakAll = rt.filter(function (t) { return Number(t.ratio) < 60; });
      var rsubs = [];
      rt.forEach(function (t) {
        var k = t.subject_slug || t.subject;
        if (k && !rsubs.some(function (x) { return x.key === k; })) rsubs.push({ key: k, name: t.subject });
      });
      var rmine = rsubs.filter(function (x) { return mySubs().indexOf(x.key) >= 0; });
      var RSUB = (rsubs.length > 1 && rmine.length === 1) ? rmine[0].key : "";
      var RCAP = 8, REXP2 = false;
      if (r.topics === null) {
        hM += upsell("Mövzu üzrə analiz");
      } else if (!rt.length) {
        hM += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("chart") +
             "</div><b>Hələ kifayət qədər cavab yoxdur</b>" +
             "Mövzu üzrə nəticə üçün ən azı 3 cavab lazımdır.</div></div>";
      } else {
        hM += (rsubs.length > 1
                ? '<div class="chips recf" id="rSub">' +
                  '<button class="chip' + (RSUB ? "" : " on") + '" data-rs="">Hamısı</button>' +
                  rsubs.map(function (x) {
                    return '<button class="chip' + (RSUB === x.key ? " on" : "") +
                      '" data-rs="' + esc(x.key) + '">' + esc(x.name) + "</button>";
                  }).join("") + "</div>"
                : "") +
          '<div id="rTopicBox"></div>' +
          /* Dovreni baglayan duyme: zeif movzular -> hazir test.
             Generator qrupun SEHV ETDIYI suallara benzeyenleri de
             avtomatik one cekir (rule.class). */
          (weakAll.length
            ? '<div class="spacer"></div>' +
              '<button class="btn go wide" id="btnRem">' + ic("gen") +
              "Zəif mövzulardan test yığ (" + weakAll.length + ")</button>"
            : "");
      }
      function rTopicRow(t) {
        return '<div class="trow"><div class="g"><b>' +
          (Number(t.ratio) < 60 ? '<span class="wdot" title="Zəif mövzu"></span>' : "") +
          esc(t.name) + "</b>" +
          "<i>" + esc(t.subject) + " · " + t.correct + " / " + t.total + "</i>" +
          meter(t.ratio) + "</div>" +
          pctChip(t.ratio) + "</div>";
      }
      function drawRTopics() {
        var box = $("rTopicBox");
        if (!box) return;
        var list = rt.filter(function (t) { return !RSUB || (t.subject_slug || t.subject) === RSUB; })
          .slice().sort(function (a, b) { return Number(a.ratio) - Number(b.ratio); });
        var need = list.filter(function (t) { return Number(t.ratio) < 80; });
        var good = list.filter(function (t) { return Number(t.ratio) >= 80; });
        var vis = REXP2 ? need : need.slice(0, RCAP);
        box.innerHTML =
          (need.length
            ? '<div class="card pad0">' + vis.map(rTopicRow).join("") +
              (need.length > vis.length
                ? '<button class="morebtn" id="rMore">Daha ' + (need.length - vis.length) + " mövzu göstər</button>"
                : "") + "</div>"
            : '<div class="ok">' + ic("check") + "<span>Bütün mövzular yaxşıdır (≥80%).</span></div>") +
          (good.length
            ? '<details class="more filt" style="margin-top:10px"><summary>Yaxşı mövzular ' +
              '<span class="fn">' + good.length + "</span></summary>" +
              '<div class="card pad0" style="margin-top:10px">' + good.map(rTopicRow).join("") + "</div></details>"
            : "");
        on("rMore", "click", function () { REXP2 = true; drawRTopics(); });
      }

      var hF = "";
      var rec = r.recent || [];
      var FCAP = 8;
      if (!rec.length) {
        hF += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("clock") +
          "</div><b>Hələ fəaliyyət yoxdur</b></div></div>";
      } else {
        hF += '<div class="card pad0" id="rRec">' + rec.map(function (x, i) {
            return '<div class="trow' + (i >= FCAP ? " hide" : "") + '"><div class="g"><b>' +
              esc(x.student) + "</b>" +
              "<i>" + esc(x.test) + " · " + dateAz(x.at) + "</i></div>" +
              pctChip(x.percent) + "</div>";
          }).join("") +
          (rec.length > FCAP
            ? '<button class="morebtn" id="rRecMore">Daha ' + (rec.length - FCAP) + " nəticə göstər</button>"
            : "") + "</div>";
      }

      h += '<div class="segs stabs" id="rTabs">' +
          seg("s", "Şagirdlər" + (st.length ? ' <span class="tn">' + st.length + "</span>" : ""), RTAB) +
          seg("m", "Mövzular" + (weakAll.length ? ' <span class="tn">' + weakAll.length + "</span>" : ""), RTAB) +
          seg("f", "Fəaliyyət" + (rec.length ? ' <span class="tn">' + rec.length + "</span>" : ""), RTAB) +
        "</div>" +
        '<div class="stab" id="rtab-s"' + (RTAB === "s" ? "" : " hidden") + ">" + hS + "</div>" +
        '<div class="stab" id="rtab-m"' + (RTAB === "m" ? "" : " hidden") + ">" + hM + "</div>" +
        '<div class="stab" id="rtab-f"' + (RTAB === "f" ? "" : " hidden") + ">" + hF + "</div>";

      show(h);
      stamp();
      drawRTopics();
      on("rTabs", "click", function (e) {
        var b = e.target.closest ? e.target.closest("[data-v]") : null;
        if (!b) return;
        RTAB = b.getAttribute("data-v");
        Array.prototype.forEach.call(document.querySelectorAll("#rTabs .seg"), function (x) {
          x.classList.toggle("on", x.getAttribute("data-v") === RTAB);
        });
        Array.prototype.forEach.call(document.querySelectorAll(".stab"), function (x) {
          x.hidden = x.id !== "rtab-" + RTAB;
        });
      });
      on("rSub", "click", function (e) {
        var b = e.target.closest ? e.target.closest("[data-rs]") : null;
        if (!b) return;
        RSUB = b.getAttribute("data-rs"); REXP2 = false;
        Array.prototype.forEach.call(document.querySelectorAll("#rSub .chip"), function (x) {
          x.classList.toggle("on", x === b);
        });
        drawRTopics();
      });
      on("rRecMore", "click", function () {
        Array.prototype.forEach.call(document.querySelectorAll("#rRec .trow.hide"), function (x) {
          x.classList.remove("hide");
        });
        $("rRecMore").remove();
      });
      on("btnB", "click", function () { nav("#/g/" + gid); });
      on("btnRef", "click", function () { screenReport(gid); });
      on("btnRem", "click", function () { remedialGen(gid, weakAll); });
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
  /* ------------------------------------------- tedris fennleri (filtr)
     Hesabda secilmis fennler fenn siyahilarini daraldir: sual banki,
     generator, ders plani.  Bos siyahi ve ya "secilenlerde hec ne
     yoxdur" hali = tam siyahi.  Bu filtrdir, mehdudiyyet deyil. */
  function mySubs() { return (ACC && ACC.subjects) || []; }
  //  Fenn slug -> ad siyahisi (bir defe yuklenir) - tapsiriq siyahisini
  //  muellimin fennine gore siralamaq ucun
  var SUBNAMES = null;
  function subjectNames() {
    if (!SUBNAMES) {
      SUBNAMES = sb.select("subjects", { select: "slug,name", order: "sort" })
        .catch(function () { SUBNAMES = null; return []; });
    }
    return SUBNAMES;
  }
  function subFilter(list, keep) {
    var s = mySubs();
    if (!s.length) return list || [];
    var out = (list || []).filter(function (x) {
      return s.indexOf(x.slug) >= 0 || (keep && x.slug === keep);
    });
    return out.length ? out : (list || []);
  }
  /* Fenn nisanlari (toggle) - qurulus ve profil ekranlarinda */
  function subChips(boxId, selected) {
    sb.select("subjects", { select: "slug,name", order: "sort" })
      .then(function (rows) {
        var box = $(boxId);
        if (!box) return;
        box.innerHTML = (rows || []).map(function (s) {
          return '<button type="button" class="chip' +
            (selected.indexOf(s.slug) >= 0 ? " on" : "") +
            '" data-sub="' + esc(s.slug) + '">' + esc(s.name) + "</button>";
        }).join("");
        box.addEventListener("click", function (ev) {
          var b = ev.target.closest ? ev.target.closest("[data-sub]") : null;
          if (b) b.classList.toggle("on");
        });
      }).catch(function () {
        var box = $(boxId);
        if (box) box.innerHTML = "";
      });
  }
  function chipVals(boxId) {
    var out = [];
    Array.prototype.forEach.call(
      document.querySelectorAll("#" + boxId + " .chip.on"),
      function (b) { out.push(b.getAttribute("data-sub")); });
    return out;
  }

  function loadLevels() {
    if (LEVELS) return Promise.resolve(LEVELS);
    //  Sinif esasli seviyyeler (kod reqemdir: 1-11). MIQ/sertifikasiya
    //  pilleleri sinif deyil - bura dusmur.
    return sb.select("levels", { select: "id,code,name,program_id", order: "sort" })
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

  //  Qrupun sinif kodu (1-11) - generator suzgeci kodla isleyir,
  //  qrupda ise level_id (uuid) durur.
  function levelCode(id) {
    if (!id || !LEVELS) return "";
    var l = LEVELS.filter(function (x) { return x.id === id; })[0];
    return l ? l.code : "";
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

    var tops = (r.topics || []).filter(function (t) {
      //  1 cavabliq movzu valideyn mektubuna dusmesin - yaniltici olur
      return Number(t.total) >= 2;
    }).sort(function (a, b) {
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

  /* Faiz cipi - deyere gore reng: >=80 yasil, >=60 narinci, alti qirmizi */
  function pctChip(p) {
    var n = Number(p) || 0;
    var c = n >= 80 ? " pvh" : (n >= 60 ? " pvm" : " pvl");
    return '<span class="pctv' + c + '">' + pct(p) + "%</span>";
  }

  /* Siqnal setri - hem ana sehifede, hem bildirisler ekraninda */
  function alertRow(a) {
    var tx;
    if (a.kind === "risk") {
      tx = "son testlərdə geriləyir (" + pct(a.prev3) + "% → " +
           pct(a.last3) + "%)" + (a.topic ? " · zəif: " + esc(a.topic) : "");
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
        esc(a["class"] || "") + ")</span> " + tx + "</span>" +
      '<span class="arrow">' + ic("right") + "</span></button>";
  }
  function bindAlerts(box) {
    if (!box) return;
    Array.prototype.forEach.call(box.querySelectorAll("[data-al]"), function (b) {
      b.addEventListener("click", function () {
        nav("#/s/" + b.getAttribute("data-al") + "/" + b.getAttribute("data-g"));
      });
    });
  }

  function statTile(val, lbl, cls) {
    return '<div class="stat ' + (cls || "") + '"><b>' + esc(String(val)) +
      "</b><span>" + esc(lbl) + "</span></div>";
  }


  /* ================================================================
     DIAQNOSTIKA - "bu usaq neyi bilmir?"  (db/118_diaqnostika.sql)
     Sagird hesabatinin ustunde ayrica kart: yarat -> gozle -> xerite.
     Xerite pullu (hesabatdaki movzu analizi kimi), test yaratmaq da
     (platforma banki).  Sagirdin OZ xeritesi onun ekranindadir - pulsuz.
     ================================================================ */
  function loadDiag(id, classId) {
    var box = $("diagBox");
    if (!box) return;
    box.innerHTML = "<h2>Diaqnostika</h2>" +
      '<div class="card"><div class="skel">Yüklənir…</div></div>';
    Promise.all([
      sb.rpc("rpc_diagnostic_result",  { p_student_id: id, p_subject: null }),
      sb.rpc("rpc_diagnostic_options", { p_student_id: id })
    ]).then(function (rr) {
      if (!$("diagBox")) return;          //  ekran artiq deyisib
      drawDiag(id, classId, rr[0] || {}, rr[1] || {});
    }).catch(function (e) {
      var b = $("diagBox");
      if (b) b.innerHTML = "<h2>Diaqnostika</h2>" + msg("err", fail(e));
    });
  }

  var DST = { ok: ["st-ok", "yaxşı"], mid: ["st-mid", "orta"], weak: ["st-weak", "zəif"] };
  function dstChip(st) {
    var l = DST[st] || DST.weak;
    return '<span class="dst ' + l[0] + '">' + l[1] + "</span>";
  }
  //  Evvelki diaqnostika ile muqayise oxu
  function dprev(t) {
    if (!t.prev_status) return "";
    var rank = { weak: 0, mid: 1, ok: 2 };
    var a = rank[t.prev_status], b = rank[t.status];
    if (a === undefined || b === undefined || a === b) {
      return '<span class="dprev same" title="Əvvəlki kimi">=</span>';
    }
    return b > a ? '<span class="dprev up" title="Əvvəlkindən yaxşı">↑</span>'
                 : '<span class="dprev down" title="Əvvəlkindən pis">↓</span>';
  }

  function drawDiag(id, classId, d, o) {
    var box = $("diagBox");
    if (!box) return;
    var subs = o.subjects || [];
    var paid = !!(o.paid || d.paid);
    var h = "<h2>Diaqnostika</h2>";

    if (!o.level) {
      box.innerHTML = h + '<div class="card"><p class="muted" style="margin:0">' +
        esc(o.reason || "Qrupun sinfi seçilməyib.") + "</p></div>";
      return;
    }
    if (!paid) {
      box.innerHTML = h + '<div class="upsell">' + ic("star") + "<div><b>Diaqnostik test</b>" +
        "<span>Sinfin bütün mövzularından hər birinə 3 sual — «bu uşaq nəyi bilmir?» " +
        "sualına 40 dəqiqədə cavab. Platformanın sual bankından yığıldığı üçün abunə " +
        "paketində açılır.</span></div></div>";
      return;
    }

    /* ---- netice (varsa) ---- */
    if (d.has) {
      var tp = d.topics || [], st = d.start || [];
      h += '<div class="card tight">' +
        '<div class="dghead"><div><b>' + esc(d.test.title) + "</b>" +
          "<i>" + dateAz(d.taken_at) + " · " + d.score + " / " + d.max_score + " düzgün</i></div>" +
          pctChip(d.percent) + "</div>" +
        '<div class="dgsum">' +
          '<span class="dst st-weak">' + (d.weak_now || 0) + " zəif</span>" +
          '<span class="dst st-mid">'  + (d.mid_now  || 0) + " orta</span>" +
          '<span class="dst st-ok">'   + (d.ok_now   || 0) + " yaxşı</span>" +
          (d.weak_prev !== null && d.weak_prev !== undefined
            ? '<span class="dgdelta">əvvəlki (' + dateAz(d.prev_at) + "): " +
              d.weak_prev + " zəif → " + (d.weak_now || 0) + "</span>" : "") +
        "</div>" +
        (st.length
          ? '<div class="warn" style="margin:12px 0 0">' + ic("warn") +
            "<span>Bundan başla: <b>" + st.map(esc).join(", ") + "</b></span></div>"
          : '<div class="ok" style="margin:12px 0 0">' + ic("check") +
            "<span>Bütün mövzular yaxşıdır.</span></div>") +
        "</div>" +
        /*  Yaxsi movzular yigilmis: 12 setirlik xerite ekrani udurdu,
            asagida "Movzu uzre menimseme" de eyni movzulari sayirdi.
            "Zeif movzulardan test yig" duymesi de bir dene qaldi -
            asagidaki #btnRem butun testleri nezere alir.  */
        '<div style="margin-top:10px" id="dgMap">' +
          (function () {
            function row(t) {
              return '<div class="trow dgrow st-' + esc(t.status) + '"><div class="g"><b>' +
                esc(t.name) + "</b>" +
                "<i>" + t.correct + " / " + t.total + " düzgün</i>" + meter(t.ratio) + "</div>" +
                dprev(t) + dstChip(t.status) + "</div>";
            }
            var need = tp.filter(function (t) { return t.status !== "ok"; });
            var good = tp.filter(function (t) { return t.status === "ok"; });
            return (need.length ? '<div class="card pad0">' + need.map(row).join("") + "</div>" : "") +
              (good.length
                ? '<details class="more filt"' + (need.length ? "" : " open") +
                  (need.length ? ' style="margin-top:10px"' : "") + ">" +
                  "<summary>Yaxşı mövzular " + '<span class="fn">' + good.length + "</span></summary>" +
                  '<div class="card pad0" style="margin-top:10px">' + good.map(row).join("") + "</div></details>"
                : "");
          })() +
        "</div>";
    }

    /* ---- gozleyen / yaratmaq ---- */
    if (d.pending) {
      h += '<div class="card tight" style="margin-top:10px"><b>Gözlənilir: ' +
        esc(d.pending.title) + "</b>" +
        '<p class="muted" style="margin:4px 0 0">' + (d.pending.questions || 0) +
        " sual · son tarix " + dateAz(d.pending.closes_at) +
        ". Şagird yazan kimi mövzu xəritəsi burada görünəcək. " +
        '<a href="#/t/' + esc(d.pending.test_id) + '">Vərəqə bax</a></p></div>';
    } else {
      var opts = subs.map(function (s) {
        return '<option value="' + esc(s.slug) + '">' + esc(s.name) + " — " + s.topics +
          " mövzu" + (showBankN() ? " · " + s.questions + " sual" : "") + "</option>";
      }).join("");
      h += '<div class="card tight" style="margin-top:10px">' +
        "<b>" + (d.has ? "Yenidən diaqnostika" : "Diaqnostik test ver") + "</b>" +
        '<p class="muted" style="margin:4px 0 10px">' + esc(o.level.name) +
          " — bütün mövzulardan hər birinə 3 sual, bir cəhd, yalnız bu şagirdə. " +
          (d.has ? "Əvvəlki ilə fərq xəritədə görünəcək."
                 : "Nəticə — mövzu xəritəsi: nədən başlamalı.") + "</p>" +
        (subs.length
          ? '<label for="dgSub">Fənn</label><select id="dgSub">' + opts + "</select>" +
            '<label for="dgDays" style="margin-top:8px">Müddət</label><select id="dgDays">' +
              '<option value="7">7 gün</option><option value="14">14 gün</option>' +
              '<option value="30">30 gün</option></select>' +
            '<button class="btn go wide" id="dgGo" style="margin-top:12px">' + ic("gen") +
              "Diaqnostik test ver</button>" +
            '<div id="dgMsg"></div>'
          : '<p class="muted" style="margin:0">Bu sinif üçün sual bankında kifayət qədər mövzu yoxdur.</p>') +
        "</div>";
    }
    box.innerHTML = h;

    on("dgGo", "click", function () {
      if (busy) return;
      var sub  = ($("dgSub")  || {}).value || "";
      var days = Number(($("dgDays") || {}).value) || 7;
      setBusy("dgGo", true, "Diaqnostik test ver");
      sb.rpc("rpc_diagnostic_create", { p_student_id: id, p_subject: sub, p_days: days })
        .then(function (res) {
          busy = false;
          $("dgMsg").innerHTML = '<div class="ok" style="margin-top:10px">' + ic("check") +
            "<span>" + (res.existing
              ? "Açıq diaqnostika artıq var — şagird hələ yazmayıb. "
              : (Number(res.questions) || 0) + " sual, " + (Number(res.topics) || 0) +
                " mövzu — tapşırıq yalnız bu şagirdə verildi. ") +
            '<a href="#/t/' + esc(res.test_id) + '">Vərəqə bax</a></span></div>';
          setTimeout(function () { loadDiag(id, classId); }, 900);
        })
        .catch(function (e) {
          setBusy("dgGo", false, "Diaqnostik test ver");
          $("dgMsg").innerHTML = msg("err", fail(e));
        });
    });
  }

  var STAB = "x";   // sagird hesabatinda secilmis sekme (sessiya boyu)
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
        '<div class="card tight"><div class="shead">' + av(s.full_name) +
          "<div><h1>" + esc(s.full_name) + "</h1>" +
          '<div class="muted" style="display:flex;align-items:center;gap:7px;margin-top:6px">' +
            "<span>" + esc(s.display_name) + "</span>" +
            '<span class="code key">' + esc(s.login_code) + "</span></div>" +
          "</div>" +
          //  Tek bu sagirde hazir test: tapsiriq ekrani o secilmis acilir
          '<button class="btn sm sasg" id="btnAsgStu" title="Yalnız bu şagirdə hazır test tapşır">' +
            ic("plus") + "Test tapşır</button>" +
        "</div></div>" +
        '<div class="stats">' +
          statTile(sm.attempts || 0, "test", "g1") +
          statTile(pct(sm.avg) + "%", "orta", "g2") +
          statTile(pct(sm.best) + "%", "ən yaxşı", "g3") +
        "</div>";
      /*  Hesabat DORD SEKMEDE: Xulase / Movzular / Sehvler / Tarixce.
          Evvel hamisi bir uzun sehife idi - 8 testle 4000px; il erzinde
          sehvler ve movzular coxaldiqca hara gedeceyi bilinmirdi
          (istifadeci sualı).  Bir anda bir sekme gorunur, ilk ekran
          heç vaxt boyumur.  Secilmis sekme sessiya boyu yadda qalir.  */
      var minA = Number(r.min_answers) || 3;
      var tAll = r.topics || [];
      var tsure = tAll.filter(function (t) { return Number(t.total) >= minA; });
      var tlow  = tAll.filter(function (t) { return Number(t.total) < minA; });
      var sweakAll = tsure.filter(function (t) { return Number(t.ratio) < 60 && t.id; });
      var weak = (r.weak !== null && r.weak) ? r.weak : [];
      var at = r.attempts || [];

      /* ---------------- XULASE ---------------- */
      var hX = '<div id="diagBox"></div>';
      if (r.topics !== null) {
        hX += "<h2>Valideyn üçün xülasə</h2>" +
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

      /* ---------------- MOVZULAR ---------------- */
      var hM = "";
      //  fenn cipleri: muellimin oz fenni secili gelir, yoxsa "Hamisi"
      var subjs = [];
      tAll.forEach(function (t) {
        if (t.subject && !subjs.some(function (x) { return x.slug === t.subject_slug; })) {
          subjs.push({ slug: t.subject_slug || t.subject, name: t.subject });
        }
      });
      var mineSub = subjs.filter(function (x) { return mySubs().indexOf(x.slug) >= 0; });
      var TSUB = (subjs.length > 1 && mineSub.length === 1) ? mineSub[0].slug : "";
      var TCAP = 8, TEXP = false;
      if (r.topics === null) {
        hM += upsell("Mövzu üzrə mənimsəmə");
      } else if (!tAll.length) {
        hM += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("chart") +
             "</div><b>Hələ cavab yoxdur</b>Şagird test işlədikcə " +
             "mövzular burada yığılacaq.</div></div>";
      } else {
        hM += (subjs.length > 1
                ? '<div class="chips recf" id="tSub">' +
                  '<button class="chip' + (TSUB ? "" : " on") + '" data-ts="">Hamısı</button>' +
                  subjs.map(function (x) {
                    return '<button class="chip' + (TSUB === x.slug ? " on" : "") +
                      '" data-ts="' + esc(x.slug) + '">' + esc(x.name) + "</button>";
                  }).join("") + "</div>"
                : "") +
          '<div id="topicBox"></div>' +
          (sweakAll.length
            ? '<div class="spacer"></div>' +
              '<button class="btn go wide" id="btnRem">' + ic("gen") +
              "Zəif mövzulardan test yığ (" + sweakAll.length + ")</button>"
            : "");
      }
      function topicRow(t) {
        var bad = Number(t.ratio) < 60;
        return '<div class="trow"><div class="g"><b>' +
          (bad ? '<span class="wdot" title="Zəif mövzu"></span>' : "") +
          esc(t.name) + "</b>" +
          "<i>" + esc(t.subject) + " · " + t.correct + " / " + t.total + "</i>" +
          meter(t.ratio) + "</div>" +
          pctChip(t.ratio) + "</div>";
      }
      function drawTopics() {
        var box = $("topicBox");
        if (!box) return;
        function inSub(t) { return !TSUB || (t.subject_slug || t.subject) === TSUB; }
        var sure = tsure.filter(inSub).slice().sort(function (a, b) {
          return Number(a.ratio) - Number(b.ratio); });
        var low  = tlow.filter(inSub);
        var need = sure.filter(function (t) { return Number(t.ratio) < 80; });
        var good = sure.filter(function (t) { return Number(t.ratio) >= 80; });
        var vis  = TEXP ? need : need.slice(0, TCAP);
        var h2 = "";
        if (sure.length) {
          /*  Zeifden yaxsiya; yaxsi (>=80%) movzular yigilmis - muellime
              zeif olanlar lazimdir.  Uzun siyahi "Daha N" ile acilir.  */
          h2 += (need.length
                  ? '<div class="card pad0">' + vis.map(topicRow).join("") +
                    (need.length > vis.length
                      ? '<button class="morebtn" id="tMore">Daha ' +
                        (need.length - vis.length) + " mövzu göstər</button>"
                      : "") + "</div>"
                  : '<div class="ok">' + ic("check") +
                    "<span>Bütün mövzular yaxşıdır (≥80%).</span></div>") +
               (good.length
                  ? '<details class="more filt" style="margin-top:10px">' +
                    "<summary>Yaxşı mövzular " +
                      '<span class="fn">' + good.length + "</span></summary>" +
                    '<div class="card pad0" style="margin-top:10px">' +
                      good.map(topicRow).join("") + "</div></details>"
                  : "");
        } else {
          h2 += '<div class="card"><p class="muted" style="margin:0">Hər mövzu üzrə ' +
            "ən azı " + minA + " cavab yığılanda etibarlı mənzərə burada görünəcək. " +
            (low.length ? "İlkin cavablar aşağıdakı bölmədədir." : "") + "</p></div>";
        }
        if (low.length) {
          h2 += '<details class="more filt" style="margin-top:10px">' +
            "<summary>Az məlumatlı mövzular " +
              '<span class="fn">' + low.length + "</span></summary>" +
            '<div class="card pad0" style="margin-top:10px">' + low.map(function (t) {
              return '<div class="trow"><div class="g"><b>' + esc(t.name) + "</b>" +
                "<i>" + esc(t.subject) + " · " + t.correct + " / " + t.total +
                ' · <span class="lowtag">az məlumat</span></i></div>' +
                '<span class="pctv">' + pct(t.ratio) + "%</span></div>";
            }).join("") + "</div></details>";
        }
        box.innerHTML = h2;
        on("tMore", "click", function () { TEXP = true; drawTopics(); });
      }

      /* ---------------- SEHVLER ---------------- */
      var hS = "";
      if (r.weak === null) {
        hS += upsell("Səhv edilən suallar");
      } else if (!weak.length) {
        hS += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("check") +
          "</div><b>Səhv edilən sual yoxdur</b>Şagird səhv edəndə sual burada yığılır.</div></div>";
      } else {
        /* Sehv edilen suallar: HEREKET merkezi - duyme ustde, siyahi altda.
           Server en cox sehv edilen 10 suali verir (tekrar edilen birinci);
           ilk 5 acıq, qalani "Daha N" ile - sehife boyumesin. */
        var WCAP = 5;
        hS += '<button class="btn go wide" id="btnFix">' + ic("gen") +
            "Bu səhvlərdən təkrar testi yığ (" + weak.length + " sual)</button>" +
          '<div id="fixMsg"></div>' +
          '<details class="more filt wrongbox" open style="margin-top:10px">' +
          "<summary>Səhv edilən suallar " +
            '<span class="fn">' + weak.length + "</span>" +
            '<span class="muted" style="font-weight:400;margin-left:auto">ən çox səhv edilən ' +
              weak.length + "</span></summary>" +
          '<div class="card pad0" style="margin-top:10px" id="wList">' +
          weak.map(function (w, i) {
            return '<div class="wq' + (i >= WCAP ? " hide" : "") + '"><div class="g"><b>' +
              esc(w.body) + "</b>" +
              (w.topic ? '<span class="wtag">' + esc(w.topic) + "</span>" : "") +
              (w.explanation ? "<i>" + esc(w.explanation) + "</i>" : "") +
              //  "1x" her setirde menasiz idi - say yalniz tekrarda
              "</div>" + (Number(w.wrong) > 1
                ? '<span class="wn">' + w.wrong + "×</span>" : "") + "</div>";
          }).join("") +
          (weak.length > WCAP
            ? '<button class="morebtn" id="wMore">Daha ' + (weak.length - WCAP) + " sual göstər</button>"
            : "") +
          "</div></details>";
      }

      /* ---------------- TARIXCE ---------------- */
      var hT = "";
      /* Dinamika: kohneden yeniye, her sutun bir test.  Iki sutunluq
         qrafik hec ne demir - uc testden basliyir. */
      if (at.length >= 3) {
        var bars = at.slice(0, 12).slice().reverse();
        hT += '<div class="card"><div class="dyn">' + bars.map(function (a) {
            var p = Math.max(6, Math.round(Number(a.percent) || 0));
            var c = p >= 80 ? "dh" : (p >= 60 ? "dm" : "dl");
            return '<i class="' + c + '" style="height:' + p + '%" title="' +
              esc(a.test) + " · " + pct(a.percent) + '%"></i>';
          }).join("") + "</div>" +
          '<p class="muted" style="margin:10px 0 0">Soldan sağa: köhnədən ' +
            "yeniyə. Yaşıl ≥80%, narıncı 60-79%, qırmızı &lt;60%.</p></div>" +
          '<div class="spacer"></div>';
      }
      if (!at.length) {
        hT += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("clock") +
             "</div><b>Hələ test işləməyib</b></div></div>";
      } else {
        //  ilk 8 test acıq, qalani "Daha N" ile - il boyu 60 test sekmeni uzatmasin
        var ACAP = 8;
        hT += '<div class="card pad0" id="atList">' + at.map(function (a, i) {
          var hid = i >= ACAP ? " hide" : "";
          return '<button class="trow atr' + hid + '" data-att="' + esc(a.id) + '">' +
            '<div class="g"><b>' + esc(a.test) + "</b>" +
            "<i>" + dateAz(a.at) + " · " + a.score + " / " + a.max +
            ' · <span class="lnk2">cavab vərəqi</span></i></div>' +
            pctChip(a.percent) + "</button>" +
            '<div class="sheet hide' + (hid ? " late" : "") + '" id="sh-' + esc(a.id) + '"></div>';
        }).join("") +
        (at.length > ACAP
          ? '<button class="morebtn" id="atMore">Daha ' + (at.length - ACAP) + " test göstər</button>"
          : "") + "</div>";
      }

      /* ---------------- sekmeler ---------------- */
      var nWeakT = tsure.filter(function (t) { return Number(t.ratio) < 60; }).length;
      function tabLbl(t, n) {
        return t + (n ? ' <span class="tn">' + n + "</span>" : "");
      }
      h += '<div class="segs stabs" id="sTabs">' +
          seg("x", "Xülasə", STAB) +
          seg("m", tabLbl("Mövzular", nWeakT), STAB) +
          seg("s", tabLbl("Səhvlər", weak.length), STAB) +
          seg("t", tabLbl("Tarixçə", at.length), STAB) +
        "</div>" +
        '<div class="stab" id="tab-x"' + (STAB === "x" ? "" : " hidden") + ">" + hX + "</div>" +
        '<div class="stab" id="tab-m"' + (STAB === "m" ? "" : " hidden") + ">" + hM + "</div>" +
        '<div class="stab" id="tab-s"' + (STAB === "s" ? "" : " hidden") + ">" + hS + "</div>" +
        '<div class="stab" id="tab-t"' + (STAB === "t" ? "" : " hidden") + ">" + hT + "</div>";

      show(h);
      loadDiag(id, classId);
      drawTopics();
      on("sTabs", "click", function (e) {
        var b = e.target.closest ? e.target.closest("[data-v]") : null;
        if (!b) return;
        STAB = b.getAttribute("data-v");
        Array.prototype.forEach.call(document.querySelectorAll("#sTabs .seg"), function (x) {
          x.classList.toggle("on", x.getAttribute("data-v") === STAB);
        });
        Array.prototype.forEach.call(document.querySelectorAll(".stab"), function (x) {
          x.hidden = x.id !== "tab-" + STAB;
        });
      });
      on("tSub", "click", function (e) {
        var b = e.target.closest ? e.target.closest("[data-ts]") : null;
        if (!b) return;
        TSUB = b.getAttribute("data-ts"); TEXP = false;
        Array.prototype.forEach.call(document.querySelectorAll("#tSub .chip"), function (x) {
          x.classList.toggle("on", x === b);
        });
        drawTopics();
      });
      on("atMore", "click", function () {
        Array.prototype.forEach.call(document.querySelectorAll("#atList .atr.hide"), function (x) {
          x.classList.remove("hide");
        });
        $("atMore").remove();
      });
      on("wMore", "click", function () {
        Array.prototype.forEach.call(document.querySelectorAll("#wList .wq.hide"), function (x) {
          x.classList.remove("hide");
        });
        $("wMore").remove();
      });
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
      //  Qrup ekranindan gelibse ora, yoxsa qrup hesabatina (canli sual:
      //  "Geri" qrupa yox, hesabata atirdi)
      on("btnB", "click", function () {
        nav(PREV_HASH === "#/g/" + classId ? PREV_HASH : "#/r/" + classId);
      });
      on("btnAsgStu", "click", function () { nav("#/a/" + classId + "/" + id); });
      on("btnRem", "click", function () { remedialGen(classId, sweakAll); });

      //  Sehvler uzerinde is: mehz sehv edilen suallardan ferdi test
      on("btnFix", "click", function () {
        if (busy) return;
        setBusy("btnFix", true, "Bu səhvlərdən təkrar testi yığ");
        sb.rpc("rpc_remedial_test", { p_student_id: id, p_count: 10 })
          .then(function (res) {
            setBusy("btnFix", false, "Bu səhvlərdən təkrar testi yığ");
            //  msg() metni esc edir - linki ozumuz yigiriq
            $("fixMsg").innerHTML = '<div class="ok" style="margin-top:10px">' +
              ic("check") + "<span>" + (Number(res.count) || 0) +
              " sualdan test yığıldı və tapşırıq YALNIZ bu şagirdə verildi " +
              "— qrupun qalanı onu görmür. " +
              '<a href="#/t/' + esc(res.test_id) + '">Vərəqə bax</a></span></div>';
          })
          .catch(function (e) {
            setBusy("btnFix", false, "Bu səhvlərdən təkrar testi yığ");
            $("fixMsg").innerHTML = msg("err", fail(e));
          });
      });

      //  Cavab vereqi: setre klik - acilir/baglanir, ilk aciliska yuklenir
      var atl = $("atList");
      if (atl) atl.addEventListener("click", function (ev) {
        var b = ev.target.closest ? ev.target.closest("[data-att]") : null;
        if (!b) return;
        var box = $("sh-" + b.getAttribute("data-att"));
        if (!box) return;
        if (!box.classList.contains("hide")) { box.classList.add("hide"); return; }
        box.classList.remove("hide");
        if (box.dataset.done) return;
        box.innerHTML = '<div class="skel" style="padding:12px 16px">Yüklənir…</div>';
        sb.rpc("rpc_attempt_sheet", { p_attempt_id: b.getAttribute("data-att") })
          .then(function (s) {
            box.dataset.done = "1";
            box.innerHTML = (s.items || []).map(function (q) {
              return '<div class="shq">' +
                "<b>" + q.ord + ". " + esc(q.body) + "</b>" +
                '<div class="sa">' +
                  '<span class="' + (q.ok ? "sc" : "sw") + '">Cavabı: ' +
                    esc(q.chosen) + "</span>" +
                  (q.ok ? "" : '<span class="sc">Düzü: ' + esc(q.correct) + "</span>") +
                "</div>" +
                (!q.ok && q.explanation
                  ? '<i class="sex">' + esc(q.explanation) + "</i>" : "") +
              "</div>";
            }).join("");
          })
          .catch(function (e) {
            box.innerHTML = '<div style="padding:10px 16px">' +
              msg("err", fail(e)) + "</div>";
          });
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
  /*  ASG_PRE: sagird hesabatindan "Test tapsir" ile gelende hemin
      sagird "Kime" secimində evvelceden secilir, Geri ora qaytarir.  */
  var ASG_PRE = "";
  var ASG_FLASH = null;   // son verilen tapsiriq - bir defelik WhatsApp qutusu
  var PREV_HASH = "", CUR_HASH = "";   // route() doldurur
  function screenAssign(gid, sid) {
    var live = guard();
    ASG_PRE = sid || "";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    Promise.all([
      sb.select("classes", { select: "id,name,level_id", eq: { id: gid } }),
      sb.rpc("rpc_class_assignments", { p_class_id: gid }),
      loadLevels(),
      //  "kime" secimi ucun qrupun aktiv sagirdleri
      sb.select("students", {
        select: "id,full_name",
        eq: { class_id: gid, is_active: true },
        order: "full_name"
      }).catch(function () { return []; })
    ]).then(function (res) {
      if (!live()) return;
      var rows = res[0];
      if (!rows || !rows.length) throw new Error("Qrup tapılmadı.");
      drawAssign(rows[0], res[1] || {}, res[3] || []);
      if (ASG_PRE) {
        var pk = $("pick");
        if (pk && pk.scrollIntoView) pk.scrollIntoView({ block: "start" });
      }
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  function drawAssign(g, d, students) {
    topTitle.textContent = g.name;
    var items = d.items || [];
    var free  = d.free_practice !== false;

    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") +
        (ASG_PRE ? "Şagird hesabatı" : esc(g.name)) + "</button>" +
      '<div class="spacer"></div>' +
      '<div class="card tight">' +
        "<h1>Tapşırıqlar</h1>" +
        '<p class="muted" style="margin:8px 0 0">Şagird tapşırığı öz ' +
          "siyahısında görür; son tarix keçəndə bağlanır.</p>" +
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
      (ASG_FLASH ? '<div id="asgFlash">' + asgShareBox(ASG_FLASH.title, ASG_FLASH.closes, ASG_FLASH.who) + "</div>" : "") +
      '<div class="segs asgf" id="asgTabs"></div>' +
      '<div id="asgList" class="card pad0"></div>' +
      '<div class="spacer"></div>' +
      /*  "Yeni tapsiriq" yeni test yaratmaq kimi oxunurdu (canli sual).
          Burada hazir test secilib qrupa verilir - basliq ve bir cumle
          bunu deyir.  */
      "<h2>Hazır testi tapşır</h2>" +
      '<p class="muted" style="margin:-6px 0 10px">Hazır testi seçin, kimə və nə vaxta ' +
        "qədər — şagirdin siyahısına düşür. Eyni test bir neçə qrupa verilə bilər.</p>" +
      '<div id="pick" class="card"><div class="skel">Testlər yüklənir…</div></div>' +
      '<div class="spacer"></div>' +
      /* Bu ekran test YARATMIR - hazir testi qrupa yoneldir.
         Muellimler bunu qarisdirirdi: siyahida yalniz kohneler
         gorunurdu, yenisini haradan yigmagi ekran demirdi. */
      '<div class="card tight">' +
        '<p class="muted" style="margin:0 0 12px">Uyğun test yoxdursa ' +
          "yenisini yığın — hazır olan kimi bura qayıdıb seçilmiş gələcək.</p>" +
        '<button class="btn wide" id="btnGenHere">' + ic("gen") +
          "Yeni test yığ</button>" +
      "</div>"
    );

    ASG_FLASH = null;
    bindWaCopy($("asgFlash"));
    on("btnBack", "click", function () {
      nav(ASG_PRE ? "#/s/" + ASG_PRE + "/" + g.id : "#/g/" + g.id);
    });
    on("btnGenHere", "click", function () { genForClass(g); });
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

    /* Aktiv/Bagli tablari - kohne tapsiriqlar aktivlere qarismasin */
    var AF = "on";
    function drawAsgList() {
      var tabs = $("asgTabs"), box = $("asgList");
      var nOn = items.filter(function (a) { return a.open !== false; }).length;
      if (tabs) tabs.innerHTML =
        seg("on", "Aktiv (" + nOn + ")", AF) +
        seg("off", "Bağlı (" + (items.length - nOn) + ")", AF);
      if (box) box.innerHTML = asgRows(items, d.students || 0, AF);
      on("asgMore", "click", function () { AEXP = true; drawAsgList(); });
    }
    AEXP = false;
    drawAsgList();
    on("asgTabs", "click", function (ev) {
      var b = ev.target.closest ? ev.target.closest(".seg") : null;
      if (!b) return;
      AF = b.getAttribute("data-v");
      drawAsgList();
    });

    bindAsgRows(g);
    loadPick(g, students || []);
  }

  function asgRows(items, students, f) {
    if (!items.length) {
      return '<div class="empty"><div class="ic">' + ic("clip") + "</div>" +
        "<b>Hələ tapşırıq verilməyib</b>" +
        "Aşağıdan test seçin — şagirdlər dərhal görəcək.</div>";
    }
    var list = !f ? items : items.filter(function (a) {
      return f === "off" ? a.open === false : a.open !== false;
    });
    if (!list.length) {
      return '<div class="empty"><div class="ic">' + ic("clip") + "</div>" +
        "<b>" + (f === "off" ? "Bağlı tapşırıq yoxdur" : "Aktiv tapşırıq yoxdur") +
        "</b>" +
        (f === "off"
          ? "Son tarixi keçən və götürülən tapşırıqlar bura düşür."
          : "Aşağıdan test seçib tapşırıq verin.") + "</div>";
    }
    //  "Bagli" il boyu boyuyur: ilk 8 + "Daha N" (AEXP acanda hamisi)
    var ACAP2 = 8;
    var full = list.length > ACAP2 && !AEXP && f === "off";
    var shown = full ? list.slice(0, ACAP2) : list;
    return shown.map(function (a) {
      var open = a.open !== false;
      var done = Number(a.done) || 0;
      var tries = Number(a.max_attempts) === 0 ? "limitsiz cəhd"
                : (Number(a.max_attempts) || 1) + " cəhd";
      //  Ferdi teyinatda mexrec 1-dir - "0/5 sagird bitirib" yanlis olardi
      var solo = !!a.student_id;
      var tot  = Number(a.targets) || (solo ? 1 : students);
      return '<div class="asg">' +
        '<div class="l1"><b>' + esc(a.title) + "</b>" +
          (solo
            ? '<span class="pill solo">' + ic("person") +
              "yalnız " + esc(a.student || "bir şagird") + "</span>"
            : "") +
          '<span class="pill' + (open ? " on" : "") + '">' +
            (open ? "Aktiv" : "Bağlı") + "</span>" +
          '<button class="btn sm ghost icon" data-del="' + esc(a.id) + '" ' +
            'title="Tapşırığı götür" aria-label="Tapşırığı götür">' + ic("x") + "</button>" +
        "</div>" +
        '<div class="l2">' + esc(a.subject || "") + " · " +
          (Number(a.questions) || 0) + " sual · " + tries +
          (a.closes_at ? " · son tarix " + dateAz(a.closes_at) : "") + "</div>" +
        '<div class="l2">' + done + "/" + tot + " şagird bitirib" +
          (a.avg != null ? " · orta " + pct(a.avg) + "%" : "") + "</div>" +
      "</div>";
    }).join("") +
    (full
      ? '<button class="morebtn" id="asgMore">Daha ' + (list.length - ACAP2) + " tapşırıq göstər</button>"
      : "");
  }
  var AEXP = false;   // "Bagli" siyahisi tam acilib

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

  /* ---------------------------------------------- yeni test -> geri
     Tapsiriq ekranindan "Yeni test yig" basilanda generatora kecirik,
     amma hara qayidacagimizi yadda saxlayiriq (GF.back).  Test hazir
     olanda hemin qrupun tapsiriq ekrani acilir ve teze test siyahida
     SECILMIS gelir - muellim yalniz son tarixi qoyub gonderir.
     PICKNEW bir defelikdir: ekran cizilen kimi silinir. */
  var PICKNEW = "";

  function genForClass(g) {
    var f = genFilter();
    //  Teze suzgec - kohne secimler yeni qrupa yapismasin
    f.subject = ""; f.topics = []; f.difficulty = [];
    f.title = ""; f.cls = ""; f.remNames = [];
    //  Teyinati generator DEYIL, tapsiriq ekrani verecek: orada son
    //  tarix, cehd sayi ve "tek sagird" secimi var.
    f.asg = "";
    //  Qrupun sinfi susmaya secili gelir; muellim istese asagi
    //  sinifleri de elave edir (cox secim).
    var kod = levelCode(g.level_id);
    f.levels = kod ? [kod] : [];
    f.back = g.id;
    f.backName = g.name || "";
    nav("#/gen");
  }

  /* Teyin edile bilen testler: sinife uygun olanlar */
  function loadPick(g, students) {
    var live = guard();
    Promise.all([
      sb.rpc("rpc_available_tests", { p_class_id: g.id }),
      //  basqa qrupdaki teyinatlar - "verilib" nisani ucun
      sb.select("assignments", { select: "test_id,class_id" })
        .catch(function () { return []; }),
      subjectNames()
    ]).then(function (res) {
      if (!live()) return;
      var box = $("pick");
      if (!box) return;
      var list = res[0] || [];
      /*  Muellimin OZ fenni birinci: riyaziyyat muellimine siyahi
          "Azerbaycan dili - 1" ile acilirdi (UX yoxlamasi).  Sira
          sabitdir - eyni fennin icinde kohne sira qalir.  */
      var myNames = (res[2] || []).filter(function (x) {
        return mySubs().indexOf(x.slug) >= 0;
      }).map(function (x) { return x.name; });
      if (myNames.length) {
        list = list.map(function (t, i) { return { t: t, i: i }; }).sort(function (a, b) {
          var am = myNames.indexOf(String(a.t.subject || "")) >= 0 ? 0 : 1;
          var bm = myNames.indexOf(String(b.t.subject || "")) >= 0 ? 0 : 1;
          return am - bm || a.i - b.i;
        }).map(function (x) { return x.t; });
      }
      var elsew = {};
      (res[1] || []).forEach(function (a) {
        if (a.class_id !== g.id) elsew[a.test_id] = true;
      });
      //  "assigned" indi yalniz QRUP teyinatini bildirir; yalniz
      //  ferdi verilmis test siyahida qalir - basqa sagirde de olar
      var free = list.filter(function (t) { return !t.assigned; });
      //  "sehvler uzerinde is" sexsi testdir - oz qrupundan basqa yerde
      //  teklif olunmur (yanlis istifadenin qarsisi)
      free = free.filter(function (t) {
        return !(elsew[t.id] &&
                 String(t.title || "").indexOf("səhvlər üzərində iş") >= 0);
      });

      /* Generatordan teze qayitmisiqsa - bildiris ve secim.
         Bir defelikdir: burada oxuyub derhal silirik. */
      var neu = PICKNEW; PICKNEW = "";
      var isNew = neu && free.filter(function (t) { return t.id === neu; }).length > 0;
      var note = "";
      if (neu) {
        note = isNew
          ? msg("ok", "Test yığıldı və aşağıda seçildi — son tarixi " +
                      "təyin edib «Tapşırıq ver» düyməsini basın.")
          //  Asagi sinifler artiq KECIR (db/112).  Siyahiya dusmeyen
          //  test yalniz YUXARI sinif ucun yigilmis ola biler.
          : msg("warn", "Test yığıldı, amma bu siyahıya düşmür — " +
                        "qrupun sinfindən YUXARI sinif üçün yığılıb. " +
                        "Aşağı siniflər olar, yuxarı yox: generatorda " +
                        "sinfi düzəldin və ya qrupun sinfini dəyişin.");
      }
      /* Iki ayri hal - eyni mesaji vermek olmaz:
         siyahi tamam bosdursa bu sinif ucun hele test YAZILMAYIB. */
      if (!list.length) {
        box.innerHTML = note + '<div class="empty"><div class="ic">' + ic("doc") + "</div>" +
          "<b>Bu sinif üçün hələ test yoxdur</b>" +
          "Test bazasına " + esc(levelName(g.level_id) || "bu sinif") +
          " materialları hələ əlavə olunmayıb. Qrupun sinfini dəyişsəniz " +
          "(yuxarıdakı qələm düyməsi) mövcud testlər açılacaq.</div>";
        return;
      }
      if (!free.length) {
        box.innerHTML = note + '<div class="empty"><div class="ic">' + ic("check") + "</div>" +
          "<b>Bütün testlər verilib</b>Bu sinif üçün başqa test qalmayıb.</div>";
        return;
      }
      function optOf(t) {
        /* Testin adi onsuz da fennle baslayirsa fenni tekrar yazmiriq:
           "Azerbaycan dili - Azerbaycan dili - 1" cirkin cixirdi. */
        var sub = String(t.subject || "");
        var ttl = String(t.title || "");
        var lbl = (sub && ttl.indexOf(sub) !== 0) ? sub + " — " + ttl : ttl;
        /*  Siyahida ASAGI sinif testleri de var - hansi sinif ucun
            yigildigi GORUNMELIDIR.  Qrupun oz sinfi tekrarlanmir.  */
        var lv = String(t.level || "");
        if (lv && lv !== (levelName(g.level_id) || "")) lbl += " · " + lv;
        return '<option value="' + esc(t.id) + '">' + esc(lbl) +
          " (" + (Number(t.questions) || 0) + " sual)" +
          (t.is_free ? "" : " · abunə") +
          (elsew[t.id] ? " · başqa qrupa da verilib" : "") + "</option>";
      }
      /*  Siyahi uc bolmede: bu sinfin platforma testleri, muellimin oz
          testleri, asagi sinifler.  Evvel hamisi bir yerde idi - 8-ci
          sinif riyaziyyat qrupu ucun ilk setir "Azerbaycan dili - 5-ci
          sinif" cixirdi (canli sual).  Bolme bosdursa gorunmur.  */
      var gl = levelName(g.level_id) || "";
      var own = free.filter(function (t) { return t.mine; });
      var here = free.filter(function (t) { return !t.mine && (!gl || String(t.level || "") === gl); });
      var lower = free.filter(function (t) { return !t.mine && gl && String(t.level || "") !== gl; });
      function grp(label, list) {
        return list.length
          ? '<optgroup label="' + esc(label) + '">' + list.map(optOf).join("") + "</optgroup>"
          : "";
      }
      box.innerHTML = note +
        '<label for="aTest">Test</label>' +
        '<select id="aTest">' +
          grp(gl ? "Platforma · " + gl : "Platforma", here) +
          grp("Öz testləriniz", own) +
          grp("Aşağı siniflər", lower) +
        "</select>" +
        //  Kime: butun qrup (kohne davranis) ve ya tek sagird
        (students.length
          ? '<label for="aWho">Kimə</label>' +
            '<select id="aWho"><option value="">Bütün qrup (' +
              students.length + " şagird)</option>" +
              students.map(function (st) {
                return '<option value="' + esc(st.id) + '">yalnız ' +
                  esc(st.full_name || "") + "</option>";
              }).join("") + "</select>"
          : "") +
        '<div class="fieldrow">' +
          '<div><label for="aDate">Son tarix</label>' +
            '<input type="date" id="aDate"></div>' +
          '<div style="flex:0 0 148px"><label for="aTry">Cəhd sayı</label>' +
            '<select id="aTry"><option value="1">1 cəhd</option>' +
              '<option value="2">2 cəhd</option><option value="3">3 cəhd</option>' +
              '<option value="0">Limitsiz</option></select></div>' +
        "</div>" +
        //  Bes ayri izah bir cumleye yigildi (UX yoxlamasi): asagi sinif
        //  testleri siyahida " · 2-ci sinif" nisani ile onsuz da gorunur
        '<p class="muted" style="margin:-8px 0 14px">Son tarix boş qalsa, ' +
          "tapşırıq siz götürənə qədər açıq qalır" +
          (students.length ? "; tək şagird seçsəniz onu yalnız o görəcək." : ".") + "</p>" +
        '<div id="aErr"></div>' +
        '<button class="btn go" id="btnAsg">' + ic("plus") + "Tapşırıq ver</button>";
      if (isNew && $("aTest")) $("aTest").value = neu;
      //  sagird hesabatindan gelib: hemin sagird secili, yazi ile
      if (ASG_PRE && $("aWho")) {
        $("aWho").value = ASG_PRE;
        var pre = students.filter(function (st) { return st.id === ASG_PRE; })[0];
        if ($("aWho").value === ASG_PRE && pre) {
          $("aErr").innerHTML = msg("ok", "Yalnız " + (pre.full_name || "bu şagird") +
            " üçün — testi seçin, «Tapşırıq ver» basın.");
        }
      }
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
    var selT = $("aTest"), selW = $("aWho");
    var ttl = selT && selT.selectedIndex >= 0 ? selT.options[selT.selectedIndex].text : "Test";
    var whoName = selW && selW.value && selW.selectedIndex >= 0
      ? selW.options[selW.selectedIndex].text.replace(/^yalnız\s+/, "") : "";
    sb.rpc("rpc_assign_test", {
      p_class_id: g.id, p_test_id: tid,
      p_closes_at: closes, p_max_attempts: Number(($("aTry") || {}).value || 1),
      //  bos = butun qrup
      p_student_id: (selW && selW.value) || null
    }).then(function (r) {
      ASG_FLASH = { title: (r && r.test) || ttl.replace(/\s+\(\d+ sual\)$/, ""), closes: closes, who: whoName };
      screenAssign(g.id, ASG_PRE);
    })
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
  //  Paket bolmesi hazirda gizlidir - config.js-deki SHOW_PLANS acir.
  function plansOn() {
    return !!(window.CFG && window.CFG.SHOW_PLANS);
  }

  function isAdmin() {
    return !!(CTX && CTX.roles && CTX.roles.indexOf("admin") >= 0);
  }
  /*  Bankin HECMI (nece min sual, fenn/sinif/movzu basina say) yalniz
      adminə gorunur.  Adi muellime is ucun lazim deyil, reqibe ise
      bankin olcusunu ve zeif fenni bir baxisda gosterirdi (istifadeci
      qerari).  Testin oz sual sayi ("6 sual", "36 sual") her yerde qalir.  */
  function showBankN() { return isAdmin(); }

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
        sb.rpc("rpc_admin_reports", { p_status: "new" }),
        sb.rpc("rpc_admin_feedback", { p_status: "new" })
      ]).then(function (r) {
        if (!live()) return;
        drawAdmin(r[0] || {}, r[1] || [], r[2] || [], r[3] || []);
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

  function drawAdmin(st, rows, reps, fbs) {
    var plans = (st.plans && st.plans.length) ? st.plans
      : [{ slug: "repetitor-25", name: "Repetitor — 25 şagird" }];
    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") + "Əsas səhifə</button>" +
      '<div class="spacer"></div>' +
      '<div class="tiles five">' +
        '<div class="tile a"><b>' + (st.accounts || 0) + "</b><span>hesab" +
          ((st.accounts_week || 0) > 0 ? " · +" + st.accounts_week + " bu həftə" : "") +
          "</span></div>" +
        '<div class="tile b"><b>' + (st.paid_accounts || 0) + "</b><span>pullu · " +
          Math.max(0, (st.accounts || 0) - (st.paid_accounts || 0)) + " pulsuz</span></div>" +
        '<div class="tile c"><b>' + azn(st.mrr_minor || 0) + "</b><span>aylıq gəlir</span></div>" +
        '<div class="tile d"><b>' + (st.attempts_week || 0) + "</b><span>cəhd · son 7 gün</span></div>" +
        '<div class="tile e"><b>' + (st.seen_week || 0) + "</b><span>girib · son 7 gün</span></div>" +
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
           ["bitir", "Bitmək üzrə"], ["girmir", "Girməyənlər"]]
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
      '<h2 id="fbH">Bizə yazılanlar' + (fbs.length
        ? ' <span class="rcnt">' + fbs.length + "</span>" : "") + "</h2>" +
      '<div class="chips" id="fbF">' +
        [["new", "Yeni"], ["seen", "Baxılıb"], ["planned", "Planda"],
         ["done", "Edilib"], ["closed", "Bağlı"], ["all", "Hamısı"]].map(function (f) {
          return '<button class="chip' + (f[0] === "new" ? " on" : "") +
            '" data-fs="' + f[0] + '">' + f[1] + "</button>";
        }).join("") +
      "</div>" +
      '<div id="fbList">' + fbCards(fbs, "new") + "</div>" +
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
    on("fbF", "click", function (ev) {
      var b = ev.target.closest ? ev.target.closest(".chip") : null;
      if (!b) return;
      var cur = document.querySelector("#fbF .chip.on");
      if (cur) cur.classList.remove("on");
      b.classList.add("on");
      var st2 = b.getAttribute("data-fs");
      sb.rpc("rpc_admin_feedback", { p_status: st2 }).then(function (r) {
        var box = $("fbList");
        if (box) box.innerHTML = fbCards(r || [], st2);
      }).catch(function () {});
    });
    on("fbList", "click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("[data-fbsave]") : null;
      if (!b || busy) return;
      var id = b.getAttribute("data-fbsave");
      var card = b.closest(".fbc");
      var sel = card.querySelector("select"), ta = card.querySelector("textarea");
      var m = card.querySelector(".fbcm");
      busy = true; b.disabled = true;
      sb.rpc("rpc_admin_feedback_set", {
        p_id: id, p_status: sel.value, p_note: (ta.value || "").trim() || null
      }).then(function () {
        busy = false; b.disabled = false;
        card.classList.add("saved");
        m.innerHTML = msg("ok", "Yadda saxlanıldı" +
          (ta.value.trim() ? " — müəllim cavabı profilində görəcək." : "."));
        var cur = document.querySelector("#fbF .chip.on");
        var fs = cur ? cur.getAttribute("data-fs") : "new";
        if (fs !== "all" && fs !== sel.value) {
          setTimeout(function () {
            card.remove();
            var h = $("fbH"), left = document.querySelectorAll("#fbList .fbc").length;
            if (h && fs === "new") {
              h.innerHTML = "Bizə yazılanlar" + (left ? ' <span class="rcnt">' + left + "</span>" : "");
            }
            if (!left) $("fbList").innerHTML = fbCards([], fs);
          }, 900);
        }
      }).catch(function (e) {
        busy = false; b.disabled = false;
        m.innerHTML = msg("err", fail(e));
      });
    });
  }

  /* «Bizə yazılanlar» kartlari: kim · nov · sehife · tarix, metn,
     status + cavab qeydi.  Cavab muellimin profilinde gorunur. */
  function fbCards(rows, st) {
    if (!rows.length) {
      return '<div class="card"><p class="muted" style="margin:0">' +
        (st === "new" ? "Yeni müraciət yoxdur. 👌" : "Bu siyahı boşdur.") + "</p></div>";
    }
    var AT = { teacher: "müəllim", student: "şagird", parent: "valideyn" };
    return rows.map(function (r) {
      var meta = [AT[r.author_type] || r.author_type];
      if (r.author_type === "teacher" && r.account) meta.push(r.account);
      if (r.author_type === "teacher" && r.email) meta.push(r.email);
      if (r.author_type !== "teacher" && r.account) meta.push(r.account);
      if (r["class"]) meta.push(r["class"]);
      if (r.page) meta.push("ekran: " + r.page);
      return '<div class="card fbc" data-id="' + esc(r.id) + '">' +
        '<div class="fbh"><span class="pill on">' + esc(fbKind(r.kind)) + "</span>" +
          "<b>" + esc(r.who || "") + "</b>" +
          '<span class="fbat">' + dateAz(r.at) + "</span></div>" +
        '<div class="qm">' + meta.map(function (x) { return "<span>" + esc(x) + "</span>"; })
          .join("<span>·</span>") + "</div>" +
        '<p class="fbb">' + esc(r.body) + "</p>" +
        '<div class="fbact">' +
          "<select>" + Object.keys(FB_ST).map(function (k) {
            return '<option value="' + k + '"' + (k === r.status ? " selected" : "") + ">" +
              FB_ST[k] + "</option>";
          }).join("") + "</select>" +
          '<textarea rows="2" maxlength="1000" placeholder="Cavab (müəllim profilində görür)">' +
            esc(r.note || "") + "</textarea>" +
          '<button class="btn sm" data-fbsave="' + esc(r.id) + '">Yadda saxla</button>' +
        "</div>" +
        '<div class="fbcm"></div>' +
      "</div>";
    }).join("");
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
          "<span>aktivlik: " + whenAz(a.last_active) + "</span>" +
        "</i>" +
        //  Girisler: muellim paneli ne vaxt acib, sagird/valideyn kodla ne vaxt girib.
        //  7 gundur girmeyen muellim narinci - pilotda zeng etmek vaxtidir.
        '<i class="lg">' +
          '<span class="' + (seenCls(a.last_login)) + '">müəllim girişi: ' + whenAz(a.last_login) + "</span>" +
          "<span>·</span><span>şagird girişi: " + whenAz(a.student_login) + "</span>" +
        "</i></div>" +
        '<div class="btns">' +
          '<button class="btn sm" data-m="1">+1 ay</button>' +
          '<button class="btn sm" data-m="6">+6 ay</button>' +
          (pl ? '<button class="btn sm ghost" data-stop="1">Dayandır</button>' : "") +
        "</div></div>";
    }).join("");
  }

  /* Giris vaxti saatla: "bu gun 14:32", "dunen 09:10"; 2 gunden kohne
     yalniz gun (saat artiq menasizdir) */
  function whenAz(iso) {
    var t = agoAz(iso);
    if (!iso) return t;
    var d = new Date(iso);
    if (isNaN(d) || (Date.now() - d.getTime()) > 2 * 86400000) return t;
    var hh = d.getHours(), mm = d.getMinutes();
    return t + " " + (hh < 10 ? "0" : "") + hh + ":" + (mm < 10 ? "0" : "") + mm;
  }
  function seenCls(iso) {
    if (!iso) return "lg-no";
    var g = (Date.now() - new Date(iso).getTime()) / 86400000;
    return g > 7 ? "lg-old" : "lg-ok";
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
                    subject: "",
                    //  COX SECIM: muellim 8 ve 7-ni birlikde secе bilir.
                    //  Bos = sinif suzgeci yoxdur (butun sinifler).
                    levels: [], topics: [], difficulty: [],
                    count: 10, title: "", asg: "",
                    cls: "", remNames: [],
                    //  tapsiriq ekranindan gelmisiksa hara qayidaq
                    back: "", backName: "" };
    return GF;
  }

  //  Sinif kodundan adi - generatorun oz FAC siyahisindan
  function levelNameByCode2(code) {
    var l = (FAC.levels || []).filter(function (x) { return x.code === code; })[0];
    //  hovuzda o sinifden sual yoxdursa FAC-da da yoxdur - umumi kesden al
    if (!l) l = (LEVELS || []).filter(function (x) { return x.code === code; })[0];
    return l ? l.name : code;
  }

  /*  FAC hazirda hansi suzgec ucun yuklenib.  Iki isi gorur:
      - eyni suzgec ucun ikinci defe server sorgusu getmir;
      - suzgec deyisib, cavab hele gelmeyibse KOHNE movzu nisanlari
        yanlis sinifle gosterilmir.  */
  var GFKEY = null;
  var GFSEQ = 0;

  function genFacKey(f) {
    return (f.pool || "") + "|" + (f.subject || "") + "|" +
           (f.levels.length === 1 ? f.levels[0] : "");
  }

  /*  Suzgeci FONDA yenileyir: ekran silinmir, "Yuklenir" skeleti
      cixmir, surusme yerinde qalir.  Evvel her sinif klikinde
      screenGen() cagirilirdi - butun forma sokulub yeniden qurulurdu
      ve sehife basa qacirdi.  Cavab gelende genRefresh() yalniz
      deyisen hisseleri yerinde tezeleyir.  */
  function genFacets() {
    var f = genFilter();
    var key = genFacKey(f);
    if (key === GFKEY) return;
    var live = guard();
    var seq = ++GFSEQ;
    sb.rpc("rpc_bank_facets", { p_subject: f.subject || null,
                                p_level: f.levels.length === 1 ? f.levels[0] : null,
                                p_pool: f.pool })
      .then(function (fac) {
        //  Ardicilliq nomresi: gec gelen kohne cavab tezesini ezmesin
        if (!live() || seq !== GFSEQ) return;
        FAC = fac || {}; GFKEY = key; genRefresh();
      })
      .catch(function () {});
  }

  function genRule(f) {
    var r = { pool: f.pool, count: f.count };
    if (f.subject) r.subject = f.subject;
    /*  Sinifler massiv kimi gedir.  Tek sinif secilibse "level" de
        elave olunur - kohne qaydalari oxuyan yerler pozulmasin
        (db/103 ikisini de taniyir).  */
    if (f.levels.length) {
      r.levels = f.levels.slice();
      if (f.levels.length === 1) r.level = f.levels[0];
    }
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
    f.levels  = lk.length === 1 ? [lk[0]] : [];
    nav("#/gen");
  }

  /*  Ilk acilis: muellimin fenni TEK olanda ve butun qruplari eyni
      sinifde olanda suzgec bos qalmasin.  "Butun fenler / Sinif
      secilmeyib" ile baslayan ekran yeni muellimi casdirirdi (UX
      yoxlamasi).  Yalniz BOS saheleri doldurur - tapsiriq ekranindan
      gelende (genForClass) sinif artiq secilidir.  */
  function genInit() {
    var f = genFilter();
    if (f.init) return Promise.resolve();
    f.init = true;
    return Promise.all([
      sb.select("classes", { select: "level_id", eq: { account_id: ACC.id } })
        .catch(function () { return []; }),
      loadLevels()
    ]).then(function (res) {
      var subs = mySubs();
      if (subs.length === 1 && !f.subject) f.subject = subs[0];
      var seen = {};
      (res[0] || []).forEach(function (c) { if (c.level_id) seen[c.level_id] = 1; });
      var ids = Object.keys(seen);
      if (ids.length === 1 && !f.levels.length) {
        var code = levelCode(ids[0]);
        if (code) f.levels = [code];
      }
    }).catch(function () {});
  }

  function screenGen() {
    var live = guard();
    var f = genFilter();
    topTitle.textContent = "Test yığ";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    //  Facets tek sinif qebul edir - movzu nisanlari onsuz da
    //  yalniz TEK sinif secilende cixir (asagida).
    genInit().then(function () {
      if (!live()) return;
      return sb.rpc("rpc_bank_facets", { p_subject: f.subject || null,
                                p_level: f.levels.length === 1 ? f.levels[0] : null,
                                p_pool: f.pool });
    })
      .then(function (fac) {
        if (!live()) return;
        FAC = fac || {}; GFKEY = genFacKey(f); GFSEQ++;
        drawGen();
        loadGenRec(f);
      })
      .catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  /*  ---- generatorun HISSELERI --------------------------------------
      Ekran bir defe qurulur; nisan basilanda YALNIZ deyisen hisse
      tezelenir (genSync).  Butun formani yeniden cizmek iki zerer
      verirdi: ekran yanib-sonurdu, ve ara merhelede sehife bir anliq
      QISALDIGI ucun brauzer surusmeni sifira sixirdi - muellim
      yerini itirirdi.  Indi forma yerinde qalir.  */
  function genSubOpts(f) {
    return '<option value="">Bütün fənlər</option>' +
      subFilter((FAC.subjects || []).filter(function (x) {
        return Number(x.n) > 0 || f.subject === x.slug;
      }), f.subject).map(function (x) {
        return '<option value="' + esc(x.slug) + '"' +
          (f.subject === x.slug ? " selected" : "") + ">" + esc(x.name) + "</option>";
      }).join("");
  }

  /*  Cipde YALNIZ reqem yazilir - basliq onsuz da "Sinif"dir.
      "1-ci sinif" yazsaq 11 cip iki setre dagilir; adi title-dadir.  */
  function genLevChips(f) {
    return (FAC.levels || []).map(function (l) {
      return '<button class="chip' +
        (f.levels.indexOf(l.code) >= 0 ? " on" : "") +
        '" data-l="' + esc(l.code) + '" title="' + esc(l.name) + '">' +
        esc(l.code) + "</button>";
    }).join("");
  }

  function genLevHint(f) {
    if (f.levels.length > 1) {
      return "Seçilmiş " + f.levels.length + " sinif arasında bərabər paylanır.";
    }
    if (f.levels.length === 1) {
      return levelNameByCode2(f.levels[0]) + " — başqasını da seçə bilərsiniz.";
    }
    return "Seçilməyib — bütün siniflərdən götürülür.";
  }

  /* Movzu nisanlari yalniz FENN + TEK SINIF secilende cixir.
     Sinifsiz fennin butun siniflerinin movzulari tokulur;
     iki sinif secilende de siyahi ikiqat olur.  Movzu secmek
     onsuz da tek sinif isi ile baglidir. */
  function genTopHtml(f) {
    if (!f.subject || f.levels.length !== 1) {
      return '<p class="muted" style="margin:12px 0 0">' +
        (!f.subject
          ? (f.levels.length === 1 ? "Mövzu seçmək üçün fənn seçin. "
                                   : "Mövzu seçmək üçün fənn və bir sinif seçin. ")
          : (f.levels.length > 1
              ? "Mövzu seçmək üçün tək sinif saxlayın. "
              : "Mövzu seçmək üçün sinif də seçin. ")) +
        "Mövzu seçilməsə, hamısından götürüləcək.</p>";
    }
    //  Suzgec deyisib, movzular hele gelmeyib.  Kohneleri gostermek
    //  olmaz - onlar BASQA sinfin movzularidir.
    if (genFacKey(f) !== GFKEY) {
      return '<p class="muted" style="margin:12px 0 0">Mövzular yüklənir…</p>';
    }
    if (!(FAC.topics || []).length) {
      return '<p class="muted" style="margin:12px 0 0">Bu fənn üçün mövzu yoxdur.</p>';
    }
    return '<div class="chips" id="gTop">' + FAC.topics.map(function (t) {
      return '<button class="chip' + (f.topics.indexOf(t.id) >= 0 ? " on" : "") +
        '" data-t="' + esc(t.id) + '">' +
        esc(topLabel(t, f.levels[0])) + "</button>";
    }).join("") + "</div>";
  }

  /*  Nisan basilanda: formanin ozu YERINDE qalir, yalniz nisanlarin
      yanili-sonuk halı, altindaki izah ve movzu qutusu deyisir.  */
  function genSync() {
    /*  Movzu qutusu bir anliq QISALIR (nisanlar -> bir setirlik yazi).
        Sened qisalanda brauzer surusmeni oz hedine sixir ve geri
        qaytarmir - muellim yerini itirir.  keepY() eyni derdi sual
        formasinda da hell edir.  */
    var back = keepY();
    var f = genFilter();
    var lv = $("gLevs");
    if (lv) {
      [].forEach.call(lv.querySelectorAll("[data-l]"), function (b) {
        var on = f.levels.indexOf(b.getAttribute("data-l")) >= 0;
        if (on) b.classList.add("on"); else b.classList.remove("on");
      });
    }
    var cd = $("gDiff");
    if (cd) {
      [].forEach.call(cd.querySelectorAll("[data-d]"), function (b) {
        var on = f.difficulty.indexOf(Number(b.getAttribute("data-d"))) >= 0;
        if (on) b.classList.add("on"); else b.classList.remove("on");
      });
    }
    var h = $("gLevHint");
    if (h) h.textContent = genLevHint(f);
    var tb = $("gTopBox");
    if (tb) tb.innerHTML = genTopHtml(f);
    back();
    genPreview();
  }

  /*  Suzgec cavabi gelende: fenn siyahisi ve sinif nisanlari da
      deyise biler (bos fenn gizledilir), ona gore onlar da
      tezelenir - amma yene YERINDE, ekrani sokmeden.  */
  function genRefresh() {
    var back = keepY();
    var f = genFilter();
    var sub = $("gsub");
    if (sub) sub.innerHTML = genSubOpts(f);
    var lv = $("gLevs");
    if (lv) lv.innerHTML = genLevChips(f);
    genSync();
    back();
  }

  function drawGen() {
    var f = genFilter();
    show(
      '<button class="btn sm ghost" id="btnBack">' + ic("back") +
        (f.back ? esc(f.backName || "Tapşırıqlar") : "Əsas səhifə") + "</button>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        "<h1>Avtomatik test</h1>" +
        '<p class="muted" style="margin:8px 0 0">Süzgəci seçin — sistem ' +
          "hovuzdan balanslı test yığacaq: mövzular arasında bərabər, " +
          "təkrarsız.</p>" +
      "</div>" +
      '<div id="gRec"></div>' +
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
        '<div style="margin-top:12px"><label for="gsub">Fənn</label>' +
          '<select id="gsub">' + genSubOpts(f) + "</select></div>" +
        /*  SINIF - COX SECIM.  Repetitor 8-ci sinfi hazirlayarken
            7-ci sinfin materialini da qatmaq isteyirdi; select tek
            secimli oldugu ucun ya bir sinif, ya "Hamisi" idi.
            Ceki QOYULMUR: secilen sinifler arasinda beraber paylanir,
            cunki muellim onlari bilerekden secib.  */
        '<label>Sinif</label>' +
        '<div class="chips num" id="gLevs">' + genLevChips(f) + "</div>" +
        //  Nisanlarla yazi arasi: menfi kenar onlari bir-birine
        //  yapisdirmisdi, oxumaq cetin idi
        '<p class="muted" id="gLevHint" style="margin:8px 0 18px">' +
          esc(genLevHint(f)) + "</p>" +
        /*  Cetinliyin de basligi var: iki nisan setri yan-yana
            durende hansinin ne oldugu bilinmirdi.  */
        '<label>Çətinlik</label>' +
        '<div class="chips" id="gDiff">' +
          [1, 2, 3].map(function (d) {
            return '<button class="chip' + (f.difficulty.indexOf(d) >= 0 ? " on" : "") +
              '" data-d="' + d + '">' + DIFF[d] + "</button>";
          }).join("") +
        "</div>" +
        '<div id="gTopBox">' + genTopHtml(f) + "</div>" +
      "</div>" +
      '<div class="spacer"></div>' +
      '<div class="card">' +
        '<div class="fieldrow">' +
          '<div><label for="gTitle">Testin adı</label>' +
            '<input id="gTitle" maxlength="120" placeholder="boş qalsa: fənn · sinif · tarix" value="' +
            esc(f.title) + '"></div>' +
          '<div style="flex:0 0 140px"><label for="gCnt">Sual sayı</label>' +
            '<input id="gCnt" type="number" min="1" max="100" inputmode="numeric" value="' +
            f.count + '"></div>' +
        "</div>" +
        /* Tapsiriq ekranindan gelmisiksa bu saheye ehtiyac yoxdur:
           teyinati ora qayidib veririk - orada son tarix, cehd sayi
           ve "tek sagird" secimi de var. */
        (f.back
          ? '<p class="muted" style="margin:0 0 14px">Hazır olan kimi «' +
            esc(f.backName || "qrup") + "» tapşırıq ekranına " +
            "qayıdacaqsınız — test orada seçilmiş gələcək.</p>"
          : '<label for="gAsg">Qrupa tapşırıq ver (istəyə görə)</label>' +
            '<select id="gAsg"><option value="">Yalnız test yığılsın</option></select>' +
            '<p class="muted" style="margin:-8px 0 14px">Qrup seçsəniz, test yaranan ' +
              "kimi ona tapşırıq gedəcək (son tarix 7 gün, 1 cəhd).</p>") +
        '<div id="gPrev"><div class="skel">Hovuz yoxlanılır…</div></div>' +
        '<div id="gErr"></div>' +
        '<button class="btn go" id="btnMake">' + ic("gen") + "Testi yığ</button>" +
      "</div>"
    );

    on("btnBack", "click", function () {
      //  imtina: geri qayidis niyyetini de temizleyirik
      if (f.back) { var gid = f.back; f.back = ""; f.backName = ""; nav("#/a/" + gid); return; }
      nav("#/");
    });
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
      f.subject = ""; f.levels = []; f.topics = [];
      screenGen();
    });
    on("gDiff", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-d]") : null;
      if (!b) return;
      var d = Number(b.getAttribute("data-d"));
      var i = f.difficulty.indexOf(d);
      if (i >= 0) f.difficulty.splice(i, 1); else f.difficulty.push(d);
      genSync();
    });
    //  Dinleyici gTopBox-a baglanir, gTop-a yox: movzu qutusunun
    //  ICI genSync-de yeniden yazilir, qutunun ozu ise yerinde qalir.
    on("gTopBox", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-t]") : null;
      if (!b) return;
      var t = b.getAttribute("data-t");
      var i = f.topics.indexOf(t);
      if (i >= 0) f.topics.splice(i, 1); else f.topics.push(t);
      genSync();
    });
    on("gsub", "change", function () {
      //  Sinif nisanlari ile eyni yol - ekran silinmir
      f.subject = $("gsub").value; f.topics = [];
      genSync(); genFacets();
    });
    on("gLevs", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-l]") : null;
      if (!b) return;
      var k = b.getAttribute("data-l");
      var i = f.levels.indexOf(k);
      if (i >= 0) f.levels.splice(i, 1); else f.levels.push(k);
      //  Movzular sinife baglidir - sinif deyisdise secim menasizdir
      f.topics = [];
      /*  Evvelce YERLI cizilir - nisan derhal yanir, sehife yerinde
          qalir.  Suzgec siyahilari (fenn saylari, movzular) sinifden
          asilidir, ona gore arxadan yenilenir; geldiyi anda ekran
          sakitce tezelenir.  Ilk sinif, ikinci sinif, secimi silmek -
          UCU DE eyni yolla gedir, yoxsa bezi klikde ekran yanib
          sonur, bezisinde yox.  */
      genSync(); genFacets();
    });
    on("gTitle", "input", function () { f.title = $("gTitle").value; });
    //  qrup siyahisi ayrica dolur - secim suzgec deyismelerinde itmesin
    if (!f.back) sb.select("classes", { select: "id,name", eq: { account_id: ACC.id },
                           order: "name" })
      .then(function (rows) {
        var sel = $("gAsg");
        if (!sel) return;
        sel.innerHTML = '<option value="">Yalnız test yığılsın</option>' +
          (rows || []).map(function (c) {
            return '<option value="' + esc(c.id) + '"' +
              (f.asg === c.id ? " selected" : "") + ">" + esc(c.name) + "</option>";
          }).join("");
      }).catch(function () {});
    on("gAsg", "change", function () { f.asg = $("gAsg").value; });

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
          //  Yeni muellimin oz suali yoxdur - bu xeta deyil, yol
          //  gostermekdir (evvel ilk aciliska qirmizi xeta cixirdi)
          : (f.pool === "mine" && !(Number((FAC.usage || {}).used) || 0)
              ? msg("warn", "Hələ öz sualınız yoxdur. «Sual bankı»nda yazın" +
                    ((ACC && ACC.plan)
                      ? " və ya yuxarıda «Platforma» seçin."
                      : " — platforma hovuzu abunə paketi ilə açılır."))
              : msg("err", "Bu süzgəclə yalnız " + found + " fərqli sual tapıldı (" +
                    want + " istənilir). Süzgəci genişləndirin və ya sayı azaldın."));
      })
      .catch(function (e) {
        if (!live()) return;
        var box = $("gPrev");
        if (box) box.innerHTML = msg("err", fail(e));
      });
  }

  /*  Ad bos qalanda "Avtomatik test" evezine menali ad: fenn, sinif,
      tarix.  Canlida "1" adli test gorundu - muellim ad yazmaga vaxt
      qoymur, siyahida ise hansi test oldugu bilinmirdi.  */
  function genAutoTitle(f) {
    var sub = (FAC.subjects || []).filter(function (x) { return x.slug === f.subject; })[0];
    var parts = [sub ? sub.name : "Test"];
    if (f.levels.length === 1) parts.push(levelNameByCode2(f.levels[0]));
    else if (f.levels.length > 1) parts.push(f.levels.slice().sort(function (a, b) {
      return Number(a) - Number(b); }).join(", ") + " siniflər");
    parts.push(dateAz(new Date().toISOString()));
    return parts.join(" · ");
  }

  /*  «Tövsiyə olunan» - dərs planı olan qruplar üçün son keçilən fəsildən
      10 sual: bir toxunuşla yığılır və tapşırıq ekranına keçir.  Qrupdan
      gəlmişiksə yalnız o qrup, yoxsa hesabın qrupları (5-ə qədər).  */
  var GREC_SEQ = 0;
  function loadGenRec(f) {
    var box = $("gRec");
    if (!box || !(ACC && ACC.plan)) return;
    var seq = ++GREC_SEQ;
    var q = f.back
      ? sb.select("classes", { select: "id,name", eq: { id: f.back } })
      : sb.select("classes", { select: "id,name", eq: { account_id: ACC.id }, order: "name" });
    q.then(function (cls) {
      cls = (cls || []).slice(0, 5);
      return Promise.all(cls.map(function (c) {
        return sb.rpc("rpc_lesson_prep", { p_class_id: c.id })
          .then(function (d) { return { c: c, d: d || {} }; })
          .catch(function () { return null; });
      }));
    }).then(function (rows) {
      if (seq !== GREC_SEQ || !$("gRec")) return;
      rows = (rows || []).filter(function (x) { return x && x.d.last && x.d.subject; });
      if (!rows.length) return;
      $("gRec").innerHTML = '<div class="spacer"></div><div class="card tight grec">' +
        '<div class="pt"><b>Tövsiyə olunan</b><span class="muted">son keçilən fəsildən · 10 sual</span></div>' +
        rows.map(function (x, i) {
          var ch = x.d.last.group || x.d.last.topic;
          return '<div class="grow"><div><b>' + esc(ch) + "</b>" +
            '<span class="muted"> · ' + esc(x.c.name) + "</span></div>" +
            '<button class="btn sm" data-grec="' + i + '">' + ic("gen") + "Yığ</button></div>";
        }).join("") + "</div>";
      Array.prototype.forEach.call($("gRec").querySelectorAll("[data-grec]"), function (b) {
        b.addEventListener("click", function () {
          var x = rows[Number(b.getAttribute("data-grec"))];
          if (!x || busy) return;
          var ff = genFilter();
          ff.pool = "all";
          ff.subject = x.d.subject; ff.levels = x.d.level ? [x.d.level] : [];
          ff.topics = x.d.last.topic_id ? [x.d.last.topic_id] : [];
          ff.difficulty = []; ff.cls = ""; ff.remNames = []; ff.asg = "";
          ff.count = 10;
          ff.title = (x.d.last.group || x.d.last.topic) + " — ev tapşırığı";
          ff.back = x.c.id; ff.backName = x.c.name;
          b.disabled = true; b.textContent = "Yığılır…";
          makeTest();
        });
      });
    }).catch(function () {});
  }

  function makeTest() {
    if (busy) return;
    var f = genFilter();
    $("gErr").innerHTML = "";
    setBusy("btnMake", true, "Testi yığ");
    sb.rpc("rpc_generate_test", { p_rule: genRule(f), p_title: (f.title || "").trim() || genAutoTitle(f) })
      .then(function (v) {
        //  qrup secilibse test derhal tapsiriq kimi gedir; tapsiriq
        //  alinmasa da test hazirdir - veraqde elle vermek olar
        if (!f.asg) return v;
        return sb.rpc("rpc_assign_test", {
          p_class_id: f.asg, p_test_id: v.test_id,
          p_closes_at: new Date(Date.now() + 7 * 864e5).toISOString(),
          p_max_attempts: 1
        }).catch(function () {}).then(function () { return v; });
      })
      .then(function (v) {
        busy = false;
        //  Tapsiriq ekranindan gelmisiksa ora qayidiriq - teze test
        //  siyahida secili gelsin deye id-ni otururuk.
        if (f.back) {
          var gid = f.back;
          f.back = ""; f.backName = "";
          PICKNEW = v.test_id;
          nav("#/a/" + gid);
          return;
        }
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
      sb.select("classes", { select: "id,name", eq: { account_id: ACC.id }, order: "name" }),
      //  bu testin movcud teyinatlari - "verilib" siyahisi ucun
      sb.select("assignments", { select: "class_id,student_id,closes_at", eq: { test_id: id } })
        .catch(function () { return []; }),
      //  "kime" secimi: hesabin butun aktiv sagirdleri, qrupa gore suzulur
      sb.select("students", {
        select: "id,full_name,class_id",
        eq: { account_id: ACC.id, is_active: true },
        order: "full_name"
      }).catch(function () { return []; })
    ]).then(function (res) {
      if (!live()) return;
      drawPaper(res[0] || {}, res[1] || [], res[2] || [], res[3] || []);
    }).catch(function (e) { if (live()) show(msg("err", fail(e))); });
  }

  /* Cap / PDF: veraq ucun temiz nusxe qurulur (ekran metalari -
     movzu, cetinlik, "sehv bildir" - kagiza dusmur), brauzerin oz
     cap pencersi acilir.  Orada "PDF olaraq saxla" da var - elave
     kitabxana lazim deyil.  withKey=true olanda cavab acari AYRICA
     sehifede cixir; sagird nusxesinde duzgun cavab izi yoxdur. */
  function paperPrint(t, withKey) {
    var qs = t.questions || [];
    var L = "ABCDEFGH";
    //  Su nisani: veraqi CAP EDEN muellimin adi + tam tarix.  Meqsed
    //  maneе yaratmaq deyil - sual basqa yerde cixsa, kimin cixardigi
    //  bilinsin.  Adi olmayan hesabda sadece "Bil10 · tarix" qalir.
    var d = new Date();
    var dm = function (n) { return (n < 10 ? "0" : "") + n; };
    var stamp = dm(d.getDate()) + "." + dm(d.getMonth() + 1) + "." + d.getFullYear();
    var who = (CTX && CTX.profile && CTX.profile.full_name) || "";
    var foot = "Bil10" + (who ? " · " + esc(who) : "") + " · " + stamp;
    var box = $("printBox");
    if (!box) {
      box = document.createElement("div");
      box.id = "printBox";
      document.body.appendChild(box);
    }
    var h = '<div class="pph">' +
      "<h1>" + esc(t.title || "") + "</h1>" +
      '<div class="ppm">' + esc(t.subject || "") +
        (t.level ? " · " + esc(t.level) : "") + " · " + qs.length +
        " sual · Bil10</div>" +
      '<div class="ppf"><span>Ad, soyad: ________________________</span>' +
        "<span>Tarix: ____________</span><span>Bal: ______</span></div>" +
      "</div>" +
      qs.map(function (q) {
        var b = '<div class="ppq"><div class="ppb">' + q.ord + ". " + esc(q.body) +
          (q.kind === "multi"
            ? ' <i class="ppmu">(bir neçə düzgün cavab)</i>' : "") + "</div>";
        if (q.kind === "text") {
          b += '<div class="ppl">Cavab: _______________________________</div>';
        } else {
          b += (q.options || []).map(function (o, i) {
            return '<div class="ppo"><b>' + L.charAt(i) + ")</b> <span>" +
              esc(o.body) + "</span></div>";
          }).join("");
        }
        return b + "</div>";
      }).join("");
    if (withKey) {
      h += '<div class="ppk"><h2>Cavab açarı — ' + esc(t.title || "") + "</h2>" +
        '<div class="ppkn">Bu səhifə şagirdlərə paylanmır.</div>' +
        '<div class="ppkg">' +
        qs.map(function (q) {
          var a;
          if (q.kind === "text") {
            a = (q.options || []).filter(function (o) { return o.correct; })
              .map(function (o) { return esc(o.body); }).join(" / ");
          } else {
            a = (q.options || []).map(function (o, i) {
              return o.correct ? L.charAt(i) : "";
            }).filter(Boolean).join(", ");
          }
          return "<span><b>" + q.ord + ".</b> " + (a || "—") + "</span>";
        }).join("") + "</div></div>";
    }
    //  Tekrarlanan altliq: <tfoot> her cap sehifesinde tekrarlanir VE
    //  ozune yer ayirir - position:fixed kimi suallarin ustune dusmur.
    box.innerHTML = '<table class="ppw"><tfoot><tr><td>' +
      '<div class="ppfoot">' + foot + "</div></td></tr></tfoot>" +
      "<tbody><tr><td>" + h + "</td></tr></tbody></table>";
    document.body.classList.add("printing");
    function off() {
      document.body.classList.remove("printing");
      window.removeEventListener("afterprint", off);
    }
    window.addEventListener("afterprint", off);
    window.print();
    //  afterprint bezi brauzerlerde gelmir - ehtiyat temizlik
    //  (sinif yalniz @media print-e tesir edir, ekranda gorunmur)
    setTimeout(off, 2000);
  }

  function drawPaper(t, classes, asgs, students) {
    students = students || [];
    //  Yalniz QRUP teyinatlari qrupu secimden cixarir; ferdi teyinat
    //  cixarmir - hemin qrupun basqa sagirdine de vermek olar.
    var asgMap = {}, soloN = {};
    (asgs || []).forEach(function (a) {
      if (a.student_id) soloN[a.class_id] = (soloN[a.class_id] || 0) + 1;
      else asgMap[a.class_id] = a;
    });
    var given = classes.filter(function (c) { return asgMap[c.id]; });
    var freeCls = classes.filter(function (c) { return !asgMap[c.id]; });
    var qs = t.questions || [];
    var done = Number(t.done) || 0;
    //  Diaqnostik test (118): "her movzudan 3 sual", yalniz bir sagirde.
    //  "Yeniden yig" ve "Qrupa teyin et" burada menasizdir - server de
    //  redd edir (119); idareetme sagird ekranindaki kartdadir.
    var diag = !!(t.gen_rule && t.gen_rule.kind === "diagnostic");
    var diagStu = diag ? (students || []).filter(function (x) {
      return x.id === t.gen_rule.student; })[0] : null;
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
        '<div class="prnrow">' +
          '<button class="btn sm" id="btnPrn">' + ic("print") +
            "Çap / PDF</button>" +
          '<button class="btn sm ghost" id="btnPrnK">' + ic("key") +
            "Cavab açarı ilə</button>" +
          (t.gen_rule && !done && !diag
            ? '<button class="btn sm ghost" id="btnRegen">' + ic("gen") +
              "Yenidən yığ</button>"
            : "") +
        "</div>" +
        '<p class="muted" style="margin:10px 0 0">Çap pəncərəsində printer ' +
          "əvəzinə «PDF olaraq saxla» seçsəniz, vərəq fayl kimi yüklənəcək. " +
          "«Cavab açarı ilə» variantında açar ayrıca səhifədə çıxır.</p>" +
        (t.gen_rule && done && !diag
          ? '<p class="muted" style="margin:8px 0 0">Bu testi artıq şagird ' +
            "işlədiyi üçün yeniləmək olmaz — yeni test yığın.</p>"
          : "") +
        '<div id="pErr"></div>' +
      "</div>" +
      '<div class="spacer"></div>' +
      (diag
        ? "<h2>Diaqnostika</h2>" +
          '<div class="card" id="pDiag">' +
            '<div class="pgrow">' + ic("person") + "<span>Hər mövzudan 3 sual — " +
              (diagStu
                ? "yalnız <b>" + esc(diagStu.full_name || "") + "</b> üçün"
                : "yalnız bir şagird üçün") +
              ", bir cəhd.</span></div>" +
            '<p class="muted" style="margin:10px 0 0">Qrupa verilmir və yenidən yığılmır: ' +
              "nəticə, mövzu xəritəsi və «Yenidən diaqnostika» şagirdin öz ekranındadır." +
              //  qisa ad noqte ile bitir ("Huseynov M.") - cumle sonuna ikinci noqte qoyulmur
              (diagStu
                ? ' <a href="#/s/' + esc(diagStu.id) + "/" + esc(diagStu.class_id || "") +
                  '">' + esc(diagStu.full_name || "Şagird") + " → şagird ekranı</a>"
                : "") +
            "</p>" +
          "</div>"
        : "<h2>Qrupa təyin et</h2>" +
      '<div class="card">' +
        (given.length || Object.keys(soloN).length
          ? '<div class="pgiven">' +
            given.map(function (c) {
              var a = asgMap[c.id];
              return '<div class="pgrow">' + ic("check") +
                "<span><b>" + esc(c.name) + "</b> — verilib" +
                (a.closes_at ? " · son tarix " + dateAz(a.closes_at) : " · açıq") +
                "</span></div>";
            }).join("") +
            //  ferdi teyinatlar: qrupu bloklamir, amma gorunmelidir
            classes.filter(function (c) { return soloN[c.id]; })
              .map(function (c) {
                return '<div class="pgrow">' + ic("person") +
                  "<span><b>" + esc(c.name) + "</b> — " + soloN[c.id] +
                  " şagirdə fərdi verilib</span></div>";
              }).join("") + "</div>"
          : "") +
        (classes.length && !freeCls.length
          ? '<p class="muted" style="margin:0">Bu test bütün qruplarınıza verilib.</p>'
          : "") +
        (freeCls.length
          ? '<div><label for="pWho">Kimə</label>' +
              '<select id="pWho"></select></div>' +
            '<p class="muted" style="margin:-8px 0 14px">Tək şagird ' +
              "seçsəniz, tapşırığı yalnız o görəcək — qrupun qalanı yox.</p>" +
            '<div class="fieldrow">' +
              '<div><label for="pCls">Qrup</label><select id="pCls">' +
                freeCls.map(function (c) {
                  return '<option value="' + esc(c.id) + '">' + esc(c.name) +
                    (soloN[c.id] ? " · " + soloN[c.id] + " şagirdə verilib" : "") +
                    "</option>";
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
          : (classes.length
              ? ""
              : '<p class="muted">Əvvəlcə əsas səhifədə qrup yaradın — sonra bu ' +
                "testi ona təyin edə biləcəksiniz.</p>")) +
      "</div>") +
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

    on("btnPrn",  "click", function () { paperPrint(t, false); });
    on("btnPrnK", "click", function () { paperPrint(t, true); });

    /* "Kime" siyahisi secilen qrupa baglidir - qrup deyisende yenilenir.
       Artiq ferdi teyinat almis sagird tekrar teklif olunmur. */
    function fillWho() {
      var sel = $("pWho"), cls = ($("pCls") || {}).value;
      if (!sel) return;
      var mine = students.filter(function (st) { return st.class_id === cls; });
      var taken = {};
      (asgs || []).forEach(function (a) {
        if (a.student_id && a.class_id === cls) taken[a.student_id] = true;
      });
      mine = mine.filter(function (st) { return !taken[st.id]; });
      sel.innerHTML = '<option value="">Bütün qrup' +
        (mine.length ? " (" + mine.length + " şagird)" : "") + "</option>" +
        mine.map(function (st) {
          return '<option value="' + esc(st.id) + '">yalnız ' +
            esc(st.full_name || "") + "</option>";
        }).join("");
    }
    fillWho();
    on("pCls", "change", fillWho);

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
        p_closes_at: closes, p_max_attempts: Number(($("pTry") || {}).value || 1),
        //  bos = butun qrup
        p_student_id: (($("pWho") || {}).value || null)
      }).then(function () {
        //  sehife yenilenir - teze teyinat "verilib" siyahisinda gorunur
        busy = false;
        screenPaper(t.id);
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

  /*  Movzu nisanlarinin heddi: bundan cox olanda sinif teleb olunur.
      Telefonda ~20 nisan iki-uc setirdir, 60 nisan ekrani udur.  */
  var TOPCAP = 20;

  /*  SORGU NESLI.  guard() yalniz UNVANI tutusdurur - bank ekraninda
      hovuz/suzgec deyisende unvan ("#/b") DEYISMIR, ona gore kohne
      sorgunun cavabi teze render-in ustune dusurdu: seqmentde
      "Platforma" yanirdi, siyahida ise muellimin oz suallari
      qalirdi.  Her sorgu oz neslini goturur; cavab gelende nesil
      hele de sonuncudursa yazilir.  */
  var BFSEQ = 0;   // suzgec (rpc_bank_facets)
  var BSEQ  = 0;   // netice sahesi (rpc_bank_list / rpc_bank_coverage)

  /*  Siyahida nece sual atlanir.  rpc_bank_list offset-i onsuz da
      desteklyirdi - ekran hemise 0 gonderirdi, ona gore 51-ci suala
      catmaq MUMKUN DEYILDI.  Suzgec deyisende sifirlanir.  */
  var BOFF = 0;

  /*  KATALOG REJIMI.  Platforma hovuzunda duz 50 sual tokmek menasiz
      idi: setirler disabled gelir (muellim platforma sualini ne acir,
      ne redaktə edir), ustelik siralama created_at desc oldugu ucun
      ekranda yalniz EN SON yazilan sinfin kesiyi gorunurdu.
      Muellimin sorusdugu "MENIM sinfimde ne qeder var" sualidir -
      ona siyahi yox, EHATE cavab verir.
      Axtaris yazilanda ve ya movzu/cetinlik secilende adi siyahiya
      qayidiriq: orada muellim konkret sual axtarir.  */
  function catalogMode(f) {
    return f.pool !== "mine" && !(f.q || "").trim() &&
           !f.topics.length && !f.difficulty.length;
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

    var myf = ++BFSEQ;
    sb.rpc("rpc_bank_facets", { p_subject: f.subject || null,
                                p_level: f.level || null, p_pool: f.pool || "mine" })
      .then(function (fac) {
        if (!live() || myf !== BFSEQ) return;
        FAC = fac || {};
        //  Ilk acilis: oz suali olmayan muellime bos "Sual tapilmadi"
        //  gostermek evezine platforma bankini aciriq (UX yoxlamasi)
        if (!f.auto) {
          f.auto = true;
          if (f.pool === "mine" && !(Number((FAC.usage || {}).used) || 0)) {
            f.pool = "platform";
            screenBank();
            return;
          }
        }
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
            subFilter((FAC.subjects || []).filter(function (s) {
              return Number(s.n) > 0 || f.subject === s.slug;
            }), f.subject).map(function (s) {
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
        /* Movzu nisanlari.  Fennsiz 110 nisan cixirdi; platforma
           hovuzunda tek fennle de 11 sinfin movzulari tokulurdu
           (Ingilis dilinde 60 nisan) - suzgec ekrani udurdu.
           Sert SAYA baglidir, hovuza yox: oz banki kicikdir, orada
           sinif istemek lazimsiz maneedir; cox olanda sinif isteyirik. */
        /* KATALOG REJIMINDE nisanlar umumiyyetle cixmir: asagidaki
           ehate siyahisi eyni movzulari sayla, cetinlik bolgusu ve
           numune ile gosterir - eyni 12 ad ekranda IKI DEFE yazilirdi.
           "Sinif secin" ipucunu da ehate panelinin ozu verir.
           Movzu ve ya cetinlik secilen kimi siyahiya keciririk;
           nisanlar orada YENE lazimdir - secimi goturmek ucun. */
        (catalogMode(f) ? "" :
        (!f.subject || (!f.level && (FAC.topics || []).length > TOPCAP)
          ? '<p class="muted" style="margin:12px 0 0">' +
            (!f.subject
              ? "Mövzuları görmək üçün fənn seçin."
              : "Bu fənndə " + (FAC.topics || []).length +
                " mövzu var — siyahını qısaltmaq üçün sinif də seçin.") + "</p>"
          : ((FAC.topics || []).length
              ? '<div class="chips" id="bTop">' + FAC.topics.map(function (t) {
                  return '<button class="chip' + (f.topics.indexOf(t.id) >= 0 ? " on" : "") +
                    '" data-t="' + esc(t.id) + '">' +
                    esc(topLabel(t, f.level)) + "</button>";
                }).join("") + "</div>"
              : '<p class="muted" style="margin:12px 0 0">Bu fənn üçün mövzu yoxdur.</p>'))) +
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

  /* ================================================================
     EHATE GORUNTUSU — "menim sinfimde ne qeder var?"
     Iki pille:  fenn -> siniflər (sayla)  ->  movzular (sayla,
     cetinlik bolgusu ve 3 numune ile).
     Movzuya basanda numuneler ACILIR - platforma sualinin
     variantlarini ve duz cavabini yalniz burada gormek olur
     (siyahida o setirler disabled-dir).
     ================================================================ */
  function loadCoverage(f, live) {
    var box = $("bList");
    if (box) box.innerHTML = '<div class="skel">Yüklənir…</div>';
    var my = ++BSEQ;
    sb.rpc("rpc_bank_coverage", {
      p_subject: f.subject, p_level: f.level || null, p_pool: f.pool
    }).then(function (d) {
      if (!live() || my !== BSEQ) return;
      drawCoverage(f, d || {});
    }).catch(function (e) {
      if (!live() || my !== BSEQ) return;
      var b = $("bList");
      if (b) b.innerHTML = msg("err", fail(e));
    });
  }

  function subName(slug) {
    var x = (FAC.subjects || []).filter(function (s) { return s.slug === slug; })[0];
    return x ? x.name : slug;
  }

  function drawCoverage(f, d) {
    var box = $("bList");
    if (!box) return;
    var total = Number(d.total) || 0;
    /*  Sinfin ADI serverin oz cavabindan goturulur.  LEVELS kesine
        guvenmek olmaz: onu loadLevels() doldurur, screenBank ise onu
        cagirmir - "#/b" birbasa acilanda kes bos olur ve basliqda
        "Riyaziyyat · 1 · 480 sual" kimi cilpaq kod qalirdi.
        d.levels sinif secilende de tam gelir (server onu suzmur).  */
    var head = '<div class="bcount">' + esc(subName(f.subject)) +
      (f.level ? " · " + esc(covLevelName(d, f.level)) : "") +
      (showBankN() ? " · " + total + " sual" : "") + "</div>";

    if (!total) {
      box.innerHTML = head + '<div class="empty"><div class="ic">' + ic("doc") +
        "</div><b>Bu bölmədə hələ sual yoxdur</b>" +
        "Başqa sinif və ya fənn seçin.</div>";
      bindCovBack(f);
      return;
    }

    //  --- pille 1: siniflər
    if (!f.level) {
      var lv = d.levels || [];
      box.innerHTML = head +
        '<div class="bpick"><p>Sinif seçin — həmin sinfin mövzuları' +
          (showBankN() ? " və hər mövzuda neçə sual olduğu" : "") + " görünəcək.</p>" +
          '<div class="g">' + lv.map(function (l) {
            return '<button class="pkb" data-l="' + esc(l.code) + '">' +
              esc(l.name) + (showBankN() ? "<i>" + (Number(l.n) || 0) + " sual</i>" : "") + "</button>";
          }).join("") + "</div>" +
          (Number(d.no_level) > 0
            ? '<p class="muted" style="margin:12px 0 0">Bundan başqa ' +
              (showBankN() ? Number(d.no_level) + " sual" : "Bəzi suallar") + " sinifsizdir — istənilən sinifdə " +
              "işlənə bilər.</p>"
            : "") +
        "</div>";
      Array.prototype.forEach.call(box.querySelectorAll("[data-l]"), function (b) {
        b.addEventListener("click", function () {
          f.level = b.getAttribute("data-l");
          f.topics = [];
          screenBank();          //  sinif deyisdi - movzu nisanlari da yenilenir
        });
      });
      return;
    }

    //  --- pille 2: movzular
    var tp = d.topics || [];
    var max = tp.reduce(function (a, t) { return Math.max(a, Number(t.n) || 0); }, 0) || 1;
    var min = tp.reduce(function (a, t) {
      return Math.min(a, Number(t.n) || 0); }, max);
    /*  Zolaq movzular arasindaki FERQI gosterir.  Hamisinda eyni say
        varsa (generator movzu basina beraber doldurub) her zolaq 100%
        olur - ekranda 12 dene tam dolu xett qalir, hec ne demir.
        Bele halda zolagi umumiyyetle cizmirik.  */
    var bars = max > min && showBankN();
    box.innerHTML = head +
      '<div class="cov">' + tp.map(function (t) {
        var n = Number(t.n) || 0;
        var parts = [];
        if (showBankN()) {
          if (Number(t.d1)) parts.push("asan " + t.d1);
          if (Number(t.d2)) parts.push("orta " + t.d2);
          if (Number(t.d3)) parts.push("çətin " + t.d3);
        }
        return '<div class="cvw">' +
          '<button class="cvr" data-t="' + esc(t.id) + '">' +
            '<div class="g"><b>' + esc(t.name) + "</b>" +
              (bars
                ? '<div class="cbar"><i style="width:' +
                  Math.round(n * 100 / max) + '%"></i></div>'
                : "") +
              (parts.length ? "<i>" + esc(parts.join(" · ")) + "</i>" : "") + "</div>" +
            (showBankN() ? '<span class="n">' + n + "</span>" : "") +
            '<span class="arrow">' + ic("right") + "</span>" +
          "</button>" +
          '<div class="smp" id="smp-' + esc(t.id) + '"></div>' +
        "</div>";
      }).join("") + "</div>" +
      (Number(d.no_topic) > 0
        ? '<div class="bpick"><p style="margin:0">Bu sinifdə ' +
          (showBankN() ? Number(d.no_topic) + " sual" : "bəzi suallar") + " mövzusuzdur.</p></div>"
        : "");

    Array.prototype.forEach.call(box.querySelectorAll("[data-t]"), function (b) {
      b.addEventListener("click", function () { toggleSamples(f, b); });
    });
    bindCovBack(f);
  }

  //  Sinifden geri qayitmaq ucun basliqdaki "geri" - suzgeci acmaga
  //  ehtiyac qalmasin.  Ayrica setir deyil, movcud .bcount-a qosulur.
  function bindCovBack(f) {
    var c = document.querySelector("#bList .bcount");
    if (!c || !f.level) return;
    c.insertAdjacentHTML("beforeend",
      ' <button class="btn sm ghost" id="covUp">' + ic("back") +
      "bütün siniflər</button>");
    on("covUp", "click", function () {
      f.level = ""; f.topics = [];
      screenBank();
    });
  }

  function covLevelName(d, code) {
    var l = (d.levels || []).filter(function (x) { return x.code === code; })[0];
    if (l && l.name) return l.name;
    //  ehtiyat: suzgecin oz siyahisi, sonra cilpaq kod
    var f2 = (FAC.levels || []).filter(function (x) { return x.code === code; })[0];
    return (f2 && f2.name) || code;
  }

  /*  Numuneler: server en coxu 3 verir (29_bank_katalog.sql).
      Ikinci klik baglayir - eyni movzuya tekrar sorgu getmir.  */
  function toggleSamples(f, btn) {
    var id  = btn.getAttribute("data-t");
    var box = $("smp-" + id);
    if (!box) return;
    if (box.innerHTML) { box.innerHTML = ""; btn.classList.remove("open"); return; }
    btn.classList.add("open");
    box.innerHTML = '<div class="skel">Yüklənir…</div>';
    sb.rpc("rpc_bank_samples", { p_topic: id, p_limit: 3, p_pool: f.pool })
      .then(function (list) {
        if (!$("smp-" + id)) return;
        list = list || [];
        if (!list.length) { box.innerHTML = ""; return; }
        box.innerHTML = list.map(function (q) {
          return '<div class="sq"><b>' + esc(q.body) + "</b>" +
            ((q.options || []).length
              ? "<ul>" + q.options.map(function (o) {
                  return '<li' + (o.correct ? ' class="c"' : "") + ">" +
                    esc(o.body) + "</li>";
                }).join("") + "</ul>"
              : '<p class="muted">Açıq cavablı sual</p>') +
            "</div>";
        }).join("") +
        '<button class="morebtn" data-all="' + esc(id) + '">' +
          "Bu mövzunun bütün suallarını gör</button>";
        var ab = box.querySelector("[data-all]");
        if (ab) ab.addEventListener("click", function () {
          f.topics = [id];
          screenBank();      //  movzu secildi -> katalogdan siyahiya kecir
        });
      })
      .catch(function (e) { box.innerHTML = msg("err", fail(e)); });
  }

  function loadBank(append) {
    var live = guard();
    var f = bankFilter();
    /*  Suzgecsiz platforma/hamisi: minlerle suali tokmek evezine fenn
        secimi teklif olunur.  Oz banki ise derhal acilir - muellim oz
        suallarini gormek ucun gelir.  */
    //  Fenn secilib, movzu/axtaris yoxdur -> siyahi yox, EHATE
    if (catalogMode(f) && f.subject) return loadCoverage(f, live);

    if (f.pool !== "mine" && nFilt(f) === 0 && !(f.q || "").trim()) {
      BSEQ++;                      //  ucusdaki kohne cavab bura yazmasin
      var box0 = $("bList");
      if (box0) {
        var subs = subFilter((FAC.subjects || []).filter(function (x) {
          return (Number(x.n) || 0) > 0;
        }));
        var total = subs.reduce(function (a, x) {
          return a + (Number(x.n) || 0);
        }, 0);
        box0.innerHTML = subs.length
          ? '<div class="bpick"><p>' +
              (showBankN() ? "Bankda <b>" + total + "</b> sual var. " : "") +
              "Siyahı üçün fənn seçin və ya yuxarıdan axtarın:</p>" +
              '<div class="g">' + subs.map(function (x) {
                return '<button class="pkb" data-s="' + esc(x.slug) + '">' +
                  esc(x.name) + (showBankN() ? "<i>" + x.n + " sual</i>" : "") + "</button>";
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
    if (!append) BOFF = 0;
    var my = ++BSEQ;
    sb.rpc("rpc_bank_list", { p_filters: bankRule(f), p_limit: 50, p_offset: BOFF })
      .then(function (d) {
        if (!live() || my !== BSEQ) return;
        var box = $("bList");
        if (!box) return;
        d = d || {};
        var items = d.items || [];
        var total = Number(d.total) || 0;
        if (!items.length && !append) {
          box.innerHTML = '<div class="empty"><div class="ic">' + ic("doc") + "</div>" +
            "<b>Sual tapılmadı</b>" +
            (f.pool === "mine"
              ? "Yuxarıdan «Yeni sual» ilə başlayın."
              : "Süzgəci genişləndirin.") + "</div>";
          return;
        }
        var shown = BOFF + items.length;
        var rows = items.map(function (q) {
          var mine = !!q.mine;
          /*  Suzgecde ONSUZ DA secilmis olani her setirde tekrarlamiriq:
              50 setirde "Ingilis dili · 11-ci sinif" 50 defe yazilirdi
              ve setri iki qat hundur edirdi.  */
          var meta = [];
          if (!f.subject && q.subject) meta.push(esc(q.subject));
          if (!f.level && q.level)     meta.push(esc(q.level));
          if (q.topic)                 meta.push(esc(q.topic));
          if (!mine)                   meta.push("platforma");
          /*  Variantlar setrin ALTINDA gosterilir - numune kartlari
              ile eyni gorunusde.  Evvel siyahida yalniz basliq vardi:
              muellim "butun suallari gor" deyende numunede gorduyu
              cavablari ITIRIRDI - genislendirdikce az melumat.
              Duymenin ICINE qoymaq olmaz: platforma suallarinda duyme
              "disabled"-dir, icindeki her sey solgunlasir.  */
          var opts = q.options || [];
          return '<div class="qitem">' +
            '<button class="qrow" data-q="' + esc(q.id) + '"' +
              (mine ? "" : " disabled") + ">" +
              '<div class="g"><b>' + esc(q.body) + "</b><i>" +
                meta.map(function (m, i) {
                  return (i ? "<span>·</span>" : "") + "<span>" + m + "</span>";
                }).join("") +
                '<span class="dif d' + (Number(q.difficulty) || 2) + '">' +
                  DIFF[Number(q.difficulty) || 2] + "</span>" +
              "</i></div>" +
              (mine ? '<span class="arrow">' + ic("right") + "</span>" : "") +
            "</button>" +
            (opts.length
              ? '<ul class="qopts">' + opts.map(function (o) {
                  return '<li' + (o.correct ? ' class="c"' : "") + ">" +
                    esc(o.body) + "</li>";
                }).join("") + "</ul>"
              : "") +
          "</div>";
        }).join("");

        var more = shown < total
          ? '<button class="morebtn" id="bMore">Daha ' +
            Math.min(50, total - shown) + " sual göstər (" + shown + "/" + total + ")</button>"
          : "";

        if (append) {
          var mb0 = $("bMore");
          if (mb0) mb0.remove();
          box.insertAdjacentHTML("beforeend", rows + more);
        } else {
          box.innerHTML =
            '<div class="bcount">' +
              (f.pool === "mine" || showBankN()
                ? total + " sual" + (shown < total ? " · " + shown + "-i göstərilir" : "")
                : (shown < total ? "İlk " + shown + " sual göstərilir" : "Tapılan suallar")) + "</div>" +
            rows + more;
        }

        on("bMore", "click", function () {
          var mb = $("bMore");
          if (mb) { mb.disabled = true; mb.textContent = "Yüklənir…"; }
          BOFF += 50;
          loadBank(true);
        });
        Array.prototype.forEach.call(box.querySelectorAll("[data-q]"), function (b) {
          if (b.dataset.bound) return;
          b.dataset.bound = "1";
          b.addEventListener("click", function () {
            nav("#/q/" + b.getAttribute("data-q"));
          });
        });
      })
      .catch(function (e) {
        if (!live() || my !== BSEQ) return;
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

  /* ------------------------------------------ alt naviqasiya (mobil)
     Telefonda bes esas bolme bir toxunusdadir; masaustunde gorunmur.
     Panel yalniz daxil olmus ve hesabi qurulmus istifadecide cixir. */
  /* Zeng - siqnallar ustluk duymesi (nokteli isare = yeni siqnal var) */
  var btnBell = document.createElement("button");
  btnBell.id = "btnBell";
  btnBell.className = "bellbtn hide";
  btnBell.title = "Bildirişlər";
  btnBell.setAttribute("aria-label", "Bildirişlər");
  btnBell.innerHTML = ic("bell") + '<i id="bellDot" class="hide"></i>';
  topWho.parentNode.insertBefore(btnBell, topWho);
  btnBell.addEventListener("click", function () { nav("#/n"); });
  function bellDot(n) {
    var d = $("bellDot");
    if (d) d.classList.toggle("hide", !(Number(n) > 0));
  }

  var bnav = document.createElement("nav");
  bnav.id = "bnav";
  bnav.className = "bnav";
  document.body.appendChild(bnav);
  var BNAV = [
    ["",    "home",   "İcmal"],
    ["b",   "doc",    "Bank"],
    ["gen", "gen",    "Test yığ"],
    ["p",   "star",   "Paket"],
    ["me",  "person", "Profil"]
  ].filter(function (it) {
    return it[0] !== "p" || !!(window.CFG && window.CFG.SHOW_PLANS);
  });
  function bnavShow(cur) {
    bnav.innerHTML = BNAV.map(function (it) {
      return '<a href="#/' + it[0] + '"' +
        (cur === it[0] ? ' class="on"' : "") + ">" +
        ic(it[1]) + "<span>" + it[2] + "</span></a>";
    }).join("");
    document.body.classList.add("bnav-on");
    btnBell.classList.remove("hide");
  }
  function bnavHide() {
    bnav.innerHTML = "";
    document.body.classList.remove("bnav-on");
    btnBell.classList.add("hide");
  }

  function route() {
    if (!ACC) { bnavHide(); screenSetup(); return; }
    var m = (location.hash || "#/").replace(/^#/, "").split("/").filter(Boolean);
    /*  "Yeni test yig" niyyeti yalniz generator ekraninda yasayir.
        Muellim oradan basqa yere kecirse niyyet de silinir - yoxsa
        sonra adi "Test yig"dan girende gozlenilmeden tapsiriq
        ekranina atilardi.  Suzgec deyisiklikleri screenGen()-i
        birbasa cagirir, ora dusmur. */
    if (GF && m[0] !== "gen") { GF.back = ""; GF.backName = ""; }
    if (m[0] !== "me" && m[0] !== "adm") FB_FROM = FB_PAGE[m[0] || ""] || (m[0] || "İcmal");
    //  "Geri" geldiyi yere qaytarsin deye evvelki unvan yadda saxlanir
    if ((location.hash || "#/") !== CUR_HASH) { PREV_HASH = CUR_HASH; CUR_HASH = location.hash || "#/"; }
    bnavShow({ b: "b", gen: "gen", p: "p", me: "me" }[m[0]] || "");
    if (m[0] === "g" && m[1]) return screenGroup(m[1]);
    if (m[0] === "r" && m[1]) return screenReport(m[1]);
    if (m[0] === "a" && m[1]) return screenAssign(m[1], m[2]);
    if (m[0] === "b") return screenBank();
    if (m[0] === "gen") return screenGen();
    if (m[0] === "t" && m[1]) return screenPaper(m[1]);
    //  gizli olanda unvanla da acilmir - ana sehifeye qaytarilir
    if (m[0] === "p") return plansOn() ? screenPaket() : nav("#/");
    if (m[0] === "adm") return screenAdmin();
    if (m[0] === "me") return screenMe();
    if (m[0] === "n") return screenNotif();
    if (m[0] === "q" && m[1]) return screenQuestion(m[1]);
    if (m[0] === "s" && m[1] && m[2]) return screenStudent(m[1], m[2]);
    screenHome();
  }

  window.addEventListener("hashchange", function () {
    if (sb.session() && CTX) route();
  });

  /* Ustlukdeki ad profil sehifesini acir */
  topWho.addEventListener("click", function () {
    if (sb.session() && CTX && ACC) nav("#/me");
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
      //  "son giris" - Idareetme ucun; server 15 deqiqede bir yazir
      sb.rpc("rpc_seen", {}).catch(function () {});
      //  zeng noktesi - hansi sehifeden acilmasindan asili olmadan
      if (ACC) sb.rpc("rpc_home", {}).then(function (v) {
        bellDot(v && v.alerts ? v.alerts.length : 0);
      }).catch(function () {});
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
