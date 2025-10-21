import 'package:navistfind/features/home/presentation/home_page.dart';
import 'package:navistfind/features/navigate/presentation/campus_map_screen.dart';
import 'package:navistfind/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/item/presentation/lost_and_found.dart';

class NavigationBarApp extends StatefulWidget {
  final int initialIndex;
  final int lostFoundInitialTabIndex;
  const NavigationBarApp({
    super.key,
    this.initialIndex = 0,
    this.lostFoundInitialTabIndex = 0,
  });

  @override
  State<NavigationBarApp> createState() => NavigationBarAppState();
}

class NavigationBarAppState extends State<NavigationBarApp> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            buildNavItem(
              index: 1,
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
              label: 'Lost & Found',
            ),
            buildNavItem(
              index: 2,
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Navigate',
            ),
            buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      const HomePage(),
      LostAndFoundScreen(initialTabIndex: widget.lostFoundInitialTabIndex),
      const CampusMapScreen(),
      const ProfileScreen(),
    ];
  }

  // Common navigation bar item
  Widget buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isSelected
        ? primaryColor.withOpacity(0.1)
        : Colors.transparent;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => currentIndex = index),
        child: Container(
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle indicator dot above the icon when selected
                  if (isSelected)
                    Positioned(
                      top: -4,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? primaryColor : Colors.grey.shade600,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
