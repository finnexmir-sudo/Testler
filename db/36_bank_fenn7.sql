-- =====================================================================
--  36_bank_fenn7.sql : 7-CI SINIF - FIZIKA, KIMYA, BIOLOGIYA, COGRAFIYA
--
--  BU FAYL ELLE YAZILMIR - tools/fenn7.py yaradir:
--      python3 tools/fenn7.py
--
--  Fizika 7 + Kimya 7 + Biologiya 7 + Cografiya 7 = 28 movzu x 10
--  = 280.  ext_key: fiz7-/kim7-/bio7-/cog7-...
--  ON SERT: 33_movzular_orta7.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('fizika','fiz-7-dovre'),
                                ('kimya','kim-7-tursu-esas'),
                                ('biologiya','bio-7-ekosistem'),
                                ('cografiya','cog-7-iqlim'))
     having count(*) = 4) then
    raise exception 'ONCE 33_movzular_orta7.sql isledilmelidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'fiz7-%' or q.ext_key like 'kim7-%'
        or q.ext_key like 'bio7-%' or q.ext_key like 'cog7-%');

with d(ext, fenn, topic, diff, rub, body, why, opts, correct) as (values
('fiz7-olcme#1','fizika','fiz-7-olcme',2,1,'Beynəlxalq vahidlər sistemi necə işarələnir?','Beynəlxalq sistem BS (SI) adlanır.',array['BS (SI)','AB','QQ','MM'],1),
('fiz7-olcme#2','fizika','fiz-7-olcme',1,1,'1 kilometr neçə metrdir?','1 km = 1000 m.',array['1000','100','10','10 000'],1),
('fiz7-olcme#3','fizika','fiz-7-olcme',3,1,'Cihazın bölgü qiyməti necə tapılır?','İki qonşu rəqəmli bölgünün fərqi aralarındakı bölgü sayına bölünür.',array['Qonşu bölgülərin fərqini bölgü sayına bölməklə','Cihazın çəkisi ilə','Rənginə görə','Təsadüfi seçilir'],1),
('fiz7-olcme#4','fizika','fiz-7-olcme',3,1,'Ştangenpərgar nə üçün istifadə olunur?','Kiçik uzunluqları dəqiq ölçmək üçün.',array['Kiçik uzunluqları dəqiq ölçmək üçün','Kütləni ölçmək üçün','Temperaturu ölçmək üçün','Vaxtı ölçmək üçün'],1),
('fiz7-olcme#5','fizika','fiz-7-olcme',2,1,'1 saat neçə saniyədir?','60 · 60 = 3600 saniyə.',array['3600','60','600','100'],1),
('fiz7-olcme#6','fizika','fiz-7-olcme',2,1,'Sahənin BS vahidi hansıdır?','Sahə kvadrat metrlə ölçülür.',array['m²','m³','sm','litr'],1),
('fiz7-olcme#7','fizika','fiz-7-olcme',2,1,'Həcm BS-də hansı vahidlə ölçülür?','Həcmin BS vahidi kub metrdir.',array['m³','m²','kq','saniyə'],1),
('fiz7-olcme#8','fizika','fiz-7-olcme',2,1,'10 millimetr neçə santimetrdir?','10 mm = 1 sm.',array['1','10','100','0,1'],1),
('fiz7-olcme#9','fizika','fiz-7-olcme',2,1,'Ölçmə xətası nədən yaranır?','Cihazın dəqiqliyindən və ölçmə şəraitindən.',array['Cihazın dəqiqliyindən','Havanın rəngindən','Günün adından','Xəta olmur'],1),
('fiz7-olcme#10','fizika','fiz-7-olcme',2,1,'250 santimetr neçə metrdir?','250 : 100 = 2,5 m.',array['2,5','25','0,25','250'],1),
('fiz7-duzxetli#1','fizika','fiz-7-duzxetli',2,1,'Sürət hansı düsturla hesablanır?','Sürət = yol : zaman (v = S/t).',array['v = S : t','v = S · t','v = t : S','v = S + t'],1),
('fiz7-duzxetli#2','fizika','fiz-7-duzxetli',2,1,'Avtomobil 3 saata 150 km yol getdi. Orta sürəti neçədir?','150 : 3 = 50 km/saat.',array['50 km/saat','45 km/saat','153 km/saat','500 km/saat'],1),
('fiz7-duzxetli#3','fizika','fiz-7-duzxetli',2,1,'Sürətin BS vahidi hansıdır?','BS-də sürət m/san ilə ölçülür.',array['m/san','km/saat','sm/dəq','m²'],1),
('fiz7-duzxetli#4','fizika','fiz-7-duzxetli',2,1,'Bərabərsürətli hərəkət hansı hərəkətdir?','Bərabər zaman fasilələrində bərabər yol gedilən hərəkət.',array['Bərabər zamanlarda bərabər yol gedilən','Sürəti artan','Sürəti azalan','Dayanmış'],1),
('fiz7-duzxetli#5','fizika','fiz-7-duzxetli',3,1,'36 km/saat neçə m/san-dır?','36 000 m : 3600 san = 10 m/san.',array['10','36','3,6','100'],1),
('fiz7-duzxetli#6','fizika','fiz-7-duzxetli',2,1,'Sürət 20 m/san, zaman 5 san olarsa, gedilən yol neçədir?','S = v · t = 20 · 5 = 100 m.',array['100 m','25 m','4 m','15 m'],1),
('fiz7-duzxetli#7','fizika','fiz-7-duzxetli',3,1,'Hərəkətin nisbiliyi nə deməkdir?','Hərəkət seçilmiş hesablama cisminə nəzərən baxılır.',array['Hərəkət hesablama cisminə nəzərəndir','Hərəkət yoxdur','Bütün cisimlər eyni sürətlədir','Sürət ölçülmür'],1),
('fiz7-duzxetli#8','fizika','fiz-7-duzxetli',2,1,'Qeyri-bərabər hərəkətdə hansı kəmiyyət dəyişir?','Sürət zamanla dəyişir.',array['Sürət','Cismin adı','Cismin rəngi','Heç nə'],1),
('fiz7-duzxetli#9','fizika','fiz-7-duzxetli',2,1,'Trayektoriya nədir?','Cismin hərəkət zamanı cızdığı xəttdir.',array['Cismin hərəkət xətti','Cismin kütləsi','Cismin forması','Zaman vahidi'],1),
('fiz7-duzxetli#10','fizika','fiz-7-duzxetli',3,1,'Piyada 1,5 m/san sürətlə 60 saniyəyə nə qədər yol gedər?','S = 1,5 · 60 = 90 m.',array['90 m','61,5 m','40 m','150 m'],1),
('fiz7-eyrixetli#1','fizika','fiz-7-eyrixetli',2,2,'Əyrixətli hərəkətə misal hansıdır?','Planetlərin Günəş ətrafında hərəkəti əyrixətlidir.',array['Planetin Günəş ətrafında hərəkəti','Liftin qalxması','Qatarın düz yolda hərəkəti','Şaquli düşən daş'],1),
('fiz7-eyrixetli#2','fizika','fiz-7-eyrixetli',3,2,'Çevrə üzrə hərəkətdə sürətin istiqaməti necə dəyişir?','İstiqamət daim dəyişir — çevrəyə toxunan boyunca yönəlir.',array['Daim dəyişir','Sabit qalır','Yalnız başlanğıcda dəyişir','Sürətin istiqaməti olmur'],1),
('fiz7-eyrixetli#3','fizika','fiz-7-eyrixetli',3,2,'Fırlanma periodu nədir?','Bir tam dövrə sərf olunan zamandır.',array['Bir tam dövrün zamanı','Dövrlərin sayı','Çevrənin uzunluğu','Sürətin modulu'],1),
('fiz7-eyrixetli#4','fizika','fiz-7-eyrixetli',3,2,'Tezlik nəyi göstərir?','Vahid zamandakı dövrlərin sayını.',array['Vahid zamanda dövrlərin sayını','Yolun uzunluğunu','Cismin kütləsini','Temperaturu'],1),
('fiz7-eyrixetli#5','fizika','fiz-7-eyrixetli',3,2,'Period 2 saniyədirsə, tezlik neçədir?','ν = 1/T = 1 : 2 = 0,5 Hs.',array['0,5 Hs','2 Hs','1 Hs','4 Hs'],1),
('fiz7-eyrixetli#6','fizika','fiz-7-eyrixetli',2,2,'Tezliyin vahidi hansıdır?','Tezlik herslə (Hs) ölçülür.',array['Hers (Hs)','Metr','Saniyə','Kiloqram'],1),
('fiz7-eyrixetli#7','fizika','fiz-7-eyrixetli',2,2,'Saat əqrəbinin ucu hansı trayektoriya ilə hərəkət edir?','Əqrəbin ucu çevrə cızır.',array['Çevrə üzrə','Düz xətt üzrə','Ziqzaqla','Hərəkət etmir'],1),
('fiz7-eyrixetli#8','fizika','fiz-7-eyrixetli',2,2,'Karusel 10 saniyəyə bir tam dövr edir. Periodu neçədir?','Period elə bir dövrün zamanıdır: 10 san.',array['10 san','1 san','0,1 san','100 san'],1),
('fiz7-eyrixetli#9','fizika','fiz-7-eyrixetli',3,2,'Çevrə üzrə bərabərsürətli hərəkətdə sürətin modulu necədir?','Modul sabitdir, istiqamət dəyişir.',array['Sabitdir','Daim artır','Daim azalır','Sıfırdır'],1),
('fiz7-eyrixetli#10','fizika','fiz-7-eyrixetli',3,2,'Period ilə tezlik arasında hansı əlaqə var?','T = 1/ν — tərs mütənasibdirlər.',array['Tərs mütənasibdirlər','Bərabərdirlər','Düz mütənasibdirlər','Əlaqə yoxdur'],1),
('fiz7-atom#1','fizika','fiz-7-atom',2,2,'Atomun nüvəsi hansı hissəciklərdən ibarətdir?','Nüvə proton və neytronlardan ibarətdir.',array['Proton və neytronlardan','Yalnız elektronlardan','Molekullardan','İşıqdan'],1),
('fiz7-atom#2','fizika','fiz-7-atom',2,2,'Elektron hansı yükə malikdir?','Elektronun yükü mənfidir.',array['Mənfi','Müsbət','Yüksüzdür','Gah müsbət, gah mənfi'],1),
('fiz7-atom#3','fizika','fiz-7-atom',2,2,'Protonun yükü necədir?','Proton müsbət yüklüdür.',array['Müsbət','Mənfi','Yüksüzdür','Dəyişkəndir'],1),
('fiz7-atom#4','fizika','fiz-7-atom',2,2,'Neytron hansı yükə malikdir?','Neytron yüksüzdür (neytraldır).',array['Yüksüzdür','Müsbət','Mənfi','İkiqat müsbət'],1),
('fiz7-atom#5','fizika','fiz-7-atom',3,2,'Atom bütövlükdə hansı yükə malikdir?','Müsbət və mənfi yüklər bərabərdir — atom neytraldır.',array['Neytraldır','Müsbətdir','Mənfidir','Yükü sonsuzdur'],1),
('fiz7-atom#6','fizika','fiz-7-atom',2,2,'Elektronlar atomda harada yerləşir?','Elektronlar nüvə ətrafında hərəkət edir.',array['Nüvə ətrafında','Nüvənin içində','Atomdan kənarda','Yalnız mərkəzdə'],1),
('fiz7-atom#7','fizika','fiz-7-atom',3,2,'Atomun ölçüsü təxminən hansı tərtibdədir?','Atomun diametri ~10⁻¹⁰ m tərtibindədir.',array['10⁻¹⁰ m','1 sm','1 mm','1 m'],1),
('fiz7-atom#8','fizika','fiz-7-atom',3,2,'Müsbət ion necə yaranır?','Atom elektron itirəndə müsbət iona çevrilir.',array['Atom elektron itirəndə','Atom elektron qəbul edəndə','Atom qızdırılanda','İon yaranmır'],1),
('fiz7-atom#9','fizika','fiz-7-atom',3,2,'Atom elektron qəbul edərsə, nəyə çevrilir?','Əlavə mənfi yük — mənfi ion yaranır.',array['Mənfi iona','Müsbət iona','Neytrona','Protona'],1),
('fiz7-atom#10','fizika','fiz-7-atom',3,2,'Nüvənin yükü nə ilə müəyyən olunur?','Nüvənin yükü protonların sayına bərabərdir.',array['Protonların sayı ilə','Neytronların sayı ilə','Elektron təbəqələri ilə','Atomun rəngi ilə'],1),
('fiz7-elektrik-sahe#1','fizika','fiz-7-elektrik-sahe',2,3,'Eyni adlı elektrik yükləri bir-birinə necə təsir edir?','Eyni adlı yüklər itələyir.',array['İtələyir','Cəzb edir','Təsir etmir','Əridir'],1),
('fiz7-elektrik-sahe#2','fizika','fiz-7-elektrik-sahe',2,3,'Müxtəlif adlı yüklər bir-birinə necə təsir edir?','Müxtəlif adlı yüklər cəzb edir.',array['Cəzb edir','İtələyir','Təsir etmir','Yandırır'],1),
('fiz7-elektrik-sahe#3','fizika','fiz-7-elektrik-sahe',3,3,'Elektrik yükünün vahidi hansıdır?','Yük kulonla (Kl) ölçülür.',array['Kulon','Amper','Volt','Om'],1),
('fiz7-elektrik-sahe#4','fizika','fiz-7-elektrik-sahe',3,3,'Cisimlər sürtünmə zamanı necə elektriklənir?','Elektronlar bir cisimdən digərinə keçir.',array['Elektronların keçməsi ilə','Protonların qaçması ilə','İstiliyin artması ilə','Elektriklənmir'],1),
('fiz7-elektrik-sahe#5','fizika','fiz-7-elektrik-sahe',3,3,'Elektrik sahəsi nədir?','Yüklü cisimlər ətrafında mövcud olan materiya formasıdır.',array['Yüklər ətrafındakı materiya forması','Boşluq','Hava axını','İşıq zolağı'],1),
('fiz7-elektrik-sahe#6','fizika','fiz-7-elektrik-sahe',3,3,'Elektroskop nə üçün istifadə olunur?','Cismin yüklü olub-olmadığını aşkar etmək üçün.',array['Yüklənməni aşkar etmək üçün','Kütləni ölçmək üçün','Sürəti ölçmək üçün','Vaxtı ölçmək üçün'],1),
('fiz7-elektrik-sahe#7','fizika','fiz-7-elektrik-sahe',3,3,'Metallarda cərəyanı hansı hissəciklər daşıyır?','Sərbəst elektronlar daşıyır.',array['Sərbəst elektronlar','Neytronlar','Atom nüvələri','Molekullar'],1),
('fiz7-elektrik-sahe#8','fizika','fiz-7-elektrik-sahe',2,3,'Dielektrik (izolyator) hansı maddədir?','Cərəyanı keçirməyən maddədir: rezin, şüşə, plastik.',array['Cərəyanı keçirməyən','Cərəyanı yaxşı keçirən','Yalnız maqnit','Yalnız maye'],1),
('fiz7-elektrik-sahe#9','fizika','fiz-7-elektrik-sahe',3,3,'Şüşə çubuq ipəyə sürtüləndə hansı yüklə yüklənir?','Şüşə elektron itirir — müsbət yüklənir.',array['Müsbət','Mənfi','Yüklənmir','Gah belə, gah elə'],1),
('fiz7-elektrik-sahe#10','fizika','fiz-7-elektrik-sahe',3,3,'Yükün saxlanması qanunu nə deyir?','Qapalı sistemdə yüklərin cəbri cəmi sabit qalır.',array['Yüklərin cəmi sabit qalır','Yüklər yox olur','Yüklər daim artır','Qanun yoxdur'],1),
('fiz7-dovre#1','fizika','fiz-7-dovre',2,3,'Elektrik dövrəsinin əsas elementləri hansılardır?','Cərəyan mənbəyi, naqillər, istehlakçı və açar.',array['Mənbə, naqillər, istehlakçı, açar','Yalnız lampa','Yalnız batareya','Taxta və şüşə'],1),
('fiz7-dovre#2','fizika','fiz-7-dovre',2,3,'Cərəyan şiddətinin vahidi hansıdır?','Cərəyan şiddəti amperlə ölçülür.',array['Amper','Volt','Om','Vatt'],1),
('fiz7-dovre#3','fizika','fiz-7-dovre',2,3,'Gərginliyin vahidi hansıdır?','Gərginlik voltla ölçülür.',array['Volt','Amper','Kulon','Hers'],1),
('fiz7-dovre#4','fizika','fiz-7-dovre',2,3,'Cərəyan şiddətini hansı cihaz ölçür?','Ampermetr cərəyan şiddətini ölçür.',array['Ampermetr','Voltmetr','Termometr','Barometr'],1),
('fiz7-dovre#5','fizika','fiz-7-dovre',2,3,'Gərginliyi ölçən cihaz hansıdır?','Voltmetr gərginliyi ölçür.',array['Voltmetr','Ampermetr','Tərəzi','Saat'],1),
('fiz7-dovre#6','fizika','fiz-7-dovre',3,3,'Ampermetr dövrəyə necə qoşulur?','Ampermetr ardıcıl qoşulur.',array['Ardıcıl','Paralel','Qoşulmur','İstənilən kimi'],1),
('fiz7-dovre#7','fizika','fiz-7-dovre',3,3,'Voltmetr dövrəyə necə qoşulur?','Voltmetr paralel qoşulur.',array['Paralel','Ardıcıl','Çarpaz','Qoşulmur'],1),
('fiz7-dovre#8','fizika','fiz-7-dovre',2,3,'Müqavimətin vahidi hansıdır?','Müqavimət omla ölçülür.',array['Om','Volt','Amper','Coul'],1),
('fiz7-dovre#9','fizika','fiz-7-dovre',3,3,'Om qanunu hansı düsturla ifadə olunur?','I = U : R.',array['I = U : R','I = U · R','I = R : U','I = U + R'],1),
('fiz7-dovre#10','fizika','fiz-7-dovre',3,3,'Gərginlik 12 V, müqavimət 4 Om olarsa, cərəyan şiddəti neçədir?','I = 12 : 4 = 3 A.',array['3 A','48 A','8 A','16 A'],1),
('fiz7-maqnit#1','fizika','fiz-7-maqnit',2,4,'Maqnitin qütbləri necə adlanır?','Şimal (N) və cənub (S) qütbləri.',array['Şimal və cənub','Şərq və qərb','Sağ və sol','Üst və alt'],1),
('fiz7-maqnit#2','fizika','fiz-7-maqnit',2,4,'Eyni adlı maqnit qütbləri bir-birinə necə təsir edir?','Eyni adlı qütblər itələyir.',array['İtələyir','Cəzb edir','Təsir etmir','Əridir'],1),
('fiz7-maqnit#3','fizika','fiz-7-maqnit',3,4,'Maqnit sahəsini nə yaradır?','Maqnitlər və cərəyanlı naqillər yaradır.',array['Maqnitlər və cərəyanlı naqillər','Yalnız taxta','Yalnız işıq','Səs dalğaları'],1),
('fiz7-maqnit#4','fizika','fiz-7-maqnit',2,4,'Kompasın işləməsi nəyə əsaslanır?','Yerin maqnit sahəsinə əsaslanır.',array['Yerin maqnit sahəsinə','Küləyə','İşığa','Temperatura'],1),
('fiz7-maqnit#5','fizika','fiz-7-maqnit',3,4,'Maqniti kəsib tək qütblü maqnit almaq olarmı?','Olmaz — hər hissə yenə iki qütblü olur.',array['Olmaz','Olar','Yalnız qışda olar','Yalnız suda olar'],1),
('fiz7-maqnit#6','fizika','fiz-7-maqnit',3,4,'Elektromaqnit nədir?','İçində dəmir özək olan cərəyanlı sarğacdır.',array['Cərəyanlı sarğac və dəmir özək','Adi daş','Şüşə boru','Taxta çubuq'],1),
('fiz7-maqnit#7','fizika','fiz-7-maqnit',2,4,'Maqnit sahəsi hansı cisimlərə təsir edir?','Dəmir-polad cisimlərə və cərəyanlı naqillərə.',array['Dəmir cisimlərə və cərəyanlı naqillərə','Bütün plastik cisimlərə','Kağıza','Şüşəyə'],1),
('fiz7-maqnit#8','fizika','fiz-7-maqnit',3,4,'Yerin maqnit qütbləri harada yerləşir?','Coğrafi qütblərə yaxın yerləşir.',array['Coğrafi qütblərə yaxın','Ekvatorda','Okeanın dibində','Dağların zirvəsində'],1),
('fiz7-maqnit#9','fizika','fiz-7-maqnit',3,4,'Maqnit sahəsinin mənzərəsini əyani görmək üçün nədən istifadə olunur?','Dəmir yonqarı sahə xətləri boyunca düzülür.',array['Dəmir yonqarından','Qum dənələrindən','Su damcısından','Kağız qırıntısından'],1),
('fiz7-maqnit#10','fizika','fiz-7-maqnit',3,4,'Elektromaqnitin gücünü necə artırmaq olar?','Cərəyanı və sarğıların sayını artırmaqla.',array['Cərəyanı və sarğı sayını artırmaqla','Rəngini dəyişməklə','Soyutmaqla','Mümkün deyil'],1),
('kim7-elementler#1','kimya','kim-7-elementler',1,1,'Kimya elmi nəyi öyrənir?','Maddələri, onların xassələrini və çevrilmələrini.',array['Maddələri və çevrilmələrini','Yalnız planetləri','Yalnız heyvanları','Yalnız tarixi'],1),
('kim7-elementler#2','kimya','kim-7-elementler',2,1,'Kimyəvi element nədir?','Eyni növ atomların məcmusudur.',array['Eyni növ atomlar','Müxtəlif maddələr qarışığı','Yalnız qazlar','Yalnız metallar'],1),
('kim7-elementler#3','kimya','kim-7-elementler',1,1,'Oksigenin kimyəvi işarəsi hansıdır?','Oksigen O işarəsi ilə göstərilir.',array['O','K','H','Os'],1),
('kim7-elementler#4','kimya','kim-7-elementler',1,1,'H işarəsi hansı elementi bildirir?','H — hidrogendir.',array['Hidrogeni','Heliumu','Dəmiri','Civəni'],1),
('kim7-elementler#5','kimya','kim-7-elementler',2,1,'Dəmirin kimyəvi işarəsi hansıdır?','Dəmir latınca ferrum: Fe.',array['Fe','De','D','Fr'],1),
('kim7-elementler#6','kimya','kim-7-elementler',2,1,'C işarəsi hansı elementin simvoludur?','C — karbondur.',array['Karbonun','Kalsiumun','Misin','Xlorun'],1),
('kim7-elementler#7','kimya','kim-7-elementler',2,1,'Kimyəvi elementlərin dövri cədvəli kimin adını daşıyır?','Cədvəli D.İ. Mendeleyev tərtib etmişdir.',array['Mendeleyevin','Nyutonun','Eynşteynin','Darvinin'],1),
('kim7-elementler#8','kimya','kim-7-elementler',2,1,'Au işarəsi hansı elementi bildirir?','Au (aurum) — qızıldır.',array['Qızılı','Gümüşü','Alüminiumu','Arqonu'],1),
('kim7-elementler#9','kimya','kim-7-elementler',3,1,'Kimyəvi işarələr əsasən nədən götürülüb?','Elementlərin latınca adlarından.',array['Latınca adlardan','Rəqəmlərdən','Şəkillərdən','Təsadüfi hərflərdən'],1),
('kim7-elementler#10','kimya','kim-7-elementler',2,1,'Azotun kimyəvi işarəsi hansıdır?','Azot (nitrogenium) — N.',array['N','A','Az','Na'],1),
('kim7-atom#1','kimya','kim-7-atom',3,1,'Elementin dövri cədvəldəki sıra nömrəsi nəyi göstərir?','Nüvədəki protonların sayını.',array['Protonların sayını','Neytronların sayını','Molekulların sayını','Elementin qiymətini'],1),
('kim7-atom#2','kimya','kim-7-atom',2,1,'Elektron təbəqələrində hansı hissəciklər yerləşir?','Təbəqələrdə elektronlar hərəkət edir.',array['Elektronlar','Protonlar','Neytronlar','Molekullar'],1),
('kim7-atom#3','kimya','kim-7-atom',3,1,'Neytral atomda elektronların sayı nəyə bərabərdir?','Protonların sayına bərabərdir.',array['Protonların sayına','Neytronların sayına','Təbəqələrin sayına','Həmişə 10-a'],1),
('kim7-atom#4','kimya','kim-7-atom',3,1,'Kütlə ədədi necə tapılır?','Proton və neytronların sayının cəmi kimi.',array['Proton və neytronların cəmi','Yalnız protonlar','Yalnız elektronlar','Təbəqələrin sayı'],1),
('kim7-atom#5','kimya','kim-7-atom',3,1,'Atomun kütləsi əsasən harada cəmlənib?','Kütlənin demək olar hamısı nüvədədir.',array['Nüvədə','Elektron təbəqələrində','Atomdan kənarda','Bərabər paylanıb'],1),
('kim7-atom#6','kimya','kim-7-atom',2,1,'Hidrogen atomunun nüvəsində neçə proton var?','Hidrogenin sıra nömrəsi 1-dir: 1 proton.',array['1','2','8','0'],1),
('kim7-atom#7','kimya','kim-7-atom',2,1,'Oksigenin sıra nömrəsi 8-dir. Nüvəsində neçə proton var?','Sıra nömrəsi qədər: 8 proton.',array['8','16','4','2'],1),
('kim7-atom#8','kimya','kim-7-atom',2,1,'İki və daha artıq atomun birləşməsindən nə yaranır?','Atomlar birləşib molekul əmələ gətirir.',array['Molekul','İşıq','Qarışıq','Məhlul'],1),
('kim7-atom#9','kimya','kim-7-atom',3,1,'Karbonun sıra nömrəsi 6-dır. Neytral karbon atomunda neçə elektron var?','Elektronlar protonlara bərabərdir: 6.',array['6','12','3','1'],1),
('kim7-atom#10','kimya','kim-7-atom',3,1,'Kimyəvi reaksiyalarda atomlar itirmi?','Xeyr — atomlar yalnız yenidən qruplaşır.',array['Xeyr, yenidən qruplaşır','Bəli, yox olur','Bəli, yarıya bölünür','Atomlar reaksiyada iştirak etmir'],1),
('kim7-birlesmeler#1','kimya','kim-7-birlesmeler',2,2,'Sadə maddə nədir?','Bir elementin atomlarından ibarət maddədir.',array['Bir elementin atomlarından ibarət maddə','Müxtəlif maddələr qarışığı','Yalnız maye','Yalnız qaz'],1),
('kim7-birlesmeler#2','kimya','kim-7-birlesmeler',2,2,'Mürəkkəb maddə nədir?','Müxtəlif elementlərin atomlarından ibarət maddədir.',array['Müxtəlif elementlərin atomlarından ibarət','Bir elementdən ibarət','Hər hansı qarışıq','Yalnız metal'],1),
('kim7-birlesmeler#3','kimya','kim-7-birlesmeler',1,2,'H₂O hansı maddənin formuludur?','H₂O — suyun formuludur.',array['Suyun','Duzun','Oksigenin','Dəmirin'],1),
('kim7-birlesmeler#4','kimya','kim-7-birlesmeler',2,2,'CO₂ formulu hansı qazı bildirir?','CO₂ — karbon qazıdır.',array['Karbon qazını','Oksigeni','Hidrogeni','Azotu'],1),
('kim7-birlesmeler#5','kimya','kim-7-birlesmeler',2,2,'Su molekulunda neçə hidrogen atomu var?','H₂O: 2 hidrogen atomu.',array['2','1','3','8'],1),
('kim7-birlesmeler#6','kimya','kim-7-birlesmeler',2,2,'O₂ sadə, yoxsa mürəkkəb maddədir?','Yalnız oksigen atomlarından ibarətdir — sadədir.',array['Sadə','Mürəkkəb','Qarışıq','Maddə deyil'],1),
('kim7-birlesmeler#7','kimya','kim-7-birlesmeler',2,2,'Kimyəvi formul nəyi göstərir?','Maddənin keyfiyyət və miqdar tərkibini.',array['Maddənin tərkibini','Maddənin qiymətini','Qabın ölçüsünü','Rəngini'],1),
('kim7-birlesmeler#8','kimya','kim-7-birlesmeler',2,2,'NaCl birləşməsi məişətdə necə tanınır?','NaCl — xörək duzudur.',array['Xörək duzu','Şəkər','Soda','Un'],1),
('kim7-birlesmeler#9','kimya','kim-7-birlesmeler',2,2,'Suyun tərkibinə hansı elementlər daxildir?','Su hidrogen və oksigendən ibarətdir.',array['Hidrogen və oksigen','Karbon və azot','Dəmir və mis','Yalnız oksigen'],1),
('kim7-birlesmeler#10','kimya','kim-7-birlesmeler',3,2,'CO₂ molekulunda cəmi neçə atom var?','1 karbon + 2 oksigen = 3 atom.',array['3','2','1','4'],1),
('kim7-qarisiqlar#1','kimya','kim-7-qarisiqlar',2,2,'Qarışıq nədir?','Bir neçə maddənin fiziki qatışığıdır.',array['Bir neçə maddənin qatışığı','Tək element','Tək molekul','Yalnız məhlul'],1),
('kim7-qarisiqlar#2','kimya','kim-7-qarisiqlar',3,2,'Bircinsli (həmcins) qarışığa misal hansıdır?','Duz suda tam həll olur — bircinsli qarışıqdır.',array['Duzun suda məhlulu','Su ilə qum','Su ilə yağ','Qum ilə dəmir qırıntısı'],1),
('kim7-qarisiqlar#3','kimya','kim-7-qarisiqlar',3,2,'Müxtəlifcinsli qarışığa misal hansıdır?','Qum suda həll olmur — hissələr seçilir.',array['Su ilə qum','Duzlu su','Şəkərli su','Hava'],1),
('kim7-qarisiqlar#4','kimya','kim-7-qarisiqlar',2,2,'Hava təmiz maddədir, yoxsa qarışıq?','Hava azot, oksigen və s. qazların qarışığıdır.',array['Qarışıqdır','Təmiz maddədir','Elementdir','Molekuldur'],1),
('kim7-qarisiqlar#5','kimya','kim-7-qarisiqlar',3,2,'Məhlul nədir?','Bircinsli qarışıqdır.',array['Bircinsli qarışıq','Müxtəlifcinsli qarışıq','Təmiz maddə','Sadə maddə'],1),
('kim7-qarisiqlar#6','kimya','kim-7-qarisiqlar',2,2,'Duzlu suda duz hansı roldadır?','Duz həll olunan maddədir, su həlledicidir.',array['Həll olunan maddə','Həlledici','Çöküntü','Qaz'],1),
('kim7-qarisiqlar#7','kimya','kim-7-qarisiqlar',1,2,'Ən geniş yayılmış həlledici hansıdır?','Su universal həlledicidir.',array['Su','Yağ','Qum','Dəmir'],1),
('kim7-qarisiqlar#8','kimya','kim-7-qarisiqlar',3,2,'Qarışıqda maddələr öz xassələrini saxlayırmı?','Bəli — qarışmada yeni maddə yaranmır.',array['Bəli, saxlayır','Xeyr, itirir','Yalnız qışda','Yalnız qazlarda'],1),
('kim7-qarisiqlar#9','kimya','kim-7-qarisiqlar',2,2,'Dəniz suyu nəyə misaldır?','Duzların suda məhluluna misaldır.',array['Məhlula','Təmiz maddəyə','Sadə maddəyə','Elementə'],1),
('kim7-qarisiqlar#10','kimya','kim-7-qarisiqlar',2,2,'Qazlı içkidə hansı qaz həll edilib?','Karbon qazı təzyiq altında həll edilir.',array['Karbon qazı','Hidrogen','Helium','Xlor'],1),
('kim7-ayrilma#1','kimya','kim-7-ayrilma',3,3,'Süzmə üsulu ilə hansı qarışıq ayrılır?','Maye ilə həll olmayan bərk maddə qarışığı.',array['Maye ilə həll olmayan bərk maddə','İki qaz','İki həll olan maddə','İki maye olmaz'],1),
('kim7-ayrilma#2','kimya','kim-7-ayrilma',2,3,'Duzlu sudan duzu hansı üsulla ayırmaq olar?','Su buxarlandırılır, duz qalır.',array['Buxarlandırma ilə','Süzmə ilə','Maqnitlə','Çökdürmə ilə'],1),
('kim7-ayrilma#3','kimya','kim-7-ayrilma',2,3,'Maqnitlə hansı qarışığı ayırmaq olar?','Tərkibində dəmir olan qarışığı.',array['Dəmir qırıntılı qarışığı','Duzlu suyu','Şəkərli suyu','İki mayeni'],1),
('kim7-ayrilma#4','kimya','kim-7-ayrilma',3,3,'Çökdürmə üsulu nəyə əsaslanır?','Ağır hissəciklərin dibə çökməsinə.',array['Hissəciklərin dibə çökməsinə','Buxarlanmaya','Yanmaya','Doymaya'],1),
('kim7-ayrilma#5','kimya','kim-7-ayrilma',3,3,'Distillə nədir?','Mayenin buxarlandırılıb yenidən kondensasiya edilməsidir.',array['Buxarlandırıb yenidən kondensasiya','Sadə süzmə','Maqnitlə ayırma','Qarışdırma'],1),
('kim7-ayrilma#6','kimya','kim-7-ayrilma',3,3,'Su ilə yağ qarışığı hansı üsulla ayrılır?','Laylara ayrıldığı üçün ayırıcı qıfla.',array['Ayırıcı qıfla','Maqnitlə','Yandırmaqla','Ayrılmır'],1),
('kim7-ayrilma#7','kimya','kim-7-ayrilma',2,3,'Süzmə zamanı süzgəcdən nə keçir?','Maye (məhlul) keçir, bərk hissəciklər qalır.',array['Maye','Bərk hissəciklər','Heç nə','Hər şey'],1),
('kim7-ayrilma#8','kimya','kim-7-ayrilma',3,3,'Ayırma üsulu seçilərkən nə nəzərə alınır?','Qarışıqdakı maddələrin xassələri.',array['Maddələrin xassələri','Qabın rəngi','Günün vaxtı','Havanın istiliyi'],1),
('kim7-ayrilma#9','kimya','kim-7-ayrilma',1,3,'Çay dəmlənəndə süzgəc nəyi saxlayır?','Çay yarpaqlarını saxlayır.',array['Çay yarpaqlarını','Suyu','Şəkəri','İstini'],1),
('kim7-ayrilma#10','kimya','kim-7-ayrilma',2,3,'Təmiz maddə qarışıqdan nə ilə fərqlənir?','Təmiz maddə yalnız bir maddədən ibarətdir.',array['Bir maddədən ibarət olması ilə','Rəngi ilə','Qabı ilə','Fərqlənmir'],1),
('kim7-reaksiyalar#1','kimya','kim-7-reaksiyalar',2,3,'Kimyəvi reaksiya nədir?','Bir maddənin başqa maddəyə çevrilməsidir.',array['Maddənin başqa maddəyə çevrilməsi','Maddənin yerdəyişməsi','Maddənin soyuması','Qabın dəyişməsi'],1),
('kim7-reaksiyalar#2','kimya','kim-7-reaksiyalar',2,3,'Kimyəvi reaksiyanın əlamətlərindən biri hansıdır?','Rəng dəyişməsi, qaz və ya çöküntü alınması.',array['Rəngin dəyişməsi','Qabın böyüməsi','Səsin ucalması','Heç bir əlamət olmur'],1),
('kim7-reaksiyalar#3','kimya','kim-7-reaksiyalar',3,3,'Kimyəvi hadisəni fiziki hadisədən nə fərqləndirir?','Kimyəvi hadisədə yeni maddə yaranır.',array['Yeni maddənin yaranması','İstiliyin olması','Sürətin dəyişməsi','Heç nə'],1),
('kim7-reaksiyalar#4','kimya','kim-7-reaksiyalar',2,3,'Dəmirin paslanması hansı hadisədir?','Yeni maddə (pas) yaranır — kimyəvi hadisədir.',array['Kimyəvi','Fiziki','Bioloji','Hadisə deyil'],1),
('kim7-reaksiyalar#5','kimya','kim-7-reaksiyalar',2,3,'Suyun buxarlanması hansı hadisədir?','Maddə dəyişmir, yalnız halı dəyişir — fizikidir.',array['Fiziki','Kimyəvi','Bioloji','Coğrafi'],1),
('kim7-reaksiyalar#6','kimya','kim-7-reaksiyalar',2,3,'Yanma reaksiyası üçün hansı qaz lazımdır?','Yanma oksigenlə gedir.',array['Oksigen','Azot','Helium','Arqon'],1),
('kim7-reaksiyalar#7','kimya','kim-7-reaksiyalar',3,3,'Reaksiyaya daxil olan maddələr necə adlanır?','Başlanğıc maddələr (reagentlər).',array['Reagentlər (başlanğıc maddələr)','Məhsullar','Qarışıqlar','İonlar'],1),
('kim7-reaksiyalar#8','kimya','kim-7-reaksiyalar',3,3,'Reaksiya nəticəsində alınan maddələr necə adlanır?','Reaksiya məhsulları adlanır.',array['Məhsullar','Reagentlər','Həlledicilər','Duzlar'],1),
('kim7-reaksiyalar#9','kimya','kim-7-reaksiyalar',2,3,'Şam yanarkən hansı qaz ayrılır?','Yanmada karbon qazı ayrılır.',array['Karbon qazı','Təmiz oksigen','Hidrogen','Xlor'],1),
('kim7-reaksiyalar#10','kimya','kim-7-reaksiyalar',3,3,'Su qaynayanda qabarcıqların çıxması kimyəvi reaksiyadırmı?','Xeyr — bu, buxarlanmadır, fiziki hadisədir.',array['Xeyr, fiziki hadisədir','Bəli, kimyəvidir','Bəli, yeni maddə yaranır','Bilmək olmaz'],1),
('kim7-tursu-esas#1','kimya','kim-7-tursu-esas',1,4,'Turşuların dadı adətən necə olur?','Turşular turş dadır (dadmaq təhlükəlidir!).',array['Turş','Şirin','Acı','Duzlu'],1),
('kim7-tursu-esas#2','kimya','kim-7-tursu-esas',2,4,'Limonda hansı turşu var?','Limonda limon turşusu var.',array['Limon turşusu','Sirkə turşusu','Xlorid turşusu','Kükürd turşusu'],1),
('kim7-tursu-esas#3','kimya','kim-7-tursu-esas',2,4,'Sirkədə hansı turşu var?','Sirkə — sirkə turşusunun məhluludur.',array['Sirkə turşusu','Limon turşusu','Süd turşusu','Azot turşusu'],1),
('kim7-tursu-esas#4','kimya','kim-7-tursu-esas',3,4,'İndikator nədir?','Mühitin turş və ya qələvi olduğunu rənglə göstərən maddə.',array['Mühiti rənglə göstərən maddə','Ölçü cihazı','Yanacaq növü','Duz növü'],1),
('kim7-tursu-esas#5','kimya','kim-7-tursu-esas',3,4,'Lakmus turş mühitdə hansı rəngi alır?','Turş mühitdə lakmus qırmızı olur.',array['Qırmızı','Göy','Yaşıl','Ağ'],1),
('kim7-tursu-esas#6','kimya','kim-7-tursu-esas',3,4,'Qələvi məhlullar toxunuşda necə olur?','Sabun kimi sürüşkəndir.',array['Sabunvarı (sürüşkən)','Quru','Yapışqan','İti'],1),
('kim7-tursu-esas#7','kimya','kim-7-tursu-esas',3,4,'Turşu ilə əsas reaksiyaya girəndə nə alınır?','Neytrallaşma gedir: duz və su alınır.',array['Duz və su','Yalnız qaz','Yalnız metal','Heç nə'],1),
('kim7-tursu-esas#8','kimya','kim-7-tursu-esas',3,4,'Mədə şirəsinin tərkibində hansı turşu var?','Mədə şirəsində xlorid turşusu var.',array['Xlorid turşusu','Limon turşusu','Sirkə turşusu','Kükürd turşusu'],1),
('kim7-tursu-esas#9','kimya','kim-7-tursu-esas',3,4,'Sabun məhlulu hansı mühitə malikdir?','Sabun qələvi mühitlidir.',array['Qələvi','Turş','Neytral','Mühiti yoxdur'],1),
('kim7-tursu-esas#10','kimya','kim-7-tursu-esas',2,4,'Turşularla işləyərkən nəyə əməl edilməlidir?','Təhlükəsizlik qaydalarına — qoruyucu vasitələrdən istifadə.',array['Təhlükəsizlik qaydalarına','Heç nəyə','Yalnız dad qaydalarına','Sürət qaydalarına'],1),
('bio7-huceyre-orqanizm#1','biologiya','bio-7-huceyre-orqanizm',3,1,'Bitki hüceyrəsini heyvan hüceyrəsindən nə fərqləndirir?','Hüceyrə divarı və xloroplastların olması.',array['Hüceyrə divarı və xloroplastlar','Nüvənin olması','Sitoplazmanın olması','Heç nə'],1),
('bio7-huceyre-orqanizm#2','biologiya','bio-7-huceyre-orqanizm',2,1,'Xloroplastlarda hansı proses gedir?','Xloroplastlarda fotosintez gedir.',array['Fotosintez','Tənəffüs yalnız','Həzm','İfrazat'],1),
('bio7-huceyre-orqanizm#3','biologiya','bio-7-huceyre-orqanizm',3,1,'Sitoplazma nədir?','Orqanoidlərin yerləşdiyi daxili mühitdir.',array['Hüceyrənin daxili mühiti','Hüceyrənin qabığı','Hüceyrənin nüvəsi','Hüceyrədən kənar maye'],1),
('bio7-huceyre-orqanizm#4','biologiya','bio-7-huceyre-orqanizm',3,1,'Hüceyrə membranı hansı funksiyanı yerinə yetirir?','Maddələrin hüceyrəyə keçidini tənzimləyir.',array['Maddələrin keçidini tənzimləyir','Fotosintez edir','İrsi məlumat saxlayır','Heç bir funksiyası yoxdur'],1),
('bio7-huceyre-orqanizm#5','biologiya','bio-7-huceyre-orqanizm',3,1,'Bitki hüceyrəsində vakuol nə saxlayır?','Hüceyrə şirəsini saxlayır.',array['Hüceyrə şirəsini','Havanı','Qumu','İşığı'],1),
('bio7-huceyre-orqanizm#6','biologiya','bio-7-huceyre-orqanizm',2,1,'Birhüceyrəli orqanizmə misal hansıdır?','Amöb bir hüceyrədən ibarətdir.',array['Amöb','İnsan','Alma ağacı','Qartal'],1),
('bio7-huceyre-orqanizm#7','biologiya','bio-7-huceyre-orqanizm',3,1,'Ardıcıllığı tamamlayın: hüceyrə → ? → orqan → orqanizm.','Hüceyrələr toxumaları əmələ gətirir.',array['Toxuma','Aləm','Molekul','Sistem yox, fərd'],1),
('bio7-huceyre-orqanizm#8','biologiya','bio-7-huceyre-orqanizm',3,1,'Mitoxondrilər hüceyrədə hansı rolu oynayır?','Enerji istehsal edir.',array['Enerji istehsalı','Rəng vermə','Səs çıxarma','Hərəkət etmə'],1),
('bio7-huceyre-orqanizm#9','biologiya','bio-7-huceyre-orqanizm',2,1,'Nüvədə nə saxlanılır?','İrsi məlumat nüvədə saxlanılır.',array['İrsi məlumat','Su ehtiyatı','Hava','Qida qalıqları'],1),
('bio7-huceyre-orqanizm#10','biologiya','bio-7-huceyre-orqanizm',2,1,'Mikroskopla baxılan obyekt haraya qoyulur?','Əşya şüşəsinin üzərinə qoyulur.',array['Əşya şüşəsinə','Okulyarın içinə','Güzgünün altına','Cibə'],1),
('bio7-bitki#1','biologiya','bio-7-bitki',2,1,'Fotosintez zamanı bitki hansı qazı udur?','Bitki karbon qazını udub oksigen verir.',array['Karbon qazını','Oksigeni','Azotu','Heliumu'],1),
('bio7-bitki#2','biologiya','bio-7-bitki',2,1,'Kök vasitəsilə bitkiyə nə daxil olur?','Su və mineral duzlar daxil olur.',array['Su və mineral duzlar','Hazır qida','İşıq','Oksigen yalnız'],1),
('bio7-bitki#3','biologiya','bio-7-bitki',3,1,'Yarpaqda suyun buxarlanması necə adlanır?','Bu proses transpirasiya adlanır.',array['Transpirasiya','Fotosintez','Kondensasiya','Distillə'],1),
('bio7-bitki#4','biologiya','bio-7-bitki',2,1,'Ağac gövdəsindəki illik halqalar nəyi göstərir?','Halqaları saymaqla ağacın yaşını bilmək olar.',array['Ağacın yaşını','Ağacın boyunu','Meyvənin dadını','Kökün dərinliyini'],1),
('bio7-bitki#5','biologiya','bio-7-bitki',3,1,'Yarpaqdakı ağızcıqlar nə üçündür?','Qaz mübadiləsi və buxarlanma üçün.',array['Qaz mübadiləsi üçün','Bəzək üçün','Yalnız rəng üçün','Heç nə üçün'],1),
('bio7-bitki#6','biologiya','bio-7-bitki',3,1,'Bitkidə üzvi maddələr harada sintez olunur?','Yaşıl yarpaqlarda (fotosintezlə).',array['Yaşıl yarpaqlarda','Köklərdə','Torpaqda','Meyvədə yalnız'],1),
('bio7-bitki#7','biologiya','bio-7-bitki',3,1,'Kök təzyiqi nəyə xidmət edir?','Suyun gövdə boyu yuxarı qalxmasına.',array['Suyun yuxarı qalxmasına','Kökün qısalmasına','Yarpağın tökülməsinə','Çiçəyin açmasına'],1),
('bio7-bitki#8','biologiya','bio-7-bitki',3,1,'Bitkilər gecə hansı prosesi davam etdirir?','Tənəffüs sutka boyu gedir.',array['Tənəffüsü','Fotosintezi','Çiçəkləməni','Heç bir prosesi'],1),
('bio7-bitki#9','biologiya','bio-7-bitki',2,1,'Fotosintez üçün enerji mənbəyi nədir?','Günəş işığı enerji mənbəyidir.',array['Günəş işığı','Torpaq istisi','Külək','Ay işığı'],1),
('bio7-bitki#10','biologiya','bio-7-bitki',3,1,'Nişasta bitkidə hansı rolu oynayır?','Ehtiyat qida maddəsidir.',array['Ehtiyat qida maddəsi','Rəng maddəsi','Zəhər','Su daşıyıcısı'],1),
('bio7-coxalma#1','biologiya','bio-7-coxalma',2,2,'Bitkilərdə cinsi çoxalma hansı orqanla bağlıdır?','Cinsi çoxalma çiçəklə bağlıdır.',array['Çiçəklə','Köklə','Yalnız yarpaqla','Yalnız gövdə ilə'],1),
('bio7-coxalma#2','biologiya','bio-7-coxalma',3,2,'Çarpaz tozlanma necə baş verir?','Bir çiçəyin tozcuğu başqa çiçəyin dişiciyinə düşür.',array['Tozcuq başqa çiçəyə düşür','Tozcuq öz dişiciyinə düşür','Tozlanma olmur','Yarpaqlar toxunur'],1),
('bio7-coxalma#3','biologiya','bio-7-coxalma',3,2,'Öz-özünə tozlanma nədir?','Tozcuğun həmin çiçəyin dişiciyinə düşməsidir.',array['Tozcuğun öz dişiciyinə düşməsi','Tozcuğun küləklə uçması','Arının gəlməsi','Toxumun düşməsi'],1),
('bio7-coxalma#4','biologiya','bio-7-coxalma',3,2,'Küləklə tozlanan bitkilərin çiçəkləri necə olur?','Kiçik, ətirsiz, nəzərəçarpmayan olur.',array['Kiçik və ətirsiz','İri və parlaq','Çox ətirli','Həmişə qırmızı'],1),
('bio7-coxalma#5','biologiya','bio-7-coxalma',2,2,'Həşəratla tozlanan çiçəklər həşəratı nə ilə cəlb edir?','Parlaq rəng, ətir və nektarla.',array['Parlaq rəng və ətirlə','Səslə','İstiliklə','Kölgə ilə'],1),
('bio7-coxalma#6','biologiya','bio-7-coxalma',3,2,'Qələmlə (çiliklə) çoxaltma hansı çoxalma növüdür?','Vegetativ çoxalmadır.',array['Vegetativ','Cinsi','Sporla','Toxumla'],1),
('bio7-coxalma#7','biologiya','bio-7-coxalma',3,2,'Mayalanmış yumurtahüceyrədən nə inkişaf edir?','Toxumun rüşeymi inkişaf edir.',array['Rüşeym','Yarpaq','Kök','Ləçək'],1),
('bio7-coxalma#8','biologiya','bio-7-coxalma',3,2,'Sporla çoxalan bitkiyə misal hansıdır?','Ayıdöşəyi (qıjı) sporla çoxalır.',array['Ayıdöşəyi (qıjı)','Alma ağacı','Buğda','Qızılgül'],1),
('bio7-coxalma#9','biologiya','bio-7-coxalma',3,2,'Toxumla çoxalma hansı çoxalma növünə aiddir?','Toxum cinsi çoxalmanın məhsuludur.',array['Cinsi (generativ)','Vegetativ','Bölünmə','Tumurcuqlanma'],1),
('bio7-coxalma#10','biologiya','bio-7-coxalma',3,2,'Calaq etmə nə üçün tətbiq olunur?','Sortun qiymətli xüsusiyyətlərini saxlamaq üçün.',array['Sortun xüsusiyyətlərini saxlamaq üçün','Ağacı qurutmaq üçün','Kökü kəsmək üçün','Yarpağı boyamaq üçün'],1),
('bio7-heyvanlar#1','biologiya','bio-7-heyvanlar',1,2,'Balıqların bədəni nə ilə örtülüdür?','Balıqların bədəni pulcuqlarla örtülüdür.',array['Pulcuqlarla','Lələklə','Tüklə','Zirehlə'],1),
('bio7-heyvanlar#2','biologiya','bio-7-heyvanlar',3,2,'Suda-quruda yaşayanların dərisi necədir?','Çılpaq və nəmdir (qurbağa kimi).',array['Çılpaq və nəm','Qalın tüklü','Lələkli','Buynuz pulcuqlu'],1),
('bio7-heyvanlar#3','biologiya','bio-7-heyvanlar',2,2,'Onurğalı heyvana misal hansıdır?','Balığın onurğası var.',array['Balıq','Soxulcan','İlbiz','Kəpənək'],1),
('bio7-heyvanlar#4','biologiya','bio-7-heyvanlar',2,2,'Onurğasız heyvan hansıdır?','Soxulcanın onurğası yoxdur.',array['Soxulcan','İt','Qartal','İlan'],1),
('bio7-heyvanlar#5','biologiya','bio-7-heyvanlar',2,2,'Həşəratların neçə ayağı var?','Həşəratların 6 ayağı var.',array['6','8','4','10'],1),
('bio7-heyvanlar#6','biologiya','bio-7-heyvanlar',2,2,'Hörümçəklərin neçə ayağı var?','Hörümçəklərin 8 ayağı var.',array['8','6','4','12'],1),
('bio7-heyvanlar#7','biologiya','bio-7-heyvanlar',3,2,'Sürünənlərin bədəni nə ilə örtülüdür?','Quru buynuz pulcuqlarla örtülüdür.',array['Buynuz pulcuqlarla','Nəm dəri ilə','Lələklə','Yunla'],1),
('bio7-heyvanlar#8','biologiya','bio-7-heyvanlar',2,2,'Məməlilərin əsas əlaməti nədir?','Balalarını südlə bəsləyirlər.',array['Balalarını südlə bəsləmək','Yumurta qoymaq','Suda nəfəs almaq','Qanadların olması'],1),
('bio7-heyvanlar#9','biologiya','bio-7-heyvanlar',3,2,'Xarici skelet hansı heyvanlara xasdır?','Buğumayaqlılara (həşəratlara, xərçəngkimilərə).',array['Buğumayaqlılara','Məməlilərə','Quşlara','Balıqlara'],1),
('bio7-heyvanlar#10','biologiya','bio-7-heyvanlar',3,2,'Delfin balıqdır, yoxsa məməli?','Delfin suda yaşayan məməlidir.',array['Məməlidir','Balıqdır','Suda-quruda yaşayandır','Molyuskdur'],1),
('bio7-muxteliflik#1','biologiya','bio-7-muxteliflik',2,3,'Bioloji müxtəliflik nədir?','Yer üzündəki canlı növlərinin zənginliyidir.',array['Canlı növlərinin zənginliyi','Daşların növləri','Havanın tərkibi','Suların dərinliyi'],1),
('bio7-muxteliflik#2','biologiya','bio-7-muxteliflik',3,3,'Növ nədir?','Çarpazlaşıb nəsil verən oxşar fərdlərin məcmusudur.',array['Oxşar fərdlərin məcmusu','Bir heyvanın adı','Bitkinin yarpağı','Yaşayış yeri'],1),
('bio7-muxteliflik#3','biologiya','bio-7-muxteliflik',3,3,'Canlıların təsnifatı ilə hansı elm məşğul olur?','Sistematika təsnifatla məşğuldur.',array['Sistematika','Astronomiya','Riyaziyyat','Tarix'],1),
('bio7-muxteliflik#4','biologiya','bio-7-muxteliflik',2,3,'Göbələklər nə ilə çoxalır?','Göbələklər sporlarla çoxalır.',array['Sporlarla','Toxumla','Çiçəklə','Yumurta ilə'],1),
('bio7-muxteliflik#5','biologiya','bio-7-muxteliflik',3,3,'Şibyələr hansı orqanizmlərin birliyidir?','Göbələklə yosunun simbiozudur.',array['Göbələk və yosunun','İki bitkinin','Bakteriya və virusun','İki heyvanın'],1),
('bio7-muxteliflik#6','biologiya','bio-7-muxteliflik',2,3,'Yosunlar əsasən harada yaşayır?','Yosunlar əsasən su mühitində yaşayır.',array['Suda','Səhrada','Buzda yalnız','Havada'],1),
('bio7-muxteliflik#7','biologiya','bio-7-muxteliflik',3,3,'Mamırların həqiqi kökü varmı?','Yoxdur — rizoidləri var.',array['Yoxdur, rizoidləri var','Bəli, dərin kökləri var','Yalnız qışda olur','Mamır bitki deyil'],1),
('bio7-muxteliflik#8','biologiya','bio-7-muxteliflik',3,3,'Çılpaqtoxumlu bitkiyə misal hansıdır?','Şam ağacının toxumu meyvə içində deyil.',array['Şam ağacı','Alma ağacı','Buğda','Lalə'],1),
('bio7-muxteliflik#9','biologiya','bio-7-muxteliflik',3,3,'Örtülütoxumlu bitkilərin toxumu harada yerləşir?','Toxum meyvənin içində yerləşir.',array['Meyvənin içində','Açıqda, pulcuqda','Kökdə','Yarpağın üstündə'],1),
('bio7-muxteliflik#10','biologiya','bio-7-muxteliflik',2,3,'Nadir növləri qorumaq üçün hansı ərazilər yaradılır?','Qoruqlar və milli parklar yaradılır.',array['Qoruqlar və milli parklar','Zavodlar','Şəhərlər','Yollar'],1),
('bio7-ekosistem#1','biologiya','bio-7-ekosistem',3,3,'Ekosistem nədir?','Canlıların və yaşayış mühitinin vəhdətidir.',array['Canlılarla mühitin vəhdəti','Yalnız heyvanlar','Yalnız bitkilər','Yalnız torpaq'],1),
('bio7-ekosistem#2','biologiya','bio-7-ekosistem',2,3,'Ekosistemdə enerjinin ilkin mənbəyi nədir?','İlkin mənbə Günəşdir.',array['Günəş','Torpaq','Su','Külək'],1),
('bio7-ekosistem#3','biologiya','bio-7-ekosistem',3,3,'Produsentlər (istehsalçılar) hansı canlılardır?','Üzvi maddə yaradan yaşıl bitkilərdir.',array['Yaşıl bitkilər','Yırtıcılar','Göbələklər','Bakteriyalar yalnız'],1),
('bio7-ekosistem#4','biologiya','bio-7-ekosistem',3,3,'Konsumentlər nə ilə qidalanır?','Hazır üzvi maddələrlə qidalanır.',array['Hazır üzvi maddələrlə','Günəş işığı ilə','Mineral duzlarla yalnız','Heç nə ilə'],1),
('bio7-ekosistem#5','biologiya','bio-7-ekosistem',3,3,'Redusentlər (parçalayıcılar) hansı canlılardır?','Bakteriya və göbələklər üzvi qalıqları parçalayır.',array['Bakteriya və göbələklər','Ağaclar','Quşlar','Balıqlar'],1),
('bio7-ekosistem#6','biologiya','bio-7-ekosistem',2,3,'Qida zəncirinin ilk halqası adətən nə olur?','Zəncir bitki ilə başlayır.',array['Bitki','Yırtıcı','İnsan','Göbələk'],1),
('bio7-ekosistem#7','biologiya','bio-7-ekosistem',3,3,'Enerji qida zənciri boyunca necə dəyişir?','Hər halqada enerji azalır.',array['Azalır','Artır','Dəyişmir','İki dəfə çoxalır'],1),
('bio7-ekosistem#8','biologiya','bio-7-ekosistem',2,3,'Meşə ekosisteminə nələr daxildir?','Bitkilər, heyvanlar, torpaq, mikroorqanizmlər.',array['Bitkilər, heyvanlar, torpaq','Yalnız ağaclar','Yalnız quşlar','Yalnız hava'],1),
('bio7-ekosistem#9','biologiya','bio-7-ekosistem',2,3,'İnsan fəaliyyəti ekosistemlərə necə təsir edə bilər?','Çirklənmə və meşə qırma ekosistemi poza bilər.',array['Poza bilər','Heç cür təsir etmir','Yalnız yaxşılaşdırır','Ekosistemlər dəyişmir'],1),
('bio7-ekosistem#10','biologiya','bio-7-ekosistem',3,3,'Süni ekosistemə misal hansıdır?','Akvariumu insan yaradıb idarə edir.',array['Akvarium','Okean','Tayqa meşəsi','Səhra'],1),
('bio7-saglam-heyat#1','biologiya','bio-7-saglam-heyat',1,4,'Sağlam həyat tərzinin əsas şərtlərindən biri hansıdır?','Düzgün qidalanma və fiziki fəallıq.',array['Düzgün qidalanma və hərəkət','Gecə oyaq qalmaq','Çox şirniyyat yemək','Hərəkətsizlik'],1),
('bio7-saglam-heyat#2','biologiya','bio-7-saglam-heyat',3,4,'Vitamin çatışmazlığı necə adlanır?','Bu hal avitaminoz adlanır.',array['Avitaminoz','Allergiya','Qrip','Angina'],1),
('bio7-saglam-heyat#3','biologiya','bio-7-saglam-heyat',2,4,'C vitamini ən çox hansı qidalarda olur?','Sitrus meyvələrində (limon, portağal) boldur.',array['Sitrus meyvələrində','Çörəkdə','Yağda','Duzda'],1),
('bio7-saglam-heyat#4','biologiya','bio-7-saglam-heyat',1,4,'Zərərli vərdişlərə nə aiddir?','Siqaret və digər zərərli maddələr.',array['Siqaret çəkmək','İdman etmək','Kitab oxumaq','Tez yatmaq'],1),
('bio7-saglam-heyat#5','biologiya','bio-7-saglam-heyat',2,4,'Gün rejiminə əməl etmək nəyə kömək edir?','Sağlamlığa və yüksək iş qabiliyyətinə.',array['Sağlamlığa və iş qabiliyyətinə','Yorğunluğa','Yuxusuzluğa','Heç nəyə'],1),
('bio7-saglam-heyat#6','biologiya','bio-7-saglam-heyat',2,4,'Orqanizm yuxu zamanı nəyi bərpa edir?','Gücünü və sinir sistemini bərpa edir.',array['Gücünü və sinir sistemini','Yalnız saçını','Yalnız dırnağını','Heç nəyi'],1),
('bio7-saglam-heyat#7','biologiya','bio-7-saglam-heyat',2,4,'Səhər gimnastikası orqanizmi nəyə hazırlayır?','Günün fəallığına hazırlayır.',array['Günün fəallığına','Yuxuya','Xəstəliyə','Yorğunluğa'],1),
('bio7-saglam-heyat#8','biologiya','bio-7-saglam-heyat',2,4,'Yoluxucu xəstəliklərdən qorunmağın yollarından biri hansıdır?','Gigiyena qaydaları və peyvənd.',array['Gigiyena və peyvənd','Soyuq su içmək','Çox yemək','Az yatmaq'],1),
('bio7-saglam-heyat#9','biologiya','bio-7-saglam-heyat',3,4,'Balanslı qidalanma nə deməkdir?','Zülal, yağ və karbohidratların düzgün nisbəti.',array['Qida maddələrinin düzgün nisbəti','Yalnız ət yemək','Yalnız şirniyyat','Gündə bir dəfə yemək'],1),
('bio7-saglam-heyat#10','biologiya','bio-7-saglam-heyat',2,4,'Uzunmüddətli hərəkətsizlik nəyə gətirib çıxarır?','Əzələlərin zəifləməsinə səbəb olur.',array['Əzələlərin zəifləməsinə','Güclənməyə','Boy artımına','Heç nəyə'],1),
('cog7-movqe#1','cografiya','cog-7-movqe',2,1,'Coğrafi mövqe nədir?','Obyektin Yer səthindəki yeridir.',array['Obyektin Yer səthindəki yeri','Obyektin çəkisi','Obyektin rəngi','Obyektin qiyməti'],1),
('cog7-movqe#2','cografiya','cog-7-movqe',3,1,'Coğrafi enlik haradan ölçülür?','Enlik ekvatordan ölçülür.',array['Ekvatordan','Qütbdən','Bakıdan','Dənizdən'],1),
('cog7-movqe#3','cografiya','cog-7-movqe',3,1,'Coğrafi uzunluq hansı meridiandan hesablanır?','Başlanğıc (Qrinviç) meridianından.',array['Qrinviç meridianından','Ekvatordan','180° meridianından','İstənilən meridiandan'],1),
('cog7-movqe#4','cografiya','cog-7-movqe',2,1,'Ekvator Yeri hansı yarımkürələrə bölür?','Şimal və cənub yarımkürələrinə.',array['Şimal və cənub','Şərq və qərb','Üst və alt','Bölmür'],1),
('cog7-movqe#5','cografiya','cog-7-movqe',3,1,'Meridianlar hansı istiqaməti göstərir?','Şimal-cənub istiqamətini.',array['Şimal-cənub','Şərq-qərb','Dairəvi','Heç birini'],1),
('cog7-movqe#6','cografiya','cog-7-movqe',3,1,'Paralellər xəritədə hansı formadadır?','Ekvatora paralel çevrələrdir.',array['Ekvatora paralel çevrələr','Düz şaquli xətlər','Ziqzaqlar','Üçbucaqlar'],1),
('cog7-movqe#7','cografiya','cog-7-movqe',2,1,'Nöqtənin coğrafi koordinatlarını nə təşkil edir?','Coğrafi enlik və uzunluq.',array['Enlik və uzunluq','Hündürlük və dərinlik','Sahə və perimetr','Ad və nömrə'],1),
('cog7-movqe#8','cografiya','cog-7-movqe',2,1,'Azərbaycan hansı yarımkürədə yerləşir?','Şimal yarımkürəsində yerləşir.',array['Şimal yarımkürəsində','Cənub yarımkürəsində','Ekvatorun üstündə','Qütbdə'],1),
('cog7-movqe#9','cografiya','cog-7-movqe',2,1,'Azərbaycanın şimal qonşusu hansı ölkədir?','Şimalda Rusiya ilə həmsərhəddir.',array['Rusiya','İran','Türkiyə','Pakistan'],1),
('cog7-movqe#10','cografiya','cog-7-movqe',3,1,'Ölkənin dənizə çıxışı nəyə müsbət təsir edir?','Ticarət və nəqliyyat əlaqələrinə.',array['Ticarət əlaqələrinə','Dağların hündürlüyünə','İqlim qurşağına','Heç nəyə'],1),
('cog7-daxili#1','cografiya','cog-7-daxili',2,1,'Yerin daxili qatları hansılardır?','Nüvə, mantiya və yer qabığı.',array['Nüvə, mantiya, yer qabığı','Su, hava, torpaq','Dağ, düzən, dərə','Şimal, cənub, mərkəz'],1),
('cog7-daxili#2','cografiya','cog-7-daxili',2,1,'Yerin ən daxili qatı hansıdır?','Mərkəzdə nüvə yerləşir.',array['Nüvə','Mantiya','Yer qabığı','Okean'],1),
('cog7-daxili#3','cografiya','cog-7-daxili',3,1,'Litosfer tavaları nədir?','Yer qabığının hərəkət edən iri bölmələridir.',array['Yer qabığının iri bölmələri','Dəniz dalğaları','Buz parçaları','Qum təpələri'],1),
('cog7-daxili#4','cografiya','cog-7-daxili',3,1,'Zəlzələlər ən çox harada baş verir?','Litosfer tavalarının sərhədlərində.',array['Tavaların sərhədlərində','Tavaların mərkəzində','Yalnız okeanda','Yalnız səhrada'],1),
('cog7-daxili#5','cografiya','cog-7-daxili',2,1,'Vulkanın ağzı necə adlanır?','Vulkanın ağzı krater adlanır.',array['Krater','Mənbə','Mənsəb','Zirvə'],1),
('cog7-daxili#6','cografiya','cog-7-daxili',3,1,'Yerin dərinliyindəki ərimiş maddə necə adlanır?','Dərinlikdəki ərimiş maddə maqmadır.',array['Maqma','Lava','Palçıq','Neft'],1),
('cog7-daxili#7','cografiya','cog-7-daxili',2,1,'Zəlzələnin gücü nə ilə qiymətləndirilir?','Ballarla qiymətləndirilir (seysmoqrafla qeyd olunur).',array['Ballarla','Litrlə','Kiloqramla','Saniyə ilə'],1),
('cog7-daxili#8','cografiya','cog-7-daxili',3,1,'Qeyzerlər və isti bulaqlar nəyin əlamətidir?','Vulkanik fəallığın əlamətidir.',array['Vulkanik fəallığın','Buzlaşmanın','Küləyin','Meşələrin'],1),
('cog7-daxili#9','cografiya','cog-7-daxili',3,1,'Dağəmələgəlmə əsasən nəyin nəticəsidir?','Litosfer tavalarının toqquşmasının.',array['Tavaların toqquşmasının','Yağışların','Küləklərin','İnsan fəaliyyətinin'],1),
('cog7-daxili#10','cografiya','cog-7-daxili',3,1,'Mantiya harada yerləşir?','Nüvə ilə yer qabığı arasında.',array['Nüvə ilə yer qabığı arasında','Yer səthində','Okeanın üstündə','Atmosferdə'],1),
('cog7-seth#1','cografiya','cog-7-seth',2,2,'Relyef nədir?','Yer səthinin formalarının məcmusudur.',array['Yer səthinin formaları','Havanın vəziyyəti','Suyun duzluluğu','Bitki örtüyü'],1),
('cog7-seth#2','cografiya','cog-7-seth',3,2,'Ovalıq hansı hündürlüyə qədər olan düzənlikdir?','0–200 m hündürlükdə olan düzənliklər ovalıqdır.',array['200 m-ə qədər','1000 m-ə qədər','5000 m-dən yuxarı','Hündürlüyü olmur'],1),
('cog7-seth#3','cografiya','cog-7-seth',2,2,'Dağlar hündürlüyünə görə necə qruplaşdırılır?','Alçaq, orta və hündür dağlar.',array['Alçaq, orta, hündür','Qara və ağ','Yaşlı və cavan yalnız','Qruplaşdırılmır'],1),
('cog7-seth#4','cografiya','cog-7-seth',3,2,'Qurudakı ən uzun dağ silsiləsi hansıdır?','And dağları ən uzun silsilədir.',array['And dağları','Alp dağları','Ural dağları','Qafqaz dağları'],1),
('cog7-seth#5','cografiya','cog-7-seth',3,2,'Yayla necə ərazidir?','Hündürlükdə yerləşən geniş düzənlikdir.',array['Hündür düzənlik','Dərin çökəklik','Dar dərə','Qumlu sahil'],1),
('cog7-seth#6','cografiya','cog-7-seth',3,2,'Xarici qüvvələr relyefə necə təsir edir?','Aşındırıb hamarlayır.',array['Aşındırıb hamarlayır','Yalnız hündürləşdirir','Təsir etmir','Yalnız rəngini dəyişir'],1),
('cog7-seth#7','cografiya','cog-7-seth',3,2,'Çay dərələri hansı qüvvənin fəaliyyəti ilə yaranır?','Axar suların yuma fəaliyyəti ilə.',array['Axar suların','Vulkanların','İnsanların','Heyvanların'],1),
('cog7-seth#8','cografiya','cog-7-seth',3,2,'Səhralarda qumun toplanması ilə hansı formalar yaranır?','Barxanlar (qum təpələri) yaranır.',array['Barxanlar','Aysberqlər','Şəlalələr','Qayalıqlar'],1),
('cog7-seth#9','cografiya','cog-7-seth',3,2,'Okean dibinin ən dərin yerləri necə adlanır?','Dərin novlar adlanır (məs., Marian novu).',array['Novlar','Yaylalar','Vadilər','Deltalar'],1),
('cog7-seth#10','cografiya','cog-7-seth',2,2,'Düzənliklər insan həyatı üçün nə ilə əlverişlidir?','Əkinçilik və məskunlaşma üçün əlverişlidir.',array['Əkinçilik və məskunlaşma üçün','Heç nə ilə','Yalnız mədən üçün','Yalnız turizm üçün'],1),
('cog7-hava#1','cografiya','cog-7-hava',2,2,'Hava şəraitini öyrənən elm necə adlanır?','Meteorologiya hava şəraitini öyrənir.',array['Meteorologiya','Geologiya','Biologiya','Tarix'],1),
('cog7-hava#2','cografiya','cog-7-hava',2,2,'Atmosfer təzyiqini hansı cihaz ölçür?','Təzyiq barometrlə ölçülür.',array['Barometr','Termometr','Hiqrometr','Xətkeş'],1),
('cog7-hava#3','cografiya','cog-7-hava',3,2,'Havanın rütubətini hansı cihaz ölçür?','Rütubət hiqrometrlə ölçülür.',array['Hiqrometr','Barometr','Ampermetr','Saat'],1),
('cog7-hava#4','cografiya','cog-7-hava',3,2,'Külək hansı təzyiq sahəsindən hansına əsir?','Yüksək təzyiqdən alçağa doğru.',array['Yüksəkdən alçağa','Alçaqdan yüksəyə','Yalnız şimaldan','Qaydası yoxdur'],1),
('cog7-hava#5','cografiya','cog-7-hava',3,2,'Buludlar nədən əmələ gəlir?','Su buxarının kondensasiyasından.',array['Su buxarının kondensasiyasından','Tozdan yalnız','Tüstüdən','İşıqdan'],1),
('cog7-hava#6','cografiya','cog-7-hava',2,2,'Yağıntı növləri hansılardır?','Yağış, qar, dolu.',array['Yağış, qar, dolu','Külək, tufan','Duman, şaxta yalnız','Şimşək və göy gurultusu'],1),
('cog7-hava#7','cografiya','cog-7-hava',3,2,'Şeh (şəbnəm) nə vaxt əmələ gəlir?','Gecə səth soyuyanda buxar kondensasiya olunur.',array['Gecə soyuma zamanı','Günorta istidə','Yalnız qışda','Heç vaxt'],1),
('cog7-hava#8','cografiya','cog-7-hava',2,2,'Hündürlüyə qalxdıqca havanın temperaturu necə dəyişir?','Temperatur azalır.',array['Azalır','Artır','Dəyişmir','Əvvəl artır, sonra sabitdir'],1),
('cog7-hava#9','cografiya','cog-7-hava',2,2,'Sinoptik xəritələr nə üçün tərtib olunur?','Hava proqnozu vermək üçün.',array['Hava proqnozu üçün','Yol çəkmək üçün','Ev tikmək üçün','Bəzək üçün'],1),
('cog7-hava#10','cografiya','cog-7-hava',3,2,'Duman nədir?','Yer səthinə yaxın kondensasiya olunmuş su damcılarıdır.',array['Səthə yaxın su damcıları','Tüstü','Toz buludu','Qar dənələri'],1),
('cog7-iqlim#1','cografiya','cog-7-iqlim',2,3,'İqlim nədir?','Ərazinin çoxillik hava rejimidir.',array['Çoxillik hava rejimi','Bir günün havası','Yalnız yağıntı','Yalnız temperatur'],1),
('cog7-iqlim#2','cografiya','cog-7-iqlim',3,3,'İqlimlə hava şəraitinin fərqi nədir?','İqlim sabit çoxillik, hava dəyişkəndir.',array['İqlim çoxillik, hava dəyişkəndir','Fərq yoxdur','Hava çoxillikdir','İqlim hər gün dəyişir'],1),
('cog7-iqlim#3','cografiya','cog-7-iqlim',2,3,'Ekvatorial qurşaqda iqlim necədir?','İl boyu isti və rütubətlidir.',array['İsti və rütubətli','Soyuq və quru','Şaxtalı','Mülayim'],1),
('cog7-iqlim#4','cografiya','cog-7-iqlim',3,3,'Arktik iqlim qurşağının xüsusiyyəti nədir?','Uzun şaxtalı qış, qısa sərin yay.',array['Uzun şaxtalı qış','İsti yay','Bol tropik yağış','Daimi istilik'],1),
('cog7-iqlim#5','cografiya','cog-7-iqlim',2,3,'İqlimə təsir edən amillərdən biri hansıdır?','Coğrafi enlik əsas amildir.',array['Coğrafi enlik','Əhalinin sayı','Dövlət dili','Bayraq rəngi'],1),
('cog7-iqlim#6','cografiya','cog-7-iqlim',3,3,'Dəniz iqlimini kontinental iqlimdən nə fərqləndirir?','Dəniz iqlimində temperatur amplitudu kiçikdir.',array['Temperatur amplitudu kiçikdir','Daha şaxtalıdır','Yağıntı olmur','Fərq yoxdur'],1),
('cog7-iqlim#7','cografiya','cog-7-iqlim',2,3,'Dağlarda yüksəkliyə qalxdıqca iqlim necə dəyişir?','Soyuqlaşır, qurşaqlar dəyişir.',array['Soyuqlaşır','İstiləşir','Dəyişmir','Yalnız küləklənir'],1),
('cog7-iqlim#8','cografiya','cog-7-iqlim',2,3,'Mülayim qurşaqda fəsillər necədir?','Dörd fəsil aydın seçilir.',array['Dörd fəsil aydın seçilir','Həmişə yaydır','Həmişə qışdır','İki fəsil olur'],1),
('cog7-iqlim#9','cografiya','cog-7-iqlim',3,3,'Okean cərəyanları iqlimə necə təsir edir?','İstiliyi bir yerdən başqa yerə daşıyır.',array['İstiliyi paylayır','Təsir etmir','Yalnız dalğa yaradır','Yalnız duz daşıyır'],1),
('cog7-iqlim#10','cografiya','cog-7-iqlim',3,3,'Subtropik iqlim qurşağı harada yerləşir?','Tropik ilə mülayim qurşaq arasında.',array['Tropik ilə mülayim arasında','Qütbdə','Ekvatorun üstündə','Okeanın dibində'],1),
('cog7-mesken#1','cografiya','cog-7-mesken',2,3,'İnsanlar məskunlaşma üçün əsasən hansı əraziləri seçiblər?','Su mənbələrinə yaxın münbit düzənlikləri.',array['Su mənbələrinə yaxın düzənlikləri','Buzlaqları','Səhraların mərkəzini','Vulkan kraterlərini'],1),
('cog7-mesken#2','cografiya','cog-7-mesken',3,3,'Urbanizasiya nədir?','Şəhərlərin və şəhər əhalisinin artmasıdır.',array['Şəhər əhalisinin artması','Kəndlərin çoxalması','Əhalinin azalması','Meşələrin artması'],1),
('cog7-mesken#3','cografiya','cog-7-mesken',2,3,'Kənd yaşayış məntəqələrində insanlar əsasən nə ilə məşğuldur?','Kənd təsərrüfatı ilə məşğuldurlar.',array['Kənd təsərrüfatı ilə','Ağır sənaye ilə','Kosmik tədqiqatlarla','Bank işi ilə'],1),
('cog7-mesken#4','cografiya','cog-7-mesken',3,3,'Meqapolis nədir?','Bir-birinə qovuşmuş nəhəng şəhərlər zolağıdır.',array['Nəhəng şəhərlər birliyi','Kiçik kənd','Dağ kəndi','Ada'],1),
('cog7-mesken#5','cografiya','cog-7-mesken',2,3,'Dünya əhalisinin sayı hazırda təqribən nə qədərdir?','8 milyarddan çoxdur.',array['8 milyarddan çox','1 milyon','100 milyon','500 min'],1),
('cog7-mesken#6','cografiya','cog-7-mesken',3,3,'Əhalinin sıxlığı necə hesablanır?','Əhalinin sayı ərazinin sahəsinə bölünür.',array['Əhali sayı sahəyə bölünür','Sahə əhaliyə vurulur','Şəhərlərin sayı ilə','Hesablanmır'],1),
('cog7-mesken#7','cografiya','cog-7-mesken',2,3,'Göydələnlər əsasən harada tikilir?','Torpağın baha olduğu iri şəhərlərdə.',array['İri şəhərlərdə','Kəndlərdə','Meşələrdə','Səhralarda'],1),
('cog7-mesken#8','cografiya','cog-7-mesken',3,3,'Əhali ən sıx hansı ərazilərdə yaşayır?','Münbit düzənliklərdə və dəniz sahillərində.',array['Münbit düzənliklərdə və sahillərdə','Buzlaqlarda','Yüksək dağlarda','Bataqlıqlarda'],1),
('cog7-mesken#9','cografiya','cog-7-mesken',2,3,'Miqrasiya nədir?','Əhalinin bir yerdən başqa yerə köçməsidir.',array['Əhalinin yerdəyişməsi','Evlərin tikilməsi','Şəhərin adının dəyişməsi','Heyvanların qışlaması'],1),
('cog7-mesken#10','cografiya','cog-7-mesken',3,3,'Hazırda dünyada ən çox əhalisi olan ölkə hansıdır?','Hindistan əhalisinə görə birincidir.',array['Hindistan','Azərbaycan','Fransa','Misir'],1),
('cog7-iqtisadi#1','cografiya','cog-7-iqtisadi',2,4,'İqtisadi fəaliyyətin əsas sahələri hansılardır?','Kənd təsərrüfatı, sənaye və xidmət sahəsi.',array['Kənd təsərrüfatı, sənaye, xidmət','Yalnız idman','Yalnız incəsənət','Yalnız təhsil'],1),
('cog7-iqtisadi#2','cografiya','cog-7-iqtisadi',3,4,'Hasilat sənayesi nə ilə məşğuldur?','Faydalı qazıntıların çıxarılması ilə.',array['Faydalı qazıntıların çıxarılması ilə','Paltar tikilməsi ilə','Çörək bişirilməsi ilə','Dərs deməklə'],1),
('cog7-iqtisadi#3','cografiya','cog-7-iqtisadi',2,4,'Azərbaycanın əsas təbii sərvəti hansıdır?','Neft və təbii qaz.',array['Neft və qaz','Almaz','Qızıl yalnız','Uran'],1),
('cog7-iqtisadi#4','cografiya','cog-7-iqtisadi',2,4,'Kənd təsərrüfatının əsas sahələri hansılardır?','Əkinçilik və heyvandarlıq.',array['Əkinçilik və heyvandarlıq','Neftçıxarma','Gəmiqayırma','Kosmonavtika'],1),
('cog7-iqtisadi#5','cografiya','cog-7-iqtisadi',2,4,'Xidmət sahəsinə nə daxildir?','Təhsil, səhiyyə, nəqliyyat, ticarət.',array['Təhsil, səhiyyə, nəqliyyat','Yalnız zavodlar','Yalnız mədənlər','Yalnız tarlalar'],1),
('cog7-iqtisadi#6','cografiya','cog-7-iqtisadi',3,4,'Emal sənayesi nə ilə məşğuldur?','Xammalı hazır məhsula çevirir.',array['Xammalı hazır məhsula çevirir','Yalnız daş çıxarır','Yalnız balıq tutur','Heç nə istehsal etmir'],1),
('cog7-iqtisadi#7','cografiya','cog-7-iqtisadi',2,4,'Turizm hansı sahəyə aiddir?','Turizm xidmət sahəsidir.',array['Xidmət sahəsinə','Hasilat sənayesinə','Əkinçiliyə','Heyvandarlığa'],1),
('cog7-iqtisadi#8','cografiya','cog-7-iqtisadi',2,4,'İxrac nədir?','Malın xarici ölkələrə satılmasıdır.',array['Malın xaricə satılması','Malın xaricdən alınması','Malın anbarda saxlanması','Malın məhv edilməsi'],1),
('cog7-iqtisadi#9','cografiya','cog-7-iqtisadi',2,4,'İdxal nədir?','Malın xaricdən ölkəyə gətirilməsidir.',array['Malın xaricdən alınması','Malın xaricə satılması','Malın istehsalı','Vergi növü'],1),
('cog7-iqtisadi#10','cografiya','cog-7-iqtisadi',3,4,'Pambıqçılıq Azərbaycanın hansı bölgəsində inkişaf etmişdir?','Aran bölgəsində (Kür-Araz ovalığında).',array['Aran bölgəsində','Böyük Qafqaz zirvələrində','Bakı buxtasında','Naxçıvan dağlarında'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = d.fenn
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '7'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = d.topic
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, quarter = excluded.quarter,
        topic_id = excluded.topic_id, level_id = excluded.level_id,
        subject_id = excluded.subject_id, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(d.opts) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform'
     and (ext_key like 'fiz7-%' or ext_key like 'kim7-%'
          or ext_key like 'bio7-%' or ext_key like 'cog7-%');
  if n <> 280 then
    raise exception 'fenn7 suallari: 280 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'fiz7-%' or q.ext_key like 'kim7-%'
          or q.ext_key like 'bio7-%' or q.ext_key like 'cog7-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'fiz7-%' or ext_key like 'kim7-%'
      or ext_key like 'bio7-%' or ext_key like 'cog7-%';
  if k <> 28 then
    raise exception 'movzu sayi 28 deyil: %', k;
  end if;
  raise notice '7-ci sinif tebiet fennleri banki: % sual, 28 movzu (fiz, kim, bio, cog).', n;
end $$;
