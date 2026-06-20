import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/feed_provider.dart';
import '../../services/supabase_service.dart';

class LikeController {
  final Map<String, Timer> _debounceTimers = {};

  void toggleLike({
    required WidgetRef ref,
    required String postId,
  }) {
    final feedController =
        ref.read(feedControllerProvider.notifier);

    final currentState =
        ref.read(feedControllerProvider);

    final postIndex =
        currentState.posts.indexWhere(
      (post) => post.id == postId,
    );

    if (postIndex == -1) {
      return;
    }

    final originalPost =
        currentState.posts[postIndex];

    final updatedPost =
        originalPost.copyWith(
      isLiked: !originalPost.isLiked,
      likeCount: originalPost.isLiked
          ? originalPost.likeCount - 1
          : originalPost.likeCount + 1,
    );

    final updatedPosts =
        [...currentState.posts];

    updatedPosts[postIndex] =
        updatedPost;

    /// Optimistic Update
    feedController.updatePosts(
      updatedPosts,
    );

    /// Debounce previous request
    _debounceTimers[postId]?.cancel();

    _debounceTimers[postId] = Timer(
      AppConstants.likeDebounceDuration,
      () async {
        try {
          await SupabaseService.toggleLike(
            postId: postId,
            userId:
                AppConstants.testUserId,
          );
        } catch (e) {
          final revertedPosts =
              [...feedController.state.posts];

          revertedPosts[postIndex] =
              originalPost;

          feedController.updatePosts(
            revertedPosts,
          );
        }
      },
    );
  }

  void dispose() {
    for (final timer
        in _debounceTimers.values) {
      timer.cancel();
    }

    _debounceTimers.clear();
  }
}