import 'package:cross_file/cross_file.dart';

import 'video_gif_models.dart';
import 'video_gif_service_factory_stub.dart'
    if (dart.library.io) 'video_gif_service_factory_io.dart';

abstract class VideoGifService {
  factory VideoGifService() => createVideoGifService();

  bool get isSupported;

  Future<VideoGifSource> loadVideo(XFile file);

  Future<GifConversionResult> createGif({
    required VideoGifSource source,
    required Duration startTime,
    required GifLengthOption length,
    required GifQualityOption quality,
    required void Function(double progress) onProgress,
    required bool Function() isCancelled,
  });

  Future<String> saveGif(GifConversionResult result);
}
