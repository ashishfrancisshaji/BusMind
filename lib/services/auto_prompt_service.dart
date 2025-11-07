import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AutoPromptService {
  static Timer? _moodTimer;
  static Timer? _postureTimer;
  static BuildContext? _context;

  static void initialize(BuildContext context) {
    _context = context;
    _startMoodPromptTimer();
    _startPosturePromptTimer();
  }

  static void _startMoodPromptTimer() {
    _moodTimer?.cancel();
    _moodTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _showMoodPrompt();
    });
  }

  static void _startPosturePromptTimer() {
    _postureTimer?.cancel();
    _postureTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _showPosturePrompt();
    });
  }

  static void _showMoodPrompt() {
    if (_context == null) return;
    
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue),
            SizedBox(width: 10),
            Text('Mood Check'),
          ],
        ),
        content: const Text(
          'It\'s time for a mood check! Let\'s see how you\'re feeling right now.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to mood detection screen
              context.go('/mood-detection');
            },
            child: const Text('Check Mood'),
          ),
        ],
      ),
    );
  }

  static void _showPosturePrompt() {
    if (_context == null) return;
    
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.accessibility, color: Colors.green),
            SizedBox(width: 10),
            Text('Posture Check'),
          ],
        ),
        content: const Text(
          'Time for a posture check! Let\'s make sure you\'re sitting comfortably.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to posture screen
              context.go('/posture');
            },
            child: const Text('Check Posture'),
          ),
        ],
      ),
    );
  }

  static void dispose() {
    _moodTimer?.cancel();
    _postureTimer?.cancel();
    _context = null;
  }

  static void resetTimers() {
    _startMoodPromptTimer();
    _startPosturePromptTimer();
  }
}
