import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth_service.dart';
import '../../core/notification_service.dart';
import '../home/home_page.dart';
import '../auth/sign_in_page.dart';
import '../../core/daily_task_service.dart'; // Added import for DailyTaskService

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Splash ekranı için gecikme (2.5 saniye)
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // Notification service'i güvenli bir şekilde başlat
      try {
        final notificationService = context.read<NotificationService>();
        await notificationService.initialize();
        await notificationService.scheduleDailyNotification();
        print('Notification service başarıyla başlatıldı');
      } catch (notificationError) {
        print('Notification service başlatılamadı: $notificationError');
        // Notification hatası uygulamanın çalışmasını engellemesin
      }
      
      // Daily task service'i başlat
      try {
        final dailyTaskService = context.read<DailyTaskService>();
        
        // Timeout ile hızlı başlatma
        await Future.any([
          dailyTaskService.loadTasksFromFirebase(),
          Future.delayed(const Duration(seconds: 3)).then((_) {
            print('Daily task service timeout, devam ediliyor...');
            return null;
          }),
        ]);
        
        print('Daily task service başarıyla başlatıldı');
      } catch (taskError) {
        print('Daily task service başlatılamadı: $taskError');
        // Task service hatası uygulamanın çalışmasını engellemesin
      }
      
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Kullanıcı giriş yapmışsa ana sayfaya git
        if (currentUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Kullanıcı giriş yapmamışsa login sayfasına git
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Uygulama başlatılamadı: $e';
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }
    
    if (!_isInitialized) {
      return const SplashScreen();
    }
    
    // Bu duruma normalde ulaşmamalı ama fallback olarak
    return const SignInPage();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 24),
              Text(
                'Bir Hata Oluştu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'Uygulama başlatılamadı',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Logo animasyonu
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Transform.scale(
                  scale: 0.5 + (_animation.value * 0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App ikonu/logo
                      Image.asset(
                        'assets/moodi.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      
                      // App adı
                      Text(
                        'Moodi',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Alt başlık
                      Text(
                        'Ruh halini takip et, mutluluğunu ölç',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade600.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Yükleniyor göstergesi
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Yükleniyor yazısı
                      Text(
                        'Yükleniyor...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade600.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 