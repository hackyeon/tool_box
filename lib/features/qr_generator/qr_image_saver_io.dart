import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveQrPng(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$fileName';
  final file = XFile.fromData(bytes, mimeType: 'image/png', name: fileName);

  await file.saveTo(path);
  return path;
}
