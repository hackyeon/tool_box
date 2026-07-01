import 'dart:typed_data';

enum GifLengthOption {
  one(1, '1초'),
  three(3, '3초'),
  five(5, '5초');

  const GifLengthOption(this.seconds, this.label);

  final int seconds;
  final String label;

  Duration get duration => Duration(seconds: seconds);
}

enum GifQualityOption {
  low(
    label: '낮음',
    description: '작은 용량, 빠른 변환',
    maxWidth: 240,
    framesPerSecond: 6,
    thumbnailQuality: 68,
    colorCount: 96,
    samplingFactor: 22,
  ),
  medium(
    label: '보통',
    description: '메신저 공유용 추천',
    maxWidth: 360,
    framesPerSecond: 8,
    thumbnailQuality: 78,
    colorCount: 160,
    samplingFactor: 14,
  ),
  high(
    label: '높음',
    description: '선명하지만 용량 증가',
    maxWidth: 480,
    framesPerSecond: 12,
    thumbnailQuality: 88,
    colorCount: 256,
    samplingFactor: 8,
  );

  const GifQualityOption({
    required this.label,
    required this.description,
    required this.maxWidth,
    required this.framesPerSecond,
    required this.thumbnailQuality,
    required this.colorCount,
    required this.samplingFactor,
  });

  final String label;
  final String description;
  final int maxWidth;
  final int framesPerSecond;
  final int thumbnailQuality;
  final int colorCount;
  final int samplingFactor;
}

class VideoGifSource {
  const VideoGifSource({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    required this.duration,
    required this.width,
    required this.height,
    this.warningMessage,
  });

  final String name;
  final String path;
  final int sizeInBytes;
  final Duration duration;
  final int width;
  final int height;
  final String? warningMessage;

  bool get canCreateGif {
    return path.isNotEmpty &&
        duration >= const Duration(seconds: 1) &&
        width > 0 &&
        height > 0 &&
        warningMessage == null;
  }

  double get aspectRatio {
    if (height == 0) {
      return 1;
    }
    return width / height;
  }
}

class GifConversionResult {
  const GifConversionResult({
    required this.bytes,
    required this.fileName,
    required this.sizeInBytes,
    required this.duration,
    required this.quality,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String fileName;
  final int sizeInBytes;
  final Duration duration;
  final GifQualityOption quality;
  final int width;
  final int height;
}

class VideoGifConversionCancelled implements Exception {
  const VideoGifConversionCancelled();
}
