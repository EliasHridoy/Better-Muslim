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

  // ─── Sign Up ───────────────────────────────────────────
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create Firestore user document
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'photoUrl': null,
          'totalPoints': 0,
          'tier': 'Bronze',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ─── Sign In ───────────────────────────────────────────
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ─── Reset Password ──────────────────────────────────────
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Get user-friendly error message ───────────────────
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
