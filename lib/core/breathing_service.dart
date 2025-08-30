import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BreathingService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _totalSessions = 0;
  int _totalTime = 0; // saniye cinsinden
  DateTime? _lastSession;
  
  int get totalSessions => _totalSessions;
  int get totalTime => _totalTime;
  DateTime? get lastSession => _lastSession;
  
  // Ortalama süre (dakika cinsinden)
  double get averageTimeMinutes {
    if (_totalSessions == 0) return 0;
    return (_totalTime / 60) / _totalSessions;
  }
  
  // Toplam süre (dakika cinsinden)
  double get totalTimeMinutes => _totalTime / 60;
  
  BreathingService() {
    _loadData();
  }
  
  // Kullanıcı ID'sini al
  String? get _userId => _auth.currentUser?.uid;
  
  // Verileri Firebase'den yükle
  Future<void> _loadData() async {
    try {
      final userId = _userId;
      if (userId == null) {
        print('Kullanıcı ID bulunamadı, nefes egzersizi verileri yüklenemiyor');
        return;
      }
      
      print('Nefes egzersizi verileri Firebase\'den yükleniyor: users/$userId/breathing');
      
      final snapshot = await _database.child('users/$userId/breathing').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print('Firebase\'den nefes egzersizi verisi alındı: $data');
        
        _totalSessions = data['totalSessions'] ?? 0;
        _totalTime = data['totalTime'] ?? 0;
        
        final lastSessionString = data['lastSession'];
        if (lastSessionString != null) {
          _lastSession = DateTime.parse(lastSessionString.toString());
        }
        
        print('Nefes egzersizi verileri yüklendi: $_totalSessions oturum, $_totalTime saniye');
      } else {
        print('Firebase\'de nefes egzersizi verisi bulunamadı, varsayılan değerler kullanılıyor');
      }
      
      notifyListeners();
    } catch (e) {
      print('Nefes egzersizi verileri Firebase\'den yüklenemedi: $e');
      print('Hata detayı: ${e.toString()}');
    }
  }
  
  // Verileri Firebase'e kaydet
  Future<void> _saveData() async {
    try {
      final userId = _userId;
      if (userId == null) {
        print('❌ Kullanıcı ID bulunamadı, nefes egzersizi verileri kaydedilemiyor');
        return;
      }
      
      print('🚀 Nefes egzersizi verileri Firebase\'e kaydediliyor: users/$userId/breathing');
      print('🔗 Database URL: ${FirebaseDatabase.instance.databaseURL}');
      
      final data = {
        'totalSessions': _totalSessions,
        'totalTime': _totalTime,
        'lastSession': _lastSession?.toIso8601String(),
        'lastUpdated': ServerValue.timestamp,
      };
      
      print('💾 Kaydedilecek veri: $data');
      
      await _database.child('users/$userId/breathing').set(data);
      
      print('✅ Nefes egzersizi verileri Firebase\'e başarıyla kaydedildi');
    } catch (e) {
      print('❌ Nefes egzersizi verileri Firebase\'e kaydedilemedi: $e');
      print('🚨 Hata detayı: ${e.toString()}');
      print('🔍 Hata tipi: ${e.runtimeType}');
      
      // Hata stack trace'ini de yazdır
      if (e is Exception) {
        print('📚 Exception detayı: ${e.toString()}');
      }
    }
  }
  
  // Nefes egzersizi tamamlandı
  Future<void> completeSession(int durationSeconds) async {
    _totalSessions++;
    _totalTime += durationSeconds;
    _lastSession = DateTime.now();
    
    // Firebase'e kaydet
    await _saveData();
    
    // Geçmiş kaydı ekle
    await _addSessionHistory(durationSeconds);
    
    notifyListeners();
  }
  
  // Nefes egzersizi geçmişini Firebase'e ekle
  Future<void> _addSessionHistory(int durationSeconds) async {
    try {
      final userId = _userId;
      if (userId == null) return;
      
      final sessionData = {
        'duration': durationSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'date': DateTime.now().toIso8601String(),
      };
      
      await _database.child('users/$userId/breathing/history').push().set(sessionData);
    } catch (e) {
      print('Nefes egzersizi geçmişi kaydedilemedi: $e');
    }
  }
  
  // Nefes egzersizi geçmişini getir
  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      
      final snapshot = await _database.child('users/$userId/breathing/history').get();
      if (!snapshot.exists) return [];
      
      final List<Map<String, dynamic>> history = [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      data.forEach((key, value) {
        if (value is Map) {
          history.add({
            'id': key,
            'duration': value['duration'] ?? 0,
            'timestamp': value['timestamp'] ?? 0,
            'date': value['date'] ?? '',
          });
        }
      });
      
      // Tarihe göre sırala (en yeni önce)
      history.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return history;
    } catch (e) {
      print('Nefes egzersizi geçmişi getirilemedi: $e');
      return [];
    }
  }
  
  // İstatistikleri sıfırla
  Future<void> resetStats() async {
    _totalSessions = 0;
    _totalTime = 0;
    _lastSession = null;
    
    await _saveData();
    notifyListeners();
  }
  
  // Son nefes egzersizi metni
  String get lastSessionText {
    if (_lastSession == null) return 'Hiç yapılmamış';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSession!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
} 