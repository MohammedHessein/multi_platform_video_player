part of '../imports.dart';

/// Brief center-screen play/pause flash.
class StatusOverlay extends StatelessWidget {
  final bool? showsPlayIcon;

  const StatusOverlay({
    super.key,
    required this.showsPlayIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (showsPlayIcon == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: Icon(
          showsPlayIcon!
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
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
    );
  }
}
