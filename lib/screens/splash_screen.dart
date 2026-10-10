
import 'package:flutter/material.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  void _navigateToHome() {
    if (_isLoaded) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF052B75), // Deep blue background
      body: GestureDetector(
        onTap: _navigateToHome,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Use cover but smartly align so the head isn't cut off on Desktop
              Image.asset(
                'assets/images/loading_logo.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              // Gradient at bottom so text is always readable
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 5),
                      builder: (context, value, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLoaded ? 'TAP TO START' : 'LOADING ${(value * 100).toInt()}%',
                              style: TextStyle(
                                color: _isLoaded ? Colors.amber : Colors.white,
                                fontSize: _isLoaded ? 22 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!_isLoaded)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 24,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
