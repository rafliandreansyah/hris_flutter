import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:geocoding/geocoding.dart'; // Disabled sementara (biaya API)
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_activity/create_activity_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/create_activity_map_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';

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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State (UI-only, non-business logic)
  ActivityTypeModel? _selectedActivityType;
  XFile? _pickedPhoto;
  ImageCompressResult? _compressResult;
  bool _isCompressingPhoto = false;
  String? _samplePhotoUrl;
  double _latitude = -6.2088;
  double _longitude = 106.8456;
  String _gpsAccuracy = '±3m';

  @override
  void dispose() {
    _locationNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshGpsLocation() async {
    try {
      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTest) {
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
        // Hide dulu karena ada biayanya untuk geocoding
        // try {
        //   final placemarks = await Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
        //   if (placemarks.isNotEmpty) {
        //     final place = placemarks.first;
        //     final street = place.street ?? '';
        //     final subLoc = place.subLocality ?? '';
        //     final locality = place.locality ?? place.subAdministrativeArea ?? '';
        //     final admin = place.administrativeArea ?? '';
        //     final fullAddr = [street, subLoc, locality, admin]
        //         .where((e) => e.trim().isNotEmpty)
        //         .join(', ');
        //     final locName = subLoc.isNotEmpty
        //         ? subLoc
        //         : (place.name?.isNotEmpty == true ? place.name! : locality);

        //     if (_addressController.text.trim().isEmpty && fullAddr.isNotEmpty) {
        //       setState(() => _addressController.text = fullAddr);
        //     }
        //     if (_locationNameController.text.trim().isEmpty && locName.isNotEmpty) {
        //       setState(() => _locationNameController.text = locName);
        //     }
        //   }
        // } catch (_) {}
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

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() {
          _pickedPhoto = photo;
          _samplePhotoUrl = null;
        });

        // Kompres di background thread tanpa memblokir UI
        ImageCompressUtil.compressXFile(
          photo,
          quality: 75,
          minWidth: 1600,
          minHeight: 1600,
          onLoadingChanged: (isCompressing) {
            if (mounted) {
              setState(() => _isCompressingPhoto = isCompressing);
            }
          },
        ).then((result) {
          if (mounted) {
            setState(() {
              _pickedPhoto = result.file;
              _compressResult = result;
            });
            debugPrint(
              '📸 [CreateActivity] Foto berhasil dikompresi:\n'
              '   • Sebelum (RAW) : ${result.originalSizeFormatted} (${result.originalSizeBytes} bytes)\n'
              '   • Sesudah (OPT) : ${result.compressedSizeFormatted} (${result.compressedSizeBytes} bytes)\n'
              '   • Efisiensi     : Hemat ${result.savedPercentage.toStringAsFixed(1)}% '
              '(${ImageCompressResult.formatBytes(result.originalSizeBytes - result.compressedSizeBytes > 0 ? result.originalSizeBytes - result.compressedSizeBytes : 0)})\n'
              '   • Waktu         : ${result.compressionDuration.inMilliseconds} ms',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _useSamplePhoto() {
    try {
      final tempFile = File(
        '${Directory.systemTemp.path}/sample_activity_proof.jpg',
      );
      if (!tempFile.existsSync()) {
        final dummyBytes = [
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x01,
          0x00,
          0x48,
          0x00,
          0x48,
          0x00,
          0x00,
          0xFF,
          0xDB,
          0x00,
          0x43,
          0x00,
          0xFF,
          0xC0,
          0x00,
          0x0B,
          0x08,
          0x00,
          0x01,
          0x00,
          0x01,
          0x01,
          0x01,
          0x11,
          0x00,
          0xFF,
          0xC4,
          0x00,
          0x14,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x09,
          0xFF,
          0xDA,
          0x00,
          0x08,
          0x01,
          0x01,
          0x00,
          0x00,
          0x3F,
          0x00,
          0x7F,
          0x00,
          0xFF,
          0xD9,
        ];
        tempFile.writeAsBytesSync(dummyBytes);
      }
      setState(() {
        _pickedPhoto = XFile(tempFile.path);
        _samplePhotoUrl = null;
      });

      // Jalankan kompresi di background untuk foto sampel
      ImageCompressUtil.compressXFile(
        XFile(tempFile.path),
        quality: 75,
        onLoadingChanged: (isCompressing) {
          if (mounted) {
            setState(() => _isCompressingPhoto = isCompressing);
          }
        },
      ).then((result) {
        if (mounted) {
          setState(() {
            _pickedPhoto = result.file;
            _compressResult = result;
          });
          debugPrint(
            '📸 [CreateActivity] Foto sampel berhasil dikompresi:\n'
            '   • Sebelum (RAW) : ${result.originalSizeFormatted} (${result.originalSizeBytes} bytes)\n'
            '   • Sesudah (OPT) : ${result.compressedSizeFormatted} (${result.compressedSizeBytes} bytes)\n'
            '   • Efisiensi     : Hemat ${result.savedPercentage.toStringAsFixed(1)}% '
            '(${ImageCompressResult.formatBytes(result.originalSizeBytes - result.compressedSizeBytes > 0 ? result.originalSizeBytes - result.compressedSizeBytes : 0)})\n'
            '   • Waktu         : ${result.compressionDuration.inMilliseconds} ms',
          );
        }
      });
    } catch (_) {
      setState(() {
        _samplePhotoUrl =
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDxEj6zf8jMFMT2IElkG6Vs3mGF8Rqz-Tsv3DSoEXHyLRKMdpxe3q3JuQnuHZyY7FtJ9KTQSXIubgPPcc1Kl27DRrLMiNyqdZ1GLeWnvAwEqXGSe5Wp9dpbR4I9k1Fdo016b66GHpo3uc4EB4OKUkJbM8XJmr-AkUJyXBTNY_AjLZpW2Mvhti4n0CIjJYIdhMY0lXYFmldLjFOw5X3XgajsvOp7c6n82WZ7M6OAW67ZSWyMH80O3Yx7Ag';
      });
    }
  }

  void _showPhotoOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Sumber Foto',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDFA),
                    child: Icon(LucideIcons.camera, color: Color(0xFF0D9488)),
                  ),
                  title: const Text('Ambil Foto Kamera'),
                  subtitle: const Text('Gunakan kamera perangkat'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDFA),
                    child: Icon(LucideIcons.image, color: Color(0xFF0D9488)),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  subtitle: const Text('Pilih foto yang tersimpan'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDFA),
                    child: Icon(LucideIcons.sparkles, color: Color(0xFF0D9488)),
                  ),
                  title: const Text('Gunakan Foto Sampel Lapangan'),
                  subtitle: const Text('Foto simulasi inspeksi Google Stitch'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _useSamplePhoto();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createState = context.read<CreateActivityBloc>().state;
    final types = createState.activityTypes;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _handleSubmit() {
    // Validasi Form
    if (_selectedActivityType == null) {
      _showWarningSnackBar('Silakan pilih Activity Type terlebih dahulu.');
      return;
    }
    if (_locationNameController.text.trim().isEmpty) {
      _showWarningSnackBar('Nama lokasi / venue wajib diisi.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showWarningSnackBar('Alamat lengkap lokasi wajib diisi.');
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

    context.read<CreateActivityBloc>().add(
      CreateActivitySubmitted(
        activityTypeId: _selectedActivityType!.id,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationNameController.text.trim(),
        locationAddress: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        file: _pickedPhoto,
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
                    // onAddressDetected: (fullAddr, locName) {
                    //   // Disabled sementara karena geocoding API berbayar
                    //   if (_addressController.text.trim().isEmpty &&
                    //       fullAddr.isNotEmpty) {
                    //     setState(() => _addressController.text = fullAddr);
                    //   }
                    //   if (_locationNameController.text.trim().isEmpty &&
                    //       locName.isNotEmpty) {
                    //     setState(() => _locationNameController.text = locName);
                    //   }
                    // },
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

                        // Field 3: Address (Alamat Lengkap) Input
                        _buildFieldLabel(
                          label: 'Address (Alamat Lengkap)',
                          isRequired: true,
                          textCol: textCol,
                        ),
                        const SizedBox(height: 6),
                        _buildTextInput(
                          controller: _addressController,
                          hintText:
                              'e.g., Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan',
                          prefixIcon: LucideIcons.mapPin,
                          textCol: textCol,
                          subtitleCol: subtitleCol,
                          inputBg: inputBg,
                          borderCol: borderCol,
                        ),

                        const SizedBox(height: 16),

                        // Field 4: Description / Task Objective Input
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
                  final isSubmitting = createState.isSubmitting;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AppButton(
                      text: 'Submit & Start Activity',
                      leadingIcon: LucideIcons.checkCircle2,
                      onPressed: isSubmitting ? null : _handleSubmit,
                      isLoading: isSubmitting,
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
    final hasPhoto = _pickedPhoto != null || _samplePhotoUrl != null;

    final Widget boxContent;

    if (hasPhoto) {
      boxContent = Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: 1),
          color: isDark
              ? AppColors.darkSurfaceContainer
              : const Color(0xFFF1F5F9),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_pickedPhoto != null)
              Image.file(File(_pickedPhoto!.path), fit: BoxFit.cover)
            else if (_samplePhotoUrl != null)
              Image.network(
                _samplePhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(LucideIcons.image, size: 36, color: subtitleCol),
                ),
              ),

            // Top Left: Compressed file size badge
            if (_compressResult != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.fileCheck,
                        size: 12,
                        color: AppColors.brandTealSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_compressResult!.compressedSizeFormatted} (-${_compressResult!.savedPercentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Right: Remove Photo Button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedPhoto = null;
                    _compressResult = null;
                    _samplePhotoUrl = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Bottom Center: Ganti Foto button
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _showPhotoOptionsSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.camera, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Ganti Foto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Dashed Upload Placeholder Box (sesuai Google Stitch)
      boxContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showPhotoOptionsSheet,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: const Color(0xFF0D9488),
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
              radius: const Radius.circular(12),
            ),
            childOnTop: true,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                    : const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.camera,
                    size: 32,
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to Capture or Upload Photo',
                    style: TextStyle(
                      color: Color(0xFF0D9488),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Supports JPG, PNG • Auto Compressed',
                    style: TextStyle(color: subtitleCol, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return NonBlockingCompressIndicator(
      isCompressing: _isCompressingPhoto,
      borderRadius: 12,
      message: 'Mengompres foto...',
      child: boxContent,
    );
  }
}
