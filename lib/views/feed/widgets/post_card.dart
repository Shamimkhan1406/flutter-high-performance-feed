import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio =
        MediaQuery.of(context).devicePixelRatio;

    final memCacheWidth =
        (MediaQuery.of(context).size.width *
                devicePixelRatio)
            .round();

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Hero(
                tag: post.id,
                child: CachedNetworkImage(
                  imageUrl: post.mediaThumbUrl,
                  memCacheWidth: memCacheWidth,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250,
                  placeholder: (
                    context,
                    url,
                  ) =>
                      const SizedBox(
                    height: 250,
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (
                    context,
                    url,
                    error,
                  ) =>
                      const SizedBox(
                    height: 250,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onLikeTap,
                    icon: Icon(
                      post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                  ),

                  Text(
                    '${post.likeCount}',
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