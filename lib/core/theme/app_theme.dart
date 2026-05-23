part of '../core.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      iconTheme: const IconThemeData(color: AppColors.onSurface),
      useMaterial3: true,
    );
  }

  static ThemeData get tvTheme {
    return darkTheme.copyWith(
      visualDensity: VisualDensity.standard,
      focusColor: AppColors.primary.withOpacity(0.12),
    );
  }
}
