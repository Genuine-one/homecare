/// KLE HOMECARE — Custom Exceptions
/// Thrown by the data layer; caught and converted to Failures in repositories.

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => 'UnauthorizedException: Session expired';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'No internet connection'});
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final Map<String, String> errors;
  const ValidationException({required this.errors});
  @override
  String toString() => 'ValidationException: $errors';
}
