import 'package:flutter/material.dart';
import '../services/like_service.dart';
import '../widgets/club/club_feed_item.dart';
import '../screens/club_detail_screen.dart';
import '../utils/app_colors.dart';

class LikedScreen extends StatefulWidget {
  // Получаем все клубы из HomeMapWrapper
  final List<Map<String, dynamic>> allClubs;

  const LikedScreen({super.key, required this.allClubs});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  List<String> _likedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final ids = await LikeService.getLikedClubs();
    setState(() {
      _likedIds = ids;
      _isLoading = false;
    });
  }

  // Удаляем лайк и обновляем список
  Future<void> _removeLike(String clubId) async {
    await LikeService.unlikeClub(clubId);
    setState(() {
      _likedIds.remove(clubId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentOrange),
      );
    }

    // Фильтруем клубы по лайкам
    final likedClubs = widget.allClubs
        .where((club) => _likedIds.contains(club['id']))
        .toList();

    if (likedClubs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text(
            'Избранное',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 60,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Вы пока не добавили клубы, которые вам понравились',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Добавьте клуб из ленты, чтобы он появился здесь.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Избранное',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: likedClubs.length,
        itemBuilder: (context, index) {
          final club = likedClubs[index];

          return Dismissible(
            key: ValueKey(club['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.only(right: 20.0),
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.primaryText,
                size: 30,
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                await _removeLike(club['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Клуб удалён из избранного.')),
                );
                return true;
              }
              return false;
            },
            child: ClubFeedItem(
              clubData: club,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClubDetailScreen(clubId: club['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
