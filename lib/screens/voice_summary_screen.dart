import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/flashcard_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_tracker.dart'; // ✅ ADDED

class VoiceSummaryScreen extends StatefulWidget {
  const VoiceSummaryScreen({super.key});

  @override
  State<VoiceSummaryScreen> createState() => _VoiceSummaryScreenState();
}

class _VoiceSummaryScreenState extends State<VoiceSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'AI Summarizer',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Consumer<VoiceProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildRecordingSection(provider),
              const SizedBox(height: 20),
              _buildExternalInputs(provider),
              const SizedBox(height: 20),
              Expanded(
                child: _buildSummariesList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingSection(VoiceProvider provider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.9)!,
            Color.lerp(AppTheme.secondaryColor, Colors.transparent, 0.9)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.8)!),
      ),
      child: Column(
        children: [
          if (provider.recordingState == RecordingState.idle) ...[
            const Icon(
              Icons.mic_none,
              size: 60,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 15),
            const Text(
              'Ready to Record',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the microphone to start recording your lecture',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ] else if (provider.recordingState == RecordingState.recording) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                _pulseController.repeat(reverse: true);
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            const Text(
              'Recording...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.formattedRecordingDuration,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            if (provider.currentTranscription.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.currentTranscription,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ] else if (provider.recordingState == RecordingState.processing) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 15),
            const Text(
              'Processing...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI is generating your summary',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ] else if (provider.recordingState == RecordingState.completed) ...[
            const Icon(
              Icons.check_circle,
              size: 60,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 15),
            const Text(
              'Summary Complete!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (provider.recordingState == RecordingState.idle)
                ElevatedButton.icon(
                  onPressed: provider.startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                )
              else if (provider.recordingState == RecordingState.recording)
                ElevatedButton.icon(
                  onPressed: () async {
                    await provider.stopRecording();
                    
                    // ✅ TRACK VOICE RECORDING IN ANALYTICS
                    if (provider.recordingState == RecordingState.completed) {
                      AnalyticsTracker.trackVoice(context);
                      debugPrint('📊 ✅ Tracked voice recording in analytics');
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recording saved and tracked!'),
                          backgroundColor: AppTheme.successColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummariesList(VoiceProvider provider) {
    if (provider.summaries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.record_voice_over_outlined,
                size: 80,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 20),
              Text(
                'No summaries yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Record your first lecture to get AI-powered summaries with key points',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Summaries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${provider.totalSummaries} total',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.summaries.length,
            itemBuilder: (context, index) {
              final summary = provider.summaries[index];
              return _buildSummaryCard(summary, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(VoiceSummary summary, VoiceProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color.lerp(AppTheme.warningColor, Colors.transparent, 0.9)!,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.record_voice_over,
            color: AppTheme.warningColor,
          ),
        ),
        title: Text(
          summary.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              _formatDuration(summary.duration),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(summary.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              provider.deleteSummary(summary.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.95)!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    summary.summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Key Points',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...summary.keyPoints.map((point) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.lerp(AppTheme.successColor, Colors.transparent, 0.95)!,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color.lerp(AppTheme.successColor, Colors.transparent, 0.8)!,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFullTranscript(summary),
                        icon: const Icon(Icons.article_outlined),
                        label: const Text('View Full Transcript'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _generateFlashcards(summary),
                      icon: const Icon(Icons.quiz),
                      label: const Text('Create Cards'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Summaries'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.of(context).pop();
            // Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFullTranscript(VoiceSummary summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(summary.title),
        content: SingleChildScrollView(
          child: Text(
            summary.originalText,
            style: const TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _generateFlashcards(VoiceSummary summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Flashcards'),
        content: const Text(
          'This will create flashcards from the summary and key points. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final sourceText = '${summary.summary}\n${summary.keyPoints.join('. ')}';
              context.read<FlashcardProvider>().generateFlashcardsFromText(sourceText, category: 'Summaries');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flashcards generated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalInputs(VoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showUrlSummarizerDialog,
              icon: const Icon(Icons.link),
              label: const Text('Summarize URL'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showDocumentSummarizerDialog,
              icon: const Icon(Icons.insert_drive_file),
              label: const Text('Summarize Document'),
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlSummarizerDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL Summarizer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Paste YouTube/article URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              Navigator.of(context).pop();
              if (url.isNotEmpty) {
                context.read<VoiceProvider>().summarizeFromUrl(url);
              }
            },
            child: const Text('Summarize'),
          ),
        ],
      ),
    );
  }

  void _showDocumentSummarizerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Summarizer'),
        content: const Text('Select a PDF/PPT file to summarize (simulated).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VoiceProvider>().summarizeFromDocument();
            },
            child: const Text('Pick & Summarize'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}