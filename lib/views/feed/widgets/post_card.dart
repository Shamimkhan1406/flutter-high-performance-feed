import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;

  const PostCard({super.key, required this.post, this.onTap, this.onLikeTap});

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final memCacheWidth = (MediaQuery.of(context).size.width * devicePixelRatio)
        .round();

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Hero(
                tag: post.id,
                child: CachedNetworkImage(
                  imageUrl: post.mediaThumbUrl,
                  memCacheWidth: memCacheWidth,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onLikeTap,
                    icon: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : Colors.grey,
                    ),
                  ),

                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(width: 12),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mode_comment_outlined),
                  ),

                  const Text(
                    '12',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const Spacer(),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                  ),

                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
