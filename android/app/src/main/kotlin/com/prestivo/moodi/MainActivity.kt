package com.prestivo.moodi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.prestivo.moodi/notifications"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeNotifications" -> {
                    try {
                        Log.d("MainActivity", "Notification service initialization requested")
                        result.success("Notification service ready")
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error initializing notifications: ${e.message}")
                        result.error("INIT_ERROR", "Failed to initialize notifications", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
