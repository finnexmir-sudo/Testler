/* =====================================================================
   bil10.az/s/?k=<acar>  -  dostun gorduyu BIR sual (db/214)

   !!! HELE AKTIV DEYIL: db/214 canlida isledilmeyib, sagird tetbiqinde
   «Dostuna at» duymesi yoxdur.  Bu qovluga yalniz elle gelmek olar.
   Acmaq ucun: CLAUDE.md -> «db/214 ... QOSULMAYIB».

   Bu sehife tetbiqin bir hissesi DEYIL: giris yoxdur, kod yoxdur,
   localStorage-a toxunmur, sagird sessiyasi ile isi yoxdur.  Ona gore
   sagird/sb.js yuklenmir - burada cemi bir «rpc» funksiyasi lazimdir.
   Yalniz oz Supabase-imize sorgu gedir; kitabxana, CDN, izleyici yoxdur.
   ===================================================================== */
(function () {
  "use strict";

  var main = document.getElementById("main");
  var K = (function () {
    var m = /[?&]k=([^&]+)/.exec(location.search || "");
    return m ? decodeURIComponent(m[1]) : "";
  })();
  var busy = false;

  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function rpc(fn, body) {
    var c = window.CFG || {};
    return fetch(c.SUPABASE_URL + "/rest/v1/rpc/" + fn, {
      method: "POST",
      headers: {
        "apikey": c.SUPABASE_ANON_KEY,
        "Authorization": "Bearer " + c.SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body || {})
    }).then(function (r) {
      return r.json().then(function (j) {
        if (!r.ok) throw new Error((j && (j.message || j.hint)) || "Xəta baş verdi.");
        return j;
      });
    });
  }
  function show(h) { main.innerHTML = h; }
  function on(id, fn) { var e = document.getElementById(id); if (e) e.addEventListener("click", fn); }

  //  Dostun OZ muellimine deye bileceyi cumle.  Sehifenin esas isi budur:
  //  usaq burada qeydiyyatdan kece bilmez - MUELLIM odeyir.  Ona gore
  //  meqsed onu tetbiqe salmaq yox, elinde bir cumle qoymaqdir.
  function pitch() {
    return '<div class="scard spitch">' +
      "<p><b>Müəllimin bunu sinfə qura bilər.</b></p>" +
      "<s>Şagirdə pulsuzdur — kodla girirsən, testi işləyirsən, nəticəni dərhal görürsən.</s>" +
      '<a class="btn go" id="goBil" href="../?src=sual">Bil10 nədir?</a></div>' +
      '<p class="sfoot"><a href="../?src=sual">bil10.az</a> · onlayn test sistemi</p>';
  }
  function bindPitch() {
    on("goBil", function () {
      //  zencirin son addimi olculur: link -> acildi -> cavabladi -> KLIK
      if (K) { try { rpc("rpc_share_open", { p_k: K, p_ev: "click" }); } catch (e) {} }
    });
  }

  function err(bas, izah) {
    show('<div class="scard serr"><b>' + esc(bas) + "</b><p>" + esc(izah) + "</p></div>" + pitch());
    bindPitch();
  }

  if (!K) {
    err("Link tam deyil", "Sənə göndərilən linki bütöv kopyalayıb aç.");
    return;
  }

  rpc("rpc_share_open", { p_k: K }).then(function (d) {
    if (!d || !d.ok) {
      var r = d && d.reason;
      if (r === "vaxt") err("Bu linkin vaxtı bitib", "Linklər 7 gün işləyir. Dostundan yenisini istə.");
      else if (r === "hedd") err("Bu link bağlandı", "Çox dəfə açılıb. Dostundan yeni link istə.");
      else err("Belə bir sual tapılmadı", "Link səhv ola bilər — dostundan bir də göndərməsini istə.");
      return;
    }
    draw(d);
  }).catch(function (e) {
    err("Açıla bilmədi", String(e && e.message || e));
  });

  function draw(d) {
    var q = d.question || {};
    var kim = d.kim || "";
    var opts = q.options || [];
    show(
      '<div class="scard">' +
        '<div class="sfrom"><span class="sav">' + esc((kim || "?").charAt(0).toUpperCase()) + "</span>" +
          "<span><b>" + esc(kim) + "</b> sənə bir sual göndərdi — bacarırsan?</span></div>" +
        (q.topic ? '<p class="stopic">' + esc(q.topic) + "</p>" : "") +
        '<p class="sq">' + esc(q.body) + "</p>" +
        (q.media_url ? '<img class="sfig" src="' + esc(q.media_url) + '" alt="">' : "") +
        '<div class="sopts" id="opts">' +
          opts.map(function (o, i) {
            return '<button class="sopt" data-o="' + esc(o.id) + '">' +
              '<span class="k">' + "ABCDEF".charAt(i) + "</span>" +
              '<span class="t">' + esc(o.body) + "</span></button>";
          }).join("") + "</div>" +
        '<div id="fb"></div>' +
      "</div>"
    );
    Array.prototype.forEach.call(main.querySelectorAll("[data-o]"), function (b) {
      b.addEventListener("click", function () {
        if (busy) return;
        busy = true;
        var all = main.querySelectorAll("[data-o]");
        Array.prototype.forEach.call(all, function (x) { x.disabled = true; });
        rpc("rpc_share_answer", { p_k: K, p_option_id: b.getAttribute("data-o") })
          .then(function (r) {
            b.classList.add(r.correct ? "ok2" : "no2");
            //  duz variant YALNIZ cavabdan sonra bildirilir
            Array.prototype.forEach.call(all, function (x) {
              if (x.getAttribute("data-o") === r.right_id && x !== b) x.classList.add("ok2");
              else if (x !== b) x.classList.add("dim2");
            });
            document.getElementById("fb").innerHTML =
              '<div class="sfb ' + (r.correct ? "y" : "n") + '"><b>' +
                (r.correct ? "Düzdür! 🎯" : "Bu dəfə alınmadı.") + "</b>" +
                (r.explanation ? "<i>" + esc(r.explanation) + "</i>" : "") + "</div>";
            main.insertAdjacentHTML("beforeend", pitch());
            bindPitch();
          })
          .catch(function (e) {
            busy = false;
            Array.prototype.forEach.call(all, function (x) { x.disabled = false; });
            document.getElementById("fb").innerHTML =
              '<div class="sfb n">' + esc(String(e && e.message || e)) + "</div>";
          });
      });
    });
  }
})();
