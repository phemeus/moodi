import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureEmailService {
  static const String _keyName = 'encryption_key';
  static const String _saltName = 'encryption_salt';
  static const String _ivName = 'encryption_iv';
  static const String _emailsKey = 'encrypted_emails';
  static const String _securityLevelKey = 'security_level';
  static const String _lastAccessKey = 'last_access_time';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutUntilKey = 'lockout_until';
  
  // Güvenlik sabitleri
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationMinutes = 30;
  static const int _sessionTimeoutMinutes = 15;
  
  // Flutter Secure Storage instance
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Local Auth instance
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Güvenlik seviyesi kontrolü
  static Future<bool> _checkSecurityLevel() async {
    try {
      final level = await _secureStorage.read(key: _securityLevelKey);
      return level == 'enterprise';
    } catch (e) {
      return false;
    }
  }
  
  // Biyometrik kimlik doğrulama
  static Future<bool> _authenticateBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      if (!canCheckBiometrics) {
        return false;
      }
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return false;
      }
      
      return await _localAuth.authenticate(
        localizedReason: 'Email hesaplarınıza erişim için kimlik doğrulama gerekli',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
  
  // Brute force koruması
  static Future<bool> _checkBruteForceProtection() async {
    try {
      final failedAttempts = await _secureStorage.read(key: _failedAttemptsKey);
      final lockoutUntil = await _secureStorage.read(key: _lockoutUntilKey);
      
      if (lockoutUntil != null) {
        final lockoutTime = DateTime.parse(lockoutUntil);
        if (DateTime.now().isBefore(lockoutTime)) {
          throw Exception('Çok fazla başarısız deneme. Lütfen ${_lockoutDurationMinutes} dakika bekleyin.');
        }
        // Lockout süresi dolmuş, sıfırla
        await _secureStorage.delete(key: _lockoutUntilKey);
        await _secureStorage.delete(key: _failedAttemptsKey);
      }
      
      final attempts = int.tryParse(failedAttempts ?? '0') ?? 0;
      if (attempts >= _maxFailedAttempts) {
        final lockoutTime = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes));
        await _secureStorage.write(key: _lockoutUntilKey, value: lockoutTime.toIso8601String());
        throw Exception('Çok fazla başarısız deneme. Hesap ${_lockoutDurationMinutes} dakika kilitlendi.');
      }
      
      return true;
    } catch (e) {
      rethrow;
    }
  }
  
  // Session timeout kontrolü
  static Future<bool> _checkSessionTimeout() async {
    try {
      final lastAccess = await _secureStorage.read(key: _lastAccessKey);
      if (lastAccess == null) return false;
      
      final lastAccessTime = DateTime.parse(lastAccess);
      final timeoutTime = lastAccessTime.add(Duration(minutes: _sessionTimeoutMinutes));
      
      if (DateTime.now().isAfter(timeoutTime)) {
        await _secureStorage.delete(key: _lastAccessKey);
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Güvenli salt oluşturma
  static Future<String> _generateSecureSalt() async {
    final random = Random.secure();
    final salt = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(salt);
  }
  
  // Güvenli IV oluşturma
  static Future<String> _generateSecureIV() async {
    final random = Random.secure();
    final iv = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(iv);
  }
  
  // Şifreleme anahtarı oluştur veya mevcut olanı al
  static Future<Encrypter> _getEncrypter() async {
    try {
      // Güvenlik kontrolleri
      await _checkBruteForceProtection();
      
      // Biyometrik kimlik doğrulama
      final isAuthenticated = await _authenticateBiometric();
      if (!isAuthenticated) {
        throw Exception('Biyometrik kimlik doğrulama başarısız');
      }
      
      // Session kontrolü
      final hasValidSession = await _checkSessionTimeout();
      if (!hasValidSession) {
        // Yeni session başlat
        await _secureStorage.write(
          key: _lastAccessKey, 
          value: DateTime.now().toIso8601String()
        );
      }
      
      // Şifreleme anahtarını güvenli depolamadan al
      String? keyString = await _secureStorage.read(key: _keyName);
      String? saltString = await _secureStorage.read(key: _saltName);
      String? ivString = await _secureStorage.read(key: _ivName);
      
      if (keyString == null || saltString == null || ivString == null) {
        // Yeni güvenlik parametreleri oluştur
        saltString = await _generateSecureSalt();
        ivString = await _generateSecureIV();
        
        // Anahtar oluştur ve güvenli depolamaya kaydet
        final key = Key.fromSecureRandom(32);
        keyString = base64.encode(key.bytes);
        
        await _secureStorage.write(key: _keyName, value: keyString);
        await _secureStorage.write(key: _saltName, value: saltString);
        await _secureStorage.write(key: _ivName, value: ivString);
        
        // Güvenlik seviyesini ayarla
        await _secureStorage.write(key: _securityLevelKey, value: 'enterprise');
      }
      
      final key = Key.fromBase64(keyString);
      return Encrypter(AES(key));
    } catch (e) {
      // Başarısız deneme sayısını artır
      await _incrementFailedAttempts();
      rethrow;
    }
  }
  
  // Başarısız deneme sayısını artır
  static Future<void> _incrementFailedAttempts() async {
    try {
      final failedAttempts = await _secureStorage.read(key: _failedAttemptsKey);
      final attempts = int.tryParse(failedAttempts ?? '0') ?? 0;
      await _secureStorage.write(key: _failedAttemptsKey, value: (attempts + 1).toString());
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Başarılı kimlik doğrulama sonrası deneme sayısını sıfırla
  static Future<void> _resetFailedAttempts() async {
    try {
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Checksum oluşturma
  static String _generateChecksum(String data) {
    final bytes = utf8.encode(data);
    int checksum = 0;
    for (int byte in bytes) {
      checksum = (checksum + byte) % 65521;
    }
    return checksum.toString();
  }
  
  // Şifrelenmiş email listesini güvenli depolamadan al
  static Future<List<String>> _getEncryptedEmailsList() async {
    try {
      final encryptedData = await _secureStorage.read(key: _emailsKey);
      if (encryptedData == null) return [];
      
      // Base64 decode
      final bytes = base64.decode(encryptedData);
      final jsonString = utf8.decode(bytes);
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  // Şifrelenmiş email listesini güvenli depolamaya kaydet
  static Future<void> _saveEncryptedEmailsList(List<String> emails) async {
    try {
      final jsonString = json.encode(emails);
      final bytes = utf8.encode(jsonString);
      final encoded = base64.encode(bytes);
      await _secureStorage.write(key: _emailsKey, value: encoded);
    } catch (e) {
      throw Exception('Email listesi kaydedilirken hata oluştu: $e');
    }
  }
  
  // Email hesabı ekle
  static Future<void> addEmailAccount({
    required String email,
    required String password,
    String? displayName,
    String? provider,
  }) async {
    try {
      final encrypter = await _getEncrypter();
      
      // Email hesap bilgilerini şifrele
      final emailData = {
        'email': email,
        'password': password,
        'displayName': displayName ?? email.split('@')[0],
        'provider': provider ?? email.split('@')[1],
        'createdAt': DateTime.now().toIso8601String(),
        'lastUsed': DateTime.now().toIso8601String(),
        'version': '2.0', // Güvenlik versiyonu
        'checksum': _generateChecksum(email + password), // Veri bütünlüğü
      };
      
      final jsonData = json.encode(emailData);
      final encrypted = encrypter.encrypt(jsonData);
      
      // Mevcut şifrelenmiş emailleri al
      List<String> encryptedEmails = await _getEncryptedEmailsList();
      
      // Aynı email varsa güncelle, yoksa ekle
      bool updated = false;
      for (int i = 0; i < encryptedEmails.length; i++) {
        try {
          final decrypted = encrypter.decrypt64(encryptedEmails[i]);
          final existingData = json.decode(decrypted);
          if (existingData['email'] == email) {
            encryptedEmails[i] = encrypted.base64;
            updated = true;
            break;
          }
        } catch (e) {
          // Şifreleme hatası olan email'i temizle
          continue;
        }
      }
      
      if (!updated) {
        encryptedEmails.add(encrypted.base64);
      }
      
      // Güvenli depolamaya kaydet
      await _saveEncryptedEmailsList(encryptedEmails);
      
      // Başarılı işlem sonrası deneme sayısını sıfırla
      await _resetFailedAttempts();
      
    } catch (e) {
      throw Exception('Email hesabı eklenirken hata oluştu: $e');
    }
  }
  
  // Tüm email hesaplarını getir
  static Future<List<Map<String, dynamic>>> getAllEmailAccounts() async {
    try {
      final encrypter = await _getEncrypter();
      
      List<String> encryptedEmails = await _getEncryptedEmailsList();
      List<Map<String, dynamic>> emailAccounts = [];
      
      for (String encryptedEmail in encryptedEmails) {
        try {
          final decrypted = encrypter.decrypt64(encryptedEmail);
          final emailData = json.decode(decrypted);
          
          // Veri bütünlüğü kontrolü
          if (emailData['checksum'] != null) {
            final expectedChecksum = _generateChecksum(emailData['email'] + emailData['password']);
            if (emailData['checksum'] != expectedChecksum) {
              // Veri bozulmuş, atla
              continue;
            }
          }
          
          emailAccounts.add(emailData);
        } catch (e) {
          // Şifreleme hatası olan email'i atla
          continue;
        }
      }
      
      // Son kullanım tarihine göre sırala
      emailAccounts.sort((a, b) {
        final aDate = DateTime.parse(a['lastUsed']);
        final bDate = DateTime.parse(b['lastUsed']);
        return bDate.compareTo(aDate);
      });
      
      // Başarılı işlem sonrası deneme sayısını sıfırla
      await _resetFailedAttempts();
      
      return emailAccounts;
    } catch (e) {
      throw Exception('Email hesapları alınırken hata oluştu: $e');
    }
  }
  
  // Belirli bir email hesabını getir
  static Future<Map<String, dynamic>?> getEmailAccount(String email) async {
    try {
      final accounts = await getAllEmailAccounts();
      try {
        return accounts.firstWhere(
          (account) => account['email'] == email,
        );
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  // Email hesabını güncelle
  static Future<void> updateEmailAccount({
    required String email,
    String? password,
    String? displayName,
    String? provider,
  }) async {
    try {
      final accounts = await getAllEmailAccounts();
      final accountIndex = accounts.indexWhere((acc) => acc['email'] == email);
      
      if (accountIndex == -1) {
        throw Exception('Email hesabı bulunamadı');
      }
      
      final existingAccount = accounts[accountIndex];
      final updatedAccount = {
        ...existingAccount,
        'password': password ?? existingAccount['password'],
        'displayName': displayName ?? existingAccount['displayName'],
        'provider': provider ?? existingAccount['provider'],
        'lastUsed': DateTime.now().toIso8601String(),
      };
      
      // Hesabı güncelle
      await addEmailAccount(
        email: updatedAccount['email'],
        password: updatedAccount['password'],
        displayName: updatedAccount['displayName'],
        provider: updatedAccount['provider'],
      );
    } catch (e) {
      throw Exception('Email hesabı güncellenirken hata oluştu: $e');
    }
  }
  
  // Email hesabını sil
  static Future<void> deleteEmailAccount(String email) async {
    try {
      final encrypter = await _getEncrypter();
      
      List<String> encryptedEmails = await _getEncryptedEmailsList();
      List<String> filteredEmails = [];
      
      for (String encryptedEmail in encryptedEmails) {
        try {
          final decrypted = encrypter.decrypt64(encryptedEmail);
          final emailData = json.decode(decrypted);
          if (emailData['email'] != email) {
            filteredEmails.add(encryptedEmail);
          }
        } catch (e) {
          // Şifreleme hatası olan email'i atla
          continue;
        }
      }
      
      await _saveEncryptedEmailsList(filteredEmails);
      
      // Başarılı işlem sonrası deneme sayısını sıfırla
      await _resetFailedAttempts();
      
    } catch (e) {
      throw Exception('Email hesabı silinirken hata oluştu: $e');
    }
  }
  
  // Email hesabı kullanımını güncelle
  static Future<void> updateLastUsed(String email) async {
    try {
      final accounts = await getAllEmailAccounts();
      Map<String, dynamic>? account;
      try {
        account = accounts.firstWhere(
          (acc) => acc['email'] == email,
        );
      } catch (e) {
        account = null;
      }
      
      if (account != null) {
        await updateEmailAccount(
          email: email,
          password: account['password'],
          displayName: account['displayName'],
          provider: account['provider'],
        );
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Tüm email hesaplarını temizle
  static Future<void> clearAllEmailAccounts() async {
    try {
      await _secureStorage.delete(key: _emailsKey);
      
      // Başarılı işlem sonrası deneme sayısını sıfırla
      await _resetFailedAttempts();
      
    } catch (e) {
      throw Exception('Email hesapları temizlenirken hata oluştu: $e');
    }
  }
  
  // Şifreleme anahtarını yenile (tüm veriler yeniden şifrelenir)
  static Future<void> regenerateEncryptionKey() async {
    try {
      // Mevcut emailleri al
      final accounts = await getAllEmailAccounts();
      
      // Eski güvenlik parametrelerini sil
      await _secureStorage.delete(key: _keyName);
      await _secureStorage.delete(key: _saltName);
      await _secureStorage.delete(key: _ivName);
      
      // Yeni anahtar ile yeniden şifrele
      for (final account in accounts) {
        await addEmailAccount(
          email: account['email'],
          password: account['password'],
          displayName: account['displayName'],
          provider: account['provider'],
        );
      }
      
      // Başarılı işlem sonrası deneme sayısını sıfırla
      await _resetFailedAttempts();
      
    } catch (e) {
      throw Exception('Şifreleme anahtarı yenilenirken hata oluştu: $e');
    }
  }
  
  // Güvenlik kontrolü
  static Future<bool> isEncryptionSecure() async {
    try {
      final level = await _checkSecurityLevel();
      return level;
    } catch (e) {
      return false;
    }
  }
  
  // Güvenlik durumu raporu
  static Future<Map<String, dynamic>> getSecurityReport() async {
    try {
      final isSecure = await isEncryptionSecure();
      final hasBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return {
        'encryption_secure': isSecure,
        'biometrics_available': hasBiometrics,
        'available_biometrics': availableBiometrics,
        'security_level': await _secureStorage.read(key: _securityLevelKey) ?? 'basic',
        'session_active': await _checkSessionTimeout(),
        'failed_attempts': await _secureStorage.read(key: _failedAttemptsKey) ?? '0',
        'last_access': await _secureStorage.read(key: _lastAccessKey),
        'lockout_status': await _secureStorage.read(key: _lockoutUntilKey),
      };
    } catch (e) {
      return {
        'encryption_secure': false,
        'error': e.toString(),
      };
    }
  }
  
  // Güvenlik ayarlarını sıfırla
  static Future<void> resetSecuritySettings() async {
    try {
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);
      await _secureStorage.delete(key: _lastAccessKey);
    } catch (e) {
      throw Exception('Güvenlik ayarları sıfırlanırken hata oluştu: $e');
    }
  }
  
  // Güvenlik testi
  static Future<bool> runSecurityTest() async {
    try {
      // Biyometrik kimlik doğrulama testi
      final canAuth = await _authenticateBiometric();
      if (!canAuth) return false;
      
      // Şifreleme testi
      final testData = 'test_security_data';
      final encrypter = await _getEncrypter();
      final encrypted = encrypter.encrypt(testData);
      final decrypted = encrypter.decrypt(encrypted);
      
      // Doğru karşılaştırma yap - decrypted bir String olduğu için direkt karşılaştır
      return decrypted == testData;
    } catch (e) {
      return false;
    }
  }
  
  // Güvenlik logları
  static Future<void> logSecurityEvent(String event, {String? details}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'event': event,
        'details': details,
        'device_info': await _getDeviceInfo(),
      };
      
      final logs = await _getSecurityLogs();
      logs.add(json.encode(logEntry));
      
      // Son 100 logu tut
      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }
      
      await _secureStorage.write(key: 'security_logs', value: json.encode(logs));
    } catch (e) {
      // Log hatası durumunda sessizce devam et
    }
  }
  
  // Güvenlik loglarını getir
  static Future<List<String>> _getSecurityLogs() async {
    try {
      final logsData = await _secureStorage.read(key: 'security_logs');
      if (logsData == null) return [];
      
      final List<dynamic> decoded = json.decode(logsData);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  // Cihaz bilgisi
  static Future<Map<String, String>> _getDeviceInfo() async {
    try {
      return {
        'platform': 'Android',
        'timestamp': DateTime.now().toIso8601String(),
        'security_level': await _secureStorage.read(key: _securityLevelKey) ?? 'unknown',
      };
    } catch (e) {
      return {
        'platform': 'Android',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
} 