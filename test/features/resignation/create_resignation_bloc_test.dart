import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_state.dart';

class _MockResignationRepository implements ResignationRepository {
  ResignationInitialFormModel? mockInitialForm;
  bool shouldThrowError = false;
  String errorMessage = 'Server error';
  SubmitResignationRequestModel? lastSubmittedRequest;

  @override
  Future<ResignationInitialFormModel> getInitialFormData() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockInitialForm ??
        const ResignationInitialFormModel(
          companyPolicy: ResignationCompanyPolicyModel(
            effectiveNoticePeriodDays: 30,
          ),
          employee: ResignationFormEmployeeModel(
            id: 'emp-1',
            name: 'John Doe',
            remainingLeaveDays: 8,
          ),
          minSuggestedDate: '2026-10-31',
          colleagues: [
            ResignationColleagueModel(
              id: 'colleague-1',
              name: 'Ahmad Fauzi',
              positionName: 'Senior Developer',
              departmentName: 'IT',
            ),
          ],
        );
  }

  @override
  Future<void> submitResignation(SubmitResignationRequestModel request) async {
    lastSubmittedRequest = request;
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
  }

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<void> cancelMyResignation() async {
    throw UnimplementedError();
  }

  @override
  Future<ResignationDetailModel> getResignationDetail(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  group('CreateResignationBloc Tests', () {
    late _MockResignationRepository repository;
    late CreateResignationBloc bloc;

    setUp(() {
      repository = _MockResignationRepository();
      bloc = CreateResignationBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state contains default properties', () {
      expect(bloc.state.status, CreateResignationStatus.initial);
      expect(bloc.state.selectedCategory, 'career_advancement');
      expect(bloc.state.isEarlyNotice, false);
      expect(bloc.state.isAgreed, false);
      expect(bloc.state.canSubmit, false);
    });

    test('CreateResignationStarted emits loading then initialLoaded on success',
        () async {
      bloc.add(const CreateResignationStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateResignationState>(
            (s) => s.status == CreateResignationStatus.loadingInitial,
          ),
          predicate<CreateResignationState>(
            (s) =>
                s.status == CreateResignationStatus.initialLoaded &&
                s.initialData?.employee.name == 'John Doe' &&
                s.selectedEffectiveDate == DateTime.parse('2026-10-31'),
          ),
        ]),
      );
    });

    test('CreateResignationStarted emits loading then failure on error',
        () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Gagal memuat aturan notice.';

      bloc.add(const CreateResignationStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateResignationState>(
            (s) => s.status == CreateResignationStatus.loadingInitial,
          ),
          predicate<CreateResignationState>(
            (s) =>
                s.status == CreateResignationStatus.failure &&
                s.errorMessage == 'Gagal memuat aturan notice.',
          ),
        ]),
      );
    });

    test('Form field events update state correctly', () async {
      bloc.add(CreateResignationDateChanged(DateTime(2026, 11, 1)));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.selectedEffectiveDate == DateTime(2026, 11, 1),
          ),
        ),
      );

      bloc.add(const CreateResignationCategoryChanged('relocation'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.selectedCategory == 'relocation',
          ),
        ),
      );

      bloc.add(const CreateResignationReasonNotesChanged('Pindah domisili'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.reasonNotes == 'Pindah domisili',
          ),
        ),
      );

      bloc.add(const CreateResignationEarlyWaiverToggled(true));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.isEarlyNotice == true,
          ),
        ),
      );

      bloc.add(const CreateResignationEarlyReasonChanged('Alasan mendesak'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.earlyNoticeReason == 'Alasan mendesak',
          ),
        ),
      );

      const colleague = ResignationColleagueModel(
        id: 'colleague-1',
        name: 'Ahmad Fauzi',
      );
      bloc.add(const CreateResignationColleagueSelected(colleague));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.selectedColleague?.name == 'Ahmad Fauzi',
          ),
        ),
      );

      bloc.add(const CreateResignationHandoverNotesChanged('Handover note'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.handoverNotes == 'Handover note',
          ),
        ),
      );

      bloc.add(const CreateResignationAgreementToggled(true));
      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) => s.isAgreed == true,
          ),
        ),
      );
    });

    test('CreateResignationSubmitted emits failure when form is incomplete',
        () async {
      bloc.add(const CreateResignationSubmitted());

      await expectLater(
        bloc.stream,
        emits(
          predicate<CreateResignationState>(
            (s) =>
                s.status == CreateResignationStatus.failure &&
                s.errorMessage == 'Harap lengkapi semua kolom wajib.',
          ),
        ),
      );
    });

    test('CreateResignationSubmitted emits submitting then success when valid',
        () async {
      // First populate valid data
      bloc.add(CreateResignationDateChanged(
        DateTime.now().add(const Duration(days: 35)),
      ));
      bloc.add(const CreateResignationCategoryChanged('career_advancement'));
      bloc.add(const CreateResignationReasonNotesChanged(
        'Melanjutkan karir ke jenjang yang lebih tinggi',
      ));
      bloc.add(const CreateResignationAgreementToggled(true));

      // Wait for state updates
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const CreateResignationSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateResignationState>(
            (s) => s.status == CreateResignationStatus.submitting,
          ),
          predicate<CreateResignationState>(
            (s) => s.status == CreateResignationStatus.success,
          ),
        ]),
      );

      expect(repository.lastSubmittedRequest?.reasonCategory,
          'career_advancement');
      expect(repository.lastSubmittedRequest?.reasonNotes,
          'Melanjutkan karir ke jenjang yang lebih tinggi');
    });

    test('CreateResignationSubmitted emits failure on api exception', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Pengajuan aktif sudah ada.';

      bloc.add(CreateResignationDateChanged(
        DateTime.now().add(const Duration(days: 35)),
      ));
      bloc.add(const CreateResignationCategoryChanged('career_advancement'));
      bloc.add(const CreateResignationReasonNotesChanged('Alasan'));
      bloc.add(const CreateResignationAgreementToggled(true));

      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const CreateResignationSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateResignationState>(
            (s) => s.status == CreateResignationStatus.submitting,
          ),
          predicate<CreateResignationState>(
            (s) =>
                s.status == CreateResignationStatus.failure &&
                s.errorMessage == 'Pengajuan aktif sudah ada.',
          ),
        ]),
      );
    });
  });
}
