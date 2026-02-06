import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

// Messages for a reservation
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, reservationId) {
  final client = SupabaseClientManager.client;

  return client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('reservation_id', reservationId)
      .order('created_at', ascending: true)
      .map((data) => data.map((m) => Message.fromJson(m)).toList());
});

// Chat service
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

class ChatService {
  final _client = SupabaseClientManager.client;

  Future<String?> _getUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    return profile?['id'];
  }

  Future<void> sendMessage({
    required String reservationId,
    required String content,
  }) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not found');

    await _client.from('messages').insert({
      'reservation_id': reservationId,
      'sender_id': userId,
      'content': content,
    });
  }

  Future<void> markAsRead(String messageId) async {
    await _client.from('messages').update({
      'is_read': true,
    }).eq('id', messageId);
  }
}

class Message {
  final String id;
  final String reservationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.reservationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      reservationId: json['reservation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get timeText {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
