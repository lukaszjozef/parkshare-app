import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseClientManager.initialize();

  runApp(
    const ProviderScope(
      child: ParkShareG181App(),
    ),
  );
}

class ParkShareG181App extends StatelessWidget {
  const ParkShareG181App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ParkShareG181',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
