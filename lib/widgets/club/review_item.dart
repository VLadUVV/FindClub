import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ReviewItem extends StatelessWidget {
  final String reviewerName;
  final String reviewText;
  final String rating; // Принимаем уже форматированную строку
  final int likesCount;

  const ReviewItem({
    super.key,
    required this.reviewerName,
    required this.reviewText,
    required this.rating,
    required this.likesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар (заглушка)
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondaryText,
            child: Icon(Icons.person, color: AppColors.background, size: 24),
          ),
          const SizedBox(width: 12),

          // Основной контент отзыва
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя и Рейтинг
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // Отображаем имя пользователя (часть ID)
                        'User: $reviewerName...', 
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Рейтинг
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen, 
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rating,
                          style: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Текст отзыва
                  Text(
                    reviewText,
                    style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Лайки
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.secondaryText, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        likesCount.toString(),
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}