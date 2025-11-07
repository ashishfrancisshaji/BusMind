import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../core/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.psychology,
      title: 'AI Mood Detection',
      description: 'Our AI analyzes your facial expressions to understand your mood and recommend the perfect activities for your bus journey.',
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      icon: Icons.music_note,
      title: 'Emotion-Aware Music',
      description: 'Get personalized music recommendations based on your current emotional state and energy level.',
      color: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      icon: Icons.quiz,
      title: 'Smart Flashcards',
      description: 'AI-generated flashcards from your lecture recordings and notes. Study smarter, not harder.',
      color: AppTheme.accentColor,
    ),
    OnboardingPage(
      icon: Icons.accessibility_new,
      title: 'Posture Monitoring',
      description: 'Real-time posture alerts to keep you healthy and comfortable during your commute.',
      color: AppTheme.successColor,
    ),
    OnboardingPage(
      icon: Icons.record_voice_over,
      title: 'Voice Summarization',
      description: 'Record lectures and get AI-powered summaries with key points extracted automatically.',
      color: AppTheme.warningColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Color.lerp(page.color, Colors.transparent, 0.9)!,
              borderRadius: BorderRadius.circular(75),
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 50),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 80),
              ElevatedButton(
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppTheme.primaryColor
            : Color.lerp(AppTheme.primaryColor, Colors.transparent, 0.7)!,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _completeOnboarding() async {
    final appState = context.read<AppStateProvider>();
    await appState.setFirstLaunchComplete();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
