import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';
import '../../services/supabase_service.dart';
import 'feed_state.dart';

class FeedController extends StateNotifier<FeedState> {
  FeedController() : super(const FeedState());

  int _page = 0;

  /// Used by LikeController for optimistic updates
  void updatePosts(List<PostModel> posts) {
    state = state.copyWith(posts: posts);
  }

  Future<void> loadInitialFeed() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _page = 0;

      final posts = await SupabaseService.fetchFeedPage(
        from: 0,
        to: AppConstants.pageSize - 1,
        userId: AppConstants.testUserId,
      );

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= AppConstants.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      _page++;

      final from = _page * AppConstants.pageSize;

      final to = from + AppConstants.pageSize - 1;

      final newPosts = await SupabaseService.fetchFeedPage(
        from: from,
        to: to,
        userId: AppConstants.testUserId,
      );

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: newPosts.length >= AppConstants.pageSize,
      );
    } catch (e) {
      _page--;

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshFeed() async {
    try {
      state = state.copyWith(isRefreshing: true, error: null);

      _page = 0;

      final posts = await SupabaseService.fetchFeedPage(
        from: 0,
        to: AppConstants.pageSize - 1,
        userId: AppConstants.testUserId,
      );

      state = state.copyWith(
        posts: posts,
        isRefreshing: false,
        hasMore: posts.length >= AppConstants.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unable to load feed');
    }
  }
}
