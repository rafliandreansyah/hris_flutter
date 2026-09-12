# Architectural Rule: Mandatory Flutter BLoC, Clean Architecture & Design System

## 1. Default State Management Pattern
- **Library**: `flutter_bloc` combined with `equatable`.
- **Scope**: Mandatory for all existing and newly created features (`activity`, `employee`, `attendance`, `leave`, `overtime`, `auth`, `dashboard`, etc.), including dialogs/bottom sheets that manage remote or asynchronous state.
- **Strict Prohibition**: Do **NOT** use `StatefulWidget` with `setState` for business logic, asynchronous API fetching, repository interaction, or pagination/filtering state. `setState` is only permitted for purely transient UI animation controllers or local drag handles.

## 2. Clean Architecture Layering
Every feature must follow this strict layer separation:
```
lib/features/<feature_name>/
├── data/
│   ├── datasources/       # Remote / Local API clients, Dio requests via ApiClient.instance
│   ├── models/            # JSON serialization models (fromJson/toJson, Equatable)
│   └── repositories/      # Concrete repository implementations (with caching if master data)
├── domain/
│   ├── models/            # (Optional) Pure domain entities if separated from DTOs
│   └── repositories/      # Abstract repository interfaces
└── presentation/
    ├── bloc/              # Sub-flow bloc (<sub_flow>_event.dart, _state.dart, _bloc.dart)
    ├── pages/             # <feature>_screen.dart (StatelessWidgets wrapping BlocProvider & Views)
    └── widgets/           # Sub-components consuming BlocBuilder/BlocConsumer
```

## 3. BLoC Standards
1. **Events**: Abstract class extending `Equatable`. Sub-classes represent explicit user intentions or lifecycle actions (`Started`, `Refreshed`, `SearchChanged`, `FilterApplied`, `LoadMoreRequested`, `SubmitRequested`).
2. **States**: Single immutable class per BLoC extending `Equatable` with an explicit `Status` enum (`initial`, `loading`, `success`, `failure`). Always provide `copyWith(...)` and complete `props`.
3. **Repository Injection**: BLoCs must accept repository interfaces via constructor, defaulting to concrete implementation if null:
   ```dart
   FeatureBloc({FeatureRepository? repository})
       : _repository = repository ?? FeatureRepositoryImpl(),
         super(const FeatureState());
   ```
4. **View Separation**: Screens must be `StatelessWidget` returning `BlocProvider<FeatureBloc>` wrapping a private `_FeatureView`. Allow injecting an optional pre-configured BLoC or Repository for testing.

## 4. Design System Invariants (Google Stitch M3 "Teal Oasis")
Zero tolerance for hardcoded design values or magic numbers:
- **Colors**: Wajib gunakan `AppColors` (`lib/app/config/app_colors.dart`). Dilarang keras memakai `Color(0xFF...)` atau `Colors.blue` langsung di widget.
- **Spacing**: Wajib gunakan `AppSpacing` (`lib/app/config/app_design.dart`) seperti `xs` (4), `sm` (8), `md` (16), `lg` (20), `xl` (24), `marginMobile` (16).
- **Radius**: Wajib gunakan `AppRadius` (`lib/app/config/app_design.dart`) seperti `sm` (4), `md` (8), `input` (12), `lg` (16), `xl` (24), `full` (9999).
- **Typography**: Wajib gunakan `AppTypography` (`lib/app/config/app_typography.dart`) yang berbasis GoogleFonts Plus Jakarta Sans.
- **Icons**: Wajib gunakan `LucideIcons` dari `package:lucide_icons_flutter/lucide_icons.dart` atau `CupertinoIcons`.

## 5. Networking & Error Handling Standards
- **API Client**: Wajib menggunakan `ApiClient.instance` berbasis `Dio`.
- **Endpoints**: Wajib didaftarkan secara terpusat di `lib/core/constants/api_endpoints.dart`.
- **Exception Catching**: Tangkap `ApiException` dari network requests dan teruskan `e.message` serta `e.statusCode` ke state BLoC.
- **Dynamic API Messages**: Tampilkan pesan error langsung dari backend (`e.message` / `state.errorMessage`), bukan pesan statis hardcoded, karena backend menyesuaikan bahasa dengan profil pengguna.
- **Standard Dialogs**: Gunakan `AppDialogUtil` (`lib/core/utils/app_dialog_util.dart`) berbasis `pro_dialog` (`showError`, `showSuccess`, `showWarning`, `showLoading`).
- **HTTP 401**: Dikelola otomatis oleh `ApiClient` (menghapus secure storage, token FCM, menampilkan sesi berakhir, redirect ke Login).
- **HTTP 404**: Sediakan tombol "Kembali" tanpa tombol retry jika data/jadwal memang tidak ada.
