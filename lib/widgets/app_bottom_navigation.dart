import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1555C0);
    const inactiveColor = Color(0xFF6B7280);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                activeColor: primaryBlue,
                inactiveColor: inactiveColor,
              ),
              _navItem(
                icon: Icons.fitness_center_outlined,
                selectedIcon: Icons.fitness_center,
                label: 'Workout',
                index: 1,
                currentIndex: currentIndex,
                activeColor: primaryBlue,
                inactiveColor: inactiveColor,
              ),
              _navItem(
                icon: Icons.apple_outlined,
                selectedIcon: Icons.apple,
                label: 'Nutrition',
                index: 2,
                currentIndex: currentIndex,
                activeColor: primaryBlue,
                inactiveColor: inactiveColor,
              ),
              _navItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Progress',
                index: 3,
                currentIndex: currentIndex,
                activeColor: primaryBlue,
                inactiveColor: inactiveColor,
              ),
              _navItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                index: 4,
                currentIndex: currentIndex,
                activeColor: primaryBlue,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required int currentIndex,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = currentIndex == index;
    final Color itemColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: itemColor,
              size: 27,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}