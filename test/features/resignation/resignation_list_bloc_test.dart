import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_state.dart';
import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_event.dart';

class _MockResignationRepository implements ResignationRepository {
  MyResignationStatusModel? mockMyStatus;
  SubordinateResignationResponseModel? mockSubordinates;
  bool shouldThrowError = false;
  String errorMessage = 'Internal Server Error';
  bool cancelCalled = false;

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockMyStatus ??
        const MyResignationStatusModel(
          hasActiveResignation: false,
          daysRemaining: 0,
        );
  }

  @override
  Future<SubordinateResignationResponseModel> getSubordinateResignations({
    String status = 'pending',
    int page = 1,
    int size = 10,
    String? search,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? startDate,
    String? endDate,
  }) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockSubordinates ??
        const SubordinateResignationResponseModel(
          success: true,
          message: 'OK',
          data: [],
          meta: ResignationPaginationMeta(
            page: 1,
            size: 10,
            total: 0,
            totalPages: 1,
          ),
        );
  }

  @override
  Future<void> cancelMyResignation() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    cancelCalled = true;
  }


  @override
  Future<ResignationInitialFormModel> getInitialFormData() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return const ResignationInitialFormModel(
      companyPolicy: ResignationCompanyPolicyModel(defaultNoticePeriodDays: 30),
      employee: ResignationFormEmployeeModel(id: 'emp-1', name: 'John'),
      minSuggestedDate: '2026-10-31',
      colleagues: [],
    );
  }

  @override
  Future<void> submitResignation(SubmitResignationRequestModel request) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
  }

  final List<Map<String, Object?>> reviewCalls = [];
  ExitInterviewRequestModel? lastExitInterview;

  @override
  Future<void> approveSubordinateResignation(
    String id, {
    required String managerNotes,
    bool approveEarlyNotice = true,
  }) async {
    reviewCalls.add({
      'action': 'approve',
      'id': id,
      'notes': managerNotes,
      'approveEarlyNotice': approveEarlyNotice,
    });
    if (shouldThrowError) throw ApiException(message: errorMessage);
  }

  @override
  Future<void> rejectSubordinateResignation(
    String id, {
    required String rejectionReason,
  }) async {
    reviewCalls.add({'action': 'reject', 'id': id, 'notes': rejectionReason});
    if (shouldThrowError) throw ApiException(message: errorMessage);
  }

  @override
  Future<void> submitExitInterview(ExitInterviewRequestModel request) async {
    lastExitInterview = request;
    if (shouldThrowError) throw ApiException(message: errorMessage);
  }
}

