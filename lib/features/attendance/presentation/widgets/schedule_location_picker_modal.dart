import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/core/utils/mapbox_geocoding_util.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Hasil pemilihan lokasi dari [ScheduleLocationPickerModal].
class ScheduleLocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String? locationName;

  const ScheduleLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.locationName,
  });
}

/// Menampilkan modal pemilih lokasi Google Maps dengan pin tetap di tengah layar.
Future<ScheduleLocationResult?> showScheduleLocationPickerModal(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  String? initialAddress,
  String title = 'Pilih Lokasi Presensi',
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<ScheduleLocationResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => ScheduleLocationPickerModal(
      initialLatitude: initialLatitude,
      initialLongitude: initialLongitude,
      initialAddress: initialAddress,
      title: title,
    ),
  );
}

class ScheduleLocationPickerModal extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String title;

  /// Bypass flag untuk lingkungan pengujian (unit/widget test)
  @visibleForTesting
  static bool bypassInTest = true;

  const ScheduleLocationPickerModal({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.title = 'Pilih Lokasi Presensi',
  });

  @override
  State<ScheduleLocationPickerModal> createState() =>
      _ScheduleLocationPickerModalState();
}

class _ScheduleLocationPickerModalState
    extends State<ScheduleLocationPickerModal> {
  GoogleMapController? _mapController;
  Timer? _debounceTimer;

  late double _currentLat;
  late double _currentLng;
  late String _currentAddress;
  String? _currentLocationName;

  bool _isGeocoding = false;
  bool _hasLocationPermission = false;

  bool get _isTestEnvironment {
    if (ScheduleLocationPickerModal.bypassInTest) return true;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST') ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLatitude ?? MapsConfig.defaultLatitude;
    _currentLng = widget.initialLongitude ?? MapsConfig.defaultLongitude;
    _currentAddress = widget.initialAddress ?? 'Menara Mandiri, Jakarta Selatan';

    if (!_isTestEnvironment &&
        (Platform.isAndroid || Platform.isIOS)) {
      _checkLocationPermission();
      _reverseGeocode(_currentLat, _currentLng);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final granted = await PermissionUtil.hasLocationPermission();
    if (mounted) {
      setState(() => _hasLocationPermission = granted);
    }
  }

  /// Melakukan reverse geocoding via Mapbox saat peta selesai digeser
  Future<void> _reverseGeocode(double lat, double lng) async {
    if (_isTestEnvironment) return;

    setState(() => _isGeocoding = true);
    try {
      final res = await MapboxGeocodingUtil.reverseGeocode(
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        setState(() {
          _currentAddress = res?.placeName ??
              'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
          _currentLocationName = res?.locationName;
          _isGeocoding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentAddress =
              'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
          _isGeocoding = false;
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentLat = position.target.latitude;
    _currentLng = position.target.longitude;
  }

  void _onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocode(_currentLat, _currentLng);
    });
  }

  /// Memusatkan kamera peta ke lokasi GPS aktual perangkat
  Future<void> _centerToCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      if (!mounted) return;

      final locResult = await PermissionUtil.requestLocationPermission(
        context: context,
        showRationale: true,
      );
      if (!locResult.isGranted) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLat, _currentLng),
            zoom: 16.5,
          ),
        ),
      );

      _reverseGeocode(_currentLat, _currentLng);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final tealBrand =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);

    final sheetHeight = MediaQuery.of(context).size.height * 0.86;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: [
          // ── Drag Handle & Header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            decoration: BoxDecoration(
              color: surfaceCol,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: borderCol, width: 1)),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkOutlineMuted
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tealBrand.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: tealBrand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Geser peta untuk mengarahkan pin ke lokasi presensi',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: subtitleCol, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Interactive Map Viewport with Center Pin ─────────────────
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Map Element
                if (!_isTestEnvironment &&
                    (Platform.isAndroid || Platform.isIOS))
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentLat, _currentLng),
                      zoom: 16.5,
                    ),
                    myLocationEnabled: _hasLocationPermission,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                  )
                else
                  _buildFallbackMap(isDark, textCol, subtitleCol),

                // Center Fixed Pin (Pin tetap di tengah viewport)
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Geser peta ke lokasi presensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        LucideIcons.mapPin,
                        size: 40,
                        color: AppColors.errorRed,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // Titik tumpu pin di peta
                      Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 38), // Offset penyeimbang visual pin
                    ],
                  ),
                ),

                // Shortcut: Pusatkan ke Lokasi Saya (Floating Button)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _centerToCurrentLocation,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceCol,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderCol, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.locateFixed,
                          color: tealBrand,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Summary Card & Konfirmasi ─────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: surfaceCol,
              border: Border(top: BorderSide(color: borderCol, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alamat Terpilih:',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_currentLat.toStringAsFixed(5)}°, ${_currentLng.toStringAsFixed(5)}°',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isGeocoding)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mendeteksi alamat titik peta...',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _currentAddress,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textCol,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 14),
                AppButton(
                  key: const Key('schedule-location-picker-confirm-button'),
                  text: 'Pilih Lokasi Ini',
                  variant: AppButtonVariant.primary,
                  leadingIcon: LucideIcons.checkCircle,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).pop(
                      ScheduleLocationResult(
                        latitude: _currentLat,
                        longitude: _currentLng,
                        address: _currentAddress,
                        locationName: _currentLocationName,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMap(bool isDark, Color textCol, Color subtitleCol) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.map,
              size: 48,
              color: subtitleCol.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive Google Maps Picker',
              style: AppTypography.titleSmall.copyWith(
                color: textCol,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Geser peta untuk menentukan titik koordinat',
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
