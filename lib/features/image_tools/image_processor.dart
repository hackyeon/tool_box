import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as image_lib;

enum ImageOutputFormat {
  jpg('JPG', 'jpg', 'image/jpeg'),
  png('PNG', 'png', 'image/png'),
  webp('WEBP', 'webp', 'image/webp');

  const ImageOutputFormat(this.label, this.extension, this.mimeType);

  final String label;
  final String extension;
  final String mimeType;
}

class ImageFileInfo {
  const ImageFileInfo({
    required this.width,
    required this.height,
    required this.sizeInBytes,
  });

  final int width;
  final int height;
  final int sizeInBytes;

  double get aspectRatio => width / height;
}

class NormalizedCropRect {
  const NormalizedCropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  const NormalizedCropRect.full() : left = 0, top = 0, right = 1, bottom = 1;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;

  double get height => bottom - top;

  bool get isFullImage {
    return left <= 0 && top <= 0 && right >= 1 && bottom >= 1;
  }

  NormalizedCropRect clamped() {
    final clampedLeft = left.clamp(0.0, 1.0);
    final clampedTop = top.clamp(0.0, 1.0);
    final clampedRight = right.clamp(0.0, 1.0);
    final clampedBottom = bottom.clamp(0.0, 1.0);

    return NormalizedCropRect(
      left: math.min(clampedLeft, clampedRight),
      top: math.min(clampedTop, clampedBottom),
      right: math.max(clampedLeft, clampedRight),
      bottom: math.max(clampedTop, clampedBottom),
    );
  }
}

class ImageProcessSettings {
  const ImageProcessSettings({
    required this.outputFormat,
    required this.quality,
    this.targetWidth,
    this.targetHeight,
    this.maintainAspectRatio = true,
    this.cropRect,
    this.rotateDegrees = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  final ImageOutputFormat outputFormat;
  final int quality;
  final int? targetWidth;
  final int? targetHeight;
  final bool maintainAspectRatio;
  final NormalizedCropRect? cropRect;
  final int rotateDegrees;
  final bool flipHorizontal;
  final bool flipVertical;
}

class ImageProcessResult {
  const ImageProcessResult({
    required this.bytes,
    required this.info,
    required this.format,
  });

  final Uint8List bytes;
  final ImageFileInfo info;
  final ImageOutputFormat format;
}

class ImageProcessor {
  const ImageProcessor();

  ImageFileInfo inspect(Uint8List bytes) {
    final image = _decode(bytes);

    return ImageFileInfo(
      width: image.width,
      height: image.height,
      sizeInBytes: bytes.length,
    );
  }

  Future<ImageProcessResult> process(
    Uint8List bytes,
    ImageProcessSettings settings,
  ) async {
    var image = _decode(bytes);

    final cropRect = settings.cropRect?.clamped();
    if (cropRect != null && !cropRect.isFullImage) {
      image = _crop(image, cropRect);
    }

    final targetWidth = settings.targetWidth;
    final targetHeight = settings.targetHeight;
    if (targetWidth != null || targetHeight != null) {
      image = image_lib.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        maintainAspect: settings.maintainAspectRatio,
        interpolation: image_lib.Interpolation.average,
      );
    }

    if (settings.flipHorizontal) {
      image = image_lib.flipHorizontal(image);
    }

    if (settings.flipVertical) {
      image = image_lib.flipVertical(image);
    }

    final normalizedRotation = settings.rotateDegrees % 360;
    if (normalizedRotation != 0) {
      image = image_lib.copyRotate(image, angle: normalizedRotation);
    }

    final encodedBytes = await _encode(image, settings);

    return ImageProcessResult(
      bytes: encodedBytes,
      info: ImageFileInfo(
        width: image.width,
        height: image.height,
        sizeInBytes: encodedBytes.length,
      ),
      format: settings.outputFormat,
    );
  }

  image_lib.Image _decode(Uint8List bytes) {
    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('지원하지 않는 이미지 파일입니다.');
    }

    return image_lib.bakeOrientation(decoded);
  }

  image_lib.Image _crop(
    image_lib.Image source,
    NormalizedCropRect normalizedRect,
  ) {
    final rect = normalizedRect.clamped();
    final x = (rect.left * source.width).round();
    final y = (rect.top * source.height).round();
    final width = math.max(1, (rect.width * source.width).round());
    final height = math.max(1, (rect.height * source.height).round());

    return image_lib.copyCrop(source, x: x, y: y, width: width, height: height);
  }

  Future<Uint8List> _encode(
    image_lib.Image image,
    ImageProcessSettings settings,
  ) async {
    return switch (settings.outputFormat) {
      ImageOutputFormat.jpg => Uint8List.fromList(
        image_lib.encodeJpg(image, quality: settings.quality),
      ),
      ImageOutputFormat.png => Uint8List.fromList(image_lib.encodePng(image)),
      ImageOutputFormat.webp => _encodeWebp(image, settings.quality),
    };
  }

  Future<Uint8List> _encodeWebp(image_lib.Image image, int quality) async {
    final pngBytes = Uint8List.fromList(image_lib.encodePng(image));

    return FlutterImageCompress.compressWithList(
      pngBytes,
      minWidth: image.width,
      minHeight: image.height,
      quality: quality,
      format: CompressFormat.webp,
      autoCorrectionAngle: false,
    );
  }
}
