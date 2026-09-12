---
name: flutter-bloc-development
description: Build Flutter features using BLoC state management, clean architecture layers, and Muratech HRIS design tokens and network standards. Apply when creating new features, screens, widgets, BLoCs, or data integrations.
---

# Flutter BLoC Development Guide for Muratech HRIS

Panduan standar dan runbook resmi untuk membangun fitur baru, halaman, komponen widget, atau integrasi data di aplikasi **Muratech HRIS Flutter**.

Semua kode baru **WAJIB** mematuhi Clean Architecture, BLoC state management dengan `Equatable`, token *Design System* Google Stitch M3 ("Teal Oasis"), dan konvensi *networking* Dio/ApiClient.

---

## 1. Panduan Alur Pengerjaan (Decision Tree)

```
Permintaan Fitur Baru / Perubahan
    │
    ├─ Fitur / Layar Baru (Full Feature):
    │   1. Buat folder: lib/features/<feature_name>/
    │   2. Data Layer:
    │      - models/<feature>_api_models.dart
    │      - datasources/<feature>_remote_datasource.dart (menggunakan ApiClient.instance)
    │      - repositories/<feature>_repository_impl.dart
    │   3. Domain Layer:
    │      - repositories/<feature>_repository.dart (abstract interface)
    │   4. Presentation Layer:
    │      - bloc/<sub_flow>/ (<flow>_event.dart, <flow>_state.dart, <flow>_bloc.dart)
    │      - pages/<feature>_screen.dart (StatelessWidget + BlocProvider)
    │      - widgets/<component>.dart (Modular cards, filter sheet, list items)
    │   5. Registrasi Rute & Endpoint:
    │      - Endpoint di lib/core/constants/api_endpoints.dart
    │      - Nama rute di lib/app/routes/route_name.dart & daftarkan di lib/app/routes/app_router.dart
    │   6. Testing:
    │      - Unit test BLoC dengan bloc_test di test/features/<feature_name>/
    │
    ├─ Penambahan / Modifikasi Widget Saja:
    │   1. Jika spesifik fitur: lib/features/<feature>/presentation/widgets/
    │   2. Jika global / reusable multi-fitur: lib/core/widgets/
    │   3. Wajib gunakan AppColors, AppSpacing, AppRadius, AppTypography, dan LucideIcons
    │   4. Konsumsi state via BlocBuilder atau BlocConsumer
    │
    └─ Integrasi Endpoint Baru:
        1. Daftarkan URL di lib/core/constants/api_endpoints.dart
        2. Tambahkan method di <feature>_remote_datasource.dart
        3. Tambahkan kontrak di <feature>_repository.dart dan implementasi di <feature>_repository_impl.dart
        4. Tambahkan Event & Handler di BLoC terkait
```

---

## 2. Struktur Folder Standar per Fitur

Setiap fitur dalam `lib/features/<feature_name>/` memiliki struktur yang seragam:

```text
lib/features/<feature_name>/
├── data/
│   ├── datasources/
│   │   └── <feature>_remote_datasource.dart    # Dio HTTP requests via ApiClient.instance
│   ├── models/
│   │   ├── <feature>_api_models.dart          # Response wrapper, Pagination Meta
│   │   └── <feature>_item.dart                # DTO model (fromJson, toJson, props)
│   └── repositories/
│       └── <feature>_repository_impl.dart     # Implementasi repository & in-memory caching
├── domain/
│   ├── models/                                # (Opsional) Entity domain murni jika dipisah
│   └── repositories/
│       └── <feature>_repository.dart          # Abstract interface
└── presentation/
    ├── bloc/
    │   └── <flow_name>/                       # Sub-flow bloc terpisah (misal: list, detail, create)
    │       ├── <flow>_bloc.dart
    │       ├── <flow>_event.dart
    │       └── <flow>_state.dart
    ├── pages/
    │   └── <feature>_screen.dart              # StatelessWidget pembungkus BlocProvider & View
    └── widgets/
        ├── <feature>_card.dart
        └── <feature>_filter_bottom_sheet.dart
```

---

## 3. Implementasi Layer per Layer

### A. Data Layer: Remote DataSource & ApiClient
* Menggunakan `ApiClient.instance` berbasis `Dio`.
* Tangkap error jaringan dengan `ApiException`.
* Parameter query atau multipart form-data disesuaikan dengan kontrak backend.

```dart
// lib/features/example/data/datasources/example_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/example/data/models/example_api_models.dart';

abstract class ExampleRemoteDataSource {
  Future<ExampleListResponse> getItems({required int page, required int size, String? search});
  Future<ExampleDetailResponse> getItemDetail(String id);
}

class ExampleRemoteDataSourceImpl implements ExampleRemoteDataSource {
  final ApiClient _apiClient;

  ExampleRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<ExampleListResponse> getItems({
    required int page,
    required int size,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.exampleList,
        queryParameters: queryParams,
      );

      return ExampleListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<ExampleDetailResponse> getItemDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiEndpoints.exampleList}/$id');
      return ExampleDetailResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
```

