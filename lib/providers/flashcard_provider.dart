import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../secrets/api_keys.dart';
// YOUR FREE GEMINI API KEY
const String GEMINI_API_KEY = ApiKeys.geminiApiKey;
enum FlashcardDifficulty {
  easy,
  medium,
  hard,
}

enum StudyMode {
  review,
  practice,
  test,
}

// IMPORTANT: Add HiveType annotation for persistence
@HiveType(typeId: 0)
class Flashcard extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String question;
  
  @HiveField(2)
  final String answer;
  
  @HiveField(3)
  final String category;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final int reviewCount;
  
  @HiveField(6)
  final double difficulty;
  
  @HiveField(7)
  final DateTime? lastReviewed;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.createdAt,
    this.reviewCount = 0,
    this.difficulty = 0.5,
    this.lastReviewed,
  });

  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    DateTime? createdAt,
    int? reviewCount,
    double? difficulty,
    DateTime? lastReviewed,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      difficulty: difficulty ?? this.difficulty,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  // Add toJson for backup persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'reviewCount': reviewCount,
    'difficulty': difficulty,
    'lastReviewed': lastReviewed?.toIso8601String(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'],
    question: json['question'],
    answer: json['answer'],
    category: json['category'],
    createdAt: DateTime.parse(json['createdAt']),
    reviewCount: json['reviewCount'] ?? 0,
    difficulty: json['difficulty'] ?? 0.5,
    lastReviewed: json['lastReviewed'] != null 
        ? DateTime.parse(json['lastReviewed']) 
        : null,
  );
}

class FlashcardProvider extends ChangeNotifier {
  Box<dynamic>? _flashcardBox; // Changed to dynamic to handle JSON storage
  List<Flashcard> _flashcards = [];
  List<Flashcard> _currentDeck = [];
  int _currentCardIndex = 0;
  bool _isFlipped = false;
  String _selectedCategory = 'All';
  
  bool _isGenerating = false;
  String _transcribedText = '';
  
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  Map<String, int> _categoryStats = {};
  List<String> _studyHistory = [];

  List<Flashcard> get flashcards => _flashcards;
  List<Flashcard> get currentDeck => _currentDeck;
  Flashcard? get currentCard => _currentDeck.isNotEmpty ? _currentDeck[_currentCardIndex] : null;
  int get currentCardIndex => _currentCardIndex;
  bool get isCardFlipped => _isFlipped;
  bool get isGenerating => _isGenerating;
  String get transcribedText => _transcribedText;
  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  String get selectedCategory => _selectedCategory;
  int get totalCards => _currentDeck.length;
  int get remainingCards => _currentDeck.length - _currentCardIndex;

  FlashcardProvider() {
    // Don't load mock data - wait for Hive to initialize
    _initializeProvider();
  }

  // FIXED: Proper initialization sequence
  Future<void> _initializeProvider() async {
    try {
      await initializeHive();
    } catch (e) {
      debugPrint('Error in provider initialization: $e');
      // Fallback to mock data if Hive fails
      _loadMockFlashcards();
    }
  }

