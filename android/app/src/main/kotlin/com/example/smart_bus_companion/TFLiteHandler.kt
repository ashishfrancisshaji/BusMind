package com.example.smart_bus_companion

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import java.nio.ByteBuffer
import java.nio.ByteOrder

class TFLiteHandler(private val context: Context) {
    private var interpreter: Interpreter? = null
    private val emotions = arrayOf("happy", "sad", "angry", "tired", "focused", "neutral")
    
    fun loadModel(): Boolean {
        return try {
            val options = Interpreter.Options().apply {
                setNumThreads(4)
                setUseNNAPI(false)
            }
            
            val modelBuffer = FileUtil.loadMappedFile(context, "models/emotion_model.tflite")
            interpreter = Interpreter(modelBuffer, options)
            
            println("✅ Model loaded successfully")
            true
        } catch (e: Exception) {
            println("❌ Error loading model: ${e.message}")
            false
        }
    }
    
    fun detectEmotion(imageBytes: ByteArray): Map<String, Any> {
        if (interpreter == null) {
            return mapOf(
                "success" to false,
                "error" to "model_not_loaded"
            )
        }
        
        return try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: return mapOf("success" to false, "error" to "invalid_image")
            
            val resizedBitmap = Bitmap.createScaledBitmap(bitmap, 48, 48, true)
            val inputBuffer = preprocessImage(resizedBitmap)
            
            val output = Array(1) { FloatArray(emotions.size) }
            interpreter?.run(inputBuffer, output)
            
            val scores = output[0]
            val maxIndex = scores.indices.maxByOrNull { scores[it] } ?: 0
            
            mapOf(
                "success" to true,
                "dominant_emotion" to emotions[maxIndex],
                "confidence" to scores[maxIndex].toDouble(),
                "all_emotions" to emotions.mapIndexed { i, emotion ->
                    mapOf("label" to emotion, "score" to scores[i].toDouble())
                }
            )
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to "inference_failed",
                "message" to (e.message ?: "Unknown error")
            )
        }
    }
    
    private fun preprocessImage(bitmap: Bitmap): ByteBuffer {
        val inputBuffer = ByteBuffer.allocateDirect(4 * 48 * 48 * 1)
        inputBuffer.order(ByteOrder.nativeOrder())
        
        val pixels = IntArray(48 * 48)
        bitmap.getPixels(pixels, 0, 48, 0, 0, 48, 48)
        
        for (pixel in pixels) {
            val r = (pixel shr 16 and 0xFF)
            val g = (pixel shr 8 and 0xFF)
            val b = (pixel and 0xFF)
            val gray = (0.299 * r + 0.587 * g + 0.114 * b).toFloat()
            inputBuffer.putFloat(gray / 255.0f)
        }
        
        return inputBuffer
    }
    
    fun dispose() {
        interpreter?.close()
        interpreter = null
    }
}