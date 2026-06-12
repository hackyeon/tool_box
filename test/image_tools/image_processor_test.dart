import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tool_box/features/image_tools/image_processor.dart';

void main() {
  const processor = ImageProcessor();

  Uint8List pngBytes(int width, int height) {
    final image = image_lib.Image(width: width, height: height);
    return Uint8List.fromList(image_lib.encodePng(image));
  }

  test('inspect reads dimensions and byte size', () {
    final bytes = pngBytes(12, 8);

    final info = processor.inspect(bytes);

    expect(info.width, 12);
    expect(info.height, 8);
    expect(info.sizeInBytes, bytes.length);
  });

  test('process crops and resizes while preserving ratio', () async {
    final bytes = pngBytes(10, 8);

    final result = await processor.process(
      bytes,
      const ImageProcessSettings(
        outputFormat: ImageOutputFormat.png,
        quality: 80,
        cropRect: NormalizedCropRect(
          left: 0.2,
          top: 0.25,
          right: 0.8,
          bottom: 0.75,
        ),
        targetWidth: 3,
      ),
    );

    expect(result.info.width, 3);
    expect(result.info.height, 2);
    expect(result.format, ImageOutputFormat.png);
  });

  test('process rotates quarter turns', () async {
    final bytes = pngBytes(2, 3);

    final result = await processor.process(
      bytes,
      const ImageProcessSettings(
        outputFormat: ImageOutputFormat.png,
        quality: 80,
        rotateDegrees: 90,
      ),
    );

    expect(result.info.width, 3);
    expect(result.info.height, 2);
  });
}
