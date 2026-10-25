import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

/// Card Requester Profile ("INFORMASI PENGAJU") presensi luar — memakai
/// [RequestDetailPersonCard] global. [showContactActions] aktif untuk approver.
class AttendanceRequestEmployeeCard extends StatelessWidget {
  final AttendanceRequestEmployeeModel employee;
  final bool showContactActions;

  const AttendanceRequestEmployeeCard({
    super.key,
    required this.employee,
    this.showContactActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return RequestDetailPersonCard(
      title: 'Informasi Pengaju',
      name: employee.fullName,
      position: employee.position?.name,
      level: employee.levelName,
      department: employee.department?.name,
      company: employee.company?.name,
      employeeNumber: employee.employeeNumber,
      email: employee.email,
      phone: employee.phone,
      avatarUrl: employee.photoUrl,
      initials: employee.initials,
      showContactActions: showContactActions,
    );
  }
}