### B. Domain & Data: Repository Pattern
* Deklarasikan kontrak murni di `domain/repositories/`.
* Implementasikan di `data/repositories/` dengan opsi *in-memory cache* untuk master data.

```dart
// Domain Interface: lib/features/example/domain/repositories/example_repository.dart
abstract class ExampleRepository {
  Future<ExampleListResponse> getItems({required int page, required int size, String? search});
  Future<ExampleDetailResponse> getItemDetail(String id);
}

// Data Implementation: lib/features/example/data/repositories/example_repository_impl.dart
class ExampleRepositoryImpl implements ExampleRepository {
  final ExampleRemoteDataSource _remoteDataSource;

  ExampleRepositoryImpl({ExampleRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ExampleRemoteDataSourceImpl();

  @override
  Future<ExampleListResponse> getItems({required int page, required int size, String? search}) {
    return _remoteDataSource.getItems(page: page, size: size, search: search);
  }

  @override
  Future<ExampleDetailResponse> getItemDetail(String id) {
    return _remoteDataSource.getItemDetail(id);
  }
}
```

### C. Presentation Layer: BLoC (Event, State, BLoC)
* **Status Enum**: `enum ExampleStatus { initial, loading, success, failure }`.
* **Single State Class**: Memuat data, pagination (`currentPage`, `totalPages`), flag loading (`isLoadingMore`), dan `errorMessage`.
* **Injeksi Repository**: BLoC menerima interface repository via konstruktor untuk kemudahan testing.

```dart
// State: lib/features/example/presentation/bloc/example_list/example_list_state.dart
import 'package:equatable/equatable.dart';

enum ExampleStatus { initial, loading, success, failure }

class ExampleListState extends Equatable {
  final ExampleStatus status;
  final List<ExampleItem> items;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final String? errorMessage;

  const ExampleListState({
    this.status = ExampleStatus.initial,
    this.items = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  ExampleListState copyWith({
    ExampleStatus? status,
    List<ExampleItem>? items,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ExampleListState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, currentPage, totalPages, isLoadingMore, errorMessage];
}
```

```dart
// BLoC: lib/features/example/presentation/bloc/example_list/example_list_bloc.dart
class ExampleListBloc extends Bloc<ExampleListEvent, ExampleListState> {
  final ExampleRepository _repository;
  static const int defaultPageSize = 20;

  ExampleListBloc({ExampleRepository? repository})
      : _repository = repository ?? ExampleRepositoryImpl(),
        super(const ExampleListState()) {
    on<ExampleListStarted>(_onStarted);
    on<ExampleListRefreshRequested>(_onRefreshRequested);
    on<ExampleListLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onStarted(
    ExampleListStarted event,
    Emitter<ExampleListState> emit,
  ) async {
    emit(state.copyWith(status: ExampleStatus.loading));
    try {
      final response = await _repository.getItems(page: 1, size: defaultPageSize);
      emit(state.copyWith(
        status: ExampleStatus.success,
        items: response.data,
        currentPage: response.meta.page,
        totalPages: response.meta.totalPages,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ExampleStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExampleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreRequested(
    ExampleListLoadMoreRequested event,
    Emitter<ExampleListState> emit,
  ) async {
    if (state.isLoadingMore || state.currentPage >= state.totalPages) return;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getItems(page: nextPage, size: defaultPageSize);
      final updatedList = List<ExampleItem>.from(state.items)..addAll(response.data);

      emit(state.copyWith(
        isLoadingMore: false,
        items: updatedList,
        currentPage: response.meta.page,
        totalPages: response.meta.totalPages,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
```

### D. Presentation Layer: Screen & Widgets
* Screen adalah `StatelessWidget` yang membungkus `BlocProvider` dan `_ScreenView`.
* Mendukung injeksi `bloc` atau `repository` opsional untuk keperluan widget test.

```dart
// Screen: lib/features/example/presentation/pages/example_screen.dart
class ExampleScreen extends StatelessWidget {
  final ExampleRepository? repository;
  final ExampleListBloc? exampleListBloc;

  const ExampleScreen({super.key, this.repository, this.exampleListBloc});

  @override
  Widget build(BuildContext context) {
    if (exampleListBloc != null) {
      return BlocProvider<ExampleListBloc>.value(
        value: exampleListBloc!,
        child: const _ExampleScreenView(),
      );
    }
    return BlocProvider<ExampleListBloc>(
      create: (context) => ExampleListBloc(repository: repository)
        ..add(const ExampleListStarted()),
      child: const _ExampleScreenView(),
    );
  }
}

class _ExampleScreenView extends StatelessWidget {
  const _ExampleScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Daftar Contoh', style: AppTypography.titleMedium),
        backgroundColor: AppColors.surface,
      ),
      body: BlocConsumer<ExampleListBloc, ExampleListState>(
        listener: (context, state) {
          if (state.status == ExampleStatus.failure && state.errorMessage != null) {
            AppDialogUtil.showError(
              context,
              message: state.errorMessage!,
              onRetry: () => context.read<ExampleListBloc>().add(const ExampleListStarted()),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ExampleStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state.items.isEmpty) {
            return Center(child: Text('Data tidak ditemukan', style: AppTypography.bodyMedium));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => ExampleCard(item: state.items[index]),
          );
        },
      ),
    );
  }
}
```

