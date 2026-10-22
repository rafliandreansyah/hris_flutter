import 'package:flutter/material.dart';

/// Observer rute global: dipakai halaman yang perlu tahu saat ia kembali menjadi
/// rute teratas (RouteAware.didPopNext), mis. Dashboard memuat ulang data.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
