import 'package:flutter/material.dart';

/// MinduRun color tokens: dark graphite surfaces, electric lime as the
/// primary action color and ice blue for energy calls to action and points.
abstract final class AppColors {
  static const primary = Color(0xFFC5F658); // Lima elétrica
  static const onPrimary = Color(0xFF10130A);
  static const accent = Color(0xFF8FD3E9); // Azul-gelo
  static const onAccent = Color(0xFF081317);
  static const background = Color(0xFF0C0D0F);
  static const surface = Color(0xFF17181B);
  static const surfaceHigh = Color(0xFF222427);
  static const ink = Color(0xFF050607);
  static const heroStart = Color(0xFF1D1F23);
  static const heroEnd = Color(0xFF2A2E34);
  static const textPrimary = Color(0xFFF0F2F4);
  static const textSecondary = Color(0xFF979CA3);
  static const border = Color(0xFF2C2E31);
  static const success = Color(0xFF5ED8A9);
  static const warning = Color(0xFFF8C655);
  static const error = Color(0xFFFD7273);
  static const gold = Color(0xFFDDB96B);
  static const silver = Color(0xFFA8AEB8);
  static const bronze = Color(0xFFBC8865);

  /// Competition status colors (each status has its own hue).
  static const scheduled = accent;
  static const active = primary;
  static const finished = textSecondary;
  static const cancelled = error;
}

/// Font families. Text uses Archivo; points, numbers and the brand use
/// Barlow Condensed ExtraBold Italic. Without the bundled font files Flutter
/// falls back to the platform font, so layouts must not depend on metrics.
abstract final class AppFonts {
  static const text = 'Archivo';
  static const display = 'BarlowCondensed';

  /// Sporty numeric style for points, positions and stats.
  static TextStyle numbers({
    double size = 20,
    Color color = AppColors.textPrimary,
  }) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    letterSpacing: size >= 30 ? -0.3 : 0,
    height: 1.0,
    color: color,
  );
}

abstract final class AppTheme {
  /// Hero gradient used on headers and highlight cards (135°).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.heroStart, AppColors.heroEnd],
  );

  static const radius = 20.0;
  static const heroRadius = 24.0;
  static const controlRadius = 14.0;
  static const sheetRadius = 28.0;

  static const heroShadow = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 28,
    offset: Offset(0, 12),
    spreadRadius: -12,
  );
  static const ctaShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 22,
    offset: Offset(0, 10),
    spreadRadius: -10,
  );

  /// Solid ice-blue style for the main energy actions.
  static ButtonStyle energyButton({double height = 52, double fontSize = 16}) =>
      FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
        disabledForegroundColor: AppColors.onAccent.withValues(alpha: 0.6),
        minimumSize: Size.fromHeight(height),
        textStyle: TextStyle(
          fontFamily: AppFonts.text,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      );

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: Color(0xFF2B3512),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.accent,
      onTertiary: AppColors.onAccent,
      error: AppColors.error,
      onError: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.textSecondary,
      outlineVariant: AppColors.border,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.ink,
      scrim: AppColors.ink,
      shadow: Colors.black,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: AppFonts.text,
    );
    final text = base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: color, width: 2),
    );
    const buttonText = TextStyle(
      fontFamily: AppFonts.text,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.15,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary),
        errorBorder: inputBorder(AppColors.error.withValues(alpha: 0.6)),
        focusedErrorBorder: inputBorder(AppColors.error),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        prefixIconColor: AppColors.textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.6),
          minimumSize: const Size(48, 52),
          shape: control,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 52),
          shape: control,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 2,
          ),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 40),
          shape: control,
          textStyle: const TextStyle(
            fontFamily: AppFonts.text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppColors.ink.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sheetRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.ink.withValues(alpha: 0.6),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        dragHandleSize: const Size(40, 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: AppColors.surfaceHigh,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.textSecondary, width: 2),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.text,
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        iconColor: AppColors.textSecondary,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
