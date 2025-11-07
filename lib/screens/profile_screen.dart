import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mood_detection_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/posture_provider.dart';
import '../providers/voice_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Profile',
        showBackButton: true,
      ),
      body: Consumer5<AppStateProvider, FlashcardProvider, PostureProvider,
          VoiceProvider, MoodDetectionProvider>(
        builder: (context, appState, flashcard, posture, voice, mood, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 30),
                _buildStatsOverview(flashcard, posture, voice),
                const SizedBox(height: 30),
                _buildSettingsSection(appState),
                const SizedBox(height: 30),
                _buildAboutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
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
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                authProvider.userName ?? 'BusMind User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                authProvider.userEmail ?? 'user@busmind.com',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsOverview(FlashcardProvider flashcard, PostureProvider posture, VoiceProvider voice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Flashcards',
                '${flashcard.flashcards.length}',
                Icons.quiz,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Summaries',
                '${voice.totalSummaries}',
                Icons.record_voice_over,
                AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Good Posture',
                '${(posture.goodPosturePercentage * 100).toInt()}%',
                Icons.accessibility_new,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Study Time',
                _formatDuration(voice.totalRecordingTime),
                Icons.timer,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
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
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark themes'),
                value: appState.isDarkMode,
                onChanged: (value) => appState.toggleDarkMode(),
                secondary: const Icon(Icons.dark_mode),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Manage app notifications'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to notifications settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy'),
                subtitle: const Text('Data and privacy settings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to privacy settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup & Sync'),
                subtitle: const Text('Backup your data to cloud'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to backup settings
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
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
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show version info
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and contact support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to help
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Rate App'),
                subtitle: const Text('Rate BusMind on the app store'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Open app store rating
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share App'),
                subtitle: const Text('Share BusMind with friends'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Share app
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.9)!,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 30,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'BusMind',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'AI-Powered Productivity for Your Commute',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                '© 2024 BusMind. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
