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
  /*  Bir valideyn - bir nece usaq (yol xeritesi 16).  Her usagin oz
      valideyn kodu ve tokeni var; telefonda hamisi bir siyahida saxlanir,
      ekranin ustunde usaq secimi.  Serverde deyisiklik yoxdur.  */
  var KIDS = [];       // [{t, c}]
  var ADD_MODE = false;
  /*  Numune sessiyasi (184: giris cavabinda demo=true).  "Valideyn kimi
      bax" ile gelen ziyaretci baxdiqdan sonra sayta qayida bilmirdi -
      «Çıxış» kod ekranini acirdi, orada yazacaq kodu yox idi.  */
  var DEMO = false;
  function kidsSave() {
    try { localStorage.setItem(LS, JSON.stringify({ kids: KIDS, cur: TOKEN, demo: DEMO })); } catch (e) {}
  }
  function kidsLoad() {
    var raw = null;
    try { raw = JSON.parse(localStorage.getItem(LS) || "null"); } catch (e) {}
    if (!raw) return;
    DEMO = raw.demo === true;
    if (raw.kids && raw.kids.length) {
      KIDS = raw.kids.filter(function (k) { return k && k.t; });
      var cur = KIDS.filter(function (k) { return k.t === raw.cur; })[0] || KIDS[0];
      if (cur) { TOKEN = cur.t; CHILD = cur.c || null; }
    } else if (raw.t) {                  // kohne format: tek usaq
      KIDS = [{ t: raw.t, c: raw.c || null }];
      TOKEN = raw.t; CHILD = raw.c || null;
    }
  }
  function kidAdd(t, c) {
    KIDS = KIDS.filter(function (k) { return k.t !== t && !(c && k.c && k.c.name === c.name && k.c.class === c.class); });
    KIDS.push({ t: t, c: c || null });
    TOKEN = t; CHILD = c || null;
    kidsSave();
  }
  function kidDrop(t) {
    KIDS = KIDS.filter(function (k) { return k.t !== t; });
    if (TOKEN === t) { TOKEN = KIDS.length ? KIDS[0].t : null; CHILD = KIDS.length ? KIDS[0].c : null; }
    kidsSave();
  }

  function $(id) { return document.getElementById(id); }
  function on(id, ev, fn) { var e = $(id); if (e) e.addEventListener(ev, fn); }
  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function show(html) {
    busy = false; main.innerHTML = html; window.scrollTo(0, 0);
    if (BAND_KEEP) BAND_KEEP = false; else setBand("");
  }
  /*  Marka zolagi (#band): usaq secimi + ad.  show()-dan EVVEL cagirilir.  */
  var BAND_KEEP = false;
  function setBand(html) {
    var b = $("band");
    if (!b) return;
    b.innerHTML = html ? '<div class="bandin">' + html + "</div>" : "";
    b.classList.toggle("hide", !html);
    main.classList.toggle("over", !!html);
    BAND_KEEP = !!html;
  }
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
        "<h1>" + (ADD_MODE ? "İkinci uşağı əlavə edin" : "Uşağınızı izləyin") + "</h1>" +
        "<p>" + (ADD_MODE ? "Bu uşaq üçün müəllimin verdiyi valideyn kodunu yazın — hər uşağın öz kodu var."
                          : "Müəllimin verdiyi valideyn kodunu yazın.") + "</p></div>" +
      '<div class="card" style="margin-top:18px">' +
        (note || "") +
        '<div id="lErr"></div>' +
        '<label for="code">Valideyn kodu</label>' +
        '<input id="code" maxlength="10" autocomplete="off" autocorrect="off" ' +
          'autocapitalize="characters" spellcheck="false" placeholder="VABCD123" ' +
          'inputmode="text" enterkeyhint="go">' +
        '<button class="btn go wide" id="btnIn">' + (ADD_MODE ? "Əlavə et" : "Daxil ol") + "</button>" +
        (ADD_MODE ? '<button class="btn ghost wide" id="btnAddCancel" style="margin-top:8px">Ləğv et</button>' : "") +
      "</div>" +
      '<p class="note" style="text-align:center;margin-top:16px">' +
        "Kod yoxdursa müəllimdən istəyin. Giriş 30 gün açıq qalır.</p>" +
      //  Kod ekrani dalan olmasin: sayta qayidis gorunen duymedir
      '<a class="btn wide ghost bak" href="../">← Bil10 ana səhifəsi</a>' +
      '<p class="note" style="text-align:center;margin-top:10px">' +
        '<a href="../komek/#valideyn" class="helplink">Necə işləyir?</a></p>'
    );
    var inp = $("code");
    //  136: ana sehifedeki "Sagird/Valideyn kimi bax" - ?kod=DEMO0001
    var qk = (function () {
      try { return (new URLSearchParams(location.search).get("kod") || "").toUpperCase(); } catch (e) { return ""; }
    })();
    if (qk) {
      inp.value = qk.replace(/[^A-Z0-9]/g, "");
      try { history.replaceState(null, "", location.pathname + location.hash); } catch (e) {}
      setTimeout(go, 50);
    }
    inp.focus();
    inp.addEventListener("input", function () {
      inp.value = inp.value.toUpperCase().replace(/[^A-Z0-9]/g, "");
    });
    inp.addEventListener("keydown", function (e) { if (e.key === "Enter") go(); });
    on("btnIn", "click", go);
    on("btnAddCancel", "click", function () { ADD_MODE = false; screenHome(); });
    if (!ADD_MODE) famLoginLink();

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
        if (d.demo === true) DEMO = true;
        kidAdd(d.token, d.child);
        markDemo();
        ADD_MODE = false;
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
        if (/Sessiya bitib/i.test(t)) {
          //  yalniz bu usagin sessiyasi bitib - qalanlar qalir
          kidDrop(TOKEN);
          if (TOKEN) { screenHome(); return; }
          logout(true); return;
        }
        show(msg("err", fail(e)) +
          '<button class="btn wide" id="btnRetry" style="margin-top:12px">' +
          "Yenidən cəhd et</button>");
        on("btnRetry", "click", screenHome);
      });
  }

  /*  910: telefona bildiris.  Bir duyme BUTUN usaqlar ucun abune edir (eyni telefon).  Cari usagin
      sessiyasi islemirse xeta verir; qalan usaqlarin bitmis sessiyasi hec neyi pozmur.  */
  var autoChk = false;
  function pushCheck() {
    var m = $("pushTest");
    if (!m || !window.B10Push) return;
    window.B10Push.test().then(function () {
      var m2 = $("pushTest"); if (!m2) return;
      m2.innerHTML = '<div class="card pushcard"><div class="pc-t"><b>Sınaq bildirişi göndərildi</b>' +
        "<i>Telefonda «Bil10 · Sınaq» bildirişini gördünüz?</i></div>" +
        '<div class="pc-a"><button type="button" class="btn sm go" id="pushYes">Gördüm</button>' +
        '<button type="button" class="btn sm ghost" id="pushNo">Görmədim</button></div></div>';
      on("pushYes", "click", function () { var x = $("pushTest"); if (x) x.innerHTML = '<p class="note pushon">Əla, bildirişlər işləyir ✓</p>'; });
      on("pushNo", "click", function () {
        var x = $("pushTest");
        if (x) x.innerHTML = '<div class="card pushcard pushblk"><div class="pc-t"><b>Bildiriş görünmür</b>' +
          "<i>Brauzer icazə verib, amma telefonun özündə bildirişlər bağlı ola bilər. Yoxla:</i>" + window.B10Push.fixHelp(true) + "</div></div>";
      });
    }, function () {
      var x = $("pushTest");
      if (x) x.innerHTML = '<div class="card pushcard pushblk"><div class="pc-t"><b>Sınaq göstərilə bilmədi</b>' +
        "<i>Səhifəni yeniləyib yenidən cəhd edin.</i>" + window.B10Push.fixHelp(true) + "</div></div>";
    });
  }

  function drawPush() {
    var box = $("pushBox");
    if (!box || !window.B10Push || DEMO || !TOKEN) return;
    var scope = "p";                     // bir cihaz = bir valideyn secimi (butun usaqlar)
    function sub1(t, s) {
      return sb.rpc("rpc_push_subscribe", { p_token: t, p_role: "parent", p_endpoint: s.endpoint,
        p_p256dh: s.p256dh, p_auth: s.auth, p_ua: (navigator.userAgent || "").slice(0, 200) });
    }
    function reg(s) {
      return sub1(TOKEN, s).then(function (r) {
        return Promise.all(KIDS.filter(function (k) { return k.t !== TOKEN; }).map(function (k) {
          return sub1(k.t, s).catch(function () { return null; });
        })).then(function () { return r; });
      });
    }
    function unreg(ep) {
      return Promise.all(KIDS.map(function (k) {
        return sb.rpc("rpc_push_unsubscribe", { p_token: k.t, p_role: "parent", p_endpoint: ep }).catch(function () { return null; });
      }));
    }
    window.B10Push.state("parent", scope).then(function (st) {
      if (!$("pushBox")) return;
      if (st === "off") { box.innerHTML = ""; return; }
      if (st === "on") {
        window.B10Push.sync("parent", scope, reg);           // yeni usaq elave olunubsa / sessiya yenilenibse tazele
        box.innerHTML = '<p class="note pushon">🔔 Bildirişlər açıqdır · <button type="button" class="linkbtn" id="pushOff">Söndür</button> · ' +
          '<button type="button" class="linkbtn" id="pushChk">Gəlmir? Yoxla</button>' +
          '<small class="pc-n">«Çıxış» etsəniz, bu telefona bildiriş gəlməyəcək.</small></p><div id="pushTest"></div>';
        on("pushChk", "click", pushCheck);
        if (autoChk) { autoChk = false; pushCheck(); }
        on("pushOff", "click", function () {
          window.B10Push.disable("parent", scope, unreg).then(drawPush, drawPush);
        });
        return;
      }
      if (st === "denied") {
        box.innerHTML = '<div class="card pushcard pushblk"><div class="pc-t"><b>Bildirişlər bloklanıb</b>' +
          "<i>Brauzer bu saytın bildirişini bağlayıb. Açmaq üçün:</i>" + window.B10Push.help(true) + "</div></div>";
        return;
      }
      if (st === "ios") {
        box.innerHTML = '<div class="card pushcard"><div class="pc-t"><b>Bildiriş almaq istəyirsiniz?</b>' +
          "<i>iPhone-da əvvəl tətbiqi ana ekrana əlavə edin: «Paylaş» → «Ana ekrana əlavə et». Sonra buradan aça bilərsiniz.</i></div></div>";
        return;
      }
      box.innerHTML = '<div class="card pushcard"><div class="pc-t"><b>Yeni test və son tarix barədə xəbər tutun</b>' +
        "<i>Qısa bildiriş telefonunuza gələcək. İstədiyiniz vaxt söndürə bilərsiniz.</i>" +
        '<i class="pc-h">Brauzer soruşanda «İcazə ver» seçin.</i></div>' +
        '<div class="pc-a"><button type="button" class="btn sm go" id="pushOn">Bildirişləri aç</button></div></div>' +
        '<div id="pushMsg"></div>';
      on("pushOn", "click", function () {
        var b = $("pushOn");
        if (b) { b.disabled = true; b.textContent = "Açılır…"; }
        window.B10Push.enable("parent", scope, reg, function () {
          var m0 = $("pushMsg");
          if (m0 && !m0.innerHTML) m0.innerHTML = '<p class="note pushon">İcazə pəncərəsi görünmürsə:</p>' + window.B10Push.help(true);
        }).then(function () { autoChk = true; drawPush(); }, function (e) {
          if (e && e.message === "denied") { drawPush(); return; }     // artıq bloklanıb: addımlarla kart
          var m = $("pushMsg");
          var t = e && e.message === "dismissed" ? "İcazə verilmədi. Yenidən basıb «İcazə ver» seçin."
                : "Bildiriş açıla bilmədi (" + window.B10Push.why(e) + "). Bir az sonra yenidən yoxlayın.";
          if (m) m.innerHTML = msg("warn", t);
          if (b) { b.disabled = false; b.textContent = "Bildirişləri aç"; }
        });
      });
    });
  }

  function drawHome(d) {
    var s   = d.summary || {};
    var out = famSession() ? '<p style="margin:0 0 10px"><a href="#" class="btn sm ghost" id="famBack">← Ailəm</a></p>' : "";

    /* ---- usaq secimi: bir nece usaq varsa ---- */
    if (KIDS.length > 1) {
      out += '<div class="kids" id="kids">' + KIDS.map(function (k) {
        return '<button type="button" class="kid' + (k.t === TOKEN ? " on" : "") + '" data-k="' + esc(k.t) + '">' +
          esc((k.c && k.c.name) || "Uşaq") + "</button>";
      }).join("") + '<button type="button" class="kid add" id="kidAdd">+ uşaq</button></div>';
    }

    /* ---- basliq: kimin ekranidir - marka zolaginda (usaq cipleri de) ---- */
    setBand(out +
      '<div class="who">' +
        '<span class="beye">Valideyn paneli</span>' +
        "<b>" + esc((d.child && d.child.name) || "Uşağım") + "</b>" +
        '<span class="muted">' +
          //  Adi bos olan muellimde "müəllim: " yazib bos qoymuruq
          [ (d.child && d.child.class) || "",
            (d.teacher || "").trim() && !famSession() ? "müəllim: " + d.teacher.trim() : "" ]
            .filter(Boolean).map(esc).join(" · ") +
        "</span>" +
      "</div>");
    out = "";

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
    } else if (s.attempts30 > 0 && !d.paid) {
      //  174: ABUNESIZ - «nə baş verib» qalir, «necədir» (ortalama,
      //  meyl) baglanir.  Yazi NEYTRALDIR: muellimin odemediyi kimi
      //  oxunan hec ne yazilmir - Bil10 muellimi oz musterisinin
      //  qarsisinda utandiran sey olmamalidir.
      out += "<p>Son 30 gündə <b>" + s.attempts30 + "</b> test yazıb. " +
        "Nəticələr aşağıdadır.</p>" +
        '<p class="muted">Ortalama və keçən ayla müqayisə abunə ilə açılır.</p>';
    } else {
      out += '<p class="muted">Son 30 gündə test yazılmayıb.</p>';
    }
    out += "</div>";

    /* ---- 910: telefona bildiris (CFG.VAPID_PUBLIC bos olanda hec ne cixmir) ---- */
    out += '<div id="pushBox"></div>';

    /* ---- bu heftenin dersleri (db/177) ----
       Muellim cedvel qurmayibsa server NULL qaytarir ve BURADA HEC NE
       cizilmir - bos «Cədvəl» karti valideyni yaniltirdi («demeli ders
       yoxdur?»).  Legv edilmis ders SILINMIR, ustunden xett cekilir -
       valideyn ucun en vacib xeber elə odur.  */
    var wk = d.week || null;
    if (wk && wk.length) {
      var gunad = ["Bazar","Bazar ertəsi","Çərşənbə axşamı","Çərşənbə",
                   "Cümə axşamı","Cümə","Şənbə"];
      //  «bu gün» SERVERDEN gelir (Baki gunu) - brauzerin tarixi ile
      //  hesablansaydi, gece yarisindan sonra basqa vaxt zonasindaki
      //  telefon sehv gunu isaretleyerdi.
      var bugun = d.today || "";
      out += "<h2>Bu həftə</h2><div class=\"card pad0 wkp\">" +
        wk.filter(function (x) { return x.hal !== "moved_out"; }).map(function (x) {
          var dt = new Date(x.date + "T00:00:00");
          var legv = x.hal === "cancelled";
          var indi = x.date === bugun;
          return '<div class="wkr' + (legv ? " off" : "") + (indi ? " now" : "") + '">' +
            '<span class="wkd">' + esc(gunad[dt.getDay()]) +
              (indi ? " · bu gün" : "") + "</span>" +
            '<span class="wkt">' + esc(x.time) + "</span>" +
            (legv ? '<span class="wkx">ləğv edilib</span>'
                  : (x.hal === "moved_in" ? '<span class="wkx">köçürülüb</span>' : "")) +
            "</div>";
        }).join("") + "</div>";
    }

    /* ---- gozleyen tapsiriq: ekranin en vacib hissesi ---- */
    var pend = d.pending || [];
    /* ---- ferdi plan (db/131): "2/5 movzu kecilib" ---- */
    if (d.plan && Number(d.plan.total) > 0) {
      out += '<div class="card plan2"><b>Fərdi plan:</b> ' + d.plan.done + " / " + d.plan.total +
        " mövzu keçilib" + (Number(d.plan.done) >= Number(d.plan.total) ? " — tamamlanıb 🎉" : "") + "</div>";
    }

    /* ---- movzu mesqi (db/133) ---- */
    if (d.practice && (Number(d.practice.mastered) || 0) + (Number(d.practice.active) || 0) > 0) {
      out += '<div class="card plan2"><b>Mövzu məşqi:</b> ' + (d.practice.mastered || 0) +
        " mövzu mənimsənilib · " + (d.practice.active || 0) + " davam edir</div>";
    }

    /* ---- davamiyyet ve odenis (db/130): bu ay ---- */
    var at = d.attendance || {};
    if (Number(at.lessons) > 0 || at.paid != null) {
      var ayv = ["yanvar","fevral","mart","aprel","may","iyun","iyul","avqust","sentyabr","oktyabr","noyabr","dekabr"];
      out += "<h2>Davamiyyət · " + ayv[new Date().getMonth()] + "</h2>" +
        '<div class="card att">' +
          (Number(at.lessons) > 0
            ? '<div class="big2">' + at.attended + " / " + at.lessons + "</div>" +
              "<p>" + at.lessons + " dərsdən <b>" + at.attended + "</b>-də iştirak edib." +
              (Number(at.lessons) - Number(at.attended) > 0
                ? " " + (Number(at.lessons) - Number(at.attended)) + " dərsə gəlməyib." : "") + "</p>"
            : "<p>Bu ay hələ dərs qeyd olunmayıb.</p>") +
          (at.paid === true ? '<p class="payok">Bu ayın ödənişi: edilib ✓</p>'
            : (at.paid === false ? '<p class="paywait">Bu ayın ödənişi: gözlənilir</p>' : "")) +
        "</div>";
    }

    out += '<h2>Gözləyən tapşırıq</h2>';
    /* 191: muellimin METNLE yazdigi ev tapsirigi - testlerle bir siyahida,
       ustde.  «Etdim» sagirdin oz isaresidir - valideyn gorur. */
    var hw = d.homework || [];
    var hwOpen = hw.filter(function (x) { return !x.done; });
    var hwDone = hw.filter(function (x) { return x.done; });
    function hwDate(x) { var p = String(x || "").split("-"); return p.length === 3 ? p[2] + "." + p[1] : ""; }
    if (!pend.length && !hwOpen.length) {
      out += '<div class="card ok-box">Gözləyən tapşırıq yoxdur.' +
        (hwDone.length ? " Edilib ✓ " + hwDone.length + " ev tapşırığı." : "") + "</div>";
    } else {
      out += '<div class="card pad0">' + hwOpen.map(function (x) {
        return '<div class="row hwr">' +
          "<div><b>" + esc(x.body) + "</b>" +
            "<i>" + [ "müəllimin tapşırığı", x.personal ? "yalnız ona" : "" ]
              .filter(Boolean).map(esc).join(" · ") + "</i></div>" +
          (x.due ? '<span class="due">' + esc(hwDate(x.due)) + "</span>" : "") +
        "</div>";
      }).join("") + pend.map(function (p) {
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
    if (!les.length && famSession()) {
      //  913: muellimsiz yol - «muellim planini islətmir» yazisi orada menasizdir
    } else if (!les.length) {
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
      (famSession() ? "Bu ekran yalnız baxmaq üçündür." : "Uşağınızla bağlı suallarınızı müəllimə verin — bu ekran yalnız baxmaq üçündür.") + "</p>" +
      (KIDS.length > 1 || famSession() ? "" :
        '<p class="note" style="text-align:center;margin:0 0 4px">Başqa uşağınız da bu müəllimdədirsə: ' +
        '<a href="#" id="kidAdd">uşaq əlavə et</a></p>');

    /* ---- bize yazin: tetbiq haqqinda teklif/problem - admin oxuyur ---- */
    out += '<details class="fbd" id="fbBox">' +
        '<summary>Tətbiq haqqında bizə yazın' +
          '<span class="fbdot hide" id="fbDot">Bil10 cavab yazdı</span></summary>' +
      //  208: yazdiqlariniz + Bil10-un cavabi (evvel cavab catmirdi)
      '<div id="fbMine"></div>' +
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
    drawPush();
    on("kidAdd", "click", function (e) { e.preventDefault(); ADD_MODE = true; screenLogin(""); });
    on("famBack", "click", function (e) { e.preventDefault(); screenFamily(); });
    on("kids", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-k]") : null;
      if (!b || b.getAttribute("data-k") === TOKEN) return;
      var k = KIDS.filter(function (x) { return x.t === b.getAttribute("data-k"); })[0];
      if (!k) return;
      TOKEN = k.t; CHILD = k.c || null; kidsSave();
      screenHome();
    });
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
        fbMineLoad(true);
      }).catch(function (e) {
        setBusy("fbGo", false, "Göndər");
        $("fbM").innerHTML = msg("err", fail(e));
      });
    });

    /*  208: qutu YIGILMIS gelir - cavab nisani ekran acilanda yuklenir
        (p_seen=false, oxunmus sayilmir); qutu acilanda p_seen=true.  */
    fbMineLoad(false);
    on("fbBox", "toggle", function () {
      if ($("fbBox") && $("fbBox").open) fbMineLoad(true);
    });

    function fbMineLoad(seen) {
      sb.rpc("rpc_parent_feedback_mine", { p_token: TOKEN, p_seen: !!seen })
        .then(function (rows) {
          var box = $("fbMine"), dot = $("fbDot");
          if (!box) return;
          rows = rows || [];
          var fresh = rows.filter(function (r) { return r.fresh; }).length;
          if (dot) dot.classList.toggle("hide", !fresh);
          if (!rows.length) { box.innerHTML = ""; return; }
          box.innerHTML = '<div class="card fbcard fbmine"><b class="fbmh">Yazdıqlarınız</b>' +
            rows.map(function (r) {
              return '<div class="fbmi">' +
                '<div class="fbmt"><span>' + esc(r.body) + "</span>" +
                  '<i>' + dateAz(r.at) + "</i></div>" +
                (r.note
                  ? '<div class="fbre' + (r.fresh ? " fresh" : "") + '">' +
                    "<div><b>Bil10-un cavabı</b>" + esc(r.note) + "</div></div>"
                  : '<div class="fbwait">Oxuyuruq — cavab buraya gələcək.</div>') +
              "</div>";
            }).join("") + "</div>";
        }).catch(function () {});
    }
  }


  /* ================================================================
     AILE YOLU (db/913) - e-poctla hesab, usaq elave et, «Ailem»
     Muellimsiz yol: valideyn oz hesabini acir, usagi OZU elave edir, usaq kodla girir.
     Movcud «muellimin verdiyi kod» yolu TOXUNULMUR.  Bayraq (app_state.family) sonukdurse bu yol
     yalniz icazeli e-poctlar ucundur (server yoxlayir) - sehifede ?aile=1 ile gorunur.
     Butun serverden gelen metn esc() ile yazilir; usaq adi innerHTML-e xam dusmur.
     ================================================================ */
  var LOGO = '<div class="hero"><div class="mark"><svg viewBox="0 0 32 32" aria-hidden="true"><defs><linearGradient id="lgF" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2b4acb"/><stop offset="1" stop-color="#0e9384"/></linearGradient></defs><path d="M12.5 3.5 H18 A8.4 8.4 0 0 1 26.4 11.9 A8.4 8.4 0 0 1 18 20.3 H13.1 L8.3 24.6 Q7.1 25.6 7.1 24 V19.1 A8.4 8.4 0 0 1 4.1 11.9 A8.4 8.4 0 0 1 12.5 3.5 Z" fill="url(#lgF)"/><g fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round"><path d="M10.2 10.2 12.5 8.4 V16"/><ellipse cx="18.4" cy="12" rx="3.1" ry="4.1"/></g><path d="M22.5 19.5 h4.2 a3.6 3.6 0 0 1 3.6 3.6 a3.6 3.6 0 0 1-3.6 3.6 h-1 l2 3.4 -4.6-3.5 a3.6 3.6 0 0 1-4.2-3.5 a3.6 3.6 0 0 1 3.6-3.6 Z" fill="#ffc94d"/><path d="M23.4 23.2 l1.5 1.5 2.6-3" fill="none" stroke="#1a2233" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/></svg></div>';
  function famHero(h, p) { return LOGO + "<h1>" + esc(h) + "</h1><p>" + esc(p) + "</p></div>"; }
  function famSession() {
    var s = window.sb && sb.session && sb.session();
    return !!(s && s.access_token);
  }
  function famUrlOn() { return /[?&]aile=1/.test(location.search); }
  var ORD = { 1: "1-ci", 2: "2-ci", 3: "3-cü", 4: "4-cü", 5: "5-ci", 6: "6-cı", 7: "7-ci", 8: "8-ci", 9: "9-cu", 10: "10-cu", 11: "11-ci" };
  function famErr(e) {
    var t = (e && e.message) ? e.message : String(e);
    if (/already registered|already been registered|User already/i.test(t)) return "Bu e-poçt artıq qeydiyyatdadır. «Daxil ol» seçin.";
    if (/Invalid login|invalid_credentials|parol yanlis/i.test(t)) return "E-poçt və ya parol yanlışdır.";
    if (/not confirmed/i.test(t)) return "E-poçtunuz təsdiqlənməyib. Poçtunuza göndərilən linkə basın.";
    if (/Password should|weak/i.test(t)) return "Parol çox zəifdir. Ən azı 8 simvol yazın.";
    if (/rate limit|too many/i.test(t)) return "Çox cəhd oldu. Bir az sonra yenidən yoxlayın.";
    return fail(e);
  }
  function famExpired(e) {
    var t = (e && e.message) || "";
    return /Sessiya bitib|Daxil olmamisiniz|JWT|401/i.test(t);
  }
  //  Giris ekraninda kicik kecid: bayraq aciqdirsa (ve ya ?aile=1)
  function famLoginLink() {
    function add() {
      var m = $("main");
      if (!m || $("famLink")) return;
      var p = document.createElement("p");
      p.id = "famLink"; p.className = "note famlink";
      p.innerHTML = 'Müəllimsiz, özünüz istifadə etmək istəyirsiniz? <a href="#" id="famGo">E-poçtla daxil olun / yeni hesab</a>';
      m.appendChild(p);
      on("famGo", "click", function (e) { e.preventDefault(); screenFamAuth("up"); });
    }
    if (famUrlOn()) { add(); return; }
    sb.rpc("rpc_family_status", {}).then(function (d) { if (d && d.on === true) add(); }).catch(function () {});
  }

  function screenFamAuth(mode, note) {
    var up = mode === "up";
    topBar.classList.add("hide");
    show(famHero(up ? "Yeni valideyn hesabı" : "Valideyn girişi",
                 up ? "30 gün pulsuz, kart tələb olunmur." : "E-poçt və parolla daxil olun.") +
      '<div class="card fam" style="margin-top:18px">' + (note || "") +
        '<div class="fseg" id="fSeg"><button type="button" data-m="in" class="' + (up ? "" : "on") + '">Daxil ol</button>' +
          '<button type="button" data-m="up" class="' + (up ? "on" : "") + '">Yeni hesab</button></div>' +
        '<div id="fErr"></div>' +
        (up ? '<label for="fName">Adınız</label><input id="fName" maxlength="80" autocomplete="name" placeholder="Ad Soyad">' : "") +
        '<label for="fMail">E-poçt</label><input id="fMail" type="email" maxlength="120" autocomplete="email" inputmode="email" ' +
          'autocapitalize="none" autocorrect="off" spellcheck="false" placeholder="ad@mail.az">' +
        '<label for="fPass">Parol</label><input id="fPass" type="password" maxlength="72" ' +
          'autocomplete="' + (up ? "new-password" : "current-password") + '" placeholder="' + (up ? "Ən azı 8 simvol" : "Parol") + '">' +
        '<button class="btn go wide" id="fGo" style="margin-top:14px">' + (up ? "Hesab yarat — 30 gün pulsuz" : "Daxil ol") + "</button>" +
      "</div>" +
      (up ? '<p class="note" style="text-align:center;margin-top:12px">Kart tələb olunmur. İstədiyiniz vaxt hesabı silə bilərsiniz.</p>' : "") +
      '<p class="note" style="text-align:center;margin-top:14px"><a href="#" id="fCode">Müəllimin verdiyi kodla daxil olun</a></p>' +
      '<a class="btn wide ghost bak" href="../">← Bil10 ana səhifəsi</a>');
    on("fSeg", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-m]") : null;
      if (b && b.getAttribute("data-m") !== mode) screenFamAuth(b.getAttribute("data-m"));
    });
    on("fCode", "click", function (e) { e.preventDefault(); screenLogin(""); });
    var label = up ? "Hesab yarat — 30 gün pulsuz" : "Daxil ol";
    var first = $(up ? "fName" : "fMail"); if (first) first.focus();
    ["fName", "fMail", "fPass"].forEach(function (id) {
      var el = $(id); if (el) el.addEventListener("keydown", function (e) { if (e.key === "Enter") go(); });
    });
    on("fGo", "click", go);

    function go() {
      if (busy) return;
      var name = up ? ($("fName").value || "").replace(/\s+/g, " ").trim() : "";
      var mail = ($("fMail").value || "").trim().toLowerCase();
      var pass = $("fPass").value || "";
      function bad(t) { $("fErr").innerHTML = msg("err", t); }
      if (up && name.length < 2) return bad("Adınızı yazın.");
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(mail)) return bad("E-poçtu düzgün yazın.");
      if (pass.length < 8) return bad("Parol ən azı 8 simvol olmalıdır.");
      $("fErr").innerHTML = "";
      setBusy("fGo", true, label);
      var p = up
        ? sb.signUp(mail, pass, name).then(function (d) {
            if (d && d.access_token) {
              //  hesab (auth) yarandi, amma xidmet bu e-poct ucun hele acilmayib - «Daxil ol» ile cehd etmeye mecbur qalmasin
              return famStart(name).catch(function (e2) { screenFamName(); var fe = $("fErr"); if (fe) fe.innerHTML = msg("err", famErr(e2)); });
            }
            //  e-poct tesdiqi aciqdir
            screenFamAuth("in", msg("ok", "Poçtunuza təsdiq linki göndərildi. Linkə basın, sonra buradan daxil olun."));
          })
        : sb.signIn(mail, pass).then(famEnter);
      p.catch(function (e) {
        setBusy("fGo", false, label);
        bad(famErr(e));
      });
    }
  }

  //  Hesabi yoxdur (qeydiyyat tamamlanmayib / e-poct tesdiqinden sonra ilk giris): yalniz ad
  function screenFamName() {
    topBar.classList.add("hide");
    show(famHero("Son addım", "Adınızı yazın, 30 günlük sınaq başlasın.") +
      '<div class="card fam" style="margin-top:18px"><div id="fErr"></div>' +
        '<label for="fName">Adınız</label><input id="fName" maxlength="80" autocomplete="name" placeholder="Ad Soyad">' +
        '<button class="btn go wide" id="fGo" style="margin-top:14px">Davam et</button></div>' +
      '<p class="note" style="text-align:center;margin-top:14px"><a href="#" id="fOut">Başqa e-poçtla daxil olun</a></p>');
    on("fOut", "click", function (e) { e.preventDefault(); logout(false); });
    $("fName").focus();
    function go() {
      if (busy) return;
      var name = ($("fName").value || "").replace(/\s+/g, " ").trim();
      if (name.length < 2) { $("fErr").innerHTML = msg("err", "Adınızı yazın."); return; }
      setBusy("fGo", true, "Davam et");
      famStart(name).catch(function (e) { setBusy("fGo", false, "Davam et"); $("fErr").innerHTML = msg("err", famErr(e)); });
    }
    on("fGo", "click", go);
    $("fName").addEventListener("keydown", function (e) { if (e.key === "Enter") go(); });
  }

  function famStart(name) {
    return sb.rpc("rpc_family_start", { p_name: name }).then(famEnter);
  }
  function famEnter() {
    return sb.rpc("rpc_family_children", {}).then(function (d) {
      if (!d || !d.has_account) { screenFamName(); return; }
      drawFamily(d);
    });
  }
  function screenFamily() {
    topBar.classList.remove("hide");
    topTitle.textContent = "Ailəm";
    show('<div class="card"><div class="skel">Yüklənir…</div></div>');
    famEnter().catch(function (e) {
      if (famExpired(e)) {
        sb.signOut().then(function () { screenFamAuth("in", msg("warn", "Giriş vaxtı bitib. Yenidən daxil olun.")); },
                          function () { screenFamAuth("in", msg("warn", "Giriş vaxtı bitib. Yenidən daxil olun.")); });
        return;
      }
      show(msg("err", famErr(e)) + '<button class="btn wide" id="btnRetry" style="margin-top:12px">Yenidən cəhd et</button>');
      on("btnRetry", "click", screenFamily);
    });
  }

  function copyText(text, btn, done) {
    function ok() { if (btn) { var old = btn.textContent; btn.textContent = done || "Kopyalandı ✓"; setTimeout(function () { btn.textContent = old; }, 1600); } }
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(text).then(ok, fallback); return; }
    } catch (e) {}
    fallback();
    function fallback() {
      try {
        var ta = document.createElement("textarea"); ta.value = text; ta.setAttribute("readonly", "");
        ta.style.position = "fixed"; ta.style.opacity = "0"; document.body.appendChild(ta); ta.select();
        document.execCommand("copy"); document.body.removeChild(ta); ok();
      } catch (e) {}
    }
  }
  function waLink(code) {
    var t = "Salam! Bil10 proqramına giriş: bil10.az/sagird ünvanında bu kodu yazın: " + code;
    return "https://wa.me/?text=" + encodeURIComponent(t);
  }

  function drawFamily(d) {
    var kids = d.kids || [], acc = d.account || {};
    topBar.classList.remove("hide");
    topTitle.textContent = "Ailəm";
    var out = "";
    if (acc.active === false) {
      out += msg("warn", "Sınaq müddəti bitib. Davam etmək üçün info@bil10.az ünvanına yazın — uşaqlarınızın məlumatları saxlanılır.");
    } else if (acc.trial_end) {
      out += '<div class="ftrial"><span>Sınaq: ' + esc(qalan(acc.trial_end)) + "</span><i>kart tələb olunmur</i></div>";
    }
    if (!kids.length) {
      out += '<div class="card ftxt"><b>Hələ uşaq əlavə etməmisiniz</b>' +
        "<p>Uşağın adını və sinfini yazın — ona uyğun başlanğıc yoxlama avtomatik hazırlanacaq.</p></div>";
    }
    out += kids.map(function (k) {
      var sd = k.subject_diag || [];
      var doneN = sd.filter(function (x) { return x.state === "done"; }).length;
      var done = sd.length > 0 && doneN === sd.length;
      var diag = sd.length ? "Başlanğıc yoxlama: " + doneN + " / " + sd.length + " fənn" + (done ? " ✓" : "") : "Başlanğıc yoxlama hazırlanır";
      var rows = sd.map(function (x) {
        var right = x.state === "done" ? '<i class="ok">tamamlandı ✓</i>'
          : x.state === "open" ? "<i>uşağa verilib</i>"
          : '<button type="button" class="btn sm ghost" data-diag="' + esc(x.slug) + '" data-kid="' + esc(k.id) + '">Yoxlama ver</button>';
        return '<div class="fk-sr"><span>' + esc(x.name) + "</span>" + right + "</div>";
      }).join("");
      return '<div class="card fk">' +
        '<div class="fk-h"><div class="fk-av">' + esc(String(k.name || "?").charAt(0).toUpperCase()) + "</div>" +
          "<div><b>" + esc(k.name) + "</b><span>" + esc(k.sinif ? (ORD[k.sinif] || (k.sinif + "-ci")) + " sinif" : "") +
            ((k.subject_names || []).length ? " · " + esc((k.subject_names || []).join(", ")) : "") + "</span></div></div>" +
        '<div class="fk-d' + (done ? " ok" : "") + '">' + esc(diag) + "</div>" +
        (rows ? '<div class="fk-sj">' + rows + "</div>" : "") +
        '<div class="fk-code"><i>Uşağın giriş kodu</i><b>' + esc(k.login_code) + "</b>" +
          "<span>bil10.az/sagird ünvanında bu kodla daxil olur</span></div>" +
        '<div class="fk-btns">' +
          '<button type="button" class="btn sm ghost" data-copy="' + esc(k.login_code) + '">Kopyala</button>' +
          '<a class="btn sm ghost" target="_blank" rel="noopener" href="' + esc(waLink(k.login_code)) + '">WhatsApp</a>' +
          '<button type="button" class="btn sm go" data-open="' + esc(k.id) + '">Ətraflı</button></div></div>';
    }).join("");
    out += (kids.length >= 6 ? "" : '<button class="btn wide ' + (kids.length ? "ghost" : "go") + '" id="famAdd">+ Uşaq əlavə et</button>') +
      '<p class="note" style="text-align:center;margin:16px 0 4px">Uşağın adı, sinfi və məşq nəticələri yalnız sizin hesabınızda görünür. ' +
      '<a href="../mexfilik/">Məxfilik</a></p>';
    show(out);
    on("famAdd", "click", screenAddChild);
    Array.prototype.forEach.call(document.querySelectorAll("[data-copy]"), function (b) {
      b.addEventListener("click", function () { copyText(b.getAttribute("data-copy"), b); });
    });
    Array.prototype.forEach.call(document.querySelectorAll("[data-diag]"), function (b) {
      b.addEventListener("click", function () { famDiag(b); });
    });
    Array.prototype.forEach.call(document.querySelectorAll("[data-open]"), function (b) {
      b.addEventListener("click", function () { famOpen(b.getAttribute("data-open"), b); });
    });
  }

  //  Secilmis, amma hele yoxlamasi verilmemis fenn ucun bir toxunusla yoxlama ver
  function famDiag(btn) {
    if (busy) return;
    busy = true; btn.disabled = true; btn.textContent = "Hazırlanır…";
    sb.rpc("rpc_family_diag", { p_student: btn.getAttribute("data-kid"), p_subject: btn.getAttribute("data-diag") })
      .then(function () { busy = false; screenFamily(); })
      .catch(function (e) {
        busy = false; btn.disabled = false; btn.textContent = "Yoxlama ver";
        if (famExpired(e)) { screenFamily(); return; }
        var m = document.createElement("div"); m.innerHTML = msg("err", famErr(e));
        main.insertBefore(m.firstChild, main.firstChild); window.scrollTo(0, 0);
      });
  }

  //  Usagin movcud valideyn ekranini ac (rpc_parent_home) - hesab sahibine usagin valideyn tokeni verilir
  function famOpen(id, btn) {
    if (busy) return;
    busy = true; if (btn) { btn.disabled = true; btn.textContent = "Gözləyin…"; }
    sb.rpc("rpc_family_open", { p_student: id }).then(function (d) {
      KIDS = []; TOKEN = null; CHILD = null;
      kidAdd(d.token, d.child);
      busy = false; ADD_MODE = false;
      screenHome();
    }).catch(function (e) {
      busy = false; if (btn) { btn.disabled = false; btn.textContent = "Ətraflı"; }
      if (famExpired(e)) { screenFamily(); return; }
      var m = document.createElement("div"); m.innerHTML = msg("err", famErr(e));
      main.insertBefore(m.firstChild, main.firstChild);
    });
  }

  //  Defolt fenn dəsti: ibtidai - riyaziyyat + Az. dili; yuxari - + Ingilis dili (movcud olanlardan)
  function famDefaults(level, avail) {
    var want = level <= 4 ? ["riyaziyyat", "az-dili"] : ["riyaziyyat", "az-dili", "ingilis-dili"];
    var have = avail.map(function (a) { return a.slug; });
    var pick = want.filter(function (w) { return have.indexOf(w) >= 0; });
    if (!pick.length) pick = have.slice(0, 2);
    return pick;
  }

  function screenAddChild() {
    topBar.classList.remove("hide");
    topTitle.textContent = "Uşaq əlavə et";
    var st = { sinif: null, avail: [], subs: [], min: 10, minTouched: false };
    //  Tovsiye olunan gundelik vaxt: ibtidai 10, orta 15, yuxari 20 deq (movcud suallarin tempine gore; ilk ailelerde yoxlanir)
    function recMin(l) { return l <= 4 ? 10 : (l <= 8 ? 15 : 20); }
    var lv = "";
    for (var i = 1; i <= 11; i++) lv += '<button type="button" class="chip" data-l="' + i + '">' + i + "</button>";
    show('<div class="card fam"><div id="cErr"></div>' +
      '<label for="cName">Uşağın adı</label><input id="cName" maxlength="60" autocomplete="off" placeholder="Məsələn: Hüseyn">' +
      "<label>Sinif</label><div class=\"chips\" id=\"cLvl\">" + lv +
        '<button type="button" class="chip" disabled style="opacity:.55" title="Tezliklə">Abituriyent · tezliklə</button></div>' +
      '<label>Hansı fənlər? <span class="fhint">(sinfə görə seçilir, dəyişə bilərsiniz)</span></label>' +
      '<div class="chips" id="cSubj"><span class="fhint">Əvvəl sinfi seçin.</span></div><div class="fhint" id="cSubjHint"></div>' +
      "<label>Gündə nə qədər vaxt? <span class=\"fhint\">(gündəlik məşq hədəfi)</span></label><div class=\"chips\" id=\"cMin\">" +
        [5, 10, 15, 20, 30].map(function (m) { return '<button type="button" class="chip' + (m === 10 ? " on" : "") + '" data-m="' + m + '">' + m + " dəq</button>"; }).join("") +
        '</div><div class="fhint" id="cMinHint">Sinfi seçəndə tövsiyə olunan vaxt göstərilir.</div>' +
      '<label class="fchk"><input type="checkbox" id="cOk"><span>Uşağımın adı, sinfi və məşq nəticələrinin Bil10-da saxlanmasına <b>razıyam</b>. ' +
        'İstədiyim vaxt silinməsini istəyə bilərəm. <a href="../mexfilik/" target="_blank" rel="noopener">Ətraflı</a></span></label>' +
      '<button class="btn go wide" id="cGo">Əlavə et</button>' +
      '<button class="btn ghost wide" id="cBack" style="margin-top:8px">Ləğv et</button></div>');
    $("cName").focus();
    on("cBack", "click", screenFamily);

    on("cLvl", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-l]") : null;
      if (!b) return;
      st.sinif = Number(b.getAttribute("data-l"));
      Array.prototype.forEach.call(document.querySelectorAll("#cLvl [data-l]"), function (x) { x.classList.toggle("on", x === b); });
      if (!st.minTouched) setMin(recMin(st.sinif));
      $("cMinHint").textContent = "Bu sinif üçün tövsiyə: " + recMin(st.sinif) + " dəq. İstədiyinizi seçə bilərsiniz.";
      $("cSubj").innerHTML = '<span class="fhint">Yüklənir…</span>';
      sb.rpc("rpc_family_subjects", { p_level_code: String(st.sinif) }).then(function (list) {
        if (st.sinif !== Number(b.getAttribute("data-l"))) return;
        st.avail = list || [];
        st.subs = famDefaults(st.sinif, st.avail);
        drawSubj();
      }).catch(function (er) { $("cSubj").innerHTML = msg("err", famErr(er)); });
    });
    function drawSubj() {
      if (!st.avail.length) { $("cSubj").innerHTML = '<span class="fhint">Bu sinif üçün hələ fənn yoxdur.</span>'; return; }
      $("cSubj").innerHTML = st.avail.map(function (a) {
        return '<button type="button" class="chip' + (st.subs.indexOf(a.slug) >= 0 ? " on" : "") + '" data-s="' + esc(a.slug) + '">' + esc(a.name) + "</button>";
      }).join("");
      var h = $("cSubjHint");
      if (h) h.textContent = st.subs.length > 3 ? "Başlanğıc yoxlama ilk 3 fənn üçün dərhal hazırlanacaq, qalanını sonra «Ailəm» ekranından bir toxunuşla verə bilərsiniz." : "";
    }
    on("cSubj", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-s]") : null;
      if (!b) return;
      var s = b.getAttribute("data-s"), ix = st.subs.indexOf(s);
      if (ix >= 0) st.subs.splice(ix, 1); else st.subs.push(s);
      drawSubj();
    });
    function setMin(m) {
      st.min = m;
      Array.prototype.forEach.call(document.querySelectorAll("#cMin [data-m]"), function (x) { x.classList.toggle("on", Number(x.getAttribute("data-m")) === m); });
    }
    on("cMin", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-m]") : null;
      if (!b) return;
      st.minTouched = true;
      setMin(Number(b.getAttribute("data-m")));
    });
    on("cGo", "click", function () {
      if (busy) return;
      var name = ($("cName").value || "").replace(/\s+/g, " ").trim();
      function bad(t) { $("cErr").innerHTML = msg("err", t); window.scrollTo(0, 0); }
      if (name.length < 2) return bad("Uşağın adını yazın.");
      if (!st.sinif) return bad("Sinfi seçin.");
      if (!st.subs.length) return bad("Ən azı bir fənn seçin.");
      if (!$("cOk").checked) return bad("Davam etmək üçün razılıq qutusunu işarələyin.");
      $("cErr").innerHTML = "";
      setBusy("cGo", true, "Əlavə et");
      sb.rpc("rpc_family_add_child", { p_name: name, p_level_code: String(st.sinif), p_subjects: st.subs, p_minutes: st.min, p_consent: true })
        .then(function (r) { busy = false; screenChildDone(r, st.avail); })
        .catch(function (er) { setBusy("cGo", false, "Əlavə et"); bad(famExpired(er) ? "Giriş vaxtı bitib. Səhifəni yeniləyib yenidən daxil olun." : famErr(er)); });
    });
  }

  function screenChildDone(r, avail) {
    topBar.classList.remove("hide");
    topTitle.textContent = "Uşaq əlavə olundu";
    var names = {}; (avail || []).forEach(function (a) { names[a.slug] = a.name; });
    var diag = r.diagnostics || [];
    var okN = diag.filter(function (x) { return x && x.ok; }).map(function (x) { return names[x.subject] || x.subject; });
    var badN = diag.filter(function (x) { return x && !x.ok; }).length;
    show('<div class="card ctr fam"><div class="fok">✓</div><h2 class="fdone">' + esc(r.name) + " üçün hazırdır</h2>" +
      '<p class="note">Uşağınız <b>bil10.az/sagird</b> ünvanında bu kodla daxil olur:</p>' +
      '<div class="fcode2">' + esc(r.login_code) + "</div>" +
      '<a class="btn wide go" target="_blank" rel="noopener" href="' + esc(waLink(r.login_code)) + '" style="margin-bottom:8px">WhatsApp-a göndər</a>' +
      '<button class="btn wide ghost" id="dCopy" type="button" data-copy="' + esc(r.login_code) + '">Kodu kopyala</button></div>' +
      '<div class="card fam"><b>Növbəti addım</b><p class="note" style="margin:6px 0 0">' +
        (okN.length ? "Başlanğıc yoxlama hazırdır: <b>" + esc(okN.join(", ")) + "</b>. Uşaq ilk dəfə daxil olanda «Yeni test» kimi görəcək; 14 gün müddəti var." : "Başlanğıc yoxlama hələ hazırlanmayıb.") +
        (badN ? " Bəzi fənlər üçün yoxlama hazırlanmadı — «Ailəm» ekranından «Yoxlama ver» düyməsi ilə yenidən cəhd edin." : "") +
        ((r.subjects_total || 0) > diag.length ? " Qalan " + ((r.subjects_total || 0) - diag.length) + " fənn üçün yoxlamanı «Ailəm» ekranından özünüz verə bilərsiniz." : "") + "</p></div>" +
      '<button class="btn wide go" id="dHome" style="margin-top:6px">Ailəm ekranına keç</button>');
    on("dCopy", "click", function () { copyText(r.login_code, $("dCopy")); });
    on("dHome", "click", screenFamily);
  }

  /* ================================================================
     CIXIS
     ================================================================ */
  /*  Ust zolaqdaki duymenin adi: numunede «Nümunədən çıx».  */
  function markDemo() {
    if (!btnOut) return;
    btnOut.textContent = DEMO ? "Nümunədən çıx" : "Çıxış";
    btnOut.classList.toggle("demoout", DEMO);
  }

  function logout(expired) {
    //  Numunede "cixis" = sayta qayitmaq: kod ekrani ziyaretci ucun
    //  dalandir, orada yazacaq kodu yoxdur.  Serverdeki sessiyalar
    //  burada da baglanir - sadece sonda ekran evezine sayt acilir.
    var sayta = DEMO && !expired;
    var all = KIDS.map(function (k) { return k.t; });
    if (TOKEN && all.indexOf(TOKEN) < 0) all.push(TOKEN);
    var wasDemo = DEMO;
    var wasFam = famSession();
    TOKEN = null; CHILD = null; KIDS = []; ADD_MODE = false; DEMO = false;
    try { localStorage.removeItem(LS); } catch (e) {}
    markDemo();
    //  910: EVVEL bu cihazdaki bildiris abunesi silinir (sessiya hele aktivdir), SONRA sessiyalar baglanir.
    //  Eks halda sessiya evvel silinerdi ve abune qalardi - basqasi girse bildiris bu valideyne gelerdi.
    function serverLogout() {
      all.forEach(function (t) { sb.rpc("rpc_parent_logout", { p_token: t }).catch(function () {}); });
    }
    if (window.B10Push && all.length && !wasDemo) {
      window.B10Push.leave(function (ep) {
        return Promise.all(all.map(function (t) {
          return sb.rpc("rpc_push_unsubscribe", { p_token: t, p_role: "parent", p_endpoint: ep }).catch(function () { return null; });
        }));
      }).then(serverLogout, serverLogout);
    } else {
      serverLogout();
    }
    if (wasFam) { try { sb.signOut().catch(function () {}); } catch (e) {} }
    if (sayta) { location.href = "../"; return; }
    screenLogin(expired ? msg("warn", "Giriş vaxtı bitib. Kodu yenidən yazın.") : "");
  }

  btnOut.addEventListener("click", function () { logout(false); });

  /* ================================================================
     BASLANGIC
     ================================================================ */
  function boot() {
    kidsLoad();
    markDemo();
    if (famSession()) { screenFamily(); return; }          // 913: e-poct sessiyasi - «Ailem»
    if (TOKEN) { screenHome(); return; }
    if (famUrlOn()) { screenFamAuth("in"); return; }       // ?aile=1: birbasa e-poct girisi
    screenLogin("");
  }

  boot();
})();
