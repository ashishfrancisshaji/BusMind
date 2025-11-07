import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'opencv_emotion_service.dart';
import '../secrets/api_keys.dart';
/// ML Service with dual mode: Custom TFLite model + Hugging Face API fallback
class MLService {
  // Hugging Face API token (fallback only)
  static const String _hfToken = ApiKeys.huggingFaceToken;
  static const String _emotionModel = 'trpakov/vit-face-expression';
  
  // Toggle between custom model and API
  // TEMPORARY: Set to false until tflite_flutter is fixed
  static bool useCustomModel = false;  // Change to true when TFLite works
  
  static bool _useOfflineMode = false;
  static int _apiCallsToday = 0;
  static const int _maxApiCallsPerDay = 100;
  static DateTime? _lastApiCallDate;

  /// Main entry point: Detect emotion from camera image
  static Future<Map<String, dynamic>> detectEmotion(XFile imageFile) async {
    if (useCustomModel) {
      debugPrint('🎯 Using custom trained model');
      // Use YOUR custom-trained model
      final initialized = await OpenCVEmotionService.initialize();
      if (!initialized) {
        debugPrint('⚠️ Custom model failed, falling back to API');
        // Fallback to API if model fails
        useCustomModel = false;
        return detectEmotion(imageFile);
      }
      return await OpenCVEmotionService.detectEmotion(imageFile);
    } else {
      debugPrint('🌐 Using Hugging Face API');
      // Use API as fallback
      try {
        final bytes = await imageFile.readAsBytes();
        
        if (bytes.length < 100) {
          return {
            'success': false,
            'error': 'image_too_small',
            'message': 'Image file is too small',
          };
        }
        
        if (bytes.length > 10 * 1024 * 1024) {
          return {
            'success': false,
            'error': 'image_too_large',
            'message': 'Image file is too large (max 10MB)',
          };
        }
        
        return await detectEmotionFromBytes(bytes);
      } catch (e, stackTrace) {
        debugPrint('❌ Error reading image file: $e');
        return {
          'success': false,
          'error': 'file_read_error',
          'message': 'Failed to read image: $e',
        };
      }
    }
  }

  /// Detect emotion from image bytes (API mode)
  static Future<Map<String, dynamic>> detectEmotionFromBytes(
    Uint8List bytes
  ) async {
    _checkAndResetDailyCounter();
    
    if (_shouldUseOfflineMode()) {
      debugPrint('🔴 Using offline mode');
      return _offlineEmotionDetection(bytes);
    }

    try {
      debugPrint('🌐 Attempting API call...');
      final result = await _callHuggingFaceAPI(bytes);
      
      if (result['success'] == true) {
        _apiCallsToday++;
        debugPrint('✅ API call successful! Calls today: $_apiCallsToday/$_maxApiCallsPerDay');
        return result;
      } else {
        debugPrint('⚠️ API call failed: ${result['error']}');
        return _offlineEmotionDetection(bytes);
      }
    } catch (e, stackTrace) {
      debugPrint('💥 Exception calling API: $e');
      _useOfflineMode = true;
      return _offlineEmotionDetection(bytes);
    }
  }

