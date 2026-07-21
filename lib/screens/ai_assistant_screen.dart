import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7F2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'AI Assistant',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: const Center(
        child: Text('AI Assistant Screen — Work in progress'),
      ),
    );
  }
}
