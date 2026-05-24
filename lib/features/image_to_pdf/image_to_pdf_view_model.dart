import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../core/pdf/pdf_generator.dart';
import 'models/selected_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageToPdfViewModel extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();
  final PdfGenerator _pdfGenerator = const PdfGenerator();

  final List<SelectedImage> _images = [];

  bool _isLoading = false;

  List<SelectedImage> get images => List.unmodifiable(_images);

  bool get isLoading => _isLoading;

  bool get canCreatePdf => _images.isNotEmpty && !_isLoading;

  double _progress = 0.0;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).toInt();

  Future<void> pickImages(BuildContext context) async {
    final pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles.isEmpty) return;

    await addImagesFromFiles(pickedFiles);
  }

  Future<void> addImagesFromFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    for (final file in files) {
      final originalBytes = await file.readAsBytes();
      final compressedBytes = await compressImage(originalBytes);

      _images.add(
        SelectedImage(
          name: file.name,
          bytes: compressedBytes,
        ),
      );
    }

    notifyListeners();
  }

  Future<Uint8List> compressImage(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
    );

    return Uint8List.fromList(result);
  }

  void removeImage(int index) {
    if (index < 0 || index >= _images.length) return;

    _images.removeAt(index);
    notifyListeners();
  }

  void clearImages() {
    _images.clear();
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final image = _images.removeAt(oldIndex);
    _images.insert(newIndex, image);

    notifyListeners();
  }

  Future<void> createPdf() async {
    if (_images.isEmpty || _isLoading) return;

    _isLoading = true;
    _progress = 0.0;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    Uint8List? pdfBytes;

    try {
      pdfBytes = await _pdfGenerator.createFromImages(
        _images.map((image) => image.bytes).toList(),
        onProgress: (current, total) {
          _progress = current / total;
          notifyListeners();
        },
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'ez_image_to_pdf.pdf',
      );
    } finally {
      pdfBytes = null;

      _isLoading = false;
      _progress = 0.0;
      notifyListeners();
    }
  }
}