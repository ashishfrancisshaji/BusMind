import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'mood_detection_provider.dart';
import 'music_provider.dart';
import 'posture_provider.dart';
import 'voice_provider.dart';
import 'flashcard_provider.dart';

class AnalyticsData {
  final DateTime date;
  final int studyMinutes;
  final int flashcardsReviewed;
  final int voiceRecordings;
  final double postureScore;
  final String dominantMood;
  final int songsPlayed;
  final int moodDetections;

  AnalyticsData({
    required this.date,
    required this.studyMinutes,
    required this.flashcardsReviewed,
    required this.voiceRecordings,
    required this.postureScore,
    required this.dominantMood,
    this.songsPlayed = 0,
    this.moodDetections = 0,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'studyMinutes': studyMinutes,
    'flashcardsReviewed': flashcardsReviewed,
    'voiceRecordings': voiceRecordings,
    'postureScore': postureScore,
    'dominantMood': dominantMood,
    'songsPlayed': songsPlayed,
    'moodDetections': moodDetections,
  };

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
    date: DateTime.parse(json['date']),
    studyMinutes: json['studyMinutes'] ?? 0,
    flashcardsReviewed: json['flashcardsReviewed'] ?? 0,
    voiceRecordings: json['voiceRecordings'] ?? 0,
    postureScore: (json['postureScore'] ?? 0.0).toDouble(),
    dominantMood: json['dominantMood'] ?? 'unknown',
    songsPlayed: json['songsPlayed'] ?? 0,
    moodDetections: json['moodDetections'] ?? 0,
  );
}

class WeeklyStats {
  final int totalStudyTime;
  final int totalFlashcards;
  final int totalRecordings;
  final double averagePostureScore;
  final Map<String, int> moodDistribution;
  final List<AnalyticsData> dailyData;
  final int totalSongsPlayed;
  final int totalMoodDetections;

  WeeklyStats({
    required this.totalStudyTime,
    required this.totalFlashcards,
    required this.totalRecordings,
    required this.averagePostureScore,
    required this.moodDistribution,
    required this.dailyData,
    this.totalSongsPlayed = 0,
    this.totalMoodDetections = 0,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  List<AnalyticsData> _analyticsData = [];
  bool _isLoading = false;
  String _selectedTimeframe = 'week';
  Timer? _dataUpdateTimer;

  // Current session tracking
  DateTime? _sessionStartTime;
  int _currentSessionFlashcards = 0;
  int _currentSessionRecordings = 0;
  int _currentSessionSongsPlayed = 0;
  int _currentSessionMoodDetections = 0;
  double _currentSessionPostureScore = 0.0;
  String _currentSessionMood = 'focused';

  // Reference to other providers (set externally)
  FlashcardProvider? _flashcardProvider;
  MusicProvider? _musicProvider;
  PostureProvider? _postureProvider;
  VoiceProvider? _voiceProvider;
  MoodDetectionProvider? _moodProvider;

  // Getters
  List<AnalyticsData> get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;
  String get selectedTimeframe => _selectedTimeframe;

  AnalyticsProvider() {
    _loadAnalyticsData();
    _startDataUpdateTimer();
  }

  // Initialize with other providers for REAL data tracking
  void linkProviders({
    FlashcardProvider? flashcardProvider,
    MusicProvider? musicProvider,
    PostureProvider? postureProvider,
    VoiceProvider? voiceProvider,
    MoodDetectionProvider? moodProvider,
  }) {
    _flashcardProvider = flashcardProvider;
    _musicProvider = musicProvider;
    _postureProvider = postureProvider;
    _voiceProvider = voiceProvider;
    _moodProvider = moodProvider;
  }

  void _startDataUpdateTimer() {
    _dataUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _syncRealTimeData();
    });
  }

  // SYNC REAL DATA from other providers
  void _syncRealTimeData() {
    if (_sessionStartTime == null) return;

    // Get real flashcard count
    _currentSessionFlashcards = _flashcardProvider?.flashcards.where((card) {
      return card.lastReviewed != null && 
             card.lastReviewed!.isAfter(_sessionStartTime!);
    }).length ?? 0;

    // Get real voice recordings count
    _currentSessionRecordings = _voiceProvider?.summaries.where((summary) {
      return summary.createdAt.isAfter(_sessionStartTime!);
    }).length ?? 0;

    // Get real mood
    _currentSessionMood = _moodProvider?.currentMood.name ?? 'focused';

    // Get real posture score
    if (_postureProvider?.goodPosturePercentage != null) {
      _currentSessionPostureScore = _postureProvider!.goodPosturePercentage;
    }

    _updateCurrentDayData();
  }

