part of '../imports.dart';

/// Read-only progress bar for Flutter Web on Smart TVs (webOS / Tizen web).
/// Avoids Material [Slider] ghosting on CanvasKit when position updates frequently.
/// Seek bar driven by [ValueNotifier] — rebuilds only this widget on web TV.
class TvSeekBarListenable extends StatelessWidget {
  final ValueNotifier<Duration> positionListenable;
  final ValueNotifier<Duration> durationListenable;

  const TvSeekBarListenable({
    super.key,
    required this.positionListenable,
    required this.durationListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: positionListenable,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: durationListenable,
          builder: (context, duration, __) {
            return TvSeekBar(position: position, duration: duration);
          },
        );
      },
    );
  }
}
