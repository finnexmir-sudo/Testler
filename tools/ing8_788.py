#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ingilis dili 8 (ikinci xarici dil, kitab 788) -> db/99_bank_ingilis8_788.sql

NIYE: mövcud ing-8-* banki (6 mövzu) kitab 788-in real 12 LESSON-una
uygun deyildi - hetta movcud 3 "uygun" movzunun (holidays/inventions/
hobbies) qrammatika sualları da bu kitabin qrammatikasi ile UYGUN
GəLMIRDI (mes. holidays Present Perfect test edirdi, kitabin Lesson 1-i
ise "too/enough" oyredir).  Butun 12 movzu kitabin oz Lesson-larina ve
qrammatikasina gore YENIDEN yazildi.

12 movzu x 30 sual = 360.  ext_key: ing8v2-<movzu>#<sira> (kohne
"ing8-*" acarlarindan AYRI - kohne suallar arxivlenir, silinmir).

Apostrof qadagandir (SQL sade dirnaqla yazilir) - "do not", "is not",
"cannot" formalari islenib.

Isletmek:
    python3 tools/ing8_788.py
"""
import io
import os

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIXIS = os.path.join(KOK, "db", "99_bank_ingilis8_788.sql")

#  (slug, ad, sort, kohne_slug_ve_reuse_movcud_sətri_yoxsa_yox)
MOVZULAR = [
    ("ing-8-holidays",           "Summer Holiday",              10),
    ("ing-8-inventions",         "Young Inventors",             20),
    ("ing-8-hobbies",            "Hobbies Around the World",    30),
    ("ing-8-real-heroes",        "Real Heroes",                 40),
    ("ing-8-choose-kind",        "Choose to Be Kind",           50),
    ("ing-8-travel-stories",     "Travel Stories",              60),
    ("ing-8-celebrations",       "Celebrations",                70),
    ("ing-8-art",                "Art",                         80),
    ("ing-8-environment",        "Help the Earth",              90),
    ("ing-8-people-life",        "People in Our Life",         100),
    ("ing-8-modern-technology",  "Modern Technology",          110),
    ("ing-8-important-skills",   "Important Skills for Teens", 120),
]

SUALLAR = {

# ==================== LESSON 1: too / enough ==========================
"ing-8-holidays": [
 ("«Excursion» sozunun mənası nədir?", "Excursion qisa bir seyahetdir.",
  ["qisa seyahət", "bilet", "otel", "hava limani"], 1, 1),
 ("«Suitcase» sozunun mənası nədir?", "Suitcase paltar ucun cantadir.",
  ["paltar cantasi", "xerite", "bilet", "otaq"], 1, 1),
 ("«Flight» sozunun mənası nədir?", "Flight teyyare ile seyahetdir.",
  ["teyyare seferi", "qatar", "avtobus", "gemi"], 1, 1),
 ("«Seaside» sozunun mənası nədir?", "Seaside deniz kenaridir.",
  ["deniz kenari", "meşə", "dag", "sehra"], 1, 1),
 ("«Abroad» sozu nəyi bildirir?", "Abroad basqa olkede demekdir.",
  ["basqa olkede", "ozu evinde", "mektebde", "bazarda"], 1, 1),
 ("«Souvenir» sozunun mənası nədir?", "Souvenir xatire hediyyesidir.",
  ["xatire hədiyyəsi", "bilet", "pasport", "xerite"], 1, 1),
 ("«Sandy beach» ifadəsi nəyi bildirir?", "Sandy beach qumlu sahildir.",
  ["qumlu sahil", "daglik yer", "meşəlik", "göl kənarı"], 1, 1),
 ("«Timetable» seyahetde nə ucun lazimdir?",
  "Timetable herəkət saatlarını bildirir.",
  ["hərəkət saatlarını bilmək üçün", "yemək bişirmək üçün",
   "otaq açmaq üçün", "bilet çap etmək üçün"], 1, 1),
 ("«Travel agency» nə ucundur?", "Travel agency sefer teskil edir.",
  ["səfər təşkil etmək", "qida satmaq", "kitab çap etmək",
   "avtomobil təmiri"], 1, 2),
 ("«Tourist attraction» ifadəsi nəyi bildirir?",
  "Tourist attraction meshur bir yerdir.",
  ["məşhur ziyarət yeri", "otel otağı", "bilet qiyməti",
   "hava proqnozu"], 1, 2),
 ("«Package tour» nə deməkdir?", "Package tour teskil olunmus seferdir.",
  ["təşkil olunmuş səyahət", "tək bilet", "yerli xəritə",
   "gecə qatarı"], 1, 2),
 ("«Campsite» nə deməkdir?", "Campsite duşərgə saliniş yeridir.",
  ["düşərgə salınan yer", "hava limanı", "muzey", "restoran"], 1, 2),
 ("«Miss the train» ifadəsi nə deməkdir?",
  "Miss the train qatara gecikmek demekdir.",
  ["qatara gecikmək", "qatarda yatmaq", "bilet almaq",
   "qatarı təmizləmək"], 1, 2),
 ("«Local food» ifadəsi nəyi bildirir?",
  "Local food yerli qidadir.", ["yerli qida", "xarici valyuta",
   "otaq açarı", "yol xəritəsi"], 1, 2),
 ("«Book a room in advance» nə deməkdir?",
  "Bu, otagi evvelceden sifariş etmek demekdir.",
  ["otağı əvvəlcədən sifariş etmək", "otaqda qalmamaq",
   "otağı təmizləmək", "otağı satmaq"], 1, 2),
 ("«Unforgettable holiday» ifadəsi necə istirahəti bildirir?",
  "Unforgettable yaddan cixmayan demekdir.",
  ["yaddan çıxmayan", "qısa", "bahalı", "yorucu"], 1, 2),
 ("«The suitcase is too heavy.» cumlesi neyi bildirir?",
  "«Too heavy» cox agir, dasimaq cetin demekdir.",
  ["Onu daşımaq çətindir", "Onu itirdilər", "O boşdur",
   "O çox yüngüldür"], 1, 2),
 ("«too» sozu adeten hansi menani verir?",
  "«Too» lazim olandan artiq, menfi menada islenir.",
  ["lazım olandan artıq (mənfi)", "kifayət qədər",
   "çox az", "tam düz"], 1, 2),
 ("«enough» sozu sifetden evvel, yoxsa sonra islenir?",
  "«Enough» sifetden SONRA gelir: big enough.",
  ["sifətdən sonra", "sifətdən əvvəl", "felin əvvəlində",
   "cümlənin sonunda həmişə tək"], 1, 2),
 ("«She is not old enough to travel alone.» cumlesi neyi bildirir?",
  "Bu, o hele cavandir, tek seyahet ede bilmez demekdir.",
  ["O, tək səyahət etmək üçün çox cavandır",
   "O, tək səyahət etmək istəmir", "O, artıq böyükdür",
   "O, heç vaxt səyahət etmir"], 1, 3),
 ("«We do not have enough time for the tour.» — nə çatismir?",
  "Vaxt catismir.", ["vaxt", "pul", "bilet", "yol"], 1, 3),
 ("«The hotel was too expensive for us.» cumlesi nə demekdir?",
  "Otel cox bahali idi, onu qarsilaya bilmediler.",
  ["Onu qarşılaya bilmədilər", "Onu çox bəyəndilər",
   "Orada qaldılar", "O, çox ucuz idi"], 1, 3),
 ("«Is the beach clean enough to swim?» — bu sual nəyi soruşur?",
  "Sahilin uzmek ucun kifayet qeder temiz olub-olmadigi.",
  ["Sahil üzmək üçün kifayət qədər təmizdirmi",
   "Sahil nə qədər uzundur", "Sahildə neçə adam var",
   "Sahil harada yerləşir"], 1, 3),
 ("«This bag is enough big.» cumlesi qrammatik cehetden duzgundurmu?",
  "Yox, doğru sıra: «big enough».",
  ["Yox, doğrusu «big enough»", "Bəli, tam düzdür",
   "Yox, doğrusu «enough bag»", "Bəli, amma mənası dəyişir"], 1, 3),
 ("«The weather was too hot to go hiking.» cumlesinde ne bas vermedi?",
  "Hava cox isti oldugu ucun gezintiye getmediler.",
  ["Gəzintiyə getmədilər", "Gəzintiyə getdilər", "Üşüdülər",
   "Yağış yağdı"], 1, 3),
 ("«He was not fast enough to catch the bus.» — neticə nədir?",
  "O, avtobusu qacirdi.",
  ["Avtobusu qaçırdı", "Avtobusa mindi", "Avtobusu sürdü",
   "Avtobusu gözlədi"], 1, 3),
 ("«This suitcase is big enough for all my clothes.» cumlesi neyi bildirir?",
  "Cantada butun paltarlar ucun kifayet qeder yer var.",
  ["Kifayət qədər yer var", "Yer çatmır", "Çanta çox kiçikdir",
   "Çanta boşdur"], 1, 3),
 ("«too tired» ifadəsi necə bir vəziyyəti bildirir?",
  "Cox yorgun, davam ede bilmeyen veziyyet.",
  ["çox yorğun, davam edə bilməyən", "az yorğun",
   "tam dincəlmiş", "həvəskar"], 1, 2),
 ("«We arrived early enough to get good seats.» — nə ucun erken geldiler?",
  "Yaxsi yer tutmaq ucun.",
  ["Yaxşı yer tutmaq üçün", "Avtobusu qaçırmaq üçün",
   "İstirahət etmək üçün", "Bilet almamaq üçün"], 1, 2),
 ("«The queue was too long, so we left.» cumlesinde niye getdiler?",
  "Növbə çox uzun oldugu ucun.",
  ["Növbə çox uzun idi", "Növbə çox qısa idi", "Hava soyuq idi",
   "Bilet bahalı idi"], 1, 2),
],

# ==================== LESSON 2: as...as / not as...as =================
"ing-8-inventions": [
 ("«Inventor» kimdir?", "Inventor yeni bir sey yaradan sexsdir.",
  ["yeni şey yaradan şəxs", "kitab satan şəxs", "müəllim",
   "həkim"], 1, 1),
 ("«Scientist» sozunun mənası nədir?", "Scientist alim demekdir.",
  ["alim", "aktyor", "musiqiçi", "idmançı"], 1, 1),
 ("«Discovery» sozunun mənası nədir?", "Discovery kesf demekdir.",
  ["kəşf", "səyahət", "kitab", "oyun"], 1, 1),
 ("«Laboratory» sozunun mənası nədir?", "Laboratory tecrube otagidir.",
  ["təcrübə otağı", "kitabxana", "mətbəx", "anbar"], 1, 1),
 ("«Telescope» nə ucun istifadə olunur?",
  "Telescope ulduzlari muşahide etmek ucundur.",
  ["ulduzları müşahidə etmək", "səs eşitmək", "yol göstərmək",
   "vaxtı ölçmək"], 1, 1),
 ("«Device» sozunun mənası nədir?", "Device cihaz demekdir.",
  ["cihaz", "kitab", "geyim", "oyuncaq"], 1, 1),
 ("«Experiment» nə deməkdir?", "Experiment tecrube demekdir.",
  ["təcrübə", "nəticə", "sual", "cavab"], 1, 1),
 ("«Improve» feili nə deməkdir?", "Improve yaxsilasdirmaq demekdir.",
  ["yaxşılaşdırmaq", "sındırmaq", "satmaq", "unutmaq"], 1, 1),
 ("«Useful invention» ifadəsi nə deməkdir?",
  "Fayda veren ixtira demekdir.",
  ["fayda verən ixtira", "köhnə əşya", "baha oyuncaq",
   "boş qutu"], 1, 2),
 ("«Create» feili nə deməkdir?", "Create yaratmaq demekdir.",
  ["yaratmaq", "silmək", "satmaq", "gizlətmək"], 1, 2),
 ("«Patent» nə ucun alinir?", "Patent ixtiranin huququnu qorumaq ucundur.",
  ["ixtiranın hüququnu qorumaq üçün", "malı satmaq üçün",
   "kitab çap etmək üçün", "səyahət etmək üçün"], 1, 2),
 ("«Science fair» nədir?", "Science fair sagirdlerin ixtiralarini gostərdiyi tedbirdir.",
  ["şagird ixtiralarının nümayişi", "idman yarışı",
   "musiqi konserti", "kitab bazarı"], 1, 2),
 ("«Fail» feilinin mənası nədir?", "Fail ugursuz olmaq demekdir.",
  ["uğursuz olmaq", "qalib gəlmək", "kəşf etmək",
   "yaratmaq"], 1, 2),
 ("«Try again» ifadəsi nəyə çağırır?",
  "Yenidən cehd etmeye cagirir.",
  ["yenidən cəhd etməyə", "dayanmağa", "unutmağa",
   "satmağa"], 1, 2),
 ("«How does it work?» sualı nəyi soruşur?",
  "Bu, cihazin neçe işlədiyini sorusur.",
  ["Cihaz necə işləyir", "Cihaz nə qədərdir",
   "Cihaz haradan alınıb", "Cihaz kimindir"], 1, 2),
 ("«as...as» qurulusu nə ucun islenir?",
  "Iki sey berabər müqayisə edilende.",
  ["iki şeyi bərabər müqayisə etmək üçün",
   "yalnız keçmişi danışmaq üçün", "sual qurmaq üçün",
   "əmr vermək üçün"], 1, 2),
 ("«This robot is as fast as that one.» cumlesi neyi bildirir?",
  "Iki robotun sureti berabərdir.",
  ["İki robotun sürəti bərabərdir", "Birinci daha sürətlidir",
   "İkinci daha sürətlidir", "Heç biri sürətli deyil"], 1, 3),
 ("«This invention is not as useful as that one.» ne demekdir?",
  "Ikinci ixtira daha faydalidir.",
  ["İkinci ixtira daha faydalıdır", "Birinci daha faydalıdır",
   "İkisi eyni faydalıdır", "Heç biri faydalı deyil"], 1, 3),
 ("«as + sifət + as» quruluşunda sifət hansı formada olur?",
  "Sifət DƏYİŞMƏDƏN, sadə formada qalır.",
  ["dəyişmədən, sadə formada", "üstünlük dərəcəsində",
   "keçmiş zamanda", "cəm formasında"], 1, 3),
 ("«The new phone is as expensive as the old one.» ne demekdir?",
  "Ikisinin qiymeti eynidir.",
  ["Qiymətləri eynidir", "Yeni telefon daha bahadır",
   "Köhnə telefon daha bahadır", "Heç biri baha deyil"], 1, 3),
 ("«not as...as» hansı menani verir?",
  "Birinci ikinciden AZ olan bir keyfiyyeti bildirir.",
  ["birinci ikincidən azdır", "birinci ikincidən çoxdur",
   "ikisi bərabərdir", "müqayisə yoxdur"], 1, 3),
 ("«She is not as tall as her brother.» — kim daha hündürdür?",
  "Qardaşı daha hundurdur.",
  ["Qardaşı", "Bacısı", "İkisi eyni boyda", "Heç biri"], 1, 3),
 ("«twice as big as» ifadəsi nəyi bildirir?",
  "Iki defe boyuk demekdir.",
  ["iki dəfə böyük", "iki dəfə kiçik", "yarısı qədər",
   "eyni ölçüdə"], 1, 3),
 ("«This machine works as well as a human.» ne demekdir?",
  "Masin insan qeder yaxsi isleyir.",
  ["Maşın insan qədər yaxşı işləyir",
   "Maşın insandan pis işləyir", "İnsan işləmir",
   "Maşın işləmir"], 1, 3),
 ("«Cars are produced in big factories.» cumlesi hansı novdedir?",
  "Bu, Məchul (Passive) novdur.",
  ["Məchul növ (Passive)", "Məlum növ (Active)",
   "Sual cümləsi", "Əmr cümləsi"], 1, 3),
 ("«The wheel was one of the first inventions.» — bu, hansı zamandadır?",
  "Kecmis zaman (Past Simple).",
  ["Keçmiş zaman", "İndiki zaman", "Gələcək zaman",
   "Present Perfect"], 1, 3),
 ("«This gadget is as light as a feather.» ifadəsi nəyi vurğulayır?",
  "Cihazin cox yungul olmasini.",
  ["cihaz çox yüngüldür", "cihaz çox ağırdır",
   "cihaz bahadır", "cihaz köhnədir"], 1, 3),
 ("«young inventors» ifadəsi kimləri bildirir?",
  "Gənc yasda ixtira eden sagirdleri.",
  ["gənc yaşda ixtira edənləri", "yaşlı alimləri",
   "müəllimləri", "jurnalistləri"], 1, 1),
 ("«Modern technology» ifadəsinin mənası nədir?",
  "Muasir texnologiya demekdir.",
  ["müasir texnologiya", "köhnə alət", "əl işi", "kitab"], 1, 1),
 ("«The new engine is as powerful as the old one, but smaller.» —"
  " hansı xüsusiyyət EYNİDİR?", "Guc (powerful) eynidir.",
  ["güc", "ölçü", "qiymət", "rəng"], 1, 3),
],

# ==================== LESSON 3: used to ================================
"ing-8-hobbies": [
 ("«Collector» kimdir?", "Collector kolleksiya toplayan sexsdir.",
  ["kolleksiya toplayan şəxs", "rəssam", "idmançı",
   "müəllim"], 1, 1),
 ("«Hiking» hobbisi harada keçirilir?",
  "Hiking tebiette, daglarda kecirilir.",
  ["dağlarda, təbiətdə", "evdə", "hovuzda", "kitabxanada"], 1, 1),
 ("«Chess» hansı oyundur?", "Chess ağıl oyunudur.",
  ["ağıl oyunu", "top oyunu", "musiqi aləti", "rəqs"], 1, 1),
 ("«Painting» məşğuliyyəti nədir?", "Painting rengkeşlikdir.",
  ["rəngkarlıq", "üzgüçülük", "oxuma", "yazı"], 1, 1),
 ("«Baking» məşğuliyyəti nə ilə bağlıdır?",
  "Baking corek/tort bisirmekle baglidir.",
  ["çörək və tort bişirmə", "bağçılıq", "tikiş", "musiqi"], 1, 1),
 ("«Photography» hansı məşğuliyyətdir?",
  "Photography sekil cekmedir.",
  ["şəkil çəkmə", "rəqs", "üzgüçülük", "yazı"], 1, 1),
 ("«Knitting» nə deməkdir?", "Knitting toxuculuqdur.",
  ["toxuculuq", "boyama", "üzgüçülük", "avtomobil sürmə"], 1, 1),
 ("«Gardening» məşğuliyyəti nədir?", "Gardening bagcilikdir.",
  ["bağçılıq", "aşpazlıq", "musiqi", "idman"], 1, 1),
 ("«Membership» sozunun mənası nədir?", "Membership uzvluk demekdir.",
  ["üzvlük", "bilet", "oyun", "növbə"], 1, 2),
 ("«Board games» hansı oyunlardır?",
  "Board games masa oyunlaridir.",
  ["masa üzərində oynanan oyunlar", "top oyunları",
   "su idmanı", "musiqi oyunları"], 1, 2),
 ("«Outdoor hobbies» hansı hobbilərdir?",
  "Acıq havada edilen hobbiler.",
  ["açıq havada edilən", "evdə edilən", "gecə edilən",
   "yalnız qışda edilən"], 1, 2),
 ("«Spare time» ifadəsinin mənası nədir?",
  "Spare time bos vaxt demekdir.",
  ["boş vaxt", "iş vaxtı", "dərs vaxtı", "yuxu vaxtı"], 1, 2),
 ("«Give up a hobby» nə deməkdir?",
  "Bir hobbidən imtina etmek demekdir.",
  ["hobbidən imtina etmək", "hobbiyə başlamaq",
   "hobbini öyrətmək", "hobbini satmaq"], 1, 2),
 ("«Take up a hobby» ifadəsi nə deməkdir?",
  "Yeni bir hobbiye başlamaq demekdir.",
  ["yeni hobbiyə başlamaq", "hobbini tərk etmək",
   "hobbini unutmaq", "hobbini satmaq"], 1, 2),
 ("«Handmade» sozunun mənası nədir?", "Handmade el ile hazirlanmis demekdir.",
  ["əllə hazırlanmış", "maşınla hazırlanmış", "köhnə",
   "bahalı"], 1, 2),
 ("«Join a club» ifadəsi nə deməkdir?",
  "Bir kluba uzv olmaq demekdir.",
  ["kluba üzv olmaq", "klubu bağlamaq", "klubu satmaq",
   "klubdan çıxmaq"], 1, 2),
 ("«used to» quruluşu nə ucun islenir?",
  "Kecmisde tekrarlanan, indi davam etmeyen aliskanliqlar ucun.",
  ["keçmişdə davam edən, indi bitmiş adətlər üçün",
   "hazırkı hərəkət üçün", "gələcək plan üçün",
   "əmr vermək üçün"], 1, 2),
 ("«I used to play chess every day.» cumlesi neyi bildirir?",
  "Kecmisde her gun sahmat oynayirdi, indi oynamir.",
  ["Keçmişdə hər gün oynayırdı, indi oynamır",
   "İndi də hər gün oynayır", "Heç vaxt oynamayıb",
   "Gələcəkdə oynayacaq"], 1, 3),
 ("«used to» sozunden sonra fel hansı formada gelir?",
  "Fel sadə (infinitive) formada gelir: used to play.",
  ["sadə forma (infinitive)", "-ing forması",
   "keçmiş zaman forması", "III forma"], 1, 3),
 ("«She did not use to like painting.» — bu cumle hansı formadadir?",
  "Bu, «used to»-nun inkar formasidir.",
  ["inkar forması", "təsdiq forması", "sual forması",
   "əmr forması"], 1, 3),
 ("«Did you use to collect stamps?» — bu, hansı formadir?",
  "Bu, sual formasidir.",
  ["sual forması", "təsdiq forması", "inkar forması",
   "keçmiş sadə forma"], 1, 3),
 ("«We used to go hiking every summer.» — indi bu vezziyet davam edirmi?",
  "Yox, bu, keçmişdə qalan aliskanlikdir.",
  ["Yox, artıq davam etmir", "Bəli, indi də davam edir",
   "Gələcəkdə başlayacaq", "Heç vaxt olmayıb"], 1, 3),
 ("«My grandfather used to be a great collector.» ne demekdir?",
  "Babasi kecmisde boyuk kolleksiyaci olub, indi deyil (ve ya artiq bele deyil).",
  ["Keçmişdə böyük kolleksiyaçı olub", "İndi kolleksiyaçıdır",
   "Heç vaxt kolleksiyaçı olmayıb", "Gələcəkdə kolleksiyaçı olacaq"], 1, 3),
 ("«I am fond ___ drawing.» boşluğunu doldurun.",
  "«Fond of» birleşməsi düzgündür.", ["of", "in", "at", "on"], 1, 2),
 ("«Be interested in» ifadəsindən sonra feil hansı formada işlənir?",
  "-ing formasinda: interested in drawing.",
  ["-ing forması", "infinitiv", "keçmiş zaman", "III forma"], 1, 2),
 ("«I enjoy ___ books.» boşluğunu doldurun.",
  "«Enjoy»-dan sonra -ing gelir.",
  ["reading", "read", "to read", "reads"], 1, 2),
 ("«Origami» sənəti haradan yaranıb?",
  "Origami Yaponiyadan yaranib.",
  ["Yaponiyadan", "Fransadan", "Çindən", "İtaliyadan"], 1, 1),
 ("«Pottery» nə deməkdir?", "Pottery saxsi qab hazirlamaqdir.",
  ["saxsı qab hazırlamaq", "rəqs", "musiqi", "yazı"], 1, 1),
 ("«Hobbies around the world» ifadəsi nə deməkdir?",
  "Dunyanin muxtelif olkelerindeki hobbiler.",
  ["dünyanın müxtəlif ölkələrindəki hobbilər",
   "yalnız bir ölkənin hobbisi", "yalnız idman hobbiləri",
   "yalnız musiqi hobbiləri"], 1, 1),
 ("«Do you ___ swimming?» boşluğuna hansı feil uyğundur?",
  "«Enjoy/like» kimi fellerdən sonra -ing gelir.",
  ["enjoy", "enjoys", "enjoyed", "to enjoy"], 1, 2),
],

# ==================== LESSON 4: Past Progressive =======================
"ing-8-real-heroes": [
 ("«Hero» sozunun mənası nədir?", "Hero qehreman demekdir.",
  ["qəhrəman", "düşmən", "yad adam", "qonşu"], 1, 1),
 ("«Brave» sifetinin mənası nədir?", "Brave cesur demekdir.",
  ["cəsur", "qorxaq", "yorğun", "sakit"], 1, 1),
 ("«Rescue» feili nə deməkdir?", "Rescue xilas etmek demekdir.",
  ["xilas etmək", "itirmək", "gizlətmək", "satmaq"], 1, 1),
 ("«Firefighter» kimdir?", "Firefighter yanğınsöndürəndir.",
  ["yanğınsöndürən", "həkim", "müəllim", "sürücü"], 1, 1),
 ("«Danger» sozunun mənası nədir?", "Danger tehluke demekdir.",
  ["təhlükə", "təhlükəsizlik", "sevinc", "sakitlik"], 1, 1),
 ("«Emergency» sozunun mənası nədir?", "Emergency fovqeladə hal demekdir.",
  ["fövqəladə hal", "adi gün", "bayram", "istirahət"], 1, 1),
 ("«Sacrifice» feili nə deməkdir?", "Sacrifice fedakarliq etmek demekdir.",
  ["fədakarlıq etmək", "qazanmaq", "gülmək", "yatmaq"], 1, 1),
 ("«Ordinary person» ifadəsi kimi bildirir?",
  "Adi, xüsusi olmayan insani bildirir.",
  ["adi insanı", "məşhur insanı", "alimi", "sərkərdəni"], 1, 1),
 ("Past Progressive (Past Continuous) hansı köməkçi fellə qurulur?",
  "was/were + -ing.", ["was/were", "have/has", "do/does",
  "will"], 1, 2),
 ("«I was reading a book at 8 p.m.» cumlesi neyi bildirir?",
  "Kecmisde konkret bir anda davam eden herəkəti.",
  ["keçmişdə konkret anda davam edən hərəkəti",
   "hazırkı hərəkəti", "gələcək planı", "tez-tez olan hərəkəti"], 1, 3),
 ("«They were helping people when the fire started.» — hansi herəkət EVVEL bashladi?",
  "Komek etme herəkəti evvel baslamisdi.",
  ["Kömək etmə", "Yanğının başlaması", "İkisi eyni vaxtda",
   "Heç biri"], 1, 3),
 ("«was» hansı əvəzliklərlə işlənir?",
  "I/he/she/it ile.", ["I, he, she, it", "you, we, they",
  "yalnız I", "yalnız they"], 1, 2),
 ("«were» hansı əvəzliklərlə işlənir?",
  "You/we/they ile.", ["you, we, they", "I, he, she, it",
  "yalnız he", "yalnız it"], 1, 2),
 ("«The hero was running towards the burning house.» cümləsində fel"
  " hansı formadadır?", "was + -ing (running).",
  ["was + -ing", "sadə keçmiş", "will + fel",
   "have + III forma"], 1, 2),
 ("Past Progressive əsasən nə ucun istifadə olunur?",
  "Kecmisde muəyyən bir anda davam eden herəkəti gostərmek ucun.",
  ["keçmişdə davam edən hərəkəti göstərmək",
   "gələcək niyyəti bildirmək", "adətləri bildirmək",
   "ümumi həqiqətləri bildirmək"], 1, 2),
 ("«While she was helping the child, her phone rang.» — hansı hərəkət"
  " DAHA UZUN davam edirdi?", "Komek etme herəkəti daha uzun idi.",
  ["Uşağa kömək etmə", "Telefonun zəng çalması",
   "İkisi eyni uzunluqda", "Heç biri"], 1, 3),
 ("«He was carrying the injured man to safety.» ne demekdir?",
  "O, yaralini tehlukesiz yere dashiyirdi (proses davam edirdi).",
  ["Yaralını təhlükəsiz yerə daşıyırdı",
   "Yaralını unutmuşdu", "Yaralıya baxmadı",
   "Yaralını axtarırdı"], 1, 3),
 ("«were saving» ifadəsi hansı zamana aiddir?",
  "Kecmisde davam eden zamana.",
  ["keçmişdə davam edən zamana", "indiki zamana",
   "gələcək zamana", "Present Perfect-ə"], 1, 2),
 ("«The children were playing when the storm began.» — storm haciseden"
  " NECə vaxt bas verdi?", "Ushaqlar oynayarken bas verdi.",
  ["uşaqlar oynayarkən", "uşaqlar yatarkən",
   "uşaqlar oxuyarkən", "uşaqlar yeyərkən"], 1, 3),
 ("Past Progressive-in inkar forması necə qurulur?",
  "was/were + not + -ing.",
  ["was/were not + -ing", "did not + fel",
   "have not + III forma", "will not + fel"], 1, 3),
 ("«She was not sleeping when the alarm rang.» ne demekdir?",
  "O, zeng caldiqda oyaq idi.",
  ["O, zəng çaldıqda oyaq idi", "O, zəng çaldıqda yatırdı",
   "O, zəngi eşitmədi", "O, evdə deyildi"], 1, 3),
 ("«Real heroes» ifadəsi kimi bildirir?",
  "Hecikat hayatda cesarətli is goren insanlari.",
  ["cəsarətlə kömək edən adi insanları", "yalnız kino"
   " qəhrəmanlarını", "yalnız idmançıları", "yalnız həkimləri"], 1, 1),
 ("«He risked his life to save the dog.» cumlesi neyi bildirir?",
  "O, iti xilas etmek ucun heyatini teхlukeye atdi.",
  ["Həyatını təhlükəyə atdı", "İtdən qorxdu",
   "İti unutdu", "İtə baxmadı"], 1, 2),
 ("«Courage» sozunun mənası nədir?", "Courage cesaret demekdir.",
  ["cəsarət", "qorxu", "yorğunluq", "laqeydlik"], 1, 1),
 ("«She was calling for help when I arrived.» — men geldiyimde o ne edirdi?",
  "Komek ucun cagirirdi.",
  ["Kömək üçün çağırırdı", "Yatırdı", "Yeyirdi",
   "Gülürdü"], 1, 3),
 ("«Volunteer» kimdir?", "Volunteer könüllü işləyən şəxsdir.",
  ["könüllü işləyən şəxs", "işəgötürən", "alim",
   "aktyor"], 1, 1),
 ("«They were working all night to rescue the survivors.» ne demekdir?",
  "Xilasetme işi bütün gecə davam etdi.",
  ["Xilasetmə bütün gecə davam etdi",
   "Xilasetmə bir dəqiqə çəkdi", "Heç kim işləmədi",
   "Sabah işlədilər"], 1, 3),
 ("Past Progressive sualı necə qurulur?",
  "Was/Were + subject + -ing?",
  ["Was/Were + subject + -ing?", "Did + subject + fel?",
   "Have + subject + III forma?", "Will + subject + fel?"], 1, 3),
 ("«What were you doing at 9 p.m. last night?» sualı nəyi soruşur?",
  "Kecen gece saat 9-da ne etdiyini sorusur.",
  ["Keçən gecə saat 9-da nə etdiyini",
   "Sabah nə edəcəyini", "Hər gün nə etdiyini",
   "Heç vaxt nə etmədiyini"], 1, 3),
 ("«Witness» kimdir?", "Witness hadiseni goren shexsdir.",
  ["hadisəni görən şəxs", "hadisəni törədən şəxs",
   "hadisədən xəbərsiz şəxs", "hadisəni unudan şəxs"], 1, 1),
],

# ==================== LESSON 5: Past Progressive Negative ==============
"ing-8-choose-kind": [
 ("«Kind» sifetinin mənası nədir?", "Kind meherbandir.",
  ["mehriban", "qəzəbli", "tənbəl", "acgöz"], 1, 1),
 ("«Bully» feili nə deməkdir?", "Bully zorakiliq etmek demekdir.",
  ["zorakılıq etmək", "kömək etmək", "gülmək",
   "oxumaq"], 1, 1),
 ("«Support» feili nə deməkdir?", "Support desteklemek demekdir.",
  ["dəstəkləmək", "qorxutmaq", "unutmaq", "satmaq"], 1, 1),
 ("«Generous» sifetinin mənası nədir?", "Generous səхavetlidir.",
  ["səxavətli", "xəsis", "tənbəl", "acgöz"], 1, 1),
 ("«Comfort» feili nə deməkdir?", "Comfort tesəlli vermek demekdir.",
  ["təsəlli vermək", "qorxutmaq", "cəzalandırmaq",
   "aldatmaq"], 1, 1),
 ("«Selfish» sifetinin mənası nədir?", "Selfish özündən başqasını düşünməyəndir.",
  ["özündən başqasını düşünməyən", "səxavətli",
   "mehriban", "sadiq"], 1, 1),
 ("«Encourage» feili nə deməkdir?", "Encourage ruhlandirmaq demekdir.",
  ["ruhlandırmaq", "qorxutmaq", "cəzalandırmaq",
   "aldatmaq"], 1, 1),
 ("«Be polite to others» ifadəsi nə deməkdir?",
  "Baskalarina qarsi nezaketli olmaq.",
  ["başqalarına nəzakətli olmaq", "başqalarını unutmaq",
   "başqalarını qorxutmaq", "başqalarını aldatmaq"], 1, 1),
 ("Past Progressive inkarında hansı söz istifadə olunur?",
  "not sozu: was/were not.",
  ["not", "no", "never", "none"], 1, 2),
 ("«I was not laughing at him.» cümləsi hansı formadadır?",
  "Bu, Past Progressive-in inkar formasidir.",
  ["Past Progressive inkar", "Past Progressive təsdiq",
   "Past Simple inkar", "Present Perfect inkar"], 1, 2),
 ("«She was not listening when he asked for help.» ne demekdir?",
  "O, komek istediyi anda diqqet etmirdi.",
  ["Kömək istədiyi an diqqət etmirdi",
   "Kömək istədiyi an diqqət edirdi",
   "Heç nə eşitmədi", "Kömək istəmədi"], 1, 3),
 ("«They were not helping the new student.» — nə etmirdilər?",
  "Yeni sagirde komek etmirdiler.",
  ["Yeni şagirdə kömək etmirdilər",
   "Yeni şagirdi tanımırdılar", "Yeni şagirdi gözləyirdilər",
   "Yeni şagirdi axtarırdılar"], 1, 3),
 ("«was not» qısaldılmış (kısa) formada necə yazılır?",
  "wasn not — apostrofsuz yazsaq: was not.",
  ["was not (qısaldılmadan)", "was no", "was never",
   "was none"], 1, 2),
 ("«He was not crying, he was just tired.» cumlesinde nə inkar edilir?",
  "Aglamasi inkar edilir.",
  ["ağlaması", "yorğunluğu", "gülməsi", "danışması"], 1, 2),
 ("«We were not fighting, we were just talking loudly.» ne demekdir?",
  "Onlar dava etmirdiler, sadəcə ucadan danisirdilar.",
  ["Dava etmirdilər, ucadan danışırdılar",
   "Dava edirdilər", "Susurdular", "Yatırdılar"], 1, 3),
 ("«I was not being unkind, I was just honest.» cümləsi nəyi izah edir?",
  "Danışan pis niyyət güdmədiyini izah edir.",
  ["pis niyyət güdmədiyini", "yalan danışdığını",
   "qəzəbləndiyini", "qorxduğunu"], 1, 3),
 ("«She was not paying attention to his feelings.» ne demekdir?",
  "O, onun hisslerine diqqet etmirdi.",
  ["Onun hisslərinə diqqət etmirdi",
   "Onun hisslərinə diqqət edirdi", "Onu tanımırdı",
   "Onunla danışmırdı"], 1, 3),
 ("«They were not being kind to the new boy.» — kime qarsi meherban"
  " deyildiler?", "Yeni oglana qarsi.",
  ["yeni oğlana", "müəllimə", "valideynlərinə",
   "qonşularına"], 1, 3),
 ("«Choose to be kind» ifadəsi nə cagirir?",
  "Meherban olmagi secmeyə cagirir.",
  ["mehriban olmağı seçməyə", "sərt olmağa",
   "susmağa", "qaçmağa"], 1, 1),
 ("«Show empathy» ifadəsi nə deməkdir?",
  "Baskasinin hissini anlamaq demekdir.",
  ["başqasının hissini anlamaq", "başqasını qorxutmaq",
   "başqasına gülmək", "başqasını unutmaq"], 1, 2),
 ("«He was not laughing at her mistake, he was helping her.» — nə etmirdi?",
  "Onun sehvine gulmurdu.",
  ["Onun səhvinə gülmürdü", "Ona kömək etmirdi",
   "Onu dinləmirdi", "Onu tanımırdı"], 1, 3),
 ("«We were not ignoring you.» sozu nəyi inkar edir?",
  "Baskasini gormezden gelmedikleri inkar edilir.",
  ["görməzdən gəlməni", "kömək etməni", "gülməni",
   "dinləməni"], 1, 3),
 ("«Respect» sozunun mənası nədir?", "Respect hormet demekdir.",
  ["hörmət", "qəzəb", "qısqanclıq", "laqeydlik"], 1, 1),
 ("«Forgive» feili nə deməkdir?", "Forgive baginshlamaq demekdir.",
  ["bağışlamaq", "unutmaq", "qorxutmaq", "cəzalandırmaq"], 1, 1),
 ("«She was not blaming him, she was trying to understand.» ne demekdir?",
  "O, onu ittiham etmirdi, anlamaga calisirdi.",
  ["İttiham etmirdi, anlamağa çalışırdı",
   "İttiham edirdi", "Ona kömək etmirdi", "Onu tanımırdı"], 1, 3),
 ("«Loneliness» sozunun mənası nədir?", "Loneliness tenhaliq demekdir.",
  ["tənhalıq", "sevinc", "hörmət", "cəsarət"], 1, 1),
 ("«Include everyone» ifadəsi nə deməkdir?",
  "Herkesi daxil etmek, kimseni kenarda qoymamaq.",
  ["hər kəsi daxil etmək", "yalnız dostları dəvət etmək",
   "kiminləsə danışmamaq", "yalnız özünü düşünmək"], 1, 2),
 ("«He was not sharing his lunch before, but now he does.» — kecmisde"
  " ne etmirdi?", "Naharini paylashmirdi.",
  ["nahar payını paylaşmırdı", "nahar yemirdi",
   "nahar bişirmirdi", "nahar almırdı"], 1, 3),
 ("«Kindness» sozunun mənası nədir?", "Kindness meherbanliq demekdir.",
  ["mehribanlıq", "qəzəb", "tənbəllik", "qısqanclıq"], 1, 1),
 ("«We were not judging him, we were listening.» ne demekdir?",
  "Onu mühakimə etmirdilər, qulaq asirdilar.",
  ["Mühakimə etmirdilər, qulaq asırdılar",
   "Mühakimə edirdilər", "Onu dinləmirdilər",
   "Ona kömək etmirdilər"], 1, 3),
],

# ==================== LESSON 6: Past Progressive Questions =============
"ing-8-travel-stories": [
 ("«Journey» sozunun mənası nədir?", "Journey seyahet demekdir.",
  ["səyahət", "otel", "bilet", "xəritə"], 1, 1),
 ("«Adventure» sozunun mənası nədir?", "Adventure macera demekdir.",
  ["macəra", "yorğunluq", "narahatlıq", "sakitlik"], 1, 1),
 ("«Get lost» ifadəsi nə deməkdir?", "Get lost azmaq demekdir.",
  ["azmaq (yolu itirmək)", "tapmaq", "gəlmək",
   "qayıtmaq"], 1, 1),
 ("«Backpack» sozunun mənası nədir?", "Backpack bel cantasidir.",
  ["bel çantası", "bilet", "xəritə", "pasport"], 1, 1),
 ("«Guide» kimdir?", "Guide beledci demekdir.",
  ["bələdçi", "sürücü", "aşpaz", "müəllim"], 1, 1),
 ("«Unexpected» sifetinin mənası nədir?", "Unexpected gozlenilmeyen demekdir.",
  ["gözlənilməyən", "gözlənilən", "adi", "planlaşdırılmış"], 1, 1),
 ("«Wander» feili nə deməkdir?", "Wander meqsedsiz gezmek demekdir.",
  ["məqsədsiz gəzmək", "qaçmaq", "yatmaq", "oxumaq"], 1, 1),
 ("«Souvenir shop» adətən harada yerləşir?",
  "Turistik yerlərin yaxınlığında.",
  ["turistik yerlərin yaxınlığında", "kənddə",
   "meşədə", "dəniz altında"], 1, 1),
 ("Past Progressive sualı necə düzəlir?",
  "Was/Were + subject + -ing + ?",
  ["Was/Were + subject + -ing?", "Did + subject + fel?",
   "Do/Does + subject + fel?", "Has/Have + subject + III forma?"], 1, 2),
 ("«What were you doing when you got lost?» sualına hansı cavab uygundur?",
  "«I was looking at the map.» kimi bir cavab uygundur.",
  ["I was looking at the map.", "I look at the map every day.",
   "I will look at the map.", "I have looked at the map."], 1, 2),
 ("«Where were they going when the storm started?» sualı nəyi soruşur?",
  "Firtina bashladiqda haraya getdiklerini sorusur.",
  ["Fırtına başlayanda haraya gedirdilər",
   "Fırtına nə vaxt bitdi", "Onlar hara getmək istəyir",
   "Onlar niyə getmədilər"], 1, 3),
 ("«Was she travelling alone?» sualının qısa cavabı necə olur?",
  "Yes, she was. / No, she was not.",
  ["Yes, she was.", "Yes, she does.", "Yes, she has.",
   "Yes, she is."], 1, 3),
 ("«Were you enjoying the trip?» sualında hansı əvəzlik istifadə olunub?",
  "You əvəzliyi.", ["you", "he", "it", "I"], 1, 2),
 ("«What was happening when you arrived?» sualı hansı zamana aiddir?",
  "Kecmisde davam eden zamana.",
  ["keçmişdə davam edən zamana", "indiki zamana",
   "gələcək zamana", "Present Perfect-ə"], 1, 2),
 ("«Were the tourists taking photos when the guide spoke?» — turistler"
  " ne edirdi?", "Sekil cekirdiler.",
  ["şəkil çəkirdilər", "yatırdılar", "yeyirdilər",
   "oxuyurdular"], 1, 3),
 ("«Who was waiting at the station?» sualında sual sozu kimə aiddir?",
  "Kim, ozel sexse aiddir.",
  ["şəxsə (kim)", "yerə (harada)", "vaxta (nə vaxt)",
   "səbəbə (niyə)"], 1, 2),
 ("«Why were you walking so fast?» sualı nəyi soruşur?",
  "Niye tez yeriyirdiler sualini sorusur.",
  ["niyə tez yeriyirdilər", "haraya gedirdilər",
   "nə vaxt getdilər", "kiminlə getdilər"], 1, 3),
 ("«Was it raining during your trip?» sualının mövzusu nədir?",
  "Seyahet zamani yagishin olub-olmadigi.",
  ["səyahət zamanı yağış", "səyahətin qiyməti",
   "səyahətin müddəti", "səyahət yeri"], 1, 2),
 ("«How were you feeling when you got lost?» sualı nəyi soruşur?",
  "Azdiqda ozunu nece hiss etdiyini sorusur.",
  ["azanda özünü necə hiss etdiyini",
   "azmadan əvvəl nə etdiyini", "hara getdiyini",
   "kiminlə olduğunu"], 1, 3),
 ("«Local guide» ifadəsi kimi bildirir?",
  "Yerli beledci demekdir.",
  ["yerli bələdçini", "əcnəbi turisti", "otel işçisini",
   "aviaşirkət işçisini"], 1, 2),
 ("«Were they staying at a hotel or a campsite?» sualı hansı seçim"
  " haqqındadır?", "Otel ve düşərgə arasindaki secim haqqinda.",
  ["otel ya düşərgə", "təyyarə ya qatar", "yay ya qış",
   "dəniz ya dağ"], 1, 3),
 ("«Amazing view» ifadəsi nəyi bildirir?",
  "Amazing view heyretamiz manzara demekdir.",
  ["heyrətamiz mənzərə", "sıxıcı mənzərə",
   "kiçik otaq", "boş sahə"], 1, 1),
 ("«Were you travelling by train or by bus?» sualında hansı"
  " nəqliyyat vasitələri müqayisə olunur?",
  "Qatar ve avtobus.", ["qatar və avtobus", "təyyarə və gəmi",
  "velosiped və avtomobil", "at və araba"], 1, 2),
 ("«What were the locals doing when you arrived?» sualı nəyi soruşur?",
  "Geldikde yerlilerin ne etdiyini sorusur.",
  ["gələndə yerlilərin nə etdiyini",
   "yerlilərin harada yaşadığını", "yerlilərin dilini",
   "yerlilərin sayını"], 1, 3),
 ("«Memorable trip» ifadəsi necə bir seyahəti bildirir?",
  "Yaddaqalan seyahet.",
  ["yaddaqalan səyahəti", "qısa səyahəti", "ucuz səyahəti",
   "təhlükəli səyahəti"], 1, 1),
 ("«Were you and your friends exploring the old town?» sualında"
  " «you and your friends» hansı əvəzliklə əvəz olunur?",
  "You (ve ya we).", ["you", "he", "it", "I"], 1, 2),
 ("«Explore» feili nə deməkdir?", "Explore kesf etmek/gezmek demekdir.",
  ["kəşf etmək, gəzmək", "satmaq", "unutmaq",
   "gizlətmək"], 1, 1),
 ("«Was the weather changing quickly during the trip?» — nə haqqında"
  " sual verilir?", "Havanin tez deyisib-deyismediyi haqqinda.",
  ["havanın tez dəyişməsi haqqında",
   "yolun uzunluğu haqqında", "otelin adı haqqında",
   "biletin qiyməti haqqında"], 1, 3),
 ("«Set off» ifadəsi nə deməkdir?",
  "Set off yola cixmaq demekdir.",
  ["yola çıxmaq", "geri qayıtmaq", "dayanmaq",
   "yatmaq"], 1, 2),
 ("«Were you taking notes during the journey?» sualının mövzusu nədir?",
  "Seyahet zamani qeydler goturub-goturmediyi.",
  ["səyahət zamanı qeyd götürmə", "səyahətin qiyməti",
   "səyahətin başlanğıcı", "səyahətin sonu"], 1, 3),
],

# ==================== LESSON 7: Past Simple and Past Progressive =======
"ing-8-celebrations": [
 ("«Celebration» sozunun mənası nədir?", "Celebration bayram/qeyd demekdir.",
  ["bayram, qeyd etmə", "iş günü", "yorğunluq",
   "səyahət"], 1, 1),
 ("«Festival» sozunun mənası nədir?", "Festival festival demekdir.",
  ["festival", "sınaq", "dərs", "iclas"], 1, 1),
 ("«Decorate» feili nə deməkdir?", "Decorate bezemek demekdir.",
  ["bəzəmək", "sındırmaq", "təmizləmək", "gizlətmək"], 1, 1),
 ("«Gathering» sozunun mənası nədir?", "Gathering yigincaq demekdir.",
  ["yığıncaq", "yarış", "imtahan", "səfər"], 1, 1),
 ("«Tradition» sozunun mənası nədir?", "Tradition ənənə demekdir.",
  ["ənənə", "qanun", "xəbər", "elan"], 1, 1),
 ("«Firework» sozunun mənası nədir?", "Firework fişəngdir.",
  ["fişəng", "şam", "hədiyyə", "bayraq"], 1, 1),
 ("«Guest» sozunun mənası nədir?", "Guest qonaq demekdir.",
  ["qonaq", "ev sahibi", "satıcı", "sürücü"], 1, 1),
 ("«Invite» feili nə deməkdir?", "Invite dəvət etmek demekdir.",
  ["dəvət etmək", "unutmaq", "cəzalandırmaq",
   "qorxutmaq"], 1, 1),
 ("Past Simple hansı bitmiş, konkret hərəkəti bildirir?",
  "Kecmisde bir defelik bitmiş hərəkəti.",
  ["keçmişdə bir dəfəlik bitmiş hərəkəti",
   "davam edən hərəkəti", "adət olan hərəkəti",
   "gələcək hərəkəti"], 1, 2),
 ("«While we were decorating the hall, the guests arrived.» — hansı"
  " hərəkət DAHA UZUN idi?", "Bezemek herekəti daha uzun idi.",
  ["bəzəmə hərəkəti", "qonaqların gəlməsi",
   "ikisi eyni uzunluqda", "heç biri"], 1, 3),
 ("«When the music started, we were dancing.» cümləsi nəyi bildirir?",
  "Musiqi baslayanda onlar artiq rəqs edirdi.",
  ["Musiqi başlayanda artıq rəqs edirdilər",
   "Musiqi başlayandan sonra rəqsə başladılar",
   "Rəqs etmədilər", "Musiqi heç başlamadı"], 1, 3),
 ("Past Simple + Past Progressive birlikdə işlənəndə adətən hansı"
  " söz istifadə olunur?",
  "«while» ve ya «when».", ["while / when", "will / shall",
  "if / unless", "since / for"], 1, 2),
 ("«She was singing when the lights went out.» — hansı hərəkət"
  " QƏFLƏTƏN bas verdi?", "İşiqlərin sönməsi qeflten bas verdi.",
  ["işıqların sönməsi", "mahnı oxuma", "ikisi də qəflətən",
   "heç biri"], 1, 3),
 ("«We were preparing the food when he called.» — telefon zeng"
  " calanda ne edirdiler?", "Yemek hazirlayirdilar.",
  ["yemək hazırlayırdılar", "yemək yeyirdilər",
   "yatırdılar", "danışırdılar"], 1, 3),
 ("«When» sozu adeten hansı zamanla islenir?",
  "Qisa, birdefelik herekətle (Past Simple).",
  ["qısa, bir dəfəlik hərəkətlə", "yalnız Past Progressive-lə",
   "yalnız gələcək zamanla", "yalnız indiki zamanla"], 1, 2),
 ("«while» sozu adeten hansı zamanla islenir?",
  "Davam eden herekətle (Past Progressive).",
  ["davam edən hərəkətlə", "yalnız Past Simple-lə",
   "yalnız gələcək zamanla", "yalnız indiki zamanla"], 1, 2),
 ("«They arrived while we were still cooking.» cümləsi nəyi bildirir?",
  "Onlar geldikde yemek hazirligi hele davam edirdi.",
  ["Onlar gələndə hazırlıq hələ davam edirdi",
   "Yemək artıq hazır idi", "Onlar heç gəlmədi",
   "Yemək bişirilmirdi"], 1, 3),
 ("«I was getting ready when the guests knocked on the door.» ne"
  " demekdir?", "Qonaqlar qapini doyende hele hazirlashirdi.",
  ["Qapı döyüləndə hələ hazırlaşırdı",
   "Artıq hazır idi", "Qapını açmadı", "Yatırdı"], 1, 3),
 ("«Anniversary» sozunun mənası nədir?", "Anniversary ildönümüdür.",
  ["ildönümü", "növbə", "sınaq", "dərs"], 1, 1),
 ("«Last year we celebrated the New Year at home.» — bu hansı"
  " zamandadır?", "Past Simple.", ["Past Simple",
  "Past Progressive", "Present Perfect", "Future Simple"], 1, 2),
 ("«We were singing songs all evening at the party.» cümləsinin"
  " vurgu etdiyi nədir?", "Herekətin uzun muddet davam etmesi.",
  ["hərəkətin uzun müddət davam etməsi",
   "hərəkətin bir dəfə olması", "hərəkətin bitməsi",
   "hərəkətin heç olmaması"], 1, 3),
 ("«Ceremony» sozunun mənası nədir?", "Ceremony merasim demekdir.",
  ["mərasim", "iş günü", "sınaq", "yarış"], 1, 1),
 ("«Congratulate» feili nə deməkdir?",
  "Congratulate tebrik etmek demekdir.",
  ["təbrik etmək", "cəzalandırmaq", "unutmaq",
   "qorxutmaq"], 1, 1),
 ("«As we were leaving, the fireworks began.» — hansı hərəkət"
  " EVVEL bashladi?", "Getmek herekəti evvel baslamisdi.",
  ["getmə hərəkəti", "fişənglərin başlaması",
   "ikisi eyni vaxtda", "heç biri"], 1, 3),
 ("«National holiday» ifadəsi nə deməkdir?",
  "Milli beynelxalq bayram.", ["milli bayram",
  "adi iş günü", "şəxsi tədbir", "məktəb imtahanı"], 1, 1),
 ("«They were celebrating loudly when the neighbours complained.» —"
  " qonshular ne etdi?", "Sikayet etdiler.",
  ["şikayət etdilər", "qoşuldular", "yatdılar",
   "getdilər"], 1, 3),
 ("«Custom» sözünün mənası nədir?", "Custom adet demekdir.",
  ["adət", "qanun", "sınaq", "elan"], 1, 1),
 ("«We had a big dinner and then we opened the presents.» — bu, hansı"
  " zamana aiddir?", "Past Simple (ardicil herekətler).",
  ["Past Simple", "Past Progressive", "Present Simple",
   "Future Simple"], 1, 2),
 ("«While the band was playing, everyone was dancing.» — iki herekət"
  " arasindaki elaqe nədir?", "Ikisi de eyni anda davam edirdi.",
  ["ikisi eyni anda davam edirdi",
   "biri digərindən əvvəl bitdi", "heç biri baş vermədi",
   "ikisi ardıcıl baş verdi"], 1, 3),
 ("«Reunion» sozunun mənası nədir?", "Reunion yeniden bir araya gelme demekdir.",
  ["yenidən bir araya gəlmə", "ayrılıq", "sükut",
   "yarış"], 1, 1),
],

# ==================== LESSON 8: can, could, be able to =================
"ing-8-art": [
 ("«Artist» kimdir?", "Artist rəssamdır.",
  ["rəssam", "həkim", "sürücü", "aşpaz"], 1, 1),
 ("«Sculpture» sozunun mənası nədir?", "Sculpture heykeltəraşlıqdır.",
  ["heykəl", "rəsm", "musiqi", "kitab"], 1, 1),
 ("«Exhibition» sozunun mənası nədir?", "Exhibition sərgi demekdir.",
  ["sərgi", "imtahan", "dərs", "yarış"], 1, 1),
 ("«Paintbrush» sozunun mənası nədir?", "Paintbrush firca demekdir.",
  ["fırça", "qələm", "kağız", "kətan"], 1, 1),
 ("«Canvas» sozunun mənası nədir?", "Canvas rəsm cekilen parcadir.",
  ["rəsm çəkilən parça", "boya", "fırça", "çərçivə"], 1, 1),
 ("«Talented» sifetinin mənası nədir?", "Talented istedadli demekdir.",
  ["istedadlı", "istedadsız", "tənbəl", "yorğun"], 1, 1),
 ("«Sketch» feili nə deməkdir?", "Sketch qaralama cekmek demekdir.",
  ["qaralama (eskiz) çəkmək", "silmək", "boyamaq",
   "sındırmaq"], 1, 1),
 ("«Masterpiece» sozunun mənası nədir?", "Masterpiece sah eser demekdir.",
  ["şah əsər", "adi rəsm", "eskiz", "köhnə kağız"], 1, 1),
 ("«can» sozu esasen nə ucun istifadə olunur?",
  "Bacariq ve ya icaze bildirmek ucun.",
  ["bacarıq və ya icazə bildirmək üçün",
   "yalnız keçmiş hərəkət üçün", "yalnız gələcək üçün",
   "əmr vermək üçün"], 1, 2),
 ("«could» sozu esasen hansı zamanda bacariq bildirir?",
  "Kecmis zamanda.", ["keçmiş zamanda", "hazırkı zamanda",
  "gələcək zamanda", "hər zamanda eyni"], 1, 2),
 ("«be able to» ifadəsi hansı zamanlarda «can»-i əvəz edə bilir?",
  "Butun zamanlarda (kecmis, indiki, gələcək).",
  ["bütün zamanlarda", "yalnız keçmişdə",
   "yalnız gələcəkdə", "heç bir zamanda"], 1, 3),
 ("«She can paint beautifully.» cümləsi nəyi bildirir?",
  "Onun rəsm cekmek bacarigini.",
  ["onun rəsm çəkmək bacarığını", "onun rəsmi sevmədiyini",
   "onun rəsm çəkə bilmədiyini", "onun rəssam olmadığını"], 1, 2),
 ("«He could draw very well when he was young.» cümləsi nəyi bildirir?",
  "Kecmisde (cavan ikən) yaxsi cekə bilirdi.",
  ["keçmişdə yaxşı çəkə bilirdi",
   "indi yaxşı çəkir", "heç vaxt çəkə bilməyib",
   "gələcəkdə çəkəcək"], 1, 3),
 ("«will be able to» hansı zamana aiddir?",
  "Gələcək zamana.", ["gələcək zamana", "keçmiş zamana",
  "hazırkı zamana", "hər zamana"], 1, 3),
 ("«can» modal felindən sonra əsas fel hansı formada gəlir?",
  "Sade (infinitiv) formada, «to» olmadan.",
  ["sadə forma, «to» olmadan", "-ing forması",
   "III forma", "«to» ilə infinitiv"], 1, 2),
 ("«Could you paint when you were five?» sualının cavabı necə"
  " olur?", "Yes, I could. / No, I could not.",
  ["Yes, I could.", "Yes, I can.", "Yes, I am able.",
   "Yes, I will."], 1, 3),
 ("«I was not able to finish the painting in time.» ne demekdir?",
  "Resmi vaxtinda bitire bilmedi.",
  ["Rəsmi vaxtında bitirə bilmədi",
   "Rəsmi vaxtında bitirdi", "Rəsmi heç başlamadı",
   "Rəsmi sildi"], 1, 3),
 ("«can not» (cannot) hansı mənanı verir?",
  "Bacarmamaq ve ya icaze olmama.",
  ["bacarmamaq / icazə olmaması", "bacarmaq",
   "keçmiş bacarıq", "gələcək bacarıq"], 1, 2),
 ("«Sculptor» kimdir?", "Sculptor heykeltəraşdır.",
  ["heykəltəraş", "rəssam (rəsm çəkən)", "musiqiçi",
   "yazıçı"], 1, 1),
 ("«He can not draw as well as his sister.» cümləsi nəyi bildirir?",
  "Bacisi ondan yaxsi cekir.",
  ["Bacısı ondan yaxşı çəkir", "O, bacısından yaxşı çəkir",
   "İkisi eyni çəkir", "Heç biri çəkə bilmir"], 1, 3),
 ("«Portrait» sozunun mənası nədir?", "Portrait portret demekdir.",
  ["portret", "mənzərə", "heykəl", "eskiz"], 1, 1),
 ("«Was able to» hansı hərəkəti bildirir?",
  "Kecmisde konkret bir defe bacarmagi.",
  ["keçmişdə konkret bir dəfə bacarmağı",
   "keçmişdə ümumi bacarığı", "gələcək bacarığı",
   "hazırkı bacarığı"], 1, 3),
 ("«Creative» sifetinin mənası nədir?", "Creative yaradici demekdir.",
  ["yaradıcı", "tənbəl", "yorğun", "acgöz"], 1, 1),
 ("«I could not find my paintbrush this morning.» ne demekdir?",
  "Fircasini tapa bilmedi.",
  ["Fırçasını tapa bilmədi", "Fırçasını tapdı",
   "Fırçasını satdı", "Fırçası yox idi"], 1, 3),
 ("«Gallery» sozunun mənası nədir?", "Gallery qalereya demekdir.",
  ["qalereya", "kitabxana", "muzey deyil, dükan",
   "məktəb"], 1, 1),
 ("«She will be able to exhibit her art next year.» — bu, hansı"
  " zamana aiddir?", "Gələcək zamana.",
  ["gələcək zamana", "keçmiş zamana", "hazırkı zamana",
   "hər zamana"], 1, 3),
 ("«Inspire» feili nə deməkdir?", "Inspire ilhamlandirmaq demekdir.",
  ["ilhamlandırmaq", "qorxutmaq", "cəzalandırmaq",
   "unutmaq"], 1, 1),
 ("«Could» sozunun mənfi (inkar) forması necədir?",
  "could not.", ["could not", "can no", "not could",
  "could non"], 1, 2),
 ("«He is able to mix colours perfectly.» cümləsi nəyi bildirir?",
  "Rengleri mukemmel qarisdirmaq bacarigini.",
  ["rəngləri mükəmməl qarışdırmaq bacarığını",
   "rəngləri sevmədiyini", "rəngləri qarışdıra bilmədiyini",
   "rənglərin adını bilmədiyini"], 1, 2),
 ("«Original artwork» ifadəsi nə deməkdir?",
  "Original artwork ozgun eser demekdir.",
  ["özgün əsər", "surət", "köhnə şəkil", "boş kətan"], 1, 2),
],

# ==================== LESSON 9: must / have to / do not have to =======
"ing-8-environment": [
 ("«Throw rubbish in the bin» nə tələb edir?",
  "Zibili zibil qutusuna atmagi teleb edir.",
  ["zibili qutuya atmaq", "zibili yerə atmaq",
   "zibili yandırmaq", "zibili gizlətmək"], 1, 1),
 ("«Plant trees» nə deməkdir?", "Plant trees agac ekmek demekdir.",
  ["ağac əkmək", "ağac kəsmək", "ağacı satmaq",
   "ağacı yandırmaq"], 1, 1),
 ("«Solar energy» hansı mənbədən alınır?",
  "Gunesden alinir.", ["günəşdən", "kömürdən", "neftdən",
  "sudan"], 1, 1),
 ("«Environment» sozunun mənası nədir?", "Environment etraf muhit demekdir.",
  ["ətraf mühit", "hava limanı", "bazar", "məktəb"], 1, 1),
 ("«Pollution» nə deməkdir?", "Pollution cirklenme demekdir.",
  ["çirklənmə", "təmizlik", "sağlamlıq", "sülh"], 1, 1),
 ("«Recycle» feilinin mənası nədir?", "Recycle tekrar emal etmek demekdir.",
  ["təkrar emal etmək", "yandırmaq", "atmaq", "gizlətmək"], 1, 1),
 ("«Global warming» nədir?", "Qlobal istilesme demekdir.",
  ["planetin qızması", "planetin soyuması",
   "havanın təmizlənməsi", "suyun donması"], 1, 1),
 ("«Endangered animals» hansı heyvanlardır?",
  "Nesli kesilme tehlukesi olan heyvanlar.",
  ["nəsli kəsilmə təhlükəsi olan heyvanlar",
   "ev heyvanları", "vəhşi quşlar", "dəniz balıqları"], 1, 1),
 ("«must» modal felindən sonra əsas fel hansı formada gəlir?",
  "Sade (infinitiv) formada, «to» olmadan.",
  ["sadə forma, «to» olmadan", "-ing forması",
   "III forma", "«to» ilə infinitiv"], 1, 2),
 ("«must» ve «have to» arasindaki fərq nədir?",
  "Must — daxili zerurət, have to — xarici qayda/tələb.",
  ["must daxili, have to xarici tələbdir",
   "heç bir fərq yoxdur", "have to yalnız keçmiş üçündür",
   "must yalnız suallarda işlənir"], 1, 3),
 ("«We must protect the rainforest.» cümləsi nəyi bildirir?",
  "Bu, guclu zerurət bildirir.",
  ["güclü zərurəti", "seçim olduğunu", "icazəni",
   "keçmiş adəti"], 1, 2),
 ("«You have to recycle plastic in this city.» cümləsi nəyi bildirir?",
  "Bu, sehərin qaydasi (xarici qaydadan gələn tələb).",
  ["şəhərin qaydasından gələn tələbi",
   "danışanın öz istəyini", "keçmiş vərdişi",
   "gələcək niyyəti"], 1, 3),
 ("«do not have to» ifadəsi nəyi bildirir?",
  "Zerurət olmadigini (mecburiyyet yoxdur).",
  ["zərurət olmadığını", "qadağa olduğunu",
   "güclü tövsiyəni", "keçmiş öhdəliyi"], 1, 3),
 ("«You do not have to buy a new bag, you can reuse an old one.»"
  " cümləsi nəyi bildirir?", "Yeni canta almaq mecburi deyil.",
  ["Yeni çanta almaq məcburi deyil",
   "Yeni çanta almaq qadağandır", "Köhnə çantanı atmaq lazımdır",
   "Heç bir çantaya ehtiyac yoxdur"], 1, 3),
 ("«must not» hansı mənanı verir?",
  "Qadaga (gorulmemesi lazim olan).",
  ["qadağanı", "zərurət olmadığını", "icazəni",
   "tövsiyəni"], 1, 3),
 ("«You must not litter in the park.» cümləsi nə deməkdir?",
  "Parkda zibil atmaq QADAGANDIR.",
  ["Parkda zibil atmaq qadağandır",
   "Parkda zibil atmaq məcburi deyil",
   "Parkda oturmaq qadağandır", "Parka girmək qadağandır"], 1, 3),
 ("«has to» hansı əvəzliklərlə işlənir?",
  "he/she/it ile.", ["he, she, it", "I, you, we, they",
  "yalnız I", "yalnız they"], 1, 2),
 ("«She has to save water at home.» cümləsindəki tələb hardan gəlir?",
  "Xarici qayda ve ya zerurətdən (mes. valideyn qaydasi).",
  ["xarici tələbdən (məsələn qayda)",
   "onun öz istəyindən", "keçmiş vərdişindən",
   "təsadüfdən"], 1, 3),
 ("«Reduce, reuse, recycle» şüarı nəyə aiddir?",
  "Tullantini azaltmaga aiddir.",
  ["tullantını azaltmağa", "enerji istehsalına",
   "meşə salmağa", "suyun təmizlənməsinə"], 1, 2),
 ("«Eco-friendly» sözünün mənası nədir?",
  "Eco-friendly ətraf muhite zerersiz demekdir.",
  ["ətraf mühitə zərərsiz", "ətraf mühitə zərərli",
   "bahalı", "köhnə"], 1, 2),
 ("«Ozone layer» planeti nədən qoruyur?",
  "Zerərli gunes suasindan.",
  ["zərərli günəş şüalarından", "yağışdan",
   "küləkdən", "soyuqdan"], 1, 2),
 ("«Deforestation» nə deməkdir?",
  "Meşə sahesinin azalmasi (qırılması).",
  ["meşələrin qırılması", "meşələrin salınması",
   "heyvanların qorunması", "suyun təmizlənməsi"], 1, 2),
 ("«Clean energy» hansı enerjidir?",
  "Cirklenme yaratmayan enerji.",
  ["çirklənmə yaratmayan enerji", "kömürdən alınan enerji",
   "neftdən alınan enerji", "bahalı enerji"], 1, 2),
 ("«Nature reserve» nədir?",
  "Tebietin qorundugu xususi erazi.",
  ["təbiətin qorunduğu ərazi", "sənaye zonası",
   "şəhər mərkəzi", "hərbi baza"], 1, 2),
 ("«Climate change» ifadəsinin mənası nədir?",
  "İqlim deyisikliyi demekdir.",
  ["iqlim dəyişikliyi", "hava proqnozu", "fəsil",
   "gündüz-gecə fərqi"], 1, 2),
 ("«We do not have to switch off every light, but we should try.»"
  " — bu, hansı münasibəti bildirir?",
  "Guclu tövsiyə, amma mecburiyyet yoxdur.",
  ["güclü tövsiyə, məcburiyyət yoxdur",
   "ciddi qadağa", "mütləq zərurət", "keçmiş öhdəlik"], 1, 3),
 ("«Volunteer to clean the beach» ifadəsi nə deməkdir?",
  "Sahili könüllü temizlemek.",
  ["sahili könüllü təmizləmək", "sahili satmaq",
   "sahildə istirahət etmək", "sahili bağlamaq"], 1, 2),
 ("«You must recycle the bottles here — it is the law.» cümləsindəki"
  " «must» hansı gücü ifadə edir?",
  "Qanuni mecburiyyeti.", ["qanuni məcburiyyəti",
  "şəxsi seçimi", "keçmiş vərdişi", "sadə tövsiyəni"], 1, 3),
 ("«Waste less water» çağırışı nəyə aiddir?",
  "Su israfini azaltmaga.",
  ["su israfını azaltmağa", "su içməyə",
   "hovuz tikməyə", "suyu satmağa"], 1, 2),
 ("«Take care of nature» ifadəsi nəyə çağırır?",
  "Tebiete qayğı gostərilmesine.",
  ["təbiətə qayğı göstərilməsinə", "təbiətdən uzaq durmağa",
   "təbiəti satmağa", "təbiəti unutmağa"], 1, 2),
],

# ==================== LESSON 10: Zero Conditional =======================
"ing-8-people-life": [
 ("«Relationship» sozunun mənası nədir?", "Relationship elaqə/munasibet demekdir.",
  ["münasibət", "sərhəd", "sınaq", "elan"], 1, 1),
 ("«Trust» feili nə deməkdir?", "Trust etibar etmek demekdir.",
  ["etibar etmək", "şübhələnmək", "qorxutmaq",
   "aldatmaq"], 1, 1),
 ("«Neighbour» kimdir?", "Neighbour qonşudur.",
  ["qonşu", "qohum", "müəllim", "həkim"], 1, 1),
 ("«Loyal» sifetinin mənası nədir?", "Loyal sadiq demekdir.",
  ["sadiq", "xəyanətkar", "tənbəl", "acgöz"], 1, 1),
 ("«Support each other» ifadəsi nə deməkdir?",
  "Bir-birine destek olmaq.",
  ["bir-birinə dəstək olmaq", "bir-birini unutmaq",
   "bir-birindən qaçmaq", "bir-birini qorxutmaq"], 1, 1),
 ("«Argue» feili nə deməkdir?", "Argue mubahise etmek demekdir.",
  ["mübahisə etmək", "razılaşmaq", "gülmək",
   "kömək etmək"], 1, 1),
 ("«Get along with» ifadəsi nə deməkdir?",
  "Kimlese yaxshi münasibətdə olmaq.",
  ["kiminləsə yaxşı münasibətdə olmaq",
   "kiminləsə mübahisə etmək", "kiminləsə tanış olmamaq",
   "kimisə unutmaq"], 1, 2),
 ("«Close friend» ifadəsi kimi bildirir?",
  "Yaxin dost demekdir.",
  ["yaxın dostu", "yad adamı", "qonşunu", "müəllimi"], 1, 1),
 ("Zero Conditional hansı cümlə strukturu ilə qurulur?",
  "If + Present Simple, Present Simple.",
  ["If + Present Simple, Present Simple",
   "If + Present Simple, will + fel",
   "If + Past Simple, would + fel",
   "If + Present Perfect, Present Simple"], 1, 2),
 ("Zero Conditional əsasən nəyi ifadə edir?",
  "Həmişə dogru olan umumi hequqetleri.",
  ["həmişə doğru olan ümumi həqiqətləri",
   "yalnız gələcək planları", "yalnız keçmiş hadisələri",
   "şəxsi arzuları"], 1, 2),
 ("«If you are kind to people, they trust you.» cümləsi nəyi bildirir?",
  "Umumi, hemişə dogru olan bir qaydani.",
  ["ümumi, həmişə doğru olan qaydanı",
   "yalnız bir dəfə baş verən hadisəni",
   "keçmişdə baş vermiş hadisəni",
   "şərti mümkün olmayan hadisəni"], 1, 3),
 ("«If we argue too much, our friendship suffers.» — bu cümlə hansı"
  " əlaqəni bildirir?", "Sebeb-neticə elaqesini.",
  ["səbəb-nəticə əlaqəsini", "zaman ardıcıllığını",
   "müqayisəni", "təəccübü"], 1, 3),
 ("Zero Conditional-da «if» əvəzinə hansı söz işlənə bilər, mənası"
  " dəyişmədən?", "«when» sozu.",
  ["when", "unless", "although", "because"], 1, 3),
 ("«If people do not communicate, misunderstandings happen.» —"
  " bu, hansı zamanda qurulub?",
  "Her ikisi de Present Simple-dedir.",
  ["hər iki hissə Present Simple-dədir",
   "birinci Past, ikinci Present", "hər ikisi Future-dədir",
   "hər ikisi Present Perfect-dədir"], 1, 3),
 ("«If you listen carefully, you understand people better.» cümləsinin"
  " mənası nədir?", "Qulaq asmaq insanlari basha dushmeye komek edir (umumi qayda).",
  ["diqqətlə qulaq asmaq anlamağa kömək edir",
   "qulaq asmaq faydasızdır", "insanlar heç vaxt anlaşılmır",
   "qulaq asmaq yalnız keçmişdə faydalı idi"], 1, 3),
 ("«Honesty» sozunun mənası nədir?", "Honesty dogruculluq demekdir.",
  ["doğruçuluq", "yalançılıq", "qısqanclıq", "yorğunluq"], 1, 1),
 ("«If two people respect each other, their relationship grows"
  " stronger.» — «if» şərti ödənəndə nə baş verir?",
  "Elaqe daha guclu olur.",
  ["əlaqə daha güclü olur", "əlaqə zəifləyir",
   "heç nə dəyişmir", "əlaqə bitir"], 1, 3),
 ("«Misunderstanding» sozunun mənası nədir?", "Misunderstanding yanlish anlama demekdir.",
  ["yanlış anlama", "düzgün anlama", "sükut",
   "razılıq"], 1, 2),
 ("«Sibling» sozunun mənası nədir?", "Sibling bacı-qardaş demekdir.",
  ["bacı-qardaş", "valideyn", "qonşu", "dost"], 1, 1),
 ("«If children spend time with grandparents, they learn a lot.»"
  " — bu cümlə Zero Conditional-a niyə uygundur?",
  "Cunki hemişə dogru olan umumi bir gerceyi bildirir.",
  ["həmişə doğru olan ümumi gerçəyi bildirir",
   "yalnız bir dəfə baş verib", "gələcəkdə baş verəcək",
   "artıq baş vermiş"], 1, 3),
 ("«Get on well with somebody» ifadəsi nə deməkdir?",
  "Kimise ile yaxshi keçinmek.",
  ["kiminləsə yaxşı keçinmək", "kiminləsə mübahisə etmək",
   "kimisə tanımamaq", "kimidənsə qorxmaq"], 1, 2),
 ("«If you help others, you feel happier.» cümləsindəki əlaqə hansı"
  " novdur?", "Umumi sebeb-neticə (Zero Conditional).",
  ["ümumi səbəb-nəticə", "yalnız təsadüf",
   "keçmiş hadisə", "gələcək plan"], 1, 3),
 ("«Generation» sozunun mənası nədir?", "Generation nesil demekdir.",
  ["nəsil", "ailə", "qohum", "dost"], 1, 1),
 ("«Elderly people» ifadəsi kimi bildirir?",
  "Yashli insanlari.", ["yaşlı insanları", "uşaqları",
  "gəncləri", "yeniyetmələri"], 1, 1),
 ("«If we do not spend time together, we grow apart.» cümləsi nəyi"
  " bildirir?", "Vaxt kecirmeseler munasibet zeifleyir (umumi qayda).",
  ["vaxt keçirməsələr münasibət zəifləyir",
   "vaxt keçirməsələr münasibət güclənir",
   "münasibətə heç təsir etmir", "yalnız bir dəfə baş verib"], 1, 3),
 ("«Caring» sifetinin mənası nədir?", "Caring qayğıkeşdir.",
  ["qayğıkeş", "laqeyd", "qəzəbli", "acgöz"], 1, 1),
 ("«If a friend needs help, a real friend listens.» — bu, hansı"
  " ümumi qaydanı bildirir?", "Hequqi dostlugun ozunu.",
  ["həqiqi dostluğun mahiyyətini",
   "yalnız bir hadisəni", "keçmiş hadisəni",
   "mümkün olmayan şərti"], 1, 3),
 ("«Understanding» sifeti kimi bildirir?",
  "Baskasini anlayan sexs.", ["başqasını anlayan şəxsi",
  "başqasını qınayan şəxsi", "susan şəxsi",
  "unudan şəxsi"], 1, 1),
 ("«If you are honest with people, they respect you.» cümləsinin"
  " struktu hansıdır?", "If + Present Simple, Present Simple.",
  ["If + Present Simple, Present Simple",
   "If + Past Simple, would", "If + Present Perfect, will",
   "If + Future, Present"], 1, 2),
 ("«Bond» sozunun mənası nədir?", "Bond insanlar arasindaki baglilikdir.",
  ["insanlar arasındakı bağlılıq", "mübahisə",
   "yad münasibət", "unudulma"], 1, 1),
],

# ==================== LESSON 11: First Conditional ======================
"ing-8-modern-technology": [
 ("«Gadget» sozunun mənası nədir?", "Gadget kicik elektron cihazdir.",
  ["kiçik elektron cihaz", "kitab", "geyim", "oyuncaq"], 1, 1),
 ("«Screen» sozunun mənası nədir?", "Screen ekran demekdir.",
  ["ekran", "düymə", "kabel", "batareya"], 1, 1),
 ("«Application (app)» sozunun mənası nədir?",
  "Application telefon proqramidir.",
  ["telefon proqramı", "kompüter özü", "internet",
   "kabel"], 1, 1),
 ("«Download» feili nə deməkdir?", "Download yuklemek demekdir.",
  ["yükləmək (internetdən)", "silmək", "satmaq",
   "çap etmək"], 1, 1),
 ("«Charge a battery» ifadəsi nə deməkdir?",
  "Batareyani doldurmaq demekdir.",
  ["batareyanı doldurmaq", "batareyanı çıxarmaq",
   "batareyanı satmaq", "batareyanı atmaq"], 1, 1),
 ("«Connect to the internet» nə deməkdir?",
  "İnternete qoshulmaq demekdir.",
  ["internetə qoşulmaq", "internetdən ayrılmaq",
   "internet almaq", "internet satmaq"], 1, 1),
 ("«Artificial intelligence» ifadəsi nə deməkdir?",
  "Suni intellekt demekdir.",
  ["süni intellekt", "insan zəkası", "kompüter viru",
   "internet sürəti"], 1, 1),
 ("«Update software» ifadəsi nə deməkdir?",
  "Proqrami yenilemek demekdir.",
  ["proqramı yeniləmək", "proqramı silmək",
   "proqramı satmaq", "proqramı gizlətmək"], 1, 1),
 ("First Conditional hansı struktura görə qurulur?",
  "If + Present Simple, will + fel.",
  ["If + Present Simple, will + fel",
   "If + Present Simple, Present Simple",
   "If + Past Simple, would + fel",
   "If + Present Perfect, will"], 1, 2),
 ("First Conditional əsasən nəyi ifadə edir?",
  "Gələcəkdə real ve mümkün olan şərtli neticəni.",
  ["gələcəkdə real, mümkün olan nəticəni",
   "keçmişdə baş vermiş hadisəni",
   "həmişə doğru olan ümumi həqiqəti",
   "mümkün olmayan xəyali şərti"], 1, 3),
 ("«If you charge your phone tonight, it will work tomorrow.»"
  " cümləsi nəyi bildirir?", "Mumkun bir sertin real neticesini.",
  ["mümkün bir şərtin real nəticəsini",
   "keçmiş bir hadisəni", "ümumi bir həqiqəti",
   "qeyri-mümkün bir vəziyyəti"], 1, 3),
 ("«If technology develops too fast, people will lose some skills.»"
  " — bu cümlədə şərt bölməsi hansıdır?",
  "«If technology develops too fast» hissesi.",
  ["If technology develops too fast",
   "people will lose some skills", "hər iki hissə",
   "heç bir hissə"], 1, 3),
 ("First Conditional-da «if» bölməsində hansı zaman işlənir?",
  "Present Simple.", ["Present Simple", "Future Simple",
  "Past Simple", "Present Perfect"], 1, 2),
 ("First Conditional-da nəticə bölməsində əsasən hansı söz işlənir?",
  "will.", ["will", "would", "did", "has"], 1, 2),
 ("«If we do not protect our data, hackers will steal it.» cümləsi"
  " nəyi xəbərdar edir?", "Melumatlar qorunmasa oglanacagini.",
  ["məlumatların oğurlanacağını", "məlumatların qorunacağını",
   "hakerlərin olmadığını", "internetin bağlanacağını"], 1, 3),
 ("«will not» (won not — apostrofsuz «will not») hansı mənanı verir?",
  "Gələcəkde bir sey bash vermeyeceyini.",
  ["gələcəkdə baş verməyəcəyini", "keçmişdə baş vermədiyini",
   "indi baş vermədiyini", "hər zaman baş verdiyini"], 1, 2),
 ("«If you press this button, the screen will turn on.» — bu, hansı"
  " sahədə tez-tez işlənən nümunədir?", "Cihazlarin isledilme qaydalarinda.",
  ["cihazların işlədilmə qaydalarında",
   "tarixi hadisələrdə", "coğrafi məlumatda",
   "şəxsi hisslərdə"], 1, 2),
 ("«Virtual reality» ifadəsi nə deməkdir?",
  "Suni yaradilmish reallik.",
  ["süni yaradılmış (virtual) reallıq",
   "real dünya", "köhnə texnologiya",
   "kağız kitab"], 1, 2),
 ("«If robots do all the work, will people become lazy?» — bu,"
  " hansı cümlə növüdür?", "First Conditional-in sual formasidir.",
  ["First Conditional sual forması",
   "Zero Conditional təsdiq forması",
   "Past Simple sual forması", "Present Perfect sualı"], 1, 3),
 ("«Password» sozunun mənası nədir?", "Password parol demekdir.",
  ["parol", "istifadəçi adı", "kabel", "batareya"], 1, 1),
 ("«If she studies coding, she will become a programmer.» cümləsindəki"
  " nəticə hansı şərtdən asılıdır?", "Kodlaşdirmani oyrenmesinden.",
  ["kodlaşdırmanı öyrənməsindən",
   "yaşından", "adından", "boyundan"], 1, 3),
 ("«Upgrade» feili nə deməkdir?", "Upgrade yenilesdirmek demekdir.",
  ["yeniləşdirmək, təkmilləşdirmək",
   "köhnəltmək", "silmək", "satmaq"], 1, 2),
 ("«If the internet connection is slow, videos will not load"
  " quickly.» cümləsi nəyi izah edir?",
  "İnternet yavash oldugunda videonun geç yuklendiyini.",
  ["internet yavaş olanda video gec yüklənir",
   "internet yavaş olanda video sürətli yüklənir",
   "internetin sürəti videoya təsir etmir",
   "video heç yüklənmir"], 1, 3),
 ("«Hacker» kimdir?", "Hacker kompüter sistemlərinə icazəsiz daxil olan şəxsdir.",
  ["kompüterə icazəsiz daxil olan şəxs",
   "proqram yaradan şəxs", "kompüter satan şəxs",
   "kompüter təmirçisi"], 1, 1),
 ("«If people rely only on machines, they will forget basic skills.»"
  " — bu, hansı narahatlığı ifadə edir?",
  "Insanlarin bazi bacariqlari itirmesi narahatligini.",
  ["insanların bəzi bacarıqları itirmə narahatlığını",
   "maşınların insanlardan zəif olması narahatlığını",
   "internetin bahalaşması narahatlığını",
   "elektrikin bitməsi narahatlığını"], 1, 3),
 ("«Wireless» sozunun mənası nədir?", "Wireless kabelsiz demekdir.",
  ["kabelsiz", "kabelli", "batareyasız", "ekransız"], 1, 1),
 ("«If you save your work, you will not lose it.» — bu tövsiyə"
  " nə üçün verilir?", "Işin itirilmesinin qarşısını almaq üçün.",
  ["işin itirilməsinin qarşısını almaq üçün",
   "işi sürətləndirmək üçün", "işi çap etmək üçün",
   "işi silmək üçün"], 1, 3),
 ("«Smart device» ifadəsi nəyi bildirir?",
  "İnternete qoshula bilen, aglı cihaz.",
  ["internetə qoşula bilən ağıllı cihaz",
   "köhnə, sadə cihaz", "kağız sənəd",
   "əl işi alət"], 1, 2),
 ("«If technology keeps improving, our lives will become easier.»"
  " cümləsindəki ümumi mesaj nədir?", "Texnologiyanin heyati asanlashdirmasi umidi.",
  ["texnologiyanın həyatı asanlaşdırma ümidi",
   "texnologiyanın həyatı çətinləşdirməsi",
   "texnologiyanın dayanacağı", "texnologiyanın lazımsız olması"], 1, 3),
 ("«Notification» sozunun mənası nədir?", "Notification bildiris demekdir.",
  ["bildiriş", "parol", "kabel", "ekran"], 1, 1),
],

# ==================== LESSON 12: Reflexive Pronouns ======================
"ing-8-important-skills": [
 ("«Skill» sozunun mənası nədir?", "Skill baciriq demekdir.",
  ["bacarıq", "zəiflik", "səhv", "yorğunluq"], 1, 1),
 ("«Teamwork» sozunun mənası nədir?", "Teamwork komanda ishidir.",
  ["komanda işi", "tək iş", "istirahət",
   "yarış"], 1, 1),
 ("«Confidence» sozunun mənası nədir?", "Confidence oz-ozune inam demekdir.",
  ["özünə inam", "qorxu", "şübhə", "yorğunluq"], 1, 1),
 ("«Responsibility» sozunun mənası nədir?", "Responsibility mesuliyyet demekdir.",
  ["məsuliyyət", "istirahət", "əyləncə",
   "səhv"], 1, 1),
 ("«Time management» ifadəsi nə deməkdir?",
  "Vaxti duzgun idarə etmek.",
  ["vaxtı düzgün idarə etmək", "vaxtı itirmək",
   "vaxtı unutmaq", "vaxtı satmaq"], 1, 1),
 ("«Solve a problem» ifadəsi nə deməkdir?",
  "Problemi hell etmek.", ["problemi həll etmək",
  "problemi yaratmaq", "problemi gizlətmək",
  "problemi unutmaq"], 1, 1),
 ("«Leadership» sozunun mənası nədir?", "Leadership liderliq demekdir.",
  ["liderlik", "tabeçilik", "tənbəllik", "qorxaqlıq"], 1, 1),
 ("«Communication skills» ifadəsi nə deməkdir?",
  "Unsiyyet baciriqlari.", ["ünsiyyət bacarıqları",
  "riyazi bacarıqlar", "idman bacarıqları",
  "musiqi bacarıqları"], 1, 1),
 ("Reflexive (özlük) əvəzliklər nə üçün istifadə olunur?",
  "Herekətin ozune yönəldiyini bildirmek ucun.",
  ["hərəkətin özünə yönəldiyini bildirmək üçün",
   "sualı bildirmək üçün", "inkarı bildirmək üçün",
   "vaxtı bildirmək üçün"], 1, 2),
 ("«myself» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«I» evezliyine.", ["I", "you", "he", "they"], 1, 2),
 ("«himself» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«he» evezliyine.", ["he", "she", "I", "we"], 1, 2),
 ("«herself» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«she» evezliyine.", ["she", "he", "it", "you"], 1, 2),
 ("«itself» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«it» evezliyine.", ["it", "he", "she", "I"], 1, 2),
 ("«ourselves» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«we» evezliyine.", ["we", "I", "you (tək)", "he"], 1, 2),
 ("«yourselves» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«you» (cem) evezliyine.", ["you (cəm)", "I", "he",
  "she"], 1, 2),
 ("«themselves» hansı əvəzliyə aid özlük əvəzliyidir?",
  "«they» evezliyine.", ["they", "he", "she", "it"], 1, 2),
 ("«I taught myself how to solve problems.» cümləsi nəyi bildirir?",
  "Ozunu ozu oyretdi, komeksiz.",
  ["Özünü özü öyrətdi, köməksiz",
   "Başqası ona öyrətdi", "Heç nə öyrənmədi",
   "Öyrənməkdən imtina etdi"], 1, 3),
 ("«She organised the project herself.» cümləsindəki «herself»"
  " sözü nəyi vurğulayır?", "Basqasinin komeyi olmadan tek etdiyini vurğulayır.",
  ["başqasının köməyi olmadan tək etdiyini",
   "onun yorulduğunu", "onun səhv etdiyini",
   "onun kömək istədiyini"], 1, 3),
 ("«He believes in himself.» ifadəsi nəyi bildirir?",
  "Ozune inaminin oldugunu.",
  ["özünə inamı olduğunu", "özünə şübhə etdiyini",
   "başqasına inandığını", "qorxduğunu"], 1, 3),
 ("«They solved the problem by themselves.» ifadəsindəki «by"
  " themselves» nə deməkdir?", "Basqasinin komeyi olmadan.",
  ["başqasının köməyi olmadan", "başqası ilə birlikdə",
   "müəllimin köməyi ilə", "heç vaxt"], 1, 3),
 ("«Take responsibility for yourself» ifadəsi nə deməkdir?",
  "Oz emellerinin mesuliyyetini daşımaq.",
  ["öz əməllərinin məsuliyyətini daşımaq",
   "başqasını günahlandırmaq", "məsuliyyətdən qaçmaq",
   "başqasına güvənmək"], 1, 2),
 ("«Be proud of yourself» ifadəsi nə deməkdir?",
  "Ozu ile fexr etmek.", ["özü ilə fəxr etmək",
  "özündən utanmaq", "özünü unutmaq",
  "özünü tənqid etmək"], 1, 2),
 ("«Critical thinking» ifadəsi nə deməkdir?",
  "Tenqidi tefekkur, meselələri diqqetli tehlil etmek baciriqi.",
  ["tənqidi təfəkkür, diqqətli təhlil bacarığı",
   "sürətli qərar vermə", "yalnız yadda saxlama",
   "yalnız hesablama bacarığı"], 1, 2),
 ("«Adaptability» sozunun mənası nədir?",
  "Deyisikliklere uyğunlashma bacarigi.",
  ["dəyişikliklərə uyğunlaşma bacarığı",
   "dəyişiklikdən qorxma", "tənbəllik",
   "inadkarlıq"], 1, 2),
 ("«She hurt herself while practising sports.» cümləsi nəyi bildirir?",
  "Idmanla mesgul olarken ozunu yaraladi.",
  ["idmanla məşğul olarkən özünü yaraladı",
   "başqasını yaraladı", "heç nə olmadı",
   "idmanı tərk etdi"], 1, 3),
 ("«Cooperation» sozunun mənası nədir?", "Cooperation emekdashliq demekdir.",
  ["əməkdaşlıq", "rəqabət", "təklik", "səssizlik"], 1, 1),
 ("«We should always be honest with ourselves.» cümləsindəki"
  " «ourselves» sözü nəyə aiddir?", "«We» evezliyine.",
  ["We", "I", "they", "he"], 1, 2),
 ("«Problem-solving skill» hansı vəziyyətdə faydalıdır?",
  "Cetin bir veziyyetle qarshilashanda.",
  ["çətin bir vəziyyətlə qarşılaşanda",
   "yalnız imtahanda", "yalnız evdə",
   "heç vaxt lazım deyil"], 1, 2),
 ("«Motivate yourself» ifadəsi nə deməkdir?",
  "Ozunu ruhlandirmaq.", ["özünü ruhlandırmaq",
  "özünü qınamaq", "özünü unutmaq",
  "başqasını ruhlandırmaq"], 1, 2),
 ("«Important skills for teens» ifadəsi kimlər üçün faydalı"
  " bacarıqları bildirir?", "Yeniyetmeler ucun.",
  ["yeniyetmələr üçün", "yalnız valideynlər üçün",
   "yalnız müəllimlər üçün", "yalnız uşaqlar üçün"], 1, 1),
],
}


def yoxla():
    n = xeta = 0
    butun = set()
    for movzu, siyahi in SUALLAR.items():
        if len(siyahi) != 30:
            print("XETA  %s: %d sual (30 olmalidir)" % (movzu, len(siyahi)))
            xeta += 1
        for body, why, opts, correct, diff in siyahi:
            n += 1
            p = []
            if len(opts) != 4:
                p.append("variant sayi %d" % len(opts))
            if len(set(opts)) != len(opts):
                p.append("tekrar variant")
            if not (1 <= correct <= 4):
                p.append("correct")
            if not why:
                p.append("izah bos")
            if diff not in (1, 2, 3):
                p.append("cetinlik")
            if body in butun:
                p.append("eyni sual iki defe")
            butun.add(body)
            for t in [body, why] + opts:
                if "'" in t:
                    p.append("apostrof var: %r" % t)
            if p:
                xeta += 1
                print("XETA  %s: %s\n      %s"
                      % (movzu, body[:60], "; ".join(p)))
    print("%d sual yoxlandi, %d xeta" % (n, xeta))
    return xeta == 0, n


def q(s):
    assert "'" not in s, "apostrof: %s" % s
    return "'" + s.replace("%", "%%") + "'"


def sql_yaz(n):
    setirler = []
    for movzu, _ad, _sort in MOVZULAR:
        for i, (body, why, opts, correct, diff) in enumerate(SUALLAR[movzu], 1):
            setirler.append(
                "(%s,%s,%d,%d,%s,%s,%s,%s,%s,%s,%d)"
                % (q("ing8v2-%s#%d" % (movzu, i)), q(movzu), diff, 1,
                   q(body), q(why),
                   q(opts[0]), q(opts[1]), q(opts[2]), q(opts[3]), correct))
    restruktur = """\
