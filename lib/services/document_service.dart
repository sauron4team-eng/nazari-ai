import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/document.dart';

/// Service d'upload et d'extraction de documents (Option A: prompt stuffing)
/// Supporte PDF, DOCX, images (OCR via Gemma multimodal), TXT.
///
/// NOTE: Les packages d'extraction (pdf_text, docx_to_text) doivent être
/// ajoutés dans pubspec.yaml. En attendant, des TODOs marquent les points d'intégration.

class DocumentService {
  Database? _db;
  static const String _table = 'documents';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'nazari_documents.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            fileName TEXT NOT NULL,
            filePath TEXT NOT NULL,
            fileType TEXT NOT NULL,
            extractedText TEXT NOT NULL,
            pageCount INTEGER DEFAULT 0,
            uploadedAt TEXT NOT NULL,
            tokenEstimate INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  /// Upload un fichier depuis le gestionnaire de fichiers
  Future<Document> uploadDocument(String sourcePath) async {
    final file = File(sourcePath);
    final fileName = p.basename(sourcePath);
    final ext = p.extension(fileName).toLowerCase();
    String fileType;
    switch (ext) {
      case '.pdf':
        fileType = 'pdf';
        break;
      case '.docx':
        fileType = 'docx';
        break;
      case '.txt':
        fileType = 'txt';
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
        fileType = 'image';
        break;
      default:
        fileType = 'unknown';
    }

    // Copie dans le dossier app
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory(p.join(appDir.path, 'documents'));
    if (!await docsDir.exists()) await docsDir.create(recursive: true);
    final destPath = p.join(docsDir.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
    await file.copy(destPath);

    // Extraction du texte
    final extractedText = await _extractText(destPath, fileType);
    final tokenEstimate = _estimateTokens(extractedText);

    final doc = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      filePath: destPath,
      fileType: fileType,
      extractedText: extractedText,
      pageCount: 0, // TODO: extraire vrai nombre de pages si PDF
      uploadedAt: DateTime.now(),
      tokenEstimate: tokenEstimate,
    );

    final db = await database;
    await db.insert(_table, doc.toMap());
    return doc;
  }

  Future<String> _extractText(String filePath, String fileType) async {
    try {
      switch (fileType) {
        case 'txt':
          return await File(filePath).readAsString();

        case 'pdf':
          // TODO: Ajouter pdf_text: ^0.5.0 dans pubspec.yaml
          // import 'package:pdf_text/pdf_text.dart';
          // final pdfDoc = await PDFDoc.fromPath(filePath);
          // return await pdfDoc.text;
          return await _mockExtract('PDF content extracted from $filePath');

        case 'docx':
          // TODO: Ajouter docx_to_text: ^1.0.0 dans pubspec.yaml
          // import 'package:docx_to_text/docx_to_text.dart';
          // final bytes = await File(filePath).readAsBytes();
          // return docxToText(bytes, filePath);
          return await _mockExtract('DOCX content extracted from $filePath');

        case 'image':
          // Pour les images, on ne peut pas extraire de texte brut ici.
          // Gemma 4 E2B est multimodal — on passera le chemin de l'image
          // directement au modèle lors du prompt.
          return '[IMAGE_FILE:$filePath]';

        default:
          return 'Unsupported file type: $fileType';
      }
    } catch (e) {
      return 'Error extracting text: \$e';
    }
  }

  Future<String> _mockExtract(String placeholder) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return placeholder;
  }

  int _estimateTokens(String text) {
    // Estimation grossière: ~4 caractères = 1 token
    return (text.length / 4).ceil();
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'uploadedAt DESC');
    return maps.map((m) => Document.fromMap(m)).toList();
  }

  Future<Document?> getDocument(String id) async {
    final db = await database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Document.fromMap(maps.first);
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final filePath = maps.first['filePath'] as String;
      try {
        await File(filePath).delete();
      } catch (_) {}
    }
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
