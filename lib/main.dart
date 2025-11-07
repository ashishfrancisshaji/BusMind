import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_theme.dart';
import 'core/router.dart';
import 'providers/app_state_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/mood_detection_provider.dart';
import 'providers/music_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/posture_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/flashcard_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register the Flashcard adapter so Hive knows how to store Flashcards
  Hive.registerAdapter(FlashcardAdapter());
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BusMindApp());
}

class BusMindApp extends StatelessWidget {
  const BusMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MoodDetectionProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => PostureProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      // 🔥 WRAP WITH BUILDER TO LINK ANALYTICS - THIS IS THE KEY CHANGE!
      child: Builder(
        builder: (context) {
          // 🔥 CONNECT ANALYTICS TO OTHER PROVIDERS
          // This runs once when app starts and links everything
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final analytics = context.read<AnalyticsProvider>();
              analytics.linkProviders(
                flashcardProvider: context.read<FlashcardProvider>(),
                musicProvider: context.read<MusicProvider>(),
                postureProvider: context.read<PostureProvider>(),
                voiceProvider: context.read<VoiceProvider>(),
                moodProvider: context.read<MoodDetectionProvider>(),
              );
              
              // ✅ START ANALYTICS SESSION - THIS IS CRITICAL!
              analytics.startStudySession();
              
              debugPrint('✅ Analytics providers linked successfully');
              debugPrint('✅ Analytics session started');
            } catch (e) {
              debugPrint('⚠️ Error linking analytics providers: $e');
            }
          });

          return Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                routerConfig: AppRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}