import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'service_providers.dart';

/// Immutable snapshot of user preferences.
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.accentColor = AccentColors.defaultAccent,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.autoOpenLinks = false,
    this.onboardingDone = false,
  });

  final ThemeMode themeMode;
  final Color accentColor;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool autoOpenLinks;
  final bool onboardingDone;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? autoOpenLinks,
    bool? onboardingDone,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoOpenLinks: autoOpenLinks ?? this.autoOpenLinks,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final storage = ref.read(storageServiceProvider);
    final themeIndex =
        storage.getSetting<int>(AppConstants.kThemeMode, defaultValue: 0) ?? 0;
    final accent = storage.getSetting<int>(AppConstants.kAccentColor,
            defaultValue: AccentColors.defaultAccent.toARGB32()) ??
        AccentColors.defaultAccent.toARGB32();
    return SettingsState(
      themeMode: ThemeMode.values[themeIndex.clamp(0, 2)],
      accentColor: Color(accent),
      soundEnabled:
          storage.getSetting<bool>(AppConstants.kSoundEnabled, defaultValue: true) ??
              true,
      hapticsEnabled: storage.getSetting<bool>(AppConstants.kHapticsEnabled,
              defaultValue: true) ??
          true,
      autoOpenLinks: storage.getSetting<bool>(AppConstants.kAutoOpenLinks,
              defaultValue: false) ??
          false,
      onboardingDone: storage.getSetting<bool>(AppConstants.kOnboardingDone,
              defaultValue: false) ??
          false,
    );
  }

  StorageService get _storage => ref.read(storageServiceProvider);

  void setThemeMode(ThemeMode mode) {
    _storage.setSetting(AppConstants.kThemeMode, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  void setAccentColor(Color color) {
    _storage.setSetting(AppConstants.kAccentColor, color.toARGB32());
    state = state.copyWith(accentColor: color);
  }

  void setSoundEnabled(bool value) {
    _storage.setSetting(AppConstants.kSoundEnabled, value);
    state = state.copyWith(soundEnabled: value);
  }

  void setHapticsEnabled(bool value) {
    _storage.setSetting(AppConstants.kHapticsEnabled, value);
    state = state.copyWith(hapticsEnabled: value);
  }

  void setAutoOpenLinks(bool value) {
    _storage.setSetting(AppConstants.kAutoOpenLinks, value);
    state = state.copyWith(autoOpenLinks: value);
  }

  void completeOnboarding() {
    _storage.setSetting(AppConstants.kOnboardingDone, true);
    state = state.copyWith(onboardingDone: true);
  }
}
