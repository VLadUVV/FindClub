import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';
import '../utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> clubs;
  final bool isLoading;
  final bool showAppBar;
  final bool showFloatingButton;
  final Position? userPosition;
  final String? sortBy;
  final VoidCallback? onLocationReady;

  const MapScreen({
    super.key,
    required this.clubs,
    required this.isLoading,
    this.showAppBar = true,
    this.showFloatingButton = true,
    this.userPosition,
    this.sortBy,
    this.onLocationReady,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late YandexMapController _controller;
  bool _mapReady = false;
  Point _userLocation = const Point(latitude: 55.751244, longitude: 37.618423);
  bool _positionLoaded = false;

  List<MapObject> _mapObjects = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    if (widget.userPosition != null) {
      _userLocation = Point(
        latitude: widget.userPosition!.latitude,
        longitude: widget.userPosition!.longitude,
      );
      _positionLoaded = true;
    }

    if (!_positionLoaded) {
      _initUserLocation();
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) async {
      final hasNet = await _hasRealConnection();
      if (hasNet && !_positionLoaded) {
        await _initUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<bool> _hasRealConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool?> _askEnableInternet() async {
    final enabled = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Нет подключения к интернету'),
          content: const Text(
            'Для корректной работы приложения необходимо включить интернет.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                AppSettings.openAppSettings(type: AppSettingsType.dataRoaming);
                Navigator.pop(context, true);
              },
              child: const Text('Мобильные данные'),
            ),
            TextButton(
              onPressed: () {
                AppSettings.openAppSettings(type: AppSettingsType.wifi);
                Navigator.pop(context, true);
              },
              child: const Text('Wi-Fi'),
            ),
          ],
        );
      },
    );
    
    if (enabled == true && !_positionLoaded) {
      await Future.delayed(const Duration(seconds: 1));
      await _initUserLocation();
    }

    return enabled;
  }

  Future<bool?> _askEnableLocationService() async {
    final enabled = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Геолокация отключена'),
          content: const Text(
            'Для корректной работы приложения включите геолокацию.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.pop(context, true);
              },
              child: const Text('Включить'),
            ),
          ],
        );
      },
    );

    if (enabled == true && !_positionLoaded) {
      await Future.delayed(const Duration(seconds: 1));
      await _initUserLocation();
    }

    return enabled;
  }

  Future<void> _initUserLocation() async {
    try {
      // Проверка интернета
      final hasNet = await _hasRealConnection();
      if (!hasNet) {
        await _askEnableInternet();
        return;
      }

      // Проверка геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _askEnableLocationService();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешение на геолокацию заблокировано в системе.')),
        );
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = Point(latitude: pos.latitude, longitude: pos.longitude);
        _positionLoaded = true;
        widget.onLocationReady?.call();
      });

      if (_mapReady) {
        await _moveToUser();
        _updateMapObjects();
      }
    } catch (e) {
      debugPrint('Ошибка при получении позиции: $e');
    }
  }

  List<Map<String, dynamic>> _clubsToShow() {
    final mode = widget.sortBy ?? 'rating';
    if (mode == 'distance' && _positionLoaded) {
      final valid = widget.clubs
          .where((c) => c['latitude'] != null && c['longitude'] != null)
          .toList();
      valid.sort((a, b) {
        final aDist = Geolocator.distanceBetween(
          _userLocation.latitude,
          _userLocation.longitude,
          (a['latitude'] as num).toDouble(),
          (a['longitude'] as num).toDouble(),
        );
        final bDist = Geolocator.distanceBetween(
          _userLocation.latitude,
          _userLocation.longitude,
          (b['latitude'] as num).toDouble(),
          (b['longitude'] as num).toDouble(),
        );
        return aDist.compareTo(bDist);
      });
    }

    if (mode == 'rating') {
      final all = [...widget.clubs];
      all.sort((a, b) {
        final ra = double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
        final rb = double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
        return rb.compareTo(ra);
      });
      return all;
    }

    return widget.clubs;
  }

  List<MapObject> _buildMapObjects() {
    final List<MapObject> objects = [];

    final toShow = _clubsToShow();
    for (final club in toShow) {
      final latRaw = club['latitude'];
      final lonRaw = club['longitude'];
      if (latRaw == null || lonRaw == null) continue;

      final lat = (latRaw as num).toDouble();
      final lon = (lonRaw as num).toDouble();
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
              anchor: const Offset(0.5, 1.0),
            ),
          ),
          onTap: (self, point) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.fixed,
                duration: Duration(milliseconds: 2000),
                content: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: Text('$name — рейтинг $rating'),
                ),
              ),
            );
          },
        ),
      );
    }

    objects.add(
      PlacemarkMapObject(
        mapId: const MapObjectId('user_marker'),
        point: _userLocation,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/icons/user_marker.png'),
            scale: 1.6,
            anchor: const Offset(0.5, 0.5),
          ),
        ),
      ),
    );

    return objects;
  }

  void _updateMapObjects() {
    setState(() {
      _mapObjects = _buildMapObjects();
    });
  }

  Future<void> _moveToUser({double zoom = 14.5}) async {
    if (!_mapReady) return;
    try {
      await _controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation, zoom: zoom),
        ),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.6),
      );
    } catch (e) {
      debugPrint('Ошибка при перемещении камеры: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    final mapObjects = _buildMapObjects();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: const Text(
                'Карта клубов',
                style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Stack(
        children: [
          YandexMap(
            mapObjects: mapObjects,
            onMapCreated: (controller) async {
              _controller = controller;
              _mapReady = true;
              if (_positionLoaded) {
                await _moveToUser();
              } else {
                _updateMapObjects();
              }
            },
          ),
          if (widget.showFloatingButton)
            Positioned(
              right: 3,
              bottom: 18,
              child: FloatingActionButton(
                backgroundColor: AppColors.accentOrange,
                onPressed: _moveToUser,
                heroTag: 'center_user',
                child: const Icon(Icons.my_location, color: AppColors.background),
              ),
            ),
        ],
      ),
    );
  }
}
