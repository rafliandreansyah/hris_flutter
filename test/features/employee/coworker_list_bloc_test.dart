import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/coworker_list/coworker_list_bloc.dart';

class MockCoworkerRepository implements EmployeeRepository {
  List<EmployeeDirectoryItem> mockCoworkers = [];
  bool shouldThrow = false;
  String? errorMessage;
  int? lastStatusCode;

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    if (shouldThrow) {
      throw ApiException(
        message: errorMessage ?? 'Gagal memuat rekan kerja',
        statusCode: lastStatusCode ?? 500,
      );
    }
    return mockCoworkers;
  }

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    throw UnimplementedError();
  }

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return 'Password berhasil diperbarui';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoworkerListBloc Unit Tests', () {
    late MockCoworkerRepository mockRepo;

    final sampleCoworker1 = const EmployeeDirectoryItem(
      id: 'cw-1',
      name: 'Budi Santoso',
      firstName: 'Budi',
      lastName: 'Santoso',
      role: 'UI/UX Designer',
      department: 'Product & Design',
      email: 'budi.santoso@oasish.com',
      phone: '081234567890',
      employeeNumber: 'EMP-001',
      initials: 'BS',
    );

    final sampleCoworker2 = const EmployeeDirectoryItem(
      id: 'cw-2',
      name: 'Dewi Lestari',
      firstName: 'Dewi',
      lastName: 'Lestari',
      role: 'Frontend Engineer',
      department: 'Engineering',
      email: 'dewi.lestari@oasish.com',
      phone: '081298765432',
      employeeNumber: 'EMP-002',
      initials: 'DL',
    );

    setUp(() {
      mockRepo = MockCoworkerRepository();
    });

    test('Initial state is correct', () {
      final bloc = CoworkerListBloc(repository: mockRepo);
      expect(bloc.state.status, CoworkerListStatus.initial);
      expect(bloc.state.coworkers, isEmpty);
      expect(bloc.state.filteredCoworkers, isEmpty);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.errorMessage, isNull);
      bloc.close();
    });

    test('CoworkerListStarted with initialCoworkers loads immediately without API call', () async {
      final bloc = CoworkerListBloc(repository: mockRepo);

      bloc.add(CoworkerListStarted(initialCoworkers: [sampleCoworker1, sampleCoworker2]));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) =>
              s.status == CoworkerListStatus.success &&
              s.coworkers.length == 2 &&
              s.filteredCoworkers.length == 2 &&
              s.filteredCoworkers.first.name == 'Budi Santoso'),
        ]),
      );

      bloc.close();
    });

    test('CoworkerListStarted without initialCoworkers fetches data from repository', () async {
      mockRepo.mockCoworkers = [sampleCoworker1, sampleCoworker2];
      final bloc = CoworkerListBloc(repository: mockRepo);

      bloc.add(const CoworkerListStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) => s.status == CoworkerListStatus.loading),
          predicate<CoworkerListState>((s) =>
              s.status == CoworkerListStatus.success &&
              s.coworkers.length == 2 &&
              s.filteredCoworkers.length == 2),
        ]),
      );

      bloc.close();
    });

    test('CoworkerListSearchChanged filters coworkers by name, role, and department', () async {
      final bloc = CoworkerListBloc(repository: mockRepo);
      bloc.add(CoworkerListStarted(initialCoworkers: [sampleCoworker1, sampleCoworker2]));
      await bloc.stream.firstWhere((s) => s.status == CoworkerListStatus.success);

      // Search by name "Dewi"
      bloc.add(const CoworkerListSearchChanged('Dewi'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) =>
              s.searchQuery == 'Dewi' &&
              s.filteredCoworkers.length == 1 &&
              s.filteredCoworkers.first.name == 'Dewi Lestari'),
        ]),
      );

      // Search by role "Designer"
      bloc.add(const CoworkerListSearchChanged('Designer'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) =>
              s.searchQuery == 'Designer' &&
              s.filteredCoworkers.length == 1 &&
              s.filteredCoworkers.first.name == 'Budi Santoso'),
        ]),
      );

      // Search by non-matching keyword
      bloc.add(const CoworkerListSearchChanged('Marketing'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) =>
              s.searchQuery == 'Marketing' &&
              s.filteredCoworkers.isEmpty),
        ]),
      );

      // Search cleared
      bloc.add(const CoworkerListSearchChanged(''));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) =>
              s.searchQuery.isEmpty &&
              s.filteredCoworkers.length == 2),
        ]),
      );

      bloc.close();
    });

    test('CoworkerListRefreshed updates the coworker list from repository', () async {
      mockRepo.mockCoworkers = [sampleCoworker1];
      final bloc = CoworkerListBloc(repository: mockRepo);
      bloc.add(const CoworkerListStarted());
      await bloc.stream.firstWhere((s) => s.status == CoworkerListStatus.success);

      expect(bloc.state.coworkers.length, 1);

      // Backend now has 2 coworkers
      mockRepo.mockCoworkers = [sampleCoworker1, sampleCoworker2];
      bloc.add(const CoworkerListRefreshed());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) => s.status == CoworkerListStatus.loading),
          predicate<CoworkerListState>((s) =>
              s.status == CoworkerListStatus.success &&
              s.coworkers.length == 2 &&
              s.filteredCoworkers.length == 2),
        ]),
      );

      bloc.close();
    });

    test('Repository error emits failure status with message', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Terjadi kesalahan pada server';
      final bloc = CoworkerListBloc(repository: mockRepo);

      bloc.add(const CoworkerListStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CoworkerListState>((s) => s.status == CoworkerListStatus.loading),
          predicate<CoworkerListState>((s) =>
              s.status == CoworkerListStatus.failure &&
              s.errorMessage == 'Terjadi kesalahan pada server'),
        ]),
      );

      bloc.close();
    });
  });
}
