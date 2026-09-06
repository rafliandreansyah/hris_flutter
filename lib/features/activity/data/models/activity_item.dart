import 'package:flutter/material.dart';

/// Status aktivitas kerja pada Oasish HRIS
enum ActivityStatus {
  completed,
  inProgress,
  pendingReview,
}

extension ActivityStatusExtension on ActivityStatus {
  String get label {
    switch (this) {
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.inProgress:
        return 'In Progress';
      case ActivityStatus.pendingReview:
        return 'Pending Review';
    }
  }

  Color get textColor {
    switch (this) {
      case ActivityStatus.completed:
        return const Color(0xFF166534); // Green 800
      case ActivityStatus.inProgress:
        return const Color(0xFFB45309); // Amber 700
      case ActivityStatus.pendingReview:
        return const Color(0xFF0369A1); // Sky 700
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ActivityStatus.completed:
        return const Color(0xFFDCFCE7); // Green 100
      case ActivityStatus.inProgress:
        return const Color(0xFFFEF3C7); // Amber 100
      case ActivityStatus.pendingReview:
        return const Color(0xFFE0F2FE); // Sky 100
    }
  }

  Color get dotColor {
    switch (this) {
      case ActivityStatus.completed:
        return const Color(0xFF16A34A);
      case ActivityStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ActivityStatus.pendingReview:
        return const Color(0xFF0284C7);
    }
  }
}

/// Model data fase progres aktivitas (2-Phase Lifecycle)
class ActivityPhaseItem {
  final int phaseNumber;
  final String title;
  final String time;
  final String label;
  final String notes;
  final String? imageUrl;
  final String? imageDescription;

  const ActivityPhaseItem({
    required this.phaseNumber,
    required this.title,
    required this.time,
    required this.label,
    required this.notes,
    this.imageUrl,
    this.imageDescription,
  });
}

