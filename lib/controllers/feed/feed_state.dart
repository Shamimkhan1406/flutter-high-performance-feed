import '../../models/post_model.dart';

class FeedState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}