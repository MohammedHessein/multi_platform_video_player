part of '../imports.dart';

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: AppConstants.phonePlayPauseIconSize.r,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        color: AppColors.primary,
      ),
    );
  }
}
