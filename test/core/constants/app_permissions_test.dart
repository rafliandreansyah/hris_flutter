import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';

void main() {
  group('AppPermissions Constants Tests', () {
    test('verifies all 12 modules permission string mappings', () {
      // Activity
      expect(AppPermissions.activityManage, 'activity.manage');

      // Overtime
      expect(AppPermissions.approvalOvertimeAction, 'approval.overtime.action');
      expect(AppPermissions.reportOvertimeView, 'report.overtime.view');

      // Leave
      expect(AppPermissions.approvalLeaveAction, 'approval.leave.action');
      expect(AppPermissions.reportLeaveView, 'report.leave.view');

      // Attendance Request
      expect(AppPermissions.approvalAttendanceAction, 'approval.attendance.action');

      // Attendance Logs
      expect(AppPermissions.attendanceManage, 'attendance.manage');
      expect(AppPermissions.reportAttendanceView, 'report.attendance.view');

      // Employee Directory
      expect(AppPermissions.employeeView, 'employee.view');

      // Warning Letter
      expect(AppPermissions.warningLetterView, 'warning_letter.view');
      expect(AppPermissions.warningLetterCreate, 'warning_letter.create');

      // Payroll
      expect(AppPermissions.payrollSlipView, 'payroll.slip.view');

      // Schedule
      expect(AppPermissions.workScheduleView, 'work_schedule.view');

      // Reimbursement / Expenses
      expect(AppPermissions.reimbursementCreate, 'reimbursement.create');
      expect(AppPermissions.approvalReimbursementManager, 'approval.reimbursement.manager');

      // Assets
      expect(AppPermissions.assetMyAssets, 'asset.my_assets');

      // Resignation
      expect(AppPermissions.resignationView, 'resignation.view');
      expect(AppPermissions.approvalResignationManager, 'approval.resignation.manager');
    });
  });
}
