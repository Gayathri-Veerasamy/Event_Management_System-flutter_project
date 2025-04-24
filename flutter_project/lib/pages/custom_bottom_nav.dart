// lib/widgets/custom_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

typedef NavCallback = void Function(int index);

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final NavCallback onTabChange;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 420;
            return GNav(
              gap: 10,
              iconSize: 24,
              padding: EdgeInsets.symmetric(
                horizontal: isTight ? 8 : 12,
                vertical: 12,
              ),
              backgroundColor: Colors.white,
              color: Colors.grey[600],
              activeColor: Colors.purple,
              tabBackgroundColor: Colors.purple.withOpacity(0.1),
              selectedIndex: selectedIndex,
              onTabChange: onTabChange,
              tabs: const [
                GButton(icon: Icons.home, text: 'Home'),
                GButton(icon: Icons.confirmation_num, text: 'Tickets'),
                GButton(icon: Icons.add_circle, text: 'Add'),
                GButton(icon: Icons.favorite_border, text: 'Favorites'),
                GButton(icon: Icons.calendar_today, text: 'Calendar'),
              ],
            );
          },
        ),
      ),
    );
  }
}
