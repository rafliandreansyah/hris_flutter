---
name: flutter-bloc-patterns
description: Advanced Flutter BLoC architectural patterns, event transformers (debounce, droppable, restartable), BlocObserver, state modeling with Equatable, and UI widgets (BlocBuilder, BlocListener, BlocConsumer, BlocSelector). Apply when designing scalable BLoC state management.
---

# Advanced Flutter BLoC Patterns & Best Practices

Panduan arsitektur dan pola lanjutan untuk implementasi state management menggunakan `flutter_bloc` di Flutter.

---

## 1. Bloc vs Cubit: Kapan Menggunakan Apa?

- **Gunakan Cubit** untuk alur sederhana tanpa event stream kompleks (contoh: ThemeCubit, VisibilityToggle, Counter).
- **Gunakan BLoC** untuk alur dengan event stream, debounce pencarian, pagination, buffering, cancellation, atau audit event logging (seperti seluruh fitur domain aplikasi HRIS: Attendance, Activity, Leave, Auth).

---

## 2. Event Transformers (Concurrency & Debounce)

Gunakan `package:bloc_concurrency` dan `stream_transform` untuk mengontrol bagaimana event dieksekusi:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(const SearchState()) {
    // 1. Debounce untuk live search (mencegah spam API)
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );

    // 2. Droppable untuk pagination load more (abaikan event baru jika request sebelumnya belum selesai)
    on<LoadMoreRequested>(
      _onLoadMore,
      transformer: droppable(),
    );

    // 3. Restartable untuk refresh (batalkan request sebelumnya jika request baru datang)
    on<RefreshRequested>(
      _onRefresh,
      transformer: restartable(),
    );
  }
}
```

---

## 3. Aturan Konsumsi Context di Widget

| Sintaks | Kapan Digunakan | Lokasi Penggunaan |
| :--- | :--- | :--- |
| `context.read<B>()` | Mengambil instance BLoC untuk memicu event (`.add()`) | Hanya di event handler / callback (`onPressed`, `onTap`, `initState`) |
| `context.watch<B>()` | Mendengarkan perubahan seluruh state dan me-rebuild widget | Di dalam method `build()` jika seluruh subtree butuh re-render |
| `context.select<B, R>()` | Hanya me-rebuild widget jika properti tertentu berubah | Di dalam method `build()` untuk widget granular (efisiensi render) |

> **PERINGATAN**: Jangan pernah memanggil `context.read<B>()` langsung di dalam method `build()` untuk merender data, karena `read` tidak mendengarkan perubahan state!

---

## 4. Pola UI Widget BLoC

- **`BlocBuilder<B, S>`**: Khusus merender widget berdasarkan state. Gunakan `buildWhen` untuk mencegah rebuild yang tidak perlu.
- **`BlocListener<B, S>`**: Khusus efek samping / one-time actions (navigasi, dialog, SnackBar). Gunakan `listenWhen`.
- **`BlocConsumer<B, S>`**: Kombinasi `builder` dan `listener` ketika satu widget perlu merender UI sekaligus menampilkan dialog/notifikasi saat error atau success.
- **`BlocSelector<B, S, T>`**: Mengambil satu bagian spesifik dari state untuk meminimalkan build cost widget:

```dart
BlocSelector<ActivityListBloc, ActivityListState, bool>(
  selector: (state) => state.isLoadingMore,
  builder: (context, isLoadingMore) {
    if (!isLoadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: CircularProgressIndicator(),
    );
  },
);
```

---

## 5. Global State Monitoring (`BlocObserver`)

Gunakan `BlocObserver` terpusat untuk logging transisi dan error secara global:

```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Logging transisi state jika diperlukan
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    // Kirim ke Crashlytics / logging service
  }
}
```
