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
  var btnBack = document.getElementById("btnBack");   // ust zolaqda «Geri» - ev ekranindan basqa

  var TOKEN = null;     // sagird sessiya tokeni
  var ME = null;        // {id, display_name}
  var CLS = null;       // {id, name}
  var S = null;         // aktiv cehd
  var ON_HOME = true;   // brauzerin "geri" duymesi tetbiqden CIXMASIN
  var busy = false;

  var LS = "sagird_ses";

  /* ================================================================
     CAVAB QARALAMASI
     Internet kesilse, telefon sonse, brauzer sehifeni atsa - secilmis
     cavablar itmesin.  Her secimden sonra localStorage-e yazilir;
     eyni cehd yeniden acilanda geri qaytarilir.
     Server tərəfinde HEC NE deyismir - bu, yalniz brauzerdedir.
     Bal yene serverdə hesablanir, duzgun cavab burada yoxdur.
     ================================================================ */
  var LSD = "sagird_qaralama";
  var DGUN = 2;          // qaralama omru - gun
  var DMAX = 5;          // en cox saxlanilan cehd sayi

  function draftAll() {
    try {
      var o = JSON.parse(localStorage.getItem(LSD) || "{}");
      return (o && typeof o === "object" && !Array.isArray(o)) ? o : {};
    } catch (e) { return {}; }
  }

  //  Kohnelmis ve hedden artiq qaralamalar atilir - yer dolmasin
  function draftPrune(o) {
    var hedd = Date.now() - DGUN * 86400000;
    var k, list = [];
    for (k in o) {
      if (!Object.prototype.hasOwnProperty.call(o, k)) continue;
      var d = o[k];
      if (!d || typeof d !== "object" || !(Number(d.at) > hedd)) { delete o[k]; continue; }
      list.push([k, Number(d.at)]);
    }
    if (list.length > DMAX) {
      list.sort(function (a, b) { return b[1] - a[1]; });
      list.slice(DMAX).forEach(function (x) { delete o[x[0]]; });
    }
    return o;
  }

  function draftSave() {
    if (!S || !S.attempt || S.done) return;
    try {
      var o = draftPrune(draftAll());
      o[S.attempt] = { i: S.i, ans: S.answers, at: Date.now() };
      localStorage.setItem(LSD, JSON.stringify(o));
    } catch (e) { /* yer yoxdursa sakit kec - test yene isleyir */ }
  }

  //  Qaralama YALNIZ eyni cehde aiddir (attempt id uuid-dir, qarismir)
  function draftLoad(attempt) {
    var d = draftAll()[attempt];
    if (!d || !d.ans || typeof d.ans !== "object") return null;
    return d;
  }

  function draftClear(attempt) {
    try {
      var o = draftAll();
      delete o[attempt];
      localStorage.setItem(LSD, JSON.stringify(o));
    } catch (e) {}
  }

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
    if (/failed to fetch|networkerror|load failed/i.test(t)) {
      return "İnternet bağlantısı yoxdur. Yenidən cəhd et.";
    }
    return t.replace(/^.*?:\s*/, "");
  }

  /* Xeta ekrani: yeniden cehd + testlere qayit.
     Sebeke kesintisinde ekran dalana direnmemelidir. */
  function errScreen(e, retry) {
    show(msg("err", fail(e)) +
      '<button class="btn go wide" id="btnRetry">Yenidən cəhd et</button>' +
      '<div class="spacer"></div>' +
      '<button class="btn wide" id="btnHome2">Testlərə qayıt</button>');
    on("btnRetry", "click", function () { retry(); });
    on("btnHome2", "click", screenTests);
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
    markScreen(true);
    topBar.classList.add("hide");
    show(
      '<div class="hero"><div class="mark"><svg viewBox="0 0 32 32" aria-hidden="true"><defs><linearGradient id="lgQ" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2b4acb"/><stop offset="1" stop-color="#0e9384"/></linearGradient></defs><path d="M12.5 3.5 H18 A8.4 8.4 0 0 1 26.4 11.9 A8.4 8.4 0 0 1 18 20.3 H13.1 L8.3 24.6 Q7.1 25.6 7.1 24 V19.1 A8.4 8.4 0 0 1 4.1 11.9 A8.4 8.4 0 0 1 12.5 3.5 Z" fill="url(#lgQ)"/><g fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round"><path d="M10.2 10.2 12.5 8.4 V16"/><ellipse cx="18.4" cy="12" rx="3.1" ry="4.1"/></g><path d="M22.5 19.5 h4.2 a3.6 3.6 0 0 1 3.6 3.6 a3.6 3.6 0 0 1-3.6 3.6 h-1 l2 3.4 -4.6-3.5 a3.6 3.6 0 0 1-4.2-3.5 a3.6 3.6 0 0 1 3.6-3.6 Z" fill="#ffc94d"/><path d="M23.4 23.2 l1.5 1.5 2.6-3" fill="none" stroke="#1a2233" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/></svg></div>' +
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
        "Kodu itirmisənsə müəllimindən yenisini istə.</p>" +
      '<p class="note" style="text-align:center;margin-top:10px">' +
        '<a href="../" class="homelink">← Bil10 ana səhifəsi</a> · ' +
        '<a href="../komek/#sagird" class="helplink">Necə işləyir?</a></p>'
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

  /* Bir test setri. isAsg = muellimin tapsirigidir (son tarix gorunur). */
  function testRow(t, isAsg) {
    var lock = !!t.locked;
    var done = Number(t.done) || 0;
    var lim  = Number(t.max_attempts) || 0;
    /* Cehd bitibse test acilmir - neticeye baxmaq olur.
       Serverde de eyni limit var; bura yalniz gorunusdur. */
    var over = !lock && done > 0 && lim > 0 && done >= lim;
    var left = !lock && !over && lim > 0 && done > 0 ? lim - done : 0;
    return '<button class="test' + (lock ? " lock" : "") + (over ? " done" : "") +
      (isAsg ? " asg" : "") +
      '" data-t="' + esc(t.id) + '" data-mode="' + (over ? "view" : "start") + '"' +
      (lock ? " disabled" : "") + ">" +
      '<div class="ic">' + ic(lock ? "lock" : (over ? "check" : "doc")) + "</div>" +
      '<div class="g"><b>' + esc(t.title) +
        //  Yalniz bu sagirde verilib - qrupun qalani gormur
        (t.personal ? '<span class="solo">sənə</span>' : "") + "</b><i>" +
        "<span>" + esc(t.subject || "") + "</span><span>·</span>" +
        "<span>" + (t.questions || 0) + " sual</span>" +
        (isAsg && t.closes_at ? dueSpan(t.closes_at) : "") +
        (left > 0 ? "<span>·</span><span>" + left + " cəhd qalıb</span>" : "") +
        (lock ? "<span>·</span><span>abunə lazımdır</span>" : "") +
        (over ? "<span>·</span><span>işlənib — toxun, nəticəni gör</span>" : "") +
      "</i></div>" +
      (done ? '<span class="best ' + pctCls(t.best) + '">' +
        Math.round(t.best) + "%</span>" : "") +
      (lock ? "" : '<span class="arrow">' + ic("right") + "</span>") + "</button>";
  }

  /* Faiz uzre reng sinfi: >=80 yasil, >=60 narinci, alti qirmizi */
  function pctCls(p) {
    var n = Number(p) || 0;
    return n >= 80 ? "bh" : (n >= 60 ? "bm" : "bl");
  }

  /* Son tarix + qalan gun: yaxinlasanda qirmizi xeberdarliq */
  function dueSpan(iso) {
    var gun = Math.ceil((new Date(iso).getTime() - Date.now()) / 864e5);
    var t = "son tarix " + esc(dateAz(iso));
    if (gun > 0 && gun <= 7) t += " · " + gun + " gün qaldı";
    return "<span>·</span><span" + (gun <= 2 ? ' class="due"' : "") + ">" +
      t + "</span>";
  }

  /* Son tarix: "4 okt" */
  function dateAz(iso) {
    if (!iso) return "";
    var d = new Date(iso);
    if (isNaN(d)) return "";
    var ay = ["yan","fev","mar","apr","may","iyn","iyl","avq","sen","okt","noy","dek"];
    return d.getDate() + " " + ay[d.getMonth()];
  }

  function screenTests() {
    markScreen(true);
    topBar.classList.remove("hide");
    topTitle.textContent = ME ? ME.display_name : "Testlər";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');

    sb.rpc("rpc_student_tests", { p_token: TOKEN }).then(function (d) {
      d = d || {};
      var asg  = d.assigned || [];
      var prac = d.practice || [];

      /* Salamlama + kicik gostericiler - "ireliledigimi gorurem" hissi */
      var worked = asg.concat(prac).filter(function (t) {
        return Number(t.done) > 0;
      });
      var avg = 0;
      worked.forEach(function (t) { avg += Number(t.best) || 0; });
      avg = worked.length ? Math.round(avg / worked.length) : 0;

      /* Dovamlilik: bugun/dunen bir sey yazilmayibsa server 0 qaytarir -
         "3 gundur ardıcılsan" kimi yalan motivasiya olmasin. 2-den az
         gostermirik, 1 gunluk "ardıcıllıq" hec neyi bildirmir. */
      var streakTxt = Number(d.streak) >= 2
        ? " · 🔥 " + Number(d.streak) + " gün ardıcıl" : "";

      var h = '<div class="shero">' + av(ME ? ME.display_name : "?") +
        "<div><b>Salam, " + esc(ME ? ME.display_name : "") + "! 👋</b>" +
        (CLS ? "<i>" + esc(CLS.name) + streakTxt + "</i>" : "") + "</div></div>";
      if (worked.length) {
        h += '<div class="stiles">' +
          '<div class="st a"><b>' + worked.length +
            "</b><span>işlənmiş test</span></div>" +
          '<div class="st b"><b>' + avg + "%</b><span>ortalama</span></div>" +
          '<button class="st c" id="btnMyRes"><b>' + ic("cup") + "</b>" +
            "<span>nəticələrim</span></button>" +
        "</div>";
        if (d.best != null) {
          h += '<p class="beststat">🏆 Ən yüksək nəticən: <b>' +
            Math.round(d.best) + "%</b></p>";
        }
      }

      /* Novbeti ders: muellim ekranindaki "NOVBETI DERS" kartinin eynisi -
         yalniz baxmaq ucundur, klik olunmur. */
      if (d.next_lesson) {
        h += '<div class="card tight nlesson"><span class="nl-tag">Növbəti dərs</span>' +
          "<b>" + esc(d.next_lesson.topic) + "</b>" +
          (d.next_lesson.subject ? "<i>" + esc(d.next_lesson.subject) + "</i>" : "") +
          "</div>";
      }

      /* 1. Muellimin verdiyi tapsiriqlar - hemise yuxarida */
      h += "<h2>Tapşırıqlar</h2>";
      if (!asg.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' + ic("check") +
             "</div><b>Tapşırıq yoxdur</b>" +
             (prac.length ? "Aşağıdakı testlərlə məşq edə bilərsən."
                          : "Müəllimin tapşırıq verməsini gözlə.") + "</div></div>";
      } else {
        h += '<div class="card pad0">' + asg.map(function (t) {
          return testRow(t, true);
        }).join("") + "</div>";
      }

      /* 2. Serbest mesq - muellim baglaya biler */
      if (prac.length) {
        h += '<div class="spacer"></div><h2>Sərbəst məşq</h2>' +
             '<div class="card pad0">' + prac.map(function (t) {
               return testRow(t, false);
             }).join("") + "</div>";
      }

      /* 3. Zeif movzular - haradan basla, konkret cavab.  .myr/.best
         siniflerini "netcelerim" siyahisindan goturur, yeni CSS lazim
         deyil.  Faiz hemise <60 oldugu ucun rengi hemise qirmizidir. */
      if (d.weak && d.weak.length) {
        h += '<div class="spacer"></div><h2>Zəif mövzular</h2>' +
          '<div class="card pad0">' + d.weak.map(function (w) {
            return '<div class="myr"><div class="g"><b>' + esc(w.topic) + "</b>" +
              "<i>" + esc(w.subject) + "</i></div>" +
              '<span class="best bl">' + Math.round(w.percent) + "%</span></div>";
          }).join("") + "</div>";
      }

      /* 4. Kecdiyi dersler - "novbeti ders" hara gedirik deyir, bu
         hardan geldik.  Ən çoxu 5, ən yenisi əvvəl. */
      if (d.lessons && d.lessons.length) {
        h += '<div class="spacer"></div><h2>Keçdiyi dərslər</h2>' +
          '<div class="card pad0">' + d.lessons.map(function (l) {
            return '<div class="myr"><div class="g"><b>' + esc(l.topic) + "</b>" +
              "<i>" + esc(l.subject) + "</i></div>" +
              '<span class="at">' + dateAz(l.at) + "</span></div>";
          }).join("") + "</div>";
      }

      show(h);
      on("btnMyRes", "click", screenMyResults);
      Array.prototype.forEach.call(main.querySelectorAll("[data-t]"), function (b) {
        b.addEventListener("click", function () {
          var id = b.getAttribute("data-t");
          if (b.getAttribute("data-mode") === "view") viewResult(id);
          else startTest(id);
        });
      });
    }).catch(function (e) {
      if (e && (e.status === 403 || /Sessiya/i.test(e.message || ""))) {
        logout("Sessiya bitdi. Kodu bir də yaz.");
        return;
      }
      errScreen(e, screenTests);
    });
  }

  /* ---------------------------------------------------------- test */
  function startTest(testId) {
    markScreen(false);
    show('<div class="card"><div class="skel">Test hazırlanır…</div></div>');
    sb.rpc("rpc_start_attempt", { p_token: TOKEN, p_test_id: testId })
      .then(function (d) {
        S = {
          attempt: d.attempt_id, test: d.test,
          qs: d.questions || [], i: 0, answers: {}
        };
        if (!S.qs.length) { show(msg("warn", "Bu testdə hələ sual yoxdur.")); return; }
        //  Yarimciq qalmis eyni cehd varsa cavablar geri qaytarilir.
        //  Yalniz HEMIN testin suallarina aid cavablar goturulur.
        var d0 = draftLoad(S.attempt);
        if (d0) {
          var mine = {}, n = 0;
          S.qs.forEach(function (q) {
            if (d0.ans[q.id]) { mine[q.id] = d0.ans[q.id]; n++; }
          });
          if (n) {
            S.answers = mine;
            S.i = Math.min(Math.max(Number(d0.i) || 0, 0), S.qs.length - 1);
            S.restored = n;
          }
        }
        drawQuestion();
      })
      .catch(function (e) { errScreen(e, function () { startTest(testId); }); });
  }

  /* Bitmis testin neticesi - yeni cehd acilmir */
  function viewResult(testId) {
    markScreen(false);
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_test_result", { p_token: TOKEN, p_test_id: testId })
      .then(function (r) {
        S = { test: r.test, attempt: r.attempt_id, done: true };
        screenResult(r, true);
      })
      .catch(function (e) { errScreen(e, function () { viewResult(testId); }); });
  }

  function drawQuestion() {
    var q = S.qs[S.i];
    var n = S.qs.length;
    var pct = Math.round((S.i) * 100 / n);
    topTitle.textContent = S.test.title;

    var picked = S.answers[q.id];

    //  Qaralamadan qayidib: bir defe bildiris goster, sonra sondur
    var rest = "";
    if (S.restored) {
      rest = '<div class="ok restored">' + ic("check") + "<span>Əvvəlki " +
        S.restored + " cavabınız qaytarıldı — davam edin.</span></div>";
      S.restored = 0;
    }

    show(
      '<div class="prog"><div class="bar"><i style="width:' + pct + '%"></i></div>' +
        '<span class="cnt">' + (S.i + 1) + " / " + n + "</span></div>" + rest +
      '<div class="q"><div class="body">' + esc(q.body) + "</div>" +
        '<button class="spk' + (VOICE ? "" : " hide") + '" id="spk" ' +
          'title="Sualı dinlə" aria-label="Sualı dinlə">' + ic("sound") + "</button>" +
      "</div>" +
      (q.kind === "text"
        ? '<div class="opts"><input id="ans" class="tans" maxlength="120" ' +
            'autocomplete="off" placeholder="Cavabı yaz" value="' +
            esc(picked || "") + '"></div>'
        : '<div class="opts" id="opts">' +
            (q.options || []).map(function (o, k) {
              return '<button class="opt' + (o.id === picked ? " sel" : "") + '" ' +
                'data-o="' + esc(o.id) + '">' +
                '<span class="k">' + "ABCDEF".charAt(k) + "</span>" +
                '<span class="t">' + esc(o.body) + "</span></button>";
            }).join("") +
          "</div>") +
      /* Sual xeritesi: hansi cavablanib, hansi yox - klikle kecid.
         Sagird sonda cavabsiz qalani buradan tapir. */
      '<div class="qnav" id="qnav">' +
        S.qs.map(function (x, k) {
          return '<button data-j="' + k + '" class="' +
            (k === S.i ? "cur" : (S.answers[x.id] ? "done" : "")) +
            '" aria-label="Sual ' + (k + 1) + '">' + (k + 1) + "</button>";
        }).join("") + "</div>" +
      '<div class="spacer"></div>' +
      /* Cavabsiz da kecmek olar - bilmediyi sualda ilisib qalmasin.
         Bitirmek AYRI duymedir: "Növbəti" hec vaxt testi bitirmir. */
      (S.i + 1 < n
        ? '<button class="btn ' + (picked ? "go" : "") + ' wide" id="btnNext">' +
            (picked ? "Növbəti sual" : "Bilmirəm, keç") + "</button>"
        : "") +
      '<button class="btn wide ' + (S.i + 1 >= n ? "go" : "ghost") +
        '" id="btnFinish">Testi bitir</button>'
    );

    on("spk", "click", function () { say(q.body, $("spk")); });

    /* Yazili sual: yazdiqca saxlanilir, duymenin adi da deyisir */
    on("ans", "input", function () {
      var v = ($("ans").value || "").trim();
      if (v) S.answers[q.id] = v; else delete S.answers[q.id];
      draftSave();
      var nx = $("btnNext");
      if (nx) {
        nx.classList.toggle("go", !!v);
        nx.textContent = v ? "Növbəti sual" : "Bilmirəm, keç";
      }
      markNav(v);
    });

    Array.prototype.forEach.call(main.querySelectorAll("[data-o]"), function (b) {
      b.addEventListener("click", function () {
        Array.prototype.forEach.call(main.querySelectorAll("[data-o]"), function (x) {
          x.classList.remove("sel");
        });
        b.classList.add("sel");
        S.answers[q.id] = b.getAttribute("data-o");
        draftSave();
        var nx = $("btnNext");
        if (nx) { nx.classList.add("go"); nx.textContent = "Növbəti sual"; }
        markNav(true);
      });
    });

    /* Geri qayidib cavabi deyismek olar - onceki suala kec */
    if (S.i > 0) {
      var back = document.createElement("button");
      back.className = "btn ghost wide";
      back.id = "btnPrev";
      back.textContent = "Əvvəlki sual";
      main.appendChild(back);
      back.addEventListener("click", function () { S.i--; draftSave(); drawQuestion(); });
    }

    on("btnNext", "click", function () {
      if (busy) return;
      S.i++; draftSave(); drawQuestion();
    });

    on("btnFinish", "click", function () {
      if (busy) return;
      /* Bitirmeden EVVEL xeberdarliq: cavabsiz sual varsa geri
         qayidib baxmaq olar - tesadufen bitirmesin. */
      var bos = S.qs.filter(function (x) { return !S.answers[x.id]; }).length;
      if (bos > 0 && !confirm(
            bos + " sual cavabsız qalıb.\n\nTesti indi bitirmək istəyirsən?\n" +
            "«Ləğv et» desən geri qayıdıb baxa bilərsən.")) return;
      finish();
    });

    on("qnav", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-j]") : null;
      if (!b || busy) return;
      S.i = Number(b.getAttribute("data-j"));
      draftSave();
      drawQuestion();
    });
  }

  /* Hazirki sualin xeritedeki xanasini yenileyir - tam yeniden
     cizmeden.  Xana "cur" qalir; cavab varsa "done" de elave olunur. */
  function markNav(hasAns) {
    var c = document.querySelector('#qnav [data-j="' + S.i + '"]');
    if (c) c.classList.toggle("done", !!hasAns);
  }

  function finish() {
    setBusy("btnFinish", true, "Testi bitir");
    var payload = S.qs.map(function (q) {
      var a = S.answers[q.id];
      /* Yazili sualda cavab METNDIR, variant id-si deyil */
      if (q.kind === "text") return { q: q.id, t: a || "" };
      return { q: q.id, o: a ? [a] : [] };
    });
    sb.rpc("rpc_submit_attempt", {
      p_token: TOKEN, p_attempt_id: S.attempt, p_answers: payload
    }).then(function (r) {
      draftClear(S.attempt);      //  gonderildi - qaralama lazim deyil
      screenResult(r);
    }).catch(function (e) {
      setBusy("btnFinish", false, "Testi bitir");
      /* Cavablar hele gonderilmeyib - tekrar cehd eyni cehdi bitirir */
      errScreen(e, finish);
    });
  }

  /* --------------------------------------------------------- netice */
  function screenResult(r, review) {
    markScreen(false);
    var pct = Math.round(Number(r.percent) || 0);
    var C = 2 * Math.PI * 58;
    var dash = (C * pct / 100).toFixed(1) + " " + C.toFixed(1);
    var passed = !!r.passed;
    S.result = r;

    topTitle.textContent = "Nəticə";
    show(
      '<div class="card"><div class="score">' +
        '<div class="ring' +
          (passed ? " pass" : (pct >= 60 ? " mid" : " lo")) + '">' +
          '<svg viewBox="0 0 132 132"><circle class="track" cx="66" cy="66" r="58" ' +
            'fill="none" stroke-width="9"/>' +
            '<circle class="fill" cx="66" cy="66" r="58" fill="none" stroke-width="9" ' +
            'stroke-dasharray="' + dash + '"/></svg>' +
          '<span class="val">' + pct + "<s>%</s></span></div>" +
        '<div class="lbl">' + r.score + " / " + r.max_score + " düzgün</div>" +
        '<div class="sub">' + fmtTime(r.duration_sec) + " · " +
          (passed
            ? (r.can_retry ? "Keçdin, afərin — bir də cəhd edə bilərsən"
                           : "Keçdin, afərin")
            : (r.can_retry
                ? "Bir də cəhd edə bilərsən"
                : "Səhvlərinə bax və mövzunu təkrarla")) + "</div>" +
      "</div></div>" +

      (review
        ? '<div class="warn" style="margin-bottom:12px">' + ic("info") +
          "<span>Bu testi artıq işləmisən — yuxarıda nəticən, aşağıda isə " +
          "bütün suallar və cavabların var. Testi yenidən işləmək olmaz.</span></div>"
        : '<div class="ok" style="margin-bottom:12px">' + ic("check") +
          "<span>Nəticə yadda saxlanıldı. Müəllimin onu panelində görür.</span></div>") +
      '<div class="row"><button class="btn go" id="btnHome" style="flex:1">Testlər</button>' +
        '<button class="btn" id="btnLb" style="flex:1">' + ic("cup") + "Lövhə</button></div>" +

      ((r.questions && r.questions.length)
        ? "<h2>Suallar</h2>" +
          (r.questions.every(function (q) { return q.correct; })
            ? '<div class="ok" style="margin-bottom:12px">' + ic("check") +
              "<span>Bütün suallara düzgün cavab verdin.</span></div>"
            : "") +
          "<div class=\"card pad0\" id=\"wrongBox\">" +
          r.questions.map(function (w) {
            var right = !!w.correct;
            return '<div class="' + (right ? "right" : "wrong") + '">' +
              '<div class="qh"><b>' + esc(w.body) + "</b>" +
                '<span class="qmark ' + (right ? "y" : "n") + '">' +
                  ic(right ? "check" : "x") + "</span></div>" +
              (w.picked && w.picked.length
                ? '<p class="picked">Sən yazdın: ' + w.picked.map(esc).join(", ") + "</p>"
                : "") +
              (w.explanation ? "<i>" + esc(w.explanation) + "</i>" : "") +
              (right ? "" :
                '<button class="rlink" data-rq="' + esc(w.question_id || "") +
                  '">Sualda səhv var?</button>' +
                '<div class="rslot" id="rs-' + esc(w.question_id || "") + '"></div>') +
            "</div>";
          }).join("") + "</div>"
        : "")
    );

    on("btnHome", "click", screenTests);
    on("btnLb", "click", function () { screenBoard(review); });
    bindWrongReports();
  }

  /* Sualda sehv gorende sagird bir klikle bildirir.  Sual DEYISMIR -
     muellim/admin baxandan sonra duzeldilir.  Server yalniz sagirdin
     OZ gorduyu suali qebul edir. */
  function bindWrongReports() {
    var box = document.getElementById("wrongBox");
    if (!box) return;
    var RS = [["cavab", "Cavab səhvdir"], ["sert", "Sual qüsurludur"],
              ["yazi", "Yazı xətası"], ["diger", "Digər"]];
    box.addEventListener("click", function (ev) {
      var b = ev.target.closest ? ev.target.closest("button") : null;
      if (!b) return;
      var qid = b.getAttribute("data-rq");
      if (qid) {
        var slot = document.getElementById("rs-" + qid);
        if (!slot) return;
        slot.innerHTML = slot.innerHTML ? "" :
          '<div class="rfrm"><select class="rsel">' + RS.map(function (x) {
            return '<option value="' + x[0] + '">' + x[1] + "</option>";
          }).join("") + "</select>" +
          '<button class="btn sm" data-rsend="' + qid + '">Göndər</button></div>';
        return;
      }
      qid = b.getAttribute("data-rsend");
      if (qid) {
        var slot2 = document.getElementById("rs-" + qid);
        if (!slot2) return;
        b.disabled = true;
        sb.rpc("rpc_report_question_student", {
          p_token: TOKEN, p_question: qid,
          p_reason: (slot2.querySelector(".rsel") || {}).value || "diger",
          p_note: ""
        }).then(function () {
          slot2.innerHTML = '<div class="rok">Bildirildi — təşəkkürlər! 🙌</div>';
        }).catch(function () {
          slot2.innerHTML = '<div class="rok">Bildirilə bilmədi. Bir az sonra yenidən yoxla.</div>';
        });
      }
    });
  }

  /* Herf-avatar: muellim panelindeki ile eyni reng qaydasi */
  function av(name) {
    var n = String(name || "?").trim();
    var ch = n.charAt(0).toUpperCase() || "?";
    var k = 7;
    for (var i = 0; i < n.length; i++) k = (k * 31 + n.charCodeAt(i)) % 100003;
    return '<span class="av c' + (k % 6) + '">' + esc(ch) + "</span>";
  }

  function fmtTime(sec) {
    sec = Math.max(0, parseInt(sec, 10) || 0);
    var m = Math.floor(sec / 60), s = sec % 60;
    return m ? (m + " dəq " + s + " san") : (s + " san");
  }

  /* ---------------------------------------------------- neticelerim */
  /* Sagird oz gedisatini gorur: mini qrafik + son testler.  Yalniz OZ
     neticeleri - duzgun cavab ve basqa sagird melumati yoxdur. */
  function screenMyResults() {
    markScreen(false);
    topTitle.textContent = "Nəticələrim";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_student_my_results", { p_token: TOKEN }).then(function (rows) {
      rows = rows || [];
      var h = '<button class="btn sm ghost" id="btnB2">' + ic("back") +
        "Testlər</button>" + '<div class="spacer"></div>';
      if (!rows.length) {
        h += '<div class="card pad0"><div class="empty"><div class="ic">' +
          ic("doc") + "</div><b>Hələ nəticə yoxdur</b>" +
          "İlk testini işlə — burada görünəcək.</div></div>";
      } else {
        if (rows.length >= 2) {
          var bars = rows.slice(0, 12).slice().reverse();
          h += '<div class="card"><div class="dyn">' + bars.map(function (a) {
            var p = Math.max(6, Math.round(Number(a.percent) || 0));
            return '<i class="d' + pctCls(p).charAt(1) + '" style="height:' +
              p + '%"></i>';
          }).join("") + "</div>" +
          '<p class="note" style="margin:10px 0 0">Soldan sağa: köhnədən ' +
            "yeniyə. Yaşıl — əla, narıncı — orta, qırmızı — təkrar lazımdır.</p>" +
          "</div>" + '<div class="spacer"></div>';
        }
        h += '<div class="card pad0">' + rows.map(function (a) {
          var p = Math.round(Number(a.percent) || 0);
          return '<div class="myr"><div class="g"><b>' + esc(a.test) + "</b>" +
            "<i>" + dateAz(a.at) + " · " + a.score + " / " + a.max + "</i></div>" +
            '<span class="best ' + pctCls(p) + '">' + p + "%</span></div>";
        }).join("") + "</div>";
      }
      show(h);
      on("btnB2", "click", screenTests);
    }).catch(function (e) { errScreen(e, screenMyResults); });
  }

  /* ---------------------------------------------------------- lovhe */
  function screenBoard(review) {
    markScreen(false);
    topTitle.textContent = "Lövhə";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    sb.rpc("rpc_leaderboard", { p_token: TOKEN, p_test_id: S.test.id })
      .then(function (rows) {
        var h = '<button class="btn sm ghost" id="btnB">' + ic("back") + "Geri</button>" +
          '<div class="card tight" style="margin-top:12px">' +
            "<h1>" + esc(S.test ? S.test.title : "Lövhə") + "</h1>" +
            '<p class="muted" style="margin:6px 0 0">' +
              (CLS ? esc(CLS.name) + " qrupundan " : "") +
              "bu testi işləyənlər</p></div>";
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
        on("btnB", "click", function () { screenResult(S.result, review); });
      })
      .catch(function (e) { errScreen(e, function () { screenBoard(review); }); });
  }

  /* ----------------------------------------------------------- boot */
  function logout(note) {
    TOKEN = null; ME = null; CLS = null; S = null;
    try { localStorage.removeItem(LS); } catch (e) {}
    screenLogin(note ? msg("warn", note) : "");
  }

  /* Test yarimciq qalibsa cixis/senifelenme xeberdarliq verir.
     Yarimciq cehd serverde "in_progress" qalir ve geri qayidanda davam edir. */
  function testInProgress() {
    return !!(S && S.qs && S.qs.length && !S.done && !S.result);
  }

  btnOut.addEventListener("click", function () {
    if (testInProgress() &&
        !confirm("Test yarımçıqdır.\n\nÇıxsan cavabların göndərilməyəcək. " +
                 "Yenə də çıxmaq istəyirsən?")) return;
    logout();
  });

  window.addEventListener("beforeunload", function (e) {
    if (!testInProgress()) return;
    e.preventDefault();
    e.returnValue = "";
    return "";
  });

  /* Brauzerin "geri" duymesi: tetbiq hec bir sehife dəyişmir (SPA),
     ona gore brauzer tarixinde əlavə pilləmiz yoxdur - "geri" birbasa
     tetbiqden EVVELKI sehifeye (mes. bil10.az) aparirdi.  Netice
     ekranindan geri basanda butun tetbiqden cixmaq gozlənilməz idi.
     Həll: ev ekranindan (Testlər) uzaqlaşanda BİR defelik tarix
     pilləsi qururuq, "geri" o pilləni sındırıb yenidən Testlərə
     qayıdır - real sehifeden hec vaxt cixmir. */
  function markScreen(isHome) {
    //  Gorunen «Geri» duymesi: yalniz ev ekranindan uzaqda.  Istifadeci
    //  brauzer oxunu yox, sehifede duyme gozleyirdi - "hani geri duymesi?"
    if (btnBack) btnBack.classList.toggle("hide", isHome);
    if (isHome) { ON_HOME = true; return; }
    if (ON_HOME) {
      ON_HOME = false;
      history.pushState({ sagird: 1 }, "", location.href);
    }
  }

  window.addEventListener("popstate", function () {
    if (testInProgress() &&
        !confirm("Test yarımçıqdır.\n\nÇıxsan cavabların göndərilməyəcək. " +
                 "Yenə də çıxmaq istəyirsən?")) {
      history.pushState({ sagird: 1 }, "", location.href);   // "geri"ni ləğv et
      return;
    }
    ON_HOME = true;
    if (TOKEN) screenTests(); else screenLogin();
  });

  /* «Geri» duymesi brauzerin oxu ile EYNI yolu gedir (history.back ->
     popstate): tek kod yolu, tarix pillesi de duzgun sindirilir.  Test
     ortasinda eyni "yarimciq test" xeberdarligini verir. */
  if (btnBack) btnBack.addEventListener("click", function () {
    if (ON_HOME) return;
    history.back();
  });

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

  /* Loqo klik = testler siyahisi (girissizse giris ekrani) */
  (function () {
    var mk = document.querySelector(".mark");
    function goHome() {
      if (S && S.attempt) return;   // imtahan zamani tesadufi cixis olmasin
      if (TOKEN) screenTests(); else screenLogin();
    }
    if (mk) { mk.style.cursor = "pointer"; mk.addEventListener("click", goHome); }
    if (topTitle) {
      topTitle.style.cursor = "pointer";
      topTitle.addEventListener("click", goHome);
    }
  })();

  boot();
})();
