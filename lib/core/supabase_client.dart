import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://incgqkflbmcxwjwqxiom.supabase.co';
const supabaseAnonKey = 'sb_publishable_B9CR5VTeeg5vjmSo4CZvIA_st1ajUZZ';

class SupabaseClientManager {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
