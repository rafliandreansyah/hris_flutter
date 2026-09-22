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
8. **Loading State Standards**:
   - **Initial Page/Tab Loading**: Always use **Shimmer (Skeleton)** placeholder cards that mirror the structure of content (requests, logs, activity feed) to maintain high perceived performance and prevent content layout shifts.
   - **Pagination (Load More)**: Use a small **`CircularProgressIndicator(strokeWidth: 2.5)`** at the bottom of the list.
   - **Form Actions / Submit**: Use **`CircularProgressIndicator`** inside the action button (e.g. submit, approve, reject).
   - **Pull-to-Refresh**: Use standard Flutter **`RefreshIndicator`**.
9. **Reusable Global Widgets & Button Loading Standards**:
   - **Reuse Existing Widgets**: Always check and reuse global widgets in `lib/core/widgets/` (such as **`AppButton`**, `AppTextField`, etc.) instead of constructing raw `ElevatedButton`, `OutlinedButton`, or custom button styles directly in features, sheets, or dialogs.
   - **Consistent Button Loading States**: Every async action button (Submit, Save, Approve, Reject, Clock In/Out, Filter, etc.) must implement `isLoading` via `AppButton(isLoading: isSubmitting, ...)`. When loading, the button displays a centered `CircularProgressIndicator(strokeWidth: 2.5)` with matching contrast foreground color, and disables further taps (`onPressed: null`).
10. **Dialog & Alert Standards (`pro_dialog`)**:
    - **Centralized Usage**: All alerts, confirmations, and status feedback dialogs across features must use **`AppDialogUtil`** backed by **`package:pro_dialog`** (`showSuccess`, `showError`, `showWarning`, `showLoading`, `showPermissionDialog`).
    - **No Raw Dialogs / SnackBars**: Avoid raw `showDialog`, `AlertDialog`, or raw `SnackBar` for critical action feedback (login failures, clock in/out confirmation, location errors, etc.).
    - **Consistent Theming & Overflow Safety**: Always adhere to `ProDialogTheme` tokens (matching Stitch M3 surface, colors, and typography), auto-vertical button layout on compact screens, and scrollable `ConstrainedBox` for multi-item or custom content.
11. **Permission Request Standards (`PermissionUtil` & `pro_dialog`)**:
    - **Centralized Permission Flow**: Never invoke `Permission.<type>.request()`, `Geolocator.requestPermission()`, or `ImagePicker.pickImage()` directly in presentation screens or widgets. Always route requests through **`PermissionUtil`**.
    - **Permission Rationale Dialog First**: If an essential permission has not yet been granted, `PermissionUtil` must present `AppDialogUtil.showPermissionDialog` (with the security shield icon and structured permission cards) before triggering native OS dialogs.
    - **Strict Non-Dismissible**: Permission rationale and permanently denied dialogs MUST set `barrierDismissible: false` and `PopScope(canPop: false)`. The user cannot dismiss via background tap or back gestures and must explicitly tap action buttons ("Izinkan" / "Tolak" or "Buka Pengaturan" / "Nanti Saja").
    - **Compound Workflows**: Multi-permission features (e.g. Attendance requiring Location + Camera; Activity Proof requiring Location + Camera + Gallery) must use compound requests (`PermissionUtil.requestAttendancePermissions`, `PermissionUtil.requestActivityProofPermissions`) to present a single composite dialog listing all required permissions with an "Izinkan Semua" button.
    - **Fast-Path Bypass**: If the requested permissions are already granted by the system, skip the rationale dialog immediately to maintain a snappy user experience.
12. **Standard Filter Bottom Sheet Pattern & Reusable Components (`lib/core/widgets/filter/`)**:
    - **Single Source of Truth for Requests**: All request modules (`attendance_request`, `leave`, `overtime`) MUST reuse the unified component **`AppRequestFilterBottomSheet`** (`lib/core/widgets/filter/app_request_filter_bottom_sheet.dart`) and **`showAppRequestFilterBottomSheet`** rather than duplicating boilerplate form and lifecycle code.
    - **Uniform Architecture**: Custom filter bottom sheets across modules (e.g. `activity`, `employee`) MUST reuse the modular building blocks from `lib/core/widgets/filter/`:
      - **Field Selector**: **`FilterFieldSelector`** (`lib/core/widgets/filter/filter_field_selector.dart`) for all form picker cards (label, value, icon, lock/clear/loading states, helper text).
      - **Option Picker Modal**: **`showFilterOptionSelector`** (`lib/core/widgets/filter/filter_option_selector_modal.dart`) with auto-search box for >5 items, checkmark indicator for active option, and anti-alias sheet.
      - **Status Segmented Chips**: **`FilterStatusSegmentedRow`** (`lib/core/widgets/filter/filter_status_segmented_row.dart`) with 4 equal horizontal buttons (`Semua`, `Diajukan` / `Requested`, `Approved`, `Rejected`), border 1.5px, subtle teal tint `#F0FDFA` when selected.
      - **Date Range Picker**: **`showAppDateRangePicker`** (`lib/core/widgets/filter/app_date_range_picker.dart`) fully styled with Stitch M3 Teal Oasis date picker tokens.
    - **Header**:
      - Rounded circular icon badge (36x36, primary/brandTeal 10% opacity, `LucideIcons.slidersHorizontal`, size 18).
      - Title using `AppTypography.titleMedium` (16sp, bold/w700).
      - Action `TextButton.icon` with `LucideIcons.rotateCcw` (size 14) labeled "Reset Filter".
      - Trailing `Divider(height: 1)`.
    - **Organization Cascading (Company -> Department -> Position)**:
      - Always consume `OrganizationFilterBloc`.
      - Department and Position fields must be disabled (locked with `LucideIcons.lock`, opacity 0.6, and helper text "Pilih perusahaan terlebih dahulu") until a company is selected.
      - Selecting a company resets downstream selections and dispatches `OrganizationFilterCompanySelected`.
      - Selecting a department resets position and dispatches `OrganizationFilterDepartmentSelected`.
    - **Footer Actions**:
      - Row with two `AppButton` widgets at `height: 50`: "Batal" (`AppButtonVariant.outlined`) and "Terapkan Filter" (`AppButtonVariant.primary`, `leadingIcon: LucideIcons.filter`).
