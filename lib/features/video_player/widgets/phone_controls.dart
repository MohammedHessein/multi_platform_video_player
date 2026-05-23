part of '../imports.dart';

class PhoneControls extends StatelessWidget {
  final bool isPlaying;
  final bool isFullScreen;
  final double playbackSpeed;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onToggleFullScreen;
  final ValueChanged<double> onSpeedChanged;

  const PhoneControls({
    super.key,
    required this.isPlaying,
    required this.isFullScreen,
    required this.playbackSpeed,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onToggleFullScreen,
    required this.onSpeedChanged,
  });

  void _showSpeedSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SpeedSelectorBottomSheet(
        currentSpeed: playbackSpeed,
        onSpeedChanged: onSpeedChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            AppColors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: topPadding + 10.h,
            left: AppConstants.horizontalPadding.w,
            right: AppConstants.horizontalPadding.w,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.videoTitle,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: Icon(
                    Icons.speed,
                    color: AppColors.white,
                    size: 24.r,
                  ),
                  onPressed: () => _showSpeedSelector(context),
                ),
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: Icon(
                    isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: AppColors.white,
                    size: 26.r,
                  ),
                  onPressed: onToggleFullScreen,
                ),
              ],
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 48.r,
                  color: AppColors.white,
                  icon: const Icon(Icons.replay_5),
                  onPressed: onSeekBackward,
                ),
                SizedBox(width: AppConstants.spacingLarge.w),
                PlayPauseButton(
                  isPlaying: isPlaying,
                  onTap: onTogglePlayPause,
                ),
                SizedBox(width: AppConstants.spacingLarge.w),
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 48.r,
                  color: AppColors.white,
                  icon: const Icon(Icons.forward_5),
                  onPressed: onSeekForward,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: AppConstants.verticalPadding.h,
            left: AppConstants.horizontalPadding.w,
            right: AppConstants.horizontalPadding.w,
            child: BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
              buildWhen: (previous, current) =>
                  previous.position != current.position ||
                  previous.duration != current.duration,
              builder: (context, state) {
                return PhoneSeekBar(
                  position: state.position,
                  duration: state.duration,
                  onSeek: onSeek,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
