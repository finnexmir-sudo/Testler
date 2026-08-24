/* =====================================================================
   Sagird tetbiqi
   Axin: kod -> test siyahisi -> suallar -> netice -> muellime gonder

   Duzgun cavab bu kodda YOXDUR. Suallar rpc_start_attempt() ile
   cavabsiz gelir, bal rpc_submit_attempt() icinde SERVERDE hesablanir.
   Brauzerde saxtakarliq etmek mumkun deyil.
   ===================================================================== */
(function () {
  "use strict";

  var main = document.getElementById("main");
  var topBar = document.getElementById("topBar");
  var topTitle = document.getElementById("topTitle");
  var btnOut = document.getElementById("btnOut");

  var TOKEN = null;     // sagird sessiya tokeni
  var ME = null;        // {id, display_name}
  var CLS = null;       // {id, name}
  var S = null;         // aktiv cehd
  var busy = false;

  var LS = "sagird_ses";

  var ICON = {
    doc:   '<path d="M11 2.5H5.5A1.5 1.5 0 0 0 4 4v11a1.5 1.5 0 0 0 1.5 1.5h8A1.5 1.5 0 0 0 15 15V6.5L11 2.5z"/>' +
           '<path d="M11 2.5v4h4"/>',
    lock:  '<rect x="4.5" y="8.5" width="10" height="7" rx="1.6"/>' +
           '<path d="M7 8.5V6.4a2.5 2.5 0 0 1 5 0v2.1"/>',
    sound: '<path d="M4 7.5h2.5L10 4.5v10L6.5 11.5H4z"/><path d="M12.5 7a3.6 3.6 0 0 1 0 5"/>',
    check: '<path d="M4 10l3.6 3.6L15 5.8"/>',
    x:     '<path d="M5.5 5.5l8 8M13.5 5.5l-8 8"/>',
    info:  '<circle cx="9.5" cy="9.5" r="6.8"/><path d="M9.5 9v3.6"/><path d="M9.5 6.6h.01"/>',
    send:  '<path d="M16 3 8.5 10.5"/><path d="M16 3l-4.8 13-2.7-5.5L3 7.8 16 3z"/>',
    cup:   '<path d="M5.5 3.5h8v3a4 4 0 0 1-8 0v-3z"/><path d="M5.5 5H3.8v1.2A2.2 2.2 0 0 0 6 8.4"/>' +
           '<path d="M13.5 5h1.7v1.2A2.2 2.2 0 0 1 13 8.4"/><path d="M9.5 10.5v3"/><path d="M6.5 15.5h6"/>',
    back:  '<path d="M11.5 4.5 6 10l5.5 5.5"/>',
    right: '<path d="M7.5 4.5 13 10l-5.5 5.5"/>'
  };
  function ic(n, cls) {
    return '<svg class="' + (cls || "") + '" viewBox="0 0 19 19" fill="none" ' +
      'stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" ' +
      'aria-hidden="true">' + (ICON[n] || "") + "</svg>";
  }

  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function $(id) { return document.getElementById(id); }
  function show(html) { busy = false; stopSay(); main.innerHTML = html; window.scrollTo(0, 0); }
  function on(id, ev, fn) { var e = $(id); if (e) e.addEventListener(ev, fn); }
  function msg(kind, text) {
    var i = kind === "ok" ? "check" : "info";
    return '<div class="' + kind + '">' + ic(i) + "<span>" + esc(text) + "</span></div>";
  }
  function fail(e) {
    var t = (e && e.message) ? e.message : String(e);
    return t.replace(/^.*?:\s*/, "");
  }
  function setBusy(id, state, label) {
    var b = $(id);
    if (!b) return;
    busy = state;
    b.disabled = state;
    if (label) b.textContent = state ? "Gözləyin…" : label;
  }

  /* ------------------------------------------------------ seslendirme */
  /* Sual metni azerbaycancadir. Azerbaycan sesi nadir hallarda olur;
     turk sesi ingilis sesinden qat-qat anlasiqlidir - ona gore sira:
     az -> tr -> istenilen. */
  var VOICE = null;
  function pickVoice() {
    if (!("speechSynthesis" in window)) return;
    var v = [];
    try { v = speechSynthesis.getVoices() || []; } catch (e) { return; }
    var by = function (re) { return v.filter(function (x) { return re.test(x.lang || ""); })[0]; };
    /* YALNIZ az ve ya tr. Ingilis sesi azerbaycanca metni oxuyanda
       anlasilmaz cixir - o halda duyme umumiyyetle gosterilmir.
       Turk sesi az-a cox yaxindir, ona gore qebul edilir. */
    VOICE = by(/^az/i) || by(/^tr/i) || null;
    if (VOICE && document.getElementById("spk")) {
      document.getElementById("spk").classList.remove("hide");
    }
  }
  if ("speechSynthesis" in window) {
    pickVoice();
    /* Seslerin siyahisi gec yuklenir - hazir olanda duymeni acirig */
    speechSynthesis.onvoiceschanged = pickVoice;
  }
  function stopSay() { try { speechSynthesis.cancel(); } catch (e) {} }
  function say(text, btn) {
    if (!("speechSynthesis" in window) || !VOICE) return;
    stopSay();
    try {
      var u = new SpeechSynthesisUtterance(String(text));
      u.lang = VOICE ? VOICE.lang : "az-AZ";
      if (VOICE) u.voice = VOICE;
      u.rate = 0.92; u.volume = 1;
      if (btn) {
        btn.classList.add("on");
        u.onend = u.onerror = function () { btn.classList.remove("on"); };
      }
      setTimeout(function () { try { speechSynthesis.speak(u); } catch (e) {} }, 90);
    } catch (e) {}
  }

  /* ------------------------------------------------------ giris ekrani */
  function screenLogin(note) {
    topBar.classList.add("hide");
    show(
      '<div class="hero"><div class="mark">T</div>' +
        "<h1>Testə başla</h1>" +
        "<p>Müəllimin verdiyi kodu yaz.</p></div>" +
      '<div class="card" style="margin-top:18px">' +
        (note || "") +
        '<div id="lErr"></div>' +
        '<label for="code">Giriş kodu</label>' +
        '<input id="code" maxlength="10" autocomplete="off" autocorrect="off" ' +
          'autocapitalize="characters" spellcheck="false" placeholder="ABCD1234" ' +
          'inputmode="text" enterkeyhint="go">' +
        '<button class="btn go wide" id="btnIn">Daxil ol</button>' +
      "</div>" +
      '<p class="note" style="text-align:center;margin-top:16px">' +
        "Kodu itirmisənsə müəllimindən yenisini istə.</p>"
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
      sb.rpc("rpc_student_login", { p_code: code }).then(function (d) {
        if (!d || d.ok !== true) {
          setBusy("btnIn", false, "Daxil ol");
          $("lErr").innerHTML = msg("err", (d && d.error) || "Kod yanlışdır.");
          return;
        }
        TOKEN = d.token; ME = d.student; CLS = d.class;
        try { localStorage.setItem(LS, JSON.stringify({ t: TOKEN, m: ME, c: CLS })); } catch (e) {}
        screenTests();
      }).catch(function (e) {
        setBusy("btnIn", false, "Daxil ol");
        $("lErr").innerHTML = msg("err", fail(e));
      });
    }
  }

  /* --------------------------------------------------- test siyahisi */
  function screenTests() {
    topBar.classList.remove("hide");
    topTitle.textContent = ME ? ME.display_name : "Testlər";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');

    sb.rpc("rpc_student_tests", { p_token: TOKEN }).then(function (rows) {
      var h = "";
      if (CLS) {
        h += '<p class="note" style="margin-bottom:14px">Qrup: <b>' + esc(CLS.name) + "</b></p>";
      }
      h += "<h2>Testlər</h2>";
      if (!rows || !rows.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("doc") + "</div>" +
             "<b>Hələ test yoxdur</b>Müəllimin test əlavə etməsini gözlə.</div></div>";
      } else {
        h += '<div class="card pad0">' + rows.map(function (t, k) {
          var lock = !!t.locked;
          var done = Number(t.done) || 0;
          var full = !lock && t.max_attempts > 0 && done >= t.max_attempts;
          return '<button class="test' + (lock ? " lock" : "") + (full ? " lock" : "") +
            '" data-t="' + esc(t.id) + '"' + ((lock || full) ? " disabled" : "") + ">" +
            '<div class="ic">' + ic((lock || full) ? "lock" : (done ? "check" : "doc")) + "</div>" +
            '<div class="g"><b>' + esc(t.title) + "</b><i>" +
              "<span>" + esc(t.subject || "") + "</span><span>·</span>" +
              "<span>" + (t.questions || 0) + " sual</span>" +
              (lock ? "<span>·</span><span>abunə lazımdır</span>" : "") +
              (full ? "<span>·</span><span>cəhd bitib</span>" : "") +
            "</i></div>" +
            (done ? '<span class="best">' + Math.round(t.best) + "%</span>" : "") +
            ((lock || full) ? "" : '<span class="arrow">' + ic("right") + "</span>") + "</button>";
        }).join("") + "</div>";
      }
      show(h);
      Array.prototype.forEach.call(main.querySelectorAll("[data-t]"), function (b) {
        b.addEventListener("click", function () { startTest(b.getAttribute("data-t")); });
      });
    }).catch(onSessionError);
  }

  /* ---------------------------------------------------------- test */
  function startTest(testId) {
    show('<div class="card"><div class="skel">Test hazırlanır…</div></div>');
    sb.rpc("rpc_start_attempt", { p_token: TOKEN, p_test_id: testId })
      .then(function (d) {
        S = {
          attempt: d.attempt_id, test: d.test,
          qs: d.questions || [], i: 0, answers: {}
        };
        if (!S.qs.length) { show(msg("warn", "Bu testdə hələ sual yoxdur.")); return; }
        drawQuestion();
      })
      .catch(function (e) {
        show(msg("err", fail(e)) +
          '<button class="btn wide" id="btnBack2">Testlərə qayıt</button>');
        on("btnBack2", "click", screenTests);
      });
  }

  function drawQuestion() {
    var q = S.qs[S.i];
    var n = S.qs.length;
    var pct = Math.round((S.i) * 100 / n);
    topTitle.textContent = S.test.title;

    var picked = S.answers[q.id];

    show(
      '<div class="prog"><div class="bar"><i style="width:' + pct + '%"></i></div>' +
        '<span class="cnt">' + (S.i + 1) + " / " + n + "</span></div>" +
      '<div class="q"><div class="body">' + esc(q.body) + "</div>" +
        '<button class="spk' + (VOICE ? "" : " hide") + '" id="spk" ' +
          'title="Sualı dinlə" aria-label="Sualı dinlə">' + ic("sound") + "</button>" +
      "</div>" +
      '<div class="opts" id="opts">' +
        (q.options || []).map(function (o, k) {
          return '<button class="opt' + (o.id === picked ? " sel" : "") + '" ' +
            'data-o="' + esc(o.id) + '">' +
            '<span class="k">' + "ABCDEF".charAt(k) + "</span>" +
            '<span class="t">' + esc(o.body) + "</span></button>";
        }).join("") +
      "</div>" +
      '<div class="spacer"></div>' +
      '<button class="btn go wide" id="btnNext"' + (picked ? "" : " disabled") + ">" +
        (S.i + 1 >= n ? "Testi bitir" : "Növbəti sual") + "</button>"
    );

    on("spk", "click", function () { say(q.body, $("spk")); });

    Array.prototype.forEach.call(main.querySelectorAll("[data-o]"), function (b) {
      b.addEventListener("click", function () {
        Array.prototype.forEach.call(main.querySelectorAll("[data-o]"), function (x) {
          x.classList.remove("sel");
        });
        b.classList.add("sel");
        S.answers[q.id] = b.getAttribute("data-o");
        var nx = $("btnNext");
        if (nx) nx.disabled = false;
      });
    });

    /* Geri qayidib cavabi deyismek olar - onceki suala kec */
    if (S.i > 0) {
      var back = document.createElement("button");
      back.className = "btn ghost wide";
      back.id = "btnPrev";
      back.textContent = "Əvvəlki sual";
      main.appendChild(back);
      back.addEventListener("click", function () { S.i--; drawQuestion(); });
    }

    on("btnNext", "click", function () {
      if (busy) return;
      if (!S.answers[q.id]) return;
      if (S.i + 1 >= S.qs.length) finish();
      else { S.i++; drawQuestion(); }
    });
  }

  function finish() {
    setBusy("btnNext", true, "Testi bitir");
    var payload = S.qs.map(function (q) {
      return { q: q.id, o: S.answers[q.id] ? [S.answers[q.id]] : [] };
    });
    sb.rpc("rpc_submit_attempt", {
      p_token: TOKEN, p_attempt_id: S.attempt, p_answers: payload
    }).then(screenResult).catch(function (e) {
      setBusy("btnNext", false, "Testi bitir");
      show(msg("err", fail(e)) + '<button class="btn wide" id="btnBack3">Testlərə qayıt</button>');
      on("btnBack3", "click", screenTests);
    });
  }

  /* --------------------------------------------------------- netice */
  function screenResult(r) {
    var pct = Math.round(Number(r.percent) || 0);
    var C = 2 * Math.PI * 58;
    var dash = (C * pct / 100).toFixed(1) + " " + C.toFixed(1);
    var passed = !!r.passed;
    S.result = r;

    topTitle.textContent = "Nəticə";
    show(
      '<div class="card"><div class="score">' +
        '<div class="ring' + (passed ? " pass" : "") + '">' +
          '<svg viewBox="0 0 132 132"><circle class="track" cx="66" cy="66" r="58" ' +
            'fill="none" stroke-width="9"/>' +
            '<circle class="fill" cx="66" cy="66" r="58" fill="none" stroke-width="9" ' +
            'stroke-dasharray="' + dash + '"/></svg>' +
          '<span class="val">' + pct + "<s>%</s></span></div>" +
        '<div class="lbl">' + r.score + " / " + r.max_score + " düzgün</div>" +
        '<div class="sub">' + fmtTime(r.duration_sec) + " · " +
          (passed ? "Keçdin, afərin" : "Bir də cəhd edə bilərsən") + "</div>" +
      "</div></div>" +

      '<div class="ok" style="margin-bottom:12px">' + ic("check") +
        "<span>Nəticə yadda saxlanıldı. Müəllimin onu panelində görür.</span></div>" +
      '<div class="row"><button class="btn go" id="btnHome" style="flex:1">Testlər</button>' +
        '<button class="btn" id="btnLb" style="flex:1">' + ic("cup") + "Lövhə</button></div>" +

      ((r.wrong && r.wrong.length)
        ? "<h2>Səhv suallar</h2><div class=\"card pad0\">" + r.wrong.map(function (w) {
            return '<div class="wrong"><b>' + esc(w.body) + "</b>" +
              (w.explanation ? "<i>" + esc(w.explanation) + "</i>" : "") + "</div>";
          }).join("") + "</div>"
        : '<div class="ok" style="margin-top:16px">' + ic("check") +
          "<span>Bütün suallara düzgün cavab verdin.</span></div>")
    );

    on("btnHome", "click", screenTests);
    on("btnLb", "click", function () { screenBoard(); });
  }

  function fmtTime(sec) {
    sec = Math.max(0, parseInt(sec, 10) || 0);
    var m = Math.floor(sec / 60), s = sec % 60;
    return m ? (m + " dəq " + s + " san") : (s + " san");
  }

  /* ---------------------------------------------------------- lovhe */
  function screenBoard() {
    topTitle.textContent = "Lövhə";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_leaderboard", { p_token: TOKEN, p_test_id: S.test.id })
      .then(function (rows) {
        var h = '<button class="btn sm ghost" id="btnB">' + ic("back") + "Geri</button>" +
                '<div class="spacer"></div>';
        if (!rows || !rows.length) {
          h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("cup") +
               "</div><b>Lövhə boşdur</b>Bu testi hələ kimsə işləməyib.</div></div>";
        } else {
          h += '<div class="card pad0">' + rows.map(function (x) {
            return '<div class="lb' + (x.is_me ? " me" : "") + '">' +
              '<span class="rk">' + x.rank + "</span>" +
              '<span class="nm">' + esc(x.name) +
                (x.tries > 1 ? ' <s>' + x.tries + " cəhd</s>" : "") + "</span>" +
              '<span class="pc">' + Math.round(x.percent) + "%</span></div>";
          }).join("") + "</div>";
        }
        show(h);
        on("btnB", "click", function () { screenResult(S.result); });
      })
      .catch(function (e) { show(msg("err", fail(e))); });
  }

  /* ----------------------------------------------------------- boot */
  function onSessionError(e) {
    if (e && (e.status === 403 || /Sessiya/i.test(e.message || ""))) {
      logout("Sessiya bitdi. Kodu bir də yaz.");
      return;
    }
    show(msg("err", fail(e)));
  }

  function logout(note) {
    TOKEN = null; ME = null; CLS = null; S = null;
    try { localStorage.removeItem(LS); } catch (e) {}
    screenLogin(note ? msg("warn", note) : "");
  }

  btnOut.addEventListener("click", function () { logout(); });

  function boot() {
    if (!window.CFG || !window.CFG.SUPABASE_URL || !window.CFG.SUPABASE_ANON_KEY) {
      show(msg("err", "config.js doldurulmayıb."));
      return;
    }
    var saved = null;
    try { saved = JSON.parse(localStorage.getItem(LS) || "null"); } catch (e) {}
    if (saved && saved.t) {
      TOKEN = saved.t; ME = saved.m; CLS = saved.c;
      screenTests();
    } else {
      screenLogin();
    }
  }

  boot();
})();
