import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../core/localization/l10n.dart';

class AccessibleBottomNav extends StatelessWidget {
  const AccessibleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.brand.withOpacity(0.12),
      elevation: 1,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined, size: 28),
          selectedIcon: const Icon(Icons.home_rounded, size: 30),
          label: L10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_alt_outlined, size: 28),
          selectedIcon: const Icon(Icons.people_alt_rounded, size: 30),
          label: L10n.community,
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
          selectedIcon: const Icon(Icons.chat_bubble_rounded, size: 30),
          label: L10n.chats,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded, size: 28),
          selectedIcon: const Icon(Icons.person_rounded, size: 30),
          label: L10n.profile,
        ),
      ],
    );
  }
}


