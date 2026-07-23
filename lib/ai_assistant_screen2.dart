import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

/// ================================================================
/// NazariAI — Conversations PERSISTANTES avec Hive
/// ================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verrouille l'app en mode portrait — pense mobile, pas tablette/desktop.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // IMPORTANT : Initialise ET ouvre la box avant runApp()
  await Hive.initFlutter();
  final box = await Hive.openBox('conversations');
  debugPrint(
    '[NazariAI] Box "conversations" ouverte — '
    '${box.containsKey('list') ? "des données existent déjà" : "vide (premier lancement)"}',
  );

  runApp(const NazariAIApp());
}

class NazariAIApp extends StatelessWidget {
  const NazariAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NazariAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
      ),
      home: const ChatScreen(),
    );
  }
}

// ==================== MODELES ====================

enum MessageAuthor { user, ai }

class ChatMessage {
  final MessageAuthor author;
  final String text;
  final List<String>? sources;
  final DateTime time;

  ChatMessage({
    required this.author,
    required this.text,
    this.sources,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
    'author': author == MessageAuthor.user ? 'user' : 'ai',
    'text': text,
    'sources': sources,
    'time': time.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) => ChatMessage(
    author: map['author'] == 'user' ? MessageAuthor.user : MessageAuthor.ai,
    text: map['text'] as String,
    sources: map['sources'] != null
        ? List<String>.from(map['sources'] as List)
        : null,
    time: DateTime.parse(map['time'] as String),
  );
}

class Conversation {
  String id;
  String title;
  DateTime updatedAt;
  List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toMap()).toList(),
  };

  factory Conversation.fromMap(Map<dynamic, dynamic> map) => Conversation(
    id: map['id'] as String,
    title: map['title'] as String,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    messages: (map['messages'] as List)
        .map((m) => ChatMessage.fromMap(m as Map<dynamic, dynamic>))
        .toList(),
  );
}

