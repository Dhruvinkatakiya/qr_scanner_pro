package com.devamjyot.qr_scanner

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes the launch "action" (from app shortcuts or
 * the home-screen widget) to Dart via a MethodChannel so the app can deep-link
 * to the scanner or the QR generator on startup.
 */
class MainActivity : FlutterActivity() {
    private val channel = "qr_scanner_pro/intent"
    private var launchAction: String? = null

    companion object {
        const val ACTION_SCAN = "com.qrscannerpro.action.SCAN"
        const val ACTION_CREATE = "com.qrscannerpro.action.CREATE"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchAction = resolveAction(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchAction" -> {
                        result.success(launchAction)
                        launchAction = null // consume once
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        launchAction = resolveAction(intent)
    }

    private fun resolveAction(intent: Intent?): String? = when (intent?.action) {
        ACTION_SCAN -> "scan"
        ACTION_CREATE -> "create"
        else -> null
    }
}
