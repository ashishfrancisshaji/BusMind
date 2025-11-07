import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';

/// Analytics tracking helper - call these methods after user actions
class AnalyticsTracker {
  /// Track flashcard review
  static void trackFlashcard(BuildContext context) {
    try {
      context.read<AnalyticsProvider>().trackFlashcardReview();
      debugPrint('📊 ✅ Tracked flashcard review');
    } catch (e) {
      debugPrint('📊 ❌ Error tracking flashcard: $e');
    }
  }
  
  /// Track voice recording
  static void trackVoice(BuildContext context) {
    try {
      context.read<AnalyticsProvider>().trackVoiceRecording();
      debugPrint('📊 ✅ Tracked voice recording');
    } catch (e) {
      debugPrint('📊 ❌ Error tracking voice: $e');
    }
  }
  
  /// Track song played
  static void trackSong(BuildContext context) {
    try {
      context.read<AnalyticsProvider>().trackSongPlayed();
      debugPrint('📊 ✅ Tracked song played');
    } catch (e) {
      debugPrint('📊 ❌ Error tracking song: $e');
    }
  }
  
  /// Track mood detection
  static void trackMood(BuildContext context, String mood) {
    try {
      context.read<AnalyticsProvider>().trackMoodDetection(mood);
      debugPrint('📊 ✅ Tracked mood: $mood');
    } catch (e) {
      debugPrint('📊 ❌ Error tracking mood: $e');
    }
  }
  
  /// Update posture score
  static void trackPosture(BuildContext context, double score) {
    try {
      context.read<AnalyticsProvider>().updatePostureScore(score);
      debugPrint('📊 ✅ Tracked posture: ${(score * 100).toInt()}%');
    } catch (e) {
      debugPrint('📊 ❌ Error tracking posture: $e');
    }
  }
}