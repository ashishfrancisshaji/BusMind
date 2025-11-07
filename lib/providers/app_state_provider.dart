import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AppStateProvider extends ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _isDarkMode = false;
  bool _isOnBus = false;
  String _currentRoute = '';
  DateTime? _busStartTime;
  Duration _estimatedTripDuration = const Duration(minutes: 30);
  
  // Alarm functionality
  final AudioPlayer _alarmPlayer = AudioPlayer();
  Timer? _alarmTimer;
  int _alarmPlayCount = 0;
  bool _isAlarmPlaying = false;
  bool _tripEndedNotified = false;

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isDarkMode => _isDarkMode;
  bool get isOnBus => _isOnBus;
  String get currentRoute => _currentRoute;
  DateTime? get busStartTime => _busStartTime;
  Duration get estimatedTripDuration => _estimatedTripDuration;
  bool get isAlarmPlaying => _isAlarmPlaying;

  AppStateProvider() {
    _loadPreferences();
    _startTripMonitoring();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isOnBus = prefs.getBool('isOnBus') ?? false;
    _currentRoute = prefs.getString('currentRoute') ?? '';
    
    final busStartTimeMs = prefs.getInt('busStartTime');
    if (busStartTimeMs != null) {
      _busStartTime = DateTime.fromMillisecondsSinceEpoch(busStartTimeMs);
    }
    
    final tripDurationMinutes = prefs.getInt('estimatedTripDuration') ?? 30;
    _estimatedTripDuration = Duration(minutes: tripDurationMinutes);
    
    notifyListeners();
  }

  void _startTripMonitoring() {
    // Check every second if trip has ended
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isOnBus && remainingTripTime.inSeconds <= 0 && !_tripEndedNotified) {
        _tripEndedNotified = true;
        _startAlarm();
      }
    });
  }

  Future<void> _startAlarm() async {
    if (_isAlarmPlaying) return;
    
    _isAlarmPlaying = true;
    _alarmPlayCount = 0;
    
    debugPrint('🚨 Trip ended! Starting alarm...');
    
    // Play alarm 10 times
    _alarmTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_alarmPlayCount >= 10 || !_isAlarmPlaying) {
        timer.cancel();
        _isAlarmPlaying = false;
        await _alarmPlayer.stop();
        debugPrint('🔕 Alarm stopped');
        notifyListeners();
        return;
      }
      
      _alarmPlayCount++;
      debugPrint('🔔 Alarm ring #$_alarmPlayCount');
      
      // Play system sound (notification sound)
      try {
        await _alarmPlayer.setSource(AssetSource('sounds/alarm.mp3'));
        await _alarmPlayer.resume();
      } catch (e) {
        // Fallback: use vibration if sound fails
        debugPrint('⚠️ Could not play alarm sound: $e');
      }
      
      notifyListeners();
    });
  }

  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    _alarmTimer?.cancel();
    await _alarmPlayer.stop();
    debugPrint('🔕 Alarm manually stopped');
    notifyListeners();
  }

  Future<void> setFirstLaunchComplete() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> startBusTrip(String route, Duration estimatedDuration) async {
    // Limit duration to 12 hours (720 minutes)
    if (estimatedDuration.inMinutes > 720) {
      estimatedDuration = const Duration(minutes: 720);
    }
    
    // Minimum 1 minute
    if (estimatedDuration.inMinutes < 1) {
      estimatedDuration = const Duration(minutes: 1);
    }
    
    _isOnBus = true;
    _currentRoute = route;
    _busStartTime = DateTime.now();
    _estimatedTripDuration = estimatedDuration;
    _tripEndedNotified = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnBus', true);
    await prefs.setString('currentRoute', route);
    await prefs.setInt('busStartTime', _busStartTime!.millisecondsSinceEpoch);
    await prefs.setInt('estimatedTripDuration', estimatedDuration.inMinutes);
    
    debugPrint('🚌 Started trip: $route for ${estimatedDuration.inMinutes} minutes');
    notifyListeners();
  }

  Future<void> endBusTrip() async {
    _isOnBus = false;
    _currentRoute = '';
    _busStartTime = null;
    _tripEndedNotified = false;
    
    // Stop alarm if playing
    await stopAlarm();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnBus', false);
    await prefs.setString('currentRoute', '');
    await prefs.remove('busStartTime');
    
    debugPrint('🛑 Ended trip');
    notifyListeners();
  }

  Duration get remainingTripTime {
    if (_busStartTime == null) return Duration.zero;
    
    final elapsed = DateTime.now().difference(_busStartTime!);
    final remaining = _estimatedTripDuration - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get tripProgress {
    if (_busStartTime == null) return 0.0;
    
    final elapsed = DateTime.now().difference(_busStartTime!);
    final progress = elapsed.inMilliseconds / _estimatedTripDuration.inMilliseconds;
    
    return progress.clamp(0.0, 1.0);
  }

  // Format remaining time properly (handles hours)
  String get formattedRemainingTime {
    final remaining = remainingTripTime;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _alarmPlayer.dispose();
    super.dispose();
  }
}