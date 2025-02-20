import 'package:test/test.dart';
import 'package:network/src/model/network_request.dart';
import 'package:network/src/network_service.dart';

// Remote Data Source following clean architecture
abstract class CountryRemoteDataSource {
  Future<Map<String, dynamic>> getCountries();
  Future<Map<String, dynamic>> getCountryByCode(String code);
}

class CountryRemoteDataSourceImpl implements CountryRemoteDataSource {
  final NetworkService networkService;
  final String baseUrl;

  CountryRemoteDataSourceImpl({
    required this.networkService,
    this.baseUrl = '/graphql',
  });

  @override
  Future<Map<String, dynamic>> getCountries() async {
    const query = '''
      query {
        countries {
          code
          name
          continent {
            name
          }
        }
      }
    ''';

    final request = NetworkRequest.graphQl(query, const {});
    final response = await networkService.request<Map<String, dynamic>, Map<String, dynamic>>(
      request: request,
      fromJson: (json) => json,
    );

    return response.when(
      success: (data) => data,
      failure: (error) => throw GraphQLException(error.toString()),
    );
  }

  @override
  Future<Map<String, dynamic>> getCountryByCode(String code) async {
    const query = '''
      query GetCountry(\$code: ID!) {
        country(code: \$code) {
          name
          code
          continent {
            name
          }
        }
      }
    ''';

    final request = NetworkRequest.graphQl(
      query,
      {'code': code},
    );

    final response = await networkService.request<Map<String, dynamic>, Map<String, dynamic>>(
      request: request,
      fromJson: (json) => json,
    );

    return response.when(
      success: (data) => data,
      failure: (error) => throw GraphQLException(error.toString()),
    );
  }
}

class GraphQLException implements Exception {
  final String message;
  GraphQLException(this.message);

  @override
  String toString() => message;
}

void main() {
  late NetworkService networkService;
  late CountryRemoteDataSource dataSource;
  const baseUrl = 'https://countries.trevorblades.com';

  setUp(() {
    networkService = NetworkService(
      baseUrlBuilder: () async => baseUrl,
      enableLogging: true,
    );
    dataSource = CountryRemoteDataSourceImpl(networkService: networkService);
  });

  group('CountryRemoteDataSource', () {
    test('getCountries returns raw data successfully', () async {
      final result = await dataSource.getCountries();
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['data'], isNotNull);
      expect(result['data']['countries'], isA<List>());
    });

    test('getCountryByCode returns raw data successfully', () async {
      const countryCode = 'US';
      final result = await dataSource.getCountryByCode(countryCode);
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['data'], isNotNull);
      expect(result['data']['country'], isA<Map<String, dynamic>>());
      expect(result['data']['country']['code'], countryCode);
    });

    test('getCountryByCode throws exception for invalid code', () async {
      const invalidCode = 'INVALID';
      final result = await dataSource.getCountryByCode(invalidCode);
      
      expect(result['data']['country'], isNull);
    });
  });
}
