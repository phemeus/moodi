import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Firebase'i güvenli bir şekilde başlat
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase başlatıldı');
      print('🔗 Database URL: ${DefaultFirebaseOptions.currentPlatform.databaseURL}');
      print('🏗️ Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      
      // Firebase Database'i manuel olarak başlat
      final database = FirebaseDatabase.instance;
      if (database.databaseURL == null) {
        print('⚠️ Database URL null, manuel olarak ayarlanıyor...');
        database.databaseURL = 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app';
      }
      print('🔗 Final Database URL: ${database.databaseURL}');
      
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        print('Firebase zaten başlatılmış, devam ediliyor...');
      } else {
        print('❌ Firebase başlatma hatası: ${e.code} - ${e.message}');
        rethrow;
      }
    }
    
    // Mobile Ads'i başlat
    try {
      await MobileAds.instance.initialize();
      print('Mobile Ads başlatıldı');
    } catch (e) {
      print('Mobile Ads başlatılamadı: $e');
    }
    
    print('Uygulama başlatıldı');
    
    runApp(const MoodiApp());
  } catch (e, stackTrace) {
    print('Uygulama başlatılırken hata: $e');
    print('Stack trace: $stackTrace');
    
    // Hata durumunda basit bir uygulama çalıştır
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Uygulama başlatılamadı'),
              const SizedBox(height: 8),
              Text('Hata: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Uygulamayı yeniden başlat
                  runApp(const MoodiApp());
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
