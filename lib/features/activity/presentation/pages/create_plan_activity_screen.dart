import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_photo_picker_card.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_plan_activity/create_plan_activity_bloc.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Form Pembuatan Rencana Aktivitas Bawahan (Create Activity Plan)
/// Sesuai Google Stitch Material 3 "Teal Oasis" & Clean Architecture BLoC.
class CreatePlanActivityScreen extends StatelessWidget {
  final ActivityRepository? activityRepository;
  final EmployeeRepository? employeeRepository;
  final CreatePlanActivityBloc? bloc;

  const CreatePlanActivityScreen({
    super.key,
    this.activityRepository,
    this.employeeRepository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreatePlanActivityBloc>.value(
        value: bloc!,
        child: const _CreatePlanActivityView(),
      );
    }
    return BlocProvider(
      create: (_) => CreatePlanActivityBloc(
        activityRepository: activityRepository,
        employeeRepository: employeeRepository,
      )..add(const CreatePlanActivityStarted()),
      child: const _CreatePlanActivityView(),
    );
  }
}

class _CreatePlanActivityView extends StatefulWidget {
  const _CreatePlanActivityView();

  @override
  State<_CreatePlanActivityView> createState() =>
      _CreatePlanActivityViewState();
}

class _CreatePlanActivityViewState extends State<_CreatePlanActivityView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Selected State
  EmployeeDirectoryItem? _selectedEmployee;
  ActivityTypeModel? _selectedActivityType;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  XFile? _pickedFile;
  ImageCompressResult? _compressResult;
  bool _isCompressingPhoto = false;

  @override
  void dispose() {
    _locationNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? _selectedDateTime : now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _showEmployeePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planBloc = context.read<CreatePlanActivityBloc>();
    final state = planBloc.state;
    final employees = state.employees;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: planBloc,
        child: StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = employees.where((emp) {
              if (query.isEmpty) return true;
              return emp.name.toLowerCase().contains(query) ||
                  emp.role.toLowerCase().contains(query) ||
                  emp.department.toLowerCase().contains(query) ||
                  (emp.employeeNumber?.toLowerCase().contains(query) ?? false);
            }).toList();

            return SafeArea(
              child: Container(
                height: MediaQuery.of(modalContext).size.height * 0.75,
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                child: Column(
                  children: [

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Pegawai / Bawahan',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              size: 20,
                              color: subtitleCol,
                            ),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, jabatan, atau divisi...',
                          hintStyle: TextStyle(
                            color: subtitleCol,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 18,
                            color: subtitleCol,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainerLow
                              : AppColors.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineMuted
                                  : AppColors.outlineMuted,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineMuted
                                  : AppColors.outlineMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // List of Employees
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  query.isEmpty
                                      ? 'Tidak ada data bawahan yang dapat ditugaskan.'
                                      : 'Tidak ada pegawai dengan kata kunci "$query".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: subtitleCol),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (_, index) {
                                final emp = filtered[index];
                                final isSelected =
                                    _selectedEmployee?.id == emp.id;

                                return ListTile(
                                  leading: AppAvatar(
                                    imageUrl: emp.avatarUrl,
                                    initials: emp.initials,
                                    size: 40,
                                  ),
                                  title: Text(
                                    emp.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.brandTeal
                                          : textCol,
                                    ),
                                  ),
                                  subtitle: Text(
                                    emp.employeeNumber != null &&
                                            emp.employeeNumber!.isNotEmpty
                                        ? '${emp.employeeNumber} • ${emp.role} • ${emp.department}'
                                        : '${emp.role} • ${emp.department}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtitleCol,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          LucideIcons.check,
                                          color: AppColors.brandTeal,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() => _selectedEmployee = emp);
                                    planBloc.add(
                                      CreatePlanActivityEmployeeSelected(emp),
                                    );
                                    Navigator.pop(sheetContext);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showActivityTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planBloc = context.read<CreatePlanActivityBloc>();
    final state = planBloc.state;
    final types = state.activityTypes;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: planBloc,
        child: SafeArea(
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
                          color: isSelected ? AppColors.brandTeal : null,
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
                              color: AppColors.brandTeal,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedActivityType = type);
                        planBloc.add(CreatePlanActivityTypeSelected(type));
                        Navigator.pop(sheetContext);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_selectedEmployee == null) {
      _showWarningSnackBar('Silakan pilih Pegawai / Bawahan yang ditugaskan.');
      return;
    }
    if (_selectedActivityType == null) {
      _showWarningSnackBar('Silakan pilih Jenis Aktivitas terlebih dahulu.');
      return;
    }
    if (_locationNameController.text.trim().isEmpty) {
      _showWarningSnackBar('Nama lokasi / tempat aktivitas wajib diisi.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showWarningSnackBar('Alamat lengkap lokasi aktivitas wajib diisi.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showWarningSnackBar('Deskripsi agenda / tugas aktivitas wajib diisi.');
      return;
    }

    final isoStartTime = _selectedDateTime.toUtc().toIso8601String();
    final targetEmployeeId =
        (_selectedEmployee!.rawId != null && _selectedEmployee!.rawId!.isNotEmpty)
            ? _selectedEmployee!.rawId!
            : _selectedEmployee!.id;

    context.read<CreatePlanActivityBloc>().add(
      CreatePlanActivitySubmitted(
        employeeId: targetEmployeeId,
        activityTypeId: _selectedActivityType!.id,
        startTime: isoStartTime,
        locationName: _locationNameController.text.trim(),
        locationAddress: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: 0,
        longitude: 0,
        file: _compressResult?.file ?? _pickedFile,
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
        : AppColors.surfaceContainerLowest;

    return BlocListener<CreatePlanActivityBloc, CreatePlanActivityState>(
      listener: (context, state) {
        if (state.status == CreatePlanActivityStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rencana aktivitas berhasil dibuat untuk bawahan!',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop(state.createdActivity);
        } else if (state.status == CreatePlanActivityStatus.failure) {
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
                      state.errorMessage.isNotEmpty
                          ? state.errorMessage
                          : 'Gagal membuat rencana aktivitas.',
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
                'Buat Rencana Aktivitas',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Penugasan rencana kerja bawahan (Status: Plan)',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 11,
                  color: subtitleCol,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Info Banner Status Plan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: 20,
                          color: AppColors.brandTeal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Penugasan Agenda Pegawai',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Plan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aktivitas ini dibuatkan berstatus Plan. Pegawai yang ditugaskan akan memulai dan mengunggah bukti saat tiba di lokasi.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Field 1: Pilih Pegawai (Bawahan)
                  _buildSectionCard(
                    cardBg: cardBg,
                    borderCol: borderCol,
                    title: 'Pilih Pegawai / Bawahan *',
                    child: InkWell(
                      onTap: _showEmployeePicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
                        ),
                        child: _selectedEmployee == null
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ketuk untuk memilih bawahan...',
                                    style: TextStyle(
                                      color: subtitleCol,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 18,
                                    color: subtitleCol,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  AppAvatar(
                                    imageUrl: _selectedEmployee!.avatarUrl,
                                    initials: _selectedEmployee!.initials,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedEmployee!.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textCol,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          _selectedEmployee!.employeeNumber != null &&
                                                  _selectedEmployee!.employeeNumber!.isNotEmpty
                                              ? '${_selectedEmployee!.employeeNumber} • ${_selectedEmployee!.role} • ${_selectedEmployee!.department}'
                                              : '${_selectedEmployee!.role} • ${_selectedEmployee!.department}',
                                          style: TextStyle(
                                            color: subtitleCol,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.checkCircle2,
                                    size: 18,
                                    color: AppColors.brandTeal,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Field 2: Jenis Aktivitas & Waktu Mulai
                  _buildSectionCard(
                    cardBg: cardBg,
                    borderCol: borderCol,
                    title: 'Detail Penugasan *',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jenis Aktivitas
                        _buildFieldLabel('Jenis Aktivitas', isRequired: true),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _showActivityTypePicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedActivityType?.name ??
                                      'Pilih jenis aktivitas...',
                                  style: TextStyle(
                                    color: _selectedActivityType != null
                                        ? textCol
                                        : subtitleCol,
                                    fontWeight: _selectedActivityType != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 14,
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
                        const SizedBox(height: 12),

                        // Tanggal & Waktu Mulai
                        _buildFieldLabel(
                          'Tanggal & Jam Mulai Rencana',
                          isRequired: true,
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDateTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 16,
                                      color: AppColors.brandTeal,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'EEEE, dd MMM yyyy • HH:mm',
                                      ).format(_selectedDateTime),
                                      style: TextStyle(
                                        color: textCol,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  LucideIcons.clock,
                                  size: 16,
                                  color: subtitleCol,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Field 3: Lokasi & Alamat
                  _buildSectionCard(
                    cardBg: cardBg,
                    borderCol: borderCol,
                    title: 'Lokasi Penugasan *',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          'Nama Lokasi / Tempat / Venue',
                          isRequired: true,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _locationNameController,
                          decoration: InputDecoration(
                            hintText:
                                'Misal: Kantor Klien PT ABC, Gedung Sudirman',
                            hintStyle: TextStyle(
                              color: subtitleCol.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFieldLabel('Alamat Lengkap', isRequired: true),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Misal: Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan',
                            hintStyle: TextStyle(
                              color: subtitleCol.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Field 4: Deskripsi Tugas / Instruksi
                  _buildSectionCard(
                    cardBg: cardBg,
                    borderCol: borderCol,
                    title: 'Instruksi / Rencana Aktivitas *',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Tuliskan rincian agenda, sasaran kerja, atau panduan tugas untuk bawahan...',
                            hintStyle: TextStyle(
                              color: subtitleCol.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Field 5: Lampiran Dokumen / Foto (Opsional)
                  _buildSectionCard(
                    cardBg: cardBg,
                    borderCol: borderCol,
                    title: 'Lampiran / Dokumen Panduan (Opsional)',
                    child: AppPhotoPickerCard(
                      file: _pickedFile,
                      compressResult: _compressResult,
                      isCompressing: _isCompressingPhoto,
                      sheetTitle: 'Pilih Lampiran Panduan',
                      sampleTitle: 'Gunakan Sampel Panduan',
                      sampleSubtitle: 'Simulasi dokumen panduan rencana aktivitas',
                      uploadPlaceholderTitle: 'Tap to Capture or Upload Document',
                      uploadPlaceholderSubtitle: 'Kamera atau Galeri (Maksimal 100 KB)',
                      previewTitle: 'Lampiran Panduan Aktivitas',
                      onFileChanged: (file, result) {
                        setState(() {
                          _pickedFile = file;
                          _compressResult = result;
                        });
                      },
                      onLoadingChanged: (loading) {
                        setState(() => _isCompressingPhoto = loading);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 7. Tombol Submit
                  BlocBuilder<CreatePlanActivityBloc, CreatePlanActivityState>(
                    builder: (context, state) {
                      return AppButton(
                        key: const ValueKey('submit_plan_activity_button'),
                        text: 'Buat Rencana Aktivitas',
                        isLoading: state.isSubmitting,
                        onPressed: state.isSubmitting ? null : _handleSubmit,
                        leadingIcon: LucideIcons.calendarPlus,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildSectionCard({
    required Color cardBg,
    required Color borderCol,
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final hasAsterisk = title.contains('*');
    final baseTitle = title.replaceAll('*', '').trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: baseTitle,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 14,
              ),
              children: hasAsterisk
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
