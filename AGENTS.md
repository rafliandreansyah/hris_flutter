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
   - **Pagination (Load More)**: Use **`AppLoadingIndicator.small()`** at the bottom of the list.
   - **Single Spinner Widget**: Never use a raw `CircularProgressIndicator` (except inside `AppButton`). Always use **`AppLoadingIndicator`** (`lib/core/widgets/app_loading_indicator.dart`): `regular` 28dp / `small` 20dp, stroke 2.5, **no accompanying text** ("Memproses…", "Memuat…").
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
    - **Frame (`AppFilterSheetFrame`)**: Every filter bottom sheet MUST wrap its form in **`AppFilterSheetFrame`** (`lib/core/widgets/filter/app_filter_sheet_frame.dart`) for a consistent, spacious header & footer.
    - **Header**:
      - Title only (`AppTypography.titleMedium`, 18sp, w700) — no leading icon badge.
      - Close `IconButton` (`LucideIcons.x`) aligned on the same row as the title (replaces the old "Batal" button).
      - Trailing `Divider(height: 1)`.
    - **Organization Cascading (Company -> Department -> Position)**:
      - Always consume `OrganizationFilterBloc`.
      - Department and Position fields must be disabled (locked with `LucideIcons.lock`, opacity 0.6, and helper text "Pilih perusahaan terlebih dahulu") until a company is selected.
      - Selecting a company resets downstream selections and dispatches `OrganizationFilterCompanySelected`.
      - Selecting a department resets position and dispatches `OrganizationFilterDepartmentSelected`.
    - **Footer Actions** (rendered by `AppFilterSheetFrame`):
      - Row with two `AppButton` widgets at `height: 50`: "Reset" (`AppButtonVariant.outlined`, `leadingIcon: LucideIcons.rotateCcw`) and "Terapkan Filter" (`AppButtonVariant.primary`, `leadingIcon: LucideIcons.filter`).
13. **Required Form Field Asterisk Standards**:
    - **Mandatory Red Asterisk (`*`)**: For all required form input fields, form labels, section headers, or upload cards across all features, the mandatory asterisk indicator (`*`) MUST ALWAYS be styled in red (`AppColors.errorRed` / `AppColors.error`, e.g., `TextSpan(text: ' *', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold))`).
    - **AppTextField Standard**: `AppTextField` automatically renders the required asterisk (`*`) in red (either cleanly extracted from `label` containing `*` or when `isRequired: true`).
    - **Zero Plain Asterisks**: Never render a required asterisk `*` in the default label or onSurface text color.
14. **Request List Card Standard (`RequestCardHeader` & `RequestListCardFrame`)**:
    - **Compact List Cards**: Across all request modules (`attendance_request`, `leave`, `overtime`, `reimbursement`, `resignation`, `warning_letter`) and feeds (`activity`), list item cards MUST use **`RequestListCardFrame`** + **`RequestCardHeader`** (`lib/core/widgets/request_card_header.dart`): avatar, name, and job title only (department as fallback) with the status chip on the right. Body lines use `RequestCardInfoLine` / `RequestCardNote`.
    - **Keep Lists Short**: Show only the key data (type, date/time, duration/amount, short note). Do NOT show employee number, company, timezone, reference IDs or "View Details" links in list cards — the whole card is tappable and the full data lives on the detail screen.
    - **Request Status = Icon Only**: Request status (leave, overtime, attendance request, reimbursement, cash advance, resignation) is shown only as **`AppStatusIcon`** (`lib/core/widgets/app_status_icon.dart`) — colored icon with Tooltip + Semantics, no text — on both list cards and detail overview. Standard labels: Menunggu Persetujuan, Disetujui, Ditolak, Dibatalkan, Dicairkan, Selesai. `AppStatusChip` (no dot) remains for non-request statuses (asset, payroll, activity).
    - **Nothing Truncated**: Names and job titles in `RequestCardHeader` wrap to multiple lines; never cut employee data with a 1-line ellipsis.
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
17. **Menu Visibility & Functional Permission Standards (`GET /auth/menus` & `SecureStorageService`)**:
    - **Dual-Layer Access Control**: Always separate **Menu Visibility** (screens available in Dashboard Bento Grid) and **Functional Permissions** (actions, approval buttons, edit capabilities).
    - **Menu Visibility (`GET /auth/menus`)**: Dashboard Bento Grid (`QuickAccessGrid`) MUST dynamically filter items via `isMenuAvailable(item.code, item.title, state.menus)`. If a menu is disabled by company policy or individual revoke in the backend, it will not appear in the API and must be hidden cleanly without breaking the grid layout.
    - **Functional Permissions (`SecureStorageService.hasPermission`)**: For actions requiring specific authority (e.g. `approval.leave.action`, `activity.manage`, `warning_letter.create`), always query `SecureStorageService.instance.hasPermissionInMemory(permissionCode)` or `hasPermission(...)`.
    - **Context-Aware Approval Workflows**: On 2-tab approval screens, only enable approval/reject action dialogs if the user has the corresponding `approval.*.action` permission.
    - **403 Forbidden Feedback**: If a mutation returns 403 Forbidden, display the backend's localized error message via `AppDialogUtil.showError(context, message: e.message)`.
