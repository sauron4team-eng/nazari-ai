import 'package:flutter/material.dart';
import 'package:nazariai/screens/ai_assistant_screen.dart' show NazariColors;

/// ---------------------------------------------------------------
/// NazariAI — écran de flashcards
///
/// INTÉGRATION :
/// 1. Copie ce fichier dans lib/screens/flashcards_screen.dart
/// 2. Depuis ai_assistant_screen.dart :
///      import 'package:nazariai/screens/flashcards_screen.dart';
/// 3. Navigue vers cet écran avec la liste de cartes générée par
///    gemma.generateFlashcards(...) :
///
///    Navigator.of(context).push(
///      MaterialPageRoute(
///        builder: (_) => FlashcardsScreen(cards: cards),
///      ),
///    );
/// ---------------------------------------------------------------

class FlashcardsScreen extends StatefulWidget {
  final List<Map<String, String>> cards;

  const FlashcardsScreen({super.key, required this.cards});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7F2),
        elevation: 0,
        foregroundColor: NazariColors.black,
        title: Text(
          'Flashcards (${_currentIndex + 1}/${widget.cards.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: NazariColors.black,
          ),
        ),
      ),
      body: widget.cards.isEmpty
          ? const Center(child: Text('No flashcards available.'))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.cards.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final card = widget.cards[index];
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: _FlipCard(
                          question: card['question'] ?? '',
                          answer: card['answer'] ?? '',
                        ),
                      );
                    },
                  ),
                ),
                _buildProgressDots(),
                const SizedBox(height: 12),
                _buildNavigationRow(),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.cards.length, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? NazariColors.black : NazariColors.grayLight,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          color: _currentIndex > 0
              ? NazariColors.black
              : NazariColors.grayLight,
          onPressed: _currentIndex > 0
              ? () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                )
              : null,
        ),
        const SizedBox(width: 24),
        Text(
          'Tap card to flip',
          style: TextStyle(fontSize: 13, color: NazariColors.grayMid),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 28),
          color: _currentIndex < widget.cards.length - 1
              ? NazariColors.black
              : NazariColors.grayLight,
          onPressed: _currentIndex < widget.cards.length - 1
              ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                )
              : null,
        ),
      ],
    );
  }
}

/// Carte individuelle avec effet de retournement 3D au tap.
class _FlipCard extends StatefulWidget {
  final String question;
  final String answer;

  const _FlipCard({required this.question, required this.answer});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showAnswer) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 3.14159;
          final isBack = angle > 3.14159 / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildCardFace(
                      label: 'ANSWER',
                      text: widget.answer,
                      backgroundColor: const Color(0xFF0B5D3B),
                      textColor: Colors.white,
                    ),
                  )
                : _buildCardFace(
                    label: 'QUESTION',
                    text: widget.question,
                    backgroundColor: Colors.white,
                    textColor: NazariColors.black,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({
    required String label,
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NazariColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
