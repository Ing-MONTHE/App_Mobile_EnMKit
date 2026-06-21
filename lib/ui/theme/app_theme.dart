import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system EnMKit — direction « fintech moderne » (Revolut / N26 / Wise).
///
/// Palette riche (indigo→violet), typographie Plus Jakarta Sans expressive,
/// profondeur par ombres multi-couches, dégradés vibrants et accents éclatants.
/// Source unique de vérité pour couleurs, typo, rayons, ombres, durées d'anim.
class AppTheme {
  AppTheme._();

  // --- Couleurs de marque ---------------------------------------------------
  static const Color indigo = Color(0xFF5145E5); // primaire
  static const Color violet = Color(0xFF7B5CFF);
  static const Color brandBlue = indigo; // alias compat

  // --- Accents éclatants (fintech) -----------------------------------------
  static const Color emerald = Color(0xFF10B981);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFF59E0B);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color pink = Color(0xFFEC4899);
  // Alias rétro-compat (anciens écrans).
  static const Color mint = emerald;
  static const Color lavender = violet;
  static const Color peach = coral;
  static const Color sky = cyan;

  // --- Fonds : crème accordé au motif doodle (texture de fond visible) ------
  static const Color bg = Color(0xFFFAF7F1);
  static const Color bgDeep = Color(0xFFF1ECE2);
  static const Color cream = bg; // alias compat
  static const Color creamDeep = bgDeep;

  // --- Encre ----------------------------------------------------------------
  static const Color ink = Color(0xFF15172E);
  static const Color inkSoft = Color(0xFF6E7191);

  // --- Sémantique -----------------------------------------------------------
  static const Color success = emerald;
  static const Color warning = amber;
  static const Color danger = coral;
  static const Color seed = indigo;

  // --- Dégradés signature ---------------------------------------------------
  static const Gradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5145E5), Color(0xFF7B5CFF), Color(0xFF9D7BFF)],
  );
  static const Gradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );
  static const Gradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF9472)],
  );

  // --- Métriques (affinées : moins "bubble", plus fintech) -----------------
  static const double radius = 20;
  static const double radiusControl = 14;
  static const double gap = 16;

  // --- Durées d'animation ---------------------------------------------------
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 650);

  /// Ombre premium, plus fine et discrète. [tint] colore légèrement l'ombre.
  static List<BoxShadow> elevedShadow({Color? tint, double strength = 1}) {
    final c = tint ?? indigo;
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.10 * strength),
        blurRadius: 18,
        offset: const Offset(0, 8),
        spreadRadius: -6,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04 * strength),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// Compat : ancien nom utilisé par des widgets existants.
  static List<BoxShadow> softShadow({Color? tint}) => elevedShadow(tint: tint);

  /// Accents sélectionnables dans les Réglages (« plusieurs styles »).
  static const Map<String, Color> accents = {
    'indigo': indigo,
    'emerald': emerald,
    'coral': coral,
    'cyan': cyan,
    'amber': amber,
    'pink': pink,
  };

  static const Map<String, String> accentLabels = {
    'indigo': 'Indigo',
    'emerald': 'Émeraude',
    'coral': 'Corail',
    'cyan': 'Cyan',
    'amber': 'Ambre',
    'pink': 'Rose',
  };

  static Color accentColor(String key) => accents[key] ?? indigo;

  /// Dégradé dérivé d'un accent (héros, FAB…).
  static Gradient accentGradient(String key) {
    final c = accentColor(key);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c, Color.lerp(c, Colors.white, 0.28)!],
    );
  }

  static ThemeData light({String accent = 'indigo'}) =>
      _build(Brightness.light, accentColor(accent));
  static ThemeData dark({String accent = 'indigo'}) =>
      _build(Brightness.dark, accentColor(accent));

  static ThemeData _build(Brightness brightness, Color primary) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: emerald,
    ).copyWith(
      surface: isDark ? const Color(0xFF14152A) : bg,
      onSurface: isDark ? const Color(0xFFEDEDF5) : ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = GoogleFonts.chakraPetchTextTheme(base.textTheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      textTheme: _tune(textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.chakraPetch(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E2038) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          textStyle: GoogleFonts.chakraPetch(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          textStyle: GoogleFonts.chakraPetch(
              fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.chakraPetch(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : bgDeep,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E2038) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: GoogleFonts.chakraPetch(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle:
            GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftPageTransition(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _tune(TextTheme t) => t.copyWith(
        displayLarge:
            t.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.2),
        displaySmall:
            t.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
        headlineMedium:
            t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineSmall:
            t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge:
            t.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: t.bodyMedium?.copyWith(height: 1.4),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      );
}

/// Transition de page : fondu + zoom doux.
class _SoftPageTransition extends PageTransitionsBuilder {
  const _SoftPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