  // FIXED: Proper Hive initialization with error handling
  Future<void> initializeHive() async {
    try {
      // Open box (use simple name without complex types)
      _flashcardBox = await Hive.openBox('flashcards_data');
      
      debugPrint('✓ Hive box opened successfully');
      
      // Load existing flashcards
      await _loadFlashcardsFromStorage();
      await _loadStudyHistory();
      await _loadCategoryStats();
      
      // Add sample data if empty
      if (_flashcards.isEmpty) {
        debugPrint('No flashcards found, loading sample data...');
        await _loadSampleData();
      } else {
        debugPrint('✓ Loaded ${_flashcards.length} flashcards from storage');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing Hive: $e');
      // Fallback to mock data
      _loadMockFlashcards();
    }
  }

  // FIXED: Load from storage with JSON fallback
  Future<void> _loadFlashcardsFromStorage() async {
    if (_flashcardBox == null) return;
    
    try {
      _flashcards.clear();
      
      // Load all flashcards from Hive
      for (var key in _flashcardBox!.keys) {
        try {
          final data = _flashcardBox!.get(key);
          
          if (data is Map) {
            // Convert map to proper format
            final flashcard = Flashcard.fromJson(Map<String, dynamic>.from(data));
            _flashcards.add(flashcard);
          } else if (data is String) {
            // Handle JSON string storage
            final json = jsonDecode(data);
            final flashcard = Flashcard.fromJson(json);
            _flashcards.add(flashcard);
          }
        } catch (e) {
          debugPrint('Error loading flashcard with key $key: $e');
        }
      }
      
      _updateCurrentDeck();
      debugPrint('✓ Loaded ${_flashcards.length} flashcards');
    } catch (e) {
      debugPrint('Error in _loadFlashcardsFromStorage: $e');
    }
  }

  // FIXED: Save to storage with proper serialization
  Future<void> _saveFlashcardToStorage(Flashcard flashcard) async {
    if (_flashcardBox == null) {
      debugPrint('⚠️ Hive box not initialized');
      return;
    }
    
    try {
      // Save as JSON map for compatibility
      await _flashcardBox!.put(flashcard.id, flashcard.toJson());
      debugPrint('✓ Saved flashcard: ${flashcard.id}');
    } catch (e) {
      debugPrint('❌ Error saving flashcard: $e');
    }
  }

  /// Generate questions using Gemini API
  Future<void> generateQuestionsWithAI({
    required String prompt,
    required String questionType,
    required int numQuestions,
    String? pdfPath,
  }) async {
    _isGenerating = true;
    _transcribedText = '';
    notifyListeners();

    try {
      if (prompt.isEmpty && pdfPath == null) {
        throw Exception('Please provide a topic');
      }

      if (GEMINI_API_KEY.isEmpty || GEMINI_API_KEY == 'YOUR_API_KEY_HERE') {
        _transcribedText = 'Error: Please add your Gemini API key in the code.';
        _isGenerating = false;
        notifyListeners();
        return;
      }

      final response = await _callGeminiAPI(prompt, questionType, numQuestions);
      
      if (response['success']) {
        _transcribedText = response['content'];
        await _parseAndCreateFlashcards(
          _transcribedText,
          'Generated - $questionType',
          questionType,
        );
      } else {
        _transcribedText = 'Error: ${response['message']}';
      }

      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
      _transcribedText = 'Error: Could not generate questions. Please try again.';
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _callGeminiAPI(
    String topic,
    String questionType,
    int numQuestions,
  ) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY'
      );

      final prompt = _buildPrompt(topic, questionType, numQuestions);

      final requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 2000,
        }
      };

