/* Sagird tetbiqi - Supabase melumatlari.
   Bu qovluq muellim/config.js ile eyni deyerleri dasiyir.
   SERVICE_ROLE / secret acar bura HEC VAXT yazilmir. */
window.CFG = {
  SUPABASE_URL: "https://trsgfmlfiuozscjzkkjp.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_MNyO1nTpvz05LYUKxX0-Jg_eyDbVrv_",    // Supabase -> Settings -> API Keys -> publishable
  //  910: telefona bildiris - VAPID AÇIQ (public) açar.  BOŞ olanda bildiriş xidməti tam gizlidir.
  //  Gizli açar (VAPID_PRIVATE) bura HEÇ VAXT yazılmır - yalnız Supabase Edge Function sirlərində durur.
  VAPID_PUBLIC: ""
};
