import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/ad_service.dart';
import '../core/mood_service.dart';
import '../core/models/mood_entry.dart';

class AIService extends ChangeNotifier {
  final AdService _adService;
  final MoodService _moodService;
  late final GenerativeModel _model;
  
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _error;

  AIService(this._adService, this._moodService) {
    // Gemini AI modelini başlat
    const apiKey = 'AIzaSyD_YcYxmdtkU0eQ5KvWzTi5MOa5xnl0i04';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  bool get isAnalyzing => _isAnalyzing;
  String? get analysisResult => _analysisResult;
  String? get error => _error;
  
  // Firebase referansları
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Kaydedilen analizler
  List<Map<String, dynamic>> _savedAnalyses = [];
  List<Map<String, dynamic>> get savedAnalyses => _savedAnalyses;
  
  // AI analizi sayısı (her 5 mood'da bir)
  int _analysisCount = 0;
  int get analysisCount => _analysisCount;
  
  // Kullanıcı ID'sini al
  String? get _userId => _auth.currentUser?.uid;

  // AI analizi başlat (ödüllü reklam ile)
  Future<void> startAIAnalysis() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
        _analysisResult = null;
      });

      // Ödüllü reklam göster
      await _adService.showRewardedAd(
        onRewarded: () {
          // Reklam izlendi, AI analizi yap
          _performAIAnalysis();
        },
        onFailed: () {
          // Reklam izlenemedi
          setState(() {
            _isAnalyzing = false;
            _error = 'Reklam izlenemedi. Lütfen tekrar deneyin.';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = 'AI analizi başlatılamadı: $e';
      });
    }
  }

  // AI analizi yap
  Future<void> _performAIAnalysis() async {
    try {
      final moodEntries = _moodService.moodEntries;
      
      if (moodEntries.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _error = 'Analiz için yeterli mood verisi yok. En az 5 mood girişi yapın.';
        });
        return;
      }

      // AI analizi simülasyonu (gerçek AI entegrasyonu için OpenAI/Claude API kullanılabilir)
      final analysis = await _generateAIAnalysis(moodEntries);
      
      // Analizi kaydet
      _saveAnalysis(analysis, moodEntries.length);
      
      setState(() {
        _isAnalyzing = false;
        _analysisResult = analysis;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = 'AI analizi sırasında hata: $e';
      });
    }
  }

  // Gerçek AI analizi üret (Gemini AI)
  Future<String> _generateAIAnalysis(List<MoodEntry> entries) async {
    try {
      if (entries.length < 3) {
        return 'Daha detaylı analiz için en az 3 mood girişi yapmanız gerekiyor.';
      }

      // Mood verilerini prompt için hazırla
      final moodData = _prepareMoodDataForAI(entries);
      
                     // Gemini AI prompt
               final prompt = '''
               Sen bir uzman psikolog ve mood analiz uzmanısın. Aşağıdaki mood verilerini analiz et ve kişiselleştirilmiş bir rapor hazırla.

               Mood Verileri:
               $moodData

               Lütfen şu formatta bir analiz raporu hazırla:

               Dikkat Çeken Noktalar:
               • [Önemli gözlem 1]
               • [Önemli gözlem 2]
               • [Önemli gözlem 3]

               Kişiselleştirilmiş Öneriler:
               • [Öneri 1]
               • [Öneri 2]
               • [Öneri 3]

               Genel İstatistikler:
               • [Mood dağılımı, yüzdeler, toplam giriş sayısı]

               Trend Analizi:
               • [Son günlerdeki trend, iyileşme/kötüleşme durumu]

               Gelecek için Öneriler:
               • [Mood durumunu iyileştirmek için somut adım 1]
               • [Mood durumunu iyileştirmek için somut adım 2]

               Uyarı: Eğer ciddi depresyon belirtileri görürsen, profesyonel yardım alınmasını öner.

               Raporu Türkçe, empatik, pozitif ama gerçekçi bir dille yaz. Her madde yeni satırda olsun ve • ile başlasın.
               ''';

      // Gemini AI'dan yanıt al
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'AI analizi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      
    } catch (e) {
      print('Gemini AI Error: $e');
      // Hata durumunda basit analiz döndür
      return _generateSimpleAnalysis(entries);
    }
  }

  // Mood verilerini AI için hazırla
  String _prepareMoodDataForAI(List<MoodEntry> entries) {
    final buffer = StringBuffer();
    
    // Son 30 günlük veriyi al (çok fazla veri olmasın)
    final now = DateTime.now();
    final recentEntries = entries.where((e) => 
      now.difference(e.timestamp).inDays <= 30
    ).toList();
    
    // Tarih sırasına göre sırala
    recentEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    buffer.writeln('Toplam mood girişi: ${entries.length}');
    buffer.writeln('Son 30 günlük veriler:');
    buffer.writeln('');
    
    for (final entry in recentEntries.take(20)) { // Maksimum 20 giriş
      final date = '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}';
      buffer.writeln('$date: ${entry.mood} ${entry.note?.isNotEmpty == true ? '- "${entry.note}"' : ''}');
    }
    
    return buffer.toString();
  }

  // Basit analiz (fallback)
  String _generateSimpleAnalysis(List<MoodEntry> entries) {
    final totalEntries = entries.length;
    final happyCount = entries.where((e) => e.mood.contains('😊') || e.mood.contains('🤩')).length;
    final sadCount = entries.where((e) => e.mood.contains('😢') || e.mood.contains('😔')).length;
    
    final analysis = StringBuffer();
    analysis.writeln('🧠 **Basit Mood Analizi**');
    analysis.writeln('');
    analysis.writeln('📊 **İstatistikler:**');
    analysis.writeln('• Toplam giriş: $totalEntries');
    analysis.writeln('• Mutlu günler: $happyCount (${((happyCount / totalEntries) * 100).toStringAsFixed(1)}%)');
    analysis.writeln('• Üzgün günler: $sadCount (${((sadCount / totalEntries) * 100).toStringAsFixed(1)}%)');
    analysis.writeln('');
    
    if (happyCount > sadCount) {
      analysis.writeln('💡 **Genel olarak pozitif bir dönemdesiniz! 🌟**');
    } else if (sadCount > happyCount) {
      analysis.writeln('💡 **Zor bir dönemden geçiyor olabilirsiniz. Kendinize iyi bakın. 🫂**');
    } else {
      analysis.writeln('💡 **Dengeli bir ruh halindesiniz. ⚖️**');
    }
    
    return analysis.toString();
  }

  // State güncelle
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Analiz sonucunu temizle
  void clearAnalysis() {
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }

  // Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Analizi Firebase'e kaydet
  Future<void> _saveAnalysis(String analysis, int moodCount) async {
    try {
      final userId = _userId;
      if (userId == null) return;
      
      final analysisData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'date': DateTime.now().toIso8601String(),
        'analysis': analysis,
        'moodCount': moodCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Firebase'e kaydet
      await _database.child('users/$userId/ai_analyses').push().set(analysisData);
      
      // Local listeye ekle
      _savedAnalyses.insert(0, analysisData);
      _analysisCount++;
      
      // En fazla 10 analiz sakla
      if (_savedAnalyses.length > 10) {
        _savedAnalyses.removeLast();
      }
      
      notifyListeners();
    } catch (e) {
      print('AI analizi Firebase\'e kaydedilemedi: $e');
    }
  }
  
  // Analizi sil
  void deleteAnalysis(String id) {
    _savedAnalyses.removeWhere((analysis) => analysis['id'] == id);
    notifyListeners();
  }
  
  // AI analizlerini Firebase'den yükle
  Future<void> loadAnalysesFromFirebase() async {
    try {
      final userId = _userId;
      if (userId == null) return;
      
      final snapshot = await _database.child('users/$userId/ai_analyses').get();
      if (!snapshot.exists) return;
      
      final List<Map<String, dynamic>> analyses = [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      data.forEach((key, value) {
        if (value is Map) {
          analyses.add({
            'id': key,
            'date': value['date'] ?? '',
            'analysis': value['analysis'] ?? '',
            'moodCount': value['moodCount'] ?? 0,
            'timestamp': value['timestamp'] ?? 0,
          });
        }
      });
      
      // Tarihe göre sırala (en yeni önce)
      analyses.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      _savedAnalyses = analyses;
      _analysisCount = analyses.length;
      notifyListeners();
    } catch (e) {
      print('AI analizleri Firebase\'den yüklenemedi: $e');
    }
  }
  
  // Tüm analizleri temizle
  Future<void> clearAllAnalyses() async {
    try {
      final userId = _userId;
      if (userId == null) return;
      
      // Firebase'den sil
      await _database.child('users/$userId/ai_analyses').remove();
      
      // Local listeyi temizle
      _savedAnalyses.clear();
      _analysisCount = 0;
      notifyListeners();
    } catch (e) {
      print('AI analizleri temizlenemedi: $e');
    }
  }
} 