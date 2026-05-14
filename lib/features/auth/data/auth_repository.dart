import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Email & password ile kayıt ol
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);
    // Firestore belgesi oluştur — hata olsa bile auth user oluşur, provider handle eder
    try {
      await _createUserDocument(cred.user!, displayName);
    } catch (_) {}
  }

  /// Email & password ile giriş yap
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Google ile giriş yap
  /// Web: Firebase signInWithPopup (sorunsuz çalışır)
  /// Mobil: google_sign_in paketi
  Future<void> signInWithGoogle() async {
    UserCredential userCred;

    if (kIsWeb) {
      // Web: Firebase Auth popup — google_sign_in paketi gerekmez
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      userCred = await _auth.signInWithPopup(provider);
    } else {
      // Mobil
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Kullanıcı iptal etti
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCred = await _auth.signInWithCredential(credential);
    }

    if (userCred.additionalUserInfo?.isNewUser == true) {
      try {
        await _createUserDocument(
          userCred.user!,
          userCred.user!.displayName ?? 'Savaşçı',
        );
      } catch (_) {}
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Firestore'da kullanıcı belgesi oluştur
  Future<void> _createUserDocument(User user, String displayName) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'displayName': displayName,
        'email': user.email,
        'level': 1,
        'xp': 0,
        'xpToNextLevel': 500,
        'streak': 0,
        'lastActiveDate': null,
        'title': 'Acemi Savaşçı',
        'stats': {
          'focus': 5,
          'energy': 5,
          'knowledge': 5,
          'strength': 5,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
