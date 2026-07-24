import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

const _modelFileName = 'gemma-4-E2B-it.litertlm';
const _modelUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

/// Dossier partagé où un utilisateur peut déposer manuellement le fichier
/// modèle (ex: reçu d'un ami), sur le même principe que les dossiers ROM
/// des émulateurs Android.
const _sharedFolderPath = '/storage/emulated/0/NazariAI/models';

/// Garde-fou anti fichier incomplet/corrompu (le modèle réel fait ~2.4 Go).
const _expectedMinSizeBytes = 2000000000;

/// Limite de caractères injectés depuis un document dans le prompt système,
/// pour rester sous la limite de tokens du modèle (maxTokens ci-dessous).
/// ~4 caractères par token en moyenne pour le français/anglais.
const _maxContextChars = 6000;

// ---------------------------------------------------------------------------
// État interne du module (pas de classe, uniquement des variables privées)
// ---------------------------------------------------------------------------

InferenceModel? _activeModel;
InferenceChat? _activeChat;

// ---------------------------------------------------------------------------
// États possibles pour l'écran d'accueil
// ---------------------------------------------------------------------------

enum GemmaReadiness {
  /// Un modèle est déjà actif, prêt à être utilisé immédiatement.
  ready,

  /// Aucun modèle actif, mais un fichier valide a été trouvé dans le
  /// dossier partagé — installation locale rapide possible, sans réseau.
  sharedFileAvailable,

  /// Aucun modèle actif et aucun fichier local trouvé — un téléchargement
  /// réseau sera nécessaire.
  needsDownload,
}

/// À utiliser sur l'écran d'accueil pour savoir quoi afficher,
/// sans déclencher de téléchargement ni d'installation.
Future<GemmaReadiness> checkGemmaReadiness() async {
  if (FlutterGemma.hasActiveModel()) {
    return GemmaReadiness.ready;
  }
  final sharedPath = await findSharedModelFile();
  if (sharedPath != null) {
    return GemmaReadiness.sharedFileAvailable;
  }
  return GemmaReadiness.needsDownload;
}

// ---------------------------------------------------------------------------
// Installation / activation du modèle
// ---------------------------------------------------------------------------

/// Vérifie si le modèle est répertorié comme installé dans le stockage
/// interne géré par le plugin. Note : ceci NE garantit PAS qu'un modèle
/// est actif pour le process en cours — voir [FlutterGemma.hasActiveModel].
Future<bool> isGemmaModelInstalled() {
  return FlutterGemma.isModelInstalled(_modelFileName);
}

/// Cherche le fichier modèle dans le dossier partagé (pattern "PSP-like").
/// Retourne le chemin si trouvé et de taille valide, sinon null.
Future<String?> findSharedModelFile() async {
  final status = await Permission.manageExternalStorage.status;
  if (!status.isGranted) {
    final result = await Permission.manageExternalStorage.request();
    if (!result.isGranted) return null;
  }

  final dir = Directory(_sharedFolderPath);
  if (!await dir.exists()) return null;

  final expectedFile = File('${dir.path}/$_modelFileName');
  if (await expectedFile.exists()) {
    final size = await expectedFile.length();
    if (size >= _expectedMinSizeBytes) {
      return expectedFile.path;
    }
    return null; // présent mais probablement corrompu/incomplet
  }

  return null;
}

