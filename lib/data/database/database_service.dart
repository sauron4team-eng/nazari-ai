import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:nazariai/data/models/document_model.dart';
import 'package:nazariai/data/models/chunk_model.dart';

/// Service pour gérer la base de données SQLite locale
class DatabaseService {
  static const String _dbName = 'nazariai.db';
  // Version incrémentée : ajout de la colonne pageNumber sur la table chunks
  static const int _dbVersion = 2;

  // Tables
  static const String _tableDocuments = 'documents';
  static const String _tableChunks = 'chunks';

  // Colonnes documents
  static const String _colDocId = 'id';
  static const String _colDocFileName = 'fileName';
  static const String _colDocFilePath = 'filePath';
  static const String _colDocFileType = 'fileType';
  static const String _colDocFileSize = 'fileSize';
  static const String _colDocFileHash = 'fileHash';
  static const String _colDocCreatedAt = 'createdAt';
  static const String _colDocUpdatedAt = 'updatedAt';
  static const String _colDocTotalChunks = 'totalChunks';
  static const String _colDocNotes = 'notes';

  // Colonnes chunks
  static const String _colChunkId = 'id';
  static const String _colChunkDocId = 'documentId';
  static const String _colChunkIndex = 'chunkIndex';
  static const String _colChunkContent = 'content';
  static const String _colChunkCharCount = 'charCount';
  static const String _colChunkPageNumber = 'pageNumber';
  static const String _colChunkCreatedAt = 'createdAt';

  static Database? _database;

  /// Initialiser ou récupérer la base de données
  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialiser la base de données
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Créer les tables
  static Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');

    // Table documents
    await db.execute('''
      CREATE TABLE $_tableDocuments (
        $_colDocId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colDocFileName TEXT NOT NULL,
        $_colDocFilePath TEXT NOT NULL UNIQUE,
        $_colDocFileType TEXT NOT NULL,
        $_colDocFileSize INTEGER NOT NULL,
        $_colDocFileHash TEXT NOT NULL UNIQUE,
        $_colDocCreatedAt TEXT NOT NULL,
        $_colDocUpdatedAt TEXT,
        $_colDocTotalChunks INTEGER NOT NULL,
        $_colDocNotes TEXT
      )
    ''');

    // Table chunks avec clé étrangère
    // pageNumber est nullable : rempli uniquement pour les PDF
    // (un chunk = une page), null pour txt/docx/doc
    await db.execute('''
      CREATE TABLE $_tableChunks (
        $_colChunkId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colChunkDocId INTEGER NOT NULL,
        $_colChunkIndex INTEGER NOT NULL,
        $_colChunkContent TEXT NOT NULL,
        $_colChunkCharCount INTEGER NOT NULL,
        $_colChunkPageNumber INTEGER,
        $_colChunkCreatedAt TEXT NOT NULL,
        FOREIGN KEY ($_colChunkDocId) REFERENCES $_tableDocuments ($_colDocId) ON DELETE CASCADE,
        UNIQUE($_colChunkDocId, $_colChunkIndex)
      )
    ''');

