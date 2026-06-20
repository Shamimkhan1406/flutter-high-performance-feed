import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/feed/feed_controller.dart';
import '../controllers/feed/feed_state.dart';

final feedControllerProvider =
    StateNotifierProvider<FeedController, FeedState>(
  (ref) => FeedController(),
);