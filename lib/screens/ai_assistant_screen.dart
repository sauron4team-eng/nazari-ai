import 'dart:io';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:nazariai/ai-services/gemma_service.dart' as gemma;
import 'package:nazariai/widgets/chat_action_menu.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:nazariai/services/documents_service.dart';

/// ---------------------------------------------------------------
/// NazariAI — écran de chat de l'assistant d'étude
///
/// INTÉGRATION :
/// 1. Copie ce fichier dans ton projet, ex: lib/screens/nazari_chat_screen.dart
/// 2. Copie nazari_logo.png dans assets/images/nazari_logo.png
/// 3. Dans pubspec.yaml, ajoute sous "flutter:" :
///      assets:
///        - assets/images/nazari_logo.png
/// 4. Appelle NazariChatScreen() depuis ton router / MaterialApp home.
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

class AiAssistantScreen extends StatefulWidget {
  final String? initialFilePath;

  const AiAssistantScreen({super.key, this.initialFilePath});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String? _attachedFilePath;
  String? _attachedFileName;
  int? _attachedFileSize;
  bool _isLoadingFile = false;
  String? _fileLoadError;
  String? _attachedFileContent;
  List<DocumentChunk> _documentChunks = [];
  bool _isModelReady = false;
  String _modelStatus = 'Initialisation du modèle IA...';
  int _downloadProgress = 0;
  final LayerLink _plusButtonLink = LayerLink();
  OverlayEntry? _actionMenuOverlay;

  @override
  void initState() {
    super.initState();
    _initGemma();
    if (widget.initialFilePath != null) {
      _attachFile(widget.initialFilePath!);
    }
  }

