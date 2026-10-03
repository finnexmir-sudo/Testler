# push-send — telefona bildiriş göndərici

Növbədəki bildirişləri (`push_outbox`, `db/910`) göndərir. Cron hər dəqiqə çağırır.

## Bir dəfəlik quraşdırma

1. **SQL:** `db/910_push.sql` məzmununu Supabase → SQL Editor-da işlədin. Sonra `db/test/canli_yoxla.sql`-də 910 sətri `true` olmalıdır.
2. **VAPID açarları:** `tools/vapid.html` faylını brauzerdə açın, «Yeni açarlar yarat». İki açarı kopyalayın.
3. **Açıq açar:** `sagird/config.js` və `valideyn/config.js`-də `VAPID_PUBLIC: "..."` sətrinə yazın (gizli açar YOX).
4. **Edge Function:** Supabase → Edge Functions → **Deploy a new function** → adı `push-send` → `index.ts` məzmununu yapışdırın.
   - **Verify JWT** seçimini **söndürün** (çağıranın JWT-si yoxdur; qapı `PUSH_SECRET`-dir).
5. **Sirlər** (Edge Functions → Secrets):
   | Ad | Dəyər |
   |---|---|
   | `VAPID_PUBLIC` | açıq açar (3-cü addımdakı ilə eyni) |
   | `VAPID_PRIVATE` | gizli açar |
   | `VAPID_SUBJECT` | `mailto:sizin-poçt@...` (yalnız push xidmətləri görür) |
   | `PUSH_SECRET` | özünüzün uydurduğunuz uzun təsadüfi söz |
6. **Planlayıcı** (Database → Extensions-da `pg_cron` və `pg_net` aktiv olmalıdır). SQL Editor-da (yer tutucuları dəyişin):

```sql
select cron.schedule('push-send', '* * * * *', $$
  select net.http_post(
    url     := 'https://<PROYEKT>.supabase.co/functions/v1/push-send',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', '<PUSH_SECRET>'),
    body    := '{}'::jsonb);
$$);
```
Dayandırmaq: `select cron.unschedule('push-send');`

7. **Açarı yandırın** (hamısı hazır olandan sonra):
```sql
update public.app_state set val = '{"on": true}' where key = 'push';
```
Əvvəlki vəziyyət: `{"on": false}` — növbəyə yazılmır və göndərici heç nə almır.

## Sınaq (öz telefonunuzda)

1. Şagird səhifəsini açın → «Bildirişləri aç» → icazə verin.
2. SQL Editor-da (şagirdin giriş kodunu yazın):
```sql
select app.push_enqueue('student',
  (select id from public.students where login_code = 'SAGIRD_KODU'),
  'test', null, 'Bil10 · Sınaq', 'Bildiriş işləyir ✓', './sagird/');
```
3. Ən çox 1 dəqiqəyə telefona bildiriş gəlməlidir. Gəlməsə: Edge Functions → push-send → Logs.

## Təhlükəsizlik
- `PUSH_SECRET` olmadan və ya səhv olarsa funksiya 401 qaytarır.
- Abunə ünvanı yalnız FCM / Mozilla / Apple / Windows push xidmətlərindən ola bilər (SSRF qorumasıdır).
- Gizli açar yalnız Supabase sirlərində qalır.
