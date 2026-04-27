// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  runApp(const ProviderScope(child: NailPOSApp()));
}

class NailPOSApp extends ConsumerWidget {
  const NailPOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTheme = ref.watch(currentThemeProvider);

    return MaterialApp.router(
      title: 'TPOS - Nail Salon',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentTheme.primaryColor,
          brightness: currentTheme == AppTheme.dark
              ? Brightness.dark
              : Brightness.light,
        ),
        scaffoldBackgroundColor: currentTheme.backgroundColor,
      ),
    );
  }
}
