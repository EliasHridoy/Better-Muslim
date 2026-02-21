import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  String? _userId;
  final FirestoreService _firestoreService = FirestoreService();

  ThemeProvider() : _isDarkMode = LocalStorageService.getDarkMode();

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Call on login to load the user's saved preference from Firestore.
  Future<void> connectUser(String userId) async {
    _userId = userId;
    try {
      final user = await _firestoreService.getUser(userId);
      if (user != null) {
        // Check if user doc has a darkMode field
        final doc = await _firestoreService.getUserDoc(userId);
        if (doc != null && doc.containsKey('darkMode')) {
          _isDarkMode = doc['darkMode'] as bool? ?? false;
          LocalStorageService.setDarkMode(_isDarkMode);
          notifyListeners();
        } else {
          // Push current local preference to cloud
          _firestoreService.updateUserPreferences(userId, {'darkMode': _isDarkMode});
        }
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  void disconnectUser() {
    _userId = null;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    LocalStorageService.setDarkMode(_isDarkMode);

    // Sync to Firestore if logged in
    if (_userId != null) {
      _firestoreService.updateUserPreferences(_userId!, {'darkMode': _isDarkMode});
    }

    notifyListeners();
  }
}
