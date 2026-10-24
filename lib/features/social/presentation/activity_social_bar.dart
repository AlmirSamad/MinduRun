import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/social_rules.dart';
import '../../competitions/presentation/competition_widgets.dart';
import '../../session/session_providers.dart';
import '../social_providers.dart';

/// Like toggle and comment count under an activity in the feed.
class ActivitySocialBar extends ConsumerWidget {
  const ActivitySocialBar({super.key, required this.activityId});
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(likesForActivityProvider(activityId));
    final comments = ref.watch(commentsForActivityProvider(activityId));
    final can = ref.watch(socialPermissionsProvider(activityId));
    final userId = ref.watch(currentUserProvider)?.id;
    final liked = likes.any((l) => l.userId == userId);
    return Row(
      children: [
        TextButton.icon(
          key: ValueKey('like-$activityId'),
          onPressed: can.like
              ? () => ref
                    .read(socialControllerProvider.notifier)
                    .toggleLike(activityId)
              : null,
          icon: Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: liked ? AppColors.error : null,
          ),
          label: Text('${likes.length}'),
        ),
        TextButton.icon(
          key: ValueKey('comments-$activityId'),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => CommentsSheet(activityId: activityId),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text('${comments.length}'),
        ),
      ],
    );
  }
}

/// Comments list with a box to add one (participants only).
class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.activityId});
  final String activityId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    try {
      ref
          .read(socialControllerProvider.notifier)
          .addComment(widget.activityId, _text.text);
      _text.clear();
      setState(() => _error = null);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    } on StateError catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsForActivityProvider(widget.activityId));
    final canComment = ref
        .watch(socialPermissionsProvider(widget.activityId))
        .comment;
    final users = ref.watch(userRepositoryProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Comentários', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: comments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Nenhum comentário ainda.'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final comment in comments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            users.getUser(comment.userId)?.displayName ??
                                'Participante',
                          ),
                          subtitle: Text(comment.text),
                          trailing: Text(
                            formatCompetitionDate(comment.createdAt),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
          ),
          if (canComment) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('comment-field'),
              controller: _text,
              maxLength: SocialRules.maxCommentLength,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Escreva um comentário',
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip: 'Enviar comentário',
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _send,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ],
        ],
      ),
    );
  }
}