  Future<void> _loadAnalyticsData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('analytics_data');
      
      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> dataList = jsonDecode(dataString);
        _analyticsData = dataList.map((json) => AnalyticsData.fromJson(json)).toList();
      }
      
      if (_analyticsData.isEmpty) {
        _generateInitialData();
        await _saveAnalyticsData();
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      _generateInitialData();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _generateInitialData() {
    final now = DateTime.now();
    _analyticsData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: index));
      return AnalyticsData(
        date: date,
        studyMinutes: 0,
        flashcardsReviewed: 0,
        voiceRecordings: 0,
        postureScore: 0.0,
        dominantMood: 'unknown',
        songsPlayed: 0,
        moodDetections: 0,
      );
    }).reversed.toList();
  }

  Future<void> _saveAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataList = _analyticsData.map((data) => data.toJson()).toList();
      await prefs.setString('analytics_data', jsonEncode(dataList));
    } catch (e) {
      debugPrint('Error saving analytics: $e');
    }
  }

  // Session tracking
  void startStudySession() {
    _sessionStartTime = DateTime.now();
    _currentSessionFlashcards = 0;
    _currentSessionRecordings = 0;
    _currentSessionSongsPlayed = 0;
    _currentSessionMoodDetections = 0;
    _currentSessionPostureScore = 0.0;
    _currentSessionMood = 'focused';
    debugPrint('📊 Analytics session started');
  }

  void endStudySession() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      _syncRealTimeData(); // Get final counts
      _updateCurrentDayData(
        additionalStudyMinutes: sessionDuration.inMinutes,
      );
      _sessionStartTime = null;
      debugPrint('📊 Analytics session ended: ${sessionDuration.inMinutes}min');
    }
  }

  // Real-time tracking methods
  void trackFlashcardReview() {
    _currentSessionFlashcards++;
    _updateCurrentDayData(additionalFlashcards: 1);
  }

  void trackVoiceRecording() {
    _currentSessionRecordings++;
    _updateCurrentDayData(additionalRecordings: 1);
  }

  void trackSongPlayed() {
    _currentSessionSongsPlayed++;
    _updateCurrentDayData(additionalSongs: 1);
  }

  void trackMoodDetection(String mood) {
    _currentSessionMoodDetections++;
    _currentSessionMood = mood;
    _updateCurrentDayData(
      additionalMoodDetections: 1,
      newMood: mood,
    );
  }

  void updatePostureScore(double score) {
    _currentSessionPostureScore = score.clamp(0.0, 1.0);
    _updateCurrentDayData(newPostureScore: score);
  }

  void _updateCurrentDayData({
    int additionalStudyMinutes = 0,
    int additionalFlashcards = 0,
    int additionalRecordings = 0,
    int additionalSongs = 0,
    int additionalMoodDetections = 0,
    double? newPostureScore,
    String? newMood,
  }) {
    final today = DateTime.now();
    final todayIndex = _analyticsData.indexWhere((data) => _isSameDay(data.date, today));

    if (todayIndex != -1) {
      final todayData = _analyticsData[todayIndex];
      _analyticsData[todayIndex] = AnalyticsData(
        date: today,
        studyMinutes: todayData.studyMinutes + additionalStudyMinutes,
        flashcardsReviewed: todayData.flashcardsReviewed + additionalFlashcards,
        voiceRecordings: todayData.voiceRecordings + additionalRecordings,
        songsPlayed: todayData.songsPlayed + additionalSongs,
        moodDetections: todayData.moodDetections + additionalMoodDetections,
        postureScore: newPostureScore ?? todayData.postureScore,
        dominantMood: newMood ?? todayData.dominantMood,
      );
    } else {
      _analyticsData.add(AnalyticsData(
        date: today,
        studyMinutes: additionalStudyMinutes,
        flashcardsReviewed: additionalFlashcards,
        voiceRecordings: additionalRecordings,
        songsPlayed: additionalSongs,
        moodDetections: additionalMoodDetections,
        postureScore: newPostureScore ?? 0.0,
        dominantMood: newMood ?? 'unknown',
      ));
    }

    _analyticsData.sort((a, b) => a.date.compareTo(b.date));
    _saveAnalyticsData();
    notifyListeners();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Analytics calculations
  WeeklyStats getWeeklyStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final weekData = _analyticsData.where(
      (data) => data.date.isAfter(weekAgo) && data.date.isBefore(now.add(const Duration(days: 1)))
    ).toList();

    final totalStudyTime = weekData.fold(0, (sum, data) => sum + data.studyMinutes);
    final totalFlashcards = weekData.fold(0, (sum, data) => sum + data.flashcardsReviewed);
    final totalRecordings = weekData.fold(0, (sum, data) => sum + data.voiceRecordings);
    final totalSongs = weekData.fold(0, (sum, data) => sum + data.songsPlayed);
    final totalMoodChecks = weekData.fold(0, (sum, data) => sum + data.moodDetections);
    
    final averagePostureScore = weekData.isEmpty 
        ? 0.0 
        : weekData.fold(0.0, (sum, data) => sum + data.postureScore) / weekData.length;

    final moodDistribution = <String, int>{};
    for (final data in weekData) {
      moodDistribution[data.dominantMood] = (moodDistribution[data.dominantMood] ?? 0) + 1;
    }

    return WeeklyStats(
      totalStudyTime: totalStudyTime,
      totalFlashcards: totalFlashcards,
      totalRecordings: totalRecordings,
      averagePostureScore: averagePostureScore,
      moodDistribution: moodDistribution,
      dailyData: weekData,
      totalSongsPlayed: totalSongs,
      totalMoodDetections: totalMoodChecks,
    );
  }

  List<AnalyticsData> getDataForTimeframe(String timeframe) {
    final now = DateTime.now();
    DateTime startDate;

    switch (timeframe) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return _analyticsData.where(
      (data) => data.date.isAfter(startDate)
    ).toList();
  }

  void setTimeframe(String timeframe) {
    _selectedTimeframe = timeframe;
    notifyListeners();
  }

  // REAL Insights based on ACTUAL data
  String getProductivityInsight() {
    final weekStats = getWeeklyStats();
    
    if (weekStats.totalStudyTime > 300) {
      return "🔥 Amazing! ${weekStats.totalStudyTime} minutes studied this week! You're crushing it!";
    } else if (weekStats.totalStudyTime > 150) {
      return "💪 Solid work! ${weekStats.totalStudyTime} minutes studied. Push for 300 minutes next week!";
    } else if (weekStats.totalStudyTime > 0) {
      return "📚 ${weekStats.totalStudyTime} minutes logged. Let's aim higher! Set daily goals to reach 300min/week.";
    } else {
      return "🎯 Ready to start? Track your study sessions and watch your progress grow!";
    }
  }

  String getPostureInsight() {
    final weekStats = getWeeklyStats();
    final score = (weekStats.averagePostureScore * 100).toInt();
    
    if (weekStats.averagePostureScore > 0.8) {
      return "✨ Excellent posture! ${score}% average. Your back thanks you!";
    } else if (weekStats.averagePostureScore > 0.6) {
      return "👍 Decent posture at ${score}%. Keep working on sitting straight!";
    } else if (weekStats.averagePostureScore > 0) {
      return "⚠️ Posture needs work (${score}%). Better posture = better focus!";
    } else {
      return "📏 Start tracking your posture for health insights!";
    }
  }

  String getMoodInsight() {
    final weekStats = getWeeklyStats();
    
    if (weekStats.moodDistribution.isEmpty) {
      return "😊 Use mood detection to get personalized insights!";
    }
    
    final dominantMood = weekStats.moodDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final moodEmojis = {
      'happy': '😊',
      'focused': '🎯',
      'tired': '😴',
      'stressed': '😰',
      'sad': '😔',
      'relaxed': '😌',
    };

    final emoji = moodEmojis[dominantMood] ?? '😐';
    
    switch (dominantMood) {
      case 'focused':
        return "$emoji Mostly focused this week! Perfect for deep learning.";
      case 'happy':
        return "$emoji Great vibes! Happy mood = better retention.";
      case 'tired':
        return "$emoji You seem tired. More rest = better performance.";
      case 'stressed':
        return "$emoji High stress detected. Try breaks and smaller goals.";
      case 'relaxed':
        return "$emoji Chill week! Good balance for long-term learning.";
      default:
        return "📊 Keep tracking mood for better insights!";
    }
  }

  // Get REAL stats
  int getTotalFlashcardsAllTime() {
    return _flashcardProvider?.flashcards.length ?? 0;
  }

  int getTotalVoiceRecordingsAllTime() {
    return _voiceProvider?.totalSummaries ?? 0;
  }

  Duration getTotalRecordingTime() {
    return _voiceProvider?.totalRecordingTime ?? Duration.zero;
  }

  String getCurrentMood() {
    return _moodProvider?.currentMood.name ?? 'unknown';
  }

  bool isPostureMonitoringActive() {
    return _postureProvider?.isMonitoring ?? false;
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    super.dispose();
  }
}