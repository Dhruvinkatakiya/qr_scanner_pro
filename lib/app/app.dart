import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/root/root_shell.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Root widget. Rebuilds themes reactively when the accent colour or theme mode
/// changes, and chooses between onboarding and the main shell on launch.
class QrScannerApp extends ConsumerWidget {
  const QrScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(settings.accentColor),
      darkTheme: AppTheme.dark(settings.accentColor),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: settings.onboardingDone
          ? const RootShell()
          : const OnboardingScreen(),
    );
  }
}
