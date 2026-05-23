part of '../core.dart';

class PlatformUtils {
  PlatformUtils._();

  static bool _isTV = false;
  static bool _initialized = false;

  static bool get isTV => _isTV;
  static bool get isPhone => !_isTV;

  /// LG webOS / Samsung web (.wgt) — Flutter Web on TV browsers only.
  static bool get isWebTv => kIsWeb;

  /// Flutter Web served over http(s), e.g. `ares-launch -H` hosted mode.
  static bool get isWebTvHosted {
    if (!kIsWeb) return false;
    final scheme = Uri.base.scheme;
    return scheme == 'http' || scheme == 'https';
  }

  /// Native flutter-tizen (.tpk) — not Flutter Web on Tizen.
  static bool get isTizenNative => !kIsWeb && Platform.isLinux;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Web is used to target Smart TVs (Tizen, WebOS)
      _isTV = true;
    } else if (Platform.isAndroid) {
      try {
        const channel = MethodChannel(AppConstants.platformChannelName);
        final String? uiMode = await channel.invokeMethod<String>(
          AppConstants.getUiModeMethod,
        );
        _isTV = uiMode == AppConstants.tvModeString;
      } catch (e) {
        debugPrint('PlatformUtils initialization failed, falling back to phone mode: $e');
        _isTV = false;
      }
    } else if (Platform.isMacOS) {
      // macOS can be used as a proxy to test tvOS layout
      _isTV = true;
    } else if (Platform.isLinux) {
      // Linux covers flutter-tizen native builds (Tizen is Linux-based)
      _isTV = true;
    }

    _initialized = true;
  }
}
