import 'package:shared_preferences/shared_preferences.dart';

class LikeService {
  static const String _likedClubsKey = 'liked_clubs';

  static Future<List<String>> getLikedClubs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_likedClubsKey) ?? [];
  }

  static Future<bool> isLiked(String clubId) async {
    final liked = await getLikedClubs();
    return liked.contains(clubId);
  }

  static Future<void> likeClub(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    final liked = await getLikedClubs();
    if (!liked.contains(clubId)) {
      liked.add(clubId);
      await prefs.setStringList(_likedClubsKey, liked);
    }
  }
  
  static Future<void> unlikeClub(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    final liked = await getLikedClubs();
    liked.remove(clubId);
    await prefs.setStringList(_likedClubsKey, liked);
  }
}
