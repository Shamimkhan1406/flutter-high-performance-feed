import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/like/like_controller.dart';

final likeControllerProvider =
    Provider<LikeController>(
  (ref) {
    final controller =
        LikeController();

    ref.onDispose(
      controller.dispose,
    );

    return controller;
  },
);