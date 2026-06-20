import 'package:flutter/material.dart';
import 'package:flutter_high_performance_feed/providers/like_provider.dart';
import 'package:flutter_high_performance_feed/views/detail/detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/feed_provider.dart';
import 'widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(feedControllerProvider.notifier).loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedControllerProvider.notifier).loadInitialFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);

    if (state.isLoading && state.posts.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null && state.posts.isEmpty) {
      return Scaffold(body: Center(child: Text(state.error!)));
    }

    if (state.posts.isEmpty) {
      return const Scaffold(body: Center(child: Text('No posts found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('High Performance Feed')),
      body: RefreshIndicator(
        onRefresh: () {
          return ref.read(feedControllerProvider.notifier).refreshFeed();
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.posts.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = state.posts[index];

            return PostCard(
              post: post,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(post: post)),
                );
              },

              onLikeTap: () {
                ref
                    .read(likeControllerProvider)
                    .toggleLike(ref: ref, postId: post.id);
              },
            );
          },
        ),
      ),
    );
  }
}
