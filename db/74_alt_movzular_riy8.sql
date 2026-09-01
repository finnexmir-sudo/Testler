-- =====================================================================
--  74_alt_movzular_riy8.sql : RIYAZIYYAT 8 - ALT MOVZULAR (SINAQ)
--
--  NIYE
--  Ders planinda indiye qeder yalniz movzu basliqlari vardi
--  ("Kvadrat tenlikler").  Muellim hemin movzunun 2 dersini kecende
--  bunu qeyd ede bilmirdi: ya hamisini "kecildi" edirdi (yalan), ya
--  hec ne.  Alt movzular plani real ders ritmi ile ust-uste salir.
--
--  EHATE: yalniz Riyaziyyat, 8-ci sinif.  Bu, SINAQDIR - beyenilse
--  qalan fenlere kecirik.  Basqa fenne/sinfe toxunulmur.
--
--  MENBE: e-derslik.edu.az, Riyaziyyat 8 (book_id 393), sag paneldeki
--  "Movzular" agaci.  Adlar EYNILE goturulub - qisaltma, birlesdirme
--  ve ya uydurma yoxdur.  Derslikdeki sira sort-a dusub.
--
--  YAZI QUSURLARI DUZELDILIB (mezmun deyismeyib - yalniz durgu
--  isaresinden sonra dusen bosluq ve sondaki artiq noqte):
--      "...helli.Kvadrat tenliyin..."      -> ". Kvadrat"
--      "...vurulmasi,bolunmesi..."          -> ", bolunmesi"
--      "Oxsar dordbucaqlilar,oxsar..."      -> ", oxsar"
--      "Fiqurlarin cevrilmesi.Donme"        -> ". Donme"
--      "Oxsarliq cevrilmesi.Homotetiya"     -> ". Homotetiya"
--      "...oxsarliginin tetbiqi."           -> sondaki noqte atildi
--
--  DUSEN DUSTER SIMVOLU DUZELDILIB (2026-08, illik yoxlama):
--      "y = x ve y = kok(x) funksiyalari"  ->  "y = x^2 ve y = kok(x)"
--  Portalin mundericat paneli ust indeksi atir; dogru ad kitabin
--  s.18 basligindan goturuldu.  Slug deyismir - ders plani ve
--  "kecildi" tarixcesi oldugu kimi qalir.
--  Keşdeki nusxe (mundericat/riyaziyyat-8-393.txt) canli portalla
--  setir-setir tutusdurulub: 11 bolme, 77 movzu - eynidir.
--
--  74 alt movzu yazilir.  Derslikdeki 77 bendden 3-i xaricdedir -
--  onlar kitabin SONUNDAKI bendlerdir, 11-ci bolmenin dersi deyil:
--      "Bolmeler uzre umumilesdirici tapsiriqlar" (s. 227)
--      "Ozunuzu yoxlayin"                          (s. 232)
--      "Cavablar"                                  (s. 234)
--  Lazim olsa bunlar da elave edile biler.
--
--  DIQQET
--   * questions cedveline TOXUNULMUR - suallar alt movzulara
--     baglanmir, teqler deyismir.  O, ayri merhelendir.
--   * Movcud 11 movzu setri deyismir - yalniz parent kimi istifade
--     olunur.  programs/levels-e de toxunulmur.
--   * Tekrar isledile biler (on conflict do update).
--
--  ON SERT: 37_movzular_orta8.sql islenmis olmalidir.
-- =====================================================================

do $$
begin
  if (select count(*) from public.topics t
        join public.subjects s on s.id = t.subject_id and s.slug = 'riyaziyyat'
        join public.levels   l on l.id = t.level_id and l.code = '8'
       where t.parent_id is null) <> 11 then
    raise exception 'ONCE 37_movzular_orta8.sql isledilmelidir '
                    '(Riyaziyyat 8 ucun 11 ust movzu gozlenilir).';
  end if;
