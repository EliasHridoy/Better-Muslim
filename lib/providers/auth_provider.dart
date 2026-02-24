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
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  String? get error => _error;
  String get displayName =>
      _userModel?.name ?? _firebaseUser?.displayName ?? 'Muslim User';

  AuthProvider() {
    _firebaseUser = _authService.currentUser;
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _firebaseUser = user;
    if (user != null) {
      _loadUserModel(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    _userModel = await _firestoreService.getUser(uid);
    notifyListeners();
  }

  // ─── Sign Up ───────────────────────────────────────────
  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        _firebaseUser = user;
        _userModel = UserModel(
          id: user.uid,
          name: name,
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

  // ─── Sign In ───────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _firebaseUser = user;
        await _loadUserModel(user.uid);
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
  // ─── Reset Password ──────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email: email);
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

  // ─── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
    await LocalStorageService.clearUserData();
    _firebaseUser = null;
    _userModel = null;
    notifyListeners();
  }

  // ─── Sync points to Firestore ──────────────────────────
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
