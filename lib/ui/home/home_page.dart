import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/auth_service.dart';
import '../../core/mood_service.dart';
import '../../core/ad_service.dart';
import '../../core/daily_task_service.dart';
import '../../core/models/daily_task.dart';
import '../../core/models/mood_entry.dart';
import 'mood_picker.dart';
import '../stats/stats_page.dart';
import '../settings/settings_page.dart';
import '../breathing/breathing_page.dart';
import '../ai/ai_analysis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const BreathingPage(),
    const StatsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Provider'dan service'leri al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodService = context.read<MoodService>();
      final adService = context.read<AdService>();
      
      // Mood entry'leri yükle
      moodService.loadMoodEntries();
      
      // Reklamları yükle
      adService.loadBannerAd();
      adService.loadInterstitialAd();
      adService.loadRewardedAd(); // AI analizi için gerekli
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı bulunamadı')),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.air_outlined),
            activeIcon: Icon(Icons.air),
            label: 'Nefes',
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'İstatistikler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moodi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/signin');
              }
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

          final todayMood = moodService.getTodayMoodEntries().isNotEmpty
              ? moodService.getTodayMoodEntries().first
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bugünkü mood
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugün nasılsın?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (todayMood != null) ...[
                          Row(
                            children: [
                              Text(
                                todayMood.mood,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (todayMood.note != null)
                                      Text(
                                        todayMood.note!,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    Text(
                                      'Kaydedildi: ${_formatTime(todayMood.timestamp)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Mood'a uygun otomatik söz
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bugün için sözün:',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getQuoteForMood(todayMood.mood),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Text('Henüz bugün için mood kaydedilmemiş.'),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showMoodPicker(context),
                            child: Text(todayMood != null ? 'Mood\'u Güncelle' : 'Mood Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Günlük Görevler
                Text(
                  'Günlük Görevler',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                Consumer<DailyTaskService>(
                  builder: (context, taskService, child) {
                    return Column(
                      children: [
                        // Günlük görev kartları
                        ...taskService.todayTasks.map((task) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: task.isCompleted 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: task.isCompleted 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                task.isCompleted ? Icons.check : Icons.radio_button_unchecked,
                                color: task.isCompleted ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? Colors.grey : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(task.categoryColor.replaceAll('#', '0xFF'))),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      task.categoryName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${task.points} puan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: task.isCompleted ? Colors.green[600] : Colors.blue[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (task.isCompleted && task.completedAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tamamlandı: ${_formatTime(task.completedAt!)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: task.isCompleted
                                ? IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.orange),
                                    onPressed: () => taskService.resetTask(task.id),
                                    tooltip: 'Görevi sıfırla',
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => taskService.completeTask(task.id),
                                    tooltip: 'Görevi tamamla',
                                  ),
                          ),
                        )).toList(),
                        
                        // Puan özeti
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.blue.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bugünkü Puan:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    '${taskService.completedTasks} / ${taskService.todayTasks.length} görev',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${taskService.totalPoints} / ${taskService.todayTasks.fold(0, (sum, task) => sum + task.points)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    'puan',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Görevleri yenile butonu
                        const SizedBox(height: 16),
                        Consumer<DailyTaskService>(
                          builder: (context, taskService, child) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      // Loading göster
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Görevler kontrol ediliyor...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      
                                      try {
                                        // Önce Firebase'de bugünkü görevler var mı kontrol et
                                        final hasTodayTasks = await taskService.checkTodayTasksInFirebase();
                                        
                                        if (hasTodayTasks) {
                                          // Bugünkü görevler varsa, sadece yenile
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Bugünkü görevler zaten mevcut, yenileniyor...'),
                                              backgroundColor: Colors.blue,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          
                                          await taskService.refreshDailyTasks();
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Görevler başarıyla yenilendi!'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } else {
                                          // Bugünkü görevler yoksa, yeni görevler oluştur
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Yeni görevler oluşturuluyor...'),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          
                                          await taskService.refreshDailyTasks();
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Yeni görevler oluşturuldu!'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Hata: $e'),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Görevleri Yenile'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Tamamlanan görevleri görüntüle butonu
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCompletedTasksDialog(context, taskService),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Tamamlanan Görevleri Görüntüle'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Yeni özellikler
                Text(
                  'Yeni Özellikler',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                // AI Analiz kartı
                Card(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIAnalysisPage(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 48,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Mood Analizi',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mood verilerinizi AI ile analiz edin',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.deepPurple.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.deepPurple.withOpacity(0.5),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Nefes egzersizi kartı
                Card(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BreathingPage(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.air,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nefes Egzersizi',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '4-4-6 tekniği ile sakinleş',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                


                const SizedBox(height: 20),

                // Son mood'lar
                Text(
                  'Son Mood\'lar',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                if (moodService.moodEntries.isNotEmpty) ...[
                  ...moodService.moodEntries.take(5).map((mood) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(
                        mood.mood,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(mood.note ?? 'Not yok'),
                      subtitle: Text(_formatDate(mood.timestamp)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteMood(context, mood),
                      ),
                    ),
                  )),
                ] else ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz mood kaydedilmemiş.'),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Banner reklam
                Consumer<AdService>(
                  builder: (context, adService, child) {
                    if (adService.isBannerAdLoaded && adService.bannerAd != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: 16),
                        width: adService.bannerAd!.size.width.toDouble(),
                        height: adService.bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: adService.bannerAd!),
                      );
                    } else if (adService.error != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reklam yüklenemedi',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMoodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const MoodPicker(),
    );
  }

  void _deleteMood(BuildContext context, MoodEntry mood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mood\'u Sil'),
        content: Text('Bu mood\'u silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final moodService = context.read<MoodService>();
              moodService.deleteMoodEntry(mood.id);
              Navigator.of(context).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Bugün ${_formatTime(date)}';
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      return 'Dün ${_formatTime(date)}';
    } else if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays} gün önce ${_formatTime(date)}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Mood'a uygun söz döndür - Otomatik seçim
  String _getQuoteForMood(String mood) {
    // Mood'a göre otomatik söz seçimi
    switch (mood) {
      case '😢': // Çok üzgün
        return 'Her yağmur damlasından sonra güneş doğar. Sen güçlüsün, bunu unutma.';
        
      case '😔': // Üzgün
        return 'Her karanlık gecenin sonunda şafak söker. Üzüntüden öğren, acıdan büyü.';
        
      case '😐': // Normal
        return 'Her gün bir hediyedir. Şu anda güvendesin, rahatla ve bu anın keyfini çıkar.';
        
      case '😊': // Mutlu
        return 'Mutluluk bir seçimdir, her gün yapabileceğin bir seçim. Gülümseme bulaşıcıdır!';
        
      case '🤩': // Çok mutlu
        return 'Senin mutluluğun başkalarının da mutluluğudur. Güzel düşün, güzel yaşa, güzel ol!';
        
      case '😠': // Kızgın
        return 'Öfke geçicidir, pişmanlık kalıcıdır. Sakin ol, düşün, sonra konuş.';
        
      default:
        return 'Her gün yeni bir başlangıçtır. Sen değerlisin!';
    }
  }

  void _showCompletedTasksDialog(BuildContext context, DailyTaskService taskService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tamamlanan Görevler'),
        content: FutureBuilder<List<DailyTask>>(
          future: taskService.getCompletedTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}');
            }
            
            final completedTasks = snapshot.data ?? [];
            
            if (completedTasks.isEmpty) {
              return const Text('Henüz tamamlanan görev bulunmuyor.');
            }
            
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: completedTasks.map((task) {
                  return ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      'Puan: ${task.points}, Kategori: ${task.categoryName}',
                    ),
                    trailing: task.completedAt != null 
                        ? Text(
                            _formatTime(task.completedAt!),
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
} 