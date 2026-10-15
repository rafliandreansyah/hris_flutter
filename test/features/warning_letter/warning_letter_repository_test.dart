import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/warning_letter/data/datasources/warning_letter_remote_datasource.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/data/repositories/warning_letter_repository_impl.dart';

class _MockWarningLetterRemoteDataSource implements WarningLetterRemoteDataSource {
  int getWarningLettersCallCount = 0;
  int getWarningLetterTypesCallCount = 0;
  int getLastWarningLetterCallCount = 0;
  int createWarningLetterCallCount = 0;
  int getWarningLetterDetailCallCount = 0;

  dynamic mockLettersResult;
  List<WarningLetterTypeModel> mockTypesResult = [];
  LastWarningLetterModel? mockLastLetterResult;
  dynamic mockCreateResult;
  dynamic mockDetailResult;

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
    getWarningLettersCallCount++;
    return mockLettersResult as WarningLetterListResponse;
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async {
    getWarningLetterTypesCallCount++;
    return mockTypesResult;
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async {
    getLastWarningLetterCallCount++;
    return mockLastLetterResult;
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    createWarningLetterCallCount++;
    return mockCreateResult as CreateWarningLetterResponse;
  }

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    getWarningLetterDetailCallCount++;
    return mockDetailResult as WarningLetterDetail;
  }
}

void main() {
  group('WarningLetterRepositoryImpl Tests', () {
    late _MockWarningLetterRemoteDataSource mockRemoteDataSource;
    late WarningLetterRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockWarningLetterRemoteDataSource();
      repository = WarningLetterRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getWarningLetters delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockLettersResult = WarningLetterListResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'wl-1',
            'warningLetterType': {
              'level': 1,
              'name': 'SP 1',
            },
            'isActive': true,
            'createdAt': '2026-10-01T08:00:00Z',
            'timezone': 'WIB',
          }
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getWarningLetters(
        page: 1,
        size: 10,
        approver: false,
      );

      expect(mockRemoteDataSource.getWarningLettersCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('wl-1'));
    });

    test('getWarningLetterTypes delegates to remote data source', () async {
      mockRemoteDataSource.mockTypesResult = [
        const WarningLetterTypeModel(
          id: 't-1',
          name: 'SP 1',
          level: 1,
          validityPeriodMonths: 6,
        ),
      ];

      final result = await repository.getWarningLetterTypes();

      expect(mockRemoteDataSource.getWarningLetterTypesCallCount, equals(1));
      expect(result.length, equals(1));
      expect(result.first.name, equals('SP 1'));
    });

    test('getLastWarningLetter delegates to remote data source', () async {
      mockRemoteDataSource.mockLastLetterResult = LastWarningLetterModel.fromJson({
        'id': 'wl-prev-1',
        'referenceNumber': 'SP/001',
        'issuedDate': '2026-05-01',
        'status': 'active',
        'warningLetterType': {
          'id': 'wl-t-1',
          'name': 'SP 1',
          'level': 1,
        },
      });

      final result = await repository.getLastWarningLetter('emp-1');

      expect(mockRemoteDataSource.getLastWarningLetterCallCount, equals(1));
      expect(result?.referenceNumber, equals('SP/001'));
    });

    test('createWarningLetter delegates to remote data source', () async {
      mockRemoteDataSource.mockCreateResult = const CreateWarningLetterResponse(
        success: true,
        message: 'Diterbitkan',
        data: CreateWarningLetterResponseData(
          id: 'new-id',
          referenceNumber: 'SP/2026/01',
        ),
      );

      const request = CreateWarningLetterRequest(
        employeeId: 'emp-1',
        warningLetterTypeId: 't-1',
        reason: 'Pelanggaran SOP',
        issuedDate: '2026-10-15',
      );

      final result = await repository.createWarningLetter(request);

      expect(mockRemoteDataSource.createWarningLetterCallCount, equals(1));
      expect(result.success, isTrue);
      expect(result.data?.referenceNumber, equals('SP/2026/01'));
    });

    test('getWarningLetterDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockDetailResult = WarningLetterDetail.fromJson({
        'id': 'wl-1',
        'referenceNumber': 'SP/001',
        'infractionReason': 'Terlambat',
        'issuedDate': '2026-10-01',
        'expiredDate': '2027-04-01',
        'warningLetterType': {
          'level': 1,
          'name': 'SP 1',
        },
      });

      final result = await repository.getWarningLetterDetail('wl-1');

      expect(mockRemoteDataSource.getWarningLetterDetailCallCount, equals(1));
      expect(result.id, equals('wl-1'));
      expect(result.referenceNumber, equals('SP/001'));
    });
  });
}
