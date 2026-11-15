import 'package:flutter/material.dart';
import 'app_appearance.dart';

// THRIVES colour palette — deep navy, soft teal, warm amber
class AppColors {
  AppColors._();

  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceVariant = Color(0xFF1C2430);
  static const teal = Color(0xFF4ECDC4);
  static const tealDim = Color(0xFF2A7A75);
  static const amber = Color(0xFFE8A645);
  static const amberDim = Color(0xFF8A6228);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const danger = Color(0xFFDA3633);
  static const dangerSurface = Color(0xFF2D1F1F);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark(
      [AppearanceSettings appearance = const AppearanceSettings()]) {
    final accent = appearance.accentColor;
    final background = appearance.background;
    final surface = appearance.surface;
    final surfaceVariant = appearance.surfaceVariant;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AppColors.amber,
        surface: surface,
        surfaceContainer: surface,
        surfaceContainerHighest: surfaceVariant,
        onPrimary: background,
        onSecondary: background,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: accent.withValues(alpha: 0.10),
      hoverColor: accent.withValues(alpha: 0.06),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CalmPageTransitionsBuilder(),
          TargetPlatform.iOS: CalmPageTransitionsBuilder(),
          TargetPlatform.linux: CalmPageTransitionsBuilder(),
          TargetPlatform.macOS: CalmPageTransitionsBuilder(),
          TargetPlatform.windows: CalmPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CalmPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      useMaterial3: true,
    );
  }
}

/// The accent and the surfaces chosen in Settings.
///
/// Reading these subscribes the widget to the theme, so a change in Settings
/// repaints the tool that is already on screen.
extension AppScheme on BuildContext {
  ColorScheme get appScheme => Theme.of(this).colorScheme;

  Color get accent => appScheme.primary;

  Color get canvas => Theme.of(this).scaffoldBackgroundColor;

  Color get panel => appScheme.surface;

  Color get panelAlt => appScheme.surfaceContainerHighest;

  Color get onAccent => appScheme.onPrimary;

  Color get accentDim => Color.lerp(accent, const Color(0xFF000000), 0.45)!;

  /// A second colour in the same scheme, for a reading that sits beside
  /// the accent and still has to stay distinct.
  Color schemeShift(double degrees) {
    final hsl = HSLColor.fromColor(accent);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }
}

/// Shared motion. Durations of a breath, a tone, or a bilateral pass stay
/// where they are. These curves only change how a value travels.
class AppMotion {
  AppMotion._();

  static const press = Duration(milliseconds: 180);
  static const settle = Duration(milliseconds: 320);
  static const page = Duration(milliseconds: 340);

  /// A breath grows and settles without a corner at either end.
  static const breathe = Curves.easeInOutSine;

  /// Something arriving on screen.
  static const arrive = Curves.easeOutCubic;

  /// Something leaving.
  static const depart = Curves.easeInCubic;

  /// A control that opens and closes.
  static const fold = Curves.easeInOutCubic;
}

/// Fade and a short rise. The emergency sigh keeps its own faster route.
class CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const CalmPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return CalmFade(animation: animation, child: child);
  }
}

/// One curved fade. The curve is owned here so a route does not add a
/// listener on every frame.
class CalmFade extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;
  final bool slide;

  const CalmFade({
    super.key,
    required this.animation,
    required this.child,
    this.slide = true,
  });

  @override
  State<CalmFade> createState() => _CalmFadeState();
}

class _CalmFadeState extends State<CalmFade> {
  late final CurvedAnimation _curved;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _curved = CurvedAnimation(
      parent: widget.animation,
      curve: AppMotion.arrive,
      reverseCurve: AppMotion.depart,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(_curved);
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: widget.slide
          ? SlideTransition(position: _slide, child: widget.child)
          : widget.child,
    );
  }
}

/// Quiet scrolling. The edge glow is a flash, so it stays off.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
