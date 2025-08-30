import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mood_service.dart';
import '../../core/ad_service.dart';
import '../../core/models/mood_entry.dart';

class MoodPicker extends StatefulWidget {
  const MoodPicker({super.key});

  @override
  State<MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<MoodPicker> {
  late String _selectedEmoji;
  late TextEditingController _noteController;
  bool _isLoading = false;

  // Basitleştirilmiş emoji listesi - 6 temel mood
  static const List<String> _popularEmojis = [
    '😢', // Çok üzgün
    '😔', // Üzgün  
    '😐', // Normal
    '😊', // Mutlu
    '🤩', // Çok mutlu
    '😠', // Kızgın
  ];

  @override
  void initState() {
    super.initState();
    _selectedEmoji = _popularEmojis[0];
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ruh Halini Seç',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Emoji seçimi
          Text(
            'Bugün nasılsın?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          
          const SizedBox(height: 16),
          
          // Emoji grid - 6 temel mood
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: _popularEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _popularEmojis[index];
                final isSelected = emoji == _selectedEmoji;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Not alanı
          Text(
            'Not ekle (isteğe bağlı)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _noteController,
            maxLength: 80,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Bugün neler yaşadın? Nasıl hissediyorsun?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '${_noteController.text.length}/80',
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMood,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Kaydet'),
            ),
          ),
          
          // Alt boşluk için
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _saveMood() async {
    setState(() => _isLoading = true);
    
    try {
      final moodService = context.read<MoodService>();
      final adService = context.read<AdService>();
      
      // Not metnini temizle
      final note = _noteController.text.trim();
      final finalNote = note.isEmpty ? null : note;
      
      // Yeni mood entry oluştur
      final moodEntry = MoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mood: _selectedEmoji,
        note: finalNote,
        timestamp: DateTime.now(),
        location: null,
      );
      
      // Mood'u kaydet
      await moodService.addMoodEntry(moodEntry);
      
      // Interstitial reklam göster
      try {
        await adService.showInterstitialAd();
      } catch (e) {
        print('Reklam gösterilemedi: $e');
      }
      
      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Modal'ı kapat
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilemedi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 