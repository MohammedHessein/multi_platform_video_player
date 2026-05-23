import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_platform_video_player/features/video_player/imports.dart';

void main() {
  testWidgets('PhoneSeekBar displays formatted position and duration', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => const PhoneSeekBar(
              position: Duration(minutes: 1, seconds: 30),
              duration: Duration(minutes: 5),
            ),
          ),
        ),
      ),
    );

    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });
}
