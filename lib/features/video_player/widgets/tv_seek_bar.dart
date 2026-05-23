part of '../imports.dart';

class TvSeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const TvSeekBar({
    super.key,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds;
    final progress = maxMs > 0
        ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4.h,
            backgroundColor: AppColors.onSurfaceVariant.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position.format(),
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(color: AppColors.white, fontSize: 12.sp),
              ),
              Text(
                duration.format(),
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(color: AppColors.white, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
