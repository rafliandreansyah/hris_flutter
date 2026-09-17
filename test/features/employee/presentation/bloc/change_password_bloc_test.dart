import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_state.dart';

class MockEmployeePasswordRepository implements EmployeeRepository {
  String? lastOldPassword;
  String? lastNewPassword;
  bool shouldThrowApiException = false;
  bool shouldThrowGenericException = false;
  String apiErrorMessage = 'Password lama Anda tidak sesuai.';
  String successMessage = 'Password berhasil diperbarui.';

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    lastOldPassword = oldPassword;
    lastNewPassword = newPassword;

    if (shouldThrowApiException) {
      throw ApiException(message: apiErrorMessage, statusCode: 400);
    }
    if (shouldThrowGenericException) {
      throw Exception('Server timeout');
    }
    return successMessage;
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async => [];

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async =>
      throw UnimplementedError();

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async =>
      throw UnimplementedError();
}

void main() {
  group('ChangePasswordBloc Unit Tests', () {
    late MockEmployeePasswordRepository mockRepo;
    late ChangePasswordBloc bloc;

    setUp(() {
      mockRepo = MockEmployeePasswordRepository();
      bloc = ChangePasswordBloc(repository: mockRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is ChangePasswordState with initial status', () {
      expect(bloc.state.status, equals(ChangePasswordStatus.initial));
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.isSuccess, isFalse);
      expect(bloc.state.isFailure, isFalse);
    });

    test('emits failure when old password is empty', () async {
      bloc.add(const ChangePasswordSubmitted(
        oldPassword: '   ',
        newPassword: 'ValidPassword123!',
        confirmPassword: 'ValidPassword123!',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ChangePasswordState>((s) =>
              s.status == ChangePasswordStatus.failure &&
              s.errorMessage == 'Password saat ini wajib diisi.'),
        ]),
      );
    });

    test('emits failure when new password is empty', () async {
      bloc.add(const ChangePasswordSubmitted(
        oldPassword: 'OldPassword123!',
        newPassword: '   ',
        confirmPassword: '   ',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ChangePasswordState>((s) =>
              s.status == ChangePasswordStatus.failure &&
              s.errorMessage == 'Password baru wajib diisi.'),
        ]),
      );
    });

    test('emits failure when confirm password does not match new password', () async {
      bloc.add(const ChangePasswordSubmitted(
        oldPassword: 'OldPassword123!',
        newPassword: 'ValidPassword123!',
        confirmPassword: 'DifferentPassword123!',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ChangePasswordState>((s) =>
              s.status == ChangePasswordStatus.failure &&
              s.errorMessage ==
                  'Konfirmasi password tidak cocok dengan password baru.'),
        ]),
      );
    });

    test('emits [loading, success] when repository successfully updates password', () async {
      bloc.add(const ChangePasswordSubmitted(
        oldPassword: 'OldPassword123!',
        newPassword: 'NewValidPassword123!',
        confirmPassword: 'NewValidPassword123!',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ChangePasswordState>((s) => s.status == ChangePasswordStatus.loading),
          predicate<ChangePasswordState>((s) =>
              s.status == ChangePasswordStatus.success &&
              s.successMessage == 'Password berhasil diperbarui.'),
        ]),
      );

      expect(mockRepo.lastOldPassword, equals('OldPassword123!'));
      expect(mockRepo.lastNewPassword, equals('NewValidPassword123!'));
    });

    test('emits [loading, failure] with backend error message on ApiException', () async {
      mockRepo.shouldThrowApiException = true;
      mockRepo.apiErrorMessage = 'Kata sandi lama tidak valid.';

      bloc.add(const ChangePasswordSubmitted(
        oldPassword: 'WrongPassword123!',
        newPassword: 'NewValidPassword123!',
        confirmPassword: 'NewValidPassword123!',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ChangePasswordState>((s) => s.status == ChangePasswordStatus.loading),
          predicate<ChangePasswordState>((s) =>
              s.status == ChangePasswordStatus.failure &&
              s.errorMessage == 'Kata sandi lama tidak valid.'),
        ]),
      );
    });

    test('emits [loading, failure] on generic Exception', () async {
      mockRepo.shouldThrowGenericException = true;

      bloc.add(const ChangePasswordSubmitted(
        oldPassword: 'OldPassword123!',
        newPassword: 'NewValidPassword123!',
        confirmPassword: 'NewValidPassword123!',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ChangePasswordState>((s) => s.status == ChangePasswordStatus.loading),
          predicate<ChangePasswordState>((s) =>
              s.status == ChangePasswordStatus.failure &&
              (s.errorMessage?.contains('Server timeout') ?? false)),
        ]),
      );
    });

    test('resets state to initial on ChangePasswordReset', () async {
      // First emit a failure
      bloc.add(const ChangePasswordSubmitted(
        oldPassword: '',
        newPassword: 'abc',
        confirmPassword: 'abc',
      ));

      await expectLater(
        bloc.stream,
        emits(predicate<ChangePasswordState>(
            (s) => s.status == ChangePasswordStatus.failure)),
      );

      // Now reset
      bloc.add(const ChangePasswordReset());

      await expectLater(
        bloc.stream,
        emits(predicate<ChangePasswordState>(
            (s) => s.status == ChangePasswordStatus.initial)),
      );
    });
  });
}
