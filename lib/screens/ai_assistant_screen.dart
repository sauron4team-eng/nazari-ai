import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../services/gemma_service.dart';
import '../services/chat_history_service.dart';
import '../services/document_service.dart';
import '../services/prompt_engineering.dart';
import '../models/conversation.dart';
import '../models/document.dart';

/// AI Assistant Screen — Chat avec Gemma 4 (100% offline)
///
/// Fonctionnalités:
/// - Envoi de messages texte à Gemma
/// - Upload de documents (PDF, DOCX, images) comme contexte
/// - Historique de conversation persistant (Hive)
/// - Titre auto-généré pour chaque conversation
/// - Indicateur "Gemma is thinking..." pendant la génération
/// - Réponses structurées avec possibilité de sources

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late GemmaService _gemma;
  late ChatHistoryService _chatHistory;
  late DocumentService _docService;

  Conversation? _conversation;
  List<Message> _messages = [];
  bool _isLoading = false;
  Document? _attachedDocument;

  @override
  void initState() {
    super.initState();
    _gemma = context.read<GemmaService>();
    _chatHistory = context.read<ChatHistoryService>();
    _docService = context.read<DocumentService>();
    _loadOrCreateConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Crée une nouvelle conversation ou charge la dernière
  Future<void> _loadOrCreateConversation() async {
    final conversations = await _chatHistory.getAllConversations();
    if (conversations.isNotEmpty) {
      setState(() {
        _conversation = conversations.first;
        _messages = List.from(_conversation!.messages);
      });
    }
  }

  /// Crée une nouvelle conversation si besoin
  Future<void> _ensureConversation(String firstMessage) async {
    if (_conversation != null) return;

    // Génère un titre via Gemma (async, non bloquant pour l'UI)
    String title = 'New Chat';
    try {
      title = await _gemma.generate(
        PromptEngineering.generateTitle(firstMessage),
      );
      title = title.trim().replaceAll('"', '').replaceAll("'", '');
      if (title.length > 40) title = '${title.substring(0, 40)}...';
    } catch (_) {
      title = firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;
    }

    final conv = Conversation.create(title);
    await _chatHistory.saveConversation(conv);
    setState(() => _conversation = conv);
  }

  /// Envoi d'un message utilisateur + réponse Gemma
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();

    // 1. Créer le message utilisateur
    final userMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
      attachmentPath: _attachedDocument?.filePath,
      attachmentType: _attachedDocument?.fileType,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _attachedDocument = null; // reset après envoi
    });

    _scrollToBottom();

    // 2. Persister la conversation
    await _ensureConversation(text);
    _conversation!.messages.add(userMsg);
    _conversation!.updatedAt = DateTime.now();
    await _chatHistory.saveConversation(_conversation!);

    // 3. Construire le prompt avec contexte document si présent
    String prompt;
    if (_attachedDocument != null && _attachedDocument!.fileType != 'image') {
      prompt = PromptEngineering.answerQuestion(
        text,
        documentContext: _attachedDocument!.extractedText,
      );
    } else {
      prompt = PromptEngineering.answerQuestion(text);
    }

    // 4. Appeler Gemma
    try {
      final response = await _gemma.generate(prompt);

      final aiMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMsg);
        _isLoading = false;
      });

      // 5. Persister la réponse
      _conversation!.messages.add(aiMsg);
      _conversation!.updatedAt = DateTime.now();
      await _chatHistory.saveConversation(_conversation!);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gemma error: $e');
    }

    _scrollToBottom();
  }

  /// Upload un document depuis le gestionnaire de fichiers
  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await _docService.uploadDocument(result.files.single.path!);
      setState(() {
        _attachedDocument = doc;
        _isLoading = false;
      });
      _showInfo(
        'Document attached: ${doc.fileName} (${doc.tokenEstimate} tokens)',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to upload document: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.hankenGrotesk(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.hankenGrotesk(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B5D3B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7F2),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'AI Assistant',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            if (_conversation != null)
              Text(
                _conversation!.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              ),
          ],
        ),
        actions: [
          if (_conversation != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF6B7280)),
              onPressed: () async {
                await _chatHistory.deleteConversation(_conversation!.id);
                setState(() {
                  _conversation = null;
                  _messages = [];
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone messages
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return msg.role == 'user'
                            ? _UserBubble(message: msg)
                            : _AiBubble(message: msg);
                      },
                    ),
            ),

            // Indicateur "Gemma pense..."
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B5D3B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gemma is thinking...',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Document attaché
            if (_attachedDocument != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEFE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description,
                        size: 16,
                        color: Color(0xFF0B5D3B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _attachedDocument!.fileName,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: const Color(0xFF0B5D3B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _attachedDocument = null),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF0B5D3B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Barre de saisie
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFE5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology,
              color: Color(0xFF0B5D3B),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about your study!',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a document or type a question.\nGemma 4 will answer offline.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, size: 20),
              color: const Color(0xFF6B7280),
              onPressed: _isLoading ? null : _pickDocument,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Ask about your study...',
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  color: const Color(0xFF1F2937),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF0B5D3B),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, size: 16, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BULLES DE CHAT
// ═══════════════════════════════════════════════════════════

class _UserBubble extends StatelessWidget {
  final Message message;
  const _UserBubble({required this.message});

  String _formatTime(DateTime t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0B5D3B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          if (message.attachmentPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Document attached',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              'You • ${_formatTime(message.timestamp)}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final Message message;
  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEFE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 14,
                        color: Color(0xFF0B5D3B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NAZARIAI',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B5D3B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message.text,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 1.55,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'NazariAI • Locally Processed',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
