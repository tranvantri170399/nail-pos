// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTheme {
  dark('Dark Theme', Color(0xFF0D0D12), Color(0xFFFF6B9D)),
  light('Light Theme', Color(0xFFFFFFFF), Color(0xFF2196F3));

  const AppTheme(this.name, this.backgroundColor, this.primaryColor);
  final String name;
  final Color backgroundColor;
  final Color primaryColor;
}

class ThemeState {
  final AppTheme theme;
  const ThemeState({required this.theme});
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState(theme: AppTheme.dark));

  void toggleTheme() {
    final currentTheme = state.theme;
    final newTheme = currentTheme == AppTheme.dark ? AppTheme.light : AppTheme.dark;
    state = ThemeState(theme: newTheme);
    
    // Lưu vào SharedPreferences
    // TODO: Implement persistence
  }

  void setTheme(AppTheme theme) {
    state = ThemeState(theme: theme);
    // TODO: Implement persistence
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

final currentThemeProvider = Provider<AppTheme>(
  (ref) => ref.watch(themeProvider).theme,
);