      debugPrint('🌐 Calling Gemini 2.5 Flash...');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return {'success': true, 'content': content ?? ''};
      } else {
        return {'success': false, 'message': 'Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      debugPrint('Exception: $e');
      return {'success': false, 'message': 'Network or API error: $e'};
    }
  }

  String _buildPrompt(String topic, String type, int count) {
    switch (type) {
      case 'mcq':
        return '''Generate exactly $count multiple choice questions about: $topic

Format each question EXACTLY like this:
Q1. [Question text]?
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
Correct Answer: [Letter]

Make questions educational and options plausible.''';

      case '2marks':
        return '''Generate exactly $count short answer questions (2 marks each) about: $topic

Format each question EXACTLY like this:
Q1. [Question text]? (2 marks)
Answer: [Brief 2-3 sentence answer]

Be concise and focused.''';

      case '5marks':
        return '''Generate exactly $count detailed questions (5 marks each) about: $topic

Format each question EXACTLY like this:
Q1. [Question text]? (5 marks)
Answer: 
1. [First key point]
2. [Second key point]
3. [Third key point]
4. [Example/Application]
5. [Conclusion]

Be comprehensive.''';

      default:
        return 'Generate $count questions about: $topic';
    }
  }

  Future<void> _parseAndCreateFlashcards(
    String content,
    String category,
    String questionType,
  ) async {
    final lines = content.split('\n');
    String currentQuestion = '';
    String currentAnswer = '';
    bool inAnswer = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) continue;

      if (RegExp(r'^Q\d+\.').hasMatch(line)) {
        if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
          await _addParsedFlashcard(currentQuestion, currentAnswer, category);
        }
        
        currentQuestion = line.replaceFirst(RegExp(r'^Q\d+\.\s*'), '');
        currentAnswer = '';
        inAnswer = false;
        continue;
      }

      if (line.toLowerCase().startsWith('answer:') || 
          line.toLowerCase().startsWith('correct answer:')) {
        inAnswer = true;
        currentAnswer = line.replaceFirst(RegExp(r'^(correct\s+)?answer:\s*', caseSensitive: false), '');
        continue;
      }

      if (inAnswer) {
        currentAnswer += '\n' + line;
      } else if (questionType == 'mcq' && RegExp(r'^[A-D]\)').hasMatch(line)) {
        currentQuestion += '\n' + line;
      }
    }

    if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
      await _addParsedFlashcard(currentQuestion, currentAnswer, category);
    }
  }

  Future<void> _addParsedFlashcard(
    String question,
    String answer,
    String category,
  ) async {
    final flashcard = Flashcard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      question: question.trim(),
      answer: answer.trim(),
      category: category,
      createdAt: DateTime.now(),
      reviewCount: 0,
      difficulty: 0.5,
    );

    _flashcards.add(flashcard);
    await _saveFlashcardToStorage(flashcard);
    _updateCurrentDeck();
  }

  void clearGeneratedContent() {
    _transcribedText = '';
    _isGenerating = false;
    notifyListeners();
  }

  // Method used by voice_summary_screen.dart to generate flashcards from transcribed text
  Future<List<Flashcard>> generateFlashcardsFromText(
    String sourceText, {
    String category = 'Generated',
  }) async {
    final List<Flashcard> generated = [];
    final cleaned = sourceText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    if (cleaned.isEmpty) return generated;

    final sentences = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().length > 10)
        .toList();
    
    for (final sentence in sentences.take(10)) {
      final parts = sentence.split(' ');
      if (parts.length < 6) continue;
      
      final answer = parts.take(3).join(' ');
      final question = 'What does this refer to: "${sentence.substring(0, sentence.length > 80 ? 80 : sentence.length)}..."?';

      final card = Flashcard(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        question: question,
        answer: answer,
        category: category,
        createdAt: DateTime.now(),
        reviewCount: 0,
        difficulty: 0.5,
      );
      
      _flashcards.add(card);
      generated.add(card);
      await _saveFlashcardToStorage(card);
    }

    _updateCurrentDeck();
    notifyListeners();
    return generated;
  }

  void _loadMockFlashcards() {
    _flashcards = [
      Flashcard(
        id: '1',
        question: 'What is the capital of France?',
        answer: 'Paris',
        category: 'Geography',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        reviewCount: 3,
        difficulty: 0.2,
      ),
      Flashcard(
        id: '2',
        question: 'What is the formula for calculating the area of a circle?',
        answer: 'A = πr²',
        category: 'Mathematics',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reviewCount: 5,
        difficulty: 0.6,
      ),
      Flashcard(
        id: '3',
        question: 'Who wrote "To Kill a Mockingbird"?',
        answer: 'Harper Lee',
        category: 'Literature',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        reviewCount: 2,
        difficulty: 0.4,
      ),
    ];
    _currentDeck = List.from(_flashcards);
    notifyListeners();
  }

  Future<void> _loadStudyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('study_history');
      if (historyJson != null) {
        _studyHistory = List<String>.from(jsonDecode(historyJson));
      }
    } catch (e) {
      debugPrint('Error loading study history: $e');
    }
  }

  Future<void> _loadCategoryStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('category_stats');
      if (statsJson != null) {
        _categoryStats = Map<String, int>.from(jsonDecode(statsJson));
      }
    } catch (e) {
      debugPrint('Error loading category stats: $e');
    }
  }

  Future<void> _loadSampleData() async {
    final sampleCards = [
      {'question': 'What is the capital of France?', 'answer': 'Paris', 'category': 'Geography'},
      {'question': 'What is 2 + 2?', 'answer': '4', 'category': 'Math'},
      {'question': 'Who wrote Romeo and Juliet?', 'answer': 'William Shakespeare', 'category': 'Literature'},
      {'question': 'What is the speed of light?', 'answer': '299,792,458 meters per second', 'category': 'Physics'},
      {'question': 'What is the chemical symbol for water?', 'answer': 'H2O', 'category': 'Chemistry'},
    ];

    for (final cardData in sampleCards) {
      await addFlashcard(cardData['question']!, cardData['answer']!, cardData['category']!);
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _currentDeck = List.from(_flashcards);
    } else {
      _currentDeck = _flashcards.where((card) => card.category == category).toList();
    }
    _currentCardIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }

  List<String> get categories {
    final categories = _flashcards.map((card) => card.category).toSet().toList();
    categories.sort();
    categories.insert(0, 'All');
    return categories;
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void nextCard() {
    if (_currentCardIndex < _currentDeck.length - 1) {
      _currentCardIndex++;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentCardIndex > 0) {
      _currentCardIndex--;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void shuffleDeck() {
    _currentDeck.shuffle();
    _currentCardIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }

  void resetDeck() {
    _currentCardIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }

  Future<void> markAnswer(bool isCorrect) async {
    if (_currentDeck.isEmpty) return;

    final currentCard = _currentDeck[_currentCardIndex];
    _totalAnswers++;
    
    if (isCorrect) {
      _correctAnswers++;
    }

    final updatedCard = Flashcard(
      id: currentCard.id,
      question: currentCard.question,
      answer: currentCard.answer,
      category: currentCard.category,
      createdAt: currentCard.createdAt,
      reviewCount: currentCard.reviewCount + 1,
      difficulty: isCorrect 
          ? (currentCard.difficulty * 0.9).clamp(0.1, 1.0)
          : (currentCard.difficulty * 1.1).clamp(0.1, 1.0),
      lastReviewed: DateTime.now(),
    );

    await _saveFlashcardToStorage(updatedCard);
    
    final index = _flashcards.indexWhere((card) => card.id == updatedCard.id);
    if (index != -1) {
      _flashcards[index] = updatedCard;
    }

    await _saveStudyProgress(currentCard.category, isCorrect);
    notifyListeners();
  }

  Future<void> _saveStudyProgress(String category, bool isCorrect) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final entry = '$timestamp: $category - ${isCorrect ? 'Correct' : 'Incorrect'}';
      _studyHistory.add(entry);
      
      if (_studyHistory.length > 100) {
        _studyHistory.removeAt(0);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('study_history', jsonEncode(_studyHistory));
    } catch (e) {
      debugPrint('Error saving study progress: $e');
    }
  }

  Future<void> addFlashcard(String question, String answer, String category) async {
    final flashcard = Flashcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      answer: answer,
      category: category,
      createdAt: DateTime.now(),
      reviewCount: 0,
      difficulty: 0.5,
    );

    _flashcards.add(flashcard);
    await _saveFlashcardToStorage(flashcard);
    await _updateCategoryStats(category, 1);
    _updateCurrentDeck();
    notifyListeners();
  }

  Future<void> _updateCategoryStats(String category, int count) async {
    try {
      _categoryStats[category] = (_categoryStats[category] ?? 0) + count;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('category_stats', jsonEncode(_categoryStats));
    } catch (e) {
      debugPrint('Error updating category stats: $e');
    }
  }

  void _updateCurrentDeck() {
    if (_selectedCategory == 'All') {
      _currentDeck = List.from(_flashcards);
    } else {
      _currentDeck = _flashcards.where((card) => card.category == _selectedCategory).toList();
    }
    notifyListeners();
  }

  Future<void> deleteFlashcard(String id) async {
    _flashcards.removeWhere((card) => card.id == id);
    _currentDeck.removeWhere((card) => card.id == id);
    
    await _flashcardBox?.delete(id);
    
    if (_currentCardIndex >= _currentDeck.length && _currentDeck.isNotEmpty) {
      _currentCardIndex = _currentDeck.length - 1;
    }
    
    _isFlipped = false;
    notifyListeners();
  }

  Future<void> addCustomFlashcard(String question, String answer, String category) async {
    final newCard = Flashcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      answer: answer,
      category: category,
      createdAt: DateTime.now(),
      reviewCount: 0,
      difficulty: 0.5,
      lastReviewed: null,
    );

    _flashcards.add(newCard);
    await _saveFlashcardToStorage(newCard);
    _updateCurrentDeck();
    notifyListeners();
  }

  @override
  void dispose() {
    _flashcardBox?.close();
    super.dispose();
  }
}