/*  PULSUZ HEDD <-> ABUNE FERQI - TEK MENBE, UC EKRAN UCUN.
    ================================================================
    Bu siyahi UC yerde gorunur:
      - panel, hediyye karti (Icmal)
      - panel, Abune sehifesi
      - ana sehife, «Nə pulsuz, nə abunədə» bolmesi
    Ona gore MENBE BURADADIR, hec bir ekranda tekrarlanmir.  Kohne
    xeberdarliq qalir: siyahi tekrarlansa, bir imkan deyisende bir yer
    yenilenir, o biri kohne qalir - ve YALAN VED yaranir.  Pul metnidir,
    duzeldilmesi en bahali cur sehvdir.

    Ana sehife serverle danismir: oradan «free» gelmir, susma 5 islenir
    (asagidaki serhe bax).  QIYMET REQEMI BURADA YOXDUR - o, ayrica
    ferqBasliq()-dedir ve yalniz panelde, serverden gelir.
    ================================================================  */
(function (w) {
  "use strict";

/*  PULSUZ HEDD <-> ABUNE FERQI - TEK MENBE.
    Iki yerde islenir: hediyye karti (esas sehife) ve Abune sehifesi.
    Siyahi TEKRARLANMAMALIDIR - yoxsa bir imkan deyisende bir yer
    yenilenir, o biri kohne qalir ve YALAN VED yaranir.  Bendler
    koddaki app.has_active_subscription qapilari ile uygunlasdirilib.  */
function siyahi(free) {
  //  Esas sehifede server bu reqemi vermir (rpc_my_context-de yoxdur),
  //  ona gore susma 5-dir.  O, app.free_seat_limit() ile EYNI olmalidir -
  //  db/test/smoke_qiymet.sql bunu yoxlayir, deyisse test dayanir.
  free = Number(free) || 5;
  //  «Limitsiz şagird» BU SIYAHIDA DEYIL - qiymet qaydasi kimi
  //  siyahinin USTUNDE, mebleqle birlikde yazilir (ferqBasliq).
  //  Sebeb (istifadeci tutdu): qalan bendlerin hamisi «abune alanda
  //  ACILAN imkandir», sagird sayi ise ODEDIYIN VAHIDDIR.  Eyni
  //  siyahida, reqemsiz duranda goz onu da «daxildir» kimi oxuyur -
  //  hesab gelende «limitsiz yazilmisdi» deyilir.  Pul isinde bu,
  //  duzeldilmesi en bahali cur seydir.
  return {
    pulsuz: [
      "<b>" + free + " şagird yeri</b>",
      "Öz suallarınız və öz testləriniz — tam işləyir",
      "Nəticə: kim neçə faiz topladı",
      //  rpc_parent_login-de abune serti YOXDUR; rpc_parent_home-da
      //  yalniz «zeif movzular» abuneyle acilir - qalani pulsuzdur.
      //  Bu, pulsuz heddin en guclu tereflerinden biridir.
      "<b>Valideyn girişi</b> — uşağın nəticəsi, meyli, gözləyən tapşırıqlar",
      "Hesabat tarixçəsi: <b>son 7 gün</b>",
      "Şagird məşqi: <b>gündə 20 sual</b>"
    ],
    abune: [
      "<b>Hazır suallar</b> — özünüz sual yazmadan test yığmaq",
      //  db/106 + db/132: v_keys.  Abunesiz hesab bank siyahisinda
      //  sualin METNINI gorur, variantlari ve duz cavabi YOX.
      //  Siyahida yox idi - elave olundu (audit, 2026-09-09).
      "Hazır sualların <b>variantları və düz cavabı</b> — siyahıda görünür",
      "Avtomatik test yığımı — mövzu və çətinliyə görə",
      "<b>Diaqnostika</b> — sinif üzrə səviyyə xəritəsi; təkrarında «əvvəl → indi» fərqi",
      "Zəif mövzu analizi — qrup, şagird və <b>valideyn</b> ekranında",
      "Dərs planı və kurikulum paketi — il əvvəlcədən hazır: " +
        "«bugünkü dərs», isinmə sualları, ev tapşırığı, sınaq",
      "Şagird üçün fərdi plan",
      "<b>Təhlükə siqnalları</b> — kim geriləyir, kim ilişib: sistem özü deyir",
      "Düzəliş — təkrar-səhv testi",
      "Cavab vərəqi — sual-sual nə yazıb",
      "Bütün hesabat tarixçəsi",
      "Şagirdə limitsiz mövzu məşqi"
    ]
  };
}

  w.FERQ = { siyahi: siyahi };
})(window);
