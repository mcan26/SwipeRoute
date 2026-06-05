class AppTranslations {
  static bool isEnglish = false;

  static const Map<String, Map<String, String>> _dict = {
    'tab_vibe': {
      'tr': 'Vibe Check',
      'en': 'Vibe Check',
    },
    'tab_discovery': {
      'tr': 'Mekan Havuzu',
      'en': 'Discovery Hub',
    },
    'tab_routes': {
      'tr': 'Rotalarım',
      'en': 'My Routes',
    },
    'tab_profile': {
      'tr': 'Profil',
      'en': 'Profile',
    },
    'settings_title': {
      'tr': 'Ayarlar & Modlar',
      'en': 'Settings & Modes',
    },
    'settings_offline': {
      'tr': 'Sadece Çevrimdışı (Yerel Veri)',
      'en': 'Offline Mode (Local Data)',
    },
    'settings_offline_desc': {
      'tr': 'İnternet veya Supabase olmadan çalışır.',
      'en': 'Works without Internet or Supabase.',
    },
    'settings_lang': {
      'tr': 'Dil (Language)',
      'en': 'Language (Dil)',
    },
    'settings_lang_desc': {
      'tr': 'Uygulama dilini İngilizce yap.',
      'en': 'Switch application language to English.',
    },
  };

  static String t(String key) {
    final lang = isEnglish ? 'en' : 'tr';
    return _dict[key]?[lang] ?? key;
  }
}