18. **Reusable Search Bar Standard (`AppSearchBar`)**:
    - **Single Source of Truth**: All search inputs across the application (Schedule, Expenses/Reimbursement, Asset, Resignation, Employee Directory, etc.) MUST use the global widget **`AppSearchBar`** (`lib/core/widgets/app_search_bar.dart`) rather than manually styling ad-hoc `TextField` inside colored container wrappers.
    - **Zero Solid Container Clutter**: Never wrap search fields in solid surface/white rectangular containers with hard bottom borders that clash with Scaffold backgrounds. Search bars must sit directly on the screen's background (`background` / `backgroundSubtle`), featuring their own clean `surfaceContainerLowest` card with subtle drop shadow and border radius (12).
    - **Consistent Suffix Interaction**: Automatically render an interactive clear (`x`) button when query text is present, and ensure automatic keyboard unfocus on outside taps via `onTapOutside`.
19. **Standard Requester & Approver Cards for Request Detail Screens (`INFORMASI PENGAJU` & `PEJABAT PENYETUJU`)**:
    - **Single Architectural Standard**: Across all request detail screens (`leave`, `overtime`, `attendance_requests`, `reimbursement`, `cash_advance`, etc.), both the Requester Profile ("INFORMASI PENGAJU") and Assigned Approver ("PEJABAT PENYETUJU") cards MUST strictly follow the unified Stitch M3 component structure:
      - **Reusable Implementation**: All module cards (`LeaveDetailEmployeeCard`, `OvertimeDetailApproverCard`, etc.) delegate to the global **`RequestDetailPersonCard`** (`lib/core/widgets/request_detail_person_card.dart`): avatar + name + position (2 lines), then a vertical info list (Perusahaan, Departemen, No. Pegawai, Email/Telepon) whose values wrap instead of being truncated.
      - **Contact Actions**: When the viewer is the approver (`isApprover`) or otherwise not the requester, pass `showContactActions: true` on the requester card to show Telepon / WhatsApp / Email buttons (via `ContactLauncherUtil`).
      - **Header Actions**: Detail screens never show separate link/share icons in the AppBar — use **`AppDetailMoreMenu`** (`lib/core/widgets/app_detail_more_menu.dart`) with `AppDetailMenuItem.share`, `AppDetailMenuItem.copyLink`, and destructive items such as "Hapus Pengajuan".
      - **Requester Card (`INFORMASI PENGAJU`)**:
        - Container: `width: double.infinity`, `padding: const EdgeInsets.all(AppSpacing.md)`, `borderRadius: BorderRadius.circular(16)`, `border: Border.all(color: borderCol, width: 1)`, background `cardBg`.
        - Section Title: `Text('INFORMASI PENGAJU', style: AppTypography.labelSmall.copyWith(color: subtitleCol, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8))`.
        - Spacing: `const SizedBox(height: 12)`.
        - Body: Global widget **`EmployeeInfoRow`** (`avatarSize: 44`, name, role/position, department, company, employeeId/nip, resolved avatar url, initials).
      - **Approver Card (`PEJABAT PENYETUJU`)**:
        - Container: Identical token decoration (`padding: AppSpacing.md`, `borderRadius: 16`, `border: borderCol`, `color: cardBg`).
        - Section Title: `Text('PEJABAT PENYETUJU', style: AppTypography.labelSmall.copyWith(color: subtitleCol, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8))`.
        - Spacing: `const SizedBox(height: 12)`.
        - Body: Global widget **`EmployeeInfoRow`** representing the assigned approver (or subtle placeholder text if approver has not been assigned).
        - Notes / Reason Callout Box: When notes/rejection reason is present, display a nested container with `padding: 12`, `borderRadius: 10`, `border: Border(left: BorderSide(color: isRejected ? AppColors.errorRed : brandColor, width: 3))`, icon `LucideIcons.messageSquare` (or `alertTriangle` if rejected), and italic note text in `AppTypography.bodySmall`.
        - Visibility: If status is still pending and no approver has been assigned/approved yet and no notes exist, auto-hide the approver card.
    - **Zero Ad-hoc Profiling**: Never build manual or ad-hoc `Row` / `AppAvatar` profile containers in request detail screens. Always implement or reuse the dedicated standard cards (`LeaveDetailEmployeeCard` / `LeaveDetailApproverCard`, `OvertimeDetailEmployeeCard` / `OvertimeDetailApproverCard`, `AttendanceRequestEmployeeCard` / `AttendanceRequestApproverCard`, `ExpenseDetailEmployeeCard` / `ExpenseDetailApproverCard`).
