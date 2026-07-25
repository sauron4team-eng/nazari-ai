import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Un chunk de texte, avec le numéro de page d'origine si applicable
/// (null pour les formats sans notion de page : txt, docx, doc)
class DocumentChunk {
  final int? pageNumber;
  final String text;

  DocumentChunk({required this.text, this.pageNumber});

  Map<String, dynamic> toJson() => {'pageNumber': pageNumber, 'text': text};

  factory DocumentChunk.fromJson(Map<String, dynamic> json) => DocumentChunk(
    pageNumber: json['pageNumber'] as int?,
    text: json['text'] as String,
  );
}

/// Modèle pour un document avec ses chunks
class DocumentChunks {
  final String documentId;
  final String fileName;
  final int fileSize;
  final String fileType;
  final DateTime createdAt;
  final List<DocumentChunk> chunks;

  DocumentChunks({
    required this.documentId,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
    required this.chunks,
  });

  /// Convertir en JSON pour le stockage
  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'fileName': fileName,
    'fileSize': fileSize,
    'fileType': fileType,
    'createdAt': createdAt.toIso8601String(),
    'chunks': chunks.map((c) => c.toJson()).toList(),
  };

  /// Créer depuis JSON
  factory DocumentChunks.fromJson(Map<String, dynamic> json) => DocumentChunks(
    documentId: json['documentId'],
    fileName: json['fileName'],
    fileSize: json['fileSize'],
    fileType: json['fileType'],
    createdAt: DateTime.parse(json['createdAt']),
    chunks: (json['chunks'] as List)
        .map((c) => DocumentChunk.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}

/// Service pour gérer l'ajout et la gestion des documents
class DocumentsService {
  /// Retourne l'icône appropriée pour une extension de fichier donnée
  static String getIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'doc':
      case 'docx':
        return 'description';
      case 'txt':
        return 'article';
      default:
        return 'insert_drive_file';
    }
  }

  /// Ajoute un document en utilisant FilePicker
  /// Retourne un Map contenant les informations du document
  /// Retourne null si l'utilisateur annule ou si une erreur se produit
  static Future<Map<String, dynamic>?> addDocument() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final path = file.path;
      if (path == null) return null;

      final extension =
          (file.extension ?? p.extension(path).replaceFirst('.', ''))
              .toLowerCase();
      final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);

      final shortPath = path.length > 120
          ? '...${path.substring(path.length - 120)}'
          : path;
      debugPrint('Selected path (shortened) : $shortPath');
      debugPrint('File name : ${file.name}');

      final documentData = {
        'title': file.name,
        'type': extension,
        'size': file.size,
        'meta': 'Added just now • $sizeMb MB',
        'icon': getIcon(extension),
        'path': path,
      };

      debugPrint('Document added : ${file.name}');
      return documentData;
    } catch (e) {
      debugPrint('Error adding document : $e');
      return null;
    }
  }

  /// Extrait les chunks d'un fichier selon son type
  /// Supporte : txt, pdf, doc, docx
  /// - pdf : un chunk par page (re-découpée si trop longue)
  /// - autres formats : chunks par nombre de caractères, sans pageNumber
  static Future<List<DocumentChunk>> extractChunksFromFile(
    String filePath, {
    int maxChunkSize = 800,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Missing file : $filePath');
      }

      final extension = p
          .extension(filePath)
          .replaceFirst('.', '')
          .toLowerCase();

      if (extension == 'pdf') {
        final bytes = await file.readAsBytes();
        return _extractPdfChunksByPage(bytes, maxChunkSize: maxChunkSize);
      }

      // Pour tous les autres formats : extraction en un seul texte,
      // puis découpage par caractères sans notion de page
      String text;
      if (extension == 'txt') {
        text = await file.readAsString(encoding: utf8);
      } else if (extension == 'docx') {
        final bytes = await file.readAsBytes();
        text = await _extractDocxText(bytes);
      } else {
        // 'doc' et fallback
        // TODO: .doc est un format binaire OLE non supporté nativement.
        // Recommandation : demander une conversion en .docx / .pdf en amont,
        // ou passer par un service externe (LibreOffice headless, Apache Tika...).
        final bytes = await file.readAsBytes();
        text = utf8.decode(bytes, allowMalformed: true);
      }

      final rawChunks = chunkText(text, maxChunkSize: maxChunkSize);
      return rawChunks.map((t) => DocumentChunk(text: t)).toList();
    } catch (e) {
      debugPrint('Error occurred while extracting content : $e');
      rethrow;
    }
  }

  /// Extrait le texte d'un PDF page par page avec Syncfusion,
  /// et retourne un DocumentChunk par page (re-découpée si trop longue,
  /// en conservant le même pageNumber pour les sous-chunks)
  static Future<List<DocumentChunk>> _extractPdfChunksByPage(
    List<int> bytes, {
    int maxChunkSize = 800,
  }) async {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final chunks = <DocumentChunk>[];

      for (int i = 0; i < document.pages.count; i++) {
        final pageNumber =
            i + 1; // pages affichées à l'utilisateur en 1-indexed
        final rawPageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        final pageText = _cleanText(rawPageText);

        if (pageText.isEmpty) continue;

        if (pageText.length <= maxChunkSize) {
          chunks.add(DocumentChunk(text: pageText, pageNumber: pageNumber));
        } else {
          // Page trop longue : re-découpage en sous-chunks
          // qui gardent tous le même numéro de page
          final subChunks = chunkText(pageText, maxChunkSize: maxChunkSize);
          for (final sub in subChunks) {
            chunks.add(DocumentChunk(text: sub, pageNumber: pageNumber));
          }
        }
      }

      return chunks;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      throw Exception('Failed to extract PDF content: $e');
    } finally {
      document?.dispose();
    }
  }

  /// Extrait le texte d'un fichier DOCX (qui est une archive ZIP contenant du XML)
  static Future<String> _extractDocxText(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      String fullText = '';

      // Chercher le fichier document.xml qui contient le texte principal
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          final content = utf8.decode(file.content as List<int>);
          // Extraire le texte entre les balises <w:t>...
          final regex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
          final matches = regex.allMatches(content);
          for (final match in matches) {
            fullText += match.group(1) ?? '';
            fullText += ' ';
          }
          break;
        }
      }

      return _cleanText(
        fullText.isNotEmpty ? fullText : 'Unable to extract text from DOCX',
      );
    } catch (e) {
      debugPrint('Error extracting DOCX text: $e');
      throw Exception('Failed to extract DOCX content: $e');
    }
  }

  /// Nettoie le texte en supprimant les caractères corrompus et non imprimables
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Divise un texte brut en chunks de taille fixe (sans notion de page)
  static List<String> chunkText(String text, {int maxChunkSize = 800}) {
    final chunks = <String>[];
    final normalized = text.replaceAll('\r\n', '\n').trim();

    if (normalized.isEmpty) return chunks;

    for (var start = 0; start < normalized.length; start += maxChunkSize) {
      final end = (start + maxChunkSize).clamp(0, normalized.length);
      chunks.add(normalized.substring(start, end));
    }

    return chunks;
  }

  /// Traite un document entier, extrait les chunks et les stocke
  /// Retourne un DocumentChunks avec tous les chunks (avec pageNumber pour les PDF)
  static Future<DocumentChunks?> processAndStoreDocument(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File not found: $filePath');
        return null;
      }

      final fileName = p.basename(filePath);
      final fileSize = await file.length();
      final extension = p
          .extension(filePath)
          .replaceFirst('.', '')
          .toLowerCase();
      final documentId = _generateDocumentId(fileName);

      final chunks = await extractChunksFromFile(filePath);

      if (chunks.isEmpty) {
        debugPrint('No content extracted from document');
        return null;
      }

      final documentChunks = DocumentChunks(
        documentId: documentId,
        fileName: fileName,
        fileSize: fileSize,
        fileType: extension,
        createdAt: DateTime.now(),
        chunks: chunks,
      );

      await _storeDocumentChunks(documentChunks);
      debugPrint('Document stored: $fileName with ${chunks.length} chunks');

      return documentChunks;
    } catch (e) {
      debugPrint('Error processing document: $e');
      rethrow;
    }
  }

  /// Stocke les chunks d'un document en persistance
  static Future<void> _storeDocumentChunks(DocumentChunks doc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(doc.toJson());
      await prefs.setString('doc_${doc.documentId}', jsonString);

      final docIds = prefs.getStringList('stored_document_ids') ?? [];
      if (!docIds.contains(doc.documentId)) {
        docIds.add(doc.documentId);
        await prefs.setStringList('stored_document_ids', docIds);
      }

      debugPrint('Document chunks stored successfully');
    } catch (e) {
      debugPrint('Error storing document chunks: $e');
      rethrow;
    }
  }

  /// Récupère un document stocké par son ID
  static Future<DocumentChunks?> getStoredDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('doc_$documentId');

      if (jsonString == null) {
        debugPrint('Document not found: $documentId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return DocumentChunks.fromJson(json);
    } catch (e) {
      debugPrint('Error retrieving document: $e');
      return null;
    }
  }

  /// Liste tous les documents stockés
  static Future<List<DocumentChunks>> getAllStoredDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docIds = prefs.getStringList('stored_document_ids') ?? [];
      final documents = <DocumentChunks>[];

      for (final id in docIds) {
        final doc = await getStoredDocument(id);
        if (doc != null) {
          documents.add(doc);
        }
      }

      return documents;
    } catch (e) {
      debugPrint('Error retrieving all documents: $e');
      return [];
    }
  }

  /// Supprime un document stocké
  static Future<bool> deleteStoredDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('doc_$documentId');

      final docIds = prefs.getStringList('stored_document_ids') ?? [];
      docIds.remove(documentId);
      await prefs.setStringList('stored_document_ids', docIds);

      debugPrint('Document deleted: $documentId');
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  /// Génère un ID unique pour un document basé sur le nom et la date
  static String _generateDocumentId(String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .toLowerCase();
    return '${cleanName}_$timestamp';
  }

  /// Obtient les chunks d'un document stocké (pour l'agent IA)
  static Future<List<DocumentChunk>> getDocumentChunksForAI(
    String documentId,
  ) async {
    final doc = await getStoredDocument(documentId);
    return doc?.chunks ?? [];
  }

  /// Récupère uniquement les chunks appartenant à une page donnée
  /// (pageNumber en 1-indexed, comme affiché à l'utilisateur)
  static Future<List<DocumentChunk>> getChunksForPage(
    String documentId,
    int pageNumber,
  ) async {
    final doc = await getStoredDocument(documentId);
    if (doc == null) return [];
    return doc.chunks.where((c) => c.pageNumber == pageNumber).toList();
  }

  /// Combine tous les chunks d'un document en un seul texte
  /// (préfixe chaque page avec son numéro pour les PDF)
  static Future<String> getFullDocumentText(String documentId) async {
    final doc = await getStoredDocument(documentId);
    if (doc == null) return '';

    final buffer = StringBuffer();
    int? lastPage;
    for (final chunk in doc.chunks) {
      if (chunk.pageNumber != null && chunk.pageNumber != lastPage) {
        buffer.writeln('\n[Page ${chunk.pageNumber}]');
        lastPage = chunk.pageNumber;
      }
      buffer.writeln(chunk.text);
    }
    return buffer.toString().trim();
  }
}
