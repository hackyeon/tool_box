import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  const PdfGenerator();

  Future<Uint8List> createFromImages(
      List<Uint8List> images, {
        void Function(int current, int total)? onProgress,
      }) async {
    final document = pw.Document();

    for (int i = 0; i < images.length; i++) {
      final image = pw.MemoryImage(images[i]);

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      onProgress?.call(i + 1, images.length);

      await Future<void>.delayed(Duration.zero);
    }

    return document.save();
  }
}