/// Crée le dossier partagé s'il n'existe pas, et retourne son chemin.
/// Utile pour afficher l'emplacement exact à l'utilisateur (onboarding).
Future<String> ensureSharedFolderExists() async {
  final status = await Permission.manageExternalStorage.status;
  if (!status.isGranted) {
    await Permission.manageExternalStorage.request();
  }

  final dir = Directory(_sharedFolderPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir.path;
}

/// Télécharge le modèle depuis le réseau (nécessite une connexion).
Future<void> _downloadGemmaModel({
  required void Function(int percent) onProgress,
}) async {
  await FlutterGemma.installModel(
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
  ).fromNetwork(_modelUrl).withProgress(onProgress).install();
}

/// Logique unifiée d'activation du modèle :
/// 1. Si un modèle est déjà actif pour ce process → rien à faire.
/// 2. Sinon, si un fichier valide existe dans le dossier partagé →
///    installation/activation locale, sans réseau.
/// 3. Sinon → téléchargement réseau.
///
/// Important : on se fie à [FlutterGemma.hasActiveModel], pas à
/// [isGemmaModelInstalled] seul, car un modèle peut être répertorié comme
/// "installé" (fichiers présents) sans être "actif" pour la session en
/// cours (l'identité active vit en mémoire pour le process, restaurée par
/// FlutterGemma.initialize() au démarrage de l'app).
Future<void> setupGemmaModel({
  required void Function(int percent) onProgress,
}) async {
  if (FlutterGemma.hasActiveModel()) {
    debugPrint('✅ Modèle déjà actif, rien à faire.');
    return;
  }

  final sharedFilePath = await findSharedModelFile();
  debugPrint('🔍 findSharedModelFile: $sharedFilePath');

  if (sharedFilePath != null) {
    debugPrint('📦 Activation depuis le fichier local...');
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(sharedFilePath).install();
    debugPrint(
      '✅ Modèle activé depuis fichier local. hasActiveModel = ${FlutterGemma.hasActiveModel()}',
    );
    return;
  }

  debugPrint('🌐 Aucun fichier local trouvé, téléchargement réseau...');
  await _downloadGemmaModel(onProgress: onProgress);
  debugPrint(
    '✅ Téléchargement terminé. hasActiveModel = ${FlutterGemma.hasActiveModel()}',
  );
}

// ---------------------------------------------------------------------------
// Chargement du modèle en mémoire et session de chat
// ---------------------------------------------------------------------------

Future<InferenceModel> _ensureModelLoaded() async {
  if (_activeModel != null) return _activeModel!;
  try {
    _activeModel = await FlutterGemma.getActiveModel(
      maxTokens: 8192,
      preferredBackend: PreferredBackend.gpu,
    );
  } catch (_) {
    _activeModel = await FlutterGemma.getActiveModel(
      maxTokens: 8192,
      preferredBackend: PreferredBackend.cpu,
    );
  }
  return _activeModel!;
}

/// Démarre (ou redémarre) une session de chat.
///
/// [documentContext] : contenu du document attaché, s'il y en a un. Le
/// texte est tronqué défensivement pour éviter de dépasser la fenêtre de
/// contexte du modèle (voir [_maxContextChars]) — à terme, remplacer par
/// une sélection des chunks les plus pertinents (RAG) plutôt qu'une simple
/// troncature.
Future<void> startChatSession({String? documentContext}) async {
  final model = await _ensureModelLoaded();

  String? truncatedContext = documentContext;
  if (documentContext != null && documentContext.length > _maxContextChars) {
    truncatedContext =
        '${documentContext.substring(0, _maxContextChars)}\n[...document tronqué...]';
  }

  const baseInstruction =
      'You are NazariAI, a warm and supportive study assistant for students. '
      'You help with two things: '
      '(1) answering questions about the student\'s uploaded documents, and '
      '(2) being a friendly, encouraging presence for general conversation — '
      'including exam stress, motivation, study techniques, and how to relax before or during exam prep. '
      'If a student seems stressed or anxious, respond with empathy first, then offer practical, '
      'grounded suggestions (short breaks, breathing, breaking work into small steps, realistic planning). '
      'Keep advice general and supportive, not clinical — you are not a therapist or doctor. '
      'If a student\'s distress seems serious or ongoing, gently encourage them to talk to someone '
      'they trust, like a friend, family member, teacher, or counselor. '
      'Answer in the same language the student uses to write to you.';

  final systemInstruction =
      (truncatedContext != null && truncatedContext.isNotEmpty)
      ? '$baseInstruction\n\n'
            'When the student asks about their document, ground your answer in the context below. '
            'If the information isn\'t there, say so clearly rather than making it up.\n\n'
            'DOCUMENT CONTEXT:\n$truncatedContext'
      : baseInstruction;

  _activeChat = await model.createChat(systemInstruction: systemInstruction);
}

/// Envoie un message utilisateur et retourne la réponse en streaming
/// (le Stream émet le texte cumulé au fil des tokens générés).
Stream<String> sendChatMessage(String userMessage) async* {
  if (_activeChat == null) {
    throw StateError(
      'Session de chat non initialisée. Appeler startChatSession() d\'abord.',
    );
  }

  await _activeChat!.addQueryChunk(
    Message.text(text: userMessage, isUser: true),
  );

  final buffer = StringBuffer();
  await for (final response in _activeChat!.generateChatResponseAsync()) {
    if (response is TextResponse) {
      buffer.write(response.token);
      yield buffer.toString();
    }
  }
}

/// Extrait le texte d'un ModelResponse. Retourne une chaîne vide si la
/// réponse n'est pas de type texte (ex: appel de fonction, pensée interne).
String _extractText(ModelResponse response) {
  if (response is TextResponse) {
    return response.token;
  }
  return '';
}

// ---------------------------------------------------------------------------
// Résumé de document
// ---------------------------------------------------------------------------

/// Génère un résumé du document à partir de son contenu texte complet.
/// Utilise une session de chat dédiée et indépendante, sans impacter
/// la session de chat principale de l'utilisateur.
Future<String> summarizeDocument(String documentText) async {
  final model = await _ensureModelLoaded();

  String textToSummarize = documentText;
  if (documentText.length > _maxContextChars) {
    textToSummarize =
        '${documentText.substring(0, _maxContextChars)}\n[...document tronqué...]';
  }

  final summaryChat = await model.createChat(
    systemInstruction:
        'You are a study assistant that summarizes academic documents clearly and concisely. '
        'Produce a summary in the same language as the document, structured in 5 to 10 key points.',
  );

  await summaryChat.addQueryChunk(
    Message.text(
      text: 'Summarize the following document:\n\n$textToSummarize',
      isUser: true,
    ),
  );

  final response = await summaryChat.generateChatResponse();
  return _extractText(response);
}

// ---------------------------------------------------------------------------
// Génération de flashcards
// ---------------------------------------------------------------------------

/// Génère des flashcards à partir du contenu texte d'un document.
/// Utilise une session de chat dédiée et indépendante de la session
/// de chat principale.
Future<List<Map<String, String>>> generateFlashcards(
  String documentText, {
  int count = 10,
}) async {
  final model = await _ensureModelLoaded();

  String textForFlashcards = documentText;
  if (documentText.length > _maxContextChars) {
    textForFlashcards =
        '${documentText.substring(0, _maxContextChars)}\n[...document tronqué...]';
  }

  final flashcardChat = await model.createChat(
    systemInstruction:
        'You are a study assistant that creates flashcards from academic documents. '
        'You must respond with ONLY a valid JSON array, no explanation, no markdown code fences, '
        'no text before or after. '
        'Each flashcard must be a clear, self-contained question and a concise, accurate answer. '
        'Cover the most important concepts in the document, avoid trivial or overly narrow details. '
        'Write the flashcards in the same language as the document. '
        'Required format: [{"question": "...", "answer": "..."}, ...]',
  );

  await flashcardChat.addQueryChunk(
    Message.text(
      text:
          'Create exactly $count flashcards from this document:\n\n$textForFlashcards',
      isUser: true,
    ),
  );

  final raw = await flashcardChat.generateChatResponse();
  return _parseFlashcardsJson(_extractText(raw));
}

/// Parsing tolérant : gère les cas où le modèle ajoute des fences ```json
/// ou du texte parasite autour du JSON attendu.
List<Map<String, String>> _parseFlashcardsJson(String raw) {
  var cleaned = raw.trim();
  cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();

  final start = cleaned.indexOf('[');
  final end = cleaned.lastIndexOf(']');
  if (start != -1 && end != -1 && end > start) {
    cleaned = cleaned.substring(start, end + 1);
  }

  try {
    final decoded = jsonDecode(cleaned) as List;
    return decoded
        .whereType<Map>()
        .map(
          (e) => {
            'question': (e['question'] ?? '').toString(),
            'answer': (e['answer'] ?? '').toString(),
          },
        )
        .where(
          (card) => card['question']!.isNotEmpty && card['answer']!.isNotEmpty,
        )
        .toList();
  } catch (e) {
    debugPrint('❌ Erreur parsing flashcards JSON: $e');
    debugPrint('Réponse brute reçue: $raw');
    return [];
  }
}

Future<void> disposeGemma() async {
  await _activeModel?.close();
  _activeModel = null;
  _activeChat = null;
}