-- ---------------------------------------------------------------------
--  I HISSƏ: movzu restrukturu (kitab 788-in 12 LESSON-una uygun)
--
--  4 movcud setir YENIDEN ISTIFADƏ olunur (id qalir):
--    ing-8-holidays        -> "Summer Holiday"      (Lesson 1, deyismir)
--    ing-8-inventions      -> "Young Inventors"      (Lesson 2, deyismir)
--    ing-8-hobbies         -> "Hobbies Around..."    (Lesson 3, deyismir)
--    ing-8-environment     -> "Help the Earth"       (Lesson 9, deyismir)
--    ing-8-present-perfect -> ing-8-real-heroes      (Lesson 4 - bu
--      kitabda "Present Perfect" YOXDUR, sətir Lesson 4-e kocurulur)
--    ing-8-media           -> ing-8-modern-technology (Lesson 11 - "Mass
--      Media" sualları kitabin heç bir konkret dersine aid deyildi)
--
--  6 YENI setir (kitabda olub, bazada olmayan LESSON-lar):
--    ing-8-real-heroes (4), ing-8-choose-kind (5), ing-8-travel-stories (6),
--    ing-8-celebrations (7), ing-8-art (8), ing-8-people-life (10),
--    ing-8-important-skills (12) - qeyd: real-heroes yuxarida movcud
--    setirin yeniden adlandirilmasi ile artiq var, qalan 6-si tam yenidir.
--
--  Kohne 180 sual (ing8-* ext_key) ARXIVLENIR (status='archived'),
--  SILINMIR - test_questions/attempt_answers kecmis nəticələri qoruyur
--  (bax CLAUDE.md: "sual bankı - qayda").  Suallarin topic_id-si də
--  yeni movzuya yonəldilir ki, arxiv movzunun tarixi ile uygun qalsin.
-- ---------------------------------------------------------------------
do $$
declare
  v_subj uuid;
  v_lvl  uuid;
  v_pp   uuid;
  v_media uuid;
begin
  select id into v_subj from public.subjects where slug = 'ingilis-dili';
  select l.id into v_lvl from public.levels l
    join public.programs p on p.id = l.program_id
   where l.code = '8' and p.slug = 'orta';

  if not exists (select 1 from public.topics
                  where subject_id = v_subj and slug = 'ing-8-present-perfect')
  then
    raise notice 'Ingilis 8 restruktur artiq isledilib, kecdim.';
    return;
  end if;

  update public.topics set name = 'Summer Holiday', sort = 10
   where subject_id = v_subj and slug = 'ing-8-holidays';
  update public.topics set name = 'Young Inventors', sort = 20
   where subject_id = v_subj and slug = 'ing-8-inventions';
  update public.topics set name = 'Hobbies Around the World', sort = 30
   where subject_id = v_subj and slug = 'ing-8-hobbies';
  update public.topics set name = 'Help the Earth', sort = 90
   where subject_id = v_subj and slug = 'ing-8-environment';

  update public.topics
     set slug = 'ing-8-real-heroes', name = 'Real Heroes', sort = 40
   where subject_id = v_subj and slug = 'ing-8-present-perfect'
  returning id into v_pp;

  update public.topics
     set slug = 'ing-8-modern-technology', name = 'Modern Technology',
         sort = 110
   where subject_id = v_subj and slug = 'ing-8-media'
  returning id into v_media;

  update public.questions set status = 'archived'
   where topic_id in (
     select id from public.topics
      where subject_id = v_subj
        and slug in ('ing-8-holidays', 'ing-8-inventions', 'ing-8-hobbies',
                      'ing-8-environment', 'ing-8-real-heroes',
                      'ing-8-modern-technology'))
     and ext_key like 'ing8-%';

  insert into public.topics (subject_id, level_id, slug, name, sort) values
    (v_subj, v_lvl, 'ing-8-choose-kind', 'Choose to Be Kind', 50),
    (v_subj, v_lvl, 'ing-8-travel-stories', 'Travel Stories', 60),
    (v_subj, v_lvl, 'ing-8-celebrations', 'Celebrations', 70),
    (v_subj, v_lvl, 'ing-8-art', 'Art', 80),
    (v_subj, v_lvl, 'ing-8-people-life', 'People in Our Life', 100),
    (v_subj, v_lvl, 'ing-8-important-skills', 'Important Skills for Teens', 120)
  on conflict (subject_id, slug) do nothing;

  raise notice 'Ingilis 8 restruktur olundu: 12 movzu (4 deyismedi, 2 '
               'kocuruldu, 6 yeni), kohne 180 sual arxivlendi.';
end $$;

"""
    with io.open(CIXIS, "w", encoding="utf-8") as f:
        f.write("""-- =====================================================================
--  99_bank_ingilis8_788.sql : INGILIS DILI 8 (kitab 788) - RESTRUKTUR + BANK
--
--  NIYE: kitab 824 ("esas xarici dil") bosdur (Cemi sehife: 0).  Kitab
--  788 ("ikinci xarici dil") isə doludur - 12 LESSON, hər birinin oz
--  qrammatika mövzusu var.  Kohne bank (6 mövzu) YALNIZ ADLA (Holidays/
--  Inventions/Hobbies) uygun idi - qrammatika sualları bu kitabda
--  ümumiyyetlə keçmeyen mövzuları (Present Perfect, Passive Voice) test
--  edirdi.  Butun 12 mövzu kitabin oz Lesson-larina ve qrammatikasina
--  uygun YENIDEN yazildi: 360 sual (12 x 30).
--
--  MENBE: e-derslik.edu.az kitab id 788 (mundericat/ingilis-dili-8-788.txt).
--
--  ELLE YAZILMIR: tools/ing8_788.py cixarir.
--
--  DIQQET
--   * Kohne 180 sual SILINMIR - status='archived' olur (CLAUDE.md
--     qaydasi: sual sətri silinmez, test_questions/attempt_answers
--     kecmis nəticələri qoruyur).
--   * Yeni suallarin ext_key-i "ing8v2-*" - kohne "ing8-*" ile
--     TOQQUSMUR.
--   * Tekrar isledile biler (on conflict do update / do nothing).
-- =====================================================================
set search_path = public, extensions;

%s
-- ---------------------------------------------------------------------
--  II HISSƏ: 360 yeni sual
-- ---------------------------------------------------------------------
delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and q.ext_key like 'ing8v2-%%';

with d(ext, topic, diff, quarter, body, why, o1, o2, o3, o4, correct) as (values
%s
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.quarter, 'published'
    from d
    join public.subjects s on s.slug = 'ingilis-dili'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '8'
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
  lateral unnest(array[d.o1, d.o2, d.o3, d.o4]) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where owner_type = 'platform' and ext_key like 'ing8v2-%%';
  if n <> %d then
    raise exception 'ingilis 8 (788) suallari: %d gozlenilirdi, %% tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'ing8v2-%%'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '%% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct t.id) into k from public.topics t
    join public.subjects s on s.id = t.subject_id and s.slug = 'ingilis-dili'
    join public.levels   l on l.id = t.level_id and l.code = '8'
   where t.parent_id is null;
  if k <> 12 then
    raise exception 'ingilis 8 ust movzu sayi 12 deyil: %%', k;
  end if;
  raise notice 'Ingilis dili 8 (kitab 788): %% sual, 12 movzu hazir.', n;
end $$;
""" % (restruktur, ",\n".join(setirler), n, n))
    print("yazildi: %s (%d sual)" % (CIXIS, n))


if __name__ == "__main__":
    ok, n = yoxla()
    if not ok:
        raise SystemExit(1)
    sql_yaz(n)
