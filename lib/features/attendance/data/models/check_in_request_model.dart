class CheckInRequestModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? note;
  final String? type; // 'IN', 'OUT', 'BREAK_START', 'BREAK_END'

  const CheckInRequestModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.note,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (note != null) 'note': note,
      if (type != null) 'type': type,
    };
  }

  factory CheckInRequestModel.fromJson(Map<String, dynamic> json) {
    return CheckInRequestModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      note: json['note'] as String?,
      type: json['type'] as String?,
    );
  }
}
