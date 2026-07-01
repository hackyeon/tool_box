import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'video_gif_models.dart';
import 'video_gif_service.dart';

class IoVideoGifService implements VideoGifService {
  const IoVideoGifService();

  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<VideoGifSource> loadVideo(XFile file) async {
    _ensureSupported();

    final videoFile = File(file.path);
    if (!videoFile.existsSync()) {
      throw const FormatException('동영상을 불러올 수 없어요. 다른 파일을 선택해주세요.');
    }

    final controller = VideoPlayerController.file(videoFile);
    try {
      await controller.initialize();
      final value = controller.value;
      if (!value.isInitialized || value.hasError) {
        throw FormatException(
          value.errorDescription ?? '동영상을 불러올 수 없어요. 다른 파일을 선택해주세요.',
        );
      }

      final size = value.size;
      final duration = value.duration;
      final fileSize = await videoFile.length();
      final warningMessage = _warningForVideo(duration, size);

      return VideoGifSource(
        name: _fileName(file),
        path: file.path,
        sizeInBytes: fileSize,
        duration: duration,
        width: size.width.round(),
        height: size.height.round(),
        warningMessage: warningMessage,
      );
    } finally {
      await controller.dispose();
    }
  }

  @override
  Future<GifConversionResult> createGif({
    required VideoGifSource source,
    required Duration startTime,
    required GifLengthOption length,
    required GifQualityOption quality,
    required void Function(double progress) onProgress,
    required bool Function() isCancelled,
  }) async {
    _ensureSupported();

    if (!source.canCreateGif) {
      throw const FormatException('선택한 동영상을 GIF로 만들 수 없어요.');
    }
    if (startTime >= source.duration) {
      throw const FormatException('시작 시간이 동영상 길이를 초과할 수 없어요.');
    }

    final remaining = source.duration - startTime;
    final clipDuration = remaining < length.duration
        ? remaining
        : length.duration;
    if (clipDuration < const Duration(seconds: 1)) {
      throw const FormatException('GIF는 최소 1초 이상 구간을 선택해주세요.');
    }

    final frameCount = math.max(
      1,
      (clipDuration.inMilliseconds / 1000 * quality.framesPerSecond).round(),
    );
    final delayCentiseconds = math.max(
      2,
      (clipDuration.inMilliseconds / frameCount / 10).round(),
    );
    final encoder = image_lib.GifEncoder(
      repeat: 0,
      delay: delayCentiseconds,
      numColors: quality.colorCount,
      samplingFactor: quality.samplingFactor,
      dither: image_lib.DitherKernel.floydSteinberg,
    );

    int? frameWidth;
    int? frameHeight;

    for (var index = 0; index < frameCount; index += 1) {
      if (isCancelled()) {
        throw const VideoGifConversionCancelled();
      }

      final timeMs = _frameTimeMs(
        startTime: startTime,
        clipDuration: clipDuration,
        frameCount: frameCount,
        index: index,
        sourceDuration: source.duration,
      );
      final frameBytes = await VideoThumbnail.thumbnailData(
        video: source.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: quality.maxWidth,
        timeMs: timeMs,
        quality: quality.thumbnailQuality,
      );

      if (frameBytes == null || frameBytes.isEmpty) {
        throw const FormatException('GIF 변환에 실패했어요. 다시 시도해주세요.');
      }

      final frame = image_lib.decodeImage(frameBytes);
      if (frame == null) {
        throw const FormatException('GIF 변환에 실패했어요. 다시 시도해주세요.');
      }

      final normalizedFrame = _normalizeFrame(
        image_lib.bakeOrientation(frame),
        width: frameWidth,
        height: frameHeight,
      );
      frameWidth ??= normalizedFrame.width;
      frameHeight ??= normalizedFrame.height;

      encoder.addFrame(normalizedFrame, duration: delayCentiseconds);
      onProgress((index + 1) / frameCount);
      await Future<void>.delayed(Duration.zero);
    }

    if (isCancelled()) {
      throw const VideoGifConversionCancelled();
    }

    final bytes = encoder.finish();
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('GIF 변환에 실패했어요. 다시 시도해주세요.');
    }

    return GifConversionResult(
      bytes: bytes,
      fileName: _resultFileName(source.name),
      sizeInBytes: bytes.length,
      duration: clipDuration,
      quality: quality,
      width: frameWidth ?? 0,
      height: frameHeight ?? 0,
    );
  }

  @override
  Future<String> saveGif(GifConversionResult result) async {
    _ensureSupported();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${result.fileName}');
    await file.writeAsBytes(result.bytes, flush: true);

    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw const FormatException('GIF 저장에 실패했어요. 저장 공간이나 권한을 확인해주세요.');
      }
    }

    try {
      await Gal.putImage(file.path);
    } on GalException catch (error) {
      throw FormatException(_galleryErrorMessage(error));
    }

    return '사진 앱/갤러리';
  }

  void _ensureSupported() {
    if (!isSupported) {
      throw UnsupportedError('현재 이 기기에서는 동영상 GIF 변환을 지원하지 않아요.');
    }
  }

  String? _warningForVideo(Duration duration, Size size) {
    if (duration < const Duration(seconds: 1)) {
      return '동영상 길이가 너무 짧아요.';
    }
    if (size.width <= 0 || size.height <= 0) {
      return '동영상 해상도를 확인할 수 없어요.';
    }
    return null;
  }

  int _frameTimeMs({
    required Duration startTime,
    required Duration clipDuration,
    required int frameCount,
    required int index,
    required Duration sourceDuration,
  }) {
    final startMs = startTime.inMilliseconds;
    final stepMs = clipDuration.inMilliseconds / frameCount;
    final candidate = startMs + (stepMs * index).round();
    return candidate.clamp(0, math.max(0, sourceDuration.inMilliseconds - 1));
  }

  image_lib.Image _normalizeFrame(
    image_lib.Image frame, {
    required int? width,
    required int? height,
  }) {
    if (width == null || height == null) {
      return frame;
    }
    if (frame.width == width && frame.height == height) {
      return frame;
    }

    return image_lib.copyResize(
      frame,
      width: width,
      height: height,
      interpolation: image_lib.Interpolation.average,
    );
  }

  String _fileName(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final separatorIndex = file.path.lastIndexOf(Platform.pathSeparator);
    return separatorIndex >= 0
        ? file.path.substring(separatorIndex + 1)
        : file.path;
  }

  String _resultFileName(String sourceName) {
    final dotIndex = sourceName.lastIndexOf('.');
    final baseName = dotIndex > 0
        ? sourceName.substring(0, dotIndex)
        : sourceName;
    final safeBaseName = baseName.replaceAll(
      RegExp(r'[^a-zA-Z0-9가-힣_-]+'),
      '_',
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeBaseName}_gif_$timestamp.gif';
  }

  String _galleryErrorMessage(GalException error) {
    return switch (error.type) {
      GalExceptionType.accessDenied => 'GIF 저장에 실패했어요. 저장 공간이나 권한을 확인해주세요.',
      GalExceptionType.notEnoughSpace => '저장 공간이 부족해 GIF를 저장할 수 없어요.',
      GalExceptionType.notSupportedFormat => '지원하지 않는 GIF 형식이에요.',
      GalExceptionType.unexpected => 'GIF 저장에 실패했어요. 저장 공간이나 권한을 확인해주세요.',
    };
  }
}
