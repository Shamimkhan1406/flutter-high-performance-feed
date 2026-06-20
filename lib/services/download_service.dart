import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  DownloadService._();

  static Future<String> downloadImage(String url) async {
  print("Downloading: $url");

  final dir =
      await getApplicationDocumentsDirectory();

  final fileName =
      DateTime.now()
          .millisecondsSinceEpoch
          .toString();

  final filePath =
      '${dir.path}/$fileName.png';

  final response = await Dio().get(
  url,
  options: Options(
    responseType: ResponseType.bytes,
    validateStatus: (_) => true,
  ),
);

  print("Status: ${response.statusCode}");

  return filePath;
}
}