import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feedback_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(feedbackServiceProvider).addFeedback(text);
      _controller.clear();
      ref.invalidate(feedbackListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleVote(String feedbackId) async {
    try {
      await ref.read(feedbackServiceProvider).toggleVote(feedbackId);
      ref.invalidate(feedbackListProvider);
      ref.invalidate(myVotesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackList = ref.watch(feedbackListProvider);
    final myVotes = ref.watch(myVotesProvider);

    final votedIds = myVotes.when(
      data: (v) => v,
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opinie i pomysły'),
      ),
      body: Column(
        children: [
          // Input card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Co byś zmienił/dodał?',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _submit,
                        icon: const Icon(Icons.send),
                        color: const Color(0xFF2563EB),
                        tooltip: 'Wyślij',
                      ),
              ],
            ),
          ),

          // Feedback list
          Expanded(
            child: feedbackList.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Brak opinii',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bądź pierwszy! Napisz co byś zmienił.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(feedbackListProvider);
                    ref.invalidate(myVotesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final hasVoted = votedIds.contains(item.id);

                      return _FeedbackCard(
                        item: item,
                        hasVoted: hasVoted,
                        onVote: () => _toggleVote(item.id),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Błąd: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackItem item;
  final bool hasVoted;
  final VoidCallback onVote;

  const _FeedbackCard({
    required this.item,
    required this.hasVoted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final authorLabel = [
      if (item.authorName != null && item.authorName!.isNotEmpty)
        item.authorName!
      else
        'Anonim',
      if (item.authorBuilding != null && item.authorBuilding!.isNotEmpty)
        'budynek ${item.authorBuilding}',
    ].join(', ');

    final timeAgo = _formatTimeAgo(item.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vote button
            Column(
              children: [
                InkWell(
                  onTap: onVote,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasVoted
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          hasVoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color: hasVoted
                              ? const Color(0xFF2563EB)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.voteCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: hasVoted
                                ? const Color(0xFF2563EB)
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$authorLabel  ·  $timeAgo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'teraz';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
    if (diff.inHours < 24) return '${diff.inHours}h temu';
    if (diff.inDays < 7) return '${diff.inDays}d temu';
    return '${date.day}.${date.month}';
  }
}
