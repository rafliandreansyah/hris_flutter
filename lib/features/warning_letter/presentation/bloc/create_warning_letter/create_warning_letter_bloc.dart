import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/data/repositories/warning_letter_repository_impl.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/create_warning_letter/create_warning_letter_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/create_warning_letter/create_warning_letter_state.dart';

export 'create_warning_letter_event.dart';
export 'create_warning_letter_state.dart';

class CreateWarningLetterBloc
    extends Bloc<CreateWarningLetterEvent, CreateWarningLetterState> {
  final WarningLetterRepository _warningLetterRepository;
  final EmployeeRepository _employeeRepository;

  CreateWarningLetterBloc({
    WarningLetterRepository? warningLetterRepository,
    EmployeeRepository? employeeRepository,
  })  : _warningLetterRepository =
            warningLetterRepository ?? WarningLetterRepositoryImpl(),
        _employeeRepository =
            employeeRepository ?? EmployeeRepositoryImpl(),
        super(CreateWarningLetterState()) {
    on<CreateWarningLetterStarted>(_onStarted);
    on<CreateWarningLetterEmployeeSelected>(_onEmployeeSelected);
    on<CreateWarningLetterTypeSelected>(_onTypeSelected);
    on<CreateWarningLetterIssuedDateChanged>(_onIssuedDateChanged);
    on<CreateWarningLetterReasonChanged>(_onReasonChanged);
    on<CreateWarningLetterSanctionChanged>(_onSanctionChanged);
    on<CreateWarningLetterFileChanged>(_onFileChanged);
    on<CreateWarningLetterSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateWarningLetterStarted event,
    Emitter<CreateWarningLetterState> emit,
  ) async {
    emit(state.copyWith(status: CreateWarningLetterStatus.loadingData));
    try {
      final results = await Future.wait([
        _warningLetterRepository.getWarningLetterTypes(),
        _employeeRepository.getEmployees(page: 1, size: 100),
      ]);

      final types = results[0] as List<dynamic>;
      final employeesResponse = results[1] as dynamic;

      final typedTypes = types.cast<WarningLetterTypeModel>();
      emit(state.copyWith(
        status: CreateWarningLetterStatus.dataLoaded,
        warningLetterTypes: typedTypes,
        employees: employeesResponse.data,
        selectedType: state.selectedType ??
            (typedTypes.isNotEmpty ? typedTypes.first : null),
      ));
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(
        status: CreateWarningLetterStatus.failure,
        errorMessage: errorMsg,
      ));
    }
  }

  Future<void> _onEmployeeSelected(
    CreateWarningLetterEmployeeSelected event,
    Emitter<CreateWarningLetterState> emit,
  ) async {
    emit(state.copyWith(
      selectedEmployee: event.employee,
      isLoadingLastLetter: true,
      hasLoadedLastLetter: false,
      clearLastWarningLetter: true,
    ));

    try {
      final lastLetter = await _warningLetterRepository.getLastWarningLetter(
        event.employee.id,
      );
      emit(state.copyWith(
        isLoadingLastLetter: false,
        hasLoadedLastLetter: true,
        lastWarningLetter: lastLetter,
      ));
    } catch (e) {
      // Jika terjadi error saat memuat last letter, tetap izinkan proses form berlanjut
      emit(state.copyWith(
        isLoadingLastLetter: false,
        hasLoadedLastLetter: true,
        clearLastWarningLetter: true,
      ));
    }
  }

  void _onTypeSelected(
    CreateWarningLetterTypeSelected event,
    Emitter<CreateWarningLetterState> emit,
  ) {
    emit(state.copyWith(selectedType: event.type));
  }

  void _onIssuedDateChanged(
    CreateWarningLetterIssuedDateChanged event,
    Emitter<CreateWarningLetterState> emit,
  ) {
    emit(state.copyWith(issuedDate: event.date));
  }

  void _onReasonChanged(
    CreateWarningLetterReasonChanged event,
    Emitter<CreateWarningLetterState> emit,
  ) {
    emit(state.copyWith(reason: event.reason));
  }

  void _onSanctionChanged(
    CreateWarningLetterSanctionChanged event,
    Emitter<CreateWarningLetterState> emit,
  ) {
    emit(state.copyWith(sanction: event.sanction));
  }

  void _onFileChanged(
    CreateWarningLetterFileChanged event,
    Emitter<CreateWarningLetterState> emit,
  ) {
    emit(state.copyWith(
      attachmentFile: event.file,
      clearAttachmentFile: event.file == null,
      compressResult: event.compressResult,
      clearCompressResult: event.compressResult == null,
    ));
  }

  Future<void> _onSubmitted(
    CreateWarningLetterSubmitted event,
    Emitter<CreateWarningLetterState> emit,
  ) async {
    if (state.selectedEmployee == null) {
      emit(state.copyWith(
        status: CreateWarningLetterStatus.failure,
        errorMessage: 'Silakan pilih pegawai terlebih dahulu.',
      ));
      return;
    }

    if (state.selectedType == null) {
      emit(state.copyWith(
        status: CreateWarningLetterStatus.failure,
        errorMessage: 'Silakan pilih tipe surat peringatan.',
      ));
      return;
    }

    if (state.reason.trim().isEmpty) {
      emit(state.copyWith(
        status: CreateWarningLetterStatus.failure,
        errorMessage: 'Alasan pelanggaran wajib diisi.',
      ));
      return;
    }

    emit(state.copyWith(
      status: CreateWarningLetterStatus.submitting,
      clearErrorMessage: true,
    ));

    try {
      final request = CreateWarningLetterRequest(
        employeeId: state.selectedEmployee!.id,
        warningLetterTypeId: state.selectedType!.id,
        reason: state.reason.trim(),
        issuedDate: state.formattedIssuedDateParam,
        sanction: state.sanction.trim().isNotEmpty
            ? state.sanction.trim()
            : null,
        file: state.attachmentFile,
      );

      final response = await _warningLetterRepository.createWarningLetter(request);

      emit(state.copyWith(
        status: CreateWarningLetterStatus.success,
        createdResponse: response,
      ));
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(
        status: CreateWarningLetterStatus.failure,
        errorMessage: errorMsg,
      ));
    }
  }
}
