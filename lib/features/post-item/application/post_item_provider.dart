import 'package:navistfind/features/post-item/data/post_item_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postItemProvider = Provider<PostItemService>((ref) => PostItemService());

final postItemStateProvider = StateProvider<bool>((ref) => false);