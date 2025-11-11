import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> clubs;
  final bool isLoading;
  final bool showAppBar;
  final bool showFloatingButton;

  const MapScreen({
    super.key,
    required this.clubs,
    required this.isLoading,
    this.showAppBar = true,
    this.showFloatingButton = true,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late YandexMapController _controller;
  bool _mapReady = false;
  bool _positionLoaded = false;

  Point _userLocation = const Point(latitude: 55.751244, longitude: 37.618423);
  List<MapObject> _mapObjects = [];

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  /// Получаем текущее местоположение пользователя с высокой точностью
  Future<void> _initUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Используем последнюю известную позицию (быстро)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _userLocation =
            Point(latitude: lastPosition.latitude, longitude: lastPosition.longitude);
      }

      // Запрашиваем свежие координаты с максимальной точностью
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        forceAndroidLocationManager: true,
      );

      setState(() {
        _userLocation = Point(latitude: pos.latitude, longitude: pos.longitude);
        _positionLoaded = true;
      });

      if (_mapReady) {
        await _moveToUser();
        _updateMapObjects();
      }
    } catch (e) {
      debugPrint('Ошибка при получении геопозиции: $e');
    }
  }

  /// Создание маркеров клубов + пользователя с правильной привязкой
  List<MapObject> _buildMapObjects() {
    final List<MapObject> objects = [];

    // Маркеры клубов
    for (final club in widget.clubs) {
      final lat = (club['latitude'] ?? 0).toDouble();
      final lon = (club['longitude'] ?? 0).toDouble();
      if (lat == 0 || lon == 0) continue;

      final id = club['id']?.toString() ?? '${lat}_$lon';
      final name = club['name'] ?? 'Клуб';
      final rating = (club['rating'] as num?)?.toStringAsFixed(1) ?? 'N/A';

      objects.add(
        PlacemarkMapObject(
          mapId: MapObjectId(id),
          point: Point(latitude: lat, longitude: lon),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage('assets/icons/club_marker.png'),
              scale: 1.3,
              anchor: const Offset(0.5, 1.0), // нижний центр на точке
            ),
          ),
          onTap: (self, point) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name — рейтинг $rating')),
            );
          },
        ),
      );
    }

    // Маркер пользователя
    objects.add(
      PlacemarkMapObject(
        mapId: const MapObjectId('user_marker'),
        point: _userLocation,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/icons/user_marker.png'),
            scale: 1.6,
            anchor: const Offset(0.5, 0.5), // центр на позиции пользователя
          ),
        ),
      ),
    );

    return objects;
  }

  /// Обновляем маркеры на карте
  void _updateMapObjects() {
    setState(() {
      _mapObjects = _buildMapObjects();
    });
  }

  /// Перемещение к пользователю
  Future<void> _moveToUser() async {
    if (!_mapReady) return;
    await _controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation, zoom: 15),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.7),
    );
  }

  /// Центрирование карты на всех точках (пользователь + клубы)
  Future<void> _fitToAllMarkers() async {
    if (!_mapReady || widget.clubs.isEmpty) return;

    final allPoints = <Point>[
      _userLocation,
      ...widget.clubs
          .where((c) => c['latitude'] != null && c['longitude'] != null)
          .map((c) => Point(
                latitude: (c['latitude'] as num).toDouble(),
                longitude: (c['longitude'] as num).toDouble(),
              )),
    ];

    if (allPoints.isEmpty) return;

    await _controller.moveCamera(
      CameraUpdate.newGeometry(Geometry.fromBoundingBox(
        BoundingBox(
          northEast: Point(
            latitude: allPoints.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
            longitude: allPoints.map((e) => e.longitude).reduce((a, b) => a > b ? a : b),
          ),
          southWest: Point(
            latitude: allPoints.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
            longitude: allPoints.map((e) => e.longitude).reduce((a, b) => a < b ? a : b),
          ),
        ),
      )),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.8),
    );
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clubs != widget.clubs && _mapReady) {
      _updateMapObjects();
      _fitToAllMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentOrange),
      );
    }

    _updateMapObjects();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: const Text(
                'Карта клубов',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _mapObjects,
            onMapCreated: (controller) async {
              _controller = controller;
              _mapReady = true;
              await _fitToAllMarkers();
            },
          ),
          if (widget.showFloatingButton)
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  FloatingActionButton(
                    backgroundColor: AppColors.accentOrange,
                    onPressed: _moveToUser,
                    heroTag: 'center_user',
                    child: const Icon(Icons.my_location, color: AppColors.background),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    backgroundColor: Colors.blueGrey,
                    onPressed: _initUserLocation,
                    heroTag: 'refresh_user',
                    child: const Icon(Icons.gps_fixed, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
