import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DataDeletionPage extends StatelessWidget {
  const DataDeletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veri Silme'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesap ve Veri Silme',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istiyorsanız, aşağıdaki seçeneklerden birini kullanabilirsiniz:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Uygulama içi veri silme
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Uygulama İçinde Veri Sil'),
                subtitle: const Text('Hesabınızı ve verilerinizi hemen silin'),
                onTap: () => _showDeleteConfirmation(context),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // E-posta ile veri silme
            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('E-posta ile Veri Silme Talebi'),
                subtitle: const Text('yasin.isiktas1@gmail.com adresine e-posta gönderin'),
                onTap: () => _sendEmail(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Web sitesi üzerinden
            Card(
              child: ListTile(
                leading: const Icon(Icons.web, color: Colors.green),
                title: const Text('Web Sitesi Üzerinden'),
                subtitle: const Text('Prestivo web sitesinden veri silme talebi yapın'),
                onTap: () => _openWebsite(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Önemli Bilgiler:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Veri silme işlemi geri alınamaz\n'
              '• Tüm kişisel verileriniz, mood kayıtlarınız ve ayarlarınız silinecek\n'
              '• Firebase hesabınız da silinecek\n'
              '• İşlem 30 gün içinde tamamlanacak',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hesap Silme Onayı'),
          content: const Text(
            'Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinizden emin misiniz? '
            'Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hesabı Sil'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(BuildContext context) {
    // TODO: Implement account deletion logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hesap silme talebi alındı. 30 gün içinde işlem tamamlanacak.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'yasin.isiktas1@gmail.com',
      query: 'subject=Veri Silme Talebi&body=Merhaba, Moodi uygulamasındaki hesabımı ve verilerimi silmek istiyorum.',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _openWebsite() async {
    final Uri websiteUri = Uri.parse('https://prestivo.com/privacy/data-deletion');
    
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri);
    }
  }
} 