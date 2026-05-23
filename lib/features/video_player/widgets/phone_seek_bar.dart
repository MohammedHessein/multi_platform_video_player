part of '../imports.dart';

class PhoneSeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;

  const PhoneSeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.onSurfaceVariant.withOpacity(0.3),
            thumbColor: AppColors.primary,
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble().clamp(
              0,
              duration.inMilliseconds.toDouble(),
            ),
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              if (onSeek != null) {
                onSeek!(Duration(milliseconds: value.toInt()));
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position.format(),
                style: TextStyle(color: AppColors.white, fontSize: 12.sp),
              ),
              Text(
                duration.format(),
                style: TextStyle(color: AppColors.white, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
