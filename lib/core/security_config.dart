/// Enterprise Security Configuration
/// 
/// Bu dosya, Moodi uygulamasının tüm güvenlik ayarlarını
/// merkezi bir yerden yönetmek için kullanılır.
/// 
/// Google Play Store uyumluluğu için optimize edilmiştir.

class SecurityConfig {
  // Private constructor - singleton pattern
  SecurityConfig._();
  
  // ===========================================================================
  // ENCRYPTION SETTINGS
  // ===========================================================================
  
  /// Şifreleme algoritması
  static const String encryptionAlgorithm = 'AES-256-GCM';
  
  /// Anahtar uzunluğu (bit)
  static const int keyLength = 256;
  
  /// Anahtar uzunluğu (byte)
  static const int keyLengthBytes = 32;
  
  /// Salt uzunluğu (byte)
  static const int saltLength = 32;
  
  /// IV uzunluğu (byte)
  static const int ivLength = 16;
  
  /// Anahtar türetme iterasyon sayısı
  static const int keyDerivationIterations = 100000;
  
  // ===========================================================================
  // AUTHENTICATION SETTINGS
  // ===========================================================================
  
  /// Maksimum başarısız deneme sayısı
  static const int maxFailedAttempts = 5;
  
  /// Hesap kilitleme süresi (dakika)
  static const int lockoutDurationMinutes = 30;
  
  /// Session timeout süresi (dakika)
  static const int sessionTimeoutMinutes = 15;
  
  /// Biyometrik kimlik doğrulama timeout (saniye)
  static const int biometricTimeoutSeconds = 30;
  
  /// Minimum şifre uzunluğu
  static const int minPasswordLength = 8;
  
  /// Şifre karmaşıklık gereksinimleri
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;
  
  // ===========================================================================
  // STORAGE SETTINGS
  // ===========================================================================
  
  /// Güvenli depolama anahtarları
  static const String encryptionKeyName = 'encryption_key';
  static const String saltName = 'encryption_salt';
  static const String ivName = 'encryption_iv';
  static const String emailsKey = 'encrypted_emails';
  static const String securityLevelKey = 'security_level';
  static const String lastAccessKey = 'last_access_time';
  static const String failedAttemptsKey = 'failed_attempts';
  static const String lockoutUntilKey = 'lockout_until';
  static const String securityLogsKey = 'security_logs';
  
  /// Güvenlik seviyeleri
  static const String securityLevelBasic = 'basic';
  static const String securityLevelStandard = 'standard';
  static const String securityLevelEnterprise = 'enterprise';
  static const String securityLevelMilitary = 'military';
  
  /// Varsayılan güvenlik seviyesi
  static const String defaultSecurityLevel = securityLevelEnterprise;
  
  // ===========================================================================
  // LOGGING SETTINGS
  // ===========================================================================
  
  /// Maksimum güvenlik log sayısı
  static const int maxSecurityLogs = 100;
  
  /// Log seviyeleri
  static const String logLevelInfo = 'INFO';
  static const String logLevelWarning = 'WARNING';
  static const String logLevelError = 'ERROR';
  static const String logLevelCritical = 'CRITICAL';
  
  /// Log event türleri
  static const String logEventLogin = 'LOGIN';
  static const String logEventLogout = 'LOGOUT';
  static const String logEventFailedAuth = 'FAILED_AUTH';
  static const String logEventAccountLocked = 'ACCOUNT_LOCKED';
  static const String logEventKeyRegenerated = 'KEY_REGENERATED';
  static const String logEventDataAccess = 'DATA_ACCESS';
  static const String logEventDataModified = 'DATA_MODIFIED';
  static const String logEventSecurityTest = 'SECURITY_TEST';
  
  // ===========================================================================
  // THREAT DETECTION SETTINGS
  // ===========================================================================
  
  /// Tehdit algılama eşikleri
  static const int suspiciousActivityThreshold = 3;
  static const int criticalActivityThreshold = 10;
  
  /// Tehdit türleri
  static const String threatTypeBruteForce = 'BRUTE_FORCE';
  static const String threatTypeDataTampering = 'DATA_TAMPERING';
  static const String threatTypeUnauthorizedAccess = 'UNAUTHORIZED_ACCESS';
  static const String threatTypeSessionHijacking = 'SESSION_HIJACKING';
  
  // ===========================================================================
  // COMPLIANCE SETTINGS
  // ===========================================================================
  
  /// GDPR uyumluluk ayarları
  static const bool gdprCompliant = true;
  static const bool dataMinimization = true;
  static const bool userConsentRequired = true;
  static const bool rightToErasure = true;
  
