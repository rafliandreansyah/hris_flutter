import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

/// Card Requester Profile ("INFORMASI PENGAJU") — memakai
/// [RequestDetailPersonCard] global agar tata letak seragam & tidak terpotong.
/// [showContactActions] diaktifkan saat dibuka sebagai approver.
class LeaveDetailEmployeeCard extends StatelessWidget {
  final LeaveEmployeeDetailModel employee;
  final bool showContactActions;

  const LeaveDetailEmployeeCard({
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
      avatarUrl: employee.resolvedAvatarUrl,
      initials: employee.initials,
      showContactActions: showContactActions,
    );
  }
}
