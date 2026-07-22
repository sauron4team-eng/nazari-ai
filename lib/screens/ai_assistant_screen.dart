import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

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
  List<String> _documentChunks = [];

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

      final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
      final text = await _extractTextFromFile(file, extension);
      if (text.trim().isEmpty) {
        throw Exception('Le document ne contient pas de texte exploitable.');
      }

      final bytes = await file.length();
      final chunks = _chunkDocumentText(text);

      setState(() {
        _attachedFilePath = path;
        _attachedFileName = p.basename(path);
        _attachedFileSize = bytes;
        _attachedFileContent = text;
        _documentChunks = chunks;
      });
      debugPrint('Fichier attaché : $_attachedFileName');
      _addAiMessage(
        'Document "${_attachedFileName!}" chargé localement. Vous pouvez maintenant poser une question sur son contenu.',
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

  Future<String> _extractTextFromFile(File file, String extension) async {
    if (extension == 'txt') {
      return await file.readAsString(encoding: utf8);
    }

    final bytes = await file.readAsBytes();
    if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
      // Extraction simple en UTF-8 comme fallback, car aucun parseur spécialisé
      // n'est installé. Remplacer par un parseur réel si disponible.
      return utf8.decode(bytes, allowMalformed: true);
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  List<String> _chunkDocumentText(String text) {
    const maxChunkSize = 800;
    final chunks = <String>[];
    final normalized = text.replaceAll('\r\n', '\n').trim();
    for (var start = 0; start < normalized.length; start += maxChunkSize) {
      final end = (start + maxChunkSize).clamp(0, normalized.length);
      chunks.add(normalized.substring(start, end));
    }
    return chunks;
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
      return 'Aucun document chargé. Cliquez sur un fichier dans l’écran Documents pour le charger et analyser son contenu.';
    }

    final queryLower = query.toLowerCase();
    final matchingChunk = _documentChunks.firstWhere(
      (chunk) => chunk.toLowerCase().contains(queryLower),
      orElse: () => _documentChunks.isNotEmpty ? _documentChunks.first : '',
    );

    if (matchingChunk.isEmpty) {
      return 'J’ai chargé "${_attachedFileName}", mais je n’ai pas trouvé d’extrait clair pour "$query". Pose une question plus précise ou vérifie le document.';
    }

    final excerpt = matchingChunk.length > 250
        ? '${matchingChunk.substring(0, 250).trim()}...'
        : matchingChunk.trim();
    return 'Hi I am your AI assistant. The attached file is titled: "${_attachedFileName}". Please ask a more specific question about the document for a better answer.';
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingFile)
                  const Text(
                    'Chargement du document...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  )
                else if (_fileLoadError != null)
                  const Text(
                    'Erreur de chargement du document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  )
                else
                  Text(
                    'Document chargé : ${_attachedFileName ?? 'Aucun document'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _isLoadingFile
                      ? 'Veuillez patienter...'
                      : _fileLoadError ??
                            _attachedFilePath ??
                            'Aucun document attaché',
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
