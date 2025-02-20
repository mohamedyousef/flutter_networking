import 'dart:io';
import 'package:dio/dio.dart';

class UploadFile {
  final File file;
  final String fieldName;
  final String? fileName;
  final String? contentType;

  UploadFile({
    required this.file,
    required this.fieldName,
    this.fileName,
    this.contentType,
  });

  MultipartFile toMultipartFile() {
    return MultipartFile.fromFileSync(
      file.path,
      filename: fileName ?? file.path.split('/').last,
      contentType: contentType != null ? _parseContentType(contentType!) : null,
    );
  }

  static DioMediaType _parseContentType(String contentType) {
    final parts = contentType.split('/');
    if (parts.length != 2) {
      throw FormatException('Invalid content type format: $contentType');
    }
    return DioMediaType(parts[0], parts[1]);
  }
}
