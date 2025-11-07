package com.example.smart_bus_companion

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.smart_bus_companion/tflite"
    private var tfliteHandler: TFLiteHandler? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        tfliteHandler = TFLiteHandler(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val success = tfliteHandler?.loadModel() ?: false
                    result.success(success)
                }
                "detectEmotion" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    if (imageBytes != null) {
                        val res = tfliteHandler?.detectEmotion(imageBytes)
                        result.success(res)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image bytes required", null)
                    }
                }
                "dispose" -> {
                    tfliteHandler?.dispose()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}