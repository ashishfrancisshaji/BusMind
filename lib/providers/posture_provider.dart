import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math';
import '../services/ml_service.dart';

enum PostureState {
  good,
  slouching,
  leaningForward,
  leaningBack,
  tiltedLeft,
  tiltedRight,
  unknown,
}

class PostureData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  final PostureState state;

  PostureData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
    required this.state,
  });
}

class PostureProvider extends ChangeNotifier {
  PostureState _currentPosture = PostureState.unknown;
  // double _postureScore = 0.0; // Unused field
  bool _isMonitoring = false;
  bool _isCameraInitialized = false;
  CameraController? _cameraController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  // DateTime? _lastAlertTime; // Unused field
  final List<String> _postureHistory = [];
  Timer? _postureCheckTimer;
  
  // Missing variables
  int _alertCount = 0;
  double _goodPosturePercentage = 0.0;
  Duration _monitoringDuration = Duration.zero;
  DateTime? _monitoringStartTime;
  DateTime? _lastAlert;
  
  // Calibration values
  // final double _baselineX = 0.0; // Unused field
  // final double _baselineY = 0.0; // Unused field
  // final double _baselineZ = 9.8; // Unused field
  
  // Sensor data
  double _accelerometerX = 0.0;
  double _accelerometerY = 0.0;
  double _accelerometerZ = 0.0;
  // double _gyroscopeX = 0.0; // Unused field
  // double _gyroscopeY = 0.0; // Unused field
  // double _gyroscopeZ = 0.0; // Unused field
  
  // Settings
  double _sensitivityThreshold = 0.3;
  Duration _alertInterval = const Duration(minutes: 5);
  bool _vibrateOnAlert = true;
  bool _soundOnAlert = false;

  // Getters
  bool get isMonitoring => _isMonitoring;
  PostureState get currentPosture => _currentPosture;
  List<String> get postureHistory => _postureHistory;
  int get alertCount => _alertCount;
  double get goodPosturePercentage => _goodPosturePercentage;
  Duration get monitoringDuration => _monitoringDuration;
  double get sensitivityThreshold => _sensitivityThreshold;
  Duration get alertInterval => _alertInterval;
  bool get vibrateOnAlert => _vibrateOnAlert;
  bool get soundOnAlert => _soundOnAlert;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringStartTime = DateTime.now();
    _alertCount = 0;
    _postureHistory.clear();
    
    // Initialize camera for visual posture detection
    if (!_isCameraInitialized) {
      await initializeCamera();
    }
    