// ==================== ECRAN PRINCIPAL ====================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _boxName = 'conversations';
  static const _storageKey = 'list';

  Box? _box;
  List<Conversation> _conversations = [];
  String? _activeId;
  bool _loaded = false;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Récupère la box (déjà ouverte dans main(), mais on sécurise
  /// au cas où cet écran serait lancé autrement).
  Future<void> _initBox() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
        debugPrint('[NazariAI] Box déjà ouverte, réutilisation directe');
      } else {
        _box = await Hive.openBox(_boxName);
        debugPrint('[NazariAI] Box ouverte manuellement depuis ChatScreen');
      }
    } catch (e, st) {
      debugPrint('[NazariAI] ERREUR à l\'ouverture de la box : $e');
      debugPrint('$st');
    }

    _loadConversations();
  }

  /// CHARGE les conversations depuis Hive
  void _loadConversations() {
    if (_box == null) {
      debugPrint(
        '[NazariAI] _box est null — impossible de charger, '
        'on démarre à vide.',
      );
      _createFirstConversation();
      return;
    }

    final raw = _box!.get(_storageKey) as List<dynamic>?;
    debugPrint(
      '[NazariAI] Clé "$_storageKey" → '
      '${raw == null ? "AUCUNE DONNÉE" : "${raw.length} conversation(s) brute(s)"}',
    );

    if (raw != null && raw.isNotEmpty) {
      try {
        final loaded =
            raw
                .map((e) => Conversation.fromMap(e as Map<dynamic, dynamic>))
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        debugPrint(
          '[NazariAI] ${loaded.length} conversation(s) restaurée(s) '
          'avec succès (titres : ${loaded.map((c) => c.title).join(", ")})',
        );

        setState(() {
          _conversations = loaded;
          _activeId = loaded.first.id;
          _loaded = true;
        });
        return;
      } catch (e, st) {
        debugPrint(
          '[NazariAI] ERREUR de décodage — les données existent '
          'mais sont illisibles : $e',
        );
        debugPrint('$st');
      }
    }

    // Premier démarrage, ou données absentes/corrompues.
    debugPrint('[NazariAI] Démarrage avec une conversation vierge');
    _createFirstConversation();
  }

  /// SAUVEGARDE dans Hive
  Future<void> _save() async {
    if (_box == null) {
      debugPrint('[NazariAI] Impossible de sauvegarder : _box est null');
      return;
    }

    final data = _conversations.map((c) => c.toMap()).toList();
    await _box!.put(_storageKey, data);
    await _box!.flush(); // force l'écriture immédiate sur le disque

    debugPrint(
      '[NazariAI] 💾 Sauvegarde effectuée : '
      '${_conversations.length} conversation(s), '
      'clés dans la box = ${_box!.keys.toList()}',
    );
  }

  void _createFirstConversation() {
    final conv = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nouvelle conversation',
      updatedAt: DateTime.now(),
      messages: [],
    );
    setState(() {
      _conversations = [conv];
      _activeId = conv.id;
      _loaded = true;
    });
    _save();
  }

  Conversation? get _activeConversation {
    if (_activeId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeId);
    } catch (_) {
      return null;
    }
  }

  List<ChatMessage> get _messages => _activeConversation?.messages ?? [];

  void _selectConversation(String id) {
    setState(() => _activeId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _newConversation() {
    final conv = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nouvelle conversation',
      updatedAt: DateTime.now(),
      messages: [],
    );
    setState(() {
      _conversations.insert(0, conv);
      _activeId = conv.id;
    });
    _save();
  }

  void _deleteConversation(String id) {
    setState(() {
      _conversations.removeWhere((c) => c.id == id);
      if (_activeId == id) {
        _activeId = _conversations.isNotEmpty ? _conversations.first.id : null;
      }
    });
    if (_conversations.isEmpty) {
      _createFirstConversation();
    } else {
      _save();
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final conv = _activeConversation;
    if (conv == null) return; // sécurité : pas de conversation active

    setState(() {
      conv.messages.add(
        ChatMessage(
          author: MessageAuthor.user,
          text: text,
          time: DateTime.now(),
        ),
      );
      conv.updatedAt = DateTime.now();
      if (conv.title == 'Nouvelle conversation') {
        conv.title = text.length > 30 ? '${text.substring(0, 30)}…' : text;
      }
      _isTyping = true;
    });
    _controller.clear();
    _save();
    _scrollToBottom();

    // Simulation réponse AI — remplace par ton vrai appel modèle/backend.
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        conv.messages.add(
          ChatMessage(
            author: MessageAuthor.ai,
            text:
                'Reponse a "$text"\n\n• Analyse basee sur tes documents\n• Traitement local',
            sources: ['Document_local.pdf'],
            time: DateTime.now(),
          ),
        );
        conv.updatedAt = DateTime.now();
        _isTyping = false;
      });
      _save();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDate(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return "A l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return DateFormat('dd/MM/yyyy').format(t);
  }

  Future<void> _openHistorySheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 8, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Conversations',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _newConversation();
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: Color(0xFF059669),
                            ),
                            label: const Text(
                              'Nouvelle',
                              style: TextStyle(color: Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_conversations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune conversation pour le moment',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            final isActive = conv.id == _activeId;
                            return InkWell(
                              onTap: () {
                                _selectConversation(conv.id);
                                Navigator.pop(sheetContext);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFECFDF5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                      color: isActive
                                          ? const Color(0xFF059669)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            conv.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isActive
                                                  ? const Color(0xFF059669)
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${conv.messages.length} messages • ${_formatDate(conv.updatedAt)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _deleteConversation(conv.id);
                                        setSheetState(() {});
                                        if (_conversations.isEmpty) {
                                          Navigator.pop(sheetContext);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ========== EN-TÊTE ==========
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeConversation?.title ?? 'NazariAI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_comment_outlined, size: 21),
                    tooltip: 'Nouvelle conversation',
                    color: Colors.black,
                    onPressed: _newConversation,
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, size: 22),
                    tooltip: 'Historique des conversations',
                    color: Colors.black,
                    onPressed: _openHistorySheet,
                  ),
                ],
              ),
            ),

            // ========== MESSAGES ==========
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return msg.author == MessageAuthor.user
                            ? _buildUserBubble(msg)
                            : _buildAiBubble(msg);
                      },
                    ),
            ),

            // Typing
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _dot(),
                          _dot(),
                          _dot(),
                          const SizedBox(width: 8),
                          const Text(
                            'NazariAI reflechit...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ========== SAISIE ==========
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Pose une question...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology,
              color: Color(0xFF059669),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NazariAI',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pose-moi des questions sur tes documents.\nTout reste sur ton appareil.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              'You • ${DateFormat('h:mm a').format(msg.time)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.55,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.psychology_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'NAZARIAI ANALYSIS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  msg.text,
                  style: const TextStyle(fontSize: 15, height: 1.55),
                ),
                if (msg.sources != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'LOCAL SOURCES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...msg.sources!.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 14),
                          const SizedBox(width: 6),
                          Text(s, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'NazariAI • Locally Processed',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF059669),
        shape: BoxShape.circle,
      ),
    );
  }
}
