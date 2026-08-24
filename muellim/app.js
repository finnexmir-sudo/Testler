/* =====================================================================
   Muellim / repetitor paneli
   Butun melumat Supabase-den gelir. Sagird kodlari, qrup kodlari ve
   yer limiti SERVERDE idare olunur - burada yalniz gosterilir.
   ===================================================================== */
(function () {
  "use strict";

  var main = document.getElementById("main");
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
    key:    '<circle cx="6.5" cy="12.5" r="3"/><path d="M8.7 10.3 15.5 3.5"/>' +
            '<path d="M13 6l2 2"/>',
    chart:  '<path d="M3.5 15.5h12"/><rect x="5" y="9" width="2.6" height="4.5" rx=".7"/>' +
            '<rect x="9" y="5.5" width="2.6" height="8" rx=".7"/>' +
            '<rect x="13" y="11" width="2.6" height="2.5" rx=".7"/>',
    star:   '<path d="M9.5 3l1.9 3.9 4.3.6-3.1 3 .7 4.3-3.8-2-3.8 2 .7-4.3-3.1-3 ' +
            '4.3-.6L9.5 3z"/>',
    clock:  '<circle cx="9.5" cy="9.5" r="6.8"/><path d="M9.5 5.8v4l2.6 1.5"/>',
    pen:    '<path d="M12.4 3.6a1.7 1.7 0 0 1 2.4 2.4L6.6 14.2l-3.1.7.7-3.1 8.2-8.2z"/>'
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
        '<label for="pass">Parol</label>' +
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

    var html =
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
      '<button class="item" id="btnBank">' +
        '<div class="ic">' + ic("doc") + "</div>" +
        '<div class="g"><b>Sual bankı</b><i><span>Öz suallarınızı yazın, ' +
          "testlərə yığın</span></i></div>" +
        '<span class="arrow">' + ic("right") + "</span></button>" +
      '<div class="spacer"></div>' +
      "<h2>Qruplar</h2>" +
      '<div id="groups" class="card pad0"><div class="skel">Yüklənir…</div></div>' +
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

    on("btnBank", "click", function () { nav("#/b"); });

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

  function loadGroups() {
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

  /* ------------------------------------------------------- qrup detali */
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
          '<span class="code key">' + esc(g.join_code) + "</span></div>" +
        '<div class="spacer"></div>' +
        '<div class="row two">' +
          '<button class="btn wide" id="btnAsgs">' + ic("clip") + "Tapşırıqlar</button>" +
          '<button class="btn wide" id="btnRep">' + ic("chart") + "Hesabat</button>" +
        "</div>" +
      "</div>" +
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
          '<div class="l1"><b>' + esc(s.full_name) + "</b>" +
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

  /* Menimseme zolagi: 0-49 zeif, 50-74 orta, 75+ yaxsi */
  function meter(ratio) {
    var r = pct(ratio);
    var cls = r >= 75 ? "ok" : (r >= 50 ? "mid" : "low");
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
          statTile(sm.active + " / " + sm.students, "aktiv şagird") +
          statTile(pct(sm.avg) + "%", "orta nəticə") +
          statTile(sm.attempts || 0, "işlənmiş test") +
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
    return sb.select("programs", { select: "id,slug", eq: { slug: "ibtidai" } })
      .then(function (ps) {
        if (!ps || !ps.length) return [];
        return sb.select("levels", {
          select: "id,code,name", eq: { program_id: ps[0].id }, order: "sort"
        });
      })
      .then(function (rows) { LEVELS = rows || []; return LEVELS; })
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

  function statTile(val, lbl) {
    return '<div class="stat"><b>' + esc(String(val)) + "</b><span>" + esc(lbl) + "</span></div>";
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
          statTile(sm.attempts || 0, "test") +
          statTile(pct(sm.avg) + "%", "orta") +
          statTile(pct(sm.best) + "%", "ən yaxşı") +
        "</div>";

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
      }

      if (r.weak !== null && r.weak && r.weak.length) {
        h += "<h2>Təkrar səhv edilən suallar</h2><div class=\"card pad0\">" +
          r.weak.map(function (w) {
            return '<div class="trow col"><b>' + esc(w.body) + "</b>" +
              (w.explanation ? "<i>" + esc(w.explanation) + "</i>" : "") +
              '<span class="tag">' + w.wrong + " dəfə səhv</span></div>";
          }).join("") + "</div>";
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
      on("btnB", "click", function () { nav("#/r/" + classId); });
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

    sb.rpc("rpc_bank_facets", { p_subject: f.subject || null, p_level: f.level || null })
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
            (FAC.subjects || []).map(function (s) {
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
        ((FAC.topics || []).length
          ? '<div class="chips" id="bTop">' + FAC.topics.map(function (t) {
              return '<button class="chip' + (f.topics.indexOf(t.id) >= 0 ? " on" : "") +
                '" data-t="' + esc(t.id) + '">' + esc(t.name) + "</button>";
            }).join("") + "</div>"
          : "") +
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
      f.pool = b.getAttribute("data-v"); drawBank();
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
    kindNote();

    on("qkind", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
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
      drawQuestion();
    });
    on("qdiff", "click", function (e) {
      var b = e.target.closest ? e.target.closest("[data-v]") : null;
      if (!b) return;
      collect(); QD.difficulty = Number(b.getAttribute("data-v")); drawQuestion();
    });
    on("qSave", "click", saveQuestion);
    if (!isNew) on("qDel", "click", delQuestion);

    /* Oxsar sual xeberdarligi - BLOKLAMIR, yalniz gosterir */
    var t = null;
    on("qbody", "input", function () {
      clearTimeout(t);
      t = setTimeout(checkSimilar, 600);
    });
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
        drawOptions(); return;
      }
      var r = e.target.closest ? e.target.closest("[data-rm]") : null;
      if (r) {
        collect();
        QD.options.splice(Number(r.getAttribute("data-rm")), 1);
        if (QD.kind !== "text" && !QD.options.some(function (o) { return o.correct; })) {
          QD.options[0].correct = true;
        }
        drawOptions(); return;
      }
      if (e.target.id === "qAdd" || (e.target.closest && e.target.closest("#qAdd"))) {
        collect();
        QD.options.push({ body: "", correct: QD.kind === "text" });
        drawOptions();
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

  btnOut.addEventListener("click", function () {
    sb.signOut().then(function () {
      CTX = null; ACC = null;
      try { history.replaceState(null, "", location.pathname); } catch (e) {}
      screenAuth("in");
    });
  });

  boot();
})();
