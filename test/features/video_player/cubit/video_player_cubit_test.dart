import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_platform_video_player/features/video_player/imports.dart';
import 'package:multi_platform_video_player/features/video_player/player/app_video_player.dart';
import 'package:multi_platform_video_player/features/video_player/player/app_video_player_value.dart';

class MockAppVideoPlayer extends Mock implements AppVideoPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerCubit videoPlayerCubit;
  late MockAppVideoPlayer mockPlayer;

  const initializedValue = AppVideoPlayerValue(
    duration: Duration(seconds: 100),
    isInitialized: true,
    isPlaying: true,
    aspectRatio: 16 / 9,
  );

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const AppVideoPlayerValue());
  });

  setUp(() {
    mockPlayer = MockAppVideoPlayer();

    when(() => mockPlayer.initialize(assetPath: any(named: 'assetPath')))
        .thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {
      when(() => mockPlayer.value).thenReturn(initializedValue);
    });
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.seekTo(any())).thenAnswer((_) async {});
    when(() => mockPlayer.setLooping(any())).thenAnswer((_) async {});
    when(() => mockPlayer.setPlaybackSpeed(any())).thenAnswer((_) async {});
    when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenReturn(null);
    when(() => mockPlayer.addListener(any())).thenReturn(null);
    when(() => mockPlayer.removeListener(any())).thenReturn(null);
    when(() => mockPlayer.buildView()).thenReturn(const SizedBox());

    when(() => mockPlayer.value).thenReturn(
      const AppVideoPlayerValue(
        duration: Duration(seconds: 100),
        isInitialized: true,
      ),
    );

    videoPlayerCubit = VideoPlayerCubit(mockPlayer: mockPlayer);
  });

  tearDown(() {
    videoPlayerCubit.close();
  });

  group('VideoPlayerCubit', () {
    test('initial state is correct', () {
      expect(videoPlayerCubit.state, const VideoPlayerState());
    });

    blocTest<VideoPlayerCubit, VideoPlayerState>(
      'initialize emits correct state and starts playback',
      build: () => videoPlayerCubit,
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const VideoPlayerState(
          isInitialized: true,
          isPlaying: true,
          duration: Duration(seconds: 100),
        ),
      ],
    );

    blocTest<VideoPlayerCubit, VideoPlayerState>(
      'togglePlayPause pauses when playing',
      build: () => videoPlayerCubit,
      seed: () => const VideoPlayerState(isPlaying: true, showControls: true),
      act: (cubit) {
        when(() => mockPlayer.value).thenReturn(initializedValue);
        cubit.togglePlayPause();
      },
      expect: () => [
        const VideoPlayerState(
          isPlaying: false,
          showControls: true,
          showStatusOverlay: true,
          overlayShowsPlay: false,
        ),
      ],
    );

    blocTest<VideoPlayerCubit, VideoPlayerState>(
      'setPlaybackSpeed updates state and controller',
      build: () => videoPlayerCubit,
      act: (cubit) => cubit.setPlaybackSpeed(1.5),
      expect: () => [
        const VideoPlayerState(playbackSpeed: 1.5),
      ],
    );

    blocTest<VideoPlayerCubit, VideoPlayerState>(
      'toggleFullScreen updates state',
      build: () => videoPlayerCubit,
      act: (cubit) => cubit.toggleFullScreen(),
      expect: () => [
        const VideoPlayerState(isFullScreen: true),
      ],
    );

    blocTest<VideoPlayerCubit, VideoPlayerState>(
      'seekTo updates state and controller',
      build: () => videoPlayerCubit,
      act: (cubit) => cubit.seekTo(const Duration(seconds: 10)),
      expect: () => [
        const VideoPlayerState(position: Duration(seconds: 10)),
      ],
    );
  });
}
