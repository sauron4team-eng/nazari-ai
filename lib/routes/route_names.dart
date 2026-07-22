// app_screens.dart
import 'package:flutter/material.dart';
import 'package:nazariai/screens/ai_assistant_screen.dart';
import 'package:nazariai/screens/documents_screen.dart';
import 'package:nazariai/screens/home_screen.dart';
import 'package:nazariai/screens/study_tools_screen.dart';

List<Widget> buildAppScreens() {
  return [
    const HomeScreen(),
    const DocumentsScreen(),
    const AiAssistantScreen(),
    const StudyToolsScreen(),
  ];
}
