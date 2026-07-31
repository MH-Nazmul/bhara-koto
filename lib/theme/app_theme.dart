import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens that Material's ColorScheme has no slot for.
///
/// The palette targets one hostile environment: a phone held at arm's length on
/// a moving bus in Dhaka sunshine. That means near-black or near-white grounds,
/// one saturated accent, and hairline borders instead of heavy shadows so the
/// UI stays crisp rather than muddy.
@immutable
class BkColors extends ThemeExtension<BkColors> {
  const BkColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
    required this.accent,
    required this.accentSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;
  final Color accent;
  final Color accentSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;

  static const BkColors dark = BkColors(
    canvas: Color(0xFF07090C),
    surface: Color(0xFF10141A),
    surfaceRaised: Color(0xFF171C24),
    hairline: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF4F7FA),
    textSecondary: Color(0xFF97A2B2),
    textFaint: Color(0xFF5F6B7C),
    accent: Color(0xFF16D28A),
    accentSoft: Color(0x2216D28A),
    warning: Color(0xFFFFB020),
    warningSoft: Color(0x22FFB020),
    danger: Color(0xFFFF5C63),
    dangerSoft: Color(0x22FF5C63),
  );

  static const BkColors light = BkColors(
    canvas: Color(0xFFF2F4F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    hairline: Color(0x14101828),
    textPrimary: Color(0xFF0A1220),
    textSecondary: Color(0xFF5B6779),
    textFaint: Color(0xFF8B97A8),
    accent: Color(0xFF00A366),
    accentSoft: Color(0x1A00A366),
    warning: Color(0xFFB56B00),
    warningSoft: Color(0x1AB56B00),
    danger: Color(0xFFD92D3A),
    dangerSoft: Color(0x1AD92D3A),
  );

  @override
  BkColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textFaint,
    Color? accent,
    Color? accentSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
  }) =>
      BkColors(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        hairline: hairline ?? this.hairline,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textFaint: textFaint ?? this.textFaint,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        warning: warning ?? this.warning,
        warningSoft: warningSoft ?? this.warningSoft,
        danger: danger ?? this.danger,
        dangerSoft: dangerSoft ?? this.dangerSoft,
      );

  @override
  BkColors lerp(ThemeExtension<BkColors>? other, double t) {
    if (other is! BkColors) return this;
    return BkColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
    );
  }
}

extension BkColorsX on BuildContext {
  BkColors get bk => Theme.of(this).extension<BkColors>()!;
}

/// Shared shape language — one radius scale, used everywhere.
abstract final class BkRadius {
  static const small = BorderRadius.all(Radius.circular(10));
  static const medium = BorderRadius.all(Radius.circular(16));
  static const large = BorderRadius.all(Radius.circular(22));
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppTheme {
  static ThemeData dark() => _build(BkColors.dark, Brightness.dark);
  static ThemeData light() => _build(BkColors.light, Brightness.light);

  /// Keeps the status bar icons legible against whichever canvas is showing.
  static SystemUiOverlayStyle overlayFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: BkColors.dark.canvas,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: BkColors.light.canvas,
              systemNavigationBarIconBrightness: Brightness.dark,
            );

  static ThemeData _build(BkColors bk, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: bk.accent,
      brightness: brightness,
    ).copyWith(
      primary: bk.accent,
      surface: bk.surface,
      error: bk.danger,
      onPrimary: brightness == Brightness.dark ? const Color(0xFF04140D) : Colors.white,
      onSurface: bk.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bk.canvas,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      extensions: [bk],
      textTheme: _textTheme(base.textTheme, bk),
      appBarTheme: AppBarTheme(
        backgroundColor: bk.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: bk.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: bk.textSecondary, size: 20),
        systemOverlayStyle: overlayFor(brightness),
      ),
      dividerTheme: DividerThemeData(color: bk.hairline, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: bk.textSecondary, size: 20),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bk.surfaceRaised,
        contentTextStyle: TextStyle(color: bk.textPrimary, fontSize: 13.5),
        shape: const RoundedRectangleBorder(borderRadius: BkRadius.medium),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bk.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: bk.textFaint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bk.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BkRadius.large),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? bk.canvas : const Color(0xFFF4F6F9),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: bk.textFaint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BkRadius.medium,
          borderSide: BorderSide(color: bk.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BkRadius.medium,
          borderSide: BorderSide(color: bk.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BkRadius.medium,
          borderSide: BorderSide(color: bk.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BkRadius.medium,
          borderSide: BorderSide(color: bk.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BkRadius.medium,
          borderSide: BorderSide(color: bk.danger, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: bk.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: bk.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        minVerticalPadding: 10,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, BkColors bk) {
    // Numbers use tabular figures so the fare doesn't jitter as digits change.
    const tabular = [FontFeature.tabularFigures()];
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            letterSpacing: -3,
            height: 1,
            fontFeatures: tabular,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
            height: 1.05,
            fontFeatures: tabular,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: tabular,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4),
          bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.35),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        )
        .apply(bodyColor: bk.textPrimary, displayColor: bk.textPrimary);
  }
}
