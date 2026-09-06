import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/create_activity_map_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Create Activity Form sesuai Google Stitch Oasish Flutter M3 HRIS
class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _locationNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State
  String? _selectedActivityType;
  XFile? _pickedPhoto;
  String? _samplePhotoUrl;
  double _latitude = -6.2088;
  double _longitude = 106.8456;
  final String _gpsAccuracy = '±3m';
  bool _isSubmitting = false;

  final List<String> _activityTypes = const [
    'Client Meeting',
    'Site Inspection',
    'Architecture Review',
    'Field Maintenance',
    'General Operational',
  ];

  @override
  void dispose() {
    _locationNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _refreshGpsLocation() {
    setState(() {
      // Sedikit jitter realistis untuk simulasi update koordinat GPS
      _latitude = -6.2088 + (DateTime.now().millisecond % 5) * 0.0001;
      _longitude = 106.8456 + (DateTime.now().millisecond % 5) * 0.0001;
    });
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
      if (photo != null) {
        setState(() {
          _pickedPhoto = photo;
          _samplePhotoUrl = null;
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
    setState(() {
      _pickedPhoto = null;
      _samplePhotoUrl =
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDxEj6zf8jMFMT2IElkG6Vs3mGF8Rqz-Tsv3DSoEXHyLRKMdpxe3q3JuQnuHZyY7FtJ9KTQSXIubgPPcc1Kl27DRrLMiNyqdZ1GLeWnvAwEqXGSe5Wp9dpbR4I9k1Fdo016b66GHpo3uc4EB4OKUkJbM8XJmr-AkUJyXBTNY_AjLZpW2Mvhti4n0CIjJYIdhMY0lXYFmldLjFOw5X3XgajsvOp7c6n82WZ7M6OAW67ZSWyMH80O3Yx7Ag';
    });
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Pilih Jenis Aktivitas',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ..._activityTypes.map((type) {
                  final isSelected = _selectedActivityType == type;
                  return ListTile(
                    title: Text(
                      type,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0D9488) : null,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(LucideIcons.check, color: Color(0xFF0D9488))
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
    if (_pickedPhoto == null && _samplePhotoUrl == null) {
      _showWarningSnackBar('Silakan upload Start Proof Photo aktivitas.');
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final dateFormatted = DateFormat('dd MMM yyyy').format(now);

    final newActivity = ActivityItem(
      id: 'ACT-${now.millisecondsSinceEpoch.toString().substring(7)}',
      title: _selectedActivityType!,
      description: _descriptionController.text.trim(),
      userName: 'Sarah Jenkins',
      userRole: 'Frontend Engineer',
      department: 'Engineering',
      company: 'PT Oasish Tech Nusantara',
      initials: 'SJ',
      status: ActivityStatus.inProgress,
      location: _locationNameController.text.trim(),
      time: timeStr,
      date: now,
      isMyActivity: true,
      category: _selectedActivityType!,
      latitude: _latitude,
      longitude: _longitude,
      fullAddress: _addressController.text.trim(),
      districtCity: 'Jakarta Selatan, DKI Jakarta',
      gpsAccuracy: _gpsAccuracy,
      isGpsVerified: true,
      phases: [
        ActivityPhaseItem(
          phaseNumber: 1,
          title: 'Phase 1: Start & Check-In',
          time: '$timeStr PM, $dateFormatted',
          label: 'Initial Description / Task Scope',
          notes: _descriptionController.text.trim(),
          imageUrl: _samplePhotoUrl ?? _pickedPhoto?.path,
          imageDescription: 'Field verification proof photo',
        ),
      ],
    );

    Navigator.of(context).pop(newActivity);
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
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final inputBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;

    return Scaffold(
      backgroundColor: bgCol,
      // 1. TopAppBar
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: textCol,
            size: 20,
          ),
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
            icon: Icon(
              LucideIcons.locateFixed,
              color: textCol,
              size: 20,
            ),
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
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                                  _selectedActivityType ??
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: (isDark
                  ? AppColors.darkSurfaceContainerLowest
                  : Colors.white)
              .withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: borderCol, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    LucideIcons.checkCircle2,
                    size: 20,
                    color: Colors.white,
                  ),
            label: Text(
              _isSubmitting ? 'Memproses...' : 'Submit & Start Activity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
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
        style: AppTypography.bodyMedium.copyWith(
          color: textCol,
          fontSize: 14,
        ),
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

    if (hasPhoto) {
      return Container(
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
              Image.file(
                File(_pickedPhoto!.path),
                fit: BoxFit.cover,
              )
            else if (_samplePhotoUrl != null)
              Image.network(
                _samplePhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(LucideIcons.image, size: 36, color: subtitleCol),
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
    }

    // Dashed Upload Placeholder Box (sesuai Google Stitch)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showPhotoOptionsSheet,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                : const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF0D9488),
              width: 1.5,
              style: BorderStyle.solid,
            ),
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
                'Supports JPG, PNG up to 5MB',
                style: TextStyle(
                  color: subtitleCol,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
