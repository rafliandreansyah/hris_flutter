import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Event transformer untuk menunda (debounce) eksekusi event pencarian teks
/// dan membatalkan proses sebelumnya jika ada input baru sebelum durasi selesai (restartable / switchMap).
EventTransformer<Event> debounceRestartable<Event>([
  Duration duration = const Duration(milliseconds: 300),
]) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

/// Event transformer untuk menunda (debounce) eksekusi event secara sekuensial (asyncExpand).
EventTransformer<Event> debounceSequential<Event>([
  Duration duration = const Duration(milliseconds: 300),
]) {
  return (events, mapper) => events.debounce(duration).asyncExpand(mapper);
}
