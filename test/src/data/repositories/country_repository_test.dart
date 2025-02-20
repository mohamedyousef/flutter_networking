import 'package:test/test.dart';
import 'package:network/src/model/network_request.dart';
import 'package:network/src/network_service.dart';

// Repository following clean architecture
class CountryRepository {
  final NetworkService networkService;
  final String baseUrl;

  CountryRepository({
    required this.networkService,
    this.baseUrl = '/graphql',
  });

  Future<List<Country>> getCountries() async {
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

    return response.when(
      success: (data) {
        final countriesData = CountriesData.fromJson(data);
        return countriesData.countries;
      },
      failure: (error) {
        throw GraphQLException(error.toString());
      },
    );
  }

  Future<Country> getCountryByCode(String code) async {
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

    final response = await networkService
        .request<Map<String, dynamic>, Map<String, dynamic>>(
      request: request,
      fromJson: (json) => json,
    );

    return response.when(
      success: (data) {
        if (data['data']['country'] == null) {
          throw GraphQLException('Country not found');
        }
        final countryData = CountryData.fromJson(data);
        return countryData.country;
      },
      failure: (error) {
        throw GraphQLException(error.toString());
      },
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
  late CountryRepository repository;
  const baseUrl = 'https://countries.trevorblades.com';

  setUp(() {
    networkService = NetworkService(
      baseUrlBuilder: () async => baseUrl,
      enableLogging: true,
    );
    repository = CountryRepository(networkService: networkService);
  });

  group('CountryRepository', () {
    test('getCountries returns list of countries', () async {
      final countries = await repository.getCountries();

      expect(countries, isNotEmpty);
      expect(countries.first.name, isNotEmpty);
      expect(countries.first.code, isNotEmpty);
      expect(countries.first.continent?.name, isNotEmpty);
    });

    test('getCountryByCode returns correct country', () async {
      const countryCode = 'US';
      final country = await repository.getCountryByCode(countryCode);

      expect(country.code, countryCode);
      expect(country.name, 'United States');
      expect(country.continent?.name, 'North America');
    });

    test('getCountryByCode throws exception for invalid code', () async {
      const invalidCode = 'INVALID';

      expect(
        () => repository.getCountryByCode(invalidCode),
        throwsA(isA<GraphQLException>()),
      );
    });
  });
}

// Domain Models
class Country {
  final String code;
  final String name;
  final Continent? continent;

  Country({
    required this.code,
    required this.name,
    this.continent,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] as String,
      name: json['name'] as String,
      continent: json['continent'] != null
          ? Continent.fromJson(json['continent'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Continent {
  final String name;

  Continent({required this.name});

  factory Continent.fromJson(Map<String, dynamic> json) {
    return Continent(
      name: json['name'] as String,
    );
  }
}

class CountriesData {
  final List<Country> countries;

  CountriesData({required this.countries});

  factory CountriesData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CountriesData(
      countries: (data['countries'] as List)
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CountryData {
  final Country country;

  CountryData({required this.country});

  factory CountryData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CountryData(
      country: Country.fromJson(data['country'] as Map<String, dynamic>),
    );
  }
}
