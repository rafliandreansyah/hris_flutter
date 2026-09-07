import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Callback signature for real-time location coordinates update.
typedef LocationChangedCallback =
    void Function(double latitude, double longitude, String accuracy);

/// Callback signature for detected reverse-geocoded address.
typedef AddressDetectedCallback =
    void Function(String fullAddress, String locationName);

/// Global Reusable Real-time Map Card Component.
///
/// Features:
/// - Desain kontainer berbingkai konsisten dengan [ActivityMapCard] (padding 16, radius 20, border & shadow).
/// - Header dengan ikon peta dan badge status real-time.
/// - Kotak peta berbingkai (ClipRRect radius 14 dengan border).
/// - Titik biru pulsing real-time GPS (tanpa pin marker manual) yang selalu terlihat.
/// - Kamera Google Maps otomatis fokus & centering ke koordinat HP pengguna saat map dimuat.
/// - Deteksi izin runtime otomatis dan tombol "Pusatkan ke Lokasi Saya".
/// - Tombol "Buka di Maps" untuk membuka koordinat di aplikasi maps default perangkat.
/// - Konten bawah peta fokus pada koordinat chip & status akurasi real-time.
class AppRealtimeMapCard extends StatefulWidget {
  final String title;
  final double latitude;
  final double longitude;
  final String gpsAccuracy;
  final double mapHeight;
  final bool enableTracking;
  final bool showOpenInMaps;
  final LocationChangedCallback? onLocationChanged;
  final AddressDetectedCallback? onAddressDetected;

  const AppRealtimeMapCard({
    super.key,
    this.title = 'Lokasi Aktivitas',
    this.latitude = -6.2088,
    this.longitude = 106.8456,
    this.gpsAccuracy = '±3m',
    this.mapHeight = 150.0,
    this.enableTracking = true,
    this.showOpenInMaps = true,
    this.onLocationChanged,
    this.onAddressDetected,
  });

  @override
  State<AppRealtimeMapCard> createState() => AppRealtimeMapCardState();
}