    // Start accelerometer monitoring
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      _accelerometerX = event.x;
      _accelerometerY = event.y;
      _accelerometerZ = event.z;
      _analyzePosture();
    });
    
    // Start gyroscope monitoring
    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      // _gyroscopeX = event.x; // Removed unused field
      // _gyroscopeY = event.y; // Removed unused field
      // _gyroscopeZ = event.z; // Removed unused field
    });
    
    // Start periodic camera-based posture checks
    _postureCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performCameraPostureCheck();
    });
    
    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _postureCheckTimer?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _postureCheckTimer = null;
    
    if (_monitoringStartTime != null) {
      _monitoringDuration = DateTime.now().difference(_monitoringStartTime!);
    }
    
    notifyListeners();
  }

  void _analyzePosture() {
    final PostureState newPosture = _detectPostureFromSensors();
    
    if (newPosture != _currentPosture) {
      _currentPosture = newPosture;
      
      // final postureData = PostureData(
      //   x: _accelerometerX,
      //   y: _accelerometerY,
      //   z: _accelerometerZ,
      //   timestamp: DateTime.now(),
      //   state: newPosture,
      // ); // Unused variable
      
      _postureHistory.add('${DateTime.now().toIso8601String()}: ${getPostureDescription()}');
      if (_postureHistory.length > 50) {
        _postureHistory.removeAt(0);
      }
      
      _updateStatistics();
      _checkForAlert();
      notifyListeners();
    }
  }

  PostureState _detectPostureFromSensors() {
    // Normalize accelerometer values
    final magnitude = sqrt(_accelerometerX * _accelerometerX + 
                          _accelerometerY * _accelerometerY + 
                          _accelerometerZ * _accelerometerZ);
    
    if (magnitude == 0) return PostureState.unknown;
    
    final normalizedX = _accelerometerX / magnitude;
    final normalizedY = _accelerometerY / magnitude;
    final normalizedZ = _accelerometerZ / magnitude;
    
    // Detect posture based on device orientation
    // These thresholds would need calibration in a real app
    if (normalizedZ.abs() > 0.8) {
      // Device is mostly flat - good posture
      return PostureState.good;
    } else if (normalizedY > _sensitivityThreshold) {
      // Device tilted forward - user leaning forward
      return PostureState.leaningForward;
    } else if (normalizedY < -_sensitivityThreshold) {
      // Device tilted back - user leaning back
      return PostureState.leaningBack;
    } else if (normalizedX > _sensitivityThreshold) {
      // Device tilted right - user tilted right
      return PostureState.tiltedRight;
    } else if (normalizedX < -_sensitivityThreshold) {
      // Device tilted left - user tilted left
      return PostureState.tiltedLeft;
    } else {
      // Default poor posture detection
      return PostureState.slouching;
    }
  }

  void _updateStatistics() {
    if (_postureHistory.isEmpty) return;
    
    final goodPostureCount = _postureHistory
        .where((data) => data.split(':')[1].trim().toLowerCase().contains('good'))
        .length;
    
    _goodPosturePercentage = goodPostureCount / _postureHistory.length;
    
    if (_monitoringStartTime != null) {
      _monitoringDuration = DateTime.now().difference(_monitoringStartTime!);
    }
  }

  void _checkForAlert() {
    if (_currentPosture == PostureState.good) return;
    
    final now = DateTime.now();
    if (_lastAlert == null || now.difference(_lastAlert!) >= _alertInterval) {
      _triggerAlert();
      _lastAlert = now;
      _alertCount++;
    }
  }

  Future<void> _triggerAlert() async {
    if (_vibrateOnAlert) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 500);
      }
    }
    
    // In a real app, you might also play a sound here
    if (_soundOnAlert) {
      // Play alert sound
    }
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use front camera for posture detection
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        _isCameraInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _performCameraPostureCheck() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    
    try {
      final image = await _cameraController!.takePicture();
      final result = await MLService.detectPosture(image);
      
      if (result['success']) {
        final postureStatus = result['posture_status'] as String;
        final score = result['score'] as double;
        
        // _postureScore = score; // Removed unused field
        _currentPosture = _mapPostureStatusToState(postureStatus);
        
        // Add to history
        _postureHistory.add('${DateTime.now().toIso8601String()}: $postureStatus (${(score * 100).toInt()}%)');
        if (_postureHistory.length > 50) {
          _postureHistory.removeAt(0);
        }
        
        // Check if alert is needed
        if (score < 0.6 && _shouldShowAlert()) {
          _triggerPostureAlert();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Camera posture check error: $e');
    }
  }

  PostureState _mapPostureStatusToState(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
      case 'good':
        return PostureState.good;
      case 'fair':
        return PostureState.slouching;
      case 'poor':
        return PostureState.leaningForward;
      default:
        return PostureState.unknown;
    }
  }

  void setSensitivity(double sensitivity) {
    _sensitivityThreshold = sensitivity.clamp(0.1, 1.0);
    notifyListeners();
  }

  void setAlertInterval(Duration interval) {
    _alertInterval = interval;
    notifyListeners();
  }

  void setVibrateOnAlert(bool vibrate) {
    _vibrateOnAlert = vibrate;
    notifyListeners();
  }

  void setSoundOnAlert(bool sound) {
    _soundOnAlert = sound;
    notifyListeners();
  }

  String getPostureDescription() {
    switch (_currentPosture) {
      case PostureState.good:
        return 'Great posture! Keep it up!';
      case PostureState.slouching:
        return 'You\'re slouching. Sit up straight!';
      case PostureState.leaningForward:
        return 'You\'re leaning forward. Sit back!';
      case PostureState.leaningBack:
        return 'You\'re leaning back. Sit up!';
      case PostureState.tiltedLeft:
        return 'You\'re tilted to the left. Center yourself!';
      case PostureState.tiltedRight:
        return 'You\'re tilted to the right. Center yourself!';
      case PostureState.unknown:
        return 'Unable to detect posture';
    }
  }

  Color getPostureColor() {
    switch (_currentPosture) {
      case PostureState.good:
        return Colors.green;
      case PostureState.slouching:
      case PostureState.leaningForward:
      case PostureState.leaningBack:
      case PostureState.tiltedLeft:
      case PostureState.tiltedRight:
        return Colors.red;
      case PostureState.unknown:
        return Colors.grey;
    }
  }

  IconData getPostureIcon() {
    switch (_currentPosture) {
      case PostureState.good:
        return Icons.check_circle;
      case PostureState.slouching:
        return Icons.warning;
      case PostureState.leaningForward:
        return Icons.keyboard_arrow_down;
      case PostureState.leaningBack:
        return Icons.keyboard_arrow_up;
      case PostureState.tiltedLeft:
        return Icons.keyboard_arrow_left;
      case PostureState.tiltedRight:
        return Icons.keyboard_arrow_right;
      case PostureState.unknown:
        return Icons.help_outline;
    }
  }

  List<PostureData> getTodaysHistory() {
    final today = DateTime.now();
    return _postureHistory.where((data) {
      return data.split(':')[0].split('T')[0] == '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    }).map((e) => PostureData(x: 0, y: 0, z: 0, timestamp: DateTime.parse(e.split(':')[0]), state: _mapPostureStatusToState(e.split(':')[1].split(' (')[0].trim()))).toList();
  }

  Map<PostureState, int> getPostureDistribution() {
    final distribution = <PostureState, int>{};
    for (final data in _postureHistory) {
      final state = _mapPostureStatusToState(data.split(':')[1].split(' (')[0].trim());
      distribution[state] = (distribution[state] ?? 0) + 1;
    }
    return distribution;
  }

  bool _shouldShowAlert() {
    final now = DateTime.now();
    return _lastAlert == null || now.difference(_lastAlert!) >= _alertInterval;
  }

  void _triggerPostureAlert() {
    _lastAlert = DateTime.now();
    _alertCount++;
    
    if (_vibrateOnAlert) {
      Vibration.vibrate(duration: 500);
    }
    
    // In a real app, you might also play a sound here
    if (_soundOnAlert) {
      // Play alert sound
    }
  }

  void resetStatistics() {
    _postureHistory.clear();
    _alertCount = 0;
    _goodPosturePercentage = 0.0;
    _monitoringDuration = Duration.zero;
    _lastAlert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    _cameraController?.dispose();
    super.dispose();
  }
}
