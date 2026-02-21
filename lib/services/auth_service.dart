import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // ─── Action Code Settings ─────────────────────────────
  ActionCodeSettings _getActionCodeSettings() {
    // For web, use the current URL; for mobile, use the dynamic link domain
    final url = kIsWeb
        ? Uri.base.toString()
        : 'https://better-muslim-2.firebaseapp.com/__/auth/action';

    return ActionCodeSettings(
      url: url,
      handleCodeInApp: true,
      iOSBundleId: 'com.bettermuslim.betterMuslim',
      androidPackageName: 'com.bettermuslim.better_muslim',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );
  }

  // ─── Send Sign-In Link ────────────────────────────────
  Future<void> sendSignInLink({required String email}) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: _getActionCodeSettings(),
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ─── Check if Link is Valid ───────────────────────────
  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  // ─── Sign In with Email Link ──────────────────────────
  Future<User?> signInWithEmailLink({
    required String email,
    required String link,
  }) async {
    try {
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ─── Create User Document ─────────────────────────────
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
  }) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      // New user — create document
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'photoUrl': null,
        'totalPoints': 0,
        'tier': 'Bronze',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Existing user — update name if provided and different
      final data = doc.data();
      if (data != null && name.isNotEmpty && data['name'] != name) {
        await _firestore.collection('users').doc(uid).update({'name': name});
      }
    }
  }

  // ─── Update Display Name ──────────────────────────────
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Get user-friendly error message ──────────────────
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Email link sign-in is not enabled. Please contact support.';
      case 'expired-action-code':
        return 'This sign-in link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This sign-in link is invalid. Please request a new one.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
