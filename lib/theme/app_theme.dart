import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AtlasColors {
  AtlasColors._();

  // Backgrounds
  static const background = Color(0xFF0E0E12);
  static const surface = Color(0xFF17171D);
  static const surfaceContainer = Color(0xFF1E1E25);
  static const surfaceContainerHigh = Color(0xFF26262E);
  static const surfaceBright = Color(0xFF2F2F38);

  // Gold accent
  static const gold = Color(0xFFCFA44E);
  static const goldLight = Color(0xFFE6C97D);
  static const goldDark = Color(0xFF8A6E2F);
  static const goldSurface = Color(0xFF231E10);

  // Text
  static const textPrimary = Color(0xFFECECEE);
  static const textSecondary = Color(0xFF8E8E98);
  static const textTertiary = Color(0xFF5A5A64);

  // Borders
  static const border = Color(0xFF2A2A33);
  static const borderLight = Color(0xFF35353F);

  // Semantic
  static const success = Color(0xFF5ABD8C);
  static const successSurface = Color(0xFF13231A);
  static const error = Color(0xFFEF6B6B);
  static const errorSurface = Color(0xFF2B1515);
  static const warning = Color(0xFFE8A84C);
  static const warningSurface = Color(0xFF2B2213);
  static const info = Color(0xFF6BA3E8);
  static const infoSurface = Color(0xFF13202B);
}

class AtlasTheme {
  AtlasTheme._();

  static ThemeData get dark {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AtlasColors.background,

      colorScheme: const ColorScheme.dark(
        primary: AtlasColors.gold,
        onPrimary: Color(0xFF1A1507),
        primaryContainer: AtlasColors.goldSurface,
        onPrimaryContainer: AtlasColors.goldLight,
        secondary: Color(0xFF8B8FA3),
        onSecondary: AtlasColors.background,
        secondaryContainer: AtlasColors.surfaceContainerHigh,
        onSecondaryContainer: AtlasColors.textPrimary,
        surface: AtlasColors.surface,
        onSurface: AtlasColors.textPrimary,
        surfaceContainerLowest: AtlasColors.background,
        surfaceContainerLow: AtlasColors.surface,
        surfaceContainer: AtlasColors.surfaceContainer,
        surfaceContainerHigh: AtlasColors.surfaceContainerHigh,
        surfaceContainerHighest: AtlasColors.surfaceBright,
        onSurfaceVariant: AtlasColors.textSecondary,
        outline: AtlasColors.border,
        outlineVariant: AtlasColors.borderLight,
        error: AtlasColors.error,
        onError: Colors.white,
        errorContainer: AtlasColors.errorSurface,
        onErrorContainer: AtlasColors.error,
      ),

      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w200,
          letterSpacing: -1.5,
        ),
        headlineLarge: baseText.headlineLarge?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: baseText.titleSmall?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: AtlasColors.textPrimary,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: AtlasColors.textPrimary,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          color: AtlasColors.textSecondary,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: baseText.labelMedium?.copyWith(
          color: AtlasColors.textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: baseText.labelSmall?.copyWith(
          color: AtlasColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AtlasColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: AtlasColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AtlasColors.border, width: 0.5),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AtlasColors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: AtlasColors.goldSurface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AtlasColors.gold, size: 22);
          }
          return const IconThemeData(
              color: AtlasColors.textTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseText.labelSmall?.copyWith(
              color: AtlasColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return baseText.labelSmall?.copyWith(
            color: AtlasColors.textTertiary,
            fontSize: 11,
          );
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AtlasColors.gold,
        unselectedLabelColor: AtlasColors.textTertiary,
        indicatorColor: AtlasColors.gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AtlasColors.border,
        labelStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AtlasColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AtlasColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AtlasColors.gold, width: 1),
        ),
        hintStyle: baseText.bodyMedium?.copyWith(
          color: AtlasColors.textTertiary,
        ),
        labelStyle: baseText.bodyMedium?.copyWith(
          color: AtlasColors.textSecondary,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AtlasColors.gold;
          }
          return AtlasColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AtlasColors.goldSurface;
          }
          return AtlasColors.surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AtlasColors.goldDark;
          }
          return AtlasColors.border;
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AtlasColors.gold,
        foregroundColor: const Color(0xFF1A1507),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AtlasColors.gold),
          foregroundColor:
              WidgetStateProperty.all(const Color(0xFF1A1507)),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(
            baseText.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              WidgetStateProperty.all(AtlasColors.textPrimary),
          side: WidgetStateProperty.all(
            const BorderSide(color: AtlasColors.border),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AtlasColors.gold),
          textStyle: WidgetStateProperty.all(
            baseText.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AtlasColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
              color: AtlasColors.border, width: 0.5),
        ),
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: AtlasColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AtlasColors.surfaceContainerHigh,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: AtlasColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: AtlasColors.border,
        thickness: 0.5,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AtlasColors.surfaceContainer,
        side: const BorderSide(
            color: AtlasColors.border, width: 0.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        labelStyle: baseText.labelSmall?.copyWith(
          color: AtlasColors.textSecondary,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AtlasColors.gold,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AtlasColors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AtlasColors.border, width: 0.5),
          ),
        ),
      ),
    );
  }
}
