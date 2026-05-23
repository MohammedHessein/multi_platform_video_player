import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_platform_video_player/core/core.dart';
import 'package:multi_platform_video_player/features/video_player/imports.dart';

class MultiPlatformVideoPlayerApp extends StatelessWidget {
  const MultiPlatformVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: PlatformUtils.isTV
          ? const Size(AppConstants.tvDesignWidth, AppConstants.tvDesignHeight)
          : const Size(
              AppConstants.phoneDesignWidth,
              AppConstants.phoneDesignHeight,
            ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: PlatformUtils.isTV ? AppTheme.tvTheme : AppTheme.darkTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: const VideoPlayerScreen(),
        );
      },
    );
  }
}
