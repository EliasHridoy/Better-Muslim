import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Model for a single prayer time.
class PrayerTime {
  final String name;
  final TimeOfDay time;
  final String formatted;
  final IconData icon;

  const PrayerTime({
    required this.name,
    required this.time,
    required this.formatted,
    required this.icon,
  });
}

/// Fetches daily prayer times from the Aladhan API.
class PrayerTimesService {
  static const _baseUrl = 'https://api.aladhan.com/v1';

  /// Get prayer times for a given date and location.
  /// Uses method 2 (ISNA) by default.
  static Future<List<PrayerTime>> getPrayerTimes({
    double latitude = 23.8103, // Default: Dhaka
    double longitude = 90.4125,
    int? method,
  }) async {
    try {
      final now = DateTime.now();
      final date = '${now.day.toString().padLeft(2, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-${now.year}';

      final url = Uri.parse(
        '$_baseUrl/timings/$date'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&method=${method ?? 2}',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return _fallbackTimes();

      final data = jsonDecode(response.body);
      final timings = data['data']['timings'] as Map<String, dynamic>;

      return [
        _parse('Fajr', timings['Fajr'], Icons.nights_stay_rounded),
        _parse('Sunrise', timings['Sunrise'], Icons.wb_twilight_rounded),
        _parse('Dhuhr', timings['Dhuhr'], Icons.wb_sunny_rounded),
        _parse('Asr', timings['Asr'], Icons.sunny_snowing),
        _parse('Maghrib', timings['Maghrib'], Icons.wb_twilight_rounded),
        _parse('Isha', timings['Isha'], Icons.dark_mode_rounded),
      ];
    } catch (e) {
      debugPrint('Prayer times API error: $e');
      return _fallbackTimes();
    }
  }

  static PrayerTime _parse(String name, String? raw, IconData icon) {
    if (raw == null) {
      return PrayerTime(
        name: name,
        time: const TimeOfDay(hour: 0, minute: 0),
        formatted: '--:--',
        icon: icon,
      );
    }

    // API returns "HH:mm (TZ)" — strip timezone part
    final clean = raw.split(' ').first;
    final parts = clean.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    String period = 'AM';
    int hour12 = hour;
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour12 -= 12;
    }
    if (hour12 == 0) hour12 = 12;
    
    final formatted12h = '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

    return PrayerTime(
      name: name,
      time: TimeOfDay(hour: hour, minute: minute),
      formatted: formatted12h,
      icon: icon,
    );
  }

  static List<PrayerTime> _fallbackTimes() {
    return [
      const PrayerTime(
          name: 'Fajr',
          time: TimeOfDay(hour: 5, minute: 0),
          formatted: '05:00 AM',
          icon: Icons.nights_stay_rounded),
      const PrayerTime(
          name: 'Sunrise',
          time: TimeOfDay(hour: 6, minute: 15),
          formatted: '06:15 AM',
          icon: Icons.wb_twilight_rounded),
      const PrayerTime(
          name: 'Dhuhr',
          time: TimeOfDay(hour: 12, minute: 30),
          formatted: '12:30 PM',
          icon: Icons.wb_sunny_rounded),
      const PrayerTime(
          name: 'Asr',
          time: TimeOfDay(hour: 15, minute: 45),
          formatted: '03:45 PM',
          icon: Icons.sunny_snowing),
      const PrayerTime(
          name: 'Maghrib',
          time: TimeOfDay(hour: 18, minute: 15),
          formatted: '06:15 PM',
          icon: Icons.wb_twilight_rounded),
      const PrayerTime(
          name: 'Isha',
          time: TimeOfDay(hour: 19, minute: 45),
          formatted: '07:45 PM',
          icon: Icons.dark_mode_rounded),
    ];
  }
}
