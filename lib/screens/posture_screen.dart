import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // ✅ ADDED
import '../providers/posture_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_tracker.dart'; // ✅ ADDED

class PostureScreen extends StatefulWidget {
  const PostureScreen({super.key});

  @override
  State<PostureScreen> createState() => _PostureScreenState();
}

class _PostureScreenState extends State<PostureScreen> {
  Timer? _analyticsTimer; // ✅ ADDED - Timer for analytics tracking

  @override
  void dispose() {
    _analyticsTimer?.cancel(); // ✅ ADDED - Clean up timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Posture Monitor',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Consumer<PostureProvider>(
        builder: (context, provider, child) {
          // FIXED: Wrap everything in SingleChildScrollView to prevent overflow
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCurrentStatus(provider),
                const SizedBox(height: 20),
                _buildStatistics(provider),
                const SizedBox(height: 20),
                _buildPostureVisualization(provider),
                const SizedBox(height: 20),
                _buildActionButton(provider),
                const SizedBox(height: 20), // Extra padding at bottom
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStatus(PostureProvider provider) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Color.lerp(provider.getPostureColor(), Colors.transparent, 0.9)!,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(provider.getPostureColor(), Colors.transparent, 0.7)!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            provider.getPostureIcon(),
            size: 60,
            color: provider.getPostureColor(),
          ),
          const SizedBox(height: 15),
          Text(
            provider.currentPosture.name.toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: provider.getPostureColor(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            provider.getPostureDescription(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          if (provider.isMonitoring) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color.lerp(AppTheme.successColor, Colors.transparent, 0.9)!,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MONITORING ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
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

  Widget _buildStatistics(PostureProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Good Posture',
            '${(provider.goodPosturePercentage * 100).toInt()}%',
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Alerts Today',
            '${provider.alertCount}',
            Icons.warning,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Session Time',
            _formatDuration(provider.monitoringDuration),
            Icons.timer,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostureVisualization(PostureProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posture Guide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 15),
          _buildPostureGuideItem(
            'Sit up straight',
            'Keep your back against the chair',
            Icons.accessibility_new,
            AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _buildPostureGuideItem(
            'Feet flat on floor',
            'Both feet should touch the ground',
            Icons.directions_walk,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildPostureGuideItem(
            'Screen at eye level',
            'Avoid looking down at your device',
            Icons.visibility,
            AppTheme.secondaryColor,
          ),
          const SizedBox(height: 12),
          _buildPostureGuideItem(
            'Shoulders relaxed',
            'Don\'t hunch your shoulders',
            Icons.self_improvement,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPostureGuideItem(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color.lerp(color, Colors.transparent, 0.9)!,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED WITH ANALYTICS TRACKING
  Widget _buildActionButton(PostureProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (provider.isMonitoring) {
            await provider.stopMonitoring();
            _analyticsTimer?.cancel(); // ✅ Stop tracking when monitoring stops
            debugPrint('📊 Stopped posture analytics tracking');
          } else {
            await provider.startMonitoring();
            // ✅ START ANALYTICS TRACKING
            _startPostureTracking(provider);
            debugPrint('📊 Started posture analytics tracking');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.isMonitoring 
              ? AppTheme.errorColor 
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          provider.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ✅ NEW METHOD - Track posture every 30 seconds
  void _startPostureTracking(PostureProvider provider) {
    _analyticsTimer?.cancel();
    
    // Track immediately when starting
    AnalyticsTracker.trackPosture(context, provider.goodPosturePercentage);
    
    // Then track every 30 seconds
    _analyticsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!provider.isMonitoring) {
        timer.cancel();
        debugPrint('📊 Posture tracking timer cancelled - monitoring stopped');
        return;
      }
      
      // Track posture score
      AnalyticsTracker.trackPosture(context, provider.goodPosturePercentage);
      debugPrint('📊 Tracked posture: ${(provider.goodPosturePercentage * 100).toInt()}%');
    });
  }

  void _showSettingsDialog() {
    final provider = context.read<PostureProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Posture Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sensitivity'),
                subtitle: Slider(
                  value: provider.sensitivityThreshold,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(provider.sensitivityThreshold * 100).toInt()}%',
                  onChanged: (value) {
                    provider.setSensitivity(value);
                    // Force rebuild of dialog
                    (context as Element).markNeedsBuild();
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Vibrate on Alert'),
                value: provider.vibrateOnAlert,
                onChanged: (value) {
                  provider.setVibrateOnAlert(value);
                  (context as Element).markNeedsBuild();
                },
              ),
              SwitchListTile(
                title: const Text('Sound on Alert'),
                value: provider.soundOnAlert,
                onChanged: (value) {
                  provider.setSoundOnAlert(value);
                  (context as Element).markNeedsBuild();
                },
              ),
              ListTile(
                title: const Text('Alert Interval'),
                subtitle: Text('${provider.alertInterval.inMinutes} minutes'),
                trailing: DropdownButton<int>(
                  value: provider.alertInterval.inMinutes,
                  items: [1, 2, 5, 10, 15].map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes min'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setAlertInterval(Duration(minutes: value));
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetStatistics();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistics reset successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Stats'),
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
}