// Kesr cevirmesinin vahid testi:  node test/kesr_vahid.js
// muellim/app.js ve sagird/app.js-deki KESR blokunun EYNI oldugunu da yoxlayir.
const fs = require("fs");
const blok = (f) => {
  const s = fs.readFileSync(f, "utf8");
  const a = s.indexOf("//  KESR-BASLA"), b = s.indexOf("//  KESR-SON");
  if (a < 0 || b < 0) throw new Error(f + ": KESR bloku yoxdur");
  return s.slice(a, b);
};
const A = blok("muellim/app.js"), B = blok("sagird/app.js");
let fails = 0;
const ok = (c, l, x) => { console.log((c ? "  OK   " : "  FAIL ") + l + (x ? "  " + x : "")); if (!c) fails++; };
ok(A === B, "muellim ve sagird kodu EYNIDIR");

const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g,
  (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const qt = new Function("esc", A + "; return qt;")(esc);
// Kesr elementini [a/b] kimi, tam hisseni {w}[a/b] kimi yazir - oxumaq asan olsun
const oxu = (h) => h
  .replace(/<span class="kmix"[^>]*><span class="kw"[^>]*>(\d+)<\/span><span class="ks"> <\/span><span class="kesr"[^>]*><span class="kn"[^>]*>(\d+)<\/span><span class="ks">\/<\/span><span class="kd"[^>]*>(\d+)<\/span><\/span><\/span>/g, "{$1|$2/$3}")
  .replace(/<span class="kesr"[^>]*><span class="kn"[^>]*>(\d+)<\/span><span class="ks">\/<\/span><span class="kd"[^>]*>(\d+)<\/span><\/span>/g, "[$1/$2]");
const eq = (girish, gozlenen) => { const c = oxu(qt(girish)); ok(c === gozlenen, JSON.stringify(girish) + " -> " + c, c === gozlenen ? "" : "(gozlenen " + gozlenen + ")"); };

console.log("Cevrilenler");
eq("3/4", "[3/4]");
eq("17/12", "[17/12]");
eq("9/9, 8/1, 1/7, 6/5 kesrlerinden", "[9/9], [8/1], [1/7], [6/5] kesrlerinden");
eq("12 1/4", "{12|1/4}");
eq("Cemi 3 1/2 saat", "Cemi {3|1/2} saat");
eq("−3/7", "−[3/7]");
eq("-3/7", "-[3/7]");
eq("1/2-dən", "[1/2]-dən");
eq("3/4-ü", "[3/4]-ü");
eq("12 5/4", "12 [5/4]");                 // duzgun deyil: tam hisse ayrilir
eq("0,5 1/2", "0,5 [1/2]");               // tam eded onluq hissenin sonudur
eq("1/2 3/4", "[1/2] [3/4]");
eq("1. 3/4", "1. [3/4]");

console.log("Cevrilmeyenler");
["km/saat", "q/sm³", "x/6", "a/b", "2/3/4", "0,(3)", "2,41(6)", "0,5/2", "3/4,5", "0.5/2", "3/4.5",
 "12/05/2024", "1 2/3/4", "10 000 / 5", "3 / 4", "5/", "/5"].forEach((t) => eq(t, t));

console.log("Tehlukesizlik (HTML kecmir)");
["<b>1</b>/2", '"><img src=x onerror=alert(1)>', "1/2<script>alert(1)</script>", "&lt;b&gt;3/4",
 "'onmouseover='alert(1)", "3/4</span><img src=x>"].forEach((t) => {
  const c = qt(t);
  //  hec bir <span>-dan basqa element ve hec bir olay atributu (span daxilinde de) yoxdur
  const tags = (c.match(/<[^>]+>/g) || []).every((x) => /^<\/?span\b/.test(x) && !/\son[a-z]+=/i.test(x) && !/\ssrc=/i.test(x));
  ok(tags, "xam HTML yoxdur: " + JSON.stringify(t), c.slice(0, 90));
});
// esc-den kecmis metnin GORUNEN hissesi deyismir
const gor = (h) => h.replace(/<[^>]+>/g, "");
ok(gor(qt("<b>1</b>/2")) === "&lt;b&gt;1&lt;/b&gt;/2", "gorunen metn esc ile eynidir");
ok(gor(qt("3/4 və 12 1/4")) === "3/4 və 12 1/4", "kesr mətni kopyalananda eyni qalir");
console.log(fails ? "\nSINDI: " + fails : "\nHAMISI KECDI");
process.exit(fails ? 1 : 0);
