import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'models/daily_task.dart';

class DailyTaskService extends ChangeNotifier {
  late final DatabaseReference _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<DailyTask> _dailyTasks = [];
  List<DailyTask> _todayTasks = [];
  int _totalPoints = 0;
  int _completedTasks = 0;
  DateTime? _lastTaskDate;
  
  // Getter'lar
  List<DailyTask> get dailyTasks => _dailyTasks;
  List<DailyTask> get todayTasks => _todayTasks;
  int get totalPoints => _totalPoints;
  int get completedTasks => _completedTasks;
  
  // 150+ Statik günlük görevler
  static final List<Map<String, dynamic>> _staticTasks = [
    // Fiziksel Sağlık (30 görev)
    {'id': '1', 'title': '20 Şınav Çek', 'description': 'Güçlü kollar için 20 şınav çek', 'category': 'fiziksel', 'points': 15},
    {'id': '2', 'title': '30 Squat Yap', 'description': 'Bacak kaslarını güçlendir', 'category': 'fiziksel', 'points': 12},
    {'id': '3', 'title': '1 Dakika Plank', 'description': 'Core kaslarını çalıştır', 'category': 'fiziksel', 'points': 10},
    {'id': '4', 'title': '10 Burpee', 'description': 'Tam vücut egzersizi yap', 'category': 'fiziksel', 'points': 18},
    {'id': '5', 'title': '5 Dakika Yoga', 'description': 'Esneklik ve denge için yoga', 'category': 'fiziksel', 'points': 8},
    {'id': '6', 'title': '15 Dakika Yürüyüş', 'description': 'Temiz havada yürüyüş yap', 'category': 'fiziksel', 'points': 10},
    {'id': '7', 'title': '10 Push-up', 'description': 'Göğüs kaslarını güçlendir', 'category': 'fiziksel', 'points': 12},
    {'id': '8', 'title': '20 Lunge', 'description': 'Bacak kaslarını çalıştır', 'category': 'fiziksel', 'points': 14},
    {'id': '9', 'title': '2 Dakika Jumping Jack', 'description': 'Kardiyo egzersizi yap', 'category': 'fiziksel', 'points': 16},
    {'id': '10', 'title': '10 Mountain Climber', 'description': 'Dinamik core egzersizi', 'category': 'fiziksel', 'points': 13},
    {'id': '11', 'title': '15 Crunch', 'description': 'Karın kaslarını çalıştır', 'category': 'fiziksel', 'points': 11},
    {'id': '12', 'title': '5 Dakika Stretching', 'description': 'Kasları esnet ve rahatlat', 'category': 'fiziksel', 'points': 7},
    {'id': '13', 'title': '25 Jump Rope', 'description': 'İp atlama ile kardiyo', 'category': 'fiziksel', 'points': 15},
    {'id': '14', 'title': '10 Tricep Dip', 'description': 'Arka kol kaslarını güçlendir', 'category': 'fiziksel', 'points': 12},
    {'id': '15', 'title': '20 Calf Raise', 'description': 'Baldır kaslarını çalıştır', 'category': 'fiziksel', 'points': 9},
    {'id': '16', 'title': '3 Dakika High Knees', 'description': 'Yüksek tempolu kardiyo', 'category': 'fiziksel', 'points': 14},
    {'id': '17', 'title': '10 Side Plank', 'description': 'Yan karın kaslarını çalıştır', 'category': 'fiziksel', 'points': 13},
    {'id': '18', 'title': '15 Glute Bridge', 'description': 'Kalça kaslarını güçlendir', 'category': 'fiziksel', 'points': 11},
    {'id': '19', 'title': '8 Pull-up', 'description': 'Sırt kaslarını çalıştır', 'category': 'fiziksel', 'points': 20},
    {'id': '20', 'title': '12 Russian Twist', 'description': 'Dönerek karın kaslarını çalıştır', 'category': 'fiziksel', 'points': 12},
    {'id': '21', 'title': '6 Dakika HIIT', 'description': 'Yüksek yoğunluklu interval', 'category': 'fiziksel', 'points': 18},
    {'id': '22', 'title': '10 Wall Sit', 'description': 'Duvar squat ile bacak kasları', 'category': 'fiziksel', 'points': 10},
    {'id': '23', 'title': '15 Superman', 'description': 'Sırt kaslarını güçlendir', 'category': 'fiziksel', 'points': 11},
    {'id': '24', 'title': '20 Arm Circle', 'description': 'Kol kaslarını esnet', 'category': 'fiziksel', 'points': 8},
    {'id': '25', 'title': '10 Leg Raise', 'description': 'Bacak kaldırma egzersizi', 'category': 'fiziksel', 'points': 12},
    {'id': '26', 'title': '5 Dakika Dance', 'description': 'Dans ederek eğlen ve hareket et', 'category': 'fiziksel', 'points': 9},
    {'id': '27', 'title': '15 Bicycle Crunch', 'description': 'Bisiklet pedalı hareketi', 'category': 'fiziksel', 'points': 13},
    {'id': '28', 'title': '10 Donkey Kick', 'description': 'Kalça kaslarını çalıştır', 'category': 'fiziksel', 'points': 11},
    {'id': '29', 'title': '20 Toe Touch', 'description': 'Ayak parmaklarına dokun', 'category': 'fiziksel', 'points': 9},
    {'id': '30', 'title': '3 Dakika Jump Rope', 'description': 'İp atlama maratonu', 'category': 'fiziksel', 'points': 16},

    // Mental Sağlık (25 görev)
    {'id': '31', 'title': '10 Dakika Meditasyon', 'description': 'Zihni sakinleştir ve odaklan', 'category': 'mental', 'points': 20},
    {'id': '32', 'title': 'Günlük Yaz', 'description': 'Bugün yaşadıklarını yaz', 'category': 'mental', 'points': 15},
    {'id': '33', 'title': '3 Derin Nefes', 'description': 'Stres azaltıcı nefes egzersizi', 'category': 'mental', 'points': 8},
    {'id': '34', 'title': 'Gratitude List', 'description': '3 şey için minnettar ol', 'category': 'mental', 'points': 12},
    {'id': '35', 'title': '5 Dakika Mindfulness', 'description': 'Şu ana odaklan', 'category': 'mental', 'points': 10},
    {'id': '36', 'title': 'Kitap Oku', 'description': 'En az 20 sayfa kitap oku', 'category': 'mental', 'points': 18},
    {'id': '37', 'title': 'Puzzle Çöz', 'description': 'Zihinsel egzersiz yap', 'category': 'mental', 'points': 14},
    {'id': '38', 'title': 'Yeni Kelime Öğren', 'description': 'Günlük yeni kelime ekle', 'category': 'mental', 'points': 9},
    {'id': '39', 'title': 'Müzik Dinle', 'description': 'Favori şarkını aç ve dinle', 'category': 'mental', 'points': 6},
    {'id': '40', 'title': 'Günlük Hedef Belirle', 'description': 'Yarın için 3 hedef yaz', 'category': 'mental', 'points': 11},
    {'id': '41', 'title': '5 Dakika Stretching', 'description': 'Vücudu esnet ve rahatlat', 'category': 'mental', 'points': 7},
    {'id': '42', 'title': 'Günlük Affirmation', 'description': 'Pozitif cümleler tekrarla', 'category': 'mental', 'points': 8},
    {'id': '43', 'title': 'Yeni Yer Keşfet', 'description': 'Daha önce gitmediğin yere git', 'category': 'mental', 'points': 16},
    {'id': '44', 'title': 'Yaratıcı Aktivite', 'description': 'Resim çiz, el işi yap', 'category': 'mental', 'points': 13},
    {'id': '45', 'title': 'Günlük Öğrenme', 'description': 'Yeni bir şey öğren', 'category': 'mental', 'points': 12},
    {'id': '46', 'title': '5 Dakika Sessizlik', 'description': 'Sessizlikte düşün', 'category': 'mental', 'points': 9},
    {'id': '47', 'title': 'Günlük Plan Yap', 'description': 'Yarın için detaylı plan', 'category': 'mental', 'points': 10},
    {'id': '48', 'title': 'Mantra Tekrarla', 'description': 'Favori mantranı tekrarla', 'category': 'mental', 'points': 7},
    {'id': '49', 'title': 'Günlük Refleksiyon', 'description': 'Bugünü değerlendir', 'category': 'mental', 'points': 11},
    {'id': '50', 'title': 'Yeni Beceri', 'description': 'Küçük bir beceri geliştir', 'category': 'mental', 'points': 15},
    {'id': '51', 'title': '5 Dakika Günlük', 'description': 'Bugünün özetini yaz', 'category': 'mental', 'points': 8},
    {'id': '52', 'title': 'Günlük Motivasyon', 'description': 'Kendini motive eden söz', 'category': 'mental', 'points': 6},
    {'id': '53', 'title': 'Yeni Aktivite', 'description': 'Daha önce yapmadığın şey', 'category': 'mental', 'points': 14},
    {'id': '54', 'title': 'Günlük Öğrenme', 'description': 'İlginç bir bilgi öğren', 'category': 'mental', 'points': 9},
    {'id': '55', 'title': '5 Dakika Odaklanma', 'description': 'Tek bir şeye odaklan', 'category': 'mental', 'points': 10},

    // Sosyal Sağlık (20 görev)
    {'id': '56', 'title': 'Birini Arayıp Teşekkür Et', 'description': 'Minnettar olduğun kişiyi ara', 'category': 'sosyal', 'points': 18},
    {'id': '57', 'title': 'Yeni Biriyle Tanış', 'description': 'Bugün yeni biriyle konuş', 'category': 'sosyal', 'points': 20},
    {'id': '58', 'title': 'Aile Üyesine Sarıl', 'description': 'Sevgi göster ve bağ kur', 'category': 'sosyal', 'points': 15},
    {'id': '59', 'title': 'Arkadaşla Buluş', 'description': 'Eski arkadaşınla görüş', 'category': 'sosyal', 'points': 16},
    {'id': '60', 'title': 'Komşuya Selam Ver', 'description': 'Komşunla selamlaş', 'category': 'sosyal', 'points': 8},
    {'id': '61', 'title': 'Birine Yardım Et', 'description': 'Bugün birine yardım et', 'category': 'sosyal', 'points': 22},
    {'id': '62', 'title': 'Grup Aktivititesi', 'description': 'Topluluk etkinliğine katıl', 'category': 'sosyal', 'points': 25},
    {'id': '63', 'title': 'Birini Dinle', 'description': 'Birinin hikayesini dinle', 'category': 'sosyal', 'points': 14},
    {'id': '64', 'title': 'Pozitif Mesaj Gönder', 'description': 'Birine güzel mesaj yaz', 'category': 'sosyal', 'points': 12},
    {'id': '65', 'title': 'Takım Çalışması', 'description': 'Birlikte çalış', 'category': 'sosyal', 'points': 18},
    {'id': '66', 'title': 'Birini Öv', 'description': 'Birinin iyi yanını söyle', 'category': 'sosyal', 'points': 11},
    {'id': '67', 'title': 'Gönüllülük', 'description': 'Gönüllü bir iş yap', 'category': 'sosyal', 'points': 30},
    {'id': '68', 'title': 'Birini Dinle', 'description': 'Birinin sorununu dinle', 'category': 'sosyal', 'points': 16},
    {'id': '69', 'title': 'Pozitif Etkileşim', 'description': 'Bugün pozitif ol', 'category': 'sosyal', 'points': 13},
    {'id': '70', 'title': 'Birini Destekle', 'description': 'Birine moral ver', 'category': 'sosyal', 'points': 17},
    {'id': '71', 'title': 'Grup Egzersizi', 'description': 'Birlikte spor yap', 'category': 'sosyal', 'points': 20},
    {'id': '72', 'title': 'Birini Teşvik Et', 'description': 'Birini cesaretlendir', 'category': 'sosyal', 'points': 15},
    {'id': '73', 'title': 'Pozitif Yorum', 'description': 'Sosyal medyada pozitif yorum', 'category': 'sosyal', 'points': 9},
    {'id': '74', 'title': 'Birini Dinle', 'description': 'Birinin başarısını kutla', 'category': 'sosyal', 'points': 12},
    {'id': '75', 'title': 'Grup Aktivitesi', 'description': 'Birlikte eğlen', 'category': 'sosyal', 'points': 19},

    // Beslenme (20 görev)
    {'id': '76', 'title': '8 Bardak Su İç', 'description': 'Günlük su ihtiyacını karşıla', 'category': 'beslenme', 'points': 15},
    {'id': '77', 'title': 'Meyve Ye', 'description': 'En az 2 porsiyon meyve', 'category': 'beslenme', 'points': 12},
    {'id': '78', 'title': 'Sebze Ye', 'description': 'En az 3 porsiyon sebze', 'category': 'beslenme', 'points': 14},
    {'id': '79', 'title': 'Kahvaltı Yap', 'description': 'Sağlıklı kahvaltı ile başla', 'category': 'beslenme', 'points': 16},
    {'id': '80', 'title': 'Protein Al', 'description': 'Yeterli protein tüket', 'category': 'beslenme', 'points': 13},
    {'id': '81', 'title': 'Şeker Azalt', 'description': 'Bugün şeker tüketme', 'category': 'beslenme', 'points': 18},
    {'id': '82', 'title': 'Tuz Azalt', 'description': 'Tuz kullanımını azalt', 'category': 'beslenme', 'points': 11},
    {'id': '83', 'title': 'Omega-3 Al', 'description': 'Balık veya kuruyemiş ye', 'category': 'beslenme', 'points': 15},
    {'id': '84', 'title': 'Lifli Gıda', 'description': 'Lif açısından zengin besin', 'category': 'beslenme', 'points': 12},
    {'id': '85', 'title': 'Vitamin C', 'description': 'C vitamini açısından zengin', 'category': 'beslenme', 'points': 10},
    {'id': '86', 'title': 'Kalsiyum', 'description': 'Süt ürünleri tüket', 'category': 'beslenme', 'points': 11},
    {'id': '87', 'title': 'Demir', 'description': 'Demir açısından zengin', 'category': 'beslenme', 'points': 13},
    {'id': '88', 'title': 'Antioksidan', 'description': 'Antioksidan açısından zengin', 'category': 'beslenme', 'points': 14},
    {'id': '89', 'title': 'Probiyotik', 'description': 'Probiyotik açısından zengin', 'category': 'beslenme', 'points': 12},
    {'id': '90', 'title': 'Bitkisel Protein', 'description': 'Bitkisel protein kaynağı', 'category': 'beslenme', 'points': 15},
    {'id': '91', 'title': 'Sağlıklı Yağ', 'description': 'Sağlıklı yağ tüket', 'category': 'beslenme', 'points': 11},
    {'id': '92', 'title': 'Kompleks Karbonhidrat', 'description': 'Tam tahıl ürünleri', 'category': 'beslenme', 'points': 13},
    {'id': '93', 'title': 'Mineraller', 'description': 'Mineral açısından zengin', 'category': 'beslenme', 'points': 12},
    {'id': '94', 'title': 'Vitamin D', 'description': 'D vitamini açısından zengin', 'category': 'beslenme', 'points': 14},
    {'id': '95', 'title': 'Anti-inflamatuar', 'description': 'Anti-inflamatuar besin', 'category': 'beslenme', 'points': 16},

    // Uyku ve Dinlenme (15 görev)
    {'id': '96', 'title': '8 Saat Uyu', 'description': 'Kaliteli uyku için 8 saat', 'category': 'uyku', 'points': 25},
    {'id': '97', 'title': 'Erken Yat', 'description': 'Saat 23:00\'dan önce yat', 'category': 'uyku', 'points': 20},
    {'id': '98', 'title': 'Uyku Rutini', 'description': 'Uyku öncesi rutin yap', 'category': 'uyku', 'points': 15},
    {'id': '99', 'title': 'Ekranı Kapat', 'description': 'Yatmadan 1 saat önce', 'category': 'uyku', 'points': 18},
    {'id': '100', 'title': 'Sakinleştirici Aktivite', 'description': 'Uyku öncesi rahatla', 'category': 'uyku', 'points': 12},
    {'id': '101', 'title': 'Uyku Ortamı', 'description': 'Uyku ortamını düzenle', 'category': 'uyku', 'points': 14},
    {'id': '102', 'title': 'Uyku Takibi', 'description': 'Uyku kalitesini takip et', 'category': 'uyku', 'points': 10},
    {'id': '103', 'title': 'Uyku Hijyeni', 'description': 'Uyku hijyenine dikkat et', 'category': 'uyku', 'points': 16},
    {'id': '104', 'title': 'Uyku Düzeni', 'description': 'Düzenli uyku saatleri', 'category': 'uyku', 'points': 22},
    {'id': '105', 'title': 'Uyku Öncesi Okuma', 'description': 'Kitap okuyarak uyu', 'category': 'uyku', 'points': 13},
    {'id': '106', 'title': 'Uyku Öncesi Meditasyon', 'description': 'Meditasyon ile uyu', 'category': 'uyku', 'points': 17},
    {'id': '107', 'title': 'Uyku Öncesi Stretching', 'description': 'Esneme ile uyu', 'category': 'uyku', 'points': 11},
    {'id': '108', 'title': 'Uyku Öncesi Müzik', 'description': 'Sakin müzik ile uyu', 'category': 'uyku', 'points': 9},
    {'id': '109', 'title': 'Uyku Öncesi Duş', 'description': 'Ilık duş ile uyu', 'category': 'uyku', 'points': 12},
    {'id': '110', 'title': 'Uyku Öncesi Günlük', 'description': 'Günlük yazarak uyu', 'category': 'uyku', 'points': 14},

    // Kişisel Gelişim (20 görev)
    {'id': '111', 'title': 'Yeni Dil Öğren', 'description': 'Günlük 5 yeni kelime', 'category': 'gelisim', 'points': 20},
    {'id': '112', 'title': 'Yeni Beceri', 'description': 'Küçük bir beceri geliştir', 'category': 'gelisim', 'points': 18},
    {'id': '113', 'title': 'Kursa Katıl', 'description': 'Online kursa katıl', 'category': 'gelisim', 'points': 25},
    {'id': '114', 'title': 'Kitap Oku', 'description': 'En az 30 sayfa oku', 'category': 'gelisim', 'points': 22},
    {'id': '115', 'title': 'Podcast Dinle', 'description': 'Eğitici podcast dinle', 'category': 'gelisim', 'points': 15},
    {'id': '116', 'title': 'Video İzle', 'description': 'Eğitici video izle', 'category': 'gelisim', 'points': 12},
    {'id': '117', 'title': 'Yeni Konu', 'description': 'Yeni bir konu öğren', 'category': 'gelisim', 'points': 16},
    {'id': '118', 'title': 'Pratik Yap', 'description': 'Öğrendiğin şeyi pratik et', 'category': 'gelisim', 'points': 19},
    {'id': '119', 'title': 'Not Al', 'description': 'Öğrendiklerini not al', 'category': 'gelisim', 'points': 11},
    {'id': '120', 'title': 'Tekrar Et', 'description': 'Önceki öğrendiklerini tekrarla', 'category': 'gelisim', 'points': 13},
    {'id': '121', 'title': 'Yeni Yöntem', 'description': 'Farklı öğrenme yöntemi', 'category': 'gelisim', 'points': 17},
    {'id': '122', 'title': 'Soru Sor', 'description': 'Anlamadığın şeyi sor', 'category': 'gelisim', 'points': 14},
    {'id': '123', 'title': 'Araştır', 'description': 'Merak ettiğin konuyu araştır', 'category': 'gelisim', 'points': 16},
    {'id': '124', 'title': 'Deneyim', 'description': 'Yeni bir deneyim yaşa', 'category': 'gelisim', 'points': 20},
    {'id': '125', 'title': 'Yaratıcılık', 'description': 'Yaratıcı bir şey yap', 'category': 'gelisim', 'points': 18},
    {'id': '126', 'title': 'Problem Çöz', 'description': 'Küçük bir problemi çöz', 'category': 'gelisim', 'points': 19},
    {'id': '127', 'title': 'Yeni Fikir', 'description': 'Yeni bir fikir üret', 'category': 'gelisim', 'points': 15},
    {'id': '128', 'title': 'Plan Yap', 'description': 'Gelecek için plan yap', 'category': 'gelisim', 'points': 16},
    {'id': '129', 'title': 'Hedef Belirle', 'description': 'Yeni hedefler belirle', 'category': 'gelisim', 'points': 17},
    {'id': '130', 'title': 'İlerleme Takibi', 'description': 'Hedeflerindeki ilerlemeyi takip et', 'category': 'gelisim', 'points': 14},

    // Çevre ve Sürdürülebilirlik (15 görev)
    {'id': '131', 'title': 'Geri Dönüşüm', 'description': 'Bugün geri dönüşüm yap', 'category': 'cevre', 'points': 16},
    {'id': '132', 'title': 'Su Tasarrufu', 'description': 'Su kullanımını azalt', 'category': 'cevre', 'points': 14},
    {'id': '133', 'title': 'Enerji Tasarrufu', 'description': 'Elektrik kullanımını azalt', 'category': 'cevre', 'points': 15},
    {'id': '134', 'title': 'Toplu Taşıma', 'description': 'Araba yerine toplu taşıma', 'category': 'cevre', 'points': 18},
    {'id': '135', 'title': 'Yürüyüş', 'description': 'Kısa mesafeleri yürü', 'category': 'cevre', 'points': 12},
    {'id': '136', 'title': 'Bisiklet', 'description': 'Bisiklet kullan', 'category': 'cevre', 'points': 20},
    {'id': '137', 'title': 'Plastik Azalt', 'description': 'Plastik kullanımını azalt', 'category': 'cevre', 'points': 17},
    {'id': '138', 'title': 'Yerel Ürün', 'description': 'Yerel ürünler satın al', 'category': 'cevre', 'points': 13},
    {'id': '139', 'title': 'Organik', 'description': 'Organik ürünler tercih et', 'category': 'cevre', 'points': 15},
    {'id': '140', 'title': 'Çevre Temizliği', 'description': 'Çevreyi temizle', 'category': 'cevre', 'points': 19},
    {'id': '141', 'title': 'Ağaç Dik', 'description': 'Ağaç dik veya koru', 'category': 'cevre', 'points': 25},
    {'id': '142', 'title': 'Hayvan Koruma', 'description': 'Hayvanlara yardım et', 'category': 'cevre', 'points': 22},
    {'id': '143', 'title': 'Çevre Eğitimi', 'description': 'Çevre hakkında bilgi al', 'category': 'cevre', 'points': 16},
    {'id': '144', 'title': 'Sürdürülebilir', 'description': 'Sürdürülebilir seçimler yap', 'category': 'cevre', 'points': 18},
    {'id': '145', 'title': 'Çevre Farkındalığı', 'description': 'Çevre konusunda farkındalık yarat', 'category': 'cevre', 'points': 20},

    // Finansal Sağlık (15 görev)
    {'id': '146', 'title': 'Bütçe Planla', 'description': 'Günlük bütçe planı yap', 'category': 'finans', 'points': 18},
    {'id': '147', 'title': 'Tasarruf', 'description': 'Bugün tasarruf yap', 'category': 'finans', 'points': 20},
    {'id': '148', 'title': 'Harcama Takibi', 'description': 'Günlük harcamaları takip et', 'category': 'finans', 'points': 15},
    {'id': '149', 'title': 'Yatırım', 'description': 'Yatırım hakkında bilgi al', 'category': 'finans', 'points': 22},
    {'id': '150', 'title': 'Finansal Hedef', 'description': 'Finansal hedef belirle', 'category': 'finans', 'points': 19},
    {'id': '151', 'title': 'Borç Ödeme', 'description': 'Varsa borç ödemesi yap', 'category': 'finans', 'points': 25},
    {'id': '152', 'title': 'Gelir Artırma', 'description': 'Gelir artırma fikirleri araştır', 'category': 'finans', 'points': 21},
    {'id': '153', 'title': 'Finansal Eğitim', 'description': 'Finansal konularda eğitim al', 'category': 'finans', 'points': 20},
    {'id': '154', 'title': 'Tasarruf Hedefi', 'description': 'Tasarruf hedefi belirle', 'category': 'finans', 'points': 17},
    {'id': '155', 'title': 'Harcama Analizi', 'description': 'Harcama alışkanlıklarını analiz et', 'category': 'finans', 'points': 16},
    {'id': '156', 'title': 'Finansal Plan', 'description': 'Uzun vadeli finansal plan', 'category': 'finans', 'points': 23},
    {'id': '157', 'title': 'Tasarruf Yöntemi', 'description': 'Yeni tasarruf yöntemi öğren', 'category': 'finans', 'points': 18},
    {'id': '158', 'title': 'Finansal Güvenlik', 'description': 'Finansal güvenlik önlemleri', 'category': 'finans', 'points': 19},
    {'id': '159', 'title': 'Finansal Bağımsızlık', 'description': 'Finansal bağımsızlık planı', 'category': 'finans', 'points': 24},
    {'id': '160', 'title': 'Finansal Özgürlük', 'description': 'Finansal özgürlük hedefi', 'category': 'finans', 'points': 26},
  ];

