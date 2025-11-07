import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/ml_service.dart';
import '../services/opencv_emotion_service.dart'; // Added this import
import 'dart:math';

enum MoodState {
  happy,
  sad,
  tired,
  stressed,
  focused,
  relaxed,
  unknown,
}

class MoodDetectionProvider extends ChangeNotifier {
  CameraController? _cameraController;
  bool _isDetecting = false;
  MoodState _currentMood = MoodState.unknown;
  double _confidence = 0.0;
  List<CameraDescription> _cameras = [];
  String _moodDescription = '';
  List<String> _recommendations = [];
  String _errorMessage = '';
  bool _isInitializing = false;
  int _detectionAttempts = 0;
  DateTime? _lastDetectionTime;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isDetecting => _isDetecting;
  MoodState get currentMood => _currentMood;
  double get confidence => _confidence;
  String get moodDescription => _moodDescription;
  List<String> get recommendations => _recommendations;
  String get errorMessage => _errorMessage;
  bool get isInitializing => _isInitializing;
  bool get isCameraReady => _cameraController?.value.isInitialized ?? false;

  // Constructor - initialize model when provider is created
  MoodDetectionProvider() {
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    final success = await OpenCVEmotionService.initialize();
    if (!success) {
      _errorMessage = 'Failed to load emotion model';
      notifyListeners();
    }
  }

  Future<void> initializeCamera() async {
    if (_isInitializing) {
      debugPrint('⏳ Camera initialization already in progress');
      return;
    }

    _isInitializing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('📷 Starting camera initialization...');
      _cameras = await availableCameras();
      debugPrint('✅ Found ${_cameras.length} cameras');
      
      if (_cameras.isEmpty) {
        debugPrint('❌ No cameras available on device');
        _errorMessage = 'No cameras found on device';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Find front camera for mood detection
      CameraDescription? frontCamera;
      try {
        frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        debugPrint('✅ Found front camera: ${frontCamera.name}');
      } catch (e) {
        debugPrint('⚠️ No front camera found, using first available');
        frontCamera = _cameras.first;
      }
      
      debugPrint('📸 Initializing camera controller...');
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Changed to medium for better quality
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // JPEG is more compatible
      );
      
      await _cameraController!.initialize();
      debugPrint('✅ Camera initialized successfully');
      
      _isInitializing = false;
      _errorMessage = '';
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing camera: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Camera initialization failed: $e';
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> startMoodDetection() async {
    if (_isDetecting) {
      debugPrint('⏳ Detection already in progress');
      return;
    }

    // Check if camera is ready
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('📷 Camera not ready, initializing...');
      await initializeCamera();
    }

    // Double-check after initialization attempt
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('❌ Camera still not initialized');
      _errorMessage = 'Camera not available. Please check permissions.';
      notifyListeners();
      return;
    }

    _isDetecting = true;
    _errorMessage = '';
    _detectionAttempts++;
    notifyListeners();

    debugPrint('🎬 Starting mood detection (attempt #$_detectionAttempts)');

    // Perform detection
    await detectMood();
    
