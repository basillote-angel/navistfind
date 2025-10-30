import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/post_item_screen.dart';
import 'package:navistfind/features/lost_found/item/presentation/lost_and_found.dart';
import 'package:navistfind/features/navigate/presentation/campus_map_screen.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/widgets/item_card.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/date_formatter.dart';
import 'how_to_claim_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    this.username = 'Angel',
    this.unreadNotifications = 3,
  });

  final String username;
  final int unreadNotifications;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int? pressedQuickActionIndex;
  bool showGreeting = true;

  // Using AppTheme constants instead of local constants

  late final PageController recommendationsController;

  @override
  void initState() {
    super.initState();
    recommendationsController = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    recommendationsController.dispose();
    super.dispose();
  }

  String getGreetingForNow() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final recommendedAsync = ref.watch(recommendedItemsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              if (showGreeting) _buildGreetingBanner(),
              const SizedBox(height: 20),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
              _buildRecommendationsHeader(context),
              const SizedBox(height: 12),
              _buildSmartRecommendations(context, recommendedAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXLarge),
          bottomRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        children: [
          const Text(
            'NavistFind',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
              if (widget.unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double titleSize = compact ? 18 : 20;
        final double paddingV = compact ? 14 : 18;
        return Stack(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                paddingV,
                AppTheme.spacingL,
                paddingV,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                gradient: AppTheme.cardGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getGreetingForNow()}, ${widget.username}! 👋',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Let's find what you lost today",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatFullDate(DateTime.now()),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: InkWell(
                onTap: () => setState(() => showGreeting = false),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.add_circle_outline_rounded,
        label: 'Report Lost Item',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PostItemScreen()));
        },
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Found Items',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LostAndFoundScreen(initialTabIndex: 0),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.navigation_rounded,
        label: 'Navigate Campus',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CampusMapScreen()));
        },
      ),
      _QuickAction(
        icon: Icons.help_outline_rounded,
        label: 'How to Claim',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HowToClaimScreen()));
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Increased aspect ratio to prevent overflow
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final isPressed = pressedQuickActionIndex == index;
        return GestureDetector(
          onTapDown: (_) => setState(() => pressedQuickActionIndex = index),
          onTapCancel: () => setState(() => pressedQuickActionIndex = null),
          onTapUp: (_) => setState(() => pressedQuickActionIndex = null),
          onTap: action.onTap,
          child: AnimatedScale(
            duration: AppTheme.fastAnimation,
            scale: isPressed ? 0.96 : 1,
            curve: AppTheme.easeOutCurve,
            child: Container(
              decoration: AppTheme.getCardDecoration(
                borderRadius: AppTheme.radiusLarge,
                shadows: AppTheme.elevatedShadow,
              ),
              padding: const EdgeInsets.fromLTRB(8, AppTheme.spacingS, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GradientCircleIcon(icon: action.icon, diameter: 36),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Smart Recommendations', style: AppTheme.heading3),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/recommendations');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text('Based on your recent lost items', style: AppTheme.bodySmall),
      ],
    );
  }

  Widget _buildSmartRecommendations(
    BuildContext context,
    AsyncValue<List<MatchScoreItem>> recommendedAsync,
  ) {
    return recommendedAsync.when(
      loading: () => SizedBox(
        height: 240,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (matches) {
        final sorted = [...matches]..sort((a, b) => b.score.compareTo(a.score));
        final items = sorted.map((m) => m.item).whereType<Item>().toList();
        if (items.isEmpty) {
          return Container(
            height: 44,
            alignment: Alignment.centerLeft,
            child: Text(
              'No recommendations yet',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGray),
            ),
          );
        }
        return SizedBox(
          height: 240,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final item = items[i];
              return ItemCard(
                item: item,
                cardWidth: 190,
                radius: AppTheme.radiusXXLarge,
                borderOpacity: 0.06,
                borderWidth: 0.75,
                onTap: () => showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) =>
                      ItemDetailsModal(itemId: item.id, type: ItemType.found),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GradientCircleIcon extends StatelessWidget {
  const _GradientCircleIcon({required this.icon, this.diameter = 44});

  final IconData icon;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: diameter,
      width: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF1F6FEB), Color(0xFFFFC857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: diameter * 0.5),
      ),
    );
  }
}

class _QuickAction {
  _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

// Legacy recommendation model removed (unused)

// Legacy card removed (unused)

// PulsingFab removed per request
