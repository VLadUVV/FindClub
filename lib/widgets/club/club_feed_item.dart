import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/like_service.dart';

class ClubFeedItem extends StatefulWidget {
  final Map<String, dynamic> clubData;
  final VoidCallback onTap;

  const ClubFeedItem({
    super.key,
    required this.clubData,
    required this.onTap,
  });

  @override
  State<ClubFeedItem> createState() => _ClubFeedItemState();
}

class _ClubFeedItemState extends State<ClubFeedItem> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadLikedStatus();
  }

  Future<void> _loadLikedStatus() async {
    final liked = await LikeService.isLiked(widget.clubData['id']);
    setState(() {
      _isLiked = liked;
    });
  }

  Future<void> _toggleLike() async {
    if (_isLiked) {
      await LikeService.unlikeClub(widget.clubData['id']);
    } else {
      await LikeService.likeClub(widget.clubData['id']);
    }
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String clubName = widget.clubData['name'] ?? 'Неизвестный клуб';
    final String clubDescription = widget.clubData['description'] ?? 'Нет описания';
    final double clubRating = (widget.clubData['rating'] as num?)?.toDouble() ?? 0.0;
    final List<String> photos = (widget.clubData['photos'] as List?)?.cast<String>() ?? [];
    final String imageUrl = photos.isNotEmpty ? photos.first : 'https://via.placeholder.com/100';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isLiked ? AppColors.accentRed : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            clubName,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleLike,
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? AppColors.accentRed : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clubDescription,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
