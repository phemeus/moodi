import 'package:flutter/material.dart';
import '../../core/secure_email_service.dart';

class SecurityInfoWidget extends StatefulWidget {
  const SecurityInfoWidget({super.key});

  @override
  State<SecurityInfoWidget> createState() => _SecurityInfoWidgetState();
}

class _SecurityInfoWidgetState extends State<SecurityInfoWidget> {
  bool _isEncryptionSecure = false;
  bool _isLoading = true;
  Map<String, dynamic> _securityReport = {};
  bool _isRunningTest = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    try {
      final isSecure = await SecureEmailService.isEncryptionSecure();
      final report = await SecureEmailService.getSecurityReport();
      
      setState(() {
        _isEncryptionSecure = isSecure;
        _securityReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isEncryptionSecure = false;
        _securityReport = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _runSecurityTest() async {
    setState(() {
      _isRunningTest = true;
    });

    try {
      final result = await SecureEmailService.runSecurityTest();
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Güvenlik testi başarılı!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Güvenlik testi başarısız!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Güvenlik durumunu yenile
      await _checkSecurityStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Güvenlik testi hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _resetSecuritySettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Ayarlarını Sıfırla'),
        content: const Text(
          'Bu işlem tüm güvenlik kilitlerini ve deneme sayılarını sıfırlayacak. '
          'Devam etmek istediğinizden emin misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SecureEmailService.resetSecuritySettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Güvenlik ayarları sıfırlandı'),
            backgroundColor: Colors.green,
          ),
        );
        await _checkSecurityStatus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSecurityIndicator(String title, bool isSecure, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSecure ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSecure ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSecure ? Icons.check_circle : Icons.error,
            color: isSecure ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isEncryptionSecure ? Icons.security : Icons.security_outlined,
                  color: _isEncryptionSecure 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Güvenlik Durumu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isRunningTest ? null : _runSecurityTest,
                  icon: _isRunningTest 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Güvenlik Testi Çalıştır',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Ana güvenlik durumu
            _buildSecurityIndicator(
              'Şifreleme Güvenliği',
              _isEncryptionSecure,
              subtitle: _isEncryptionSecure 
                  ? 'AES-256 şifreleme aktif'
                  : 'Şifreleme devre dışı'
            ),
            
            const SizedBox(height: 12),
            
            // Biyometrik kimlik doğrulama
            _buildSecurityIndicator(
              'Biyometrik Kimlik Doğrulama',
              _securityReport['biometrics_available'] ?? false,
              subtitle: _securityReport['biometrics_available'] == true
                  ? 'Parmak izi, yüz tanıma veya iris tarama aktif'
                  : 'Biyometrik kimlik doğrulama mevcut değil'
            ),
            
            const SizedBox(height: 12),
            
            // Session durumu
            _buildSecurityIndicator(
              'Oturum Güvenliği',
              _securityReport['session_active'] ?? false,
              subtitle: _securityReport['session_active'] == true
                  ? 'Aktif oturum mevcut'
                  : 'Oturum süresi dolmuş'
            ),
            
            const SizedBox(height: 12),
            
            // Güvenlik seviyesi
            _buildSecurityIndicator(
              'Güvenlik Seviyesi',
              (_securityReport['security_level'] ?? 'basic') == 'enterprise',
              subtitle: 'Seviye: ${_securityReport['security_level'] ?? 'basic'}'
            ),
            
            const SizedBox(height: 16),
            
            // Güvenlik detayları
            if (_securityReport['failed_attempts'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Güvenlik Uyarısı',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Başarısız deneme sayısı: ${_securityReport['failed_attempts']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Güvenlik bilgileri
            Text(
              '🔐 Enterprise Güvenlik Özellikleri:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              '• AES-256 endüstri standardı şifreleme\n'
              '• Biyometrik kimlik doğrulama\n'
              '• Brute force koruması (5 deneme limiti)\n'
              '• Otomatik hesap kilitleme (30 dakika)\n'
              '• Session timeout (15 dakika)\n'
              '• Veri bütünlüğü kontrolü (checksum)\n'
              '• Güvenlik logları ve izleme\n'
              '• Flutter Secure Storage ile güvenli depolama',
              style: TextStyle(fontSize: 12),
            ),
            
            const SizedBox(height: 16),
            
            // Güvenlik ayarları butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetSecuritySettings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Güvenlik Sıfırla'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkSecurityStatus,
                    icon: const Icon(Icons.security),
                    label: const Text('Durumu Yenile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 