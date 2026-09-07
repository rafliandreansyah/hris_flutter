# AGENTS.md - Project Rules & Guidelines for HRIS Flutter

## 🚀 Core Architecture Guidelines
1. **State Management**: Always use **`flutter_bloc`** and **`equatable`** for all state management across the project (`activity`, `employee`, `auth`, `dashboard`, etc.).
2. **Clean Architecture**:
   - Maintain clear separation: Presentation (Pages, Widgets, BLoC) -> Domain (Repository Interfaces) -> Data (Datasources, Repository Implementations, Models).
   - No direct `setState` for network calls, data fetching, or business logic.
3. **Master Data & Caching**:
   - Master data (such as organization filters: companies, departments, positions) should be managed via dedicated BLoCs with in-memory caching to avoid redundant API requests.
4. **Testing Standards**:
   - Every BLoC must have comprehensive unit tests using standard `test` and `bloc_test` patterns.
   - Maintain 100% passing rate across all widget and unit test suites.
