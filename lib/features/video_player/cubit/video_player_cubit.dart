part of '../imports.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerState>
    with WidgetsBindingObserver {
  late AppVideoPlayer _player;
  Timer? _controlsTimer;
  Timer? _statusOverlayTimer;
  Timer? _bufferingDebounceTimer;
  int _overlayGeneration = 0;
  DateTime _lastNotifierEmit = DateTime(0);
  bool _playerReady = false;
  bool _webNotifiersDisposed = false;

  /// True while the user is interacting with a menu, speed selector, etc.
  /// Controls auto-hide is paused until [endInteraction] is called.
  bool _isUserInteracting = false;

  /// Throttle gate for native position emissions (avoids Android TV stutter).
  DateTime _lastPositionEmit = DateTime(0);

  /// Seek bar position and duration updates driven by ValueNotifier to completely
  /// bypass Bloc state rebuilds across both Web TV and Native Android TV platforms.
  final ValueNotifier<Duration> playbackPosition =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> playbackDuration =
      ValueNotifier<Duration>(Duration.zero);

  AppVideoPlayer get player => _player;

  VideoPlayerCubit({AppVideoPlayer? mockPlayer})
    : super(const VideoPlayerState()) {
    WidgetsBinding.instance.addObserver(this);
    if (mockPlayer != null) {
      _player = mockPlayer;
      _playerReady = true;
    }
  }

  void _showStatusOverlay({
    required bool showPlayIcon,
    bool? isPlaying,
  }) {
    _statusOverlayTimer?.cancel();
    final generation = ++_overlayGeneration;
    emit(
      state.copyWith(
        showStatusOverlay: true,
        overlayShowsPlay: showPlayIcon,
        isPlaying: isPlaying ?? state.isPlaying,
      ),
    );
    _statusOverlayTimer = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed && generation == _overlayGeneration) {
        emit(
          state.copyWith(
            showStatusOverlay: false,
            clearOverlayShowsPlay: true,
          ),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_player.value.isPlaying) {
        _player.pause();
        emit(this.state.copyWith(isPlaying: false));
      }
    }
  }

  Future<void> initialize() async {
    try {
      if (!_playerReady) {
        _player = createAppVideoPlayer();
        _playerReady = true;
      }

      await _player.initialize(assetPath: AppConstants.videoAssetPath);
      await _player.setLooping(true);

      try {
        if (PlatformUtils.isWebTv) {
          await _player.setVolume(0.0);
        }
        await _player.play();
      } catch (e) {
        debugPrint('Autoplay blocked or failed: $e');
      }

      final duration = _player.value.duration;
      playbackDuration.value = duration;
      playbackPosition.value = Duration.zero;

      emit(
        state.copyWith(
          isInitialized: true,
          isPlaying: _player.value.isPlaying,
          duration: duration,
        ),
      );

      _player.addListener(_videoListener);

      _startControlsTimer();
    } catch (e) {
      debugPrint('Video initialize failed: $e');
      emit(
        state.copyWith(
          isInitialized: true,
          errorMessage: AppStrings.errorLoadingVideo,
        ),
      );
    }
  }

  void _videoListener() {
    if (isClosed) return;

    final value = _player.value;

    // Synchronize ValueNotifiers for seekbar rendering on all TV platforms
    final pos = value.position;
    final dur = value.duration;
    if (playbackPosition.value != pos) {
      var skipPositionNotify = false;
      if (PlatformUtils.isWebTv) {
        final now = DateTime.now();
        if (now.difference(_lastNotifierEmit).inMilliseconds <
            AppConstants.webPositionNotifyThrottleMs) {
          skipPositionNotify = true;
        } else {
          _lastNotifierEmit = now;
        }
      }
      if (!skipPositionNotify) {
        playbackPosition.value = pos;
      }
    }
    if (dur > Duration.zero && playbackDuration.value != dur) {
      playbackDuration.value = dur;
    }

    // TV: position via ValueNotifiers only; sync play/buffer for controls.
    if (PlatformUtils.isTV) {
      _syncTvPlaybackState();
      return;
    }

    // Only emit for meaningful state changes — throttle position to avoid
    // the excessive Bloc rebuilds that cause Android TV stuttering.
    final stateChanged = state.isBuffering != value.isBuffering ||
        state.isPlaying != value.isPlaying;

    final now = DateTime.now();
    final positionDue = now.difference(_lastPositionEmit).inMilliseconds >=
        AppConstants.positionThrottleMs;

    if (stateChanged || positionDue) {
      _lastPositionEmit = now;
      emit(
        state.copyWith(
          isBuffering: value.isBuffering,
          isPlaying: value.isPlaying,
          position: value.position,
        ),
      );
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (_isUserInteracting) return;

    final duration = PlatformUtils.isTV
        ? AppConstants.tvControlsAutoHideDuration
        : AppConstants.controlsAutoHideDuration;

    _controlsTimer = Timer(duration, () {
      if (!isClosed && !_isUserInteracting) {
        emit(state.copyWith(showControls: false));
      }
    });
  }

  void showControls() {
    if (!state.showControls) {
      emit(state.copyWith(showControls: true));
    }
    if (!_isUserInteracting) {
      _startControlsTimer();
    }
  }

  /// Call when the user opens a menu / speed-selector / dialog.
  /// Controls will stay visible until [endInteraction] is called.
  void beginInteraction() {
    _isUserInteracting = true;
    _controlsTimer?.cancel();
    if (!state.showControls) {
      emit(state.copyWith(showControls: true));
    }
  }

  /// Call when the user closes a menu / speed-selector / dialog.
  void endInteraction() {
    _isUserInteracting = false;
    _startControlsTimer();
  }

  void toggleControls() {
    final show = !state.showControls;
    emit(state.copyWith(showControls: show));
    if (show) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void togglePlayPause() {
    showControls();
    final willPlay = !_player.value.isPlaying;
    if (willPlay) {
      _player.play();
    } else {
      _player.pause();
    }
    _showStatusOverlay(showPlayIcon: willPlay, isPlaying: willPlay);
  }

  void seekTo(Duration position) {
    showControls();
    _player.seekTo(position);
    playbackPosition.value = position;
    if (!PlatformUtils.isWebTv) {
      emit(state.copyWith(position: position));
    }
  }

  void onDoubleTapSeek(bool isForward) {
    _showStatusOverlay(showPlayIcon: state.isPlaying);
    emit(
      state.copyWith(
        doubleTapSide: isForward
            ? AppConstants.sideRight
            : AppConstants.sideLeft,
      ),
    );
    Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        emit(state.copyWith(clearDoubleTapSide: true));
      }
    });
    if (isForward) {
      seekForward();
    } else {
      seekBackward();
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (PlatformUtils.isTizenNative && speed != 1.0) {
      debugPrint('Playback speed changes are not supported on native Tizen.');
      return;
    }
    try {
      await _player.setPlaybackSpeed(speed);
      emit(state.copyWith(playbackSpeed: speed));
    } catch (e) {
      debugPrint('setPlaybackSpeed failed: $e');
    }
  }

  void seekForward() {
    showControls();
    final newPosition = _player.value.position + AppConstants.seekDuration;
    seekTo(newPosition > state.duration ? state.duration : newPosition);
  }

  void seekBackward() {
    showControls();
    final newPosition = _player.value.position - AppConstants.seekDuration;
    seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void _syncTvPlaybackState() {
    final value = _player.value;
    if (state.isPlaying != value.isPlaying) {
      emit(state.copyWith(isPlaying: value.isPlaying));
    }
    _syncTvBuffering(value.isBuffering);
  }

  /// Debounce buffering spinner on TV — reduces brief "quality flicker" flashes.
  void _syncTvBuffering(bool isBuffering) {
    if (isBuffering) {
      if (state.isBuffering) return;
      _bufferingDebounceTimer?.cancel();
      _bufferingDebounceTimer = Timer(
        const Duration(milliseconds: AppConstants.tvBufferingShowDelayMs),
        () {
          if (isClosed) return;
          if (_player.value.isBuffering) {
            emit(state.copyWith(isBuffering: true));
          }
        },
      );
    } else {
      _bufferingDebounceTimer?.cancel();
      if (state.isBuffering) {
        emit(state.copyWith(isBuffering: false));
      }
    }
  }

  void toggleFullScreen() {
    final isFullScreen = !state.isFullScreen;
    emit(state.copyWith(isFullScreen: isFullScreen));

    if (isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      if (PlatformUtils.isTV) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    _statusOverlayTimer?.cancel();
    _bufferingDebounceTimer?.cancel();
    if (_playerReady) {
      _player.removeListener(_videoListener);
      _player.dispose();
    }
    if (!_webNotifiersDisposed) {
      playbackPosition.dispose();
      playbackDuration.dispose();
      _webNotifiersDisposed = true;
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return super.close();
  }
}
