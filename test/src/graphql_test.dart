import 'package:test/test.dart';
import 'package:network/src/model/network_request.dart';
import 'package:network/src/network_service.dart';

void main() {
  late NetworkService networkService;
  const baseUrl =
      'https://countries.trevorblades.com'; // Public GraphQL API for testing

  setUp(() {
    networkService = NetworkService(
      baseUrlBuilder: () async => baseUrl,
      enableLogging: true,
    );
  });

  group('GraphQL Queries', () {
    test('should successfully fetch countries data', () async {
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
      final response = await networkService
          .request<Map<String, dynamic>, Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json,
      );

      response.when(
        success: (data) {
          final countriesData = CountriesData.fromJson(data);
          expect(countriesData.countries, isNotEmpty);
          final firstCountry = countriesData.countries.first;
          expect(firstCountry.code, isNotNull);
          expect(firstCountry.name, isNotNull);
          expect(firstCountry.continent?.name, isNotNull);
        },
        failure: (error) {
          fail('Should not fail: $error');
        },
      );
    });

    test('should handle GraphQL errors correctly', () async {
      const invalidQuery = '''
        query {
          invalidField {
            name
          }
        }
      ''';

      final request = NetworkRequest.graphQl(
        invalidQuery,
        const {},
      );

      final response = await networkService
          .request<Map<String, dynamic>, Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json,
      );

      response.when(
        success: (data) {
          if (data['errors'] != null) {
            // GraphQL returns 200 even with errors, but includes an errors array
            expect(data['errors'], isNotEmpty);
          } else {
            fail('Should not succeed with invalid query');
          }
        },
        failure: (error) {
          expect(error, isNotNull);
        },
      );
    });

    test('should handle variables in GraphQL query', () async {
      const query = '''
        query GetCountry(\$code: ID!) {
          country(code: \$code) {
            name
            continent {
              name
            }
          }
        }
      ''';

      final request = NetworkRequest.graphQl(
        query,
        {'code': 'US'},
      );

      final response = await networkService
          .request<Map<String, dynamic>, Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json,
      );

      response.when(
        success: (data) {
          final countryData = CountryData.fromJson(data);
          expect(countryData.country?.name, 'United States');
          expect(countryData.country?.continent?.name, 'North America');
        },
        failure: (error) {
          fail('Should not fail: $error');
        },
      );
    });

    test('should handle null response gracefully', () async {
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
        {'code': 'INVALID'},
      );

      final response = await networkService
          .request<Map<String, dynamic>, Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json,
      );

      response.when(
        success: (data) {
          final countryData = CountryData.fromJson(data);
          expect(countryData.country, isNull);
        },
        failure: (error) {
          fail('Should not fail: $error');
        },
      );
    });
  });
}

class CountriesData {
  final List<Country> countries;

  CountriesData({required this.countries});

  factory CountriesData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final countriesList = data['countries'] as List<dynamic>;
    return CountriesData(
      countries: countriesList
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CountryData {
  final Country? country;

  CountryData({required this.country});

  factory CountryData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final countryJson = data['country'];
    return CountryData(
      country: countryJson != null 
          ? Country.fromJson(countryJson as Map<String, dynamic>)
          : null,
    );
  }
}

class Country {
  final String? code;
  final String? name;
  final Continent? continent;

  Country({
    required this.code,
    required this.name,
    this.continent,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] as String?,
      name: json['name'] as String?,
      continent: json['continent'] != null
          ? Continent.fromJson(json['continent'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Continent {
  final String? name;

  Continent({required this.name});

  factory Continent.fromJson(Map<String, dynamic> json) {
    return Continent(
      name: json['name'] as String?,
    );
  }
}
