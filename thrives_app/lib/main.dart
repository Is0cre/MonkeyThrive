import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/widgets/emergency_button.dart';
import 'core/models/tolerance_state.dart';
import 'core/state/wot_scope.dart';
import 'core/theme/app_appearance.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/prefs_service.dart';
import 'core/storage/tier_service.dart';
import 'core/widgets/main_shell.dart';
import 'features/checkin/screens/checkin_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final onboardingDone = await PrefsService.isOnboardingDone();
  final savedWot = await PrefsService.loadTodaysWotState();
  await AppAppearanceController.instance.load();
  await TierService.init();
  runApp(ThrivesApp(onboardingDone: onboardingDone, initialWot: savedWot));
}

class ThrivesApp extends StatefulWidget {
  final bool onboardingDone;
  final ToleranceState? initialWot;

  const ThrivesApp({
    super.key,
    required this.onboardingDone,
    required this.initialWot,
  });

  @override
  State<ThrivesApp> createState() => _ThrivesAppState();
}

class _ThrivesAppState extends State<ThrivesApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _onboardingDone;
  late final ValueNotifier<ToleranceState?> _wotNotifier;

  // Current route: onboarding → checkin → shell
  _AppRoute get _route {
    if (!_onboardingDone) return _AppRoute.onboarding;
    if (_wotNotifier.value == null) return _AppRoute.checkin;
    return _AppRoute.shell;
  }

  @override
  void initState() {
    super.initState();
    _onboardingDone = widget.onboardingDone;
    _wotNotifier = ValueNotifier(widget.initialWot);
    HardwareKeyboard.instance.addHandler(_onVolumeKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onVolumeKey);
    _wotNotifier.dispose();
    super.dispose();
  }

  /// Volume keys open the sigh. The handler is a no-op for every other key,
  /// including on the web build where these keys usually never arrive.
  bool _onVolumeKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.audioVolumeUp &&
        key != LogicalKeyboardKey.audioVolumeDown) {
      return false;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return false;
    EmergencyButton.open(navigator);
    return true;
  }

  void _onOnboardingComplete([ToleranceState? initialWot]) {
    setState(() {
      _onboardingDone = true;
      if (initialWot != null) {
        _wotNotifier.value = initialWot;
      }
    });
  }

  void _onCheckInComplete(ToleranceState state) {
    _wotNotifier.value = state;
    setState(() {}); // trigger route update
  }

  void _resetOnboarding() async {
    await PrefsService.resetOnboarding();
    setState(() {
      _onboardingDone = false;
      _wotNotifier.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WoTScope(
      notifier: _wotNotifier,
      child: ValueListenableBuilder<AppearanceSettings>(
        valueListenable: AppAppearanceController.instance.notifier,
        builder: (context, appearance, _) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: appearance.surface,
            systemNavigationBarIconBrightness: Brightness.light,
          ));
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'MonkeyThrive',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark(appearance),
            darkTheme: AppTheme.dark(appearance),
            themeMode: ThemeMode.dark,
            home: _buildHome(),
          );
        },
      ),
    );
  }

  Widget _buildHome() {
    switch (_route) {
      case _AppRoute.onboarding:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
      case _AppRoute.checkin:
        return CheckInScreen(onComplete: _onCheckInComplete);
      case _AppRoute.shell:
        return MainShell(onResetOnboarding: _resetOnboarding);
    }
  }
}

enum _AppRoute { onboarding, checkin, shell }
