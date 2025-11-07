import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecordingState {
  idle,
  recording,
  processing,
  completed,
  error,
}

class VoiceSummary {
  final String id;
  final String title;
  final String originalText;
  final String summary;
  final List<String> keyPoints;
  final Duration duration;
  final DateTime createdAt;
  final String? audioPath;

  VoiceSummary({
    required this.id,
    required this.title,
    required this.originalText,
    required this.summary,
    required this.keyPoints,
    required this.duration,
    required this.createdAt,
    this.audioPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'originalText': originalText,
    'summary': summary,
    'keyPoints': keyPoints,
    'duration': duration.inSeconds,
    'createdAt': createdAt.toIso8601String(),
    'audioPath': audioPath,
  };

  factory VoiceSummary.fromJson(Map<String, dynamic> json) => VoiceSummary(
    id: json['id'],
    title: json['title'],
    originalText: json['originalText'],
    summary: json['summary'],
    keyPoints: List<String>.from(json['keyPoints']),
    duration: Duration(seconds: json['duration']),
    createdAt: DateTime.parse(json['createdAt']),
    audioPath: json['audioPath'],
  );
}

class VoiceProvider extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcribedText = '';
  String _currentSummary = '';
  RecordingState _recordingState = RecordingState.idle;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;
  List<VoiceSummary> _summaries = [];
  String _errorMessage = '';
  bool _isInitialized = false;
  double _confidenceLevel = 0.0;

  // Getters
  RecordingState get recordingState => _recordingState;
  String get currentTranscription => _transcribedText;
  String get currentSummary => _currentSummary;
  List<VoiceSummary> get summaries => _summaries;
  Duration get recordingDuration => _recordingDuration;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  double get confidenceLevel => _confidenceLevel;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  VoiceProvider() {
    _initializeServices();
    _loadSummaries();
  }

