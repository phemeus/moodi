class MoodEntry {
  final String id;
  final String mood; // emoji string
  final String? note;
  final DateTime timestamp;
  final String? location;

  const MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    required this.timestamp,
    this.location,
  });

  // JSON'dan MoodEntry oluştur
  factory MoodEntry.fromJson(String id, Map<String, dynamic> json) {
    return MoodEntry(
      id: id,
      mood: json['mood'] as String? ?? '',
      note: json['note'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? 0),
      location: json['location'] as String?,
    );
  }

  // MoodEntry'den JSON oluştur
  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'note': note,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': location,
    };
  }

  // Yeni değerler ile güncelle
  MoodEntry copyWith({
    String? mood,
    String? note,
    DateTime? timestamp,
    String? location,
  }) {
    return MoodEntry(
      id: id,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }

  // Tarih anahtarı (YYYY-MM-DD formatında)
  String get dateKey {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  // Bugün mü kontrol et
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }

  // Bu hafta mı kontrol et
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return timestamp.isAfter(startOfWeek) && timestamp.isBefore(endOfWeek);
  }

  // Bu ay mı kontrol et
  bool get isThisMonth {
    final now = DateTime.now();
    return timestamp.year == now.year && timestamp.month == now.month;
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, mood: $mood, note: $note, timestamp: $timestamp)';
  }
} 