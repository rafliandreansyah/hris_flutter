import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';

class _MockOrgRepository implements OrganizationFilterRepository {
  int companiesCallCount = 0;
  int departmentsCallCount = 0;
  int positionsCallCount = 0;

  bool shouldThrow = false;

  final sampleCompanies = const [
    CompanyItem(id: 'c1', name: 'PT Oasish Tech Nusantara'),
    CompanyItem(id: 'c2', name: 'PT Oasish Distribusi Digital'),
  ];

  final sampleDepartments = const [
    DepartmentItem(id: 'd1', name: 'Engineering', companyId: 'c1'),
    DepartmentItem(id: 'd2', name: 'Operations', companyId: 'c1'),
  ];

  final samplePositions = const [
    PositionItem(id: 'p1', name: 'Frontend Engineer', companyId: 'c1', departmentId: 'd1'),
    PositionItem(id: 'p2', name: 'Backend Engineer', companyId: 'c1', departmentId: 'd1'),
  ];

  @override
  Future<List<CompanyItem>> getCompanies({String? search}) async {
    companiesCallCount++;
    if (shouldThrow) throw Exception('API Error');
    return sampleCompanies;
  }

  @override
  Future<List<DepartmentItem>> getDepartments({String? companyId, String? search}) async {
    departmentsCallCount++;
    if (shouldThrow) throw Exception('API Error');
    return sampleDepartments;
  }

  @override
  Future<List<PositionItem>> getPositions({String? companyId, String? departmentId, String? search}) async {
    positionsCallCount++;
    if (shouldThrow) throw Exception('API Error');
    return samplePositions;
  }
}

void main() {
  group('OrganizationFilterBloc Unit Tests', () {
    late _MockOrgRepository repository;
    late OrganizationFilterBloc bloc;

    setUp(() {
      repository = _MockOrgRepository();
      bloc = OrganizationFilterBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is OrganizationFilterStatus.initial and empty', () {
      expect(bloc.state.status, OrganizationFilterStatus.initial);
      expect(bloc.state.companies, isEmpty);
      expect(bloc.state.departments, isEmpty);
      expect(bloc.state.positions, isEmpty);
    });

    test('OrganizationFilterStarted loads companies and updates status to loaded', () async {
      bloc.add(const OrganizationFilterStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OrganizationFilterState>()
              .having((s) => s.status, 'status', OrganizationFilterStatus.loadingCompanies),
          isA<OrganizationFilterState>()
              .having((s) => s.status, 'status', OrganizationFilterStatus.loaded)
              .having((s) => s.companies.length, 'companies.length', 2),
        ]),
      );

      expect(repository.companiesCallCount, 1);

      // Calling started again without forceRefresh should NOT trigger another call
      bloc.add(const OrganizationFilterStarted());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repository.companiesCallCount, 1);
    });

    test('OrganizationFilterCompanySelected fetches and caches departments & positions', () async {
      bloc.add(const OrganizationFilterCompanySelected(companyId: 'c1'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OrganizationFilterState>()
              .having((s) => s.selectedCompanyId, 'companyId', 'c1'),
          isA<OrganizationFilterState>()
              .having((s) => s.status, 'status', OrganizationFilterStatus.loadingChildren),
          isA<OrganizationFilterState>()
              .having((s) => s.status, 'status', OrganizationFilterStatus.loaded)
              .having((s) => s.departments.length, 'departments.length', 2)
              .having((s) => s.positions.length, 'positions.length', 2)
              .having((s) => s.cachedDepartmentsByCompany.containsKey('c1'), 'cachedDepts', true)
              .having((s) => s.cachedPositionsByCompany.containsKey('c1'), 'cachedPos', true),
        ]),
      );

      expect(repository.departmentsCallCount, 1);
      expect(repository.positionsCallCount, 1);

      // Selecting the same company again uses the cache directly without hitting repo
      bloc.add(const OrganizationFilterCompanySelected(companyId: 'c1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.departmentsCallCount, 1);
      expect(repository.positionsCallCount, 1);
    });

    test('Clearing selected company clears departments and positions', () async {
      bloc.add(const OrganizationFilterCompanySelected(companyId: 'c1'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const OrganizationFilterCompanySelected(companyId: ''));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.selectedCompanyId, isNull);
      expect(bloc.state.departments, isEmpty);
      expect(bloc.state.positions, isEmpty);
    });

    test('Repository failure emits failure status with errorMessage', () async {
      repository.shouldThrow = true;
      bloc.add(const OrganizationFilterStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OrganizationFilterState>()
              .having((s) => s.status, 'status', OrganizationFilterStatus.loadingCompanies),
          isA<OrganizationFilterState>()
              .having((s) => s.status, 'status', OrganizationFilterStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', contains('API Error')),
        ]),
      );
    });
  });
}