  /// KVKK uyumluluk ayarları
  static const bool kvkkCompliant = true;
  
  /// Google Play Store uyumluluk
  static const bool playStoreCompliant = true;
  static const bool targetApiLevel33 = true;
  static const bool supports64Bit = true;
  
  // ===========================================================================
  // PERFORMANCE SETTINGS
  // ===========================================================================
  
  /// Performans limitleri
  static const int maxEncryptionTimeMs = 1000;
  static const int maxDecryptionTimeMs = 1000;
  static const int maxAuthenticationTimeMs = 5000;
  
  /// Cache ayarları
  static const bool enableSecurityCache = true;
  static const int securityCacheSize = 50;
  static const int securityCacheTimeoutMinutes = 5;
  
  // ===========================================================================
  // DEBUG SETTINGS
  // ===========================================================================
  
  /// Debug modu (sadece development için)
  static const bool debugMode = false;
  
  /// Güvenlik testleri
  static const bool enableSecurityTests = true;
  static const bool enablePenetrationTests = false;
  static const bool enablePerformanceTests = true;
  
  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================
  
  /// Güvenlik seviyesi kontrolü
  static bool isSecurityLevelValid(String level) {
    return [
      securityLevelBasic,
      securityLevelStandard,
      securityLevelEnterprise,
      securityLevelMilitary,
    ].contains(level);
  }
  
  /// Log seviyesi kontrolü
  static bool isLogLevelValid(String level) {
    return [
      logLevelInfo,
      logLevelWarning,
      logLevelError,
      logLevelCritical,
    ].contains(level);
  }
  
  /// Tehdit türü kontrolü
  static bool isThreatTypeValid(String type) {
    return [
      threatTypeBruteForce,
      threatTypeDataTampering,
      threatTypeUnauthorizedAccess,
      threatTypeSessionHijacking,
    ].contains(type);
  }
  
  /// Şifre gücü kontrolü
  static bool isPasswordStrong(String password) {
    if (password.length < minPasswordLength) return false;
    
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasNumbers = false;
    bool hasSpecialChars = false;
    
    for (int i = 0; i < password.length; i++) {
      final char = password[i];
      if (char.contains(RegExp(r'[A-Z]'))) hasUppercase = true;
      if (char.contains(RegExp(r'[a-z]'))) hasLowercase = true;
      if (char.contains(RegExp(r'[0-9]'))) hasNumbers = true;
      if (char.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) hasSpecialChars = true;
    }
    
    if (requireUppercase && !hasUppercase) return false;
    if (requireLowercase && !hasLowercase) return false;
    if (requireNumbers && !hasNumbers) return false;
    if (requireSpecialChars && !hasSpecialChars) return false;
    
    return true;
  }
  
  /// Güvenlik skoru hesaplama
  static int calculateSecurityScore({
    required bool hasBiometrics,
    required bool hasStrongPassword,
    required bool hasEncryption,
    required bool hasSessionTimeout,
    required bool hasBruteForceProtection,
  }) {
    int score = 0;
    
    if (hasBiometrics) score += 25;
    if (hasStrongPassword) score += 20;
    if (hasEncryption) score += 25;
    if (hasSessionTimeout) score += 15;
    if (hasBruteForceProtection) score += 15;
    
    return score;
  }
  
  /// Güvenlik seviyesi önerisi
  static String getRecommendedSecurityLevel(int securityScore) {
    if (securityScore >= 90) return securityLevelMilitary;
    if (securityScore >= 80) return securityLevelEnterprise;
    if (securityScore >= 60) return securityLevelStandard;
    return securityLevelBasic;
  }
  
  /// Compliance raporu
  static Map<String, bool> getComplianceReport() {
    return {
      'gdpr_compliant': gdprCompliant,
      'kvkk_compliant': kvkkCompliant,
      'play_store_compliant': playStoreCompliant,
      'target_api_level_33': targetApiLevel33,
      'supports_64bit': supports64Bit,
      'data_minimization': dataMinimization,
      'user_consent_required': userConsentRequired,
      'right_to_erasure': rightToErasure,
    };
  }
  
  /// Güvenlik özellikleri listesi
  static List<String> getSecurityFeatures() {
    return [
      'AES-256-GCM şifreleme',
      'Biyometrik kimlik doğrulama',
      'Brute force koruması',
      'Session timeout',
      'Veri bütünlüğü kontrolü',
      'Güvenlik logları',
      'Tehdit algılama',
      'Otomatik hesap kilitleme',
      'Şifre gücü kontrolü',
      'Güvenli depolama',
    ];
  }
} 