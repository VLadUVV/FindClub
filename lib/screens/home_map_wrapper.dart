import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_colors.dart';
import '../services/supabase_data_service.dart';
import 'home_feed_screen.dart';
import 'map_screen.dart';

class HomeMapWrapper extends StatefulWidget {
  final void Function(List<Map<String, dynamic>>)? onClubsUpdated;

  const HomeMapWrapper({super.key, this.onClubsUpdated});

  @override
  State<HomeMapWrapper> createState() => _HomeMapWrapperState();
}

class _HomeMapWrapperState extends State<HomeMapWrapper> {
  bool _showMap = true;
  String _currentSortBy = 'distance'; // по умолчанию — ближайшие клубы
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _filteredClubs = [];
  bool _isLoading = true;
  final SupabaseDataService _dataService = SupabaseDataService();
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  void _toggleView() {
    setState(() => _showMap = !_showMap);
  }

  /// Получаем текущее местоположение пользователя
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Службы геолокации отключены.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Доступ к геолокации запрещён.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Доступ к геолокации навсегда запрещён.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });
  }

  /// Загружаем клубы из Supabase и вычисляем расстояние
  Future<void> _fetchClubs() async {
    setState(() => _isLoading = true);

    try {
      await _determinePosition();
      final fetchedClubs = await _dataService.fetchClubs();

      for (var club in fetchedClubs) {
        final lat = club['latitude'];
        final lon = club['longitude'];
        if (lat != null && lon != null && _currentPosition != null) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lon,
          );
          club['distance'] = distance / 1000.0; // км
        } else {
          club['distance'] = double.infinity;
        }
      }

      setState(() {
        _clubs = fetchedClubs;
        _applySearchFilter(_searchController.text);
      });

      widget.onClubsUpdated?.call(_filteredClubs);
    } catch (e) {
      print('Ошибка при загрузке клубов: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Поиск по имени и описанию
  void _applySearchFilter(String query) {
    List<Map<String, dynamic>> filtered;

    if (query.isEmpty) {
      filtered = List.from(_clubs);
    } else {
      final lowerQuery = query.toLowerCase();
      filtered = _clubs.where((club) {
        final name = (club['name'] ?? '').toString().toLowerCase();
        final desc = (club['description'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery) || desc.contains(lowerQuery);
      }).toList();
    }

    _applySorting(filtered);
  }

  /// Сортировка — по близости или рейтингу
  void _applySorting(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      switch (_currentSortBy) {
        case 'distance':
          final double distA = (a['distance'] ?? double.infinity).toDouble();
          final double distB = (b['distance'] ?? double.infinity).toDouble();
          return distA.compareTo(distB);
        case 'rating':
        default:
          final double ratingA =
              double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
          final double ratingB =
              double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
          return ratingB.compareTo(ratingA);
      }
    });

    setState(() {
      _filteredClubs = list;
    });

    widget.onClubsUpdated?.call(_filteredClubs);
  }

/// Меню фильтров с сортировкой
void _showSortOptions() async {
  final result = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      MediaQuery.of(context).size.width - 150,
      AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10,
      0,
      0,
    ),
    items: [
      _buildSortItem('По близости', 'distance'),
      _buildSortItem('По рейтингу', 'rating'),
    ],
    color: AppColors.cardBackground,
  );

  // Если выбрали новый фильтр — применяем сортировку
  if (result != null && result != _currentSortBy) {
    setState(() => _currentSortBy = result);
    _applySearchFilter(_searchController.text); // обновляем фильтр/сортировку
  }
}

PopupMenuItem<String> _buildSortItem(String title, String value) {
  final isSelected = _currentSortBy == value;
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isSelected)
          const Icon(Icons.check, color: AppColors.accentOrange)
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final String titleText = _showMap ? 'Карта клубов' : 'Лента клубов';
    final String buttonText =
        _showMap ? 'Посмотреть в ленте' : 'Посмотреть на карте';
    final IconData buttonIcon = _showMap ? Icons.list : Icons.map;

    Widget appBarTitle;
    bool centerTitle = true;

    if (_showMap) {
      appBarTitle = Text(
        titleText,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      );
      centerTitle = true;
    } else {
      appBarTitle = Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _applySearchFilter,
          decoration: const InputDecoration(
            hintText: 'Поиск клубов...',
            hintStyle: TextStyle(color: AppColors.secondaryText),
            prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          ),
          style: const TextStyle(color: AppColors.primaryText),
        ),
      );
      centerTitle = false;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        title: appBarTitle,
        centerTitle: centerTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primaryText),
            onPressed: _showSortOptions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _showMap ? 0 : 1,
            children: [
              MapScreen(
                clubs: _filteredClubs,
                isLoading: _isLoading,
                showAppBar: false,
                showFloatingButton: true,
              ),
              HomeFeedScreen(
                clubs: _filteredClubs,
                isLoading: _isLoading,
                showAppBar: false,
                showFloatingButton: false,
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton.icon(
                onPressed: _toggleView,
                icon: Icon(buttonIcon, color: AppColors.background),
                label: Text(
                  buttonText,
                  style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
