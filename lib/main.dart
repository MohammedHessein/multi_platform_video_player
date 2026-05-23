import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_platform_video_player/app.dart';
import 'package:multi_platform_video_player/core/core.dart';
import 'package:multi_platform_video_player/core/platform/tizen_safe_video_player_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isLinux) {
    TizenSafeVideoPlayerPlatform.install();
  }
  await EasyLocalization.ensureInitialized();
  await PlatformUtils.initialize();

  if (PlatformUtils.isTV) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: AppConstants.translationsPath,
      fallbackLocale: const Locale('en'),
      child: const MultiPlatformVideoPlayerApp(),
    ),
  );
}
