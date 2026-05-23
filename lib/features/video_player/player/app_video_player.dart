import 'package:flutter/widgets.dart';

import 'app_video_player_value.dart';

/// Platform-agnostic video playback API used by [VideoPlayerCubit].
abstract class AppVideoPlayer {
  AppVideoPlayerValue get value;

  Future<void> initialize({required String assetPath});

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Future<void> setLooping(bool looping);

  Future<void> setVolume(double volume);

  Future<void> setPlaybackSpeed(double speed);

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);

  void dispose();

  /// Renders the video surface (HtmlElementView on web, VideoPlayer elsewhere).
  Widget buildView();
}
