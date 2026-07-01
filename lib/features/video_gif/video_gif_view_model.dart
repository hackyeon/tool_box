import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'video_gif_models.dart';
import 'video_gif_service.dart';

class VideoGifViewModel extends ChangeNotifier {
  VideoGifViewModel({ImagePicker? imagePicker, VideoGifService? service})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _service = service ?? VideoGifService();

  final ImagePicker _imagePicker;
  final VideoGifService _service;

  VideoGifSource? _source;
  GifConversionResult? _result;
  GifLengthOption _length = GifLengthOption.three;
  GifQualityOption _quality = GifQualityOption.medium;
  Duration _startTime = Duration.zero;
  double _progress = 0;
  bool _isLoadingVideo = false;
  bool _isConverting = false;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _cancelRequested = false;
  String? _errorMessage;
  String? _noticeMessage;
  String? _savedPath;

  VideoGifSource? get source => _source;
  GifConversionResult? get result => _result;
  GifLengthOption get length => _length;
  GifQualityOption get quality => _quality;
  Duration get startTime => _startTime;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).clamp(0, 100).round();
  bool get isLoadingVideo => _isLoadingVideo;
  bool get isConverting => _isConverting;
  bool get isSaving => _isSaving;
  bool get isSharing => _isSharing;
  bool get isCancelling => _cancelRequested && _isConverting;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  String? get savedPath => _savedPath;
  bool get isSupported => _service.isSupported;
  bool get hasSource => _source != null;
  bool get hasResult => _result != null;

  bool get isBusy {
    return _isLoadingVideo || _isConverting || _isSaving || _isSharing;
  }

  bool get canCreateGif {
    final source = _source;
    return source != null &&
        source.canCreateGif &&
        canUseLength(_length) &&
        !_isLoadingVideo &&
        !_isConverting;
  }

  bool get canSave => _result != null && !_isSaving && !_isConverting;

  bool get canShare => _result != null && !_isSharing && !_isConverting;

  Duration get maxStartTime {
    final source = _source;
    if (source == null || source.duration <= _length.duration) {
      return Duration.zero;
    }

    return source.duration - _length.duration;
  }

  List<Duration> get quickStartTimes {
    const options = [
      Duration.zero,
      Duration(seconds: 3),
      Duration(seconds: 10),
    ];
    return options.where((option) => option <= maxStartTime).toList();
  }

  Future<void> pickVideo() async {
    if (!_service.isSupported) {
      _setError('현재 이 기기에서는 동영상 GIF 변환을 지원하지 않아요.');
      return;
    }

    final pickedFile = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }

    await addVideoFromFile(pickedFile);
  }

  Future<void> addVideoFromFile(XFile file) async {
    _isLoadingVideo = true;
    _clearMessages();
    _result = null;
    _savedPath = null;
    notifyListeners();

    try {
      final source = await _service.loadVideo(file);
      _source = source;
      _startTime = Duration.zero;
      _length = _defaultLengthFor(source.duration);
      _result = null;
      if (source.warningMessage != null) {
        _noticeMessage = source.warningMessage;
      }
    } catch (error) {
      _source = null;
      _setErrorSilently(_friendlyError(error));
    } finally {
      _isLoadingVideo = false;
      notifyListeners();
    }
  }

  void clearVideo() {
    _source = null;
    _result = null;
    _startTime = Duration.zero;
    _length = GifLengthOption.three;
    _quality = GifQualityOption.medium;
    _progress = 0;
    _savedPath = null;
    _clearMessages();
    notifyListeners();
  }

  void setStartTime(Duration startTime) {
    final clamped = _clampDuration(startTime, Duration.zero, maxStartTime);
    if (clamped == _startTime) {
      return;
    }

    _startTime = clamped;
    _invalidateResult();
    notifyListeners();
  }

  void setLength(GifLengthOption length) {
    if (_length == length || !canUseLength(length)) {
      return;
    }

    _length = length;
    _startTime = _clampDuration(_startTime, Duration.zero, maxStartTime);
    _invalidateResult();
    notifyListeners();
  }

  void setQuality(GifQualityOption quality) {
    if (_quality == quality) {
      return;
    }

    _quality = quality;
    _invalidateResult();
    notifyListeners();
  }

  bool canUseLength(GifLengthOption length) {
    final source = _source;
    return source == null || source.duration >= length.duration;
  }

  Future<void> createGif() async {
    final source = _source;
    if (source == null || !canCreateGif) {
      return;
    }

    _isConverting = true;
    _cancelRequested = false;
    _progress = 0;
    _result = null;
    _savedPath = null;
    _clearMessages();
    notifyListeners();

    try {
      final result = await _service.createGif(
        source: source,
        startTime: _startTime,
        length: _length,
        quality: _quality,
        onProgress: (progress) {
          _progress = progress.clamp(0, 1);
          notifyListeners();
        },
        isCancelled: () => _cancelRequested,
      );

      _result = result;
      _noticeMessage = 'GIF가 완성되었어요.';
    } on VideoGifConversionCancelled {
      _noticeMessage = 'GIF 만들기를 취소했어요.';
    } catch (error) {
      _setErrorSilently(_friendlyError(error));
    } finally {
      _isConverting = false;
      _cancelRequested = false;
      _progress = 0;
      notifyListeners();
    }
  }

  void cancelConversion() {
    if (!_isConverting || _cancelRequested) {
      return;
    }

    _cancelRequested = true;
    notifyListeners();
  }

  Future<void> saveResult() async {
    final result = _result;
    if (result == null || _isSaving) {
      return;
    }

    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      _savedPath = await _service.saveGif(result);
      _noticeMessage = 'GIF가 저장되었어요.';
    } catch (error) {
      _setErrorSilently(_friendlyError(error, saving: true));
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> shareResult() async {
    final result = _result;
    if (result == null || _isSharing) {
      return;
    }

    _isSharing = true;
    _clearMessages();
    notifyListeners();

    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            result.bytes,
            mimeType: 'image/gif',
            name: result.fileName,
          ),
        ],
        fileNameOverrides: [result.fileName],
      );
    } catch (error) {
      _setErrorSilently(_friendlyError(error));
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  void makeAgain() {
    _result = null;
    _savedPath = null;
    _clearMessages();
    notifyListeners();
  }

  GifLengthOption _defaultLengthFor(Duration duration) {
    if (duration >= GifLengthOption.three.duration) {
      return GifLengthOption.three;
    }
    if (duration >= GifLengthOption.one.duration) {
      return GifLengthOption.one;
    }
    return GifLengthOption.one;
  }

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    final milliseconds =
        value.inMilliseconds.clamp(
              min.inMilliseconds,
              math.max(min.inMilliseconds, max.inMilliseconds),
            )
            as int;
    return Duration(milliseconds: milliseconds);
  }

  void _invalidateResult() {
    _result = null;
    _savedPath = null;
    _clearMessages();
  }

  void _setError(String message) {
    _setErrorSilently(message);
    notifyListeners();
  }

  void _setErrorSilently(String message) {
    _errorMessage = message;
    _noticeMessage = null;
  }

  void _clearMessages() {
    _errorMessage = null;
    _noticeMessage = null;
  }

  String _friendlyError(Object error, {bool saving = false}) {
    if (error is FormatException) {
      return error.message;
    }
    if (error is UnsupportedError) {
      return error.message ?? '현재 이 기기에서는 동영상 GIF 변환을 지원하지 않아요.';
    }
    if (saving) {
      return 'GIF 저장에 실패했어요. 저장 공간이나 권한을 확인해주세요.';
    }
    return 'GIF 변환에 실패했어요. 동영상 길이나 파일 형식을 확인해주세요.';
  }
}
