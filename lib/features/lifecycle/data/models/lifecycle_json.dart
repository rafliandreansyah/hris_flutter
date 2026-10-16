/// Helper parsing JSON untuk model lifecycle (tanggal kalender `YYYY-MM-DD` & timestamp ISO).
DateTime? lcDate(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v);
}

double? lcDouble(dynamic v) => v is num ? v.toDouble() : null;

int lcInt(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

List<Map<String, dynamic>> lcList(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<Map<String, dynamic>>().toList();
}

/// Label status/tipe (Indonesia), konsisten dengan web.
const Map<String, String> lcEvaluationStatusLabels = {
  'draft': 'Menunggu penilaian',
  'revision_requested': 'Perlu revisi',
  'submitted': 'Menunggu HR',
  'hr_reviewed': 'Ditinjau HR',
  'decided': 'Keputusan ditetapkan',
  'executed': 'Selesai',
  'canceled': 'Dibatalkan',
};

const Map<String, String> lcEvaluationTypeLabels = {
  'probation': 'Evaluasi Masa Percobaan',
  'contract_renewal': 'Evaluasi Perpanjangan Kontrak',
  'periodic': 'Evaluasi Berkala',
};

const Map<String, String> lcDecisionLabels = {
  'pass_probation': 'Lulus masa percobaan',
  'extend_probation': 'Perpanjang masa percobaan',
  'fail_probation': 'Tidak lulus masa percobaan',
  'convert_permanent': 'Diangkat menjadi karyawan tetap',
  'extend_contract': 'Kontrak diperpanjang',
  'end_contract': 'Kontrak tidak diperpanjang',
};

String lcLabel(Map<String, String> map, String? key) =>
    key == null ? '-' : (map[key] ?? key);
