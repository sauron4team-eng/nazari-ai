# Architecture SQLite - NazariAI

## 📐 Schéma de Données

### Table: `documents`
Stocke les métadonnées des documents analysés

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fileName TEXT NOT NULL,
  filePath TEXT NOT NULL UNIQUE,
  fileType TEXT NOT NULL,           -- txt, pdf, doc, docx
  fileSize INTEGER NOT NULL,        -- en bytes
  fileHash TEXT NOT NULL UNIQUE,    -- MD5 pour détecter changements
  createdAt TEXT NOT NULL,          -- ISO 8601
  updatedAt TEXT,                   -- ISO 8601 (nullable)
  totalChunks INTEGER NOT NULL,     -- nombre de chunks
  notes TEXT                        -- notes utilisateur (nullable)
)
```

### Table: `chunks`
Stocke les fragments de texte extrait des documents

```sql
CREATE TABLE chunks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  documentId INTEGER NOT NULL,      -- FK vers documents.id
  chunkIndex INTEGER NOT NULL,      -- position (0, 1, 2, ...)
  content TEXT NOT NULL,            -- contenu du chunk
  charCount INTEGER NOT NULL,       -- nombre de caractères
  createdAt TEXT NOT NULL,          -- ISO 8601
  FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE,
  UNIQUE(documentId, chunkIndex)
)
```

## 🏗️ Architecture des Fichiers

```
lib/
├── data/
│   ├── database/
│   │   └── database_service.dart      # Service CRUD SQLite (bas niveau)
│   └── models/
│       ├── document_model.dart        # Modèle Document
│       └── chunk_model.dart           # Modèle Chunk
├── services/
│   ├── documents_service.dart         # Extraction de contenu (existant)
│   └── document_storage_service.dart  # Intégration stockage (nouveau)
└── ...
```

## 💾 Flux de Stockage

### 1. Ajout d'un Document

```dart
// Utilisateur sélectionne un fichier
final filePath = '/path/to/document.pdf';

// Traiter et stocker en BD
final doc = await DocumentStorageService.processAndStoreDocumentToDatabase(
  filePath,
  notes: 'Notes optionnelles'
);

// doc contient:
// - id (généré par BD)
// - fileName, filePath, fileType, fileSize
// - fileHash (MD5)
// - totalChunks (nombre de chunks)
// - createdAt
```

### 2. Récupération des Chunks pour l'IA

```dart
// Récupérer les chunks d'un document
final chunks = await DocumentStorageService.getDocumentChunks(documentId);

// Chaque chunk contient:
// - documentId (référence)
// - chunkIndex (position 0, 1, 2...)
// - content (texte du chunk)
// - charCount (taille)

// Pour envoyer à Gemma:
for (final chunk in chunks) {
  await gemmaService.processChunk(
    documentId: chunk.documentId,
    chunkIndex: chunk.chunkIndex,
    content: chunk.content,
  );
}
```

### 3. Récupération du Texte Complet

```dart
// Récupérer le document complet (tous les chunks joints)
final fullText = await DocumentStorageService.getFullDocumentText(documentId);

// Ou avec métadonnées
final docData = await DocumentStorageService.getDocumentWithChunks(documentId);
final doc = docData['document'] as DocumentModel;
final chunks = docData['chunks'] as List<ChunkModel>;
```

## 🔄 Gestion des Changements de Fichier

```dart
// Vérifier si le fichier a changé
final hasChanged = await DocumentStorageService.hasFileChanged(documentId);

if (hasChanged) {
  // Réanalyser le document
  // (supprime anciens chunks, extrait nouveaux, met à jour hash)
  final updated = await DocumentStorageService.reanalyzeDocument(documentId);
}
```

## 📊 Statistiques

```dart
final stats = await DocumentStorageService.getStatistics();
// Retourne:
// {
//   'documents': 42,
//   'chunks': 5280,
//   'totalSize': 52428800  // en bytes
// }
```

## 🗑️ Suppression

```dart
// Supprimer un document (cascade supprime aussi les chunks)
await DocumentStorageService.deleteDocument(documentId);
```

## 🔍 Recherche

```dart
// Rechercher par nom ou notes
final results = await DocumentStorageService.searchDocuments('gemma');
// Retourne les documents dont fileName ou notes contiennent 'gemma'
```

## ⚙️ Configuration de la Base de Données

**Localisation:**
- Android: `/data/data/com.example.nazariai/databases/nazariai.db`
- iOS: `Documents/nazariai.db`
- Windows: Local data folder

**Version:** 1
- Peut être incrémentée pour migrations futures

## 🎯 Avantages de cette Architecture

✅ **Persistance complète** - Documents et chunks survivent fermeture app
✅ **Accès rapide** - Pas de réextraction à chaque utilisation
✅ **Détection de changements** - Hash MD5 détecte modifications de fichier
✅ **Relations correctes** - FK assurent cohérence données
✅ **Suppression en cascade** - Chunks supprimés automatiquement avec document
✅ **Requêtes optimisées** - Indexe sur FK et combinaisons
✅ **Scalabilité** - Supporte centaines/milliers de documents
✅ **Compatible Gemma** - Chunks disponibles immédiatement

## 📝 Prochaines Étapes

1. Intégrer `DocumentStorageService` dans AI Assistant Screen
2. Ajouter une UI pour gérer les documents stockés (liste, suppression, notes)
3. Implémenter synchronisation avec Gemma
4. Ajouter cache en mémoire pour optimiser lectures fréquentes
