import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<List<PostModel>> fetchPosts({
    required int from,
    required int to,
  }) async {
    final response = await client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);

    return response.map<PostModel>((item) => PostModel.fromMap(item)).toList();
  }

  static Future<Set<String>> fetchLikedPosts(String userId) async {
    final response = await client
        .from('user_likes')
        .select('post_id')
        .eq('user_id', userId);

    return response.map<String>((item) => item['post_id'] as String).toSet();
  }

  static Future<List<PostModel>> fetchFeedPage({
    required int from,
    required int to,
    required String userId,
  }) async {
    final posts = await fetchPosts(from: from, to: to);

    final likedPosts = await fetchLikedPosts(userId);

    return posts
        .map((post) => post.copyWith(isLiked: likedPosts.contains(post.id)))
        .toList();
  }

  static Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    await client.rpc(
      'toggle_like',
      params: {'p_post_id': postId, 'p_user_id': userId},
    );
  }
}
