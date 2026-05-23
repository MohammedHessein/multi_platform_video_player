part of '../imports.dart';

/// Web TV layout: video layer never rebuilds; overlays use narrow [BlocSelector]s.
class WebTvVideoLayout extends StatelessWidget {
  final VideoPlayerCubit cubit;

  const WebTvVideoLayout({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          cubit.showControls();
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: cubit.toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            WebVideoSurface(player: cubit.player),
            RepaintBoundary(
              child: BlocSelector<VideoPlayerCubit, VideoPlayerState, bool?>(
                selector: (state) => state.overlayShowsPlay,
                builder: (context, showsPlayIcon) {
                  return StatusOverlay(showsPlayIcon: showsPlayIcon);
                },
              ),
            ),
            BlocSelector<VideoPlayerCubit, VideoPlayerState, _TvControlsSelectorData>(
              selector: (state) => _TvControlsSelectorData(
                showControls: state.showControls,
                isPlaying: state.isPlaying,
                playbackSpeed: state.playbackSpeed,
              ),
              builder: (context, data) {
                return RepaintBoundary(
                  child: AnimatedOpacity(
                    opacity: data.showControls ? 1.0 : 0.0,
                    duration: AppConstants.webTvControlsFadeDuration,
                    child: IgnorePointer(
                      ignoring: !data.showControls,
                      child: TvControls(
                        isPlaying: data.isPlaying,
                        playbackSpeed: data.playbackSpeed,
                        onTogglePlayPause: cubit.togglePlayPause,
                        onSeekForward: cubit.seekForward,
                        onSeekBackward: cubit.seekBackward,
                        onSpeedChanged: cubit.setPlaybackSpeed,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _TvControlsSelectorData {
  final bool showControls;
  final bool isPlaying;
  final double playbackSpeed;

  const _TvControlsSelectorData({
    required this.showControls,
    required this.isPlaying,
    required this.playbackSpeed,
  });

  @override
  bool operator ==(Object other) =>
      other is _TvControlsSelectorData &&
      showControls == other.showControls &&
      isPlaying == other.isPlaying &&
      playbackSpeed == other.playbackSpeed;

  @override
  int get hashCode => Object.hash(showControls, isPlaying, playbackSpeed);
}
