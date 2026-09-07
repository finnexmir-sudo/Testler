/* Supabase layihenizin melumatlari.
   ANON acar ictimaidir - o, brauzerdeki her sorguda gedir, gizletmeye
   ehtiyac yoxdur. Mudafie RLS-dedir.
   SERVICE_ROLE acarini bura HEC VAXT yazma - o, butun RLS-i kecir. */
window.CFG = {
  SUPABASE_URL: "https://trsgfmlfiuozscjzkkjp.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_MNyO1nTpvz05LYUKxX0-Jg_eyDbVrv_",   // Supabase -> Settings -> API Keys -> anon public
  STUDENT_URL: "https://bil10.az/sagird/",  // sagird tetbiqi
  PARENT_URL:  "https://bil10.az/valideyn/",  // valideyn tetbiqi
  CONTACT_WHATSAPP: "+994702023080",  // paket/sual ucun WhatsApp (reklamdaki nomre)
  //  Paket/qiymet bolmesi gorunsunmu?  false olanda alt menyudan,
  //  suretli emeliyyatlardan ve unvandan gizlenir.  Satisa hazir
  //  olanda true et - basqa hec ne deyismir.
  SHOW_PLANS: false
};