20. **Header, ID & Media Standards**:
    - **No AppBar Subtitles**: AppBar titles are a single `Text`. Never add a subtitle line under the title; if the subtitle carried data (e.g. the attendance date), render it in the page content instead.
    - **Never Show Internal IDs**: Do not display database IDs/UUIDs (request IDs, document IDs, `employee.id` fallbacks) anywhere in the UI or in share texts. Human-readable numbers (employee number, reference number) are fine.
    - **Media Heights**: Photo previews in forms/details use at least 200–260dp (`AppPhotoPickerCard`, `AppImageThumbnailPreview` default 220) and maps at least 220dp (`AppRealtimeMapCard` default 220).
    - **Timezone Display**: Show the IANA name as-is via `AppDateUtil.timezoneLabel` (e.g. `Asia/Jakarta`); **never** abbreviate to WIB/WITA/WIT. Fallback is `AppDateUtil.defaultTimezone` (`Asia/Jakarta`).
    - **Human Error Messages**: Never show `e.toString()` / `'$e'` to users. Use **`AppErrorMessage.from(e)`** (`lib/core/utils/app_error_message.dart`) — API messages pass through, network/timeout/unknown errors become friendly Indonesian text. Device authentication errors (`LocalAuthException`) are mapped in `BiometricService`.
    - **Indonesian UI Text**: Screen titles, statuses, and labels are Indonesian (add keys to `app_id.arb` + `app_en.arb` for titles, use `l10n?.key ?? 'Default Indonesia'`). No mixed English like "Clock In", "On Time", "Pending", "Request Detail".
    - **Employee Level**: Person cards show `level` when present (`RequestDetailPersonCard(level: …)`), hidden when empty.
    - **Delete Own Request**: Leave, overtime, attendance request, reimbursement and cash advance can be deleted by the owner while still pending, via the `AppDetailMoreMenu` "Hapus Pengajuan" item.

