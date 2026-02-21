import 'package:flutter/material.dart';
import '../services/prayer_times_service.dart';

class PrayerTimesProvider extends ChangeNotifier {
  List<PrayerTime> _prayerTimes = [];
  PrayerTime? _nextPrayer;
  Duration _timeUntilNext = Duration.zero;
  bool _isLoading = true;
  String? _error;

  List<PrayerTime> get prayerTimes => _prayerTimes;
  PrayerTime? get nextPrayer => _nextPrayer;
  Duration get timeUntilNext => _timeUntilNext;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PrayerTimesProvider() {
    fetchPrayerTimes();
  }

  Future<void> fetchPrayerTimes({
    double latitude = 23.8103,
    double longitude = 90.4125,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _prayerTimes = await PrayerTimesService.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
      );
      _calculateNextPrayer();
      _error = null;
    } catch (e) {
      _error = 'Could not load prayer times';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _calculateNextPrayer() {
    final now = DateTime.now();
    final todayMinutes = now.hour * 60 + now.minute;

    for (final prayer in _prayerTimes) {
      final prayerMinutes = prayer.time.hour * 60 + prayer.time.minute;
      if (prayerMinutes > todayMinutes) {
        _nextPrayer = prayer;
        _timeUntilNext = Duration(minutes: prayerMinutes - todayMinutes);
        return;
      }
    }

    // All prayers passed — next is tomorrow's Fajr
    if (_prayerTimes.isNotEmpty) {
      _nextPrayer = _prayerTimes.first;
      final fajrMinutes =
          _prayerTimes.first.time.hour * 60 + _prayerTimes.first.time.minute;
      _timeUntilNext =
          Duration(minutes: (1440 - todayMinutes) + fajrMinutes);
    }
  }

  /// Format duration as "Xh Ym"
  String get timeUntilNextFormatted {
    final hours = _timeUntilNext.inHours;
    final minutes = _timeUntilNext.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
