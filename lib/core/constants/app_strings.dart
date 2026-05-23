part of '../core.dart';

class AppStrings {
  AppStrings._();

  static String get appTitle => 'appTitle'.tr();
  static String get play => 'play'.tr();
  static String get pause => 'pause'.tr();
  static String get forward => 'forward'.tr();
  static String get rewind => 'rewind'.tr();
  static String get errorLoadingVideo => 'errorLoadingVideo'.tr();
  static String get loadingVideo => 'loadingVideo'.tr();
  static String get seekDuration => 'seekDuration'.tr();
  static String get playbackSpeed => 'playbackSpeed'.tr();
  static String get videoTitle => 'videoTitle'.tr();
  static String get exitAppTitle => 'exitAppTitle'.tr();
  static String get exitAppMessage => 'exitAppMessage'.tr();
  static String get yes => 'yes'.tr();
  static String get no => 'no'.tr();
  static String get exitHostedWebOsHint => 'exitHostedWebOsHint'.tr();
  static String speed(double speed) => 'speed'.tr(args: [speed.toString()]);
}
