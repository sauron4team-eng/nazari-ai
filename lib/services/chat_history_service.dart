import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/conversation.dart';

/// Persistance des conversations via Hive (100% offline)
class ChatHistoryService {
  static const String _boxName = 'nazari_conversations';
  Box<String>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  Future<List<Conversation>> getAllConversations() async {
    await init();
    final list = <Conversation>[];
    for (final entry in _box!.values) {
      try {
        final json = jsonDecode(entry) as Map<String, dynamic>;
        list.add(Conversation.fromJson(json));
      } catch (_) {
        // skip corrupted entries
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<Conversation?> getConversation(String id) async {
    await init();
    final raw = _box!.get(id);
    if (raw == null) return null;
    return Conversation.fromJson(jsonDecode(raw));
  }

  Future<void> saveConversation(Conversation conv) async {
    await init();
    await _box!.put(conv.id, jsonEncode(conv.toJson()));
  }

  Future<void> deleteConversation(String id) async {
    await init();
    await _box!.delete(id);
  }

  Future<void> addMessage(String conversationId, Message message) async {
    final conv = await getConversation(conversationId);
    if (conv == null) return;
    conv.messages.add(message);
    conv.updatedAt = DateTime.now();
    await saveConversation(conv);
  }

  Future<void> clearAll() async {
    await init();
    await _box!.clear();
  }
}
