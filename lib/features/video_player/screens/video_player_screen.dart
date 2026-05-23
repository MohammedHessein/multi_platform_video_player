part of '../imports.dart';

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideoPlayerCubit()..initialize(),
      child: (!kIsWeb && Platform.isAndroid)
          ? const SafeArea(
              top: false,
              child: Scaffold(
                backgroundColor: AppColors.background,
                body: VideoView(),
              ),
            )
          : const Scaffold(
              backgroundColor: AppColors.background,
              body: VideoView(),
            ),
    );
  }
}
