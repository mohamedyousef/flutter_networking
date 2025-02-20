class GraphQLError {
  final String message;
  final List<GraphQLLocation>? locations;
  final List<String>? path;
  final Map<String, dynamic>? extensions;

  GraphQLError({
    required this.message,
    this.locations,
    this.path,
    this.extensions,
  });

  factory GraphQLError.fromJson(Map<String, dynamic> json) {
    return GraphQLError(
      message: json['message'] as String,
      locations: json['locations'] != null
          ? (json['locations'] as List)
              .map((e) => GraphQLLocation.fromJson(e))
              .toList()
          : null,
      path: json['path'] != null
          ? (json['path'] as List).map((e) => e.toString()).toList()
          : null,
      extensions: json['extensions'] as Map<String, dynamic>?,
    );
  }
}

class GraphQLLocation {
  final int line;
  final int column;

  GraphQLLocation({required this.line, required this.column});

  factory GraphQLLocation.fromJson(Map<String, dynamic> json) {
    return GraphQLLocation(
      line: json['line'] as int,
      column: json['column'] as int,
    );
  }
}
