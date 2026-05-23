part of '../imports.dart';

class VideoPlayerState extends Equatable {
  final bool isInitialized;
  final bool isPlaying;
  final bool isFullScreen;
  final bool showControls;
  final bool showStatusOverlay;
  /// Frozen while [showStatusOverlay] is true — which icon to flash (play vs pause).
  final bool? overlayShowsPlay;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final double playbackSpeed;
  final String? doubleTapSide;
  final String? errorMessage;

  const VideoPlayerState({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isFullScreen = false,
    this.showControls = true,
    this.showStatusOverlay = false,
    this.overlayShowsPlay,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.playbackSpeed = 1.0,
    this.doubleTapSide,
    this.errorMessage,
  });

  VideoPlayerState copyWith({
    bool? isInitialized,
    bool? isPlaying,
    bool? isFullScreen,
    bool? showControls,
    bool? showStatusOverlay,
    bool? overlayShowsPlay,
    bool clearOverlayShowsPlay = false,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    double? playbackSpeed,
    String? doubleTapSide,
    bool clearDoubleTapSide = false,
    String? errorMessage,
  }) {
    return VideoPlayerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      showControls: showControls ?? this.showControls,
      showStatusOverlay: showStatusOverlay ?? this.showStatusOverlay,
      overlayShowsPlay: clearOverlayShowsPlay
          ? null
          : (overlayShowsPlay ?? this.overlayShowsPlay),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      doubleTapSide: clearDoubleTapSide
          ? null
          : (doubleTapSide ?? this.doubleTapSide),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isInitialized,
    isPlaying,
    isFullScreen,
    showControls,
    showStatusOverlay,
    overlayShowsPlay,
    position,
    duration,
    isBuffering,
    playbackSpeed,
    doubleTapSide,
    errorMessage,
  ];
}
