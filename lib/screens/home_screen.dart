import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/posture_provider.dart';
import '../core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTripCard(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 25),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good $greeting',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to study?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.go('/profile'),
          iconSize: 28,
        ),
      ],
    );
  }

  Widget _buildTripCard() {
    return Consumer<AppStateProvider>(
      builder: (context, state, _) {
        if (!state.isOnBus) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start a trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Track your study time',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showStartTripDialog,
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          );
        }

        // Active trip
        final remaining = state.remainingTripTime;
        final mins = remaining.inMinutes;
        final secs = remaining.inSeconds % 60;
        
        return Card(
          color: AppTheme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trip in progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$mins:${secs.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: state.tripProgress,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.currentRoute,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.endBusTrip(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('End Trip'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _Action('Flashcards', Icons.style, '/flashcards', AppTheme.primaryColor),
      _Action('Mood Check', Icons.mood, '/mood-detection', Colors.orange),
      _Action('Music', Icons.music_note, '/music', Colors.purple),
      _Action('Posture', Icons.accessibility_new, '/posture', Colors.green),
      _Action('Summary', Icons.mic, '/voice-summary', Colors.blue),
      _Action('Analytics', Icons.bar_chart, '/analytics', Colors.red),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, i) => _buildActionCard(actions[i]),
        ),
      ],
    );
  }

  Widget _buildActionCard(_Action action) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.color.withAlpha(77),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 32),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: action.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer2<FlashcardProvider, PostureProvider>(
      builder: (context, flashcards, posture, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (flashcards.flashcards.isNotEmpty)
              _buildActivityItem(
                'Studied ${flashcards.flashcards.length} flashcards',
                Icons.check_circle,
                Colors.green,
              ),
            if (posture.alertCount > 0)
              _buildActivityItem(
                '${posture.alertCount} posture alerts today',
                Icons.notifications,
                Colors.orange,
              ),
            _buildActivityItem(
              'Ready for more',
              Icons.psychology,
              AppTheme.primaryColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(String text, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  void _showStartTripDialog() {
    final routeController = TextEditingController();
    final durationController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: 'Bus route (optional)',
                hintText: 'e.g., Route 42',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final route = routeController.text.trim();
              final mins = int.tryParse(durationController.text) ?? 30;
              context.read<AppStateProvider>().startBusTrip(
                route.isEmpty ? 'My Route' : route,
                Duration(minutes: mins),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  
  _Action(this.label, this.icon, this.route, this.color);
}