class AppRealtimeMapCardState extends State<AppRealtimeMapCard>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late double _currentLat;
  late double _currentLng;
  late String _currentAccuracy;
  bool _hasLocationPermission = false;
  bool _isLocating = true;

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentLat = widget.latitude;
    _currentLng = widget.longitude;
    _currentAccuracy = widget.gpsAccuracy;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    if (!_isTestEnvironment &&
        !Platform.isWindows &&
        !Platform.isLinux &&
        !Platform.isMacOS) {
      _initGpsLocation();
    } else {
      _isLocating = false;
    }
  }

  @override
  void didUpdateWidget(covariant AppRealtimeMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _currentLat = widget.latitude;
      _currentLng = widget.longitude;
      _animateCameraToCurrent();
    }
    if (oldWidget.gpsAccuracy != widget.gpsAccuracy) {
      _currentAccuracy = widget.gpsAccuracy;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Inisialisasi pengambilan posisi GPS dan streaming real-time
  Future<void> _initGpsLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLocating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }

      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
          _isLocating = true;
        });
      }

      // 1. Dapatkan posisi saat ini dengan akurasi tinggi
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _handleNewPosition(position);

      // 2. Dapatkan stream posisi real-time jika tracking aktif
      if (widget.enableTracking) {
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen(_handleNewPosition);
      }
    } catch (e) {
      debugPrint('[AppRealtimeMapCard] Gps fetch error: $e');
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _handleNewPosition(Position position) {
    if (!mounted) return;
    final accuracyText = '±${position.accuracy.round()}m';
    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _currentAccuracy = accuracyText;
      _isLocating = false;
      _hasLocationPermission = true;
    });

    _animateCameraToCurrent();
    widget.onLocationChanged?.call(
      position.latitude,
      position.longitude,
      accuracyText,
    );

    _reverseGeocode(position.latitude, position.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      if (_isTestEnvironment) return;
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final subLoc = place.subLocality ?? '';
        final locality = place.locality ?? place.subAdministrativeArea ?? '';
        final admin = place.administrativeArea ?? '';

        final fullAddr = [
          street,
          subLoc,
          locality,
          admin,
        ].where((element) => element.trim().isNotEmpty).join(', ');
        final locName = subLoc.isNotEmpty
            ? subLoc
            : (place.name?.isNotEmpty == true ? place.name! : locality);

        widget.onAddressDetected?.call(fullAddr, locName);
      }
    } catch (_) {}
  }

  void _animateCameraToCurrent() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_currentLat, _currentLng), zoom: 16.5),
      ),
    );
  }

  /// Method publik untuk merefresh lokasi GPS secara manual
  Future<void> refreshLocation() async {
    _animateCameraToCurrent();
    if (!_isTestEnvironment) {
      await _initGpsLocation();
    }
  }

  /// Membuka lokasi aktual pada aplikasi Maps default perangkat
  Future<void> _openInDefaultMaps() async {
    if (_isTestEnvironment) return;
    await MapsConfig.openGoogleMaps(
      latitude: _currentLat,
      longitude: _currentLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final targetLocation = LatLng(_currentLat, _currentLng);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar: Map Icon + Title + Real-time Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.map,
                    size: 18,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              // Real-time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandTeal.withValues(alpha: 0.15)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Real-time',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Framed Map Container (ClipRRect radius 14, no pin marker, visible blue GPS pulsing dot)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: widget.mapHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: borderCol, width: 1),
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Native GoogleMap with Real-time Blue Dot (myLocationEnabled)
                  if (!_isTestEnvironment &&
                      (Platform.isAndroid || Platform.isIOS))
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: targetLocation,
                        zoom: 16.5,
                      ),
                      // Murni lingkaran biru GPS tanpa pin marker merah/buatan
                      markers: const <Marker>{},
                      circles: {
                        Circle(
                          circleId: const CircleId('user_realtime_radius'),
                          center: targetLocation,
                          radius: 35,
                          fillColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.14),
                          strokeColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                      },
                      myLocationEnabled: _hasLocationPermission,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      liteModeEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        // Langsung fokuskan kamera ke koordinat aktual perangkat
                        _animateCameraToCurrent();
                      },
                    )
                  else
                    _buildFallbackMapPreview(isDark, textCol),

                  // Indikator Titik Biru GPS (Pulsing Radar Blue Dot) di tengah peta
                  // Memberikan visualisasi instan posisi real-time tanpa pin marker manual
                  IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Gelombang radar biru luar
                              Container(
                                width: 38 * _pulseAnimation.value + 16,
                                height: 38 * _pulseAnimation.value + 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2563EB).withValues(
                                    alpha: (1.0 - _pulseAnimation.value) * 0.35,
                                  ),
                                ),
                              ),
                              // Titik biru solid GPS
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2563EB),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Overlay Badge: Live GPS Tracking (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isLocating
                                ? 'Mencari GPS...'
                                : 'Live GPS Tracking',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overlay Badge: GPS Akurat (Bottom Left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkSurfaceContainerLowest
                                    : Colors.white)
                                .withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCol, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'GPS Akurat ($_currentAccuracy)',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textCol,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Floating: Pusatkan ke Lokasi Saya (Bottom Right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _animateCameraToCurrent();
                          _initGpsLocation();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.darkSurfaceContainerLowest
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            border: Border.all(color: borderCol, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.locateFixed,
                            size: 15,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Content: Lat-Long Coordinates Chip & Tombol Buka di Maps Default
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderCol, width: 1),
                ),
                child: Text(
                  '${_currentLat.toStringAsFixed(4)}° S, ${_currentLng.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandTeal,
                  ),
                ),
              ),
              if (widget.showOpenInMaps)
                InkWell(
                  onTap: _openInDefaultMaps,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.externalLink,
                          size: 13,
                          color: AppColors.brandTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Buka di Maps',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tampilan Fallback Map Preview saat testing/web dengan indikator titik biru GPS
  Widget _buildFallbackMapPreview(bool isDark, Color textCol) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.9,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Google Maps • Live GPS Blue Dot',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
