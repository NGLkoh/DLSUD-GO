// lib/screens/splash/splash_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../auth/terms_conditions_screen.dart';
import '../dashboard/main_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // --- Controllers ---
  late AnimationController _mainController;   // Controls entrance sequence
  late AnimationController _rippleController; // Controls shockwave behind logo
  late AnimationController _shimmerController;// Controls light gleam on text
  late AnimationController _bgController;     // Controls background gradient movement

  // --- Animations ---
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _loaderOpacity;
  late Animation<Alignment> _bgTopAlignment;
  late Animation<Alignment> _bgBottomAlignment;

  // --- State ---
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _startSequence();
  }

  void _initParticles() {
    // Generate organic particles with random properties
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        speed: 0.2 + _random.nextDouble() * 0.4, // Varied speeds
        size: 2.0 + _random.nextDouble() * 4.0,  // Varied sizes
        opacity: 0.1 + _random.nextDouble() * 0.3, // Varied opacity
      ));
    }
  }

  void _initAnimations() {
    // 1. Main Sequence Controller (Entrance)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 2. Background Gradient Movement (Looping)
    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    // 3. Ripple Effect (Looping)
    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // 4. Text Shimmer (One-shot after text appears)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // --- Tweens ---

    // Logo: Elastic pop-in
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Text: Smooth slide up
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    // Loader: Fades in late
    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // Background Gradient Animation (Aurora Effect)
    _bgTopAlignment = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(_bgController);

    _bgBottomAlignment = AlignmentTween(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(_bgController);
  }

  void _startSequence() async {
    await _mainController.forward();
    // Start text shimmer after text has slid in
    _shimmerController.forward();
    
    // Delay before navigation
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _navigateToNext();
    });
  }

  void _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final termsAccepted = prefs.getBool('terms_accepted') ?? false;

    if (!mounted) return;

    Widget destination = termsAccepted 
        ? const MainDashboard() 
        : const TermsConditionsScreen(isFirstTime: true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // "Zoom into Logo" transition
          // The screen expands massively towards the viewer
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rippleController.dispose();
    _shimmerController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              // 1. Dynamic Aurora Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _bgTopAlignment.value,
                    end: _bgBottomAlignment.value,
                    colors: const [
                      AppColors.primaryGreen,
                      AppColors.darkGreen,
                      Color(0xFF004D26), // Darker depth
                    ],
                  ),
                ),
              ),

              // 2. Organic Particles
              Positioned.fill(
                child: ParticleField(particles: _particles, controller: _bgController),
              ),

              // 3. Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Stack
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // A. Ripple Shockwave behind logo
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: RipplePainter(
                                _rippleController.value, 
                                opacity: _logoScale.value // Only show when logo appears
                              ),
                              size: const Size(300, 300),
                            );
                          },
                        ),
                        
                        // B. The Logo (FIXED: White background removed)
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: Container(
                              width: 170, // Slightly larger to compensate for padding removal
                              height: 170,
                              // BoxDecoration, ClipOval, and Padding removed here.
                              // Just the raw image now.
                              child: Image.asset(
                                'assets/images/DLSU-D GO!.png',
                                fit: BoxFit.contain, // Ensures nothing is cut off
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // Text Stack with Shimmer
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            // "DLSU-D GO" with Shimmer
                            AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: const [
                                        Colors.white,
                                        Color(0xFFE0F7FA), // Slight tint
                                        Colors.white,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                      begin: Alignment(-1.0 + (_shimmerController.value * 3), 0.0),
                                      end: Alignment(1.0 + (_shimmerController.value * 3), 0.0),
                                      tileMode: TileMode.clamp,
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'DLSU-D GO',
                                    style: TextStyle(
                                      fontFamily: 'Poppins', // Ensure you have this font or default
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Subtitle
                            Text(
                              'Your Smart Campus Navigator',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Custom Loader (Pulsing Dots)
                    FadeTransition(
                      opacity: _loaderOpacity,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Helper Classes ---

class Particle {
  Offset position; // 0.0 to 1.0 relative
  final double speed;
  final double size;
  final double opacity;

  Particle({
    required this.position, 
    required this.speed, 
    required this.size, 
    required this.opacity
  });
}

class ParticleField extends StatelessWidget {
  final List<Particle> particles;
  final AnimationController controller;

  const ParticleField({super.key, required this.particles, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(particles, controller.value),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Move particle upwards based on speed and time
      // Using modulo 1.0 to wrap around when it goes off screen
      double dy = (particle.position.dy - (progress * particle.speed)) % 1.0;
      if (dy < 0) dy += 1.0;

      final x = particle.position.dx * size.width;
      final y = dy * size.height;

      paint.color = Colors.white.withOpacity(particle.opacity);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RipplePainter extends CustomPainter {
  final double animationValue;
  final double opacity;

  RipplePainter(this.animationValue, {this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw 3 concentric ripples
    for (int i = 0; i < 3; i++) {
      // Offset animations so ripples don't move in unison
      final double waveProgress = (animationValue + (i * 0.33)) % 1.0;
      final double radius = waveProgress * (size.width / 1.5);
      final double waveOpacity = (1.0 - waveProgress) * 0.3 * opacity;

      paint.color = Colors.white.withOpacity(waveOpacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}