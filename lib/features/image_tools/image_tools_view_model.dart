import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'image_processor.dart';

enum CropAspectOption {
  none('없음', null),
  free('자유', null),
  square('1:1', 1),
  fourThree('4:3', 4 / 3),
  sixteenNine('16:9', 16 / 9),
  nineSixteen('9:16', 9 / 16);

  const CropAspectOption(this.label, this.aspectRatio);

  final String label;
  final double? aspectRatio;

  bool get isEnabled => this != CropAspectOption.none;
}

class ResizePreset {
  const ResizePreset({
    required this.label,
    required this.width,
    required this.height,
  });

  final String label;
  final int width;
  final int height;
}

class ImageToolImage {
  const ImageToolImage({
    required this.name,
    required this.bytes,
    required this.info,
  });

  final String name;
  final Uint8List bytes;
  final ImageFileInfo info;
}

class ImageToolsViewModel extends ChangeNotifier {
  ImageToolsViewModel({ImagePicker? imagePicker, ImageProcessor? processor})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _processor = processor ?? const ImageProcessor();

  static const qualityOptions = [100, 90, 80, 70];
  static const resizePresets = [
    ResizePreset(label: 'SNS', width: 1080, height: 1080),
    ResizePreset(label: '블로그', width: 1920, height: 1080),
    ResizePreset(label: '문서첨부', width: 1280, height: 720),
  ];

  final ImagePicker _imagePicker;
  final ImageProcessor _processor;

  ImageToolImage? _source;
  ImageProcessResult? _result;
  bool _isProcessing = false;
  bool _isSharing = false;
  String? _errorMessage;

  int _quality = 80;
  ImageOutputFormat _outputFormat = ImageOutputFormat.jpg;
  bool _resizeEnabled = false;
  bool _maintainAspectRatio = true;
  int? _targetWidth;
  int? _targetHeight;
  CropAspectOption _cropAspect = CropAspectOption.none;
  NormalizedCropRect _cropRect = const NormalizedCropRect.full();
  int _rotationDegrees = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  ImageToolImage? get source => _source;
  ImageProcessResult? get result => _result;
  bool get isProcessing => _isProcessing;
  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;
  int get quality => _quality;
  ImageOutputFormat get outputFormat => _outputFormat;
  bool get resizeEnabled => _resizeEnabled;
  bool get maintainAspectRatio => _maintainAspectRatio;
  int? get targetWidth => _targetWidth;
  int? get targetHeight => _targetHeight;
  CropAspectOption get cropAspect => _cropAspect;
  NormalizedCropRect get cropRect => _cropRect;
  int get rotationDegrees => _rotationDegrees;
  bool get flipHorizontal => _flipHorizontal;
  bool get flipVertical => _flipVertical;

  bool get hasSource => _source != null;
  bool get canProcess => hasSource && !_isProcessing;
  bool get canShare => _result != null && !_isProcessing && !_isSharing;

  int? get reductionPercent {
    final source = _source;
    final result = _result;
    if (source == null || result == null || source.info.sizeInBytes == 0) {
      return null;
    }

    final reduction = 1 - (result.info.sizeInBytes / source.info.sizeInBytes);
    return (reduction * 100).round();
  }

