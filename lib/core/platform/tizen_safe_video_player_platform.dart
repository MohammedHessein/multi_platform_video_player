import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Wraps [VideoPlayerPlatform] to swallow Tizen TV / emulator gaps where native
/// media APIs return `Function not implemented` for playback speed and position.
class TizenSafeVideoPlayerPlatform extends VideoPlayerPlatform {
  TizenSafeVideoPlayerPlatform(this._delegate);

  final VideoPlayerPlatform _delegate;
  final Map<int, Duration> _lastPositionByTexture = <int, Duration>{};

  /// Call once after plugins register (e.g. from [main] on flutter-tizen).
  static void install() {
    final current = VideoPlayerPlatform.instance;
    if (current is TizenSafeVideoPlayerPlatform) {
      return;
    }
    VideoPlayerPlatform.instance = TizenSafeVideoPlayerPlatform(current);
  }

  static bool _isNotImplemented(PlatformException error) {
    final message = error.message?.toLowerCase() ?? '';
    final code = error.code.toLowerCase();
    return message.contains('function not implemented') ||
        code.contains('not implemented');
  }

  @override
  Future<void> init() => _delegate.init();

  @override
  Future<void> dispose(int textureId) {
    _lastPositionByTexture.remove(textureId);
    return _delegate.dispose(textureId);
  }

  @override
  Future<int?> create(DataSource dataSource) => _delegate.create(dataSource);

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) =>
      _delegate.createWithOptions(options);

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) =>
      _delegate.videoEventsFor(textureId);

  @override
  Future<void> setLooping(int textureId, bool looping) =>
      _delegate.setLooping(textureId, looping);

  @override
  Future<void> play(int textureId) => _delegate.play(textureId);

  @override
  Future<void> pause(int textureId) => _delegate.pause(textureId);

  @override
  Future<void> setVolume(int textureId, double volume) =>
      _delegate.setVolume(textureId, volume);

  @override
  Future<void> seekTo(int textureId, Duration position) async {
    _lastPositionByTexture[textureId] = position;
    await _delegate.seekTo(textureId, position);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    try {
      await _delegate.setPlaybackSpeed(textureId, speed);
    } on PlatformException catch (error) {
      if (_isNotImplemented(error)) {
        debugPrint(
          'TizenSafeVideoPlayerPlatform: setPlaybackSpeed ignored ($speed)',
        );
        return;
      }
      rethrow;
    }
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    try {
      final position = await _delegate.getPosition(textureId);
      _lastPositionByTexture[textureId] = position;
      return position;
    } on PlatformException catch (error) {
      if (_isNotImplemented(error)) {
        return _lastPositionByTexture[textureId] ?? Duration.zero;
      }
      rethrow;
    }
  }

  @override
  Widget buildView(int textureId) => _delegate.buildView(textureId);

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      _delegate.buildViewWithOptions(options);

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) =>
      _delegate.setMixWithOthers(mixWithOthers);

  @override
  Future<void> setWebOptions(int textureId, VideoPlayerWebOptions options) =>
      _delegate.setWebOptions(textureId, options);
}
