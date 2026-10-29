import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/config/supabase_config.dart';

void main() {
  test('uses local mode when Supabase variables are absent', () async {
    expect(SupabaseConfig.isConfigured, isFalse);
    expect(await SupabaseConfig.initialize(), isFalse);
  });
}
