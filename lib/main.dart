import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/study_tools_screen.dart';
import 'services/model_manager.dart';
import 'services/gemma_service.dart';
import 'services/chat_history_service.dart';
import 'services/document_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const NazariAIApp());
}

class NazariAIApp extends StatelessWidget {
  const NazariAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelManager()),
        Provider(create: (_) => GemmaService(useMock: false)),
        Provider(create: (_) => ChatHistoryService()..init()),
        Provider(create: (_) => DocumentService()),
      ],
      child: MaterialApp(
        title: 'NazariAI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B5D3B),
            primary: const Color(0xFF0B5D3B),
            secondary: const Color(0xFFD4A017),
            surface: const Color(0xFFFFFFFF),
            //background: const Color(0xFFF9F7F2),
            onSurface: const Color(0xFF1F2937),
          ),
          scaffoldBackgroundColor: const Color(0xFFF9F7F2),
          textTheme: GoogleFonts.hankenGroteskTextTheme(),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF0B5D3B),
            unselectedItemColor: Color(0xFF6B7280),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        home: const AppEntry(),
      ),
    );
  }
}

/// Gère la transition Splash → MainScreen SANS Navigator.
/// Tout reste sous le même MultiProvider — plus d'erreur ProviderNotFound.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showSplash
          ? const SplashScreen(key: ValueKey('splash'))
          : const MainScreen(key: ValueKey('main')),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const DocumentsScreen(),
      const AiAssistantScreen(),
      StudyToolsScreen(onNavigateToTab: _onItemTapped),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Study Tools',
          ),
        ],
      ),
    );
  }
}
