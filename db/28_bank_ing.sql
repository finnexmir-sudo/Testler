-- =====================================================================
--  28_bank_ing.sql : INGILIS DILI 1-4 PLATFORMA SUAL BANKI
--
--  BU FAYL ELLE YAZILMIR - tools/ing.py yaradir:
--      python3 tools/ing.py
--
--  Her sinifde 6 movzu x 10 = 60;  4 sinif = 240 sual.
--  ext_key: ing<sinif>-<movzu>#<sira>.
--  ON SERT: 14_movzular.sql islenmis olmalidir (ing-* movzulari).
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where (s.slug, t.slug) in (('ingilis-dili','ing-1-alphabet'),
                                ('ingilis-dili','ing-4-reading'))
     having count(*) = 2) then
    raise exception 'ONCE 14_movzular.sql isledilmelidir (ing-* movzulari yoxdur).';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.owner_type = 'platform'
   and (q.ext_key like 'ing1-%' or q.ext_key like 'ing2-%'
        or q.ext_key like 'ing3-%' or q.ext_key like 'ing4-%');

with d(ext, sinif, topic, diff, rub, body, why, opts, correct) as (values
('ing1-alphabet#1','1','ing-1-alphabet',1,1,'İngilis əlifbasının ilk hərfi hansıdır?','İngilis əlifbası A hərfi ilə başlayır.',array['A','B','Z','C'],1),
('ing1-alphabet#2','1','ing-1-alphabet',1,1,'«B» hərfindən sonra hansı hərf gəlir?','Əlifbada B-dən sonra C gəlir.',array['C','D','A','E'],1),
('ing1-alphabet#3','1','ing-1-alphabet',1,1,'İngilis əlifbasının sonuncu hərfi hansıdır?','Əlifba Z hərfi ilə bitir.',array['Z','Y','X','W'],1),
('ing1-alphabet#4','1','ing-1-alphabet',1,1,'«Ball» sözü hansı hərflə başlayır?','Ball sözünün ilk hərfi B-dir.',array['B','D','P','L'],1),
('ing1-alphabet#5','1','ing-1-alphabet',2,1,'Böyük «D» hərfinin kiçik yazılışı hansıdır?','D hərfinin kiçik forması d-dir.',array['d','b','p','q'],1),
('ing1-alphabet#6','1','ing-1-alphabet',2,1,'Hansı söz «C» hərfi ilə başlayır?','Cat sözü C ilə başlayır.',array['cat','dog','egg','fish'],1),
('ing1-alphabet#7','1','ing-1-alphabet',2,1,'Hansı sırada hərflər əlifba ardıcıllığı ilə düzülüb?','Əlifba sırası: A, B, C.',array['A, B, C','B, A, C','C, B, A','A, C, B'],1),
('ing1-alphabet#8','1','ing-1-alphabet',2,1,'«E» hərfindən əvvəl hansı hərf gəlir?','Əlifbada E-dən əvvəl D gəlir.',array['D','F','C','G'],1),
('ing1-alphabet#9','1','ing-1-alphabet',1,1,'«Dog» sözündə neçə hərf var?','D-o-g: üç hərf.',array['3','2','4','5'],1),
('ing1-alphabet#10','1','ing-1-alphabet',2,1,'Kiçik «g» hərfinin böyük yazılışı hansıdır?','g hərfinin böyük forması G-dir.',array['G','Q','J','C'],1),
('ing1-greetings#1','1','ing-1-greetings',1,1,'Səhər görüşəndə ingiliscə nə deyilir?','Səhər salamı: Good morning.',array['Good morning','Good night','Goodbye','Sorry'],1),
('ing1-greetings#2','1','ing-1-greetings',1,1,'«Goodbye» nə deməkdir?','Goodbye — sağ ol, əlvida.',array['Əlvida (sağ ol)','Salam','Təşəkkür','Bağışla'],1),
('ing1-greetings#3','1','ing-1-greetings',1,1,'Gecə yatmağa gedəndə nə deyilir?','Yatmazdan əvvəl: Good night.',array['Good night','Good morning','Hello','Thanks'],1),
('ing1-greetings#4','1','ing-1-greetings',2,1,'«How are you?» sualına hansı cavab uyğundur?','Cavab: I am fine, thank you.',array['I am fine, thank you.','My name is Tural.','It is a cat.','Goodbye.'],1),
('ing1-greetings#5','1','ing-1-greetings',1,1,'«Hi» sözü nə bildirir?','Hi — dostlar arasında salamlaşmadır.',array['Salam','Əlvida','Gecən xeyrə','Ad'],1),
('ing1-greetings#6','1','ing-1-greetings',1,1,'Dostunla ayrılanda nə deyirsən?','Ayrılanda: Bye.',array['Bye','Hello','Good morning','Yes'],1),
('ing1-greetings#7','1','ing-1-greetings',2,1,'«Nice to meet you» nə vaxt deyilir?','Yeni tanış olanda deyilir.',array['Tanış olanda','Yatanda','Yemək yeyəndə','Qaçanda'],1),
('ing1-greetings#8','1','ing-1-greetings',2,1,'Özünü təqdim etmək üçün hansı cümlə işlənir?','Özünü təqdim etmə: I am Aysu.',array['I am Aysu.','It is a dog.','Bye-bye.','No, thanks.'],1),
('ing1-greetings#9','1','ing-1-greetings',2,1,'«Please» sözü nə üçün işlənir?','Please — xahiş bildirir (zəhmət olmasa).',array['Xahiş üçün','Salamlaşmaq üçün','Ayrılmaq üçün','Saymaq üçün'],1),
('ing1-greetings#10','1','ing-1-greetings',2,1,'«Sorry» nə deməkdir?','Sorry — bağışla, üzr istəyirəm.',array['Bağışla','Salam','Sağ ol','Bəli'],1),
('ing1-numbers#1','1','ing-1-numbers',1,2,'«One» hansı ədəddir?','One — 1 deməkdir.',array['1','2','10','0'],1),
('ing1-numbers#2','1','ing-1-numbers',1,2,'«Three» sözü hansı rəqəmi bildirir?','Three — 3 deməkdir.',array['3','8','13','2'],1),
('ing1-numbers#3','1','ing-1-numbers',1,2,'İngiliscə «beş» necə deyilir?','Beş — five.',array['five','four','nine','two'],1),
('ing1-numbers#4','1','ing-1-numbers',2,2,'Two + two = ? Cavabı ingiliscə deyin.','2 + 2 = 4 — four.',array['four','three','five','two'],1),
('ing1-numbers#5','1','ing-1-numbers',1,2,'«Seven» hansı ədəddir?','Seven — 7 deməkdir.',array['7','6','17','8'],1),
('ing1-numbers#6','1','ing-1-numbers',2,2,'Ardıcıllığı davam etdirin: one, two, three, …','Üçdən sonra dörd gəlir: four.',array['four','six','ten','one'],1),
('ing1-numbers#7','1','ing-1-numbers',1,2,'Doqquz ingiliscə necə deyilir?','Doqquz — nine.',array['nine','six','seven','ten'],1),
('ing1-numbers#8','1','ing-1-numbers',2,2,'«Six» və «eight» ədədlərindən hansı böyükdür?','Six = 6, eight = 8; 8 böyükdür.',array['eight','six','Bərabərdirlər','Bilmək olmaz'],1),
('ing1-numbers#9','1','ing-1-numbers',2,2,'Əllərimizdəki barmaqların sayı ingiliscə necə deyilir?','İki əldə 10 barmaq — ten.',array['ten','five','two','one'],1),
('ing1-numbers#10','1','ing-1-numbers',2,2,'«Zero» nə deməkdir?','Zero — sıfır.',array['Sıfır','On','Bir','Yüz'],1),
('ing1-colours#1','1','ing-1-colours',1,2,'«Red» hansı rəngdir?','Red — qırmızı.',array['Qırmızı','Göy','Yaşıl','Sarı'],1),
('ing1-colours#2','1','ing-1-colours',1,2,'Göy rəng ingiliscə necə deyilir?','Göy — blue.',array['blue','black','brown','green'],1),
('ing1-colours#3','1','ing-1-colours',1,2,'«Green» nə deməkdir?','Green — yaşıl.',array['Yaşıl','Ağ','Qara','Çəhrayı'],1),
('ing1-colours#4','1','ing-1-colours',2,2,'Günəş adətən hansı rənglə çəkilir? (ingiliscə)','Günəş sarı rənglə çəkilir — yellow.',array['yellow','purple','grey','black'],1),
('ing1-colours#5','1','ing-1-colours',1,2,'«White» hansı rəngi bildirir?','White — ağ.',array['Ağ','Qara','Qırmızı','Göy'],1),
('ing1-colours#6','1','ing-1-colours',2,2,'Gecənin rəngi ingiliscə hansıdır?','Gecə qaranlıqdır — black.',array['black','white','pink','orange'],1),
('ing1-colours#7','1','ing-1-colours',2,2,'«Orange» sözü həm meyvə, həm də hansı rəngdir?','Orange — portağal və narıncı rəng.',array['Narıncı','Bənövşəyi','Boz','Yaşıl'],1),
('ing1-colours#8','1','ing-1-colours',2,2,'Hansı söz rəng bildirmir?','Book — kitab deməkdir; pink, brown, grey rənglərdir.',array['book','pink','brown','grey'],1),
('ing1-colours#9','1','ing-1-colours',2,2,'«Pink» nə deməkdir?','Pink — çəhrayı.',array['Çəhrayı','Qəhvəyi','Göy','Qara'],1),
('ing1-colours#10','1','ing-1-colours',2,2,'Ot (grass) adətən hansı rəngdə olur? (ingiliscə)','Ot yaşıldır — green.',array['green','red','white','blue'],1),
('ing1-family#1','1','ing-1-family',1,3,'«Mother» nə deməkdir?','Mother — ana.',array['Ana','Ata','Bacı','Qardaş'],1),
('ing1-family#2','1','ing-1-family',1,3,'Ata ingiliscə necə deyilir?','Ata — father.',array['father','mother','sister','baby'],1),
('ing1-family#3','1','ing-1-family',1,3,'«Baby» sözü kimi bildirir?','Baby — körpə uşaq.',array['Körpəni','Babanı','Müəllimi','Qonşunu'],1),
('ing1-family#4','1','ing-1-family',1,3,'«Family» sözünün mənası nədir?','Family — ailə.',array['Ailə','Məktəb','Ev','Bağça'],1),
('ing1-family#5','1','ing-1-family',2,3,'«Grandfather» kimdir?','Grandfather — baba.',array['Baba','Nənə','Əmi','Dayı'],1),
('ing1-family#6','1','ing-1-family',2,3,'«I love my family» cümləsi nə deməkdir?','Mən ailəmi sevirəm.',array['Mən ailəmi sevirəm','Mən məktəbə gedirəm','Mənim itim var','Mən yemək yeyirəm'],1),
('ing1-family#7','1','ing-1-family',2,3,'Hansı söz ailə üzvü bildirmir?','Table — masa deməkdir.',array['table','mother','father','sister'],1),
('ing1-family#8','1','ing-1-family',2,3,'«This is my father» cümləsində kimdən danışılır?','Cümlədə atadan danışılır.',array['Atadan','Anadan','Bacıdan','Nənədən'],1),
('ing1-family#9','1','ing-1-family',1,3,'Bacı ingiliscə necə deyilir?','Bacı — sister.',array['sister','brother','mother','aunt'],1),
('ing1-family#10','1','ing-1-family',2,3,'«Mum» və «Dad» sözləri kimləri bildirir?','Mum — ana, Dad — ata (əzizləmə formaları).',array['Ana və atanı','Nənə və babanı','Bacı və qardaşı','Müəllimləri'],1),
('ing1-animals#1','1','ing-1-animals',1,4,'«Cat» hansı heyvandır?','Cat — pişik.',array['Pişik','İt','Balıq','Quş'],1),
('ing1-animals#2','1','ing-1-animals',1,4,'İt ingiliscə necə deyilir?','İt — dog.',array['dog','cat','cow','hen'],1),
('ing1-animals#3','1','ing-1-animals',1,4,'«Fish» nə deməkdir?','Fish — balıq.',array['Balıq','Fil','At','Dovşan'],1),
('ing1-animals#4','1','ing-1-animals',1,4,'«Bird» nə deməkdir?','Bird — quş.',array['Quş','Böcək','İlan','Ayı'],1),
('ing1-animals#5','1','ing-1-animals',2,4,'At ingiliscə necə deyilir?','At — horse.',array['horse','house','mouse','goose'],1),
('ing1-animals#6','1','ing-1-animals',2,4,'«Rabbit» sözünün mənası nədir?','Rabbit — dovşan.',array['Dovşan','Tülkü','Canavar','Kirpi'],1),
('ing1-animals#7','1','ing-1-animals',2,4,'Hansı söz heyvan adı deyil?','Apple — alma deməkdir.',array['apple','lion','bear','wolf'],1),
('ing1-animals#8','1','ing-1-animals',2,4,'Süd verən ev heyvanı ingiliscə necə adlanır?','İnək — cow.',array['cow','cat','dog','duck'],1),
('ing1-animals#9','1','ing-1-animals',2,4,'Ən böyük quru heyvanı ingiliscə necə deyilir?','Fil — elephant.',array['elephant','mouse','rabbit','frog'],1),
('ing1-animals#10','1','ing-1-animals',2,4,'«Chicken» nə deməkdir?','Chicken — toyuq.',array['Toyuq','Ördək','Qaz','Sərçə'],1),
('ing2-numbers#1','2','ing-2-numbers',1,1,'«Twenty» hansı ədəddir?','Twenty — 20 deməkdir.',array['20','12','2','22'],1),
('ing2-numbers#2','2','ing-2-numbers',2,1,'«Twelve» hansı ədəddir?','Twelve — 12 deməkdir.',array['12','20','2','10'],1),
('ing2-numbers#3','2','ing-2-numbers',2,1,'Otuz ingiliscə necə deyilir?','Otuz — thirty.',array['thirty','thirteen','three','sixty'],1),
('ing2-numbers#4','2','ing-2-numbers',2,1,'«Fifteen» sözü hansı ədədi bildirir?','Fifteen — 15 deməkdir.',array['15','50','5','14'],1),
('ing2-numbers#5','2','ing-2-numbers',2,1,'«Fourteen» hansı ədəddir?','Fourteen — 14 deməkdir.',array['14','40','4','44'],1),
('ing2-numbers#6','2','ing-2-numbers',2,1,'«One hundred» nə deməkdir?','One hundred — 100.',array['100','10','1 000','11'],1),
('ing2-numbers#7','2','ing-2-numbers',2,1,'Ardıcıllığı davam etdirin: ten, twenty, thirty, …','Onluqlarla sayma: forty (40).',array['forty','fifty','fourteen','ninety'],1),
('ing2-numbers#8','2','ing-2-numbers',2,1,'Əlli ingiliscə necə deyilir?','Əlli — fifty.',array['fifty','fifteen','five','forty'],1),
('ing2-numbers#9','2','ing-2-numbers',2,1,'Hansı söz «60» deməkdir?','Sixty — 60.',array['sixty','sixteen','six','seventy'],1),
('ing2-numbers#10','2','ing-2-numbers',2,1,'«Ninety» hansı ədədi bildirir?','Ninety — 90 deməkdir.',array['90','19','9','99'],1),
('ing2-school#1','2','ing-2-school',1,1,'«Pencil» nə deməkdir?','Pencil — karandaş.',array['Karandaş','Qələm','Silgi','Dəftər'],1),
('ing2-school#2','2','ing-2-school',1,1,'Dəftər ingiliscə necə deyilir?','Dəftər — notebook.',array['notebook','pencil','desk','door'],1),
('ing2-school#3','2','ing-2-school',1,1,'«Teacher» harada işləyir?','Müəllim məktəbdə işləyir.',array['Məktəbdə','Xəstəxanada','Mağazada','Zavodda'],1),
('ing2-school#4','2','ing-2-school',1,1,'«Lesson» sözünün mənası nədir?','Lesson — dərs.',array['Dərs','Oyun','Yemək','Mahnı'],1),
('ing2-school#5','2','ing-2-school',2,1,'Silgi ingiliscə necə deyilir?','Silgi — rubber (eraser).',array['rubber (eraser)','ruler','pen','book'],1),
('ing2-school#6','2','ing-2-school',2,1,'«Desk» nədir?','Desk — parta.',array['Parta','Lövhə','Qapı','Pəncərə'],1),
('ing2-school#7','2','ing-2-school',2,1,'«Go to school» nə deməkdir?','Go to school — məktəbə getmək.',array['Məktəbə getmək','Evə qayıtmaq','Yatmaq','Oynamaq'],1),
('ing2-school#8','2','ing-2-school',2,1,'Hansı söz məktəb ləvazimatı deyil?','Banana — meyvədir.',array['banana','pencil','notebook','schoolbag'],1),
('ing2-school#9','2','ing-2-school',2,1,'«Classroom» nə deməkdir?','Classroom — sinif otağı.',array['Sinif otağı','Yataq otağı','Mətbəx','Həyət'],1),
('ing2-school#10','2','ing-2-school',2,1,'«Stand up» əmri nə bildirir?','Stand up — ayağa qalx.',array['Ayağa qalx','Otur','Yaz','Oxu'],1),
('ing2-body#1','2','ing-2-body',1,2,'«Head» bədənin hansı hissəsidir?','Head — baş.',array['Baş','Əl','Ayaq','Göz'],1),
('ing2-body#2','2','ing-2-body',1,2,'Əl ingiliscə necə deyilir?','Əl — hand.',array['hand','head','hair','ear'],1),
('ing2-body#3','2','ing-2-body',1,2,'«Eyes» hansı orqanlardır?','Eyes — gözlər, görmək üçündür.',array['Gözlər','Qulaqlar','Əllər','Dizlər'],1),
('ing2-body#4','2','ing-2-body',1,2,'«Nose» nə deməkdir?','Nose — burun.',array['Burun','Ağız','Boyun','Barmaq'],1),
('ing2-body#5','2','ing-2-body',2,2,'Qulaq ingiliscə necə deyilir?','Qulaq — ear.',array['ear','eye','arm','hair'],1),
('ing2-body#6','2','ing-2-body',2,2,'«Leg» sözünün mənası nədir?','Leg — qıç (ayaq).',array['Qıç (ayaq)','Qol','Bel','Çiyin'],1),
('ing2-body#7','2','ing-2-body',2,2,'«Ten ___» — barmaqlar haqqında cümləni tamamlayın.','On barmaq — ten fingers.',array['fingers','heads','noses','mouths'],1),
('ing2-body#8','2','ing-2-body',2,2,'«Mouth» nə deməkdir?','Mouth — ağız.',array['Ağız','Diş','Dodaq','Çənə'],1),
('ing2-body#9','2','ing-2-body',2,2,'Saç ingiliscə necə deyilir?','Saç — hair.',array['hair','hand','ear','eye'],1),
('ing2-body#10','2','ing-2-body',2,2,'Hansı söz bədən üzvü deyil?','Car — maşın deməkdir.',array['car','arm','foot','face'],1),
('ing2-food#1','2','ing-2-food',1,2,'«Bread» nə deməkdir?','Bread — çörək.',array['Çörək','Süd','Su','Pendir'],1),
('ing2-food#2','2','ing-2-food',1,2,'Süd ingiliscə necə deyilir?','Süd — milk.',array['milk','meat','rice','tea'],1),
('ing2-food#3','2','ing-2-food',1,2,'«Apple» hansı meyvədir?','Apple — alma.',array['Alma','Armud','Banan','Üzüm'],1),
('ing2-food#4','2','ing-2-food',1,2,'«Water» nə deməkdir?','Water — su.',array['Su','Çay','Şirə','Süd'],1),
('ing2-food#5','2','ing-2-food',2,2,'Pendir ingiliscə necə deyilir?','Pendir — cheese.',array['cheese','butter','bread','egg'],1),
('ing2-food#6','2','ing-2-food',1,2,'«Egg» nə deməkdir?','Egg — yumurta.',array['Yumurta','Ət','Düyü','Şorba'],1),
('ing2-food#7','2','ing-2-food',2,2,'Hansı söz meyvə adıdır?','Banana — banan, meyvədir.',array['banana','soup','rice','meat'],1),
('ing2-food#8','2','ing-2-food',2,2,'«I like tea» cümləsi nə deməkdir?','Mən çay xoşlayıram.',array['Mən çay xoşlayıram','Mən su içmirəm','Mən yemək bişirirəm','Mən südü sevirəm'],1),
('ing2-food#9','2','ing-2-food',2,2,'«Ice cream» nədir?','Ice cream — dondurma.',array['Dondurma','İsti şorba','Duzlu pendir','Qara çay'],1),
('ing2-food#10','2','ing-2-food',2,2,'Hansı söz içki bildirir?','Juice — şirə, içkidir.',array['juice','bread','butter','salad'],1),
('ing2-toys#1','2','ing-2-toys',1,3,'«Toy» sözünün mənası nədir?','Toy — oyuncaq.',array['Oyuncaq','Kitab','Yemək','Geyim'],1),
('ing2-toys#2','2','ing-2-toys',1,3,'Top ingiliscə necə deyilir?','Top — ball.',array['ball','doll','car','kite'],1),
('ing2-toys#3','2','ing-2-toys',1,3,'«Doll» nə deməkdir?','Doll — kukla.',array['Kukla','Top','Kubik','Ayı'],1),
('ing2-toys#4','2','ing-2-toys',2,3,'«Toy car» nə deməkdir?','Toy car — oyuncaq maşın.',array['Oyuncaq maşın','Əsl maşın','Velosiped','Qatar'],1),
('ing2-toys#5','2','ing-2-toys',2,3,'Kubiklər ingiliscə necə deyilir?','Kubiklər — blocks.',array['blocks','books','balls','boxes'],1),
('ing2-toys#6','2','ing-2-toys',2,3,'«Teddy bear» hansı oyuncaqdır?','Teddy bear — oyuncaq ayı.',array['Oyuncaq ayı','Oyuncaq it','Kukla','Çərpələng'],1),
('ing2-toys#7','2','ing-2-toys',2,3,'«Kite» nədir?','Kite — çərpələng.',array['Çərpələng','Təyyarə','Quş','Şar'],1),
('ing2-toys#8','2','ing-2-toys',2,3,'«Play with toys» nə deməkdir?','Oyuncaqlarla oynamaq.',array['Oyuncaqlarla oynamaq','Oyuncaqları atmaq','Oyuncaq almaq','Oyuncaq düzəltmək'],1),
('ing2-toys#9','2','ing-2-toys',2,3,'Hansı söz oyuncaq bildirmir?','Window — pəncərə deməkdir.',array['window','doll','ball','kite'],1),
('ing2-toys#10','2','ing-2-toys',2,3,'«My favourite toy» ifadəsi nə deməkdir?','Mənim ən sevimli oyuncağım.',array['Ən sevimli oyuncağım','Köhnə oyuncağım','Qırıq oyuncaq','Yeni kitabım'],1),
('ing2-verbs#1','2','ing-2-verbs',1,4,'«Read» feili nə deməkdir?','Read — oxumaq.',array['Oxumaq','Yazmaq','Qaçmaq','Yatmaq'],1),
('ing2-verbs#2','2','ing-2-verbs',1,4,'Yazmaq ingiliscə necə deyilir?','Yazmaq — write.',array['write','read','sing','eat'],1),
('ing2-verbs#3','2','ing-2-verbs',1,4,'«Sing» nə deməkdir?','Sing — mahnı oxumaq.',array['Mahnı oxumaq','Rəqs etmək','Gülmək','Danışmaq'],1),
('ing2-verbs#4','2','ing-2-verbs',1,4,'«Dance» feilinin mənası nədir?','Dance — rəqs etmək.',array['Rəqs etmək','Yemək','İçmək','Uçmaq'],1),
('ing2-verbs#5','2','ing-2-verbs',2,4,'Getmək ingiliscə necə deyilir?','Getmək — go.',array['go','come','sit','stop'],1),
('ing2-verbs#6','2','ing-2-verbs',1,4,'«Eat» nə deməkdir?','Eat — yemək (yemək yemək).',array['Yemək','İçmək','Yumaq','Almaq'],1),
('ing2-verbs#7','2','ing-2-verbs',2,4,'«Drink» feili nə bildirir?','Drink — içmək.',array['İçmək','Yemək','Bişirmək','Kəsmək'],1),
('ing2-verbs#8','2','ing-2-verbs',2,4,'Hansı söz hərəkət (feil) bildirir?','Open — açmaq, hərəkətdir.',array['open','table','red','cat'],1),
('ing2-verbs#9','2','ing-2-verbs',2,4,'«Sleep» nə deməkdir?','Sleep — yatmaq.',array['Yatmaq','Oyanmaq','Gəzmək','Oxumaq'],1),
('ing2-verbs#10','2','ing-2-verbs',2,4,'«Look» feilinin mənası nədir?','Look — baxmaq.',array['Baxmaq','Eşitmək','Tutmaq','Atmaq'],1),
('ing3-time#1','3','ing-3-time',2,1,'«What time is it?» sualı nəyi soruşur?','Saatın neçə olduğunu soruşur.',array['Saatın neçə olduğunu','Havanın necə olduğunu','Adını','Yaşını'],1),
('ing3-time#2','3','ing-3-time',1,1,'«Monday» hansı gündür?','Monday — bazar ertəsi.',array['Bazar ertəsi','Bazar','Cümə','Şənbə'],1),
('ing3-time#3','3','ing-3-time',2,1,'«Sunday» nə deməkdir?','Sunday — bazar günü.',array['Bazar günü','Çərşənbə','Cümə axşamı','Bazar ertəsi'],1),
('ing3-time#4','3','ing-3-time',3,1,'İngilis dilində həftə günlərinin adları necə yazılır?','Günlərin adları böyük hərflə yazılır: Monday, Friday.',array['Böyük hərflə','Kiçik hərflə','Rəqəmlə','Dırnaqda'],1),
('ing3-time#5','3','ing-3-time',1,1,'«Today» sözünün mənası nədir?','Today — bu gün.',array['Bu gün','Sabah','Dünən','Həftə'],1),
('ing3-time#6','3','ing-3-time',1,1,'«Tomorrow» nə deməkdir?','Tomorrow — sabah.',array['Sabah','Bu gün','Dünən','Ay'],1),
('ing3-time#7','3','ing-3-time',2,1,'«Spring» hansı fəsildir?','Spring — yaz.',array['Yaz','Yay','Payız','Qış'],1),
('ing3-time#8','3','ing-3-time',1,1,'Qış ingiliscə necə deyilir?','Qış — winter.',array['winter','summer','autumn','spring'],1),
('ing3-time#9','3','ing-3-time',2,1,'«Yesterday» nə deməkdir?','Yesterday — dünən.',array['Dünən','Sabah','İndi','Gec'],1),
('ing3-time#10','3','ing-3-time',2,1,'«Week» sözü nəyi bildirir?','Week — həftə (7 gün).',array['Həftəni','Ayı','İli','Saatı'],1),
('ing3-clothes#1','3','ing-3-clothes',1,1,'«Shirt» nə deməkdir?','Shirt — köynək.',array['Köynək','Şalvar','Papaq','Corab'],1),
('ing3-clothes#2','3','ing-3-clothes',2,1,'Yubka ingiliscə necə deyilir?','Yubka — skirt.',array['skirt','shirt','short','sock'],1),
('ing3-clothes#3','3','ing-3-clothes',2,1,'«Scarf» nə deməkdir?','Scarf — şərf.',array['Şərf','Əlcək','Kəmər','Çanta'],1),
('ing3-clothes#4','3','ing-3-clothes',2,1,'«Jacket» hansı geyimdir?','Jacket — gödəkçə.',array['Gödəkçə','Don','Ayaqqabı','Corab'],1),
('ing3-clothes#5','3','ing-3-clothes',2,1,'«Put on» ifadəsi nə bildirir?','Put on — geyinmək.',array['Geyinmək','Soyunmaq','Yumaq','Ütüləmək'],1),
('ing3-clothes#6','3','ing-3-clothes',2,1,'«Take off» nə deməkdir?','Take off — soyunmaq, çıxarmaq.',array['Soyunmaq (çıxarmaq)','Geyinmək','Almaq','Tikmək'],1),
('ing3-clothes#7','3','ing-3-clothes',2,1,'Başa taxılan yüngül geyim ingiliscə necə adlanır?','Kepka — cap.',array['cap','sock','boot','belt'],1),
('ing3-clothes#8','3','ing-3-clothes',2,1,'«Uniform» nə deməkdir?','Uniform — (məktəb) forması.',array['Forma','İdman ayaqqabısı','Yağmurluq','Pijama'],1),
('ing3-clothes#9','3','ing-3-clothes',2,1,'Hansı söz geyim bildirmir?','Spoon — qaşıq deməkdir.',array['spoon','shirt','skirt','jacket'],1),
('ing3-clothes#10','3','ing-3-clothes',2,1,'«Boots» hansı geyimdir?','Boots — çəkmələr.',array['Çəkmələr','Əlcəklər','Köynəklər','Papaqlar'],1),
('ing3-weather#1','3','ing-3-weather',1,2,'«It is sunny» cümləsi havanın necə olduğunu bildirir?','Sunny — günəşli.',array['Günəşli','Yağışlı','Qarlı','Küləkli'],1),
('ing3-weather#2','3','ing-3-weather',1,2,'«Rainy» nə deməkdir?','Rainy — yağışlı.',array['Yağışlı','Günəşli','Dumanlı','Soyuq'],1),
('ing3-weather#3','3','ing-3-weather',1,2,'Qarlı hava ingiliscə necə deyilir?','Qarlı — snowy.',array['snowy','sunny','windy','rainy'],1),
('ing3-weather#4','3','ing-3-weather',2,2,'«Windy» sözünün mənası nədir?','Windy — küləkli.',array['Küləkli','İsti','Buludlu','Aydın'],1),
('ing3-weather#5','3','ing-3-weather',2,2,'«Hot» və «cold» sözləri nəyi bildirir?','Hot — isti, cold — soyuq.',array['İsti və soyuğu','Gecə və gündüzü','Yaş və qurunu','Ağ və qaranı'],1),
('ing3-weather#6','3','ing-3-weather',2,2,'«Cloud» nə deməkdir?','Cloud — bulud.',array['Bulud','Yağış','Günəş','Şimşək'],1),
('ing3-weather#7','3','ing-3-weather',2,2,'«It is raining» nə deməkdir?','Yağış yağır.',array['Yağış yağır','Qar yağır','Günəş çıxıb','Külək əsir'],1),
('ing3-weather#8','3','ing-3-weather',2,2,'Hava adətən hansı fəsildə «snowy» olur?','Qar qışda yağır.',array['Qışda','Yayda','Yazda','Payızda'],1),
('ing3-weather#9','3','ing-3-weather',2,2,'«Warm» sözünün mənası nədir?','Warm — ilıq, isti.',array['İlıq','Şaxtalı','Yaş','Qaranlıq'],1),
('ing3-weather#10','3','ing-3-weather',2,2,'«How is the weather?» sualı nəyi soruşur?','Havanın necə olduğunu soruşur.',array['Havanın necə olduğunu','Saatı','Yolu','Qiyməti'],1),
('ing3-house#1','3','ing-3-house',1,2,'«House» sözü nəyi bildirir?','House — ev.',array['Evi','Bağı','Yolu','Məktəbi'],1),
('ing3-house#2','3','ing-3-house',1,2,'«Room» nə deməkdir?','Room — otaq.',array['Otaq','Dam','Qapı','Həyət'],1),
('ing3-house#3','3','ing-3-house',1,2,'«Table» hansı əşyadır?','Table — masa (stol).',array['Masa','Stul','Çarpayı','Şkaf'],1),
('ing3-house#4','3','ing-3-house',1,2,'«Chair» nə deməkdir?','Chair — stul.',array['Stul','Masa','Xalça','Güzgü'],1),
('ing3-house#5','3','ing-3-house',1,2,'«Bed» nə deməkdir?','Bed — çarpayı.',array['Çarpayı','Divan','Pəncərə','Soba'],1),
('ing3-house#6','3','ing-3-house',2,2,'Pəncərə ingiliscə necə deyilir?','Pəncərə — window.',array['window','wall','floor','roof'],1),
('ing3-house#7','3','ing-3-house',2,2,'«Lamp» nə deməkdir?','Lamp — lampa (işıq).',array['Lampa','Kitab','Saat','Vaza'],1),
('ing3-house#8','3','ing-3-house',2,2,'«In the room» ifadəsi nə bildirir?','Otağın içində.',array['Otağın içində','Otağın üstündə','Otağın yanında','Otaqdan kənarda'],1),
('ing3-house#9','3','ing-3-house',2,2,'Hansı əşya adətən mətbəxdə olur?','Fridge — soyuducu, mətbəxdə olur.',array['fridge','bed','sofa','wardrobe'],1),
('ing3-house#10','3','ing-3-house',2,2,'«Wardrobe» nə üçündür?','Wardrobe — paltar şkafı.',array['Paltar saxlamaq üçün','Yemək bişirmək üçün','Yatmaq üçün','Kitab oxumaq üçün'],1),
('ing3-present#1','3','ing-3-present',2,3,'«I play» cümləsinə «she» üçün hansı forma uyğundur?','III şəxsin təkində feil «-s» qəbul edir: She plays.',array['She plays.','She play.','She playing.','She is play.'],1),
('ing3-present#2','3','ing-3-present',2,3,'«He ___ to school every day.» boşluğu doldurun.','He ilə: goes.',array['goes','go','going','gone'],1),
('ing3-present#3','3','ing-3-present',2,3,'«They read books every evening» cümləsi hansı zamandadır?','Təkrarlanan hərəkət — Present Simple (indiki sadə).',array['Present Simple','Past Simple','Gələcək','Heç bir zaman'],1),
('ing3-present#4','3','ing-3-present',2,3,'«Do you like milk?» sualına qısa cavab hansıdır?','Qısa cavab: Yes, I do.',array['Yes, I do.','Yes, I am.','Yes, I can.','Yes, it is.'],1),
('ing3-present#5','3','ing-3-present',3,3,'«She does not ___ TV.» boşluğu doldurun.','Does not-dan sonra feilin əsas forması: watch.',array['watch','watches','watching','watched'],1),
('ing3-present#6','3','ing-3-present',3,3,'Present Simple hansı hərəkəti bildirir?','Adi, hər gün təkrarlanan hərəkəti bildirir.',array['Adi, təkrarlanan hərəkəti','Yalnız keçmişi','Yalnız bu andakını','Heç bir hərəkəti'],1),
('ing3-present#7','3','ing-3-present',2,3,'«We ___ English at school.» boşluğu doldurun.','We ilə feil dəyişmir: learn.',array['learn','learns','learning','to learns'],1),
('ing3-present#8','3','ing-3-present',2,3,'Present Simple-da III şəxsin təkində feilə nə artırılır?','He/she/it ilə feilə «-s» artırılır.',array['-s şəkilçisi','-ed şəkilçisi','-ing şəkilçisi','Heç nə'],1),
('ing3-present#9','3','ing-3-present',3,3,'«Does he play chess?» cümləsində köməkçi feil hansıdır?','Sualda köməkçi feil does-dur.',array['Does','Play','He','Chess'],1),
('ing3-present#10','3','ing-3-present',2,3,'«I ___ my homework every day.» boşluğu doldurun.','Do my homework — ev tapşırığını yerinə yetirmək.',array['do','does','doing','dids'],1),
('ing3-prepositions#1','3','ing-3-prepositions',1,4,'«In» sözönü nə bildirir?','In — içində.',array['İçində','Üstündə','Altında','Yanında'],1),
('ing3-prepositions#2','3','ing-3-prepositions',2,4,'«Behind» nə deməkdir?','Behind — arxasında.',array['Arxasında','Qarşısında','İçində','Arasında'],1),
('ing3-prepositions#3','3','ing-3-prepositions',2,4,'«Next to» ifadəsinin mənası nədir?','Next to — yanında.',array['Yanında','Uzağında','Altında','Üstündə'],1),
('ing3-prepositions#4','3','ing-3-prepositions',2,4,'«Between» nə bildirir?','Between — ikisinin arasında.',array['Arasında','İçində','Kənarında','Arxasında'],1),
('ing3-prepositions#5','3','ing-3-prepositions',2,4,'«In front of» nə deməkdir?','In front of — qarşısında.',array['Qarşısında','Arxasında','Altında','İçində'],1),
('ing3-prepositions#6','3','ing-3-prepositions',2,4,'«The book is in the bag» — kitab haradadır?','In the bag — çantanın içində.',array['Çantanın içində','Çantanın üstündə','Masanın altında','Rəfdə'],1),
('ing3-prepositions#7','3','ing-3-prepositions',2,4,'«The ball is behind the door» — top haradadır?','Behind the door — qapının arxasında.',array['Qapının arxasında','Qapının qarşısında','Qapının üstündə','Otağın ortasında'],1),
('ing3-prepositions#8','3','ing-3-prepositions',3,4,'Hansı söz sözönüdür (preposition)?','On — sözönüdür; qalanları isim, sifət, feildir.',array['on','cat','red','run'],1),
('ing3-prepositions#9','3','ing-3-prepositions',2,4,'«The school is near my house» cümləsində «near» nə deməkdir?','Near — yaxınlığında.',array['Yaxınlığında','İçində','Uzağında','Altında'],1),
('ing3-prepositions#10','3','ing-3-prepositions',2,4,'«Put the pen on the desk» əmrində qələm haraya qoyulmalıdır?','On the desk — partanın üstünə.',array['Partanın üstünə','Partanın altına','Çantaya','Pəncərəyə'],1),
('ing4-past#1','4','ing-4-past',2,1,'«Played» feili hansı zamandadır?','«-ed» şəkilçisi keçmiş zamanı göstərir.',array['Keçmiş','İndiki','Gələcək','Heç bir zaman'],1),
('ing4-past#2','4','ing-4-past',2,1,'«Go» feilinin keçmiş forması hansıdır?','Go qaydasız feildir: went.',array['went','goed','gone to','going'],1),
('ing4-past#3','4','ing-4-past',3,1,'«I was at home yesterday» cümləsində «was» nəyi bildirir?','Was — keçmişdə olmağı bildirir.',array['Keçmişdə olmağı','Gələcəyi','İstəyi','Sualı'],1),
('ing4-past#4','4','ing-4-past',2,1,'«I ___ a bird in the garden.» (görmək feilinin keçmişi)','See feilinin keçmişi: saw.',array['saw','see','seen','sees'],1),
('ing4-past#5','4','ing-4-past',2,1,'Qaydalı feillərin keçmiş forması necə düzəlir?','Sonuna «-ed» artırılır: play — played.',array['-ed artırmaqla','-ing artırmaqla','-s artırmaqla','Dəyişməz qalır'],1),
('ing4-past#6','4','ing-4-past',2,1,'«They ___ football yesterday.» boşluğu doldurun.','Yesterday keçmişi göstərir: played.',array['played','play','plays','playing'],1),
('ing4-past#7','4','ing-4-past',2,1,'Keçmiş zamanda «have» feili necə olur?','Have qaydasızdır: had.',array['had','haved','has','having'],1),
('ing4-past#8','4','ing-4-past',3,1,'«Did you watch TV?» sualına qısa cavab hansıdır?','Qısa cavab: Yes, I did.',array['Yes, I did.','Yes, I do.','Yes, I am.','Yes, I have.'],1),
('ing4-past#9','4','ing-4-past',2,1,'«Come» feilinin keçmiş forması hansıdır?','Come qaydasızdır: came.',array['came','comed','coming','comes'],1),
('ing4-past#10','4','ing-4-past',2,1,'«Yesterday» sözü hansı zamanla işlənir?','Yesterday (dünən) keçmiş zamanla işlənir.',array['Keçmiş zamanla','Gələcək zamanla','Yalnız indiki ilə','Heç bir zamanla'],1),
('ing4-jobs#1','4','ing-4-jobs',1,2,'«Doctor» hansı peşə sahibidir?','Doctor — həkim.',array['Həkim','Müəllim','Sürücü','Aşpaz'],1),
('ing4-jobs#2','4','ing-4-jobs',2,2,'Aşpaz ingiliscə necə deyilir?','Aşpaz — cook.',array['cook','book','look','hook'],1),
('ing4-jobs#3','4','ing-4-jobs',1,2,'«Pilot» nəyi idarə edir?','Pilot təyyarəni idarə edir.',array['Təyyarəni','Qatarı','Gəmini','Avtobusu'],1),
('ing4-jobs#4','4','ing-4-jobs',2,2,'«Vet» kimləri müalicə edir?','Vet — baytar, heyvanları müalicə edir.',array['Heyvanları','Uşaqları','İdmançıları','Müəllimləri'],1),
('ing4-jobs#5','4','ing-4-jobs',2,2,'«Farmer» harada işləyir?','Farmer təsərrüfatda (fermada) işləyir.',array['Fermada','Xəstəxanada','Bankda','Teatrda'],1),
('ing4-jobs#6','4','ing-4-jobs',2,2,'Polis ingiliscə necə deyilir?','Polis — police officer.',array['police officer','postman','singer','waiter'],1),
('ing4-jobs#7','4','ing-4-jobs',2,2,'«Dentist» nəyi müalicə edir?','Dentist dişləri müalicə edir.',array['Dişləri','Gözləri','Qulağı','Ayağı'],1),
('ing4-jobs#8','4','ing-4-jobs',2,2,'«Builder» nə edir?','Builder ev və binalar tikir.',array['Ev tikir','Yemək bişirir','Mahnı oxuyur','Məktub daşıyır'],1),
('ing4-jobs#9','4','ing-4-jobs',1,2,'«Singer» kimdir?','Singer — müğənni.',array['Müğənni','Rəssam','Yazıçı','Həkim'],1),
('ing4-jobs#10','4','ing-4-jobs',2,2,'«What is your job?» sualı nəyi soruşur?','Peşəni (harada işlədiyini) soruşur.',array['Peşəni','Yaşı','Ünvanı','Adı'],1),
('ing4-hobbies#1','4','ing-4-hobbies',1,2,'«Hobby» sözünün mənası nədir?','Hobby — sevimli məşğuliyyət.',array['Sevimli məşğuliyyət','İş','Dərs','Yuxu'],1),
('ing4-hobbies#2','4','ing-4-hobbies',1,2,'«Reading» hansı məşğuliyyətdir?','Reading — kitab oxumaq.',array['Oxumaq','Yazmaq','Üzmək','Qaçmaq'],1),
('ing4-hobbies#3','4','ing-4-hobbies',1,2,'«Drawing» nə deməkdir?','Drawing — şəkil çəkmək.',array['Şəkil çəkmək','Mahnı oxumaq','Tikmək','Bişirmək'],1),
('ing4-hobbies#4','4','ing-4-hobbies',2,2,'«I like swimming» cümləsi nəyi bildirir?','Danışan üzməyi xoşlayır.',array['Üzməyi xoşladığını','Üzə bilmədiyini','Suya girməkdən qorxduğunu','Qaçmağı sevdiyini'],1),
('ing4-hobbies#5','4','ing-4-hobbies',3,2,'«Collecting stamps» nə deməkdir?','Marka kolleksiyası yığmaq.',array['Marka yığmaq','Məktub yazmaq','Poçta getmək','Şəkil çəkmək'],1),
('ing4-hobbies#6','4','ing-4-hobbies',2,2,'«Playing chess» hansı oyundur?','Chess — şahmat.',array['Şahmat','Dama','Futbol','Loto'],1),
('ing4-hobbies#7','4','ing-4-hobbies',1,2,'«Dancing» məşğuliyyəti nədir?','Dancing — rəqs etmək.',array['Rəqs','İdman qaçışı','Üzgüçülük','Rəsm'],1),
('ing4-hobbies#8','4','ing-4-hobbies',2,2,'«My hobby is fishing» — söhbət hansı məşğuliyyətdən gedir?','Fishing — balıq tutmaq.',array['Balıq tutmaqdan','Quş tutmaqdan','Gəmi sürməkdən','Su içməkdən'],1),
('ing4-hobbies#9','4','ing-4-hobbies',2,2,'«Watching cartoons» nə deməkdir?','Cizgi filmlərinə baxmaq.',array['Cizgi filmlərinə baxmaq','Kino çəkmək','Televizor almaq','Şəkil yığmaq'],1),
('ing4-hobbies#10','4','ing-4-hobbies',2,2,'«What is your hobby?» sualına hansı cavab uyğundur?','Cavab məşğuliyyət bildirməlidir: My hobby is reading.',array['My hobby is reading.','I am ten.','It is sunny.','This is my mother.'],1),
('ing4-comparative#1','4','ing-4-comparative',2,3,'«Big» sifətinin müqayisə forması hansıdır?','Big — bigger (daha böyük).',array['bigger','biggest','more big','big'],1),
('ing4-comparative#2','4','ing-4-comparative',2,3,'«Small — smaller — the smallest» sırası nəyi göstərir?','Sifətin müqayisə dərəcələrini göstərir.',array['Müqayisə dərəcələrini','Cəm formasını','Zamanı','Sual formasını'],1),
('ing4-comparative#3','4','ing-4-comparative',2,3,'«A giraffe is ___ than a horse.» boşluğu doldurun.','Zürafə atdan hündürdür: taller.',array['taller','tall','the tallest','more tall'],1),
('ing4-comparative#4','4','ing-4-comparative',3,3,'«Good» sifətinin müqayisə forması hansıdır?','Good qaydasız sifətdir: better.',array['better','gooder','more good','best of'],1),
('ing4-comparative#5','4','ing-4-comparative',2,3,'«The longest river» ifadəsi nə deməkdir?','Ən uzun çay.',array['Ən uzun çay','Uzun çay','Daha uzun çay','Qısa çay'],1),
('ing4-comparative#6','4','ing-4-comparative',3,3,'Uzun sifətlərin müqayisəsində hansı söz işlənir?','Uzun sifətlərlə «more» işlənir: more beautiful.',array['more','-er yox, -est','much yox, many','the'],1),
('ing4-comparative#7','4','ing-4-comparative',2,3,'«Winter is ___ than summer.» boşluğu doldurun.','Qış yaydan soyuqdur: colder.',array['colder','hotter','cold','coldest'],1),
('ing4-comparative#8','4','ing-4-comparative',2,3,'«Fast» sözünün müqayisə forması hansıdır?','Fast — faster (daha sürətli).',array['faster','fastest','more fast','fasting'],1),
('ing4-comparative#9','4','ing-4-comparative',2,3,'«The best» nə deməkdir?','The best — ən yaxşı.',array['Ən yaxşı','Daha pis','Yaxşı','Ən pis'],1),
('ing4-comparative#10','4','ing-4-comparative',3,3,'«Short — shorter» qaydasına uyğun cüt hansıdır?','Old — older eyni qayda ilə düzəlir.',array['old — older','good — better','bad — worse','beautiful — more beautiful'],1),
('ing4-questions#1','4','ing-4-questions',1,3,'«Where» sual sözü nəyi soruşur?','Where — harada, yeri soruşur.',array['Yeri','Vaxtı','Səbəbi','Sayı'],1),
('ing4-questions#2','4','ing-4-questions',1,3,'«When» nə deməkdir?','When — nə vaxt.',array['Nə vaxt','Harada','Kim','Necə'],1),
('ing4-questions#3','4','ing-4-questions',2,3,'«Who» sual sözü nəyə aiddir?','Who — kim, şəxsi soruşur.',array['Şəxsə','Əşyaya','Yerə','Rəngə'],1),
('ing4-questions#4','4','ing-4-questions',2,3,'«Why» nə soruşur?','Why — niyə, səbəbi soruşur.',array['Səbəbi','Yeri','Vaxtı','Qiyməti'],1),
('ing4-questions#5','4','ing-4-questions',2,3,'«How many» hansı sualı verir?','How many — neçə, sayı soruşur.',array['Sayı','Rəngi','Dadı','Yaşı yox, yeri'],1),
('ing4-questions#6','4','ing-4-questions',2,3,'«___ is your birthday?» boşluğuna hansı söz uyğundur?','Vaxt soruşulur: When.',array['When','Who','What colour','How many'],1),
('ing4-questions#7','4','ing-4-questions',2,3,'«___ do you live?» boşluğunu doldurun.','Yaşayış yeri soruşulur: Where.',array['Where','Why','Who','When'],1),
('ing4-questions#8','4','ing-4-questions',2,3,'«How old is she?» sualı nəyi soruşur?','How old — yaşı soruşur.',array['Yaşını','Boyunu','Adını','Ünvanını'],1),
('ing4-questions#9','4','ing-4-questions',2,3,'«What colour is it?» sualına hansı cavab uyğundur?','Rəng soruşulur: It is red.',array['It is red.','It is ten.','He is a doctor.','Yes, it is.'],1),
('ing4-questions#10','4','ing-4-questions',2,3,'«Is this your pen?» sualına qısa cavab hansıdır?','Qısa cavab: Yes, it is.',array['Yes, it is.','Yes, I do.','Yes, I can.','Yes, he does.'],1),
('ing4-reading#1','4','ing-4-reading',1,4,'Mətn: «Tom has a dog. The dog is black.» Tomun iti hansı rəngdədir?','Mətndə deyilir: the dog is black — qara.',array['Qara','Ağ','Qəhvəyi','Boz'],1),
('ing4-reading#2','4','ing-4-reading',2,4,'Mətn: «Ann likes apples and pears.» Ann hansı meyvələri xoşlayır?','Apples and pears — alma və armud.',array['Alma və armudu','Banan və üzümü','Gilas və əriyi','Heç bir meyvəni'],1),
('ing4-reading#3','4','ing-4-reading',2,4,'Mətn: «My school is big and new.» Məktəb necədir?','Big and new — böyük və təzə.',array['Böyük və təzə','Kiçik və köhnə','Uzaq və qaranlıq','Bağlı'],1),
('ing4-reading#4','4','ing-4-reading',2,4,'Mətn: «We go to the park on Sundays.» Parka nə vaxt gedirlər?','On Sundays — bazar günləri.',array['Bazar günləri','Hər gün','Səhərlər','Qışda'],1),
('ing4-reading#5','4','ing-4-reading',1,4,'Mətn: «There are five books on the desk.» Partada neçə kitab var?','Five — 5 kitab.',array['5','4','15','50'],1),
('ing4-reading#6','4','ing-4-reading',2,4,'Mətn: «Lala is nine. Her brother is seven.» Lalanın qardaşı neçə yaşındadır?','Seven — 7 yaşındadır.',array['7','9','17','6'],1),
('ing4-reading#7','4','ing-4-reading',2,4,'Mətn: «The cat sleeps on the sofa.» Pişik harada yatır?','On the sofa — divanın üstündə.',array['Divanda','Yerdə','Çarpayıda','Həyətdə'],1),
('ing4-reading#8','4','ing-4-reading',2,4,'Mətn: «I get up at eight.» Danışan saat neçədə yuxudan durur?','At eight — saat 8-də.',array['8-də','7-də','9-da','10-da'],1),
('ing4-reading#9','4','ing-4-reading',2,4,'Mətn: «Father reads a newspaper.» Ata nə oxuyur?','Newspaper — qəzet.',array['Qəzet','Kitab','Jurnal','Məktub'],1),
('ing4-reading#10','4','ing-4-reading',1,4,'Mətn: «It is winter. It is snowy.» Mətndə hansı fəsildən danışılır?','Winter — qış.',array['Qışdan','Yaydan','Yazdan','Payızdan'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, d.rub, 'published'
    from d
    join public.subjects s on s.slug = 'ingilis-dili'
    join public.programs p on p.slug = 'ibtidai'
    join public.levels   l on l.program_id = p.id and l.code = d.sinif
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
     and (ext_key like 'ing1-%' or ext_key like 'ing2-%'
          or ext_key like 'ing3-%' or ext_key like 'ing4-%');
  if n <> 240 then
    raise exception 'ing 1-4 suallari: 240 gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where (q.ext_key like 'ing1-%' or q.ext_key like 'ing2-%'
          or q.ext_key like 'ing3-%' or q.ext_key like 'ing4-%')
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '% sualda variant qurulusu sehvdir', k;
  end if;
  select count(distinct topic_id) into k from public.questions
   where ext_key like 'ing1-%' or ext_key like 'ing2-%'
      or ext_key like 'ing3-%' or ext_key like 'ing4-%';
  if k <> 24 then
    raise exception 'movzu sayi 24 deyil: %', k;
  end if;
  raise notice 'Ingilis dili 1-4 banki: % sual, 24 movzu.', n;
end $$;
