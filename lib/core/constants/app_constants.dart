part of '../core.dart';

class AppConstants {
  AppConstants._();

  static const String translationsPath = 'assets/translations';
  static const String platformChannelName =
      'com.mohammed.multi_platform_video_player/platform';
  static const String getUiModeMethod = 'getUiMode';
  static const String tvModeString = 'television';
  static const String videoAssetPath = 'assets/videos/sample.mp4';
  static const String sideLeft = 'left';
  static const String sideRight = 'right';
  static const Duration controlsAutoHideDuration = Duration(seconds: 3);
  static const Duration tvControlsAutoHideDuration = Duration(seconds: 6);
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration webTvControlsFadeDuration = Duration(milliseconds: 100);
  static const Duration seekDuration = Duration(seconds: 5);
  static const int positionThrottleMs = 250;
  static const int tvBufferingShowDelayMs = 400;
  static const int webPositionNotifyThrottleMs = 250;
  static const Duration webPositionFallbackInterval = Duration(milliseconds: 500);
  static const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 24.0;
  static const double spacingSmall = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 32.0;
  static const double spacingExtraLarge = 40.0;
  static const double phonePlayPauseIconSize = 64.0;
  static const double tvPrimaryButtonSize = 100.0;
  static const double tvSecondaryButtonSize = 80.0;
  static const double tvPrimaryIconSize = 56.0;
  static const double tvSecondaryIconSize = 42.0;
  static const double tvDesignWidth = 960.0;
  static const double tvDesignHeight = 540.0;
  static const double phoneDesignWidth = 360.0;
  static const double phoneDesignHeight = 690.0;
}
