import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // Timezone'ları başlat
      tz.initializeTimeZones();

      // Android ayarları
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS ayarları
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Genel ayarlar
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Bildirimleri başlat
      await _notifications.initialize(initSettings);
      
      // Android kanal oluştur
      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }
      
      print('Notification service başarıyla başlatıldı');
    } catch (e) {
      print('Notification service başlatılamadı: $e');
      rethrow;
    }
  }

  Future<void> _createAndroidChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        'moodi_daily',
        'Günlük Mood Hatırlatıcı',
        description: 'Her akşam mood girişi için hatırlatma',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
          
      print('Android notification kanalı oluşturuldu');
    } catch (e) {
      print('Android notification kanalı oluşturulamadı: $e');
      // Hata durumunda devam et
    }
  }

  // Her akşam 9'da bildirim planla
  Future<void> scheduleDailyNotification() async {
    try {
      // Önce mevcut bildirimi iptal et
      await cancelDailyNotification();
      
      // Bildirim ID'si
      const notificationId = 1;
      
      // Akşam 9'da bildirim
      final scheduledDate = _getNext9PM();
      
      // Exact alarm izni kontrol et (Android 12+)
      // Not: canScheduleExactAlarms metodu mevcut değil, direkt normal bildirim kullan
      if (Platform.isAndroid) {
        print('Android için normal bildirim kullanılıyor');
        await _scheduleNormalNotification(notificationId, scheduledDate);
        return;
      }
      
      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'moodi_daily',
        'Günlük Mood Hatırlatıcı',
        channelDescription: 'Her akşam mood girişi için hatırlatma',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF673AB7), // Deep Purple
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Bugün nasıl hissediyorsun? Mood\'unu kaydet ve gününü değerlendir! 😊',
          htmlFormatBigText: true,
          contentTitle: 'Mood Hatırlatıcı',
          htmlFormatContentTitle: true,
          summaryText: 'Günlük mood takibi',
          htmlFormatSummaryText: true,
        ),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      // Notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Bildirimi planla
      await _notifications.zonedSchedule(
        notificationId,
        'Mood Hatırlatıcı 🌙',
        'Bugün nasıl hissediyorsun? Mood\'unu kaydet ve gününü değerlendir! 😊',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte
      );

      print('Günlük bildirim planlandı: ${scheduledDate.toString()}');
    } catch (e) {
      print('Daily notification scheduling hatası: $e');
      // Hata durumunda devam et
    }
  }

  // Normal bildirim planla (exact alarm olmadan)
  Future<void> _scheduleNormalNotification(int notificationId, tz.TZDateTime scheduledDate) async {
    try {
      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'moodi_daily',
        'Günlük Mood Hatırlatıcı',
        channelDescription: 'Her akşam mood girişi için hatırlatma',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF673AB7), // Deep Purple
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Bugün nasıl hissediyorsun? Mood\'unu kaydet ve gününü değerlendir! 😊',
          htmlFormatBigText: true,
          contentTitle: 'Mood Hatırlatıcı',
          htmlFormatContentTitle: true,
          summaryText: 'Günlük mood takibi',
          htmlFormatSummaryText: true,
        ),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      // Notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Bildirimi planla (exact alarm olmadan)
      await _notifications.zonedSchedule(
        notificationId,
        'Mood Hatırlatıcı 🌙',
        'Bugün nasıl hissediyorsun? Mood\'unu kaydet ve gününü değerlendir! 😊',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Exact alarm olmadan
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte
      );

      print('Normal bildirim planlandı: ${scheduledDate.toString()}');
    } catch (e) {
      print('Normal notification scheduling hatası: $e');
      // Hata durumunda devam et
    }
  }

  // Sonraki akşam 9'u hesapla
  tz.TZDateTime _getNext9PM() {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, // Saat 9 (21:00)
      0,  // Dakika 0
    );

    // Eğer bugün 9'u geçtiyse, yarın 9'da planla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Bildirimi iptal et
  Future<void> cancelDailyNotification() async {
    try {
      await _notifications.cancel(1);
      print('Günlük bildirim iptal edildi');
    } catch (e) {
      print('Bildirim iptal edilemedi: $e');
    }
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Tüm bildirimler iptal edildi');
    } catch (e) {
      print('Tüm bildirimler iptal edilemedi: $e');
    }
  }

  // Bildirim durumunu kontrol et
  Future<bool> isNotificationScheduled() async {
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      return pendingNotifications.any((notification) => notification.id == 1);
    } catch (e) {
      print('Bildirim durumu kontrol edilemedi: $e');
      return false;
    }
  }
} 