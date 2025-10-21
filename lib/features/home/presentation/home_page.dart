import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/post_item_screen.dart';
import 'package:navistfind/features/lost_found/item/presentation/lost_and_found.dart';
import 'package:navistfind/features/navigate/presentation/campus_map_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.username = 'Angel',
    this.unreadNotifications = 3,
  });

  final String username;
  final int unreadNotifications;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  bool isSearchExpanded = false;
  int? pressedQuickActionIndex;
  bool showGreeting = true;

  static const Color darkBlue = Color(0xFF123A7D);
  static const Color navy = Color(0xFF1C2A40);
  static const Color primaryBlue = Color(0xFF1F6FEB);
  static const Color golden = Color(0xFFFFC857);
  static const Color softYellow = Color(0xFFFFF4D8);
  static const Color lightGray = Color(0xFFF4F6F8);
  static const Color successGreen = Color(0xFF19A15F);
  static const Color textGray = Color(0xFF6B7280);

  late final PageController recommendationsController;

  @override
  void initState() {
    super.initState();
    recommendationsController = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    recommendationsController.dispose();
    super.dispose();
  }

  String formatFullDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String getGreetingForNow() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
              _buildRecommendationsHeader(),
              const SizedBox(height: 12),
              _buildSmartRecommendations(),
              const SizedBox(height: 28),
              _buildHelpInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: Colors.redAccent,
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
              padding: EdgeInsets.fromLTRB(16, paddingV, 16, paddingV),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F0FF), Color(0xFFDFF7FF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getGreetingForNow()}, ${widget.username}! \uD83D\uDC4B',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: darkBlue,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Let's find what you lost today",
                    style: TextStyle(
                      fontSize: 14,
                      color: textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatFullDate(DateTime.now()),
                    style: const TextStyle(fontSize: 13, color: textGray),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: InkWell(
                onTap: () => setState(() => showGreeting = false),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 18, color: darkBlue),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: isSearchExpanded ? 60 : 56,
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: textGray),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onTap: () => setState(() => isSearchExpanded = true),
              decoration: const InputDecoration(
                hintText: 'Search lost or found items...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {},
            ),
          ),
        ],
      ),
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
        icon: Icons.insights_outlined,
        label: 'View Status',
        onTap: () {},
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
        // Slightly taller cells to avoid vertical overflow
        childAspectRatio: 0.78,
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
            duration: const Duration(milliseconds: 120),
            scale: isPressed ? 0.96 : 1,
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GradientCircleIcon(icon: action.icon, diameter: 38),
                    const SizedBox(height: 6),
                    Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: darkBlue,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Smart Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: darkBlue,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Based on your recent lost items',
          style: TextStyle(
            fontSize: 12,
            color: textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartRecommendations() {
    final recommendations = <_Recommendation>[
      _Recommendation(
        name: 'Black Wallet',
        location: 'Found near Library',
        similarityPercent: 96,
        imageAsset: null,
      ),
      _Recommendation(
        name: 'Blue ID Lanyard',
        location: 'Admin Office',
        similarityPercent: 92,
        imageAsset: null,
      ),
      _Recommendation(
        name: 'Gray Hoodie',
        location: 'Gymnasium',
        similarityPercent: 88,
        imageAsset: null,
      ),
    ];

    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: recommendationsController,
        padEnds: false,
        itemCount: recommendations.length,
        physics: const BouncingScrollPhysics(),
        allowImplicitScrolling: false,
        clipBehavior: Clip.hardEdge,
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == recommendations.length - 1 ? 0 : 14,
            ),
            child: _RecommendationCard(
              recommendation: rec,
              onViewDetails: () {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelpInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: softYellow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: golden.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: darkBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "If you can’t find your item, try posting it under ‘Report Lost Item’. Our AI will continuously search for possible matches.",
                  style: TextStyle(fontSize: 13, color: darkBlue, height: 1.3),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: darkBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {},
                    child: const Text('Learn More'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        child: Icon(icon, color: _HomePageState.darkBlue, size: diameter * 0.5),
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

class _Recommendation {
  _Recommendation({
    required this.name,
    required this.location,
    required this.similarityPercent,
    this.imageAsset,
  });

  final String name;
  final String location;
  final int similarityPercent;
  final String? imageAsset;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onViewDetails,
  });

  final _Recommendation recommendation;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: recommendation.imageAsset != null
                ? Image.asset(
                    recommendation.imageAsset!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    width: double.infinity,
                  )
                : Container(
                    width: double.infinity,
                    color: const Color(0xFFF0F3F8),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 56,
                      color: _HomePageState.darkBlue,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _HomePageState.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _HomePageState.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: _HomePageState.successGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${recommendation.similarityPercent}% Match',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _HomePageState.successGreen,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onViewDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: _HomePageState.primaryBlue,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PulsingFab removed per request
