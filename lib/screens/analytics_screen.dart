import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/mood_detection_provider.dart';
import '../providers/posture_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Analytics',
        showBackButton: true,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, child) {
          if (analyticsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeframeSelector(analyticsProvider),
                const SizedBox(height: 20),
                _buildWeeklyOverview(analyticsProvider),
                const SizedBox(height: 30),
                _buildRealTimeStats(),
                const SizedBox(height: 30),
                _buildStudyTimeChart(analyticsProvider),
                const SizedBox(height: 30),
                _buildInsightsSection(analyticsProvider),
                const SizedBox(height: 30),
                _buildDetailedStats(analyticsProvider),
                const SizedBox(height: 30),
                _buildMoodDistribution(analyticsProvider),
                const SizedBox(height: 30),
                _buildTravelSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeframeSelector(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTimeframeButton('Week', 'week', provider),
          _buildTimeframeButton('Month', 'month', provider),
          _buildTimeframeButton('Year', 'year', provider),
        ],
      ),
    );
  }

  Widget _buildTimeframeButton(String label, String value, AnalyticsProvider provider) {
    final isSelected = provider.selectedTimeframe == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTimeframe(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview(AnalyticsProvider provider) {
    final weekStats = provider.getWeeklyStats();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week\'s Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Study Time',
                  '${weekStats.totalStudyTime}m',
                  Icons.schedule,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  'Flashcards',
                  '${weekStats.totalFlashcards}',
                  Icons.quiz,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Recordings',
                  '${weekStats.totalRecordings}',
                  Icons.mic,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  'Posture',
                  '${(weekStats.averagePostureScore * 100).toInt()}%',
                  Icons.accessibility_new,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // REAL-TIME STATS from actual providers
  Widget _buildRealTimeStats() {
    return Consumer5<FlashcardProvider, VoiceProvider, MoodDetectionProvider, PostureProvider, AppStateProvider>(
      builder: (context, flashcard, voice, mood, posture, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 15),
            Container(
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
                  _buildRealTimeRow(
                    'Total Flashcards',
                    '${flashcard.flashcards.length}',
                    Icons.style,
                    AppTheme.primaryColor,
                  ),
                  const Divider(),
                  _buildRealTimeRow(
                    'Voice Summaries',
                    '${voice.totalSummaries}',
                    Icons.mic,
                    AppTheme.successColor,
                  ),
                  const Divider(),
                  _buildRealTimeRow(
                    'Recording Time',
                    _formatDuration(voice.totalRecordingTime),
                    Icons.timer,
                    AppTheme.secondaryColor,
                  ),
                  const Divider(),
                  _buildRealTimeRow(
                    'Current Mood',
                    mood.currentMood.name.toUpperCase(),
                    mood.getMoodIcon(),
                    mood.getMoodColor(),
                  ),
                  const Divider(),
                  _buildRealTimeRow(
                    'Posture Monitoring',
                    posture.isMonitoring ? 'ACTIVE' : 'INACTIVE',
                    posture.getPostureIcon(),
                    posture.isMonitoring ? AppTheme.successColor : Colors.grey,
                  ),
                  if (appState.isOnBus) ...[
                    const Divider(),
                    _buildRealTimeRow(
                      'Bus Trip',
                      appState.currentRoute,
                      Icons.directions_bus,
                      AppTheme.accentColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealTimeRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        _buildInsightCard(
          'Productivity',
          provider.getProductivityInsight(),
          Icons.trending_up,
          AppTheme.successColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          'Posture Health',
          provider.getPostureInsight(),
          Icons.accessibility_new,
          AppTheme.warningColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          'Mood Analysis',
          provider.getMoodInsight(),
          Icons.sentiment_satisfied,
          AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String insight, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(AnalyticsProvider provider) {
    final data = provider.getDataForTimeframe(provider.selectedTimeframe);
    final sessionsWithStudy = data.where((d) => d.studyMinutes > 0).length;
    final avgSession = sessionsWithStudy > 0 
        ? (data.fold(0, (sum, d) => sum + d.studyMinutes) / sessionsWithStudy).toInt()
        : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
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
              _buildStatRow(
                'Total Sessions',
                '$sessionsWithStudy',
                Icons.play_circle_outline,
              ),
              const Divider(),
              _buildStatRow(
                'Avg Session',
                '${avgSession}m',
                Icons.timer,
              ),
              const Divider(),
              _buildStatRow(
                'Best Day',
                _getMostProductiveDay(data),
                Icons.star,
              ),
              const Divider(),
              _buildStatRow(
                'Streak',
                '${_getCurrentStreak(data)} days',
                Icons.local_fire_department,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution(AnalyticsProvider provider) {
    final weekStats = provider.getWeeklyStats();
    final moodData = weekStats.moodDistribution;
    
    if (moodData.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = moodData.values.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood Distribution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
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
            children: moodData.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return _buildMoodBar(entry.key, entry.value, percentage);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodBar(String mood, int count, double percentage) {
    final moodColors = {
      'happy': AppTheme.successColor,
      'focused': AppTheme.primaryColor,
      'tired': AppTheme.warningColor,
      'stressed': AppTheme.errorColor,
      'sad': Colors.blue.shade600,
      'relaxed': Colors.purple.shade600,
      'unknown': AppTheme.textSecondary,
    };

    final moodEmojis = {
      'happy': '😊',
      'focused': '🎯',
      'tired': '😴',
      'stressed': '😰',
      'sad': '😔',
      'relaxed': '😌',
      'unknown': '❓',
    };

    final color = moodColors[mood] ?? AppTheme.textSecondary;
    final emoji = moodEmojis[mood] ?? '❓';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    mood.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$count days (${percentage.toInt()}%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Travel & Study Balance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 15),
            Container(
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
                  _buildTravelMetric(
                    'Current Status',
                    appState.isOnBus ? 'On Bus' : 'Not Traveling',
                    Icons.directions_bus,
                    appState.isOnBus ? AppTheme.successColor : Colors.grey,
                  ),
                  if (appState.isOnBus) ...[
                    const Divider(),
                    _buildTravelMetric(
                      'Route',
                      appState.currentRoute,
                      Icons.route,
                      AppTheme.primaryColor,
                    ),
                    const Divider(),
                    _buildTravelMetric(
                      'Progress',
                      '${(appState.tripProgress * 100).toInt()}%',
                      Icons.timeline,
                      AppTheme.accentColor,
                    ),
                    const Divider(),
                    _buildTravelMetric(
                      'Time Left',
                      appState.formattedRemainingTime,
                      Icons.timer,
                      AppTheme.warningColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTravelMetric(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTimeChart(AnalyticsProvider provider) {
    final data = provider.getDataForTimeframe(provider.selectedTimeframe);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study Time Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 200,
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
          child: _buildLineChart(data),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<AnalyticsData> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final maxValue = data.map((d) => d.studyMinutes).reduce(math.max).toDouble();
    final minValue = data.map((d) => d.studyMinutes).reduce(math.min).toDouble();
    final range = maxValue - minValue;

    return CustomPaint(
      painter: LineChartPainter(data, maxValue, minValue, range),
      size: const Size(double.infinity, double.infinity),
    );
  }

  String _getMostProductiveDay(List<AnalyticsData> data) {
    if (data.isEmpty) return 'No data';
    
    final mostProductive = data.reduce((a, b) => 
      a.studyMinutes > b.studyMinutes ? a : b);
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[mostProductive.date.weekday - 1];
  }

  int _getCurrentStreak(List<AnalyticsData> data) {
    if (data.isEmpty) return 0;
    
    int streak = 0;
    final sortedData = data.reversed.toList();
    
    for (final dayData in sortedData) {
      if (dayData.studyMinutes > 0) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

class LineChartPainter extends CustomPainter {
  final List<AnalyticsData> data;
  final double maxValue;
  final double minValue;
  final double range;

  LineChartPainter(this.data, this.maxValue, this.minValue, this.range);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i].studyMinutes - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - 20;
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < data.length; i += math.max(1, data.length ~/ 5)) {
      final x = (i / (data.length - 1)) * size.width;
      final dayName = _getDayName(data[i].date);
      
      textPainter.text = TextSpan(
        text: dayName,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 15),
      );
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}