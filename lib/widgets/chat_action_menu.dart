// lib/widgets/chat_action_menu.dart
import 'package:flutter/material.dart';
import 'package:nazariai/screens/ai_assistant_screen.dart';

class ChatActionMenu extends StatelessWidget {
  final VoidCallback onSummarize;
  final VoidCallback onGenerateQuiz;
  final VoidCallback onGenerateFlashcards;

  const ChatActionMenu({
    super.key,
    required this.onSummarize,
    required this.onGenerateQuiz,
    required this.onGenerateFlashcards,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NazariColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChatActionMenuItem(
              icon: Icons.summarize_outlined,
              label: 'Summarize',
              onTap: onSummarize,
            ),
            _ChatActionMenuItem(
              icon: Icons.quiz_outlined,
              label: 'Generate Quiz',
              onTap: onGenerateQuiz,
            ),
            _ChatActionMenuItem(
              icon: Icons.style_outlined,
              label: 'Generate Flashcards',
              onTap: onGenerateFlashcards,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChatActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: NazariColors.black),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: NazariColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
