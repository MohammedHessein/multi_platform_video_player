part of '../imports.dart';

/// Isolates the HTML5 video layer from frequent Bloc rebuilds on Smart TV web.
class WebVideoSurface extends StatefulWidget {
  final AppVideoPlayer player;

  const WebVideoSurface({super.key, required this.player});

  @override
  State<WebVideoSurface> createState() => _WebVideoSurfaceState();
}

class _WebVideoSurfaceState extends State<WebVideoSurface> {
  double _aspectRatio = 16 / 9;
  late final Widget _videoView;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.player.value.aspectRatio;
    _videoView = widget.player.buildView();
    widget.player.addListener(_onPlayerUpdate);
  }

  @override
  void dispose() {
    widget.player.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  void _onPlayerUpdate() {
    final ratio = widget.player.value.aspectRatio;
    if (ratio > 0 && ratio != _aspectRatio) {
      setState(() => _aspectRatio = ratio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: _videoView,
        ),
      ),
    );
  }
}
