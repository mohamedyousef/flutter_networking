import 'package:network/src/model/upload_file.dart';

class NetworkRequest {
  final String method;

  final String endpoint;
  final String endpointVersion;

  final Map<String, dynamic>? body;

  final Map<String, String> _queryParameters = {};
  final Map<String, String> _headers = {};

  NetworkRequest.get({
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  }) : method = 'GET';

  NetworkRequest.patch({
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  }) : method = 'PATCH';

  NetworkRequest.post({
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  }) : method = 'POST';

  NetworkRequest.put({
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  }) : method = 'PUT';

  NetworkRequest.options({
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  }) : method = 'OPTIONS';

  NetworkRequest.delete({
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  }) : method = 'DELETE';

  NetworkRequest.graphQl({
    required final String query,
    required final Map<String, dynamic> variables,
  })  : method = 'POST',
        body = {
          'query': query,
          'variables': variables,
        },
        endpoint = '/graphql',
        endpointVersion = '';

  NetworkRequest.graphQlUpload({
    required String query,
    required Map<String, dynamic> variables,
    required List<UploadFile> files,
  })  : method = 'POST',
        endpoint = '/graphql',
        endpointVersion = '',
        body = {
          'operations': {
            'query': query,
            'variables': variables,
          },
          'map': _createUploadMap(files),
          'files': <String, dynamic>{},
        } {
    for (var i = 0; i < files.length; i++) {
      (body!['files'] as Map<String, dynamic>)[i.toString()] =
          files[i].toMultipartFile();
    }
    addHeader('Content-Type', 'multipart/form-data');
  }

  static Map<String, List<String>> _createUploadMap(List<UploadFile> files) {
    final map = <String, List<String>>{};
    for (var i = 0; i < files.length; i++) {
      map[i.toString()] = ['variables.${files[i].fieldName}'];
    }
    return map;
  }

  NetworkRequest({
    required this.method,
    required this.endpoint,
    this.endpointVersion = '',
    this.body,
  });

  void addQueryParameter(String key, String value) {
    _queryParameters[key] = value;
  }

  void addHeader(String key, String value) {
    _headers[key] = value;
  }

  Map<String, dynamic> get queryParameters => _queryParameters;

  Map<String, String> get headers => _headers;
}
