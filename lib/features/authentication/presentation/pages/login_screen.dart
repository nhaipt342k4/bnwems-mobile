import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // 1. Entrance Fade & Slide Controller
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // 2. Infinite Clockwise & Counter-Clockwise Logo Halo Controllers
  late final AnimationController _rotateController;
  late final AnimationController _reverseRotateController;

  // 3. Expanding Aura Ripple Pulse Controller
  late final AnimationController _pulseAuraController;

  // 4. Infinite Drifting Background Controller
  late final AnimationController _driftController;
  late final Animation<Alignment> _alignTopAnim;
  late final Animation<Alignment> _alignBottomAnim;

  // 5. Infinite Shimmer Button Beam Controller
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;

  // 6. Floating Gold Dust Particles Data
  final List<_Particle> _particles = List.generate(
    16,
    (index) => _Particle(
      x: math.Random().nextDouble(),
      y: math.Random().nextDouble(),
      size: math.Random().nextDouble() * 5 + 3,
      speed: math.Random().nextDouble() * 0.002 + 0.001,
      opacity: math.Random().nextDouble() * 0.5 + 0.2,
    ),
  );

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));

    // 2. Logo Clockwise & Counter-Clockwise Rotations
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _reverseRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    // 3. Expanding Golden Aura Ripple Wave
    _pulseAuraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 4. Continuous Drifting Background Gradient
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _alignTopAnim = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(parent: _driftController, curve: Curves.easeInOut));

    _alignBottomAnim = AlignmentTween(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(CurvedAnimation(parent: _driftController, curve: Curves.easeInOut));

    // 5. Continuous Shimmer Light Beam for Login Button
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _rotateController.dispose();
    _reverseRotateController.dispose();
    _pulseAuraController.dispose();
    _driftController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go('/staff/dashboard');
    }
  }

  Widget _buildRadiantLogo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Continuous Expanding Aura Waves (Outer Ripple Wave)
          AnimatedBuilder(
            animation: _pulseAuraController,
            builder: (context, child) {
              final progress = _pulseAuraController.value;
              return Container(
                width: 80 + (70 * progress),
                height: 80 + (70 * progress),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4A359).withValues(alpha: (1.0 - progress) * 0.5),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF3D084).withValues(alpha: (1.0 - progress) * 0.4),
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. High-Lux Soft Ambient Golden Glow Backdrop
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A359).withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: const Color(0xFFFDE68A).withValues(alpha: 0.4),
                  blurRadius: 60,
                  spreadRadius: 16,
                ),
              ],
            ),
          ),

          // 3. Counter-Clockwise Outer Starburst Halo
          RotationTransition(
            turns: _reverseRotateController,
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0x88FDE68A),
                    Color(0x00FFFFFF),
                    Color(0xBBD4A359),
                    Color(0x00FFFFFF),
                  ],
                ),
              ),
            ),
          ),

          // 4. Clockwise Inner Sweep Gradient Ring
          RotationTransition(
            turns: _rotateController,
            child: Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFFD4A359),
                    Color(0xFFFFF9EE),
                    Color(0xFFA87E46),
                    Color(0xFFF3D084),
                    Color(0xFFD4A359),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC59B63).withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 5. High-End Metallic Embossed Core 'B' Badge
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE2B877),
                  Color(0xFFC59B63),
                  Color(0xFF8C6B38),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFFFF9EE), width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: const Color(0xFFFDE68A).withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: -1,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'B',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontFamily: 'serif',
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    Shadow(
                      color: const Color(0xFFFDE68A).withValues(alpha: 0.85),
                      blurRadius: 14,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _driftController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _alignTopAnim.value,
                end: _alignBottomAnim.value,
                colors: const [
                  Color(0xFFFAF6F0),
                  Color(0xFFF5ECE0),
                  Color(0xFFF7F2EA),
                  Color(0xFFEFE6D8),
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Floating Gold Dust Particles
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ParticlePainter(_particles),
                );
              },
            ),

            // Main Scrollable Body
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ultra-Radiant 'B' Logo Badge
                              _buildRadiantLogo(),
                              const SizedBox(height: 16),

                              // Sub-brand Title
                              const Text(
                                'WEDDING & EVENTS',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                  color: Color(0xFF70593E),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Main App Title
                              const Text(
                                'BNWEMS Staff',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF2C241E),
                                  fontFamily: 'serif',
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              const Text(
                                'Đăng nhập để xem công việc được giao',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.warmTextMuted,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Glassmorphic Luxury Form Card
                              Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(26.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: const Color(0xFFEFE8DC)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: AppColors.goldPrimary.withValues(alpha: 0.06),
                                      blurRadius: 36,
                                      spreadRadius: -4,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Label 1: TÊN ĐĂNG NHẬP
                                      const Text(
                                        'TÊN ĐĂNG NHẬP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: AppColors.goldLabel,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Username Input Field
                                      TextFormField(
                                        controller: _usernameController,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.warmTextDark,
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Vui lòng nhập tên đăng nhập';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Nhập tên đăng nhập',
                                          hintStyle: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.goldHint,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                            size: 20,
                                            color: AppColors.warmTextMuted,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFFAF6F0),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: Color(0xFFF0E8DC), width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.8),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: AppColors.cancelledText, width: 1.0),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: AppColors.cancelledText, width: 1.5),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Label 2: MẬT KHẨU
                                      const Text(
                                        'MẬT KHẨU',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: AppColors.goldLabel,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Password Input Field
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.warmTextDark,
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Vui lòng nhập mật khẩu';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          hintStyle: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.goldHint,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            size: 20,
                                            color: AppColors.warmTextMuted,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                              size: 20,
                                              color: AppColors.warmTextMuted,
                                            ),
                                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFFAF6F0),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: Color(0xFFF0E8DC), width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.8),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: AppColors.cancelledText, width: 1.0),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: AppColors.cancelledText, width: 1.5),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Forgot Password Link
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () => context.push('/auth/forgot-password'),
                                          child: const Text(
                                            'Quên mật khẩu?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.goldPrimary,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Error Message Banner
                                      if (auth.errorMessage != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.cancelledBg,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppColors.cancelledText.withValues(alpha: 0.2)),
                                          ),
                                          child: Text(
                                            auth.errorMessage!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.cancelledText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),

                                      // Dynamic Shimmer Animated Button
                                      AnimatedBuilder(
                                        animation: _shimmerController,
                                        builder: (context, child) {
                                          return Container(
                                            width: double.infinity,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(30),
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFC59B63), Color(0xFFA87E46)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFC59B63).withValues(alpha: 0.35),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(30),
                                              child: Stack(
                                                children: [
                                                  // Base Button Widget
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.transparent,
                                                      shadowColor: Colors.transparent,
                                                      minimumSize: const Size.fromHeight(52),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                    ),
                                                    onPressed: auth.isLoading ? null : _handleLogin,
                                                    child: auth.isLoading
                                                        ? const SizedBox(
                                                            height: 22,
                                                            width: 22,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2.2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                            ),
                                                          )
                                                        : const Text(
                                                            'ĐẮNG NHẬP',
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 1.5,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                  ),

                                                  // Moving Gold Shimmer Beam Effect
                                                  if (!auth.isLoading)
                                                    Positioned.fill(
                                                      child: IgnorePointer(
                                                        child: FractionalTranslation(
                                                          translation: Offset(_shimmerAnim.value, 0),
                                                          child: Container(
                                                            width: 120,
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: [
                                                                  Colors.white.withValues(alpha: 0.0),
                                                                  Colors.white.withValues(alpha: 0.35),
                                                                  Colors.white.withValues(alpha: 0.0),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Class & Painter for Floating Gold Dust Particles
class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.y -= p.speed;
      if (p.y < 0) {
        p.y = 1.0;
        p.x = math.Random().nextDouble();
      }

      final paint = Paint()
        ..color = const Color(0xFFC59B63).withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
