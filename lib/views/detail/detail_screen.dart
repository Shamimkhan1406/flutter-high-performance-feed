import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/download_service.dart';

import '../../models/post_model.dart';

class DetailScreen extends StatefulWidget {
  final PostModel post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _mobileLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: widget.post.id,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.post.mediaThumbUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: widget.post.mediaMobileUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 400),
                      imageBuilder: (context, provider) {
                        if (!_mobileLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _mobileLoaded = true;
                              });
                            }
                          });
                        }

                        return Image(image: provider, fit: BoxFit.cover);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              '${widget.post.likeCount} likes',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                debugPrint('RAW URL: ${widget.post.mediaRawUrl}');
                try {
                  final path = await DownloadService.downloadImage(
                    widget.post.mediaRawUrl,
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloaded to:\n$path')),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Download High Resolution'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
