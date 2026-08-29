import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Interceptor logging menggunakan PrettyDioLogger untuk memudahkan debugging HTTP request/response.
class LoggingInterceptor {
  static PrettyDioLogger get instance => PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      );
}
