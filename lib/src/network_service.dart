import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:network/src/create_refresh_access_token_options.dart';
import 'package:network/src/interceptor/access_token_interceptor.dart';
import 'package:network/src/interceptor/logging_intercepter.dart';
import 'package:network/src/json_parser.dart';
import 'package:network/src/model/graphql_response.dart';
import 'package:network/src/model/network_request.dart';
import 'package:network/src/model/network_response.dart';

import 'interceptor/header_interceptor.dart';
import 'logger.dart';
import 'model/network_error_type.dart';

typedef BaseUrlBuilder = Future<String> Function();
typedef OnHttpClientCreate = HttpClient Function();

class NetworkService {
  final JsonParser _jsonParser = JsonParser();

  final CreateRefreshAccessTokenOptions? createRefreshAccessTokenOptions;
  late Dio _dio;
  final BaseUrlBuilder baseUrlBuilder;
  final void Function()? onUnAuthorizedCallback;
  final bool enableLogging;

  NetworkService({
    required this.baseUrlBuilder,
    this.createRefreshAccessTokenOptions,
    this.onUnAuthorizedCallback,
    this.enableLogging = true,
    int connectTimeout = 8000,
    int sendTimeout = 8000,
    int receiveTimeout = 10000,
  }) {
    _dio = Dio();
    _dio.options.connectTimeout = Duration(milliseconds: connectTimeout);
    _dio.options.sendTimeout = Duration(milliseconds: sendTimeout);
    _dio.options.receiveTimeout = Duration(milliseconds: receiveTimeout);
    _initInterceptors();
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  void addHeaderInterceptor(HeaderInterceptor interceptor) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      interceptor.onHeaderRequest(options);
      handler.next(options);
    }));
  }

  void onHttpClientCreate(OnHttpClientCreate onHttpClientCreate) {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        onHttpClientCreate;
  }

  void _initInterceptors() {
    if (enableLogging) {
      addInterceptor(LoggingInterceptor(logger: logger));
    }

    if (createRefreshAccessTokenOptions != null) {
      addInterceptor(AccessTokenInterceptor(
        dio: _dio,
        createAccessTokenOptions: createRefreshAccessTokenOptions!,
      ));
    }
  }

  Future<NetworkResponse<T>> request<T extends Object, K>({
    required NetworkRequest request,
    K Function(Map<String, dynamic>)? fromJson,
  }) async {
    _dio.options.baseUrl = await baseUrlBuilder();
    try {
      final response = await _request(request);

      final dataObject = _jsonParser.parse<T, K>(response.data, fromJson);

      if (fromJson == null && dataObject == null) {
        return NetworkResponse.success(
          jsonParser: _jsonParser,
          statusCode: response.statusCode,
          rawData: response.data,
          dataOnSuccess: null,
        );
      }

      if (dataObject != null) {
        return NetworkResponse.success(
          jsonParser: _jsonParser,
          statusCode: response.statusCode,
          rawData: response.data,
          dataOnSuccess: dataObject,
        );
      } else {
        return NetworkResponse.failure(
          jsonParser: _jsonParser,
          statusCode: response.statusCode,
          rawData: response.data,
          errorType: NetworkErrorType.parsing,
        );
      }
    } on DioException catch (dioException) {
      if (dioException.response?.statusCode == 401) {
        onUnAuthorizedCallback?.call();
      }
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: dioException.response?.statusCode,
        rawData: dioException.response?.data,
        errorType: _getErrorType(dioException),
      );
    } on Error catch (e) {
      logger.e(e);
      logger.e(e.stackTrace);
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: null,
        rawData: null,
        errorType: NetworkErrorType.other,
      );
    }
  }

  Future<NetworkResponse<T>> executeGraphQLRequest<T>({
    required NetworkRequest request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final baseUrl = await baseUrlBuilder();
      final response = await _dio.request(
        baseUrl + request.endpoint,
        data: request.body,
        queryParameters: request.queryParameters,
        options: Options(
          method: request.method,
          headers: request.headers,
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      final graphQLResponse =
          GraphQLResponse<T>.fromJson(responseData, fromJson);
      final networkResponse = graphQLResponse.toNetworkResponse();
      networkResponse.ifHasError(
        (errorType) {
          if (errorType == NetworkErrorType.unauthorised) {
            onUnAuthorizedCallback?.call();
          }
        },
      );

      return networkResponse;
    } on DioException catch (dioException) {
      if (dioException.response?.statusCode == 401) {
        onUnAuthorizedCallback?.call();
      }
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: dioException.response?.statusCode,
        rawData: dioException.response?.data,
        errorType: _getErrorType(dioException),
      );
    } catch (error) {
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: null,
        rawData: error.toString(),
        errorType: NetworkErrorType.other,
      );
    }
  }

  Future<NetworkResponse<T>> executeGraphQLUpload<T>({
    required NetworkRequest request,
    required T Function(Map<String, dynamic>) fromJson,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final baseUrl = await baseUrlBuilder();
      final response = await _dio.request(
        baseUrl + request.endpoint,
        data: FormData.fromMap(request.body ?? {}),
        options: Options(
          method: request.method,
          headers: request.headers,
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress != null
            ? (count, total) => onProgress(count / total)
            : null,
      );

      final responseData = response.data as Map<String, dynamic>;
      final graphQLResponse =
          GraphQLResponse<T>.fromJson(responseData, fromJson);
      return graphQLResponse.toNetworkResponse();
    } on DioException catch (dioException) {
      if (dioException.response?.statusCode == 401) {
        onUnAuthorizedCallback?.call();
      }
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: dioException.response?.statusCode,
        rawData: dioException.response?.data,
        errorType: _getErrorType(dioException),
      );
    } catch (error) {
      return NetworkResponse.failure(
        jsonParser: _jsonParser,
        statusCode: null,
        rawData: error.toString(),
        errorType: NetworkErrorType.other,
      );
    }
  }

  Future<Response> _request(NetworkRequest request) {
    final options = Options(
      method: request.method,
      headers: request.headers,
    );

    return _dio.request(
      request.endpoint,
      data: request.body,
      queryParameters: request.queryParameters,
      options: options,
    );
  }

  NetworkErrorType _getErrorType(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkErrorType.badConnection;

      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
        return _getErrorTypeWhenHaveResponse(dioException.response?.statusCode);

      case DioExceptionType.cancel:
        return NetworkErrorType.cancel;

      case DioExceptionType.unknown:
        if (dioException.error is SocketException) {
          return NetworkErrorType.badConnection;
        } else {
          return NetworkErrorType.other;
        }
    }
  }

  NetworkErrorType _getErrorTypeWhenHaveResponse(int? statusCode) {
    if (statusCode == null) {
      return NetworkErrorType.other;
    }

    if (statusCode == 401) {
      return NetworkErrorType.unauthorised;
    } else if (statusCode == 403) {
      return NetworkErrorType.forbidden;
    } else if (statusCode == 404) {
      return NetworkErrorType.noData;
    } else if (statusCode == 422) {
      return NetworkErrorType.unprocessable;
    } else if (statusCode >= 500) {
      return NetworkErrorType.server;
    }

    return NetworkErrorType.other;
  }
}
