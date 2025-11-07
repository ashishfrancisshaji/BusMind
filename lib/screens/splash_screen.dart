import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../services/auto_prompt_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Simple fade-in without fancy animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AutoPromptService.initialize(context);
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Give user time to see the splash
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    
    // Simple navigation logic
    if (authProvider.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple icon container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              
              // App name
              const Text(
                'BusMind',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Study smarter on your commute',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}