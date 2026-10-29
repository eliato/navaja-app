import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get key =>
      publishableKey.isNotEmpty ? publishableKey : legacyAnonKey;

  static bool get isConfigured => url.isNotEmpty && key.isNotEmpty;

  static Future<bool> initialize() async {
    if (url.isEmpty && key.isEmpty) return false;
    if (!isConfigured) {
      throw StateError(
        'SUPABASE_URL y la clave pública de Supabase deben configurarse juntas.',
      );
    }
    await Supabase.initialize(url: url, publishableKey: key);
    return true;
  }
}
