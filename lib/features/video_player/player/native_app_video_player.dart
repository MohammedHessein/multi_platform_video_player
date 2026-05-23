import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'app_video_player.dart';
import 'app_video_player_value.dart';

/// Wraps [video_player] for mobile, Android TV, and native Tizen builds.
class NativeAppVideoPlayer implements AppVideoPlayer {
  late VideoPlayerController _controller;
  bool _ownsController = true;

  NativeAppVideoPlayer({VideoPlayerController? controller}) {
    if (controller != null) {
      _controller = controller;
      _ownsController = false;
    }
  }

  VideoPlayerController get controller => _controller;

  @override
  AppVideoPlayerValue get value {
    final v = _controller.value;
    return AppVideoPlayerValue(
      duration: v.duration,
      position: v.position,
      isInitialized: v.isInitialized,
      isPlaying: v.isPlaying,
      isBuffering: v.isBuffering,
      aspectRatio: v.aspectRatio,
    );
  }

  @override
  Future<void> initialize({required String assetPath}) async {
    if (!_ownsController) {
      await _controller.initialize();
      return;
    }
    _controller = VideoPlayerController.asset(
      assetPath,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    await _controller.initialize();
  }

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> setLooping(bool looping) => _controller.setLooping(looping);

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _controller.setPlaybackSpeed(speed);
    } on PlatformException catch (error) {
      debugPrint('NativeAppVideoPlayer.setPlaybackSpeed: ${error.message}');
    }
  }

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
  }

  @override
  Widget buildView() => VideoPlayer(_controller);
}