---

## 4. Design System Tokens (Stitch M3 "Teal Oasis")

Dilarang keras memakai *hardcoded values* (angka ajaib / hex manual). Gunakan token terpusat berikut:

### Colors (`lib/app/config/app_colors.dart`)
* **Brand / Primary**: `AppColors.primary` (`#00685F`), `AppColors.brandTeal` (`#0D9488`), `AppColors.primaryContainer` (`#F0FDFA`)
* **Canvas & Surface**: `AppColors.background` (`#FAF8FF`), `AppColors.surface` (`#FAF8FF`), `AppColors.surfaceContainerLowest` (`#FFFFFF`)
* **Status**: `AppColors.success` (`#10B981`), `AppColors.warning` (`#F59E0B`), `AppColors.error` (`#BA1A1A`), `AppColors.errorRed` (`#EF4444`)
* **Text**: `AppColors.onSurface` (`#131B2E`), `AppColors.onSurfaceVariant` (`#3D4947`)

### Spacing & Grid (`lib/app/config/app_design.dart`)
* `AppSpacing.xs` (4.0)
* `AppSpacing.sm` (8.0)
* `AppSpacing.md` (16.0)
* `AppSpacing.lg` (20.0)
* `AppSpacing.xl` (24.0)
* `AppSpacing.xxl` (32.0)
* `AppSpacing.marginMobile` (16.0)

### Border Radius (`lib/app/config/app_design.dart`)
* `AppRadius.sm` (4.0)
* `AppRadius.md` (8.0) - default card radius
* `AppRadius.input` (12.0) - form field border
* `AppRadius.lg` (16.0) - medium cards
* `AppRadius.xl` (24.0) - bottom sheet & large modal
* `AppRadius.full` (9999.0) - pill button & chips
* Pre-built `BorderRadius`: `AppRadius.borderMd`, `AppRadius.borderInput`, `AppRadius.borderFull`

### Typography (`lib/app/config/app_typography.dart`)
Font resmi: **Plus Jakarta Sans** via `GoogleFonts`
* Headings: `AppTypography.headlineLarge`, `AppTypography.headlineMedium`
* Titles: `AppTypography.titleMedium`, `AppTypography.titleSmall`
* Body: `AppTypography.bodyLarge`, `AppTypography.bodyMedium`, `AppTypography.bodySmall`
* Labels: `AppTypography.labelMedium`, `AppTypography.labelSmall`

### Icons
* Gunakan package `lucide_icons_flutter` (`LucideIcons.<iconName>`). Contoh: `LucideIcons.calendar`, `LucideIcons.mapPin`, `LucideIcons.filter`.

---

## 5. Standar Penanganan Error & Dialog Feedback

* **Standard Dialogs**: Gunakan `AppDialogUtil` dari `lib/core/utils/app_dialog_util.dart`:
  * `AppDialogUtil.showError(context, message: state.errorMessage, onRetry: ...)`
  * `AppDialogUtil.showSuccess(context, message: '...')`
  * `AppDialogUtil.showWarning(context, message: '...', onConfirm: ...)`
  * `AppDialogUtil.showLoading(context, title: 'Menyimpan...')`
* **Pesan Error Dinamis**: Ambil pesan error langsung dari backend (`e.message` / `state.errorMessage`), jangan hardcode teks error statis karena backend mengatur bahasa sesuai preferensi profil pengguna.
* **HTTP 401**: Dikelola otomatis oleh `ApiClient`. Sesi lokal dibersihkan dan pengguna diarahkan ke Login.

---

## 6. Checklist Pembuatan Fitur Baru

Sebelum menyelesaikan tugas implementasi, selalu verifikasi checklist ini:

- [ ] Folder mengikuti struktur `data/`, `domain/`, `presentation/`
- [ ] BLoC, Event, dan State mengimplementasikan `Equatable`
- [ ] State menggunakan `Status` enum (`initial`, `loading`, `success`, `failure`) dan method `copyWith`
- [ ] BLoC menerima repository melalui konstruktor (dengan default fallback)
- [ ] Tidak ada panggilan API atau `setState` untuk logika bisnis di dalam Widget
- [ ] Remote DataSource memanggil `ApiClient.instance` dan menangani `ApiException`
- [ ] Seluruh warna menggunakan `AppColors`, padding menggunakan `AppSpacing`, radius menggunakan `AppRadius`, font menggunakan `AppTypography`
- [ ] Icon menggunakan `LucideIcons`
- [ ] Feedback error/sukses menggunakan `AppDialogUtil` (`pro_dialog`)
- [ ] Rute didaftarkan di `RouteName` dan `AppRouter`
- [ ] Kode terformat rapi (`dart format .`)
