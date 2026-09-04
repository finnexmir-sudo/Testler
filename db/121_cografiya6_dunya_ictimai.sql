-- =====================================================================
--  121_cografiya6_dunya_ictimai.sql : COG-6-DUNYA - ICTIMAI HISSE
--
--  "Dunya bizim evimizdir" movzusunun derslikdeki alt-basliqlarinin
--  yarisi ictimai hemiyyetlidir (sosial heyat, cemiyyet, dovlet,
--  aile, QHT, vetendasliq, milli mesuliyyet, lokal-qlobal elaqeler) -
--  amma movcud 30 sual (fenn6.py: SUALLAR+ELAVE+ELAVE30) yalniz
--  fiziki cografiyadir (materikler, okeanlar, heyvanlar). Ictimai
--  hisseye bir dene de sual yox idi - istifadeci auditinde tapildi.
--
--  Movzu aci deyismir, yalniz elave sual (#31-#48). ELLE yazilib -
--  kicik, birdefelik elave olduğu ucun ayrica tools/ skripti yaradilmadi.
--  ON SERT: 81_movzular_orta6.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'cografiya' and t.slug = 'cog-6-dunya') then
    raise exception 'ONCE 81_movzular_orta6.sql islenmis olmalidir.';
  end if;
end $$;

with d(ext, diff, body, why, opts, correct) as (values
('cog6-dunya#31',1,'Sosial həyat termini nəyi ifadə edir?','Sosial həyat insanların bir-biri ilə münasibətdə, birgə yaşamasıdır.',array['İnsanların bir-biri ilə münasibətdə yaşaması','Yalnız təbiət hadisələri','Yalnız iqtisadi göstəricilər','Yalnız hava şəraiti'],1),
('cog6-dunya#32',1,'Cəmiyyətin ən kiçik özəyi hansı qurumdur?','Ailə cəmiyyətin ən kiçik özəyi sayılır.',array['Ailə','Şirkət','Dövlət','Qonşuluq'],1),
('cog6-dunya#33',1,'Ailə niyə çox vaxt kiçik dövlətə bənzədilir?','Ailənin də öz daxili qaydaları və məsuliyyət bölgüsü olur.',array['Öz qaydaları və məsuliyyət bölgüsü olduğu üçün','Ailənin öz pulu olduğu üçün','Ailənin öz ordusu olduğu üçün','Ailənin öz bayrağı olduğu üçün'],1),
('cog6-dunya#34',2,'Cəmiyyət dedikdə nə başa düşülür?','Cəmiyyət ortaq ərazidə yaşayıb bir-biri ilə əlaqədə olan insanlar toplumudur.',array['Ortaq ərazidə yaşayan, əlaqədə olan insanlar toplumu','Yalnız bir ailə','Yalnız dövlət məmurları','Yalnız bir şəhərin binaları'],1),
('cog6-dunya#35',1,'Dövlət cəmiyyətin hansı növ qurumudur?','Dövlət cəmiyyətin siyasi qurumudur.',array['Siyasi qurumdur','Yalnız idman qurumudur','Yalnız dini qurumdur','Yalnız ticarət qurumudur'],1),
('cog6-dunya#36',2,'Dövlətin əsas vəzifələrindən biri hansıdır?','Dövlət qanunları qoruyub vətəndaşların təhlükəsizliyini təmin edir.',array['Qanunları qoruyub təhlükəsizliyi təmin etmək','Yalnız bayram təşkil etmək','Yalnız idman yarışı keçirmək','Heç bir vəzifəsi yoxdur'],1),
('cog6-dunya#37',1,'Novruz bayramı hansı mövsümün gəlişini bildirir?','Novruz baharın (yazın) gəlişini bildirən bayramdır.',array['Baharın gəlişini','Qışın gəlişini','Payızın gəlişini','Yayın sonunu'],1),
('cog6-dunya#38',2,'Novruz şənlikləri cəmiyyətdə hansı rolu oynayır?','Şənliklər insanları birləşdirib ənənələri yaşadır.',array['İnsanları birləşdirib ənənələri yaşadır','Yalnız bazarları bağlayır','Heç bir rolu yoxdur','Yalnız məktəbləri bağlayır'],1),
('cog6-dunya#39',2,'Qeyri-hökumət təşkilatları (QHT) nə məqsədlə fəaliyyət göstərir?','QHT-lər dövlətdən asılı olmadan ictimai problemlərin həllinə kömək edir.',array['İctimai problemlərin həllinə kömək etmək','Yalnız vergi toplamaq','Yalnız qanun qəbul etmək','Yalnız ordu saxlamaq'],1),
('cog6-dunya#40',3,'QHT-ləri dövlət qurumlarından fərqləndirən əsas cəhət nədir?','QHT-lər dövlət büdcəsindən deyil, könüllü fəaliyyət və ianələrdən qidalanır.',array['Könüllü fəaliyyət və ianələrlə işləməsi','Yalnız xarici ölkədə yerləşməsi','Yalnız internetdə fəaliyyəti','Qanun qəbul etmək hüququ olması'],1),
('cog6-dunya#41',2,'Şirkətlər cəmiyyətin sosial həyatına necə töhfə verə bilər?','Şirkətlər iş yerləri yaradıb sosial layihələri dəstəkləyə bilər.',array['İş yerləri yaradıb sosial layihələri dəstəkləməklə','Yalnız reklam yayaraq','Yalnız vergi ödəməkdən yayınaraq','Heç bir töhfə verə bilməz'],1),
('cog6-dunya#42',1,'İş mühiti insanın sosial həyatına necə təsir edir?','İş yerində insanlar yeni əlaqələr və birgə fəaliyyət imkanı qazanır.',array['Yeni əlaqələr və birgə fəaliyyət imkanı yaradır','Heç bir təsiri yoxdur','Yalnız yorğunluq yaradır','Yalnız gəlir azaldır'],1),
('cog6-dunya#43',2,'Lokal əlaqələr dedikdə nə nəzərdə tutulur?','Lokal əlaqələr yaxın ətrafda - qonşuluqda, şəhər səviyyəsində qurulan əlaqələrdir.',array['Yaxın ətrafda (qonşuluq, şəhər) qurulan əlaqələr','Yalnız başqa qitə ilə əlaqələr','Yalnız kosmik əlaqələr','Heç bir əlaqə'],1),
('cog6-dunya#44',3,'Lokal əlaqələrlə qlobal əlaqələr arasındakı fərq nədir?','Lokal əlaqələr yaxın ərazidə, qlobal əlaqələr isə dünya miqyasında qurulur.',array['Əhatə dairəsinin (yaxın - dünya miqyaslı) fərqli olması','Heç bir fərq yoxdur','Lokal əlaqələr yalnız onlaynda olur','Qlobal əlaqələr yalnız bir ölkədə olur'],1),
('cog6-dunya#45',1,'Vətəndaşın əsas vəzifələrindən biri hansıdır?','Vətəndaşın əsas vəzifələrindən biri qanunlara riayət etməkdir.',array['Qanunlara riayət etmək','Yalnız istirahət etmək','Yalnız səyahət etmək','Heç bir vəzifəsi yoxdur'],1),
('cog6-dunya#46',2,'Milli məsuliyyət hissi nəyi ifadə edir?','Milli məsuliyyət hissi öz ölkəsinin inkişafına töhfə vermək istəyini ifadə edir.',array['Öz ölkəsinin inkişafına töhfə vermək istəyini','Yalnız bayrağı sevməyi','Yalnız himni bilməyi','Heç nəyi ifadə etmir'],1),
('cog6-dunya#47',3,'Azərbaycanın dünya dövlətləri ilə münasibətləri əsasən hansı prinsiplərə söykənir?','Azərbaycan qarşılıqlı hörmət və əməkdaşlıq prinsiplərinə söykənən münasibətlər qurur.',array['Qarşılıqlı hörmət və əməkdaşlıq','Yalnız təcrid olunma','Yalnız hərbi rəqabət','Heç bir prinsipə söykənmir'],1),
('cog6-dunya#48',1,'Dünya nə üçün insanlara həm böyük, həm də kiçik görünə bilər?','Məsafələr böyükdür, amma nəqliyyat və rabitə onları yaxınlaşdırır.',array['Məsafələr böyükdür, amma nəqliyyat-rabitə yaxınlaşdırır','Dünyanın ölçüsü hər gün dəyişir','Dünya həqiqətən kiçilir','Heç bir səbəbi yoxdur'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff, 4, 'published'
    from d
    join public.subjects s on s.slug = 'cografiya'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '6'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'cog-6-dunya'
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, status = 'published'
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
   where ext_key like 'cog6-dunya#%' and ext_key ~ '#[0-9]+$'
     and split_part(ext_key,'#',2)::int between 31 and 48;
  if n <> 18 then
    raise exception '121: 18 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'cog6-dunya#%' and q.ext_key ~ '#[0-9]+$'
     and split_part(q.ext_key,'#',2)::int between 31 and 48
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '121: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '121 OK - % ictimai sual elave olundu (cog-6-dunya, cemi 48 sual).', n;
end $$;
