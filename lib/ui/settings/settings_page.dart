import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth_service.dart';
import '../../core/mood_service.dart';
import '../../core/notification_service.dart';
import 'data_deletion_page.dart';
import 'email_accounts_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgileri
            _buildUserInfoSection(),
            
            const SizedBox(height: 24),
            
            // Uygulama ayarları
            _buildAppSettingsSection(),
            
            const SizedBox(height: 24),
            
            // Veri yönetimi
            _buildDataSection(),
            
            const SizedBox(height: 24),
            
            // Email hesapları
            _buildEmailAccountsSection(),
            
            const SizedBox(height: 24),
            
            // Hakkında
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kullanıcı Bilgileri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: user?.photoURL != null 
                      ? NetworkImage(user!.photoURL!) 
                      : null,
                  child: user?.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? user?.email ?? 'Kullanıcı',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Email bilgisi yok',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Aktif',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uygulama Ayarları',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bildirimler
            ListTile(
              leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
              title: const Text('Günlük Bildirimler'),
              subtitle: const Text('Her akşam 9\'da mood hatırlatıcısı'),
              trailing: FutureBuilder<bool>(
                future: context.read<NotificationService>().isNotificationScheduled(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return Switch(
                    value: isEnabled,
                    onChanged: (value) async {
                      final notificationService = context.read<NotificationService>();
                      if (value) {
                        await notificationService.scheduleDailyNotification();
                      } else {
                        await notificationService.cancelDailyNotification();
                      }
                      setState(() {});
                    },
                  );
                },
              ),
            ),
            
            const Divider(),
            
            // Karanlık tema
            ListTile(
              leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
              title: const Text('Karanlık Tema'),
              subtitle: const Text('Otomatik tema değişimi'),
              trailing: Switch(
                value: false, // TODO: Implement theme settings
                onChanged: (value) {
                  // TODO: Save theme preference
                },
              ),
            ),
            
            const Divider(),
            
            // Reklamları kaldır
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Reklamları Kaldır'),
              subtitle: const Text('Premium özellik - yakında'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
              onTap: () {
                _showPremiumDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailAccountsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Hesapları',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              title: const Text('Email Hesaplarını Yönet'),
              subtitle: const Text('Şifrelenmiş email hesaplarınızı güvenle saklayın'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmailAccountsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veri Yönetimi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mood verilerini dışa aktar
            ListTile(
              leading: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
              title: const Text('Verileri Dışa Aktar'),
              subtitle: const Text('Mood verilerinizi CSV olarak indirin'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showExportDialog();
              },
            ),
            
            const Divider(),
            
            // Verileri temizle
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Verileri Temizle'),
              subtitle: const Text('Tüm mood verilerinizi silin'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showClearDataDialog();
              },
            ),
            
            const Divider(),
            
            // Hesap ve veri silme
            ListTile(
              leading: Icon(Icons.person_off, color: Colors.red),
              title: const Text('Hesap ve Veri Silme'),
              subtitle: const Text('Hesabınızı kalıcı olarak silin'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataDeletionPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hakkında',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              title: const Text('Versiyon'),
              subtitle: const Text('1.0.0'),
              onTap: () {},
            ),
            
            ListTile(
              leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
              title: const Text('Geliştirici'),
              subtitle: const Text('Prestivo'),
              onTap: () {},
            ),
            
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Gizlilik Politikası'),
              subtitle: const Text('Verileriniz güvende'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showPrivacyDialog();
              },
            ),
            
            const Divider(),
            
            // Çıkış yap
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Hesabınızdan çıkış yapın'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Özellik'),
        content: const Text('Reklamları kaldırma özelliği yakında gelecek! Bu özellik için premium üyelik gerekli olacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veri Dışa Aktarma'),
        content: const Text('Mood verilerinizi CSV formatında dışa aktarma özelliği yakında gelecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Temizle'),
        content: const Text('Tüm mood verilerinizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: const Text('Moodi uygulaması verilerinizi güvenle saklar. Tüm veriler yerel olarak saklanır ve sadece size aittir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final moodService = context.read<MoodService>();
      await moodService.clearAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm veriler başarıyla temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler temizlenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla çıkış yapıldı'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Ana sayfaya yönlendir
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 