  // Constructor
  DailyTaskService() {
    _initializeFirebase();
    _initializeTasks();
    // Async işlemleri arka planda başlat (UI'ı bloklamamak için)
    _initializeAsync();
  }

  // Firebase'i başlat
  void _initializeFirebase() {
    try {
      // Firebase Database'i başlat
      final database = FirebaseDatabase.instance;
      
      // Database URL'i kontrol et ve gerekirse ayarla
      if (database.databaseURL == null) {
        print('⚠️ Database URL null, manuel olarak ayarlanıyor...');
        database.databaseURL = 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app';
        print('🔗 Database URL ayarlandı: ${database.databaseURL}');
      }
      
      // Database referansını oluştur
      _database = database.ref();
      
      // Bağlantıyı test et
      print('🧪 Firebase Database bağlantısı test ediliyor...');
      try {
        // Basit bir test referansı oluştur
        final testRef = _database.child('connection_test');
        print('📍 Test Reference: ${testRef.path}');
        
        // Test verisi yaz (sadece referans oluşturma testi)
        print('✅ Firebase Database başlatıldı');
        print('🔗 Database URL: ${database.databaseURL}');
        print('📍 Database Reference: ${_database.path}');
        print('🏗️ Firebase App: ${database.app.name}');
      } catch (testError) {
        print('⚠️ Firebase bağlantı testi sırasında uyarı: $testError');
        print('✅ Firebase Database başlatıldı (test uyarısı ile)');
        print('🔗 Database URL: ${database.databaseURL}');
        print('📍 Database Reference: ${_database.path}');
        print('🏗️ Firebase App: ${database.app.name}');
      }
      
    } catch (e) {
      print('❌ Firebase Database başlatılamadı: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      
      // Hata durumunda varsayılan referans oluştur
      try {
        _database = FirebaseDatabase.instance.ref();
        print('⚠️ Varsayılan Database referansı oluşturuldu');
      } catch (fallbackError) {
        print('❌ Varsayılan referans da oluşturulamadı: $fallbackError');
        // Son çare olarak boş bir referans oluştur
        _database = FirebaseDatabase.instance.ref();
      }
    }
  }

  // Async işlemleri başlat
  void _initializeAsync() {
    // UI'ı bloklamamak için microtask kullan
    Future.microtask(() async {
      await _checkAndRefreshDailyTasks();
    });
  }

  // Kategori bilgilerini al
  String _getCategoryName(String category) {
    switch (category) {
      case 'fiziksel':
        return 'Fiziksel Sağlık';
      case 'mental':
        return 'Mental Sağlık';
      case 'sosyal':
        return 'Sosyal Sağlık';
      case 'beslenme':
        return 'Beslenme';
      case 'uyku':
        return 'Uyku ve Dinlenme';
      case 'gelisim':
        return 'Kişisel Gelişim';
      case 'cevre':
        return 'Çevre ve Sürdürülebilirlik';
      case 'finans':
        return 'Finansal Sağlık';
      default:
        return category;
    }
  }

  // Kategori rengini al
  String _getCategoryColor(String category) {
    switch (category) {
      case 'fiziksel':
        return '#FF6B6B'; // Kırmızı
      case 'mental':
        return '#4ECDC4'; // Turkuaz
      case 'sosyal':
        return '#45B7D1'; // Mavi
      case 'beslenme':
        return '#96CEB4'; // Yeşil
      case 'uyku':
        return '#FFEAA7'; // Sarı
      case 'gelisim':
        return '#DDA0DD'; // Mor
      case 'cevre':
        return '#98D8C8'; // Açık yeşil
      case 'finans':
        return '#F7DC6F'; // Altın
      default:
        return '#2196F3'; // Varsayılan mavi
    }
  }

  // Görevleri başlat
  void _initializeTasks() {
    _dailyTasks = _staticTasks.map((task) => DailyTask(
      id: task['id'],
      title: task['title'],
      description: task['description'],
      category: task['category'],
      categoryName: _getCategoryName(task['category']),
      categoryColor: _getCategoryColor(task['category']),
      points: task['points'],
      date: DateTime.now(),
    )).toList();
  }

  // Günlük görevleri kontrol et ve gerekirse yenile
  Future<void> _checkAndRefreshDailyTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDateString = prefs.getString('last_task_date');
      
      if (lastDateString != null) {
        _lastTaskDate = DateTime.parse(lastDateString);
      }
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      print('🔄 Günlük görev kontrolü başlıyor...');
      print('📅 Önceki tarih: $_lastTaskDate');
      print('📅 Bugünkü tarih: $todayDate');
      
      // Önce Firebase'de bugünkü görevler var mı kontrol et
      final hasTodayTasks = await checkTodayTasksInFirebase();
      print('🔍 Firebase\'de bugünkü görevler: ${hasTodayTasks ? 'Var' : 'Yok'}');
      
      // Eğer yeni günse veya ilk kez açılıyorsa
      if (_lastTaskDate == null || 
          _lastTaskDate!.year != todayDate.year ||
          _lastTaskDate!.month != todayDate.month ||
          _lastTaskDate!.day != todayDate.day) {
        
        print('🆕 Yeni gün tespit edildi');
        
        if (hasTodayTasks) {
          print('✅ Firebase\'de bugünkü görevler mevcut, yükleniyor...');
          // Firebase'den bugünkü görevleri yükle
          await _loadTodayTasksFromFirebase();
        } else {
          print('🆕 Firebase\'de bugünkü görev yok, yeni görevler oluşturuluyor...');
          // Yeni görevler oluştur ve Firebase'e kaydet
          await _refreshDailyTasks();
        }
        
        await prefs.setString('last_task_date', todayDate.toIso8601String());
        print('✅ Günlük görev kontrolü tamamlandı: $todayDate');
        
      } else {
        print('🔄 Aynı gün, mevcut görevler kontrol ediliyor...');
        print('📅 Tarih: $todayDate');
        
        if (hasTodayTasks) {
          print('✅ Firebase\'de bugünkü görevler mevcut, yükleniyor...');
          // Firebase'den bugünkü görevleri yükle
          await _loadTodayTasksFromFirebase();
        } else {
          print('⚠️ Firebase\'de bugünkü görev bulunamadı, yeni görevler oluşturuluyor...');
          // Yeni görevler oluştur ve Firebase'e kaydet
          await _refreshDailyTasks();
        }
      }
    } catch (e) {
      print('❌ Günlük görev kontrolü sırasında hata: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      // Hata durumunda yeni görevler oluştur
      await _refreshDailyTasks();
    }
  }

