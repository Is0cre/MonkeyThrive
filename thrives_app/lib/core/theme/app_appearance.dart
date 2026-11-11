import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccent {
  teal,
  green,
  blue,
  amber,
}

enum AppContrast {
  soft,
  standard,
  high,
}

class AppearanceSettings {
  final AppAccent accent;
  final AppContrast contrast;

  const AppearanceSettings({
    this.accent = AppAccent.teal,
    this.contrast = AppContrast.standard,
  });

  Color get accentColor {
    switch (accent) {
      case AppAccent.teal:
        return const Color(0xFF4ECDC4);
      case AppAccent.green:
        return const Color(0xFF6FCF97);
      case AppAccent.blue:
        return const Color(0xFF66A6FF);
      case AppAccent.amber:
        return const Color(0xFFE8A645);
    }
  }

  Color get background {
    switch (contrast) {
      case AppContrast.soft:
        return const Color(0xFF111821);
      case AppContrast.standard:
        return const Color(0xFF0D1117);
      case AppContrast.high:
        return Colors.black;
    }
  }

  Color get surface {
    switch (contrast) {
      case AppContrast.soft:
        return const Color(0xFF1A222D);
      case AppContrast.standard:
        return const Color(0xFF161B22);
      case AppContrast.high:
        return const Color(0xFF0F1318);
    }
  }

  Color get surfaceVariant {
    switch (contrast) {
      case AppContrast.soft:
        return const Color(0xFF222C39);
      case AppContrast.standard:
        return const Color(0xFF1C2430);
      case AppContrast.high:
        return const Color(0xFF202833);
    }
  }

  AppearanceSettings copyWith({
    AppAccent? accent,
    AppContrast? contrast,
  }) {
    return AppearanceSettings(
      accent: accent ?? this.accent,
      contrast: contrast ?? this.contrast,
    );
  }
}

class AppAppearanceController {
  AppAppearanceController._();

  static final instance = AppAppearanceController._();

  static const _keyAccent = 'appearance_accent';
  static const _keyContrast = 'appearance_contrast';

  final notifier = ValueNotifier<AppearanceSettings>(
    const AppearanceSettings(),
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final accent = _enumByName(
      AppAccent.values,
      prefs.getString(_keyAccent),
      AppAccent.teal,
    );
    final contrast = _enumByName(
      AppContrast.values,
      prefs.getString(_keyContrast),
      AppContrast.standard,
    );
    notifier.value = AppearanceSettings(accent: accent, contrast: contrast);
  }

  Future<void> setAccent(AppAccent accent) async {
    final next = notifier.value.copyWith(accent: accent);
    notifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccent, accent.name);
  }

  Future<void> setContrast(AppContrast contrast) async {
    final next = notifier.value.copyWith(contrast: contrast);
    notifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContrast, contrast.name);
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
