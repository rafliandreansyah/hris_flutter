/// Wrapper respons standar dari API backend Muratech HRIS.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic errors;
  final dynamic meta;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? (json['error'] == null),
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] ?? json['error'],
      meta: json['meta'] ?? json['pagination'],
    );
  }
}
