import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/utils/mapbox_geocoding_util.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_photo_picker_card.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_activity/create_activity_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/create_activity_map_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Create Activity Form sesuai Google Stitch Oasish Flutter M3 HRIS
class CreateActivityScreen extends StatelessWidget {
  final ActivityRepository? repository;
  final CreateActivityBloc? bloc;

  const CreateActivityScreen({super.key, this.repository, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreateActivityBloc>.value(
        value: bloc!,
        child: const _CreateActivityView(),
      );
    }
    return BlocProvider(
      create: (_) =>
          CreateActivityBloc(repository: repository)
            ..add(const CreateActivityStarted()),
      child: const _CreateActivityView(),
    );
  }
}

class _CreateActivityView extends StatefulWidget {
  const _CreateActivityView();

  @override
  State<_CreateActivityView> createState() => _CreateActivityViewState();
}

class _CreateActivityViewState extends State<_CreateActivityView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State (UI-only, non-business logic)
  ActivityTypeModel? _selectedActivityType;
  XFile? _pickedPhoto;
  ImageCompressResult? _compressResult;
  bool _isCompressingPhoto = false;
  bool _isGeocoding = false;
  String? _samplePhotoUrl;
  double _latitude = -6.2088;
  double _longitude = 106.8456;
  String _gpsAccuracy = '±3m';

  @override
  void dispose() {
    _locationNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshGpsLocation() async {
    try {
      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTest) {
        final isGpsOn = await PermissionUtil.ensureLocationServiceEnabled(context);
        if (!isGpsOn) return;

        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _gpsAccuracy = '±${pos.accuracy.round()}m';
        });
      } else {
        setState(() {
          _latitude = -6.2088 + (DateTime.now().millisecond % 5) * 0.0001;
          _longitude = 106.8456 + (DateTime.now().millisecond % 5) * 0.0001;
        });
      }
    } catch (_) {
      setState(() {
        _latitude = -6.2088 + (DateTime.now().millisecond % 5) * 0.0001;
        _longitude = 106.8456 + (DateTime.now().millisecond % 5) * 0.0001;
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.locateFixed, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lokasi GPS diperbarui ke: ${_latitude.toStringAsFixed(4)}° S, ${_longitude.toStringAsFixed(4)}° E',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showActivityTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createState = context.read<CreateActivityBloc>().state;
    final types = createState.activityTypes;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Pilih Jenis Aktivitas',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                if (types.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('Tidak ada jenis aktivitas tersedia.'),
                    ),
                  ),
                ...types.map((type) {
                  final isSelected = _selectedActivityType?.id == type.id;
                  return ListTile(
                    title: Text(
                      type.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0D9488) : null,
                      ),
                    ),
                    subtitle: type.code != null && type.code!.isNotEmpty
                        ? Text(
                            type.code!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            color: Color(0xFF0D9488),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedActivityType = type);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Validasi Form
    if (_selectedActivityType == null) {
      _showWarningSnackBar('Silakan pilih Activity Type terlebih dahulu.');
      return;
    }
    if (_locationNameController.text.trim().isEmpty) {
      _showWarningSnackBar('Nama lokasi / venue wajib diisi.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showWarningSnackBar('Deskripsi agenda / tujuan aktivitas wajib diisi.');
      return;
    }
    if (_pickedPhoto == null) {
      _showWarningSnackBar('Silakan upload Start Proof Photo aktivitas.');
      return;
    }

    setState(() => _isGeocoding = true);
    String geocodedAddress;
    try {
      geocodedAddress = await MapboxGeocodingUtil.getSafeAddress(
        latitude: _latitude,
        longitude: _longitude,
      );
    } catch (_) {
      geocodedAddress =
          'Lat: ${_latitude.toStringAsFixed(6)}, Lng: ${_longitude.toStringAsFixed(6)}';
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }

    if (!mounted) return;

    context.read<CreateActivityBloc>().add(
      CreateActivitySubmitted(
        activityTypeId: _selectedActivityType!.id,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationNameController.text.trim(),
        locationAddress: geocodedAddress,
        description: _descriptionController.text.trim(),
        file: _compressResult?.file ?? _pickedPhoto,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.backgroundSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final inputBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;

    return BlocListener<CreateActivityBloc, CreateActivityState>(
      listener: (context, createState) {
        if (createState.status == CreateActivityStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Aktivitas berhasil dibuat!')),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop(createState.createdActivity);
        } else if (createState.status == CreateActivityStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      createState.errorMessage.isNotEmpty
                          ? createState.errorMessage
                          : 'Gagal membuat aktivitas.',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgCol,
        // 1. TopAppBar
        appBar: AppBar(
          backgroundColor: bgCol,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Kembali',
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Activity',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Phase 1: Log initial activity & check-in',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 11,
                  color: subtitleCol,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.locateFixed, color: textCol, size: 20),
              tooltip: 'Perbarui Lokasi GPS',
              onPressed: _refreshGpsLocation,
            ),
            const SizedBox(width: 8),
          ],
        ),

        // 2. Main Scrollable Form Content
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live GPS Map View Card
                  CreateActivityMapCard(
                    latitude: _latitude,
                    longitude: _longitude,
                    gpsAccuracy: _gpsAccuracy,
                    onLocationChanged: (lat, lng, acc) {
                      setState(() {
                        _latitude = lat;
                        _longitude = lng;
                        _gpsAccuracy = acc;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Form Fields Container Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderCol, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field 1: Activity Type Selector
                        _buildFieldLabel(
                          label: 'Activity Type',
                          isRequired: true,
                          textCol: textCol,
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _showActivityTypePicker,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderCol, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.shapes,
                                  size: 18,
                                  color: subtitleCol,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedActivityType?.name ??
                                        'Select activity type...',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _selectedActivityType != null
                                          ? textCol
                                          : subtitleCol,
                                      fontSize: 14,
                                      fontWeight: _selectedActivityType != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronDown,
                                  size: 18,
                                  color: subtitleCol,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Field 2: Location / Venue Name Input
                        _buildFieldLabel(
                          label: 'Location / Venue Name',
                          isRequired: true,
                          textCol: textCol,
                        ),
                        const SizedBox(height: 6),
                        _buildTextInput(
                          controller: _locationNameController,
                          hintText: 'e.g., SCBD Tower 2 - Meeting Room 4A',
                          prefixIcon: LucideIcons.building2,
                          textCol: textCol,
                          subtitleCol: subtitleCol,
                          inputBg: inputBg,
                          borderCol: borderCol,
                        ),

                        const SizedBox(height: 16),

                        // Field 3: Description / Task Objective Input
                        _buildFieldLabel(
                          label: 'Description / Task Objective',
                          isRequired: true,
                          textCol: textCol,
                        ),
                        const SizedBox(height: 6),
                        _buildTextInput(
                          controller: _descriptionController,
                          hintText:
                              'Describe the purpose of this activity, agenda, or initial scope...',
                          prefixIcon: LucideIcons.alignLeft,
                          textCol: textCol,
                          subtitleCol: subtitleCol,
                          inputBg: inputBg,
                          borderCol: borderCol,
                          maxLines: 4,
                        ),

                        const SizedBox(height: 20),

                        // Field 5: Start Proof Photo Area
                        _buildFieldLabel(
                          label: 'Start Proof Photo',
                          isRequired: true,
                          textCol: textCol,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Take a selfie or capture venue photo',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPhotoPickerBox(
                          isDark: isDark,
                          borderCol: borderCol,
                          subtitleCol: subtitleCol,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Bottom Sticky Action Button
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color:
                (isDark ? AppColors.darkSurfaceContainerLowest : Colors.white)
                    .withValues(alpha: 0.95),
            border: Border(top: BorderSide(color: borderCol, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: BlocBuilder<CreateActivityBloc, CreateActivityState>(
                builder: (context, createState) {
                  final isBusy = createState.isSubmitting || _isGeocoding;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AppButton(
                      text: 'Submit & Start Activity',
                      leadingIcon: LucideIcons.checkCircle2,
                      onPressed: isBusy ? null : _handleSubmit,
                      isLoading: isBusy,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel({
    required String label,
    required bool isRequired,
    required Color textCol,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required Color textCol,
    required Color subtitleCol,
    required Color inputBg,
    required Color borderCol,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        style: AppTypography.bodyMedium.copyWith(color: textCol, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: subtitleCol.withValues(alpha: 0.7),
            fontSize: 13.5,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 10,
              bottom: maxLines > 1 ? 55 : 0,
            ),
            child: Icon(prefixIcon, size: 18, color: subtitleCol),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerBox({
    required bool isDark,
    required Color borderCol,
    required Color subtitleCol,
  }) {
    return AppPhotoPickerCard(
      file: _pickedPhoto,
      sampleUrl: _samplePhotoUrl,
      compressResult: _compressResult,
      isCompressing: _isCompressingPhoto,
      sheetTitle: 'Pilih Sumber Foto',
      sampleTitle: 'Gunakan Foto Sampel Lapangan',
      sampleSubtitle: 'Foto simulasi inspeksi Google Stitch',
      uploadPlaceholderTitle: 'Tap to Capture or Upload Photo',
      uploadPlaceholderSubtitle: 'Supports JPG, PNG • Auto Compressed',
      previewTitle: 'Foto Bukti Aktivitas',
      previewButtonKey: const ValueKey('preview_activity_photo_btn'),
      onFileChanged: (file, result) {
        setState(() {
          _pickedPhoto = file;
          _compressResult = result;
          if (file == null) {
            _samplePhotoUrl = null;
          }
        });
      },
      onLoadingChanged: (loading) {
        setState(() => _isCompressingPhoto = loading);
      },
    );
  }
}
