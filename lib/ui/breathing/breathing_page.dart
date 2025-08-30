import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/breathing_service.dart';

/// Sakinleş ekranı - nefes egzersizi
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  bool _isBreathing = false;
  String _breathingPhase = 'Nefes al';
  int _countdown = 4;
  Timer? _breathingTimer;
  int _currentSessionTime = 0; // Mevcut oturum süresi
  
  // Nefes egzersizi fazları
  final List<Map<String, dynamic>> _breathingPhases = [
    {'name': 'Nefes al', 'duration': 4, 'color': Colors.blue, 'emoji': '🫁'},
    {'name': 'Tut', 'duration': 4, 'color': Colors.green, 'emoji': '⏸️'},
    {'name': 'Ver', 'duration': 6, 'color': Colors.orange, 'emoji': '💨'},
  ];
  
  int _currentPhaseIndex = 0;
  
  // Motivasyon mesajları
  final List<String> _calmMessages = [
    'Derin nefes al, sakinleş 🧘‍♀️',
    'Her nefes seni huzura yaklaştırır ✨',
    'Şu anda güvendesin, rahatla 🕊️',
    'Nefesinle birlikte stres gitsin 🌊',
    'Bu an senin, keyfini çıkar 🌸',
    'Yavaşla, acele etme 🐌',
    'Her nefes yeni bir başlangıç 🌅',
    'Huzur içinde ol, her şey yolunda 🕯️',
  ];
  
  // İstatistikler - Provider'dan alınacak

  @override
  void initState() {
    super.initState();
    
    // Nefes animasyonu için controller
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Daire büyüyüp küçülme animasyonu
    _breathingAnimation = Tween<double>(
      begin: 80.0,
      end: 140.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    // Firebase'den verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBreathingData();
    });
  }
  
  // Nefes egzersizi verilerini yükle
  void _loadBreathingData() {
    final breathingService = context.read<BreathingService>();
    // Veriler zaten BreathingService'de otomatik yükleniyor
    // Burada sadece UI'ı güncelle
    setState(() {});
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _breathingTimer?.cancel();
    super.dispose();
  }

  /// Nefes egzersizini başlat
  void _startBreathing() {
    if (_isBreathing) return;
    
    setState(() {
      _isBreathing = true;
      _currentPhaseIndex = 0;
    });
    
    _startBreathingPhase();
  }

  /// Nefes egzersizini durdur
  void _stopBreathing() {
    setState(() {
      _isBreathing = false;
      _breathingPhase = 'Nefes al';
      _countdown = 4;
    });
    
    _breathingTimer?.cancel();
    _breathingController.reset();
    
    // Nefes egzersizi istatistiklerini güncelle
    if (_currentSessionTime > 0) {
      final breathingService = context.read<BreathingService>();
      breathingService.completeSession(_currentSessionTime);
      _currentSessionTime = 0; // Sıfırla
    }
  }

  /// Nefes fazını başlat
  void _startBreathingPhase() {
    if (!_isBreathing) return;
    
    final phase = _breathingPhases[_currentPhaseIndex];
    final duration = phase['duration'] as int;
    
    setState(() {
      _breathingPhase = phase['name'] as String;
      _countdown = duration;
    });
    
    // Animasyonu başlat
    if (_currentPhaseIndex == 0) {
      // Nefes alma - daire büyüsün
      _breathingController.forward();
    } else if (_currentPhaseIndex == 1) {
      // Tutma - daire sabit kalsın
      _breathingController.value = 1.0;
    } else {
      // Verme - daire küçülsün
      _breathingController.reverse();
    }
    
    // Geri sayım
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isBreathing) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdown--;
        _currentSessionTime++;
      });
      
      if (_countdown <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  /// Nefes egzersizini sıfırla
  void _resetBreathing() {
    // Eğer nefes egzersizi çalışıyorsa durdur
    if (_isBreathing) {
      _stopBreathing();
    }
    
    // Timer'ı iptal et
    _breathingTimer?.cancel();
    
    // Animasyonu sıfırla
    _breathingController.reset();
    
    // State'i sıfırla
    setState(() {
      _currentPhaseIndex = 0;
      _breathingPhase = 'Nefes al';
      _countdown = 4;
      _currentSessionTime = 0; // Oturum süresini de sıfırla
    });
    
    // Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nefes egzersizi sıfırlandı 🫁'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Sonraki fazı başlat
  void _nextPhase() {
    _currentPhaseIndex = (_currentPhaseIndex + 1) % _breathingPhases.length;
    
    if (_currentPhaseIndex == 0) {
      // Bir tur tamamlandı, tekrar başla
      _startBreathingPhase();
    } else {
      _startBreathingPhase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sakinleş',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: isVerySmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // Başlık
                  Text(
                    'Nefes Egzersizi',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isVerySmallScreen ? 16 : 20),
                  
                  // Açıklama
                  Container(
                    padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
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
                    child: Text(
                      '4-4-6 nefes tekniği ile sakinleş:\n'
                      '4 saniye nefes al, 4 saniye tut, 6 saniye ver.',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 14 : 16,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 24 : 40),
                  
                  // Nefes animasyonu
                  SizedBox(
                    height: isSmallScreen ? screenHeight * 0.35 : screenHeight * 0.4,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animasyonlu daire
                          AnimatedBuilder(
                            animation: _breathingAnimation,
                            builder: (context, child) {
                              return Container(
                                width: _breathingAnimation.value,
                                height: _breathingAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isBreathing 
                                      ? _breathingPhases[_currentPhaseIndex]['color'].withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: _isBreathing 
                                        ? _breathingPhases[_currentPhaseIndex]['color']
                                        : Colors.grey,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _isBreathing ? Icons.air : Icons.air_outlined,
                                    size: _breathingAnimation.value * 0.3,
                                    color: _isBreathing 
                                        ? _breathingPhases[_currentPhaseIndex]['color']
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isVerySmallScreen ? 20 : 30),
                          
                          // Faz bilgisi
                          Text(
                            _breathingPhase,
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: _isBreathing 
                                  ? _breathingPhases[_currentPhaseIndex]['color']
                                  : Colors.grey,
                            ),
                          ),
                          SizedBox(height: isVerySmallScreen ? 8 : 10),
                          
                          // Geri sayım
                          if (_isBreathing)
                            Text(
                              '$_countdown',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 36 : 48,
                                fontWeight: FontWeight.bold,
                                color: _breathingPhases[_currentPhaseIndex]['color'],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // İstatistikler
                  Container(
                    padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                    margin: EdgeInsets.only(bottom: isVerySmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Consumer<BreathingService>(
                              builder: (context, breathingService, child) {
                                return Text(
                                  '${breathingService.totalSessions}',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                );
                              },
                            ),
                            Text(
                              'Seans',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 12 : 14,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Consumer<BreathingService>(
                              builder: (context, breathingService, child) {
                                return Text(
                                  '${(breathingService.totalTimeMinutes).floor()}',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                );
                              },
                            ),
                            Text(
                              'Dakika',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 12 : 14,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Kontrol butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Başlat/Durdur butonu
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 4 : 8),
                          child: ElevatedButton(
                            onPressed: _isBreathing ? _stopBreathing : _startBreathing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isBreathing ? Colors.red : Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 20 : 32,
                                vertical: isVerySmallScreen ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              _isBreathing ? 'Durdur' : 'Başlat',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Sıfırla butonu
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 4 : 8),
                          child: ElevatedButton(
                            onPressed: () => _resetBreathing(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 16 : 24,
                                vertical: isVerySmallScreen ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Sıfırla',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isVerySmallScreen ? 16 : 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 