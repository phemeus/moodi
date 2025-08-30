import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/mood_entry.dart';

class MoodService extends ChangeNotifier {
  late final FirebaseDatabase _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = false;
  String? _error;

  MoodService() {
    // Doğru database URL'ini manuel olarak ayarla
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://moodi-35089-default-rtdb.europe-west1.firebasedatabase.app',
    );
  }

  List<MoodEntry> get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mood entry ekle
  Future<void> addMoodEntry(MoodEntry entry) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Production güvenlik kontrolleri
      if (entry.mood.isEmpty) throw Exception('Mood seçilmedi');
      // Tarih kontrolünü basitleştir
      final now = DateTime.now();
      if (entry.timestamp.isAfter(now)) {
        throw Exception('Geçersiz tarih');
      }

      final ref = _database.ref('users/${user.uid}/moods');
      final newRef = ref.push();
      
      await newRef.set({
        'mood': entry.mood,
        'note': entry.note,
        'timestamp': ServerValue.timestamp,
        'location': entry.location,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Local listeyi güncelle
      _moodEntries.add(entry);
      _moodEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mood entry'leri yükle
  Future<void> loadMoodEntries() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final ref = _database.ref('users/${user.uid}/moods');
      // Index olmadan tüm mood'ları al ve client-side sırala
      final snapshot = await ref.get();

      if (snapshot.exists) {
        _moodEntries = [];
        for (final child in snapshot.children) {
          final data = child.value as Map<dynamic, dynamic>;
          _moodEntries.add(MoodEntry(
            id: child.key!,
            mood: data['mood'] ?? '',
            note: data['note'] ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
            location: data['location'] ?? '',
          ));
        }
        // Client-side sıralama
        _moodEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mood entry sil
  Future<void> deleteMoodEntry(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final ref = _database.ref('users/${user.uid}/moods/$id');
      await ref.remove();

      // Local listeyi güncelle
      _moodEntries.removeWhere((entry) => entry.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Tüm verileri temizle
  Future<void> clearAllData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final ref = _database.ref('users/${user.uid}/moods');
      await ref.remove();

      // Local listeyi temizle
      _moodEntries.clear();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Belirli tarih aralığındaki mood'ları getir
  List<MoodEntry> getMoodEntriesByDateRange(DateTime start, DateTime end) {
    return _moodEntries.where((entry) {
      return entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end);
    }).toList();
  }

  // Bugünkü mood'ları getir
  List<MoodEntry> getTodayMoodEntries() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getMoodEntriesByDateRange(startOfDay, endOfDay);
  }

  // Haftalık mood'ları getir
  List<MoodEntry> getWeeklyMoodEntries() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getMoodEntriesByDateRange(startOfWeek, endOfWeek);
  }

  // Aylık mood'ları getir
  List<MoodEntry> getMonthlyMoodEntries() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return getMoodEntriesByDateRange(startOfMonth, endOfMonth);
  }
} 