void main() {
  late _MockResignationRepository repository;
  late ResignationListBloc bloc;

  setUp(() {
    repository = _MockResignationRepository();
    bloc = ResignationListBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ResignationListBloc Tests', () {
    test('Initial state contains default properties', () {
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.isMyStatusLoading, false);
      expect(bloc.state.myStatus, isNull);
      expect(bloc.state.hasActiveResignation, false);
      expect(bloc.state.subordinates, isEmpty);
      expect(bloc.state.subordinatesStatusFilter, 'pending');
    });

    test('TabChanged event updates currentTabIndex', () async {
      bloc.add(const ResignationListTabChanged(1));
      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>(
          (state) => state.currentTabIndex == 1,
        )),
      );
    });

    test('MyStatusRequested emits loading then success', () async {
      const sampleStatus = MyResignationStatusModel(
        hasActiveResignation: true,
        daysRemaining: 24,
        resignation: ResignationDetailModel(
          id: 'res-1',
          companyId: 'comp-1',
          employeeId: 'emp-1',
          status: 'manager_approved',
          reason: 'Mendapat karir baru',
        ),
      );
      repository.mockMyStatus = sampleStatus;

      bloc.add(const ResignationListMyStatusRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isMyStatusLoading == true),
          predicate<dynamic>((s) =>
              s.isMyStatusLoading == false &&
              s.hasActiveResignation == true &&
              s.myStatus?.daysRemaining == 24),
        ]),
      );
    });

    test('MyStatusRequested handles ApiException failure', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Network connection lost';

      bloc.add(const ResignationListMyStatusRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isMyStatusLoading == true),
          predicate<dynamic>((s) =>
              s.isMyStatusLoading == false &&
              s.errorMessage == 'Network connection lost'),
        ]),
      );
    });

    test('SubordinatesRequested fetches subordinate resignation list', () async {
      const sampleResponse = SubordinateResignationResponseModel(
        success: true,
        message: 'Success',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-1',
            companyId: 'comp-1',
            employeeId: 'emp-2',
            employeeName: 'Dimas Prasetyo',
            status: 'submitted',
          ),
        ],
        meta: ResignationPaginationMeta(
          page: 1,
          size: 10,
          total: 1,
          totalPages: 1,
        ),
      );
      repository.mockSubordinates = sampleResponse;

      bloc.add(const ResignationListSubordinatesRequested(statusFilter: 'pending'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isSubordinatesLoading == true),
          predicate<dynamic>((s) =>
              s.isSubordinatesLoading == false &&
              s.subordinates.length == 1 &&
              s.subordinates.first.employeeName == 'Dimas Prasetyo'),
        ]),
      );
    });

    test('SubordinatesLoadMore appends next page items', () async {
      const page1 = SubordinateResignationResponseModel(
        success: true,
        message: 'Success',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-1',
            companyId: 'comp-1',
            employeeId: 'emp-1',
            employeeName: 'User 1',
          ),
        ],
        meta: ResignationPaginationMeta(
          page: 1,
          size: 10,
          total: 2,
          totalPages: 2,
        ),
      );
      repository.mockSubordinates = page1;
      bloc.add(const ResignationListSubordinatesRequested());
      await bloc.stream.firstWhere((s) => !s.isSubordinatesLoading);

      const page2 = SubordinateResignationResponseModel(
        success: true,
        message: 'Success',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-2',
            companyId: 'comp-1',
            employeeId: 'emp-2',
            employeeName: 'User 2',
          ),
        ],
        meta: ResignationPaginationMeta(
          page: 2,
          size: 10,
          total: 2,
          totalPages: 2,
        ),
      );
      repository.mockSubordinates = page2;

      bloc.add(const ResignationListSubordinatesLoadMore());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isSubordinatesLoadingMore == true),
          predicate<dynamic>((s) =>
              s.isSubordinatesLoadingMore == false &&
              s.subordinates.length == 2 &&
              s.subordinatesPage == 2),
        ]),
      );
    });

    test('FilterApplied updates filterData and triggers fetch', () async {
      const filter = AppRequestFilterData(company: 'PT Muratech Mandiri');
      bloc.add(const ResignationListFilterApplied(filter));

      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>(
          (s) => s.filterData.company == 'PT Muratech Mandiri',
        )),
      );
    });

    test('CancelRequested invokes cancel repository and emits success', () async {
      bloc.add(const ResignationListCancelRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isCancelling == true),
          predicate<dynamic>((s) => s.isCancelling == false && s.cancelSuccess == true),
          predicate<dynamic>((s) => s.isMyStatusLoading == true),
          predicate<dynamic>((s) => s.isMyStatusLoading == false),
        ]),
      );
      expect(repository.cancelCalled, true);
    });

    test('ResignationListStarted sets canViewSubordinates true when user has approval permission', () async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.approvalResignationManager,
      ]);
      final customBloc = ResignationListBloc(repository: repository);
      customBloc.add(const ResignationListStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(customBloc.state.canViewSubordinates, isTrue);
      customBloc.close();
      SecureStorageService.instance.setPermissionsInMemory([]);
    });

    test('ResignationListStarted sets canViewSubordinates false when user lacks subordinate permission', () async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.resignationCreate,
      ]);
      final customBloc = ResignationListBloc(repository: repository);
      customBloc.add(const ResignationListStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(customBloc.state.canViewSubordinates, isFalse);
      customBloc.close();
      SecureStorageService.instance.setPermissionsInMemory([]);
    });
  });

  group('ResignationListBloc - review atasan & exit interview', () {
    test('menyetujui: memanggil API approve dengan catatan & early notice, lalu sukses', () async {
      bloc.add(const ResignationListSubordinateReviewed(
        id: 'sub-1',
        isApproved: true,
        notes: 'Sudah dibahas 1-on-1',
        approveEarlyNotice: false,
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ResignationListState>((s) => s.isActionSubmitting),
          predicate<ResignationListState>(
            (s) =>
                !s.isActionSubmitting &&
                s.actionSuccessMessage == 'Pengajuan resign disetujui.',
          ),
        ]),
      );

      expect(repository.reviewCalls, [
        {
          'action': 'approve',
          'id': 'sub-1',
          'notes': 'Sudah dibahas 1-on-1',
          'approveEarlyNotice': false,
        },
      ]);
    });

    test('menolak: memanggil API reject dengan alasan', () async {
      bloc.add(const ResignationListSubordinateReviewed(
        id: 'sub-2',
        isApproved: false,
        notes: 'Masih ada proyek kritis',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ResignationListState>(
            (s) => s.actionSuccessMessage == 'Pengajuan resign ditolak.',
          ),
        ),
      );

      expect(repository.reviewCalls.single['action'], 'reject');
      expect(repository.reviewCalls.single['notes'], 'Masih ada proyek kritis');
    });

    test('setelah review sukses daftar bawahan dimuat ulang', () async {
      repository.mockSubordinates = const SubordinateResignationResponseModel(
        success: true,
        message: 'OK',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-1',
            companyId: 'c',
            employeeId: 'e',
            employeeName: 'Dimas',
            status: 'manager_approved',
          ),
        ],
        meta: ResignationPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );

      bloc.add(const ResignationListSubordinateReviewed(
        id: 'sub-1',
        isApproved: true,
        notes: 'Disetujui',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ResignationListState>(
            (s) => s.subordinates.length == 1 && !s.isSubordinatesLoading,
          ),
        ),
      );
    });

    test('error API: pesan backend diteruskan dan tidak ada pesan sukses', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Pengajuan sudah diproses';

      bloc.add(const ResignationListSubordinateReviewed(
        id: 'sub-1',
        isApproved: true,
        notes: 'Setuju',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ResignationListState>((s) => s.isActionSubmitting),
          predicate<ResignationListState>(
            (s) =>
                !s.isActionSubmitting &&
                s.errorMessage == 'Pengajuan sudah diproses' &&
                s.actionSuccessMessage == null,
          ),
        ]),
      );
    });

    test('exit interview: mengirim payload lalu memuat ulang status saya', () async {
      const request = ExitInterviewRequestModel(
        satisfactionCulture: 4,
        reasonFeedback: 'Ingin pindah kota',
        isAnonymous: true,
      );

      bloc.add(const ResignationListExitInterviewSubmitted(request));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ResignationListState>(
            (s) =>
                s.actionSuccessMessage ==
                'Terima kasih, kuesioner exit interview telah dikirim.',
          ),
        ),
      );
      expect(repository.lastExitInterview, request);
    });

    test('exit interview dilewati menampilkan pesan khusus', () async {
      bloc.add(
        const ResignationListExitInterviewSubmitted(
          ExitInterviewRequestModel.skipped(),
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ResignationListState>(
            (s) => s.actionSuccessMessage == 'Exit interview dilewati.',
          ),
        ),
      );
    });
  });
}
