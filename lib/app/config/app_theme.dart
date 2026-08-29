import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_theme_extension.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Sistem Global Theme untuk Oasish Flutter M3 HRIS
/// Menyelaraskan seluruh komponen Material 3 dengan Google Stitch Design System ("Teal Oasis").
abstract class AppTheme {
  // =========================================================================
  // --- ☀️ LIGHT THEME CONFIGURATION ---
  // =========================================================================
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,

      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,

      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,

      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,

      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,

      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundSubtle,

      // Extensions
      extensions: const <ThemeExtension<dynamic>>[AppCustomColors.light],

      // Typography
      textTheme: _buildTextTheme(
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textMuted: AppColors.textMuted,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundSubtle,
        surfaceTintColor: AppColors.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg, // 16px
          side: const BorderSide(color: AppColors.outlineMuted, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons (Primary Action - Stadium / Pill)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary,
          ),
        ),
      ),

      // Outlined Buttons (Stadium / Pill)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandTeal,
          side: const BorderSide(color: AppColors.outlineMuted, width: 1),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Filled Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          textStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandTeal,
          textStyle: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),

      // TextFields / Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderInput, // 12px
          borderSide: const BorderSide(color: AppColors.outlineMuted, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.outlineMuted, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
      ),

      // Chips (Pill shape)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onPrimaryContainer,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        showDragHandle: true,
        dragHandleColor: AppColors.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // SnackBars (Floating)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.inverseOnSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderInput),
        elevation: 4,
      ),

      // Navigation Bar (Material 3 Bottom Navigation)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 2,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onPrimaryContainer);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.brandTeal,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.brandTeal,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.brandTeal,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineMuted,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),

      // Progress Indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandTeal,
        linearTrackColor: AppColors.primaryContainer,
        circularTrackColor: AppColors.primaryContainer,
      ),

      // Toggles (Checkbox, Radio, Switch)
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandTeal;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        side: const BorderSide(color: AppColors.outlineMuted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandTeal;
          return AppColors.outline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onPrimary;
          return AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandTeal;
          return AppColors.surfaceContainerHigh;
        }),
      ),
    );
  }

  // =========================================================================
  // --- 🌙 DARK THEME CONFIGURATION ---
  // =========================================================================
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,

      secondary: AppColors.secondaryFixedDim,
      onSecondary: AppColors.onSecondaryFixed,
      secondaryContainer: AppColors.onSecondaryFixedVariant,
      onSecondaryContainer: AppColors.secondaryFixed,

      tertiary: AppColors.tertiaryFixedDim,
      onTertiary: AppColors.onTertiaryFixed,
      tertiaryContainer: AppColors.onTertiaryFixedVariant,
      onTertiaryContainer: AppColors.tertiaryFixed,

      error: AppColors.errorRed,
      onError: AppColors.onError,
      errorContainer: AppColors.onErrorContainer,
      onErrorContainer: AppColors.errorContainer,

      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
      surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,

      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      inverseSurface: AppColors.surfaceBright,
      onInverseSurface: AppColors.onSurface,
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.darkPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackgroundSubtle,

      // Extensions
      extensions: const <ThemeExtension<dynamic>>[AppCustomColors.dark],

      // Typography
      textTheme: _buildTextTheme(
        textPrimary: AppColors.darkOnSurface,
        textSecondary: AppColors.darkOnSurfaceVariant,
        textMuted: AppColors.darkOutline,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackgroundSubtle,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.darkOnSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkOnSurface),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: AppColors.darkOutlineMuted, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkOnPrimary,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkOutlineMuted, width: 1),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Filled Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryContainer,
          foregroundColor: AppColors.darkOnPrimaryContainer,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          textStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          textStyle: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.darkOnSurface),
      ),

      // TextFields / Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkOutline,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkOnSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(
            color: AppColors.darkOutlineMuted,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(
            color: AppColors.darkOutlineMuted,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(
            color: AppColors.darkPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkPrimaryContainer,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkOnPrimaryContainer,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.darkOnSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkOnSurfaceVariant,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        showDragHandle: true,
        dragHandleColor: AppColors.darkOutline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // SnackBars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurfaceContainerHighest,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkOnSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderInput),
        elevation: 4,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceContainerLow,
        elevation: 2,
        indicatorColor: AppColors.darkPrimaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkPrimary,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.darkOnSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkOnPrimaryContainer);
          }
          return const IconThemeData(color: AppColors.darkOnSurfaceVariant);
        }),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.darkPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.darkPrimary,
        unselectedLabelColor: AppColors.darkOnSurfaceVariant,
        labelStyle: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.darkPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnSurface,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.darkOnSurfaceVariant,
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.darkOutlineMuted,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),

      // Progress Indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkPrimary,
        linearTrackColor: AppColors.darkPrimaryContainer,
        circularTrackColor: AppColors.darkPrimaryContainer,
      ),

      // Toggles
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkPrimary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        side: const BorderSide(color: AppColors.darkOutlineMuted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkPrimary;
          }
          return AppColors.darkOutline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkOnPrimary;
          }
          return AppColors.darkOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkPrimary;
          }
          return AppColors.darkSurfaceContainerHigh;
        }),
      ),
    );
  }

  // =========================================================================
  // --- 🔤 PRIVATE TEXT THEME BUILDER ---
  // =========================================================================
  static TextTheme _buildTextTheme({
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return TextTheme(
      headlineLarge: AppTypography.headlineLarge.copyWith(color: textPrimary),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: textPrimary),
      headlineSmall: AppTypography.headlineLargeMobile.copyWith(
        color: textPrimary,
      ),
      titleLarge: AppTypography.headlineMedium.copyWith(color: textPrimary),
      titleMedium: AppTypography.titleMedium.copyWith(color: textPrimary),
      titleSmall: AppTypography.titleSmall.copyWith(color: textPrimary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: textPrimary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: textSecondary),
      bodySmall: AppTypography.bodySmall.copyWith(color: textSecondary),
      labelLarge: AppTypography.titleSmall.copyWith(color: textPrimary),
      labelMedium: AppTypography.labelMedium.copyWith(color: textSecondary),
      labelSmall: AppTypography.labelSmall.copyWith(color: textMuted),
    );
  }
}
