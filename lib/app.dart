import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth_service.dart';
import 'core/mood_service.dart';
import 'core/ad_service.dart';
import 'core/ai_service.dart';
import 'core/notification_service.dart';
import 'core/daily_task_service.dart';
import 'core/breathing_service.dart';
import 'ui/gate/splash_gate.dart';

class MoodiApp extends StatelessWidget {
  const MoodiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MoodService()),
        ChangeNotifierProvider(create: (_) => AdService()),
        ChangeNotifierProxyProvider2<AdService, MoodService, AIService>(
          create: (context) => AIService(
            context.read<AdService>(),
            context.read<MoodService>(),
          ),
          update: (context, adService, moodService, previous) =>
            previous ?? AIService(adService, moodService),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
                  ChangeNotifierProvider(create: (_) => DailyTaskService()),
          ChangeNotifierProvider(create: (_) => BreathingService()),
      ],
      child: MaterialApp(
        title: 'Moodi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: const SplashGate(),
      ),
    );
  }
} 