-- =====================================================================
--  89_alt_movzular_ingilis6_11.sql : INGILIS DILI 6-7, 10-11 - ALT MOVZULAR
--
--  NIYE
--  Sekkizinci fenn.  Riyaziyyat, heyat bilgisi, informatika, fizika,
--  kimya, biologiya hazirdir.
--
--  MENBE: e-derslik.edu.az "Movzular" agaci - kitab id 916 (6),
--  710 (7), 738 (10), 805 (11).  Adlar EYNILE goturulub.
--
--  BU FAYLDA YALNIZ 4 SINIF VAR - qalan 7 sinifin sebebi ferqlidir:
--
--  1-4-CU SINIF: bazadaki movzular ("Alphabet - elifba", "Colours -
--  renglor" kimi ikidilli adlarla) e-derslik dersliyinden GOTURULMEYIB
--  - elle qurulmus lugetevi movzulardir, arxasinda kitab id yoxdur.
--  Alt movzu ucun menbe HEC vaxt olmayacaq.
--
--  5 VE 9-CU SINIF: kitab id 850 (5) ve 886 (9) - dersliyin oz
--  mundericat paneli YALNIZ UNIT basliqlarini verir, hech bir alt
--  ders sadalanmir (bax: sehife: 120/160, amma bolme: 1, hamisi tek
--  "UNITS" basligi altinda).  Bazadaki 6-8 movzu artiq bu tek-sevi-
--  yeli mundericatin ozudur - alt movzu cixaracaq basqa sey yoxdur.
--
--  8-Cİ SINIF: kitab id 824-un server terefi TAM BOSDUR (Cemi sehife:
--  0) - portal bu derslik ucun meznunu hele yuklemeyib (biologiya
--  9-la eyni veziyyet, bax db/88). Portal meznunu yukleyende elave
--  olunacaq.
--
--  10-CU SINIFDE 9 UNIT, BAZADA 6 MOVZU: iki movzu adinin ozu
--  birlesmeni gosterir - "Success and Health" (ing-10-success)
--  Unit 5 (Success) + Unit 6 (Health is Wealth) deyir, "Stages of
--  Life. Media" (ing-10-media) ise Unit 7 (Stages of Life) + Unit 9
--  (Media) - aralarindaki Unit 8 (Happiness) adda gorunmese de bu
--  ikisinin arasinda basqa yeri yoxdur, ona gore de ing-10-media-ya
--  gedir.  Qalan 4 unit (Kindness/Victorious/Environmental Problems/
--  Cultures) birbasa bire-bir.
--
--  BURAXILAN BENDLER: dersliyin sonundaki aparat - "Tests",
--  "Grammar bank/Bank", "Communication activities", "Audio scripts",
--  "Wordlist", "List/Irregular verb(s) list", "References", "Tracks",
--  "Activities", "Text credits, video credits and references" -
--  ders deyil, elavedir (7, 10 ve 11-ci sinifin son unitinde gelir).
--
--  YAZI QUSURLARI: 11-ci sinifde iki bend noqteden sonra bosluqsuz
--  ("Reading.A text...", "topic.A lead-in..."), bir bend apostrofu
--  SQL-de tehlukelidir ("shouldn't" -> "should not").
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

--  AD DUZELISLERI (mezmun deyismeyib):
--   * yazi (3): yazi qusuru (bosluq, herf)
--       11-ci  s.32   Reading.A text about an unusual natural phenomenon
--                    -> Reading. A text about an unusual natural phenomenon
--       11-ci  s.73   Focus on the topic.A lead-in to the topic: No Regrets
--                    -> Focus on the topic. A lead-in to the topic: No Regrets
--       11-ci  s.78   Grammar A. Past Regrets or Mistakes should/shouldn't have done
--                    -> Grammar A. Past Regrets or Mistakes should/should not have done

insert into public.topics (subject_id, level_id, parent_id, slug, name, sort)
select p.subject_id, p.level_id, p.id, v.slug, v.name, v.sort
  from (values
    --  ============  6-ci sinif  ============
    --  UNIT 1. About Town  (ing-6-town)
    ('ing-6-town', 'ing-6-town-places',
     'Places in Town', 10),
    ('ing-6-town', 'ing-6-town-there-are',
     'There is/are (Affirmative, Negative, Yes/No Questions and Short Answers)', 20),
    ('ing-6-town', 'ing-6-town-prepositions-place',
     'Prepositions of Place', 30),
    ('ing-6-town', 'ing-6-town-adverbs-frequency',
     'Adverbs of Frequency', 40),
    --  UNIT 2. Delicious Diversity  (ing-6-food)
    ('ing-6-food', 'ing-6-food-food',
     'Food', 10),
    ('ing-6-food', 'ing-6-food-can-for',
     'Can for Permission (Affirmative, Negative, Yes/No Questions and Short Answers)', 20),
    ('ing-6-food', 'ing-6-food-cooking',
     'Cooking', 30),
    ('ing-6-food', 'ing-6-food-making-suggestions',
     'Making Suggestions and Responding', 40),
    ('ing-6-food', 'ing-6-food-subject-object',
     'Subject and Object Pronouns', 50),
    ('ing-6-food', 'ing-6-food-review',
     'Review', 60),
    --  UNIT 3. What a Holiday!  (ing-6-holiday)
    ('ing-6-holiday', 'ing-6-holiday-holiday',
     'On Holiday', 10),
    ('ing-6-holiday', 'ing-6-holiday-past-simple',
     'Past Simple of be (Affirmative and Negative)', 20),
    ('ing-6-holiday', 'ing-6-holiday-there-was',
     'There was/were', 30),
    ('ing-6-holiday', 'ing-6-holiday-facilities-people',
     'Facilities, People and Activities', 40),
    --  UNIT 4. We all have a story  (ing-6-stories)
    ('ing-6-stories', 'ing-6-stories-story-verbs',
     'Story Verbs', 10),
    ('ing-6-stories', 'ing-6-stories-past-affirmative',
     'Past Simple of Regular Verbs (Affirmative)', 20),
    ('ing-6-stories', 'ing-6-stories-time-expressions',
     'Time Expressions', 30),
    ('ing-6-stories', 'ing-6-stories-irregular-and',
     'Past Simple of Irregular Verbs (Affirmative and Negative), Past Simple of Regular Verbs (Negative)', 40),
    ('ing-6-stories', 'ing-6-stories-review',
     'Review', 50),
    --  UNIT 5. Incredible Journeys  (ing-6-journeys)
    ('ing-6-journeys', 'ing-6-journeys-transport',
     'Transport', 10),
    ('ing-6-journeys', 'ing-6-journeys-simple-regular',
     'Past Simple of Regular and Irregular Verbs (Questions and Answers)', 20),
    ('ing-6-journeys', 'ing-6-journeys-transport-verbs',
     'Transport Verbs', 30),
    ('ing-6-journeys', 'ing-6-journeys-could-for',
     'Could for Ability in the Past (Affirmative, Negative, Yes/No Questions and Short Answers)', 40),
    --  UNIT 6. Heroes Make a Difference  (ing-6-heroes)
    ('ing-6-heroes', 'ing-6-heroes-personality-adjectives',
     'Personality Adjectives', 10),
    ('ing-6-heroes', 'ing-6-heroes-affirmative-negative',
     'Past Continuous (Affirmative and Negative)', 20),
    ('ing-6-heroes', 'ing-6-heroes-feelings',
     'Feelings', 30),
    ('ing-6-heroes', 'ing-6-heroes-questions-answers',
     'Past Continuous (Questions and Answers)', 40),
    ('ing-6-heroes', 'ing-6-heroes-review',
     'Review', 50),
    --  UNIT 7. Great Ideas  (ing-6-ideas)
    ('ing-6-ideas', 'ing-6-ideas-innovation-verbs',
     'Innovation Verbs', 10),
    ('ing-6-ideas', 'ing-6-ideas-past-continuous',
     'Past Continuous and Past Simple', 20),
    ('ing-6-ideas', 'ing-6-ideas-technology',
     'Technology', 30),
    ('ing-6-ideas', 'ing-6-ideas-possessive-pronouns',
     'Possessive Pronouns', 40),
    --  UNIT 8. Our Natural World  (ing-6-nature)
    ('ing-6-nature', 'ing-6-nature-nature',
     'Nature', 10),
    ('ing-6-nature', 'ing-6-nature-verbs-express',
     'Verbs to Express Likes, Wants and Needs', 20),
    ('ing-6-nature', 'ing-6-nature-the-weather',
     'The Weather', 30),
    ('ing-6-nature', 'ing-6-nature-connectors-after',
     'Connectors (After And, Before, But, However and So)', 40),
    ('ing-6-nature', 'ing-6-nature-review',
     'Review', 50),
    --  ============  7-ci sinif  ============
    --  UNIT 1.SCHOOLS AROUND THE WORLD  (ing-7-schools)
    ('ing-7-schools', 'ing-7-schools-read-article',
     'Read an article about schools around the world', 10),
    ('ing-7-schools', 'ing-7-schools-common-adjectives',
     'Common adjectives', 20),
    ('ing-7-schools', 'ing-7-schools-ending-and',
     'Adjectives ending in -ed and -ing; Too vs. enough', 30),
    ('ing-7-schools', 'ing-7-schools-listen-person',
     'Listen to a person talking about a school', 40),
    ('ing-7-schools', 'ing-7-schools-revision-grade',
     'Revision of Grade 6', 50),
    ('ing-7-schools', 'ing-7-schools-story-thank',
     'Story time: Thank you, Mr Falker by Patricia Polacco Part 1', 60),
    ('ing-7-schools', 'ing-7-schools-watch-asking',
     'Time to watch: Asking for permission', 70),
    ('ing-7-schools', 'ing-7-schools-review',
     'Review', 80),
    --  UNIT 2. A WORLD OF TECHNOLOGY  (ing-7-technology)
    ('ing-7-technology', 'ing-7-technology-read-article',
     'Read an article about two young people', 10),
    ('ing-7-technology', 'ing-7-technology-common-adjectives',
     'Common adjectives', 20),
    ('ing-7-technology', 'ing-7-technology-and-infinitives',
     'Adjectives and infinitives; Used to', 30),
    ('ing-7-technology', 'ing-7-technology-listen-person',
     'Listen to a person talking about a young scientist', 40),
    ('ing-7-technology', 'ing-7-technology-paragraph',
     'A paragraph', 50),
    ('ing-7-technology', 'ing-7-technology-story-thank',
     'Story time: Thank you, Mr Falker by Patricia Polacco Part 2', 60),
    ('ing-7-technology', 'ing-7-technology-watch-expressing',
     'Time to watch: Expressing anxiety', 70),
    ('ing-7-technology', 'ing-7-technology-review',
     'Review', 80),
    --  UNIT 3. WHAT A TALENT!  (ing-7-talent)
    ('ing-7-talent', 'ing-7-talent-read-article',
     'Read an article about talented people', 10),
    ('ing-7-talent', 'ing-7-talent-common-phrasal',
     'Common phrasal verbs', 20),
    ('ing-7-talent', 'ing-7-talent-past-continuous',
     'Past Continuous; Time clauses with when and while', 30),
    ('ing-7-talent', 'ing-7-talent-listen-conversation',
     'Listen to a conversation about a talented person', 40),
    ('ing-7-talent', 'ing-7-talent-writing-process',
     'Writing process: Prewriting', 50),
    ('ing-7-talent', 'ing-7-talent-story-better',
     'Story time: Better Than You by Trudy Ludwig Part 1', 60),
    ('ing-7-talent', 'ing-7-talent-watch-inviting',
     'Time to watch: Inviting', 70),
    ('ing-7-talent', 'ing-7-talent-review',
     'Review', 80),
    --  UNIT 4. TRAVEL  (ing-7-travel)
    ('ing-7-travel', 'ing-7-travel-read-interview',
     'Read an interview with a young travel blogger', 10),
    ('ing-7-travel', 'ing-7-travel-vocabulary-for',
     'Vocabulary for travel', 20),
    ('ing-7-travel', 'ing-7-travel-alternative-questions',
     'Alternative questions; Tag questions', 30),
    ('ing-7-travel', 'ing-7-travel-listen-talk',
     'Listen to a talk with a travel blogger', 40),
    ('ing-7-travel', 'ing-7-travel-writing-process',
     'Writing process: Drafting', 50),
    ('ing-7-travel', 'ing-7-travel-story-better',
     'Story time: Better Than You by Trudy Ludwig Part 2', 60),
    ('ing-7-travel', 'ing-7-travel-watch-giving',
     'Time to watch: Giving thanks', 70),
    ('ing-7-travel', 'ing-7-travel-review',
     'Review', 80),
    --  UNIT 5.FRIENDS FOREVER  (ing-7-friends)
    ('ing-7-friends', 'ing-7-friends-read-article',
     'Read an article about friends', 10),
    ('ing-7-friends', 'ing-7-friends-vocabulary-for',
     'Vocabulary for describing characters', 20),
    ('ing-7-friends', 'ing-7-friends-zero-conditional',
     'Zero Conditional;First Conditional', 30),
    ('ing-7-friends', 'ing-7-friends-listen-song',
     'Listen to a song about friendship', 40),
    ('ing-7-friends', 'ing-7-friends-writing-process',
     'Writing process: Revising and editing', 50),
    ('ing-7-friends', 'ing-7-friends-story-each',
     'Story time: Each Kindness by Jacqueline Woodson Part 1', 60),
    ('ing-7-friends', 'ing-7-friends-watch-offering',
     'Time to watch: Offering help', 70),
    ('ing-7-friends', 'ing-7-friends-review',
     'Review', 80),
    --  UNIT 6.LIFE IN THE FUTURE  (ing-7-future)
    ('ing-7-future', 'ing-7-future-read-article',
     'Read an article about future life', 10),
    ('ing-7-future', 'ing-7-future-film-vocabulary',
     'Film vocabulary', 20),
    ('ing-7-future', 'ing-7-future-present-continuous',
     'Present Continuous and Present Simple for Future;Future Possibility and Prediction', 30),
    ('ing-7-future', 'ing-7-future-listen-conversation',
     'Listen to a conversation about films', 40),
    ('ing-7-future', 'ing-7-future-writing-letter',
     'Writing a letter', 50),
    ('ing-7-future', 'ing-7-future-story-each',
     'Story time: Each Kindness by Jacqueline Woodson Part 2', 60),
    ('ing-7-future', 'ing-7-future-watch-asking',
     'Time to watch: Asking for advice', 70),
    ('ing-7-future', 'ing-7-future-review',
     'Review', 80),
    --  ============  10-cu sinif  ============
    --  UNIT 1. KINDNESS  (ing-10-kindness)
    ('ing-10-kindness', 'ing-10-kindness-vocabulary-related',
     'Vocabulary related to kindness', 10),
    ('ing-10-kindness', 'ing-10-kindness-read-article',
     'Read an article about random acts of kindness', 20),
    ('ing-10-kindness', 'ing-10-kindness-adjective-clauses',
     'A. Adjective clauses; B. Essential and nonessential adjective clauses', 30),
    ('ing-10-kindness', 'ing-10-kindness-listen-the',
     'Listen to the people talking about volunteering they do', 40),
    ('ing-10-kindness', 'ing-10-kindness-descriptive-paragraphs',
     'Descriptive paragraphs', 50),
    ('ing-10-kindness', 'ing-10-kindness-time-watch',
     'Time to Watch', 60),
    ('ing-10-kindness', 'ing-10-kindness-use-english',
     'Use of English', 70),
    ('ing-10-kindness', 'ing-10-kindness-mistake-detector',
     'Mistake Detector', 80),
    --  UNIT 2. WE ARE VICTORIOUS!  (ing-10-victory)
    ('ing-10-victory', 'ing-10-victory-vocabulary-related',
     'Vocabulary related to the 44-Day Patriotic War', 10),
    ('ing-10-victory', 'ing-10-victory-read-article',
     'Read an article written by a veteran of the 44-Day Patriotic War', 20),
    ('ing-10-victory', 'ing-10-victory-adverb-clauses',
     'A. Adverb clauses of reason and result; B. Adverb clauses of purpose', 30),
    ('ing-10-victory', 'ing-10-victory-listen-parts',
     'Listen to the parts of interviews with President Ilham Aliyev', 40),
    ('ing-10-victory', 'ing-10-victory-cause-effect',
     'Cause/Effect paragraphs', 50),
    ('ing-10-victory', 'ing-10-victory-time-watch',
     'Time to Watch', 60),
    ('ing-10-victory', 'ing-10-victory-use-english',
     'Use of English', 70),
    ('ing-10-victory', 'ing-10-victory-mistake-detector',
     'Mistake Detector', 80),
    --  UNIT 3. CPULTURES  (ing-10-cultures)
    ('ing-10-cultures', 'ing-10-cultures-vocabulary-related',
     'Vocabulary related to cultures', 10),
    ('ing-10-cultures', 'ing-10-cultures-read-article',
     'Read an article about different festivals', 20),
    ('ing-10-cultures', 'ing-10-cultures-adverb-clauses',
     'A. Adverb clauses of concession; B. Adverb clauses of contrast', 30),
    ('ing-10-cultures', 'ing-10-cultures-listen-talk',
     'Listen to a talk about some languages', 40),
    ('ing-10-cultures', 'ing-10-cultures-comparison-paragraphs',
     'Comparison paragraphs', 50),
    ('ing-10-cultures', 'ing-10-cultures-time-watch',
     'Time to Watch', 60),
    ('ing-10-cultures', 'ing-10-cultures-use-english',
     'Use of English', 70),
    ('ing-10-cultures', 'ing-10-cultures-mistake-detector',
     'Mistake Detector', 80),
    --  UNIT 4. ENVIRONMENTAL PROBLEMS  (ing-10-environment)
    ('ing-10-environment', 'ing-10-environment-vocabulary-related',
     'Vocabulary related to environmental problems', 10),
    ('ing-10-environment', 'ing-10-environment-read-article',
     'Read an article about light pollution', 20),
    ('ing-10-environment', 'ing-10-environment-present-perfect',
     'A. Present Perfect Progressive; B. Past Simple, Present Perfect and Present Perfect Progressive', 30),
    ('ing-10-environment', 'ing-10-environment-listen-talk',
     'Listen to a talk about air pollution', 40),
    ('ing-10-environment', 'ing-10-environment-problem-solution',
     'Problem/ Solution paragraphs', 50),
    ('ing-10-environment', 'ing-10-environment-time-watch',
     'Time to Watch', 60),
    ('ing-10-environment', 'ing-10-environment-use-english',
     'Use of English', 70),
    ('ing-10-environment', 'ing-10-environment-mistake-detector',
     'Mistake Detector', 80),
    --  UNIT 5. SUCCESS  (ing-10-success)
    ('ing-10-success', 'ing-10-success-vocabulary-related',
     'Vocabulary related to success', 10),
    ('ing-10-success', 'ing-10-success-read-article',
     'Read an article about success', 20),
    ('ing-10-success', 'ing-10-success-past-perfect',
     'A. Past Perfect; B. Past Perfect Passive', 30),
    ('ing-10-success', 'ing-10-success-listen-talk',
     'Listen to a talk about a famous comedian', 40),
    ('ing-10-success', 'ing-10-success-narrative-paragraphs',
     'Narrative paragraphs', 50),
    ('ing-10-success', 'ing-10-success-time-watch',
     'Time to Watch', 60),
    ('ing-10-success', 'ing-10-success-use-english',
     'Use of English', 70),
    ('ing-10-success', 'ing-10-success-mistake-detector',
     'Mistake Detector', 80),
    --  UNIT 6. HEALTH IS WEALTH!  (ing-10-success)
    ('ing-10-success', 'ing-10-success-vocabulary-related-health',
     'Vocabulary related to health', 90),
    ('ing-10-success', 'ing-10-success-read-article-healthy',
     'Read an article about a healthy lifestyle', 100),
    ('ing-10-success', 'ing-10-success-subject-verb',
     'A. Subject-verb agreement; B. Would rather/ had better', 110),
    ('ing-10-success', 'ing-10-success-listen-conversation',
     'Listen to a conversation about two different sports', 120),
    ('ing-10-success', 'ing-10-success-opinion-paragraphs',
     'Opinion paragraphs', 130),
    ('ing-10-success', 'ing-10-success-time-watch-2',
     'Time to Watch', 140),
    ('ing-10-success', 'ing-10-success-use-english-2',
     'Use of English', 150),
    ('ing-10-success', 'ing-10-success-mistake-detector-2',
     'Mistake Detector', 160),
    --  UNIT 7. STAGES OF LIFE  (ing-10-media)
    ('ing-10-media', 'ing-10-media-vocabulary-related',
     'Vocabulary related to stages of life', 10),
    ('ing-10-media', 'ing-10-media-read-article',
     'Read an article about stages of life', 20),
    ('ing-10-media', 'ing-10-media-reported-speech',
     'A. Reported Speech; B. Reporting orders, requests and suggestions', 30),
    ('ing-10-media', 'ing-10-media-listen-teacher',
     'Listen to a teacher working at the Skills Centre', 40),
    ('ing-10-media', 'ing-10-media-classification-paragraphs',
     'Classification paragraphs', 50),
    ('ing-10-media', 'ing-10-media-time-watch',
     'Time to Watch', 60),
    ('ing-10-media', 'ing-10-media-use-english',
     'Use of English', 70),
    ('ing-10-media', 'ing-10-media-mistake-detector',
     'Mistake Detector', 80),
    --  UNIT 8. HAPPINESS  (ing-10-media)
    ('ing-10-media', 'ing-10-media-vocabulary-happiness',
     'Vocabulary related to happiness', 90),
    ('ing-10-media', 'ing-10-media-read-article-about',
     'Read an article about happiness', 100),
    ('ing-10-media', 'ing-10-media-reporting-yes',
     'A. Reporting Yes/No questions; B. Reporting WH questions', 110),
    ('ing-10-media', 'ing-10-media-listen-story',
     'Listen to a story', 120),
    ('ing-10-media', 'ing-10-media-definition-paragraphs',
     'Definition paragraphs', 130),
    ('ing-10-media', 'ing-10-media-time-watch-2',
     'Time to Watch', 140),
    ('ing-10-media', 'ing-10-media-use-english-2',
     'Use of English', 150),
    ('ing-10-media', 'ing-10-media-mistake-detector-2',
     'Mistake Detector', 160),
    --  UNIT 9. MEDIA  (ing-10-media)
    ('ing-10-media', 'ing-10-media-vocabulary-related-media',
     'Vocabulary related to media', 170),
    ('ing-10-media', 'ing-10-media-read-article-cyberbullying',
     'Read an article about cyberbullying', 180),
    ('ing-10-media', 'ing-10-media-second-conditional',
     'A. Second Conditional; B. Zero, First and Second Conditionals', 190),
    ('ing-10-media', 'ing-10-media-listen-talk',
     'Listen to a talk about different types of books', 200),
    ('ing-10-media', 'ing-10-media-process-paragraphs',
     'Process paragraphs', 210),
    ('ing-10-media', 'ing-10-media-time-watch-3',
     'Time to Watch', 220),
    ('ing-10-media', 'ing-10-media-use-english-3',
     'Use of English', 230),
    ('ing-10-media', 'ing-10-media-mistake-detector-3',
     'Mistake Detector', 240),
    --  ============  11-ci sinif  ============
    --  UNIT 1. THE WHYS AND WHEREFORES  (ing-11-whys)
    ('ing-11-whys', 'ing-11-whys-the-topic',
     'Focus on the topic. A lead-in to the topic: The Whys and Wherefores', 10),
    ('ing-11-whys', 'ing-11-whys-key-words',
     'Vocabulary. Key words and phrases', 20),
    ('ing-11-whys', 'ing-11-whys-reading-magazine',
     'Reading. A magazine article "Why Questioning Is Important"', 30),
    ('ing-11-whys', 'ing-11-whys-yes-question',
     'Grammar A. An included yes/no question', 40),
    ('ing-11-whys', 'ing-11-whys-grammar-question',
     'Grammar B. An included Wh question', 50),
    ('ing-11-whys', 'ing-11-whys-listening-talk',
     'Listening. A talk on types of questions', 60),
    ('ing-11-whys', 'ing-11-whys-speaking-individual',
     'Speaking. Individual and collaborative speaking tasks', 70),
    ('ing-11-whys', 'ing-11-whys-writing-paragraph',
     'Writing. Paragraph and essay structures', 80),
    ('ing-11-whys', 'ing-11-whys-word-inspector',
     'Word Inspector. Language development: Focus on vocabulary', 90),
    ('ing-11-whys', 'ing-11-whys-time-watch',
     'Time to Watch. An episode from a game show "Are you smarter than a fifth grader?"', 100),
    ('ing-11-whys', 'ing-11-whys-use-english',
     'Use of English. Language development: Focus on vocabulary and grammar', 110),
    ('ing-11-whys', 'ing-11-whys-mistake-detector',
     'Mistake Detector. Self-assessment through mistake identification', 120),
    --  UNIT 2. LIFETIME EXPERIENCES  (ing-11-experiences)
    ('ing-11-experiences', 'ing-11-experiences-topic-lead',
     'Focus on the topic. A lead-in to the topic: Lifetime Experiences', 10),
    ('ing-11-experiences', 'ing-11-experiences-key-words',
     'Vocabulary. Key words and phrases', 20),
    ('ing-11-experiences', 'ing-11-experiences-reading-text',
     'Reading. A text about an unusual natural phenomenon', 30),
    ('ing-11-experiences', 'ing-11-experiences-past-perfect',
     'Grammar A. Past Perfect Progressive', 40),
    ('ing-11-experiences', 'ing-11-experiences-narrative-tenses',
     'Grammar B. Narrative tenses', 50),
    ('ing-11-experiences', 'ing-11-experiences-listening-talk',
     'Listening. A talk on the Northern lights', 60),
    ('ing-11-experiences', 'ing-11-experiences-speaking-individual',
     'Speaking. Individual and collaborative speaking tasks', 70),
    ('ing-11-experiences', 'ing-11-experiences-writing-parts',
     'Writing. Parts of an essay: Introduction', 80),
    ('ing-11-experiences', 'ing-11-experiences-word-inspector',
     'Word Inspector. Language development: Focus on vocabulary', 90),
    ('ing-11-experiences', 'ing-11-experiences-time-watch',
     'Time to Watch. A video about a safari trip to Tanzania', 100),
    ('ing-11-experiences', 'ing-11-experiences-use-english',
     'Use of English. Language development: Focus on vocabulary and grammar', 110),
    ('ing-11-experiences', 'ing-11-experiences-mistake-detector',
     'Mistake Detector. Self-assessment through mistake identification', 120),
    --  UNIT 3. THE ART OF CONVERSATION  (ing-11-conversation)
    ('ing-11-conversation', 'ing-11-conversation-topic-lead',
     'Focus on the topic. A lead-in to the topic: The Art of Conversation', 10),
    ('ing-11-conversation', 'ing-11-conversation-key-words',
     'Vocabulary. Key words and phrases', 20),
    ('ing-11-conversation', 'ing-11-conversation-reading-article',
     'Reading. An article about the danger of losing the art of conversation', 30),
    ('ing-11-conversation', 'ing-11-conversation-grammar-conditional',
     'Grammar A. Third Conditional', 40),
    ('ing-11-conversation', 'ing-11-conversation-second-conditionals',
     'Grammar B. Second and Third Conditionals', 50),
    ('ing-11-conversation', 'ing-11-conversation-listening-differences',
     'Listening. A talk on the differences between ambiverts and omniverts', 60),
    ('ing-11-conversation', 'ing-11-conversation-speaking-individual',
     'Speaking. Individual and collaborative speaking tasks', 70),
    ('ing-11-conversation', 'ing-11-conversation-writing-parts',
     'Writing. Parts of an essay: Thesis statement', 80),
    ('ing-11-conversation', 'ing-11-conversation-word-inspector',
     'Word Inspector. Language development: Focus on vocabulary', 90),
    ('ing-11-conversation', 'ing-11-conversation-time-watch',
     'Time to Watch. A TED talk about verbal and non-verbal behaviour', 100),
    ('ing-11-conversation', 'ing-11-conversation-use-english',
     'Use of English. Language development: Focus on vocabulary and grammar', 110),
    ('ing-11-conversation', 'ing-11-conversation-mistake-detector',
     'Mistake Detector. Self-assessment through mistake identification', 120),
    --  UNIT 4. NO REGRETS  (ing-11-regrets)
    ('ing-11-regrets', 'ing-11-regrets-topic-lead',
     'Focus on the topic. A lead-in to the topic: No Regrets', 10),
    ('ing-11-regrets', 'ing-11-regrets-key-words',
     'Vocabulary. Key words and phrases', 20),
    ('ing-11-regrets', 'ing-11-regrets-reading-magazine',
     'Reading. A magazine article "The Biggest Regrets of a University Graduate"', 30),
    ('ing-11-regrets', 'ing-11-regrets-past-mistakes',
     'Grammar A. Past Regrets or Mistakes should/should not have done', 40),
    ('ing-11-regrets', 'ing-11-regrets-verbs-that',
     'Grammar B. Verbs that change meaning with gerund/infinitive', 50),
    ('ing-11-regrets', 'ing-11-regrets-listening-people',
     'Listening. People talking about their biggest regrets', 60),
    ('ing-11-regrets', 'ing-11-regrets-speaking-individual',
     'Speaking. Individual and collaborative speaking tasks', 70),
    ('ing-11-regrets', 'ing-11-regrets-writing-parts',
     'Writing. Parts of an essay: Body paragraphs', 80),
    ('ing-11-regrets', 'ing-11-regrets-word-inspector',
     'Word Inspector. Language development: Focus on vocabulary', 90),
    ('ing-11-regrets', 'ing-11-regrets-time-watch',
     'Time to Watch. An animation "Dried-up in meetings" a story written by Mir Jalal', 100),
    ('ing-11-regrets', 'ing-11-regrets-use-english',
     'Use of English. Language development: Focus on vocabulary and grammar', 110),
    ('ing-11-regrets', 'ing-11-regrets-mistake-detector',
     'Mistake Detector. Self-assessment through mistake identification', 120),
    --  UNIT 5. CREATIVITY  (ing-11-creativity)
    ('ing-11-creativity', 'ing-11-creativity-the-topic',
     'Focus on the topic. A lead-in to the topic: Creativity', 10),
    ('ing-11-creativity', 'ing-11-creativity-key-words',
     'Vocabulary. Key words and phrases', 20),
    ('ing-11-creativity', 'ing-11-creativity-reading-article',
     'Reading. An article about creativity', 30),
    ('ing-11-creativity', 'ing-11-creativity-grammar-voice',
     'Grammar A. Passive Voice', 40),
    ('ing-11-creativity', 'ing-11-creativity-grammar-causatives',
     'Grammar B. Passive Causatives', 50),
    ('ing-11-creativity', 'ing-11-creativity-listening-talk',
     'Listening. A talk on one way of boosting creativity', 60),
    ('ing-11-creativity', 'ing-11-creativity-speaking-individual',
     'Speaking. Individual and collaborative speaking tasks', 70),
    ('ing-11-creativity', 'ing-11-creativity-writing-parts',
     'Writing. Parts of an essay: Concluding paragraphs', 80),
    ('ing-11-creativity', 'ing-11-creativity-word-inspector',
     'Word Inspector. Language development: Focus on vocabulary', 90),
    ('ing-11-creativity', 'ing-11-creativity-time-watch',
     'Time to Watch. News stories about two creative people', 100),
    ('ing-11-creativity', 'ing-11-creativity-use-english',
     'Use of English. Language development: Focus on vocabulary and grammar', 110),
    ('ing-11-creativity', 'ing-11-creativity-mistake-detector',
     'Mistake Detector. Self-assessment through mistake identification', 120),
    --  UNIT 6. IN THE NEWS  (ing-11-news)
    ('ing-11-news', 'ing-11-news-the-topic',
     'Focus on the topic. A lead-in to the topic: In the News', 10),
    ('ing-11-news', 'ing-11-news-key-words',
     'Vocabulary. Key words and phrases', 20),
    ('ing-11-news', 'ing-11-news-reading-magazine',
     'Reading. A magazine article about News Addiction', 30),
    ('ing-11-news', 'ing-11-news-verbs-with',
     'Grammar A. Verbs with future meaning', 40),
    ('ing-11-news', 'ing-11-news-grammar-perfect',
     'Grammar B. Future Perfect', 50),
    ('ing-11-news', 'ing-11-news-listening-reports',
     'Listening. News reports', 60),
    ('ing-11-news', 'ing-11-news-speaking-individual',
     'Speaking. Individual and collaborative speaking tasks', 70),
    ('ing-11-news', 'ing-11-news-writing-citations',
     'Writing. Citations', 80),
    ('ing-11-news', 'ing-11-news-word-inspector',
     'Word Inspector. Language development: Focus on vocabulary', 90),
    ('ing-11-news', 'ing-11-news-time-watch',
     'Time to Watch. News stories that went viral', 100),
    ('ing-11-news', 'ing-11-news-use-english',
     'Use of English. Language development: Focus on vocabulary and grammar', 110),
    ('ing-11-news', 'ing-11-news-mistake-detector',
     'Mistake Detector. Self-assessment through mistake identification', 120)
  ) as v(parent_slug, slug, name, sort)
  join public.topics p on p.slug = v.parent_slug
   and p.subject_id = (select id from public.subjects where slug = 'ingilis-dili')
on conflict (subject_id, slug) do update
  set name = excluded.name, sort = excluded.sort,
      parent_id = excluded.parent_id, level_id = excluded.level_id;

do $$
declare k int;
begin
  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'ingilis-dili'
    join public.levels   l on l.id = p.level_id and l.code = '6';
  if k <> 37 then
    raise exception 'ingilis-dili 6-ci alt movzulari: 37 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'ingilis-dili'
    join public.levels   l on l.id = p.level_id and l.code = '7';
  if k <> 48 then
    raise exception 'ingilis-dili 7-ci alt movzulari: 48 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'ingilis-dili'
    join public.levels   l on l.id = p.level_id and l.code = '10';
  if k <> 72 then
    raise exception 'ingilis-dili 10-cu alt movzulari: 72 gozlenilirdi, % tapildi', k;
  end if;

  select count(*) into k from public.topics c
    join public.topics p on p.id = c.parent_id
    join public.subjects s on s.id = p.subject_id and s.slug = 'ingilis-dili'
    join public.levels   l on l.id = p.level_id and l.code = '11';
  if k <> 72 then
    raise exception 'ingilis-dili 11-ci alt movzulari: 72 gozlenilirdi, % tapildi', k;
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
    join public.subjects s on s.id = t.subject_id and s.slug = 'ingilis-dili'
    join public.levels   l on l.id = t.level_id
   where t.parent_id is null and true;
  if k <> 70 then
    raise exception 'Ingilis dili ust movzu sayi 70 deyil: %', k;
  end if;

  raise notice 'Ingilis dili 6, 7, 10, 11 (1-4, 5, 8, 9 menbesiz/bos): 229 alt movzu hazir.';
end $$;
