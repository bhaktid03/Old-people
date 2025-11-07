import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../core/localization/l10n.dart';
import '../core/accessibility/accessibility_manager.dart';

class AccessibleBottomNav extends StatefulWidget {
  const AccessibleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddTap;

  @override
  State<AccessibleBottomNav> createState() => _AccessibleBottomNavState();
}

class _AccessibleBottomNavState extends State<AccessibleBottomNav> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();

  @override
  void initState() {
    super.initState();
    _accessibilityManager.addListener(_onAccessibilityChanged);
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  void _onAccessibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontScale = _accessibilityManager.fontScale;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : AppColors.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: (70 * fontScale).clamp(60.0, 80.0),
          padding: EdgeInsets.symmetric(
            horizontal: (8 * fontScale).clamp(6.0, 12.0),
            vertical: (6 * fontScale).clamp(4.0, 8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: L10n.home,
                isSelected: widget.currentIndex == 0,
                isDark: isDark,
                fontScale: fontScale,
                onTap: () => widget.onTap(0),
              ),
              _NavItem(
                icon: Icons.people_alt_outlined,
                selectedIcon: Icons.people_alt_rounded,
                label: L10n.community,
                isSelected: widget.currentIndex == 1,
                isDark: isDark,
                fontScale: fontScale,
                onTap: () => widget.onTap(1),
              ),
              // Add button in the middle
              _AddButton(
                isDark: isDark,
                fontScale: fontScale,
                onTap: widget.onAddTap ?? () {},
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                selectedIcon: Icons.chat_bubble_rounded,
                label: L10n.chats,
                isSelected: widget.currentIndex == 2,
                isDark: isDark,
                fontScale: fontScale,
                onTap: () => widget.onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: L10n.profile,
                isSelected: widget.currentIndex == 3,
                isDark: isDark,
                fontScale: fontScale,
                onTap: () => widget.onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.fontScale,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = (26 * fontScale).clamp(22.0, 30.0);
    final fontSize = (11 * fontScale).clamp(10.0, 13.0);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (6 * fontScale).clamp(4.0, 10.0),
              vertical: (4 * fontScale).clamp(2.0, 6.0),
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark 
                      ? AppColors.brand.withOpacity(0.2)
                      : AppColors.brand.withOpacity(0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    size: iconSize,
                    color: isSelected
                        ? AppColors.brand
                        : (isDark 
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textSecondary),
                  ),
                ),
                SizedBox(height: (4 * fontScale).clamp(2.0, 6.0)),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.brand
                          : (isDark 
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textSecondary),
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.isDark,
    required this.fontScale,
    required this.onTap,
  });

  final bool isDark;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buttonSize = (56 * fontScale).clamp(50.0, 64.0);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: (32 * fontScale).clamp(28.0, 36.0),
          ),
        ),
      ),
    );
  }
}


