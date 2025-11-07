import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

enum MusicGenre {
  focus,
  relaxing,
  energizing,
  ambient,
  classical,
  lofi,
}

enum MoodCategory {
  happy,
  sad,
  angry,
  tired,
  focused,
  relaxed,
}

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 0.7;
  String _currentTrack = '';
  String? _currentMood;
  List<String> _favoriteTrackIds = [];
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;

  late Map<MoodCategory, List<Map<String, String>>> _moodPlaylists;
  List<Map<String, String>> _currentPlaylist = [];
  List<Map<String, String>> _customSongs = [];

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String get currentTrack => _currentTrack;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  List<Map<String, String>> get playlist => _currentPlaylist;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  String? get currentMood => _currentMood;

  MusicProvider() {
    _initializePlayer();
    _loadMoodPlaylists();
    _loadFavorites();
    _loadCustomSongs();
  }

  void _initializePlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _isLoading = state == PlayerState.paused;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _onTrackComplete();
    });
  }

  void _loadMoodPlaylists() {
    _moodPlaylists = {
      MoodCategory.happy: [
        {
          'id': 'happy_1',
          'title': 'Upbeat Melody',
          'artist': 'SoundHelix',
          'genre': 'energizing',
          'mood': 'happy',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'happy_2',
          'title': 'Joyful Energy',
          'artist': 'SoundHelix',
          'genre': 'energizing',
          'mood': 'happy',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'happy_3',
          'title': 'Carefree Vibes',
          'artist': 'SoundHelix',
          'genre': 'energizing',
          'mood': 'happy',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'happy_4',
          'title': 'Positive Energy',
          'artist': 'SoundHelix',
          'genre': 'energizing',
          'mood': 'happy',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
      ],

      MoodCategory.sad: [
        {
          'id': 'sad_1',
          'title': 'Calm Waters',
          'artist': 'SoundHelix',
          'genre': 'relaxing',
          'mood': 'sad',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'sad_2',
          'title': 'Gentle Comfort',
          'artist': 'SoundHelix',
          'genre': 'relaxing',
          'mood': 'sad',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'sad_3',
          'title': 'Peaceful Mind',
          'artist': 'SoundHelix',
          'genre': 'classical',
          'mood': 'sad',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'sad_4',
          'title': 'Soothing Melody',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'sad',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
      ],

      MoodCategory.angry: [
        {
          'id': 'angry_1',
          'title': 'Stress Relief',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'stressed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'angry_2',
          'title': 'Deep Breath',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'stressed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'angry_3',
          'title': 'Peaceful Mind',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'stressed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'angry_4',
          'title': 'Calm Down',
          'artist': 'SoundHelix',
          'genre': 'classical',
          'mood': 'stressed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
      ],

      MoodCategory.tired: [
        {
          'id': 'tired_1',
          'title': 'Wake Up Energy',
          'artist': 'SoundHelix',
          'genre': 'energizing',
          'mood': 'tired',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'tired_2',
          'title': 'Gentle Rest',
          'artist': 'SoundHelix',
          'genre': 'relaxing',
          'mood': 'tired',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'tired_3',
          'title': 'Morning Drive',
          'artist': 'SoundHelix',
          'genre': 'energizing',
          'mood': 'tired',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'tired_4',
          'title': 'Soft Energy',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'tired',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
      ],

      MoodCategory.focused: [
        {
          'id': 'focus_1',
          'title': 'Deep Focus',
          'artist': 'SoundHelix',
          'genre': 'focus',
          'mood': 'focused',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'focus_2',
          'title': 'Study Lofi',
          'artist': 'SoundHelix',
          'genre': 'lofi',
          'mood': 'focused',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'focus_3',
          'title': 'Concentration',
          'artist': 'SoundHelix',
          'genre': 'focus',
          'mood': 'focused',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'focus_4',
          'title': 'Flow State',
          'artist': 'SoundHelix',
          'genre': 'classical',
          'mood': 'focused',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
      ],

      MoodCategory.relaxed: [
        {
          'id': 'relax_1',
          'title': 'Ambient Space',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'relaxed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'relax_2',
          'title': 'Night Sky',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'relaxed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'relax_3',
          'title': 'Peaceful Thoughts',
          'artist': 'SoundHelix',
          'genre': 'ambient',
          'mood': 'relaxed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
        {
          'id': 'relax_4',
          'title': 'Tranquil State',
          'artist': 'SoundHelix',
          'genre': 'relaxing',
          'mood': 'relaxed',
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
          'duration': '360',
          'isCustom': 'false',
          'isLocalFile': 'false',
        },
      ],
    };

    _currentPlaylist = _moodPlaylists[MoodCategory.focused]!;
  }

  Future<void> _loadCustomSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customSongsJson = prefs.getString('custom_songs');
      if (customSongsJson != null) {
        final List<dynamic> decoded = jsonDecode(customSongsJson);
        _customSongs = decoded.map((e) => Map<String, String>.from(e)).toList();
        _mergeCustomSongsIntoPlaylists();
        debugPrint('✅ Loaded ${_customSongs.length} custom songs');
      }
    } catch (e) {
      debugPrint('Error loading custom songs: $e');
    }
  }

  Future<void> _saveCustomSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_songs', jsonEncode(_customSongs));
      debugPrint('✅ Saved ${_customSongs.length} custom songs');
    } catch (e) {
      debugPrint('Error saving custom songs: $e');
    }
  }

  void _mergeCustomSongsIntoPlaylists() {
    for (final song in _customSongs) {
      final moodCategory = _mapEmotionToMoodCategory(song['mood']!);
      if (!_moodPlaylists[moodCategory]!.any((s) => s['id'] == song['id'])) {
        _moodPlaylists[moodCategory]!.add(song);
      }
    }
    if (_currentMood != null) {
      final moodCategory = _mapEmotionToMoodCategory(_currentMood!);
      _currentPlaylist = _moodPlaylists[moodCategory]!;
    }
  }

  Future<void> addCustomSong({
    required String title,
    required String artist,
    required String url,
    required String mood,
    required String genre,
    bool isLocalFile = false,
  }) async {
    final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    
    final newSong = {
      'id': customId,
      'title': title,
      'artist': artist,
      'genre': genre,
      'mood': mood,
      'url': url,
      'duration': '180',
      'isCustom': 'true',
      'isLocalFile': isLocalFile.toString(),
    };

    _customSongs.add(newSong);
    await _saveCustomSongs();
    
    final moodCategory = _mapEmotionToMoodCategory(mood);
    _moodPlaylists[moodCategory]!.add(newSong);
    
    if (_currentMood != null) {
      final currentMoodCategory = _mapEmotionToMoodCategory(_currentMood!);
      _currentPlaylist = _moodPlaylists[currentMoodCategory]!;
    } else {
      _currentPlaylist = _moodPlaylists[MoodCategory.focused]!;
    }
    
    debugPrint('✅ Added custom song: $title to $mood playlist (${isLocalFile ? "Local" : "URL"})');
    debugPrint('📊 Total custom songs: ${_customSongs.length}');
    debugPrint('📊 Total tracks in ${moodCategory.name}: ${_moodPlaylists[moodCategory]!.length}');
    
    notifyListeners();
  }

  Future<void> deleteCustomSong(String trackId) async {
    _customSongs.removeWhere((song) => song['id'] == trackId);
    await _saveCustomSongs();
    
    for (final playlist in _moodPlaylists.values) {
      playlist.removeWhere((song) => song['id'] == trackId);
    }
    
    if (_currentMood != null) {
      final moodCategory = _mapEmotionToMoodCategory(_currentMood!);
      _currentPlaylist = _moodPlaylists[moodCategory]!;
    }
    
    final currentTrackId = _currentPlaylist
        .where((song) => song['title'] == _currentTrack)
        .map((song) => song['id'])
        .firstOrNull;
    
    if (currentTrackId == trackId) {
      await stop();
    }
    
    debugPrint('🗑️ Deleted custom song: $trackId');
    notifyListeners();
  }

  Future<void> updateMoodBasedMusic(String emotion) async {
    debugPrint('🎵 Updating music for emotion: $emotion');
    _currentMood = emotion;
    
    final moodCategory = _mapEmotionToMoodCategory(emotion);
    _currentPlaylist = _moodPlaylists[moodCategory]!;
    
    debugPrint('🎵 Switched to ${moodCategory.name} playlist (${_currentPlaylist.length} tracks)');
    
    if (!_isPlaying && _currentPlaylist.isNotEmpty) {
      await playTrack(_currentPlaylist.first['id']!);
    }
    
    notifyListeners();
  }

  MoodCategory _mapEmotionToMoodCategory(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return MoodCategory.happy;
      case 'sad':
        return MoodCategory.sad;
      case 'angry':
      case 'stressed':
        return MoodCategory.angry;
      case 'tired':
        return MoodCategory.tired;
      case 'focused':
      case 'neutral':
      case 'unknown':
        return MoodCategory.focused;
      case 'relaxed':
        return MoodCategory.relaxed;
      default:
        debugPrint('⚠️ Unknown emotion: $emotion, defaulting to focused');
        return MoodCategory.focused;
    }
  }

  List<Map<String, String>> getRecommendationsForMood(String mood) {
    final moodCategory = _mapEmotionToMoodCategory(mood);
    return _moodPlaylists[moodCategory] ?? [];
  }

  List<Map<String, String>> getAllTracks() {
    final allTracks = <Map<String, String>>[];
    final seenIds = <String>{};
    
    for (final playlist in _moodPlaylists.values) {
      for (final track in playlist) {
        if (!seenIds.contains(track['id'])) {
          allTracks.add(track);
          seenIds.add(track['id']!);
        }
      }
    }
    
    return allTracks;
  }

  Future<void> playTrack(String trackId) async {
    _isLoading = true;
    notifyListeners();

    try {
      Map<String, String>? track = _currentPlaylist.cast<Map<String, String>?>().firstWhere(
        (t) => t!['id'] == trackId,
        orElse: () => null,
      );

      if (track == null) {
        for (final playlist in _moodPlaylists.values) {
          try {
            track = playlist.firstWhere((t) => t['id'] == trackId);
            break;
          } catch (e) {
            continue;
          }
        }
      }

      if (track == null) {
        debugPrint('❌ Track not found: $trackId');
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentTrack = track['title']!;

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      final isLocalFile = track['isLocalFile'] == 'true';
      final audioSource = track['url']!;
      
      debugPrint('▶️ Setting audio source (${isLocalFile ? "Local" : "URL"}): $audioSource');
      
      if (isLocalFile) {
        await _audioPlayer.setSourceDeviceFile(audioSource).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Failed to load local audio in 10 seconds');
          },
        );
      } else {
        await _audioPlayer.setSourceUrl(audioSource).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Failed to load audio in 10 seconds');
          },
        );
      }
      
      debugPrint('▶️ Starting playback...');
      await _audioPlayer.resume().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Failed to start playback in 5 seconds');
        },
      );

      _isPlaying = true;
      _isLoading = false;
      _duration = Duration(seconds: int.parse(track['duration']!));

      await _saveRecentPlay(trackId);
      
      debugPrint('✅ Playing: ${track['title']} (${track['mood']})');
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      debugPrint('❌ Error playing track: $e');
      
      if (e.toString().contains('Timeout')) {
        debugPrint('⚠️ Network timeout - check internet connection');
      } else if (e.toString().contains('AndroidAudioError')) {
        debugPrint('⚠️ Audio format not supported or network issue');
      } else if (e.toString().contains('FileSystemException')) {
        debugPrint('⚠️ Local file not found or not accessible');
      }
    }

    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _currentTrack = '';
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
    _position = position;
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  Future<void> toggleFavorite(String trackId) async {
    if (_favoriteTrackIds.contains(trackId)) {
      _favoriteTrackIds.remove(trackId);
    } else {
      _favoriteTrackIds.add(trackId);
    }
    await _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String trackId) {
    return _favoriteTrackIds.contains(trackId);
  }

  List<Map<String, String>> getFavorites() {
    final allTracks = getAllTracks();
    return allTracks.where((track) => _favoriteTrackIds.contains(track['id'])).toList();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorite_tracks');
      if (favoritesJson != null) {
        _favoriteTrackIds = List<String>.from(jsonDecode(favoritesJson));
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorite_tracks', jsonEncode(_favoriteTrackIds));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _saveRecentPlay(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentPlays = prefs.getStringList('recent_plays') ?? [];

      recentPlays.remove(trackId);
      recentPlays.insert(0, trackId);

      if (recentPlays.length > 20) {
        recentPlays = recentPlays.take(20).toList();
      }

      await prefs.setStringList('recent_plays', recentPlays);
    } catch (e) {
      debugPrint('Error saving recent play: $e');
    }
  }

  Future<void> playNext() async {
    if (_currentPlaylist.isEmpty) return;

    int currentIndex = _currentPlaylist.indexWhere((track) => track['title'] == _currentTrack);
    int nextIndex;

    if (_isShuffleEnabled) {
      nextIndex = DateTime.now().millisecondsSinceEpoch % _currentPlaylist.length;
    } else {
      nextIndex = (currentIndex + 1) % _currentPlaylist.length;
    }

    await playTrack(_currentPlaylist[nextIndex]['id']!);
  }

  Future<void> playPrevious() async {
    if (_currentPlaylist.isEmpty) return;

    int currentIndex = _currentPlaylist.indexWhere((track) => track['title'] == _currentTrack);
    int previousIndex;

    if (_isShuffleEnabled) {
      previousIndex = DateTime.now().millisecondsSinceEpoch % _currentPlaylist.length;
    } else {
      previousIndex = (currentIndex - 1 + _currentPlaylist.length) % _currentPlaylist.length;
    }

    await playTrack(_currentPlaylist[previousIndex]['id']!);
  }

  void _onTrackComplete() {
    if (_isRepeatEnabled) {
      final currentTrackId = _currentPlaylist.firstWhere(
        (track) => track['title'] == _currentTrack,
        orElse: () => {},
      )['id'];
      if (currentTrackId != null) {
        playTrack(currentTrackId);
      }
    } else {
      playNext();
    }
  }

  String get formattedCurrentPosition => _formatDuration(_position);
  String get formattedTotalDuration => _formatDuration(_duration);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}