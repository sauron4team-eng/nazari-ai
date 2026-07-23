import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;

  final double _parallaxX = 0;
  final double _parallaxY = 0;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _floatController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _floatController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _floatController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    super.dispose();
  }

  Widget _buildStaggeredItem(Widget child, double delay) {
    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(delay, delay + 0.35, curve: Curves.easeOutCubic),
          ),
        );

    final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(delay, delay + 0.35, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        return Transform.translate(
          offset: slideAnimation.value,
          child: Opacity(opacity: opacityAnimation.value, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Logo Header ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school,
                      color: Color(0xFF0B5D3B),
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NazariAI',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B5D3B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main Content ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),

              const SizedBox(height: 40),

              // ── Footer ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Text(
                      'Designed for focused minds. No subscriptions required for core offline features.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Privacy Policy',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0B5D3B),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Terms of Service',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0B5D3B),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  MOBILE LAYOUT (matches screen.png exactly)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Offline Badge
        _buildStaggeredItem(Center(child: _buildOfflineBadge()), 0.0),

        const SizedBox(height: 24),

        // Title
        _buildStaggeredItem(
          Text(
            'Your Offline AI Academic Assistant.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B5D3B),
              height: 1.29,
              letterSpacing: -0.56,
            ),
          ),
          0.1,
        ),

        const SizedBox(height: 16),

        // Subtitle
        _buildStaggeredItem(
          Text(
            'Study anywhere, anytime. NazariAI processes your documents locally, ensuring your focus remains unbroken even without an internet connection.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          0.2,
        ),

        const SizedBox(height: 24),

        // Buttons
        _buildStaggeredItem(
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5D3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(
                      0xFF0B5D3B,
                    ).withValues(alpha: 0.25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B5D3B),
                    side: const BorderSide(
                      color: Color(0xFF0B5D3B),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Demo',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B5D3B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.play_circle_outline, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          0.28,
        ),

        const SizedBox(height: 24),

        // Trust Badges
        _buildStaggeredItem(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTrustBadge(Icons.security, 'Local-First Privacy'),
              const SizedBox(width: 20),
              _buildTrustBadge(Icons.verified_user, 'Academic Integrity'),
            ],
          ),
          0.36,
        ),

        const SizedBox(height: 32),

        // Bento Cards
        _buildStaggeredItem(_buildBentoCards(showImage: false), 0.42),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT (matches the responsive HTML)
  // ═══════════════════════════════════════════════════════════
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left column — text content
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStaggeredItem(_buildOfflineBadge(), 0.0),
              const SizedBox(height: 24),
              _buildStaggeredItem(
                Text(
                  'Your Offline AI Academic Assistant.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B5D3B),
                    height: 1.17,
                    letterSpacing: -0.96,
                  ),
                ),
                0.1,
              ),
              const SizedBox(height: 16),
              _buildStaggeredItem(
                Text(
                  'Study anywhere, anytime. NazariAI processes your documents locally, ensuring your focus remains unbroken even without an internet connection.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.56,
                  ),
                ),
                0.2,
              ),
              const SizedBox(height: 24),
              _buildStaggeredItem(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5D3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: const Color(
                          0xFF0B5D3B,
                        ).withValues(alpha: 0.25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B5D3B),
                        side: const BorderSide(
                          color: Color(0xFF0B5D3B),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Demo',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B5D3B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.play_circle_outline, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                0.28,
              ),
              const SizedBox(height: 24),
              _buildStaggeredItem(
                Row(
                  children: [
                    _buildTrustBadge(Icons.security, 'Local-First Privacy'),
                    const SizedBox(width: 20),
                    _buildTrustBadge(Icons.verified_user, 'Academic Integrity'),
                  ],
                ),
                0.36,
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Right column — bento cards
        Expanded(
          flex: 6,
          child: _buildStaggeredItem(_buildBentoCards(showImage: true), 0.42),
        ),
      ],
    );
  }

  // ── Offline Badge ──
  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A017),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            '100% OFFLINE CAPABLE',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Trust Badge ──
  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF0B5D3B), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ── Bento Cards Stack ──
  Widget _buildBentoCards({required bool showImage}) {
    return SizedBox(
      height: 380,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0B5D3B).withValues(alpha: 0.08),
                    const Color(0xFFD4A017).withValues(alpha: 0.04),
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Cards Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFloatingCard(
                        controller: _floatController1,
                        phase: 0,
                        child: _buildDocumentCard(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: _buildFloatingCard(
                          controller: _floatController2,
                          phase: pi * 0.5,
                          child: _buildAICard(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFloatingCard(
                  controller: _floatController3,
                  phase: pi,
                  child: _buildStudySessionCard(),
                ),
              ],
            ),
          ),

          // Student Image Overlay (desktop only)
          if (showImage)
            Positioned(
              bottom: -20,
              right: -10,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF9F7F2), width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCfeVE3CatYsoToH4ctplYh21__6U-jQeS5ertGxQ4TMU-0wz6sco7M9pdaWeXNSncekp2tBHlWAlR8DcQYL0USkzYJXsprO-00N8zKut9g5ZUqW-NXTb3IJZ4ngLsePSMBC9aQsuFXML6ofSZ4DA0nPP05QoF7lGUTmqVJAS0ZU0YAUs8i51YPXX5dnoKhC6VEfKWi4xdlDbiWrmJtRkLVMeYfBdpY_0UFVUElD2SJBz4LzjmGeePWX840YlHuiOyRAUaLeBkp5ElM',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFDCEFE5),
                      child: const Icon(Icons.person, color: Color(0xFF0B5D3B)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Floating Animation Wrapper ──
  Widget _buildFloatingCard({
    required AnimationController controller,
    required double phase,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, childWidget) {
        final t = controller.value * 2 * pi;
        final offsetY = sin(t + phase) * 10;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: childWidget,
        );
      },
      child: child,
    );
  }

  // ── Document Card ──
  Widget _buildDocumentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFE5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xFF0B5D3B),
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 6,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0B5D3B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0B5D3B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Document Indexing...',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0B5D3B),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Card ──
  Widget _buildAICard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF3D8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology,
              color: Color(0xFFD4A017),
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: 0.67,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Local AI Active',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFD4A017),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Study Session Card ──
  Widget _buildStudySessionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Study Session',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '85%',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0B5D3B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEFE5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B5D3B),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0B5D3B).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Color(0xFF0B5D3B),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
