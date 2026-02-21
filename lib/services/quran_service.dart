import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Model for a Quran verse.
class QuranVerse {
  final String arabic;
  final String translation;
  final String reference; // e.g. "Al-Baqarah 2:255"

  const QuranVerse({
    required this.arabic,
    required this.translation,
    required this.reference,
  });
}

/// Fetches a random Quran verse from the Al-Quran Cloud API.
class QuranService {
  static const _baseUrl = 'https://api.alquran.cloud/v1';

  /// Get the verse of the day (based on the day of year for consistency).
  static Future<QuranVerse> getVerseOfTheDay() async {
    try {
      // Use day-of-year as seed for consistency within the same day
      final dayOfYear = DateTime.now().difference(
          DateTime(DateTime.now().year, 1, 1)).inDays + 1;
      // Quran has 6236 verses total
      final verseNumber = (dayOfYear % 6236) + 1;

      final url = Uri.parse('$_baseUrl/ayah/$verseNumber/editions/quran-uthmani,en.sahih');
      final response = await http.get(url);

      if (response.statusCode != 200) return _fallbackVerse();

      final data = jsonDecode(response.body);
      final editions = data['data'] as List;

      final arabic = editions[0];
      final english = editions[1];

      final surahName = arabic['surah']['englishName'];
      final surahNumber = arabic['surah']['number'];
      final ayahNumber = arabic['numberInSurah'];

      return QuranVerse(
        arabic: arabic['text'] ?? '',
        translation: english['text'] ?? '',
        reference: '$surahName $surahNumber:$ayahNumber',
      );
    } catch (e) {
      debugPrint('Quran API error: $e');
      return _fallbackVerse();
    }
  }

  /// Get a random inspirational verse from a curated list.
  static QuranVerse getRandomInspiration() {
    final random = Random();
    return _inspirationalVerses[random.nextInt(_inspirationalVerses.length)];
  }

  static QuranVerse _fallbackVerse() {
    return const QuranVerse(
      arabic: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      translation: 'For indeed, with hardship will be ease.',
      reference: 'Ash-Sharh 94:5',
    );
  }

  static const List<QuranVerse> _inspirationalVerses = [
    QuranVerse(
      arabic: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      translation: 'For indeed, with hardship will be ease.',
      reference: 'Ash-Sharh 94:5',
    ),
    QuranVerse(
      arabic: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
      translation: 'And whoever relies upon Allah - then He is sufficient for him.',
      reference: 'At-Talaq 65:3',
    ),
    QuranVerse(
      arabic: 'ادْعُونِي أَسْتَجِبْ لَكُمْ',
      translation: 'Call upon Me; I will respond to you.',
      reference: 'Ghafir 40:60',
    ),
    QuranVerse(
      arabic: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
      translation: 'Indeed, Allah is with the patient.',
      reference: 'Al-Baqarah 2:153',
    ),
    QuranVerse(
      arabic: 'وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ',
      translation: 'Do not despair of the mercy of Allah.',
      reference: 'Yusuf 12:87',
    ),
  ];
}
