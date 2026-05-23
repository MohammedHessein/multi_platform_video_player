import 'package:flutter/foundation.dart';

@immutable
class AppVideoPlayerValue {
  final Duration duration;
  final Duration position;
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final double aspectRatio;

  const AppVideoPlayerValue({
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.aspectRatio = 16 / 9,
  });

  static const AppVideoPlayerValue empty = AppVideoPlayerValue();

  @override
  bool operator ==(Object other) {
    if (other is! AppVideoPlayerValue) return false;
    return duration == other.duration &&
        position == other.position &&
        isInitialized == other.isInitialized &&
        isPlaying == other.isPlaying &&
        isBuffering == other.isBuffering &&
        aspectRatio == other.aspectRatio;
  }

  @override
  int get hashCode => Object.hash(
    duration,
    position,
    isInitialized,
    isPlaying,
    isBuffering,
    aspectRatio,
  );
}
