import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

class FeedbackItem {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorBuilding;
  final int voteCount;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorBuilding,
    required this.voteCount,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['author_name'],
      authorBuilding: json['author_building'],
      voteCount: json['vote_count'] ?? 0,
    );
  }
}

// All feedback sorted by votes
final feedbackListProvider = FutureProvider<List<FeedbackItem>>((ref) async {
  final client = SupabaseClientManager.client;

  final response = await client
      .from('feedback_with_votes')
      .select()
      .order('vote_count', ascending: false)
      .order('created_at', ascending: false);

  return (response as List)
      .map((item) => FeedbackItem.fromJson(item))
      .toList();
});

// IDs of feedback the current user has voted on
final myVotesProvider = FutureProvider<Set<String>>((ref) async {
  final client = SupabaseClientManager.client;
  final user = client.auth.currentUser;
  if (user == null) return {};

  final userProfile = await client
      .from('users')
      .select('id')
      .eq('auth_id', user.id)
      .maybeSingle();

  if (userProfile == null) return {};

  final response = await client
      .from('feedback_votes')
      .select('feedback_id')
      .eq('user_id', userProfile['id']);

  return (response as List)
      .map((v) => v['feedback_id'] as String)
      .toSet();
});

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

class FeedbackService {
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

  Future<void> addFeedback(String content) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not found');

    await _client.from('feedback').insert({
      'user_id': userId,
      'content': content,
    });
  }

  Future<void> toggleVote(String feedbackId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not found');

    // Check if already voted
    final existing = await _client
        .from('feedback_votes')
        .select('id')
        .eq('feedback_id', feedbackId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Remove vote
      await _client
          .from('feedback_votes')
          .delete()
          .eq('id', existing['id']);
    } else {
      // Add vote
      await _client.from('feedback_votes').insert({
        'feedback_id': feedbackId,
        'user_id': userId,
      });
    }
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _client.from('feedback').delete().eq('id', feedbackId);
  }
}
