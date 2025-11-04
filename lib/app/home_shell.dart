import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../features/headlines/presentation/news_home_screen.dart';
import '../features/community/presentation/community_wall_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = [
    const NewsHomeScreen(),
    const CommunityWallScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: AccessibleBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}


