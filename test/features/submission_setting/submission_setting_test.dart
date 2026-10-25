import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';
import 'package:hris_flutter/features/submission_setting/domain/repositories/submission_setting_repository.dart';
import 'package:hris_flutter/features/submission_setting/presentation/bloc/submission_setting_cubit.dart';

class _FakeRepo implements SubmissionSettingRepository {
  SubmissionSettingModel? result;
  Object? error;

  @override
  Future<SubmissionSettingModel> getSubmissionSetting() async {
    if (error != null) throw error!;
    return result!;
  }
}

const _json = {
  'attendance': {
    'isLiveEnabled': true,
    'isScheduledEnabled': false,
    'scheduledQuota': {
      'enabled': true,
      'period': 'monthly',
      'limit': 4,
      'used': 4,
      'remaining': 0,
      'periodStart': '2026-10-01',
      'periodEnd': '2026-10-31',
    },
  },
  'dateWindows': {
    'leave': {
      'isUnlimited': false,
      'daysBefore': 14,
      'daysAfter': 14,
      'minDate': '2026-10-11',
      'maxDate': '2026-11-08',
    },
    'overtime': {
      'isUnlimited': true,
      'daysBefore': 14,
      'daysAfter': 14,
      'minDate': null,
      'maxDate': null,
    },
  },
  'timezone': 'Asia/Makassar',
  'today': '2026-10-25',
};

void main() {
  group('SubmissionSettingModel.fromJson', () {
    final model = SubmissionSettingModel.fromJson(Map<String, dynamic>.from(_json));

    test('membaca toggle presensi langsung & terjadwal terpisah', () {
      expect(model.isLiveEnabled, isTrue);
      expect(model.isScheduledEnabled, isFalse);
    });

    test('membaca kuota dan menandai habis', () {
      expect(model.scheduledQuota.enabled, isTrue);
      expect(model.scheduledQuota.isExhausted, isTrue);
      expect(model.scheduledQuota.isYearly, isFalse);
      expect(model.scheduledQuota.periodEnd, DateTime(2026, 10, 31));
    });

    test('membaca jendela tanggal; bebas = tanpa min/max', () {
      final leave = model.windowFor(SubmissionWindowType.leave)!;
      expect(leave.isUnlimited, isFalse);
      expect(leave.minDate, DateTime(2026, 10, 11));
      expect(leave.maxDate, DateTime(2026, 11, 8));

      final overtime = model.windowFor(SubmissionWindowType.overtime)!;
      expect(overtime.isUnlimited, isTrue);
      expect(overtime.minDate, isNull);

      expect(model.windowFor(SubmissionWindowType.resignation), isNull);
      expect(model.timezone, 'Asia/Makassar');
    });

    test('respons kosong memakai default aman (semua aktif, tanpa kuota)', () {
      final empty = SubmissionSettingModel.fromJson(const <String, dynamic>{});
      expect(empty.isLiveEnabled, isTrue);
      expect(empty.isScheduledEnabled, isTrue);
      expect(empty.scheduledQuota.enabled, isFalse);
      expect(empty.scheduledQuota.isExhausted, isFalse);
    });
  });

  group('SubmissionSettingCubit', () {
    final data = SubmissionSettingModel.fromJson(Map<String, dynamic>.from(_json));

    test('load sukses: loading lalu loaded', () async {
      final cubit = SubmissionSettingCubit(repository: _FakeRepo()..result = data);
      final states = <SubmissionSettingState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        const SubmissionSettingState(status: SubmissionSettingStatus.loading),
        SubmissionSettingState(status: SubmissionSettingStatus.loaded, data: data),
      ]);
      await sub.cancel();
      await cubit.close();
    });

    test('load gagal: pesan API dipertahankan dan data lama tidak hilang', () async {
      final repo = _FakeRepo()..result = data;
      final cubit = SubmissionSettingCubit(repository: repo);
      await cubit.load();

      repo.error = const ApiException(message: 'Gagal', statusCode: 500);
      final states = <SubmissionSettingState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, SubmissionSettingStatus.failure);
      expect(states.last.message, 'Gagal');
      expect(states.last.data, data); // batas terakhir yang diketahui tetap dipakai form
      await sub.cancel();
      await cubit.close();
    });
  });
}
