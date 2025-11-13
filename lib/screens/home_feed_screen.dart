import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/club/club_feed_item.dart';
import 'club_detail_screen.dart';

class HomeFeedScreen extends StatelessWidget {
  final List<Map<String, dynamic>> clubs;
  final bool isLoading;
  final bool showAppBar;
  final bool showFloatingButton; 

  const HomeFeedScreen({
    super.key, 
    required this.clubs,
    required this.isLoading,
    this.showAppBar = true, 
    this.showFloatingButton = true, 
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    if (clubs.isEmpty) {
      return const Center(child: Text('Нет доступных клубов.', style: TextStyle(color: AppColors.primaryText)));
    }
    
    return ListView.builder(
      itemCount: clubs.length,
      itemBuilder: (context, index) {
        final club = clubs[index];
        return ClubFeedItem(
          clubData: club,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClubDetailScreen(clubId: club['id']),
              ),
            );
          },
        );
      },
      padding: const EdgeInsets.only(bottom: 100), 
    );
  }
}