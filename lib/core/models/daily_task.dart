class DailyTask {
  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryName;
  final String categoryColor;
  final int points;
  final bool isCompleted;
  final DateTime date;
  final DateTime? completedAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryName,
    required this.categoryColor,
    required this.points,
    this.isCompleted = false,
    required this.date,
    this.completedAt,
  });

  // JSON'dan DailyTask oluştur
  factory DailyTask.fromJson(Map<String, dynamic> json) {
    // completedDate alanı varsa onu kullan, yoksa date alanını kullan
    DateTime taskDate;
    if (json.containsKey('completedDate')) {
      try {
        taskDate = DateTime.parse(json['completedDate'] as String);
      } catch (e) {
        taskDate = DateTime.parse(json['date'] as String);
      }
    } else {
      taskDate = DateTime.parse(json['date'] as String);
    }
    
    return DailyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      categoryName: json['categoryName'] as String? ?? json['category'] as String,
      categoryColor: json['categoryColor'] as String? ?? '#2196F3',
      points: json['points'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      date: taskDate,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }

  // DailyTask'ı JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'categoryName': categoryName,
      'categoryColor': categoryColor,
      'points': points,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Görevi tamamla
  DailyTask complete() {
    return DailyTask(
      id: id,
      title: title,
      description: description,
      category: category,
      categoryName: categoryName,
      categoryColor: categoryColor,
      points: points,
      isCompleted: true,
      date: date,
      completedAt: DateTime.now(),
    );
  }

  // Görevi sıfırla
  DailyTask reset() {
    return DailyTask(
      id: id,
      title: title,
      description: description,
      category: category,
      categoryName: categoryName,
      categoryColor: categoryColor,
      points: points,
      isCompleted: false,
      date: date,
      completedAt: null,
    );
  }
} 