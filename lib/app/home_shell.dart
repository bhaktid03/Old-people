import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../features/headlines/presentation/news_home_screen.dart';
import '../features/community/presentation/community_wall_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  DateTime? _lastBackPressedAt;
  final GlobalKey<CommunityWallScreenState> _communityKey = GlobalKey<CommunityWallScreenState>();

  List<Widget> get _pages => [
    const NewsHomeScreen(),
    CommunityWallScreen(key: _communityKey),
    const ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final navigator = Navigator.of(context);

        // If there are routes to pop, pop the current route
        if (navigator.canPop()) {
          navigator.maybePop();
          return;
        }

        // If not on the first tab, go to the first tab instead of exiting
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }

        // On the first tab and no routes to pop: require double back to exit
        final now = DateTime.now();
        final pressedRecently = _lastBackPressedAt != null &&
            now.difference(_lastBackPressedAt!).inMilliseconds < 2000;

        if (pressedRecently) {
          // Allow system to handle exit on the next back press by temporarily enabling pop
          // Showing no message here to keep the flow quick.
          _lastBackPressedAt = null;
          Navigator.of(context).maybePop();
          return;
        }

        _lastBackPressedAt = now;
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      },
      child: Scaffold(
        body: SafeArea(child: _pages[_index]),
        bottomNavigationBar: AccessibleBottomNav(
          currentIndex: _index,
          onTap: (i) {
            setState(() => _index = i);
          },
          onAddTap: () {
            // Open the composer from community screen
            // If not on community tab, switch to it first
            if (_index != 1) {
              setState(() => _index = 1);
              // Wait a bit for the tab to switch, then open composer
              Future.delayed(const Duration(milliseconds: 100), () {
                _communityKey.currentState?.openComposer();
              });
            } else {
              _communityKey.currentState?.openComposer();
            }
          },
        ),
      ),
    );
  }
}


