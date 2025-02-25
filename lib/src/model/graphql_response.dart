import 'package:network/src/json_parser.dart';
import 'package:network/src/model/graphql_error.dart';
import 'package:network/src/model/network_error_type.dart';
import 'package:network/src/model/network_response.dart';

class GraphQLResponse<T> {
  final T? data;
  final List<GraphQLError>? errors;
  final Map<String, dynamic>? extensions;
  final JsonParser _jsonParser = JsonParser();
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  GraphQLResponse({
    this.data,
    this.errors,
    this.extensions,
  });

  factory GraphQLResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return GraphQLResponse(
      data: json['data'] != null ? fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: json['errors'] != null
          ? (json['errors'] as List).map((e) => GraphQLError.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      extensions: json['extensions'] as Map<String, dynamic>?,
    );
  }

  NetworkResponse<T> toNetworkResponse() {
    if (!hasErrors && data != null) {
      return NetworkResponse.success(
        jsonParser: _jsonParser,
        statusCode: 200,
        dataOnSuccess: data,
        rawData: {
          'data': data,
          if (extensions != null) 'extensions': extensions,
        },
      );
    } else {
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: 200, // GraphQL always returns 200 even with errors
        rawData: {
          if (data != null) 'data': data,
          if (errors != null) 'errors': errors,
          if (extensions != null) 'extensions': extensions,
        },
        errorType: _determineErrorType(errors),
      );
    }
  }

  NetworkErrorType _determineErrorType(List<GraphQLError>? errors) {
    if (errors == null || errors.isEmpty) {
      return NetworkErrorType.other;
    }

    // Check extensions for specific error codes
    final firstError = errors.first;
    final errorMessage = firstError.extensions?['message'] as String?;
    final errorCode = errorMessage ?? firstError.extensions?['code'] as String?;

    switch (errorCode?.toLowerCase()) {
      case 'unauthorized':
      case 'unauthenticated':
        return NetworkErrorType.unauthorised;
      case 'forbidden':
        return NetworkErrorType.forbidden;
      case 'validation':
      case 'bad_request':
        return NetworkErrorType.badRequest;
      case 'not_found':
        return NetworkErrorType.noData;
      case 'internal_server_error':
        return NetworkErrorType.server;
      default:
        return NetworkErrorType.operation;
    }
  }
}
