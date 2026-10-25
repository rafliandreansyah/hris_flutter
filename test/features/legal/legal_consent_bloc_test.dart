import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/legal/presentation/bloc/legal_consent/legal_consent_bloc.dart';

import 'fake_legal_consent_repository.dart';

void main() {
  group('LegalConsentBloc', () {
    late FakeLegalConsentRepository repo;
    late LegalConsentBloc bloc;

    setUp(() {
      repo = FakeLegalConsentRepository();
      bloc = LegalConsentBloc(repository: repo);
    });

    tearDown(() => bloc.close());

    test('state awal: belum dicentang dan belum disetujui', () {
      expect(bloc.state, const LegalConsentState());
    });

    test('toggle mengubah isAgreed', () async {
      bloc.add(const LegalConsentAgreementToggled(true));
      await expectLater(
        bloc.stream,
        emits(const LegalConsentState(isAgreed: true)),
      );

      bloc.add(const LegalConsentAgreementToggled(false));
      await expectLater(bloc.stream, emits(const LegalConsentState()));
    });

    test('accept tanpa centang diabaikan', () async {
      bloc.add(const LegalConsentAccepted());
      await Future<void>.delayed(Duration.zero);

      expect(repo.acceptCalls, 0);
      expect(bloc.state.isAccepted, isFalse);
    });

    test('accept setelah dicentang menyimpan persetujuan', () async {
      bloc
        ..add(const LegalConsentAgreementToggled(true))
        ..add(const LegalConsentAccepted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const LegalConsentState(isAgreed: true),
          const LegalConsentState(isAgreed: true, isSubmitting: true),
          const LegalConsentState(isAgreed: true, isAccepted: true),
        ]),
      );
      expect(repo.acceptCalls, 1);
      expect(repo.accepted, isTrue);
    });

    test('accept gagal -> errorMessage dari exception', () async {
      repo.acceptError = const ApiException(message: 'Penyimpanan penuh');
      bloc
        ..add(const LegalConsentAgreementToggled(true))
        ..add(const LegalConsentAccepted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const LegalConsentState(isAgreed: true),
          const LegalConsentState(isAgreed: true, isSubmitting: true),
          const LegalConsentState(
            isAgreed: true,
            errorMessage: 'Penyimpanan penuh',
          ),
        ]),
      );
    });
  });
}
