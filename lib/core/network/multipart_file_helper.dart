import 'package:dio/dio.dart';

/// Tipe media dari ekstensi nama file. Dipakai agar `contentType` eksplisit,
/// tidak bergantung pada tebakan Dio dari ekstensi (server memvalidasi magic bytes).
DioMediaType mediaTypeForFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return DioMediaType('image', 'jpeg');
    case 'png':
      return DioMediaType('image', 'png');
    case 'webp':
      return DioMediaType('image', 'webp');
    case 'pdf':
      return DioMediaType('application', 'pdf');
    default:
      return DioMediaType('application', 'octet-stream');
  }
}

/// Pengganti `MultipartFile.fromFile` dengan `contentType` eksplisit.
Future<MultipartFile> multipartFromPath(String path, {String? filename}) {
  return MultipartFile.fromFile(
    path,
    filename: filename,
    contentType: mediaTypeForFileName(filename ?? path),
  );
}

/// Pengganti `MultipartFile.fromBytes` dengan `contentType` eksplisit.
MultipartFile multipartFromBytes(List<int> bytes, {required String filename}) {
  return MultipartFile.fromBytes(
    bytes,
    filename: filename,
    contentType: mediaTypeForFileName(filename),
  );
}
