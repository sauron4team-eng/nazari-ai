import 'package:flutter/material.dart';

/// ---------------------------------------------------------------
/// NazariAI — écran de chat de l'assistant d'étude
/// + historique de conversations (liste, création, suppression,
///   réouverture — comme ChatGPT).
///
/// INTÉGRATION :
/// 1. Copie ce fichier dans ton projet, ex: lib/screens/nazari_chat_screen.dart
/// 2. Copie nazari_logo.png dans assets/images/nazari_logo.png (si utilisé)
/// 3. Dans pubspec.yaml, ajoute sous "flutter:" :
///      assets:
///        - assets/images/nazari_logo.png
/// 4. Appelle AiAssistantScreen() depuis ton router / MaterialApp home.
///
/// NOTE SUR LA PERSISTANCE :
/// Ici, les conversations vivent en mémoire (elles disparaissent si
/// l'app redémarre). Pour les sauvegarder durablement, branche
/// _conversations sur SharedPreferences (ou ta base locale) dans
/// _loadConversations() / _persistConversations() — voir les TODO.
/// ---------------------------------------------------------------

class NazariColors {
  static const black = Color(0xFF111111);
  static const grayMid = Color(0xFF6B6B6B);
  static const grayLight = Color(0xFF9A9A9A);
  static const bgUser = Color(0xFFEEEEEE);
  static const border = Color(0xFF111111);
  static const white = Colors.white;
}

enum MessageAuthor { user, ai }

class ChatMessage {
  final MessageAuthor author;
  final String text;
  final List<String>? sources; // noms de documents, si author == ai
  final DateTime time;

  ChatMessage({
    required this.author,
    required this.text,
    this.sources,
    required this.time,
  });
}

class Conversation {
  final String id;
  String title;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
}

class AiAssistantScreen1 extends StatefulWidget {
  const AiAssistantScreen1({super.key});

  @override
  State<AiAssistantScreen1> createState() => _AiAssistantScreen1State();
}

class _AiAssistantScreen1State extends State<AiAssistantScreen1> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ---- Historique des conversations ----
  final List<Conversation> _conversations = [];
  String? _activeConversationId;

  // Raccourci vers les messages de la conversation active
  // (évite de dupliquer l'état ailleurs).
  List<ChatMessage> get _messages => _activeConversation?.messages ?? const [];

  Conversation? get _activeConversation {
    if (_activeConversationId == null) return null;
    for (final c in _conversations) {
      if (c.id == _activeConversationId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // TODO: remplace par un vrai chargement depuis SharedPreferences /
    // ta base locale si tu veux que l'historique survive au redémarrage.
    _startNewConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_conversations.length}';

  void _startNewConversation() {
    final conv = Conversation(
      id: _newId(),
      title: 'Nouvelle conversation',
      updatedAt: DateTime.now(),
    );
    setState(() {
      _conversations.insert(0, conv);
      _activeConversationId = conv.id;
    });
    // TODO: _persistConversations();
  }

  void _openConversation(String id) {
    setState(() => _activeConversationId = id);
    Navigator.of(
      context,
    ).maybePop(); // ferme la feuille d'historique si ouverte
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _deleteConversation(String id) {
    setState(() {
      _conversations.removeWhere((c) => c.id == id);
      if (_activeConversationId == id) {
        _activeConversationId = _conversations.isNotEmpty
            ? _conversations.first.id
            : null;
      }
    });
    if (_activeConversationId == null) {
      _startNewConversation();
    }
    // TODO: _persistConversations();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    var conv = _activeConversation;
    conv ??= () {
      _startNewConversation();
      return _activeConversation!;
    }();

    setState(() {
      conv!.messages.add(
        ChatMessage(
          author: MessageAuthor.user,
          text: text,
          time: DateTime.now(),
        ),
      );
      conv.updatedAt = DateTime.now();
      if (conv.title == 'Nouvelle conversation') {
        conv.title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      }
    });
    _controller.clear();
    // TODO: _persistConversations();

    // TODO: brancher ici l'appel à ton backend / modèle local.
    // Quand la réponse arrive, ajoute-la avec :
    // setState(() {
    //   conv!.messages.add(ChatMessage(
    //     author: MessageAuthor.ai,
    //     text: "...",
    //     sources: ["Lecture_Notes_Week4.pdf"],
    //     time: DateTime.now(),
    //   ));
    //   conv.updatedAt = DateTime.now();
    // });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _openHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final sorted = [..._conversations]
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
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
                            _startNewConversation();
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: NazariColors.black,
                          ),
                          label: const Text(
                            'Nouvelle',
                            style: TextStyle(color: NazariColors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sorted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune conversation pour le moment',
                        style: TextStyle(color: NazariColors.grayLight),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final conv = sorted[index];
                          final isActive = conv.id == _activeConversationId;
                          return ListTile(
                            leading: const Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: NazariColors.black,
                            ),
                            title: Text(
                              conv.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              _formatDate(conv.updatedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: NazariColors.grayMid,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 19,
                                color: NazariColors.grayLight,
                              ),
                              onPressed: () {
                                _deleteConversation(conv.id);
                                setSheetState(() {});
                                if (_conversations.isEmpty) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                            ),
                            onTap: () => _openConversation(conv.id),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime t) {
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) return "Aujourd'hui • ${_formatTime(t)}";
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} • ${_formatTime(t)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NazariColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildConversationSubbar(),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Ask me anything about your study!',
                        style: TextStyle(color: NazariColors.grayLight),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return msg.author == MessageAuthor.user
                            ? _UserBubble(message: msg)
                            : _AiCard(message: msg);
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationSubbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _activeConversation?.title ?? 'Nouvelle conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: NazariColors.grayMid),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, size: 20),
            tooltip: 'Nouvelle conversation',
            color: NazariColors.black,
            onPressed: _startNewConversation,
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 22),
            tooltip: 'Historique des conversations',
            color: NazariColors.black,
            onPressed: _openHistorySheet,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: NazariColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, size: 20),
              color: NazariColors.black,
              onPressed: () {
                // TODO: ouvrir le sélecteur de document
              },
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ask about your study',
                  hintStyle: TextStyle(color: NazariColors.grayLight),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: NazariColors.black,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, size: 16, color: Colors.white),
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: const BoxDecoration(
              color: NazariColors.bgUser,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 15, color: NazariColors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 2),
            child: Text(
              'You • ${_formatTime(message.time)}',
              style: const TextStyle(fontSize: 12, color: NazariColors.grayMid),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  final ChatMessage message;
  const _AiCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              border: Border.all(color: NazariColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.psychology_outlined,
                      size: 18,
                      color: NazariColors.black,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'NAZARIAI ANALYSIS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: NazariColors.black,
                  ),
                ),
                if (message.sources != null && message.sources!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFD8D8D8), height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'LOCAL SOURCES',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...message.sources!.map(
                    (source) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: NazariColors.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                source,
                                style: const TextStyle(fontSize: 13.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 2),
            child: Text(
              'NazariAI • Locally Processed',
              style: TextStyle(fontSize: 12, color: NazariColors.grayMid),
            ),
          ),
        ],
      ),
    );
  }
}
