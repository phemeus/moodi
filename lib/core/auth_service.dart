import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'secure_email_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Kullanıcı durumu stream'i
  Stream<User?> get authState => _auth.authStateChanges().handleError((error) {
    print('Auth state error: $error');
    return null;
  });

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Google ile giriş
  Future<void> signInWithGoogle() async {
    try {
      // Önce mevcut oturumu temizle
      await _googleSignIn.signOut();
      
      // Google Sign-In'i başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google girişi iptal edildi');
      }

      // Google authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Token kontrolü
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google authentication token alınamadı');
      }

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      await _auth.signInWithCredential(credential);
      
      // Google hesap bilgilerini güvenli şekilde kaydet
      try {
        await SecureEmailService.addEmailAccount(
          email: googleUser.email,
          password: 'Google OAuth', // Google hesapları için özel işaret
          displayName: googleUser.displayName,
          provider: 'google.com',
        );
      } catch (e) {
        // Email kaydetme hatası giriş işlemini engellemez
        print('Google hesap bilgileri kaydedilemedi: $e');
      }
      
      notifyListeners();
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw _mapAuthError(e);
    }
  }

  // Email/şifre ile giriş
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Email hesabını güvenli şekilde kaydet
      try {
        await SecureEmailService.addEmailAccount(
          email: email,
          password: password,
          displayName: email.split('@')[0],
          provider: email.split('@')[1],
        );
      } catch (e) {
        // Email kaydetme hatası giriş işlemini engellemez
        print('Email hesabı kaydedilemedi: $e');
      }
      
      notifyListeners();
    } catch (e) {
      throw _mapAuthError(e);
    }
  }

  // Email/şifre ile kayıt
  Future<void> registerWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Email hesabını güvenli şekilde kaydet
      try {
        await SecureEmailService.addEmailAccount(
          email: email,
          password: password,
          displayName: email.split('@')[0],
          provider: email.split('@')[1],
        );
      } catch (e) {
        // Email kaydetme hatası kayıt işlemini engellemez
        print('Email hesabı kaydedilemedi: $e');
      }
      
      notifyListeners();
    } catch (e) {
      throw _mapAuthError(e);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw _mapAuthError(e);
    }
  }

  // Firebase hatalarını Türkçe mesajlara çevir
  String _mapAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
        case 'wrong-password':
          return 'Hatalı şifre';
        case 'email-already-in-use':
          return 'Bu email adresi zaten kullanımda';
        case 'weak-password':
          return 'Şifre çok zayıf (en az 6 karakter)';
        case 'invalid-email':
          return 'Geçersiz email adresi';
        case 'user-disabled':
          return 'Hesap devre dışı bırakılmış';
        case 'too-many-requests':
          return 'Çok fazla deneme yapıldı, lütfen bekleyin';
        case 'network-request-failed':
          return 'İnternet bağlantısı hatası';
        case 'account-exists-with-different-credential':
          return 'Bu email adresi farklı bir yöntemle kayıtlı';
        case 'invalid-credential':
          return 'Geçersiz kimlik bilgileri';
        case 'operation-not-allowed':
          return 'Bu işlem desteklenmiyor';
        case 'user-mismatch':
          return 'Kullanıcı uyumsuzluğu';
        case 'requires-recent-login':
          return 'Güvenlik için tekrar giriş yapın';
        default:
          return 'Giriş yapılamadı: ${error.message}';
      }
    } else if (error is Exception) {
      final errorMessage = error.toString();
      if (errorMessage.contains('Google girişi iptal edildi')) {
        return 'Google girişi iptal edildi';
      } else if (errorMessage.contains('Google authentication token alınamadı')) {
        return 'Google kimlik doğrulama hatası';
      } else if (errorMessage.contains('network')) {
        return 'İnternet bağlantısı hatası';
      } else {
      return 'Beklenmeyen hata: $error';
      }
    } else {
      return 'Bilinmeyen hata oluştu';
    }
  }

  // Kullanıcı bilgilerini al
  String getUserDisplayName() {
    final user = currentUser;
    if (user == null) return 'Misafir';
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    if (user.email != null) {
      return user.email!.split('@')[0];
    }
    
    return 'Kullanıcı';
  }

  // Google hesabı mı kontrol et
  bool isGoogleAccount() {
    final user = currentUser;
    if (user == null) return false;
    
    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }
} 