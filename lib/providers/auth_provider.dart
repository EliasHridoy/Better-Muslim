import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isLinkSent = false;
  String? _error;
  String? _pendingEmail;
  String? _pendingName;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isLinkSent => _isLinkSent;
  String? get error => _error;
  String? get pendingEmail => _pendingEmail;
  String get displayName =>
      _userModel?.name ?? _firebaseUser?.displayName ?? 'Muslim User';

  AuthProvider() {
    _firebaseUser = _authService.currentUser;
    _authService.authStateChanges.listen(_onAuthStateChanged);
    // Restore pending email if the user closed the app before clicking the link
    _pendingEmail = LocalStorageService.getPendingEmail();
    _pendingName = LocalStorageService.getPendingName();
  }

  void _onAuthStateChanged(User? user) {
    _firebaseUser = user;
    if (user != null) {
      _loadUserModel(user.uid);
      // Clear pending data on successful sign-in
      _pendingEmail = null;
      _pendingName = null;
      _isLinkSent = false;
      LocalStorageService.clearPendingAuth();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    _userModel = await _firestoreService.getUser(uid);
    notifyListeners();
  }

  // ─── Send Sign-In Link ────────────────────────────────
  Future<bool> sendSignInLink(String email, {String name = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendSignInLink(email: email);

      // Store pending info locally so it survives app restarts
      _pendingEmail = email;
      _pendingName = name;
      _isLinkSent = true;
      await LocalStorageService.setPendingEmail(email);
      if (name.isNotEmpty) {
        await LocalStorageService.setPendingName(name);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _error = e.message ?? 'A Firebase error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Handle Incoming Email Link ───────────────────────
  Future<bool> handleEmailLink(String link) async {
    if (!_authService.isSignInWithEmailLink(link)) return false;

    final email = _pendingEmail ?? LocalStorageService.getPendingEmail();
    if (email == null || email.isEmpty) {
      _error = 'Please enter your email again to complete sign-in.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailLink(
        email: email,
        link: link,
      );

      if (user != null) {
        _firebaseUser = user;
        final name = _pendingName ?? LocalStorageService.getPendingName() ?? '';

        // Update display name
        if (name.isNotEmpty) {
          await _authService.updateDisplayName(name);
        }

        // Create or update user document in Firestore
        await _authService.createUserDocument(
          uid: user.uid,
          name: name,
          email: email,
        );

        // Load user model
        _userModel = await _firestoreService.getUser(user.uid);

        _userModel ??= UserModel(
            id: user.uid,
            name: name.isEmpty ? 'Muslim User' : name,
            email: email,
            totalPoints: LocalStorageService.getTotalPoints(),
            tier: 'Bronze',
          );

        // Sync local points to cloud
        await _firestoreService.updateUserPoints(
          user.uid,
          _userModel!.totalPoints,
          _userModel!.tier,
        );

        // Clear pending auth data
        _pendingEmail = null;
        _pendingName = null;
        _isLinkSent = false;
        await LocalStorageService.clearPendingAuth();
      }

      _isLoading = false;
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _error = e.message ?? 'A Firebase error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
    _firebaseUser = null;
    _userModel = null;
    notifyListeners();
  }

  // ─── Sync points to Firestore ─────────────────────────
  Future<void> syncPoints(int totalPoints, String tier) async {
    if (!isLoggedIn) return;
    _userModel = _userModel?.copyWith(totalPoints: totalPoints, tier: tier);
    await _firestoreService.updateUserPoints(
      _firebaseUser!.uid,
      totalPoints,
      tier,
    );
    notifyListeners();
  }

  // ─── Reset link-sent state ────────────────────────────
  void resetLinkSent() {
    _isLinkSent = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
