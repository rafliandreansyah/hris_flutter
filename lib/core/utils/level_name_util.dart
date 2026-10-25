/// Mengambil nama level/jenjang pegawai dari JSON API.
/// Mendukung objek `{ "name": "..." }` maupun string langsung. Null bila kosong.
String? parseLevelName(dynamic raw) {
  if (raw == null) return null;
  final value = raw is Map ? raw['name'] : raw;
  final name = value?.toString().trim() ?? '';
  return name.isEmpty ? null : name;
}