13. **Required Form Field Asterisk Standards**:
    - **Mandatory Red Asterisk (`*`)**: For all required form input fields, form labels, section headers, or upload cards across all features, the mandatory asterisk indicator (`*`) MUST ALWAYS be styled in red (`AppColors.errorRed` / `AppColors.error`, e.g., `TextSpan(text: ' *', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold))`).
    - **AppTextField Standard**: `AppTextField` automatically renders the required asterisk (`*`) in red (either cleanly extracted from `label` containing `*` or when `isRequired: true`).
    - **Zero Plain Asterisks**: Never render a required asterisk `*` in the default label or onSurface text color.
14. **Request Items Employee Info Standard (`EmployeeInfoRow`)**:
    - **Single Standard for Request Modules**: Across all request modules (`attendance_request`, `leave`, `overtime`, etc.) and feeds (`activity`), all request item cards displayed in list views MUST ALWAYS use the global widget **`EmployeeInfoRow`** (`lib/core/widgets/employee_info_row.dart`) for rendering employee identity (avatar, name, role • department, employee number badge, company badge).
    - **Consistency Across Cards**: Never build manual or ad-hoc avatar + employee info columns in request cards. Always pass `name`, `role`, `department`, `company`, `employeeId`, `avatarUrl`, `initials`, and a compact `avatarSize` (typically 40–44) into `EmployeeInfoRow`.
15. **Keyboard Dismiss & Form Action Standards (`onTapOutside` & Unfocus on Submit)**:
    - **Global `AppTextField`**: Always configure default `onTapOutside: widget.onTapOutside ?? (event) => FocusManager.instance.primaryFocus?.unfocus()` so tapping outside any text field immediately dismisses the software keyboard on iOS and Android.
    - **Direct TextField / TextFormField**: Any raw input field across forms, search bars, dialogs, or filter sheets MUST specify `onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus()`.
    - **Form Action Handlers**: All form submit and action handlers (`_handleSubmit`, `_submitForm`, dialog submit buttons) MUST invoke `FocusManager.instance.primaryFocus?.unfocus()` on the very first line before validation and BLoC event dispatching.
    - **Bottom Action Buttons Placement**: Form action buttons must be placed in `Scaffold.bottomNavigationBar` (with `SafeArea(top: false, child: ...)`), keeping buttons anchored at the bottom of the screen instead of jumping above the keyboard while typing, maintaining a clean and spacious viewport.
16. **Consistent Tab Naming & Localization Standards (Context-Aware Tabs)**:
    - **Context-Aware Rule**: All 2-tab screens (`TabBar`) across the application must strictly adhere to the standardized Context-Aware tab naming:
      - **Request & Approval Modules** (`leave`, `overtime`, `attendance_requests`, `reimbursement` / `expenses`):
        - **Left Tab (Self/Employee)**: `l10n?.tabMyRequests ?? 'Pengajuan Saya'` (Icon: `LucideIcons.calendarClock`, `LucideIcons.alarmClock`, `LucideIcons.mapPin`, or `LucideIcons.receipt`).
        - **Right Tab (Team/Approver)**: `l10n?.tabTeamApprovals ?? 'Persetujuan Tim'` (Icon: `LucideIcons.users`).
        - *Never* use "Bawahan", hardcoded English "My Requests / Team Requests", or ad-hoc labels.
      - **Log & Monitoring Modules** (`attendance_logs`, `activity`):
        - **Left Tab (Self)**: `l10n?.tabSelf ?? 'Saya'` (Icon: `LucideIcons.user` or `LucideIcons.clipboardList`).
        - **Right Tab (Team)**: `l10n?.tabMyTeam ?? 'Tim Saya'` (Icon: `LucideIcons.users`).
      - **Formal Document Modules** (`warning_letter`):
        - **Left Tab**: `l10n?.tabWarningReceived ?? 'Surat Diterima'` (Icon: `LucideIcons.triangleAlert`).
        - **Right Tab**: `l10n?.tabWarningIssued ?? 'Diterbitkan'` (Icon: `LucideIcons.clipboardList`).
    - **Localization Mandate**: Tab titles MUST always be localized using `AppLocalizations` (`l10n?.tab... ?? 'Default Indonesian'`) with graceful fallback to prevent null errors in unit/widget tests.
    - **Unified Pill-Style TabBar**: Always style `TabBar` using the modern pill container (`height: 48–52`, `padding: 4`, `borderRadius: 14–16`, background `AppColors.darkSurfaceContainer` / `#F1F5F9`, indicator card with soft drop shadow, label in `brandColor` bold, unselected in `subtitleCol`).




