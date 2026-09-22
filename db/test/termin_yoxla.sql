-- =====================================================================
--  termin_yoxla.sql : ARIFMETIK TERMINLERIN AUDITI (yalniz OXUYUR)
--
--  NIYE LAZIMDIR
--  2026-09-22: sagird Nergiz A. bir sualı «Şərt qüsurludur» deyə
--  bildirdi: «Çıxılan 600, fərq 250-dirsə, ÇIXAN neçədir?»  Iki qusur
--  var idi - «çıxan» termin deyil, «çıxılan» ise AZALAN menasinda
--  islenmisdi.  Duzgun cavab 350 isarelenmisdi; halbuki duzgun
--  terminle oxusaq cavab 850 olmali idi (o da variantlar arasinda!).
--  Bir sualda bele qarisiqliq varsa, qonsularinda da ola biler.
--
--  DUZGUN TERMINLER (ibtidai kurikulum)
--    toplama :  toplanan + toplanan = cem
--    cixma   :  AZALAN - CIXILAN = ferq
--    vurma   :  vuruq x vuruq = hasil
--    bolme   :  bolunen : bolen = qismet
--
--  ISTIFADE:  Supabase -> SQL Editor -> bunu yapisdir -> Run.
--  Cavab bir cedveldir.  «sebeb» sutunu niye isarelendiyini deyir,
--  «duz_cavab» ise isarelenmis cavabdir - goz bir baxisda tutur.
--  HEC NE DEYISMIR: sirf select.  Duzelisi panelden el ile edirsen.
--
--  REGEX QEYDI: hem «ç/ı/ə», hem ASCII yazilisi («c/i/e») tutulur -
--  bank metnlerinde ikisi de rast gelir.  «\m...\M» soz serhedi
--  Azerbaycan herflerinde etibarli deyil, ona gore acıq serhed:
--  (^|[^[:alnum:]]) ... ([^[:alnum:]]|$).
--
--  22.09: «iki emelin termini bir sualda» qaydasi CIXARILDI.  35 setir
--  verdi, icinde bir dene de qusur yox idi: «İki ədədin cəmi 480,
--  fərqi 80-dir» kimi tamamile duzgun cumleler idi.  Tutmayan suzgec
--  ziyandir - goz oyrenir, sonra esl tapintini da atlayir.
--
--  QEYD: bu bir suzgecdir, hokm deyil.  Isarelenen her sual qusurlu
--  demek deyil - insan oxuyub qerar verir.
-- =====================================================================
with s as (
  select q.id,
         coalesce(sub.name, '?')                      as fenn,
         coalesce(lv.code, '?')                       as sinif,
         coalesce(t.name, '(movzusuz)')               as movzu,
         case q.owner_type when 'platform' then 'bank' else 'muellim' end as sahib,
         q.body,
         --  22.09: EVVEL yalniz q.body suzulurdu - «explanation»
         --  unudulmusdu ve izahlarda kohne termin qalmisdi
         --  (istifadeci panelde gordu).  Indi ikisi birlikde.
         coalesce(q.explanation, '')                  as izah,
         lower(q.body || ' ' || coalesce(q.explanation, '')) as gov,
         (select string_agg(o.body, ' | ' order by o.ord)
            from public.question_options o
           where o.question_id = q.id and o.is_correct) as duz_cavab
    from public.questions q
    left join public.subjects sub on sub.id = q.subject_id
    left join public.levels   lv  on lv.id  = q.level_id
    left join public.topics   t   on t.id   = q.topic_id
   where q.status <> 'archived'
),
--  terminlerin hansi ailelerden oldugu
b as (
  select s.*,
         gov ~ '(azalan|[cç][ıi]x[ıi]lan|f[əe]rq)'                 as cixma_ail,
         gov ~ '(toplanan|c[əe]m)'                              as topl_ail,
         gov ~ '(vuruq|hasil)'                                  as vurma_ail,
         gov ~ '(b[öo]l[üu]n[əe]n|b[öo]l[əe]n|qism[əe]t)'       as bolme_ail,
         --  «çıxan» / «toplayan» / «vuran» ARIFMETIK TERMIN DEYIL
         gov ~ '(^|[^[:alnum:]])[cç][ıi]xan([^[:alnum:]]|$)'                                   as uydurma_cixan,
         gov ~ '(^|[^[:alnum:]])toplayan([^[:alnum:]]|$)'                                   as uydurma_toplayan,
         gov ~ '(^|[^[:alnum:]])vuran([^[:alnum:]]|$)'                                      as uydurma_vuran,
         gov ~ '[cç][ıi]x[ıi]lan'                                  as var_cixilan,
         gov ~ 'azalan'                                         as var_azalan,
         gov ~ 'f[əe]rq'                                        as var_ferq
    from s
)
select sebeb, fenn, sinif, movzu, sahib, body as sual, duz_cavab, id
from (
  --  1) Uydurma termin: cixmada «çıxan» kimi soz var
  select 1 as sira,
         'uydurma termin: «' ||
           case when uydurma_cixan     then 'çıxan'
                when uydurma_toplayan  then 'toplayan'
                else 'vuran' end || '»' as sebeb,
         b.*
    from b
   where (uydurma_cixan and (cixma_ail or gov ~ '[cç][ıi]xma'))
      or (uydurma_toplayan and topl_ail)
      or (uydurma_vuran and vurma_ail)

  union all
  --  2) Qarisiqliq subhesi: «çıxılan» + «fərq» var, «azalan» YOXDUR.
  --     Cixmanin uc uzvunden ikisi verilirse, ucuncusu sorusulur -
  --     burada sorusulan azalandir, amma adi cekilmir.  Mehz bizim
  --     tutdugumuz sualin qelibi budur.
  select 2,
         'azalan/çıxılan qarışığı ola bilər (azalan sözü yoxdur)',
         b.*
    from b
   where var_cixilan and var_ferq and not var_azalan

  union all
  --  3) Terminli sualda variant YOXDUR ve ya duz cavab isarelenmeyib
  select 3,
         'termin var, amma düz cavab işarələnməyib',
         b.*
    from b
   where (cixma_ail or topl_ail or vurma_ail or bolme_ail)
     and duz_cavab is null
) x
order by sira, fenn, sinif, movzu;
