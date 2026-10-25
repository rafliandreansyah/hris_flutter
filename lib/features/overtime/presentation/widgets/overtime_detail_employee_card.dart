import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

/// Card Requester Profile ("INFORMASI PENGAJU") lembur — memakai
/// [RequestDetailPersonCard] global. [showContactActions] aktif untuk approver.
class OvertimeDetailEmployeeCard extends StatelessWidget {
  final OvertimeEmployeeModel employee;
  final bool showContactActions;

  const OvertimeDetailEmployeeCard({
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
      avatarUrl: resolveFileUrl(employee.photoUrl),
      initials: employee.initials,
      showContactActions: showContactActions,
    );
  }
}
