-- =====================================================================
--  126_fiz7_skalyar_vektorial.sql : FIZ-7-OLCME SKALYAR/VEKTORIAL
--
--  "Fiziki kemiyyetler ve olcme" movzusunun alt-basligi "Skalyar ve
--  vektorial kemiyyetler"dir - amma 30 sualin hec birinde bu ferq
--  toxunulmayib (hamisi vahid cevirmesi/olcme aletleridir).
--  Istifadeci auditinde tapildi.
--
--  4 yeni sual elave edir (movcud suallara toxunulmur).
--  ext_key: fiz7-olcme#31-34.
--
--  ON SERT: 33_movzular_orta7.sql islenmis olmalidir.
--  SONRA:   05_grants.sql yeniden islet.
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.topics t join public.subjects s
      on s.id = t.subject_id
     where s.slug = 'fizika' and t.slug = 'fiz-7-olcme') then
    raise exception 'ONCE 33_movzular_orta7.sql islenmis olmalidir.';
  end if;
end $$;

delete from public.question_options o
 using public.questions q
 where o.question_id = q.id
   and q.ext_key like 'fiz7-olcme#%' and q.ext_key ~ '#(3[1-4])$';

with d(ext, diff, body, why, opts, correct) as (values
('fiz7-olcme#31',1,'Skalyar kəmiyyət nə ilə xarakterizə olunur?','Skalyar kəmiyyət yalnız ədədi qiymətlə (istiqamətsiz) xarakterizə olunur.',array['Yalnız ədədi qiymətlə','Ədədi qiymət və istiqamətlə','Yalnız istiqamətlə','Rənglə'],1),
('fiz7-olcme#32',2,'Vektorial kəmiyyət skalyar kəmiyyətdən nə ilə fərqlənir?','Vektorial kəmiyyətin ədədi qiymətdən əlavə istiqaməti də var.',array['İstiqamətinin olması ilə','Vahidinin olmaması ilə','Ölçülə bilməməsi ilə','Rəqəmlə ifadə olunmaması ilə'],1),
('fiz7-olcme#33',2,'Aşağıdakılardan hansı vektorial kəmiyyətdir?','Qüvvə həm qiymət, həm də istiqamətlə xarakterizə olunan vektorial kəmiyyətdir.',array['Qüvvə','Kütlə','Temperatur','Vaxt'],1),
('fiz7-olcme#34',3,'Yerdəyişmə niyə vektorial kəmiyyət sayılır?','Yerdəyişmənin həm miqdarı (məsafə), həm də istiqaməti vardır.',array['Həm miqdarı, həm istiqaməti olduğu üçün','Yalnız ədədi qiyməti olduğu üçün','Vahidsiz olduğu üçün','Həmişə sıfır olduğu üçün'],1)
),
ins as (
  insert into public.questions
    (ext_key, owner_type, subject_id, level_id, topic_id, kind,
     body, explanation, difficulty, quarter, status)
  select d.ext, 'platform', s.id, l.id, tp.id, 'single',
         d.body, d.why, d.diff::int, 1, 'published'
    from d
    join public.subjects s on s.slug = 'fizika'
    join public.programs p on p.slug = 'orta'
    join public.levels   l on l.program_id = p.id and l.code = '7'
    join public.topics   tp on tp.subject_id = s.id and tp.slug = 'fiz-7-olcme'
  on conflict (ext_key) do update
    set body = excluded.body, explanation = excluded.explanation,
        difficulty = excluded.difficulty, status = 'published'
  returning id, ext_key
)
insert into public.question_options (question_id, ord, body, is_correct)
select ins.id, o.ord, o.txt, o.ord = d.correct::int
  from ins
  join d on d.ext = ins.ext_key,
  lateral unnest(d.opts) with ordinality as o(txt, ord);

do $$
declare n int; k int;
begin
  select count(*) into n from public.questions
   where ext_key like 'fiz7-olcme#%' and ext_key ~ '#(3[1-4])$';
  if n <> 4 then
    raise exception '126: 4 sual gozlenilirdi, % tapildi', n;
  end if;
  select count(*) into k from public.questions q
   where q.ext_key like 'fiz7-olcme#%' and q.ext_key ~ '#(3[1-4])$'
     and ((select count(*) from public.question_options o
            where o.question_id = q.id) <> 4
       or (select count(*) from public.question_options o
            where o.question_id = q.id and o.is_correct) <> 1);
  if k > 0 then
    raise exception '126: % sualda variant qurulusu sehvdir', k;
  end if;
  raise notice '126 OK - 4 sual elave olundu (fiz-7-olcme, skalyar/vektorial kemiyyet).';
end $$;
