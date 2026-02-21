/// Curated duas for specific prayer times and general use.
class DuaService {
  // ─── Fajr Duas (morning supplications) ──────────────────
  static const List<Dua> fajrDuas = [
    Dua(
      arabic: 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
      translation: 'O Allah, by Your leave we have reached the morning and by Your leave we have reached the evening. By Your leave we live and die, and unto You is our resurrection.',
      reference: 'Tirmidhi',
    ),
    Dua(
      arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      translation: 'We have reached the morning and at this very time all sovereignty belongs to Allah. All praise is for Allah. None has the right to be worshipped except Allah, alone, without any partner.',
      reference: 'Muslim',
    ),
    Dua(
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
      translation: 'O Allah, I ask You for beneficial knowledge, good provision, and acceptable deeds.',
      reference: 'Ibn Majah',
    ),
    Dua(
      arabic: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي',
      translation: 'O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health.',
      reference: 'Abu Dawud',
    ),
    Dua(
      arabic: 'رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ وَأَعُوذُ بِكَ رَبِّ أَنْ يَحْضُرُونِ',
      translation: 'My Lord, I seek refuge in You from the incitements of the devils, and I seek refuge in You, my Lord, lest they be present with me.',
      reference: "Al-Mu'minun 23:97-98",
    ),
  ];

  // ─── Isha Duas (evening / night supplications) ──────────
  static const List<Dua> ishaDuas = [
    Dua(
      arabic: 'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
      translation: 'O Allah, by Your leave we have reached the evening and by Your leave we have reached the morning. By Your leave we live and die, and unto You is our return.',
      reference: 'Tirmidhi',
    ),
    Dua(
      arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ مَا عَمِلْتُ وَمِنْ شَرِّ مَا لَمْ أَعْمَلْ',
      translation: 'O Allah, I seek refuge in You from the evil of what I have done and from the evil of what I have not done.',
      reference: 'Muslim',
    ),
    Dua(
      arabic: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
      translation: 'O Allah, protect me from Your punishment on the Day You resurrect Your servants.',
      reference: 'Abu Dawud',
    ),
    Dua(
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      translation: 'In Your name O Allah, I die and I live.',
      reference: 'Bukhari',
    ),
    Dua(
      arabic: 'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ وَفَوَّضْتُ أَمْرِي إِلَيْكَ وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ',
      translation: 'O Allah, I submit myself to You, and I entrust my affairs to You, and I turn my back to You for refuge.',
      reference: 'Bukhari & Muslim',
    ),
  ];

  /// Get a random Fajr dua
  static Dua getRandomFajrDua() {
    final index = DateTime.now().microsecond % fajrDuas.length;
    return fajrDuas[index];
  }

  /// Get a random Isha dua
  static Dua getRandomIshaDua() {
    final index = DateTime.now().microsecond % ishaDuas.length;
    return ishaDuas[index];
  }
}

class Dua {
  final String arabic;
  final String translation;
  final String reference;

  const Dua({
    required this.arabic,
    required this.translation,
    required this.reference,
  });
}
