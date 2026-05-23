// TV web target only — HTML5 video performs better than video_player on webOS.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'app_video_player.dart';
import 'app_video_player_value.dart';
import 'package:multi_platform_video_player/core/core.dart';

/// Direct HTML5 <video> playback for LG webOS / Samsung web TV browsers.
/// Works with ares hosted mode (http://) and packaged .ipk (file://).
class WebAppVideoPlayer implements AppVideoPlayer {
  late final html.VideoElement _video;
  late final String _viewType;

  /// Captured once at construction — avoids repeated evaluation of [Uri.base]
  /// which can shift on some webOS builds after the app bootstraps.
  final Uri _baseUri;

  final List<VoidCallback> _listeners = <VoidCallback>[];

  /// Persistent subscriptions wired in the constructor — cancelled in [dispose].
  late final List<StreamSubscription<html.Event>> _subs;

  Timer? _positionFallbackTimer;
  DateTime _lastPositionNotify = DateTime(0);
  AppVideoPlayerValue _value = AppVideoPlayerValue.empty;
  bool _disposed = false;

  WebAppVideoPlayer() : _baseUri = Uri.base {
    _viewType = 'tv-html-video-${DateTime.now().microsecondsSinceEpoch}';

    _video = html.VideoElement()
      ..controls = false
      ..autoplay = false
      ..loop = false // keep in sync with AppVideoPlayerValue default
      ..muted = true
      ..preload = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'fill'
      ..style.backgroundColor = '#000000'
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true');

    // Register once per unique viewType — the factory is intentionally
    // captured here so it always refers to the current (non-disposed) element.
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _video);

