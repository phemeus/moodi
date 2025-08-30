# Moodi - Ruh Hali Takip Uygulaması

Moodi, günlük ruh halinizi takip etmenizi ve mental sağlığınızı iyileştirmenizi sağlayan kapsamlı bir Flutter uygulamasıdır.

## 🚀 Özellikler

### 📱 Ana Özellikler
- **Mood Takibi**: Günlük ruh halinizi emoji ve notlarla kaydedin
- **İstatistikler**: Ruh hali değişimlerinizi grafiklerle analiz edin
- **Kullanıcı Hesabı**: Firebase Authentication ile güvenli giriş
- **Reklam Desteği**: Google AdMob entegrasyonu

### 🆕 Yeni Eklenen Özellikler

#### 1. 🌬️ Nefes Egzersizi
- **Animasyonlu Nefes Döngüsü**: Genişleyen ve küçülen daire ile nefes ritmini takip edin
- **4 Fazlı Nefes Tekniği**: Nefes al → Tut → Nefes ver → Tut
- **Stres Azaltma**: Günlük stresi azaltmak için basit ama etkili nefes egzersizleri
- **Görsel Geri Bildirim**: Nefes sayacı ve faz göstergesi

#### 2. 🎰 Alışkanlık Çarkı (Wheel of Habits)
- **100+ Rastgele Görev**: Fiziksel aktivite, sosyal, kişisel gelişim ve daha fazlası
- **Renkli Çark**: Güzel animasyonlu çark ile eğlenceli görev seçimi
- **Kategorize Edilmiş Görevler**:
  - 🏃‍♂️ Fiziksel aktiviteler (şınav, squat, yürüyüş)
  - 💧 Su ve beslenme
  - 👥 Sosyal aktiviteler
  - 📚 Kişisel gelişim
  - 🧹 Temizlik ve düzen
  - 🧘‍♀️ Ruh sağlığı
  - 🎨 Yaratıcılık
  - 📖 Öğrenme
  - ❤️ İlişkiler
  - 🎯 Hedefler

#### 3. 💬 Motivasyonel Sözler
- **Ruh Haline Göre Sözler**: 8 farklı mood kategorisinde 100+ söz
- **Akıllı Filtreleme**: Mutlu, üzgün, stresli, yorgun, kızgın, endişeli, motivasyon, genel
- **Rastgele Söz**: Her gün yeni motivasyon
- **Mood Bazlı Seçim**: Mevcut ruh halinize uygun sözler

#### 4. 🔐 Enterprise Güvenlik
- **AES-256 Şifreleme**: Endüstri standardı güvenlik
- **Biometric Authentication**: Parmak izi, yüz tanıma desteği
- **Brute Force Koruması**: Güvenlik saldırılarına karşı koruma
- **Session Management**: Otomatik timeout ve güvenlik kontrolleri
- **Google Play Store Uyumlu**: Enterprise seviye güvenlik standartları

## 🛠️ Teknik Detaylar

### Kullanılan Teknolojiler
- **Flutter**: Cross-platform mobil uygulama geliştirme
- **Firebase**: Authentication ve veri yönetimi
- **Provider**: State management
- **Google AdMob**: Reklam entegrasyonu
- **Flutter Secure Storage**: Güvenli veri saklama
- **Local Authentication**: Biometric kimlik doğrulama

### Proje Yapısı
```
lib/
├── core/           # Temel servisler ve modeller
│   ├── models/     # Veri modelleri
│   ├── utils/      # Yardımcı fonksiyonlar
│   └── services/   # Firebase ve güvenlik servisleri
├── ui/            # Kullanıcı arayüzü
│   ├── auth/      # Giriş sayfaları
│   ├── breathing/ # Nefes egzersizi
│   ├── home/      # Ana sayfa
│   ├── stats/     # İstatistikler
│   └── settings/  # Ayarlar ve güvenlik
└── main.dart      # Uygulama giriş noktası
```

## 📱 Kurulum

1. **Flutter Kurulumu**: Flutter SDK'yı kurun
2. **Bağımlılıkları Yükleyin**: `flutter pub get`
3. **Firebase Kurulumu**: Firebase projesini oluşturun ve yapılandırın
4. **Google AdMob**: AdMob hesabı oluşturun ve reklam ID'lerini ekleyin
5. **Uygulamayı Çalıştırın**: `flutter run`

## 🎯 Kullanım

### Nefes Egzersizi
1. Ana sayfada "Nefes Egzersizi" kartına tıklayın
2. "Başla" butonuna basın
3. Animasyonlu daireyi takip ederek nefes alın ve verin
4. 4 fazlı nefes döngüsünü tamamlayın

### Günlük Görevler
1. Ana sayfada günlük görevleri görün
2. Görevleri tamamlayarak puan kazanın
3. "Tamamlanmış Görevler" ile geçmiş aktivitelerinizi takip edin

### Güvenlik Ayarları
1. Ayarlar sayfasında "Güvenlik Bilgileri"ne gidin
2. Güvenlik testini çalıştırın
3. Biometric authentication'ı aktif edin

## 🔧 Yapılandırma

### Firebase
- `google-services.json` dosyasını `android/app/` klasörüne ekleyin
- Firebase Authentication'ı etkinleştirin

### Google AdMob
- `android/app/src/main/AndroidManifest.xml` dosyasında reklam ID'lerini güncelleyin
- Test reklamları için test cihaz ID'lerini ekleyin

### Güvenlik
- Android manifest'te biometric izinlerini kontrol edin
- Flutter Secure Storage için gerekli bağımlılıkları ekleyin

## 📊 Performans

- **Nefes Egzersizi**: Smooth 60fps animasyonlar
- **Günlük Görevler**: Firebase real-time sync
- **Güvenlik**: AES-256 şifreleme ile hızlı işlem
- **UI**: Material Design 3 ile modern arayüz

## 🔒 Güvenlik Özellikleri

- **AES-256 Encryption**: Endüstri standardı şifreleme
- **Biometric Authentication**: Parmak izi, yüz tanıma
- **Secure Storage**: Android Keystore ve iOS Keychain
- **Brute Force Protection**: Güvenlik saldırılarına karşı koruma
- **Session Management**: Otomatik timeout
- **Data Integrity**: Checksum doğrulama

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit yapın (`git commit -m 'Add some AmazingFeature'`)
4. Push yapın (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

- **Geliştirici**: Prestivo
- **Email**: [Email adresiniz]
- **Proje Linki**: [GitHub repo linki]

## 🙏 Teşekkürler

- Flutter ekibine harika framework için
- Firebase ekibine backend servisleri için
- Google AdMob ekibine reklam entegrasyonu için
- Tüm açık kaynak topluluğuna

---

**Moodi ile ruh halinizi takip edin, nefes alın, alışkanlıklar geliştirin ve motivasyonunuzu artırın! 🌟**
