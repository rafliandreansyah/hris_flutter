import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/employee_info_card.dart';

/// Card absensi — hanya menampilkan informasi karyawan.
/// Untuk lokasi kerja, gunakan widget terpisah.
class AttendanceEmployeeCard extends StatelessWidget {
  final String employeeName;
  final String employeeRole;
  final String employeeId;
  final String? photoUrl;
  final String? initials;

  const AttendanceEmployeeCard({
    super.key,
    required this.employeeName,
    required this.employeeRole,
    required this.employeeId,
    this.photoUrl,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeInfoCard(
      employeeName: employeeName,
      employeeRole: employeeRole,
      employeeId: employeeId,
      photoUrl: photoUrl,
      initials: initials,
      avatarSize: 48,
    );
  }
}