    // Store subscriptions so they can be cancelled on dispose.
    _subs = [
      _video.onLoadedMetadata.listen((_) => _syncFromElement()),
      _video.onPlaying.listen((_) => _syncFromElement(isPlaying: true)),
      _video.onPause.listen((_) => _syncFromElement(isPlaying: false)),
      _video.onEnded.listen((_) => _syncFromElement(isPlaying: false)),
      // Buffering state — webOS fires these reliably.
      _video.onWaiting.listen((_) => _syncFromElement(isBuffering: true)),
      _video.onCanPlay.listen((_) => _syncFromElement(isBuffering: false)),
      _video.onError.listen((_) => _syncFromElement()),
    ];
  }

  // ---------------------------------------------------------------------------
  // URL candidates
  // ---------------------------------------------------------------------------

  /// Candidate URLs for hosted (http/https) and packaged (file://) webOS builds.
  ///
  /// Uses [_baseUri] captured at construction time rather than [Uri.base] so
  /// the result is stable for the lifetime of this player instance.
  List<String> _assetUrlCandidates(String assetPath) {
    final relative = assetPath.replaceFirst(RegExp(r'^assets/'), '');
    final fileName =
    relative.contains('/') ? relative.split('/').last : relative;

    final isFileProtocol = _baseUri.scheme == 'file';

    if (isFileProtocol) {
      // Packaged TV app (.ipk / .wgt) – local media/ folder first.
      return [
        _baseUri.resolve('media/$fileName').toString(),
        _baseUri.resolve('assets/assets/$relative').toString(),
        _baseUri.resolve('assets/$relative').toString(),
        _baseUri.resolve(relative).toString(),
      ];
    } else {
      // Hosted (ares-launch -H) – media/ is copied next to index.html by run script.
      return [
        _baseUri.resolve('media/$fileName').toString(),
        _baseUri.resolve('assets/assets/$relative').toString(),
        _baseUri.resolve('assets/$relative').toString(),
        _baseUri.resolve(relative).toString(),
      ];
    }
  }

  // ---------------------------------------------------------------------------
  // AppVideoPlayer interface
  // ---------------------------------------------------------------------------

  @override
  AppVideoPlayerValue get value => _value;

  @override
  Future<void> initialize({required String assetPath}) async {
    final candidates = _assetUrlCandidates(assetPath);
    debugPrint('WebTV init (${_baseUri.scheme}): trying ${candidates.length} URLs');
    for (final url in candidates) {
      debugPrint('WebTV candidate: $url');
    }
    Object? lastError;
    final perUrlTimeout = _baseUri.scheme == 'file'
        ? const Duration(seconds: 3)
        : const Duration(seconds: 6);

    for (final url in candidates) {
      try {
        await _loadSource(url, timeout: perUrlTimeout);
        debugPrint('WebTV video loaded from: $url');
        return;
      } catch (e) {
        lastError = e;
        debugPrint('WebTV video failed ($url): $e');
      }
    }

    throw lastError ?? Exception('Could not load video from any candidate URL');
  }

  /// Loads [url] into the video element and waits for either `loadedmetadata`
  /// (success) or `error` (failure) — whichever arrives first.
  ///
  /// The [Completer] races both events so a 404 / network error rejects in
  /// milliseconds. Timeout is kept short (6 s) because webOS can silently
  /// stall without firing an error event, and we have fallback URLs to try.
  Future<void> _loadSource(
    String url, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    _positionFallbackTimer?.cancel();
    _video.pause();
    _video.removeAttribute('src');
    _video.load();

    final completer = Completer<void>();

    late final StreamSubscription<html.Event> metaSub;
    late final StreamSubscription<html.Event> errSub;

    void cleanUp() {
      metaSub.cancel();
      errSub.cancel();
    }

    metaSub = _video.onLoadedMetadata.listen((_) {
      if (!completer.isCompleted) completer.complete();
      cleanUp();
    });

    errSub = _video.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('video error for $url (code: ${_video.error?.code})'),
        );
      }
      cleanUp();
    });

    _video.src = url;
    _video.load();

    await completer.future.timeout(
      timeout,
      onTimeout: () {
        cleanUp();
        throw TimeoutException('metadata timeout for $url');
      },
    );

    if (!_video.duration.isFinite || _video.duration <= 0) {
      throw StateError('invalid duration for $url');
    }

    _syncFromElement();
    _startPositionFallback();
  }

  // ---------------------------------------------------------------------------
  // Playback controls
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async {
    await _video.play();
    _video.muted = false;
    _startPositionFallback();
    _syncFromElement();
  }

  @override
  Future<void> pause() async {
    _video.pause();
    _positionFallbackTimer?.cancel();
    _syncFromElement();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _video.currentTime = position.inMilliseconds / 1000.0;
    _syncFromElement();
  }

  @override
  Future<void> setLooping(bool looping) async {
    _video.loop = looping;
  }

  @override
  Future<void> setVolume(double volume) async {
    _video.muted = volume <= 0;
    _video.volume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _video.playbackRate = speed;
  }

  // ---------------------------------------------------------------------------
  // Listener management
  // ---------------------------------------------------------------------------

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  // ---------------------------------------------------------------------------
  // Widget
  // ---------------------------------------------------------------------------

  @override
  Widget buildView() => HtmlElementView(viewType: _viewType);

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    if (_disposed) return; // guard against double-dispose
    _disposed = true;

    _positionFallbackTimer?.cancel();

    // Cancel all persistent DOM event subscriptions to avoid memory leaks.
    for (final sub in _subs) {
      sub.cancel();
    }

    _video.pause();
    _video.removeAttribute('src');
    _video.load();
    _listeners.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _startPositionFallback() {
    _positionFallbackTimer?.cancel();
    _positionFallbackTimer = Timer.periodic(
      AppConstants.webPositionFallbackInterval,
      (_) {
        if (!_video.paused && !_disposed) {
          _syncFromElement();
        }
      },
    );
  }

  void _syncFromElement({bool? isPlaying, bool? isBuffering}) {
    if (_disposed) return;

    final durationMs =
        (_video.duration.isFinite ? _video.duration : 0) * 1000;
    final positionMs =
        (_video.currentTime.isFinite ? _video.currentTime : 0) * 1000;
    final width = _video.videoWidth;
    final height = _video.videoHeight;

    final next = AppVideoPlayerValue(
      duration: Duration(milliseconds: durationMs.round()),
      position: Duration(milliseconds: positionMs.round()),
      isInitialized: durationMs > 0,
      isPlaying: isPlaying ?? (!_video.paused && !_video.ended),
      // Carry forward the previous buffering state when not explicitly set,
      // so an unrelated sync call doesn't silently clear a buffering flag.
      isBuffering: isBuffering ?? _value.isBuffering,
      aspectRatio: width > 0 && height > 0 ? width / height : 16 / 9,
    );

    if (next == _value) return;

    final positionOnly = next.position != _value.position &&
        next.isPlaying == _value.isPlaying &&
        next.isBuffering == _value.isBuffering &&
        next.duration == _value.duration &&
        next.isInitialized == _value.isInitialized;

    if (positionOnly) {
      final now = DateTime.now();
      if (now.difference(_lastPositionNotify).inMilliseconds <
          AppConstants.webPositionNotifyThrottleMs) {
        _value = next;
        return;
      }
      _lastPositionNotify = now;
    }

    _value = next;
    _notifyListeners();
  }

  void _notifyListeners() {
    // Iterate over a copy so listeners can safely remove themselves during the call.
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}