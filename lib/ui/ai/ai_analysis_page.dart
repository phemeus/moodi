import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ai_service.dart';
import '../../core/mood_service.dart';

class AIAnalysisPage extends StatefulWidget {
  const AIAnalysisPage({super.key});

  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage> {
  @override
  Widget build(BuildContext context) {
    // Responsive tasarım için ekran boyutları
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Mood Analizi',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: isVerySmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: Consumer<AIService>(
        builder: (context, aiService, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: isVerySmallScreen ? 40 : 48,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(height: isVerySmallScreen ? 8 : 12),
                            Text(
                              'AI Mood Analizi',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                fontSize: isVerySmallScreen ? 18 : 20,
                              ),
                            ),
                            SizedBox(height: isVerySmallScreen ? 4 : 6),
                            Text(
                              'Mood verilerinizi analiz ederek kişiselleştirilmiş öneriler alın',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.deepPurple.withOpacity(0.7),
                                fontSize: isVerySmallScreen ? 12 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Analiz butonu veya sonuç
                      if (aiService.error != null)
                        _buildErrorState(aiService)
                      else if (aiService.analysisResult == null && !aiService.isAnalyzing)
                        _buildAnalysisButton(aiService)
                      else if (aiService.isAnalyzing)
                        _buildLoadingState()
                      else
                        _buildAnalysisResult(aiService),
                      
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      
                      // Bilgi kartı
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: isVerySmallScreen ? 16 : 20,
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 8),
                            Expanded(
                              child: Text(
                                'AI analizi için kısa bir ödüllü reklam izlemeniz gerekiyor. Reklam tamamlandıktan sonra detaylı analiz raporunuz hazırlanacak.',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: isVerySmallScreen ? 10 : 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Alt boşluk
                      SizedBox(height: isSmallScreen ? 12 : 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisButton(AIService aiService) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final isVerySmallScreen = MediaQuery.of(context).size.height < 600;
    
    // Mood sayısına göre AI analizi butonunu göster
    final moodService = context.read<MoodService>();
    final moodCount = moodService.moodEntries.length;
    final canAnalyze = moodCount >= 5 && (moodCount % 5 == 0);
    
    if (!canAnalyze) {
      return Container(
        width: double.infinity,
        height: isVerySmallScreen ? 120 : 140,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                color: Colors.grey,
                size: isVerySmallScreen ? 32 : 36,
              ),
              SizedBox(height: isVerySmallScreen ? 8 : 12),
              Text(
                'AI Analizi Kilidi',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isVerySmallScreen ? 4 : 6),
              Text(
                'Her 5 mood girişinde bir AI analizi yapabilirsiniz',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isVerySmallScreen ? 11 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isVerySmallScreen ? 4 : 6),
              Text(
                'Şu anki durum: $moodCount / ${((moodCount ~/ 5) + 1) * 5}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isVerySmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: isVerySmallScreen ? 120 : 140,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => aiService.startAIAnalysis(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 2 : 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: isVerySmallScreen ? 24 : 32,
                  color: Colors.deepPurple,
                ),
                SizedBox(height: isVerySmallScreen ? 8 : 12),
                Text(
                  'AI Analizi Başlat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: isVerySmallScreen ? 16 : 18,
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 6 : 8),
                Text(
                  'Kısa reklam izleyerek analizi başlatın',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.deepPurple.withOpacity(0.7),
                    fontSize: isVerySmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final isVerySmallScreen = MediaQuery.of(context).size.height < 600;
    
    return Container(
      width: double.infinity,
      height: isVerySmallScreen ? 150 : 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Text(
              'AI Analizi Yapılıyor...',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 6 : 8),
            Text(
              'Mood verileriniz analiz ediliyor',
              style: TextStyle(
                color: Colors.grey,
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 6 : 8),
            Text(
              'Reklam izlendi ✓',
              style: TextStyle(
                color: Colors.green,
                fontSize: isVerySmallScreen ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(AIService aiService) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Analiz Sonucu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => aiService.clearAnalysis(),
                  icon: const Icon(Icons.refresh),
                  color: Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: _formatAnalysisText(aiService.analysisResult!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AI analiz metnini formatla
  Widget _formatAnalysisText(String analysisText) {
    // Markdown işaretlerini temizle
    String cleanText = analysisText
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('*', '')
        .replaceAll('_', '')
        .replaceAll('#', '')
        .replaceAll('>', '')
        .replaceAll('```', '');
    
    // Satırları böl
    List<String> lines = cleanText.split('\n');
    List<Widget> widgets = [];
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      if (line.startsWith('Dikkat Çeken Noktalar:') || 
          line.startsWith('Kişiselleştirilmiş Öneriler:') ||
          line.startsWith('Genel İstatistikler:') ||
          line.startsWith('Trend Analizi:') ||
          line.startsWith('Gelecek için Öneriler:') ||
          line.startsWith('Uyarı:')) {
        // Başlık
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ),
        );
      } else if (line.startsWith('•') || line.startsWith('-')) {
        // Madde işareti
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.deepPurple)),
                Expanded(
                  child: Text(
                    line.substring(1).trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Normal metin
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              line,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildErrorState(AIService aiService) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final isVerySmallScreen = MediaQuery.of(context).size.height < 600;
    
    return Container(
      width: double.infinity,
      height: isVerySmallScreen ? 150 : 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isVerySmallScreen ? 36 : 48,
              color: Colors.orange,
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Text(
              'Bir Hata Oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: isVerySmallScreen ? 16 : 18,
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 6 : 8),
            Text(
              aiService.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            ElevatedButton(
              onPressed: () {
                aiService.clearError();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 8 : 12,
                ),
              ),
              child: Text(
                'Tekrar Dene',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isVerySmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 