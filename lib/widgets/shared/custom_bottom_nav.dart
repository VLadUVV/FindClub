import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // 0: Главная
              _buildNavItem(Icons.home, 0, selectedIndex, 'Главная'), 
              // 1: Избранное
              _buildNavItem(Icons.favorite_border, 1, selectedIndex, 'Избранное'),
              // 2: Профиль (Если нужен)
              // _buildNavItem(Icons.person_outline, 2, selectedIndex, 'Профиль'), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, int selectedIndex, String label) {
    final bool isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.accentOrange : AppColors.primaryText,
            ),
          ],
        ),
      ),
    );
  }
}