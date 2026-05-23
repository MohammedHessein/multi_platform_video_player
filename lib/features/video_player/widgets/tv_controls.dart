part of '../imports.dart';

class TvControls extends StatelessWidget {
  final bool isPlaying;
  final double playbackSpeed;
  final bool showStatusOverlay;
  final bool? overlayShowsPlay;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final ValueChanged<double> onSpeedChanged;

  const TvControls({
    super.key,
    required this.isPlaying,
    required this.playbackSpeed,
    this.showStatusOverlay = false,
    this.overlayShowsPlay,
    required this.onTogglePlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTogglePlayPause,
            behavior: HitTestBehavior.opaque,
            child: Container(
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
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),
        ),
        if (showStatusOverlay && overlayShowsPlay != null)
          IgnorePointer(
            child: Center(
              child: Icon(
                overlayShowsPlay!
                    ? Icons.play_arrow
                    : Icons.pause,
                size: 100.r,
                color: AppColors.white.withOpacity(0.9),
                shadows: const [
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        // Top Bar
        Positioned(
          top: 20.h,
          left: AppConstants.horizontalPadding.w,
          right: AppConstants.horizontalPadding.w,
          child: Row(
            children: [
              Text(
                AppStrings.videoTitle,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: AppConstants.verticalPadding.h,
          left: AppConstants.horizontalPadding.w,
          right: AppConstants.horizontalPadding.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeFocus(
                child: TvSeekBarListenable(
                  positionListenable: context.read<VideoPlayerCubit>().playbackPosition,
                  durationListenable: context.read<VideoPlayerCubit>().playbackDuration,
                ),
              ),
              SizedBox(height: AppConstants.spacingMedium.h),
              Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
                  SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousFocusIntent(),
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TvFocusButton(
                      icon: Icons.replay_5,
                      onTap: onSeekBackward,
                      label: AppStrings.rewind,
                    ),
                    SizedBox(width: AppConstants.spacingLarge.w),
                    TvFocusButton(
                      autofocus: true,
                      icon: isPlaying ? Icons.pause : Icons.play_arrow,
                      onTap: onTogglePlayPause,
                      size: AppConstants.tvPrimaryButtonSize,
                      iconSize: AppConstants.tvPrimaryIconSize,
                      label: isPlaying ? AppStrings.pause : AppStrings.play,
                    ),
                    SizedBox(width: AppConstants.spacingLarge.w),
                    TvFocusButton(
                      icon: Icons.forward_5,
                      onTap: onSeekForward,
                      label: AppStrings.forward,
                    ),
                    if (!PlatformUtils.isTizenNative) ...[
                      SizedBox(width: AppConstants.spacingLarge.w),
                      TvFocusButton(
                        icon: Icons.speed,
                        onTap: () {
                          final cubit = context.read<VideoPlayerCubit>();
                          cubit.beginInteraction();
                          final currentIndex =
                              AppConstants.playbackSpeeds.indexOf(
                            playbackSpeed,
                          );
                          final nextIndex =
                              (currentIndex + 1) %
                              AppConstants.playbackSpeeds.length;
                          onSpeedChanged(
                            AppConstants.playbackSpeeds[nextIndex],
                          );
                          // Auto-resume auto-hide timer after a short delay of inactivity
                          Future.delayed(const Duration(seconds: 2), () {
                            if (!cubit.isClosed) {
                              cubit.endInteraction();
                            }
                          });
                        },
                        label: AppStrings.speed(playbackSpeed),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