end $$;

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  1. Kvadrat kök. Həqiqi ədədlər
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-hesabi',
     'Kvadrat köklər. Hesabi kvadrat kök', 10),
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-heqiqi',
     'Həqiqi ədədlər', 20),
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-funksiya',
     'y = x² və y = √x funksiyaları', 30),
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-xasse',
     'Hesabi kvadrat kökün xassələri', 40),
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-xasse-tetbiq',
     'Hesabi kvadrat kökün xassələrinin tətbiqi', 50),
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-quvvet',
     'Tam üstlü qüvvət', 60),
    ('riy-8-kvadrat-kok', 'riy-8-kvadrat-kok-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  2. Pifaqor teoremi
    ('riy-8-pifaqor', 'riy-8-pifaqor-teorem',
     'Pifaqor teoremi', 10),
    ('riy-8-pifaqor', 'riy-8-pifaqor-tetbiq',
     'Pifaqor teoreminin tətbiqi', 20),
    ('riy-8-pifaqor', 'riy-8-pifaqor-umumi',
     'Ümumiləşdirici tapşırıqlar', 30),
    --  3. Kvadrat tənliklər
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-anlayis',
     'Kvadrat tənliklər', 10),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-vuruq',
     'Kvadrat tənliklərin vuruqlara ayırma üsulu ilə həlli', 20),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-tam-kvadrat',
     'Tam kvadrat ayırmaqla kvadrat tənliklərin həlli', 30),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-qrafik',
     'Kvadrat tənliyin qrafik üsulla həlli', 40),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-dustur',
     'Kvadrat tənliklərin həlli. Kvadrat tənliyin kökləri düsturu', 50),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-viyet',
     'Viyet teoremi', 60),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-getirilen',
     'Kvadrat tənliyə gətirilən tənliklər', 70),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-mesele',
     'Kvadrat tənliklərin tətbiqi ilə məsələ həlli', 80),
    ('riy-8-kvadrat-tenlik', 'riy-8-kvadrat-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  4. Dördbucaqlılar
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-anlayis',
     'Dördbucaqlılar', 10),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-bucaq',
     'Dördbucaqlının daxili və xarici bucaqları', 20),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-paraleloqram',
     'Paraleloqram', 30),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-paraleloqram-nov',
     'Paraleloqramın növləri', 40),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-paraleloqram-tetbiq',
     'Paraleloqramın xassələrinin tətbiqi', 50),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-orta-xett',
     'Üçbucağın orta xətti', 60),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-trapesiya',
     'Trapesiya', 70),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-trapesiya-orta-xett',
     'Trapesiyanın orta xətti', 80),
    ('riy-8-dordbucaqlilar', 'riy-8-dordbucaqlilar-umumi',
     'Ümumiləşdirici tapşırıqlar', 90),
    --  5. Rasional ifadələr
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-anlayis',
     'Rasional ifadələr', 10),
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-sadelesdirme',
     'Rasional ifadələrin sadələşdirilməsi', 20),
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-vurma-bolme',
     'Rasional ifadələrin vurulması, bölünməsi və qüvvətə yüksəldilməsi', 30),
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-toplama-cixma',
     'Rasional ifadələrin toplanması və çıxılması', 40),
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-emeller',
     'Rasional ifadələr üzərində əməllər', 50),
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-funksiya',
     'y = k / x funksiyası və onun qrafiki', 60),
    ('riy-8-rasional-ifade', 'riy-8-rasional-ifade-umumi',
     'Ümumiləşdirici tapşırıqlar', 70),
    --  6. Fiqurların sahəsi
    ('riy-8-sahe', 'riy-8-sahe-aksiom',
     'Sahə aksiomları', 10),
    ('riy-8-sahe', 'riy-8-sahe-paraleloqram',
     'Paraleloqramın sahəsi', 20),
    ('riy-8-sahe', 'riy-8-sahe-ucbucaq',
     'Üçbucağın sahəsi', 30),
    ('riy-8-sahe', 'riy-8-sahe-trapesiya',
     'Trapesiyanın sahəsi', 40),
    ('riy-8-sahe', 'riy-8-sahe-romb',
     'Rombun sahəsi', 50),
    ('riy-8-sahe', 'riy-8-sahe-umumi',
     'Ümumiləşdirici tapşırıqlar', 60),
    --  7. Rasional tənliklər
    ('riy-8-rasional-tenlik', 'riy-8-rasional-tenlik-anlayis',
     'Rasional tənliklər', 10),
    ('riy-8-rasional-tenlik', 'riy-8-rasional-tenlik-mesele',
     'Rasional tənliklərin tətbiqi ilə məsələ həlli', 20),
    ('riy-8-rasional-tenlik', 'riy-8-rasional-tenlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 30),
    --  8. Fiqurların oxşarlığı
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-nisbet',
     'Nisbət, tənasüb, miqyas', 10),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-parca',
     'Mütənasib parçalar', 20),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-fiqurlar',
     'Oxşar dördbucaqlılar, oxşar üçbucaqlar', 30),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-elamet',
     'Üçbucaqların oxşarlıq əlamətləri', 40),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-duzbucaqli',
     'Düzbucaqlı üçbucaqların oxşarlığı', 50),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-tetbiq',
     'Üçbucaqların oxşarlığının tətbiqi', 60),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-sahe',
     'Oxşar fiqurların sahəsi', 70),
    ('riy-8-oxsarliq', 'riy-8-oxsarliq-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  9. Bərabərsizliklər
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-anlayis',
     'Bərabərsizliklər', 10),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-xasse',
     'Bərabərsizliklərin xassələri', 20),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-toplama-vurma',
     'Bərabərsizliklərin toplanması və vurulması', 30),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-araliq',
     'Ədədi aralıqlar', 40),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-xetti',
     'Birdəyişənli xətti bərabərsizliklərin həlli', 50),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-ikiqat',
     'İkiqat bərabərsizliklərin həlli', 60),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-modul',
     'Dəyişəni modul işarəsi daxilində olan sadə bərabərsizliklər', 70),
    ('riy-8-berabersizlik', 'riy-8-berabersizlik-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  10. Triqonometrik nisbətlər. Koordinatlar üsulu. Fiqurların çevrilməsi
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-nisbet',
     'Düzbucaqlı üçbucaq və triqonometrik nisbətlər', 10),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-mesele',
     'Triqonometrik nisbətlərin tətbiqi ilə məsələ həlli', 20),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-eynilik',
     'Triqonometrik eyniliklər', 30),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-orta-noqte',
     'Parçanın orta nöqtəsinin koordinatları', 40),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-duz-xett',
     'İki nöqtədən keçən düz xəttin tənliyi', 50),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-donme',
     'Fiqurların çevrilməsi. Dönmə', 60),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-homotetiya',
     'Oxşarlıq çevrilməsi. Homotetiya', 70),
    ('riy-8-triqonometrik', 'riy-8-triqonometrik-umumi',
     'Ümumiləşdirici tapşırıqlar', 80),
    --  11. Məlumatın toplanması və təqdimi. Ehtimalın hesablanması
    ('riy-8-ehtimal', 'riy-8-ehtimal-melumat',
     'Məlumatın toplanması və təqdim', 10),
    ('riy-8-ehtimal', 'riy-8-ehtimal-merkez',
     'Mərkəzə meyilli ölçülər', 20),
    ('riy-8-ehtimal', 'riy-8-ehtimal-umumi-1',
     'Ümumiləşdirici tapşırıqlar', 30),
    ('riy-8-ehtimal', 'riy-8-ehtimal-hesablama',
     'Ehtimalın hesablanması', 40),
    ('riy-8-ehtimal', 'riy-8-ehtimal-hadise',
     'Asılı olmayan və asılı hadisələr', 50),
    ('riy-8-ehtimal', 'riy-8-ehtimal-umumi-2',
     'Ümumiləşdirici tapşırıqlar', 60)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'riyaziyyat')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = p.level_id and l.code = '8';
  if k <> 74 then
    raise exception 'Riyaziyyat 8 alt movzulari: 74 gozlenilirdi, % tapildi', k;
  end if;

  --  alt movzuda sual OLMAMALIDIR
  select count(*) into k from public.questions q
    join public.topics t on t.id = q.topic_id
   where t.parent_id is not null;
  if k > 0 then
    raise exception '% sual alt movzuya baglanib - bu merhelede olmamalidir', k;
  end if;

  --  hec bir alt movzu ust seviyyede qalmamalidir
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'riyaziyyat'
    join public.levels   l on l.id = t.level_id and l.code = '8'
   where t.parent_id is null;
  if k <> 11 then
    raise exception 'Riyaziyyat 8-de ust movzu sayi 11 deyil: %', k;
  end if;

  raise notice 'Riyaziyyat 8: 74 alt movzu hazir (11 movzu altinda).';
end $$;
