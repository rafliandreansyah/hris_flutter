import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_state.dart';

class CreateReimbursementBloc
    extends Bloc<CreateReimbursementEvent, CreateReimbursementState> {
  final ReimbursementRepository _repository;
  final EmployeeRepository _employeeRepository;
  final AuthLocalDataSource _authLocalDataSource;

  CreateReimbursementBloc({
    ReimbursementRepository? repository,
    EmployeeRepository? employeeRepository,
    AuthLocalDataSource? authLocalDataSource,
  })  : _repository = repository ?? ReimbursementRepositoryImpl(),
        _employeeRepository = employeeRepository ?? EmployeeRepositoryImpl(),
        _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSourceImpl(),
        super(const CreateReimbursementState()) {
    on<CreateReimbursementStarted>(_onStarted);
    on<CreateReimbursementTypeChanged>(_onTypeChanged);
    on<CreateReimbursementCashAdvanceSelected>(_onCashAdvanceSelected);
    on<CreateReimbursementCashAdvanceObjectSelected>(_onCashAdvanceObjectSelected);
    on<CreateReimbursementItemAdded>(_onItemAdded);
    on<CreateReimbursementItemRemoved>(_onItemRemoved);
    on<CreateReimbursementFileChanged>(_onFileChanged);
    on<CreateReimbursementSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateReimbursementStarted event,
    Emitter<CreateReimbursementState> emit,
  ) async {
    emit(state.copyWith(
      isCategoriesLoading: true,
      isEmployeeLoading: true,
    ));

    // 1. Fetch categories
    try {
      final categories = await _repository.getCategories();
      emit(state.copyWith(
        categories: categories,
        isCategoriesLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isCategoriesLoading: false));
    }

    // 2. Fetch employee detail (for bank info & department)
    try {
      final employeeId = await _authLocalDataSource.getEmployeeId();
      if (employeeId != null && employeeId.isNotEmpty) {
        final emp = await _employeeRepository.getEmployeeDetail(employeeId);
        emit(state.copyWith(
          employeeDetail: emp,
          isEmployeeLoading: false,
        ));
      } else {
        emit(state.copyWith(isEmployeeLoading: false));
      }
    } catch (_) {
      emit(state.copyWith(isEmployeeLoading: false));
    }
  }

  void _onTypeChanged(
    CreateReimbursementTypeChanged event,
    Emitter<CreateReimbursementState> emit,
  ) {
    if (event.type == 'out_of_pocket') {
      emit(state.copyWith(
        type: event.type,
        clearCashAdvanceId: true,
        clearSelectedCashAdvance: true,
      ));
    } else {
      emit(state.copyWith(type: event.type));
    }
  }

  Future<void> _onCashAdvanceSelected(
    CreateReimbursementCashAdvanceSelected event,
    Emitter<CreateReimbursementState> emit,
  ) async {
    if (event.cashAdvanceId == null || event.cashAdvanceId!.isEmpty) {
      emit(state.copyWith(
        clearCashAdvanceId: true,
        clearSelectedCashAdvance: true,
      ));
      return;
    }

    emit(state.copyWith(cashAdvanceId: event.cashAdvanceId));

    try {
      final detail = await _repository.getCashAdvanceDetail(event.cashAdvanceId!);
      emit(state.copyWith(
        cashAdvanceNominal: detail.approvedAmount ?? detail.requestedAmount,
        cashAdvanceNumber: detail.advanceNumber,
        cashAdvanceTitle: detail.title,
      ));
    } catch (_) {
      // Ignore if detail cannot be fetched immediately
    }
  }

  void _onCashAdvanceObjectSelected(
    CreateReimbursementCashAdvanceObjectSelected event,
    Emitter<CreateReimbursementState> emit,
  ) {
    final item = event.cashAdvance;
    emit(state.copyWith(
      cashAdvanceId: item.id,
      selectedCashAdvance: item,
      cashAdvanceNominal: item.approvedAmount ?? item.requestedAmount,
      cashAdvanceNumber: item.referenceNumber,
      cashAdvanceTitle: item.title,
    ));
  }

  void _onItemAdded(
    CreateReimbursementItemAdded event,
    Emitter<CreateReimbursementState> emit,
  ) {
    final updated = List<Map<String, dynamic>>.from(state.items)..add(event.item);
    emit(state.copyWith(items: updated));
  }

  void _onItemRemoved(
    CreateReimbursementItemRemoved event,
    Emitter<CreateReimbursementState> emit,
  ) {
    if (event.index < 0 || event.index >= state.items.length) return;
    final updated = List<Map<String, dynamic>>.from(state.items)
      ..removeAt(event.index);
    emit(state.copyWith(items: updated));
  }

  void _onFileChanged(
    CreateReimbursementFileChanged event,
    Emitter<CreateReimbursementState> emit,
  ) {
    emit(state.copyWith(
      file: event.file,
      clearFile: event.file == null,
    ));
  }

  Future<void> _onSubmitted(
    CreateReimbursementSubmitted event,
    Emitter<CreateReimbursementState> emit,
  ) async {
    if (state.items.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Minimal sertakan 1 nota/struk pengeluaran',
      ));
      return;
    }

    if (state.type == 'cash_advance_settlement' &&
        (state.cashAdvanceId == null || state.cashAdvanceId!.isEmpty)) {
      emit(state.copyWith(
        errorMessage: 'Harap pilih kasbon aktif yang ingin diselesaikan',
      ));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      clearErrorMessage: true,
    ));

    try {
      final claimNumber = await _repository.createReimbursement(
        title: event.title,
        description: event.description,
        type: state.type,
        cashAdvanceId: state.cashAdvanceId,
        bankName: event.bankName,
        bankAccountNumber: event.bankAccountNumber,
        bankAccountHolder: event.bankAccountHolder,
        items: state.items,
        file: state.file,
        files: event.files,
      );

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdClaimNumber: claimNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}
