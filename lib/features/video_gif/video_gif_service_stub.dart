import 'package:cross_file/cross_file.dart';

import 'video_gif_models.dart';
import 'video_gif_service.dart';

class UnsupportedVideoGifService implements VideoGifService {
  const UnsupportedVideoGifService();

  @override
  bool get isSupported => false;

  @override
  Future<VideoGifSource> loadVideo(XFile file) {
    throw UnsupportedError('현재 이 환경에서는 동영상 GIF 변환을 지원하지 않아요.');
  }

  @override
  Future<GifConversionResult> createGif({
    required VideoGifSource source,
    required Duration startTime,
    required GifLengthOption length,
    required GifQualityOption quality,
    required void Function(double progress) onProgress,
    required bool Function() isCancelled,
  }) {
    throw UnsupportedError('현재 이 환경에서는 동영상 GIF 변환을 지원하지 않아요.');
  }

  @override
  Future<String> saveGif(GifConversionResult result) {
    throw UnsupportedError('현재 이 환경에서는 GIF 저장을 지원하지 않아요.');
  }
}
