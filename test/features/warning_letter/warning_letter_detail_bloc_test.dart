import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_bloc.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_state.dart';

class _MockDetailRepo implements WarningLetterRepository {
  WarningLetterDetail? detailToReturn;
  Exception? exceptionToThrow;

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return detailToReturn ??
        const WarningLetterDetail(
          id: 'wl-default-1',
          warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
          timezone: 'WIB',
          isActive: true,
          createdAt: null,
          issuedDate: null,
          expiredDate: null,
        );
  }

  @override
  Future<WarningLetterListResponse> getWarningLetters({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  }) async {
    return const WarningLetterListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: WarningLetterPaginationMeta(
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async => [];

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async =>
      null;

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    return const CreateWarningLetterResponse(success: true, message: 'OK');
  }
}

void main() {
  group('WarningLetterDetailBloc Tests', () {
    late _MockDetailRepo repository;
    late WarningLetterDetailBloc bloc;

    final sampleDetail = WarningLetterDetail(
      id: 'wl-101',
      warningLetterType:
          const WarningLetterTypeSummary(level: 1, name: 'Surat Peringatan 1'),
      referenceNumber: 'SP/2026/08/0019',
      attachmentUrl: 'https://example.com/sp.pdf',
      infractionReason: 'Indisipliner Keterlambatan',
      sanction: 'Teguran Tertulis',
      employee: const WarningLetterEmployee(
        id: 'emp-1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
      ),
      issuedDate: DateTime(2026, 8, 29),
      expiredDate: DateTime(2027, 2, 28),
      timezone: 'WIB',
      isActive: true,
      issuedByEmployee: const WarningLetterEmployee(
        id: 'emp-2',
        firstName: 'Alex',
        lastName: 'Rivera',
      ),
      createdAt: DateTime(2026, 8, 29, 12, 47),
    );

    setUp(() {
      repository = _MockDetailRepo();
      bloc = WarningLetterDetailBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is WarningLetterDetailInitial', () {
      expect(bloc.state, const WarningLetterDetailInitial());
    });

    test('FetchWarningLetterDetail emits loading and loaded on success', () async {
      repository.detailToReturn = sampleDetail;

      final expected = [
        const WarningLetterDetailLoading(),
        WarningLetterDetailLoaded(sampleDetail),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const FetchWarningLetterDetail('wl-101'));
    });

    test('FetchWarningLetterDetail emits loading and error on ApiException',
        () async {
      repository.exceptionToThrow = const ApiException(
        message: 'Surat peringatan tidak ditemukan',
        statusCode: 404,
      );

      final expected = [
        const WarningLetterDetailLoading(),
        const WarningLetterDetailError(
          message: 'Surat peringatan tidak ditemukan',
          statusCode: 404,
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const FetchWarningLetterDetail('wl-nonexistent'));
    });

    test('FetchWarningLetterDetail emits loading and error on generic Exception',
        () async {
      repository.exceptionToThrow = Exception('Network timeout');

      final expected = [
        const WarningLetterDetailLoading(),
        predicate<WarningLetterDetailState>((state) {
          return state is WarningLetterDetailError &&
              state.message.contains('Network timeout');
        }),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const FetchWarningLetterDetail('wl-101'));
    });

    test('RefreshWarningLetterDetail refetches and updates loaded state',
        () async {
      repository.detailToReturn = sampleDetail;

      bloc.add(const FetchWarningLetterDetail('wl-101'));
      await expectLater(
        bloc.stream,
        emitsThrough(WarningLetterDetailLoaded(sampleDetail)),
      );

      final updatedDetail = WarningLetterDetail(
        id: 'wl-101',
        warningLetterType: const WarningLetterTypeSummary(
          level: 1,
          name: 'Surat Peringatan 1',
        ),
        referenceNumber: 'SP/2026/08/0019',
        attachmentUrl: 'https://example.com/sp-v2.pdf',
        infractionReason: 'Indisipliner Diperbarui',
        timezone: 'WIB',
        isActive: false,
        createdAt: DateTime(2026, 8, 29, 12, 47),
      );
      repository.detailToReturn = updatedDetail;

      expectLater(
        bloc.stream,
        emits(WarningLetterDetailLoaded(updatedDetail)),
      );

      bloc.add(const RefreshWarningLetterDetail());
    });
  });
}
