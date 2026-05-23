package com.mohammed.multi_platform_video_player

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mohammed.multi_platform_video_player/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getUiMode") {
                    val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                    val mode = uiModeManager.currentModeType
                    if (mode == Configuration.UI_MODE_TYPE_TELEVISION) {
                        result.success("television")
                    } else {
                        result.success("normal")
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
