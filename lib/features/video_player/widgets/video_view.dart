part of '../imports.dart';

class VideoView extends StatelessWidget {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (previous, current) {
        return previous.copyWith(
              position: current.position,
              duration: current.duration,
            ) !=
            current;
      },
      builder: (context, state) {
        if (!state.isInitialized) {
          return Container(
            color: AppColors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.loadingVideo,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.errorMessage != null) {
          return Center(
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final cubit = context.read<VideoPlayerCubit>();

        if (PlatformUtils.isWebTv) {
          return WebTvVideoLayout(cubit: cubit);
        }

        final screenWidth = MediaQuery.sizeOf(context).width;

        return Focus(
          onKeyEvent: (node, event) {
            cubit.showControls();
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: cubit.toggleControls,
            onDoubleTapDown: (details) {
              if (PlatformUtils.isTV) return;
              final isForward = details.globalPosition.dx > screenWidth / 2;
              cubit.onDoubleTapSeek(isForward);
            },
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Center(
                  child: RepaintBoundary(
                    child: AspectRatio(
                      aspectRatio: cubit.player.value.aspectRatio,
                      child: cubit.player.buildView(),
                    ),
                  ),
                ),
                if (state.doubleTapSide != null)
                  DoubleTapFeedback(side: state.doubleTapSide!),
                if (state.isBuffering)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                RepaintBoundary(
                  child: StatusOverlay(showsPlayIcon: state.overlayShowsPlay),
                ),
                if (PlatformUtils.isTV)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedOpacity(
                        opacity: state.showControls ? 1.0 : 0.0,
                        duration: AppConstants.animationDurationMedium,
                        child: IgnorePointer(
                          ignoring: !state.showControls,
                          child: TvControls(
                            isPlaying: state.isPlaying,
                            playbackSpeed: state.playbackSpeed,
                            onTogglePlayPause: cubit.togglePlayPause,
                            onSeekForward: cubit.seekForward,
                            onSeekBackward: cubit.seekBackward,
                            onSpeedChanged: cubit.setPlaybackSpeed,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedOpacity(
                        opacity: state.showControls ? 1.0 : 0.0,
                        duration: AppConstants.animationDurationMedium,
                        child: IgnorePointer(
                          ignoring: !state.showControls,
                          child: PhoneControls(
                            isPlaying: state.isPlaying,
                            isFullScreen: state.isFullScreen,
                            playbackSpeed: state.playbackSpeed,
                            onTogglePlayPause: cubit.togglePlayPause,
                            onSeek: cubit.seekTo,
                            onSeekForward: cubit.seekForward,
                            onSeekBackward: cubit.seekBackward,
                            onToggleFullScreen: cubit.toggleFullScreen,
                            onSpeedChanged: cubit.setPlaybackSpeed,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
