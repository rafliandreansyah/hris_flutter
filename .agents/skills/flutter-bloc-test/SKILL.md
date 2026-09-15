---
name: flutter-bloc-test
description: Write comprehensive unit and widget tests for BLoC and Cubit using package:bloc_test, mocktail, and mockito. Apply when creating or modifying BLoC tests, mocking repositories, and testing UI reactions to state changes.
---

# Flutter BLoC Testing Guide (`bloc_test`)

Panduan resmi untuk membuat unit test BLoC/Cubit dan widget test interaksi BLoC menggunakan `package:bloc_test`, `package:flutter_test`, dan `package:mocktail`.

---

## 1. Prinsip Utama Pengujian BLoC

1. **Deterministic & Predictable**: Test harus selalu menghasilkan output yang sama tanpa bergantung pada server nyata.
2. **Mock Semua Dependency**: Repositori, data source, dan layanan pihak ketiga harus di-mock.
3. **Uji State Transitions**: Verifikasi urutan state yang di-emit: `initial` -> `loading` -> `success` / `failure`.
4. **Cakupan Error & Edge Cases**: Selalu uji skenario kegagalan (`ApiException`, timeout, empty data).
5. **Equatable State**: Pastikan State mengimplementasikan `Equatable` agar matcher `expect` membandingkan nilai objek (`value equality`).

---

## 2. Struktur File Test BLoC

```text
test/
└── features/
    └── <feature_name>/
        └── presentation/
            └── bloc/
                └── <flow_name>/
                    └── <flow_name>_bloc_test.dart
```

---

## 3. Template Unit Test: `blocTest`

Gunakan fungsi `blocTest<BlocType, StateType>` dari `package:bloc_test`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_state.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

void main() {
  late MockActivityRepository mockRepository;
  late ActivityListBloc bloc;

  final dummyListResponse = ActivityListResponse(
    data: [
      ActivityItem(id: '1', title: 'Task 1', date: '2026-09-15', status: 'approved'),
    ],
    meta: const PaginationMeta(page: 1, totalPages: 2, totalItems: 20),
  );

  setUp(() {
    mockRepository = MockActivityRepository();
    bloc = ActivityListBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ActivityListBloc', () {
    test('initial state memiliki status initial dan list kosong', () {
      expect(bloc.state.status, equals(ActivityStatus.initial));
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.currentPage, equals(1));
    });

    group('ActivityListStarted', () {
      blocTest<ActivityListBloc, ActivityListState>(
        'emit [loading, success] saat pemanggilan repositori berhasil',
        build: () {
          when(() => mockRepository.getActivities(page: 1, size: any(named: 'size')))
              .thenAnswer((_) async => dummyListResponse);
          return ActivityListBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const ActivityListStarted()),
        expect: () => [
          const ActivityListState(status: ActivityStatus.loading),
          ActivityListState(
            status: ActivityStatus.success,
            items: dummyListResponse.data,
            currentPage: 1,
            totalPages: 2,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getActivities(page: 1, size: any(named: 'size'))).called(1);
        },
      );

      blocTest<ActivityListBloc, ActivityListState>(
        'emit [loading, failure] saat terjadi ApiException',
        build: () {
          when(() => mockRepository.getActivities(page: 1, size: any(named: 'size')))
              .thenThrow(ApiException(message: 'Gagal memuat data', statusCode: 500));
          return ActivityListBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const ActivityListStarted()),
        expect: () => [
          const ActivityListState(status: ActivityStatus.loading),
          const ActivityListState(
            status: ActivityStatus.failure,
            errorMessage: 'Gagal memuat data',
          ),
        ],
      );
    });
  });
}
```

---

## 4. Parameter Utama `blocTest`

| Parameter | Deskripsi |
| :--- | :--- |
| `build` | Mengembalikan instance BLoC baru untuk test. |
| `seed` | Menentukan state awal sebelum aksi dimulai (misal: state pagination). |
| `act` | Callback aksi (`bloc.add(Event())`). |
| `wait` | Durasi jeda untuk menunggu debounce atau timer asinkron. |
| `expect` | List state yang diharapkan di-emit secara berurutan. |
| `verify` | Memverifikasi pemanggilan method dependency mock. |

---

## 5. UI Widget Testing dengan `MockBloc` (`whenListen`)

Untuk menguji Widget tanpa menjalankan bisnis logic nyata:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityListBloc extends MockBloc<ActivityListEvent, ActivityListState>
    implements ActivityListBloc {}

void main() {
  late MockActivityListBloc mockBloc;

  setUp(() {
    mockBloc = MockActivityListBloc();
  });

  testWidgets('menampilkan loading indicator saat status loading', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const ActivityListState(status: ActivityStatus.loading),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ActivityListBloc>.value(
          value: mockBloc,
          child: const ActivityScreenView(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```
