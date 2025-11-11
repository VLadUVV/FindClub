import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class LeaveReviewButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LeaveReviewButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit, color: AppColors.background),
        label: const Text(
          'Оставить отзыв',
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 5,
        ),
      ),
    );
  }
}