    debugPrint('Database tables created successfully');
  }

  /// Gérer les migrations de base de données
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Ajout de la colonne pageNumber (nullable, donc pas besoin de DEFAULT)
      // sur les bases déjà existantes en version 1.
      await db.execute(
        'ALTER TABLE $_tableChunks ADD COLUMN $_colChunkPageNumber INTEGER',
      );
      debugPrint('Migration v1 -> v2: added $_colChunkPageNumber column');
    }
  }

  // ============ OPÉRATIONS DOCUMENTS ============

  /// Insérer un document
  static Future<int> insertDocument(DocumentModel document) async {
    final db = await getDatabase();
    try {
      final id = await db.insert(
        _tableDocuments,
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      debugPrint('Document inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting document: $e');
      rethrow;
    }
  }

  /// Récupérer tous les documents
  static Future<List<DocumentModel>> getAllDocuments() async {
    final db = await getDatabase();
    try {
      final maps = await db.query(
        _tableDocuments,
        orderBy: '$_colDocCreatedAt DESC',
      );
      return maps.map((map) => DocumentModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching all documents: $e');
      return [];
    }
  }

  /// Récupérer un document par ID
  static Future<DocumentModel?> getDocumentById(int id) async {
    final db = await getDatabase();
    try {
      final maps = await db.query(
        _tableDocuments,
        where: '$_colDocId = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return DocumentModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error fetching document by ID: $e');
      return null;
    }
  }

  /// Récupérer un document par son hash (pour déterminer s'il existe déjà)
  static Future<DocumentModel?> getDocumentByHash(String hash) async {
    final db = await getDatabase();
    try {
      final maps = await db.query(
        _tableDocuments,
        where: '$_colDocFileHash = ?',
        whereArgs: [hash],
      );
      if (maps.isEmpty) return null;
      return DocumentModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error fetching document by hash: $e');
      return null;
    }
  }

  /// Mettre à jour un document
  static Future<int> updateDocument(DocumentModel document) async {
    final db = await getDatabase();
    try {
      final count = await db.update(
        _tableDocuments,
        document.toMap(),
        where: '$_colDocId = ?',
        whereArgs: [document.id],
      );
      debugPrint('Updated $count document(s)');
      return count;
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  /// Supprimer un document (cascade supprime aussi les chunks)
  static Future<int> deleteDocument(int id) async {
    final db = await getDatabase();
    try {
      final count = await db.delete(
        _tableDocuments,
        where: '$_colDocId = ?',
        whereArgs: [id],
      );
      debugPrint('Deleted $count document(s)');
      return count;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  // ============ OPÉRATIONS CHUNKS ============

  /// Insérer un chunk
  static Future<int> insertChunk(ChunkModel chunk) async {
    final db = await getDatabase();
    try {
      final id = await db.insert(
        _tableChunks,
        chunk.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      debugPrint('Chunk inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting chunk: $e');
      rethrow;
    }
  }

  /// Insérer plusieurs chunks en une transaction
  static Future<List<int>> insertChunks(List<ChunkModel> chunks) async {
    final db = await getDatabase();
    try {
      final ids = <int>[];
      await db.transaction((txn) async {
        for (final chunk in chunks) {
          final id = await txn.insert(
            _tableChunks,
            chunk.toMap(),
            conflictAlgorithm: ConflictAlgorithm.fail,
          );
          ids.add(id);
        }
      });
      debugPrint('Inserted ${ids.length} chunks');
      return ids;
    } catch (e) {
      debugPrint('Error inserting chunks: $e');
      rethrow;
    }
  }

  /// Récupérer tous les chunks d'un document
  static Future<List<ChunkModel>> getChunksByDocumentId(int documentId) async {
    final db = await getDatabase();
    try {
      final maps = await db.query(
        _tableChunks,
        where: '$_colChunkDocId = ?',
        whereArgs: [documentId],
        orderBy: '$_colChunkIndex ASC',
      );
      return maps.map((map) => ChunkModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching chunks by document ID: $e');
      return [];
    }
  }

  /// Récupérer les chunks d'une page donnée pour un document
  /// (pageNumber en 1-indexed ; utile pour cibler un extrait précis d'un PDF)
  static Future<List<ChunkModel>> getChunksByPage(
    int documentId,
    int pageNumber,
  ) async {
    final db = await getDatabase();
    try {
      final maps = await db.query(
        _tableChunks,
        where: '$_colChunkDocId = ? AND $_colChunkPageNumber = ?',
        whereArgs: [documentId, pageNumber],
        orderBy: '$_colChunkIndex ASC',
      );
      return maps.map((map) => ChunkModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching chunks by page: $e');
      return [];
    }
  }

  /// Récupérer un chunk spécifique
  static Future<ChunkModel?> getChunkById(int id) async {
    final db = await getDatabase();
    try {
      final maps = await db.query(
        _tableChunks,
        where: '$_colChunkId = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return ChunkModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error fetching chunk by ID: $e');
      return null;
    }
  }

  /// Mettre à jour un chunk
  static Future<int> updateChunk(ChunkModel chunk) async {
    final db = await getDatabase();
    try {
      final count = await db.update(
        _tableChunks,
        chunk.toMap(),
        where: '$_colChunkId = ?',
        whereArgs: [chunk.id],
      );
      debugPrint('Updated $count chunk(s)');
      return count;
    } catch (e) {
      debugPrint('Error updating chunk: $e');
      rethrow;
    }
  }

  /// Supprimer tous les chunks d'un document
  static Future<int> deleteChunksByDocumentId(int documentId) async {
    final db = await getDatabase();
    try {
      final count = await db.delete(
        _tableChunks,
        where: '$_colChunkDocId = ?',
        whereArgs: [documentId],
      );
      debugPrint('Deleted $count chunk(s)');
      return count;
    } catch (e) {
      debugPrint('Error deleting chunks: $e');
      rethrow;
    }
  }

  // ============ OPÉRATIONS COMBINÉES ============

  /// Récupérer un document avec tous ses chunks
  static Future<Map<String, dynamic>?> getDocumentWithChunks(
    int documentId,
  ) async {
    final document = await getDocumentById(documentId);
    if (document == null) return null;

    final chunks = await getChunksByDocumentId(documentId);

    return {'document': document, 'chunks': chunks};
  }

  /// Obtenir les statistiques de la base de données
  static Future<Map<String, dynamic>> getStatistics() async {
    final db = await getDatabase();
    try {
      final docCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableDocuments'),
      );
      final chunkCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableChunks'),
      );
      final totalSize = Sqflite.firstIntValue(
        await db.rawQuery('SELECT SUM($_colDocFileSize) FROM $_tableDocuments'),
      );

      return {
        'documents': docCount ?? 0,
        'chunks': chunkCount ?? 0,
        'totalSize': totalSize ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      return {'documents': 0, 'chunks': 0, 'totalSize': 0};
    }
  }

  /// Fermer la base de données
  static Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      debugPrint('Database closed');
    }
  }
}
