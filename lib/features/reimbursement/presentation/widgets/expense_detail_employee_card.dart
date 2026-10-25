import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';

/// Card Requester Profile ("INFORMASI PENGAJU") reimbursement/kasbon —
/// memakai [RequestDetailPersonCard] global. Tombol kontak otomatis muncul
/// saat yang melihat bukan pengaju itu sendiri (mis. approver/finance).
class ExpenseDetailEmployeeCard extends StatelessWidget {
  final ExpenseEmployeeModel employee;
  final bool? showContactActions;

  const ExpenseDetailEmployeeCard({
    super.key,
    required this.employee,
    this.showContactActions,
  });

  @override
  Widget build(BuildContext context) {
    return RequestDetailPersonCard(
      title: 'Informasi Pengaju',
      name: employee.fullName,
      position: employee.position,
      level: employee.levelName,
      department: employee.department,
      company: employee.company,
      employeeNumber: employee.displayEmployeeNumber,
      email: employee.email,
      phone: employee.phone,
      avatarUrl: employee.resolvedPhotoUrl,
      initials: employee.initials,
      showContactActions:
          showContactActions ??
          RequestDetailPersonCard.isOtherPerson(employee.id),
    );
  }
}
