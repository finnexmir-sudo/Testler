-- =====================================================================
--  smoke_sual_sekli.sql : sualin sekli (db/188)
--
--  Iddialar: app.svg_uri xam SVG-ni data-URI edir · platforma suali
--  sekil dasiya bilir · MUELLIM suali dasiya BILMIR · yanlis unvan
--  (javascript:, http:, adi metn) redd olunur · suphali soz (script,
--  onload, onerror) redd olunur · hedden boyuk sekil redd olunur.
--
--  Niye bu qeder qapi: sekil <img>-de cizilir, ona gore skript onsuz
--  da islemir - amma bir qat sehv edende ikincisi tutmalidir.
-- =====================================================================
\set ON_ERROR_STOP on
set client_min_messages = warning;

delete from public.questions where ext_key like 'sekil-smoke%';

do $$
declare v_subj uuid; v_id uuid; u text; bad boolean;
begin
  select id into v_subj from public.subjects limit 1;

  --  1. svg_uri
  u := app.svg_uri('<svg viewBox="0 0 10 10"><path d="M1 1h8"/></svg>');
  assert u like 'data:image/svg+xml,%', 'data-URI yaranmadi: ' || coalesce(u, 'null');
  assert position('<' in u) = 0, 'kodlasdirilmamis < qaldi';
  assert position('"' in u) = 0, 'kodlasdirilmamis " qaldi';
  assert app.svg_uri(null) is null, 'bos girisde null qaytarmadi';
  assert app.svg_uri('   ') is null, 'bosluqda null qaytarmadi';

  --  2. platforma suali - kecir
  insert into public.questions (ext_key, owner_type, subject_id, kind, body, media_url)
  values ('sekil-smoke#1', 'platform', v_subj, 'single', 'Ucbucaq',
          app.svg_uri('<svg viewBox="0 0 20 20"><path d="M2 18h16L10 2z"/></svg>'))
  returning id into v_id;
  assert v_id is not null, 'platforma sekli yazilmadi';

  --  3. muellim suali - REDD
  bad := false;
  begin
    insert into public.questions (ext_key, owner_type, subject_id, kind, body, media_url)
    values ('sekil-smoke#2', 'educator', v_subj, 'single', 'Muellim',
            'data:image/svg+xml,%3Csvg%3E%3C/svg%3E');
  exception when check_violation then bad := true;
  end;
  assert bad, 'MUELLIM suali sekil dasidi!';

  --  4. yanlis unvanlar - REDD
  foreach u in array array['javascript:alert(1)', 'http://a.az/x.svg',
                           'adi metn', 'data:text/html,%3Cb%3E'] loop
    bad := false;
    begin
      insert into public.questions (ext_key, owner_type, subject_id, kind, body, media_url)
      values ('sekil-smoke#3', 'platform', v_subj, 'single', 'Pis unvan', u);
    exception when check_violation then bad := true;
    end;
    assert bad, 'yanlis unvan kecdi: ' || u;
  end loop;

  --  5. suphali sozler - REDD
  foreach u in array array['data:image/svg+xml,%3Csvg%3E%3Cscript%3Ex',
                           'data:image/svg+xml,%3Csvg onload=x%3E',
                           'data:image/svg+xml,%3Cimg onerror=x%3E'] loop
    bad := false;
    begin
      insert into public.questions (ext_key, owner_type, subject_id, kind, body, media_url)
      values ('sekil-smoke#4', 'platform', v_subj, 'single', 'Supheli', u);
    exception when check_violation then bad := true;
    end;
    assert bad, 'suphali soz kecdi: ' || left(u, 40);
  end loop;

  --  6. hedden boyuk - REDD
  bad := false;
  begin
    insert into public.questions (ext_key, owner_type, subject_id, kind, body, media_url)
    values ('sekil-smoke#5', 'platform', v_subj, 'single', 'Boyuk',
            'data:image/svg+xml,' || repeat('a', 24001));
  exception when check_violation then bad := true;
  end;
  assert bad, '24 KB-dan boyuk sekil kecdi';
end $$;

--  7. RPC-ler sekli qaytarir (sutun onsuz da siyahidadir - yoxlanir)
do $$
declare n int;
begin
  select count(*) into n from public.questions
   where ext_key = 'sekil-smoke#1' and media_url is not null;
  assert n = 1, 'sekil bazada qalmadi';
end $$;

delete from public.questions where ext_key like 'sekil-smoke%';
\echo 'OK  1 · svg_uri; platforma sekli kecir; muellim/yanlis unvan/suphali soz/boyuk olcu redd'
