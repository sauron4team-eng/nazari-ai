import 'dart:math' show pi;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudyToolsScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const StudyToolsScreen({super.key, this.onNavigateToTab});

  @override
  State<StudyToolsScreen> createState() => _StudyToolsScreenState();
}

class _StudyToolsScreenState extends State<StudyToolsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Widget _stagger(Widget child, double delay) {
    final slide = Tween<Offset>(begin: const Offset(0, 20), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(delay, delay + 0.35, curve: Curves.easeOutCubic),
          ),
        );
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(delay, delay + 0.35, curve: Curves.easeOut),
      ),
    );
    return AnimatedBuilder(
      animation: _staggerController,
      child: child,
      builder: (_, child) => Transform.translate(
        offset: slide.value,
        child: Opacity(opacity: fade.value, child: child),
      ),
    );
  }

  void _goToAI() {
    widget.onNavigateToTab?.call(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Header ──
              _stagger(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.school,
                          color: Color(0xFF0B5D3B),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NazariAI',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B5D3B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.cloud_off,
                        color: Color(0xFF6B7280),
                      ),
                      splashRadius: 24,
                    ),
                  ],
                ),
                0.0,
              ),

              const SizedBox(height: 24),

              // ── Title ──
              _stagger(
                Text(
                  'Study Tools',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    height: 1.17,
                    letterSpacing: -0.96,
                  ),
                ),
                0.05,
              ),
              const SizedBox(height: 8),
              _stagger(
                Text(
                  'Power up your learning with AI-driven document analysis and adaptive study techniques.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                0.1,
              ),

              const SizedBox(height: 24),

              // ── Bento Grid ──
              _stagger(_buildBentoGrid(), 0.15),

              const SizedBox(height: 32),

              // ── Recent Results ──
              _stagger(_buildRecentResultsHeader(), 0.25),
              const SizedBox(height: 16),
              _stagger(_buildScoreCards(), 0.3),

              const SizedBox(height: 32),

              // ── Ready to study? ──
              _stagger(_buildReviewBanner(), 0.4),

              const SizedBox(height: 24),

              // ── Offline Toast ──
              _stagger(_buildOfflineToast(), 0.5),

              const SizedBox(height: 100), // space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BENTO GRID
  // ═══════════════════════════════════════════════════════════
  Widget _buildBentoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768;
        final gap = 16.0;
        final crossCount = isWide ? 4 : 2;
        final itemW =
            (constraints.maxWidth - gap * (crossCount - 1)) / crossCount;

        // Span widths
        double spanWidth(int span) => itemW * span + gap * (span - 1);

        final quizSpan = isWide ? 2 : 2;
        final flashSpan = isWide ? 2 : 2;
        final examSpan = isWide ? 3 : 2;
        final keySpan = isWide ? 1 : 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: spanWidth(quizSpan),
              child: _QuizCard(onTap: _goToAI),
            ),
            SizedBox(
              width: spanWidth(flashSpan),
              child: _FlashcardCard(onTap: _goToAI),
            ),
            SizedBox(
              width: spanWidth(examSpan),
              child: _ExamPrepCard(onTap: _goToAI),
            ),
            SizedBox(
              width: spanWidth(keySpan),
              child: _KeywordsCard(onTap: _goToAI),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  RECENT RESULTS
  // ═══════════════════════════════════════════════════════════
  Widget _buildRecentResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Results',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
            height: 1.33,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View Analytics',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B5D3B),
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768;
        if (isWide) {
          return Row(
            children: const [
              Expanded(
                child: _ScoreCard(
                  title: 'Advanced Macroeconomics',
                  meta: '2 hours ago \u2022 18/20 correct',
                  percent: 90,
                  color: Color(0xFF0B5D3B),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _ScoreCard(
                  title: 'Cognitive Psychology',
                  meta: 'Yesterday \u2022 13/20 correct',
                  percent: 65,
                  color: Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _ScoreCard(
                  title: 'CS 201: Algorithms',
                  meta: 'Oct 24 \u2022 16/20 correct',
                  percent: 80,
                  color: Color(0xFFD4A017),
                ),
              ),
            ],
          );
        }
        return Column(
          children: const [
            _ScoreCard(
              title: 'Advanced Macroeconomics',
              meta: '2 hours ago \u2022 18/20 correct',
              percent: 90,
              color: Color(0xFF0B5D3B),
            ),
            SizedBox(height: 12),
            _ScoreCard(
              title: 'Cognitive Psychology',
              meta: 'Yesterday \u2022 13/20 correct',
              percent: 65,
              color: Color(0xFFF59E0B),
            ),
            SizedBox(height: 12),
            _ScoreCard(
              title: 'CS 201: Algorithms',
              meta: 'Oct 24 \u2022 16/20 correct',
              percent: 80,
              color: Color(0xFFD4A017),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  REVIEW BANNER
  // ═══════════════════════════════════════════════════════════
  Widget _buildReviewBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4EF),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isWide) ...[
                Transform.rotate(
                  angle: -6 * pi / 180,
                  child: Container(
                    width: 80,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.style,
                        color: Color(0xFFD1D5DB),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
              _reviewBannerText(isWide),
              if (!isWide) const SizedBox(height: 16),
              if (isWide) const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _goToAI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A017),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFD4A017).withValues(alpha: 0.3),
                ),
                child: Text(
                  'Review Now',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reviewBannerText(bool isWide) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          'Ready to study?',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
            height: 1.33,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You have 42 cards due for review today in "Microbiology Basics".',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
            height: 1.43,
          ),
        ),
      ],
    );

    // Expanded n'a de sens que sur l'axe horizontal (largeur bornée).
    // En vertical, le Flex est dans un SingleChildScrollView -> hauteur
    // non bornée -> Expanded y ferait planter le layout.
    return isWide ? Expanded(child: column) : column;
  }

  // ═══════════════════════════════════════════════════════════
  //  OFFLINE TOAST
  // ═══════════════════════════════════════════════════════════
  Widget _buildOfflineToast() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D312E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt, color: Color(0xFF8DD6AB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI Processing is running locally. No internet needed.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BENTO CARDS
// ═══════════════════════════════════════════════════════════

class _QuizCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuizCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Positioned(
                      top: -24,
                      right: -24,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEFE5).withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Icon(Icons.quiz, color: Color(0xFF0B5D3B), size: 32),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Generate Quiz',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B5D3B),
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Instant multiple-choice and short-answer quizzes from your lecture notes.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Start Analysis',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B5D3B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF0B5D3B),
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashcardCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FlashcardCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_stories, color: Color(0xFFD4A017), size: 32),
            const SizedBox(height: 16),
            Text(
              'Flashcard Deck',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4A017),
                height: 1.33,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Active recall training with spaced repetition AI engine.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.43,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Open Decks',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD4A017),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFD4A017),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamPrepCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ExamPrepCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0B5D3B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B5D3B).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.model_training,
                color: Colors.white.withValues(alpha: 0.08),
                size: 140,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Exam Prep Mode',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.64,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A full simulation based on your syllabus, course history, and identified weak spots. Includes timed sessions and detailed logic walkthroughs.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B5D3B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Initialize Simulation',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _KeywordsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFE9),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.tag, color: Color(0xFF0B5D3B), size: 40),
            const SizedBox(height: 12),
            Text(
              'Keywords',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B5D3B),
                height: 1.33,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Extract Key Concepts',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SCORE CARD
// ═══════════════════════════════════════════════════════════

class _ScoreCard extends StatelessWidget {
  final String title;
  final String meta;
  final int percent;
  final Color color;

  const _ScoreCard({
    required this.title,
    required this.meta,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              painter: _CircleProgressPainter(
                percent: percent,
                color: color,
                bgColor: const Color(0xFFE0E3DE),
                strokeWidth: 4,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CIRCLE PROGRESS PAINTER
// ═══════════════════════════════════════════════════════════

class _CircleProgressPainter extends CustomPainter {
  final int percent;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.percent,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * (percent / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter old) {
    return old.percent != percent ||
        old.color != color ||
        old.bgColor != bgColor ||
        old.strokeWidth != strokeWidth;
  }
}
