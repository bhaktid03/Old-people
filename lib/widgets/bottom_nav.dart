import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:newseva/app.dart';
import 'package:newseva/voice_assistant_wrapper.dart';
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // Plus button in the middle
              _AddButton(
                isDark: isDark,
                fontScale: fontScale,
                onTap: widget.onAddTap ?? () {},
              ),
              _NavItem(
                icon: Icons.mic_none,
                selectedIcon: Icons.mic,
                label: "Voice",
                isSelected: widget.currentIndex == 99, // doesn't matter, no tab switching needed
                isDark: isDark,
                fontScale: fontScale,
                onTap: () async {
                  // Show loading loader before opening
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // Load ENV only when voice button clicked
                    await dotenv.load(fileName: ".env");

                    // Initialize LiveKit
                    await LiveKitClient.initialize();
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Voice assistant init failed: $e")),
                    );
                    return;
                  }

                  // Remove loader
                  Navigator.pop(context);

                  // Now open Voice Assistant
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VoiceAssistantWrapper(),
                    ),
                  );
                },
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
    final iconSize = (28 * fontScale).clamp(24.0, 32.0);
    final fontSize = (12 * fontScale).clamp(10.0, 14.0);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: (8 * fontScale).clamp(6.0, 12.0),
              vertical: (6 * fontScale).clamp(4.0, 8.0),
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark 
                      ? AppColors.brand.withOpacity(0.25)
                      : AppColors.brand.withOpacity(0.15))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: AppColors.brand.withOpacity(0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    size: iconSize,
                    color: isSelected
                        ? AppColors.brand
                        : (isDark 
                            ? Colors.white.withOpacity(0.75)
                            : AppColors.textSecondary),
                  ),
                ),
                SizedBox(height: (5 * fontScale).clamp(3.0, 7.0)),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.brand
                          : (isDark 
                              ? Colors.white.withOpacity(0.75)
                              : AppColors.textSecondary),
                      letterSpacing: 0.3,
                      height: 1.1,
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

class _AddButton extends StatefulWidget {
  const _AddButton({
    required this.isDark,
    required this.fontScale,
    required this.onTap,
  });

  final bool isDark;
  final double fontScale;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = (56 * widget.fontScale).clamp(50.0, 64.0);
    
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
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
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: (32 * widget.fontScale).clamp(28.0, 36.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

