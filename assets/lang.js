/*  Ana sehifenin dil duymesi: AZ | RU.
    Menbe HTML Azerbaycancadir (axtaris sistemi ve kohne linkler ucun).
    Rus dilini secende her yazi dugunu asagidaki lugetle deyisdirilir.
    Lugetin acari - Azerbaycanca metnin bosluqlari sixilmis hali; metn
    deyisilende acar uygun gelmeyecek ve test/e2e_ana_dil.py bunu tutacaq.
    Daxil edilen hec ne istifadecidan gelmir - yalniz bu fayldaki sabit metn.  */
(function () {
  "use strict";
  var KEY = "bil10_lang";

  var RU = {
    "Necə işləyir": "Как это работает",
    "Video": "Видео",
    "İmkanlar": "Возможности",
    "Bələdçi": "Руководство",
    "Hesabınıza keçin": "Войти в аккаунт",
    "Giriş": "Вход",
    "Beta dövrü · müəllimlər üçün": "Бета-период · для учителей",
    "Şagirdinizin nəyi bilmədiyini": "Чего не знает ваш ученик —",
    "görün.": "теперь видно.",
    "Bil10 diaqnostika, test və fərdi məşqi birləşdirir: hər şagirdin zəif mövzusunu tapır və növbəti addımı göstərir. Siz testi verirsiniz, qalanını sistem edir.":
      "Bil10 объединяет диагностику, тесты и индивидуальную практику: находит слабую тему каждого ученика и показывает следующий шаг. Вы даёте тест — остальное делает система.",
    "Özünüz sınayın, fərqi görün:": "Попробуйте сами и увидите разницу:",
    "Müəllim kimi bax": "Посмотреть как учитель",
    "hazır qrup, hesabat — qeydiyyatsız": "готовая группа, отчёт — без регистрации",
    "Hesab yarat": "Создать аккаунт",
    "1 dəqiqə — ad, e-poçt, parol": "1 минута — имя, e-mail, пароль",
    "Kodun var?": "Есть код?",
    "Şagirdəm": "Я ученик",
    "kodla gir": "вход по коду",
    "Valideynəm": "Я родитель",
    "Müəllim hesabınız var?": "Есть аккаунт учителя?",
    "Müəllim paneli": "Панель учителя",
    "7-ci sinif · Riyaziyyat": "7 класс · Математика",
    "Diaqnostika bitdi": "Диагностика завершена",
    "Şagirdin nəticəsi": "Результат ученика",
    "Aysel M.": "Айсель М.",
    "Diaqnostika · 20 sual · 14 düz": "Диагностика · 20 вопросов · 14 верно",
    "ümumi nəticə": "общий результат",
    "Kəsrlər": "Дроби",
    "yaxşı · 92%": "хорошо · 92%",
    "Tənliklər": "Уравнения",
    "orta · 55%": "средне · 55%",
    "Faizlər": "Проценты",
    "zəif · 30%": "слабо · 30%",
    "Qrup üzrə": "По группе",
    "orta nəticə · 12 şagird": "средний результат · 12 учеников",
    "yaxşı: 4": "хорошо: 4",
    "orta: 5": "средне: 5",
    "zəif: 3": "слабо: 3",
    "Bundan başla": "Начните отсюда",
    "Faizlər — qrupun yarısı zəifdir. 5 suallıq isinmə testi hazırdır, bir toxunuşla göndərin.":
      "Проценты — у половины группы слабо. Разминочный тест из 5 вопросов готов, отправьте одним касанием.",
    "Nümunə məlumat — real ekran panelin içindədir.": "Пример данных — настоящий экран находится внутри панели.",
    "Bal serverdə hesablanır": "Баллы считаются на сервере",
    "Bir diaqnostikadan sonra üç cavab:": "После одной диагностики — три ответа:",
    "Kim hazırdır?": "Кто готов?",
    "Nəyi təkrar edim?": "Что повторить?",
    "Növbəti dərs nədən başlasın?": "С чего начать следующий урок?",
    "Nəticəni göstərmir.": "Не просто показывает результат.",
    "Nəticədən növbəti addımı çıxarır.": "Из результата выводит следующий шаг.",
    "Dörd addım, hər həftə eyni dövrə. Qurmaq bir dəfəlik işdir.":
      "Четыре шага, каждую неделю один и тот же цикл. Настроить нужно один раз.",
    "Addım-addım bələdçi, ekran şəkilləri ilə →": "Пошаговое руководство со скриншотами →",
    "Diaqnostika verin": "Дайте диагностику",
    "Hazır bankdan, sinfə görə. Şagird kodla girir, telefonda həll edir — qeydiyyat yoxdur.":
      "Из готового банка, по классу. Ученик входит по коду и решает на телефоне — регистрации нет.",
    "Zəif mövzunu tapın": "Найдите слабую тему",
    "Hər şagird üçün mövzu-mövzu: zəif, orta, yaxşı. Bil10 «bundan başla» deyir.":
      "По каждому ученику, тема за темой: слабо, средне, хорошо. Bil10 подсказывает: «Начните отсюда».",
    "Məşq etdirin": "Дайте потренироваться",
    "Həmin mövzudan təkrar test bir toxunuşla; səhv etdiyi suallar səhv dəftərində yenidən gəlir.":
      "Повторный тест по этой теме — одним касанием; вопросы, в которых ученик ошибся, возвращаются в тетради ошибок.",
    "Yenidən ölçün": "Измерьте ещё раз",
    "Diaqnostikanı təkrar verin: «əvvəl → indi» fərqi şagirddə, qrupda və valideynin ekranında.":
      "Дайте диагностику повторно: разница «было → стало» видна у ученика, в группе и на экране родителя.",
    "Brauzeriniz videonu göstərmir.": "Ваш браузер не показывает видео.",
    "Video təqdimat": "Видеопрезентация",
    "Proqram": "Программа",
    "1,5 dəqiqəyə": "за 1,5 минуты",
    "— 10 səhnə, real ekranlar": "— 10 сцен, реальные экраны",
    "Qrupdan hesabata, dərs planından valideyn tətbiqinə — hər səhnə bir real ekran və iki cümlə izah. Səs yoxdur, telefonda səssiz də baxılır.":
      "От группы до отчёта, от плана урока до приложения для родителей — в каждой сцене один реальный экран и два предложения пояснения. Звука нет, можно смотреть на телефоне без звука.",
    "Bu, qısa baxışdır — addım-addım izah və bütün imkanlar": "Это краткий обзор — пошаговые пояснения и все возможности",
    "bələdçidədir →": "в руководстве →",
    "Sürət:": "Скорость:",
    "Normal": "Обычная",
    "Tez gəlirsə yavaşladın — seçim yadda qalır.": "Если слишком быстро — замедлите: выбор запоминается.",
    "Hazır sual bankı": "Готовый банк вопросов",
    "— 1–11-ci siniflər, 12 fənn; test bir dəqiqəyə yığılır": "— 1–11 классы, 12 предметов; тест собирается за минуту",
    "Diaqnostika": "Диагностика",
    "— hər şagird üçün mövzu-mövzu: zəif · orta · yaxşı, «bundan başla»":
      "— по каждому ученику тема за темой: слабо · средне · хорошо, «Начните отсюда»",
    "Kurikulum üzrə dərs planı": "План уроков по программе",
    "— bu günün dərsi, isinmə 5 sual, ev tapşırığı": "— урок на сегодня, разминка из 5 вопросов, домашнее задание",
    "Şagird kodla girir": "Ученик входит по коду",
    "— qeydiyyat yoxdur; bal serverdə hesablanır": "— регистрации нет; баллы считаются на сервере",
    "Valideyn öz kodu ilə": "Родитель — по своему коду",
    "— nəticə, zəif mövzular, davamiyyət, gözləyən tapşırıq": "— результат, слабые темы, посещаемость, ожидающее задание",
    "Bəyəndiniz? Hesab yaradın.": "Понравилось? Создайте аккаунт.",
    "Bir dəqiqə çəkir: ad, e-poçt, parol — sonra ilk qrupunuzu yaradıb şagirdə kodu göndərirsiniz.":
      "Это займёт минуту: имя, e-mail, пароль — затем вы создаёте первую группу и отправляете ученику код.",
    "Bələdçini oxu": "Прочитать руководство",
    "Bil10 beta versiyasındadır.": "Bil10 находится в бета-версии.",
    "Rəy və təklifləriniz bizim üçün vacibdir — hər birini diqqətlə oxuyub nəzərə alırıq.":
      "Ваши отзывы и предложения важны для нас — мы внимательно читаем каждый и учитываем.",
    "Bir ekranda şagirdinizi, dərsinizi, qərarınızı görün.": "Ученик, урок и решение — на одном экране.",
    "Repetitorun həftəlik vaxtını yeyən işlər — sual yazmaq, yoxlamaq, valideynə hesabat — sistemin üstündədir. Siz dərsə qalırsınız.":
      "Работа, которая съедает время репетитора, — писать вопросы, проверять, отчитываться перед родителями — ложится на систему. Вам остаётся урок.",
    "1–11-ci siniflər, 12 məktəb fənni. Mövzu və çətinliyi seçirsiniz, test özü yığılır. Öz suallarınızı da əlavə edirsiniz.":
      "1–11 классы, 12 школьных предметов. Вы выбираете тему и сложность — тест собирается сам. Свои вопросы тоже можно добавлять.",
    "Doğru cavab şagirdin cihazına heç vaxt getmir. Köçürmək və nəticəni dəyişmək mümkün deyil.":
      "Правильный ответ никогда не попадает на устройство ученика. Списать или изменить результат невозможно.",
    "Zəif mövzu hesabatı": "Отчёт по слабым темам",
    "«Vurmada 92%, mətn məsələsində 41%» — dərsi hara yönəldəcəyiniz özü görünür.":
      "«Умножение — 92%, текстовые задачи — 41%» — сразу видно, куда направить урок.",
    "Son tarix və cəhd limiti": "Срок сдачи и лимит попыток",
    "Tapşırıq vaxtında bağlanır. Neçə dəfə işləyə biləcəyini siz təyin edirsiniz.":
      "Задание закрывается вовремя. Сколько раз его можно выполнять — решаете вы.",
    "Liderlər lövhəsi": "Таблица лидеров",
    "Qrup daxilində sağlam yarış. Şagird tam soyadı görmür — yalnız qısa ad.":
      "Здоровое соревнование внутри группы. Ученик не видит полной фамилии — только короткое имя.",
    "Səhvin izahı": "Объяснение ошибки",
    "Şagird səhv edəndə qaydanı orada görür — hər dəfə sizdən soruşmur.":
      "Когда ученик ошибается, он сразу видит правило и не спрашивает вас каждый раз.",
    "Qeydiyyatsız giriş": "Вход без регистрации",
    "Şagird və valideyn üçün qeydiyyat yoxdur.": "Ученику и родителю регистрация не нужна.",
    "E-poçt də lazım deyil. Şagird müəllimin verdiyi kodu yazır, testi işləyir, nəticəsini görür; valideyn öz kodu ilə uşağının gedişatına baxır.":
      "E-mail тоже не нужен. Ученик вводит код, который дал учитель, решает тест и видит результат; родитель по своему коду следит за успехами ребёнка.",
    "Bal serverdə hesablanır, cavab cihaza getmir": "Баллы считаются на сервере, ответ не попадает на устройство",
    "Şagird tam soyadla görünmür": "Ученик не отображается с полной фамилией",
    "Məlumat reklam üçün istifadə edilmir": "Данные не используются для рекламы",
    "Etibar": "Доверие",
    "Şagird məlumatı ilə işləyərkən rahat olun.": "Работайте с данными учеников спокойно.",
    "Siz yalnız öz qruplarınızı və onların nəticəsini görürsünüz. Nə saxlanır, nə saxlanmır —":
      "Вы видите только свои группы и их результаты. Что сохраняется, а что нет —",
    "məxfilik siyasətində →": "в политике конфиденциальности →",
    "İlk addım sizdən": "Первый шаг — за вами",
    "Növbəti dərsiniz üçün aydın başlanğıc yaradın.": "Начните следующий урок с ясной точки отсчёта.",
    "Müəllimin qərarını aydınlaşdıran diaqnostika.": "Диагностика, которая проясняет решение учителя.",
    "Beta · hazırlıq mərhələsindədir": "Бета · на стадии подготовки",
    "Sayt": "Сайт",
    "Məxfilik": "Конфиденциальность",
    "Nümunə hesab": "Демо-аккаунт",
    "Şagird girişi": "Вход для учеников",
    "Valideyn girişi": "Вход для родителей",
    "Əlaqə": "Контакты",
    "© 2026 Bil10 · onlayn test sistemi": "© 2026 Bil10 · система онлайн-тестирования",
    "Bütün hüquqlar qorunur": "Все права защищены"
  };

  var RU_ATTR = {
    "Sürət": "Скорость",
    "Videoda nə görəcəksiniz": "Что вы увидите в видео"
  };

  var META = {
    title: "Bil10 — онлайн-система тестирования для репетиторов и учителей",
    description: "Bil10 — онлайн-система тестирования для репетиторов и учителей. Создайте группу, назначьте задание — результаты соберутся автоматически."
  };

  function norm(s) { return s.replace(/\s+/g, " ").trim(); }

  var orig = [];          // [{n: textNode, az: "boşluqlu orijinal"}]
  var origAttr = [];      // [{e: element, k: "aria-label", az: "..."}]
  var origMeta = null;

  function collect() {
    var w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT), n;
    while ((n = w.nextNode())) {
      var pe = n.parentElement;
      if (!pe || /^(SCRIPT|STYLE)$/.test(pe.tagName) || pe.closest("svg")) continue;
      if (norm(n.nodeValue)) orig.push({ n: n, az: n.nodeValue });
    }
    var els = document.querySelectorAll("[aria-label]");
    for (var i = 0; i < els.length; i++)
      origAttr.push({ e: els[i], k: "aria-label", az: els[i].getAttribute("aria-label") });
    var d = document.querySelector('meta[name="description"]');
    origMeta = { title: document.title, d: d, desc: d ? d.getAttribute("content") : "" };
  }

  //  Bosluqlari (bas/son) qoruyub icindeki metni evez edir
  function swap(az, ru) {
    var m = /^(\s*)([\s\S]*?)(\s*)$/.exec(az);
    return m[1] + ru + m[3];
  }

  function apply(lang) {
    if (!orig.length) collect();
    var ru = lang === "ru", i, o;
    for (i = 0; i < orig.length; i++) {
      o = orig[i];
      var t = ru ? RU[norm(o.az)] : null;
      o.n.nodeValue = t ? swap(o.az, t) : o.az;
    }
    for (i = 0; i < origAttr.length; i++) {
      o = origAttr[i];
      o.e.setAttribute(o.k, (ru && RU_ATTR[o.az]) || o.az);
    }
    document.title = ru ? META.title : origMeta.title;
    if (origMeta.d) origMeta.d.setAttribute("content", ru ? META.description : origMeta.desc);
    document.documentElement.lang = ru ? "ru" : "az";
    var bs = document.querySelectorAll(".lsw [data-lang]");
    for (i = 0; i < bs.length; i++) {
      var on = bs[i].getAttribute("data-lang") === lang;
      bs[i].classList.toggle("on", on);
      bs[i].setAttribute("aria-pressed", on ? "true" : "false");
    }
  }

  function saved() {
    var q = /[?&]lang=(ru|az)\b/.exec(location.search);
    if (q) return q[1];
    try { var v = localStorage.getItem(KEY); if (v === "ru" || v === "az") return v; } catch (e) {}
    return "az";
  }

  function set(lang) {
    try { localStorage.setItem(KEY, lang); } catch (e) {}
    apply(lang);
  }

  function init() {
    var bs = document.querySelectorAll(".lsw [data-lang]");
    for (var i = 0; i < bs.length; i++)
      bs[i].addEventListener("click", function () { set(this.getAttribute("data-lang")); });
    var l = saved();
    if (l === "ru") apply("ru");
    else {
      for (var j = 0; j < bs.length; j++)
        bs[j].classList.toggle("on", bs[j].getAttribute("data-lang") === "az");
    }
  }

  //  Yoxlama ucun acilir (test/e2e_ana_dil.py)
  window.__bil10Lang = { RU: RU, norm: norm, set: set };
  init();
})();
