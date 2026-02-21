class AppConstants {
  // Default prayers
  static const List<String> defaultPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  // Default Tasbih phrases
  static const List<String> defaultTasbih = [
    'SubhanAllah',
    'Alhamdulillah',
    'Allahu Akbar',
    'Astaghfirullah',
  ];

  // Points
  static const int pointsPerTask = 1;
  static const int pointsPerFriend = 5;

  // Tiers
  static const int bronzeMin = 0;
  static const int silverMin = 100;
  static const int goldMin = 500;
  static const int platinumMin = 2000;

  // Hive box names
  static const String userBox = 'user_box';
  static const String tasksBox = 'tasks_box';
  static const String entriesBox = 'entries_box';
  static const String settingsBox = 'settings_box';
  static const String charityEntriesBox = 'charity_entries_box';
  static const String syncBox = 'sync_box';
}