    _isDetecting = false;
    _lastDetectionTime = DateTime.now();
    notifyListeners();
  }

  Future<void> detectMood() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('❌ Camera not initialized');
      _errorMessage = 'Camera not ready';
      _simulateMoodDetection();
      return;
    }

    try {
      debugPrint('📸 Taking picture...');
      final image = await _cameraController!.takePicture();
      debugPrint('✅ Picture captured: ${image.path}');
      debugPrint('📏 Image size: ${await image.length()} bytes');
      
      debugPrint('🤖 Sending to ML Service...');
      final result = await MLService.detectEmotion(image);
      
      debugPrint('📊 ML Result received');
      debugPrint('   Success: ${result['success']}');
      debugPrint('   Error: ${result['error']}');
      debugPrint('   Emotion: ${result['dominant_emotion']}');
      debugPrint('   Confidence: ${result['confidence']}');
      debugPrint('   Offline: ${result['offline_mode']}');
      
      if (result['success']) {
        final emotion = result['dominant_emotion'];
        _currentMood = _mapEmotionToMood(emotion);
        _confidence = result['confidence'] ?? 0.5;
        
        // Show mode info
        if (result['offline_mode'] == true) {
          debugPrint('⚠️ Using offline detection');
          _errorMessage = result['note'] ?? 'Using offline mode';
        } else if (result['api_used'] == true) {
          debugPrint('✅ API detection successful');
          debugPrint('   Raw emotion: ${result['raw_emotion']}');
          debugPrint('   Mapped to: $_currentMood');
          _errorMessage = '';
        }
        
        _updateMoodDescription();
        _generateRecommendations();
        
        debugPrint('🎯 Final mood: $_currentMood (${(_confidence * 100).toInt()}%)');
        
        // 🎵 AUTO-UPDATE MUSIC BASED ON DETECTED EMOTION
        //_updateMusic(emotion);
      } else {
        debugPrint('❌ Detection failed: ${result['error']}');
        final error = result['error'];
        
        // Handle specific errors with user-friendly messages
        if (error == 'model_loading') {
          debugPrint('⏳ Model is loading, will retry...');
          _errorMessage = 'AI model is warming up. Trying again in 5 seconds...';
          notifyListeners();
          
          await Future.delayed(const Duration(seconds: 5));
          
          // Retry detection
          if (_isDetecting) {
            debugPrint('🔄 Retrying detection...');
            return detectMood();
          }
        } else if (error == 'invalid_token') {
          debugPrint('🔑 Invalid API token');
          _errorMessage = 'API token invalid. Using offline mode.';
          MLService.enableOfflineMode();
        } else if (error == 'network_error') {
          debugPrint('🌐 Network error');
          _errorMessage = 'Network error. Using offline mode.';
        } else {
          _errorMessage = result['message'] ?? 'Detection failed';
        }
        
        debugPrint('🔄 Falling back to simulated detection');
        _simulateMoodDetection();
      }
    } catch (e, stackTrace) {
      debugPrint('💥 Exception in detectMood: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Error: $e';
      _simulateMoodDetection();
    }
  }

  void _simulateMoodDetection() {
    debugPrint('🎲 Using simulated mood detection');
    final random = Random();
    final moods = [
      MoodState.happy,
      MoodState.focused,
      MoodState.relaxed,
      MoodState.tired,
    ];
    
    _currentMood = moods[random.nextInt(moods.length)];
    _confidence = 0.5 + (random.nextDouble() * 0.3); // 0.5 to 0.8
    
    debugPrint('🎭 Simulated mood: $_currentMood (${(_confidence * 100).toInt()}%)');
    
    _updateMoodDescription();
    _generateRecommendations();
    notifyListeners();
  }

  MoodState _mapEmotionToMood(String emotion) {
    final normalized = emotion.toLowerCase();
    
    switch (normalized) {
      case 'happy':
      case 'joy':
        return MoodState.happy;
      case 'sad':
      case 'sadness':
        return MoodState.sad;
      case 'angry':
      case 'anger':
      case 'stressed':
        return MoodState.stressed;
      case 'fear':
      case 'anxiety':
        return MoodState.stressed;
      case 'neutral':
      case 'focused':
        return MoodState.focused;
      case 'surprise':
        return MoodState.focused;
      case 'tired':
        return MoodState.tired;
      case 'relaxed':
        return MoodState.relaxed;
      default:
        debugPrint('⚠️ Unknown emotion: $emotion, defaulting to focused');
        return MoodState.focused;
    }
  }

  void _updateMoodDescription() {
    switch (_currentMood) {
      case MoodState.happy:
        _moodDescription = 'You seem cheerful and energetic!';
        break;
      case MoodState.sad:
        _moodDescription = 'You appear to be feeling down.';
        break;
      case MoodState.tired:
        _moodDescription = 'You look tired and could use some rest.';
        break;
      case MoodState.stressed:
        _moodDescription = 'You seem stressed or anxious.';
        break;
      case MoodState.focused:
        _moodDescription = 'You appear focused and ready to learn.';
        break;
      case MoodState.relaxed:
        _moodDescription = 'You look calm and relaxed.';
        break;
      case MoodState.unknown:
        _moodDescription = 'Unable to detect your current mood.';
        break;
    }
  }

  void _generateRecommendations() {
    switch (_currentMood) {
      case MoodState.happy:
        _recommendations = [
          'Great time for upbeat music!',
          'Perfect mood for challenging flashcards',
          'Consider sharing your positive energy',
        ];
        break;
      case MoodState.sad:
        _recommendations = [
          'Try some calming music',
          'Light review of familiar topics',
          'Practice some breathing exercises',
        ];
        break;
      case MoodState.tired:
        _recommendations = [
          'Listen to energizing music',
          'Take short breaks between study sessions',
          'Check your posture - sit up straight',
        ];
        break;
      case MoodState.stressed:
        _recommendations = [
          'Try relaxing ambient sounds',
          'Start with easier flashcards',
          'Practice mindfulness exercises',
        ];
        break;
      case MoodState.focused:
        _recommendations = [
          'Perfect time for intensive studying',
          'Try challenging flashcards',
          'Listen to focus-enhancing music',
        ];
        break;
      case MoodState.relaxed:
        _recommendations = [
          'Good time for passive learning',
          'Listen to educational podcasts',
          'Review previous study materials',
        ];
        break;
      case MoodState.unknown:
        _recommendations = [
          'Try the mood detection again',
          'Ensure good lighting',
          'Look directly at the camera',
        ];
        break;
    }
  }

  Color getMoodColor() {
    switch (_currentMood) {
      case MoodState.happy:
        return Colors.yellow.shade600;
      case MoodState.sad:
        return Colors.blue.shade600;
      case MoodState.tired:
        return Colors.grey.shade600;
      case MoodState.stressed:
        return Colors.red.shade600;
      case MoodState.focused:
        return Colors.green.shade600;
      case MoodState.relaxed:
        return Colors.purple.shade600;
      case MoodState.unknown:
        return Colors.grey.shade400;
    }
  }

  IconData getMoodIcon() {
    switch (_currentMood) {
      case MoodState.happy:
        return Icons.sentiment_very_satisfied;
      case MoodState.sad:
        return Icons.sentiment_very_dissatisfied;
      case MoodState.tired:
        return Icons.bedtime;
      case MoodState.stressed:
        return Icons.sentiment_dissatisfied;
      case MoodState.focused:
        return Icons.psychology;
      case MoodState.relaxed:
        return Icons.self_improvement;
      case MoodState.unknown:
        return Icons.help_outline;
    }
  }

  // Reset state
  void reset() {
    _currentMood = MoodState.unknown;
    _confidence = 0.0;
    _moodDescription = '';
    _recommendations = [];
    _errorMessage = '';
    _detectionAttempts = 0;
    notifyListeners();
  }

  // Get stats
  String getLastDetectionTime() {
    if (_lastDetectionTime == null) return 'Never';
    
    final now = DateTime.now();
    final diff = now.difference(_lastDetectionTime!);
    
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing MoodDetectionProvider');
    _cameraController?.dispose();
    super.dispose();
  }
}