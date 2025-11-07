import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/music_provider.dart';
import '../providers/mood_detection_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_tracker.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer2<MusicProvider, MoodDetectionProvider>(
        builder: (context, musicProvider, moodProvider, child) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(musicProvider),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildNowPlaying(musicProvider),
                    const SizedBox(height: 30),
                    _buildMoodBasedRecommendations(musicProvider, moodProvider),
                    const SizedBox(height: 30),
                    _buildPlaylist(musicProvider),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(MusicProvider provider) {
    return CustomSliverAppBar(
      title: 'Smart Music',
      showBackButton: true,
      expandedHeight: 200,
      pinned: true,
      floating: false,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Smart Music',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.music_note,
              size: 80,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlaying(MusicProvider provider) {
    if (provider.currentTrack.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
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
        child: const Column(
          children: [
            Icon(
              Icons.music_off,
              size: 60,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 15),
            Text(
              'No music playing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Select a track to start listening',
              style: TextStyle(
                fontSize: 14,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.9)!,
            Color.lerp(AppTheme.secondaryColor, Colors.transparent, 0.9)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.8)!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.currentTrack,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Unknown Artist',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.formattedCurrentPosition,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    provider.formattedTotalDuration,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: provider.progress.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * provider.duration.inMilliseconds).round(),
                    );
                    provider.seekTo(newPosition);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: provider.playPrevious,
                icon: const Icon(Icons.skip_previous),
                iconSize: 30,
                color: AppTheme.primaryColor,
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: provider.isPlaying ? provider.pause : provider.resume,
                  icon: Icon(
                    provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 30,
                ),
              ),
              IconButton(
                onPressed: provider.playNext,
                icon: const Icon(Icons.skip_next),
                iconSize: 30,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBasedRecommendations(MusicProvider musicProvider, MoodDetectionProvider moodProvider) {
    final recommendations = musicProvider.getRecommendationsForMood(moodProvider.currentMood.name);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final moodName = moodProvider.currentMood.name.toLowerCase();
    final displayTitle = moodName == 'unknown' || moodName == 'neutral' 
        ? 'For You' 
        : 'Recommended for ${moodProvider.currentMood.name}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              moodProvider.getMoodIcon(),
              color: moodProvider.getMoodColor(),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final track = recommendations[index];
              return Padding(
                padding: const EdgeInsets.only(right: 15, bottom: 5),
                child: SizedBox(
                  width: 200,
                  child: _buildTrackCard(track, musicProvider),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylist(MusicProvider provider) {
    final allTracks = provider.getAllTracks();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Tracks (${allTracks.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddSongDialog(context, provider),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allTracks.length,
          itemBuilder: (context, index) {
            final track = allTracks[index];
            final isCurrentTrack = provider.currentTrack == track['title'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isCurrentTrack 
                    ? Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.9)!
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: isCurrentTrack 
                    ? Border.all(color: Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.7)!)
                    : null,
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getGenreColorFromString(track['genre']!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  track['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCurrentTrack ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${track['artist']!} • ${track['genre']!}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrentTrack && provider.isPlaying)
                      const Icon(
                        Icons.equalizer,
                        color: AppTheme.primaryColor,
                      ),
                    if (track['isCustom'] == 'true')
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteSong(context, provider, track['id']!),
                      ),
                  ],
                ),
                // ✅ UPDATED: Track music when song starts playing
                onTap: () async {
                  final trackId = track['id']!;
                  await provider.playTrack(trackId);
                  
                  // Wait a moment for playback to start
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  // ✅ TRACK if song is actually playing
                  if (provider.isPlaying && provider.currentTrack == track['title']) {
                    AnalyticsTracker.trackSong(context);
                    debugPrint('📊 ✅ Tracked song: ${track['title']}');
                    
                    // Show subtle feedback
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Now playing: ${track['title']}'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.purple.shade600,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrackCard(Map<String, String> track, MusicProvider provider) {
    final isCustom = track['isCustom'] == 'true';
    
    return GestureDetector(
      onTap: () async {
        final trackId = track['id']!;
        await provider.playTrack(trackId);
        
        // Wait a moment for playback to start
        await Future.delayed(const Duration(milliseconds: 500));
        
        // ✅ TRACK if song is actually playing from recommendations
        if (provider.isPlaying && provider.currentTrack == track['title']) {
          AnalyticsTracker.trackSong(context);
          debugPrint('📊 ✅ Tracked song (recommendation): ${track['title']}');
          
          // Show subtle feedback
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Now playing: ${track['title']}'),
                  ),
                ],
              ),
              backgroundColor: Colors.purple.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getGenreColorFromString(track['genre']!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (isCustom)
                  GestureDetector(
                    onTap: () => _confirmDeleteSong(context, provider, track['id']!),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              track['title']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              track['artist']!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isCustom)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 10, color: AppTheme.accentColor),
                    SizedBox(width: 2),
                    Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context, MusicProvider provider) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    String selectedMood = 'happy';
    String selectedGenre = 'energizing';
    String? selectedFilePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Song'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Song Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.music_note),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(
                    labelText: 'Artist Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.audio,
                        allowMultiple: false,
                      );
                      
                      if (result != null) {
                        final path = result.files.single.path;
                        
                        if (path != null && path.isNotEmpty) {
                          setState(() {
                            selectedFilePath = path;
                          });
                          debugPrint('✅ Selected file: $path');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not access file path')),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('❌ Error picking file: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error picking file: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.folder_open),
                  label: Text(selectedFilePath == null ? 'Pick Audio File' : 'Change File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                if (selectedFilePath != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFilePath!.split('/').last,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'Mood Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'happy', child: Text('😊 Happy')),
                    DropdownMenuItem(value: 'sad', child: Text('😢 Sad')),
                    DropdownMenuItem(value: 'angry', child: Text('😤 Stressed')),
                    DropdownMenuItem(value: 'tired', child: Text('😴 Tired')),
                    DropdownMenuItem(value: 'focused', child: Text('🎯 Focused')),
                    DropdownMenuItem(value: 'relaxed', child: Text('😌 Relaxed')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMood = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGenre,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.library_music),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'energizing', child: Text('⚡ Energizing')),
                    DropdownMenuItem(value: 'relaxing', child: Text('🌊 Relaxing')),
                    DropdownMenuItem(value: 'ambient', child: Text('🌌 Ambient')),
                    DropdownMenuItem(value: 'classical', child: Text('🎻 Classical')),
                    DropdownMenuItem(value: 'lofi', child: Text('📻 Lo-fi')),
                    DropdownMenuItem(value: 'focus', child: Text('🎧 Focus')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedGenre = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final hasTitle = titleController.text.isNotEmpty;
                final hasArtist = artistController.text.isNotEmpty;
                final hasFile = selectedFilePath != null;

                if (hasTitle && hasArtist && hasFile) {
                  await provider.addCustomSong(
                    title: titleController.text,
                    artist: artistController.text,
                    url: selectedFilePath!,
                    mood: selectedMood,
                    genre: selectedGenre,
                    isLocalFile: true,
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ "${titleController.text}" added successfully!'),
                      backgroundColor: AppTheme.successColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields and select an audio file'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Add Song'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSong(BuildContext context, MusicProvider provider, String trackId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: const Text('Are you sure you want to delete this song?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteCustomSong(trackId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Song deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getGenreColorFromString(String genre) {
    switch (genre.toLowerCase()) {
      case 'focus':
        return AppTheme.primaryColor;
      case 'relaxing':
        return AppTheme.secondaryColor;
      case 'energizing':
        return AppTheme.accentColor;
      case 'ambient':
        return AppTheme.successColor;
      case 'classical':
        return AppTheme.warningColor;
      case 'lofi':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }
}