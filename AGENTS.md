# AGENTS.md - Project Rules & Guidelines for HRIS Flutter

## 🚀 Core Architecture Guidelines
1. **State Management**: Always use **`flutter_bloc`** and **`equatable`** for all state management across the project (`activity`, `employee`, `attendance`, `leave`, `overtime`, `auth`, `dashboard`, etc.).
2. **Clean Architecture**:
   - Maintain clear separation: Presentation (Pages, Widgets, BLoC) -> Domain (Repository Interfaces) -> Data (Datasources, Repository Implementations, Models).
   - No direct `setState` for network calls, data fetching, or business logic.
3. **Master Data & Caching**:
   - Master data (such as organization filters: companies, departments, positions) should be managed via dedicated BLoCs with in-memory caching to avoid redundant API requests.
4. **Testing Standards**:
   - Every BLoC must have comprehensive unit tests using standard `test` and `bloc_test` patterns.
   - Maintain 100% passing rate across all widget and unit test suites.
5. **Error Handling & API Feedback Standards**:
   - **Always verify and handle error states** across all screens (Dashboard, Attendance, Activity, Employee, etc.) during feature development, refactoring, and pair programming.
   - Catch `ApiException` from network requests and propagate the `message` and `statusCode` through BLoC failure/error states.
   - **API Error Messages**: Always extract and display the error message directly from the API (`e.message` / `state.message`) rather than hardcoding static error texts, as the backend already configures the default language based on the employee/user profile.
   - **Consistent User Feedback**: Display standardized error popups using `AppDialogUtil.showError` (`pro_dialog`) alongside in-screen error/empty states.
   - **Special HTTP Status Codes**:
     - **401 Unauthorized**: Handled globally by `ApiClient` auto-logout (clear secure storage, clear in-memory token, delete FCM token via `NotificationService`, show session expired dialog, and redirect to login).
     - **404 Not Found**: For schedule or specific missing resource errors, provide only a "Kembali" option without retry buttons.
6. **Design System & Styling Standards (Stitch M3 "Teal Oasis")**:
   - **Zero Hardcoded Values**: Never hardcode colors, padding, margins, border radiuses, or text styles in widgets.
   - **Colors**: Always use `AppColors` from `lib/app/config/app_colors.dart` (`primary`, `brandTeal`, `surface`, `background`, `error`, `success`, `warning`, etc.).
   - **Spacing & Radius**: Always use `AppSpacing` and `AppRadius` from `lib/app/config/app_design.dart`.
   - **Typography**: Always use `AppTypography` from `lib/app/config/app_typography.dart` (GoogleFonts Plus Jakarta Sans).
   - **Icons**: Always prefer `LucideIcons` from `package:lucide_icons_flutter/lucide_icons.dart`.
7. **Networking & Routing**:
   - Centralize API endpoints in `lib/core/constants/api_endpoints.dart`.
   - Centralize routes in `lib/app/routes/route_name.dart` and register them in `lib/app/routes/app_router.dart`.
