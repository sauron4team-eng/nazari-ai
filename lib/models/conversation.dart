import 'package:hive/hive.dart';

part 'conversation.g.dart'; // Pour build_runner si tu veux, sinon adapters manuels ci-dessous

@HiveType(typeId: 1)
class Conversation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  List<Message> messages;

  @HiveField(5)
  String? documentId; // lié à un doc uploadé si applicable

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.documentId,
  });

  factory Conversation.create(String title, {String? documentId}) {
    final now = DateTime.now();
    return Conversation(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
      documentId: documentId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'documentId': documentId,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        messages: (json['messages'] as List)
            .map((m) => Message.fromJson(m))
            .toList(),
        documentId: json['documentId'],
      );
}

@HiveType(typeId: 2)
class Message extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String role; // 'user' | 'model' | 'system'

  @HiveField(2)
  String text;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  String? attachmentPath; // image/doc path si multimodal

  @HiveField(5)
  String? attachmentType; // 'pdf' | 'image' | 'docx'

  Message({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.attachmentPath,
    this.attachmentType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'attachmentPath': attachmentPath,
        'attachmentType': attachmentType,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        role: json['role'],
        text: json['text'],
        timestamp: DateTime.parse(json['timestamp']),
        attachmentPath: json['attachmentPath'],
        attachmentType: json['attachmentType'],
      );
}
