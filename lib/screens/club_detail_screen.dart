import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/supabase_data_service.dart';
import '../widgets/shared/image_gallery.dart';

class ClubDetailScreen extends StatefulWidget {
  final String clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final SupabaseDataService _dataService = SupabaseDataService();
  Map<String, dynamic>? _clubData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clubDetails = await _dataService.fetchClubById(widget.clubId);

      setState(() {
        _clubData = clubDetails;
      });
    } catch (e) {
      print('Ошибка при загрузке данных клуба: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить данные клуба')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentOrange),
        ),
      );
    }

    if (_clubData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text(
            'Ошибка',
            style: TextStyle(color: AppColors.primaryText),
          ),
          iconTheme: const IconThemeData(color: AppColors.primaryText),
        ),
        body: const Center(
          child: Text(
            'Клуб не найден.',
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
      );
    }

    final clubName = _clubData!['name'] ?? 'Неизвестный клуб';
    final clubDescription = _clubData!['description'] ?? 'Описание отсутствует.';
    final rating = _clubData!['rating'];
    final clubRating =
        rating is num ? rating.toStringAsFixed(1) : (rating ?? 'N/A').toString();

    // Поле в БД называется "photos"
    final imageUrls = (_clubData!['photos'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        title: Text(
          clubName,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Рейтинг
            Row(
              children: [
                const Icon(Icons.star,
                    color: AppColors.accentOrange, size: 20),
                const SizedBox(width: 4),
                Text(
                  clubRating,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Описание
            Text(
              clubDescription,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Фото клуба
            if (imageUrls.isNotEmpty) ...[
              const Text(
                'Фотографии клуба:',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              ImageGallery(imageUrls: imageUrls),
            ] else
              const Text(
                'Фото отсутствуют.',
                style: TextStyle(color: AppColors.secondaryText),
              ),

            const SizedBox(height: 24),

            // Координаты
            if (_clubData!['latitude'] != null &&
                _clubData!['longitude'] != null)
              Text(
                'Координаты: ${_clubData!['latitude']}, ${_clubData!['longitude']}',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