/// Model item log aktivitas kerja harian (Daily Work Log / Activity Report)
class ActivityItem {
  final String id;
  final String title;
  final String description;
  final String userName;
  final String userRole;
  final String department;
  final String company;
  final String? avatarUrl;
  final String initials;
  final ActivityStatus status;
  final String location;
  final String time;
  final DateTime date;
  final bool isMyActivity;
  final String? category;
  final double latitude;
  final double longitude;
  final String fullAddress;
  final String districtCity;
  final String gpsAccuracy;
  final bool isGpsVerified;
  final List<ActivityPhaseItem>? phases;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.userName,
    required this.userRole,
    required this.department,
    required this.company,
    this.avatarUrl,
    required this.initials,
    required this.status,
    required this.location,
    required this.time,
    required this.date,
    this.isMyActivity = false,
    this.category,
    this.latitude = -6.2253,
    this.longitude = 106.8097,
    this.fullAddress = 'SCBD Lot 28, Jl. Jend. Sudirman Kav. 52-53',
    this.districtCity =
        'Kec. Kebayoran Baru, Kota Jakarta Selatan, DKI Jakarta 12190',
    this.gpsAccuracy = '±3m',
    this.isGpsVerified = true,
    this.phases,
  });

  /// Mengembalikan list fase progres aktivitas default jika tidak di-override
  List<ActivityPhaseItem> get activePhases {
    if (phases != null && phases!.isNotEmpty) {
      return phases!;
    }
    return [
      ActivityPhaseItem(
        phaseNumber: 1,
        title: 'Phase 1: Start & Check-In',
        time: '$time, 27 Aug 2026',
        label: 'Initial Description / Task Scope',
        notes: description.isNotEmpty
            ? description
            : 'Conducted field safety audit, inspected emergency fire exits, and reviewed worker safety gear adherence.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDxEj6zf8jMFMT2IElkG6Vs3mGF8Rqz-Tsv3DSoEXHyLRKMdpxe3q3JuQnuHZyY7FtJ9KTQSXIubgPPcc1Kl27DRrLMiNyqdZ1GLeWnvAwEqXGSe5Wp9dpbR4I9k1Fdo016b66GHpo3uc4EB4OKUkJbM8XJmr-AkUJyXBTNY_AjLZpW2Mvhti4n0CIjJYIdhMY0lXYFmldLjFOw5X3XgajsvOp7c6n82WZ7M6OAW67ZSWyMH80O3Yx7Ag',
        imageDescription: 'Field safety audit and structural inspection site',
      ),
      ActivityPhaseItem(
        phaseNumber: 2,
        title: 'Phase 2: Completion & Report',
        time: '15:30 PM, 27 Aug 2026',
        label: 'Completion Notes / Outcome',
        notes:
            'All inspection points passed. Fire exits clear of obstacles. Signed report handed to site coordinator.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAsxKPvfAIUfjVETL1ey0y_lsc2YLMnLo5ELOPi3I7PK_ES7qlIWaQxNaIXSuR3dMkmwaiXWF61vLV6oIk1iuFHkBJH-CLYSPo2HrlAjOedkS_DE6MleRZE4rc-XmSV3sz84FkCC_xaw3L5sXCucDjlO0Q-N5fvYUvwdoUUj3MkJw4PoUqa9tAwaGufUowWwdNjQygmkfdM2MKIMbP8UxG-5jgxN9JPMIYiOVVpS3C9F61usk4E1gfX3Q',
        imageDescription: 'Certified safety gear and signed site documentation',
      ),
    ];
  }

  /// Sample data aktivitas sesuai Google Stitch UI & skenario HRIS
  static List<ActivityItem> get sampleActivities {
    final now = DateTime.now();
    return [
      ActivityItem(
        id: 'ACT-001',
        title: 'Code Review',
        description:
            'Reviewed PR #204 for attendance geolocation improvements and merged to develop branch.',
        userName: 'Sarah Jenkins',
        userRole: 'Frontend Engineer',
        department: 'Engineering',
        company: 'PT Oasish Tech Nusantara',
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCF6q8Nm974PgAc0X1CfstbfECIwL_UQeoKNxk-0zfhMDkE80lpoOrOhls0sPSV0atnv7PwJ5Bg9neK38yCh1U1wGirCNTcGnbSCN2pWG7CLx0pMXlj0_alYRirdscfGNceBRK8OVb1nL03IzTLMcczAvP_TKHpeA-WbiIFQ7uPYxcvT70n_3D9FbrPghyzzzRZqKpvvwe3StsHWaoCvqofaNLVFg9DsqZs8klLp2U2anIrfTeZDuJswQ',
        initials: 'SJ',
        status: ActivityStatus.completed,
        location: 'HQ Office - Floor 3',
        time: '14:10',
        date: now,
        isMyActivity: true,
        category: 'Engineering Review',
      ),
      ActivityItem(
        id: 'ACT-002',
        title: 'Site Inspection',
        description:
            'Conducted weekly safety assessment and verified material delivery manifests.',
        userName: 'Budi Santoso',
        userRole: 'Site Supervisor (L4)',
        department: 'Operations',
        company: 'PT Oasish Tech Nusantara',
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCCieNhGFwpf35jQli4A7sUHZqFs4AQG6Hk6X7M3SKX72F1sVS96mWfTOwsiTG285IRf-1DUwDasLmVYdaJXAle6BNMM_mHtxNDJ0iPfQuAF4mWhbhKLeyXYfsVLKofU1lbmHZAy4X0t3MeSsedxTr0jnU_uU4n0bpiIhXZ8Ab6bHCFGnhBV-d64VNQJctpE0fqkf0Nv-rmrYRSjpXRB1QVJxgQsqU-mFfE2Fq_UwIUK1ZcS8r2oLxgDw',
        initials: 'BS',
        status: ActivityStatus.completed,
        location: 'SCBD Tower 2 - Construction Floor 14',
        time: '11:30',
        date: now,
        isMyActivity: false,
        category: 'Site Inspection',
        latitude: -6.2253,
        longitude: 106.8097,
        fullAddress: 'SCBD Lot 28, Jl. Jend. Sudirman Kav. 52-53',
        districtCity:
            'Kec. Kebayoran Baru, Kota Jakarta Selatan, DKI Jakarta 12190',
        phases: const [
          ActivityPhaseItem(
            phaseNumber: 1,
            title: 'Phase 1: Start & Check-In',
            time: '12:24 PM, 27 Aug 2026',
            label: 'Initial Description / Task Scope',
            notes:
                'Conducted field safety audit, inspected emergency fire exits, and reviewed worker safety gear adherence.',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDxEj6zf8jMFMT2IElkG6Vs3mGF8Rqz-Tsv3DSoEXHyLRKMdpxe3q3JuQnuHZyY7FtJ9KTQSXIubgPPcc1Kl27DRrLMiNyqdZ1GLeWnvAwEqXGSe5Wp9dpbR4I9k1Fdo016b66GHpo3uc4EB4OKUkJbM8XJmr-AkUJyXBTNY_AjLZpW2Mvhti4n0CIjJYIdhMY0lXYFmldLjFOw5X3XgajsvOp7c6n82WZ7M6OAW67ZSWyMH80O3Yx7Ag',
            imageDescription:
                'Active modern construction site during midday inspection',
          ),
          ActivityPhaseItem(
            phaseNumber: 2,
            title: 'Phase 2: Completion & Report',
            time: '15:30 PM, 27 Aug 2026',
            label: 'Completion Notes / Outcome',
            notes:
                'All inspection points passed. Fire exits clear of obstacles. Signed report handed to site coordinator.',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAsxKPvfAIUfjVETL1ey0y_lsc2YLMnLo5ELOPi3I7PK_ES7qlIWaQxNaIXSuR3dMkmwaiXWF61vLV6oIk1iuFHkBJH-CLYSPo2HrlAjOedkS_DE6MleRZE4rc-XmSV3sz84FkCC_xaw3L5sXCucDjlO0Q-N5fvYUvwdoUUj3MkJw4PoUqa9tAwaGufUowWwdNjQygmkfdM2MKIMbP8UxG-5jgxN9JPMIYiOVVpS3C9F61usk4E1gfX3Q',
            imageDescription:
                'Industrial safety gear and signed report handoff',
          ),
        ],
      ),
      ActivityItem(
        id: 'ACT-003',
        title: 'Regression Testing',
        description:
            'Executing mobile app test suite for v2.4 sprint release. Verified biometric clock-in modules.',
        userName: 'Jessica Pranata',
        userRole: 'QA Engineer',
        department: 'Engineering',
        company: 'PT Oasish Tech Nusantara',
        initials: 'JP',
        status: ActivityStatus.inProgress,
        location: 'Remote / Home Office',
        time: '10:15',
        date: now,
        isMyActivity: false,
        category: 'Quality Assurance',
      ),
      ActivityItem(
        id: 'ACT-004',
        title: 'Sprint Planning & Backlog Refinement',
        description:
            'Finalized user stories and acceptance criteria for upcoming HR payroll automation cycle.',
        userName: 'Sarah Jenkins',
        userRole: 'Frontend Engineer',
        department: 'Engineering',
        company: 'PT Oasish Tech Nusantara',
        initials: 'SJ',
        status: ActivityStatus.completed,
        location: 'HQ Office - Meeting Room 4A',
        time: '09:00',
        date: now.subtract(const Duration(days: 1)),
        isMyActivity: true,
        category: 'Sprint Event',
      ),
      ActivityItem(
        id: 'ACT-005',
        title: 'New Hires Induction Session',
        description:
            'Completed onboarding induction program for batch September 2026 engineering & product recruits.',
        userName: 'Rina Kusuma',
        userRole: 'HR Specialist',
        department: 'People Operations',
        company: 'PT Oasish Tech Nusantara',
        initials: 'RK',
        status: ActivityStatus.pendingReview,
        location: 'HQ Office - Training Center',
        time: '08:30',
        date: now.subtract(const Duration(days: 2)),
        isMyActivity: false,
        category: 'Human Capital',
      ),
      ActivityItem(
        id: 'ACT-006',
        title: 'Client System Demonstration',
        description:
            'Presented the latest mobile attendance tracking module to key enterprise stakeholders.',
        userName: 'David Wijaya',
        userRole: 'Product Manager',
        department: 'Product',
        company: 'PT Oasish Tech Nusantara',
        initials: 'DW',
        status: ActivityStatus.completed,
        location: 'Plaza Senayan Client Suite',
        time: '15:45',
        date: now.subtract(const Duration(days: 3)),
        isMyActivity: false,
        category: 'Product Demo',
      ),
    ];
  }
}
