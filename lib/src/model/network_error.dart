enum NetworkErrorType {
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  cancelled,
  other,
  parsing,
}

class NetworkError {
  final NetworkErrorType type;
  final String message;

  NetworkError({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}
