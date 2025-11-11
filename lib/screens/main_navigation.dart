import 'package:flutter/material.dart';
import '../widgets/shared/custom_bottom_nav.dart';
import 'home_map_wrapper.dart';
import 'liked_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _allClubs = [];

  void _updateAllClubs(List<Map<String, dynamic>> clubs) {
    setState(() {
      _allClubs = clubs;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      HomeMapWrapper(
        key: const ValueKey('home_map_wrapper'),
        onClubsUpdated: _updateAllClubs,
      ),
      LikedScreen(allClubs: _allClubs), // Передаем все клубы
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
