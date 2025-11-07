import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/mood_detection_provider.dart';
import '../providers/music_provider.dart';
import '../services/ml_service.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_tracker.dart'; // ✅ ADDED

class MoodDetectionScreen extends StatefulWidget {
  const MoodDetectionScreen({super.key});

  @override
  State<MoodDetectionScreen> createState() => _MoodDetectionScreenState();
}

class _MoodDetectionScreenState extends State<MoodDetectionScreen> {
  bool _apiTested = false;
  String _apiStatus = 'Checking...';
  bool _musicUpdated = false;
  String _currentPlaylist = '';
  
  // ✅ ADDED: Track if we've already tracked this mood detection
  String? _lastTrackedMood;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final provider = context.read<MoodDetectionProvider>();
    
    // Initialize camera
    await provider.initializeCamera();
    
    // Test API connection
    final result = await MLService.testAPIConnection();
    setState(() {
      _apiTested = true;
      _apiStatus = result['message'] ?? 'Unknown';
    });
    
    if (result['success'] == true) {
      debugPrint('✅ API is ready');
    } else {
      debugPrint('⚠️ API not available: ${result['message']}');
    }
  }

  /// 🎵 MUSIC INTEGRATION - Called after successful mood detection
  Future<void> _handleMoodDetectionComplete(MoodDetectionProvider moodProvider) async {
    if (moodProvider.currentMood == MoodState.unknown) return;

    final musicProvider = context.read<MusicProvider>();
    final emotion = moodProvider.currentMood.name;

    debugPrint('🎵 ========================================');
    debugPrint('🎵 MUSIC CHANGE TRIGGERED');
    debugPrint('🎵 Detected emotion: $emotion');
    debugPrint('🎵 Confidence: ${(moodProvider.confidence * 100).toInt()}%');
    
    // Update music based on detected emotion
    await musicProvider.updateMoodBasedMusic(emotion);
    
    setState(() {
      _musicUpdated = true;
      _currentPlaylist = emotion;
    });

    debugPrint('🎵 Music provider updated successfully');
    debugPrint('🎵 Current mood in music provider: ${musicProvider.currentMood}');
    debugPrint('🎵 Current playlist size: ${musicProvider.playlist.length}');
    debugPrint('🎵 Now playing: ${musicProvider.currentTrack}');
    debugPrint('🎵 Is playing: ${musicProvider.isPlaying}');
    debugPrint('🎵 ========================================');

    // Show success notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getMoodMusicIcon(emotion),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎵 Music Updated!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Playing ${_getMoodPlaylistName(emotion)} music',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (musicProvider.isPlaying)
                const Icon(Icons.equalizer, color: Colors.white),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to music screen
              Navigator.pushNamed(context, '/music');
            },
          ),
        ),
      );
    }
  }

  IconData _getMoodMusicIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return Icons.sentiment_very_satisfied;
      case 'sad': return Icons.sentiment_dissatisfied;
      case 'angry': return Icons.self_improvement;
      case 'tired': return Icons.bedtime;
      case 'focused': return Icons.psychology;
      default: return Icons.music_note;
    }
  }

  String _getMoodPlaylistName(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return 'upbeat & energetic';
      case 'sad': return 'calming & comforting';
      case 'angry': return 'relaxing & stress-relief';
      case 'stressed': return 'peaceful & calming';
      case 'tired': return 'energizing';
      case 'focused': return 'focus & concentration';
      default: return 'ambient';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Mood Detection',
        showBackButton: true,
      ),
      body: Consumer2<MoodDetectionProvider, MusicProvider>(
        builder: (context, moodProvider, musicProvider, child) {
          // ✅ FIXED: Track mood when detection completes (only once per detection)
          if (moodProvider.currentMood != MoodState.unknown && 
              !moodProvider.isDetecting &&
              _lastTrackedMood != moodProvider.currentMood.name) {
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final emotion = moodProvider.currentMood.name;
              
              // ✅ TRACK MOOD IN ANALYTICS
              AnalyticsTracker.trackMood(context, emotion);
              debugPrint('📊 ✅ Tracked mood: $emotion (${(moodProvider.confidence * 100).toInt()}%)');
              
              // Update last tracked mood to prevent duplicate tracking
              setState(() {
                _lastTrackedMood = emotion;
              });
              
              // Then update music
              _handleMoodDetectionComplete(moodProvider);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusCard(moodProvider, musicProvider),
                const SizedBox(height: 20),
                _buildCameraPreview(moodProvider),
                const SizedBox(height: 20),
                _buildMoodResult(moodProvider),
                if (moodProvider.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildErrorCard(moodProvider),
                ],
                if (_musicUpdated) ...[
                  const SizedBox(height: 20),
                  _buildMusicStatusCard(musicProvider),
                ],
                const SizedBox(height: 20),
                _buildRecommendations(moodProvider),
                const SizedBox(height: 20),
                _buildActionButton(moodProvider),
                const SizedBox(height: 20),
                _buildDebugInfo(moodProvider, musicProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(MoodDetectionProvider provider, MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            provider.isCameraReady ? Icons.check_circle : Icons.info_outline,
            color: provider.isCameraReady ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            provider.isCameraReady ? 'Camera Ready' : 'Initializing Camera...',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 🎵 NEW: Music Status Card
  Widget _buildMusicStatusCard(MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Music Playlist Updated',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_getMoodPlaylistName(_currentPlaylist)} (${musicProvider.playlist.length} tracks)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (musicProvider.isPlaying)
                const Icon(
                  Icons.equalizer,
                  color: Colors.green,
                  size: 28,
                ),
            ],
          ),
          if (musicProvider.currentTrack.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    musicProvider.isPlaying ? Icons.play_circle_filled : Icons.pause_circle_filled,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musicProvider.currentTrack,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${musicProvider.formattedCurrentPosition} / ${musicProvider.formattedTotalDuration}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraPreview(MoodDetectionProvider provider) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: provider.isCameraReady
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(provider.cameraController!),
                  if (provider.isDetecting)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isInitializing) ...[
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Initializing Camera...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Camera not available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => provider.initializeCamera(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMoodResult(MoodDetectionProvider provider) {
    if (provider.currentMood == MoodState.unknown && !provider.isDetecting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 50,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 15),
            Text(
              'Tap "Detect Mood" to analyze your emotional state',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.isDetecting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              'Analyzing your mood...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take 20-30 seconds on first use',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.lerp(provider.getMoodColor(), Colors.transparent, 0.9)!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.lerp(provider.getMoodColor(), Colors.transparent, 0.7)!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider.getMoodIcon(),
                size: 40,
                color: provider.getMoodColor(),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.currentMood.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: provider.getMoodColor(),
                    ),
                  ),
                  Text(
                    'Confidence: ${(provider.confidence * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            provider.moodDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Detected ${provider.getLastDetectionTime()}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(MoodDetectionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.errorMessage,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(MoodDetectionProvider provider) {
    if (provider.recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        ...provider.recommendations.map((recommendation) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButton(MoodDetectionProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isDetecting || !provider.isCameraReady
            ? null
            : () async {
                // ✅ Reset tracking when starting new detection
                setState(() {
                  _lastTrackedMood = null;
                });
                await provider.startMoodDetection();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          provider.isDetecting 
              ? 'Detecting...' 
              : !provider.isCameraReady 
                  ? 'Camera Not Ready'
                  : 'Detect Mood',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo(MoodDetectionProvider provider, MusicProvider musicProvider) {
    return ExpansionTile(
      title: const Text(
        'Debug Info',
        style: TextStyle(fontSize: 14),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _debugRow('API Configured', MLService.isAPIConfigured.toString()),
              _debugRow('Current Mode', MLService.currentMode),
              _debugRow('Camera Ready', provider.isCameraReady.toString()),
              _debugRow('Is Detecting', provider.isDetecting.toString()),
              _debugRow('Current Mood', provider.currentMood.name),
              _debugRow('Confidence', '${(provider.confidence * 100).toInt()}%'),
              _debugRow('Last Tracked', _lastTrackedMood ?? 'none'),
              const Divider(),
              const Text('🎵 Music Debug:', style: TextStyle(fontWeight: FontWeight.bold)),
              _debugRow('Music Updated', _musicUpdated.toString()),
              _debugRow('Current Playlist', musicProvider.currentMood ?? 'none'),
              _debugRow('Playlist Size', musicProvider.playlist.length.toString()),
              _debugRow('Is Playing', musicProvider.isPlaying.toString()),
              _debugRow('Current Track', musicProvider.currentTrack.isEmpty ? 'none' : musicProvider.currentTrack),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Testing API...')),
                    );
                    final result = await MLService.testAPIConnection();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Test complete'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test API'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}