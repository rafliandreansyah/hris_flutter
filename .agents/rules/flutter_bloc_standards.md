# Architectural Rule: Mandatory Flutter BLoC & Clean Architecture

## 1. Default State Management Pattern
- **Library**: `flutter_bloc` combined with `equatable`.
- **Scope**: Mandatory for all existing and newly created features (`activity`, `employee`, `auth`, `dashboard`, etc.), including dialogs/bottom sheets that manage remote or asynchronous state.
- **Strict Prohibition**: Do **NOT** use `StatefulWidget` with `setState` for business logic, asynchronous API fetching, repository interaction, or pagination/filtering state. `setState` is only permitted for purely transient UI animation controllers or local drag handles.

## 2. Clean Architecture Layering
Every feature must follow this strict layer separation:
```
lib/features/<feature_name>/
├── data/
│   ├── datasources/       # Remote / Local API clients, Dio requests
│   ├── models/            # JSON serialization models (fromJson/toJson)
│   └── repositories/      # Concrete repository implementations
├── domain/
│   ├── models/            # (Optional) Domain entities if separated from DTOs
│   └── repositories/      # Abstract repository interfaces
└── presentation/
    ├── bloc/              # <feature>_event.dart, <feature>_state.dart, <feature>_bloc.dart
    ├── pages/             # StatelessWidgets wrapping BlocProvider & Views
    └── widgets/           # Sub-components consuming BlocBuilder/BlocConsumer
```

## 3. BLoC Standards
1. **Events**: Abstract class extending `Equatable`. Sub-classes represent explicit user intentions or lifecycle actions (`Started`, `Refreshed`, `SearchChanged`, `FilterApplied`, `LoadMoreRequested`, `SubmitRequested`).
2. **States**: Immutable class extending `Equatable` with explicit `Status` enums (`initial`, `loading`, `loaded`, `submitting`, `actionSuccess`, `failure`). Always provide `copyWith(...)`.
3. **Repository Injection**: BLoCs must accept repository interfaces (e.g. `EmployeeRepository`) via constructor, defaulting to concrete implementation if null. This enables seamless unit testing with mocks.
4. **View Separation**: Screens should be `StatelessWidget` returning `BlocProvider<FeatureBloc>` wrapping a private `_FeatureView`. Allow injecting an optional pre-configured BLoC for testing.
