import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _attachFile(widget.initialFilePath!);
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

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

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

    final response = _generateLocalResponse(text);
    _addAiMessage(
      response,
      sources: _attachedFileName != null ? [_attachedFileName!] : null,
    );
  }

  String _generateLocalResponse(String query) {
    if (_attachedFileContent == null || _attachedFileContent!.isEmpty) {
      return 'No document loaded. Click on a file in the Documents screen to load and analyze its content.';
    }

    final queryLower = query.toLowerCase();

    // firstWhere doit comparer chunk.text (String) et non le chunk lui-même
    // (chunk est un DocumentChunk depuis la nouvelle API)
    DocumentChunk? matchingChunk;
    for (final chunk in _documentChunks) {
      if (chunk.text.toLowerCase().contains(queryLower)) {
        matchingChunk = chunk;
        break;
      }
    }
    matchingChunk ??= _documentChunks.isNotEmpty ? _documentChunks.first : null;

    if (matchingChunk == null || matchingChunk.text.isEmpty) {
      return 'I have loaded "$_attachedFileName", but I couldn\'t find a clear excerpt for "$query". Please ask a more specific question or check the document.';
    }

    final excerpt = matchingChunk.text.length > 250
        ? '${matchingChunk.text.substring(0, 250).trim()}...'
        : matchingChunk.text.trim();

    // Le numéro de page est maintenant disponible pour les PDF : on l'ajoute
    // à la réponse quand il existe.
    final pageInfo = matchingChunk.pageNumber != null
        ? ' (page ${matchingChunk.pageNumber})'
        : '';

    return 'Hi I am your AI assistant. The attached file is titled: "$_attachedFileName"$pageInfo. Here is a relevant excerpt: "$excerpt" Please ask a more specific question about the document for a better answer.';
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
          // Affichage de tous les chunks
          if (_documentChunks.isNotEmpty && !_isLoadingFile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contenu du document :',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NazariColors.grayMid,
                      ),
                    ),
                    Text(
                      '${_documentChunks.length} chunks',
                      style: const TextStyle(
                        fontSize: 11,
                        color: NazariColors.grayLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _documentChunks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final chunk = entry.value;
                        // chunk.text au lieu de chunk (String) directement
                        final preview = chunk.text.length > 150
                            ? '${chunk.text.substring(0, 150).trim()}...'
                            : chunk.text.trim();
                        // Label enrichi avec le numéro de page si disponible
                        // (uniquement pour les PDF)
                        final label = chunk.pageNumber != null
                            ? 'Chunk ${index + 1}/${_documentChunks.length} • Page ${chunk.pageNumber}'
                            : 'Chunk ${index + 1}/${_documentChunks.length}';
                        return Column(
                          children: [
                            if (index > 0)
                              const Divider(
                                height: 1,
                                color: Color(0xFFF0F0F0),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: NazariColors.grayLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preview,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: NazariColors.grayMid,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
