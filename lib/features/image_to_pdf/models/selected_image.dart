import 'dart:typed_data';

class SelectedImage {
  final String name;
  final Uint8List bytes;

  const SelectedImage({
    required this.name,
    required this.bytes,
  });
}