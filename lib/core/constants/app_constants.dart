import 'dart:io';

String get superbase_url => Platform.environment['SUPERBASE_URL'] ?? '';
String get superbase_anon_key => Platform.environment['SUPERBASE_ANON_KEY'] ?? '';

class AppConstants {
  static String supabaseUrl = superbase_url;

  static String supabaseAnonKey = superbase_anon_key;

  static const String testUserId = 'user_123';

  static const int pageSize = 10;

  static const Duration likeDebounceDuration =
      Duration(milliseconds: 800);
}