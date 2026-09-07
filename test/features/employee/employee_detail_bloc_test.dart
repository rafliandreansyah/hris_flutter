import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_detail/employee_detail_bloc.dart';

class MockEmployeeDetailRepository implements EmployeeRepository {
  EmployeeDetailData? mockDetail;
  String? lastRequestedId;
  bool shouldThrow = false;

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
    lastRequestedId = employeeId;
    if (shouldThrow) {
      throw Exception('Server error 500');
    }
    return mockDetail ??
        EmployeeDetailData(
          id: employeeId,
          firstName: 'Alice',
          email: 'alice@example.com',
          status: true,
        );
  }
}

void main() {
  group('EmployeeDetailBloc Unit Tests', () {
    late MockEmployeeDetailRepository mockRepo;

    setUp(() {
      mockRepo = MockEmployeeDetailRepository();
    });

    test('Initial state is correct', () {
      final bloc = EmployeeDetailBloc(repository: mockRepo);
      expect(bloc.state.status, EmployeeDetailStatus.initial);
      expect(bloc.state.detail, isNull);
      expect(bloc.state.isLoading, isFalse);
      bloc.close();
    });

    test('EmployeeDetailStarted with employeeId fetches detail successfully', () async {
      final bloc = EmployeeDetailBloc(repository: mockRepo);

      bloc.add(const EmployeeDetailStarted(employeeId: 'emp-101'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeDetailState>((s) => s.status == EmployeeDetailStatus.loading),
          predicate<EmployeeDetailState>((s) =>
              s.status == EmployeeDetailStatus.success &&
              s.detail?.id == 'emp-101' &&
              s.detail?.firstName == 'Alice'),
        ]),
      );

      expect(mockRepo.lastRequestedId, 'emp-101');
      bloc.close();
    });

    test('EmployeeDetailStarted with EmployeeDirectoryItem uses rawId or id', () async {
      final bloc = EmployeeDetailBloc(repository: mockRepo);
      const item = EmployeeDirectoryItem(
        id: 'dir-1',
        rawId: 'raw-uuid-1',
        name: 'Bob',
        role: 'PM',
        department: 'Product',
        email: 'bob@example.com',
        initials: 'B',
      );

      bloc.add(const EmployeeDetailStarted(employee: item));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeDetailState>((s) => s.status == EmployeeDetailStatus.loading),
          predicate<EmployeeDetailState>((s) =>
              s.status == EmployeeDetailStatus.success &&
              s.detail?.id == 'raw-uuid-1'),
        ]),
      );

      expect(mockRepo.lastRequestedId, 'raw-uuid-1');
      bloc.close();
    });

    test('EmployeeDetailRefreshed re-fetches the current detail', () async {
      final bloc = EmployeeDetailBloc(repository: mockRepo);

      bloc.add(const EmployeeDetailStarted(employeeId: 'emp-202'));
      await bloc.stream.firstWhere((s) => s.status == EmployeeDetailStatus.success);

      bloc.add(const EmployeeDetailRefreshed());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeDetailState>((s) => s.status == EmployeeDetailStatus.loading),
          predicate<EmployeeDetailState>((s) => s.status == EmployeeDetailStatus.success),
        ]),
      );

      expect(mockRepo.lastRequestedId, 'emp-202');
      bloc.close();
    });

    test('Repository exception causes failure status with error message', () async {
      mockRepo.shouldThrow = true;
      final bloc = EmployeeDetailBloc(repository: mockRepo);

      bloc.add(const EmployeeDetailStarted(employeeId: 'emp-err'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeDetailState>((s) => s.status == EmployeeDetailStatus.loading),
          predicate<EmployeeDetailState>((s) =>
              s.status == EmployeeDetailStatus.failure &&
              s.errorMessage != null),
        ]),
      );
      bloc.close();
    });
  });
}
