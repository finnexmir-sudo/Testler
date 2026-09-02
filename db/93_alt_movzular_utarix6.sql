-- =====================================================================
--  93_alt_movzular_utarix6.sql : UMUMI TARIX 6 - ALT MOVZULAR
--
--  NIYE
--  On ikinci fenn.  Kitab id 920 - şagird gostərdi (link
--  bu sessiyada mundericat.py-a elave edildi).
--
--  YALNIZ 6-CI SINIF: 8, 9 ve 11-ci sinifin kitablari (791/879/809,
--  eyni yolla tapilib) HEC BIR halda bazadaki movzu adlarina UYGUN
--  GəLMIR - dersliyin real bolmeleri REGIONAL-OLKE icindir (Qizilbas/
--  Mogol/Cin/Osmanli/Qafqaz, Amerika/Britaniya/Fransa/Rusiya), baza
--  ise TEMATIK dovr adlari gozleyir (Boyuk cografi kesfler/Intibah/
--  Inqilablar/Maarifcilik, Senaye cevrilisi/Napoleon/Birlesme/ABS).
--  Bu, tesadufi adlandirma ferqi deyil - iki AYRI dersliyin mundericati
--  kimi gorunur.  CLAUDE.md-de qeyd edildi, davam etmezden evvel
--  istifadeci ile aydinlasdirilmalidir.
--
--  MENBE: e-derslik.edu.az kitab id 920.  Adlar EYNILE goturulub.
--
--  DERSLIYIN QURULUSU: 3 bolme - "Tarix" (2 ders) -> utarix-6-ibtidai,
--  "Qedim Serq sivilizasiyalari" (8 ders, sehife 50-den ikiye bolunur:
--  Ehramlar/Sumer/Ikicayarasi -> mesopotamiya, Oda sitayis/Parfiya/
--  Tanrinin doyusculeri/Ipek yolu/Sahmat -> serq) ve "Qedim Qerb
--  sivilizasiyalari" (2 ders, sehife 116-dan bolunur: Avropa
--  medeniyyetinin besiyi -> yunanistan, ilk Respublika yaradanlar ->
--  roma).  utarix-6-medeniyyet ucun mundericatda isare yoxdur -
--  biologiya-11-viruslar ile eyni qerar, 0 alt movzu qalir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.
--
--  ELLE YAZILMIR: tools/alt_movzular.py cixarir.  Duzelis skriptde
--  edilir, sonra SQL yeniden yaradilir.
--
--  XARIC EDILEN BENDLER: kitabin sonundaki aparat - "Sozluk",
--  "Cavablar", "Ozunuzu yoxlayin", "Mesele hellline numune",
--  "yarimil / sinif uzre umumilesdirici tapsiriqlar".  Bolmenin
--  dersi deyil.  db/74 de eyni qaydani tutub.
--
--  DIQQET
--   * questions cedveline TOXUNULMUR - suallar alt movzulara
--     baglanmir, teqler deyismir.  O, ayri merhelendir.
--   * Movcud ust movzu setirleri deyismir - yalniz parent kimi
--     islenir.  programs/levels-e de toxunulmur.
--   * Tekrar isledile biler (on conflict do update).
--   * db/102 movzu silmeyi bloklayir - bu fayl hec ne silmir.
-- =====================================================================
set search_path = public, extensions;

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  6-ci sinif  ============
    --  Tarix  (utarix-6-ibtidai)
    ('utarix-6-ibtidai', 'utarix-6-ibtidai-tarixde-hesabi',
     'Tarixdə il hesabı', 10),
    ('utarix-6-ibtidai', 'utarix-6-ibtidai-cemiyyet',
     'İbtidai cəmiyyət', 20),
    --  Qedim Serq sivilizasiyalari  (utarix-6-mesopotamiya)
    ('utarix-6-mesopotamiya', 'utarix-6-mesopotamiya-ehramlar-olkesi',
     'Ehramlar ölkəsi', 10),
    ('utarix-6-mesopotamiya', 'utarix-6-mesopotamiya-sumerden-baslanan',
     'Şumerdən başlanan tarix', 20),
    ('utarix-6-mesopotamiya', 'utarix-6-mesopotamiya-ikicayarasinin-diger',
     'ikiçayarasının digər dövlətləri', 30),
    --  Qedim Serq sivilizasiyalari  (utarix-6-serq)
    ('utarix-6-serq', 'utarix-6-serq-oda-sitayis',
     'Oda sitayiş edənlər', 10),
    ('utarix-6-serq', 'utarix-6-serq-parfiya-dovleti',
     'Parfiya dövləti.', 20),
    ('utarix-6-serq', 'utarix-6-serq-tanrinin-doyusculeri',
     'Tanrının döyüşçüləri', 30),
    ('utarix-6-serq', 'utarix-6-serq-boyuk-ipek',
     'Böyük ipək yolunun başlandığı ölkə', 40),
    ('utarix-6-serq', 'utarix-6-serq-sahmatin-veteni',
     'Şahmatın vətəni', 50),
    --  Qedim Qerb sivilizasiyalari  (utarix-6-yunanistan)
    ('utarix-6-yunanistan', 'utarix-6-yunanistan-avropa-medeniyyetinin',
     'Avropa mədəniyyətinin beşiyi', 10),
    --  Qedim Qerb sivilizasiyalari  (utarix-6-roma)
    ('utarix-6-roma', 'utarix-6-roma-ilk-respublika',
     'ilk Respublika yaradanlar', 10)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'umumi-tarix')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 12 then
    raise exception 'umumi-tarix 6-ci alt movzulari: 12 gozlenilirdi, % tapildi', k;
  end if;

  --  alt movzuda sual OLMAMALIDIR
  select count(*) into k from public.questions q
    join public.topics t on t.id = q.topic_id
   where t.parent_id is not null;
  if k > 0 then
    raise exception '% sual alt movzuya baglanib - bu merhelede olmamalidir', k;
  end if;

  --  ust movzu sayi deyismemelidir
  select count(*) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'umumi-tarix'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and l.code in ('6','8','9','11');
  if k <> 24 then
    raise exception 'Umumi tarix ust movzu sayi (6,8,9,11) 24 deyil: %', k;
  end if;

  raise notice 'Umumi tarix 6 (8/9/11 uygunsuzluq - bax CLAUDE.md): 12 alt movzu hazir.';
end $$;
