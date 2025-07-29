import 'package:navistfind/features/home/presentation/home_screen.dart';
import 'package:navistfind/features/map/presentation/campus_map_screen.dart';
import 'package:navistfind/features/notifications/presentation/notification_screen.dart';
import 'package:navistfind/features/post-item/presentation/post_item_screen.dart';
import 'package:navistfind/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';

class NavigationBarApp extends StatefulWidget {
  const NavigationBarApp({super.key});

  @override
  State<NavigationBarApp> createState() => NavigationBarAppState();
}

class NavigationBarAppState extends State<NavigationBarApp> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
     CampusMapScreen(),
    const PostItemScreen(),
     NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Navigate',
            ),
            buildPostNavItem(),
            buildNavItem(
              index: 3,
              icon: Icons.notifications_active_outlined,
              activeIcon: Icons.notifications_active_rounded,
              label: 'Heads Up',
            ),
            buildNavItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
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

  // Exclusive for post navigation bar item
  Widget buildPostNavItem() {
    final primaryColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          // Navigate to CreatePostScreen and wait for the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostItemScreen()),
          );

          // Check if we got a result indicating navigation back
          if (result == true) {
            setState(() {
              currentIndex = 0; // Navigate back to Home or any screen you prefer
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

