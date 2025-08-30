import 'package:intl/intl.dart';

class MoodDateUtils {
  // Bugünün tarih anahtarını döndür (YYYY-MM-DD)
  static String todayKey() {
    final now = DateTime.now();
    return keyOf(now);
  }

  // Verilen DateTime'dan tarih anahtarı oluştur
  static String keyOf(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Tarih anahtarını DateTime'a çevir
  static DateTime fromKey(String dateKey) {
    return DateFormat('yyyy-MM-dd').parse(dateKey);
  }

  // İnsan tarafından okunabilir tarih formatı (TR)
  static String human(DateTime date) {
    // Türkçe yerelleştirme için
    final formatter = DateFormat('d MMM y, EEEE', 'tr_TR');
    return formatter.format(date);
  }

  // Kısa tarih formatı (TR)
  static String short(DateTime date) {
    final formatter = DateFormat('d MMM', 'tr_TR');
    return formatter.format(date);
  }

  // Haftanın günü (TR)
  static String weekday(DateTime date) {
    final formatter = DateFormat('EEEE', 'tr_TR');
    return formatter.format(date);
  }

  // Tarih anahtarını insan tarafından okunabilir yap
  static String humanFromKey(String dateKey) {
    final date = fromKey(dateKey);
    return human(date);
  }

  // Bugün mü kontrol et
  static bool isToday(String dateKey) {
    return dateKey == todayKey();
  }

  // Dün mü kontrol et
  static bool isYesterday(String dateKey) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateKey == keyOf(yesterday);
  }

  // Tarih anahtarını göreceli metin olarak göster
  static String relative(String dateKey) {
    if (isToday(dateKey)) return 'Bugün';
    if (isYesterday(dateKey)) return 'Dün';
    return humanFromKey(dateKey);
  }
} 