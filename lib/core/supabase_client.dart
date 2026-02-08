import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

class SupabaseClientManager {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL not set. Use --dart-define=SUPABASE_URL=...');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY not set. Use --dart-define=SUPABASE_ANON_KEY=...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