  /// Call Hugging Face Inference API
  static Future<Map<String, dynamic>> _callHuggingFaceAPI(
    Uint8List imageBytes
  ) async {
    final url = Uri.parse(
      'https://api-inference.huggingface.co/models/$_emotionModel'
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/octet-stream',
        },
        body: imageBytes,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return _parseSuccessResponse(response.body);
      } else if (response.statusCode == 503) {
        return {
          'success': false,
          'error': 'model_loading',
          'message': 'Model is warming up. Please try again in 20 seconds.',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'invalid_token',
          'message': 'Invalid API token',
        };
      } else {
        return {
          'success': false,
          'error': 'api_error',
          'message': 'API returned status ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'network_error',
        'message': 'Network error: $e',
      };
    }
  }

  /// Parse API response
  static Map<String, dynamic> _parseSuccessResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      
      if (decoded is List && decoded.isNotEmpty) {
        final results = List<Map<String, dynamic>>.from(decoded);
        results.sort((a, b) => 
          (b['score'] as num).compareTo(a['score'] as num)
        );
        
        final topEmotion = results.first;
        
        return {
          'success': true,
          'dominant_emotion': _normalizeEmotionLabel(topEmotion['label']),
          'confidence': topEmotion['score'],
          'raw_emotion': topEmotion['label'],
          'all_emotions': results.map((e) => {
            'label': _normalizeEmotionLabel(e['label']),
            'raw_label': e['label'],
            'score': e['score'],
          }).toList(),
          'api_used': true,
        };
      }
      
      return {
        'success': false,
        'error': 'invalid_format',
        'message': 'Invalid response format',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'parse_error',
        'message': 'Failed to parse response: $e',
      };
    }
  }

  /// Normalize emotion labels
  static String _normalizeEmotionLabel(String label) {
    final normalized = label.toLowerCase().trim();
    
    if (normalized.contains('joy') || normalized.contains('happy')) {
      return 'happy';
    } else if (normalized.contains('sad')) {
      return 'sad';
    } else if (normalized.contains('ang') || normalized.contains('mad')) {
      return 'stressed';
    } else if (normalized.contains('fear') || normalized.contains('anx')) {
      return 'stressed';
    } else if (normalized.contains('neutral') || normalized.contains('calm')) {
      return 'focused';
    } else if (normalized.contains('surprise')) {
      return 'focused';
    } else if (normalized.contains('tire') || normalized.contains('bore')) {
      return 'tired';
    } else if (normalized.contains('relax')) {
      return 'relaxed';
    }
    
    return 'unknown';
  }

  static bool _shouldUseOfflineMode() {
    return _hfToken.isEmpty || 
           _useOfflineMode || 
           _apiCallsToday >= _maxApiCallsPerDay;
  }

  static void _checkAndResetDailyCounter() {
    final now = DateTime.now();
    if (_lastApiCallDate == null || 
        _lastApiCallDate!.day != now.day) {
      _apiCallsToday = 0;
      _lastApiCallDate = now;
    }
  }

  /// Offline fallback
  static Map<String, dynamic> _offlineEmotionDetection(Uint8List bytes) {
    int sum = 0;
    int sampleSize = bytes.length > 2000 ? 2000 : bytes.length;
    
    for (int i = 0; i < sampleSize; i++) {
      sum += bytes[i];
    }
    
    double avgBrightness = sum / sampleSize;
    
    String emotion;
    double confidence;
    
    if (avgBrightness > 180) {
      emotion = 'happy';
      confidence = 0.65;
    } else if (avgBrightness > 140) {
      emotion = 'focused';
      confidence = 0.70;
    } else if (avgBrightness < 80) {
      emotion = 'tired';
      confidence = 0.60;
    } else {
      emotion = 'focused';
      confidence = 0.58;
    }

    return {
      'success': true,
      'dominant_emotion': emotion,
      'confidence': confidence,
      'offline_mode': true,
      'note': 'Using basic offline detection',
    };
  }

  /// Test API connection
  static Future<Map<String, dynamic>> testAPIConnection() async {
    debugPrint('🧪 Testing API connection...');
    
    if (!isAPIConfigured) {
      return {
        'success': false,
        'message': 'No API token configured',
      };
    }
    
    try {
      final url = Uri.parse('https://api-inference.huggingface.co/models/$_emotionModel');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_hfToken'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 503) {
        return {
          'success': true,
          'message': response.statusCode == 503 
            ? 'API reachable but model needs warming up'
            : 'API ready to use',
          'status_code': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid API token',
          'status_code': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Unexpected response: ${response.statusCode}',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: $e',
      };
    }
  }

  /// Posture detection - placeholder
  static Future<Map<String, dynamic>> detectPosture(XFile imageFile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'success': true,
      'posture_status': 'good',
      'score': 0.75,
      'note': 'Using device sensors in PostureProvider',
      'recommendation': 'Check posture screen for real-time monitoring',
    };
  }

  /// Get study recommendations based on detected emotion
  static Map<String, dynamic> getMoodRecommendations(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return {
          'music_genre': 'upbeat',
          'activities': [
            'Great energy! Tackle challenging topics',
            'Try active recall with flashcards',
          ],
          'study_tip': 'Perfect time for hard problems',
          'focus_level': 'high',
        };
        
      case 'sad':
        return {
          'music_genre': 'calming',
          'activities': [
            'Take it easy - review familiar material',
            'Listen to calming background music',
          ],
          'study_tip': 'Light review sessions work best',
          'focus_level': 'low',
        };
        
      case 'stressed':
        return {
          'music_genre': 'relaxing',
          'activities': [
            'Take deep breaths first',
            'Start with easier topics',
            'Break tasks into small chunks',
          ],
          'study_tip': 'Short 10-minute study bursts',
          'focus_level': 'medium',
        };
        
      case 'focused':
      case 'neutral':
        return {
          'music_genre': 'focus',
          'activities': [
            'Perfect for deep learning',
            'Use the Pomodoro technique',
            'Try active recall methods',
          ],
          'study_tip': 'Ideal for flashcard practice',
          'focus_level': 'high',
        };
        
      case 'tired':
        return {
          'music_genre': 'energizing',
          'activities': [
            'Light review only',
            'Listen to lecture summaries',
            'Consider a short break',
          ],
          'study_tip': 'Passive learning mode',
          'focus_level': 'low',
        };
        
      case 'relaxed':
        return {
          'music_genre': 'ambient',
          'activities': [
            'Good for reading and note-taking',
            'Try mind-mapping concepts',
          ],
          'study_tip': 'Great for organizing thoughts',
          'focus_level': 'medium',
        };
        
      default:
        return {
          'music_genre': 'ambient',
          'activities': [
            'Check your mood with the detector',
            'Find a comfortable position',
          ],
          'study_tip': 'Get settled and start',
          'focus_level': 'unknown',
        };
    }
  }

  /// Manual controls
  static void enableOfflineMode() => _useOfflineMode = true;
  static void disableOfflineMode() => _useOfflineMode = false;
  
  static bool get isAPIConfigured => _hfToken.isNotEmpty;
  
  static String get currentMode {
    if (useCustomModel) return 'Custom Model (52.7% accuracy)';
    if (!isAPIConfigured) return 'No API token';
    if (_useOfflineMode) return 'Offline mode';
    if (_apiCallsToday >= _maxApiCallsPerDay) return 'Daily limit reached';
    return 'API ($_apiCallsToday/$_maxApiCallsPerDay calls)';
  }
}