  Future<void> _initializeServices() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _errorMessage = error.errorMsg;
          _recordingState = RecordingState.error;
          notifyListeners();
        },
      );
      
      if (_isInitialized) {
        debugPrint('Speech-to-text initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing speech-to-text: $e');
      _errorMessage = 'Failed to initialize speech recognition';
      _isInitialized = false;
    }
    notifyListeners();
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    if (!_isInitialized) {
      await _initializeServices();
    }

    if (!await _requestPermissions()) {
      _errorMessage = 'Microphone permission denied';
      _recordingState = RecordingState.error;
      notifyListeners();
      return;
    }

    try {
      _recordingState = RecordingState.recording;
      _transcribedText = '';
      _recordingDuration = Duration.zero;
      _errorMessage = '';
      notifyListeners();

      // Get recording path
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = '${directory.path}/$fileName';

      // Start audio recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      // Start speech recognition
      await _speechToText.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords;
          _confidenceLevel = result.confidence;
          notifyListeners();
        },
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 3),
        // ignore: deprecated_member_use
        partialResults: true,
        localeId: 'en_US',
        // ignore: deprecated_member_use
        cancelOnError: false,
      );

      _isListening = true;

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration = Duration(seconds: timer.tick);
        notifyListeners();
      });

    } catch (e) {
      debugPrint('Error starting recording: $e');
      _errorMessage = 'Failed to start recording: $e';
      _recordingState = RecordingState.error;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    try {
      _recordingState = RecordingState.processing;
      _isListening = false;
      _recordingTimer?.cancel();
      notifyListeners();

      // Stop audio recording
      await _audioRecorder.stop();

      // Stop speech recognition
      await _speechToText.stop();

      if (_transcribedText.isNotEmpty) {
        await _generateSummary();
        _recordingState = RecordingState.completed;
      } else {
        _errorMessage = 'No speech detected';
        _recordingState = RecordingState.error;
      }

    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _errorMessage = 'Failed to stop recording: $e';
      _recordingState = RecordingState.error;
    }
    notifyListeners();
  }

  Future<void> _generateSummary() async {
    if (_transcribedText.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // Simulate AI summarization (replace with actual AI service)
      await Future.delayed(const Duration(seconds: 2));
      
      final sentences = _transcribedText.split('. ');
      final keyPoints = <String>[];
      String summary = '';

      if (sentences.length > 3) {
        // Extract key points (first and last sentences, plus any with keywords)
        keyPoints.add(sentences.first);
        keyPoints.add(sentences.last);
        
        for (final sentence in sentences) {
          if (sentence.toLowerCase().contains(RegExp(r'\b(important|key|main|conclusion|summary)\b'))) {
            keyPoints.add(sentence);
          }
        }
        
        summary = 'Summary: ${sentences.take(2).join('. ')}.';
      } else {
        summary = _transcribedText;
        keyPoints.addAll(sentences);
      }

      final voiceSummary = VoiceSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _generateTitle(_transcribedText),
        originalText: _transcribedText,
        summary: summary,
        keyPoints: keyPoints.take(5).toList(),
        duration: _recordingDuration,
        createdAt: DateTime.now(),
        audioPath: _recordingPath,
      );

      _summaries.insert(0, voiceSummary);
      _currentSummary = summary;
      await _saveSummaries();

    } catch (e) {
      debugPrint('Error generating summary: $e');
      _errorMessage = 'Failed to generate summary';
    }

    _isProcessing = false;
    notifyListeners();
  }

  String _generateTitle(String text) {
    final words = text.split(' ').take(5).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }

  Future<void> _loadSummaries() async {
    // Load from local storage (implement with SharedPreferences or Hive)
    _summaries = [
      VoiceSummary(
        id: '1',
        title: 'Physics Lecture - Newton\'s Laws',
        originalText: 'Today we discussed Newton\'s three laws of motion. The first law states that an object at rest stays at rest...',
        summary: 'Covered Newton\'s three laws of motion with practical examples.',
        keyPoints: [
          'First law: Objects at rest stay at rest',
          'Second law: F = ma',
          'Third law: Every action has equal and opposite reaction'
        ],
        duration: const Duration(minutes: 45),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      VoiceSummary(
        id: '2',
        title: 'History - World War II',
        originalText: 'World War II was a global conflict that lasted from 1939 to 1945...',
        summary: 'Overview of World War II timeline and major events.',
        keyPoints: [
          'Started in 1939, ended in 1945',
          'Major powers involved',
          'Significant battles and outcomes'
        ],
        duration: const Duration(minutes: 30),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    notifyListeners();
  }

  Future<void> _saveSummaries() async {
    // Implement with SharedPreferences or Hive
    debugPrint('Saving ${_summaries.length} summaries');
  }

  // URL summarizer stub (simulate extracting transcript and creating a summary)
  Future<void> summarizeFromUrl(String url) async {
    _recordingState = RecordingState.processing;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      final text = 'Extracted transcript from $url. Key ideas about the topic are discussed including overview, key points, and conclusions.';
      final summary = 'AI Summary of $url: Overview of topic, key insights, and conclusions.';
      final keyPoints = [
        'Overview of topic',
        'Key insights explained',
        'Conclusions and takeaways',
      ];
      final vs = VoiceSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'URL Summary',
        originalText: text,
        summary: summary,
        keyPoints: keyPoints,
        duration: const Duration(minutes: 5),
        createdAt: DateTime.now(),
      );
      _summaries.insert(0, vs);
      await _saveSummaries();
      _recordingState = RecordingState.completed;
      notifyListeners();
    } catch (e) {
      _recordingState = RecordingState.error;
      _errorMessage = 'Failed to summarize URL';
      notifyListeners();
    }
  }

  // Document summarizer stub (simulate reading PDF/PPT and summarizing)
  Future<void> summarizeFromDocument() async {
    _recordingState = RecordingState.processing;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      const text = 'Extracted document text. Sections include introduction, methods, results, and discussion.';
      const summary = 'AI Summary: Introduction, methods overview, key results, and final discussion.';
      final keyPoints = [
        'Introduction highlights',
        'Methods overview',
        'Key results',
        'Discussion and implications',
      ];
      final vs = VoiceSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Document Summary',
        originalText: text,
        summary: summary,
        keyPoints: keyPoints,
        duration: const Duration(minutes: 3),
        createdAt: DateTime.now(),
      );
      _summaries.insert(0, vs);
      await _saveSummaries();
      _recordingState = RecordingState.completed;
      notifyListeners();
    } catch (e) {
      _recordingState = RecordingState.error;
      _errorMessage = 'Failed to summarize document';
      notifyListeners();
    }
  }

  void clearCurrentSession() {
    _transcribedText = '';
    _currentSummary = '';
    _recordingDuration = Duration.zero;
    _recordingPath = null;
    _errorMessage = '';
    _recordingState = RecordingState.idle;
    notifyListeners();
  }

  void deleteSummary(String id) {
    _summaries.removeWhere((summary) => summary.id == id);
    _saveSummaries();
    notifyListeners();
  }

  List<VoiceSummary> getRecentSummaries(int count) {
    return _summaries.take(count).toList();
  }

  int get totalSummaries => _summaries.length;

  Duration get totalRecordingTime {
    return _summaries.fold(Duration.zero, (total, summary) => total + summary.duration);
  }

  String get formattedRecordingDuration {
    return _formatDuration(_recordingDuration);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
