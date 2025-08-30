import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/mood_service.dart';
import '../../core/models/mood_entry.dart';
import '../../core/daily_task_service.dart';
import '../../core/breathing_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında mood verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodService = context.read<MoodService>();
      moodService.loadMoodEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final moodService = context.read<MoodService>();
              moodService.loadMoodEntries();
            },
          ),
        ],
      ),
      body: Consumer<MoodService>(
        builder: (context, moodService, child) {
          if (moodService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (moodService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${moodService.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => moodService.loadMoodEntries(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (moodService.moodEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz mood kaydedilmemiş',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İstatistikleri görmek için mood eklemeye başla',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genel istatistikler
                _buildGeneralStats(moodService),
                
                const SizedBox(height: 24),
                
                // Nefes egzersizi istatistikleri
                _buildBreathingStats(),
                
                const SizedBox(height: 24),
                
                // Günlük görev istatistikleri
                _buildDailyTaskStats(),
                
                const SizedBox(height: 24),
                
                // Haftalık mood grafiği
                _buildWeeklyChart(moodService),
                
                const SizedBox(height: 24),
                
                // En popüler mood'lar
                _buildPopularMoods(moodService),
                
                const SizedBox(height: 24),
                
                // Aylık trend
                _buildMonthlyTrend(moodService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneralStats(MoodService moodService) {
    final totalMoods = moodService.moodEntries.length;
    final thisWeekMoods = moodService.getWeeklyMoodEntries().length;
    final thisMonthMoods = moodService.getMonthlyMoodEntries().length;
    final todayMoods = moodService.getTodayMoodEntries().length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel İstatistikler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam',
                    totalMoods.toString(),
                    Icons.emoji_emotions,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Bu Hafta',
                    thisWeekMoods.toString(),
                    Icons.view_week,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay',
                    thisMonthMoods.toString(),
                    Icons.calendar_month,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Bugün',
                    todayMoods.toString(),
                    Icons.today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Nefes egzersizi istatistikleri
  Widget _buildBreathingStats() {
    return Consumer<BreathingService>(
      builder: (context, breathingService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.air, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Nefes Egzersizi İstatistikleri',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Toplam nefes egzersizi
                _buildStatRow('Toplam Nefes Egzersizi', '${breathingService.totalSessions}', Icons.fitness_center),
                
                // Toplam nefes süresi
                _buildStatRow('Toplam Nefes Süresi', '${breathingService.totalTimeMinutes.toStringAsFixed(1)} dakika', Icons.timer),
                
                // Ortalama nefes süresi
                _buildStatRow('Ortalama Nefes Süresi', '${breathingService.averageTimeMinutes.toStringAsFixed(1)} dakika', Icons.av_timer),
                
                // Son nefes egzersizi
                _buildStatRow('Son Nefes Egzersizi', breathingService.lastSessionText, Icons.schedule),
              ],
            ),
          ),
        );
      },
    );
  }

  // Günlük görev istatistikleri
  Widget _buildDailyTaskStats() {
    return Consumer<DailyTaskService>(
      builder: (context, taskService, child) {
        final totalTasks = taskService.todayTasks.length;
        final completedTasks = taskService.completedTasks;
        final totalPoints = taskService.totalPoints;
        final maxPoints = taskService.todayTasks.fold(0, (sum, task) => sum + task.points);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.task_alt, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Günlük Görev İstatistikleri',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Tamamlanan görevler
                _buildStatRow('Tamamlanan Görevler', '$completedTasks / $totalTasks', Icons.check_circle),
                
                // Toplam puan
                _buildStatRow('Toplam Puan', '$totalPoints / $maxPoints', Icons.stars),
                
                // Tamamlanma oranı
                _buildStatRow('Tamamlanma Oranı', '%${totalTasks > 0 ? (completedTasks / totalTasks * 100).toStringAsFixed(1) : '0'}', Icons.pie_chart),
                
                // Kategori dağılımı
                _buildStatRow('Kategori Dağılımı', '${taskService.todayTasks.map((t) => t.category).toSet().length} kategori', Icons.category),
                
                const SizedBox(height: 16),
                
                // Kategori bazlı detaylar
                if (taskService.todayTasks.isNotEmpty) ...[
                  Text(
                    'Kategori Detayları:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...taskService.todayTasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(task.categoryColor, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.categoryName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.isCompleted ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.isCompleted ? '${task.points} puan' : '0 puan',
                            style: TextStyle(
                              color: task.isCompleted ? Colors.green[700] : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
                
                const SizedBox(height: 20),
                
                // Firebase'den gelen genel istatistikler
                _buildFirebaseTaskStats(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Firebase'den gelen görev istatistikleri
  Widget _buildFirebaseTaskStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getFirebaseTaskStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final stats = snapshot.data!;
        final general = stats['general'] as Map<String, dynamic>?;
        final categories = stats['categories'] as Map<String, dynamic>?;
        
        if (general == null) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Görev İstatistikleri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            
            // Genel istatistikler
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Görev',
                    '${general['totalCompletedTasks'] ?? 0}',
                    Icons.task_alt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Toplam Puan',
                    '${general['totalPoints'] ?? 0}',
                    Icons.stars,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Gün',
                    '${general['totalDays'] ?? 0}',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Ortalama Oran',
                    '%${general['averageCompletionRate']?.toStringAsFixed(1) ?? '0'}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Streak bilgileri
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Mevcut Streak',
                    '${general['currentStreak'] ?? 0} gün',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'En Uzun Streak',
                    '${general['longestStreak'] ?? 0} gün',
                    Icons.emoji_events,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            if (categories != null) ...[
              const SizedBox(height: 20),
              
              Text(
                'Kategori Performansı',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 12),
              
              ...categories.entries.map((entry) {
                final category = entry.key;
                final categoryStats = entry.value as Map<String, dynamic>;
                final completionRate = categoryStats['completionRate'] as double? ?? 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getCategoryEmoji(category),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getCategoryName(category),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '%${completionRate.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: completionRate > 70 ? Colors.green : 
                                    completionRate > 40 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionRate > 70 ? Colors.green : 
                          completionRate > 40 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        );
      },
    );
  }

  // Firebase'den görev istatistiklerini al
  Future<Map<String, dynamic>> _getFirebaseTaskStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final statsRef = FirebaseDatabase.instance.ref().child('users/${user.uid}/task_stats');
        final snapshot = await statsRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      print('Firebase görev istatistikleri alınamadı: $e');
    }
    return {};
  }

  // Kategori emoji'sini getir
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'fiziksel': return '🟢';
      case 'mental': return '🔵';
      case 'sosyal': return '🟡';
      case 'beslenme': return '🟠';
      case 'uyku': return '🟣';
      case 'gelisim': return '🔴';
      case 'cevre': return '🟤';
      case 'finans': return '⚫';
      default: return '⚪';
    }
  }

  // Kategori adını getir
  String _getCategoryName(String category) {
    switch (category) {
      case 'fiziksel': return 'Fiziksel Sağlık';
      case 'mental': return 'Mental Sağlık';
      case 'sosyal': return 'Sosyal Sağlık';
      case 'beslenme': return 'Beslenme';
      case 'uyku': return 'Uyku & Dinlenme';
      case 'gelisim': return 'Kişisel Gelişim';
      case 'cevre': return 'Çevre & Sürdürülebilirlik';
      case 'finans': return 'Finansal Sağlık';
      default: return 'Diğer';
    }
  }

  Widget _buildWeeklyChart(MoodService moodService) {
    final weeklyMoods = moodService.getWeeklyMoodEntries();
    final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    // Haftalık mood sayılarını hesapla
    final weekData = List.generate(7, (index) {
      final dayStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + index));
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      return weeklyMoods.where((mood) {
        return mood.timestamp.isAfter(dayStart) && mood.timestamp.isBefore(dayEnd);
      }).length;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu Hafta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weekData.isEmpty ? 10 : (weekData.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < weekDays.length) {
                            return Text(weekDays[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weekData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: entry.value > 0 ? Colors.blue : Colors.grey.withOpacity(0.3),
                      )],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularMoods(MoodService moodService) {
    // Mood frekanslarını hesapla
    final moodCounts = <String, int>{};
    for (final mood in moodService.moodEntries) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
    }
    
    // En popüler mood'ları sırala
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Popüler Mood\'lar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            ...sortedMoods.take(5).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.value / moodService.moodEntries.length,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Stat row widget'ı
  Widget _buildStatRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend(MoodService moodService) {
    final monthlyMoods = moodService.getMonthlyMoodEntries();
    final monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    
    // Son 6 ayın verilerini al
    final last6Months = List.generate(6, (index) {
      final month = DateTime.now().month - 5 + index;
      final year = DateTime.now().year;
      if (month <= 0) {
        return DateTime(year - 1, month + 12);
      }
      return DateTime(year, month);
    });

    final monthData = last6Months.map((date) {
      return monthlyMoods.where((mood) {
        return mood.timestamp.year == date.year && mood.timestamp.month == date.month;
      }).length;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aylık Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < monthNames.length) {
                            return Text(monthNames[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 