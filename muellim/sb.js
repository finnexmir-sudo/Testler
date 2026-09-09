/* =====================================================================
   sb.js - Supabase ucun yungul muraciet qati
   Xarici kitabxana yoxdur: CDN yuklenmir, tedarik zenciri riski yoxdur.
   Yalniz lazim olan hisse: qeydiyyat, giris, token yenileme, select, rpc.
   ===================================================================== */
(function () {
  "use strict";

  var KEY = "panel_session";
  var S = null;

  function cfg() {
    var c = window.CFG || {};
    if (!c.SUPABASE_URL || !c.SUPABASE_ANON_KEY) {
      throw new Error("config.js doldurulmayib: SUPABASE_URL ve SUPABASE_ANON_KEY lazimdir.");
    }
    return c;
  }

  /*  JETONUN BITME VAXTI - oz mohurumuzla.
      Supabase cavabinda 'expires_in' (saniye) ve bezen 'expires_at'
      (unix) gelir.  Biz OZUMUZ mohur vururuq: indi + expires_in.
      Niye serverin 'expires_at'-ina guvenmirik: telefonun saati sehv
      qurulubsa hemin reqem yaniltir - saat geridedirse jeton "hele
      diridir" gorunur ve 401 yene qacilmaz olur.  Oz mohurumuz eyni
      saatla vurulur, ona gore saat serhi ozunu yeyir.
      Kohne sessiyada (mohursuz) sifir qayidir - hec ne deyismir,
      kohne 401 yolu isleyir; ilk yenilemeden sonra mohur da yaranir.  */
  var SKEW = 60000;        //  bir deqiqe ehtiyat - sorgu yolda ikeni bitmesin
  var refreshing = null;   //  eyni anda YALNIZ bir yenileme (paralel sorgular)
  var ended = false;       //  "sessiya bitdi" siqnali bir defe verilsin

  function stamp(s) {
    if (s && !s.sb_exp) {
      if (s.expires_in) s.sb_exp = Date.now() + Number(s.expires_in) * 1000;
      else if (s.expires_at) s.sb_exp = Number(s.expires_at) * 1000;
    }
    return s;
  }
  function tokenOld() {
    return !!(S && S.sb_exp && Date.now() > S.sb_exp - SKEW);
  }

  function loadSession() {
    try { S = JSON.parse(localStorage.getItem(KEY) || "null"); } catch (e) { S = null; }
    return S;
  }
  /*  Yaddasdakini GOTUR, amma bosaltma.  Basqa tab jetonu yenilemis
      ola biler - onu goturmek nahaq ikinci yenilemenin qarsisini alir.
      loadSession() burada ISLEMIR: gizli rejimde localStorage xeta
      atir ve S sifirlanardi - yeni is gorən sessiya ITERDI.  */
  function adoptStored() {
    var v = null;
    try { v = JSON.parse(localStorage.getItem(KEY) || "null"); } catch (e) { return; }
    if (v && v.access_token) S = v;
  }
  function saveSession(s) {
    S = stamp(s);
    if (S) ended = false;          //  teze sessiya - siqnal yeniden verile biler
    try {
      if (S) localStorage.setItem(KEY, JSON.stringify(S));
      else localStorage.removeItem(KEY);
    } catch (e) {}
  }

  function headers(withAuth) {
    var c = cfg();
    var h = {
      "apikey": c.SUPABASE_ANON_KEY,
      "Content-Type": "application/json"
    };
    if (withAuth && S && S.access_token) h["Authorization"] = "Bearer " + S.access_token;
    else h["Authorization"] = "Bearer " + c.SUPABASE_ANON_KEY;
    return h;
  }

  function readError(body, status) {
    var msg = "";
    if (body && typeof body === "object") {
      msg = body.message || body.error_description || body.msg || body.error || body.hint || "";
    }
    if (!msg) msg = "Xeta bas verdi (" + status + ").";
    return msg;
  }

  /* Sebeke xetasi (telefon internetı kesilende) fetch "Failed to fetch"
     atir - bu, istifadeciye hec ne demir. Bir defe tekrar cehd edirik,
     alinmasa anlasilan mesaj veririk. */
  function netFetch(url, init, tried) {
    return fetch(url, init).catch(function (e) {
      if (!tried) {
        return new Promise(function (res) { setTimeout(res, 900); })
          .then(function () { return netFetch(url, init, true); });
      }
      var err = new Error("İnternet bağlantısı yoxdur. Yenidən cəhd et.");
      err.offline = true;
      throw err;
    });
  }

  /*  Sessiya bitdi - 401 yolu ile onceden yenileme yolu eyni cumleni
      demelidir, ona gore bir yerdedir.  */
  function sessionEnded() {
    saveSession(null);
    if (!ended) {
      ended = true;
      //  butun ekranlar ucun merkezi siqnal - app giris ekranina qaytarir.
      //  GECIKDIRILIR (setTimeout): cagiran ekran oz "xeta" kartini elə
      //  indi cizir; siqnal ondan SONRA gelmelidir ki, giris formasi
      //  ustde qalsin.  Eks halda istifadeci "Sessiya bitib" yazan xeta
      //  kartinda ilisir - giris formasi hec cixmir.
      setTimeout(function () {
        try { window.dispatchEvent(new Event("sb:sessionend")); } catch (e) {}
      }, 0);
    }
    var e2 = new Error("Sessiya bitib. Yeniden daxil olun.");
    e2.session = true;
    throw e2;
  }

  /*  ONCEDEN YENILEME (olculub: ilk aciilisda 1-2 saniye).
      Jeton bir saat yasayir.  Evvel zencir bele idi:
        sorgu -> 401 -> yenileme -> tekrar sorgu     = 3 gedis-gelis
      Indi jetonun vaxti kecibse:
        yenileme -> sorgu                            = 2 gedis-gelis
      Jeton diridirse HEC NE deyismir - elave sorgu getmir.  */
  function request(path, opt, retry) {
    opt = opt || {};
    if (opt.auth !== false && !retry && tokenOld()) {
      //  Basqa tab (ve ya bu sehifenin evvelki sorgusu) artiq
      //  yenilemis ola biler - once yaddasdakini oxu, nahaq yere
      //  ikinci yenileme gonderme (Supabase yenileme jetonunu
      //  DEYISIR, ust-uste dusen iki yenileme sessiyani qira biler).
      adoptStored();
      if (tokenOld() && S && S.refresh_token) {
        return refresh().then(function (ok) {
          if (!ok) return sessionEnded();
          return send(path, opt, true);
        });
      }
    }
    return send(path, opt, retry);
  }

  function send(path, opt, retry) {
    var c = cfg();
    return netFetch(c.SUPABASE_URL + path, {
      method: opt.method || "GET",
      headers: headers(opt.auth !== false),
      body: opt.body ? JSON.stringify(opt.body) : undefined
    }).then(function (r) {
      return r.text().then(function (t) {
        var data = null;
        if (t) { try { data = JSON.parse(t); } catch (e) { data = t; } }
        if (r.ok) return data;

        // Token kohnelibse bir defe yenileyib tekrar cehd edirik
        if (r.status === 401 && !retry && S && S.refresh_token) {
          return refresh().then(function (ok) {
            if (!ok) return sessionEnded();
            return send(path, opt, true);
          });
        }
        var err = new Error(readError(data, r.status));
        err.status = r.status;
        err.body = data;
        throw err;
      });
    });
  }

  /*  TEK UCUS: eyni anda bes sorgu 401 alsa da yenileme BIR defe
      gedir.  Supabase yenileme jetonunu her istifadede deyisir -
      paralel iki yenileme ikincisini "kohne jeton" sayib sessiyani
      qirardi.  */
  function refresh() {
    if (refreshing) return refreshing;
    if (!S || !S.refresh_token) return Promise.resolve(false);
    var c = cfg();
    var tok = S.refresh_token;
    refreshing = fetch(c.SUPABASE_URL + "/auth/v1/token?grant_type=refresh_token", {
      method: "POST",
      headers: { "apikey": c.SUPABASE_ANON_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: tok })
    }).then(function (r) {
      if (!r.ok) return false;
      return r.json().then(function (d) {
        if (!d || !d.access_token) return false;
        saveSession(d);
        return true;
      });
    }).catch(function () { return false; })
      .then(function (ok) { refreshing = null; return ok; });
    return refreshing;
  }

  var sb = {
    session: function () { return S; },
    loadSession: loadSession,

    signUp: function (email, password, fullName) {
      return request("/auth/v1/signup", {
        method: "POST", auth: false,
        body: { email: email, password: password, data: { full_name: fullName || "" } }
      }).then(function (d) {
        // E-poct tesdiqi acıqdirsa access_token gelmir - istifadeci postu yoxlamalidir
        if (d && d.access_token) saveSession(d);
        return d;
      });
    },

    /*  Anonim giris (numune hesab, db/136): Supabase-de "Allow anonymous
        sign-ins" acıq olmalidir.  Bagli olanda 422 qayidir - tetbiq
        "numune hazir deyil" deyir.  */
    signInAnon: function () {
      return request("/auth/v1/signup", { method: "POST", auth: false, body: {} })
        .then(function (d) {
          if (!d || !d.access_token) throw new Error("Anonim giriş alınmadı.");
          saveSession(d);
          return d;
        });
    },

    signIn: function (email, password) {
      return request("/auth/v1/token?grant_type=password", {
        method: "POST", auth: false,
        body: { email: email, password: password }
      }).then(function (d) {
        if (!d || !d.access_token) throw new Error("Giris alinmadi.");
        saveSession(d);
        return d;
      });
    },

    /* Parol berpasi: e-pocta link gonderilir; linke kecende Supabase
       istifadecini redirect_to unvanina token ile qaytarir. */
    recover: function (email, redirectTo) {
      return request("/auth/v1/recover?redirect_to=" +
                     encodeURIComponent(redirectTo || ""), {
        method: "POST", auth: false,
        body: { email: email }
      });
    },

    /* Berpa linkinden gelen tokenlerle sessiya qurulur */
    setSession: function (accessToken, refreshToken) {
      saveSession({ access_token: accessToken, refresh_token: refreshToken });
    },

    /* Yeni parol - aktiv sessiya ile */
    updatePassword: function (newPass) {
      return request("/auth/v1/user", {
        method: "PUT",
        body: { password: newPass }
      });
    },

    signOut: function () {
      var had = !!(S && S.access_token);
      var p = had ? request("/auth/v1/logout", { method: "POST" }).catch(function () {}) 
                  : Promise.resolve();
      return p.then(function () { saveSession(null); });
    },

    rpc: function (fn, args) {
      return request("/rest/v1/rpc/" + encodeURIComponent(fn), {
        method: "POST", body: args || {}
      });
    },

    /* select("students", {select:"id,full_name", eq:{class_id:x}, order:"full_name"}) */
    select: function (table, o) {
      o = o || {};
      var q = [];
      q.push("select=" + encodeURIComponent(o.select || "*"));
      if (o.eq) {
        Object.keys(o.eq).forEach(function (k) {
          q.push(encodeURIComponent(k) + "=eq." + encodeURIComponent(o.eq[k]));
        });
      }
      if (o.order) q.push("order=" + encodeURIComponent(o.order));
      return request("/rest/v1/" + encodeURIComponent(table) + "?" + q.join("&"));
    },

    /* update("classes", {id: x}, {name: "Yeni ad"}) */
    update: function (table, eq, patch) {
      var q = Object.keys(eq).map(function (k) {
        return encodeURIComponent(k) + "=eq." + encodeURIComponent(eq[k]);
      });
      return request("/rest/v1/" + encodeURIComponent(table) + "?" + q.join("&"),
                     { method: "PATCH", body: patch });
    },

    del: function (table, eq) {
      var q = Object.keys(eq).map(function (k) {
        return encodeURIComponent(k) + "=eq." + encodeURIComponent(eq[k]);
      });
      return request("/rest/v1/" + encodeURIComponent(table) + "?" + q.join("&"),
                     { method: "DELETE" });
    }
  };

  loadSession();
  window.sb = sb;
})();
