class JsonParser {
  T? parse<T, K>(dynamic data, T Function(Map<String, dynamic>)? fromJson) {
    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic> && fromJson != null) {
      return fromJson(data);
    }

    return data as T;
  }
}
