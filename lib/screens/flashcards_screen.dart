import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_tracker.dart'; // ✅ ALREADY IMPORTED
import 'package:file_picker/file_picker.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _topicController = TextEditingController();
  String _questionType = 'mcq';
  int _numQuestions = 10;
  String? _uploadedFileName;
  String? _uploadedFilePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Study Materials',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCardDialog,
            tooltip: 'Add Flashcard',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Flashcards', icon: Icon(Icons.style)),
                Tab(text: 'Create with AI', icon: Icon(Icons.auto_awesome)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlashcardsTab(),
                _buildAIGeneratorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ FLASHCARDS TAB - WITH ANALYTICS ============
  Widget _buildFlashcardsTab() {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, child) {
        if (provider.flashcards.isEmpty) {
          return _buildEmptyFlashcards();
        }

        return Column(
          children: [
            _buildCategorySelector(provider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.currentDeck.length,
                itemBuilder: (context, index) {
                  final card = provider.currentDeck[index];
                  return _buildExpandedFlashcard(card, provider, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySelector(FlashcardProvider provider) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final isSelected = category == provider.selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.setCategory(category);
                }
              },
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ UPDATED: Flashcard with analytics tracking
  Widget _buildExpandedFlashcard(Flashcard card, FlashcardProvider provider, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.all(20),
          // ✅ TRACK WHEN USER REVIEWS (EXPANDS) A FLASHCARD
          onExpansionChanged: (expanded) {
            if (expanded) {
              // Track analytics
              AnalyticsTracker.trackFlashcard(context);
              debugPrint('📊 ✅ Flashcard reviewed: ${card.question}');
              
              // Show subtle feedback
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('Review tracked!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                ),
              );
            }
          },
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          title: Text(
            card.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    card.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Reviewed ${card.reviewCount}x',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          children: [
            // ANSWER SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Answer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.answer,
                    style: const TextStyle(
                      height: 1.6,
                      fontSize: 15,
                      color: AppTheme.successColor,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Added ${_formatDate(card.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () => _confirmDelete(card.id, provider),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyFlashcards() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.style_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No flashcards yet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create your first flashcards to get started\nwith your study journey',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ AI GENERATOR TAB ============
  Widget _buildAIGeneratorTab() {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, child) {
        return Container(
          color: Colors.black,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildQuestionGeneratorCard(provider),
                const SizedBox(height: 20),
                if (provider.isGenerating)
                  _buildGeneratingIndicator()
                else if (provider.transcribedText.isNotEmpty)
                  _buildGeneratedQuestions(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionGeneratorCard(FlashcardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'AI Question Generator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _topicController,
            enabled: !provider.isGenerating,
            maxLines: 3,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'What topic would you like to study?',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'e.g., "Newton\'s Laws", "Photosynthesis", "World War II"',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
              helperText: 'Enter a topic and we\'ll generate questions for you',
              helperStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: !provider.isGenerating ? _pickPDF : null,
            icon: Icon(
              _uploadedFileName != null ? Icons.check_circle : Icons.upload_file,
              color: Colors.white70,
            ),
            label: Text(
              _uploadedFileName ?? 'Upload Study Material (Optional)',
              style: const TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              side: BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_uploadedFileName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: $_uploadedFileName',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _uploadedFileName = null;
                      _uploadedFilePath = null;
                    });
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          const Text(
            'Question Type:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildQuestionTypeChip('Multiple Choice', 'mcq', !provider.isGenerating),
              _buildQuestionTypeChip('Short Answer', '2marks', !provider.isGenerating),
              _buildQuestionTypeChip('Essay', '5marks', !provider.isGenerating),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Number of Questions:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _numQuestions,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2a2a2a),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: [5, 10, 15, 20].map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text('$num', style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: !provider.isGenerating ? (val) => setState(() => _numQuestions = val!) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !provider.isGenerating ? () => _generateQuestions(provider) : null,
              icon: provider.isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                provider.isGenerating ? 'Generating...' : 'Generate Questions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeChip(String label, String value, bool enabled) {
    final isSelected = _questionType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: enabled
          ? (val) {
              if (val) setState(() => _questionType = value);
            }
          : null,
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: AppTheme.primaryColor.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.white24,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildGeneratingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 24),
          Text(
            'Generating Questions...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please wait while your questions are being created',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedQuestions(FlashcardProvider provider) {
    final isError = provider.transcribedText.startsWith('Error:');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError ? Colors.red : AppTheme.successColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isError ? Colors.red : AppTheme.successColor).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isError 
                      ? Colors.red.withOpacity(0.1) 
                      : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle,
                  color: isError ? Colors.red : AppTheme.successColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isError ? 'Generation Failed' : 'Questions Created Successfully!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isError ? Colors.red : AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SingleChildScrollView(
              child: Text(
                provider.transcribedText,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF1a1a1a),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          if (!isError) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Questions saved! View them in Flashcards tab'),
                          backgroundColor: AppTheme.successColor,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.clearGeneratedContent();
                    _topicController.clear();
                    setState(() {
                      _uploadedFileName = null;
                      _uploadedFilePath = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => provider.clearGeneratedContent(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============
  void _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _uploadedFileName = result.files.single.name;
          _uploadedFilePath = result.files.single.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${result.files.single.name}'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateQuestions(FlashcardProvider provider) async {
    final topic = _topicController.text.trim();

    if (topic.isEmpty && _uploadedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic or upload a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await provider.generateQuestionsWithAI(
        prompt: topic,
        questionType: _questionType,
        numQuestions: _numQuestions,
        pdfPath: _uploadedFilePath,
      );

      if (!provider.transcribedText.startsWith('Error:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Generated $_numQuestions questions successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showAddCardDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    String selectedCategory = 'General';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('Add New Flashcard'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: InputDecoration(
                  labelText: 'Question',
                  hintText: 'Enter your question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: answerController,
                decoration: InputDecoration(
                  labelText: 'Answer',
                  hintText: 'Enter the answer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Science, Math, History',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                onChanged: (value) => selectedCategory = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (questionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a question'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (answerController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an answer'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              context.read<FlashcardProvider>().addCustomFlashcard(
                questionController.text.trim(),
                answerController.text.trim(),
                selectedCategory.trim().isEmpty ? 'General' : selectedCategory.trim(),
              );

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flashcard added!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, FlashcardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Flashcard'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this flashcard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteFlashcard(id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flashcard deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}