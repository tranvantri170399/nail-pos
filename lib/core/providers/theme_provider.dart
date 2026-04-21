// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _storageKey = 'app_theme';

  ThemeNotifier() : super(const ThemeState(theme: AppTheme.dark)) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_storageKey);

    if (savedTheme == null) return;

    final theme = savedTheme == AppTheme.light.name
        ? AppTheme.light
        : AppTheme.dark;
    state = ThemeState(theme: theme);
  }

  Future<void> _saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, theme.name);
  }

  void toggleTheme() {
    final currentTheme = state.theme;
    final newTheme = currentTheme == AppTheme.dark ? AppTheme.light : AppTheme.dark;
    state = ThemeState(theme: newTheme);
    _saveTheme(newTheme);
  }

  void setTheme(AppTheme theme) {
    state = ThemeState(theme: theme);
    _saveTheme(theme);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

final currentThemeProvider = Provider<AppTheme>(
  (ref) => ref.watch(themeProvider).theme,
);
