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
    final errorMessage = firstError.message;
    final errorCode = firstError.extensions?['code'] as String?;

    if (errorCode == 'unauthorized' ||
        errorCode == 'unauthenticated' ||
        errorMessage.contains('Unauthorized') ||
        errorMessage.contains('Unauthenticated')) {
      return NetworkErrorType.unauthorised;
    } else if (errorCode == 'forbidden' || errorMessage.contains('Forbidden')) {
      return NetworkErrorType.forbidden;
    } else if (errorMessage.contains('Bad Request')) {
      return NetworkErrorType.badRequest;
    } else if (errorCode == 'not_found') {
      return NetworkErrorType.noData;
    } else if (errorCode == 'internal_server_error' || errorMessage.contains('Internal Server Error')) {
      return NetworkErrorType.server;
    } else {
      return NetworkErrorType.operation;
    }
  }
}