  Future<void> pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }

    await addImageFromFile(pickedFile);
  }

  Future<void> addImageFromFile(XFile file) async {
    _setBusyState(processing: true);

    try {
      final bytes = await file.readAsBytes();
      final info = _processor.inspect(bytes);

      _source = ImageToolImage(name: file.name, bytes: bytes, info: info);
      _outputFormat = _formatFromName(file.name);
      _resetEditsForImage(info);
      _clearResult();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _setBusyState(processing: false);
    }
  }

  void clearImage() {
    _source = null;
    _result = null;
    _errorMessage = null;
    _resetEditDefaults();
    notifyListeners();
  }

  void setQuality(int quality) {
    if (_quality == quality) {
      return;
    }

    _quality = quality;
    _invalidateResult();
  }

  void setOutputFormat(ImageOutputFormat format) {
    if (_outputFormat == format) {
      return;
    }

    _outputFormat = format;
    _invalidateResult();
  }

  void setResizeEnabled(bool enabled) {
    if (_resizeEnabled == enabled) {
      return;
    }

    _resizeEnabled = enabled;
    if (enabled && _source != null && _targetWidth == null) {
      _setWidthKeepingAspect(math.min(_source!.info.width, 1920));
    }
    _invalidateResult();
  }

  void setMaintainAspectRatio(bool enabled) {
    if (_maintainAspectRatio == enabled) {
      return;
    }

    _maintainAspectRatio = enabled;
    if (enabled && _targetWidth != null) {
      _setWidthKeepingAspect(_targetWidth!);
    }
    _invalidateResult();
  }

  void setTargetWidth(int? width) {
    _resizeEnabled = true;
    if (width == null || width <= 0) {
      _targetWidth = null;
      _invalidateResult();
      return;
    }

    if (_maintainAspectRatio) {
      _setWidthKeepingAspect(width);
    } else {
      _targetWidth = width;
    }
    _invalidateResult();
  }

  void setTargetHeight(int? height) {
    _resizeEnabled = true;
    if (height == null || height <= 0) {
      _targetHeight = null;
      _invalidateResult();
      return;
    }

    if (_maintainAspectRatio) {
      _setHeightKeepingAspect(height);
    } else {
      _targetHeight = height;
    }
    _invalidateResult();
  }

  void applyResizePreset(ResizePreset preset) {
    _resizeEnabled = true;
    _targetWidth = preset.width;
    _targetHeight = preset.height;
    _invalidateResult();
  }

  void setCropAspect(CropAspectOption aspect) {
    if (_cropAspect == aspect) {
      return;
    }

    _cropAspect = aspect;
    _cropRect = _initialCropRect(aspect);
    _invalidateResult();
  }

  void setCropRect(NormalizedCropRect rect) {
    _cropRect = rect.clamped();
    _invalidateResult();
  }

  void rotateLeft() {
    _rotationDegrees = (_rotationDegrees + 270) % 360;
    _invalidateResult();
  }

  void rotateRight() {
    _rotationDegrees = (_rotationDegrees + 90) % 360;
    _invalidateResult();
  }

  void rotateHalfTurn() {
    _rotationDegrees = (_rotationDegrees + 180) % 360;
    _invalidateResult();
  }

  void toggleFlipHorizontal() {
    _flipHorizontal = !_flipHorizontal;
    _invalidateResult();
  }

  void toggleFlipVertical() {
    _flipVertical = !_flipVertical;
    _invalidateResult();
  }

  Future<void> processImage() async {
    final source = _source;
    if (source == null || _isProcessing) {
      return;
    }

    _setBusyState(processing: true);

    try {
      final result = await _processor.process(
        source.bytes,
        ImageProcessSettings(
          outputFormat: _outputFormat,
          quality: _quality,
          targetWidth: _resizeEnabled ? _targetWidth : null,
          targetHeight: _resizeEnabled ? _targetHeight : null,
          maintainAspectRatio: _maintainAspectRatio,
          cropRect: _cropAspect.isEnabled ? _cropRect : null,
          rotateDegrees: _rotationDegrees,
          flipHorizontal: _flipHorizontal,
          flipVertical: _flipVertical,
        ),
      );

      _result = result;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _setBusyState(processing: false);
    }
  }

  Future<void> shareResult() async {
    final result = _result;
    if (result == null || _isSharing) {
      return;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    final fileName = _resultFileName();
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            result.bytes,
            mimeType: result.format.mimeType,
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  void _resetEditsForImage(ImageFileInfo info) {
    _quality = 80;
    _resizeEnabled = false;
    _maintainAspectRatio = true;
    _targetWidth = math.min(info.width, 1920);
    _targetHeight = (_targetWidth! / info.aspectRatio).round();
    _cropAspect = CropAspectOption.none;
    _cropRect = const NormalizedCropRect.full();
    _rotationDegrees = 0;
    _flipHorizontal = false;
    _flipVertical = false;
  }

  void _resetEditDefaults() {
    _quality = 80;
    _outputFormat = ImageOutputFormat.jpg;
    _resizeEnabled = false;
    _maintainAspectRatio = true;
    _targetWidth = null;
    _targetHeight = null;
    _cropAspect = CropAspectOption.none;
    _cropRect = const NormalizedCropRect.full();
    _rotationDegrees = 0;
    _flipHorizontal = false;
    _flipVertical = false;
  }

  void _setWidthKeepingAspect(int width) {
    final source = _source;
    _targetWidth = width;
    if (source == null) {
      return;
    }
    _targetHeight = math.max(1, (width / source.info.aspectRatio).round());
  }

  void _setHeightKeepingAspect(int height) {
    final source = _source;
    _targetHeight = height;
    if (source == null) {
      return;
    }
    _targetWidth = math.max(1, (height * source.info.aspectRatio).round());
  }

  NormalizedCropRect _initialCropRect(CropAspectOption aspect) {
    if (!aspect.isEnabled) {
      return const NormalizedCropRect.full();
    }

    final source = _source;
    if (source == null || aspect.aspectRatio == null) {
      return const NormalizedCropRect(
        left: 0.1,
        top: 0.1,
        right: 0.9,
        bottom: 0.9,
      );
    }

    const maxCoverage = 0.88;
    final normalizedAspectRatio = aspect.aspectRatio! / source.info.aspectRatio;
    var width = maxCoverage;
    var height = width / normalizedAspectRatio;

    if (height > maxCoverage) {
      height = maxCoverage;
      width = height * normalizedAspectRatio;
    }

    final left = (1 - width) / 2;
    final top = (1 - height) / 2;

    return NormalizedCropRect(
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
    ).clamped();
  }

  ImageOutputFormat _formatFromName(String name) {
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.endsWith('.png')) {
      return ImageOutputFormat.png;
    }
    if (lowercaseName.endsWith('.webp')) {
      return ImageOutputFormat.webp;
    }
    return ImageOutputFormat.jpg;
  }

  String _resultFileName() {
    final sourceName = _source?.name ?? 'image';
    final dotIndex = sourceName.lastIndexOf('.');
    final baseName = dotIndex > 0
        ? sourceName.substring(0, dotIndex)
        : sourceName;
    final safeBaseName = baseName.replaceAll(
      RegExp(r'[^a-zA-Z0-9가-힣_-]+'),
      '_',
    );

    return '${safeBaseName}_edited.${_result!.format.extension}';
  }

  void _setBusyState({required bool processing}) {
    _isProcessing = processing;
    if (processing) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _invalidateResult() {
    _clearResult();
    notifyListeners();
  }

  void _clearResult() {
    _result = null;
    _errorMessage = null;
  }

  String _friendlyError(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    return '이미지를 처리하지 못했습니다. 다른 파일로 다시 시도해 주세요.';
  }
}
