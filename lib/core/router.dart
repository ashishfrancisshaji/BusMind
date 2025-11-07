import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/mood_detection_screen.dart';
import '../screens/music_screen.dart';
import '../screens/flashcards_screen.dart';
import '../screens/posture_screen.dart';
import '../screens/voice_summary_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      
      // If not authenticated and not on auth or splash screen, redirect to auth
      if (!isAuthenticated && 
          state.uri.toString() != '/auth' && 
          state.uri.toString() != '/splash') {
        return '/auth';
      }
      
      // If authenticated and on auth screen, redirect to home
      if (isAuthenticated && state.uri.toString() == '/auth') {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mood-detection',
        name: 'mood-detection',
        builder: (context, state) => const MoodDetectionScreen(),
      ),
      GoRoute(
        path: '/music',
        name: 'music',
        builder: (context, state) => const MusicScreen(),
      ),
      GoRoute(
        path: '/flashcards',
        name: 'flashcards',
        builder: (context, state) => const FlashcardsScreen(),
      ),
      GoRoute(
        path: '/posture',
        name: 'posture',
        builder: (context, state) => const PostureScreen(),
      ),
      GoRoute(
        path: '/voice-summary',
        name: 'voice-summary',
        builder: (context, state) => const VoiceSummaryScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
  );
}