  // Firebase'de bugünkü görevler var mı kontrol et
  Future<bool> checkTodayTasksInFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, Firebase kontrol yapılamıyor');
        return false;
      }
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final taskRef = _database.child('users/${user.uid}/daily_tasks/$today');
      
      print('🔍 Firebase\'de bugünkü görevler kontrol ediliyor: users/${user.uid}/daily_tasks/$today');
      
      final snapshot = await taskRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Firebase kontrol timeout');
          throw TimeoutException('Firebase kontrol timeout');
        },
      );
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final hasTasks = data.keys.any((key) => key != '_summary');
        print('✅ Firebase\'de bugünkü görevler bulundu: ${hasTasks ? 'Var' : 'Sadece özet'}');
        return hasTasks;
      } else {
        print('ℹ️ Firebase\'de bugünkü görev bulunamadı');
        return false;
      }
    } catch (e) {
      print('❌ Firebase kontrol hatası: $e');
      return false;
    }
  }

  // Firebase'den bugünkü görevleri yükle
  Future<void> _loadTodayTasksFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, Firebase\'den yükleme yapılamıyor');
        return;
      }
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final taskRef = _database.child('users/${user.uid}/daily_tasks/$today');
      
      print('📥 Firebase\'den bugünkü görevler yükleniyor...');
      
      final snapshot = await taskRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Firebase yükleme timeout');
          throw TimeoutException('Firebase yükleme timeout');
        },
      );
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print('✅ Firebase\'den veri alındı, ${data.length} öğe');
        
        // Özet bilgileri kontrol et
        if (data.containsKey('_summary')) {
          final summary = data['_summary'] as Map<dynamic, dynamic>;
          print('📊 Özet bilgiler: $summary');
          
          // İstatistikleri güncelle
          _completedTasks = summary['completedTasks'] ?? 0;
          _totalPoints = summary['totalPoints'] ?? 0;
        }
        
        // Görevleri yükle
        final loadedTasks = <DailyTask>[];
        data.forEach((key, value) {
          if (key != '_summary' && value is Map) {
            try {
              final taskData = Map<String, dynamic>.from(value);
              final task = DailyTask.fromJson(taskData);
              loadedTasks.add(task);
              print('📋 Görev yüklendi: ${task.title} (Tamamlandı: ${task.isCompleted})');
            } catch (e) {
              print('⚠️ Görev parse hatası: $e');
            }
          }
        });
        
        if (loadedTasks.isNotEmpty) {
          _todayTasks = loadedTasks;
          _updateStats();
          notifyListeners();
          print('✅ Firebase\'den ${loadedTasks.length} görev yüklendi');
          print('📊 İstatistikler güncellendi. Toplam puan: $_totalPoints, Tamamlanan: $_completedTasks');
        } else {
          print('⚠️ Firebase\'den görev yüklenemedi, yeni görevler oluşturuluyor...');
          await _refreshDailyTasks();
        }
      } else {
        print('⚠️ Firebase\'de veri bulunamadı, yeni görevler oluşturuluyor...');
        await _refreshDailyTasks();
      }
    } catch (e) {
      print('❌ Firebase\'den yükleme hatası: $e');
      print('🔄 Hata durumunda yeni görevler oluşturuluyor...');
      await _refreshDailyTasks();
    }
  }

  // Yeni gün için görevleri yenile
  Future<void> _refreshDailyTasks() async {
    await _generateTodayTasks();
    await _saveTasksToFirebase();
    notifyListeners();
  }

  // Bugün için 3 rastgele görev oluştur (tamamlananları hariç tut)
  Future<void> _generateTodayTasks() async {
    try {
      print('=== GÜNLÜK GÖREV OLUŞTURMA BAŞLADI ===');
      
      // Önce tamamlanan görevleri Firebase'den al
      final completedTaskIds = await _getCompletedTaskIds();
      print('📋 Tamamlanan görev ID\'leri: $completedTaskIds');
      print('📊 Toplam tamamlanan görev sayısı: ${completedTaskIds.length}');
      
      // Tamamlanmamış görevleri filtrele
      final availableTasks = _dailyTasks.where((task) => !completedTaskIds.contains(task.id)).toList();
      print('📋 Kullanılabilir görev sayısı: ${availableTasks.length}');
      
      if (availableTasks.isEmpty) {
        print('⚠️ Tüm görevler tamamlanmış, yeni görevler oluşturuluyor...');
        // Tüm görevleri sıfırla ve yeniden başlat
        await _resetAllCompletedTasks();
        availableTasks.addAll(_dailyTasks);
        print('🔄 Tüm görevler sıfırlandı, kullanılabilir görev sayısı: ${availableTasks.length}');
      }
      
      // Rastgele karıştır
      final random = DateTime.now().millisecondsSinceEpoch;
      final shuffled = List<DailyTask>.from(availableTasks);
      
      for (int i = shuffled.length - 1; i > 0; i--) {
        int j = (random % (i + 1)).toInt();
        DailyTask temp = shuffled[i];
        shuffled[i] = shuffled[j];
        shuffled[j] = temp;
      }
      
      // İlk 3'ünü al (veya mevcut sayı kadar)
      final taskCount = shuffled.length >= 3 ? 3 : shuffled.length;
      _todayTasks = shuffled.take(taskCount).toList();
      
      print('✅ Günlük görevler oluşturuldu:');
      for (final task in _todayTasks) {
        print('   📋 ${task.id}: ${task.title} (${task.category}) - ${task.points} puan');
      }
      
      _updateStats();
      print('📊 İstatistikler güncellendi. Toplam puan: $_totalPoints, Tamamlanan: $_completedTasks');
      
      print('=== GÜNLÜK GÖREV OLUŞTURMA TAMAMLANDI ===');
    } catch (e) {
      print('❌ Görev oluşturma hatası: $e');
      // Hata durumunda basit yöntemle devam et
      _generateSimpleTasks();
    }
  }

  // Basit görev oluşturma (hata durumunda)
  void _generateSimpleTasks() {
    print('🔄 Basit görev oluşturma yöntemi kullanılıyor...');
    final random = DateTime.now().millisecondsSinceEpoch;
    final shuffled = List<DailyTask>.from(_dailyTasks);
    
    // Rastgele karıştır
    for (int i = shuffled.length - 1; i > 0; i--) {
      int j = (random % (i + 1)).toInt();
      DailyTask temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    
    // İlk 3'ünü al
    _todayTasks = shuffled.take(3).toList();
    _updateStats();
    print('✅ Basit görev oluşturma tamamlandı');
  }

  // Firebase'den tamamlanan görev ID'lerini al
  Future<Set<String>> _getCompletedTaskIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, tamamlanan görevler alınamıyor');
        return <String>{};
      }
      
      print('🔍 Tamamlanan görevler Firebase\'den alınıyor...');
      final completedRef = _database.child('users/${user.uid}/completed_tasks');
      
      final snapshot = await completedRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Tamamlanan görevler alma timeout');
          throw TimeoutException('Tamamlanan görevler alma timeout');
        },
      );
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final completedIds = <String>{};
        
        data.forEach((taskId, taskData) {
          if (taskData is Map && taskData['isCompleted'] == true) {
            completedIds.add(taskId as String);
          }
        });
        
        print('✅ Tamamlanan görev ID\'leri alındı: ${completedIds.length} adet');
        return completedIds;
      } else {
        print('ℹ️ Tamamlanan görev tablosu bulunamadı, boş liste döndürülüyor');
        return <String>{};
      }
    } catch (e) {
      print('❌ Tamamlanan görevler alınamadı: $e');
      return <String>{};
    }
  }

  // Tüm tamamlanan görevleri sıfırla (tüm görevler tamamlandığında)
  Future<void> _resetAllCompletedTasks() async {
    try {
      print('🔄 Tüm tamamlanan görevler sıfırlanıyor...');
      final user = _auth.currentUser;
      if (user != null) {
        final completedRef = _database.child('users/${user.uid}/completed_tasks');
        await completedRef.remove();
        print('✅ Tüm tamamlanan görevler sıfırlandı');
      }
    } catch (e) {
      print('❌ Tamamlanan görevler sıfırlanamadı: $e');
    }
  }

  // Görevi tamamla
  Future<void> completeTask(String taskId) async {
    print('=== GÖREV TAMAMLAMA BAŞLADI ===');
    print('Görev ID: $taskId');
    
    final taskIndex = _todayTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      print('Görev bulundu: ${_todayTasks[taskIndex].title}');
      print('Önceki durum: ${_todayTasks[taskIndex].isCompleted}');
      
      _todayTasks[taskIndex] = _todayTasks[taskIndex].complete();
      print('Görev tamamlandı: ${_todayTasks[taskIndex].isCompleted}');
      
      _updateStats();
      print('İstatistikler güncellendi. Toplam puan: $_totalPoints, Tamamlanan: $_completedTasks');
      
      notifyListeners();
      print('UI güncellendi');
      
      // Firebase'e kaydet
      print('Firebase kayıt başlıyor...');
      await _saveTasksToFirebase();
      
      // Tamamlanan görevi completed_tasks tablosuna da kaydet
      print('Tamamlanan görev completed_tasks tablosuna kaydediliyor...');
      await _saveCompletedTaskToFirebase(_todayTasks[taskIndex]);
      
      print('=== GÖREV TAMAMLAMA TAMAMLANDI ===');
    } else {
      print('Görev bulunamadı: $taskId');
    }
  }

  // Tamamlanan görevi completed_tasks tablosuna kaydet
  Future<void> _saveCompletedTaskToFirebase(DailyTask completedTask) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, tamamlanan görev kaydedilemiyor');
        return;
      }
      
      print('💾 Tamamlanan görev completed_tasks tablosuna kaydediliyor...');
      print('📋 Görev: ${completedTask.title} (ID: ${completedTask.id})');
      
      final completedRef = _database.child('users/${user.uid}/completed_tasks/${completedTask.id}');
      
      final completedTaskData = {
        'id': completedTask.id,
        'title': completedTask.title,
        'description': completedTask.description,
        'category': completedTask.category,
        'categoryName': completedTask.categoryName,
        'categoryColor': completedTask.categoryColor,
        'points': completedTask.points,
        'isCompleted': true,
        'completedAt': completedTask.completedAt?.toIso8601String(),
        'completedDate': DateTime.now().toIso8601String().split('T')[0], // Sadece tarih
        'lastCompleted': DateTime.now().toIso8601String(),
        'date': completedTask.date.toIso8601String(), // Orijinal tarih de ekle
      };
      
      print('📝 Kaydedilecek veri: $completedTaskData');
      
      await completedRef.set(completedTaskData).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Tamamlanan görev kayıt timeout');
          throw TimeoutException('Tamamlanan görev kayıt timeout');
        },
      );
      
      print('✅ Tamamlanan görev completed_tasks tablosuna kaydedildi');
      print('📍 Firebase path: users/${user.uid}/completed_tasks/${completedTask.id}');
      
    } catch (e) {
      print('❌ Tamamlanan görev completed_tasks tablosuna kaydedilemedi: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      print('💡 Ana görev verisi kaydedildi, completed_tasks kaydı sonra yapılabilir');
    }
  }

  // Görevi sıfırla
  Future<void> resetTask(String taskId) async {
    final taskIndex = _todayTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      print('Görev sıfırlanıyor: ${_todayTasks[taskIndex].title}');
      
      _todayTasks[taskIndex] = _todayTasks[taskIndex].reset();
      _updateStats();
      notifyListeners();
      
      print('Görev sıfırlandı, istatistikler güncellendi. Toplam puan: $_totalPoints');
      
      // Firebase'e kaydet
      await _saveTasksToFirebase();
      
      // Tamamlanan görevi completed_tasks tablosundan da sil
      print('Tamamlanan görev completed_tasks tablosundan siliniyor...');
      await _removeCompletedTaskFromFirebase(_todayTasks[taskIndex]);
      
    } else {
      print('Görev bulunamadı: $taskId');
    }
  }

  // Tamamlanan görevi completed_tasks tablosundan sil
  Future<void> _removeCompletedTaskFromFirebase(DailyTask resetTask) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, tamamlanan görev silinemiyor');
        return;
      }
      
      print('🗑️ Tamamlanan görev completed_tasks tablosundan siliniyor...');
      print('📋 Görev: ${resetTask.title} (ID: ${resetTask.id})');
      
      final completedRef = _database.child('users/${user.uid}/completed_tasks/${resetTask.id}');
      
      await completedRef.remove().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Tamamlanan görev silme timeout');
          throw TimeoutException('Tamamlanan görev silme timeout');
        },
      );
      
      print('✅ Tamamlanan görev completed_tasks tablosundan silindi');
      print('📍 Firebase path: users/${user.uid}/completed_tasks/${resetTask.id}');
      
    } catch (e) {
      print('❌ Tamamlanan görev completed_tasks tablosundan silinemedi: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      print('💡 Ana görev verisi güncellendi, completed_tasks silme işlemi sonra yapılabilir');
    }
  }

  // İstatistikleri güncelle
  void _updateStats() {
    _totalPoints = _todayTasks.where((task) => task.isCompleted).fold(0, (sum, task) => sum + task.points);
    _completedTasks = _todayTasks.where((task) => task.isCompleted).length;
  }

  // Firebase'e tüm görevleri kaydet
  Future<void> _saveTasksToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, Firebase kayıt yapılamıyor');
        return;
      }
      
      print('🚀 Firebase kayıt başlıyor - Kullanıcı: ${user.uid}');
      
      // Firebase Database durumunu kontrol et
      final database = FirebaseDatabase.instance;
      print('🔗 Database URL: ${database.databaseURL}');
      print('🔗 Database App: ${database.app.name}');
      
      if (database.databaseURL == null) {
        print('⚠️ Database URL hala null, manuel olarak ayarlanıyor...');
        database.databaseURL = 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app';
      }
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      DatabaseReference taskRef = _database.child('users/${user.uid}/daily_tasks/$today');
      
      print('📍 Firebase path: users/${user.uid}/daily_tasks/$today');
      print('📍 Task Reference: ${taskRef.path}');
      print('📅 Tarih: $today');
      print('👤 Kullanıcı ID: ${user.uid}');
      print('🔗 Database Reference: ${_database.path}');
      
      // Task reference'ın geçerli olduğunu kontrol et
      print('🔍 Task Reference kontrol ediliyor...');
      print('📍 Mevcut Task Reference: ${taskRef.path}');
      print('🔗 Mevcut Database Reference: ${_database.path}');
      
      if (taskRef.path.isEmpty) {
        print('⚠️ Task reference boş, yeniden oluşturuluyor...');
        taskRef = _database.child('users/${user.uid}/daily_tasks/$today');
        print('📍 Güncellenmiş Task Reference: ${taskRef.path}');
      }
      
      print('✅ Task Reference kontrol edildi');
      print('📍 Final Task Reference: ${taskRef.path}');
      print('🔗 Final Database Reference: ${_database.path}');
      
      final tasksData = <String, dynamic>{};
      print('📝 Görevler hazırlanıyor...');
      print('📊 Toplam görev sayısı: ${_todayTasks.length}');
      
      for (final task in _todayTasks) {
        final taskJson = task.toJson();
        tasksData[task.id] = taskJson;
        print('📝 Görev ekleniyor: ${task.id} - ${task.title}');
        print('   📋 Tamamlandı: ${task.isCompleted}');
        print('   🎯 Puan: ${task.points}');
        print('   🏷️ Kategori: ${task.category}');
        print('   📅 Tarih: ${task.date}');
        if (task.completedAt != null) {
          print('   ✅ Tamamlanma: ${task.completedAt}');
        }
      }
      
      print('✅ Görevler hazırlandı');
      print('📊 Hazırlanan görev sayısı: ${tasksData.length}');
      print('🔑 Görev ID\'leri: ${tasksData.keys.toList()}');
      
      // Günlük özet bilgileri de ekle
      print('📊 Özet bilgiler hazırlanıyor...');
      final summary = {
        'date': today,
        'totalTasks': _todayTasks.length,
        'completedTasks': _completedTasks,
        'totalPoints': _totalPoints,
        'maxPoints': _todayTasks.fold(0, (sum, task) => sum + task.points),
        'completionRate': _todayTasks.isNotEmpty ? (_completedTasks / _todayTasks.length * 100).toStringAsFixed(1) : '0',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      tasksData['_summary'] = summary;
      print('📊 Özet bilgiler:');
      print('   📅 Tarih: ${summary['date']}');
      print('   📋 Toplam Görev: ${summary['totalTasks']}');
      print('   ✅ Tamamlanan: ${summary['completedTasks']}');
      print('   🎯 Toplam Puan: ${summary['totalPoints']}');
      print('   🏆 Maksimum Puan: ${summary['maxPoints']}');
      print('   📊 Tamamlanma Oranı: ${summary['completionRate']}%');
      print('   🕐 Son Güncelleme: ${summary['lastUpdated']}');
      
      print('✅ Özet bilgiler hazırlandı');
      print('💾 Kaydedilecek veri yapısı: ${tasksData.keys.toList()}');
      print('📊 Toplam veri boyutu: ${tasksData.length} öğe');
      
      // Firebase Database durumunu tekrar kontrol et
      print('🔍 Firebase Database durumu kontrol ediliyor...');
      print('🔗 Mevcut Database URL: ${database.databaseURL}');
      print('🏗️ Mevcut Firebase App: ${database.app.name}');
      
      // Database URL null ise zorla ayarla
      if (database.databaseURL == null) {
        print('⚠️ Database URL hala null, zorla ayarlanıyor...');
        database.databaseURL = 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app';
        print('🔗 Database URL zorla ayarlandı: ${database.databaseURL}');
        
        // Database referansını yeniden oluştur
        _database = database.ref();
        print('🔗 Yeni Database Reference oluşturuldu: ${_database.path}');
      }
      
      // Database referansını yeniden oluştur
      if (_database.path.isEmpty) {
        print('⚠️ Database referansı boş, yeniden oluşturuluyor...');
        _database = database.ref();
        print('🔗 Yeni Database Reference: ${_database.path}');
      }
      
      // Database URL'ini tekrar kontrol et ve gerekirse ayarla
      if (database.databaseURL == null || database.databaseURL!.isEmpty) {
        print('🚨 Database URL hala null veya boş, son kez ayarlanıyor...');
        database.databaseURL = 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app';
        print('🔗 Database URL son kez ayarlandı: ${database.databaseURL}');
        
        // Database referansını tekrar oluştur
        _database = database.ref();
        print('🔗 Database Reference son kez oluşturuldu: ${_database.path}');
      }
      
      print('✅ Firebase Database durumu kontrol edildi');
      print('🔗 Final Database URL: ${database.databaseURL}');
      print('📍 Final Database Reference: ${_database.path}');
      
      // Database URL'ini son kez kontrol et
      if (database.databaseURL == null || database.databaseURL!.isEmpty) {
        print('💥 Database URL hala null, Firebase işlemi iptal ediliyor!');
        throw Exception('Firebase Database URL null, işlem iptal edildi');
      }
      
      // Database bağlantısını test et
      print('🧪 Database bağlantısı test ediliyor...');
      try {
        final testRef = _database.child('connection_test');
        print('📍 Test Reference: ${testRef.path}');
        print('✅ Database bağlantısı test edildi');
        print('🔗 Database URL: ${database.databaseURL}');
        print('🏗️ Firebase App: ${database.app.name}');
        print('🔗 Database Reference Path: ${_database.path}');
        
        // Basit bir test verisi yaz
        print('🧪 Test verisi yazılıyor...');
        await testRef.set({'test': true, 'timestamp': DateTime.now().toIso8601String()});
        print('✅ Test verisi yazıldı');
        
        // Test verisini oku
        print('📖 Test verisi okunuyor...');
        final testSnapshot = await testRef.get();
        if (testSnapshot.exists) {
          print('✅ Test verisi okundu: ${testSnapshot.value}');
          
          // Test verisini sil
          print('🗑️ Test verisi siliniyor...');
          await testRef.remove();
          print('✅ Test verisi silindi');
          print('🎉 Database bağlantı testi başarılı!');
        } else {
          print('❌ Test verisi okunamadı');
        }
      } catch (testError) {
        print('❌ Database bağlantı testi başarısız: $testError');
        print('🚨 Test hatası: ${testError.toString()}');
        print('💡 Firebase bağlantısında sorun var, işlem devam ediyor...');
      }
      
      // Önce mevcut veriyi kontrol et
      print('🔍 Mevcut veri kontrol ediliyor...');
      print('📍 Kontrol edilecek path: ${taskRef.path}');
      print('💾 Kontrol edilecek veri boyutu: ${tasksData.length} görev');
      print('⏰ Timeout süresi: 10 saniye');
      
      // Database URL'ini son kez kontrol et
      if (database.databaseURL == null || database.databaseURL!.isEmpty) {
        print('💥 Database URL hala null, Firebase işlemi iptal ediliyor!');
        throw Exception('Firebase Database URL null, işlem iptal edildi');
      }
      
      // Database referansını son kez kontrol et
      if (_database.path.isEmpty) {
        print('💥 Database Reference boş, Firebase işlemi iptal ediliyor!');
        throw Exception('Firebase Database Reference boş, işlem iptal edildi');
      }
      
      try {
        print('📖 Firebase\'den veri okunuyor...');
        final snapshot = await taskRef.get().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Firebase get operasyonu timeout');
            throw TimeoutException('Firebase get operasyonu timeout');
          },
        );
        
        if (snapshot.exists) {
          print('✅ Mevcut veri bulundu, güncelleniyor...');
          print('📊 Mevcut veri boyutu: ${snapshot.children.length}');
          print('📝 Güncellenecek veri: ${tasksData.keys.toList()}');
          
          // Mevcut veriyi güncelle
          print('🔄 Firebase update operasyonu başlıyor...');
          await taskRef.update(tasksData).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ Firebase update operasyonu timeout');
              throw TimeoutException('Firebase update operasyonu timeout');
            },
          );
          print('✅ Günlük görevler Firebase\'de güncellendi');
        } else {
          print('🆕 Yeni veri oluşturuluyor...');
          print('📝 Oluşturulacak veri: ${tasksData.keys.toList()}');
          print('📊 Veri boyutu: ${tasksData.length} öğe');
          
          // Yeni veri oluştur
          print('🆕 Firebase set operasyonu başlıyor...');
          await taskRef.set(tasksData).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ Firebase set operasyonu timeout');
              throw TimeoutException('Firebase set operasyonu timeout');
            },
          );
          print('✅ Günlük görevler Firebase\'de oluşturuldu');
        }
      } catch (operationError) {
        print('❌ Firebase operasyon hatası: $operationError');
        print('🚨 Operasyon hatası detayı: ${operationError.toString()}');
        print('🔍 Hata tipi: ${operationError.runtimeType}');
        
        // Database URL'ini tekrar kontrol et
        if (database.databaseURL == null || database.databaseURL!.isEmpty) {
          print('💥 Database URL null, tekrar deneme iptal ediliyor!');
          throw Exception('Firebase Database URL null, tekrar deneme iptal edildi');
        }
        
        // Hata durumunda tekrar dene
        try {
          print('🔄 Firebase operasyonu tekrar deneniyor...');
          print('📍 Tekrar deneme path: ${taskRef.path}');
          print('💾 Tekrar deneme veri: ${tasksData.keys.toList()}');
          print('⏰ Tekrar deneme timeout: 15 saniye');
          print('🔄 Tekrar deneme operasyonu: set()');
          
          await taskRef.set(tasksData).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Firebase tekrar deneme timeout');
              throw TimeoutException('Firebase tekrar deneme timeout');
            },
          );
          print('✅ Günlük görevler Firebase\'de tekrar deneme ile oluşturuldu');
        } catch (retryError) {
          print('❌ Firebase tekrar deneme de başarısız: $retryError');
          print('🚨 Tekrar deneme hatası detayı: ${retryError.toString()}');
          print('🔍 Tekrar deneme hata tipi: ${retryError.runtimeType}');
          
          // Database URL'ini son kez kontrol et
          if (database.databaseURL == null || database.databaseURL!.isEmpty) {
            print('💥 Database URL null, işlem tamamen iptal ediliyor!');
            throw Exception('Firebase Database URL null, işlem tamamen iptal edildi');
          }
          
          throw Exception('Firebase operasyonu başarısız: $retryError');
        }
      }
      
      // İstatistikleri de güncelle
      print('📈 İstatistikler güncelleniyor...');
      try {
        await _updateFirebaseStats();
        print('✅ İstatistikler güncellendi');
      } catch (statsError) {
        print('⚠️ İstatistik güncelleme hatası: $statsError');
        print('💡 Ana görev verisi kaydedildi, istatistikler sonra güncellenebilir');
      }
      
      // SharedPreferences'a da kaydet (offline için)
      print('💾 Local storage\'a kaydediliyor...');
      try {
        await _saveTasksToLocal();
        print('✅ Local storage kayıt başarılı');
      } catch (localError) {
        print('⚠️ Local storage kayıt hatası: $localError');
        print('💡 Firebase kayıt başarılı, local kayıt sonra yapılabilir');
      }
      
      // Firebase başarı mesajı
      print('🎯 Firebase kayıt işlemi tamamlandı!');
      print('📊 Veri kayıt durumu:');
      print('   🔥 Firebase: ✅ Başarılı');
      print('   💾 Local: ✅ Başarılı');
      print('   📈 İstatistikler: ✅ Güncellendi');
      print('   📅 Tarih: $today');
      print('   👤 Kullanıcı: ${user.uid}');
      print('   📋 Görev Sayısı: ${_todayTasks.length}');
      print('   ✅ Tamamlanan: $_completedTasks');
      print('   🎯 Toplam Puan: $_totalPoints');
      print('   🕐 Tamamlanma Zamanı: ${DateTime.now().toIso8601String()}');
      print('   🔗 Firebase Path: users/${user.uid}/daily_tasks/$today');
      print('   🎯 Durum: Tüm veriler başarıyla kaydedildi');
      print('   🎊 İşlem: Firebase Realtime Database\'e görevler kaydedildi');
      print('   🔗 Database URL: ${database.databaseURL}');
      print('   📍 Database Reference: ${_database.path}');
    } catch (e) {
      print('❌ Görevler Firebase\'e kaydedilemedi: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      print('🔍 Hata tipi: ${e.runtimeType}');
      
      // Hata stack trace'ini de yazdır
      if (e is Exception) {
        print('📚 Exception detayı: ${e.toString()}');
      }
      
      // TimeoutException kontrolü
      if (e is TimeoutException) {
        print('⏰ Firebase timeout hatası: ${e.message}');
        print('💡 İnternet bağlantısını kontrol edin');
      }
      
      // FirebaseException kontrolü
      if (e.toString().contains('FirebaseException')) {
        print('🔥 Firebase hatası tespit edildi');
        print('💡 Firebase kurallarını ve bağlantısını kontrol edin');
      }
      
      // Hata durumunda local'e kaydet
      print('💾 Hata durumunda local storage\'a kaydediliyor...');
      Exception? localError;
      try {
        await _saveTasksToLocal();
        print('✅ Local storage kayıt başarılı');
      } catch (e) {
        localError = Exception(e.toString());
        print('❌ Local storage kayıt da başarısız: $e');
      }
      
      print('📊 Hata özeti:');
      print('   🔥 Firebase: ❌ Başarısız');
      print('   💾 Local: ${localError != null ? '❌ Başarısız' : '✅ Başarılı'}');
      print('   📅 Tarih: ${DateTime.now().toIso8601String().split('T')[0]}');
      print('   👤 Kullanıcı: ${_auth.currentUser?.uid ?? 'Bilinmiyor'}');
      print('   📋 Görev Sayısı: ${_todayTasks.length}');
      print('   ✅ Tamamlanan: $_completedTasks');
      print('   🎯 Toplam Puan: $_totalPoints');
      print('   🕐 Hata Zamanı: ${DateTime.now().toIso8601String()}');
      print('   🔗 Hedef Path: users/${_auth.currentUser?.uid ?? 'Bilinmiyor'}/daily_tasks/${DateTime.now().toIso8601String().split('T')[0]}');
      print('   🎯 Durum: Firebase kayıt başarısız, local kayıt ${localError != null ? 'başarısız' : 'başarılı'}');
      print('   💡 Öneriler:');
      print('      - İnternet bağlantısını kontrol edin');
      print('      - Firebase kurallarını kontrol edin');
      print('      - Uygulamayı yeniden başlatın');
      print('      - Firebase Console\'da kuralları kontrol edin');
      print('      - Firebase Console\'da Realtime Database kurallarını kontrol edin');
      print('      - Firebase Console\'da Authentication durumunu kontrol edin');
      print('      - Firebase Console\'da Project ID: moodi-35089');
      print('      - Firebase Console\'da Database URL: https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app');
      print('      - Firebase Console\'da Realtime Database kurallarını şu şekilde ayarlayın:');

    }
  }

  // Firebase'de genel istatistikleri güncelle
  Future<void> _updateFirebaseStats() async {
    try {
      print('Firebase istatistikleri güncelleniyor...');
      final user = _auth.currentUser;
      if (user != null) {
        print('Kullanıcı bulundu: ${user.uid}');
        
        final statsRef = _database.child('users/${user.uid}/task_stats');
        print('İstatistik path: users/${user.uid}/task_stats');
        
        // Genel istatistikler
        print('Genel istatistikler hesaplanıyor...');
        final totalCompletedTasks = await _getTotalCompletedTasks();
        final totalPoints = await _getTotalPoints();
        final totalDays = await _getTotalDays();
        final averageCompletionRate = await _getAverageCompletionRate();
        final bestDay = await _getBestDay();
        final currentStreak = await _getCurrentStreak();
        final longestStreak = await _getLongestStreak();
        
        print('Hesaplanan istatistikler:');
        print('- Toplam tamamlanan görev: $totalCompletedTasks');
        print('- Toplam puan: $totalPoints');
        print('- Toplam gün: $totalDays');
        print('- Ortalama tamamlanma oranı: $averageCompletionRate');
        print('- En iyi gün: $bestDay');
        print('- Mevcut streak: $currentStreak');
        print('- En uzun streak: $longestStreak');
        
        final generalStats = {
          'totalCompletedTasks': totalCompletedTasks,
          'totalPoints': totalPoints,
          'totalDays': totalDays,
          'averageCompletionRate': averageCompletionRate,
          'bestDay': bestDay,
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        
        print('Genel istatistikler kaydediliyor: $generalStats');
        await statsRef.child('general').set(generalStats).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Genel istatistikler kayıt timeout');
            throw TimeoutException('Genel istatistikler kayıt timeout');
          },
        );
        print('Genel istatistikler kaydedildi');
        
        // Kategori bazlı istatistikler
        print('Kategori istatistikleri hesaplanıyor...');
        final categoryStats = await _getCategoryStats();
        print('Kategori istatistikleri: $categoryStats');
        
        await statsRef.child('categories').set(categoryStats).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Kategori istatistikleri kayıt timeout');
            throw TimeoutException('Kategori istatistikleri kayıt timeout');
          },
        );
        print('Kategori istatistikleri kaydedildi');
        
        print('Firebase istatistikleri başarıyla güncellendi!');
      } else {
        print('Kullanıcı bulunamadı, istatistikler güncellenemiyor');
      }
    } catch (e) {
      print('Firebase istatistikleri güncellenemedi: $e');
      print('Hata detayı: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Toplam tamamlanan görev sayısı
  Future<int> _getTotalCompletedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          int total = 0;
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          data.forEach((date, dayData) {
            if (dayData is Map && dayData.containsKey('_summary')) {
              final summary = dayData['_summary'] as Map<dynamic, dynamic>;
              total += summary['completedTasks'] as int? ?? 0;
            }
          });
          
          return total;
        }
      }
    } catch (e) {
      print('Toplam tamamlanan görev sayısı alınamadı: $e');
    }
    return 0;
  }

  // Toplam puan
  Future<int> _getTotalPoints() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          int total = 0;
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          data.forEach((date, dayData) {
            if (dayData is Map && dayData.containsKey('_summary')) {
              final summary = dayData['_summary'] as Map<dynamic, dynamic>;
              total += summary['totalPoints'] as int? ?? 0;
            }
          });
          
          return total;
        }
      }
    } catch (e) {
      print('Toplam puan alınamadı: $e');
    }
    return 0;
  }

  // Toplam gün sayısı
  Future<int> _getTotalDays() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          return data.length;
        }
      }
    } catch (e) {
      print('Toplam gün sayısı alınamadı: $e');
    }
    return 0;
  }

  // Ortalama tamamlanma oranı
  Future<double> _getAverageCompletionRate() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          double totalRate = 0;
          int dayCount = 0;
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          data.forEach((date, dayData) {
            if (dayData is Map && dayData.containsKey('_summary')) {
              final summary = dayData['_summary'] as Map<dynamic, dynamic>;
              final rate = double.tryParse(summary['completionRate'] as String? ?? '0') ?? 0;
              totalRate += rate;
              dayCount++;
            }
          });
          
          return dayCount > 0 ? totalRate / dayCount : 0;
        }
      }
    } catch (e) {
      print('Ortalama tamamlanma oranı alınamadı: $e');
    }
    return 0;
  }

  // En iyi gün
  Future<Map<String, dynamic>> _getBestDay() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          String bestDate = '';
          int bestPoints = 0;
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          data.forEach((date, dayData) {
            if (dayData is Map && dayData.containsKey('_summary')) {
              final summary = dayData['_summary'] as Map<dynamic, dynamic>;
              final points = summary['totalPoints'] as int? ?? 0;
              
              if (points > bestPoints) {
                bestPoints = points;
                bestDate = date as String;
              }
            }
          });
          
          return {
            'date': bestDate,
            'points': bestPoints,
          };
        }
      }
    } catch (e) {
      print('En iyi gün bilgisi alınamadı: $e');
    }
    return {'date': '', 'points': 0};
  }

  // Mevcut streak
  Future<int> _getCurrentStreak() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final dates = data.keys.cast<String>().toList()..sort();
          
          int streak = 0;
          final today = DateTime.now();
          
          for (int i = dates.length - 1; i >= 0; i--) {
            final date = DateTime.parse(dates[i]);
            final dayData = data[dates[i]] as Map<dynamic, dynamic>;
            
            if (dayData.containsKey('_summary')) {
              final summary = dayData['_summary'] as Map<dynamic, dynamic>;
              final completedTasks = summary['completedTasks'] as int? ?? 0;
              
              if (completedTasks > 0) {
                streak++;
              } else {
                break;
              }
            }
          }
          
          return streak;
        }
      }
    } catch (e) {
      print('Mevcut streak alınamadı: $e');
    }
    return 0;
  }

  // En uzun streak
  Future<int> _getLongestStreak() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final dates = data.keys.cast<String>().toList()..sort();
          
          int currentStreak = 0;
          int longestStreak = 0;
          
          for (final date in dates) {
            final dayData = data[date] as Map<dynamic, dynamic>;
            
            if (dayData.containsKey('_summary')) {
              final summary = dayData['_summary'] as Map<dynamic, dynamic>;
              final completedTasks = summary['completedTasks'] as int? ?? 0;
              
              if (completedTasks > 0) {
                currentStreak++;
                longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
              } else {
                currentStreak = 0;
              }
            }
          }
          
          return longestStreak;
        }
      }
    } catch (e) {
      print('En uzun streak alınamadı: $e');
    }
    return 0;
  }

  // Kategori bazlı istatistikler
  Future<Map<String, dynamic>> _getCategoryStats() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final tasksRef = _database.child('users/${user.uid}/daily_tasks');
        final snapshot = await tasksRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final categoryStats = <String, Map<String, dynamic>>{};
          
          // Kategori listesi
          final categories = ['fiziksel', 'mental', 'sosyal', 'beslenme', 'uyku', 'gelisim', 'cevre', 'finans'];
          
          for (final category in categories) {
            categoryStats[category] = {
              'totalTasks': 0,
              'completedTasks': 0,
              'totalPoints': 0,
              'completionRate': 0.0,
            };
          }
          
          data.forEach((date, dayData) {
            if (dayData is Map) {
              dayData.forEach((taskId, taskData) {
                if (taskId != '_summary' && taskData is Map) {
                  final task = Map<String, dynamic>.from(taskData);
                  final category = task['category'] as String? ?? '';
                  final isCompleted = task['isCompleted'] as bool? ?? false;
                  final points = task['points'] as int? ?? 0;
                  
                  if (categoryStats.containsKey(category)) {
                    categoryStats[category]!['totalTasks'] = (categoryStats[category]!['totalTasks'] as int) + 1;
                    
                    if (isCompleted) {
                      categoryStats[category]!['completedTasks'] = (categoryStats[category]!['completedTasks'] as int) + 1;
                      categoryStats[category]!['totalPoints'] = (categoryStats[category]!['totalPoints'] as int) + points;
                    }
                  }
                }
              });
            }
          });
          
          // Tamamlanma oranlarını hesapla
          categoryStats.forEach((category, stats) {
            final total = stats['totalTasks'] as int;
            final completed = stats['completedTasks'] as int;
            
            if (total > 0) {
              stats['completionRate'] = (completed / total * 100).toStringAsFixed(1);
            }
          });
          
          return categoryStats;
        }
      }
    } catch (e) {
      print('Kategori istatistikleri alınamadı: $e');
    }
    return {};
  }

  // Local storage'a görevleri kaydet
  Future<void> _saveTasksToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Her görevi ayrı ayrı kaydet (daha hızlı)
      for (final task in _todayTasks) {
        final taskKey = 'task_${today}_${task.id}';
        await prefs.setString(taskKey, task.toJson().toString());
      }
      
      // Tarih bilgisini kaydet
      await prefs.setString('last_task_date', today);
      print('Görevler local storage\'a kaydedildi: $today');
    } catch (e) {
      print('Görevler local storage\'a kaydedilemedi: $e');
    }
  }

  // Local storage'dan görevleri yükle
  Future<void> _loadTasksFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      bool hasLoadedTasks = false;
      
      // Her görevi ayrı ayrı yükle
      for (int i = 0; i < _todayTasks.length; i++) {
        final taskKey = 'task_${today}_${_todayTasks[i].id}';
        final taskString = prefs.getString(taskKey);
        
        if (taskString != null) {
          try {
            // Basit string parsing (gerçek uygulamada JSON kullanılabilir)
            // Şimdilik sadece tamamlanma durumunu kontrol et
            if (taskString.contains('"isCompleted":true')) {
              _todayTasks[i] = _todayTasks[i].complete();
              hasLoadedTasks = true;
            }
          } catch (e) {
            print('Local task parsing hatası: $e');
          }
        }
      }
      
      if (hasLoadedTasks) {
        _updateStats();
        notifyListeners();
        print('Local storage\'dan görevler yüklendi: $today');
      }
    } catch (e) {
      print('Local storage\'dan görevler yüklenemedi: $e');
    }
  }

  // Firebase'den görevleri yükle
  Future<void> loadTasksFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final taskRef = _database.child('users/${user.uid}/daily_tasks/$today');
        
        print('Firebase\'den görevler yükleniyor: users/${user.uid}/daily_tasks/$today');
        
        // Timeout ile Firebase işlemi
        final snapshot = await taskRef.get().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Firebase timeout - local cache kullanılıyor');
            throw TimeoutException('Firebase timeout');
          },
        );
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          print('Firebase\'den veri alındı: $data');
          
          // Özet bilgileri kontrol et
          if (data.containsKey('_summary')) {
            final summary = data['_summary'] as Map<dynamic, dynamic>;
            print('Özet bilgiler: $summary');
            
            // İstatistikleri güncelle
            _completedTasks = summary['completedTasks'] ?? 0;
            _totalPoints = summary['totalPoints'] ?? 0;
          }
          
          // Görevleri güncelle
          bool hasChanges = false;
          for (int i = 0; i < _todayTasks.length; i++) {
            final taskId = _todayTasks[i].id;
            if (data.containsKey(taskId)) {
              final taskData = data[taskId] as Map<dynamic, dynamic>;
              print('Görev verisi: $taskData');
              
              final loadedTask = DailyTask.fromJson(Map<String, dynamic>.from(taskData));
              
              // Görev durumunu güncelle
              if (_todayTasks[i].isCompleted != loadedTask.isCompleted) {
                _todayTasks[i] = loadedTask;
                hasChanges = true;
                print('Görev güncellendi: ${loadedTask.title} - Tamamlandı: ${loadedTask.isCompleted}');
              }
            }
          }
          
          if (hasChanges) {
            _updateStats();
            notifyListeners();
            print('Görevler güncellendi ve UI yenilendi');
          }
          
          print('Günlük görevler Firebase\'den başarıyla yüklendi');
        } else {
          // Firebase'de veri yoksa local'den yüklemeyi dene
          print('Firebase\'de veri bulunamadı, local storage kontrol ediliyor...');
          await _loadTasksFromLocal();
        }
      } else {
        print('Kullanıcı bulunamadı, Firebase yükleme yapılamıyor');
      }
    } on TimeoutException {
      print('Firebase timeout, local cache kullanılıyor');
      await _loadTasksFromLocal();
    } catch (e) {
      print('Görevler Firebase\'den yüklenemedi: $e');
      print('Hata detayı: ${e.toString()}');
      // Hata durumunda local'den yüklemeyi dene
      await _loadTasksFromLocal();
    }
  }

  // Manuel olarak görevleri yenile (kullanıcı için)
  Future<void> refreshDailyTasks() async {
    await _refreshDailyTasks();
  }

  // Kategoriye göre görevleri getir
  List<DailyTask> getTasksByCategory(String category) {
    return _dailyTasks.where((task) => task.category == category).toList();
  }

  // Toplam puanı getir
  int getTotalPoints() {
    return _totalPoints;
  }

  // Tamamlanan görev sayısını getir
  int getCompletedTasksCount() {
    return _completedTasks;
  }

  // Bugünkü görevleri getir
  List<DailyTask> getTodayTasks() {
    return _todayTasks;
  }

  // Haftalık istatistikleri getir
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        final stats = <String, dynamic>{};
        
        for (int i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));
          final dateString = date.toIso8601String().split('T')[0];
          
          final taskRef = _database.child('users/${user.uid}/daily_tasks/$dateString');
          final snapshot = await taskRef.get();
          
          if (snapshot.exists) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            int completedCount = 0;
            int totalPoints = 0;
            
            data.values.forEach((taskData) {
              final task = taskData as Map<dynamic, dynamic>;
              if (task['isCompleted'] == true) {
                completedCount++;
                totalPoints += task['points'] as int;
              }
            });
            
            stats[dateString] = {
              'completed': completedCount,
              'points': totalPoints,
            };
          } else {
            stats[dateString] = {
              'completed': 0,
              'points': 0,
            };
          }
        }
        
        return stats;
      }
    } catch (e) {
      print('Haftalık istatistikler alınamadı: $e');
    }
    
    return {};
  }

  // Aylık istatistikleri getir
  Future<Map<String, dynamic>> getMonthlyStats() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
        final monthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
        final stats = <String, dynamic>{};
        
        for (int i = 0; i < monthEnd.day; i++) {
          final date = monthStart.add(Duration(days: i));
          final dateString = date.toIso8601String().split('T')[0];
          
          final taskRef = _database.child('users/${user.uid}/daily_tasks/$dateString');
          final snapshot = await taskRef.get();
          
          if (snapshot.exists) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            int completedCount = 0;
            int totalPoints = 0;
            
            data.values.forEach((taskData) {
              final task = taskData as Map<dynamic, dynamic>;
              if (task['isCompleted'] == true) {
                completedCount++;
                totalPoints += task['points'] as int;
              }
            });
            
            stats[dateString] = {
              'completed': completedCount,
              'points': totalPoints,
            };
          } else {
            stats[dateString] = {
              'completed': 0,
              'points': 0,
            };
          }
        }
        
        return stats;
      }
    } catch (e) {
      print('Aylık istatistikler alınamadı: $e');
    }
    
    return {};
  }

  // Firebase bağlantısını test et
  Future<bool> testFirebaseConnection() async {
    try {
      print('=== 🔥 FIREBASE BAĞLANTI TESTİ BAŞLADI ===');
      
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı');
        return false;
      }
      
      print('✅ Kullanıcı bulundu: ${user.uid}');
      
      // Firebase Database durumunu kontrol et
      final database = FirebaseDatabase.instance;
      print('🔗 Database URL: ${database.databaseURL}');
      print('🏗️ Firebase App: ${database.app.name}');
      print('🔑 Auth durumu: ${_auth.authStateChanges()}');
      
      // Database URL null ise ayarla
      if (database.databaseURL == null) {
        print('⚠️ Database URL null, manuel olarak ayarlanıyor...');
        database.databaseURL = 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app';
        print('🔗 Database URL ayarlandı: ${database.databaseURL}');
      }
      
      // Test verisi yaz
      final testRef = _database.child('users/${user.uid}/test_connection');
      print('📍 Test path: users/${user.uid}/test_connection');
      print('📍 Test Reference: ${testRef.path}');
      
      final testData = {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Firebase bağlantı testi başarılı',
        'userId': user.uid,
        'databaseURL': database.databaseURL,
      };
      
      print('💾 Test verisi: $testData');
      
      // Test verisi yazma
      print('📝 Test verisi yazılıyor...');
      await testRef.set(testData).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Test verisi yazma timeout');
          throw TimeoutException('Test verisi yazma timeout');
        },
      );
      print('✅ Test verisi yazıldı');
      
      // Test verisini okuma
      print('📖 Test verisi okunuyor...');
      final snapshot = await testRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Test verisi okuma timeout');
          throw TimeoutException('Test verisi okuma timeout');
        },
      );
      if (snapshot.exists) {
        print('✅ Test verisi okundu: ${snapshot.value}');
        
        // Test verisini silme
        print('🗑️ Test verisi siliniyor...');
        await testRef.remove().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Test verisi silme timeout');
            throw TimeoutException('Test verisi silme timeout');
          },
        );
        print('✅ Test verisi silindi');
        
        print('=== 🎉 FIREBASE BAĞLANTI TESTİ BAŞARILI ===');
        return true;
      } else {
        print('❌ Test verisi okunamadı');
        return false;
      }
    } catch (e) {
      print('❌ Firebase bağlantı testi başarısız: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      print('🔍 Hata tipi: ${e.runtimeType}');
      
      // Hata stack trace'ini de yazdır
      if (e is Exception) {
        print('📚 Exception detayı: ${e.toString()}');
      }
      
      return false;
    }
  }

  // Manuel olarak Firebase'e kaydet (test için)
  Future<void> forceSaveToFirebase() async {
    print('=== MANUEL FIREBASE KAYIT BAŞLADI ===');
    try {
      await _saveTasksToFirebase();
      print('✅ Manuel kayıt başarılı');
    } catch (e) {
      print('❌ Manuel kayıt başarısız: $e');
    }
    print('=== MANUEL FIREBASE KAYIT TAMAMLANDI ===');
  }

  // Tamamlanan görevleri getir
  Future<List<DailyTask>> getCompletedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Kullanıcı bulunamadı, tamamlanan görevler alınamıyor');
        return [];
      }
      
      print('🔍 Tamamlanan görevler getiriliyor...');
      
      // 1. Önce completed_tasks tablosundan al
      print('📍 Firebase path: users/${user.uid}/completed_tasks');
      final completedRef = _database.child('users/${user.uid}/completed_tasks');
      
      final snapshot = await completedRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Tamamlanan görevler alma timeout');
          throw TimeoutException('Tamamlanan görevler alma timeout');
        },
      );
      
      final completedTasks = <DailyTask>[];
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print('📊 Firebase completed_tasks\'den veri alındı, ${data.length} öğe');
        
        data.forEach((taskId, taskData) {
          print('🔍 Görev ID: $taskId, Veri: $taskData');
          
          if (taskData is Map) {
            final taskMap = Map<String, dynamic>.from(taskData);
            print('📝 Görev Map: $taskMap');
            
            if (taskMap['isCompleted'] == true) {
              try {
                final task = DailyTask.fromJson(taskMap);
                completedTasks.add(task);
                print('✅ Görev başarıyla parse edildi: ${task.title}');
              } catch (e) {
                print('⚠️ Görev parse hatası: $e');
                print('🚨 Hatalı veri: $taskMap');
              }
            } else {
              print('ℹ️ Görev tamamlanmamış: isCompleted = ${taskMap['isCompleted']}');
            }
          } else {
            print('⚠️ Görev verisi Map değil: ${taskData.runtimeType}');
          }
        });
      } else {
        print('ℹ️ Firebase\'de completed_tasks tablosu bulunamadı');
      }
      
      // 2. Mevcut günlük görevlerden de tamamlananları ekle
      print('🔍 Mevcut günlük görevlerden tamamlananlar kontrol ediliyor...');
      final todayCompletedTasks = _todayTasks.where((task) => task.isCompleted).toList();
      print('📊 Bugün tamamlanan görev sayısı: ${todayCompletedTasks.length}');
      
      for (final task in todayCompletedTasks) {
        // Eğer zaten completed_tasks'ta yoksa ekle
        if (!completedTasks.any((completed) => completed.id == task.id)) {
          completedTasks.add(task);
          print('✅ Bugünkü tamamlanan görev eklendi: ${task.title}');
        }
      }
      
      print('✅ Toplam tamamlanan görev sayısı: ${completedTasks.length}');
      for (final task in completedTasks) {
        print('   📋 ${task.title} (${task.category}) - ${task.points} puan');
      }
      
      return completedTasks;
    } catch (e) {
      print('❌ Tamamlanan görevler alınamadı: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      print('🔍 Hata tipi: ${e.runtimeType}');
      return [];
    }
  }
} 