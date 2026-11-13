// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MonkeyThrive';

  @override
  String get boxBreathingTitle => 'Box Breathing';

  @override
  String get breathingBegin => 'Begin';

  @override
  String get breathingPause => 'Pause';

  @override
  String breathingCycle(int current, int total) {
    return 'Cycle $current of $total';
  }
}
