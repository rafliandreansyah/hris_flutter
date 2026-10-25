import 'package:equatable/equatable.dart';

/// Jenis pengajuan yang punya batas rentang tanggal (sama dengan kunci `dateWindows` di API).
enum SubmissionWindowType {
  scheduledAttendance('scheduled_attendance'),
  leave('leave'),
  overtime('overtime'),
  reimbursement('reimbursement'),
  cashAdvance('cash_advance'),
  resignation('resignation');

  const SubmissionWindowType(this.key);
  final String key;
}

/// Rentang tanggal yang boleh dipilih untuk satu jenis pengajuan.
/// [minDate] / [maxDate] null berarti bebas (tidak dibatasi perusahaan).
class DateWindowModel extends Equatable {
  final bool isUnlimited;
  final int daysBefore;
  final int daysAfter;
  final DateTime? minDate;
  final DateTime? maxDate;

  const DateWindowModel({
    this.isUnlimited = true,
    this.daysBefore = 14,
    this.daysAfter = 14,
    this.minDate,
    this.maxDate,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final parts = v.toString().split('T').first.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  factory DateWindowModel.fromJson(Map<String, dynamic> json) {
    return DateWindowModel(
      isUnlimited: json['isUnlimited'] == true,
      daysBefore: (json['daysBefore'] as num?)?.toInt() ?? 14,
      daysAfter: (json['daysAfter'] as num?)?.toInt() ?? 14,
      minDate: _parseDate(json['minDate']),
      maxDate: _parseDate(json['maxDate']),
    );
  }

  @override
  List<Object?> get props => [isUnlimited, daysBefore, daysAfter, minDate, maxDate];
}

/// Kuota pengajuan presensi terjadwal pada periode berjalan.
class ScheduledQuotaModel extends Equatable {
  final bool enabled;
  final String period; // 'monthly' | 'yearly'
  final int limit;
  final int used;
  final int? remaining;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const ScheduledQuotaModel({
    this.enabled = false,
    this.period = 'monthly',
    this.limit = 0,
    this.used = 0,
    this.remaining,
    this.periodStart,
    this.periodEnd,
  });

  bool get isYearly => period == 'yearly';

  /// True bila kuota aktif dan sudah habis.
  bool get isExhausted => enabled && (remaining ?? 0) <= 0;

  factory ScheduledQuotaModel.fromJson(Map<String, dynamic> json) {
    return ScheduledQuotaModel(
      enabled: json['enabled'] == true,
      period: json['period']?.toString() ?? 'monthly',
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt(),
      periodStart: DateWindowModel._parseDate(json['periodStart']),
      periodEnd: DateWindowModel._parseDate(json['periodEnd']),
    );
  }

  @override
  List<Object?> get props => [enabled, period, limit, used, remaining, periodStart, periodEnd];
}

/// Respons GET /submission-settings
class SubmissionSettingModel extends Equatable {
  /// Menu Presensi Langsung / Terjadwal diatur terpisah per perusahaan (CompanyMenu).
  final bool isLiveEnabled;
  final bool isScheduledEnabled;
  final ScheduledQuotaModel scheduledQuota;
  final Map<String, DateWindowModel> dateWindows;
  final String timezone;

  const SubmissionSettingModel({
    this.isLiveEnabled = true,
    this.isScheduledEnabled = true,
    this.scheduledQuota = const ScheduledQuotaModel(),
    this.dateWindows = const {},
    this.timezone = 'Asia/Jakarta',
  });

  DateWindowModel? windowFor(SubmissionWindowType type) => dateWindows[type.key];

  factory SubmissionSettingModel.fromJson(Map<String, dynamic> json) {
    final attendance = json['attendance'];
    final quotaJson = attendance is Map<String, dynamic> ? attendance['scheduledQuota'] : null;
    final windowsJson = json['dateWindows'];
    final att = attendance is Map<String, dynamic> ? attendance : const <String, dynamic>{};
    return SubmissionSettingModel(
      isLiveEnabled: att['isLiveEnabled'] != false,
      isScheduledEnabled: att['isScheduledEnabled'] != false,
      scheduledQuota: quotaJson is Map<String, dynamic>
          ? ScheduledQuotaModel.fromJson(quotaJson)
          : const ScheduledQuotaModel(),
      dateWindows: windowsJson is Map<String, dynamic>
          ? {
              for (final e in windowsJson.entries)
                if (e.value is Map<String, dynamic>)
                  e.key: DateWindowModel.fromJson(e.value as Map<String, dynamic>),
            }
          : const {},
      timezone: json['timezone']?.toString() ?? 'Asia/Jakarta',
    );
  }

  @override
  List<Object?> get props => [isLiveEnabled, isScheduledEnabled, scheduledQuota, dateWindows, timezone];
}