  Future<void> _initGemma() async {
    try {
      await gemma.setupGemmaModel(
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _modelStatus = 'Téléchargement du modèle... $p%';
              _downloadProgress = p;
            });
          }
        },
      );

      if (mounted) setState(() => _modelStatus = 'Chargement du modèle...');
      //Verifier la presence du fichier avant de lancer la session de chat
      debugPrint('Modèle actif ? ${FlutterGemma.hasActiveModel()}');

      await gemma.startChatSession(); // pas encore de document à ce stade

      if (mounted) {
        setState(() {
          _isModelReady = true;
          _modelStatus = 'Prêt';
        });
        debugPrint('Etat pret');
      }
    } catch (e, stack) {
      debugPrint('❌ Erreur init Gemma : $e');
      debugPrint('Stack : $stack');
      if (mounted) {
        setState(() {
          _modelStatus = 'Erreur : $e';
        });
      }
    }
  }

  Future<void> _attachFile(String path) async {
    setState(() {
      _isLoadingFile = true;
      _fileLoadError = null;
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Fichier introuvable : $path');
      }

      // Un seul appel à extractChunksFromFile (l'ancien code l'appelait
      // deux fois, dont une fois sans "await", ce qui ne compilait pas)
      final chunks = await DocumentsService.extractChunksFromFile(path);
      if (chunks.isEmpty) {
        throw Exception('Le document ne contient pas de texte exploitable.');
      }

      final bytes = await file.length();
      // Texte complet reconstitué à partir des chunks (chunk.text au lieu
      // de chunk directement, puisque chunk est maintenant un DocumentChunk)
      final fullText = chunks.map((c) => c.text).join('\n\n');

      setState(() {
        _attachedFilePath = path;
        _attachedFileName = p.basename(path);
        _attachedFileSize = bytes;
        _attachedFileContent = fullText;
        _documentChunks = chunks;
      });
      // Attendre que le modèle soit prêt avant de démarrer une session avec contexte
      if (!_isModelReady) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 200));
          return !_isModelReady;
        });
      }

      await gemma.startChatSession(documentContext: fullText);
      debugPrint('File attached : $_attachedFileName');
      _addAiMessage(
        'Document "${_attachedFileName!}" loaded locally. You can now ask questions about its content.',
        sources: [_attachedFileName!],
      );
    } catch (e) {
      setState(() {
        _fileLoadError = e.toString();
        _attachedFilePath = null;
        _attachedFileName = null;
        _attachedFileSize = null;
        _attachedFileContent = null;
        _documentChunks = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFile = false;
        });
      }
    }
  }

  void _addAiMessage(String text, {List<String>? sources}) {
    setState(() {
      _messages.add(
        ChatMessage(
          author: MessageAuthor.ai,
          text: text,
          sources: sources,
          time: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  //Action on "+" AIChat icon
  void _toggleActionMenu() {
    try {
      if (_actionMenuOverlay != null) {
        _closeActionMenu();
        print('Toggle Action clique ok');
      } else {
        _openActionMenu();
        print('Toggle Action clique mais erreur');
      }
    } catch (e) {
      print("Error toggleActionMenu: $e");
    }
  }

  void _openActionMenu() {
    final overlay = Overlay.of(context);
    _actionMenuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Zone invisible qui capte les taps en dehors du menu pour le fermer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeActionMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _plusButtonLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8),
            child: ChatActionMenu(
              onSummarize: () {
                _closeActionMenu();
                _handleSummarize();
              },
              onGenerateQuiz: () {
                _closeActionMenu();
                _handleGenerateQuiz();
              },
              onGenerateFlashcards: () {
                _closeActionMenu();
                _handleGenerateFlashcards();
              },
            ),
          ),
        ],
      ),
    );
    overlay.insert(_actionMenuOverlay!);
  }

  void _closeActionMenu() {
    _actionMenuOverlay?.remove();
    _actionMenuOverlay = null;
  }

  @override
  void dispose() {
    _closeActionMenu();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!_isModelReady) {
      _addAiMessage(
        'Le modèle IA n\'est pas encore prêt, patiente quelques secondes.',
      );
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          author: MessageAuthor.user,
          text: text,
          time: DateTime.now(),
        ),
      );
    });
    _controller.clear();

    // Message IA placeholder, qu'on va mettre à jour au fil du streaming
    final aiMessageIndex = _messages.length;
    setState(() {
      _messages.add(
        ChatMessage(
          author: MessageAuthor.ai,
          text: '',
          sources: _attachedFileName != null ? [_attachedFileName!] : null,
          time: DateTime.now(),
        ),
      );
    });

    try {
      await for (final partial in gemma.sendChatMessage(text)) {
        setState(() {
          _messages[aiMessageIndex] = ChatMessage(
            author: MessageAuthor.ai,
            text: partial,
            sources: _messages[aiMessageIndex].sources,
            time: _messages[aiMessageIndex].time,
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages[aiMessageIndex] = ChatMessage(
          author: MessageAuthor.ai,
          text: 'Erreur pendant la génération de la réponse : $e',
          time: _messages[aiMessageIndex].time,
        );
      });
    }
  }

  //Methods to manage menu under "+" on the AIChat
  Future<void> _handleSummarize() async {
    if (_attachedFileContent == null || _attachedFileContent!.isEmpty) {
      _addAiMessage(
        'Aucun document chargé à résumer. Attache d\'abord un document.',
      );
      return;
    }
    if (!_isModelReady) {
      _addAiMessage(
        'Le modèle IA n\'est pas encore prêt, patiente quelques secondes.',
      );
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          author: MessageAuthor.user,
          text: 'Summarize this document.',
          time: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final summary = await gemma.summarizeDocument(_attachedFileContent!);
      _addAiMessage(
        summary,
        sources: _attachedFileName != null ? [_attachedFileName!] : null,
      );
    } catch (e) {
      _addAiMessage('Erreur pendant la génération du résumé : $e');
    }
  }

  Future<void> _handleGenerateFlashcards() async {
    if (_attachedFileContent == null || _attachedFileContent!.isEmpty) {
      _addAiMessage('Aucun document chargé pour générer des flashcards.');
      return;
    }
    if (!_isModelReady) {
      _addAiMessage(
        'Le modèle IA n\'est pas encore prêt, patiente quelques secondes.',
      );
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          author: MessageAuthor.user,
          text: 'Generate flashcards from this document.',
          time: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final cards = await gemma.generateFlashcards(
        _attachedFileContent!,
        count: 10,
      );
      if (cards.isEmpty) {
        _addAiMessage('Je n\'ai pas réussi à générer de flashcards, réessaie.');
        return;
      }
      final formatted = cards
          .asMap()
          .entries
          .map(
            (e) =>
                'Q${e.key + 1}: ${e.value['question']}\nA${e.key + 1}: ${e.value['answer']}',
          )
          .join('\n\n');
      _addAiMessage(
        formatted,
        sources: _attachedFileName != null ? [_attachedFileName!] : null,
      );
    } catch (e) {
      _addAiMessage('Erreur pendant la génération des flashcards : $e');
    }
  }

  Future<void> _handleGenerateQuiz() async {
    _addAiMessage(
      'La génération de quiz arrive bientôt — pas encore implémentée.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoadingFile ||
                _attachedFileName != null ||
                _fileLoadError != null)
              _buildAttachmentBanner(),
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
              icon: const Icon(Icons.add, size: 20),
              color: NazariColors.black,
              onPressed: () {
                _toggleActionMenu();
                setState(() {});
              },
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your study',
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

  Widget _buildAttachmentBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingFile)
                      const Text(
                        'Loading document...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (_fileLoadError != null)
                      const Text(
                        'Error loading document',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      )
                    else
                      Text(
                        'Document loaded : ${_attachedFileName ?? 'No document'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoadingFile
                          ? 'Please wait...'
                          : _fileLoadError ??
                                _attachedFilePath ??
                                'No document attached',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _fileLoadError != null
                            ? Colors.red
                            : NazariColors.grayMid,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoadingFile && _attachedFileSize != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '${(_attachedFileSize! / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NazariColors.grayMid,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
