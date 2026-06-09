import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

Future<String> saveQrPng(Uint8List bytes, String fileName) async {
  final file = XFile.fromData(bytes, mimeType: 'image/png', name: fileName);

  await file.saveTo(fileName);
  return fileName;
}
