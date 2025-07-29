import 'package:navistfind/features/profile/data/profile_service.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'posted_items_notifier.dart';


final profileServiceProvider = Provider((ref) => ProfileService());

final profileInfoProvider = FutureProvider<User>((ref) async {
  final profileInfo = ref.read(profileServiceProvider);
  return await profileInfo.fetchInfo();
});

final postedItemsProvider = StateNotifierProvider<PostedItemsNotifier, AsyncValue<List<PostedItem>>>(
  (ref) => PostedItemsNotifier(ref.read(profileServiceProvider)),
);
